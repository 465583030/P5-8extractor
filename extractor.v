//	Module name: parser->extractor
//	Authority @ lijunnan
//	Last edited time: 2017/02/14
//	Function outline: programmable parser
//

//one ram;
module extractor(
clk,
reset,
headerData_valid,
headerData,
headerData_finish_valid,
pktID,
action_valid,
action,
field_valid,
field,
hvOffset,
field_finish_valid,
field_finish_bid,
bid_enable,	// enable
stateType_valid,
stateType
);
parameter 	extractionID 	= 1,
			widthExtraction = 3,
			widthHeaderData	= 32;


integer	i;

input	clk;
input	reset;
input	headerData_valid;
input	[widthHeaderData-1:0]	headerData;
input	headerData_finish_valid;
input	[7:0]	pktID;
input	action_valid;
input	[124:0]	action;//[124:120] bid; [119:96] state + typeOffset+ 8bit mask(num); [95:0]: filedLocation;
output	reg	field_valid;
output	reg	[widthHeaderData-1:0]	field;
output	reg	[11:0]	hvOffset;	//5bit:ramID+ 7bit offset;
output	reg	field_finish_valid;
output	reg	[23:0]	field_finish_bid;	// //8bit action; 3bid reserved; 5'd bid;+ 8'd pktID 
output	reg	bid_enable;
output	reg	stateType_valid;
output	reg	[44:0]	stateType;


//=========temp=========//
//bid_enable
reg	[2:0]	bid_count;
reg	bid_count_add;
//headerIn
reg	state_headIn;
reg	[1:0]	ramID;
reg	[5:0]	addr_temp;
//locationIn
reg	[7:0] pktID_temp;
reg	[4:0] bid_temp;
reg	[7:0] state_temp;
reg	[7:0] typeOffset_temp;
reg	[7:0] typeMask_temp;
reg	end_temp;
reg	extraction_temp;
reg	flowMod_temp;
reg [4:0] reserved;
reg	[7:0] hvOffset_temp,hvOffset_temp_reserved;
reg	[15:0]	length_temp;	//[15] valid '1'is offset, '0' is fixed value; [14:8] offset, [7:0] value;
reg	[15:0]	location_temp[3:0];
reg	[7:0]	headerOffset_temp;
reg	[7:0]	headerLocation;
reg	[7:0]	headerLocation_count,headerLocation_limit;
reg	[117:0]	action_temp;
reg	[3:0]	state_locationIn;
parameter	idle_locationIn		= 4'd0,
			read_fifo_action	= 4'd1,
			read_fifo_newHeader	= 4'd2,
			write_typeOffset	= 4'd3,
			write_headerOffset	= 4'd4,
			write_fieldLocation_0=4'd5,
			write_fieldLocation_1=4'd6,
			write_fieldLocation_2=4'd7,
			write_fieldLocation_3=4'd8,
			write_end			= 4'd9;

//field extraction
			
//ram_header
reg	[7:0]	addr_a,addr_b;
reg	[widthHeaderData-1:0]	data_b;
reg	wren_b,rden_a;
wire	[widthHeaderData-1:0]	q_a;

//fifo_action
reg		[124:0]	data_action;
reg		wrreq_action,rdreq_action;
wire	empty_action;
wire	[124:0]	q_action;
//fifo_newHeader
reg		[132:0]	data_newHeader;
reg		wrreq_newHeader,rdreq_newHeader;
wire	empty_newHeader;
wire	[132:0]	q_newHeader;
//fifo_location
reg		[39:0]	data_location;
reg		wrreq_location,rdreq_location;
wire	empty_location;
wire	[39:0]	q_location;
//fifo_offset
reg		[15:0]	offset;
reg		offset_valid;	
reg		rdreq_offset;
wire	empty_offset;
wire	[15:0]	q_offset;
//fifo_bid;
reg		[4:0]	data_bid;
reg		rdreq_bid,wrreq_bid;
wire	empty_bid;
wire	[4:0]	q_bid;	

reg		stage_enable[4:0];
reg		[31:0]	q_location_temp[4:0];
reg		[7:0]	q_pktID_temp[4:0];
reg		offset_valid_temp[4:0];
reg		[7:0]	offset_temp[4:0];
reg		[31:0]	field_temp,fieldValue,maskBit_temp;
reg		state_stage_0,state_stage_1,state_stage_2,state_stage_3;
parameter	clock_0	= 1'd0,
			clock_1	= 1'd1;

		
			

//field extraction	
// two clock for one stage.
//pipeline_stage_0; function: read fifo_location; read fifo every two clocks;
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		state_stage_0 <= clock_0;
		rdreq_location <= 1'b0;
	end
	else begin
	case(state_stage_0)
		clock_0: begin
			if(empty_location==1'b0) begin
				rdreq_location <= 1'b1;
				state_stage_0 <= clock_1;
			end
			else state_stage_0 <= clock_0;
		end
		clock_1: begin	
			rdreq_location <= 1'b0;
			state_stage_0 <= clock_0;
		end
	endcase
	end
end

//pipeline_stage_1; function: read header_ram;
//clock_1-2;
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		addr_a <= 8'b0;
		rden_a <= 1'b0;
		stage_enable[0] <= 1'b0;
		state_stage_1 <= clock_0;
		field_finish_valid <= 1'b0;
		field_finish_bid <= 24'b0;
		offset_valid_temp[0] <= 1'b0;
		offset_temp[0] <= 8'b0;
	end
	else begin
		case(state_stage_1)
			clock_0: begin
				if(rdreq_location==1'b1) begin
					state_stage_1 <= clock_1;
					if(q_location[31]==1'b1) begin
						rden_a <= 1'b0;
						field_finish_valid <= 1'b1;
						field_finish_bid <= {q_location[23:16],3'b0,q_location[28:24],q_location[39:32]};	//bid;
						stage_enable[0] <= 1'b0;
					end
					else if((q_location[29]==1'b1) && (q_location[15]==1'b0)) begin
						rden_a <= 1'b0;
						offset_valid_temp[0] <= 1'b1;
						offset_temp[0] <= q_location[23:16] + q_location[7:0];
						stage_enable[0] <= 1'b0;
					end
					else begin
						rden_a <= 1'b1;
						addr_a <= {q_location[25:24],{1'b0,q_location[14:10]}};
						stage_enable[0] <= 1'b1;
					end
				end
				else begin 
					state_stage_1 <= clock_0;
					rden_a <= 1'b0;
					stage_enable[0] <= 1'b0;
				end
			end
			clock_1: begin	// stage_enable[0] valid;
				if(rden_a==1'b1) addr_a <= addr_a + 8'd1;
				field_finish_valid <= 1'b0;
				offset_valid_temp[0] <= 1'b0;
				state_stage_1 <= clock_0;
			end
		endcase
	end
end

//clock_2-3; stage_enable[0-1] valid;

//pipeline_stage_2; function: wait time;
//clock_4-5; function: get ram data;
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		state_stage_2 <= clock_0;
		fieldValue <= 32'b0;
		field_temp <= 32'b0;
		maskBit_temp <= 32'b0;
	end
	else begin
		case(state_stage_2)
			clock_0: begin
				if(stage_enable[2]==1'b1) begin
					field_temp <= q_a;
					state_stage_2 <= clock_1;
				end
				else state_stage_2 <= clock_0;
			end
			clock_1: begin	//q_location_temp[3]
				if(stage_enable[3]==1'b1) begin
					case(q_location_temp[3][9:8])
					2'd0:	fieldValue <= field_temp;
					2'd1:	fieldValue <= {field_temp[23:0],q_a[31:24]};
					2'd2:	fieldValue <= {field_temp[15:0],q_a[31:16]};
					3'd3:	fieldValue <= {field_temp[7:0],q_a[31:8]};
					endcase
					case(q_location_temp[3][23:16])
						8'd0:	maskBit_temp <= 32'hffff_ffff;
						8'd8:	maskBit_temp <= 32'hffff_ff00;
						8'd16:	maskBit_temp <= 32'hffff_0000;
						8'd24:	maskBit_temp <= 32'hff00_0000;
						default: maskBit_temp <= 32'hffff_ffff;
					endcase					
				end
				state_stage_2 <= clock_0;
			end
		endcase
	end
end
//pipeline_stage_3; function: wait time;
//clock_6-7; function: typeState/length/field out;
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		state_stage_3 <= clock_0;
		offset_valid <= 1'b0;
		offset <= 16'b0;
		stateType_valid <= 1'b0;
		stateType <= 45'b0;
		field_valid <= 1'b0;
		field <= 32'b0;
		hvOffset <= 12'b0;
	end
	else begin 
		case(state_stage_3)
			clock_0: begin
				if(stage_enable[4]==1'b1) begin
					case(q_location_temp[4][31:29])
						3'b000:	begin
							hvOffset <= {q_location_temp[4][28:24],q_location_temp[4][22:16]};
							field_valid <= 1'b1;
							field <= fieldValue;
						end
						3'b010: begin
							stateType_valid <= 1'b1;						
							stateType <= {q_location_temp[4][28:24],fieldValue&maskBit_temp,q_location_temp[4][7:0]};
						end
						3'b001: begin
							offset_valid <= 1'b1;
							if(q_location_temp[4][0]==1'b0) offset <= {q_pktID_temp[4],q_location_temp[4][23:16] + fieldValue[31:28]*4};
							else offset <= {q_pktID_temp[4],q_location_temp[4][23:16] + fieldValue[27:24]*4};
						end
						default: begin
						end
					endcase
					state_stage_3 <= clock_1;
				end
				else if(offset_valid_temp[4]==1'b1) begin
					offset_valid <= 1'b1;
					offset <= {q_pktID_temp[4],offset_temp[4]};
					state_stage_3 <= clock_1;
				end
				else state_stage_3 <= clock_0;
			end
			clock_1: begin
				offset_valid <= 1'b0;
				stateType_valid <= 1'b0;
				field_valid <= 1'b0;
				state_stage_3 <= clock_0;
			end
		endcase
	end
end

//stage_enable manage
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		stage_enable[1] <= 1'b0;stage_enable[2] <= 1'b0;
		stage_enable[3] <= 1'b0;stage_enable[4] <= 1'b0;
		offset_valid_temp[1] <= 1'b0;offset_valid_temp[2] <= 1'b0;
	end
	else begin
		stage_enable[1] <=	stage_enable[0];
		stage_enable[2] <=	stage_enable[1];
		stage_enable[3] <=	stage_enable[2];
		stage_enable[4] <=	stage_enable[3];
		q_location_temp[0] <= 	q_location[31:0];
		q_location_temp[1] <=	q_location_temp[0];
		q_location_temp[2] <=	q_location_temp[1];
		q_location_temp[3] <=	q_location_temp[2];
		q_location_temp[4] <=	q_location_temp[3];
		q_pktID_temp[0] <= q_location[39:32];
		q_pktID_temp[1] <= q_pktID_temp[0];
		q_pktID_temp[2] <= q_pktID_temp[1];
		q_pktID_temp[3] <= q_pktID_temp[2];
		q_pktID_temp[4] <= q_pktID_temp[3];
		
		offset_valid_temp[1] <= offset_valid_temp[0];
		offset_valid_temp[2] <= offset_valid_temp[1];
		offset_valid_temp[3] <= offset_valid_temp[2];
		offset_valid_temp[4] <= offset_valid_temp[3];		
		offset_temp[1] <= offset_temp[0];
		offset_temp[2] <= offset_temp[1];
		offset_temp[3] <= offset_temp[2];
		offset_temp[4] <= offset_temp[3];
	end
end




//Location in
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		wrreq_location <= 1'b0;
		data_location <= 40'b0;
		state_locationIn <= idle_locationIn;
		rdreq_action <= 1'b0;
		rdreq_newHeader <= 1'b0;
		rdreq_offset <= 1'b0;
		pktID_temp <= 8'd0;
		typeMask_temp <= 8'd0;
	end
	else begin
		case(state_locationIn)
			idle_locationIn: begin
				wrreq_location <= 1'b0;
				if(empty_action == 1'b0) begin
					state_locationIn <= read_fifo_action;
					rdreq_action <= 1'b1;
					rdreq_offset <= 1'b1;
				end
				else if(empty_newHeader == 1'b0) begin
					state_locationIn <= read_fifo_newHeader;
					rdreq_newHeader <= 1'b1;
				end
				else state_locationIn <= 1'b0;
			end
			read_fifo_action: begin
				rdreq_action <= 1'b0;
				rdreq_offset <= 1'b0;
				{pktID_temp,headerOffset_temp} <= q_offset;
				{bid_temp,state_temp,typeOffset_temp,typeMask_temp,end_temp,extraction_temp,flowMod_temp,
				reserved,hvOffset_temp,length_temp,location_temp[0],
				location_temp[1],location_temp[2],location_temp[3]} <= q_action;
				case(q_action[95:94])
				2'b00: state_locationIn <= write_typeOffset;
				2'b01: state_locationIn <= write_typeOffset;
				2'b10: state_locationIn <= write_end;
				2'b11: state_locationIn <= write_fieldLocation_0;
				endcase
				headerLocation <= q_action[63:56] + q_offset[7:0];	// first fieldLocation;
				headerLocation_limit <= q_action[55:48];
				headerLocation_count <= 8'd0;
			end
			read_fifo_newHeader: begin
				rdreq_newHeader <= 1'b0;
				headerOffset_temp <= 8'b0;
				{pktID_temp,bid_temp,state_temp,typeOffset_temp,typeMask_temp,end_temp,extraction_temp,flowMod_temp,
				reserved,hvOffset_temp,length_temp,location_temp[0],
				location_temp[1],location_temp[2],location_temp[3]} <= q_newHeader;
				case(q_newHeader[95:94])
				2'b00: state_locationIn <= write_typeOffset;
				2'b01: state_locationIn <= write_typeOffset;
				2'b10: state_locationIn <= write_end;
				2'b11: state_locationIn <= write_fieldLocation_0;
				endcase
				{headerLocation,headerLocation_limit}<= q_newHeader[63:48];
				headerLocation_count <= 8'd0;
			end
			write_typeOffset: begin
				wrreq_location <= 1'b1;
				data_location <= {pktID_temp,1'b0,1'b1,1'b0,bid_temp,typeMask_temp,typeOffset_temp+headerOffset_temp,state_temp};
				state_locationIn <= write_headerOffset;
			end
			write_headerOffset: begin
				wrreq_location <= 1'b1;
				data_location <= {pktID_temp,1'b0,1'b0,1'b1,bid_temp,headerOffset_temp,length_temp};
				if(extraction_temp==1'b1) state_locationIn <= write_fieldLocation_0;
				else state_locationIn <= idle_locationIn;
			end
			write_fieldLocation_0: begin
				wrreq_location <= 1'b1;
				data_location <= {pktID_temp,1'b0,1'b0,1'b0,bid_temp,hvOffset_temp,headerLocation,8'b0};
				hvOffset_temp <= hvOffset_temp + 8'd1;
				if(headerLocation_count < headerLocation_limit) begin
					headerLocation_count <= headerLocation_count + 8'd1;
					headerLocation <= headerLocation + 8'd4;
					state_locationIn <= write_fieldLocation_0;
				end
				else begin
					case({end_temp,location_temp[1][15]})
						2'b00: state_locationIn <= idle_locationIn;
						2'b10: state_locationIn <= write_end;
						default: begin
							headerLocation <= location_temp[1][15:8] + headerOffset_temp;
							headerLocation_limit <= location_temp[1][7:0];
							headerLocation_count <= 8'd0;
							state_locationIn <= write_fieldLocation_1;
						end
					endcase
				end				
			end
			write_fieldLocation_1: begin
				wrreq_location <= 1'b1;
				data_location <= {pktID_temp,1'b0,1'b0,1'b0,bid_temp,hvOffset_temp,headerLocation,8'b0};
				hvOffset_temp <= hvOffset_temp + 8'd1;
				if(headerLocation_count < headerLocation_limit) begin
					headerLocation_count <= headerLocation_count + 8'd1;
					headerLocation <= headerLocation + 8'd4;
					state_locationIn <= write_fieldLocation_1;
				end
				else begin
					case({end_temp,location_temp[2][15]})
						2'b00: state_locationIn <= idle_locationIn;
						2'b10: state_locationIn <= write_end;
						default: begin
							headerLocation <= location_temp[2][15:8] + headerOffset_temp;
							headerLocation_limit <= location_temp[2][7:0];
							headerLocation_count <= 8'd0;
							state_locationIn <= write_fieldLocation_2;
						end
					endcase
				end				
			end
			write_fieldLocation_2: begin
				wrreq_location <= 1'b1;
				data_location <= {pktID_temp,1'b0,1'b0,1'b0,bid_temp,hvOffset_temp,headerLocation,8'b0};
				hvOffset_temp <= hvOffset_temp + 8'd1;
				if(headerLocation_count < headerLocation_limit) begin
					headerLocation_count <= headerLocation_count + 8'd1;
					headerLocation <= headerLocation + 8'd4;
					state_locationIn <= write_fieldLocation_2;
				end
				else begin
					case({end_temp,location_temp[3][15]})
						2'b00: state_locationIn <= idle_locationIn;
						2'b10: state_locationIn <= write_end;
						default: begin
							headerLocation <= location_temp[3][15:8] + headerOffset_temp;
							headerLocation_limit <= location_temp[3][7:0];
							headerLocation_count <= 8'd0;
							state_locationIn <= write_fieldLocation_3;
						end
					endcase
				end				
			end
			write_fieldLocation_3: begin
				wrreq_location <= 1'b1;
				data_location <= {pktID_temp,1'b0,1'b0,1'b0,bid_temp,hvOffset_temp,headerLocation,8'b0};
				hvOffset_temp <= hvOffset_temp + 8'd1;
				if(headerLocation_count < headerLocation_limit) begin
					headerLocation_count <= headerLocation_count + 8'd1;
					headerLocation <= headerLocation + 8'd4;
					state_locationIn <= write_fieldLocation_3;
				end
				else begin
					if(end_temp==1'b1) state_locationIn <= write_end;
					else state_locationIn <= idle_locationIn;
				end				
			end
			write_end: begin	// offset_fifo;
				wrreq_location <= 1'b1;
				if(flowMod_temp == 1'b1) data_location <= {pktID_temp,1'b1,2'b0,bid_temp,1'b1,23'b0};
				else data_location <= {pktID_temp,1'b1,2'b0,bid_temp,24'b0};
				state_locationIn <= idle_locationIn;
			end
			default: state_locationIn <= idle_locationIn;
		endcase
	end
end


// head_in
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		wren_b <= 1'b0;
		addr_b <= 8'd0;
		data_b <= 32'b0;
		state_headIn <= 1'b0;
		bid_count_add <= 1'b0;
		wrreq_newHeader <= 1'b0;
		data_newHeader <= 133'b0;
	end
	else begin
		case(state_headIn)
			1'b0: begin
				if(headerData_valid==1'b1) begin
					wren_b <= 1'b1;
					addr_b <= {ramID,6'b0};
					data_b <= headerData;
					state_headIn <= 1'b1;
					bid_count_add <= 1'b1;
				end
				else wren_b <= 1'b0;
				wrreq_newHeader <= 1'b0;
			end
			1'b1: begin
				if(headerData_finish_valid == 1'b1) begin 
					state_headIn <= 1'b0;
					data_newHeader <= {pktID,extractionID[2:0],ramID,8'h0,8'd12,8'd16,2'b01,6'b0,8'b0,8'b0,8'd14,1'b1,7'b0,8'd3,48'b0};
					wrreq_newHeader <= 1'b1;
				end
				else state_headIn <= 1'b1;		
				wren_b <= 1'b1;
				addr_b <= addr_b + 8'd1;
				data_b <= headerData;
				bid_count_add <= 1'b0;
			end
		endcase
	end
end


reg	[1:0]	state_bid;
parameter	idle_bid	= 2'd0,
			write_fifo_bid	= 2'd1,
			ready_bid	= 2'd2;

// ramID manage
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		bid_enable <= 1'b0;
		bid_count <= 3'd0;
		state_bid <= idle_bid;
		data_bid <= 5'b0;
		wrreq_bid <= 1'b0;
	end
	else begin
		case(state_bid)
			idle_bid: begin
				data_bid <= {extractionID[2:0],2'b0};
				wrreq_bid <= 1'b1;
				state_bid <= write_fifo_bid;
			end
			write_fifo_bid: begin
				if(data_bid[1:0]==2'd2) state_bid <= ready_bid;
				else state_bid <= write_fifo_bid;
				data_bid <= data_bid + 5'd1;
			end
			ready_bid: begin
				if(field_finish_valid==1'b1) begin
					wrreq_bid <= 1'b1;
					data_bid <= field_finish_bid[12:8];
				end
				else wrreq_bid <= 1'b0;
				state_bid <= ready_bid;
			end
			default: state_bid <= idle_bid;
		endcase
		
		
		if(bid_count > 3'd0) bid_enable <= 1'b1;
		else bid_enable <= 1'b0;
		case({bid_count_add,wrreq_bid})
			2'b00: bid_count <= bid_count;
			2'b01: bid_count <= bid_count + 3'd1;
			2'b10: bid_count <= bid_count - 3'd1;
			2'b11: bid_count <= bid_count;
			default: bid_count <= bid_count;
		endcase
	end
end
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		rdreq_bid <= 1'b0;
		ramID <= 2'b0;
	end
	else begin
		ramID <= q_bid[1:0];
		if(headerData_finish_valid==1'b1) rdreq_bid <= 1'b1;
		else rdreq_bid <= 1'b0;
	end
end
//action in
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		wrreq_action <= 1'b0;
		data_action <= 125'b0;
	end
	else begin
		if((action_valid == 1'b1) && action[124:122]==extractionID[2:0]) begin
			wrreq_action <= 1'b1;
			data_action <= action;
		end
		else wrreq_action <= 1'b0;
	end
end


ram ram_32_256(
	.address_a(addr_a),
	.address_b(addr_b),
	.clock(clk),
	.data_a({widthHeaderData{1'b0}}),
	.data_b(data_b),
	.rden_a(rden_a),
	.rden_b(1'b0),
	.wren_a(1'b0),
	.wren_b(wren_b),
	.q_a(q_a),
	.q_b()
	);
defparam
	ram_32_256.width 	= widthHeaderData,
	ram_32_256.depth	= 8,
	ram_32_256.words	= 256;



	
	
fifo fifo_action(	// stateTypeLocation
.aclr(!reset),
.clock(clk),
.data(data_action),
.rdreq(rdreq_action),
.wrreq(wrreq_action),
.empty(empty_action),
.full(),
.q(q_action),
.usedw()
);
defparam
    fifo_action.width = 125,
    fifo_action.depth = 3,
    fifo_action.words = 8;	

fifo fifo_newHeader(
.aclr(!reset),
.clock(clk),
.data(data_newHeader),
.rdreq(rdreq_newHeader),
.wrreq(wrreq_newHeader),
.empty(empty_newHeader),
.full(),
.q(q_newHeader),
.usedw()	
);	
defparam
    fifo_newHeader.width = 133,	//pktID[7:0] + 125;
    fifo_newHeader.depth = 3,
    fifo_newHeader.words = 8;

fifo fifo_location(	//[39:32] pktID;
					//[31] end_tag; [30] type_tag;	[29] length_tag;	[28:24] bid;
					//[23:16] hvOffset;  [15:8] location; [7:0] mask/state;
.aclr(!reset),
.clock(clk),
.data(data_location),
.rdreq(rdreq_location),
.wrreq(wrreq_location),
.empty(empty_location),
.full(),
.q(q_location),
.usedw()
);
defparam
    fifo_location.width = 40,	//pktID + 32;
    fifo_location.depth = 3,
    fifo_location.words = 8;	
	
fifo fifo_offset(
.aclr(!reset),
.clock(clk),
.data(offset),
.rdreq(rdreq_offset),
.wrreq(offset_valid),
.empty(empty_offset),
.full(),
.q(q_offset),
.usedw()
);	
defparam
    fifo_offset.width = 16,	// pktID[7:0]+ 8bit;
    fifo_offset.depth = 4,
    fifo_offset.words = 16;


	
fifo fifo_bid(
.aclr(!reset),
.clock(clk),
.data(data_bid),
.rdreq(headerData_finish_valid),
.wrreq(wrreq_bid),
.empty(empty_bid),
.full(),
.q(q_bid),
.usedw()
);	
defparam
    fifo_bid.width = 5,
    fifo_bid.depth = 4,
    fifo_bid.words = 16;
	
	

endmodule
