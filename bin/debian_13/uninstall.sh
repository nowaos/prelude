#!/bin/bash
#
# Removes the Prelude GRUB theme from Debian 13 and restores what the
# install changed, as recorded in /var/lib/nowaos-prelude/state.
#
# The install leaves a copy of this script beside that record, so either of
# these works — the copy needs no repo around it:
#
#   sudo ./bin/debian_13/uninstall.sh
#   sudo /var/lib/nowaos-prelude/bin/debian_13/uninstall.sh

set -e

SH_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SH_ROOT="$(cd "$(dirname "$SH_SCRIPT")/../.." && pwd)"

source "$SH_ROOT/bin/helpers/common.sh"

require_root "$@"

has_command update-grub || abort "update-grub not found. Is this a Debian system?"

load_state

prompt -i "Uninstalling theme..."

### Debian's own theme

# No state file, but a theme on disk, means an install from before Prelude
# kept a record. That version disabled 05_debian_theme unconditionally on
# Debian, so a disabled script next to an installed theme was its doing.
if [ ! -f "$STATE_FILE" ] && [ -d "$THEME_PATH" ] \
  && [ -f "$DEBIAN_THEME" ] && [ ! -x "$DEBIAN_THEME" ]; then
  DEBIAN_THEME_DISABLED="yes"

  prompt -w "No install record found. Assuming an older Prelude disabled ${DEBIAN_THEME}."
fi

# Only give the execute bit back if the install is the one that took it. A
# user who disabled 05_debian_theme themselves keeps it disabled.
if [ "${DEBIAN_THEME_DISABLED:-no}" = "yes" ] && [ -f "$DEBIAN_THEME" ]; then
  chmod +x "$DEBIAN_THEME"

  prompt -i "Re-enabled Debian default theme"
elif [ -f "$DEBIAN_THEME" ] && [ ! -x "$DEBIAN_THEME" ]; then
  prompt -w "${DEBIAN_THEME} is disabled, but not by Prelude. Leaving it alone."
fi

### GRUB config

if [ -f "$GRUB_DROPIN" ]; then
  rm -f "$GRUB_DROPIN"

  prompt -i "Removed ${GRUB_DROPIN}"
fi

# Versions before the drop-in appended GRUB_THEME straight into
# /etc/default/grub. Drop that line if it still points at our theme, and
# leave every other line — including any grub.bak — untouched.
if grep -q "^[[:space:]]*GRUB_THEME=.*${THEME_PATH}" "$GRUB_DEFAULT_FILE" 2>/dev/null; then
  TMP_CFG="$(mktemp)"

  awk -v path="$THEME_PATH" \
    '!($0 ~ /^[[:space:]]*GRUB_THEME=/ && index($0, path))' \
    "$GRUB_DEFAULT_FILE" > "$TMP_CFG"

  cat "$TMP_CFG" > "$GRUB_DEFAULT_FILE"
  rm -f "$TMP_CFG"

  prompt -i "Removed a leftover GRUB_THEME line from ${GRUB_DEFAULT_FILE}"
fi

if [ -f "${GRUB_DEFAULT_FILE}.bak" ]; then
  prompt -w "${GRUB_DEFAULT_FILE}.bak was left by an older install. Delete it yourself if you no longer need it."
fi

### Theme files

if [ -d "$THEME_PATH" ]; then
  rm -rf "${THEME_PATH:?}"

  prompt -i "Deleted theme directory: ${THEME_PATH}"
fi

# A stock Debian has no /usr/share/grub/themes at all — the install's
# mkdir -p created it along with our own directory inside it. Take it back
# out, unless another theme has since moved in.
rmdir "$(dirname "$THEME_PATH")" 2> /dev/null || true

update_grub

# Last, so a failure anywhere above leaves the stashed copy of this script in
# place to be run again. Deleting the directory it is running from is safe:
# the kernel keeps the inode alive until bash closes it.
rm -rf "${STATE_DIR:?}"

prompt -s "Theme uninstalled successfully!"
