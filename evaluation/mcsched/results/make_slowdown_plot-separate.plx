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

		if ($workload_fmt =~ /(\d+)(\w+)\+(\d+)(\w+)/) {
			$id = 1;
			for (1 .. $1) {
				$workload_name[$id++] = $2;
			}
			for (1 .. $3) {
				$name = "$2+$4";
				$name .= "(UP)" if $4 eq "x264";		# NOTE: x264 corunner is only used as UP VM
				$workload_name[$id++] = $name;
			}
		}
                while(<FD>) {
			if (/VM(\d+) workload iterations: (\d+)\/(\d+)/) {
				$guest_id = $1;
				$total_iter[$guest_id] = $2;
				$min_iter = $3;
				next;
			}
			if (/^Guest(\d+)/) {
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

				$sum{$workload_name[$guest_id]}{$mode} += $sec;
				$sqsum{$workload_name[$guest_id]}{$mode} += ($sec * $sec);
				$n{$workload_name[$guest_id]}{$mode}++;
				$nr_iter[$guest_id]++;

				#if ($workload_fmt eq "1canneal+4x264" && $mode eq "fairbal_pct100-1:500000:18000000:1:0:0") {
				#	print "g$guest_id: $1 -> $sec - nr_iter=$nr_iter[$guest_id] sum=$sum{$workload_fmt}{$mode}{$guest_id} total_iter=$total_iter[$guest_id] min_iter=$min_iter\n";
				#}
                        }
                }
                close FD;
	}
}

$plot_name = "$dir-slowdown";
open OFD, ">$plot_name.dat";
$slowdown_idx = 2;
$slowdown_step = 4;
$plot = "'$plot_name.dat'";
$plot_first = 1;
@fill_map = ("fs solid 0.05", "fs pattern 2", "fs solid 0.45", "fs pattern 4", "fs solid 0.85", "fs pattern 6");
@title_map = ("Baseline", "Balance", "LC Balance", "LC Balance+Resched-DP", "LC Balance+Resched-DP+TLB-Co", "LC Balance+Resched-DP+TLB-Co+Resched-Co");
$idx = 0;
$max_slowdown = 0;
foreach $workload (sort keys %sum) {
	$workload_name = $workload;
	$workload_name =~ s/^\w+\+//g unless (defined($solorun_time{$workload_name}));
	printf OFD "%-15s", $workload_name;
	foreach $mode (sort keys %{$sum{$workload}}) {
		$nr_samples = $n{$workload}{$mode};
		$avg = $sum{$workload}{$mode} / $nr_samples;
		$sd = sqrt(($sqsum{$workload}{$mode} / $nr_samples) - ($avg * $avg));
		$slowdown = $avg / $solorun_time{$workload_name};
		printf OFD "%-8.2lf%-8.2lf%-6.2lf%-3d\t", $slowdown, $avg, $sd, $nr_samples;
		$max_slowdown = $slowdown if $slowdown > $max_slowdown;

		if ($plot_first) {
			$plot .= ", ''" unless $mode eq "baseline";
			$plot .= " u $slowdown_idx:xtic(1) t \"$title_map[$idx]\" $fill_map[$idx] lt 1";
			$slowdown_idx += $slowdown_step;
			$idx++;
		}
	}
	$plot_first = 0;
	print OFD "\n";
	if ($workload_name =~ /UP/) {
		printf OFD "\"\" 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n";
	}
}
close OFD;
#print "$plot\n";
$max_slowdown += 0.5;
$max_slowdown = 4 if $max_slowdown > 4;
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 23
set output '$plot_name.eps'
set size 3,1
set key reverse right box Left horizontal width -1
set ylabel 'Slowdown (relative to solorun)' 
set xrange [-1:38]
set yrange [0:$max_slowdown]
#set parametric
const=12.6
#set xtics 0,10
set xtics nomirror
set xtic rotate by -45
#set ytics 0,20
set ytics nomirror
set style data histograms
set style histogram 
#set style histogram cluster gap 1
set grid y
set boxwidth 1
plot $plot #, const,t t '' lt 2 lw 4
";
close OFD;

system("gnuplot $plot_name.plt");
