#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true  

# Override SteamCMD launch arguments if necessary
# Used for subscribing to betas or for testing
if [ -z "$STEAMCMD_UPDATE_ARGS" ]; then
	bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" +app_update "$STEAMAPPID_TOOL" +quit
else
	steamcmd_update_args=($STEAMCMD_UPDATE_ARGS)
	bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" +app_update "$STEAMAPPID_TOOL" "${steamcmd_update_args[@]}" +quit
fi

bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" +app_update "$STEAMAPPID_TOOL" +quit

exec bash "./launch.sh"
