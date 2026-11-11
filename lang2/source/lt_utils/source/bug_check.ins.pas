{ lang2/source/lt_utils/source/bug_check.ins.pas - BUG_CHECK, reporting an
  internal compiler error (lang2/source/lt_utils/source/bug_check.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: the parameter names and types.
}

type
  bug_check_$string_t = array [1..256] of char;

{ BUG_CHECK - report the internal error described by the format string
  (VFMT_ directives, ending `%$') and its arguments.  bug_check.pas
  0x0754C0 (cc.m68k): a frame of 11 slots, the first three addresses,
  the rest longwords, all passed on; il_utils passes the format alone
  (`pea' of a string after the routine).  322 call sites. }
procedure bug_check(
    in format: univ bug_check_$string_t;
    in a1: univ bug_check_$string_t); options(variable); extern;
