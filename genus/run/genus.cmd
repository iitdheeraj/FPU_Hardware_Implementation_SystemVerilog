# Cadence Genus(TM) Synthesis Solution, Version 21.10-p002_1, built Aug 20 2021 10:13:13

# Date: Sun Apr 09 15:51:40 2023
# Host: phoenix (x86_64 w/Linux 4.18.0-338.el8.x86_64) (16cores*32cpus*1physical cpu*AMD Ryzen 9 5950X 16-Core Processor 512KB)
# OS:   CentOS Stream release 8

set_attr init_lib_search_path /media/disk1/tools/Cadence/Cadence_lib/UMC65nm_PDK/STDCELLS/synopsys/ccs/
set_attr hdl_search_path ../rtl/
set_attr library uk65lscllmvbbr_120c25_tc_ccs.lib
read_hdl -sv top_FPU.sv
elaborate
set_top_module top_FPU
read_sdc ../constraints/FPU.sdc
set_attr syn_generic_effort high
syn_generic
syn_map
report_gates
set_attr syn_opt_effort high
syn_opt
report_gates
check_design > design_check.txt
report_gates > gates.txt
report_area > area.txt
report_power > power.txt
report_timing > timing.txt
write_hdl > gen_FPU.v
write_sdc > gen_FPU_sdc.sdc
write_sdf > fifo_sdf.sdf
