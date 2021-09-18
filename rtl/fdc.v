////////////////////////////////////////////////////////////////////////////////
// Project Name:	COCO3 Targeting MISTer 
// File Name:		fdc.v
//
// Floppy Disk Controller for MISTer
//
////////////////////////////////////////////////////////////////////////////////
//
// Code based partily on work by Gary Becker
// Copyright (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
//
// Floopy Disk Controller by Stan Hodge (stan.pda@gmail.com)
// Copyright (c) 2021 by Stan Hodge (stan.pda@gmail.com)
//
// All rights reserved

// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



module fdc(
	input        		CLK,     		// clock
	input        		RESET_N,	   	// async reset
	input        		HDD_EN,
	input				RW_N,
	input				PH_2,			// Processor sync'd enable
	input  		[3:0]	ADDRESS,       	// i/o port addr [extended for coco]
	input  		[7:0]	DATA_IN,        // data in
	output 		[7:0] 	DATA_HDD,      	// data out
	output       		HALT,         	// DMA request
	output       		NMI_09,

// 	SD block level interface

	input 		[3:0]	img_mounted, 	// signaling that new image has been mounted
	input				img_readonly, 	// mounted as read only. valid only for active bit in img_mounted
	input 		[19:0] 	img_size,    	// size of image in bytes. 1MB MAX!

	output		[31:0] 	sd_lba[4],
	output		[5:0]	sd_blk_cnt[4],	// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!
	output reg	[3:0]	sd_rd,
	output reg  [3:0]	sd_wr,
	input       [3:0]	sd_ack,

// 	SD byte level access. Signals for 2-PORT altsyncram.
	input  		[8:0]	sd_buff_addr,
	input  		[7:0] 	sd_buff_dout,
	output 		[7:0] 	sd_buff_din[4],
	input        		sd_buff_wr,
	
	output		[7:0]	probe
);


wire	[7:0]	DRIVE_SEL_EXT;
wire			MOTOR;
wire			WRT_PREC;
wire			DENSITY;
wire			HALT_EN;

// Diagnostics only
assign probe = {sd_ack, WR[0], RD[0], NMI_09, HALT};

// Generate a 1 Mhz enable for the fdc... and control writes
wire ena_1Mhz;
wire [5:0]	div_1mhz;

assign ena_1Mhz = (div_1mhz == 6'd5) ? 1'b1: 1'b0;

always@(negedge CLK or negedge RESET_N)
begin
	if (~RESET_N)	div_1mhz <= 6'd0;
	else
		begin
			if (ena_1Mhz)
				div_1mhz <= 6'd0;
			else
				div_1mhz <= div_1mhz + 6'd1;
		end
end

//FDC read data path.  =$ff40 or wd1793(s)
assign	DATA_HDD =		({HDD_EN, ADDRESS[3:0]} == 5'h10)	?	{HALT_EN, 
																DRIVE_SEL_EXT[3],
																DENSITY, 
																WRT_PREC, 
																MOTOR, 
																DRIVE_SEL_EXT[2:0]}:
						(CE == 1'b1)						?	DATA_1793: //(1793[s])
																8'h00;

// $ff40 control register [part 1]
always @(negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		DRIVE_SEL_EXT <= 8'h00;
		MOTOR <= 1'b0;
		WRT_PREC <= 1'b0;
		DENSITY <= 1'b0;
	end
	else
	begin
		if (PH_2)
		begin
			case ({RW_N, HDD_EN, ADDRESS[3:0]})
			6'b010000:
			begin
				DRIVE_SEL_EXT <= 	{4'b0000,
									DATA_IN[6],		// Drive Select [3] / Side Select
									DATA_IN[2:0]};	// Drive Select [2:0]
				MOTOR <= DATA_IN[3];				// Turn on motor, not used here just checked, 0=MotorOff 1=MotorOn
				WRT_PREC <= DATA_IN[4];				// Write Precompensation, not used here
				DENSITY <= DATA_IN[5];				// Density, not used here just checked
			end
			endcase
		end
	end
end

// $ff40 control register [part 2]
always @(negedge CLK or negedge HALT_EN_RST)
begin
	if(!HALT_EN_RST)
	begin
		HALT_EN <= 1'b0;
	end
	else
	begin
		if (PH_2)
		begin
			case ({RW_N, HDD_EN, ADDRESS[3:0]})
			6'b010000:
			begin
				HALT_EN <= DATA_IN[7];					// Normal Halt enable, 0=Disabled 1=Enabled
			end
			endcase
		end
	end
end

// SD blk system is a array of 4 systems - one for each drive.  
// To keep disk track memory, we created 4 wd1793's to match the sd block interfaces
// For the interface back to the coco - we need to isolate the wd1793 the computer is talking
// to and route those feedback signals back to the coco.  This is accomplished via the drive
// select.  'drive_index' identifies which controller is addressd.


wire	[2:0]	drive_index;

assign 	drive_index = 	(DRIVE_SEL_EXT[3:0] == 4'b1000)	?	3'd3: 
						(DRIVE_SEL_EXT[3:0] == 4'b0100)	?	3'd2:
						(DRIVE_SEL_EXT[3:0] == 4'b0010)	?	3'd1:
						(DRIVE_SEL_EXT[3:0] == 4'b0001)	?	3'd0:
						(DRIVE_SEL_EXT[3:0] == 4'b1100)	?	3'd2: // Side select and drive 2 = drive 2
						(DRIVE_SEL_EXT[3:0] == 4'b1010)	?	3'd1: // Side select and drive 1 = drive 1
						(DRIVE_SEL_EXT[3:0] == 4'b1001)	?	3'd0: // Side select and drive 0 = drive 0
															3'd4;

// Control signals for the wd1793

wire 			INTRQ[4];
wire			DRQ[4];
wire			selected_DRQ;
wire			selected_INTRQ;

wire			WR[4];
wire			RD[4];
wire			RD_E[4];
wire			CE;
wire			HALT_EN_RST;
wire	[7:0]	DATA_1793;
wire	[7:0]	dout[4];
wire			read;
wire			write;
reg 			read_d;
reg				write_d;
reg		[7:0]	DATA_IN_L;
reg				r_w_active;
reg				clk_1Mhz_enable_found;
reg				second_clk_1Mhz_enable_found;

assign CE = (HDD_EN && ADDRESS[3]);

//assign WR[0] = (~RW_N && CE) && (drive_index == 3'd0);
//assign WR[1] = (~RW_N && CE) && (drive_index == 3'd1);
//assign WR[2] = (~RW_N && CE) && (drive_index == 3'd2);
//assign WR[3] = (~RW_N && CE) && (drive_index == 3'd3);

assign RD[0] = ((RW_N && CE) || RD_E[0])  && (drive_index == 3'd0);
assign RD[1] = ((RW_N && CE) || RD_E[1])  && (drive_index == 3'd1);
assign RD[2] = ((RW_N && CE) || RD_E[2])  && (drive_index == 3'd2);
assign RD[3] = ((RW_N && CE) || RD_E[3])  && (drive_index == 3'd3);

assign read = (RW_N && CE);
assign write = (~RW_N && CE);

// The idea here is to "stretch" the CPU read and write signals to ensure we catch a 1 mhz enable.
// For writes we will buffer the data out to ensure it does not go away.
// For reads it is expected that data is available asynchronusly at the cpu rate and the only reason to catch a 
// 1Mhz edge is to update pointer and misc flags. 

always @(negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		read_d <= 1'b0;
		write_d <= 1'b0;
		r_w_active <= 1'b0;
		clk_1Mhz_enable_found <= 1'b0;
		second_clk_1Mhz_enable_found <= 1'b0;
		WR[0] <= 1'b0;
		WR[1] <= 1'b0;
		WR[2] <= 1'b0;
		WR[3] <= 1'b0;
		RD_E[0] <= 1'b0;
		RD_E[1] <= 1'b0;
		RD_E[2] <= 1'b0;
		RD_E[3] <= 1'b0;
	end
	else
	begin
		read_d <= read;
		write_d <= write;
		
//		Synchronus rising edge of write
		if ((write == 1'b1) && (write_d == 1'b0))
		begin
//			Latch Data
			DATA_IN_L <= DATA_IN;
//			Set Writes
			r_w_active <= 1'b1;
			case (drive_index)
				3'd0:
					WR[0] <= 1'b1;
				3'd1:
					WR[1] <= 1'b1;
				3'd2:
					WR[2] <= 1'b1;
				3'd3:
					WR[3] <= 1'b1;
			endcase
		end

//		Synchronus rising edge of read
		if ((read == 1'b1) && (read_d == 1'b0))
		begin
			r_w_active <= 1'b1;
			case (drive_index)
				3'd0:
					RD_E[0] <= 1'b1;
				3'd1:
					RD_E[1] <= 1'b1;
				3'd2:
					RD_E[2] <= 1'b1;
				3'd3:
					RD_E[3] <= 1'b1;
			endcase
		end

//		Clears
		if (ena_1Mhz && r_w_active)
			clk_1Mhz_enable_found <= 1'b1;

		if (ena_1Mhz && clk_1Mhz_enable_found)
			second_clk_1Mhz_enable_found <= 1'b1;

//		1 50Mhz clock later...
		if (second_clk_1Mhz_enable_found)
		begin
			clk_1Mhz_enable_found <= 1'b0;
			second_clk_1Mhz_enable_found <= 1'b0;
			r_w_active <= 1'b0;
			
			WR[0] <= 1'b0;
			WR[1] <= 1'b0;
			WR[2] <= 1'b0;
			WR[3] <= 1'b0;

			RD_E[0] <= 1'b0;
			RD_E[1] <= 1'b0;
			RD_E[2] <= 1'b0;
			RD_E[3] <= 1'b0;
		end
	end
end


//	NMI from disk controller
//	Selected INTRQ
assign	selected_INTRQ	=	(drive_index == 3'd0)	?	INTRQ[0]:
							(drive_index == 3'd1)	?	INTRQ[1]:
							(drive_index == 3'd2)	?	INTRQ[2]:
							(drive_index == 3'd3)	?	INTRQ[3]:
														1'b0;

assign	NMI_09	=	DENSITY & selected_INTRQ;				// Send NMI if Double Density (Halt Mode)

//	HALT from disk controller
//	Selected DRQ
assign	selected_DRQ	=	(drive_index == 3'd0)	?	DRQ[0]:
							(drive_index == 3'd1)	?	DRQ[1]:
							(drive_index == 3'd2)	?	DRQ[2]:
							(drive_index == 3'd3)	?	DRQ[3]:
														1'b1;

assign	HALT	=	HALT_EN & ~selected_DRQ;

assign	HALT_EN_RST = RESET_N & ~selected_INTRQ; // From controller schematic

// Data bus selection
assign	DATA_1793 	=		(drive_index == 3'd0)	?	dout[0]:
							(drive_index == 3'd1)	?	dout[1]:
							(drive_index == 3'd2)	?	dout[2]:
							(drive_index == 3'd3)	?	dout[3]:
														8'd0;

// The SD_BLK interface and thus the wd1793 will allways transfer 1 blk. This is blk qty - 1 per spec.
assign sd_blk_cnt[3] = 6'd0;
assign sd_blk_cnt[2] = 6'd0;
assign sd_blk_cnt[1] = 6'd0;
assign sd_blk_cnt[0] = 6'd0;

reg				drive_wp[4];
reg				drive_ready[4];

// As drives are mounted in MISTer this logic saves the write protect and generates ready for
// changing drives to the wd1793.
// This can also get the disk size to properly handle DS drives - TBD

// Drive 0

always @(negedge img_mounted[0] or negedge RESET_N)
begin
	if (~RESET_N)
	begin
		drive_wp[0] <= 1'b1;
		drive_ready[0] <= 1'b0;
	end
	else
		begin
			drive_wp[0] <= img_readonly;
			drive_ready[0] <= 1'b1;
		end
end

// Drive 1

always @(negedge img_mounted[1] or negedge RESET_N)
begin
	if (~RESET_N)
	begin
		drive_wp[1] <= 1'b1;
		drive_ready[1] <= 1'b0;
	end
	else
		begin
			drive_wp[1] <= img_readonly;
			drive_ready[1] <= 1'b1;
		end
end

// Drive 2

always @(negedge img_mounted[2] or negedge RESET_N)
begin
	if (~RESET_N)
	begin
		drive_wp[2] <= 1'b1;
		drive_ready[2] <= 1'b0;
	end
	else
		begin
			drive_wp[2] <= img_readonly;
			drive_ready[2] <= 1'b1;
		end
end

// Drive 3

always @(negedge img_mounted[3] or negedge RESET_N)
begin
	if (~RESET_N)
	begin
		drive_wp[3] <= 1'b1;
		drive_ready[3] <= 1'b0;
	end
	else
		begin
			drive_wp[3] <= img_readonly;
			drive_ready[3] <= 1'b1;
		end
end



wd1793 #(1,1) coco_wd1793_0
(
	.clk_sys(~CLK),
	.ce(ena_1Mhz),
	.reset(~RESET_N),
	.io_en(1'b1),
	.rd(RD[0]),
	.wr(WR[0]),
	.addr(ADDRESS[1:0]),
//	.din(DATA_IN),
	.din(DATA_IN_L),
	.dout(dout[0]),
	.drq(DRQ[0]),
	.intrq(INTRQ[0]),

	.img_mounted(img_mounted[0]),
	.img_size(img_size),

	.sd_lba(sd_lba[0]),
	.sd_rd(sd_rd[0]),
	.sd_wr(sd_wr[0]), 
	.sd_ack(sd_ack[0]),

	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din[0]), 
	.sd_buff_wr(sd_buff_wr),

	.wp(drive_wp[0]),

	.size_code(3'd5),		// 5 is 18 sector x 256 bits COCO standard
	.layout(1'b1),			// 0 = Track-Side-Sector, 1 - Side-Track-Sector
	.side(1'b0),			// Not support DS yet.
	.ready(drive_ready[0]),

	.input_active(0),
	.input_addr(0),
	.input_data(0),
	.input_wr(0),
	.buff_din(0)
);

wd1793 #(1,0) coco_wd1793_1
(
	.clk_sys(~CLK),
	.ce(ena_1Mhz),
	.reset(~RESET_N),
	.io_en(1'b1),
	.rd(RD[1]),
	.wr(WR[1]),
	.addr(ADDRESS[1:0]),
//	.din(DATA_IN),
	.din(DATA_IN_L),
	.dout(dout[1]),
	.drq(DRQ[1]),
	.intrq(INTRQ[1]),

	.img_mounted(img_mounted[1]),
	.img_size(img_size),

	.sd_lba(sd_lba[1]),
	.sd_rd(sd_rd[1]),
	.sd_wr(sd_wr[1]), 
	.sd_ack(sd_ack[1]),

	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din[1]), 
	.sd_buff_wr(sd_buff_wr),

	.wp(drive_wp[1]),

	.size_code(3'd5),		// 5 is 18 sector x 256 bits COCO standard
	.layout(1'b1),			// 0 = Track-Side-Sector, 1 - Side-Track-Sector
	.side(1'b0),			// Not support DS yet.
	.ready(drive_ready[1]),

	.input_active(0),
	.input_addr(0),
	.input_data(0),
	.input_wr(0),
	.buff_din(0)
);

wd1793 #(1,0) coco_wd1793_2
(
	.clk_sys(~CLK),
	.ce(ena_1Mhz),
	.reset(~RESET_N),
	.io_en(1'b1),
	.rd(RD[2]),
	.wr(WR[2]),
	.addr(ADDRESS[1:0]),
//	.din(DATA_IN),
	.din(DATA_IN_L),
	.dout(dout[2]),
	.drq(DRQ[2]),
	.intrq(INTRQ[2]),

	.img_mounted(img_mounted[2]),
	.img_size(img_size),

	.sd_lba(sd_lba[2]),
	.sd_rd(sd_rd[2]),
	.sd_wr(sd_wr[2]), 
	.sd_ack(sd_ack[2]),

	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din[2]), 
	.sd_buff_wr(sd_buff_wr),

	.wp(drive_wp[2]),

	.size_code(3'd5),		// 5 is 18 sector x 256 bits COCO standard
	.layout(1'b1),			// 0 = Track-Side-Sector, 1 - Side-Track-Sector
	.side(1'b0),			// Not support DS yet.
	.ready(drive_ready[2]),

	.input_active(0),
	.input_addr(0),
	.input_data(0),
	.input_wr(0),
	.buff_din(0)
);

wd1793 #(1,0) coco_wd1793_3
(
	.clk_sys(~CLK),
	.ce(ena_1Mhz),
	.reset(~RESET_N),
	.io_en(1'b1),
	.rd(RD[3]),
	.wr(WR[3]),
	.addr(ADDRESS[1:0]),
//	.din(DATA_IN),
	.din(DATA_IN_L),
	.dout(dout[3]),
	.drq(DRQ[3]),
	.intrq(INTRQ[3]),

	.img_mounted(img_mounted[3]),
	.img_size(img_size),

	.sd_lba(sd_lba[3]),
	.sd_rd(sd_rd[3]),
	.sd_wr(sd_wr[3]), 
	.sd_ack(sd_ack[3]),

	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din[3]), 
	.sd_buff_wr(sd_buff_wr),

	.wp(drive_wp[3]),

	.size_code(3'd5),		// 5 is 18 sector x 256 bits COCO standard
	.layout(1'b1),			// 0 = Track-Side-Sector, 1 - Side-Track-Sector
	.side(1'b0),			// Not support DS yet.
	.ready(drive_ready[3]),

	.input_active(0),
	.input_addr(0),
	.input_data(0),
	.input_wr(0),
	.buff_din(0)
);

endmodule
