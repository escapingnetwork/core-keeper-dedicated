#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true

# Initialize arguments array
args=(
    "+@sSteamCmdForcePlatformType" "linux"
    "+@sSteamCmdForcePlatformBitness" "64"
    "+force_install_dir" "$STEAMAPPDIR"
    "+login" "anonymous"
    "+app_update" "$STEAMAPPID" "validate"
    "+app_update" "$STEAMAPPID_TOOL" "validate"
)

# Override SteamCMD launch arguments if necessary
# Used for subscribing to betas or for testing
if [ -n "$STEAMCMD_UPDATE_ARGS" ]; then
    args+=("${STEAMCMD_UPDATE_ARGS[@]}")
fi

# Add the quit command
args+=("+quit")

# Run SteamCMD with the arguments
if [ "${USE_DEPOT_DOWNLOADER}" == true ]; then
    DepotDownloader -app $STEAMAPPID -osarch 64 -dir $STEAMAPPDIR -validate
    DepotDownloader -app $STEAMAPPID_TOOL -osarch 64 -dir $STEAMAPPDIR -validate
    chmod +x $STEAMAPPDIR/CoreKeeperServer
else
    "$STEAMCMDDIR/steamcmd.sh" "${args[@]}"
fi

exec bash "${SCRIPTSDIR}/launch.sh"
