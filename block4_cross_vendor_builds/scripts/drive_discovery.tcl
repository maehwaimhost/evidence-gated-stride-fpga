set STATUS {REPO_ROOT/block4_builds/discovery/discovery_flow_status.txt}
set fh [open $STATUS w]
proc note {fh m} { puts $fh $m ; flush $fh }
cd {REPO_ROOT/block4_builds/discovery}
note $fh "CWD [pwd]"
# variant variable undefined -> generate the base reference design
if {[catch {source MPFS_DISCOVERY_KIT_REFERENCE_DESIGN.tcl} m]} {
    note $fh "GENERATE rc=1 msg=$m"
} else {
    note $fh "GENERATE rc=0"
}
# find the generated prjx
set prjx ""
foreach p [glob -nocomplain REPO_ROOT/block4_builds/discovery/*/*.prjx REPO_ROOT/block4_builds/discovery/*.prjx] { set prjx $p ; break }
note $fh "PRJX=$prjx"
catch {open_project -file $prjx}
foreach tool {SYNTHESIZE PLACEROUTE VERIFYTIMING GENERATEPROGRAMMINGDATA} {
    set rc [catch {run_tool -name $tool} m]
    note $fh "$tool rc=$rc msg=$m"
}
catch {save_project}
note $fh "DONE"
close $fh
