#!/usr/bin/perl -w

@parsec_workloads=qw(blackscholes  bodytrack  canneal  dedup  facesim  ferret  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264);

$templ = @ARGV ? shift(@ARGV) : "parsec_template";
$postfix = @ARGV ? shift(@ARGV) : "";
$clean = $templ eq "-c";

open FD, $templ or die "file open error: $templ\n" unless $clean;
foreach $p (@parsec_workloads) {
	if ($clean) {
		`rm -f $p*`;
		next;
	}
        $t = "apps";
        $t = $p eq "canneal" || $p eq "dedup" || $p eq "streamcluster" ? "kernels" : "apps";
        seek (FD, 0, 0);
        open OFD, ">$p$postfix";
        while(<FD>) {
                s/^PACKAGE=/PACKAGE=$p/g;
                s/^TYPE=/TYPE=$t/g;
                if ($p eq "streamcluster") {
                        s/tar xf.+//g;
                }
                if ($p eq "freqmine") {
                        s/-k/-k -c gcc-openmp/g;
                }
		if ($p eq "x264") {	# for large input, optimize it to make warmup fast
			s/^tar.+/dd if=pkgs\/\$TYPE\/\$PACKAGE\/run\/eledream_1920x1080_512.y4m of=\/dev\/null/g;
		}
                print OFD "$_";
        }
        close OFD;
}
close FD;
