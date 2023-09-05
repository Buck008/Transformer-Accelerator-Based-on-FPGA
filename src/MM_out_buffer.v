`timescale 1ns / 1ps

module MM_out_buffer
#(              
    parameter integer                                        data_width = 8,
    parameter integer                                        OUT_Feature_Block_num = 2400,
    parameter integer                                        OUT_MEM_WIDTH = 32,
    parameter integer                                        A_size =  2,
    parameter integer                                        shift_width = 20,
    parameter integer                                        log2_array_m = 4,
    parameter integer                                        F_length_width = 10,
    parameter integer                                        F_width_block_num_width = 5,
    parameter integer                                        W_width_block_num_width = 5
)(
    input                                                    clk,
    input                                                    rst_n,
        
    input [shift_width - 1:0]                                shift,
    input [F_length_width-1:0]                               F_length, //1 ~ block_num *A_size
    input [F_width_block_num_width-1:0]                      F_width_block_num, //1 ~ block_num
    input [W_width_block_num_width-1:0]                      W_width_block_num, //1 ~ block_num
            
    input                                                    in_data_valid,
    input                                                    in_data_last,
    input [A_size*(log2_array_m+data_width*2)-1:0]           in_data,

    output reg                                               out_data_valid,
    output                                                   out_data_last,
    input                                                    out_data_ready,
    output reg [A_size * data_width -1:0]                    out_data
);

function integer clogb2 (input integer bit_depth);              
begin:log
    automatic integer temp;
    temp = 0;                                                        
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)begin
        if(bit_depth[0] & bit_depth!=1)
            temp = 1;                   
        bit_depth = bit_depth >> 1;
    end
    clogb2 = clogb2 + temp - 1;                                   
end                                                   
endfunction
localparam integer F_size_width = clogb2(OUT_Feature_Block_num);

(*ram_style="block"*) reg  [A_size*OUT_MEM_WIDTH-1:0]                  F_array [OUT_Feature_Block_num-1 : 0];

reg  [F_size_width-1:0]                                                  out_F_block_size;
reg  [F_size_width-1:0]                                                  B_addr;
reg  [F_size_width-1:0]                                                  C_addr;
wire [A_size*(log2_array_m+data_width*2)-1:0]                            A;
wire [A_size*OUT_MEM_WIDTH-1:0]                                          A_in_adder; //bit width extension
wire [A_size*OUT_MEM_WIDTH-1:0]                                          B;
wire [A_size*OUT_MEM_WIDTH-1:0]                                          C;
reg  [F_width_block_num_width-1:0]                                       last_cnt;

reg                                                                      start_trans;                   

reg                                                                      F_array_out_valid;
reg                                                                      F_array_out_valid_delay1;
reg                                                                      F_array_out_valid_delay2;
wire                                                                     F_array_out_last_delay2;
reg  [F_size_width-1:0]                                                  F_array_out_cnt;
reg  [F_size_width-1:0]                                                  F_array_out_cnt_delay1;


wire [A_size*OUT_MEM_WIDTH-1:0]                                          out_F_data;
reg  [A_size*OUT_MEM_WIDTH-1:0]                                          out_F_data_delay1;
wire [A_size * data_width -1:0]                                          shifted_data;
reg  [F_size_width-1:0]                                                  out_data_cnt;

reg  [F_size_width-1:0]                                                  in_F_array_addr;
reg  [A_size*OUT_MEM_WIDTH-1:0]                                          in_F_array_data;

reg  [W_width_block_num_width-1:0]                                       out_data_col_addr;
reg  [F_length_width-1:0]                                                out_data_row_addr;
wire [F_size_width-1:0]                                                  out_data_addr;
reg  [F_size_width-1:0]                                                  clear_addr;

wire [F_size_width-1:0]                                                  out_F_array_addr;
reg  [A_size*OUT_MEM_WIDTH-1:0]                                          out_F_array_data;


assign A = in_data;
// assign start_trans = last_cnt == F_width_block_num;
assign F_array_out_last_delay2 = F_array_out_cnt_delay1 == out_F_block_size;
assign out_data_addr = out_data_col_addr * F_length + out_data_row_addr;
assign out_data_last = (out_data_cnt == out_F_block_size-1) & out_data_ready;

genvar i;
generate
    for(i=0; i<OUT_Feature_Block_num; i=i+1 )begin
        initial begin F_array[i]<=0;end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        start_trans <= 0;
    else if (F_array_out_valid)
        start_trans <= 0;
    else if (last_cnt == F_width_block_num)
        start_trans <= 1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        F_array_out_valid <= 0;
    else if(start_trans & out_data_ready)
        F_array_out_valid <= 1;
    else if(F_array_out_cnt == out_F_block_size - 1 & (F_array_out_valid&out_data_ready))
        F_array_out_valid <= 0;
    else 
        F_array_out_valid <= F_array_out_valid;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        F_array_out_valid_delay1 <= 0;
    else if (F_array_out_cnt_delay1 ==out_F_block_size-1 &(F_array_out_valid_delay1&out_data_ready))
        F_array_out_valid_delay1<=0;
    else if (F_array_out_valid & out_data_ready)
        F_array_out_valid_delay1 <= 1;
    else
        F_array_out_valid_delay1<=F_array_out_valid_delay1;
end

initial F_array_out_valid_delay2 =0;
always @(posedge clk ) begin
    if(out_data_ready)
        F_array_out_valid_delay2<=F_array_out_valid_delay1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        F_array_out_cnt <= 0;
    else if (F_array_out_cnt == out_F_block_size)
        F_array_out_cnt <= 0;
    else if (F_array_out_valid & out_data_ready)
        F_array_out_cnt <= F_array_out_cnt + 1;
    else
        F_array_out_cnt <= F_array_out_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        out_data_cnt <= 0;
    else if (out_data_cnt == out_F_block_size)
        out_data_cnt <= 0;
    else if (out_data_valid & out_data_ready)
        out_data_cnt <= out_data_cnt + 1;
    else
        out_data_cnt <= out_data_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        F_array_out_cnt_delay1 <= 0;
    else if (F_array_out_cnt_delay1 == out_F_block_size)
        F_array_out_cnt_delay1 <= 0;
    else if (F_array_out_valid_delay1 & out_data_ready)
        F_array_out_cnt_delay1 <= F_array_out_cnt_delay1 + 1;
    else
        F_array_out_cnt_delay1 <= F_array_out_cnt_delay1;
end

always @(posedge clk ) begin
    if(F_array_out_valid_delay1 & out_data_ready)
        out_F_data_delay1 <= out_F_data;
    else 
        out_F_data_delay1 <= out_F_data_delay1;
end


always @(posedge clk ) begin
    if(F_array_out_valid_delay2 & out_data_ready)
        out_data <= shifted_data;
    else
        out_data <= out_data;
end

initial out_data_valid = 0;
always @(posedge clk ) begin
    if(out_data_ready)
        out_data_valid <= F_array_out_valid_delay2;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        out_data_col_addr <= 0;
    else if (F_array_out_last_delay2)
        out_data_col_addr <= 0;
    else if (out_data_col_addr == W_width_block_num-1 & out_data_row_addr == F_length - 1 )
        out_data_col_addr <= out_data_col_addr;
    else if (out_data_col_addr == W_width_block_num-1 & (F_array_out_valid & out_data_ready))
        out_data_col_addr <= 0;
    else if (F_array_out_valid & out_data_ready)
        out_data_col_addr <= out_data_col_addr+1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        out_data_row_addr <= 0;
    else if (F_array_out_last_delay2)
        out_data_row_addr <= 0;
    else if (out_data_row_addr == F_length - 1)
        out_data_row_addr<=out_data_row_addr;
    else if ((F_array_out_valid & out_data_ready)&
             ((out_data_col_addr == W_width_block_num-1 ) | ( W_width_block_num == 1 ))
             )
        out_data_row_addr <= out_data_row_addr + 1;
    else
        out_data_row_addr <= out_data_row_addr;
end

always @(*) begin
    if(in_data_valid)
        B_addr = C_addr + 1;
    else 
        B_addr = C_addr;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        clear_addr <= 0;
    // else if (out_data_last)
    //     clear_addr <= 0;
    else if (F_array_out_last_delay2)
        clear_addr <= out_F_block_size - 1;
    // else if (out_data_addr == out_F_block_size - 1)
    else if(out_data_col_addr == W_width_block_num-1 & out_data_row_addr == F_length - 1)
        clear_addr <= clear_addr;
    else if (F_array_out_valid & out_data_ready)
        clear_addr <= out_data_addr;
end

always @(*) begin
    case (in_data_valid)
        1'b1: in_F_array_addr = C_addr;
        1'b0: in_F_array_addr = clear_addr; 
        default: in_F_array_addr = 0;
    endcase
end

always @(posedge clk ) begin  //write port
    if(in_data_valid)
        F_array[in_F_array_addr] <= in_F_array_data;
    else if (F_array_out_valid_delay1 | out_data_valid & out_data_ready)
        F_array[in_F_array_addr] <=in_F_array_data;
end

always @(*) begin
    if(in_data_valid)
        in_F_array_data = C;
    else
        in_F_array_data = 0;
end

assign out_F_array_addr = (F_array_out_valid_delay2 | F_array_out_valid)? out_data_addr : B_addr;

always @(posedge clk) begin //read port
    if (F_array_out_valid & ~out_data_ready)
        out_F_array_data <= out_F_array_data;
    else
        out_F_array_data<=F_array[out_F_array_addr];
end
                            
assign B = out_F_array_data;
assign out_F_data = out_F_array_data;

initial out_F_block_size =0;
always @(posedge clk ) begin
    out_F_block_size <= F_length * W_width_block_num;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        C_addr <= 0;
    else if (in_data_last)
        C_addr <= 0;
    else if(in_data_valid)
        C_addr <= C_addr + 1;
    else
        C_addr <= C_addr;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        last_cnt <= 0;
    else if (last_cnt == F_width_block_num)
        last_cnt <= 0;
    else if (in_data_last)
        last_cnt <= last_cnt + 1;
    else 
        last_cnt <= last_cnt;
end


AdderS 
#(
    .data_width(OUT_MEM_WIDTH),
    .A_size(A_size)
)U_Adders 
(
    .A(A_in_adder),
    .B(B),
    .C(C)
);

generate
    for(i=0;i<A_size;i=i+1)begin
        assign A_in_adder[i*OUT_MEM_WIDTH +: OUT_MEM_WIDTH] = $signed(A[i*(log2_array_m+data_width*2) +: (log2_array_m+data_width*2)]);
    end
endgenerate

generate
    for(i=0;i<A_size;i=i+1)begin:right_shifter_u
        right_shifter 
        #(
            .before_data_width(OUT_MEM_WIDTH),
            .after_data_width(data_width),
            .shift_width(shift_width)
        )u_right_shifter(
            .shift(shift),
            .data_in(out_F_data_delay1[i*OUT_MEM_WIDTH +: OUT_MEM_WIDTH]),
            .data_out(shifted_data[i*data_width+:data_width])
        );
    end
endgenerate
endmodule