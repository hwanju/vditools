#!/usr/bin/perl -w

@res_files = `ls *.result`;
foreach $res_file (@res_files) {
        if ( $res_file =~ /\d+(\w+).*@(\w+)/ ) {
                $workload = $1;
                $mode = $2;
		$cmd = $workload eq "raytrace" ? "rtview" : $workload;

                chomp($res_file);
                $total = $sqtotal = $n = $do_calc = 0;
                open FD, $res_file;
                while(<FD>) {
			if (/Command being/) {
				if (/$cmd/) { $do_calc = 1 }
				else	    { $do_calc = 0 }
			}
                        if ($do_calc && /Elapsed.+: ([0-9:]+)/) {
                                @times = split(/:/, $1);
                                $nr_times = int(@times);
                                if ($nr_times == 2) {
                                        $sec = $times[0] * 60 + $times[1];
                                }
                                elsif ($nr_times == 3) {
                                        $sec = $times[0] * 3600 + $times[1] * 60 + $times[2];
                                }
                                $total += $sec;
                                $sqtotal += ($sec * $sec);
                                $n++;
                                #printf "$res_file: $1 %d\n", $sec;
                        }
                }
                close FD;
                $avg = $n ? $total / $n : 0;
                #$sd = sqrt(($sqtotal / $n) - ($avg * $avg));

                $avg_time{$workload}{$mode} = $avg;
        }
}

@mode_list = ("baseline", "purebal", "purebal_mig", "fairbal_pct0", "fairbal_pct110", "fairbal_pct100");
foreach $mode (@mode_list) {
        print "\t$mode";
}
print "\n";
foreach $workload ( sort keys %avg_time) {
        print "$workload";
        foreach $mode (@mode_list) {
                if ($avg_time{$workload}{$mode}) {
                        printf "\t%.2lf", $avg_time{$workload}{$mode};
                }
                else {
                        print "\t0";
                }
        }
        print "\n";
}
