#!/bin/bash

sudo service klipper stop
cd ~/klipper

# Update mcu rpi
echo "Start update mcu rpi"
echo ""
make clean
#make menuconfig KCONFIG_CONFIG=/home/pi/klipper_config/script/config.rpi
make KCONFIG=/home/pi/klipper_config/script/config.rpi
read -p "mcu rpi firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"
make flash KCONFIG_CONFIG=/home/pi/klipper_config/script/config.rpi
echo "Finish update mcu rpi"
echo ""

# Update mcu
echo "Start update mcu"
echo ""
make clean
#make menuconfig KCONFIG_CONFIG=/home/pi/klipper_config/script/config.skr_mini_e3_v3
make KCONFIG_CONFIG=/home/pi/klipper_config/script/config.skr_mini_e3_v3
read -p "mcu firmware built, please check above for any errors. Press [Enter] to continue, or [Ctrl+C] to abort"
./scripts/flash-sdcard.sh /dev/serial/by-id/usb-Klipper_lpc1769_1840010F871C4AAF863E7C5DC32000F5-if00 btt-skr-turbo-v1.4
read -p "mcu firmware flashed, please check above for any errors. Press [Enter] to continue, or [Ctrl+C] to abort"
echo "Finish update mcu"
echo ""

sudo service klipper start
