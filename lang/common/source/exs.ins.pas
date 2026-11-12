{ lang/common/source/exs.ins.pas - EXS_, the exception scopes of the
  routines being compiled (cc.a88k only): which handlers a raise in a
  frame reaches, for the PRISM back end.  Opened first by exs.pas
  (before real_globals, mem, std, bvs, il, cargs, ass, diag and base),
  so it declares nothing that needs another insert: the IL nodes it is
  passed (subprogram blocks, exception frames, exception sites, the
  exceptions' VAR_NAMEs) are univ_ptr here.  Also opened by at_backend,
  lir, lir_main, post and sched, after backend.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k (exs.pas 0x068B88..0x06A2E6); the headings checked against
  exs.pas's bodies (translator PA).  A handler enquiry: start (or
  exs_$exception_raise_strategy), the handlers one by one
  (exs_$next_exception_handler, nil at the end), end; the results come
  back by address.

  Not known from the original: every parameter name. }

{ EXS_$INITIALISE - the exception semantics of the compilation: whether
  the language has exceptions and whether a routine can propagate one
  (the second needs the first); the pool of exception bit vectors
  opened.  0x06932A, 0xD4 bytes; called from at_backend. }
procedure exs_$initialise(
    has_exceptions: boolean;
    propagates: boolean); options(val_param); extern;

{ EXS_$FINALISE - 0x069552, 0x80 bytes; called from at_backend. }
procedure exs_$finalise; extern;

{ EXS_$START_SUBPROGRAM - b (a subprogram block: kind 105, 107 or 108)
  the current subprogram.  0x0695F0, 0xAC bytes; called from
  at_backend. }
procedure exs_$start_subprogram(
    b: univ_ptr); options(val_param); extern;

{ EXS_$END_CURRENT_SUBPROGRAM - its exceptions recorded at the block's
  +36.  0x06972A, 0x62 bytes; called from at_backend. }
procedure exs_$end_current_subprogram; extern;

{ EXS_$START_EXCEPTION_HANDLER_ENQUIRY - the handlers an exception
  raised at site (an IL node) in frame reaches; exc the exception when
  only one can be, handler the first handler's +48 (or, with
  use_strategy and a single handler that takes everything, the handler
  itself with handled set and no enquiry left open), site_flag and
  site_word from the site.  0x069A2A, 0x1EE bytes; called from lir. }
procedure exs_$start_exception_handler_enquiry(
    frame: univ_ptr;
    site: univ_ptr;
    check_storage: boolean;
    use_strategy: boolean;
    var handled: boolean;
    var exc: univ_ptr;
    var handler: univ_ptr;
    var site_flag: boolean;
    var site_word: integer); options(val_param); extern;

{ EXS_$NEXT_EXCEPTION_HANDLER - the enquiry's next handler, nil after
  the last.  0x069C60, 0x52 bytes; called from lir. }
function exs_$next_exception_handler: univ_ptr; extern;

{ EXS_$END_EXCEPTION_HANDLER_ENQUIRY - propagated: whether an exception
  can leave the routine from the site (then added to the subprogram's).
  0x069CB2, 0xD0 bytes; called from lir. }
procedure exs_$end_exception_handler_enquiry(
    var propagated: boolean); extern;

{ EXS_$MAP_TO_PREDEFINED_EXCEPTION - which of the seven predefined
  exceptions (il_f0) e (a VAR_NAME) is; 7 for none.  0x069F3A, 0x54
  bytes; called from lir. }
function exs_$map_to_predefined_exception(
    e: univ_ptr): integer; options(val_param); extern;

{ EXS_$EXCEPTION_RAISE_STRATEGY - an enquiry at site in frame that
  ends at once unless handled: handled, exc and handler as
  exs_$start_exception_handler_enquiry's.  0x069FCC, 0x4C bytes;
  called from lir. }
procedure exs_$exception_raise_strategy(
    frame: univ_ptr;
    site: univ_ptr;
    var handled: boolean;
    var exc: univ_ptr;
    var handler: univ_ptr); options(val_param); extern;

{ EXS_$START_ALL_EXCEPTION_HANDLERS_OF_ROUTINE_ENQUIRY - 0x06A034, 0x36
  bytes; called from lir_main. }
procedure exs_$start_all_exception_handlers_of_routine_enquiry; extern;

{ EXS_$ROUTINES_NEXT_EXCEPTION_HANDLER - every handler of the current
  subprogram's frames, nil after the last.  0x06A0AC, 0x78 bytes; called
  from lir_main. }
function exs_$routines_next_exception_handler: univ_ptr; extern;

{ EXS_$SUBPROGRAM_MAY_PROPOGATE_EXCEPTIONS_BY_EXPLICIT_RAISE - 0x06A160,
  0x6A bytes; called from sched. }
function exs_$subprogram_may_propogate_exceptions_by_explicit_raise(
    b: univ_ptr): boolean; options(val_param); extern;

{ EXS_$FRAME_HAS_HANDLER_FOR_PREDEFINED_EXCEPTION - whether frame (nil:
  false) handles predefined exception k (its +40, a set of 0..15).
  0x06A22A, 0x40 bytes; called from post. }
function exs_$frame_has_handler_for_predefined_exception(
    frame: univ_ptr;
    k: integer): boolean; options(val_param); extern;

{ EXS_$FRAME_IS_LEXICALLY_NESTED - whether inner is within outer
  (deeper, outer among its enclosing frames; true for outer nil, false
  for inner nil).  0x06A26A, 0x7C bytes;
  called from post. }
function exs_$frame_is_lexically_nested(
    outer: univ_ptr;
    inner: univ_ptr): boolean; options(val_param); extern;
