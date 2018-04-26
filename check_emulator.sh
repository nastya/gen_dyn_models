#!/bin/bash


arch="$1"

if [ "$arch" == "arm" ]; then
  if [ `ps aux | grep 'emulator64-arm' | wc -l` -le 2 ]; then
    echo 'Emulator not running'
  else
    echo 'Emulator running'
  fi
else
  if [ `ps aux | grep 'qemu-system-i386' | wc -l` -le 2 ]; then #not the best way of checking
    echo 'Emulator not running'
  else
    echo 'Emulator running'
  fi
fi

#  if [ `ps aux | grep '/home/nastya/genymotion/player' | wc -l` -le 2 ]; then
#    echo 'Emulator not running'
#  else
#    echo 'Emulator running'
#  fi
