{ lang/common/source/diag.ins.pas - DIAG_, the compilers' diagnostic
  output: text formatted by VFMT_ control strings, gathered into a line
  and written behind a prefix (which callers push and pop to indent).

  No Apollo copy survives; the headings are read off the diag module
  (lang/common/source/diag.pas) and its callers in cc.m68k and cc.a88k
  of DOMAIN C 6.9.  It stands alone, naming no type of another insert:
  diag.pas opens it before /sys/ins/base.ins.pas and vfmt.ins.pas, and
  std.pas opens it with no other insert (their .blocks file lists).
  Every by-value parameter is passed by value: the routines are
  val_param (a 16-bit value takes a 2-byte slot: DIAG_$DROP_AND_YIELD_
  PREFIX's second parameter is at (10,A6)).

  Not known from the original: every type and parameter name here.
}

type
  { A control string or an argument, as VFMT_ takes them (VFMT_'s string
    type is array [1..200] of char). }
  diag_$string_t = array [1..200] of char;
  diag_$arg_t = integer32;

  { The varying strings the prefix routines take and give. }
  diag_$vstring_t = varying [200] of char;

{ DIAG_$WRITE - format the control string with up to ten arguments
  (VFMT_ conventions, each passed by address) onto the current line.
  0x06845A: the control string at (8,A6), the arguments at
  (12,A6)..(48,A6), all passed on to VFMT_$ENCODE. }
procedure diag_$write(
    in control_string: univ diag_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ diag_$arg_t); options(variable, val_param); extern;

{ DIAG_$WRITELN - DIAG_$WRITE, then end the line.  0x0684FA. }
procedure diag_$writeln(
    in control_string: univ diag_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ diag_$arg_t); options(variable, val_param); extern;

{ DIAG_$NEW_LINE - write the line (behind its prefix) and start a new
  one.  0x06855A. }
procedure diag_$new_line; extern;

{ DIAG_$ASSURE_FRESH_LINE - end the line unless nothing has been
  written to it.  0x0685C2. }
procedure diag_$assure_fresh_line; extern;

{ DIAG_$TAB_TO_WITH_FILL - fill the line with fill up to column (at most
  200).  0x0685DE: column a longword at (8,A6), fill a char at (12,A6). }
procedure diag_$tab_to_with_fill(
    column: integer32;
    fill: char); options(val_param); extern;

{ DIAG_$TAB_TO - DIAG_$TAB_TO_WITH_FILL with blanks.  0x06863E. }
procedure diag_$tab_to(
    column: integer32); options(val_param); extern;

{ DIAG_$CURRENT_COLUMN - the line's length.  0x06865E. }
function diag_$current_column: integer32; extern;

{ DIAG_$SET_PREFIX - append s to the prefix (to at most 200 characters);
  old_length is what to give DIAG_$DROP_PREFIX to undo it.  0x068676. }
procedure diag_$set_prefix(
    in s: univ diag_$vstring_t;
    out old_length: integer); options(val_param); extern;

{ DIAG_$DROP_PREFIX - cut the prefix back to old_length.  0x0686DC. }
procedure diag_$drop_prefix(
    old_length: integer); options(val_param); extern;

{ DIAG_$DROP_AND_YIELD_PREFIX - cut the prefix back to old_length and
  give what is cut.  0x0686F8. }
procedure diag_$drop_and_yield_prefix(
    old_length: integer;
    out yielded: univ diag_$vstring_t); options(val_param); extern;

{ DIAG_$INDENT - append n blanks to the prefix (to at most 200
  characters); old_length as DIAG_$SET_PREFIX's.  0x068754. }
procedure diag_$indent(
    n: integer32;
    out old_length: integer); options(val_param); extern;

{ DIAG_$BANNER - title on a fresh line, a blank, then `=' to column 83.
  0x0687BE. }
procedure diag_$banner(
    in title: univ diag_$string_t); options(val_param); extern;
