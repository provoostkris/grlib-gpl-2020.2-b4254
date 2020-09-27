-----------------------------------------------------------------------------
-- LEON3 Demonstration design running on a Terasic DE10-nano Cyclone5 KIT
-- rev. 1.0 : 2020 Provoost Kris
------------------------------------------------------------------------------

Info:
The minimal reference design from GRLIB is used as a base for setting up a LEON3 demonstration design. 
Source code is modified and expanded to support the Terasic DE10-nano.
Tech support for cyclone5 device is added in the libraries.
The work has been done in free time, no guarantees / support are provided with the design.

Note: 
The Cyclone 5 SoC has a dual core on chip ARM. Obviously the LEON is less performant then these CPU's.
The idea behind the porting is to have the LEON available on a low end FPGA. The port should work for 
other Cyclone 5 families as well. 

Implementation:
- The CPU is a single core LEON
- It will run at 50 MHz, using a PLL
- A small amount of onchip SRAM is provided
- GPIO_0 is mapped (in the assigment file) for input only
- GPIO_1 is mapped (in the assigment file) for output only
- KEY_0 is for RESET of the system
- KEY_1 is for the DSU break control
- SW(0) is for the DSU enable control
- LEDs will inducate if the system is running
   

Flow:
- A linux virtual box ,Ubuntu 18, was used to execute the Makefile.
  >> copy the repository and navigate to ../designs/leon3-terasic-de10-nano
  >> make scripts
- The quartus .qpf and .qdf are copied to windows with Quartus 18.1 installed and Cyclone 5 device pack
  >> open the Quartus project
  >> mannually add the .sdc file for timing constraint
  >> "ctrl + l"
- After +/- 10 min. the compilation completes.
  >> open the programmer and program the .sof from the ../output_files/ to the FPGA
  
Debug:
- Connect a FTDI breakout adapter to the windows machine
  >> FTDI.GND <> GPIO1.12
  >> FTDI.TX  <> GPIO0.40
  >> FTDI.RX  <> GPIO1.01
  >>             GPIO signals as listed on the board (not the VHDL)
- Download GRMON2 evaluation from gaisler
  >> unpack grmon
  >> launch from the command line : grmon -uart com4
  >> see output below for commands and responses


output captured:
----------------


C:\Users\Kris\Downloads\grmon-eval-64-3.2.5\grmon-eval-3.2.5\windows\bin64>grmon -uart com4

  GRMON debug monitor v3.2.5 64-bit eval version

  Copyright (C) 2020 Cobham Gaisler - All rights reserved.
  For latest updates, go to http://www.gaisler.com/
  Comments or bug-reports to support@gaisler.com

  This eval version will expire on 20/02/2021

  GRLIB build version: 4254
  Detected frequency:  50,0 MHz

  Component                            Vendor
  LEON3 SPARC V8 Processor             Cobham Gaisler
  JTAG Debug Link                      Cobham Gaisler
  AHB Debug UART                       Cobham Gaisler
  Generic AHB ROM                      Cobham Gaisler
  AHB/APB Bridge                       Cobham Gaisler
  LEON3 Debug Support Unit             Cobham Gaisler
  Single-port AHB SRAM module          Cobham Gaisler
  Modular Timer Unit                   Cobham Gaisler
  Generic UART                         Cobham Gaisler
  Multi-processor Interrupt Ctrl.      Cobham Gaisler
  Modular Timer Unit                   Cobham Gaisler
  General Purpose I/O port             Cobham Gaisler

  Use command 'info sys' to print a detailed report of attached cores

grmon3> info sys
  cpu0      Cobham Gaisler  LEON3 SPARC V8 Processor
            AHB Master 0
  ahbjtag0  Cobham Gaisler  JTAG Debug Link
            AHB Master 1
  ahbuart0  Cobham Gaisler  AHB Debug UART
            AHB Master 2
            APB: 80000400 - 80000500
            Baudrate 115200, AHB frequency 50,00 MHz
  ahbrom0   Cobham Gaisler  Generic AHB ROM
            AHB: 00000000 - 00100000
            32-bit ROM: 1 MB @ 0x00000000
  apbmst0   Cobham Gaisler  AHB/APB Bridge
            AHB: 80000000 - 80100000
  dsu0      Cobham Gaisler  LEON3 Debug Support Unit
            AHB: 90000000 - a0000000
            Device is disabled
  ahbram0   Cobham Gaisler  Single-port AHB SRAM module
            AHB: 40000000 - 40100000
            32-bit SRAM: 64 kB @ 0x40000000
  gptimer0  Cobham Gaisler  Modular Timer Unit
            APB: 80000000 - 80000100
            IRQ: 8
            7-bit scalar, 2 * 16-bit timers, divisor 50
  uart0     Cobham Gaisler  Generic UART
            APB: 80000100 - 80000200
            IRQ: 2
            Baudrate 38343, FIFO debug mode available
  irqmp0    Cobham Gaisler  Multi-processor Interrupt Ctrl.
            APB: 80000200 - 80000300
  gptimer1  Cobham Gaisler  Modular Timer Unit
            APB: 80000300 - 80000400
            IRQ: 8
            8-bit scalar, 2 * 16-bit timers, divisor 50
  gpio0     Cobham Gaisler  General Purpose I/O port
            APB: 80000700 - 80000800

grmon3>