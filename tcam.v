//	Module name: parser->BVbasedSearcher
//	Authority @ lijunnan
//	Last edited time: 2017/02/15
//	Function outline: programmable parser
//	===do not support read;

module BVbasedSearcher(
clk,
reset,
key,
key_valid,
index_valid,
index,
ruleSet_valid,
ruleSet,
result_valid,
result
);
parameter	depthTCAM = 6;

input	clk;
input	reset;
input	[44:0]	key;
input	key_valid;
output	reg	index_valid;
output	reg	[depthTCAM+4:0]	index;
input	ruleSet_valid;
input	[49:0]	ruleSet;		// [49:48] operationCode 2'd0:read; 2'd1:add; 2'd2:del;
								// 	[47:8] key:type+state;
								//	[7:0] ruleNUM;
output	reg	result_valid;
output	reg	[63:0]	result;
//temp

integer i1,i2,i3;

wire	bv_valid[4:0];
wire	[63:0]	bv[4:0];
reg		bv_and_valid;
reg		[63:0]	bv_and;
// bid manage
reg	[4:0]	bid_temp[10:0];
wire	countid_valid;
wire	[5:0]	countid;

reg	set_valid[4:0];
reg	[16:0]	rule_set[4:0];	//[16]: '1' is add; '0'; is del;
							//[15:8]: subKey;
							//[7:0]: ruleNum;

always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		for(i1=0;i1<5;i1=i1+1) begin
			set_valid[i1] <=1'b0;
			rule_set[i1] <= 17'b0;
		end
	end
	else begin
		if(ruleSet_valid==1'b1) begin 
			for(i2=0;i2<5;i2=i2+1) begin
				set_valid[i2] <=1'b1;
			end
			rule_set[0] <= {ruleSet[48],ruleSet[15:0]};
			rule_set[1] <= {ruleSet[48],ruleSet[23:16],ruleSet[7:0]};
			rule_set[2] <= {ruleSet[48],ruleSet[31:24],ruleSet[7:0]};
			rule_set[3] <= {ruleSet[48],ruleSet[39:32],ruleSet[7:0]};
			rule_set[4] <= {ruleSet[48],ruleSet[47:40],ruleSet[7:0]};
			
		end
		else begin 
			for(i3=0;i3<5;i3=i3+1) begin
				set_valid[i3] <=1'b0;
				rule_set[i3] <= 17'b0;
			end
		end
	end
end							
							
							
//
generate
	genvar i;
	for(i=0; i<5; i=i+1) begin: lookup_bit
		lookup_bit lb(
		.clk(clk),
		.reset(reset),
		.key_valid(key_valid),
		.key(key[(i*8+7):i*8]),
		.bv_valid(bv_valid[i]),
		.bv(bv[i]),
		.set_valid(set_valid[i]),
		.set(rule_set[i])
		);
		end
endgenerate

always @(posedge clk or negedge reset) begin
	if(!reset) begin
		bv_and_valid <= 1'b0;
		bv_and	<= 64'b0;
	end
	else begin
		bv_and <= bv[0]&bv[1]&bv[2]&bv[3]&bv[4];
		bv_and_valid <= bv_valid[0];
		
		
	end
end

calculate_countid calculate_countid(
.clk(clk),
.reset(reset),
.bv_in_valid(bv_and_valid),
.bv_in(bv_and),
.countid_valid(countid_valid),
.countid(countid)
);


//bid manage


always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		bid_temp[0] <= 5'b0;
	end
	else begin
		bid_temp[0] <= key[44:40];
		bid_temp[1] <= bid_temp[0];
		bid_temp[2] <= bid_temp[1];
		bid_temp[3] <= bid_temp[2];
		bid_temp[4] <= bid_temp[3];
		bid_temp[5] <= bid_temp[4];
		bid_temp[6] <= bid_temp[5];
		bid_temp[7] <= bid_temp[6];
		bid_temp[8] <= bid_temp[7];
		bid_temp[9] <= bid_temp[8];
		bid_temp[10] <= bid_temp[9];		
	end
end

always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		index_valid <= 1'b0;
		index <= 11'b0;
	end
	else begin
		if(countid_valid==1'b1) begin
			index_valid <= 1'b1;
			index <= {bid_temp[9],countid};
		end
		else index_valid <= 1'b0;
	end
end




endmodule
