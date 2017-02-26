//	Module name: parser->result_mux
//	Authority @ lijunnan
//	Last edited time: 2017/02/15
//	Function outline: programmable parser
//

module result_mux(
clk,
reset,
metadata_valid_0,
metadata_0,
metadata_valid_1,
metadata_1,
metadata_valid_2,
metadata_2,
metadata_valid_3,
metadata_3,
metadata_valid_4,
metadata_4,
metadata_valid_5,
metadata_5,
metadata_valid_6,
metadata_6,
metadata_valid_7,
metadata_7,
headerVector_valid,
headerVector
);
parameter 	numExtraction = 8,
			widthHeaderData = 32;

parameter	widthHV	= 200,	// 8bit pktID; + 192 metadata;
			numMeta	= 4,
			limitMeta=4'd5;			

input	clk;
input	reset;
input	metadata_valid_0;
input	[widthHV-1:0]	metadata_0;
input	metadata_valid_1;
input	[widthHV-1:0]	metadata_1;
input	metadata_valid_2;
input	[widthHV-1:0]	metadata_2;
input	metadata_valid_3;
input	[widthHV-1:0]	metadata_3;
input	metadata_valid_4;
input	[widthHV-1:0]	metadata_4;
input	metadata_valid_5;
input	[widthHV-1:0]	metadata_5;
input	metadata_valid_6;
input	[widthHV-1:0]	metadata_6;
input	metadata_valid_7;
input	[widthHV-1:0]	metadata_7;
output	reg	headerVector_valid;
output	reg	[widthHV-1:0]	headerVector;


reg		rdreq_meta[numExtraction-1:0];
wire	empty_meta[numExtraction-1:0];
wire	[widthHV-1:0]	q_meta[numExtraction-1:0];

reg	[2:0]	state;
parameter	read_odd 	= 4'd0,
			read_even	= 4'd1,
			read_fifo	= 4'd2;

reg	[numMeta-1:0]	count_meta;			

reg	odd_even_tag;	//'1' is odd; '0' is even;			

always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		state <= read_odd;
		count_meta <= 4'b0;
		headerVector_valid <= 1'b0;
		headerVector <= {widthHV{1'b0}};
		odd_even_tag <= 1'b1;
		rdreq_meta[0] <= 1'b0;rdreq_meta[1] <= 1'b0;rdreq_meta[2] <= 1'b0;
		rdreq_meta[3] <= 1'b0;rdreq_meta[4] <= 1'b0;rdreq_meta[5] <= 1'b0;
		rdreq_meta[6] <= 1'b0;rdreq_meta[7] <= 1'b0;
	end
	else begin
		case(state)
			read_odd: begin
				headerVector_valid <= 1'b0;
				headerVector <= {widthHV{1'b0}};
				if(empty_meta[0]==1'b0) begin
					rdreq_meta[0] <= 1'b1;
					state <= read_fifo;
				end
				else if(empty_meta[2]==1'b0) begin
					rdreq_meta[2] <= 1'b1;
					state <= read_fifo;
				end
				else if(empty_meta[4]==1'b0) begin
					rdreq_meta[4] <= 1'b1;
					state <= read_fifo;
				end
				else if(empty_meta[6]==1'b0) begin
					rdreq_meta[6] <= 1'b1;
					state <= read_fifo;
				end
				else begin 
					state <= read_even;
					odd_even_tag <= 1'b0;
				end
			end
			read_even: begin
				headerVector_valid <= 1'b0;
				headerVector <= {widthHV{1'b0}};
				if(empty_meta[1]==1'b0) begin
					rdreq_meta[1] <= 1'b1;
					state <= read_fifo;
				end
				else if(empty_meta[3]==1'b0) begin
					rdreq_meta[3] <= 1'b1;
					state <= read_fifo;
				end
				else if(empty_meta[5]==1'b0) begin
					rdreq_meta[5] <= 1'b1;
					state <= read_fifo;
				end
				else if(empty_meta[7]==1'b0) begin
					rdreq_meta[7] <= 1'b1;
					state <= read_fifo;
				end
				else begin 
					state <= read_odd;
					odd_even_tag <= 1'b1;
				end
			end
			read_fifo: begin
				if(odd_even_tag==1'b1) state <= read_odd;
				else state <= read_even;
				headerVector_valid <= 1'b1;
				odd_even_tag <= ~odd_even_tag;
				rdreq_meta[0] <= 1'b0;rdreq_meta[1] <= 1'b0;rdreq_meta[2] <= 1'b0;
				rdreq_meta[3] <= 1'b0;rdreq_meta[4] <= 1'b0;rdreq_meta[5] <= 1'b0;
				rdreq_meta[6] <= 1'b0;rdreq_meta[7] <= 1'b0;
				case({rdreq_meta[7],rdreq_meta[6],rdreq_meta[5],rdreq_meta[4],
					rdreq_meta[3],rdreq_meta[2],rdreq_meta[1],rdreq_meta[0]})
					8'h1: headerVector <= q_meta[0];
					8'h2: headerVector <= q_meta[1];
					8'h4: headerVector <= q_meta[2];
					8'h8: headerVector <= q_meta[3];
					8'h10: headerVector <= q_meta[4];
					8'h20: headerVector <= q_meta[5];
					8'h40: headerVector <= q_meta[6];
					8'h80: headerVector <= q_meta[7];
				endcase
			end
			default: state <= read_odd;
		endcase
	end
end


fifo fifo_meta_0(
.aclr(!reset),
.clock(clk),
.data(metadata_0),
.rdreq(rdreq_meta[0]),
.wrreq(metadata_valid_0),
.empty(empty_meta[0]),
.full(),
.q(q_meta[0]),
.usedw()
);
defparam
    fifo_meta_0.width = widthHV,
    fifo_meta_0.depth = 5,
    fifo_meta_0.words = 32;

fifo fifo_meta_1(
.aclr(!reset),
.clock(clk),
.data(metadata_1),
.rdreq(rdreq_meta[1]),
.wrreq(metadata_valid_1),
.empty(empty_meta[1]),
.full(),
.q(q_meta[1]),
.usedw()
);
defparam
    fifo_meta_1.width = widthHV,
    fifo_meta_1.depth = 5,
    fifo_meta_1.words = 32;

fifo fifo_meta_2(
.aclr(!reset),
.clock(clk),
.data(metadata_2),
.rdreq(rdreq_meta[2]),
.wrreq(metadata_valid_2),
.empty(empty_meta[2]),
.full(),
.q(q_meta[2]),
.usedw()
);
defparam
    fifo_meta_2.width = widthHV,
    fifo_meta_2.depth = 5,
    fifo_meta_2.words = 32;

fifo fifo_meta_3(
.aclr(!reset),
.clock(clk),
.data(metadata_3),
.rdreq(rdreq_meta[3]),
.wrreq(metadata_valid_3),
.empty(empty_meta[3]),
.full(),
.q(q_meta[3]),
.usedw()
);
defparam
    fifo_meta_3.width = widthHV,
    fifo_meta_3.depth = 5,
    fifo_meta_3.words = 32;

fifo fifo_meta_4(
.aclr(!reset),
.clock(clk),
.data(metadata_4),
.rdreq(rdreq_meta[4]),
.wrreq(metadata_valid_4),
.empty(empty_meta[4]),
.full(),
.q(q_meta[4]),
.usedw()
);
defparam
    fifo_meta_4.width = widthHV,
    fifo_meta_4.depth = 5,
    fifo_meta_4.words = 32;

fifo fifo_meta_5(
.aclr(!reset),
.clock(clk),
.data(metadata_5),
.rdreq(rdreq_meta[5]),
.wrreq(metadata_valid_5),
.empty(empty_meta[5]),
.full(),
.q(q_meta[5]),
.usedw()
);
defparam
    fifo_meta_5.width = widthHV,
    fifo_meta_5.depth = 5,
    fifo_meta_5.words = 32;

fifo fifo_meta_6(
.aclr(!reset),
.clock(clk),
.data(metadata_6),
.rdreq(rdreq_meta[6]),
.wrreq(metadata_valid_6),
.empty(empty_meta[6]),
.full(),
.q(q_meta[6]),
.usedw()
);
defparam
    fifo_meta_6.width = widthHV,
    fifo_meta_6.depth = 5,
    fifo_meta_6.words = 32;

fifo fifo_meta_7(
.aclr(!reset),
.clock(clk),
.data(metadata_7),
.rdreq(rdreq_meta[7]),
.wrreq(metadata_valid_7),
.empty(empty_meta[7]),
.full(),
.q(q_meta[7]),
.usedw()
);
defparam
    fifo_meta_7.width = widthHV,
    fifo_meta_7.depth = 5,
    fifo_meta_7.words = 32;






	
endmodule

