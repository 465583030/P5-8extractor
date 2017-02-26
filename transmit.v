
module transmit(
clk,
reset,
action_valid,
action,
pktIDout_valid,
pktIDout,
um2cdp_rule_wrreq,
um2cdp_rule,
cdp2um_tx_enable,
writeRule_enable
);

input	clk;
input	reset;
input	action_valid;
input	[31:0]	action;
output	reg	pktIDout_valid;
output	reg	[11:0]	pktIDout;	// [11:8] action_ins; [8]: '1' is discard;
output	reg	um2cdp_rule_wrreq;
output	reg	[29:0]	um2cdp_rule;
input			cdp2um_tx_enable;
input	writeRule_enable;

reg	[3:0]	state;
parameter	idle 			= 4'd0,
			read_fifo		= 4'd1,
			wait_trans_1	= 4'd2,
			wait_bubble_1	= 4'd3,
			wait_bubble_2	= 4'd4,
			wait_bubble_3	= 4'd5,
			wait_trans_2	= 4'd6,
			wait_bubble_1_b	= 4'd7,
			wait_bubble_2_b	= 4'd8,
			wait_bubble_3_b	= 4'd9,
			wait_write_rule	= 4'd10;

reg	rdreq_action;
wire	empty_action;
wire	[31:0]	q_action;

reg	[7:0]	pktID_temp;
reg	[3:0]	rule_temp;			
			
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		pktIDout_valid <= 1'b0;
		pktIDout <= 12'b0;
		um2cdp_rule_wrreq <= 1'b0;
		um2cdp_rule <= 30'b0;
		state <= idle;
		rdreq_action <= 1'b0;
	end
	else begin
		case(state)
			idle: begin
				pktIDout_valid <= 1'b0;
				if((writeRule_enable== 1'b1) && (empty_action == 1'b0)) begin
					state <= read_fifo;
					rdreq_action <= 1'b1;
				end
				else state <= idle;
			end
			read_fifo: begin
				rdreq_action <= 1'b0;
				if((q_action[3:0]==4'd0)||(q_action[19:16]==4'd1)) begin
					state <= idle;
					pktIDout_valid<=1'b1;
					pktIDout <= {4'd1,q_action[31:24]};
				end
				else begin
					pktID_temp <= q_action[31:24];
					um2cdp_rule_wrreq <= 1'b1;
					if(q_action[3:0]==4'hf) begin
						rule_temp <= 4'd2;
						um2cdp_rule <= {26'b0, 4'd1};
						state <= wait_trans_2;
					end
					else begin
						um2cdp_rule <= {26'b0,q_action[3:0]};
						state <= wait_trans_1;
					end					
				end
			end
			wait_trans_1: begin
				um2cdp_rule_wrreq <= 1'b0;
				if(cdp2um_tx_enable==1'b1) begin
					pktIDout_valid <= 1'b1;
					pktIDout <= {4'd0,pktID_temp};
					state <= wait_bubble_1;
				end
				else state <= wait_trans_1;
			end
			wait_bubble_1: begin 
				pktIDout_valid <= 1'b0;	
				state <= wait_bubble_2;
			end
			wait_bubble_2: state <= wait_bubble_3;
			wait_bubble_3: state <= idle;
			
			wait_trans_2: begin
				um2cdp_rule_wrreq <= 1'b0;
				if(rule_temp== 4'd0) begin
					if(cdp2um_tx_enable==1'b1) begin
						pktIDout_valid <= 1'b1;
						pktIDout <= {4'd0,pktID_temp};
						state <= wait_bubble_1;
					end
					else state <= wait_trans_2;
				end
				else begin
					if(cdp2um_tx_enable==1'b1) begin
						pktIDout_valid <= 1'b1;
						pktIDout <= {4'd2,pktID_temp};
						state <= wait_bubble_1_b;
					end
					else state <= wait_trans_2;
				end
			end
			wait_bubble_1_b: begin 
				pktIDout_valid <= 1'b0;	
				state <= wait_bubble_2_b;
			end
			wait_bubble_2_b: state <= wait_bubble_3_b;
			wait_bubble_3_b: state <= wait_write_rule;
			wait_write_rule: begin
				pktIDout_valid <= 1'b0;				
				if((writeRule_enable== 1'b1) && (empty_action == 1'b0)) begin
					state <= wait_trans_2;
					rule_temp <= rule_temp << 2'd1;
					um2cdp_rule_wrreq <= 1'b1;
					um2cdp_rule <= {26'b0,rule_temp};
				end
				else state <= wait_write_rule;
			end
			default: state <= idle;
		endcase
	end
end	

fifo fifo_action(
.aclr(!reset),
.clock(clk),
.data(action),
.rdreq(rdreq_action),
.wrreq(action_valid),
.empty(empty_action),
.full(),
.q(q_action),
.usedw()
);	
defparam
    fifo_action.width = 32,
    fifo_action.depth = 4,
    fifo_action.words = 16;






endmodule