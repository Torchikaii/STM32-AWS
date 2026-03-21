# Getting Started

## What This Project Does

CI/CD pipeline that automates building STM32 projects:

1. **Generate code** from STM32CubeMX (.ioc files)
2. **Compile** with ARM GCC toolchain
3. **Flash** to STM32F439 MCU

Your changes to `.ioc` files → automatic code generation → compiled firmware.

## Hardware You Need

- STM32F439 MCU (or any STM32F4 series)
- ST-Link v2 programmer/debugger
- USB cable to connect ST-Link to PC

## Software Prerequisites

- Linux (Ubuntu/Debian)
- Docker
- Git
- STM32Cube account (free): https://www.st.com/en/development-tools/stm32cubemx.html

## Quick Start

### Step 1: Clone Repository

```bash
git clone https://github.com/torchikaii/STM32-AWS.git
cd STM32-AWS
```

### Step 2: Build Docker Image

```bash
docker build -t cubemx-base .
```

This builds container with:
- STM32CubeMX
- ARM GCC toolchain
- xvfb (virtual display)

### Step 3: Accept License (One Time)

```bash
docker run -it --name cubemx-container cubemx-base bash
```

Inside container:
```bash
xvfb-run -a STM32CubeMX
```

1. Go to **Help > Software Updates > Download**
2. Accept the license agreement
3. Exit CubeMX

Back on host:
```bash
docker commit cubemx-container cubemx-base:licensed
```

### Step 4: Generate Code and Build

```bash
docker run -it --rm \
  -v $(pwd):/github/workspace \
  cubemx-base:licensed \
  bash
```

Inside container:
```bash
cd /github/workspace
./generate_script.sh
./run-cubemx.sh
cd test439
make
```

### Step 5: Flash to MCU

Connect ST-Link to PC and MCU.

```bash
./compile-flash.sh
```

## What Each Script Does

| Script | Purpose |
|--------|---------|
| `generate_script.sh` | Creates `generate_script.txt` with CubeMX commands |
| `run-cubemx.sh` | Runs STM32CubeMX to regenerate code from .ioc |
| `compile-flash.sh` | Compiles and flashes firmware via OpenOCD |

## Next Steps

- **GitHub Actions CI/CD**: Push changes → automatic build
- **Modify test439**: Edit `test439/test439.ioc` in STM32CubeMX → regenerate
- **Create new project**: Use existing project as template, modify .ioc

## Troubleshooting

### "Permission denied" when accessing /dev/ttyUSB0

Add user to dialout group:
```bash
sudo usermod -a -G dialout $USER
# Log out and back in
```

### Docker build fails

Ensure you have:
- At least 20GB free disk space
- Docker daemon running
- Internet connection (downloads CubeMX ~230MB)

### License dialog appears

You skipped step 3 (accept license). Run:
```bash
docker rm cubemx-container  # if exists
docker run -it --name cubemx-container cubemx-base bash
# Accept license, exit
docker commit cubemx-container cubemx-base:licensed
```
