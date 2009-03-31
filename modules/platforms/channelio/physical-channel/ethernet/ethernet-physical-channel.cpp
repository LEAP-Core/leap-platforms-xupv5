//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <iostream>

#include "asim/provides/physical_channel.h"

using namespace std;

// ==============================================
//            WARNING WARNING WARNING
// This code is swarming with potential deadlocks
// ==============================================

// ============================================
//               Physical Channel              
// ============================================

// constructor: set up hardware partition
PHYSICAL_CHANNEL_CLASS::PHYSICAL_CHANNEL_CLASS(
    PLATFORMS_MODULE p,
    PHYSICAL_DEVICES d) :
        PLATFORMS_MODULE_CLASS(p)
{
    // cache links to useful physical devices
    ethernetDevice = d->GetEthernetDevice();
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read()
{
    // blocking loop
    while (true)
    {
        // check if message is ready
        if (incomingMessage && !incomingMessage->CanAppend())
        {
            // message is ready!
            UMF_MESSAGE msg = incomingMessage;
            incomingMessage = NULL;
            return msg;
        }

        // read some data from FIFO
        readFIFO();
    }

    // shouldn't be here
    return NULL;
}

// non-blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::TryRead()
{
    // attempt read 
    readFIFO();

    // now see if we have a complete message
    if (incomingMessage && !incomingMessage->CanAppend())
    {
        UMF_MESSAGE msg = incomingMessage;
        incomingMessage = NULL;
        return msg;
    }

    // message not yet ready
    return NULL;
}

// write
void
PHYSICAL_CHANNEL_CLASS::Write(
    UMF_MESSAGE message)
{

    // construct header
    UMF_CHUNK header = message->EncodeHeader();

    // this gets ugly - we need to block until space is available
    int header_ret = -1;

    while (header_ret == -1)
    {
        header_ret = ethernetDevice.enq(UINT64(header));
    }

    // write message data to physical channel
    // NOTE: hardware demarshaller expects chunk pattern to start from most
    //       significant chunk and end at least significant chunk, so we will
    //       send chunks in reverse order

    message->StartReverseExtract();
    while (message->CanReverseExtract())
    {
        UMF_CHUNK chunk = message->ReverseExtractChunk();

        // once again block until space is available
        int ret = -1;

        while (ret == -1)
        {
            ret = ethernetDevice.enq(UINT64(chunk));
        }

    }

    // de-allocate message
    message->Delete();
}


// read one chunk's worth of unread data
void
PHYSICAL_CHANNEL_CLASS::readFIFO()
{
    UMF_CHUNK chunk;
    UINT64 inc;

    // check cached pointers to see if we can actually read anything
    if (pchannel->empty())
    {
        return;
    }

    // determine if we are starting a new message
    if (incomingMessage == NULL)
    {
        // read up to one chunk
        int ret = pciExpressDevice->deq(&inc);
        chunk = UMF_CHUNK(inc);

        // new message
        incomingMessage = UMF_MESSAGE_CLASS::New();
        incomingMessage->DecodeHeader(chunk);
    }
    else if (!incomingMessage->CanAppend())
    {
        // uh-oh.. we already have a full message, but it hasn't been
        // asked for yet. We will simply not read the pipe, but in
        // future, we might want to include a read buffer.
    }
    else
    {
        // read up to one chunk
        int ret = pciExpressDevice->deq(&inc);
        chunk = UMF_CHUNK(inc);

        // read in some more bytes for the current message
        incomingMessage->AppendChunk(chunk);
    }
}
