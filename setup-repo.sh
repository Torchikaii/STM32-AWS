#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIG_DIR="$(pwd)"
CUBEMX_AUTO_XML="$SCRIPT_DIR/cubemx-auto.xml"
CUBEMX_INSTALL_DIR="$HOME/STM32CubeMX"
CUBEMX_BIN="$CUBEMX_INSTALL_DIR/STM32CubeMX"

echo "setup-repo.sh running"

sudo apt update -y
sudo apt install -y \
    p7zip-full \
    make \
    build-essential \
    libusb-1.0-0-dev \
    gcc-arm-none-eabi \
    gdb-multiarch \
    openocd 

if [ -x "$CUBEMX_BIN" ]; then
    echo "CubeMX already installed at $CUBEMX_INSTALL_DIR, skipping download"
else
    cd "$HOME"
    wget https://stm32-cube-mx.s3.eu-central-1.amazonaws.com/stm32cubemx-lin-v6-15-0.zip -O stm32cubemx.zip
    7z x -y stm32cubemx.zip
    chmod +x SetupSTM32CubeMX-*
    ./SetupSTM32CubeMX-6.15.0 -c --option-file "$CUBEMX_AUTO_XML"
    rm -f stm32cubemx.zip SetupSTM32CubeMX-*
fi

cd "$ORIG_DIR"
echo ""
echo "CubeMX installed to: $CUBEMX_INSTALL_DIR"
echo "Repo location:      $SCRIPT_DIR"
echo "setup-repo.sh completed"

