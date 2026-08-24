#!/bin/bash
#
# Installs the Prelude GRUB theme on Debian 13.
#
# Everything it touches is recorded in /var/lib/nowaos-prelude/state, and a
# copy of the uninstaller is left there too, so the machine can be put back
# the way it was found even without this repo.
#
# Usage:
#   sudo ./bin/debian_13/install.sh

set -e

SH_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SH_ROOT="$(cd "$(dirname "$SH_SCRIPT")/../.." && pwd)"

source "$SH_ROOT/bin/helpers/common.sh"

THEME_SRC="$SH_ROOT/src"

require_root "$@"

[ -d "$THEME_SRC" ] || abort "No theme sources at $THEME_SRC"
has_command update-grub || abort "update-grub not found. Is this a Debian system?"

# An earlier install already recorded what the machine looked like. Reuse it
# rather than reading the current state, which is the state we ourselves left
# behind: a second run finds 05_debian_theme already disabled and must not
# conclude the user is the one who disabled it.
DEBIAN_THEME_DISABLED="$(state_get DEBIAN_THEME_DISABLED)"
DEBIAN_THEME_DISABLED="${DEBIAN_THEME_DISABLED:-no}"

### Theme files

prompt -i "Installing theme into ${THEME_PATH}..."

rm -rf "${THEME_PATH:?}"
mkdir -p "$THEME_PATH"

cp -a "$THEME_SRC"/* "$THEME_PATH"

### GRUB config

prompt -i "Setting ${THEME_NAME} as default..."

# Only claim the resolution if the user has not picked one themselves. The
# drop-in is sourced after /etc/default/grub, so anything we write here wins.
GFXMODE=""

if ! grep -q "^[[:space:]]*GRUB_GFXMODE=" "$GRUB_DEFAULT_FILE" 2>/dev/null; then
  if [ -r /sys/class/graphics/fb0/virtual_size ]; then
    GFXMODE="$(tr ',' 'x' < /sys/class/graphics/fb0/virtual_size)"

    prompt -i "GRUB resolution set to ${GFXMODE}."
  else
    GFXMODE="1024x768"

    prompt -w "Could not detect screen resolution. Using fallback: ${GFXMODE}"
  fi
fi

mkdir -p "$(dirname "$GRUB_DROPIN")"

{
  echo "# Written by Prelude. Removed by its uninstall. Do not edit."
  echo "GRUB_THEME=\"${THEME_PATH}/theme.txt\""

  if [ -n "$GFXMODE" ]; then
    echo "GRUB_GFXMODE=${GFXMODE}"
    echo "GRUB_GFXPAYLOAD_LINUX=keep"
  fi
} > "$GRUB_DROPIN"

### Debian's own theme

# 05_debian_theme paints desktop-base's wallpaper and colors over the menu.
# Dropping its execute bit is how grub-mkconfig is told to skip a script;
# the uninstall puts the bit back if we were the ones to take it.
if [ -x "$DEBIAN_THEME" ]; then
  chmod -x "$DEBIAN_THEME"

  DEBIAN_THEME_DISABLED="yes"

  prompt -w "Debian default theme disabled"
fi

save_state

stash_uninstaller "$(dirname "$SH_SCRIPT")"

update_grub

prompt -s "Theme installed successfully!"
