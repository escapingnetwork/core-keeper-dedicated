###########################################################
# Dockerfile that builds a Core Keeper Gameserver
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="leandro.martin@protonmail.com"

ENV STEAMAPPID 1007
ENV STEAMAPPID_TOOL 1963720
ENV STEAMAPP core-keeper
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"
ENV STEAMAPPDATADIR "${HOMEDIR}/${STEAMAPP}-data"
ENV DLURL https://raw.githubusercontent.com/arguser/core-keeper-dedicated

COPY ./entry.sh ${HOMEDIR}/entry.sh
COPY ./launch.sh ${HOMEDIR}/launch.sh

# Install Core Keeper server dependencies and clean up
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
	xvfb mesa-utils \
	&& mkdir -p "${STEAMAPPDIR}" \
	&& mkdir -p "${STEAMAPPDATADIR}" \
	&& chmod +x "${HOMEDIR}/entry.sh" \
	&& chmod +x "${HOMEDIR}/launch.sh" \
	&& chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${HOMEDIR}/launch.sh" "${STEAMAPPDIR}" \
	&& rm -rf /var/lib/apt/lists/*


ENV WORLD_INDEX=0 \
	WORLD_NAME="Core Keeper Server" \
	WORLD_SEED=0 \
	GAME_ID="" \
	DATA_PATH="" \
	MAX_PLAYERS=10

# Switch to user
USER ${USER}

# Switch to workdir
WORKDIR ${HOMEDIR}

VOLUME ${STEAMAPPDIR}

CMD ["bash", "entry.sh"] 
