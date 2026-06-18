#!/bin/bash
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

cp /etc/lsb-release /home/chronos/user/MyFiles/Downloads/ 2>/dev/null
LSB_RELEASE="/etc/lsb-release"
BACKUP="${LSB_RELEASE}.bak"
cp "$LSB_RELEASE" "$BACKUP"
DEVBOARD="https://commondatastorage.googleapis.com/chromeos-dev-installer/board"

echo "${GREEN}Backed up as ${BOLD}$BACKUP ${RESET}${GREEN}and${BOLD} $BACKUP2${RESET}"

ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    NEW_BOARD="octopus"
elif [[ "$ARCH" == "aarch64" ]]; then
    NEW_BOARD="navi"
else
    echo "${RED}Unsupported arch: ${BOLD}$ARCH ${RESET}"
    sleep 3
    exit 1
fi

echo "${BLUE}Arch: $ARCH -> spoofing board to: $NEW_BOARD${RESET}"

BUILD=$(grep "^CHROMEOS_RELEASE_BUILD_NUMBER=" "$LSB_RELEASE" | cut -d= -f2)
MILESTONE=$(grep "^CHROMEOS_RELEASE_CHROME_MILESTONE=" "$LSB_RELEASE" | cut -d= -f2)

echo "${CYAN}Searching for valid versions for $NEW_BOARD -> $BUILD${RESET}"
NEW_VERSION=""
for PATCH in $(seq 0 99); do
    CANDIDATE="${BUILD}.${PATCH}.0"
    URL="${DEVBOARD}/${NEW_BOARD}/${CANDIDATE}/packages/Packages"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    if [[ "$HTTP_CODE" == "200" ]]; then
        NEW_VERSION="$CANDIDATE"
        echo "${GREEN}Found valid version: $NEW_VERSION${RESET}"
        break
    fi
done

if [[ -z "$NEW_VERSION" ]]; then
    echo "${RED}ERROR: No valid version found for board '$NEW_BOARD' -> $BUILD ${RESET}"
    sleep 3
    exit 1
fi

sed -i \
    -e "s/^CHROMEOS_RELEASE_BOARD=.*/CHROMEOS_RELEASE_BOARD=${NEW_BOARD}/" \
    -e "s/^CHROMEOS_RELEASE_BUILDER_PATH=.*/CHROMEOS_RELEASE_BUILDER_PATH=${NEW_BOARD}-release\/R${MILESTONE}-${NEW_VERSION}/" \
    -e "s/^CHROMEOS_RELEASE_DESCRIPTION=.*/CHROMEOS_RELEASE_DESCRIPTION=${NEW_VERSION} (Official Build) stable-channel ${NEW_BOARD} /" \
    "$LSB_RELEASE"

echo "${MAGENTA}Result:"
grep -E "BOARD|BUILDER_PATH|DESCRIPTION" "$LSB_RELEASE"
echo "${RESET}"
