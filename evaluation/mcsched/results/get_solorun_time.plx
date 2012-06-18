#!/usr/bin/perl -w

@res_files = `ls *.result`;
foreach $res_file (@res_files) {
        if ( $res_file =~ /^1(\w+)/ ) {
                $workload = $1;

                chomp($res_file);
                $total = $n = 0;
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
				$n++;
                        }
                }
                close FD;
		printf ("$workload\t%d\n", $total / $n);
        }
}
