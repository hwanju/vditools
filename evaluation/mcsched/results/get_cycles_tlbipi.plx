#!/usr/bin/perl -w

@flist = `ls *.guest.perf`;

foreach $f (@flist) {
        chomp($f);
        $workload = $1 if ($f =~ /1(\w+)/);
        $mode = $1 if ($f =~ /@(\w+)\.guest/);
        open FD, $f;
        $sum = 0;
        while(<FD>) {
                if(/native_flush_tlb_others/) {
                        @cols = split(/\s+/);
                        $pct = $cols[1];
                        $pct =~ s/%//g;
                        $sum += $pct;
                }
        }
        close FD;
        print "$workload\@$mode\t$sum\n";
}
