#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${1:-generate_script.txt}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
CUBEMX_PATH="${CUBEMX_PATH:-$HOME/STM32CubeMX/STM32CubeMX}"

echo "Using SCRIPT_PATH=$SCRIPT_PATH"
echo "Using CUBEMX_PATH=$CUBEMX_PATH"
echo "Using HOME=$HOME"

xvfb-run -a -s "-screen 0 1024x768x24" \
    "$CUBEMX_PATH" -q "$SCRIPT_PATH"
