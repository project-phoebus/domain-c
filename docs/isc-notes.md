# The ISC: notes for rebuilding the generator

The owner decided (docs/questions.md 151) that the generated ISC units
(`moon_unit/.../iscg_input/`: isc_pass_1_main, isc_pass_2_main, isc_vars,
isc_pattern_matcher, isc_debug, isc_main) are to be rebuilt as a generator
and its input, not translated routine by routine.  This file collects what
the hand-written units' translation (translator PD, 2026-11-11) showed
about the generated side.  Everything here is read off cc.a88k; what is
a guess says so.

## The two passes

- **Pass 1** is top-down over an IL tree.  `pass_1(node, inh, depth,
  permissible)` (isc_pass_1_main 0x0F04BC; isc.pvt.pas) returns a list
  of candidate solutions (isc_solution_fields.ins.pas's
  `solution_list_t`) whose kinds are in `permissible` (a longword set
  of `solution$t`, kind k bit k).  The caller chooses one
  (`choose_one_solution`, or `choose_one_cse_solution` for a CSE) and,
  when the inherited attributes ask (`inh^.f38.preserve`), copies it
  into the preserved heap (`preserve_solution`).  isc_pass_1_main's 186
  named routines are the matcher's entry points by IL kind and
  operator, named `isc_<kind>[_<operator>]` (isc_tree_node_add_top,
  isc_assign_node_div_by_aop, isc_cbranch_node, isc_fortran_symbol,
  ...): the names follow `il$t` (isc_enumeration.ins.pas).
- **Pass 2** is bottom-up over the chosen solution: `pass_2(sol, depth)`
  (isc_pass_2_main 0x18C588, its one named routine) returns at once for
  nil or a solution already done (`f114.pass_2_done`); if the solution
  has a `chain` (+88) pass 2 goes there instead (copying `eval_order`
  to it when the chain's kind is 22 `solution$proper_subtree`);
  otherwise its children (+116, `nchildren` at +114, at most 5) in
  `eval_order` (1 left to right, 2 right to left; anything else is
  printed "ERROR: unknown evaluation order"); then base_reg and
  index_reg are reset to `isc_user_routines_31c`, +0, +16, +20, +24
  cleared, and the **pass-2 action of the solution's rule** is called.
- **Calling convention of the pass-2 actions:** isc_pass_2_main keeps a
  table of routine pointers in its data, indexed by the rule
  (`move.w (112,A2),D2; ext.l; lsl.l #2; movea.l (-4,A5,D0.l),A0; jsr
  (A0)` with A5 0x47F788): entry `rule` at A5 - 4 + 4 * rule.  Each
  action is called with four longword arguments: (sol, sol^.chain, sol,
  sol) (pushed as fp-4 = sol, sol, fp-8 = chain, sol).  Then
  `pass_2_done` is set.
- The hand-written handlers the patterns delegate to:
  `pass_1_isc_call(node, rclass, inh, depth)` and `pass_2_isc_call(node,
  async, ftn_io, pfm, inh, depth)` for the call operators (the actions
  of isc_tree_node_isc_call_top and its siblings pass rclass 4 and depth
  0); `pass_1_cse_parent_ob(parent, tree, inh)`, `pass_1_cse_use_ob(use,
  tree, inh)`, `pass_2_cse_parent_ob(parent, stmt)`,
  `pass_2_cse_use_ob(use, stmt)` and the `pass_[12]_cse_{parent,use}_
  <field>` accessors for the CSE nodes (isc_routine_externs.ins.pas).

## The records

- **Inherited attributes** (isc_attribute_records.ins.pas,
  `inherited_attributes_t`, 40 bytes; since translator RN3 its fields
  carry isc_print_il_node's names, docs/questions.md 271, and the names
  below are the earlier readings; `new_inherited_attributes(heap,
  node)`: node and stmt := node, precision and available 32, arith 1
  arith_integer): +4 the statement's top, +12 the statement, +20 the call
  being built, +24/+28 precision and available bits, +32 the source line
  and the statement's index (copied as one longword), +38 the arithmetic
  (`arith$t`), +39 bits (b5: a call's routine operand; b2 `preserve`).
  lir's lir_3b80 is the same record (lir_$complete_top_level_node_
  inherited_attrs fills +4, +32, +34).
- **Solutions** (isc_solution_fields.ins.pas, `isc_solution_t`, 432
  bytes; backend.ins.pas's `solution_t` is batch A's view of the same;
  since translator RN3 both name their fields after dump_solution's
  attributes, docs/questions.md 267, and the names below are the
  earlier readings):
  `new_solution(heap, kind, nchildren, inh, sym, w98)` (isc_main
  0x0D9318) sets kind (+108), nchildren (+114), inh (+104), sym (+100),
  w98 (+98), eval_order 1 (+96 as the longword 16#10000), +77 := 32, +82
  bits 4 and 2, base_reg and index_reg := isc_user_routines_31c.  The
  field names isc_cse_handling's accessors give: obj_w_name +0,
  base_reg +4, index_reg +8, live_range +20, bits_known +32,
  bits_trusted +36, disp and lit_value +48, fp_reg_max .. ip_reg_result
  +58..+72 (words, the registers a solution needs and leaves),
  embedded_sr_temp +81 bit 1, has_sym_disp +82 bit 7, uses_disp +84
  bit 6, uses_index_reg +84 bit 5, code_bytes +92, delay +94,
  eval_order +96, memory_refs +110 (the costs choose_one_cse_solution
  compares: code_bytes + delay, then memory_refs).  +112 is the **rule**
  (the pattern's number: pass 2's action index), +115 bits: 7 a
  preserve copy, 4 preserved, 3 pass_2_done, 6 and 5 read by isc_to_lir
  and preserve_solution.  +116..+132 the five children; +352..+431
  twenty solution pointers belonging to the rule (the "solution fields"
  proper: `fields`).
- **Which rules have extra fields:** preserve_solution (isc_main
  0x0D94A6) tests a byte table in isc_main's data at A5 - 1 + rule (bit
  7 set: the rule's fields must be copied too), then switches on the
  rule, by the offsets of the pointers it copies: 12, 179, 181, 274,
  275, 290, 292, 301, 304, 344, 375, 377..379, 418, 445, 448, 474, 542,
  548, 549 +352 and +356; 262, 479, 550 +356; 114, 115 +358 (not a
  longword boundary: the rules' fields are laid out per rule, a variant
  record in the original, not one array); 177 +356..+368; 186 +360; 422
  +352..+364; 423 +352..+376.  The generator must emit this table and
  switch from the pattern description (isc_solution_t's `fields` is
  only an approximation of the union).
- **Solution lists:** an 8-byte head (first, last) and 8-byte cells (sol,
  next), from the ISC heap (isc_user_routines +0x23C);
  solution_list$preserve copies into the preserved heap (+0x224).

## The read-only tables

- `isc_tool_generated_readonly_tables` (0x2BC13C, 3264 bytes): by its
  name the generator's.  It begins with words in 0..23 (23, 14, 14, 14,
  5, 5, 5, 14, 15, 14, 5, ...): solution kinds (5 address_mode, 14
  literal_32_bits, 11 ip_reg, 8..10 the floating registers, 23 void).
  **A guess:** the kind each rule's solution has, by rule number (1632
  words would cover more rules than the ~550 preserve_solution names),
  or several such per-rule tables in a row; the tail is zeros.  Not
  read further: no hand-written unit reads it.
- `isc_readonly_tables` (0x2BCDFC, 3120 bytes): hand-maintained tables
  of the ISC (the name lacks "tool_generated").  It begins with zeros,
  16#FFFFFFFF, then pairs like 1 1 3 2 5 4 7 6 / 1 1 1 1 13 12 15 14
  (the shapes of relational-operator inversion and operand-swap maps),
  byte masks (00FF FF00 ...), and ends with runs of 8, 16, 32 (bits by
  some class).  Not read further.

## isc_main

isc_main.pas (moon_unit, 18 named routines, 4684 bytes in a span of 8684)
is ordinary code, translated by translator PD2: the solution and
inherited-attribute allocators, preserve_solution, the solution lists,
apply_pass_1_and_choose_to_list, apply_pass_2_to_list, and the phase's
entry points (isc_$begin_compilation, isc_$begin_routine,
isc_$end_routine, isc_$end_compilation, isc_$initialize_routine,
isc_$process_statement).  Its span holds 3238 bytes after
isc_$end_routine (between 0x0DA5B4 and 0x0DB25A) that no .blocks record
names: isc_$end_routine's strings and il$t's identifier table
(0x0DA74A), no code.  What it shows of the generated side:

- Its one table, im_rule_has_fields (isc_main's data +0x0, a boolean by
  rule 1..563), is the generator's: true for the 30 rules
  preserve_solution names (12, 114, 115, 177, 179, 181, 186, 262, 274,
  275, 290, 292, 301, 304, 344, 375, 377..379, 418, 422, 423, 445, 448,
  474, 479, 542, 548..550).  So there are 563 rules (pass 2's action
  table at isc_pass_2_main's A5 - 4 has an entry per rule).
  preserve_solution copies the rule's fields only for a solution with a
  chain (+88); a solution without one has its children copied instead.
- isc_$process_statement runs pass 1 with every solution kind but none
  permitted (16#FFFFFE), choose_one_solution, pass_2(sol, 0) between
  isc_to_lir's begin_statement and end_statement, the ISC heap marked
  and released around the statement.  isc_$begin_routine walks the
  routine's statements from rtn_t's +20 through +8 to the BLK_END_NODE
  (149), each under fresh attributes (line +20, index +43..+44).
  apply_pass_1_and_choose_to_list follows +8 only through the
  statement kinds (an assignment of any operator but 12, 17, 18; 228,
  149, 148, 141, 214, 215, 142, 139, 227, 144, 150, 224, 225, 151).
- The generated units keep counts in isc_user_routines' data (the
  metering under sw3 names them): +0x300 calls_to_pass_1
  (isc_pass_1_main), +0x2FC calls_to_pass_2 (isc_pass_2_main), +0x2F8
  calls_to_pattern_matcher (isc_pattern_matcher), +0x2F4
  max_solutions_for_one_il_node and +0x350 the il$t that had it, +0x2EC
  the solutions made from the ISC heap during a statement
  (new_solution, duplicate_solution) with +0x2E8 the maximum and +0x2F0
  its statement; +0x9C a boolean by IL node kind (the reference kinds:
  137, 138, 143, 145..147, 164, 171, 175, 189, 205), read by
  isc_pass_1_main.  isc_$begin_compilation calls isc_pass_1_main's
  isc_pass_1_begin_compilation (0x0EFE96).
- Traces: sw13 sets isc_user_routines_356 and asks on the terminal for
  the source line to trace (+0x304; -1 every line), sw12 sets _354; a
  statement on another line runs with both cleared.

## isc_user_routines: what the patterns call (translator PD2)

isc_user_routines.pas (138 routines, all translated; headings in
isc_routine_externs.ins.pas) is the library the generated pattern
actions call.  What its shape says about the generator's input:

- **Attribute functions.**  The patterns compute synthesized attributes
  through small functions of the operator (an `il$t' element) and the
  operands' attributes: `bits_known_function(op, a, b)' and
  `bits_trusted_function(op, a, b)' (jump tables over il_add_top ..
  il_unsigned_mod_top, 105..173; an operator outside the table is a
  pattern bug, printed with il$t's name table and bug_check'ed unless
  traced), `evaluation_order_function(op, n1, n2, legal)' with
  `legal_evaluation_orders(s1, s2)' (bit 0 left to right, bit 1 right
  to left: what the solution's `eval_order', +96, receives),
  `available_precision_function(sol)', `not_permissible_function(node,
  w, permissible)' (a `solution$set_t': integer register bit 11,
  floating register bit 8), `bits_to_alignment(known, trusted)'.
  Names ending in `_function' are the attribute-grammar's attribute
  evaluators; the generator's description must name them per
  attribute (bits_known, bits_trusted, eval_order, available
  precision, permissible kinds).
- **Predicates** (the patterns' guards): il_node_has_integer_value,
  il_node_has_float_value, il_node_is_literal_sequence_of_ones/_zeroes,
  is_sequence_of_ones(_right_justified), is_sequence_of_zeroes,
  is_power_of_2, is_all_zeroes, is_device, is_in_range,
  in_interval_at_compile_time(size, s1, s2), verify_bits and
  verify_any_bits(known, trusted, position, width, expected),
  invertible_in_sp/_dp, is_a_register_solution, similar_solutions and
  clearly_dominates (the matcher's pruning of candidate lists: equal
  costs and results, or no worse in every cost), expression_has_side_
  effects, return_value_needs_assign_node,
  lir_$can_encode_as_immediate_postincrement.
- **Values**: il_node_to_integer_value, integer32_from_char_string_ob,
  sign_extend, log_2, number_of_{left,right}most_{zeroes,ones},
  number_of_one_bits, length_of_sequence_of_{ones,zeroes},
  make_bit_mask_1(n, lsb), make_bit_mask_2(msb, lsb),
  compute_number_loaded_bytes(n, known, trusted),
  fetch_precision_to_bits_trusted, pc_relative_literal_size_to_bits_
  trusted, precision_from_il_node, arithmetic_from_il_node,
  rlen_code_from_type_node, isc_$precision_from_rlen_and_size,
  alignment_from_il_node (and alignment_from_sr_info for strength-
  reduced variables), bits_trusted_of_symbol, get_kind_of_home_
  solution, solution_kind_of_symbol, il_kind_function and
  get_uparrow_dot_kind (a node's kind: the matcher's dispatch).
- **Solution constructors** (the actions' results): create_solution_
  for_{address_mode, case_jump_base, ip_reg, ip_reg_scaled, fp_reg,
  fp_reg_pair, fp_reg_quad, literal_32_bits} and _fp_reg(_pair)_
  physical, all from the ISC heap (isc_user_routines +0x23C) with no
  children; duplicate_address_mode(_adding_byte_offset),
  ip_reg_to_ip_reg_scaled / ip_reg_scaled_to_ip_reg,
  high_/low_half_of_fp_reg_pair/_quad (kinds 2, 3, 9), address_mode_
  for_{expression_temporary, single_value, double_value,
  integer32_value} (literals in the pool, from literal_base_register),
  find_well_known_literal_solution (isc_literal_solutions, +0x254, for
  -1..32; made by well_known_literal: kind 14, bits all known and
  trusted, disp the value).  The solution fields the constructors and
  the address modes set: kind (+108), bits_known (+32), bits_trusted
  (+36), disp (+48), base_reg (+4) and index_reg (+8) (solution
  pointers: isc_user_routines_31c for none, +0x340 the frame,
  literal_base_register for literals), obj_w_name (+0), has_sym_disp
  (+82 bit 7), +84 bits 7 and 6 (uses_disp) and 5 (uses_index_reg),
  physical (+83 bit 3) and reg (+78) for physical registers, shift
  (+79) of a scaled register, +76/+77 a register field's position and
  width, l40/l44/w56 (+40, +44, +56) of an integer literal's address
  mode (the value, -1, 4).
- **Side effects** the patterns request: side_effect_symbol_fill_in_
  size (a symbol's size), side_effect_set_var_$address_exposed
  (attribute bit 12), set_isc_is_cse_on_live_range_if_local_cse,
  make_expression_temporary / possibly_make_expression_temporary /
  cs_temp_to_var_name (temporaries: kind 109 variables in il_180's
  block, numbered by +0x310), value_top_over (a VALUE_TOP tree),
  widen_char_string_ob, process_eval_node (an EVAL_NODE's children
  given to isc_$process_statement), warning_unaligned_atomic_access.
- **Errors**: pattern_match_error(pme, kind, math, line), pme 1..15:
  1 scalar_aop mixing registers, 2 and 3 byte-aligned longword and
  word accesses (written, never fatal), 4 double floating registers, 5
  FP under [no_fp], 7 set_sr on the AT, 8 an unsupported f_math_top
  (math kinds 0..15: abs, sin, cos, tan, log, log10, exp, atan, atan2,
  sqrt, trunc, nint, max, min, conjg, aimag), 9 an unsupported node,
  10 an invalid load/store precision, 11 a compare operator, 12
  enable/disable/set_sr, 13 a processor register, 14 floating point,
  15 an unaligned floating access; 6 and others "Unexpected pme$
  value".  The generator's `pme$' enumeration is these.
- **Home solutions** (register allocation candidacy): local_initialize_
  symbol decides a symbol's home (see its comment: vat 5 or declared
  candidates; volatile, structure, address-taken, aliased, wider than
  32 bits (64/128-bit reals when +0x358), kinds 127 and 133 excluded)
  and gives it an integer, floating, pair or quad register solution
  with fresh live ranges (pairs for the complex classes 6 and 13).
  The variable attribute bits (vatt_set_to_string's names): 0
  volatile, 1 atomic, 2 physical, 3 dev_read, 4 dev_write, 5
  processor_reg, 6 initialized, 7 forloopindex, 8 uplevel, 9
  loop_trip_count, 10 is_formal_parameter, 14 temporary, 15 register,
  16 bss, 17 strength_reduction_temp, 18 allocated, 20 induction, 21
  nooptimize, 22 force_to_memory, 24 marked_init_local_symbols, 25
  isc_was_here (the home made), 26 is_a_register_candidate, 27
  seen_in_ra, 28 mentioned_in_sym_disp, 29 spilled_to_memory.
- **Enumerations whose name tables the unit writes**: the IL node kinds
  (an_kind_t, 237), tree operators (90: NOP_TOP .. ILLEGAL_TOP),
  assignment operators (38: SCALAR_AOP .. ILLEGAL_AOP), il$t (178),
  solution$t (25), arith$t (6), arg_loc_t (7), the FORTRAN data
  classes (14: NONE, XBINTEGER, ..., XDPCOMPLEX); the phase bits
  (phase_set_to_string: 0 atomic_address .. 22 local_cse) and type
  attribute bits (type_attr_set_to_string: 0 volatile .. 18
  overlay_set) as written names.
- **Tables**: isc_readonly_tables (0x2BCDFC) is read at +0x140 (words
  by register class code: the arith$t of a class), +0x174 (longwords
  by class: its bits, -2 by size, -1 none) and +0xAA8 (masks of k low
  bits, 0..32); declared in isc_types.ins.pas as an extern view.  The
  module's own data: +0x0 the 32 powers of two (is_power_of_2, log_2),
  +0x80 a type_exp record (low -32768, high 32767) for FORTRAN symbols.

## The rewrite tables

rewrite.pas's multiplication tables (m32_prism_and_pa.pas and
m16_prism.pas, included inside the table declarations) are plainly
generated (one entry per multiplier 0..1023, each up to six
shift/add/subtract steps); the generator is not known.  They are
reproduced from the image's data, byte for byte.
