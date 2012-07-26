#!/usr/bin/perl -w

die "Usage: $0 <logfile> [mode]\n" unless @ARGV >= 1;
$logfn = shift(@ARGV);
$mode = @ARGV ? shift(@ARGV) : -1;
open FD, $logfn or die "Error: file open error ($logfn)\n";

$bin_us = 10000;
$max_bid = 0;

while(<FD>) {
        ($m, $lat_us) = split(/\s+/);
        next if ($mode >= 0 && $m != $mode);
        $bid = int($lat_us / $bin_us);
        $histo{$bid}++;
        $max_bid = $bid if $bid > $max_bid;
        $nr_lats++;
}

foreach $bid (0 .. $max_bid) {
        printf "%d\t%.3lf\n", $bid * ($bin_us / 1000), defined($histo{$bid}) ? $histo{$bid} / $nr_lats : 0;
}
