# A Debian 13 with just enough GRUB to exercise the install scripts.
#
# The point of running here rather than on a developer's machine is that the
# scripts run unmodified, as real root, against a real /etc and a real
# /etc/grub.d/05_debian_theme. Nothing about them is faked for the test.

FROM debian:13

RUN apt-get update \
  && apt-get install -y --no-install-recommends bats grub-common \
  && rm -rf /var/lib/apt/lists/*

# grub-common ships /etc/grub.d/05_debian_theme, but /etc/default/grub comes
# from grub-pc/grub-efi, which will not install without a disk to point at.
COPY fixtures/default-grub /etc/default/grub

# The one thing that cannot be real: update-grub reads the partition table
# and writes /boot/grub/grub.cfg. There is no disk here, so it records the
# call and returns. Everything else the scripts touch is genuine.
COPY support/update-grub /usr/local/bin/update-grub

RUN chmod +x /usr/local/bin/update-grub

# Whole-directory copies, so a test can be handed back a stock Debian 13
# rather than one with the previous test's leftovers deleted by name. These
# are the same directories the suite fingerprints; keep the two in step.
RUN mkdir -p /opt/pristine \
  && cp -a /etc/default /opt/pristine/default \
  && cp -a /etc/grub.d /opt/pristine/grub.d \
  && cp -a /usr/share/grub /opt/pristine/share-grub \
  && cp -a /usr/local/bin/update-grub /opt/pristine/update-grub

WORKDIR /repo
