FROM ubuntu:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y  \
        wget \
        unzip \
        openjdk-11-jre \
        xvfb \
        libgtk-3-0 \
        build-essential \
        gcc-arm-none-eabi  \
        binutils-arm-none-eabi  \
        libnewlib-arm-none-eabi  \
        make && \
    rm -rf /var/lib/apt/lists/*

# Download and install STM32CubeMX
WORKDIR /opt

COPY cubemx-auto.xml /tmp/cubemx-auto.xml

RUN wget https://stm32-cube-mx.s3.eu-central-1.amazonaws.com/stm32cubemx-lin-v6-15-0.zip -O stm32cubemx.zip && \
    unzip stm32cubemx.zip && \
    chmod +x SetupSTM32CubeMX-* && \
    ./SetupSTM32CubeMX-6.15.0 -c --option-file /tmp/cubemx-auto.xml && \
    rm -f stm32cubemx.zip SetupSTM32CubeMX-*

# Add CubeMX to PATH (adjust version as needed)
ENV PATH="/opt/STM32CubeMX:${PATH}"

# Example: Command to run code generation (adjust .ioc path)
# RUN STM32CubeMX -q -c <path_to_project.ioc>

# Entrypoint (optional)
# CMD ["bash"]

WORKDIR /github/workspace
