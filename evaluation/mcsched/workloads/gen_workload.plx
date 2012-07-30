#!/usr/bin/perl -w
$script_dir = "mcsched";

die "Usage: $0 <N>workload+<M>workload\@mode\n" if @ARGV < 1;
$fn = shift(@ARGV);
##$postfix = @ARGV ? shift(@ARGV) : "";
die "Error: $fn aleary exits. Check it!\n" if -e $fn;

open FD, "workloads.inc";
while(<FD>) {
	next if (/^#/);
	($workload_name, $list) = split(/=/);
	$list =~ s/"//g;
	@workload_list = split(/\s+/, $list);
	@parsec_workloads  = @workload_list if ($workload_name eq "parsec_workloads");
	@npb_workloads     = @workload_list if ($workload_name eq "npb_workloads");
	@ubuntu_workloads  = @workload_list if ($workload_name eq "ubuntu_workloads");
	@windows_workloads = @workload_list if ($workload_name eq "windows_workloads");
}
close FD;

open FD, ">$fn";

# for workload membership
my %parsec;
my %ubuntu;
my %windows;
@parsec{@parsec_workloads} = ();
@npb{@npb_workloads} = ();
@ubuntu{@ubuntu_workloads} = ();
@windows{@windows_workloads} = ();

($workloads, $mode) = split( /@/, $fn );
$prolog = $epilog = $mode;
####$epilog =~ s/_pct\d+//g;
####$epilog .= "_epilog";
$epilog = "common_epilog";
$prolog =~ s/pct(\d+)/$1pct/g;
$prolog .= "_prolog";

print "Warning: ../scripts/$prolog doesn't exist!\n" unless -e "../scripts/$prolog";
print "Warning: ../scripts/$epilog doesn't exist!\n" unless -e "../scripts/$epilog";

print FD "prolog_script = '$script_dir/$prolog'\n";
print FD "epilog_script = '$script_dir/$epilog'\n";
print FD "workload_scripts = (\n";

@workload_list = split( /\+/, $workloads );
foreach $w (@workload_list) {
        if ($w =~ /(\d+)(\S+)/) {
                $n = $1;
                $name = $2;
		$subdir = "";
		if (exists $parsec{$name})		{ $subdir = "ubuntu/parsec" }
		elsif (exists $npb{$name})		{ $subdir = "ubuntu/npb" }
		elsif (exists $ubuntu{$name})		{ $subdir = "ubuntu/interactive" }
		elsif (exists $windows{$name})		{ $subdir = "windows/interactive" }
		elsif ($name =~ /Pi/)			{ $subdir = "ubuntu/Pi" }
		else					{ $subdir = "ubuntu" }

		# Pi-specific
                $name =~ s/Pi_/Pi-/g;
                $name .= "-536M" if $name eq "Pi-single";       # FIXME

		$script_path = "../scripts/$subdir/$name";
                print "Warning: $script_path doesn't exist!\n" unless -e $script_path;
                foreach (1 .. $n) {
                        print FD "\t'$script_dir/$subdir/$name',\n";
                }

        }
}
print FD ")\n";
