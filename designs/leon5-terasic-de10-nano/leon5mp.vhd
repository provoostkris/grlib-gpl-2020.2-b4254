------------------------------------------------------------------------------
--  TOP level design file for LEON-5 <> Terrasic DE10 nano Cyclone 5 design
--  rev. 1.0 : 2020 Provoost Kris
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  LEON3 Demonstration design
--  Copyright (C) 2013 Aeroflex Gaisler
------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2015 - 2019, Cobham Gaisler
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;
use techmap.allclkgen.all;
library gaisler;
use gaisler.memctrl.all;
use gaisler.leon3.all;
use gaisler.leon5.all;
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.i2c.all;
use gaisler.jtag.all;
--pragma translate_off
use gaisler.sim.all;
--pragma translate_on
library esa;
use esa.memoryctrl.all;
use work.config.all;

entity leon5mp is
  generic (
    fabtech   : integer := CFG_FABTECH; -- support for cyclone 5 added in libs
    memtech   : integer := CFG_MEMTECH; -- support for cyclone 5 added in libs
    padtech   : integer := CFG_PADTECH; -- using default tech
    clktech   : integer := CFG_CLKTECH; -- using altera macro function for PLL
    disas     : integer := CFG_DISAS;
    ahbtrace  : integer := CFG_AHBTRACE;
    dbguart   : integer := CFG_DUART
    );
  port (
    FPGA_CLK1_50      : in    std_ulogic; --! FPGA clock 1 input 50 MHz
    FPGA_CLK2_50      : in    std_ulogic; --! FPGA clock 2 input 50 MHz
    FPGA_CLK3_50      : in    std_ulogic; --! FPGA clock 3 input 50 MHz

   -- Buttons & LEDs
    KEY               : in    std_logic_vector(1 downto 0); --! Push button - debounced
    SW                : in    std_logic_vector(3 downto 0); --! Slide button
    Led               : out   std_logic_vector(7 downto 0); --! indicators

    -- GPIO banks
    GPIO_0            : in       std_logic_vector(35 downto 0);
    GPIO_1            : out      std_logic_vector(35 downto 0)
  );
end;

architecture rtl of leon5mp is

--constant maxahbm : integer := CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG+CFG_GRETH;
-- constant maxahbm : integer := 16;
-- constant maxahbs : integer := 16;
-- constant maxapbs : integer := CFG_IRQ3_ENABLE+CFG_GPT_ENABLE+CFG_GRGPIO_ENABLE+CFG_AHBSTAT+CFG_AHBSTAT;

-- CLK & RST signals
signal clkm, rstn         : std_ulogic;
signal rstraw             : std_logic;
signal lock               : std_logic;
  
signal vcc, gnd   : std_logic;
signal memi  : memory_in_type;
signal memo  : memory_out_type;
signal wpo   : wprot_out_type;

signal perf : l3stat_in_type;

signal cgi   : clkgen_in_type;
signal cgo   : clkgen_out_type;
signal u1i, dui : uart_in_type;
signal u1o, duo : uart_out_type;

-- signal gpti : gptimer_in_type;
-- signal gpto : gptimer_out_type;

-- signal gpioi : gpio_in_type;
-- signal gpioo : gpio_out_type;

signal rst : std_ulogic;
signal tck, tckn, tms, tdi, tdo : std_ulogic;

-- signal i2ci, dvi_i2ci : i2c_in_type;
-- signal i2co, dvi_i2co : i2c_out_type;

constant clock_mult : integer := CFG_CLKMUL;      --! Clock multiplier
constant clock_div  : integer := CFG_CLKDIV;      --! Clock divider
constant BOARD_FREQ : integer := 50_000;          --! CLK input frequency in KHz
constant CPU_FREQ   : integer := BOARD_FREQ * clock_mult / clock_div;  --! CPU freq in KHz

signal stati : ahbstat_in_type;

signal dsurx_int   : std_logic;
signal dsutx_int   : std_logic;
signal dsuctsn_int : std_logic;
signal dsurtsn_int : std_logic;

signal dsu_sel : std_logic;

signal dsuen, cpu0errn, dsubreak : std_ulogic;

function max(x,y: integer) return integer is
begin
  if x>y then return x; else return y; end if;
end max;

-- Bus indexes
constant hmidx_cpu     : integer := 0;
constant hmidx_greth   : integer := hmidx_cpu     + CFG_NCPU;
constant hmidx_free    : integer := hmidx_greth   + CFG_GRETH;
constant l5sys_nextmst : integer := max(hmidx_free-CFG_NCPU, 1);

constant hdidx_ahbuart : integer := 0;
constant hdidx_ahbjtag : integer := hdidx_ahbuart + CFG_AHB_UART;
constant hdidx_greth   : integer := hdidx_ahbjtag + CFG_AHB_JTAG;
constant hdidx_free    : integer := hdidx_greth   + CFG_GRETH;
constant l5sys_ndbgmst : integer := max(hdidx_free, 1);

constant hsidx_mctrl   : integer := 0;
constant hsidx_l2c     : integer := hsidx_mctrl  + CFG_MCTRL_LEON2;
constant hsidx_mig     : integer := hsidx_l2c    + CFG_L2_EN;
constant hsidx_ahbram  : integer := hsidx_mig    + CFG_MIG_7SERIES;
constant hsidx_ahbrom  : integer := hsidx_ahbram + CFG_AHBRAMEN;
constant hsidx_ahbrep  : integer := hsidx_ahbrom + CFG_AHBROMEN;
constant hsidx_free    : integer := hsidx_ahbrep
--pragma translate_off
                                    + 1
--pragma translate_on
                                    ;
constant l5sys_nextslv : integer := max(hsidx_free, 1);

constant pidx_ahbuart  : integer := 0;
constant pidx_mctrl    : integer := pidx_ahbuart + CFG_AHB_UART;
constant pidx_mig      : integer := pidx_mctrl   + CFG_MCTRL_LEON2;
constant pidx_greth    : integer := pidx_mig     + 1;
constant pidx_rgmii    : integer := pidx_greth   + CFG_GRETH;
constant pidx_ahbstat  : integer := pidx_rgmii   + CFG_GRETH;
constant pidx_i2cmst   : integer := pidx_ahbstat + CFG_AHBSTAT;
constant pidx_free     : integer := pidx_i2cmst  + CFG_I2C_ENABLE;
constant l5sys_nextapb : integer := pidx_free;

signal ahbmi: ahb_mst_in_type;
signal ahbmo: ahb_mst_out_vector_type(CFG_NCPU+l5sys_nextmst-1 downto CFG_NCPU);
signal ahbsi: ahb_slv_in_type;
signal ahbso: ahb_slv_out_vector_type(l5sys_nextslv-1 downto 0);
signal dbgmi: ahb_mst_in_vector_type(l5sys_ndbgmst-1 downto 0);
signal dbgmo: ahb_mst_out_vector_type(l5sys_ndbgmst-1 downto 0);

signal greth_dbgmi: ahb_mst_in_type;
signal greth_dbgmo: ahb_mst_out_type;

signal apbi  : apb_slv_in_type;
signal apbo  : apb_slv_out_vector := (others => apb_none);

signal mig_ahbsi : ahb_slv_in_type;
signal mig_ahbso : ahb_slv_out_type;


-- signals used for mapping BOARD pins
signal clk          : std_ulogic;
signal rst_n        : std_ulogic;
  
begin

----------------------------------------------------------------------
---  Pin mapping -------------------------------------
----------------------------------------------------------------------
clk_pad : clkpad  
  generic map   (tech => padtech) 
  port map      (FPGA_CLK1_50, clk); 

resetn_pad : inpad 
  generic map   (tech => padtech) 
  port map      (KEY(0), rst_n); 
  
----------------------------------------------------------------------
---  Reset and Clock generation  -------------------------------------
----------------------------------------------------------------------

  vcc <= '1'; 
  gnd <= '0';

  cgi.pllctrl <= "00";
  cgi.pllrst  <= rstraw;

  -- reset generator
  rst0 : rstgen 
    generic map (acthigh => 0)
    port map  ( rst_n,clkm,lock,rstn,rstraw);
  
  lock <= cgo.clklock;
  lock_pad : outpad generic map  (tech  => padtech) port map (LED(6), lock);

  -- clock generator
  clkgen0 : clkgen
    generic map ( clktech,clock_mult,clock_div, 
                  0,0,0,0,0,BOARD_FREQ,0)
    port map    ( clk,gnd,clkm,open, 
                  open,open,open,cgi,cgo,open,open,open);

  ----------------------------------------------------------------------
  -- LEON5 processor system
  ----------------------------------------------------------------------

  l5sys : leon5sys
    generic map (
      fabtech  => fabtech,
      memtech  => memtech,
      ncpu     => CFG_NCPU,
      nextmst  => l5sys_nextmst,
      nextslv  => l5sys_nextslv,
      nextapb  => l5sys_nextapb,
      ndbgmst  => l5sys_ndbgmst,
      cached   => CFG_DFIXED,
      wbmask   => CFG_BWMASK,
      busw     => CFG_AHBW,
      fpuconf  => CFG_FPUTYPE,
      disas    => disas,
      ahbtrace => ahbtrace
      )
     port map (
      clk      => clkm,
      rstn     => rstn,
      ahbmi    => ahbmi,
      ahbmo    => ahbmo(CFG_NCPU+l5sys_nextmst-1 downto CFG_NCPU),
      ahbsi    => ahbsi,
      ahbso    => ahbso(l5sys_nextslv-1 downto 0),
      dbgmi    => dbgmi,
      dbgmo    => dbgmo,
      apbi     => apbi,
      apbo     => apbo,
      dsuen    => dsuen,
      dsubreak => dsubreak,
      cpu0errn => cpu0errn,
      uarti    => u1i,
      uarto    => u1o
      );

  nomst: if hmidx_free=CFG_NCPU generate
    ahbmo(CFG_NCPU) <= ahbm_none;
  end generate;
  noslv: if hsidx_free=0 generate
    ahbso(0) <= ahbs_none;
  end generate;

  dsuen <= '1';
  led1_pad          : outpad generic map (tech => padtech)    port map (led(1), cpu0errn);
  dsui_break_pad    : inpad  generic map (tech => padtech)    port map (KEY(1), dsubreak);
  dsuact_pad        : outpad generic map (tech => padtech)    port map (led(0), dsuen);

  -- Debug UART
  dcomgen : if CFG_AHB_UART = 1 generate
    dcom0 : ahbuart
      generic map (hindex => hdidx_ahbuart, pindex => pidx_ahbuart, paddr => 7)
      port map (rstn, clkm, dui, duo, apbi, apbo(pidx_ahbuart), dbgmi(hdidx_ahbuart), dbgmo(hdidx_ahbuart));
    dui.extclk <= '0';
  end generate;

  sw4_pad : inpad generic map (tech => padtech)      port map (SW(3), dsu_sel);

  dsutx_int   <= duo.txd     when dsu_sel = '1' else u1o.txd;
  dui.rxd     <= dsurx_int   when dsu_sel = '1' else '1';
  u1i.rxd     <= dsurx_int   when dsu_sel = '0' else '1';
  dsurtsn_int <= duo.rtsn    when dsu_sel = '1' else u1o.rtsn;
  dui.ctsn    <= dsuctsn_int when dsu_sel = '1' else '1';
  u1i.ctsn    <= dsuctsn_int when dsu_sel = '0' else '1';

  dsurx_pad   : inpad  generic map (tech => padtech) port map (GPIO_0(35), dsurx_int);
  dsutx_pad   : outpad generic map (tech => padtech) port map (GPIO_1(00), dsutx_int);
  dsuctsn_pad : inpad  generic map (tech => padtech) port map (GPIO_0(34), dsuctsn_int);
  dsurtsn_pad : outpad generic map (tech => padtech) port map (GPIO_1(01), dsurtsn_int);

  -----------------------------------------------------------------------------
  -- JTAG debug link
  -----------------------------------------------------------------------------
  ahbjtaggen0 :if CFG_AHB_JTAG = 1 generate
    ahbjtag0 : ahbjtag generic map(tech => fabtech, hindex => hdidx_ahbjtag)
      port map(rstn, clkm, tck, tms, tdi, tdo, dbgmi(hdidx_ahbjtag), dbgmo(hdidx_ahbjtag),
               open, open, open, open, open, open, open, gnd);
  end generate;

----------------------------------------------------------------------
---  SPI Memory Controller--------------------------------------------
----------------------------------------------------------------------
--- no support foreseen

----------------------------------------------------------------------
---  Memory controllers ----------------------------------------------
----------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- L2 cache, optionally covering DDR3 SDRAM memory controller
  -----------------------------------------------------------------------------
  nol2c : if CFG_L2_EN = 0 generate
    -- ahbso(hsidx_mig) <= mig_ahbso;
    mig_ahbsi <= ahbsi;
    perf <= l3stat_in_none;
  end generate;

-----------------------------------------------------------------------
---  ETHERNET ---------------------------------------------------------
-----------------------------------------------------------------------

  edcl0 : if (CFG_GRETH=1 and CFG_DSU_ETH=1) generate
    greth_dbgmi         <= dbgmi(hdidx_greth);
    dbgmo(hdidx_greth)  <= greth_dbgmo;
  end generate;
  noedcl0 : if not (CFG_GRETH=1 and CFG_DSU_ETH=1) generate
    greth_dbgmi         <= ahbm_in_none;
  end generate;

----------------------------------------------------------------------
---  I2C Controller --------------------------------------------------
----------------------------------------------------------------------
--- no support foreseen

-----------------------------------------------------------------------
---  AHBSTAT  ---------------------------------------------------------
-----------------------------------------------------------------------

  ahbs : if CFG_AHBSTAT = 1 generate   -- AHB status register
    stati <= ahbstat_in_none;
    ahbstat0 : ahbstat generic map (pindex => pidx_ahbstat, paddr => 15, pirq => 7,
   nftslv => CFG_AHBSTATN)
      port map (rstn, clkm, ahbmi, ahbsi, stati, apbi, apbo(pidx_ahbstat));
  end generate;

-----------------------------------------------------------------------
---  AHB ROM ----------------------------------------------------------
-----------------------------------------------------------------------

  bpromgen : if CFG_AHBROMEN /= 0 generate
    brom : entity work.ahbrom
      generic map (hindex => hsidx_ahbrom, haddr => CFG_AHBRODDR, pipe => CFG_AHBROPIP)
      port map ( rstn, clkm, ahbsi, ahbso(hsidx_ahbrom));
  end generate;

-----------------------------------------------------------------------
---  AHB RAM ----------------------------------------------------------
-----------------------------------------------------------------------

  ocram : if CFG_AHBRAMEN = 1 generate
    ahbram0 : ahbram generic map (hindex => hsidx_ahbram, haddr => CFG_AHBRADDR,
   tech => CFG_MEMTECH, kbytes => CFG_AHBRSZ, pipe => CFG_AHBRPIPE)
    port map ( rstn, clkm, ahbsi, ahbso(hsidx_ahbram));
  end generate;

-----------------------------------------------------------------------
---  Test report module  ----------------------------------------------
-----------------------------------------------------------------------

  -- pragma translate_off
  test0 : ahbrep generic map (hindex => hsidx_ahbrep, haddr => 16#200#)
    port map (rstn, clkm, ahbsi, ahbso(hsidx_ahbrep));
  -- pragma translate_on

 -----------------------------------------------------------------------
 ---  Boot message  ----------------------------------------------------
 -----------------------------------------------------------------------

 -- pragma translate_off
   x : report_design
   generic map (
    msg1 => "LEON/GRLIB Xilinx KC705 Demonstration design",
    fabtech => tech_table(fabtech), memtech => tech_table(memtech),
    mdel => 1
   );
 -- pragma translate_on
 end;
