#------------------------------------------------------------------------------
#--  Quartus timing constraint file for LEON-3 <> Terrasic DE10 nano Cyclone 5 design
#--  rev. 1.0 : 2020 Provoost Kris
#------------------------------------------------------------------------------

# dedicated clock inputs (pins on the kit)
create_clock -period 20 [get_ports FPGA_CLK1_50]
create_clock -period 20 [get_ports FPGA_CLK2_50]
create_clock -period 20 [get_ports FPGA_CLK3_50]

# set false paths from reset buttons
set_false_path -from [get_ports {KEY[0] KEY[1]}] -to [get_registers *]

# general directives for PLL usage
derive_pll_clocks
derive_clock_uncertainty