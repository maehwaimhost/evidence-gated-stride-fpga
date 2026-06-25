# External driver (OUTSIDE the cloned repo; does not modify repo sources).
# One clean invocation: generate the design via the repo's canonical Tcl
# (no flow flags -> generation only), then run the board-less flow with
# explicit per-stage status logging to a file we control (libero stdout is
# empty under the Windows GUI subsystem, so we self-report).
set STATUS {REPO_ROOT/block4_builds/icicle_flow_status.txt}
set fh [open $STATUS w]
proc note {fh m} { puts $fh $m ; flush $fh }
cd {REPO_ROOT/block4_builds/icicle}
note $fh "CWD [pwd]"
if {[catch {source MPFS_ICICLE_KIT_REFERENCE_DESIGN.tcl} m]} {
    note $fh "GENERATE rc=1 msg=$m"
} else {
    note $fh "GENERATE rc=0"
}
# Ensure the generated project is open (the repo Tcl may close it).
catch {open_project {REPO_ROOT/block4_builds/icicle/BASE_DESIGN_ES_FD0AEBB9/BASE_DESIGN_ES_FD0AEBB9.prjx}}
foreach tool {SYNTHESIZE PLACEROUTE VERIFYTIMING GENERATEPROGRAMMINGDATA} {
    set rc [catch {run_tool -name $tool} m]
    note $fh "$tool rc=$rc msg=$m"
}
catch {save_project}
note $fh "DONE"
close $fh
