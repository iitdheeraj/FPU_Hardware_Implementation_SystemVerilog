# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.10-p002_1 on Sun Apr 09 18:52:25 IST 2023

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design top_FPU

create_clock -name "clk" -period 1.0 -waveform {0.0 0.5} [get_ports clk]
set_clock_transition 0.05 [get_clocks clk]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay -max 0.05 [get_ports rst]
set_wire_load_mode "top"
set_clock_uncertainty -setup 0.01 [get_ports clk]
set_clock_uncertainty -hold 0.01 [get_ports clk]
## List of unsupported SDC commands ##
set_max_area 0
