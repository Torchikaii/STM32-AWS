# Getting Started

## First Time Setup


### 1. Build Docker image
```bash
docker build --no-cache -t stm32-aws/cubemx-runner:dev .
```

### 2. Run container from image
```bash
xhost +local:docker && \
docker run -dit \
  --name cubemx-container \
  -e DISPLAY=$DISPLAY \
  -e ST_CUBE_EMAIL \
  -e ST_CUBE_PASSWORD \
  -e CUBEMX_PATH=/opt/STM32CubeMX/STM32CubeMX \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $XAUTHORITY:$XAUTHORITY \
  -e XAUTHORITY=$XAUTHORITY \
  stm32-aws/cubemx-runner:dev && \
docker cp $(pwd)/. cubemx-container:/github/workspace && \
docker exec -it cubemx-container bash
```

### 3. Install vim inside docker container

```bash
apt-get update
apt-get install vim -y
```

### 4. Setup project for CubeMX inside container

run
```
/opt/STM32CubeMX/STM32CubeMX
```
And follow steps in GUI:
1. open existing .ioc file located inside
`/github/workspace/<yourfile>.ioc`

2. Click generate code

3. Wait for it to download, accept all licenses that pop up

4. When prompted to open project, hit `close` and exit program

### 5. Edit run-cubemx.sh, to run without xvfb

Replace
```bash

CUBEMX_PATH="${CUBEMX_PATH:-$HOME/STM32CubeMX/STM32CubeMX}"
```
with
```bash
CUBEMX_PATH="${CUBEMX_PATH:-/opt/STM32CubeMX/STM32CubeMX}"
```

and also replace 
```bash
xvfb-run -a -s "-screen 0 1024x768x24" \
    "$CUBEMX_PATH" -q "$SCRIPT_PATH"
```

with
```bash
"$CUBEMX_PATH" -q "$SCRIPT_PATH"
```

### 6. Inside container - accept license
```bash
./generate_script.sh
./run-cubemx.sh
```
Accept the license popup when it appears. Scripts continue after acceptance.

### 7. Exit container and commit changes
```bash
exit
docker commit cubemx-container stm32-aws/cubemx-runner:dev
docker rm cubemx-container
```

### 8. Tag docker container

```bash
docker tag stm32-aws/cubemx-runner:dev ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev
```

### 9. Push to GHCR
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
```

### 3. (Optional) Flash to MCU
```bash
cd test439
./compile-flash.sh
```
