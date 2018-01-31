/*=========================================================================*
 *									   *
 *	SCREEN - convert SCREEN code files to plain ASCII. 		   *
 *									   *
 *=========================================================================*
 *									   *
 *	(C) Copyright 1995 by Olaf Seibert, KosmoSoft.                     *
 *	May not be sold or used for any commercial purpose.		   *
 *	May be distributed freely as long as this notice is retained.	   *
 *									   *
 *=========================================================================*
 *									   *
 *Fixed Bug: Prints { for CTRL-[ and [ for SHIFT-CTRL-[.		   *
 *	     Analogous for [ \ ] ^ _.					   *
 *									   *
 *									   *
 *									   *
 *									   *
 *=========================================================================*/

#include <stdio.h>

#define PETSHIFT(c)    ((c) | 0x80)
#define CTRL(c)        ((c) - 0x40)

main(argc, argv)
int argc;
char *argv[];
{
    register int ch;
    register int rvs;
    register FILE *in = stdin;
    register FILE *out = stdout;
#undef stdin
#undef stdout
#define stdin	in
#define stdout	out

    while ((ch = getchar()) != EOF) {
	rvs = ch & 0x80;
	ch &= 0x7F;

	if (ch < 0x20) {	/* lower case letters */
	    ch += 0x60;
	} else if (ch < 0x40) {	/* punctuation */
	    ;
	} else if (ch < 0x60) {	/* upper case letters */
	    ;
	} else			/* shifted punctuation: graphics */
	    ch = '_';

	if (rvs)
	    printf("\x1b[4m%c\x1b[0m", ch);
	else
	    putchar(ch);
    }

    return 0;
}
