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

                ####if load_idx == cur_load_idx:
                ####        self.invalid_load = 1
                

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
                self.cpu_load   = [0] * (nr_load_entries * 20)    # FIXME: remove hardcoded number
                self.run_delay  = [0] * (nr_load_entries * 20)    # FIXME: remove hardcoded number
                self.vcpu_flags = [0] * (nr_load_entries * 20)    # FIXME: remove hardcoded number
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
                #if self.vcpu_id == 0:
                #        print "DEBUG: set_load - cur_load_idx=%d, load_idx=%d(%d), cpu_load=%d, invalid_load=%d" % (cur_load_idx, load_idx, self.load_idx, cpu_load, self.invalid_load)

                self.load_idx = self.load_idx + 1

                #### if load_idx == cur_load_idx:
                ####         self.invalid_load = 1

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
                #if self.vcpu_id == 0:
                #        print "DEBUG:\tupdate_load_idx=%d" % (self.load_idx)
                self.invalid_load = 0
                for gtid in self.gthread_load_info:
                        self.gthread_load_info[gtid].update_load_idx(start_load_idx)

        ### called at load check entry (LC 1) & load check exit (LC 0)
        def make_run_delay_ratio(self, monitor_period): 

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

        def set_vcpu_flags(self, start_load_idx, vcpu_flags):
                for i in range(start_load_idx, self.load_idx):
                        self.vcpu_flags[i] = vcpu_flags

        def report_load(self, ofile, start_load_time, end_load_time):
                # ui event info: FIXME
                start_load_idx = vm_load_info[self.vm_id].load_idx_by_time(start_load_time)
                end_load_idx   = vm_load_info[self.vm_id].load_idx_by_time(end_load_time)
                load_period_ns = vm_load_info[self.vm_id].get_load_period();
                #ofile.write("# ui_event: epoch=%d offset=%d\n" % (abs(end_load_idx-start_load_idx) - 1, start_load_time % load_period_ns))

                # print label
                ofile.write("%-10s%-10s%-10s%-10s" % ("#time", "epoch", "ptime", "vcpu"))
                for gtid in self.gthread_load_info:
                        gtid_with_tag = "%s/%s" % (gtid, vm_load_info[self.vm_id].get_gtask_class_tag(gtid))
                        ofile.write("%-10s" % gtid_with_tag)
                ofile.write("%-20s%-10s" % ("run_delay_ratio", "vcpu_flags"))
                ofile.write("\n")

                pre_monitor_period = (self.nr_load_entries - 1) * load_period_ns / 1000000
                invalid_load = 0
                for i in range(self.load_idx + 8):        # FIXME
                        # time (ms)
                        ofile.write("%-10d" % (i * (load_period_ns / 1000000) - pre_monitor_period))

                        # epoch
                        ofile.write("%-10d" % i)

                        # ptime
                        ofile.write("%-10d" % load_period_ns)

                        # vcpu load
                        ofile.write("%-10d" % self.cpu_load[i])

                        # gthread load
                        for gtid in self.gthread_load_info:
                                self.gthread_load_info[gtid].report_load(ofile, i)
                        
                        # vcpu run_delay
                        ofile.write("%-10.3lf" % self.run_delay[i])

                        # vcpu flags
                        ofile.write("%d" % self.vcpu_flags[i])

                        ofile.write("\n")

                self.clear()
        
        def clear(self):
                self.gthread_load_info.clear()

class VM_Load_Info:
        def __init__(self, vm_id):
                self.profile_id = 0
                self.load_seqnum = 0
                self.vcpu_load_info = {}
                self.background_tasks = set()
                self.interactive_tasks = set()
                self.ambiguous_tasks = set()
                self.event_type = ""

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
                else:
                        self.start_load_idx = self.start_load_idx + self.nr_loads()

                for vcpu_id in self.vcpu_load_info.keys():
                        self.vcpu_load_info[vcpu_id].update_load_idx(self.start_load_idx)

        def make_run_delay_ratio(self, start_load_time, end_load_time):
                monitor_period = end_load_time - start_load_time
                #if self.load_seqnum == 1:
                #        monitor_period = (self.nr_load_entries * self.load_period_msec * 1000000) - monitor_period
                for vcpu_id in self.vcpu_load_info.keys():
                        self.vcpu_load_info[vcpu_id].make_run_delay_ratio(monitor_period)

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

        def set_vcpu_flags(self, vcpu_id, vcpu_flags):
                if (vcpu_id in self.vcpu_load_info):
                        self.vcpu_load_info[vcpu_id].set_vcpu_flags(self.start_load_idx, vcpu_flags)

        def set_gthread_load(self, vcpu_id, guest_task_id, cur_load_idx, load_idx, cpu_load):
                if (vcpu_id not in self.vcpu_load_info):
                        self.vcpu_load_info[vcpu_id] = VCPU_Load_Info(self.vm_id, vcpu_id, cur_load_idx, load_idx, cpu_load, self.nr_load_entries)
                self.vcpu_load_info[vcpu_id].set_gthread_load(guest_task_id, vcpu_id, cur_load_idx, load_idx, cpu_load)

        def classify_gtask(self, guest_task_id, flags):
                if flags & 2:
                        self.background_tasks.add(guest_task_id)
                elif flags & 1:
                        self.interactive_tasks.add(guest_task_id)
                elif flags == 0:
                        self.ambiguous_tasks.add(guest_task_id)
        def update_ui_info(self, event_type, event_info):
                if (event_type == 0 and event_info == 28) or event_type == 3:
                        self.profile_id = self.profile_id + 1

                        if event_type == 0:
                                self.event_type = "Key"
                        elif event_type == 3:
                                self.event_type = "Mouse"

        def clear(self):
                self.vcpu_load_info.clear()

        def report_gtask_class(self):
                ofile = open("class-vm%d-id%d.dat" % (self.vm_id, self.profile_id), 'w')
                ofile.write("background: ")
                for gtid in self.background_tasks:
                        ofile.write("%s " % gtid)
                ofile.write("\n")
                ofile.write("interactive: ")
                for gtid in self.interactive_tasks:
                        ofile.write("%s " % gtid)
                ofile.write("\n")
                ofile.write("ambiguous: ")
                for gtid in self.ambiguous_tasks.difference(self.interactive_tasks):
                        ofile.write("%s " % gtid)
                ofile.write("\n")
                ofile.close()

                self.background_tasks.clear()
                self.interactive_tasks.clear()
                self.ambiguous_tasks.clear()

        def get_gtask_class_tag(self, gtid):
                if gtid in self.background_tasks:
                        return "B";
                elif gtid in self.interactive_tasks:
                        return "I";
                return "A";

        def report_load(self):
                self.make_run_delay_ratio(self.start_load_time, self.end_load_time)
                for vcpu_id in self.vcpu_load_info.keys():
                        ofile = open("load-vm%d-vcpu%d-id%d.dat" % (self.vm_id, vcpu_id, self.profile_id), 'w')
                        # print global information
                        self.vcpu_load_info[vcpu_id].report_load(ofile, self.start_load_time, self.end_load_time)
                        ofile.close()
                ofile = open("event-vm%d-id%d.dat" % (self.vm_id, self.profile_id), 'w')
                ofile.write( "%s %.2lf %.2lf\n" % (self.event_type, self.nr_load_entries - 1.5, 0.99))

                self.report_gtask_class()

                self.clear()
                self.load_seqnum = 0

        #def inc_profile_id(self):
        #        self.profile_id = self.profile_id + 1

        def get_profile_id(self):
                return self.profile_id

load_check_event   = re.compile(r'''LC ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
vcpu_load_event    = re.compile(r'''VL ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
gthread_load_event = re.compile(r'''TL ([0-9]+) ([0-9]+) ([0-9a-f]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
vcpu_stat_event    = re.compile(r'''VS ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)''')
gtask_stat_event   = re.compile(r'''TS ([0-9]+) ([0-9]+) ([0-9a-f]+) ([0-9]+) ([0-9]+)''')
ui_event           = re.compile(r'''UI ([0-9]+) ([0-9]+) ([0-9]+)''')

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
                        vm_load_info[vm_id].set_info(vm_id, int(p.group(3)), int(p.group(4)), int(p.group(5)), int(p.group(6)))
                else:           # exit
                        vm_load_info[vm_id].report_load()
                        #vm_load_info[vm_id].inc_profile_id()
                continue
        p = vcpu_load_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].set_vcpu_load(int(p.group(2)), int(p.group(3)), int(p.group(4)), int(p.group(5)))
                continue
        p = vcpu_stat_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].set_run_delay(int(p.group(2)), int(p.group(3)))
                vm_load_info[vm_id].set_vcpu_flags(int(p.group(2)), int(p.group(4)))
                continue
        p = gthread_load_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].set_gthread_load(int(p.group(2)), p.group(3), int(p.group(4)), int(p.group(5)), int(p.group(6)))
                continue
        p = gtask_stat_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                vm_load_info[vm_id].classify_gtask(p.group(3), int(p.group(5)))
                continue
        p = ui_event.search(line);
        if not (p == None):
                vm_id = int(p.group(1))
                if (vm_id not in vm_load_info):
                        vm_load_info[vm_id] = VM_Load_Info(vm_id)
                vm_load_info[vm_id].update_ui_info(int(p.group(2)), int(p.group(3)))
                continue
