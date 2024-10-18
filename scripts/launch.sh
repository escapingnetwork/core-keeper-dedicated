#!/bin/bash

# Switch to workdir
cd "${STEAMAPPDIR}"

### Function for gracefully shutdown
function kill_corekeeperserver {
	if [[ -n "$ckpid" ]]; then
		kill $ckpid
		wait $ckpid
	fi
	if [[ ! -z "$xvfbpid" ]]; then
		kill $xvfbpid
		wait $xvfbpid
	fi
}

trap kill_corekeeperserver EXIT

if [ -f "GameID.txt" ]; then rm GameID.txt; fi

# Compile Parameters
# Populates `params` array with parameters.
# Creates `logfile` var with log file path.
source "${SCRIPTSDIR}/compile-parameters.sh"

# Create the log file and folder.
mkdir -p "${STEAMAPPDIR}/logs"
touch "$logfile"

# Start Xvfb
Xvfb :99 -screen 0 1x1x24 -nolisten tcp &
xvfbpid=$!

# Start Core Keeper Server
DISPLAY=:99 LD_LIBRARY_PATH="$LD_LIBRARY_PATH:../Steamworks SDK Redist/linux64/" ./CoreKeeperServer "${params[@]}" &
ckpid=$!

echo "Started server process with pid ${ckpid}"

tail --pid "$ckpid" -n +1 -f "$logfile" &

until [ -f GameID.txt ]; do
	sleep 0.1
done

gameid=$(<GameID.txt)
if [ -n "$DISCORD_HOOK" ]; then
	format="${DISCORD_PRINTF_STR:-%s}"
	curl -fsSL -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"$(printf "${format}" "${gameid}")\"}" "${DISCORD_HOOK}"
fi

wait $ckpid
