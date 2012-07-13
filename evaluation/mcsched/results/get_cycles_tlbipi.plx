#!/usr/bin/perl -w

$dir = @ARGV ? shift(@ARGV) : ".";
@flist = `ls $dir/*.guest.perf`;

foreach $f (@flist) {
        chomp($f);
        open FD, $f;
        $sum = 0;
        while(<FD>) {
                if(/native_flush_tlb_others/ ||
		   /__bitmap_empty/) {
                        @cols = split(/\s+/);
                        $pct = $cols[1];
                        $pct =~ s/%//g;
                        $sum += $pct;
                }
        }
        close FD;
	$f =~ s/\.guest\.perf$//g;
        print "$f\t$sum\n";
}
