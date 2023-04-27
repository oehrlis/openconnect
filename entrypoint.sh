#!/usr/bin/env sh
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Data Platforms
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: entrypoint.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2023.04.27
# Revision...: 0.1.0
# Purpose....: Dockerfile to build a openconnect images
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------

# - Default Values -------------------------------------------------------------
SERVER=${SERVER:-""}                        # VPN endpoint
AUTHGROUP=${AUTHGROUP:-""}                  # VPN Authentication Group
USERNAME=${USERNAME:-""}                    # VPN Login username
PASSWORD=${PASSWORD:-""}                    # VPN Login primary password
TOKEN=${TOKEN:-""}                          # OTP Token
OPTIONS=${OPTIONS:-""}                      # Additional OpenConnect parameters / options
DYNAMIC_TOKEN=${DYNAMIC_TOKEN:-"TRUE"}      # TRUE if dynamic OTP is required, FALSE otherwise.
OC_PID=${OC_PID:-"/var/run/openconnect.pid"}  # OpenConnect PID file
# - EOF Default Values ---------------------------------------------------------
set -e

echo "ARGS:      $@"

echo "USER_GID: "${USER_GID:-9001}
echo "USER_UID: "${USER_UID:-9001}

# - Initialization -------------------------------------------------------------
if [ ! -r /vpn/vpn.config ]; then
  echo "ERR : Could not load config file from /vpn/vpn.config. Please check your volume config" 1>&2
  exit 1
else
  echo "INFO: Source /vpn/vpn.config"
  source /vpn/vpn.config
fi

# check if we do have a VPN server defined
if [ -z "$SERVER" ]; then
  echo "ERR : No server is set. Exiting." 1>&2
  exit 1
fi

# check if we do have a VPN user defined
if [ -z "$USERNAME" ]; then
  echo "ERR : No username is set. Exiting." 1>&2
  exit 1
fi

# Read password from file
if [ -r /vpn/passwd ]; then
  echo "INFO: Load vpn password from /vpn/passwd ..."
  read PASSWORD < /vpn/passwd
  while [ -z ${PASSWORD} ]; do
    sleep 1;
    echo "INFO: Please add password to file vpnpasswd ..."
    read PASSWORD < /vpn/token;
  done
  echo "INFO: Password provided ..."
else
  echo "ERR : Could not load password from /vpn/passwd. Please check your volume config" 1>&2
  exit 1
fi

# load token from file
if [ -r /vpn/token ]; then
  echo "INFO: Reading token..."
  read TOKEN < /vpn/token
  while [ -z ${TOKEN} ]; do
    sleep 1;
    echo "INFO: Please update token in file vpntoken ..."
    read TOKEN < /vpn/token;
  done
  echo "INFO: Token provided as ${TOKEN}"
else
  echo "ERR : Could not load token from /vpn/token. Please check your volume config" 1>&2
  exit 1
fi

# reset token in case of dynamic tokens
if [ "${DYNAMIC_TOKEN^^}" = "TRUE" ]; then
  echo "INFO: Resetting token for next use ..."
  echo "" > /vpn/token
fi

# Remove trailing newline, if any
SANED_VARS=( PASSWORD TOKEN )
for i in "${SANED_VARS[@]}"
do
  export "$i"="${!i%$'\n'}"
done

# update openconnect options with AuthGroup if defined
if [[ -n "${AUTHGROUP}" ]]; then
    OPTIONS="--authgroup=${AUTHGROUP} ${OPTIONS}"
fi

# generate host keys if not present
ssh-keygen -A

# reset password for vpn ssh user
VPN_PWD=$(pwgen -1 15)
echo "--------------------------------------------------------------------------------"
echo "- vpn password : $VPN_PWD"
echo "--------------------------------------------------------------------------------"
echo "vpn:$VPN_PWD" | chpasswd
chmod 600 /home/vpn/.ssh/authorized_keys
chown -R vpn:vpn /home/vpn/.ssh

# - Functions ------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Purpose....: Function to start openconnect
# ------------------------------------------------------------------------------
run () {
  echo "INFO: Starting openconnect ..."
  (
    echo -e "${PASSWORD}\n${TOKEN}\n"
    read -s
  ) | openconnect --pid-file=${OC_PID} --user=${USERNAME} ${OPTIONS} --passwd-on-stdin --no-dtls ${SERVER}
}
# - EOF Functions --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
echo "INFO: Start sshd ---------------------------------------------------------------"
# do not detach (-D), log to stderr (-e)
exec /usr/sbin/sshd -D -e &

# loop through function run to restart openconnect if necessary 
until (run); do
  echo "WARN: openconnect exited. Restarting process in 60 seconds…" >&2
  sleep 60
done
# --- EOF ----------------------------------------------------------------------