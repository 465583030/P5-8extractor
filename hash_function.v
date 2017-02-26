module hash_function(
clk,
reset,
key_valid,
key,
hash_value_valid,
hash_1,
hash_2,
hash_3
);

input	clk;
input	reset;
input	key_valid;
input	[39:0] key;
output	reg	hash_value_valid;
output	reg	[8:0]	hash_1;
output	reg	[8:0]	hash_2;
output	reg	[8:0]	hash_3;

reg		state;

always @ (posedge clk or negedge reset) begin
	if(!reset) begin
		hash_value_valid <= 1'b0;
		hash_1 <= 9'd0;
		hash_2 <= 9'd0;
		hash_3 <= 9'd0;
		state <= 1'b0;
	end
	else begin
		case(state)
			1'b0: begin
				if(key_valid == 1'b1) begin
					hash_value_valid <= 1'b1;
					hash_1 <= {1'b0,key[39:35],key[2:0]};
					hash_2 <= {1'b0,key[39:35],key[2:0]};
					hash_3 <= {1'b0,key[39:35],key[2:0]};
					state <= 1'b1;
				end
				else hash_value_valid <= 1'b0;
			end
			1'b1: begin
				hash_value_valid <= 1'b1;
				hash_1 <= {1'b1,key[39:35],key[2:0]};
				hash_2 <= {1'b1,key[34:30],key[2:0]};
				hash_3 <= {1'b1,key[34:30],key[2:0]};
				state <= 1'b0;
			end
		endcase
	end
end


endmodule
