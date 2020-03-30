**********************************************************
		COCO3 FPGA V4.1.2
		by Gary Becker
		DE2-115 Conversion by Stan Hodge
		4/30/18
**********************************************************

This note replaces Gary's original readme file and is specific
to this port.

This is a conversion from the original source posted for
V4.1.  During verification, a bug was found in the
drivewire implementation, manifesting itself by incorrect
drive 3 operation.  Gary posted code to update the firmware
for the 6502 controlling the drivewire port AND removing
the RTC implementation.  This code was rolled into this
distribution.
																														 
Credit is given to Leslie who can be found on the COCO
group with the id of 'redskulldc' for the PIN cross reference
listing for TERASIC boards and the DE1 target. I have
augmented this with the pins specific to the DE2-115 port.
The spreadsheet is 'Terasic_pins_V2.xls'. Also included is
a specific tab in the spreadsheet with just the names and 
pins which can be exported to a .csv file and imported into
Quartus2.  This file is also in the archive as 
'coco3fpga_dw_DE2_115.csv' in the COC3FPGA directory.

The project is Quartus 2 is 'coco3fpga_dw.qpf' in the COCO3FPGA
directory. As a reference only the original paths for the 
project was 'C:\projects\coco\V4.1.0_DE2_115\...

Running:

1.	The file in the root of the project 'DE1_Flash_short.bin'
	needs to be programmed into the onboard flash memory at
	address 0x0.  The easiest way to accomplish this is to
	use the TERASIC control panel for the DE2-115.
2. 	Plug in a PS2 keyboard
3. 	Plug in a VGA monitor 
4. 	As a quick test set switches 9-0 to (where 1 is up)
	9876543210
	0000000110
5.	Connect audio to the 'green' line out connector
6. 	Download ..\CoCo3FPGA\coco3fpga_dw.sof

Typically, this will start up by showing the COCO3 Easter Egg.
Simply hit <ctrl><alt><del> to reset into the COCO.  Note:
You do need to read Gary's documentation for the settings of 
the physical switches SW1-SW9 for proper operation.

To get drivewire working plug a rs-232 cable in and connect
it to your host.  Set the baud rate to 115200 and load up
the drivewire software with some disks.  I was not able
to get much faster speed out of the coco rs232.  However,
the multipak RS-232 is pined out on the 40 pin connector.

Note: To use this you must have a TTL level rs-232 adapter.
Amazon sells a USB to TTL port adapter to flying pins for
~$8.

Pins on J15 are:
COCOPin		FPGA Pin	J15 Name	J15 Pin
OPTTXD		AF24		GPIO[14]	  17
OPTRXD		AE21		GPIO[15]	  18
GND			--			  GND		  12 (or 30)

Do not connect the + voltage from the adapter back to the
FPGA dev board!

With this you can successfully run 921600 on your drivewire
interface.

Because the GPIO connectors between the DE1 and the DE2-115
are different, the external analog board interface is not
supported. (yet)[don't get hopes up].  For this reason, the 
external SRAM interface is commented out in the code.

The verilog code was modified using 'ifdef' constructs and
by defining a new symbol - 'DE2-115'.  If you wish you can
comment out the DE2-115 and the code should compile for a DE1
board (with the necessary chip change and pinout adjustment).

An additional module was added to the design.  This module is
a counter system which can be hooked up to any event.  It
counts up [16 bit] and displays on the additional 4 displays
which the DE2-115 has beyond the DE1.  It has a timeout /
reset at 4 seconds of no activity.  It also blanks leading
zeros including the least significant nibble - so the default
display is all blanks.  In the design it is connected to the
serial port to show drivewire activity over the multipak rs-232.

Memory is set up as the 2MB SRAM on the DE2-115 board.  It is
all mapped to the COCO but as of this document I do not have
a correct memory test program to validate.  The one which does
come close thinks there is 8MB and stops with an error after
2MB.  Validating 2MB...

The SDRAM is setup and functional.  Only the lower 16 bits are
mapped to maintain compatibility  with the DE1.  The basic
dram memory test had been ran without error for validation.

