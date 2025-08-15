#!/bin/bash

declare -A characters

LogParser() {
    while IFS= read -r line; do
        echo "$line"

        if [[ "$line" == "[userid:"*"] player"*"connected islocalplayer="* ]]; then

            # Extract the steamid and character name
            steamid=$(echo "$line" | awk -F'[[]|[ :]+|[]]' '{print $3}')
            char_name=$(echo "$line" | awk -F'player | connected' '{print $2}')
            LogDebug "Character Name: $char_name ($steamid)"

            # Store character name for future use
            characters[$steamid]=$char_name

            [[ "${DISCORD_PLAYER_JOIN_ENABLED,,}" == false ]] && continue

            # Build message from vars and send message
            message=$(char_name="$char_name" steamid="$steamid" envsubst <<<"$DISCORD_PLAYER_JOIN_MESSAGE")
            SendDiscordMessage "$DISCORD_PLAYER_JOIN_TITLE" "$message" "$DISCORD_PLAYER_JOIN_COLOR"
        fi

        if [[ "$line" == *"Disconnected from userid:"* ]]; then
            [[ "${DISCORD_PLAYER_LEAVE_ENABLED,,}" == false ]] && continue

            # Extract steamid and reason
            steamid=$(echo "$line" | awk -F'[ :]+' '{print $4}')
            reason=$(echo "$line" | awk -F'with reason ' '{print $2}')
            char_name=${characters[$steamid]:-"Unknown"}
            LogDebug "Character Name: $char_name ($steamid)"

            # Build message from vars and send message
            message=$(char_name="$char_name" steamid="$steamid" reason="$reason" envsubst <<<"$DISCORD_PLAYER_LEAVE_MESSAGE")
            SendDiscordMessage "$DISCORD_PLAYER_LEAVE_TITLE" "$message" "$DISCORD_PLAYER_LEAVE_COLOR"
        fi

        if [[ "$line" == "World creation version is"* ]]; then
            [[ "${DISCORD_SERVER_START_ENABLED,,}" == false ]] && continue

            game_info="${STEAMAPPDIR}/GameInfo.txt"

            read -r gameid \
                    allowed_platforms \
                    public_ip \
                    port \
                    password \
                    join_string < <(
              awk -F': ' '
                BEGIN { gameid=""; allowed_platforms=""; public_ip=""; port=""; password=""; join_string="" }
                /^GameID:/ { gameid=$2 }
                /^Allowed platforms:/ { allowed_platforms=$2 }
                /^Public IP:/ { public_ip=$2 }
                /^Port:/ { port=$2 }
                /^Password:/ { password=$2 }
                /^Paste to ip-field/ { if (getline) join_string=$0 }
                END { print gameid, allowed_platforms, public_ip, port, password, join_string }
              ' "$game_info"
            )

            # Build message from vars and send message
            message=$(
                world_name="$WORLD_NAME" \
                gameid="$gameid" \
                allowed_platforms="$allowed_platforms" \
                public_ip="$public_ip" \
                port="$port" \
                password="$password" \
                join_string="$join_string" \
                envsubst <<<"$DISCORD_SERVER_START_MESSAGE"
            )
            SendDiscordMessage "$DISCORD_SERVER_START_TITLE" "$message" "$DISCORD_SERVER_START_COLOR"
        fi
    done
}
