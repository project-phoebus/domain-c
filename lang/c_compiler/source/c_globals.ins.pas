{ lang/c_compiler/source/c_globals.ins.pas - the C front end's shared
  variables and headings (opened after the common prelude,
  lang/lang/source/globals.ins.pas, and c_objtype.ins.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: the variables' names.
}

{ TODO(pascal) c_globals.ins.pas is incomplete

  The rest of the front end's interface is added as its units and their
  users are translated. }

var
  { c_error.pas's data, A5 0x1400AC (cc.m68k): a boolean c_main's cc
    sets (st 0x05B910); error0..error3 (error_listing) do not save an
    error for the listing while it is set; cgerr_no_source, errorlst,
    cgerr, error_text, warning_text and c_lex_pp's section_sem test it.
    Its meaning is not known. }
  c_error_0: extern boolean;

{ ERRORLST - report error code at line with nargs of the arguments args
  (c_error.pas 0x0495EC, cc.a88k 0x04986C): every parameter by address
  (error_listing's error0..error3 `pea' each; nargs a constant in their
  code). }
procedure errorlst(
    in code: integer;
    in line: integer;
    in args: univ error_listing_$args_t;
    in nargs: integer); extern;
