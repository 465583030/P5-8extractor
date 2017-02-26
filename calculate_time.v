`timescale 1ns/1ps
module calculate_time(
clk,
reset,
start_valid,
ramID_start,
count,
over_valid,
ramID_over,
pktDelay,
pktCount
);
parameter id=1;
parameter widthExtraction = 2;
parameter limitTime = 50000;

input	clk;
input	reset;
input	start_valid;
input	[4:0]	ramID_start;
output	reg	[31:0]	count;
input	over_valid;
input	[4:0]	ramID_over;
output	reg	[31:0] pktDelay;
output	reg	[31:0] pktCount;

//temp
reg	[5:0]	addr_a,addr_b;
reg	[31:0]	data_b;
reg	rden_a,wren_b;
wire	[31:0]	q_a;


reg	[31:0]	timeOver;

reg	[3:0]	countID;

integer i;

reg		state;
reg	[1:0]	state_cal;
parameter	idle	= 2'd0,
			wait1	= 2'd1,
			calTime	= 2'd2;

//time_in
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		countID <= 4'd0;
		wren_b <= 1'b0;
		addr_b <= 6'b0;
		data_b <= 32'b0;
	end
	else begin
		if(start_valid==1'b1) begin
			countID <= countID +4'd1;
			if(countID[widthExtraction-1:0]== id) begin
				wren_b <= 1'b1;
				//addr_b <= {1'b0,ramID_start};
				addr_b <= addr_b + 6'd1;
				data_b <= count;
			end
			else wren_b <= 1'b0;
		end 
		else begin 
			countID <= countID;
			wren_b <= 1'b0;
		end
	end
end			
			

//=======time_cal..========//
//rden valid
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		rden_a <= 1'b0;
		addr_a <= 6'b0;
		state <= 1'b0;
		timeOver <= 32'b0;
	end
	else begin
		case(state) 
			1'b0: begin
				if(over_valid==1'b1) begin
					rden_a <= 1'b1;
					//addr_a <= {1'b0,ramID_over};
					addr_a <= addr_a + 6'd1;
					state <= 1'b1;
					timeOver <= count;
				end
				else state <= 1'b0;
			end
			1'b1: begin
				rden_a<= 1'b0;
				if(over_valid==1'b0) begin
					state <= 1'b0;
				end
				else state <= 1'b1;
			end
		endcase
	end
end
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		pktDelay <= 32'b0;
		state_cal <= idle;
		pktCount <= 32'b0;
	end
	else begin
		case(state_cal)
			idle: begin
				if(rden_a == 1'b1) state_cal <= wait1;
				else state_cal <= idle;
				if(count==limitTime) begin
					pktDelay <= 32'b0;
					pktCount <= 32'b0;
				end
			end
			wait1: begin
				state_cal <= calTime;
				if(count==limitTime) begin
					pktDelay <= 32'b0;
					pktCount <= 32'b0;
				end
			end
			calTime: begin
				if((q_a > timeOver)||(count==limitTime)) begin
					pktDelay <= 32'b0;
					pktCount <= 32'b0;
				end
				else begin
					pktDelay <= pktDelay + timeOver-q_a;
					pktCount <= pktCount + 32'b1;
				end
				state_cal <= idle;
			end
			default: begin end
		endcase
	end
end


//timeCount
always @ (posedge clk or negedge reset) begin
	if(!reset) count <= 32'b0;
	else begin
		if(count == limitTime) count <= 32'b0;
		else count <= count+32'd1;
	end
end




ram ram_count(
.address_a(addr_a),
.address_b(addr_b),
.clock(clk),
.data_a(32'd0),
.data_b(data_b),
.rden_a(rden_a),
.rden_b(1'b0),
.wren_a(1'b0),
.wren_b(wren_b),
.q_a(q_a),
.q_b()
);
defparam
	ram_count.width	= 32,
	ram_count.depth	= 6,
	ram_count.words	= 64;



endmodule
