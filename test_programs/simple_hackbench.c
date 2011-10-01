#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/poll.h>
#include <sched.h>

int fds1[2];
int fds2[2];
unsigned long long loop = 1000000000;

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
	unsigned long long i, j;

	int cpu_id = 0;
	cpu_set_t set;
	CPU_ZERO(&set);
	CPU_SET(cpu_id, &set);
	sched_setaffinity(0, sizeof(cpu_set_t), &set);

	/* work */
	while(1){
		for(i = 0; i < loop; i++){
			j += 1;
		}

		printf("T1: Sending message...\n");
		write(fds1[1], &dummy, 1);
		printf("T1: Waiting...\n");
		ready(fds2[0]);
		j=0;
	}
}

void receiver(void)
{
	unsigned long long i, j;
	char dummy;

	int cpu_id = 1;
	cpu_set_t set;
	CPU_ZERO(&set);
	CPU_SET(cpu_id, &set);
	sched_setaffinity(0, sizeof(cpu_set_t), &set);

	while(1) {
		printf("T2: Waiting...\n");
		ready(fds1[0]);

		/* work */
		for(i = 0; i < loop; i++){
			j += 1;
		}

		printf("T2: Sending message...\n");
		write(fds2[1], &dummy, 1);
	}
}

int main(void)
{
	pthread_t pth_tab[2];

	pipe(fds1);
	pipe(fds2);

	pthread_create(&pth_tab[0], NULL, (void*) &sender, NULL);
	pthread_create(&pth_tab[1], NULL, (void*) &receiver, NULL);

	pthread_join(pth_tab[0], NULL);
	pthread_join(pth_tab[1], NULL);

	return 0;
}
