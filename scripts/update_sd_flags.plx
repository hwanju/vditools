#!/usr/bin/perl -w

=pod
#define SD_LOAD_BALANCE         0x0001  /* Do load balancing on this domain. */
#define SD_BALANCE_NEWIDLE      0x0002  /* Balance when about to become idle */
#define SD_BALANCE_EXEC         0x0004  /* Balance on exec */
#define SD_BALANCE_FORK         0x0008  /* Balance on fork, clone */
#define SD_BALANCE_WAKE         0x0010  /* Balance on wakeup */
#define SD_WAKE_AFFINE          0x0020  /* Wake task to waking CPU */
#define SD_PREFER_LOCAL         0x0040  /* Prefer to keep tasks local to this domain */
#define SD_SHARE_CPUPOWER       0x0080  /* Domain members share cpu power */
#define SD_POWERSAVINGS_BALANCE 0x0100  /* Balance for power savings */
#define SD_SHARE_PKG_RESOURCES  0x0200  /* Domain members share cpu pkg resources */
#define SD_SERIALIZE            0x0400  /* Only a single load balancing instance */
#define SD_ASYM_PACKING         0x0800  /* Place busy groups earlier in the domain */
#define SD_PREFER_SIBLING       0x1000  /* Prefer to place tasks in a sibling domain */
#define SD_OVERLAP              0x2000  /* sched_domains of this level overlap */
=cut

my @flag_name_list = qw( SD_LOAD_BALANCE SD_BALANCE_NEWIDLE SD_BALANCE_EXEC SD_BALANCE_FORK SD_BALANCE_WAKE SD_WAKE_AFFINE SD_PREFER_LOCAL SD_SHARE_CPUPOWER SD_POWERSAVINGS_BALANCE SD_SHARE_PKG_RESOURCES SD_SERIALIZE SD_ASYM_PACKING SD_PREFER_SIBLING SD_OVERLAP );

die "$0 <domain id> [flag_name on|off]\n\tavailable flag names=@flag_name_list" unless @ARGV >= 1;
$dom = shift(@ARGV);
if (@ARGV) {
	$flag_name = shift(@ARGV);
	die "on or off must be specified!\n" unless @ARGV;
	$on = shift(@ARGV);
}
$i = 0;
$set = defined($flag_name);
if ($set) {
	foreach $f (@flag_name_list) {
		$flag_bit{$f} = (1<<$i++); 
	}
}
foreach $cpu (0 .. 31) {
	$dom_dir = "/proc/sys/kernel/sched_domain/cpu$cpu/domain$dom";
        if ( -e $dom_dir) {
                $flags = `cat $dom_dir/flags`;
                chomp($flags);
		if (!$set) {	# get
			printf("flags=0x%x\n", $flags);
			$i = 0;
			foreach $f (@flag_name_list) {
				print "$f\n" if $flags & (1<<$i++);
			}
			last;
		}
		else {		# set
			$new_flags = $on eq "on" ? $flags | $flag_bit{$flag_name} : $flags & ~$flag_bit{$flag_name};
			if ($new_flags != $flags) {
				`echo $new_flags > /proc/sys/kernel/sched_domain/cpu$cpu/domain$dom/flags`;
				printf "cpu$cpu domain$dom: $flag_name is turned $on (%x->%x)\n", $flags, $new_flags;
			}
			else {
				printf "cpu$cpu domain$dom: $flag_name is already $on (%x)\n", $flags;
			}
		}
        }
}
