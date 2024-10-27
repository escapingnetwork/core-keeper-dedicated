#!/bin/bash


## Logging Functions
declare -A COLORS=(
    ["RESET"]='\033[0m'
    ["WHITE"]='\033[0;37m'
    ["RED_BOLD"]='\033[1;31m'
    ["GREEN_BOLD"]='\033[1;32m'
    ["YELLOW_BOLD"]='\033[1;33m'
    ["CYAN_BOLD"]='\033[1;36m'
    ["BLUE"]='\033[0;34m'
)

# Generic logging function
Log() {
    local message="$1"
    local color="$2"
    printf "${color}%s${COLORS["RESET"]}\n" "$message"
}

# Specific logging functions
LogInfo() {
    Log "$1" "${COLORS["WHITE"]}"
}
LogWarn() {
    Log "$1" "${COLORS["YELLOW_BOLD"]}"
}
LogError() {
    Log "$1" "${COLORS["RED_BOLD"]}"
}
LogSuccess() {
    Log "$1" "${COLORS["GREEN_BOLD"]}"
}
LogAction() {
    Log "$1" "${COLORS["CYAN_BOLD"]}"
}
LogDebug() {
    if [[ "${DEBUG,,}" == true ]]; then
        Log "$1" "${COLORS["BLUE"]}"
    fi
}

SendDiscordMessage() {
  local title="$1"
  local message="$2"
  local color="$3"
  local wait="$4"

  if [ -n "${DISCORD_WEBHOOK_URL}" ]; then
    # printf is to solve issues with literal \n and jo
    # shellcheck disable=SC2059
    "${SCRIPTSDIR}"/discord.sh "$title" "$(printf "$message")" "$color" &
    waitpid=$!
  fi

  if [[ "${wait,,}" == true ]]; then
    wait "$waitpid"
  fi
}
