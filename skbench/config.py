# This is an example of configuration file
# this configuration is written as a python script, so after you edit, you should rename this file to config.py
# The form of <field> is only configurable, so you should replace it with your configuration based on each comment

import os
import sys
mount_point = '/mnt/domains'

guests_saved_state_map = {
	'win7_64': '/mnt/sdb/vm_saved/win7_64.saved',
}

guests_image_map = {
	'win7_64': '/mnt/sdb/vm_images2/win7_64.qcow2',
}

host_ip = '115.145.212.176'
# specify rootfs path for each guest domain by means of either rootfs_dev or rootfs_map. 
#rootfs_dev = 'xvda2'        # guest-side device name spcified in /etc/xen/<domain config file>. Sxbench inspects rootfs_map first.
port_map = {              # specify each path. It is useful when guest domains are heterogenous(PV, HVM, and Parallax are mixed)
	'win7_64': 5924,
}


active_guests = ['win7_64']   # active guest's names who participate in the benchmark

dist = [os.path.normpath(sys.modules[__name__].__file__ + '/../dist')]
