`timescale 1ns / 1ps


module MM_ultra
#(
    parameter integer                                       A_size = 16,
    parameter integer                                       data_width = 8,
    parameter integer                                       shift_width = 10,
    parameter integer                                       Weight_Block_num = 2400, 
    parameter integer                                       IN_Feature_Block_num = 2400, 
    parameter integer                                       OUT_Feature_Block_num = 2400,
    parameter integer                                       OUT_MEM_WIDTH = 32,
    parameter integer                                       F_length_width = 9,
    parameter integer                                       F_width_block_num_width = 5,
    parameter integer                                       W_width_block_num_width = 5
)(
    input                                                   clk,
    input                                                   rst_n,


    input [shift_width-1:0]                                 shift_in,
    input [F_length_width-1:0]                              F_length_in, 
    input [F_width_block_num_width-1:0]                     F_width_block_num_in,
    input [W_width_block_num_width-1:0]                     W_width_block_num_in, 


    input                                                   in_F_valid,
    input                                                   in_F_last,
    output                                                  in_F_ready,
    input [A_size * data_width - 1:0]                       in_F_data,

    input                                                   in_W_valid,
    input                                                   in_W_last,
    output                                                  in_W_ready,
    input [A_size * data_width - 1:0]                       in_W_data,

    output                                                  out_data_valid,
    input                                                   out_data_ready,
    output                                                  out_data_last,
    output [A_size * data_width -1:0]                       out_data

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
localparam integer log2_array_m = clogb2(A_size);

reg [shift_width-1:0]                                 shift;
reg [F_length_width-1:0]                              F_length; 
reg [F_width_block_num_width-1:0]                     F_width_block_num;
reg [W_width_block_num_width-1:0]                     W_width_block_num; 
reg [shift_width-1:0]                                 shift_in_delay1;
reg [F_length_width-1:0]                              F_length_in_delay1; 
reg [F_width_block_num_width-1:0]                     F_width_block_num_in_delay1;
reg [W_width_block_num_width-1:0]                     W_width_block_num_in_delay1; 

initial begin
    shift = {(shift_width){1'b1}};
    F_length = {(F_length_width){1'b1}};
    F_width_block_num = {(F_width_block_num_width){1'b1}};
    W_width_block_num = {(W_width_block_num_width){1'b1}};
end

always @(posedge clk ) begin
    if(shift_in_delay1 != shift_in)
        shift <= shift_in;
end

always @(posedge clk ) begin
    if(F_length_in_delay1 != F_length_in)
        F_length <=F_length_in;
end

always @(posedge clk ) begin
    if(F_width_block_num_in_delay1 != F_width_block_num_in)
        F_width_block_num <= F_width_block_num_in;
end

always @(posedge clk ) begin
    if(W_width_block_num_in_delay1 != W_width_block_num_in)
        W_width_block_num <= W_width_block_num_in;
end

always @(posedge clk ) begin
    shift_in_delay1 <= shift_in;
    F_length_in_delay1 <= F_length_in;
    F_width_block_num_in_delay1 <= F_width_block_num_in;
    W_width_block_num_in_delay1 <= W_width_block_num_in;
end


wire [A_size*(log2_array_m+data_width*2)-1:0]               MM_buffer_out_data;
wire                                                        MM_buffer_out_valid;
wire                                                        MM_buffer_out_last;

wire                                                        in_MM_buffer_F_valid;
wire                                                        in_MM_buffer_F_last;
wire                                                        in_MM_buffer_F_ready;
wire [A_size * data_width - 1:0]                            in_MM_buffer_F_data;

wire                                                        in_MM_buffer_W_valid;
wire                                                        in_MM_buffer_W_last;
wire                                                        in_MM_buffer_W_ready;
wire [A_size * data_width - 1:0]                            in_MM_buffer_W_data;




MM_in_buffer
#(
    .A_size(A_size),
    .data_width(data_width),
    .Weight_Block_num(Weight_Block_num), 
    .IN_Feature_Block_num(IN_Feature_Block_num),
    .F_length_width(F_length_width),
    .F_width_block_num_width(F_width_block_num_width),
    .W_width_block_num_width(W_width_block_num_width)
)u_MM_in_buffer(
    .clk(clk),
    .rst_n(rst_n),
    
    .W_width_block_num(W_width_block_num), //1 ~ block_num
    .F_width_block_num(F_width_block_num), //1 ~ block_num
    .F_length(F_length),                   //1 ~ block_num *A_size

    .MM_buffer_out_last(MM_buffer_out_last),

    .in_F_valid(in_F_valid),
    .in_F_last(in_F_last),
    .in_F_ready(in_F_ready),
    .in_F_data(in_F_data),

    .in_W_valid(in_W_valid),
    .in_W_last(in_W_last),
    .in_W_ready(in_W_ready),
    .in_W_data(in_W_data),

    .in_MM_buffer_F_valid(in_MM_buffer_F_valid),
    .in_MM_buffer_F_last(in_MM_buffer_F_last),
    .in_MM_buffer_F_ready(in_MM_buffer_F_ready),
    .in_MM_buffer_F_data(in_MM_buffer_F_data),

    .in_MM_buffer_W_valid(in_MM_buffer_W_valid),
    .in_MM_buffer_W_last(in_MM_buffer_W_last),
    .in_MM_buffer_W_ready(in_MM_buffer_W_ready),
    .in_MM_buffer_W_data(in_MM_buffer_W_data)

);


MM_buffer
#(
    .array_m(A_size),
    .array_n(A_size),
    .data_width(data_width),
    .log2_array_m(log2_array_m),
    .F_length_width(F_length_width),
    .W_width_block_num_width(W_width_block_num_width)
)u_MM_buffer(
    .clk(clk),
    .rst_n(rst_n),

    // .shift(shift),
    .FL(F_length), //feature length
    .num_blobk_W(W_width_block_num),

    .MM_buffer_inWeight_data(in_MM_buffer_W_data),
    .MM_buffer_inWeight_valid(in_MM_buffer_W_valid),
    .MM_buffer_inWeight_ready(in_MM_buffer_W_ready),
    .MM_buffer_inWeight_last(in_MM_buffer_W_last),

    .MM_buffer_inFeature_data(in_MM_buffer_F_data),
    .MM_buffer_inFeature_valid(in_MM_buffer_F_valid),
    .MM_buffer_inFeature_ready(in_MM_buffer_F_ready),
    .MM_buffer_inFeature_last(in_MM_buffer_F_last),

    .MM_buffer_out_data(MM_buffer_out_data),
    .MM_buffer_out_valid(MM_buffer_out_valid),
    .MM_buffer_out_last(MM_buffer_out_last)
);


MM_out_buffer
#(
    .data_width(data_width),
    .OUT_Feature_Block_num(OUT_Feature_Block_num),
    .A_size(A_size),
    .shift_width(shift_width),
    .log2_array_m(log2_array_m),
    .OUT_MEM_WIDTH(OUT_MEM_WIDTH),
    .F_length_width(F_length_width),
    .F_width_block_num_width(F_width_block_num_width),
    .W_width_block_num_width(W_width_block_num_width)
)u_MM_out_buffer(
    .clk(clk),
    .rst_n(rst_n),

    .shift(shift),
    .F_length(F_length), //1 ~ block_num *A_size
    .F_width_block_num(F_width_block_num), //1 ~ block_num
    .W_width_block_num(W_width_block_num), //1 ~ block_num
    
    .in_data_valid(MM_buffer_out_valid),
    .in_data_last(MM_buffer_out_last),
    .in_data(MM_buffer_out_data),

    .out_data_valid(out_data_valid),
    .out_data_ready(out_data_ready),
    .out_data_last(out_data_last),
    .out_data(out_data)
);
endmodule
