import os
import re
import time

from config import *

class Control:
	def __init__(self):
		if not os.path.exists(mount_point):
			os.makedirs(mount_point)

	def __del__(self):
		for guest in os.listdir(mount_point):
			self.umount(guest)

	def list(self):
		return os.listdir(guests_img_root)

	def mount_target(self, guest):
		return '%s/%s' % (mount_point, guest)

	def mount_ubuntu(self, target):
		ret = os.system('mount /dev/nbd0p1 %s' % target)
		return ret

	def mount_fedora(self, target):
		ret = os.system('vgscan')
		assert ret == 0
		ret = os.system('vgchange -ay');
		assert ret == 0
		ret = os.system('mount /dev/VolGroup/lv_root %s' % target)
		return ret

	def mount_windows(self, target):
		ret = os.system('mount /dev/nbd0p2 %s' % target)
		return ret

	def mount(self, guest):
		image_path = rootfs_map[guest]
		print 'rootfs path: %s' % image_path 
		target = self.mount_target(guest)

		os.mkdir(target)
		ret = os.system('modprobe nbd max_part=8')
		assert ret == 0
		ret = os.system('qemu-nbd -c /dev/nbd0 %s' % image_path)
		assert ret == 0
		# TODO: automatic primary partition discovery
		time.sleep(3)
		
		if guest in active_ubuntu_guests:
			ret = self.mount_ubuntu(target)
		if guest in active_fedora_guests:
			ret = self.mount_fedora(target)
		if guest in active_windows_guests:
			ret = self.mount_windows(target)
		assert ret == 0
		
		return target

	def umount(self, guest):
		target = self.mount_target(guest)
		if not os.path.exists(target):
			return

		ret = os.system('umount %s' % target)
		assert ret == 0
		os.rmdir(target)
		
		if guest in active_fedora_guests:
			ret = os.system('vgchange -an VolGroup')
			assert ret == 0

		ret = os.system('qemu-nbd -d /dev/nbd0')
		assert ret == 0

	def create(self, guest, blocking=True):
		self._execute_cmd('virsh create %s' % config_map[guest], blocking)

	def shutdown(self, guest, blocking=True):
		if blocking:
			self._execute_cmd('virsh shutdown %s' % guest, True)
		else:
			self._execute_cmd('virsh shutdown %s' % guest, False)

	def shutdown_all(self, blocking=True):
		if blocking:
			for	guest in active_linux_guests:
				self._execute_cmd('virsh shutdown %s' % guest, True)
		else:
			for guest in active_linux_guests:
				self._execute_cmd('virsh shutdown %s' % guest, False)

		if blocking:
			for	guest in active_windows_guests:
				self._execute_cmd('virsh destroy %s' % guest, True)
		else:
			for guest in active_windows_guests:
				self._execute_cmd('virsh destroy %s' % guest, False)

	def destroy(self, guest, blocking=True):
		self._execute_cmd('virsh destroy %s' % guest, blocking)

	def destroy_all(self, blocking=True):
		for guest in active_guests:
			self._execute_cmd('virsh destroy %s' % guest, blocking)

	def restore(self, guest):
		self._execute_cmd('virsh restore %s' % guests_saved_state_map[guest], True)

	def _execute_cmd(self, cmd, blocking):
		if not blocking:
			cmd += ' &'
        #print cmd
		ret = os.system(cmd)
        #assert ret == 0

