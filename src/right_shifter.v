`timescale 1ns / 1ps
//ËÄÉáÎåÈë
module right_shifter
#(
    parameter before_data_width = 32,
    parameter after_data_width = 8,
    parameter shift_width = 5
)
(
    shift,
    data_in,
    data_out
);

input wire [shift_width-1:0]shift;
input wire signed [before_data_width-1:0] data_in;
output reg signed[after_data_width-1:0] data_out;

wire signed [before_data_width-1:0] temp1_out;
wire signed [before_data_width-1:0] temp2_out;

assign temp1_out = data_in >>> shift;
assign temp2_out = data_in[shift-1] ? temp1_out + 1 : temp1_out;

wire under_min = temp2_out[before_data_width-1] & (~(& temp2_out[before_data_width-2:after_data_width-1]));
wire over_max = (~temp2_out[before_data_width-1]) & (|temp2_out[before_data_width-2:after_data_width-1]);

wire under_min_S0 = data_in[before_data_width-1] & (~(& data_in[before_data_width-2:after_data_width-1]));
wire over_max_S0 = (~data_in[before_data_width-1]) & (|data_in[before_data_width-2:after_data_width-1]);

always @(*) begin
    if(shift == 0)
        case ({under_min_S0,over_max_S0})
            2'b10: data_out = {1'b1,{(after_data_width-1){1'b0}}};//data_out = 8'b1000_0000;
            2'b01: data_out = {1'b0,{(after_data_width-1){1'b1}}};//8'b0111_1111;
            default: data_out = data_in;
        endcase
    else begin
        case ({under_min,over_max})
            2'b10: data_out = {1'b1,{(after_data_width-1){1'b0}}};//data_out = 8'b1000_0000;
            2'b01: data_out = {1'b0,{(after_data_width-1){1'b1}}};//8'b0111_1111;
            default: data_out = temp2_out[after_data_width-1:0];
        endcase
    end
end

endmodule

