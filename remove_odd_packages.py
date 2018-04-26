#!/usr/bin/python
import subprocess
import sys

avd = ""

emulator_id = "emulator-5554"
if len(sys.argv) >= 2:
	avd = sys.argv[1]
if len(sys.argv) >= 3:
	emulator_id = sys.argv[2]

orig_packages_file = "packages_on_install_android7.txt"
if "API16" in avd:
	orig_packages_file = "packages_on_install_android4.txt"


p_orig_install = open(orig_packages_file, 'r').read()[:-1].split('\n')

out = subprocess.check_output(["adb", "-s", emulator_id, "shell", "pm", "list", "packages"])
for package_name in out[:-1].split('\n'):
	package_name = package_name[8:]
	if not package_name in p_orig_install:
		print package_name
		out = subprocess.check_output(["adb", "-s", emulator_id, "uninstall", package_name])
		print out


