#!/usr/bin/perl -w

if (@ARGV < 2) {
	print "$0 <guest VM format> <eval_config file> [postfix]\n";
	print "\tguest VM format := NV | VC
			N := <# of VMs>
			V := <VM name>
			C := +VC | e
		(e means epsilon (or null))
		e.g., $0 5ubuntu1104
		      $0 win7+ubuntu1104-1+ubuntu1104-2)
		      
		postfix is for guest names for images and configs\n";
	exit;
}
$vm_format = shift(@ARGV);
$eval_conf_fn = shift(@ARGV);
$postfix = @ARGV ? shift(@ARGV) : "";

die "$eval_conf_fn doesn't exist. You MUST create $eval_conf_fn based on eval_config.example (Don't touch eval_config.example itself!)\n" if ! -e $eval_conf_fn;

$config_fn = "config_$vm_format$postfix.py";

if ($vm_format =~ /^(\d+)(\w+)/) {
	$nr_vm = $1;
	$name = $2;
	for $i (1 .. $nr_vm) {
		$guest_name[$i-1] = "${name}-$i";
		$guest_img_name[$i-1] = "${name}${postfix}-$i";
	}
}
else {
	@guest_name = split(/\+/, $vm_format);
	if ($postfix ne "") {
		$i = 0;
		for $name (@guest_name) {
			if ($name =~ /-\d+$/) {
				$name =~ s/-(\d+)$/$postfix-$1/g;
			}
			else {
				$name .= $postfix;
			}
			$guest_img_name[$i++] = $name;
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
print OFD '
import os
import sys

';
print OFD "gateway = '$conf{'GATEWAY'}'\n";
print OFD "netmask = '$conf{'NETMASK'}'\n";
print OFD "mount_point = '$conf{'GUEST_MNT_POINT'}'\n";
print OFD "guests_image_map= {\n";
for ($i = 0 ; $i < $nr_guest ; $i++) {
	print OFD "\t'$guest_name[$i]': '$conf{'GUEST_IMAGE_DIR'}/$guest_img_name[$i].qcow2',\n";
}
print OFD "}\n";
print OFD "guests_config_map = {\n";
for ($i = 0 ; $i < $nr_guest ; $i++) {
	print OFD "\t'$guest_name[$i]': os.getcwd() + '/virsh/$guest_img_name[$i].xml',\n";
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

print OFD "normal_guests = [";
for ($i = 0 ; $i < $nr_guest ; $i++) {
	print OFD ", " unless $i == 0;
	print OFD "'$guest_name[$i]'";
}
print OFD "]\n";

print OFD "trace_guests = [";
for ($i = 0 ; $i < $conf{'NR_TRACE_GUEST'}; $i++) {
	print OFD ", " unless $i == 0;
	print OFD "'$guest_name[$i]'";
}
print OFD "]\n";
print OFD "dist = [os.path.normpath(sys.modules[__name__].__file__ + '/../dist')]\n";

