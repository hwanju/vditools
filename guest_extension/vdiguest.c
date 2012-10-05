#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <dirent.h>
#include <linux/input.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/epoll.h>
#include <sys/time.h>
#include <termios.h>
#include <signal.h>
#include <sched.h>

/* Parameters */
int audio_monitor = 0;		/* -a: audio monitor if 1 */
int init_nr_fast_cpus = 2;	/* -f <val>: initial # of fast cpus */
int verbose;			/* -v: verbose level */
enum {
	MODE_STATIC,
	MODE_LOAD,
	MODE_DYNAMIC,
	MODE_END
};
char *mode_desc[] = {
	"Static: # of fast & slow cpus are fixed in predefined numbers",
	"Load: # of slow cpus is determined based on previous CPU loads of slow tasks",
	"Dynamic: start with Static, and adjust # of fast cpus based on CPU loads on fast cpus"
};
int mode = MODE_STATIC;

#define exit_with_msg(args...) do { fprintf(stderr, args); exit(-1); } while (0)

#define VB_MAJOR	1
#define VB_MINOR	2
#define debug_printf(level, args...)  \
	do { if (level <= verbose) printf(args); } while (0)

#define SLOW_TASK_PATH		"/proc/kvm_slow_task"
#define AUDIO_ACTIVITY_PATH	"/tmp/vdiguest-audio-activity"

#define CPUSET_PATH		"/dev/cpuset/vdiguest"
#define SLOW_GROUP_NAME		"slow"
#define FAST_GROUP_NAME		"fast"
#define CPUS_NODE		"cpuset.cpus"
#define MEMS_NODE		"cpuset.mems"
#define PROCS_NODE		"cgroup.procs"
#define ROOT_PROCS_PATH		CPUSET_PATH "/" PROCS_NODE
#define SLOW_CPUS_PATH		CPUSET_PATH "/" SLOW_GROUP_NAME "/" CPUS_NODE
#define FAST_CPUS_PATH		CPUSET_PATH "/" FAST_GROUP_NAME "/" CPUS_NODE
#define SLOW_MEMS_PATH		CPUSET_PATH "/" SLOW_GROUP_NAME "/" MEMS_NODE
#define FAST_MEMS_PATH		CPUSET_PATH "/" FAST_GROUP_NAME "/" MEMS_NODE
#define SLOW_PROCS_PATH		CPUSET_PATH "/" SLOW_GROUP_NAME "/" PROCS_NODE
#define FAST_PROCS_PATH		CPUSET_PATH "/" FAST_GROUP_NAME "/" PROCS_NODE

#define MAX_SLOW_TASKS		64
#define MAX_PATH_LEN		256

#define MAX_INPUT_DECS		8
#define MAX_INPUT_EVENTS	32
#define INPUT_NAME_LEN		256
#define INPUT_TYPE_KEYBOARD	0
#define INPUT_TYPE_MOUSE	1
/* currently 2~ types are not defined */

unsigned long stat_mon_period_us = 1000000;
#define start_stat_monitor()	do { ualarm(stat_mon_period_us, 0); } while(0)

int nr_cpus;	/* # of available CPUs */
int my_pid;

struct input_descriptor {
	int fd;
	int type;
	char *path;
	char name[INPUT_NAME_LEN];
} input_desc[MAX_INPUT_DECS];

struct slow_task {
	int task_id;
	int load_pct;
};

/* safewrite is borrowed from libvirtd 
 * Like write(), but restarts after EINTR */
static ssize_t safewrite(int fd, const void *buf, size_t count)
{
	size_t nwritten = 0;
	while (count > 0) {
		ssize_t r = write(fd, buf, count);

		if (r < 0 && errno == EINTR)
			continue;
		if (r < 0)
			return r;
		if (r == 0)
			return nwritten;
		buf = (const char *)buf + r;
		count -= r;
		nwritten += r;
	}
	return nwritten;
}

static int filewrite(const char *path, const char *str)
{
	int fd;
	int ret;
	if ((fd = open(path, O_WRONLY|O_TRUNC)) < 0) {
		perror("file open error");
		return -1;
	}
	ret = safewrite(fd, str, strlen(str));
	close(fd);

	debug_printf(VB_MAJOR, "write %s to %s\n", str, path);

	return ret;
}

#define fileprintf(path, args...) ({	\
	int ret;	\
	char str[256];	\
	snprintf(str, 256, args);	\
	ret = filewrite(path, str);	\
	ret;	\
}) 

static char *get_name_by_pid(int pid)
{
	static char comm[256];
	static char *na = "N/A\n";
	char comm_path[32];
	FILE *fp;

	snprintf(comm_path, 32, "/proc/%d/comm", pid);
	if ((fp = fopen(comm_path, "r")) == NULL)
		return na;
	fgets(comm, 256, fp);
	fclose(fp);

	return comm ? comm : na;
}

#define debug_procname_print(pid)	\
	do { debug_printf(VB_MAJOR, "\t%d=%s", pid, get_name_by_pid(pid)); } while(0)

static void move_slow_tasks(int nr_slow_tasks, struct slow_task *slow_tasks, int nr_slow_cpus)
{
	int i;

	fileprintf(SLOW_CPUS_PATH, "%d-%d", nr_cpus - nr_slow_cpus, nr_cpus - 1);
	for (i = 0; i < nr_slow_tasks; i++) {
		if (my_pid == slow_tasks[i].task_id)	/* unlikely */
			continue;
		fileprintf(SLOW_PROCS_PATH, "%d", slow_tasks[i].task_id);
		debug_procname_print(slow_tasks[i].task_id);
	}
}

static void mod_fast_cpus(int nr_fast_cpus)
{
	fileprintf(FAST_CPUS_PATH, "%d-%d", 0, nr_fast_cpus - 1);
}

static void move_fast_tasks(void)
{
	int pid;
	FILE *fp = fopen(ROOT_PROCS_PATH, "r");
	if (!fp) {
		fprintf(stderr, "Error: %s open, so fail to move fast tasks!\n", 
				ROOT_PROCS_PATH);
		return;
	}
	while(fscanf(fp, "%d", &pid) == 1) {
		fileprintf(FAST_PROCS_PATH, "%d", pid);
		debug_procname_print(pid);
	}
	fclose(fp);

	if (verbose >= VB_MAJOR) {
		if ((fp = fopen(ROOT_PROCS_PATH, "r")) == NULL)
			return;
		debug_printf(VB_MAJOR, "Process list failed to move to fast cpu group\n");
		while(fscanf(fp, "%d", &pid) == 1)
			debug_procname_print(pid);
		fclose(fp);
	}
}

static void restore_tasks(void)
{
	int pid;
	FILE *fp = fopen(SLOW_PROCS_PATH, "r");
	if (!fp) {
		fprintf(stderr, "Error: %s open, so fail to move fast tasks!\n", 
				SLOW_PROCS_PATH);
		return;
	}
	mod_fast_cpus(nr_cpus);
	while(fscanf(fp, "%d", &pid) == 1) {
		fileprintf(FAST_PROCS_PATH, "%d", pid);
		debug_procname_print(pid);
	}
	fclose(fp);
}

static int get_slow_tasks(struct slow_task *slow_tasks, int *nr_slow_cpus)
{
	FILE *fp;
	int n = 0;
	int load_pct = 0;

	if ((fp = fopen(SLOW_TASK_PATH, "r")) == NULL)
		return 0;

	while(fscanf(fp, "%d %d", &slow_tasks[n].task_id, &slow_tasks[n].load_pct) == 2) {
		load_pct += slow_tasks[n].load_pct;

		debug_printf(VB_MAJOR, "\t%d pct load: ", slow_tasks[n].load_pct);
		debug_procname_print(slow_tasks[n].task_id);

		n++;
	}
	*nr_slow_cpus = (load_pct + 99) / 100;
	debug_printf(VB_MAJOR, "aggregated load of slow tasks = %d%% (nr_slow_cpus=%d)\n", 
			load_pct, *nr_slow_cpus);
	fclose(fp);

	return n;
}

/* fast version of checking if there is still a slow task */
static int slow_task_exist(void)
{
	FILE *fp;
	int ret, dummy;
	if ((fp = fopen(SLOW_TASK_PATH, "r")) == NULL)
		return 0;
	ret = fscanf(fp, "%d", &dummy) == 1;
	fclose(fp);

	debug_printf(VB_MINOR, "\tcheck if slow tasks exist -> %s\n", ret ? "true" : "false");

	return ret;
}

static int audio_activity_exist(void)
{
	FILE *fp;
	int audio_activity = 0;
	if (!audio_monitor)
		return 0;
	if ((fp = fopen(AUDIO_ACTIVITY_PATH, "r")) == NULL)
		return 0;
	fscanf(fp, "%d", &audio_activity);
	fclose(fp);

	debug_printf(VB_MINOR, "\taudio activity exists -> %s\n", audio_activity ? "true" : "false");

	return audio_activity;
}

static void isolate_slow_tasks(void)
{
	int nr_fast_cpus, nr_slow_cpus;
	int nr_slow_tasks;
	struct slow_task slow_tasks[MAX_SLOW_TASKS];

	nr_slow_tasks = get_slow_tasks(slow_tasks, &nr_slow_cpus);

	/* if no slow tasks, nothing to do */
	if (nr_slow_tasks == 0) {
		restore_tasks();
		return;
	}
	if (mode == MODE_STATIC) {
		nr_fast_cpus = init_nr_fast_cpus;
		nr_slow_cpus = nr_cpus - nr_fast_cpus;
	}
	else if (mode == MODE_LOAD) {
		if (nr_cpus - nr_slow_cpus < init_nr_fast_cpus)	/* short of fast cpus */
			nr_slow_cpus = nr_cpus - init_nr_fast_cpus;
		nr_fast_cpus = nr_cpus - nr_slow_cpus;
	}

	debug_printf(VB_MAJOR, "# nr_fast cpus=%d, nr_slow cpus=%d (nr_slow_tasks=%d, init_nr_fast_cpus=%d)\n", 
			nr_fast_cpus, nr_slow_cpus, nr_slow_tasks, init_nr_fast_cpus); 

	move_slow_tasks(nr_slow_tasks, slow_tasks, nr_slow_cpus);
	mod_fast_cpus(nr_fast_cpus);
	start_stat_monitor();
}

static void stat_monitor(int arg)
{
	int audio_activity = audio_activity_exist();

	if (!slow_task_exist()) {
		restore_tasks();
		if (!audio_activity)
			return;
	}
	else if (audio_activity)
		isolate_slow_tasks();
	start_stat_monitor();
}

static void monitor_input(int epfd)
{
	int i;
	int nr_events;
	struct epoll_event events[MAX_INPUT_EVENTS];
	struct input_event input_evt[64];
	int size = sizeof (struct input_event);
	struct input_descriptor *idesc;
	static unsigned int seq_num = 1;

	while(1) {
		nr_events = epoll_wait(epfd, events, MAX_INPUT_EVENTS, 100);
		if (nr_events < 0 || errno == EINTR)
			continue;
		for (i = 0; i < nr_events; i++) {
			idesc = (struct input_descriptor *)events[i].data.ptr;
			if (read(idesc->fd, input_evt, size * 64) < size)
				continue;

			if (idesc->type == INPUT_TYPE_KEYBOARD) {
				if (input_evt[0].value != ' ' && 
				    input_evt[1].value == 1 && 
				    input_evt[1].type == 1 &&
				    input_evt[1].code == 28) {	/* enter key press */
					debug_printf (VB_MAJOR, "\nI%d: keyboard (code=%d)\n", 
							seq_num++,
							(input_evt[1].code));
					isolate_slow_tasks();
				}
			}
			else if (idesc->type == INPUT_TYPE_MOUSE) {
				if (input_evt[1].value == 0 &&	/* mouse click released */
				    input_evt[1].type == 1) {
					debug_printf(VB_MAJOR, "\nI%d: mouse ([0].value=%x [0].type=%x [1].value=%x [1].type=%x)\n",
						seq_num++,
						input_evt[0].value, input_evt[0].type,
						input_evt[1].value, input_evt[1].type);
					isolate_slow_tasks();
				}
			}
		}
	}
}

/* slow, but convinient for initialization */
#define shell_command(args...) ({	\
	int ret;	\
	char cmd[256];	\
	snprintf(cmd, 256, args);	\
	ret = system(cmd);	\
	ret;	\
})

static int setup_cpuset(void)
{
	int ret;
	shell_command("mkdir -p %s", CPUSET_PATH);
	shell_command("mount -t cgroup -o cpuset none %s", CPUSET_PATH);
	shell_command("mkdir -p %s/%s", CPUSET_PATH, SLOW_GROUP_NAME);
	shell_command("mkdir -p %s/%s", CPUSET_PATH, FAST_GROUP_NAME);

	/* FIXME: currently assume guest kernel has memory node 0 */
	fileprintf(SLOW_MEMS_PATH, "%d", 0);
	fileprintf(FAST_MEMS_PATH, "%d", 0);

	mod_fast_cpus(nr_cpus);
	move_fast_tasks();

	/* simply check the above commands by the following */
	return shell_command("ls %s/%s/tasks > /dev/null", 
			CPUSET_PATH, SLOW_GROUP_NAME);
}

static int init_input_monitor(int nr_devs, char **input_devs)
{
	int i;
	int fd;
	int epfd;
	struct epoll_event event;

	if ((epfd = epoll_create(nr_devs)) < 0) {
		perror("epoll_create");
		return -1;
	}
	for (i = 0; i < nr_devs && i < MAX_INPUT_DECS; i++) {
		if ((fd = open(input_devs[i], O_RDONLY)) == -1)
			exit_with_msg("file open error: %s\n", input_devs[i]);

		/* set input descriptor */
		input_desc[i].fd = fd;
		input_desc[i].type = i;
		input_desc[i].path = input_devs[i];
		ioctl (fd, EVIOCGNAME(INPUT_NAME_LEN), input_desc[i].name);

		/* add to epoll interface */
		event.events = EPOLLIN;
		event.data.ptr = &input_desc[i];
		if (epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &event) < 0) {
			perror("epoll_ctl");
			return -1;
		}
		printf ("path=%s name=%s fd=%d type=%d\n", 
				input_desc[i].path, 
				input_desc[i].name, 
				input_desc[i].fd,
				input_desc[i].type);
	}
	return epfd;
}

static void init_stat_monitor(void)
{
	struct sigaction act;
	act.sa_handler = stat_monitor;
	sigaction(SIGALRM, &act, 0);
}

static void make_myself_realtime(void)
{
	struct sched_param sp = { .sched_priority = 1 };
	if (sched_setscheduler(0, SCHED_FIFO, &sp) < 0)
		perror("sched_setscheduler");
}

int main (int argc, char *argv[])
{
	int c;
	int epfd = -1;

	opterr = 0;
	while ((c = getopt (argc, argv, "af:m:p:v:")) != -1) {
		switch (c) {
			case 'a':
				audio_monitor = 1;
				break;
			case 'f':
				init_nr_fast_cpus = atoi(optarg);
				break;
			case 'm':
				mode = atoi(optarg);
				break;
			case 'p':
				stat_mon_period_us = atoi(optarg) * 1000;	/* ms->us */
				break;
			case 'v':
				verbose = atoi(optarg);
				break;
			default:
				exit_with_msg("Error: -%c is an invalid option!\n", c);
		}
	}
	argc -= (optind - 1);

	if (argc < 2 || mode >= MODE_END || mode < 0) {
		exit_with_msg("Usage: %s [-d,-f <# of fast cpus>, -m <mode>] <keyboard input device file> <mouse input device file> <others> ...\n", argv[0]);
	}

	if ((getuid()) != 0)
		exit_with_msg("%s", "Error: root privilege is required!\n");

	if ((epfd = init_input_monitor(argc - 1, &argv[optind])) < 0)
		exit_with_msg("%s", "Error: input monitor set failed!\n");

	if ((nr_cpus = sysconf(_SC_NPROCESSORS_ONLN)) < 1)
		exit_with_msg("%s", "Error: fail to get the number of CPUs!\n");

	if (nr_cpus == 1)
		exit_with_msg("%s", "Error: work only on SMP guest!\n");

	if (init_nr_fast_cpus > nr_cpus)
		exit_with_msg("%s", "Error: initial # of fast cpus (%d) is greater than # of available CPUs (%d)!\n",
				init_nr_fast_cpus, nr_cpus);

	if (nr_cpus - init_nr_fast_cpus < 1)
		init_nr_fast_cpus = 1;

	my_pid = getpid();

	printf("config: init_nr_fast_cpus=%d mode=%d stat_mon_period_us=%lums verbose=%d\n", 
			init_nr_fast_cpus, mode, stat_mon_period_us / 1000, verbose);
	printf("\t[MODE] %s\n", mode_desc[mode]);

	if (setup_cpuset() != 0)
		exit_with_msg("%s", "Error: cpuset cgroup setup is failed!\n");
	printf("cpuset configuration is done.\n");

	make_myself_realtime();

	init_stat_monitor();

	monitor_input(epfd);

	return 0;
} 
