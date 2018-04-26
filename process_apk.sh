#!/bin/bash

type="$1"
filename="$2"
short_filename="$3"
models_save_dir="$4"
emulator_id="$5"

function remove_apk {
  rm -rf "/home/nastya/test_scripts/apktool-out"
  apktool d -o /home/nastya/test_scripts/apktool-out -f $filename
  if [ ! -e "/home/nastya/test_scripts/apktool-out/AndroidManifest.xml" ]; then
    echo 'Failed to decompile app'
    return
  fi
  pkg_name=`cat ~/test_scripts/apktool-out/AndroidManifest.xml | grep 'package=' | sed 's/.*package="//g' | sed 's/".*//g'`
  adb -s "$emulator_id" uninstall $pkg_name
  return
}

count_events=100

if [[ "$avd" == "API24"* ]]; then # a bit hacky way to check Android API version
  policy="dfs_greedy" # dfs for old version of droidbot, dfs_greedy for new
else
  policy="dfs" # dfs for old version of droidbot, dfs_greedy for new
fi

policy="dfs_greedy" # dfs for old version of droidbot, dfs_greedy for new
method_profiling="full"
time_limit="20m"

timeout_install="15s"
#if [ "$type" == "droidbox" ]; then
#  timeout_install="60s"
#fi

res=$(timeout $timeout_install adb -s "$emulator_id" install $filename 2>&1)
if [[ "$res" != *"Success"* ]]; then
  echo 'App can not be installed '$res
  echo "$res" > "$models_save_dir$short_filename.error"
  exit
else
  remove_apk
fi

mkdir "$models_save_dir$short_filename"
if [ "$type" == "droidbox" ]; then #TODO check everything
  timeout -k 2s $time_limit droidbot -d "$emulator_id" -a $filename -o "$models_save_dir$short_filename" -policy $policy -count $count_events -use_with_droidbox &> "$models_save_dir$short_filename/log.txt"
  #timeout -k 2s $time_limit droidbot -d "$emulator_id" -a $filename -o "$models_save_dir$short_filename" -policy dfs -count $count_events -use_with_droidbox &> "$models_save_dir$short_filename/log.txt"
  echo $filename > "$models_save_dir$short_filename/filename.txt"
  python ~/droidbot/droidbot/short_dynamic_api_model.py "$models_save_dir$short_filename" > "$models_save_dir$short_filename/d_model.json"
else
  timeout -k 2s $time_limit droidbot -d "$emulator_id" -a $filename -o "$models_save_dir$short_filename" -policy $policy -count $count_events -use_method_profiling $method_profiling &> "$models_save_dir$short_filename/log.txt"
  echo $filename > "$models_save_dir$short_filename/filename.txt"
  python ~/droidbot/droidbot/dynamic_api_model.py "$models_save_dir$short_filename" $filename > "$models_save_dir$short_filename/d_model.json"
fi

#leave only d_model.json and dumpsys_* and log.txt
ls "$models_save_dir$short_filename" | grep -v 'd_model*\|filename.txt\|log.txt\|dumpsys*' | xargs -I{} rm -rf "$models_save_dir$short_filename"/{}
remove_apk
