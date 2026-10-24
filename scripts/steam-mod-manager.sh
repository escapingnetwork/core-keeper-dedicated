#!/bin/bash
source "${SCRIPTSDIR}/helper-functions.sh"

# Workshop items belong to the Core Keeper game app, not the dedicated server app
STEAM_WORKSHOP_CONTENT_DIR="${STEAMAPPDIR}/steamapps/workshop/content/${STEAM_WORKSHOP_APPID}"

# Copy every folder containing a ModManifest.json from a downloaded workshop item into $MODSDIR.
# Copying (rather than moving) keeps the workshop cache intact so steamcmd can skip unchanged items.
install_steam_mod() {
  local mod_id="$1"
  local item_dir="${STEAM_WORKSHOP_CONTENT_DIR}/${mod_id}"

  if [ ! -d "${item_dir}" ]; then
    LogError "Steam Workshop mod ${mod_id} was not downloaded"
    exit 1
  fi

  local manifests=()
  mapfile -t manifests < <(find "${item_dir}" -type f -name "ModManifest.json")

  if [ "${#manifests[@]}" -eq 0 ]; then
    LogError "Steam Workshop mod ${mod_id} does not contain a ModManifest.json"
    exit 1
  fi

  local manifest mod_src mod_dest
  for manifest in "${manifests[@]}"; do
    mod_src="$(dirname "${manifest}")"
    if [ "${mod_src}" = "${item_dir}" ]; then
      mod_dest="${MODSDIR}/${mod_id}"
    else
      mod_dest="${MODSDIR}/$(basename "${mod_src}")"
    fi

    rm -rf "${mod_dest}"
    cp -a "${mod_src}" "${mod_dest}"
    LogInfo "Installed Steam Workshop mod ${mod_id} to ${mod_dest}"
  done
}

manage_steam_mods() {
  if [ -z "${STEAM_WORKSHOP_MODS}" ]; then
    LogInfo "STEAM_WORKSHOP_MODS is empty, skipping Steam Workshop mod installation"
    return 0
  fi

  local raw_list=() mod_ids=() mod_id
  local -A seen=()
  IFS=',' read -ra raw_list <<< "${STEAM_WORKSHOP_MODS}"
  for mod_id in "${raw_list[@]}"; do
    mod_id=$(echo "${mod_id}" | tr -d '[:space:]')
    [ -z "${mod_id}" ] && continue
    if [[ ! "${mod_id}" =~ ^[0-9]+$ ]]; then
      LogError "Invalid Steam Workshop mod id: ${mod_id}"
      exit 1
    fi
    [ -n "${seen[${mod_id}]}" ] && continue
    seen[${mod_id}]=1
    mod_ids+=("${mod_id}")
  done

  if [ "${#mod_ids[@]}" -eq 0 ]; then
    LogWarn "STEAM_WORKSHOP_MODS is set but contains no mod ids"
    return 0
  fi

  local args=(
    "+@sSteamCmdForcePlatformType" "linux"
    "+@sSteamCmdForcePlatformBitness" "64"
    "+force_install_dir" "${STEAMAPPDIR}"
    "+login" "anonymous"
  )
  for mod_id in "${mod_ids[@]}"; do
    args+=("+workshop_download_item" "${STEAM_WORKSHOP_APPID}" "${mod_id}")
  done
  args+=("+quit")

  LogInfo "Downloading Steam Workshop mods..."
  "${STEAMCMDDIR}/steamcmd.sh" "${args[@]}"

  mkdir -p "${MODSDIR}"
  for mod_id in "${mod_ids[@]}"; do
    install_steam_mod "${mod_id}"
  done
}
