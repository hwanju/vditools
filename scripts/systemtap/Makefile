all: trace_lock_holder

trace_lock_holder: trace_lock_holder.stp
	stap -v -r `uname -r` $@.stp -m $@

trace_lock_holder_resched_ipi: trace_lock_holder_resched_ipi.stp
	stap -v -r `uname -r` $@.stp -m $@

time_ipi_prof: time_ipi_prof.stp
	stap -v -r `uname -r` $@.stp -m $@

resched_ipi_stat: resched_ipi_stat.stp
	stap -v -r `uname -r` $@.stp -m $@

futex_wake_prof: futex_wake_prof.stp
	stap -v -r `uname -r` $@.stp -m $@

urgent_sched_debug: urgent_sched_debug.stp
	stap -v -r `uname -r` $@.stp -m $@

urgent_sched_prof: urgent_sched_prof.stp
	stap -v -r `uname -r` $@.stp -m $@

balsched_debug: balsched_debug.stp
	stap -v -r `uname -r` $@.stp -m $@

balsched_prof: balsched_prof.stp
	stap -v -r `uname -r` $@.stp -m $@
