
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name LoboVIC -dir "C:/Users/Trond/FPGA/LoboVIC/planAhead_run_4" -part xc6slx9tqg144-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/Trond/FPGA/LoboVIC/LoboVIC.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/Trond/FPGA/LoboVIC} {ipcore_dir} }
add_files [list {ipcore_dir/charrom_CP865.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/colour_mem.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/video_mem.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "LoboVIC.ucf" [current_fileset -constrset]
add_files [list {LoboVIC.ucf}] -fileset [get_property constrset [current_run]]
link_design
