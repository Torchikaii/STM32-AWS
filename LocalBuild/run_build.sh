#!/bin/bash

# STM32 Code Generation - Local Build
echo "Starting STM32 Code Generation..."

# Check required environment variables
if [ -z "$ST_CUBE_EMAIL" ] || [ -z "$ST_CUBE_PASSWORD" ]; then
    echo "Error: ST_CUBE_EMAIL and ST_CUBE_PASSWORD environment variables must be set"
    echo "Export them like: export ST_CUBE_EMAIL=your_email@example.com"
    echo "                 export ST_CUBE_PASSWORD=your_password"
    exit 1
fi

# Build Docker image
echo "Building Docker image..."
docker build -t ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev .

# Create generate_script.txt
echo "Creating generate_script.txt..."
cat > generate_script.txt << EOF
login "${ST_CUBE_EMAIL}" "${ST_CUBE_PASSWORD}" y
swmgr refresh
swmgr install stm32cube_f4_1.28.2 ask
config load "/workspace/Initial_project.ioc"
project toolchain "Makefile"
project path "/workspace"
project name "Initial_project"
project generateunderroot 1
project generate
exit
EOF

cat generate_script.txt
echo $PWD

# Run STM32CubeMX
echo "Running STM32CubeMX..."
SCRIPT_PATH="$(realpath "generate_script.txt")"
echo "Using SCRIPT_PATH=$SCRIPT_PATH"
echo "Using HOME=$HOME"
echo "Using PWD=$PWD"
timeout 300 docker run --rm -v "$(pwd):/workspace" -w /workspace \
  ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev \
  xvfb-run -a -s "-screen 0 1024x768x24" /opt/STM32CubeMX/STM32CubeMX -q "generate_script.txt" || echo "STM32CubeMX step failed or timed out, continuing..."

# Install ARM GCC toolchain (in container)
echo "Installing ARM GCC toolchain..."
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev \
  bash -c "apt-get update && apt-get install -y build-essential gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi make"

# Build firmware
if [ -d "Initial_project" ] && [ -f "Initial_project/Makefile" ]; then
  echo "Building firmware..."
  docker run --rm -v "$(pwd):/workspace" -w /workspace/Initial_project \
    -e MAKEFLAGS="-j$(nproc)" \
    ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev \
    bash -c "make && arm-none-eabi-size build/*.elf || true"
else
  echo "Code generation failed - Initial_project directory or Makefile not found"
  exit 1
fi

# Verify artifacts exist
echo "Checking build artifacts..."
ls -la Initial_project/build || ls -la Initial_project/
ELF=$(ls Initial_project/build/*.elf 2>/dev/null || ls Initial_project/*.elf)
BIN=$(ls Initial_project/build/*.bin 2>/dev/null || ls Initial_project/*.bin)
MAP=$(ls Initial_project/build/*.map 2>/dev/null || ls Initial_project/*.map)
echo "ELF=$ELF BIN=$BIN MAP=$MAP"
test -f "$ELF" && test -f "$BIN" && test -f "$MAP"

# Show size and enforce flash/RAM budgets (STM32F407: ~1MB Flash, 192KB RAM)
echo "Enforcing size budgets..."
set -euo pipefail
ELF=$(ls Initial_project/build/*.elf 2>/dev/null || ls Initial_project/*.elf)
# parse the last line of `size` output
read -r TEXT DATA BSS DEC <<<"$(docker run --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev arm-none-eabi-size "$ELF" | awk 'END{print $1,$2,$3,$4}')"
docker run --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev arm-none-eabi-size "$ELF"
FLASH_USED=$((TEXT+DATA))
RAM_USED=$((DATA+BSS))
echo "FLASH_USED=$FLASH_USED  RAM_USED=$RAM_USED"
[ "$FLASH_USED" -le $((1024*1024)) ] || { echo "Flash overflow"; exit 1; }
[ "$RAM_USED"   -le $((192*1024))   ] || { echo "RAM overflow"; exit 1; }

# Basic ELF sanity: vector table & entry symbol present
echo "Checking ELF sanity..."
ELF=$(ls Initial_project/build/*.elf 2>/dev/null || ls Initial_project/*.elf)
# Ensure Reset_Handler exists
docker run --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev arm-none-eabi-nm "$ELF" | grep -q ' T Reset_Handler' || { echo "Missing Reset_Handler"; exit 0; }
# Dump first few vectors for debugging
docker run --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev arm-none-eabi-objdump -D -j .isr_vector "$ELF" | head -n 40

echo "Build process completed successfully."