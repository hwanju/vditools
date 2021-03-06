#!/usr/bin/perl -w

if (@ARGV < 2) {
	print "$0 <guest VM format> <eval_config file> [postfix]\n";
	print "\tguest VM format F := G | F+F
			G := NV
			N := <# of VMs>
			V := <VM name>
		e.g., $0 5ubuntu1104
		      $0 1win7+3ubuntu1104)
		      
		postfix is for guest names for images and configs\n";
	exit;
}
$vm_format = shift(@ARGV);
$eval_conf_fn = shift(@ARGV);
$postfix = @ARGV ? shift(@ARGV) : "";

die "$eval_conf_fn doesn't exist. You MUST create $eval_conf_fn based on eval_config.example (Don't touch eval_config.example itself!)\n" if ! -e $eval_conf_fn;

$config_fn = "config_$vm_format$postfix.py";

@guest_grps = split(/\+/, $vm_format);
$i = 1;
foreach $guest_grp(@guest_grps) {
	if ($guest_grp =~ /(\d+)(\w+)/) {
		$nr_vm = $1;
		$base_name = $name = $2;
		$base_name =~ s/up$//;
		for (1 .. $nr_vm) {
			$guest_name[$i-1] = "${base_name}-$i";
			$guest_img_fn[$i-1] = "${base_name}${postfix}-$i.qcow2";
			$xml_fn[$i-1] = "${name}${postfix}-$i.xml";
			$i++;
		}
	}
}

$nr_guest = int(@guest_name);
die "Error: format is invalid!\n" unless $nr_guest > 0;

open FD, "$eval_conf_fn";
while(<FD>) {
	@f = split(/\s+/);
	if ($f[0] eq "GUEST_IP") {
		$i = 0;
		foreach $ip (@f) {
			next if $ip eq $f[0];
			$guest_ip[$i++] = $ip;
		}
	}
	else {
		$conf{$f[0]} = $f[1];
	}
}
close FD;

#generate config
open OFD, ">$config_fn" or die "file open error: $config_fn\n";
print OFD 'import os
import sys

';
print OFD "gateway = '$conf{'GATEWAY'}'\n";
print OFD "netmask = '$conf{'NETMASK'}'\n";
print OFD "mount_point = '$conf{'GUEST_MNT_POINT'}'\n";
print OFD "guest_list = [";
for ($i = 0 ; $i < $nr_guest; $i++) {
	print OFD ", " unless $i == 0;
	print OFD "'$guest_name[$i]'";
}
print OFD "]\n";
print OFD "guests_image_map= {\n";
for ($i = 0 ; $i < $nr_guest ; $i++) {
	print OFD "\t'$guest_name[$i]': '$conf{'GUEST_IMAGE_DIR'}/$guest_img_fn[$i]',\n";
}
print OFD "}\n";
print OFD "guests_config_map = {\n";
for ($i = 0 ; $i < $nr_guest ; $i++) {
	print OFD "\t'$guest_name[$i]': os.getcwd() + '/virsh/$xml_fn[$i]',\n";
}
print OFD "}\n";

print OFD "host_ip = '$conf{'HOST_IP'}'\n";
print OFD "client_machine_ip = '$conf{'CLIENT_IP'}'\n";
print OFD "client_machine_bitness = '$conf{'CLIENT_BITNESS'}'\n";

print OFD "ip_map = {\n";
for ($i = 0 ; $i < $nr_guest ; $i++) {
	print OFD "\t'$guest_name[$i]': '$guest_ip[$i]',\n";
}
print OFD "}\n";
print OFD "guest_bitness = {\n";
for ($i = 0 ; $i < $nr_guest ; $i++) {
	print OFD "\t'$guest_name[$i]': '$conf{'GUEST_BITNESS'}',\n";
}
print OFD "}\n";

print OFD "trace_guests = [";
for ($i = 0 ; $i < $conf{'NR_TRACE_GUEST'}; $i++) {
	print OFD ", " unless $i == 0;
	print OFD "'$guest_name[$i]'";
}
print OFD "]\n";
print OFD "dist = [os.path.normpath(sys.modules[__name__].__file__ + '/../dist')]\n";

