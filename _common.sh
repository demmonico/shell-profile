#!/usr/bin/env bash
#
# This is common profile script
#
#-------------------------------------------------------------------#

# logs
function _ps_log_msg() {
  local file="${_PS_ROOT_DIR}/init.log"
  echo "$1" >> "${file}"
}
function _ps_log_show() {
  local file="${_PS_ROOT_DIR}/init.log"
  cat "${file}"
}
function _ps_log_init() {
  local file="${_PS_ROOT_DIR}/init.log"
  echo "Starting profile init log" > "${file}"
}
_ps_log_init



### autoload modules

for module in $( find "${_PS_ROOT_DIR}/modules" -type d -mindepth 1 -maxdepth 1 ); do
  INDEX_SCRIPT="${module}/index.sh"
  if [ -f "${INDEX_SCRIPT}" ]; then
    . "${INDEX_SCRIPT}"
    _ps_log_msg "Module has been connected - INDEX_SCRIPT='${INDEX_SCRIPT}'"
  fi
done



### aliases

alias ll="ls -al"

function watcha {
    echo watch -n 1 $(alias "$@" | cut -d\' -f2)
}

# read SSH identity and add to SSH key manager
# ssh-add -l | grep $(cat ~/.ssh/id_rsa.pub | cut -d' ' -f3) >/dev/null || ssh-add ~/.ssh/id_rsa

t() {
  if [ -f "terragrunt.hcl" ]; then
    command terragrund "$@"
  elif ls *.tm.hcl 1> /dev/null 2>&1; then
    command terramate "$@"
  else
    command terraform "$@"
  fi
}
