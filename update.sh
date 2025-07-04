#!/bin/bash

# Grub2 Theme

ROOT_UID=0
MAX_DELAY=20                                        # max delay for user to enter root password

THEME_DIR="/usr/share/grub/themes"
THEME_SRC=src
THEME_NAME=Prelude

# COLORS

CDEF="\033[0m"                                     # default color
CCIN="\033[0;36m"                                  # info color
CGSC="\033[0;32m"                                  # success color
CRER="\033[0;31m"                                  # error color
CWAR="\033[0;33m"                                  # waring color
b_CDEF="\033[1;37m"                                # bold default color
b_CCIN="\033[1;36m"                                # bold info color
b_CGSC="\033[1;32m"                                # bold success color
b_CRER="\033[1;31m"                                # bold error color
b_CWAR="\033[1;33m"                                # bold warning color

# echo like ...  with  flag type  and display message  colors
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}[ OK ]${CDEF} ${@:2}";;          # print success message
    "-e"|"--error")
      echo -e "${b_CRER}[FAIL]${CDEF} ${@:2}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}[WARN]${CDEF} ${@:2}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}[INFO]${CDEF} ${@:2}";;          # print info message
    *)
    echo -e "$@"
    ;;
  esac
}

# Check command avalibility
function has_command() {
  command -v $1 > /dev/null
}

prompt -w "Checking for root access..."

# Checking for root access and proceed if it is present
if [ "$UID" -eq "$ROOT_UID" ]; then
  prompt -i "Updating theme..."

  # Remove the current theme folder
  [[ -d ${THEME_DIR}/${THEME_NAME} ]] && rm -rf ${THEME_DIR}/${THEME_NAME}
  mkdir -p "${THEME_DIR}/${THEME_NAME}"

  # Copy theme
  cp -a ${THEME_SRC}/* ${THEME_DIR}/${THEME_NAME}

  prompt "---"

  if has_command update-grub; then
    update-grub
  elif has_command grub-mkconfig; then
    grub-mkconfig -o /boot/grub/grub.cfg
  elif has_command grub2-mkconfig; then
    if has_command zypper; then
      grub2-mkconfig -o /boot/grub2/grub.cfg
    elif has_command dnf; then
      grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    fi
  fi

  prompt "---"
  prompt -s "Theme updated successfully!"
else
  prompt -e "Insufficient privileges. Please run as administrator."
  read -p "Enter password: " -t${MAX_DELAY} -s

  prompt "\n"
  
  [[ -n "$REPLY" ]] && {
    sudo -S <<< $REPLY $0
  } || {
    prompt "\nOperation canceled"
    exit 1
  }
fi
