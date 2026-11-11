{ lang2/source/lt_utils/source/bug_check.ins.pas - BUG_CHECK, the
  compilers' internal-error stops: a message in ERROR_'s standard format,
  then a simulated fault.

  No Apollo copy survives; the headings are read off bug_check.pas
  (cc.m68k 0x0754C0..0x075618) and its callers (ass.pas, htm.pas,
  mrh.pas, ...).  Each routine takes a VFMT_ control string and up to
  ten arguments, every one passed by address and passed on as it is to
  ERROR_$STD_FORMAT (options(variable): callers pass only what the
  control string uses).  It is opened after /sys/ins/base.ins.pas or
  /us/ins/ubase.ins.pas (status_$t).

  Not known from the original: the type and parameter names.
}

type
  { A control string or an argument, as ERROR_$STD_FORMAT takes them
    (error_$string_t, error_$integer32).  The bound is not known: no
    routine indexes the string, and callers pass messages longer than
    error_$string_t's 80 characters. }
  bug_check_$string_t = array [1..256] of char;
  bug_check_$arg_t = integer32;

{ BUG_CHECK - the message, then a fault with status 16#7F000000.
  0x0754C0: the control string at (8,A6), a1..a10 at (12,A6)..(48,A6). }
procedure bug_check(
    in control_string: univ bug_check_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ bug_check_$arg_t); options(variable); extern;

{ OK_OR_BUG_CHECK - nothing when status is status_$ok; else the
  message, with status's text, and a fault with status 16#7F000000.
  0x075538: status at (8,A6) (`tst.l (A2)'), then as bug_check's. }
procedure ok_or_bug_check(
    in status: univ status_$t;
    in control_string: univ bug_check_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ bug_check_$arg_t); options(variable); extern;

{ UNIMPLEMENTED - bug_check's message, then a fault with status
  16#7F000001.  0x0755AA. }
procedure unimplemented(
    in control_string: univ bug_check_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ bug_check_$arg_t); options(variable); extern;
