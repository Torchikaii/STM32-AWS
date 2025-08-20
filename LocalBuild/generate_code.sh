#!/bin/bash

# Run STM32CubeMX to generate code
echo "Running STM32CubeMX..."
SCRIPT_PATH="$(realpath "generate_script.txt")"
xvfb-run -a -s "-screen 0 1024x768x24" /opt/STM32CubeMX/STM32CubeMX -q "$SCRIPT_PATH"

