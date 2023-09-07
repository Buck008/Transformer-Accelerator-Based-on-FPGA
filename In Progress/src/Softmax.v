`timescale 1ns / 1ps

module Softmax(
    input                   clk,
    input                   rst_n,
    
    input [9:0]             length_input,
    input [10:0]            lengthX2,
    input [11:0]            lengthX3,
    input signed [4:0]      scale_in,//scale_in and scale_out must be kept during the valid_in, min =-1, max =10
    input [3:0]             scale_out,//min = 7,max  = 14
    input signed [7:0]      data_in,
    input                   valid_in,
    
    output reg [7:0]        data_out,
    // output reg [15:0]       data_out,
    output                  valid_out,
    output                  out_last
);


(*MAX_FANOUT = 25 *)  reg [9:0] length;
reg valid_in_delay1;
reg valid_in_delay2;
reg valid_in_delay3;
reg valid_in_delay4;
reg valid_in_delay5;
reg valid_in_delay6;
reg valid_in_delay7;
reg valid_in_delay8;
reg valid_in_delay9;
reg valid_in_delay10;
reg [15:0] cnt;
reg signed [7:0] data_in_max;
reg signed [19:0] x_max_S9Q10;
reg signed [19:0] x_max_S9Q10_delay1;
reg signed [19:0] x_max_S9Q10_delay2;
reg signed [19:0] x_max_S9Q10_delay3;
reg signed [19:0] x_max_S9Q10_delay4;
reg signed [19:0] x_max_S9Q10_delay5;
reg signed [19:0] x_max_S9Q10_delay6;
reg  [19:0] e_sum_U8Q12;
reg [1:0] stage_delay1;
reg [1:0] stage_delay2;
reg [1:0] stage_delay3;
reg [1:0] stage_delay4;
reg [1:0] stage_delay5;
reg [1:0] stage_delay6;
reg [1:0] stage_delay7;
reg [1:0] stage_delay8;
reg [1:0] stage_delay9;
reg [1:0] stage_delay10;
reg [3:0] scale_out_delay1;
reg [3:0] scale_out_delay2;
reg [3:0] scale_out_delay3;
reg [3:0] scale_out_delay4;
reg [3:0] scale_out_delay5;
reg [3:0] scale_out_delay6;
reg [3:0] scale_out_delay7;
reg [3:0] scale_out_delay8;
reg [3:0] scale_out_delay9;
reg   [7:0] exp_out;
// reg   [15:0] exp_out;

wire [1:0] stage;// 1:first input, 2:second input, 3:third input
wire signed [8:0] x_max_9b;
wire  [11:0] exp_U0Q12;
wire  [13:0] exp_U0Q14_out;
wire [15:0] e_sum_U8Q8;
wire [15:0] e_sum_U8Q8_temp;
wire [12:0] ln_U3Q10;
wire signed [20:0] x_max_ln_S10Q10;
wire signed [19:0] x_max_ln_S9Q10;

assign x_max_ln_S10Q10 = x_max_S9Q10_delay6-$signed({7'b000_0000,ln_U3Q10}); 
assign x_max_ln_S9Q10 = x_max_ln_S10Q10[20] == 0 ? 0:(x_max_ln_S10Q10 < -524288) ? 20'b1000_0000_0000_0000_0000:x_max_ln_S10Q10;
//assign stage = cnt<=(length -1) ? 1 : (length- 1<cnt && cnt <=length*2-1 ? 2 : 3);
assign stage = cnt<=(length -1) ? 1 : (length- 1<cnt && cnt <=lengthX2-1 ? 2 : 3);
assign x_max_9b = data_in-data_in_max;
assign e_sum_U8Q8_temp = e_sum_U8Q12[19:4] + (e_sum_U8Q12[3]?1:0);
assign e_sum_U8Q8 =  e_sum_U8Q8_temp> 256 ? e_sum_U8Q8_temp: 256;
assign valid_out = (stage_delay10==3 & valid_in_delay10)?1:0;
assign out_last = (stage_delay10 == 3) & (stage_delay9==1);

always @(*) begin
    case(scale_out_delay9)
        14:begin exp_out = (|exp_U0Q14_out[13:7]) ? 8'b0111_1111 : {1'b0,exp_U0Q14_out[6:0]}; end

        13:begin exp_out = (|exp_U0Q14_out[13:8]) ? 8'b0111_1111 : {1'b0,exp_U0Q14_out[7:1]}; end

        12:begin exp_out = (|exp_U0Q14_out[13:9]) ? 8'b0111_1111 : {1'b0,exp_U0Q14_out[8:2]}; end
        
        11:begin exp_out = (|exp_U0Q14_out[13:10]) ? 8'b0111_1111 : {1'b0,exp_U0Q14_out[9:3]};end

        10:begin exp_out = (|exp_U0Q14_out[13:11]) ? 8'b0111_1111 : {1'b0,exp_U0Q14_out[10:4]};end

         9:begin exp_out = (|exp_U0Q14_out[13:12]) ? 8'b0111_1111 : {1'b0, exp_U0Q14_out[11:5]};end

         8:begin exp_out = (exp_U0Q14_out[13]) ? 8'b0111_1111 : {1'b0, exp_U0Q14_out[12:6]};end

         7:begin exp_out = {1'b0, exp_U0Q14_out[13:7]}; end  

         default: begin exp_out = {1'b0, exp_U0Q14_out[13:7]}; end 
    endcase                                                                                                                                                                                                    
end                                                                                                              

always@(posedge clk)begin
    data_out<=exp_out;
end

always @(posedge clk ) begin
    length <= length_input;
end

always@(posedge clk)begin
    stage_delay1<=stage;
    stage_delay2<=stage_delay1;
    stage_delay3<=stage_delay2;
    stage_delay4<=stage_delay3;
    stage_delay5<=stage_delay4;
    stage_delay6<=stage_delay5;
    stage_delay7<=stage_delay6;
    stage_delay8<=stage_delay7;
    stage_delay9<=stage_delay8;
    stage_delay10<=stage_delay9;
end

always@(posedge clk)begin
    scale_out_delay1<=scale_out;
    scale_out_delay2<=scale_out_delay1;
    scale_out_delay3<=scale_out_delay2;
    scale_out_delay4<=scale_out_delay3;
    scale_out_delay5<=scale_out_delay4;
    scale_out_delay6<=scale_out_delay5;
    scale_out_delay7<=scale_out_delay6;
    scale_out_delay8<=scale_out_delay7;
    scale_out_delay9<=scale_out_delay8;
end

always@(posedge clk)begin
    valid_in_delay1<=valid_in;
    valid_in_delay2<=valid_in_delay1;
    valid_in_delay3<=valid_in_delay2;
    valid_in_delay4<=valid_in_delay3;
    valid_in_delay5<=valid_in_delay4;
    valid_in_delay6<=valid_in_delay5;
    valid_in_delay7<=valid_in_delay6;
    valid_in_delay8<=valid_in_delay7;
    valid_in_delay9<=valid_in_delay8;
    valid_in_delay10<=valid_in_delay9;
end

initial begin  cnt=0;  end
always@(posedge clk or negedge rst_n)begin
    if (~rst_n)
        cnt<=0;
    else begin
        if(cnt==0&valid_in)
            cnt<=1;
        else if(cnt==0)
            cnt<=cnt;
        else if(cnt==lengthX3-1)
            cnt<=0;
        else if(valid_in)
            cnt<=cnt+1;
        else
            cnt<=cnt;
    end
end

// initial begin data_in_max=8'b11111111;end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        data_in_max<=8'b11111111;
    else if(cnt==lengthX3-1)
        data_in_max<=8'b11111111;
    else if(valid_in&stage==1)
        data_in_max<=(data_in_max>data_in)?data_in_max:data_in;
end

always @(*) begin
    if (scale_in == -1)
        x_max_S9Q10 =  $signed(x_max_9b) <<< 11;
    else if (scale_in < 10) begin
        x_max_S9Q10 = $signed(x_max_9b) <<< (5'd10- scale_in[3:0]);
    end
    else begin // in_scale == 10
        x_max_S9Q10 = x_max_9b;
    end
end

always@(posedge clk)begin
    x_max_S9Q10_delay1<=x_max_S9Q10;
    x_max_S9Q10_delay2<=x_max_S9Q10_delay1;
    x_max_S9Q10_delay3<=x_max_S9Q10_delay2;
    x_max_S9Q10_delay4<=x_max_S9Q10_delay3;
    x_max_S9Q10_delay5<=x_max_S9Q10_delay4;
    x_max_S9Q10_delay6<=x_max_S9Q10_delay5;
end


always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        e_sum_U8Q12<=0;
    else if(stage_delay4==2 & valid_in_delay4)
        e_sum_U8Q12<=exp_U0Q12+e_sum_U8Q12;
    else if(stage_delay4==1)
        e_sum_U8Q12<=0;
end

wire [24:0] exp_U0Q25;
assign exp_U0Q12 = exp_U0Q25[24:13];

Exp_module u_Exp_module_1(
	.clk(clk),
    .x_S9Q10(x_max_S9Q10_delay1), 
    .y_U0Q25_reg1(exp_U0Q25) 
);

Ln_module u_Ln_module(//latency=2
	.clk(clk),
    .x_U8Q8(e_sum_U8Q8),    
    .y_U3Q10(ln_U3Q10)  
);

wire [24:0] exp_U0Q25_out;
assign exp_U0Q14_out = exp_U0Q25_out[24:11];

Exp_module u_Exp_module_2(
	.clk(clk),
    .x_S9Q10(x_max_ln_S9Q10), 
    .y_U0Q25_reg1(exp_U0Q25_out) 
);
endmodule