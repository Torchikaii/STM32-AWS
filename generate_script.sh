REPO_PATH="/opt/STM32CubeMX/STM32-AWS"
IOC_PATH="$REPO_PATH/test439/test439.ioc"
PROJECT_PATH="$REPO_PATH/test439"

echo "login \"${ST_CUBE_EMAIL}\" \"${ST_CUBE_PASSWORD}\" y" > generate_script.txt
echo "swmgr refresh" >> generate_script.txt
echo "swmgr install stm32cube_f4_1.28.2 ask" >> generate_script.txt
echo "config load \"$IOC_PATH\"" >> generate_script.txt
echo "project toolchain \"Makefile\"" >> generate_script.txt
echo "project path \"$PROJECT_PATH\"" >> generate_script.txt
echo "project name \"test439\"" >> generate_script.txt
echo "project generateunderroot 1" >> generate_script.txt
echo "project generate" >> generate_script.txt
echo "exit" >> generate_script.txt
