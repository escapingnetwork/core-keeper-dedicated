#!/bin/bash

# This scripts compiles parameters from an ENV arg to an array
# this should be run with source, so the params ENV becomes avaliable.

add_param() {
    local param_name="$1"
    local param_value="$2"

    if [ -n "$param_value" ]; then
        params+=("$param_name" "$param_value")
    fi
}

# Makes log file avaliable for other uses.
logfile="${STEAMAPPDIR}/logs/$(date '+%Y-%m-%d_%H-%M-%S').log"
params=(
    "-batchmode" 
    "-logfile" "$logfile"
)

add_param "-world" "$WORLD_INDEX"
add_param "-worldname" "$WORLD_NAME"
add_param "-worldseed" "$WORLD_SEED"
add_param "-worldmode" "$WORLD_MODE"
add_param "-gameid" "$GAME_ID"
add_param "-datapath" "$DATA_PATH"
add_param "-maxplayers" "$MAX_PLAYERS"
add_param "-season" "$SEASON"
add_param "-ip" "$SERVER_IP"
add_param "-port" "$SERVER_PORT"

echo "${params[@]}"
