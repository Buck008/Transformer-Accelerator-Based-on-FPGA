`timescale 1ns / 1ps
`define length 197
`define scale_in 6
`define scale_out 7
//scale_in and scale_out must be kept during the valid_in, min =-1, max =10
//scale_out min = 7,max  = 12
module Softmax_top_tb;
reg                           clk;
reg                           rst_n;

reg [9:0]                     length;
reg signed [4:0]              scale_in;
reg [3:0]                     scale_out;

wire signed [7:0]             top_data_in;
reg                           top_valid_in;
wire                          top_ready_in;
reg                           top_last_in;

wire    [7:0]                 top_data_out;
wire                          top_valid_out;
wire                          top_last_out;

Softmax_control u_Softmax_control(
    .clk(clk),
    .length_input(length),
    .rst_n(rst_n),
    .scale_in_input(scale_in),
    .scale_out_input(scale_out),

    .top_data_in(top_data_in),
    .top_valid_in(top_valid_in),
    .top_ready_in(top_ready_in),
    .top_last_in(top_last_in),

    .top_data_out(top_data_out),
    .top_valid_out(top_valid_out),    
    .top_last_out(top_last_out)
);

task Softmax_task(input real x[`length-1:0], output real y[`length-1:0] );
begin
    automatic int Scnt = 0;
    automatic real in_max = 0;
    automatic real exp[`length];
    automatic real exp_sum = 0;
    
    for(Scnt = 0;Scnt<`length;Scnt++)begin
        if(in_max<x[Scnt])
            in_max = x[Scnt];
    end
    
    for(Scnt = 0;Scnt<`length;Scnt++)begin
        x[Scnt] = x[Scnt] - in_max;
        exp[Scnt] = $exp(x[Scnt]);
        exp_sum = exp_sum + exp[Scnt];
    end
    
    for(Scnt = 0;Scnt<`length;Scnt++)begin
        y[Scnt] = exp[Scnt]/exp_sum;
    end
end
endtask

reg [9:0] cnt;
reg [9:0] cnt_valid;
reg [9:0] y_cnt;

real x_real [`length - 1:0];
real y_real [`length - 1:0];
reg [31:0] time_cnt;
reg signed [7:0] x_hard [`length-1:0];
reg signed [7:0] y_hard [`length-1:0];
reg control_valid;


real differ;
real temp1;
real temp2;
real hard_max;
real real_max;
real error_cnt;

always @(posedge clk) begin
    if(u_Softmax_control.u_Softmax.out_last | (!top_ready_in))
        control_valid = 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        time_cnt<=0;
    else
        time_cnt<=time_cnt+1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_valid<=0;
    else 
        cnt_valid <= cnt_valid +1;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt<=0;
    else if(cnt == length)
        cnt<=0;
    else if(top_valid_in & top_ready_in)
        cnt <= cnt+1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        y_cnt<=0;
    else if(y_cnt == length-1)
        y_cnt<=0;
    else if(top_valid_out)
        y_cnt <= y_cnt+1;
    else
        y_cnt <= y_cnt;
end

always @(posedge clk ) begin
    if(top_valid_out)
        y_hard[y_cnt] <= top_data_out;
end

assign top_data_in = x_hard[cnt];
assign top_valid_in =(cnt <= `length-1)&(~cnt_valid[1])&control_valid;
assign top_last_in = (cnt == `length - 1) ;

initial begin
    clk = 1;
end

always  begin
    #50 clk = ~clk;
end


integer i;
initial begin
    control_valid = 0;
    rst_n = 0;

    length = `length;
    scale_in = `scale_in;
    scale_out = `scale_out;
    for(i=0;i<`length;i++)begin
        x_hard[i] = 100;
//        x_hard[i] = $random % 176;
//        if(i==`length/2)
//            x_hard[i] = 110;
//        if(i==`length/3)
//            x_hard[i] = 10;
//        if(i==`length/4)
//            x_hard[i] = 60;
//        if(i==`length/5)
//            x_hard[i] = 40; 
        x_real[i] = $itor($signed(x_hard[i])) * $pow(2, -$itor(scale_in));
    end
    Softmax_task(x_real,y_real);
    control_valid = 1;
    #350 rst_n = 1;
    for (i=0;i<5*`length;i++)begin
        #100;
    end
    
    
    
    error_cnt = 0;
    real_max = 0;
    hard_max = 0;
    for (i=0;i<`length;i++)begin
        temp1 = $itor($signed(y_hard[i])) * $pow(2,-$itor(scale_out));
        temp2 = y_real[i];
        if (temp1 >hard_max)
            hard_max = temp1;
        if(temp2>real_max)
            real_max = temp2;
        differ =  temp1- temp2;
        if( differ >  $pow(2,-$itor(scale_out)) |differ < -$pow(2,-$itor(scale_out))) begin
            error_cnt++;
            $display("%d: differ percentile = %6.4f%%, differ = %6.4f, real = %6.4f, hard = %6.4f",i,differ/y_real[i]*100,differ,temp2,temp1);
        end
    end
    $display("The ratio of error greater than the minimum precision: %6.4f%%",100 *error_cnt / `length);
    $display("real_max = %6.4f, hard_max = %6.4f",real_max, hard_max);
    
    
    
    
    for(i=0;i<`length;i++)begin
//        x_hard[i] = i;
        x_hard[i] = $random % 256;
//        if(i==`length/2)
//            x_hard[i] = 110;
//        if(i==`length/3)
//            x_hard[i] = 10;
//        if(i==`length/4)
//            x_hard[i] = 60;
//        if(i==`length/5)
//            x_hard[i] = 40; 
        x_real[i] = $itor($signed(x_hard[i])) * $pow(2, -$itor(scale_in));
    end
    Softmax_task(x_real,y_real);
    control_valid = 1;
    for (i=0;i<5*`length;i++)begin
        #100;
    end

    
    error_cnt = 0;
    real_max = 0;
    hard_max = 0;
    for (i=0;i<`length;i++)begin
        temp1 = $itor($signed(y_hard[i])) * $pow(2,-$itor(scale_out));
        temp2 = y_real[i];
        if (temp1 >hard_max)
            hard_max = temp1;
        if(temp2>real_max)
            real_max = temp2;
        differ =  temp1- temp2;
        if( differ >  $pow(2,-$itor(scale_out)) |differ < -$pow(2,-$itor(scale_out))) begin
            error_cnt++;
            $display("%d: differ percentile = %6.5f%%, differ = %6.5f, real = %6.5f, hard = %6.5f, y_hard = %0d",i,differ/y_real[i]*100,differ,temp2,temp1,y_hard[i]);
        end
    end
    $display("The ratio of error greater than the minimum precision: %6.5f%%",100 *error_cnt / `length);
    $display("real_max = %6.5f, hard_max = %6.5f",real_max, hard_max);
    #100 $finish();
end


endmodule