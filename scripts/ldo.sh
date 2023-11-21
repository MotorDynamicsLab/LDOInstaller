#!/usr/bin/env bash
# Part of raspi-config https://github.com/RPi-Distro/raspi-config
#
# See LICENSE file for copyright and license details

set -e

INTERACTIVE=True
ASK_TO_REBOOT=0
RCLOCAL=/etc/rc.local
CONFIG=/boot/firmware/config.txt

USER=${SUDO_USER:-$(who -m | awk '{ print $1 }')}
if [ -z "$USER" ] && [ -n "$HOME" ]; then
  USER=$(getent passwd | awk -F: "\$6 == \"$HOME\" {print \$1}")
fi
if [ -z "$USER" ] || [ "$USER" = "root" ]; then
  USER=$(getent passwd | awk -F: '$3 == "1000" {print $1}')
fi

if [ -e /proc/device-tree/chosen/os_prefix ]; then
  PREFIX="$(cat /proc/device-tree/chosen/os_prefix)"
fi
CMDLINE="/boot${FIRMWARE}/${PREFIX}cmdline.txt"

INIT="$(ps --no-headers -o comm 1)"

HOMEDIR="$(getent passwd "$USER" | cut -d: -f6)"

FBRES="$(cat /sys/class/graphics/fb0/virtual_size | sed -r 's/,/:/')" # get current framebuffer resolution

calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error
  # output from tput. However in this case, tput detects neither stdout or
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=18
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$((WT_HEIGHT - 7))
}

get_boot_splash() {
  if grep -q "splash" $CMDLINE ; then
    echo 0
  else
    echo 1
  fi
}


get_splash_service() {
  if systemctl status splash.service  | grep -q -w loaded; then
    echo 0
  else
    echo 1
  fi
}

do_boot_splash() {
  DEFAULT=--defaultno
  if [ $(get_boot_splash) -eq 0 ]; then
    DEFAULT=
  fi

  if whiptail --yesno "Would you like to show the splash screen at boot?" $DEFAULT 20 60 2 ; then
    RET=$?
  else
    RET=$?
  fi

  if [ $RET -eq 0 ]; then
    if ! grep -q "splash" $CMDLINE ; then
      sudo sed -i $CMDLINE -e "s/$/ consoleblank=1 logo.nologo quiet loglevel=0 plymouth.enable=0 vt.global_cursor_default=0 plymouth.ignore-serial-consoles splash fastboot noatime nodiratime noram/"
    fi
    #set_config_var disable_splash 1 $CONFIG
    if ! grep -q "disable_splash=1" $CONFIG ; then
      sudo sed -i $CONFIG -e "/^\[all\]/a disable_splash=1"
    fi
    if ! grep -q "ldospin" $RCLOCAL ; then
      sudo sed -i $RCLOCAL -e "/^exit 0/i dmesg --console-off"
      sudo sed -i $RCLOCAL -e "/^exit 0/i /usr/bin/mplayer -vf scale=${FBRES} -vo fbdev2 ${HOMEDIR}/LDOInstaller/splash/ldospin.mp4 &> /dev/null"
    fi
    if [ $(get_splash_service) -eq 1 ]; then
      sudo cp $HOMEDIR/LDOInstaller/splash/splash.service /etc/systemd/system/splash.service
      sudo sed -i /etc/systemd/system/splash.service -e "/^\[Service\]/a ExecStart=/usr/bin/mplayer -vf scale=${FBRES} -vo fbdev2 ${HOMEDIR}/LDOInstaller/splash/ldo.mp4 &> /dev/null"
      sudo systemctl enable splash.service
    fi
    STATUS=enabled
  elif [ $RET -eq 1 ]; then
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
    if grep -q "ldospin" $RCLOCAL ; then
      sudo sed -i $RCLOCAL -z -e "s/dmesg --console-off\n//"
      sudo sed -i $RCLOCAL -z -e "s|/usr/bin/mplayer -vf scale=${FBRES} -vo fbdev2 ${HOMEDIR}/LDOInstaller/splash/ldospin.mp4 &> /dev/null\n||"
    fi
    if [ $(get_splash_service) -eq 0 ]; then
      sudo systemctl disable splash.service 
      sudo rm /etc/systemd/system/splash.service
    fi
    STATUS=disabled
  else
    return $RET
  fi
    whiptail --msgbox "Splash screen at boot is $STATUS" 20 60 1
}


function rotatescreen() {

  DEFAULT=--defaultno

  if whiptail --yesno "Would you like to rotate the screen?" $DEFAULT 20 60 2 ; then
    RET=$?
  else
    RET=$?
  fi

  if [ $RET -eq 0 ]; then
    if ! grep -q "display_lcd_rotate=2" $CONFIG ; then
      sudo sed -i $CONFIG -e "s/dtoverlay=vc4-/#dtoverlay=vc4-/"
      sudo sed -i $CONFIG -e "/^\[all\]/a display_lcd_rotate=2"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=rpi-ft5406,touchscreen-inverted-x=1,touchscreen-inverted-y=1"
    fi
    STATUS=enabled
  elif [ $RET -eq 1 ]; then 
    if grep -q "display_lcd_rotate=2" $CONFIG ; then
      sudo sed -i $CONFIG -e "s/#dtoverlay=vc4-/dtoverlay=vc4-/"
      sudo sed -i $CONFIG -z -e "s/display_lcd_rotate=2\n//"
      sudo sed -i $CONFIG -z -e "s/dtoverlay=rpi-ft5406,touchscreen-inverted-x=1,touchscreen-inverted-y=1\n//"
    fi  
    STATUS=disabled
  else
    return $RET
  fi
    whiptail --msgbox "Screen rotation is $STATUS" 20 60 1
}
