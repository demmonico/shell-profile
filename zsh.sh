#!/usr/bin/env bash
#
# This is main profile script entrypoint in ZSH
#
#-------------------------------------------------------------------#

### common

_PS_ROOT_DIR="$( dirname $(readlink -f $0) )"
. "${_PS_ROOT_DIR}/_common.sh"
_ps_log_msg "Common parts have been connected - '${_PS_ROOT_DIR}/_common.sh'"



### autoload ZSH modules

for module in $( find "${_PS_ROOT_DIR}/modules-zsh" -type d -mindepth 1 -maxdepth 1 ); do
  local INDEX_SCRIPT="${module}/index.sh"
  if [ -f "${INDEX_SCRIPT}" ]; then
    . "${INDEX_SCRIPT}"
    _ps_log_msg "ZSH Module has been connected - INDEX_SCRIPT='${INDEX_SCRIPT}'"
  fi
done
