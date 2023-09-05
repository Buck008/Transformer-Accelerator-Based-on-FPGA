#include"matrix.h"


matrix mat_create(int num_of_rows, int num_of_cols){
    matrix A;
    A.num_of_rows = num_of_rows;
    A.num_of_cols = num_of_cols;
    DATA_TYPE * ddrAddr = (DATA_TYPE*) malloc( num_of_rows * num_of_cols * sizeof(DATA_TYPE));
    A.ddrAddr = ddrAddr;
    return A;
}

void mat_setValue(matrix A, int row, int col, DATA_TYPE value){
    if((row > A.num_of_rows-1) || (col > A.num_of_cols -1)){
        printf("mat_setValue: index out of bound, row = %d, col = %d\n",row,col);
        return;
    }
    if(row <0  || col < 0){
        printf("mat_setValue: negative index\n");
        return;
    }
    *(A.ddrAddr + row * A.num_of_cols + col) = value;
}

DATA_TYPE mat_getValue(matrix A, int row, int col){
    if((row > A.num_of_rows-1) || (col > A.num_of_cols -1)){
        printf("mat_getValue: index out of bound, row = %d, col = %d\n",row,col);
        return 0;
    }
        if(row <0  || col < 0){
        printf("mat_getValue: negative index\n");
        return 0;
    }
    return *(A.ddrAddr + row * A.num_of_cols + col);
}

void mat_set(matrix_Ptr A_p, void * addr, int num_of_rows, int num_of_cols){ //注意内存泄漏
    int size = num_of_cols * num_of_rows * sizeof(DATA_TYPE);
    free(A_p->ddrAddr);
    A_p->ddrAddr = (DATA_TYPE *) malloc(size);
    memcpy(A_p->ddrAddr,addr,size);
    A_p->num_of_cols = num_of_cols;
    A_p->num_of_rows = num_of_rows;
    return;
}

void mat_mul(matrix A, matrix B, matrix C, int R_shift){ //A * B = C
    if(A.num_of_cols != B.num_of_rows){
        printf("size mismatch\n");
        return;
    }
    if(A.num_of_rows != C.num_of_rows || B.num_of_cols != C.num_of_cols){
        printf("size mismatch\n");
        return;
    }
    int temp;
    int i;
    int j;
    int k;

    for (i=0;i<C.num_of_rows;i++){
//    	printf("\n");
        for(j=0;j<C.num_of_cols;j++){
            temp=0;
            for(k=0;k<A.num_of_cols;k++){
                temp = temp + mat_getValue(A,i,k)*mat_getValue(B,k,j);
            }
//            printf("temp: %d\n",temp);
            if(R_shift > 0){
            	temp = (temp+(1<<(R_shift-1))) >> R_shift; //四舍五入
            }

            if (temp > MAX_LIMIT){
                temp = MAX_LIMIT;
            }
            if (temp < MIN_LIMIT){
                temp = MIN_LIMIT;
            }
//            printf("%d",temp);
            mat_setValue(C,i,j,temp);
        }
    }
};

void mat_print(matrix A){
	int i,j;
	for(i=0;i<A.num_of_rows;i++){
		printf("row %d: ",i);
		for(j=0;j<A.num_of_cols;j++){
			printf("%7d",(int)mat_getValue(A,i,j));
		}
		printf("\n");
	}
	printf("\n");
}

void mat_free(matrix A){
    free(A.ddrAddr);
}

