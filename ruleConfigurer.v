//	Module name: parser->ruleConfigurer
//	Authority @ lijunnan
//	Last edited time: 2017/02/15
//	Function outline: programmable parser
//

module ruleConfigurer(
clk,
reset,
ruleSet_valid,
ruleSet,
ruleSetTCAM_valid,
ruleSetTCAM,
ruleSetActionRAM_valid,
ruleSetActionRAM
);
input	clk;
input	reset;
input	ruleSet_valid;
input	[169:0]	ruleSet;//input Next state; typeLocation; HeadVectorLocation; fieldLocation; ruleNum
				//[161:160]: operationCode 2'd0:read; 2'd1:add; 2'd2:del;
				//[159:120] key:type+state;
				//[119:112]: nextState;	[111:104]:typeLocation;	[103:8]fieldLocations;	[7:0]ruleNum
output	reg	ruleSetTCAM_valid;
output	reg	[49:0]	ruleSetTCAM;// [49:48] operationCode 2'd0:read; 2'd1:add; 2'd2:del;
								// 	[47:8] key:type+state;
								//	[7:0] ruleNUM;
output	reg	ruleSetActionRAM_valid;
output	reg	[129:0]	ruleSetActionRAM;	// 	[129:128]: operationCode 2'd0:read; 2'd1:add; 2'd2:del;
										//	[127:120]: nextState;	[119:112]:typeLocation; [111:104] typeMask;
										//	[103:8]fieldLocations;	
										//	[7:0]ruleNum

always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		ruleSetActionRAM_valid <= 1'b0;
		ruleSetActionRAM <= 130'b0;
		ruleSetTCAM_valid <= 1'b0;
		ruleSetTCAM <= 50'b0;
	end
	else begin
		if(ruleSet_valid==1'b1) begin
			case(ruleSet[169:168])
				2'd0: begin
					ruleSetActionRAM_valid <= 1'b1;
					ruleSetActionRAM <= {2'd0,120'b0,ruleSet[7:0]};
					ruleSetTCAM_valid <= 1'b0;
				end
				2'd1: begin
					ruleSetActionRAM_valid <= 1'b1;
					ruleSetActionRAM <= {2'd1,ruleSet[127:0]};
					ruleSetTCAM_valid <= 1'b1;
					ruleSetTCAM <= {2'd1,ruleSet[167:128],ruleSet[7:0]};
				end
				2'd2: begin
					ruleSetActionRAM_valid <= 1'b0;
					ruleSetTCAM_valid <= 1'b1;
					ruleSetTCAM <= {2'd2,ruleSet[167:128],ruleSet[7:0]};
				end
				default: begin 
				end
			endcase
		end
		else begin
			ruleSetActionRAM_valid <= 1'b0;
			ruleSetTCAM_valid <= 1'b0;
		end
	end
end										
										


endmodule
