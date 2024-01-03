#!/usr/bin/env bash

# common K8s
alias k="kubectl"
alias ke="k exec -ti"

# watch nodes
function kwn-req() {
  local NS=${1:+"-n $1"}
  local APP=${2:-"services"}
  local _DIR="$( dirname $(readlink -f $0) )"

  watch -n 30 "${_DIR}/k8s-watch-nodes-requests.sh ${APP} ${NS}"
}

# watch pods
function kwp() {
  local NS=${1:+"-n $1"}

  watch "kubectl get pods --sort-by=.metadata.creationTimestamp ${NS} | grep -v 'Completed' | tail"
}
function kwp-error() {
  local NS=${1:+"-n $1"}

  watch "kubectl get pods --sort-by=.metadata.creationTimestamp ${NS} | grep 'Error' | tail"
}
