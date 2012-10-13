#!/usr/bin/perl -w

while(<>) {
	if (/(\d+)\s+GA (d\d+_v\d+)/) {
		$time = $1;
		$id = $2;
		if (/f=(\d+)/) { 
			$flags{$id} = $1;
			if (defined($prev_flags{$id}) && $prev_flags{$id} > 0 && $flags{$id} == 0) {
				print "$time: $_";
			}
			$prev_flags{$id} = $flags{$id};
		}
	}

}
