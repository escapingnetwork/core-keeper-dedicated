#!/bin/bash

source "${SCRIPTSDIR}/mod-manager.sh"

mkdir -p "${STEAMAPPDIR}" || true

NEEDS_VALIDATION=false

if [ ! -f "${STEAMAPPDIR}/CoreKeeperServer" ]; then
    NEEDS_VALIDATION=true
fi

if [ "${USE_DEPOT_DOWNLOADER}" == true ]; then
    app_args=("-app" "$STEAMAPPID" "-osarch" "64" "-dir" "$STEAMAPPDIR")
    tool_args=("-app" "$STEAMAPPID_TOOL" "-osarch" "64" "-dir" "$STEAMAPPDIR")

    if [ "$NEEDS_VALIDATION" == true ]; then
        app_args+=("-validate")
        tool_args+=("-validate")
    fi

    DepotDownloader "${app_args[@]}"
    DepotDownloader "${tool_args[@]}"
    
else
    args=(
        "+@sSteamCmdForcePlatformType" "linux"
        "+@sSteamCmdForcePlatformBitness" "64"
        "+force_install_dir" "$STEAMAPPDIR"
        "+login" "anonymous"
    )

    app_args=("+app_update" "$STEAMAPPID")
    tool_args=("+app_update" "$STEAMAPPID_TOOL")

    if [ "$NEEDS_VALIDATION" == true ]; then
        app_args+=("validate")
        tool_args+=("validate")
    fi

    args+=("${app_args[@]}")
    args+=("${tool_args[@]}")

    if [ -n "$STEAMCMD_UPDATE_ARGS" ]; then
        args+=("${STEAMCMD_UPDATE_ARGS[@]}")
    fi

    args+=("+quit")

    "$STEAMCMDDIR/steamcmd.sh" "${args[@]}"
fi

chmod +x "$STEAMAPPDIR/CoreKeeperServer"

manage_mods

exec bash "${SCRIPTSDIR}/launch.sh"
