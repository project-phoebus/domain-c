{ lang/lang/source/error_listing.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/error_listing.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ ERROR_LISTING - diagnostics: error0..error3 report an error code at a
  source line with 0 to 3 arguments through the front end's errorlst,
  first saving each (when listing with -EXP) for print_error to report
  again at its line.  error_listing.pas (cc.m68k 0x0AC634..0x0AC9BA,
  cc.a88k 0x0AE014..0x0AE39A).  The code and the line are words by
  value (callers: `move.w line,-(SP); move.w #code,-(SP)', the line
  often the front end's current line); each argument is a longword, an
  address (`pea', `move.l').

  Not known from the original: the parameter names and the arguments'
  type (anything: identifier nodes, constant nodes, strings). }

{ TODO(pascal) error_listing's arguments are univ_ptr by value

  The callers push an address for each argument and error1..error3
  copy the slots into an array of longwords; whether the original
  declared them as pointers or otherwise is not decidable from the
  image. }

type
  { An error's arguments (error1..error3 copy theirs to a local array;
    save_errors copies 12 bytes). }
  error_listing_$args_t = array [1..3] of univ_ptr;

  { A saved error (26 bytes, from pas_$new): save_errors builds the
    list, print_error walks it, c_error's error_not_printed (nested in
    errorlst) searches it from error_listing_first. }
  error_listing_$ptr_t = ^error_listing_$t;
  error_listing_$t = record
    args: error_listing_$args_t;        { +0 }
    next: error_listing_$ptr_t;         { +12 }
    code: integer;                      { +16 }
    nargs: integer;                     { +18 }
    line: integer;                      { +20 }
    x16: integer;                       { +22: 63 from every caller;
                                          nothing reads it }
    printed: boolean;                   { +24: cleared by save_errors,
                                          tested by print_error }
  end;

{ SAVE_ERRORS - append an error to the list unless it repeats the last
  one.  0x0AC634: every parameter by address (error0..error3 `pea' their
  frame slots and constants). }
procedure save_errors(
    in line: integer;
    in code: integer;
    in args: error_listing_$args_t;
    in nargs: integer;
    in x16: integer); extern;

{ ERROR0..ERROR3 - 0x0AC728, 0x0AC78A, 0x0AC7F2, 0x0AC862. }
procedure error0(
    code: integer;
    line: integer); options(val_param); extern;

procedure error1(
    code: integer;
    line: integer;
    a1: univ_ptr); options(val_param); extern;

procedure error2(
    code: integer;
    line: integer;
    a1: univ_ptr;
    a2: univ_ptr); options(val_param); extern;

procedure error3(
    code: integer;
    line: integer;
    a1: univ_ptr;
    a2: univ_ptr;
    a3: univ_ptr); options(val_param); extern;

{ PRINT_ERROR - report again the saved errors of line.  0x0AC8E0:
  line by address (c_lex_pp's advance_listing_to_line passes its
  current line's cell). }
procedure print_error(
    in line: integer); extern;


var
  { error_listing.pas's data (A5 0x2C3168 cc.m68k, 0x4431D8 cc.a88k):
    +0 print_error's place in the list and +4 the list's last entry
    (the unit's own), then: }
  { +0x8: the list's first entry (c_error's error_not_printed). }
  error_listing_first: extern error_listing_$ptr_t;
  { +0xC: a boolean outbin's wr_instr sets and clears (st, clr.b) and
    c_error, c_lex_pp and iosub test (tst.b); while it is set
    error0..error3 save nothing.  Its meaning is not known. }
  error_listing_0c: extern boolean;
