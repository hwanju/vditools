#!/usr/bin/perl -w

@res_files = `ls *.result`;
print "#workload\tuser\tsys\tuser(%)\tsys(%)\ttime\n";
foreach $res_file (@res_files) {
        if ( $res_file =~ /^\d?([a-z0-9]+)/ ) {
                $p = $1;

                chomp($res_file);
                $n = $total = $total_user = $total_sys = 0;
                open FD, $res_file;
                while(<FD>) {
                        if (/User time \(seconds\): (\d+\.\d+)/) {
                                $total_user += $1;
                        }
                        elsif (/System time \(seconds\): (\d+\.\d+)/) {
                                $total_sys += $1;
                        }
                        elsif (/Elapsed.+: ([0-9:]+)/) {
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
                                #printf "$res_file: $1 %d\n", $sec;
                        }
                }
                close FD;
                $avg_user = $n ? $total_user / $n : 0;
                $avg_sys =  $n ? $total_sys / $n : 0;
                $avg_total = $avg_user + $avg_sys;

                $avg = $n ? $total / $n : 0;

                printf("$p\t$avg_user\t$avg_sys\t%.1lf\t%.1lf\t%.2lf\n", $avg_user * 100 / $avg_total, $avg_sys * 100 / $avg_total, $avg);
        }
}
