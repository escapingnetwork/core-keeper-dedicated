#!/bin/bash
source "${SCRIPTSDIR}/helper-functions.sh"

# From: https://github.com/thijsvanloef/palworld-server-docker/blob/32ffe489daecbc332701592f2facf0fe3237c65f/scripts/init.sh#L15
# Checks for root, updates UID and GID of user steam
# and updates folders owners
if [[ "$(id -u)" -eq 0 ]] && [[ "$(id -g)" -eq 0 ]]; then
    if [[ "${PUID}" -ne 0 ]] && [[ "${PGID}" -ne 0 ]]; then
        LogAction "EXECUTING USERMOD"
        usermod -o -u "${PUID}" "${USER}"
        groupmod -o -g "${PGID}" "${USER}"
        chown -R "${USER}:${USER}" "${HOMEDIR}"
    else
        LogError "Running as root is not supported, please fix your PUID and PGID!"
        exit 1
    fi
elif [[ "$(id -u)" -eq 0 ]] || [[ "$(id -g)" -eq 0 ]]; then
    LogError "Running as root is not supported, please fix your user!"
    exit 1
fi

if ! [ -w "${STEAMAPPDIR}" ]; then
    LogError "${STEAMAPPDIR} is not writable."
    exit 1
fi

if ! [ -w "${STEAMAPPDATADIR}" ]; then
    LogError "${STEAMAPPDATADIR} is not writable."
    exit 1
fi

#Restart cleanup
if [ -f "/tmp/.X99-lock" ]; then rm /tmp/.X99-lock; fi

if [[ "$(id -u)" -eq 0 ]]; then
    exec gosu "${USER}" bash "${SCRIPTSDIR}/setup.sh"
else
    exec bash "${SCRIPTSDIR}/setup.sh"
fi
