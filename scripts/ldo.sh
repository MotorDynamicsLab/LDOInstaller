#!/usr/bin/env bash
# Part of raspi-config https://github.com/RPi-Distro/raspi-config
#
# See LICENSE file for copyright and license details

set -e

INTERACTIVE=True
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

function calc_wt_size() {
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



function get_boot_splash() {
  if grep -q "splash" $CMDLINE ; then
    echo 0
  else
    echo 1
  fi
}


function get_splash_service() {
  if systemctl status splash.service  | grep -q -w loaded; then
    echo 0
  else
    echo 1
  fi
}

function do_boot_splash() {
  DEFAULT=--defaultno
  if [ $(get_boot_splash) -eq 0 ]; then
    DEFAULT=
  fi
  local mplayer="false"
  if whiptail --yesno "Would you like to show the splash screen at boot?" $DEFAULT 20 60 2 ; then
    RET=$?
  else
    RET=$?
  fi
  ### check system for installed mplayer
  if dpkg -s mplayer 2>/dev/null | grep -q "Status: install ok installed"; then
    mplayer="true"
    else
    mplayer="false"
  fi

  if [ $RET -eq 0 ]; then

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
    STATUS=enabled
  elif [ $RET -eq 1 ]; then
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
    STATUS=disabled
  else
    return $RET
  fi

  if [ -e /boot/firmware/config.txt ] ; then
    sudo rm /boot/cmdline.txt
    sudo rm /boot/config.txt
    sudo ln -s /boot/firmware/cmdline.txt /boot/cmdline.txt
    sudo ln -s /boot/firmware/config.txt /boot/config.txt
  fi

    whiptail --msgbox "Splash screen at boot is $STATUS" 20 60 1
}

function install_35dpi_lcd() {
  DEFAULT=--defaultyes
    if whiptail --yesno "Would you like to install the 3.5 DPI LCD screen?" $DEFAULT 20 60 2 ; then
    RET=$?
  else
    RET=$?
  fi

  if [ $RET -eq 0 ]; then
    sudo cp $HOMEDIR/LDOInstaller/configs/ldo_35dpi_3b4b.dtbo /boot/overlays/ldo_35dpi_3b4b.dtbo
    sudo cp $HOMEDIR/LDOInstaller/configs/ldo_35dpi_3b.dtbo /boot/overlays/ldo_35dpi_3b.dtbo
    sudo cp $HOMEDIR/LDOInstaller/configs/ldo_35dpi_4b.dtbo /boot/overlays/ldo_35dpi_4b.dtbo
    if ! grep -q "dtoverlay=ldo_35dpi_4b.dtbo" $CONFIG ; then
      sudo sed -i $CONFIG -e "/^\[all\]/a gpio=0-9=a2"
      sudo sed -i $CONFIG -e "/^\[all\]/a gpio=12-17=a2"
      sudo sed -i $CONFIG -e "/^\[all\]/a gpio=20-25=a2"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=dpi18"
      sudo sed -i $CONFIG -e "/^\[all\]/a enable_dpi_lcd=1"
      sudo sed -i $CONFIG -e "/^\[all\]/a display_default_lcd=1"
      sudo sed -i $CONFIG -e "/^\[all\]/a extra_transpose_buffer=2"
      sudo sed -i $CONFIG -e "/^\[all\]/a dpi_group=2"
      sudo sed -i $CONFIG -e "/^\[all\]/a dpi_mode=87"
      sudo sed -i $CONFIG -e "/^\[all\]/a dpi_output_format=0x6f006"
      sudo sed -i $CONFIG -e "/^\[all\]/a hdmi_timings=640 0 20 10 10 480 0 10 5 5 0 0 0 60 0 60000000 1"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=ldo_35dpi_3b4b.dtbo"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=ldo_35dpi_3b.dtbo"
      sudo sed -i $CONFIG -e "/^\[all\]/a dtoverlay=ldo_35dpi_4b.dtbo"
    fi
    if ! grep -q "display_lcd_rotate=2" $CONFIG ; then
      sudo sed -i $CONFIG -e "/^\[all\]/a display_lcd_rotate=2"
    fi
    STATUS=installed
  elif [ $RET -eq 1 ]; then 
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
    STATUS=uninstalled
  else
    return $RET
  fi
    whiptail --msgbox "3.5 DPI LCD screen is $STATUS" 20 60 1

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
    echo "${mcu}"
  done
  
}

function select_mcu() {
  unset selected_mcu_id
  local i=0 sel_index=0
  local mcu_type=$1
  declare -a args=(
    --title "Possible MCUs"
    --menu "Select ${mcu_type} MCU:" 25 78 12 --
)

  get_mcus || true

  for mcu in "${mcu_list[@]}"; do
    i=$(( i + 1 ))
    args+=("$i" "$mcu")
  done

  sel_index=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)-1

  if [ ${#mcu_list[@]} -eq 0 ]; then
    whiptail --msgbox "No MCU found!" 20 60 1
    return 1
  fi

  selected_mcu_id="${mcu_list[${sel_index}]}"

}

function select_printer_cfg() {
  local i=0 sel_index=0

  if (( ${#configs[@]} < 1 )); then
    print_error "No configs found!\n MCU either not connected or not detected!"
    return
  fi

declare -a args=(
    --title "Sizes"
    --menu "Choose a size:" 25 78 12 --
)

  for config in "${configs[@]}"; do
    i=$(( i + 1 ))
    echo -e "${i}) PATH: ${cyan}${config}${white}"
    args+=("$i" "$config")
  done

  sel_index=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)-1
  selected_printer_cfg="${configs[${sel_index}]}"
}
