{ lang/common/source/exs.ins.pas - EXS_, the exception scopes of the
  routines being compiled (cc.a88k only): which handlers a raise in a
  frame reaches, for the PRISM back end.  Opened first by exs.pas
  (before real_globals, mem, std, bvs, il, cargs, ass, diag and base),
  so it declares its own types; also by at_backend, lir, lir_main, post
  and sched, after backend.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k (exs.pas 0x068B88..0x06A2E6).  The headings were read off
  exs.pas's frames and the callers' pushes.

  Not known from the original: every parameter name. }

{ exs.pas (cc.a88k). }

{ EXS_$INITIALISE - 0x06932A, 0xD4 bytes; called from at_backend.  Frame
  8:b; 10:b. }
procedure exs_$initialise(
    p1: boolean;
    p2: boolean); options(val_param); extern;

{ EXS_$FINALISE - 0x069552, 0x80 bytes; called from at_backend. }
procedure exs_$finalise; extern;

{ EXS_$START_SUBPROGRAM - 0x0695F0, 0xAC bytes; called from at_backend.
  Frame 8:al. }
procedure exs_$start_subprogram(
    p1: univ_ptr); options(val_param); extern;

{ EXS_$END_CURRENT_SUBPROGRAM - 0x06972A, 0x62 bytes; called from
  at_backend. }
procedure exs_$end_current_subprogram; extern;

{ EXS_$START_EXCEPTION_HANDLER_ENQUIRY - 0x069A2A, 0x1EE bytes; called
  from lir.  Frame 8:al; 12:al; 16:bw; 18:b; 20:al; 24:al; 28:al; 32:a;
  36:al. }
procedure exs_$start_exception_handler_enquiry(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer;
    p4: boolean;
    p5: univ_ptr;
    p6: univ_ptr;
    p7: univ_ptr;
    p8: univ_ptr;
    p9: univ_ptr); options(val_param); extern;

{ EXS_$NEXT_EXCEPTION_HANDLER - 0x069C60, 0x52 bytes; called from lir.
  Result: A0 (callers: A02). }
function exs_$next_exception_handler: univ_ptr; extern;

{ EXS_$END_EXCEPTION_HANDLER_ENQUIRY - 0x069CB2, 0xD0 bytes; called from
  lir.  Frame 8:a. }
procedure exs_$end_exception_handler_enquiry(
    p1: univ_ptr); options(val_param); extern;

{ EXS_$MAP_TO_PREDEFINED_EXCEPTION - 0x069F3A, 0x54 bytes; called from
  lir.  Frame 8:a.  Result: A0 (callers: D0b1 D0w1). }
function exs_$map_to_predefined_exception(
    p1: univ_ptr): boolean; options(val_param); extern;

{ EXS_$EXCEPTION_RAISE_STRATEGY - 0x069FCC, 0x4C bytes; called from lir.
  Frame 8:l; 12:al; 16:a; 20:al; 24:al. }
procedure exs_$exception_raise_strategy(
    p1: integer32;
    p2: univ_ptr;
    p3: univ_ptr;
    p4: univ_ptr;
    p5: univ_ptr); options(val_param); extern;

{ EXS_$START_ALL_EXCEPTION_HANDLERS_OF_ROUTINE_ENQUIRY - 0x06A034, 0x36
  bytes; called from lir_main. }
procedure exs_$start_all_exception_handlers_of_routine_enquiry; extern;

{ EXS_$ROUTINES_NEXT_EXCEPTION_HANDLER - 0x06A0AC, 0x78 bytes; called from
  lir_main.  Result: A0 (callers: A01). }
function exs_$routines_next_exception_handler: univ_ptr; extern;

{ EXS_$SUBPROGRAM_MAY_PROPOGATE_EXCEPTIONS_BY_EXPLICIT_RAISE - 0x06A160,
  0x6A bytes; called from sched.  Frame 8:al.  Result: D0 (callers: D0b1).
  }
function exs_$subprogram_may_propogate_exceptions_by_explicit_raise(
    p1: univ_ptr): boolean; options(val_param); extern;

{ EXS_$FRAME_HAS_HANDLER_FOR_PREDEFINED_EXCEPTION - 0x06A22A, 0x40 bytes;
  called from post.  Frame 8:al; 12:w.  Result: D0 (callers: D0b2). }
function exs_$frame_has_handler_for_predefined_exception(
    p1: univ_ptr;
    p2: integer): boolean; options(val_param); extern;

{ EXS_$FRAME_IS_LEXICALLY_NESTED - 0x06A26A, 0x7C bytes; called from post.
  Frame 8:l; 12:a.  Result: D0 (callers: D0b1). }
function exs_$frame_is_lexically_nested(
    p1: integer32;
    p2: univ_ptr): boolean; options(val_param); extern;
