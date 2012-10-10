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
	stap -v -r `uname -r` $@.stp `cat /sys/module/kvm/parameters/resched_ipi_unlock_latency_ns` ${VERBOSE} -m $@

urgent_sched_prof: urgent_sched_prof.stp
	stap -v -r `uname -r` $@.stp -m $@

balsched_debug: balsched_debug.stp
	stap -v -r `uname -r` $@.stp -m $@

balsched_prof: balsched_prof.stp
	stap -v -r `uname -r` $@.stp -m $@

trace_ipi: trace_ipi.stp
	stap -v -r `uname -r` $@.stp -m $@

trace_sched: trace_sched.stp
	stap -v -r `uname -r` $@.stp -m $@

trace_lhp: trace_lhp.stp
	stap -v -r `uname -r` $@.stp -m $@

trace_lock_holder_ple: trace_lock_holder_ple.stp
	stap -v -r `uname -r` $@.stp -m $@

# vamp
vamp_correlation: vamp_correlation.stp
	stap -v -r `uname -r` $@.stp -m $@
vamp_debug: vamp_debug.stp
	stap -v -r `uname -r` $@.stp -m $@
vamp_sched_latency: vamp_sched_latency.stp
	stap -v -r `uname -r` $@.stp -m $@
vamp_sched: vamp_sched.stp
	stap -v -r `uname -r` $@.stp -m $@
vdi_load: vdi_load.stp
	stap -v -r `uname -r` $@.stp -m $@
sched_trace: sched_trace.stp
	stap -v -r `uname -r` $@.stp -m $@
vamp_audio_waker: vamp_audio_waker.stp
	stap -v -r `uname -r` $@.stp -m $@
vamp_bg: vamp_bg.stp
	stap -v -r `uname -r` $@.stp -m $@
