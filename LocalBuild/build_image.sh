#!/bin/bash

# Build Docker Image
echo "Building Docker image..."
docker build -t ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev .