#!/usr/bin/env bats
#
# The copy of the uninstaller the install leaves in /var/lib/nowaos-prelude.
#
# The repo may have been a tarball in /tmp that is already gone. What the
# install stashes has to work on its own.

load ../support/helper

@test "install stashes the uninstaller and its helpers" {
  run "$INSTALL"

  [ "$status" -eq 0 ]
  [ -x "$STASHED" ]
  [ -f "$STATE_DIR/bin/helpers/common.sh" ]
}

@test "the stash does not carry the theme sources" {
  run "$INSTALL"

  [ "$status" -eq 0 ]

  # Removing a theme never reads the theme. Copying src/ would park the
  # icons in /var/lib for nothing.
  [ ! -e "$STATE_DIR/src" ]
}

@test "the stashed uninstaller loads its own helpers, not the repo's" {
  run "$INSTALL"
  [ "$status" -eq 0 ]

  # This marker exists only in the stashed copy. If the copy resolved its
  # helpers back through /repo, it would not appear in the output — and the
  # stash would be useless on a machine where the repo is gone.
  echo 'prompt -i "helpers came from the stash"' >> "$STATE_DIR/bin/helpers/common.sh"

  run "$STASHED"

  [ "$status" -eq 0 ]
  [[ "$output" == *"helpers came from the stash"* ]]
}

@test "the stashed uninstaller removes the theme and then itself" {
  run "$INSTALL"
  [ "$status" -eq 0 ]

  run "$STASHED"

  [ "$status" -eq 0 ]
  [ -x "$DEBIAN_THEME" ]
  [ ! -e "$THEME" ]
  [ ! -e "$DROPIN" ]

  # It deletes the directory it is running from. The kernel keeps the inode
  # alive until bash is done with it, so this has to finish cleanly.
  [ ! -e "$STATE_DIR" ]
}

@test "a failing update-grub leaves the stashed uninstaller in place" {
  run "$INSTALL"
  [ "$status" -eq 0 ]

  printf '#!/bin/sh\nexit 1\n' > /usr/local/bin/update-grub

  run "$STASHED"

  [ "$status" -ne 0 ]

  # The stash has to outlive every step that can fail, or a failure here
  # would leave the machine half-restored with no uninstaller to run again.
  [ -x "$STASHED" ]
}
