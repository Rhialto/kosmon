/*=========================================================================*
 *									   *
 *	PETSCII - convert PETSCII files to plain ASCII. 		   *
 *	SCREEN - convert SCREEN code files to plain ASCII. 		   *
 *	BASIC - convert saved BASIC files to plain ASCII.		   *
 *									   *
 *=========================================================================*
 *									   *
 *	(C) Copyright 1988,1995 by Olaf Seibert, KosmoSoft.                *
 *	May not be sold or used for any commercial purpose.		   *
 *	May be distributed freely as long as this notice is retained.	   *
 *									   *
 *=========================================================================*
 *									   *
 *Fixed Bug: Prints { for CTRL-[ and [ for SHIFT-CTRL-[.		   *
 *	     Analogous for [ \ ] ^ _.					   *
 *									   *
 *=========================================================================*/

#include <stdio.h>

#define PETSHIFT(c)    ((c) | 0x80)
#define CTRL(c)        ((c) - 0x40)

#define RVS	"\x1b[7m"	/* 4 = underline */
#define OFF	"\x1b[0m"
#define CHR	"\"+chr$(%d)+\""
#define BRAKET	"[%d]"

const char *gfxfmt = NULL;

int
print_screen(int ch, FILE *out)
{
    int rvs = ch & 0x80;
    ch &= 0x7F;

    if (ch < 0x20) {		/* lower case letters */
	if (ch > 'Z' - 'A' + 1)
	    ch -= 0x20;		/* Make [ print as [ */
	ch += 0x60;
    } else if (ch < 0x40) {	/* punctuation */
	;
    } else if (ch < 0x60) {	/* upper case letters */
	if (ch > 0x40 + 'Z' - 'A' + 1)
	    ch += 0x20;		/* Make shift-[\]^_ print as {|}~DEL */
    } else			/* shifted punctuation: graphics */
	ch = '_';

    if (rvs)
	fprintf(out, RVS "%c" OFF, ch);
    else
	putc(ch, out);
}

int
print_petscii(int ch, FILE *out)
{
    static int qmod = 0;

    if (ch < ' ') {
	if (ch == CTRL('M')) {
	    ch = '\n';
	    qmod = 0;
	} else if (qmod) {
	    if (gfxfmt) {
		printf(gfxfmt, ch);
	    } else {
		/* Quote-mode: reverse lower case */
		if (ch > CTRL('Z'))
		    ch -= 0x20; /* Make ctrl-[ print as [ */
		printf(RVS "%c" OFF, ch + 0x40 + 0x20);
	    }
	    return;
	}
    } else if (ch <= '@') {
	if (ch == '"')
	    qmod = !qmod;
    } else if (ch < '[')
	ch += 0x20;
    else if (ch < 96)
	;
    else if (ch < 128) {  /* Duplicates */
	if (qmod && gfxfmt) {
	    printf(gfxfmt, ch);
	    return;
	}
	ch -= 0x20;
    } else if (ch < PETSHIFT(' ')) {
	if (ch == PETSHIFT(CTRL('M'))) {
	    ch = '\n';
	    qmod = 0;
	} else if (qmod) {
	    /* Quote-mode: underlined upper case */
	    if (gfxfmt) {
		printf(gfxfmt, ch);
	    } else {
		if (ch > PETSHIFT(CTRL('Z')))
		    ch += 0x20; /* Make shift-ctrl-[ print as {  } */
		printf(RVS "%c" OFF, ch + 0x40 - 0x80);
	    }
	    return;
	}
    } else if (ch <= PETSHIFT('@')) {
	if (qmod && gfxfmt) {
	    printf(gfxfmt, ch);
	    return;
	}
	ch = '_';
    } else if (ch <= PETSHIFT('Z')) {
	ch += 'A' - PETSHIFT('A');
    } else {
	if (qmod && gfxfmt) {
	    printf(gfxfmt, ch);
	    return;
	}
	ch = '_';
    }

    putc(ch, out);
}

/* simple version */

int
make_petscii(int ch, FILE *out)
{
    if (ch == '\n') {
	ch = 13;
    } else if (ch >= 'A' && ch <= 'Z') {
	ch += -'A' + 0x41 + 0x80;
    } else if (ch >= 'a' && ch <= 'z') {
	ch += -'a' + 0x41;
    }
    putc(ch, out);
}

char *tokens[] = {
    /* Basic 1.0 */
    /*80*/"end", "for", "next", "data", "input#", "input", "dim", "read",
    /*88*/"let", "goto", "run", "if", "restore", "gosub", "return", "rem",
    /*90*/"stop", "on", "wait", "load", "save", "verify", "def", "poke",
    /*98*/"print#", "print", "cont", "list", "clr", "cmd", "sys", "open",
    /*a0*/"close", "get", "new", "tab(", "to", "fn", "spc(", "then",
    /*a8*/"not", "step", "+", "-", "*", "/", "^", "and",
    /*b0*/"or", ">", "=", "<", "sgn", "int", "abs", "usr",
    /*b8*/"fre", "pos", "sqr", "rnd", "log", "exp", "cos", "sin",
    /*c0*/"tan", "atn", "peek", "len", "str$", "val", "asc", "chr$",
    /*c8*/"left$", "right$", "mid$",
    /* Basic 2.0 */
    /*cb*/"go",
    /* Basic 4.0 */
    /*cc*/"concat", "dopen", "dclose", "record",
    /*d0*/"header", "collect", "backup", "copy", "append", "dsave", "dload", "append",
    /*d8*/"dsave", "dload", "catalog", "rename", "scratch", "directory",
    /* nonexistent */
    "[de]", "[df]",
    "[e0]", "[e1]", "[e2]", "[e3]", "[e4]", "[e5]", "[e6]", "[e7]",
    "[e8]", "[e9]", "[ea]", "[eb]", "[ec]", "[ed]", "[ee]", "[ef]",
    "[f0]", "[f1]", "[f2]", "[f3]", "[f4]", "[f5]", "[f6]", "[f7]",
    "[f8]", "[f9]", "[fa]", "[fb]", "[fc]", "[fd]", "[fe]", "[pi]"
};

void
basic(FILE *in, FILE *out)
{
    int ch;
    int word;
    int qmod = 0;

    word = getc(in);
    word += 256 * getc(in);
    printf("Load at $%04x\n", word);

    /* Special case for $0400 with extra 00 byte at the beginning */
    if ((word & 0xFF) == 0)
	getc(in);

    while ((ch = getc(in)) != EOF) {
	/* Get basic line link */
	word = ch;
	word += 256 * getc(in);
	if (word == 0)
	    break;
	/* Get line number */
	word = getc(in);
	word += 256 * getc(in);
	printf(" %d ", word);
	while ((ch = getc(in)) != EOF) {
	    if (ch == 0) {
		qmod = 0;
		print_petscii(13, stdout);
		break;
	    }
	    if (ch == 34)
		qmod = !qmod;
	    if (ch < 0x80 || qmod) {
		print_petscii(ch, stdout);
	    } else {
		fprintf(stdout, "%s", tokens[ch - 0x80]);
	    }
	}
    }
}

void
screen(FILE *in, FILE *out)
{
    int ch;

    while ((ch = getc(in)) != EOF) {
	print_screen(ch, out);
    }
}


void
petscii(FILE *in, FILE *out)
{
    int ch;

    while ((ch = getc(in)) != EOF) {
	print_petscii(ch, out);
    }
}

void
topetscii(FILE *in, FILE *out)
{
    int ch;

    while ((ch = getc(in)) != EOF) {
	make_petscii(ch, out);
    }
}


int
main(argc, argv)
int argc;
char *argv[];
{
    int bflag = 0;
    int sflag = 0;
    int tflag = 0;
    int i;

    for (i = 1; i < argc; i++) {
	if (strcmp(argv[i], "-s") == 0) {
	    sflag = 1;
	} else if (strcmp(argv[i], "-b") == 0) {
	    bflag = 1;
	} else if (strcmp(argv[i], "-chr") == 0) {
	    gfxfmt = CHR;
	    bflag = 1;
	} else if (strcmp(argv[i], "-bra") == 0) {
	    gfxfmt = BRAKET;
	    bflag = 1;
	} else if (strcmp(argv[i], "-t") == 0) {
	    tflag = 1;
	}
    }

    if (tflag) {
	topetscii(stdin, stdout);
    } else {
	if (bflag) {
	    basic(stdin, stdout);
	} else if (sflag) {
	    screen(stdin, stdout);
	} else {
	    petscii(stdin, stdout);
	}
    }

    return 0;
}
