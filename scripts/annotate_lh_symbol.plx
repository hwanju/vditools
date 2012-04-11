#!/usr/bin/perl -w

$vmlinux_path="/backup/vdikernel/vmlinux";
die "Usage: $0 <lock holder trace file> [vmlinux path(=$vmlinux_path)]\n" unless @ARGV > 0;
$fn = shift(@ARGV);
$vmlinux_path = shift(@ARGV) if @ARGV;

open FD, $fn or die "file open error: $fn\n";

while(<FD>) {
        if (/([a-f0-9]+)\s+(\d+)/) {
                $eip = $1;
                $count = $2;
                $info = `./find_lh_loc.plx $eip $vmlinux_path 2> /dev/null`;
                print "$eip\t$count\t$info";
        }
}
