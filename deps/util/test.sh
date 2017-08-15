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

function summarize {
  while read _ _ lua _; do
    read result
    printf '%8s: %s\n' "$lua" "$result"
  done
}

if [[ $LUA ]]; then
  $LUA test/all.lua -v -o text | awk "$COLOURIZE"
else
  > /tmp/$$.luaunit
  for LUA in lua5.1 lua5.2 lua5.3 luajit; do
    echo ''
    echo "==== testing $LUA ====" | tee -a /tmp/$$.luaunit
    if type "$LUA" >/dev/null; then
      $LUA test/all.lua -v -o text | tee -a /tmp/$$.luaunit | awk "$COLOURIZE"
    else
      echo "MISSING" >> /tmp/$$.luaunit
    fi
  done
  echo ''
  echo '==== summary ===='
  egrep '^(==== testing|Ran [0-9]+ tests|MISSING)' /tmp/$$.luaunit | summarize
fi
