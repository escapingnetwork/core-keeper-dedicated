###########################################################
# Dockerfile that builds a Core Keeper Gameserver
###########################################################
FROM cm2network/steamcmd:root AS base-amd64
FROM --platform=arm64 sonroyaalmerol/steamcmd-arm64:root-2024-11-24 AS base-arm64

ARG TARGETARCH
FROM base-${TARGETARCH}

LABEL maintainer="leandro.martin@protonmail.com"

ENV STEAMAPPID=1007
ENV STEAMAPPID_TOOL=1963720
ENV STEAMAPP=core-keeper
ENV STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"
ENV STEAMAPPDATADIR="${HOMEDIR}/${STEAMAPP}-data"
ENV SCRIPTSDIR="${HOMEDIR}/scripts"
ENV MODSDIR="${STEAMAPPDATADIR}/StreamingAssets/Mods"
ENV DLURL=https://raw.githubusercontent.com/escapingnetwork/core-keeper-dedicated

ARG TARGETARCH
RUN case "${TARGETARCH}" in \
    "amd64") dpkg --add-architecture i386 ;; \
    esac

# Install Core Keeper server dependencies and clean up
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        xvfb \
        libxi6 \
        tini \
        tzdata \
        gosu \
        jo \
        gettext-base \
        unzip \
	wget \
    && rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
    "arm64") apt-get update \
        && apt-get install -y --no-install-recommends --no-install-suggests \
            libmonosgen-2.0-1 \
            libdbus-1-3 \
            libxcursor1 \
            libxinerama1 \
            libxss1 \
            libatomic1 \
            libpulse0 \
	&& rm -rf /var/lib/apt/lists/* ;; \
    esac

# Download Depot downloader
ARG DEPOT_DOWNLOADER_VERSION="2.7.4"
RUN case "${TARGETARCH}" in \
        "amd64") DEPOT_DOWNLOADER_FILENAME=DepotDownloader-linux-x64.zip ;; \
        "arm64") DEPOT_DOWNLOADER_FILENAME=DepotDownloader-linux-arm64.zip ;; \
    esac \
    && wget --progress=dot:giga "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/${DEPOT_DOWNLOADER_FILENAME}" -O DepotDownloader.zip \
    && unzip DepotDownloader.zip \
    && rm -rf DepotDownloader.xml \
    && chmod +x DepotDownloader \
    && mv DepotDownloader /usr/local/bin/DepotDownloader

# Setup X11 Sockets folder
RUN mkdir /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix \
    && chown root /tmp/.X11-unix

# Box64/86 configuration
ENV BOX64_DYNAREC_BIGBLOCK=0 \
    BOX64_DYNAREC_SAFEFLAGS=2 \
    BOX64_DYNAREC_STRONGMEM=3 \
    BOX64_DYNAREC_FASTROUND=0 \
    BOX64_DYNAREC_FASTNAN=0 \
    BOX64_DYNAREC_X87DOUBLE=1 \
    BOX64_DYNAREC_BLEEDING_EDGE=0 \
    BOX86_DYNAREC_BIGBLOCK=0 \
    BOX86_DYNAREC_SAFEFLAGS=2 \
    BOX86_DYNAREC_STRONGMEM=3 \
    BOX86_DYNAREC_FASTROUND=0 \
    BOX86_DYNAREC_FASTNAN=0 \
    BOX86_DYNAREC_X87DOUBLE=1 \
    BOX86_DYNAREC_BLEEDING_EDGE=0

# Setup folders
COPY ./scripts ${SCRIPTSDIR}
RUN set -x \
    && chmod +x -R "${SCRIPTSDIR}" \
    && mkdir -p "${STEAMAPPDIR}" \
    && mkdir -p "${STEAMAPPDATADIR}" \
    && chown -R "${USER}:${USER}" "${SCRIPTSDIR}" "${STEAMAPPDIR}" "${STEAMAPPDATADIR}"

# Declare envs and their default values
ENV PUID=1000 \
    PGID=1000 \
    USE_DEPOT_DOWNLOADER=false \
    WORLD_INDEX=0 \
    WORLD_NAME="Core Keeper Server" \
    WORLD_SEED=0 \
    WORLD_MODE=0 \
    GAME_ID="" \
    DATA_PATH="${STEAMAPPDATADIR}" \
    MAX_PLAYERS=10 \
    SEASON="" \
    SERVER_IP="" \
    SERVER_PORT="" \
    DISCORD_WEBHOOK_URL="" \
    # Player Join
    DISCORD_PLAYER_JOIN_ENABLED=true \
    DISCORD_PLAYER_JOIN_MESSAGE='${char_name} (${steamid}) has joined the server.' \
    DISCORD_PLAYER_JOIN_TITLE="Player Joined" \
    DISCORD_PLAYER_JOIN_COLOR="47456" \
    # Player Leave
    DISCORD_PLAYER_LEAVE_ENABLED=true \
    DISCORD_PLAYER_LEAVE_MESSAGE='${char_name} (${steamid}) has disconnected. Reason: ${reason}.' \
    DISCORD_PLAYER_LEAVE_TITLE="Player Left" \
    DISCORD_PLAYER_LEAVE_COLOR="11477760" \
    # Server Start
    DISCORD_SERVER_START_ENABLED=true \
    DISCORD_SERVER_START_MESSAGE='**World:** ${world_name}\n**GameID:** ${gameid}' \
    DISCORD_SERVER_START_TITLE="Server Started" \
    DISCORD_SERVER_START_COLOR="2013440" \
    # Server Stop
    DISCORD_SERVER_STOP_ENABLED=true \
    DISCORD_SERVER_STOP_MESSAGE="" \
    DISCORD_SERVER_STOP_TITLE="Server Stopped" \
    DISCORD_SERVER_STOP_COLOR="12779520"

# Switch to workdir
WORKDIR ${HOMEDIR}

# Use tini as the entrypoint for signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["bash", "scripts/entry.sh"]
