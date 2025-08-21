#!/bin/bash

# Run the full build process
echo "Starting the build process..."

# Step 1: Build the Docker image
./LocalBuild/build_image.sh

# Step 2: Create generate_script.txt
echo "Creating generate_script.txt..."
cat > generate_script.txt << 'EOF'
config load "$(pwd)/Initial_project.ioc"
project toolchain "Makefile"
project path "$(pwd)"
project name "Initial_project"
project generateunderroot 1
project generate
exit
EOF

# Step 3: Run STM32CubeMX in Docker
echo "Running STM32CubeMX in Docker..."
docker run --rm -v "$(pwd):/workspace" -w /workspace cubemx-runner \
  xvfb-run -a -s "-screen 0 1024x768x24" /opt/STM32CubeMX/STM32CubeMX -q generate_script.txt

# Step 4: Build firmware in Docker
echo "Building firmware in Docker..."
docker run --rm -v "$(pwd):/workspace" -w /workspace/Initial_project cubemx-runner make

# Step 5: Check build artifacts
echo "Checking build artifacts..."
ls -la Initial_project/build || ls -la Initial_project/

# Step 6: Enforce size budgets
echo "Enforcing size budgets..."
ELF=$(ls Initial_project/build/*.elf 2>/dev/null || ls Initial_project/*.elf)
if [ -n "$ELF" ]; then
  docker run --rm -v "$(pwd):/workspace" -w /workspace cubemx-runner \
    arm-none-eabi-size "$ELF"
  read -r TEXT DATA BSS DEC <<<"$(docker run --rm -v "$(pwd):/workspace" -w /workspace cubemx-runner arm-none-eabi-size "$ELF" | awk 'END{print $1,$2,$3,$4}')"
  FLASH_USED=$((TEXT + DATA))
  RAM_USED=$((DATA + BSS))
  echo "FLASH_USED=$FLASH_USED  RAM_USED=$RAM_USED"
  [ "$FLASH_USED" -le $((1024 * 1024)) ] || { echo "Flash overflow"; exit 1; }
  [ "$RAM_USED" -le $((192 * 1024)) ] || { echo "RAM overflow"; exit 1; }
else
  echo "No ELF file found!"
  exit 1
fi

echo "Build process completed successfully."

