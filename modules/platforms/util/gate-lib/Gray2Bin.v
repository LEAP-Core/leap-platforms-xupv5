//==============================================================================
//	File:		$URL: svn+ssh://repositorypub@repository.eecs.berkeley.edu/public/Projects/GateLib/trunk/Core/GateCore/Hardware/Library/Gray2Bin.v $
//	Version:	$Revision: 18793 $
//	Author:		Greg Gibeling (http://gdgib.gotdns.com/~gdgib/)
//	Copyright:	Copyright 2003-2009 UC Berkeley
//==============================================================================

//==============================================================================
//	Section:	License
//==============================================================================
//	Copyright (c) 2003-2009, Regents of the University of California
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without modification,
//	are permitted provided that the following conditions are met:
//
//		- Redistributions of source code must retain the above copyright notice,
//			this list of conditions and the following disclaimer.
//		- Redistributions in binary form must reproduce the above copyright
//			notice, this list of conditions and the following disclaimer
//			in the documentation and/or other materials provided with the
//			distribution.
//		- Neither the name of the University of California, Berkeley nor the
//			names of its contributors may be used to endorse or promote
//			products derived from this software without specific prior
//			written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//	ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//==============================================================================

//------------------------------------------------------------------------------
//	Module:		Gray2Bin
//	Desc:		This is a simple gray code to binary converter
//	Params:		Width:		The width of the binary/gray code
//	Author:		<a href="http://gdgib.gotdns.com/~gdgib/">Greg Gibeling</a>
//	Version:	$Revision: 18793 $
//------------------------------------------------------------------------------
module	Gray2Bin(Gray, Bin);
	//--------------------------------------------------------------------------
	//	Parameters
	//--------------------------------------------------------------------------
	parameter				Width =					8;
	//--------------------------------------------------------------------------

	//--------------------------------------------------------------------------
	//	I/O
	//--------------------------------------------------------------------------
	input	[Width-1:0]		Gray;
	output	[Width-1:0]		Bin;
	//--------------------------------------------------------------------------

	//--------------------------------------------------------------------------
	//	Regs
	//--------------------------------------------------------------------------
	genvar					i;
	//--------------------------------------------------------------------------
  
	//--------------------------------------------------------------------------
	//	Converter
	//--------------------------------------------------------------------------
	generate for(i = 0; i < Width; i = i + 1) begin:G2B
		assign	Bin[i] =							^Gray[Width-1:i];
	end endgenerate
	//--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
