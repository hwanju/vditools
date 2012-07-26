#!/usr/bin/perl -w

#use Statistics::Basic qw(:all);

my $line = 0;

sub check_ipi_latency {
        $time_ms = $_[0];
        $vm_id = $_[1];
        $src_vcpu_id = $_[2];
        $dst_vcpu_id = $_[3];

        print "hwandori: $ipi_pending{$vm_id}{$dst_vcpu_id} $nr_pending_ipi{$vm_id}{$src_vcpu_id}\n" if $line ==  771321;
        print "hwandori: $ipi_pending{$vm_id}{$dst_vcpu_id} $nr_pending_ipi{$vm_id}{$src_vcpu_id}\n" if $line ==  773416;

        if (defined($nr_pending_ipi{$vm_id}{$src_vcpu_id}) && $ipi_pending{$vm_id}{$dst_vcpu_id}) {
                $nr_pending_ipi{$vm_id}{$src_vcpu_id}-- if $nr_pending_ipi{$vm_id}{$src_vcpu_id} > 0;
                $vcpu_ipi_pending{$vm_id}{$dst_vcpu_id} = 0;
                $ipi_pending{$vm_id}{$dst_vcpu_id} = 0;

                if ($nr_pending_ipi{$vm_id}{$src_vcpu_id} == 0) {
                        $latency = $time_ms - $ipi_pending_timestamp{$vm_id}{$src_vcpu_id};
                        push(@ipi_latency, $latency);
                        print "$line: $latency $ipi_pending_timestamp{$vm_id}{$src_vcpu_id} $time_ms v$src_vcpu_id -> v$dst_vcpu_id\n";
                }
        }
}

while(<>) {
        $line++;
        if (/(\d+) VA (\d+) (\d+)/) {
                $time_ms = $1;
                $vm_id = $2;
                $vcpu_id = $3;

                $vcpu_running{$vm_id}{$vcpu_id} = 1;
                $src_vcpu_id = $ipi_src_vcpu{$vm_id}{$vcpu_id};
                check_ipi_latency($time_ms, $vm_id, $src_vcpu_id, $vcpu_id) if ($vcpu_ipi_pending{$vm_id}{$vcpu_id} && $src_vcpu_id != $vcpu_id);
                $vcpu_ipi_pending{$vm_id}{$vcpu_id} = 0;
        }
        elsif (/\d+ VD (\d+) (\d+)/) {
                $vm_id = $1;
                $vcpu_id = $2;

                $vcpu_running{$vm_id}{$vcpu_id} = 0;
                $vcpu_ipi_pending{$vm_id}{$vcpu_id} = 0;
        }
        elsif (/(\d+) IPI (\d+) (\d+) \d+ icr_low=[0-9a-f]+ sh=all-but-self/) {
                $time_ms = $1;
                $vm_id = $2;
                $src_vcpu_id = $3;
                print "$line: matured ipi ($nr_pending_ipi{$vm_id}{$src_vcpu_id})\n" if $nr_pending_ipi{$vm_id}{$src_vcpu_id};
                $nr_pending_ipi{$vm_id}{$src_vcpu_id} = 7;
                $ipi_pending_timestamp{$vm_id}{$src_vcpu_id} = $time_ms;
                for ($i = 0 ; $i < 8 ; $i++ ){
                        $ipi_pending{$vm_id}{$i} = 1;
                }
        }
        elsif (/(\d+) IP (\d+) (\d+) (\d+)/) {
                $time_ms = $1;
                $vm_id = $2;
                $src_vcpu_id = $3;
                $dst_vcpu_id = $4;
                check_ipi_latency($time_ms, $vm_id, $src_vcpu_id, $dst_vcpu_id) if ($vcpu_running{$vm_id}{$dst_vcpu_id} && $src_vcpu_id != $dst_vcpu_id);
                $vcpu_ipi_pending{$vm_id}{$dst_vcpu_id} = $vcpu_running{$vm_id}{$dst_vcpu_id} ? 0 : 1;
                $ipi_src_vcpu{$vm_id}{$dst_vcpu_id} = $src_vcpu_id unless ($vcpu_running{$vm_id}{$dst_vcpu_id});
        }
}
