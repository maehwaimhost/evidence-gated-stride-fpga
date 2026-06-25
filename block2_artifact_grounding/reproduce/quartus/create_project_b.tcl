package require ::quartus::project

set script_dir [file dirname [file normalize [info script]]]
set exp_dir [file dirname $script_dir]
set src_dir [file join $exp_dir src]
set work_dir [file join $exp_dir results quartus project_b]
file mkdir $work_dir
cd $work_dir

set project_name top_b
set revision_name top_b

if {[is_project_open]} {
    project_close
}

project_new $project_name -revision $revision_name -overwrite
set_global_assignment -name FAMILY "Cyclone 10 GX"
set_global_assignment -name DEVICE 10CX220YU484E5G
set_global_assignment -name TOP_LEVEL_ENTITY top_b
set_global_assignment -name VERILOG_FILE [file join $src_dir top_b.v]
set_global_assignment -name SDC_FILE [file join $script_dir top_b.sdc]
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
export_assignments
project_close
