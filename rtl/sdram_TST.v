

module sdram_TST(
	input        		CLK,     		// clock
	input        		RESET_N,	   	// async reset

	input	[7:0]		count,
	input				read_write,		//read=1
	input				start,
	input				start_edge,
	input				rd_buf_mode,	// 0= 32 bit capture , 1= 2 16 bit capture
	input	[2:0]		rd_inc,
	
	output	[7:0]		sum,
	output	[31:0]		sdram_rd_buf,	// 32 bit caputure
	
//	SDRAM

	output	[24:0]		sdram_addr,
	input	[31:0]		sdram_ldout,
	input	[15:0]		sdram_dout,
	output	[7:0]		sdram_din,
	output				sdram_req,
	output				sdram_rnw,
	
	input				sdram_ready
);


wire	[2:0]	state;
wire	[7:0]	cycles;

wire	[15:0]	pattern1 = 16'haaaa;
wire	[15:0]	pattern2 = 16'h5555;

wire	[15:0]	pattern;
wire  start_edge_d;
wire  we_save;
wire  second_chunk;
wire  third_chunk;

// Write pattern
assign pattern = (cycles[0] == 1'b0) ? pattern1: pattern2;

always@(posedge CLK or negedge RESET_N)
begin
	if (~RESET_N)
	begin
		start_edge_d <= 1'b0;
		state <= 3'd0;
		cycles <= 8'd0;
		sum <= 8'd0;
		sdram_req <= 1'b0;
		sdram_rnw <= 1'b1; // read
		sdram_addr <= 25'h0000000;
		we_save <= 1'b0;
		second_chunk <= 1'b0;
		third_chunk <= 1'b0;
	end
	else
	begin
		start_edge_d <= start_edge;

		if (second_chunk)
		begin
			sdram_rd_buf[31:16] <= sdram_dout;
			sum <= sum + sdram_dout[7:0] + sdram_dout[15:8];
			second_chunk <= 1'b0;
			third_chunk <= 1'b1;
		end

		if (third_chunk)
		begin
			sdram_rd_buf <= sdram_ldout;
			third_chunk <= 1'b0;
		end

		case (state)
			3'd0:
			begin
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
				begin
					sdram_req <= 1'b1;
					sdram_rnw <= 1'b1; // read
				end
				else
				begin
					sdram_req <= 1'b1;
					sdram_rnw <= 1'b0; // write
					sdram_din <= cycles+ 5'h10;
					we_save <= 1'b1;
				end
				cycles <= cycles + 1'b1;
				state <= 3'd2;
			end
			3'd2:
			begin
				if (sdram_ready == 1'b0)
				begin
					sdram_req <= 1'b0;
					state <= 3'd3;
				end
			end
			3'd3:
			begin
				if (sdram_ready)
				begin
					sdram_rd_buf[15:0] <= sdram_dout;
					sum <= sum + sdram_dout[7:0] + sdram_dout[15:8];
					second_chunk <= 1'b1;
					if (we_save)
						sdram_addr <= sdram_addr + 2'b01;
					else
						sdram_addr <= sdram_addr + rd_inc;
				
					we_save <= 1'b0;
					if (cycles == count)
						state <= 3'd0;
					else
						state <= 3'd1;
				end
			end
		endcase
	end
end

endmodule
