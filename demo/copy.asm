	processor 6502

sal = $00c7
eal = $00c9

start1 =	$b000
end1 =		$e800
start2 =	$f000
end2 = 		$0000

latch = $fff0
latchrom = 0
latchram = $80 + $40 + $20

	org $0500
	
	sei 

	lda #<start1
	sta sal
	ldx #>start1
	lda #>end1
	jsr copypages

	ldx #>start2
	lda #>end2
	jsr copypages

	lda #latchram
	sta latch
	cli

	rts

copypages:
	ldy #0
copypages_y:
	sta eal+1
	stx sal+1

loop1:
	ldx #latchrom
	stx latch
	lda (sal),y
	ldx #latchram
	stx latch
	sta (sal),y
	dey
	bne loop1
	inc sal+1
	lda sal+1
	cmp eal+1
	bne loop1

	rts

	; end
