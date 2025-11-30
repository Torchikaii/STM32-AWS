### STM32-AWS CI/CD Workflows

This directory contains GitHub Actions workflows for automated STM32 firmware development.

### Workflow Overview

flowchart below describes CI/CD proccess for both `build-image.yml` and `stm32_generate_code.yml` workflows 

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
        W[Initial_project.elf]
        X[Initial_project.bin<br/>MCU firmware]
        Y[Initial_project.hex]
        Z[Initial_project.map]
    end
    
    C --> GENERATION
    GENERATION --> BUILD
    BUILD --> VALIDATION
    VALIDATION --> ARTIFACTS
    
    DOCKER --> CONTAINER
    CONTAINER -.-> GENERATION
    
    R --> AA[Upload build outputs<br/>3 Month Retention]
```



### Workflow explanation

###### 1. `build-image.yml`
Builds Docker container with STM32CubeMX and toolchain.

- **Triggers**: Manual dispatch
- **Output**: `ghcr.io/torchikaii/stm32-aws/cubemx-runner:latest`

###### 2. `stm32_generate_code.yml`
Main CI/CD pipeline for firmware generation and build.

- **Triggers**: Push to main, PR to main, manual dispatch
- **Container**: Custom Docker image with STM32CubeMX
- **Outputs**: Firmware binaries (.elf, .bin, .hex, .map)

In theory CI/CD should work without the .ioc file, it would just grab the existing C code, however you should think of it like:

- `.ioc` = architectural blueprint
- Generated C files = constructed building
- STM32Cube package = construction materials/tools

## Caching & Performance

First builds are slow due to:
- Docker layer downloads
- STM32Cube firmware package download (~hundreds of MB)

Subsequent builds are faster through:
- Docker layer caching


## Security

- ST account credentials stored as GitHub secrets
- Container registry authentication via GitHub tokens
- No hardoced credentials in workflows (gitleaks enabled)