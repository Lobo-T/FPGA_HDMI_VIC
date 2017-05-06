
# PlanAhead Launch Script for Post PAR Floorplanning, created by Project Navigator

create_project -name LoboVIC -dir "C:/Users/Trond/FPGA/LoboVIC-extern CPU/planAhead_run_1" -part xc6slx9tqg144-2
set srcset [get_property srcset [current_run -impl]]
set_property design_mode GateLvl $srcset
set_property edif_top_file "C:/Users/Trond/FPGA/LoboVIC-extern CPU/LoboVIC.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/Trond/FPGA/LoboVIC-extern CPU} {ipcore_dir} }
add_files [list {ipcore_dir/charrom_CP865.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/colour_mem.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/video_mem.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "LoboVIC.ucf" [current_fileset -constrset]
add_files [list {LoboVIC.ucf}] -fileset [get_property constrset [current_run]]
link_design
read_xdl -file "C:/Users/Trond/FPGA/LoboVIC-extern CPU/LoboVIC.ncd"
if {[catch {read_twx -name results_1 -file "C:/Users/Trond/FPGA/LoboVIC-extern CPU/LoboVIC.twx"} eInfo]} {
   puts "WARNING: there was a problem importing \"C:/Users/Trond/FPGA/LoboVIC-extern CPU/LoboVIC.twx\": $eInfo"
}
