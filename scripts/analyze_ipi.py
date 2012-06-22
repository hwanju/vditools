#!/usr/bin/python

import sys
import re
import copy

class ReschedIpiFlow:
	def __init__(self):
		self.vcpu_flow = []
		self.last_dst_vcpus = []
		self.flow_type = 1
		self.start_time_us = 0

	def add_entry(self, time_us, src_vcpu_id, dst_vcpu_id):
		self.vcpu_flow.append([src_vcpu_id, dst_vcpu_id])
		self.last_dst_vcpus.append(dst_vcpu_id)

	def check_full(self):
		return (self.flow_type != 2 and len(self.vcpu_flow) == 7) or (self.flow_type == 2 and len(self.vcpu_flow) == 8)	# FIXME

	def update_flow(self, time_us, runtime_after_sched_us, src_vcpu_id, dst_vcpu_id):
		if len(self.vcpu_flow) == 0:
			self.add_entry(time_us, src_vcpu_id, dst_vcpu_id)
			return

		# previous flow exists
		if runtime_after_sched_us <= 100:	# flow threshold
			cascaded = src_vcpu_id in self.last_dst_vcpus

			if self.check_full():
				self.chunk_flow(time_us)
			elif cascaded:
				if self.flow_type == 2 and src_vcpu_id == self.last_dst_vcpus[0]:
					self.flow_type == 3
				self.last_dst_vcpus.remove(src_vcpu_id)
			elif src_vcpu_id == self.vcpu_flow[-1][0]:	# type 2 or 3 flow detected	
				if len(self.vcpu_flow) > 1:
					self.chunk_flow(time_us, True)	# chunk previous flow
				self.last_dst_vcpus = [self.vcpu_flow[0][1]]
				self.flow_type = 2
			else:
				self.chunk_flow(time_us)
		else:
			self.chunk_flow(time_us)

		self.add_entry(time_us, src_vcpu_id, dst_vcpu_id)

	def chunk_flow(self, time_us, keep_tail=False):
		if self.check_full():
			####print "FULL",
			global trace_start_time_us
			print "%d\t1" % (self.start_time_us - trace_start_time_us)
		#### print "%d flow t=%d n=%d" % (self.start_time_us, self.flow_type, len(self.vcpu_flow)), self.vcpu_flow
		if keep_tail:
			self.vcpu_flow = self.vcpu_flow[-1:]
		else:
			self.vcpu_flow = []
		self.flow_type = 1
		self.start_time_us = time_us

	def update_terminal(self, time_us, vcpu_id, state):
		if vcpu_id in self.last_dst_vcpus:
			self.last_dst_vcpus.remove(vcpu_id)
			if len(self.last_dst_vcpus) == 0:
				self.chunk_flow(time_us, True)

if (len(sys.argv) != 2):
        print "Usage: %s <trace file>" % sys.argv[0]
        exit(-1)
trace_fn = sys.argv[1];
trace_file = open(trace_fn, 'r')

ipi_event = re.compile(r'''([0-9]+) ([0-9]+) I fd ([0-9]+) ([0-9]+)''')
desched_event = re.compile(r'''([0-9]+) D ([0-9]+) ([0-9]+)''')

trace_start_time_us = None
resched_ipi_flow = ReschedIpiFlow()
for line in trace_file:
	p = ipi_event.search(line)
	if not (p == None):
		time_us = int(p.group(1))
		runtime_after_sched_us = int(p.group(2))
		src_vcpu_id = int(p.group(3))
		dst_vcpu_id = int(p.group(4))

		if trace_start_time_us == None:
			trace_start_time_us = time_us

		resched_ipi_flow.update_flow(time_us, runtime_after_sched_us, src_vcpu_id, dst_vcpu_id)

	p = desched_event.search(line)
	if not (p == None):
		time_us = int(p.group(1))
		vcpu_id = int(p.group(2))
		state = int(p.group(3))

		resched_ipi_flow.update_terminal(time_us, vcpu_id, state)
		
