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
        while(1);
}

int main(int argc, char **argv)
{
        int i;
        pthread_t *threads;
        int *ids;

        if (argc != 2) {
                fprintf(stderr, "Usage: %s <# of threads>\n", argv[0]);
                exit(-1);
        }
        nr_threads = atoi(argv[1]);
        threads = (pthread_t *)malloc(nr_threads * sizeof(pthread_t));

        for (i=0 ; i < nr_threads ; i++) {
                pthread_create(threads + i, NULL, worker, NULL);
        }

        for (i=0 ; i < nr_threads ; i++) {
                pthread_join(threads[i], NULL);
        }

        free(threads);

	return 0;
}
