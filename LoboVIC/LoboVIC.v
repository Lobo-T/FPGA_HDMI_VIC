`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    06:04:56 03/05/2017 
// Design Name: 
// Module Name:    LoboVIC 
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
module LoboVIC(
	input clk_50M,  // 50MHz
	input btn1,btn2,btn3,
	input [7:0] dilswitch,
	output [7:0] led,
	output [2:0] TMDSp, TMDSn,
	output TMDSp_clock, TMDSn_clock,
	input UART_RX,
	output UART_TX,

	output clk12usb,
	output usb_RES,
	output spi_SSusb,
	output spi_MOSI,
	output spi_SCK,
	input spi_MISO
   );
	

//////////Clocking	
wire clk_TMDS, DCM_TMDS_CLKFX, pixclk, pixclkout, tmdsclk0;
//wire clk_50M_bufg;

//Generer 25 Mhz HDMI pikselklokke og 250Mhz HDMI bitklokke
// 50Mhz / 2 = 25MHz
// 50MHz x 5 = 250MHz
DCM_SP #(.CLKFX_MULTIPLY(5),.CLKDV_DIVIDE(2)) 
	DCM_TMDS_inst(.CLKIN(clk_50M), .CLKFX(DCM_TMDS_CLKFX), .CLKDV(pixclk), .CLK0(tmdsclk0), .CLKFB(tmdsclk0), .PSEN(1'b0), .RST(1'b0),
	.CLK180(), .CLK270(), .CLK2X(), .CLK2X180(), .CLK90(), .CLKFX180(), .LOCKED(), .PSDONE(), .STATUS(), .DSSEN(), .PSCLK(), .PSINCDEC());

BUFG BUFG_TMDSp(.I(DCM_TMDS_CLKFX), .O(clk_TMDS));
//BUFG BUFG_50M(.I(clk_50M), .O(clk_50M_bufg));

//Trengs for � drive TMDS klokken (pikselklokke) ut av kretsen
ODDR2 #(
.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
.INIT(1'b0), // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
) ODDR2_TMDSclock (
.Q(pixclkout), // 1-bit DDR output data
.C0(pixclk), // 1-bit clock input
.C1(~pixclk), // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(1'b1), // 1-bit data input (associated with C0)
.D1(1'b0), // 1-bit data input (associated with C1)
.R(1'b0), // 1-bit reset input
.S(1'b0) // 1-bit set input
);

////////////
wire clk12out,clkCPU,pllLocked;

//Generer 12Mhz for � drive MAX3421 kretsen.  Og 5,10 eller 14 Mhz for � drive CPUen.
clk12 clockgen
 (// Clock in ports
  .CLK_IN1(clk_50M),      // IN
  // Clock out ports
  .CLK_OUT12(clk12out),     // OUT
  .CLK_OUT5(clkCPU),     // OUT
  .CLK_OUT10(),     // OUT
  .CLK_OUT14(),     // OUT
  // Status and control signals
  .RESET(1'b0),// IN
  .LOCKED(pllLocked));      // OUT
	 
//Trengs for � drive klokke ut av kretsen
//12Mhz
ODDR2 #(
.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
.INIT(1'b0), // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
) ODDR2_clk12usb (
.Q(clk12usb), // 1-bit DDR output data
.C0(clk12out), // 1-bit clock input
.C1(~clk12out), // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(1'b1), // 1-bit data input (associated with C0)
.D1(1'b0), // 1-bit data input (associated with C1)
.R(1'b0), // 1-bit reset input
.S(1'b0) // 1-bit set input
);

///////////////////////////////////////////////////////////////////////////

// MEMORY
////////////////////////////////////////////////////////////////////////
wire [15:0] vmemabus;
wire [15:0] vmemabus_mod;
wire [7:0] vmemdbus;

wire [15:0] cpuabus;			//CPU adressebus
wire [7:0] cpudbusO;			//CPU databus ut
wire [7:0] cpudbusI;			//CPU dabus inn
wire [7:0] memcpudbusI;		//Data ut fra minne, inn til CPU
wire cpuWrite;					//Er h�y n�r CPUen skriver, motsatt av en fysisk 6502.

wire [10:0] chrabusV;		//Character ROM adressebuss for video output
wire [7:0] chrdbusV;			//Character ROM databuss for video output

//Skal egentlig v�re 12:0, tom for ram.  M� dele opp blokkramen.
wire [10:0] colabusV;		//Farge RAM for video out
wire [7:0] coldbusV;

assign vmemabus_mod = (btn1)?(vmemabus):
							(btn2)?(vmemabus + 16'h4B00):	//Start vidmemLo
							 vmemabus+16'hB100;				//Start vidmemHi

video_mem vmem1 (
  .clka(clkCPU), // input clka
  .ena(1'b1), // input ena
  .wea(cpuWrite), // input [0 : 0] wea
  .addra(cpuabus), // input [15 : 0] addra
  .dina(cpudbusO), // input [7 : 0] dina
  .douta(memcpudbusI), // output [7 : 0] douta
  .clkb(pixclk), // input clkb
  .web(1'b0), // input [0 : 0] web
  .addrb(vmemabus_mod), // input [15 : 0] addrb
  .dinb(8'b00000000), // input [7 : 0] dinb
  .doutb(vmemdbus) // output [7 : 0] doutb
);

charrom_CP865 charmem (
  .a(11'b0), // input [10 : 0] a
  .d(8'b0), // input [7 : 0] d
  .dpra(chrabusV), // input [10 : 0] dpra
  .clk(pixclk), // input clk
  .we(1'b0), // input we
  .spo(), // output [7 : 0] spo
  .dpo(chrdbusV) // output [7 : 0] dpo
);

colour_mem colmem (
  .a(13'b0), // input [12 : 0] a
  .d(8'b0), // input [7 : 0] d
  .dpra(colabusV), // input [12 : 0] dpra
  .clk(pixclk), // input clk
  .we(1'b0), // input we
  .spo(), // output [7 : 0] spo
  .dpo(coldbusV) // output [7 : 0] dpo
);
////////////////////////////////////////////////////////////////////////
// CPU
cpu cpu1 (
    .clk(clkCPU), 
    .reset(~pllLocked), 
    .AB(cpuabus), 
    .DI(cpudbusI), 
    .DO(cpudbusO), 
    .WE(cpuWrite), 
    .IRQ(cpuIRQ), 
    .NMI(1'b0), 
    .RDY(~btn3)
    );

//Data i UART generer interrupt
assign cpuIRQ = ~rx_empty;
/////////////////////////////////////////////////////////////////////////
// UART
wire [7:0] uart_rx_data;
reg [7:0] uart_tx_data;
wire rd_uart,wr_uart;
wire rx_empty,tx_full;


uart uart1 (
    .clk(clkCPU), 
    .reset(~pllLocked), 
    .rd_uart(rd_uart), 
    .wr_uart(wr_uart), 
    .rx(UART_RX), 
    .w_data(uart_tx_data), 
    .tx_full(tx_full), 
    .rx_empty(rx_empty), 
    .tx(UART_TX), 
    .r_data(uart_rx_data)
    );

/////////////////////////////////////////////////////////////////////////
//SPI
wire spi_Start_transfer;
wire spi_Busy;
wire spi_New_data;
reg [7:0] spi_Data_in;
wire [7:0] spi_Data_out;
reg spi_SSusb_reg=1'b0;

assign spi_SSusb = ~spi_SSusb_reg;
assign usb_RES = pllLocked;

spi SPI_master1 (
    .clk(clk_50M), 
    .rst(~pllLocked), 
    .miso(spi_MISO), 
    .mosi(spi_MOSI), 
    .sck(spi_SCK), 
    .start(spi_Start_transfer), 
    .data_in(spi_Data_in), 
    .data_out(spi_Data_out), 
    .busy(spi_Busy), 
    .new_data(spi_New_data)
    );

/////////////////////////////////////////////////////////////////////////
//Coprocessor
///////////
reg [31:0] mulResult;
reg [7:0] mulFacAlo,mulFacAhi,mulFacBlo,mulFacBhi;
always @(posedge clkCPU)
	mulResult = {mulFacAhi,mulFacAlo} * {mulFacBhi,mulFacBlo};
	


//wire timer_int10ms;
//intTimer timer10ms (
//	.clk(clk_50M),
//	.count(18'd5000000),
//	.interrupt(timer_int10ms)
//	);
//assign cpuNMI=timer_int10ms;

wire [7:0] randout;
lfsr rand1 (
    .clk(clkCPU), 
    .reset(~pllLocked), 
    .en(1'b1), 
    .q(randout)
    );
/////////////////////////////////////////////////////////////////////////
// CPU IO
////////////////////////////////////////////////////////////////////////
reg [7:0] ledstat = 0;
assign led = ledstat;
reg [15:0] cpuabus_reg;
reg cpuWrite_reg;
reg [1:0] gfxMode = 2'b0;

//N�r vi skriver til adresse 65000 skriver vi i virkeligheten til lysdiodene	
always @(posedge clkCPU)
	begin
		if((cpuabus == 65000) && cpuWrite)
			ledstat <= cpudbusO;
	end

//Skriving til 65003 skriver til UART TX bufferet	
always @(posedge clkCPU)
	begin
		if((cpuabus == 65003) && cpuWrite)
			uart_tx_data <= cpudbusO;
		else if(cpuabus == 65007 && cpuWrite)
			spi_SSusb_reg <= cpudbusO[1];
		else if(cpuabus == 65006 && cpuWrite)
			spi_Data_in <= cpudbusO;
	end

//Skriving til 65005 skriver til UART kontrollregisteret.
//D0: Start TX
//D1: Data i RX lest (hent neste fra FIFO)
assign rd_uart = (cpuabus == 65005 && cpuWrite) ? cpudbusO[1] : 1'b0;
assign wr_uart = (cpuabus == 65005 && cpuWrite) ? cpudbusO[0] : 1'b0;

assign spi_Start_transfer = (cpuabus == 65007 && cpuWrite) ? cpudbusO[0] : 1'b0;
	
//HW multiplikator faktor A = 65010,65011, B = 65012,65013
always @(posedge clkCPU)
	begin
		if((cpuabus == 65010) && cpuWrite)
			mulFacAlo <= cpudbusO;
	end	
always @(posedge clkCPU)
	begin
		if((cpuabus == 65011) && cpuWrite)
			mulFacAhi <= cpudbusO;
	end	
always @(posedge clkCPU)
	begin
		if((cpuabus == 65012) && cpuWrite)
			mulFacBlo <= cpudbusO;
	end	
always @(posedge clkCPU)
	begin
		if((cpuabus == 65013) && cpuWrite)
			mulFacBhi <= cpudbusO;
	end
//gfxMode bit 1 lavt: Textmodus
//gfxMode bit 1 h�yt: Grafikkmodus	
always @(posedge clkCPU)
	begin
		if((cpuabus == 65018) && cpuWrite)
			gfxMode <= cpudbusO[1:0];
	end	
	
//Data input bussen til CPUen m� forsinkes en syklus n�r den ikke leser fra synkron BRAM.
always @(posedge clkCPU)
	begin
		cpuabus_reg <= cpuabus;
		cpuWrite_reg <= cpuWrite;
	end
	
//Lesing fra adresse 65001 vil lese dilswitchene
//Lesing fra adresse 65002 vil lese data i UART RX buffer
//Lesing fra adresse 65004 vil lese UART status D0: TX full, D1: RX tom
//65014-65017 HW multiplikator resultat
//65018 Pseudo random generator
assign cpudbusI = ((cpuabus_reg == 65001) && ~cpuWrite_reg) ? dilswitch :

						(cpuabus_reg == 65002 && ~cpuWrite_reg)? uart_rx_data :
						(cpuabus_reg == 65004 && ~cpuWrite_reg)? {6'b000000,rx_empty,tx_full} :
						
						(cpuabus_reg == 65009 && ~cpuWrite_reg)? {6'b000000,spi_New_data,spi_Busy} :
						(cpuabus_reg == 65008 && ~cpuWrite_reg)? spi_Data_out :
						
						(cpuabus_reg == 65014 && ~cpuWrite_reg)? mulResult[7:0] :
						(cpuabus_reg == 65015 && ~cpuWrite_reg)? mulResult[15:8] :
						(cpuabus_reg == 65016 && ~cpuWrite_reg)? mulResult[23:16] :
						(cpuabus_reg == 65017 && ~cpuWrite_reg)? mulResult[31:24] :
						
						(cpuabus_reg == 65019 && ~cpuWrite_reg)? randout :
						memcpudbusI;

/////////////////////////////////////////////////////////////////////////
// VIDEO OUTPUT
wire [2:0] TMDS;

HDMIoutput HDMIout (
    .clk_TMDS(clk_TMDS), 
    .pixclk(pixclk),
	 .gfxMode(gfxMode),
    .vmemdbus(vmemdbus), 
    .vmemabus(vmemabus), 
    .TMDS(TMDS),
	 .chrabus(chrabusV), 
    .chrdbus(chrdbusV),
	 .coldbus(coldbusV),
	 .colabus(colabusV)
    );

//Differensial utgangsbuffer
OBUFDS OBUFDS_red  (.I(TMDS[2]), .O(TMDSp[2]), .OB(TMDSn[2]));
OBUFDS OBUFDS_green(.I(TMDS[1]), .O(TMDSp[1]), .OB(TMDSn[1]));
OBUFDS OBUFDS_blue (.I(TMDS[0]), .O(TMDSp[0]), .OB(TMDSn[0]));
OBUFDS OBUFDS_clock(.I(pixclkout), .O(TMDSp_clock), .OB(TMDSn_clock));


endmodule
//////////////////////////////////////////////////////////////////////////
//Timer
module intTimer(
input clk,
input [18:0] count,
output reg interrupt
);
	reg [18:0] counter=0;
	always @(posedge clk)
		begin
			if(counter >= count)
				begin
					interrupt <= 1'b1;
					counter <= 18'd0;
				end
			else
				begin
					interrupt <= 1'b0;
					counter <= counter + 1'b1;
				end
		end
endmodule
/////////////////////////////////////////////////////////////////////////
//Pseudorandom generator
module lfsr(input clk, reset, en, output reg [7:0] q);
  always @(posedge clk or posedge reset) begin
    if (reset)
      q <= 8'd1; // can be anything except zero
    else if (en)
      q <= {q[6:0], q[7] ^ q[5] ^ q[4] ^ q[3]}; // polynomial for maximal LFSR
  end
endmodule
