#!/usr/bin/perl -w

$seq_num = 1;
if ($ARGV[0] eq "-n") {
	shift(@ARGV);
	$seq_num = shift(@ARGV);
}

foreach $f (@ARGV) {
	open FD, $f or die "file open error: $f\n";
	print "$f\n";
	$n = 0;
	while(<FD>) {
		last if $n > $seq_num;
		if (/^# /) {
			$label = $_;
		}
		if (/value \|/) {
			$n++;
			next unless $seq_num == $n;

			print $label;
			while(<FD>) {
				last unless /\|/;
				s/\s+//g;
				s/\|/\t/g;
				s/@+//g;
				print "$_\n";
			}
		}
	}
	close FD;
}
