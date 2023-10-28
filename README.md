# mitamae-cloud-image
generate cloud image from mitamae recipe

# Environment Variables

```bash
$ direnv edit .
```

```sh
#!/bin/sh

APT_PROXY_HOST="proxy.apt.internal:3142"

export APT_REPO_URL_UBUNTU="http://${APT_PROXY_HOST}/ubuntu"
export APT_REPO_URL_UBUNTU_PORTS="http://${APT_PROXY_HOST}/ubuntu-ports"

export APT_REPO_URL_UBUNTU_JA="http://${APT_PROXY_HOST}/ubuntu-ja"
export APT_REPO_URL_UBUNTU_JA_NON_FREE="http://${APT_PROXY_HOST}/ubuntu-ja-non-free"

export APT_REPO_URL_PPA_MOZILLA_TEAM="http://${APT_PROXY_HOST}/ppa-mozilla-team"

export APT_REPO_URL_PPA_GRAPHICS_DRIVERS="http://${APT_PROXY_HOST}/ppa-graphics-drivers"

export APT_REPO_URL_DEBIAN="http://${APT_PROXY_HOST}/debian"
export APT_REPO_URL_DEBIAN_SECURITY="http://${APT_PROXY_HOST}/debian-security"

export APT_REPO_URL_RASPBERRYPI="http://${APT_PROXY_HOST}/raspberrypi"

export APT_REPO_URL_NVIDIA_CUDA_UBUNTU_FOCAL="http://${APT_PROXY_HOST}/nvidia-cuda-focal"
export APT_REPO_URL_NVIDIA_CUDA_UBUNTU_JAMMY="http://${APT_PROXY_HOST}/nvidia-cuda-jammy"
export APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BULLSEYE="http://${APT_PROXY_HOST}/nvidia-cuda-bullseye"
export APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM="http://${APT_PROXY_HOST}/nvidia-cuda-bookworm"

export ARCH_PACMAN_MIRROR="https://ftp.jaist.ac.jp/pub/Linux/ArchLinux/"

export TIMEZONE="Asia/Tokyo"

# export INITRAMFS_COMPRESS="lz4"
# export ROOTFS_ARCHIVE_FORMAT_TARBALL="lz4"
# export ROOTFS_ARCHIVE_FORMAT_SQUASHFS="lz4"

# export DISABLE_SQUASHFS="true"
# export DISABLE_TARBALL="true"
# export DISABLE_DISKIMG="true"
# export DISABLE_SHA256SUMS="true"

# export LOG_LEVEL="debug"
```
