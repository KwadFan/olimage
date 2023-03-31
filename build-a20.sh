#!/bin/sh

# qemu-user-static != 5.2 may have issues when building bullseye arm64 images
# recommended host OS to build: debian buster amd64 with qemu-user-static from buster-backports
apt-get install qemu-user-static


# a20
#bash run_headless.sh -v image --size 500 --ssh --hostname ultimainsailos A20-OLinuXino bullseye base ultimainsailos-bullseye-A20-$(date +%Y%m%d-%H%M%S).img
bash run_headless.sh -v image --size 500 --ssh --hostname ultimainsailos A20-OLinuXino-lime2 bullseye base ultimainsailos-bullseye-A20-$(date +%Y%m%d-%H%M%S).img
