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

  # Create themes directory if not exists
  prompt -i "Checking for the existence of themes directory..."

  [[ -d ${THEME_DIR}/${THEME_NAME} ]] && rm -rf ${THEME_DIR}/${THEME_NAME}
  mkdir -p "${THEME_DIR}/${THEME_NAME}"

  # Copy theme
  prompt -i "Installing theme..."

  cp -a ${THEME_SRC}/* ${THEME_DIR}/${THEME_NAME}

  # Disable 05_debian_theme if system is Debian
  if grep -qi 'ID=debian' /etc/os-release || grep -qi 'ID_LIKE=debian' /etc/os-release; then
    if [ -f /etc/grub.d/05_debian_theme ]; then
      chmod -x /etc/grub.d/05_debian_theme

      prompt -w "Debian default theme disabled"
    fi
  fi

  # Set theme
  prompt -i "Setting ${THEME_NAME} as default..."

  # Backup grub config
  cp -an /etc/default/grub /etc/default/grub.bak

  grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub

  echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub

  # Set grub resolution if not already defined
  if ! grep -q "^GRUB_GFXMODE=" /etc/default/grub; then
    DETECTED_RES=""
    
    # Detect resolution from framebuffer or fallback to 1024x768
    if [ -f /sys/class/graphics/fb0/virtual_size ]; then
      DETECTED_RES=$(cat /sys/class/graphics/fb0/virtual_size | tr ',' 'x')
      
      prompt -i "GRUB resolution set to $DETECTED_RES."
    else
      DETECTED_RES="1024x768"
      
      prompt -w "Could not detect screen resolution. Using fallback: $DETECTED_RES"
    fi

    echo "GRUB_GFXMODE=$DETECTED_RES" >> /etc/default/grub
    echo "GRUB_GFXPAYLOAD_LINUX=keep" >> /etc/default/grub
  fi

  # Update grub config
  prompt -i "Updating GRUB config..."
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
  prompt -s "Theme installed successfully!"
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
