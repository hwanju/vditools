#!/usr/bin/perl -w

my $stat_info_msg = '
CPU statistics
--------------
cpu<N> 1 2 3 4 5 6 7 8 9

First field is a sched_yield() statistic:
1) # of times sched_yield() was called

Next three are schedule() statistics:
2) # of times we switched to the expired queue and reused it
3) # of times schedule() was called
4) # of times schedule() left the processor idle

Next two are try_to_wake_up() statistics:
5) # of times try_to_wake_up() was called
6) # of times try_to_wake_up() was called to wake up the local cpu

Next three are statistics describing scheduling latency:
7) sum of all time spent running by tasks on this processor (in jiffies)
8) sum of all time spent waiting to run by tasks on this processor (in
jiffies)
9) # of timeslices run on this cpu


Domain statistics
-----------------
One of these is produced per domain for each cpu described. (Note that if
CONFIG_SMP is not defined, *no* domains are utilized and these lines
will not appear in the output.)

domain<N> <cpumask> 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36

The first field is a bit mask indicating what cpus this domain operates over.

The next 24 are a variety of load_balance() statistics in grouped into types
of idleness (idle, busy, and newly idle):

1) # of times in this domain load_balance() was called when the
cpu was idle
2) # of times in this domain load_balance() checked but found
the load did not require balancing when the cpu was idle
3) # of times in this domain load_balance() tried to move one or
more tasks and failed, when the cpu was idle
4) sum of imbalances discovered (if any) with each call to
load_balance() in this domain when the cpu was idle
5) # of times in this domain pull_task() was called when the cpu
was idle
6) # of times in this domain pull_task() was called even though
the target task was cache-hot when idle
7) # of times in this domain load_balance() was called but did
not find a busier queue while the cpu was idle
8) # of times in this domain a busier queue was found while the
cpu was idle but no busier group was found

9) # of times in this domain load_balance() was called when the
cpu was busy
10) # of times in this domain load_balance() checked but found the
load did not require balancing when busy
11) # of times in this domain load_balance() tried to move one or
more tasks and failed, when the cpu was busy
12) sum of imbalances discovered (if any) with each call to
load_balance() in this domain when the cpu was busy
13) # of times in this domain pull_task() was called when busy
14) # of times in this domain pull_task() was called even though the
target task was cache-hot when busy
15) # of times in this domain load_balance() was called but did not
find a busier queue while the cpu was busy
16) # of times in this domain a busier queue was found while the cpu
was busy but no busier group was found

17) # of times in this domain load_balance() was called when the
cpu was just becoming idle
18) # of times in this domain load_balance() checked but found the
load did not require balancing when the cpu was just becoming idle
19) # of times in this domain load_balance() tried to move one or more
tasks and failed, when the cpu was just becoming idle
20) sum of imbalances discovered (if any) with each call to
load_balance() in this domain when the cpu was just becoming idle
21) # of times in this domain pull_task() was called when newly idle
22) # of times in this domain pull_task() was called even though the
target task was cache-hot when just becoming idle
23) # of times in this domain load_balance() was called but did not
find a busier queue while the cpu was just becoming idle
24) # of times in this domain a busier queue was found while the cpu
was just becoming idle but no busier group was found

Next three are active_load_balance() statistics:
25) # of times active_load_balance() was called
26) # of times active_load_balance() tried to move a task and failed
27) # of times active_load_balance() successfully moved a task

Next three are sched_balance_exec() statistics:
28) sbe_cnt is not used
29) sbe_balanced is not used
30) sbe_pushed is not used

Next three are sched_balance_fork() statistics:
31) sbf_cnt is not used
32) sbf_balanced is not used
33) sbf_pushed is not used

Next three are try_to_wake_up() statistics:
34) # of times in this domain try_to_wake_up() awoke a task that
last ran on a different cpu in this domain
35) # of times in this domain try_to_wake_up() moved a task to the
waking cpu because it was cache-cold on its own cpu anyway
36) # of times in this domain try_to_wake_up() started passive balancing
';

@cpu_label = qw(cpu yld_cnt   sched_switch    sched_cnt   sched_goidle    ttwu_cnt    ttwu_local  rq_cpu_time run_delay   pcount); 
@domain_label = qw(domain lb_cnt[0]    lb_balanced[0]  lb_failed[0]    lb_imbalance[0] lb_gained[0]    lb_hot_gained[0]    lb_nobusyq[0]   lb_nobusyg[0]   lb_cnt[1]   lb_balanced[1]  lb_failed[1]    lb_imbalance[1] lb_gained[1]    lb_hot_gained[1]    lb_nobusyq[1]   lb_nobusyg[1]   lb_cnt[2]   lb_balanced[2]  lb_failed[2]    lb_imbalance[2] lb_gained[2]    lb_hot_gained[2]    lb_nobusyq[2]   lb_nobusyg[2]   alb_cnt alb_failed  alb_pushed  sbe_cnt sbe_balanced    sbe_pushed  sbf_cnt sbf_balanced    sbf_pushed  ttwu_wake_remote    ttwu_move_affine    ttwu_move_balance);

sub show_label {
        foreach $l ( @cpu_label ) {
                printf( "$l " );
        }
        print "\n" ;
        foreach $l ( @domain_label ) {
                printf( "$l " );
        }
        print "\n" ;
}

if( @ARGV && $ARGV[0] eq "-h" ) {
        die "Usage: $0 <schedstat log file>\n\t->log file contains a pair of /proc/schedstat log, which involves start and end log\n";
}
if( @ARGV && $ARGV[0] eq "-s" ) {
        die "$stat_info_msg\n";
}

$stat_state = 1;
while(<>) {
        if( /^start_time=(\d+)/ ) { 
                $start_time = $1;
                $stat_state = 0;
        }
        elsif( /^end_time=(\d+)/ ) {
                $end_time = $1;
                $stat_state = 1;

                $elapsed_time = $end_time - $start_time;

                printf( "%d\n", $elapsed_time );
                show_label();
        }
        elsif( /^cpu(\d+)/ ) {
                $cpu = $1;
                if( $stat_state == 0 ) {
                        $cpu_info[$cpu] = $_;
                }
                else {
                        @start_count = split( /\s+/, $cpu_info[$cpu] );
                        @end_count = split( /\s+/ );
                        $max_idx = scalar @start_count - 1;

                        print "cpu$cpu ";
                        foreach $i ( 1 .. $max_idx ) {
                                #printf "%.2lf ", ($end_count[$i] - $start_count[$i]) / $elapsed_time;
                                printf "%d ", ($end_count[$i] - $start_count[$i]);
                        }
                        print "\n";
                }
        }
        elsif( /^domain(\d+)/ ) {
                $domain_id = $1;
                if( $stat_state == 0 ) {
                        $domain_info[$cpu][$domain_id] = $_;
                }
                else {
                        @start_count = split( /\s+/, $domain_info[$cpu][$domain_id] );
                        @end_count = split( /\s+/ );
                        $max_idx = scalar @start_count - 1;

                        print "domain$domain_id ";
                        foreach $i ( 2 .. $max_idx ) {
                                #printf "%.2lf ", ($end_count[$i] - $start_count[$i]) / $elapsed_time;
                                printf "%d ", ($end_count[$i] - $start_count[$i]);
                        }
                        print "\n";
                }
        }
}

