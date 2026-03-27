#!/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUBEMX_AUTO_XML="$SCRIPT_DIR/cubemx-auto.xml"
CUBEMX_INSTALL_DIR="/opt/STM32CubeMX"

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
    

cd /tmp

wget https://stm32-cube-mx.s3.eu-central-1.amazonaws.com/stm32cubemx-lin-v6-15-0.zip -O stm32cubemx.zip
7z x -y stm32cubemx.zip
chmod +x SetupSTM32CubeMX-*
sudo ./SetupSTM32CubeMX-6.15.0 -c --option-file "$CUBEMX_AUTO_XML"
rm -f stm32cubemx.zip SetupSTM32CubeMX-*

sudo ln -sf /home/pc/repos/STM32-AWS "$CUBEMX_INSTALL_DIR/STM32-AWS"

echo ""
echo "CubeMX installed to: $CUBEMX_INSTALL_DIR"
echo "Repo symlinked to:   $CUBEMX_INSTALL_DIR/STM32-AWS"
echo "setup-repo.sh completed"

