#!/bin/bash
source "${SCRIPTSDIR}/helper-functions.sh"

MODIO_CORE_KEEPER_ENDPOINT="${MODIO_API_URL}/games/@corekeeper/mods"

download_and_install_mod() {
  if [ -z "${MODIO_API_KEY}" ]; then
    LogError "MODIO_API_KEY is required for downloading mods"
    exit 1
  fi

  local mod_string_id="$1"
  local version="$2"

  # The mod.io API needs the mod string id to be prefixed with @
  local modio_mod_endpoint="${MODIO_CORE_KEEPER_ENDPOINT}/@${mod_string_id}"
  local download_url
  local actual_version

  local mod_info
  mod_info=$(curl -s "${modio_mod_endpoint}?api_key=${MODIO_API_KEY}")

  if [ -z "$mod_info" ]; then
    LogError "Failed to get mod info for mod ${mod_string_id}"
    exit 1
  fi

  local mod_name
  mod_name=$(echo "$mod_info" | jq -r ".name")

  if [ -n "$version" ]; then
    # Get all files for the mod
    local mod_files
    mod_files=$(curl -s "${modio_mod_endpoint}/files?api_key=${MODIO_API_KEY}")

    if [ -z "$mod_files" ]; then
      LogError "Failed to get mod files for ${mod_name} (${mod_string_id})"
      exit 1
    fi

    # Find the specified version
    download_url=$(echo "$mod_files" | jq -r ".data[] | select(.version == \"${version}\") | .download.binary_url")
    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
      LogError "Version ${version} not found for mod ${mod_name} (${mod_string_id})"
      exit 1
    fi
    actual_version="$version"
  else
    # Use latest version
    download_url=$(echo "$mod_info" | jq -r ".modfile.download.binary_url")
    actual_version=$(echo "$mod_info" | jq -r ".modfile.version")
  fi

  if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
    LogError "Failed to get download URL for mod ${mod_name} (${mod_string_id})"
    exit 1
  fi

  # Create temp directory for download
  local temp_dir
  temp_dir=$(mktemp -d)
  local temp_mod_download="${temp_dir}/${mod_string_id}.zip"

  local mod_dir="${MODSDIR}/${mod_string_id}"

  # Download and extract mod
  if curl -s -L "${download_url}?api_key=${MODIO_API_KEY}" -o "${temp_mod_download}"; then
    # Create mod directory and extract
    mkdir -p "${mod_dir}"
    unzip -q "${temp_mod_download}" -d "${mod_dir}"
    LogInfo "Installed ${mod_name} (${mod_string_id}) ${actual_version}"
  else
    LogError "Failed to install ${mod_name} (${mod_string_id}) ${actual_version}"
    exit 1
  fi

  # Cleanup
  rm -rf "${temp_dir}"
}

install_mods() {
  # Split the comma-separated list of mods
  IFS=',' read -ra mod_list <<< "$MODS"

  for mod_spec in "${mod_list[@]}"; do
    # Trim whitespace
    mod_spec=$(echo "$mod_spec" | tr -d '[:space:]')
    [ -z "$mod_spec" ] && continue

    local mod_string_id
    local version
    # Split into id and version
    if [[ "$mod_spec" =~ ":" ]]; then
      mod_string_id="${mod_spec%%:*}" # Everything before the colon
      version="${mod_spec#*:}" # Everything after the colon
    else
      mod_string_id="$mod_spec"
      version=""
    fi

    download_and_install_mod "$mod_string_id" "$version"
  done
}

manage_mods() {
  # We always clear the mods directory so the installed mods reflect exactly what was specified by the user
  rm -rf "${MODSDIR}"
  mkdir -p "${MODSDIR}"

  if [[ "${MODS_ENABLED,,}" != "true" ]]; then
    LogInfo "MODS_ENABLED is not true, skipping mod installation"
    return 0
  fi

  if [ -z "${MODS}" ]; then
    LogWarn "MODS_ENABLED is true but there are no mods specified"
    return 0
  fi

  LogInfo "Installing mods..."
  install_mods
}
