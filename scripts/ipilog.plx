#!/usr/bin/perl -w

die "Usage: $0 <log file> <latency file>\n" unless @ARGV == 2;
$logfn = shift(@ARGV);
$latfn = shift(@ARGV);
open LOGFD, $logfn or die "Error: file open error ($logfn)\n";
open LATFD, $latfn or die "Error: file open error ($latfn)\n";

$bin_us = 10000;        # 10ms
$start_time_us = `head -1 $logfn | awk '{print \$1}'`;
$end_time_us   = `tail -1 $logfn | awk '{print \$1}'`;
$total_time_us = $end_time_us - $start_time_us;
$nr_bins = $total_time_us / $bin_us;
#print "# total_time_us=$total_time_us nr_bins=$nr_bins\n";

$i = 0;
while(<LATFD>) {
        $lats[$i / 2] = int($_) if $i % 2 == 0;
        $i++;
}
foreach $lat (@lats) {
        print "$lat\n";
}
exit;

while(<LOGFD>) {
        if (/(\d+) UI \d+ \d+ \d+ id=(\d+)/) {
                $time_us = $1;
                $id = $2;
                if (!defined($input_start_us[$id])) {
                        $input_start_us[$id] = $time_us;
                }
        }
        if (/(\d+) D \d+ vec=([0-9a-f]+)/) {
                $time_us = $1 - $start_time_us;
                $vector = $2;
                $bid = int($time_us / $bin_us);

                $nr_ipis{$vector}{$bid}++;

                if ($id && $vector eq "e1") {
                }
        }
}

print "#";
foreach $vector (keys %nr_ipis) {
        print "\t$vector";
}
print "\n";

foreach $i (0 .. ($nr_bins - 1)) {
        print "$i";
        foreach $vector (keys %nr_ipis) {
                if (defined($nr_ipis{$vector}{$i})) {
                        print "\t$nr_ipis{$vector}{$i}";
                }
                else {
                        print "\t0";
                }
        }
        print "\n";
}
