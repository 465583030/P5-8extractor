//	Module name: parser->distributor->data_128to32
//	Authority @ lijunnan
//	Last edited time: 2017/02/13
//	Function outline: programmable parser
//

module data_128to32(
clk,
reset,
headerOut_enable,
rdreq,
data_in,
headerData_out_valid,
headerData_out,
headerData_finish_valid,
pktID
);
parameter 	widthPkt = 138,
			widthHeaderData = 32;

input	clk;
input	reset;
input	headerOut_enable;
output	reg	rdreq;
input	[widthPkt-1:0] data_in;
output	reg	headerData_out_valid;
output	reg	[widthHeaderData-1:0] headerData_out;
output	reg	headerData_finish_valid;
output	reg	[7:0]	pktID;

//temp
reg	[widthPkt-1:0]	headerData_temp;
reg [2:0] state;
parameter 	idle = 3'd0,
			read_fifo = 3'd1,
			out_2	= 3'd2,
			out_3	= 3'd3,
			out_4	= 3'd4;
			

always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		headerData_out_valid <= 1'b0;
		headerData_out <= {widthHeaderData{1'b0}};
		rdreq <= 1'b0;
		headerData_finish_valid <= 1'b0;
		pktID <= 8'b0;
		state <= idle;
	end
	else begin
		case(state)
		idle: begin
			headerData_out_valid <= 1'b0;
			headerData_finish_valid <= 1'b0;
			if(headerOut_enable == 1'b1) begin
				rdreq <= 1'b1;
				state <= read_fifo;
			end
			else begin
				rdreq <= 1'b0;
			end
		end
		read_fifo: begin
			rdreq <= 1'b0;
			headerData_temp <= data_in;
			headerData_out_valid <= 1'b1;
			headerData_out <= data_in[127:96]; // need to be changed; parameter format
			state <= out_2;
		end
		out_2: begin
			headerData_out <= headerData_temp[95:64]; // need to be changed; parameter format
			state <= out_3;
		end
		out_3: begin
			headerData_out <= headerData_temp[63:32]; // need to be changed; parameter format
			state <= out_4;
		end
		out_4: begin
			headerData_out <= headerData_temp[31:0]; // need to be changed; parameter format
			if(headerData_temp[129:128]==2'b1) begin 
				headerData_finish_valid <= 1'b1;
				pktID <= headerData_temp[137:130];
				state <= idle;
			end
			else headerData_finish_valid <= 1'b0;
			
			if(headerOut_enable==1'b1) begin
				state <= read_fifo;
				rdreq <= 1'b1;
			end
			else state <= idle;
		end
		default: state <= idle;
		endcase
	end
end


endmodule