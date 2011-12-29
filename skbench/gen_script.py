import re
from config import *
import time

default_disabled_services = ['sysklogd', 'klogd']
jobs = []

class Gen_script:
	def __init__(self, workload_file, private_arg):
        # load config file and workload file
		exec( open( workload_file ).read() )

		num_of_waits = len(active_guests)
		if trace_replay == 1:
			num_of_waits += len(trace_guests)
			num_of_waits += len(windows_trace_guests)
	
		self.job = {}

        ####### Host's job is treated separately #######
		self.job[0] = """
			echo "Waiting for results from guest in background..."
			for N in $GUEST_NS; do
				nc -l -p $((20000 + $N)) > /tmp/result$N &
			done
		"""
		
		self.job[0] += """
			for GUEST_IP in $GUEST_IPS; do
				ssh $GUEST_IP ~/job > /dev/null &
			done
		"""

		if trace_replay == 1:
			base = len(active_guests) + 1
			for n in range(base, len(trace_guests) + len(windows_trace_guests) + base):
				self.job[0] += "ssh %s ~/job_%d > /dev/null &" % (client_machine_ip, n)

		self.job[0] += """
			# wait for guests' initializing
			wait_signal_64 %d 10000

			virsh list
			echo "[All guests are ready to execute]"
		""" % num_of_waits

		self.job[0] += "PRIVATE_ARG=%s          # for prolog and epilog\n" % private_arg

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
		"""
		if trace_replay == 1:
			base = len(active_guests) + 1
			for n in range(base, len(trace_guests) + len(windows_trace_guests) + base):
				port = 30000 + n
				self.job[0] += "send_signal_%s %s %d\n" % (client_machine_bitness, client_machine_ip, port)

		self.job[0] += """
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
		""" % num_of_waits

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
		for guest_id in range(len(active_guests)):
			job_id = guest_id + 1;     
			
			self.job[job_id] = 'export PRIVATE_ARG=%s           # private argument provided by skbench\n' % private_arg

			f = open( 'scripts/' + workload_scripts[guest_id] )
			self.job[job_id] += f.read()
			f.close()

			# replace predefined macros with real commands
			guest_name = active_guests[guest_id]
            # replace WAIT_START_SIGNAL with real command. If this macro is not found, real command is augmented at start.
			self.job[job_id], nr_rep = re.subn( "WAIT_START_SIGNAL", "wait_signal_%s 1 10001   # WAIT_START_SIGNAL\n" % guest_bitness[guest_name], self.job[job_id] )

            # replace SEND_BOOT_SIGNAL with real command. If this macro is not found, real command is augmented at start.
			self.job[job_id], nr_rep = re.subn( "SEND_READY_SIGNAL", "send_signal_%s $IP_HOST 10000     # SEND_READY_SIGNAL\n" % guest_bitness[guest_name], self.job[job_id] )
			if nr_rep < 1:
				self.job[job_id] = 'send_signal_%s $IP_HOST 10000   # SEND_READY_SIGNAL\n' % guest_bitness[guest_name] + self.job[job_id]

#			if active_linux_guests[guest_id] in active_ubuntu_guests:
			self.job[job_id] = re.sub( "TO_HOST", "nc -q 0 $IP_HOST $((20000 + %d))" % job_id, self.job[job_id] )
#			else:
#				self.job[job_id] = re.sub( "TO_HOST", "nc $IP_HOST $((20000 + %d))" % job_id, self.job[job_id] )
	
            # Workload start

			self.job[job_id] += 'send_signal_%s $IP_HOST 10002\n' % guest_bitness[guest_name]

		if trace_replay == 1:
			base = len(active_guests)
			for guest_id in range(base, len(trace_guests) + len(windows_trace_guests) + base):
				job_id = guest_id + 1

				f = open( 'scripts/' + workload_scripts[guest_id] )
				self.job[job_id] = f.read()
				f.close()

				wait_port = 30000 + job_id
				self.job[job_id], nr_rep = re.subn( "WAIT_START_SIGNAL", "wait_signal_%s 1 %d # WAIT_START_SIGNAL\n" % (client_machine_bitness, wait_port), self.job[job_id] )

				self.job[job_id], nr_rep = re.subn( "SEND_READY_SIGNAL", "send_signal_%s $IP_HOST 10000 # SEND_READY_SIGNAL\n" % client_machine_bitness, self.job[job_id] )
				if nr_rep < 1:
					self.job[job_id] = 'send_signal_%s $IP_HOST 10000 # SEND_READY_SIGNAL\n' % client_machine_bitness + self.job[job_id]

				self.job[job_id] += 'send_signal_%s $IP_HOST 10002\n' % client_machine_bitness

			
