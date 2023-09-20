`timescale 1ns / 1ns

`define A_size 16
`define DATA_WIDTH 8
`define SHIFT_WIDTH 10 
`define IN_Feature_Block_num 2400
`define Weight_Block_num 2400
`define OUT_Feature_Block_num 2400
`define OUT_MEM_WIDTH 21
`define F_length_width 10
`define F_width_block_num_width 5
`define W_width_block_num_width 5

`define IN_ROWS_NUM 200 //MM_buffer also has limit
`define IN_COLS_NUM 96 //Must be integer multiple of A_size
`define OUT_COLS_NUM 160 //Must be integer multiple of A_size


module MM_Ultra_tb;

parameter integer P_shift = 9;
parameter integer P_F_length = `IN_ROWS_NUM;
parameter integer P_F_width_block_num = `IN_COLS_NUM / `A_size;
parameter integer P_W_width_block_num = `OUT_COLS_NUM / `A_size;



task MM_soft(input integer x[`IN_ROWS_NUM-1:0][`IN_COLS_NUM-1:0], 
               input integer y[`IN_COLS_NUM-1:0][`OUT_COLS_NUM-1:0],
               input integer scale,
               output integer z[`IN_ROWS_NUM-1:0][`OUT_COLS_NUM-1:0]);
begin
    automatic integer temp;
    automatic integer i;
    automatic integer j;
    automatic integer k;

    for (i=0;i<`IN_ROWS_NUM;i++)begin
        for (j=0;j<`OUT_COLS_NUM;j++)begin
            temp = 0;
            for (k=0;k<`IN_COLS_NUM;k++) begin
                temp = temp + x[i][k] * y[k][j];    
            end

//            $display("%d",temp);
            if(scale > 0 )begin
                temp = (temp+(1<<(scale-1))) >>> scale; //round
            end
            if (temp > 127)
                temp = 127;
            if (temp < -128)
                temp = -128;
//                        $display("%d",temp);
            z[i][j] = temp;
        end
    end
end
endtask


reg                                                   clk;
reg                                                   rst_n;

reg [`SHIFT_WIDTH-1:0]                                shift;
reg [`F_length_width-1:0]                             F_length; //1 ~ block_num *A_size
reg [`F_width_block_num_width-1:0]                    F_width_block_num; //1 ~ block_num
reg [`W_width_block_num_width-1:0]                    W_width_block_num; //1 ~ block_num


reg                                                   in_F_valid;
wire                                                  in_F_last;
wire                                                  in_F_ready;
wire [`A_size * `DATA_WIDTH - 1:0]                    in_F_data;

reg                                                   out_data_ready;
reg                                                   in_W_valid;
wire                                                  in_W_last;
wire                                                  in_W_ready;
wire  [`A_size * `DATA_WIDTH - 1:0]                   in_W_data;

wire                                                  out_data_valid;
wire                                                  out_data_last;
wire [`A_size * `DATA_WIDTH -1:0]                     out_data;

genvar i,j;


MM_ultra
#(
    .A_size(`A_size),                                                   //Determines the side length of SA, that is, the size
    .data_width(`DATA_WIDTH),                                           //Determines the quantized data bit width
    .shift_width(`SHIFT_WIDTH),                                         //Determines the bit width of the shifter shift variable
    .Weight_Block_num(`Weight_Block_num),                               //Determines the number of weight_buffer_blocks in the IN_BUFFER.
    .IN_Feature_Block_num(`IN_Feature_Block_num),                       //Determines the number of feature_buffer_blocks in the IN_BUFFER.
    .OUT_Feature_Block_num(`OUT_Feature_Block_num),                     //Determines the number of feature_buffer_blocks in the OUT_BUFFER.
    .OUT_MEM_WIDTH(`OUT_MEM_WIDTH),                                     //Determines the data bit width of the OUT_BUFFER
    .F_length_width(`F_length_width),                                   //Determines the bit width of the F_length register and the bram size in the MM_buffer
    .F_width_block_num_width(`F_width_block_num_width),                 
    .W_width_block_num_width(`W_width_block_num_width)                  
                                                                        //F length and W width block num will be multiplied. Notice the timing
)u_MM_ultra(
    .clk(clk),
    .rst_n(rst_n),


    .shift_in(shift),
    .F_length_in(F_length), //1 ~ block_num *A_size
    .F_width_block_num_in(F_width_block_num), //1 ~ block_num
    .W_width_block_num_in(W_width_block_num), //1 ~ block_num


    .in_F_valid(in_F_valid),
    .in_F_last(in_F_last),
    .in_F_ready(in_F_ready),
    .in_F_data(in_F_data),

    .in_W_valid(in_W_valid),
    .in_W_last(in_W_last),
    .in_W_ready(in_W_ready),
    .in_W_data(in_W_data),

    .out_data_valid(out_data_valid),
    .out_data_last(out_data_last),
    .out_data_ready(out_data_ready),
    .out_data(out_data)
);

integer x[`IN_ROWS_NUM-1:0][`IN_COLS_NUM-1:0];
integer y[`IN_COLS_NUM-1:0][`OUT_COLS_NUM-1:0];

integer x_flatten[`IN_ROWS_NUM * `IN_COLS_NUM - 1:0];
integer y_flatten[`IN_COLS_NUM * `OUT_COLS_NUM - 1:0];

initial begin
    integer i;
    integer j;
    $display("x:");
    $write("[");
    for(i=0;i<`IN_ROWS_NUM;i++)begin
        $write("[");
        for(j=0;j<`IN_COLS_NUM;j++)begin
//            automatic integer temp = (i * `IN_COLS_NUM + j)%256 - 128;
            automatic integer temp = $random%128;
//            automatic integer temp = 1;
            if (temp > 127)
                temp = 127;
            if(temp < -128)
                temp = -128;
            x[i][j] = temp;
            x_flatten[i*`IN_COLS_NUM + j] = temp;
             $write("%5d,",x[i][j]);
        end
             $display("],");
    end    
    $write("]");
    $display();
    $display("y:");
    $write("[");
    for(i=0;i<`IN_COLS_NUM;i++)begin
        $write("[");
        for(j=0;j<`OUT_COLS_NUM;j++)begin
//            automatic integer temp = j; 
            automatic integer temp = $random%128;            
//            automatic integer temp = 1;
            if (temp > 127)
                temp = 127;
            if(temp < -128)
                temp = -128;
            y[i][j] = temp;
            y_flatten[i*`OUT_COLS_NUM + j] = temp;
            $write("%5d,",y[i][j]);
        end
        $display("],");
    end
    $display("]");
end
integer z_soft[`IN_ROWS_NUM-1:0][`OUT_COLS_NUM-1:0];



wire [`A_size * `DATA_WIDTH - 1:0] x_in_array [`IN_ROWS_NUM * P_F_width_block_num - 1:0];
wire [`A_size * `DATA_WIDTH - 1:0] y_in_array [`IN_COLS_NUM * P_W_width_block_num - 1:0];


generate
    for(i=0;i<`IN_ROWS_NUM * P_F_width_block_num;i++)begin
        for(j=0;j<`A_size;j++)begin
            assign x_in_array[i][j*`DATA_WIDTH +: `DATA_WIDTH] = x_flatten[i*`A_size + j];
        end
    end

    for(i=0;i<`IN_COLS_NUM * P_W_width_block_num;i++)begin
        for(j=0;j<`A_size;j++)begin
            assign y_in_array[i][j*`DATA_WIDTH +: `DATA_WIDTH] = y_flatten[i*`A_size + j];
        end
    end
endgenerate

reg start_trans;
initial start_trans = 0;

reg [31:0] in_F_addr;
initial in_F_addr = 0;

always @(posedge clk ) begin
    if(in_F_last)
        in_F_addr <=0;
    if(in_F_valid)
        in_F_addr <= in_F_addr + 1;
end

assign in_F_data = x_in_array[in_F_addr];
wire [`DATA_WIDTH - 1:0] F_in_data_display  [`A_size - 1:0];
generate
    for(i=0;i<`A_size;i++)begin
        assign F_in_data_display[i] = in_F_data[i*`DATA_WIDTH +: `DATA_WIDTH];
    end
endgenerate
assign in_F_last =(in_F_addr == `IN_ROWS_NUM * P_F_width_block_num - 1)? 1:0;

always @(posedge clk) begin
    if(~rst_n)
        in_F_valid <= 0;
    else if (start_trans)
        in_F_valid <= 1;
    else if (in_F_last)
        in_F_valid <= 0;
end

reg [31:0] in_W_addr;
initial in_W_addr = 0;

always @(posedge clk ) begin
    if(in_W_last)
        in_W_addr <=0;
    if(in_W_valid)
        in_W_addr <= in_W_addr + 1;
end

assign in_W_data = y_in_array[in_W_addr];
wire [`DATA_WIDTH - 1:0] W_in_data_display [`A_size - 1:0];
generate
    for(i=0;i<`A_size;i++)begin
        assign W_in_data_display[i] = in_W_data[i*`DATA_WIDTH +: `DATA_WIDTH];
    end
endgenerate
assign in_W_last =(in_W_addr == `IN_COLS_NUM * P_W_width_block_num - 1)? 1:0;

always @(posedge clk) begin
    if(~rst_n)
        in_W_valid <= 0;
    else if (start_trans)
        in_W_valid <= 1;
    else if (in_W_last)
        in_W_valid <= 0;
end

wire [`DATA_WIDTH - 1:0] out_data_display   [`A_size - 1:0];
generate
    for(i=0;i<`A_size;i++)begin
        assign out_data_display[i] = out_data[i*`DATA_WIDTH +: `DATA_WIDTH];
    end
endgenerate

reg [`A_size * `DATA_WIDTH - 1:0] z_hard [`IN_ROWS_NUM * P_W_width_block_num-1:0];
reg [31:0] z_hard_addr;
integer z_hard_array [`IN_ROWS_NUM-1:0][`OUT_COLS_NUM-1:0];
wire [`DATA_WIDTH - 1:0] z_hard_flatten [`IN_ROWS_NUM * `OUT_COLS_NUM-1:0];
initial z_hard_addr = 0;

always @(posedge clk ) begin
    if (out_data_last)
        z_hard_addr <= 0;
    else if(out_data_valid&out_data_ready)
        z_hard_addr <= z_hard_addr + 1;
end

always @(posedge clk) begin
    if(out_data_valid &out_data_ready)
        z_hard[z_hard_addr] <= out_data;
end

generate
    for(i = 0;i<`IN_ROWS_NUM * P_W_width_block_num;i++)begin
        for(j=0;j<`A_size;j++)begin
            assign z_hard_flatten[i*`A_size+j] = z_hard[i][j*`DATA_WIDTH +: `DATA_WIDTH]; 
        end
    end

    for(i=0;i<`IN_ROWS_NUM;i++)begin
        for(j=0;j<`OUT_COLS_NUM;j++)begin
            always @(*) begin
                z_hard_array[i][j] = $signed(z_hard_flatten[i*`OUT_COLS_NUM + j]);
            end
        end
    end
endgenerate



initial clk = 0;
always  begin
    #5 clk = ~clk;
end

reg out_data_ready_gen;

initial out_data_ready_gen = 0;
always begin
    #10 out_data_ready_gen = //~out_data_ready_gen;
                            {$random}%2;
end

always @(posedge clk ) begin
    out_data_ready <= out_data_ready_gen;
end

initial begin
    shift = 0;
    F_length = 0;
    F_width_block_num = 0;
    W_width_block_num =0;
end


initial begin
    rst_n = 0;
    #50 rst_n = 1;
    #50
    #1000
    shift = P_shift;
    F_length = P_F_length;
    F_width_block_num = P_F_width_block_num;
    W_width_block_num = P_W_width_block_num;
    MM_soft(x,y,shift,z_soft);
    #1000 start_trans = 1;
    #10 start_trans = 0;
end
integer error = 0;
integer zero_error = 0;

integer m,n;
always  begin
    #10
    if(out_data_last) begin
        error = 0;
        #(200*`IN_ROWS_NUM)
        $display("z_hard:");
        for(m=0;m<`IN_ROWS_NUM;m++)begin
            for(n=0;n<`OUT_COLS_NUM;n++)begin
                if($signed(z_hard_array[m][n])!= z_soft[m][n])begin
                    $write("error:hard = %0d, soft = %0d.      ",$signed(z_hard_array[m][n]),z_soft[m][n]);
                    error++;
                end
                else
                    $write("%7d,",$signed(z_hard_array[m][n]));
            end
            $display();
        end
        #10;
        if(error != 0)
            $display("Error!, error = %d.",error);
        else
        $display("No Error.");

        for(m=0;m<`OUT_Feature_Block_num;m++)begin
            if(u_MM_ultra.u_MM_out_buffer.F_array[m]!=0)
                zero_error= zero_error+1;
        end
        if(zero_error != 0)
            $display("Error!, zero_error = %d.",zero_error);
        else
        $display("No zero_error.");
        $finish();
    end
end
    
endmodule
