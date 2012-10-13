#!/usr/bin/perl -w

while(<>) {
	$line++;
	if (/GA/) {
		if (/t=([0-9a-f]+)/) {
			$kvm_cr3 = $1;
			if (/pgd=([0-9a-f]+)/) {
				$guest_cr3 = $1;
				if ($kvm_cr3 ne $guest_cr3) {
					print "$line: different cr3 (kvm=$kvm_cr3, guest=$guest_cr3)\n";
				}
			}
		}
	}
}
