{ lang/lang/source/globals_from_frontend.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  Variables and foreign headings the compiler's units share (no unit
  of this name).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ What each front end supplies to the common code. }

{ CGERR_NO_SOURCE - report error code (with arg) with no source position.
  The C front end's is c_error.pas 0x0491EC (cc.m68k): code a word at
  (8,A6), arg a longword at (10,A6), passed on to cgerr with the current
  line.  Callers: gspace32 (codes 28, 9).

  Not known from the original: the parameter names; arg's meaning. }
procedure cgerr_no_source(
    code: integer;
    arg: integer32); options(val_param); extern;
