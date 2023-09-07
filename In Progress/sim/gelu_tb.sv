`timescale 1ns / 1ps


module gelu_tb();
reg [2:0] in_scale;
reg [7:0] x;
reg clk;
reg [127:0] cnt;
wire [7:0] y;

gelu u_gelu(
	.clk(clk),
    .in_scale(in_scale),
    .x(x),
    .y_reg1(y)
);

task gelu_task(input real x, output real y );
begin
    automatic real tanh_o;
    automatic real tanh_i;
    automatic real pi = 3.1415926535897932;
    automatic real cst_1;
    automatic real cst_2 = 0.044715;
    cst_1 = $sqrt(2/pi);
    tanh_i = cst_1 * (x + cst_2 * $pow(x,3));
    tanh_o= $tanh(tanh_i);
    y= 0.5 * x * (1 + tanh_o);
end
endtask

always begin
	#50 clk=~clk;
end
initial begin
clk=1;
#20000$display("cnt = %1d",cnt); $display("END");$finish;
end

initial cnt = 0;
real y_soft_reg8;
real y_hard;
real x_soft;
real x_soft_reg8;
real x_hard;
real temp;
genvar i;
//real y_soft_reg_array [7:0];
//always @(posedge clk ) begin
//    y_soft_reg_array[0] <= y_soft;
//end

//generate
//    for(i=1;i<8;i++)begin
//        always @(posedge clk ) begin
//            y_soft_reg_array[i] <= y_soft_reg_array[i-1];
//        end
//    end
//endgenerate

real x_soft_reg_array [7:0];
always @(posedge clk ) begin
    x_soft_reg_array[0] <= x_soft;
end

generate
    for(i=1;i<8;i++)begin
        always @(posedge clk ) begin
            x_soft_reg_array[i] <= x_soft_reg_array[i-1];
        end
    end
endgenerate

reg[2:0] in_scale_reg_array [7:0];
always @(posedge clk ) begin
    in_scale_reg_array[0] <= in_scale;
end

generate
    for(i=1;i<8;i++)begin
        always @(posedge clk ) begin
            in_scale_reg_array[i] <= in_scale_reg_array[i-1];
        end
    end
endgenerate
assign x_soft_reg8 = x_soft_reg_array[7];
real differ;
always begin
    #50;
//    x=1;in_scale=2;
    x = $random % 128;in_scale = {$random}%7;
    cnt = cnt +1;
    x_soft = $itor($signed(x)) / $pow(2, $itor(in_scale)) ;
    gelu_task(x_soft_reg8,y_soft_reg8);
    y_hard = $itor($signed(y))/$pow(2, $itor(in_scale_reg_array[7]));
    differ = $pow(2, -$itor(in_scale_reg_array[7]));
    temp=y_hard-y_soft_reg8;
    if(temp>differ || temp < -differ)begin
         $display("diff = %6.3f, y_hard=%6.3f, y_soft=%6.3f, x_soft=%6.3f, cnt = %1d",temp,y_hard,y_soft_reg8,x_soft_reg8,cnt);
    end
    
    #50;
end



endmodule
