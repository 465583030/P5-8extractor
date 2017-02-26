module pkt_gen(
clk,
reset,
headerData_valid,
headerData,
headerData_out_valid,
headerData_out,
headerIn_enable
);
input	clk;
input	reset;
input	headerData_valid;
input	[129:0]	headerData;
output	reg	headerData_out_valid;
output	reg	[137:0]	headerData_out;
input 	headerIn_enable;


reg	[7:0]	count_temp;

reg state_headerIn,state_headerOut;
//fifo//
reg		rdreq_header,wrreq_header;
reg		[129:0] data_header;
wire	empty_header;
wire	[129:0]	q_header;

//header out;
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		rdreq_header <= 1'b0;
		headerData_out_valid <= 1'b0;
		headerData_out <= 138'b0;
		state_headerOut <= 1'b0;
		count_temp <= 8'd0;
	end
	else begin
		case(state_headerOut)
			1'b0: begin
				headerData_out_valid <= 1'b0;
				headerData_out <= 138'b0;
				if((empty_header==1'b0) && (headerIn_enable==1'b1)) begin
					rdreq_header <= 1'b1;
					state_headerOut <= 1'b1;
				end
				else begin
					rdreq_header <= 1'b0;
					state_headerOut <= 1'b0;
				end
			end
			1'b1: begin
				headerData_out_valid <= 1'b1;
				headerData_out <= {count_temp,q_header};
				if(q_header[129:128]==2'b01) begin
					rdreq_header <= 1'b0;
					state_headerOut <= 1'b0;
					count_temp <= count_temp + 8'd1;
				end
				else begin
					rdreq_header <= 1'b1;
					state_headerOut <= 1'b1;
				end
			end
		endcase
	end
end


//header in
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		wrreq_header <= 1'b0;
		data_header <= 130'b0;
		state_headerIn <= 1'b0;
	end
	else begin
		case(state_headerIn)
			1'b0: begin
				if(headerData_valid == 1'b1) begin
					if(headerIn_enable==1'b1) begin
						wrreq_header <= 1'b1;
						data_header <= headerData;
					end
					else begin
						wrreq_header <= 1'b0;
						state_headerIn <= 1'b1;
					end
				end
				else begin
					wrreq_header <= 1'b0;
					state_headerIn <= 1'b0;
				end
			end
			1'b1: begin 
				data_header <= headerData;
				if(headerData[129:128]==2'b01) begin
					state_headerIn <= 1'b0;
				end
				else state_headerIn <= 1'b1;
			end
		endcase
	end
end

reg	[31:0]	count_time;
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		count_time <= 32'b0;
	end
	else begin
		count_time <= 32'b1 + count_time;
	end
end

fifo fifo_header(
.aclr(!reset),
.clock(clk),
.data(data_header),
.rdreq(rdreq_header),
.wrreq(wrreq_header),
.empty(empty_header),
.full(),
.q(q_header),
.usedw()
);
defparam
    fifo_header.width = 130,
    fifo_header.depth = 8,
    fifo_header.words = 256;

endmodule	