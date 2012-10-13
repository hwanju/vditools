#!/usr/bin/perl -w

die "Usage: $0 <debug file> <task_id1> <task_id2> ...\n" unless @ARGV > 0;
$fn = shift(@ARGV);
$prefix = $fn;
$prefix =~ s/\.debug//g;
open FD, $fn or die "file open error: $fn\n";
foreach $tid (@ARGV) {
	$task{$tid} = 1;
	system("rm -f $prefix-$tid.ac");
}
while(<FD>) {
	if (/(\d+) BG t=([0-9a-f]+)/) {
		$time_us = $1;
		$start_time_us = $time_us unless defined($start_time_us);
		$tid = $2;
		if ($task{$tid}) {
			$audio_count = $1 if (/avg=(\d+)/);
			open OFD, ">>$prefix-$tid.ac";
			printf OFD "%.2lf\t$audio_count\n", ($time_us - $start_time_us) / 1000000;
			close(OFD);
		}
	}
}

