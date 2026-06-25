package require ::quartus::project

set script_dir [file dirname [file normalize [info script]]]
set exp_dir [file dirname $script_dir]
set src_dir [file join $exp_dir src]
set work_dir [file join $exp_dir results quartus project]
file mkdir $work_dir
cd $work_dir

set project_name top
set revision_name top

if {[is_project_open]} {
    project_close
}

project_new $project_name -revision $revision_name -overwrite
set_global_assignment -name FAMILY "Cyclone 10 GX"
set_global_assignment -name DEVICE 10CX220YU484E5G
set_global_assignment -name TOP_LEVEL_ENTITY top
set_global_assignment -name VERILOG_FILE [file join $src_dir top.v]
set_global_assignment -name SDC_FILE [file join $script_dir top.sdc]
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
set_location_assignment PIN_C15 -to clk
set_location_assignment PIN_C17 -to reset_n
set_location_assignment PIN_C18 -to led[0]
set_location_assignment PIN_C16 -to led[1]
set_location_assignment PIN_C19 -to led[2]
set_location_assignment PIN_D17 -to led[3]
set_instance_assignment -name IO_STANDARD "1.8 V" -to clk
set_instance_assignment -name IO_STANDARD "1.8 V" -to reset_n
set_instance_assignment -name IO_STANDARD "1.8 V" -to led[0]
set_instance_assignment -name IO_STANDARD "1.8 V" -to led[1]
set_instance_assignment -name IO_STANDARD "1.8 V" -to led[2]
set_instance_assignment -name IO_STANDARD "1.8 V" -to led[3]
export_assignments
project_close
