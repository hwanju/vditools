#!/usr/bin/perl -w

while(<>) {
        if (/(\d+) WT (\d+) (\d+) \d+ \d+ \d+ \d+ \d+ ipi=1/) {
                $sched_time{$2}{$3} = $1;
        }
        elsif (/\d+ VA (\d+) (\d+)/) {
                $hlt{$1}{$2} = 0;
        }
        elsif (/\d+ HLT (\d+) (\d+)/) {
                $hlt{$1}{$2} = 1;
        }
        elsif (/(\d+) VD (\d+) (\d+) \d+ (\d+)/) {
                if($sched_time{$2}{$3} && !$hlt{$2}{$3} && $4) {
                        $lat = $1 - $sched_time{$2}{$3};
                        if ($lat < 100) {
                                print ("$1: $lat\n");
                        }
                }
                $sched_time{$2}{$3} = 0;
        }
}
