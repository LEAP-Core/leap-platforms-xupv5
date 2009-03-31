//==============================================================================
//	File:		$URL: svn+ssh://repositorypub@repository.eecs.berkeley.edu/public/Projects/GateLib/trunk/Core/GateCore/Hardware/FIFO/Library/FIFOSemaphore.v $
//	Version:	$Revision: 18793 $
//	Author:		Greg Gibeling (http://gdgib.gotdns.com/~gdgib/)
//	Copyright:	Copyright 2005-2009 UC Berkeley
//==============================================================================

//==============================================================================
//	Section:	License
//==============================================================================
//	Copyright (c) 2005-2009, Regents of the University of California
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

//==============================================================================
//	Includes
//==============================================================================
`include "Const.v"
//==============================================================================

//------------------------------------------------------------------------------
//	Module:		FIFOSemaphore
//	Desc:		An adaptation of FIFOControl for use as a semaphore.
//	Params:		Asynchronous: Use a completely asynchronous design
//				Buffering: The maximum value of the semaphore counter.
//	Author:		<a href="http://gdgib.gotdns.com/~gdgib/">Greg Gibeling</a>
//	Version:	$Revision: 18793 $
//------------------------------------------------------------------------------
module	FIFOSemaphore(
			//------------------------------------------------------------------
			//	Clock & Reset Inputs
			//------------------------------------------------------------------
			Clock,
			Reset,
			//------------------------------------------------------------------
			
			//------------------------------------------------------------------
			//	Input Interface
			//------------------------------------------------------------------
			InClock,
			InReset,
			InValid,
			InReady,
			//------------------------------------------------------------------
			
			//------------------------------------------------------------------
			//	Output Interface
			//------------------------------------------------------------------
			OutClock,
			OutReset,
			OutValid,
			OutReady
			//------------------------------------------------------------------
	);
	//--------------------------------------------------------------------------
	//	Parameters
	//--------------------------------------------------------------------------
	parameter				Asynchronous =			0,
							Buffering =				16;
	//--------------------------------------------------------------------------
	
	//--------------------------------------------------------------------------
	//	Clock & Reset Inputs
	//--------------------------------------------------------------------------
	input					Clock, Reset;
	//--------------------------------------------------------------------------
	
	//--------------------------------------------------------------------------
	//	Input Interface
	//--------------------------------------------------------------------------
	input					InClock, InReset;
	input					InValid;
	output					InReady;
	//--------------------------------------------------------------------------
	
	//--------------------------------------------------------------------------
	//	Output Interface
	//--------------------------------------------------------------------------
	input					OutClock, OutReset;
	output					OutValid;
	input					OutReady;
	//--------------------------------------------------------------------------
	
	//--------------------------------------------------------------------------
	//	FIFO Controller
	//--------------------------------------------------------------------------
	FIFOControl		#(			.Asynchronous(		Asynchronous),
								.FWLatency(			Asynchronous ? 2 : 1),
								.Buffering(			Buffering),
								.BWLatency(			Asynchronous ? 2 : 1))
					Control(	.Clock(				Clock),
								.Reset(				Reset),
								
								.InClock(			InClock),
								.InReset(			InReset),
								.InValid(			InValid),
								.InAccept(			InReady),
								.InWrite(			),
								.InGate(			),
								.InWriteAddress(	),
								.InReadAddress(		),
								.InEmptyCount(		),
								
								.OutClock(			OutClock),
								.OutReset(			OutReset),
								.OutSend(			OutValid),
								.OutReady(			OutReady),
								.OutRead(			),
								.OutGate(			),
								.OutReadAddress(	),
								.OutWriteAddress(	),
								.OutFullCount(		));
	//--------------------------------------------------------------------------
endmodule	
//------------------------------------------------------------------------------
