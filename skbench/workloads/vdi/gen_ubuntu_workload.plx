#!/usr/bin/perl -w
#3blackscholes+3Pi_single@baseline

die "Usage: $0 <N>workload+<M>workload\@mode\n" unless @ARGV == 1;
$fn = shift(@ARGV);
die "Error: $fn aleary exits. Check it!\n" if -e $fn;
open FD, ">$fn";

($workloads, $mode) = split( /@/, $fn );
$prolog = $epilog = $mode;
$epilog =~ s/_pct\d+//g;
$epilog .= "_epilog";
$prolog =~ s/pct(\d+)/$1pct/g;
$prolog .= "_prolog";

print "Warning: ../../scripts/vdi/$prolog doesn't exist!\n" unless -e "../../scripts/vdi/$prolog";
print "Warning: ../../scripts/vdi/$epilog doesn't exist!\n" unless -e "../../scripts/vdi/$epilog";

print FD "prolog_script = 'vdi/$prolog'\n";
print FD "epilog_script = 'vdi/$epilog'\n";
print FD "workload_scripts = (\n";

@workload_list = split( /\+/, $workloads );
foreach $w (@workload_list) {
        if ($w =~ /(\d+)(\S+)/) {
                $n = $1;
                $name = $2;
                $subdir = $name =~ /Pi/ ? "Pi" : "parsec";      # FIXME
                $name =~ s/Pi_/Pi-/g;
                $name .= "-536M" if $name eq "Pi-single";       # FIXME
                print "Warning: ../../scripts/vdi/ubuntu/$subdir/$name doesn't exist!\n" unless -e "../../scripts/vdi/ubuntu/$subdir/$name";
                foreach (1 .. $n) {
                        print FD "\t'vdi/ubuntu/$subdir/$name',\n";
                }

        }
}
print FD ")\n";

