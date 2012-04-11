#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <sched.h>
#include <sys/syscall.h>

#define COMPUT_ITER 1000000
unsigned long comput_iter = COMPUT_ITER;
int is_skewed;
int is_pinned;
int nr_threads;

pthread_barrier_t barrier;

void *worker(void *arg) {
        int n = 0;
        int id = *(int *)arg;
        int iter = comput_iter;

        if (is_skewed)
                iter = id * (comput_iter / nr_threads);

        printf("id%d: # of iterations = %d\n", id, iter);

        if (is_pinned) {
                cpu_set_t cpuset;
                CPU_ZERO(&cpuset);
                CPU_SET(id-1, &cpuset);
	        if (sched_setaffinity(0, sizeof(cpu_set_t), &cpuset))
                        perror("sched_setaffinity");
        }

        while(1) {
                int i;
                for (i=0 ; i < iter; i++);
                pthread_barrier_wait(&barrier);
                //printf("tid=%d %dth barrier\n", (pid_t)syscall(SYS_gettid), n);
                n++;
        }
}

int main(int argc, char **argv)
{
        int i;
        pthread_t *threads;
        int *ids;

        if (argc < 4) {
                fprintf(stderr, "Usage: %s <# of threads> <0=balanced or 1=skewed> <0=no affinity or 1=affinity> [computation iterations(=%d)]\n", argv[0], COMPUT_ITER);
                exit(-1);
        }
        nr_threads = atoi(argv[1]);
        is_skewed = atoi(argv[2]);
        is_pinned = atoi(argv[3]);

        if (argc > 4) 
                comput_iter = (unsigned long)atol(argv[4]);

        printf("nr_threads=%d comput_iter=%lu %s %s\n", 
                        nr_threads, comput_iter, is_skewed ? "skewed" : "balanced", is_pinned ? "pinned" : "nonpinned");

        threads = (pthread_t *)malloc(nr_threads * sizeof(pthread_t));
        ids = (int *)malloc(nr_threads * sizeof(int));

        pthread_barrier_init(&barrier, NULL, nr_threads);

        for (i=0 ; i < nr_threads ; i++) {
                ids[i] = i + 1;
                pthread_create(threads + i, NULL, worker, ids + i);
        }

        for (i=0 ; i < nr_threads ; i++) {
                pthread_join(threads[i], NULL);
        }

        free(threads);
        free(ids);

	return 0;
}
