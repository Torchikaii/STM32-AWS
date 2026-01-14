# STM32-AWS

> ⚠️ **This project is in a very early stage of development.**  
> Features and documentation are actively being developed—expect rapid changes!

## About

STM32-AWS is an experimental project aiming to connect STM32 microcontrollers to AWS IoT services.  
The project is open to contributors and is currently in its foundational phase.

## Project Structure

```
STM32-AWS/
│
├── .github/
│   └── workflows/
│       ├── stm32_generate_code.yml    # CI/CD: Code generation & build
│       ├── build-image.yml            # Docker image builder
│       ├── gitleaks.yml               # Security: Secret scanning
│       └── README.md                  # Workflow documentation
│
├── MCUs/                              # Multi-MCU support structure
│   └── F407G/
│       └── F407GDISC1/
│           ├── F407GDISC1.ioc         # STM32CubeMX config
│           ├── Core/                  # Generated HAL code
│           ├── USB_HOST/              # USB middleware
│           └── .mxproject              # CubeMX metadata
│
├── Core/                              # STM32 application code
│   ├── Inc/                           # Header files
│   │   └── main.h
│   ├── Src/                           # Source files
│   │   └── main.c
│   └── Startup/
│       └── startup_stm32f407vgtx.s    # Boot assembly
│
├── Drivers/                           # STM32 HAL drivers
│   ├── CMSIS/                         # ARM Cortex-M interface
│   └── STM32F4xx_HAL_Driver/          # STM32F4 HAL library
│
├── Middlewares/                       # Third-party libraries
│   └── ST/
│       └── STM32_USB_Host_Library/    # USB Host stack
│
│
├── PCB/                               # Hardware design files
│   ├── Komponentai/                   # Component libraries (only for ESP12F)
│   │   ├── *.IntLib                   # Integrated libraries
│   │   └── [Component folders]/       # Individual components
│   ├── PCB_Project/                   # Main PCB design
│   │   ├── *.SchDoc                   # Schematics
│   │   ├── *.PcbDoc                   # PCB layout
│   │   └── Project Outputs/           # Gerber files
│   ├── PCB_Start/                     # Initial PCB (not implemented)
│   │   ├── initial.SchDoc
│   │   ├── initial.PcbDoc
│   │   └── PCB_Start.PrjPcb
│   └── README.md
│
├── Datasheets/                        # Hardware documentation
│   ├── STM32F407VG-DISC1 board datasheet.pdf
│   └── STM32F407xx datasheet.pdf
│
├── Plan/                              # Project planning docs
│   ├── initial_plan.md
│   ├── introduction-to-STM32.md
│   └── imgs/
│
├── AI/                                # AI context engineering
│   ├── cursor.md
│   ├── INITIAL.md
│   └── PRP.md
│
├── Initial_project.ioc                # Root STM32CubeMX config
├── Dockerfile                         # CI/CD container definition
├── cubemx-auto.xml                    # CubeMX automation config
├── .gitignore                         # Git exclusions
└── README.md                          # This file
```

## Contributing

We welcome your help!  
- Please check open issues and discussions.
- Create a branch (e.g., `feat/12-update-readme`) for your work.
- Open a pull request with a clear summary of your changes.

## Roadmap

- [ ] Initial connectivity to AWS IoT
- [ ] Device registration and management
- [ ] Secure communication

---

Thank you for your interest in STM32-AWS!  
Feel free to open issues and suggest improvements.
