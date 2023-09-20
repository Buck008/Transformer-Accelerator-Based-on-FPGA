`timescale 1ns / 1ps

module PE_array
(
    clk,
    rst_n,
    set_w,
    x_packed,
    w_packed,
    PE_out_packed
);
parameter integer data_width = 8;
parameter integer array_m = 16;
parameter integer array_n = 16;
parameter integer log2_array_m = 4;


input wire clk;
input wire rst_n;
input wire set_w;
input [data_width*array_m-1:0]                     x_packed;
input [array_m*array_n*data_width-1:0]             w_packed; 
output [array_n*(log2_array_m+data_width*2)-1:0]   PE_out_packed;

wire [array_n*data_width-1:0] w_line_array [array_m-1:0];
wire [array_n*(log2_array_m+data_width*2)-1:0] psum_in_packed_array [array_m:0];

wire [data_width-1:0] x_array [array_m-1:0];

//assign PE_out_packed = psum_in_packed_array[array_m];
wire [array_n*(log2_array_m+data_width*2)-1:0] psum_in_packed_last;
assign psum_in_packed_last = psum_in_packed_array[array_m];
genvar i;
generate
    for(i=array_n-1;i>=0;i=i-1) begin: buf_out
        if(i==array_n-1)begin
            assign PE_out_packed[(log2_array_m+data_width*2)*i +: (log2_array_m+data_width*2)] =  psum_in_packed_last[(log2_array_m+data_width*2)*i +: (log2_array_m+data_width*2)];
        end
        else begin
            reg [(log2_array_m+data_width*2)-1:0] out_buf [array_n-2-i:0];
            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)
                    out_buf[0]<=0;
                else
                    out_buf[0]<=psum_in_packed_last[i*(log2_array_m+data_width*2) +: (log2_array_m+data_width*2)];
            end
            
            genvar k;
            for (k=1;k<=array_n-2-i;k=k+1)begin:out_buf_for
                always@(posedge clk or negedge rst_n)begin
                    if(~rst_n)
                        out_buf[k]<=0;
                    else
                        out_buf[k]<=out_buf[k-1];
                end
            end
            assign PE_out_packed[i*(log2_array_m+data_width*2) +: (log2_array_m+data_width*2)] = out_buf [array_n-2-i];
        end
    end
endgenerate
assign psum_in_packed_array[0] = 0;


generate
    for (i=0;i<array_m;i=i+1)begin:packed_to_array_1
        assign x_array[i] = x_packed[data_width*i +: data_width];
        assign w_line_array[i] = w_packed[(array_n*data_width)*i +: (array_n*data_width)];
    end
endgenerate

generate
    for (i=0; i<array_m; i=i+1) begin:array
        if (i==0) begin
            PE_line #(
                .data_width (data_width),
                .array_m(array_m),
                .array_n(array_n),
                .log2_array_m(log2_array_m)
            )
            PE_line_u
            (
                .clk(clk),
                .rst_n(rst_n),
                .set_w(set_w),
                .x(x_array[i]),
                .psum_in_packed(psum_in_packed_array[i]),
                .w_packed(w_line_array[i]),
                .psum_out_packed(psum_in_packed_array[i+1])
            );            
        end
        else begin
            reg [data_width-1:0] x_buf [i-1:0];
            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)
                    x_buf[0]<=0;
                else
                    x_buf[0]<=x_array[i];
            end

            genvar k;
            for (k=1;k<=i-1;k=k+1)begin:x_buf_for
                always@(posedge clk or negedge rst_n)begin
                    if(~rst_n)
                        x_buf[k]<=0;
                    else
                        x_buf[k]<=x_buf[k-1];
                end
            end

             PE_line #(
                .data_width (data_width),
                .array_m(array_m),
                .array_n(array_n),
                .log2_array_m(log2_array_m)
            )
            PE_line_u
            (
                .clk(clk),
                .rst_n(rst_n),
                .set_w(set_w),
                .x(x_buf[i-1]),
                .psum_in_packed(psum_in_packed_array[i]),
                .w_packed(w_line_array[i]),
                .psum_out_packed(psum_in_packed_array[i+1])
            );           
        end
    end
endgenerate
endmodule
