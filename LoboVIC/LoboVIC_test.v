`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:36:53 03/10/2017
// Design Name:   LoboVIC
// Module Name:   C:/Users/Trond/FPGA/LoboVIC/LoboVIC_test.v
// Project Name:  LoboVIC
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: LoboVIC
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module LoboVIC_test;

	// Inputs
	reg clk_50M;
	reg btn1;
	reg btn2;
	reg btn3;
	reg [7:0] dilswitch;
	reg UART_RX;

	// Outputs
	wire clk12usb;
	wire [7:0] led;
	wire [2:0] TMDSp;
	wire [2:0] TMDSn;
	wire TMDSp_clock;
	wire TMDSn_clock;
	wire UART_TX;

	// Instantiate the Unit Under Test (UUT)
	LoboVIC uut (
		.clk_50M(clk_50M), 
		.btn1(btn1), 
		.btn2(btn2), 
		.btn3(btn3), 
		.clk12usb(clk12usb), 
		.dilswitch(dilswitch), 
		.led(led), 
		.TMDSp(TMDSp), 
		.TMDSn(TMDSn), 
		.TMDSp_clock(TMDSp_clock), 
		.TMDSn_clock(TMDSn_clock), 
		.UART_RX(UART_RX), 
		.UART_TX(UART_TX)
	);

	initial begin
		// Initialize Inputs
		clk_50M = 0;
		btn1 = 0;
		btn2 = 0;
		btn3 = 0;
		dilswitch = 0;
		UART_RX = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		 
	end
   always #10 clk_50M = ~clk_50M;   
endmodule

