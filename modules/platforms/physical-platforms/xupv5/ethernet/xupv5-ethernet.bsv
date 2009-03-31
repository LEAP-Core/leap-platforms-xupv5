//
// Copyright (C) 2009 Massachusetts Institute of Technology
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

import FIFO::*;
import Clocks::*;

// xupv5-ethernet

// The Physical Platform for the XUP Virtex 5 with Ethernet

`include "led_device.bsh"
`include "switch_device.bsh"
`include "buttons_device.bsh"
`include "ethernet_device.bsh"
`include "ddr2_sdram_device.bsh"

// Coming soon:
// Audio
// DVI
// Flash
// Keyboard
// LCD
// Mouse
// PCIe
// Serial
// SATA
// SRAM
// USB
// VGA


// 8 switches, 13 leds, (0-7, +5 for ones by buttons), 5 buttons

`define NUMBER_LEDS 13
`define NUMBER_SWITCHES 8
`define NUMBER_BUTTONS 5

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;

    interface LEDS_DRIVER#(`NUMBER_LEDS)         ledsDriver;
    interface SWITCHES_DRIVER#(`NUMBER_SWITCHES) switchesDriver;
    interface BUTTONS_DRIVER#(`NUMBER_BUTTONS  ) buttonsDriver;
    interface PCI_EXPRESS_DRIVER                 ethernetDriver;
    // interface DDR2_SDRAM_DRIVER                  ddr2SDRAMDriver;
        
    // each set of physical drivers must support a soft reset method
    method Action soft_reset();
        
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    interface LEDS_WIRES#(`NUMBER_LEDS)          ledsWires;
    interface SWITCHES_WIRES#(`NUMBER_SWITCHES)  switchesWires;
    interface BUTTONS_WIRES#(`NUMBER_BUTTONS)    buttonsWires;
    interface PCI_EXPRESS_WIRES                  ethernetWires;
    // interface DDR2_SDRAM_WIRES                   ddr2SDRAMWires;
    
endinterface

// PHYSICAL_PLATFORM

// The platform is the aggregation of wires and drivers.

interface PHYSICAL_PLATFORM;

    interface PHYSICAL_DRIVERS physicalDrivers;
    interface TOP_LEVEL_WIRES  topLevelWires;

endinterface

// mkPhysicalPlatform

// This is a convenient way for the outside world to instantiate all the devices
// and an aggregation of all the wires.

module mkPhysicalPlatform#(Clock topLevelClock, Reset topLevelReset)
       //interface: 
                    (PHYSICAL_PLATFORM);
    
    // Submodules
    
    LEDS_DEVICE#(`NUMBER_LEDS)         leds_device         <- mkLEDsDevice(topLevelClock, topLevelReset);
    SWITCHES_DEVICE#(`NUMBER_SWITCHES) switches_device     <- mkSwitchesDevice(topLevelClock, topLevelReset);
    BUTTONS_DEVICE#(`NUMBER_BUTTONS)   buttons_device      <- mkButtonsDevice(topLevelClock, topLevelReset);
    ETHERNET_DEVICE                    ethernet_device     <- mkEthernetDevice();
    // DDR2_SDRAM_DEVICE                  ddr2_sdram_device   <- mkDDR2SDRAMDevice(topLevelClock, topLevelReset);

    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface ledsDriver       = leds_device.driver;
        interface switchesDriver   = switches_device.driver;
        interface buttonsDriver    = buttons_device.driver;
        interface ethernetDriver   = ethernet_device.driver;
        // interface ddr2SDRAMDriver  = ddr2_sdram_device.driver;
    
        // Soft Reset method
        method soft_reset = ethernet.driver.softReset;
    
    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;
    
        interface ledsWires        = leds_device.wires;
        interface switchesWires    = switches_device.wires;
        interface buttonsWires     = buttons_device.wires;
        interface ethernetWires    = ethernet_device.wires;
        // interface ddr2SDRAMWires   = ddr2_sdram_device.wires;

    endinterface
               
endmodule
