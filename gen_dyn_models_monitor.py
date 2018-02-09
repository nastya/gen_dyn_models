#!/usr/bin/python
import threading
import sys
import subprocess
import os
import datetime

#WARNING adb version for genymotion doesn't match adb version for original emulator. Fix in bashrc before running.
#first argument is a file with a list of programs to generate models and the second argument is a directory for saving models
#third argument is the indication of the mode (parallel or usual)
#fourth argument is avd_name (only for parallel mode now)
mode = "usual"
avd = ""
if (len(sys.argv) > 3):
  mode = sys.argv[3]
if (len(sys.argv) > 4):
  avd = sys.argv[4]
  
time_slot = 30*60 # 30 minutes
models_save_dir = sys.argv[2] + '/'

if not os.path.exists(models_save_dir):
    os.makedirs(models_save_dir)

xpra_session = 100
max_xpra_num = 0
if mode == 'parallel':
	try:
		out = subprocess.check_output("xpra list", shell=True) #TODO need to substitute all this stuff with regular expressions
		for line in out[:-1].split('\n')[1:]:
			ind_st = line.find(':')
			ind = ind_st + 1
			while ind < len(line) and line[ind] >= '0' and line[ind] <= '9':
				ind += 1
			xpra_num = line[ind_st + 1:ind]
			max_xpra_num = max(max_xpra_num, int(xpra_num))
	except subprocess.CalledProcessError:
		pass

if max_xpra_num != 0:
	xpra_session = max_xpra_num + 1

try:
	subprocess.check_output(["./stop_emulator.sh", mode, str(xpra_session)]) #cleaning up everything before launch
except subprocess.CalledProcessError:
	pass

p = subprocess.Popen('./gen_dyn_models.py ' + sys.argv[1] + ' ' + models_save_dir + ' ' + str(xpra_session) + ' ' + mode + ' ' + avd, shell=True)

def check_generating_models():
  global p
  global models_save_dir
  threading.Timer(time_slot, check_generating_models).start()
  print "Checking models are generated"

  flag_new = False
  last_modified_limit = datetime.datetime.now()
  delta = datetime.timedelta(seconds=time_slot*3)
  last_modified_limit = last_modified_limit - delta
  last_modified = last_modified_limit
  for d in os.listdir(models_save_dir):
    if not os.path.isdir(models_save_dir + d):
      continue
    stat = os.stat(models_save_dir + d)
    model_time = datetime.datetime.fromtimestamp(int(stat.st_mtime))
    if model_time > last_modified:
      last_modified = model_time

    now = datetime.datetime.now()
    delta = datetime.timedelta(seconds=time_slot)

    if not (model_time < now - delta):
      flag_new = True
      break
  print 'last_modified', last_modified
  print 'last_modified_limit', last_modified_limit
  if last_modified <= last_modified_limit:
    print 'No more models are generated. Either finished processing or having serious problems with emulator.'
    out = subprocess.check_output("ps aux | grep 'gen_dyn_models' | grep '" + sys.argv[1] + "' | grep '" + models_save_dir + "'", shell=True)
    for line in out[:-1].split('\n'):
      pid = line.split()[1]
      subprocess.call("kill " + pid, shell = True)
    p.kill()
    subprocess.call("ls " + models_save_dir + " | xargs -I{} rm " + models_save_dir + "{}.error", shell=True)
    os._exit(0)
  #in case not
  if not flag_new:
    out = subprocess.check_output("ps aux | grep 'gen_dyn_models' | grep '" + sys.argv[1] + "' | grep '" + models_save_dir + "'", shell=True)
    for line in out[:-1].split('\n'):
      pid = line.split()[1]
      subprocess.call("kill " + pid, shell = True)
    p.kill()
    try:
      subprocess.check_output(["./stop_emulator.sh", mode, str(xpra_session)]) #cleaning up everything before launch
    except subprocess.CalledProcessError:
      pass
    p = subprocess.Popen('./gen_dyn_models.py ' + sys.argv[1] + ' ' + models_save_dir + ' ' + str(xpra_session) + ' ' + mode + ' ' + avd, shell=True)


threading.Timer(time_slot, check_generating_models).start()
