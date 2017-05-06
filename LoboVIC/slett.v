`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:31:40 03/27/2017 
// Design Name: 
// Module Name:    slett 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module slett(
	input clk_50M,
	input btn1,
	input btn2,
	output [7:0] LED,
	
	output [2:0] TMDSp, TMDSn,
	output TMDSp_clock, TMDSn_clock,
	
	input UART_RX,
	output UART_TX,
	
	output PHI2,
	output PHI2_180,
	output NMIB,
	output IRQB,
	output RESB,
	input [23:0] AB,
	inout [7:0] DB,
	inout RDY,
	input VPA,
	input VDA,
	input R_WB,
	input E,
	
	output USBRESB,
	output USBSS,
	output USBCLK,
	output SCK,
	output MOSI,
	input MISO,
	input USBGPX,
	input USBINT,

	output RAM1_OEB,
	output RAM1_CEB,

	output DDC_SCL,
	inout DDC_SDA,
	
	output SS2

    );

wire [2:0] TMDS;
OBUFDS OBUFDS_red  (.I(TMDS[2]), .O(TMDSp[2]), .OB(TMDSn[2]));
OBUFDS OBUFDS_green(.I(TMDS[1]), .O(TMDSp[1]), .OB(TMDSn[1]));
OBUFDS OBUFDS_blue (.I(TMDS[0]), .O(TMDSp[0]), .OB(TMDSn[0]));
OBUFDS OBUFDS_clock(.I(pixclkout), .O(TMDSp_clock), .OB(TMDSn_clock));

endmodule
