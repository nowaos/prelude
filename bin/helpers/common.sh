#!/bin/bash
#
# Helpers shared by the install and uninstall scripts.
#
# Sourced by each script after it resolves SH_ROOT (the repo root).

### Paths

THEME_NAME="Prelude"
THEME_DIR="/usr/share/grub/themes"
THEME_PATH="${THEME_DIR}/${THEME_NAME}"

# Debian's grub-mkconfig sources /etc/default/grub, then every .cfg in
# /etc/default/grub.d. Owning a file there means the uninstall is a single
# rm, and /etc/default/grub is never touched.
GRUB_DEFAULT_FILE="/etc/default/grub"
GRUB_DROPIN="/etc/default/grub.d/prelude.cfg"

# The Debian script that paints desktop-base's background over the menu.
DEBIAN_THEME="/etc/grub.d/05_debian_theme"

# What the install changed, so the uninstall restores only that — next to a
# copy of the uninstaller itself, so the theme can still be removed from a
# machine that no longer has the repo.
STATE_DIR="/var/lib/nowaos-prelude"
STATE_FILE="${STATE_DIR}/state"

ROOT_UID=0

### Output

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

abort() {
  prompt -e "$@"
  exit 1
}

### Running

# Check command avalibility
has_command() {
  command -v $1 > /dev/null
}

# Re-run the current script under sudo. Passing the arguments along keeps
# `install.sh --something` working when it re-execs.
require_root() {
  [ "$UID" -eq "$ROOT_UID" ] && return 0

  prompt -w "Root access required, re-running under sudo..."

  has_command sudo || abort "Insufficient privileges and sudo is not available."

  exec sudo -- "$SH_SCRIPT" "$@"
}

### State
#
# A plain key=value file, written by the install and read by the uninstall.
# Only the install may have changed the system, so only it knows what the
# machine looked like beforehand.

# Read the whole record, overriding the paths above with the ones actually
# installed. The uninstall wants this: it must remove what is on disk, not
# what this version of the script would install today.
load_state() {
  [ -f "$STATE_FILE" ] && . "$STATE_FILE"

  return 0
}

# Read one value, leaving everything else alone. The install wants this: it
# writes to the paths above, and only looks back for what it cannot observe.
state_get() {
  local key="$1"

  [ -f "$STATE_FILE" ] || return 0

  sed -n "s/^${key}=\"\(.*\)\"$/\1/p" "$STATE_FILE"
}

save_state() {
  mkdir -p "$STATE_DIR"

  cat > "$STATE_FILE" << EOF
# Written by Prelude's install. Read by its uninstall. Do not edit.
THEME_PATH="${THEME_PATH}"
GRUB_DROPIN="${GRUB_DROPIN}"
DEBIAN_THEME_DISABLED="${DEBIAN_THEME_DISABLED}"
EOF
}

### Stashing
#
# The repo is not around forever: it may have been a tarball in /tmp, or a
# clone the user has since deleted. Leave a working uninstaller behind.

# Copies the uninstaller and its helpers into STATE_DIR, keeping the repo's
# layout. That is the whole trick: the copy resolves bin/helpers/common.sh
# through the same relative path the original does, so there is no second
# code path to keep correct. src/ is left out — removing a theme never reads
# the theme.
stash_uninstaller() {
  local os_dir="$1"
  local os

  os="$(basename "$os_dir")"

  mkdir -p "$STATE_DIR/bin/helpers" "$STATE_DIR/bin/$os"

  cp "$SH_ROOT/bin/helpers/common.sh" "$STATE_DIR/bin/helpers/common.sh"
  cp "$os_dir/uninstall.sh" "$STATE_DIR/bin/$os/uninstall.sh"

  chmod +x "$STATE_DIR/bin/$os/uninstall.sh"
}

### GRUB

update_grub() {
  prompt -i "Updating GRUB config..."
  prompt "---"

  update-grub

  prompt "---"
}
