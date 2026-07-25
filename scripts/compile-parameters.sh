#!/bin/bash

# This scripts compiles parameters from an set of ENV variables to an array
# this should be run with source, so the params ENV becomes avaliable.

# Function to add arguments to parameter array
# usage: add_param <name> <$env_value>
add_param() {
    local param_name="$1"
    local param_value="$2"

    if [ -n "$param_value" ]; then
        params+=("$param_name" "$param_value")
    fi
}

# Function to add flags to parameter array
# usage: add_flag <name> <$env_value>
add_flag() {
    local flag_name="$1"
    local flag_value="$2"

    if [ "${flag_value,,}" = "true" ]; then
        params+=("$flag_name")
    fi
}

append_custom_launch_params() {
    local input="${CUSTOM_LAUNCH_PARAMS:-}"
    local current=""
    local quote=""
    local char
    local escape=0
    local token_started=0
    local i
    local -a custom_params=()

    if [ -z "$input" ]; then
        return
    fi

    for ((i = 0; i < ${#input}; i++)); do
        char="${input:i:1}"

        if [ "$escape" -eq 1 ]; then
            current+="$char"
            token_started=1
            escape=0
            continue
        fi

        if [ "$quote" = "\"" ]; then
            if [ "$char" = "\\" ]; then
                escape=1
            elif [ "$char" = "\"" ]; then
                quote=""
            else
                current+="$char"
                token_started=1
            fi
            continue
        fi

        if [ "$quote" = "'" ]; then
            if [ "$char" = "'" ]; then
                quote=""
            else
                current+="$char"
                token_started=1
            fi
            continue
        fi

        case "$char" in
            [[:space:]])
                if [ "$token_started" -eq 1 ]; then
                    custom_params+=("$current")
                    current=""
                    token_started=0
                fi
                ;;
            "'")
                quote="'"
                token_started=1
                ;;
            "\"")
                quote="\""
                token_started=1
                ;;
            "\\")
                escape=1
                token_started=1
                ;;
            *)
                current+="$char"
                token_started=1
                ;;
        esac
    done

    if [ "$escape" -eq 1 ]; then
        current+="\\"
    fi

    if [ -n "$quote" ]; then
        echo "Invalid CUSTOM_LAUNCH_PARAMS: unmatched quote" >&2
        exit 1
    fi

    if [ "$token_started" -eq 1 ]; then
        custom_params+=("$current")
    fi

    params+=("${custom_params[@]}")
}

json_string() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"

    printf '"%s"' "$value"
}

json_int_or_default() {
    local name="$1"
    local value="$2"
    local default="$3"

    if [ -z "$value" ]; then
        printf '%s' "$default"
        return
    fi

    if [[ "$value" =~ ^-?[0-9]+$ ]]; then
        printf '%s' "$value"
        return
    fi

    echo "Invalid integer value for ${name}: ${value}" >&2
    exit 1
}

generate_server_config() {
    local data_path="${DATA_PATH:-${STEAMAPPDATADIR:-}}"
    local server_config="${data_path}/ServerConfig.generated.json"
    local world
    local hashed_world_seed
    local max_players
    local max_number_packets_sent_per_frame
    local network_send_rate
    local world_mode
    local season_override

    world="$(json_int_or_default "WORLD_INDEX" "${WORLD_INDEX:-}" 0)" || exit 1
    hashed_world_seed="$(json_int_or_default "HASHED_WORLD_SEED" "${HASHED_WORLD_SEED:-}" 0)" || exit 1
    max_players="$(json_int_or_default "MAX_PLAYERS" "${MAX_PLAYERS:-}" 10)" || exit 1
    max_number_packets_sent_per_frame="$(json_int_or_default "MAX_NUMBER_PACKETS_SENT_PER_FRAME" "${MAX_NUMBER_PACKETS_SENT_PER_FRAME:-}" 1)" || exit 1
    network_send_rate="$(json_int_or_default "NETWORK_SEND_RATE" "${NETWORK_SEND_RATE:-}" 20)" || exit 1
    world_mode="$(json_int_or_default "WORLD_MODE" "${WORLD_MODE:-}" 0)" || exit 1
    season_override="$(json_int_or_default "SEASON" "${SEASON:-}" -1)" || exit 1

    mkdir -p "$(dirname "$server_config")"

    cat > "$server_config" <<EOF
{
    "gameId": $(json_string "${GAME_ID:-}"),
    "password": $(json_string "${PASSWORD:-}"),
    "world": ${world},
    "worldName": $(json_string "${WORLD_NAME:-}"),
    "worldSeed": $(json_string "${WORLD_SEED:-}"),
    "hashedWorldSeed": ${hashed_world_seed},
    "maxNumberPlayers": ${max_players},
    "maxNumberPacketsSentPerFrame": ${max_number_packets_sent_per_frame},
    "networkSendRate": ${network_send_rate},
    "worldMode": ${world_mode},
    "seasonOverride": ${season_override}
}
EOF

    params+=("-serverconfig" "$server_config")
}

# Makes log file avaliable for other uses.
logfile="${STEAMAPPDIR}/logs/$(date '+%Y-%m-%d_%H-%M-%S').log"
params=(
    "-batchmode"
    "-logfile" "$logfile"
)

override_server_config="${OVERRIDE_SERVER_CONFIG:-}"
if [ "${override_server_config,,}" = "true" ]; then
    generate_server_config
fi

add_param "-world"              "${WORLD_INDEX}"
add_param "-worldname"          "${WORLD_NAME}"
add_param "-worldseed"          "${WORLD_SEED}"
add_param "-worldmode"          "${WORLD_MODE}"
add_param "-hashedworldseed"    "${HASHED_WORLD_SEED}"
add_param "-gameid"             "${GAME_ID}"
add_param "-datapath"           "${DATA_PATH:-${STEAMAPPDATADIR}}"
add_param "-maxplayers"         "${MAX_PLAYERS}"
add_param "-season"             "${SEASON}"
add_param "-ip"                 "${SERVER_IP}"
add_param "-port"               "${SERVER_PORT}"
add_param "-activatecontent"    "${ACTIVATE_CONTENT}"
add_param "-password"           "${PASSWORD}"
add_param "-allowonlyplatform"  "${ALLOW_ONLY_PLATFORM}"

add_flag "-activateallcontent"  "${ACTIVATE_ALL_CONTENT}"

append_custom_launch_params

echo "${params[@]}"
