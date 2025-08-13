FROM ubuntu:latest

RUN apt-get update -o Acquire::Retries=3 && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "what steps needed to install cubemx"

WORKDIR /github/workspace
