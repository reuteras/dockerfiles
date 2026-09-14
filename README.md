# dockerfiles

Collection of Dockerfiles in one repo instead of adding a new repository for each and every tool as I have done before. See list at the end of this page.

## Tools in this repository

- [elastic-lab](./elastic-lab/README.md) - Notes and setup scripts for testing the ELK stack, auditbeat/auditd, and Sysmon for Linux
- [elastic-linux-lpe-lab](./elastic-linux-lpe-lab/README.md) - Elastic Security, Fleet, Elastic Defend, and Auditd lab for Linux privilege-escalation detection testing
- [fq](https://github.com/wader/fq) - Tool, language and decoders for working with binary data. Usage and more in [fq](./fq/README.md)
- [hfinger](https://github.com/CERT-Polska/hfinger) - Fingerprinting HTTP requests. Usage and more in [hfinger](./hfinger/README.md)
- [marimo](https://github.com/marimo-team/marimo) - Reactive Python notebooks. Usage and more in [marimo](./marimo/README.md)
- [nDPI](https://github.com/ntop/nDPI) - Deep packet inspection toolkit. Usage and more in [nDPI](./nDPI/README.md)
- [nginx](./nginx/README.md) - nginx configured with WebDAV-style upload support
- [snort2suricata](https://github.com/google/gonids) - Converts Snort rules to Suricata rules. Usage and more in [snort2suricata](./snort2suricata/README.md)
- [webdav](./webdav/README.md) - nginx-based WebDAV server
- [zeek](https://github.com/zeek/zeek) - Network security monitoring platform. Usage and more in [zeek](./zeek/README.md)

## Repositories with one tool in each

- [container-notebook](https://github.com/reuteras/container-notebook)
- [container-vma](https://github.com/reuteras/container-vma)
- [container-wise](https://github.com/reuteras/container-wise)

## Install the March 2026 kernel on Debian Trixie ARM64

The Debian snapshot from March 31, 2026 contains the signed security kernel
`6.12.74-2`, installed as `6.12.74+deb13+1-arm64`. Confirm that the VM uses
the `arm64` architecture and has sufficient space in `/boot`:

```console
$ dpkg --print-architecture
arm64
$ uname -m
aarch64
$ df -h /boot
```

Create `/etc/apt/sources.list.d/march-2026-kernel.sources` with the following
contents:

```deb822
Types: deb
URIs: https://snapshot.debian.org/archive/debian/20260331T235959Z/
Suites: trixie
Components: main
Architectures: arm64
Check-Valid-Until: no
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://snapshot.debian.org/archive/debian-security/20260331T235959Z/
Suites: trixie-security
Components: main
Architectures: arm64
Check-Valid-Until: no
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

Update the package indexes, confirm the exact version, and simulate the
installation before making changes:

```sh
sudo apt-get update
apt-cache policy 'linux-image-6.12.74+deb13+1-arm64'
sudo apt-get --simulate install \
  'linux-image-6.12.74+deb13+1-arm64=6.12.74-2'
```

Install the versioned kernel package. Using the versioned package keeps any
newer installed kernel available as a fallback and avoids downgrading the
`linux-image-arm64` meta-package.

```sh
sudo apt-get install \
  'linux-image-6.12.74+deb13+1-arm64=6.12.74-2'
ls -l /boot/vmlinuz-6.12.74+deb13+1-arm64
sudo update-grub
```

If a newer kernel is installed, select `6.12.74+deb13+1-arm64` from GRUB's
**Advanced options for Debian GNU/Linux** menu. Keep VM console access
available for the first reboot. After booting, verify the running kernel:

```sh
uname -r
```

The command should report `6.12.74+deb13+1-arm64`. Remove the temporary
snapshot source after a successful boot and refresh APT:

```sh
sudo rm /etc/apt/sources.list.d/march-2026-kernel.sources
sudo apt-get update
```

`Check-Valid-Until: no` permits use of expired historical metadata; signature
verification remains enabled through Debian's archive keyring. See Debian's
[snapshot archive](https://snapshot.debian.org/) and
[snapshot rollback guidance](https://wiki.debian.org/RollbackUpdate) for more
information.
