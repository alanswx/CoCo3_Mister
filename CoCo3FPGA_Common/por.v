////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 4.0
// File Name:		por.v
//
// CoCo3 in an FPGA
//
// Revision: 4.0 
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
// The FDC co-processor copyrighted Daniel Wallner.
// SDRAM Controller copyrighted by XESS Corp.
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 4.0
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
//	4.0.X.X		Full Release
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
//
//	POR by Stan Hodge 8/15/21
////////////////////////////////////////////////////////////////////////////////


module POR(
input				CLK,   // set for 500ms @ 50Mhz
output				POR	   // Positive output  Reset to normal 1 => 0
);


reg     [24:0]	por_counter = 25'b0000000000000000000000000;
reg         	por_reset = 1'b1;

always @(posedge CLK)
begin
	por_counter <= por_counter + 1'b1;
    if (por_counter == 25'd25000000) 
    	por_reset <= 1'b0;
end

assign POR = por_reset;

endmodule
