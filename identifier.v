module identifier(
clk,
reset,
stateType_valid_0,
stateType_0,
stateType_valid_1,
stateType_1,
stateType_valid_2,
stateType_2,
stateType_valid_3,
stateType_3,
stateType_valid_4,
stateType_4,
stateType_valid_5,
stateType_5,
stateType_valid_6,
stateType_6,
stateType_valid_7,
stateType_7,
type_out,
type_out_valid
);
parameter	numExtraction = 8,
			widthExtraction	=3,
			widthHeaderData	= 32;
input	clk;
input	reset;
input	stateType_valid_0;
input	[44:0]	stateType_0;
input	stateType_valid_1;
input	[44:0]	stateType_1;
input	stateType_valid_2;
input	[44:0]	stateType_2;
input	stateType_valid_3;
input	[44:0]	stateType_3;
input	stateType_valid_4;
input	[44:0]	stateType_4;
input	stateType_valid_5;
input	[44:0]	stateType_5;
input	stateType_valid_6;
input	[44:0]	stateType_6;
input	stateType_valid_7;
input	[44:0]	stateType_7;
output	reg	[44:0]	type_out;
output	reg	type_out_valid;

//--------temp----------//
integer i;

//==fifo==//
wire	[44:0]	data_stateType[numExtraction-1:0];
wire	wrreq_stateType[numExtraction-1:0];
reg		rdreq_stateType[numExtraction-1:0];
wire	empty_stateType[numExtraction-1:0];
wire	[44:0]	q_stateType[numExtraction-1:0];

assign data_stateType[0] = stateType_0;
assign data_stateType[1] = stateType_1;	
assign data_stateType[2] = stateType_2; 
assign data_stateType[3] = stateType_3;
assign data_stateType[4] = stateType_4;	
assign data_stateType[5] = stateType_5;
assign data_stateType[6] = stateType_6;	
assign data_stateType[7] = stateType_7;	
assign wrreq_stateType[0]= stateType_valid_0;
assign wrreq_stateType[1]= stateType_valid_1;
assign wrreq_stateType[2]= stateType_valid_2;
assign wrreq_stateType[3]= stateType_valid_3;
assign wrreq_stateType[4]= stateType_valid_4;
assign wrreq_stateType[5]= stateType_valid_5;
assign wrreq_stateType[6]= stateType_valid_6;
assign wrreq_stateType[7]= stateType_valid_7;


//temp 
wire	[3:0]	empty_odd_tag,empty_even_tag;
assign	empty_even_tag = {empty_stateType[7],empty_stateType[5],
					empty_stateType[3],empty_stateType[1]};
assign	empty_odd_tag = {empty_stateType[6],empty_stateType[4],
					empty_stateType[2],empty_stateType[0]};
					
//reg	[2:0]	tag;
reg		stateHungry;
parameter	read_odd	= 1'd0,
			read_even	= 1'd1;
			
		

		

//muxer 8to1//
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		stateHungry <= read_odd;
		type_out_valid <= 1'b0;
		type_out <= 45'b0;
		for(i=0;i<numExtraction;i=i+1) rdreq_stateType[i] <= 1'b0;
	end
	else begin // hungry to die
		case(stateHungry)
			read_odd: begin
				rdreq_stateType[1] <= 1'b0;
				rdreq_stateType[3] <= 1'b0;
				rdreq_stateType[5] <= 1'b0;
				rdreq_stateType[7] <= 1'b0;
				
				if(empty_stateType[0]==1'b0) rdreq_stateType[0] <= 1'b1;
				else if(empty_stateType[2]==1'b0) rdreq_stateType[2] <= 1'b1;
				else if(empty_stateType[4]==1'b0) rdreq_stateType[4] <= 1'b1;
				else if(empty_stateType[6]==1'b0) rdreq_stateType[6] <= 1'b1;
				else begin
				end
				stateHungry <= read_even;
				
				case({rdreq_stateType[7],rdreq_stateType[5],rdreq_stateType[3],rdreq_stateType[1]})
					4'h1: begin
						type_out_valid <= 1'b1;
						type_out <= q_stateType[1];
					end
					4'h2: begin
						type_out_valid <= 1'b1;
						type_out <= q_stateType[3];
					end
					4'h4: begin
						type_out_valid <= 1'b1;
						type_out <= q_stateType[5];
					end
					4'h8: begin
						type_out_valid <= 1'b1;
						type_out <= q_stateType[7];
					end
					default: begin
						type_out_valid <= 1'b0;
					end
				endcase
			end
			read_even: begin
				rdreq_stateType[0] <= 1'b0;
				rdreq_stateType[2] <= 1'b0;
				rdreq_stateType[4] <= 1'b0;
				rdreq_stateType[6] <= 1'b0;
				
				if(empty_stateType[1]==1'b0) rdreq_stateType[1] <= 1'b1;
				else if(empty_stateType[3]==1'b0) rdreq_stateType[3] <= 1'b1;
				else if(empty_stateType[5]==1'b0) rdreq_stateType[5] <= 1'b1;
				else if(empty_stateType[7]==1'b0) rdreq_stateType[7] <= 1'b1;
				else begin
				end
				stateHungry <= read_odd;
				
				case({rdreq_stateType[6],rdreq_stateType[4],rdreq_stateType[2],rdreq_stateType[0]})
					4'h1: begin
						type_out_valid <= 1'b1;
						type_out <= q_stateType[0];
					end
					4'h2: begin
						type_out_valid <= 1'b1;
						type_out <= q_stateType[2];
					end
					4'h4: begin
						type_out_valid <= 1'b1;
						type_out <= q_stateType[4];
					end
					4'h8: begin
						type_out_valid <= 1'b1;
						type_out <= q_stateType[6];
					end
					default: begin
						type_out_valid <= 1'b0;
					end
				endcase
			end
		endcase
	end
end


		



//fifo_stateType_0-7
generate
	genvar h;
	for(h=0;h<numExtraction;h=h+1) begin : fifo
	fifo fifo_stateType(
	.aclr(!reset),
	.clock(clk),
	.data(data_stateType[h]),
	.rdreq(rdreq_stateType[h]),
	.wrreq(wrreq_stateType[h]),
	.empty(empty_stateType[h]),
	.full(),
	.q(q_stateType[h]),
	.usedw()
	);
	defparam
		fifo_stateType.width = 45,
		fifo_stateType.depth = 4,
		fifo_stateType.words = 16;
	end
endgenerate
		
		



	
	
endmodule
