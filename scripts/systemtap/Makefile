all: trace_lock_holder

trace_lock_holder: trace_lock_holder.stp
	stap -v -r `uname -r` $@.stp -m $@

trace_lock_holder_resched_ipi: trace_lock_holder_resched_ipi.stp
	stap -v -r `uname -r` $@.stp -m $@
