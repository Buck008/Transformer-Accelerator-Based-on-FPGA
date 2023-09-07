import numpy as np
from pynq import allocate
from pynq import MMIO

A_SIZE = 25
in_F_max_size = 4000 * A_SIZE
in_W_max_size = 4000 * A_SIZE
out_F_max_size = 4000 * A_SIZE
in_F_width_max = 64 * A_SIZE
in_W_width_max  = 64 * A_SIZE
shift_max = 32

def mat_create(shape, data_type = np.int8):
    height = shape[0]
    width = shape[1]
    if height % A_SIZE != 0:
        An_h = height + A_SIZE - height % A_SIZE
    else:
        An_h = height
        
    if width % A_SIZE != 0:
        An_w = width+ A_SIZE - width % A_SIZE
    else:
        An_w = width
    A = allocate(shape=(An_h,An_w), dtype=data_type)
    return [A[0:height,0:width], A]

def mat_setValue(A,B:np.ndarray): #use numpy array to set value
    A[0][:] = B 
    
def mat_getNdarray(A):
    B = np.zeros((A[0].shape[0],A[0].shape[1])) 
    B = A[0].copy()
    return B

def mat_delete(A):
    A[1].freebuffer()
    
def mat_print(A):
    print(A[0])

def mat_mul_soft(A,B,C,shift):
    C0 = A[0].astype(np.int32) @ B[0].astype(np.int32)
    C0 = np.right_shift(C0,shift)
    C0 = np.clip(C0,-128,127)
    C[0][:] = C0 

def ini_MM():
    global MM_ultra 
    global in_f_dma 
    global in_w_dma
    global out_f_dma

    MM_ultra_addr= 0xA0030000
    MM_ultra_addr_range = 0xFFF
    MM_ultra = MMIO(MM_ultra_addr, MM_ultra_addr_range)
    
    global XAXIDMA_IDLE_MASK
    XAXIDMA_IDLE_MASK = 0x00000002
    
    IN_FEATURE_DMA_ADDR = 0xA0000000
    in_f_range = 0x10000
    in_f_dma = MMIO(IN_FEATURE_DMA_ADDR, in_f_range)

    IN_WEIGHT_DMA_ADDR = 0xA0010000
    in_w_range = 0x10000
    in_w_dma = MMIO(IN_WEIGHT_DMA_ADDR, in_w_range)

    OUT_FEATURE_DMA_ADDR = 0xA0020000
    out_f_range = 0x10000
    out_f_dma = MMIO(OUT_FEATURE_DMA_ADDR, out_f_range)
    

def in_feature_transfer(array, start_offset = 0, len = 0):
    start_addr = array.physical_address + start_offset
    if len == 0:
        len = array.nbytes
    array.flush()
    in_f_dma.write(0x0,0x4) #reset
    in_f_dma.write(0x18,start_addr)
    in_f_dma.write(0x0,0x1) #open channel 
    in_f_dma.write(0x28,len)
    
def in_weight_transfer(array, start_offset = 0, len = 0):
    start_addr = array.physical_address + start_offset
    if len == 0:
        len = array.nbytes
    array.flush()
    in_w_dma.write(0x0,0x4) #reset
    in_w_dma.write(0x18,start_addr)
    in_w_dma.write(0x0,0x1) #open channel 
    in_w_dma.write(0x28,len)

def out_feature_transfer(array, start_offset = 0, len = 0):
    start_addr = array.physical_address + start_offset
    if len == 0:
        len = array.nbytes
    out_f_dma.write(0x30,0x4) #reset
    out_f_dma.write(0x48,start_addr)
    out_f_dma.write(0x30,0x1) #open channel 
    out_f_dma.write(0x58,len)
    array.invalidate()
    
def out_feature_wait():
    while False if out_f_dma.read(0x34) & XAXIDMA_IDLE_MASK else True:
        pass
def in_feature_wait():
    while False if in_f_dma.read(0x4) & XAXIDMA_IDLE_MASK else True:
        pass
def in_weight_wait():
    while False if in_w_dma.read(0x4) & XAXIDMA_IDLE_MASK else True:
        pass
    
def mat_mul(A, B, C,shift=0):
    A = A[1]
    B = B[1]
    C = C[1]
    A_h = A.shape[0]
    A_w = A.shape[1]
    B_h = B.shape[0]
    B_w = B.shape[1]
    if A_h == 1:
        print("\033[31mThe height of matrix A can not be 1\033[0m")
        return 
    if A_w > in_F_width_max:
        print("\033[31mThe width of matrix A is too large\033[0m")
        return 
    if A_w != B_h:
        print("\033[31mThe width of matrix A is not equal to the height of matrix B\033[0m")
        return
    if A_w % A_SIZE != 0 :
        print("\033[31mThe width of matrix A is not the integer multiple of A_SIZE\033[0m")
        return
    if B_w % A_SIZE != 0 :
        print("\033[31mThe width of matrix B is not the integer multiple of A_SIZE\033[0m")
        return
    if A.nbytes > in_F_max_size:
        print("\033[31mThe size of matrix A is too large\033[0m")
        return
    if B.nbytes > in_W_max_size:
        print("\033[31mThe size of matrix B is too large\033[0m")
        return
    if C.nbytes > in_W_max_size:
        print("\033[31mThe size of matrix C is too large\033[0m")
        return
    F_width_block_num = int(A_w / A_SIZE)
    W_width_block_num = int(B_w /A_SIZE)
    MM_ultra.write(0x0,shift)
    MM_ultra.write(0x4,A_h)
    MM_ultra.write(0x8,F_width_block_num)
    MM_ultra.write(0xc,W_width_block_num)
    out_feature_transfer(C)
    in_feature_transfer(A)
    in_weight_transfer(B)
    out_feature_wait()