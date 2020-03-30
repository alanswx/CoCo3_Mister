////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 3.0
// File Name:		coco3fpga.v
//
// CoCo3 in an FPGA
//
// Revision: 3.0 08/15/15
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
// The FDC co-processor copyrighted Daniel Wallner.
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 4.1.2
//
// Copyright (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
//
// All rights reserved
//
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
// The latest version of this file can be found at:
//      http://groups.yahoo.com/group/CoCo3FPGA
//
// File history :
//
//  1.0			Full Release
//  2.0			Partial Release
//  3.0			Full Release
//  3.0.0.1		Update to fix DoD interrupt issue
//	3.0.1.0		Update to fix 32/40 CoCO3 Text issue and add 2 Meg max memory
//	4.1.2.X		Fixed 6502 code for drivewire, removed timer, fixed 6551 baud 
//				rate (& DE2-115 compiler symbol)
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// DE2-115 Conversion by Stan Hodge
// shodgefamily@yahoo.com
// Conversion is made via a defined symbol 'DE2_115'  Code of the original code
// base 4.1.2 is manipulated with `ifdef' and 'ifndef' compiler directives
////////////////////////////////////////////////////////////////////////////////

//	SRH
//	Un-comment for DE2-115
`define DE2_115
//

module coco3fpga_dw(
// Input Clocks
CLK50MHZ,
// SRH
`ifndef DE2_115
CLK24MHZ,
CLK24MHZ_2,
`endif
CLK27MHZ,
//SRH
`ifndef DE2_115
CLK27MHZ_2,
CLK3_57MHZ,
`endif
// RAM and ROM
RAM0_DATA,				// 16 bit data bus to RAM 0
RAM0_ADDRESS,
RAM0_RW_N,
RAM0_CS_N,				// Chip Select for RAM 0
RAM0_BE0_N,				// Byte Enable for RAM 0
RAM0_BE1_N,				// Byte Enable for RAM 0
RAM0_OE_N,

// SRH remove RAM1 in DE2-115 implementation
`ifndef DE2_115
RAM1_ADDRESS,
RAM1_ADDRESS9_1,
RAM1_ADDRESS10_1,
RAM1_DATA,
RAM1_BE0_N,
RAM1_BE1_N,
RAM1_BE2_N,
RAM1_BE3_N,
RAM1_CS0_N,
RAM1_CS1_N,
RAM1_RW0_N,
RAM1_RW1_N,
RAM1_OE0_N,
RAM1_OE1_N,
`endif

FLASH_ADDRESS,
FLASH_DATA,																																 
FLASH_WE_N,
FLASH_RESET_N,
FLASH_CE_N,
FLASH_OE_N,
`ifdef DE2_115
FLASH_WP_N,
FLASH_RY,
`endif
// SDRAM
SDRAM_ADDRESS,
SDRAM_BANK,
SDRAM_DATA,
SDRAM_LDQM,
SDRAM_UDQM,
`ifdef DE2_115
SDRAM_DQM,
`endif
SDRAM_RAS_N,
SDRAM_CAS_N,
SDRAM_CKE,
SDRAM_CLK,
SDRAM_CS_N,
SDRAM_RW_N,
// VGA
// SRH The DE2-115 has a 8,8,8 RGB VGA interface
`ifdef DE2_115
RED7,
GREEN7,
BLUE7,
RED6,
GREEN6,
BLUE6,
RED5,
GREEN5,
BLUE5,
RED4,
GREEN4,
BLUE4,
`endif
RED3,
GREEN3,
BLUE3,
RED2,
GREEN2,
BLUE2,
RED1,
GREEN1,
BLUE1,
RED0,
GREEN0,
BLUE0,
H_SYNC,
V_SYNC,
// SRH Extra control lines for the VGA tripple DAC on the DE2-115
`ifdef DE2_115
VGA_SYNC_N,
VGA_BLANK_N,
HBLANK,
	VBLANK,
VGA_CLK,
`endif

// PS/2
ps2_clk,
ps2_data,
//ms_clk,
//ms_data,
//Serial Ports
DE1TXD,
DE1RXD,
OPTTXD,
OPTRXD,
// I2C
I2C_SCL,
I2C_DAT,
//Codec
AUD_XCK,
AUD_BCLK,
AUD_DACDAT,
AUD_DACLRCK,
AUD_ADCDAT,
AUD_ADCLRCK,
// 7 Segment Display
SEGMENT0_N,
SEGMENT1_N,
SEGMENT2_N,
SEGMENT3_N,
`ifdef DE2_115
SEGMENT4_N,
SEGMENT5_N,
SEGMENT6_N,
SEGMENT7_N,
`endif

// LEDs
LEDG,
LEDR,
// CoCo Joystick
PADDLE_MCLK,
PADDLE_CLK,
P_SWITCH,
//SPI for SD Card
MOSI,
MISO,
SPI_CLK,
SPI_SS_N,
`ifdef DE2_115
SD_WP_N, // HWP = 0
`endif
// Debug Test Points
//TEST_1,
//TEST_2,
//TEST_3,
//TEST_4,
// WiFi
WF_RXD,
WF_TXD,
RST,
//RTC I2C
CK_CLK,
CK_DAT,
// Buttons and Switches
SWITCH,
BUTTON_N,
GPIO
);


//Analog Board
parameter BOARD_TYPE = 8'h00;

`include "../CoCo3FPGA_Common/coco3fpga_top.v"
