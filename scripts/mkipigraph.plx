#!/usr/bin/perl -w

$unit_ms = @ARGV ? shift(@ARGV) : 1000;
$outfmt = "png";
$prof_id = 0;

sub gen_graph() 
{
        print OFD "}\n";
        close OFD;
        $outfn = $dotfn;
        $outfn =~ s/\.dot/\.$outfmt/g;
        system("dot -T$outfmt -o$outfn $dotfn");
        #system("rm -f $dotfn")
}
while(<>) {
        if (/^(\d+)$/) {
                $time_us = $1;
                $prof_id++;
                gen_graph() if $prof_id > 1;
                $dotfn = "ipi$prof_id.dot";
                open OFD, ">$dotfn" or die "file open error ($dotfn)\n";
                print OFD "digraph {\n";
        }
        elsif (/^(\d+)\s+(\d+)\s+(\d+)$/) {
                $src_vcpu_id = $1;
                $dst_vcpu_id = $2;
                $nr_ipi = $3;
                $nr_ipi_per_unit = $nr_ipi * (1000 * $unit_ms) / $time_us;
                $penwidth = $nr_ipi_per_unit / 10;
                $penwidth = 0.2 if $penwidth < 1;
                $penwidth = 15 if $penwidth > 15;
                if ($penwidth >= 10) {
                        $color = "red";
                }
                elsif ($penwidth >= 5) {
                        $color = "blue";
                }
                else {
                        $color = "black";
                }
                printf OFD "\t\"VCPU%d\" -> \"VCPU%d\" [penwidth=%.1lf, color=%s]\n", $src_vcpu_id, $dst_vcpu_id, $penwidth, $color;
        }
}
gen_graph()
