#!/usr/bin/env bash

### git commit + index

alias gstat="git status"
alias gadd="git add ."
alias gpull="git pull"

function gcom() { git commit -m "$1"; }

function gpush() {
  local local_branch="$(git rev-parse --abbrev-ref HEAD)"
  local origin_branch="${1:-"${local_branch}"}"
  git push "${@:2}" origin "${origin_branch}"
}

### git remote

alias grem="git remote -v"

function grem-add() { git remote add origin "$1"; }
