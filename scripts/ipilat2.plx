#!/usr/bin/perl -w

while(<>) {
        #$line++;
        if (/(\d+) PM (\d+) (\d+) ([0-9a-f]+)/) {
                if (!$ipi_pending_time{$2}{$3} && $4 ne "0") {
                        $ipi_pending_time{$2}{$3} = $1;
                        #print "$line: start $4\n";
                }
                elsif ($ipi_pending_time{$2}{$3} && $4 eq "0") {
                        #print "$line: end $4\n";
                        $lat = $1 - $ipi_pending_time{$2}{$3};
                        $total += $lat;
                        $n++;
                        $ipi_pending_time{$2}{$3} = 0;

                        if ($lat > 10000) {
                                print "$1: $2 $3 $lat\n";
                        }
                }
        }
}
printf ("avg=%d\n", $total / $n);
