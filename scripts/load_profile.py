#!/usr/bin/python

import sys
import re

class Gthread_Load_Info:
        def __init__(self, guest_task_id, vcpu_id, cur_load_idx, load_idx, cpu_load, nr_load_entries, start_load_idx):
                self.guest_task_id = guest_task_id
                self.vcpu_id = vcpu_id
                self.nr_load_entries = nr_load_entries
                self.cpu_load = [0] * (nr_load_entries * 20)    # FIXME: remove hardcoded number
                self.invalid_load = 0 
                self.load_idx = start_load_idx
                self.set_load(cur_load_idx, load_idx, cpu_load)

        def set_load(self, cur_load_idx, load_idx, cpu_load):
                if self.invalid_load == 0:
                        self.cpu_load[self.load_idx] = cpu_load
                else:
                        self.cpu_load[self.load_idx] = 0

                self.load_idx = self.load_idx + 1

                if load_idx == cur_load_idx:
                        self.invalid_load = 1
                

        def update_load_idx(self, start_load_idx):
                self.load_idx = start_load_idx
                self.invalid_load = 0

        def report_load(self, ofile, load_idx):
                ofile.write("%-10d" % self.cpu_load[load_idx])

class VCPU_Load_Info:
        def __init__(self, vm_id, vcpu_id, cur_load_idx, load_idx, cpu_load, nr_load_entries):
                self.vm_id = vm_id
                self.vcpu_id = vcpu_id
                self.nr_load_entries = nr_load_entries
                self.cpu_load  = [0] * (nr_load_entries * 20)    # FIXME: remove hardcoded number
                self.run_delay = [0] * (nr_load_entries * 20)    # FIXME: remove hardcoded number
                self.invalid_load = 0 
                self.gthread_load_info = {}
                self.load_idx = 0               # increment every load setting
                self.start_load_idx = 0         # updated only by update_load_idx
                self.set_load(cur_load_idx, load_idx, cpu_load)

        def set_load(self, cur_load_idx, load_idx, cpu_load):
                if self.invalid_load == 0:
                        self.cpu_load[self.load_idx] = cpu_load
                else:
                        self.cpu_load[self.load_idx] = 0

                self.load_idx = self.load_idx + 1

                if load_idx == cur_load_idx:
                        self.invalid_load = 1

        def set_gthread_load(self, guest_task_id, vcpu_id, cur_load_idx, load_idx, cpu_load):
                if (guest_task_id in self.gthread_load_info):
                        self.gthread_load_info[guest_task_id].set_load(cur_load_idx, load_idx, cpu_load)
                else:
                        self.gthread_load_info[guest_task_id] = Gthread_Load_Info(guest_task_id, vcpu_id, cur_load_idx, 
                                        load_idx, cpu_load, self.nr_load_entries, vm_load_info[self.vm_id].get_start_load_idx())

        ### called at load check entry (LC 1)
        def update_load_idx(self, start_load_idx):
                self.start_load_idx = start_load_idx
                self.load_idx = start_load_idx
                self.invalid_load = 0
                for gtid in self.gthread_load_info:
                        self.gthread_load_info[gtid].update_load_idx(start_load_idx)

        ### called at load check entry (LC 1) & load check exit (LC 0)
        def make_run_delay_ratio(self, start_load_time, end_load_time): 
                monitor_period = end_load_time - start_load_time 

                ### denominator: desched_period -> monitor_period
                ###run_time = 0
                ###for i in range(self.start_load_idx, self.load_idx):
                ###        run_time += self.cpu_load[i]
                ###desched_period = monitor_period - run_time
                for i in range(self.start_load_idx, self.load_idx):
                        #if float(self.run_delay[i]) / monitor_period > 1:
                        #        print "DEBUG: id%d v%d load_idx=%d run_delay=%d, monitor_period=%d, ratio=%.4lf" % (vm_load_info[self.vm_id].get_profile_id(), self.vcpu_id, i, self.run_delay[i], monitor_period, float(self.run_delay[i]) / monitor_period)
                        self.run_delay[i] = float(self.run_delay[i]) / monitor_period
                        if self.run_delay[i] > 1.0:             # small error is possible
                                self.run_delay[i] = 1.0


        def set_run_delay(self, start_load_idx, run_delay):
                for i in range(start_load_idx, self.load_idx):
                        self.run_delay[i] = run_delay

        def report_load(self, ofile, start_load_time, end_load_time):
                # ui event info: FIXME
                start_load_idx = vm_load_info[self.vm_id].load_idx_by_time(start_load_time)
                end_load_idx   = vm_load_info[self.vm_id].load_idx_by_time(end_load_time)
                ofile.write("# ui_event: epoch=%d offset=%d\n" % (abs(end_load_idx-start_load_idx) - 1, start_load_time % vm_load_info[self.vm_id].get_load_period()))

                # print label
                ofile.write("%-10s%-10s%-10s" % ("#epoch", "ptime", "vcpu"))
                for gtid in self.gthread_load_info:
                        ofile.write("%-10s" % gtid)
                ofile.write("%-10s" % "run_delay_ratio")
                ofile.write("\n")

                invalid_load = 0
                for i in range(self.load_idx + 8):        # FIXME
                        # epoch
                        ofile.write("%-10d" % i)

                        # ptime
                        ofile.write("%-10d" % vm_load_info[self.vm_id].get_load_period())

                        # vcpu load
                        ofile.write("%-10d" % self.cpu_load[i])

                        # gthread load
                        for gtid in self.gthread_load_info:
                                self.gthread_load_info[gtid].report_load(ofile, i)
                        
                        # vcpu run_delay
                        ofile.write("%-10.3lf" % self.run_delay[i])

                        ofile.write("\n")

                self.clear()
        
        def clear(self):
                self.gthread_load_info.clear()

class VM_Load_Info:
        def __init__(self, vm_id, nr_load_entries, load_period_msec, start_load_time, end_load_time):
                self.profile_id = 1
                self.load_seqnum = 0
                self.vcpu_load_info = {}
                self.set_info(vm_id, nr_load_entries, load_period_msec, start_load_time, end_load_time)

        def set_info(self, vm_id, nr_load_entries, load_period_msec, start_load_time, end_load_time):
                if self.load_seqnum > 0:
                        self.make_run_delay_ratio(self.start_load_time, self.end_load_time)
                self.update_load_idx(start_load_time)

                self.load_seqnum = self.load_seqnum + 1
                self.vm_id = vm_id
                self.nr_load_entries = nr_load_entries
                self.load_period_msec = load_period_msec
                self.start_load_time = start_load_time
                self.end_load_time = end_load_time

        def update_load_idx(self, start_load_time):
                if self.load_seqnum == 0:
                        self.start_load_idx = 0
                        self.monitor_start_time = start_load_time
                elif self.load_seqnum == 1:
                        self.start_load_idx = self.nr_load_entries - 1
                elif self.load_seqnum > 1:
                        self.start_load_idx = self.start_load_idx + self.nr_loads()

                for vcpu_id in self.vcpu_load_info.keys():
                        self.vcpu_load_info[vcpu_id].update_load_idx(self.start_load_idx)

        def make_run_delay_ratio(self, start_load_time, end_load_time):
                for vcpu_id in self.vcpu_load_info.keys():
                        self.vcpu_load_info[vcpu_id].make_run_delay_ratio(start_load_time, end_load_time)

        def get_start_load_idx(self):
                return self.start_load_idx

        def load_idx_by_time(self, time_in_ns):
                return (time_in_ns / 1000000 / self.load_period_msec) % self.nr_load_entries 

        def nr_loads(self):
                return (self.end_load_time / 1000000 / self.load_period_msec) - (self.start_load_time / 1000000 / self.load_period_msec)

        def get_load_period(self):
                return self.load_period_msec * 1000000  # in ns

        def set_vcpu_load(self, vcpu_id, cur_load_idx, load_idx, cpu_load):
                if (vcpu_id in self.vcpu_load_info):
                        self.vcpu_load_info[vcpu_id].set_load(cur_load_idx, load_idx, cpu_load)
                else:
                        self.vcpu_load_info[vcpu_id] = VCPU_Load_Info(self.vm_id, vcpu_id, cur_load_idx, load_idx, cpu_load, self.nr_load_entries)

        def set_run_delay(self, vcpu_id, run_delay):
                if (vcpu_id in self.vcpu_load_info):
                        self.vcpu_load_info[vcpu_id].set_run_delay(self.start_load_idx, run_delay)

        def set_gthread_load(self, vcpu_id, guest_task_id, cur_load_idx, load_idx, cpu_load):
                self.vcpu_load_info[vcpu_id].set_gthread_load(guest_task_id, vcpu_id, cur_load_idx, load_idx, cpu_load)

        def clear(self):
                self.vcpu_load_info.clear()

        def report_load(self):
                self.make_run_delay_ratio(self.start_load_time, self.end_load_time)
                for vcpu_id in self.vcpu_load_info.keys():
                        ofile = open("load-vm%d-vcpu%d-id%d.dat" % (self.vm_id, vcpu_id, self.profile_id), 'w')
                        # print global information
                        self.vcpu_load_info[vcpu_id].report_load(ofile, self.start_load_time, self.end_load_time)
                        ofile.close()
                self.clear()
                self.load_seqnum = 0

        def inc_profile_id(self):
                self.profile_id = self.profile_id + 1

        def get_profile_id(self):
                return self.profile_id

load_check_event   = re.compile(r'''LC ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
vcpu_load_event    = re.compile(r'''VL ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
gthread_load_event = re.compile(r'''TL ([0-9]+) ([0-9]+) ([0-9a-f]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
run_delay_event    = re.compile(r'''RD ([0-9]+) ([0-9]+) ([0-9]+)''')

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
                        vm_load_info[vm_id].inc_profile_id()
                continue
        p = vcpu_load_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].set_vcpu_load(int(p.group(2)), int(p.group(3)), int(p.group(4)), int(p.group(5)))
                continue
        p = run_delay_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].set_run_delay(int(p.group(2)), int(p.group(3)))
                continue
        p = gthread_load_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].set_gthread_load(int(p.group(2)), p.group(3), int(p.group(4)), int(p.group(5)), int(p.group(6)))
                continue
