#!/usr/bin/env bats
#
# bin/debian_13/uninstall.sh — undoing the install, and knowing what was not
# the install's doing in the first place.

load ../support/helper

@test "uninstall re-enables Debian's theme script" {
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ ! -x "$DEBIAN_THEME" ]

  run "$UNINSTALL"

  [ "$status" -eq 0 ]
  [ -x "$DEBIAN_THEME" ]
}

@test "uninstall removes every file the install created" {
  run "$INSTALL"
  [ "$status" -eq 0 ]

  run "$UNINSTALL"

  [ "$status" -eq 0 ]
  [ ! -e "$THEME" ]
  [ ! -e "$DROPIN" ]
  [ ! -e "$STATE" ]
  [ ! -e "$STATE_DIR" ]
}

@test "uninstall leaves Debian's theme script alone if the user disabled it" {
  chmod -x "$DEBIAN_THEME"

  run "$INSTALL"
  [ "$status" -eq 0 ]

  grep -q '^DEBIAN_THEME_DISABLED="no"$' "$STATE"

  run "$UNINSTALL"

  [ "$status" -eq 0 ]
  [ ! -x "$DEBIAN_THEME" ]
}

@test "uninstall is safe to run when nothing is installed" {
  run "$UNINSTALL"

  [ "$status" -eq 0 ]
  [ -x "$DEBIAN_THEME" ]
}
