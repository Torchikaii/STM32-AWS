# Getting Started

## Local Setup

### Prerequisites

```bash
sudo apt update
sudo apt install -y git
```

### 1. Clone repository
```bash
git clone https://github.com/Torchikaii/STM32-AWS.git
cd STM32-AWS
```

### 2. Run setup script
```bash
export ST_CUBE_EMAIL=<your_email>
export ST_CUBE_PASSWORD=<your_password>
./setup-repo.sh
```

This will:
- Install all dependencies
- Install STM32CubeMX to `~/STM32CubeMX`

### 3. Open project in Cubemx and download pakcages

run command below
```bash
$HOME/STM32CubeMX/STM32CubeMX
```
When GUI opens up, then open the existing project (it is inside
this repo) and click "Generate code". Once prompted for
credentials, enter your ST-Link credentials and login. Wait
for all firmware packages to download and accept all license
pop-ups.

### 4. Verify setup
```bash
./generate_script.sh
./run-cubemx.sh
```

---

## Docker Setup

**Note:** Project may fail on Wayland. For better experience, use X11.

### Build Docker image
```bash
docker build --no-cache -t stm32-aws/cubemx-runner:dev .
```

### Run container (first time - accept license)
```bash
xhost +local:docker && \
docker run -dit \
  --name cubemx-container \
  -e DISPLAY=$DISPLAY \
  -e ST_CUBE_EMAIL \
  -e ST_CUBE_PASSWORD \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $XAUTHORITY:$XAUTHORITY \
  -e XAUTHORITY=$XAUTHORITY \
  stm32-aws/cubemx-runner:dev && \
docker cp $(pwd)/. cubemx-container:/root/STM32CubeMX/STM32-AWS && \
docker exec -it cubemx-container bash
```

Inside container:
```bash
./setup-repo.sh
./generate_script.sh
$HOME/STM32CubeMX/STM32CubeMX -q generate_script.txt
# Accept any license popups, then exit
exit
docker commit cubemx-container stm32-aws/cubemx-runner:dev
docker rm cubemx-container
```

### Push to GHCR
```bash
docker tag stm32-aws/cubemx-runner:dev ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev
docker push ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev
```

### Run container (normal workflow)
```bash
docker run -it --rm \
  --name cubemx-container \
  -e DISPLAY=$DISPLAY \
  -e ST_CUBE_EMAIL \
  -e ST_CUBE_PASSWORD \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $XAUTHORITY:$XAUTHORITY \
  -e XAUTHORITY=$XAUTHORITY \
  stm32-aws/cubemx-runner:dev \
  bash
```

Inside container:
```bash
cd ~/STM32CubeMX/STM32-AWS
./generate_script.sh
./run-cubemx.sh
```

---

## Flash to MCU (Local)

```bash
cd test439
./compile-flash.sh
```
