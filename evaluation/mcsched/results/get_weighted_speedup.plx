#!/usr/bin/perl -w

die "Usage: $0 <solorun dat>\n" unless @ARGV == 1;
$solorun_fn = shift(@ARGV);
open FD, $solorun_fn or die "file open error: $solorun_fn\n";
while(<FD>) {
	$solorun_time{$1} = $2 if (/(\w+)\s+(\d+)/);
	$solorun_time{$1 . "1"} = $2 if (/(\w+)\s+(\d+)/);
	$solorun_time{$1 . "2"} = $2 if (/(\w+)\s+(\d+)/);
}
close FD;

@res_files = `ls *.result`;
foreach $res_file (@res_files) {
        if ( $res_file =~ /1(\w+)\+1(\w+)@(\w+)/ ) {
                $w1 = $1;
		$w2 = $2;
		$identical = $w1 eq $w2;
                $mode = $3;

		$c1 = $w1 eq "raytrace" ? "rtview" : $w1;

                chomp($res_file);
                open FD, $res_file;
		for $w ($w1, $w2) { $total{$w} = $last{$w} = $n{$w} = 0 }
                while(<FD>) {
			$guest_id = $1 if (/^Guest(\d+)/);
			if (/Command being/) {
				if (/$c1/)	{ $w = $w1 }
				else		{ $w = $w2 }
				$w .= $guest_id if $identical;
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
				$total{$w} += $sec;
				$last{$w} = $sec;
				$n{$w}++;
                        }
                }
                close FD;
		if ($identical) {
			$w1 = $w1 . "1";
			$w2 = $w2 . "2";
		}
		$w = $n{$w1} > $n{$w2} ? $w1 : $w2;
		$total{$w} -= $last{$w};
		$n{$w}--;
		## print "$w1: total=$total{$w1} n=$n{$w1}\n";
		## print "$w2: total=$total{$w2} n=$n{$w2}\n";

		$wname = "$w1+$w2";
		$avg{$wname}{$mode}[0] = $n{$w1} ? $total{$w1} / $n{$w1} : 0;
		$avg{$wname}{$mode}[1] = $n{$w2} ? $total{$w2} / $n{$w2} : 0;
		$mode_map{$mode} = 1;
        }
}

printf "%-30s";
foreach $mode (sort keys %mode_map) {
        print "$mode\t";
}
print "\n";
foreach $wname (sort keys %avg) {
	printf "%-30s", $wname;
	($w1, $w2) = split(/\+/, $wname);
	foreach $mode (sort keys %{$avg{$wname}}) {
		$w1_speedup = $avg{$wname}{$mode}[0] ? $solorun_time{$w1} / $avg{$wname}{$mode}[0] : 0;
		$w2_speedup = $avg{$wname}{$mode}[1] ? $solorun_time{$w2} / $avg{$wname}{$mode}[1] : 0;
		$weigted_speedup = $w1_speedup + $w2_speedup;
		##printf "%d(=%d+%d)\t", $avg{$wname}{$mode}[0] + $avg{$wname}{$mode}[1], $avg{$wname}{$mode}[0], $avg{$wname}{$mode}[1];
		printf "%.2lf(=%.2lf+%.2lf)\t", $weigted_speedup, $w1_speedup, $w2_speedup;
	}
	print "\n";
}
