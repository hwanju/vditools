#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/poll.h>
#include <sched.h>

int fds1[2];
int fds2[2];
unsigned int interval = 0;
unsigned int iteration = 0;

void ready(int wakefd)
{
	char dummy;
	struct pollfd pollfd = { .fd = wakefd, .events = POLLIN };
	
	if (poll(&pollfd, 1, -1) != 1)
		fprintf(stderr, "error in ready\n");
}

void sender(void)
{
	char dummy;

	int cpu_id = 0;
	int i;
	cpu_set_t set;
	CPU_ZERO(&set);
	CPU_SET(cpu_id, &set);
	sched_setaffinity(0, sizeof(cpu_set_t), &set);

	for(i=0; i<iteration; i++){
		/* Sleep for the specified time */
		sleep(interval);

		printf("T1: Sending message...\n");
		write(fds1[1], &dummy, 1);

	}
}

void receiver(void)
{
	char dummy;

	int cpu_id = 1;
	int i;
	cpu_set_t set;
	CPU_ZERO(&set);
	CPU_SET(cpu_id, &set);
	sched_setaffinity(0, sizeof(cpu_set_t), &set);

	for(i=0; i<iteration; i++) {
		printf("T2: Waiting...\n");
		ready(fds1[0]);
	}
}

int main(int argc, char *argv[])
{
	if(argc != 3){
		printf("Usage: %s <Interval(sec)> <Number of iterations>\n", argv[0]);
		return 0;
	}

	interval = atoi(argv[1]);
	iteration = atoi(argv[2]);

	pthread_t pth_tab[2];

	pipe(fds1);
	pipe(fds2);

	pthread_create(&pth_tab[0], NULL, (void*) &sender, NULL);
	pthread_create(&pth_tab[1], NULL, (void*) &receiver, NULL);

	pthread_join(pth_tab[0], NULL);
	pthread_join(pth_tab[1], NULL);

	return 0;
}
