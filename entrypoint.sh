#!/usr/bin/env sh
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Data Platforms
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: entrypoint.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2023.04.26
# Revision...: 1.0
# Purpose....: Dockerfile to build a openconnect images
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------
set -e

echo "ARGS:      $@"

echo "USER_GID: "${USER_GID:-9001}
echo "USER_UID: "${USER_UID:-9001}

# generate host keys if not present
ssh-keygen -A

ROOT_PWD=$(pwgen -1 15)
echo "--------------------------------------"
echo "- root password : $ROOT_PWD"
echo "--------------------------------------"
echo "root:$ROOT_PWD" | chpasswd

# do not detach (-D), log to stderr (-e)
exec /usr/sbin/sshd -D -e &

if [[ -n "${OPENCONNECT_AUTHGROUP}" ]]; then
    OPENCONNECT_OPTIONS="--authgroup=${OPENCONNECT_AUTHGROUP} ${OPENCONNECT_OPTIONS}"
fi

run () {
  # Start openconnect
  if [[ -z "${OPENCONNECT_PASSWORD}" ]]; then
  # Ask for password
    echo "run : openconnect -u \"$OPENCONNECT_USER\" $OPENCONNECT_OPTIONS $OPENCONNECT_URL"
    openconnect -u "$OPENCONNECT_USER" $OPENCONNECT_OPTIONS $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]] && [[ ! -z "${OPENCONNECT_MFA_CODE}" ]]; then
  # Multi factor authentication (MFA)
    echo "run : openconnect -u \"$OPENCONNECT_USER\" $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL with pwd and mfa"
    (echo $OPENCONNECT_PASSWORD; echo $OPENCONNECT_MFA_CODE) | openconnect -u "$OPENCONNECT_USER" $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]]; then
  # Standard authentication
    echo "run : openconnect -u \"$OPENCONNECT_USER\" $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL with pwd"
    echo $OPENCONNECT_PASSWORD | openconnect -u "$OPENCONNECT_USER" $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL
  fi
}

until (run); do
  echo "openconnect exited. Restarting process in 60 seconds…" >&2
  sleep 60
done
# --- EOF ----------------------------------------------------------------------