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
- How much of isc_main is generator text and how much is the
  generator's own output.  (isc_debug: section 9; isc_print_il_node was
  generated.)
- Pass-1 actions 399 and 402 have no trace string: generated without
  it (an input flag?) or a different skeleton.
- Whether the ISC objects really were bound in alphabetical order (the
  basis for guessing module names).

## 9. isc_debug's generated regions (translator PE)

isc_debug.pas is translated by hand (question 270); the regions between
the comments `{ iscg: begin <what> }` and `{ iscg: end }` are the ones
the generator is to own.  They are written out in full for now, so the
unit compiles and compares.

| region (in order) | where | generated from |
|---|---|---|
| `print_il_node views` | type section: `pin_<kind>_t` / `pin_<kind>_ptr_t`, 54 records | the IL description: each node kind's static attributes, named as printed, at the offsets the code reads (fillers unnamed; aliases at one offset, e.g. var_name's address/disp/processor_register_address at +56, as variants) |
| `dump_solution view` | type section: `ds_solution_t` | the attribute declarations (2.4): the solution record under the image's names (isc_solution_fields.ins.pas's isc_solution_t keeps the hand-written units' names, question 267) |
| `static attributes by IL node kind` | isc_print_il_node: the arms of `case kind of` | one arm per node kind of il$t (the 64 node kinds, exactly il$t's non-operator elements; 10 have no static attributes and share an empty arm), in il$t's order; assign_node, tree_node and cmp_tree_node have a nested `case op of` in alphabetical order: assign_node one arm per il$t aop (34), cmp_tree_node one per il$t comparison (6), tree_node 76 (il$t's tree operators but mark_dynamic_space_top and physical_top, and the six comparisons too); each arm writes its attributes in alphabetical order |
| `inherited attributes` | isc_print_il_node, after the case | the inherited attribute declarations (17, alphabetical but il last), written for every node |
| `dump_solution fields` | dump_solution, under at_backend_switches.level = 7 | the attribute declarations: the declared pass-1 attributes (alphabetical), then the generator's fields (before_transform .. already_through_pass_2) |
| `solution kinds` | print_permissible_solution_kinds | solution$t, one test per kind 1..23 |

The evidence that isc_print_il_node is generated (section 8's open point):
its 64 arms are exactly il$t's node kinds, the code holds them in il$t's
alphabetical order (a jump table does not need it), the comparison
operators' compare chain tests them in that order (24, 84, 11, 12, 40,
23), the attributes are printed under the input's names with a fixed
`static <name>: ` / `inherited <name>: ` shape and the same writes per
type (integer `:1`, unsigned, boolean, enumerated through the type's
identifier table, pointers through isc_user_routines' printers or as
integers without a width), and an assignment's `static
source_line_number` prints the inherited one.  The generator's input must
therefore also declare each IL node kind's static attributes (name,
type, node offset) and the inherited attributes; the fixed text is the
routine's frame: the nil test, the `Node <kind>: address = ` line, the
otherwise bug_check, and indent.

The view records duplicate knowledge of isc_types.ins.pas's isc_node_t
variants (assign_node +76 op, tree_node +36 op, var_name +28 type, ...)
under the attribute names; a generator that emits both from one
description would remove the duplication.

isc_print_il_node is 0x168C0 bytes; Rev 8.89 reaches its far arms
through `jmp (-n,A5)` thunks (pattern 164; every jump-table entry has a
stub of its own).  dpc refuses a routine of that size ("a `case` arm
beyond the reach of a 16-bit table offset": docs/dpc-gaps.md 46); the
gate does not meet it because the gap-4 rule drops the writes, which
shrinks the routine to 0x4B0C bytes.

## 10. Phase 2 progress (translator GB, 2026-11-12)

Done: the tables and the matcher, isc_pass_2_main and isc_vars (GA's
order, 7.5).  Not started: the action bodies' decompiler, the action
modules, isc_pass_1_main's operator routines.

### 10.1 The tools

- `tools/iscg_extract.py [--binary B] [--out DIR] [--json FILE]` (about
  40 s) writes the rule file from cc.a88k.  Its matcher decoder follows
  each arm of pattern_matcher's two jump tables through the shared tails
  (a try reached by a jump into another arm counts under both), and
  checks that every failing test leads to the same remaining tries as
  the call's return (by decoding from both).  It then reads the files it
  wrote with the generator's parser and fails unless they give the
  decoded matcher back, try for try and test for test (683 tries in 184
  arms: 11 kind arms, 173 il$t arms; GA's inventory counted 185, one a
  misread arm at 0x2058B4).
- `tools/iscg_gen.py [--rules DIR] [--out DIR]` writes the generated
  units into the iscg_input derived-object directory;
  `tools/iscg_gen.py --check` regenerates in memory and fails, with a
  diff, if a committed unit differs.  tools/cc_check.sh runs `--check`
  whenever its arguments include a file under iscg_input (the full gate
  does).  The generator's fixed text (unit headers, hard_work,
  pattern_matcher's traces, pass_2) is `tools/iscg_text.py`.
- `iscg_names.txt` (generated, beside the units) is the manifest: each
  anonymous action's name (transform_<r>_pass_1/_2) and its cc.a88k
  address, from the rule file's `image' clauses.  tools/cc_datacheck.py
  reads it to resolve the action tables' relocations (otherwise 1126
  unverified pointers).

### 10.2 The rule file

`moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/rules/`: 27 files,
3813 lines, 118 KB.

- `declarations.isc`: `kinds` (solution$t), 79 `attribute` lines
  (dump_solution's names with offset, bit and size class), 179
  `operator` lines (isc_pass_1_main's routine, il$t, children, each
  pass_1 call's permissible set: `derived' where it equals the union of
  the kinds the patterns test at that call's position, else the set,
  `inherited', `-np'; 90 derived so far: a routine whose first pass_1
  call is not for child 1 (add_top's `inherited' one) is compared at the
  wrong position, to fix when isc_pass_1_main is generated), and the six
  `map`s (opcode_rr_reversed, opcode_rr, opcode_immediate,
  opcode_double, opcode_immediate_negated, opcode_single: names ours).
- `NN_topic.isc`, NN 01..25 in address order (topics as 1.2; the
  module names of question 266 follow them): `section NN topic image
  pass_1 a5 X, pass_2 a5 Y;` then, in rule order,

      transform 182  ip_reg <- and_to_aop ($1: [address_mode, ip_reg, ip_reg_field], $2: not_top($1: bit_set_top($1: literal_32_bits, $2: ip_reg, $3: void)))
        pass_1 image 16#170AEA;
        pass_2 image 16#1DF8DC;
      end;

  An alternative list `op1 | op2 (children)` shares the children; a
  rule tried under operators with different children lists one group
  per children (none so far).  A set of kinds is `[a, b]` (braces are
  comments).  Flags: `check_permissible` (3 rules) and
  `no_could_deadlock_child` (80).  `pass_2 image ... empty` marks the
  45 empty pass-2 actions.  The image clauses are placeholders for the
  bodies: the generator uses them only for the manifest.
- `readonly.isc`: isc_readonly_tables' 3120 bytes as words (the ISC's
  own tables, not the generator's; isc_vars defines them through
  isc_types.ins.pas's views).

### 10.3 The generated units and the gate

| unit | routines | gate (cc.a88k) | data check |
|------|---------:|----------------|------------|
| isc_pattern_matcher | 2 | errors=0; hard_work sim 0.24, pattern_matcher 0.07 (most arms left out: gap 25) | 3376 bytes of module data, all 563 relocations resolved: no difference (one layout shift, dpc gap 37) |
| isc_pass_2_main | 1 | errors=0; sim 0.00 (see below) | 2252 bytes, 563 relocations: no difference |
| isc_vars | 0 | errors=0 (nothing to compare) | both sections, 6384 bytes: no difference |

- pattern_matcher is `case solution$t(solution^.kind) of` with every
  kind 1..23 a label (the kinds without chain rules share one empty
  arm: the image's in-range kinds without tries go to the case's end,
  only 0 and 24 to the error) and `case il$t(solution^.w98) of` with a
  label per operator some pattern names (unlabelled ones go to the
  otherwise, as in the image).  A try is one `if` per test, nested, in
  pattern order: the image leaves at the first failing test, a child is
  read only when the tests before it hold, and dpc evaluates `and`
  whole (it would read a nested child of a node that is not a
  proper_subtree).  The image's shared `pea rule; bra' tails and arms
  jumping into one another are Rev 8.89 cross-jumping, not the source.
- dpc refuses pattern_matcher whole ("more values live at once than
  there are registers" once the il$t arms reach and_to_aop, "a routine
  needing this many registers" with flat `and`s): the gate compiles it
  with the il$t arms from and_to_aop to the otherwise left out (gap 25,
  tools/cc_gap_rewrites.txt).  dpc --check-only accepts the whole
  routine (writes aside).
- isc_pass_2_main's similarity is meaningless: coff_compare ends pass_2
  at the next named routine, hard_work (0x73EA4 bytes later: the pass-2
  modules lie between).  The comparison tool of question 268 should end
  a named routine at the manifest's next address too.
- Question 261, settled: isc_vars defines isc_readonly_tables (its
  .blocks record names the section); isc_types.ins.pas declares the
  section's variable (`var (isc_readonly_tables)', the scheme of
  question 161) and isc_vars gives it its value with `define', laid out
  by isc_types' views (extended by 4 bytes to the section's end).
  isc_tool_generated_readonly_tables likewise, declared in isc.pvt.pas.
  isc_vars opens lang2/source/isc/isc_var_defines.ins.pas first (a
  stub: its contents are not in the image).
- Field names: the generator writes isc_solution_fields' current names
  (kind, w98 for il_kind, children, f114.b6 for
  builtin_could_deadlock_sched, f76.physical/no_modify/serialize/reg);
  dead_end (+81.3), which the insert does not name, is read through a
  unit-local view.  The mapping lives in iscg_text.py's fixed text and
  iscg_gen.py's FIELD_MAP (question 267).

### 10.4 What remains

1. **The action bodies**: pass 2 done (10.6, translator GC); pass 1
   done but 5 actions (10.7, translator GE).  The decompiler from the
   pass-1 and pass-2 actions to the statement language (section 4),
   macros for the templates of 2.5, the cost tables of 2.6, and the
   generator's emission of the 50 modules.  The action headings are
   fixed by the tables' types: pass 1 `(var subject: isc_solution_t; il:
   univ_ptr; inh: inherited_attributes_ptr_t; var work, result:
   isc_solution_ptr_t)`, pass 2 `(var self: isc_solution_t; subject:
   isc_solution_ptr_t; var result: isc_solution_t; solution:
   isc_solution_ptr_t)`, both val_param (hard_work and pass_2 push
   `pea (A2)' for the var records).  The rule file's `pass_1 image ...;`
   placeholders become the statement lists; the image addresses move to
   the manifest only.
2. **The action modules' gate** (question 268): done (10.6) for the
   pass-2 modules and the named units before anonymous code, and (10.7)
   for the pass-1 modules (every section's `module' line).  `tools/cc_isc_check.py`
   driven by iscg_names.txt (extended with each module's file, A5 and
   code range: the section clauses have the A5s), reusing coff_compare's
   compile_program/compare_object with `starts` augmented by the
   manifest's addresses and the module's A5 as its data base; also for
   the named units, so that pass_2 and pattern_matcher end where the
   image's code does.  cc_check.sh calls it for files the manifest names
   and .blocks does not.
3. isc_pass_1_main: generated (10.5); all 186 routines generated or
   fixed text (GD2).
4. isc_main's preserve_solution table and isc_debug's dump_solution
   field list (question 270: hand-translated units, generated parts by
   marked includes).

### 10.5 isc_pass_1_main (translator GD, 2026-11-12)

Generated: `tools/iscg_gen.py` writes isc_pass_1_main.pas from the
rule file's operator declarations (declarations.isc) and the fixed text
of `tools/iscg_text.py` (P1_HEAD, P1_TYPES, P1_DATA, CROSS_PRODUCT,
UNRECOGNIZED_IL_NODE, DISPATCH, BEGIN_COMPILATION_HEAD, PASS_1).  The
lifting and the emission are `tools/iscg_pass1.py` (separate from the
transforms' code; iscg_extract.py's `operators()`/`pass1_operators()`
and iscg_gen.py's `Rules.parse` (`operator') and `isc_pass_1_main()`
call it).

- **133 of 186 routines generated**: pass_1, cross_product_to_solutions_
  of_parent, isc_unrecognized_il_node, isc_pass_1_begin_compilation,
  the three dispatchers (isc_tree_node, isc_cmp_tree_node,
  isc_assign_node: one template) and 126 operator routines lifted
  from the image.  **53 remain** (`fixed;' in the rule file with their
  pass_1 calls' sets; declared extern in the unit and listed in its
  header): the lifter stops at their first construct it does not know
  (a field compare such as `cmpi.w #59,(36,A1)' in the div/mod family,
  `tst.b 0x44E76A' (a global flag) in char_string_ob and its two
  siblings, the blocks' frame-size code in entry_blk/function_blk/
  procedure_blk, the swap of compare_top through the relation table,
  the larger rewrites of div, mod, mul, isc_mul and the bit fields).
  Their text goes either into the lifter (a new statement form) or into
  iscg_text.py's P1_ROUTINES (read off by hand), the operator
  declaration keeping `fixed;'.
- **Dispatch**: begin_compilation is generated from the routines'
  names (isc_tree_node_<top>, isc_cmp_tree_node_<top>,
  isc_assign_node_<aop>, isc_<an_kind>, the enumerations isc_user_
  routines declares), in declaration order, each table's default loop
  just before its first routine; the extractor checks the result
  against the image's stores, cell for cell.
- **The operator declaration** (the OPERATORS_COMMENT in declarations.isc
  explains it): `operator NAME il X children N image ADDR;' then
  `child K NODE [copy_all]', its inherited-attribute statements
  (`fetch_precision <- isc_$precision_from_rlen_and_size(il.w24, -1);'),
  `permissible derived|inherited|[kinds] [-np];', and `call',
  `let nK <- f(...);', node stores of a rewritten node (`n2.p40 <-
  il.p44;'), `trace rewrite;', `child solutions NODE copy_all' (the
  routine's own list: pass_1 at the same depth), `solutions_made;',
  `if COND; ... else; ... endif;'.  The default inherited attributes
  are copied in alphabetical order before a child's statements (the
  generator writes the copy); the statements' names are
  isc_print_il_node's (question 271), mapped to the insert's fields
  by iscg_pass1.INH_ATTRS.
- **Derived masks by position** (GB's open point): a pass_1 call's
  position is the children[k] it is stored in (call_positions), so a
  routine whose first call is a rewrite (add_top's swap: `inherited')
  compares its children's sets at positions 1 and 2.  The fixed
  routines list `position: set' (`pass_1 inherited, 1: derived -np, 2:
  derived -np').
- **Gate**: errors=0 (best effort, similarity 0.42); the module data
  (the four tables, 1820 bytes, uninitialized) match; the 25 pass-1
  modules' data between this block and isc_pass_2_main's is a
  cc_datacheck_known.txt entry (no .blocks unit owns it).  The writes
  are gap 4 (a rewrite line for the unit).
- Questions 420 .. 423; patterns 173 .. 343.

**The 53 routines left `fixed' (translator GD2, 2026-11-12): all 186
done, none extern.**  Each was either lifted (the lifter and the rule
file's statements extended, so the generator emits it from declarations.isc)
or written as fixed text (iscg_text.P1_ROUTINES, read off the image by
hand; its declaration keeps `fixed;' with the pass_1 calls' sets):

- *Lifted* (29): agg_aop, fp_aop, scalar_aop (a field condition and the
  rewrite_$agg_aop rewrite), char_string_ob, namelist_constant_ob,
  set_con_ob (target_properties.p_be and +0xB4), at_lib_dsc, lib_dsc
  (il_180's fields as arguments), isc_addr_top, set_extend_top (a
  zero-extended word argument), signed_div_top, unsigned_div_top,
  signed_mod_top, unsigned_mod_top (`immediate_parent_wants_signed <-
  il.w36 = 59': a boolean from `cmpi; seq'), blk_end_node (an or-chain
  and a bit of il.p48's byte), raise_exception (a boolean function's
  result), isc_signed_mod_top, isc_signed_rem_top (bits set by one
  `or.w #72' of +38), addr_con, branch_node, case_node_range_check,
  cbranch_node (a child whose list is one solution made in the routine:
  `child K NODE solution KIND'), nlbranch_node (il_kind_function in a
  condition), addr_top (precision_from_il_node, arithmetic_from_il_node),
  bit_set_top, f_extend_top, sr_top (a condition after the children, the
  void solution in its then part), isc_unsigned_mod_top,
  isc_unsigned_rem_top (two longwords of the node copied by `lea; move.l
  (A)+; move.l (A)'), isc_agg_zero_aop (a statement's index, `nK.index
  <- il.index'), insert_bit_field (`rlen_bits(X)'), bit_field_assign and
  both bit_field_cmp_top (three booleans and-ed through a local, a
  compare of il_node_to_integer_value's result).
- *Fixed text* (24): the routines whose control flow is not one
  condition over children and rewrites, or that read tables the
  language does not name: isc_func_call_top (pass_1_isc_call, depth
  0), f_math_top (an or-chain merged with a boolean table of
  isc_readonly_tables +424, children at rlen_bits), func_call_top (the
  temporary's kind by cases), f_div_top (the reciprocal rewrite under
  an and/or of five calls), return_node (the assignment of the return
  value: a word table at +346, rlen_bits div 8), isc_agg_aop (the count
  times the element's bytes), entry_blk, function_blk, procedure_blk
  (a two-bit field, a comparison with il_180's, each branch with its
  own trace), fortran_symbol (three paths and initialize_symbol), both
  compare_top (the converse relation from the word table at +0x30),
  mul_top, isc_mul_top, isc_mul_to_aop, div_by_aop, div_top, mod_top
  (the large rewrites: library calls through std_lib_rtns[1], [5], [7],
  the in-line conditions over il_180's bit 4 of +374 and
  cargs_$options.flags_286 elements 13 and 14, value_top_over).
  _p1() builds a routine from its comment and body (`@COPY v' the
  default copy, `@TRACE' the REWRITE trace); _blk, _compare and
  _p1_rewrite_tail share the repeated ones.
- **The lifter's additions** (iscg_pass1.Lifter): tests (cmpi, cmp, tst,
  btst, a boolean function's tstb) and their branches as and/or chains
  (an or when a test jumps over the next one to the then part); `scc'
  booleans stored as attributes; booleans and-ed through a local;
  global cells (GLOBAL_CELLS: target_properties.p_be, .l180) and the
  node pointer il_180 (GLOBAL_NODES) as roots; clr stores of a rewritten
  node; bit 7 copied from a loaded byte; bits set together by or.w/or.b;
  rlen_bits; the index; solution_list$new/new_solution/append as a
  solution child; one condition anywhere in the body (after children
  too), its else part optional, its then part ending at the exit or at
  the `st' of solutions_made.  BOOL_FUNCS, EXPR_FUNCS and ORD_FUNCS list
  the functions read as expressions; CALL_CASTS and CALL_BOOL the
  arguments the headings need cast (il_$node_ptr_t, false).  The
  extractor takes the lifter's il$t and children where
  cc_isc_inventory's reading has none (branch_node stores the count
  through a data register's copy).
- **The fixed text's views** (P1_TYPES): p1_node_chars_t (a node's bytes
  as values), p1_target_view_t (target_properties +0xB4),
  p1_readonly_bytes_t and p1_readonly_words_t (isc_readonly_tables by
  byte and word).
- **Gate**: errors=0, 186 routines, similarity 0.43 (0.59 modulo
  registers); the data and `iscg_gen.py --check' agree.  Questions 440 ..
  443, patterns 186, 187.

### 10.6 The pass-2 actions (translator GC, 2026-11-12)

All 563 pass-2 actions are in the rule file as bodies in the statement
language, lifted from the image (none written by hand), and the 25
modules `isc_pass_2_<nn>_<topic>.pas` are generated and compile with
errors=0 under the gate.

**The tools.**

- `tools/cc_isc_check.py [--keep DIR] [--diff] [-v] FILE.pas ...`
  (`--list` prints the manifest's modules): compiles each file as the
  gate does (cc_datacheck's gap rewrites and inserts) and compares it
  through coff_compare's library (pascal_progress.compare_object): a
  module's routines at the manifest's addresses with the module's A5 as
  its data base, a named unit's at its .blocks addresses, every routine
  ending at the next start .blocks or the manifest gives (pass_2 now
  0.64 instead of 0.00); then cc_datacheck's check on the same object (a
  module standing for a .blocks unit with its A5).  It fails when dpc
  fails, a module routine the manifest names is not in the object, or
  the data differ.  tools/cc_check.sh hands it every file under
  iscg_input that the manifest names (`module' or `unit' lines:
  isc_pass_1_main.pas, isc_pass_2_main.pas and the 25 modules).
- The manifest (iscg_names.txt) gains `module<TAB>FILE<TAB>A5<TAB>START
  <TAB>END' for the pass-2 modules (A5 `-' for sections 21 and 22, whose
  actions are all empty and load none; the ranges from the actions'
  addresses, the last ending at hard_work 0x20042C) and
  `unit<TAB>FILE<TAB>named' lines (cc_datacheck reads only the two-field
  routine lines).
- `tools/iscg_p2lang.py`: the statement language (its docstring is the
  grammar): abstract syntax, printer, parser, and the translation to
  Pascal with the insert's field names (no rename, question 267) and the
  casts the types need.  `tools/iscg_p2lift.py [RULE ...] | --stats`: the
  decompiler (below).  `tools/iscg_p2gen.py`: the rule file's pass_2
  clauses (`pass_2 image 16#A empty;`, `... begin ... end;`, `... hand
  begin ... end;` kept by the extractor, `... residue;` which keeps the
  section's module from being generated) and the modules' emission.
  iscg_extract.py writes the lifted bodies (about 20 s more);
  iscg_gen.py emits a module for each section none of whose actions is
  residue (all 25 now).

**The language as built** (section 4's proposal, made concrete): `path
<- expr;`, `emit KIND(args);` (debug_lir_$KIND_instruction with
result.inherited_attributes; `emit label`), `let result <- e line N;`
(solution.live_range <- e and the nil check with the original's message:
rules 358, 392, 414, 416..418, 420..422, the image's lines), procedure
calls, `if/elsif/else ... end;`, `for v := lo to hi do ... end;`, `temp
t: type;`.  Paths: the parameters self, subject, result, solution
(self and result are the same solution, read through different
parameters: the language keeps which); `$K` (subject.$K); attributes by
the image's names; the rule's own fields by offset (`c137` a choice
byte, `w136`, `l352`); `opc$NAME`; the tables `opcode_rr[...]` etc.,
`isc_literal_solutions[k]`, `lir_3c60/3d60/3e60/3f90[...]`,
`readonly_wN[...]` (isc_readonly_tables' unnamed word tables), IL node
fields by offset (`self.il.l4`, `.w26`, `.b14`: the node's kind is not
known to the action, question 287); `&`, `!`, lshft/rshft/arshft;
unsigned comparisons `u<` etc.

**The decompiler** follows the control flow from the prologue to the
single epilogue, executing symbolically: registers, frame temporaries
and the argument pushes hold expressions; a store is an assignment, a
`jsr` a call whose arguments are the pending pushes matched to the
heading's parameters by size (headings read from the inserts the
modules open); a conditional branch an `if` whose arms run to the
nearest post-dominator with no argument pending (cross-jumped argument
tails are duplicated into the arms); a `dbf` loop a `for` (its loop
variables temps); a register value used across a statement that may
have changed it (a call's value used twice or later, a field stored
meanwhile, a value differing between the arms) a `temp`; the rest is
written where used.  Idioms: the boolean copy (sne/lsr/lsl/or into a
cleared bit), signed division (bpl/addq/asr), merged word pushes,
partial pops, `move.l (SP),-(SP)`, field addresses (lea/add to a
solution pointer), the `movea.l A0,A0` filler.  The printer and parser
must agree on every body (checked when lifting).

Coverage: 518 non-empty actions, 0 residue, 0 hand-written; 6,996
assignments, 8,581 emits, 920 other calls, 5,380 ifs, 18 for loops, 37
let-results; 3,948 temps in 297 actions (question 286).  Forms lifted but
not named: 44 actions read IL node fields by offset, 8 isc_readonly_tables
word tables.

**The modules.**  Each opens GB's INCLUDES, declares only the views it
needs (p2_flags_t: the booleans the insert lumps in b81_7_2 and
b83_7_4; p2_locals_t: the rule's words and misaligned longwords; p2_node_t;
p2_readonly_t; lir_3c60/3d60, which lir.pvt.pas declares and the ISC
does not open), and one routine per rule (`transform_<r>_pass_2`, the
heading of p2_pass_2_action_t; an empty action `begin end`, a bare `rts`
as in the image).  No module data: the image's four bytes are what Rev
8.89 gives every module (pattern 177, std's precedent), nothing reads
them; dpc allocates none and loads no A5 (pattern 1).  Similarity (cc.a88k,
mean over the non-identical routines): 0.39 (05) .. 0.68 (03), most
0.5 - 0.6; 30 routines `same' (empty actions mostly) besides sections 21 and
22.  dpc gaps met: 7 (real constants: address_mode_for_single/
double_value's argument in modules 03, 04, 06, 10, 24; the check drops
the call) and 25 (15 actions of several hundred statements: 02's 153,
157, 169, 170; 09's 445, 448, 450, 474; 14's 384; 24's 178, 180, 181,
186; 25's 120, 123; the check compiles them with an empty body).
tools/cc_typecheck.sh on the modules reports only gap 7's message.

**What remains for pass 2.**  Names: the temps (t1..), the modules',
routines' and parameters' (question 266), IL node fields by kind
(question 287), the readonly tables (413).  Macros for the statement
templates of 2.5 (copy all pass-2 attributes from $1: 39 actions) are
not used: the bodies are written out.  The pass-1 modules' data still go
to cc_datacheck_known.txt's isc_pass_1_main entry; their `module' lines
in the manifest would let cc_isc_check own them.  Questions 410 .. 415,
patterns 177 .. 338.

### 10.7 The pass-1 actions (translator GE, 2026-11-12)

558 of the 563 pass-1 actions are in the rule file as clauses in the
statement language: 556 lifted from the image, 2 written by hand (rules
399 and 402); 5 are residue.  21 of the 25 modules
`isc_pass_1_<nn>_<topic>.pas` are generated and compile with errors=0
under cc_isc_check, their data (the cost tables) equal to the image's.

**The tools** (new files; hooks of a few lines in iscg_gen.py's Rules.parse,
names() and all(), and iscg_extract.py's extract() and write_rules()):

- `tools/iscg_p1lift.py [RULE ...] | --stats [--section N] | --raw RULE`:
  the decompiler.  It subclasses iscg_p2lift's Lifter (the same symbolic
  execution, ifs at post-dominators, temps), adding the pass-1 heading
  (subject, il, inh; the var pointers work and result), the trace as
  one statement (write + writeln to pas_$output at A5-4), the cost tables
  (module data at A5 + offset, or an absolute base above 32 KB, indexed
  by a choice byte), Rev 8.89's boolean forms (s<cc> into bytes, not.b,
  and.b, or.b and a test of bit 7; a boolean function's value moved into
  a packed field by lsr.b #7 / lsl.b / or.b into a cleared bit, bit 7 by
  andi.b #-128; booleans of two bytes set or cleared by one word or/and),
  adjacent fields cleared or copied by one longword move (split into
  their fields), block copies through two postincrement registers,
  constants copied from the code (lea pc), the low byte or word of a
  longer field, a node byte sign-extended, the high/low word by swap and
  clr.w, abs, the run time's 32-bit arithmetic (m$mis$lll, m$ois$lll,
  m$ois$wlw, m$dis$lll ... written as *, mod, div; they leave D1 alone),
  lir_4090, isc_readonly_tables' byte and longword tables, il_180 and
  two cargs_$options flags.  **Short-circuit conditions**: from a
  conditional branch the lifter collects the blocks that only compute a
  condition (loads, compares, tests, set bytes, frame temporaries and
  function calls whose arguments they push) and reduces their graph to
  one condition with and/or (four rules: x or y, x or not y, x and y, x
  and not y, while a block has one way in); each exit gets the registers
  every way into it agrees on.  Without this the p2 lifter duplicates the
  then-part into every or-arm.  The join of an if/else also merges
  frame temporaries (a value set on both arms: p2's branch kept the
  then-arm's) and gives a phi of a boolean and a register's dead value
  the boolean.  **The skeleton** is then matched on the statements:
  `result := nil; work := nil', nested ifs (the conditions) with temps'
  assignments between them, the trace, the cycle guard and its trace,
  new_solution(isc_heap, the rule's kind, 0, inh, il, 0) (temps Rev 8.89
  computes before its first stores move to the body), which_transform,
  before_transform, the seven already_ copies, the flag, `work := s;
  result := s'; for a proper_subtree rule `result := subject'.  What
  does not match is residue.
- `tools/iscg_p1lang.py`: the clause (its docstring is the grammar):
  `pass_1 image A [rewrite] [hand [dropped]] begin ... end;' with
  `condition e;' (one per nesting level), `cycle_guard already_X;',
  `cycle_mark already_X;' (11 chain rules set the flag without the
  test), the macros `copy f, g from P [to S];' and `sum f, g of P, Q [to
  S];', `trace 'text';', and inline cost tables `bytes(v1, ..)[e]',
  `words(..)[e]' (entry k = vk, 0 and the rest zero; `bytes@k(...)'
  places a table where the image's layout is not the reverse of the
  clause: 8 rules); the Emitter (result is the local `solution', subject
  the var record, `subject' alone its address, the rule's own longwords
  that hold numbers through a view p1_int_fields_t, a boolean kept in a
  rule's byte as 255 * ord(b), and/or operands parenthesized for Pascal's
  precedence).
- `tools/iscg_p1gen.py`: the clauses in the rule file (extract_bodies,
  hand_clauses kept by the extractor), the modules and the manifest's
  `module' lines (all 25: their A5s bound the data blocks before them).

**The cost tables** (2.6, decoded): every table is `array [0..16]' of
bytes (memory_references, delay) or words (code_bytes), indexed by an
alternative's choice byte; entry 0 is always 0, no entry past 11 is
non-zero; each is read exactly once in the image, so the clause writes
it inline where it is used.  A rule's tables lie in the reverse of their
order in the code (the generator built them by pushing), rules in rule
order, each table on 8 bytes (17 bytes take 24, 17 words 40; pattern
188).  The modules declare them as p1_byte_costs_t (packed array
[0..23]) and p1_word_costs_t (array [0..19]) with 17 initial values,
the module's last table unpadded (its block ends 4 bytes before the next
module's A5: the next pas_$output), which dpc lays out as the image
does (dpc gap 47).  4,049 tables in the 21 generated modules (6,020 in
the clauses): no data difference but module 02's past 32 KB, where Rev
8.89 allocated otherwise (pattern 189, questions 297: a
cc_datacheck_known.txt entry).

**Coverage**: 556 lifted, 2 hand (399, 402: `dropped': Rev 8.89 kept only
the condition's first test; the generator writes the test with an empty
arm), 5 residue: rules 9, 10 (a double compared with zero through the
FPP emulation, fpp_$ with inline operands: dpc gap 7's ground), 20 (a
longword of target_properties +0x9C, inside its unnamed p_94), 211 (the
signed-division idiom on a value joined from two arms after a call), 177
(btst by a register).  Sections 07, 12, 23 and 24 are therefore not
generated.  In the lifted clauses: 472 conditions, 304 statements
between them, 372 cycle guards, 13 rewrites, 13,599 assignments, 161
copy (5,247 fields) and 218 sum (575 fields) macros, 3,995 ifs, 1,291
temps.

**The modules**: the generator writes the skeleton around each clause
(the trace as `write(...); writeln;', gap 4's rewrite line per module in
cc_gap_rewrites.txt), the views the bodies need (p2's node, flags and
locals views; p1_already_t for the guard's flags at +342..+348,
p1_int_fields_t, p1_snode_t, p1_readonly_t), the tables, one routine
per rule.  Similarity (cc.a88k, non-identical routines): 0.34 (21) ..
0.51 (08), 0.53 .. 0.75 modulo registers.  Gap 25 (dpc runs out of
registers; the check compiles them empty): 02's 153, 157, 158, 169, 170;
09's 445, 450, 474; 10's 423; 14's 384; 25's 120, 121.  tools/cc_typecheck.sh
reports only gap 4's message.

**Tested**: the extraction gives the same rule file under any
PYTHONHASHSEED (no set iterated for output); iscg_gen.py --check passes.

**What remains**: the 5 residue actions (sections 07, 12, 23, 24); names
(the tables', the temps', questions 266, 286); the cc_datacheck_known.txt
entry for isc_pass_1_main's span is gone (the manifest's A5s end its
block at module 01's); the 4 ungenerated pass-1 modules' data are checked
by nobody until their modules exist.  Questions 450 .. 455, patterns
188 .. 371, dpc gap 47.

