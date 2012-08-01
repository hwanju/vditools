#!/usr/bin/perl -w

$filter = @ARGV ? shift(@ARGV) : "";

@res_files = `ls *$filter*.result`;
foreach $res_file (@res_files) {
        if ( $res_file =~ /^1(\w+)\@(.+)\./ ) {
                $workload = $1;
		$mode = $2;

                chomp($res_file);
                $total = $sqtotal = $n = 0;
                open FD, $res_file;
                while(<FD>) {
                        if (/Elapsed.+: ([0-9:]+)/) {
                                @times = split(/:/, $1);
                                $nr_times = int(@times);
                                if ($nr_times == 2) {
                                        $sec = $times[0] * 60 + $times[1];
                                }
                                elsif ($nr_times == 3) {
                                        $sec = $times[0] * 3600 + $times[1] * 60 + $times[2];
                                }
				$total += $sec;
				$sqtotal += ($sec*$sec);
				$n++;
                        }
                }
                close FD;
		if ($n) {
			$avg = $total / $n;
			$sd = sqrt(($sqtotal / $n) - ($avg*$avg));
		}
		else { $avg = $sd = 0 }
		$up = $mode =~ /-up/ ? "(UP)" : "";
		printf ("$workload$up\t%d\t%.2lf\n", $avg, $sd);
        }
}
