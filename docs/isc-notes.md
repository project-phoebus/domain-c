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
  `inherited_attributes_t`, 40 bytes; `new_inherited_attributes(heap,
  node)`: node and stmt := node, precision and available 32, arith 1
  arith_integer): +4 the statement's top, +12 the statement, +20 the call
  being built, +24/+28 precision and available bits, +32 the source line
  and the statement's index (copied as one longword), +38 the arithmetic
  (`arith$t`), +39 bits (b5: a call's routine operand; b2 `preserve`).
  lir's lir_3b80 is the same record (lir_$complete_top_level_node_
  inherited_attrs fills +4, +32, +34).
- **Solutions** (isc_solution_fields.ins.pas, `isc_solution_t`, 432
  bytes; backend.ins.pas's `solution_t` is batch A's view of the same):
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
is ordinary code: the solution and inherited-attribute allocators,
preserve_solution, the solution lists, apply_pass_1_and_choose_to_list,
apply_pass_2_to_list, and the phase's entry points (isc_$begin_
compilation, isc_$begin_routine, isc_$process_statement,
isc_$end_routine, isc_$end_compilation, isc_$initialize_routine).  Its
headings are in isc_routine_externs.ins.pas; it was not translated
(docs/backend-plan.md, "ISC (hand-written)").  Its span holds 3238
bytes after isc_$end_routine that no .blocks record names (between
0x0DA5B4 and 0x0DB25A): isc_$end_routine's identifier table of il$t
(0x0DA74A) and, probably, generated code.

## The rewrite tables

rewrite.pas's multiplication tables (m32_prism_and_pa.pas and
m16_prism.pas, included inside the table declarations) are plainly
generated (one entry per multiplier 0..1023, each up to six
shift/add/subtract steps); the generator is not known.  They are
reproduced from the image's data, byte for byte.
