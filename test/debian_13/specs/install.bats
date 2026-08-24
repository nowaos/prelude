#!/usr/bin/env bats
#
# bin/debian_13/install.sh — what it puts on the machine, and what it is
# careful not to touch.

load ../support/helper

@test "install copies the theme into /usr/share/grub/themes" {
  run "$INSTALL"

  [ "$status" -eq 0 ]
  [ -f "$THEME/theme.txt" ]
  [ -d "$THEME/icons" ]
  [ -d "$THEME/img" ]
}

@test "install points GRUB at the theme through a drop-in" {
  run "$INSTALL"

  [ "$status" -eq 0 ]
  [ -f "$DROPIN" ]

  grep -q "^GRUB_THEME=\"${THEME}/theme.txt\"$" "$DROPIN"
}

@test "install leaves /etc/default/grub untouched" {
  before="$(md5sum < "$GRUB_DEFAULT")"

  run "$INSTALL"

  [ "$status" -eq 0 ]
  [ "$(md5sum < "$GRUB_DEFAULT")" = "$before" ]
}

@test "install disables Debian's theme script and records that it did" {
  run "$INSTALL"

  [ "$status" -eq 0 ]
  [ ! -x "$DEBIAN_THEME" ]

  grep -q '^DEBIAN_THEME_DISABLED="yes"$' "$STATE"
}

@test "install regenerates the GRUB config" {
  run "$INSTALL"

  [ "$status" -eq 0 ]
  [ -f /tmp/update-grub.calls ]
}

@test "install keeps a resolution the user already chose" {
  echo "GRUB_GFXMODE=1280x1024" >> "$GRUB_DEFAULT"

  run "$INSTALL"

  [ "$status" -eq 0 ]

  # The drop-in is read after /etc/default/grub, so writing one here would
  # silently override the user's choice.
  ! grep -q "GRUB_GFXMODE" "$DROPIN"
}

@test "install sets a resolution when the user has not" {
  run "$INSTALL"

  [ "$status" -eq 0 ]

  # The value depends on the machine running the test, the presence of a
  # line does not.
  grep -qE "^GRUB_GFXMODE=[0-9]+x[0-9]+$" "$DROPIN"
}

@test "a commented GRUB_GFXMODE does not count as the user choosing one" {
  grep -q "^#GRUB_GFXMODE=640x480$" "$GRUB_DEFAULT"

  run "$INSTALL"

  [ "$status" -eq 0 ]

  grep -qE "^GRUB_GFXMODE=" "$DROPIN"
}

@test "installing twice still remembers who disabled Debian's theme script" {
  run "$INSTALL"
  [ "$status" -eq 0 ]

  # The second run finds the script already disabled. It must not conclude
  # the user is the one who disabled it.
  run "$INSTALL"
  [ "$status" -eq 0 ]

  grep -q '^DEBIAN_THEME_DISABLED="yes"$' "$STATE"
}
