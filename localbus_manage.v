
module localbus_manage(
clk,
reset,
localbus_cs_n,
localbus_rd_wr,
localbus_data,
localbus_ale,
localbus_ack_n,
localbus_data_out,

parserRuleSet_valid,
parserRuleSet,
result_valid,
result,
lookupRuleSet_valid,
lookupRuleSet
);
input	clk;
input	reset;
input	localbus_cs_n;
input	localbus_rd_wr;
input	[31:0]	localbus_data;
input	localbus_ale;
output	reg	localbus_ack_n;
output	reg	[31:0] localbus_data_out;

output	reg	parserRuleSet_valid;
output	reg	[169:0]	parserRuleSet;//input Next state; typeLocation; HeadVectorLocation; fieldLocation; ruleNum
						//[169:168]: operationCode 2'd0:read; 2'd1:add; 2'd2:del;
						//[167:128] key:type+state ;
						//[117:120]: nextState;	[119:104]:typeLocation,+ 8bit typeMask;	[103:8]fieldLocations;	[7:0]ruleNum

input	result_valid;
input	[119:0]	result;
output	reg	lookupRuleSet_valid;
output	reg	[63:0]	lookupRuleSet;

reg	[31:0]	localbus_addr;
reg	[119:0]	result_temp;

reg	[3:0]	state;
parameter	idle		= 4'd0,
			read_rule	= 4'd1,
			write_rule	= 4'd2,
			wait_back	= 4'd3;

always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		localbus_ack_n <= 1'b1;
		localbus_data_out <= 32'b0;
		state <= idle;
		parserRuleSet_valid <= 1'b0;
		parserRuleSet <= 170'b0;
		lookupRuleSet_valid <= 1'b0;
		lookupRuleSet <= 64'b0;
		localbus_addr <= 32'b0;
	end
	else begin
		case(state)
			idle: begin
				if(localbus_ale==1'b1) begin
					localbus_addr <= localbus_data;
					if(localbus_rd_wr==1'b1) begin
						state <= read_rule;
					end
					else begin
						state <= write_rule;
					end
				end
				else state <= idle;
			end
			read_rule: begin
				if(localbus_cs_n==1'b0) begin
					localbus_ack_n <= 1'b0;
					state <= wait_back;
					case(localbus_addr[1:0])
						2'd0: localbus_data_out <= {8'b0,result_temp[119:96]};
						2'd1: localbus_data_out <= result_temp[95:64];
						2'd2: localbus_data_out <= result_temp[63:32];
						2'd3: localbus_data_out <= result_temp[31:0];
						default: localbus_data_out <= 32'b0;
					endcase
				end
				else state <= read_rule;
			end
			write_rule: begin
				if(localbus_cs_n==1'b0) begin
					localbus_ack_n <= 1'b0;
					state <= wait_back;
					case(localbus_addr[2:0])
						3'd0: parserRuleSet[169:160] <= localbus_data[9:0];
						3'd1: parserRuleSet[159:128] <= localbus_data;
						3'd2: parserRuleSet[127:96] <= localbus_data;
						3'd3: parserRuleSet[95:64] <= localbus_data;
						3'd4: parserRuleSet[63:32] <= localbus_data;
						3'd5: begin 
							parserRuleSet[31:0] <= localbus_data;
							parserRuleSet_valid <= 1'b1;
						end
						3'd6: lookupRuleSet[63:32]	<= localbus_data;
						3'd7: begin 
							lookupRuleSet[31:0]	<= localbus_data;
							lookupRuleSet_valid <= 1'b1;
						end
						default: begin
						end
					endcase
				end
				else state <= write_rule;
			end
			wait_back: begin
				parserRuleSet_valid <= 1'b0;
				lookupRuleSet_valid <= 1'b0;
				if(localbus_cs_n==1'b1) begin
					state <= idle;
					localbus_ack_n <= 1'b1;
				end
				else state <= wait_back;
			end
			default: state <= idle;
		endcase
	end
end

//result_temp;
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		result_temp <= 120'b0;
	end
	else begin
		if(result_valid==1'b1) result_temp <= result;
		else result_temp <= result_temp;
	end	
end


endmodule