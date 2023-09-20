`timescale 1ns / 1ps

module AdderS
#(
    parameter integer A_size = 4,
    parameter integer data_width = 8
)(
    input  [A_size * data_width - 1 : 0] A,
    input  [A_size * data_width - 1 : 0] B,
    output reg [A_size * data_width - 1 : 0] C
);
wire [(data_width + 1)-1:0] temp [A_size-1:0]; //Double sign bit to determine positive overflow or negative overflow
wire [data_width - 1:0] C_array_display [A_size-1:0];
genvar i;

generate
    for(i=0;i<A_size;i=i+1)begin
        assign C_array_display[i] = C[i*data_width +: data_width];
    end
endgenerate

generate
    for(i=0;i<A_size;i=i+1)begin
        assign temp[i] = {A[(i+1)*data_width-1],A[i *data_width +: data_width]} 
                       + {B[(i+1)*data_width-1],B[i *data_width +: data_width]};
    end
endgenerate
generate
    for(i=0;i<A_size;i=i+1)begin
        always @(*) begin
            case (temp[i][data_width:data_width-1])
                2'b01: C[i * data_width +: data_width] = {1'b0,{(data_width-1){1'b1}}};   
                2'b10: C[i * data_width +: data_width] = {1'b1,{(data_width-1){1'b0}}};   
                default: C[i * data_width +: data_width] = temp[i][data_width-1:0];
            endcase
         
        end
    end
endgenerate
endmodule
