
module lookup(
clk,
reset,
headerVector_valid,
headerVector,
action_valid,
action,
ruleSet_valid,
ruleSet
);

input	clk;
input	reset;
input	headerVector_valid;
input	[199:0]	headerVector;
output	reg	action_valid;
output	reg	[31:0]	action;
input	ruleSet_valid;
input	[63:0]	ruleSet;



reg	[51:0]	rule_dmac[3:0];	//48mac + 4 port;
reg	[51:0]	rule_smac[1:0];	//48mac + 4 ins;	'0001' is discard, '0000' is passed;


//lookup
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		action_valid <= 1'b0;
		action <= 32'b0;
	end
	else begin
		if(headerVector_valid==1'b1) begin
			action_valid <= 1'b1;
			action[31:24] <= headerVector[199:192];
			if(headerVector[191:144]==rule_dmac[0][51:4]) action[3:0] <= rule_dmac[0][3:0];
			else if(headerVector[191:144]==rule_dmac[1][51:4]) action[3:0] <= rule_dmac[1][3:0];
			else if(headerVector[191:144]==rule_dmac[2][51:4]) action[3:0] <= rule_dmac[2][3:0];
			else if(headerVector[191:144]==rule_dmac[3][51:4]) action[3:0] <= rule_dmac[3][3:0];
			else action[3:0] <= 4'd0;

			if(headerVector[143:96]==rule_smac[0][51:0]) action[19:16] <= rule_smac[0][3:0];
			else if(headerVector[143:96]==rule_smac[1][51:0]) action[19:16] <= rule_smac[1][3:0];
			else action[19:16] <= 4'd0;
		end
		else action_valid <= 1'b0;
	end
end

//rule set
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		rule_dmac[0] <= 52'b0;rule_dmac[1] <= 52'b0;
		rule_dmac[2] <= 52'b0;rule_dmac[3] <= 52'b0;
		rule_smac[0] <= 52'b0;rule_smac[1] <= 52'b0;
	end
	else begin
		if(ruleSet_valid==1'b1) begin
			case(ruleSet[55:52])
				4'd0:	rule_dmac[0] <= ruleSet[51:0];
				4'd1:	rule_dmac[1] <= ruleSet[51:0];
				4'd2:	rule_dmac[2] <= ruleSet[51:0];
				4'd3:	rule_dmac[3] <= ruleSet[51:0];
				4'd4:	rule_smac[0] <= ruleSet[51:0];
				4'd5:	rule_smac[1] <= ruleSet[51:0];
				default: begin
				end
			endcase
		end
		else begin 
		end
	end
end









endmodule