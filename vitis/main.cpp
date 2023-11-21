#include "Matrix.h"
#include "stdio.h"
#include <stdlib.h>
int main(){
	u32 IN_ROWS_NUM = 121;
	u32 IN_COLS_NUM = 311;
	u32 OUT_COLS_NUM = 72;

	int R_shift = 0;

    u32 i;
    u32 j;
    Matrix A(IN_ROWS_NUM, IN_COLS_NUM);
    Matrix B(IN_COLS_NUM, OUT_COLS_NUM);
    Matrix C(IN_ROWS_NUM, OUT_COLS_NUM);
    Matrix C_hard(IN_ROWS_NUM, OUT_COLS_NUM);
	for(i=0;i<IN_ROWS_NUM;i++){
		for(j=0;j<IN_COLS_NUM;j++){
			DATA_TYPE value = rand()%256-128;//rand()%16-7;
//			DATA_TYPE value = (i * A_SIZE +j + 128)%256 - 128;
//			DATA_TYPE value = 1;
			A.set_value(i,j,value);
		}
	}

	for(i=0;i<IN_COLS_NUM;i++){
		for(j=0;j<OUT_COLS_NUM;j++){
			DATA_TYPE value = rand()%256-128;//rand()%16-7;
//			DATA_TYPE value = (i * A_SIZE +j + 128)%256 - 128;
//			DATA_TYPE value = 2;
			B.set_value(i,j,value);
		}
	}

	Matrix_mul_soft(A, B, C, R_shift);
	Matrix_mul_hard(A, B, C_hard, R_shift);
	bool result = Matrix_compare(C, C_hard);
	if(result){
		printf("Right!");
	}else{
		printf("Wrong!");
	}

	return 0;
}
