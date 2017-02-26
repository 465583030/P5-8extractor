//	Module name: um
//	Authority @ lijunnan
//	Last edited time: 2017/02/18
//	Function outline: programmable parser
//


`timescale 1ns/1ps

module um(
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
um2cdp_path,					//if um2cdp_path=0, packets are routed to UM, else if um2cdp_path=1, packets are routed to CDP.
cdp2um_data_valid,
cdp2um_data,
um2cdp_tx_enable,
um2cdp_data_valid,
um2cdp_data,
cdp2um_tx_enable,				//change the name by mxl and ccz according to UM2.0;
um2cdp_rule,
um2cdp_rule_wrreq,
cdp2um_rule_usedw
);



input         clk;
input         reset;
input         localbus_cs_n;
input         localbus_rd_wr;
input [31:0]  localbus_data;
input         localbus_ale;
output        wire	localbus_ack_n;
output wire	[31:0]  localbus_data_out;

output        reg	um2cdp_path;
input         cdp2um_data_valid;
input [138:0] cdp2um_data;
output        reg	um2cdp_tx_enable;
output        wire	um2cdp_data_valid;
output	wire[138:0] um2cdp_data;
input         cdp2um_tx_enable;
output        wire	um2cdp_rule_wrreq;
output	wire[29:0]  um2cdp_rule;
input [4:0]   cdp2um_rule_usedw; 


//----------------wire---------------//
wire	[7:0]	headerData_valid;
wire	[255:0]	headerData;	
wire	[7:0]	headerData_finish_valid;
wire	[63:0]	pktID;
wire	headerVector_valid;
wire	[199:0]	headerVector;
wire	parserRuleSet_valid;
wire	[169:0]	parserRuleSet;
wire	result_valid;
wire	[119:0]	result;
wire	headerIn_enable;
wire	[7:0]	bid_bitmap;

parser parser(
.clk(clk),
.reset(reset),
.headerData_valid(headerData_valid),
.headerData(headerData),
.headerData_finish_valid(headerData_finish_valid),
.pktID(pktID),
.headerVector_valid(headerVector_valid),
.headerVector(headerVector),
.ruleSet_valid(parserRuleSet_valid),
.ruleSet(parserRuleSet),
.result_valid(result_valid),
.result(result),
.bid_bitmap(bid_bitmap)
);


wire	action_valid;
wire	[31:0]	action;	// [31:24] pktID; [23:16] action_ins; [15:0] port;
wire	lookupRuleSet_valid;
wire	[63:0]	lookupRuleSet;

lookup lookup(
.clk(clk),
.reset(reset),
.headerVector_valid(headerVector_valid),
.headerVector(headerVector),
.action_valid(action_valid),
.action(action),
.ruleSet_valid(lookupRuleSet_valid),
.ruleSet(lookupRuleSet)
);

wire	pktID2pb_valid;
wire	[11:0]	pktID2pb;	//action_ins 4bit + 8bit pktID; [9:8]: '01' is discard; '02' is repeated;
wire	writeRule_enable; 
//wire	pktIn_enable;

transmit transmit(
.clk(clk),
.reset(reset), 
.action_valid(action_valid),
.action(action),
.pktIDout_valid(pktID2pb_valid),
.pktIDout(pktID2pb),
.um2cdp_rule_wrreq(um2cdp_rule_wrreq),
.um2cdp_rule(um2cdp_rule),
.cdp2um_tx_enable(cdp2um_tx_enable),
.writeRule_enable(writeRule_enable)
);

pktBuffer pktBuffer(
.clk(clk),
.reset(reset),
.pktID_in_valid(pktID2pb_valid),
.pktID_in(pktID2pb),
.cdp2um_data_valid(cdp2um_data_valid),
.cdp2um_data(cdp2um_data),



.um2cdp_data_valid(um2cdp_data_valid),
.um2cdp_data(um2cdp_data),
.headerData_valid(headerData_valid),
.headerData(headerData),
.headerData_finish_valid(headerData_finish_valid),
.pktID_out(pktID),
.bid_bitmap(bid_bitmap),
.headerIn_enable(headerIn_enable),
.cdp2um_rule_usedw(cdp2um_rule_usedw),
.writeRule_enable(writeRule_enable)
);

localbus_manage localbus_manage(
.clk(clk),
.reset(reset),
.localbus_cs_n(localbus_cs_n),
.localbus_rd_wr(localbus_rd_wr),
.localbus_data(localbus_data),
.localbus_ale(localbus_ale),
.localbus_ack_n(localbus_ack_n),
.localbus_data_out(localbus_data_out),

.parserRuleSet_valid(parserRuleSet_valid),
.parserRuleSet(parserRuleSet),
.result_valid(result_valid),
.result(result),
.lookupRuleSet_valid(lookupRuleSet_valid),
.lookupRuleSet(lookupRuleSet)
);


reg	state; 
  
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		um2cdp_path <= 1'b0;
		state <= 1'b0;
		um2cdp_tx_enable <= 1'b0;
	end
	else begin
		case(state)
			1'b0: begin
				if((cdp2um_data_valid == 1'b0) && (bid_bitmap == 8'hff)) begin
					state <= 1'b1;
					um2cdp_tx_enable <= 1'b1;
				end
				else begin
					state <= 1'b0;
					um2cdp_tx_enable <= 1'b0;
				end
			end
			1'b1: begin
				if((cdp2um_data_valid == 1'b1) || (bid_bitmap != 8'hff)) begin
					state <= 1'b0;
					um2cdp_tx_enable <= 1'b0;
				end
				else begin
					state <= 1'b1;
					um2cdp_tx_enable <= 1'b1;
				end
			end
			default: state <= 1'b0;
		endcase
	end
end




reg	[31:0]	count_time;
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		count_time <= 31'b0;
	end
	else begin
		count_time <= count_time + 32'd1;
	end
end




endmodule