-----------------------------------------------------------------------------
-- LEON5 Demonstration design running on a Terasic DE10-nano Cyclone5 KIT
-- rev. 1.0 : 2020 Provoost Kris
------------------------------------------------------------------------------

Info:
The minimal reference design from GRLIB is used as a base for setting up a LEON5 demonstration design. 
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
- The quartus .qpf and .qdf are copied to windows with Quartus 18.1 installed and Cyclone 5 device pack
  >> open the Quartus project
  >> "ctrl + l"
- After +/- 75 min. the compilation completes.
  >> open the programmer and program the .sof from the ../output_files/ to the FPGA
  
Debug:
- Connect a FTDI breakout adapter to the windows machine
  >> FTDI.GND <> GPIO1.12
  >> FTDI.TX  <> GPIO0.40
  >> FTDI.RX  <> GPIO1.01
  >>             GPIO signals as listed on the board (not the VHDL)
- Download GRMON2 evaluation from gaisler
  >> unpack grmon
  >> launch from the command line : grmon -uart com3
  >> see output below for commands and responses


output captured:
----------------


C:\Users\Kris\Downloads\grmon-eval-64-3.2.5\grmon-eval-3.2.5\windows\bin64>grmon -uart com3

  GRMON debug monitor v3.2.5 64-bit eval version

  Copyright (C) 2020 Cobham Gaisler - All rights reserved.
  For latest updates, go to http://www.gaisler.com/
  Comments or bug-reports to support@gaisler.com

  This eval version will expire on 20/02/2021

  GRLIB build version: 4254
  Detected frequency:  50,0 MHz

  Component                            Vendor
  LEON5 SPARC V8 Processor             Cobham Gaisler
  LEON5 Debug Support Unit             Cobham Gaisler
  AHB Debug UART                       Cobham Gaisler
  JTAG Debug Link                      Cobham Gaisler
  Single-port AHB SRAM module          Cobham Gaisler
  Generic AHB ROM                      Cobham Gaisler
  AHB/APB Bridge                       Cobham Gaisler
  Generic UART                         Cobham Gaisler
  Multi-processor Interrupt Ctrl.      Cobham Gaisler
  Modular Timer Unit                   Cobham Gaisler

  Use command 'info sys' to print a detailed report of attached cores

grmon3> info sys
  cpu0      Cobham Gaisler  LEON5 SPARC V8 Processor
            AHB Master 0
  dsu0      Cobham Gaisler  LEON5 Debug Support Unit
            AHB Master 2
            AHB: 90000000 - a0000000
            AHB trace: 256 lines, 32-bit bus
            CPU0:  win 8, nwp 2, itrace 256, V8 mul/div, srmmu, lddel 1, GRFPU
                   stack pointer 0x40000ff0I64x
                   icache 4 * 4 kB, 32 B/line, rnd
                   dcache 4 * 4 kB, 32 B/line, rnd
  ahbuart0  Cobham Gaisler  AHB Debug UART
            AHB Master 3
            APB: 80000700 - 80000800
            Baudrate 115200, AHB frequency 50,00 MHz
  ahbjtag0  Cobham Gaisler  JTAG Debug Link
            AHB Master 4
  ahbram0   Cobham Gaisler  Single-port AHB SRAM module
            AHB: 40000000 - 40100000
            32-bit SRAM: 4 kB @ 0x40000000
  ahbrom0   Cobham Gaisler  Generic AHB ROM
            AHB: 00000000 - 00100000
            32-bit ROM: 1 MB @ 0x00000000
  apbmst0   Cobham Gaisler  AHB/APB Bridge
            AHB: 80000000 - 80100000
  uart0     Cobham Gaisler  Generic UART
            APB: 80000100 - 80000200
            IRQ: 2
            Baudrate 38343, FIFO debug mode available
  irqmp0    Cobham Gaisler  Multi-processor Interrupt Ctrl.
            APB: 80000200 - 80000300
            EIRQ: 12
  gptimer0  Cobham Gaisler  Modular Timer Unit
            APB: 80000300 - 80000400
            IRQ: 8
            16-bit scalar, 2 * 32-bit timers, divisor 50

grmon3> exit

Exiting GRMON

C:\Users\Kris\Downloads\grmon-eval-64-3.2.5\grmon-eval-3.2.5\windows\bin64>