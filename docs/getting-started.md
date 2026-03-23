# Getting Started

## First Time Setup


### 1. Build Docker image
```bash
docker build -t stm32-aws/cubemx-runner:dev .
```

### 2. Run container from image
```bash
xhost +local:docker
docker run -it \
  --name cubemx-container \
  -e DISPLAY=$DISPLAY \
  -e ST_CUBE_EMAIL \
  -e ST_CUBE_PASSWORD \
  -e CUBEMX_PATH=/opt/STM32CubeMX/STM32CubeMX \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $XAUTHORITY:$XAUTHORITY \
  -e XAUTHORITY=$XAUTHORITY \
  -v $(pwd):/github/workspace \
  stm32-aws/cubemx-runner:dev \
  bash
```

### 3. Inside container - accept license
```bash
./generate_script.sh
./run-cubemx.sh
```
Accept the license popup when it appears. Scripts continue after acceptance.

### 4. Exit container and commit changes
```bash
exit
docker commit cubemx-container stm32-aws/cubemx-runner:dev
docker rm cubemx-container
```

### 5. Push to GHCR (optional)
```bash
docker push stm32-aws/cubemx-runner:dev
```

## Normal Workflow

### 1. Run container
```bash
docker run -it --rm \
  --name cubemx-container \
  -e DISPLAY=$DISPLAY \
  -e ST_CUBE_EMAIL \
  -e ST_CUBE_PASSWORD \
  -e CUBEMX_PATH=/opt/STM32CubeMX/STM32CubeMX \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $XAUTHORITY:$XAUTHORITY \
  -e XAUTHORITY=$XAUTHORITY \
  -v $(pwd):/github/workspace \
  stm32-aws/cubemx-runner:dev \
  bash
```

### 2. Inside container - run scripts
```bash
cd /github/workspace
./generate_script.sh
./run-cubemx.sh
cd test439
make
```

### 3. (Optional) Flash to MCU
```bash
./compile-flash.sh
```
