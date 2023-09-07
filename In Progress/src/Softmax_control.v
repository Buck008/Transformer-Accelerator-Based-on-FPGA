`timescale 1ns / 1ps


module Softmax_control(
    input                           clk,
    input                           rst_n,

    input [9:0]                     length_input,
    input signed [4:0]              scale_in_input,
    input [3:0]                     scale_out_input,
    
    
    input signed [7:0]              top_data_in,
    input                           top_valid_in,
    output                          top_ready_in,
    input                           top_last_in,
    
    output     [7:0]                top_data_out,
    output                          top_valid_out,
    output                          top_last_out

);

reg [9:0] length;
reg [11:0] lengthX3;
reg [10:0] lengthX2;
reg signed [4:0] scale_in;
reg [3:0] scale_out;
reg [15:0] cnt_in;
reg [15:0] cnt_stage;
reg Softmax_valid_in;
reg Softmax_valid_in_delay1;
reg top_valid_in_delay1;
reg [9:0] out_addr;
reg top_last_in_reg;
reg top_ready_in_delay1;
reg [7:0] Softmax_data_in_delay1;
reg signed [7:0] in_data_buffer [1023:0];

wire valid_input_flag;
//wire [7:0] Softmax_data_in;
wire [7:0] Softmax_data_out;
wire buffer_wen;
wire Softmax_valid_out;
wire [9:0] in_addr;
wire Softmax_out_last;
wire length1_flag;
wire length2_flag;
wire length3_flag;

assign length1_flag = cnt_stage<=length;
assign length2_flag = cnt_stage<=lengthX2;
assign length3_flag = cnt_stage<=lengthX3;
assign in_addr = (cnt_in < length)? cnt_in:0;
assign valid_input_flag = top_valid_in&top_ready_in;
assign buffer_wen = top_valid_in&top_ready_in;
assign top_data_out = Softmax_data_out;
assign top_valid_out = Softmax_valid_out;
assign top_last_out = Softmax_out_last & top_last_in_reg;
assign top_ready_in = cnt_in < length;
//assign Softmax_data_in = in_data_buffer[out_addr];

always @(posedge clk ) begin
//    Softmax_data_in_delay1<=Softmax_data_in;
    Softmax_data_in_delay1<=in_data_buffer[out_addr]; //block mem
end

always @(posedge clk ) begin
    Softmax_valid_in_delay1<=Softmax_valid_in;
end

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        top_last_in_reg<=0;
    else if (top_last_in)
        top_last_in_reg<=1;
    else if (top_last_out)
        top_last_in_reg<=0;
    else
        top_last_in_reg<=top_last_in_reg;
end

always@(posedge clk)begin
    top_ready_in_delay1<=top_ready_in;
end

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        cnt_in <= 0;
    else if(cnt_stage == lengthX3)//(cnt_stage == length * 3)
        cnt_in <= 0;
    else if(valid_input_flag)
        cnt_in <= cnt_in + 1;
    else
        cnt_in <= cnt_in;
end

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        cnt_stage<=0;
    else if (cnt_stage == lengthX3)//(cnt_stage == length * 3)
        cnt_stage <= 0;
    else if (cnt_stage < length & valid_input_flag)
        cnt_stage<=cnt_stage+1;
    else if (cnt_stage >= length)
        cnt_stage<=cnt_stage+1;
    else
        cnt_stage <= cnt_stage;
end

always @(posedge clk ) begin
    length <= length_input;
    scale_in <= scale_in_input;
    scale_out <= scale_out_input;
end

always @(posedge clk ) begin
    lengthX3<=length * 3;
end

always @(posedge clk ) begin
    lengthX2<=length * 2;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        top_valid_in_delay1<=0;
    else
        top_valid_in_delay1<=top_valid_in;
end

always @(posedge clk) begin
    if(buffer_wen)
        in_data_buffer[in_addr] <= top_data_in;
end

// always @(*)begin
//     if(cnt_stage<=length)
//         Softmax_valid_in = top_valid_in_delay1;
//     else if(cnt_stage >length | cnt_stage<=lengthX3)//cnt_stage <=  length*3)
//         Softmax_valid_in = 1;
//     else 
//         Softmax_valid_in = 0;
// end




always @(*)begin
    case({ length1_flag, length3_flag}) 
        2'b11: Softmax_valid_in = top_valid_in_delay1 & top_ready_in_delay1;
        2'b01: Softmax_valid_in = 1;
        default: Softmax_valid_in=0;
    endcase
end

// always @(*)begin
//     if(cnt_stage>0&cnt_stage<=length)
//         out_addr = cnt_stage -1;
//     else if (cnt_stage>length & cnt_stage<=lengthX2)//2*length)
//         out_addr = cnt_stage - 1 - length;
//     else if (cnt_stage>2*length & cnt_stage <=lengthX3)//<= 3*length)
//         out_addr = cnt_stage - 1 - lengthX2;//2*length;
//     else
//         out_addr = 0;
// end


always @(*) begin
    case({(cnt_stage>0),length1_flag,length2_flag,length3_flag})
        4'b1111: out_addr = cnt_stage -1;
        4'b1011: out_addr = cnt_stage - 1 - length;
        4'b1001: out_addr = cnt_stage - 1 - lengthX2;
        default:out_addr = 0;
    endcase
end


Softmax u_Softmax(
    .clk(clk),
    .rst_n(rst_n),
    .length_input(length_input),
    .lengthX2(lengthX2),
    .lengthX3(lengthX3),
    .scale_in(scale_in),//scale_in and scale_out must be kept during the valid_in, min =-1, max =10
    .scale_out(scale_out),//min = 7,max  = 14
    .data_in(Softmax_data_in_delay1),
    .valid_in(Softmax_valid_in_delay1),

    .data_out(Softmax_data_out),
    .valid_out(Softmax_valid_out),
    .out_last(Softmax_out_last)
);
endmodule
