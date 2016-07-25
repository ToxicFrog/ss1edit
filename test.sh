#!/bin/bash

COLOURIZE='
  BEGIN             { flag=0; suite=""; new_suite="" }
  (flag)            { print $0; next }
  /^Started on/     { print $0 }
  /^    ([^\.]+)\./ { FS="\\."; $0=$0; new_suite=$1; FS=" " }
  (new_suite != suite) { print new_suite; suite=new_suite }
  /Ok$/             { print "\033[7;38;2;0;255;0m✔\033[0m " $2 }
  /FAIL$/           { print "\033[7;38;2;255;0;0m✘\033[0m " $2 }
  /ERROR$/          { print "\033[7;38;2;255;255;255m❗\033[0m " $2 }
  /^===========/    { print $0; flag=1 }
'

if [[ $LUA ]]; then
  $LUA test/all.lua -v -o text | awk "$COLOURIZE"
else
  set -o pipefail
  for LUA in lua5.1 lua5.2 lua5.3 luajit; do
    echo "==== testing $LUA ===="
    $LUA test/all.lua -v -o text | awk "$COLOURIZE" || break
  done
fi
