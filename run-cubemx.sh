#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${1:-$SCRIPT_DIR/generate_script.txt}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
CUBEMX_PATH="${CUBEMX_PATH:-$HOME/STM32CubeMX/STM32CubeMX}"

echo "Using CUBEMX_PATH=$CUBEMX_PATH"
echo "Using SCRIPT_PATH=$SCRIPT_PATH"

"$CUBEMX_PATH" -q "$SCRIPT_PATH"
