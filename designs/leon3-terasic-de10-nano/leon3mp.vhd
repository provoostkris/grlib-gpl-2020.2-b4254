------------------------------------------------------------------------------
--  TOP level design file for LEON-3 <> Terrasic DE10 nano Cyclone 5 design
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
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.jtag.all;
--pragma translate_off
use gaisler.sim.all;
--pragma translate_on
library esa;
use esa.memoryctrl.all;
use work.config.all;

entity leon3mp is
  generic (
    fabtech   : integer := CFG_FABTECH; -- support for cyclone 5 added in libs
    memtech   : integer := CFG_MEMTECH; -- support for cyclone 5 added in libs
    padtech   : integer := CFG_PADTECH; -- using default tech
    clktech   : integer := CFG_CLKTECH; -- using altera macro function for PLL
    disas     : integer := CFG_DISAS;
    pclow     : integer := CFG_PCLOW
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

architecture rtl of leon3mp is
  
  signal vcc, gnd   : std_logic_vector(4 downto 0);
  
  -- Memory controler signals
  signal memi : memory_in_type;
  signal memo : memory_out_type;
  signal wpo  : wprot_out_type;
  
  -- AMBA bus signals
  signal apbi  : apb_slv_in_type;
  signal apbo  : apb_slv_out_vector := (others => apb_none);
  signal ahbsi : ahb_slv_in_type;
  signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
  signal ahbmi : ahb_mst_in_type;
  signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);

  -- Clock signals
  signal cgi : clkgen_in_type;
  signal cgo : clkgen_out_type;

  -- UART signals
  signal dui      : uart_in_type;
  signal duo      : uart_out_type;
  signal uart_1_i, 
         uart_2_i : uart_in_type;
  signal uart_1_o, 
         uart_2_o : uart_out_type;

  -- IRQ signals
  signal irqi : irq_in_vector(0 to 0);
  signal irqo : irq_out_vector(0 to 0);

  -- debug signals
  signal dbgi : l3_debug_in_vector(0 to 0);
  signal dbgo : l3_debug_out_vector(0 to 0);

  -- debug support unit signals
  signal dsui     : dsu_in_type;
  signal dsuo     : dsu_out_type;
  signal ndsuact  : std_ulogic;
  signal dsubren  : std_ulogic;
  
  -- FPU signals
  signal fpi : grfpu_in_vector_type;
  signal fpo : grfpu_out_vector_type;
  
  -- status signals
  signal stati : ahbstat_in_type;
  
  -- Timer signals
  signal gptimer_0_i : gptimer_in_type;
  signal gptimer_0_o : gptimer_out_type;
  signal gptimer_1_i : gptimer_in_type;
  signal gptimer_1_o : gptimer_out_type;

  signal gp_io_0_i  : gpio_in_type;
  signal gp_io_0_o  : gpio_out_type;
  
  -- CLOCK signals
  signal clkm, rstn         : std_ulogic;
  signal rstraw             : std_logic;
  signal lock               : std_logic;
  
  -- JTAG signals
  signal tck, tms, tdi, tdo : std_ulogic;

  -- RS232 APB Uart (unconnected)
  signal rxd1 : std_logic;
  signal txd1 : std_logic;
  signal rxd2 : std_logic;
  signal txd2 : std_logic;
  
  attribute keep                     : boolean;
  attribute keep of lock             : signal is true;
  attribute keep of clkm             : signal is true;

  constant clock_mult : integer := CFG_CLKMUL;      --! Clock multiplier
  constant clock_div  : integer := CFG_CLKDIV;      --! Clock divider
  constant BOARD_FREQ : integer := 50_000;          --! CLK input frequency in KHz
  constant CPU_FREQ   : integer := BOARD_FREQ * clock_mult / clock_div;  --! CPU freq in KHz

  constant IOAEN : integer := 1;
  
  -- signals used for mapping BOARD pins to LEON ports
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

  vcc <= (others => '1'); 
  gnd <= (others => '0');

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
    port map    ( clk,gnd(0),clkm,open, 
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
---------------------------------------------------------------------- 
---  AHB CONTROLLER --------------------------------------------------
----------------------------------------------------------------------

  ahb0 : ahbctrl 		-- AHB arbiter/multiplexer
  generic map (defmast => CFG_DEFMST, split => CFG_SPLIT, 
               rrobin => CFG_RROBIN, ioaddr => CFG_AHBIO, 
               ioen => IOAEN, 
               nahbm => CFG_NCPU+CFG_AHB_JTAG+1,    -- +1 for the debug uart
               nahbs => 4) 
  port map    (rstn, clkm, ahbmi, ahbmo, ahbsi, ahbso);

----------------------------------------------------------------------
---  LEON3 processor and DSU -----------------------------------------
----------------------------------------------------------------------

  -- LEON3 processor
  nosh : if CFG_GRFPUSH = 0 generate    
    cpu : for i in 0 to CFG_NCPU-1 generate
      u0 : leon3s 		-- LEON3 processor      
      generic map ( i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU*(1-CFG_GRFPUSH), CFG_V8, 
                    0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE, 
                    CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
                    CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
                    CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP, 
                    CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR, CFG_NCPU-1,
                    0, 0, CFG_MMU_PAGE, CFG_BP, CFG_NP_ASI, CFG_WRPSR)
      port map (    clkm, rstn, ahbmi, ahbmo(i), ahbsi, ahbso, 
                    irqi(i), irqo(i), dbgi(i), dbgo(i));
    end generate;
  end generate;

  -- sh : if CFG_GRFPUSH = 1 generate
    -- cpu : for i in 0 to CFG_NCPU-1 generate
      -- u0 : leon3sh 		-- LEON3 processor      
      -- generic map ( i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8, 
                    -- 0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE, 
                    -- CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
                    -- CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
                    -- CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP, 
                    -- CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR, CFG_NCPU-1,
                    -- 0, 0, CFG_MMU_PAGE, CFG_BP, CFG_NP_ASI, CFG_WRPSR)
      -- port map (    clkm, rstn, ahbmi, ahbmo(i), ahbsi, ahbso, 
                    -- irqi(i), irqo(i), dbgi(i), dbgo(i), fpi(i), fpo(i));
  -- end generate;
    
    -- grfpush0 : grfpushwx 
        -- generic map ((CFG_FPU-1), CFG_NCPU, fabtech)
        -- port map    (clkm, rstn, fpi, fpo);
    
  -- end generate;

  errorn_pad : outpad generic map (tech => padtech) port map (led(3), dbgo(0).error);
  
  dsugen : if CFG_DSU = 1 generate
    dsu0 : dsu3			-- LEON3 Debug Support Unit
      generic map (hindex => 2, haddr => 16#900#, hmask => 16#F00#, 
                   ncpu => CFG_NCPU, tbits => 30, tech => memtech, irq => 0,
                   kbytes => CFG_ATBSZ)
      port map    (rstn, clkm, ahbmi, ahbsi, ahbso(2), dbgo, dbgi, dsui, dsuo);

    dsuen_pad   : inpad generic map   (tech => padtech) port map (SW(0), dsui.enable);    
    dsubre_pad  : inpad generic map   (tech => padtech) port map (KEY(1), dsubren);
    dsui.break  <= not dsubren;
    dsuact_pad  : outpad generic map  (tech => padtech) port map (LED(7), dsuo.active);
  end generate; 
  
  nodsu : if CFG_DSU = 0 generate 
    ahbso(2) <= ahbs_none; dsuo.tstop <= '0'; dsuo.active <= '0';
  end generate;

  ahbjtaggen0 :if CFG_AHB_JTAG = 1 generate
    ahbjtag0 : ahbjtag 
      generic map ( tech => fabtech, hindex => CFG_NCPU)
      port map    ( rstn, clkm, tck, tms, tdi, tdo, ahbmi, ahbmo(CFG_NCPU),
                    open, open, open, open, open, open, open, gnd(0));
  end generate;
  
--  if CFG_AHB_JTAG = 0 , do nothing
  
  -- Debug UART
  dcom0 : ahbuart 
    generic map   ( hindex => CFG_NCPU+CFG_AHB_JTAG, 
                    pindex => 4, paddr => 4)
    port map      ( rstn, clkm, dui, duo, apbi, apbo(4), ahbmi, ahbmo(CFG_NCPU+CFG_AHB_JTAG));
  
  dsurx_pad   : inpad generic map   (tech  => padtech) port map (GPIO_0(35), dui.rxd);
  dsutx_pad   : outpad generic map  (tech  => padtech) port map (GPIO_1(00), duo.txd);
  dcom_rx_pad : outpad generic map  (tech  => padtech) port map (LED(0), not dui.rxd);
  dcom_tx_pad : outpad generic map  (tech  => padtech) port map (LED(1), not duo.txd);
  dui.ctsn   <= '0';
  dui.extclk <= '0';
----------------------------------------------------------------------
---  Memory controllers ----------------------------------------------
----------------------------------------------------------------------


-----------------------------------------------------------------------
---  AHB ROM ----------------------------------------------------------
-----------------------------------------------------------------------

  bpromgen : if CFG_AHBROMEN /= 0 and CFG_SPIMCTRL = 0 generate
    brom : entity work.ahbrom
      generic map (hindex => 0, haddr => CFG_AHBRODDR, pipe => CFG_AHBROPIP)
      port map    (rstn, clkm, ahbsi, ahbso(0));
  end generate;
  noprom : if CFG_AHBROMEN = 0 and CFG_SPIMCTRL = 0 generate
    ahbso(0) <= ahbs_none;
  end generate;
  
----------------------------------------------------------------------
---  APB Bridge and various periherals -------------------------------
----------------------------------------------------------------------

  apb0 : apbctrl				-- AHB/APB bridge
    generic map (hindex => 1, haddr => CFG_APBADDR)
    port map (rstn, clkm, ahbsi, ahbso(1), apbi, apbo);
  
  ua1 : if CFG_UART1_ENABLE /= 0 generate
    uart1 : apbuart			-- UART 1
      generic map ( pindex => 1, paddr => 1,  pirq => 2, 
                    console => dbguart, fifosize => CFG_UART1_FIFO)
      port map    ( rstn, clkm, apbi, apbo(1), uart_1_i, uart_1_o);
    uart_1_i.rxd    <= rxd1;
    uart_1_i.ctsn   <= '0';
    uart_1_i.extclk <= '0';
    txd1            <= uart_1_o.txd;
  end generate;
  
  no_ua1 : if CFG_UART1_ENABLE = 0 generate 
    apbo(1) <= apb_none; 
  end generate;
  
  ua2 : if CFG_UART2_ENABLE /= 0 generate
    uart2 : apbuart			-- UART 2
      generic map ( pindex => 6, paddr => 6,  pirq => 3, 
                    fifosize => CFG_UART2_FIFO)
      port map    ( rstn, clkm, apbi, apbo(6), uart_2_i, uart_2_o);
    uart_2_i.rxd    <= rxd2; 
    uart_2_i.ctsn   <= '0'; 
    uart_2_i.extclk <= '0'; 
    txd2            <= uart_2_o.txd;
  end generate;
  
  no_ua2 : if CFG_UART2_ENABLE = 0 generate 
    apbo(6) <= apb_none; 
  end generate;
  
  irqctrl3 :  if CFG_IRQ3_ENABLE /= 0 generate
    irqctrl0 : irqmp			-- interrupt controller
      generic map ( pindex => 2, paddr => 2, ncpu => CFG_NCPU)
      port map    ( rstn, clkm, apbi, apbo(2), irqo, irqi);
  end generate;
  
  no_irq3 :   if CFG_IRQ3_ENABLE = 0 generate
    x : for i in 0 to CFG_NCPU-1 generate
      irqi(i).irl <= "0000";
    end generate;
    apbo(2) <= apb_none;
  end generate;


  gpt : if CFG_GPT_ENABLE /= 0 generate
    
    timer0 : gptimer 			-- timer Unit (APB slave 3)
      generic map ( pindex => 3, paddr => 3, pirq => CFG_GPT_IRQ,
                    sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW,
                    ntimers => CFG_GPT_NTIM, nbits => CFG_GPT_TW)
      port map (    rstn, clkm, apbi, apbo(3), gptimer_0_i, gptimer_0_o);
      
      gptimer_0_i <= gpti_dhalt_drive(dsuo.tstop);
  
    timer1 : gptimer     -- Time Unit (APB slave 0)
      generic map ( pindex => 0, paddr => 0, pirq => CFG_GPT_IRQ,
                    sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW,
                    ntimers => CFG_GPT_NTIM, nbits => CFG_GPT_TW)
      port map    ( rstn, clkm, apbi, apbo(0), gptimer_1_i, gptimer_1_o);
  
      gptimer_1_i <= gpti_dhalt_drive(dsuo.tstop);
      
  end generate;
  
  no_gpt : if CFG_GPT_ENABLE = 0 generate 
    apbo(0) <= apb_none; 
    apbo(3) <= apb_none; 
  end generate;
  
  ahbs : if CFG_AHBSTAT = 1 generate	-- AHB status register
    stati <= ahbstat_in_none;
    ahbstat0 : ahbstat 
      generic map ( pindex => 5, paddr => 5, 
                    pirq => 1, nftslv => CFG_AHBSTATN)
      port map    ( rstn, clkm, ahbmi, ahbsi, stati, apbi, apbo(5));
  end generate;
  
  no_ahbs : if CFG_AHBSTAT = 0 generate 
    apbo(5) <= apb_none; 
  end generate;
  
  gpio0 : if CFG_GRGPIO_ENABLE /= 0 generate     -- GRGPIO0 port
    grgpio0: grgpio
      generic map ( pindex => 7, paddr => 7, 
                    imask => CFG_GRGPIO_IMASK, 
                    nbits => CFG_GRGPIO_WIDTH)
      port map    ( rstn, clkm, apbi, apbo(7), gp_io_0_i, gp_io_0_o);
    
    pio_pads : for i in 0 to CFG_GRGPIO_WIDTH-1 generate
      -- for now only use input pad
      pio_in_pad: inpad generic map  (tech  => padtech) port map (GPIO_0(i), gp_io_0_i.din(i));
    end generate;
    
  end generate;
  
  no_gpio0: if CFG_GRGPIO_ENABLE = 0 generate 
    apbo(7) <= apb_none; 
  end generate;

-----------------------------------------------------------------------
---  AHB RAM ----------------------------------------------------------
-----------------------------------------------------------------------

  ocram : if CFG_AHBRAMEN = 1 generate 
    ahbram0 : ahbram 
      generic map ( hindex => 3, haddr => CFG_AHBRADDR, 
                    tech => memtech, kbytes => CFG_AHBRSZ)
      port map    ( rstn, clkm, ahbsi, ahbso(3));
  end generate;
  
  no_ocram : if CFG_AHBRAMEN = 0 generate 
    ahbso(3) <= ahbs_none; 
  end generate;  
-----------------------------------------------------------------------
--  Test report module, only used for simulation ----------------------
-----------------------------------------------------------------------

--pragma translate_off
  -- test0 : ahbrep 
    -- generic map (hindex => 4, haddr => 16#200#)
    -- port map (rstn, clkm, ahbsi, ahbso(5));
--pragma translate_on

-----------------------------------------------------------------------
---  Boot message  ----------------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off
  x : report_design
    generic map (
      msg1 => "LEON3 Demonstration design",
      fabtech => tech_table(fabtech), memtech => tech_table(memtech),
      mdel => 1
      );
-- pragma translate_on

end rtl;
