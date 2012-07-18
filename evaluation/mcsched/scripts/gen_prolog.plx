#!/usr/bin/perl -w

$templ = @ARGV ? shift(@ARGV) : "prolog_template";
$clean = $templ eq "-c" ? 1 : 0;

%mode_to_id = (
	"baseline"		=> 0,
	"purebal"		=> 1,	
	"purebal_mig"		=> 2,	
	"fairbal_0pct"		=> 3,	
	"fairbal_100pct"	=> 3
);
@submodes = qw( orig lhp perf prof );
foreach $m (keys %mode_to_id) {
	$balsched = $mode_to_id{$m};
	$ipisched = $m =~ /fairbal/ ? 7 : 0;
	$imbalance = 0;
	$imbalance = $1 if ($m =~ /(\d+)/);
	`rm -f ${m}_prolog*` if $clean;
	foreach $sm (@submodes) {
		$prolog = "${m}_prolog.$sm";
		if ($clean) {
			unlink($prolog);
			next;
		}
		`sed 's/^BALSCHED=/BALSCHED=$balsched/g' $templ > $prolog.tmp.1`;
		`sed 's/^IPISCHED=/IPISCHED=$ipisched/g' $prolog.tmp.1 > $prolog.tmp.2`;
		`sed 's/^IMBALANCE=/IMBALANCE=$imbalance/g' $prolog.tmp.2 > $prolog`;
		`rm -f $prolog.tmp*`;
		`cat ${sm}_script >> $prolog` if (-e "${sm}_script"); 
	}
}
`./set_mode.sh orig` unless $clean;
