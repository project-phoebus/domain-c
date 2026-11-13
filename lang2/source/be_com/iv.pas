{ iv - the PRISM back end's induction variable phase (IV): the loops'
  induction variables (ivr_: candidates from the loop heads' joins,
  propagated through adds, subs, moves and modifying loads and stores,
  then verified), the induction expressions of them found in each block
  (ixr_: instantiations of secondary variables, address modes),
  strength reduced (ixt_: the most used expression of a secondary made
  a new primary variable, the others rewritten from it), the variables
  recomputed for oli; and the expression utilities (iv_utils_) oli
  shares.  The loops are walked by interval, innermost first
  (iv_$walk_basic_blocks_in_order).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x238DB0  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x238DD2  iv_$begin_compilation
    --------  0x238EE0  iv_$end_compilation
    --------  0x238EE2  iv_$end_routine
    --------  0x238F3C  zero (internal)
    --------  0x238F62  alloc_induction_lts (internal)
    --------  0x238F98  alloc_induction_addr (internal)
    --------  0x238FD0  alloc_induction_expr (internal)
    --------  0x239008  alloc_induction_class (internal)
    --------  0x239040  alloc_expression (internal)
    --------  0x239078  alloc_induction_variable (internal)
    --------  0x2390B0  create_induction_addr (internal)
    --------  0x2390FC  free_expression (internal)
    --------  0x239110  iv_utils_$delete_expression
    --------  0x23916C  order_expressions (internal)
    --------  0x2392CE  get_canonical_compare_node (internal)
    --------  0x2393BC  get_canonical_base_node (internal)
    --------  0x2393F4  get_canonical_remaining_node (internal)
    --------  0x239414  has_canonical_form (internal)
    --------  0x23942A  canonical_base_node_is_positive (internal)
    --------  0x239438  build_multiplier_from_base (internal)
    --------  0x239508  iv_utils_$create_add_expression
    --------  0x239542  iv_utils_$create_sub_expression
    --------  0x23957C  iv_utils_$create_mul_expression
    --------  0x2395B6  iv_utils_$create_neg_expression (internal)
    --------  0x2395E2  iv_utils_$create_value_expression
    --------  0x239612  iv_utils_$create_lts_expression
    --------  0x239642  iv_utils_$create_operand_expression
    --------  0x239680  create_transfer_expression (internal)
    --------  0x2396A0  create_move_expression (internal)
    --------  0x2396C0  iv_utils_$expression_is_zero (internal)
    --------  0x2396DA  iv_utils_$canonicalize_expression
    --------  0x23974E  create_add_or_sub_expression (internal)
    --------  0x239776  same_base_operand (internal)
    --------  0x2397DC  operand_offset_difference (internal)
    --------  0x239828  clean_up_additive_canonical_result (internal)
    --------  0x239BA4  canonicalize_add_expression (internal)
    --------  0x239F5C  canonicalize_sub_expression (internal)
    --------  0x23A374  canonicalize_mul_expression (internal)
    --------  0x23A5DA  canonicalize_neg_expression (internal)
    --------  0x23A6FA  canonicalize_rsub_expression (internal)
    --------  0x23A73C  iv_utils_$duplicate_expression
    --------  0x23A830  iv_utils_$compare_expressions
    --------  0x23A956  propagate_up_cost (internal)
    --------  0x23AACC  can_encode_as_register (internal)
    --------  0x23AB0E  first_operand_can_change (internal)
    --------  0x23AB78  propagate_down_type (internal)
    --------  0x23AED4  elaborate_expression (internal)
    --------  0x23B07E  iv_utils_$elaborate_expression
    --------  0x23B124  find_last_instruction (internal)
    --------  0x23B16A  add_operand_to_segment (internal)
    --------  0x23B1F6  create_operand_from_elaborated_expression (internal)
    --------  0x23B876  iv_utils_$create_operand_from_expression
    --------  0x23B8EE  iv_utils_$live_range_from_elaborated_expression
    --------  0x23BBAE  increments_are_equal (internal)
    --------  0x23BBE8  create_induction_lts (internal)
    --------  0x23BC54  free_induction_lts (internal)
    --------  0x23BC64  iv_utils_$delete_induction_lts
    --------  0x23BD24  free_induction_addr (internal)
    --------  0x23BD34  iv_utils_$delete_induction_addr (internal)
    --------  0x23BD70  free_induction_expr (internal)
    --------  0x23BD80  create_induction_expr (internal)
    --------  0x23BDCC  create_induction_class (internal)
    --------  0x23BE24  free_induction_class (internal)
    --------  0x23BE34  create_induction_variable (internal)
    --------  0x23BF04  free_induction_variable (internal)
    --------  0x23BF14  iv_utils_$delete_induction_expr (internal)
    --------  0x23BFB0  iv_utils_$delete_induction_class (internal)
    --------  0x23C028  iv_utils_$delete_induction_variable (internal)
    --------  0x23C112  interval_contains_bb (internal)
    --------  0x23C140  lts_is_loop_invariant (internal)
    --------  0x23C2AC  operand_is_loop_invariant (internal)
    --------  0x23C316  find_definition (internal)
    --------  0x23C3BA  iv_utils_$locate_definition (internal)
    --------  0x23C44A  iv_utils_$create_expression_from_lts
    --------  0x23C702  iv_utils_$create_expression_from_operand
    --------  0x23C7AA  propagate_induction_increment (internal)
    --------  0x23C850  ivr_$propagate_induction_for_lifetime_segment (internal)
    --------  0x23CB6C  duplicate_increment_information (internal)
    --------  0x23CBAE  ivr_$locate_induction_candidates (internal)
    --------  0x23CD10  ivr_$propagate_induction_into_basic_block (internal)
    --------  0x23CE66  operand_has_same_induction_variable (internal)
    --------  0x23CEAE  apply_to_creating_induction_segments (internal)
    --------  0x23CFB2  ivr_$mark_lifetime_segments_as_induction_variables
    --------  0x23D062  ivr_$verify_candidate_is_induction_variable (internal)
    --------  0x23D238  ivr_$finalize_induction_variables (internal)
    --------  0x23D288  iv_$walk_basic_blocks_in_order
    --------  0x23D340  operand_is_any_induction_expression (internal)
    --------  0x23D39A  ixr_$find_current_lts_for_iv (internal)
    --------  0x23D5A0  iv_utils_$compare_address_expressions
    --------  0x23D60C  ixr_$find_induction_class (internal)
    --------  0x23D692  ixr_$find_induction_expr (internal)
    --------  0x23D718  ixr_$find_induction_variable (internal)
    --------  0x23D852  ixr_$create_induction_lts_from_induction_instantiation (internal)
    --------  0x23D8FE  ixr_$create_induction_addr_from_induction_instantiation (internal)
    --------  0x23D9A0  ixr_$get_induction_instantiation_from_operand (internal)
    --------  0x23DC0A  operand_is_current_induction_expression (internal)
    --------  0x23DC6E  ixr_$induction_expr_plus_loop_invariant (internal)
    --------  0x23DD6A  ixr_$induction_expr_plus_induction_expr (internal)
    --------  0x23DF3C  ixr_$induction_expr_times_loop_invariant (internal)
    --------  0x23E042  ixr_$induction_expr_shifted_loop_invariant (internal)
    --------  0x23E14C  ixr_$induction_expression (internal)
    --------  0x23E1D0  ixr_$scan_addressing_mode (internal)
    --------  0x23E2B6  ixr_$scan_basic_block_for_induction_expressions
    --------  0x23E6E6  ixt_$multiply_cost (internal)
    --------  0x23E754  get_secondary_segment (internal)
    --------  0x23E766  ixt_$induction_segment_exists (internal)
    --------  0x23E7BE  ixt_$clear_primary_used_fields (internal)
    --------  0x23E7D8  ixt_$mark_primary_used_fields (internal)
    --------  0x23E86E  ixt_$count_primary_used_fields (internal)
    --------  0x23E8B6  ixt_$replace_segment_references (internal)
    --------  0x23E9FE  ixt_$create_increment_instruction (internal)
    --------  0x23EB76  remove_segment_from_operand (internal)
    --------  0x23EC12  ixt_$replace_induction_expr (internal)
    --------  0x23EF5A  ixt_$cleanup_segment_references (internal)
    --------  0x23EFD8  ixt_$cleanup_induction_expr (internal)
    --------  0x23F054  ixt_$instantiate_induction_expr (internal)
    --------  0x23F5E0  ixt_$process_secondary_induction_variable (internal)
    --------  0x23F954  ixt_$process_primary_induction_variable (internal)
    --------  0x23F9AC  ixt_$process_induction_transformations (internal)
    --------  0x23F9DE  iv_$locate_induction_variables_at_loop_start
    --------  0x23FA46  iv_$locate_induction_variables_for_basic_block
    --------  0x23FA6A  iv_$locate_induction_variables_at_loop_end
    --------  0x23FB02  iv_$build_nested_reverse_postorder_lists (internal)
    --------  0x23FB60  get_increment_from_induction (internal)
    --------  0x23FD98  recompute_for_oli
    --------  0x23FF80  iv_$process_routine
    A5 0x486500: the module's data: instr_size (+0, instr_size.init),
    iv_opc_set (+0x300), iv_opc_kind (+0x330: the expression kind of an
    opcode), iv_commuted (+0x630), iv_opnd_pos (+0x650), iv_opc (+0x688,
    two rows), iv_nchildren (+0x6C0), the six heaps (+0x6E0 .. +0x758),
    iv_zero (+0x774), the free lists (+0x778 .. +0x788, +0x7B0), the
    routine's state (+0x78C .. +0x7B8), iv_elab_class (+0x7C0),
    iv_signs (+0x7DA, not read), the increment opcodes (+0x7E0, +0x7F0).

  The expression utilities' callers in other units reach them through
  iv.ins.pas, which also declares the induction records and (as the
  image's .blocks list implies: they are listed with the routines
  declared before their bodies) create_operand_from_expression and
  create_expression_from_lts/_operand.  A module-level routine that
  does not load A5 is internal, whatever its prefix.

  Not known from the original: every local, parameter, cell and type
  name. }

module iv;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/iv.ins.pas';
var
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_size.init';
%include 'lang2/source/be_com/utils.ins.pas';

type
  iv_cost_t = array [1..2] of integer;

  { iv's view of a block (a field batch A has not named; backend.ins.pas
    bb_t's space138): an interval head's first member (+138), the
    members chained at bb_t.next142 (+142). }
  iv_bb_v_ptr_t = ^iv_bb_v_t;
  iv_bb_v_t = record
    space0: array [0..137] of char;
    first138: bb_ptr_t;                 { +138 }
  end;

  { A join birthpoint's input, as utils.pas's ut_jbi_t: chained from
    the join instruction's operand 3's link (+72) at next_op. }
  iv_jbi_ptr_t = ^iv_jbi_t;
  iv_jbi_t = record
    next: iv_jbi_ptr_t;                 { +0 }
    next_op: iv_jbi_ptr_t;              { +4 }
    lts: lts_ptr_t;                     { +8 }
  end;

  { A literal pool operand's constant (its link, an IL node made by
    smcontk): w4 its type (constants of types 0, 3, 4, 7 and 10 are
    taken), value (+8). }
  iv_node_v_ptr_t = ^iv_node_v_t;
  iv_node_v_t = record
    w0: integer;                        { +0 }
    w2: integer;                        { +2 }
    w4: integer;                        { +4 }
    w6: integer;                        { +6 }
    value: integer32;                   { +8 }
  end;

  { The state of an enclosing loop while an inner one is worked on (20
    bytes, `new' and `dispose'): chained from iv_states. }
  iv_state_ptr_t = ^iv_state_t;
  iv_state_t = record
    prev: iv_state_ptr_t;               { +0 }
    head: bb_ptr_t;                     { +4 }
    vars: iv_var_ptr_t;                 { +8 }
    vars_last: iv_var_ptr_t;            { +12 }
    l16: integer32;                     { +16 }
  end;

  { An instantiation of an induction variable (12 bytes, passed by
    address and returned through the caller's space): the variable, the
    expression added to it, and the variable's segment current at the
    operand (ixr_$get_induction_instantiation_from_operand). }
  iv_inst_t = record
    ivar: iv_var_ptr_t;                 { +0 }
    expr: iv_expr_ptr_t;                { +4 }
    ilts: iv_lts_ptr_t;                 { +8 }
  end;

  { What apply_to_creating_induction_segments and
    iv_$walk_basic_blocks_in_order call (`jsr (A1)', addresses passed
    by `move.l #addr': pattern 104): given a segment's or a block's
    slot by address. }
  iv_lts_proc_t = ^procedure(
      var s: lts_ptr_t);
  iv_bb_proc_t = ^procedure(
      var bb: bb_ptr_t);

var
  { +0x300: the opcodes an expression is made from (those with a kind
    in iv_opc_kind): a set of 0..383, 48 bytes, tested `move.w #383;
    sub.w opc; lsr.w #3; btst opc,(A5+0x300,D0.w)'. }
  iv_opc_set: set of 0..383 := [75, 77, 79, 81, 83, 92, 105, 106, 116,
    126, 135, 137, 138, 144, 178];

  { +0x330: the expression kind an instruction of each opcode computes
    (0 none), by opcode 0..383 (0x300 bytes, up to iv_commuted; .rwdi
    sets only the nonzero words). }
  iv_opc_kind: array [0..383] of integer := [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 0 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 16 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 32 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 48 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 4, 0, 5,  { 64 }
    0, 6, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0,  { 80 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 11, 0, 0, 0, 0, 0,  { 96 }
    0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0,  { 112 }
    0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 6, 0, 0, 0, 0, 0,  { 128 }
    10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 144 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 160 }
    0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 176 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 192 }
    0, 0, 0, 0, 172 of 0];              { 208 }

  { +0x630: the kind an expression of each kind becomes with its
    children exchanged (0 none). }
  iv_commuted: array [0..15] of integer := [
    0, 0, 0, 0, 0, 5, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  { +0x650: the instruction operand each child of an expression of each
    kind becomes. }
  iv_opnd_pos: array [0..13, 1..2] of integer := [
    [0, 0], [0, 0], [0, 0], [0, 0], [1, 0], [2, 1], [2, 1], [2, 1],
    [2, 1], [1, 0], [1, 0], [0, 0], [1, 2], [0, 0]];

  { +0x688: the opcode that computes an expression of each kind in an
    integer register (row 1: neg, add, sub, -, rsub, mffp, move, loadl,
    lsl) and in a floating one (row 2, +0x6A2: negi, addi, subi, muli,
    -, mtfp, copys, loads): one table by register file and kind, indexed
    A5 + 0x66E + 26 rclass + 2 kind (create_operand_from_elaborated_
    expression). }
  iv_opc: array [1..2, 0..12] of integer := [
    [0, 0, 0, 0, 77, 79, 81, 0, 83, 116, 75, 105, 92],
    [0, 0, 0, 0, 135, 137, 138, 178, 0, 126, 144, 106, 0]];

  { +0x6C0: the children of an expression of each kind. }
  iv_nchildren: array [0..12] of integer := [
    0, 0, 0, 0, 1, 2, 2, 2, 2, 1, 1, 0, 2];

  { +0x6E0 .. +0x758: the heaps, with their names. }
  iv_iexpr_heap: mrh_$heap_t;           { +0x6E0: induction expressions
                                          (22 bytes) }
  iv_addr_heap: mrh_$heap_t;            { +0x6F8: induction address
                                          modes (28) }
  iv_class_heap: mrh_$heap_t;           { +0x710: induction classes (20) }
  iv_lts_heap: mrh_$heap_t;             { +0x728: induction lts (36) }
  iv_var_heap: mrh_$heap_t;             { +0x740: induction variables
                                          (62) }
  iv_expr_heap: mrh_$heap_t;            { +0x758: expressions (24) }

  { +0x778 .. +0x788, +0x7B0: the records given back, for reuse. }
  iv_free_class: iv_class_ptr_t;        { +0x778 (chained at +8) }
  iv_free_iexpr: iv_iexpr_ptr_t;        { +0x77C (+8) }
  iv_free_addr: iv_addr_ptr_t;          { +0x780 (+16) }
  iv_free_lts: iv_lts_ptr_t;            { +0x784 (+16) }
  iv_free_var: iv_var_ptr_t;            { +0x788 (+50) }
  iv_free_expr: iv_expr_ptr_t;          { +0x7B0 (+12) }

  { +0x774, +0x78C .. +0x7B8: the routine's state. }
  iv_zero: iv_expr_ptr_t;               { +0x774: the constant 0 (what an
                                          instantiated expression is
                                          replaced by) }
  iv_intervals: bb_ptr_t;               { +0x78C: the blocks in no
                                          interval (the outermost heads
                                          among them), chained at +142 }
  iv_790: univ_ptr;                     { +0x790: cleared, not read }
  iv_states: iv_state_ptr_t;            { +0x794: the enclosing loops' }
  iv_vars_last: iv_var_ptr_t;           { +0x798: the last on iv_vars }
  iv_vars: iv_var_ptr_t;                { +0x79C: the primary induction
                                          variables, chained at +50 }
  iv_head: bb_ptr_t;                    { +0x7A0: the loop (interval head)
                                          being worked on }
  iv_bb80: bb_ptr_t;                    { +0x7A8: the routine's +80, not
                                          read }
  iv_rtn: rtn_ptr_t;                    { +0x7AC: the routine }
  iv_7b4: integer;                      { +0x7B4: set to 1, not read }
  iv_7b6: integer;                      { +0x7B6: set to 1, not read }
  iv_changed: boolean;                  { +0x7B8: an expression was
                                          instantiated }

  { +0x7DA: six characters no instruction reads (as mmt's 'touched',
    docs/questions.md 170). }
  iv_signs: array [1..6] of char := '+-+-+-';

  { +0x7E0, +0x7F0: the opcode that adds an increment of each sign (-1
    sub, 0 move, 1 add) in each register file (ixt_$create_increment_
    instruction; ixt_$instantiate_induction_expr the second, the same). }
  iv_incr_opc: array [-1..1, 1..2] of integer := [
    [81, 138], [75, 144], [79, 137]];
  iv_incr_opc2: array [-1..1, 1..2] of integer := [
    [81, 138], [75, 144], [79, 137]];

  { +0x7C0: how elaborate_expression picks the register file of an
    expression's children by its kind: 1 its own (none), 2 the segment's
    definition's kind, 3 integer, 4 floating. }
  iv_elab_class: array [0..12] of integer := [
    0, 1, 2, 3, 1, 1, 1, 4, 3, 1, 1, 1, 3];

{ iv_$begin_compilation - the heaps made.  0x238DD2, 0xA0 bytes: each
  heap's flags and size pushed as one longword (pattern 105). }

procedure iv_$begin_compilation;
begin
  mrh_$initialize(iv_expr_heap, 1, 24, 'expression%');
  mrh_$initialize(iv_var_heap, 1, 62, 'induction variable%');
  mrh_$initialize(iv_class_heap, 1, 20, 'induction class%');
  mrh_$initialize(iv_addr_heap, 1, 28, 'induction address mode%');
  mrh_$initialize(iv_iexpr_heap, 1, 22, 'induction expression%');
  mrh_$initialize(iv_lts_heap, 1, 36, 'induction lts%');
end;

{ iv_$end_compilation - nothing.  0x238EE0, 2 bytes. }

procedure iv_$end_compilation;
begin
end;

{ iv_$end_routine - the heaps released (the free lists are not
  cleared).  0x238EE2, 0x5A bytes. }

procedure iv_$end_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(iv_expr_heap);
  mrh_$release_all(iv_var_heap);
  mrh_$release_all(iv_class_heap);
  mrh_$release_all(iv_iexpr_heap);
  mrh_$release_all(iv_addr_heap);
  mrh_$release_all(iv_lts_heap);
end;

{ zero - n bytes from p cleared, one by one.  0x238F3C, 0x26 bytes, no
  frame (unlike at_backend's and zzzzz's longword helpers, pattern
  100). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  bytes_t = packed array [1..65536] of char;
var
  b: ^bytes_t;
  k: integer32;
begin
  b := p;
  for k := 1 to n do
    b^[k] := chr(0);
end;

{ alloc_induction_lts - an induction lts, reused from the free list
  (cleared) or new.  0x238F62, 0x36 bytes, no A5: A0.  The other
  allocators are alike (pattern 98's per-unit helpers' shape). }

function alloc_induction_lts: iv_lts_ptr_t; internal;
var
  l: iv_lts_ptr_t;
begin
  if iv_free_lts = nil then
    l := mrh_$alloc_fixed(iv_lts_heap)
  else begin
    l := iv_free_lts;
    iv_free_lts := l^.next;
    zero(l, 36);
  end;
  alloc_induction_lts := l;
end;

{ alloc_induction_addr - an induction address mode.  0x238F98, 0x38
  bytes. }

function alloc_induction_addr: iv_addr_ptr_t; internal;
var
  a: iv_addr_ptr_t;
begin
  if iv_free_addr = nil then
    a := mrh_$alloc_fixed(iv_addr_heap)
  else begin
    a := iv_free_addr;
    iv_free_addr := a^.next;
    zero(a, 28);
  end;
  alloc_induction_addr := a;
end;

{ alloc_induction_expr - an induction expression.  0x238FD0, 0x38
  bytes. }

function alloc_induction_expr: iv_iexpr_ptr_t; internal;
var
  x: iv_iexpr_ptr_t;
begin
  if iv_free_iexpr = nil then
    x := mrh_$alloc_fixed(iv_iexpr_heap)
  else begin
    x := iv_free_iexpr;
    iv_free_iexpr := x^.next;
    zero(x, 22);
  end;
  alloc_induction_expr := x;
end;

{ alloc_induction_class - an induction class.  0x239008, 0x38 bytes. }

function alloc_induction_class: iv_class_ptr_t; internal;
var
  c: iv_class_ptr_t;
begin
  if iv_free_class = nil then
    c := mrh_$alloc_fixed(iv_class_heap)
  else begin
    c := iv_free_class;
    iv_free_class := c^.next;
    zero(c, 20);
  end;
  alloc_induction_class := c;
end;

{ alloc_expression - an expression, reused from the free list (cleared)
  or new.  0x239040, 0x38 bytes, no A5: A0. }

function alloc_expression: iv_expr_ptr_t; internal;
var
  e: iv_expr_ptr_t;
begin
  if iv_free_expr = nil then
    e := mrh_$alloc_fixed(iv_expr_heap)
  else begin
    e := iv_free_expr;
    iv_free_expr := e^.left;
    zero(e, 24);
  end;
  alloc_expression := e;
end;

{ alloc_induction_variable - an induction variable.  0x239078, 0x38
  bytes. }

function alloc_induction_variable: iv_var_ptr_t; internal;
var
  v: iv_var_ptr_t;
begin
  if iv_free_var = nil then
    v := mrh_$alloc_fixed(iv_var_heap)
  else begin
    v := iv_free_var;
    iv_free_var := v^.next;
    zero(v, 62);
  end;
  alloc_induction_variable := v;
end;

{ create_induction_addr - an address mode of operand o (of its
  instruction) by induction expression x, put first on x's list; the
  variable's current segment ilts and o's base register operand.
  0x2390B0, 0x4C bytes, no A5. }

function create_induction_addr(
    x: iv_iexpr_ptr_t;
    ilts: iv_lts_ptr_t;
    o: opnd_ptr_t;
    base: opnd_ptr_t): iv_addr_ptr_t; options(val_param); internal;
var
  a: iv_addr_ptr_t;
begin
  a := alloc_induction_addr;
  a^.iexpr := x;
  a^.ilts := ilts;
  a^.opnd := o;
  a^.base := base;
  a^.instr := utils_ins_$operands_instruction(o);
  a^.next := x^.addrs;
  x^.addrs := a;
  create_induction_addr := a;
end;

{ free_expression - e put on the free list (not its children), e nil.
  0x2390FC, 0x14 bytes, no frame. }

procedure free_expression(
    var e: iv_expr_ptr_t); internal;
begin
  e^.left := iv_free_expr;
  iv_free_expr := e;
  e := nil;
end;

{ iv_utils_$delete_expression - e and its children (by the kind's
  count) given back.  0x239110, 0x5C bytes: recursive. }

procedure iv_utils_$delete_expression(
    var e: iv_expr_ptr_t);
var
  k: integer32;
begin
  if e <> nil then begin
    for k := 1 to iv_nchildren[e^.kind] do
      iv_utils_$delete_expression(e^.child[k]);
    free_expression(e);
  end;
end;

{ order_expressions - the order of two canonical compare nodes: by
  kind; constants equal; operands by kind, displacements by their node
  and value, like registers by their live range's number (1 for
  others); segments by block order, then by the operand within one
  instruction, else 1 when a's definition comes first in a's block, -1
  when b's does.  0x23916C, 0x162 bytes, no A5: the orders and numbers
  compared unsigned. }

function order_expressions(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): integer32; options(val_param); internal;
var
  d: integer32;
  ia, ib, i: instr_ptr_t;
begin
  d := a^.kind - b^.kind;
  if d = 0 then
    if a^.kind <> iv_value then
      if a^.kind = iv_operand then begin
        d := ord(a^.opnd.h.kind) - ord(b^.opnd.h.kind);
        if d = 0 then
          case a^.opnd.h.kind of
            operand$displacement_arg_block, operand$displacement_stack_frame,
            operand$displacement_literal_pool: begin
              d := integer32(a^.opnd.link) - integer32(b^.opnd.link);
              if d = 0 then
                d := a^.opnd.value - b^.opnd.value;
            end;
            operand$ip_reg_like, operand$fp_reg_like,
            operand$fp_reg_pair_like:
              d := a^.opnd.lts^.lr^.num - b^.opnd.lts^.lr^.num;
            otherwise
              d := 1;
          end;
      end
      else if a^.kind = iv_lts then begin
        if a^.lts = b^.lts then
          d := 0
        else begin
          d := a^.lts^.bb^.order - b^.lts^.bb^.order;
          if d = 0 then begin
            ia := utils_ins_$operands_instruction(a^.lts^.refs);
            ib := utils_ins_$operands_instruction(b^.lts^.refs);
            if ia = ib then
              d := a^.lts^.refs^.h.num - b^.lts^.refs^.h.num
            else begin
              i := a^.lts^.bb^.first;
              while i <> nil do begin
                if i = ia then begin
                  d := 1;
                  exit;
                end;
                if i = ib then begin
                  d := -1;
                  exit;
                end;
                i := i^.next;
              end;
            end;
          end;
        end;
      end
      else
        d := 1;
  order_expressions := d;
end;

{ get_canonical_compare_node - what orders a canonical expression: a
  leaf itself; for a sum or difference its base (the right child); for
  a negation its operand or segment, or the segment a multiple of it
  multiplies; for a multiple the segment it multiplies; nil for
  anything else.  0x2392CE, 0xEE bytes, no A5: jump tables by kind. }

function get_canonical_compare_node(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  r, x, y: iv_expr_ptr_t;
begin
  r := nil;
  if e <> nil then
    case e^.kind of
      iv_value, iv_lts, iv_operand:
        r := e;
      iv_add, iv_sub: begin
        x := e^.right;
        case x^.kind of
          iv_value, iv_lts, iv_operand:
            r := x;
          iv_neg: begin
            y := x^.left;
            if (y^.kind = iv_lts) or (y^.kind = iv_operand) then
              r := y
            else if y^.kind = iv_mul then
              if y^.left^.kind = iv_lts then
                r := y^.left;
          end;
          iv_mul:
            if x^.left^.kind = iv_lts then
              r := x^.left;
          otherwise
            ;
        end;
      end;
      iv_neg: begin
        y := e^.left;
        if (y^.kind = iv_lts) or (y^.kind = iv_operand) then
          r := y
        else if y^.kind = iv_mul then
          if y^.left^.kind = iv_lts then
            r := y^.left;
      end;
      iv_mul:
        if e^.left^.kind = iv_lts then
          r := e^.left;
      otherwise
        ;
    end;
  get_canonical_compare_node := r;
end;

{ get_canonical_base_node - a sum's or difference's right child, any
  other expression of kind 1..7 itself.  0x2393BC, 0x38 bytes, no
  frame. }

function get_canonical_base_node(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  r: iv_expr_ptr_t;
begin
  r := nil;
  if e <> nil then
    case e^.kind of
      iv_value, iv_lts, iv_operand, iv_neg, iv_mul:
        r := e;
      iv_add, iv_sub:
        r := e^.right;
      otherwise
        ;
    end;
  get_canonical_base_node := r;
end;

{ get_canonical_remaining_node - a sum's or difference's left child,
  else nil.  0x2393F4, 0x20 bytes, no frame. }

function get_canonical_remaining_node(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  r: iv_expr_ptr_t;
begin
  r := nil;
  if e <> nil then
    if (e^.kind = iv_sub) or (e^.kind = iv_add) then
      r := e^.left;
  get_canonical_remaining_node := r;
end;

{ has_canonical_form - e has a compare node.  0x239414, 0x16 bytes. }

function has_canonical_form(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
begin
  has_canonical_form := get_canonical_compare_node(e) <> nil;
end;

{ canonical_base_node_is_positive - e is not a difference (its base is
  added).  0x23942A, 0xE bytes, no frame. }

function canonical_base_node_is_positive(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
begin
  canonical_base_node_is_positive := e^.kind <> iv_sub;
end;

function iv_utils_$create_neg_expression(
    a: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); forward;

{ build_multiplier_from_base - the factor of a base node's compare node
  (positive: added, else subtracted): 1 or -1 for a leaf, a multiple's
  factor, a negation's leaf -1 or 1 and its multiple's factor negated;
  nil for anything else.  0x239438, 0xD0 bytes, no A5: the sign as
  ord(positive) * 2 - 1. }

function build_multiplier_from_base(
    e: iv_expr_ptr_t;
    positive: boolean): iv_expr_ptr_t; options(val_param); internal;
var
  r, x: iv_expr_ptr_t;
begin
  r := nil;
  case e^.kind of
    iv_value, iv_lts, iv_operand:
      r := iv_utils_$create_value_expression(ord(positive) * 2 - 1);
    iv_mul: begin
      r := e^.right;
      if not positive then
        r := iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(r));
    end;
    iv_neg: begin
      x := e^.left;
      case x^.kind of
        iv_value, iv_lts, iv_operand:
          r := iv_utils_$create_value_expression(1 - ord(positive) * 2);
        iv_mul: begin
          r := x^.right;
          if positive then
            r := iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(r));
        end;
        otherwise
          ;
      end;
    end;
    otherwise
      ;
  end;
  build_multiplier_from_base := r;
end;

{ iv_utils_$create_add_expression .. iv_utils_$create_operand_expression
  - an expression of each kind (the leaves made canonical).  0x239508
  (0x3A bytes), 0x239542 (0x3A), 0x23957C (0x3A), 0x2395B6 (0x2C),
  0x2395E2 (0x30), 0x239612 (0x30), 0x239642 (0x3E: the operand copied
  as three longwords); A0. }

function iv_utils_$create_add_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_add;
  e^.left := a;
  e^.right := b;
  iv_utils_$create_add_expression := e;
end;

function iv_utils_$create_sub_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_sub;
  e^.left := a;
  e^.right := b;
  iv_utils_$create_sub_expression := e;
end;

function iv_utils_$create_mul_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_mul;
  e^.left := a;
  e^.right := b;
  iv_utils_$create_mul_expression := e;
end;

function iv_utils_$create_neg_expression(
    a: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param);
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_neg;
  e^.left := a;
  iv_utils_$create_neg_expression := e;
end;

function iv_utils_$create_value_expression(
    v: integer32): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_value;
  e^.value := v;
  e^.canonical := true;
  iv_utils_$create_value_expression := e;
end;

function iv_utils_$create_lts_expression(
    l: lts_ptr_t): iv_expr_ptr_t; options(val_param);
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_lts;
  e^.lts := l;
  e^.canonical := true;
  iv_utils_$create_lts_expression := e;
end;

function iv_utils_$create_operand_expression(
    in o: opnd_t): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_operand;
  e^.opnd := o;
  e^.canonical := true;
  iv_utils_$create_operand_expression := e;
end;

{ create_transfer_expression, create_move_expression - an expression
  moving a between the register files, or within one.  0x239680,
  0x2396A0 (0x20 bytes each), no A5. }

function create_transfer_expression(
    a: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_transfer;
  e^.left := a;
  create_transfer_expression := e;
end;

function create_move_expression(
    a: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_move;
  e^.left := a;
  create_move_expression := e;
end;

{ iv_utils_$expression_is_zero - e is the constant 0.  0x2396C0, 0x1A
  bytes, no frame (internal: no A5). }

function iv_utils_$expression_is_zero(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
begin
  iv_utils_$expression_is_zero := (e^.kind = iv_value) and (e^.value = 0);
end;

{ forward: the canonicalizations call each other. }
function canonicalize_add_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function canonicalize_sub_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function canonicalize_mul_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function canonicalize_neg_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function canonicalize_rsub_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function iv_utils_$compare_expressions(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): boolean; options(val_param); forward;

{ iv_utils_$canonicalize_expression - e in canonical form (a sum of
  terms ordered by their compare nodes, constants folded), unless it is
  already.  0x2396DA, 0x74 bytes: a jump table by kind. }

function iv_utils_$canonicalize_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t;
begin
  if e <> nil then
    if not e^.canonical then
      case e^.kind of
        iv_neg:
          e := canonicalize_neg_expression(e);
        iv_add:
          e := canonicalize_add_expression(e);
        iv_sub:
          e := canonicalize_sub_expression(e);
        iv_mul:
          e := canonicalize_mul_expression(e);
        iv_rsub:
          e := canonicalize_rsub_expression(e);
        otherwise
          ;
      end;
  iv_utils_$canonicalize_expression := e;
end;

{ create_add_or_sub_expression - a + b when add, else a - b.  0x23974E,
  0x28 bytes, no A5: add a byte at (8,A6), a and b at (10,A6),
  (14,A6). }

function create_add_or_sub_expression(
    add: boolean;
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
begin
  if add then
    create_add_or_sub_expression := iv_utils_$create_add_expression(a, b)
  else
    create_add_or_sub_expression := iv_utils_$create_sub_expression(a, b);
end;

{ same_base_operand - a and b are displacement operands (arg block,
  stack frame, literal pool, XSB) of one kind and node.  0x239776, 0x66
  bytes, no A5. }

function same_base_operand(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  if (a^.kind = iv_operand) and (b^.kind = iv_operand) then
    if b^.opnd.h.kind = a^.opnd.h.kind then
      if a^.opnd.h.kind in [operand$displacement_arg_block..
                            operand$displacement_XSB_base] then
        if b^.opnd.link = a^.opnd.link then
          r := true;
  same_base_operand := r;
end;

{ operand_offset_difference - the constant a's displacement minus b's (0
  unless a is a displacement).  0x2397DC, 0x4C bytes, no A5: the
  constant expression's A0 left as the result (pattern 32). }

function operand_offset_difference(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  d: integer32;
begin
  if a^.opnd.h.kind in [operand$displacement_arg_block..
                        operand$displacement_XSB_base] then
    d := a^.opnd.value - b^.opnd.value
  else
    d := 0;
  operand_offset_difference := iv_utils_$create_value_expression(d);
end;

{ clean_up_additive_canonical_result - a canonical sum or difference
  simplified: + 0 dropped, - -x and + -x turned around, displacements
  of one base subtracted into a constant, a*x +- b*x and a*c +- b*(-c)
  made (a +- b)*x, x - x made 0 and x + x made 2*x (for multiples).
  0x239828, 0x37C bytes, no A5: the parameter given back through its
  own address. }

function clean_up_additive_canonical_result(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  r, a, b, d, t, t2: iv_expr_ptr_t;
begin
  r := e;
  if (e^.kind = iv_add) or (e^.kind = iv_sub) then begin
    a := e^.left;
    b := e^.right;
    if iv_utils_$expression_is_zero(b) then begin
      t := b;
      free_expression(t);
      free_expression(e);
      r := a;
    end
    else if b^.kind = iv_neg then begin
      a := b^.left;
      t := b;
      free_expression(t);
      if r^.kind = iv_add then
        r^.kind := iv_sub
      else
        r^.kind := iv_add;
      r^.right := a;
    end
    else if b^.kind = iv_operand then begin
      if (r^.kind = iv_sub) and same_base_operand(a, b) then begin
        a := operand_offset_difference(a, b);
        iv_utils_$delete_expression(e);
        r := a;
      end
      else if (r^.kind = iv_add) and (a^.kind = iv_neg)
          and same_base_operand(a^.left, b) then begin
        a := operand_offset_difference(b, a^.left);
        iv_utils_$delete_expression(e);
        r := a;
      end
      else begin
        d := nil;
        if (r^.kind = iv_sub) and (a^.kind = iv_add)
            and same_base_operand(a^.right, b) then
          d := operand_offset_difference(a^.right, b)
        else if (r^.kind = iv_add) and (a^.kind = iv_sub)
            and same_base_operand(b, a^.right) then
          d := operand_offset_difference(b, a^.right);
        if d <> nil then begin
          free_expression(e);
          r := iv_utils_$create_add_expression(a^.left, d);
          free_expression(a^.right);
          t := a;
          free_expression(t);
          t2 := b;
          free_expression(t2);
        end;
      end;
    end
    else if (b^.kind = iv_mul) and (a^.kind = iv_mul)
        and (b^.left^.kind <> iv_lts) and (a^.left^.kind <> iv_lts)
        and (b^.right^.kind = iv_lts) and (a^.right^.kind = iv_lts)
        and (b^.right^.lts = a^.right^.lts) then begin
      r := iv_utils_$create_mul_expression(
          iv_utils_$canonicalize_expression(
              create_add_or_sub_expression(r^.kind = iv_add, a^.left, b^.left)),
          a^.right);
      free_expression(b^.right);
      t := b;
      free_expression(t);
      t2 := a;
      free_expression(t2);
    end
    else if (b^.kind = iv_mul) and (a^.kind = iv_mul)
        and (b^.left^.kind <> iv_lts) and (a^.left^.kind <> iv_lts)
        and (a^.right^.kind = iv_value) and (b^.right^.kind = iv_value)
        and (-a^.right^.value = b^.right^.value) then begin
      r := iv_utils_$create_mul_expression(
          iv_utils_$canonicalize_expression(
              create_add_or_sub_expression(r^.kind <> iv_add, a^.left, b^.left)),
          a^.right);
      free_expression(b^.right);
      t := b;
      free_expression(t);
      t2 := a;
      free_expression(t2);
    end
    else if (b^.kind = iv_mul) and (a^.kind = iv_mul)
        and iv_utils_$compare_expressions(b, a) then
      if r^.kind = iv_sub then begin
        iv_utils_$delete_expression(r);
        r := iv_utils_$create_value_expression(0);
      end
      else begin
        t := a;
        iv_utils_$delete_expression(t);
        free_expression(r);
        r := iv_utils_$canonicalize_expression(
            iv_utils_$create_mul_expression(b, iv_utils_$create_value_expression(2)));
      end;
  end;
  clean_up_additive_canonical_result := r;
end;

{ canonicalize_add_expression - a sum in canonical form: the children
  canonical; when both have compare nodes the terms are merged in
  their order (the greater term's remainder added to the other side),
  equal constants folded and equal terms' multipliers added; a term
  with no compare node kept on the left.  0x239BA4, 0x3B8 bytes, no
  A5. }

function canonicalize_add_expression;
var
  r, l, rt, cr, cl, br, bl, rr, rl, t: iv_expr_ptr_t;
  ord_: integer32;
  pos, pr, pl: boolean;
  v: integer32;
begin
  if e^.canonical then begin
    canonicalize_add_expression := e;
    return;
  end;
  e^.left := iv_utils_$canonicalize_expression(e^.left);
  e^.right := iv_utils_$canonicalize_expression(e^.right);
  l := e^.left;
  rt := e^.right;
  r := e;
  if has_canonical_form(rt) then begin
    if has_canonical_form(l) then begin
      cr := get_canonical_compare_node(rt);
      cl := get_canonical_compare_node(l);
      br := get_canonical_base_node(rt);
      bl := get_canonical_base_node(l);
      rr := get_canonical_remaining_node(rt);
      rl := get_canonical_remaining_node(l);
      ord_ := order_expressions(cl, cr);
      if ord_ > 0 then begin
        if rr <> nil then begin
          free_expression(e);
          pos := canonical_base_node_is_positive(rt);
          t := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(l, rr));
          r := create_add_or_sub_expression(pos, t, br);
          if r^.left^.kind = iv_value then
            r := iv_utils_$canonicalize_expression(r);
        end;
      end
      else if ord_ < 0 then begin
        free_expression(e);
        if rl <> nil then
          r := iv_utils_$canonicalize_expression(
              create_add_or_sub_expression(canonical_base_node_is_positive(l),
                  iv_utils_$create_add_expression(rt, rl), bl))
        else
          r := iv_utils_$create_add_expression(rt, l);
      end
      else if cr^.kind = iv_value then begin
        free_expression(e);
        if canonical_base_node_is_positive(rt) then
          v := cr^.value
        else
          v := -cr^.value;
        if canonical_base_node_is_positive(l) then
          v := v + cl^.value
        else
          v := v - cl^.value;
        r := iv_utils_$create_value_expression(v);
        if rr <> nil then begin
          if rl <> nil then
            r := iv_utils_$create_add_expression(
                iv_utils_$canonicalize_expression(
                    iv_utils_$create_add_expression(rl, rr)), r)
          else
            r := iv_utils_$create_add_expression(rr, r);
        end
        else if rl <> nil then
          r := iv_utils_$create_add_expression(rl, r);
      end
      else begin
        free_expression(e);
        pr := canonical_base_node_is_positive(rt);
        pl := canonical_base_node_is_positive(l);
        r := iv_utils_$canonicalize_expression(
            iv_utils_$create_mul_expression(
                iv_utils_$create_add_expression(build_multiplier_from_base(bl, pl),
                                                build_multiplier_from_base(br, pr)),
                cr));
        if rr <> nil then begin
          if rl <> nil then
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                r, iv_utils_$create_add_expression(rr, rl)))
          else
            r := iv_utils_$canonicalize_expression(
                iv_utils_$create_add_expression(rr, r));
        end
        else if rl <> nil then
          r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(rl, r));
      end;
    end
    else begin
      br := get_canonical_base_node(rt);
      rr := get_canonical_remaining_node(rt);
      if rr <> nil then begin
        free_expression(e);
        pos := canonical_base_node_is_positive(rt);
        t := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(l, rr));
        r := create_add_or_sub_expression(pos, t, br);
      end;
    end;
  end
  else if has_canonical_form(l) then begin
    free_expression(e);
    bl := get_canonical_base_node(l);
    rl := get_canonical_remaining_node(l);
    if rl <> nil then begin
      pos := canonical_base_node_is_positive(l);
      t := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(rt, rl));
      r := create_add_or_sub_expression(pos, t, bl);
    end
    else
      r := iv_utils_$create_add_expression(rt, bl);
  end;
  r := clean_up_additive_canonical_result(r);
  r^.canonical := true;
  canonicalize_add_expression := r;
end;

{ canonicalize_sub_expression - a difference in canonical form, as a
  sum: the subtracted side negated.  0x239F5C, 0x418 bytes, no A5. }

function canonicalize_sub_expression;
var
  r, l, rt, cr, cl, br, bl, rr, rl, t, n: iv_expr_ptr_t;
  ord_: integer32;
  neg, p, pr, pl: boolean;
  v: integer32;
begin
  if e^.canonical then begin
    canonicalize_sub_expression := e;
    return;
  end;
  e^.left := iv_utils_$canonicalize_expression(e^.left);
  e^.right := iv_utils_$canonicalize_expression(e^.right);
  l := e^.left;
  rt := e^.right;
  r := e;
  if has_canonical_form(rt) then begin
    if has_canonical_form(l) then begin
      cr := get_canonical_compare_node(rt);
      cl := get_canonical_compare_node(l);
      br := get_canonical_base_node(rt);
      bl := get_canonical_base_node(l);
      rr := get_canonical_remaining_node(rt);
      rl := get_canonical_remaining_node(l);
      ord_ := order_expressions(cl, cr);
      if ord_ > 0 then begin
        if rr <> nil then begin
          free_expression(e);
          neg := not canonical_base_node_is_positive(rt);
          t := iv_utils_$canonicalize_expression(iv_utils_$create_sub_expression(l, rr));
          if neg then
            r := iv_utils_$create_add_expression(t, br)
          else
            r := iv_utils_$create_sub_expression(t, br);
          if r^.left^.kind = iv_value then
            r := iv_utils_$canonicalize_expression(r);
        end;
      end
      else if ord_ < 0 then begin
        free_expression(e);
        n := iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(rt));
        if rl <> nil then
          r := iv_utils_$canonicalize_expression(
              create_add_or_sub_expression(canonical_base_node_is_positive(l),
                  iv_utils_$create_add_expression(n, rl), bl))
        else
          r := iv_utils_$create_add_expression(n, l);
      end
      else if cr^.kind = iv_value then begin
        free_expression(e);
        if canonical_base_node_is_positive(rt) then
          v := -cr^.value
        else
          v := cr^.value;
        if canonical_base_node_is_positive(l) then
          v := v + cl^.value
        else
          v := v - cl^.value;
        r := iv_utils_$create_value_expression(v);
        if rr <> nil then begin
          if rl <> nil then
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                iv_utils_$create_sub_expression(rl, rr), r))
          else
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                iv_utils_$create_neg_expression(rr), r));
        end
        else if rl <> nil then
          r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(rl, r));
      end
      else begin
        free_expression(e);
        pr := canonical_base_node_is_positive(rt);
        pl := canonical_base_node_is_positive(l);
        r := iv_utils_$canonicalize_expression(
            iv_utils_$create_mul_expression(
                iv_utils_$create_sub_expression(build_multiplier_from_base(bl, pl),
                                                build_multiplier_from_base(br, pr)),
                cr));
        if rr <> nil then begin
          if rl <> nil then
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                r, iv_utils_$create_sub_expression(rl, rr)))
          else
            r := iv_utils_$canonicalize_expression(
                iv_utils_$create_sub_expression(r, rr));
        end
        else if rl <> nil then
          r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(r, rl));
      end;
    end
    else begin
      br := get_canonical_base_node(rt);
      rr := get_canonical_remaining_node(rt);
      if rr <> nil then begin
        free_expression(e);
        neg := not canonical_base_node_is_positive(rt);
        t := iv_utils_$canonicalize_expression(iv_utils_$create_sub_expression(l, rr));
        if neg then
          r := iv_utils_$create_add_expression(t, br)
        else
          r := iv_utils_$create_sub_expression(t, br);
      end;
    end;
  end
  else if has_canonical_form(l) then begin
    free_expression(e);
    bl := get_canonical_base_node(l);
    rl := get_canonical_remaining_node(l);
    if rl <> nil then begin
      p := canonical_base_node_is_positive(l);
      t := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
          iv_utils_$create_neg_expression(rt), rl));
      if p then
        r := iv_utils_$create_add_expression(t, bl)
      else
        r := iv_utils_$create_sub_expression(t, bl);
    end
    else
      r := iv_utils_$create_add_expression(
          iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(rt)), bl);
  end;
  r := clean_up_additive_canonical_result(r);
  r^.canonical := true;
  canonicalize_sub_expression := r;
end;

{ canonicalize_mul_expression - a product in canonical form: by 0, 1 and
  -1 simplified, constants folded, a constant moved inside a negation,
  a multiple or a canonical sum or difference; a constant on the left
  moved right.  0x23A374, 0x266 bytes, no A5: the product by M$MIS. }

function canonicalize_mul_expression;
var
  r, l, rt, t, d: iv_expr_ptr_t;
begin
  if e^.canonical then begin
    canonicalize_mul_expression := e;
    return;
  end;
  e^.left := iv_utils_$canonicalize_expression(e^.left);
  e^.right := iv_utils_$canonicalize_expression(e^.right);
  rt := e^.right;
  l := e^.left;
  r := e;
  if rt^.kind = iv_value then begin
    if rt^.value = 0 then begin
      free_expression(e);
      r := rt;
      t := l;
      iv_utils_$delete_expression(t);
    end
    else if rt^.value = 1 then begin
      free_expression(e);
      r := l;
      t := rt;
      iv_utils_$delete_expression(t);
    end
    else if rt^.value = -1 then begin
      free_expression(e);
      r := iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(l));
      t := rt;
      iv_utils_$delete_expression(t);
    end
    else
      case l^.kind of
        iv_value: begin
          free_expression(e);
          r := rt;
          r^.value := l^.value * r^.value;
          t := l;
          free_expression(t);
        end;
        iv_neg: begin
          free_expression(e);
          rt^.value := -rt^.value;
          r := iv_utils_$canonicalize_expression(
              iv_utils_$create_mul_expression(l^.left, rt));
          t := l;
          free_expression(t);
        end;
        iv_mul:
          if l^.right^.kind = iv_value then begin
            free_expression(e);
            r := iv_utils_$canonicalize_expression(iv_utils_$create_mul_expression(
                l^.left, iv_utils_$create_mul_expression(l^.right, rt)));
          end;
        iv_add:
          if has_canonical_form(l) then begin
            free_expression(e);
            d := iv_utils_$duplicate_expression(rt);
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                iv_utils_$create_mul_expression(l^.left, d),
                iv_utils_$create_mul_expression(l^.right, rt)));
          end;
        iv_sub:
          if has_canonical_form(l) then begin
            free_expression(e);
            d := iv_utils_$duplicate_expression(rt);
            r := iv_utils_$canonicalize_expression(iv_utils_$create_sub_expression(
                iv_utils_$create_mul_expression(l^.left, d),
                iv_utils_$create_mul_expression(l^.right, rt)));
          end;
        otherwise
          ;
      end;
  end
  else if l^.kind = iv_value then begin
    free_expression(e);
    r := canonicalize_mul_expression(iv_utils_$create_mul_expression(rt, l));
  end;
  r^.canonical := true;
  canonicalize_mul_expression := r;
end;

{ canonicalize_neg_expression - a negation in canonical form: a constant
  negated, - -x made x, -(a - b) made -a + b, -(a + b) made -a + -b, a
  multiple's constant negated.  0x23A5DA, 0x120 bytes, no A5. }

function canonicalize_neg_expression;
var
  r, l, t: iv_expr_ptr_t;
begin
  if e^.canonical then begin
    canonicalize_neg_expression := e;
    return;
  end;
  e^.left := iv_utils_$canonicalize_expression(e^.left);
  l := e^.left;
  r := e;
  case l^.kind of
    iv_value: begin
      l^.value := -l^.value;
      free_expression(e);
      r := l;
    end;
    iv_neg: begin
      free_expression(e);
      r := l^.left;
      t := l;
      free_expression(t);
    end;
    iv_sub: begin
      free_expression(e);
      r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
          iv_utils_$create_neg_expression(l^.left), l^.right));
      t := l;
      free_expression(t);
    end;
    iv_add: begin
      free_expression(e);
      r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
          iv_utils_$create_neg_expression(l^.left),
          iv_utils_$create_neg_expression(l^.right)));
      t := l;
      free_expression(t);
    end;
    iv_mul:
      if l^.right^.kind = iv_value then begin
        free_expression(e);
        l^.right^.value := -l^.right^.value;
        r := l;
      end;
    otherwise
      ;
  end;
  r^.canonical := true;
  canonicalize_neg_expression := r;
end;

{ canonicalize_rsub_expression - a reversed difference made a difference
  and canonicalized.  0x23A6FA, 0x42 bytes, no A5: the canonical
  form's A0 left as the result (pattern 32). }

function canonicalize_rsub_expression;
var
  l, r: iv_expr_ptr_t;
begin
  l := iv_utils_$canonicalize_expression(e^.left);
  r := iv_utils_$canonicalize_expression(e^.right);
  e^.kind := iv_sub;
  e^.left := r;
  e^.right := l;
  canonicalize_rsub_expression := iv_utils_$canonicalize_expression(e);
end;

{ iv_utils_$duplicate_expression - a copy of e (nil for nil).  0x23A73C,
  0xC0 bytes: recursive; the message ends in %. (as the image has it). }

function iv_utils_$duplicate_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t;
var
  r: iv_expr_ptr_t;
  k: integer32;
begin
  if e = nil then
    r := nil
  else if iv_nchildren[e^.kind] > 0 then begin
    r := alloc_expression;
    r^.kind := e^.kind;
    for k := 1 to iv_nchildren[e^.kind] do
      r^.child[k] := iv_utils_$duplicate_expression(e^.child[k]);
  end
  else
    case e^.kind of
      iv_value:
        r := iv_utils_$create_value_expression(e^.value);
      iv_operand:
        r := iv_utils_$create_operand_expression(e^.opnd);
      iv_lts:
        r := iv_utils_$create_lts_expression(e^.lts);
      otherwise
        bug_check('IV_$duplicate_expression: Unknown expression type%.');
    end;
  iv_utils_$duplicate_expression := r;
end;

{ iv_utils_$compare_expressions - a and b are the same expression (both
  nil, or of one kind with equal children, values, segments or
  operands: displacements by node and value, like registers by
  segment).  0x23A830, 0xEE bytes: recursive. }

function iv_utils_$compare_expressions;
var
  r: boolean;
  k: integer32;
begin
  r := false;
  if (a = nil) and (b = nil) then
    r := true
  else if (a <> nil) and (b <> nil) then
    if a^.kind = b^.kind then
      if iv_nchildren[a^.kind] > 0 then begin
        for k := 1 to iv_nchildren[a^.kind] do
          if not iv_utils_$compare_expressions(a^.child[k], b^.child[k]) then begin
            iv_utils_$compare_expressions := false;
            return;
          end;
        r := true;
      end
      else
        case a^.kind of
          iv_value:
            r := a^.value = b^.value;
          iv_lts:
            r := a^.lts = b^.lts;
          iv_operand:
            if a^.opnd.h.kind = b^.opnd.h.kind then
              case a^.opnd.h.kind of
                operand$displacement_arg_block, operand$displacement_stack_frame,
                operand$displacement_literal_pool:
                  r := (a^.opnd.link = b^.opnd.link)
                       and (a^.opnd.value = b^.opnd.value);
                operand$ip_reg_like, operand$fp_reg_like,
                operand$fp_reg_pair_like:
                  r := a^.opnd.lts = b^.opnd.lts;
                otherwise
                  ;
              end;
          otherwise
            ;
        end;
  iv_utils_$compare_expressions := r;
end;

{ propagate_up_cost - the cost of computing e in each register file (1
  integer, 2 floating): a transfer (1) unless its file is chosen, a
  constant integer, an operand floating when it is a floating register,
  else the children's sums, each then at most the other's plus a
  transfer.  0x23A956, 0x176 bytes, no A5: recursive. }

procedure propagate_up_cost(
    var cost: iv_cost_t;
    e: iv_expr_ptr_t); options(val_param); internal;
var
  k, j: integer;
  n: integer32;
  sub: iv_cost_t;
begin
  for k := 1 to 2 do
    cost[k] := 0;
  if e^.rclass <> 0 then begin
    for k := 1 to 2 do
      if k <> e^.rclass then
        cost[k] := 1;
  end
  else if e^.kind = iv_value then begin
    for k := 1 to 2 do
      if k <> 1 then
        cost[k] := 1;
  end
  else if e^.kind = iv_operand then begin
    if e^.opnd.h.kind in [operand$fp_reg, operand$fp_reg_physical,
                          operand$fp_reg_like] then begin
      for k := 1 to 2 do
        if k <> 2 then
          cost[k] := 1;
    end
    else
      for k := 1 to 2 do
        if k <> 1 then
          cost[k] := 1;
  end
  else if iv_nchildren[e^.kind] > 0 then begin
    for n := 1 to iv_nchildren[e^.kind] do begin
      propagate_up_cost(sub, e^.child[n]);
      for k := 1 to 2 do
        cost[k] := cost[k] + sub[k];
    end;
    for k := 1 to 2 do
      for j := 1 to 2 do
        if cost[k] > cost[j] + 1 then
          if j <> k then
            cost[k] := cost[j] + 1;
  end;
end;

{ can_encode_as_register - e can be an instruction's register operand:
  not a constant, and an operand only when it is a like register (or a
  case jump base).  0x23AACC, 0x42 bytes, no A5. }

function can_encode_as_register(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
begin
  if e^.kind = iv_value then
    can_encode_as_register := false
  else if e^.kind = iv_operand then
    can_encode_as_register := e^.opnd.h.kind in [operand$ip_reg_like,
        operand$fp_reg_like, operand$fp_reg_pair_like, operand$case_jump_base]
  else
    can_encode_as_register := true;
end;

{ first_operand_can_change - the child that becomes e's operand 1 can be
  a register.  0x23AB0E, 0x6A bytes, no A5 (iv's tables through the
  caller's A5). }

function first_operand_can_change(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
var
  k: integer32;
begin
  first_operand_can_change := false;
  for k := 1 to iv_nchildren[e^.kind] do
    if iv_opnd_pos[e^.kind, k] = 1 then begin
      first_operand_can_change := can_encode_as_register(e^.child[k]);
      return;
    end;
end;

{ propagate_down_type - e (and its children) computed in register file
  t: a multiply by a power of 2 in integers made a shift; the children's
  file the cheaper (propagate_up_cost); in integers a child that cannot
  be a register made an immediate (the commuted instruction's when only
  operand 1 takes one), a move or a load; a transfer added where the
  files differ, a constant in floating registers loaded, an operand
  moved and transferred.  0x23AB78, 0x35C bytes, no A5: recursive. }

function propagate_down_type(
    e: iv_expr_ptr_t;
    t: integer): iv_expr_ptr_t; options(val_param); internal;
label
  1, 2;
var
  best, k: integer;
  n, b: integer32;
  pos: integer32;
  cost, sub: iv_cost_t;
  c, x: iv_expr_ptr_t;
begin
  if e = nil then
    goto 2;
  if e^.rclass = t then
    goto 2;
  if e^.rclass <> 0 then
    e := create_transfer_expression(e)
  else begin
    if (e^.kind = iv_mul) and (t = 1) then
      for b := 0 to 31 do
        if lshft(1, b) = e^.right^.value then begin
          e^.kind := iv_shift;
          e^.right^.value := b;
          exit;
        end;
    if iv_nchildren[e^.kind] <= 0 then
      goto 1;
    best := t;
    if 1 < iv_nchildren[e^.kind] then begin
      for k := 1 to 2 do
        cost[k] := 0;
      for n := 1 to iv_nchildren[e^.kind] do begin
        propagate_up_cost(sub, e^.child[n]);
        for k := 1 to 2 do
          cost[k] := cost[k] + sub[k];
      end;
      for k := 1 to 2 do
        if cost[best] > cost[k] + 1 then
          best := k;
    end;
    for n := 1 to iv_nchildren[e^.kind] do
      e^.child[n] := propagate_down_type(e^.child[n], best);
    if (e^.kind = iv_mul) and (best = 1) then
      for b := 0 to 31 do
        if lshft(1, b) = e^.right^.value then begin
          e^.kind := iv_shift;
          e^.right^.value := b;
          exit;
        end;
    if best = 1 then
      for n := 1 to iv_nchildren[e^.kind] do begin
        pos := iv_opnd_pos[e^.kind, n];
        if not can_encode_as_register(e^.child[n]) then begin
          c := e^.child[n];
          if c^.kind = iv_value then begin
            if not lir_$can_encode_as_immediate_operand(c^.value,
                       iv_opc[1, e^.kind], pos) then
              if (pos <> 1) and (iv_commuted[e^.kind] <> 0)
                  and first_operand_can_change(e)
                  and lir_$can_encode_as_immediate_operand(c^.value,
                          iv_opc[1, iv_commuted[e^.kind]], 1) then begin
                x := e^.right;
                e^.right := e^.left;
                e^.left := x;
                e^.kind := iv_commuted[e^.kind];
              end
              else if lir_$can_encode_as_immediate_operand(c^.value,
                          ord(opc$move), 1) then begin
                e^.child[n] := create_move_expression(e^.child[n]);
                e^.child[n]^.rclass := 1;
              end
              else
                e^.child[n]^.kind := iv_load;
          end
          else if pos <> 1 then
            if (iv_commuted[e^.kind] <> 0) and first_operand_can_change(e) then begin
              x := e^.right;
              e^.right := e^.left;
              e^.left := x;
              e^.kind := iv_commuted[e^.kind];
            end
            else begin
              e^.child[n] := create_move_expression(e^.child[n]);
              e^.child[n]^.rclass := 1;
            end;
        end;
      end;
    e^.rclass := best;
    if best <> t then
      e := create_transfer_expression(e);
  end;
1:
  e^.rclass := t;
  if (e^.kind = iv_value) and (t <> 1) then
    e^.kind := iv_load
  else if (e^.kind = iv_operand) and (t <> 1) then begin
    e^.rclass := 1;
    e := create_move_expression(e);
    e^.rclass := 1;
    e := create_transfer_expression(e);
    e^.rclass := t;
  end;
2:
  propagate_down_type := e;
end;

{ elaborate_expression - e's register files chosen from the leaves up:
  a multiple by a power of 2 integer, by a negative one negated; the
  children elaborated in the file the kind wants (iv_elab_class: a
  segment's its definition's operand kind); a + -b, -a + b and a - -b
  turned into differences and sums; then e in that file, and when
  force in t (and a multiple in integers).  0x23AED4, 0x1AA bytes, no
  A5: recursive. }

function elaborate_expression(
    e: iv_expr_ptr_t;
    t: integer;
    force: boolean): iv_expr_ptr_t; options(val_param); internal;
var
  w, cls: integer;
  v, n: integer32;
  x: iv_expr_ptr_t;
begin
  w := 0;
  cls := iv_elab_class[e^.kind];
  if e^.kind = iv_mul then
    if e^.right^.kind = iv_value then begin
      v := e^.right^.value;
      if v > 0 then begin
        if (~(v - 1) & v) = v then
          cls := 1;
      end
      else if v < 0 then
        if (-v & v) = -v then begin
          e^.right^.value := -v;
          e := iv_utils_$create_neg_expression(e);
          cls := iv_elab_class[e^.kind];
        end;
    end;
  case cls of
    3:
      w := 1;
    4:
      w := 2;
    2:
      w := ord(e^.lts^.refs^.h.kind);
    otherwise
      ;
  end;
  for n := 1 to iv_nchildren[e^.kind] do
    e^.child[n] := elaborate_expression(e^.child[n], w, w <> 0);
  if e^.kind = iv_add then begin
    if e^.left^.kind = iv_neg then begin
      x := e^.left^.left;
      free_expression(e^.left);
      e^.kind := iv_sub;
      e^.left := e^.right;
      e^.right := x;
    end
    else if e^.right^.kind = iv_neg then begin
      x := e^.right^.left;
      free_expression(e^.right);
      e^.kind := iv_sub;
      e^.right := x;
    end;
  end
  else if e^.kind = iv_sub then
    if e^.right^.kind = iv_neg then begin
      x := e^.right^.left;
      free_expression(e^.right);
      e^.kind := iv_add;
      e^.right := x;
    end;
  if w <> 0 then
    e := propagate_down_type(e, w);
  if force then
    if (t <> w) or ((e^.kind = iv_mul) and (t = 1)) then
      e := propagate_down_type(e, t);
  elaborate_expression := e;
end;

{ iv_utils_$elaborate_expression - e elaborated in rclass, a constant
  left as the immediate operand pos of opc when it encodes so, else
  moved (or loaded), an operand that cannot be a register moved.
  0x23B07E, 0xA6 bytes: pos passed on as a longword. }

function iv_utils_$elaborate_expression;
var
  r: iv_expr_ptr_t;
  p: integer32;
begin
  r := elaborate_expression(e, rclass, true);
  p := pos;
  if r^.kind = iv_value then begin
    if not lir_$can_encode_as_immediate_operand(r^.value, opc, p) then
      if lir_$can_encode_as_immediate_operand(r^.value, ord(opc$move),
                                              1) then begin
        r := create_move_expression(r);
        r^.rclass := 1;
      end
      else
        r^.kind := iv_load;
  end
  else if r^.kind = iv_operand then
    if not can_encode_as_register(r) then begin
      r := create_move_expression(r);
      r^.rclass := 1;
    end;
  iv_utils_$elaborate_expression := r;
end;

{ find_last_instruction - the block's last instruction, or the first of
  the branches and jumps (classes 1, 5, 6) just before it.  0x23B124,
  0x46 bytes, no A5: `moveq #98; btst' of the opcode's class. }

function find_last_instruction(
    bb: bb_ptr_t): instr_ptr_t; options(val_param); internal;
var
  i, p: instr_ptr_t;
begin
  i := bb^.last;
  p := i^.prev;
  while p <> nil do begin
    if not (instruction_attributes[p^.opc].class
            in [class$branch, class$fp_branch, class$jump]) then
      exit;
    i := p;
    p := p^.prev;
  end;
  find_last_instruction := i;
end;

{ add_operand_to_segment - operand o made a reference of kind to
  segment s with properties rrp (also its live range's), chained on
  s's references: last when it means to modify, after the definition
  when it reads and the first reference writes, else first.  0x23B16A,
  0x8C bytes, no A5. }

procedure add_operand_to_segment(
    o: opnd_ptr_t;
    s: lts_ptr_t;
    rrp: integer;
    kind: integer); options(val_param); internal;
var
  p: ^opnd_ptr_t;
begin
  s^.rrp := rrp$set_t(integer(s^.rrp) ! rrp);
  opnd_bytes_ptr_t(o)^.rrp := rrp;
  o^.h.count := 0;
  opnd_bytes_ptr_t(o)^.b3 := (opnd_bytes_ptr_t(o)^.b3 & 16#E0) ! kind;
  o^.lts := s;
  o^.link := nil;
  s^.lr^.rrp := rrp$set_t(integer(s^.lr^.rrp) ! rrp);
  p := addr(s^.refs);
  if (rrp & 16#20) <> 0 then begin
    while p^ <> nil do
      p := addr(p^^.link);
  end
  else if (rrp & 16#10) <> 0 then
    if p^ <> nil then
      if (opnd_bytes_ptr_t(p^)^.rrp & 12) <> 0 then
        p := addr(p^^.link);
  o^.link := p^;
  p^ := o;
end;

{ create_operand_from_elaborated_expression - operand o made what the
  elaborated expression e computes, for an instruction in block use_bb:
  a segment's value read (from the live range's last segment in the
  block, or an exposed one with a birthpoint made for it), an operand
  copied (keeping o's number), a constant an immediate; an operation an
  instruction (after at, else before code_bb's closing branches)
  computing a new live range, its operands made recursively (a child
  that cannot be the register an operand other than 1 needs, or an
  operand as operand 1 of other than an add or move, moved first; a
  shift by a constant the operand's scale where the opcode takes it;
  a commutative operation's children exchanged for that); a constant
  loaded from the literal pool.  0x23B1F6, 0x680 bytes, no A5:
  recursive; the opcode from iv_opc by e's register file and kind. }

procedure create_operand_from_elaborated_expression(
    o: opnd_ptr_t;
    var e: iv_expr_ptr_t;
    at: instr_ptr_t;
    use_bb: bb_ptr_t;
    code_bb: bb_ptr_t); options(val_param); internal;
var
  s, d, f: lts_ptr_t;
  lr: lr_ptr_t;
  prev: lts_ptr_t;
  created: boolean;
  n, k, pos, a, b: integer32;
  opc: integer;
  shift: integer32;
  c, x: iv_expr_ptr_t;
  i: instr_ptr_t;
  r: opnd_ptr_t;
begin
  case e^.kind of
    iv_lts: begin
      d := e^.lts;
      created := false;
      lr := d^.lr;
      if use_bb = code_bb then begin
        s := utils_$find_last_lts_in_bb(lr, use_bb, prev);
        if s = nil then begin
          s := utils_$get_final_lts(lr, use_bb, created);
          utils_$put_lts_on_exposed_list(s);
        end;
      end
      else
        s := utils_$get_exposed_lts(lr, use_bb, created);
      if created then begin
        if d^.f2.exposed then
          if d^.l44 <> nil then
            d := d^.l44;
        if not d^.f2.final then
          if use_bb <> d^.bb then
            utils_$put_lts_on_final_list(d);
        utils_$add_birthpoint(d, use_bb, true);
      end;
      add_operand_to_segment(o, s, 16, e^.rclass);
    end;
    iv_operand: begin
      k := o^.h.num;
      o^ := e^.opnd;
      o^.h.num := k;
    end;
    iv_value: begin
      o^.h.kind := operand$immediate;
      o^.value := e^.value;
      o^.link := nil;
      opnd_bytes_ptr_t(o)^.rrp := 16;
      o^.h.bytes := 4;
      o^.h.count := 0;
    end;
    otherwise begin
      n := iv_nchildren[e^.kind];
      opc := iv_opc[e^.rclass, e^.kind];
      if at = nil then
        at := find_last_instruction(code_bb);
      for k := 1 to n do begin
        c := e^.child[k];
        if (iv_opnd_pos[e^.kind, k] <> 1) and not can_encode_as_register(c)
            and (e^.kind <> iv_shift) then begin
          c := create_move_expression(c);
          c^.rclass := c^.left^.rclass;
          e^.child[k] := c;
        end
        else if (iv_opnd_pos[e^.kind, k] = 1) and (e^.kind <> iv_add)
            and (c^.kind = iv_operand) and (e^.kind <> iv_move) then begin
          c := create_move_expression(c);
          c^.rclass := c^.left^.rclass;
          e^.child[k] := c;
        end;
      end;
      if n = 2 then
        if iv_commuted[e^.kind] <> 0 then begin
          a := iv_opnd_pos[e^.kind, 1];
          b := iv_opnd_pos[e^.kind, 2];
          if can_encode_as_register(e^.child[a]) then begin
            c := e^.child[a];
            if not ((c^.kind = iv_shift) and (c^.right^.kind = iv_value)
                    and tm_utils_$can_convert_to_ip_reg_operand(opc, 1,
                            c^.right^.value)
                    and can_encode_as_register(c^.left)) then begin
              c := e^.child[b];
              if c^.kind = iv_shift then
                if c^.right^.kind = iv_value then
                  if tm_utils_$can_convert_to_ip_reg_operand(
                         iv_opc[e^.rclass, iv_commuted[e^.kind]], 1,
                         c^.right^.value) then
                    if can_encode_as_register(c^.left) then begin
                      x := e^.left;
                      e^.left := e^.right;
                      e^.right := x;
                      e^.kind := iv_commuted[e^.kind];
                      opc := iv_opc[e^.rclass, e^.kind];
                    end;
            end;
          end;
        end;
      i := lir_$optimizer_new_instruction(at, opc, false);
      i^.h.preference := false;
      for k := 1 to i^.h.nopnds do
        i^.opnds[k].h.num := k;
      for k := 1 to n do begin
        pos := iv_opnd_pos[e^.kind, k];
        shift := 0;
        c := e^.child[k];
        if c^.kind = iv_shift then
          if c^.right^.kind = iv_value then
            if tm_utils_$can_convert_to_ip_reg_operand(opc, pos,
                                                       c^.right^.value) then
              if can_encode_as_register(c^.left) then begin
                shift := c^.right^.value;
                c := c^.left;
              end;
        create_operand_from_elaborated_expression(addr(i^.opnds[pos]), c, i,
                                                  code_bb, code_bb);
        if shift <> 0 then
          i^.opnds[pos].h.count := shift;
      end;
      if e^.kind = iv_load then begin
        discard(sym_$reformat_literal_operand(smcontk(linteger_ob, e^.value),
                                              4, 0,
                                              addr(i^.opnds[1])));
        opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
        i^.opnds[1].h.kind := operand$displacement_literal_pool;
        i^.opnds[1].h.bytes := 4;
        opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
        i^.opnds[2].h.kind := operand$ip_reg_like;
        i^.opnds[2].lts := lir_main_c48;     { a segment (lir_main +0xC48) }
        i^.h.may_generate_an_exception := false;
        n := 2;
      end;
      r := addr(i^.opnds[n + 1]);
      opnd_bytes_ptr_t(r)^.rrp := 8;
      opnd_bytes_ptr_t(r)^.b3 := (opnd_bytes_ptr_t(r)^.b3 & 16#E0) ! e^.rclass;
      opnd_bytes_ptr_t(o)^.rrp := 16;
      opnd_bytes_ptr_t(o)^.b3 := (opnd_bytes_ptr_t(o)^.b3 & 16#E0) ! e^.rclass;
      lr := lir_$new_live_range_for_kind(e^.rclass);
      lr^.rrp := rrp$set_t(integer(lr^.rrp) ! 24);
      if use_bb = code_bb then begin
        lir_utils_$add_lts_to_lr(24, lr, code_bb, s);
        r^.lts := s;
        r^.link := o;
        o^.lts := s;
        o^.link := nil;
        s^.refs := r;
      end
      else begin
        bv_$make_live_range_complex(iv_rtn, lr);
        f := utils_$get_final_lts(lr, code_bb, created);
        s := utils_$get_exposed_lts(lr, use_bb, created);
        o^.lts := s;
        o^.link := nil;
        s^.refs := o;
        s^.rrp := s^.rrp + [rrp$read];
        r^.lts := f;
        r^.link := nil;
        f^.refs := r;
        f^.rrp := f^.rrp + [rrp$write];
        utils_$add_birthpoint(f, use_bb, true);
      end;
    end;
  end;
end;

{ iv_utils_$create_operand_from_expression - operand o (of an
  instruction in its block) made the value of a copy of e elaborated in
  register file rclass for its place, the instructions put after at
  in code_bb.  0x23B876, 0x78 bytes. }

procedure iv_utils_$create_operand_from_expression;
var
  i: instr_ptr_t;
  r: iv_expr_ptr_t;
begin
  i := utils_ins_$operands_instruction(o);
  r := iv_utils_$elaborate_expression(iv_utils_$duplicate_expression(e),
                                      rclass, i^.opc, o^.h.num);
  create_operand_from_elaborated_expression(o, r, at, i^.bb, code_bb);
  iv_utils_$delete_expression(r);
end;

{ iv_utils_$live_range_from_elaborated_expression - e as an operand: a
  segment its live range (kind 1), an operand itself (2), a constant
  its value (3); an operation an instruction made at the head of bb
  writing a new live range (kind 1), its operands filled from its
  children (a live range in their +8; an operand copied takes the
  child's number k, though it goes to slot pos), a constant loaded from
  the literal pool.  0x23B8EE, 0x2C0 bytes: recursive. }

procedure iv_utils_$live_range_from_elaborated_expression;
var
  n, k, pos: integer32;
  opc: integer;
  i: instr_ptr_t;
  p: opnd_ptr_t;
  clr: lr_ptr_t;
  cvalue: integer32;
  cop: opnd_ptr_t;
  ckind: integer;
begin
  case e^.kind of
    iv_lts:
      lr := e^.lts^.lr;
    iv_operand: begin
      op := addr(e^.opnd);
      kind := 2;
      return;
    end;
    iv_value: begin
      value := e^.value;
      kind := 3;
      return;
    end;
    otherwise begin
      n := iv_nchildren[e^.kind];
      opc := iv_opc[e^.rclass, e^.kind];
      i := lir_$optimizer_new_instruction(bb^.first, opc, false);
      i^.h.preference := false;
      for k := 1 to i^.h.nopnds do
        i^.opnds[k].h.num := k;
      for k := 1 to n do begin
        pos := iv_opnd_pos[e^.kind, k];
        p := addr(i^.opnds[pos]);
        opnd_bytes_ptr_t(p)^.rrp := 16;
        iv_utils_$live_range_from_elaborated_expression(e^.child[k], bb, clr,
                                                        cvalue, cop, ckind);
        case ckind of
          1: begin
            opnd_bytes_ptr_t(p)^.b3 := (opnd_bytes_ptr_t(p)^.b3 & 16#E0)
                                       ! e^.child[k]^.rclass;
            p^.ptr := clr;
          end;
          3: begin
            p^.h.kind := operand$immediate;
            p^.value := cvalue;
            p^.link := nil;
            p^.h.bytes := 4;
            p^.h.count := 0;
          end;
          2: begin
            p^ := cop^;
            p^.h.num := k;
          end;
          otherwise
            ;
        end;
      end;
      if e^.kind = iv_load then begin
        discard(sym_$reformat_literal_operand(smcontk(linteger_ob, e^.value),
                                              4, 0,
                                              addr(i^.opnds[1])));
        opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
        i^.opnds[1].h.kind := operand$displacement_literal_pool;
        i^.opnds[1].h.bytes := 4;
        opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
        i^.opnds[2].h.kind := operand$ip_reg_like;
        i^.opnds[2].lts := lir_main_c48;     { a segment (lir_main +0xC48) }
        i^.h.may_generate_an_exception := false;
        n := 2;
      end;
      opnd_bytes_ptr_t(addr(i^.opnds[n + 1]))^.rrp := 8;
      opnd_bytes_ptr_t(addr(i^.opnds[n + 1]))^.b3 :=
          (opnd_bytes_ptr_t(addr(i^.opnds[n + 1]))^.b3 & 16#E0) ! e^.rclass;
      clr := lir_$new_live_range_for_kind(e^.rclass);
      i^.opnds[n + 1].ptr := clr;
      lr := clr;
    end;
  end;
  kind := 1;
end;

{ increments_are_equal - both induction lts' increments are known and
  the same.  0x23BBAE, 0x3A bytes, no A5. }

function increments_are_equal(
    a: iv_lts_ptr_t;
    b: iv_lts_ptr_t): boolean; options(val_param); internal;
begin
  increments_are_equal := false;
  if a^.h.known then
    if b^.h.known then
      increments_are_equal := iv_utils_$compare_expressions(a^.incr, b^.incr);
end;

{ create_induction_lts - segment s's induction lts of kind for variable
  v (kinds 1..3 put first on v's list; a kind 2 of a secondary variable
  made 3), its increment known as v's.  0x23BBE8, 0x6C bytes, no A5:
  `moveq #14; btst kind' for kinds 1..3; frame 8:w 10:l 14:l
  (pattern 125). }

function create_induction_lts(
    kind: integer;
    s: lts_ptr_t;
    v: iv_var_ptr_t): iv_lts_ptr_t; options(val_param); internal;
var
  l: iv_lts_ptr_t;
begin
  l := alloc_induction_lts;
  l^.h.kind := kind;
  l^.ivar := v;
  l^.lts := s;
  if kind in [1..3] then begin
    l^.next := v^.ltss;
    v^.ltss := l;
  end;
  if kind = 2 then
    if v^.parent <> nil then
      l^.h.kind := 3;
  l^.h.known := v^.f48.known;
  s^.l24 := integer32(l);
  create_induction_lts := l;
end;

{ free_induction_lts - l put on the free list.  0x23BC54, 0x10 bytes,
  no frame. }

procedure free_induction_lts(
    l: iv_lts_ptr_t); options(val_param); internal;
begin
  l^.next := iv_free_lts;
  iv_free_lts := l;
end;

{ iv_utils_$delete_induction_lts - l given back: a kind 1..3's
  expressions deleted and l taken off its variable's list, a kind 4's
  off its induction expression's; its segment's +24 cleared when it
  points to l.  The caller's pointer is not cleared.  0x23BC64, 0xC0
  bytes (loads A5): a jump table by kind - 1. }

procedure iv_utils_$delete_induction_lts(
    var lp: iv_lts_ptr_t);
var
  l, x: iv_lts_ptr_t;
  p: ^iv_lts_ptr_t;
begin
  l := lp;
  if l = nil then
    return;
  case l^.h.kind of
    1, 2, 3: begin
      iv_utils_$delete_expression(l^.incr);
      iv_utils_$delete_expression(l^.step);
      p := addr(l^.ivar^.ltss);
      x := p^;
      while x <> nil do begin
        if x = l then begin
          p^ := x^.next;
          exit;
        end;
        p := addr(x^.next);
        x := x^.next;
      end;
    end;
    4: begin
      p := addr(l^.iexpr^.ltss);
      x := p^;
      while x <> nil do begin
        if x = l then begin
          p^ := x^.next;
          exit;
        end;
        p := addr(x^.next);
        x := x^.next;
      end;
    end;
    otherwise
      ;
  end;
  if l^.lts <> nil then begin
    if iv_lts_ptr_t(l^.lts^.l24) = l then
      l^.lts^.l24 := 0;
  end;
  l^.lts := nil;
  free_induction_lts(l);
end;

{ free_induction_addr - a put on the free list.  0x23BD24, 0x10 bytes,
  no frame. }

procedure free_induction_addr(
    a: iv_addr_ptr_t); options(val_param); internal;
begin
  a^.next := iv_free_addr;
  iv_free_addr := a;
end;

{ iv_utils_$delete_induction_addr - a taken off its induction
  expression's list (which must hold it: no nil test) and given back.
  0x23BD34, 0x3C bytes, no A5. }

procedure iv_utils_$delete_induction_addr(
    a: iv_addr_ptr_t); options(val_param); internal;
var
  p: ^iv_addr_ptr_t;
  x: iv_addr_ptr_t;
begin
  p := addr(a^.iexpr^.addrs);
  x := p^;
  while x <> a do begin
    p := addr(x^.next);
    x := x^.next;
  end;
  p^ := x^.next;
  free_induction_addr(a);
end;

{ free_induction_expr - x put on the free list.  0x23BD70, 0x10 bytes,
  no frame. }

procedure free_induction_expr(
    x: iv_iexpr_ptr_t); options(val_param); internal;
begin
  x^.next := iv_free_iexpr;
  iv_free_iexpr := x;
end;

{ create_induction_expr - an induction expression of e put first on
  class c's list, numbered one more than the one before it (1 for the
  first).  0x23BD80, 0x4C bytes, no A5. }

function create_induction_expr(
    c: iv_class_ptr_t;
    e: iv_expr_ptr_t): iv_iexpr_ptr_t; options(val_param); internal;
var
  x: iv_iexpr_ptr_t;
begin
  x := alloc_induction_expr;
  if c^.iexprs = nil then
    x^.num := 1
  else
    x^.num := c^.iexprs^.num + 1;
  x^.class := c;
  x^.expr := e;
  x^.next := c^.iexprs;
  c^.iexprs := x;
  create_induction_expr := x;
end;

{ create_induction_class - a class of variable v put last on v's list,
  numbered one more than the last (1 for the first).  0x23BDCC, 0x58
  bytes, no A5: frame 8:w 10:l. }

function create_induction_class(
    w16: integer;
    v: iv_var_ptr_t): iv_class_ptr_t; options(val_param); internal;
var
  c: iv_class_ptr_t;
begin
  c := alloc_induction_class;
  c^.ivar := v;
  c^.w16 := w16;
  c^.prev := v^.classes_last;
  if v^.classes = nil then begin
    v^.classes := c;
    c^.num := 1;
  end
  else begin
    v^.classes_last^.next := c;
    c^.num := v^.classes_last^.num + 1;
  end;
  v^.classes_last := c;
  create_induction_class := c;
end;

{ free_induction_class - c put on the free list.  0x23BE24, 0x10 bytes,
  no frame. }

procedure free_induction_class(
    c: iv_class_ptr_t); options(val_param); internal;
begin
  c^.next := iv_free_class;
  iv_free_class := c;
end;

{ create_induction_variable - a variable of kind for segment s in the
  loop iv_head: a primary (no parent) put last on iv_vars, a secondary
  last on its parent's children (its known flag the parent's); s given
  a kind 1 induction lts with a zero increment, known.  0x23BE34, 0xD0
  bytes, no A5. }

function create_induction_variable(
    s: lts_ptr_t;
    parent: iv_var_ptr_t;
    kind: integer): iv_var_ptr_t; options(val_param); internal;
var
  v: iv_var_ptr_t;
  l: iv_lts_ptr_t;
begin
  v := alloc_induction_variable;
  v^.lts := s;
  v^.head := iv_head;
  v^.parent := parent;
  v^.f48.kind := kind;
  if parent = nil then begin
    if iv_vars = nil then
      iv_vars := v
    else
      iv_vars_last^.next := v;
    iv_vars_last := v;
  end;
  if s <> nil then begin
    l := create_induction_lts(1, s, v);
    l^.incr := iv_utils_$create_value_expression(0);
    l^.step := nil;
    l^.h.known := true;
  end;
  if parent <> nil then begin
    v^.f48.known := parent^.f48.known;
    if parent^.l54 = nil then
      parent^.l54 := v
    else begin
      v^.l54 := parent^.children_last;
      parent^.children_last^.next := v;
    end;
    parent^.children_last := v;
  end;
  create_induction_variable := v;
end;

{ free_induction_variable - v put on the free list.  0x23BF04, 0x10
  bytes, no frame. }

procedure free_induction_variable(
    v: iv_var_ptr_t); options(val_param); internal;
begin
  v^.next := iv_free_var;
  iv_free_var := v;
end;

{ iv_utils_$delete_induction_expr - x's instantiations and address modes
  deleted, its expression, and x taken off its class's list and given
  back.  0x23BF14, 0x9C bytes, no A5. }

procedure iv_utils_$delete_induction_expr(
    x: iv_iexpr_ptr_t); options(val_param); internal;
var
  l, ln, t: iv_lts_ptr_t;
  a, an: iv_addr_ptr_t;
  p: ^iv_iexpr_ptr_t;
  y: iv_iexpr_ptr_t;
begin
  l := x^.ltss;
  while l <> nil do begin
    ln := l^.next;
    t := l;
    iv_utils_$delete_induction_lts(t);
    l := ln;
  end;
  a := x^.addrs;
  while a <> nil do begin
    an := a^.next;
    iv_utils_$delete_induction_addr(a);
    a := an;
  end;
  if x^.expr <> nil then
    iv_utils_$delete_expression(x^.expr);
  p := addr(x^.class^.iexprs);
  y := p^;
  while y <> nil do begin
    if y = x then begin
      p^ := y^.next;
      exit;
    end;
    p := addr(y^.next);
    y := y^.next;
  end;
  free_induction_expr(x);
end;

{ iv_utils_$delete_induction_class - c's induction expressions deleted,
  c taken off its variable's list and given back.  0x23BFB0, 0x78
  bytes, no A5. }

procedure iv_utils_$delete_induction_class(
    c: iv_class_ptr_t); options(val_param); internal;
var
  x, xn: iv_iexpr_ptr_t;
  v: iv_var_ptr_t;
begin
  x := c^.iexprs;
  while x <> nil do begin
    xn := x^.next;
    iv_utils_$delete_induction_expr(x);
    x := xn;
  end;
  v := c^.ivar;
  if c^.next <> nil then
    c^.next^.prev := c^.prev;
  if c^.prev <> nil then
    c^.prev^.next := c^.next;
  if v^.classes = c then
    v^.classes := c^.next;
  if v^.classes_last = c then
    v^.classes_last := c^.prev;
  free_induction_class(c);
end;

{ iv_utils_$delete_induction_variable - v's classes and induction lts
  deleted; a secondary taken off its parent's children, a primary's
  children deleted and it taken off iv_vars; v given back.  0x23C028,
  0xEA bytes, no A5: recursive. }

procedure iv_utils_$delete_induction_variable(
    v: iv_var_ptr_t); options(val_param); internal;
var
  c, cn: iv_class_ptr_t;
  l, ln, t: iv_lts_ptr_t;
  pa, w, wn, prev: iv_var_ptr_t;
  p: ^iv_var_ptr_t;
begin
  c := v^.classes;
  while c <> nil do begin
    cn := c^.next;
    iv_utils_$delete_induction_class(c);
    c := cn;
  end;
  l := v^.ltss;
  while l <> nil do begin
    ln := l^.next;
    t := l;
    iv_utils_$delete_induction_lts(t);
    l := ln;
  end;
  pa := v^.parent;
  if pa <> nil then begin
    if pa^.l54 = v then
      pa^.l54 := v^.next
    else
      v^.l54^.next := v^.next;
    if pa^.children_last = v then
      pa^.children_last := v^.l54
    else
      v^.next^.l54 := v^.l54;
  end
  else begin
    w := v^.l54;
    while w <> nil do begin
      wn := w^.next;
      iv_utils_$delete_induction_variable(w);
      w := wn;
    end;
    prev := nil;
    p := addr(iv_vars);
    w := p^;
    while w <> nil do begin
      if w = v then begin
        p^ := w^.next;
        if iv_vars_last = w then
          iv_vars_last := prev;
        exit;
      end;
      prev := w;
      p := addr(w^.next);
      w := w^.next;
    end;
  end;
  free_induction_variable(v);
end;

{ interval_contains_bb - bb is in the interval headed by head (any
  block when head is nil): head is bb or reached up bb's interval heads
  (+70).  0x23C112, 0x2E bytes, no frame. }

function interval_contains_bb(
    bb: bb_ptr_t;
    head: bb_ptr_t): boolean; options(val_param); internal;
begin
  if head = nil then
    interval_contains_bb := true
  else begin
    while (bb <> nil) and (bb <> head) do
      bb := bb^.l70;
    interval_contains_bb := bb <> nil;
  end;
end;

function operand_is_loop_invariant(
    o: opnd_ptr_t;
    head: bb_ptr_t): boolean; options(val_param); internal; forward;

{ lts_is_loop_invariant - segment s (the final segment that reaches an
  exposed one) does not change in the loop headed by head: defined
  outside it, or by an instruction of a kind whose operands are
  invariant (a load of a literal pool constant of types 0, 3, 4, 7,
  10; an add, sub, rsub or muli; a neg, move, copys, mffp or mtfp; an
  lsl by an immediate).  0x23C140, 0x16C bytes, no A5: the opcodes
  compared one by one; recursive through operand_is_loop_invariant. }

function lts_is_loop_invariant(
    s: lts_ptr_t;
    head: bb_ptr_t): boolean; options(val_param); internal;
var
  i: instr_ptr_t;
  r: boolean;
begin
  if s^.f2.exposed then
    if s^.l44 <> nil then
      s := s^.l44;
  if not interval_contains_bb(s^.bb, head) then
    r := true
  else begin
    i := utils_ins_$operands_instruction(s^.refs);
    r := false;
    case i^.opc of
      106, 105:                         { loads, loadl }
        if s^.refs^.h.num = 3 then
          if i^.opnds[1].h.kind = operand$displacement_literal_pool then
            if iv_node_v_ptr_t(i^.opnds[1].link)^.w4 in [0, 3, 4, 7, 10] then
              r := true;
      178, 83, 138, 81, 137, 79:        { muli, rsub, subi, sub, addi, add }
        if s^.refs^.h.num = 3 then
          if operand_is_loop_invariant(addr(i^.opnds[1]), head) then
            if operand_is_loop_invariant(addr(i^.opnds[2]), head) then
              r := true;
      135, 77, 75, 144, 116, 126:       { negi, neg, move, copys, mffp, mtfp }
        if s^.refs^.h.num <> 1 then
          if operand_is_loop_invariant(addr(i^.opnds[1]), head) then
            r := true;
      92:                               { lsl }
        if s^.refs^.h.num <> 1 then
          if operand_is_loop_invariant(addr(i^.opnds[1]), head) then
            if i^.opnds[2].h.kind = operand$immediate then
              r := true;
      otherwise
        ;
    end;
  end;
  lts_is_loop_invariant := r;
end;

{ operand_is_loop_invariant - o (none, a constant, a like register, a
  displacement, ...) does not change in the loop headed by head; a
  register's segment by lts_is_loop_invariant, never a physical
  register's.  0x23C2AC, 0x6A bytes, no A5: masks 16#10FF7001, 126 and
  16#27000 (the last's kinds already taken by the first). }

function operand_is_loop_invariant;
var
  k: operand$t;
begin
  if o = nil then
    operand_is_loop_invariant := true
  else begin
    k := o^.h.kind;
    if k in [operand$none, operand$ip_reg_like..operand$fp_reg_pair_like,
             operand$flow_graph_edge..operand$immediate,
             operand$exception_information] then
      operand_is_loop_invariant := true
    else if k in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
      if o^.lts^.lr^.f2.physical_register then
        operand_is_loop_invariant := false
      else
        operand_is_loop_invariant := lts_is_loop_invariant(o^.lts, head);
    end
    else if k in [operand$ip_reg_like..operand$fp_reg_pair_like,
                  operand$case_jump_base] then
      operand_is_loop_invariant := true
    else
      operand_is_loop_invariant := false;
  end;
end;

{ find_definition - whether one definition of the live range reaches bb
  (from its marked blocks, l134 the segment, mark146 yes): a block
  without predecessors (or a predecessor reached by none) has none;
  blocks on the path marked no while searched, then yes with the
  definition (l134) when every predecessor reached gives the same one.
  0x23C316, 0xA4 bytes, no A5: recursive over the predecessors. }

function find_definition(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    yes: integer32;
    no: integer32): boolean; options(val_param); internal;
label
  9;
var
  e: fg_edge_ptr_t;
  def, x: univ_ptr;
  none: boolean;
begin
  if bb^.mark146 = yes then begin
    find_definition := true;
    return;
  end;
  if bb^.mark146 = no then begin
    find_definition := false;
    return;
  end;
  if bb^.preds = nil then
    goto 9;
  bb^.mark146 := no;
  def := nil;
  none := true;
  e := bb^.preds;
  while e <> nil do begin
    if find_definition(lr, e^.source, yes, no) then begin
      none := false;
      x := e^.source^.l134;
      if x = nil then
        goto 9;
      if def = nil then
        def := x
      else if def <> x then
        goto 9;
    end;
    e := e^.next_pred;
  end;
  if none then begin
    bb^.mark146 := no;
    find_definition := false;
  end
  else begin
    bb^.mark146 := yes;
    bb^.l134 := def;
    find_definition := true;
  end;
  return;
9:
  bb^.l134 := nil;
  bb^.mark146 := yes;
  find_definition := true;
end;

{ iv_utils_$locate_definition - the one definition of live range lr
  that reaches bb, or nil: each block's first writing segment (by the
  live range's list) marked as its definition, then find_definition
  with two new marks.  0x23C3BA, 0x90 bytes, no A5. }

function iv_utils_$locate_definition(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t; options(val_param); internal;
var
  yes, no: integer32;
  s: lts_ptr_t;
  b: bb_ptr_t;
begin
  iv_rtn^.marks := iv_rtn^.marks + 1;
  yes := iv_rtn^.marks;
  iv_rtn^.marks := iv_rtn^.marks + 1;
  no := iv_rtn^.marks;
  s := lr^.ltss;
  b := nil;
  while s <> nil do begin
    if s^.bb <> b then
      if (integer(s^.rrp) & 12) <> 0 then begin
        b := s^.bb;
        b^.l134 := s;
        b^.mark146 := yes;
      end;
    s := s^.next;
  end;
  if find_definition(lr, bb, yes, no) then
    iv_utils_$locate_definition := bb^.l134
  else
    iv_utils_$locate_definition := nil;
end;

{ iv_utils_$create_expression_from_lts - the expression segment s (or the
  final segment that reaches it) holds, seen from the loop headed by
  head: what its defining instruction computes when that has a kind
  (iv_opc_set), its operands' expressions (a shift by a constant made a
  multiply by its power of 2; a move or transfer its operand's; nil
  when an operand has none), canonicalized; a literal pool constant's
  value; else the segment itself when it is defined outside the loop
  and is the one definition reaching head (always when head is nil);
  nil otherwise (a segment of the loop with no expression is a
  bug).  0x23C44A, 0x278 bytes. }

function iv_utils_$create_expression_from_lts;
var
  r, x: iv_expr_ptr_t;
  i: instr_ptr_t;
  k, n, j: integer32;
  ch: array [1..2] of iv_expr_ptr_t;
begin
  if s^.f2.exposed then
    if s^.l44 <> nil then
      s := s^.l44;
  r := nil;
  i := utils_ins_$operands_instruction(s^.refs);
  if (opnd_bytes_ptr_t(s^.refs)^.rrp & 12) <> 0 then
    if i^.opc in iv_opc_set then begin
      k := iv_opc_kind[i^.opc];
      n := iv_nchildren[k];
      if n > 0 then begin
        for j := 1 to n do
          ch[j] := nil;
        for j := 1 to n do begin
          x := iv_utils_$create_expression_from_operand(
                   addr(i^.opnds[iv_opnd_pos[k, j]]), head);
          if x = nil then
            exit;
          ch[j] := x;
        end;
        if x <> nil then
          case k of
            iv_shift:
              if ch[2]^.kind <> iv_value then
                x := nil
              else begin
                r := alloc_expression;
                for j := 1 to n do
                  r^.child[j] := ch[j];
                r^.kind := iv_mul;
                r^.right^.value := lshft(1, r^.right^.value);
              end;
            iv_transfer, iv_move:
              r := x;
            otherwise begin
              r := alloc_expression;
              r^.kind := k;
              for j := 1 to n do
                r^.child[j] := ch[j];
              r := iv_utils_$canonicalize_expression(r);
            end;
          end;
        if x = nil then
          for j := 1 to n do
            if ch[j] <> nil then
              iv_utils_$delete_expression(ch[j]);
      end
      else if s^.refs^.h.num = 3 then
        if i^.opnds[1].h.kind = operand$displacement_literal_pool then
          if iv_node_v_ptr_t(i^.opnds[1].link)^.w4 in [0, 3, 4, 7, 10] then
            r := iv_utils_$create_value_expression(
                     iv_node_v_ptr_t(i^.opnds[1].link)^.value);
    end;
  if r = nil then
    if head = nil then
      r := iv_utils_$create_lts_expression(s)
    else if interval_contains_bb(s^.bb, head) then
      bug_check('IV_$create_expression_from_lts: Unknown instruction type found%.')
    else if s^.f2.final then
      if iv_utils_$locate_definition(s^.lr, head) = s then
        r := iv_utils_$create_lts_expression(s);
  iv_utils_$create_expression_from_lts := r;
end;

{ iv_utils_$create_expression_from_operand - o's expression seen from the
  loop headed by head: an immediate a constant, an operand that does not
  change (operand_is_loop_invariant's first mask) itself, a register's
  segment's expression (times 2**scale), nil for a physical register
  or anything else.  0x23C702, 0xA8 bytes. }

function iv_utils_$create_expression_from_operand;
var
  k: operand$t;
  r: iv_expr_ptr_t;
  s: lts_ptr_t;
  c: integer32;
begin
  k := o^.h.kind;
  if k = operand$immediate then
    r := iv_utils_$create_value_expression(o^.value)
  else if k in [operand$none, operand$ip_reg_like..operand$fp_reg_pair_like,
                operand$flow_graph_edge..operand$immediate,
                operand$exception_information] then
    r := iv_utils_$create_operand_expression(o^)
  else if k in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
    if o^.lts^.lr^.f2.physical_register then
      r := nil
    else begin
      s := o^.lts;
      if s^.f2.exposed then
        if s^.l44 <> nil then
          s := s^.l44;
      r := iv_utils_$create_expression_from_lts(s, head);
      if r <> nil then begin
        c := o^.h.count;
        if c <> 0 then
          r := iv_utils_$create_mul_expression(r,
                   iv_utils_$create_value_expression(lshft(1, c)));
      end;
    end;
  end
  else
    r := nil;
  iv_utils_$create_expression_from_operand := r;
end;

{ propagate_induction_increment - l (a segment o's instruction defines
  from the one with induction lts from) given from's known flag, step
  the expression of o (the operand added; negated for a subtraction),
  incr from's increment plus step.  0x23C7AA, 0xA6 bytes, no A5: frame
  8:a 12:a 16:l 20:b. }

procedure propagate_induction_increment(
    l: iv_lts_ptr_t;
    from: iv_lts_ptr_t;
    o: opnd_ptr_t;
    neg: boolean); options(val_param); internal;
var
  x, y: iv_expr_ptr_t;
begin
  l^.h.known := from^.h.known;
  l^.incr := nil;
  l^.step := nil;
  if o <> nil then begin
    x := iv_utils_$create_expression_from_operand(o, iv_head);
    if neg then
      x := iv_utils_$canonicalize_expression(
               iv_utils_$create_neg_expression(x));
    l^.step := x;
  end;
  if from^.h.known then begin
    y := iv_utils_$duplicate_expression(from^.incr);
    if o <> nil then
      y := iv_utils_$canonicalize_expression(
               iv_utils_$create_add_expression(y,
                   iv_utils_$duplicate_expression(x)));
    l^.incr := y;
  end;
end;

{ ivr_$propagate_induction_for_lifetime_segment - every segment an
  instruction reading s (unscaled) defines by adding a loop invariant to
  it given a candidate induction lts of s's variable, with its
  increment, and followed in turn: a join's result (no increment), a
  move's (an increment of 0), an add's or sub's result (the other
  operand; negated when s is subtracted), a load's or store's base
  register modified by it (the access's displacement).  0x23C850,
  0x31C bytes, no A5: recursive; the opcodes compared one by one. }

procedure ivr_$propagate_induction_for_lifetime_segment(
    s: lts_ptr_t); options(val_param); internal;
label
  1;
var
  o: opnd_ptr_t;
  i: instr_ptr_t;
  num, k: integer;
  res, inc: opnd_ptr_t;
  neg: boolean;
  zop: opnd_t;
  lr: lr_ptr_t;
  t: lts_ptr_t;
  l: iv_lts_ptr_t;
begin
  o := s^.refs;
  while o <> nil do begin
    if o^.h.read and (o^.h.count = 0) then begin
      i := utils_ins_$operands_instruction(o);
      num := o^.h.num;
      res := nil;
      neg := false;
      case i^.opc of
        203:                            { join_bp }
          if num = 1 then begin
            inc := nil;
            res := addr(i^.opnds[2]);
          end;
        144, 75: begin                  { copys, move }
          inc := addr(zop);
          res := addr(i^.opnds[2]);
          zop.h.num := 0;
          zop.h.kind := operand$immediate;
          zop.value := 0;
        end;
        137, 79:                        { addi, add }
          if num = 1 then begin
            inc := addr(i^.opnds[2]);
            res := addr(i^.opnds[3]);
          end
          else if num = 2 then begin
            inc := addr(i^.opnds[1]);
            res := addr(i^.opnds[3]);
          end;
        138, 81:                        { subi, sub }
          if num = 2 then begin
            neg := true;
            inc := addr(i^.opnds[1]);
            res := addr(i^.opnds[3]);
          end;
        83:                             { rsub }
          if num = 1 then begin
            neg := true;
            inc := addr(i^.opnds[2]);
            res := addr(i^.opnds[3]);
          end;
        221, 109, 106, 105, 104, 218, 103, 217:   { loadq, loadd, loads,
                                          loadl, loadwu, loadws, loadbu,
                                          loadbs }
          if i^.h.modify in [1, 2] then
            if o^.h.intend_to_modify then begin
              inc := addr(i^.opnds[1]);
              lr := s^.lr;
              for k := num + 1 to i^.h.nopnds do
                if i^.opnds[k].h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
                  if i^.opnds[k].lts^.lr = lr then
                    if i^.opnds[k].h.modify then begin
                      res := addr(i^.opnds[k]);
                      goto 1;
                    end;
            end;
        228, 124, 121, 120, 119, 118:   { storeq, stored, stores, storel,
                                          storew, storeb }
          if i^.h.modify in [1, 2] then
            if o^.h.intend_to_modify then begin
              inc := addr(i^.opnds[2]);
              lr := s^.lr;
              for k := num + 1 to i^.h.nopnds do
                if i^.opnds[k].h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
                  if i^.opnds[k].lts^.lr = lr then
                    if i^.opnds[k].h.modify then begin
                      res := addr(i^.opnds[k]);
                      goto 1;
                    end;
            end;
        otherwise
          ;
      end;
    1:
      if res <> nil then
        if (inc = nil) or operand_is_loop_invariant(inc, iv_head) then
          if res^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
            t := res^.lts;
            if not t^.lr^.f2.physical_register then begin
              l := create_induction_lts(1, t,
                                        iv_lts_ptr_t(s^.l24)^.ivar);
              propagate_induction_increment(l, iv_lts_ptr_t(s^.l24), inc,
                                            neg);
              ivr_$propagate_induction_for_lifetime_segment(t);
            end;
          end;
    end;
    o := o^.link;
  end;
end;

{ duplicate_increment_information - to's increment made a copy of
  from's (or unknown).  0x23CB6C, 0x42 bytes, no A5. }

procedure duplicate_increment_information(
    from: iv_lts_ptr_t;
    dst: iv_lts_ptr_t); options(val_param); internal;
begin
  if from^.h.known then begin
    dst^.h.known := true;
    dst^.incr := iv_utils_$duplicate_expression(from^.incr);
  end
  else begin
    dst^.h.known := false;
    dst^.incr := nil;
  end;
end;

{ ivr_$locate_induction_candidates - the candidates of the loop headed
  by head: each exposed integer register segment not yet a candidate
  that a join defines with inputs from inside the loop and from outside
  becomes a variable (its initial value the one outside input's
  segment), or a candidate of the variable all its outside inputs are
  candidates of when none comes from inside; one whose final segment
  (l44) is a candidate gets that one's variable and increment; each is
  then followed (ivr_$propagate_induction_for_lifetime_segment).
  0x23CBAE, 0x162 bytes, no A5. }

procedure ivr_$locate_induction_candidates(
    head: bb_ptr_t); options(val_param); internal;
label
  8, 9;
var
  s, t, last: lts_ptr_t;
  d: opnd_ptr_t;
  l, f, nl: iv_lts_ptr_t;
  i: instr_ptr_t;
  inp: iv_jbi_ptr_t;
  n_in, n_out: integer32;
  v: iv_var_ptr_t;
begin
  s := head^.exposed;
  while s <> nil do begin
    d := s^.refs;
    l := iv_lts_ptr_t(s^.l24);
    if l <> nil then
      if l^.h.kind = 1 then
        goto 9;
    if d = nil then
      goto 9;
    if d^.h.kind <> operand$ip_reg then
      goto 9;
    i := utils_ins_$operands_instruction(d);
    if i^.opc = 203 then begin          { join_bp }
      n_in := 0;
      n_out := 0;
      inp := iv_jbi_ptr_t(i^.opnds[3].link);
      while inp <> nil do begin
        t := inp^.lts;
        if interval_contains_bb(t^.bb, head) then
          n_in := n_in + 1
        else begin
          if (n_out = 0) and (t^.l24 <> 0) then
            v := iv_lts_ptr_t(t^.l24)^.ivar
          else if t^.l24 = 0 then
            v := nil
          else if v <> iv_lts_ptr_t(t^.l24)^.ivar then
            v := nil;
          last := t;
          n_out := n_out + 1;
        end;
        inp := inp^.next_op;
      end;
      if n_in > 0 then begin
        if n_out <= 0 then
          goto 9;
        v := create_induction_variable(s, nil, ord(d^.h.kind));
        if n_out = 1 then
          v^.init := iv_utils_$create_lts_expression(last);
      end
      else begin
        if n_out <= 0 then
          goto 9;
        if v = nil then
          goto 9;
        discard(create_induction_lts(1, s, v));
      end;
    end
    else begin
      if s^.l44 = nil then
        goto 9;
      f := iv_lts_ptr_t(lts_ptr_t(s^.l44)^.l24);
      if f = nil then
        goto 9;
      nl := create_induction_lts(1, s, f^.ivar);
      duplicate_increment_information(f, nl);
    end;
  8:
    ivr_$propagate_induction_for_lifetime_segment(s);
  9:
    s := s^.next_exposed;
  end;
end;

{ ivr_$propagate_induction_into_basic_block - bb's exposed register
  segments without an induction lts made candidates: a join's result
  when every input is a candidate (not an instantiation) of one
  variable (its increment the inputs' when all are equal, else
  unknown), else the candidate its final segment (l44) is; each then
  followed.  0x23CD10, 0x156 bytes, no A5.  v is set from the first
  input only when it has a variable (else it keeps an earlier value,
  which the inputs' test then rejects). }

procedure ivr_$propagate_induction_into_basic_block(
    bb: bb_ptr_t); options(val_param); internal;
label
  9;
var
  s: lts_ptr_t;
  d: opnd_ptr_t;
  i: instr_ptr_t;
  inp, first_inp: iv_jbi_ptr_t;
  l, nl, first: iv_lts_ptr_t;
  v: iv_var_ptr_t;
begin
  s := bb^.exposed;
  while s <> nil do begin
    if s^.l24 <> 0 then
      goto 9;
    d := s^.refs;
    if d = nil then
      goto 9;
    if not (d^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical]) then
      goto 9;
    i := utils_ins_$operands_instruction(d);
    if i^.opc = 203 then begin          { join_bp }
      inp := iv_jbi_ptr_t(i^.opnds[3].link);
      l := iv_lts_ptr_t(inp^.lts^.l24);
      if l <> nil then
        if l^.ivar <> nil then
          v := l^.ivar;
      while inp <> nil do begin
        l := iv_lts_ptr_t(inp^.lts^.l24);
        if (l = nil) or (v <> l^.ivar) or (l^.h.kind = 4) then begin
          v := nil;
          goto 9;
        end;
        inp := inp^.next_op;
      end;
      if v = nil then
        goto 9;
      nl := create_induction_lts(1, s, v);
      inp := iv_jbi_ptr_t(i^.opnds[3].link);
      first := iv_lts_ptr_t(inp^.lts^.l24);
      while inp <> nil do begin
        if not increments_are_equal(first, iv_lts_ptr_t(inp^.lts^.l24)) then
          exit;
        inp := inp^.next_op;
      end;
      if inp <> nil then
        nl^.h.known := false
      else
        duplicate_increment_information(l, nl);
    end
    else begin
      if s^.l44 = nil then
        goto 9;
      l := iv_lts_ptr_t(lts_ptr_t(s^.l44)^.l24);
      if l = nil then
        goto 9;
      if l^.h.kind = 4 then
        goto 9;
      v := l^.ivar;
      nl := create_induction_lts(1, s, v);
      duplicate_increment_information(l, nl);
    end;
    ivr_$propagate_induction_for_lifetime_segment(s);
  9:
    s := s^.next_exposed;
  end;
end;

{ operand_has_same_induction_variable - o is a register whose segment
  has an induction lts of s's variable.  0x23CE66, 0x48 bytes, no A5. }

function operand_has_same_induction_variable(
    s: lts_ptr_t;
    o: opnd_ptr_t): boolean; options(val_param); internal;
var
  l: iv_lts_ptr_t;
begin
  operand_has_same_induction_variable := false;
  if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
    l := iv_lts_ptr_t(o^.lts^.l24);
    if l <> nil then
      if l^.ivar = iv_lts_ptr_t(s^.l24)^.ivar then
        operand_has_same_induction_variable := true;
  end;
end;

{ apply_to_creating_induction_segments - f applied to (the slots of) the
  segments of s's variable that make s: an exposed s's final segment, a
  join's inputs, the registers its defining instruction reads.
  0x23CEAE, 0x104 bytes, no A5: f called `jsr (A1)'. }

procedure apply_to_creating_induction_segments(
    s: lts_ptr_t;
    f: iv_lts_proc_t); options(val_param); internal;
var
  l, fl: iv_lts_ptr_t;
  t: lts_ptr_t;
  i: instr_ptr_t;
  inp: iv_jbi_ptr_t;
  k: integer32;
  o: opnd_ptr_t;
begin
  l := iv_lts_ptr_t(s^.l24);
  if s^.f2.exposed then begin
    t := s^.l44;
    if t <> nil then begin
      fl := iv_lts_ptr_t(t^.l24);
      if fl <> nil then
        if fl^.ivar = l^.ivar then
          f^(t);
    end;
  end
  else begin
    i := utils_ins_$operands_instruction(s^.refs);
    if i^.opc = 203 then begin          { join_bp }
      inp := iv_jbi_ptr_t(i^.opnds[3].link);
      while inp <> nil do begin
        fl := iv_lts_ptr_t(inp^.lts^.l24);
        if fl <> nil then
          if fl^.ivar = l^.ivar then
            f^(inp^.lts);
        inp := inp^.next_op;
      end;
    end;
    for k := 1 to i^.h.nopnds do begin
      o := addr(i^.opnds[k]);
      if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
        if o^.h.read then
          if operand_has_same_induction_variable(s, o) then
            f^(o^.lts);
    end;
  end;
end;

{ ivr_$mark_lifetime_segments_as_induction_variables - s's candidate (and
  the candidates that make it, recursively) confirmed (kind 2), known as
  its variable is; an add or sub defining it counted (w44).  0x23CFB2,
  0x9E bytes (loads A5: passes itself, `move.l #0x23CFB2'); the opcodes
  `in' a constant set of 0..143 laid out from its significant bytes
  (pattern 102). }

procedure ivr_$mark_lifetime_segments_as_induction_variables(
    var s: lts_ptr_t);
var
  t: lts_ptr_t;
  l: iv_lts_ptr_t;
  d: opnd_ptr_t;
  i: instr_ptr_t;
begin
  t := s;
  l := iv_lts_ptr_t(t^.l24);
  if l <> nil then
    if l^.h.kind = 1 then begin
      l^.h.kind := 2;
      l^.h.known := l^.ivar^.f48.known;
      d := t^.refs;
      if d <> nil then
        if (opnd_bytes_ptr_t(d)^.rrp & 12) <> 0 then begin
          i := utils_ins_$operands_instruction(d);
          if i^.opc in [79, 81, 83, 137, 138] then
            l^.ivar^.w44 := l^.ivar^.w44 + 1;
        end;
      apply_to_creating_induction_segments(t,
          addr(ivr_$mark_lifetime_segments_as_induction_variables));
    end;
end;

{ ivr_$verify_candidate_is_induction_variable - v is an induction
  variable: every input of its join from inside the loop a candidate of
  v (their increments equal makes v's increment known); its segments
  then confirmed, the unconfirmed candidates deleted, the others'
  first_in_bb set; no block holds two of its first segments, and no
  exposed one is reached by a segment of v that is not first in its
  block (from inside the loop, for a join).  Verified (+48 bit 2) and
  the increment (+8) set.  0x23D062, 0x1D6 bytes, no A5. }

function ivr_$verify_candidate_is_induction_variable(
    v: iv_var_ptr_t): boolean; options(val_param); internal;
label
  1, 9;
var
  ok, same: boolean;
  i: instr_ptr_t;
  first, l, ln, t: iv_lts_ptr_t;
  inp: iv_jbi_ptr_t;
  p: ^iv_lts_ptr_t;
  lastbb, b, cur: bb_ptr_t;
  x: iv_lts_ptr_t;
  s: lts_ptr_t;
  cnt: integer;
begin
  ok := true;
  i := utils_ins_$operands_instruction(v^.lts^.refs);
  first := nil;
  same := ok;
  inp := iv_jbi_ptr_t(i^.opnds[3].link);
  while inp <> nil do begin
    if interval_contains_bb(inp^.lts^.bb, iv_head) then begin
      l := iv_lts_ptr_t(inp^.lts^.l24);
      if (l = nil) or (l^.ivar <> v) then begin
        ok := false;
        goto 1;
      end;
      if same then
        if first = nil then begin
          first := l;
          same := l^.h.known;
        end
        else
          same := increments_are_equal(first, l);
    end;
    inp := inp^.next_op;
  end;
1:
  ivr_$mark_lifetime_segments_as_induction_variables(i^.opnds[2].lts);
  p := addr(v^.ltss);
  l := v^.ltss;
  lastbb := nil;
  while l <> nil do begin
    ln := l^.next;
    b := l^.lts^.bb;
    if l^.h.kind = 1 then begin
      t := l;
      iv_utils_$delete_induction_lts(t);
      p^ := ln;
    end
    else begin
      l^.h.first_in_bb := lastbb <> b;
      p := addr(l^.next);
      lastbb := b;
    end;
    l := ln;
  end;
  x := v^.ltss;
  cur := nil;
  while x <> nil do begin
    s := x^.lts;
    if s^.bb <> cur then begin
      cnt := 0;
      cur := s^.bb;
    end;
    if s^.f2.first_in_bb then begin
      cnt := cnt + 1;
      if cnt > 1 then begin
        ok := false;
        goto 9;
      end;
    end;
    if s^.f2.exposed then
      if s^.l44 <> nil then begin
        l := iv_lts_ptr_t(lts_ptr_t(s^.l44)^.l24);
        if l <> nil then
          if not l^.h.first_in_bb then begin
            ok := false;
            goto 9;
          end;
      end
      else begin
        i := utils_ins_$operands_instruction(s^.refs);
        if i^.opc = 203 then begin      { join_bp }
          inp := iv_jbi_ptr_t(i^.opnds[3].link);
          while inp <> nil do begin
            l := iv_lts_ptr_t(inp^.lts^.l24);
            if l <> nil then
              if not l^.h.first_in_bb then
                if interval_contains_bb(inp^.lts^.bb, iv_head) then begin
                  ok := false;
                  exit;
                end;
            inp := inp^.next_op;
          end;
        end;
      end;
    x := x^.next;
  end;
  if ok then begin
    v^.f48.verified := true;
    if same then begin
      v^.f48.known := true;
      v^.incr := iv_utils_$duplicate_expression(first^.incr);
    end;
  end;
9:
  ivr_$verify_candidate_is_induction_variable := ok;
end;

{ ivr_$finalize_induction_variables - each primary variable verified
  (made final, its multiplier 1) or deleted.  0x23D238, 0x50 bytes, no
  A5: head, which its caller pushes, is not read. }

procedure ivr_$finalize_induction_variables(
    head: bb_ptr_t); options(val_param); internal;
var
  v, n: iv_var_ptr_t;
begin
  v := iv_vars;
  while v <> nil do begin
    n := v^.next;
    if ivr_$verify_candidate_is_induction_variable(v) then begin
      v^.f48.final := true;
      v^.mult := iv_utils_$create_value_expression(1);
    end
    else
      iv_utils_$delete_induction_variable(v);
    v := n;
  end;
end;

{ iv_$walk_basic_blocks_in_order - the blocks of the interval headed by
  bb in order: pre and each called for bb, each for its members, a
  member that heads an interval (+18 bit 6, distinguished_entry)
  walked in turn, then post for bb (any of them nil).  0x23D288, 0xB8 bytes: recursive; every
  argument by address (in: the callers pass the routines as constants
  placed after their code, pattern 116), copied to locals for the inner
  calls. }

procedure iv_$walk_basic_blocks_in_order(
    in bb: bb_ptr_t;
    in pre: iv_bb_proc_t;
    in each: iv_bb_proc_t;
    in post: iv_bb_proc_t);
var
  b, c, t: bb_ptr_t;
  p1, p2, p3: iv_bb_proc_t;
  q1, q2, q3: iv_bb_proc_t;
begin
  p1 := pre;
  b := bb;
  p2 := each;
  p3 := post;
  if p1 <> nil then begin
    t := b;
    p1^(t);
  end;
  if p2 <> nil then begin
    t := b;
    p2^(t);
  end;
  c := iv_bb_v_ptr_t(b)^.first138;
  while c <> nil do begin
    if c^.f.distinguished_entry then begin
      q3 := p3;
      q2 := p2;
      q1 := p1;
      t := c;
      iv_$walk_basic_blocks_in_order(t, q1, q2, q3);
    end
    else if p2 <> nil then begin
      t := c;
      p2^(t);
    end;
    c := c^.next142;
  end;
  if p3 <> nil then begin
    t := b;
    p3^(t);
  end;
end;

{ operand_is_any_induction_expression - o is a register whose segment
  has an induction lts, or is exposed (not a join's) with a final
  segment that has one.  0x23D340, 0x5A bytes, no A5. }

function operand_is_any_induction_expression(
    o: opnd_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  s: lts_ptr_t;
  i: instr_ptr_t;
begin
  r := false;
  if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
    s := o^.lts;
    if s^.l24 <> 0 then
      r := true
    else if s^.f2.exposed then begin
      i := utils_ins_$operands_instruction(s^.refs);
      if i^.opc <> 203 then             { join_bp }
        if lts_ptr_t(s^.l44)^.l24 <> 0 then
          r := true;
    end;
  end;
  operand_is_any_induction_expression := r;
end;

{ ixr_$find_current_lts_for_iv - variable v's confirmed segment (its
  induction lts) current at operand o: when o's block has an exposed
  segment of v, the first on v's list in the block whose definition
  comes before o (by instruction number, then operand number), else the
  block's last examined; otherwise the one reaching the block from the
  blocks up its l54 chain (of a block's finals of v, the one the
  others' list run in the block leads to), through its final segment.
  0x23D39A, 0x186 bytes, no A5: the numbers compared unsigned. }

function ixr_$find_current_lts_for_iv(
    v: iv_var_ptr_t;
    o: opnd_ptr_t): iv_lts_ptr_t; options(val_param); internal;
label
  9;
var
  i, j: instr_ptr_t;
  bb, c: bb_ptr_t;
  s: lts_ptr_t;
  l, x, r, y: iv_lts_ptr_t;
begin
  i := utils_ins_$operands_instruction(o);
  bb := i^.bb;
  s := bb^.exposed;
  while s <> nil do begin
    l := iv_lts_ptr_t(s^.l24);
    if l <> nil then
      if l^.ivar = v then
        if l^.h.kind = 2 then
          exit;
    s := s^.next_exposed;
  end;
  if s <> nil then begin
    x := v^.ltss;
    while x^.lts^.bb <> bb do
      x := x^.next;
    while x <> nil do begin
      if x^.lts^.bb <> bb then
        goto 9;
      r := x;
      j := utils_ins_$operands_instruction(x^.lts^.refs);
      if j^.num < i^.num then
        goto 9;
      if j^.num = i^.num then
        if x^.lts^.refs^.h.num <= o^.h.num then
          goto 9;
      x := x^.next;
    end;
  end
  else begin
    c := bb^.l54;
    r := nil;
    while (c <> nil) and (r = nil) do begin
      s := c^.finals;
      while s <> nil do begin
        l := iv_lts_ptr_t(s^.l24);
        if l <> nil then
          if l^.ivar = v then
            if l^.h.kind = 2 then
              if r = nil then
                r := l
              else begin
                y := l;
                while y <> nil do begin
                  if y^.lts^.bb <> c then
                    exit;
                  if y = r then begin
                    r := l;
                    exit;
                  end;
                  y := y^.next;
                end;
              end;
        s := s^.next_final;
      end;
      c := c^.l54;
    end;
    if r = nil then
      bug_check('IV_$FIND_CURRENT_LTS_FOR_IV: No Creation Segment was Found%.');
    s := r^.lts;
    if s^.f2.exposed then
      if s^.l44 <> nil then
        s := s^.l44;
    if (s = nil) or (s^.l24 = 0) then
      bug_check('IV_$FIND_CURRENT_LTS_FOR_IV: No Creation Segment was Found%.');
    r := iv_lts_ptr_t(s^.l24);
  end;
9:
  if r^.h.kind <> 2 then
    bug_check('IV_$FIND_CURRENT_LTS_FOR_IV: LTS is not Primary Induction Variable%.');
  ixr_$find_current_lts_for_iv := r;
end;

{ iv_utils_$compare_address_expressions - two address expressions are
  the same: both constants, or the same once a constant added to or
  subtracted from each is dropped.  0x23D5A0, 0x6C bytes (`moveq #1'
  reused for the kind tests: pattern 75; `moveq #96; btst' for add and
  sub). }

function iv_utils_$compare_address_expressions;
begin
  if (a^.kind = iv_value) and (b^.kind = iv_value) then
    iv_utils_$compare_address_expressions := true
  else begin
    if a^.kind in [iv_add, iv_sub] then
      if a^.right^.kind = iv_value then
        a := a^.left;
    if b^.kind in [iv_add, iv_sub] then
      if b^.right^.kind = iv_value then
        b := b^.left;
    iv_utils_$compare_address_expressions :=
        iv_utils_$compare_expressions(a, b);
  end;
end;

{ ixr_$find_induction_class - v's class of kind w (1 expressions, 2
  addresses) whose first induction expression's expression e matches
  (compare_expressions, compare_address_expressions), made when none
  does.  0x23D60C, 0x86 bytes, no A5. }

function ixr_$find_induction_class(
    v: iv_var_ptr_t;
    e: iv_expr_ptr_t;
    w: integer): iv_class_ptr_t; options(val_param); internal;
var
  c: iv_class_ptr_t;
  r: boolean;
begin
  c := v^.classes;
  while c <> nil do begin
    if c^.w16 = w then begin
      r := false;
      case c^.w16 of
        1: r := iv_utils_$compare_expressions(e, c^.iexprs^.expr);
        2: r := iv_utils_$compare_address_expressions(e, c^.iexprs^.expr);
        otherwise
          ;
      end;
      if r then
        exit;
    end;
    c := c^.next;
  end;
  if c = nil then
    c := create_induction_class(w, v);
  ixr_$find_induction_class := c;
end;

{ ixr_$find_induction_expr - the induction expression of e in v's class
  of kind w (an expression class's first; an address class's that is
  the same), made with a copy of e when none is.  0x23D692, 0x86 bytes,
  no A5. }

function ixr_$find_induction_expr(
    v: iv_var_ptr_t;
    e: iv_expr_ptr_t;
    w: integer): iv_iexpr_ptr_t; options(val_param); internal;
var
  c: iv_class_ptr_t;
  x: iv_iexpr_ptr_t;
begin
  c := ixr_$find_induction_class(v, e, w);
  case c^.w16 of
    1:
      x := c^.iexprs;
    2: begin
      x := c^.iexprs;
      while x <> nil do begin
        if iv_utils_$compare_expressions(e, x^.expr) then
          exit;
        x := x^.next;
      end;
    end;
    otherwise
      x := nil;
  end;
  if x = nil then
    x := create_induction_expr(c, iv_utils_$duplicate_expression(e));
  ixr_$find_induction_expr := x;
end;

{ ixr_$find_induction_variable - the variable of kind that is m times v:
  v itself for m = 1 of v's kind, else the primary's child of kind with
  the multiplier m times v's (and its parents'), made with v's
  increment and initial value times m when none is (the copy of the
  increment otherwise deleted; the multiplier's is kept).  0x23D718,
  0x13A bytes, no A5. }

function ixr_$find_induction_variable(
    v: iv_var_ptr_t;
    m: iv_expr_ptr_t;
    kind: integer): iv_var_ptr_t; options(val_param); internal;
var
  w: iv_var_ptr_t;
  mm, inc, t: iv_expr_ptr_t;
begin
  if (v^.f48.kind = kind) and (m^.kind = iv_value) and (m^.value = 1) then
    w := v
  else begin
    mm := iv_utils_$duplicate_expression(m);
    if v^.f48.known then
      inc := iv_utils_$canonicalize_expression(
                 iv_utils_$create_mul_expression(
                     iv_utils_$duplicate_expression(v^.incr),
                     iv_utils_$duplicate_expression(m)))
    else
      inc := nil;
    while v^.parent <> nil do begin
      mm := iv_utils_$canonicalize_expression(
                iv_utils_$create_mul_expression(
                    iv_utils_$duplicate_expression(v^.mult), mm));
      v := v^.parent;
    end;
    w := v^.l54;
    while w <> nil do begin
      if w^.f48.kind = kind then
        if iv_utils_$compare_expressions(w^.mult, mm) then
          exit;
      w := w^.next;
    end;
    if w = nil then begin
      w := create_induction_variable(nil, v, kind);
      w^.head := v^.head;
      w^.incr := inc;
      w^.mult := mm;
      if v^.init <> nil then
        w^.init := iv_utils_$canonicalize_expression(
                       iv_utils_$create_mul_expression(
                           iv_utils_$duplicate_expression(v^.init),
                           iv_utils_$duplicate_expression(mm)));
    end
    else begin
      t := inc;
      iv_utils_$delete_expression(t);
    end;
  end;
  ixr_$find_induction_variable := w;
end;

{ ixr_$create_induction_lts_from_induction_instantiation - o's segment
  given a kind 4 induction lts of the instantiation's expression (an
  expression class's induction expression), on that expression's list;
  cur the variable's segment current there, stale when it does not
  reach o.  Nothing for a physical register.  0x23D852, 0xAC bytes, no
  A5: inst by address, copied. }

procedure ixr_$create_induction_lts_from_induction_instantiation(
    inst: iv_inst_t;
    o: opnd_ptr_t); options(val_param); internal;
var
  x: iv_iexpr_ptr_t;
  l: iv_lts_ptr_t;
begin
  if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
    if o^.lts^.lr^.f2.physical_register then
      return;
  x := ixr_$find_induction_expr(inst.ivar, inst.expr, 1);
  l := create_induction_lts(4, o^.lts, inst.ivar);
  l^.cur := inst.ilts;
  l^.iexpr := x;
  l^.next := x^.ltss;
  x^.ltss := l;
  if ixr_$find_current_lts_for_iv(inst.ilts^.ivar, o) <> l^.cur then
    l^.h.stale := true;
end;

{ ixr_$create_induction_addr_from_induction_instantiation - an address
  mode of operand o (base its base register) by the instantiation's
  expression (an address class's induction expression), stale when the
  variable's current segment does not reach o.  Nothing when either is
  a physical register.  0x23D8FE, 0xA2 bytes, no A5. }

procedure ixr_$create_induction_addr_from_induction_instantiation(
    inst: iv_inst_t;
    o: opnd_ptr_t;
    base: opnd_ptr_t); options(val_param); internal;
var
  a: iv_addr_ptr_t;
begin
  if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
    if o^.lts^.lr^.f2.physical_register then
      return;
  if base^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
    if base^.lts^.lr^.f2.physical_register then
      return;
  a := create_induction_addr(ixr_$find_induction_expr(inst.ivar, inst.expr, 2),
                             inst.ilts, o, base);
  if ixr_$find_current_lts_for_iv(a^.ilts^.ivar, o) <> a^.ilts then
    a^.stale := true;
end;

{ ixr_$get_induction_instantiation_from_operand - what operand o (times
  2**scale, negated when neg) is of an induction variable of kind: the
  variable (of kind, times that factor), the expression added (a kind 4
  segment's induction expression times the factor, else 0), the
  variable's segment current at o (moved to the current one, the
  expression adjusted by the increments' difference times the
  multiplier, when it is not; no variable when its increment is not
  known, a candidate's link from o's segment then dropped).  o's
  segment without an induction lts of its own gets an instantiation
  of the one reaching it.  0x23D9A0, 0x216 bytes, no A5: the record
  returned through the caller's address at (8). }

function ixr_$get_induction_instantiation_from_operand(
    o: opnd_ptr_t;
    neg: boolean;
    kind: integer): iv_inst_t; options(val_param); internal;
var
  m: integer32;
  s, t: lts_ptr_t;
  l0, il, cur, c: iv_lts_ptr_t;
  tmp, r: iv_inst_t;
  v: iv_var_ptr_t;
  x, e, d: iv_expr_ptr_t;
begin
  m := lshft(1, o^.h.count);
  if neg then
    m := -m;
  s := o^.lts;
  l0 := iv_lts_ptr_t(s^.l24);
  if l0 <> nil then
    il := l0
  else begin
    t := s;
    if t^.f2.exposed then
      if t^.l44 <> nil then
        t := t^.l44;
    il := iv_lts_ptr_t(t^.l24);
    if il = nil then
      bug_check('IV_$get_induction_instantiation_from_operand: No Creation Induction LTS was Found%.');
  end;
  if il^.h.kind in [3, 4] then
    cur := il^.cur
  else
    cur := il;
  if l0 = nil then begin
    tmp.ivar := il^.ivar;
    tmp.ilts := cur;
    if il^.h.kind = 4 then
      tmp.expr := iv_utils_$duplicate_expression(il^.iexpr^.expr)
    else
      tmp.expr := iv_utils_$create_value_expression(0);
    ixr_$create_induction_lts_from_induction_instantiation(tmp, o);
  end;
  v := il^.ivar;
  if (m = 1) and (v^.f48.kind = kind) then
    r.ivar := v
  else begin
    x := iv_utils_$create_value_expression(m);
    r.ivar := ixr_$find_induction_variable(v, x, kind);
    iv_utils_$delete_expression(x);
  end;
  if il^.h.kind = 4 then begin
    e := iv_utils_$duplicate_expression(il^.iexpr^.expr);
    if m <> 1 then
      e := iv_utils_$canonicalize_expression(
               iv_utils_$create_mul_expression(e,
                   iv_utils_$create_value_expression(m)));
  end
  else
    e := iv_utils_$create_value_expression(0);
  r.expr := e;
  r.ilts := cur;
  c := ixr_$find_current_lts_for_iv(r.ilts^.ivar, o);
  if c <> r.ilts then
    if r.ivar^.f48.known then begin
      d := iv_utils_$canonicalize_expression(
               iv_utils_$create_mul_expression(
                   iv_utils_$create_sub_expression(
                       iv_utils_$duplicate_expression(r.ilts^.incr),
                       iv_utils_$duplicate_expression(c^.incr)),
                   iv_utils_$duplicate_expression(r.ivar^.mult)));
      r.expr := iv_utils_$canonicalize_expression(
                    iv_utils_$create_add_expression(r.expr, d));
      r.ilts := c;
    end
    else begin
      if l0 <> nil then
        if l0^.h.kind <> 2 then
          s^.l24 := 0;
      r.ivar := nil;
      r.ilts := nil;
      iv_utils_$delete_expression(r.expr);
    end;
  ixr_$get_induction_instantiation_from_operand := r;
end;

{ operand_is_current_induction_expression - o is a register whose
  segment (or, exposed without one, the final segment reaching it) has
  an induction lts of a variable of the loop being worked on.
  0x23DC0A, 0x64 bytes, no A5. }

function operand_is_current_induction_expression(
    o: opnd_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  s: lts_ptr_t;
  l: iv_lts_ptr_t;
begin
  r := false;
  if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
    s := o^.lts;
    l := iv_lts_ptr_t(s^.l24);
    if s^.l44 <> nil then
      if l = nil then
        if s^.f2.exposed then
          l := iv_lts_ptr_t(lts_ptr_t(s^.l44)^.l24);
    if l <> nil then
      if l^.ivar^.head = iv_head then
        r := true;
  end;
  operand_is_current_induction_expression := r;
end;

{ ixr_$induction_expr_plus_loop_invariant - instruction i's operand r
  (numbers) is an instantiation of what operand a is plus the loop
  invariant operand b (each negated when asked).  0x23DC6E, 0xFC bytes,
  no A5: frame 8:a 12:w 14:b 16:w 18:b 20:w.  The invariant's
  expression is not deleted when a is no instantiation. }

procedure ixr_$induction_expr_plus_loop_invariant(
    i: instr_ptr_t;
    a: integer;
    neg_a: boolean;
    b: integer;
    neg_b: boolean;
    r: integer); options(val_param); internal;
var
  pa, pb, pr: opnd_ptr_t;
  x: iv_expr_ptr_t;
  inst: iv_inst_t;
begin
  pa := addr(i^.opnds[a]);
  pb := addr(i^.opnds[b]);
  pr := addr(i^.opnds[r]);
  x := iv_utils_$create_expression_from_operand(pb, iv_head);
  if neg_b then
    x := iv_utils_$create_neg_expression(x);
  x := iv_utils_$canonicalize_expression(x);
  inst := ixr_$get_induction_instantiation_from_operand(pa, neg_a,
                                                        ord(pr^.h.kind));
  if inst.ivar <> nil then begin
    inst.expr := iv_utils_$canonicalize_expression(
                     iv_utils_$create_add_expression(inst.expr,
                         iv_utils_$duplicate_expression(x)));
    ixr_$create_induction_lts_from_induction_instantiation(inst, pr);
    iv_utils_$delete_expression(inst.expr);
    iv_utils_$delete_expression(x);
  end;
end;

{ ixr_$induction_expr_plus_induction_expr - operand r is an
  instantiation of the sum of two operands' instantiations at the same
  segment of variables that are one's parent or siblings: of the
  variable of the summed multipliers (none when it is 0), the summed
  expressions.  0x23DD6A, 0x1D2 bytes, no A5. }

procedure ixr_$induction_expr_plus_induction_expr(
    i: instr_ptr_t;
    a: integer;
    neg_a: boolean;
    b: integer;
    neg_b: boolean;
    r: integer); options(val_param); internal;
label
  9;
var
  pa, pb, pr: opnd_ptr_t;
  v, va, vb, p: iv_var_ptr_t;
  ia, ib, t: iv_inst_t;
  m, e, tmp: iv_expr_ptr_t;
begin
  pa := addr(i^.opnds[a]);
  pb := addr(i^.opnds[b]);
  pr := addr(i^.opnds[r]);
  v := nil;
  ia := ixr_$get_induction_instantiation_from_operand(pa, neg_a,
                                                      ord(pr^.h.kind));
  if ia.ivar = nil then
    return;
  ib := ixr_$get_induction_instantiation_from_operand(pb, neg_b,
                                                      ord(pr^.h.kind));
  if ib.ivar = nil then
    goto 9;
  va := ia.ivar;
  vb := ib.ivar;
  if ia.ilts = ib.ilts then begin
    p := va^.parent;
    if p <> nil then begin
      if p = vb^.parent then
        v := p
      else if p = vb then
        v := vb;
    end
    else begin
      p := vb^.parent;
      if p <> nil then begin
        if p = va then
          v := va;
      end
      else if vb = va then
        v := va;
    end;
  end;
  if v <> nil then begin
    m := iv_utils_$canonicalize_expression(
             iv_utils_$create_add_expression(
                 iv_utils_$duplicate_expression(va^.mult),
                 iv_utils_$duplicate_expression(vb^.mult)));
    e := iv_utils_$canonicalize_expression(
             iv_utils_$create_add_expression(
                 iv_utils_$duplicate_expression(ia.expr),
                 iv_utils_$duplicate_expression(ib.expr)));
    if not iv_utils_$expression_is_zero(m) then begin
      t.expr := e;
      t.ivar := ixr_$find_induction_variable(v, m, ord(pr^.h.kind));
      t.ilts := ia.ilts;
      ixr_$create_induction_lts_from_induction_instantiation(t, pr);
    end;
    iv_utils_$delete_expression(m);
    tmp := e;
    iv_utils_$delete_expression(tmp);
  end;
  iv_utils_$delete_expression(ib.expr);
9:
  iv_utils_$delete_expression(ia.expr);
end;

{ ixr_$induction_expr_times_loop_invariant - operand r is an
  instantiation of operand a's times the loop invariant operand b (not
  0): of the variable times b, the expression times b.  0x23DF3C, 0x106
  bytes, no A5. }

procedure ixr_$induction_expr_times_loop_invariant(
    i: instr_ptr_t;
    a: integer;
    b: integer;
    r: integer); options(val_param); internal;
var
  pa, pb, pr: opnd_ptr_t;
  x: iv_expr_ptr_t;
  inst: iv_inst_t;
begin
  pa := addr(i^.opnds[a]);
  pb := addr(i^.opnds[b]);
  pr := addr(i^.opnds[r]);
  x := iv_utils_$create_expression_from_operand(pb, iv_head);
  if not iv_utils_$expression_is_zero(x) then begin
    inst := ixr_$get_induction_instantiation_from_operand(pa, false,
                                                          ord(pr^.h.kind));
    if inst.ivar <> nil then begin
      inst.ivar := ixr_$find_induction_variable(inst.ivar, x,
                                                ord(pr^.h.kind));
      inst.expr := iv_utils_$canonicalize_expression(
                       iv_utils_$create_mul_expression(inst.expr,
                           iv_utils_$duplicate_expression(x)));
      ixr_$create_induction_lts_from_induction_instantiation(inst, pr);
      iv_utils_$delete_expression(inst.expr);
    end;
  end;
  iv_utils_$delete_expression(x);
end;

{ ixr_$induction_expr_shifted_loop_invariant - operand r is an
  instantiation of operand a's shifted by the constant operand b (made
  its power of 2).  0x23E042, 0x10A bytes, no A5: the constant's
  expression is not deleted when a is no instantiation. }

procedure ixr_$induction_expr_shifted_loop_invariant(
    i: instr_ptr_t;
    a: integer;
    b: integer;
    r: integer); options(val_param); internal;
var
  pa, pb, pr: opnd_ptr_t;
  x, tmp: iv_expr_ptr_t;
  inst: iv_inst_t;
begin
  pa := addr(i^.opnds[a]);
  pb := addr(i^.opnds[b]);
  pr := addr(i^.opnds[r]);
  x := iv_utils_$create_expression_from_operand(pb, iv_head);
  if x^.kind = iv_value then begin
    inst := ixr_$get_induction_instantiation_from_operand(pa, false,
                                                          ord(pr^.h.kind));
    if inst.ivar = nil then
      return;
    x^.value := lshft(1, x^.value);
    inst.ivar := ixr_$find_induction_variable(inst.ivar, x, ord(pr^.h.kind));
    inst.expr := iv_utils_$canonicalize_expression(
                     iv_utils_$create_mul_expression(inst.expr,
                         iv_utils_$duplicate_expression(x)));
    ixr_$create_induction_lts_from_induction_instantiation(inst, pr);
    iv_utils_$delete_expression(inst.expr);
  end;
  tmp := x;
  iv_utils_$delete_expression(tmp);
end;

{ ixr_$induction_expression - operand r is an instantiation of operand
  a's (negated when asked).  0x23E14C, 0x84 bytes, no A5. }

procedure ixr_$induction_expression(
    i: instr_ptr_t;
    a: integer;
    neg: boolean;
    r: integer); options(val_param); internal;
var
  pa, pr: opnd_ptr_t;
  inst: iv_inst_t;
begin
  pa := addr(i^.opnds[a]);
  pr := addr(i^.opnds[r]);
  inst := ixr_$get_induction_instantiation_from_operand(pa, neg,
                                                        ord(pr^.h.kind));
  if inst.ivar <> nil then begin
    ixr_$create_induction_lts_from_induction_instantiation(inst, pr);
    iv_utils_$delete_expression(inst.expr);
  end;
end;

{ ixr_$scan_addressing_mode - a memory access through o and base, one an
  induction register of the loop and the other invariant (o not
  modified by it), made an address mode of the instantiation plus the
  invariant's expression.  0x23E1D0, 0xE6 bytes, no A5. }

procedure ixr_$scan_addressing_mode(
    o: opnd_ptr_t;
    base: opnd_ptr_t); options(val_param); internal;
var
  ind, other: opnd_ptr_t;
  inst: iv_inst_t;
begin
  ind := nil;
  other := ind;
  if not o^.h.intend_to_modify then
    if operand_is_current_induction_expression(o)
        and operand_is_loop_invariant(base, iv_head) then begin
      ind := o;
      other := base;
    end
    else if operand_is_current_induction_expression(base)
        and operand_is_loop_invariant(o, iv_head) then begin
      ind := base;
      other := o;
    end;
  if ind <> nil then begin
    inst := ixr_$get_induction_instantiation_from_operand(ind, false,
                                                          ord(ind^.h.kind));
    if inst.ivar <> nil then begin
      inst.expr := iv_utils_$canonicalize_expression(
                       iv_utils_$create_add_expression(inst.expr,
                           iv_utils_$create_expression_from_operand(other,
                                                                    iv_head)));
      ixr_$create_induction_addr_from_induction_instantiation(inst, o, base);
      iv_utils_$delete_expression(inst.expr);
    end;
  end;
end;

{ ixr_$scan_basic_block_for_induction_expressions - bb's instructions
  renumbered to increase, then each computing an induction expression of
  the loop recognized: an add, sub or rsub of two induction registers or
  of one and an invariant (unless its result already has an induction
  lts), a move's, mffp's or mtfp's copy, a muli by an invariant, a neg,
  an lsl by a constant; a load's or store's address.  0x23E2B6, 0x430
  bytes (loads A5): the opcodes compared one by one; constant word and
  boolean arguments pushed merged as longwords (pattern 105); the
  numbers zero-extended. }

procedure ixr_$scan_basic_block_for_induction_expressions(
    var bb: bb_ptr_t);
var
  i: instr_ptr_t;
  n, k: integer32;
  o1, o2: opnd_ptr_t;
begin
  i := bb^.first;
  n := i^.num;
  i := i^.next;
  while i <> nil do begin
    k := i^.num;
    if k <= n then begin
      n := n + 1;
      i^.num := n;
    end
    else
      n := k;
    i := i^.next;
  end;
  i := bb^.first;
  while i <> nil do begin
    case i^.opc of
      137, 79:                          { addi, add }
        if not operand_is_any_induction_expression(addr(i^.opnds[3])) then begin
          o1 := addr(i^.opnds[1]);
          if operand_is_current_induction_expression(o1) then begin
            o2 := addr(i^.opnds[2]);
            if operand_is_current_induction_expression(o2) then
              ixr_$induction_expr_plus_induction_expr(i, 1, false, 2, false, 3)
            else if operand_is_loop_invariant(o2, iv_head) then
              ixr_$induction_expr_plus_loop_invariant(i, 1, false, 2, false, 3);
          end
          else if operand_is_current_induction_expression(addr(i^.opnds[2])) then
            if operand_is_loop_invariant(o1, iv_head) then
              ixr_$induction_expr_plus_loop_invariant(i, 2, false, 1, false, 3);
        end;
      138, 81:                          { subi, sub }
        if not operand_is_any_induction_expression(addr(i^.opnds[3])) then begin
          o1 := addr(i^.opnds[1]);
          if operand_is_current_induction_expression(o1) then begin
            o2 := addr(i^.opnds[2]);
            if operand_is_current_induction_expression(o2) then
              ixr_$induction_expr_plus_induction_expr(i, 1, true, 2, false, 3)
            else if operand_is_loop_invariant(o2, iv_head) then
              ixr_$induction_expr_plus_loop_invariant(i, 1, true, 2, false, 3);
          end
          else if operand_is_current_induction_expression(addr(i^.opnds[2])) then
            if operand_is_loop_invariant(o1, iv_head) then
              ixr_$induction_expr_plus_loop_invariant(i, 2, false, 1, true, 3);
        end;
      83:                               { rsub }
        if not operand_is_any_induction_expression(addr(i^.opnds[3])) then begin
          o2 := addr(i^.opnds[2]);
          if operand_is_current_induction_expression(o2) then begin
            o1 := addr(i^.opnds[1]);
            if operand_is_current_induction_expression(o1) then
              ixr_$induction_expr_plus_induction_expr(i, 1, false, 2, true, 3)
            else if operand_is_loop_invariant(o1, iv_head) then
              ixr_$induction_expr_plus_loop_invariant(i, 2, true, 1, false, 3);
          end
          else if operand_is_current_induction_expression(addr(i^.opnds[1])) then
            if operand_is_loop_invariant(o2, iv_head) then
              ixr_$induction_expr_plus_loop_invariant(i, 1, false, 2, true, 3);
        end;
      75:                               { move }
        if not operand_is_any_induction_expression(addr(i^.opnds[2])) then
          if operand_is_current_induction_expression(addr(i^.opnds[1])) then
            ixr_$induction_expression(i, 1, false, 2);
      116, 126:                         { mffp, mtfp }
        if operand_is_current_induction_expression(addr(i^.opnds[1])) then
          ixr_$induction_expression(i, 1, false, 2);
      178: begin                        { muli }
        o1 := addr(i^.opnds[1]);
        if operand_is_current_induction_expression(o1) then begin
          if operand_is_loop_invariant(addr(i^.opnds[2]), iv_head) then
            ixr_$induction_expr_times_loop_invariant(i, 1, 2, 3);
        end
        else if operand_is_current_induction_expression(addr(i^.opnds[2])) then
          if operand_is_loop_invariant(o1, iv_head) then
            ixr_$induction_expr_times_loop_invariant(i, 2, 1, 3);
      end;
      135, 77:                          { negi, neg }
        if operand_is_current_induction_expression(addr(i^.opnds[1])) then
          ixr_$induction_expression(i, 1, true, 2);
      92:                               { lsl }
        if operand_is_current_induction_expression(addr(i^.opnds[1])) then
          if operand_is_loop_invariant(addr(i^.opnds[2]), iv_head) then
            ixr_$induction_expr_shifted_loop_invariant(i, 1, 2, 3);
      203:                              { join_bp }
        ;
      221, 109, 106, 105, 104, 218, 103, 217:   { the loads }
        ixr_$scan_addressing_mode(addr(i^.opnds[2]), addr(i^.opnds[1]));
      228, 124, 121, 120, 119, 118:     { the stores }
        ixr_$scan_addressing_mode(addr(i^.opnds[3]), addr(i^.opnds[2]));
      otherwise
        ;
    end;
    i := i^.next;
  end;
end;

{ ixt_$multiply_cost - cost c of multiplying by v's multiplier: for an
  integer variable none when it is a power of 2 up to 8 (a scale), c
  for a larger one, 4c otherwise; for others c when it is 1, else 2c.
  0x23E6E6, 0x6E bytes, no A5. }

function ixt_$multiply_cost(
    v: iv_var_ptr_t;
    c: integer32): integer32; options(val_param); internal;
var
  m: iv_expr_ptr_t;
begin
  m := v^.mult;
  if v^.f48.kind <> 1 then begin
    if not ((m^.kind = iv_value) and (m^.value = 1)) then
      c := c + c;
  end
  else if (m^.kind = iv_value) and ((~(m^.value - 1) & m^.value) = m^.value) then begin
    if m^.value <= 8 then
      c := 0;
  end
  else
    c := lshft(c, 2);
  ixt_$multiply_cost := c;
end;

{ get_secondary_segment - the segment of s's secondary.  0x23E754, 0x12
  bytes, no frame. }

function get_secondary_segment(
    s: lts_ptr_t): lts_ptr_t; options(val_param); internal;
begin
  get_secondary_segment := iv_lts_ptr_t(s^.l24)^.sec^.lts;
end;

{ ixt_$induction_segment_exists - l's segment still points to it and,
  when it is defined, has readers or an instruction that must stay
  (+2 bit 6).  0x23E766, 0x58 bytes, no A5. }

function ixt_$induction_segment_exists(
    l: iv_lts_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  s: lts_ptr_t;
  d: opnd_ptr_t;
begin
  r := true;
  s := l^.lts;
  if iv_lts_ptr_t(s^.l24) <> l then
    r := false
  else begin
    d := s^.refs;
    if d <> nil then
      if (opnd_bytes_ptr_t(d)^.rrp & 12) <> 0 then
        if d^.link = nil then
          if not utils_ins_$operands_instruction(d)^.h.b2_6 then
            r := false;
  end;
  ixt_$induction_segment_exists := r;
end;

{ ixt_$clear_primary_used_fields - v's segments' used flags cleared.
  0x23E7BE, 0x1A bytes, no frame: `andi.w #-49' of the first word. }

procedure ixt_$clear_primary_used_fields(
    v: iv_var_ptr_t); options(val_param); internal;
var
  l: iv_lts_ptr_t;
begin
  l := v^.ltss;
  while l <> nil do begin
    l^.h.used_known := false;
    l^.h.used_unknown := false;
    l := l^.next;
  end;
end;

{ ixt_$mark_primary_used_fields - x's instantiations whose segment is
  gone deleted; the others' and the address modes' current segments
  marked used (known or not, by the instantiation's segment's
  increment).  0x23E7D8, 0x96 bytes, no A5. }

procedure ixt_$mark_primary_used_fields(
    x: iv_iexpr_ptr_t); options(val_param); internal;
var
  l, ln, t: iv_lts_ptr_t;
  a, an: iv_addr_ptr_t;
begin
  l := x^.ltss;
  while l <> nil do begin
    ln := l^.next;
    if not ixt_$induction_segment_exists(l) then begin
      t := l;
      iv_utils_$delete_induction_lts(t);
    end
    else if l^.h.known then
      l^.cur^.h.used_known := true
    else
      l^.cur^.h.used_unknown := true;
    l := ln;
  end;
  a := x^.addrs;
  while a <> nil do begin
    an := a^.next;
    if a^.ilts^.h.known then
      a^.ilts^.h.used_known := true
    else
      a^.ilts^.h.used_unknown := true;
    a := an;
  end;
end;

{ ixt_$count_primary_used_fields - v's segments used with a known
  increment and (otherwise) with an unknown one.  0x23E86E, 0x48 bytes,
  no A5. }

procedure ixt_$count_primary_used_fields(
    v: iv_var_ptr_t;
    out n_known: integer32;
    out n_unknown: integer32); options(val_param); internal;
var
  l: iv_lts_ptr_t;
  a, b: integer32;
begin
  a := 0;
  b := a;
  l := v^.ltss;
  while l <> nil do begin
    if l^.h.used_known then
      a := a + 1
    else if l^.h.used_unknown then
      b := b + 1;
    l := l^.next;
  end;
  n_known := a;
  n_unknown := b;
end;

{ ixt_$replace_segment_references - the readers of s (not writers or
  modifiers) at which s's variable's current segment is s's own made
  readers of t, through an exposed segment of t's live range (made
  complex, t made final, a birthpoint added) when s is in another block;
  each put after t's definition.  0x23E8B6, 0x148 bytes, no A5. }

procedure ixt_$replace_segment_references(
    s: lts_ptr_t;
    t: lts_ptr_t); options(val_param); internal;
var
  l: iv_lts_ptr_t;
  bb: bb_ptr_t;
  o, nxt, x: opnd_ptr_t;
  p, q: ^opnd_ptr_t;
  u: lts_ptr_t;
  created: boolean;
begin
  l := iv_lts_ptr_t(s^.l24);
  bb := s^.bb;
  if l = nil then
    if s^.f2.exposed then
      if s^.l44 <> nil then
        l := iv_lts_ptr_t(lts_ptr_t(s^.l44)^.l24);
  if l <> nil then
    if l^.h.kind in [3, 4] then
      l := l^.cur;
  o := s^.refs;
  p := addr(s^.refs);
  while o <> nil do begin
    nxt := o^.link;
    if ((opnd_bytes_ptr_t(o)^.rrp & 16#2C) <> 0) or (l = nil) then
      p := addr(o^.link)
    else if ixr_$find_current_lts_for_iv(l^.ivar, o) <> l then
      p := addr(o^.link)
    else begin
      p^ := o^.link;
      if t^.bb = bb then
        u := t
      else begin
        if t^.lr^.id = 0 then begin
          bv_$make_live_range_complex(iv_rtn, t^.lr);
          utils_$put_lts_on_final_list(t);
        end;
        u := utils_$get_exposed_lts(t^.lr, bb, created);
        if created then
          utils_$add_birthpoint(t, bb, true);
      end;
      q := addr(u^.refs);
      x := u^.refs;
      if x <> nil then
        if (opnd_bytes_ptr_t(x)^.rrp & 12) <> 0 then begin
          q := addr(x^.link);
          x := x^.link;
        end;
      o^.lts := u;
      o^.link := x;
      q^ := o;
    end;
    o := nxt;
  end;
end;

{ ixt_$create_increment_instruction - an instruction adding e (sub of
  its negation, a move for 0) to src giving dst, in register file
  rclass, put before at (past the joins and labels there) or after it
  (past those after it); an operand that is not a register made in
  code_bb.  0x23E9FE, 0x178 bytes, no A5: the opcode from iv_incr_opc
  by sign and file; frame 8:a 12:w 14:l 18:w 20:l 24:w 26:a 30:b 32:l
  36:l (32, the source's block, not read). }

procedure ixt_$create_increment_instruction(
    e: iv_expr_ptr_t;
    rclass: integer;
    src: lts_ptr_t;
    src_rrp: integer;
    dst: lts_ptr_t;
    dst_rrp: integer;
    at: instr_ptr_t;
    after: boolean;
    src_bb: bb_ptr_t;
    code_bb: bb_ptr_t); options(val_param); internal;
var
  sign, n, k: integer32;
  x, tmp: iv_expr_ptr_t;
  i: instr_ptr_t;
begin
  if e^.kind = iv_neg then begin
    sign := -1;
    x := iv_utils_$duplicate_expression(e^.left);
  end
  else if (e^.kind = iv_value) and (e^.value < 0) then begin
    sign := -1;
    x := iv_utils_$create_value_expression(-e^.value);
  end
  else if iv_utils_$expression_is_zero(e) then begin
    sign := 0;
    x := iv_utils_$create_value_expression(sign);
  end
  else begin
    sign := 1;
    x := iv_utils_$duplicate_expression(e);
  end;
  if not after then begin
    while at <> nil do begin
      if not ((at^.opc = 203) or (at^.opc = 199)) then  { join_bp, label }
        exit;
      at := at^.next;
    end;
  end
  else
    while at^.next <> nil do begin
      if not ((at^.next^.opc = 203) or (at^.next^.opc = 199)) then
        exit;
      at := at^.next;
    end;
  i := lir_$optimizer_new_instruction(at, iv_incr_opc[sign, rclass], after);
  for k := 1 to i^.h.nopnds do
    i^.opnds[k].h.num := k;
  n := 1;
  if (i^.opc = 79) or (i^.opc = 81) or (i^.opc = 138) or (i^.opc = 137) then begin
    iv_utils_$create_operand_from_expression(addr(i^.opnds[1]), nil, code_bb,
                                             x, rclass);
    n := 2;
  end;
  add_operand_to_segment(addr(i^.opnds[n]), src, src_rrp, rclass);
  add_operand_to_segment(addr(i^.opnds[n + 1]), dst, dst_rrp, rclass);
  tmp := x;
  iv_utils_$delete_expression(tmp);
end;

{ remove_segment_from_operand - register operand o taken off its
  segment's references; a segment left unread (not exposed with a
  successor list, l28, or a final reaching it) excised, or its defining
  instruction when its definition has no readers left.  0x23EB76, 0x9C
  bytes, no A5. }

procedure remove_segment_from_operand(
    o: opnd_ptr_t); options(val_param); internal;
var
  s: lts_ptr_t;
  p: ^opnd_ptr_t;
  x, d: opnd_ptr_t;
begin
  if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
    s := o^.lts;
    x := s^.refs;
    p := addr(s^.refs);
    while x <> o do begin
      p := addr(x^.link);
      x := x^.link;
    end;
    p^ := x^.link;
    if not s^.f2.exposed then begin
      if s^.l28 <> nil then
        return;
      if s^.l44 <> nil then
        return;
    end;
    if s^.refs = nil then
      utils_$excise_lts_cleanly(s, true)
    else begin
      d := s^.refs;
      if d^.link = nil then
        if (opnd_bytes_ptr_t(d)^.rrp & 12) <> 0 then
          discard(utils_$excise_instruction_if_unconsumed(
                      utils_ins_$operands_instruction(d), true));
    end;
  end;
end;

{ ixt_$replace_induction_expr - induction expression x's uses replaced
  by e, a function of the primary variable: for an expression class,
  its instantiations whose segment is gone dropped, a new segment made
  next to each primary segment used (an increment instruction from the
  primary's secondary, its instantiation recorded in repl; with e 0 the
  secondary's own), and each live instantiation's readers moved to its
  current segment's replacement (and the exposed segments it reaches in
  the loop); for an address class, each mode's operand made a reader of
  the replacement (through an exposed segment in its block) and its
  base the value of e.  0x23EC12, 0x348 bytes, no A5. }

procedure ixt_$replace_induction_expr(
    x: iv_iexpr_ptr_t;
    e: iv_expr_ptr_t); options(val_param); internal;
var
  v, pv: iv_var_ptr_t;
  p: ^iv_lts_ptr_t;
  l, pl, q, nl, ln: iv_lts_ptr_t;
  zero, after, created: boolean;
  s, t, u, y: lts_ptr_t;
  d: opnd_ptr_t;
  at: instr_ptr_t;
  ix: iv_iexpr_ptr_t;
  a, an: iv_addr_ptr_t;
  bb: bb_ptr_t;
begin
  v := x^.class^.ivar;
  pv := v;
  if v^.parent <> nil then
    pv := v^.parent;
  case x^.class^.w16 of
    1: begin
      p := addr(x^.ltss);
      l := x^.ltss;
      while l <> nil do begin
        if not ixt_$induction_segment_exists(l) then
          p^ := l^.next
        else
          p := addr(l^.next);
        l := l^.next;
      end;
      if x^.ltss = nil then
        return;
      zero := iv_utils_$expression_is_zero(e);
      if not zero then begin
        ixt_$clear_primary_used_fields(pv);
        ixt_$mark_primary_used_fields(x);
      end;
      pl := pv^.ltss;
      while pl <> nil do begin
        if zero then
          pl^.repl := pl^.sec
        else if pl^.h.used_known or pl^.h.used_unknown then begin
          q := pl^.sec;
          s := q^.lts;
          d := s^.refs;
          if (opnd_bytes_ptr_t(d)^.rrp & 12) <> 0 then begin
            at := utils_ins_$operands_instruction(d);
            after := true;
          end
          else begin
            at := s^.bb^.first;
            while at <> nil do begin
              if not ((at^.opc = 199) or (at^.opc = 203)) then  { label, join_bp }
                exit;
              at := at^.next;
            end;
            after := false;
          end;
          lir_utils_$add_lts_to_lr(8, lir_$new_live_range_for_kind(v^.f48.kind),
                                   s^.bb, t);
          ixt_$create_increment_instruction(e, v^.f48.kind, s, 16, t, 8, at,
                                            after, s^.bb, v^.head^.l54);
          ix := ixr_$find_induction_expr(pv, e, 1);
          nl := create_induction_lts(4, t, v);
          nl^.iexpr := ix;
          nl^.next := ix^.ltss;
          ix^.ltss := nl;
          pl^.repl := nl;
        end;
        pl := pl^.next;
      end;
      l := x^.ltss;
      while l <> nil do begin
        ln := l^.next;
        s := l^.lts;
        if ixt_$induction_segment_exists(l) then
          if not l^.h.stale then begin
            t := l^.cur^.repl^.lts;
            ixt_$replace_segment_references(s, t);
            if not s^.f2.exposed then
              if s^.l28 <> nil then begin
                y := s^.l28;
                while y <> nil do begin
                  if interval_contains_bb(y^.bb, v^.head) then
                    ixt_$replace_segment_references(y, t);
                  y := y^.l28;
                end;
              end;
          end;
        l := ln;
      end;
    end;
    2: begin
      if x^.addrs = nil then
        return;
      l := pv^.ltss;
      while l <> nil do begin
        l^.repl := l^.sec;
        l := l^.next;
      end;
      a := x^.addrs;
      while a <> nil do begin
        an := a^.next;
        if not a^.stale then begin
          t := a^.ilts^.repl^.lts;
          bb := a^.instr^.bb;
          remove_segment_from_operand(a^.opnd);
          remove_segment_from_operand(a^.base);
          if t^.bb = bb then
            u := t
          else begin
            u := utils_$get_exposed_lts(t^.lr, bb, created);
            if created then begin
              utils_$add_birthpoint(t, bb, true);
              if u^.f2.first_in_bb then
                utils_$put_lts_on_final_list(u);
            end;
          end;
          add_operand_to_segment(a^.opnd, u, 16, v^.f48.kind);
          iv_utils_$create_operand_from_expression(a^.base, nil, iv_head^.l54,
                                                   e, 1);
          iv_utils_$delete_induction_addr(a);
        end;
        a := an;
      end;
    end;
    otherwise
      ;
  end;
end;

{ ixt_$cleanup_segment_references - segment s dropped when nothing reads
  it (with its induction lts), or its defining instruction excised when
  its definition has no readers (and s is not exposed and reaches no
  exposed segment; the induction lts deleted when the excision
  happens).  0x23EF5A, 0x7E bytes, no A5. }

procedure ixt_$cleanup_segment_references(
    s: lts_ptr_t); options(val_param); internal;
var
  d: opnd_ptr_t;
  l: iv_lts_ptr_t;
begin
  d := s^.refs;
  l := iv_lts_ptr_t(s^.l24);
  if d = nil then begin
    iv_utils_$delete_induction_lts(l);
    utils_$excise_lts_cleanly(s, true);
  end
  else if s^.l28 = nil then
    if not s^.f2.exposed then
      if (opnd_bytes_ptr_t(d)^.rrp & 12) <> 0 then
        if d^.link = nil then
          if utils_$excise_instruction_if_unconsumed(
                 utils_ins_$operands_instruction(d), true) then
            iv_utils_$delete_induction_lts(l);
end;

{ ixt_$cleanup_induction_expr - x's instantiations' segments (and the
  exposed segments each reaches) cleaned up; an instantiation whose
  segment is gone deleted.  0x23EFD8, 0x7C bytes, no A5. }

procedure ixt_$cleanup_induction_expr(
    x: iv_iexpr_ptr_t); options(val_param); internal;
var
  l, ln, t: iv_lts_ptr_t;
  s, y, yn: lts_ptr_t;
begin
  l := x^.ltss;
  while l <> nil do begin
    ln := l^.next;
    s := l^.lts;
    if ixt_$induction_segment_exists(l) then
      if not s^.f2.exposed then begin
        y := s^.l28;
        while y <> nil do begin
          yn := y^.l28;
          ixt_$cleanup_segment_references(y);
          y := yn;
        end;
      end;
    if ixt_$induction_segment_exists(l) then
      ixt_$cleanup_segment_references(s)
    else begin
      t := l;
      iv_utils_$delete_induction_lts(t);
    end;
    l := ln;
  end;
end;

{ ixt_$instantiate_induction_expr - x (an expression of a secondary
  variable) made a new primary variable: its initial value the
  secondary's plus x's expression, its increment the secondary's,
  multiplier 1, final; a new complex live range given a segment for
  each run of the primary's segments in a block (until one with a
  nonzero step; an exposed one not made in a block the primary is final
  in), each with a confirmed induction lts (the step and increment
  times the secondary's multiplier) that the run's segments record as
  their secondary (those left without one take the one their block's
  run or the segment reaching it has); the initial value moved into it
  at the end of the loop's dominator; birthpoints for the exposed ones
  (join inputs from inside the loop and the start value for a join in
  the loop head), increment instructions between the runs; the new
  variable's list made of the new segments, each once.  The routine's
  change flag set.  0x23F054, 0x54A bytes, no A5: the move from
  iv_incr_opc2's 0 row. }

function ixt_$instantiate_induction_expr(
    x: iv_iexpr_ptr_t): iv_var_ptr_t; options(val_param); internal;
label
  8;
var
  v, pv, nv: iv_var_ptr_t;
  kind: integer;
  lr: lr_ptr_t;
  l, q, last, nl, y, c, a1, a0: iv_lts_ptr_t;
  s, ls, t, f: lts_ptr_t;
  bb, prevbb, dom, bbl: bb_ptr_t;
  created: boolean;
  i: instr_ptr_t;
  k: integer32;
  j: univ_ptr;
  inp: iv_jbi_ptr_t;
  p: ^iv_lts_ptr_t;
begin
  iv_changed := true;
  v := x^.class^.ivar;
  pv := v^.parent;
  kind := v^.f48.kind;
  nv := create_induction_variable(nil, nil, kind);
  nv^.head := pv^.head;
  nv^.incr := iv_utils_$duplicate_expression(v^.incr);
  nv^.init := iv_utils_$canonicalize_expression(
                  iv_utils_$create_add_expression(
                      iv_utils_$duplicate_expression(v^.init),
                      iv_utils_$duplicate_expression(x^.expr)));
  nv^.mult := iv_utils_$create_value_expression(1);
  nv^.w44 := pv^.w44;
  nv^.f48.known := pv^.f48.known;
  nv^.f48.final := true;
  lr := lir_$new_live_range_for_kind(kind);
  bv_$make_live_range_complex(iv_rtn, lr);
  l := pv^.ltss;
  while l <> nil do begin
    l^.sec := nil;
    l := l^.next;
  end;
  l := pv^.ltss;
  dom := pv^.head^.l54;
  prevbb := nil;
  while l <> nil do begin
    s := l^.lts;
    bb := s^.bb;
    last := l;
    q := l^.next;
    while q <> nil do begin
      if q^.lts^.bb <> bb then
        exit;
      if last^.step = nil then
        exit;
      if not iv_utils_$expression_is_zero(last^.step) then
        exit;
      last := q;
      q := q^.next;
    end;
    ls := last^.lts;
    if last <> l then
      if ls^.f2.exposed then
        if s^.f2.final and (bb <> prevbb) then
          goto 8;
    if ls^.f2.exposed then begin
      t := utils_$get_exposed_lts(lr, bb, created);
      if s^.f2.final and (bb <> prevbb) then
        utils_$put_lts_on_final_list(t);
    end
    else if s^.f2.final and (bb <> prevbb) then
      t := utils_$get_final_lts(lr, bb, created)
    else
      t := lir_utils_$add_lts_after_lts(t, 36, bb);
    nl := create_induction_lts(2, t, nv);
    nl^.h.used_known := false;
    y := l;
    while y <> q do begin
      y^.sec := nl;
      y := y^.next;
    end;
    if last^.step <> nil then
      nl^.step := iv_utils_$canonicalize_expression(
                      iv_utils_$create_mul_expression(
                          iv_utils_$duplicate_expression(last^.step),
                          iv_utils_$duplicate_expression(v^.mult)));
    if last^.incr <> nil then
      nl^.incr := iv_utils_$canonicalize_expression(
                      iv_utils_$create_mul_expression(
                          iv_utils_$duplicate_expression(last^.incr),
                          iv_utils_$duplicate_expression(v^.mult)));
  8:
    prevbb := bb;
    l := q;
  end;
  l := pv^.ltss;
  while l <> nil do begin
    if l^.sec = nil then begin
      c := l;
      while c^.sec = nil do begin
        a1 := c;
        a0 := c^.next;
        while (a1^.sec = nil) and (a0 <> nil) do begin
          if a0^.lts^.bb <> c^.lts^.bb then
            exit;
          a1 := a0;
          a0 := a0^.next;
        end;
        s := a1^.lts;
        if s^.f2.exposed then
          if s^.l44 <> nil then
            s := s^.l44;
        if iv_lts_ptr_t(s^.l24) = c then
          bug_check('IV_$instantiate_induction_expr: No Secondary for LTS %3WD.%2ZWD%.',
                    s^.lr^.num, s^.f2);
        c := iv_lts_ptr_t(s^.l24);
      end;
      l^.sec := c^.sec;
    end;
    l := l^.next;
  end;
  f := utils_$get_final_lts(lr, dom, created);
  i := lir_$optimizer_new_instruction(find_last_instruction(dom),
                                      iv_incr_opc2[0, kind], false);
  for k := 1 to i^.h.nopnds do
    i^.opnds[k].h.num := k;
  add_operand_to_segment(addr(i^.opnds[2]), f, 8, kind);
  iv_utils_$create_operand_from_expression(addr(i^.opnds[1]), i, dom,
                                           nv^.init, kind);
  l := pv^.ltss;
  while l <> nil do begin
    s := l^.lts;
    bbl := s^.bb;
    nl := l^.sec;
    if bbl = nl^.lts^.bb then
      if s^.f2.exposed then begin
        i := utils_ins_$operands_instruction(s^.refs);
        if i^.opc <> 203 then           { join_bp }
          utils_$add_birthpoint(get_secondary_segment(s^.l44), bbl, true)
        else begin
          j := fg_utils_$generate_join_birthpoint(
                   get_secondary_segment(i^.opnds[1].lts),
                   get_secondary_segment(i^.opnds[2].lts));
          inp := iv_jbi_ptr_t(i^.opnds[3].link);
          while inp <> nil do begin
            if interval_contains_bb(inp^.lts^.bb, pv^.head) then
              fg_utils_$add_jbi(j, get_secondary_segment(inp^.lts));
            inp := inp^.next_op;
          end;
          if s^.bb = pv^.head then
            fg_utils_$add_jbi(j, f);
        end;
      end
      else if l^.step <> nil then
        if l^.next^.sec <> nl then
          ixt_$create_increment_instruction(nl^.step, kind,
              l^.next^.sec^.lts, 48, nl^.lts, 4,
              utils_ins_$operands_instruction(s^.refs), false, bbl, dom);
    l := l^.next;
  end;
  p := addr(nv^.ltss);
  l := pv^.ltss;
  while l <> nil do begin
    nl := l^.sec;
    if not nl^.h.used_known then
      if nl^.lts^.bb = l^.lts^.bb then begin
        nl^.h.used_known := true;
        p^ := nl;
        p := addr(nl^.next);
      end;
    l := l^.next;
  end;
  p^ := nil;
  ixt_$instantiate_induction_expr := nv;
end;

{ ixt_$process_secondary_induction_variable - secondary v strength
  reduced: of each address class the induction expression whose
  instantiation the most primary segments use (known, then unknown)
  instantiated and replaced by the new variable (iv_zero), the others
  used replaced by their difference from it; then the expression class
  likewise when what it saves (its uses less those of zero expressions,
  plus the multiply's cost) reaches the primary's adds; v deleted.
  0x23F5E0, 0x374 bytes, no A5. }

procedure ixt_$process_secondary_induction_variable(
    v: iv_var_ptr_t); options(val_param); internal;
var
  pv: iv_var_ptr_t;
  c, bc: iv_class_ptr_t;
  x, best: iv_iexpr_ptr_t;
  nk, nu, bk, bu, total, n, z: integer32;
  d: iv_expr_ptr_t;
begin
  pv := v^.parent;
  c := v^.classes;
  while c <> nil do begin
    if c^.w16 = 2 then begin
      best := nil;
      bk := 0;
      bu := bk;
      x := c^.iexprs;
      while x <> nil do begin
        ixt_$clear_primary_used_fields(pv);
        ixt_$mark_primary_used_fields(x);
        ixt_$count_primary_used_fields(pv, nk, nu);
        if (best = nil) or (bk < nk) or ((bk = nk) and (bu < nu)) then begin
          best := x;
          bk := nk;
          bu := nu;
        end;
        x := x^.next;
      end;
      if best <> nil then begin
        discard(ixt_$instantiate_induction_expr(best));
        ixt_$replace_induction_expr(best, iv_zero);
        ixt_$cleanup_induction_expr(best);
        x := c^.iexprs;
        while x <> nil do begin
          if x <> best then begin
            ixt_$clear_primary_used_fields(pv);
            ixt_$mark_primary_used_fields(x);
            ixt_$count_primary_used_fields(pv, nk, nu);
            if (nk > 0) or (nu > 0) then begin
              d := iv_utils_$canonicalize_expression(
                       iv_utils_$create_sub_expression(
                           iv_utils_$duplicate_expression(x^.expr),
                           iv_utils_$duplicate_expression(best^.expr)));
              ixt_$replace_induction_expr(x, d);
              ixt_$cleanup_induction_expr(x);
              iv_utils_$delete_expression(d);
            end;
          end;
          x := x^.next;
        end;
      end;
    end;
    c := c^.next;
  end;
  ixt_$clear_primary_used_fields(pv);
  c := v^.classes;
  while c <> nil do begin
    if c^.w16 = 1 then
      ixt_$mark_primary_used_fields(c^.iexprs);
    c := c^.next;
  end;
  ixt_$count_primary_used_fields(pv, nk, nu);
  total := nu + nk;
  bc := nil;
  bk := 0;
  bu := bk;
  c := v^.classes;
  while c <> nil do begin
    if c^.w16 = 1 then begin
      ixt_$clear_primary_used_fields(pv);
      ixt_$mark_primary_used_fields(c^.iexprs);
      ixt_$count_primary_used_fields(pv, nk, nu);
      if (bc = nil) or (bk < nk) or ((bk = nk) and (bu < nu)) then begin
        bc := c;
        bk := nk;
        bu := nu;
      end;
    end;
    c := c^.next;
  end;
  if bc <> nil then begin
    ixt_$clear_primary_used_fields(pv);
    ixt_$mark_primary_used_fields(bc^.iexprs);
    ixt_$count_primary_used_fields(pv, nk, nu);
    n := nk + nu;
    ixt_$clear_primary_used_fields(pv);
    c := v^.classes;
    while c <> nil do begin
      if c^.w16 = 1 then
        if iv_utils_$expression_is_zero(c^.iexprs^.expr) then
          ixt_$mark_primary_used_fields(c^.iexprs);
      c := c^.next;
    end;
    ixt_$count_primary_used_fields(pv, nk, nu);
    z := nk + nu;
    n := n - z;
    if ixt_$multiply_cost(v, total) + n >= pv^.w44 then begin
      discard(ixt_$instantiate_induction_expr(bc^.iexprs));
      ixt_$replace_induction_expr(bc^.iexprs, iv_zero);
      ixt_$cleanup_induction_expr(bc^.iexprs);
      c := v^.classes_last;
      while c <> nil do begin
        if c^.w16 = 1 then
          if c <> bc then begin
            ixt_$clear_primary_used_fields(pv);
            ixt_$mark_primary_used_fields(c^.iexprs);
            ixt_$count_primary_used_fields(pv, nk, nu);
            if (nk > 0) or (nu > 0) then begin
              d := iv_utils_$canonicalize_expression(
                       iv_utils_$create_sub_expression(
                           iv_utils_$duplicate_expression(c^.iexprs^.expr),
                           iv_utils_$duplicate_expression(bc^.iexprs^.expr)));
              ixt_$replace_induction_expr(c^.iexprs, d);
              ixt_$cleanup_induction_expr(c^.iexprs);
              iv_utils_$delete_expression(d);
            end;
          end;
        c := c^.prev;
      end;
    end;
  end;
  iv_utils_$delete_induction_variable(v);
end;

{ ixt_$process_primary_induction_variable - v's secondaries with an
  initial value processed, last first; v's classes deleted.  0x23F954,
  0x58 bytes, no A5. }

procedure ixt_$process_primary_induction_variable(
    v: iv_var_ptr_t); options(val_param); internal;
var
  w, p: iv_var_ptr_t;
  c, n: iv_class_ptr_t;
begin
  w := v^.children_last;
  while w <> nil do begin
    p := w^.l54;
    if w^.init <> nil then
      ixt_$process_secondary_induction_variable(w);
    w := p;
  end;
  c := v^.classes;
  while c <> nil do begin
    n := c^.next;
    iv_utils_$delete_induction_class(c);
    c := n;
  end;
end;

{ ixt_$process_induction_transformations - each primary variable
  processed, up to the last there was when it began.  0x23F9AC, 0x32
  bytes, no A5. }

procedure ixt_$process_induction_transformations; internal;
var
  v, last: iv_var_ptr_t;
begin
  v := iv_vars;
  last := iv_vars_last;
  while v <> nil do begin
    ixt_$process_primary_induction_variable(v);
    if v = last then
      exit;
    v := v^.next;
  end;
end;

{ iv_$locate_induction_variables_at_loop_start - the walk's entry into
  the loop headed by bb: the enclosing loop's state pushed (a 20-byte
  record), bb made the loop, its candidates found.  0x23F9DE, 0x68
  bytes (`new'). }

procedure iv_$locate_induction_variables_at_loop_start(
    var bb: bb_ptr_t);
var
  b: bb_ptr_t;
  f: iv_state_ptr_t;
begin
  b := bb;
  new(f);
  f^.prev := iv_states;
  f^.head := iv_head;
  f^.vars := iv_vars;
  f^.vars_last := iv_vars_last;
  iv_states := f;
  iv_head := b;
  iv_vars := nil;
  iv_vars_last := nil;
  ivr_$locate_induction_candidates(b);
end;

{ iv_$locate_induction_variables_for_basic_block - the candidates
  propagated into a block of the loop.  0x23FA46, 0x24 bytes. }

procedure iv_$locate_induction_variables_for_basic_block(
    var bb: bb_ptr_t);
begin
  ivr_$propagate_induction_into_basic_block(bb);
end;

{ iv_$locate_induction_variables_at_loop_end - the walk's exit from the
  loop headed by bb: its variables finalized; when some remain and the
  loop is not irreducible (+18 bit 5), its blocks scanned for induction
  expressions and the transformations made; the enclosing state popped
  (`dispose').  0x23FA6A, 0x90 bytes: the walk's routines passed as
  constants by address (nil, scan, nil), placed after the routine. }

procedure iv_$locate_induction_variables_at_loop_end(
    var bb: bb_ptr_t);
var
  b, t: bb_ptr_t;
  f: iv_state_ptr_t;
begin
  b := bb;
  ivr_$finalize_induction_variables(b);
  if iv_vars <> nil then
    if not b^.f.irreducible then begin
      t := b;
      iv_$walk_basic_blocks_in_order(t, nil,
          addr(ixr_$scan_basic_block_for_induction_expressions), nil);
      ixt_$process_induction_transformations;
    end;
  f := iv_states;
  iv_head := iv_states^.head;
  iv_vars := iv_states^.vars;
  iv_vars_last := iv_states^.vars_last;
  iv_states := iv_states^.prev;
  dispose(f);
end;

{ iv_$build_nested_reverse_postorder_lists - each interval head's
  members (+138, chained at +142) listed in the routine's walk order
  (+72, at +114), put first; blocks in no interval on iv_intervals.
  0x23FB02, 0x5E bytes, no frame. }

procedure iv_$build_nested_reverse_postorder_lists(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  b, h: bb_ptr_t;
begin
  iv_intervals := nil;
  b := rtn^.bbs;
  while b <> nil do begin
    if b^.f.distinguished_entry then
      iv_bb_v_ptr_t(b)^.first138 := nil;
    b^.next142 := nil;
    b := b^.next;
  end;
  b := rtn^.bbs72;
  while b <> nil do begin
    h := b^.l70;
    if h <> nil then begin
      b^.next142 := iv_bb_v_ptr_t(h)^.first138;
      iv_bb_v_ptr_t(h)^.first138 := b;
    end
    else begin
      b^.next142 := iv_intervals;
      iv_intervals := b;
    end;
    b := b^.next114;
  end;
end;

{ get_increment_from_induction - the step a segment's defining
  instruction adds to the operand of its variable: an add's other
  operand, a sub's or rsub's negated, a load's or store's displacement,
  0 for a copy (neg, move and the like); nil otherwise (a bug).
  0x23FB60, 0x1B4 bytes, no A5. }

function get_increment_from_induction(
    l: iv_lts_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  i: instr_ptr_t;
  o: opnd_ptr_t;
  k: integer32;
  r: iv_expr_ptr_t;
  m: iv_lts_ptr_t;
begin
  o := nil;
  i := utils_ins_$operands_instruction(l^.lts^.refs);
  for k := 1 to l^.lts^.refs^.h.num - 1 do
    if i^.opnds[k].h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
      m := iv_lts_ptr_t(i^.opnds[k].lts^.l24);
      if m <> nil then
        if m^.ivar = l^.ivar then begin
          o := addr(i^.opnds[k]);
          exit;
        end;
    end;
  if o = nil then
    bug_check('IV_$get_increment_from_induction: no source operand found%.');
  case i^.opc of
    137, 79:                            { addi, add }
      if o^.h.num = 1 then
        r := iv_utils_$create_expression_from_operand(addr(i^.opnds[2]), nil)
      else
        r := iv_utils_$create_expression_from_operand(addr(i^.opnds[1]), nil);
    138, 81:                            { subi, sub }
      r := iv_utils_$canonicalize_expression(
               iv_utils_$create_neg_expression(
                   iv_utils_$create_expression_from_operand(
                       addr(i^.opnds[1]), nil)));
    83:                                 { rsub }
      r := iv_utils_$canonicalize_expression(
               iv_utils_$create_neg_expression(
                   iv_utils_$create_expression_from_operand(
                       addr(i^.opnds[2]), nil)));
    221, 109, 106, 105, 104, 218, 103, 217:   { the loads }
      r := iv_utils_$create_expression_from_operand(addr(i^.opnds[1]), nil);
    228, 124, 121, 120, 119, 118:     { the stores }
      r := iv_utils_$create_expression_from_operand(addr(i^.opnds[2]), nil);
    135, 77, 144, 126, 116, 75:       { negi, neg, copys, mtfp, mffp, move }
      r := iv_utils_$create_value_expression(0);
    otherwise
      bug_check('IV_$get_increment_from_induction: invalid increment instruction found%.');
  end;
  get_increment_from_induction := r;
end;

{ recompute_for_oli - after the transformations, the variables of the
  joins (kept, +2 bit 6) at the head of bb recomputed from the code as
  it now is, for oli: in a loop with a tail block (+74) their increment
  and initial value dropped; else an initial value that is not a
  constant made the expression of the final segment of its live range
  in the nearest block up bb's l54 chain, each segment's non-constant
  step that of its defining instruction, and a non-constant increment
  (and each segment's incr) the steps' running sum.  0x23FD98, 0x1A8
  bytes (loads A5: the walk calls it). }

procedure recompute_for_oli(
    var bb: bb_ptr_t);
var
  b, c: bb_ptr_t;
  i: instr_ptr_t;
  l: iv_lts_ptr_t;
  v: iv_var_ptr_t;
  lr: lr_ptr_t;
  f: lts_ptr_t;
  acc: iv_expr_ptr_t;
begin
  b := bb;
  i := b^.first;
  while i <> nil do begin
    if (i^.opc <> 203) and (i^.opc <> 199) then   { join_bp, label }
      exit;
    if i^.opc = 203 then
      if i^.h.b2_6 then begin
        l := iv_lts_ptr_t(i^.opnds[1].lts^.l24);
        if l <> nil then begin
          v := l^.ivar;
          if b^.l74 <> nil then begin
            iv_utils_$delete_expression(v^.incr);
            iv_utils_$delete_expression(v^.init);
          end
          else begin
            lr := i^.opnds[1].lts^.lr;
            if v^.init <> nil then
              if v^.init^.kind <> iv_value then begin
                iv_utils_$delete_expression(v^.init);
                c := b^.l54;
                f := nil;
                while (c <> nil) and (f = nil) do begin
                  f := utils_$find_final_lts(lr, c);
                  c := c^.l54;
                end;
                if f = nil then
                  bug_check('IV_$recompute_for_OLI: no creating LTS for initial value found%.');
                v^.init := iv_utils_$create_expression_from_lts(f, nil);
              end;
            l := v^.ltss;
            while l <> nil do begin
              if l^.step <> nil then
                if l^.step^.kind <> iv_value then begin
                  iv_utils_$delete_expression(l^.step);
                  l^.step := get_increment_from_induction(l);
                end;
              l := l^.next;
            end;
            if v^.incr <> nil then
              if v^.incr^.kind <> iv_value then begin
                iv_utils_$delete_expression(v^.incr);
                acc := iv_utils_$create_value_expression(0);
                l := v^.ltss;
                while l <> nil do begin
                  if l^.step <> nil then
                    acc := iv_utils_$canonicalize_expression(
                               iv_utils_$create_add_expression(acc,
                                   iv_utils_$duplicate_expression(l^.step)));
                  iv_utils_$delete_expression(l^.incr);
                  l^.incr := iv_utils_$duplicate_expression(acc);
                  l := l^.next;
                end;
                v^.incr := acc;
              end;
          end;
        end;
      end;
    i := i^.next;
  end;
end;

{ iv_$process_routine - the IV phase (unless at_backend_switches' sw15):
  the state reset, the intervals listed; each outermost interval head
  walked (loop start, each block, loop end); when something was
  instantiated, unless sw14, the CSEs recomputed, copies eliminated and
  adds and subs tried for autoincrement in walk order, the global data
  flow walk redone and the variables recomputed for oli.  0x23FF80,
  0x1D2 bytes: the walks' routines passed as constants by address,
  placed after the routine (0x240152..). }

procedure iv_$process_routine(
    rtn: rtn_ptr_t);
var
  b, t: bb_ptr_t;
  i: instr_ptr_t;
begin
  lir_utils_$sanity_check(rtn);
  if at_backend_switches.sw15 then
    return;
  iv_rtn := rtn;
  iv_bb80 := rtn^.bb80;
  iv_changed := false;
  iv_7b4 := 1;
  iv_7b6 := 1;
  iv_head := nil;
  iv_vars := nil;
  iv_vars_last := nil;
  iv_states := nil;
  iv_790 := nil;
  iv_free_expr := nil;
  iv_free_var := nil;
  iv_free_class := nil;
  iv_free_addr := nil;
  iv_free_iexpr := nil;
  iv_free_lts := nil;
  iv_zero := iv_utils_$create_value_expression(0);
  iv_$build_nested_reverse_postorder_lists(rtn);
  b := iv_intervals;
  while b <> nil do begin
    if b^.f.distinguished_entry then begin
      t := b;
      iv_$walk_basic_blocks_in_order(t,
          addr(iv_$locate_induction_variables_at_loop_start),
          addr(iv_$locate_induction_variables_for_basic_block),
          addr(iv_$locate_induction_variables_at_loop_end));
    end;
    b := b^.next142;
  end;
  if iv_changed then begin
    if not at_backend_switches.sw14 then begin
      com_$compute_cses(rtn, 0);
      b := rtn^.bbs72;
      while b <> nil do begin
        i := b^.first;
        while i <> nil do begin
          if instruction_attributes[i^.opc].b6_0 then
            tr_utils_$attempt_copy_elimination(rtn, i)
          else if (i^.opc = 79) or (i^.opc = 81) then   { add, sub }
            discard(tr_utils_$attempt_autoincrement(rtn, i));
          i := i^.next;
        end;
        b := b^.next114;
      end;
    end;
    df_utils_$global_walk(rtn, rtn^.l192, 0, 0);
    b := iv_intervals;
    while b <> nil do begin
      if b^.f.distinguished_entry then begin
        t := b;
        iv_$walk_basic_blocks_in_order(t, addr(recompute_for_oli), nil, nil);
      end;
      b := b^.next142;
    end;
  end;
end;
