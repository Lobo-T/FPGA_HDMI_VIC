#define println(TEXTADR) PHA:LDA #<TEXTADR:STA loAdr:LDA #>TEXTADR:STA hiAdr:JSR prtStr:JSR prtCRLN:PLA
#define BLT BCC
#define BGE BCS

#include io.asm
#include max3421.asm

	*=0000

;Zeropage pointer adresse for funksjonskall
	loAdr = $00
	hiAdr = $01
;Disse brukes kun under USB konfigurasjon og kan gjenbrukes senere
	counter1 = $02
	usbBuffer = $03		; 64 bytes
	usbBufferEnd = $42 	;
	usbThisDescriptor = $43
	usbNextDescriptor = $44
	usbKbdOK = $45
	.dsb $46
CursorPos:
	.byt 0,$96	
DrawPos: 
	.byt 0,$96
CurrChar:
	.byt 0
Jiffyclock:
	.byt 0,0,0,0


	;*= $2000
	.dsb $0200-*
	
	CLC
	XCE
	REP #$30
	.al
	.xl
	LDA #$01FF
	TCS
	LDA #$0000
	TCD
	SEP #$30
	.as 
	.xs
	
	LDA #$C0		;Background colour
	STA $FBC0
	
	LDA #0
	STA Jiffyclock
	STA Jiffyclock+1
	STA Jiffyclock+2
	STA Jiffyclock+3
	
	;Bank1 memtest
	LDA #1
	STA @$010000
	LDA #23
	STA @$010001
	LDA #42
	STA @$020004
	
	JSR prtCRLN
	LDA @$010000
	TAX
	JSR prtHexChr
	LDA @$010001
	TAX
	JSR prtHexChr
	LDA @$020004
	TAX
	JSR prtHexChr
	JSR prtCRLN
	
	;LDX #$FF  ;Kjent verdi for toppen av stacken
	;TXS
	;-----
;Send tekst til seriellporten
	LDX #0
	JMP serloop
tekststart:
	.asc "Trond Mjåtveit Hansen designer datamaskin"  ;Lang tekst for å fylle UART fifoen
	.byt 10,13  ;\r\n
tekstslutt:

serloop
	LDA #1
	AND 65004	;Sjekk om UART FIFO er full
	BNE serloop	;Vent på UART
	LDA tekststart,x
	STA 65003
	LDA #1
	STA 65005
	INX
	CPX #tekstslutt-tekststart
	BNE serloop

	;debug
	;JMP SDcardReset
;--------------------
;USB setup

	;Set full duplex
	LDX #rPINCTL
	LDY #bmFDUPSPI|bmPOSINT|bmGPXB
	JSR wrUSBreg

	;Set LED
	LDX #rIOPINS1
	LDY #bmGPOUT0
	JSR wrUSBreg

	;RESET MAX3421
	LDX #rUSBCTL
	LDY #bmCHIPRES
	JSR wrUSBreg
	LDX #rUSBCTL
	LDY #00
	JSR wrUSBreg
	
	;Get OSCOK
	;Vent til MAX3421s PLL har låst
WAIT_OSC_LOOP:
	LDX #rUSBIRQ
	JSR rdUSBreg
	AND #bmOSCOKIRQ
	BEQ WAIT_OSC_LOOP
	;debug
	println(TXT_OSC_STARTET)

	;Sett host mode.  Slå på pulldown
	LDX #rMODE
	LDY #bmDPPULLDN|bmDMPULLDN|bmHOST
	JSR wrUSBreg

	LDX #rMODE
	JSR rdUSBreg
	TAX
	println(TXT_MODE)
	JSR prtHexChr
	JSR prtCRLN

	;Initialise toggle values
	LDX #rHCTL
	LDY #bmRCVTOG0|bmSNDTOG0
	JSR wrUSBreg

	LDX #rHCTL
	LDY #bmSAMPLEBUS
	JSR wrUSBreg

WAIT_SAMPLEBUS:
	LDX #rHCTL
	JSR rdUSBreg
	AND #bmSAMPLEBUS
	BEQ WAIT_SAMPLEBUS

	println(TXT_SAMPLEBUS)

WAIT_JK_STATUS:
	LDX #rHRSL
	JSR rdUSBreg
	TAX

	println(TXT_HRSL)
	JSR prtHexChr
	JSR prtCRLN

	TXA
	AND #bmJSTATUS
	BNE USB_FULLSPEED_HOST
	TXA
	AND #bmKSTATUS
	BNE USB_LOSPEED_HOST

	println(TXT_NO_KBD)

	JMP MAIN

USB_LOSPEED_HOST:
	LDX #rMODE
	LDY #MODE_LS_HOST
	JSR wrUSBreg
	println(TXT_LO_SPEED)
	JMP USB_ENUMERATE

USB_FULLSPEED_HOST:
	LDX #rMODE
	LDY #MODE_FS_HOST
	JSR wrUSBreg
	println(TXT_FULL_SPEED)
	JMP USB_ENUMERATE

USB_ENUMERATE:
USB_BUSRESET:
	LDX #rHCTL
	LDY #bmBUSRST
	JSR wrUSBreg

USB_BUSRESET_LOOP:
	LDX #rHCTL
	JSR rdUSBreg
	AND bmBUSRST
	BNE USB_BUSRESET_LOOP
	println(TXT_USB_RESET)

	JSR prtCRLN
	LDX #rMODE
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	JSR prtCRLN

	println(TXT_WAIT)

	.(
	;Wait 200 frames 
	LDA #200
	STA counter1
USB_WAITFRAME_LOOP:
	LDX #rHIRQ
	LDY #bmFRAMEIRQ
	JSR wrUSBreg
USB_READ_FIRQ_LOOP:
	LDX #rHIRQ
	JSR rdUSBreg
	TAX
	;JSR prtHexChr
	AND #bmFRAMEIRQ
	BEQ USB_READ_FIRQ_LOOP
	DEC counter1
	BNE USB_WAITFRAME_LOOP
	;200 frames
	.)

	;Set USB adresse 0
	LDX #rPERADDR
	LDY #00
	JSR wrUSBreg

	;------------Get descriptor--------------------------
	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	LDX #rSUDFIFO
	LDY #$80
	JSR wrUSBreg
	;bRequest USB GET_DESCRIPTOR = 6
	LDX #rSUDFIFO
	LDY #6
	JSR wrUSBreg
	;wValue low
	LDX #rSUDFIFO
	LDY #0		
	JSR wrUSBreg
	;wValue high
	LDX #rSUDFIFO
	LDY #2			;Configuration
	JSR wrUSBreg
	;wIndex low
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wIndex high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wLength low
	LDX #rSUDFIFO
	LDY #64
	JSR wrUSBreg
	;wLength high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokSETUP
	JSR wrUSBreg

	.(
	JSR prtCRLN
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	JSR prtCRLN
	.)

	println(TXT_GET_DESCRIPTOR)
	;--Data in stage
	;Set receive toggle 1
	LDX #rHCTL
	LDY #bmRCVTOG1
	JSR wrUSBreg

	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokIN
	JSR wrUSBreg
	.(
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	JSR prtCRLN
	.)
	LDX #rRCVBC
	JSR rdUSBreg
	TAY
	TAX
	println(TXT_LENGTH)
	JSR prtHexChr
	JSR prtCRLN

	LDX #usbBuffer
	STX counter1
DescrLab1:
	LDX #rRCVFIFO
	JSR rdUSBreg
	;TAX
	;JSR prtHexChr
	;JSR prtCRLN
	LDX counter1
	STA usbBuffer,x
	INC counter1
	DEY
	BNE DescrLab1

	;Read rcvFIFO
	LDX #rHIRQ
	LDY #bmRCVDAVIRQ
	JSR wrUSBreg

	;Print buffer
	LDY #usbBuffer
	PRINTBUF_LOOP:
	LDX	usbBuffer,y
	jsr prtHexChr
	jsr prtCRLN
	INY
	DEC counter1
	BNE PRINTBUF_LOOP

	println(TXT_GET_DESCRIPTOR_END)
	;--Statusstage--
	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokOUTHS
	JSR wrUSBreg

	.(
	JSR prtCRLN
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	.)
	;----get desc end---
	;-Tolk descriptors
	;Første descriptor skal være en configuration descriptor siden det er det vi har bedt om
	LDY #usbBuffer
	STY usbThisDescriptor
	LDA usbBuffer,y
	STA usbNextDescriptor	;Ta vare på desc. lengde
	TYA
	CLC
	ADC usbNextDescriptor
	STA usbNextDescriptor	;Ta vare på offset for neste descriptor
	LDY usbThisDescriptor
	TYA
	CLC
	ADC	#8					;Power
	JSR prtCRLN
	println(TXT_POWER)
	TAY
	LDA usbBuffer,y
	TAX
	JSR prtHexChr
	JSR prtCRLN

	;Neste skal være en Interface descriptor
SearchInterfaceDesciptor:
	LDY usbNextDescriptor
	STY usbThisDescriptor
	LDA usbBuffer,y
	STA usbNextDescriptor	;Descriptor lengde
	TYA
	CLC
	ADC usbNextDescriptor
	STA usbNextDescriptor	;Descriptor offset
	INY	;type
	LDA usbBuffer,y
	CMP	#4		;interface type
	BNE DescParseError
	INY			;IF number
	INY			;Alt setting
	INY			;NumEndpoint
	INY			;IF class
	LDA usbBuffer,y
	println(TXT_KBD_CLASS)
	TAX
	JSR prtHexChr
	JSR prtCRLN
	CMP	#3		;HID class
	BNE DescParseError
	INY			;SubClass
	LDA usbBuffer,y
	println(TXT_KBD_SUBCLASS)
	TAX
	JSR prtHexChr
	JSR prtCRLN
	CMP #1		;Boot IF
	BNE DescParseError
	INY			;Protocol
	LDA usbBuffer,y
	println(TXT_KBD_PROTOCOL)
	TAX
	JSR prtHexChr
	JSR prtCRLN
	CMP #1		;Keyboard
	BNE DescParseError
	JMP SearchEndpointDescriptor

DescParseError:		;Denne er plassert her i midten for å være innenfor branch lengde
	LDA #00
	STA usbKbdOK
	println(TXT_UNKNOWN)
	JMP ParseDone

SearchEndpointDescriptor:
	println(TXT_USB_SEARCH)
	LDY usbNextDescriptor
	STY usbThisDescriptor
	LDA usbBuffer,y
	STA usbNextDescriptor
	TYA
	CLC
	ADC usbNextDescriptor
	STA usbNextDescriptor
	CMP	#usbBufferEnd
	BCS DescParseError	;Buffer overrun
	INY					;DescriptorType
	LDA usbBuffer,y
	TAX
	JSR prtHexChr
	JSR prtCRLN
	CMP #5
	BNE	SearchEndpointDescriptor
	;Da skal vi være i første endpoint descriptor.
	INY					;Endpoint Addresse
	LDA usbBuffer,y
	AND #%00001111		;Vi er bare interessert i addressen som er i de fire laveste bitene.
	STA UsbKbdEPAdr
	println(TXT_KBD_EP)
	TAX
	JSR prtHexChr
	JSR prtCRLN
	LDA #01
	STA usbKbdOK

	JMP ParseDone

ParseDone:
	;-----------Set address-----------
	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	;Set address setup request
	;bmRequestType Request Host to device, standard, recipient device
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;bRequest USB SET ADDRESS = 5
	LDX #rSUDFIFO
	LDY #5
	JSR wrUSBreg
	;wValue low
	LDX #rSUDFIFO
	LDY #1
	JSR wrUSBreg
	;wValue high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wIndex low
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wIndex high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wLength low
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wLength high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokSETUP
	JSR wrUSBreg
	.(
	JSR prtCRLN
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	.)
	;--Statusstage--
	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokINHS
	JSR wrUSBreg

	.(
	JSR prtCRLN
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	.)
	;----------Set address end----------

	;Set USB adresse 1
	LDX #rPERADDR
	LDY #1
	JSR wrUSBreg
	.(
	;Wait 200 frames
	LDA #200
	STA counter1
USB_WAITFRAME_LOOP:
	LDX #rHIRQ
	LDY #bmFRAMEIRQ
	JSR wrUSBreg
	USB_READ_FIRQ_LOOP:
	LDX #rHIRQ
	JSR rdUSBreg
	TAX
	;JSR prtHexChr
	AND #bmFRAMEIRQ
	BEQ USB_READ_FIRQ_LOOP
	DEC counter1
	BNE USB_WAITFRAME_LOOP
	;200 frames
	.)


	;----------Set configuration----
	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	;bmRequestType Request Host to device, standard, recipient device
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;bRequest USB SET CONFIGURATION = 9
	LDX #rSUDFIFO
	LDY #9
	JSR wrUSBreg
	;wValue low
	LDX #rSUDFIFO
	LDY #1
	JSR wrUSBreg
	;wValue high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wIndex low
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wIndex high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wLength low
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wLength high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokSETUP
	JSR wrUSBreg

	.(
	JSR prtCRLN
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	.)

	;--Statusstage--
	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokINHS
	JSR wrUSBreg

	.(
	JSR prtCRLN
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	.)
	;------------Set conf end-------
	;----------Set protocol----
	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	;bmRequestType Request Host to device, standard, recipient device
	LDX #rSUDFIFO
	LDY #%00100001
	JSR wrUSBreg
	;bRequest SET PROTOCOL
	LDX #rSUDFIFO
	LDY #$0B
	JSR wrUSBreg
	;wValue low
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wValue high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wIndex low
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wIndex high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wLength low
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg
	;wLength high
	LDX #rSUDFIFO
	LDY #0
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokSETUP
	JSR wrUSBreg

	.(
	JSR prtCRLN
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	.)
	;--Statusstage--
	;Reset transfer done IRQ
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	LDX #rHXFR
	LDY #tokINHS
	JSR wrUSBreg

	.(
	JSR prtCRLN
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	TAX
	JSR prtHexChr
	.)
	;------------Set protocol end-------
	.(
	;Wait 200 frames 
	LDA #200
	STA counter1
	USB_WAITFRAME_LOOP:
	LDX #rHIRQ
	LDY #bmFRAMEIRQ
	JSR wrUSBreg
	USB_READ_FIRQ_LOOP:
	LDX #rHIRQ
	JSR rdUSBreg
	TAX
	;JSR prtHexChr
	AND #bmFRAMEIRQ
	BEQ USB_READ_FIRQ_LOOP
	DEC counter1
	BNE USB_WAITFRAME_LOOP
	;200 frames
	.)
;--------------------------------------------
SDcardReset:
	LDY #$ff
	LDX #100
.(
spiTXwait:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait
	STY bSPI_TX
	LDA #$00|bmSPI_CTRL_wr_spi
	STA bSPI_CTRL
	DEX
	BNE spiTXwait
	.)
	println(TESTSDC)
	;GO_IDLE_STATE
	LDA #%01000000
	JSR sendSPISDCbyte
	LDA #%00000000
	JSR sendSPISDCbyte
	LDA #%00000000
	JSR sendSPISDCbyte
	LDA #%00000000
	JSR sendSPISDCbyte
	LDA #%00000000
	JSR sendSPISDCbyte
	LDA #%10010101
	JSR sendSPISDCbyte
	LDA #00
	JSR sendSPISDCbyte
	
	;Status
.(
	LDY #30
spiTXwait:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait
	LDA #$ff
	STA bSPI_TX
	LDA #bmSPI_CTRL_SSsdcard|bmSPI_CTRL_wr_spi
	STA bSPI_CTRL
spiTXwait2:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait2	
	LDX bSPI_RX
	JSR prtHexChr
	DEY
	BNE spiTXwait
	.)
	
	JSR prtCRLN
	
CMD8:
	.(
spiTXwait:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait
	.)
	println(TESTSDC)
	;GO_IDLE_STATE
	LDA #%01001000
	JSR sendSPISDCbyte
	LDA #%00000000
	JSR sendSPISDCbyte
	LDA #%00000000
	JSR sendSPISDCbyte
	LDA #%00000001
	JSR sendSPISDCbyte
	LDA #%10101010
	JSR sendSPISDCbyte
	LDA #%10000111
	JSR sendSPISDCbyte

	.(
	LDY #30
spiTXwait:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait
	LDA #$ff
	STA bSPI_TX
	LDA #bmSPI_CTRL_SSsdcard|bmSPI_CTRL_wr_spi
	STA bSPI_CTRL
spiTXwait2:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait2	
	LDX bSPI_RX
	JSR prtHexChr
	DEY
	BNE spiTXwait
	.)
	
	;-----
	println(TESTSDCEND)
;-----------------------------------------------------------------------------------------------
	;Test print string
	JSR prtCRLN
	println(TESTSTRNG1)
	
	JMP MAIN



TESTSTRNG1: .byt "Boot complete",0
TESTSDC: .byt "SD card test",0
TESTSDCEND: .byt "SD card test END",0

;Addresse og endpoint for tilkoplet USB tastatur
UsbKbdAdr: .byt 0
UsbKbdEPAdr: .byt 0
KbdLastKey: .byt 0
KbdLocks: .byt 0
KbdModifiers: 
KbdKeyArray: .byt 0,0,0,0,0,0,0,0
;---------------------------------------------------------------------------------
;--------------------MAIN---------------------------------------------------------
;---------------------------------------------------------------------------------

MAIN:
	CLI	;Enable interrupts

	LDA #0
	STA DrawPos
	LDA #$96
	STA DrawPos+1
	;----
	LDA #176
	LDY #0
	STA (DrawPos),y
	
	;HW screenpos kalkulator
	LDX #40
	STX bScreenX
	LDX #30
	STX bScreenY
	LDX bScreenAdrLo
	STX DrawPos
	LDX bScreenAdrHi
	STX DrawPos+1
	STA (DrawPos),Y
	
	;----
	
	LDX #$0
	
loop1
	;Kopier Jiffyclk til LEDs
	LDA Jiffyclock+1
	STA bLEDPORT

	;Sjekk om F2 er inne og skift grafikkmodus
	LDA #59
	CMP KbdKeyArray+2
	BNE F2NOT
	LDA #bmGFX_MODE_BM160
	JMP F2END
F2NOT:
	LDA #bmGFX_MODE_TEXT
F2END:
	STA bGFX_MODE
	
	;Sjekk om F1 er inne
	LDA #58				;USB keycode for F1
	CMP KbdKeyArray+2	;Første tast
	BNE GetInputAndDraw
Demo1:
	LDX CurrChar
	LDA bRandom
	STA $E900,X		;Colmem
	STA $E100,X		;Charmem
	LDY #0
	STA (DrawPos),y
	INC DrawPos
	BNE Demo1Next
	INC DrawPos+1
	LDA DrawPos+1
	CMP #$e1
	BNE Demo1Next
	LDA #$96
	STA DrawPos+1
	INC CurrChar
	
GetInputAndDraw:
	JSR kbdrd
	BCS KbdNext
	JSR sendUARTchar
	LDY #0
	STA (CursorPos),y
IncCursorPos:
	INC CursorPos
	BNE IncCursorPosNext
	INC	CursorPos+1
IncCursorPosNext:

KbdNext:
Demo1Next:
	JMP loop1

;--------------------------------------------------------------------------
;----------FUNKSJONER------------------------------------------------------
;--------------------------------------------------------------------------
	;Print null terminated string.  Startadresse i loAdr og hiAdr.
prtStr:
	PHA
	TYA
	PHA
	LDY #$00
prtStrLoop1:
	LDA #bmUART_STATUS_tx_full
	AND bUART_STATUS
	BNE prtStrLoop1:
	LDA (loAdr),Y
	BEQ prtStrEnd
	STA bUART_TX
	LDA #bmUART_CTRL_wr_uart
	STA bUART_CTRL
	INY
	JMP prtStrLoop1
prtStrEnd:
	PLA
	TAY
	PLA
	RTS

	;Print \r\n
prtCRLN:
	PHA
	LDA #<STR_CRLN
	STA loAdr
	LDA #>STR_CRLN
	STA hiAdr
	JSR prtStr
	PLA
	RTS
STR_CRLN: .byt 10,13,00

	;Skriver en byte som hex til UART
	;Byte som skal printes i X
prtHexChr:
	PHA
	TXA
	PHA
	AND #%11110000
	CLC
	ROR
	ROR
	ROR
	ROR
	TAX
	LDA HEXCHAR_TABLE,X
	JSR sendUARTchar
	PLA
	PHA
	AND #%00001111
	TAX
	LDA HEXCHAR_TABLE,X
	JSR sendUARTchar
	PLA
	TAX
	PLA
	RTS

sendUARTchar:  ;Char i A
	PHA
sendUARTloop:
	LDA #bmUART_STATUS_tx_full
	AND bUART_STATUS
	BNE sendUARTloop
	PLA
	PHA
	STA bUART_TX
	LDA #bmUART_CTRL_wr_uart
	STA bUART_CTRL
	PLA
	RTS

HEXCHAR_TABLE: .byt "0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"
	;------------------------------------
	;SPI funksjoner
	;Write USB register.  Reg i X, val i Y
wrUSBreg:
	PHA
	TXA
	ORA #wrREG
	JSR sendSPIUSBbyte
	TYA
	JSR sendSPIUSBbyte
	LDA #00			;Fjern Slave Select
	STA bSPI_CTRL;
	PLA
	RTS

	;Read USB register.   Reg i X.  Resultat i A
rdUSBreg:
	TXA
	JSR sendSPIUSBbyte
	LDA #00
	JSR sendSPIUSBbyte
	LDA #00			;Fjern Slave Select
	STA bSPI_CTRL;
	LDA bSPI_RX
	RTS

	;Sender en byte til MAX3421
sendSPIUSBbyte:
.(
	PHA
spiTXwait:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait
	PLA
	STA bSPI_TX
	LDA #bmSPI_CTRL_SSusb
	STA bSPI_CTRL
	LDA #bmSPI_CTRL_SSusb|bmSPI_CTRL_wr_spi
	STA bSPI_CTRL
spiTXwait2:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait2
	RTS
	.)

sendSPISDCbyte:
.(
	PHA
spiTXwait:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait
	PLA
	STA bSPI_TX
	LDA #bmSPI_CTRL_SSsdcard
	STA bSPI_CTRL
	LDA #bmSPI_CTRL_SSsdcard|bmSPI_CTRL_wr_spi
	STA bSPI_CTRL
spiTXwait2:
	LDA #bmSPI_STATUS_busy
	AND bSPI_STATUS
	BNE spiTXwait2
	RTS
	.)
;------------

;Hent nytt tegn fra tastaturet.
;Ved ny tast returnerer tegn i Acc og Carry clear
;Ved ingen ny tast returnerer Carry set
;Vi bryr oss kun om første KeyCode.
;Men hele USB Boot protocol keyboard rapporten vil også være tilgjengelig i KbdKeyArray
kbdrd:
	;Reset transfer done
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg

	;Start new kbd in request
	.(
	LDX #rHXFR
	LDA UsbKbdEPAdr	;Hent endpoint adresse
	ORA #tokIN
	TAY
	JSR wrUSBreg
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	LDX #rHRSL
	JSR rdUSBreg
	.)
	AND #%00001111	;Fire laveste bit er transfer result koden
	CMP #4			;NAK, for kort tid siden sist vi leste
	BEQ NoNewKey
	LDY #0
rcvLoop2:
	LDX #rRCVFIFO
	JSR rdUSBreg
	STA KbdKeyArray,y
	INY
	CPY #8
	BNE rcvLoop2
	LDX #rHIRQ
	LDY #bmRCVDAVIRQ	 ;Reset rcv data available IRQ
	JSR wrUSBreg
	;Se om det er en ny tast
	LDY #2		;Offset for første keycode
	LDA KbdKeyArray,y
	CMP KbdLastKey
	BEQ NoNewKey
	STA KbdLastKey	;Husk hva vi leste sist.
	CMP #0
	BEQ NoNewKey	;Ikke rapporter nullverdi
	CMP #57			;CRUISE CONTROL FOR COOL!
	BEQ CapsLockPressed 
KbdGoTranslate:
	JSR KbdTranslate
	RTS
NoNewKey:
	SEC
	RTS
	;---
CapsLockPressed:
	LDA KbdLocks
	BIT #%00000010
	BEQ	CapsSet
CapsReset:
	AND #%11111101
	STA KbdLocks
	JMP KbdWriteLeds
CapsSet:
	ORA #%00000010
	STA KbdLocks

	KbdWriteLeds:
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg	;Reset transfer done
	
	LDX #rSUDFIFO
	LDY #%00100001	;bnRequestType Class
	JSR wrUSBreg
	LDY #9 			;SET_REPORT
	JSR wrUSBreg
	LDY #0				;wValueLow
	JSR wrUSBreg	
	LDY #2
	JSR wrUSBreg	;wValueHigh, 2 OUT
	LDY #0
	JSR wrUSBreg	;wIndexL
	JSR wrUSBreg	;wIndexH
	LDY #1			;1 byte data
	JSR wrUSBreg	;wLengthL 1
	LDY #0
	JSR wrUSBreg	;wLengthH
		
	LDX #rHXFR
	LDY #tokSETUP	;Endpoint 0.  
	JSR wrUSBreg
.(
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	
	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg	;Reset transfer done
.)
	LDX #rSNDFIFO
	LDY KbdLocks
	JSR wrUSBreg
	LDX #rSNDBC
	LDY #1			;1 byte
	JSR wrUSBreg
	LDX #rHCTL
	LDY #bmSNDTOG1
	JSR wrUSBreg
CapsLockOutData:
	LDX #rHXFR
	LDY #tokOUT
	JSR wrUSBreg
	
.(
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt
	.)

	LDX #rHIRQ
	LDY #bmHXFRDNIRQ
	JSR wrUSBreg	;Reset transfer done

	LDX #rHRSL
	JSR rdUSBreg
	AND #%00001111
	CMP #4
	BNE CapsLockHandshake
	JMP CapsLockOutData
CapsLockHandshake:
	LDX #rHXFR
	LDY #tokINHS
	JSR wrUSBreg
.(
XFRrslt:
	LDX #rHIRQ
	JSR rdUSBreg
	AND #bmHXFRDNIRQ
	BEQ XFRrslt

	LDX #rHRSL
	JSR rdUSBreg
	AND #%00001111
	CMP #4
	BNE Next
	;println(TXT_NAK3)
	JMP CapsLockHandshake	;retry
Next:
	.)
	SEC
	RTS
	
KbdTranslate:
	TAX
	CMP #57
	BCS KbdNotPrintable
	LDA KbdLocks		;Bit 1 inneholder capslock status
	ORA KbdModifiers	;Fra USB rapport
	AND #%00100010		;Høyre og venstre shift fra USB keyboard.  Må fikses hvis bit 5 i KbdLocks brukes til noe.
	BNE KbdShift
	LDA	KbdLookupTable,x
	CLC
	RTS
KbdShift:
	LDA KbdLookupTableShifted,x
	CLC
	RTS
KbdNotPrintable:
	JSR prtHexChr
	SEC
	RTS
	;---

KbdLookupTable:
	.byt 0,0,0,0
	.byt "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
	.byt "1","2","3","4","5","6","7","8","9","0",13,27,8,9,32,"+",92,"å",94,"<","'","ø","æ",124,44,46,"-"
KbdLookupTableShifted:
	.byt 0,0,0,0
	.byt "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
	.byt "!",34,"#","$","%","&","/","(",")","=",13,27,8,9,32,"?","`","Å","~",">","*","Ø","Æ","§",59,58,"_"
KbdKeypadLookupTable:
	.byt "/","*","-","+",13,"1","2","3","4","5","6","7","8","9","0",46,"<"
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
	NOP
	NOP
	NOP
	NOP
	NOP
#include text.asm
	NOP
	NOP
	NOP
	NOP
	NOP
;-----------------------------------------------------------------------------------------------------
;	.dsb $f000-*
;Interrupthandler
Interrupthandler:
	;Save Acc,X,Y
	SEI
	PHA
	TXA
	PHA
	TYA
	PHA
	CLD

	;UART
	LDA #%00000010
	AND 65004
	BNE IR_UART_END
	JSR uartRXhandler
IR_UART_END

	;Restore Acc,X,Y
	PLA
	TAY
	PLA
	TAX
	PLA
	CLI
	;Return
	RTI
	;------------------
	;UART RX
uartRXhandler
	LDA 65002
	STA 65003
	LDA #%00000011  ;D1:RX read D0:TX start
	STA 65005
	RTS
	
NMIHandler:
	INC Jiffyclock
	BNE	NMIEnd
	INC Jiffyclock+1
	BNE NMIEnd
	INC Jiffyclock+2
	BNE NMIEnd
	INC Jiffyclock+3
NMIEnd:
	RTI
;----------------------------------------------------------------------------------------
;Vektorer
;	.dsb $fffa-*,$ff
	;NMI	$FFFA/$FFFB
;	.byt <NMIHandler,>NMIHandler
	;RESET	$FFFC/$FFFD	
;	.byt $00,$02
	;IRQ	$FFFE/$FFFF
;	.byt <Interrupthandler,>Interrupthandler
