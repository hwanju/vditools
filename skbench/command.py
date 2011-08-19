import os
import shutil
import time

from control import Control
from config import *


def copy(from_guest, to_guests):
	ctl = Control()

	assert from_guest in ctl.list()
	for to_guest in to_guests:
		assert to_guest not in ctl.list()

	for to_guest in to_guests:
		# duplicate image files
		ret = os.system('cp -a --sparse=always %s %s' % (
			os.path.join(domains_root, from_guest),
			os.path.join(domains_root, to_guest)))
		assert ret == 0
        
		# modify the hostname
		target = ctl.mount(to_guest)
		file(target + '/etc/hostname', 'w').write(to_guest + '\n')
		ctl.umount(to_guest)

def update(test):
	ctl = Control()
	for n in range(1, len(active_guests) + 1):
		guest = active_guests[n - 1]
 		assert guest in ip_map
		assert n in test.job
		assert n in test.disabled_services

		target = ctl.mount(guest)

		# copy distribution files
		for path in dist:
			try:
				os.remove(target + path)
			except OSError:
				pass
 			try:
				shutil.rmtree(target + path, True)
			except OSError:
				pass

			try:
				os.makedirs(os.path.dirname(target + path.rstrip('/')))
			except OSError:
				pass

			if os.path.isfile(path):
				shutil.copy2(path, target + path)
			else:
				shutil.copytree(path, target + path)

		if guest in active_linux_guests:
#			# set up the network address
#			interfaces_path = target + '/etc/network/interfaces'
#			f = file(interfaces_path, 'w')
#			f.write('auto lo\niface lo inet loopback\n')
#			f.write('auto eth0\niface eth0 inet static\n')
#			f.write('address %s\n' % ip_map[guest])
#			f.write('gateway %s\n' % gateway)
#			f.write('netmask %s\n' % netmask)
#			f.close()

			# TODO: /etc/hosts

			# update the rc.local file
			f = file(target + '/etc/rc.local', 'w')
			f.write('#!/bin/bash -e\n')
			f.write(augmented_job(test, n) + '\n')
			f.write('exit 0\n')
			f.close()

			# enable/disable services
#			disable = set(test.disabled_services[n])
#			for sub in ('S', '0', '1', '2', '3', '4', '5', '6'):
#				dirname = target + '/etc/rc%s.d' % sub
#				for filename in os.listdir(dirname):
#					new_filename = filename[:3]
#					if filename[3:] in disable:
#						new_filename = new_filename.lower()
#					else:
#						new_filename = new_filename.upper()
#					new_filename += filename[3:]
#					if filename == new_filename:
#						continue
#					os.rename(os.path.join(dirname, filename),
#						os.path.join(dirname, new_filename))

		if guest in active_windows_guests:
			f = file(target + '/Users/win7/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/startup.bat', 'w')
			f.write(augmented_windows_job(test, n))
			f.close()

		ctl.umount(guest)

def clean(test):
	stop()

	ctl = Control()
	for n in range(1, len(active_guests) + 1):
		guest = active_guests[n - 1]
		assert guest in ip_map
		assert n in test.disabled_services

		target = ctl.mount(guest)

		if guest in active_linux_guests:
			# clean the rc.local file
			f = file(target + '/etc/rc.local', 'w')
			f.write('#!/bin/sh -e\n')
			f.write('exit 0\n')
			f.close()

			# enable services
#			disable = set(test.disabled_services[n])
#			for sub in ('S', '0', '1', '2', '3', '4', '5', '6'):
#				dirname = target + '/etc/rc%s.d' % sub
#				for filename in os.listdir(dirname):
#					new_filename = filename[:3].upper() + filename[3:]
#					if filename == new_filename:
#						continue
#				os.rename(os.path.join(dirname, filename),
#					os.path.join(dirname, new_filename))

		if guest in active_windows_guests:
			ret = os.system('rm %s/Users/win7/AppData/Roaming/Microsoft/Windows/Start\ Menu/Programs/Startup/startup.bat' % target)
			assert ret

		ctl.umount(guest)

def augmented_windows_job(test, n):
	s = ''
#	port = 20000 + n

#	for path in dist:
#		if os.path.isdir(path):
#			s += 'path=%s;\%path\%\n' % path
	
#	s += 'set TO_HOST=%s\n' % host_ip
#	s += 'set BOOT_PORT=10000\n'
#	s += 'set WAIT_PORT=10001\n'
#	s += 'set RESULT_PORT=%d\n' % port
#	s += 'set END_PORT=10002\n'
#	
	s += test.job[n]

	return s

def augmented_job(test, n):
	s = ''
	for path in dist:
		if os.path.isdir(path):
			s += 'export PATH="%s:$PATH"\n' % path

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

	return s

def start(test):
	update(test)

	ctl = Control()

	for guest in active_guests:
		ctl.create(guest)

	f = file('/tmp/host_job', 'w')
	f.write('#!/bin/bash -e\n')
	f.write(augmented_job(test, 0))
	f.write('exit 0\n')
	f.close()

	os.chmod('/tmp/host_job', 0755)
	os.system('/tmp/host_job')

def start_stop(test):
	start(test)
	stop()

def stop():
	ctl = Control()
	ctl.shutdown_all()

def restore_replay(replay_file, active_guest_num):
	ctl = Control()
	exec( open( replay_file ).read() )

#prolog job
	job = ""
	for path in dist:
		if os.path.isdir(path):
			job += 'export PATH="%s:$PATH"\n' % path

	job += "# prolog\n"
	f = open( 'scripts/' + prolog_script )
	lines = f.readlines()
	job += '\t'.join(lines);
	f.close()

	guest_id = 0
	for guest in active_guests:
		trace = 'traces/' + trace_files[guest_id]
		job += "spicec -h localhost -p %d -P %s > /dev/null &\n" % (port_map[guest], trace)
		guest_id = guest_id + 1

	job += "wait_signal_64 %d 10000\n" % active_guest_num

#epilog job
	job += "# epilog\n"
	f = open( 'scripts/' + epilog_script )
	lines = f.readlines()
	job += '\t'.join(lines);
	f.close()

	f = file( '/tmp/host_job', 'w' )
	f.write('#!/bin/bash -e\n')
	f.write(job)
	f.write('exit 0\n')
	f.close()

	os.chmod('/tmp/host_job', 0755)

	for guest in active_guests:
		img_path = guests_image_map[guest]
		backup_path = img_path + '.bak'
		ret = os.system('mv %s %s' % (img_path, backup_path))
		assert ret == 0
		ret = os.system('qemu-img create -f qcow2 -b %s %s' % (backup_path, img_path))
		assert ret == 0

	for guest in active_guests:
		ctl.restore( guest )

	os.system('/tmp/host_job')

	ctl.destroy_all()
	
	for guest in active_guests:
		img_path = guests_image_map[guest]
		backup_path = img_path + '.bak'
		ret = os.system('rm %s' % img_path)
		assert ret == 0
		ret = os.system('mv %s %s' % (backup_path, img_path))
		assert ret == 0

	
	
