echo "login \"${ST_CUBE_EMAIL}\" \"${ST_CUBE_PASSWORD}\" y" > generate_script.txt
echo "swmgr refresh" >> generate_script.txt
echo "swmgr install stm32cube_f4_1.28.2 ask" >> generate_script.txt
echo "config load \"/__w/STM32-AWS/STM32-AWS/Initial_project.ioc\"" >> generate_script.txt
echo "project toolchain \"Makefile\"" >> generate_script.txt
echo "project path \"/__w/STM32-AWS/STM32-AWS\"" >> generate_script.txt
echo "project name \"Initial_project\"" >> generate_script.txt
echo "project generateunderroot 1" >> generate_script.txt
echo "project generate" >> generate_script.txt
echo "exit" >> generate_script.txt
