#!/usr/bin/env bash
#
# Shared by every spec, which pulls it in with:
#
#   load ../support/helper
#
# Holds the paths under test, the reset that runs before each test, and the
# fingerprint the restore specs compare.

### Paths

INSTALL="/repo/bin/debian_13/install.sh"
UNINSTALL="/repo/bin/debian_13/uninstall.sh"

THEME="/usr/share/grub/themes/Prelude"
DROPIN="/etc/default/grub.d/prelude.cfg"
DEBIAN_THEME="/etc/grub.d/05_debian_theme"
GRUB_DEFAULT="/etc/default/grub"

STATE_DIR="/var/lib/nowaos-prelude"
STATE="${STATE_DIR}/state"
STASHED="${STATE_DIR}/bin/debian_13/uninstall.sh"

### Reset

# Back to a stock Debian 13 before every test, so no test can pass or fail
# because of what another one left behind.
#
# These are whole-directory restores rather than a list of files to delete.
# Deleting by name only clears leftovers someone remembered to name, which is
# precisely the assumption the restore specs exist to not make.
setup() {
  rm -rf /etc/default /etc/grub.d /usr/share/grub "$STATE_DIR" \
    /tmp/update-grub.calls

  cp -a /opt/pristine/default /etc/default
  cp -a /opt/pristine/grub.d /etc/grub.d
  cp -a /opt/pristine/share-grub /usr/share/grub

  # Some specs break update-grub on purpose.
  cp -a /opt/pristine/update-grub /usr/local/bin/update-grub
}

### Assertions

# Type, permissions and contents of everything the scripts could plausibly
# reach. Comparing this before and after is what proves the uninstall left no
# trace, including traces nobody thought to write a test for.
fingerprint() {
  find /etc/default /etc/grub.d /usr/share/grub "$STATE_DIR" \
    -printf '%y %m %p\n' 2>/dev/null | sort

  find /etc/default /etc/grub.d -type f -exec md5sum {} + 2>/dev/null | sort
}

# Runs install then uninstall through the given uninstaller, and fails if the
# system is not byte-for-byte what it was. Both restore specs are this.
assert_round_trip_leaves_no_trace() {
  local uninstaller="$1"
  local before after

  before="$(fingerprint)"

  run "$INSTALL"
  [ "$status" -eq 0 ]

  run "$uninstaller"
  [ "$status" -eq 0 ]

  after="$(fingerprint)"

  if [ "$before" != "$after" ]; then
    echo "--- ${uninstaller} did not restore these ---" >&2
    diff <(echo "$before") <(echo "$after") >&2 || true

    return 1
  fi
}
