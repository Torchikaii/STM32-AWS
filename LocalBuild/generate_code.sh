#!/bin/bash

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

# Run STM32CubeMX to generate code in Docker
echo "Running STM32CubeMX in Docker..."
SCRIPT_PATH="$(realpath "generate_script.txt")"
echo "Using SCRIPT_PATH=$SCRIPT_PATH"
echo "Using HOME=$HOME"
echo "Using PWD=$PWD"
docker run --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev \
  xvfb-run -a -s "-screen 0 1024x768x24" /opt/STM32CubeMX/STM32CubeMX -q "generate_script.txt"