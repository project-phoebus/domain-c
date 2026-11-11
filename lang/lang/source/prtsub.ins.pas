{ lang/lang/source/prtsub.ins.pas - PRTSUB, building a printed line: a
  varying string of at most 256 characters, appended to by character,
  string, boolean, decimal and hexadecimal number, and tab.

  No Apollo copy survives; the headings are read off prtsub.pas (cc.m68k
  0x09829C..0x09852A) and its callers.  Counts, widths and values by value
  (val_param), the line and strings by address.

  Not known from the original: every type and parameter name here.
}

const
  prtsub_$max_line = 256;               { every bound in prtsub.pas }

type
  prtsub_$line_t = varying [256] of char;
  prtsub_$chars_t = array [1..256] of char;

{ PRTCATC - c to the end of s, unless s is full.  0x09829C. }
procedure prtcatc(
    in out s: prtsub_$line_t;
    c: char); options(val_param); extern;

{ PRTCATS - n characters of t to the end of s, as many as fit.
  0x0982C6. }
procedure prtcats(
    in out s: prtsub_$line_t;
    in t: univ prtsub_$chars_t;
    n: integer); options(val_param); extern;

{ PRTCATB - `true' or `false' to the end of s.  0x09832C. }
procedure prtcatb(
    in out s: prtsub_$line_t;
    b: boolean); options(val_param); extern;

{ PRTINT - n in decimal to the end of s: a `-' first when negative; with
  zero_fill, zeros in front to width digits; more digits than width lose
  the leading ones.  0x098378. }
procedure prtint(
    in out s: prtsub_$line_t;
    n: integer32;
    width: integer;
    zero_fill: boolean); options(val_param); extern;

{ PRTHEX - the last width of n's eight hexadecimal digits to the end of
  s.  0x098456. }
procedure prthex(
    in out s: prtsub_$line_t;
    n: integer32;
    width: integer); options(val_param); extern;

{ PRTTAB - blanks to the end of s until it is column - 1 long (at most
  256).  0x0984A8. }
procedure prttab(
    in out s: prtsub_$line_t;
    column: integer); options(val_param); extern;

{ PRTSUB_$EQUAL - whether a and b are the same characters.  0x0984E2. }
function prtsub_$equal(
    in a: prtsub_$line_t;
    in b: prtsub_$line_t): boolean; extern;
