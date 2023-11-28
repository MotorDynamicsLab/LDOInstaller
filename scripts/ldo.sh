#!/usr/bin/env bash

#=======================================================================#
# Copyright (C) 2023 - 2023 LDO Motors                                  #
#                                                                       #
# This file is part of LDO Installer                                    #
# https://github.com/MotorDynamicsLab/LDOInstaller.git                  # 
#                                                                       #
# This script utilizes scripts from                                     #
# KIAUH - Klipper Installation And Update Helper                        #
# https://github.com/dw-0/kiauh                                         #
#                                                                       #
# This file may be distributed under the terms of the GNU GPLv3 license #
#=======================================================================#

set -e

ASK_TO_REBOOT=0

if [ -e /boot/firmware/config.txt ] ; then
  FIRMWARE=/firmware
else
  FIRMWARE=
fi
CONFIG=/boot${FIRMWARE}/config.txt
CMDLINE=/boot${FIRMWARE}/cmdline.txt

USER=${SUDO_USER:-$(who -m | awk '{ print $1 }')}
if [ -z "$USER" ] && [ -n "$HOME" ]; then
  USER=$(getent passwd | awk -F: "\$6 == \"$HOME\" {print \$1}")
fi
if [ -z "$USER" ] || [ "$USER" = "root" ]; then
  USER=$(getent passwd | awk -F: '$3 == "1000" {print $1}')
fi

INIT="$(ps --no-headers -o comm 1)"

HOMEDIR="$(getent passwd "$USER" | cut -d: -f6)"

FBRES="$(cat /sys/class/graphics/fb0/virtual_size | sed -r 's/,/:/')" # get current framebuffer resolution


function get_splash_service() {
  if systemctl status splash.service  | grep -q -w loaded; then
    echo 0
  else
    echo 1
  fi
}

function do_boot_splash() {
  local option=$1 
  local mplayer="false"

  ### check system for installed mplayer
  if dpkg -s mplayer 2>/dev/null | grep -q "Status: install ok installed"; then
    mplayer="true"
    else
    mplayer="false"
  fi
  if [[ ${option} -eq 1 ]]; then

    if [ ${mplayer} == "false" ]; then
      sudo apt-get install mplayer -y
      ok_msg "mplayer installed!"
    fi
    if ! grep -q "splash" $CMDLINE ; then
      sudo sed -i $CMDLINE -e "s/$/ consoleblank=1 logo.nologo quiet loglevel=0 plymouth.enable=0 vt.global_cursor_default=0 plymouth.ignore-serial-consoles splash fastboot noatime nodiratime noram/"
    fi
    #set_config_var disable_splash 1 $CONFIG
    if ! grep -q "disable_splash=1" $CONFIG ; then
      sudo sed -i $CONFIG -e "/^\[all\]/a disable_splash=1"
    fi
    if [ $(get_splash_service) -eq 1 ]; then
      sudo cp $HOMEDIR/LDOInstaller/splash/splash.service /etc/systemd/system/splash.service
      sudo sed -i /etc/systemd/system/splash.service -e "/^\[Service\]/a ExecStart=/usr/bin/mplayer -vf scale=${FBRES} -vo fbdev2 ${HOMEDIR}/LDOInstaller/splash/ldo.mp4 &> /dev/null"
      sudo systemctl enable splash.service
    fi
    STATUS=installed
  elif [[ ${option} -eq 2 ]]; then
    if [ ${mplayer} == "true" ]; then
      sudo apt-get remove mplayer -y
      ok_msg "mplayer removed!"
    fi
    if grep -q "splash" $CMDLINE ; then
      sudo sed -i $CMDLINE -e "s/ consoleblank=1//"
      sudo sed -i $CMDLINE -e "s/ quiet//"
      sudo sed -i $CMDLINE -e "s/ plymouth.ignore-serial-consoles//"
      sudo sed -i $CMDLINE -e "s/ logo.nologo//"
      sudo sed -i $CMDLINE -e "s/ loglevel=0//"
      sudo sed -i $CMDLINE -e "s/ plymouth.enable=0//"
      sudo sed -i $CMDLINE -e "s/ vt.global_cursor_default=0//"
      sudo sed -i $CMDLINE -e "s/ splash//"
      sudo sed -i $CMDLINE -e "s/ fastboot//"
      sudo sed -i $CMDLINE -e "s/ noatime//"
      sudo sed -i $CMDLINE -e "s/ nodiratime//"
      sudo sed -i $CMDLINE -e "s/ noram//"
    fi
    #clear_config_var disable_splash $CONFIG
    if grep -q "disable_splash=1" $CONFIG ; then
      sudo sed -i $CONFIG -z -e "s/disable_splash=1\n//"
    fi
    if [ $(get_splash_service) -eq 0 ]; then
      sudo systemctl disable splash.service 
      sudo rm /etc/systemd/system/splash.service
    fi
    STATUS=removed
  else
    return $option
  fi

  if [ -e /boot/firmware/config.txt ] ; then
    sudo rm /boot/cmdline.txt
    sudo rm /boot/config.txt
    sudo ln -s /boot/firmware/cmdline.txt /boot/cmdline.txt
    sudo ln -s /boot/firmware/config.txt /boot/config.txt
  fi
    ok_msg "Splash screen ${STATUS}!"
}

function do_35dpi_lcd() {
  local option=$1 

  if [[ ${option} -eq 1 ]]; then
    sudo cp $HOMEDIR/LDOInstaller/configs/ldo_35dpi_3b4b.dtbo /boot/overlays/ldo_35dpi_3b4b.dtbo
    sudo cp $HOMEDIR/LDOInstaller/configs/ldo_35dpi_3b.dtbo /boot/overlays/ldo_35dpi_3b.dtbo
    sudo cp $HOMEDIR/LDOInstaller/configs/ldo_35dpi_4b.dtbo /boot/overlays/ldo_35dpi_4b.dtbo
    if ! grep -q "dtoverlay=ldo_35dpi_4b.dtbo" $CONFIG ; then
      if ! grep -q "display_lcd_rotate=2" $CONFIG ; then
        sudo sed -i $CONFIG -e "/^\[all\]/a display_lcd_rotate=2"
      fi
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=ldo_35dpi_4b.dtbo"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=ldo_35dpi_3b.dtbo"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=ldo_35dpi_3b4b.dtbo"
      sudo sed -i $CONFIG -e "/^\[all\]/a hdmi_timings=640 0 20 10 10 480 0 10 5 5 0 0 0 60 0 60000000 1"
      sudo sed -i $CONFIG -e "/^\[all\]/a dpi_output_format=0x6f006"
      sudo sed -i $CONFIG -e "/^\[all\]/a dpi_mode=87"
      sudo sed -i $CONFIG -e "/^\[all\]/a dpi_group=2"
      sudo sed -i $CONFIG -e "/^\[all\]/a extra_transpose_buffer=2"
      sudo sed -i $CONFIG -e "/^\[all\]/a display_default_lcd=1"
      sudo sed -i $CONFIG -e "/^\[all\]/a enable_dpi_lcd=1"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=dpi18"
      sudo sed -i $CONFIG -e "/^\[all\]/a gpio=20-25=a2"
      sudo sed -i $CONFIG -e "/^\[all\]/a gpio=12-17=a2"
      sudo sed -i $CONFIG -e "/^\[all\]/a gpio=0-9=a2"
    fi

    STATUS=installed
  elif [[ ${option} -eq 2 ]]; then
    if grep -q "dtoverlay=ldo_35dpi_4b.dtbo" $CONFIG ; then
      sudo sed -i $CONFIG -z -e "s/gpio=0-9=a2\n//"
      sudo sed -i $CONFIG -z -e "s/gpio=12-17=a2\n//"
      sudo sed -i $CONFIG -z -e "s/gpio=20-25=a2\n//"
      sudo sed -i $CONFIG -z -e "s/dtoverlay=dpi18\n//"
      sudo sed -i $CONFIG -z -e "s/enable_dpi_lcd=1\n//"
      sudo sed -i $CONFIG -z -e "s/display_default_lcd=1\n//"
      sudo sed -i $CONFIG -z -e "s/extra_transpose_buffer=2\n//"
      sudo sed -i $CONFIG -z -e "s/dpi_group=2\n//"
      sudo sed -i $CONFIG -z -e "s/dpi_mode=87\n//"
      sudo sed -i $CONFIG -z -e "s/dpi_output_format=0x6f006\n//"
      sudo sed -i $CONFIG -z -e "s/hdmi_timings=640 0 20 10 10 480 0 10 5 5 0 0 0 60 0 60000000 1\n//"
      sudo sed -i $CONFIG -z -e "s/dtoverlay=ldo_35dpi_3b4b.dtbo\n//"
      sudo sed -i $CONFIG -z -e "s/dtoverlay=ldo_35dpi_3b.dtbo\n//"
      sudo sed -i $CONFIG -z -e "s/dtoverlay=ldo_35dpi_4b.dtbo\n//"
      sudo sed -i $CONFIG -z -e "s/display_lcd_rotate=2\n//"
    fi  
    STATUS=removed
  else
    return $option
  fi
    ok_msg "3.5 Screen Driver ${STATUS}!"

}

function do_43rotatescreen() {
  local option=$1 

  if [[ ${option} -eq 1 ]]; then
    if ! grep -q "display_lcd_rotate=2" $CONFIG ; then
      sudo sed -i $CONFIG -e "s/dtoverlay=vc4-/#dtoverlay=vc4-/"
      sudo sed -i $CONFIG -e "/^\[all\]/a display_lcd_rotate=2"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=rpi-ft5406,touchscreen-inverted-x=1,touchscreen-inverted-y=1"
    fi
    STATUS=enabled
  elif [[ ${option} -eq 2 ]]; then
    if grep -q "display_lcd_rotate=2" $CONFIG ; then
      sudo sed -i $CONFIG -e "s/#dtoverlay=vc4-/dtoverlay=vc4-/"
      sudo sed -i $CONFIG -z -e "s/display_lcd_rotate=2\n//"
      sudo sed -i $CONFIG -z -e "s/dtoverlay=rpi-ft5406,touchscreen-inverted-x=1,touchscreen-inverted-y=1\n//"
    fi  
    STATUS=disabled
  else
    return $RET
  fi
    ok_msg "4.3 Screen Rotation ${STATUS}!"
}


function get_mcus() {
  unset mcu_list
  unset mcu_index
  sleep 1

  mcus=$(lsusb | grep "DFU" | cut -d " " -f 6 2>/dev/null)

  for mcu in ${mcus}; do
    mcu_list+=("${mcu}")
  done

  mcus=$(find /dev/serial/by-id/* 2>/dev/null)
  for mcu in ${mcus}; do
    mcu_list+=("${mcu}")
  done

  mcus=$(find /dev/serial/by-path/* 2>/dev/null)
  for mcu in ${mcus}; do
    mcu_list+=("${mcu}")
  done

  mcus=$(find /dev -maxdepth 1 -regextype posix-extended -regex "^\/dev\/tty(AMA0|S0)$" 2>/dev/null)

  for mcu in ${mcus}; do
    mcu_list+=("${mcu}")
  done
  
}

