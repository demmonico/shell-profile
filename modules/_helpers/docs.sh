#!/usr/bin/env bash
#
# Docs creation helper
#
#-------------------------------------------------------------------#

function ps-help-cmd() { # Iterate over folders and print ONLY entities, that named as PUBLICLY accessible
  function _scan_dir() {
    local dir="$1"
    local maxdepth="${2:+"-maxdepth ${2}"}"

    for file in $( find "${dir}" -type f -name '*.sh' -mindepth 1 $( echo "${maxdepth}" ) ); do
      if [ $is_verbose_mode ]; then echo ""; echo "${file} >>>"; fi
      OUT="$(
        awk '/^function [^_][a-zA-Z0-9_]*.*[#].*$/ {$1=""; print $0}' "${file}" | sed 's/(.*# / : /'
        awk '/^function [^_][a-zA-Z0-9_]*[^#]*$/ {print " " $2}' "${file}" | sed 's/(.*$//'
        awk '/^alias [^_][a-zA-Z0-9_]*=/ {$1=""; print $0}' "${file}" | awk -F '"' '{$2=""; print $0}' | sed 's/=//' | sed 's/\ *# / : /'
      )"
      echo "${OUT}" | grep -v "^[[:space:]]*$" | sort
      if [ $is_verbose_mode ]; then echo "<<<"; fi
    done
  }

  # root folder
  local is_verbose_mode="$( [[ "$1" == "-v" ]] && echo "true" || echo "" )"
  local dir="${2%/}"
  local paths=()
  if [ -n "${dir}" ]; then
    paths=( "${dir}" )
  else
    paths=( "${_PS_ROOT_DIR}" "${_PS_CUSTOM_DIR}" )
  fi

  for dir in "${paths[@]}"; do
      echo ""
      echo "=================="
      echo "Cmd in '${dir}'..."
      echo ""
      _scan_dir "${dir}" 1

      # modules folders
      for d in $( find "${dir}" -type d -not -path '*/\.*' -mindepth 2 ); do
        echo ""
        echo "Module '${d#"$dir/"}' ------------------"
        _scan_dir "${d}"
      done
  done
}
