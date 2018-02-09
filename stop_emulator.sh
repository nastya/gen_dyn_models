#!/bin/bash

mode="usual"
if [ $# -gt 0 ]; then
  mode="$1"
fi
xpra_num="100"
if [ $# -gt 1 ]; then
  xpra_num="$2"
fi


if [ "$mode" == "parallel" ]; then
  xpra stop ':'$xpra_num
  exit
else
  xpra stop
  sleep 5s
  killall VBoxHeadless
  killall droidbot
  killall adb
  sleep 2s
fi

