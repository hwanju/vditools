# This is an example of configuration file
# this configuration is written as a python script, so after you edit, you should rename this file to config.py
# The form of <field> is only configurable, so you should replace it with your configuration based on each comment

import os
import sys

guests_saved_state_map = {
	'parsec1': '/mnt/sdb/vm_saved/parsec1.saved',
	'parsec2': '/mnt/sdb/vm_saved/parsec2.saved',
	'parsec3': '/mnt/sdb/vm_saved/parsec3.saved',
	'parsec4': '/mnt/sdb/vm_saved/parsec4.saved',
	'interactive': '/mnt/sdb/vm_saved/interactive.saved',
}

guests_image_map = {
	'parsec1': '/mnt/sdb/vm_images/parsec1.qcow2',
	'parsec2': '/mnt/sdb/vm_images/parsec2.qcow2',
	'parsec3': '/mnt/sdb/vm_images/parsec3.qcow2',
	'parsec4': '/mnt/sdb/vm_images/parsec4.qcow2',
	'interactive': '/mnt/sdb/vm_images/interactive.qcow2',
}

host_ip = '115.145.212.176'

trace_replay = 1

client_machine_ip = '115.145.212.176'

client_machine_bitness = '64'

ip_map = {
	'parsec1': '115.145.212.177',
	'parsec2': '115.145.212.178',
	'parsec3': '115.145.212.179',
	'parsec4': '115.145.212.180',
}

guest_bitness = {
	'parsec1': '64',
	'parsec2': '64',
	'parsec3': '64',
	'parsec4': '64',
}

active_guests = ['parsec1', 'parsec2', 'parsec3', 'parsec4']   # active guest's names who participate in the benchmark

trace_guests = ['interactive']

dist = [os.path.normpath(sys.modules[__name__].__file__ + '/../dist')]
