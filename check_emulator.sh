#!/bin/bash

type="$1"

if [ "$type" == "droidbox" ]; then
  if [ `ps aux | grep 'emulator64-arm' | wc -l` -le 2 ]; then
    echo 'Emulator not running'
  else
    echo 'Emulator running'
  fi
else
  if [ `ps aux | grep '/home/nastya/genymotion/player' | wc -l` -le 2 ]; then
    echo 'Emulator not running'
  else
    echo 'Emulator running'
  fi
fi
