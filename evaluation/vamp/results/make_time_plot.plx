#!/usr/bin/perl -w

die "Usage: $0 [-m <1:mixed in vm or 2:mixed out of vm>] <plot desc file> <stat name (e.g., avg, max>\n" unless @ARGV >= 2;
$mixed = 0;
if ($ARGV[0] eq "-m") {
	shift(@ARGV);
	$mixed = shift(@ARGV);
	die "Error: invalid mixed mode\n" unless $mixed == 1 || $mixed == 2;
}
$fn = shift(@ARGV);
$stat = shift(@ARGV);
$stat = "avg" if $mixed;	# mixed workloads support only avg
$name = $fn;
$name =~ s/\.desc//g;
$name .= "-$stat";
$name .= $mixed == 1 ? "-intra_mixed" : "-inter_mixed" if $mixed;

open FD, $fn or die "file open error: $fn\n";
open OFD, ">$name.dat";
$plot_cmd = "plot";
$set_xtic = "set xtic (";
$set_labels = "";
$app_idx = 0;
$line = 0;
$ymax = 1.4;
if ($mixed == 1) {
	$set_xlabel = "set xlabel 'Corunning workloads in the same VM'";
	$set_ylabel = "set ylabel 'Normalized execution time";
}
elsif ($mixed == 2) {
	$set_xlabel = "set xlabel 'Corunning workloads in another VM'";
	$set_ylabel = "set ylabel 'Normalized execution time";
}
else {
	$set_xlabel = "set xlabel 'Interactive workloads'";
	$set_ylabel = "set ylabel 'Normalized launch time";
}
while(<FD>) {
	next if substr($_, 0, 1) eq "#";
	$line++;

	if ($line == 1) {
		@modes = split(/\s+/);
	}
	elsif ($line == 2) {
		@plot_titles = split(/\s+/);
		foreach $i (0 .. int(@plot_titles) - 1) {
			$plot_titles[$i] =~ s/_/ /g;
		}
		foreach $t (@plot_titles) {
			$t =~ s/_/ /g;
		}
		printf OFD "%-50s", "# workloads";
		$base_idx = 2;
		$i = 0;
		foreach $mode (@modes) {
			printf OFD "%-20s", "$stat($mode)";
			printf OFD "%-18s", "sd($mode)" if $stat eq "avg";
			$plot_cmd .= "," if $i > 0;
			$solid = $i * 0.20 + 0.10;
			if ($stat eq "avg") {
				$avg_idx = $i * 2 + $base_idx;
				$sd_idx  = $i * 2 + $base_idx + 1;
				$plot_cmd .= " '$name.dat' u (\$$avg_idx / \$$base_idx):(\$$sd_idx / \$$base_idx) t '$plot_titles[$i]' lt 1 fs solid $solid";
			}
			else {
				$idx = $i + $base_idx;
				$plot_cmd .= " '$name.dat' u (\$$idx / \$$base_idx) t '$plot_titles[$i]' lt 1 fs solid $solid";
			}
			$i++;
		}
		print OFD "\n";
	}
	else {
		($prefix, $xtic) = split(/\s+/);
		$xtic = "w/ $xtic" if $mixed;
		$set_xtic .= ", " if $app_idx > 0;
		$set_xtic .= "'$xtic' $app_idx";
		printf OFD "%-50s", $prefix;
		print "$prefix\n";
		$i = 0;
		foreach $mode (@modes) {
			if ($mixed) {
				$rawfn = "$prefix-$mode.result";
				if (!defined($nr_iter)) {
					$nr_iter = `grep iterations $rawfn | head -1 | cut -d/ -f2`;
					chomp($nr_iter);
				}
				if ($mixed == 1) {
					$stat_all=`./get_avg_time.plx $rawfn $nr_iter 1`;
				}
				else {
					$stat_all=`./get_avg_time.plx $rawfn $nr_iter -1`;
				}
			}
			else {
				$mult = $prefix =~ /launch/ ? 2 : 1;
				$rawfn = "$prefix-$mode.latency";
				$resfn = "$prefix-$mode.time";
				`./get_latency.plx $rawfn $mult > $resfn`;
				$stat_all = `tail -1 $resfn`;
			}
			print "\t$mode: $stat_all";
			$val = $1 if ($stat_all =~ /$stat=(\d+\.\d+)/);
			$sd  = $1 if ($stat_all =~ /sd=(\d+\.\d+)/);
			printf OFD "%-20.2lf", $val;
			printf OFD "%-18.2lf", $sd if $stat eq "avg";

			if ($i == 0) {
				$time_sec = $mixed ? $val : $val / 1000;
				if ($mixed) {
					$set_labels .= sprintf("set label '%ds' at %.2lf,1.07\n", $time_sec, $app_idx - (int(@modes) / 2 * 0.15));
				}
				else {
					$set_labels .= sprintf("set label '%.1lfs' at %.2lf,1.05\n", $time_sec, $app_idx - (int(@modes) / 2 * 0.15));
				}
			}
			$i++;
		}
		print OFD "\n";
		print "\n";
		$app_idx++;
	}
}
if ($stat eq "avg") {
	$set_errorbars = "set style histogram errorbars lw 2\n" if $stat eq "avg";
}
else {
	$set_errorbars = "";
}
$set_xtic .= ")";
$app_idx -= 0.5;
open PFD, ">$name.plt";
print PFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 20
set output '$name.eps'
set key reverse left Left width -1
$set_labels
$set_xlabel
$set_ylabel
set xrange [-0.5:$app_idx]
set yrange [0:$ymax]
#set xtics 0,10
set xtics nomirror
#set xtic rotate by -45
#set ytics 0,0.1
set ytics nomirror
set style data histograms
#set style fill solid 1.0
set style histogram
$set_errorbars
set grid y
set boxwidth 0.85
$set_xtic
$plot_cmd
";
close PFD;

system("gnuplot $name.plt");
