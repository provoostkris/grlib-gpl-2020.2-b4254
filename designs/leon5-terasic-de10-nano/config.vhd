------------------------------------------------------------------------------
--  Configuration package for LEON-5 <> Terrasic DE10 nano Cyclone 5 design
--  rev. 1.0 : 2020 Provoost Kris
------------------------------------------------------------------------------

library techmap;
use techmap.gencomp.all;

package config is
-- Technology and synthesis options
  constant CFG_FABTECH : integer := cyclone5;
  constant CFG_MEMTECH : integer := cyclone5;
  constant CFG_PADTECH : integer := cyclone5;
  constant CFG_TRANSTECH : integer := TT_XGTP0;
  constant CFG_NOASYNC : integer := 0;
  constant CFG_SCAN : integer := 0;
-- Clock generator
  constant CFG_CLKTECH : integer := cyclone5;
  constant CFG_CLKMUL : integer := 2;
  constant CFG_CLKDIV : integer := 2;
  constant CFG_OCLKDIV : integer := 1;
  constant CFG_OCLKBDIV : integer := 0;
  constant CFG_OCLKCDIV : integer := 0;
  constant CFG_PCIDLL : integer := 0;
  constant CFG_PCISYSCLK: integer := 0;
  constant CFG_CLK_NOFB : integer := 0;
  
--LEON5 processor system
  constant CFG_NCPU : integer := (1);
  constant CFG_FPUTYPE : integer := 0;
  constant CFG_AHBW : integer := 32;
  constant CFG_BWMASK : integer := 16#0000#;
  constant CFG_DFIXED : integer := 16#0#;

-- L2 Cache
  constant CFG_L2_EN : integer := 0;
  constant CFG_L2_SIZE : integer := 64;
  constant CFG_L2_WAYS : integer := 1;
  constant CFG_L2_HPROT : integer := 0;
  constant CFG_L2_PEN : integer := 0;
  constant CFG_L2_WT : integer := 0;
  constant CFG_L2_RAN : integer := 0;
  constant CFG_L2_SHARE : integer := 0;
  constant CFG_L2_LSZ : integer := 32;
  constant CFG_L2_MAP : integer := 16#00F0#;
  constant CFG_L2_MTRR : integer := (0);
  constant CFG_L2_EDAC : integer := 0;
  constant CFG_L2_AXI : integer := 0;
  
-- AMBA settings
  constant CFG_DEFMST : integer := (0);
  constant CFG_RROBIN : integer := 1;
  constant CFG_SPLIT : integer := 0;
  constant CFG_FPNPEN : integer := 0;
  constant CFG_AHBIO : integer := 16#FFF#;
  constant CFG_APBADDR : integer := 16#800#;
  constant CFG_AHB_MON : integer := 0;
  constant CFG_AHB_MONERR : integer := 0;
  constant CFG_AHB_MONWAR : integer := 0;
  constant CFG_AHB_DTRACE : integer := 0;
-- DSU UART
  constant CFG_AHB_UART : integer := 1;
-- JTAG based DSU interface
  constant CFG_AHB_JTAG : integer := 1;
-- Ethernet DSU
  constant CFG_DSU_ETH : integer := 0 + 0 + 0;
  constant CFG_ETH_BUF : integer := 1;
  constant CFG_ETH_IPM : integer := 16#C0A8#;
  constant CFG_ETH_IPL : integer := 16#0033#;
  constant CFG_ETH_ENM : integer := 16#020000#;
  constant CFG_ETH_ENL : integer := 16#000009#;
-- PROM/SRAM controller
  constant CFG_SRCTRL : integer := 0;
  constant CFG_SRCTRL_PROMWS : integer := 0;
  constant CFG_SRCTRL_RAMWS : integer := 0;
  constant CFG_SRCTRL_IOWS : integer := 0;
  constant CFG_SRCTRL_RMW : integer := 0;
  constant CFG_SRCTRL_8BIT : integer := 0;
  constant CFG_SRCTRL_SRBANKS : integer := 1;
  constant CFG_SRCTRL_BANKSZ : integer := 0;
  constant CFG_SRCTRL_ROMASEL : integer := 0;
-- LEON2 memory controller
  constant CFG_MCTRL_LEON2 : integer := 0;
  constant CFG_MCTRL_RAM8BIT : integer := 0;
  constant CFG_MCTRL_RAM16BIT : integer := 0;
  constant CFG_MCTRL_5CS : integer := 0;
  constant CFG_MCTRL_SDEN : integer := 1;
  constant CFG_MCTRL_SEPBUS : integer := 0;
  constant CFG_MCTRL_INVCLK : integer := 0;
  constant CFG_MCTRL_SD64 : integer := 0;
  constant CFG_MCTRL_PAGE : integer := 1 + 0;
-- SDRAM controller
  constant CFG_SDCTRL : integer := 0;
  constant CFG_SDCTRL_INVCLK : integer := 0;
  constant CFG_SDCTRL_SD64 : integer := 0;
  constant CFG_SDCTRL_PAGE : integer := 0 + 0;
-- AHB status register
  constant CFG_AHBSTAT : integer := 0;
  constant CFG_AHBSTATN : integer := 1;
-- SPI memory controller
  constant CFG_SPIMCTRL : integer := 0;
  constant CFG_SPIMCTRL_SDCARD : integer := 0;
  constant CFG_SPIMCTRL_READCMD : integer := 16#0#;
  constant CFG_SPIMCTRL_DUMMYBYTE : integer := 0;
  constant CFG_SPIMCTRL_DUALOUTPUT : integer := 0;
  constant CFG_SPIMCTRL_SCALER : integer := 1;
  constant CFG_SPIMCTRL_ASCALER : integer := 1;
  constant CFG_SPIMCTRL_PWRUPCNT : integer := 0;
  constant CFG_SPIMCTRL_OFFSET : integer := 16#0#;
-- AHB ROM
  constant CFG_AHBROMEN : integer := 1;
  constant CFG_AHBROPIP : integer := 0;
  constant CFG_AHBRODDR : integer := 16#000#;
  constant CFG_ROMADDR : integer := 16#000#;
  constant CFG_ROMMASK : integer := 16#E00# + 16#000#;
-- AHB RAM
  constant CFG_AHBRAMEN : integer := 1;
  constant CFG_AHBRSZ   : integer := 2**7;
  constant CFG_AHBRADDR : integer := 16#400#;
  constant CFG_AHBRPIPE : integer := 0;
-- Gaisler Ethernet core
  constant CFG_GRETH : integer := 0;
  constant CFG_GRETH1G : integer := 0;
  constant CFG_ETH_FIFO : integer := 8;
  constant CFG_GRETH_FMC : integer := 0;
-- CAN 2.0 interface
  constant CFG_CAN : integer := 0;
  constant CFG_CANIO : integer := 16#0#;
  constant CFG_CANIRQ : integer := 0;
  constant CFG_CANLOOP : integer := 0;
  constant CFG_CAN_SYNCRST : integer := 0;
  constant CFG_CANFT : integer := 0;
-- GRPCI2 interface
  constant CFG_GRPCI2_MASTER : integer := 0;
  constant CFG_GRPCI2_TARGET : integer := 0;
  constant CFG_GRPCI2_DMA : integer := 0;
  constant CFG_GRPCI2_VID : integer := 16#0#;
  constant CFG_GRPCI2_DID : integer := 16#0#;
  constant CFG_GRPCI2_CLASS : integer := 16#0#;
  constant CFG_GRPCI2_RID : integer := 16#0#;
  constant CFG_GRPCI2_CAP : integer := 16#40#;
  constant CFG_GRPCI2_NCAP : integer := 16#0#;
  constant CFG_GRPCI2_BAR0 : integer := 0;
  constant CFG_GRPCI2_BAR1 : integer := 0;
  constant CFG_GRPCI2_BAR2 : integer := 0;
  constant CFG_GRPCI2_BAR3 : integer := 0;
  constant CFG_GRPCI2_BAR4 : integer := 0;
  constant CFG_GRPCI2_BAR5 : integer := 0;
  constant CFG_GRPCI2_FDEPTH : integer := 3;
  constant CFG_GRPCI2_FCOUNT : integer := 2;
  constant CFG_GRPCI2_ENDIAN : integer := 0;
  constant CFG_GRPCI2_DEVINT : integer := 0;
  constant CFG_GRPCI2_DEVINTMSK : integer := 16#0#;
  constant CFG_GRPCI2_HOSTINT : integer := 0;
  constant CFG_GRPCI2_HOSTINTMSK: integer := 16#0#;
  constant CFG_GRPCI2_TRACE : integer := 0;
  constant CFG_GRPCI2_TRACEAPB : integer := 0;
  constant CFG_GRPCI2_BYPASS : integer := 0;
  constant CFG_GRPCI2_EXTCFG : integer := (0);
-- PCI arbiter
  constant CFG_PCI_ARB : integer := 0;
  constant CFG_PCI_ARBAPB : integer := 0;
  constant CFG_PCI_ARB_NGNT : integer := 4;
-- Spacewire interface
  constant CFG_SPW_EN : integer := 0;
  constant CFG_SPW_NUM : integer := 1;
  constant CFG_SPW_AHBFIFO : integer := 4;
  constant CFG_SPW_RXFIFO : integer := 16;
  constant CFG_SPW_RMAP : integer := 0;
  constant CFG_SPW_RMAPBUF : integer := 4;
  constant CFG_SPW_RMAPCRC : integer := 0;
  constant CFG_SPW_NETLIST : integer := 0;
  constant CFG_SPW_FT : integer := 0;
  constant CFG_SPW_GRSPW : integer := 2;
  constant CFG_SPW_RXUNAL : integer := 0;
  constant CFG_SPW_DMACHAN : integer := 1;
  constant CFG_SPW_PORTS : integer := 1;
  constant CFG_SPW_INPUT : integer := 2;
  constant CFG_SPW_OUTPUT : integer := 0;
  constant CFG_SPW_RTSAME : integer := 0;
-- UART 1
  constant CFG_UART1_ENABLE : integer := 1;
  constant CFG_UART1_FIFO : integer := 4;
-- UART 2
  constant CFG_UART2_ENABLE : integer := 0;
  constant CFG_UART2_FIFO : integer := 1;
-- LEON3 interrupt controller
  constant CFG_IRQ3_ENABLE : integer := 1;
  constant CFG_IRQ3_NSEC : integer := 0;
-- Modular timer
  constant CFG_GPT_ENABLE : integer := 1;
  constant CFG_GPT_NTIM : integer := (2);
  constant CFG_GPT_SW : integer := (8);
  constant CFG_GPT_TW : integer := (16);
  constant CFG_GPT_IRQ : integer := (8);
  constant CFG_GPT_SEPIRQ : integer := 1;
  constant CFG_GPT_WDOGEN : integer := 1;
  constant CFG_GPT_WDOG : integer := 16#FFFF#;
-- GPIO port
  constant CFG_GRGPIO_ENABLE : integer := 1;
  constant CFG_GRGPIO_IMASK : integer := 16#0000#;
  constant CFG_GRGPIO_WIDTH : integer := (8);
-- I2C master
  constant CFG_I2C_ENABLE : integer := 0;
-- GRLIB debugging
  constant CFG_DUART : integer := 1;
-- LEON5 subsystem debugging
  constant CFG_DISAS : integer := 0;
  constant CFG_AHBTRACE: integer := 0;
-- Xilinx MIG 7-Series
  constant CFG_MIG_7SERIES : integer := 0;
  constant CFG_MIG_7SERIES_MODEL : integer := 0;
end;
