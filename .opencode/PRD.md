# STM32-AWS Product Requirements Document

---

## 1. Executive Summary

STM32-AWS is an open-source IoT framework designed to simplify connecting STM32 microcontrollers to AWS cloud services. The framework provides an abstraction layer that enables embedded developers to focus on application logic rather than low-level connectivity concerns.

**Core Value Proposition**: Reduce time-to-market for STM32-based IoT products by providing a unified API for ethernet connectivity, MQTT communication with AWS IoT Core, and integrated latency benchmarking.

**MVP Goal**: Deliver a functional framework that supports STM32F4 series MCUs with ethernet connectivity, AWS IoT Core integration via MQTT, and comprehensive latency measurement capabilities.

---

## 2. Mission & Principles

### Mission Statement
Enable embedded developers to rapidly deploy STM32-based IoT devices with reliable AWS connectivity, transparent latency metrics, and minimal vendor lock-in.

### Core Principles

1. **MCU Agnosticism** - Framework must work consistently across STM32 families (F0-F7, H7, L0-L5, U5, WB, WL) without per-MCU configuration
2. **Zero-Config CI/CD** - Code generation and building must work out-of-the-box for any supported MCU in GitHub Actions
3. **Environment Parity** - Local Docker builds must produce identical results to CI/CD pipeline
4. **Observable Systems** - Latency must be measurable at each hop with 1ms precision
5. **Progressive Complexity** - Simple use cases should remain simple; advanced features optional
6. **Infrastructure as Code** - All cloud resources managed via Terraform

---

## 3. Target Users

### Primary Personas

**Embedded Developer (Primary)**
- Experienced with STM32CubeMX and C/C++
- Familiar with AWS services but not an expert
- Wants to ship IoT products quickly without deep cloud expertise
- Technical comfort: High

**DevOps Engineer**
- Manages CI/CD pipelines
- Needs reproducible builds across MCU variants
- Values automation and Infrastructure as Code

### Problems Solved

1. Complex AWS IoT connectivity setup for resource-constrained devices
2. Lack of visibility into end-to-end latency in embedded systems
3. No way to measure how long commands take to execute or database writes
4. Fragmented toolchain across STM32 families
5. Manual, error-prone code generation processes
6. Inconsistent results between local builds and CI/CD

---

## 4. Scope

### In Scope (MVP) ✅

- [ ] **Ethernet Driver**: LAN8742A PHY support with STM32F439 (RMII interface)
- [ ] **Network Stack**: LwIP integration via STM32CubeMX
- [ ] **AWS IoT Core**: MQTT over TLS connectivity
- [ ] **Device Shadow**: Direct shadow for command/control
- [ ] **CI/CD Pipeline**: GitHub Actions with STM32CubeMX code generation
- [ ] **Project Generator**: TUI script for creating new STM32 projects
- [ ] **Latency Measurement**: Full end-to-end benchmarking with correlation IDs
- [ ] **Time Monitoring**: Real-time measurement of command execution, database writes, and cloud round-trip times
- [ ] **PostgreSQL Database**: AWS RDS for metrics storage
- [ ] **EC2 Control Server**: Command execution node
- [ ] **Multi-MCU Foundation**: Architecture supporting F4 series and beyond
- [ ] **Terraform Infrastructure**: VPC, RDS, EC2, IoT Core
- [ ] **Testing Framework**: Unit, integration, and HIL tests

### Out of Scope ❌

- [ ] OTA firmware updates (future phase)
- [ ] Lambda-based control logic (future phase - EC2 only for now)
- [ ] Grafana dashboards (future phase)
- [ ] LoRa connectivity (future phase - STM32WL)
- [ ] Bluetooth LE connectivity (future phase - STM32WB)
- [ ] Device provisioning/registration workflow (future phase)

---

## 5. User Stories

### Developer Stories

1. **As an** embedded developer, **I want** to generate a project for any STM32F4 MCU with ethernet support **so that** I don't need to manually configure CubeMX each time.

2. **As an** embedded developer, **I want** my STM32 device to automatically connect to AWS IoT Core over MQTT **so that** I can focus on application logic.

3. **As an** embedded developer, **I want** to know exactly how long each operation takes (database write, command execution, cloud round-trip) **so that** I can identify bottlenecks and optimize my system.

4. **As an** embedded developer, **I want** to add the framework to a new STM32 project with minimal configuration **so that** I can start building my application immediately.

5. **As an** embedded developer, **I want** to use a simple TUI script to create new STM32 projects **so that** I don't have to manually set up CubeMX and Makefile.

### Operations Stories

5. **As a** DevOps engineer, **I want** the CI/CD pipeline to work for any STM32 MCU family without modification **so that** I don't need to maintain per-MCU configurations.

6. **As a** DevOps engineer, **I want** all cloud infrastructure defined in Terraform **so that** I can version control and reproduce environments.

7. **As a** DevOps engineer, **I want** to run code generation locally with the same results as CI/CD **so that** I can debug build issues.

### Product Stories

8. **As a** product owner, **I want** latency data stored in PostgreSQL **so that** I can query and analyze system performance over time.

9. **As a** product owner, **I want** the framework to support multiple STM32 families **so that** I can choose the right MCU for each use case.

---

## 6. Architecture & Design

### High-Level System Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌─────────────┐
│   STM32 MCU     │────▶│  AWS IoT     │────▶│   PostgreSQL    │◀────│   EC2       │
│   (Ethernet)    │     │   Core       │     │   (RDS)         │     │   Server    │
│                 │     │   (MQTT)     │     │                 │     │             │
└─────────────────┘     └──────────────┘     └─────────────────┘     └─────────────┘
        │                       │                       │                       │
        ▼                       ▼                       ▼                       ▼
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌─────────────┐
│ DWT Cycle       │     │ Lambda       │     │ Latency         │     │ Command     │
│ Counter         │     │ Timestamps   │     │ Metrics         │     │ Execution   │
│ (1 cycle        │     │ (~1ms)       │     │ Table           │     │ Service     │
│  precision)     │     │              │     │                 │     │             │
└─────────────────┘     └──────────────┘     └─────────────────┘     └─────────────┘
```

### Data Flow with Correlation IDs

```
MCU Send ──[correlation_uuid, payload, DWT_timestamp]──▶ AWS IoT Core
                                                              │
                                                              ▼
                                                      Lambda (timestamp + store)
                                                              │
                                                              ▼
                                                      PostgreSQL (metrics table)
                                                              │
                                                              ▼
                                                      EC2 (process command)
                                                              │
                                                              ▼
                                                      Response path (same correlation_id)
```

### Key Components

| Component | Responsibility |
|----------|----------------|
| `STM32-AWS-Framework` | Core library for MCU connectivity |
| `project-generator` | TUI script for creating new STM32 projects |
| `stm32-cubemx-generator` | CI/CD code generation automation |
| `aws-infrastructure` | Terraform modules for cloud resources |
| `latency-collector` | Data pipeline from IoT to database |
| `ec2-control-server` | Command execution service |

> **Note**: This is a brief overview of the intended project structure. It is subject to change as the project evolves.

### Directory Structure

```
STM32-AWS/
├── .github/
│   └── workflows/
│       └── stm32_generate_code.yml    # CI/CD pipeline
├── Terraform/                     # Terraform IaC
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
├── src/                               # Framework source
│   ├── ethernet/
│   ├── mqtt/
│   └── latency/
├── scripts/
│   └── project-generator/              # TUI for creating new projects
├── docker/
│   └── cubemx-runner/                 # Docker image for CI
└── docs/
```

### Framework Usage Model

The framework does NOT ship with bundled projects for each MCU. Instead:

1. **Project Generation**: Users run the `project-generator` TUI script which prompts for:
   - STM32CubeMX credentials (stored for future CI/CD runs)
   - MCU type (e.g., STM32F439ZI)
   - Project name and location
   - Required peripherals (Ethernet, USB, etc.)

2. **Generation Process**: The script:
   - Creates a new STM32CubeMX .ioc file
   - Generates Makefile-based project
   - Integrates the STM32-AWS-Framework source

3. **User Workflow**:
   ```
   ./scripts/project-generator.sh
   → Select MCU type
   → Enter project name
   → Select peripherals
   → Generate project
   → cd myproject && make
   ```

---

## 7. Technology Stack

### Embedded (MCU)

| Component | Technology | Version |
|-----------|------------|---------|
| MCU Family | STM32 | F4 series (initially) |
| IDE/Config | STM32CubeMX | 6.15.0+ |
| Toolchain | ARM GCC | 10.3+ |
| Network Stack | LwIP | 2.1.x |
| MQTT Client | wolfMQTT | Latest |
| TLS | mbedTLS | Latest |

### Cloud (AWS)

| Component | Service | Configuration |
|-----------|---------|---------------|
| MQTT Broker | AWS IoT Core | TLS 1.2+ |
| Database | PostgreSQL (RDS) | 14+ |
| Compute | EC2 | t3.micro (dev) |
| VPC | AWS VPC | Public/private subnets |
| Container Registry | GitHub Container Registry | ghcr.io |

### CI/CD

| Component | Technology |
|-----------|------------|
| Build Runner | GitHub Actions |
| Build System | Make (Makefile) |
| Container | Custom Docker (STM32CubeMX + ARM GCC) |
| Virtual Display | xvfb |
| Automation | expect / xdotool |

---

## 8. Security & Configuration

### AWS IoT Core Security

- **Authentication**: X.509 certificates per device
- **Authorization**: IoT Core policies (least privilege)
- **TLS**: Mutual authentication (client + server certificates)

### Infrastructure Security

- **VPC**: Private subnets for RDS and EC2
- **Security Groups**: Restrictive ingress/egress rules
- **Secrets**: AWS Secrets Manager for credentials
- **SSH**: Key-based authentication only for EC2

### Configuration Management

- **MCU Configuration**: STM32CubeMX `.ioc` files (version controlled)
- **Cloud Configuration**: Terraform `.tfvars` files
- **Framework Config**: `aws_config.h` header file

---

## 9. API Specification

### MQTT Topics

| Topic | Direction | Payload |
|-------|-----------|---------|
| `device/{device_id}/command` | Cloud → MCU | JSON command |
| `device/{device_id}/response` | MCU → Cloud | JSON response |
| `device/{device_id}/telemetry` | MCU → Cloud | Sensor data |
| `device/{device_id}/latency` | MCU → Cloud | Latency metrics |

### Latency Metrics Schema (PostgreSQL)

The database stores time measurements for each operation, allowing analysis of where delays occur. Each record includes:

- **Correlation ID**: Links all timestamps for a single request across the entire chain
- **Device ID**: Identifies which MCU sent the data
- **MCU Timestamps**: Hardware cycle counts from the STM32 (for precise microsecond-level timing)
- **Cloud Timestamps**: Server-side timestamps when messages arrive at IoT Core and when data is written to the database
- **Calculated Latencies**: Pre-computed differences showing how long each step took (e.g., MCU to IoT, IoT to DB, command execution)
- **Payload**: The original JSON data for debugging

This structure enables querying to identify which component causes delays - the MCU, network, cloud processing, or database operations.

---

## 10. Success Criteria

### Functional Acceptance Criteria

- [ ] STM32F439 connects to network via DHCP
- [ ] STM32F439 establishes TLS connection to AWS IoT Core
- [ ] STM32F439 publishes/subscribes to MQTT topics
- [ ] Commands from cloud control LED on MCU
- [ ] Latency metrics stored in PostgreSQL with <1ms cloud-side precision
- [ ] CI/CD pipeline generates code for any STM32F4 MCU
- [ ] CI/CD pipeline compiles and produces ELF/BIN/HEX
- [ ] Terraform creates VPC, RDS, EC2, IoT Core resources
- [ ] Framework builds for multiple STM32 families (F4, at minimum)

### Quality Indicators

| Metric | Target |
|--------|--------|
| Code generation success rate | 100% |
| CI/CD build time | < 5 minutes |
| End-to-end latency (MCU → Cloud → DB) | < 500ms (typical) |
| Latency measurement precision | ±1ms |
| Framework binary size | < 64KB (base) |

---

## 11. Implementation Phases

### Phase 1: CI/CD Foundation ✅ (Current Focus)
**Goal**: Fix and solidify the CI/CD pipeline to work for any STM32 MCU

**Deliverables**:
- [ ] Dockerfile with STM32CubeMX
- [ ] GitHub Actions workflow
- [ ] Test project (STM32F439ZI)

**Timeline**: 1-2 weeks

### Phase 2: Ethernet & Network
**Goal**: Functional ethernet connectivity on STM32F439

**Deliverables**:
- [ ] LAN8742A PHY driver integration
- [ ] LwIP stack configuration
- [ ] DHCP client functionality
- [ ] Basic connectivity test

**Timeline**: 2-3 weeks

### Phase 3: AWS Integration
**Goal**: Connect device to AWS IoT Core

**Deliverables**:
- [ ] TLS connectivity to AWS IoT
- [ ] MQTT client integration (wolfMQTT)
- [ ] Device shadow implementation
- [ ] Command/response handling

**Timeline**: 3-4 weeks

### Phase 4: Latency Measurement
**Goal**: End-to-end latency benchmarking

**Deliverables**:
- [ ] DWT cycle counter integration
- [ ] Correlation ID system
- [ ] PostgreSQL schema
- [ ] Latency dashboard queries

**Timeline**: 2-3 weeks

### Phase 5: Infrastructure as Code
**Goal**: Terraform-managed AWS resources

**Deliverables**:
- [ ] VPC module
- [ ] RDS PostgreSQL module
- [ ] EC2 control server module
- [ ] AWS IoT Core configuration

**Timeline**: 1-2 weeks

---

## 12. Testing Strategy

### Testing Types

- **Unit Tests**: Test individual framework components (MQTT, ethernet, latency modules)
- **Integration Tests**: Test interactions between framework and AWS services
- **Hardware-in-the-Loop (HIL)**: Test on actual STM32 hardware with network connectivity
- **CI/CD Validation**: Verify builds succeed for all supported MCU families

### Time Measurement & Monitoring

The framework must provide comprehensive time measurement capabilities:

- **Command Execution Time**: Measure how long each cloud command takes to execute on MCU
- **Database Write Time**: Track time to write data to PostgreSQL
- **Cloud Round-Trip Time**: Measure total time from MCU send to response receipt
- **Per-Hop Latency**: Break down latency at each network hop (MCU → IoT → DB → EC2)

### Monitoring Approach

- Store all time measurements in PostgreSQL with correlation IDs
- Query capabilities for analyzing latency trends
- Support for identifying which component causes delays

---

## 13. Risks & Mitigations

### Risk 1: STM32CubeMX License Dialog in CI/CD
**Impact**: Pipeline hangs indefinitely
**Likelihood**: Certain (occurs with any new MCU family)
**Mitigation**: Implement expect/xdotool automation for license acceptance

### Risk 2: TLS Handshake Memory Constraints
**Impact**: MCU runs out of RAM during TLS
**Likelihood**: Medium
**Mitigation**: Use wolfMQTT with minimal TLS footprint, optimize buffer sizes

### Risk 3: Multi-MCU Compatibility
**Impact**: Framework works only for F4 series
**Likelihood**: High (without intentional design)
**Mitigation**: Abstract PHY and peripheral access, test across families

### Risk 4: Latency Precision on MCU
**Impact**: Timestamps inaccurate due to interrupt jitter
**Likelihood**: Medium
**Mitigation**: Use DWT cycle counter (hardware), disable interrupts during critical timing

### Risk 5: AWS IoT Core Costs
**Impact**: Uncontrolled usage costs at scale
**Likelihood**: Low (early stage)
**Mitigation**: Monitor message counts, implement message batching

### Risk 6: Local vs CI Environment Differences
**Impact**: Code works locally but fails in CI/CD
**Likelihood**: High (occurs when switching to new MCU)
**Mitigation**: Use containerized builds matching CI environment, automate license acceptance

---

## 14. Future Considerations

### Post-MVP Enhancements

1. **LoRa Support** - Expand to STM32WL series
2. **Bluetooth LE** - Expand to STM32WB series
3. **OTA Updates** - S3-based firmware distribution
4. **Lambda Control** - Serverless command processing
5. **Grafana Integration** - Pre-built latency dashboards
6. **Device Provisioning** - Fleet provisioning workflow
7. **Multi-Framework Support** - ESP32, Nordic nRF52

### Integration Opportunities

- AWS IoT Greengrass for edge computing
- AWS Timestream for time-series data
- AWS Device Defender for security

---

## Appendix: Key Technical Context

### STM32CubeMX License Behavior

The `swmgr install` command supports two license modes:
- `deny` - Won't install if license not previously accepted
- `ask` - Shows GUI dialog to accept license (blocks in headless environments)

**No silent accept option exists**. This requires automation via expect/xdotool.

### Supported MCU Families (Goal)

| Series | Wireless | Status | Notes |
|--------|----------|--------|-------|
| F4 | Ethernet | Target | Initial support |
| F7 | Ethernet | Planned | |
| H7 | Ethernet | Planned | |
| L4 | Ethernet | Planned | |
| WB | Bluetooth LE + Thread/Zigbee | Planned | No WiFi |
| WL | LoRa (sub-GHz) | Planned | No WiFi/Bluetooth |
| U5 | Ethernet | Planned | Ultra-low power |

### Build Artifacts

| Artifact | Purpose |
|----------|---------|
| `.elf` | Debugging with GDB |
| `.bin` | Flash to MCU |
| `.hex` | Flash with ST-LINK |
| `.map` | Memory analysis |

---

*Document Version: 1.0*  
*Last Updated: 2026-03-12*
