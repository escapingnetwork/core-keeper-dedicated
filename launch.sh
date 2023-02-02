#!/bin/bash

# Switch to workdir
cd "${STEAMAPPDIR}"

xvfbpid=""
ckpid=""

function kill_corekeeperserver {
        if [[ ! -z "$ckpid" ]]; then
                kill $ckpid
        fi
        sleep 1
        if [[ ! -z "$xvfbpid" ]]; then
                kill $xvfbpid
        fi
}

trap kill_corekeeperserver EXIT

if ! (dpkg -l xvfb >/dev/null) ; then
    echo "Installing xvfb dependency..."
    sleep 1
    sudo apt-get update -yy && sudo apt-get install xvfb -yy
fi

set -m

rm -f /tmp/.X99-lock

Xvfb :99 -screen 0 1x1x24 -nolisten tcp &
xvfbpid=$!

rm -f GameID.txt

chmod +x ./CoreKeeperServer

DISPLAY=:99 LD_LIBRARY_PATH="$LD_LIBRARY_PATH:../Steamworks SDK Redist/linux64/" ./CoreKeeperServer -batchmode -logfile -world "${WORLD_INDEX}" -worldname "${WORLD_NAME}" -worldseed "${WORLD_SEED}" -gameid "${GAME_ID}" -datapath "${STEAMAPPDATADIR}" -maxplayers "${MAX_PLAYERS}" -logfile CoreKeeperServerLog.txt -season "${SEASON}"&

ckpid=$!

echo "Started server process with pid $ckpid"

while [ ! -f GameID.txt ]; do
        sleep 0.1
done

gameid=$(cat GameID.txt)
echo "Game ID: ${gameid}"

if [ -z "$DISCORD" ]; then
	DISCORD=0
fi

if [ $DISCORD -eq 1 ]; then
    if [ -z "$DISCORD_HOOK" ]; then
	echo "Please set DISCORD_WEBHOOK url."
        else
        curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"${gameid}\"}" "${DISCORD_HOOK}"
    fi
fi

wait $ckpid
ckpid=""
