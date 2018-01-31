####
#
#	Makefile for all versions of KOSMON
#

BASE	= 5000
AFLAGS	= -Dbase=$$$(BASE)

.SUFFIXES:	.asm .prg .lst

.asm.prg:
	dasm $< -o$*.prg $(AFLAGS)

.asm.lst:
	dasm $< -l$*.lst

all:	kosmon.prg kosmon.lst

kosmons:    kosmon-64.prg kosmon-8032.prg kosmon-4032.prg kosmon-3032.prg

copy.prg:	copy.asm
kosmon.prg:	kosmon.asm

kosmon-64.prg: kosmon.asm
	dasm kosmon.asm -Mtarget=c64 -Dpetb2=0 -Dpetb4=0 -Dpetb440=0 -Dpetb480=0 -okosmon-64.prg $(AFLAGS)

kosmon-8032.prg: kosmon.asm
	dasm kosmon.asm -Mtarget=pet -Dpetb2=0 -Dpetb4=1 -Dpetb440=0 -Dpetb480=1 -okosmon-8032.prg $(AFLAGS)

kosmon-4032.prg: kosmon.asm
	dasm kosmon.asm -Mtarget=pet -Dpetb2=0 -Dpetb4=1 -Dpetb440=1 -Dpetb480=0 -okosmon-4032.prg $(AFLAGS)

kosmon-3032.prg: kosmon.asm
	dasm kosmon.asm -Mtarget=pet -Dpetb2=1 -Dpetb4=0 -okosmon-3032.prg $(AFLAGS)

