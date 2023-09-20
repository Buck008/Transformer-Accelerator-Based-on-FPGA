#include "xparameters.h"
#include "xil_io.h"
#include "stdio.h"
#include "xtime_l.h"
#include <stdlib.h>
#include "xil_cache.h"
#include "xil_types.h"
#include "xaxidma_hw.h"
#include "sleep.h"
#include "matrix.h"
#include "defines.h"

#define CAL_SOFT 0
XTime t1,t2,t3,t4,t5,t6;

int main()
{
int times = 10;
int a;
for(a=0;a<times;a++){
	printf("/*************************************************************/\n");
	printf("Hello,%d\n",a);
	u32 shift = 10;
	u32 IN_ROWS_NUM = 240;
	u32 IN_COLS_NUM = 240;
	u32 OUT_COLS_NUM = 240;

	u32 F_width_block_num = IN_COLS_NUM / A_SIZE;
	u32 W_width_block_num = OUT_COLS_NUM /A_SIZE;
	Xil_DCacheDisable();
	int feature_in_size = IN_ROWS_NUM * IN_COLS_NUM;
	int feature_out_size = IN_ROWS_NUM * OUT_COLS_NUM;
	int weight_size = IN_COLS_NUM * OUT_COLS_NUM;

#if CAL_SOFT
    matrix A = mat_create(IN_ROWS_NUM,IN_COLS_NUM);
    matrix B = mat_create(IN_COLS_NUM,OUT_COLS_NUM);
    matrix C = mat_create(IN_ROWS_NUM,OUT_COLS_NUM);
#endif
    s8 *weight_buffer ;
    s8 *feature_in_buffer;
    s8 *feature_out_buffer;

	XTime_GetTime(&t1);
    feature_in_buffer = (s8*) malloc(feature_in_size);
    weight_buffer =  (s8*) malloc(weight_size);
    feature_out_buffer = (s8*) malloc(feature_out_size);

	XTime_GetTime(&t2);
    int i;
    int j;
	for(i=0;i<IN_ROWS_NUM;i++){
		for(j=0;j<IN_COLS_NUM;j++){
			int value = rand()%256-128;//rand()%16-7;
//			int value = (i * A_SIZE +j + 128)%256 - 128;
//			int value = 1;
			*(feature_in_buffer + i * IN_COLS_NUM + j)=value;
#if CAL_SOFT
			mat_setValue(A,i,j,value);
#endif
		}
	}
	for(i=0;i<IN_COLS_NUM;i++){
		for(j=0;j<OUT_COLS_NUM;j++){
			int value = rand()%256-128;//rand()%16-7;
//			int value = (i * A_SIZE +j + 128)%256 - 128;
//			int value = 2;
			*(weight_buffer + i * OUT_COLS_NUM + j)=value;
#if CAL_SOFT
			mat_setValue(B,i,j,value);
#endif
		}
	}

	XTime_GetTime(&t3);
	Xil_Out32(SHIFT_ADDR,shift);
	Xil_Out32(FL_ADDR,IN_ROWS_NUM);
	Xil_Out32(FWBN_ADDR,F_width_block_num);
	Xil_Out32(WWBN_ADDR,W_width_block_num);


	//先打开接受通道
	Xil_Out32(RESULT_S2MM_DMACR, 0x4);//reset
	Xil_Out32(RESULT_S2MM_DA, (u32)feature_out_buffer);
	Xil_Out32(RESULT_S2MM_DMACR, 0x1); 
	Xil_Out32(RESULT_S2MM_LENGTH,feature_out_size); 

	Xil_Out32(WEIGHT_MM2S_DMACR, 0x4);//reset
	Xil_Out32(WEIGHT_MM2S_SA, (u32)weight_buffer); 
	Xil_Out32(WEIGHT_MM2S_DMACR, 0x1);  
	Xil_Out32(WEIGHT_MM2S_LENGTH,weight_size); 

	Xil_Out32(FEATURE_MM2S_DMACR, 0x4);//reset
	Xil_Out32(FEATURE_MM2S_SA, (u32)feature_in_buffer); 
	Xil_Out32(FEATURE_MM2S_DMACR, 0x1);  
	Xil_Out32(FEATURE_MM2S_LENGTH,feature_in_size); 


	while((Xil_In32(RESULT_S2MM_DMASR) & XAXIDMA_IDLE_MASK) ? FALSE : TRUE){
		printf("*\n");
	};
//	sleep(1);
	XTime_GetTime(&t4);

	XTime_GetTime(&t5);
#if CAL_SOFT
	mat_mul(A,B,C,shift);
#endif
	XTime_GetTime(&t6);


	float T_allocBuffer = (float)(t2-t1)*(1000000 / COUNTS_PER_SECOND);
	float T_hard = (float)(t4-t3)*1000000 / COUNTS_PER_SECOND;
//	float T_reshapeBuffer = (float)(t5-t4)*1000000 / COUNTS_PER_SECOND;
#if CAL_SOFT
	float T_soft = (float)(t6-t5)*1000000 / COUNTS_PER_SECOND;
#endif

#if CAL_SOFT
	unsigned long error_num = 0;
	for(i=0;i<IN_ROWS_NUM;i++){
		for(j=0;j<OUT_COLS_NUM;j++){
			int temp = (int)*(feature_out_buffer + i * OUT_COLS_NUM + j)- mat_getValue(C,i,j);
			if(temp!=0){
				error_num++;
				if(error_num < 1000){
					printf("row %d, col %d: %7d,%7d\n",i,j,temp,mat_getValue(C,i,j));
				}
			}

		}
	}
#endif
	printf("Time consumed for allocating memory: %.2fus\n",T_allocBuffer);
	printf("Time consumed in PL cal: %.2fus\n",T_hard);
#if CAL_SOFT
	printf("Time consumed in PS cal: %.2fus\n",T_soft);
#endif
	free(weight_buffer);
	free(feature_in_buffer);
	free(feature_out_buffer);
#if CAL_SOFT
	mat_free(A);
	mat_free(B);
	mat_free(C);
#endif
	printf("END\n");
	printf("/*************************************************************/\n\n\n\n\n\n\n");
}
	return 0;
}
