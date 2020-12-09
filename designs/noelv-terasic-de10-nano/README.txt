-----------------------------------------------------------------------------
-- NOELV Demonstration design running on a Terasic DE10-nano Cyclone5 KIT
-- rev. 1.0 : 2020 Provoost Kris
------------------------------------------------------------------------------

Info:
The reference design from GRLIB is used as a base for setting up a NOELV demonstration design. 
Source code is modified and expanded to support the Terasic DE10-nano.
Tech support for cyclone5 device is added in the libraries.
The work has been done in free time, no guarantees / support are provided with the design.

Note: 
The Cyclone 5 SoC has a dual core on chip ARM. Obviously the NOEL is less performant then these CPU's.
The idea behind the porting is to have the NOEL available on a low end FPGA. The port should work for 
other Cyclone 5 families as well. 

Implementation:
- The CPU is a single core
- It will run at 50 MHz, using a PLL
- A small amount of onchip SRAM is provided
- GPIO_0 is mapped (in the assigment file) for input only
- GPIO_1 is mapped (in the assigment file) for output only
- KEY(0) is for RESET of the system
- KEY(1) is for the DSU break control
- SW(0) (down) 
- SW(1) (down) 
- SW(2) (down) 
- SW(3) (up) is for the DSU selection control
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
  NOEL-V RISC-V Processor              Cobham Gaisler
  AHB Debug UART                       Cobham Gaisler
  JTAG Debug Link                      Cobham Gaisler
  Single-port AHB SRAM module          Cobham Gaisler
  Generic AHB ROM                      Cobham Gaisler
  Xilinx MIG Controller                Cobham Gaisler
  AHB/APB Bridge                       Cobham Gaisler
  RISC-V CLINT                         Cobham Gaisler
  RISC-V PLIC                          Cobham Gaisler
  RISC-V Debug Module                  Cobham Gaisler
  AMBA Trace Buffer                    Cobham Gaisler
  General Purpose I/O port             Cobham Gaisler
  Generic UART                         Cobham Gaisler
  Version and Revision Register        Cobham Gaisler
  Modular Timer Unit                   Cobham Gaisler

  Use command 'info sys' to print a detailed report of attached cores

grmon3> info sys
  cpu0      Cobham Gaisler  NOEL-V RISC-V Processor
            AHB Master 0
  ahbuart0  Cobham Gaisler  AHB Debug UART
            AHB Master 2
            APB: 80000e00 - 80000f00
            Baudrate 115200, AHB frequency 50,00 MHz
  ahbjtag0  Cobham Gaisler  JTAG Debug Link
            AHB Master 3
  ahbram0   Cobham Gaisler  Single-port AHB SRAM module
            AHB: 40000000 - 40100000
            32-bit SRAM: 64 kB @ 0x40000000
  ahbrom0   Cobham Gaisler  Generic AHB ROM
            AHB: 00000000 - 00100000
            32-bit ROM: 1 MB @ 0x00000000
  mig0      Cobham Gaisler  Xilinx MIG Controller
            AHB: 40000000 - 80000000
            SDRAM: 8 Mbyte
  apbmst0   Cobham Gaisler  AHB/APB Bridge
            AHB: 80000000 - 80100000
  clint0    Cobham Gaisler  RISC-V CLINT
            AHB: e0100000 - e0200000
  plic0     Cobham Gaisler  RISC-V PLIC
            AHB: 84000000 - 88000000
            4 contexts, 32 interrupt sources
  dm0       Cobham Gaisler  RISC-V Debug Module
            AHB: 90000000 - a0000000
            hart0: DXLEN 64, MXLEN 64, SXLEN 64, UXLEN 64
                   ISA A D F I M,  Modes M S U
                   Stack pointer 0x4000fff0
                   icache not implemented
                   dcache not implemented
                   2 triggers
  ahbtrace0 Cobham Gaisler  AMBA Trace Buffer
            AHB: fff00000 - fff20000
            Trace buffer size: 128 lines
  gpio0     Cobham Gaisler  General Purpose I/O port
            APB: 80000400 - 80000500
  uart0     Cobham Gaisler  Generic UART
            APB: 80000100 - 80000200
            IRQ: 1
            Baudrate 38343, FIFO debug mode available
  version0  Cobham Gaisler  Version and Revision Register
            APB: 80000200 - 80000300
            Version 0, Revision 7
  gptimer0  Cobham Gaisler  Modular Timer Unit
            APB: 80000300 - 80000400
            IRQ: 2
            16-bit scalar, 2 * 32-bit timers, divisor 50

grmon3>