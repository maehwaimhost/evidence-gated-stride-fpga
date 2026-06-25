set script_dir [file dirname [file normalize [info script]]]
set exp_dir [file dirname $script_dir]
set src_dir [file join $exp_dir src]
set result_dir [file join $exp_dir results libero]
file mkdir $result_dir

set status_file [file join $result_dir libero_status.csv]
set status_ch [open $status_file w]
puts $status_ch "stage,status,detail"

proc record_status {ch stage status detail} {
    regsub -all {[\r\n,]} $detail { } clean_detail
    puts $ch "$stage,$status,$clean_detail"
    flush $ch
}

# ---------------- Design A (single-clock probe) ----------------

set project_name ap_stride_libero
set project_dir [file join $result_dir project]
file delete -force $project_dir

if {[catch {
    new_project \
        -instantiate_in_smartdesign 1 \
        -ondemand_build_dh 1 \
        -use_enhanced_constraint_flow 1 \
        -location $project_dir \
        -name $project_name \
        -hdl {VERILOG} \
        -family {PolarFire} \
        -die {MPF100T} \
        -package {FCG484} \
        -speed {-1} \
        -die_voltage {1.0}
    record_status $status_ch project_create ok "PolarFire MPF100T FCG484 project created"
} err]} {
    record_status $status_ch project_create fail $err
    close $status_ch
    exit
}

if {[catch {
    import_files -convert_EDN_to_HDL 0 -library {work} -hdl_source [file join $src_dir top.v]
    create_links -convert_EDN_to_HDL 0 -sdc [file join $script_dir top.sdc]
    build_design_hierarchy
    set_root -module {top::work}
    organize_tool_files -tool {SYNTHESIZE} -file [file join $script_dir top.sdc] -module {top::work} -input_type {constraint}
    organize_tool_files -tool {PLACEROUTE} -file [file join $script_dir top.sdc] -module {top::work} -input_type {constraint}
    organize_tool_files -tool {VERIFYTIMING} -file [file join $script_dir top.sdc] -module {top::work} -input_type {constraint}
    save_project
    record_status $status_ch source_import ok "HDL and SDC loaded"
} err]} {
    record_status $status_ch source_import fail $err
}

foreach tool_name {SYNTHESIZE PLACEROUTE VERIFYTIMING GENERATEPROGRAMMINGDATA GENERATEPROGRAMMINGFILE} {
    if {[catch {run_tool -name $tool_name} err]} {
        record_status $status_ch $tool_name fail $err
    } else {
        record_status $status_ch $tool_name ok "$tool_name completed"
    }
    save_project
}

if {[catch {
    export_bitstream_file \
        -file_name {ap_stride_libero} \
        -format {STP DAT PPD} \
        -limit_SVF_file_size 0 \
        -limit_SVF_file_by_max_filesize_or_vectors {SIZE} \
        -svf_max_filesize {1024} \
        -svf_max_vectors {1000}
    record_status $status_ch export_bitstream ok "programming files exported"
} err]} {
    record_status $status_ch export_bitstream fail $err
}

save_project
close_project

# ---------------- Design B (dual clock domain, async FIFO, CDC) ----------------

set project_name_b ap_stride_libero_b
set project_dir_b [file join $result_dir project_b]
file delete -force $project_dir_b

if {[catch {
    new_project \
        -instantiate_in_smartdesign 1 \
        -ondemand_build_dh 1 \
        -use_enhanced_constraint_flow 1 \
        -location $project_dir_b \
        -name $project_name_b \
        -hdl {VERILOG} \
        -family {PolarFire} \
        -die {MPF100T} \
        -package {FCG484} \
        -speed {-1} \
        -die_voltage {1.0}
    record_status $status_ch project_create_b ok "PolarFire MPF100T FCG484 project created"
} err]} {
    record_status $status_ch project_create_b fail $err
    close $status_ch
    exit
}

if {[catch {
    import_files -convert_EDN_to_HDL 0 -library {work} -hdl_source [file join $src_dir top_b.v]
    create_links -convert_EDN_to_HDL 0 -sdc [file join $script_dir top_b.sdc]
    build_design_hierarchy
    set_root -module {top_b::work}
    organize_tool_files -tool {SYNTHESIZE} -file [file join $script_dir top_b.sdc] -module {top_b::work} -input_type {constraint}
    organize_tool_files -tool {PLACEROUTE} -file [file join $script_dir top_b.sdc] -module {top_b::work} -input_type {constraint}
    organize_tool_files -tool {VERIFYTIMING} -file [file join $script_dir top_b.sdc] -module {top_b::work} -input_type {constraint}
    save_project
    record_status $status_ch source_import_b ok "HDL and SDC loaded"
} err]} {
    record_status $status_ch source_import_b fail $err
}

foreach tool_name {SYNTHESIZE PLACEROUTE VERIFYTIMING GENERATEPROGRAMMINGDATA GENERATEPROGRAMMINGFILE} {
    if {[catch {run_tool -name $tool_name} err]} {
        record_status $status_ch ${tool_name}_b fail $err
    } else {
        record_status $status_ch ${tool_name}_b ok "$tool_name completed"
    }
    save_project
}

if {[catch {
    export_bitstream_file \
        -file_name {ap_stride_libero_b} \
        -format {STP DAT PPD} \
        -limit_SVF_file_size 0 \
        -limit_SVF_file_by_max_filesize_or_vectors {SIZE} \
        -svf_max_filesize {1024} \
        -svf_max_vectors {1000}
    record_status $status_ch export_bitstream_b ok "programming files exported"
} err]} {
    record_status $status_ch export_bitstream_b fail $err
}

save_project
close_project
close $status_ch
exit
