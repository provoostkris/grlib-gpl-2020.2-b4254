------------------------------------------------------------------------------
--  TOP level design file for NOEL-V <> Terrasic DE10 nano Cyclone 5 design
--  rev. 1.0 : 2020 Provoost Kris
-----------------------------------------------------------------------------------------------------------------------------------------------------------
--  Based on VC707 Demonstration design
------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2015 - 2020, Cobham Gaisler
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
library grlib, techmap;
use grlib.amba.all;
use grlib.devices.all;
use grlib.stdlib.all;
use grlib.config.all;
use grlib.config_types.all;
use techmap.gencomp.all;
use techmap.allclkgen.all;

library gaisler;
use gaisler.noelv.all;
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.i2c.all;
use gaisler.spi.all;
use gaisler.net.all;
use gaisler.jtag.all;
use gaisler.grusb.all;
use gaisler.l2cache.all;
use gaisler.subsys.all;
use gaisler.axi.all;
use gaisler.plic.all;
use gaisler.riscv.all;
use gaisler.noelv.all;
-- pragma translate_off
use gaisler.sim.all;
library unisim;
use unisim.all;
-- pragma translate_on

use work.config.all;

entity noelvmp is
    generic (
      fabtech                 : integer := CFG_FABTECH;
      memtech                 : integer := CFG_MEMTECH;
      padtech                 : integer := CFG_PADTECH;
      clktech                 : integer := CFG_CLKTECH;
      disas                   : integer := CFG_DISAS;   -- Enable disassembly to console
      dbguart                 : integer := CFG_DUART;   -- Print UART on console
      pclow                   : integer := CFG_PCLOW;
      USE_MIG_INTERFACE_MODEL : boolean := true
      -- autonegotiation         : integer := 1;
      -- riscv_mmu               : integer := 2;
      -- pmp_no_tor              : integer :=  0;  -- Disable PMP TOR
      -- pmp_entries             : integer :=  8;  -- Implemented PMP registers
      -- pmp_g                   : integer :=  1   -- PMP grain is 2^(pmp_g + 2) bytes
      -- pmp_msb                 : integer := 31   -- High bit for PMP checks
      
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

architecture rtl of noelvmp is

constant ncpu     : integer := 1;
constant nextslv  : integer := 3
-- pragma translate_off
                               + 1
-- pragma translate_on
                               ;
constant ndbgmst  : integer := 3
                               ;

--constant maxahbm : integer := CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG+CFG_GRETH+CFG_GRUSBHC+CFG_GRUSBDC+CFG_GRUSB_DCL;
constant maxahbm : integer := 16;
--constant maxahbs : integer := 1+CFG_DSU+CFG_MCTRL_LEON2+CFG_AHBROMEN+CFG_AHBRAMEN+2+CFG_GRUSBDC;
constant maxahbs : integer := 16;
constant maxapbs : integer := CFG_IRQ3_ENABLE+CFG_GPT_ENABLE+CFG_GRGPIO_ENABLE+CFG_AHBSTAT+CFG_AHBSTAT+CFG_GRUSBHC+CFG_GRUSBDC+CFG_PRC;

constant clock_mult : integer := CFG_CLKMUL;      --! Clock multiplier
constant clock_div  : integer := CFG_CLKDIV;      --! Clock divider
constant BOARD_FREQ : integer := 50_000;          --! CLK input frequency in KHz
constant CPU_FREQ   : integer := BOARD_FREQ * clock_mult / clock_div;  --! CPU freq in KHz


signal vcc, gnd   : std_logic;

signal apbi  : apb_slv_in_vector;
signal apbo  : apb_slv_out_vector := (others => apb_none);
signal apbi1 : apb_slv_in_type;
signal apbo1 : apb_slv_out_vector := (others => apb_none);
signal apbi2 : apb_slv_in_type;
signal apbo2 : apb_slv_out_vector := (others => apb_none);
signal ahbsi : ahb_slv_in_type;
signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
signal ahbmi : ahb_mst_in_type;
signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);
signal mig_ahbsi : ahb_slv_in_type;                            
signal mig_ahbso : ahb_slv_out_type;
  
signal aximi : axi_somi_type;
signal aximo : axi4_mosi_type;

signal clkm : std_ulogic := '0';
signal rstn, rstraw : std_ulogic;

signal cgi, cgi2, cgiu   : clkgen_in_type;
signal cgo, cgo2, cgou   : clkgen_out_type;
signal u1i, u2i, dui     : uart_in_type;
signal u1o, u2o, duo     : uart_out_type;

signal gpti : gptimer_in_type;
signal gpto : gptimer_out_type;

signal gpioi : gpio_in_type;
signal gpioo : gpio_out_type;

signal lock, rst : std_ulogic;
signal tck, tckn, tms, tdi, tdo : std_ulogic;

signal stati : ahbstat_in_type;

signal dsurx_int   : std_logic; 
signal dsutx_int   : std_logic; 
signal dsuctsn_int : std_logic;
signal dsurtsn_int : std_logic;
signal dsu_sel     : std_logic;

signal ldsuen     : std_logic;
signal ldsubreak  : std_logic;
signal lcpu0errn  : std_logic;
signal dbgmi      : ahb_mst_in_vector_type(ndbgmst-1 downto 0);
signal dbgmo      : ahb_mst_out_vector_type(ndbgmst-1 downto 0);

-- NOELV
signal ext_irqi       : std_logic_vector(15 downto 0);
signal cpurstn        : std_ulogic;

-- Memory
signal mem_aximi      : axi_somi_type;
signal mem_aximo      : axi_mosi_type;

constant mig_hindex : integer := 2
-- pragma translate_off
                                 + 1
-- pragma translate_on
                                 ;

constant mig_hconfig : ahb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_MIG_7SERIES, 0, 0, 0),
  4 => ahb_membar(16#400#, '1', '1', 16#C00#),
  others => zero32);

-- signals used for mapping BOARD pins to LEON ports
signal clk          : std_ulogic;
signal rst_n        : std_ulogic;

attribute keep         : boolean;
attribute syn_keep     : string;
attribute keep of clkm : signal is true;
  
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
  rstn_pad : outpad generic map  (tech  => padtech) port map (LED(7), rst_n);

  -- clock generator
  clkgen0 : clkgen
    generic map ( clktech,clock_mult,clock_div, 
                  0,0,0,0,0,BOARD_FREQ,0)
    port map    ( clk,gnd,clkm,open, 
                  open,open,open,cgi,cgo,open,open,open);

---------------------------------------------------------------------- 
---  Running indicator --------------------------------------------------
----------------------------------------------------------------------
  p_led: process ( rst_n , clkm)
  variable v_cnt : integer range 0 to 2**24;
  begin
    if rst_n = '0' then
      led(5) <= '0';
      v_cnt  := 0;
    elsif (rising_edge(clkm)) then
      v_cnt  := v_cnt + 1 ;
      if v_cnt < 2**23 then 
        led(5)  <= '1';
      else
        led(5)  <= '0';
      end if;
    end if;
  end process p_led;

  led(2)  <= '0';
  led(4)  <= '1';


gen_soc: if CFG_SOC = 1 generate
----------------------------------------------------------------------
---  NOEL-V SUBSYSTEM -----------------------------------------
----------------------------------------------------------------------

    noelv0 : noelvsys 
    generic map (
      fabtech   => fabtech,
      memtech   => memtech,
      ncpu      => ncpu,
      nextmst   => 1,--2,
      nextslv   => nextslv,
      nextapb   => 5,
      ndbgmst   => ndbgmst,
      cached    => 0,
      wbmask    => 16#00FF#,
      busw      => 128,         --32/64/128
      cmemconf  => 4,
      fpuconf   => 0,
      disas     => 1,
      ahbtrace  => 0,
      cfg       => 1,
      devid     => 0,
      version   => 0,
      revision  => 7,
      nodbus    => CFG_NODBGBUS
      )
    port map(
      clk       => clkm, -- : in  std_ulogic;
      rstn      => rstn, -- : in  std_ulogic;
      -- AHB bus interface for other masters (DMA units)
      ahbmi     => ahbmi, -- : out ahb_mst_in_type;
      ahbmo     => ahbmo(ncpu downto ncpu), -- : in  ahb_mst_out_vector_type(ncpu+nextmst-1 downto ncpu);
      -- AHB bus interface for slaves (memory controllers, etc)
      ahbsi     => ahbsi, -- : out ahb_slv_in_type;
      ahbso     => ahbso(nextslv-1 downto 0), -- : in  ahb_slv_out_vector_type(nextslv-1 downto 0);
      -- AHB master interface for debug links
      dbgmi     => dbgmi, -- : out ahb_mst_in_vector_type(ndbgmst-1 downto 0);
      dbgmo     => dbgmo, -- : in  ahb_mst_out_vector_type(ndbgmst-1 downto 0);
      -- APB interface for external APB slaves
      apbi      => apbi, -- : out apb_slv_in_type;
      apbo      => apbo, -- : in  apb_slv_out_vector;
      -- Bootstrap signals
      dsuen     => ldsuen, -- : in  std_ulogic;
      dsubreak  => ldsubreak, -- : in  std_ulogic;
      cpu0errn  => lcpu0errn, -- : out std_ulogic;
      -- UART connection
      uarti     => u1i, -- : in  uart_in_type;
      uarto     => u1o  -- : out uart_out_type
      );

  ldsuen <= '1';
  led1_pad    : outpad generic map (tech => padtech) port map (led(1), lcpu0errn);
  dsubre_pad  : inpad  generic map (tech => padtech) port map (KEY(1), ldsubreak); 
  dsuact_pad  : outpad generic map (tech => padtech) port map (led(0), ldsuen);

  -----------------------------------------------------------------------------
  -- Debug UART ---------------------------------------------------------------
  -----------------------------------------------------------------------------
  dcomgen : if CFG_AHB_UART = 1 generate
    dcom0 : ahbuart
      generic map(
        hindex => 0,
        pindex => 1,
        paddr => 14)
      port map(
        rstn,
        clkm,
        dui,
        duo,
        apbi(1),
        apbo(1),
        dbgmi(0),
        dbgmo(0));
        dui.extclk <= '0';
  end generate;

  nouah : if CFG_AHB_UART = 0 generate
    apbo(1)    <= apb_none;
    duo.txd    <= '0';
    duo.rtsn   <= '0';
    dui.extclk <= '0';
  end generate;

  sw4_pad : inpad generic map (tech => padtech)      port map (SW(3), dsu_sel);

  dsutx_int     <= duo.txd      when dsu_sel = '1' else u1o.txd;
  dui.rxd       <= dsurx_int    when dsu_sel = '1' else '1';
  u1i.rxd       <= dsurx_int    when dsu_sel = '0' else '1';
  dsurtsn_int   <= duo.rtsn     when dsu_sel = '1' else u1o.rtsn;  
  dui.ctsn      <= dsuctsn_int  when dsu_sel = '1' else '1';
  u1i.ctsn      <= dsuctsn_int  when dsu_sel = '0' else '1';
  
  dsurx_pad   : inpad  generic map (tech => padtech) port map (GPIO_0(35), dsurx_int);
  dsutx_pad   : outpad generic map (tech => padtech) port map (GPIO_1(00), dsutx_int);
  dsuctsn_pad : inpad  generic map (tech => padtech) port map (GPIO_0(34), dsuctsn_int);
  dsurtsn_pad : outpad generic map (tech => padtech) port map (GPIO_1(01), dsurtsn_int);

  -----------------------------------------------------------------------------
  -- JTAG debug link ----------------------------------------------------------
  -----------------------------------------------------------------------------
  
  ahbjtaggen0 : if CFG_AHB_JTAG = 1 generate
    ahbjtag0 : ahbjtag
      generic map(tech => fabtech, hindex => 1)
      port map(rstn, clkm, tck, tms, tdi, tdo, dbgmi(1), dbgmo(1),
               open, open, open, open, open, open, open, gnd);
  end generate;

  nojtag : if CFG_AHB_JTAG = 0 generate
    dbgmo(1) <= ahbm_none;
  end generate;
  
----------------------------------------------------------------------
---  DDR3 memory controller ------------------------------------------
----------------------------------------------------------------------

-- TODO

-----------------------------------------------------------------------
---  ETHERNET ---------------------------------------------------------
-----------------------------------------------------------------------

--TODO

-----------------------------------------------------------------------
---  USB      ---------------------------------------------------------
-----------------------------------------------------------------------

--TODO

----------------------------------------------------------------------
---  I2C Controller --------------------------------------------------
----------------------------------------------------------------------

-- TODO

----------------------------------------------------------------------
---  GPIO Controller -------------------------------------------------
----------------------------------------------------------------------
  gpio0 : if CFG_GRGPIO_ENABLE /= 0 generate     -- GPIO unit
    grgpio0: grgpio
      generic map
        (pindex => 3, paddr => 4, imask => CFG_GRGPIO_IMASK, nbits => 7)
      port map
        (rst => rstn, clk => clkm, apbi => apbi(3), apbo => apbo(3),gpioi => gpioi, gpioo => gpioo);
    
    pio_pads : for i in 0 to CFG_GRGPIO_WIDTH-1 generate
      -- for now only use input pad
      pio_in_pad: inpad generic map  (tech  => padtech) port map (GPIO_0(i), gpioi.din(i));
    end generate;
    
  end generate;

----------------------------------------------------------------------
  --  AHB Status Register
----------------------------------------------------------------------  
  ahbs : if CFG_AHBSTAT = 1 generate  
    stati <= ahbstat_in_none;
    ahbstat0 : ahbstat
      generic map(pindex  => 2,
                  paddr   => 15,
                  pirq    => 4,
                  nftslv  => CFG_AHBSTATN)
      port map(rstn,clkm,ahbmi,ahbsi,stati,apbi(2),apbo(2));
  end generate;

  -----------------------------------------------------------------------
  ---  AHB RAM ----------------------------------------------------------
  -----------------------------------------------------------------------
    ahbram1 : ahbram 
      generic map (
        hindex      => 0,
        haddr       => 16#400#,
        tech        => CFG_MEMTECH,
        kbytes      => 64,
        endianness  => GRLIB_CONFIG_ARRAY(grlib_little_endian))
      port map (
        rstn,
        clkm,
        ahbsi,
        ahbso(0));
      
  -----------------------------------------------------------------------
  ---  AHB ROM ----------------------------------------------------------
  -----------------------------------------------------------------------
  brom : entity work.ahbrom
    generic map (
      hindex  => 1,
      haddr   => 16#000#,
      pipe    => 0)
    port map (
      rst     => rstn,
      clk     => clkm,
      ahbsi   => ahbsi,
      ahbso   => ahbso(1));

  -----------------------------------------------------------------------
  ---  Fake MIG PNP -----------------------------------------------------
  -----------------------------------------------------------------------
  ahbso(mig_hindex).hindex  <= mig_hindex;
  ahbso(mig_hindex).hconfig <= mig_hconfig;
  ahbso(mig_hindex).hready  <= '1';
  ahbso(mig_hindex).hresp   <= "00";
  ahbso(mig_hindex).hirq    <= (others => '0');
  ahbso(mig_hindex).hrdata  <= (others => '0');  

end generate gen_soc;	 
-----------------------------------------------------------------------
---  Test report module  ----------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off
  test0 : ahbrep
    generic map(    hindex => 2, haddr => 16#200#)
    port map(       rstn, clkm, ahbsi, ahbso(2));
-- pragma translate_on
  
 -----------------------------------------------------------------------
 ---  Boot message  ----------------------------------------------------
 -----------------------------------------------------------------------

 -- pragma translate_off
  x : report_design
    generic map(
      msg1    => "NOELV/GRLIB DE10-nano demonstration design",
      fabtech => tech_table(fabtech), memtech => tech_table(memtech),
      mdel    => 1
      );
 -- pragma translate_on

 end;