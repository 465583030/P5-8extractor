//	Module name: test
//	Authority @ lijunnan
//	Last edited time: 2017/02/16
//	Function outline: programmable parser
//
// 	The load ahead is long and has no end.

`timescale 1ns/1ps

module test();

reg clk;
reg	reset;


//interface_signal//
reg	localbus_cs_n;
reg	localbus_rd_wr;
reg	[31:0]	localbus_data;
reg	localbus_ale;
wire	localbus_ack_n;
wire	[31:0]	localbus_data_out;
wire	um2cdp_path;
reg		cdp2um_data_valid;
reg		[138:0]	cdp2um_data;
wire	um2cdp_tx_enable;
wire	um2cdp_data_valid;
wire	[138:0]	um2cdp_data;
reg		cdp2um_tx_enable;
wire	um2cdp_rule_wrreq;
wire	[29:0]	um2cdp_rule;
reg		[4:0]	cdp2um_rule_usedw;

um um(
clk,
reset,

//---localbus--//
localbus_cs_n,
localbus_rd_wr,
localbus_data,
localbus_ale, 
localbus_ack_n,  
localbus_data_out,		
//--cdp--//
um2cdp_path,
cdp2um_data_valid,
cdp2um_data,
um2cdp_tx_enable,
um2cdp_data_valid,
um2cdp_data,
cdp2um_tx_enable,
um2cdp_rule,
um2cdp_rule_wrreq,
cdp2um_rule_usedw
);


//packet data;
integer i;
reg	[138:0]	pkt[9:0];
initial begin
	pkt[0] = {3'b101,8'b0,48'h1111_2222_3333,48'h4444_5555_6666,16'h0800,16'h4500};// mac1
	pkt[1] = {3'b100,8'b0,32'h0032_7919,32'h0000_4011,32'h7dfc_c0a8,32'h0000_0000};
	pkt[2] = {3'b100,8'b0,32'h0101_0800,32'h4789_0400,32'h0500_6162,32'h6364_6566};
	pkt[3] = {3'b100,8'b0,32'h6768_4444,32'h5555_6666,32'h1111_2222,32'h3333_0800};
	pkt[4] = {3'b100,8'b0,32'h0032_7919,32'h0000_4011,32'h7dfc_c0a8,32'h0164_c0a8};
	pkt[5] = {3'b100,8'b0,32'h0032_7919,32'h0000_4011,32'h7dfc_c0a8,32'h0164_c0a8};
	pkt[6] = {3'b110,8'b0,32'h0032_7919,32'h0000_4011,32'h7dfc_c0a8,32'h0164_c0a8};
	pkt[7] = {3'b101,8'b0,48'hffff_ffff_ffff,48'h4444_5555_6666,16'h0806,16'h0001};// arp_request;
	pkt[8] = {3'b101,8'b0,48'h4444_5555_6666,48'h1111_2222_3333,16'h0806,16'h0001};// arp_respond;
	pkt[9] = {3'b101,8'b0,48'h4444_5555_6666,48'h1111_2222_3333,16'h0800,16'h0001};// mac2;
end



initial begin
	reset = 1'b1;
	clk = 1'b0;
	cdp2um_data_valid = 1'b0;
	cdp2um_data = 138'b0;
	cdp2um_tx_enable = 1'b1;
	cdp2um_rule_usedw = 5'd1;
	localbus_rd_wr = 1'b1;
	localbus_ale = 1'b0;
	localbus_cs_n= 1'b1;
	localbus_data= 32'b0;
	#1 reset = 1'b0;
	#1 reset = 1'b1;
	forever #1 clk = ~clk;
end
//rule set//
// ruleSet <= {2'd1,32'h0800_4500,8'h0,
//					8'd1,8'd9,8'd24,	// '1' represent "IP"
//					1'b0,1'b0,6'b0,8'd4,8'b0,8'd20,1'b1,7'd12,8'd1,48'b0,8'd1};
initial begin
	//add;
	#20 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd1,8'h00};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0001;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h00_0000_00;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,8'd0,8'd24,1'b0,1'b0,6'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'b0,8'd8,1'b1,7'd0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd9};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//*******************************
	// 2; udp
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd1,8'h00};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0001;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h00_0000_01;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd2,8'd0,8'd24,1'b0,1'b0,6'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'b0,8'd8,1'b1,7'd0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd10};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	//
	//**********************************************************
	// 3; vxlan
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd1,8'h00};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0001;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h00_0000_02;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd3,8'd0,8'd24,1'b1,1'b1,6'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'b0,8'd8,1'b1,7'd0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd11};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	
	//********************************************
	
	// 4;
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd1,8'h00};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h00_0000_01;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'd0,8'd24,1'b1,1'b1,6'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'b0,8'd8,1'b1,7'd0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd12};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	
	
	
	//add_end;


	#20 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd1,8'h08};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0001;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h00_0000_00;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,8'd9,8'd24,1'b0,1'b1,6'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'b0,8'd20,1'b1,7'd12};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd1};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	
	//lookuprule
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0006;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'h0,4'h0,20'h1111_2};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0007;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {12'h222,16'h3333,4'h1};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	
	
	//arp;// ruleSet <= {2'd1,32'h0806_0000,8'h0,	// add, type, state;
					// 8'd9,8'd9,8'd0,	//nextState, typeOffset;
					// 1'b1,1'b0,6'b0,8'd4,8'b0,8'd20,1'b0,7'd12,8'd1,48'b0,8'd2};
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd1,8'h08};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0001;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h06_0000_00;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd9,8'd9,8'd0,1'b1,1'b0,6'b0};// 8'd9,8'd9,8'd0,1'b1,1'b0,6'b0
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'b0,8'd20,1'b1,7'd12};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd2};	// ruleID;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//lookuprule
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0006;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'h0,4'h1,20'hffff_f};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0007;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {12'hfff,16'hffff,4'hf};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	
	//mac2
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0006;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'h0,4'h2,20'h4444_5};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0007;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {12'h555,16'h6666,4'h2};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	
	/*
	//del
	//arp;// ruleSet <= {2'd2,32'h0806_0000,8'h0,	// add, type, state;
					// 8'd9,8'd9,8'd0,	//nextState, typeOffset;
					// 1'b1,1'b0,6'b0,8'd4,8'b0,8'd20,1'b0,7'd12,8'd1,48'b0,8'd2};
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd2,8'h08};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0001;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h06_0000_00;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd9,8'd9,8'd0,1'b1,1'b0,6'b0};// 8'd9,8'd9,8'd0,1'b1,1'b0,6'b0
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'b0,8'd20,1'b1,7'd12};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd2};	// ruleID;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	*/
	//udp
	// ruleSet <= {2'd1,32'h1100_0000,8'h1,	// add, type, state;
					// 8'd2,8'd2,8'd16,	//nextState, typeOffset;
					// 1'b0,1'b1,6'b0,8'd4,8'b0,8'd8,1'b0,7'd0,8'd0,48'b0,8'd3};
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd1,8'h11};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0001;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h00_0000_01;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd2,8'd2,8'd16,1'b0,1'b1,6'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd5,8'b0,8'd8,1'b1,7'd0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd0,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd3};	// ruleID;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	
	
	//vxlan
	// ruleSet <= {2'd1,32'h4789_0000,8'h2,	// add, type, state;
					// 8'd9,8'd9,8'd0,	//nextState, typeOffset;
					// 1'b1,1'b0,6'b0,8'd4,8'b0,8'd20,1'b0,7'd0,8'd0,48'b0,8'd4};
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0000;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {22'b0,2'd1,8'h47};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0001;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= 32'h89_0000_02;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0002;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd9,8'd9,8'd0,1'b1,1'b0,6'b0};// 8'd9,8'd9,8'd0,1'b1,1'b0,6'b0
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0003;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd4,8'b0,8'd20,1'b1,7'd12};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0004;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {8'd1,24'b0};
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	//
	#4 begin
		localbus_ale <= 1'b1;
		localbus_data <= 32'h1400_0005;
		localbus_rd_wr<= 1'b0;
	end
	#4 begin
		localbus_ale <= 1'b0;
		localbus_cs_n <= 1'b0;
		localbus_data <= {24'b0,8'd4};	// ruleID;
	end
	#4 begin
		localbus_cs_n <= 1'b1;
	end
	
	
	// // add arp;
	// #10 begin 
		// ruleSet_valid <= 1'b1;
		// ruleSet <= {2'd1,32'h0806_0001,8'h0,	// add, type, state;
					// 8'd9,8'd9,8'd0,	//nextState, typeOffset;
					// 1'b1,1'b0,6'b0,8'd4,8'b0,8'd20,1'b0,7'd12,8'd1,48'b0,8'd2};
		// //end_tag, extraction_tag,reserved, HVoffset, length, fieldLocations;
	// end
	// #2 ruleSet_valid <= 1'b0;
	// //read arp;
	// /* #10 begin 
		// ruleSet_valid <= 1'b1;
		// ruleSet <= {2'd0,32'h0806_0001,8'h0,	// add, type, state;
					// 8'd9,8'd9,	//nextState, typeOffset;
					// 1'b1,1'b0,6'b0,8'd4,8'b0,8'd20,1'b0,7'd12,8'd1,48'b0,8'd2};
		// //end_tag, extraction_tag,reserved, HVoffset, length, fieldLocations;
	// end
	// #2 ruleSet_valid <= 1'b0; */
	
	// // del arp;
	// #10 begin 
		// ruleSet_valid <= 1'b1;
		// ruleSet <= {2'd2,32'h0806_0001,8'h0,	// add, type, state;
					// 8'd9,8'd9,8'd0,	//nextState, typeOffset;
					// 1'b1,1'b0,6'b0,8'd4,8'b0,8'd8,1'b0,7'd12,8'd1,48'b0,8'd2};
		// //end_tag, extraction_tag,reserved, HVoffset, length, fieldLocations;
	// end
	// #2 ruleSet_valid <= 1'b0;
	// //udp
	// #10 begin 
		// ruleSet_valid <= 1'b1;
		// ruleSet <= {2'd1,32'h1100_0000,8'h1,	// add, type, state;
					// 8'd2,8'd2,8'd16,	//nextState, typeOffset;
					// 1'b0,1'b1,6'b0,8'd4,8'b0,8'd8,1'b0,7'd0,8'd0,48'b0,8'd3};
		// //end_tag, extraction_tag,reserved, HVoffset, length, fieldLocations;
	// end
	// #2 ruleSet_valid <= 1'b0;
	// //vxlan
	// #10 begin 
		// ruleSet_valid <= 1'b1;
		// ruleSet <= {2'd1,32'h4789_0000,8'h2,	// add, type, state;
					// 8'd9,8'd9,8'd0,	//nextState, typeOffset;
					// 1'b1,1'b0,6'b0,8'd4,8'b0,8'd20,1'b0,7'd0,8'd0,48'b0,8'd4};
		// //end_tag, extraction_tag,reserved, HVoffset, length, fieldLocations;
	// end
	// #2 ruleSet_valid <= 1'b0;
	
end

reg	[138:0]	count;

initial begin
	count <= 139'b0;
	#300 begin end
	for(i=0;i<9;i=i+1) begin
		//arp
		#20 begin
			cdp2um_data = pkt[0];
			cdp2um_data_valid = 1'b1;
		end
		#2 cdp2um_data = pkt[1]+count;
		#2 cdp2um_data = pkt[2];
		#2 cdp2um_data = pkt[3];
		#2 cdp2um_data = pkt[4];
		#2 cdp2um_data = pkt[5];
		#2 cdp2um_data = pkt[6];
		#2 cdp2um_data_valid = 1'b0;
		//arp_respond
		#2 count = count + 139'd1;
		#20 begin
			cdp2um_data = pkt[8];
			cdp2um_data_valid = 1'b1;
		end
		#2 cdp2um_data = pkt[1]+count;
		#2 cdp2um_data = pkt[2];
		#2 cdp2um_data = pkt[6];
		#2 cdp2um_data_valid = 1'b0;
		
		//ping_request;
		#2 count = count + 139'd1;
		#2 begin
			cdp2um_data = pkt[0];
			cdp2um_data_valid = 1'b1;
		end
		#2 cdp2um_data = pkt[1]+count;
		#2 cdp2um_data = pkt[2];
		#2 cdp2um_data = pkt[3];
		#2 cdp2um_data = pkt[4];
		#2 cdp2um_data = pkt[5];
		#2 cdp2um_data = pkt[6];		
		#2 cdp2um_data_valid = 1'b0;
		
		
		
		
		//mac2
		#2 count = count + 139'd1;
		#20 begin
			cdp2um_data = pkt[9];
			cdp2um_data_valid = 1'b1;
		end
		#2 cdp2um_data = pkt[1]+count;
		#2 cdp2um_data = pkt[2];
		#2 cdp2um_data = pkt[3];
		#2 cdp2um_data = pkt[4];
		#2 cdp2um_data = pkt[5];
		#2 cdp2um_data = pkt[6];
		#2 cdp2um_data_valid = 1'b0;
	end
	
end

endmodule
