#!/usr/bin/perl -w

die "Usage: $0 <audio debug file>\n" unless @ARGV == 1;
$fn = shift(@ARGV);
open FD, $fn or die "Error: file open ($fn)\n";
$name = $fn;
$name =~ s/\.debug//g;

while(<FD>) {
	last if /^#/;
	@vals = split(/\s+/);
	open OFD, ">>$name-$vals[1].dat";
	print OFD "$vals[0]\t$vals[2]\n";
	close OFD;
}
