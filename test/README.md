# Tests

One directory per supported system, mirroring `bin/`:

```
test/
└── debian_13/
    ├── run.sh                Builds the container and runs the suite
    ├── Dockerfile            The system under test
    ├── specs/
    │   ├── install.bats      What the install puts on the machine
    │   ├── uninstall.bats    Undoing it, and knowing what was not ours
    │   ├── stash.bats        The uninstaller copy left in /var/lib
    │   ├── legacy.bats       Upgrading from the version that kept no record
    │   └── restore.bats      The round trip, fingerprinted
    ├── support/
    │   ├── helper.bash       Paths, setup(), fingerprint()
    │   └── update-grub       Stands in for the real one
    └── fixtures/
        └── default-grub      Stock /etc/default/grub, which grub-common omits
```

Run them with:

```
./test/debian_13/run.sh
```

Docker is the only requirement. `--filter NAME` narrows to matching tests and
`--shell` drops you into the container.

Every spec starts with `load ../support/helper`, which brings in the paths
under test, the reset that runs before each test, and the fingerprint the
restore specs compare.

## Why a container

The scripts edit `/etc` and `/usr/share` as root. Testing that on a developer's
machine means either rewriting their paths — which tests a modified copy of the
scripts, not the ones that ship — or trusting a sandbox made of convention.

In a `debian:13` container they run **unmodified, as real root, against a real
filesystem**. The `/etc/grub.d/05_debian_theme` they disable is the genuine
file from `grub-common`, not a fixture. The container is thrown away
afterwards, and the repo is mounted read-only, so a test cannot change the
machine running it or the working tree.

Only `update-grub` is stubbed. It reads the partition table and writes
`/boot/grub/grub.cfg`; there is no disk in a container to read. The stub
records that it was called, which is all the scripts need it to do.

## The specs that matter

Most of the suite checks one named thing each: the drop-in gets written,
`05_debian_theme` gets disabled, `/etc/default/grub` is never touched.

`restore.bats` is different. It fingerprints every file, mode and checksum
under every directory the scripts can reach, installs, uninstalls, and fails if
anything differs:

```
@test "install then uninstall leaves the system exactly as it was"
```

Its value is catching what nobody thought to test. It is what found the empty
`/usr/share/grub/themes` the uninstall used to leave behind — a directory no
named assertion was looking for.

It runs twice: once through the repo's `uninstall.sh`, once through the copy
the install stashes in `/var/lib/nowaos-prelude`. That copy is what removes the
theme from a machine where the repo is long gone, so it has to be just as
clean.

For that to work, each test has to start from a genuinely stock system. `setup()`
restores whole directories from a pristine copy rather than deleting leftovers
by name; deleting by name only clears what someone remembered to name, which is
the assumption this test exists to avoid.

## Checking the tests can fail

A suite that passes proves nothing until you have watched it fail. Break
something on purpose and run it:

```bash
# uninstall forgets to give back the execute bit
sed -i 's|^  chmod +x "$DEBIAN_THEME"|  :|' bin/debian_13/uninstall.sh
./test/debian_13/run.sh
git checkout bin/debian_13/uninstall.sh
```

Five should fail, both restore specs among them.

## Adding a system

Copy `debian_13/`, adjust the `Dockerfile` to that system, and point
`support/helper.bash` at the matching `bin/<os>/` scripts. `run.sh` takes its
OS name from its own directory, so it needs no edit.
