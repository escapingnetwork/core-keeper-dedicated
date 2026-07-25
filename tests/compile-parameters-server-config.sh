#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

contains_param_pair() {
    local key="$1"
    local value="$2"
    local index

    for index in "${!params[@]}"; do
        if [[ "${params[$index]}" == "$key" && "${params[$((index + 1))]:-}" == "$value" ]]; then
            return 0
        fi
    done

    return 1
}

contains_param() {
    local key="$1"
    local item

    for item in "${params[@]}"; do
        if [[ "$item" == "$key" ]]; then
            return 0
        fi
    done

    return 1
}

reset_env() {
    export STEAMAPPDIR="$tmp_root/server"
    export STEAMAPPDATADIR="$tmp_root/data"
    export WORLD_INDEX=0
    export WORLD_NAME="Core Keeper Server"
    export WORLD_SEED=""
    export WORLD_MODE=0
    export HASHED_WORLD_SEED=""
    export GAME_ID=""
    export DATA_PATH="$STEAMAPPDATADIR"
    export MAX_PLAYERS=10
    export SEASON=""
    export SERVER_IP=""
    export SERVER_PORT=""
    export ACTIVATE_CONTENT=""
    export PASSWORD=""
    export ALLOW_ONLY_PLATFORM=""
    export ACTIVATE_ALL_CONTENT=false
    export OVERRIDE_SERVER_CONFIG=""
    export MAX_NUMBER_PACKETS_SENT_PER_FRAME=""
    export NETWORK_SEND_RATE=""
    export CUSTOM_LAUNCH_PARAMS=""

    mkdir -p "$STEAMAPPDIR" "$STEAMAPPDATADIR"
}

compile_parameters() {
    params=()
    logfile=""
    # shellcheck source=../scripts/compile-parameters.sh
    source "$repo_root/scripts/compile-parameters.sh" >/dev/null
}

reset_env
compile_parameters

if contains_param "-serverconfig"; then
    fail "-serverconfig should not be emitted unless OVERRIDE_SERVER_CONFIG=true"
fi

if [[ -e "$STEAMAPPDATADIR/ServerConfig.generated.json" ]]; then
    fail "generated ServerConfig should not be written unless OVERRIDE_SERVER_CONFIG=true"
fi

reset_env
export OVERRIDE_SERVER_CONFIG=true
export MAX_NUMBER_PACKETS_SENT_PER_FRAME=4
export NETWORK_SEND_RATE=20
export WORLD_NAME='Farm "One"'
export WORLD_SEED="seed-value"
export HASHED_WORLD_SEED=123
export GAME_ID="ABCDEFGHIJKLMNOP"
export MAX_PLAYERS=12
export SEASON=3
export PASSWORD="direct-pass"

compile_parameters

config_path="$STEAMAPPDATADIR/ServerConfig.generated.json"

contains_param_pair "-serverconfig" "$config_path" || fail "expected -serverconfig $config_path"
contains_param_pair "-worldname" 'Farm "One"' || fail "existing WORLD_NAME CLI parameter was not preserved"
contains_param_pair "-maxplayers" "12" || fail "existing MAX_PLAYERS CLI parameter was not preserved"
[[ -f "$config_path" ]] || fail "generated ServerConfig file was not created"

grep -F '"worldName": "Farm \"One\""' "$config_path" >/dev/null || fail "worldName was not JSON escaped correctly"
grep -F '"worldSeed": "seed-value"' "$config_path" >/dev/null || fail "worldSeed missing from generated config"
grep -F '"hashedWorldSeed": 123' "$config_path" >/dev/null || fail "hashedWorldSeed missing from generated config"
grep -F '"maxNumberPlayers": 12' "$config_path" >/dev/null || fail "maxNumberPlayers missing from generated config"
grep -F '"maxNumberPacketsSentPerFrame": 4' "$config_path" >/dev/null || fail "maxNumberPacketsSentPerFrame missing from generated config"
grep -F '"networkSendRate": 20' "$config_path" >/dev/null || fail "networkSendRate missing from generated config"
grep -F '"seasonOverride": 3' "$config_path" >/dev/null || fail "seasonOverride missing from generated config"
grep -F '"password": "direct-pass"' "$config_path" >/dev/null || fail "password missing from generated config"

reset_env
export OVERRIDE_SERVER_CONFIG=false
export MAX_NUMBER_PACKETS_SENT_PER_FRAME=8
export NETWORK_SEND_RATE=20

compile_parameters

if contains_param "-serverconfig"; then
    fail "-serverconfig should not be emitted when OVERRIDE_SERVER_CONFIG=false"
fi

reset_env
export CUSTOM_LAUNCH_PARAMS="-keepserverrunning -modflag simple-value -quoted \"value with spaces\" -single 'single value'"

compile_parameters

contains_param "-keepserverrunning" || fail "custom standalone flag was not appended"
contains_param_pair "-modflag" "simple-value" || fail "custom flag/value pair was not appended"
contains_param_pair "-quoted" "value with spaces" || fail "custom double-quoted value was not preserved"
contains_param_pair "-single" "single value" || fail "custom single-quoted value was not preserved"
contains_param_pair "-maxplayers" "10" || fail "existing parameters should still be emitted with custom launch params"

echo "compile-parameters-server-config: ok"
