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

        if [[ "$line" == "Started session with info: "* ]]; then
            [[ "${DISCORD_SERVER_START_ENABLED,,}" == false ]] && continue

            game_info="${STEAMAPPDIR}/GameInfo.txt"
            game_info_timeout=5
            game_info_count=0

            LogDebug "Detecting file $game_info (max $game_info_timeout seconds)..."

            # GameInfo.txt creation can happen shortly after the log line appears
            until [[ -f "$game_info" ]] || [ "$game_info_count" -ge "$game_info_timeout" ]; do
                sleep 1
                ((game_info_count++))
            done

            if [[ ! -f "$game_info" ]]; then
                LogDebug "Failed to detect file $game_info after $game_info_timeout seconds"
            else

                LogDebug "Detected file $game_info, sending discord server start message"

                read -r gameid \
                        allowed_platforms \
                        public_ip \
                        port \
                        password  < <(
                    awk -F': ' '
                      BEGIN { gameid=""; allowed_platforms=""; public_ip=""; port=""; password=""; }
                      /^GameID:/ { gameid=$2 }
                      /^Allowed platforms:/ { allowed_platforms=$2 }
                      /^Public IP:/ { public_ip=$2 }
                      /^Port:/ { port=$2 }
                      /^Password:/ { password=$2 }
                      END { print gameid, allowed_platforms, public_ip, port, password }
                    ' "$game_info"
                )

                if [[ -n "$port" ]]; then # Port will be set in Direct Connection and is empty in Steam Datagram Relay
                    join_string="${public_ip}:${port}::${password}"
                fi

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
        fi
    done
}
