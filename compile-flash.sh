

cd "test439"
pwd

make -j4

openocd -f interface/stlink.cfg -f target/stm32f4x.cfg \
  -c "program build/test439.elf verify reset exit"
