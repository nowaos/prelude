# Prelude

A minimalist GRUB2 theme.

## Scripts

Install:

```
sudo ./bin/debian_13/install.sh
```

Uninstall:

```
sudo ./bin/debian_13/uninstall.sh
```

Running the install again updates the theme in place.

## What the install touches

| Path | What happens |
| --- | --- |
| `/usr/share/grub/themes/Prelude` | The theme files. |
| `/etc/default/grub.d/prelude.cfg` | Sets `GRUB_THEME`, and `GRUB_GFXMODE` if you have not picked one. Debian's `grub-mkconfig` reads this directory after `/etc/default/grub`, which is never modified. |
| `/etc/grub.d/05_debian_theme` | Loses its execute bit, so Debian stops painting `desktop-base`'s background over the menu. |
| `/var/lib/nowaos-prelude/` | A record of the above, so the uninstall restores only what the install changed — plus a copy of the uninstaller itself. |

The uninstall reverses each of these. It re-enables `05_debian_theme` only if
the install is what disabled it — if you had already turned it off yourself, it
stays off.

Because the install leaves a copy of the uninstaller behind, the theme can be
removed from a machine that no longer has this repo:

```
sudo /var/lib/nowaos-prelude/bin/debian_13/uninstall.sh
```

## Tests

```
./test/debian_13/run.sh
```

Runs the scripts unmodified, as root, in a throwaway Debian 13 container. See
[test/README.md](test/README.md).

## License

[GPL-3.0-only](https://opensource.org/license/gpl-3-0)

Copyright (c) 2025-present, Alexandre Magro
