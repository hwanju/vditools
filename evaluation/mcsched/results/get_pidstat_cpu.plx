#!/usr/bin/perl -w

print "#sec\tsystem(%)\tuser(%)\tguest(%)\n";
while(<>) {
        if(/kvm$/) {
                s/^\s+//g;
                @info = split(/\s+/);
                $start_time = $info[0] - 1 unless $start_time;
                $first_pid = $info[1] if !defined($first_pid);
                if ($first_pid == $info[1]) {
                        printf "%d\t$info[3]\t$info[2]\t$info[4]\n", $info[0] - $start_time;
                        $total += ($info[3] + $info[2] + $info[4]);
                        $n++;
                }
        }
}
printf "%.2lf\n", $total / $n;
