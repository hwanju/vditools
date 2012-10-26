#!/usr/bin/perl -w

die "Usage: $0 <vamp_bg debug file>\n" unless @ARGV == 1;
$dbgfn = shift(@ARGV); 
$latfn = $dbgfn;
$latfn =~ s/\.debug/\.latency/g;
$mult = $dbgfn =~ /launch/ ? 2 : 1;
@lat_samples = `./get_latency.plx $latfn $mult`;
$nr_samples = int(@lat_samples);

open FD, "$dbgfn" or die "file open error: $dbgfn\n";
$id = 0;
while(<FD>) {
	if (/LC id=(\d+) op=1/) {
		$id = $1;
		chomp($lat_samples[$id-1]);
		last if $id >= $nr_samples;
		print "\n$lat_samples[$id-1]";
	}
	elsif (/BG t=([0-9a-f]+) pid=(\d+) f=2 n=(\w+)/) {
		$task_id = $1;
		$pid = $2;
		$name = $3;
		printf "\t%-17s%-8s%-8s", $name, $task_id, $pid;
	}
}
close FD;
print "\n";
