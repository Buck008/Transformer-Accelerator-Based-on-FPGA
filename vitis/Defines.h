#ifndef SRC_DEFINES_H_
#define SRC_DEFINES_H_
#include "xparameters.h"
#include "xaxidma_hw.h"
#define CACHE_LINE_SIZE 32
#define DATA_TYPE s8
#define MAX_LIMIT 127
#define MIN_LIMIT -128

#define MM_ADDR 			XPAR_MM_ULTRA_TOP_0_BASEADDR
#define SHIFT_ADDR 			MM_ADDR
#define FL_ADDR 			(MM_ADDR + 0x04)
#define FWBN_ADDR 		    (MM_ADDR +0x08)
#define WWBN_ADDR	        (MM_ADDR +0x0c)

#define WEIGHT_DMA_ADDR 	XPAR_AXI_DMA_1_BASEADDR
#define WEIGHT_MM2S_DMACR  	(WEIGHT_DMA_ADDR + XAXIDMA_TX_OFFSET + XAXIDMA_CR_OFFSET) //MM2S DMA Control register
#define WEIGHT_MM2S_DMASR  	(WEIGHT_DMA_ADDR + XAXIDMA_TX_OFFSET + XAXIDMA_SR_OFFSET) //MM2S DMA Status register
#define WEIGHT_MM2S_SA	    (WEIGHT_DMA_ADDR + XAXIDMA_TX_OFFSET + XAXIDMA_SRCADDR_OFFSET) //MM2S Source Address
#define WEIGHT_MM2S_LENGTH 	(WEIGHT_DMA_ADDR + XAXIDMA_TX_OFFSET + XAXIDMA_BUFFLEN_OFFSET) //MM2S Transfer Length (Bytes)

#define FEATURE_DMA_ADDR 	XPAR_AXI_DMA_0_BASEADDR
#define FEATURE_MM2S_DMACR  (FEATURE_DMA_ADDR + XAXIDMA_TX_OFFSET + XAXIDMA_CR_OFFSET) //MM2S DMA Control register
#define FEATURE_MM2S_DMASR  (FEATURE_DMA_ADDR + XAXIDMA_TX_OFFSET + XAXIDMA_SR_OFFSET) //MM2S DMA Status register
#define FEATURE_MM2S_SA	    (FEATURE_DMA_ADDR + XAXIDMA_TX_OFFSET + XAXIDMA_SRCADDR_OFFSET) //MM2S Source Address
#define FEATURE_MM2S_LENGTH (FEATURE_DMA_ADDR + XAXIDMA_TX_OFFSET + XAXIDMA_BUFFLEN_OFFSET) //MM2S Transfer Length (Bytes)

#define RESULT_DMA_ADDR		XPAR_AXI_DMA_2_BASEADDR
#define RESULT_S2MM_DMACR  (RESULT_DMA_ADDR + XAXIDMA_RX_OFFSET + XAXIDMA_CR_OFFSET) //S2MM DMA Control register
#define RESULT_S2MM_DMASR  (RESULT_DMA_ADDR + XAXIDMA_RX_OFFSET + XAXIDMA_SR_OFFSET) //S2MM DMA Status register
#define RESULT_S2MM_DA	    (RESULT_DMA_ADDR + XAXIDMA_RX_OFFSET + XAXIDMA_SRCADDR_OFFSET) //S2MM Destination Address
#define RESULT_S2MM_LENGTH (RESULT_DMA_ADDR + XAXIDMA_RX_OFFSET + XAXIDMA_BUFFLEN_OFFSET) //S2MM Transfer Length (Bytes)


//SA parameters
#define A_SIZE 16
#define W_block_num 4096
#define F_in_block_num 4096
#define F_out_Block_num 4096
#define F_length_width 10
#define F_width_block_num_width 6
#define W_width_block_num_width 6
#define shift_width 5

//matrix size limits
#define F_IN_MATRIX_SIZE_MAX (F_in_block_num * A_SIZE)
#define W_MATRIX_SIZE_MAX (W_block_num * A_SIZE)
#define F_OUT_MATRIX_SIZE_MAX (F_out_Block_num * A_SIZE)
#define F_LENGTH_MAX (2 ** F_length_width)
#define F_WIDTH_MAX ((2 ** F_width_block_num_width) * A_SIZE)
#define W_LENGTH_MAX F_WIDTH_MAX
#define W_WIDTH_MAX ((2 ** W_width_block_num_width) * A_SIZE)


#endif /* SRC_DEFINES_H_ */
