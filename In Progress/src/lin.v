`timescale 1ns / 1ps   //latency = 4
module lin(
	input  wire				  clk, 
    input  wire signed [11:0] x_in_L_2Q9,
    output reg  signed [8:0]  L_1Q7 
);

wire signed [9:0] x_in_L_2Q7 = x_in_L_2Q9[11:2];
wire sign = x_in_L_2Q9[11];
reg  sign_reg1;
reg  sign_reg2;
reg  sign_reg3;
always@(posedge clk)begin
	sign_reg1<=sign;
	sign_reg2<=sign_reg1;
	sign_reg3<=sign_reg2;
end
wire signed [9:0] x_in_L_2Q7_abs = (sign==1'b1) ? (~x_in_L_2Q7+1) : x_in_L_2Q7;
wire signed [3:0] b_1Q2 = 4'sb0111; //b=7/4
wire signed [6:0] a_0Q7 = -7'sd37; 

wire signed [9:0] x_in_L_2Q7_abs_b = x_in_L_2Q7_abs - {b_1Q2,5'b00000};
reg  signed [9:0] x_in_L_2Q7_abs_b_reg1; 
always@(posedge clk)begin
	x_in_L_2Q7_abs_b_reg1<=x_in_L_2Q7_abs_b;
end

wire signed [18:0] temp_4Q14 = x_in_L_2Q7_abs_b_reg1*x_in_L_2Q7_abs_b_reg1;
reg  signed [18:0] temp_4Q14_reg1;
always@(posedge clk)begin
	temp_4Q14_reg1<=temp_4Q14;
end	
wire signed [25:0] l_4Q21 = a_0Q7*temp_4Q14_reg1+ 23'sb0_1_0_0000_0000_0000_0000_0000;
reg  signed [25:0] l_4Q21_reg1;
always@(posedge clk)begin
	l_4Q21_reg1<=l_4Q21;
end
//wire signed [25:0] l_4Q21 = a_0Q7 * x_in_L_2Q7_abs_b * x_in_L_2Q7_abs_b + 23'sb0_1_0_0000_0000_0000_0000_0000;
reg signed [25:0] sign_l_4Q21;
always @(*) begin
    if (sign_reg3==1'b1)begin
        sign_l_4Q21 = ~l_4Q21_reg1+1;
    end
    else begin
        sign_l_4Q21 = l_4Q21_reg1;
    end
end
always@(posedge clk)begin
	L_1Q7<=sign_l_4Q21[22:14];
end
//assign L_1Q7 = sign_l_4Q21[22:14];
endmodule
