# mitamae-cloud-image
generate cloud image from mitamae recipe

# Environment Variables

```bash
$ direnv edit .
```

```sh
#!/bin/sh

export APT_REPO_URL_UBUNTU="http://proxy.apt.internal:3142/ubuntu"
export APT_REPO_URL_UBUNTU_PORTS="http://proxy.apt.internal:3142/ubuntu-ports"

export APT_REPO_URL_UBUNTU_JA="http://proxy.apt.internal:3142/ubuntu-ja"
export APT_REPO_URL_UBUNTU_JA_NON_FREE="http://proxy.apt.internal:3142/ubuntu-ja-non-free"

export APT_REPO_URL_PPA_GRAPHICS_DRIVERS="http://proxy.apt.internal:3142/ppa-gpu-driver"

export APT_REPO_URL_DEBIAN="http://proxy.apt.internal:3142/debian"
export APT_REPO_URL_DEBIAN_SECURITY="http://proxy.apt.internal:3142/debian-security"

export APT_REPO_URL_RASPBERRYPI="http://proxy.apt.internal:3142/raspberrypi"

export ARCH_PACMAN_MIRROR="https://ftp.jaist.ac.jp/pub/Linux/ArchLinux/"

# export INITRAMFS_COMPRESS="lz4"
# export ROOTFS_ARCHIVE_FORMAT_TARBALL="lz4"
# export ROOTFS_ARCHIVE_FORMAT_SQUASHFS="lz4"

# export DISABLE_SQUASHFS="true"
# export DISABLE_TARBALL="true"
# export DISABLE_SHA256SUMS="true"

# export LOG_LEVEL="debug"
```
