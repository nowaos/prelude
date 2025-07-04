#!/bin/bash

ROOT_UID=0
MAX_DELAY=20

THEME_DIR="/usr/share/grub/themes"
THEME_NAME="Prelude"

GRUB_CFG="/etc/default/grub"
BACKUP_CFG="/etc/default/grub.bak"

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

prompt -w "Checking for root access..."

if [ "$UID" -eq "$ROOT_UID" ]; then
  prompt -i "Uninstalling theme"

  # Remove GRUB_THEME line
  if grep -q "^GRUB_THEME=" "$GRUB_CFG"; then
    sed -i '/^GRUB_THEME=/d' "$GRUB_CFG"
    prompt -i "Removed GRUB_THEME from $GRUB_CFG"
  fi

  # Restore backup if it exists
  if [ -f "$BACKUP_CFG" ]; then
    cp -f "$BACKUP_CFG" "$GRUB_CFG"
    prompt -i "Restored backup from $BACKUP_CFG"
  fi

  # Remove theme files
  if [ -d "${THEME_DIR}/${THEME_NAME}" ]; then
    rm -rf "${THEME_DIR:?}/${THEME_NAME}"
    prompt -i "Deleted theme directory: ${THEME_DIR}/${THEME_NAME}"
  fi

  # Update GRUB config
  prompt -i "Updating GRUB configuration..."
  prompt "---"

  if command -v update-grub >/dev/null; then
    update-grub
  elif command -v grub-mkconfig >/dev/null; then
    grub-mkconfig -o /boot/grub/grub.cfg
  elif command -v grub2-mkconfig >/dev/null; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
  fi

  prompt "---"
  prompt -s "Theme uninstalled successfully!"
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

