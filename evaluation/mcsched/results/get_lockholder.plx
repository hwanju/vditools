#!/usr/bin/perl -w

die "Usage: $0 <name filter(e.g., futex)> <lockholder dump file>\n" unless @ARGV == 2;
$filter = shift(@ARGV);
$fn = shift(@ARGV);
$out_fn = $fn;
$out_fn =~ s/\.\w+/\.lhp/g;
open FD, $fn or die "file open error: $fn\n";
open OFD, ">$out_fn";

$nr_lhp = 0;
while(<FD>) {
	$line++;
	last if (/lhp_cur_eip/);
	next if (/lhp$/);
	chomp;
	@stat = split(/\s+/);
	$depth = $stat[0];
	if ($depth > 0) {	# lhp
		$match = 0;
		for($i = 0 ; $i < $depth && $stat[$i] ; $i++) {
			$lock_loc = `find_lh_loc.plx $stat[$i] 2> /dev/null`;
			if ($lock_loc =~ /$filter/) {
				chomp($lock_loc);
				print OFD "line $line: $_\n$stat[$i] --> $lock_loc LHP=$stat[5]\n";
				$match = 1;
			}
		}
		$nr_lhp += $stat[5] if $match;
	}
}
print OFD "$nr_lhp\n";
