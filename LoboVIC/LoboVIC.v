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
	input clk_50M,
	input btn1,btn2,
	input S1,S2,S3,
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
	output BE,
	input [23:0] AB,
	inout [7:0] DB,
	inout RDY,
	input VPA,
	input VDA,
	input R_WB,
	
	output USBRESB,
	output USBSS,
	output USBCLK,
	output spi_SCK,
	output spi_MOSI,
	input spi_MISO,
	input USBGPX,
	input USBINT,

	output RAM1_OEB,
	output RAM1_CEB,

	//output DDC_SCL,
	//inout DDC_SDA,
	
	output SS2
   );
	

//////////Clocking	
wire clk_TMDS, DCM_TMDS_CLKFX, pixclk, pixclkout, tmdsclk0;
wire clk_50M_bufg;

//Generer 25 Mhz HDMI pikselklokke og 250Mhz HDMI bitklokke
// 50Mhz / 2 = 25MHz
// 50MHz x 5 = 250MHz
DCM_SP #(.CLKFX_MULTIPLY(5),.CLKDV_DIVIDE(2)) 
	DCM_TMDS_inst(.CLKIN(clk_50M), .CLKFX(DCM_TMDS_CLKFX), .CLKDV(pixclk), .CLK0(tmdsclk0), .CLKFB(tmdsclk0), .PSEN(1'b0), .RST(1'b0),
	.CLK180(), .CLK270(), .CLK2X(), .CLK2X180(), .CLK90(), .CLKFX180(), .LOCKED(), .PSDONE(), .STATUS(), .DSSEN(), .PSCLK(), .PSINCDEC());

BUFG BUFG_TMDSp(.I(DCM_TMDS_CLKFX), .O(clk_TMDS));
BUFG BUFG_50M(.I(clk_50M), .O(clk_50M_bufg));

//Trengs for å drive TMDS klokken (pikselklokke) ut av kretsen
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
wire clk12out,clkCPU,clkCPU_180,clkMEM,pllLocked;

//Generer 12Mhz for å drive MAX3421 kretsen.  Og 5,10 eller 14 Mhz for å drive CPUen.
clk12 clockgen
 (// Clock in ports
  .CLK_IN1(clk_50M),      // IN
  // Clock out ports
  .CLK_OUT12(clk12out),     // OUT
  .CLK_OUT5(clkCPU),     // OUT
  .CLK_OUT5_180(clkCPU_180), // OUT
  .CLK_OUT10(clkMEM),
  // Status and control signals
  .RESET(1'b0),// IN
  .LOCKED(pllLocked));      // OUT
	 
//Trengs for å drive klokke ut av kretsen
//12Mhz
ODDR2 #(
.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
.INIT(1'b0), // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
) ODDR2_clk12usb (
.Q(USBCLK), // 1-bit DDR output data
.C0(clk12out), // 1-bit clock input
.C1(~clk12out), // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(1'b1), // 1-bit data input (associated with C0)
.D1(1'b0), // 1-bit data input (associated with C1)
.R(1'b0), // 1-bit reset input
.S(1'b0) // 1-bit set input
);

//Trengs for å drive klokke ut av kretsen
//PHI2
ODDR2 #(
.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
.INIT(1'b0), // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
) ODDR2_PHI2 (
.Q(PHI2), // 1-bit DDR output data
.C0(clkCPU), // 1-bit clock input
.C1(~clkCPU), // 1-bit clock input
.CE(1'b1), // 1-bit clock enable input
.D0(1'b1), // 1-bit data input (associated with C0)
.D1(1'b0), // 1-bit data input (associated with C1)
.R(1'b0), // 1-bit reset input
.S(1'b0) // 1-bit set input
);

//Trengs for å drive klokke ut av kretsen
//PHI2_180
ODDR2 #(
.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
.INIT(1'b0), // Sets initial state of the Q output to 1'b0 or 1'b1
.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
) ODDR2_PHI2_180 (
.Q(PHI2_180), // 1-bit DDR output data
.C0(clkCPU_180), // 1-bit clock input
.C1(~clkCPU_180), // 1-bit clock input
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
wire enableFPGAmem;
wire enableVmem;
wire enableColmem;
wire enableChrmem;

wire [15:0] cpuabus;			//CPU adressebus
wire [7:0] cpudbusO;			//CPU databus ut
wire [7:0] cpudbusI;			//CPU dabus inn
wire [7:0] memcpudbusI;		//Data ut fra minne, inn til CPU
wire [7:0] vmemcpudbusI;
wire [7:0] colmemcpudbusI;
wire [7:0] charmemcpudbusI;
wire cpuWrite;					//Er høy når CPUen skriver, motsatt av en fysisk 6502.

wire [10:0] chrabusV;		//Character ROM adressebuss for video output
wire [7:0] chrdbusV;			//Character ROM databuss for video output

wire [12:0] colabusV;		//Farge RAM for video out
wire [7:0] coldbusV;

assign vmemabus_mod = (S1)?(vmemabus):
							(S2)?(vmemabus + 16'h4B00):	//Start vidmemLo
							 vmemabus+16'h9600;				//Start vidmemHi

assign enableFPGAmem = ((AB[23:16] == 8'b00000000) && (VDA || VPA));							 
assign enableVmem = enableFPGAmem && (AB[15:0] < 16'hE100);
assign enableColmem = enableFPGAmem && (AB[15:0] >= 16'hE900) && (AB[15:0] < 16'hFD00);
assign enableChrmem = enableFPGAmem && (AB[15:0] >= 16'hE100) && (AB[15:0] < 16'hE900);

assign memcpudbusI = (enableColmem)	? (colmemcpudbusI)  : 
							(enableChrmem)	? (charmemcpudbusI) :
												  (vmemcpudbusI);

video_mem vmem1 (
  .clka(clkMEM), // input clka
  .ena(1'b1), // input ena
  .wea(cpuWrite && enableVmem), // input [0 : 0] wea
  .addra(cpuabus [15:0]), // input [15 : 0] addra
  .dina(cpudbusO), // input [7 : 0] dina
  .douta(vmemcpudbusI), // output [7 : 0] douta
  .clkb(pixclk), // input clkb
  .web(1'b0), // input [0 : 0] web
  .addrb(vmemabus_mod), // input [15 : 0] addrb
  .dinb(8'b00000000), // input [7 : 0] dinb
  .doutb(vmemdbus) // output [7 : 0] doutb
);

charrom_CP865 charmem (
  .a((cpuabus [15:0])-16'hE100), // input [10 : 0] a
  .d(cpudbusO), // input [7 : 0] d
  .dpra(chrabusV), // input [10 : 0] dpra
  .clk(clkMEM), // input clk
  .we(cpuWrite && enableChrmem), // input we
  .spo(charmemcpudbusI), // output [7 : 0] spo
  .dpo(chrdbusV) // output [7 : 0] dpo
);

colour_mem colmem (
  .clka(clkMEM), // input clka
  .ena(1'b1), // input ena
  .wea(cpuWrite && enableColmem), // input [0 : 0] wea
  .addra((cpuabus [15:0])-16'hE900), // input [12 : 0] addra
  .dina(cpudbusO), // input [7 : 0] dina
  .douta(colmemcpudbusI), // output [7 : 0] douta
  .clkb(pixclk), // input clkb
  .web(1'b0), // input [0 : 0] web
  .addrb(colabusV), // input [12 : 0] addrb
  .dinb(8'b0), // input [7 : 0] dinb
  .doutb(coldbusV) // output [7 : 0] doutb
);
////////////////////////////////////////////////////////////////////////
//Extern memory
//512k chip
assign RAM1_CEB = ~(((AB[23:20] == 4'b0000) && (AB[19:16] != 4'b0000)) && (VDA || VPA)); 
assign RAM1_OEB = ~(~RAM1_CEB && R_WB);

////////////////////////////////////////////////////////////////////////
//CPU signals
wire RDYout,RDYin;
assign BE = 1'b1;
assign RDYout = 1'b0;
assign cpuWrite = ~R_WB;

assign cpuabus = AB[15:0];
//Tristate
assign DB = (enableFPGAmem && R_WB) ? cpudbusI : 8'bz;	//tristate hvis annen bank er valgt
assign cpudbusO = DB;
assign RDY = (S3) ? RDYout : 1'bz;
assign RDYin = RDY;

assign RESB = pllLocked;

//Data i UART generer interrupt
assign IRQB = rx_empty;
assign NMIB = ~jiffyNMI;
/////////////////////////////////////////////////////////////////////////
// UART
wire [7:0] uart_rx_data;
reg [7:0] uart_tx_data;
wire rd_uart,wr_uart;
wire rx_empty,tx_full;


uart uart1 (
    .clk(~clkCPU), 
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
wire spi_Busy;
wire spi_New_data;
reg [7:0] spi_Data_in;
wire [7:0] spi_Data_out;
reg spi_SSusb_reg=1'b0;
reg spi_SSsdcard_reg =1'b0;
reg spi_Start_transfer;

assign USBRESB = pllLocked;
assign USBSS = ~spi_SSusb_reg;
assign SS2 = ~spi_SSsdcard_reg;

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
//Hardware mulitplicator
reg [31:0] mulResult;
reg [7:0] mulFacAlo,mulFacAhi,mulFacBlo,mulFacBhi;
always @(posedge clkCPU)
	mulResult = {mulFacAhi,mulFacAlo} * {mulFacBhi,mulFacBlo};

//Hardware videomemory X,Y to address calculator
reg [15:0] screenAddr;
reg [7:0] screenX,screenY;
always @(posedge clkCPU)
	begin
		if(gfxMode[1]==1'b1)
			screenAddr = (screenX + (screenY * 160)) + 16'h9600;
		else
			screenAddr = (screenX + (screenY * 80)) + 16'h9600;
	end
	
//Random number generator
wire [7:0] randout;
lfsr rand1 (
    .clk(clkCPU), 
    .reset(~pllLocked), 
    .en(1'b1), 
    .q(randout)
    );

//Jiffy generator
irq_gen jiffy (
    .clk(clk_50M_bufg), 
    .reset(~pllLocked), 
    .irq(jiffyNMI)
    );
	 
/////////////////////////////////////////////////////////////////////////
// CPU IO
////////////////////////////////////////////////////////////////////////
reg [7:0] ledstat = 0;
assign LED = ledstat;
reg [1:0] gfxMode = 2'b0;

////////////////////////////////////////////	
///////////////// CPU WRITE ////////////////
////////////////////////////////////////////

//Når vi skriver til adresse 65000 skriver vi i virkeligheten til lysdiodene	
always @(negedge clkCPU)
	begin
		if((cpuabus == 65000) && cpuWrite && enableFPGAmem)
			ledstat <= cpudbusO;
	end

//Skriving til 65003 skriver til UART TX bufferet	
always @(negedge clkCPU)
	begin
		if((cpuabus == 65003) && cpuWrite && enableFPGAmem)
			uart_tx_data <= cpudbusO;
		else if(cpuabus == 65007 && cpuWrite && enableFPGAmem)
			begin
				spi_SSusb_reg <= cpudbusO[1];
				spi_SSsdcard_reg <= cpudbusO[2];
				spi_Start_transfer <= cpudbusO[0];
			end
		else if(cpuabus == 65006 && cpuWrite && enableFPGAmem)
			spi_Data_in <= cpudbusO;
		else
			spi_Start_transfer <= 1'b0;
	end

//Skriving til 65005 skriver til UART kontrollregisteret.
//D0: Start TX
//D1: Data i RX lest (hent neste fra FIFO)
assign rd_uart = (cpuabus == 65005 && cpuWrite && enableFPGAmem) ? cpudbusO[1] : 1'b0;
assign wr_uart = (cpuabus == 65005 && cpuWrite && enableFPGAmem) ? cpudbusO[0] : 1'b0;

//assign spi_Start_transfer = (cpuabus == 65007 && cpuWrite) ? cpudbusO[0] : 1'b0;
	
//HW multiplikator faktor A = 65010,65011, B = 65012,65013
always @(negedge clkCPU)
	begin
		if((cpuabus == 65010) && cpuWrite && enableFPGAmem)
			mulFacAlo <= cpudbusO;
	end	
always @(negedge clkCPU)
	begin
		if((cpuabus == 65011) && cpuWrite && enableFPGAmem)
			mulFacAhi <= cpudbusO;
	end	
always @(negedge clkCPU)
	begin
		if((cpuabus == 65012) && cpuWrite && enableFPGAmem)
			mulFacBlo <= cpudbusO;
	end	
always @(negedge clkCPU)
	begin
		if((cpuabus == 65013) && cpuWrite && enableFPGAmem)
			mulFacBhi <= cpudbusO;
	end
	
always @(negedge clkCPU)
	begin
		if((cpuabus == 65020) && cpuWrite && enableFPGAmem)
			screenX <= cpudbusO;
	end
always @(negedge clkCPU)
	begin
		if((cpuabus == 65021) && cpuWrite && enableFPGAmem)
			screenY <= cpudbusO;
	end
	
//gfxMode bit 1 lavt: Textmodus
//gfxMode bit 1 høyt: Grafikkmodus	
always @(negedge clkCPU)
	begin
		if((cpuabus == 65018) && cpuWrite && enableFPGAmem)
			gfxMode <= cpudbusO[1:0];
	end	
	
////////////////////////////////////////////	
///////////////// CPU READ /////////////////
////////////////////////////////////////////

//Lesing fra adresse 65001 vil lese dilswitchene
//Lesing fra adresse 65002 vil lese data i UART RX buffer
//Lesing fra adresse 65004 vil lese UART status D0: TX full, D1: RX tom
//65014-65017 HW multiplikator resultat
//65018 Pseudo random generator
assign cpudbusI = //((cpuabus == 65001) && ~cpuWrite) ? dilswitch :

						(cpuabus == 65002 && ~cpuWrite && enableFPGAmem)? uart_rx_data :
						(cpuabus == 65004 && ~cpuWrite && enableFPGAmem)? {6'b000000,rx_empty,tx_full} :
						
						(cpuabus == 65009 && ~cpuWrite && enableFPGAmem)? {6'b000000,spi_New_data,spi_Busy} :
						(cpuabus == 65008 && ~cpuWrite && enableFPGAmem)? spi_Data_out :
						
						(cpuabus == 65014 && ~cpuWrite && enableFPGAmem)? mulResult[7:0] :
						(cpuabus == 65015 && ~cpuWrite && enableFPGAmem)? mulResult[15:8] :
						(cpuabus == 65016 && ~cpuWrite && enableFPGAmem)? mulResult[23:16] :
						(cpuabus == 65017 && ~cpuWrite && enableFPGAmem)? mulResult[31:24] :
						
						(cpuabus == 65019 && ~cpuWrite && enableFPGAmem)? randout :
						
						(cpuabus == 65022 && ~cpuWrite && enableFPGAmem)? screenAddr[7:0] :
						(cpuabus == 65023 && ~cpuWrite && enableFPGAmem)? screenAddr[15:8] :
						
						(cpuabus == 16'hffea && ~cpuWrite && enableFPGAmem)? 8'h52 :	//NMI
						(cpuabus == 16'hffeb && ~cpuWrite && enableFPGAmem)? 8'hd :
						(cpuabus == 16'hfffa && ~cpuWrite && enableFPGAmem)? 8'h52 :	//NMI
						(cpuabus == 16'hfffb && ~cpuWrite && enableFPGAmem)? 8'hd :

						(cpuabus == 16'hffee && ~cpuWrite && enableFPGAmem)? 8'h2e:		//IRQ
						(cpuabus == 16'hffef && ~cpuWrite && enableFPGAmem)? 8'hd :
						(cpuabus == 16'hfffe && ~cpuWrite && enableFPGAmem)? 8'h2e:		//IRQ
						(cpuabus == 16'hffff && ~cpuWrite && enableFPGAmem)? 8'hd :

						(cpuabus == 16'hfffc && ~cpuWrite && enableFPGAmem)? 8'h0 :		//Reset
						(cpuabus == 16'hfffd && ~cpuWrite && enableFPGAmem)? 8'h2 :
						
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

////////////////////////////////////////////////////////////////////////
//Generer interrupt hvert 10ms
module irq_gen
(
   input   clk, reset,
   output  irq
);

parameter  INTERVAL   = 'd500000,		//Hvert 10ms ved 50Mhz
           IRQ_LENGTH = 'd50;
           
localparam INT_W  = log2(INTERVAL);


reg [INT_W-1:0]      cnt_int;
reg [IRQ_LENGTH-1:0] irq_reg;


 always @(posedge clk or posedge reset)
    if ( reset )  
          cnt_int <= {INT_W{1'b0}};
    else
      if ( cnt_int == INTERVAL )  cnt_int <= 'h0;
      else                        cnt_int <= cnt_int + 1'b1;
           
 always @(posedge clk)
   if    ( cnt_int == INTERVAL )  irq_reg <= 'h1;
   else                           irq_reg <= irq_reg << 1;
  
assign irq = |irq_reg;

////////////  log2 function  //////////////
function integer log2;                   //
input [31:0] value;                      //
for (log2=0; value>0; log2=log2+1)       //
    value = value>>1;                    //
endfunction                              //
///////////////////////////////////////////

endmodule
////////////////////////////////////////////////////////////////////////////
