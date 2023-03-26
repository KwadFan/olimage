#!/bin/sh

# qemu-user-static != 5.2 may have issues when building bullseye arm64 images
# recommended host OS to build: debian buster amd64 with qemu-user-static from buster-backports
apt-get install qemu-user-static


# a20
bash run_headless.sh -v image A20-OLinuXino bullseye minimal    A20-OLinuXino-bullseye-minimal-$(date +%Y%m%d-%H%M%S).img
bash run_headless.sh -v image A20-OLinuXino bullseye base       A20-OLinuXino-bullseye-base-$(date +%Y%m%d-%H%M%S).img

# release images

# a20
ARGS=-r bash run_headless.sh -v image A20-OLinuXino bullseye minimal    A20-OLinuXino-bullseye-minimal-$(date +%Y%m%d-%H%M%S).img
ARGS=-r bash run_headless.sh -v image A20-OLinuXino bullseye base       A20-OLinuXino-bullseye-base-$(date +%Y%m%d-%H%M%S).img
