//
//  head_buffer module
//
//  tcam_test
//
//  Created by LiJunnan on 16/12/22.
//  Copyright (c) 2016year LiJunnan. All rights shared including commercialization.
`timescale 1ns/1ns

//******addr_a need to be modified****** line 69

module head_buffer(
clk,
reset,
head_in,
head_in_valid,
ramID,
addr_in,
addr_in_valid,
type_out,
type_out_valid
);

input	clk;
input	reset;
input	[31:0]	head_in;
input	head_in_valid;
input	[4:0]	ramID;
input	[19:0]	addr_in;  // 8bit state +5bit ramID+7bit location_byte; 
input	addr_in_valid;
output	reg	[44:0]	type_out; //5bit ramID + 32bit type_out + 8bit state;
output	reg	type_out_valid;
//=========temp=========//
reg	[4:0]	ramIDtemp[3:0];
reg	addr_in_validTemp[3:0];
reg	[7:0]	stateTemp[3:0];


//----ram----//
reg	[9:0]	addr_a,addr_b;  //[9:5] identify pakcet; [4:0] identify header data;
reg	rden_a,wren_b;
reg	[31:0]	data_b;
wire	[31:0]	q_a;

reg	[1:0]	addr_temp[3:0];
reg	[31:0]	type_temp;
//reg	[4:0]	headerID_r,headerID_w;

//reg	[2:0]	state;
parameter	idle		= 3'd0,
			wait_1		= 3'd1,
			wait_2		= 3'd2,
			read_1		= 3'd3,
			read_2		= 3'd4;
reg	state_headIn;

			
			
//----read headerType----//
//stage 1//
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		rden_a <= 1'b0;
		addr_a <= 10'b0;
	end
	else begin
		if(addr_in_valid == 1'b1) begin
			rden_a <= 1'b1;
			addr_a <= {5'b0,addr_in[6:2]};//need to change
			
		end
		else if (addr_in_validTemp[0]==1'b1) begin
			rden_a <= 1'b1;
			addr_a <= addr_a+10'd1;
		end
		else rden_a <= 1'b0;
	end
end
//===stage 2===//
//wait [0]
//===stage 3===//
//wait [1]
//===stage 4===// [2]
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		type_temp <= 32'b0;
	end
	else begin
		type_temp <= q_a;
	end
end
//===stage 5===// [3]
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		type_out_valid <= 1'b0;
		type_out <= 37'b0;
	end
	else begin
		if(addr_in_validTemp[3] == 1'b1) begin
			type_out_valid <= 1'b1;
			case(addr_temp[3])
				2'd0:	type_out <= {ramIDtemp[3],type_temp,stateTemp[3]};
				2'd1:	type_out <= {ramIDtemp[3],type_temp[23:0],q_a[31:24],stateTemp[3]};	
				2'd2:	type_out <= {ramIDtemp[3],type_temp[15:0],q_a[31:16],stateTemp[3]};
				2'd3:	type_out <= {ramIDtemp[3],type_temp[7:0],q_a[31:8],stateTemp[3]};
			endcase
		end
		else type_out_valid <= 1'b0;
	end
end



//===convey ramIDtemp===//
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		ramIDtemp[0] <= 5'd0;ramIDtemp[1] <= 5'd0;
		ramIDtemp[2] <= 5'd0;ramIDtemp[3] <= 5'd0;
		addr_temp[0] <= 2'b0;
		addr_in_validTemp[0] <= 1'b0;
		stateTemp[0] <= 8'd0;
	end
	else begin
		ramIDtemp[0] <= addr_in[11:7];
		ramIDtemp[1] <= ramIDtemp[0];
		ramIDtemp[2] <= ramIDtemp[1];
		ramIDtemp[3] <= ramIDtemp[2];
		addr_temp[0] <= addr_in[1:0];
		addr_temp[1] <= addr_temp[0];
		addr_temp[2] <= addr_temp[1];
		addr_temp[3] <= addr_temp[2];
		addr_in_validTemp[0] <= addr_in_valid;
		addr_in_validTemp[1] <= addr_in_validTemp[0];
		addr_in_validTemp[2] <= addr_in_validTemp[1];
		addr_in_validTemp[3] <= addr_in_validTemp[2];
		//addr_in_validTemp[4] <= addr_in_validTemp[3];
		stateTemp[0] <= addr_in[19:12];
		stateTemp[1] <=	stateTemp[0];
		stateTemp[2] <=	stateTemp[1];
		stateTemp[3] <=	stateTemp[2];
		
	end
end
// head_in
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		wren_b <= 1'b0;
		addr_b <= 10'b0;
		state_headIn <= 1'b0;
	end
	else begin
		case(state_headIn)
			1'b0: begin
				if(head_in_valid==1'b1) begin
					wren_b <= 1'b1;
					addr_b <= {ramID,5'b0};
					data_b <= head_in;
					state_headIn <= 1'b1;
				end
				else wren_b <= 1'b0;
			end
			1'b1: begin
				if(head_in_valid == 1'b1) begin
					wren_b <= 1'b1;
					addr_b <= addr_b + 10'd1;
					data_b <= head_in;
					state_headIn <= 1'b1;
				end
				else begin
					wren_b <= 1'b0;
					state_headIn <= 1'b0;
				end
			end
		endcase
	end
end


ram ram_32_1024(
	.address_a(addr_a),
	.address_b(addr_b),
	.clock(clk),
	.data_a(32'b0),
	.data_b(data_b),
	.rden_a(rden_a),
	.rden_b(1'b0),
	.wren_a(1'b0),
	.wren_b(wren_b),
	.q_a(q_a),
	.q_b()
	);
defparam
	ram_32_1024.width 	= 32,
	ram_32_1024.depth	= 10,
	ram_32_1024.words	= 1024;




endmodule
