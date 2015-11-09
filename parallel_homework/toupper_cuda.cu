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
	int fd = open(filename, O_RDWR);
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
	void *file = mmap(0, length, PROT_WRITE, MAP_SHARED, fd, 0);
	if (file == (void *)-1) 
	{
		printf("failed to stat file: %s\n", filename); 
		exit(1);
	}

	*length_out = length;
	return (char *)file;
}


/*__global__ void cube(float * d_out, float * d_in){
	int idx=threadIdx.x;
    float f=d_in[idx];
    d_out[idx]=f*f*f;
}

int main(int argc, char ** argv) {
	const int ARRAY_SIZE = 64;
	const int ARRAY_BYTES = ARRAY_SIZE * sizeof(float);

	// generate the input array on the host
	float h_in[ARRAY_SIZE];
	for (int i = 0; i < ARRAY_SIZE; i++) {
		h_in[i] = float(i);
	}
	float h_out[ARRAY_SIZE];

	// declare GPU memory pointers
	float * d_in;
	float * d_out;

	// allocate GPU memory
	cudaMalloc((void**) &d_in, ARRAY_BYTES);
	cudaMalloc((void**) &d_out, ARRAY_BYTES);

	// transfer the array to the GPU
	cudaMemcpy(d_in, h_in, ARRAY_BYTES, cudaMemcpyHostToDevice);

	// launch the kernel
	cube<<<1, ARRAY_SIZE>>>(d_out, d_in);

	// copy back the result array to the CPU
	cudaMemcpy(h_out, d_out, ARRAY_BYTES, cudaMemcpyDeviceToHost);

	// print out the resulting array
	for (int i =0; i < ARRAY_SIZE; i++) {
		printf("%f", h_out[i]);
		printf(((i % 4) != 3) ? "\t" : "\n");
	}

	cudaFree(d_in);
	cudaFree(d_out);

	return 0;
}*/
__global__ void upper(int length, char* file){

	int index=blockIdx.x * blockDim.x + threadIdx.x;
	while(index<length){
		if(file[index]>=97 && file[index]<=122){
			file[index]-=32;
		}
		index+=blockDim.x * gridDim.x;
	}

}
int main(int argc, char *argv[]) 
{
	int length = 0;
	char *file = map_file(argv[1], &length);
	//cudaEvent_t start, stop;
	//cudaEventCreate(&start);
	//cudaEventCreate(&stop);
	
	//cudaEventRecord(start);

	tick_count start = tick_count::now();

	// Your code here! (and maybe elsewhere)

	char* d_in;//gpu file pointer
	cudaMalloc( (void**) &d_in, length+1);//not sure if need null terminator

	cudaMemcpy(d_in, file, length+1, cudaMemcpyHostToDevice);//copy file to device

	upper<<<2, 128>>>(length, d_in);
	
	cudaMemcpy(file, d_in, length+1, cudaMemcpyDeviceToHost);//copy modified file back to cpu
	//printf("%c\n", file[1]);


	tick_count end = tick_count::now();
	printf("time = %f seconds\n", (end - start).seconds());  
	
	cudaFree(d_in);

	
	/*cudaEventRecord(stop);
	cudaEventSynchronize(stop);
	float milliseconds=0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	printf("time = %f milliseconds\n", milliseconds);
	*/

}
