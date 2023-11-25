#!/usr/bin/env bash

#=======================================================================#
# Copyright (C) 2023 - 2023 LDO Motors                                  #
#                                                                       #
# This file is part of LDO Installer                                    #
# https://github.com/MotorDynamicsLab/LDOInstaller.git                  # 
#                                                                       #
# Which calls scripts from through symlinks                             #
# KIAUH - Klipper Installation And Update Helper                        #
# https://github.com/dw-0/kiauh                                         #
#                                                                       #
# This file may be distributed under the terms of the GNU GPLv3 license #
#=======================================================================#

set -e
unset -f print_header



function print_header() {
  top_border
  echo -e "|     $(title_msg "~~~~~~~~~~~~~ [ LDO Installer ] ~~~~~~~~~~~~~")     |"
  echo -e "|     $(title_msg "   Printer Installation and Configuration    ")     |"
  echo -e "|     $(title_msg "                        Thank You - KIAUH    ")     |"
  echo -e "|     $(title_msg "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")     |"
  bottom_border
}

function ldoinstaller_ui() {
  top_border
  echo -e "|    ${yellow}~~~~~~~~~~~~~~ [ LDO Main Menu ] ~~~~~~~~~~~~~${white}     |"
  hr
  echo -e "|                  Configure Klipper                    |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|  Select LDO Kit:                                      |"
  echo -e "|  1) [Voron 0]                                         |"
  echo -e "|  2) [Voron 2.4]                                       |"
  echo -e "|  3) [Voron Trident]                                   |"
  echo -e "|  4) [Voron Switchwire]                                |"
  echo -e "|  5) [Positron]                                        |"
  echo -e "|                                                       |"
  echo -e "|  6) [Rotate Screen (BTT/Waveshare)]                   |"
  echo -e "|  7) [Splash Screen]                                   |"
  quit_footer
}

function ldo_menu() {

  ### return early if klipper is not installed
  local klipper_services
  klipper_services=$(klipper_systemd)
  if [[ -z ${klipper_services} ]]; then
    local error="Klipper not installed! Please install Klipper first!"
    log_error "LDO Setup started without Klipper being installed. Aborting setup."
    print_error "${error}" && return
  fi

  do_action "" "ldoinstaller_ui"
  local regex line gcode_dir
  unset selected_mcu_id
  unset selected_printer_cfg
  unset mcu_list

  regex="${HOME//\//\\/}\/([A-Za-z0-9_]+)\/config\/printer\.cfg"
  #configs=$(find "${HOME}" -maxdepth 3 -regextype posix-extended -regex "${regex}" | sort)
  mapfile -t configs < <(find "${HOME}" -maxdepth 3 -regextype posix-extended -regex "${regex}" | sort)
  if [[ -z ${configs} ]]; then
    print_error "No printer.cfg found! Installation of Macros will be skipped ..."
    log_error "execution stopped! reason: no printer.cfg found in ${HOME}"
    return
  fi

  for config in ${configs}; do
    path=$(echo "${config}" | rev | cut -d"/" -f2- | rev)
  done

  local action
  while true; do
    read -p "${cyan}####### Perform action:${white} " action
    case "${action}" in
      1)
        do_action "ldov0_ui";;
      2)
        do_action "ldov24_ui";;
      3)
        do_action "ldovt_ui";;
      4)
        do_action "ldosw_ui";;
      5)
        do_action "ldopv_ui";;
      6)
        clear && print_header
        do_43rotatescreen
        ldoinstaller_ui;;
      7)
        clear && print_header
        ldosplash_ui
        ldoinstaller_ui;;
      Q|q)
        echo -e "${green}###### Happy printing! ######${white}"; echo
        exit 0;;
      *)
        deny_action "ldoinstaller_ui";;
    esac
  done
  ldo_menu
}

function ldov0_ui() {
  top_border
  echo -e "|      ${yellow}~~~~~~~~~~~~~ [ LDO V0 Menu ] ~~~~~~~~~~~~~${white}      |"
  hr
  echo -e "|                  Configure Klipper                    |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|  Select V0.1 Revision:                                |"
  echo -e "|  1) [Rev A/B/C/D]                                     |"
  hr
  echo -e "|  Select V0.1-S1 Revision:                             |"
  echo -e "|  2) [Rev E]                                           |"
  echo -e "|                                                       |"
  hr
  echo -e "|  Select V0.2-S1 Revision:                             |"
  echo -e "|  3) [Rev A/A+]                                        |"
  echo -e "|                                                       |"
  back_footer

  local action
  while true; do
    read -p "${cyan}###### Perform action:${white} " action
    case "${action}" in
      1)
        select_msg "V0.1 Rev A/B/C/D"
        ldoinstaller "V01" "A0" "00" 120 120 120
        ldo_menu;;
      2)
        select_msg "V0.1-S1 Rev E"
        ldoinstaller "V01" "E0" "00" 120 120 120
        ldo_menu;;
      3)
        select_msg "V0.2-S1 Rev A/A+"
        ldoinstaller "V02" "A0" "00" 120 120 120
        ldo_menu;;

      B|b)
        clear; ldo_menu; break;;
      *)
        error_msg "Invalid command!";;
    esac
  done
}

function ldov24_ui() {
  top_border
  echo -e "|     ${yellow}~~~~~~~~~~~~~ [ LDO V2.4 Menu ] ~~~~~~~~~~~~~${white}     |"
  hr
  echo -e "|                  Configure Klipper                    |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|  V2.4 Rev A/B Revision:                               |"
  echo -e "|  Select printer size                                  |"
  echo -e "|  1) [250mm]                                           |"
  echo -e "|  2) [300mm]                                           |"
  echo -e "|  3) [350mm]                                           |"
  echo -e "|                                                       |"
  echo -e "|  V2.4 Rev C Revision:                                 |"
  echo -e "|  Select printer size                                  |"
  echo -e "|  4) [250mm]                                           |"
  echo -e "|  5) [300mm]                                           |"
  echo -e "|  6) [350mm]                                           |"
  echo -e "|                                                       |"
  back_footer

  local action
  while true; do
    read -p "${cyan}###### Perform action:${white} " action
    case "${action}" in
      1)
        select_msg "Rev A/B 250mm"
        ldoinstaller "V24" "B0" "00" 250 250 200
        ldo_menu;;
      2)
        select_msg "Rev A/B 300mm"
        ldoinstaller "V24" "B0" "00" 300 300 250
        ldo_menu;;
      3)
        select_msg "Rev A/B 300mm"
        ldoinstaller "V24" "B0" "00" 350 350 300
        ldo_menu;;
      4)
        select_msg "Rev C 250mm"
        ldoinstaller "V24" "C0" "00" 250 250 200
        ldo_menu;;
      5)
        select_msg "Rev C 350mm"
        ldoinstaller "V24" "C0" "00" 300 300 250
        ldo_menu;;
      6)
        select_msg "Rev C 350mm"
        ldoinstaller "V24" "C0" "00" 350 350 300
        ldo_menu;;
      B|b)
        clear; ldo_menu; break;;
      *)
        error_msg "Invalid command!";;
    esac
  done
}

function ldovt_ui() {
  top_border
  echo -e "|   ${yellow}~~~~~~~~~~~~~ [ LDO Trident Menu ] ~~~~~~~~~~~~~${white}   |"
  hr
  echo -e "|                  Configure Klipper                    |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|  Trident Rev A/B Revision:                            |"
  echo -e "|  Select printer size                                  |"
  echo -e "|  1) [250mm]                                           |"
  echo -e "|  2) [300mm]                                           |"
  echo -e "|                                                       |"
  echo -e "|  Trident Rev C Revision:                              |"
  echo -e "|  Select printer size                                  |"
  echo -e "|  3) [250mm]                                           |"
  echo -e "|  4) [300mm]                                           |"
  echo -e "|                                                       |"
  back_footer

  local action
  while true; do
    read -p "${cyan}###### Perform action:${white} " action
    case "${action}" in
      1)
        select_msg "Rev A/B 250mm"
        ldoinstaller "VT0" "B0" "00" 250 250 200
        ldo_menu;;
      2)
        select_msg "Rev A/B 300mm"
        ldoinstaller "VT0" "B0" "00" 300 300 250
        ldo_menu;;
      3)
        select_msg "Rev C 250mm"
        ldoinstaller "VT0" "C0" "00" 250 250 200
        ldo_menu;;
      4)
        select_msg "Rev C 350mm"
        ldoinstaller "VT0" "C0" "00" 300 300 250
        ldo_menu;;
      B|b)
        clear; ldo_menu; break;;
      *)
        error_msg "Invalid command!";;
    esac
  done
}

function ldovsw_ui() {
  top_border
  echo -e "|  ${yellow}~~~~~~~~~~~~~ [ LDO Switchwire Menu ] ~~~~~~~~~~~~~${white}   |"
  hr
  echo -e "|                  Configure Klipper                    |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|  Configure Klipper:                                   |"
  echo -e "|  1) [250mm]                                           |"
  echo -e "|  2) [300mm]                                           |"
  echo -e "|                                                       |"
  back_footer
}

function ldopv_ui() {
  top_border
  echo -e "|  ${yellow}~~~~~~~~~~~~~~ [ LDO Positron Menu ] ~~~~~~~~~~~~~~${white}   |"
  hr
  echo -e "|                  Configure Klipper                    |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|  3.5 Display Driver:                                  |"
  echo -e "|  1) [Install]                                         |"
  echo -e "|  2) [Remmove]                                         |"
  echo -e "|                                                       |"
  echo -e "|  Configure Klipper:                                   |"
  echo -e "|  2) [Rev A]                                           |"
  echo -e "|                                                       |"
  back_footer
  local action
  while true; do
    read -p "${cyan}###### Perform action:${white} " action
    case "${action}" in
      1)
        select_msg "Install 3.5 Display Driver"
        do_35dpi_lcd 1
        ldo_menu;;
      2)
        select_msg "Remove 3.5 Display Driver"
        do_35dpi_lcd 2
        ldo_menu;;
      3)
        select_msg "Rev C 250mm"
        ldoinstaller "PV3" "A0" "00" 0 0 0
        ldo_menu;;
      B|b)
        clear; ldo_menu; break;;
      *)
        error_msg "Invalid command!";;
    esac
  done

}

function ldosplash_ui() {
  top_border
  echo -e "|  ${yellow}~~~~~~~~~~~~~~~~~~ [ LDO Menu ] ~~~~~~~~~~~~~~~~~~${white}   |"
  hr
  echo -e "|                  LDO Splash Screen                    |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|                                                       |"
  echo -e "|  1) [Install]                                         |"
  echo -e "|  2) [Remove]                                          |"
  echo -e "|                                                       |"
  back_footer

  local action
  while true; do
    read -p "${cyan}###### Perform action:${white} " action
    case "${action}" in
      1)
        select_msg "Install Splash Screen"
        do_boot_splash 1
        ldo_menu;;
      2)
        select_msg "Remove Splash Screen"
        do_boot_splash 2
        ldo_menu;;
      B|b)
        clear; ldo_menu; break;;
      *)
        error_msg "Invalid command!";;
    esac
  done
}


function 43rotatescreen_ui() {
  top_border
  echo -e "|  ${yellow}~~~~~~~~~~~~~~~~~~ [ LDO Menu ] ~~~~~~~~~~~~~~~~~~${white}   |"
  hr
  echo -e "|                  Rotate 4.3 Screen                    |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|                                                       |"
  echo -e "|  1) [Enable]                                          |"
  echo -e "|  2) [Disable]                                         |"
  echo -e "|                                                       |"
  back_footer

  local action
  while true; do
    read -p "${cyan}###### Perform action:${white} " action
    case "${action}" in
      1)
        select_msg "Install Splash Screen"
        do_43rotatescreen 1
        ldo_menu;;
      2)
        select_msg "Remove Splash Screen"
        do_43rotatescreen 2
        ldo_menu;;
      B|b)
        clear; ldo_menu; break;;
      *)
        error_msg "Invalid command!";;
    esac
  done
}

function ldoprintercfg_ui() {
  local i str
  top_border
  echo -e "|  ${yellow}~~~~~~~~~~~~~~~~~~ [ LDO Menu ] ~~~~~~~~~~~~~~~~~~${white}   |"
  hr
  echo -e "|                  LDO Printer Config                   |"
  echo -e "|-------------------------------------------------------|"
  echo -e "|                                                       |"
  for config in "${configs[@]}"; do
    i=$(( i + 1 ))
    str="|  ${i}) ${config}                                                       "
    echo -e "${str:0:56}|"
    args+=("$i" "$config")
  done
  echo -e "|                                                       |"
  back_footer

  local action
  while true; do
    read -p "${cyan}###### Perform action:${white} " action
    if [[ ${action} -gt 0 ]] && [[ ${action} -le ${#configs[@]} ]]; then
      selected_printer_cfg="${configs[${action}-1]}"
      break
    fi
    case "${action}" in
      B|b)
        clear; ldo_menu; break;;
      *)
        error_msg "Invalid command!";;
    esac
  done
}

function ldoprintermcu_ui() {
  local i str mcu_type=$1
  top_border
  echo -e "|  ${yellow}~~~~~~~~~~~~~~~~~~ [ LDO Menu ] ~~~~~~~~~~~~~~~~~~${white}   |"
  hr
  str="|                  LDO ${mcu_type}                                           "
  echo -e "${str:0:56}|"
  echo -e "|-------------------------------------------------------|"
  echo -e "|                                                       |"

  get_mcus || true

  for mcu in "${mcu_list[@]}"; do
    i=$(( i + 1 ))
    str="|  ${i}) ${mcu}                                                       "
    echo -e "${str:0:56}|"
    args+=("$i" "$mcu")
  done
  echo -e "|                                                       |"
  back_footer

  local action
  while true; do
    read -p "${cyan}###### Perform action:${white} " action
    if [[ ${action} -gt 0 ]] && [[ ${action} -le ${#mcu_list[@]} ]]; then
        selected_mcu_id="${mcu_list[${action}-1]}"
      break
    fi
    case "${action}" in
      B|b)
        clear; ldo_menu; break;;
      *)
        error_msg "Invalid command!";;
    esac
  done
}


function download_ldo_configs() {
  local ms_cfg_repo path configs regex line gcode_dir

  status_msg "Cloning ldoinstaller ..."
  [[ -d "${HOME}/ldoinstaller" ]] && rm -rf "${HOME}/ldoinstaller"
  if git clone --recurse-submodules "${LDOINSTALLER_REPO}" "${HOME}/ldoinstaller"; then
    ok_msg "Done!"
  else
    print_error "Cloning failed! Aborting installation ..."
    log_error "execution stopped! reason: cloning failed"
    return
  fi
}

function ldoinstaller() {
  local printer=$1 rev=$2 ver=$3
  local max_x=$4 max_y=$5 max_z=$6
  local configfilename="${printer}-${rev}-${ver}.cfg"

  if [[ $max_x == $max_y ]]; then
    max_xy=$max_x
  else
    max_xy=$max_x,$max_y
  fi
  ldoprintercfg_ui
  echo -e "\n${configfilename}\n"

        ldoprintermcu_ui "Mainboard"
        status_msg "Configuring ${selected_printer_cfg} ..."
          if [[ -e "${selected_printer_cfg}" && ! -h "${selected_printer_cfg}" ]]; then
            warn_msg "Attention! Existing printer.cfg detected!"
            warn_msg "The file will be copied to 'printer.bak.cfg' to be able to continue with the installation."
            if ! cp "${selected_printer_cfg}" "${selected_printer_cfg}.bak"; then
              error_msg "Copying printer.cfg failed! Aborting installation ..."
              return
            fi
          fi
        if ! sudo cp "${HOME}/LDOInstaller/configs/${configfilename}" "${selected_printer_cfg}"; then
          error_msg "Creating ${path}/printer.cfg failed! Aborting installation ..."
          return
        else
          status_msg "Setting MCU ${selected_mcu_id} in ${selected_printer_cfg}..."
          log_info "${path}/printer.cfg"

          sudo sed -i "s|#{serial_mcu}#|$selected_mcu_id|gi" "${selected_printer_cfg}"

          if grep -Eq "#{serial_mcu_umb}#" "${selected_printer_cfg}"; then
            ldoprintermcu_ui  "Umbilical"
            status_msg "Setting MCU ${selected_mcu_id} in ${selected_printer_cfg}..."
            sudo sed -i "s|#{serial_mcu_umb}#|$selected_mcu_id|gi" "${selected_printer_cfg}"
          fi

          if grep -Eq "#{serial_mcu_pth}#" "${selected_printer_cfg}"; then
            ldoprintermcu_ui  "Toolhead"
            status_msg "Setting MCU ${selected_mcu_id} in ${selected_printer_cfg}..."
            sudo sed -i "s|#{serial_mcu_pth}#|$selected_mcu_id|gi" "${selected_printer_cfg}"
          fi

          status_msg "Setting up ${selected_printer_cfg}..."
          sed -i "s|#{max_xy}#|$max_xy|gi" "${selected_printer_cfg}"
          sed -i "s|#{max_z}#|$max_z|gi" "${selected_printer_cfg}"
          # Set Gantry Points
          sed -i "s|#{max_xy_a60}#|$(($max_xy+60))|gi" "${selected_printer_cfg}"
          sed -i "s|#{max_xy_a70}#|$(($max_xy+70))|gi" "${selected_printer_cfg}"
          sed -i "s|#{max_xy_s75}#|$(($max_xy-75))|gi" "${selected_printer_cfg}"
          sed -i "s|#{max_xy_s50}#|$(($max_xy-50))|gi" "${selected_printer_cfg}"

          sed -i "s|#{max_x_d2}#|$(($max_x/2))|gi" "${selected_printer_cfg}"
          sed -i "s|#{max_y_d2}#|$(($max_y/2))|gi" "${selected_printer_cfg}"

          sed -i "s|#{max_xy_a48}#|$(($max_xy+48))|gi" "${selected_printer_cfg}"
          sed -i "s|#{max_xy_a50}#|$(($max_xy+50))|gi" "${selected_printer_cfg}"
          sed -i "s|#{max_xy_s55}#|$(($max_xy-55))|gi" "${selected_printer_cfg}"
          sed -i "s|#{max_xy_s30}#|$(($max_xy-30))|gi" "${selected_printer_cfg}"

          # if ! grep -Eq "^\[include mainsail.cfg\]$" "${path}/printer.cfg"; then
          #   log_info "${path}/printer.cfg"
          #   sed -i $CONFIG -e "/^\[mcu\]/i [include mainsail.cfg]" "${path}/printer.cfg"
          # fi
          if ! grep -Eq "^\[include fluidd.cfg\]$" "${path}/printer.cfg"; then
            log_info "${path}/printer.cfg"
            sed -i -e "/^\[mcu\]/i[include fluidd.cfg]" "${path}/printer.cfg"
          fi

          gcode_dir=${path/config/gcodes}
          if ! grep -Eq "^\[virtual_sdcard\]$" "${path}/printer.cfg"; then
            log_info "${path}/printer.cfg"
            sed -i -e "/^\[mcu\]/i[virtual_sdcard]\npath: ${gcode_dir}\non_error_gcode: CANCEL_PRINT\n" "${path}/printer.cfg"
          fi

          read -p "LDO Setup Complete. Press [Enter] to continue..."
        fi
}


function buzz_steppers() {
  echo "FIRMWARE_RESTART" >> ~/printer_data/comms/klippy.serial
  echo "STEPPER_BUZZ STEPPER=stepper_x" >> ~/printer_data/comms/klippy.serial
}

