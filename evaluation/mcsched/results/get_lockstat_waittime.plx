#!/usr/bin/perl -w

die "$0 <result file> [threshold(=95%)]\n" unless @ARGV;
$res_fn = shift(@ARGV);
$threshold = @ARGV ? shift(@ARGV) : 95;
open FD, $res_fn or die "file open error: $res_fn\n";
while(<FD>) {
        last if (/^start_stat/);
        $start = 1 if /^lock_stat/;
        if ($start && /:/) {
                s/^\s+//g;
                @stat = split(/\s+/);
                $lock_name = $stat[0];
                next if $lock_name =~ /sem-[WR]/;
                $lock_name =~ s/://g;
                $lock_name =~ s/\/\d+$//g;
                $wait_time{$lock_name} += $stat[5];
                $total_wait_time += $stat[5];
        }
}
foreach $lock_name (sort {$wait_time{$b} <=> $wait_time{$a}} keys %wait_time) {
        $cumulative_wait_time += $wait_time{$lock_name};
        printf ("$lock_name\t%.2lf\n", $wait_time{$lock_name} * 100 / $total_wait_time);
        last if ($cumulative_wait_time * 100 / $total_wait_time) > $threshold;
}
