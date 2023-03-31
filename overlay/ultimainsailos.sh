#!/usr/bin/env bash
#### MainsailOS for Ultimaker image
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2023 - till today
#### https://github.com/KwadFan/olimage
####
#### This File is distributed under GPLv3
####
# shellcheck enable=require-variable-braces

# Exit on errors
set -Eex

# Vars
BASE_USER="um"
WORKDIR="/home/um"
GIT_URL="https://github.com"
REPOS=(
        "mainsail-crew/mainsail-config"
        "th33xitus/kiauh"
        "Arksine/moonraker"
        "Klipper3d/klipper"
        )
DATA_STRUCT=(
        "printer_data"
        "printer_data/config"
        "printer_data/comms"
        "printer_data/logs"
        "printer_data/systemd"
        )
KLIPPER_SRC_DIR="${WORKDIR}/klipper"
KLIPPER_PYTHON_DIR="${WORKDIR}/klippy-env"
KLIPPER_PYENV_REQ="scripts/klippy-requirements.txt"
MAINSAIL_CONFIG_SRC_PATH="${WORKDIR}/mainsail-config/mainsail.cfg"
MAINSAIL_CONFIG_DEST_PATH="${WORKDIR}/printer_data/config/mainsail.cfg"
MAINSAIL_URL="https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip"

## Step 1: Change Working Dir
echo "Step 1: Change WORKING DIR to '${WORKDIR}'"
pushd "${WORKDIR}"
echo "END Step 1"
## END Step 1

## Step 2: Clone needed Repositories
echo "Step 2: Clone needed repositories ..."
for repo in "${REPOS[@]}"; do
    echo -e "Cloning '${repo}' ..."
    sudo -u "${BASE_USER}" git clone "${GIT_URL}/${repo}.git"
    echo -e "Cloning '${repo}' ... done!"
done
echo "END Step 2"
## END Step 2

## Step 3: Create File structure
echo -e "Step 3: Create File structure ..."
for dir in "${DATA_STRUCT[@]}"; do
    echo -e "Create DATA_STRUCT ..."
    sudo -u "${BASE_USER}" mkdir -p "${WORKDIR}/${dir}"
    echo -e "Create DATA_STRUCT ... done!"
done
echo -e "END Step 3"
## END Step 3

## Step 4: Install Klipper
echo -e "Install Klipper ..."
### Substep 1: Create klippy venv
echo -e "Creating Virtualenv for Klipper (klippy-env) ..."
sudo -u "${BASE_USER}" virtualenv -p python3 "${KLIPPER_PYTHON_DIR}"
### END Substep 1
### Substep 2: Install py deps
echo -e "Installing klippy Python Dependencies ..."
sudo -u "${BASE_USER}" "${KLIPPER_PYTHON_DIR}"/bin/pip install -r "${KLIPPER_SRC_DIR}/${KLIPPER_PYENV_REQ}"
### END Substep 2
### Substep 3: Create klipper.env in printer_data/systemd
echo "Create klipper.env file ..."
KLIPPER_ENV_ARGS="${WORKDIR}/klipper/klippy/klippy.py"
KLIPPER_ENV_ARGS+=" ${WORKDIR}/printer_data/config/printer.cfg"
KLIPPER_ENV_ARGS+=" -l ${WORKDIR}/printer_data/logs/klippy.log"
KLIPPER_ENV_ARGS+=" -I ${WORKDIR}/printer_data/comms/klippy.serial"
KLIPPER_ENV_ARGS+=" -a ${WORKDIR}/printer_data/comms/klippy.sock"

echo "KLIPPER_ARGS=${KLIPPER_ENV_ARGS}" | sudo -u "${BASE_USER}" tee -a "${WORKDIR}/printer_data/systemd/klipper.env"
echo "Create klipper.env file ... done!"

echo "DEBUG: print klipper.env file"
cat "${WORKDIR}/printer_data/systemd/klipper.env"
### END Substep 3
### Substep 4: Create klipper.service
cat << EOF > /etc/systemd/system/klipper.service
[Unit]
Description=Klipper 3D Printer Firmware SV1
Documentation=https://www.klipper3d.org/
After=network-online.target
Before=moonraker.service
Wants=udev.target

[Install]
Alias=klippy
WantedBy=multi-user.target

[Service]
Type=simple
User=pi
RemainAfterExit=yes
WorkingDirectory=${WORKDIR}/klipper
EnvironmentFile=${WORKDIR}/printer_data/systemd/klipper.env
ExecStart=${WORKDIR}/klippy-env/bin/python \$KLIPPER_ARGS
Restart=always
RestartSec=10

EOF

echo "DEBUG: print klipper.service file"
cat /etc/systemd/system/klipper.service
### END Substep 4
### Substep 5: Enable Klipper Service
systemctl enable klipper.service
### END Substep 5
## END Step 4

## Step 5: Install Moonraker
echo "Step 5: Install Moonraker ..."
### Substep 1: Change WORKING DIR
pushd "${WORKDIR}/moonraker" &> /dev/null || exit 1
### END Substep 1
### Substep 2: Install moonraker
echo -e "Launch moonraker install routine ..."
sudo -u "${BASE_USER}" ./scripts/install-moonraker.sh -z -x
### END Substep 2
### Substep 3: Install policykit rules
echo -e "Install moonrakers PolicyKit Rules ..."
sudo -u "${BASE_USER}" ./scripts/set-policykit-rules.sh --root
### END Substep 3
### Substep 4: Replace default moonraker.conf
if [[ -f "${WORKDIR}/printer_data/config/moonraker.conf" ]]; then
    rm -rf "${WORKDIR}/printer_data/config/moonraker.conf"
fi
cat << EOF > "${WORKDIR}/printer_data/config/moonraker.conf"
[server]
host: 0.0.0.0
port: 7125
# The maximum size allowed for a file upload (in MiB).  Default 1024 MiB
max_upload_size: 1024
# Path to klippy Unix Domain Socket
klippy_uds_address: ~/printer_data/comms/klippy.sock

[file_manager]
# post processing for object cancel. Not recommended for low resource SBCs such as a Pi Zero. Default False
enable_object_processing: False

[authorization]
cors_domains:
    https://my.mainsail.xyz
    http://my.mainsail.xyz
    http://*.local
    http://*.lan
trusted_clients:
    10.0.0.0/8
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.168.0.0/16
    FE80::/10
    ::1/128

# enables partial support of Octoprint API
[octoprint_compat]

# enables moonraker to track and store print history.
[history]

# this enables moonraker announcements for mainsail
[announcements]
subscriptions:
    mainsail

# this enables moonraker's update manager
[update_manager]
refresh_interval: 168
enable_auto_refresh: True

[update_manager mainsail]
type: web
channel: stable
repo: mainsail-crew/mainsail
path: ~/mainsail

[update_manager mainsail-config]
type: git_repo
primary_branch: master
path: ~/mainsail-config
origin: https://github.com/mainsail-crew/mainsail-config.git
managed_services: klipper

EOF

### END Substep 4
### Substep 5: Ensure moonraker.conf is owned by BASE_USER
chown "${BASE_USER}":"${BASE_USER}" "${WORKDIR}/printer_data/config/moonraker.conf"
chmod 0755 "${WORKDIR}/printer_data/config/moonraker.conf"
### END Substep 5
### Substep 6: Leave monnraker dir
popd &> /dev/null || exit 1
### END Substep 6
### Substep 7: Ensure moonraker service is enabled
sudo systemctl enable moonraker.service
### END Substep 7
echo "END Step 5"
## END Step 5

## Step 6: Install mainsail.cfg to printer_data/config
echo -e "Step 6: Install mainsail.cfg to printer_data/config ..."
if [[ -f "${MAINSAIL_CONFIG_SRC_PATH}" ]]; then
    sudo -u "${BASE_USER}" \
    ln -sf "${MAINSAIL_CONFIG_SRC_PATH}" "${MAINSAIL_CONFIG_DEST_PATH}"
fi
echo -e "END Step 6"
## END Step 6

## Step 7: Install mainsail
#### NOTE: Nginx config is done via Framework
#### See: olimage/filesystem/base.py Line#78
echo -e "Step 7: Install mainsail ..."
### Substep 1: Get and install mainsail
sudo -u "${BASE_USER}" wget -q --show-progress -O mainsail.zip "${MAINSAIL_URL}"
sudo -u "${BASE_USER}" unzip mainsail.zip -d "${WORKDIR}"/mainsail
#### cleanup
rm -f "${WORKDIR}/mainsail.zip"
### END Substep 1
### Substep 2: Link log files
ln -sf /var/log/nginx/mainsail-access.log "${WORKDIR}/printer_data/logs"
ln -sf /var/log/nginx/mainsail-error.log "${WORKDIR}/printer_data/logs"
### END Substep 2
echo -e "END Step 7"
## END Step 7
