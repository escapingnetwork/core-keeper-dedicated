#!/bin/bash
source "${SCRIPTSDIR}/helper-functions.sh"

MODS_MANIFEST="${MODSDIR}/.manifest"
MODIO_CORE_KEEPER_ID="5289"
MODIO_CORE_KEEPER_ENDPOINT="${MODIO_API_URL}/games/${MODIO_CORE_KEEPER_ID}/mods"

mkdir -p "${MODSDIR}"

download_and_install_mod() {
  if [ -z "${MODIO_API_KEY}" ]; then
    LogError "MODIO_API_KEY is required for downloading mods"
    return 1
  fi

  local mod_id="$1"
  local version="$2"
  local download_url
  local actual_version

  local mod_info
  mod_info=$(curl -s \
    "${MODIO_CORE_KEEPER_ENDPOINT}/${mod_id}?api_key=${MODIO_API_KEY}")

  if [ -z "$mod_info" ]; then
    LogError "Failed to get mod info for mod ID ${mod_id}"
    return 1
  fi

  local mod_name
  mod_name=$(echo "$mod_info" | jq -r ".name")

  if [ -n "$version" ]; then
    # Get all files for the mod
    local mod_files
    mod_files=$(curl -s \
      "${MODIO_CORE_KEEPER_ENDPOINT}/${mod_id}/files?api_key=${MODIO_API_KEY}")

    if [ -z "$mod_files" ]; then
      LogError "Failed to get mod files for ${mod_name} (${mod_id})"
      return 1
    fi

    # Find the specified version
    download_url=$(echo "$mod_files" | jq -r ".data[] | select(.version == \"${version}\") | .download.binary_url")
    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
      LogError "Version ${version} not isDirNameInManifest for mod ${mod_name} (${mod_id})"
      return 1
    fi
    actual_version="$version"
  else
    # Use latest version
    download_url=$(echo "$mod_info" | jq -r ".modfile.download.binary_url")
    actual_version=$(echo "$mod_info" | jq -r ".modfile.version")
  fi

  if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
    LogError "Failed to get download URL for mod ${mod_name} (${mod_id})"
    return 1
  fi

  # Create temp directory for download
  local temp_dir
  temp_dir=$(mktemp -d)
  local temp_mod_download="${temp_dir}/${mod_id}.zip"

  local mod_dir="${MODSDIR}/${mod_id}"

  # Download and extract mod
  if curl -s -L "${download_url}?api_key=${MODIO_API_KEY}" -o "${temp_mod_download}"; then
    # Remove existing mod directory if it exists
    rm -rf "${mod_dir}"

    # Create mod directory and extract
    mkdir -p "${mod_dir}"
    unzip -q "${temp_mod_download}" -d "${mod_dir}"

    # Update manifest
    echo "${mod_id}:${actual_version}" >> "${MODS_MANIFEST}.tmp"
    LogInfo "Installed ${mod_name} (${mod_id}) ${actual_version}"
  else
    LogError "Failed to install ${mod_name} (${mod_id}) ${actual_version}"
    return 1
  fi

  # Cleanup
  rm -rf "${temp_dir}"
}

cleanup_mods() {
  local installed_mods=()
  if [ -f "${MODS_MANIFEST}" ]; then
    while IFS=: read -r mod_id _; do
      installed_mods+=("$mod_id")
    done < "${MODS_MANIFEST}"
  fi

  # Get list of current mod directories
  for mod_dir in "${MODSDIR}"/*; do
    if [ -d "$mod_dir" ]; then
      local dir_name
      dir_name=$(basename "$mod_dir")

      # Skip if not a mod directory
      if [[ "$dir_name" == "." || "$dir_name" == ".." || "$dir_name" == ".manifest" ]]; then
        continue
      fi

      # Check if mod is in current manifest
      local isInManifest=false
      for mod in "${installed_mods[@]}"; do
        if [ "$dir_name" == "$mod" ]; then
          isInManifest=true
          break
        fi
      done

      # Remove if not in manifest
      if [ "$isInManifest" == false ]; then
        LogWarn "Removing unused mod: ${dir_name}"
        rm -rf "$mod_dir"
      fi
    fi
  done
}

install_mods() {
  # Read each line, ignore comments and empty lines
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Extract mod spec (remove comments and trim)
    local mod_spec
    mod_spec=$(echo "$line" | sed 's/#.*$//' | tr -d '[:space:]')
    [ -z "$mod_spec" ] && continue

    local mod_id
    local version
    # Split into id and version
    if [[ "$mod_spec" =~ ":" ]]; then
      mod_id="${mod_spec%%:*}" # Everything before the colon
      version="${mod_spec#*:}" # Everything after the colon
    else
      mod_id="$mod_spec"
      version=""
    fi

    download_and_install_mod "$mod_id" "$version"
  done <<< "$MODS"
}

manage_mods() {
  if [[ "${MODS_ENABLED,,}" != "true" ]]; then
    return 0
  fi

  if [ -z "${MODS}" ]; then
    LogWarn "MODS_ENABLED is true but there are no mods specified"
    return 0
  fi

  LogInfo "Installing mods..."

  # Create temporary manifest
  rm -f "${MODS_MANIFEST}.tmp"
  touch "${MODS_MANIFEST}.tmp"

  install_mods

  # Replace old manifest with new one
  mv "${MODS_MANIFEST}.tmp" "${MODS_MANIFEST}"

  # Cleanup unused mods
  cleanup_mods
}
