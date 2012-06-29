#!/usr/bin/perl -w

@trace_files = `ls *.debug`;
foreach $trace_fn (@trace_files) {
	chomp($trace_fn);
	$workload = $1 if ($trace_fn =~ /1(\w+)@/);
	$latency_fn = $trace_fn;
	$latency_fn =~ s/\.debug/\.latency/g;
	if ($trace_fn =~ /powerpoint/ || 
	    $trace_fn =~ /winchrome/ ||
            $trace_fn =~ /iexplore/  ||
            $trace_fn =~ /acrobat/ ) {
		$os = "windows";
	}
	else {
		$os = "linux";
	}
	#print "# $workload\n";
	push(@{$workload_list{$os}}, $workload);
	$res=`../get_interactive_ipi.plx $os $trace_fn $latency_fn`;
	@lines = split(/\n/, $res);
	foreach (@lines) {
		($name, $ipi_per_sec) = split(/\s+/);
		$ipi{$os}{$name}{$workload} = $ipi_per_sec;
	}
}
foreach $os (sort keys %ipi) {
	print "# $os\n";
	foreach $workload (@{$workload_list{$os}}) {
		print "\t$workload";
	}
	print "\n";
	foreach $name (sort keys %{$ipi{$os}}) {
		print "$name";
		#foreach $workload (keys %{$ipi{$os}{$name}}) {
		foreach $workload (@{$workload_list{$os}}) {
			printf "\t%d", $ipi{$os}{$name}{$workload};
		}
		print "\n";
	}
}

