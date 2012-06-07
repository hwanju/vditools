#!/usr/bin/perl -w

if (@ARGV < 4) {
	print "$0 <guest VM format> <guest_config file> <eval_config file> <xml_template> [postfix]\n";
	print "\tguest VM format := NV | VC
			N := <# of VMs>
			V := <VM name>
		e.g., $0 5ubuntu1104
		      
		postfix is for guest names for images and configs\n";
	exit;
}
$vm_format = shift(@ARGV);
$guest_conf_fn = shift(@ARGV);
$eval_conf_fn = shift(@ARGV);
$xml_templ = shift(@ARGV);
$postfix = @ARGV ? shift(@ARGV) : "";

die "$guest_conf_fn doesn't exist. You MUST create $guest_conf_fn based on guest_config.example (Don't touch guest_config.example itself!)\n" if ! -e $guest_conf_fn;
die "$eval_conf_fn doesn't exist. You MUST create $eval_conf_fn based on eval_config.example (Don't touch eval_config.example itself!)\n" if ! -e $eval_conf_fn;

if ($vm_format =~ /^(\d+)([\w\.]+)/) {
	$nr_vm = $1;
	$name = $2;
	for $i (1 .. $nr_vm) {
		$guest_name[$i-1] = "${name}-$i";
		$guest_img_name[$i-1] = "${name}${postfix}-$i";
	}
}
else {
	die "format is invalid\n";
}
$nr_guest = int(@guest_name);

open FD, "$guest_conf_fn";
while(<FD>) {
	@f = split(/\s+/);
	if ($f[0] eq "GUEST_MAC") {
		$i = 0;
		foreach $ip (@f) {
			next if $ip eq $f[0];
			$guest_mac[$i++] = $ip;
		}
	}
	else {
		$conf{$f[0]} = $f[1];
	}
}
close FD;

# can override MC via environment variable
$conf{'MC'} = $ENV{MC} ? 'Y' : 'N' if defined($ENV{MC});

open FD, "$eval_conf_fn";
while(<FD>) {
	@f = split(/\s+/);
	$conf{$f[0]} = $f[1];	# We do not use GUEST_IP here
}
close FD;

#generate xml
$uuid_head = "1e77f5bf-b623-186d-1651-7feb7272";
$uuid_tail_base = "8e41";
open FD, "$xml_templ" or die "file open error: $xml_templ\n"; 
for $i (0 .. ($nr_guest - 1)) {
	seek(FD, 0, 0);
	open OFD, ">$guest_img_name[$i].xml";
	$uuid_tail = sprintf("%x", hex($uuid_tail_base) + $i);
	$spice_port = int($conf{'SPICE_PORT_BASE'}) + $i;
	while(<FD>) {
		s/(qemu=)/$1'$conf{'QEMU'}'/g;
		s/(<name>)/$1$guest_name[$i]/g;
		s/(<uuid>)/$1$uuid_head$uuid_tail/g;
		s/(<memory>)/$1$conf{'MEM'}/g;
		s/(<currentMemory>)/$1$conf{'MEM'}/g;
		s/(<vcpu>)/$1$conf{'VCPU'}/g;
		s/(arch=)/$1'$conf{'ARCH'}'/g;
		s/(source file=)/$1'$conf{'GUEST_IMAGE_DIR'}\/$guest_img_name[$i].qcow2'/g;
		s/(mac address=)/$1'$guest_mac[$i]'/g;
		s/(listen=)/$1'$conf{'HOST_IP'}'/g;
		s/(port=)/$1'$spice_port'/g;

		print OFD $_;

		if ($conf{'MC'} eq "Y" && /<vcpu>/) {
			print OFD "  <cpu>\n";
			print OFD "    <topology sockets='1' cores='$conf{'VCPU'}' threads='1'/>\n";
			print OFD "  </cpu>\n";
		}
	}
	close OFD;
}
