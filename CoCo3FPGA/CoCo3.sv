//============================================================================
//  CoCo3 port to MiSTer
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//
//============================================================================

module emu
(
        //Master input clock
        input         CLK_50M,

        //Async reset from top-level module.
        //Can be used as initial reset.
        input         RESET,

        //Must be passed to hps_io module
        inout  [45:0] HPS_BUS,

        //Base video clock. Usually equals to CLK_SYS.
        output        CLK_VIDEO,

        //Multiple resolutions are supported using different CE_PIXEL rates.
        //Must be based on CLK_VIDEO
        output        CE_PIXEL,

        //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
        output  [7:0] VIDEO_ARX,
        output  [7:0] VIDEO_ARY,

        output  [7:0] VGA_R,
        output  [7:0] VGA_G,
        output  [7:0] VGA_B,
        output        VGA_HS,
        output        VGA_VS,
        output        VGA_DE,    // = ~(VBlank | HBlank)
        output        VGA_F1,
        output [1:0]  VGA_SL,

        output        LED_USER,  // 1 - ON, 0 - OFF.

        // b[1]: 0 - LED status is system status OR'd with b[0]
        //       1 - LED status is controled solely by b[0]
        // hint: supply 2'b00 to let the system control the LED.
        output  [1:0] LED_POWER,
        output  [1:0] LED_DISK,

        // I/O board button press simulation (active high)
        // b[1]: user button
        // b[0]: osd button
        output  [1:0] BUTTONS,


        output [15:0] AUDIO_L,
        output [15:0] AUDIO_R,
        output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
        output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
        input         TAPE_IN,
        //ADC
        inout   [3:0] ADC_BUS,

        // SD-SPI
        output        SD_SCK,
        output        SD_MOSI,
        input         SD_MISO,
        output        SD_CS,
        input         SD_CD,

        //High latency DDR3 RAM interface
        //Use for non-critical time purposes
        output        DDRAM_CLK,
        input         DDRAM_BUSY,
        output  [7:0] DDRAM_BURSTCNT,
        output [28:0] DDRAM_ADDR,
        input  [63:0] DDRAM_DOUT,
        input         DDRAM_DOUT_READY,
        output        DDRAM_RD,
        output [63:0] DDRAM_DIN,
        output  [7:0] DDRAM_BE,
        output        DDRAM_WE,

        //SDRAM interface with lower latency
        output        SDRAM_CLK,
        output        SDRAM_CKE,
        output [12:0] SDRAM_A,
        output  [1:0] SDRAM_BA,
        inout  [15:0] SDRAM_DQ,
        output        SDRAM_DQML,
        output        SDRAM_DQMH,
        output        SDRAM_nCS,
        output        SDRAM_nCAS,
        output        SDRAM_nRAS,
        output        SDRAM_nWE,

        input         UART_CTS,
        output        UART_RTS,
        input         UART_RXD,
        output        UART_TXD,
        output        UART_DTR,
        input         UART_DSR,


        // Open-drain User port.
        // 0 - D+/RX
        // 1 - D-/TX
        // 2..6 - USR2..USR6
        // Set USER_OUT to 1 to read from USER_IN.
        input   [6:0] USER_IN,
        output  [6:0] USER_OUT,

        input         OSD_STATUS
);


//`define SOUND_DBG
assign VGA_SL=0;
//assign CE_PIXEL=1;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign USER_OUT = '1;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign ADC_BUS  = 'Z;
//assign {SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 6'b111111;
//assign SDRAM_DQ = 'Z;


assign VGA_F1    = 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : status[2]  ? 8'd4 : 8'd3;
assign HDMI_ARY = status[1] ? 8'd9  : status[2]  ? 8'd3 : 8'd4;

`include "build_id.v"
localparam CONF_STR = {
        "COCO3;;",
        "H0O1,Aspect Ratio,Original,Wide;",
        "H0O2,Orientation,Vert,Horz;",
        "O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
        "-;",
        "R0,Reset;",
        "J1,Fire,Start 1P,Start 2P,Coin,Cheat;",
        "jn,A,Start,Select,R,L;",
        "V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_vid;

assign clk_sys = CLK_50M;
assign clk_vid = CLK_50M;
/*
wire pll_locked;

pll pll
(
        .refclk(CLK_50M),
        .rst(0),
        .outclk_0(clk_vid),
        .outclk_1(clk_sys),
        .locked(pll_locked)
);

*/
///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [10:0] ps2_key;

wire [15:0] joy1 = joy1a | joy2a;
wire [15:0] joy2 = joy1a | joy2a;
wire [15:0] joy1a;
wire [15:0] joy2a;

wire [21:0] gamma_bus;

assign CLK_VIDEO = clk_sys;
assign VIDEO_ARX = 4;
assign VIDEO_ARY = 3;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
        .clk_sys(clk_sys),
        .HPS_BUS(HPS_BUS),

        .conf_str(CONF_STR),

        .buttons(buttons),
        .status(status),
        .status_menumask(direct_video),
        .forced_scandoubler(forced_scandoubler),
        .gamma_bus(gamma_bus),
        .direct_video(direct_video),

        .ioctl_download(ioctl_download),
        .ioctl_wr(ioctl_wr),
        .ioctl_addr(ioctl_addr),
        .ioctl_dout(ioctl_dout),
        .ioctl_index(ioctl_index),

        .joystick_0(joy1a),
        .joystick_1(joy2a),
        .ps2_key(ps2_key),


        .ps2_kbd_clk_out    ( ps2_kbd_clk    ),
        .ps2_kbd_data_out   ( ps2_kbd_data   )
);

wire ps2_kbd_clk;
wire ps2_kbd_data;


wire hblank, vblank;
wire hs, vs;

wire vga_clk;

video_mixer #(.GAMMA(1)) video_mixer
(
        .*,

        .clk_vid(clk_vid),
        .ce_pix(vga_clk),
        .ce_pix_out(CE_PIXEL),

        .scanlines(0),
        .scandoubler(  forced_scandoubler),
        .hq2x(0),

        .mono(0),

        .R(r),
        //.R(8'b11111111),
        .G(g),
        .B(b),

        // Positive pulses.
        .HSync(hs),
        .VSync(vs),
        .HBlank(hblank),
        .VBlank(vblank)
);
//
//
wire [9:0] audio;
assign AUDIO_L = {audio, 6'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;

wire [7:0] r;
wire [7:0] g;
wire [7:0] b;


coco3fpga_dw coco3 (
.CLK50MHZ(CLK_50M),
// SDRAM
.SDRAM_ADDRESS(SDRAM_A),
.SDRAM_BANK(SDRAM_BA),
.SDRAM_DATA(SDRAM_DQ),
.SDRAM_LDQM(SDRAM_DQML),
.SDRAM_UDQM(SDRAM_DQMH),
.SDRAM_DQM(SDRAM_DQ),
.SDRAM_RAS_N(SDRAM_nRAS),
.SDRAM_CAS_N(SDRAM_nCAS),
.SDRAM_CKE(SDRAM_CKE),
.SDRAM_CLK(SDRAM_CLK),
.SDRAM_CS_N(SDRAM_nCS),
.SDRAM_RW_N(SDRAM_nWE),
// VGA
// SRH The DE2-115 has a 8,8,8 RGB VGA interface
.RED7(r[7]),
.GREEN7(g[7]),
.BLUE7(b[7]),
.RED6(r[6]),
.GREEN6(g[6]),
.BLUE6(b[6]),
.RED5(r[5]),
.GREEN5(g[5]),
.BLUE5(b[5]),
.RED4(r[4]),
.GREEN4(g[4]),
.BLUE4(b[4]),
.RED3(r[3]),
.GREEN3(g[3]),
.BLUE3(b[3]),
.RED2(r[2]),
.GREEN2(g[2]),
.BLUE2(b[2]),
.RED1(r[1]),
.GREEN1(g[1]),
.BLUE1(b[1]),
.RED0(r[0]),
.GREEN0(g[0]),
.BLUE0(b[0]),
.H_SYNC(hs),
.V_SYNC(vs),
.HBLANK(hblank),
.VBLANK(vblank),
.VGA_CLK(vga_clk),
// PS/2
.ps2_clk(ps2_kbd_clk),
.ps2_data(ps2_kbd_data),

);
/*
coco3fpga_dw coco3 (
// Input Clocks
.CLK50MHZ(CLK_50M),
        l
CLK27MHZ,
// RAM and ROM
RAM0_DATA,				// 16 bit data bus to RAM 0
RAM0_ADDRESS,
RAM0_RW_N,
RAM0_CS_N,				// Chip Select for RAM 0
RAM0_BE0_N,				// Byte Enable for RAM 0
RAM0_BE1_N,				// Byte Enable for RAM 0
RAM0_OE_N,
FLASH_ADDRESS,
FLASH_WE_N,
FLASH_RESET_N,
FLASH_CE_N,
FLASH_OE_N,
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
SEGMENT4_N,
SEGMENT5_N,
SEGMENT6_N,
SEGMENT7_N,
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
SD_WP_N, // HWP = 0
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

        .RESET(RESET | status[0] | buttons[1]),
        .CLK(clk_sys),
        .ENA_6(ce_6m),
        .ENA_4(ce_4m),
        .ENA_1M79(ce_1m79)
);
*/
endmodule
