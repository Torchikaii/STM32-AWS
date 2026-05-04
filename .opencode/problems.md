# Problems & Challenges

This document outlines known problems, technical challenges, and limitations encountered during development of the STM32-AWS framework.

---

## 1. STM32CubeMX CI/CD Issues

### Problem: License Agreement Dialog in Headless Environments

**Status**: ✅ RESOLVED

**Solution**: Users accept license once when building their Docker image. The license acceptance is stored in `~/.STM32CubeMX/` and persisted in the Docker image layer via `docker commit`.

**Workflow**:
1. Build Docker image from Dockerfile
2. Run container interactively: `docker run -it --name cubemx-container <image> bash`
3. Launch CubeMX with xvfb, accept license once
4. Commit container: `docker commit cubemx-container <image>:licensed`
5. Use licensed image for CI/CD

**Related Files**:
- `Dockerfile` - base image with CubeMX installed
- `docs/testing-CICD-locally.md` - documentation

---

## 2. Multi-MCU Consistency

### Problem: Different MCUs Require Different Firmware Packages

**Description**: Each STM32 MCU family (F0, F1, F2, F3, F4, F7, H7, L0, L1, L4, etc.) requires a separate firmware package. The CI/CD pipeline must handle downloading and installing these packages without user interaction.

**Challenge**: 
- No way to pre-install all firmware packages (too large)
- Each new MCU family triggers the license dialog
- Framework should work seamlessly across all STM32 families

**Goal**: The automation solution (expect/xdotool) must work for ANY STM32 MCU without modification.

---

## 3. Docker Image Size vs. Functionality Trade-off

### Option A: Minimal Image (Current)
- Smaller image size
- Must download firmware packages on first use
- License dialog issue occurs

### Option B: Pre-installed Firmware
- Image size: ~10-20GB
- Works out-of-the-box for all MCUs
- Large download for users, long build times

**Current Decision**: Go with Option A (minimal + automation) for faster iteration.

---

## 4. TLS/MQTT Memory Constraints

### Problem: Limited RAM on STM32 MCU

**Description**: TLS handshake and MQTT protocol require significant memory. STM32F439 has 256KB RAM, but TLS contexts can consume 30-50KB+.

**Challenge**:
- wolfMQTT with TLS needs careful buffer configuration
- Must balance performance vs. memory usage

**Mitigation**:
- Use minimal TLS cipher suites
- Configure small buffers for MQTT packets
- Consider TLS session resumption

---

## 5. Latency Measurement Precision

### Problem: Timestamp Jitter from Interrupts

**Description**: When storing timestamps in software (e.g., at start of function), interrupt latency causes jitter in measurements.

**Challenge**:
- Software timestamps can vary by 10-100μs due to interrupts
- Need consistent 1ms precision

**Solution**:
- Use DWT->CYCCNT hardware cycle counter (single-cycle precision)
- Disable interrupts during critical timing sections
- Correlate with cloud-side timestamps using UUIDs

---

## 6. AWS IoT Core Costs

### Problem: Message-based Pricing

**Description**: AWS IoT Core charges per message (publish/subscribe).

**Challenge**:
- Latency measurement requires frequent messaging
- Must balance measurement granularity vs. cost

**Current Approach**:
- Include latency data in existing command/response messages (JSON payload)
- Use message batching where possible

---

## 7. GitHub Actions vs. Local Consistency

### Problem: Different Behavior Between Local and CI

**Description**: Scripts that work locally fail in CI due to environment differences.

**Examples**:
- Local: X11 display available, can see GUI
- CI: xvfb virtual display, license dialog can't be clicked

**Root Cause**:
- Local environment has more resources
- CI environment is stripped down

**Solution**: Use containerized builds that match CI environment locally.

---

## 8. Framework Portability

### Problem: Abstraction Across MCU Families

**Description**: Different STM32 families have different:
- Peripheral APIs (HAL vs. LL)
- Clock configurations
- Memory layouts
- PHY interfaces

**Challenge**: Create a unified API that works across F4, F7, H7, L4, etc.

**Approach**:
- Use STM32CubeMX for hardware generation
- Keep framework code portable (minimize MCU-specific #ifdefs)
- Document supported configurations per MCU family

---

## 9. Device Provisioning

### Problem: Securely Provisioning Devices

**Description**: Each device needs unique X.509 certificates to connect to AWS IoT Core.

**Current Scope**: Not addressed in MVP
**Future**: Need automated provisioning workflow

---

## 10. Build Artifact Management

### Problem: Large Binary Sizes

**Description**: Including full AWS IoT SDK and TLS libraries significantly increases binary size.

**Challenge**:
- Must fit in MCU flash (1MB for F439)
- Need to optimize code size

**Mitigation**:
- Use wolfMQTT (lightweight) instead of AWS IoT SDK
- Enable compiler optimizations (-Os)
- Strip unused libraries

---

## 11. Development Reference Project

### test439/ Directory Purpose

The `test439/` directory in this repository is a **development and testing reference only**. It is used during framework development to verify builds and functionality.

**Important Notes**:
- This directory is NOT part of the shipped framework
- It may be removed or modified at any time
- It serves as a temporary reference for validating the CI/CD pipeline
- Users should generate their own projects using the project-generator script

---

## 12. Local Development Setup

### Overview

For local development, users can run the same STM32CubeMX code generation used in CI/CD. This ensures consistency between local and CI environments.

### Prerequisites

```bash
# Core build tools
sudo apt update
sudo apt install make build-essential

# ARM GCC toolchain
sudo apt install gcc-arm-none-eabi gdb-multiarch

# ST-Link for flashing
sudo apt install openocd libusb-1.0-0-dev

# Java (required for STM32CubeMX)
sudo apt install openjdk-11-jre


```

### STM32CubeMX Installation

Download and install STM32CubeMX with automated options:

```bash
wget https://stm32-cube-mx.s3.eu-central-1.amazonaws.com/stm32cubemx-lin-v6-15-0.zip -O stm32cubemx.zip
unzip stm32cubemx.zip
chmod +x SetupSTM32CubeMX-*

# Install with auto-accept (using cubemx-auto.xml)
./SetupSTM32CubeMX-6.15.0 -c --option-file /path/to/cubemx-auto.xml
```

### Local Build and Flash Workflow

1. **Generate code** (from project directory):
   ```bash
   ./run-cubemx.sh
   ```

2. **Compile**:
   ```bash
   make
   ```

3. **Flash with OpenOCD**:
   ```bash
   openocd -f interface/stlink.cfg -f target/stm32f4x.cfg \
     -c "program build/project.elf verify reset exit"
   ```

4. **Debug with GDB**:
   ```bash
   # Start OpenOCD in one terminal
   openocd -f interface/stlink.cfg -f target/stm32f4x.cfg
   
   # In another terminal
   gdb-multiarch build/project.elf
   (gdb) target extended-remote tcp:127.0.0.1:3333
   (gdb) monitor reset halt
   (gdb) load
   (gdb) monitor reset
   (gdb) continue
   ```

### See Also

- `.github/workflows/stm32_generate_code.yml` - CI/CD pipeline reference
- `generate_script.txt` - Example CubeMX script

---

## Summary of Priority Issues

| Priority | Issue | Impact | Status |
|----------|-------|--------|--------|
| 🔴 Critical | License dialog in CI | Pipeline hangs | ✅ Resolved |
| 🔴 Critical | CI consistency | Blocks development | ✅ Resolved |
| 🟠 High | Multi-MCU support | Core requirement | Pending |
| 🟡 Medium | TLS memory constraints | Performance | Pending |
| 🟡 Medium | Latency precision | Core feature | Pending |
| 🟢 Low | Cost optimization | Future concern | Pending |

---

*Document Version: 1.0*  
*Last Updated: 2026-03-12*
