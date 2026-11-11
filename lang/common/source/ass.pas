{ ass - ASS_, the compilers' assertions.  A failed check calls the
  context call-backs (each describes where the compilation was, in the
  diagnostic output) and stops through BUG_CHECK; a warning goes out in
  ERROR_'s standard format and the compilation goes on.  ASS_$DESCRIBE
  puts a text in the diagnostic prefix until the next warning.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x067420  0x0676A0  show_context (internal)
    0x067460  0x0676E0  ass_$initialise
    0x0674E4  0x067764  ass_$external_data_error
    0x067544  0x0677C4  ass_$external_resource_error
    0x0675A4  0x067824  ass_$restriction
    0x067604  0x067884  ass_$precondition_fail
    0x067664  0x0678E4  ass_$postcondition_fail
    0x0676C4  0x067944  ass_$invariant_fail
    0x067724  0x0679A4  ass_$not_implemented
    0x067784  0x067A04  ass_$os_error
    0x06781C  0x067A9C  ass_$warning
    0x0678C4  0x067B44  ass_$describe
    0x067924  0x067BA4  ass_$enable_context_call_back
    0x067996  0x067C16  ass_$disable_context_call_back
    A5 0x14AECC (cc.m68k), 0x2CAECC (cc.a88k): the module's data, 0x134
    bytes to bvs's.

  Module data as the image uses it: +0 a byte, true while a description
  is in force; +2 the prefix in force before it (DIAG_'s varying [200] of
  char); +208 the column then (a longword); +216 the program's name (a
  varying [80] of char: the length word, the characters from +218); +304
  the current context call-back.

  The global routines load A5; show_context, which does not (it uses
  its callers' A5), is internal.  The failure routines load their eleven
  arguments into registers at entry and push them again as they came
  (docs/rev889-patterns.md 6).
}
module ass;

%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/diag.ins.pas';
%include '/sys/ins/base.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include '/sys/ins/error.ins.pas';

{ TODO(pascal) the bytes at +212..+215 and +298..+303

  No routine reads them: a variable no routine uses, or the bound of
  the name (80 from the loop in ass_$initialise), is not known. }

var
  described: boolean;                   { +0 }
  prefix_before: diag_$vstring_t;       { +2 }
  column_before: integer32;             { +208 }
  program_name: varying [80] of char;   { +216 }
  current_call_back: ass_$context_call_back_t;  { +304 }

{ show_context - run the context call-backs, each on a fresh line with
  no prefix; each call-back is given the cell that holds it.

  0x067420, 0x40 bytes, internal (no A5 load, `bsr' from the failure
  routines):
    bra to the test                while current_call_back <> nil do
    jsr diag_$assure_fresh_line      begin
    clr.w -(SP); jsr diag_$drop_prefix
    pea (304,A5); movea.l (304,A5),A0; jsr (A0)
    tst.l (304,A5); bne              end;
    jsr diag_$assure_fresh_line;   then the same two calls.
    clr.w -(SP); jsr diag_$drop_prefix

  Not known from the original:
  - how a call-back leaves the loop (by ASS_$DISABLE_CONTEXT_CALL_BACK
    of the cell it is given, by the look of that routine). }

procedure show_context; internal;
begin
  while current_call_back <> nil do begin
    diag_$assure_fresh_line;
    diag_$drop_prefix(0);
    current_call_back^(current_call_back);
  end;
  diag_$assure_fresh_line;
  diag_$drop_prefix(0);
end;

{ ass_$initialise - the program's name for the messages.

  0x067460, 0x80 bytes: len in D2, name in A2.  program_name.length
  (+216) := 0; while program_name.length < 80 (`cmpi.w #80; bcc' out:
  the second test only when the first holds, `and then') and
  program_name.length < len (zero-extended, `cmp.l D2,D0; bcs': an
  unsigned compare), the length grows by one and the character is
  copied from name[length] (`move.b (-1,A2,D1.l)').  Then described :=
  false, current_call_back := nil, and ERROR_$INIT_STD_FORMAT (0x0674CA)
  of the word 2 (0x0674E2, stream_$errout), the byte `?' (0x0674E0),
  name and len as a word (stored back to (12,A6), `pea (14,A6)').

  Not known from the original:
  - why the second compare is unsigned (dpc's is signed, `blt'; they
    differ only for a negative len); len's type may be a non-negative
    subrange. }

procedure ass_$initialise(
    in name: univ ass_$string_t;
    len: integer32);
var
  name_length: integer;
begin
  program_name.length := 0;
  while (program_name.length < 80) and then (program_name.length < len) do begin
    program_name.length := program_name.length + 1;
    program_name.body[program_name.length] := name[program_name.length];
  end;
  described := false;
  current_call_back := nil;
  name_length := len;
  error_$init_std_format(stream_$errout, '?', name, name_length);
end;

{ The failure routines.  Each: show_context (`bsr'), then BUG_CHECK
  (UNIMPLEMENTED for ass_$not_implemented) of the control string and
  a1..a10.

  0x0674E4 (ass_$external_data_error), 0x067544, 0x0675A4, 0x067604,
  0x067664, 0x0676C4, 0x067724 (ass_$not_implemented): 0x60 bytes each,
  `movem.l D2-D7/A2-A5', the arguments loaded at entry, `bsr
  show_context', the eleven pushed, `jsr bug_check' (unimplemented). }

procedure ass_$external_data_error(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
begin
  show_context;
  bug_check(control_string, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
end;

procedure ass_$external_resource_error(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
begin
  show_context;
  bug_check(control_string, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
end;

procedure ass_$restriction(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
begin
  show_context;
  bug_check(control_string, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
end;

procedure ass_$precondition_fail(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
begin
  show_context;
  bug_check(control_string, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
end;

procedure ass_$postcondition_fail(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
begin
  show_context;
  bug_check(control_string, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
end;

procedure ass_$invariant_fail(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
begin
  show_context;
  bug_check(control_string, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
end;

procedure ass_$not_implemented(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
begin
  show_context;
  unimplemented(control_string, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
end;

{ ass_$os_error - a failed system call.

  0x067784, 0x72 bytes: the twelve arguments loaded at entry; `tst.l
  (A2); bne' (status): ass_$precondition_fail (`bsr', 0x0677BE) of
  'ASS_$OS_ERROR -- status = status_$ok%$' (0x0677F6); show_context;
  OK_OR_BUG_CHECK (0x0677E6) of the twelve. }

procedure ass_$os_error(
    in status: univ ass_$status_t;
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
begin
  if status = 0 then
    ass_$precondition_fail('ASS_$OS_ERROR -- status = status_$ok%$');
  show_context;
  ok_or_bug_check(status, control_string, a1, a2, a3, a4, a5, a6, a7, a8,
                  a9, a10);
end;

{ ass_$warning - the message, and the compilation goes on.

  0x06781C, 0xA2 bytes: show_context; ERROR_$STD_FORMAT (0x067870) of
  the longword 0 at 0x0678C0, the control string and a1..a10.  When
  described (`tst.b (A5); bpl' to the end): DIAG_$DROP_PREFIX(0),
  DIAG_$SET_PREFIX(prefix_before (+2), (-2,A6)),
  DIAG_$ASSURE_FRESH_LINE, DIAG_$TAB_TO(column_before) unless it is 0,
  described := false. }

procedure ass_$warning(
    in control_string: univ ass_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ ass_$arg_t);
var
  old_length: integer;                  { (-2,A6) }
begin
  show_context;
  error_$std_format(0, control_string, a1, a2, a3, a4, a5, a6, a7, a8,
                    a9, a10);
  if described then begin
    diag_$drop_prefix(0);
    diag_$set_prefix(prefix_before, old_length);
    diag_$assure_fresh_line;
    if column_before <> 0 then
      diag_$tab_to(column_before);
    described := false;
  end;
end;

{ ass_$describe - s as the diagnostic prefix.

  0x0678C4, 0x60 bytes: DIAG_$ASSURE_FRESH_LINE; when not described
  (`tst.b (A5); bmi'): described := true (`move.b #-1'), column_before
  := DIAG_$CURRENT_COLUMN, DIAG_$DROP_AND_YIELD_PREFIX(0,
  prefix_before); else DIAG_$DROP_PREFIX(0).  Then DIAG_$SET_PREFIX(s,
  (-2,A6)). }

procedure ass_$describe(
    in s: univ ass_$description_t);
var
  old_length: integer;                  { (-2,A6) }
begin
  diag_$assure_fresh_line;
  if not described then begin
    described := true;
    column_before := diag_$current_column;
    diag_$drop_and_yield_prefix(0, prefix_before);
  end
  else
    diag_$drop_prefix(0);
  diag_$set_prefix(s, old_length);
end;

{ ass_$enable_context_call_back - call_back becomes the current one.

  0x067924, 0x38 bytes: `cmpa.w #0,A2; bne' (call_back by value):
  ass_$precondition_fail (`bsr') of 'ASS_$ENABLE_CONTEXT_CALL_BACK -- NIL
  call_back provided%$' (0x06795C); previous := current_call_back;
  current_call_back := call_back. }

procedure ass_$enable_context_call_back(
    call_back: ass_$context_call_back_t;
    out previous: ass_$context_call_back_t);
begin
  if call_back = nil then
    ass_$precondition_fail(
      'ASS_$ENABLE_CONTEXT_CALL_BACK -- NIL call_back provided%$');
  previous := current_call_back;
  current_call_back := call_back;
end;

{ ass_$disable_context_call_back - previous becomes the current one
  again.

  0x067996, 0x1E bytes: `move.l (A0),(304,A5); clr.l (A0)'. }

procedure ass_$disable_context_call_back(
    in out previous: ass_$context_call_back_t);
begin
  current_call_back := previous;
  previous := nil;
end;
