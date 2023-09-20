`timescale 1ns / 1ps

module PE_line
#(
    parameter array_m = 4, 
    parameter array_n = 4, 
    parameter data_width = 8,
    parameter log2_array_m = 2
)
(
    input                                               clk,
    input                                               rst_n,
    input                                               set_w,
    input [data_width-1:0]                              x,
    input [array_n*(log2_array_m+data_width*2)-1:0]     psum_in_packed,
    input [array_n*data_width-1:0] w_packed,
    output [array_n*(log2_array_m+data_width*2)-1:0]    psum_out_packed
);

wire [2*data_width+log2_array_m-1:0] psum_in_array [array_n-1:0];
wire [2*data_width+log2_array_m-1:0] psum_out_array [array_n-1:0];
wire [data_width-1:0] w_array [array_n-1:0];
wire [data_width-1:0] x_array [array_n:0]; 

assign x_array[0]=x;

genvar i;
generate
    for(i=0;i<array_n;i=i+1)begin:packed_to_array_1
        assign w_array[i] = w_packed[ data_width*i +: data_width];
        assign psum_out_packed[(log2_array_m+data_width*2)*i +: (log2_array_m+data_width*2)] = psum_out_array[i];
        assign psum_in_array[i] = psum_in_packed[(log2_array_m+data_width*2)*i +: (log2_array_m+data_width*2)];
    end
endgenerate

generate
    for(i=0;i<array_n;i=i+1)begin:array_line
        PE#(
            .data_width(data_width),
            .array_m(array_m),
            .array_n(array_n),   
            .log2_array_m(log2_array_m)
        )
        PE_u(
            .clk(clk),
            .set_w(set_w),   
            .rst_n(rst_n),   
            .x_in(x_array[i]),
            .w(w_array[i]),
            .psum_in(psum_in_array[i]), 
            .x_out(x_array[i+1]),
            .psum_out(psum_out_array[i]) 
        );
    end
endgenerate
endmodule
