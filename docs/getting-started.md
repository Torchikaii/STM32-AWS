# Getting Started

## Local Setup

### Prerequisites

Software:

- OS: Debian based distro with X11 (preferred)
(optionally: Wayland, but may break stuff)
- ST account
- git

Hardware:

- Computer with internet access and usb.
- STM32F439ZI 144 pin NUCLEO board
- USB micro cable with data transfering capabilities.


### 1. Clone repository

Clone repo to the `$HOME` folder's subfolder e.g.
`~/repos/`

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

This command will launch CubeMX GUI
```bash
$HOME/STM32CubeMX/STM32CubeMX
```
- When GUI opens up, then open the existing project
`File -> Load project -> path/to/your-repo/test439/test439.ioc`

- After project opens up, click `Generate code`

- Once prompted for credentials, enter your ST-Link credentials
and login. Wait for all firmware packages to download and accept
all license pop-ups.

- Final popup should say "The Code is succesfully generated
under <path>" Click `Close` and exit CubeMX GUI.

### 4. Verify setup

Accept license when pops up after running these commands:
```bash
./generate_script.sh
./run-cubemx.sh
./compile-flash.sh
```

Further sections needs verification, don't try them out yet
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
