#!/usr/bin/perl -w

foreach $dat_fn (@ARGV) {
        open FD, $dat_fn or next;
        $line = 0;
        while(<FD>) {
                $line++;
                next if $line == 1 || $line == 2;
                @cols = split( /\s+/ );
                $epoch = $cols[0];
                $ptime = $cols[1];
                $vtime = $cols[2];
                $ttime = 0;
                for ($i = 3; $i < int(@cols); $i++) {
                        $ttime += $cols[$i];
                }

                printf "$dat_fn:$line(epoch=$epoch) [VCPU] vcpu time($vtime) > ptime($ptime) (diff=%dns, %dms)\n", 
                        $vtime - $ptime, ($vtime - $ptime) / 1000000 if $vtime > $ptime;
                printf "$dat_fn:$line(epoch=$epoch) [TASK] vcpu time($vtime) %s total time of guest threads($ttime) (diff=%dns, %dms)\n",
                        $vtime > $ttime ? ">" : "<", abs($vtime - $ttime), abs($vtime - $ttime) / 1000000 if $vtime != $ttime;
        }
}
