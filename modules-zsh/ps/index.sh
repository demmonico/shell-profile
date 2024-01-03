#!/usr/bin/env bash
#
# PROMPT hacking
#
#-------------------------------------------------------------------#

function function_exists() {
  declare -f -F $1 > /dev/null
  return $?
}

# k8s prefix
source "/opt/homebrew/opt/kube-ps1/share/kube-ps1.sh"
function ps_kube_prefix() { if [ "$FLAG_KUBE_PS" -eq "1" ] && function_exists kube_ps1; then echo "$(kube_ps1) "; fi }
function ps_enable_kube_prefix() { FLAG_KUBE_PS=1; }
function ps_disable_kube_prefix() { FLAG_KUBE_PS=0; }
function ps_switch_kube_prefix() { if [ ${FLAG_KUBE_PS} -eq 0 ]; then ps_enable_kube_prefix; else ps_disable_kube_prefix; fi }
ps_disable_kube_prefix

alias ps-ek=ps_enable_kube_prefix
alias ps-dk=ps_disable_kube_prefix
if _ps_h_is_shell_zsh; then bindkey -s '^k' 'ps_switch_kube_prefix^M'; fi

# user prefix, come from ohmyzsh
function ps_enable_user_prefix() { DEFAULT_USER=""; }
function ps_disable_user_prefix() { DEFAULT_USER="$USER"; }
function ps_switch_user_prefix() { if [[ "${DEFAULT_USER}" == "${USER}" ]]; then ps_enable_user_prefix; else ps_disable_user_prefix; fi }
ps_disable_user_prefix

alias ps-eu=ps_enable_user_prefix
alias ps-du=ps_disable_user_prefix
if _ps_h_is_shell_zsh; then bindkey -s '^u' 'ps_switch_user_prefix^M'; fi

PS1='$(ps_kube_prefix)'$PS1
