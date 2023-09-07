`timescale 1ns / 1ps

module EightGelus
#(
    parameter num_gelu  = 4
)
(
    input clk,
    input rst_n,
    
    // input [63:0]  in_data,
    input [num_gelu*8 -1: 0] in_data,
    input         in_valid,
    output        in_ready,
    input         in_last,
    // input [7:0]   in_keep,
    input [num_gelu-1:0]   in_keep,
    
    // output [63:0] out_data,
    output [num_gelu*8 -1: 0]  out_data,
    output        out_valid,
    input         out_ready,
    output        out_last,
    // output [7:0]  out_keep,
    output [num_gelu-1:0] out_keep,

    
    input  [2:0]  scale
    );

assign in_ready = out_ready;
reg [8:0] valid_reg;

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        valid_reg[0]<=0;
    else
        valid_reg[0] <= in_valid;
end

genvar i;
generate
for(i=1;i<9;i=i+1)begin
    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)
            valid_reg[i]<=0;
        else           
            valid_reg[i]<=valid_reg[i-1];
       
    end
end
endgenerate
assign out_valid = valid_reg[8];

reg [8:0] last_reg;

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        last_reg[0]<=0;
    else
        last_reg[0] <= in_last;
end

generate
for(i=1;i<9;i=i+1)begin
    always@(posedge clk or negedge rst_n)begin
        if(~rst_n)
            last_reg[i]<=0;
        else           
            last_reg[i]<=last_reg[i-1];
       
    end
end
endgenerate
assign out_last = last_reg[8];


reg [num_gelu*8-1:0]  in_data_delay1;

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        in_data_delay1<=0;
    else
        in_data_delay1<=in_data;
end
 
reg [num_gelu-1:0] keep_reg [8:0];
assign out_keep = keep_reg[8];
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        keep_reg[0] <=0;
    else
        keep_reg[0] <= in_keep;
end

generate 
    for(i=1;i<9;i=i+1)begin
        always@(posedge clk or negedge rst_n)begin
            if(~rst_n)
                keep_reg[i] <=0;
            else
                keep_reg[i] <= keep_reg[i-1];
        end
    end
endgenerate

generate
    for(i=0;i<num_gelu;i=i+1)begin
        gelu u_gelu(
            .clk(clk),        
            .in_scale(scale),
            .x(in_data_delay1[i*8+7 : i*8]),       
            .y_reg1(out_data[i*8+7 : i*8])  
        );
    end
endgenerate

endmodule
