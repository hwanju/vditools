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
$plot_name1 = "$dir-parsec_normalized";
$plot_name2 = "$dir-x264_slowdown";
open OFD, ">$plot_name.dat";
open OFD1, ">$plot_name1.dat";
open OFD2, ">$plot_name2.dat";
$slowdown_idx = 2;
$slowdown_step = 4;
$plot = "'$plot_name.dat'";
$plot1 = "'$plot_name1.dat'";
$plot2 = "'$plot_name2.dat'";

$plot_first = 1;
@fill_map = ("fs solid 0.05", "fs pattern 2", "fs solid 0.45", "fs pattern 4", "fs solid 0.85", "fs pattern 6");
@title_map = ("Baseline", "Baseline+DelayedResched", "LC Balance", "LC Balance+DelayedResched", "LC Balance+Resched-DP");
#@fill_map = ("fs solid 0.05", "fs pattern 2", "fs solid 0.30", "fs pattern 4", "fs solid 0.65", "fs pattern 6", "fs solid 0.90", "fs pattern 8");
#@title_map = ("Baseline", "Baseline+DelayedResched", "Baseline+Unfairlock", "LC Balance", "LC Balance+DelayedResched", "LC Balance+Resched-DP", "LC Balance+Resched-DP+Unfairlock");
$idx = 0;
$max_slowdown = 0;
	
print OFD "# ";
print OFD1 "# ";
print OFD2 "# ";
foreach $mode (sort keys %{$sum{"streamcluster"}}) {
	printf OFD "$mode\t";
	printf OFD1 "$mode\t";
	printf OFD2 "$mode\t";
}
print OFD "\n";
print OFD1 "\n";
print OFD2 "\n";

foreach $workload (sort keys %sum) {
	$workload_name = $workload;
	$workload_name =~ s/^\w+\+//g unless (defined($solorun_time{$workload_name}));
	printf OFD "%-15s", $workload_name;
	printf OFD1 "%-15s", $workload_name if $workload_name ne "x264(UP)"; 
	printf OFD2 "%-15s", $prev_workload_name if $workload_name eq "x264(UP)";
	foreach $mode (sort keys %{$sum{$workload}}) {
		$nr_samples = $n{$workload}{$mode};
		$avg = $sum{$workload}{$mode} / $nr_samples;
		$sd = sqrt(($sqsum{$workload}{$mode} / $nr_samples) - ($avg * $avg));
		$slowdown = $avg / $solorun_time{$workload_name};
		printf OFD "%-8.2lf%-8.2lf%-6.2lf%-3d\t", $slowdown, $avg, $sd, $nr_samples;
		printf OFD1 "%-8.2lf\t", $avg if $workload_name ne "x264(UP)";
		printf OFD2 "%-8.2lf\t", $slowdown if $workload_name eq "x264(UP)";
		$max_slowdown = $slowdown if $slowdown > $max_slowdown;

		if ($plot_first) {
			$plot .= ", ''" unless $mode eq "baseline";
			$plot1 .= ", ''" unless $mode eq "baseline";
			$plot2 .= ", ''" unless $mode eq "baseline";

			$plot .= " u $slowdown_idx:xtic(1) t \"$title_map[$idx]\" $fill_map[$idx] lt 1";

			$subidx = $idx + 2;
			$plot1 .= " u ( \$$subidx / \$2 ):xtic(1) t \"$title_map[$idx]\" $fill_map[$idx] lt 1";
			$plot2 .= " u $subidx:xtic(1) t \"$title_map[$idx]\" $fill_map[$idx] lt 1";

			$slowdown_idx += $slowdown_step;
			$idx++;
		}
	}
	$plot_first = 0;
	print OFD "\n";
	print OFD1 "\n" if $workload_name ne "x264(UP)";
	print OFD2 "\n" if $workload_name eq "x264(UP)";
	if ($workload_name =~ /UP/) {
		printf OFD "\"\" 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n";
	}
	$prev_workload_name = $workload_name;
}
close OFD;
#print "$plot\n";
$max_slowdown += 0.5;
$max_slowdown = 4 if $max_slowdown > 4;
open OFD, ">$plot_name.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 22
set output '$plot_name.eps'
set size 2.4,1
set key reverse right box Left outside horizontal width -1
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
set label \"A workload mix\" at -0.95, 2.2
#set style arrow 1 head nofilled ls 1 
set arrow from 0.5, 2 to 0, 1.7
set arrow from 0.5, 2 to 1, 1.7
set style data histograms
set style histogram 
#set style histogram cluster gap 1
set grid y
set boxwidth 1
plot $plot #, const,t t '' lt 2 lw 4
";
close OFD;

system("gnuplot $plot_name.plt");

open OFD, ">$plot_name1.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 24
set output '$plot_name1.eps'
set size 1.5,1
set key reverse right box Left outside width -1
set xlabel 'The workloads of SMP VM'
set ylabel 'Normalized execution time' 
set xrange [-0.5:1.7]
set yrange [0:1]
#set parametric
#set xtics 0,10
set xtics nomirror
#set xtic rotate by -45
#set ytics 0,20
set ytics nomirror
set style data histograms
set style histogram 
#set style histogram cluster gap 1
set grid y
set boxwidth 1
plot $plot1 
";
close OFD;

system("gnuplot $plot_name1.plt");

open OFD, ">$plot_name2.plt";
print OFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 22
set output '$plot_name2.eps'
set size 1.5,1
set key reverse right box Left outside horizontal width -1
set xlabel 'The workloads of SMP VM (corunning workloads of UP VMs)'
set ylabel 'Slowdown (relative to solorun)' 
#set xrange [-1:38]
set yrange [0:1.5]
#set parametric
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
plot $plot2 
";
close OFD;

system("gnuplot $plot_name2.plt");
