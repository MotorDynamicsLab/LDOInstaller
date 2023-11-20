#!/bin/sh
# Part of raspi-config https://github.com/RPi-Distro/raspi-config
#
# See LICENSE file for copyright and license details

INTERACTIVE=True
ASK_TO_REBOOT=0
RCLOCAL=/etc/rc.local

if [ -e /boot/firmware/config.txt ] ; then
  FIRMWARE=/firmware
else
  FIRMWARE=
fi
CONFIG=/boot${FIRMWARE}/config.txt

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

set_config_var() {
  lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

clear_config_var() {
  lua - "$1" "$2" <<EOF > "$2.bak"
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
  if line:match("^%s*"..key.."=.*$") then
    line="#"..line
  end
  print(line)
end
EOF
mv "$2.bak" "$2"
}

get_config_var() {
  lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
local found=false
for line in file:lines() do
  local val = line:match("^%s*"..key.."=(.*)$")
  if (val ~= nil) then
    print(val)
    found=true
    break
  end
end
if not found then
   print(0)
end
EOF
}

do_finish() {
  if [ $ASK_TO_REBOOT -eq 1 ]; then
    whiptail --yesno "Would you like to reboot now?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      sync
      reboot
    fi
  fi
  exit 0
}

get_boot_splash() {
  if grep -q "splash" $CMDLINE ; then
    echo 0
  else
    echo 1
  fi
}


get_spash_service() {
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
  if [ "$INTERACTIVE" = True ]; then
    whiptail --yesno "Would you like to show the splash screen at boot?" $DEFAULT 20 60 2
    RET=$?
  else
    RET=$1
  fi
  if [ $RET -eq 0 ]; then
    if ! grep -q "splash" $CMDLINE ; then
      sed -i $CMDLINE -e "s/$/ consoleblank=1 logo.nologo quiet loglevel=0 plymouth.enable=0 vt.global_cursor_default=0 plymouth.ignore-serial-consoles splash fastboot noatime nodiratime noram/"
      cp $HOMEDIR/LDOSetup/splash/splash.service /etc/systemd/system/splash.service
      sed -i /etc/systemd/system/splash.service -e "/^\[Service\]/a ExecStart=/usr/bin/mplayer -vf scale=${FBRES} -vo fbdev2 ${HOMEDIR}/LDOSetup/splash/ldo.mp4 &> /dev/null"
      systemctl enable splash.service
    fi
    set_config_var disable_splash 1 $CONFIG
    if ! grep -q "ldospin" $RCLOCAL ; then
      sed -i $RCLOCAL -e "/^exit 0/i dmesg --console-off"
      sed -i $RCLOCAL -e "/^exit 0/i /usr/bin/mplayer -vf scale=${FBRES} -vo fbdev2 ${HOMEDIR}/LDOSetup/splash/ldospin.mp4 &> /dev/null"
    fi
    STATUS=enabled
  elif [ $RET -eq 1 ]; then
    if grep -q "splash" $CMDLINE ; then
      sed -i $CMDLINE -e "s/ consoleblank=1//"
      sed -i $CMDLINE -e "s/ quiet//"
      sed -i $CMDLINE -e "s/ plymouth.ignore-serial-consoles//"
      sed -i $CMDLINE -e "s/ logo.nologo//"
      sed -i $CMDLINE -e "s/ loglevel=0//"
      sed -i $CMDLINE -e "s/ plymouth.enable=0//"
      sed -i $CMDLINE -e "s/ vt.global_cursor_default=0//"
      sed -i $CMDLINE -e "s/ splash//"
      sed -i $CMDLINE -e "s/ fastboot//"
      sed -i $CMDLINE -e "s/ noatime//"
      sed -i $CMDLINE -e "s/ nodiratime//"
      sed -i $CMDLINE -e "s/ noram//"
    fi
    clear_config_var disable_splash $CONFIG
    if grep -q "ldospin" $RCLOCAL ; then
      sed -i $RCLOCAL -z -e "s/dmesg --console-off\n//"
      sed -i $RCLOCAL -z -e "s|/usr/bin/mplayer -vf scale=${FBRES} -vo fbdev2 ${HOMEDIR}/LDOSetup/splash/ldospin.mp4 &> /dev/null\n||"
    fi
    if [ $(get_spash_service) -eq 0 ]; then
      systemctl disable splash.service 
    fi
    STATUS=disabled
  else
    return $RET
  fi
  if [ "$INTERACTIVE" = True ]; then
    whiptail --msgbox "Splash screen at boot is $STATUS" 20 60 1
  fi
}

#
# Interactive use loop
#
if [ "$INTERACTIVE" = True ]; then
  [ -e $CONFIG ] || touch $CONFIG
  calc_wt_size
  while true; do
      FUN=$(whiptail --title "LDO Installer" --backtitle "LDO" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
        "1 Splash Screen" "Enable/Disable" \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      do_finish
    elif [ $RET -eq 0 ]; then
      case "$FUN" in
        1\ *) do_boot_splash ;;
        *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
    else
      exit 1
    fi
  done
fi