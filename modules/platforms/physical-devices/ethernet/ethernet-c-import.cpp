#include <iostream>
#include <unistd.h>

extern "C"
{
#include "ramp_fifo.h"
}

#include "asim/provides/ethernet_device.h"

using namespace std;

// ============================================
//              Ethernet Device
// ============================================

// takes care of talking to driver and resolving
// endianness issues

ETHERNET_DEVICE_CLASS::ETHERNET_DEVICE_CLASS(
    HASIM_MODULE p) :
        HASIM_MODULE_CLASS(p)
{
    // TODO: take ethernet device from command-line parameter.
    if (ramp_chan_init(&pchannel, "eth0") != 0) {
            cerr << "ethernet device: unable to open driver" << endl;
            exit(1);
    }
}

ETHERNET_DEVICE_CLASS::~ETHERNET_DEVICE_CLASS()
{
    Cleanup();
}

// override default chain-uninit method because
// we need to do something special
void
ETHERNET_DEVICE_CLASS::Uninit()
{
    Cleanup();

    // call default uninit so that we can continue
    // chain if necessary
    HASIM_MODULE_CLASS::Uninit();
}

void
ETHERNET_DEVICE_CLASS::Cleanup()
{
    ramp_chan_close(&pchannel);
}

int
ETHERNET_DEVICE_CLASS::deq(UINT64 *data)
{
    int ret = ramp_fifo_deq(data, &pchannel);
    if (ret < 0)
    {
        cerr << "ethernet device: ERROR: deq() failed" << endl;
        Uninit();
        exit(1);
    }
    return ret;
}

int
ETHERNET_DEVICE_CLASS::enq(
    UINT64 data)
{
    int ret = ramp_fifo_enq(&pchannel, data);
    if (ret > 0)
    {
        cerr << "ethernet device: ERROR: enq() failed" << endl;
        Uninit();
        exit(1);
    }
    return ret;
}

int
ETHERNET_DEVICE_CLASS::empty()
{
    return pchannel->rx_buffer.tail == pchannel->rx_buffer.head;
}
