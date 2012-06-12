#!/usr/bin/perl -w

@res_files = `ls *.result`;
foreach $res_file (@res_files) {
        if ( $res_file =~ /\d+(\w+).*@(\w+)/ ) {
                $workload = $1;
                $mode = $2;
		$cmd = $workload eq "raytrace" ? "rtview" : $workload;

                chomp($res_file);
		$main = 0;
                $total = $sqtotal = $n = 0;
		$corun_total = $corun_n = 0;
                open FD, $res_file;
                while(<FD>) {
			if (/Command being/) {
				if (/$cmd/ && !$main)	{ $main = 1 }
				else			{ $main = 0 }
			}
                        if (/Elapsed.+: ([0-9:]+)/) {
                                @times = split(/:/, $1);
                                $nr_times = int(@times);
                                if ($nr_times == 2) {
                                        $sec = $times[0] * 60 + $times[1];
                                }
                                elsif ($nr_times == 3) {
                                        $sec = $times[0] * 3600 + $times[1] * 60 + $times[2];
                                }
				if ($main) {
					$total += $sec;
					$sqtotal += ($sec * $sec);
					$n++;
				}
				else {
					$corun_total += $sec;
					$corun_n++;
				}
                        }
                }
                close FD;
                $avg = $n ? $total / $n : 0;
                #$sd = sqrt(($sqtotal / $n) - ($avg * $avg));
                $avg_time{$workload}{$mode} = $avg;

		$avg = $corun_n ? $corun_total / $corun_n : 0;
                $corun_avg_time{$workload}{$mode} = $avg;
        }
}

#@mode_list = ("baseline", "purebal", "purebal_mig", "fairbal_pct0", "fairbal_pct150", "fairbal_pct100");
@mode_list = ("baseline", "purebal", "purebal_mig", "fairbal_pct100", "fairbal_pct150", "fairbal_pct200", "fairbal_pct250", "fairbal_pct300");
foreach $mode (@mode_list) {
        print "\t$mode";
}
print "\n";
foreach $workload ( sort keys %avg_time) {
        print "$workload";
        foreach $mode (@mode_list) {
                if ($avg_time{$workload}{$mode}) {
                        printf "\t%d", $avg_time{$workload}{$mode};
                }
                else {
                        print "\t0";
                }

                if ($corun_avg_time{$workload}{$mode}) {
                        printf " (%d)", $corun_avg_time{$workload}{$mode};
                }
        }
        print "\n";
}
