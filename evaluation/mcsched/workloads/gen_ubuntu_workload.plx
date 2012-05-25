#!/usr/bin/perl -w
$script_dir = "mcsched";

die "Usage: $0 <N>workload+<M>workload\@mode\n" if @ARGV < 1;
$fn = shift(@ARGV);
##$postfix = @ARGV ? shift(@ARGV) : "";
die "Error: $fn aleary exits. Check it!\n" if -e $fn;
open FD, ">$fn";

@parsec_workloads=qw( blackscholes  bodytrack  canneal  dedup  facesim  ferret  fluidanimate  freqmine  raytrace  streamcluster  swaptions  vips  x264 );
foreach $p (@parsec_workloads) {
	$parsec{$p} = 1;
}

($workloads, $mode) = split( /@/, $fn );
$prolog = $epilog = $mode;
####$epilog =~ s/_pct\d+//g;
####$epilog .= "_epilog";
$epilog = "common_epilog";
$prolog =~ s/pct(\d+)/$1pct/g;
$prolog .= "_prolog";

print "Warning: ../scripts/$prolog doesn't exist!\n" unless -e "../scripts/$prolog";
print "Warning: ../scripts/$epilog doesn't exist!\n" unless -e "../scripts/$epilog";

print FD "prolog_script = '$script_dir/$prolog'\n";
print FD "epilog_script = '$script_dir/$epilog'\n";
print FD "workload_scripts = (\n";

@workload_list = split( /\+/, $workloads );
foreach $w (@workload_list) {
        if ($w =~ /(\d+)(\S+)/) {
                $n = $1;
                $name = $2;
                $subdir = $name =~ /Pi/ ? "Pi" : ($parsec{$name} ? "parsec" : "");
                $name =~ s/Pi_/Pi-/g;
                $name .= "-536M" if $name eq "Pi-single";       # FIXME
                print "Warning: ../scripts/ubuntu/$subdir/$name doesn't exist!\n" unless -e "../scripts/ubuntu/$subdir/$name";
                foreach (1 .. $n) {
                        print FD "\t'$script_dir/ubuntu/$subdir/$name',\n";
                }

        }
}
print FD ")\n";
