#ifndef __ETHERNET_DEVICE__
#define __ETHERNET_DEVICE__

#include "hasim-module.h"

extern "C"
{
#include "ramp_fifo.h"
}

// ===============================================
//               Ethernet Device
// ===============================================

// =========== The actual Device Class ===========
typedef class ETHERNET_DEVICE_CLASS* ETHERNET_DEVICE;
class ETHERNET_DEVICE_CLASS: public HASIM_MODULE_CLASS
{
    private:
        // instantiate the C handle
	ramp_chan_t pchannel;

    public:
        ETHERNET_DEVICE_CLASS(HASIM_MODULE);
        ~ETHERNET_DEVICE_CLASS();

        void     Cleanup();
        void     Uninit();
        
        int enq(UINT64 * val);
        int deq(UINT64 * val);
        int empty();
};

#endif
