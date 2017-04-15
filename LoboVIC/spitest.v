`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:08:50 03/30/2017
// Design Name:   spi
// Module Name:   C:/Users/Trond/FPGA/LoboVIC/spitest.v
// Project Name:  LoboVIC
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: spi
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module spitest;

	// Inputs
	reg clk;
	reg rst;
	reg miso;
	reg start;
	reg [7:0] data_in;

	// Outputs
	wire mosi;
	wire sck;
	wire [7:0] data_out;
	wire busy;
	wire new_data;

	// Instantiate the Unit Under Test (UUT)
	spi uut (
		.clk(clk), 
		.rst(rst), 
		.miso(miso), 
		.mosi(mosi), 
		.sck(sck), 
		.start(start), 
		.data_in(data_in), 
		.data_out(data_out), 
		.busy(busy), 
		.new_data(new_data)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		miso = 0;
		start = 0;
		data_in = 8'b11001010;
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		#50 rst = 1'b1;
		#100 rst = 1'b0;
		#150 start = 1'b1;
		#500 start = 1'b0;

	end
	
   always #10 clk = ~clk;
	
endmodule

