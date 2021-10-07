

module sdram_TST(
	input        		CLK,     		// clock
	input        		RESET_N,	   	// async reset

	input	[7:0]		count,
	input				read_write,		//read=1
	input				start,
	input				start_edge,
	
	output	[7:0]		sum,
	
//	SDRAM

	output	[24:0]		sdram_addr,
	output	[1:0]		sdram_wtbt,
	input	[15:0]		sdram_data_o,
	output	[15:0]		sdram_data_i,
	output				sdram_rd,
	output				sdram_we,
	input				sdram_ready
	
);


wire	[2:0]	state;
wire	[7:0]	cycles;

wire	[15:0]	pattern1 = 16'haaaa;
wire	[15:0]	pattern2 = 16'h5555;

wire	[15:0]	pattern;
wire  start_edge_d;

// Write pattern
assign pattern = (cycles[0] == 1'b0) ? pattern1: pattern2;

always@(negedge CLK or negedge RESET_N)
begin
	if (~RESET_N)
	begin
		start_edge_d <= 1'b0;
		state <= 3'd0;
		cycles <= 8'd0;
		sum <= 8'd0;
		sdram_rd <= 1'b0;
		sdram_we <= 1'b0;
		sdram_wtbt <= 2'b00;
		sdram_addr <= 25'h0000000;
	end
	else
	begin
		start_edge_d <= start_edge;
		case (state)
			3'd0:
			begin
				sdram_addr <= 25'h0000000;
				cycles <= 8'd0;
				sum <= 8'd0;
				if (start | (start_edge && ~start_edge_d))
				begin
					sdram_addr <= 25'h0000000;
					cycles <= 8'd0;
					sum <= 8'd0;
					state <= 3'd1;
				end
			end
			3'd1:
			begin
				if (read_write)
					sdram_rd <= 1'b1;
				else
				begin
					sdram_we <= 1'b1;
					sdram_data_i <= pattern;
				end
				cycles <= cycles + 1'b1;
				state <= 3'd2;
			end
			3'd2:
				if (sdram_ready)
				begin
					sdram_rd <= 1'b0;
					sdram_we <= 1'b0;

					sum <= sum + sdram_data_o[7:0];
					sdram_addr <= sdram_addr + 1'b1;
					if (cycles == count)
						state <= 3'd0;
					else
						state <= 3'd1;
				end
		endcase
	end
end

endmodule
