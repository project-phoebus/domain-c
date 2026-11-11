{ lang/lang/source/error_listing.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/error_listing.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ ERROR_LISTING - diagnostics: error0..error3 report an error code at a
  source line with 0 to 3 arguments, saved for the listing and printed.
  error_listing.pas (cc.m68k 0x0AC634..0x0AC9BA).  The code and the line
  are words by value (callers: `move.w line,-(SP); move.w #code,-(SP)',
  the line often the front end's current line); each argument is passed
  by address (`pea').

  Not known from the original: the parameter names and the arguments'
  type (anything: identifier nodes, constant nodes, strings). }

{ TODO(pascal) error_listing's arguments are univ_ptr by value

  The callers push an address for each argument; whether the original
  declared them `in ... univ' (by address) or as pointers is not
  decidable from the image.  save_errors's slots are the conservative
  reading. }

procedure save_errors(
    a: univ_ptr;
    b: univ_ptr;
    c: univ_ptr;
    d: univ_ptr;
    e: univ_ptr); options(val_param); extern;

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

{ PRINT_ERROR - print a saved error.  0x0AC8E0. }
procedure print_error(
    p: univ_ptr); options(val_param); extern;

var
  { error_listing.pas's data (A5 0x2C3168 cc.m68k, 0x4431D8 cc.a88k),
    +0xC: a boolean outbin's wr_instr sets and clears (st, clr.b) and
    c_error, c_lex_pp and iosub test (tst.b).  Its meaning is not
    known. }
  error_listing_0c: extern boolean;
