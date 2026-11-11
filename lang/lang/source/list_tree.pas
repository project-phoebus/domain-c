{ list_tree - LIST_TREE, the IL dumps of -TREE: a tree under a node
  (list_tree_$print_tree), the whole IL of a compilation, block by block
  and basic block by basic block (list_tree_$print_whole_il), a tree
  node's descriptor and register class (list_tree_$print_aux,
  list_tree_$print_rlen), and a consistency check of the use counts
  (list_tree_$sanity_check).  The lines are built in the module's line
  and written by listln (the listing) or, when no routine is given,
  diag_$writeln.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07E7C0  0x0801A0  initialise_list_tree
    0x07E7E8  0x0801C8  fresh_ln
    0x07E878  0x080258  finialise_list_tree
    0x07E890  0x080270  print_ln
    0x07E8CA  0x0802AA  break_line
    0x07E906  0x0802E6  print_char
    0x07E936  0x080316  print_2_chars
    0x07E97E  0x08035E  print_3_chars
    0x07E9DC  0x0803BC  print_string
    0x07EA38  0x080418  print_integer
    0x07EA6A  0x08044A  print_hex
    0x07EA9A  0x08047A  print_bool
    0x07EABA  0x08049A  print_comma
    0x07EAF0  0x0804D0  print_object_ptr
    0x07EB20  0x080500  prtphasebits
    0x07EE44  0x080824  print_uc_and_phase
    0x07EECC  0x0808AC  print_rlen
    0x07F024  0x080A04  list_tree_$print_rlen
    0x07F04E  0x080A2E  print_relational
    0x07F1CE  0x080BAE  print_math
    0x07F43A  0x080E1A  print_opmod_use
    0x07F76E  0x08114E  print_known_aux
    0x07F8B4  0x081294  list_tree_$print_aux
    0x07F8EE  0x0812CE  print_tree_ref
    0x07FD94  0x081774  print_tree_exp
    0x080F80  0x082960  print_variable
    0x08227E  0x083C5E  print_exception_frame
    0x082560  0x083F40  print_routine_block
    0x0833EA  0x084DCA  write_68k_register_name
    0x083462  0x084E42  print_top_node
    0x0851C4  0x086BA4  print_spine
    0x0851FA  0x086BDA  print_data_node
    0x0855B0  0x086F90  begins_inline_block
    0x085616  0x086FF6  advance_and_print
    0x085694  0x087074  print_basic_block
    0x085ABA  0x08749A  list_tree_$print_whole_il
    0x085CDA  0x0876BA  list_tree_$print_tree
    0x085DAC  0x08778C  sanity_check_countdown (in list_tree_$sanity_check)
    0x085F42  0x087922  sanity_check_bad_uc (in list_tree_$sanity_check)
    0x086072  0x087A52  sanity_check_walk (in list_tree_$sanity_check)
    0x086340  0x087D20  sanity_check_walk_spine (in list_tree_$sanity_check)
    0x0865E8  0x087FC8  list_tree_$sanity_check
    A5 0x169DFC (cc.m68k), 0x2E9E6C (cc.a88k): the module's data, 332
    bytes: +0 24 blanks (the names' padding), +0x18 the line (a
    varying string: its length 0 and 256 blanks initialized), +0x11C
    countdown (3), +0x120 the routine the lines go to, +0x124 the
    inline depth, +0x126 the statement index last printed, +0x128 the
    node last numbered, +0x12A the line's indent (all 0), +0x130 the
    size letters (9 pairs).  The IL's globals are il.pas's (il_d4,
    il_110, il_118, il_11c, il_120, il_124, il_126, il_180, il_184).

  The routines without A5 (every module-level one but the four
  list_tree_$ routines and begins_inline_block) are internal; the
  sanity_check_ routines are nested in list_tree_$sanity_check.

  The phase bits' names (prtphasebits): 0 ATM, 1 VOL, 2 VOLexpr,
  3 DEVrd, 4 DEVwt, 5 vis, 6 cse, 7 algn_arg_lst, 8 indx_lng, 9 dly,
  10 bnd, 11 wlkd, 12 sd_eff, 13 tgt_rt, 14 tgt_lft, 15 invar,
  16 VOLdecl, 17 nvr_invld, 18 isc, 19 phys, 20 proc_reg, 21 enf_paren,
  22 lcl_cse (add_node_$phase_t).  The register classes (print_rlen):
  0 null, 1 byte, 2 word, 4 long, 5 addr, 6 r4, 7 r8, 8 c8, 9 cs,
  10 vcs, 11 agg, 12 c16.  The tree operators (+36) are printed by name
  in print_tree_exp: 0 NOP, 1 ADD, 2 SUB, 3 MUL, 4 DIV, 5 DIVIDE, 6 MOD,
  7 NEG, 8 NOT, 9 AND, 10 OR, 11 BIT_TEST, 12 COMPARE, ... 89 ILLEGAL
  (the whole list in that routine's header).  The node kinds are
  numbers (docs/questions.md 78); this unit has no table of their names.

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the kind and operator
  sets, every one), 9 (sanity_check_walk_spine declared forward), 29
  (print_top_node's variables used).

  Not known from the original: every name but the routines'; the
  module's variables and the locals; the node views' field names.
}
module list_tree;

%include 'lang/lang/source/globals.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang/lang/source/list_tree.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/common/source/diag.ins.pas';

type
  { A tree node's descriptor (add_node_$desc_t) as print_known_aux reads
    it: +6 and +8 are zero-extended. }
  lt_aux_t = record
    size: integer32;                    { +0 }
    rlen: integer;                      { +4 }
    opmod1: 0..65535;                   { +6 }
    opmod2: 0..65535;                   { +8 }
    flags: packed record                { +10 }
      ovfl: boolean;                    { .7 }
      sgn: boolean;                     { .6 }
      f5, f4, f3, f2, f1, f0: boolean;
      b11: 0..255;                      { +11 }
    end;
    unused_12: integer32;               { +12 }
  end;

  { A variable's attributes (+32 of a 109 node), named by print_variable:
    0 var_$volatile .. 31 var_$withrecord. }
  lt_vattr_t = set of 0..31;

  { Where a dump's lines go (listln's heading). }
  lt_emit_t = ^procedure(
      in s: univ iosub_$line_t);

  { A word compared unsigned. }
  lt_word_t = 0..65535;

  { A byte of flags tested bit by bit. }
  lt_bits_t = set of 0..7;

  lt_ptr_t = ^lt_node_t;

  { A statement's variables (+22): each entry points at a record whose
    +0 is the variable. }
  lt_pp_t = ^lt_ptr_t;
  lt_vars_t = array [1..1000000] of lt_pp_t;
  lt_vars_ptr_t = ^lt_vars_t;

  { The variables a statement uses (+34). }
  lt_used_t = set of 0..255;
  lt_used_ptr_t = ^lt_used_t;

  { An entry of a register list (191; 12 bytes from +52). }
  lt_reg_t = record
    entity: lt_ptr_t;                   { +0 }
    reg1: 0..65535;                     { +4 }
    reg2: 0..65535;                     { +6 }
    w8: integer;                        { +8 }
    flags: set of 0..15;                { +10: 0 BIND .. 8 DESTROY }
  end;
  lt_regs_t = array [1..1000] of lt_reg_t;
  lt_regs_ptr_t = ^lt_regs_t;

  { A register's assignment (a 178 node's entries). }
  lt_ra_t = record
    node: lt_ptr_t;                     { +0 }
    size: integer;                      { +4: its letters' index }
    w6: integer;                        { +6 }
  end;

  { A basic block (il_11c's entries). }
  lt_bb_ptr_t = ^lt_bb_t;
  lt_bbs_t = array [1..100000] of lt_bb_ptr_t;
  lt_bbs_ptr_t = ^lt_bbs_t;
  lt_bb_t = record
    flags: lt_bits_t;                   { +0: 0 abnormal, 1 loop head,
                                          2 preheader, 7 cleanup }
    b1: char;                           { +1 }
    depth: integer;                     { +2: the loop depth }
    dom: lt_bb_ptr_t;                   { +4: the dominator }
    x8: integer32;                      { +8 }
    index: lt_bb_ptr_t;                 { +12: the loop index's }
    preheader: lt_bb_ptr_t;             { +16 }
    x20: integer32;                     { +20 }
    regs: lt_ptr_t;                     { +24: the register assignments }
    x28: array [7..19] of integer32;    { +28 }
    w80: integer;                       { +80 }
    num: 0..65535;                      { +82: its number }
    first: lt_ptr_t;                    { +84: its first statement }
    last: lt_ptr_t;                     { +88: its last }
    x92: array [23..24] of integer32;   { +92 }
    reg_save: integer32;                { +100: the registers saved }
    w104: integer;                      { +104 }
    nsucc: integer;                     { +106 }
    succ: lt_bbs_ptr_t;                 { +108: the successors }
    w112: integer;                      { +112 }
    npred: integer;                     { +114 }
    pred: array [1..1000] of lt_bb_ptr_t;  { +116: the predecessors }
  end;

  { An edge of the call graph (print_routine_block). }
  lt_edge_ptr_t = ^lt_edge_t;
  lt_edge_t = record
    callee: lt_ptr_t;                   { +0 }
    entry: lt_ptr_t;                    { +4 }
    caller: lt_ptr_t;                   { +8 }
    caller_ib: lt_ptr_t;                { +12 }
    call: lt_ptr_t;                     { +16 }
    tln: lt_ptr_t;                      { +20 }
    x24: integer32;                     { +24 }
    next_caller: lt_edge_ptr_t;         { +28 }
    next_callee: lt_edge_ptr_t;         { +32 }
  end;
  lt_ptr_array_t = array [1..64] of lt_ptr_t;

  { A node as this unit reads it.  The kinds' variants by offset (xp, xl,
    xw, xc as il.ins.pas's) where no named one is declared. }
  lt_node_t = record
    flags: packed record                { +0 }
      rewritten: boolean;               { .7 }
      f6, f5, f4, f3, f2, f1, f0: boolean;
    end;
    b1: char;                           { +1 }
    kind: integer;                      { +2 }
    case integer of
      { A tree node (137, 138, 143; 164, 171, 175, 189, 190, 219, 220,
        232 as listed). }
      1: (phase: add_node_$phase_t;     { +4 }
          w8: integer;                  { +8 }
          cse_parent: 0..65535;         { +10: the parent's number }
          l12: integer32;               { +12 }
          uses: integer;                { +16 }
          w18: integer;                 { +18 }
          aux: lt_aux_t;                { +20 }
          op: 0..65535;                 { +36: the operator }
          count: integer;               { +38: the operands }
          opnd: lt_ptr_array_t);        { +40 }
      { A reference (145 DINDEX_NODE, 146 PTR_NODE, 147 DISP_NODE, 205
        SYM_DISP_NODE). }
      2: (rf_phase: add_node_$phase_t;  { +4 }
          rf_w8: integer;               { +8 }
          rf_w10: integer;              { +10 }
          rf_w12: integer;              { +12 }
          rf_w14: integer;              { +14 }
          rf_uses: integer;             { +16 }
          rf_w18: integer;              { +18 }
          rf_w20: integer;              { +20 }
          align: -128..127;             { +22 }
          addr_bits: 0..255;            { +23 }
          base: lt_ptr_t;               { +24 }
          ind: lt_ptr_t;                { +28 }
          disp: integer32;              { +32: a symbol for 205 }
          index: lt_ptr_t;              { +36 }
          scale: integer;               { +40 }
          index_len: integer);          { +42 }
      { An ISC node (219 ISC_FETCH, 220 ISC_CONVERT, 232 ISC_SHARE). }
      3: (is_opnd: lt_ptr_t;            { +4 }
          is_size: integer32;           { +8 }
          is_rlen: integer;             { +12 }
          is_signed: boolean;           { +14 }
          is_b15: char;                 { +15 }
          is_w16: integer;              { +16 }
          is_w18: integer;              { +18 }
          is_next: lt_ptr_t);           { +20 }
      { A variable (109). }
      4: (vr_name: lt_ptr_t;            { +4: its identifier }
          vr_x8: array [2..6] of integer32;         { +8 }
          vr_type: lt_ptr_t;            { +28 }
          vr_attr: lt_vattr_t;          { +32 }
          vr_x36: array [9..13] of integer32;       { +36 }
          vr_disp: integer32;           { +56 }
          vr_x60: array [15..17] of integer32;      { +60 }
          vr_vat: integer;              { +72: its allocation }
          vr_number: integer);          { +74 }
      { A Fortran symbol (110). }
      5: (fs_x4: integer32;             { +4 }
          fs_w8: integer;               { +8 }
          fs_flags: packed record       { +10 }
            b7: boolean;
            b6, b5, b4: boolean;
            d_cls: 0..15;               { .3..0: the data class }
            b11: 0..255;                { +11 }
          end;
          fs_x12: array [3..10] of integer32;       { +12 }
          fs_attr: packed record        { +44 }
            cls: 0..15;                 { .7..4: the kind of symbol }
            f3, f2, f1, f0: boolean;
            f15, f14, f13, f12: boolean;  { +45 }
            f11, f10, f9, f8: boolean;
          end;
          fs_w46: integer;              { +46 }
          fs_lbl_root: lt_ptr_t;        { +48 }
          fs_x52: array [13..16] of integer32;      { +52 }
          fs_w68: integer;              { +68 }
          fs_len: integer;              { +70 }
          fs_name: array [1..4096] of char);        { +72 }
      { An exception frame (222). }
      6: (ef_x4: array [1..9] of integer32;         { +4 }
          ef_predefined: set of 0..15); { +40 }
      { A block (105..108 program, module, procedure and function, 167
        an entry, 172 an inner block, 209 block data). }
      7: (bk_x4: array [1..60] of integer32;        { +4 }
          bk_callees: lt_edge_ptr_t;    { +244: the call graph's edges
                                          to its callees }
          bk_x248: integer32;           { +248 }
          bk_callers: lt_edge_ptr_t;    { +252: from its callers }
          bk_x256: array [64..72] of integer32;     { +256 }
          bk_w292: integer;             { +292 }
          bk_slevel: integer;           { +294 }
          bk_name: lt_ptr_t;            { +296: its identifier }
          bk_line: integer;             { +300 }
          bk_w302: integer;             { +302 }
          bk_alias: lt_ptr_t;           { +304: its alias's identifier }
          bk_x308: array [77..91] of integer32;     { +308 }
          bk_w368: integer;             { +368 }
          bk_w370: integer;             { +370 }
          bk_w372: integer;             { +372 }
          bk_atts: array [374..379] of lt_bits_t);  { +374: the
                                          attributes, by byte }
      { A top-level node (a statement: 139..142, 144, 148..151, 188,
        191, 214, 215, 223..225, 227, 228, 231, 233). }
      8: (st_prev: lt_ptr_t;            { +4 }
          st_next: lt_ptr_t;            { +8: the spine }
          st_xf: lt_ptr_t;              { +12 }
          st_x16: integer32;            { +16 }
          st_ln: integer;               { +20: the line }
          st_vars: lt_vars_ptr_t;       { +22: the routine's variables }
          st_x26: integer32;            { +26 }
          st_x30: integer32;            { +30 }
          st_used: lt_used_ptr_t;       { +34: the variables used }
          st_def: char;                 { +38: the variable defined }
          st_b39: char;                 { +39 }
          st_b40: char;                 { +40 }
          st_b41: char;                 { +41: flags }
          st_b42: char;                 { +42: flags }
          st_b43: char;                 { +43: the statement index }
          st_b44: char;                 { +44 }
          st_lvl: char;                 { +45 }
          st_w46: integer;              { +46 }
          st_aux: lt_aux_t;             { +48: an assignment's (140,
                                          227) descriptor }
          st_dst: lt_ptr_t;             { +64 }
          st_src: lt_ptr_t;             { +68 }
          st_len: lt_ptr_t;             { +72 }
          st_aop: 0..65535);            { +76: the assignment operator }
      18: (sl_x4: array [1..11] of integer32;       { +4 }
           st_serial: 0..65535;         { +48: a label's (144) serial }
           st_count: 0..65535;          { +50: an evaluation's (139)
                                          operands }
           mm_sreg: 0..65535);          { +52: an MMU operation's (233) }
      19: (hd_x4: array [1..16] of integer32;       { +4 }
           hd_w68: integer;             { +68 }
           hd_count: 0..65535);         { +70: a handler's (223)
                                          exceptions, from +76 }
      { A block's register assignments (178), per register 0..23. }
      17: (ra: array [0..23] of lt_ra_t);           { +4 }
      9: (xp: array [1..94] of lt_ptr_t);           { +4 }
      10: (xp2_pad: integer;                        { +4 }
           xp2: array [1..93] of lt_ptr_t);         { +6 }
      11: (xl: array [1..94] of integer32);         { +4 }
      12: (xl2_pad: integer;                        { +4 }
           xl2: array [1..93] of integer32);        { +6 }
      13: (xw: array [2..189] of integer);          { +4 }
      14: (xc: array [4..379] of char);             { +4 }
      15: (xb: array [4..379] of -128..127);        { +4 }
      16: (xs: array [4..379] of lt_bits_t);        { +4 }
  end;

  { The line's sizes' letters (+0x130 of the data), by +8 of a register
    assignment. }
  lt_size_t = array [1..2] of char;

  { TYPE_EXP's result (c_objtype.ins.pas type_exp_t, 28 bytes). }
  lt_texp_t = record
    base: lt_ptr_t;                     { +0 }
    node: univ_ptr;                     { +4 }
    low: integer32;                     { +8 }
    high: integer32;                    { +12 }
    size: integer32;                    { +16 }
    bytes: integer32;                   { +20 }
    flags: integer32;                   { +24 }
  end;

  { The IL's node table (il_120, il_126 entries). }
  lt_nodes_t = array [1..1000000] of lt_ptr_t;
  lt_nodes_ptr_t = ^lt_nodes_t;

var
  { The module's data, A5 0x169DFC (cc.m68k), 0x2E9E6C (cc.a88k). }
  blanks: array [1..24] of char := '                        ';  { +0 }
  line: iosub_$line_t;                  { +0x18: the line being built (the
                                          image's has length 0 and 256
                                          blanks; dpc refuses '' for a
                                          varying string's initializer) }
  countdown: integer32 := 3;            { +0x11C: sanity_check_countdown }
  emit: lt_emit_t := nil;               { +0x120: where lines go (nil:
                                          diag_$writeln) }
  inline_depth: integer := 0;           { +0x124 }
  w126: integer := 0;                   { +0x126 }
  last_node: integer := 0;              { +0x128: the node last numbered }
  indent: integer := 0;                 { +0x12A: the line's indent }
  size_letters: array [0..8] of lt_size_t := [
    '**', 'B:', 'W:', '**', 'L:', 'A:', 'R:', 'D:', '**'];  { +0x130 }

{ initialise_list_tree - a fresh dump whose lines go to p.

  0x07E7C0, 0x28 bytes: no frame (docs/rev889-patterns.md 16); p at
  (4,SP); clears the line's length (+0x18), the indent, the node
  number, +0x126 and the inline depth and keeps p (+0x120). }

procedure initialise_list_tree(
    p: lt_emit_t); internal; options(val_param);
begin
  line.length := 0;
  indent := 0;
  emit := p;
  last_node := 0;
  w126 := 0;
  inline_depth := 0;
end;

{ fresh_ln - unless the line holds only its indent, write it; start a
  new one indented by n (at most 246).

  0x07E7E8, 0x8C bytes: the line's length compared with the indent
  (+0x12A); through emit (`jsr (A0)', the line by address) or, when
  emit is nil, diag_$assure_fresh_line and diag_$writeln('%a%$', the
  characters, the length as a longword in a frame temporary); then n
  blanks (the `dbf' loop), n kept as the indent. }

procedure fresh_ln(
    n: integer); internal; options(val_param);
var
  len: integer32;
  n2: integer;
  i: integer32;
begin
  if line.length <> indent then begin
    if emit <> nil then
      emit^(line)
    else begin
      diag_$assure_fresh_line;
      len := line.length;
      diag_$writeln('%a%$', line.body, len);
    end;
  end;
  line.length := 0;
  n2 := n;
  if n2 > 246 then
    n2 := 246;
  for i := 1 to n2 do begin
    line.length := line.length + 1;
    line.body[line.length] := ' ';
  end;
  indent := n;
end;

{ finialise_list_tree - the last line written; the dump's state reset.

  0x07E878, 0x18 bytes: fresh_ln(0), initialise_list_tree(nil). }

procedure finialise_list_tree; internal;
begin
  fresh_ln(0);
  initialise_list_tree(nil);
end;

{ print_ln - the line to the listing (listln) even if it holds only
  its indent (then empty); a new one indented by n.

  0x07E890, 0x3A bytes. }

procedure print_ln(
    n: integer); internal; options(val_param);
begin
  if line.length = indent then
    line.length := 0;
  listln(line);
  line.length := 0;
  indent := 0;
  fresh_ln(n);
end;

{ break_line - the line is full: end it with '\', continue on the next
  at the same indent after '\ '.

  0x07E8CA, 0x3C bytes. }

procedure break_line; internal;
begin
  line.length := line.length + 1;
  line.body[line.length] := '\';
  fresh_ln(indent);
  line.length := line.length + 1;
  line.body[line.length] := '\';
  line.length := line.length + 1;
  line.body[line.length] := ' ';
end;

{ print_char - c to the line (broken first when full).

  0x07E906, 0x30 bytes: the length plus 1 compared unsigned with 256
  (`cmpi.l #256; bcs'). }

procedure print_char(
    c: char); internal; options(val_param);
begin
  if line.length + 1 >= 256 then
    break_line;
  line.length := line.length + 1;
  line.body[line.length] := c;
end;

{ print_2_chars - c1 and c2 to the line.

  0x07E936, 0x48 bytes. }

procedure print_2_chars(
    c1: char;
    c2: char); internal; options(val_param);
begin
  if line.length + 2 >= 256 then
    break_line;
  line.length := line.length + 1;
  line.body[line.length] := c1;
  line.length := line.length + 1;
  line.body[line.length] := c2;
end;

{ print_3_chars - c1, c2 and c3 to the line.

  0x07E97E, 0x5E bytes. }

procedure print_3_chars(
    c1: char;
    c2: char;
    c3: char); internal; options(val_param);
begin
  if line.length + 3 >= 256 then
    break_line;
  line.length := line.length + 1;
  line.body[line.length] := c1;
  line.length := line.length + 1;
  line.body[line.length] := c2;
  line.length := line.length + 1;
  line.body[line.length] := c3;
end;

{ print_string - the n characters of s to the line.

  0x07E9DC, 0x5C bytes: the length plus n compared signed with 256
  (`blt'); the characters copied in a `dbf' loop, the length kept in
  D0 and stored once at the end. }

procedure print_string(
    in s: univ prtsub_$chars_t;
    n: integer); internal; options(val_param);
var
  len: integer32;
  i: integer32;
begin
  if line.length + n >= 256 then
    break_line;
  len := line.length;
  for i := 1 to n do begin
    len := len + 1;
    line.body[len] := s[i];
  end;
  line.length := len;
end;

{ print_integer - n in decimal (prtint: width, zero_fill) to the line.

  0x07EA38, 0x32 bytes: a PRTSUB line in the frame (-264). }

procedure print_integer(
    n: integer32;
    width: integer;
    zero_fill: boolean); internal; options(val_param);
var
  s: prtsub_$line_t;
begin
  s.length := 0;
  prtint(s, n, width, zero_fill);
  print_string(s.body, s.length);
end;

{ print_hex - the last width hexadecimal digits of n to the line.

  0x07EA6A, 0x30 bytes. }

procedure print_hex(
    n: integer32;
    width: integer); internal; options(val_param);
var
  s: prtsub_$line_t;
begin
  s.length := 0;
  prthex(s, n, width);
  print_string(s.body, s.length);
end;

{ print_bool - '1' or '0'.

  0x07EA9A, 0x20 bytes. }

procedure print_bool(
    b: boolean); internal; options(val_param);
begin
  if b then
    print_char('1')
  else
    print_char('0');
end;

{ print_comma - s (n characters) to the line, after a ',' unless it is
  the first (first is false until the first call).

  0x07EABA, 0x36 bytes. }

procedure print_comma(
    var first: boolean;
    in s: univ prtsub_$chars_t;
    n: integer); internal; options(val_param);
begin
  if first then
    print_char(',')
  else
    first := true;
  print_string(s, n);
end;

{ print_object_ptr - the node p as PRTOBJ prints it (with full, its
  kind).

  0x07EAF0, 0x30 bytes. }

procedure print_object_ptr(
    p: univ_ptr;
    full: boolean); internal; options(val_param);
var
  s: prtsub_$line_t;
begin
  s.length := 0;
  prtobj_$prtobj_full(s, p, full);
  print_string(s.body, s.length);
end;

{ prtphasebits - the names of the phase bits set in ph, separated by
  commas.

  0x07EB20, 0x292 bytes: the separator's flag a frame byte (-6); the
  bits tested in the source's order (`btst #n,D2'; bit 7 `tst.b', 15
  `tst.w'). }

procedure prtphasebits(
    ph: add_node_$phase_t); internal; options(val_param);
var
  first: boolean;
begin
  first := false;
  if 17 in ph then print_comma(first, 'nvr_invld', 9);
  if 0 in ph then print_comma(first, 'ATM', 3);
  if 1 in ph then print_comma(first, 'VOL', 3);
  if 2 in ph then print_comma(first, 'VOLexpr', 7);
  if 16 in ph then print_comma(first, 'VOLdecl', 7);
  if 3 in ph then print_comma(first, 'DEVrd', 5);
  if 4 in ph then print_comma(first, 'DEVwt', 5);
  if 5 in ph then print_comma(first, 'vis', 3);
  if 6 in ph then print_comma(first, 'cse', 3);
  if 7 in ph then print_comma(first, 'algn_arg_lst', 12);
  if 8 in ph then print_comma(first, 'indx_lng', 8);
  if 9 in ph then print_comma(first, 'dly', 3);
  if 10 in ph then print_comma(first, 'bnd', 3);
  if 11 in ph then print_comma(first, 'wlkd', 4);
  if 12 in ph then print_comma(first, 'sd_eff', 6);
  if 13 in ph then print_comma(first, 'tgt_rt', 6);
  if 14 in ph then print_comma(first, 'tgt_lft', 7);
  if 15 in ph then print_comma(first, 'invar', 5);
  if 18 in ph then print_comma(first, 'isc', 3);
  if 19 in ph then print_comma(first, 'phys', 4);
  if 20 in ph then print_comma(first, 'proc_reg', 8);
  if 21 in ph then print_comma(first, 'enf_paren', 9);
  if 22 in ph then print_comma(first, 'lcl_cse', 7);
end;

{ print_uc_and_phase - ' [' the phase bits, ',' and 'uc=' the use count
  unless it is 1, ']'; nothing for an empty phase and a count of 1.

  0x07EE44, 0x80 bytes: uc (8) a word, ph (10) a longword. }

procedure print_uc_and_phase(
    uc: integer;
    ph: add_node_$phase_t); internal; options(val_param);
begin
  if (ph <> []) or (uc <> 1) then begin
    print_string(' [', 2);
    prtphasebits(ph);
    if uc <> 1 then begin
      if ph <> [] then
        print_char(',');
      print_string('uc=', 3);
      print_integer(uc, 3, true);
    end;
    print_char(']');
  end;
end;

{ print_rlen - the name of register class r to s; another value as
  '?? ' r ' ??'.

  0x07EECC, 0x122 bytes: a `case' of 13 entries (3 not a label); every
  arm ends at one prtcats (0x07EFDA). }

procedure print_rlen(
    in out s: prtsub_$line_t;
    r: integer); internal; options(val_param);
begin
  case r of
    0: prtcats(s, '??-null-??', 10);
    1: prtcats(s, 'byte', 4);
    2: prtcats(s, 'word', 4);
    4: prtcats(s, 'long', 4);
    5: prtcats(s, 'addr', 4);
    6: prtcats(s, 'r4', 2);
    7: prtcats(s, 'r8', 2);
    8: prtcats(s, 'c8', 2);
    9: prtcats(s, 'cs', 2);
    10: prtcats(s, 'vcs', 3);
    11: prtcats(s, 'agg', 3);
    12: prtcats(s, 'c16', 3);
    otherwise begin
      prtcats(s, '?? ', 3);
      prtint(s, r, 10, false);
      prtcats(s, ' ??', 3);
    end;
  end;
end;

{ LIST_TREE_$PRINT_RLEN - print_rlen for other units.

  0x07F024, 0x2A bytes: loads A5; no call sites in the binaries. }

procedure list_tree_$print_rlen(
    in out s: univ prtsub_$line_t;
    r: integer); options(val_param);
begin
  print_rlen(s, r);
end;

{ print_relational - the name of condition code c to s.

  0x07F04E, 0x160 bytes: a `case' of 16 entries. }

procedure print_relational(
    in out s: prtsub_$line_t;
    c: integer); internal; options(val_param);
begin
  case c of
    0: prtcats(s, 'T', 1);
    1: prtcats(s, 'F', 1);
    2: prtcats(s, 'HI', 2);
    3: prtcats(s, 'LS', 2);
    4: prtcats(s, 'CC', 2);
    5: prtcats(s, 'CS', 2);
    6: prtcats(s, 'NE', 2);
    7: prtcats(s, 'EQ', 2);
    8: prtcats(s, 'VC', 2);
    9: prtcats(s, 'VS', 2);
    10: prtcats(s, 'PL', 2);
    11: prtcats(s, 'MI', 2);
    12: prtcats(s, 'GE', 2);
    13: prtcats(s, 'LT', 2);
    14: prtcats(s, 'GT', 2);
    15: prtcats(s, 'LE', 2);
    otherwise begin
      prtcats(s, '?? ', 3);
      prtint(s, c, 10, false);
      prtcats(s, ' ??', 3);
    end;
  end;
end;

{ print_math - the name of mathematical function f to s.

  0x07F1CE, 0x1F0 bytes: a `case' of 25 entries. }

procedure print_math(
    in out s: prtsub_$line_t;
    f: integer); internal; options(val_param);
begin
  case f of
    0: prtcats(s, 'ABS', 3);
    1: prtcats(s, 'SIN', 3);
    2: prtcats(s, 'COS', 3);
    3: prtcats(s, 'TAN', 3);
    4: prtcats(s, 'LOG', 3);
    5: prtcats(s, 'LOG10', 5);
    6: prtcats(s, 'EXP', 3);
    7: prtcats(s, 'ATAN', 4);
    8: prtcats(s, 'ATAN2', 5);
    9: prtcats(s, 'SQRT', 4);
    10: prtcats(s, 'TRUNC', 5);
    11: prtcats(s, 'NINT', 4);
    12: prtcats(s, 'MAX', 3);
    13: prtcats(s, 'MIN', 3);
    14: prtcats(s, 'CONJG', 5);
    15: prtcats(s, 'AIMAG', 5);
    16: prtcats(s, 'ASIN', 4);
    17: prtcats(s, 'ACOS', 4);
    18: prtcats(s, 'SINH', 4);
    19: prtcats(s, 'COSH', 4);
    20: prtcats(s, 'TANH', 4);
    21: prtcats(s, 'ROUND', 5);
    22: prtcats(s, 'II_EXPON', 8);
    23: prtcats(s, 'FI_EXPON', 8);
    24: prtcats(s, 'FF_EXPON', 8);
    otherwise begin
      prtcats(s, '?? ', 3);
      prtint(s, f, 10, false);
      prtcats(s, ' ??', 3);
    end;
  end;
end;

{ print_opmod_use - an operand modifier v as use u says it is used to
  s: ',op/' (',op1/' for the second) and the use's name and value;
  nothing for the first when u is 0 (not used) or 18.

  0x07F43A, 0x29E bytes: the test `move.l #0x40001,D1; btst u,D1'; a
  `case' of 19 entries; 0 and 18 print v raw ('??NOT USED ', '??USE '),
  with its register class after a '/' when v <= 12, and ' ??' (one copy
  of the tail, docs/rev889-patterns.md 23). }

procedure print_opmod_use(
    in out s: prtsub_$line_t;
    v: integer32;
    u: integer;
    second: boolean); internal; options(val_param);
begin
  if not second and (u in [0, 18]) then
    return;
  if second then
    prtcats(s, ',op1/', 5)
  else
    prtcats(s, ',op/', 4);
  case u of
    0: begin
      prtcats(s, '??NOT USED ', 11);
      prtint(s, v, 10, false);
      if v <= 12 then begin
        prtcatc(s, '/');
        print_rlen(s, v);
      end;
      prtcats(s, ' ??', 3);
    end;
    1: begin
      prtcats(s, 'opr1=', 5);
      print_rlen(s, v);
    end;
    2: begin
      prtcats(s, 'opr2=', 5);
      print_rlen(s, v);
    end;
    3: begin
      prtcats(s, 'opr1-2=', 7);
      print_rlen(s, v);
    end;
    4: begin
      prtcats(s, 'opr2-3=', 7);
      print_rlen(s, v);
    end;
    5: begin
      prtcats(s, 'src=', 4);
      print_rlen(s, v);
    end;
    6: begin
      prtcats(s, 'dst=', 4);
      print_rlen(s, v);
    end;
    7: begin
      prtcats(s, 'rel=', 4);
      print_relational(s, v);
    end;
    8: begin
      prtcats(s, 'opr1 bytes=', 11);
      prtint(s, v, 10, false);
    end;
    9: begin
      prtcats(s, 'start bit=', 10);
      prtint(s, v, 10, false);
    end;
    10: begin
      prtcats(s, 'fw=', 3);
      prtint(s, v, 10, false);
    end;
    11: begin
      prtcats(s, 'func=', 5);
      print_math(s, v);
    end;
    12: begin
      prtcats(s, 'fill bytes=', 11);
      prtint(s, v, 10, false);
    end;
    13: begin
      prtcats(s, 'alignment=', 10);
      prtint(s, v, 10, false);
    end;
    14: begin
      prtcats(s, 'units=', 6);
      print_rlen(s, v);
    end;
    15: begin
      prtcats(s, 'col=', 4);
      prtint(s, v, 10, false);
    end;
    16: begin
      prtcats(s, 'msg#=', 5);
      prtint(s, v, 10, false);
    end;
    17: begin
      prtcats(s, 'linkage reg=', 12);
      prtint(s, v, 10, false);
    end;
    18: begin
      prtcats(s, '??USE ', 6);
      prtint(s, v, 10, false);
      if v <= 12 then begin
        prtcatc(s, '/');
        print_rlen(s, v);
      end;
      prtcats(s, ' ??', 3);
    end;
    otherwise
  end;
end;

{ print_known_aux - a tree node's descriptor to s: ' aux[rl=' its
  register class and ',sz=' its size (or 'null' for class 0 and size
  0), its two operand modifiers as uses u1 and u2 say, with sgn its
  signedness, with ovfl ',ovfl=1' when its overflow flag is set; ']'.

  0x07F76E, 0x128 bytes: the modifiers (+6, +8) zero-extended
  (`clr.l; move.w'); the flags at +10 bit 6 (`btst #6') and bit 7
  (`tst.b'). }

procedure print_known_aux(
    in out s: prtsub_$line_t;
    in aux: lt_aux_t;
    u1: integer;
    u2: integer;
    sgn: boolean;
    ovfl: boolean); internal; options(val_param);
begin
  prtcats(s, ' aux[rl=', 8);
  if (aux.rlen = 0) and (aux.size = 0) then
    prtcats(s, 'null', 4)
  else begin
    print_rlen(s, aux.rlen);
    prtcats(s, ',sz=', 4);
    prtint(s, aux.size, 10, false);
  end;
  print_opmod_use(s, aux.opmod1, u1, false);
  print_opmod_use(s, aux.opmod2, u2, true);
  if sgn then begin
    prtcats(s, ',sgn=', 5);
    if aux.flags.sgn then
      prtcatc(s, '1')
    else
      prtcatc(s, '0');
  end;
  if ovfl and aux.flags.ovfl then
    prtcats(s, ',ovfl=1', 7);
  prtcatc(s, ']');
end;

{ LIST_TREE_$PRINT_AUX - a descriptor to s with its modifiers raw.

  0x07F8B4, 0x3A bytes: loads A5; print_known_aux(s, aux, 18, 18,
  true, true) (18 and 18 pushed as one longword, docs/rev889-patterns.md
  54); no call sites in the binaries. }

procedure list_tree_$print_aux(
    in out s: univ prtsub_$line_t;
    in aux: univ lt_aux_t); options(val_param);
begin
  print_known_aux(s, aux, 18, 18, true, true);
end;

{ print_tree_ref - a short reference to the node t: for the kinds the
  dumps number, 'Node' and its number in the IL's node table (il_120,
  il_126 entries), searched from the last one numbered, and ' ' with
  -TREE ADDR or when it is not in the table (else nothing more); then
  'R-' for a rewritten node and a letter or word for its kind and its
  address in hexadecimal; other nodes as PRTOBJ prints them (a node
  with a phase after it in braces).

  0x07F8EE, 0x434 bytes.  The kind sets are 30-byte constants (0..239,
  no range check: docs/rev889-patterns.md 41) at 0x07FD22 and
  0x07FD66; -TREE NA (cargs_$options.na, `btst #2,0x2C3665') turns
  the numbering off.  The table is tried at last_node + 1, then from
  last_node down to 1 (a `dbf' loop) and from last_node + 2 up to
  il_126 (found there, last_node moves).  The `case' on the kind is a
  compare chain in the labels' order; its letters end at one
  print_char (0x07FC04), its words at one print_string (0x07FC80),
  both followed by print_hex(t, 8) (0x07FD0C); the other arms end at
  the epilogue.  Kind 172 (an inner block): 'ib' when +296 is not nil
  or (nil) its kind is 73, else 'inner_blk ' and +296 as an object
  (the image reads the kind through the nil pointer).

  Not known from the original: the loops' form (a goto out of them is
  written). }

procedure print_tree_ref(
    t: lt_ptr_t;
    b: boolean); internal; options(val_param);
label
  1;
var
  ph: add_node_$phase_t;
  i: integer;
  n: integer32;
begin
  if t = nil then begin
    print_object_ptr(t, true);
    return;
  end;
  if (t^.kind in [137..140, 142..143, 145..148, 164, 171, 175, 189..190, 205, 214..215, 219..220, 223..225, 227..228, 231..233]) and (il_120 <> nil) and not cargs_$options.na then begin
    if lt_nodes_ptr_t(il_120)^[last_node + 1] = t then begin
      print_string('Node', 4);
      print_integer(last_node + 1, 5, true);
      last_node := last_node + 1;
    end
    else begin
      for i := last_node downto 1 do
        if lt_nodes_ptr_t(il_120)^[i] = t then begin
          print_string('Node', 4);
          n := i;
          print_integer(n, 5, true);
          goto 1;
        end;
      for i := last_node + 2 to il_126 do
        if lt_nodes_ptr_t(il_120)^[i] = t then begin
          last_node := i;
          print_string('Node', 4);
          n := i;
          print_integer(n, 5, true);
          goto 1;
        end;
      b := true;
    end;
  1:
    if not (cargs_$options.addr or b) then
      return;
    print_char(' ');
  end;
  if t^.flags.rewritten then
    print_2_chars('R', '-');
  if t^.kind in [139..142, 148..151, 214..215, 223..225, 227..228, 231, 233] then
    print_char('s')
  else if t^.kind in [219, 232, 220] then
    print_char('a')
  else
    case t^.kind of
      221, 114, 166, 113: print_char('f');
      137: print_char('t');
      138: print_char('g');
      143: print_char('c');
      146: print_char('p');
      147: print_char('d');
      205: print_char('m');
      145: print_char('i');
      164: print_string('cs', 2);
      171: print_string('cc', 2);
      175: print_string('pf', 2);
      190: print_string('cse', 3);
      189: print_string('use', 3);
      222: print_char('e');
      172:
        if (t^.xp[73] <> nil) or (t^.xp[73]^.kind = 73) then
          print_string('ib', 2)
        else begin
          print_string('inner_blk ', 10);
          print_object_ptr(t^.xp[73], true);
          return;
        end;
      144: begin
        print_char(':');
        print_object_ptr(t, true);
        print_2_chars(' ', ' ');
        return;
      end;
      188: print_string('udf', 3);
      191: print_string('reg', 3);
      176: begin
        print_string('REC_CONST ', 10);
        print_string('linkp=', 6);
        print_hex(t^.xl[1], 8);
        print_string(',size=', 6);
        print_integer(t^.xl[2], 6, false);
        return;
      end;
      209, 167, 105, 108, 107, 106: begin
        print_object_ptr(t, true);
        return;
      end;
      otherwise begin
        ph := getphase(t);
        if ph <> [] then begin
          print_char('{');
          prtphasebits(ph);
          print_char('}');
        end;
        print_object_ptr(t, true);
        return;
      end;
    end;
  print_hex(integer32(t), 8);
end;

procedure print_spine(
    t: lt_ptr_t;
    n: integer); internal; options(val_param); forward;

{ print_tree_exp - the tree t on lines indented by n: its reference and
  ': ', its kind and operator, the descriptor (print_known_aux, with the
  uses the operator gives its modifiers), the use count and phase, its
  operands as references and then each operand's tree indented by 2
  more (a call's spine operands as 'IN  Args:' or 'OUT Args:' and the
  spine indented by 4); a reference with its displacement or symbol,
  alignment, base, index and the base's and index's trees; the other
  kinds in their own forms.  '*** NIL ***' for nil.

  0x07FD94, 0xDAC bytes.  The kinds dumped are a set constant
  (0x080B40); the kinds' `case' is a compare chain in the labels'
  order.  The operator's `case' (+36) is a jump table of 90 entries
  (0x07FED0); the operators:
    0 NOP, 1 ADD, 2 SUB, 3 MUL, 4 DIV, 5 DIVIDE, 6 MOD, 7 NEG, 8 NOT,
    9 AND, 10 OR, 11 BIT_TEST, 12 COMPARE, 13 INDEX, 14 UNPACK, 15 CALL,
    16 FUNC_CALL, 17 VALUE, 18 EXTEND, 19 SET_AND, 20 SET_OR,
    21 SET_DIFF, 22 SET_EXTEND, 23 SET_CMP, 24 AGG_CMP, 25 BIT_SET,
    26 ADDR, 27 LSHFT, 28 RSHFT, 29 ABS, 30 ISC_CALL, 31 ISC_FUNC_CALL,
    32 ISC_FUNC_CALL_HIDDEN_TEMP, 33 ISC_MUL, 34 F_ADD, 35 F_SUB,
    36 F_MUL, 37 F_DIV, 38 F_NEG, 39 F_EXTEND, 40 F_COMPARE, 41 F_MATH,
    42 F_EXPON, 43 EXPON, 44 EOR, 45 MAX, 46 MIN, 47 AND-to-SR or
    OR-to-SR (by the sign of operand 1's +8), 48 CHK, 49 ALSHFT,
    50 ARSHFT, 51 p_C3EXPR, 52 p_LOGOR, 53 p_LOGAND, 54 p_ASSIGN,
    55 p_POST_ID, 56 p_COMMA, 57 p_LOGNOT, 58 REF_EXPRp_, 59 SIGNED_DIV,
    60 UNSIGNED_DIV, 61 SIGNED_MOD, 62 UNSIGNED_MOD, 63 ALIGN,
    64 ISC_ADDR, 65 ALLOC_DYNM, 66 CACHE, 67 ISC_FIO_INIT, 68 STRCMP,
    69 STRLEN, 70 STRNCMP, 71 ISC_SELECT, 72 SET_BIT_IN_SET,
    73 SET_RANGE_IN_SET, 74 ISC_SIGNED_REM, 75 ISC_UNSIGNED_REM,
    76 ISC_SIGNED_MOD, 77 ISC_UNSIGNED_MOD, 78 ISC_AGG_CMP,
    79 ISC_AGG_LEX_CMP, 80 RANGE_CHECK, 81 F_RANGE_CHECK,
    82 MARK_DYNAMIC_SPACE, 83 EXTRACT_BIT_FIELD, 84 BIT_FIELD_CMP,
    85 PHYSICAL, 86 ADA_EXPON, 87 F_ADA_EXPON, 88 p_PAS_GET_CHK,
    89 ILLEGAL; others '<ORD(TOP)=' n '>'.
  The arms' identical tails are shared (docs/rev889-patterns.md 23:
  the shifts', multiplications' and divisions' uses 1 and 2, the
  comparisons' 3 and 7, the ISC calls' 17).  The sign and overflow
  flags are printed for the operators of two constant sets of 0..95
  (0x080DEC, 0x080DF8: no range check).  A tree whose phase has bit 6
  (cse, `btst #6,(7,A2)') prints 'cse_parent= Node' and its +10
  instead of its operands.  The locals: the PRTSUB line at -264, the
  uses at -280 and -278.

  Not known from the original: whether the operators' names came from
  a table in the source (each is a literal here); the form of the tests
  on the kind before the operator (a `case' whose 137 arm is empty);
  the jump into the references' common part (a goto). }

procedure print_tree_exp(
    t: lt_ptr_t;
    n: integer); internal; options(val_param);
label
  2;
var
  s: prtsub_$line_t;
  u2: integer;
  u1: integer;
  i: integer32;
  ab: integer32;
begin
  fresh_ln(n);
  if t = nil then begin
    print_string('*** NIL ***', 11);
    return;
  end;
  if t^.kind in [137..138, 143, 145..147, 164, 171, 175, 189..190, 205, 219..220, 232] then begin
    print_tree_ref(t, true);
    print_2_chars(':', ' ');
    if t^.flags.rewritten then
      print_string('REWRITTEN ', 10);
    case t^.kind of
      143, 138, 137: begin
        case t^.kind of
          137: ;
          138: print_string('gen_', 4);
          143: print_string('cmp_', 4);
        end;
        u1 := 0;
        u2 := 0;
        case t^.op of
          0: print_string('NOP', 3);
          17: print_string('VALUE', 5);
          63: begin
            print_string('ALIGN', 5);
            u1 := 13;
          end;
          18: begin
            print_string('EXTEND', 6);
            u1 := 1;
          end;
          29: print_string('ABS', 3);
          7: print_string('NEG', 3);
          8: print_string('NOT', 3);
          1: print_string('ADD', 3);
          2: print_string('SUB', 3);
          9: print_string('AND', 3);
          10: print_string('OR', 2);
          44: print_string('EOR', 3);
          45: print_string('MAX', 3);
          46: print_string('MIN', 3);
          27: begin print_string('LSHFT', 5); u1 := 1; u2 := 2; end;
          28: begin print_string('RSHFT', 5); u1 := 1; u2 := 2; end;
          49: begin print_string('ALSHFT', 6); u1 := 1; u2 := 2; end;
          50: begin print_string('ARSHFT', 6); u1 := 1; u2 := 2; end;
          3: begin print_string('MUL', 3); u1 := 1; u2 := 2; end;
          33: begin print_string('ISC_MUL', 7); u1 := 1; u2 := 2; end;
          5: begin print_string('DIVIDE', 6); u1 := 1; u2 := 2; end;
          4: begin print_string('DIV', 3); u1 := 1; u2 := 2; end;
          59: begin print_string('SIGNED_DIV', 10); u1 := 1; u2 := 2; end;
          60: begin print_string('UNSIGNED_DIV', 12); u1 := 1; u2 := 2; end;
          6: begin print_string('MOD', 3); u1 := 1; u2 := 2; end;
          61: begin print_string('SIGNED_MOD', 10); u1 := 1; u2 := 2; end;
          62: begin print_string('UNSIGNED_MOD', 12); u1 := 1; u2 := 2; end;
          76: begin print_string('ISC_SIGNED_MOD', 14); u1 := 1; u2 := 2; end;
          77: begin print_string('ISC_UNSIGNED_MOD', 16); u1 := 1; u2 := 2; end;
          74: begin print_string('ISC_SIGNED_REM', 14); u1 := 1; u2 := 2; end;
          75: begin print_string('ISC_UNSIGNED_REM', 16); u1 := 1; u2 := 2; end;
          43: print_string('EXPON', 5);
          86: print_string('ADA_EXPON', 9);
          84: begin
            print_string('BIT_FIELD_CMP', 13);
            u1 := 3;
            if (t^.kind = 143) or (t^.aux.opmod2 <> 0) then u2 := 7;
          end;
          12: begin
            print_string('COMPARE', 7);
            u1 := 3;
            if (t^.kind = 143) or (t^.aux.opmod2 <> 0) then u2 := 7;
          end;
          40: begin
            print_string('F_COMPARE', 9);
            u1 := 3;
            if (t^.kind = 143) or (t^.aux.opmod2 <> 0) then u2 := 7;
          end;
          23: begin
            print_string('SET_CMP', 7);
            u1 := 3;
            if (t^.kind = 143) or (t^.aux.opmod2 <> 0) then u2 := 7;
          end;
          24: begin
            print_string('AGG_CMP', 7);
            u1 := 3;
            if (t^.kind = 143) or (t^.aux.opmod2 <> 0) then u2 := 7;
          end;
          78: begin
            print_string('ISC_AGG_CMP', 11);
            u1 := 3;
            if (t^.kind = 143) or (t^.aux.opmod2 <> 0) then u2 := 7;
          end;
          79: begin
            print_string('ISC_AGG_LEX_CMP', 15);
            u1 := 3;
            if (t^.kind = 143) or (t^.aux.opmod2 <> 0) then u2 := 7;
          end;
          70: print_string('STRNCMP', 7);
          68: print_string('STRCMP', 6);
          69: print_string('STRLEN', 6);
          11: begin
            print_string('BIT_TEST', 8);
            if t^.kind = 143 then u2 := 7;
            if t^.count = 2 then u1 := 2 else u1 := 4;
          end;
          25: begin
            print_string('BIT_SET', 7);
            if t^.count = 2 then u1 := 2 else u1 := 4;
          end;
          13: begin
            print_string('INDEX', 5);
            u1 := 2;
          end;
          14: begin
            print_string('UNPACK', 6);
            u1 := 1;
            u2 := 10;
          end;
          83: begin
            print_string('EXTRACT_BIT_FIELD', 17);
            u1 := 10;
          end;
          15: print_string('CALL', 4);
          30: begin print_string('ISC_CALL', 8); u1 := 17; end;
          16: print_string('FUNC_CALL', 9);
          31: begin print_string('ISC_FUNC_CALL', 13); u1 := 17; end;
          32: begin print_string('ISC_FUNC_CALL_HIDDEN_TEMP', 25); u1 := 17; end;
          26: print_string('ADDR', 4);
          64: begin
            print_string('ISC_ADDR', 8);
            u1 := 1;
            u2 := 8;
          end;
          38: print_string('F_NEG', 5);
          34: print_string('F_ADD', 5);
          35: print_string('F_SUB', 5);
          36: print_string('F_MUL', 5);
          37: print_string('F_DIV', 5);
          39: begin
            print_string('F_EXTEND', 8);
            if t^.count = 1 then u1 := 1 else u1 := 3;
            u2 := 0;
          end;
          41: begin
            print_string('F_MATH', 6);
            u1 := 11;
            if t^.count = 1 then u2 := 1 else u2 := 3;
          end;
          42: begin
            print_string('F_EXPON', 7);
            u2 := 1;
          end;
          87: print_string('F_ADA_EXPON', 11);
          47:
            if t^.opnd[1]^.xl[2] < 0 then
              print_string('AND-to-SR', 9)
            else
              print_string('OR-to-SR', 8);
          85: print_string('PHYSICAL', 8);
          66: print_string('CACHE', 5);
          51: print_string('p_C3EXPR', 8);
          52: print_string('p_LOGOR', 7);
          53: print_string('p_LOGAND', 8);
          54: print_string('p_ASSIGN', 8);
          55: print_string('p_POST_ID', 9);
          56: print_string('p_COMMA', 7);
          57: print_string('p_LOGNOT', 8);
          88: print_string('p_PAS_GET_CHK', 13);
          58: print_string('REF_EXPRp_', 10);
          65: print_string('ALLOC_DYNM', 10);
          67: print_string('ISC_FIO_INIT', 12);
          71: print_string('ISC_SELECT', 10);
          72: begin
            print_string('SET_BIT_IN_SET', 14);
            u1 := 2;
          end;
          73: begin
            print_string('SET_RANGE_IN_SET', 16);
            u1 := 4;
          end;
          19: print_string('SET_AND', 7);
          20: print_string('SET_OR', 6);
          21: print_string('SET_DIFF', 8);
          22: print_string('SET_EXTEND', 10);
          48: print_string('CHK', 3);
          80: print_string('RANGE_CHECK', 11);
          81: print_string('F_RANGE_CHECK', 13);
          82: print_string('MARK_DYNAMIC_SPACE', 18);
          89: print_string('ILLEGAL', 7);
          otherwise begin
            print_string('<ORD(TOP)=', 10);
            print_integer(t^.op, 2, true);
            print_char('>');
          end;
        end;
        s.length := 0;
        print_known_aux(s, t^.aux, u1, u2, t^.op in [0, 3..4, 6, 14, 17..18, 41, 43, 45..46, 86], t^.op in [1..4, 6..7, 18, 29, 33, 43, 59..62, 74..77, 86]);
        print_string(s.body, s.length);
        print_uc_and_phase(t^.uses, t^.phase);
        print_char(' ');
        if 6 in t^.phase then begin
          print_string('cse_parent= Node', 16);
          print_integer(t^.cse_parent, 5, true);
        end
        else begin
          for i := 1 to t^.count do begin
            print_tree_ref(t^.opnd[i], false);
            if t^.count <> i then
              print_char(',');
          end;
          for i := 1 to t^.count do
            if not il_utils_$tree_node_operand_is_spine(t^.op, i) then
              print_tree_exp(t^.opnd[i], n + 2)
            else begin
              fresh_ln(n + 2);
              if i = 2 then
                print_string('IN  Args:', 9)
              else
                print_string('OUT Args:', 9);
              if t^.opnd[i] = nil then
                print_string(' <none>', 7)
              else
                print_spine(t^.opnd[i], n + 4);
            end;
        end;
      end;
      145, 205, 147, 146: begin
        if t^.kind = 146 then
          print_string('PTR', 3)
        else if t^.kind = 147 then begin
          print_string('DISP(', 5);
          print_integer(t^.disp, 10, false);
          print_char(')');
          goto 2;
        end
        else if t^.kind = 205 then begin
          print_string('SYM_DISP(', 9);
          print_object_ptr(univ_ptr(t^.disp), true);
          print_char(')');
          goto 2;
        end
        else begin
          print_string('DINDEX', 6);
          if t^.disp <> 0 then begin
            print_string('(***DISP=', 9);
            print_integer(t^.disp, 10, false);
            print_string('***)', 4);
          end;
        end;
        print_string(' [align=', 8);
        print_integer(t^.align, 10, false);
        ab := t^.addr_bits & (lshft(1, t^.align) - 1);
        if ab <> 0 then begin
          print_string(',addr_bits=', 11);
          print_integer(ab, 10, false);
        end;
        print_char(']');
      2:
        print_uc_and_phase(t^.rf_uses, t^.rf_phase);
        print_char(' ');
        print_tree_ref(t^.base, false);
        if t^.kind = 145 then begin
          print_char(',');
          if t^.index_len = 4 then
            print_string('long ', 5)
          else
            print_string('word ', 5);
          print_tree_ref(t^.index, false);
          if t^.scale <> 0 then begin
            print_char('*');
            print_integer(lshft(1, t^.scale), 1, false);
          end;
        end;
        print_string(', ind=', 6);
        print_tree_ref(t^.ind, false);
        print_tree_exp(t^.base, n + 2);
        if t^.kind = 145 then
          print_tree_exp(t^.index, n + 2);
      end;
      171: begin
        print_string('CC_CALL ', 8);
        print_tree_ref(t^.xp[4], false);
        print_tree_exp(t^.xp[4], n + 2);
      end;
      175: begin
        print_string('PF_CALL ', 8);
        print_tree_ref(t^.xp[4], false);
        print_tree_exp(t^.xp[4], n + 2);
      end;
      164: begin
        print_string('CHARSTR(', 8);
        print_integer(t^.xw[15], 5, false);
        print_char(')');
        print_char(' ');
        print_uc_and_phase(t^.uses, []);
        print_tree_ref(t^.xp[5], false);
        print_char(',');
        print_tree_ref(t^.xp[6], false);
        print_tree_exp(t^.xp[5], n + 2);
        print_tree_exp(t^.xp[6], n + 2);
      end;
      190: begin
        print_string('CSE_PARENT ', 11);
        print_tree_ref(t^.xp[1], false);
        print_tree_exp(t^.xp[1], n + 2);
      end;
      189: begin
        print_string('CSE_USE ', 8);
        print_string('Parent ', 7);
        print_tree_ref(t^.xp[4], true);
      end;
      232, 220, 219: begin
        case t^.kind of
          219: print_string('ISC_FETCH', 9);
          220: print_string('ISC_CONVT', 9);
          232: print_string('ISC_SHARE', 9);
        end;
        print_string(' (size=', 7);
        print_integer(t^.is_size, 10, false);
        print_string(',rlen=', 6);
        s.length := 0;
        print_rlen(s, t^.is_rlen);
        print_string(s.body, s.length);
        print_string(',signed=', 8);
        print_bool(t^.is_signed);
        print_string(') ', 2);
        print_tree_ref(t^.is_opnd, true);
        print_string(' next=', 6);
        print_tree_ref(t^.is_next, true);
        print_tree_exp(t^.is_opnd, n + 2);
      end;
    end;
  end;
  fresh_ln(n);
end;

{ print_variable - a line for the variable v of block blk at indent n:
  the variable's number (+74) and address, its name padded to 18, its
  allocation class, displacement and size in bytes; for a Fortran
  symbol (110) its data class and its kind of symbol with that kind's
  flags, else its type's kind; then the variable's attributes.  Other
  nodes as PRTOBJ prints them.

  0x080F80, 0xB46 bytes.  A Fortran symbol's variable node comes from
  varn_from_fortran_symbol(v, blk, false); a variable (109) is its own.
  The size: 0 for a Fortran symbol of data class 7 with +10 bit 7, else
  sz_fsym(v); a variable's from type_exp(+28, addr(te)) (te at -32,
  its size at -16).  The `case' on the allocation (+72 of the variable
  node) is a table of 12, on the data class (+10 bits 3..0) of 14 with
  'd_cls=' n for the others, on the kind of symbol (+44 bits 7..4) of
  9; the type's kind a compare chain in the labels' order ('typ^.knd = '
  n for the others).  The kinds' names are the image's (an_kind_t's
  CHAR_TYPE and VOID_TYPE are 'char_type' and 'void_type', some cut to
  16 characters).  The attributes are the variable node's set at +32
  (tested as bytes, words and longwords in turn).  The names' padding
  is blanks (the module's +0).

  Not known from the original: the Fortran symbol's fields' names
  (from the strings printed); 'fmt_const_ptr=' is printed with no
  value. }

procedure print_variable(
    v: lt_ptr_t;
    blk: univ_ptr;
    n: integer); internal; options(val_param);
var
  bytes: integer32;
  te: lt_texp_t;
  vn: lt_ptr_t;
begin
  fresh_ln(n);
  if v^.kind = 110 then
    vn := lt_ptr_t(varn_from_fortran_symbol(il_$node_ptr_t(v), il_$node_ptr_t(blk), false))
  else if v^.kind = 109 then
    vn := v
  else begin
    print_object_ptr(v, true);
    return;
  end;
  print_integer(vn^.vr_number, 3, true);
  print_char(' ');
  print_hex(integer32(v), 8);
  print_string(blanks, 2);
  if v^.kind = 110 then begin
    print_string(v^.fs_name, v^.fs_len);
    print_string(blanks, 18 - v^.fs_len);
    if (v^.fs_flags.d_cls = 7) and v^.fs_flags.b7 then
      bytes := 0
    else
      bytes := sz_fsym(il_$node_ptr_t(v));
  end
  else begin
    print_string(v^.vr_name^.xc[18], v^.vr_name^.xw[8]);
    print_string(blanks, 18 - v^.vr_name^.xw[8]);
    type_exp(v^.vr_type, addr(te));
    bytes := te.size;
  end;
  case vn^.vr_vat of
    0: print_string('local_vat    ', 13);
    1: print_string('static_vat   ', 13);
    2: print_string('dynm_vat     ', 13);
    3: print_string('extern_vat   ', 13);
    4: print_string('externdef_vat', 13);
    5: print_string('param_vat    ', 13);
    6: print_string('xdynm_vat    ', 13);
    7: print_string('xstatic_vat  ', 13);
    8: print_string('xextrndef_vat', 13);
    9: print_string('based_vat    ', 13);
    10: print_string('sect_vat     ', 13);
    11: print_string('absolute_vat ', 13);
    otherwise
  end;
  print_string(' Disp:', 6);
  print_hex(vn^.vr_disp, 6);
  print_string('  Bytes:', 8);
  print_integer(bytes, 4, true);
  print_string(blanks, 2);
  if v^.kind = 110 then begin
    case v^.fs_flags.d_cls of
      0: print_string('none       ', 11);
      1: print_string('xbinteger  ', 11);
      2: print_string('xsinteger  ', 11);
      3: print_string('xlinteger  ', 11);
      4: print_string('xreal      ', 11);
      5: print_string('xdoubleprec', 11);
      6: print_string('xcomplex   ', 11);
      7: print_string('xcharacter ', 11);
      8: print_string('xblogical  ', 11);
      9: print_string('xslogical  ', 11);
      10: print_string('xllogical  ', 11);
      11: print_string('xaddress   ', 11);
      12: print_string('nomore     ', 11);
      13: print_string('xdpcomplex ', 11);
      otherwise begin
        print_string('d_cls=', 6);
        print_integer(v^.fs_flags.d_cls, 4, true);
        print_char(' ');
      end;
    end;
    case v^.fs_attr.cls of
      0: print_string('xnone             ', 18);
      1: begin
        print_string('routine           ', 18);
        if v^.fs_attr.f3 then print_string('self ', 5);
        if v^.fs_attr.f2 then print_string('entry ', 6);
        if v^.fs_attr.f1 then print_string('external ', 9);
        if v^.fs_attr.f0 then print_string('has_been_declared_locally ', 26);
        if v^.fs_attr.f15 then print_string('has_been_defined ', 17);
        if v^.fs_attr.f14 then print_string('internal_subprogram ', 20);
      end;
      2: print_string('symbolic_constant ', 18);
      3: begin
        print_string('variable          ', 18);
        if v^.fs_attr.f3 then print_string('initialized ', 12);
        if v^.fs_attr.f2 then print_string('saved ', 6);
        if v^.fs_attr.f1 then print_string('by_value ', 9);
        if v^.fs_attr.f0 then print_string('naturally_aligned ', 18);
      end;
      4: print_string('alternate_return  ', 18);
      5: print_string('common            ', 18);
      6: begin
        print_string('xlabel            ', 18);
        if v^.fs_attr.f3 then print_string('used_lhs ', 9);
        if v^.fs_attr.f2 then print_string('used_rhs ', 9);
        if v^.fs_attr.f1 then print_string('abnormal ', 9);
        if v^.fs_attr.f0 then print_string('nlgoto ', 7);
        if v^.fs_attr.f15 then print_string('is_executable_label ', 20);
        if v^.fs_attr.f14 then print_string('is_assigned_goto_label ', 23);
        if v^.fs_attr.f13 then print_string('well_behaved_abnormal ', 22);
        if v^.fs_attr.f12 then begin
          print_string('is_format_label ', 16);
          print_string('fmt_const_ptr=', 14);
        end
        else begin
          print_string('lbl_root=', 9);
          print_tree_ref(v^.fs_lbl_root, false);
        end;
      end;
      7: print_string('namelist_groupname', 18);
      8: print_string('stmt_func         ', 18);
      otherwise
    end;
  end
  else
    case te.base^.kind of
      122: print_string('integer_type    ', 16);
      123: print_string('real_type       ', 16);
      124: print_string('bool_type       ', 16);
      125: print_string('char_type       ', 16);
      126: print_string('char_string_con_', 16);
      127: print_string('char_array_type ', 16);
      128: print_string('subr_type       ', 16);
      129: print_string('enum_type       ', 16);
      130: print_string('ptr_type        ', 16);
      131: print_string('array_type      ', 16);
      132: print_string('record_type     ', 16);
      133: print_string('file_type       ', 16);
      134: print_string('set_type        ', 16);
      135: print_string('univ_ptr_type   ', 16);
      136: print_string('null_set_type   ', 16);
      173: print_string('proc__type      ', 16);
      174: print_string('func__type      ', 16);
      177: print_string('offset_type     ', 16);
      196: print_string('varying_type    ', 16);
      197: print_string('parray_type     ', 16);
      206: print_string('dynamic_array_ty', 16);
      210: print_string('void_type       ', 16);
      217: print_string('char16_type     ', 16);
      218: print_string('char16_array_typ', 16);
      otherwise begin
        print_string('typ^.knd = ', 11);
        print_integer(te.base^.kind, 4, true);
        print_char(' ');
      end;
    end;
  if 0 in vn^.vr_attr then print_string('var_$volatile ', 14);
  if 1 in vn^.vr_attr then print_string('var_$atomic ', 12);
  if 2 in vn^.vr_attr then print_string('var_$physical ', 14);
  if 3 in vn^.vr_attr then print_string('var_$dev_read ', 14);
  if 4 in vn^.vr_attr then print_string('var_$dev_write ', 15);
  if 5 in vn^.vr_attr then print_string('var_$processor_reg ', 19);
  if 6 in vn^.vr_attr then print_string('var_$initialized ', 17);
  if 7 in vn^.vr_attr then print_string('var_$forloopindex ', 18);
  if 8 in vn^.vr_attr then print_string('var_$uplevel ', 13);
  if 9 in vn^.vr_attr then print_string('var_$loop_trip_count ', 21);
  if 10 in vn^.vr_attr then print_string('var_$is_formal_parameter ', 25);
  if 11 in vn^.vr_attr then print_string('var_$unique_value ', 18);
  if 12 in vn^.vr_attr then print_string('var_$address_exposed ', 21);
  if 13 in vn^.vr_attr then print_string('var_$passed_by_reference ', 25);
  if 14 in vn^.vr_attr then print_string('var_$temporary ', 15);
  if 15 in vn^.vr_attr then print_string('var_$register ', 14);
  if 16 in vn^.vr_attr then print_string('var_$bss ', 9);
  if 17 in vn^.vr_attr then print_string('var_$strength_reduction ', 24);
  if 18 in vn^.vr_attr then print_string('var_$allocated ', 15);
  if 19 in vn^.vr_attr then print_string('var_$already_seen_this_formal ', 30);
  if 20 in vn^.vr_attr then print_string('var_$induction ', 15);
  if 21 in vn^.vr_attr then print_string('var_$nooptimize ', 16);
  if 22 in vn^.vr_attr then print_string('var_$force_to_memory', 20);
  if 23 in vn^.vr_attr then print_string('var_$display_ptr ', 17);
  if 24 in vn^.vr_attr then print_string('var_$wasbound ', 14);
  if 25 in vn^.vr_attr then print_string('var_$isc_was_here ', 18);
  if 26 in vn^.vr_attr then print_string('var_$is_a_register_candidate ', 29);
  if 27 in vn^.vr_attr then print_string('var_$seen_in_ra ', 16);
  if 28 in vn^.vr_attr then print_string('var_$mentioned_in_sym_disp ', 27);
  if 29 in vn^.vr_attr then print_string('var_$spilled_to_memory ', 23);
  if 30 in vn^.vr_attr then print_string('var_$local_copy ', 16);
  if 31 in vn^.vr_attr then print_string('var_$withrecord ', 16);
  fresh_ln(n);
end;

{ print_exception_frame - a line for the exception frame f (222) at
  indent n: 'X' and its address; its owner, enclosing frame and depth,
  OTHERS handler and count, its explicit handlers (a chain of 223
  nodes through +72 while +70 is not 0) and the predefined exceptions
  it handles (+40, a set of 0..6: constraint_error, numeric_error,
  storage_error, predefined_4 ...).  Its result is the frame's +4 (the
  next frame), nil when f is not a frame.

  0x08227E, 0x218 bytes: the result kept in A3 and left in A0; the
  second parameter (12, the block) not read; the separator's flag in
  D0 (`st', `clr.b'); the predefined loop a `dbf' of 7 from 0 with
  the element tested `btst D2,D1' on the word (+40); 'predefined_' and
  the element + 1 (zero-extended) for those past 2. }

function print_exception_frame(
    f: lt_ptr_t;
    blk: univ_ptr;
    n: integer): lt_ptr_t; internal; options(val_param);
var
  next: lt_ptr_t;
  h: lt_ptr_t;
  first: boolean;
  i: 0..6;
begin
  fresh_ln(n);
  print_char('X');
  print_hex(integer32(f), 8);
  print_string(blanks, 2);
  if (f = nil) or (f^.kind <> 222) then begin
    next := nil;
    print_string('**not an exception frame**', 26);
  end
  else begin
    next := f^.xp[1];
    print_string('Exception Frame Owner:', 22);
    print_tree_ref(f^.xp[3], true);
    print_string(' Enclosing:', 11);
    print_tree_ref(f^.xp[4], true);
    print_string(' Enclosing Depth:', 17);
    print_integer(f^.xl[5], 10, false);
    print_string(' OTHERS:', 8);
    print_tree_ref(f^.xp[8], true);
    print_string(' Cnt:', 5);
    print_integer(f^.xl[6], 10, false);
    print_string(' EXPLICIT:(', 11);
    h := f^.xp[7];
    while h <> nil do begin
      print_tree_ref(h, true);
      if (h^.kind = 223) and (h^.xw[35] <> 0) then
        h := h^.xp[18]
      else begin
        print_string('<<Not an explicit handler**', 27);
        h := nil;
      end;
      if h <> nil then
        print_char(',');
    end;
    print_char(')');
    if f^.ef_predefined <> [] then begin
      print_string(' PREDEFINED:(', 13);
      first := true;
      for i := 0 to 6 do
        if i in f^.ef_predefined then begin
          if not first then
            print_char(',');
          case i of
            0: print_string('constraint_error', 16);
            1: print_string('numeric_error', 13);
            2: print_string('storage_error', 13);
            otherwise begin
              print_string('predefined_', 11);
              print_integer(i + 1, 10, false);
            end;
          end;
          first := false;
        end;
      print_char(')');
    end;
  end;
  fresh_ln(n);
  print_exception_frame := next;
end;

{ print_routine_block - the block b at indent n: its address, kind,
  name and line; with full, its alias name, temporaries' base and
  limit and stack size, first and last nodes, static level, the
  block's allocation and calling convention, its attributes, its
  variables (Fortran symbols and variables; with -TREE BCT the other
  symbols as well), exception frames, inner blocks (each in full, after
  'Inner blocks:') and the call graph's edges to its callees and from
  its callers.

  0x082560, 0xA30 bytes.  The block's kind a compare chain of 7
  labels; the allocation (+376 bits 8..7) and calling convention (+377
  bits 6..4) jump tables of 4 and 6; the attributes the bytes +374 to
  +379 bit by bit in the order printed.  -TREE BCT is
  cargs_$options.bct (`btst #4' of 0x2C3665, its address hoisted out of
  the loop).  A Fortran symbol's chain is +4, a variable's +16.  The
  call graph's edges (lt_edge_t) are chained through +32 from the
  callee list (+244) and +28 from the caller list (+252); 'Yucko --'
  when an edge's caller or callee is not b.  A callee that is a block
  (a set of 0..223 at 0x083156: 105..108, 172, 209) is printed by name
  with its entry, the caller's inner block, +20 ('TLN') and the call;
  another node as a reference.  'a0_ptr_ret ' (11 characters) is
  printed with length 12.

  Not known from the original: the attributes' field names (from the
  strings printed); the edge record's. }

procedure print_routine_block(
    b: lt_ptr_t;
    n: integer;
    full: boolean); internal; options(val_param);
var
  m: integer;
  v: lt_ptr_t;
  e: lt_edge_ptr_t;
begin
  fresh_ln(n);
  print_hex(integer32(b), 8);
  case b^.kind of
    105: print_string('  program_blk   ', 16);
    106: print_string('  module_blk    ', 16);
    107: print_string('  procedure_blk ', 16);
    108: print_string('  function_blk  ', 16);
    209: print_string('  blockdata_blk ', 16);
    167: print_string('  entry_blk     ', 16);
    172: print_string('  inner_blk     ', 16);
    otherwise
  end;
  print_string(b^.bk_name^.xc[18], b^.bk_name^.xw[8]);
  print_string('    line nr ', 12);
  print_integer(b^.xw[150], 5, true);
  fresh_ln(0);
  if not full then
    return;
  m := n + 4;
  fresh_ln(m);
  if b^.bk_alias <> nil then begin
    print_string('alias name: ', 12);
    print_string(b^.bk_alias^.xc[18], b^.bk_alias^.xw[8]);
    fresh_ln(m);
  end;
  print_string('-temp base = ', 13);
  print_hex(-b^.xl[20], 8);
  print_string('      -temp limit =  ', 21);
  print_hex(-b^.xl[21], 8);
  print_string('      -stack_size = ', 20);
  print_hex(-b^.xl[28], 8);
  fresh_ln(m);
  print_string('proc_start: ', 12);
  print_tree_ref(b^.xp[25], true);
  print_string('      blk_end_node: ', 20);
  print_tree_ref(b^.xp[26], true);
  print_string('      slevel = ', 15);
  print_integer(b^.xb[294], 3, false);
  fresh_ln(m);
  case rshft(b^.xw[188] & 16#180, 7) of
    0: print_string('local_bat   ', 12);
    1: print_string('forward_bat ', 12);
    2: print_string('extern_bat  ', 12);
    3: print_string('param_bat   ', 12);
    otherwise
  end;
  case rshft(ord(b^.xc[377]) & 16#70, 4) of
    0: print_string('call_unk   ', 11);
    1: print_string('call_pas   ', 11);
    2: print_string('call_ftn   ', 11);
    3: print_string('call_c     ', 11);
    4: print_string('call_c_std ', 11);
    5: print_string('call_ada   ', 11);
    otherwise
  end;
  print_string('    blk_atts: ', 14);
  if 3 in b^.bk_atts[376] then print_string('local_name_only ', 16);
  if 4 in b^.bk_atts[376] then print_string('save_db ', 8);
  if 5 in b^.bk_atts[376] then print_string('abnorm ', 7);
  if 6 in b^.bk_atts[376] then print_string('NLGoTo ', 7);
  if 7 in b^.bk_atts[376] then print_string('Need_FP_FCW ', 12);
  if 0 in b^.bk_atts[375] then print_string('NoSave_Regs ', 12);
  if 1 in b^.bk_atts[375] then print_string('NoReturn ', 9);
  if 2 in b^.bk_atts[375] then print_string('D0_Ptr_Ret ', 11);
  if 3 in b^.bk_atts[375] then print_string('use_db ', 7);
  if 4 in b^.bk_atts[375] then print_string('a0_ptr_ret ', 12);
  if 5 in b^.bk_atts[375] then print_string('inline ', 7);
  if 6 in b^.bk_atts[375] then print_string('noinline ', 9);
  if 7 in b^.bk_atts[375] then print_string('inlineable ', 11);
  if 0 in b^.bk_atts[374] then print_string('expanded ', 9);
  if 1 in b^.bk_atts[374] then print_string('inlined ', 8);
  if 2 in b^.bk_atts[374] then print_string('inline_block ', 13);
  if 3 in b^.bk_atts[374] then print_string('visible ', 8);
  if 4 in b^.bk_atts[374] then print_string('no_fp ', 6);
  if 5 in b^.bk_atts[374] then print_string('resident_proc ', 14);
  if 6 in b^.bk_atts[374] then print_string('addr_fparam ', 12);
  if 7 in b^.bk_atts[374] then print_string('assigned_goto ', 14);
  fresh_ln(m);
  if 3 in b^.bk_atts[377] then print_string('func_assign ', 12);
  if 2 in b^.bk_atts[377] then print_string('variable_arg_list ', 18);
  if 1 in b^.bk_atts[377] then print_string('val_param_flag ', 15);
  if 0 in b^.bk_atts[377] then print_string('fasn ', 5);
  if 7 in b^.bk_atts[378] then print_string('sb_display ', 11);
  if 6 in b^.bk_atts[378] then print_string('pass_display ', 13);
  if 5 in b^.bk_atts[378] then print_string('save_static_link_in_frame ', 26);
  if 4 in b^.bk_atts[378] then print_string('must_have_own_frame ', 20);
  if 3 in b^.bk_atts[378] then print_string('sb_12_in_use ', 13);
  if 1 in b^.bk_atts[378] then print_string('returns_dynamic_results ', 24);
  if 0 in b^.bk_atts[378] then print_string('respect_storage_error ', 22);
  if 7 in b^.bk_atts[379] then print_string('local_call_same_db ', 19);
  if 6 in b^.bk_atts[379] then print_string('local_call_different_db ', 24);
  if 5 in b^.bk_atts[379] then print_string('calls_extern_non_lib_routine ', 29);
  if 4 in b^.bk_atts[379] then print_string('never_entered_recursively ', 26);
  if 2 in b^.bk_atts[379] then print_string('coded ', 6);
  if 1 in b^.bk_atts[379] then print_string('visited_depth_first ', 20);
  if 0 in b^.bk_atts[379] then print_string('visited_set_local_call_bits ', 28);
  fresh_ln(m);
  v := b^.xp[4];
  while v <> nil do
    if (v^.kind = 110) or (v^.kind = 109) then begin
      if v^.kind = 110 then begin
        print_variable(v, b, n + 6);
        v := v^.xp[1];
      end
      else if v^.kind = 109 then begin
        print_variable(v, b, n + 6);
        v := v^.xp[4];
      end;
    end
    else begin
      if cargs_$options.bct then
        print_variable(v, b, n + 6);
      v := v^.xp[4];
    end;
  v := b^.xp[8];
  while v <> nil do
    v := print_exception_frame(v, b, n + 6);
  v := b^.xp[1];
  if (b^.kind <> 172) and (v <> nil) and (v^.kind = 172) then begin
    fresh_ln(m);
    print_string('Inner blocks:', 13);
    fresh_ln(0);
    while (v <> nil) and (v^.kind = 172) do begin
      fresh_ln(n + 6);
      print_routine_block(v, n + 6, false);
      v := v^.xp[1];
    end;
  end;
  e := b^.bk_callees;
  if e <> nil then begin
    fresh_ln(m);
    print_string('Call graph -- callees:', 22);
    while e <> nil do begin
      if e^.caller <> b then begin
        fresh_ln(n + 5);
        print_string('Yucko -- caller <> caller ', 26);
        print_hex(integer32(e^.caller), 8);
      end;
      fresh_ln(n + 6);
      print_hex(integer32(e), 8);
      print_string(blanks, 2);
      print_hex(integer32(e^.callee), 8);
      print_char(' ');
      if e^.callee = nil then
        print_string('NIL', 3)
      else if e^.callee^.kind in [105..108, 172, 209] then begin
        print_string(e^.callee^.bk_name^.xc[18], e^.callee^.bk_name^.xw[8]);
        print_string(blanks, 18 - e^.callee^.bk_name^.xw[8]);
        if (e^.entry <> nil) and (e^.entry <> e^.callee) then begin
          print_string('  entry ', 8);
          print_hex(integer32(e^.entry), 8);
          print_char(' ');
          print_string(e^.entry^.bk_name^.xc[18], e^.entry^.bk_name^.xw[8]);
        end;
        print_string('  caller_ib: ', 13);
        print_hex(integer32(e^.caller_ib), 8);
        print_string('  TLN: ', 7);
        print_hex(integer32(e^.tln), 8);
        print_string('  call: ', 8);
        print_hex(integer32(e^.call), 8);
      end
      else
        print_tree_ref(e^.callee, true);
      e := e^.next_callee;
    end;
  end;
  e := b^.bk_callers;
  if e <> nil then begin
    fresh_ln(m);
    print_string('Call graph -- callers:', 22);
    while e <> nil do begin
      if e^.callee <> b then begin
        fresh_ln(n + 5);
        print_string('Yucko -- callee <> callee ', 26);
        print_hex(integer32(e^.callee), 8);
      end;
      fresh_ln(n + 6);
      print_hex(integer32(e), 8);
      print_string(blanks, 2);
      print_hex(integer32(e^.caller), 8);
      print_char(' ');
      print_string(e^.caller^.bk_name^.xc[18], e^.caller^.bk_name^.xw[8]);
      print_string(blanks, 18 - e^.caller^.bk_name^.xw[8]);
      e := e^.next_caller;
    end;
  end;
  fresh_ln(0);
  print_ln(0);
end;

{ write_68k_register_name - register r as D0..D7, A0..A7 or FP0..FP7
  (r 0..23); 'notreg' for another.

  0x0833EA, 0x72 bytes: unsigned compares (`bhi', `bcs'); the digit
  added to the code as a byte. }

procedure write_68k_register_name(
    r: lt_word_t); internal; options(val_param);
begin
  if r <= 7 then
    print_2_chars('D', chr(r + 48))
  else if (r >= 8) and (r <= 15) then
    print_2_chars('A', chr(r + 40))
  else if (r >= 16) and (r <= 23) then
    print_3_chars('F', 'P', chr(r + 32))
  else
    print_string('notreg', 6);
end;

{ print_top_node - the top-level node (a statement) t at indent n: with
  the routine's variables' table, 'STMT_INDEX' and the variables the
  statement uses and defines; its flags; its reference, line, statement
  index, level and +12 ('xf') in brackets; then by kind: a label, a
  block's entry (the block in full, which becomes the current routine)
  and end, an assignment (its operator, descriptor, destination, source
  and length, their trees; a strength reduction temporary's variable),
  an evaluation, the branches, a return, a use-definition (188), a
  register list (191), exception handlers, raises and releases, the bit
  field stores, case nodes, a spine mark and an MMU operation; other
  nodes as PRTOBJ prints them.

  0x083462, 0x167E bytes.  The statement index is the 16 bits at +43
  (`andi.l #0xFFFF00' of the longword at +42, `lsr.l #8'); it is kept
  in the module's +0x126 for the 'STMT_INDEX' line, which needs the
  current routine (il_180, not an entry 167), il_11c and the variables'
  table (+22, entries pointing at a record whose +0 is the variable).
  The variables used are a set of 0..255 behind +34 (all 8 longwords
  tested with `dbne'; elements tested with a range check), printed by
  name: a Fortran symbol's (+70, +72) when the routine's calling
  convention (+377 bits 6..4) is 2, else the variable's identifier
  (+4).  The flags are the 16 bits at +41 (tested as bytes; any set: a
  line break after them).  The bracket's separator is kept in D2 ('['
  then ',').  The kinds' `case' is a compare chain in the labels'
  order; the label classes (+72 bits 5..1) a table of 22, the
  assignment operators (+76) of 38 (26 and 34 not labels: 'ORD(AOP)='),
  the register-list flags' names a table of 9, the MMU operations (+54)
  of 12.  The assignment's sign and overflow flags are printed for the
  operators of a set constant of 0..47 (0x084CA4) and of the longword
  0x05F84006 (`btst' after a range check against 31).  The assignment
  operators' uses: AGG 12, DIV_BY and the shifts 5, PACK and FIELD 9
  and 10 (shared tails, docs/rev889-patterns.md 23).  'SET OR TO' is
  printed with length 10 and 'SET DIFF' with 9 (the next literal's
  first character).  A register list's entries are 12 bytes from +52
  (lt_reg_t): its flags' STORE and STORET (mask 24) print the
  registers before the entity, BIND, LOAD, LOADT, INVALIDATE and COPY
  (mask 167) after it; flag 6 (REGPAIR) the second register.  The
  entity's node number: +16 of a CSE parent (190), else +10 of a tree
  or reference (a set of 0..159 at 0x084F04; the frame word -282 is
  not set for other kinds), else for an ADDR tree (137, operator 26)
  operand 1's +10.  The locals: the PRTSUB line at -264, the uses at
  -280 and -278, the node number at -282, n + 2 at -300.

  Not known from the original: the statement's fields' names (from the
  strings printed); the form of the 16-bit fields (written as the
  image's masks and shifts). }

procedure print_top_node(
    t: lt_ptr_t;
    n: integer); internal; options(val_param);
var
  s: prtsub_$line_t;
  u2: integer;
  u1: integer;
  num: 0..65535;
  printed: boolean;
  sep: char;
  i: integer32;
  j: 0..8;
  k: integer32;
  e: lt_ptr_t;
  r: lt_regs_ptr_t;
  m: integer;
begin
  fresh_ln(n);
  printed := false;
  if (t^.kind <> 191) and (rshft(t^.xl2[10] & 16#FFFF00, 8) <> 0) then
    w126 := rshft(t^.xl2[10] & 16#FFFF00, 8);
  if (il_180 <> nil) and (il_180^.kind <> 167) and (il_11c <> nil) and
      (t^.st_vars <> nil) and (rshft(t^.xl2[10] & 16#FFFF00, 8) <> 0) then begin
    print_string('STMT_INDEX ', 11);
    print_integer(w126, 5, true);
    print_char(' ');
    if (t^.st_used <> nil) and (t^.st_used^ <> []) and (t^.kind <> 191) then begin
      printed := true;
      print_string('Vars used : ', 12);
      for i := 1 to il_180^.xw[145] do
        if (t^.st_vars <> nil) and (t^.st_vars^[i] <> nil) and (i in t^.st_used^) then begin
          if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
            print_string(t^.st_vars^[i]^^.fs_name, t^.st_vars^[i]^^.fs_len)
          else
            print_string(t^.st_vars^[i]^^.vr_name^.xc[18], t^.st_vars^[i]^^.vr_name^.xw[8]);
          print_char(' ');
        end;
      fresh_ln(n);
    end;
    if (ord(t^.st_def) <> 0) and (t^.kind <> 191) then begin
      if printed then
        print_string('                Vars defined : ', 31)
      else
        print_string('Vars defined : ', 15);
      print_object_ptr(t^.st_vars^[ord(t^.st_def)]^, true);
      print_char(' ');
      fresh_ln(n);
    end;
  end;
  fresh_ln(n);
  if 0 in t^.xs[42] then print_string('begins_proc ', 12);
  if 1 in t^.xs[42] then print_string('begins_basic_block ', 19);
  if 2 in t^.xs[42] then print_string('ends_proc ', 10);
  if 3 in t^.xs[42] then print_string('ends_basic_block ', 17);
  if 5 in t^.xs[42] then print_string('contains_call_w_simple_p ', 25);
  if 4 in t^.xs[42] then print_string('contains_user_call ', 19);
  if 7 in t^.xs[42] then print_string('constant_assign ', 16);
  if 0 in t^.xs[41] then print_string('stmt_eliminated ', 16);
  if 1 in t^.xs[41] then print_string('contains_cse ', 13);
  if 2 in t^.xs[41] then print_string('defsubtracted ', 14);
  if 3 in t^.xs[41] then print_string('loophascalls ', 13);
  if 4 in t^.xs[41] then print_string('contains_fp_expr ', 17);
  if 5 in t^.xs[41] then print_string('compiler_generated_stmt ', 24);
  if 7 in t^.xs[41] then print_string('inliner_generated_stmt ', 23);
  if 6 in t^.xs[41] then print_string('pascal_for_loop ', 16);
  if rshft(t^.xl[10] & 16#FFFF00, 8) <> 0 then
    fresh_ln(n);
  print_tree_ref(t, true);
  print_string(': ', 2);
  sep := '[';
  if t^.st_ln <> 0 then begin
    print_char(sep);
    sep := ',';
    print_string('ln=', 3);
    print_integer(t^.st_ln, 5, false);
  end;
  if rshft(t^.xl2[10] & 16#FFFF00, 8) <> 0 then begin
    print_char(sep);
    sep := ',';
    print_string('stmt=', 5);
    print_integer(rshft(t^.xl2[10] & 16#FFFF00, 8), 5, false);
  end;
  if ord(t^.st_lvl) <> 0 then begin
    print_char(sep);
    sep := ',';
    print_string('lvl=', 4);
    print_integer(ord(t^.st_lvl), 10, false);
  end;
  if t^.st_xf <> nil then begin
    print_char(sep);
    sep := ',';
    print_string('xf=', 3);
    print_tree_ref(t^.st_xf, true);
  end;
  if sep = ',' then
    print_string('] ', 2);
  if t^.flags.rewritten then
    print_string('REWRITTEN ', 10);
  case t^.kind of
    144: begin
      case rshft(ord(t^.xc[72]) & 62, 1) of
        0: print_string('ELSE', 4);
        1: print_string('ENDIF', 5);
        2: print_string('WHILE START', 11);
        3: print_string('WHILE NEXT', 10);
        4: print_string('WHILE EXIT', 10);
        5: print_string('REPEAT START', 12);
        6: print_string('REPEAT NEXT', 11);
        7: print_string('REPEAT EXIT', 11);
        8: print_string('FOR START', 9);
        9: print_string('FOR NEXT', 8);
        10: print_string('FOR EXIT', 8);
        11: print_string('User', 4);
        12: print_string('RETURN', 6);
        13: print_string('PROC', 4);
        14: print_string('TEMP', 4);
        15: print_string('CASE STMT', 9);
        16: print_string('CASE ENDTE', 10);
        17: print_string('FACTOR', 6);
        18: print_string('PAR_REGION', 10);
        19: print_string('PAR_CRITICAL', 12);
        20: print_string('PAR_ORDERED', 11);
        21: print_string('PAR_ONE_PROC', 12);
        otherwise begin
          print_string('ord(class)', 10);
          print_char('=');
          print_integer(rshft(ord(t^.xc[72]) & 62, 1), 4, false);
        end;
      end;
      print_string(' LABEL(def=', 11);
      print_bool(7 in t^.xs[72]);
      print_string(',fwrd=', 6);
      print_bool(6 in t^.xs[72]);
      if 7 in t^.xs[74] then
        if 7 in t^.xs[77] then
          print_string(',abnormal(well_behaved)', 23)
        else
          print_string(',abnormal', 9);
      if 7 in t^.xs[75] then
        print_string(',NLGoTo', 7);
      if 7 in t^.xs[76] then
        print_string(',assigned_goto_target', 21);
      print_string(') serial=', 9);
      print_integer(t^.st_serial, 6, false);
      print_string(',addr=', 6);
      print_integer(t^.xl[14], 10, false);
    end;
    148: begin
      if not (t^.xp[12]^.kind in [167, 172]) then
        il_180 := il_$node_ptr_t(t^.xp[12]);
      print_string('BLOCK_ENTRY ', 12);
      print_tree_ref(t^.xp[12], true);
      fresh_ln(n);
      print_routine_block(t^.xp[12], n + 4, true);
    end;
    140: begin
      u1 := 0;
      u2 := 0;
      case t^.st_aop of
        0: print_string('SCALAR', 6);
        11: print_string('FP', 2);
        6: begin
          print_string('AGG', 3);
          u2 := 12;
        end;
        13: print_string('NOT TO', 6);
        14: print_string('NEG TO', 6);
        1: print_string('ADD TO', 6);
        2: print_string('SUB FROM', 8);
        3: print_string('AND TO', 6);
        4: print_string('OR TO', 5);
        5: print_string('EOR TO', 6);
        23: print_string('MUL TO', 6);
        24: begin print_string('DIV_BY', 6); u2 := 5; end;
        15: begin print_string('LSHFT TO', 8); u2 := 5; end;
        16: begin print_string('RSHFT TO', 8); u2 := 5; end;
        17: print_string('BSET TO', 7);
        18: print_string('BCLR TO', 7);
        19: print_string('F_ADD TO', 8);
        20: print_string('F_SUB FROM', 10);
        21: print_string('F_MUL TO', 8);
        22: print_string('F_DIV BY', 8);
        25: print_string('AGG_LEN', 7);
        31: print_string('ISC_AGG', 7);
        33: print_string('ISC_AGG_0', 9);
        32: print_string('ISC_SLICE', 9);
        7: print_string('SET AND TO', 10);
        8: print_string('SET OR TO', 10);
        9: print_string('SET DIFF', 9);
        27: print_string('STRCAT', 6);
        28: print_string('STRCPY', 6);
        29: print_string('STRNCAT', 7);
        30: print_string('STRNCPY', 7);
        10: begin print_string('PACK', 4); u1 := 9; u2 := 10; end;
        12: begin print_string('FIELD', 5); u1 := 9; u2 := 10; end;
        35: print_string('RANGE_CHECK_TO', 14);
        36: print_string('F_RANGE_CHECK_TO', 16);
        37: print_string('ILLEGAL', 7);
        otherwise begin
          print_string('ORD(AOP)=', 9);
          print_integer(t^.st_aop, 4, false);
        end;
      end;
      print_string(' ASSIGN', 7);
      s.length := 0;
      print_known_aux(s, t^.st_aux, u1, u2, t^.st_aop in [23..24, 35..36], (t^.st_aop <= 31) and (t^.st_aop in [1..2, 14, 19..24, 26]));
      print_string(s.body, s.length);
      print_char(' ');
      print_tree_ref(t^.st_dst, false);
      if t^.st_aop in [36, 35] then begin
        print_string(' IN ', 4);
        print_tree_ref(t^.st_src, false);
        print_string(' .. ', 4);
        print_tree_ref(t^.st_len, false);
      end
      else begin
        print_string(' := ', 4);
        print_tree_ref(t^.st_src, false);
        if t^.st_len <> nil then begin
          print_string(', LEN=', 6);
          print_tree_ref(t^.st_len, false);
        end;
      end;
      print_tree_exp(t^.st_dst, n + 2);
      print_tree_exp(t^.st_src, n + 2);
      if t^.st_len <> nil then
        print_tree_exp(t^.st_len, n + 2);
      if t^.st_aop = 0 then
        if il_utils_$is_strength_reduction_temp(il_$node_ptr_t(t^.st_dst)) then begin
          fresh_ln(2);
          print_string('Strength reduction temp:', 24);
          print_variable(t^.st_dst, il_180, 4);
          if t^.st_dst^.kind = 109 then
            print_tree_exp(lt_pp_t(t^.st_dst^.xp[13])^, 6)
          else
            print_tree_exp(lt_pp_t(t^.st_dst^.xp2[11])^, 6);
        end;
    end;
    139: begin
      print_string('EVAL ', 5);
      for i := 1 to t^.st_count do begin
        print_tree_ref(t^.xp[12 + i], false);
        if t^.st_count <> i then
          print_char(',');
      end;
      for i := 1 to t^.st_count do
        print_tree_exp(t^.xp[12 + i], n + 2);
    end;
    141: begin
      print_string('BRANCH ', 7);
      print_tree_ref(t^.xp[12], false);
    end;
    142: begin
      if 7 in t^.xs[60] then
        print_string('TBRANCH ', 8)
      else
        print_string('FBRANCH ', 8);
      print_tree_ref(t^.xp[12], false);
      print_char(',');
      print_tree_ref(t^.xp[14], false);
      print_tree_exp(t^.xp[14], n + 2);
    end;
    150: begin
      print_string('NLBRANCH ', 9);
      print_tree_ref(t^.xp[12], false);
      print_tree_exp(t^.xp[12], n + 2);
    end;
    151: begin
      print_string('RETURN ', 7);
      if t^.xp[12] <> nil then begin
        print_string('rlen=', 5);
        s.length := 0;
        print_rlen(s, t^.xw[26]);
        print_string(s.body, s.length);
        print_char(' ');
        print_tree_ref(t^.xp[12], false);
        print_tree_exp(t^.xp[12], n + 2);
      end;
    end;
    188: begin
      print_string('entity=', 7);
      print_object_ptr(t^.xp[12], true);
      print_string(', parmnum=', 10);
      print_integer(t^.xw[30], 10, false);
      if t^.xp[13] <> nil then begin
        print_string(', parent=', 9);
        print_tree_ref(t^.xp[13], false);
      end;
      if t^.xp[14] <> nil then begin
        print_string(', tree=', 7);
        print_string(',  ', 3);
        print_tree_ref(t^.xp[14], false);
      end;
    end;
    191: begin
      m := n + 2;
      r := addr(t^.xp[13]);
      for k := 1 to t^.xw[25] do begin
        fresh_ln(m);
        for j := 0 to 8 do
          if j in r^[k].flags then
            case j of
              0: print_string('BIND ', 5);
              1: print_string('LOAD ', 5);
              2: print_string('LOADT ', 6);
              3: print_string('STORE ', 6);
              4: print_string('STORET ', 7);
              5: print_string('INVALIDATE ', 11);
              6: print_string('REGPAIR ', 8);
              7: print_string('COPY ', 5);
              8: print_string('DESTROY ', 8);
            end;
        if (r^[k].flags * [3, 4]) <> [] then begin
          write_68k_register_name(r^[k].reg1);
          if 6 in r^[k].flags then begin
            print_char(' ');
            write_68k_register_name(r^[k].reg2);
          end;
          print_char(',');
        end;
        e := r^[k].entity;
        if e <> nil then
          if (e^.kind = 110) or (e^.kind = 109) then begin
            if e^.kind = 109 then
              for i := 1 to e^.vr_name^.xw[8] do
                print_char(e^.vr_name^.xc[17 + i])
            else
              for i := 1 to e^.fs_len do
                print_char(e^.fs_name[i]);
          end
          else if (e <> nil) and (e^.kind in [137..138, 143, 145..147, 190]) then begin
            if e^.kind in [138, 137] then
              print_string('addr over ', 10);
            print_string('Node', 4);
            if e^.kind = 190 then
              num := e^.xw[8]
            else if e^.kind in [137..138, 143, 145..147] then
              num := e^.cse_parent;
            if (num = 0) and (e^.kind = 137) and (e^.op = 26) then
              num := e^.opnd[1]^.cse_parent;
            print_integer(num, 5, false);
          end
          else if (e <> nil) and (e^.kind in [88, 89, 195, 163]) then
            print_object_ptr(e, true);
        if (r^[k].flags * [0..2, 5, 7]) <> [] then begin
          print_char(',');
          write_68k_register_name(r^[k].reg1);
          if 6 in r^[k].flags then begin
            print_char(' ');
            write_68k_register_name(r^[k].reg2);
          end;
        end;
      end;
    end;
    149: begin
      print_string('BLOCK_END ', 10);
      print_tree_ref(t^.xp[12], false);
      if t^.xp[12]^.kind <> 172 then
        il_180 := nil;
    end;
    223: begin
      if t^.xw[35] = 0 then
        print_string('OTHERS ', 7)
      else
        print_string('EXPLICIT ', 9);
      print_string('HANDLER_ENTRY exc_frm=', 22);
      print_tree_ref(t^.xp[12], true);
      if t^.xw[35] <> 0 then begin
        print_string(' exc=(', 6);
        for i := 1 to t^.hd_count do begin
          print_tree_ref(t^.xp[18 + i], true);
          if t^.hd_count <> i then
            print_char(',');
        end;
        print_char(')');
      end;
    end;
    224: begin
      print_string('RAISE_EXCEPTION ', 16);
      print_tree_ref(t^.xp[12], false);
      print_string(' exc_var=', 9);
      print_tree_ref(t^.xp[13], false);
      print_tree_exp(t^.xp[12], n + 2);
    end;
    225: begin
      print_string('RELEASE_DYNAMIC_SPACE ', 22);
      print_tree_ref(t^.xp[12], false);
      print_tree_exp(t^.xp[12], n + 2);
    end;
    227: begin
      print_string('INSERT_BIT_FIELD ', 17);
      s.length := 0;
      print_known_aux(s, t^.st_aux, 18, 18, false, false);
      print_string(s.body, s.length);
      print_char(' ');
      print_tree_ref(t^.xp[16], false);
      print_string(' + bit_offset( ', 15);
      print_tree_ref(t^.xp[17], false);
      print_string(' ) := ', 6);
      print_tree_ref(t^.xp[18], false);
      print_string(', bit_size= ', 12);
      print_integer(t^.xl[19], 10, false);
      print_tree_exp(t^.xp[16], n + 2);
      print_tree_exp(t^.xp[17], n + 2);
      print_tree_exp(t^.xp[18], n + 2);
    end;
    228: begin
      print_string('BIT_FIELD_ASSIGN ', 17);
      print_tree_ref(t^.xp[12], false);
      print_string(' + bit_offset( ', 15);
      print_tree_ref(t^.xp[13], false);
      print_string(' ) := ', 6);
      print_tree_ref(t^.xp[14], false);
      print_string(' + bit_offset( ', 15);
      print_tree_ref(t^.xp[15], false);
      print_string(' ), bit_size= ', 14);
      print_tree_ref(t^.xp[16], false);
      print_tree_exp(t^.xp[12], n + 2);
      print_tree_exp(t^.xp[13], n + 2);
      print_tree_exp(t^.xp[14], n + 2);
      print_tree_exp(t^.xp[15], n + 2);
      print_tree_exp(t^.xp[16], n + 2);
    end;
    215, 214: begin
      if t^.kind = 214 then
        print_string('CASE_NODE_RANGE_CHECK ', 22)
      else
        print_string('CASE_NODE_NO_RANGE_CHECK ', 25);
      print_string('table_disp( ', 12);
      print_tree_ref(t^.xp[12], false);
      print_string(' )', 2);
      if t^.kind = 214 then begin
        print_string(' table( ', 8);
        print_tree_ref(t^.xp[14], false);
        print_string(' ) range_check_code( ', 21);
        print_tree_ref(t^.xp[15], false);
        print_string(' ) out_of_range_target( ', 24);
        print_tree_ref(t^.xp[16], false);
        print_string(' )', 2);
      end;
      print_tree_exp(t^.xp[12], n + 2);
      if t^.kind = 214 then
        print_tree_exp(t^.xp[14], n + 2);
    end;
    231: begin
      print_string('SPINE_MARK ', 11);
      print_string(' next= ', 7);
      print_tree_ref(t^.xp[12], false);
      print_string(' prev= ', 7);
      print_tree_ref(t^.xp[13], false);
    end;
    233: begin
      print_string('PA_MMU_BIP', 10);
      case t^.xw[27] of
        0: print_string('(flush_dc_va) ', 14);
        1: print_string('(flush_dc_entry) ', 17);
        2: print_string('(purge_dc_va) ', 14);
        3: print_string('(purge_dc_entry) ', 17);
        4: print_string('(purge_dtlb_va) ', 16);
        5: print_string('(purge_dtlb_entry) ', 19);
        6: print_string('(flush_ic_va) ', 14);
        7: print_string('(flush_ic_entry) ', 17);
        8: print_string('(purge_ic_va) ', 14);
        9: print_string('(purge_ic_entry) ', 17);
        10: print_string('(purge_itlb_va) ', 16);
        11: print_string('(purge_itlb_entry) ', 19);
        otherwise
      end;
      print_string('sreg= ', 6);
      print_integer(t^.mm_sreg, 2, false);
      print_string('  ', 2);
      print_tree_ref(t^.xp[12], false);
      print_tree_exp(t^.xp[12], n + 2);
    end;
    otherwise
      print_object_ptr(t, true);
  end;
  fresh_ln(n);
end;

{ print_spine - the statements of the spine from t (chained through +8)
  at indent n, then a fresh line at 0.

  0x0851C4, 0x36 bytes. }

procedure print_spine;
var
  p: lt_ptr_t;
begin
  p := t;
  while p <> nil do begin
    print_top_node(p, n);
    p := p^.xp[2];
  end;
  fresh_ln(0);
end;

{ print_data_node - a Fortran data initialization node d at indent n:
  a name list (113: with x its variable offset and length, else its
  initial value, whose constant list is printed node by node), a
  default sequence (221), an implied DO (166: its controls' trees and
  its body's nodes, chained through +4 back to d) or a constant list
  (114); other nodes as PRTOBJ prints them.

  0x0851FA, 0x310 bytes: the kinds a compare chain in the labels'
  order; a name list's and a default sequence's constant lists (114)
  share one loop (0x0853D4, the first node printed unconditionally).
  ', var_offse' is printed with length 11 (cut). }

procedure print_data_node(
    d: lt_ptr_t;
    n: integer;
    x: boolean); internal; options(val_param);
var
  p: lt_ptr_t;
begin
  fresh_ln(n);
  print_tree_ref(d, true);
  print_char(':');
  case d^.kind of
    113: begin
      print_string('FDATA_NLIST ', 12);
      print_object_ptr(d^.xp[2], true);
      print_string(', const_offset=', 15);
      print_integer(d^.xl[3], 10, false);
      if x then begin
        print_string(', var_offse', 11);
        print_tree_ref(d^.xp[4], false);
        print_string(', length=', 9);
        print_integer(d^.xw[10], 5, false);
        if d^.xp[4] <> nil then
          print_tree_exp(d^.xp[4], n + 2);
      end
      else begin
        print_string(', initial_value=', 16);
        print_tree_ref(d^.xp[4], false);
        print_string(', size=', 7);
        print_integer(d^.xl[5], 10, false);
        if d^.xp[4] <> nil then
          if d^.xp[4]^.kind = 114 then begin
            p := d^.xp[4];
            repeat
              print_data_node(p, n + 2, false);
              p := p^.xp[1];
            until p = nil;
          end
          else
            print_tree_exp(d^.xp[4], n + 2);
      end;
    end;
    221: begin
      print_string('FDATA_DEFAULT_SEQ ', 18);
      print_object_ptr(d^.xp[2], true);
      print_char(',');
      print_integer(d^.xl[3], 10, false);
      print_string('->', 2);
      print_integer(d^.xl[6], 10, false);
      print_char(',');
      print_tree_ref(d^.xp[4], false);
      print_char(',');
      print_integer(d^.xl[5], 10, false);
      if d^.xp[4]^.kind = 114 then begin
        p := d^.xp[4];
        repeat
          print_data_node(p, n + 2, false);
          p := p^.xp[1];
        until p = nil;
      end
      else
        print_tree_exp(d^.xp[4], n + 2);
    end;
    166: begin
      print_string('FDATA_DO ', 9);
      print_object_ptr(d^.xp[4], true);
      print_string('= initial:', 10);
      print_tree_ref(d^.xp[8], false);
      print_string(', final:', 8);
      print_tree_ref(d^.xp[10], false);
      print_string(', inc:', 6);
      print_tree_ref(d^.xp[9], false);
      print_tree_exp(d^.xp[8], n + 2);
      print_tree_exp(d^.xp[10], n + 2);
      print_tree_exp(d^.xp[9], n + 2);
      p := d^.xp[2];
      while p <> d do begin
        print_data_node(p, n + 2, true);
        p := p^.xp[1];
      end;
    end;
    114: begin
      print_string('FDATA_CLIST repeat_count:', 25);
      print_integer(d^.xl[3], 10, false);
      print_string(' constant:', 10);
      print_object_ptr(d^.xp[2], true);
    end;
    otherwise
      print_object_ptr(d, true);
  end;
  fresh_ln(n);
end;

{ begins_inline_block - whether the label p begins an inlined block: the
  statements after it, past block entries and register lists, reach a
  block entry (148) whose block is an inner block (172) with the
  attribute inline_block (+374 bit 2).

  0x0855B0, 0x66 bytes: loads A5 (not internal; no other unit calls
  it); p by address (`pea' of the caller's slot or frame temporary). }

function begins_inline_block(
    in p: lt_ptr_t): boolean;
var
  q: lt_ptr_t;
begin
  begins_inline_block := false;
  q := p;
  if (q <> nil) and (q^.kind = 144) then begin
    q := q^.xp[2];
    while (q <> nil) and ((q^.kind = 148) or (q^.kind = 191)) do begin
      if q^.kind = 148 then begin
        if (q^.xp[12]^.kind = 172) and (2 in q^.xp[12]^.bk_atts[374]) then
          begins_inline_block := true;
        return;
      end;
      q := q^.xp[2];
    end;
  end;
end;

{ advance_and_print - the statement t on the listing: outside inlined
  blocks the listing is first advanced to its line when that is not
  before line (and line becomes it); the inline depth counts the
  inlined blocks entered and left.

  0x085616, 0x7E bytes: t by value; line by address (the callers keep
  it in D2 and pass a frame temporary, reloading D2 after the call). }

procedure advance_and_print(
    t: lt_ptr_t;
    var line: integer32); internal; options(val_param);
begin
  if begins_inline_block(t) then
    inline_depth := inline_depth + 1;
  if inline_depth = 0 then
    if t^.st_ln >= line then begin
      line := t^.st_ln;
      advance_listing_to_line(t^.st_ln);
    end;
  if (t^.kind = 149) and (t^.xp[12]^.kind = 172) and (2 in t^.xp[12]^.bk_atts[374]) then
    inline_depth := inline_depth - 1;
  print_top_node(t, 0);
  print_ln(0);
end;

{ print_basic_block - the heading of basic block b (number n): its
  dominator, registers saved, loop depth and index, kind, preheader,
  predecessors and successors (by number, +82) and the register
  assignments made at it (a 178 node: per register 0..23 the node and
  its size's letters).

  0x085694, 0x384 bytes: n (8) a word, b (10); the predecessors are
  inline from +116 (count +114), the successors behind +108 (count
  +106); the size letters the module's table (+0x130, by +8 of the
  assignment's entry); the node number as print_top_node's register
  list prints it (a CSE use, 189, from +10 through a frame word, -8). }

procedure print_basic_block(
    n: integer;
    b: lt_bb_ptr_t); internal; options(val_param);
var
  w: 0..65535;
  i: integer;
  r: integer;
  x: lt_ptr_t;
  num: 0..65535;
begin
  fresh_ln(0);
  print_ln(0);
  print_string('BLOCK:', 6);
  print_integer(n, 4, true);
  print_string(' DOM:', 5);
  if b^.dom <> nil then
    print_integer(b^.dom^.num, 4, true)
  else
    print_integer(0, 4, true);
  print_string(' Reg Save:', 10);
  print_hex(b^.reg_save, 6);
  print_string(' Loop Depth:', 12);
  print_integer(b^.depth, 2, true);
  print_string(' Loop Index:', 12);
  if b^.index <> nil then
    print_integer(b^.index^.num, 4, true)
  else
    print_integer(0, 4, true);
  if 2 in b^.flags then print_string(' Preheader', 10);
  if 1 in b^.flags then print_string(' Loop Head ', 11);
  if 0 in b^.flags then print_string(' Abnormal ', 10);
  if 7 in b^.flags then print_string(' CLEANUP  ', 10);
  fresh_ln(0);
  if 1 in b^.flags then begin
    print_string(' PreHeader ', 11);
    if b^.preheader <> nil then
      print_integer(b^.preheader^.num, 4, true)
    else
      print_integer(0, 4, true);
    fresh_ln(0);
  end;
  if b^.npred > 0 then begin
    print_string(' Predecessors:', 14);
    for i := 1 to b^.npred do begin
      print_char(' ');
      print_integer(b^.pred[i]^.num, 4, true);
    end;
    fresh_ln(0);
  end;
  if b^.nsucc > 0 then begin
    print_string(' Successors:  ', 14);
    for i := 1 to b^.nsucc do begin
      print_char(' ');
      print_integer(b^.succ^[i]^.num, 4, true);
    end;
    fresh_ln(0);
  end;
  if (b^.regs <> nil) and (b^.regs^.kind = 178) then begin
    print_string(' Register Assignments: ', 23);
    fresh_ln(0);
    for r := 0 to 23 do
      if b^.regs^.ra[r].node <> nil then begin
        print_string(blanks, 4);
        write_68k_register_name(r);
        print_string(':  ', 3);
        print_string(size_letters[b^.regs^.ra[r].size], 2);
        x := b^.regs^.ra[r].node;
        if x^.kind in [137..138, 143, 145..147] then begin
          num := x^.cse_parent;
          if (num = 0) and (x^.kind = 137) and (x^.op = 26) then
            num := x^.opnd[1]^.cse_parent;
          print_string('Node', 4);
          print_integer(num, 5, true);
        end
        else if x^.kind = 189 then begin
          w := x^.cse_parent;
          print_string('Node', 4);
          print_integer(w, 5, true);
        end
        else
          print_object_ptr(x, true);
        fresh_ln(0);
      end;
    print_ln(0);
  end;
end;

{ LIST_TREE_$PRINT_WHOLE_IL - the whole IL to the listing (-TREE): the
  top-level nodes from il_d4, routine by routine (each label 144 with
  its block entry) and basic block by basic block (il_11c's il_124
  blocks, each from its first statement +84 to its last +88 after its
  heading), the listing advanced to each statement's line; then any
  statements left, and the data initializations of il_110's and
  il_118's chains.  The current routine (il_180) is saved and
  restored.

  0x085ABA, 0x220 bytes: initialise_list_tree(addr(listln)) (`move.l
  #0x0B5F42'); the line in D2 (0 also standing for nil); unless the
  CPU set has element 6 (cc.a88k's, `btst #0,0x2C3670'), the block's
  basic blocks (+164, count +274) and node table (+168, count +272)
  are made IL's (il_11c, il_124, il_120, il_126).  The first loop's
  bottom test is t (its top test il_11c).

  Not known from the original: the loops' form (gotos out of the
  inner loops are written). }

procedure list_tree_$print_whole_il;
label
  1, 2;
var
  saved: il_$node_ptr_t;
  line: integer32;
  t: lt_ptr_t;
  b: lt_ptr_t;
  i: integer;
  p: lt_ptr_t;
  d: lt_ptr_t;
begin
  initialise_list_tree(addr(listln));
  saved := il_180;
  line := 0;
  if (il_d4 <> nil) and (lt_ptr_t(il_d4)^.xp[2] <> nil) then
    il_180 := il_$node_ptr_t(lt_ptr_t(il_d4)^.xp[2]^.xp[12])
  else
    il_180 := nil;
  t := lt_ptr_t(il_d4);
  if (t <> nil) and (t^.kind = 144) then
    while (t <> nil) and (il_11c <> nil) do begin
      if not (6 in cargs_$options.cpu) then begin
        b := t^.xp[2]^.xp[12];
        if b^.xp[41] <> nil then begin
          il_11c := b^.xp[41];
          il_124 := b^.xw[137];
        end;
        if b^.xp[42] <> nil then begin
          il_120 := b^.xp[42];
          il_126 := b^.xw[136];
        end;
      end;
      for i := 1 to il_124 do
        if lt_bbs_ptr_t(il_11c)^[i] <> nil then begin
          while lt_bbs_ptr_t(il_11c)^[i]^.first <> t do begin
            if t = nil then
              goto 1;
            advance_and_print(t, line);
            if t^.xp[2] = nil then
              goto 1;
            t := t^.xp[2];
          end;
        1:
          if t <> nil then begin
            if inline_depth = 0 then
              if not begins_inline_block(t) then
                if t^.st_ln >= line then begin
                  line := t^.st_ln;
                  advance_listing_to_line(t^.st_ln);
                end;
            print_basic_block(i, lt_bbs_ptr_t(il_11c)^[i]);
            repeat
              advance_and_print(t, line);
              if lt_bbs_ptr_t(il_11c)^[i]^.last = t then
                goto 2;
              if t^.xp[2] = nil then
                goto 2;
              t := t^.xp[2];
            until false;
          2:
            t := t^.xp[2];
          end;
        end;
    end;
  while t <> nil do begin
    advance_and_print(t, line);
    t := t^.xp[2];
  end;
  p := lt_ptr_t(il_110);
  while p <> nil do begin
    d := p^.xp[7];
    while d <> nil do begin
      print_data_node(d, 0, false);
      d := d^.xp[1];
    end;
    p := p^.xp[1];
  end;
  p := lt_ptr_t(il_118);
  while p <> nil do begin
    d := p^.xp[9];
    while d <> nil do begin
      print_data_node(d, 0, false);
      d := d^.xp[1];
    end;
    p := p^.xp[2];
  end;
  fresh_ln(0);
  il_180 := saved;
  finialise_list_tree;
end;

{ LIST_TREE_$PRINT_TREE - the tree under t, its lines through emit (nil:
  diag_$writeln): a statement (a set of 0..239 at 0x085D8E) as
  print_top_node prints it, a data initialization as print_data_node
  (with x), anything else as its reference and its tree at indent 2.

  0x085CDA, 0xB4 bytes: the pad of initialise_list_tree's argument
  area left for fresh_ln's (docs/rev889-patterns.md 51). }

procedure list_tree_$print_tree(
    t: il_$node_ptr_t;
    emit: univ_ptr);
begin
  initialise_list_tree(emit);
  fresh_ln(0);
  if t = nil then
    print_object_ptr(t, true)
  else if t^.kind in [139..142, 144, 148..151, 188, 191, 214..215, 223..225, 227..228, 231, 233] then
    print_top_node(lt_ptr_t(t), 0)
  else if t^.kind in [113, 114, 221, 166] then
    print_data_node(lt_ptr_t(t), 0, true)
  else begin
    print_tree_ref(lt_ptr_t(t), true);
    print_tree_exp(lt_ptr_t(t), 2);
  end;
  fresh_ln(0);
  finialise_list_tree;
end;

{ LIST_TREE_$SANITY_CHECK - check the IL's use counts and top-level
  links three times over (mode -1 clears each tree's count of uses, 0
  counts them, 1 compares them with the use counts and marks the trees
  visited); report inconsistencies (at most countdown's three) by
  vfmt_$write and on the listing, naming the check by name (len
  characters).

  0x0865E8, 0x68 bytes: loads A5; the parameters are read only by the
  nested routines (through the frame passed in A1:
  docs/rev889-patterns.md 44, 26); the modes in D3 (-1..1, a `dbf' of
  3); il_180 set from il_184 before each walk of il_d4's spine and
  restored at the end; no call sites in the binaries.

  Not known from the original: the parameters' names and types (a
  name by address and its length, as the messages' %15A take them). }

procedure list_tree_$sanity_check(
    in name: univ prtsub_$chars_t;
    len: integer32); options(val_param);
var
  saved: il_$node_ptr_t;
  mode: integer32;

  { sanity_check_countdown - whether another inconsistency is reported
    (three are): the routine's name, t's node number and statement
    index (when it has them) and address by vfmt_$write; after the
    third 'More insanity, but I''ll shut up for now.'.

    0x085DAC, 0xFA bytes: countdown (+0x11C) decremented; the kinds
    with a node number a set of 0..207 (0x085EE6) with a range check;
    the statement index the 16 bits at +43 of the statement (+12 of a
    tree, or the node itself when it is a statement: the set at
    0x085D8E), sign-extended (`lsl.l #8; swap; ext.l'); the values by
    address in frame temporaries. }

  function sanity_check_countdown(
      t: lt_ptr_t): boolean; options(val_param);
  var
    v: integer32;
    x: integer32;
  begin
    countdown := countdown - 1;
    if countdown <= 0 then begin
      if countdown = 0 then
        vfmt_$write('More insanity, but I''ll shut up for now.%.');
      sanity_check_countdown := false;
      return;
    end;
    v := il_180^.xp[74]^.xw[8];
    vfmt_$write('Routine: %A%$', il_180^.xp[74]^.xc[18], v);
    if (t^.kind in [137..138, 143, 145..147, 164, 171, 175, 189, 205]) and (t^.cse_parent <> 0) then begin
      v := t^.cse_parent;
      vfmt_$write('    Node Number: %8LD%$', v);
    end;
    if (t^.kind in [137..138, 143, 145..147, 164, 171, 175, 189, 205]) and (t^.xp[3] <> nil) then begin
      x := t^.xp[3]^.xl2[10];
      v := rshft(lshft(x, 8), 16);
      if v > 32767 then
        v := v - 65536;
      vfmt_$write('    STMT INDEX: %8LD%$', v);
    end
    else if t^.kind in [139..142, 144, 148..151, 188, 191, 214..215, 223..225, 227..228, 231, 233] then begin
      x := t^.xl2[10];
      v := rshft(lshft(x, 8), 16);
      if v > 32767 then
        v := v - 65536;
      vfmt_$write('    STMT INDEX: %8LD%$', v);
    end;
    vfmt_$write('    node address: 0x%8ZLH%.', t);
    sanity_check_countdown := true;
  end;

  { sanity_check_bad_uc - report t's use count is (should be should) by
    vfmt_$write and on the listing, with t's tree.

    0x085F42, 0xBC bytes: the parent's frame in A1 (its name (8) and
    len (12), the low word for print_string); is and should by
    address. }

  procedure sanity_check_bad_uc(
      t: lt_ptr_t;
      is: integer32;
      should: integer32); options(val_param);
  begin
    if sanity_check_countdown(t) then begin
      vfmt_$write('sanity_check( %15A ):  INCONSISTENT UC:  is %3d should be %3d%.', name, len, is, should);
      fresh_ln(0);
      print_string('sanity check( ', 14);
      print_string(name, len);
      print_string(' ):  INCONSISTENT UC:  is ', 26);
      print_integer(is, 3, true);
      print_string(' should be ', 11);
      print_integer(should, 3, true);
      fresh_ln(0);
      print_tree_exp(t, 4);
      fresh_ln(0);
    end;
  end;

  procedure sanity_check_walk_spine(mode: integer32; t: lt_ptr_t); options(val_param); forward;

  { sanity_check_walk - one pass over the tree t: mode -1 clears the
    count of uses (+18), 0 counts this use, 1 compares a count not yet
    marked (not negative) with the use count (+16); the operands are
    walked (in modes 0 and 1 only at a tree's first use), a call's
    spine operands as spines; in mode 1 the tree is then marked (-1).
    A DINDEX with a displacement is reported.

    0x086072, 0x27A bytes: the kinds a compare chain; the count's
    check repeated in each arm (trees, references, 164) and the mark
    one tail (0x0862BE); the calls (171, 175), CSE nodes and ISC nodes
    walk their operand and return. }

  procedure sanity_check_walk(
      mode: integer32;
      t: lt_ptr_t); options(val_param);
  var
    i: integer32;
  begin
    if t = nil then
      return;
    case t^.kind of
      143, 138, 137: begin
        if mode < 0 then
          t^.w18 := 0
        else if mode = 0 then
          t^.w18 := t^.w18 + 1
        else if (t^.w18 >= 0) and (t^.w18 <> t^.uses) then
          sanity_check_bad_uc(t, t^.uses, t^.w18);
        if (mode <> 0) or (t^.w18 = 1) then
          for i := 1 to t^.count do
            if il_utils_$tree_node_operand_is_spine(t^.op, i) then
              sanity_check_walk_spine(mode, t^.opnd[i])
            else
              sanity_check_walk(mode, t^.opnd[i]);
        if mode > 0 then
          t^.w18 := -1;
      end;
      145, 205, 147, 146: begin
        if mode < 0 then
          t^.rf_w18 := 0
        else if mode = 0 then
          t^.rf_w18 := t^.rf_w18 + 1
        else if (t^.rf_w18 >= 0) and (t^.rf_w18 <> t^.rf_uses) then
          sanity_check_bad_uc(t, t^.rf_uses, t^.rf_w18);
        sanity_check_walk(mode, t^.base);
        if t^.kind = 145 then begin
          sanity_check_walk(mode, t^.index);
          if t^.disp <> 0 then begin
            vfmt_$write('sanity_check( %15A ):  DINDEX_NODE has non-0 .DISP%.', name, len);
            fresh_ln(0);
            print_string('sanity check( ', 14);
            print_string(name, len);
            print_string(' ):  DINDEX_NODE has non-0 .DISP', 32);
            fresh_ln(0);
          end;
        end;
        if mode > 0 then
          t^.rf_w18 := -1;
      end;
      171, 175:
        sanity_check_walk(mode, t^.xp[4]);
      164: begin
        if mode < 0 then
          t^.w18 := 0
        else if mode = 0 then
          t^.w18 := t^.w18 + 1
        else if (t^.w18 >= 0) and (t^.w18 <> t^.uses) then
          sanity_check_bad_uc(t, t^.uses, t^.w18);
        if (mode <> 0) or (t^.w18 = 1) then begin
          sanity_check_walk(mode, t^.xp[5]);
          sanity_check_walk(mode, t^.xp[6]);
        end;
        if mode > 0 then
          t^.w18 := -1;
      end;
      190:
        sanity_check_walk(mode, t^.xp[1]);
      189:
        sanity_check_walk(mode, t^.xp[5]);
      232, 220, 219:
        sanity_check_walk(mode, t^.xp[1]);
      otherwise
    end;
  end;

  { sanity_check_walk_spine - one pass over the statements from t: in
    mode 1 a statement whose successor's back link (+8, +4) is not it
    is reported; each statement's trees are walked.

    0x086340, 0x250 bytes: the kinds a compare chain (the statements
    without trees first, an empty arm); for a block entry (148) the
    image tests the entry's own kind for 108 or 107 (never true) before
    making it the current routine; an evaluation's count (+50)
    sign-extended here. }

  procedure sanity_check_walk_spine;
  var
    p: lt_ptr_t;
    i: integer;
  begin
    p := t;
    while p <> nil do begin
      if (p^.xp[2] <> nil) and (p^.xp[2]^.xp[1] <> p) and (mode > 0) then
        if sanity_check_countdown(p^.xp[2]) then begin
          vfmt_$write('sanity_check( %15A ):  BAD link.lastp TOP LEVEL LINK%.', name, len);
          fresh_ln(0);
          print_string('sanity check( ', 14);
          print_string(name, len);
          print_string(' ):  BAD TOP LEVEL link.lastp LINK', 34);
          print_tree_ref(p^.xp[2], true);
          fresh_ln(0);
        end;
      case p^.kind of
        233, 231, 223, 149, 191, 188, 150, 141, 144: ;
        148:
          if (p^.kind = 108) or (p^.kind = 107) then
            il_180 := il_$node_ptr_t(p);
        140: begin
          sanity_check_walk(mode, p^.st_dst);
          sanity_check_walk(mode, p^.st_src);
          sanity_check_walk(mode, p^.st_len);
        end;
        139:
          for i := 1 to p^.xw[25] do
            sanity_check_walk(mode, p^.xp[12 + i]);
        142: begin
          sanity_check_walk(mode, p^.xp[12]);
          sanity_check_walk(mode, p^.xp[14]);
        end;
        151: sanity_check_walk(mode, p^.xp[12]);
        224: sanity_check_walk(mode, p^.xp[12]);
        225: sanity_check_walk(mode, p^.xp[12]);
        227: begin
          sanity_check_walk(mode, p^.xp[16]);
          sanity_check_walk(mode, p^.xp[17]);
          sanity_check_walk(mode, p^.xp[18]);
        end;
        228: begin
          sanity_check_walk(mode, p^.xp[12]);
          sanity_check_walk(mode, p^.xp[13]);
          sanity_check_walk(mode, p^.xp[14]);
          sanity_check_walk(mode, p^.xp[15]);
          sanity_check_walk(mode, p^.xp[16]);
        end;
        215, 214: sanity_check_walk(mode, p^.xp[12]);
        otherwise
      end;
      p := p^.xp[2];
    end;
  end;

begin
  initialise_list_tree(addr(listln));
  saved := il_180;
  for mode := -1 to 1 do begin
    il_180 := il_184;
    sanity_check_walk_spine(mode, lt_ptr_t(il_d4));
  end;
  il_180 := saved;
  finialise_list_tree;
end;
