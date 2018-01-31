;;;;
;
; .A *= 10 (%1010)
;
mul10:	sta tmp
	asl a
	asl a
	clc
	adc tmp
	asl a
	rts

tmp:	dc.b
;;;;
