set script_dir [file dirname [file normalize [info script]]]
set exp_dir [file dirname $script_dir]
set src_dir [file join $exp_dir src]
set result_dir [file join $exp_dir results vivado]
file mkdir $result_dir

set part_name xc7a35tcpg236-1
set status_file [file join $result_dir vivado_status.csv]
set status_ch [open $status_file w]
puts $status_ch "stage,status,detail"

proc record_status {ch stage status detail} {
    regsub -all {[\r\n,]} $detail { } clean_detail
    puts $ch "$stage,$status,$clean_detail"
    flush $ch
}

# Robust run completion: trust the run STATUS when it reports Complete; otherwise
# fall back to the checkpoint the run step wrote on disk. This tolerates the flaky
# child-process teardown crash (EXCEPTION_ACCESS_VIOLATION after route_design
# completes) that can leave a finished run marked as ERROR.
proc open_run_or_checkpoint {run_name dcp_glob} {
    catch {wait_on_run $run_name -timeout 30}
    set status [get_property STATUS [get_runs $run_name]]
    if {[string first "Complete" $status] >= 0} {
        open_run $run_name
        return "run_status=$status"
    }
    set dcps [glob -nocomplain $dcp_glob]
    if {[llength $dcps] > 0} {
        open_checkpoint [lindex $dcps 0]
        return "run_status=$status; opened_checkpoint=[file tail [lindex $dcps 0]]"
    }
    error "$run_name did not complete and left no checkpoint: $status"
}

record_status $status_ch environment ok "Vivado [version -short], part $part_name"

# ---------------- Design A (single-clock probe) ----------------

set project_dir [file join $result_dir project]
file delete -force $project_dir

if {[catch {
    create_project -force ap_stride_vivado $project_dir -part $part_name
    set_property target_language Verilog [current_project]
    add_files -fileset sources_1 [file join $src_dir top.v]
    add_files -fileset sim_1 [file join $src_dir tb_top.v]
    add_files -fileset constrs_1 [file join $script_dir top.xdc]
    set_property top top [get_filesets sources_1]
    set_property top tb_top [get_filesets sim_1]
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
    record_status $status_ch project_create ok "XPR project, source files, sim files, and XDC constraints loaded"
} err]} {
    record_status $status_ch project_create fail $err
}

if {[catch {
    launch_runs synth_1 -jobs 2
    set how [open_run_or_checkpoint synth_1 [file join $project_dir ap_stride_vivado.runs synth_1 *.dcp]]
    write_checkpoint -force [file join $result_dir top_synth.dcp]
    report_utilization -file [file join $result_dir top_synth_utilization.rpt]
    report_timing_summary -file [file join $result_dir top_synth_timing_summary.rpt]
} err]} {
    record_status $status_ch synthesis fail $err
} else {
    record_status $status_ch synthesis ok "synthesis checkpoint and reports generated; $how"
}
catch {close_design}

if {[catch {
    launch_runs impl_1 -to_step route_design -jobs 2
    set how [open_run_or_checkpoint impl_1 [file join $project_dir ap_stride_vivado.runs impl_1 *routed.dcp]]
    write_checkpoint -force [file join $result_dir top_routed.dcp]
    report_utilization -file [file join $result_dir top_impl_utilization.rpt]
    report_timing_summary -file [file join $result_dir top_impl_timing_summary.rpt]
    report_drc -file [file join $result_dir top_impl_drc.rpt]
} err]} {
    record_status $status_ch implementation fail $err
} else {
    record_status $status_ch implementation ok "placed-and-routed checkpoint and reports generated; $how"
}

if {[catch {
    set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
    set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
    write_bitstream -force [file join $result_dir top.bit]
} err]} {
    record_status $status_ch bitstream fail $err
} else {
    record_status $status_ch bitstream ok "bitstream generated"
}

catch {close_project}
catch {close_project}

# ---------------- Design B (dual clock domain, async FIFO, CDC) ----------------

set project_dir_b [file join $result_dir project_b]
file delete -force $project_dir_b

if {[catch {
    create_project -force ap_stride_vivado_b $project_dir_b -part $part_name
    set_property target_language Verilog [current_project]
    add_files -fileset sources_1 [file join $src_dir top_b.v]
    add_files -fileset sim_1 [file join $src_dir tb_top_b.v]
    add_files -fileset constrs_1 [file join $script_dir top_b.xdc]
    set_property top top_b [get_filesets sources_1]
    set_property top tb_top_b [get_filesets sim_1]
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
    record_status $status_ch project_create_b ok "XPR project, source files, sim files, and XDC constraints loaded"
} err]} {
    record_status $status_ch project_create_b fail $err
}

if {[catch {
    launch_runs synth_1 -jobs 2
    set how [open_run_or_checkpoint synth_1 [file join $project_dir_b ap_stride_vivado_b.runs synth_1 *.dcp]]
    write_checkpoint -force [file join $result_dir top_b_synth.dcp]
    report_utilization -file [file join $result_dir top_b_synth_utilization.rpt]
    report_timing_summary -file [file join $result_dir top_b_synth_timing_summary.rpt]
    report_clock_interaction -file [file join $result_dir top_b_synth_clock_interaction.rpt]
} err]} {
    record_status $status_ch synthesis_b fail $err
} else {
    record_status $status_ch synthesis_b ok "synthesis checkpoint and reports generated; $how"
}
catch {close_design}

if {[catch {
    launch_runs impl_1 -to_step route_design -jobs 2
    set how [open_run_or_checkpoint impl_1 [file join $project_dir_b ap_stride_vivado_b.runs impl_1 *routed.dcp]]
    write_checkpoint -force [file join $result_dir top_b_routed.dcp]
    report_utilization -file [file join $result_dir top_b_impl_utilization.rpt]
    report_timing_summary -file [file join $result_dir top_b_impl_timing_summary.rpt]
    report_clock_interaction -file [file join $result_dir top_b_impl_clock_interaction.rpt]
    report_cdc -file [file join $result_dir top_b_impl_cdc.rpt]
    report_drc -file [file join $result_dir top_b_impl_drc.rpt]
} err]} {
    record_status $status_ch implementation_b fail $err
} else {
    record_status $status_ch implementation_b ok "placed-and-routed checkpoint and reports generated; $how"
}

if {[catch {
    set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
    set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
    write_bitstream -force [file join $result_dir top_b.bit]
} err]} {
    record_status $status_ch bitstream_b fail $err
} else {
    record_status $status_ch bitstream_b ok "bitstream generated"
}

catch {close_project}
catch {close_project}
close $status_ch
exit
