gui_open_window Wave
gui_sg_create clk12_group
gui_list_add_group -id Wave.1 {clk12_group}
gui_sg_addsignal -group clk12_group {clk12_tb.test_phase}
gui_set_radix -radix {ascii} -signals {clk12_tb.test_phase}
gui_sg_addsignal -group clk12_group {{Input_clocks}} -divider
gui_sg_addsignal -group clk12_group {clk12_tb.CLK_IN1}
gui_sg_addsignal -group clk12_group {{Output_clocks}} -divider
gui_sg_addsignal -group clk12_group {clk12_tb.dut.clk}
gui_list_expand -id Wave.1 clk12_tb.dut.clk
gui_sg_addsignal -group clk12_group {{Status_control}} -divider
gui_sg_addsignal -group clk12_group {clk12_tb.RESET}
gui_sg_addsignal -group clk12_group {clk12_tb.LOCKED}
gui_sg_addsignal -group clk12_group {{Counters}} -divider
gui_sg_addsignal -group clk12_group {clk12_tb.COUNT}
gui_sg_addsignal -group clk12_group {clk12_tb.dut.counter}
gui_list_expand -id Wave.1 clk12_tb.dut.counter
gui_zoom -window Wave.1 -full
