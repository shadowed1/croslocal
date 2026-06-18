#!/bin/bash
# LSB Spoofing by shadowed1
# Studio Microphone by justaguy

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

find /usr/local -mindepth 1 \
  \( -type d \( -name '*chard*' -o -name '*ChromeOS_PowerControl*' \) -prune \) -o \
  \( -name '*sudocrosh*' \) -o \
  -print 2>/dev/null

LSB_RELEASE="/etc/lsb-release"
BACKUP="${LSB_RELEASE}.bak"
BACKUP2="${LSB_RELEASE}.$(date +%Y%m%d-%H%M%S).bak"
cp "$LSB_RELEASE" "$BACKUP"
cp "$LSB_RELEASE" "$BACKUP2"
DEVBOARD="https://commondatastorage.googleapis.com/chromeos-dev-installer/board"

echo "${GREEN}Backed up as ${BOLD}$BACKUP ${RESET}${GREEN}and${BOLD} $BACKUP2${RESET}"

ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    NEW_BOARD="octopus"
elif [[ "$ARCH" == "aarch64" ]]; then
    NEW_BOARD="rauru"
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

printf 'n\n' | dev_install

BOARD=$(grep ^CHROMEOS_RELEASE_BOARD /etc/lsb-release | cut -d= -f2 | sed 's/-signed//')
VERSION=$(grep ^CHROMEOS_RELEASE_VERSION /etc/lsb-release | cut -d= -f2)
PORTAGE_BINHOST="https://commondatastorage.googleapis.com/chromeos-dev-installer/board/${BOARD}/${VERSION}/packages"
echo "PORTAGE_BINHOST=$PORTAGE_BINHOST"

ldconfig
PORTAGE_CONFIGROOT=/usr/local PORTAGE_BINHOST=$PORTAGE_BINHOST emerge --getbinpkg --usepkgonly --nodeps -v sys-devel/binutils

unset LD_LIBRARY_PATH LD_PRELOAD

sed -i '/libforcefm.so/d' /usr/share/cros/init/cras-env.sh 2>/dev/null || true

rm -f \
  /usr/local/force_fm.S \
  /usr/local/force_fm.o \
  /usr/local/libforcefm.so \
  /usr/lib64/libforcefm.so

dlcservice_util --install --id=nc-ap-dlc 2>&1 || true
dlcservice_util --dlc_state --id=nc-ap-dlc 2>&1 || true

ARCH=$(uname -m)

case "${ARCH}" in
    aarch64)
        TARGET="aarch64-cros-linux-gnu"
        ;;
    x86_64)
        TARGET="x86_64-cros-linux-gnu"
        ;;
    *)
        echo "${RED}Unsupported architecture: ${ARCH}${RESET}"
        sleep 3
        exit 1
        ;;
esac

BINUTILS_VERSION=$(
    find "/usr/local/${TARGET}/binutils-bin" -mindepth 1 -maxdepth 1 -type d \
    | sed 's#.*/##' \
    | sort -V \
    | tail -n1
)

if [ -z "${BINUTILS_VERSION}" ]; then
    echo "Unable to determine binutils version for ${TARGET}" >&2
    exit 1
fi

B="/usr/local/${TARGET}/binutils-bin/${BINUTILS_VERSION}"

if [ "${ARCH}" = "x86_64" ]; then
    BLIB="/usr/local/lib64/binutils/${TARGET}/${BINUTILS_VERSION}"
else
    BLIB="/usr/local/lib/binutils/${TARGET}/${BINUTILS_VERSION}"
fi

cat >/usr/local/force_fm.S <<'EOF'
.text
.globl _ZN12segmentation17FeatureManagement16IsFeatureEnabledERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE
.type _ZN12segmentation17FeatureManagement16IsFeatureEnabledERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE, @function
_ZN12segmentation17FeatureManagement16IsFeatureEnabledERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE:
  mov $1, %eax
  ret
.size _ZN12segmentation17FeatureManagement16IsFeatureEnabledERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE, .-_ZN12segmentation17FeatureManagement16IsFeatureEnabledERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE
EOF

LD_LIBRARY_PATH="$BLIB" \
  "$B/as" --64 \
  -o /usr/local/force_fm.o \
  /usr/local/force_fm.S

LD_LIBRARY_PATH="$BLIB" \
  "$B/ld" -shared \
  -o /usr/local/libforcefm.so \
  /usr/local/force_fm.o

cp -f /usr/local/libforcefm.so /usr/lib64/libforcefm.so
chown root:root /usr/lib64/libforcefm.so
chmod 4755 /usr/lib64/libforcefm.so

echo 'export LD_PRELOAD="libforcefm.so${LD_PRELOAD:+:$LD_PRELOAD}"' \
  >> /usr/share/cros/init/cras-env.sh

restart cras
sleep 2

grep -F libforcefm /proc/$(pidof cras)/maps || echo 'not loaded'

dbus-send \
  --system \
  --print-reply \
  --dest=org.chromium.cras \
  /org/chromium/cras \
  org.chromium.cras.Control.GetAudioEffectDlcs

dbus-send \
  --system \
  --print-reply \
  --dest=org.chromium.cras \
  /org/chromium/cras \
  org.chromium.cras.Control.IsStyleTransferSupported

dbus-send \
  --system \
  --print-reply \
  --dest=org.chromium.cras \
  /org/chromium/cras \
  org.chromium.cras.Control.GetVoiceIsolationUIAppearance

  mv /etc/lsb-release.bak /etc/lsb-release

find /usr/local -mindepth 1 \
  \( -type d \( -name '*chard*' -o -name '*ChromeOS_PowerControl*' \) -prune \) -o \
  \( -name '*sudocrosh*' \) -o \
  -print 2>/dev/null
