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

