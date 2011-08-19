import re
from config import *
import time

default_disabled_services = ['sysklogd', 'klogd']
jobs = []

class Gen_script:
	def __init__(self, workload_file, private_arg, active_guest_num, auto_mode, passive_mode):
        # load config file and workload file
		exec( open( workload_file ).read() )

		num_of_guests = active_guest_num;
		if num_of_guests == 0:
			num_of_guests = len( workload_scripts )

		wait_guest_num = 1
		if auto_mode == 1:
			wait_guest_num = num_of_guests
		
		self.disabled_services = {}
		for n in range(num_of_guests):
			self.disabled_services[1 + n] = default_disabled_services

		self.job = {}

        ####### Host's job is treated separately #######
		self.job[0] = """
			echo "Waiting for results from guest in background..."
			for N in $GUEST_NS; do
				nc -l -p $((20000 + $N)) > /tmp/result$N &
			done
		"""
		#TODO: multiple vcpu handling
		#self.job[0] += """
		#pcpu_number=`cat /proc/cpuinfo | grep "siblings" | tail -1 | cut -d: -f2`
		#"""
		pcpu_num = 0
		for guest in active_guests:
			self.job[0] += "virsh vcpupin %s 0 %d\n" % (guest, pcpu_num)
			self.job[0] += "virsh vcpuinfo %s\n" % guest
			pcpu_num += 1
			pcpu_num %= 4

		self.job[0] += """
			# wait for guests' booting
			wait_signal_64 %d 10000

			virsh list
			echo "[All guests finish booting]"
		""" % num_of_guests

		self.job[0] += "PRIVATE_ARG=%s          # for prolog and epilog\n" % private_arg

		#TODO: clarify manual mode
		if auto_mode == 0:
			self.job[0] += """
				echo "[Manual test mode]" 
				echo "  To start, send_signal $IP_HOST 10001"
				echo "  To end,   send_signal $IP_HOST 10002"
				sleep 3; 
				echo $PRIVATE_ARG | nc canh1.kaist.ac.kr 33333          # semi-auto 
				wait_signal_64 1 10001
			""" 

        # Prolog part
		self.job[0] += "# prolog\n"

		f = open( 'scripts/' + prolog_script )
		lines = f.readlines()
		self.job[0] += '\t'.join(lines);
		f.close()

		self.job[0] += """
			# send signals to all guest with WAIT_START_SIGNAL
			for GUEST_IP in $GUEST_IPS; do
				send_signal_64 $GUEST_IP 10001
			done

			echo -n "start_time="
			date +%%s %s

			echo "[Workloads start...]"
		""" % ''

		self.job[0] += """
			# wait for stop signal
			wait_signal_64 %d 10002
			echo -n "end_time="
			date +%%s
			echo "[Workloads end]"

			# epilog 
		""" % len(active_guests) #wait_guest_num

#TODO: adjust when auto_mode == 0
		if auto_mode == 0:
			self.job[0] += """
				# send signals to all guest with WAIT_STOP_SIGNAL
				echo "Sending stop signals to all domU with WAIT_STOP_SIGNAL"
				for DOMU_IP in $DOMU_IPS; do
					send_signal_64 $DOMU_IP 10002
				done
			"""

		f = open( 'scripts/' + epilog_script )
		lines = f.readlines()
		self.job[0] += '\t'.join(lines);
		f.close()

		self.job[0] += """
			echo "Waiting for getting results from guests..."
			sleep 3
			echo "[Results of guests]"
			for N in $GUEST_NS; do
				echo "Guest$N:"
				cat /tmp/result$N
			done
		"""

        ####### Generate scripts for guest based on workload file #######
		for guest_id in range(len(active_linux_guests)):
			job_id = guest_id + 1;     

			self.job[job_id] = 'export PRIVATE_ARG=%s           # private argument provided by skbench\n' % private_arg
			if passive_mode:
				self.job[job_id] += 'export SKBENCH=1                # indicate following workload is started by skbench\n'
				self.job[job_id] += 'export PATH=$PATH:/usr/local/bin\n'

			f = open( 'scripts/' + workload_scripts[guest_id] )
			self.job[job_id] += f.read()
			f.close()

			# replace predefined macros with real commands
			if passive_mode == 0:
                # replace WAIT_START_SIGNAL with real command. If this macro is not found, real command is augmented at start.
				self.job[job_id], nr_rep = re.subn( "WAIT_START_SIGNAL", "wait_signal_32 1 10001   # WAIT_START_SIGNAL\n", self.job[job_id] )
				if nr_rep < 1:
					self.job[job_id] = 'wait_signal_32 1 10001    # WAIT_START_SIGNAL\n' + self.job[job_id]

                # replace SEND_BOOT_SIGNAL with real command. If this macro is not found, real command is augmented at start.
				self.job[job_id], nr_rep = re.subn( "SEND_BOOT_SIGNAL", "send_signal_32 $IP_HOST 10000     # SEND_BOOT_SIGNAL\n", self.job[job_id] )
				if nr_rep < 1:
					self.job[job_id] = 'send_signal_32 $IP_HOST 10000   # SEND_BOOT_SIGNAL\n' + self.job[job_id]

				if auto_mode == 0:
                    # replace WAIT_STOP_SIGNAL with real command. If this macro is not found, real command is augmented at end.
					self.job[job_id], nr_rep = re.subn( "WAIT_STOP_SIGNAL", "wait_signal_32 1 10002    # WAIT_STOP_SIGNAL", self.job[job_id] )
					if nr_rep < 1:
						self.job[job_id] += 'wait_signal_32 1 10002    # WAIT_STOP_SIGNAL\n'

			if active_linux_guests[guest_id] in active_ubuntu_guests:
				self.job[job_id] = re.sub( "TO_HOST", "nc -q 0 $IP_HOST $((20000 + %d))" % job_id, self.job[job_id] )
			else:
				self.job[job_id] = re.sub( "TO_HOST", "nc $IP_HOST $((20000 + %d))" % job_id, self.job[job_id] )
	
            # Workload start

			if auto_mode == 1:
				self.job[job_id] += 'send_signal_32 $IP_HOST 10002\n'

		for guest_id in range(len(active_windows_guests)):
			guest_id += len(active_linux_guests);
			job_id = guest_id + 1;
			self.job[job_id] = ''
			f = open( 'scripts/' + workload_scripts[guest_id] )
			self.job[job_id] += f.read()
			f.close()
			
