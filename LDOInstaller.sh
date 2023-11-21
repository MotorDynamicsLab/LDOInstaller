#!/usr/bin/env bash

#=======================================================================#
# Copyright (C) 2023 - 2023 LDO Motors                                  #
#                                                                       #
# This file is part of LDO Setup                                        #
# https://github.com/MotorDynamicsLab/LDOSetup.git                      # 
#                                                                       #
# Which calls scripts from through symlinks                             #
# KIAUH - Klipper Installation And Update Helper                        #
# https://github.com/dw-0/kiauh                                         #
#                                                                       #
# This file may be distributed under the terms of the GNU GPLv3 license #
#=======================================================================#

set -e
clear

 #=============== KIAUH ================#
KIAUH_SRCDIR="${HOME}/kiauh"
KIAUH_REPO="https://github.com/dw-0/kiauh.git"

 #=============== LDOInstaller ================#
LDOINSTALLER_DIR="${HOME}/LDOInstaller"
LDOINSTALLER_REPO="https://github.com/MotorDynamicsLab/LDOInstaller.git"


### sourcing include scripts
if [ -d "${KIAUH_SRCDIR}" ]; then
    for script in "${KIAUH_SRCDIR}/scripts/ui/"*.sh; do . "${script}"; done
    for script in "${KIAUH_SRCDIR}/scripts/"*.sh; do . "${script}"; done
    for script in "${LDOINSTALLER_DIR}/scripts/ui/"*.sh; do . "${script}"; done
    for script in "${LDOINSTALLER_DIR}/scripts/"*.sh; do . "${script}"; done
  echo -e "OK"
  init_logfile
  set_globals
  ldo_menu
else
  echo -e "Please install KIAUH first! then install Klipper with KIAUH and then run this script again!"
  echo -e "1) sudo apt-get update && sudo apt-get install git -y"
  echo -e "2) cd ~ && git clone https://github.com/dw-0/kiauh.git"
  echo -e "3) ./kiauh/kiauh.sh"
  exit 0
fi

