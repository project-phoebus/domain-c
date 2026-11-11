{ lang/common/source/ass.ins.pas - ASS_, the compilers' assertions: the
  failed checks of the common units (precondition, postcondition,
  invariant, restriction, ...) stop the compilation through BUG_CHECK
  after the context call-backs have described where it was; warnings go
  out in ERROR_'s standard format and the compilation goes on.

  No Apollo copy survives; the headings are read off ass.pas (cc.m68k
  0x067420..0x0679B4) and its callers in cc.m68k and cc.a88k of DOMAIN C
  6.9.  It stands alone, naming no type of another insert: ass.pas opens
  it first (its .blocks file list), the other units after std.ins.pas or
  /sys/ins/base.ins.pas in no fixed order.  Each failure routine takes a
  VFMT_ control string and up to ten arguments, every one passed by
  address (options(variable)).

  Not known from the original: every type and parameter name here.
}

type
  { A control string or an argument, as ERROR_$STD_FORMAT takes them
    (the routines pass them on to BUG_CHECK).  The bound is not known:
    no routine indexes the string, and callers pass messages of more
    than 80 characters (token.pas 0x0738AC). }
  ass_$string_t = array [1..256] of char;
  ass_$arg_t = integer32;

  { A status_$t, as ASS_$OS_ERROR takes it (base.ins.pas is not open
    where this insert is). }
  ass_$status_t = integer32;

  { The text ASS_$DESCRIBE puts in the diagnostic prefix (DIAG_'s
    varying [200] of char). }
  ass_$description_t = varying [200] of char;

  { A context call-back: a procedure called, before a failure's message,
    with the address of the cell that holds the current call-back (so
    that it can pass it to ASS_$DISABLE_CONTEXT_CALL_BACK and let the
    previous one run next).  The parameter is univ: a procedure type
    cannot name itself. }
  ass_$context_call_back_t = ^procedure(
      in out current: univ univ_ptr);

{ ASS_$INITIALISE - the program's name (at most 80 characters) for the
  messages: no description, no call-back, and ERROR_$INIT_STD_FORMAT of
  errout, `?' and the name.  0x067460: name at (8,A6), len a longword at
  (12,A6). }
procedure ass_$initialise(
    in name: univ ass_$string_t;
    len: integer32); options(val_param); extern;

{ The failures: the context call-backs, then BUG_CHECK of the message
  (UNIMPLEMENTED for ASS_$NOT_IMPLEMENTED).  0x0674E4..0x067724: the
  control string at (8,A6), a1..a10 at (12,A6)..(48,A6). }
procedure ass_$external_data_error(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

procedure ass_$external_resource_error(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

procedure ass_$restriction(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

procedure ass_$precondition_fail(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

procedure ass_$postcondition_fail(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

procedure ass_$invariant_fail(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

procedure ass_$not_implemented(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

{ ASS_$OS_ERROR - a failed system call: status (which must not be
  status_$ok) and the message, through OK_OR_BUG_CHECK.  0x067784:
  status at (8,A6), then as the others. }
procedure ass_$os_error(
    in status: univ ass_$status_t;
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

{ ASS_$WARNING - the context call-backs, then the message in ERROR_'s
  standard format; the compilation goes on (a description is
  withdrawn).  0x06781C. }
procedure ass_$warning(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t); options(variable); extern;

{ ASS_$DESCRIBE - s as the diagnostic prefix, the prefix and column
  in force before the first description kept for ASS_$WARNING to give
  back.  0x0678C4. }
procedure ass_$describe(
    in s: univ ass_$description_t); extern;

{ ASS_$ENABLE_CONTEXT_CALL_BACK - call_back becomes the current
  context call-back (it must not be nil); previous is the one it
  replaces.  0x067924: call_back by value at (8,A6), previous by address
  at (12,A6). }
procedure ass_$enable_context_call_back(
    call_back: ass_$context_call_back_t;
    out previous: ass_$context_call_back_t); options(val_param); extern;

{ ASS_$DISABLE_CONTEXT_CALL_BACK - previous becomes the current context
  call-back again, and previous nil.  0x067996. }
procedure ass_$disable_context_call_back(
    in out previous: ass_$context_call_back_t); extern;
