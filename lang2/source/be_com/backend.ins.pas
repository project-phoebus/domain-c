{ lang2/source/be_com/backend.ins.pas - the PRISM back end's common
  insert (cc.a88k only): opened by every be_com unit but
  target_at_dummies and exs, by call_conv and by the ISC units, after
  the lang prelude (and at_base.ins.pas where a unit opens it) and
  before lt_utils mrh.ins.pas, lang prtsub.ins.pas,
  be_prism/target.ins.pas and the opcode enumeration.  So it may use
  only the prelude's types and mrh's (opened just before it by most
  units, just after it by others: it declares nothing of mrh's), and
  the opcodes (opc$t) only in what follows target.ins.pas: the opcode
  fields here are words (opc$w_t).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  Apollo built several initializers from this insert (DSEE
  derived objects backend.ins.pas/hbe6404cd.000/backend.ins/*.init:
  am_string, block_string, lsq_string, rrp_string, operand_letter,
  rrp_letter, register_letter, lsq_suffix, of_string, operand_string,
  operand_forms_mask, the amse_ tables, move_opcode, build_access,
  solution_kind), so its enumerations' element names survive as those
  tables' strings: the sections operand_string (0x2B6E0C) and of_string
  (0x2B7184), and dmp's module data (am, block, lsq, rrp at +0x120
  .. +0x23E).  The generator strips a prefix (of_string has
  "0_mod_2_s_immed16"): the prefixes here follow the image's other
  generated enumerations (OPC$, ARG_LOC$, SOLUTION$).

  The back end's objects, as the leaf units use them:
  - a routine (rtn_t, what each phase's process_routine is passed);
  - its live ranges (lr_t, rtn +52) with their lifetime segments
    (lts_t, an lr's +36);
  - its basic blocks (bb_t, rtn +76 in code order, chained at +118),
    each with its instructions (instr_t, bb +34 first, +38 last,
    chained at +4 and +8);
  - an instruction's operands (opnd_t, 12 bytes from +44: operand k at
    +32 + 12k, its +0 holding k, so utils_ins_$operands_instruction
    finds the instruction from any operand);
  - the opcodes' attributes (instr_attr_t, the section
    instruction_attributes, 20 bytes by opcode);
  - the code cells zzzzz makes from the instructions (cell_t).

  Not known from the original: every type, field, cell and parameter
  name here but the routines' (the .blocks names) and the enumerations'
  elements (above); fields are named by offset where their use is not
  yet known.  The headings were read off the callees' frames and the
  callers' pushes (a pointer univ_ptr, a longword integer32, a word
  integer, a byte boolean; p1..pn): each unit's translator narrows its
  own. }

{ TODO(pascal) backend.ins.pas: the records hold what the leaf units
  (dfa, sem_utils, xtp, zzzzz) and the routines' allocations show;
  rtn_t, bb_t, lr_t and lts_t are mostly unnamed space. }

type
  { An opcode as the records hold it: a word (opc$t's ordinal; the
    enumeration is opened after this insert). }
  opc$w_t = 0..383;

  { The kinds of operand (operand_string, 32 entries of 25 characters:
    "none", "ip_reg", ...; operand_letter's 'I', 'F', 'P', ... in dmp).
    An operand's +3 bits 4..0. }
  operand$t = (
    operand$none, operand$ip_reg, operand$fp_reg,  { 0 }
    operand$fp_reg_pair, operand$ip_reg_physical,
    operand$fp_reg_physical, operand$fp_reg_pair_physical,
    operand$ip_condition_codes, operand$fp_condition_codes,  { 7 }
    operand$argument_block_memory, operand$inscrutable_memory,
    operand$well_behaved_memory, operand$ip_reg_like,
    operand$fp_reg_like, operand$fp_reg_pair_like,
    operand$forward_label_reference, operand$flow_graph_edge,  { 15 }
    operand$case_jump_base, operand$displacement_routine,
    operand$displacement_arg_block, operand$displacement_stack_frame,
    operand$displacement_literal_pool, operand$displacement_XSB_base,
    operand$immediate, operand$bind_time_immediate,  { 23 }
    operand$symbol_definition, operand$label_reference,
    operand$join_birthpoint_inputs, operand$exception_information,
    operand$spare_3, operand$spare_2, operand$spare_1);  { 29 }

  { The operand forms an instruction's operand may take (of_string, 44
    entries of 34 characters, the last empty; asm and lir print them). }
  of$t = (
    of$none, of$ip_reg_or_long_pc_disp, of$ip_reg_or_basic_block,
    of$ip_compare_a_operand, of$fp_reg_pair, of$short_pc_disp,  { 5 }
    of$ip_reg_or_s_immed11, of$ip_reg_scaled_or_s_immed8, of$s_immed16,
    of$ip_reg_or_s_immed8, of$ip_reg_scaled_or_s_immed16,  { 10 }
    of$ip_reg_or_s_immed16, of$ip_reg_or_u_i16_or_hi_i16, of$u_immed13,
    of$ip_reg_or_and_or_bic_u_immed16, of$sc_reg_or_u_immed5,  { 15 }
    of$ip_reg_or_u_immed5, of$fp_reg_quad, of$ip_reg, of$fp_reg,
    of$u_immed4, of$ip_reg_scaled_or_pa_add_immed,  { 21 }
    of$trap_serialize_register, of$ip_reg_or_s_immed5,
    of$0_mod_2_s_immed16, of$0_mod_4_s_immed16,  { 25 }
    of$ip_reg_or_s_u_hi_immed16, of$ip_reg_or_0_mod_2_s_immed16,
    of$ip_reg_or_0_mod_4_s_immed16, of$ip_reg_or_0_mod_8_s_immed16,
    of$ip_reg_or_0_mod_16_s_immed16, of$ip_reg_or_s_immed14,  { 31 }
    of$control_register, of$ip_reg_scaled_3_or_s_immed5,
    of$ip_reg_scaled_2_or_s_immed5, of$signed_immed11,  { 35 }
    of$ip_reg_scaled_2_or_s_immed14, of$ip_reg_scaled_or_pa_move_immed,
    of$u_immed5, of$ip_reg_scaled_3_or_s_immed14, of$signed_immed14,
    of$space_register, of$ip_reg_scaled_1_or_s_immed14);  { 42 }

  { Addressing modes (dmp's am_string: 3 of 10 characters). }
  am$t = (am$nomodify, am$postmodify, am$premodify);

  { Load and store qualifiers (dmp's lsq_string, 4 of 8). }
  lsq$t = (lsq$normal, lsq$lock, lsq$unlock, lsq$physical);

  { Basic block kinds (dmp's block_string, 4 of 6). }
  block$t = (block$normal, block$start, block$final, block$return);

  { A lifetime segment's properties (dmp's rrp_string, 16 of 17
    characters; rrp_letter one letter each), a set. }
  rrp$t = (
    rrp$fp_reg_even_only, rrp$fp_reg_odd_only, rrp$modify, rrp$write,
    rrp$read, rrp$intend_to_modify, rrp$unconsumed, rrp$spare_1,
    rrp$life_mark, rrp$ra_marked, rrp$true_write, rrp$store_through,
    rrp$unique_value, rrp$safe_base_address, rrp$fp_reg, rrp$ip_reg);
  rrp$set_t = set of rrp$t;

  { Where an argument is passed (the ISC's arg_loc_t_to_string writes
    one: its identifier table at cc.a88k 0x216F3A; lir's
    build_arg_loc.init).  The type's name is the ISC routine's. }
  arg_loc_t = (
    arg_loc$ip_reg, arg_loc$fp_reg, arg_loc$fp_reg_pair,
    arg_loc$fp_reg_quad, arg_loc$memory, arg_loc$ctl_reg,
    arg_loc$sr_reg);

const
  { Instruction classes: instr_attr_t's class (+7), copied to an
    instruction's +40.  The values group the opcodes as below; no
    names survive. }
  class$alu = 0;                        { tst, cmp, move, add, ..., nop,
                                          costly, bugcheck, none, adj_move }
  class$branch = 1;                     { bnever .. bv }
  class$call = 2;
  class$fp_double = 3;                  { copyd .. truncdi5 }
  class$entry = 4;
  class$fp_branch = 5;                  { fbeq .. fblt }
  class$jump = 6;                       { jump, dispatch }
  class$enable = 7;                     { enable, disable }
  class$immediate = 8;                  { movei .. xori, cvtis, cvtid,
                                          muli, divi, fnop }
  class$seq = 9;                        { seq, mmt_seq }
  class$synch = 10;                     { synchb, synchw, synch }
  class$limit = 11;
  class$fp_control = 12;                { mffp, fpquiesce, mtfp }
  class$ipccnop = 13;
  class$trap = 14;
  class$load_pair = 15;
  class$load = 16;                      { loadbu .. loadd }
  class$fp_single = 17;                 { copys .. truncsi5 }
  class$pmove = 18;                     { pmove, pmovei, pcopys, pcopyd }
  class$label = 19;                     { epilogue, label, label$ }
  class$svc = 20;                       { svc, svc2 }
  class$store = 21;                     { storeb .. stored }
  class$mfpr = 22;
  class$mtpr = 23;
  class$return = 24;
  class$table = 25;                     { ltorg, tableb, tablew, tablel }
  class$join_bp = 26;
  class$trap_cond = 27;                 { trap_gt .. trapd_flt }

type
  instr_ptr_t = ^instr_t;
  opnd_ptr_t = ^opnd_t;
  bb_ptr_t = ^bb_t;
  lr_ptr_t = ^lr_t;
  lts_ptr_t = ^lts_t;
  rtn_ptr_t = ^rtn_t;
  cell_ptr_t = ^cell_t;

  { batch A: bit vectors (bv.pas): bit k of a vector is bit k mod 32 of
    its longword k div 32 (bv_$test: `lsr.w #5', `and.w #31', `btst
    Dn,Dn'), so a longword is a set of 0..31 in dpc's layout.  A live
    range's complex id (its +4 word) numbers its bit.  The routine's
    map from complex ids to live ranges (+60) is an array of them. }
  bv_word_t = set of 0..31;
  bv_t = array [0..65535] of bv_word_t;
  bv_ptr_t = ^bv_t;
  lr_map_t = array [0..65535] of lr_ptr_t;
  lr_map_ptr_t = ^lr_map_t;
  fg_edge_ptr_t = ^fg_edge_t;

  { An opcode's attributes (the section instruction_attributes, 20
    bytes by opcode, for opc$undefined..opc$adj_move).  Fields by
    offset: b6_0 (lir's opt_new_instruction copies it to an
    instruction's +0 bit 6), class (+7: class$...), b11 (bit 7 copied
    to an instruction's +2 bit 5; bits 6..3 the operands an
    instruction of the opcode has when made with its default size;
    bits 2..0 nresults, the operands it writes: sem_utils, zzzzz),
    b14_0, b15, b19 (bits read by post, utils, ra_utils). }
  instr_attr_t = packed record
    w0: 0..65535;                       { +0 }
    w2: 0..65535;                       { +2 }
    b4: 0..255;                         { +4 (asm: compared with 10) }
    num1: 0..255;                       { +5: 1 in every entry }
    b6_7_1: 0..127;                     { +6 }
    b6_0: boolean;
    class: 0..255;                      { +7: class$... }
    form2: 0..255;                      { +8 }
    num2: 0..255;                       { +9: 2 }
    b10: 0..255;                        { +10 }
    b11_7: boolean;                     { +11 }
    nopnds: 0..15;
    nresults: 0..7;
    b12: 0..255;                        { +12 }
    num3: 0..255;                       { +13: 3 }
    b14_7_1: 0..127;                    { +14 }
    b14_0: boolean;
    b15: 0..255;                        { +15 }
    b16: 0..255;                        { +16 }
    num4: 0..255;                       { +17: 4 }
    w18: 0..65535;                      { +18 }
  end;
  instr_attrs_t = array [0..211] of instr_attr_t;

  { An operand (12 bytes; an instruction's k-th at its +32 + 12k).  The
    first longword is one packed record (dpc lays a 0..255 field of an
    unpacked record out as a word): num (+0) is k (zzzzz compares a
    register operand's with 31, the zero register, most likely); +1 the
    low byte of
    rrp$set_t (xtp copies its bits 3..2 to a segment's rrp and sets
    0x30 for an operand that reads and means to modify; sem_utils tests
    read); +2 bits 5..4 a count sem_utils subtracts; +3 bits 4..0 the
    kind (operand$t).  link (+4) the operand it is tied to (the
    definition a use reads: utils_ins_$operands_instruction of it); +8
    the immediate value, or a register operand's lifetime segment.
    batch A (fga): an immediate's, a bind-time immediate's and an XSB
    displacement's +4 (link) points to its node (a constant or symbol);
    a flow graph edge operand's +8 is the edge. }
  opnd_hdr_t = packed record
    num: 0..255;                        { +0 }
    spare_1: boolean;                   { +1 .7 (rrp$'s elements 7..0) }
    unconsumed: boolean;
    intend_to_modify: boolean;
    read: boolean;                      { .4 }
    write: boolean;
    modify: boolean;
    fp_reg_odd_only: boolean;
    fp_reg_even_only: boolean;
    b2_7, b2_6: boolean;                { +2 }
    count: 0..3;                        { .5..4 }
    b2_3_0: 0..15;
    b3_7, b3_6, b3_5: boolean;          { +3 }
    kind: operand$t;                    { .4..0 }
  end;
  opnd_t = record
    h: opnd_hdr_t;                      { +0 }
    link: opnd_ptr_t;                   { +4 }
    case integer of                     { +8 }
      1: (value: integer32);
      2: (lts: lts_ptr_t);
      3: (ptr: univ_ptr);
  end;

  { An instruction (lir's opt_new_instruction: 44 bytes and 12 for each
    operand, from the routine's heap).  The first longword (h) is one
    packed record: +0 b6 the opcode's b6_0, b4 (sets_cc) marks one
    that sets the condition codes (xtp puts an IPCCNOP after it; zzzzz
    lists one whose result is register 31 as a TST or CMP), b2
    (grouped) one of a
    group that runs on (xtp: insert_ipccnop skips them), b1 copied from
    the instruction it is put next to (instr_bug_check: then +32 points
    to the source position); nopnds (+1) its operands; +2 bit 5 the
    opcode's b11_7; width (+3) the field width of an insert or extract
    (sem_utils).  next/prev (+4, +8) in its block, bb (+12) the block;
    opc (+20); +28 and +32 the source position zzzzz copies to a code
    cell (+32 the line, a word, or a pointer; copied from the
    instruction it is put next to); class (+40, the opcode's); num
    (+42) its serial number (lir +0x4214).  zzzzz makes a label's
    instruction its own code cell (cell_t's layout over it). }
  instr_hdr_t = packed record
    b0_7: boolean;                      { +0 }
    b0_6: boolean;
    b0_5: boolean;
    sets_cc: boolean;                   { .4 }
    b0_3: boolean;
    grouped: boolean;                   { .2 }
    b0_1: boolean;
    b0_0: boolean;
    nopnds: 0..255;                     { +1 }
    b2_7, b2_6, b2_5, b2_4, b2_3, b2_2, b2_1, b2_0: boolean;   { +2
                                          (b2_6: df_utils marks an
                                          instruction the global walk
                                          reached, fga and hal one that
                                          must stay) }
    width: 0..255;                      { +3 }
  end;
  instr_t = record
    h: instr_hdr_t;                     { +0 }
    next: instr_ptr_t;                  { +4 }
    prev: instr_ptr_t;                  { +8 }
    bb: bb_ptr_t;                       { +12 }
    l16: integer32;                     { +16: a walk's mark (tr_utils;
                                          df_utils: queued in this walk) }
    opc: opc$w_t;                       { +20 }
    w22: integer;                       { +22 }
    l24: integer32;                     { +24 (df_utils: the next in its
                                          work queue, the last pointing
                                          to itself) }
    l28: integer32;                     { +28: source position }
    l32: integer32;                     { +32: source position (df_utils,
                                          fga: the next on lir_main_c44's
                                          chain) }
    l36: integer32;                     { +36 }
    class: char;                        { +40: class$... }
    b41: char;                          { +41 }
    num: integer;                       { +42 }
    opnds: array [1..255] of opnd_t;    { +44 }
  end;

  { A basic block.  num (+10) its number (printed with an
    instruction's num as nnn:nnn); +16..+19 one packed record: +17 bit
    5 (xtp), +19 bit 4 (needs_label: zzzzz); first and last
    instructions (+34, +38); next in code order (+118). }
  bb_flags_t = packed record
    b16: 0..255;                        { +16 }
    b17_7, b17_6: boolean;              { +17 }
    b17_5: boolean;                     { .5 (xtp) }
    b17_4, b17_3, b17_2, b17_1, b17_0: boolean;
    b18_7: boolean;                     { +18 }
    b18_6: boolean;                     { .6 (tr_utils: the head of its
                                          interval) }
    b18_5: boolean;                     { .5 (tr_utils: of an interval
                                          head) }
    b18_4, b18_3, b18_2, b18_1, b18_0: boolean;
    b19_7, b19_6, b19_5: boolean;       { +19 }
    needs_label: boolean;               { .4 (zzzzz) }
    b19_3, b19_2, b19_1, b19_0: boolean;
  end;
  bb_t = record
    l0: integer32;                      { +0 }
    l4: integer32;                      { +4 }
    w8: integer;                        { +8 }
    num: integer;                       { +10 }
    order: 0..65535;                    { +12: its place in the order
                                          the live ranges' segment lists
                                          follow (utils; tr_utils orders
                                          segments by it: `clr.l;
                                          move.w', unsigned; batch A
                                          (PA): was w12, batch C (PC):
                                          w12) }
    f14: packed record                  { +14 }
      b14: 0..255;                      { (tr_utils: compared with 1 and
                                          2) }
      b15: 0..255;
      end;
    f: bb_flags_t;                      { +16 (utils: +19 bit 1 marks a
                                          block find_definition saw) }
    f20: packed record                  { +20 }
      b20_7: boolean;
      b20_6: boolean;                   { .6 (tr_utils) }
      b20_5, b20_4: boolean;
      b20_3: boolean;                   { .3 (tr_utils) }
      b20_2, b20_1, b20_0: boolean;
      b21: 0..255;                      { +21 }
      end;
    succs: fg_edge_ptr_t;               { +22: edges out, chained at
                                          their next_succ (bv,
                                          tr_utils; batch C: l22) }
    preds: fg_edge_ptr_t;               { +26: edges in, chained at
                                          their next_pred (bv,
                                          tr_utils; batch C: l26) }
    w30: integer;                       { +30 }
    w32: integer;                       { +32 }
    first: instr_ptr_t;                 { +34 }
    last: instr_ptr_t;                  { +38 }
    space42: array [42..45] of char;    { +42 }
    l46: bb_ptr_t;                      { +46: its first child in the
                                          dominator tree (hal; batch A) }
    l50: bb_ptr_t;                      { +50: its next sibling there
                                          (hal; batch A) }
    l54: bb_ptr_t;                      { +54: a list of blocks
                                          utils_$locate_definition
                                          searches first (hal walks up
                                          through it from a loop's exit:
                                          its immediate dominator, most
                                          likely) }
    l58: bb_ptr_t;                      { +58: hal's candidates for the
                                          end of a hammock headed here,
                                          chained through their l58 (its
                                          immediate postdominator, most
                                          likely; batch A) }
    exposed: lts_ptr_t;                 { +62: its exposed segments
                                          (with lir_main_c86 0; chained
                                          at their +16) }
    finals: lts_ptr_t;                  { +66: its final segments
                                          (chained at +20) }
    l70: bb_ptr_t;                      { +70: the head of its interval
                                          (tr_utils' bb_interval) }
    l74: univ_ptr;                      { +74 (hal: a loop head without
                                          it gets a tail block; batch A) }
    l78: bb_ptr_t;                      { +78: a chain hal puts a new
                                          block on after the block it
                                          precedes (batch A) }
    l82: bb_ptr_t;                      { +82 (tr_utils: the hammock
                                          head, of a block not one) }
    live_out: bv_ptr_t;                 { +86: the union of the
                                          successors' live_in (bv;
                                          tr_utils sets a live range's
                                          bit when its segment is final
                                          in the block; batch C: l86) }
    live_gen: bv_ptr_t;                 { +90: read before written
                                          (batch C: l90, exposed) }
    live_in: bv_ptr_t;                  { +94: (live_out and
                                          transparent) or live_gen
                                          (batch C: l94, exposed) }
    l98: fg_edge_ptr_t;                 { +98: an edge (tr_utils: its
                                          target follows the hammock);
                                          batch A: hal's hammock record
                                          (hal_hammock_t: head +0, the
                                          block after it +4, so the
                                          edge's target is that block) }
    l102: bb_ptr_t;                     { +102: the first block of its
                                          hammock (tr_utils) }
    l106: bb_ptr_t;                     { +106: the next block of the
                                          hammock (tr_utils) }
    transparent: bv_ptr_t;              { +110: not written in the
                                          block (all ones initially;
                                          batch C: l110, written) }
    next114: bb_ptr_t;                  { +114: the order (from the
                                          routine's +72) bv's backward
                                          propagation walks: the block
                                          before it in code order (hal
                                          links a new block in before a
                                          block through next and
                                          next114) }
    next: bb_ptr_t;                     { +118 }
    avail_in: bv_ptr_t;                 { +122: the predecessors'
                                          avail_out, joined (bv) }
    avail_out: bv_ptr_t;                { +126: (avail_in and
                                          transparent) or avail_gen
                                          (hal keeps the block's
                                          dominators there while it
                                          finds hammocks: bit order) }
    avail_gen: bv_ptr_t;                { +130 }
    l134: univ_ptr;                     { +134: segments by block,
                                          chained at their next, while
                                          df_utils rebuilds the live
                                          ranges' lists; fga walks the
                                          blocks through it (batch A) }
    space138: array [138..145] of char; { +138 }
    mark146: integer32;                 { +146: a visit mark (utils'
                                          look_for_path, tr_utils;
                                          batch C: l146) }
    l150: bb_ptr_t;                     { +150: hal's work list (batch
                                          A) }
  end;

  { A flow graph edge (bv, tr_utils; zzzzz's zz_edge_t reads the
    target): on its source's list of edges out (succs, +22) chained at
    next_succ, and its target's of edges in (preds, +26) chained at
    next_pred.  Batches A and C each declared it (batch C as bb_edge_t,
    next_out, next_in); batch A's names kept. }
  fg_edge_t = record
    source: bb_ptr_t;                   { +0 }
    target: bb_ptr_t;                   { +4 }
    next_succ: fg_edge_ptr_t;           { +8 }
    next_pred: fg_edge_ptr_t;           { +12 }
  end;

  { A lifetime segment: rrp (+0) its properties (xtp: an IPCCNOP's
    result segment gets modify and loses write); +3 bit 4 (xtp: a
    condition code segment's that needs no IPCCNOP when clear); refs
    (+4) the operands that refer to it, the definition first; next (+8) in its live range's
    list; +40 a longword dfa clears; lr (+48) its live range. }
  { batch A (utils): num, exposed, first_in_bb, final, refs (was def),
    bb .. mark named; l44 was integer32.  The operands that refer to a
    segment (its definition first, then its readers) are chained from
    its refs through their link (+4); an
    exposed segment's l44 is the final segment (of another block) that
    reaches it, whose l28 heads the exposed segments it reaches
    (chained at their l28); a join birthpoint's segment's l44 heads its
    inputs (records chained at +0, utils' ut_jbi_t). }
  lts_t = record
    rrp: rrp$set_t;                     { +0 }
    f2: packed record                   { +2 }
      num: 0..255;                      { its number in the live range
                                          (printed lr.num; batch C: b2) }
      exposed: boolean;                 { +3.7: on the block's exposed
                                          list (batch C: b3_7) }
      first_in_bb: boolean;             { .6: the live range's first in
                                          its block (tr_utils: set on
                                          one segment of its live range
                                          in each block; batch C: b3_6) }
      b3_5: boolean;
      final: boolean;                   { .4: on the block's final list
                                          (xtp, tr_utils; batch C:
                                          b3_4) }
      b3_3: boolean;
      b3_2: boolean;                    { .2 (tr_utils: marked) }
      b3_1, b3_0: boolean;
      end;
    refs: opnd_ptr_t;                   { +4: the operands that refer to
                                          it, its definition first
                                          (MM's and batch C's def) }
    next: lts_ptr_t;                    { +8: in its live range's list,
                                          by block order }
    bb: bb_ptr_t;                       { +12: its block }
    next_exposed: lts_ptr_t;            { +16 }
    next_final: lts_ptr_t;              { +20 }
    l24: integer32;                     { +24 (utils clears it in phase
                                          9) }
    l28: lts_ptr_t;                     { +28 (chained from l44's) }
    l32: integer32;                     { +32 }
    mark: integer32;                    { +36: the walks' marks }
    l40: integer32;                     { +40 (dfa clears it) }
    l44: univ_ptr;                      { +44: an lts_ptr_t (the final
                                          segment that reaches it;
                                          tr_utils: the one it was
                                          merged after) or a join's
                                          inputs (batch C had
                                          lts_ptr_t) }
    lr: lr_ptr_t;                       { +48 }
  end;

  { A live range: rrp (+0) its properties (xtp sets read, modify and
    intend_to_modify); chained from the routine's lrs (+52) at +12; sym
    (+24) what it holds (an IL node: xtp reads its kind at +2 and a
    longword of flags at +24, at +32 for kind 109); ltss (+36) its
    segments. }
  lr_t = record
    rrp: rrp$set_t;                     { +0 }
    f2: packed record                   { +2 }
      b2: 0..255;
      b3_7: boolean;                    { .7 (tr_utils: its uses depend
                                          on every instruction; utils
                                          tests it with `tst.b (3)':
                                          batch A read +2 as a word w2
                                          and 16#80) }
      b3_6, b3_5, b3_4, b3_3: boolean;
      b3_2: boolean;                    { .2 (tr_utils: marked) }
      b3_1, b3_0: boolean;
      end;
    id: 0..65535;                       { +4: its complex id, its bit
                                          in the bit vectors (bv; 0 for
                                          none; batch C: w4) }
    num: integer;                       { +6: its number (printed;
                                          batch C: w6) }
    l8: integer32;                      { +8 }
    next: lr_ptr_t;                     { +12 }
    mate: lr_ptr_t;                     { +16: its mate, the other half
                                          of a pair: made complex with
                                          it (bv), merged with it
                                          (tr_utils_$merge_lrs; batch
                                          A: lr16, batch C: l16) }
    node20: univ_ptr;                   { +20: an IL node (a VAR_NAME,
                                          109, or 110: utils reads its
                                          flags; batch C: l20) }
    sym: univ_ptr;                      { +24 }
    l28: integer32;                     { +28 }
    l32: integer32;                     { +32 }
    ltss: lts_ptr_t;                    { +36 }
    l40: integer32;                     { +40 (tr_utils: a serial
                                          number) }
    l44: integer32;                     { +44 }
    l48: integer32;                     { +48 }
    l52: lr_ptr_t;                      { +52 (tr_utils: the marked
                                          live ranges' chain) }
    w56: integer;                       { +56: its segments' count }
    w58: integer;                       { +58 }
    l60: integer32;                     { +60 }
    { batch A (utils): the segment lists by block (lir_main_c86 1) and
      their hints (the last found and the one before it, valid with
      lir_main_c8d). }
    exposed_hint: lts_ptr_t;            { +64 }
    exposed_prev: lts_ptr_t;            { +68 }
    exposed: lts_ptr_t;                 { +72 (tr_utils_$merge_lrs
                                          clears it; batch C: l72) }
    finals: lts_ptr_t;                  { +76 (likewise; batch C:
                                          l76) }
    final_hint: lts_ptr_t;              { +80 }
    final_prev: lts_ptr_t;              { +84 }
  end;

  { A routine being compiled: what at_backend's phases are passed.
    node (+0) its IL node (whose +188 zzzzz reads); lrs (+52) its live
    ranges; bbs (+76) its basic blocks in code order; cells (+88) the
    code cells zzzzz makes, epilogues (+92) zzzzz's epilogue marks
    (code cells chained at +12); l112 (+112) the segment a returning
    jump's operand 1 has (zzzzz); l192 (+192) passed on by dfa and xtp
    to df_utils_$global_walk. }
  rtn_t = record
    node: univ_ptr;                     { +0: an il_$node_ptr_t (batch
                                          A: univ_ptr, since fga, hal,
                                          life, sanity, sym and tm_utils
                                          open this insert without the
                                          prelude's il.ins.pas) }
    space4: array [4..51] of char;      { +4 }
    lrs: lr_ptr_t;                      { +52 }
    lrs_last: lr_ptr_t;                 { +56: the last live range
                                          (lir_$alloc_live_range,
                                          mmt_utils) }
    lr_map: lr_map_ptr_t;               { +60: the live ranges by
                                          complex id (bv) }
    space64: array [64..71] of char;    { +64 }
    bbs72: bb_ptr_t;                    { +72: the blocks in the order
                                          bv's backward propagation
                                          walks (chained at +114) }
    bbs: bb_ptr_t;                      { +76 }
    bb80: bb_ptr_t;                     { +80: a block the memory live
                                          range is live out of (df_utils:
                                          batch A) }
    space84: array [84..87] of char;    { +84 }
    cells: cell_ptr_t;                  { +88 }
    epilogues: cell_ptr_t;              { +92 }
    return_instr: instr_ptr_t;          { +96: its RETURN (fga's
                                          messages; batch A) }
    ap_lr: lr_ptr_t;                    { +100: the argument pointer's
                                          live range, the RETURN's
                                          operand 3 (fga); df_utils makes
                                          it complex for every walk
                                          (batch A) }
    space104: array [104..107] of char; { +104 }
    lr108: lr_ptr_t;                    { +108: a live range df_utils
                                          always makes complex and never
                                          drops (batch A) }
    l112: lts_ptr_t;                    { +112: zzzzz compares a
                                          returning jump's operand 1
                                          segment with it, but df_utils
                                          makes it complex and compares
                                          live ranges with it: a live
                                          range (cast there) }
    space116: array [116..139] of char; { +116 }
    lr140: lr_ptr_t;                    { +140: a live range df_utils
                                          always makes complex (batch A) }
    memory_lr: lr_ptr_t;                { +144: the memory live range
                                          (df_utils: "Memory LR"; batch
                                          A) }
    space148: array [148..179] of char; { +148 }
    marks: integer32;                   { +180: the walks' marks and
                                          serial numbers, counted up
                                          (utils, tr_utils_$mark_dependents;
                                          batch C: l180) }
    nbbs: integer32;                    { +184: its blocks (bv) }
    l188: integer32;                    { +188 }
    l192: integer32;                    { +192: its complex live
                                          ranges, the last complex id
                                          given (bv) }
    space196: array [196..199] of char; { +196 }
    l200: integer32;                    { +200: the number of the last
                                          live range life splits
                                          (batch A) }
    space204: array [204..225] of char; { +204 }
    f226: packed record                 { +226 (batch A: fga) }
      b226_7, b226_6, b226_5, b226_4, b226_3: boolean;
      b226_2: boolean;                  { .2: sets b226_0 (fga) }
      b226_1: boolean;
      b226_0: boolean;                  { .0: the AP read may be taken
                                          out of the RETURN (fga) }
      b227_7: boolean;                  { +227 }
      b227_6: boolean;                  { .6: some block may be resumed
                                          asynchronously (fga) }
      b227_5, b227_4, b227_3, b227_2, b227_1, b227_0: boolean;
      end;
    f228: packed record                 { +228 }
      b228_7, b228_6, b228_5, b228_4, b228_3: boolean;
      b228_2: boolean;                  { .2 (tr_utils) }
      b228_1, b228_0: boolean;
      end;
  end;

  { A code cell (zzzzz): what bin, lst and asm emit, 20 bytes and 12
    for each operand (opnds, the instruction's operands copied).  The
    first longword (h) is one packed record: +0 flags (bits 7..5
    zzzzz's, bits 4..0 cleared), opc (+1) the opcode as a byte, +3 bit
    5 set on a label's.  next (+4), +8 and +16 the instruction's source
    position (+28, +32), +12 a label's symbol or number (or the next
    epilogue mark), +12 of a case table its entries' count. }
  cell_hdr_t = packed record
    b0_7, b0_6, b0_5: boolean;          { +0 }
    b0_4, b0_3, b0_2: boolean;
    b0_1: boolean;                      { .1: +16 points to the source
                                          position (the instruction's
                                          +0 bit 1) }
    b0_0: boolean;
    opc: 0..255;                        { +1 }
    b2: 0..255;                         { +2 }
    b3_7, b3_6: boolean;                { +3 }
    is_label: boolean;                  { .5 }
    b3_4_0: 0..31;
  end;
  cell_t = record
    h: cell_hdr_t;                      { +0 }
    next: cell_ptr_t;                   { +4 }
    l8: integer32;                      { +8 }
    l12: integer32;                     { +12 }
    l16: integer32;                     { +16 }
    opnds: array [1..255] of opnd_t;    { +20: zzzzz's local cell is
                                          3080 bytes }
  end;

  { The current phase's debug switches (at_backend +0x500: the phase
    letter's word of cargs_$debug_switches, set by run_phase and
    begin/end_compilation), MSB first: sw8 makes at_backend print the
    phase's name around each call; level (bits 2..0) is passed on as
    a number (dfa, xtp). }
  at_switches_t = packed record
    sw15, sw14, sw13, sw12, sw11: boolean;   { +0x500 .7.. .3 }
    sw10: boolean;                      { .2 (xtp) }
    sw9: boolean;                       { .1 (dfa, xtp) }
    sw8: boolean;                       { .0 }
    sw7, sw6, sw5, sw4: boolean;        { +0x501 .7 .. .4 }
    sw3: boolean;                       { .3 (dfa) }
    level: 0..7;                        { .2..0 }
  end;

  { batch B: the views lst, bin and asm (translator PB) read the
    opcode tables and the code cells through. }

  { instr_attr_t as four operand descriptions from +4, one longword
    each: form (of$t: lst prints an immediate of form
    of$ip_compare_a_operand negated, `#' before the forms of its
    set), num (k, the operand's number), b2 (bits 7..6: lst prints the
    insert/extract width before an operand whose b2 has them, when the
    opcode's b14_7_1 is odd), b3 (operand 1's is the class, +7). }
  instr_attr_opnd_t = packed record
    form: 0..255;                       { +4k }
    num: 0..255;                        { +4k+1 }
    b2: 0..255;                         { +4k+2 }
    b3: 0..255;                         { +4k+3 }
  end;
  instr_attr_view_ptr_t = ^instr_attr_view_t;
  instr_attr_view_t = record
    w0: 0..65535;                       { +0 }
    w2: 0..65535;                       { +2 }
    opnds: array [1..4] of instr_attr_opnd_t;    { +4 }
  end;

  { A code cell's first longword (cell_hdr_t) with its +3 as lst reads
    it by the cell's kind: modify (bits 7..6) am$t of a load or store
    and the squash mode of a branch (lst's ".SN", ".ST", ".SF", ".SA"),
    lsq (bits 5..4) lsq$t of a load or store; width the whole byte (an
    insert's or extract's field width, a load_pair's offset as
    signed). }
  cell_head_ptr_t = ^cell_head_t;
  cell_head_t = packed record
    flags: 0..255;                      { +0 }
    opc: 0..255;                        { +1 }
    b2: 0..255;                         { +2: bits 3..0 lst's cycle
                                          column, bit 6 the next cell
                                          continues this one }
    case integer of
      1: (modify: 0..3;                 { +3 .7..6 }
          lsq: 0..3;                    { .5..4 }
          b3_3_0: 0..15);
      2: (width: 0..255);
      3: (offset: -128..127);
  end;

  { An opcode's assembly (the section instruction_assembly, 44 bytes by
    opcode, for opc$undefined..opc$adj_move; asm.pas includes its
    initializer, instr_assembly.init).  w0 and w4 the encoding, +8 bit
    5 (squash) the branch takes a squash suffix, bit 4 (no_hex) lst
    shows no instruction word, prasm_len the length of prasm_name; +9
    name_len the length of name, half (bits 3..1) the operands that
    name a single's half (lst's ".H"); prasm_format (+10) how lst
    lays the instruction out in -PRASM form; prasm_name (+11) its
    operator there, name (+19) its mnemonic; opnd (+36) a word for
    each operand (bits 2..1 lst's display format: 0 decimal, 2
    hexadecimal). }
  instr_asm_ptr_t = ^instr_asm_t;
  instr_asm_t = packed record
    w0: integer32;                      { +0 }
    w4: integer32;                      { +4 }
    b8_7, b8_6: boolean;                { +8 }
    squash: boolean;                    { .5 }
    no_hex: boolean;                    { .4 }
    prasm_len: 0..15;                   { .3..0 }
    name_len: 0..15;                    { +9 .7..4 }
    half: 0..7;                         { .3..1 }
    b9_0: boolean;
    text: packed array [10..35] of char;    { +10: prasm_format
                                          (text[10]), prasm_name
                                          (text[11..18]), name
                                          (text[19..34]); dpc puts a
                                          character array of a packed
                                          record on an even offset }
    opnd: array [1..4] of 0..65535;     { +36 }
  end;
  instr_asms_t = array [0..211] of instr_asm_t;

  { A literal (lst_$prtlit, lst_$display_literal): kind (+4) 0..21: 0
    integer, 1 short, 2 byte, 3 long, 4..7 their unsigned forms, 8..10
    word, byte and long booleans, 11 char, 12 single (held as a
    double), 13 double, 14 complex, 15 double complex, 16 namelist
    descriptor (p0^'s +18), 18 varying string (w12 its length, chars
    from +14), 19 string (len its length, chars from +12), 20
    read-only data, 21 a def_const; 17 unknown. }
  lit_ptr_t = ^lit_t;
  lit_t = record
    p0: univ_ptr;                       { +0 }
    kind: integer;                      { +4 }
    len: integer;                       { +6 }
    case integer of
      1: (value: integer32;             { +8 }
          l12: integer32;               { +12 }
          l16: integer32;               { +16 }
          l20: integer32);              { +20 }
      2: (d: double;                    { +8 }
          d16: double);                 { +16 }
      3: (r: real;                      { +8 }
          r12: real);                   { +12 }
      4: (w8: integer;                  { +8 }
          w10: integer;                 { +10 }
          w12: integer;                 { +12 }
          chars14: array [1..256] of char);    { +14 }
      5: (b8, b9, b10, b11: char;       { +8 }
          chars: array [1..256] of char);      { +12 }
  end;

  { A literal pool entry (lst_$display_literal, bin): lit (+4) the
    literal, size (+16), addr (+20) its address in the pool. }
  lpe_ptr_t = ^lpe_t;
  lpe_t = record
    l0: integer32;                      { +0 }
    lit: lit_ptr_t;                     { +4 }
    l8: integer32;                      { +8 }
    l12: integer32;                     { +12 }
    size: integer32;                    { +16 }
    addr: integer32;                    { +20 }
  end;

  { The listing's line (prtsub.ins.pas's prtsub_$line_t, which is
    opened after this insert). }
  lst_line_t = varying [256] of char;

{ batch C (tr_utils, mmt, mmt_utils, trans, com, iv, oli): }
type
  { An operand's first longword as four bytes: rrp (+1) is the low byte
    of its rrp$set_t (opnd_hdr_t's booleans), stored and masked whole
    by the optimizer (tr_utils: 8 write, 16 read, 12 write or modify). }
  opnd_bytes_ptr_t = ^opnd_bytes_t;
  opnd_bytes_t = packed record
    num: 0..255;                        { +0 }
    rrp: 0..255;                        { +1 }
    b2: 0..255;                         { +2 }
    b3: 0..255;                         { +3 }
  end;

  { An address comparison (mmt_utils_$addr_compare, or what oli sets with
    mmt_utils_$set_address_comparison_function): how the memory
    references of two loads or stores relate (1 the same, 2 and 4/5
    overlapping, 3 disjoint, 0 not known), disp the second's
    displacement from the first; report true when mmt_utils asks only to
    be told (inform_about_relationships). }
  mmt_compare_t = ^function(
      a: instr_ptr_t;
      b: instr_ptr_t;
      report: boolean;
      out disp: integer32): integer; options(val_param);
{ end batch C }

{ The named sections of the opcode and operand tables (DSEE
  initializers: instr_attributes.init in lir.pas, instr_mnemonic.init and
  instr_mnemonic_length.init in lst.pas, instr_assembly.init in asm.pas,
  of_string*.init in lir.pas, operand_string*.init in dmp.pas,
  operand_forms_mask.init and the amse_ tables in tm_utils.pas).  Each
  unit that declares a section shares it. }
var (instruction_attributes)
  instruction_attributes: instr_attrs_t;
var (instruction_mnemonic)
  instruction_mnemonic: array [0..383] of packed array [1..12] of char;
var (instruction_mnemonic_length)
  instruction_mnemonic_length: array [0..383] of integer;
var (operand_forms_mask)
  operand_forms_mask: array [0..43] of char;
var (of_string_length)
  of_string_length: array [0..43] of integer;
var (of_string)
  of_string: array [0..43] of packed array [1..34] of char;
var (operand_string_length)
  operand_string_length: array [0..31] of integer;
var (operand_string)
  operand_string: array [0..31] of packed array [1..25] of char;

{ batch B: the opcodes' assembly (0x2B9CCC, 212 entries of 44 bytes;
  lst and asm read it, asm includes instr_assembly.init). }
var (instruction_assembly)
  instruction_assembly: instr_asms_t;

var
  { at_backend.pas's data (A5 0x485830), reached absolutely. }
  at_backend_4fc: extern univ_ptr;      { +0x4FC (get_calling_conventions'
                                          record; dmp, lir_utils, ra,
                                          rewrite, utils) }
  at_backend_switches: extern at_switches_t;   { +0x500 (21 units) }
  at_backend_phase: extern integer;     { +0x502: the phase running,
                                          0..19 (19 none) }

  { lir_main.pas's data (A5 0x48B3AC): the cells units other than lir,
    lir_main and lir_utils reach (theirs are lir.pvt.pas's). }
  lir_main_b40: extern integer32;       { +0xB40 (address taken: lir, lst) }
  lir_main_c40: extern integer32;       { +0xC40 }
  lir_main_c44: extern univ_ptr;        { +0xC44 }
  lir_main_c48: extern integer32;       { +0xC48 }
  lir_main_c4c: extern integer32;       { +0xC4C }
  lir_main_c50: extern integer32;       { +0xC50 }
  lir_main_c54: extern integer32;       { +0xC54 }
  lir_main_c58: extern univ_ptr;        { +0xC58 }
  lir_main_c5c: extern integer32;       { +0xC5C }
  lir_main_c60: extern univ_ptr;        { +0xC60 }
  lir_main_c64: extern univ_ptr;        { +0xC64 }
  lir_main_c68: extern integer32;       { +0xC68 }
  lir_main_c6c: extern integer32;       { +0xC6C }
  lir_main_c70: extern univ_ptr;        { +0xC70 }
  lir_main_heap: extern univ_ptr;       { +0xC74: the routine's heap
                                          (lir's instructions), a
                                          ^mrh_$heap_t: dfa, sem_utils
                                          and others open mrh.ins.pas
                                          after this insert }
  lir_main_c78: extern univ_ptr;        { +0xC78: the lifetime bit
                                          vectors' space (bv; batch A:
                                          was integer32) }
  lir_main_c7c: extern univ_ptr;        { +0xC7C: the availability bit
                                          vectors' space (bv; batch A:
                                          was integer32) }
  lir_main_c80: extern integer32;       { +0xC80: the bits each vector
                                          has room for (bv) }
  lir_main_c84: extern integer;         { +0xC84: the bit vectors each
                                          block has, 0, 4 or 7 (bv; xtp:
                                          nonzero skips the global
                                          walk) }
  lir_main_c86: extern integer;         { +0xC86: where the segment
                                          lists are kept: 0 by block, 1
                                          by live range (utils; xtp sets
                                          it to 1) }
  lir_main_c88: extern boolean;         { +0xC88 }
  lir_main_c89: extern boolean;         { +0xC89 }
  lir_main_c8c: extern boolean;         { +0xC8C }
  lir_main_c8d: extern boolean;         { +0xC8D: the live ranges'
                                          hints valid (utils) }
  lir_main_c8e: extern boolean;         { +0xC8E: definitions may be
                                          located (utils) }
  lir_main_da4: extern boolean;         { +0xDA4: set by
                                          at_backend_$begin_compilation
                                          from the options; dfa and xtp
                                          skip the global data flow when
                                          set }

  { lir.pas's data (A5 0x487180), reached by units other than
    lir_main, lir_utils and ra_utils. }
  lir_3e60: extern integer32;           { +0x3E60 (ISC) }
  lir_3f60: extern integer32;           { +0x3F60 (address taken:
                                          call_conv, rewrite) }
  lir_3f78: extern integer32;           { +0x3F78 (call_conv) }
  lir_3f90: extern integer32;           { +0x3F90 (address taken) }
  lir_3f94: extern integer32;           { +0x3F94 (com) }
  lir_3f98: extern integer32;           { +0x3F98 (com) }
  lir_3f9c: extern integer32;           { +0x3F9C (com) }
  lir_4090: extern integer32;           { +0x4090 (address taken) }
  lir_4204: extern integer32;           { +0x4204 (ra) }
  lir_4208: extern integer32;           { +0x4208 (ra) }
  lir_420c: extern integer32;           { +0x420C (address taken: ra) }
  lir_422a: extern boolean;             { +0x422A (ra_utils) }

  { Other units' cells reached absolutely. }
  asm_658: extern integer32;            { asm +0x658 (lir, ra_utils) }
  dmp_3c2: extern integer;              { dmp +0x3C2 (at_backend; ra
                                          reads its low byte) }
  lst_13c: extern univ_ptr;             { lst +0x13C (at_backend, bin,
                                          dmp) }
  lst_140: extern integer;              { lst +0x140 (sym) }
  ra_654: extern integer32;             { ra +0x654 (lir_main) }
  ra_658: extern integer32;             { ra +0x658 (lir_main) }
  sched_3158: extern integer32;         { sched +0x3158 (lir_main) }

  { batch B: cells lst reaches. }
  lir_main_ac0: extern array [0..31] of univ_ptr;    { lir_main +0xAC0
                                          (0x48BE6C): by register
                                          number, what a register
                                          operand's link is when it
                                          names the physical register
                                          (lst_$display_operand) }


{ asm.pas (cc.a88k). }

{ ASM_$END_ROUTINE - 0x21DCC4, 0x2 bytes (no A5). }
procedure asm_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ ASM_$PROCESS_ROUTINE - 0x21F6D4, 0x19A2 bytes.  Frame 8:al. }
procedure asm_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ ASM_$BEGIN_COMPILATION - 0x221848, 0xA8 bytes. }
procedure asm_$begin_compilation; extern;

{ ASM_$END_COMPILATION - 0x22195C, 0xC4 bytes. }
procedure asm_$end_compilation; extern;

{ at_backend.pas (cc.a88k). }

{ INSTR_BUG_CHECK - bug_check's message with the instruction's source
  line (its +32 word, or the word at +4 of what +32 points to when its
  +0 bit 1 is set; mapped through lst_13c's table, 99999 without it;
  0 for no instruction) as the first argument.  0x221A78, 0xA0 bytes;
  called from df_utils, life, lir_utils, sched, sched_utils, utils:
  each argument by address (instr, the record, compared with nil),
  the rest passed on as they are. }
procedure instr_bug_check(
    in control_string: univ bug_check_$string_t;
    in instr: univ instr_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9:
       univ bug_check_$arg_t); options(variable); extern;

{ PHASE_BUG_CHECK - bug_check's message with the running phase's name
  (at_backend's table, by at_backend_phase) as the first argument.
  0x221B18, 0x66 bytes; called from sanity. }
procedure phase_bug_check(
    in control_string: univ bug_check_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9:
       univ bug_check_$arg_t); options(variable); extern;

{ PHASE_INSTR_BUG_CHECK - instr_bug_check's, the phase's name first.
  0x221B7E, 0xAC bytes; called from sanity. }
procedure phase_instr_bug_check(
    in control_string: univ bug_check_$string_t;
    in instr: univ instr_t;
    in a1, a2, a3, a4, a5, a6, a7, a8:
       univ bug_check_$arg_t); options(variable); extern;

{ bin.pas (cc.a88k). }

{ BIN_$BEGIN_COMPILATION - 0x222B3C, 0x6A bytes. }
procedure bin_$begin_compilation; extern;

{ BIN_$END_COMPILATION - 0x222BD8, 0x2 bytes (no A5). }
procedure bin_$end_compilation; extern;

{ BIN_$UNWIND_BITS - a routine's unwind facts (the return register,
  whether its frame is pushed, its frame register above 23, an ECB).
  0x223728, 0x5E bytes; called from lst.  Frame 8:a; 12:a; 16:a; 20:al;
  24:al (the results by address; narrowed by translator PB). }
procedure bin_$unwind_bits(
    info: univ_ptr;
    out frame_reg: integer32;
    out pushed: boolean;
    out big_reg: boolean;
    out ecb: boolean); extern;

{ bv.pas (cc.a88k).  batch A: the headings narrowed from bv.pas's
  bodies (n a vector's bits, a non-negative longword; v, src, dst bit
  vectors; lr the live range whose complex id is the bit); bv_$subtract
  and bv_$make_live_range_complex are procedures (their callers'
  reads of D0/A0 were the registers' other uses). }

{ BV_$TEST - 0x224D0E, 0x32 bytes; called from fg_utils lir_utils mmt
  mmt_utils ra ra_utils trans. }
function bv_$test(
    v: bv_ptr_t;
    lr: lr_ptr_t): boolean; options(val_param); extern;

{ BV_$TEST_AND_SET - 0x224D40, 0x46 bytes; called from df_utils. }
function bv_$test_and_set(
    v: bv_ptr_t;
    lr: lr_ptr_t): boolean; options(val_param); extern;

{ BV_$TEST_AND_CLEAR - 0x224D86, 0x48 bytes; called from mmt. }
function bv_$test_and_clear(
    v: bv_ptr_t;
    lr: lr_ptr_t): boolean; options(val_param); extern;

{ BV_$SET - 0x224DCE, 0x38 bytes; called from dbg_life df_utils fg_utils
  lir_utils mmt mmt_utils ra ra_utils tr_utils trans. }
procedure bv_$set(
    v: bv_ptr_t;
    lr: lr_ptr_t); options(val_param); extern;

{ BV_$SET_IF_NOT_KILLED - lr's bit set in v when it is in not_killed.
  0x224E06, 0x44 bytes; called from dbg_life mmt ra. }
procedure bv_$set_if_not_killed(
    not_killed: bv_ptr_t;
    lr: lr_ptr_t;
    v: bv_ptr_t); options(val_param); extern;

{ BV_$CLEAR - 0x224E4A, 0x3A bytes; called from dbg_life lir_utils mmt
  mmt_utils ra ra_utils trans utils. }
procedure bv_$clear(
    v: bv_ptr_t;
    lr: lr_ptr_t); options(val_param); extern;

{ BV_$COPY - dst := src.  0x224E84, 0x48 bytes; called from fg_utils mmt
  ra_utils. }
procedure bv_$copy(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t); options(val_param); extern;

{ BV_$COPY_AND_TEST - dst := src; whether it has a bit set.  0x224ECC,
  0x4C bytes; called from mmt. }
function bv_$copy_and_test(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t): boolean; options(val_param); extern;

{ BV_$EQUAL - 0x224F18, 0x5A bytes; called from mmt mmt_utils ra_utils. }
function bv_$equal(
    n: linteger;
    a: bv_ptr_t;
    b: bv_ptr_t): boolean; options(val_param); extern;

{ BV_$OR - dst := dst or src.  0x224F72, 0x50 bytes; called from fg_utils
  mmt ra_utils. }
procedure bv_$or(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t); options(val_param); extern;

{ BV_$AND - dst := dst and src.  0x224FC2, 0x50 bytes; called from
  ra_utils. }
procedure bv_$and(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t); options(val_param); extern;

{ BV_$AND_TO - dst := a and b.  0x225012, 0x54 bytes; called from
  fg_utils mmt mmt_utils ra_utils. }
procedure bv_$and_to(
    n: linteger;
    a: bv_ptr_t;
    b: bv_ptr_t;
    dst: bv_ptr_t); options(val_param); extern;

{ BV_$SUBTRACT - dst := dst and not src.  0x225066, 0x52 bytes; called
  from fg_utils mmt mmt_utils ra_utils. }
procedure bv_$subtract(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t); options(val_param); extern;

{ BV_$SET1_SUBSUMES_SET2 - whether every bit of set2 is in set1.
  0x2250B8, 0x5C bytes; called from mmt. }
function bv_$set1_subsumes_set2(
    n: linteger;
    set1: bv_ptr_t;
    set2: bv_ptr_t): boolean; options(val_param); extern;

{ BV_$FIND_NEXT_VAL - the first bit of v after bit k (up to the
  routine's last complex id), 0 for none.  0x225114, 0x88 bytes; called
  from lir_utils mmt mmt_utils. }
function bv_$find_next_val(
    rtn: rtn_ptr_t;
    v: bv_ptr_t;
    k: integer32): integer32; options(val_param); extern;

{ BV_$FIND_NEXT - the live range of the first bit of v after lr's
  (from the first for nil) whose map entry is a live range still
  complex; nil for none.  0x22519C, 0x78 bytes; called from dbg_life
  fg_utils lir_utils ra ra_utils trans. }
function bv_$find_next(
    rtn: rtn_ptr_t;
    v: bv_ptr_t;
    lr: lr_ptr_t): lr_ptr_t; options(val_param); extern;

{ BV_$MAKE_LIVE_RANGE_COMPLEX - a complex id for lr (and for the live
  range at its +16), the vectors enlarged when the bits run out.
  0x225370, 0x214 bytes; called from com df_utils iv life oli ra_utils
  trans. }
procedure bv_$make_live_range_complex(
    rtn: rtn_ptr_t;
    lr: lr_ptr_t); options(val_param); extern;

{ BV_$CREATE_DFA_BIT_VECTORS - 0x225846, 0xA8 bytes; called from
  df_utils. }
procedure bv_$create_dfa_bit_vectors(
    rtn: rtn_ptr_t); options(val_param); extern;

{ BV_$INITIALIZE_BIT_VECTORS - the lifetime vectors (nvectors 4) or the
  lifetime and availability vectors (7) for n bits, any_path saying how
  availability joins (or, else and).  0x2258EE, 0x6E bytes; called from
  dbg_life mmt post ra ra_utils. }
procedure bv_$initialize_bit_vectors(
    rtn: rtn_ptr_t;
    n: linteger;
    nvectors: integer32;
    any_path: boolean); options(val_param); extern;

{ BV_$PROPAGATE_LIFETIMES - live_in and live_out to a fixed point.
  0x22599A, 0x17E bytes; called from dbg_life mmt post ra_utils. }
procedure bv_$propagate_lifetimes(
    n: linteger;
    rtn: rtn_ptr_t); options(val_param); extern;

{ BV_$PROPAGATE_AVAILABILITY - avail_in and avail_out to a fixed point.
  0x225B18, 0x1BE bytes; called from dbg_life mmt post ra_utils. }
procedure bv_$propagate_availability(
    n: linteger;
    rtn: rtn_ptr_t;
    any_path: boolean); options(val_param); extern;

{ BV_$RELEASE_BIT_VECTORS - 0x225D1C, 0x5C bytes; called from dbg_life dfa
  hal life mmt oli post ra ra_utils trans xtp. }
procedure bv_$release_bit_vectors(
    rtn: rtn_ptr_t); options(val_param); extern;

{ BV_$RELEASE_AVAILABILITY_BIT_VECTORS - 0x225D78, 0x4C bytes; called from
  post ra ra_utils. }
procedure bv_$release_availability_bit_vectors(
    rtn: rtn_ptr_t); options(val_param); extern;

{ BV_$RELEASE_LR_MAP - 0x225DC4, 0x2E bytes; called from lir. }
procedure bv_$release_lr_map(
    rtn: rtn_ptr_t); options(val_param); extern;

{ com.pas (cc.a88k). }

{ COM_$COMPUTE_CSES - 0x22BFD2, 0x58 bytes; called from iv.  Frame 8:al;
  12:l. }
procedure com_$compute_cses(
    p1: univ_ptr;
    p2: integer32); options(val_param); extern;

{ COM_$BEGIN_COMPILATION - 0x22C02A, 0x26 bytes. }
procedure com_$begin_compilation; extern;

{ COM_$END_COMPILATION - 0x22C064, 0x1C bytes. }
procedure com_$end_compilation; extern;

{ COM_$END_ROUTINE - 0x22C080, 0x2 bytes (no A5). }
procedure com_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ COM_$PROCESS_ROUTINE - 0x22C082, 0x33A bytes.  Frame 8:al. }
procedure com_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ dbg_life.pas (cc.a88k). }

{ DBG_LIFE_$PROCESS_ROUTINE - 0x22E2BC, 0x25A bytes.  Frame 8:a. }
procedure dbg_life_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ DBG_LIFE_$END_ROUTINE - 0x22E562, 0x2 bytes (no A5). }
procedure dbg_life_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ df_utils.pas (cc.a88k). }

{ DF_UTILS_$BEGIN_COMPILATION - 0x22E586, 0x2 bytes (no A5); called from
  at_backend. }
procedure df_utils_$begin_compilation; extern;

{ DF_UTILS_$INIT_FOR_ROUTINE - 0x22E588, 0x1A bytes; called from
  at_backend.  Frame 8:a. }
procedure df_utils_$init_for_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ DF_UTILS_$END_ROUTINE - 0x22E5A2, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure df_utils_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ DF_UTILS_$END_COMPILATION - 0x22E5A4, 0x2 bytes (no A5); called from
  at_backend. }
procedure df_utils_$end_compilation; extern;

{ DF_UTILS_$GLOBAL_WALK - 0x22F03A, 0x36 bytes; called from com dfa
  fg_utils fga iv mmt trans xtp.  Frame 8:al; 12:l; 16:w; 18:l. }
procedure df_utils_$global_walk(
    rtn: rtn_ptr_t;
    nlrs: integer32;
    how: integer;
    level: integer32); options(val_param); extern;

{ DF_UTILS_$GLOBAL_WALK_WITH_ASYNC_PROTECTION - 0x22F070, 0x36 bytes;
  called from fga.  Frame 8:al; 12:l; 16:w; 18:l.  batch A: both walks
  named from df_utils' bodies: nlrs the routine's complex live ranges
  (stored at its +192), how lir_main_c86's next value (1: the segment
  lists by live range), level stored and not read. }
procedure df_utils_$global_walk_with_async_protection(
    rtn: rtn_ptr_t;
    nlrs: integer32;
    how: integer;
    level: integer32); options(val_param); extern;

{ dfa.pas (cc.a88k). }

{ DFA_$BEGIN_COMPILATION - 0x22F0A8, 0x2 bytes (no A5). }
procedure dfa_$begin_compilation; extern;

{ DFA_$END_ROUTINE - 0x22F0AA, 0x2 bytes (no A5). }
procedure dfa_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ DFA_$END_COMPILATION - 0x22F0AC, 0x2 bytes (no A5). }
procedure dfa_$end_compilation; extern;

{ DFA_$PROCESS_ROUTINE - 0x22F0AE, 0xDA bytes.  Frame 8:a. }
procedure dfa_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ dmp.pas (cc.a88k). }

{ DMP_$STARTING_BASIC_BLOCK - 0x22F188, 0x5E bytes; called from ra.  Frame
  8:al. }
procedure dmp_$starting_basic_block(
    p1: univ_ptr); options(val_param); extern;

{ DMP_$NOTE_LABEL - 0x22F1FC, 0x22 bytes; called from lir.  Frame 8:pw. }
procedure dmp_$note_label(
    p1: integer); options(val_param); extern;

{ DMP_$COMPLEX_LR_BIT_VECTOR_HEADER - 0x22F374, 0x2A bytes; called from
  dbg_life mmt.  Frame 8:al.  (batch C: narrowed from mmt's calls.) }
procedure dmp_$complex_lr_bit_vector_header(
    rtn: rtn_ptr_t); options(val_param); extern;

{ batch C: a line of text dmp_$complex_lr_bit_vector prints before a
  vector (mmt passes constants and a 128-character buffer). }
type
  dmp_$text_t = array [1..256] of char;

{ DMP_$COMPLEX_LR_BIT_VECTOR - 0x22F48C, 0x12A bytes; called from dbg_life
  mmt.  Frame 8:al; 12:a; 16:alp; 20:al.  (batch C: narrowed from mmt's
  calls: the text by address, its length by value, the vector.) }
procedure dmp_$complex_lr_bit_vector(
    rtn: rtn_ptr_t;
    in text: univ dmp_$text_t;
    len: integer32;
    v: bv_ptr_t); options(val_param); extern;

{ DMP_$REG_SET - 0x22F5D8, 0xE4 bytes; called from ra.  Frame 8:l; 12:l. }
procedure dmp_$reg_set(
    p1: integer32;
    p2: integer32); options(val_param); extern;

{ DMP_$ALL_BASIC_BLOCK_HEADERS - 0x2304A8, 0x40 bytes; called from ra.
  Frame 8:al. }
procedure dmp_$all_basic_block_headers(
    p1: univ_ptr); options(val_param); extern;

{ DMP_$GET_LINE_NUMBER - 0x2309C4, 0x6A bytes; called from fg_utils.
  Frame 8:a; 12:a.  Result: D0 (callers: D0l3). }
function dmp_$get_line_number(
    p1: univ_ptr;
    p2: univ_ptr): integer32; options(val_param); extern;

{ DMP_$INSTRUCTION - 0x230A2E, 0x800 bytes; called from lir.  Frame 8:al;
  110:w; 612:w. }
procedure dmp_$instruction(
    p1: univ_ptr;
    p2: integer;
    p3: integer); options(val_param); extern;

{ DMP_$THREE_CHAR_LR_NAME_FROM_LR - 0x232010, 0x114 bytes; called from ra.
  Frame 8:al; 12:a; 16:a.  Result: D0 (callers: D0l23). }
function dmp_$three_char_lr_name_from_lr(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr): integer32; options(val_param); extern;

{ DMP_$WHOLE_ROUTINE - 0x23394A, 0x718 bytes; called from at_backend com
  fg_utils ra ra_utils.  Frame 8:al; 12:b; 14:b. }
procedure dmp_$whole_routine(
    p1: univ_ptr;
    p2: boolean;
    p3: boolean); options(val_param); extern;

{ DMP_$INTERFERENCE_GRAPH_ANALYSIS - 0x2345FA, 0xC8 bytes; called from ra.
  Frame 8:a; 12:a; 16:p; 20:a; 24:b. }
procedure dmp_$interference_graph_analysis(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer32;
    p4: univ_ptr;
    p5: boolean); options(val_param); extern;

{ DMP_$MEMORY_USAGE - 0x23474A, 0x188 bytes; called from at_backend. }
procedure dmp_$memory_usage; extern;

{ fg_utils.pas (cc.a88k). }

{ FG_UTILS_$BEGIN_COMPILATION - 0x2349A2, 0x52 bytes; called from
  at_backend. }
procedure fg_utils_$begin_compilation; extern;

{ FG_UTILS_$INIT_FOR_ROUTINE - 0x234A46, 0x2E bytes; called from
  at_backend.  Frame 8:a. }
procedure fg_utils_$init_for_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ FG_UTILS_$END_ROUTINE - 0x234A74, 0x1E bytes; called from at_backend.
  Frame 8:a. }
procedure fg_utils_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ FG_UTILS_$END_COMPILATION - 0x234A92, 0x2 bytes (no A5); called from
  at_backend. }
procedure fg_utils_$end_compilation; extern;

{ FG_UTILS_$DROP_THIS_BLOCK - 0x234AB8, 0x184 bytes; called from asm.
  Frame 8:al; 12:al. }
procedure fg_utils_$drop_this_block(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ FG_UTILS_$FORWARD_THIS_BLOCK - 0x234C3C, 0x3C8 bytes; called from fga
  post.  Frame 8:l; 12:al; 16:al (batch A: from fga's call, a block
  whose one instruction is a jump, and the jump). }
procedure fg_utils_$forward_this_block(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t;
    jump: instr_ptr_t); options(val_param); extern;

{ FG_UTILS_$COMPUTE_DFS_LISTS - 0x2354E0, 0xA2 bytes; called from dfa fga.
  Frame 8:al; 12:l; 16:b. }
procedure fg_utils_$compute_dfs_lists(
    rtn: rtn_ptr_t;
    level: integer32;
    p3: boolean); options(val_param); extern;

{ FG_UTILS_$INTERVALS - 0x235676, 0x1AC bytes; called from dfa.  Frame
  8:al. }
procedure fg_utils_$intervals(
    rtn: rtn_ptr_t); options(val_param); extern;

{ FG_UTILS_$SEPARATE_LOOP_HEADER_EDGES - 0x235822, 0x8E bytes; called from
  hal oli.  Frame 8:l; 12:l; 16:bw.  Result: A0 (callers: A04).  batch
  A: from hal's calls, the block whose edges in are separated, the
  loop's head, a flag (false from guarantee_header, true from
  hal_$insert_loop_tails); the edges taken off, chained at next_pred. }
function fg_utils_$separate_loop_header_edges(
    bb: bb_ptr_t;
    head: bb_ptr_t;
    p3: boolean): fg_edge_ptr_t; options(val_param); extern;

{ FG_UTILS_$MAKE_LOOPS_UNCONDITIONAL - 0x235F04, 0x30 bytes; called from
  dfa.  Frame 8:a. }
procedure fg_utils_$make_loops_unconditional(
    rtn: rtn_ptr_t); options(val_param); extern;

{ FG_UTILS_$FORWARD_EMPTY_BLOCKS - 0x235F34, 0x238 bytes; called from hal
  xtp.  Frame 8:al.  Result: D0 (callers: D0b1). }
function fg_utils_$forward_empty_blocks(
    rtn: rtn_ptr_t): boolean; options(val_param); extern;

{ FG_UTILS_$END_SENSELESS_LOOPS - 0x23619E, 0x1BC bytes; called from hal
  xtp.  Frame 8:al.  Result: D0 (callers: D0b2). }
function fg_utils_$end_senseless_loops(
    rtn: rtn_ptr_t): boolean; options(val_param); extern;

{ FG_UTILS_$GENERATE_JOIN_BIRTHPOINT - 0x2366F8, 0x138 bytes; called from
  iv.  Frame 8:al; 12:al.  Result: read (callers: A01). }
function fg_utils_$generate_join_birthpoint(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ FG_UTILS_$INSERT_JOIN_BIRTHPOINT - 0x236874, 0xA0 bytes; called from
  utils.  Frame 8:al; 12:al.  Result: read (callers: A01). }
function fg_utils_$insert_join_birthpoint(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ FG_UTILS_$ADD_JBI - 0x236B9C, 0x4E bytes; called from iv utils.  Frame
  8:al; 12:al. }
procedure fg_utils_$add_jbi(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ FG_UTILS_$DOMINATORS - 0x236C4A, 0x4D6 bytes; called from dfa.  Frame
  8:al; 12:b; 14:l. }
procedure fg_utils_$dominators(
    rtn: rtn_ptr_t;
    p2: boolean;
    level: integer32); options(val_param); extern;

{ FG_UTILS_$DROP_OLD_JOIN_BIRTHPOINTS - 0x2372C4, 0x124 bytes; called from
  xtp.  Frame 8:al. }
procedure fg_utils_$drop_old_join_birthpoints(
    rtn: rtn_ptr_t); options(val_param); extern;

{ FG_UTILS_$RECOMPUTE_POSTNUM - 0x23743A, 0x48 bytes; called from oli.
  Frame 8:al. }
procedure fg_utils_$recompute_postnum(
    p1: univ_ptr); options(val_param); extern;

{ FG_UTILS_$RECOMPUTE_DOMINATORS_AND_DFS_LISTS - 0x237482, 0x92 bytes;
  called from hal konst oli xtp.  Frame 8:al; 12:w; 14:l. }
procedure fg_utils_$recompute_dominators_and_dfs_lists(
    rtn: rtn_ptr_t;
    p2: integer;
    level: integer32); options(val_param); extern;

{ FG_UTILS_$COMPUTE_LR_LIFETIME - 0x237660, 0xBC bytes; called from
  tr_utils.  Frame 8:al. }
procedure fg_utils_$compute_lr_lifetime(
    p1: univ_ptr); options(val_param); extern;

{ FG_UTILS_$RECOMPUTE_SSA_FORM_FOR_LR - 0x2377A0, 0x284 bytes; called from
  com tr_utils.  Frame 8:al. }
procedure fg_utils_$recompute_ssa_form_for_lr(
    p1: univ_ptr); options(val_param); extern;

{ fga.pas (cc.a88k). }

{ FGA_$BEGIN_COMPILATION - 0x237A82, 0x2 bytes (no A5). }
procedure fga_$begin_compilation; extern;

{ FGA_$END_ROUTINE - 0x237A84, 0x2 bytes (no A5). }
procedure fga_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ FGA_$END_COMPILATION - 0x237A86, 0x2 bytes (no A5). }
procedure fga_$end_compilation; extern;

{ FGA_$PROCESS_ROUTINE - 0x23817A, 0x1B8 bytes.  Frame 8:l. }
procedure fga_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ hal.pas (cc.a88k). }

{ HAL_$FIND_HAMMOCKS - 0x2387C6, 0x1C2 bytes; called from oli xtp.  Frame
  8:al. }
procedure hal_$find_hammocks(
    rtn: rtn_ptr_t); options(val_param); extern;

{ HAL_$BEGIN_COMPILATION - 0x238CD6, 0x26 bytes. }
procedure hal_$begin_compilation; extern;

{ HAL_$END_COMPILATION - 0x238D06, 0x2 bytes (no A5). }
procedure hal_$end_compilation; extern;

{ HAL_$PROCESS_ROUTINE - 0x238D08, 0x8C bytes.  Frame 8:a. }
procedure hal_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ HAL_$END_ROUTINE - 0x238D94, 0x1C bytes. }
procedure hal_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ iv.pas (cc.a88k). }

{ IV_$BEGIN_COMPILATION - 0x238DD2, 0xA0 bytes. }
procedure iv_$begin_compilation; extern;

{ IV_$END_COMPILATION - 0x238EE0, 0x2 bytes (no A5). }
procedure iv_$end_compilation; extern;

{ IV_$END_ROUTINE - 0x238EE2, 0x5A bytes. }
procedure iv_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ IV_$PROCESS_ROUTINE - 0x23FF80, 0x1D2 bytes.  Frame 8:al. }
procedure iv_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ jbr.pas (cc.a88k). }

{ JBR_$BEGIN_COMPILATION - 0x240164, 0x2 bytes (no A5). }
procedure jbr_$begin_compilation; extern;

{ JBR_$END_COMPILATION - 0x240166, 0x2 bytes (no A5). }
procedure jbr_$end_compilation; extern;

{ JBR_$PROCESS_ROUTINE - 0x240168, 0x2 bytes (no A5). }
procedure jbr_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ JBR_$END_ROUTINE - 0x24016A, 0x2 bytes (no A5). }
procedure jbr_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ konst.pas (cc.a88k). }

{ KONST_$BEGIN_COMPILATION - 0x24018E, 0x2 bytes (no A5). }
procedure konst_$begin_compilation; extern;

{ KONST_$END_COMPILATION - 0x240190, 0x2 bytes (no A5). }
procedure konst_$end_compilation; extern;

{ KONST_$PROCESS_ROUTINE - 0x241B6C, 0x5A bytes.  Frame 8:a. }
procedure konst_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ KONST_$END_ROUTINE - 0x241BC6, 0x1E bytes. }
procedure konst_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ life.pas (cc.a88k). }

{ LIFE_$BEGIN_COMPILATION - 0x241C06, 0x2 bytes (no A5). }
procedure life_$begin_compilation; extern;

{ LIFE_$END_COMPILATION - 0x241C08, 0x2 bytes (no A5). }
procedure life_$end_compilation; extern;

{ LIFE_$PROCESS_ROUTINE - 0x24260A, 0x212 bytes; called from com xtp.
  Frame 8:l. }
procedure life_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ LIFE_$END_ROUTINE - 0x24281C, 0x2 bytes (no A5). }
procedure life_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ lir.pas (cc.a88k). }

{ LIR_$BEGIN_COMPILATION - 0x242994, 0x344 bytes; called from at_backend.
  }
procedure lir_$begin_compilation; extern;

{ LIR_$COMPLETE_TOP_LEVEL_NODE_INHERITED_ATTRS - 0x242E7E, 0x58 bytes;
  called from lir_main.  Frame 8:al. }
procedure lir_$complete_top_level_node_inherited_attrs(
    p1: univ_ptr); options(val_param); extern;

{ LIR_$GET_NEW_INSTRUCTION_NO_EXCEPTIONS - 0x2433C2, 0x40 bytes; called
  from lir_main lir_utils ra_utils.  Frame 8:l; 12:w; 14:al; 18:l; 22:al.
  Result: read (callers: A015). }
function lir_$get_new_instruction_no_exceptions(
    p1: integer32;
    p2: integer;
    p3: univ_ptr;
    p4: integer32;
    p5: univ_ptr): univ_ptr; options(val_param); extern;

{ LIR_$ADD_FLOW_GRAPH_EDGE - 0x243402, 0x68 bytes; called from asm
  fg_utils fga hal lir_main oli post utils.  Frame 8:al; 12:al.  Result:
  read (callers: A013 D0l1). }
function lir_$add_flow_graph_edge(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ LIR_$NEW_BASIC_BLOCK - 0x2434DE, 0x7E bytes; called from asm fg_utils
  hal oli post.  Result: A0 (callers: A013). }
function lir_$new_basic_block: univ_ptr; extern;

{ LIR_$NEW_LABEL - 0x243784, 0x28 bytes; called from isc_user_routines
  lir_main sym.  Result: read (callers: A05). }
function lir_$new_label: univ_ptr; extern;

{ LIR_$LABEL - 0x2437AC, 0xF4 bytes; called from isc_to_lir lir_main.
  Frame 8:al. }
procedure lir_$label(
    p1: univ_ptr); options(val_param); extern;

{ LIR_$FREE_LIFETIME_SEGMENT - 0x2438CE, 0x7E bytes; called from fg_utils
  mmt_utils utils.  Frame 8:al. }
procedure lir_$free_lifetime_segment(
    p1: univ_ptr); options(val_param); extern;

{ LIR_$NEW_LIFETIME_SEGMENT - 0x2439B8, 0x66 bytes; called from fg_utils
  oli utils.  Frame 8:al.  Result: A0 (callers: A05). }
function lir_$new_lifetime_segment(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ LIR_$NEW_LIVE_RANGE - 0x243AB0, 0x1C bytes; called from com life
  lir_main lir_utils mmt mmt_utils oli ra_utils tr_utils.  Result: read
  (callers: A018). }
function lir_$new_live_range: univ_ptr; extern;

{ LIR_$NEW_LIVE_RANGE_IP_REG - 0x243ACC, 0x20 bytes; called from com
  isc_user_routines life lir_utils oli ra_utils tr_utils.  No
  parameters (the body reads none: lir_$alloc_live_range, rrp 16#8000;
  the frame read off a caller was another call's arguments,
  docs/rev889-patterns.md 63).  Result: read (callers: A015). }
function lir_$new_live_range_ip_reg: univ_ptr; extern;

{ LIR_$NEW_LIVE_RANGE_FP_REG - 0x243AEC, 0x20 bytes; called from com
  isc_cse_handling isc_to_lir isc_user_routines life lir_utils oli
  ra_utils tr_utils.  Result: read (callers: A014). }
function lir_$new_live_range_fp_reg: univ_ptr; extern;

{ LIR_$NEW_LIVE_RANGE_FP_REG_PAIR - 0x243B0C, 0x40 bytes; called from com
  isc_cse_handling isc_to_lir isc_user_routines life lir_utils oli
  ra_utils tr_utils.  Result: A0 (callers: A023). }
function lir_$new_live_range_fp_reg_pair: univ_ptr; extern;

{ LIR_$NEW_LIVE_RANGE_FOR_KIND - 0x243B4C, 0x42 bytes; called from com iv
  oli tr_utils.  Frame 8:w.  Result: read (callers: A026 D0l1). }
function lir_$new_live_range_for_kind(
    p1: integer): univ_ptr; options(val_param); extern;

{ LIR_$NEW_INSTRUCTION - 0x243B8E, 0x5A bytes; called from asm fg_utils
  hal oli post.  Frame 8:w.  Result: D0 (callers: A011). }
function lir_$new_instruction(
    p1: integer): univ_ptr; options(val_param); extern;

{ LIR_$BREAK_BASIC_BLOCK - 0x243BE8, 0x26 bytes; called from isc_to_lir. }
procedure lir_$break_basic_block; extern;

{ LIR_$OPTIMIZER_NEW_N_OPR_INSTR - 0x243DD8, 0x2C bytes; called from com
  mmt mmt_utils ra_utils.  Frame 8:al; 12:lw; 14:b; 16:al.  Result: read
  (callers: A05).  As lir_$optimizer_new_instruction with n operands
  (mmt_utils' reading of its call: opc a word, n a longword). }
function lir_$optimizer_new_n_opr_instr(
    anchor: instr_ptr_t;
    opc: integer;
    after: boolean;
    n: integer32): instr_ptr_t; options(val_param); extern;

{ LIR_$OPTIMIZER_NEW_INSTRUCTION - a new instruction of opcode opc, of
  the opcode's default size (lir_$opt_new_instruction with true, nil),
  put after anchor (after) or before it in anchor's block.  0x243E04,
  0x2A bytes; called from com fg_utils iv lir_utils oli tr_utils xtp:
  anchor a pointer, opc a word, after a byte; A0. }
function lir_$optimizer_new_instruction(
    anchor: instr_ptr_t;
    opc: integer;
    after: boolean): instr_ptr_t; options(val_param); extern;

{ LIR_$BUILD_OPERAND - 0x24409A, 0xF58 bytes; called from lir_main
  lir_utils.  Frame 8:al; 12:al; 16:bl; 17:b; 18:b. }
procedure lir_$build_operand(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer32;
    p4: boolean;
    p5: boolean); options(val_param); extern;

{ LIR_$COMPLETE_INSTRUCTION - 0x2457F4, 0xDCE bytes; called from lir_main.
  Frame 8:al.  Result: read (callers: D0l1). }
function lir_$complete_instruction(
    p1: univ_ptr): integer32; options(val_param); extern;

{ LIR_$DISPATCH_INSTRUCTION - 0x2467B6, 0x108 bytes; called from
  isc_to_lir.  Frame 8:l; 12:l; 16:w; 18:l. }
procedure lir_$dispatch_instruction(
    p1: integer32;
    p2: integer32;
    p3: integer;
    p4: integer32); options(val_param); extern;

{ LIR_$BRANCH_INSTRUCTION - 0x24691E, 0xA6 bytes; called from isc_to_lir
  lir_main.  Frame 8:al; 12:al; 16:w; 18:l. }
procedure lir_$branch_instruction(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer;
    p4: integer32); options(val_param); extern;

{ LIR_$OPERATE_AND_BRANCH_INSTRUCTION - 0x2469F4, 0xCE bytes; called from
  isc_to_lir.  Frame 8:l; 12:w; 14:l; 18:l; 22:l; 26:l. }
procedure lir_$operate_and_branch_instruction(
    p1: integer32;
    p2: integer;
    p3: integer32;
    p4: integer32;
    p5: integer32;
    p6: integer32); options(val_param); extern;

{ LIR_$USE_TRAP_FOR_EXCEPTION_RAISE - 0x246BC6, 0x62 bytes; called from
  isc_pass_1_main.  Frame 8:l; 12:al.  Result: D0 (callers: D0b1). }
function lir_$use_trap_for_exception_raise(
    p1: integer32;
    p2: univ_ptr): boolean; options(val_param); extern;

{ LIR_$SIMPLE_INSTRUCTION - 0x246D90, 0x1EE bytes; called from isc_to_lir
  lir_main.  Frame 8:al; 12:w; 14:l; 18:al; 22:al; 26:al; 30:l. }
procedure lir_$simple_instruction(
    p1: univ_ptr;
    p2: integer;
    p3: integer32;
    p4: univ_ptr;
    p5: univ_ptr;
    p6: univ_ptr;
    p7: integer32); options(val_param); extern;

{ LIR_$FIELD_INSTRUCTION - 0x246FAE, 0xDC bytes; called from isc_to_lir.
  Frame 8:l; 12:w; 14:l; 18:lp; 22:l; 26:l; 30:l. }
procedure lir_$field_instruction(
    p1: integer32;
    p2: integer;
    p3: integer32;
    p4: integer32;
    p5: integer32;
    p6: integer32;
    p7: integer32); options(val_param); extern;

{ LIR_$LOAD_INSTRUCTION - 0x2470EC, 0x274 bytes; called from isc_to_lir
  lir_main.  Frame 8:al; 12:w; 14:al; 18:al; 22:al; 26:al; 30:l; 34:l;
  38:l; 42:al. }
procedure lir_$load_instruction(
    p1: univ_ptr;
    p2: integer;
    p3: univ_ptr;
    p4: univ_ptr;
    p5: univ_ptr;
    p6: univ_ptr;
    p7: integer32;
    p8: integer32;
    p9: integer32;
    p10: univ_ptr); options(val_param); extern;

{ LIR_$MFPR_INSTRUCTION - 0x2473D8, 0xC8 bytes; called from isc_to_lir.
  Frame 8:l; 12:w; 14:l; 18:l; 22:l; 26:l; 30:l. }
procedure lir_$mfpr_instruction(
    p1: integer32;
    p2: integer;
    p3: integer32;
    p4: integer32;
    p5: integer32;
    p6: integer32;
    p7: integer32); options(val_param); extern;

{ LIR_$COMMON_LHS_RHS_TOKEN - 0x2474CE, 0xA0 bytes; called from
  isc_to_lir.  Frame 8:l. }
procedure lir_$common_lhs_rhs_token(
    p1: integer32); options(val_param); extern;

{ LIR_$DISJOINT_LHS_AND_RHS_TOKENS - 0x2475B2, 0x124 bytes; called from
  isc_to_lir.  Frame 8:l; 12:l; 16:l. }
procedure lir_$disjoint_lhs_and_rhs_tokens(
    p1: integer32;
    p2: integer32;
    p3: integer32); options(val_param); extern;

{ LIR_$STORE_INSTRUCTION - 0x24771E, 0x1D0 bytes; called from isc_to_lir
  lir_main.  Frame 8:l; 12:w; 14:l; 18:al; 22:al; 26:al; 30:l; 34:l; 38:l;
  42:al. }
procedure lir_$store_instruction(
    p1: integer32;
    p2: integer;
    p3: integer32;
    p4: univ_ptr;
    p5: univ_ptr;
    p6: univ_ptr;
    p7: integer32;
    p8: integer32;
    p9: integer32;
    p10: univ_ptr); options(val_param); extern;

{ LIR_$MTPR_INSTRUCTION - 0x247968, 0xC8 bytes; called from isc_to_lir.
  Frame 8:l; 12:w; 14:l; 18:l; 22:l; 26:l; 30:l. }
procedure lir_$mtpr_instruction(
    p1: integer32;
    p2: integer;
    p3: integer32;
    p4: integer32;
    p5: integer32;
    p6: integer32;
    p7: integer32); options(val_param); extern;

{ LIR_$BEGIN_FORTRAN_IO_SEQUENCE - 0x247A5E, 0xBA bytes; called from
  isc_to_lir.  Frame 8:al. }
procedure lir_$begin_fortran_io_sequence(
    p1: univ_ptr); options(val_param); extern;

{ LIR_$BEGIN_CALL_OR_SVC - 0x247B80, 0x5C bytes; called from isc_to_lir.
  Frame 8:w; 10:l; 14:l.  Result: D0 (callers: A01). }
function lir_$begin_call_or_svc(
    p1: integer;
    p2: integer32;
    p3: integer32): univ_ptr; options(val_param); extern;

{ LIR_$EMIT_CALL_OR_SVC - 0x247DFC, 0x42C bytes; called from isc_to_lir.
  Frame 8:al; 12:al; 16:al; 20:l; 24:al; 28:l. }
procedure lir_$emit_call_or_svc(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr;
    p4: integer32;
    p5: univ_ptr;
    p6: integer32); options(val_param); extern;

{ LIR_$END_CALL_OR_SVC - 0x2482A4, 0x2A bytes; called from isc_to_lir.
  Frame 8:l; 12:al. }
procedure lir_$end_call_or_svc(
    p1: integer32;
    p2: univ_ptr); options(val_param); extern;

{ LIR_$REINITIALIZE - 0x2482CE, 0x6DC bytes; called from lir_main.  Frame
  8:al. }
procedure lir_$reinitialize(
    p1: univ_ptr); options(val_param); extern;

{ LIR_$END_ROUTINE - 0x2489AA, 0xB6 bytes; called from at_backend. }
procedure lir_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ lir_main.pas (cc.a88k). }

{ LIR_MAIN_$ADD_LIVE_RANGE - 0x249020, 0x66 bytes; called from lir.  Frame
  8:al; 12:al.  Result: read (callers: A08). }
function lir_main_$add_live_range(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ LIR_MAIN_$ADD_IP_REG_PHYSICAL_LR - 0x249086, 0x80 bytes; called from
  lir.  Frame 8:al; 12:l.  Result: A0 (callers: A01). }
function lir_main_$add_ip_reg_physical_lr(
    p1: univ_ptr;
    p2: integer32): univ_ptr; options(val_param); extern;

{ LIR_MAIN_$REINIT_PHYSICAL_REGS - 0x249106, 0x182 bytes; called from lir.
  Frame 8:l; 12:al; 16:al. }
procedure lir_main_$reinit_physical_regs(
    p1: integer32;
    p2: univ_ptr;
    p3: univ_ptr); options(val_param); extern;

{ LIR_MAIN_$BEGIN_ROUTINE - 0x249288, 0x30A bytes; called from at_backend.
  Frame 8:al. }
procedure lir_main_$begin_routine(
    p1: univ_ptr); options(val_param); extern;

{ LIR_MAIN_$ENTRY - 0x249610, 0xAC4 bytes; called from isc_to_lir.  Frame
  8:al; 102:?. }
procedure lir_main_$entry(
    p1: univ_ptr;
    p2: integer32); options(val_param); extern;

{ LIR_MAIN_$HANDLER_REENTRY - 0x24A124, 0xBC bytes; called from
  isc_to_lir.  Frame 8:al. }
procedure lir_main_$handler_reentry(
    p1: univ_ptr); options(val_param); extern;

{ LIR_MAIN_$BUILD_INITIAL_EPILOG - 0x24A746, 0x74C bytes; called from
  at_backend.  Frame 8:al. }
procedure lir_main_$build_initial_epilog(
    p1: univ_ptr); options(val_param); extern;

{ LIR_MAIN_$SAVE_AND_RESTORE_CODE - 0x24B618, 0xA20 bytes; called from ra.
  Frame 8:al. }
procedure lir_main_$save_and_restore_code(
    p1: univ_ptr); options(val_param); extern;

{ lir_utils.pas (cc.a88k). }

{ LIR_UTILS_$EXCISE_INST - 0x24C0FC, 0x52 bytes; called from com fg_utils
  mmt mmt_utils tr_utils utils.  Frame 8:al.  Result: read (callers:
  D0l1). }
function lir_utils_$excise_inst(
    p1: univ_ptr): integer32; options(val_param); extern;

{ LIR_UTILS_$CREATE_PREFERENCE_MOVE - 0x24C14E, 0xFC bytes; called from
  com ra_utils.  Frame 8:w; 10:al; 14:bw.  Result: read (callers: A08). }
function lir_utils_$create_preference_move(
    p1: integer;
    p2: univ_ptr;
    p3: integer): univ_ptr; options(val_param); extern;

{ LIR_UTILS_$ADD_LTS_TO_LR - 0x24C24A, 0x5E bytes; called from com iv mmt
  mmt_utils ra_utils tr_utils.  Frame 8:w; 10:al; 14:l; 18:a: a new
  segment of lr (mrh_$alloc_fixed from lir_utils' heap), first on its
  list (+36), lr's count (+56) up; its rrp the given bits and lr's
  (16#C003), +2 lr's +57, +12 bb, +48 lr; lr's rrp gets the bits; the
  segment stored through lts (tr_utils' reading). }
procedure lir_utils_$add_lts_to_lr(
    rrp: integer;
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    out lts: lts_ptr_t); options(val_param); extern;

{ LIR_UTILS_$ADD_LTS_AFTER_LTS - 0x24C2A8, 0x6A bytes; called from iv
  mmt_utils tr_utils xtp.  Frame 8:al; 12:w; 14:l.  Result: D0 (callers:
  A04). }
function lir_utils_$add_lts_after_lts(
    lts: lts_ptr_t;
    p2: integer;
    bb: bb_ptr_t): lts_ptr_t; options(val_param); extern;

{ LIR_UTILS_$TRANS_INSERT_MOVE - 0x24C312, 0x912 bytes; called from com
  sched_utils.  Frame 8:al. }
procedure lir_utils_$trans_insert_move(
    p1: univ_ptr); options(val_param); extern;

{ LIR_UTILS_$ADD_MEMORY_HOME - 0x24D0F2, 0x18C bytes; called from
  ra_utils.  Frame 8:l; 12:al; 16:bw.  Result: read (callers: D0l1). }
function lir_utils_$add_memory_home(
    p1: integer32;
    p2: univ_ptr;
    p3: integer): integer32; options(val_param); extern;

{ LIR_UTILS_$FLESH_OUT_NEW_LOAD_OR_STORE - 0x24D34C, 0x288 bytes; called
  from ra_utils.  Frame 8:al; 12:al; 16:al; 20:al; 24:l; 28:a; 32:al;
  36:l; 40:l; 44:l; 48:l; 52:l; 56:a.  Result: D0 (callers: D0l1). }
function lir_utils_$flesh_out_new_load_or_store(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr;
    p4: univ_ptr;
    p5: integer32;
    p6: univ_ptr;
    p7: univ_ptr;
    p8: integer32;
    p9: integer32;
    p10: integer32;
    p11: integer32;
    p12: integer32;
    p13: univ_ptr): integer32; options(val_param); extern;

{ LIR_UTILS_$GET_NEXT_ASYNC_EXPOSED_LR - 0x24D65A, 0xF4 bytes; called from
  df_utils mmt.  Frame 8:l; 12:al; 16:a.  Result: D0 (callers: D0l3). }
function lir_utils_$get_next_async_exposed_lr(
    p1: integer32;
    p2: univ_ptr;
    p3: univ_ptr): integer32; options(val_param); extern;

{ LIR_UTILS_$FIX_STORE_THROUGH_LRS - 0x24D808, 0xC8E bytes; called from
  fga.  Frame 8:al. }
procedure lir_utils_$fix_store_through_lrs(
    p1: univ_ptr); options(val_param); extern;

{ LIR_UTILS_$FIND_MATE_OPERAND - 0x24E5F8, 0x26 bytes; called from com
  sched_utils tr_utils trans utils.  Frame 8:al.  Result: read (callers:
  A014 D0w1). }
function lir_utils_$find_mate_operand(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ lst.pas (cc.a88k). }

{ LST_$BEGIN_COMPILATION - 0x24EA36, 0xAE bytes; called from bin. }
procedure lst_$begin_compilation; extern;

{ LST_$END_COMPILATION - 0x24EAE4, 0x2 bytes (no A5). }
procedure lst_$end_compilation; extern;

{ LST_$NEW_LINE - 0x24EAE6, 0x22 bytes; called from bin. }
procedure lst_$new_line; extern;

{ LST_$DEFINE_DATA_SECTION - 0x24EB0A, 0x84 bytes; called from bin.  Frame
  8:al. }
procedure lst_$define_data_section(
    sect: univ_ptr); options(val_param); extern;

{ LST_$SET_DATA_SECTION - 0x24EB98, 0xD4 bytes; called from bin.  Frame
  8:a. }
procedure lst_$set_data_section(
    sect: univ_ptr); options(val_param); extern;

{ LST_$PROGRAM_SECTION - 0x24EC88, 0xF8 bytes; called from bin.  Frame
  8:al. }
procedure lst_$program_section(
    sect: univ_ptr); options(val_param); extern;

{ LST_$PROCEDURE_ENTRY - 0x24ED94, 0x50A bytes; called from bin.  Frame
  8:al; 12:a; 16:al. }
procedure lst_$procedure_entry(
    info: univ_ptr;
    p2: univ_ptr;
    node: univ_ptr); options(val_param); extern;

{ LST_$PRTLIT - 0x24F8FC, 0x490 bytes; called from dmp.  Frame 8:a; 12:al.
  }
procedure lst_$prtlit(
    in out s: univ lst_line_t;
    lit: lit_ptr_t); options(val_param); extern;

{ LST_$DISPLAY_CODE_CELL - 0x250A0A, 0xD28 bytes; called from bin.  Frame
  8:al. }
procedure lst_$display_code_cell(
    cell: cell_ptr_t); options(val_param); extern;

{ LST_$DISPLAY_LITERAL - 0x251796, 0x326 bytes; called from bin.  Frame
  8:a. }
procedure lst_$display_literal(
    entry: lpe_ptr_t); options(val_param); extern;

{ LST_$DISPLAY_TABLE - 0x251C92, 0xD0 bytes; called from bin.  Frame 8:a.
  }
procedure lst_$display_table(
    cell: cell_ptr_t); options(val_param); extern;

{ mmt.pas (cc.a88k). }

{ MMT_$BEGIN_COMPILATION - 0x254F18, 0xB2 bytes. }
procedure mmt_$begin_compilation; extern;

{ MMT_$PROCESS_ROUTINE - 0x254FFC, 0x1A6 bytes.  Frame 8:al. }
procedure mmt_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ MMT_$END_ROUTINE - 0x2551D4, 0x2 bytes (no A5). }
procedure mmt_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ MMT_$END_COMPILATION - 0x2551D6, 0x2 bytes (no A5). }
procedure mmt_$end_compilation; extern;

{ mmt_utils.pas (cc.a88k). }

{ MMT_UTILS_$BEGIN_COMPILATION - 0x255210, 0x2 bytes (no A5); called from
  at_backend. }
procedure mmt_utils_$begin_compilation; extern;

{ MMT_UTILS_$INIT_FOR_ROUTINE - 0x255212, 0x3C bytes; called from
  at_backend.  Frame 8:a. }
procedure mmt_utils_$init_for_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ MMT_UTILS_$END_ROUTINE - 0x25524E, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure mmt_utils_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ MMT_UTILS_$END_COMPILATION - 0x255250, 0x2 bytes (no A5); called from
  at_backend. }
procedure mmt_utils_$end_compilation; extern;

{ MMT_UTILS_$ADDR_COMPARE - how two loads' or stores' memory references
  relate (mmt_compare_t).  0x255DA8, 0x272 bytes; called from com oli.
  Frame 8:al; 12:al; 16:bw; 18:al.  Result: D0 (callers: D01 D0w6). }
function mmt_utils_$addr_compare(
    a: instr_ptr_t;
    b: instr_ptr_t;
    report: boolean;
    out disp: integer32): integer; options(val_param); extern;

{ MMT_UTILS_$SET_ADDRESS_COMPARISON_FUNCTION - the comparison
  discover_relationships uses (nil: addr_compare) and whether it is
  told every pair of related references.  0x25601A, 0x3A bytes; called
  from oli.  Frame 8:al; 12:bw. }
procedure mmt_utils_$set_address_comparison_function(
    f: mmt_compare_t;
    inform: boolean); options(val_param); extern;

{ MMT_UTILS_$ANALYZE_ONE_BB - the memory references of bb put into
  MMT_SEQ tokens.  0x25789E, 0x3CE bytes; called from oli.  Frame 8:al;
  12:al; 16:l. }
procedure mmt_utils_$analyze_one_bb(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t;
    level: integer32); options(val_param); extern;

{ MMT_UTILS_$ANALYZE_BLOCKS - analyze_one_bb for each block of rtn.
  0x257CEC, 0x74 bytes; called from com.  Frame 8:al; 12:l. }
procedure mmt_utils_$analyze_blocks(
    rtn: rtn_ptr_t;
    level: integer32); options(val_param); extern;

{ oli.pas (cc.a88k). }

{ OLI_$BEGIN_COMPILATION - 0x25878E, 0x24 bytes. }
procedure oli_$begin_compilation; extern;

{ OLI_$END_COMPILATION - 0x2587C6, 0x2 bytes (no A5). }
procedure oli_$end_compilation; extern;

{ OLI_$PROCESS_ROUTINE - 0x26118E, 0x112 bytes.  Frame 8:al. }
procedure oli_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ OLI_$END_ROUTINE - 0x2612A0, 0x2 bytes (no A5). }
procedure oli_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ post.pas (cc.a88k). }

{ POST_$BEGIN_COMPILATION - 0x266AE8, 0x36 bytes. }
procedure post_$begin_compilation; extern;

{ POST_$PROCESS_ROUTINE - 0x266B34, 0x106 bytes.  Frame 8:l. }
procedure post_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ POST_$END_ROUTINE - 0x266C3A, 0x1C bytes. }
procedure post_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ POST_$END_COMPILATION - 0x266C56, 0x2 bytes (no A5). }
procedure post_$end_compilation; extern;

{ ra.pas (cc.a88k). }

{ RA_$BEGIN_COMPILATION - 0x266C90, 0x192 bytes. }
procedure ra_$begin_compilation; extern;

{ RA_$END_COMPILATION - 0x266E30, 0x2 bytes (no A5). }
procedure ra_$end_compilation; extern;

{ RA_$PROCESS_ROUTINE - 0x26D610, 0x6D0 bytes.  Frame 8:l. }
procedure ra_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ RA_$END_ROUTINE - 0x26DF22, 0x2 bytes (no A5). }
procedure ra_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ ra_utils.pas (cc.a88k). }

{ RA_UTILS_$BEGIN_COMPILATION - 0x26DF46, 0x2 bytes (no A5); called from
  at_backend. }
procedure ra_utils_$begin_compilation; extern;

{ RA_UTILS_$INIT_FOR_ROUTINE - 0x26DF48, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure ra_utils_$init_for_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ RA_UTILS_$END_ROUTINE - 0x26DF4A, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure ra_utils_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ RA_UTILS_$END_COMPILATION - 0x26DF4C, 0x2 bytes (no A5); called from
  at_backend. }
procedure ra_utils_$end_compilation; extern;

{ RA_UTILS_$SPILL_PASS_THROUGH_LRS - 0x26F488, 0x266 bytes; called from
  xtp.  Frame 8:al; 12:l.  Result: D0 (callers: D0b1). }
function ra_utils_$spill_pass_through_lrs(
    rtn: rtn_ptr_t;
    level: integer32): boolean; options(val_param); extern;

{ sanity.pas (cc.a88k). }

{ LIR_UTILS_$REPAIR_LTS_PROPERTIES - 0x273C46, 0x24 bytes; called from
  com.  Frame 8:al. }
procedure lir_utils_$repair_lts_properties(
    rtn: rtn_ptr_t); options(val_param); extern;

{ LIR_UTILS_$SANITY_CHECK - 0x273C6A, 0x24 bytes; called from com dfa fga
  hal iv life mmt oli sched trans xtp.  Frame 8:al. }
procedure lir_utils_$sanity_check(
    rtn: rtn_ptr_t); options(val_param); extern;

{ sched.pas (cc.a88k). }

{ SCHED_$BEGIN_COMPILATION - 0x27900A, 0x2 bytes (no A5). }
procedure sched_$begin_compilation; extern;

{ SCHED_$END_COMPILATION - 0x27900C, 0x2 bytes (no A5). }
procedure sched_$end_compilation; extern;

{ SCHED_$END_ROUTINE - 0x27900E, 0x2 bytes (no A5). }
procedure sched_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ SCHED_$PROCESS_ROUTINE - 0x279010, 0x152 bytes.  Frame 8:al. }
procedure sched_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ sched_utils.pas (cc.a88k). }

{ SCHED_UTILS_$BEGIN_COMPILATION - 0x2791B2, 0x2 bytes (no A5); called
  from at_backend. }
procedure sched_utils_$begin_compilation; extern;

{ SCHED_UTILS_$INIT_FOR_ROUTINE - 0x2791B4, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure sched_utils_$init_for_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ SCHED_UTILS_$END_ROUTINE - 0x2791B6, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure sched_utils_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ SCHED_UTILS_$END_COMPILATION - 0x2791B8, 0x2 bytes (no A5); called from
  at_backend. }
procedure sched_utils_$end_compilation; extern;

{ SCHED_UTILS_$OPERAND_DELAY - 0x279266, 0x5E8 bytes; called from
  ra_utils.  Frame 8:a; 12:al; 16:w; 17:?.  Result: D0 (callers: D0b1
  D0l2). }
function sched_utils_$operand_delay(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer;
    p4: integer32): boolean; options(val_param); extern;

{ SCHED_UTILS_$FILL_IN_OPERAND_DELAYS - 0x279A42, 0x76 bytes; called from
  oli sched.  Frame 8:al; 12:lw; 14:b. }
procedure sched_utils_$fill_in_operand_delays(
    p1: univ_ptr;
    p2: integer32;
    p3: boolean); options(val_param); extern;

{ SCHED_UTILS_$CALCULATE_PRECEDENCE - 0x279BC4, 0x118 bytes; called from
  oli.  Frame 8:l; 12:bw. }
procedure sched_utils_$calculate_precedence(
    p1: integer32;
    p2: integer); options(val_param); extern;

{ SCHED_UTILS_$INSERT_SNUGGLE_MOVES - 0x27A398, 0x7E bytes; called from
  com xtp.  Frame 8:al. }
procedure sched_utils_$insert_snuggle_moves(
    rtn: rtn_ptr_t); options(val_param); extern;

{ sem_utils.pas (cc.a88k). }

{ SEM_UTILS_$BEGIN_COMPILATION - 0x27A418, 0x2 bytes (no A5); called from
  at_backend. }
procedure sem_utils_$begin_compilation; extern;

{ SEM_UTILS_$INIT_FOR_ROUTINE - 0x27A41A, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure sem_utils_$init_for_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ SEM_UTILS_$END_ROUTINE - 0x27A41C, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure sem_utils_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ SEM_UTILS_$END_COMPILATION - 0x27A41E, 0x2 bytes (no A5); called from
  at_backend. }
procedure sem_utils_$end_compilation; extern;

{ SEM_UTILS_$NUMBER_OF_RELEVANT_LOW_ORDER_BITS - how many low-order bits of
  input operand o its instruction reads.  0x27A47E, 0x1B8 bytes; called
  from com, konst; D0. }
function sem_utils_$number_of_relevant_low_order_bits(
    o: opnd_ptr_t): integer32; options(val_param); extern;

{ sym.pas (cc.a88k). }

{ SYM_$INITIALIZE_LOCAL_SYMBOLS - 0x27AACA, 0x70 bytes; called from
  lir_main.  Frame 8:al. }
procedure sym_$initialize_local_symbols(
    p1: univ_ptr); options(val_param); extern;

{ SYM_$BACKEND_LABEL_FOR_CASE_JUMP - 0x27AB3A, 0x28 bytes; called from
  rewrite.  Frame 8:l.  Result: read (callers: A01). }
function sym_$backend_label_for_case_jump(
    p1: integer32): univ_ptr; options(val_param); extern;

{ SYM_$FULLY_QUALIFIED_ROUTINE_NAME - 0x27AB62, 0x94 bytes; called from
  at_backend bin com.  Frame 8:al; 12:al; 16:bw.  Result: D0 (callers:
  D0l1). }
function sym_$fully_qualified_routine_name(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer): integer32; options(val_param); extern;

{ SYM_$APPEND_SYMBOL_PRINT_NAME - 0x27AC22, 0x13C bytes; called from dmp
  lst.  Frame 8:a; 12:al.  Result: D0 (callers: D0b10). }
function sym_$append_symbol_print_name(
    p1: univ_ptr;
    p2: univ_ptr): boolean; options(val_param); extern;

{ SYM_$DISPLAY_SYMBOL_PRINT_NAME - 0x27AD88, 0x66 bytes; called from
  dbg_life dmp.  Frame 8:al.  Result: D0 (callers: D0b2). }
function sym_$display_symbol_print_name(
    p1: univ_ptr): boolean; options(val_param); extern;

{ SYM_$OBJECT_WITH_IMMEDIATE_DISP - 0x27AE70, 0x58 bytes; called from lir.
  Frame 8:a.  Result: A0 (callers: A01). }
function sym_$object_with_immediate_disp(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ SYM_$IS_STATIC_VAT - 0x27AEC8, 0x44 bytes; called from lir_utils.  Frame
  8:al.  Result: D0 (callers: D0b1). }
function sym_$is_static_vat(
    p1: univ_ptr): boolean; options(val_param); extern;

{ SYM_$HAS_DISPLACEMENT - 0x27AF0C, 0x32 bytes; called from lst.  Frame
  8:a.  Result: D0 (callers: D0b1). }
function sym_$has_displacement(
    p1: univ_ptr): boolean; options(val_param); extern;

{ SYM_$ALLOCATION_SIZE_IN_BYTES - 0x27B1A0, 0xF0 bytes; called from
  lir_utils utils.  Frame 8:a.  Result: D0 (callers: D0l1). }
function sym_$allocation_size_in_bytes(
    p1: univ_ptr): integer32; options(val_param); extern;

{ SYM_$ALLOCATE_STATIC_VARIABLE - 0x27B2C6, 0xE4 bytes; called from
  lir_utils rewrite.  Frame 8:a; 12:al. }
procedure sym_$allocate_static_variable(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ SYM_$REFORMAT_LITERAL - 0x27B47A, 0x1F2 bytes; called from asm.  Frame
  8:al.  Result: A0 (callers: A02). }
function sym_$reformat_literal(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ SYM_$REFORMAT_LITERAL_OPERAND - 0x27B66C, 0x54 bytes; called from iv lir
  oli.  Frame 8:al; 12:l; 16:l; 20:a.  Result: D0 (callers: D0b1 D0l4). }
function sym_$reformat_literal_operand(
    p1: univ_ptr;
    p2: integer32;
    p3: integer32;
    p4: univ_ptr): boolean; options(val_param); extern;

{ tm_utils.pas (cc.a88k). }

{ TM_UTILS_$BEGIN_COMPILATION - 0x27B714, 0x2 bytes (no A5); called from
  at_backend. }
procedure tm_utils_$begin_compilation; extern;

{ TM_UTILS_$INIT_FOR_ROUTINE - 0x27B716, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure tm_utils_$init_for_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ TM_UTILS_$END_ROUTINE - 0x27B718, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure tm_utils_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ TM_UTILS_$END_COMPILATION - 0x27B71A, 0x2 bytes (no A5); called from
  at_backend. }
procedure tm_utils_$end_compilation; extern;

{ TM_UTILS_$CAN_CONVERT_TO_IMMEDIATE_OPERAND - 0x27B71C, 0x11C bytes;
  called from tr_utils.  Frame 8:l; 12:a; 16:l.  Result: D0 (tr_utils
  reads it as a boolean). }
function tm_utils_$can_convert_to_immediate_operand(
    value: integer32;
    instr: instr_ptr_t;
    k: integer32): boolean; options(val_param); extern;

{ TM_UTILS_$CAN_CONVERT_TO_IP_REG_OPERAND - 0x27B838, 0xA2 bytes; called
  from iv tr_utils.  Frame 8:w; 10:al; 14:l.  Result: D0 (callers: D0b4).
  }
function tm_utils_$can_convert_to_ip_reg_operand(
    opc: integer;
    k: integer32;
    count: integer32): boolean; options(val_param); extern;

{ TM_UTILS_$CAN_ENCODE_AS_IMMEDIATE_OPERAND - 0x27B8F2, 0x19C bytes;
  called from konst oli sanity tr_utils.  Frame 8:l; 12:w; 14:al.  Result:
  D0 (callers: D0b11).  Whether value can be operand k (its number, a
  longword: tr_utils pushes `pea 0x1' after a pad) of an instruction of
  opcode opc (its operand forms from instruction_attributes). }
function tm_utils_$can_encode_as_immediate_operand(
    value: integer32;
    opc: integer;
    k: integer32): boolean; options(val_param); extern;

{ TM_UTILS_$CAN_POSTMODIFY_BASE_REGISTER_BY - 0x27BBA2, 0xC2 bytes; called
  from oli tr_utils.  Frame 8:l; 12:w.  Result: D0 (callers: D0b4). }
function tm_utils_$can_postmodify_base_register_by(
    p1: integer32;
    p2: integer): boolean; options(val_param); extern;

{ TM_UTILS_$CAN_PREMODIFY_BASE_REGISTER_BY - 0x27BCB6, 0xC2 bytes; called
  from oli tr_utils.  Frame 8:l; 12:w.  Result: D0 (callers: D0b2). }
function tm_utils_$can_premodify_base_register_by(
    p1: integer32;
    p2: integer): boolean; options(val_param); extern;

{ TM_UTILS_$INTERACTION_DISTANCE_BACKWARD - 0x27BDC8, 0xAA bytes; called
  from oli.  Frame 8:a.  Result: D0 (callers: D0l1). }
function tm_utils_$interaction_distance_backward(
    p1: univ_ptr): integer32; options(val_param); extern;

{ TM_UTILS_$INTERACTION_DISTANCE_FORWARD - 0x27BE72, 0x5E bytes; called
  from oli.  Frame 8:a.  Result: D0 (callers: D0l1). }
function tm_utils_$interaction_distance_forward(
    p1: univ_ptr): integer32; options(val_param); extern;

{ TM_UTILS_$MINIMUM_DISTANCE - 0x27BED0, 0x294 bytes; called from oli.
  Frame 8:a; 12:l.  Result: D0 (callers: D0l2). }
function tm_utils_$minimum_distance(
    p1: univ_ptr;
    p2: integer32): integer32; options(val_param); extern;

{ LIR_$CAN_ENCODE_AS_IMMEDIATE_OPERAND - 0x27C164, 0x26 bytes; called from
  iv trans.  Frame 8:l; 12:w; 14:al.  Result: read (callers: D0b8). }
function lir_$can_encode_as_immediate_operand(
    p1: integer32;
    p2: integer;
    p3: univ_ptr): boolean; options(val_param); extern;

{ tr_utils.pas (cc.a88k). }

{ TR_UTILS_$BEGIN_COMPILATION - 0x27C1AE, 0x24 bytes; called from
  at_backend. }
procedure tr_utils_$begin_compilation; extern;

{ TR_UTILS_$INIT_FOR_ROUTINE - 0x27C1F0, 0x2 bytes (no A5); called from
  at_backend.  Frame 8:a. }
procedure tr_utils_$init_for_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ TR_UTILS_$END_ROUTINE - 0x27C1F2, 0x1C bytes; called from at_backend.
  Frame 8:a. }
procedure tr_utils_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ TR_UTILS_$END_COMPILATION - 0x27C20E, 0x2 bytes (no A5); called from
  at_backend. }
procedure tr_utils_$end_compilation; extern;

{ TR_UTILS_$RELATIVE_INSTR_POSITION - 0x27C51E, 0xBC bytes; called from
  life.  Frame 8:al; 12:al.  Result: D0 (callers: D0l8). }
function tr_utils_$relative_instr_position(
    a: instr_ptr_t;
    b: instr_ptr_t): integer32; options(val_param); extern;

{ TR_UTILS_$MERGE_LRS - 0x27CC5E, 0x23A bytes; called from trans.  Frame
  8:al; 12:al; 16:l; 20:b; 22:b. }
procedure tr_utils_$merge_lrs(
    lr: lr_ptr_t;
    src: lr_ptr_t;
    bb: bb_ptr_t;
    with_mates: boolean;
    set_bits: boolean); options(val_param); extern;

{ TR_UTILS_$ATTEMPT_COPY_ELIMINATION - 0x27D5EE, 0xD0 bytes; called from
  com iv trans.  Frame 8:l; 12:al. }
procedure tr_utils_$attempt_copy_elimination(
    rtn: rtn_ptr_t;
    instr: instr_ptr_t); options(val_param); extern;

{ TR_UTILS_$TRY_TWIDDLING_DISP - 0x27E4F0, 0x42C bytes; called from trans.
  Frame 8:al; 12:l; 16:bl; 18:b.  Result: D0 (callers: D0b2). }
function tr_utils_$try_twiddling_disp(
    instr: instr_ptr_t;
    disp: integer32;
    no_add: boolean;
    no_copy_elim: boolean): boolean; options(val_param); extern;

{ TR_UTILS_$ATTEMPT_AUTOINCREMENT - 0x280610, 0x130 bytes; called from iv
  trans.  Frame 8:l; 12:a.  Result: D0 (callers: D0b1). }
function tr_utils_$attempt_autoincrement(
    rtn: rtn_ptr_t;
    add: instr_ptr_t): boolean; options(val_param); extern;

{ TR_UTILS_$ATTEMPT_TEST_ELIMINATION - 0x28163E, 0x2C8 bytes; called from
  com trans.  Frame 8:l; 12:al. }
procedure tr_utils_$attempt_test_elimination(
    rtn: rtn_ptr_t;
    tst: instr_ptr_t); options(val_param); extern;

{ trans.pas (cc.a88k). }

{ TRANS_$OMEGA_MOTIONS - 0x2833AE, 0x178 bytes; called from com.  Frame
  8:l. }
procedure trans_$omega_motions(
    p1: integer32); options(val_param); extern;

{ TRANS_$ALPHA_MOTIONS - 0x283D6C, 0x3DC bytes; called from com.  Frame
  8:l. }
procedure trans_$alpha_motions(
    p1: integer32); options(val_param); extern;

{ TRANS_$KILL_SILLY_EXTRACT - 0x28446C, 0xF4 bytes; called from com.
  Frame 8:a. }
procedure trans_$kill_silly_extract(
    p1: univ_ptr); options(val_param); extern;

{ TRANS_$COPY_ELIMINATION - 0x284560, 0x70 bytes; called from com.  Frame
  8:al. }
procedure trans_$copy_elimination(
    p1: univ_ptr); options(val_param); extern;

{ TRANS_$BEGIN_COMPILATION - 0x2845D0, 0x2 bytes (no A5). }
procedure trans_$begin_compilation; extern;

{ TRANS_$END_COMPILATION - 0x2845D2, 0x2 bytes (no A5). }
procedure trans_$end_compilation; extern;

{ TRANS_$END_ROUTINE - 0x2845D4, 0x2 bytes (no A5). }
procedure trans_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ TRANS_$PROCESS_ROUTINE - 0x2845D6, 0x2F0 bytes.  Frame 8:al. }
procedure trans_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ xtp.pas (cc.a88k). }

{ XTP_$BEGIN_COMPILATION - 0x287DA8, 0x2 bytes (no A5). }
procedure xtp_$begin_compilation; extern;

{ XTP_$END_COMPILATION - 0x287DAA, 0x2 bytes (no A5). }
procedure xtp_$end_compilation; extern;

{ XTP_$PROCESS_ROUTINE - 0x287DAC, 0x1D2 bytes.  Frame 8:l. }
procedure xtp_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ XTP_$END_ROUTINE - 0x287F7E, 0x2 bytes (no A5). }
procedure xtp_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ zzzzz.pas (cc.a88k). }

{ ZZZZZ_$BEGIN_COMPILATION - 0x287F98, 0x22 bytes. }
procedure zzzzz_$begin_compilation; extern;

{ ZZZZZ_$END_COMPILATION - 0x287FC8, 0x2 bytes (no A5). }
procedure zzzzz_$end_compilation; extern;

{ ZZZZZ_$PREALLOCATE_LABEL - a label instruction (opc$label, one
  operand of kind operand$symbol_definition) from zzzzz's heap, to be
  put in a block later.  0x287FCA, 0x58 bytes; called from
  isc_user_routines, lir_main, sym; A0. }
function zzzzz_$preallocate_label: instr_ptr_t; extern;

{ ZZZZZ_$PREALLOCATE_CASE_TABLE - a TABLEL code cell of n entries from
  rws_$alloc_heap, chained on the current routine's tables.  0x288022,
  0x70 bytes; called from rewrite: n by address; A0. }
function zzzzz_$preallocate_case_table(
    in n: integer32): cell_ptr_t; extern;

{ ZZZZZ_$NEW_CODE_CELL - an empty code cell of opcode opc (its size
  from code_cell_size) from zzzzz's heap.  0x288092, 0x56 bytes; called
  from asm: opc (a word) by address; A0. }
function zzzzz_$new_code_cell(
    in opc: integer): cell_ptr_t; extern;

{ ZZZZZ_$PROCESS_ROUTINE - 0x288214, 0x436 bytes.  Frame 8:a. }
procedure zzzzz_$process_routine(
    rtn: rtn_ptr_t); options(val_param); extern;