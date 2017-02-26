
module pktBuffer(
clk,
reset,
pktID_in_valid,
pktID_in,
cdp2um_data_valid,
cdp2um_data,
um2cdp_data_valid,
um2cdp_data,
headerData_valid,
headerData,
headerData_finish_valid,
pktID_out,
bid_bitmap,
headerIn_enable,
cdp2um_rule_usedw,
writeRule_enable
);

input	clk;
input	reset;
input	pktID_in_valid;
input	[11:0]	pktID_in;//action_ins 4bit + 8bit pktID; [9:8]: '01' is discard; '02' is repeated; 
input	cdp2um_data_valid;
input	[138:0]	cdp2um_data;
output	reg	um2cdp_data_valid;
output	reg	[138:0]	um2cdp_data;
//output	wire	[7:0]	headerData_valid;
//output	wire	[255:0]	headerData;
//output	wire	[7:0]	headerData_finish_valid;
//output	wire	[63:0]	pktID_out;
output	reg	[7:0]	headerData_valid;
output	reg	[255:0]	headerData;
output	reg	[7:0]	headerData_finish_valid;
output	reg	[63:0]	pktID_out;

input	[7:0]	bid_bitmap;
output	reg		headerIn_enable;
input	[4:0]	cdp2um_rule_usedw;
output	reg		writeRule_enable;

//temp
reg	[7:0]	pktID_temp;

//ram
reg	[8:0]	addr_a,addr_b;
reg	[138:0]	data_b;
reg	rden_a,wren_b;
wire	[138:0]	q_a;
// fifo
reg	[7:0]	wrreq_header;
wire	rdreq_header[7:0];
reg	[137:0]	data_header;	// pktID, 2'b tag, 128data;
wire 	empty_header[7:0];
wire 	[137:0] 	q_header[7:0];

reg		[7:0]	ramID,count_header;
reg		state,state_in;
parameter	idle_in		= 1'd0,
			wait_end	= 1'd1;






//pkt in;
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		pktID_temp <= 8'b0;
		addr_b <= 9'b0;
		wren_b <= 1'b0;
		data_b <= 139'b0;
		state_in <= idle_in;
	end
	else begin
		case(state_in)
			idle_in: begin
				if((cdp2um_data_valid==1'b1)&&(cdp2um_data[138:136]==3'b101)) begin
					wren_b 	<= 1'b1;
					addr_b	<= {pktID_temp[4:0],4'b0};
					data_b	<= cdp2um_data;
					state_in <= wait_end;
				end
				else begin
					wren_b <= 1'b0;
					state_in <= idle_in;
				end
			end
			wait_end: begin
				if(cdp2um_data[138:136]==3'b110) begin 
					state_in <= idle_in;
					pktID_temp <= pktID_temp + 8'd1;
				end
				else state_in <= wait_end;
				data_b <= cdp2um_data;
				addr_b <= addr_b + 9'd1;
			end
			default: state_in <= idle_in;
		endcase
	end
end

reg	[1:0]	state_out;
parameter	idle_out	= 2'd0,
			wait_1		= 2'd1,
			wait_2		= 2'd2,
			read_ram	= 2'd3;
//pkt out
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		addr_a <= 9'b0;
		rden_a <= 1'b0;
		um2cdp_data_valid <= 1'b0;
		um2cdp_data <= 139'b0;
		state_out <= idle_out;
		writeRule_enable <= 1'b0;
	end
	else begin
		case(state_out)
			idle_out: begin
				um2cdp_data_valid <= 1'b0;
				if((pktID_in_valid==1'b1)&&(pktID_in[9:8]!=2'd1)) begin
					rden_a 	<= 1'b1;
					addr_a	<= {pktID_in[4:0],4'b0};
					state_out <= wait_1;
				end
				else begin
					state_out <= idle_in;
				end
				if(cdp2um_rule_usedw < 5'd30) writeRule_enable <= 1'b1;
				else writeRule_enable <= 1'b0;
			end
			wait_1: begin
				writeRule_enable <= 1'b0;
				state_out <= wait_2;
				addr_a <= addr_a +9'd1;
			end
			wait_2: begin
				state_out <= read_ram;
				addr_a <= addr_a +9'd1;
			end
			read_ram: begin
				if(q_a[138:136]==3'b110) state_out <= idle_out;
				else state_out <= read_ram;
				um2cdp_data_valid <= 1'b1;
				um2cdp_data <= q_a;
				addr_a <= addr_a + 9'd1;
			end
			default: state_out <= idle_out;
		endcase
	end
end

//pkt in sim
reg	[255:0]	packet_add;
reg	[64:0]	pktID_add;
reg	[3:0]	state_sim;

parameter 	idle_sim		= 4'd0,
			ready_sim		= 4'd1,
			wait_end_sim	= 4'd2,
			bubble_sim		= 4'd3;

always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		headerData_valid <= 8'd0;
		headerData <= 256'b0;
		headerData_finish_valid <= 8'd0;
		pktID_out <= 64'b0;
		pktID_add <= 	{8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1};
		packet_add <= 	{32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,
						32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1,32'd1};
	end
	else begin
		case(state_sim)
			idle_sim: begin
				if(cdp2um_data_valid==1'b1) state_sim <= ready_sim;
				else state_sim <= idle_sim;
			end
			ready_sim: begin
				headerData_finish_valid <= 8'h0;
				if(bid_bitmap==8'hff) begin 
					headerData_valid <= 8'hff;
					headerData <= packet_add;
					state_sim <= wait_end_sim;					
				end
				else begin
					headerData_valid <= 8'h0;
					state_sim <= ready_sim;
				end
			end
			wait_end_sim: begin
				if(headerData[7:0]==8'd15) begin 
					state_sim <= ready_sim;
					//state_sim <= bubble_sim;
					headerData_finish_valid <= 8'hff;
					pktID_out <= pktID_add + pktID_out;
				end
				else state_sim <= wait_end_sim;
				headerData <= packet_add + headerData;
			end
			bubble_sim: begin
				headerData_finish_valid <= 8'h0;
				headerData_valid <= 8'h0;
			end
			default: state_sim <= idle_sim;
		endcase
	end
end


/*


//128 to 32;
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		ramID <= 8'b1;
		state <= idle_in;
		data_header <= 138'b0;
		wrreq_header <= 8'b0;
		count_header <= 8'd0;
	end
	else begin
		case(state)
			idle_in: begin
				if((cdp2um_data_valid == 1'b1) && (cdp2um_data[138:136]==3'b101))begin
					data_header <= {pktID_temp,2'b10,cdp2um_data[127:0]};
					wrreq_header <= ramID;
					state <= wait_end;
					count_header <= 8'd0;
				end
				else wrreq_header <= 8'd0;
			end
			wait_end: begin
				if((count_header == 8'd31)||cdp2um_data[138:136]==3'b110) begin
					state <= idle_in;
					data_header <= {pktID_temp,2'b01,cdp2um_data[127:0]};
					if(ramID == 8'h80) ramID <= 8'd1;
					else ramID <= ramID + ramID;
				end
				else begin 
					state <= wait_end;
					data_header <= {pktID_temp,2'b00,cdp2um_data[127:0]};
				end
			end
		endcase
	end
end

generate
	genvar j;
	for(j=0;j<8;j=j+1) begin : data_128to32	// 8bit pktID; headTag, tailTag, 128bit data;
		data_128to32 header_128to32(
		.clk(clk),
		.reset(reset),
		.headerOut_enable(bid_bitmap[j]&(~empty_header[j])),
		.rdreq(rdreq_header[j]),
		.data_in(q_header[j]),
		.headerData_out_valid(headerData_valid[j]),
		.headerData_out(headerData[j*32+31:j*32]),
		.pktID(pktID_out[j*8+7:j*8]),
		.headerData_finish_valid(headerData_finish_valid[j])
		);
		defparam 	header_128to32.widthPkt = 138,
					header_128to32.widthHeaderData = 32;
	end
endgenerate
*/

ram ram_138_1024(	// block: 256B;	// 4bit addr;
.address_a(addr_a),
.address_b(addr_b),
.clock(clk),
.data_a(139'b0),
.data_b(data_b),
.rden_a(rden_a),
.rden_b(1'b0),
.wren_a(1'b0),
.wren_b(wren_b),
.q_a(q_a),
.q_b()

);
defparam
	ram_138_1024.width 	= 139,
	ram_138_1024.depth	= 9,
	ram_138_1024.words	= 512;

generate
	genvar i;
	for(i=0;i<8;i=i+1) begin : fifo
		fifo fifo_header(
		.aclr(!reset),
		.clock(clk),
		.data(data_header),
		.rdreq(rdreq_header[i]),
		.wrreq(wrreq_header[i]),
		.empty(empty_header[i]),
		.full(),
		.q(q_header[i]),
		.usedw()
		);
		defparam
			fifo_header.width = 138,
			fifo_header.depth = 6,
			fifo_header.words = 64;
    end
endgenerate	
	



endmodule