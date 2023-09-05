`timescale 1ns / 1ps

module MM_ultra_top #
	(
		// Users to add parameters here
        parameter integer     array_size=24,                                      //决定了SA的边长，即大小
        parameter integer     data_width=8,                                       //决定了量化的数据位宽
        parameter integer     shift_width=5,                                      //决定了移位器移位变量的位宽
        parameter integer     Weight_block_num=2000,                              //决定了IN_BUFFER里面weight_buffer_block的数量 一个block包含A_size个数据,数据位宽 data_width
        parameter integer     in_feature_Block_num=2000,                          //决定了IN_BUFFER里面feature_buffer_block的数量 一个block包含A_size个数据,数据位宽 data_width
        parameter integer     out_feature_block_num=2000,                         //决定了OUT_BUFFER里面feature_buffer_block的数量 一个block包含A_size个数据,数据位宽OUT_MEM_WIDTH
        parameter integer     out_mem_width=21,                                   //决定了OUT_BUFFER的数据位宽
        parameter integer     feature_length_width=10,                            //决定了F_length寄存器位宽以及MM_buffer里面bram大小
        parameter integer     feature_width_block_num_width=6,                    //决定了F_width_block_num寄存器位宽
        parameter integer     weight_width_block_num_width=6,                     //决定了W_width_block_num寄存器位宽以及MM_buffer里面bram大小
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		localparam integer C_S00_AXI_DATA_WIDTH	= 32,
		localparam integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		input 										aclk,
    	input 										aresetn,
	
    	input [array_size*data_width-1:0] 	        s0_axis_tdata,
    	input       								s0_axis_tvalid,
    	output      								s0_axis_tready,
    	input       								s0_axis_tlast,

    	input [array_size*data_width-1:0] 	        s1_axis_tdata,
    	input       								s1_axis_tvalid,
    	output      								s1_axis_tready,
    	input       								s1_axis_tlast,
    		
    	output [array_size*data_width-1:0] 	        m0_axis_tdata,
    	output       								m0_axis_tvalid,
    	input        								m0_axis_tready,
    	output      			 					m0_axis_tlast,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	MM_ultra_axi # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),

        .array_size(array_size),                  
        .data_width(data_width),                   
        .shift_width(shift_width),                  
        .Weight_block_num(Weight_block_num),          
        .in_feature_Block_num(in_feature_Block_num),      
        .out_feature_block_num(out_feature_block_num),     
        .out_mem_width(out_mem_width),               
        .feature_length_width(feature_length_width),        
        .feature_width_block_num_width(feature_width_block_num_width),
        .weight_width_block_num_width(weight_width_block_num_width)
	) U_MM_ultra_axi (
		.S_AXI_ACLK(aclk),
		.S_AXI_ARESETN(aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),

		.axis_aclk(aclk),
		.aresetn(aresetn),

		.s0_axis_tdata(s0_axis_tdata),
		.s0_axis_tvalid(s0_axis_tvalid),
		.s0_axis_tready(s0_axis_tready),
		.s0_axis_tlast(s0_axis_tlast),
		
		.s1_axis_tdata(s1_axis_tdata),
		.s1_axis_tvalid(s1_axis_tvalid),
		.s1_axis_tready(s1_axis_tready),
		.s1_axis_tlast(s1_axis_tlast),

		.m0_axis_tdata(m0_axis_tdata),
		.m0_axis_tvalid(m0_axis_tvalid),
		.m0_axis_tready(m0_axis_tready),
		.m0_axis_tlast(m0_axis_tlast)
	);

	// Add user logic here

	// User logic ends

	endmodule
