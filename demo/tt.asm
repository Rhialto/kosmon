	processor 6502

pet	= 1
c64	= 2

target	= c64

    if target == c64

r6510	= $1
verck_bas	= $A
txttab	= $2B
fretop	= $33
memsiz	= $37
chrget	= $73
status	= $90
verck_os	= $93
mybitcount	= $A3
riprty	= $AB
sal	= $AC
eal	= $AE
tape1	= $B2
fnlen	= $B7
sa	= $B9
fnadr	= $BB
roprty	= $BD
cas1	= $C0
memuss	= $C3
datax	= $D7
irqtmp	= $29f
igone	= $308
iload	= $330
tbuffr	= $33C
newstt	= $A7AE
igone_org	= $A7E7
stop_bas	= $A82C
synerr	= $AF08
viccr1	= $D011
cia1icr	= $DC0D
cia2tbl	= $DD06
cia2tbh	= $DD07
cia2icr	= $DD0D
cia2crb	= $DD0F
maybeloaderrror	= $E17A
slpara	= $E1D4	; get parameters for load/save - 3:f43e, 4:f47d
ealtoxy	= $F5A9
printloading	= $F5D2
prsaving	= $F68F
printfound	= $F750
pressplayontape	= $F817
waitrecordplay	= $F838

motoroff	= $FC93	; also reset irq and cia to normal

	endif

getin	= $FFE4

mystart	= $9c00
mychecksum = datax
myleaderlen = riprty
mytapebyte = roprty

	ORG mystart

L9C00:
L9C02	= . + 2
; Instruction parameter accessed to determine location of code.
	JMP init

	if target == c64
	org mystart + $10
	endif

	; Check if we must lower the top of memory pointer

adjust_fretop:
	LDA #<mystart
	TAX
	SEC
	SBC memsiz
	LDA L9C02	; == >mystart
	TAY
	SBC memsiz+1
	BCS L9C26
L9C1E:
	STX memsiz
	STY memsiz+1
	STX fretop
	STY fretop+1
L9C26:
	RTS

	if target == c64
	; This makes the startup-sys for the $9c00 version 40000

	org mystart + $40

	endif

init:
	JSR adjust_fretop
	LDA #<wedge
	STA igone
	STY igone+1
	RTS

wedge:
	JSR chrget
	BEQ L9C64
L9C60:
	CMP #$5F	; left-arrow
	BEQ L9C67
L9C64:
	JMP igone_org
L9C67:
	JSR chrget
	CMP #"S"
	BEQ arrows
L9C6E:
	CMP #"L"
	BEQ arrowl
L9C72:
	CMP #"V"
	BEQ arrowv
L9C76:
	JMP synerr

arrows:
	JSR chrget
	JSR dosave
	JMP newstt
arrowl:
	JSR chrget
	JSR doload
	JMP newstt
arrowv:
	JSR chrget
	JSR dovrfy
	JMP newstt

dosave:
	LDX #$5
	STX myleaderlen
	JSR slpara
	LDX #$4
L9CF9:
	LDA txttab-1,X
	STA sal-1,X
	DEX
	BNE L9CF9

	JSR waitrecordplay
	JSR prsaving
	JSR motoron
	JSR writeleader
	LDA sa
	CLC
	ADC #$1
	DEX		; X governs write timing throughout
	JSR writebyte	; write 1 or 2 (SA+1) to indicate header block
	LDX #$8
L9D17:
	LDA sal,Y	; write start and end addresses
	JSR writebyte
	LDX #$6
	INY
	CPY #$5
	NOP
	BNE L9D17

	LDY #$0		; write the file name
	LDX #$4
L9D29:
	LDA (fnadr),Y
	CPY fnlen
	BCC L9D32

	LDA #$20	; pad it with spaces
	DEX
L9D32:
	JSR writebyte
	LDX #$5
	INY
	CPY #$BB	; at end of a $C0 bytes buffer?
	BNE L9D29

			; now start on the program data block
L9D3C:
	LDA #$2
	STA myleaderlen
	JSR writeleader	; Y becomes 0
	TYA		; 0
	JSR writebyte	; 0 after leader indicates prg data block
	STY mychecksum
	LDX #$7
	NOP

L9D4C:
	LDA (sal),Y	; get byte from memory
	JSR writebyte	; write it
	LDX #$3
	INC sal		; increment address
	BNE L9D5B

	INC sal+1
	DEX		; adjust timing
	DEX
L9D5B:
	LDA sal		; check if at end yet
	CMP eal
	LDA sal+1
	SBC eal+1
	BCC L9D4C	; loop while sal < eal

	NOP
L9D66:
	LDA mychecksum	; checksum
	JSR writebyte
	LDX #$7
	DEY
	BNE L9D66	; write it 256 times

	INY
	STY cas1	; interlock: turn off motor
	CLI		; allow interrupts
	CLC		; indicate success
	LDA #$0		; indicate to leave irq alone
	STA irqtmp+1
	JMP motoroff	; also reset irq and cia to normal

motoron:
	LDY #$0		; allow motor to be on
	STY cas1	; (tape motor interlock)

	LDA viccr1	; screen off
	AND #$EF
	STA viccr1

L9D89			; delay a bit
	DEX		; probably so that the irq can
	BNE L9D89	; turn on the cassette motor
	DEY
	BNE L9D89
	SEI		; disable interrupts
	RTS

writeleader:
	LDY #$0		; count where we are in the leader page
L9D93:
	LDA #$2		; write 02 bytes at first
	JSR writebyte
	LDX #$7
	DEY
	CPY #$9		; but the 9 last bytes will be different
	BNE L9D93

	LDX #$5
	DEC myleaderlen	; length of leader in pages
	BNE L9D93
L9DA5:
	TYA		; write 09, 08, ... 01.
	JSR writebyte
	LDX #$7
	DEY
	BNE L9DA5
	DEX
	DEX
	RTS

writebyte:
	STA mytapebyte	; byte to write
	EOR mychecksum	; checksum
	STA mychecksum
	LDA #$8
	STA mybitcount
L9DBB:
	ASL mytapebyte
	LDA r6510	; set write line to 0
	AND #$F7
	JSR writebit	; write a bit as indicated by .C
	LDX #$11	; set timing
	NOP
	ORA #$8		; set write line to 1
	JSR writebit	; write a bit as indicated by .C
	LDX #$E		; set timing
	DEC mybitcount
	BNE L9DBB	; loop while not 8 bits done

	RTS

writebit:		; delay first. The more code there is between
	DEX		; successive calls of this routine, the smaller
	BNE writebit	; .X should be set.
	BCC L9DDD	; if writing a 1,
	LDX #$B		; delay some more
L9DDA:
	DEX
	BNE L9DDA
L9DDD:
	STA r6510	; finally change the write line as indicated
	RTS

doload:
	LDX #$0		; load
	dc.b $2c	; bit.zpg
dovrfy
	LDX #$1		; verify

	LDY txttab
	LDA txttab+1
	STX verck_bas
	STX verck_os
	STY memuss
	STA memuss+1
	JSR slpara	; get load/save params
	JSR loadprg
	JMP maybeloaderrror ; and reset CHRGET

loadprg:
	JSR readheader
	LDA myleaderlen
	CMP #$2		; check type (= SA+1). 2 = abs. load
	BEQ L9E0E

	CMP #$1		; not 1 (relocatable load) -> find next
	BNE loadprg
	LDA sa
	BEQ L9E18	; sa == 0: rel. load.
L9E0E:
	LDA tbuffr	; absolute load:
	STA memuss	; use addresses as saved
	LDA tbuffr+1
	STA memuss+1
L9E18:
	JSR printfound

;L9E1B:
;	JSR getin	; wait for a keypress
;	BEQ L9E1B

	JSR stop_bas	; allow a BREAK to basic
	LDY fnlen	; check if correct filename
	BEQ L9E32
L9E27:
	DEY
	LDA (fnadr),Y	; name as given by user
	CMP tbuffr+5,Y	; name as found
	BNE loadprg	; not equal: find next program
	TYA
	BNE L9E27

L9E32:
	STY status	; clear ST
	JSR printloading ; print loading or verifying
	LDA tbuffr+1+1	; adjust load address:
	SEC		; loadend := savedend - savestart + loadstart
	SBC tbuffr
	PHP
	CLC
	ADC memuss
	STA eal
	LDA tbuffr+3
	ADC memuss+1
	PLP
	SBC tbuffr+1
	STA eal+1
	JSR loadmem
	LDA mytapebyte
	EOR mychecksum	; must be 00
	ORA status
	BEQ L9E5E

	LDA #$FF	; set ST in case of load error
	STA status
L9E5E:
	JMP ealtoxy	; load EAL into X and Y, as per normal LOAD.

readheader:
	JSR findleader
	CMP #$0
	BEQ readheader

	STA myleaderlen
L9E6A:
	JSR readbyte
	STA (tape1),Y
	INY
	CPY #$C0
	BNE L9E6A

	BEQ stoptape

loadmem:
	JSR findleader
L9E79:
	JSR readbyte	; MUST be 00 for the next line to work
	CPY verck_os
	BNE L9E82
	STA (memuss),Y
L9E82:
	CMP (memuss),Y
	BEQ L9E88
	STX status	; load error
L9E88:
	EOR mychecksum	; update checksum
	STA mychecksum

	INC memuss	; increment load address
	BNE L9E92
	INC memuss+1
L9E92:
	LDA memuss
	CMP eal		; at end yet?
	LDA memuss+1
	SBC eal+1
	BCC L9E79

	JSR readbyte
	JSR motoron
	INY

stoptape:
	STY cas1
	CLI
	CLC
	LDA #$0
	STA irqtmp+1
	JMP motoroff	; also reset irq and cia to normal

findleader:
	JSR pressplayontape
	JSR motoron
	STY mychecksum
	LDA #$7
	STA cia2tbl	; timer low byte
	LDX #$1		; timer high byte
L9EBE:
	JSR readbit	; read a bit
	ROL mytapebyte	; look at every bit position
	LDA mytapebyte
	CMP #$2		; to syncronise with the 02 bytes in a leader
	BNE L9EBE

	LDY #$9		; were synced now - find the 09 .. 01 sequence
L9ECB:
	JSR readbyte
	CMP #$2		; that follows the 02 bytes
	BEQ L9ECB
L9ED2:
	CPY mytapebyte	; look for the 09 first
	BNE L9EBE	; if wrong, restart unsynchronised
	JSR readbyte	; check the next byte
	DEY
	BNE L9ED2
L9EDC:
	RTS		; okay, ready to read the type now

readbyte:
	LDA #$8
	STA mybitcount
L9EE1:
	JSR readbit
	ROL mytapebyte
	NOP		; room to put a sta $d021 or something like that
	NOP
	NOP
	DEC mybitcount
	BNE L9EE1

	LDA mytapebyte
	RTS

readbit:
	LDA #$10	; flag bit in interrupt control/flag register
L9EF2:			; "flag" triggers on 1->0 edges
	BIT cia1icr
	BEQ L9EF2

	LDA cia2icr	; remember the timer b underflow bit
	STX cia2tbh	; reload the timer latch, not the timer itself yet
	PHA
	LDA #$19	; %0001 1001: start timer B, one-shot, force load
	STA cia2crb	; do it
	PLA
	LSR ;A		; get bit 1 (timer b underflow)
	LSR ;A		; into the carry
	RTS

	if target == c64
	org mystart + $0308
	; This brings us to 53000 for the $cc00 version

patchiload:
	LDA #<niload	; low byte for iload vector
	LDY L9C02	; get starting page
	INY		; plus $0300
	INY
	INY
	STA iload
	STY iload+1
	RTS

niload:
	STA verck_os
	JSR loadprg
	LDA #$0
	STA status
	LDA mytapebyte
	EOR mychecksum
	BEQ L9F31
L9F2F:
	DEC status
L9F31:
	RTS
L9F32:
	dc.b "_ALLOAD VIATURBO!!!",0

	endif

	dc.b "25091984",0
	dc.b "19011995",0
