{ bug_check - the compilers' internal-error stops: the message in
  ERROR_'s standard format (ERROR_$STD_FORMAT, with the stream, the
  initial character and the command name ASS_$INITIALISE set up), then
  PFM_$ERROR_TRAP, which simulates a fault and so ends the compilation
  through the fault handlers.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0754C0  0x076EA0  bug_check
    0x075538  0x076F18  ok_or_bug_check
    0x0755AA  0x076F8A  unimplemented
    A5 0x1695E8 (cc.m68k), 0x2E9658 (cc.a88k): the module's data; no
    routine here reads it.

  Every routine is global and loads A5.  The arguments are loaded into
  registers at entry, last first, and pushed again as they came
  (docs/rev889-patterns.md 6): each is passed by address and passed on
  so.  The status for ERROR_$STD_FORMAT and for PFM_$ERROR_TRAP are
  longword constants after the code (`pea (d,PC)').
}
module bug_check;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/error.ins.pas';
%include '/sys/ins/pfm.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

{ TODO(pascal) the trap statuses' names

  16#7F000000 (bug_check, ok_or_bug_check) and 16#7F000001
  (unimplemented): subsystem 16#7F, codes 0 and 1, no fail bit.  No
  customer insert names them; the names below are not known from the
  original, nor how the original wrote a status_$t constant (written
  here as a type transfer of an integer constant). }

const
  bug_check_status = 16#7F000000;
  unimplemented_status = 16#7F000001;

{ bug_check - the message, then a fault.

  0x0754C0, 0x6E bytes: ERROR_$STD_FORMAT (0x075510) with the longword 0
  at 0x075530 for the status, the control string and a1..a10; then
  PFM_$ERROR_TRAP (0x07551E) of the longword 16#7F000000 at 0x075534. }

procedure bug_check(
    in control_string: univ bug_check_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ bug_check_$arg_t);
begin
  error_$std_format(0, control_string, a1, a2, a3, a4, a5, a6, a7, a8,
                    a9, a10);
  pfm_$error_trap(status_$t(bug_check_status));
end;

{ ok_or_bug_check - nothing when status is status_$ok; else the message
  with status's text, then a fault.

  0x075538, 0x72 bytes: `tst.l (A2); beq' to the end (status.all = 0);
  ERROR_$STD_FORMAT (0x07558C) with status, the control string and
  a1..a10; PFM_$ERROR_TRAP (0x07559A) of the constant at 0x075534, not
  of status. }

procedure ok_or_bug_check(
    in status: univ status_$t;
    in control_string: univ bug_check_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ bug_check_$arg_t);
begin
  if status.all <> status_$ok then begin
    error_$std_format(status, control_string, a1, a2, a3, a4, a5, a6, a7,
                      a8, a9, a10);
    pfm_$error_trap(status_$t(bug_check_status));
  end;
end;

{ unimplemented - bug_check's message, then a fault with another status.

  0x0755AA, 0x6E bytes: as bug_check; PFM_$ERROR_TRAP (0x075608) of the
  longword 16#7F000001 at 0x075618. }

procedure unimplemented(
    in control_string: univ bug_check_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ bug_check_$arg_t);
begin
  error_$std_format(0, control_string, a1, a2, a3, a4, a5, a6, a7, a8,
                    a9, a10);
  pfm_$error_trap(status_$t(unimplemented_status));
end;
