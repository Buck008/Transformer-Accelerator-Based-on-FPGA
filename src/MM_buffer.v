`timescale 1ns / 1ps
`define IDLE 2'b00
`define SET_WEIGHT 2'b01
`define SET_FEATURE 2'b11

module MM_buffer#
(
    parameter integer                                  array_m = 3,
    parameter integer                                  array_n = 3,
    parameter integer                                  data_width = 8,
    parameter integer                                  log2_array_m = 4,
    parameter integer                                  F_length_width = 10,
    parameter integer                                  W_width_block_num_width = 5 
)(
    input                                                   clk,
    input                                                   rst_n,


    input [F_length_width-1:0]                              FL, 
    input [W_width_block_num_width-1:0]                     num_blobk_W, 


    input [array_m * data_width - 1:0]                      MM_buffer_inWeight_data,
    input                                                   MM_buffer_inWeight_valid,
    output                                                  MM_buffer_inWeight_ready,
    input                                                   MM_buffer_inWeight_last,

    input [array_m * data_width - 1:0]                      MM_buffer_inFeature_data,
    input                                                   MM_buffer_inFeature_valid,
    output                                                  MM_buffer_inFeature_ready,
    input                                                   MM_buffer_inFeature_last,

    output [array_n*(log2_array_m+data_width*2)-1:0]        MM_buffer_out_data,
    output                                                  MM_buffer_out_valid,
    output                                                  MM_buffer_out_last
);
localparam integer feature_buffer_depth = $pow(2, F_length_width);
localparam integer W_block_num_width = W_width_block_num_width + log2_array_m;
localparam integer weight_buffer_depth = $pow(2, W_width_block_num_width) * array_m;


reg [1:0]                                                   state;


reg                                                         start;
wire                                                        start_ahead1;
reg                                                         set_w_delay1;
reg                                                         w_end;
reg                                                         weight_flag_up;

reg [W_block_num_width-1:0]                                 total_WL_reg;
reg [F_length_width-1:0]                                    FL_reg;

reg [W_block_num_width-1:0]                                 weight_buffer_cnt;
reg [W_block_num_width-1:0]                                 weight_buffer_in_addr;
reg [array_m * data_width - 1:0]                            weight_buffer [weight_buffer_depth-1:0];

reg [F_length_width-1:0]                                    feature_buffer_cnt;
reg [F_length_width-1:0]                                    feature_buffer_in_addr;
reg [array_m * data_width - 1:0]                            feature_buffer [feature_buffer_depth-1:0];

wire                                                        both_full;
reg                                                         both_full_delay1;

reg [array_m * data_width - 1:0]                            MM_in_data;
reg                                                         MM_in_data_valid;
reg                                                         MM_in_last;

reg                                                         input_weight_valid;
wire                                                        input_weight_last;
reg [array_m * data_width - 1:0]                            input_weight_data;
wire [W_block_num_width-1:0]                                input_weight_addr;
reg [W_width_block_num_width-1:0]                           input_weight_col;
reg [log2_array_m-1:0]                                      input_weight_row;
reg [W_block_num_width-1:0]                                 weight_cnt;                                

reg                                                         input_feature_valid;
wire                                                        input_feature_last;
reg [array_m * data_width - 1:0]                            input_feature_data;
reg [F_length_width-1:0]                                    input_feature_addr;
reg [F_length_width-1:0]                                    feature_cnt;

wire                                                        set_w;
wire                                                        total_last;
wire                                                        wdata_flag_up;

wire [array_n*(log2_array_m+data_width*2)-1:0]              output_feature_data;
wire                                                        output_feature_valid;
wire                                                        output_feature_last;


assign both_full = (weight_buffer_cnt == total_WL_reg) & (feature_buffer_cnt == FL_reg);
assign MM_buffer_out_valid = output_feature_valid;
assign MM_buffer_out_data = output_feature_data;
assign MM_buffer_out_last = total_last;
assign total_last = output_feature_last & w_end;
assign MM_buffer_inWeight_ready = (weight_buffer_cnt<=total_WL_reg-1);
assign MM_buffer_inFeature_ready = (feature_buffer_cnt<=FL_reg-1);
// assign wdata_flag_up = start | weight_flag_up;
assign wdata_flag_up = start | weight_flag_up & (state != 0);
assign input_weight_last = weight_cnt == array_m - 1;
assign input_feature_last = feature_cnt == FL_reg - 1;
assign input_weight_addr = input_weight_row * num_blobk_W + input_weight_col;
assign start_ahead1 = both_full & (~both_full_delay1);


always @(*) begin
    case (state)
        `IDLE : begin
            MM_in_data_valid = 0;
            MM_in_last = 0;
            MM_in_data = 0;
        end 
        `SET_WEIGHT : begin
            MM_in_data_valid = input_weight_valid;
            MM_in_last = input_weight_last;
            MM_in_data = input_weight_data;
        end
        `SET_FEATURE: begin
            MM_in_data_valid = input_feature_valid;
            MM_in_last = input_feature_last;
            MM_in_data = input_feature_data;
        end
        default: begin
            MM_in_data_valid = 0;
            MM_in_last = 0;
            MM_in_data = 0;
        end
    endcase
end

initial both_full_delay1 =0;
always @(posedge clk ) begin
    both_full_delay1 <= both_full;
end

initial start = 0;
always @(posedge clk ) begin
    start <= start_ahead1;
end
initial set_w_delay1= 0;
always @(posedge clk ) begin
    set_w_delay1 <= set_w;
end
initial total_WL_reg= 0;
always @(posedge clk ) begin
    total_WL_reg <= num_blobk_W * array_m;
end
initial FL_reg= 0;
always @(posedge clk ) begin
    FL_reg <= FL;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        weight_buffer_cnt <= 0;
    else if ( MM_buffer_inWeight_valid & MM_buffer_inWeight_ready)
        weight_buffer_cnt <= weight_buffer_cnt + 1;
    else if (total_last)
        weight_buffer_cnt <= 0;
    else
        weight_buffer_cnt <= weight_buffer_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        feature_buffer_cnt <= 0;
    else if ( MM_buffer_inFeature_valid & MM_buffer_inFeature_ready)
        feature_buffer_cnt <= feature_buffer_cnt + 1;
    else if (total_last)
        feature_buffer_cnt <= 0;
    else
        feature_buffer_cnt <= feature_buffer_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        w_end <= 1;
    else if(start)
        w_end <= 0;
    else if (input_weight_addr == total_WL_reg -1)
        w_end <= 1;
    else 
        w_end <= w_end;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        weight_buffer_in_addr <= 0;
    else if ( MM_buffer_inWeight_last)
        weight_buffer_in_addr <= 0;
    else if ( MM_buffer_inWeight_valid & MM_buffer_inWeight_ready)
        weight_buffer_in_addr <= weight_buffer_in_addr + 1;
    else 
        weight_buffer_in_addr <= weight_buffer_in_addr;
end

always @(posedge clk ) begin
    if( MM_buffer_inWeight_valid & MM_buffer_inWeight_ready)
        weight_buffer[weight_buffer_in_addr] <= MM_buffer_inWeight_data;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        feature_buffer_in_addr <= 0;
    else if ( MM_buffer_inFeature_last)
        feature_buffer_in_addr <= 0;
    else if ( MM_buffer_inFeature_valid & MM_buffer_inFeature_ready)
        feature_buffer_in_addr <= feature_buffer_in_addr + 1;
    else 
        feature_buffer_in_addr <= feature_buffer_in_addr;
end

always @(posedge clk ) begin
    if( MM_buffer_inFeature_valid & MM_buffer_inFeature_ready)
        feature_buffer[feature_buffer_in_addr] <= MM_buffer_inFeature_data;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        state <= `IDLE;
    else if (state == `IDLE) begin //only start can wake up state
        if (start)
            state <= `SET_WEIGHT;
        else
            state <= state;
    end
    else begin
        case ({weight_flag_up, set_w_delay1,total_last})
            3'b100: state <= `SET_WEIGHT;
            3'b010: state <= `SET_FEATURE;
            3'b001: state <= `IDLE;
            default: state <= state;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
        weight_flag_up <= 0;
    else if(weight_flag_up)
        weight_flag_up <= 0;
    else if (output_feature_last)
        weight_flag_up <= 1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        input_weight_valid <= 0;
    else if(wdata_flag_up)
        input_weight_valid <= 1;
    else if(input_weight_last)
        input_weight_valid <= 0;
    else
        input_weight_valid <= input_weight_valid;
end

always @(posedge clk ) begin
    input_weight_data <= weight_buffer[input_weight_addr];
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        weight_cnt <= 0;
    else if (weight_cnt == array_m)
        weight_cnt <= 0;
    else if (state == `SET_WEIGHT & input_weight_valid)
        weight_cnt <= weight_cnt + 1;
    else
        weight_cnt <= weight_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        input_feature_valid <= 0;
    else if (set_w_delay1)
        input_feature_valid <= 1;
    else if (input_feature_last)
        input_feature_valid <= 0;
    else 
        input_feature_valid <= input_feature_valid;
end

always @(posedge clk ) begin
    input_feature_data <= feature_buffer[input_feature_addr];
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        input_feature_addr <= 0;
    else if (input_feature_addr == FL_reg - 1)
        input_feature_addr <= 0;
    else if (set_w_delay1)
        input_feature_addr <= 1;
    else if (state == `SET_FEATURE & input_feature_valid & input_feature_addr!=0)//make sure that only set_w_dealy1 can pull up the addr when it equal to zero 
        input_feature_addr <= input_feature_addr + 1;
    else
        input_feature_addr <= input_feature_addr;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        feature_cnt <= 0;
    else if(feature_cnt == FL_reg)
        feature_cnt <= 0;
    else if(state == `SET_FEATURE & input_feature_valid)
        feature_cnt <= feature_cnt + 1;
    else 
        feature_cnt <= feature_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        input_weight_col <= 0;
    else if(input_weight_col == num_blobk_W)
        input_weight_col <= 0;
    else if(input_weight_last)
        input_weight_col <= input_weight_col + 1;
    else
        input_weight_col <= input_weight_col;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        input_weight_row <= 0;
    else if (input_weight_row == array_m - 1)
        input_weight_row <= 0;
    else if (wdata_flag_up)
        input_weight_row <= 1;
    else if (input_weight_row != 0)
        input_weight_row <= input_weight_row + 1;
end

MM
#(
    .array_m(array_m), //Array 行数
    .array_n(array_n), //Array 列数
    .data_width(data_width), //数据宽度
    .log2_array_m(log2_array_m)
) u_MM
(
    .clk(clk),
    .rst_n(rst_n),

    .set_w_port(set_w),

    .wdata_flag_up(wdata_flag_up), 

    .MM_in_data(MM_in_data),
    .MM_in_data_valid(MM_in_data_valid),
    .MM_in_last(MM_in_last),

    .MM_out_data(output_feature_data),
    .MM_out_data_valid(output_feature_valid),
    .MM_out_last(output_feature_last)
);
    
endmodule
