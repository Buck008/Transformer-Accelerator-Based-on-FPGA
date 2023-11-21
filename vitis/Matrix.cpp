#include "Matrix.h"
#include "xparameters.h"
#include "Defines.h"
#include <stdio.h>
#include "xil_io.h"
#include "xtime_l.h"
#include "xil_cache.h"
#include <string.h>

Matrix::Matrix(int rows, int cols) {
	this->rows = rows;
	this->cols= cols;
	this->real_cols = (cols / A_SIZE + (cols % A_SIZE != 0 ? 1 : 0)) * A_SIZE;
	this->real_rows = (rows / A_SIZE + (rows % A_SIZE != 0 ? 1 : 0)) * A_SIZE;
	this->real_size = real_cols * real_rows;
	this->base_addr = new DATA_TYPE[real_rows * real_cols](); //initialize to 0
}

Matrix::~Matrix() {
    delete[] base_addr;
}

int Matrix::get_real_cols() const{
	return this->real_cols;
}

int Matrix::get_real_rows() const{
	return this->real_rows;
}

int Matrix::get_real_size() const{
	return this->real_size;
}

DATA_TYPE * Matrix::get_base_addr() const{
	return this->base_addr;
}

void Matrix::set_value(int row, int col, DATA_TYPE value){
	*(this->base_addr + row * this->real_cols + col)=value;
}

DATA_TYPE Matrix::get_value(int row, int col){
	return *(this->base_addr + row * this->real_cols + col);
}

void Matrix::mat_print(){
	for(int i = 0; i < this->rows; i++){
		for(int j = 0; j < this->cols; j++){
			printf("%d, ", this->get_value(i,j));
		}
		printf("\n");
	}
}
bool Matrix_compare(const Matrix &A, const Matrix &B){
	if(A.rows != B.rows){
		printf("size mismatch\n");
	    return FALSE;
	}
	if(A.cols != B.cols){
		printf("size mismatch\n");
	    return FALSE;
	}
	int result = memcmp(A.get_base_addr(), B.get_base_addr(), A.get_real_size());
	return (bool)result;
}
void Matrix_mul_soft(Matrix &A, Matrix &B, Matrix &C, int R_shift){ //A*B=C
	if(A.cols != B.rows){
		printf("size mismatch\n");
	    return;
	}
	if(A.rows != C.rows || B.cols != C.cols){
		printf("size mismatch\n");
	    return;
	}
	int temp;
	int i;
	int j;
	int k;

	for (i=0;i<C.rows;i++){
//    	printf("\n");
		for(j=0;j<C.cols;j++){
			temp=0;
	        for(k=0;k<A.cols;k++){
	        	temp = temp + A.get_value(i,k)*B.get_value(k,j);
	        }
//	        printf("temp: %d\n",temp);
	        if(R_shift > 0){
	        	temp = (temp+(1<<(R_shift-1))) >> R_shift; //rounding off
	        }
	        if (temp > MAX_LIMIT){
	        	temp = MAX_LIMIT;
	        }
	        if (temp < MIN_LIMIT){
	            temp = MIN_LIMIT;
	        }
//          printf("%d",temp);
	        C.set_value(i,j,temp);
	    }
	}
}

void Matrix_mul_hard(Matrix &A, Matrix &B, Matrix &C, int R_shift){//A*B=C
	if(A.cols != B.rows){
		printf("size mismatch\n");
	    return;
	}
	if(A.rows != C.rows || B.cols != C.cols){
		printf("size mismatch\n");
	    return;
	}
	u32 weight_buffer;
	u32 feature_in_buffer;
	u32 feature_out_buffer;
	int weight_size;
	int feature_in_size;
	int feature_out_size;

	weight_buffer = (u32)B.get_base_addr();
	feature_in_buffer = (u32)A.get_base_addr();
	feature_out_buffer = (u32)C.get_base_addr();

	weight_size = B.get_real_size();
	feature_in_size = A.get_real_size();
	feature_out_size = C.get_real_size();

	u32 shift = R_shift;
	u32 in_rows_num = A.get_real_rows();
	u32 F_width_block_num = A.get_real_cols() / A_SIZE;
	u32 W_width_block_num = B.get_real_cols() / A_SIZE;

	Xil_DCacheFlushRange(weight_buffer,weight_size);
	Xil_DCacheFlushRange(feature_in_buffer,feature_in_size);
	Xil_DCacheFlushRange(feature_out_buffer,feature_out_size);

	//set control register value
	Xil_Out32(SHIFT_ADDR,shift);
	Xil_Out32(FL_ADDR,in_rows_num);
	Xil_Out32(FWBN_ADDR,F_width_block_num);
	Xil_Out32(WWBN_ADDR,W_width_block_num);

	//first open receive channel
	Xil_Out32(RESULT_S2MM_DMACR, 0x4);//reset
	Xil_Out32(RESULT_S2MM_DA, feature_out_buffer); //set addr
	Xil_Out32(RESULT_S2MM_DMACR, 0x1);  //open channel
	Xil_Out32(RESULT_S2MM_LENGTH,feature_out_size); //set length

	Xil_Out32(WEIGHT_MM2S_DMACR, 0x4);
	Xil_Out32(WEIGHT_MM2S_SA, weight_buffer);
	Xil_Out32(WEIGHT_MM2S_DMACR, 0x1);
	Xil_Out32(WEIGHT_MM2S_LENGTH,weight_size);

	Xil_Out32(FEATURE_MM2S_DMACR, 0x4);
	Xil_Out32(FEATURE_MM2S_SA, feature_in_buffer);
	Xil_Out32(FEATURE_MM2S_DMACR, 0x1);
	Xil_Out32(FEATURE_MM2S_LENGTH,feature_in_size);


	while((Xil_In32(RESULT_S2MM_DMASR) & XAXIDMA_IDLE_MASK) ? FALSE : TRUE){
		printf("*\n");
	};
}


