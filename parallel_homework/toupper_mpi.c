#include <string.h>
#include "mpi.h"

#include <stdio.h>      
#include <unistd.h>     
#include <stdlib.h>     
#include <ctype.h>      
#include <sys/types.h>  
#include <sys/mman.h>   
#include <sys/stat.h>   
#include <fcntl.h>      

#define min(a,b) (a) < (b) ? (a) : (b)

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
		printf("failed to mmap file: %s\n", filename); 
		exit(1);
	}

	*length_out = length;
	return (char *)file;
}

int main(int argc, char *argv[]) 
{
	//size=command line param
	int rank;
	int size;
	double max_time;

	MPI_Init( &argc, &argv );
	MPI_Comm_size( MPI_COMM_WORLD, &size );
	MPI_Comm_rank( MPI_COMM_WORLD, &rank );

	int length = 0;
	char* file = map_file(argv[1], &length);

	double start = MPI_Wtime();

	//printf("Size: %d Rank: %d\n", size, rank);

	//char buffer[100];

	// Your code here!
	MPI_Status stat;
	int number;
	for(int i=0; i<size; i++){
		if(i==rank){
			for(int j=i*length/size; j<(i+1)*length/size; j++){
				file[j]=toupper(file[j]);
			}
		}
	}
	

	double my_time = MPI_Wtime() - start;
	MPI_Reduce(&my_time, &max_time, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

	MPI_Finalize();

	if (rank == 0)
		printf("time = %f seconds\n", max_time);  
}
