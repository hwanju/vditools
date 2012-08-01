#!/usr/bin/perl -w

die "Usage: $0 <dir (e.g., _1parsrc+4x264>\n" unless @ARGV;
$dir = shift(@ARGV);
$dir =~ s/\/$//g;

@tlbipi_cycles = `./get_cycles_tlbipi.plx $dir`;
@spinlock_cycles = `./get_cycles_spinlock.plx $dir`;
$i = -1;
foreach $line (@tlbipi_cycles) {
	$i++;
	($conf, $cycle) = split(/\s+/, $line);
	$base_conf = `basename $conf`;
	$urgent_tslice = $1 if ($base_conf =~ /\d+:(\d+):\d+:\d+:\d+:\d+/);
	if ($base_conf =~ /1(\w+)\+.+\@(.+)-perf/) {
		$workload = $1;
		$mode = $2;
	}
	else { next }
	if ($mode eq "baseline") {
		$mode = "Baseline";
	}
	elsif ($mode eq "fairbal_pct100-0:0:0:0:0:0") {
		$mode = "LC Balance";
	}
	elsif ($mode eq "fairbal_pct100-1:500000:18000000:1:500000:0") {
		$mode = "LC Balance+Resched-DP+TLB-Co";
	}
	else { next }

	$tlb{$workload}{$mode} = $cycle;
	$total_cycles = $cycle;

	($conf, $cycle) = split(/\s+/, $spinlock_cycles[$i]);
	$spinlock{$workload}{$mode} = $cycle;
	$total_cycles += $cycle;

	$res_file = $conf;
	$res_file =~ s/-perf//g;
	$res_file .= ".result";
	$iter_info = `grep VM1 $res_file | tail -n1`;
	@tmp = split(/\s+/, $iter_info);
	$iter_pair = $tmp[-1];
	($iter, $global_iter) = split(/\//, $iter_pair);
	$iter-- if $iter > $global_iter;

	$res = `./get_avg_time.plx $res_file $iter 1`;
	($avg, $sd) = split(/\s+/, $res);
	$avg_time{$workload}{$mode} = $avg;
	$sd_time{$workload}{$mode} = $sd;

	$max_avg{$workload} = $avg if !defined($max_avg{$workload}) || $avg > $max_avg{$workload};
	$max_cycles{$workload} = $total_cycles if !defined($max_cycles{$workload}) || $total_cycles > $max_avg{$workload};

	print "$res_file: $iter_pair --> $iter / $global_iter --> avg=$avg sd=$sd\n";
}

foreach $workload (keys %tlb) {
	$label = $dir;
	$label =~ s/-ple//g;
	$plot_name = "$label-$workload-ple";
	open OFD, ">$plot_name.dat";
	print OFD "#Mode\tTLB cycles\tSpinlock cycles\tAvg Time\tSd Time\n";
	$i = 0;
	$xtics = "set xtics (";
	foreach $mode (sort keys %{$tlb{$workload}}) {
		$xtic = $mode;
		$xtic =~ s/\+/\\n\+/g;
		$xtics .= ", " unless $i == 0;
		$xtics .= "\"$xtic\" $i";
		$label = $mode;
		$label =~ s/\s+/_/g;
		printf OFD "%s\t%.2lf\t%.2lf\t%d\t%.2lf\t%.2lf\n", 
			$label, 
			$tlb{$workload}{$mode}, $spinlock{$workload}{$mode}, 
			$i++, $avg_time{$workload}{$mode} / $avg_time{$workload}{"Baseline"}, 
			$sd_time{$workload}{$mode} / $avg_time{$workload}{"Baseline"};
	}
	close OFD;
	$xtics .= ")";
	$xmargin = 0.3;
	$i -= (1 - $xmargin);
	$max_avg{$workload} /= $avg_time{$workload}{"Baseline"};
	$max_avg{$workload} += 0.35;
	$max_cycles{$workload} += 5;
	open OFD, ">$plot_name.plt";
	print OFD "
	set terminal postscript eps enhanced monochrome
	set terminal post 'Times-Roman' 25
	set output '$plot_name.eps'
	#set size 0.95,1
	set bmargin 3.5
	set key invert reverse left Left width -1
	set ylabel 'Normalized average execution time' 
	set y2label 'CPU cycles (%)' 
	set xrange [-$xmargin:$i]
	set yrange [0:$max_avg{$workload}]
	set y2range [0:$max_cycles{$workload}]
	#set xtics 0,10
	set xtics nomirror
	#set xtic rotate by -45
	$xtics
	#set ytics 0,20
	set ytics 0,0.2
	set ytics nomirror
	set y2tics 0,5
	set style data histograms
	set style histogram rowstacked
	set grid y
	set boxwidth 0.35
	plot '$plot_name.dat' u 2 t 'CPU cycles for TLB shootdown' fs solid 0.50 lt 1 axis x1y2, '' u 3 t 'CPU cycles for lock spinning' fs pattern 4 lt 1 axis x1y2, '' u 4:5:6 t 'Normalized execution time' w yerrorlines lt 1 pt 4 lw 2"; 
	close OFD;
	
	system("gnuplot $plot_name.plt");
}
