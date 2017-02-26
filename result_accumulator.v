//	Module name: parser->result_accumulator
//	Authority @ lijunnan
//	Last edited time: 2017/02/15
//	Function outline: programmable parser
//

module result_accumulator(
clk,
reset,
field_valid,
field,
offset,
field_finish_valid,
field_finish_bid,
metadata_valid,
metadata
);
parameter	widthHeaderData = 32,
			widthHeaderVector=200;

input	clk;
input	reset;
input	field_valid;
input	[widthHeaderData-1:0]	field;
input	[11:0]	offset;	// 5bit:ramID+ 7bit offset;
input	field_finish_valid;
input	[23:0]	field_finish_bid;	// 8bit action; 3bit reserved; 5bit bid + 8 bit pktID;
output	reg		metadata_valid;
output	reg	[widthHeaderVector-1:0]	metadata;	// 8bit pktID, widthHV metadata;


//====temp====//
reg		[7:0]	pktID_temp;
//ram
reg		[7:0]	addr_a;
reg		rden_a;
wire	[widthHeaderData-1:0]	q_a;
//fifo
reg		rdreq_finish;
wire	empty_finish;
wire	[23:0]	q_finish;

reg	[2:0]	state;
parameter		idle		= 3'd0,
				read_fifo	= 3'd1,
				wait1		= 3'd2,
				wait2		= 3'd3,
				read		= 3'd4;

//accumulate result;
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		metadata_valid <= 1'b0;
		metadata <= {widthHeaderVector{1'b0}};
		rden_a <= 1'b0;
		addr_a <= 8'b0;
		rdreq_finish <= 1'b0;
		pktID_temp <= 8'd0;
		state <= idle;
	end
	else begin
		case(state)
			idle: begin
				metadata_valid <= 1'b0;
				if(empty_finish == 1'b0) begin
					state <= read_fifo;
					rdreq_finish <= 1'b1;
				end
			end
			read_fifo: begin
				rdreq_finish <= 1'b0;
				if(q_finish[23]==1'b1) begin
					metadata_valid <= 1'b1;
					metadata <= {q_finish[7:0],{(widthHeaderVector-8){1'b0}}};
					state <= idle;
				end
				else begin
					rden_a <= 1'b1;
					addr_a <= {q_finish[9:8],6'b0};
					pktID_temp <= q_finish[7:0];
					state <= wait1;
				end
			end
			wait1: begin	// 0
				addr_a <= addr_a + 10'd1;
				state <= wait2;
			end
			wait2: begin	// 1
				addr_a <= addr_a + 10'd1;
				state <= read;
			end
			read: begin		// 2
				if(addr_a[3:0] == 4'd7) begin
					state <= idle;
					rden_a <= 1'b0;
					metadata_valid <= 1'b1;
				end
				else state <=read;
				metadata <= {pktID_temp,metadata[widthHeaderVector-41:0],q_a};
				addr_a <= addr_a + 10'b1;
				
			end
		endcase
	end
end


ram result(
.address_a(addr_a),
.address_b({offset[8:7],offset[5:0]}),
.clock(clk),
.data_a({widthHeaderData{1'b0}}),
.data_b(field),
.rden_a(rden_a),
.rden_b(1'b0),
.wren_a(1'b0),
.wren_b(field_valid),
.q_a(q_a),
.q_b()
);
defparam
	result.width	= widthHeaderData,
	result.depth	= 8,
	result.words	= 256;

	
	
fifo fifo_finish(
.aclr(!reset),
.clock(clk),
.data(field_finish_bid),
.rdreq(rdreq_finish),
.wrreq(field_finish_valid),
.empty(empty_finish),
.full(),
.q(q_finish),
.usedw()
);
defparam
	fifo_finish.width = 24,
	fifo_finish.depth = 5,
	fifo_finish.words = 32;




endmodule
