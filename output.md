# STM32CubeMX Docker Debug Summary

## Issue
STM32CubeMX code generation hangs at `project generate` in Docker/CI, but works locally.

## Root Cause
The Docker container is missing the STM32F4 firmware package (or has an older version). When `swmgr install stm32cube_f4_1.28.2 ask` runs, it attempts to download the package and displays a license acceptance dialog. Since xvfb cannot interact with dialogs, the process hangs waiting for user input.

Evidence:
- Container shows `13 KO` after swmgr commands
- Local machine shows `28 KO` after swmgr commands
- This indicates fewer packages installed in container

## xvfb Does NOT Click Anything
xvfb provides a virtual X11 display only - it cannot click buttons or interact with dialogs. It merely renders graphics to a virtual framebuffer.

## Working Commands

### Run container interactively with xvfb
```bash
docker run -it --rm ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev bash
```

### Check installed firmware packages
```bash
xvfb-run -a /opt/STM32CubeMX/STM32CubeMX -i <<'EOF'
swmgr list
exit
EOF
```

### Run script with xvfb (to see where it hangs)
```bash
xvfb-run -a /opt/STM32CubeMX/STM32CubeMX generate_script.txt
```

### To see actual GUI on host screen (requires X11 permissions)
On host machine:
```bash
xhost +local:docker
```

Then run container:
```bash
docker run -it --rm \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $XAUTHORITY:$XAUTHORITY \
  -e XAUTHORITY=$XAUTHORITY \
  ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev bash
```

Inside container:
```bash
/opt/STM32CubeMX/STM32CubeMX generate_script.txt
```

## Possible Solutions

### Option 1: Pre-install firmware in Docker build
Download firmware package locally (after accepting license), then COPY to Docker image:
```dockerfile
COPY STM32CubeF4 /root/.stm32cube/Repository/STM32CubeF4
```
Use `deny` instead of `ask` in script (no license prompt needed if already downloaded).

### Option 2: Use expect to automate dialog
Install `expect` package and use it to simulate clicking "Yes" on license dialog.

### Option 3: Pre-bake firmware into container
Build new container version with F4 firmware already installed and license accepted.

## Notes
- The container likely has F407 firmware pre-installed (worked for previous project)
- F439 requires downloading new firmware package, triggering license dialog
- `swmgr install` only supports `deny` or `ask` - no direct `accept` option
- Credentials are only needed to download firmware once; after that, package can be reused
