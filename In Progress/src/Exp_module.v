`timescale 1ns / 1ps
module Exp_module(//latency = 3
	input 					clk,      
    input  signed [19:0]    x_S9Q10, //有符号数
    output reg signed [24:0]    y_U0Q25_reg1 //无符号数
);

wire signed [24:0] x_log2e_S10Q14; //有符号数，一定小于等于0
reg  signed [24:0] x_log2e_S10Q14_reg1; //有符号数，一定小于等于0
assign x_log2e_S10Q14  = x_S9Q10 * 6'sd23;

always@(posedge clk)begin
	x_log2e_S10Q14_reg1 <= x_log2e_S10Q14;
end

wire [23:0] x_log2e_U10Q14_abs; //x_log2e_6Q10的绝对值无符号数，可以少一位符号位，因为不可能出现-256
assign x_log2e_U10Q14_abs = ~x_log2e_S10Q14_reg1+1;

wire [9:0] x_int_10Q0 = x_log2e_U10Q14_abs[23:14];

wire [13:0] x_decimal_0Q14 = x_log2e_U10Q14_abs[13:0];//小数部分，无符号数

wire [14:0] temp_1Q14 = 15'b100_0000_0000_0000 - {2'b0,x_decimal_0Q14[13:1]};//1+0.5*x_decimal,无符号数
reg  [14:0] temp_1Q14_reg1;
wire [3:0] x_int_4Q0;//无符号数
assign x_int_4Q0 = (x_int_10Q0 > 12)? 4'd12 : x_int_10Q0;//截断为12

wire [11:0] temp_2_int_1Q11; //2的冥,最大值为1
reg  [11:0] temp_2_int_1Q11_reg1; //2的冥,最大值为1
assign temp_2_int_1Q11 = 12'b1000_0000_0000 >> x_int_4Q0;
always@(posedge clk)begin
	temp_2_int_1Q11_reg1<=temp_2_int_1Q11;
	temp_1Q14_reg1<=temp_1Q14;
end

wire [26:0] temp_y_2Q25 = temp_2_int_1Q11_reg1 * temp_1Q14_reg1;//无符号数


// wire signed [11:0] y_U0Q12;
// assign y_U0Q12 = temp_y_2Q25[25] == 1'b1 ? 12'b1111_1111_1111:temp_y_2Q25[24:13];
wire signed [24:0] y_U0Q25;
assign y_U0Q25 = temp_y_2Q25[25] == 1'b1 ? 25'h1FF_FFFF:temp_y_2Q25[24:0];

always@(posedge clk)begin 
	y_U0Q25_reg1<=y_U0Q25;
end

endmodule
