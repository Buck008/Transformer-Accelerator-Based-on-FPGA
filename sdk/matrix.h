#ifndef SRC_MATRIX_H_
#define SRC_MATRIX_H_
#include "xil_types.h"
#include <stdio.h>
#include<stdlib.h>
#include <limits.h>
#include "xil_printf.h"
#include <string.h>

#define DATA_TYPE s8
#define MAX_LIMIT 127
#define MIN_LIMIT -128

typedef struct{
    int num_of_rows;
    int num_of_cols;
    DATA_TYPE *ddrAddr;
} matrix, *matrix_Ptr;

matrix mat_create(int num_of_rows, int num_of_cols);
void mat_setValue(matrix A, int row, int col, DATA_TYPE value);
DATA_TYPE mat_getValue(matrix A, int row, int col);
void mat_set(matrix_Ptr A, void * addr, int num_of_rows, int num_of_cols);
void mat_mul(matrix A, matrix B, matrix C, int R_shift);
void mat_free(matrix A);
void mat_print(matrix A);

#endif /* SRC_MATRIX_H_ */
