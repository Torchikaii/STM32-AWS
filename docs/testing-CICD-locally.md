Before you begin make sure that MCU is connected to PC via USB
and you have installed all packages on your linux system.

### Testing locally without docker container

1. run `generate_script.sh`
```
./generate_script.sh
```
This will create generate_script.txt file with all command list
that will be passed to cubemx and executed.


2. run `run-cubemx.sh`
```
./run-cubemx.sh
```
This will regenerate STM32 project's code from `.ioc` file. This
script should run in complete silent mode with no user
intervention.


3. run `compile-flash.sh`
```
./compile-flash.sh
```
This will compile project using `make` and flash it using
`openocd`

### Testing locally with docker container

**First time setup (accept license):**

1. Build Docker image
```
docker build -t cubemx-base .
```

2. Run container interactively to accept license
```
docker run -it --name cubemx-container cubemx-base bash
```

3. Inside container - accept license once
```
xvfb-run -a STM32CubeMX
```
Navigate to Help > Software Updates > Download and accept the
license agreement. Then exit CubeMX.

4. Commit container with accepted license
```
docker commit cubemx-container cubemx-base:licensed
```

5. Push to GHCR (optional, for CI/CD)
```
docker tag cubemx-base:licensed ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev
docker push ghcr.io/torchikaii/stm32-aws/cubemx-runner:dev
```

**Normal workflow (after license is accepted):**

1. Run container with workspace mounted
```
docker run -it --rm \
  -v $(pwd):/github/workspace \
  cubemx-base:licensed \
  bash
```

2. Inside container - generate script and run CubeMX
```
cd /github/workspace
./generate_script.sh
./run-cubemx.sh
```

3. Inside container - compile
```
cd /github/workspace/test439
make
```

If all steps complete without hanging, the CI/CD pipeline will
work the same in GitHub Actions.
