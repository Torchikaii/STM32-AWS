FROM ubuntu:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget unzip openjdk-11-jre && \
    rm -rf /var/lib/apt/lists/*

# Download STM32CubeMX installer
WORKDIR /opt
RUN wget https://stm32-cube-mx.s3.eu-central-1.amazonaws.com/en.SetupSTM32CubeMX-6.12.1-Win.zip -O stm32cubemx.zip

# Unzip and install CubeMX
RUN unzip stm32cubemx.zip && \
    chmod +x SetupSTM32CubeMX-*.linux && \
    ./SetupSTM32CubeMX-*.linux --mode unattended

# Add CubeMX to PATH (adjust version as needed)
ENV PATH="/root/STMicroelectronics/STM32Cube/STM32CubeMX:${PATH}"

# Example: Command to run code generation (adjust .ioc path)
# RUN STM32CubeMX -q -c <path_to_project.ioc>

# Entrypoint (optional)
# CMD ["bash"]

WORKDIR /github/workspace
