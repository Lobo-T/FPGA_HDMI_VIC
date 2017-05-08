
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name LoboVIC -dir "C:/Users/Trond/FPGA/LoboVIC/planAhead_run_1" -part xc6slx9tqg144-2
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "LoboVIC.ucf" [current_fileset -constrset]
add_files [list {ipcore_dir/video_mem.ngc}]
set hdlfile [add_files [list {ipcore_dir/clk12.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/charrom_CP865.ngc}]
add_files [list {ipcore_dir/colour_mem.ngc}]
set hdlfile [add_files [list {uart_tx.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {uart_rx.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {mod_m_counter.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {fifo.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {uart.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {SPI_master.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/video_mem.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/colour_mem.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/charrom_CP865.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {HDMIoutput.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {LoboVIC.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set_property top LoboVIC $srcset
add_files [list {LoboVIC.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/charrom_CP865.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/colour_mem.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/video_mem.ncf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9tqg144-2
