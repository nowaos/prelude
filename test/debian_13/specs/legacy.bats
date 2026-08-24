#!/usr/bin/env bats
#
# Upgrading from the version that kept no record.
#
# That install edited /etc/default/grub directly and disabled Debian's theme
# script without writing down that it had. The current uninstall has to clean
# up after it anyway.

load ../support/helper

@test "uninstall cleans up an install from before the state file existed" {
  # What the old script left: the theme in place, GRUB_THEME appended
  # straight into /etc/default/grub, and no record of any of it.
  mkdir -p "$THEME"
  cp -a /repo/src/* "$THEME"
  chmod -x "$DEBIAN_THEME"
  echo "GRUB_THEME=\"${THEME}/theme.txt\"" >> "$GRUB_DEFAULT"

  run "$UNINSTALL"

  [ "$status" -eq 0 ]
  [ -x "$DEBIAN_THEME" ]
  [ ! -e "$THEME" ]

  ! grep -q "GRUB_THEME" "$GRUB_DEFAULT"
}

@test "the legacy cleanup leaves unrelated GRUB_THEME lines alone" {
  echo 'GRUB_THEME="/usr/share/grub/themes/SomethingElse/theme.txt"' >> "$GRUB_DEFAULT"

  run "$INSTALL"
  [ "$status" -eq 0 ]

  run "$UNINSTALL"

  [ "$status" -eq 0 ]

  grep -q "SomethingElse" "$GRUB_DEFAULT"
}
