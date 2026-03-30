#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOC_PATH="$SCRIPT_DIR/test439/test439.ioc"
PROJECT_PATH="$SCRIPT_DIR/test439"

echo "login \"${ST_CUBE_EMAIL}\" \"${ST_CUBE_PASSWORD}\" y" > "$SCRIPT_DIR/generate_script.txt"
echo "swmgr refresh" >> "$SCRIPT_DIR/generate_script.txt"
echo "swmgr install stm32cube_f4_1.28.3 ask" >> "$SCRIPT_DIR/generate_script.txt"
echo "config load \"$IOC_PATH\"" >> "$SCRIPT_DIR/generate_script.txt"
echo "project toolchain \"Makefile\"" >> "$SCRIPT_DIR/generate_script.txt"
echo "project path \"$PROJECT_PATH\"" >> "$SCRIPT_DIR/generate_script.txt"
echo "project name \"test439\"" >> "$SCRIPT_DIR/generate_script.txt"
echo "project generateunderroot 1" >> "$SCRIPT_DIR/generate_script.txt"
echo "project generate" >> "$SCRIPT_DIR/generate_script.txt"
echo "exit" >> "$SCRIPT_DIR/generate_script.txt"
