# mitamae-cloud-image

generate cloud image from mitamae recipe

# Environment Variables

```bash
$ direnv edit .
```

```sh
#!/bin/sh

APT_CACHER_HOST="cacher.apt.internal"
APT_MIRROR_HOST="mirror.apt.internal"

# Apt Mirror List

export APT_REPO_URL_DEBIAN="http://${APT_MIRROR_HOST}/debian"
export APT_REPO_URL_DEBIAN_SECURITY="http://${APT_MIRROR_HOST}/debian-security"

export APT_REPO_URL_UBUNTU="http://${APT_MIRROR_HOST}/ubuntu"
export APT_REPO_URL_UBUNTU_PORTS="http://${APT_MIRROR_HOST}/ubuntu-ports"

export APT_REPO_URL_RASPBERRYPI="http://${APT_MIRROR_HOST}/raspberrypi"

export APT_REPO_URL_NVIDIA_CUDA_DEBIAN_TRIXIE="http://${APT_MIRROR_HOST}/nvidia-cuda-trixie"
export APT_REPO_URL_NVIDIA_CUDA_UBUNTU_RESOLUTE="http://${APT_MIRROR_HOST}/nvidia-cuda-resolute"

export APT_REPO_URL_POWERDNS_DEBIAN="http://${APT_MIRROR_HOST}/powerdns-debian"
export APT_REPO_URL_POWERDNS_UBUNTU="http://${APT_MIRROR_HOST}/powerdns-ubuntu"

export APT_REPO_URL_ISC_KEA_DEBIAN="http://${APT_MIRROR_HOST}/isc-kea-32x-debian"
export APT_REPO_URL_ISC_KEA_UBUNTU="http://${APT_MIRROR_HOST}/isc-kea-32x-ubuntu"

# Apt Cacher List

export APT_REPO_URL_PPA_MOZILLA_TEAM="http://${APT_CACHER_HOST}/ppa-mozilla-team"
export APT_REPO_URL_PPA_DRACUT_NG="http://${APT_CACHER_HOST}/ppa-dracut-ng"

export APT_REPO_URL_PROXMOX_VE_ENTERPRISE="http://${APT_CACHER_HOST}/proxmox-ve-enterprise"
export APT_REPO_URL_PROXMOX_VE_COMMUNITY="http://${APT_CACHER_HOST}/proxmox-ve-community"

export APT_REPO_URL_NVIDIA_CUDA_UBUNTU_NOBLE="http://${APT_CACHER_HOST}/nvidia-cuda-noble"
export APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM="http://${APT_CACHER_HOST}/nvidia-cuda-bookworm"

export APT_REPO_PPA_NVIDIA_VGPU_KEYRING_UID="[GPG_UID]"
export APT_REPO_PPA_NVIDIA_VGPU_KEYRING_FINGER_PRINT="[GPG_FINGER_PRINT]"
export APT_REPO_PPA_NVIDIA_VGPU_KEYRING_URL="http://${APT_CACHER_HOST}/ppa-nvidia-vgpu/public.gpg"
export APT_REPO_PPA_NVIDIA_VGPU_URL="http://${APT_CACHER_HOST}/ppa-nvidia-vgpu"

export ARCH_PACMAN_MIRROR="https://ftp.jaist.ac.jp/pub/Linux/ArchLinux/"

export TIMEZONE="Asia/Tokyo"

# For minimal or proxmox-ve profile (or any profile with ENABLE_ADMINISTRATOR="true")
# export ENABLE_ADMINISTRATOR="true"
# Generate password:
# openssl passwd -6 -salt "$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 8 | head -n 1)"
# export ADMIN_USERNAME="admin"
# export ADMIN_FULLNAME="Admin User"
# export ADMIN_PASSWORD=""
# export ADMIN_SSH_AUTHORIZED_KEYS=""

# Build directory (default: /var/lib/mitamae-cloud-image/[TARGET])
# export TARGET_DIRECTORY="/var/lib/mitamae-cloud-image/rootfs"
# The build directory is a tmpfs (default size: half of the memory)
# export TARGET_TMPFS_SIZE="8G"
# export DISABLE_TARGET_TMPFS="true"

# export ROOTFS_ARCHIVE_FORMAT="xz"
# export DRACUT_COMPRESS="zstd"

# export DISABLE_SQUASHFS="true"
# export DISABLE_TARBALL="true"
# export DISABLE_CPIO="true"
# export DISABLE_SHA256SUMS="true"
# export DISABLE_SEIROFILE="true"
# export DISABLE_ISO="true"

# export LOG_LEVEL="debug"
```

# Virtual Machine

The amd64 builds other than the Raspberry Pi ones also write a `Seirofile` next to the images,
which boots them as a live machine on [seiro](https://github.com/takumin/seiro):

```sh
cd releases/debian/trixie/cloud-backports/amd64/server
seiro up
seiro ssh server
```

The roles with Cloud-Init create the user `ops` with `~/.ssh/authorized_keys`.
The `minimal` and `proxmox-ve` roles have no Cloud-Init and bring up the network with `anynet`; log in on `seiro console` as the administrator of `ENABLE_ADMINISTRATOR`.

# Boot Parameters

The images boot `rootfs.squashfs` as a live root with the dmsquash-live and livenet modules of dracut,
and run it on an overlay in memory.

Network boot fetches the squashfs over HTTP, running DHCP in the initrd without `ip=`
(which systemd-network-generator would also apply to every interface of the live root):

```
root=live:http://boot.example.internal/rootfs.squashfs seednet.url=http://boot.example.internal/seed/{hostname}/ ds=nocloud
```

USB boot (`scripts/generate-bootable-usb.sh`) reads `LiveOS/squashfs.img` on the boot partition and copies it into memory:

```
root=live:UUID=<boot partition> rd.live.ram=1 ds=nocloud
```

The images add the following parameters:

- `seednet.url=<url>`: [seednet](https://github.com/takumin/seednet) fetches the NoCloud seed (`meta-data` and `user-data`, and `vendor-data` and `network-config` if the seed has them) in the initrd, brings up the network of the initrd and of the live root from its `network-config`, and hands the seed to Cloud-Init in `/var/lib/cloud/seed/nocloud`. `{hostname}`, `{domainname}` and `{fqdn}` in the URL are the names from DHCP. The URL is the directory of the seed and ends in `/`; a seed that is not there stops the boot in the initrd. Use it with `ds=nocloud`, and `ds=nocloud;dsmode=net` for Cloud-Init before 24.1 (Debian 12), which skips the init modules otherwise.
- `anynet`: Run DHCP on every wired interface of the live root, instead of the network config of Cloud-Init. It does nothing where seednet brought up the network of the initrd from a `network-config`.

# ISO Image

The amd64 `server` builds with the kernels for virtual machines (`cloud` on Debian, `virtual` on Ubuntu) also write `live.iso`, which boots the same live root as the bootable USB from a CD-ROM,
for a VPS that installs a new server from an ISO image.
The squashfs goes into the ISO as it is, so the ISO outgrows it only by the kernel, the initrd and GRUB (about 12M).
Cloud-Init takes the user and the network from a NoCloud seed on a disk labelled `cidata`, which the VPS attaches next to the ISO.
