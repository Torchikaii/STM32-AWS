#!/bin/bash

# Run STM32CubeMX to generate code in Docker
echo "Running STM32CubeMX in Docker..."
docker run --rm -v "$(pwd):/workspace" -w /workspace cubemx-runner \
  xvfb-run -a -s "-screen 0 1024x768x24" /opt/STM32CubeMX/STM32CubeMX -q generate_script.txt

