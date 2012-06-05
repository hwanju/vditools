#!/usr/bin/perl -w

$eval_conf_fn = "../config/eval_config";
die "$eval_conf_fn doesn't exist. You MUST create $eval_conf_fn based on eval_config.example (Don't touch eval_config.example itself!)\n" if ! -e $eval_conf_fn;

open FD, "$eval_conf_fn";
while(<FD>) {
	@f = split(/\s+/);
	$conf{$f[0]} = $f[1];
}
close FD;
$dest_host = "root\@$conf{'CLIENT_IP'}";
$trace_dir="$conf{'CLIENT_HOME'}/$conf{'CLIENT_TRACE_DIR'}/traces";

print "Copy trace files to $dest_host:$trace_dir ...\n";
system("ssh $dest_host mkdir -p $trace_dir");
system("scp *.trace $dest_host:$trace_dir");
