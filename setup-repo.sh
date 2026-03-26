#!/bin/env bash

set -e

echo "setup-repo.sh running"

sudo apt update -y
sudo apt install 7z -y
sudo apt install make -y
sudo apt install build-essential -y
sudp apt install libusb-1.0-0-dev -y
sudo apt install gcc-arm-none-eabi -y
sudo apt install gdb-multiarch -y
sudo apt install openocd -y



wget https://stm32-cube-mx.s3.eu-central-1.amazonaws.com/stm32cubemx-lin-v6-15-0.zip -O stm32cubemx.zip
7z x stm32cubemx.zip
chmod +x SetupSTM32CubeMX-*
./SetupSTM32CubeMX-6.15.0 -c --option-file /path/to/cubemx-auto.xml


echo "setup-repo.sh completed"

