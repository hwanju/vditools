#!/usr/bin/python

import sys
import os
import getopt
from gen_script import Gen_script
from command import *

commands = {
	'copy': copy,
	'update': update,
	'clean': clean,
	'start': start,
	'start-stop': start_stop,
	'stop': stop,
	'restore-replay': restore_replay,
}
workload_free_cmds = ( 'copy', 'stop' )

def print_usage_and_exit():
	sys.stdout = sys.stderr
	print '%s -w <workload file> or -r <replay_file> [options] [values] COMMAND ARGUMENTS...' % sys.argv[0]
	print
	print 'COMMANDs:'
	print 'copy SRC-DOM-U DEST-DOM-U...'
	print 'update'
	print 'clean'
	print 'start\t\t(update is implied)'
	print 'start-stop\t(update is implied)'
	print 'stop'
	print 'restore-replay'

	print '\nOptions' 
	print '\t-p\ta private argument to be delivered to prolog and epilog scripts in a workload file (default 0)'
	print '\t-n\tthe number of domain to be tested (must be less than or equal to the number specified in workload file'
	print '\t-a\tautomatic test. each domU sends a start signal to 10001 port and a end signal to 10002'

	sys.exit(-1);

if __name__ == '__main__':
	# default arguments
	workload_file = ''
	replay_file = ''
	private_arg = ''
	active_guest_num = 0
	auto_mode = 0
	passive_mode = 0

	opts, args = getopt.getopt( sys.argv[1:], 'w:r:p:n:as' )
	for opt, arg in opts:
		if opt == '-w':     # config file
			workload_file = arg
		if opt == '-r':
			replay_file = arg
		if opt == '-p':
			private_arg = arg
		if opt == '-n':
			active_guest_num = int(arg)
		if opt == '-a':
			auto_mode = 1
		if opt == '-s':
			passive_mode = 1

	if len(args) < 1 or args[0] not in commands: 
		print_usage_and_exit();

	cmd = args[0]
	if cmd in workload_free_cmds:
		commands[cmd](args[1:])
	elif cmd == 'restore-replay':
		if not os.path.isabs( replay_file ) and not os.path.isfile( replay_file ):
			replay_file = 'replays/' + replay_file
			if not os.path.isfile( replay_file ):
				print >> sys.stderr, '%s is not found' % replay_file
				sys.exit(-1)
		print '%s is used as a replay file' % replay_file
		commands[cmd]( replay_file, active_guest_num )
	else:
        # if workload path doesn't exsit, add a prefix 'workload/' to the path
		if not os.path.isabs( workload_file ) and not os.path.isfile( workload_file ):
			workload_file = 'workloads/' + workload_file
			if not os.path.isfile( workload_file ):
				print >> sys.stderr, '%s is not found' % workload_file
				sys.exit(-1)

		print '%s is used as a workload file' % workload_file
        
		commands[cmd]( Gen_script( workload_file, private_arg, active_guest_num, auto_mode, passive_mode ) )
