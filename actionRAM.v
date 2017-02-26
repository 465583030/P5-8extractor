//	Module name: parser->actionRAM
//	Authority @ lijunnan
//	Last edited time: 2017/02/15
//	Function outline: programmable parser
//
//	:)
// 	do not need support delete
module actionRAM(
clk,
reset,
index_valid,
index,
action_valid,
action,	
ruleSet_valid,
ruleSet,
result_valid,
result
);
parameter	depthRAM = 6;

input	clk;
input	reset;
input	index_valid;
input	[depthRAM+4:0]	index;	//bid + index;
output	reg	action_valid;
output	reg	[124:0]	action;//[124:120] bid; [119:96] state + typeOffset + 8bit mask(num); [95:0]: filedLocation;
input	ruleSet_valid;
input	[129:0]	ruleSet;	// 	[129:128]: operationCode 2'd0:read; 2'd1:add; 2'd2:del;
							//	[127:120]: nextState;	[119:112]:typeLocation; [111:104] typeMask;
							//	[103:8]fieldLocations;	
							//	[7:0]ruleNum
output	reg	result_valid;
output	reg	[119:0]	result;

//ram
reg		[119:0]	data_b;
reg		rden_b,wren_b;
wire	[119:0]	q_a,q_b;
reg		[5:0]	addr_b;

reg	index_valid_temp[1:0];
reg	[4:0]	bid_temp[1:0];
reg	[5:0]	index_temp[1:0];// support default Action operation, discard;


// index_valid_temp manage 
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		index_valid_temp[0] <= 1'b0;
		index_valid_temp[1] <= 1'b0;
		bid_temp[0] <= 5'b0;
		index_temp[0] <= 6'b0;
	end
	else begin
		index_valid_temp[0] <= index_valid;
		index_valid_temp[1] <= index_valid_temp[0];
		bid_temp[0] <= index[10:6];
		bid_temp[1] <= bid_temp[0];
		index_temp[0] <= index[5:0];
		index_temp[1] <= index_temp[0];
	end
end

// stage 1 wait_1;	index_valid valid;
// stage 2 wait_2;	index_valid_temp[0] valid;
// stage 3 read_ram;	index_valid_temp[1] valid;
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		action_valid <= 1'b0;
		action <= 125'b0;
	end
	else begin
		if(index_valid_temp[1]==1'b1) begin
			action_valid <= 1'b1;
			if(index_temp[1]==6'h3f) action <= {bid_temp[1],24'b0,1'b1,1'b0,1'b1,93'b0};
			else action <= {bid_temp[1],q_a};
		end
		else action_valid <= 1'b0;
	end
end

reg	[3:0]	state;
parameter 	idle	= 4'd0,
			wait_1	= 4'd1,
			wait_2	= 4'd2,
			read_ram= 4'd3;

//update
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		state <= idle;
		wren_b <= 1'b0;
		rden_b <= 1'b0;
		data_b <= 120'b0;
		addr_b <= 6'b0;
		result_valid <= 1'b0;
		result <= 120'b0;
	end
	else begin
		case(state)
			idle: begin
				result_valid <= 1'b0;
				if(ruleSet_valid==1'b1) begin
					if(ruleSet[128]==1'b1) begin	// add;
						wren_b <= 1'b1;
						addr_b <= ruleSet[5:0];
						data_b <= ruleSet[127:8];
						state <= idle;
					end
					else begin	// read;
						rden_b <= 1'b1;
						addr_b <= ruleSet[5:0];
						state <= wait_1;
					end
				end
				else begin
					wren_b <= 1'b0;
					rden_b <= 1'b0;
				end
			end
			wait_1: begin
				rden_b <= 1'b0;
				state <= wait_2;
			end
			wait_2: state <= read_ram;
			read_ram: begin
				result_valid <= 1'b1;
				result <= q_b;
				state <= idle;
			end
			default: state <= idle;
		endcase
	end
end


ram ram_112_64(
.address_a(index[5:0]),
.address_b(addr_b),
.clock(clk),
.data_a(120'b0),
.data_b(data_b),
.rden_a(index_valid),
.rden_b(rden_b),
.wren_a(1'b0),
.wren_b(wren_b),
.q_a(q_a),
.q_b(q_b)

);
defparam
	ram_112_64.width 	= 120,
	ram_112_64.depth	= 6,
	ram_112_64.words	= 64;


endmodule

