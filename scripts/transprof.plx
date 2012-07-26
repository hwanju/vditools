#!/usr/bin/perl -w

while(<>) {
        $line++;
        if (/VD (\d+) (\d+) \d+ \d+/) {
                $first_sched{$1}{$2} = 1;
                $nr_sched++;
        }
        if(/GA (\d+) (\d+) \d+ [0-9a-f]{5} (\d+)/) {
                #if (defined($first_sched{$1}{$2}) && $first_sched{$1}{$2} == 0) {
                        if (defined($vcpu_flags{$1}{$2}) && $vcpu_flags{$1}{$2} == 2 && $3 != 2) {
                                $bg_to_fg++;
                                #print ("bg-to-fg: $line\n");
                        }
                        elsif (defined($vcpu_flags{$1}{$2}) && $vcpu_flags{$1}{$2} != 2 && $3 == 2) {
                                $fg_to_bg++;
                                #print ("fg-to-bg: $line\n");
                        }
                        elsif (defined($vcpu_flags{$1}{$2}) && $vcpu_flags{$1}{$2} == 0 && $3 == 1) {
                                $n_to_int++;
                                #print ("n-to-int: $line\n");
                        }
                        elsif (defined($vcpu_flags{$1}{$2}) && $vcpu_flags{$1}{$2} == 1 && $3 == 0) {
                                $int_to_n++;
                                #print ("int-to-n: $line\n");
                        }
                        elsif (defined($vcpu_flags{$1}{$2}) && $vcpu_flags{$1}{$2} == 0 && $3 == 0) {
                                $n_to_n++;
                                #print ("n-to-n: $line\n");
                        }
                        elsif (defined($vcpu_flags{$1}{$2}) && $vcpu_flags{$1}{$2} == 1 && $3 == 1) {
                                $int_to_int++;
                                #print ("int-to-int: $line\n");
                        }
                        elsif (defined($vcpu_flags{$1}{$2}) && $vcpu_flags{$1}{$2} == 2 && $3 == 2) {
                                $bg_to_bg++;
                                #print ("bg-to-bg: $line\n");
                        }
                        #}
                $vcpu_flags{$1}{$2} = $3;
                $first_sched{$1}{$2} = 0;
        }
}
print "bg_to_fg/nr_sched = $bg_to_fg/$nr_sched\n";
print "fg_to_bg/nr_sched = $fg_to_bg/$nr_sched\n";
print "n-to-int/nr_sched = $n_to_int/$nr_sched\n";
print "int-to-n/nr_sched = $int_to_n/$nr_sched\n";
print "n-to-n/nr_sched = $n_to_n/$nr_sched\n";
print "int-to-int/nr_sched = $int_to_int/$nr_sched\n";
print "bg-to-bg/nr_sched = $bg_to_bg/$nr_sched\n";
