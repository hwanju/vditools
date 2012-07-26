#!/usr/bin/perl -w

$fn = @ARGV ? shift(@ARGV) : "load_sample.dump";
open FD, $fn or die "file open error: $fn\n";
while(<FD>) {
        if (/^LI \d+ 1 0 (\d+) (\d+) (\d+) (\d+)/ ) {
                $id++;
                print "$id: phase=$1 pload=$2 load=$3 gload=$4\n";
        }
}
