
`timescale 1ns/1ps


module lookup_bit(
clk,
reset,
key_valid,
key,
bv_valid,
bv,
set_valid,
set

);

input           clk;
input           reset;
input	key_valid;
input	[7:0]	key;
output	reg	bv_valid;
output	reg	[63:0]	bv;
input	set_valid;
input	[16:0]	set;	//[16]: '1' is add; '0'; is del;
						//[15:8]: subKey;
						//[7:0]: ruleNum;



//----ram---//a:lookup;       b:set;
reg	[7:0]	addr_b;	
reg	[64:0]	data_b;
reg	rden_b,wren_b;
wire[64:0]	q_a,q_b;

reg	[7:0]	rule_id;

reg	[15:0]	temp_shift;
reg	[255:0]	q_temp;
reg	[255:0]	data_temp;

reg	[3:0]	state;
reg	[16:0]	set_temp;
parameter	idle	= 4'd0,
			wait_1	= 4'd1,
			wait_2	= 4'd2,
			read_ram= 4'd3,
			write_ram=4'd4;



				
reg	key_valid_temp[1:0];
//key_valid manage;
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		key_valid_temp[0] <= 1'b0;
		key_valid_temp[1] <= 1'b0;		
	end
	else begin
		key_valid_temp[0] <= key_valid;
		key_valid_temp[1] <= key_valid_temp[0];
	end
end
//wait_1--> key_valid			
//wait_2--> key_valid_temp[0] valid
//bv_out--> key_valid_temp[1] valid
				
always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		bv_valid <= 1'b0;
		bv <= 64'b0;
	end
	else begin
		if(key_valid_temp[1]==1'b1) begin
			bv_valid <= 1'b1;
			if(q_a[64]==1'b1) bv <= q_a[63:0];
			else bv <= 64'b0;
		end
		else begin
			bv_valid <= 1'b0;
		end
	end
end

reg	[63:0]	q_b_temp;
reg	[63:0]	data_and_temp;

//---update---//
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		rden_b <= 1'b0;
		wren_b <= 1'b0;
		data_b <= 65'b0;
		addr_b <= 8'b0;
		data_and_temp <= 64'b0;
		set_temp <= 17'b0;
	end
	else begin
		case(state)
			idle: begin
				wren_b <= 1'b0;
				if(set_valid == 1'b1) begin
					state <= wait_1;
					set_temp <= set;
					addr_b <= set[15:8];
					rden_b <= 1'b1;
				end
				else begin
					rden_b <= 1'b0;
					state <= idle;
				end
			end
			wait_1: begin
				if(set_temp[16]==1'b1) begin	//add
					data_and_temp <= 64'd1 << set_temp[5:0];
				end
				else begin	//del
					data_and_temp <= ~(64'd1 << set_temp[5:0]);
				end
				state <= wait_2;
				rden_b <= 1'b0;
			end
			wait_2: begin
				state <= read_ram;
			end
			read_ram: begin
				if(q_b[64]==1'b1) begin
					q_b_temp <= q_b[63:0];
				end
				else begin
					q_b_temp <= 64'b0;
				end
				state <= write_ram;
			end
			write_ram: begin
				wren_b <= 1'b1;
				addr_b <= set_temp[15:8];
				if(set_temp[16]==1'b1) data_b <= {1'b1,(q_b_temp|data_and_temp)};
				else data_b <= {1'b1,(q_b_temp&data_and_temp)};
				
				state <= idle;
			end
			default: state <= idle;
		endcase
	end
end




ram ram_65_256(
.address_a(key),
.address_b(addr_b),
.clock(clk),
.data_a(65'b0),
.data_b(data_b),
.rden_a(key_valid),
.rden_b(rden_b),
.wren_a(1'b0),
.wren_b(wren_b),
.q_a(q_a),
.q_b(q_b)

);
defparam
	ram_65_256.width 	= 65,
	ram_65_256.depth	= 8,
	ram_65_256.words	= 256;

		









endmodule


