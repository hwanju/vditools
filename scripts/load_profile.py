#!/usr/bin/python

import sys
import re

class Gthread_Load_Info:
        def __init__(self, guest_task_id, vcpu_id, cur_load_idx, load_idx, cpu_load, nr_load_entries):
                self.guest_task_id = guest_task_id
                self.vcpu_id = vcpu_id
                self.nr_load_entries = nr_load_entries
                self.cpu_load = [0] * nr_load_entries
                self.invalid_load = 0 
                self.set_load(cur_load_idx, load_idx, cpu_load)

        def set_load(self, cur_load_idx, load_idx, cpu_load):
                self.cur_load_idx = cur_load_idx
                self.cpu_load[load_idx] = cpu_load

        def report_load(self, ofile, load_idx):
                if (self.invalid_load == 0):
                        ofile.write("%-10d" % self.cpu_load[load_idx])
                else:
                        ofile.write("%-10d" % 0)
                if (load_idx == self.cur_load_idx):
                        self.invalid_load = 1

class VCPU_Load_Info:
        def __init__(self, vm_id, vcpu_id, cur_load_idx, load_idx, cpu_load, nr_load_entries):
                self.vm_id = vm_id
                self.vcpu_id = vcpu_id
                self.nr_load_entries = nr_load_entries
                self.cpu_load = [0] * nr_load_entries
                self.set_load(cur_load_idx, load_idx, cpu_load)
                self.gthread_load_info = {}

        def set_load(self, cur_load_idx, load_idx, cpu_load):
                self.cur_load_idx = cur_load_idx
                self.cpu_load[load_idx] = cpu_load

        def set_gthread_load(self, guest_task_id, vcpu_id, cur_load_idx, load_idx, cpu_load):
                if (guest_task_id in self.gthread_load_info):
                        self.gthread_load_info[guest_task_id].set_load(cur_load_idx, load_idx, cpu_load)
                else:
                        self.gthread_load_info[guest_task_id] = Gthread_Load_Info(guest_task_id, vcpu_id, cur_load_idx, load_idx, cpu_load, self.nr_load_entries)

        def report_load(self, ofile, start_load_time, end_load_time):
                start_load_idx = vm_load_info[self.vm_id].load_idx_by_time(start_load_time)
                end_load_idx   = vm_load_info[self.vm_id].load_idx_by_time(end_load_time)

                # ui event info
                ofile.write("# ui_event: epoch=%d offset=%d\n" % (abs(end_load_idx-start_load_idx) - 1, start_load_time % vm_load_info[self.vm_id].get_load_period()))
                # print label
                ofile.write("%-10s%-10s%-10s" % ("#epoch", "ptime", "vcpu"))
                for gtid in self.gthread_load_info:
                        ofile.write("%-10s" % gtid)
                ofile.write("\n")

                load_idx = (end_load_idx + 1) % self.nr_load_entries
                invalid_load = 0
                for i in range(self.nr_load_entries):
                        # epoch
                        ofile.write("%-10d" % i)

                        # ptime
                        if (load_idx != end_load_idx):
                                ofile.write("%-10d" % vm_load_info[self.vm_id].get_load_period())
                        else:
                                ofile.write("%-10d" % (end_load_time % vm_load_info[self.vm_id].get_load_period()))

                        # vcpu load
                        if (invalid_load == 0):
                                ofile.write("%-10d" % self.cpu_load[load_idx])
                        else:
                                ofile.write("%-10d" % 0)

                        # gthread load
                        for gtid in self.gthread_load_info:
                                self.gthread_load_info[gtid].report_load(ofile, load_idx)
                        ofile.write("\n")

                        if (load_idx == end_load_idx):
                                break
                        if (load_idx == self.cur_load_idx):
                                invalid_load = 1
                        load_idx = (load_idx + 1) % self.nr_load_entries
                self.clear()
        
        def clear(self):
                self.gthread_load_info.clear()

class VM_Load_Info:
        def __init__(self, vm_id, nr_load_entries, load_period_msec, start_load_time, end_load_time):
                self.profile_id = 0
                self.set_info(vm_id, nr_load_entries, load_period_msec, start_load_time, end_load_time)
                self.vcpu_load_info = {}

        def set_info(self, vm_id, nr_load_entries, load_period_msec, start_load_time, end_load_time):
                self.profile_id = self.profile_id + 1
                self.vm_id = vm_id
                self.nr_load_entries = nr_load_entries
                self.load_period_msec = load_period_msec
                self.start_load_time = start_load_time
                self.end_load_time = end_load_time

        def load_idx_by_time(self, time_in_ns):
                return (time_in_ns / 1000000 / self.load_period_msec) % self.nr_load_entries 

        def get_load_period(self):
                return self.load_period_msec * 1000000  # in ns

        def set_vcpu_load(self, vcpu_id, cur_load_idx, load_idx, cpu_load):
                if (vcpu_id in self.vcpu_load_info):
                        self.vcpu_load_info[vcpu_id].set_load(cur_load_idx, load_idx, cpu_load)
                else:
                        self.vcpu_load_info[vcpu_id] = VCPU_Load_Info(self.vm_id, vcpu_id, cur_load_idx, load_idx, cpu_load, self.nr_load_entries)

        def set_gthread_load(self, vcpu_id, guest_task_id, cur_load_idx, load_idx, cpu_load):
                self.vcpu_load_info[vcpu_id].set_gthread_load(guest_task_id, vcpu_id, cur_load_idx, load_idx, cpu_load)

        def report_load(self):
                for vcpu_id in self.vcpu_load_info.keys():
                        ofile = open("load-vm%d-vcpu%d-id%d.dat" % (self.vm_id, vcpu_id, self.profile_id), 'w')
                        # print global information
                        self.vcpu_load_info[vcpu_id].report_load(ofile, self.start_load_time, self.end_load_time)
                        ofile.close()
                self.clear()
        def clear(self):
                self.vcpu_load_info.clear()

load_check_event   = re.compile(r'''LC ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
vcpu_load_event    = re.compile(r'''VL ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
gthread_load_event = re.compile(r'''TL ([0-9]+) ([0-9]+) ([0-9a-f]+) ([0-9]+) ([0-9]+) ([0-9]+)''')

if (len(sys.argv) != 2):
        print "Usage: %s <load dump file>" % sys.argv[0]
        exit(-1)
input_filename = sys.argv[1];
load_file = open(input_filename, 'r')

vm_load_info = {}

for line in load_file:
        p = load_check_event.search(line);
        if not (p == None):
                op = int(p.group(1))
                vm_id = int(p.group(2))
                if (op == 1):   # entry
                        if (vm_id in vm_load_info):
                                vm_load_info[vm_id].set_info(vm_id, int(p.group(3)), int(p.group(4)), int(p.group(5)), int(p.group(6)))
                        else:
                                vm_load_info[vm_id] = VM_Load_Info(vm_id, int(p.group(3)), int(p.group(4)), int(p.group(5)), int(p.group(6)))
                else:           # exit
                        vm_load_info[vm_id].report_load()
                continue
        p = vcpu_load_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].set_vcpu_load(int(p.group(2)), int(p.group(3)), int(p.group(4)), int(p.group(5)))
                continue
        p = gthread_load_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].set_gthread_load(int(p.group(2)), p.group(3), int(p.group(4)), int(p.group(5)), int(p.group(6)))
                continue
