#!/usr/bin/python

import sys
import re

FlowID = 0
class CascadedIPIFlow:
	def __init__(self, src_vcpu_id, dst_vcpu_id):
		global FlowID
		self.flow_id = FlowID 
		FlowID = FlowID + 1
		self.vcpu_seq = [src_vcpu_id, dst_vcpu_id]
	def extend_flow(self, src_vcpu_id, dst_vcpu_id):
		if src_vcpu_id == self.vcpu_seq[-1]:	# linked?
			if dst_vcpu_id in self.vcpu_seq:	# not disjoint
				return -1
			self.vcpu_seq.append(dst_vcpu_id)	# cascased (linked & disjoint)
			return 1
		return 0
	def cmp_flow(self, vcpu_id):
		return vcpu_id == self.vcpu_seq[-1]

if (len(sys.argv) != 2):
        print "Usage: %s <trace file>" % sys.argv[0]
        exit(-1)
trace_fn = sys.argv[1];
trace_file = open(trace_fn, 'r')

ipi_event = re.compile(r'''([0-9]+) I fd ([0-9]+) ([0-9]+)''')
blk_event = re.compile(r'''([0-9]+) B ([0-9]+)''')

cascaded_ipi_flow_list = []

for line in trace_file:
	p = ipi_event.search(line)
	if not (p == None):
		time_us = int(p.group(1))
		src_vcpu_id = int(p.group(2))
		dst_vcpu_id = int(p.group(3))

		new = True
		for flow in cascaded_ipi_flow_list:
			ret = flow.extend_flow(src_vcpu_id, dst_vcpu_id)
			if ret == 1:
				print "%d ext: f%d %d->%d n=%d" % (time_us, flow.flow_id, src_vcpu_id, dst_vcpu_id, len(flow.vcpu_seq)), flow.vcpu_seq
				new = False
			elif ret == -1:
				if len(flow.vcpu_seq) == 8:
					print "%d br: f%d %d->%d n=%d" % (time_us, flow.flow_id, src_vcpu_id, dst_vcpu_id, len(flow.vcpu_seq)), flow.vcpu_seq
				else:
					print "%d cc: f%d %d->%d n=%d" % (time_us, flow.flow_id, src_vcpu_id, dst_vcpu_id, len(flow.vcpu_seq)), flow.vcpu_seq
				cascaded_ipi_flow_list.remove(flow)
		if new:	# not found
			flow = CascadedIPIFlow(src_vcpu_id, dst_vcpu_id)
			print "%d new: f%d %d->%d" % (time_us, flow.flow_id, src_vcpu_id, dst_vcpu_id)
			cascaded_ipi_flow_list.append(flow)
	p = blk_event.search(line)
	if not (p == None):
		time_us = int(p.group(1))
		vcpu_id = int(p.group(2))
		for flow in cascaded_ipi_flow_list:
			if flow.cmp_flow(vcpu_id):
				print "%d end: f%d %d n=%d" % (time_us, flow.flow_id, vcpu_id, len(flow.vcpu_seq)), flow.vcpu_seq
				cascaded_ipi_flow_list.remove(flow)

