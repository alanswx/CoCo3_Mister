////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 4.0
// File Name:		coco3fpga.v
//
// CoCo3 in an FPGA
//
// Revision: 4.0 07/10/16
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
////////////////////////////////////////////////////////////////////////////////

/*****************************************************************************
* Joystick to CoCo compatable
******************************************************************************/

assign PADDLE_MCLK = MCLOCK[6];
//Cycle through this State Machine 1 time for each reading
//
always @(negedge MCLOCK[6] or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		JOY_CLK0 <= 13'h0000;
		JOY_TRIGGER0 <= 1'b0;
		JCASE0 <= 1'b0;
	end
	else
	begin
		case(JCASE0)
		1'b0:
		begin
			JOY_CLK0 <= JOY_CLK0 + 1'b1;
			if(JOY_CLK0 == 13'h1893)							// 4096/(0.7/5*4.65)=6291
			begin
				JOY_TRIGGER0 <= 1'b1;
				JCASE0 <= 1'b1;
			end
		end
		1'b1:
		begin
			if(JOY_CLK0 == 13'h18B5)							// 6325
			begin
				JOY_CLK0 <= 13'h0000;
				JCASE0 <= 1'b0;
				JOY_TRIGGER0 <= 1'b0;
			end
			else
				JOY_CLK0 <= JOY_CLK0 + 1'b1;
		end
		endcase
	end
end

always @(negedge PADDLE_CLK[0] or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		PADDLE_ZERO_0 <= 10'h000;
		PADDLE_VAL_0 <= 12'h000;
		PADDLE_STATE_0 <= 2'b00;
		JOY1_COUNT <= 6'h00;
	end
	else
	begin
		case(PADDLE_STATE_0)
		2'b00:
		begin
			PADDLE_ZERO_0 <= PADDLE_ZERO_0 + 1'b1;
			PADDLE_VAL_0 <= 12'h000;
			if(PADDLE_ZERO_0 == 10'h3AE)						// 6291*0.15=943-1
				PADDLE_STATE_0 <= 2'b01;
			else
				if(JOY_TRIGGER0)
					PADDLE_STATE_0 <= 2'b10;
				else
					PADDLE_STATE_0 <= 2'b00;
		end
		2'b01:
		begin
			PADDLE_VAL_0 <= PADDLE_VAL_0 + 1'b1;
			if(PADDLE_VAL_0 == 12'hFFE)						// 4096-2
				PADDLE_STATE_0 <= 2'b10;
			else
			begin
				if(JOY_TRIGGER0)
					PADDLE_STATE_0 <= 2'b10;
				else
					PADDLE_STATE_0 <= 2'b01;
			end
		end
		2'b10:
		begin
			PADDLE_ZERO_0 <= 10'h000;
			JOY1_COUNT <= PADDLE_VAL_0[11:6];
			PADDLE_LATCH_0 <= PADDLE_VAL_0;
			if(JOY_TRIGGER0)
					PADDLE_STATE_0 <= 2'b11;
		end
		2'b11:
		begin
			if(!JOY_TRIGGER0)
				PADDLE_STATE_0 <= 2'b00;
		end
		endcase
	end
end

always @(negedge MCLOCK[6] or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		JOY_CLK1 <= 13'h0000;
		JOY_TRIGGER1 <= 1'b0;
		JCASE1 <= 1'b0;
	end
	else
	begin
		case(JCASE1)
		1'b0:
		begin
			JOY_CLK1 <= JOY_CLK1 + 1'b1;
			if(JOY_CLK1 == 13'h1893)							// 4096/(0.7/5*4.65)=6291
			begin
				JOY_TRIGGER1 <= 1'b1;
				JCASE1 <= 1'b1;
			end
		end
		1'b1:
		begin
			if(JOY_CLK1 == 13'h18B5)							// 6325
			begin
				JOY_CLK1 <= 13'h0000;
				JCASE1 <= 1'b0;
				JOY_TRIGGER1 <= 1'b0;
			end
			else
				JOY_CLK1 <= JOY_CLK1 + 1'b1;
		end
		endcase
	end
end

always @(negedge PADDLE_CLK[1] or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		PADDLE_ZERO_1 <= 10'h000;
		PADDLE_VAL_1 <= 12'h000;
		PADDLE_STATE_1 <= 2'b00;
		JOY2_COUNT <= 6'h00;
	end
	else
	begin
		case(PADDLE_STATE_1)
		2'b00:
		begin
			PADDLE_ZERO_1 <= PADDLE_ZERO_1 + 1'b1;
			PADDLE_VAL_1 <= 12'h000;
			if(PADDLE_ZERO_1 == 10'h3AE)						// 6291*0.15=943-1
				PADDLE_STATE_1 <= 2'b01;
			else
				if(JOY_TRIGGER1)
					PADDLE_STATE_1 <= 2'b10;
				else
					PADDLE_STATE_1 <= 2'b00;
		end
		2'b01:
		begin
			PADDLE_VAL_1 <= PADDLE_VAL_1 + 1'b1;
			if(PADDLE_VAL_1 == 12'hFFE)						// 4096-2
				PADDLE_STATE_1 <= 2'b10;
			else
			begin
				if(JOY_TRIGGER1)
					PADDLE_STATE_1 <= 2'b10;
				else
					PADDLE_STATE_1 <= 2'b01;
			end
		end
		2'b10:
		begin
			PADDLE_ZERO_1 <= 10'h000;
			JOY2_COUNT <= PADDLE_VAL_1[11:6];
			PADDLE_LATCH_1 <= PADDLE_VAL_1;
			if(JOY_TRIGGER1)
					PADDLE_STATE_1 <= 2'b11;
		end
		2'b11:
		begin
			if(!JOY_TRIGGER1)
				PADDLE_STATE_1 <= 2'b00;
		end
		endcase
	end
end

always @(negedge MCLOCK[6] or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		JOY_CLK2 <= 13'h0000;
		JOY_TRIGGER2 <= 1'b0;
		JCASE2 <= 1'b0;
	end
	else
	begin
		case(JCASE2)
		1'b0:
		begin
			JOY_CLK2 <= JOY_CLK2 + 1'b1;
			if(JOY_CLK2 == 13'h1893)							// 4096/(0.7/5*4.65)=6291
			begin
				JOY_TRIGGER2 <= 1'b1;
				JCASE2 <= 1'b1;
			end
		end
		1'b1:
		begin
			if(JOY_CLK2 == 13'h18B5)							// 6325
			begin
				JOY_CLK2 <= 13'h0000;
				JCASE2 <= 1'b0;
				JOY_TRIGGER2 <= 1'b0;
			end
			else
				JOY_CLK2 <= JOY_CLK2 + 1'b1;
		end
		endcase
	end
end

always @(negedge PADDLE_CLK[2] or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		PADDLE_ZERO_2 <= 10'h000;
		PADDLE_VAL_2 <= 12'h000;
		PADDLE_STATE_2 <= 2'b00;
		JOY3_COUNT <= 6'h00;
	end
	else
	begin
		case(PADDLE_STATE_2)
		2'b00:
		begin
			PADDLE_ZERO_2 <= PADDLE_ZERO_2 + 1'b1;
			PADDLE_VAL_2 <= 12'h000;
			if(PADDLE_ZERO_2 == 10'h3AE)						// 6291*0.15=943-1
				PADDLE_STATE_2 <= 2'b01;
			else
				if(JOY_TRIGGER2)
					PADDLE_STATE_2 <= 2'b10;
				else
					PADDLE_STATE_2 <= 2'b00;
		end
		2'b01:
		begin
			PADDLE_VAL_2 <= PADDLE_VAL_2 + 1'b1;
			if(PADDLE_VAL_2 == 12'hFFE)						// 4096-2
				PADDLE_STATE_2 <= 2'b10;
			else
			begin
				if(JOY_TRIGGER2)
					PADDLE_STATE_2 <= 2'b10;
				else
					PADDLE_STATE_2 <= 2'b01;
			end
		end
		2'b10:
		begin
			PADDLE_ZERO_2 <= 10'h000;
			JOY3_COUNT <= PADDLE_VAL_2[11:6];
			PADDLE_LATCH_2 <= PADDLE_VAL_2;
			if(JOY_TRIGGER2)
					PADDLE_STATE_2 <= 2'b11;
		end
		2'b11:
		begin
			if(!JOY_TRIGGER2)
				PADDLE_STATE_2 <= 2'b00;
		end
		endcase
	end
end

always @(negedge MCLOCK[6] or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		JOY_CLK3 <= 13'h0000;
		JOY_TRIGGER3 <= 1'b0;
		JCASE3 <= 1'b0;
	end
	else
	begin
		case(JCASE3)
		1'b0:
		begin
			JOY_CLK3 <= JOY_CLK3 + 1'b1;
			if(JOY_CLK3 == 13'h1893)							// 4096/(0.7/5*4.65)=6291
			begin
				JOY_TRIGGER3 <= 1'b1;
				JCASE3 <= 1'b1;
			end
		end
		1'b1:
		begin
			if(JOY_CLK3 == 13'h18B5)							// 6325
			begin
				JOY_CLK3 <= 13'h0000;
				JCASE3 <= 1'b0;
				JOY_TRIGGER3 <= 1'b0;
			end
			else
				JOY_CLK3 <= JOY_CLK3 + 1'b1;
		end
		endcase
	end
end

always @(negedge PADDLE_CLK[3] or negedge RESET_N)
begin
	if(~RESET_N)
	begin
		PADDLE_ZERO_3 <= 10'h000;
		PADDLE_VAL_3 <= 12'h000;
		PADDLE_STATE_3 <= 2'b00;
		JOY4_COUNT <= 6'h00;
	end
	else
	begin
		case(PADDLE_STATE_3)
		2'b00:
		begin
			PADDLE_ZERO_3 <= PADDLE_ZERO_3 + 1'b1;
			PADDLE_VAL_3 <= 12'h000;
			if(PADDLE_ZERO_3 == 10'h3AE)						// 6291*0.15=943-1
				PADDLE_STATE_3 <= 2'b01;
			else
				if(JOY_TRIGGER3)
					PADDLE_STATE_3 <= 2'b10;
				else
					PADDLE_STATE_3 <= 2'b00;
		end
		2'b01:
		begin
			PADDLE_VAL_3 <= PADDLE_VAL_3 + 1'b1;
			if(PADDLE_VAL_3 == 12'hFFE)						// 4096-2
				PADDLE_STATE_3 <= 2'b10;
			else
			begin
				if(JOY_TRIGGER3)
					PADDLE_STATE_3 <= 2'b10;
				else
					PADDLE_STATE_3 <= 2'b01;
			end
		end
		2'b10:
		begin
			PADDLE_ZERO_3 <= 10'h000;
			JOY4_COUNT <= PADDLE_VAL_3[11:6];
			PADDLE_LATCH_3 <= PADDLE_VAL_3;
			if(JOY_TRIGGER3)
					PADDLE_STATE_3 <= 2'b11;
		end
		2'b11:
		begin
			if(!JOY_TRIGGER3)
				PADDLE_STATE_3 <= 2'b00;
		end
		endcase
	end
end


always @(posedge CLK50MHZ) begin
  case (SEL)
  2'b00:
		if (joya2[15:10] > DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
  2'b01:
  		if (joya2[7:2] > DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
2'b10:
		if (joya1[15:10] > DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
  2'b11:
  		if (joya1[7:2] > DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
	endcase
end

/*
assign JSTICK =	(SEL == 2'b11)		?	JOY4:			// Left Y
						(SEL == 2'b10)		?	JOY3:			// Left X
						(SEL == 2'b01)		?	JOY2:			// Right Y
													JOY1;			// Right X

assign JOY1 = (JOY1_COUNT >= DTOA_CODE)	?	1'b1:
															1'b0;

assign JOY2 = (JOY2_COUNT >= DTOA_CODE)	?	1'b1:
															1'b0;

assign JOY3 = (JOY3_COUNT >= DTOA_CODE)	?	1'b1:
															1'b0;

assign JOY4 = (JOY4_COUNT >= DTOA_CODE)	?	1'b1:
															1'b0;
*/
