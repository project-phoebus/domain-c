{ exs - EXS_, the exception scopes of the routines being compiled
  (cc.a88k only): for an exception site (a raise, a check, an operator
  or call that can fault) in an exception frame, the exceptions it can
  raise (a BVS_ vector of exception numbers, a VAR_NAME's +74) and the
  handlers of the frame and the frames around it that take them, one
  by one; what escapes is added to the subprogram's record (the
  block's +36: the vector and whether it raises explicitly).  The last
  enquiry is cached: one asked again for the same site gets the same
  answer without the walk.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x068B88  check_frame (internal)
    --------  0x068C58  exception_name_index
    --------  0x068D2C  set_predefined_exception (internal)
    --------  0x068D80  reset_bit_vector (in exception_info)
    --------  0x068DB8  copy_bit_vector (in exception_info)
    --------  0x068DF4  set_bit (in exception_info)
    --------  0x068E22  set_predefined (in exception_info)
    --------  0x068E4E  set_access_fault (in exception_info)
    --------  0x068E7C  exception_info (internal)
    --------  0x06932A  exs_$initialise
    --------  0x069552  exs_$finalise
    --------  0x0695F0  exs_$start_subprogram
    --------  0x06972A  exs_$end_current_subprogram
    --------  0x0697BE  init_exception_handler_enquiry (internal)
    --------  0x0698C4  find_next_exception_handler (internal)
    --------  0x069A2A  exs_$start_exception_handler_enquiry
    --------  0x069C60  exs_$next_exception_handler
    --------  0x069CB2  exs_$end_exception_handler_enquiry
    --------  0x069EDE  exs_$cancel_exception_handler_enquiry (internal)
    --------  0x069F3A  exs_$map_to_predefined_exception
    --------  0x069FCC  exs_$exception_raise_strategy
    --------  0x06A018  set_frame (internal)
    --------  0x06A034  exs_$start_all_exception_handlers_of_routine_enquiry
    --------  0x06A0AC  exs_$routines_next_exception_handler
    --------  0x06A160  exs_$subprogram_may_propogate_exceptions_by_explicit_raise
    --------  0x06A22A  exs_$frame_has_handler_for_predefined_exception
    --------  0x06A26A  exs_$frame_is_lexically_nested
    A5 0x2CB2F4 (ecb's, which has none): the module's data, 110 bytes
    (the cache +0..+0x33, the walks +0x34..+0x4B, the vectors, the
    subprogram, the pool, the flags to +0x6C).

  The predefined exceptions are il.pas's il_f0 (0..6; 0x2E9DD0 the
  first): 0 for the checks of kind 140's 35 and 36 and the operators
  48, 80, 81, 1 for the arithmetic faults, 2 for an access fault (and
  for a site in a subprogram whose +378 bit 0 is set, when asked).

  Not known from the original: every local and parameter name; the
  module variables' names; the IL nodes' views (exs_node_t ...) and
  their fields' names. }
module exs;

%include 'lang/common/source/exs.ins.pas';
%include 'lang/lang/source/real_globals.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/bvs.ins.pas';
%include 'lang/lang/source/il.ins.pas';
%include 'lang/lang/source/cargs.ins.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/diag.ins.pas';
%include '/sys/ins/base.ins.pas';

type
  { The IL nodes as exs reads them: the kind at +2 of each. }
  exs_node_ptr_t = ^exs_node_t;
  exs_node_t = record
    w0: integer;                        { +0 }
    kind: integer;                      { +2 }
    p4: univ_ptr;                       { +4: kind 190's operand }
    unused_8: array [8..19] of char;    { +8 }
    p20: univ_ptr;                      { +20: kind 189's operand }
  end;
  { VAR_NAME (109): an exception's number. }
  exs_var_ptr_t = ^exs_var_t;
  exs_var_t = record
    unused_0: array [0..73] of char;    { +0 }
    num: 0..65535;                      { +74 }
  end;
  { ADDR_CON (163): the name it is the address of. }
  exs_addr_con_ptr_t = ^exs_addr_con_t;
  exs_addr_con_t = record
    unused_0: array [0..7] of char;     { +0 }
    name: univ_ptr;                     { +8 }
  end;
  { A raise (224): the exception (+52, nil to raise again). }
  exs_raise_ptr_t = ^exs_raise_t;
  exs_raise_t = record
    unused_0: array [0..51] of char;    { +0 }
    exc: univ_ptr;                      { +52 }
    site_word: integer;                 { +56 }
    site_flag: boolean;                 { +58 }
  end;
  { A check (140): the check's kind at +76 (1..36). }
  exs_check_ptr_t = ^exs_check_t;
  exs_check_t = record
    unused_0: array [0..53] of char;    { +0 }
    site_word: integer;                 { +54 }
    unused_56: char;                    { +56 }
    site_flag: boolean;                 { +57 }
    unused_58: array [58..75] of char;  { +58 }
    check: integer;                     { +76 }
  end;
  { A tree node (137, 138, 143): the operator (+36, 0..87) and its
    operand (+40: a call's routine). }
  exs_tree_ptr_t = ^exs_tree_t;
  exs_tree_t = record
    unused_0: array [0..25] of char;    { +0 }
    site_word: integer;                 { +26 }
    unused_28: char;                    { +28 }
    site_flag: boolean;                 { +29 }
    unused_30: array [30..35] of char;  { +30 }
    op: integer;                        { +36 }
    unused_38: integer;                 { +38 }
    opnd: univ_ptr;                     { +40 }
  end;
  { A subprogram's exceptions (6 bytes from the pool, at its +36). }
  exs_info_ptr_t = ^exs_info_t;
  exs_info_t = record
    raised: bvs_$t;                     { +0 }
    explicit: boolean;                  { +4 }
  end;
  { A subprogram block (105, 107, 108): its frames (+32), its
    exceptions (+36), +378 bit 0 (a storage error possible anywhere). }
  exs_block_ptr_t = ^exs_block_t;
  exs_block_t = record
    w0: integer;                        { +0 }
    kind: integer;                      { +2 }
    unused_4: array [4..31] of char;    { +4 }
    frames: univ_ptr;                   { +32 }
    info: exs_info_ptr_t;               { +36 }
    unused_40: array [40..377] of char; { +40 }
    f378: packed record                 { +378 }
      b7, b6, b5, b4, b3, b2, b1: boolean;
      storage: boolean;                 { .0 }
      end;
  end;
  { An exception frame (222): the next of the subprogram's (+4), its
    subprogram (+12), the frame around it (+16) and its depth (+20),
    its handlers (+28), a handler for every exception (+32), the
    predefined exceptions it handles (+40). }
  exs_frame_ptr_t = ^exs_frame_t;
  exs_frame_t = record
    w0: integer;                        { +0 }
    kind: integer;                      { +2 }
    next: exs_frame_ptr_t;              { +4 }
    unused_8: integer32;                { +8 }
    subprogram: univ_ptr;               { +12 }
    parent: exs_frame_ptr_t;            { +16 }
    depth: linteger;                    { +20 }
    unused_24: integer32;               { +24 }
    handlers: univ_ptr;                 { +28 }
    others: univ_ptr;                   { +32 }
    unused_36: integer32;               { +36 }
    predefined: set of 0..15;           { +40 }
  end;
  { A handler: the exceptions it names (+70 of them from +76), the next
    of the frame's (+72); +48 what an enquiry returns for it. }
  exs_handler_ptr_t = ^exs_handler_t;
  exs_handler_t = record
    unused_0: array [0..47] of char;    { +0 }
    l48: univ_ptr;                      { +48 }
    unused_52: array [52..69] of char;  { +52 }
    nnames: 0..65535;                   { +70 }
    next: exs_handler_ptr_t;            { +72 }
    names: array [1..1000] of univ_ptr; { +76 }
  end;

var
  cache_raised: bvs_$t;                 { +0: the cached enquiry's }
  cache_valid: boolean;                 { +4 (stored as a longword of
                                          -1 or 0) }
  cache_subprogram: univ_ptr;           { +8 }
  cache_frame: univ_ptr;                { +12 }
  cache_site: univ_ptr;                 { +16 }
  cache_check_storage: boolean;         { +20 (a longword: ext.l) }
  cache_exc: univ_ptr;                  { +24 }
  cache_site_flag: boolean;             { +28 }
  cache_all_handled: boolean;           { +29 }
  cache_explicit: boolean;              { +30 }
  cache_site_word: integer;             { +32 }
  cache_walk_frame: exs_frame_ptr_t;    { +36 }
  cache_walk_handler: exs_handler_ptr_t;  { +40 }
  cache_first: univ_ptr;                { +44 }
  cache_second: univ_ptr;               { +48 }
  routine_handler: exs_handler_ptr_t;   { +52: the routine enquiry's }
  routine_frame: exs_frame_ptr_t;       { +56 }
  second_handler: univ_ptr;             { +60: the enquiry's first two }
  first_handler: univ_ptr;              { +64 }
  walk_handler: exs_handler_ptr_t;      { +68: the walk's next handler }
  walk_frame: exs_frame_ptr_t;          { +72: and its frame }
  raised: bvs_$t;                       { +76: what the site can raise,
                                          not yet handled }
  sub_raised: bvs_$t;                   { +80: what leaves the current
                                          subprogram }
  subprogram: exs_block_ptr_t;          { +84: the current subprogram }
  pool: mem_$pool_t;                    { +88 }
  next_state: integer;                  { +92: exs_$next_exception_handler:
                                          0 the first, 1 the second, 2
                                          the walk }
  routine_enquiry: boolean;             { +94 }
  enquiry: boolean;                     { +96: an enquiry is open }
  explicit: boolean;                    { +98: the site raises
                                          explicitly }
  all_handled: boolean;                 { +100: nothing escapes }
  sub_explicit: boolean;                { +102 }
  propagation_on: boolean;              { +104: routines propagate
                                          exceptions }
  exceptions_on: boolean;               { +106: the language has
                                          exceptions }
  active: boolean;                      { +108: initialised }

{ check_frame - nothing for nil; else ass_$precondition_fail unless f is
  an exception frame (kind 222) of the current subprogram (its +12).

  0x068B88, 0x40 bytes, internal (no A5: the caller's): `cmpi.w
  #222,(2,A2)', `cmpa.l (12,A2),A0' with A0 the subprogram (84,A5). }

procedure check_frame(
    f: exs_frame_ptr_t); options(val_param); internal;
begin
  if f <> nil then begin
    if f^.kind <> 222 then
      ass_$precondition_fail(
        'EXS_$CHECK_FRAME -- not an exception frame of current subprogram%$');
    if f^.subprogram <> subprogram then
      ass_$precondition_fail(
        'EXS_$CHECK_FRAME -- exception frame does not belong to current subprogram%$');
  end;
end;

{ exception_name_index - the number of the exception e names: a
  VAR_NAME's +74, an ADDR_CON's name's (recursively).

  0x068C58, 0x5A bytes: e by address (`tst.l (A2)'); `cmpi.w #109',
  `cmpi.w #163'; the result a word, not set after the failure for
  another kind. }

function exception_name_index(
    var e: univ_ptr): integer;
begin
  if e = nil then
    ass_$precondition_fail('EXS_$EXCEPTION_NAME_INDEX -- NIL exception name%$');
  case exs_node_ptr_t(e)^.kind of
    109:
      exception_name_index := exs_var_ptr_t(e)^.num;
    163:
      exception_name_index :=
        exception_name_index(exs_addr_con_ptr_t(e)^.name);
    otherwise
      ass_$precondition_fail(
        'EXS_$EXCEPTION_NAME_INDEX -- exception name not a VAR_NAME or ADDR_CON%$');
  end;
end;

{ set_predefined_exception - predefined exception k's bit set in v
  (bit 0 when il_f0[k] is nil); nothing for nil.

  0x068D2C, 0x54 bytes, internal: il_f0 at `movea.l #0x2E9DA0' +0x30
  (`tst.l (0x30,A0,D3.w)', D3 4k), passed by address to
  exception_name_index. }

procedure set_predefined_exception(
    v: bvs_$t;
    k: integer); options(val_param); internal;
begin
  if v <> nil then
    if il_f0[k] <> nil then
      bvs_$set(v, exception_name_index(il_f0[k]))
    else
      bvs_$set(v, 0);
end;

{ exception_info - what site can raise: its exceptions in v (when v is
  not nil), nothing_raised when there are none, exc the exception when
  it is one known (nil else), explicit for a raise or a call of a
  routine that raises explicitly, site_flag and site_word the site's.
  By kind: a raise (224) its exception (all of them to raise again); an
  access (228, 149, 148, 225, and 205, 147, 146, 145) an access fault;
  a check (140) by its kind; a tree node (143, 138, 137) by its
  operator (a call: what the routine propagates, all when not known;
  0 and 17: their operand's); 190 and 189 their operand's; anything
  else an access fault.  With check_storage and a subprogram whose
  +378 bit 0 is set, storage error too.  Without exceptions in the
  language, nothing.

  0x068E7C, 0x450 bytes, internal: site (8, A2), check_storage (12,
  D2), exc (14), site_flag (18, D4), site_word (22, D3), v (26),
  nothing_raised (30), explicit (34, A3); the outputs cleared first
  (exc `move.l #0', nothing_raised `move.b #-1'); the kinds a compare
  chain, the check's kind a jump table of 36 from 1 (0x068FCE), the
  operator one of 88 (0x06908E); the operands' by a recursive call
  that returns at once (the storage check is not repeated). }

procedure exception_info(
    site: exs_node_ptr_t;
    check_storage: boolean;
    var exc: univ_ptr;
    var site_flag: boolean;
    var site_word: integer;
    v: bvs_$t;
    var nothing_raised: boolean;
    var explicit: boolean); options(val_param); internal;
var
  callee: exs_block_ptr_t;

{ reset_bit_vector - every bit of v value (nothing_raised the
  opposite).  0x068D80, 0x38 bytes: value (8), the parent's frame in A1
  (A2); v at its +26, nothing_raised at +30. }

  procedure reset_bit_vector(
      value: boolean); options(val_param);
  begin
    nothing_raised := not value;
    if v <> nil then
      bvs_$reset_bit_vector(v, value);
  end;

{ copy_bit_vector - v := src (when v is not nil); nothing_raised when
  src has no bit set.  0x068DB8, 0x3C bytes: the parent's frame from
  the dynamic link; bvs_$copy_and_test, else bvs_$test_bit_vector(src,
  false), `not.b'. }

  procedure copy_bit_vector(
      src: bvs_$t); options(val_param);
  begin
    if v <> nil then
      nothing_raised := not bvs_$copy_and_test(src, v)
    else
      nothing_raised := not bvs_$test_bit_vector(src, false);
  end;

{ set_bit - bit set in v; nothing_raised false.  0x068DF4, 0x2E bytes
  (`move.b #0'). }

  procedure set_bit(
      bit: integer); options(val_param);
  begin
    nothing_raised := false;
    if v <> nil then
      bvs_$set(v, bit);
  end;

{ set_predefined - predefined exception k's bit set in v;
  nothing_raised false.  0x068E22, 0x2C bytes: the parent's frame in
  A1. }

  procedure set_predefined(
      k: integer); options(val_param);
  begin
    nothing_raised := false;
    if v <> nil then
      set_predefined_exception(v, k);
  end;

{ set_access_fault - v only predefined exception 2, exc il_f0[2].
  0x068E4E, 0x2E bytes: reset_bit_vector(false), set_predefined(2), exc
  := 0x2E9DD8. }

  procedure set_access_fault;
  begin
    reset_bit_vector(false);
    set_predefined(2);
    exc := il_f0[2];
  end;

begin
  if subprogram = nil then
    ass_$precondition_fail('EXS_$EXCEPTION_INFO -- no current subprogram set%$');
  if site = nil then
    ass_$precondition_fail('EXS_$EXCEPTION_INFO -- exception site NIL%$');
  exc := nil;
  site_flag := false;
  site_word := 0;
  nothing_raised := true;
  explicit := false;
  if not exceptions_on then begin
    reset_bit_vector(false);
    return;
  end;
  case site^.kind of
    224: begin
      site_flag := exs_raise_ptr_t(site)^.site_flag;
      site_word := exs_raise_ptr_t(site)^.site_word;
      explicit := true;
      if exs_raise_ptr_t(site)^.exc <> nil then begin
        exc := exs_raise_ptr_t(site)^.exc;
        reset_bit_vector(false);
        set_bit(exception_name_index(exs_raise_ptr_t(site)^.exc));
      end
      else
        reset_bit_vector(true);
    end;
    228, 149, 148, 225:
      set_access_fault;
    140:
      case exs_check_ptr_t(site)^.check of
        1, 2, 14, 19, 20, 21, 22, 23, 24, 26: begin
          reset_bit_vector(false);
          set_predefined(1);
          exc := il_f0[1];
        end;
        31, 32, 33, 34:
          set_access_fault;
        35, 36: begin
          site_flag := exs_check_ptr_t(site)^.site_flag;
          site_word := exs_check_ptr_t(site)^.site_word;
          reset_bit_vector(false);
          set_predefined(0);
          exc := il_f0[0];
        end;
        otherwise
          set_access_fault;
      end;
    143, 138, 137:
      case exs_tree_ptr_t(site)^.op of
        48, 80, 81: begin
          site_flag := exs_tree_ptr_t(site)^.site_flag;
          site_word := exs_tree_ptr_t(site)^.site_word;
          reset_bit_vector(false);
          set_predefined(0);
          exc := il_f0[0];
        end;
        15, 16, 30, 31, 32:
          if not propagation_on then
            reset_bit_vector(false)
          else begin
            callee := exs_tree_ptr_t(site)^.opnd;
            if ((callee^.kind = 105) or (callee^.kind = 108)
                or (callee^.kind = 107))
               and (callee^.info <> nil) then begin
              explicit := callee^.info^.explicit;
              copy_bit_vector(callee^.info^.raised);
            end
            else begin
              explicit := true;
              reset_bit_vector(true);
            end;
          end;
        1, 2, 3, 4, 6, 7, 18, 27, 28, 29, 33, 34, 35, 36, 37, 38, 39,
        40, 41, 42, 43, 49, 50, 59, 60, 61, 62, 74, 75, 76, 77, 86,
        87: begin
          reset_bit_vector(false);
          set_predefined(1);
          exc := il_f0[1];
        end;
        82:
          reset_bit_vector(false);
        65: begin
          reset_bit_vector(false);
          set_predefined(2);
          exc := il_f0[2];
        end;
        12, 78, 79, 84:
          set_access_fault;
        0, 17: begin
          exception_info(exs_tree_ptr_t(site)^.opnd, check_storage, exc,
                         site_flag, site_word, v, nothing_raised,
                         explicit);
          return;
        end;
        otherwise
          set_access_fault;
      end;
    205, 147, 146, 145:
      set_access_fault;
    190: begin
      exception_info(site^.p4, check_storage, exc, site_flag, site_word,
                     v, nothing_raised, explicit);
      return;
    end;
    189: begin
      exception_info(site^.p20, check_storage, exc, site_flag, site_word,
                     v, nothing_raised, explicit);
      return;
    end;
    otherwise
      set_access_fault;
  end;
  if check_storage then
    if subprogram^.f378.storage then begin
      if nothing_raised then
        exc := il_f0[2]
      else if exc <> il_f0[2] then
        exc := nil;
      set_predefined_exception(v, 2);
    end;
end;

{ exs_$initialise - the exception semantics (a language without
  exceptions cannot propagate them; with frames the predefined
  exceptions and the exception processor must be defined: il_13c
  set needs il_f0[2], [1], il_138 and il_f0[0]), the pool opened, the
  state cleared.

  0x06932A, 0xD4 bytes: has_exceptions (8, D3), propagates (10, D2):
  `not.b; and.b; bpl'; active `move.b #-1'; mem_$open_pool(pool, 'exs_$
  exception bit vectors%', false); the cells cleared (`move.l #0',
  `move.b #0'), cache_valid's longword too. }

procedure exs_$initialise(
    has_exceptions: boolean;
    propagates: boolean);
begin
  if (not has_exceptions) and propagates then
    ass_$precondition_fail(
      'EXS_$INITIALISE -- inconsistent exception semantics: if a language does not support exceptions, then it cannot propogate exceptions%$');
  active := true;
  exceptions_on := has_exceptions;
  propagation_on := propagates;
  if il_13c <> 0 then
    if (il_f0[2] = nil) or (il_f0[1] = nil) or (il_138 = 0)
       or (il_f0[0] = nil) then
      ass_$precondition_fail(
        'EXS_$INITIALISE -- compilation unit has exception frames but has not defined the exception_processor or predefined constraint_error, numeric_error and storage_error exceptions%$');
  mem_$open_pool(pool, 'exs_$ exception bit vectors%', false);
  subprogram := nil;
  sub_raised := nil;
  sub_explicit := false;
  raised := nil;
  all_handled := false;
  explicit := false;
  enquiry := false;
  cache_raised := nil;
  cache_valid := false;
  routine_enquiry := false;
end;

{ exs_$finalise - the state cleared and the pool emptied.

  0x069552, 0x80 bytes: ass_$precondition_fail unless active. }

procedure exs_$finalise;
begin
  if not active then
    ass_$precondition_fail('EXS_$FINALISE -- not active%$');
  active := false;
  propagation_on := false;
  subprogram := nil;
  sub_raised := nil;
  sub_explicit := false;
  raised := nil;
  all_handled := false;
  explicit := false;
  enquiry := false;
  cache_raised := nil;
  cache_valid := false;
  routine_enquiry := false;
  mem_$empty_pool(pool);
end;

{ exs_$start_subprogram - b the current subprogram (the last ended
  first); when routines propagate exceptions, a new vector for what
  leaves it (storage error in it from the start when its +378 bit 0 is
  set).

  0x0695F0, 0xAC bytes: the kinds by `seq'/`or.b' and one `bmi';
  bvs_$create_bit_vector(pool, il_140 + 1, false). }

procedure exs_$start_subprogram(
    b: univ_ptr);
var
  blk: exs_block_ptr_t;
begin
  blk := b;
  if subprogram <> nil then
    exs_$end_current_subprogram;
  if (blk = nil) or else
     not ((blk^.kind = 108) or (blk^.kind = 107) or (blk^.kind = 105)) then
    ass_$precondition_fail(
      'EXS_$START_SUBPROGRAM -- b is not a subprogram block_rec%$');
  if propagation_on then begin
    if blk^.info <> nil then
      ass_$precondition_fail(
        'EXS_$START_SUBPROGRAM -- subprogram has already had exception information computed%$');
    sub_raised := bvs_$create_bit_vector(pool, il_140 + 1, false);
    sub_explicit := false;
    if blk^.f378.storage then
      set_predefined_exception(sub_raised, 2);
  end;
  subprogram := blk;
end;

{ exs_$end_current_subprogram - when routines propagate exceptions,
  what leaves the subprogram recorded at its +36 (6 bytes from the
  pool); no current subprogram.

  0x06972A, 0x62 bytes: mem_$alloc(pool, 6) (`pea 0x6'). }

procedure exs_$end_current_subprogram;
var
  info: exs_info_ptr_t;
begin
  if subprogram = nil then
    ass_$precondition_fail('EXS_$END_SUBPROGRAM -- not started a subprogram%$');
  if propagation_on then begin
    info := mem_$alloc(pool, 6);
    info^.raised := sub_raised;
    info^.explicit := sub_explicit;
    subprogram^.info := info;
    sub_raised := nil;
    sub_explicit := false;
  end;
  subprogram := nil;
end;

{ init_exception_handler_enquiry - an enquiry opened at site in frame:
  what the site raises (in raised, made when first needed), the walk
  from frame's first handler (none when nothing is raised).

  0x0697BE, 0xC0 bytes, internal: frame (8, A4), site (12),
  check_storage (16), exc (18), site_flag (22, A3), site_word (26,
  A2); exception_info(..., raised, all_handled, explicit) (`pea
  (100,A5)', `pea (98,A5)'). }

procedure init_exception_handler_enquiry(
    frame: exs_frame_ptr_t;
    site: exs_node_ptr_t;
    check_storage: boolean;
    var exc: univ_ptr;
    var site_flag: boolean;
    var site_word: integer); options(val_param); internal;
begin
  if enquiry then
    ass_$precondition_fail(
      'EXS_$INIT_EXCEPTION_HANDLER_ENQUIRY -- previous enquiry not complete%$');
  check_frame(frame);
  walk_frame := frame;
  if exceptions_on and (raised = nil) then
    raised := bvs_$create_bit_vector(pool, il_140 + 1, false);
  exception_info(site, check_storage, exc, site_flag, site_word, raised,
                 all_handled, explicit);
  if all_handled then
    walk_frame := nil;
  if walk_frame = nil then
    walk_handler := nil
  else
    walk_handler := walk_frame^.handlers;
  enquiry := true;
end;

{ find_next_exception_handler - the next handler that takes one of the
  exceptions still raised (its exceptions taken out), through the
  frame's handlers and then the frames around it; a frame's handler
  for everything takes the rest; nil at the end.  all_handled when
  nothing is left (the walk then ends).

  0x0698C4, 0x12E bytes, internal: the handler's names from 1 to +70
  (`dbf'), each bvs_$test_and_clear(raised, exception_name_index(...))
  or-ed into the found flag (D2); bvs_$test_bit_vector(raised, false)
  when one is found. }

function find_next_exception_handler: univ_ptr; internal;
var
  found: boolean;
  h: univ_ptr;
  k: integer32;
  n: integer32;
begin
  if not enquiry then
    ass_$precondition_fail(
      'EXS_$FIND_NEXT_EXCEPTION_HANDLER -- no enquiry started%$');
  repeat
    if walk_frame = nil then begin
      find_next_exception_handler := nil;
      return;
    end;
    if walk_handler = nil then begin
      if walk_frame^.others = nil then begin
        walk_frame := walk_frame^.parent;
        if walk_frame = nil then
          walk_handler := nil
        else
          walk_handler := walk_frame^.handlers;
        found := false;
      end
      else begin
        bvs_$reset_bit_vector(raised, false);
        all_handled := true;
        h := walk_frame^.others;
        walk_frame := nil;
        walk_handler := nil;
        find_next_exception_handler := h;
        return;
      end;
    end
    else begin
      found := false;
      n := walk_handler^.nnames;
      for k := 1 to n do
        if bvs_$test_and_clear(raised,
             exception_name_index(walk_handler^.names[k])) then
          found := true;
      if found then begin
        h := walk_handler;
        if bvs_$test_bit_vector(raised, false) then begin
          walk_frame := nil;
          walk_handler := nil;
          all_handled := true;
        end
        else
          walk_handler := walk_handler^.next;
      end
      else
        walk_handler := walk_handler^.next;
    end;
  until found;
  find_next_exception_handler := h;
end;

{ exs_$start_exception_handler_enquiry - an enquiry at site in frame,
  from the cache when it is the last one's (the same subprogram,
  frame, site and check_storage), else opened and its first two
  handlers found and cached.  handled with use_strategy, exactly one
  handler, a known exception, everything handled and optimization 28
  (cargs opt_on, +0x280 bit 5): handler the handler itself and the enquiry
  closed; else handler the first's +48 (nil for none).

  0x069A2A, 0x1EE bytes: frame (8, A2), site (12, A3), check_storage
  (16, D3, compared extended to a longword with +20), use_strategy (18,
  D2), handled (20, D5), exc (24), handler (28), site_flag (32, A4),
  site_word (36, D4); the cache's comparisons each `seq; tst.b; bpl';
  cache_valid := true as `move.l D0,(4,A5)' of -1; next_state 2 or 0. }

procedure exs_$start_exception_handler_enquiry(
    frame: univ_ptr;
    site: univ_ptr;
    check_storage: boolean;
    use_strategy: boolean;
    var handled: boolean;
    var exc: univ_ptr;
    var handler: univ_ptr;
    var site_flag: boolean;
    var site_word: integer);
begin
  if enquiry then
    ass_$precondition_fail(
      'EXS_$START_EXCEPTION_HANDLER_ENQUIRY -- previous enquiry not complete%$');
  if cache_valid and then (subprogram = cache_subprogram)
     and then (frame = cache_frame) and then (site = cache_site)
     and then (check_storage = cache_check_storage) then begin
    exc := cache_exc;
    site_flag := cache_site_flag;
    site_word := cache_site_word;
    if exceptions_on then
      bvs_$copy(cache_raised, raised);
    all_handled := cache_all_handled;
    explicit := cache_explicit;
    walk_frame := cache_walk_frame;
    walk_handler := cache_walk_handler;
    first_handler := cache_first;
    second_handler := cache_second;
    enquiry := true;
  end
  else begin
    init_exception_handler_enquiry(frame, site, check_storage, exc,
                                   site_flag, site_word);
    first_handler := find_next_exception_handler;
    second_handler := find_next_exception_handler;
    cache_valid := true;
    cache_subprogram := subprogram;
    cache_frame := frame;
    cache_site := site;
    cache_check_storage := check_storage;
    cache_exc := exc;
    cache_site_flag := site_flag;
    cache_site_word := site_word;
    if exceptions_on then begin
      if cache_raised = nil then
        cache_raised := bvs_$create_bit_vector(pool, il_140 + 1, false);
      bvs_$copy(raised, cache_raised);
    end;
    cache_all_handled := all_handled;
    cache_explicit := explicit;
    cache_walk_frame := walk_frame;
    cache_walk_handler := walk_handler;
    cache_first := first_handler;
    cache_second := second_handler;
  end;
  if first_handler = nil then
    next_state := 2
  else
    next_state := 0;
  if use_strategy and (first_handler <> nil) and (second_handler = nil)
     and (exc <> nil) and all_handled
     and (28 in cargs_$options.opt_on) then begin
    handled := true;
    handler := first_handler;
    enquiry := false;
  end
  else begin
    handled := false;
    if first_handler = nil then
      handler := nil
    else
      handler := exs_handler_ptr_t(first_handler)^.l48;
  end;
end;

{ exs_$next_exception_handler - the enquiry's next handler: the two
  found when it started, then the walk's.

  0x069C60, 0x52 bytes: next_state 0, 1, 2 by compares; A0 not set for
  another state. }

function exs_$next_exception_handler: univ_ptr;
begin
  case next_state of
    0: begin
      exs_$next_exception_handler := first_handler;
      if second_handler = nil then
        next_state := 2
      else
        next_state := 1;
    end;
    1: begin
      exs_$next_exception_handler := second_handler;
      next_state := 2;
    end;
    2:
      exs_$next_exception_handler := find_next_exception_handler;
  end;
end;

{ exs_$end_exception_handler_enquiry - the enquiry closed; every
  handler must have been asked for.  propagated (when routines
  propagate exceptions) unless everything was handled, and then what
  escapes added to the subprogram's.

  0x069CB2, 0xD0 bytes: the failure's argument the tree node's
  operator (+36) or the node's kind, zero-extended to a frame longword
  at -8; bvs_$or(raised, sub_raised); `or.b' of explicit into
  sub_explicit. }

procedure exs_$end_exception_handler_enquiry(
    var propagated: boolean);
var
  site: exs_node_ptr_t;
  n: integer32;
begin
  if not enquiry then
    ass_$precondition_fail(
      'EXS_$END_EXCEPTION_HANDLER_ENQUIRY -- no enquiry started%$');
  if (next_state <> 2) or (walk_frame <> nil) then begin
    site := cache_site;
    if (site^.kind = 143) or (site^.kind = 138) or (site^.kind = 137) then begin
      n := exs_tree_ptr_t(site)^.op;
      ass_$precondition_fail(
        'EXS_$END_EXCEPTION_HANDLER_ENQUIRY -- have not processed all handlers of tree node enquiry (ord(tree_node.op)=%lsd)%$',
        n);
    end
    else begin
      n := site^.kind;
      ass_$precondition_fail(
        'EXS_$END_EXCEPTION_HANDLER_ENQUIRY -- have not processed all handlers of node enquiry (ord(node^.kind)=%lsd)%$',
        n);
    end;
  end;
  if not propagation_on then
    propagated := false
  else begin
    if sub_raised = nil then
      ass_$precondition_fail(
        'EXS_$END_EXCEPTION_HANDLER_ENQUIRY -- no current subprogram%$');
    propagated := not all_handled;
    if propagated then begin
      bvs_$or(raised, sub_raised);
      sub_explicit := sub_explicit or explicit;
    end;
  end;
  enquiry := false;
end;

{ exs_$cancel_exception_handler_enquiry - the enquiry closed.

  0x069EDE, 0x1E bytes, internal (no A5: the caller's). }

procedure exs_$cancel_exception_handler_enquiry; internal;
begin
  if not enquiry then
    ass_$precondition_fail(
      'EXS_$CANCEL_EXCEPTION_HANDLER_ENQUIRY -- no enquiry started%$');
  enquiry := false;
end;

{ exs_$map_to_predefined_exception - the index of e among il_f0's seven
  (7 when it is none of them).

  0x069F3A, 0x54 bytes: `cmpi.w #7; beq' then `cmpa.l (0x30,A0,D1.w)'
  with A0 0x2E9DA0; the index a word in D0. }

function exs_$map_to_predefined_exception(
    e: univ_ptr): integer;
var
  k: integer;
begin
  if (e = nil) or else (exs_node_ptr_t(e)^.kind <> 109) then
    ass_$precondition_fail(
      'EXS_$MAP_TO_PREDEFINED_EXCEPTION -- exception not a var_name%$');
  k := 0;
  while (k <> 7) and then (il_f0[k] <> e) do
    k := k + 1;
  exs_$map_to_predefined_exception := k;
end;

{ exs_$exception_raise_strategy - an enquiry with use_strategy that is
  closed at once unless handled.

  0x069FCC, 0x4C bytes: check_storage false (`clr.w'), use_strategy
  true (`st'); site_flag and site_word in the frame (-4, -2). }

procedure exs_$exception_raise_strategy(
    frame: univ_ptr;
    site: univ_ptr;
    var handled: boolean;
    var exc: univ_ptr;
    var handler: univ_ptr);
var
  site_word: integer;
  site_flag: boolean;
begin
  exs_$start_exception_handler_enquiry(frame, site, false, true, handled,
                                       exc, handler, site_flag, site_word);
  if not handled then
    exs_$cancel_exception_handler_enquiry;
end;

{ set_frame - the routine enquiry at f's handlers.

  0x06A018, 0x1C bytes, internal, no frame: f at (4,SP). }

procedure set_frame(
    f: exs_frame_ptr_t); options(val_param); internal;
begin
  routine_frame := f;
  if f = nil then
    routine_handler := nil
  else
    routine_handler := f^.handlers;
end;

{ exs_$start_all_exception_handlers_of_routine_enquiry - a routine
  enquiry from the current subprogram's first frame (+32).

  0x06A034, 0x36 bytes. }

procedure exs_$start_all_exception_handlers_of_routine_enquiry;
begin
  if subprogram = nil then
    ass_$precondition_fail(
      'EXS_$ROUTINE_NEXT_EXCEPTION_HANDLER -- no current subprogram set%$');
  set_frame(subprogram^.frames);
  routine_enquiry := true;
end;

{ exs_$routines_next_exception_handler - the routine enquiry's next
  handler: each frame's handlers (along +72), then its handler for
  everything, then the next frame's (+4); nil at the end.

  0x06A0AC, 0x78 bytes. }

function exs_$routines_next_exception_handler: univ_ptr;
var
  h: univ_ptr;
begin
  if not routine_enquiry then
    ass_$precondition_fail(
      'EXS_$ROUTINE_NEXT_EXCEPTION_HANDLER -- no enquiry started%$');
  repeat
    if routine_frame = nil then begin
      exs_$routines_next_exception_handler := nil;
      return;
    end;
    if routine_handler <> nil then begin
      h := routine_handler;
      routine_handler := routine_handler^.next;
      exs_$routines_next_exception_handler := h;
      return;
    end;
    if routine_frame^.others <> nil then begin
      h := routine_frame^.others;
      set_frame(routine_frame^.next);
      exs_$routines_next_exception_handler := h;
      return;
    end;
    set_frame(routine_frame^.next);
  until false;
end;

{ exs_$subprogram_may_propogate_exceptions_by_explicit_raise - false
  when routines do not propagate exceptions; true when b has no
  record yet.

  0x06A160, 0x6A bytes: the kinds as exs_$start_subprogram's. }

function exs_$subprogram_may_propogate_exceptions_by_explicit_raise(
    b: univ_ptr): boolean;
var
  blk: exs_block_ptr_t;
begin
  blk := b;
  if (blk = nil) or else
     not ((blk^.kind = 108) or (blk^.kind = 107) or (blk^.kind = 105)) then
    ass_$precondition_fail(
      'EXS_$SUBPROGRAM_MAY_PROPOGATE_EXCEPTIONS_BY_EXPLICIT_RAISE -- b is not a subprogram block_rec%$');
  if not propagation_on then
    exs_$subprogram_may_propogate_exceptions_by_explicit_raise := false
  else if blk^.info = nil then
    exs_$subprogram_may_propogate_exceptions_by_explicit_raise := true
  else
    exs_$subprogram_may_propogate_exceptions_by_explicit_raise :=
      blk^.info^.explicit;
end;

{ exs_$frame_has_handler_for_predefined_exception - 0x06A22A, 0x40
  bytes: `btst D2,D0' of the word at +40. }

function exs_$frame_has_handler_for_predefined_exception(
    frame: univ_ptr;
    k: integer): boolean;
var
  f: exs_frame_ptr_t;
begin
  f := frame;
  if f = nil then
    exs_$frame_has_handler_for_predefined_exception := false
  else begin
    check_frame(f);
    exs_$frame_has_handler_for_predefined_exception := k in f^.predefined;
  end;
end;

{ exs_$frame_is_lexically_nested - inner taken up (+16) by the
  difference of the depths (+20) and compared with outer, when outer
  is the shallower.

  0x06A26A, 0x7C bytes: outer (8, D2), inner (12, A2), both checked;
  `cmp.l; bcs' (the depths unsigned); the walk a `dbf' with the borrow
  from the high word. }

function exs_$frame_is_lexically_nested(
    outer: univ_ptr;
    inner: univ_ptr): boolean;
var
  o, f: exs_frame_ptr_t;
  k: integer32;
begin
  o := outer;
  f := inner;
  check_frame(o);
  check_frame(f);
  if f = nil then
    exs_$frame_is_lexically_nested := false
  else if o = nil then
    exs_$frame_is_lexically_nested := true
  else if o^.depth < f^.depth then begin
    for k := 1 to f^.depth - o^.depth do
      f := f^.parent;
    exs_$frame_is_lexically_nested := f = o;
  end
  else
    exs_$frame_is_lexically_nested := false;
end;
