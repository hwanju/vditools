#!/usr/bin/perl

$vmlinux_path="/backup/vdikernel/vmlinux";
die "Usage: $0 <lock holder trace file> [vmlinux path(=$vmlinux_path)]\n" unless @ARGV > 0;
$fn = shift(@ARGV);
$vmlinux_path = shift(@ARGV) if @ARGV;

open FD, $fn or die "file open error: $fn\n";

while(<FD>) {
	unless (/^#/) {
		@info = split(/\s+/);

		print "$_";
		foreach $i (1 .. 4) {
			$eip = $info[$i];
			if ($eip ne "0") {
				$indent = "";
				foreach $j (2 .. $i) { $indent .= "\t" };
				$syminfo = `./find_lh_loc.plx $eip $vmlinux_path 2> /dev/null`;
				print "# $indent$syminfo";
			}
		}
        }
}
