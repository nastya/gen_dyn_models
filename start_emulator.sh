#!/bin/bash

# start_emulator.sh type_of_logging xpra_session_number avd_name
# type_of_logging (type) -- droidbox or usual
type="$1" 

avd="API24_x86" #now only for droidbox version
xpra_num="100"
emulator_id="emulator-5554"
port="5554"
arch="x86"

if [ $# -gt 1 ]; then
  xpra_num="$2"
fi

if [ $# -gt 2 ]; then
  avd="$3"
fi

if [ $# -gt 3 ]; then
  arch="$4"
fi

port=$((5554 + ($xpra_num - 100) * 2))
emulator_id="emulator-"$port

echo 'avd='$avd
echo 'xpra_num='$xpra_num

function install_test_app {
  res=$(timeout 40s adb -s "$emulator_id" install ~/droidbot/test_apps/zok.android.letters.apk 2>&1)
  echo "$res"
  if [[ "$res" == *"Success"* ]]; then
    app_installed_flag=1
    echo 'Test app installed'
  else
    app_installed_flag=0
    echo 'Test app not installed'
  fi
  adb -s "$emulator_id" uninstall zok.android.letters
}

#Get list of running emulator identifiers
#devices=$(adb devices | grep 'emulator-' | sed 's/.device*//g')

#echo $devices

number_of_tries_emulator=0
function start_emulator {
  number_of_tries_emulator=$(( number_of_tries_emulator+1 ))
  if [ $number_of_tries_emulator -ge 6 ]; then
    echo 'Terminating... emulator not started'
    exit
  fi
  emulator_cmd="/home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/qemu/linux-x86_64/qemu-system-i386"
  if [ "$arch" == "arm" ]; then
    emulator_cmd="/home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/emulator64-arm"
  fi
  if [ "$type" == "droidbox" ]; then #decided to leave this condition, it might be useful in case I understand how to make -system and -ramdisk parameters work and not to subsitute the original images
    echo "Starting Android emulator with droidbox"
    command='"LD_LIBRARY_PATH=/home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64/qt/lib/:/home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64:~/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64/gles_swiftshader '$emulator_cmd' -avd '$avd' -port '$port' -wipe-data"'
  else
    echo "Starting Android emulator with original images"
    command='"LD_LIBRARY_PATH=/home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64/qt/lib/:/home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64:~/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64/gles_swiftshader '$emulator_cmd' -avd '$avd' -port '$port' -wipe-data"'
  fi
  bash_command="'bash -c "$command"'"
  xpra start ':'$xpra_num --start-child='bash -c '"$command" #droidbox compatible android4.1 arm
  sleep 10s
  if [ `ps aux | grep 'emulator' | grep "$avd " | wc -l` -le 2 ]; then
    echo 'Emulator not started'
    xpra stop ':'$xpra_num
    start_emulator
    return
  fi
  sleep 3m
#     while read line
#     do
#         if [[ ! "$devices" == *"$line"* ]]; then
#             emulator_id="$line"
#         fi
#     done <<< "$(adb devices | grep 'emulator-' | sed 's/.device*//g')"
  install_test_app
  if [ $app_installed_flag -eq 0 ]; then
    echo 'Emulator started incorrectly'
    xpra stop ':'$xpra_num
    start_emulator
    return
  fi
  number_of_tries_emulator=0
  
  if [[ "$avd" == "API24"* ]]; then # a bit hacky way to check Android API version
    adb shell "su 0 toybox date $(date +%m%d%H%M%Y.%S)" #command for new Android
  else
    adb -s $emulator_id shell "su 0 toolbox date -s $(date +%Y%m%d.%H%M%S)" #command for old Android
  fi
#   else    #Part for genymotion usage
#     # This part is not adapted to parallel execution
#     echo "Starting Android emulator without droidbox logs"
#     xpra start :100 --start-child='bash -c "/home/nastya/genymotion/player --vm-name \"Google Nexus 6P - 7.1.0 - API 25 - 1440x2560\""'
#     #xpra start :100 --start-child='bash -c "LD_LIBRARY_PATH=/home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64/qt/lib/:/home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64:~/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/lib64/gles_swiftshader /home/nastya/android-sdk/adt-bundle-linux-x86_64-20130729/sdk/emulator/qemu/linux-x86_64/qemu-system-i386 -avd API24_x86"' #android7.1
#     sleep 10s
#     if [ `ps aux | grep '/home/nastya/genymotion/player' | wc -l` -le 2 ]; then
#       echo 'Emulator not started'
#       xpra stop
#       sleep 5s
#       killall VBoxHeadless
#       sleep 5s
#       start_emulator
#       return
#     fi
#     sleep 3m
#     #TODO sometimes the emulator hangs on loading, need to figure it out too (think it's figured out by install_test_app)
#     install_test_app
#     if [ $app_installed_flag -eq 0 ]; then
#       echo 'Emulator started incorrectly'
#       xpra stop
#       sleep 5s
#       killall VBoxHeadless
#       sleep 5s
#       start_emulator
#       return
#     fi
#     number_of_tries_emulator=0
#     adb shell "su 0 toybox date $(date +%m%d%H%M%Y.%S)"
#  fi
  echo 'Emulator started, emulator_id:'$emulator_id
}

start_emulator
