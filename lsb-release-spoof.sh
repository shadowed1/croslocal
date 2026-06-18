#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

LSB_RELEASE="/etc/lsb-release"
BACKUP="${LSB_RELEASE}.bak"

cp "$LSB_RELEASE" "$BACKUP"
echo "${GREEN}Backed up to ${BOLD}$BACKUP${RESET}"
sleep 1

ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    NEW_BOARD="octopus"
elif [[ "$ARCH" == "aarch64" ]]; then
    NEW_BOARD="navi"
else
    echo "${RED}Unsupported arch: ${BOLD}$ARCH${RESET}"
    sleep 3
    exit 1
fi

echo "${CYAN}Arch: ${BOLD}$ARCH${RESET}${CYAN} -> spoofing board to: ${BOLD}$NEW_BOARD${RESET}"
sleep 1

sed -i \
    -e "s/^CHROMEOS_RELEASE_BOARD=.*/CHROMEOS_RELEASE_BOARD=${NEW_BOARD}/" \
    -e "s/^CHROMEOS_RELEASE_BUILDER_PATH=.*/CHROMEOS_RELEASE_BUILDER_PATH=${NEW_BOARD}-release\/R148-16640.61.0/" \
    -e "s/^CHROMEOS_RELEASE_DESCRIPTION=.*/CHROMEOS_RELEASE_DESCRIPTION=16640.61.0 (Official Build) stable-channel ${NEW_BOARD} /" \
    "$LSB_RELEASE"

echo "${MAGENTA}/etc/lsb-release ${BOLD}"
cat $LSB_RELEASE
echo "${RESET}"
