#!/usr/bin/perl -w

@npb_workloads=qw(bt cg dc ep ft is lu mg sp ua);

$templ = @ARGV ? shift(@ARGV) : "npb_iter_template";
$class = @ARGV ? shift(@ARGV) : "B";
$clean = $templ eq "-c";

open FD, $templ or die "file open error: $templ\n" unless $clean;
foreach $p (@npb_workloads) {
	if ($clean) {
		`rm -f $p*`;
		next;
	}
        seek (FD, 0, 0);
        open OFD, ">$p";
        while(<FD>) {
                s/^PROGRAM=/PROGRAM=$p/g;
                s/^CLASS=/CLASS=$class/g;
                print OFD "$_";
        }
        close OFD;
}
close FD;
