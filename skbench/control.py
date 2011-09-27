import os
import re
import time

from config import *

class Control:
	def list(self):
		return os.listdir(guests_img_root)

	def destroy(self, guest, blocking=True):
		self._execute_cmd('virsh destroy %s' % guest, blocking)
		img_path = guests_image_map[guest]
		backup_path = img_path + '.bak'
		ret = os.system('rm %s' % img_path)
		assert ret == 0
		ret = os.system('mv %s %s' % (backup_path, img_path))
		assert ret == 0

	def destroy_all(self, blocking=True):
		for guest in active_guests:
			self.destroy(guest)
		if trace_replay == 1:	
			for guest in trace_guests:
				self.destroy(guest)	

	def restore(self, guest):
		img_path = guests_image_map[guest]
		backup_path = img_path + '.bak'
		ret = os.system('mv %s %s' % (img_path, backup_path))
		assert ret == 0
		ret = os.system('qemu-img create -f qcow2 -b %s %s' % (backup_path, img_path))
		assert ret == 0
		self._execute_cmd('virsh restore %s' % guests_saved_state_map[guest], True)

	def _execute_cmd(self, cmd, blocking):
		if not blocking:
			cmd += ' &'
        #print cmd
		ret = os.system(cmd)
        #assert ret == 0

