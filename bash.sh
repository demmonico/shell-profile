#!/usr/bin/env bash
#
# This is main profile script entrypoint in Bash
#
#-------------------------------------------------------------------#

### common

_PS_ROOT_DIR="$( dirname $(readlink -f $0) )"
. "${_PS_ROOT_DIR}/_common.sh"
_ps_log_msg "Common parts have been connected - '${_PS_ROOT_DIR}/_common.sh'"
