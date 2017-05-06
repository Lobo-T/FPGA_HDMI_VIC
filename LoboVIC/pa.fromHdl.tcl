
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name LoboVIC -dir "C:/Users/Trond/FPGA/LoboVIC-extern CPU/planAhead_run_5" -part xc6slx9tqg144-2
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "slett.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {slett.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/video_mem.ngc}]
add_files [list {ipcore_dir/colour_mem.ngc}]
add_files [list {ipcore_dir/charrom_CP865.ngc}]
set_property top slett $srcset
add_files [list {slett.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/charrom_CP865.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/colour_mem.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/gfxrom.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/video_mem.ncf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9tqg144-2
