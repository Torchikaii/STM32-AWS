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

### 3. Install vim inside docker container

```bash
apt-get update
apt-get install vim
```

### 4. Edit run-cubemx.sh, to run without xvbf 

Replace

```bash
xvfb-run -a -s "-screen 0 1024x768x24" \
    "$CUBEMX_PATH" -q "$SCRIPT_PATH"
```

with 
```
$CUBEMX_PATH -q $SCRIPT_PATH
```

### 5. Inside container - accept license
```bash
./generate_script.sh
./run-cubemx.sh
```
Accept the license popup when it appears. Scripts continue after acceptance.

### 6. Exit container and commit changes
```bash
exit
docker commit cubemx-container stm32-aws/cubemx-runner:dev
docker rm cubemx-container
```

### 7. Push to GHCR
```bash
docker push ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev
```

further sections needs review
----------------

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
