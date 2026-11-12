# The ISC generator: analysis and design (phase 1)

The owner decided (docs/questions.md 151) that the generated ISC of
cc.a88k is rebuilt as the ISC generator's input (a pattern description)
plus a generator in `tools/` that emits Pascal of the image's shape,
checked by the gate like any other unit.  This file is phase 1: what the
image holds, how a rule is represented, what the generator's input must
say, what the generator must emit, how it is checked, and the plan for
phase 2.  Translator GA, 2026-11-12.  Everything here is read off
cc.a88k with `tools/cc_isc_inventory.py` (below) unless it says
"proposed" or "a guess".  docs/isc-notes.md (translator PD, extended by
PD2) describes the passes from the hand-written side; this file does not
repeat it but corrects two readings (section 2.4).

## 1. The inventory

`tools/cc_isc_inventory.py BINARY {routines|summary|clusters|matcher|
tables|il|fields|json}` finds every routine between isc_debug's start
and isc_to_lir's (0x0BD1DC .. 0x2088B0, 1,357,524 bytes): the .blocks
records of the iscg_input units, both action tables (one routine per
rule), the targets of calls, and any plausible `link a6` in uncovered
bytes.  It reports address, code length (through the last rts), span
(to the next routine), name or table entry, the A5 loaded, the callers
and callees.  It runs in about 40 s (objdump per routine).

### 1.1 Numbers

| what | routines | code bytes |
|------|---------:|-----------:|
| named (.blocks) in the iscg_input units | 211 | 131,010 |
| pass-1 actions (pattern_matcher's table) | 563 | 616,688 |
| pass-2 actions (isc_pass_2_main's table) | 563 | 473,318 |
| other routines found | 0 | |

- **563 rules**, numbered 1..563 (the tables' .rwdi initialization
  stops there; rule numbers are the image's "which_transform").  Every
  rule has exactly one pass-1 and one pass-2 action; no routine is in
  both tables; no action is called directly; no unreached routine.  The
  "~1080 unnamed routines" are these 1126.
- **45 pass-2 actions are empty** (a bare `rts`, no link, no A5):
  rules 1, 21, 24, 30, 101, 140, 191, 207, 209, 210, 215, 227, 232,
  240, 263..266, 276, 277, 280, 281, 308, 340, 341, 349, 359, 370, 449,
  462, 475, 481, 551..563.  No pass-1 action is empty.
- Every pass-1 action but two (399, 402) prints "Pattern N matched the
  semantics." with its own rule number.
- The 97 extra "called" routines the tool lists inside isc_debug are
  false: decoded constants of isc_print_il_node (see 3.4, long-branch
  thunks).  They are reported, not counted above.

### 1.2 The actions are 25 + 25 separately compiled modules

The actions load **26 different A5 values in pass 1 and 25 in pass 2**,
in runs.  Each run is a module of its own (each pass-1 run has its own
`pas_$output` cell at A5-4, relocated by .rwdi), compiled without
.blocks records (no unit header, no routine names, no line table):

- 25 pass-1 modules (A5 0x44F308 .. 0x479960, data 0 .. 56,712 bytes
  each, 197,660 in all: their cost tables, 2.6) and 25 pass-2 modules (A5
  0x480058 + 4k, k = 0..24: four bytes each, no relocated cell; the two
  whose actions are all empty load no A5 at all, so A5 0x4800A8 and
  0x4800AC are never seen).
- **Each module holds a run of consecutive rules, in rule order, and
  the pass-2 modules hold the same runs in the same order as the
  pass-1 modules.**  In address order:

| # | rules | IL operators / subject kinds (from the matcher) |
|--:|-------|---------------------------------------------|
| 1 | 63..86 | dindex, disp, ptr, sym_disp nodes (address modes) |
| 2 | 140..172 | scalar_aop, agg_aop, fp_aop (assignments) |
| 3 | 306..323 | f_add .. f_sub on fp_reg (single float) |
| 4 | 253..305 | add, sub, mul, div, mod, abs, min, max, expon ... (integer) |
| 5 | 340..348 | calls (call_top, isc_call_top, pf_call, isc_fio_init) |
| 6 | 489..532 | float on fp_reg_pair / fp_reg_quad |
| 7 | 2..12 | constants (integer_ob .. set_con_ob) |
| 8 | 87..100 | cse_parent_ob, cse_use_ob |
| 9 | 435..488 | addr, align, dynamic space, bit fields, chk, index, ... |
| 10 | 404..434 | extend_top, f_extend_top |
| 11 | 227..240 | branch, cbranch, label, case, return, block entry/end |
| 12 | 13..34 | leaves: registers, blocks, addr_con, lib_dsc |
| 13 | 324..339 | and, or, eor, not |
| 14 | 378..403 | chain rules (subject a solution kind, not an IL node) |
| 15 | 241..252 | processor registers |
| 16 | 533..550 | set operators |
| 17 | 200..205 | set assignment operators |
| 18 | 349..374 | shifts |
| 19 | 375..377 | strcmp, strlen, strncmp |
| 20 | 35..62 | var_name, fortran_symbol |
| 21 | 551..563 | proper_subtree rewrites |
| 22 | 1 | use_def_ob |
| 23 | 206..226 | aggregate/string assignment operators |
| 24 | 173..199 | add_to_aop .. rshft_to_aop |
| 25 | 101..139 | compares, bit tests, flow |

  So the generator's input came in 25 sections (files, probably), the
  rules numbered in input order (section 22 first, then 7, 12, 20, ...),
  and each section was emitted as one pass-1 and one pass-2 module.
  The modules' memory order is not the rule order; it is consistent with
  the binder taking the ISC's objects in alphabetical order of file name
  (every named ISC unit is in alphabetical order: isc_call_handling,
  isc_cse_handling, isc_debug, isc_main, isc_pass_1_main, [the 25
  pass-1 modules], isc_pass_2_main, [the 25 pass-2 modules],
  isc_pattern_matcher, isc_to_lir, isc_user_routines, isc_vars), which
  would put the pass-1 modules' names between "isc_pass_1_main" and
  "isc_pass_2_main".  Their names are not in the image.
- The line numbers of the input survive in nine pass-2 messages: "ISC:
  A 'let result <- ...;' in pattern 358 (line number 31146) used a nil
  live_range" (also 392 at 32913, 414 at 33959, 416, 417, 418, 420, 421,
  422 at 34259).  The input was one numbered text of some 45,000 lines
  (about 80 lines a rule), with a statement `let result <- ...;`.

### 1.3 isc_vars and empty

isc_vars has no code and no A5; its file record's "code start" 0x148AC4
is the middle of an instruction of module 14 (the cell is not an address
in version-4 records).  It names the read-only sections
`isc_tool_generated_readonly_tables` (0x2BC13C, 3264 bytes) and
`isc_readonly_tables` (0x2BCDFC, 3120 bytes): isc_vars is the unit that
defines them.  empty.pas's code start 0x101194 also falls inside module
2; neither unit has bytes in the range.

## 2. How a rule is represented

### 2.1 The flow (what the named routines do)

1. `pass_1(node, inh, depth, permissible)` (isc_pass_1_main) dispatches
   on the node's an_kind (its A5+872 table, filled at run time by
   isc_pass_1_begin_compilation; isc_tree_node dispatches on the
   operator through A5+0, isc_cmp_tree_node through A5+360,
   isc_assign_node through A5+720) to `isc_<kind>[_<op>]`.  That routine returns
   the node's il$t (the proper_subtree's `il_kind`, +98), the number of
   children, and each child's solution list, got by calling pass_1 on
   the child with inherited attributes it builds (precision, available,
   arith from isc_readonly_tables by rlen, preserve, ...) and a
   **permissible set per child position**.
2. pass_1 builds one `proper_subtree` solution (kind 22) per element of
   the cross product of the children's lists (`new_solution(heap, 22,
   n, inh, node, il_kind)`, children at +116..) and hands the list to
   `cross_product_to_solutions_of_parent`, which runs
   `pattern_matcher(sol, work, result, node, inh, permissible)` on each
   element of the work list until it is empty.
3. `pattern_matcher` (isc_pattern_matcher) is `case sol^.kind of`; for
   kind 22 a nested `case sol^.il_kind of`; each arm a flat sequence of
   tries `if <tests on the children's kinds> then hard_work(sol, work,
   result, node, inh, permissible, rule)`.
4. `hard_work` (fixed code): if the rule's byte at A5+0x8CF+r is set,
   the rule's result kind (isc_tool_generated_readonly_tables word r)
   must be permissible; counts the children marked
   `builtin_could_deadlock_sched` (at most one, none if the byte at
   A5+0xB07+r is set); calls the **pass-1 action** (A5-4+4r) with
   `(subject, node, inh, var work, var result)`; marks the new solution
   could_deadlock when it holds a physical register that may be
   clobbered; tests `result` against the result list
   (`similar_solutions`, `clearly_dominates`: the dominated one is
   dropped) and appends it there if its kind is permissible or
   proper_subtree (a proper_subtree in a child's list is what a nested
   pattern of the parent matches); appends `work` to the work list
   (closure: the chain rules are tried on it next) unless it is a
   dead_end.
5. Pass 2 (`pass_2`, isc_pass_2_main) is bottom-up over the chosen
   solution: a solution made by a rule has `before_transform` (+88) =
   the subject it was made from; pass 2 walks that first (which walks
   the proper_subtree's children in `evaluation_order`), then calls the
   **pass-2 action** of the solution's rule with `(var self,
   before_transform, var self, self)`.  A proper_subtree has no
   before_transform and gets no action.

### 2.2 A rule's pattern

Decoded completely from pattern_matcher (`cc_isc_inventory.py
matcher`): 683 tries of the 563 rules (64 rules are tried under more
than one operator, e.g. rule 2 under the twelve integer constant kinds,
rules 140..157 under both scalar_aop and agg_aop/fp_aop), every test
understood, every failing branch going to the next try (no shared
prefixes).  A pattern is

- either an **IL pattern**: one or more il$t operators (the arms the
  rule is tried under) and, per child position k, the child's solution
  kind (`$k:ip_reg`) or a set of kinds (`$2:{ip_reg,literal_32_bits}`,
  compiled as a btst of a mask), or a nested pattern: the child is a
  proper_subtree with its own operator and children (`$2:proper_subtree
  & $2.op=il_not_top & $2.1:proper_subtree & $2.1.op=il_bit_set_top &
  $2.1.1:literal_32_bits ...`, rule 182); children not tested are
  unconstrained;
- or a **chain pattern**: the subject is a solution of a kind
  (address_mode, flow, fp_reg, fp_reg_pair, fp_reg_quad, ip_reg,
  ip_reg_field, ip_reg_scaled, literal_32_bits, literal_64_bits,
  processor_reg): rules 108, 250..252, 378..403, 529, 530.

The pattern has no costs: costs are attributes computed by the pass-1
action (code_bytes +92, delay +94, memory_references +110), compared by
hard_work's dominance tests and choose_one_solution.

**The per-child permissible sets of isc_pass_1_main follow from the
patterns**: of the 128 operator routines whose children the matcher
tests, 91 pass constant masks equal to the union of the kinds the
operator's tries test at each position (e.g. add_top 0x3900 / 0x7900,
f_compare_top 0x700 / 0xC700).  The other 37 differ by kinds 20
any_solution (added for assignment targets), 21 irrelevant and 22
proper_subtree (not in the masks: a proper_subtree is always offered),
pass a superset (f_div_top 0x700 where the rules take only fp_reg), or
compute the set at run time (`cc_isc_inventory.py il`).  The generator
can derive the masks, with a per-operator override in the input for
the exceptions.

### 2.3 A rule's solution kind, number and per-rule data

- **Result kind**: `isc_tool_generated_readonly_tables` +0, one word
  per rule 1..563 (23 void for rule 1, 22 proper_subtree for
  551..563); also the literal `new_solution(heap, kind, 0, inh, node,
  0)` in the pass-1 action.
- **The rule number** (`which_transform`, +112) is stored by the pass-1
  action; it indexes both action tables, the per-rule tables of
  pattern_matcher's data and isc_main's preserve table (A5-1+r).
- Per-rule flags: hard_work's two byte tables (check-permissible: rules
  382, 395, 400; no could-deadlock child: 80 rules), preserve_solution's
  bit-7 table and its switch (rules whose local pointer fields must be
  copied: docs/isc-notes.md).
- The rest of the tool tables: six word tables of 178 entries indexed by
  il$t, mapping operators to opcodes: +1126 reg-reg with reversed
  operands (sub -> rsub), +1482 reg-reg (sub -> sub), +1838 immediate
  (addi, subi, andi, ori, xori), +2194 double float (addd .. negd), +2550
  immediate with neg (negi), +2906 single float (adds .. negs).  The
  actions index them by the subject's il_kind (`tables`).

### 2.4 The solution record is generated from attribute declarations

dump_solution (isc_debug) prints every field after its name: the input's
attribute names (`cc_isc_inventory.py fields`).  They are:

- generator fields: object_with_name +0, base_register +4,
  index_register +8, false_label +16, live_range +20,
  live_range_of_imaginary_part +24 (pass 2); before_transform +88,
  code_bytes +92, delay +94, evaluation_order +96, il_kind +98, il +100,
  inherited_attributes +104, kind +108, memory_references +110,
  which_transform +112, number_of_children +114, at +115
  already_preserved .7, builtin_could_deadlock_sched .6,
  builtin_is_local_cse .5, builtin_local_cse_has_been_preserved .4,
  already_through_pass_2 .3; children +116..+132; already_address_mode
  .. already_processor_reg +342..+348 (one per register kind: the
  "Infinite cycle prevented" guard of the chain rules);
- declared pass-1 attributes, laid out by size class in declaration
  order (longwords +28..+52: advancing_displacement, bits_known,
  bits_trusted, bits_known_of_fetched_value,
  bits_trusted_of_fetched_value, literal_32_bits_value, pass_1_size;
  words +56..+74: bytes, the six fp_reg_.../ip_reg_ max/result pairs,
  n_bytes_to_back_up; bytes +76..+80: bit_position_of_lsb,
  field_precision, physical_register_number, scale, slevel_attribute;
  booleans packed from +81 bit 7 in alphabetical order:
  all_zeroes_or_all_ones .. uses_the_index_register +84 bit 5);
- per-rule locals from +136 (case_value at +136, the alternative
  numbers of 2.6) and pointer locals from +352 (preserve_solution's
  fields).

Two readings of docs/isc-notes.md change: +88 is before_transform (the
subject a rule's solution was made from, not a chain that replaces the
children), and +112 is which_transform.  isc_solution_fields.ins.pas
uses abbreviations taken from the CSE accessors' names (memory_refs,
eval_order, obj_w_name, has_sym_disp, uses_disp, embedded_sr_temp):
the generated insert would carry dump_solution's names (question 267).

### 2.5 The actions: whole bodies are not templates

Normalizing each action (`clusters`; level 0 masks addresses, A5, the
rule number and the trace text; level 1 also every immediate and
displacement; level 2 also the callees):

| | level 0 | level 1 | level 2 |
|-|--------:|--------:|--------:|
| pass 1: clusters / singletons | 527 / 510 | 463 / 403 | 457 / 391 |
| pass 1: largest clusters | 9, 8, 6, 3, 3, 2 (x12) | 9, 8, 8, 7, 5, 5 | 9, 8, 8, 7, 5, 5 |
| pass 2: clusters / singletons | 390 / 347 | 348 / 285 | 329 / 257 |
| pass 2: largest clusters | 45 (empty), 39, 16, 12, 7, 6 | 45, 40, 16, 12, 8, 8 | 45, 40, 16, 12, 8, 8 |

So a whole action is a template for few rules (the 45 empty pass-2
actions; 39 pass-2 actions that copy every pass-2 attribute from $1;
16 that set the live range from a local and object_with_name from il;
8 pass-1 actions among 555..563 that sum the children's costs).  The
regularity is at the statement level.  Of the pass-1 code (616,688
bytes) about 23% is the generator's skeleton, 7% attribute copies from a
child (`movX child(K),result(K)`), 17% packed-boolean moves, 20% cost
arithmetic (sums of children's costs, cost-table lookups) and 31% the
rest (semantic conditions, user-routine calls); of the pass-2 code
(473,318 bytes) 17% is calls, 79% their argument computations and
conditions (scratch idiom count, approximate).

The pass-1 skeleton (every action; rule 1 is nothing else):

```
procedure <p1 action>(subject: solution_ptr; il: univ_ptr;
    inh: inherited_attributes_ptr_t; var work, result: solution_ptr);
begin
  result := nil; work := nil;
  if <the rule's semantic condition> then begin       { optional }
    if isc trace (0x481154) then writeln(output, 'Pattern N matched the semantics.');
    if subject^.already_<k> then                      { chain rules }
      <trace 'Infinite cycle prevented by NOT adding this to the work list.'>
    else begin
      s := new_solution(heap, <result kind>, 0, inh, il, 0);
      s^.which_transform := N; s^.before_transform := subject;
      <the rule's attribute statements, in input order>
      s^.already_address_mode := subject^.already_address_mode; ... (7 bytes)
      s^.already_<k> := true;                         { chain rules }
      work := s; result := s
    end
  end
end;
```

The proper_subtree rules (551..563) make no solution: they set the
subject's own costs and return it in `result` only, so that the
parent's list holds the subtree for an enclosing nested pattern (their
operators are exactly those that occur nested in other patterns:
not_top, bit_set_top, rshf_top, f_extend_top, ...).  Pass-2 actions have no skeleton beyond the
heading: their bodies are attribute statements (object_with_name,
live_range, base/index register) and the instruction emission
(debug_lir_$simple/load/store/field/branch_instruction, label, ...:
353, 163, 71, 136, 93 actions), with `pattern_match_error` (147
actions) where no alternative fits.  95 routines are called from pass 1
and 62 from pass 2, nearly all isc_user_routines' (create_solution_for_
ip_reg, find_well_known_literal_solution, evaluation_order_function,
lir_$can_encode_as_immediate_operand, ...).

### 2.6 Alternatives and cost tables

Large rules choose between instruction sequences.  Rule 150 (void <-
scalar_aop/agg_aop/fp_aop, $1:ip_reg & $2:address_mode: a store) sets
some fifty byte locals (+136 .. +185) to 1 or 2 by conditions
(`lir_$can_encode_as_immediate_operand(disp + 3, opc 105, 1)`, the
address mode's flags, the node's size), then computes

```
code_bytes        := table_cb[1][alt_137] + table_cb[2][alt_138] + ... + $1.code_bytes + $2.code_bytes
memory_references := table_mr[..][alt_..] + ...
```

from word and byte tables in the module's data (A5+176 .. +5928 in
module 2, rows 40 and 24 bytes apart).  Its pass-2 action tests the
same locals (`if alt_136 = 1 ... if alt_137 = 1 ...`) and emits the
corresponding loads and stores.  So the input described each rule's
instruction sequences with their alternatives, and the generator
derived both the cost tables (from the instructions' sizes and
classes) and the pass-2 emission.  This is the part of the language
least understood (section 6).

## 3. Worked examples, decoded from the image

The proposed input format (section 4) is used; `$k` is the subject's
child k (before_transform^.children[k]), `result` the new solution,
`subject` the before_transform itself.

**Rule 1** (module 22; p1 0x162AFC, p2 0x1CF06C):

```
transform 1  void <- use_def_ob
  pass_1
  pass_2
```

The pass-1 action is the skeleton alone (kind void, costs zero); the
pass-2 action is empty.

**Rule 2** (module 7; p1 0x11D42C, p2 0x1AA44C), tried under twelve
operators:

```
transform 2  literal_32_bits <- binteger_ob | ubinteger_ob | blogical_ob | integer_ob
                              | uinteger_ob | linteger_ob | ulinteger_ob | llogical_ob
                              | slogical_ob | sinteger_ob | usinteger_ob
  pass_1
    result.code_bytes <- 0; result.memory_references <- 0; result.delay <- 0;
    result.bits_known <- il^.value;               { the node's +8 }
    result.bits_trusted <- -1;
    result.literal_32_bits_value <- il^.value;
  pass_2
    result.object_with_name <- result.il;
```

(The cost zeroing is three `clr.w` the generator writes for every
leaf rule; whether the input wrote them is unknown.)

**Rule 145** (module 2; p1 0x0F7A02, p2 0x18D1FE), a register move:

```
transform 145  void <- scalar_aop | agg_aop | fp_aop ($1: ip_reg, $2: ip_reg)
  condition il^.<+48> <= 4                       { unsigned; the node's size? }
  pass_1
    result.code_bytes <- $1.code_bytes + $2.code_bytes + 4;
    result.memory_references <- $1.memory_references + $2.memory_references;
    result.delay <- $1.delay + $2.delay;
    result.evaluation_order <- 1;
    result.ip_reg_max <- $1.ip_reg_max + $2.ip_reg_max;
    result.fp_reg_max <- $1.fp_reg_max + $2.fp_reg_max;
    result.fp_reg_pair_max <- $1.fp_reg_pair_max + $2.fp_reg_pair_max;
  pass_2
    emit simple(opc$move, request$preference_move, $2, $1, nil);
```

The pass-2 call is `debug_lir_$simple_instruction(self.inherited_
attributes, 75, 16#04000000, $2, $1, nil)`.

**Rule 397** (module 14; p1 0x14B4B4, p2 0x1C3752), a chain rule: the
literal zero is register 31.

```
transform 397  ip_reg <- literal_32_bits
  condition not $1.inherited_attributes^.<+39 bit 5> and $1.literal_32_bits_value = 0
  cycle_guard already_ip_reg
  local lr: live_range                           { +352 }
  pass_1
    result.lr <- <well-known zero, isc_user_routines +0x31C>^.live_range;
    result.code_bytes <- $1.code_bytes; result.memory_references <- $1.memory_references;
    result.delay <- $1.delay;
    result.bit_7_was_sign_extended <- true; result.bit_15_was_sign_extended <- true;
    result.bits_known <- $1.bits_known; result.bits_trusted <- $1.bits_trusted;
    result.derived_from_literal <- true;
    result.ip_reg_max <- 0; result.ip_reg_result <- 0;
    result.literal_32_bits_value <- 0;
    result.physical_register <- get_live_range_assigned(result.lr);
    result.physical_register_number <- get_live_range_register(result.lr);
    result.physical_register_is_no_modify <- get_live_range_no_modify(result.lr);
    result.physical_register_user_declared <- get_live_range_serialize(result.lr);
  pass_2
    result.live_range <- result.lr;
    result.object_with_name <- subject.object_with_name;
```

(`$1` of a chain rule is the subject itself.  The two sign-extension
booleans are set by one `or.w #48,(80,A2)`, an instance of Rev 8.89
merging adjacent bit sets.)

**Rule 182** (module 24; p1 0x170AEA, p2 0x1DF8DC), a nested pattern:

```
transform 182  ip_reg <- and_to_aop ($1: address_mode|ip_reg|ip_reg_field,
                                     $2: not_top($1: bit_set_top($1: literal_32_bits,
                                                                 $2: ip_reg, $3: void)))
```

**Rule 551** (module 21; p1 0x1621CC, p2 empty), a proper_subtree rule
(dpreal_ob): the action makes no solution; it sets the subject's costs
and offers the subject itself to the parent (`result`, not `work`).

```
transform 551  proper_subtree <- dpreal_ob
  rewrite
    subject.code_bytes <- 0; subject.memory_references <- 0; subject.delay <- 0;
```

## 4. The generator's input (proposed)

One text file (or one file per section, `tools/iscg/<section>.isc`, and
a master that lists them in rule order), Pascal-flavoured, in the
image's vocabulary.  It has five kinds of declarations.

```
{ 1. the solution record }
attributes pass_1
  advancing_displacement: integer32;  all_zeroes_or_all_ones: boolean;
  arg_block_location: boolean;  ...  uses_the_index_register: boolean;
end;
attributes pass_2
  object_with_name: univ_ptr;  base_register, index_register: lr_ptr_t;
  false_label: univ_ptr;  live_range, live_range_of_imaginary_part: lr_ptr_t;
end;

{ 2. the IL operators the ISC knows: an_kind (or tree/assign operator),
     its children (node offsets), the inherited attributes each child
     gets, and permissible-set overrides }
operator add_top  tree_op 1  children +40, +44  commutative_literal
  child 1  inherit precision <- precision_from_rlen(il^.rlen), arith <- arith_by_rlen;
  child 2  inherit ...;
end;

{ 3. opcode maps (the six il$t tables) }
map opcode_rr_reversed  add_top, add_to_aop -> opc$add;  sub_top, sub_from_aop -> opc$rsub; ...

{ 4. sections, one pass-1 and one pass-2 module each }
section shifts;            { rules follow in input order, numbered 1.. }

{ 5. transforms }
transform 397  ip_reg <- literal_32_bits           { number checked, not chosen }
  [check_permissible] [no_deadlock_children] [preserve_locals]
  condition <boolean expression>;                  { optional }
  cycle_guard already_ip_reg;                      { chain rules }
  local lr: live_range;                            { per-rule fields, laid out by the generator }
  pass_1
    <statements>
  pass_2
    <statements>
end;
```

Statements: `x <- e;` (assignment to `result.f`, `subject.f`, `local`),
`if/then/else`, `case`, calls of isc_user_routines' and lir_ routines,
`emit <kind>(opcode, requests, operands...)` for the debug_lir_
instruction calls, `let result <- e;` (pass 2: the result's live range,
with the nil check that prints the pattern and line number),
`alternatives ... end` for 2.6 (syntax to be fixed in phase 2 once the
cost tables are decoded).  Expressions: Pascal, with attribute paths
`$k.f`, `$k.$j.f`, `result.f`, `subject.f`, `il^.f`, `inh^.f`.

A rule entry is pattern -> solution kind, flags, condition, locals and
two statement lists; there is no separate cost field (costs are
attributes) and no child-order field (evaluation_order is an attribute,
set by `result.evaluation_order <- evaluation_order_function(...)` in
177 rules, `<- 1` or left at new_solution's 1 in the rest).  Macros
cover the statement-level templates found in 2.5: `copy f1, f2, ... from
$k;`, `sum code_bytes, delay, memory_references of $1, $2 [+ n];`,
`copy all pass_1 from $k;`.

## 5. What the generator emits

| unit | generated from | fixed text |
|------|----------------|------------|
| 25 pass-1 action modules | the transforms' pass_1 parts, the cost tables (module data) | the skeleton |
| 25 pass-2 action modules | the transforms' pass_2 parts | the heading |
| isc_pass_1_main | the operator declarations: isc_<kind>[_<op>] (182), the dispatch-table initialization in isc_pass_1_begin_compilation | pass_1, cross_product_to_solutions_of_parent, isc_unrecognized_il_node |
| isc_pattern_matcher | pattern_matcher's arms; data: the pass-1 action table, the two flag tables | hard_work, pattern_matcher's prologue and trace |
| isc_pass_2_main | data: the pass-2 action table (563 `addr` of extern routines) | pass_2 |
| isc_vars | isc_tool_generated_readonly_tables (result kinds, opcode maps) | isc_readonly_tables (hand data) |
| isc_main | preserve_solution's switch and byte table | the rest (ordinary code: translated as usual) |
| isc_debug | dump_solution's field list | indent, print_permissible_solution_kinds, isc_print_il_node (translated as usual) |
| inserts | isc_solution_fields (the record from the attribute declarations and the per-rule locals), isc_enumeration (il$t), solution_string.init | isc.pvt |

Rev 8.89's code shape constrains the emitted Pascal (dpc must then
produce the same):

- An action is a module-level, exported routine (it loads A5 even when
  it does not use it: rules 2, 397's pass-2 actions), except an empty
  one, which is a bare `rts` (dpc must not emit link/unlk/A5 for an
  empty procedure: to check).
- Statement order is the image's order: the compiler reorders nothing,
  so the rule file keeps statement order exactly; the children are
  re-fetched for each statement (`move.l (116,A2),A1` every time: no
  `with`); the seven already_ bytes are seven statements, not a record
  copy.
- The trace's position (after the condition, before the cycle guard)
  and the order `result := nil; work := nil` (the fifth argument first).
- pattern_matcher: the nested case statements compile to word jump
  tables; the last try of each arm shares the call (`pea rule; bra
  common`): Rev 8.89 cross-jumping, which dpc may not do (then "size
  differs", best effort).
- Module data: pass-1 modules have `pas_$output` at A5-4 and the cost
  tables above A5 as initialized module variables; pass-2 modules four
  uninitialized bytes.
- isc_print_il_node (92,352 bytes) passes 32 KB: Rev 8.89 reaches far
  code through `jmp (-n,A5)` to `jmp abs.l` thunks in the module's data
  (54 thunks to tails shared by cross-jumping: docs/rev889-patterns.md
  164).  dpc gap, probably.  Empty actions: pattern 165.

## 6. How it is checked

- The generated Pascal is committed (the gate does not run the
  generator) and is compiled and compared like any unit:
  `tools/cc_check.sh moon_unit/.../iscg_input/isc_pattern_matcher.pas`
  etc.  `tools/iscg_gen.py --check` regenerates into a scratch tree and
  fails if the committed files differ, so the rule file stays the
  source.
- The six named units already have .blocks units; the gate needs no
  change for them.
- The 50 action modules have no .blocks unit, so coff_compare cannot
  pick them.  Proposed: the generator writes a manifest
  (`tools/iscg/modules.txt`: file, A5, code range, and per routine its
  name and address, the address taken from the action table by rule),
  coff_compare gains `--anon START END A5 --names FILE` to compare a
  unit against that range, and cc_check.sh and cc_addrcheck.py read the
  manifest for files under iscg_input that .blocks does not know
  (question 268).
- The extractor and generator round-trip: extract the rule file from
  the image, generate, compare.  The tables (isc_vars, pattern_matcher's
  and pass_2_main's data, the cost tables) are compared byte for byte
  (tools/cc_data.py, translator QA's data checker when it lands).

## 7. Phase 2 plan

1. **Extractor** (`tools/iscg_extract.py`, from cc_isc_inventory.py):
   patterns (done here, ~200 lines), result kinds, flags, opcode maps
   and the attribute declarations (done), the operator declarations
   from isc_pass_1_main (children, masks: done; inherited attributes:
   to do, ~300 lines), preserve_solution's switch (~100), the cost
   tables (~300), and the **action bodies**: skeleton and idiom
   recognition (~400), then a structured decompiler of the residue to
   the statement language (expressions, if/else, case, calls, emit:
   ~1500).  About 3,000 lines of Python; the residue it cannot lift is
   written by hand into the rule file.
2. **Rule file**: 563 transforms in 25 sections plus the declarations;
   the original was about 45,000 lines, ours perhaps 25,000 - 35,000.
3. **Generator** (`tools/iscg_gen.py`, ~1,500 lines plus the fixed-text
   templates of hard_work, pass_1, pass_2, the action skeleton):
   emits the 50 modules (about 1.09 MB of code, perhaps 60,000 lines of
   Pascal), the five named units' generated parts, the inserts and the
   manifest.
4. **Gate**: coff_compare `--anon` and the manifest (~100 lines in the
   shared tools; question 268).
5. Order: the tables and pattern_matcher first (small, all decoded,
   gate early), then pass_2_main and isc_vars, then isc_pass_1_main's
   operator routines, then the actions section by section (start with
   sections 21, 22, 7, 14: small and regular), the large store/load
   sections (2, 9, 23) last.

## 8. Still unknown

- The names of the 50 modules, of the actions and of their parameters,
  and of the sections (question 266).
- The input language's real syntax: only "pattern", "transform"
  (which_transform, before_transform), `let result <- ...;` and the
  attribute names survive.
- The alternatives and cost tables (2.6): how the tables' rows map to
  instructions and costs; whether code_bytes counts bytes (4 per
  instruction in rule 145) and what delay measures.
- isc_pass_1_main's inherited-attribute rules (only partly read) and the
  run-time permissible sets of some operators.
- The flags at pattern_matcher A5+0xB04 (a byte reset per call, set when
  a proper_subtree is re-queued).
- Why pass-2 modules have four data bytes and no output cell.
- How much of isc_debug and isc_main is generator text and how much is
  the generator's own output; whether isc_print_il_node was generated.
- Pass-1 actions 399 and 402 have no trace string: generated without
  it (an input flag?) or a different skeleton.
- Whether the ISC objects really were bound in alphabetical order (the
  basis for guessing module names).
