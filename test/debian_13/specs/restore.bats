#!/usr/bin/env bats
#
# The whole question, in two tests.
#
# Everything else in specs/ checks one named thing each. These two check
# everything at once: fingerprint the machine, install, uninstall, and fail
# if a single file, mode or checksum differs. What they catch is what nobody
# thought to write an assertion for.

load ../support/helper

@test "install then uninstall leaves the system exactly as it was" {
  assert_round_trip_leaves_no_trace "$UNINSTALL"
}

@test "the stashed uninstaller leaves the system exactly as it was too" {
  # The copy in /var/lib is what removes the theme from a machine where the
  # repo is long gone. It has to be just as clean as the original.
  assert_round_trip_leaves_no_trace "$STASHED"
}
