#!/bin/bash

declare -A characters

LogParser() {
    while IFS= read -r line; do
        echo "$line"

        if [[ "$line" == *"is using new name"* ]]; then

            # Extract the steamid and character name
            steamid=$(echo "$line" | awk -F'[[]|[ :]+|[]]' '{print $3}')
            char_name=$(echo "$line" | awk -F'new name ' '{print $2}')
            LogDebug "Character Name: $char_name ($steamid)"

            # Store character name for future use
            characters[$steamid]=$char_name

            [[ "${DISCORD_PLAYER_JOIN_ENABLED,,}" == false ]] && return 0

            # Build message from vars and send message
            message=$(char_name="$char_name" steamid="$steamid" envsubst <<<"$DISCORD_PLAYER_JOIN_MESSAGE")
            SendDiscordMessage "$DISCORD_PLAYER_JOIN_TITLE" "$message" "$DISCORD_PLAYER_JOIN_COLOR"
        fi

        if [[ "$line" == *"Disconnected from userid:"* ]]; then
            [[ "${DISCORD_PLAYER_LEAVE_ENABLED,,}" == false ]] && return 0

            # Extract steamid and reason
            steamid=$(echo "$line" | awk -F'[ :]+' '{print $4}')
            reason=$(echo "$line" | awk -F'with reason ' '{print $2}')
            char_name=${characters[$steamid]:-"Unknown"}
            LogDebug "Character Name: $char_name ($steamid)"

            # Build message from vars and send message
            message=$(char_name="$char_name" steamid="$steamid" reason="$reason" envsubst <<<"$DISCORD_PLAYER_LEAVE_MESSAGE")
            SendDiscordMessage "$DISCORD_PLAYER_LEAVE_TITLE" "$message" "$DISCORD_PLAYER_LEAVE_COLOR"
        fi

        if [[ "$line" == "Started session with Game ID "* ]]; then
            [[ "${DISCORD_SERVER_START_ENABLED,,}" == false ]] && return 0

            # Extract Game ID
            gameid=$(echo "$line" | awk '{print $6}')

            # Build message from vars and send message
            message=$(world_name="$WORLD_NAME" gameid="$gameid" envsubst <<<"$DISCORD_SERVER_START_MESSAGE")
            SendDiscordMessage "$DISCORD_SERVER_START_TITLE" "$message" "$DISCORD_SERVER_START_COLOR"
        fi
    done
}
