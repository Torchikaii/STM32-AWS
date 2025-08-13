FROM ubuntu:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget unzip openjdk-11-jre && \
    rm -rf /var/lib/apt/lists/*

# Download STM32CubeMX installer
WORKDIR /opt
uRUN wget https://www.st.com/content/ccc/resource/technical/software/sw_development_suite/group0/10/71/68/2c/85/6f/49/82/stm32cubemx-lin_v6.9.2/files/stm32cubemx-lin_v6.9.2.zip/jcr:content/translations/en.stm32cubemx-lin_v6.9.2.zip -O stm32cubemx.zip

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
