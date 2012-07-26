#!/usr/bin/perl -w

die "Usage: $0 <dir>\n" unless @ARGV == 1;
$dir = shift(@ARGV);
$dir =~ s/\/$//;
$solorun_fn = "solorun_time.dat";
open FD, $solorun_fn or die "file open error: $solorun_fn\n";
while(<FD>) {
	($workload, $avg) = split(/\s+/);
	$solorun_time{$workload} = $avg;
}
close FD;

@res_files = `ls $dir/*.result`;
#@res_files = ("1streamcluster+4x264\@fairbal_pct100.result");
foreach $res_file (@res_files) {
        if ( $res_file =~ /(.+)@(.+)\.result/ ) {
		$workload_fmt = $1;
		$mode = $2;
		$workload_fmt =~ s/^.+\///g;
                chomp($res_file);
                open FD, $res_file;

		$mode = "baseline-balance" if $mode eq "purebal";	# for sorting!

                while(<FD>) {
			if (/VM(\d+) workload iterations: (\d+)\/(\d+)/) {
				$guest_id = $1;
				$total_iter[$guest_id] = $2;
				$min_iter = $3;
				next;
			}
			if (/Guest(\d+):/) {
				$guest_id = $1;
				$nr_iter[$guest_id] = 0;
			}
                        if (/Elapsed.+: ([0-9:]+)/) {
				next if ($nr_iter[$guest_id] >= $min_iter && $nr_iter[$guest_id] >= $total_iter[$guest_id] - 1);
                                @times = split(/:/, $1);
                                $nr_times = int(@times);
                                if ($nr_times == 2) {
                                        $sec = $times[0] * 60 + $times[1];
                                }
                                elsif ($nr_times == 3) {
                                        $sec = $times[0] * 3600 + $times[1] * 60 + $times[2];
                                }

				$sum{$workload_fmt}{$mode}{$guest_id} += $sec;
				$sqsum{$workload_fmt}{$mode}{$guest_id} += ($sec * $sec);
				$n{$workload_fmt}{$mode}{$guest_id}++;
				$nr_iter[$guest_id]++;

				#if ($workload_fmt eq "1canneal+4x264" && $mode eq "fairbal_pct100-1:500000:18000000:1:0:0") {
				#	print "g$guest_id: $1 -> $sec - nr_iter=$nr_iter[$guest_id] sum=$sum{$workload_fmt}{$mode}{$guest_id} total_iter=$total_iter[$guest_id] min_iter=$min_iter\n";
				#}
                        }
                }
                close FD;
	}
}
$nr_guests = $guest_id;

$plot_name = "$dir-weighted-speedup";
open OFD, ">$plot_name.dat";
printf OFD "%-30s%-45s", "#workload_mix", "mode";
$lab_start = 2;
$lab_step  = 6;
$x = $lab_start;
$speedup_idx = 3;
$speedup_step = 4;
$xtics = "set xtics (";
$plot = "'$plot_name.dat'";
$plot_first = 1;
@fill_map = ("", "fs solid 0.70", "fs solid 0.15", "fs solid 0.15", "fs solid 0.15", "fs solid 0.15");
@label_map = ("a", "b", "c", "d", "e");
$label_idx = 0;
$label_cmd = "";
foreach $workload_fmt (sort keys %sum) {
	if ($workload_fmt =~ /(\d+)(\w+)\+(\d+)(\w+)/) {
		$guest_id = 1;
		for (1 .. $1) {
			$workload_name[$guest_id++] = $2;
			printf OFD "%-21s\t", $workload_name[$guest_id - 1] if $x == $lab_start;
		}
		for (1 .. $3) {
			$name = $4;
			$name .= "(UP)" if $4 eq "x264";		# NOTE: x264 corunner is only used as UP VM
			$workload_name[$guest_id++] = $name;
			printf OFD "%-21s\t", $workload_name[$guest_id - 1] if $x == $lab_start;
		}
		print OFD "\n" if $x == $lab_start;
		$xtics .= ", " unless $x == $lab_start;
		$xtics .= "\"$workload_name[1]\" $x";
		$x += $lab_step;
	}
	foreach $mode (sort keys %{$sum{$workload_fmt}}) {
		printf OFD "%-30s%-55s", $workload_fmt, $mode;
		$weighted_speedup = 0;
		foreach $guest_id (sort {$a <=> $b} keys %{$sum{$workload_fmt}{$mode}}) {
			$nr_samples = $n{$workload_fmt}{$mode}{$guest_id};
			$avg = $sum{$workload_fmt}{$mode}{$guest_id} / $nr_samples;
			$sd = sqrt(($sqsum{$workload_fmt}{$mode}{$guest_id} / $nr_samples) - ($avg * $avg));
			$speedup = $solorun_time{$workload_name[$guest_id]} / $avg;
			$weighted_speedup += $speedup;
			printf OFD "%-5.2lf%-7.2lf%-6.2lf%-3d\t", $speedup, $avg, $sd, $nr_samples;
			if ($plot_first) {
				$plot .= ", ''" unless $guest_id == 1;
				$title = $guest_id == 1 ? "Main workload (at X-axis)" : "Corunner ($workload_name[$guest_id])";
				$plot .= " u $speedup_idx t \"$title\" $fill_map[$guest_id] lt 1";
				$speedup_idx += $speedup_step;
			}
			if ($workload_fmt =~ /1blackscholes/ && $guest_id != 1) {
				$label_xpos = $label_idx - 0.5;
				$label_ypos = $weighted_speedup + 0.07;
				$label_cmd .= "set label '$label_map[$label_idx]' at $label_xpos, $label_ypos\n";
				$label_idx++;
			}

		}
		$plot_first = 0;
		print OFD "\n";
	}
	
	printf OFD "%-30s%-55s", "blank", "blank";
	for (1 .. $nr_guests) {
		printf OFD "%-5.2lf%-7.2lf%-6.2lf%-3d\t", 0, 0, 0, 0;
	}
	print OFD "\n";
}
close OFD;
$xtics .= ")";
#print "$xtics\n";
#print "$plot\n";
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 22
set output '$plot_name.eps'
set size 1.4,1
set key invert reverse left box Left width -1
set ylabel 'Weighted speedup' 
set yrange [0:2.1]
#set xtics 0,10
set xtics nomirror
set xtic rotate by -45
$xtics
$label_cmd
#set ytics 0,20
set ytics nomirror
set style data histograms
set style histogram rowstacked
set grid y
set boxwidth 0.60
plot $plot
";
close OFD;

system("gnuplot $plot_name.plt");
