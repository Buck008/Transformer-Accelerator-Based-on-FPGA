`timescale 1ns / 1ps
//latency=4+4
module gelu(
	input                           clk,
    input [2:0]                     in_scale,
    input signed [7:0]              x, 
    output reg signed [7:0]         y_reg1
);
reg signed [7:0] x_reg1;
reg signed [7:0] x_reg2;
reg signed [7:0] x_reg3;
reg signed [7:0] x_reg4;
reg signed [7:0] x_reg5;
reg signed [7:0] x_reg6;
reg signed [7:0] x_reg7;

reg [2:0] in_scale_reg1;
reg [2:0] in_scale_reg2;
reg [2:0] in_scale_reg3;
reg [2:0] in_scale_reg4;
reg [2:0] in_scale_reg5;
reg [2:0] in_scale_reg6;
reg [2:0] in_scale_reg7;
always@(posedge clk)begin
	in_scale_reg1<=in_scale;
	in_scale_reg2<=in_scale_reg1;
	in_scale_reg3<=in_scale_reg2;
	in_scale_reg4<=in_scale_reg3;
	in_scale_reg5<=in_scale_reg4;
	in_scale_reg6<=in_scale_reg5;
	in_scale_reg7<=in_scale_reg6;
end
always@(posedge clk)begin
	x_reg1<=x;
	x_reg2<=x_reg1;
	x_reg3<=x_reg2;
	x_reg4<=x_reg3;
	x_reg5<=x_reg4;
	x_reg6<=x_reg5;
	x_reg7<=x_reg6;
end
reg signed [7:0]  y;
reg signed [15:0] x_in_8Q7;
reg signed [15:0] x_in_8Q7_reg1;
reg signed [15:0] x_in_8Q7_reg2;
reg signed [15:0] x_in_8Q7_reg3;
reg signed [15:0] x_in_8Q7_reg4;
reg signed [15:0] x_in_8Q7_reg5;
reg signed [15:0] x_in_8Q7_reg6;
reg signed [15:0] x_in_8Q7_reg7;
always @(*) begin
    if (in_scale < 7  ) begin
        x_in_8Q7 = $signed(x) <<< (3'd7- in_scale);//×óÒÆ
    end
    else begin // in_scale == 7
        x_in_8Q7 = x;
    end
end
always@(posedge clk)begin
	x_in_8Q7_reg1<=x_in_8Q7;
	x_in_8Q7_reg2<=x_in_8Q7_reg1;
	x_in_8Q7_reg3<=x_in_8Q7_reg2;
	x_in_8Q7_reg4<=x_in_8Q7_reg3;
	x_in_8Q7_reg5<=x_in_8Q7_reg4;
	x_in_8Q7_reg6<=x_in_8Q7_reg5;
	x_in_8Q7_reg7<=x_in_8Q7_reg6;
end
wire signed [9:0] c_2_5_2Q7 =  10'b0_10_1000_000;
wire signed [9:0] _c_2_5_2Q7 = 10'b1_01_1000_000;
wire signed [18:0] out_3Q15;
reg  signed [18:0] out_3Q15_reg1;
wire signed [10:0] y_3Q7;


wire signed [11:0] x_in_L_2Q9;
reg  signed [11:0] x_in_L_2Q9_reg1;
assign x_in_L_2Q9 = $signed(x_in_8Q7_reg1[9:0]) * 3'sb011; 
//                      <2.5           3/4
always@(posedge clk)begin
	x_in_L_2Q9_reg1<=x_in_L_2Q9;
end
wire signed [8:0] L_1Q7;
lin u_lin(//latency = 4
	.clk(clk),
    .x_in_L_2Q9(x_in_L_2Q9_reg1),
    .L_1Q7(L_1Q7) 
);
wire signed [9:0] L_2Q7_1 = L_1Q7 + 10'sb001_000_0000;
wire signed [9:0] half_L_1Q8 = L_2Q7_1;
assign out_3Q15 = half_L_1Q8 *  $signed(x_in_8Q7_reg6[9:0]);
always@(posedge clk)begin
	out_3Q15_reg1<=out_3Q15;
end
assign y_3Q7= out_3Q15_reg1[18:8]; 

always @(*) begin
    if(x_reg7[7]==1'b1 && x_in_8Q7_reg7<=_c_2_5_2Q7)begin
        y = 0;
    end
    else if(x_reg7[7]==1'b0 && x_in_8Q7_reg7 >= c_2_5_2Q7)begin
        y = x_reg7;
    end
    else begin
//        y=y_3Q7;
        y = (y_3Q7>>>(3'd7-in_scale_reg7));
    end
end
always@(posedge clk)begin
	y_reg1 <= y;
end
endmodule
