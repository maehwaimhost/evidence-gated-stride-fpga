# External Vivado non-project flow (OUTSIDE repo; references repo sources
# unchanged). Board-less full implementation of PicoRV32's repo-defined
# `system` top to bitstream on Artix-7 (Arty-A7-35 part). I/O left
# unconstrained (no board) -> downgrade UCIO/NSTD DRC so place/route/bitstream
# proceed. firmware.hex (4096 NOP) provided in CWD as a build input.
set OUT REPO_ROOT/block4_builds/picorv32_vivado
read_verilog [list REPO_ROOT/block4_builds/picorv32/scripts/quartus/system.v REPO_ROOT/block4_builds/picorv32/picorv32.v]
read_xdc $OUT/clk.xdc
synth_design -top system -part xc7a35ticsg324-1L
report_utilization -file $OUT/vivado_utilization.rpt
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
opt_design
place_design
route_design
report_timing_summary -file $OUT/vivado_timing.rpt
write_checkpoint -force $OUT/picorv32_viv_routed.dcp
write_bitstream -force $OUT/picorv32_viv.bit
puts "VIVADO_FLOW_DONE"
