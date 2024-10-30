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

# Minimize Linux Firmware

export MINIMIZE_LINUX_FIRMWARE="true"

# Apt Mirror List

export APT_REPO_URL_DEBIAN="http://${APT_MIRROR_HOST}/debian"
export APT_REPO_URL_DEBIAN_SECURITY="http://${APT_MIRROR_HOST}/debian-security"

export APT_REPO_URL_UBUNTU="http://${APT_MIRROR_HOST}/ubuntu"
export APT_REPO_URL_UBUNTU_PORTS="http://${APT_MIRROR_HOST}/ubuntu-ports"

export APT_REPO_URL_RASPBERRYPI="http://${APT_MIRROR_HOST}/raspberrypi"

export APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM="http://${APT_MIRROR_HOST}/nvidia-cuda-bookworm"
export APT_REPO_URL_NVIDIA_CUDA_UBUNTU_NOBLE="http://${APT_MIRROR_HOST}/nvidia-cuda-noble"

# Apt Cacher List

export APT_REPO_URL_UBUNTU_JA="http://${APT_CACHER_HOST}/ubuntu-ja"
export APT_REPO_URL_UBUNTU_JA_NON_FREE="http://${APT_CACHER_HOST}/ubuntu-ja-non-free"

export APT_REPO_URL_PPA_MOZILLA_TEAM="http://${APT_CACHER_HOST}/ppa-mozilla-team"

export APT_REPO_URL_PROXMOX_VE_ENTERPRISE="http://${APT_CACHER_HOST}/proxmox-ve-enterprise"
export APT_REPO_URL_PROXMOX_VE_COMMUNITY="http://${APT_CACHER_HOST}/proxmox-ve-community"

export APT_REPO_URL_NVIDIA_CUDA_UBUNTU_JAMMY="http://${APT_CACHER_HOST}/nvidia-cuda-jammy"
export APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BULLSEYE="http://${APT_CACHER_HOST}/nvidia-cuda-bullseye"

export APT_REPO_PPA_NVIDIA_VGPU_KEYRING_UID="[GPG_UID]"
export APT_REPO_PPA_NVIDIA_VGPU_KEYRING_FINGER_PRINT="[GPG_FINGER_PRINT]"
export APT_REPO_PPA_NVIDIA_VGPU_KEYRING_URL="http://${APT_CACHER_HOST}/ppa-nvidia-vgpu/public.gpg"
export APT_REPO_PPA_NVIDIA_VGPU_URL="http://${APT_CACHER_HOST}/ppa-nvidia-vgpu"

export ARCH_PACMAN_MIRROR="https://ftp.jaist.ac.jp/pub/Linux/ArchLinux/"

export TIMEZONE="Asia/Tokyo"

# For minimal or proxmox-ve profile
# Generate password:
# openssl passwd -6 -salt "$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 8 | head -n 1)"
# export ADMIN_USERNAME="admin"
# export ADMIN_FULLNAME="Admin User"
# export ADMIN_PASSWORD=""
# export ADMIN_SSH_AUTHORIZED_KEYS=""

# export ROOTFS_ARCHIVE_FORMAT="xz"

# export DISABLE_SQUASHFS="true"
# export DISABLE_TARBALL="true"
# export DISABLE_CPIO="true"
# export DISABLE_SHA256SUMS="true"

# export LOG_LEVEL="debug"
```
