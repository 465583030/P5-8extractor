//
//  hash_template module
//
//
//  hash
//
//  Created by LiJunnan on 16/11/27.
//  Copyright (c) 2016year LiJunnan. All rights reserved.
//
`timescale 1ns/1ps

module tss(
clk,
reset,
type_valid,
type,
rule_set_valid,
rule_set,
state_typeLocation_valid,
state_typeLocation,
headVectorLocation_valid,
headVectorLocation
);
input	clk;
input	reset;
input	type_valid;
input	[44:0]	type;
input	rule_set_valid;
input	[162:0]	rule_set;	//2+9=11bit_ruleID	+80 field_locations+ 40bit_rule(type+state) +32 action(16:state_typeLocation + 8:HV + 8:indext)+
output	reg	state_typeLocation_valid;
output	reg	[20:0]	state_typeLocation; //5 bit ramID + 8bit_state	+ 	8bit_typeLocation
output	reg	headVectorLocation_valid;
output	reg	[92:0]	headVectorLocation; // 5 +8bit + 80 field_locations




reg		wren_b_8bit,wren_b_16bit,wren_b_32bit;
reg	[127:0] data_b_8bit;
reg	[135:0]	data_b_16bit;
reg	[151:0]	data_b_32bit;
reg	[8:0]	addr_a_8bit,addr_b_8bit,addr_a_16bit,addr_b_16bit,addr_a_32bit,addr_b_32bit;
wire	[127:0] 	q_a_8bit;
wire	[135:0]	q_a_16bit;
wire	[151:0]	q_a_32bit;
wire	rden_a;


//--temp..
wire [8:0]	hash_1,hash_2,hash_3;
reg	typeValidTemp[4:0];
reg	[44:0]	typeTemp[4:0];
reg	state;
reg	[1:0]	tag;



//stage_1.. 
hash_function key_match_hash(
.clk(clk),
.reset(reset),
.key_valid(type_valid),
.key(type[39:0]),
.hash_value_valid(rden_a),
.hash_1(hash_1),
.hash_2(hash_2),
.hash_3(hash_3)
);
//stage 2.. wait1 [0]
//stage 3.. wait2 [1]
//stage 4.. [2] & [3]
always @ (posedge clk or negedge reset)
begin
	if(!reset) begin
		state_typeLocation_valid <= 1'b0;
		headVectorLocation_valid <= 1'b0;
		state_typeLocation <= 21'b0;
		headVectorLocation <= 93'b0;
		state <= 1'b0;
		tag <= 2'b0;
	end
	else begin
		case(state)
		1'b0: begin
			state_typeLocation_valid <= 1'b0;
			headVectorLocation_valid <= 1'b0;
			
			
			if(typeValidTemp[2]==1'b1) state <= 1'b1;
			else state <= 1'b0;	
			if(q_a_32bit[151:112] == typeTemp[2][39:0]) begin
					tag = 2'd3;
					state_typeLocation <= {typeTemp[2][44:40],q_a_32bit[31:16]};
					headVectorLocation <= {typeTemp[2][44:40],q_a_32bit[15:8],q_a_32bit[111:32]};
			end
			else if(q_a_16bit[135:112] == {typeTemp[2][39:24],typeTemp[2][7:0]}) begin
					tag = 2'd2;
					state_typeLocation <= {typeTemp[2][44:40],q_a_16bit[31:16]};
					headVectorLocation <= {typeTemp[2][44:40],q_a_16bit[15:8],q_a_16bit[111:32]};
			end
			else if(q_a_8bit[127:112] == {typeTemp[2][39:32],typeTemp[2][7:0]}) begin
					tag = 2'd1;
					state_typeLocation <= {typeTemp[2][44:40],q_a_8bit[31:16]};
					headVectorLocation <= {typeTemp[2][44:40],q_a_8bit[15:8],q_a_8bit[111:32]};
			end
			else begin
					tag = 2'd0;
					state_typeLocation <= 21'b0;
					headVectorLocation <= 93'b0;
			end
		end
		1'b1: begin
				state <= 1'b0;
				state_typeLocation_valid <= 1'b1;
				headVectorLocation_valid <= 1'b1;
				if(q_a_32bit[151:112] == typeTemp[3][39:0]) begin
					tag = 2'd3;
					state_typeLocation <= {typeTemp[3][44:40],q_a_32bit[31:16]};
					headVectorLocation <= {typeTemp[3][44:40],q_a_32bit[15:8],q_a_32bit[111:32]};
				end
				else if(q_a_16bit[135:112]  == {typeTemp[3][39:24],typeTemp[3][7:0]}) begin
					if(tag != 2'd3) begin
						tag = 2'd2;
						state_typeLocation <= {typeTemp[3][44:40],q_a_16bit[31:16]};
						headVectorLocation <= {typeTemp[3][44:40],q_a_16bit[15:8],q_a_16bit[111:32]};
					end
				end
				else if(q_a_8bit[127:112] == {typeTemp[3][39:32],typeTemp[3][7:0]}) begin
					if(tag == 2'd0) begin
						tag <= 2'd1;
						state_typeLocation <= {typeTemp[3][44:40],q_a_8bit[31:16]};
						headVectorLocation <= {typeTemp[3][44:40],q_a_8bit[15:8],q_a_8bit[111:32]};
					end
				end
				else begin
					tag = 2'd0;
				end
		end
		endcase
	end
end


	
//convert valid and key_set_value 
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		typeValidTemp[0] <= 1'b0;
		typeValidTemp[1] <= 1'b0;
		typeValidTemp[2] <= 1'b0;
		typeValidTemp[3] <= 1'b0;
		
	end
	else begin
		typeValidTemp[0] <= type_valid;
		typeValidTemp[1] <= typeValidTemp[0];
		typeValidTemp[2] <= typeValidTemp[1];
		typeValidTemp[3] <= typeValidTemp[2];
		typeValidTemp[4] <= typeValidTemp[3];
		
		typeTemp[0] <= type;
		typeTemp[1] <= typeTemp[0];
		typeTemp[2] <= typeTemp[1];
		typeTemp[3] <= typeTemp[2];
		typeTemp[4] <= typeTemp[3];
	end
end
//rule_set
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		wren_b_8bit <= 1'b0;
		wren_b_16bit <= 1'b0;
		wren_b_32bit <= 1'b0;
		addr_b_8bit <= 9'b0;
		addr_b_16bit<= 9'b0;
		addr_b_32bit <= 9'b0;
		data_b_8bit <= 48'b0;
		data_b_16bit <= 56'b0;
		data_b_32bit <= 72'b0;
	end
	else begin
		if(rule_set_valid==1'b1) begin
			case(rule_set[162:161])
				2'd0: begin
					wren_b_8bit <= 1'b1;
					addr_b_8bit <= rule_set[160:152];
					data_b_8bit <= {rule_set[151:144],rule_set[119:0]};
				end
				2'd1:begin
					wren_b_16bit <= 1'b1;
					addr_b_16bit <= rule_set[160:152];
					data_b_16bit <= {rule_set[151:136],rule_set[119:0]};
				end				
				2'd2:begin
					wren_b_32bit <= 1'b1;
					addr_b_32bit <= rule_set[160:152];
					data_b_32bit <= {rule_set[151:0]};
				end
				2'd3: begin end
			endcase
		end
		else begin
			wren_b_8bit <= 1'b0;
			wren_b_16bit <= 1'b0;
			wren_b_32bit <= 1'b0;
		end
	end
end


ram tss_8bit(
.address_a(hash_1),
.address_b(addr_b_8bit),
.clock(clk),
.data_a(128'd0),
.data_b(data_b_8bit),
.rden_a(rden_a),
.rden_b(1'b0),
.wren_a(1'b0),
.wren_b(wren_b_8bit),
.q_a(q_a_8bit),
.q_b()
);
defparam
	tss_8bit.width	= 128,
	tss_8bit.depth	= 9,
	tss_8bit.words	= 512;
	
ram tss_16bit(
.address_a(hash_2),
.address_b(addr_b_16bit),
.clock(clk),
.data_a(136'd0),
.data_b(data_b_16bit),
.rden_a(rden_a),
.rden_b(1'b0),
.wren_a(1'b0),
.wren_b(wren_b_16bit),
.q_a(q_a_16bit),
.q_b()
);
defparam
	tss_16bit.width	= 136,
	tss_16bit.depth	= 9,
	tss_16bit.words	= 512;

ram tss_32bit(
.address_a(hash_3),
.address_b(addr_b_32bit),
.clock(clk),
.data_a(152'd0),
.data_b(data_b_32bit),
.rden_a(rden_a),
.rden_b(1'b0),
.wren_a(1'b0),
.wren_b(wren_b_32bit),
.q_a(q_a_32bit),
.q_b()
);
defparam
	tss_32bit.width	= 152,
	tss_32bit.depth	= 9,
	tss_32bit.words	= 512;
endmodule




