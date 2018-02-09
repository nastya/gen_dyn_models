#!/usr/bin/python
import sys
from subprocess import call, check_output
import os.path
import time
import subprocess

# That's a good idea to analyse applications that failed in another version of emulator TODO
# WARNING the script is still buggy, it exited after 107 applications for uncertain reason
# need to process sudden emulator failures
# the easiest way to fix would be to wrap into a script that monitors new models in models_save_dir and restarts script in case necessary

analysis_type = "droidbox"
models_save_dir = sys.argv[2]
xpra_session = "100"
mode = "usual"
avd = ""

if (len(sys.argv) > 3):
  xpra_session = sys.argv[3]
if (len(sys.argv) > 4):
  mode = sys.argv[4]
if (len(sys.argv) > 5):
  avd = sys.argv[5]

out = check_output(["./start_emulator.sh", analysis_type, xpra_session, avd])
if ('Terminating' in out):
	print out
	print 'Emulator not started'
	sys.exit(-1)
emulator_id = out[out.find('emulator_id:') + len('emulator_id:'):-1]
print 'emulator_id:', emulator_id

print 'Emulator started'
call("./remove_odd_packages.py " + analysis_type + ' ' + emulator_id, shell=True)
#check emulator process is running

# Maybe it runs the same apps several times never getting to the end?
apk_list = sys.argv[1] #file with a list of apps to generate models
count = 0

postponed = []

def process_file(filename, postpone_flag = True):
	global count
	global postponed
	global analysis_type
	global models_save_dir
	short_filename = filename.split("/")[-1]
	print filename, short_filename
	if os.path.isdir(models_save_dir + short_filename):
		print 'Skipping...'
		return
	if os.path.isfile(models_save_dir + short_filename + '.error') and postpone_flag:
		print 'Postponing...'
		postponed.append(filename)
		return
	count += 1
	if (count % 100 == 0) or (count != 1 and analysis_type == 'droidbox'):
							#last condition is for restarting emulator after each app in droidbox mode
		print 'Restarting emulator'
		try:
			call(["./stop_emulator.sh", mode, xpra_session])
		except CalledProcessError:
			pass
		out = check_output(["./start_emulator.sh", analysis_type, xpra_session, avd])
		if ('Terminating' in out):
			print out
			print 'Emulator not started'
			sys.exit(-1)
		call("./remove_odd_packages.py " + analysis_type + ' ' + emulator_id, shell=True)

	#check emulator is alive
	out = check_output(['./check_emulator.sh', analysis_type])
	if ('Emulator not running' in out):
		print 'Restarting emulator'
		try:
			call(["./stop_emulator.sh", mode, xpra_session])
		except CalledProcessError:
			pass
		out = check_output(["./start_emulator.sh", analysis_type, xpra_session, avd])
		if ('Terminating' in out):
			print out
			print 'Emulator not started'
			sys.exit(-1)
		call("./remove_odd_packages.py " + analysis_type + ' ' + emulator_id, shell=True)


	call(["./process_apk.sh", analysis_type, filename, short_filename, models_save_dir, emulator_id]) #hangs on this call
	out = check_output("ps aux | grep 'droidbot' | grep '" + models_save_dir + short_filename + "'", shell=True)
	for line in out[:-1].split('\n'):
		pid = line.split()[1]
		call("kill " + pid, shell = True)
		call("pkill -STOP -P " + pid, shell = True)

for line in open(apk_list).readlines():
	filename = line[:-1]
	process_file(filename)

for filename in postponed:
	process_file(filename, False)

try:
	call(["./stop_emulator.sh", mode, xpra_session])
except CalledProcessError:
	pass
