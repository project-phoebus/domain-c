{ rewrite - the ISC's tree rewrites before pass 1: a call (or an
  operator, an assignment or a statement done by a run-time routine)
  into an ISC call tree with its argument copies and register or slot
  placements from the calling conventions (rewrite_$routine_call); a
  multiply by a constant into shifts, adds and subtracts from the
  m32_prism_and_pa and m16_prism tables (rewrite_$const_mul,
  rewrite_$mul_to_aop); a chain of equality branches on one value into
  a case statement with a jump table (rewrite_$check_for_case_statement);
  the routine's entry with a large dynamic frame into a call of
  rws_$alloc_temp (rewrite_$entry); an aggregate assignment into an
  ISC_AGG over a CSE of its address (rewrite_$agg_aop).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x21B618  get_home_or_temp (internal)
    --------  0x21B770  rewrite_$routine_call
    --------  0x21CBC8  correct_uc (internal)
    --------  0x21CC5C  correct_opmod (internal)
    --------  0x21CC6C  make_tree_node (internal)
    --------  0x21CCBA  construct_instruction (internal)
    --------  0x21CF6C  rewrite_$const_mul
    --------  0x21D272  rewrite_$mul_to_aop
    --------  0x21D30C  case_displacement (internal)
    --------  0x21D378  common_piece_of_tree (internal)
    --------  0x21D3A0  tree_is_a_constant (internal)
    --------  0x21D41A  turn_into_case_statement (internal)
    --------  0x21D6CE  rewrite_$check_for_case_statement
    --------  0x21D8C2  make_call_to_rws_$alloc_temp (internal)
    --------  0x21D926  rewrite_$entry
    --------  0x21DA9A  rewrite_$agg_aop
  A5 0x48115C: the module's data, 0x4078 bytes (below).  The internal
  routines use the caller's A5 (make_tree_node reads +16..+48).

  The nodes are made from lir's heap (lir +0x3F60, backend.ins.pas's
  lir_3f60, passed by address), rewrite_$agg_aop's from the ISC's
  preserved heap.

  Not known from the original: the parameters', locals' and module
  variables' names; the node views (rw_node_t) are the reconstruction's. }
module rewrite;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'us/us/ins/strl.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/at_lib_dsc.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas';
%include 'lang2/source/isc/isc_consts.ins.pas';
%include 'lang2/source/isc/isc_types.ins.pas';
%include 'lang2/source/isc/isc_routine_externs.ins.pas';
%include 'lang2/source/isc/isc_var_externs.ins.pas';
%include 'lang/lang/source/list_tree.ins.pas';

type
  { The nodes as rewrite reads and builds them (kinds: add_node.pas's
    an_kind_t ordinals). }
  rw_ptr_t = ^rw_node_t;
  rw_ptrs_t = array [0..7] of rw_ptr_t;
  rw_node_t = record
    rewritten: boolean;                 { +0: set in what rewrite makes
                                          (rw_rewritten) }
    b1: char;                           { +1 }
    kind: integer;                      { +2 }
    case integer of
      { A tree node (137, 143 a comparison; 138 done). }
      1: (phase: add_node_$phase_t;     { +4 }
          w8: integer;                  { +8 }
          f10: packed record            { +10: an ISC_FUNC_CALL's result
                                          location and register }
            b10: 0..255;
            b11: 0..255;
            end;
          f12: packed record            { +12: a call's flags }
            fio: boolean;               { .7: a FORTRAN I/O call
                                          (rewrite_$routine_call) }
            b12_6_0: 0..127;
            async: boolean;             { +13 .7: the conventions' async }
            b13_6_0: 0..127;
            cleanup: boolean;           { +14 .7: the conventions'
                                          cleanup }
            b14_6_0: 0..127;
            b15: 0..255;
            end;
          uses: integer;                { +16 }
          w18: integer;                 { +18 }
          desc: add_node_$desc_t;       { +20: size, rlen, w6 (opmod1),
                                          w8 (opmod2), flags }
          op: integer;                  { +36 }
          count: integer;               { +38 }
          opnd: array [1..64] of rw_ptr_t);     { +40 }
      { A statement: 140 ASSIGN_NODE's fields from +48 (228
        BIT_FIELD_ASSIGN and the others through st_p48.. below). }
      2: (prev: rw_ptr_t;               { +4 }
          next: rw_ptr_t;               { +8 }
          top: univ_ptr;                { +12 }
          st_l16: integer32;            { +16 }
          line: integer;                { +20 }
          st_x22: array [22..41] of char;           { +22 }
          l42: integer32;               { +42: +43..+44 the statement's
                                          index }
          st_w46: integer;              { +46 }
          size: integer32;              { +48 }
          rlen: integer;                { +52 }
          w54: integer;                 { +54 }
          w56: integer;                 { +56 }
          w58: integer;                 { +58 }
          l60: integer32;               { +60 }
          dst: rw_ptr_t;                { +64 }
          src: rw_ptr_t;                { +68 }
          x72: rw_ptr_t;                { +72 }
          aop: integer);                { +76 }
      3: (st_x4: array [1..11] of integer32;        { +4 }
          st_p48: rw_ptr_t;             { +48 }
          st_p52: rw_ptr_t;             { +52 }
          st_p56: rw_ptr_t;             { +56 }
          st_p60: rw_ptr_t;             { +60 }
          st_p64: rw_ptr_t);            { +64 }
      { 139 EVAL_NODE (+50 its count, +52 its tree), 142 CBRANCH_NODE
        (+56 the condition, +60 bit 7 the branch is taken when true). }
      4: (ev_x4: array [1..11] of integer32;        { +4 }
          ev_w48: integer;              { +48 }
          ev_count: integer;            { +50 }
          ev_x52: array [13..14] of integer32;      { +52 }
          cb_f60: packed record         { +60 }
            on_true: boolean;
            b6_0: 0..127;
            end);
      { A reference: 145 DINDEX_NODE, 146 PTR_NODE, 147 DISP_NODE. }
      5: (rf_phase: integer32;          { +4 }
          rf_x8: array [2..3] of integer32;         { +8 }
          rf_uses: integer;             { +16 }
          rf_w18: integer;              { +18 }
          rf_w20: integer;              { +20 }
          rf_f22: packed record         { +22 }
            b22: 0..255;
            b23: 0..255;
            end;
          rf_base: rw_ptr_t;            { +24 }
          rf_l28: integer32;            { +28 }
          rf_disp: integer32;           { +32 }
          rf_index: rw_ptr_t;           { +36 }
          rf_l40: integer32);           { +40: scale and index length }
      { 109 VAR_NAME (+32 its attributes, +72 its allocation), 110
        FORTRAN_SYMBOL (+24 its attributes, +40, +44 bits 7..4 its
        class, +48). }
      6: (vr_x4: array [1..5] of integer32;         { +4 }
          fs_attr: integer32;           { +24 }
          vr_x28: integer32;            { +28 }
          vr_attr: integer32;           { +32 }
          vr_x36: integer32;            { +36 }
          fs_p40: rw_ptr_t;             { +40 }
          fs_f44: packed record         { +44 }
            cls: 0..15;
            b3_0: 0..15;
            b45: 0..255;
            end;
          fs_p48: rw_ptr_t;             { +48 }
          vr_x52: array [13..17] of integer32;      { +52 }
          vr_vat: integer;              { +72 }
          vr_w74: integer;              { +74 }
          vr_x76: integer32;            { +76 }
          vr_link: rw_ptr_t);           { +80: lir_main's temporaries'
                                          chain (get_home_or_temp) }
      { 163 ADDR_CON (+8 its symbol, +20 its kind), 164 CS_NODE (+20). }
      7: (ac_x4: integer32;             { +4 }
          ac_sym: rw_ptr_t;             { +8 }
          ac_x12: array [3..4] of integer32;        { +12 }
          ac_f20: packed record         { +20 }
            b20: 0..255;
            b21: 0..255;
            end);
      8: (cs_x4: array [1..4] of integer32;         { +4 }
          cs_value: rw_ptr_t);          { +20 }
      { 81 an integer constant. }
      9: (ic_next: rw_ptr_t;            { +4 }
          ic_value: integer32);         { +8 }
      10: (ic_x4: integer32;            { +4 }
           ic_high: integer;            { +8 }
           ic_low: integer);            { +10 }
      { 203 PHYSICAL_REGISTER_OB (+4 the location's class, +6 the
        register), 204 ARGUMENT_BLOCK_LOCATION_OB (+4 the offset). }
      11: (lo_class: integer;           { +4 }
           lo_reg: integer);            { +6 }
      12: (lo_offset: integer32);       { +4 }
      { 159 LIB_DSC: +8 the name's length, its characters from the word
        +12 + 2 * +10. }
      13: (ld_x4: integer32;            { +4 }
           ld_len: 0..65535;            { +8 }
           ld_skip: integer;            { +10 }
           ld_words: array [0..2047] of integer);   { +12 }
      { A block (105..108, 167 an entry's: +148 its routine). }
      14: (bk_x4: array [4..71] of char;            { +4 }
           bk_p72: univ_ptr;            { +72 }
           bk_x76: array [76..147] of char;         { +76 }
           bk_routine: rw_ptr_t;        { +148 }
           bk_x152: array [152..175] of char;       { +152 }
           bk_dynamic: integer32;       { +176: the dynamic frame's
                                          bytes }
           bk_xdynm: rw_ptr_t;          { +180 }
           bk_x184: integer32;          { +184 }
           bk_l188: integer32;          { +188 }
           bk_sect: univ_ptr;           { +192 }
           bk_x196: array [196..239] of char;       { +196 }
           bk_parent: rw_ptr_t;         { +240 }
           bk_x244: array [244..267] of char;       { +244 }
           bk_args: integer;            { +268: the argument area's
                                          bytes }
           bk_x270: array [270..293] of char;       { +270 }
           bk_f294: packed record       { +294 }
             slevel: -128..127;
             b295: 0..255;
             end;
           bk_x296: array [296..375] of char;       { +296 }
           bk_w376: 0..65535;           { +376 }
           bk_b378: 0..255;             { +378 }
           bk_f379: packed record       { +379 }
             b7, b6, b5: boolean;
             b4: boolean;               { .4 }
             b3_0: 0..15;
             end);
      { 117 LABEL_NAME (+20 its routine, +28 its node). }
      15: (lb_x4: array [1..4] of integer32;        { +4 }
           lb_block: rw_ptr_t;          { +20 }
           lb_x24: integer32;           { +24 }
           lb_node: rw_ptr_t);          { +28 }
  end;

  { An entry of the multiplication tables (8 bytes): up to six steps,
    each an op (rw_op_tab's tree operator, after a left shift by
    rw_shift_tab's count for ops 3..5, 7..12) on the values a and b
    (0 the multiplicand, k the result of step k; for ops 0 and 1 b is a
    shift count, 8 more for op 1).  rw_steps_t reads the steps whole
    (zero: no more steps), as the image does (`and.l #16#3FF000' of the
    first longword for step 2); not a variant of rw_seq_t because dpc
    does not take a positional initializer for a variant record. }
  rw_seq_ptr_t = ^rw_seq_t;
  rw_seq_t = packed record
    op1: 0..15; a1: 0..7; b1: 0..7;
    op2: 0..15; a2: 0..7; b2: 0..7;
    op3: 0..15; a3: 0..7; b3: 0..7;
    op4: 0..15; a4: 0..7; b4: 0..7;
    op5: 0..15; a5: 0..7; b5: 0..7;
    op6: 0..15; a6: 0..7; b6: 0..7;
    pad: 0..15;
  end;
  rw_steps_ptr_t = ^rw_steps_t;
  rw_steps_t = packed record
    s1, s2, s3, s4, s5, s6: 0..1023;
    pad: 0..15;
  end;
  rw_seq_table_t = array [0..1023] of rw_seq_t;

  { A case table (zzzzz_$preallocate_case_table's cell): the labels
    from +20. }
  rw_case_table_ptr_t = ^rw_case_table_t;
  rw_case_table_t = record
    x0: array [0..4] of integer32;      { +0 }
    labels: array [0..1023] of univ_ptr;    { +20 }
  end;

  rw_heap_ptr_t = ^mrh_$heap_t;
  rw_desc_ptr_t = ^add_node_$desc_t;

  { The 12 bytes of a tree node from +4 that make_tree_node copies (a
    node's phase, +8, +10, +12). }
  rw_hdr_ptr_t = ^rw_hdr_t;
  rw_hdr_t = record
    phase: add_node_$phase_t;           { +0 }
    w4: integer;                        { +4 }
    w6: integer;                        { +6 }
    l8: integer32;                      { +8 }
  end;

var
  { The module's data (A5 0x48115C), in address order. }
  rw_long_desc: add_node_$desc_t := [4, 4, 4, 4, [false, false, false,
      false, false, false, false, false, 0], 0];    { +0: a longword's
                                          descriptor }
  rw_hdr: rw_hdr_t;                     { +16: what make_tree_node puts
                                          at +4 }
  rw_unused_28: integer32;              { +28 }
  rw_desc: add_node_$desc_t;            { +32: make_tree_node's
                                          descriptor }
  rw_rewritten: boolean;                { +48: make_tree_node's +0 }
  rw_unused_50: array [0..2] of integer;    { +49 in the image (+50
                                          here: dpc gives a boolean two
                                          bytes, docs/dpc-gaps.md 37) }
  { +56: by step op, the tree operator (27 LSHFT, 1 ADD, 2 SUB); +88:
    the left shift its first operand gets first (0 none). }
  rw_op_tab: array [0..15] of integer := [27, 27, 1, 1, 1, 1, 2, 2, 2,
      2, 2, 2, 2, 0, 0, 0];
  rw_shift_tab: array [0..15] of integer := [0, 0, 0, 1, 2, 3, 0, 1, 2,
      3, 1, 2, 3, 0, 0, 0];
  rw_m32: rw_seq_table_t := [           { +120 }
%include 'lang2/source/be_com/m32_prism_and_pa.pas';
      ];
  rw_m16: rw_seq_table_t := [           { +8312 }
%include 'lang2/source/be_com/m16_prism.pas';
      ];

{ get_home_or_temp - where an argument sym of class rlen and bits bits
  is copied: its memory home (isc_$get_memory_home, of a real type for
  the floating classes 6, 7, 8, 12, else an integer type) or one of
  lir_main's 8-byte temporaries (the free one kept for 32 bits or less,
  lir_main_c58; else the next of the list from lir_main_c60, a new one
  appended when there is none: 64 bits, static when il_180's +379 bit 4
  is set, lir_main_c68 counting their bytes); a home or new temporary
  is marked (attributes 16#402000); for fewer than 32 bits, a DISP_NODE
  of it at the value's place in its word (4, or 8 in the kept
  temporary, less the bytes).

  0x21B618, 0x158 bytes, internal (the caller's A5): sym 8, rlen a word
  at 12, bits 14; `bgt' on 32 for the kept temporary, `blt' for the
  DISP_NODE; the temporaries chained at +80 (lir_main_c5c the first,
  lir_main_c64 the last); the offset `addq.l #7; lsr.l #3' subtracted.

  Not known from the original: lir_main's cells' names (batch A's). }

function get_home_or_temp(
    sym: rw_ptr_t;
    rlen: integer;
    bits: integer32): rw_ptr_t; options(val_param, internal);
label
  1;
var
  kind: integer;
  h: rw_ptr_t;
  t: rw_ptr_t;
  n: rw_ptr_t;
  off: integer32;
begin
  if (rlen = 6) or (rlen = 7) or (rlen = 12) or (rlen = 8) then
    kind := 123
  else
    kind := 122;
  h := isc_$get_memory_home(sym, kind, bits);
  if h = nil then begin
    if bits <= 32 then begin
      h := lir_main_c58;
      if h <> nil then begin
        lir_main_c58 := nil;
        off := 8;
        goto 1;
      end;
    end;
    h := lir_main_c60;
    if h = nil then begin
      h := make_expression_temporary(123, 64);
      lir_main_c68 := lir_main_c68 + 8;
      if lir_main_c64 = nil then
        lir_main_c5c := integer32(h)
      else begin
        t := lir_main_c64;
        t^.vr_link := h;
      end;
      lir_main_c64 := h;
      h^.vr_link := nil;
      if rw_ptr_t(il_180)^.bk_f379.b4 then
        sym_$allocate_static_variable(h, 8);
    end;
    if bits <= 32 then
      lir_main_c58 := h;
    lir_main_c60 := h^.vr_link;
  end;
  if h^.kind = 109 then
    h^.vr_attr := h^.vr_attr ! 16#402000
  else
    h^.fs_attr := h^.fs_attr ! 16#402000;
  if bits >= 32 then begin
    get_home_or_temp := h;
    return;
  end;
  off := 4;
1:
  n := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 36);
  n^.kind := 147;
  n^.rewritten := rw_rewritten;
  n^.rf_disp := off - rshft(bits + 7, 3);
  n^.rf_base := h;
  get_home_or_temp := n;
end;

{ rewrite_$routine_call - node rewritten as an ISC call tree: node a
  call (137 with op 15 CALL or 16 FUNC_CALL), an operator done by a
  run-time routine (137 with op 41, 42, 87, 86, 43, 65, 82, 84: the
  routine from at_lib_dsc_ptr by the result class and opmods), or a
  statement done by one (150 NLBRANCH_NODE, 224, 225, 140 ASSIGN_NODE
  of aop 32, 228 BIT_FIELD_ASSIGN, 149: their routines from
  at_lib_dsc_ptr [46..59]).  The call tree (80 bytes, three operands:
  the routine, the inputs, the outputs) carries the conventions
  (at_call_conv's record at +52, its register w14 as opmod1, async and
  cleanup at +13 and +14) and is ISC_CALL (op 30) for a procedure,
  ISC_FUNC_CALL (31) for a function whose result comes back by value
  (its size, class, location and register in the call tree), else
  ISC_FUNC_CALL_HIDDEN_TEMP (32) with the hidden temporary temp (put in
  node's first operand, marked +34 bit 5, node's +5 bit 7).  The
  argument area (il_180's +268) grows to the conventions' (cgerr 50
  past 2048 bytes; at least 24 for a call).  For each argument after
  the result: the value (the node's operand of the descriptor's number,
  the static link of the NLBRANCH_NODE's target level or the label's
  address, the statement's operand by position); a CS_NODE's value, a
  FORTRAN constant's value, a FORTRAN routine's address constant made;
  a double of a pair of slots copied into a new temporary (the next
  argument of the same number then given the original); a value that
  must not stay in a register copied into its home or a temporary
  (get_home_or_temp: an ASSIGN_NODE on the inputs, and one back on the
  outputs for a by-reference argument of mode 1, 3 or 4), a variable
  or symbol marked; then an argument ASSIGN_NODE (+64 its location:
  204 a slot by offset, 203 a register by class and number; +68 the
  value, its address (ISC_ADDR, op 64) when by reference, at a
  displacement for a by-value part) on the input chain, and its
  reverse on the output chain for a by-value argument of mode 3 or 4.
  Then the static link (conventions +4, register w12) and the callee's
  data section (register w16, when the callee needs DB and the
  routine's DB register is not that one or is clobbered: il_node_154 or
  an address constant); the chains joined to the call tree's.  A call
  of a lib_dsc named fio_$xfer_..., fio_$inq_... is marked FORTRAN I/O
  (+12 bit 7), any other fio_$... routine also wrapped in an
  ISC_FIO_INIT (op 67) with the call's label operands (FORTRAN symbols
  of class 6 whose value is a 144).  A statement is wrapped in an
  EVAL_NODE.  The original and the rewritten trees are listed under
  the phase's switch sw10.

  0x21B770, 0x1296 bytes: node 8, temp 12, inh 16; the statement kinds
  tested on a bit table of 0..239 (the top-level kinds); the call tree
  in (-316,A6) and (-380,A6); the argument index in D4 and 26 times it
  in D3 and (-422,A6) (call_conv_$arg_t's size); the loop `subq.w
  #1,(-382,A6); bcc' (nargs - first + 1 times); every node from lir's
  heap.

  Not known from the original: what the heap is called; the at_lib_dsc
  entries' routines (by index only); the bit_field_assign message has
  no terminator in the image (it runs into the assign_node one). }

function rewrite_$routine_call(
    node: rw_ptr_t;
    temp: rw_ptr_t;
    inh: inherited_attributes_ptr_t): rw_ptr_t; options(val_param);
var
  top: univ_ptr;
  stmt: 0..65535;
  line: integer;
  c: rw_ptr_t;
  res: rw_ptr_t;
  is_call: boolean;
  r: rw_ptr_t;
  conv: call_conv_$ptr_t;
  rconv: call_conv_$ptr_t;
  db: lr_ptr_t;
  first: integer;
  j: integer;
  n: integer;
  arg: rw_ptr_t;
  inputs: rw_ptr_t;
  outputs: rw_ptr_t;
  last_in: rw_ptr_t;
  saved: rw_ptr_t;
  home: rw_ptr_t;
  value: rw_ptr_t;
  size: integer32;
  rl: integer;
  rlen: integer;
  bits: integer32;
  cand: boolean;
  copy: boolean;
  a, b, an, o, l, d, t: rw_ptr_t;
  lvl: integer;
  i: integer;
  x: integer;
  lib: rw_ptr_t;
  old: rw_ptr_t;
begin
  rw_rewritten := true;
  if node^.kind in [139..142, 144, 148..151, 188, 191, 214..215,
                    223..225, 227..228, 231, 233] then begin
    top := node^.top;
    stmt := rshft(node^.l42 & 16#FFFF00, 8);
    line := node^.line;
  end
  else begin
    top := inh^.exception_frame;
    stmt := inh^.pos.stmt_number;
    line := inh^.pos.source_line_number;
  end;
  if at_backend_switches.sw10 then begin
    vfmt_$write('REWRITE -- original tree for source line %wd:%.', line);
    list_tree_$print_tree(il_$node_ptr_t(node), nil);
  end;
  c := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
  res := c;
  c^.kind := 137;
  c^.rewritten := true;
  c^.count := 3;
  conv := nil;
  if node^.kind = 137 then begin
    c^.desc := node^.desc;
    rw_hdr_ptr_t(addr(c^.phase))^ := rw_hdr_ptr_t(addr(node^.phase))^;
    is_call := (node^.op = 15) or (node^.op = 16);
    if is_call then begin
      r := node^.opnd[1];
      if r^.kind = 171 then
        c^.opnd[1] := rw_ptr_t(r^.cs_x4[4])
      else if (r^.kind = 110) and (r^.fs_p40 <> nil) then
        c^.opnd[1] := r^.fs_p40
      else
        c^.opnd[1] := r;
      conv := at_call_conv(il_$node_ptr_t(node));
    end
    else begin
      if node^.op = 41 then
        c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[node^.desc.rlen * 20
                                             + node^.desc.w6 - 121])
      else if node^.op = 42 then begin
        if (node^.desc.w8 = 7) or (node^.desc.w8 = 6) then
          c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[34 + node^.desc.rlen])
        else
          c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[38 + node^.desc.rlen]);
      end
      else if node^.op = 87 then
        c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[36 + node^.desc.rlen])
      else if node^.op = 86 then begin
        if not node^.desc.flags.signed then
          c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[48])
        else if node^.desc.flags.b7 then
          c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[49])
        else
          c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[47]);
      end
      else if node^.op = 43 then
        c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[46])
      else if node^.op = 65 then
        c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[52])
      else if node^.op = 82 then
        c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[53])
      else if node^.op = 84 then begin
        if node^.desc.w8 = 7 then
          c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[56])
        else
          c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[57]);
      end
      else begin
        bug_check('REWRITE: unrecognized tree_node.op%.');
        c^.opnd[1] := nil;
      end;
      if c^.opnd[1] <> nil then
        conv := at_call_conv(il_$node_ptr_t(c^.opnd[1]));
    end;
  end
  else begin
    is_call := false;
    if node^.kind = 150 then
      c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[51])
    else if node^.kind = 224 then
      c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[55])
    else if node^.kind = 225 then
      c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[54])
    else if (node^.kind = 140) and (node^.aop = 32) then
      c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[50])
    else if node^.kind = 228 then
      c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[58])
    else if node^.kind = 149 then
      c^.opnd[1] := rw_ptr_t(at_lib_dsc_ptr[59])
    else
      bug_check('REWRITE: unrecognized IL kind.op%.');
    if c^.opnd[1] <> nil then
      conv := at_call_conv(il_$node_ptr_t(c^.opnd[1]));
  end;

  { the conventions }
  c^.opnd[4] := rw_ptr_t(conv);
  c^.desc.w6 := conv^.w14;
  c^.f12.async := conv^.async;
  c^.f12.cleanup := conv^.cleanup;
  if conv^.args_size > 2048 then begin
    at_backend_506 := false;
    cgerr(50, line, smcontk(81, conv^.args_size));
  end
  else if rw_ptr_t(il_180)^.bk_args < conv^.args_size then
    rw_ptr_t(il_180)^.bk_args := conv^.args_size;
  if (rw_ptr_t(il_180)^.bk_args < 24) and is_call then
    rw_ptr_t(il_180)^.bk_args := 24;

  { the kind of call }
  if (node^.kind = 150) or (node^.kind = 140) or (node^.kind = 225)
     or (node^.kind = 224) or (node^.kind = 228) or (node^.kind = 149)
     or (node^.op = 15) then begin
    c^.op := 30;
    first := 1;
  end
  else if (node^.op = 16) and (conv^.args[1].f16.rlen = 0) then begin
    c^.op := 30;
    first := 2;
  end
  else begin
    c^.desc.rlen := conv^.args[1].f16.rlen;
    c^.desc.size := conv^.args[1].size;
    c^.f10.b10 := conv^.args[1].f18.loc;
    c^.f10.b11 := conv^.args[1].f22.reg;
    if not conv^.args[1].by_value then begin
      c^.op := 32;
      first := 1;
      node^.opnd[1] := temp;
      if temp <> nil then begin
        temp^.vr_attr := temp^.vr_attr ! 16#2000;
        node^.phase := node^.phase + [23];
      end;
    end
    else begin
      c^.op := 31;
      first := 2;
    end;
  end;

  { the arguments }
  inputs := nil;
  outputs := nil;
  last_in := nil;
  saved := nil;
  arg := nil;
  for j := first to conv^.nargs do begin
    home := nil;
    if node^.kind = 137 then
      arg := node^.opnd[conv^.args[j].num + ord(is_call)]
    else if node^.kind = 150 then begin
      if j = 1 then begin
        if node^.st_p48^.kind <> 117 then
          bug_check('REWRITE: unexpected NLBRANCH_NODE.DST%.');
        lvl := rw_ptr_t(il_180)^.bk_f294.slevel
               - node^.st_p48^.lb_block^.bk_f294.slevel;
        arg := rw_ptr_t(il_180)^.bk_parent;
        for i := lvl - 2 downto 0 do
          arg := rw_ptr_t(arg^.top);
      end
      else begin
        l := node^.st_p48^.lb_node;
        while l^.kind <> 148 do
          l := l^.prev;
        if l^.st_p48^.bk_l188 <> rw_ptr_t(il_180)^.bk_l188 then
          cgerr(25, node^.line, node^.st_p48);
        arg := rw_ptr_t(get_proc_addr_con(6,
                   il_$node_ptr_t(node^.st_p48^.lb_node),
                   rw_ptr_t(il_180)^.bk_l188,
                   rw_ptr_t(il_180)^.bk_sect));
      end;
    end
    else if node^.kind = 140 then begin
      case j of
        1: arg := node^.src;
        2: arg := node^.dst;
        3: arg := node^.x72;
        otherwise
          bug_check('REWRITE: Wrong number of assign_node arguments.');
      end;
    end
    else if node^.kind = 228 then begin
      case j of
        1: arg := node^.st_p56;
        2: arg := node^.st_p60;
        3: arg := node^.st_p48;
        4: arg := node^.st_p52;
        5: arg := node^.st_p64;
        otherwise
          bug_check('REWRITE: Wrong number of bit_field_assign arguments.');
      end;
    end
    else if (node^.kind = 225) or (node^.kind = 224) then
      arg := node^.st_p48
    else
      bug_check('REWRITE: unrecognized IL kind for the call.op%.');

    { a byte or halfword passed to op 86's routine: widened }
    if (node^.kind = 137) and (j = 2) and (node^.op = 86)
       and ((node^.desc.rlen = 2) or (node^.desc.rlen = 1)) then begin
      t := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 44);
      t^.kind := 137;
      t^.rewritten := true;
      t^.op := 18;
      t^.count := 1;
      t^.desc.rlen := 4;
      t^.desc.w6 := node^.desc.rlen;
      t^.opnd[1] := arg;
      arg := t;
    end;
    if arg^.kind = 164 then
      arg := arg^.cs_value;
    if (arg^.kind = 110) and (arg^.fs_f44.cls = 6) then begin
      d := arg^.fs_p48;
      if d^.kind in [77..90, 92..93, 101, 156, 176, 198, 200] then
        arg := d;
    end;
    if (arg^.kind = 163) and (arg^.ac_f20.b20 = 4)
       and (arg^.ac_sym^.kind = 110) and (arg^.ac_sym^.fs_f44.cls = 1)
       and (arg^.ac_sym^.fs_p40 <> nil) then
      arg^.ac_sym := arg^.ac_sym^.fs_p40
    else if (arg^.kind = 110) and (arg^.fs_f44.cls = 1)
            and (arg^.fs_p40 <> nil)
            and (arg^.fs_p40 <> rw_ptr_t(il_180))
            and (rshft(arg^.fs_p40^.bk_w376 & 16#180, 7) = 0) then
      arg := rw_ptr_t(make_new_addr_con(5, il_$node_ptr_t(arg^.fs_p40), 0,
                 rw_ptr_t(il_180)^.bk_sect, false));

    { the original of a split double given to the last of its parts }
    if saved <> nil then
      if (j = conv^.nargs)
         or (conv^.args[j].num <> conv^.args[j + 1].num) then begin
        node^.opnd[conv^.args[j].num + ord(is_call)] := saved;
        saved := nil;
      end;

    if arg^.kind = 147 then
      cand := isc_$is_a_register_candidate(arg^.rf_base)
    else
      cand := isc_$is_a_register_candidate(arg);
    copy := not (20 in getphase(arg)) and not cand;
    if conv^.args[j].by_value then begin
      value := arg;
      if (arg^.kind = 137) and (j < conv^.nargs)
         and (conv^.args[j + 1].num = conv^.args[j].num)
         and (arg^.desc.rlen = 7) then begin
        home := make_expression_temporary(123, 64);
        home^.vr_attr := home^.vr_attr ! 16#2000;
        size := 8;
        rlen := 7;
        value := home;
        x := conv^.args[j].num + ord(is_call);
        saved := node^.opnd[x];
        node^.opnd[x] := home;
      end;
    end
    else if cand and (arg^.kind = 147) then begin
      get_rlen_and_size(il_$node_ptr_t(arg^.rf_base), rl, size);
      rlen := rl;
      bits := isc_$precision_from_rlen_and_size(rlen, size);
      size := bits div 8;
      home := get_home_or_temp(arg^.rf_base, rlen, bits);
      value := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 44);
      value^.kind := 147;
      value^.rewritten := true;
      value^.rf_phase := arg^.rf_phase;
      value^.rf_x8 := arg^.rf_x8;
      value^.rf_uses := arg^.rf_uses;
      value^.rf_w18 := arg^.rf_w18;
      value^.rf_w20 := arg^.rf_w20;
      value^.rf_f22 := arg^.rf_f22;
      value^.rf_l28 := arg^.rf_l28;
      value^.rf_disp := arg^.rf_disp;
      value^.rf_index := arg^.rf_index;
      value^.rf_l40 := arg^.rf_l40;
      value^.rf_base := home;
      arg := arg^.rf_base;
    end
    else if ((arg^.kind = 109) or (arg^.kind = 110)) and copy then begin
      if arg^.kind = 109 then
        arg^.vr_attr := arg^.vr_attr ! 16#402000
      else
        arg^.fs_attr := arg^.fs_attr ! 16#402000;
      value := arg;
    end
    else if copy
            or (arg^.kind in [77..90, 92, 105..108, 144..147, 156, 163,
                              167, 192, 195, 200, 205, 212]) then begin
      d := rw_ptr_t(alias_$ind_for_captured_lvalue(il_$node_ptr_t(arg)));
      if d <> nil then begin
        if d^.kind = 109 then
          d^.vr_attr := d^.vr_attr ! 16#402000
        else if d^.kind = 110 then
          d^.fs_attr := d^.fs_attr ! 16#402000;
      end;
      value := arg;
    end
    else begin
      if (arg^.kind = 109) and (arg^.vr_vat <> 5) then begin
        get_rlen_and_size(il_$node_ptr_t(arg), rl, size);
        rlen := rl;
      end
      else begin
        rlen := conv^.args[j].f16.rlen;
        size := conv^.args[j].size;
      end;
      bits := isc_$precision_from_rlen_and_size(rlen, size);
      size := bits div 8;
      home := get_home_or_temp(arg, rlen, bits);
      value := home;
    end;

    { the copy into the home or temporary, and back }
    if home <> nil then begin
      a := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
      a^.kind := 140;
      a^.rewritten := true;
      a^.size := size;
      a^.rlen := rlen;
      a^.top := top;
      a^.l42 := (a^.l42 & 16#FF0000FF) ! lshft(stmt, 8);
      a^.line := line;
      a^.next := c^.opnd[2];
      if (a^.rlen = 6) or (a^.rlen = 7) or (a^.rlen = 12)
         or (a^.rlen = 8) then
        a^.aop := 11
      else if a^.rlen = 11 then
        a^.aop := 6
      else
        a^.aop := 0;
      if last_in = nil then
        last_in := a;
      c^.opnd[2] := a;
      a^.src := arg;
      a^.dst := home;
      if not conv^.args[j].by_value
         and (conv^.args[j].f22.mode in [1, 3, 4]) and cand then begin
        b := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
        b^.kind := 140;
        b^.rewritten := true;
        b^.top := top;
        b^.l42 := (b^.l42 & 16#FF0000FF) ! lshft(stmt, 8);
        b^.line := line;
        b^.next := c^.opnd[3];
        b^.size := size;
        b^.rlen := rlen;
        b^.src := home;
        b^.dst := arg;
        if (b^.rlen = 6) or (b^.rlen = 7) or (b^.rlen = 12)
           or (b^.rlen = 8) then
          b^.aop := 11
        else if b^.rlen = 11 then
          b^.aop := 6
        else
          b^.aop := 0;
        c^.opnd[3] := b;
      end;
    end;

    { the argument }
    an := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
    an^.kind := 140;
    an^.rewritten := true;
    if not conv^.args[j].by_value then begin
      an^.size := 4;
      an^.rlen := 5;
      an^.aop := 0;
    end
    else begin
      an^.size := conv^.args[j].size;
      an^.rlen := conv^.args[j].f16.rlen;
      x := conv^.args[j].f16.rlen;
      if (x = 6) or (x = 7) or (x = 12) or (x = 8) then
        an^.aop := 11
      else if x = 11 then
        an^.aop := 6
      else
        an^.aop := 0;
    end;
    an^.top := top;
    an^.l42 := (an^.l42 & 16#FF0000FF) ! lshft(stmt, 8);
    an^.line := line;
    an^.next := inputs;
    inputs := an;
    l := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 8);
    an^.dst := l;
    if conv^.args[j].f18.loc = 4 then begin
      l^.kind := 204;
      l^.rewritten := true;
      l^.lo_offset := conv^.args[j].offset;
    end
    else begin
      l^.kind := 203;
      l^.rewritten := true;
      l^.lo_class := conv^.args[j].f18.loc;
      l^.lo_reg := conv^.args[j].f22.reg;
    end;
    if conv^.args[j].by_value then begin
      if conv^.args[j].w6 = 0 then
        an^.src := value
      else begin
        d := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 40);
        an^.src := d;
        d^.kind := 147;
        d^.rewritten := true;
        d^.rf_disp := conv^.args[j].w6;
        d^.rf_base := value;
      end;
    end
    else if value^.kind = 146 then
      an^.src := value^.rf_base
    else begin
      t := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 44);
      an^.src := t;
      t^.kind := 137;
      t^.rewritten := true;
      t^.op := 64;
      t^.count := 1;
      t^.desc.size := 4;
      t^.desc.rlen := 5;
      t^.desc.w6 := conv^.args[j].f16.rlen;
      t^.desc.w8 := conv^.args[j].size;
      t^.opnd[1] := value;
      an^.size := 4;
      an^.rlen := 5;
      an^.aop := 0;
    end;
    if (c^.op = 32) and (j = 1) then
      c^.opnd[5] := an^.src;
    if conv^.args[j].by_value
       and (conv^.args[j].f22.mode in [3, 4]) then begin
      o := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
      o^.kind := 140;
      o^.rewritten := true;
      o^.prev := an^.prev;
      o^.next := an^.next;
      o^.top := an^.top;
      o^.st_l16 := an^.st_l16;
      o^.line := an^.line;
      o^.st_x22 := an^.st_x22;
      o^.l42 := an^.l42;
      o^.st_w46 := an^.st_w46;
      o^.size := an^.size;
      o^.rlen := an^.rlen;
      o^.w54 := an^.w54;
      o^.w56 := an^.w56;
      o^.w58 := an^.w58;
      o^.l60 := an^.l60;
      o^.x72 := an^.x72;
      o^.aop := an^.aop;
      o^.src := an^.dst;
      o^.dst := an^.src;
      o^.next := outputs;
      outputs := o;
    end;
  end;

  { the static link }
  if conv^.link <> nil then begin
    an := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
    an^.kind := 140;
    an^.rewritten := true;
    an^.size := 4;
    an^.rlen := 5;
    an^.top := top;
    an^.l42 := (an^.l42 & 16#FF0000FF) ! lshft(stmt, 8);
    an^.line := line;
    an^.next := inputs;
    an^.aop := 0;
    inputs := an;
    an^.src := conv^.link;
    l := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 8);
    an^.dst := l;
    l^.kind := 203;
    l^.rewritten := true;
    l^.lo_class := 0;
    l^.lo_reg := conv^.w12;
  end;

  { the callee's data section }
  if conv^.b27 and conv^.needs_db then begin
    rconv := rtn_ptr_t(at_backend_4fc)^.conv;
    db := rtn_ptr_t(at_backend_4fc)^.db_lr;
    if not db^.f2.physical or (db^.f2.reg <> conv^.w16)
       or ((rconv^.w16 & 31) in bv_word_t(rconv^.ip76)) then begin
      an := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
      an^.kind := 140;
      an^.rewritten := true;
      an^.size := 4;
      an^.rlen := 5;
      an^.top := top;
      an^.l42 := (an^.l42 & 16#FF0000FF) ! lshft(stmt, 8);
      an^.line := line;
      an^.next := inputs;
      an^.aop := 0;
      inputs := an;
      if conv^.data_sect = rw_ptr_t(il_180)^.bk_sect then
        an^.src := rw_ptr_t(il_node_154)
      else
        an^.src := rw_ptr_t(make_new_addr_con(10,
                       il_$node_ptr_t(conv^.data_sect), 0,
                       rw_ptr_t(il_180)^.bk_sect, false));
      l := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 8);
      an^.dst := l;
      l^.kind := 203;
      l^.rewritten := true;
      l^.lo_class := 0;
      l^.lo_reg := conv^.w16;
    end;
  end;

  { the chains joined }
  if c^.opnd[2] <> nil then
    last_in^.next := inputs
  else
    c^.opnd[2] := inputs;
  if outputs <> nil then begin
    o := outputs;
    while o^.next <> nil do
      o := o^.next;
    o^.next := c^.opnd[3];
    c^.opnd[3] := outputs;
  end;

  { FORTRAN I/O }
  if (res^.kind = 137) and (res^.op = 30) then begin
    res^.f12.fio := false;
    lib := res^.opnd[1];
    if lib^.kind = 159 then begin
      if lib^.ld_len > 9 then
        if strl_$eq(lib^.ld_words[lib^.ld_skip], 10, 'fio_$xfer_', 10)
           or strl_$eq(lib^.ld_words[lib^.ld_skip], 9, 'fio_$inq_', 9) then
          res^.f12.fio := true;
      if not res^.f12.fio and (lib^.ld_len > 5) then
        if strl_$eq(lib^.ld_words[lib^.ld_skip], 5, 'fio_$', 5) then begin
          res^.f12.fio := true;
          old := res;
          res := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 52);
          res^.kind := 137;
          res^.rewritten := true;
          res^.op := 67;
          res^.count := 1;
          res^.opnd[1] := old;
          for i := 2 to node^.count do begin
            d := node^.opnd[i];
            if (d^.kind = 110) and (d^.fs_f44.cls = 6)
               and (d^.fs_p48^.kind = 144) then begin
              res^.count := res^.count + 1;
              res^.opnd[res^.count] := d;
            end;
          end;
        end;
    end;
  end;

  { a statement: an EVAL_NODE }
  if node^.kind in [139..142, 144, 148..151, 188, 191, 214..215,
                    223..225, 227..228, 231, 233] then begin
    d := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 56);
    d^.kind := 139;
    d^.rewritten := true;
    d^.ev_count := 1;
    d^.prev := node^.prev;
    d^.next := node^.next;
    d^.top := node^.top;
    d^.st_l16 := node^.st_l16;
    d^.line := node^.line;
    d^.st_x22 := node^.st_x22;
    d^.l42 := node^.l42;
    d^.st_p52 := res;
    res := d;
  end;
  if at_backend_switches.sw10 then begin
    vfmt_$write('REWRITE -- rewritten tree:%.');
    list_tree_$print_tree(il_$node_ptr_t(res), nil);
  end;
  rewrite_$routine_call := res;
end;

{ correct_uc - n's use count raised (a tree, a comparison, a reference
  and their bases, through a PF_CALL's +16 without raising it); a node
  used more than once (not a CSE use) marked shared (+5 bit 6, +12
  cleared); the count (0 for what is not counted).

  0x21CBC8, 0x94 bytes, internal: a compare chain on the kind (143,
  137; 175; 146, 147, 205; 145); `addq.w #1,(16,A2)'; the mark `bset
  #6,(1,A0); clr.l (8,A0)' with A0 the node's +4. }

function correct_uc(
    n: rw_ptr_t): integer32; options(val_param, internal);
var
  k: integer32;
begin
  case n^.kind of
    143, 137:
      ;
    175: begin
      discard(correct_uc(rw_ptr_t(n^.cs_x4[4])));
      correct_uc := 0;
      return;
    end;
    146, 147, 205:
      discard(correct_uc(n^.rf_base));
    145: begin
      discard(correct_uc(n^.rf_index));
      discard(correct_uc(n^.rf_base));
    end;
    otherwise begin
      correct_uc := 0;
      return;
    end;
  end;
  n^.uses := n^.uses + 1;
  k := n^.uses;
  if (k > 1) and (n^.kind <> 189) then begin
    n^.phase := n^.phase + [22];
    rw_hdr_ptr_t(addr(n^.phase))^.l8 := 0;
  end;
  correct_uc := k;
end;

{ correct_opmod - an opmod of a new tree set to the descriptor's class
  when its operand k is a step's result (not the multiplicand).

  0x21CC5C, 0x10 bytes, internal, no frame: p at 4, k a word at 8. }

procedure correct_opmod(
    var p: integer;
    k: integer); options(val_param, internal);
begin
  if k <> 0 then
    p := rw_desc.rlen;
end;

{ make_tree_node - a new tree node of two operands from lir's heap,
  with rw_desc and rw_hdr.

  0x21CC6C, 0x4E bytes, internal (the caller's A5): 48 bytes. }

function make_tree_node: rw_ptr_t; options(internal);
var
  n: rw_ptr_t;
begin
  n := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 48);
  n^.kind := 137;
  n^.rewritten := rw_rewritten;
  n^.desc := rw_desc;
  rw_hdr_ptr_t(addr(n^.phase))^ := rw_hdr;
  n^.count := 2;
  make_tree_node := n;
end;

{ construct_instruction - step k of the multiplication sequence e: its
  tree (a new one in ops[k] when the result is to be negated or more
  steps follow; else ops[k] is the multiply's own tree), its operator
  from rw_op_tab, its operands: for ops 0 and 1 a and a shift count (b,
  8 more for op 1), for 2 and 6 a and b, for 3..5 and 10..12 a shifted
  left (rw_shift_tab) and b, for 7..9 a and b shifted; each operand's
  use counted (correct_uc).  Whether more steps follow.

  0x21CCBA, 0x2B2 bytes, internal: e 8, k a word at 12, neg a byte at
  14, ops 16 (the array, ops[k] at 4k); the step's fields read by a
  case on k - 1 (the packed record's extracts; for k = 6 no next step);
  the shift's tree in A3 (`btst' on 16#380 for ops 7..9 taking b); a
  case of 13 on the op. }

function construct_instruction(
    e: rw_seq_ptr_t;
    k: integer;
    neg: boolean;
    var ops: rw_ptrs_t): boolean; options(val_param, internal);
var
  op, a, b: integer;
  rest: integer32;
  sh: rw_ptr_t;
  n: rw_ptr_t;
begin
  case k of
    1: begin op := e^.op1; a := e^.a1; b := e^.b1; rest := rw_steps_ptr_t(e)^.s2; end;
    2: begin op := e^.op2; a := e^.a2; b := e^.b2; rest := rw_steps_ptr_t(e)^.s3; end;
    3: begin op := e^.op3; a := e^.a3; b := e^.b3; rest := rw_steps_ptr_t(e)^.s4; end;
    4: begin op := e^.op4; a := e^.a4; b := e^.b4; rest := rw_steps_ptr_t(e)^.s5; end;
    5: begin op := e^.op5; a := e^.a5; b := e^.b5; rest := rw_steps_ptr_t(e)^.s6; end;
    6: begin op := e^.op6; a := e^.a6; b := e^.b6; rest := 0; end;
  end;
  if neg or (rest <> 0) then
    ops[k] := make_tree_node;
  if rw_shift_tab[op] = 0 then
    sh := nil
  else begin
    sh := make_tree_node;
    sh^.op := 27;
    if op in [7, 8, 9] then begin
      sh^.opnd[1] := ops[b];
      correct_opmod(sh^.desc.w6, b);
    end
    else begin
      sh^.opnd[1] := ops[a];
      correct_opmod(sh^.desc.w6, a);
    end;
    discard(correct_uc(sh^.opnd[1]));
    sh^.opnd[2] := rw_ptr_t(smcontk(81, rw_shift_tab[op]));
  end;
  n := ops[k];
  if op = 1 then
    b := b + 8;
  n^.op := rw_op_tab[op];
  case op of
    0, 1: begin
      n^.opnd[1] := ops[a];
      correct_opmod(n^.desc.w6, a);
      n^.opnd[2] := rw_ptr_t(smcontk(81, b));
    end;
    2, 6: begin
      n^.opnd[1] := ops[a];
      correct_opmod(n^.desc.w6, a);
      n^.opnd[2] := ops[b];
      correct_opmod(n^.desc.w8, b);
    end;
    3, 4, 5, 10, 11, 12: begin
      n^.opnd[1] := sh;
      n^.opnd[2] := ops[b];
      correct_opmod(n^.desc.w8, b);
    end;
    7, 8, 9: begin
      n^.opnd[1] := ops[a];
      correct_opmod(n^.desc.w6, a);
      n^.opnd[2] := sh;
    end;
    otherwise
      ;
  end;
  discard(correct_uc(n^.opnd[1]));
  discard(correct_uc(n^.opnd[2]));
  construct_instruction := rest <> 0;
end;

{ rewrite_$const_mul - the multiply node made an ISC_MUL (op 33); when
  its second operand is an integer constant m whose sequence is known
  (m, its sign taken off, and over 1023 its low zero bits shifted off,
  at most 1023; a sequence of no steps only for 1 negated or shifted),
  the multiply rewritten as the sequence's shifts, adds and subtracts
  on the first operand (converted, op 18, when its class differs from
  the descriptor's opmod1; else, unless a register candidate variable,
  op 17), then negated (op 7) and shifted left (op 27) as needed, and
  the new tree returned (else node).  The table: m32_prism_and_pa for
  an opmod1 of 2 or less, else m16_prism.  The trees are listed under
  sw10.

  0x21CF6C, 0x274 bytes: node 8; the constant kinds tested on a bit
  table of 0..207; rw_desc and rw_hdr from the node (16 and 12 bytes);
  m in D5, the shift in D3, neg in D4, `neg or shift' in D2; the entry
  e (fp-64) computed before the range test; the steps' trees in
  (-32,A6).. (ops[0] the operand, ops[1..7] the multiply's tree);
  the result in D6.

  Not known from the original: the bug check's message has no
  terminator in the image. }

function rewrite_$const_mul(
    node: rw_ptr_t): rw_ptr_t; options(val_param);
label
  1;
var
  res: rw_ptr_t;
  cst: rw_ptr_t;
  m: integer32;
  shift: integer32;
  neg: boolean;
  more: boolean;
  e: rw_seq_ptr_t;
  t: rw_ptr_t;
  x: rw_ptr_t;
  u: rw_ptr_t;
  ops: rw_ptrs_t;
  k: integer;
  i: integer;
  r: rw_ptr_t;
  n: rw_ptr_t;
begin
  if at_backend_switches.sw10 then begin
    vfmt_$write('REWRITE_$CONST_MUL -- original tree:%.');
    list_tree_$print_tree(il_$node_ptr_t(node), nil);
  end;
  rw_rewritten := true;
  res := node;
  node^.op := 33;
  cst := node^.opnd[2];
  if cst^.kind in [77..87, 101, 200] then begin
    m := cst^.ic_value;
    rw_desc := node^.desc;
    rw_hdr := rw_hdr_ptr_t(addr(node^.phase))^;
    neg := false;
    if m < 0 then begin
      m := -m;
      neg := true;
    end;
    shift := 0;
    if m > 1023 then
      while not odd(m) do begin
        m := rshft(m, 1);
        shift := shift + 1;
      end;
    more := (shift <> 0) or neg;
    if rw_desc.w6 <= 2 then
      e := addr(rw_m32[m])
    else
      e := addr(rw_m16[m]);
    if m > 1023 then
      goto 1;
    if (rw_steps_ptr_t(e)^.s1 = 0) and not (more and (m = 1)) then
      goto 1;
    node^.op := 3;
    t := make_tree_node;
    t^.opnd[1] := node^.opnd[1];
    t^.opnd[2] := node^.opnd[2];
    res := t;
    t^.uses := 0;
    x := t^.opnd[1];
    if rw_desc.rlen <> rw_desc.w6 then begin
      u := make_tree_node;
      u^.op := 18;
      u^.opnd[1] := x;
      u^.count := 1;
      u^.uses := 0;
      ops[0] := u;
      rw_desc.w6 := rw_desc.rlen;
      rw_desc.w8 := rw_desc.rlen;
    end
    else if ((x^.kind = 109) or (x^.kind = 110))
            and isc_$is_a_register_candidate(x) then
      ops[0] := x
    else begin
      u := make_tree_node;
      u^.op := 17;
      u^.opnd[1] := x;
      u^.count := 1;
      u^.uses := 0;
      ops[0] := u;
    end;
    if rw_steps_ptr_t(e)^.s1 = 0 then begin
      if m <> 1 then
        bug_check('REWRITE_$CONST_MUL: Unexpected multiplier ');
      k := 0;
    end
    else begin
      for i := 1 to 7 do
        ops[i] := t;
      k := 1;
      while construct_instruction(e, k, more, ops) do
        k := k + 1;
    end;
    r := ops[k];
    if neg then begin
      discard(correct_uc(r));
      if shift = 0 then
        n := t
      else begin
        n := make_tree_node;
        correct_opmod(n^.desc.w6, k);
      end;
      n^.opnd[1] := r;
      n^.desc.w6 := rw_desc.rlen;
      n^.op := 7;
      n^.count := 1;
      r := n;
    end;
    if shift <> 0 then begin
      discard(correct_uc(r));
      t^.desc.w6 := rw_desc.rlen;
      t^.desc.w8 := rw_desc.rlen;
      t^.op := 27;
      t^.opnd[1] := r;
      t^.opnd[2] := rw_ptr_t(smcontk(81, shift));
    end;
    if at_backend_switches.sw10 then begin
      vfmt_$write('REWRITE_$CONST_MUL -- rewritten tree:%.');
      list_tree_$print_tree(il_$node_ptr_t(t), nil);
    end;
  end;
1:
  rewrite_$const_mul := res;
end;

{ rewrite_$mul_to_aop - a multiply-assign node (aop 26) whose source is
  an integer constant made an assignment (aop 0) of the multiply's
  rewritten tree, when rewrite_$const_mul rewrites it.

  0x21D272, 0x9A bytes: node 8; rw_desc from the node's +48 (16 bytes),
  rw_hdr's phase and +8 cleared; the multiply's tree `move.l
  #16#30002,(36)' (op 3, two operands); the result node itself. }

function rewrite_$mul_to_aop(
    node: rw_ptr_t): rw_ptr_t; options(val_param);
var
  t: rw_ptr_t;
  r: rw_ptr_t;
begin
  rw_rewritten := true;
  node^.aop := 26;
  if node^.src^.kind in [77..87, 101, 200] then begin
    rw_desc := rw_desc_ptr_t(addr(node^.size))^;
    rw_hdr.phase := [];
    rw_hdr.l8 := 0;
    t := make_tree_node;
    t^.op := 3;
    t^.count := 2;
    t^.opnd[1] := node^.dst;
    t^.opnd[2] := node^.src;
    r := rewrite_$const_mul(t);
    if r^.op <> 33 then begin
      node^.aop := 0;
      node^.src := r;
    end;
  end;
  rewrite_$mul_to_aop := node;
end;

{ case_displacement - the jump table's entry for the index tree x: a
  DINDEX_NODE of the table's address constant n scaled by 4 (+40
  16#20004), used once.

  0x21D30C, 0x6C bytes, internal: x 8, n 12; rw_hdr copied to +4, then
  +4 set to 256, +22 to 2. }

function case_displacement(
    x: rw_ptr_t;
    n: rw_ptr_t): rw_ptr_t; options(val_param, internal);
var
  d: rw_ptr_t;
begin
  d := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 44);
  d^.kind := 145;
  rw_hdr_ptr_t(addr(d^.phase))^ := rw_hdr;
  d^.rf_phase := 256;
  d^.rf_uses := 1;
  d^.rf_f22.b22 := 2;
  d^.rf_l40 := 16#20004;
  d^.rf_base := n;
  d^.rf_index := x;
  case_displacement := d;
end;

{ common_piece_of_tree - n through a CSE: a parent's tree, a use's tree.

  0x21D378, 0x28 bytes, internal, no frame. }

function common_piece_of_tree(
    n: rw_ptr_t): rw_ptr_t; options(val_param, internal);
begin
  if n <> nil then
    if n^.kind = 190 then
      n := rw_ptr_t(isc_node_ptr_t(n)^.cp_tree)
    else if n^.kind = 189 then
      n := rw_ptr_t(isc_node_ptr_t(n)^.cu_tree);
  common_piece_of_tree := n;
end;

{ tree_is_a_constant - whether n is an integer constant, through CSEs
  and the unary operators 0, 7, 8, 17, 18 and 63.

  0x21D3A0, 0x72 bytes, internal: the kinds on a bit table of 0..207,
  the operators on one of 0..63. }

function tree_is_a_constant(
    n: rw_ptr_t): boolean; options(val_param, internal);
label
  1;
begin
1:
  tree_is_a_constant := true;
  if not (n^.kind in [77..87, 101, 200]) then begin
    if n^.kind = 190 then begin
      n := rw_ptr_t(isc_node_ptr_t(n)^.cp_tree);
      goto 1;
    end
    else if n^.kind = 189 then begin
      n := rw_ptr_t(isc_node_ptr_t(n)^.cu_tree);
      goto 1;
    end
    else if (n^.kind = 137) and (n^.op in [0, 7, 8, 17, 18, 63]) then begin
      n := n^.opnd[1];
      goto 1;
    end;
    tree_is_a_constant := false;
  end;
end;

{ turn_into_case_statement - whether the evaluation statement stmt and
  the conditional branches after it are a switch on one value: the
  value (stmt's tree, through a CSE: a tree of op 17 used more than 4
  times) compared for equality (opmod2 7, the constant either side) in
  each of the next uses - 1 statements (CBRANCH_NODEs taken on true),
  of a class of at most 4 bytes, the constants within 1024 and dense
  enough (4 per branch less 5 at least the range).  If so: rw_desc a
  longword's, the value widened (op 18, signed for a negative low)
  when narrower; low taken as 0 when between 1 and 7; low, high, the
  default label (the branch's target, or a label node put before the
  statement after the chain), the next statement, the case table
  (zzzzz_$preallocate_case_table, the branches' labels by constant,
  the default elsewhere) and the value returned, done set.

  0x21D41A, 0x2B4 bytes, internal: stmt 8; next 12, table 16, default
  20, value 24, low 28, high 32, done 36 by address; low and high in
  D5, D6 (16#7FFFFFFF, 16#80000000 at first), the count in D3; a new
  label node from gspace (84 bytes); the table's entries from +20 by
  the constants' low words less low (`move.w (10,A1); sub.w D5;
  lsl.w #2'); the default's loop `dbf' with the word counter's
  borrow. }

function turn_into_case_statement(
    stmt: rw_ptr_t;
    var next: rw_ptr_t;
    var table: rw_case_table_ptr_t;
    var dflt: rw_ptr_t;
    var value: rw_ptr_t;
    var low: integer32;
    var high: integer32;
    var done: boolean): boolean; options(val_param, internal);
label
  1;
var
  ok: boolean;
  t: rw_ptr_t;
  cnt: integer32;
  lo, hi: integer32;
  br: rw_ptr_t;
  i: integer32;
  cmp: rw_ptr_t;
  k: rw_ptr_t;
  v: integer32;
  range: integer32;
  lab: rw_ptr_t;
  tbl: rw_case_table_ptr_t;
  sz: integer32;
begin
  ok := false;
  t := stmt^.st_p52;
  if t = nil then
    goto 1;
  t := common_piece_of_tree(t);
  cnt := t^.uses - 1;
  if cnt < 4 then
    goto 1;
  if (t^.kind <> 137) and (t^.kind <> 138) then
    goto 1;
  if t^.op <> 17 then
    goto 1;
  lo := 16#7FFFFFFF;
  hi := 16#80000000;
  br := stmt^.next;
  i := cnt;
  while i > 0 do begin
    if br^.kind <> 142 then
      goto 1;
    if not br^.cb_f60.on_true then
      goto 1;
    cmp := br^.st_p56;
    if cmp^.kind <> 143 then
      goto 1;
    if cmp^.desc.w8 <> 7 then
      goto 1;
    if common_piece_of_tree(cmp^.opnd[1]) <> t then begin
      if common_piece_of_tree(cmp^.opnd[2]) <> t then
        goto 1;
      k := cmp^.opnd[1];
      cmp^.opnd[1] := cmp^.opnd[2];
      cmp^.opnd[2] := k;
    end;
    value := cmp^.opnd[1];
    k := cmp^.opnd[2];
    if not (k^.kind in [77..87, 101, 200]) then
      goto 1;
    v := k^.ic_value;
    if v < lo then
      lo := v;
    if v > hi then
      hi := v;
    br := br^.next;
    i := i - 1;
  end;
  if t^.desc.rlen = 0 then
    goto 1;
  if (t^.desc.rlen < 0) or (t^.desc.rlen > 4) then
    goto 1;
  range := hi - lo;
  if range >= 1024 then
    goto 1;
  if range <= 0 then
    goto 1;
  if cnt * 4 - 5 < range then
    goto 1;
  ok := true;
  rw_desc := rw_long_desc;
  rw_hdr.phase := [];
  rw_hdr.l8 := 0;
  if (t^.desc.rlen >= 0) and (t^.desc.rlen < 4) then begin
    t^.op := 18;
    t^.desc.flags.signed := lo < 0;
    t^.desc.w6 := t^.desc.rlen;
    t^.desc.rlen := 4;
  end;
  if (lo > 0) and (lo < 8) then begin
    lo := 0;
    range := hi;
  end;
  low := lo;
  high := hi;
  if br^.kind = 141 then begin
    dflt := br^.st_p48;
    next := br^.next;
  end
  else begin
    if br^.kind = 144 then
      lab := br
    else begin
      lab := gspace(84);
      lab^.kind := 144;
      lab^.prev := br^.prev;
      br^.prev^.next := lab;
      lab^.next := br;
      br^.prev := lab;
    end;
    dflt := lab;
    next := lab;
  end;
  sz := range + 1;
  tbl := rw_case_table_ptr_t(zzzzz_$preallocate_case_table(sz));
  table := tbl;
  br := stmt^.next;
  while cnt > 0 do begin
    v := br^.st_p56^.opnd[2]^.ic_low - lo;
    tbl^.labels[v] := sym_$backend_label_for_case_jump(br^.st_p48);
    br := br^.next;
    cnt := cnt - 1;
  end;
  for i := 0 to range do
    if tbl^.labels[i] = nil then
      tbl^.labels[i] := sym_$backend_label_for_case_jump(dflt);
  done := true;
1:
  turn_into_case_statement := ok;
end;

{ rewrite_$check_for_case_statement - the evaluation statement stmt and
  the branches after it made a case statement (on the PRISM: target
  properties' p_10 = 3) when turn_into_case_statement agrees and its
  value is not constant: a 214 CASE_NODE_RANGE_CHECK (the value less
  low compared unsigned, opmod2 3, with high less low, the default for
  out of range) or a 215 CASE_NODE_NO_RANGE_CHECK, the table's address
  (an address constant of the case node itself, through an op 17 tree
  with a range check), the jump through case_displacement, put after
  stmt and before the chain's end.

  0x21D6CE, 0x1F4 bytes: stmt 8; rw_rewritten cleared; the results in
  frame cells, then D2..D7; the case node from gspace (68 bytes), its
  statement fields from stmt's; the value less low by a SUB (op 2) or,
  for a negative low, an ADD (op 1) of its magnitude; `move.l
  #16#400000,(4)' and `#16#110001,(36)' in the range check's op 17
  tree. }

procedure rewrite_$check_for_case_statement(
    stmt: rw_ptr_t); options(val_param);
var
  next: rw_ptr_t;
  table: rw_case_table_ptr_t;
  dflt: rw_ptr_t;
  value: rw_ptr_t;
  low, high: integer32;
  done: boolean;
  s: rw_ptr_t;
  t: rw_ptr_t;
  a: rw_ptr_t;
  c: rw_ptr_t;
begin
  rw_rewritten := false;
  if target_properties.p_10 <> 3 then
    return;
  if stmt = nil then
    return;
  if stmt^.kind <> 139 then
    return;
  if stmt^.ev_count = 0 then
    return;
  if stmt^.next = nil then
    return;
  if stmt^.next^.kind <> 142 then
    return;
  if tree_is_a_constant(stmt^.st_p52) then
    return;
  if not turn_into_case_statement(stmt, next, table, dflt, value, low,
                                  high, done) then
    return;
  s := gspace(68);
  s^.top := stmt^.top;
  s^.line := stmt^.line;
  s^.l42 := (s^.l42 & 16#FF0000FF) ! (stmt^.l42 & 16#FFFF00);
  if low <> 0 then begin
    high := high - low;
    t := make_tree_node;
    if low > 0 then
      t^.op := 2
    else begin
      low := -low;
      t^.op := 1;
    end;
    t^.count := 2;
    t^.uses := 1;
    t^.opnd[1] := value;
    t^.opnd[2] := rw_ptr_t(smcontk(81, low));
    value := t;
  end;
  a := rw_ptr_t(get_proc_addr_con(6, il_$node_ptr_t(s),
           rw_ptr_t(il_180)^.bk_l188, rw_ptr_t(il_180)^.bk_sect));
  if not done then
    s^.kind := 215
  else begin
    s^.kind := 214;
    t := make_tree_node;
    t^.uses := 2;
    t^.phase := [22];
    t^.op := 17;
    t^.count := 1;
    t^.opnd[1] := a;
    a := t;
    s^.st_p56 := a;
    c := make_tree_node;
    c^.kind := 143;
    c^.op := 12;
    c^.desc.w8 := 3;
    c^.count := 2;
    c^.opnd[1] := value;
    discard(correct_uc(value));
    c^.opnd[2] := rw_ptr_t(smcontk(81, high));
    s^.st_p60 := c;
    s^.st_p64 := dflt;
  end;
  s^.st_p48 := case_displacement(value, a);
  s^.st_p52 := rw_ptr_t(table);
  s^.st_p64 := dflt;
  s^.next := next;
  s^.prev := stmt;
  stmt^.next := s;
  next^.prev := s;
end;

{ make_call_to_rws_$alloc_temp - a call (op 16, an address, two
  operands) of the run-time routine rws_$alloc_temp (its library
  descriptor, at_lib_dsc +16#10EC) for size bytes (a constant of kind
  82).

  0x21D8C2, 0x64 bytes, internal: size 8; `lea 0x2B6350'. }

function make_call_to_rws_$alloc_temp(
    size: integer32): rw_ptr_t; options(val_param, internal);
var
  n: rw_ptr_t;
begin
  n := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 48);
  n^.kind := 137;
  n^.op := 16;
  n^.desc.size := 4;
  n^.desc.rlen := 5;
  n^.count := 2;
  n^.opnd[1] := rw_ptr_t(addr(at_lib_dsc[16#10EC]));
  n^.opnd[2] := rw_ptr_t(smcontk(82, size));
  make_call_to_rws_$alloc_temp := n;
end;

{ rewrite_$entry - the entry statement node of a routine (or an entry
  block's routine) with more than 128K of dynamic frame: its XSB
  pointer made first if needed, then assignments after node of the
  dynamic area's base (the routine's +180 record's +24) from a call of
  rws_$alloc_temp, and with -DBS or -DBA a copy of it in a new
  temporary (marked +35 bit 0; the routine's +72); the frame size
  cleared; no_xsb says whether this was done.  A BLOCK_ENTRY_NODE of
  the routine after them: second.

  0x21D926, 0x174 bytes: node 8, no_xsb 12, second 16 (lir_main's
  +0xDB4 and +0xD9C); `cmpi.l #16#20000,(176,A2); bgt'; the debug
  level from cargs +0x282 bits 16..15 (the db field, `bcs' on 2); the
  assignments 80 bytes from lir's heap, the block entry 52. }

procedure rewrite_$entry(
    node: univ_ptr;
    var no_xsb: boolean;
    var second: univ_ptr); options(val_param);
var
  stmt: rw_ptr_t;
  b: rw_ptr_t;
  nxt: rw_ptr_t;
  x: rw_ptr_t;
  a: rw_ptr_t;
  a2: rw_ptr_t;
  tmp: rw_ptr_t;
  e: rw_ptr_t;
begin
  rw_rewritten := false;
  stmt := node;
  b := stmt^.st_p48;
  if b^.kind = 167 then
    b := b^.bk_routine;
  nxt := stmt^.next;
  x := b^.bk_xdynm;
  if x = nil then
    b^.bk_dynamic := 0;
  if b^.bk_dynamic <= 16#20000 then
    no_xsb := false
  else begin
    no_xsb := true;
    if x^.top <> nil then begin
      discard(make_xdynm_ptr(il_$node_ptr_t(b), 0));
      x := b^.bk_xdynm;
    end;
    a := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
    a^.kind := 140;
    stmt^.next := a;
    a^.size := 4;
    a^.rlen := 5;
    a^.prev := stmt;
    a^.aop := 0;
    a^.src := make_call_to_rws_$alloc_temp(b^.bk_dynamic);
    a^.dst := x^.rf_base;
    stmt := a;
    if cargs_$options.db >= 2 then begin
      a2 := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 80);
      a2^.kind := 140;
      a^.next := a2;
      a2^.size := 4;
      a2^.rlen := 5;
      a2^.prev := a;
      a2^.aop := 0;
      a2^.src := x^.rf_base;
      tmp := make_expression_temporary(122, 32);
      tmp^.vr_attr := tmp^.vr_attr ! 1;
      a2^.dst := tmp;
      b^.bk_p72 := tmp;
      stmt := a2;
    end;
    b^.bk_dynamic := 0;
  end;
  e := mrh_$alloc(rw_heap_ptr_t(addr(lir_3f60))^, 52);
  stmt^.next := e;
  e^.kind := 148;
  e^.prev := stmt;
  e^.st_p48 := b;
  e^.next := nxt;
  second := e;
end;

{ rewrite_$agg_aop - the aggregate assignment node made an ISC_AGG
  (aop 34) of a word-sized fill's shape: an ASSIGN_NODE (aop 6, the
  source, w56 0) to a CSE of the destination (a tree of op 0 and class
  9 over it, its parent and use, unless the destination is a variable
  or FORTRAN symbol) and, after it, the ISC_AGG with the DISP_NODE of
  the destination's end (size less w56) and the constants 32 and w56;
  node's next becomes the ISC_AGG.  Returns the source's assignment
  (not linked: the caller's).

  0x21DA9A, 0x22A bytes: node 8; the fields read first (next D7, top,
  line D3, the index D4, w56 zero-extended D6, rlen D5, size D1, the
  destination A3, the source); every new node from the ISC's preserved
  heap (isc_user_routines +0x224). }

function rewrite_$agg_aop(
    node: rw_ptr_t): rw_ptr_t; options(val_param);
var
  nxt: rw_ptr_t;
  top: univ_ptr;
  line: integer;
  stmt: integer32;
  w56: integer32;
  rlen: integer;
  len: integer32;
  dst: rw_ptr_t;
  src: rw_ptr_t;
  p: rw_ptr_t;
  t: rw_ptr_t;
  u: rw_ptr_t;
  d: rw_ptr_t;
  k32: rw_ptr_t;
  kw: rw_ptr_t;
  a: rw_ptr_t;
  b: rw_ptr_t;
begin
  rw_rewritten := true;
  nxt := node^.next;
  top := node^.top;
  stmt := rshft(node^.l42 & 16#FFFF00, 8);
  line := node^.line;
  w56 := node^.w56 & 16#FFFF;
  rlen := node^.rlen;
  dst := node^.dst;
  src := node^.src;
  len := node^.size - w56;
  if (dst^.kind = 110) or (dst^.kind = 109) then
    p := dst
  else begin
    t := mrh_$alloc(isc_preserve_heap, 44);
    t^.kind := 137;
    t^.rewritten := true;
    rw_hdr_ptr_t(addr(t^.phase))^.l8 := integer32(node);
    t^.op := 0;
    t^.desc.rlen := 9;
    t^.desc.size := len;
    t^.opnd[1] := dst;
    p := mrh_$alloc(isc_preserve_heap, 28);
    p^.kind := 190;
    p^.rewritten := true;
    isc_node_ptr_t(p)^.cp_tree := isc_node_ptr_t(t);
    u := mrh_$alloc(isc_preserve_heap, 36);
    u^.kind := 189;
    u^.rewritten := true;
    isc_node_ptr_t(u)^.cu_tree := isc_node_ptr_t(t);
    isc_node_ptr_t(u)^.cu_parent := isc_node_ptr_t(p);
    dst := u;
  end;
  d := mrh_$alloc(isc_preserve_heap, 36);
  d^.kind := 147;
  d^.rewritten := true;
  d^.rf_f22.b23 := 0;
  d^.rf_disp := len;
  d^.rf_base := dst;
  d^.rf_l28 := 0;
  k32 := mrh_$alloc(isc_preserve_heap, 12);
  k32^.kind := 81;
  k32^.rewritten := true;
  k32^.ic_value := 32;
  kw := mrh_$alloc(isc_preserve_heap, 12);
  kw^.kind := 81;
  kw^.rewritten := true;
  kw^.ic_value := w56;
  a := mrh_$alloc(isc_preserve_heap, 80);
  a^.kind := 140;
  a^.rewritten := true;
  a^.next := nxt;
  a^.top := top;
  a^.line := line;
  a^.l42 := (a^.l42 & 16#FF0000FF) ! lshft(stmt, 8);
  a^.dst := d;
  a^.src := k32;
  a^.x72 := kw;
  a^.aop := 34;
  a^.rlen := 1;
  b := mrh_$alloc(isc_preserve_heap, 80);
  b^.kind := 140;
  b^.rewritten := true;
  b^.next := a;
  b^.top := top;
  b^.line := line;
  b^.l42 := (b^.l42 & 16#FF0000FF) ! lshft(stmt, 8);
  b^.dst := p;
  b^.src := src;
  b^.aop := 6;
  b^.w56 := 0;
  b^.rlen := rlen;
  b^.size := len;
  node^.next := a;
  rewrite_$agg_aop := b;
end;
