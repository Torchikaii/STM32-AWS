#!/bin/bash

# Run the full build process
echo "Starting the build process..."

# Step 1: Build the Docker image
./LocalBuild/build_image.sh

# Step 2: Generate code
./LocalBuild/generate_code.sh

# Step 3: Install ARM GCC toolchain
echo "Installing ARM GCC toolchain..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    libnewlib-arm-none-eabi \
    make

# Step 4: Build firmware
echo "Building firmware..."
cd /path/to/your/project/Initial_project
make

# Step 5: Check build artifacts
echo "Checking build artifacts..."
ls -la build || ls -la .

# Step 6: Enforce size budgets
echo "Enforcing size budgets..."
ELF=$(ls build/*.elf 2>/dev/null || ls *.elf)
read -r TEXT DATA BSS DEC <<<"$(arm-none-eabi-size "$ELF" | awk 'END{print $1,$2,$3,$4}')"
FLASH_USED=$((TEXT + DATA))
RAM_USED=$((DATA + BSS))
echo "FLASH_USED=$FLASH_USED  RAM_USED=$RAM_USED"
[ "$FLASH_USED" -le $((1024 * 1024)) ] || { echo "Flash overflow"; exit 1; }
[ "$RAM_USED" -le $((192 * 1024)) ] || { echo "RAM overflow"; exit 1; }

echo "Build process completed successfully."

