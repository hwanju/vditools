#!/usr/bin/python

import sys
import os
import getopt
from gen_script import Gen_script
from command import *

commands = {
	'start-stop': start_stop,
}

def print_usage_and_exit():
	sys.stdout = sys.stderr
	print '%s -w <workload file> [options] [values] COMMAND ARGUMENTS...' % sys.argv[0]
	print
	print 'COMMANDs:'
	print 'start-stop\t(update is implied)'

	print '\nOptions' 
	print '\t-p\ta private argument to be delivered to prolog and epilog scripts in a workload file (default 0)'

	sys.exit(-1);

if __name__ == '__main__':
	# default arguments
	workload_file = ''
	private_arg = ''

	opts, args = getopt.getopt( sys.argv[1:], 'w:p' )
	for opt, arg in opts:
		if opt == '-w':     # config file
			workload_file = arg
		if opt == '-p':
			private_arg = arg

	if len(args) < 1 or args[0] not in commands: 
		print_usage_and_exit();

	cmd = args[0]
    # if workload path doesn't exsit, add a prefix 'workload/' to the path
	if not os.path.isabs( workload_file ) and not os.path.isfile( workload_file ):
		workload_file = 'workloads/' + workload_file
		if not os.path.isfile( workload_file ):
			print >> sys.stderr, '%s is not found' % workload_file
			sys.exit(-1)

	print '%s is used as a workload file' % workload_file
       
	commands[cmd]( Gen_script( workload_file, private_arg) )
