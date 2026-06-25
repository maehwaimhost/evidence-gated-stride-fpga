set files [glob REPO_ROOT/block4_builds/serv/rtl/*.v]
read_verilog $files
read_xdc REPO_ROOT/block4_builds/serv/vivado/clk.xdc
synth_design -top serv_synth_wrapper -part xc7a35ticsg324-1L
report_utilization -file REPO_ROOT/block4_builds/serv/vivado/vivado_utilization.rpt
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
opt_design
place_design
route_design
report_timing_summary -file REPO_ROOT/block4_builds/serv/vivado/vivado_timing.rpt
write_checkpoint -force REPO_ROOT/block4_builds/serv/vivado/serv_viv_routed.dcp
write_bitstream -force REPO_ROOT/block4_builds/serv/vivado/serv_viv.bit
puts "VIVADO_FLOW_DONE"
