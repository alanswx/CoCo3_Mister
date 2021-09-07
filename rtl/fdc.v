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
	input        		CLK_EN,        	// ce at CPU clock rate
	input        		RESET_N,	   	// async reset
	input        		HDD_EN,
	input				RW_N,
	input  		[3:0]	ADDRESS,       	// i/o port addr [extended for coco]
	input  		[7:0]	DATA_IN,        // data in
	output 		[7:0] 	DATA_HDD,      	// data out
	output       		HALT,         	// DMA request
	output       		NMI_09,
//	output       		busy,			// unused???

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
	input  		[7:0]	sd_buff_addr,
	input  		[7:0] 	sd_buff_dout,
	output 		[7:0] 	sd_buff_din[4],
	input        		sd_buff_wr
);

wire	[7:0]	DRIVE_SEL_EXT;
wire			MOTOR;
wire			WRT_PREC;
wire			DENSITY;
wire			HALT_EN;
wire 			INTRQ;
wire			DRQ;

wire			WR;
wire			RD;
wire			CE;
wire			HALT_EN_RST;
wire	[7:0]	DATA_1793;

assign	DATA_HDD =		({HDD_EN, ADDRESS[3:0]} == 5'h10)	?	{HALT_EN, 
																DRIVE_SEL_EXT[3],
																DENSITY, 
																WRT_PREC, 
																MOTOR, 
																DRIVE_SEL_EXT[2:0]}:
						(CE == 1'b1)						?	DATA_1793:
																8'h00;

assign WR = (~RW_N & CE);
assign RD = (RW_N & CE);
assign CE = (HDD_EN & ADDRESS[3]);


//	NMI from disk controller
assign	NMI_09	=	DENSITY & INTRQ;				// Send NMI if Double Density (Halt Mode)

//	HALT from disk controller
assign	HALT	=	HALT_EN & DRQ;

assign HALT_EN_RST = RESET_N & ~INTRQ; // From controller schematic

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
		if (CLK_EN)
		begin
			case ({RW_N, HDD_EN, ADDRESS[3:0]})
			6'b010000:
			begin
				DRIVE_SEL_EXT <= 	{4'b0000,
									DATA_IN[6],		// Drive Select [3] / Side Select
									DATA_IN[2:0]};		// Drive Select [2:0]
				MOTOR <= DATA_IN[3];					// Turn on motor, not used here just checked, 0=MotorOff 1=MotorOn
				WRT_PREC <= DATA_IN[4];				// Write Precompensation, not used here
				DENSITY <= DATA_IN[5];					// Density, not used here just checked
			end
			endcase
		end
	end
end

always @(negedge CLK or negedge HALT_EN_RST)
begin
	if(!HALT_EN_RST)
	begin
		HALT_EN <= 1'b0;
	end
	else
	begin
		if (CLK_EN)
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

wire	[2:0]	drive_index;
wire 	[7:0]	temp_sd_buf_din;
wire			temp_sd_rd;
wire			temp_sd_wr;
wire	[31:0]	temp_sd_lba;
wire			temp_img_mounted;
wire			temp_sd_ack;

assign 	drive_index = 	(DRIVE_SEL_EXT[3:0] == 4'b1000)	?	3'd3: 
						(DRIVE_SEL_EXT[3:0] == 4'b0100)	?	3'd2:
						(DRIVE_SEL_EXT[3:0] == 4'b0010)	?	3'd1:
															3'd0;
assign sd_buff_din[3] = temp_sd_buf_din;
assign sd_buff_din[2] = temp_sd_buf_din;
assign sd_buff_din[1] = temp_sd_buf_din;
assign sd_buff_din[0] = temp_sd_buf_din;

assign sd_blk_cnt[3] = 6'd0;
assign sd_blk_cnt[2] = 6'd0;
assign sd_blk_cnt[1] = 6'd0;
assign sd_blk_cnt[0] = 6'd0;

assign sd_rd = 			(drive_index == 3'd3)			?	{temp_sd_rd,3'b000}:
						(drive_index == 3'd2)			?	{1'b0,temp_sd_rd,2'b00}:
						(drive_index == 3'd1)			?	{2'b00,temp_sd_rd,1'b0}:
															{3'b000,temp_sd_rd};

assign sd_wr = 			(drive_index == 3'd3)			?	{temp_sd_wr,3'b000}:
						(drive_index == 3'd2)			?	{1'b0,temp_sd_wr,2'b00}:
						(drive_index == 3'd1)			?	{2'b00,temp_sd_wr,1'b0}:
															{3'b000,temp_sd_wr};

assign sd_lba[3]=		(drive_index == 3'd3)			?	temp_sd_lba:
															32'd0;

assign sd_lba[2]=		(drive_index == 3'd2)			?	temp_sd_lba:
															32'd0;

assign sd_lba[1]=		(drive_index == 3'd1)			?	temp_sd_lba:
															32'd0;

assign sd_lba[0]=		(drive_index == 3'd0)			?	temp_sd_lba:
															32'd0;

assign temp_img_mounted =	(drive_index == 3'd3)		?	img_mounted[3]:
							(drive_index == 3'd2)		?	img_mounted[2]:
							(drive_index == 3'd1)		?	img_mounted[1]:
															img_mounted[0];

assign temp_sd_ack =		(drive_index == 3'd3)		?	sd_ack[3]:
							(drive_index == 3'd2)		?	sd_ack[2]:
							(drive_index == 3'd1)		?	sd_ack[1]:
															sd_ack[0];

wd1793 #(1,0) coco_wd1793
(
	.clk_sys(CLK),
	.ce(CLK_EN),
	.reset(RESET_N),
	.io_en(CE),
	.rd(RD),
	.wr(WR),
	.addr(ADDRESS[1:0]),
	.din(DATA_IN),
	.dout(DATA_1793),
	.drq(DRQ),
	.intrq(INTRQ),

	.img_mounted(temp_img_mounted),
	.img_size(img_size),

	.sd_lba(temp_sd_lba),
	.sd_rd(temp_sd_rd),
	.sd_wr(temp_sd_wr), 
	.sd_ack(temp_sd_ack),

	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(temp_sd_buf_din), 
	.sd_buff_wr(sd_buff_wr),

	.wp(1'b0),

	.size_code(3'd5),		// 5 is 18 sector x 256 bits COCO standard
	.layout(1'b1),			// 0 = Track-Side-Sector, 1 - Side-Track-Sector
	.side(1'b0),			// Not support DS yet.
	.ready(1'b1),			// ?? [always?]

	.input_active(0),
	.input_addr(0),
	.input_data(0),
	.input_wr(0),
	.buff_din(0)
);

endmodule
