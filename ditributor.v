//	Module name: parser->distributor
//	Authority @ lijunnan
//	Last edited time: 2017/02/13
//	Function outline: programmable parser
//
//	:)

module distributor(
clk,
reset,
headerData_in_valid,
headerData_in,
headerEnd_valid,
bid_bitmap,
headerData_out_valid,
headerData_out,
pktID_out,
headerData_finish_valid,
headerIn_enable
);
parameter 	widthHeaderData = 32,
			numExtraction	= 8,
			widthPkt		= 138;

input 	clk;
input	reset;
input	headerData_in_valid;
input	[widthPkt-1:0]	headerData_in;
input	headerEnd_valid;
input	[numExtraction-1:0]	bid_bitmap;
output	wire	[numExtraction-1:0]	headerData_out_valid;
output	wire	[widthHeaderData*numExtraction-1:0]	headerData_out;
output	wire	[numExtraction-1:0]	headerData_finish_valid;
output	wire	[8*numExtraction-1:0] pktID_out;
output	reg	headerIn_enable;


//=====temp=====//
integer i1,i2,i3,i4,i5;
reg	[7:0]	ramID;	// distribute packets one by one 

//headerIn_enable manage//
reg	[numExtraction-1:0]	usedw_bitmap;


//====bid_manage====//
reg	[1:0]	bidStart_tag[numExtraction-1:0];
reg	[1:0]	bidEnd_tag[numExtraction-1:0];
reg	empty_tag[numExtraction-1:0];


//fifo_temp//
reg		[widthPkt-1:0]	data_header;
wire	rdreq_header[numExtraction-1:0];
reg		[numExtraction-1:0]wrreq_header;
wire 	empty_header[numExtraction-1:0];
wire 	[widthPkt-1:0] 	q_header[numExtraction-1:0];
wire 	[5:0] 	usedw_header[numExtraction-1:0];


//======state====//
reg	state;
parameter		idle		= 1'd0,
				wait_end	= 1'd1;
				



always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		ramID <= 8'b1;
		state <= idle;
		wrreq_header <= {numExtraction{1'b0}};
	end
	else begin
		case(state)
			idle: begin
				if(headerData_in_valid == 1'b1) begin
					data_header <= headerData_in;
					wrreq_header <= ramID;
					state <= wait_end;
				end
				else wrreq_header <= {numExtraction{1'b0}};
			end
			wait_end: begin
				if(headerData_in[129:128] == 2'b1) begin
					if(ramID == 8'h80) ramID <= 8'd1;	// need to be changed; parameter formate
					else ramID <= ramID + ramID;
					state <= idle;
				end
				else state <= wait_end;
				data_header <= headerData_in;
			end
		endcase
	end
end


//128to32//
generate
	genvar j;
	for(j=0;j<numExtraction;j=j+1) begin : data_128to32	// 8bit pktID; headTag, tailTag, 128bit data;
		data_128to32 header_128to32(
		.clk(clk),
		.reset(reset),
		.headerOut_enable(bid_bitmap[j]&(~empty_header[j])),
		.rdreq(rdreq_header[j]),
		.data_in(q_header[j]),
		.headerData_out_valid(headerData_out_valid[j]),
		.headerData_out(headerData_out[(j+1)*widthHeaderData-1:j*widthHeaderData]),
		.pktID(pktID_out[j*8+7:j*8]),
		.headerData_finish_valid(headerData_finish_valid[j])
		);
		defparam 	header_128to32.widthPkt = widthPkt,
					header_128to32.widthHeaderData = widthHeaderData;
	end
endgenerate





always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		headerIn_enable <= 1'b0;
		usedw_bitmap <= {numExtraction{1'b0}};
	end
	else begin
		for(i2=0;i2<numExtraction;i2=i2+1)begin
			if(usedw_header[i2]>6'd50)	usedw_bitmap[i2] <= 1'b1;
			else usedw_bitmap[i2] <= 1'b0;
		end
		if(usedw_bitmap=={numExtraction{1'b0}}) headerIn_enable <= 1'b1;
		else headerIn_enable <= 1'b0;
	end
end




generate
	genvar i;
	for(i=0;i<numExtraction;i=i+1) begin : fifo
		fifo fifo_header(
		.aclr(!reset),
		.clock(clk),
		.data(data_header),
		.rdreq(rdreq_header[i]),
		.wrreq(wrreq_header[i]),
		.empty(empty_header[i]),
		.full(),
		.q(q_header[i]),
		.usedw(usedw_header[i])
		);
		defparam
			fifo_header.width = 138,
			fifo_header.depth = 6,
			fifo_header.words = 64;
    end
endgenerate




endmodule
