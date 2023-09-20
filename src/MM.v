`timescale 1ns / 1ps

module MM
#(
    parameter array_m = 6, 
    parameter array_n = 6, 
    parameter data_width = 8, 
    // parameter shift_width = 20,
    parameter log2_array_m = 4,
    localparam integer axis_data_width = array_m * data_width 
)
(
    clk,
    rst_n,

    set_w_port,

    // shift,
    wdata_flag_up, 

    MM_in_data,
    MM_in_data_valid,
    MM_in_last,

    MM_out_data,
    MM_out_data_valid,
    MM_out_last
);

input wire                                                      clk;
input wire                                                      rst_n;

output wire                                                      set_w_port;

// input wire [shift_width-1:0]                                    shift;
input wire                                                      wdata_flag_up; 

input wire [axis_data_width-1:0]                                MM_in_data;
input wire                                                      MM_in_data_valid;
input wire                                                      MM_in_last;

output wire [array_n*(log2_array_m+data_width*2)-1:0]           MM_out_data;
output wire                                                     MM_out_data_valid;
output wire                                                     MM_out_last;



reg [array_n*(log2_array_m+data_width*2)-1:0]    data_out_reg1;
reg [axis_data_width-1:0] feature_in_reg1;
reg [axis_data_width-1:0] weight_buffer [array_m-1:0];
reg MM_out_data_valid_reg_array [2*array_m:0];
reg MM_out_last_reg_array [2*array_m:0];
reg [5:0] weight_buffer_cnt;
//reg weight_ready;
reg wdata_flag;

wire set_w;
wire [array_n*(log2_array_m+data_width*2)-1:0]  data_out;
wire [array_m*array_n*data_width-1:0] w_packed;
wire [array_n*(log2_array_m+data_width*2)-1:0] PE_out_packed;
wire [axis_data_width-1:0] feature_in;
wire [axis_data_width-1:0] weight_in;
wire [data_width*array_m-1:0] x_packed;


genvar i;
generate
    for(i=0;i<array_m;i=i+1)begin:array_to_packed
        assign w_packed[(data_width*array_n)*i +: (data_width*array_n)] = weight_buffer[array_m-1-i];//注意下标这里是反的
    end
endgenerate

assign set_w_port = set_w;
assign MM_out_data = data_out_reg1;
assign weight_in = (wdata_flag & MM_in_data_valid) ? MM_in_data : 0;
assign feature_in = ((~wdata_flag) & MM_in_data_valid)? MM_in_data : 0;
assign set_w = (weight_buffer_cnt==array_m) ? 1:0;
assign x_packed = feature_in_reg1;
assign MM_out_data_valid = MM_out_data_valid_reg_array[2*array_m];
assign MM_out_last = MM_out_last_reg_array[2*array_m];



always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        weight_buffer_cnt <= 0;
    else if(weight_buffer_cnt == array_m)
        weight_buffer_cnt<=0;
    else if (wdata_flag & MM_in_data_valid)
        weight_buffer_cnt<=weight_buffer_cnt+1;
    else 
        weight_buffer_cnt<=weight_buffer_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        wdata_flag<=0;
    else 
        case ({wdata_flag_up,MM_in_last})
            2'b10 :  wdata_flag <= 1;
            2'b01 :  wdata_flag <= 0;
            default :  wdata_flag <= wdata_flag;
        endcase
end

always @(posedge clk)begin
    data_out_reg1 <= data_out;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        feature_in_reg1 <= 0;
    else
        feature_in_reg1 <= feature_in;
end

//always @(posedge clk or negedge rst_n) begin
//    if(~rst_n)
//        weight_ready <= 0;
//    else if (wdata_flag & MM_in_data_valid)
//        weight_ready <= 0;
//    else if (weight_buffer_cnt == array_m - 1)
//        weight_ready <= 1;
//    else
//        weight_ready <= weight_ready;
//end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        weight_buffer[0]<=0;
    else if(wdata_flag & MM_in_data_valid)
        weight_buffer[0]<=weight_in;
    else
        weight_buffer[0]<=weight_buffer[0];
end

integer j;
always @(posedge clk or negedge rst_n) begin
    for(j=1;j<array_m;j=j+1)begin
        if(~rst_n)
            weight_buffer[j]<=0;
        else if (wdata_flag & MM_in_data_valid)
            weight_buffer[j]<=weight_buffer[j-1];
        else
            weight_buffer[j]<=weight_buffer[j];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        MM_out_data_valid_reg_array[0]<=0;
    else
        MM_out_data_valid_reg_array[0]<=MM_in_data_valid & (~wdata_flag);
end
generate
    for(i=1;i<=array_m*2;i=i+1)begin
        always @(posedge clk or negedge rst_n) begin
            if(~rst_n)
                MM_out_data_valid_reg_array[i]<=0;
            else
                MM_out_data_valid_reg_array[i]<=MM_out_data_valid_reg_array[i-1];
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        MM_out_last_reg_array[0]<=0;
    else
        MM_out_last_reg_array[0]<=MM_in_last & (~wdata_flag);
end

generate
    for(i=1;i<=array_m*2;i=i+1) begin
        always @(posedge clk or negedge rst_n) begin
            if(~rst_n)
                MM_out_last_reg_array[i]<=0;
            else
                MM_out_last_reg_array[i]<=MM_out_last_reg_array[i-1];
        end
    end
endgenerate

PE_array#
(
    .data_width(data_width),
    .array_m(array_m),
    .array_n(array_n),
    .log2_array_m(log2_array_m)
)
u_PE_array
(
    .clk(clk),
    .rst_n(rst_n),
    .set_w(set_w),
    .x_packed(x_packed),
    .w_packed(w_packed),
    .PE_out_packed(PE_out_packed)
);

// generate
//     for(i=0;i<array_n;i=i+1)begin:right_shifter_u
//         right_shifter 
//         #(
//             .data_width(data_width),
//             .array_m(array_m),
//             .array_n(array_n),
//             .log2_array_m(log2_array_m),
//             .shift_width(shift_width)
//         )u_right_shifter(
//             .shift(shift),
//             .data_in(PE_out_packed[i*(log2_array_m+data_width*2)+:(log2_array_m+data_width*2)]),
//             .data_out(data_out[i*data_width+:data_width])
//         );
//     end
// endgenerate

assign data_out = PE_out_packed;
endmodule
