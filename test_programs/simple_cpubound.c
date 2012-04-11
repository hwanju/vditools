#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <sched.h>
#include <sys/syscall.h>

int nr_threads;
int is_pinned;

pthread_barrier_t barrier;

void *worker(void *arg) {
        int id = *(int *)arg;

        if (is_pinned) {
                cpu_set_t cpuset;
                CPU_ZERO(&cpuset);
                CPU_SET(id, &cpuset);
	        if (sched_setaffinity(0, sizeof(cpu_set_t), &cpuset))
                        perror("sched_setaffinity");
        }
        while(1);
}

int main(int argc, char **argv)
{
        int i;
        pthread_t *threads;
        int *ids;

        if (argc < 2) {
                fprintf(stderr, "Usage: %s <# of threads> [1=affinity(default: 0=no affinity)]] \n", argv[0]);
                exit(-1);
        }
        nr_threads = atoi(argv[1]);
        if (argc > 2)
                is_pinned = atoi(argv[2]);
        threads = (pthread_t *)malloc(nr_threads * sizeof(pthread_t));
        ids = (int *)malloc(nr_threads * sizeof(int));

        for (i=0 ; i < nr_threads ; i++) {
                ids[i] = i;
                pthread_create(threads + i, NULL, worker, ids + i);
        }

        for (i=0 ; i < nr_threads ; i++) {
                pthread_join(threads[i], NULL);
        }

        free(threads);
        free(ids);

	return 0;
}
