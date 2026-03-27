#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${1:-generate_script.txt}"
SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
CUBEMX_PATH="${CUBEMX_PATH:-/opt/STM32CubeMX/STM32CubeMX}"
REPO_PATH="/opt/STM32CubeMX/STM32-AWS"

echo "Using CUBEMX_PATH=$CUBEMX_PATH"
echo "Using REPO_PATH=$REPO_PATH"

if [ -d "$REPO_PATH" ]; then
    cd "$REPO_PATH"
    SCRIPT_PATH="${1:-generate_script.txt}"
    SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"
    echo "Using SCRIPT_PATH=$SCRIPT_PATH"
    "$CUBEMX_PATH" -q "$SCRIPT_PATH"
else
    echo "Error: Repo not found at $REPO_PATH"
    echo "Run setup-repo.sh first to create symlink"
    exit 1
fi
