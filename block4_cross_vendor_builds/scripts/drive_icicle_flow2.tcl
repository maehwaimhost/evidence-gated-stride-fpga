# External flow driver (OUTSIDE repo). Opens the already-generated project
# and runs each tool with explicit rc/message logging to a status file.
set STATUS {REPO_ROOT/block4_builds/icicle_flow_status.txt}
set fh [open $STATUS w]
proc note {fh m} { puts $fh $m ; flush $fh }
set rc [catch {open_project {REPO_ROOT/block4_builds/icicle/BASE_DESIGN_ES_FD0AEBB9/BASE_DESIGN_ES_FD0AEBB9.prjx}} m]
note $fh "OPEN rc=$rc msg=$m"
foreach tool {SYNTHESIZE PLACEROUTE VERIFYTIMING GENERATEPROGRAMMINGDATA} {
    set rc [catch {run_tool -name $tool} m]
    note $fh "$tool rc=$rc msg=$m"
}
catch {save_project}
note $fh "DONE"
close $fh
