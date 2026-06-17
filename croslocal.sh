#/bin/bash
# Created by https://github.com/justaguy
# Edited by https://github.com/shadowed1

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

if [ "$(whoami)" != "root" ]; then
    echo "${YELLOW}Please log into VT-2 as ${RESET}${RED}${BOLD}root${RESET}${YELLOW} for this script.${RESET}"
    sleep 3
    exit 0
fi
echo "${BLUE}${BOLD}This script will enable Guest Login for ChromeOS.${RESET}${BOLD}"
echo "${BLUE}Please enable Debugging Features during setup if you want the local account to be the owner! ${RESET}"

while true; do
    read -rp "${YELLOW}${BOLD}Proceed with Local Account creation?${RESET}${BOLD} (Y/n): ${RESET}" confirm
    case "$confirm" in
        [Yy]* | "")
            break
            ;;
        [Nn]*)
            echo "${BLUE}Cancelled.${RESET}"
            sleep 3
            exit 0
            ;;
        *)
            echo "${RED}Please answer Y/n.${RESET}"
            ;;
    esac
done

U='username@mustbeinthisformat'
P='password'
N='display name'
G='NameOnlyOneWord'
L='gaia' # DONT CHANGE PLZZZZ
H="$(cryptohome --action=obfuscate_user --user="$U" 2>/dev/null | tail -1)"
PY="$(command -v python3 || command -v python)"\
CH="$(

[ -n "$PY" ] || {
  dev_install --only_bootstrap
}

if [ ! -f /usr/sbin/cryptohome ]; then
    dev_install --only_bootstrap
fi

cp -a "/home/chronos/Local State" "/home/chronos/Local State.bak.localacct"

if ! cryptohome --action=is_mounted --user="$U" | grep -q true; then
  OUT="$(cryptohome --action=start_auth_session --user="$U" --auth_intent=AUTH_INTENT_DECRYPT 2>&1)"
  SID="$(printf '%s\n' "$OUT" | awk '/auth_session_id:/ {print $2; exit}' | tr -d '"')"

  if cryptohome --action=list_auth_factors --user="$U" 2>&1 | grep -q 'label: gaia'; then
    cryptohome --action=authenticate_auth_factor \
      --auth_session_id="$SID" \
      --key_label="$L" \
      --password="$P"
  else
    cryptohome --action=create_persistent_user \
      --auth_session_id="$SID"

    cryptohome --action=add_auth_factor \
      --auth_session_id="$SID" \
      --key_label="$L" \
      --password="$P"
  fi

  cryptohome --action=prepare_persistent_vault \
    --auth_session_id="$SID"
fi

U="$U" N="$N" G="$G" "$PY" - <<'PY'
import json, os

path = '/home/chronos/Local State'
user = os.environ['U']
display_name = os.environ['N']
given_name = os.environ['G']

with open(path) as f:
    data = json.load(f)

known_users = data.setdefault('KnownUsers', [])
entry = next(
    (
        x for x in known_users
        if isinstance(x, dict) and x.get('email', '').lower() == user.lower()
    ),
    None,
)

if entry is None:
    entry = {'email': user}
    known_users.append(entry)

entry.update({
    'email': user,
    'profile_requires_policy': False,
    'using_saml': False,
    'using_saml_principals_api': False,
    'is_enterprise_managed': False,
    'last_input_method': 'xkb:us::eng',
    'reauth_reason': 0,
})

for key in ('gaps_cookie', 'enterprise_account_manager', 'onboarding_screen_pending'):
    entry.pop(key, None)

logged_in = [x for x in data.setdefault('LoggedInUsers', []) if x != user]
data['LoggedInUsers'] = [user] + logged_in

data.setdefault('UserDisplayName', {})[user] = display_name
data.setdefault('UserGivenName', {})[user] = given_name
data.setdefault('UserDisplayEmail', {})[user] = user
data.setdefault('UserForceOnlineSignin', {})[user] = False
data.setdefault('OAuthTokenStatus', {})[user] = 1
data.setdefault('UserType', {})[user] = 0

data['LastActiveUser'] = user
data['LastLoggedInRegularUser'] = user

with open(path, 'w') as f:
    json.dump(data, f, separators=(',', ':'))
PY

mkdir -p "/home/user/$H/.pki/nssdb"
[ -f "/home/user/$H/Preferences" ] || printf '{}\n' >"/home/user/$H/Preferences"
chown -R chronos:chronos "/home/user/$H" 2>/dev/null

cp -a /etc/chrome_dev.conf /etc/chrome_dev.conf.bak.localacct 2>/dev/null || true

for f in \
  --disable-gaia-services \
  --skip-force-online-signin-for-testing \
  --allow-failed-policy-fetch-for-test
do
  grep -qx -- "$f" /etc/chrome_dev.conf 2>/dev/null || echo "$f" >>/etc/chrome_dev.conf
done

dbus-send \
  --system \
  --print-reply \
  --dest=org.chromium.SessionManager \
  /org/chromium/SessionManager \
  org.chromium.SessionManagerInterface.EnableChromeTesting \
  boolean:true \
  array:string:"--login-user=$U","--login-profile=$H","--oobe-skip-postlogin","--disable-gaia-services","--skip-force-online-signin-for-testing","--allow-failed-policy-fetch-for-test" \
  array:string:
