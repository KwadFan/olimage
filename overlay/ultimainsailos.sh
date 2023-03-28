#!/usr/bin/env bash

# Exit on errors
set -Eex


echo "Hello World!"
echo "Hello World!"
echo "Hello World!"
echo "Hello World!"
echo "Hello World!"


# Vars
BASE_USER="um"
WORKDIR="/home/um"
GIT_URL="https://github.com"
REPOS=(
        "mainsail-crew/mainsail-config"
        "mainsail-crew/crowsnest"
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


## Step 1: Change Working Dir
pushd "${WORKDIR}"
## END Step 1

## Step 2: Clone needed Repositories
for repo in "${REPOS[@]}"; do
    echo -e "Cloning '${repo}' ..."
    sudo -u "${BASE_USER}" git clone "${GIT_URL}/${repo}.git"
    echo -e "Cloning '${repo}' ... done!"
done
## END Step 2

## Step 3: Create File structure
for dir in "${DATA_STRUCT[@]}"; do
    echo -e "Create DATA_STRUCT ..."
    sudo -u "${BASE_USER}" mkdir -p "${WORKDIR}/${dir}"
    echo -e "Create DATA_STRUCT ... done!"
done
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
KLIPPER_ARGS="${WORKDIR}/klipper/klippy/klippy.py"
KLIPPER_ARGS+="${WORKDIR}/printer_data/config/printer.cfg"
KLIPPER_ARGS+="-l ${WORKDIR}/printer_data/logs/klippy.log"
KLIPPER_ARGS+="-I ${WORKDIR}/printer_data/comms/klippy.serial"
KLIPPER_ARGS+="-a ${WORKDIR}/printer_data/comms/klippy.sock"

echo "DEBUG: Args='${KLIPPER_ARGS}'"
### END Substep 3
