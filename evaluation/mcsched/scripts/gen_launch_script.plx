#!/usr/bin/perl -w

# default path
$eval_conf_fn = "../config/eval_config";
$guest_conf_fn = "../virsh/guest_config";
$templ = "launch_template";

@ubuntu_workloads  = qw( impress firefox chrome gimp );
@windows_workloads = qw( powerpoint );
for (@ubuntu_workloads)  { $is_ubuntu_workload{$_} = 1 }

if (@ARGV == 1 && $ARGV[0] eq "-c") {
	$clean = 1;
}
elsif (@ARGV == 2) {
	$nr_iter = shift(@ARGV);
	$think_time_ms = shift(@ARGV);
}
else {
	print "$0 <# of iteration (unit: 10)> <think time in ms>\n";
	exit;
}

# get eval config
unless ($clean) {
	die "$eval_conf_fn doesn't exist. You MUST create $eval_conf_fn based on eval_config.example (Don't touch eval_config.example itself!)\n" if ! -e $eval_conf_fn;
	open FD, "$eval_conf_fn";
	while(<FD>) {
		@f = split(/\s+/);
		$conf{$f[0]} = $f[1];
	}
	close FD;
	die "$guest_conf_fn doesn't exist. You MUST create $guest_conf_fn based on guest_config.example (Don't touch guest_config.example itself!)\n" if ! -e $guest_conf_fn;
	open FD, "$guest_conf_fn";
	while(<FD>) {
		@f = split(/\s+/);
		$conf{$f[0]} = $f[1];
	}
	close FD;
}

open FD, $templ or die "file open error: $templ\n" unless $clean;
foreach $p (@ubuntu_workloads, @windows_workloads) {
	$workload = $p . "_launch";
	$subdir = $is_ubuntu_workload{$p} ? "ubuntu/interactive" : "windows/interactive";
	if ($clean) {
		`rm -f $subdir/$workload`;
		next;
	}
        seek (FD, 0, 0);
        open OFD, ">$subdir/$workload";
	while(<FD>) {
		s/^(CLIENT_HOME=)/$1$conf{'CLIENT_HOME'}/g;
		s/^(CLIENT_TRACE_DIR=)/$1$conf{'CLIENT_TRACE_DIR'}/g;
		s/^(WORKLOAD=)/$1$workload/g;
		s/^(THINK_TIME_MS=)/$1$think_time_ms/g;
		s/^(NR_ITER=)/$1$nr_iter/g;
		s/^(SPICE_PORT=)/$1$conf{'SPICE_PORT_BASE'}/g;

		print OFD "$_";
	}
	close OFD;
}
close FD;
