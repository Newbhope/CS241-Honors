#include <string.h>	

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <omp.h>

#include "tbb/tick_count.h" 
using tbb::tick_count;

char* map_file(char *filename, int *length_out) 
{
	struct stat file_stat;
	int fd = open(filename, O_RDONLY);
	if (fd == -1) 
	{
		printf("failed to open file: %s\n", filename); 
		exit(1);
	}
	if (fstat(fd, &file_stat) != 0) 
	{
		printf("failed to stat file: %s\n", filename); 
		exit(1);
	}
	off_t length = file_stat.st_size;
	void *file = mmap(0, length, PROT_WRITE, MAP_PRIVATE, fd, 0);
	if (file == (void *)-1) 
	{
		printf("failed to stat file: %s\n", filename); 
		exit(1);
	}

	*length_out = length;
	return (char *)file;
}
__global__ void count(int length, char* file, unsigned* d_1){
	int index=blockIdx.x * blockDim.x + threadIdx.x;
	while(index<length){
		d_1[ file[index] ]++;
		index+=blockDim.x * gridDim.x;
	}
}

int main(int argc, char *argv[]) 
{
	int length = 0;
	bool print = false;
	if (strncmp(argv[1], "-print", 7) == 0) 
	{
		print = true;
		argv = &argv[1];
	}
	char *file = map_file(argv[1], &length);
	unsigned histogram[256] = {0};

	tick_count start = tick_count::now();

	// Your code here! (and maybe elsewhere)
	unsigned* d_1;
	char* d_2;
	cudaMalloc( (void**) &d_2, length+1);
	cudaMalloc( (void**) &d_1, 256*sizeof(unsigned));
	
	cudaMemcpy(d_1, histogram, 256*sizeof(unsigned), cudaMemcpyHostToDevice);
	cudaMemcpy(d_2, file, length+1, cudaMemcpyHostToDevice);
	
	count<<<2, 128>>>(length, d_2, d_1);
	
	cudaMemcpy(histogram, d_1, 256*sizeof(unsigned), cudaMemcpyDeviceToHost);
	
	cudaFree(d_1);
	cudaFree(d_2);
	//not getting right values for some reason
	tick_count end = tick_count::now();

	printf("time = %f seconds\n", (end - start).seconds());  

	if (print) 
	{
		for (int i = 0 ; i < 128 ; i ++) 
		{
			if (histogram[i] != 0) 
			{
				printf("%c (%d): %d\n", i, i, histogram[i]);
			}
		}
	}
}
