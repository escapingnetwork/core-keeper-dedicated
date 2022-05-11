#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true  

# Override SteamCMD launch arguments if necessary
# Used for subscribing to betas or for testing
# if [ -z "$STEAMCMD_UPDATE_ARGS" ]; then
# 	bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" +app_update "$STEAMAPPID_TOOL" +quit
# else
# 	steamcmd_update_args=($STEAMCMD_UPDATE_ARGS)
# 	bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" +app_update "$STEAMAPPID_TOOL" "${steamcmd_update_args[@]}" +quit
# fi

bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" +app_update "$STEAMAPPID_TOOL" +quit

# Switch to workdir
cd "${STEAMAPPDIR}"

bash "./_launch.sh" \
			-world "${WORLD_INDEX}" \
			-worldname="${WORLD_NAME}" \
			-worldseed="${WORLD_SEED}" \
			-gameid="${GAME_ID}" \
			-datapath="${STEAMAPPDIR}/${DATA_PATH}" \
			-maxplayers="${MAX_PLAYERS}"
