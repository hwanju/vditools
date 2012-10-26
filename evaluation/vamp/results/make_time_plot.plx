#!/usr/bin/perl -w

die "Usage: $0 [-b: browse details | -m <1:mixed in vm or 2:mixed out of vm>] <plot desc file> <stat name (e.g., avg, max>\n" unless @ARGV >= 2;
$mixed = 0;
@browser_names = ("");
@browse_sites = ("");
if ($ARGV[0] eq "-m") {
	shift(@ARGV);
	$mixed = shift(@ARGV);
	die "Error: invalid mixed mode\n" unless $mixed == 1 || $mixed == 2;
}
elsif ($ARGV[0] eq "-b") {
	$browse_detail = shift(@ARGV);
	@browse_sites = qw( Amazon BBC CNN Craigslist eBay ESPN Google MSN Slashdot Twitter Average );
	@browser_names = ();
}
$fn = shift(@ARGV);
$stat = shift(@ARGV);
$stat = "avg" if $mixed;	# mixed workloads support only avg
$name = $fn;
$name =~ s/\.desc//g;
$name .= "-$stat";
$name .= $mixed == 1 ? "-intra_mixed" : "-inter_mixed" if $mixed;

open FD, $fn or die "file open error: $fn\n";
$set_xtic = "set xtic (";
$set_labels = "";
$set_size = "set size 1.3,1";
$app_idx = 0;
$line = 0;
$ymax = 1.6;
if ($mixed == 1) {
	$set_xlabel = "set xlabel 'Corunning applications in the same VM'";
	$set_ylabel = "set ylabel 'Normalized execution time";
}
elsif ($mixed == 2) {
	$set_xlabel = "set xlabel 'Corunning applications in another VM'";
	$set_ylabel = "set ylabel 'Normalized execution time";
}
else {
	$xlabel = "Interactive applications";
	$ylabel = "Normalized launch time";
	if ($name =~ /Browse/) {
		$xlabel = $browse_detail ? "Web sites" : "Web browser applications";
		$ylabel = "Normalized response time";
	}
	$set_xlabel = "set xlabel '$xlabel'";
	$set_ylabel = "set ylabel '$ylabel";
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
	}
	else {
		($prefix, $xtic) = split(/\s+/);
		$xtic = "w/ $xtic" if $mixed;
		$set_xtic .= ", " if $app_idx > 0;
		$set_xtic .= "'$xtic' $app_idx";

		if ($browse_detail || $line == 3) {
			if ($browse_detail) {
				$browser_name = $xtic;
				push(@browser_names, $browser_name);
				$datfn = "$name-$browser_name.dat";
				print "=== $browser_name ===\n";
			}
			else {
				$browser_name = "";
				$datfn = "$name.dat";
			}
			open OFD, ">$datfn";

			if ($browse_detail) {
				printf OFD "# $prefix\n";
				printf OFD "%-15s", "# sites";
			}
			else {
				printf OFD "%-50s", "# workloads";
			}

			$base_idx = 2;
			$i = 0;
			$plot_cmd = "plot";
			foreach $mode (@modes) {
				printf OFD "%-20s", "$stat($mode)";
				printf OFD "%-18s", "sd($mode)" if $stat eq "avg";

				$plot_cmd .= "," if $i > 0;
				$solid = $i * 0.13 + 0.05;
				if ($stat eq "avg") {
					$avg_idx = $i * 2 + $base_idx;
					$sd_idx  = $i * 2 + $base_idx + 1;
					$plot_cmd .= " '$datfn' u (\$$avg_idx / \$$base_idx):(\$$sd_idx / \$$base_idx) t '$plot_titles[$i]' lt 1 fs solid $solid";
				}
				else {
					$idx = $i + $base_idx;
					$plot_cmd .= " '$datfn' u (\$$idx / \$$base_idx) t '$plot_titles[$i]' lt 1 fs solid $solid";
				}
				$i++;
			}
			print OFD "\n";
			$plot_cmds{$browser_name} = $plot_cmd;
		}

		$site_idx = 0;
		foreach $site (@browse_sites) {
			if ($browse_detail) {
				printf OFD "%-15s", $site;
				print "$site\n";
			}
			else {
				printf OFD "%-50s", $prefix;
				print "$prefix\n";
			}
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
					$opt = "";
					if ($browse_detail && $site_idx < 10) {
						$resfn =~ s/\.time/-$site\.time/g;
						$opt = sprintf("%d 10", $site_idx + 1);
					}
					`./get_latency.plx $rawfn $mult $opt > $resfn`;
					$stat_all = `tail -1 $resfn`;
				}
				print "\t$mode: $stat_all";
				$val = $1 if ($stat_all =~ /$stat=(\d+\.\d+)/);
				$sd  = $1 if ($stat_all =~ /sd=(\d+\.\d+)/);
				printf OFD "%-20.2lf", $val;
				printf OFD "%-18.2lf", $sd if $stat eq "avg";

				if ($i == 0) {
					$time_sec = $mixed ? $val : $val / 1000;
					$label_xpos = $browse_detail ? $site_idx : $app_idx;
					$label_xpos -= (int(@modes) / 2 * 0.13);
					if ($mixed) {
						$set_labels{$browser_name} .= sprintf("set label '%ds' at %.2lf,1.09\n", $time_sec, $label_xpos);
					}
					else {
						$set_labels{$browser_name} .= sprintf("set label '%.1lfs' at %.2lf,1.05\n", $time_sec, $label_xpos);
					}
				}
				$i++;
			}
			print OFD "\n";
			$site_idx++;
		}
		close OFD if $browse_detail;	# each line makes its own data file
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
$xmax = $app_idx - 0.5;

$i = 0;
if ($browse_detail) {
	$set_xtic = "set xtic (";
	foreach $site (@browse_sites) {
		$set_xtic .= ", " if $i > 0;
		$set_xtic .= "'$site' $i";
		$i++;
	}
	$set_xtic .= ")";
	$xmax = $i - 0.5;
	$set_size = "set size 2.5,1";
}

foreach $browser_name (@browser_names) {
	if ($browse_detail) {
		$plt_name = "$name-$browser_name" 
	}
	else {
		$plt_name = "$name";
	}

	open PFD, ">$plt_name.plt";
	print PFD "
set terminal postscript eps enhanced monochrome
set terminal post 'Times-Roman' 23
set output '$plt_name.eps'
set key reverse Left outside right width -1
$set_size
$set_labels{$browser_name}
$set_xlabel
$set_ylabel
set xrange [-0.5:$xmax]
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
$plot_cmds{$browser_name}
";
	close PFD;
	system("gnuplot $plt_name.plt");
}

