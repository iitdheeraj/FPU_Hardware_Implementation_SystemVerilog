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
write_sdf > gen_FPU_sdf.sdf

