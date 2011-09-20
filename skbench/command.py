import os
import shutil
import time

from control import Control
from config import *

def update(test, n, guest):
	# copy distribution files
	ret = os.system('scp -r ./dist %s:~/dist' % ip_map[guest])
	assert ret == 0

	# generate workload
	f = file('/tmp/skbench_job', 'w')
	f.write(augmented_job(test, n) + '\n')
	f.close()
	os.chmod('/tmp/skbench_job', 0755)

	# copy a workload script to a corresponding guest's home dir
	ret = os.system('scp /tmp/skbench_job %s:~/job' % ip_map[guest])
	assert ret == 0

def update_client(test, n):
	# copy distribution files
	ret = os.system('scp -r ./dist %s:~/dist' % client_machine_ip)
	assert ret == 0

	# generate workload
	f = file('/tmp/skbench_job', 'w')
	f.write(augmented_job(test, n) + '\n')
	f.close()
	os.chmod('/tmp/skbench_job', 0755)

	# copy a workload scropt to a corresponding guest's home dir
	ret = os.system('scp /tmp/skbench_job %s:~/job' % client_machine_ip)
	assert ret == 0

def augmented_job(test, n):
	s = ''

	s += '#!/bin/bash \n'

	if n == 0:
		for path in dist:
			if os.path.isdir(path):
				s += 'export PATH="%s:$PATH"\n' % path
	else:	
		s += 'export PATH=~/dist:$PATH\n'

	s += 'export IP_HOST="%s"\n' % host_ip

	guest_ns = ''
	guest_names = ''
	guest_ips = ''

	for i in range(1, len(active_guests) + 1):
		guest = active_guests[i - 1]
		s += 'export NAME_GUEST%d="%s"\n' % (i, guest)
		s += 'export IP_GUEST%d="%s"\n' % (i, ip_map[guest])

		guest_ns += str(i) + ' '
		guest_names += guest + ' '
		guest_ips += ip_map[guest] + ' '

	s += 'export GUEST_NS="%s"\n' % guest_ns.strip()
	s += 'export GUEST_NAMES="%s"\n' % guest_names.strip()
	s += 'export GUEST_IPS="%s"\n' % guest_ips.strip()

	s += test.job[n]

	s += 'exit 0\n'

	return s

def start(test):
	ctl = Control()

	for n in range(1, len(active_guests) + 1): 
		assert n in test.job
		guest = active_guests[n - 1]
		ctl.restore(guest)
		update(test, n, guest)

	if trace_replay == 1:
		n = len(active_guests) + 1
		update_client(test, n)
	
	for guest in trace_guests:
		ctl.restore(guest)

	f = file('/tmp/host_job', 'w')
	f.write(augmented_job(test, 0))
	f.close()

	os.chmod('/tmp/host_job', 0755)
	os.system('/tmp/host_job')

def start_stop(test):
	start(test)
	stop()

def stop():
	ctl = Control()
	ctl.destroy_all()	
