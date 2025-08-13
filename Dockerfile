FROM ubuntu:latest

RUN apt-get update -o Acquire::Retries=3 && \
    apt-get install -y python3-pip curl sudo jq unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages ansible boto3 awscli

RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" && \
    dpkg -i session-manager-plugin.deb && \
    rm session-manager-plugin.deb

WORKDIR /github/workspace
