`timescale 1ns / 1ps
`define IDLE 2'b00
`define IN_DATA 2'b01
`define CAL 2'b11
// reg [A_size * data_width - 1:0] in_F_array [Feature_Width_Block_num * Feature_Length : 0];
// reg [A_size * data_width - 1:0] in_W_array [A_size * Weight_Width_Block_num * Feature_Width_Block_num : 0];
module MM_in_buffer
#(
    parameter integer                               A_size = 24,
    parameter integer                               data_width = 8,
    parameter integer                               Weight_Block_num = 2400, 
    parameter integer                               IN_Feature_Block_num = 2400,
    parameter integer                               F_length_width = 10,
    parameter integer                               F_width_block_num_width = 5,
    parameter integer                               W_width_block_num_width = 5
)(
    input                                           clk,
    input                                           rst_n,
    
    input [W_width_block_num_width-1:0]             W_width_block_num, //1 ~ block_num


    input [F_width_block_num_width-1:0]             F_width_block_num, //1 ~ block_num
    input [F_length_width-1:0]                      F_length, //1 ~ block_num *A_size

    input                                           MM_buffer_out_last,

    input                                           in_F_valid,
    input                                           in_F_last,
    output                                          in_F_ready,
    input [A_size * data_width - 1:0]               in_F_data,

    input                                           in_W_valid,
    input                                           in_W_last,
    output                                          in_W_ready,
    input [A_size * data_width - 1:0]               in_W_data,

    output reg                                      in_MM_buffer_F_valid,
    output                                          in_MM_buffer_F_last,
    input                                           in_MM_buffer_F_ready,
    output reg [A_size * data_width - 1:0]          in_MM_buffer_F_data,

    output reg                                      in_MM_buffer_W_valid,
    output                                          in_MM_buffer_W_last,
    input                                           in_MM_buffer_W_ready,
    output reg [A_size * data_width - 1:0]          in_MM_buffer_W_data

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

localparam integer F_size_width = clogb2(IN_Feature_Block_num);
localparam integer W_size_width = clogb2(Weight_Block_num);
localparam integer log_A_size = clogb2(A_size);
wire start;

reg [A_size * data_width - 1:0] in_F_array [IN_Feature_Block_num - 1 : 0];
reg [A_size * data_width - 1:0] in_W_array [Weight_Block_num - 1 : 0];
 
reg [1:0]                                    state;
reg [W_size_width-1:0]                       W_block_size;
reg [F_size_width-1:0]                       F_block_size; 

reg [F_size_width-1:0]                       in_F_cnt;
reg [F_size_width-1:0]                       in_F_addr;

reg [W_size_width-1:0]                       in_W_cnt;
reg [W_size_width-1:0]                       in_W_addr;

reg [F_size_width-1:0]                       in_MM_buffer_F_cnt;
reg [F_length_width-1:0]                     out_F_row_addr;
reg [F_width_block_num_width-1:0]            out_F_col_addr;
wire [F_size_width-1:0]                      out_F_addr;

reg [W_size_width-1:0]                       in_MM_buffer_W_cnt;
reg [W_size_width-1:0]                       out_W_addr;


assign in_F_ready = (in_F_cnt < F_block_size) & (state != `CAL);
assign in_W_ready = (in_W_cnt < W_block_size) & (state != `CAL);
assign out_F_addr = out_F_row_addr * F_width_block_num + out_F_col_addr;
assign start = ((in_F_cnt == F_block_size & in_W_cnt == W_block_size) 
                | MM_buffer_out_last)
                & (out_F_col_addr!=F_width_block_num);
assign in_MM_buffer_F_last = in_MM_buffer_F_cnt == F_length - 1;
assign in_MM_buffer_W_last = in_MM_buffer_W_cnt == W_width_block_num * A_size - 1; 

initial F_block_size=0;
always @(posedge clk ) begin
    F_block_size <= F_length * F_width_block_num;
end

reg [log_A_size + F_width_block_num_width-1:0] temp_m;
initial temp_m = 0;
initial W_block_size=0;
always @(posedge clk ) begin
    temp_m <= F_width_block_num *A_size;
    W_block_size <= W_width_block_num * temp_m;
end

always @(posedge clk ) begin
    if(in_F_valid & in_F_ready)
        in_F_array[in_F_addr] <= in_F_data;
end

always @(posedge clk ) begin
    if(in_W_valid & in_W_ready)
        in_W_array[in_W_addr] <= in_W_data;
end

always @(posedge clk) begin
    in_MM_buffer_F_data <= in_F_array[out_F_addr];
end


always @(posedge clk) begin
    in_MM_buffer_W_data <= in_W_array[out_W_addr];
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        state <= `IDLE;
    else if (state == `IDLE & (in_F_valid | in_W_valid))
        state <= `IN_DATA;
    else if (state == `IN_DATA & start)
        state <= `CAL;
    else if (state == `CAL & MM_buffer_out_last 
            & ( out_F_col_addr == F_width_block_num))
        state <= `IDLE;
    else
        state <= state;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        in_F_cnt<=0;
    else if (start)
        in_F_cnt <= 0;
    else if (in_F_valid & in_F_ready)
        in_F_cnt <= in_F_cnt + 1;
    else
        in_F_cnt <= in_F_cnt;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        in_F_addr<=0;
    else if (in_F_last)
        in_F_addr <= 0;
    else if (in_F_valid & in_F_ready)
        in_F_addr <= in_F_addr + 1;
    else
        in_F_addr <= in_F_addr;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        in_W_cnt<=0;
    else if (start)
        in_W_cnt <= 0;
    else if (in_W_valid & in_W_ready)
        in_W_cnt <= in_W_cnt + 1;
    else
        in_W_cnt <= in_W_cnt;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        in_W_addr<=0;
    else if (in_W_last)
        in_W_addr <= 0;
    else if (in_W_valid & in_W_ready)
        in_W_addr <= in_W_addr + 1;
    else
        in_W_addr <= in_W_addr;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        in_MM_buffer_F_valid <= 0;
    else if(start)
        in_MM_buffer_F_valid <= 1;
    else if (in_MM_buffer_F_last)
        in_MM_buffer_F_valid <= 0;
    else 
        in_MM_buffer_F_valid<=in_MM_buffer_F_valid;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        in_MM_buffer_F_cnt<=0;
    else if (in_MM_buffer_F_cnt == F_length)
        in_MM_buffer_F_cnt<=0;
    else if (in_MM_buffer_F_valid & in_MM_buffer_F_ready)
        in_MM_buffer_F_cnt<=in_MM_buffer_F_cnt+1;
    else
        in_MM_buffer_F_cnt <= in_MM_buffer_F_cnt;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        out_F_row_addr <= 0;
    else if (start)
        out_F_row_addr <= 1;
    else if (out_F_row_addr == F_length - 1)
        out_F_row_addr <= 0;
    else if (out_F_row_addr != 0 & in_MM_buffer_F_valid & in_MM_buffer_F_ready)
        out_F_row_addr <= out_F_row_addr + 1;
    else
        out_F_row_addr <= out_F_row_addr;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
       out_F_col_addr <= 0;
    else if (MM_buffer_out_last & out_F_col_addr == F_width_block_num)
        out_F_col_addr <= 0; 
    else if(in_MM_buffer_F_last)
        out_F_col_addr <= out_F_col_addr + 1;
    else
        out_F_col_addr <= out_F_col_addr;
end

always @(posedge clk  or negedge rst_n) begin
    if(~rst_n)
        in_MM_buffer_W_valid <= 0;
    else if(start)
        in_MM_buffer_W_valid <= 1;
    else if (in_MM_buffer_W_last)
        in_MM_buffer_W_valid <= 0;
    else 
        in_MM_buffer_W_valid<=in_MM_buffer_W_valid;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        in_MM_buffer_W_cnt <= 0;
    else if (in_MM_buffer_W_cnt == W_width_block_num * A_size)
        in_MM_buffer_W_cnt <= 0;
    else if (in_MM_buffer_W_valid & in_MM_buffer_W_ready)
        in_MM_buffer_W_cnt<=in_MM_buffer_W_cnt+1;
    else
        in_MM_buffer_W_cnt<=in_MM_buffer_W_cnt;
end

always @(posedge clk or negedge rst_n ) begin
    if(~rst_n)
        out_W_addr <= 0;
    else if (out_W_addr== W_block_size -1)
        out_W_addr <= 0;
    else if ((start 
            | (in_MM_buffer_W_valid & in_MM_buffer_W_ready))
            & (~in_MM_buffer_W_last))
        out_W_addr<=out_W_addr+1;
    else
        out_W_addr<=out_W_addr;
end
endmodule