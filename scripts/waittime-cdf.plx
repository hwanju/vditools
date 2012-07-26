#!/usr/bin/perl -w

die "Usage: $0 <datfile> [mode]\n" unless @ARGV >= 1;
$datfn = shift(@ARGV);
$cdffn = $datfn;
$cdffn =~ s/\.dat/\.cdf/g;

$mode = @ARGV ? shift(@ARGV) : -1;
@wtimes = `cat $datfn | awk '{print \$2}' | sort -n`;
$nr_wtimes = @wtimes;
open OFD, ">$cdffn" or die "Error: file open error ($cdffn)\n";

foreach $wtime (@wtimes) {
        chomp($wtime);
        $i++;

        printf OFD "$wtime\t%.4lf\n", $i / $nr_wtimes;
}
