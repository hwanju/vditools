#!/usr/bin/perl -w

die "Usage: $0 <dir (e.g., _1parsrc+4x264>\n" unless @ARGV;
$dir = shift(@ARGV);
$dir =~ s/\/$//g;

@tinfo_list = `ls -d $dir/*.threadinfo`;
foreach $tinfo (@tinfo_list) {
	next if ($tinfo =~ /-perf/ || $tinfo =~ /-nople/ || $tinfo =~ /-tlbnoyield/);
	chomp($tinfo);
	@tinfo_files = `ls $tinfo/g1.*`;
	$conf = `basename $tinfo`;
	chomp($conf);

	foreach $f (@tinfo_files) {
		open FD, $f;
		undef($ple);
		while(<FD>) {
			if (/nr_ple\s+:\s+(\d+)/) {
				if (!defined($ple)) {
					$ple = $1;
				}
				else {
					$ple_count{$conf} += ($1 - $ple);

					## for debug
					##$count = $1;
					##print ("$conf\t$f\t$count\t$ple\t$ple_count{$conf}\n") if ($conf =~ /facesim/ && $conf =~ /baseline/);
					##print ("$conf\t$f\t$count\t$ple\t$ple_count{$conf}\n") if ($conf =~ /facesim/ && $conf =~ /fairbal_pct100-1:500000/);
				}
			}
		}
		close FD;
	}
}
foreach $conf (keys %ple_count) {
	#print "$conf\t$ple_count{$conf}\n";
	if ($conf =~ /baseline/ && $conf !~ /nople/) {
		$workload = $1 if ($conf =~ /1(\w+)\+/);
		$baseline_ple{$workload} = $ple_count{$conf};
		#### print "$conf\t$workload\t$ple_count{$conf}\n";
	}
}
print "#workload\tple_reduction(%)\n";
foreach $conf (keys %ple_count) {
	#print "$conf\t$ple_count{$conf}\n";
	if ($conf =~ /fairbal_pct100-1:500000:18000000:1:500000:0/ && $conf !~ /nople/) {
		$workload = $1 if ($conf =~ /1(\w+)\+/);
		$ple_reduction = ($baseline_ple{$workload} - $ple_count{$conf}) * 100 / $baseline_ple{$workload};
		printf "$workload\t%.1lf\n", $ple_reduction;
		#print "$conf\t$workload\t$baseline_ple{$workload}\t$ple_count{$conf}\t$ple_reduction\n";
	}
}
