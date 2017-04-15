; MAX3421E support header												

; MAX3421E command byte format: rrrrr0wa where 'r' is register number	
;
wrREG = $2
; MAX3421E Registers in HOST mode. 
;
rRCVFIFO	= $08	;1<<3
rSNDFIFO	= $10	;2<<3
rSUDFIFO	= $20	;4<<3
rRCVBC		= $30	;6<<3
rSNDBC		= $38	;7<<3

rUSBIRQ		= $68	;13<<3
; USBIRQ Bits	
bmVBUSIRQ   = $40	;b6
bmNOVBUSIRQ = $20	;b5
bmOSCOKIRQ  = $01	;b0

rUSBIEN		= $70	;14<<3
; USBIEN Bits	
bmVBUSIE    = $40	;b6
bmNOVBUSIE  = $20	;b5
bmOSCOKIE   = $01	;b0

rUSBCTL 	= $78	;15<<3
; USBCTL Bits	
bmCHIPRES   = $20	;b5
bmPWRDOWN   = $10	;b4

rCPUCTL		= $80	;16<<3
; CPUCTL Bits	
bmPUSLEWID1	= $80	;b7
bmPULSEWID0 = $40	;b6
bmIE        = $01	;b0

rPINCTL = $88	;17<<3
; PINCTL Bits	
bmFDUPSPI   = $10	;b4
bmINTLEVEL  = $08	;b3
bmPOSINT    = $04	;b2
bmGPXB      = $02	;b1
bmGPXA      = $01	;b0
; GPX pin selections
GPX_OPERATE	= $00
GPX_VBDET	= $01
GPX_BUSACT	= $02
GPX_SOF		= $03

rREVISION 	= $90	;18<<3

rIOPINS1 	= $a0	;20<<3

; IOPINS1 Bits	
bmGPOUT0    = $01
bmGPOUT1    = $02
bmGPOUT2    = $04
bmGPOUT3    = $08
bmGPIN0     = $10
bmGPIN1     = $20
bmGPIN2     = $40
bmGPIN3     = $80

rIOPINS2 	= $a8	;21<<3
; IOPINS2 Bits	
bmGPOUT4    = $01
bmGPOUT5    = $02
bmGPOUT6    = $04
bmGPOUT7    = $08
bmGPIN4     = $10
bmGPIN5     = $20
bmGPIN6     = $40
bmGPIN7     = $80

rGPINIRQ	= $b0	;22<<3
; GPINIRQ Bits 
bmGPINIRQ0 = $01
bmGPINIRQ1 = $02
bmGPINIRQ2 = $04
bmGPINIRQ3 = $08
bmGPINIRQ4 = $10
bmGPINIRQ5 = $20
bmGPINIRQ6 = $40
bmGPINIRQ7 = $80

rGPINIEN	= $b8	;23<<3
; GPINIEN Bits 
bmGPINIEN0 = $01
bmGPINIEN1 = $02
bmGPINIEN2 = $04
bmGPINIEN3 = $08
bmGPINIEN4 = $10
bmGPINIEN5 = $20
bmGPINIEN6 = $40
bmGPINIEN7 = $80

rGPINPOL 	= $c0	;24<<3
; GPINPOL Bits 
bmGPINPOL0 = $01
bmGPINPOL1 = $02
bmGPINPOL2 = $04
bmGPINPOL3 = $08
bmGPINPOL4 = $10
bmGPINPOL5 = $20
bmGPINPOL6 = $40
bmGPINPOL7 = $80

rHIRQ		= $c8	;25<<3
; HIRQ Bits 
bmBUSEVENTIRQ   = $01   ; indicates BUS Reset Done or BUS Resume     
bmRWUIRQ        = $02
bmRCVDAVIRQ     = $04
bmSNDBAVIRQ     = $08
bmSUSDNIRQ      = $10
bmCONDETIRQ     = $20
bmFRAMEIRQ      = $40
bmHXFRDNIRQ     = $80

rHIEN 		= $d0	;26<<3
; HIEN Bits 
bmBUSEVENTIE    = $01
bmRWUIE         = $02
bmRCVDAVIE      = $04
bmSNDBAVIE      = $08
bmSUSDNIE       = $10
bmCONDETIE      = $20
bmFRAMEIE       = $40
bmHXFRDNIE      = $80

rMODE		= $d8	;27<<3
; MODE Bits 
bmHOST          = $01
bmLOWSPEED      = $02
bmHUBPRE        = $04
bmSOFKAENAB     = $08
bmSEPIRQ        = $10
bmDELAYISO      = $20
bmDMPULLDN      = $40
bmDPPULLDN      = $80

rPERADDR	= $e0	;28<<3

rHCTL		= $e8	;29<<3
; HCTL Bits 
bmBUSRST        = $01
bmFRMRST        = $02
bmSAMPLEBUS     = $04
bmSIGRSM        = $08
bmRCVTOG0       = $10
bmRCVTOG1       = $20
bmSNDTOG0       = $40
bmSNDTOG1       = $80



rHXFR		= $f0	;30<<3
; Host transfer token values for writing the HXFR register (R30)	
; OR this bit field with the endpoint number in bits 3:0				
tokSETUP  = $10  ; HS=0, ISO=0, OUTNIN=0, SETUP=1
tokIN     = $00  ; HS=0, ISO=0, OUTNIN=0, SETUP=0
tokOUT    = $20  ; HS=0, ISO=0, OUTNIN=1, SETUP=0
tokINHS   = $80  ; HS=1, ISO=0, OUTNIN=0, SETUP=0
tokOUTHS  = $A0  ; HS=1, ISO=0, OUTNIN=1, SETUP=0 
tokISOIN  = $40  ; HS=0, ISO=1, OUTNIN=0, SETUP=0
tokISOOUT = $60  ; HS=0, ISO=1, OUTNIN=1, SETUP=0

rHRSL		= $f8	;31<<3
; HRSL Bits 
bmRCVTOGRD	= $10
bmSNDTOGRD	= $20
bmKSTATUS	= $40
bmJSTATUS	= $80
bmSE0		= $00	;SE0 - disconnect state
bmSE1		= $c0	;SE1 - illegal state		
; Host error result codes, the 4 LSB's in the HRSL register 
hrSUCCESS   = $00
hrBUSY      = $01
hrBADREQ    = $02
hrUNDEF     = $03
hrNAK       = $04
hrSTALL     = $05
hrTOGERR    = $06
hrWRONGPID  = $07
hrBADBC     = $08
hrPIDERR    = $09
hrPKTERR    = $0A
hrCRCERR    = $0B
hrKERR      = $0C
hrJERR      = $0D
hrTIMEOUT   = $0E
hrBABBLE    = $0F

MODE_FS_HOST = bmDPPULLDN|bmDMPULLDN|bmHOST|bmSOFKAENAB
MODE_LS_HOST = bmDPPULLDN|bmDMPULLDN|bmHOST|bmLOWSPEED|bmSOFKAENAB



