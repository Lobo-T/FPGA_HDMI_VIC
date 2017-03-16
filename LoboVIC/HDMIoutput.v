`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:49:15 01/19/2017 
// Design Name: 
// Module Name:    HDMIoutput 
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
module HDMIoutput(
	input clk_TMDS,
	input pixclk,
	input [7:0] vmemdbus,
	output reg [15:0] vmemabus=0,
	output [2:0] TMDS,
	
	input [7:0] chrdbus,
	output [10:0] chrabus,

	input [7:0] coldbus,
	output [12:0] colabus
);

////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////
reg [9:0] CounterX=798, CounterY=523;
reg hSync, vSync, DrawArea;
always @(posedge pixclk) DrawArea <= (CounterX<640) && (CounterY<480);

always @(posedge pixclk) CounterX <= (CounterX==799) ? 1'b0 : CounterX+(1'b1);
always @(posedge pixclk) if(CounterX==799) CounterY <= (CounterY==524) ? 1'b0 : CounterY+(1'b1);

always @(posedge pixclk) hSync <= (CounterX>=656) && (CounterX<752);
always @(posedge pixclk) vSync <= (CounterY>=490) && (CounterY<492);

////////////////
// 4-dobling X og Y
//reg [1:0] Xmod4=0;
//reg [1:0] Ymod4=1;
//
//always @(posedge pixclk)
//begin
//	Xmod4 <= (Xmod4==2'd3) ? 2'd0 : Xmod4+2'd1;
//end
//always @(posedge pixclk)
//begin
//	if(CounterX == 640 && CounterY<480)
//		Ymod4 <= (Ymod4==2'd3) ? 2'd0 : Ymod4+2'd1;
//end		
//
//always @(posedge pixclk)
//begin	
//	if(CounterX == 799 && CounterY == 524)
//		vmemabus <= 0;
//	else if(CounterX==639 && Ymod4!=0 && vmemabus >= 159)
//			vmemabus <= vmemabus-15'd160;
//	else if(Xmod4==0 && DrawArea)
//		vmemabus <= vmemabus + 1'b1;
//	else
//		vmemabus <= vmemabus;
//end
///////
// 640x480 character mode 8x8 chars
reg [2:0] Xmod8=0;
reg [2:0] Ymod8=1;

always @(posedge pixclk)
begin
	Xmod8 <= (Xmod8==3'd7) ? 3'd0 : Xmod8+3'd1;
end
always @(posedge pixclk)
begin
	if(CounterX == 640 && CounterY<480)
		Ymod8 <= (Ymod8==3'd7) ? 3'd0 : Ymod8+3'd1;
end		

always @(posedge pixclk)
begin	
	if(CounterX == 799 && CounterY == 524)
		vmemabus <= 0;
	else if(CounterX==639 && Ymod8!=0 && vmemabus >= 79)
			vmemabus <= vmemabus-80;
	else if(Xmod8==0 && DrawArea)
		vmemabus <= vmemabus + 1'b1;
	else
		vmemabus <= vmemabus;
end

//always @(posedge pixclk)
//	$display("%d %d : %d:%d :::X:%d:Y:%d", CounterX,CounterY,vmemabus,vmemdbus,Xmod8,Ymod8);
	
//wire [10:0] chrabus;
//wire [7:0] chrdbus;
//charrom_CP865 charrom (
//  .a(chrabus), // input [10 : 0] a
//  .spo(chrdbus) // output [7 : 0] spo
//);


assign colabus = vmemabus/8;

//wire [7:0] testvmemd = 82;
//assign chrabus = (testvmemd*8)+((CounterY)%8);
assign chrabus = (vmemdbus*8)+((CounterY)%8);
wire [7:0] pixout;
wire [7:0] rowshift = chrdbus << ((CounterX)%8);
assign pixout = (rowshift & 8'b10000000)?
					 coldbus :
					 8'b0;
					 
////////////////////////////////////////////////////////////////////////
wire [7:0] red, green, blue;
RGB332_converter conv1(.RGB332(pixout), .RED(red), .GREEN(green), .BLUE(blue));
//RGB332_converter conv1(.RGB332(vmemdbus), .RED(red), .GREEN(green), .BLUE(blue));

////////////////////////////////////////////////////////////////////////
wire [9:0] TMDS_red, TMDS_green, TMDS_blue;
TMDS_encoder encode_R(.clk(pixclk), .VD(red  ), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_red));
TMDS_encoder encode_G(.clk(pixclk), .VD(green), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_green));
TMDS_encoder encode_B(.clk(pixclk), .VD(blue ), .CD({vSync,hSync}), .VDE(DrawArea), .TMDS(TMDS_blue));

////////////////////////////////////////////////////////////////////////
reg [3:0] TMDS_mod10=0;  // modulus 10 counter
reg [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
reg TMDS_shift_load=0;
always @(posedge clk_TMDS) TMDS_shift_load <= (TMDS_mod10==4'd9);

always @(posedge clk_TMDS)
begin
	TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:1];
	TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:1];
	TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:1];	
	TMDS_mod10 <= (TMDS_mod10==4'd9) ? 4'd0 : TMDS_mod10+4'd1;
end

assign TMDS[2] = TMDS_shift_red  [0];
assign TMDS[1] = TMDS_shift_green  [0];
assign TMDS[0] = TMDS_shift_blue  [0];

endmodule


////////////////////////////////////////////////////////////////////////
module TMDS_encoder(
	input clk,
	input [7:0] VD,  // video data (red, green or blue)
	input [1:0] CD,  // control data
	input VDE,  // video data enable, to choose between CD (when VDE=0) and VD (when VDE=1)
	output reg [9:0] TMDS = 0
);

wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};

reg [3:0] balance_acc = 0;
wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
wire balance_sign_eq = (balance[3] == balance_acc[3]);
wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);

always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 4'h0;
endmodule


////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////
//Converter fra RGB 3:3:2 format til 24bit (en byte per farge)
module RGB332_converter(
	input [7:0] RGB332,
	output reg [7:0] RED,GREEN,BLUE
);

	always @*
	case(RGB332[7:5])
		3'b000: RED = 8'b00000000;
		3'b001: RED = 8'd36;
		3'b010: RED = 8'd73;
		3'b011: RED = 8'd109;
		3'b100: RED = 8'd146;
		3'b101: RED = 8'd182;
		3'b110: RED = 8'd219;
		3'b111: RED = 8'b11111111;
	endcase

	always @*
	case(RGB332[4:2])
		3'b000: GREEN = 8'b00000000;
		3'b001: GREEN = 8'd36;
		3'b010: GREEN = 8'd73;
		3'b011: GREEN = 8'd109;
		3'b100: GREEN = 8'd146;
		3'b101: GREEN = 8'd182;
		3'b110: GREEN = 8'd219;
		3'b111: GREEN = 8'b11111111;
	endcase

	always @*
	case(RGB332[1:0])
		2'b00: BLUE = 8'b00000000;
		2'b01: BLUE = 8'd85;
		2'b10: BLUE = 8'd170;
		2'b11: BLUE = 8'b11111111;
	endcase

endmodule
////////////////////////////////////////////////////////////////////////