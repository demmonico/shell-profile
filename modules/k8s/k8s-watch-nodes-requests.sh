#!/usr/bin/env bash

APP=${1:+"-l application=$1"}
NS=${2:+"-n $2"}

printf "Command: %s\n\n" "kubectl describe nodes ${NS} ${APP}"

kubectl describe nodes ${NS} ${APP} | \
  grep 'Name:\|  cpu \|  memory ' | \
  awk '{getline line2;getline line3;print $0, line2, line3}' | \
  sed -E 's/^.*(ip.*internal).*\(([0-9]*)%.*\([0-9]*%.*\(([0-9]*)%.*\([0-9]*%.*$/\1|\2|\3/g' | \
  awk -F "|" 'BEGIN{printf "%-50s%+10s%+10s\n","Name","CPU Req","RAM Req"}; {printf "%-50s%+10s%+10s\n",$1,$2,$3}' \
