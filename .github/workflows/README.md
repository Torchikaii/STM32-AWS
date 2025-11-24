# STM32-AWS CI/CD Workflows

This directory contains GitHub Actions workflows for automated STM32 firmware development.

## Workflow Overview

```mermaid
flowchart TD
    A[Push to main branch] --> B[GitHub Actions Trigger]
    B --> C[STM32 Code Generation Job]
    
    subgraph DOCKER["Docker Image Build"]
        D1[Checkout Code] --> D2[Login to GHCR]
        D2 --> D3[Build Custom Image]
        D3 --> D4[Push to Registry]
    end
    
    subgraph GENERATION["Code Generation Stage"]
        E[Checkout Repository] --> F[Create CubeMX Script]
        F --> G[Login to ST Account]
        G --> H[Download STM32F4 firmware package]
        H --> I[Load .ioc Configuration]
        I --> J[Generate C Code & Makefile]
    end
    
    subgraph BUILD["Build Stage"]
        K[Install ARM GCC] --> L[Compile Firmware]
        L --> M[Generate ELF/BIN/HEX]
        M --> N[Size Analysis]
    end
    
    subgraph VALIDATION["Validation Stage"]
        O[Check Artifacts Exist] --> P[Enforce Size Budgets]
        P --> Q[ELF Sanity Checks]
        Q --> R[Vector Table Validation]
    end
    
    subgraph CONTAINER["Docker Container"]
        S[Ubuntu Base Image]
        T[STM32CubeMX 6.15.0]
        U[ARM GCC Toolchain]
        V[Build Tools & Dependencies]
    end
    
    subgraph ARTIFACTS["Build Artifacts"]
        W[Initial_project.elf<br/>Executable]
        X[Initial_project.bin<br/>Binary Image]
        Y[Initial_project.hex<br/>Intel HEX]
        Z[Initial_project.map<br/>Memory Map]
    end
    
    C --> GENERATION
    GENERATION --> BUILD
    BUILD --> VALIDATION
    VALIDATION --> ARTIFACTS
    
    DOCKER --> CONTAINER
    CONTAINER -.-> GENERATION
    
    R --> AA[Upload Artifacts<br/>3 Month Retention]
```

## Design Philosophy: .ioc as Source Code

### Current Approach (Recommended)
- **`.ioc` file** = Source of truth for hardware configuration
- **Generated C files** = Build artifacts (not committed to git)
- **CubeMX regeneration** = Part of build process

### Alternative Approach (Not Recommended)
You could commit the generated code and only regenerate when `.ioc` changes, but this creates:

- **Merge conflicts** when multiple developers modify hardware configurations
- **Sync issues** between `.ioc` and committed C code
- **Repository bloat** from large generated HAL files
- **Inconsistent states** where code doesn't match configuration
- **Manual maintenance** of generated files

The current approach treats `.ioc` as source code and C files as build artifacts - which is the recommended STM32 workflow. This ensures:
- Hardware configuration changes are atomic
- Generated code is always consistent with `.ioc`
- Clean separation between design (`.ioc`) and implementation
- Reproducible builds across environments

## Workflows

### 1. `build-image.yml`
Builds Docker container with STM32CubeMX and toolchain.

**Triggers**: Manual dispatch
**Output**: `ghcr.io/torchikaii/stm32-aws/cubemx-runner:latest`

### 2. `stm32_generate_code.yml`
Main CI/CD pipeline for firmware generation and build.

**Triggers**: Push to main, PR to main, manual dispatch
**Container**: Custom Docker image with STM32CubeMX
**Outputs**: Firmware binaries (.elf, .bin, .hex, .map)

## Caching & Performance

First builds are slow due to:
- Docker layer downloads
- STM32Cube firmware package download (~hundreds of MB)
- Initial compilation of HAL libraries

Subsequent builds are faster through:
- Docker layer caching
- Incremental compilation
- GitHub Actions runner caching

## Security

- ST account credentials stored as GitHub secrets
- Container registry authentication via GitHub tokens
- No hardcoded paths or credentials in workflows