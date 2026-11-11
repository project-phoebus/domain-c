{ add_node - ADD_NODE, building IL nodes: the C front end's tree nodes
  over its expression stack (add_tn, with the constant folding and the
  reassociations it does on the way), the reference nodes (add_disp_node,
  add_dn, add_sdn, add_dindexn, add_pn), buildtreenode, the phase a node
  carries (getphase), copying a tree (copy_tree) and making and
  disposing of top-level nodes.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x09F9A4  0x0A1384  get_next_symbol
    0x09F9A6  0x0A1386  char_maxlen
    0x09F9BC  0x0A139C  make_temp
    0x09F9D6  0x0A13B6  make_char_temp
    0x09F9F0  0x0A13D0  init_aux_ftn
    0x09F9F2  0x0A13D2  add_top_node
    0x09FA3E  0x0A141E  push
    0x09FA6E  0x0A144E  phasefromvatt
    0x09FAD4  0x0A14B4  getphase
    0x09FBAE  0x0A158E  walk_it
    0x09FF08  0x0A18E8  copy_tree
    0x0A04E4  0x0A1EC4  invariant_sizeof_top_level
    0x0A05EE  0x0A1FCE  add_node_$dispose_top_level
    0x0A1190  0x0A2B70  add_node_$new_top_level
    0x0A1262  0x0A2C42  add_routine_reference
    0x0A1300  0x0A2CE0  add_disp_node
    0x0A13D6  0x0A2DB6  add_dn
    0x0A13FE  0x0A2DDE  add_sdn
    0x0A14F8  0x0A2ED8  add_dindexn
    0x0A1652  0x0A3032  add_pn
    0x0A18C2  0x0A32A2  distribute (in add_tn)
    0x0A1ABC  0x0A349C  add_tn
    0x0A4C54  0x0A6634  buildtreenode
    A5 0x2C2080 (cc.m68k), 0x4420F0 (cc.a88k): the module's data, 56
    bytes: +0 swap_cc (16 words, initialized), +0x20 cc_call_len (a
    longword; +0x22, its low word, is read as a word), +0x28..+0x37
    four longwords 127, 32767, 255, 65535 that no routine of the unit
    reads.  The file the messages go to is the run time's (-4,A5).

  get_next_symbol and init_aux_ftn are lone `rts' (docs/rev889-
  patterns.md 13); char_maxlen, make_temp and make_char_temp load A5 and
  return 0 or nil: the C compiler's stand-ins for what the other
  compilers' front ends supply.  phasefromvatt and
  invariant_sizeof_top_level do not load A5 and have no frame
  (internal); distribute is nested in add_tn (it takes add_tn's frame
  from its dynamic link, docs/rev889-patterns.md 25); every other
  routine is global and loads A5.  The routines only this unit calls
  are declared here (add_node.ins.pas).

  The IL node kinds have names in the image: add_node_$dispose_top_level
  and add_node_$new_top_level write a kind as an enumerated value, and
  the run time's name table for the enumeration follows the routine
  (cc.m68k 0x0A06A6: 237 names, END_OB 0 .. UNION_OB 236; 137
  TREE_NODE, 145 DINDEX_NODE, 146 PTR_NODE, 147 DISP_NODE, 205
  SYM_DISP_NODE, ...).  The enumeration is declared here as an_kind_t
  for those writes (CHAR_TYPE and VOID_TYPE as kind_char_type and
  kind_void_type: c_globals.ins.pas has cells of those names);
  elsewhere the kinds are numbers, as in the other units
  (docs/questions.md 78).  The nodes are read through the unit's
  an_node_t, the expression stack through c_objtype's c_exp_t.

  dpc gaps (docs/dpc-gaps.md): 4 (writeln), 7 (real constants and
  arithmetic), 8 (`in' on the node kind and operator sets), 11
  (make_temp, make_char_temp), 15 (add_disp_node), 25 (add_tn).

  Not known from the original: every name of the module's variables
  and locals, an_node_t's, the enumeration type's (its constants are
  the image's); the meaning of the operator codes.
}
module add_node;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pfm.ins.pas';
%include 'us/us/ins/fpp_errs.ins.pas';
%include 'us/us/ins/peb.ins.pas';
%include 'us/us/ins/error.ins.pas';
%include '/sys/ins/error.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';

type
  { The IL node kinds, as the image names them (the enumeration's name
    table after add_node_$dispose_top_level). }
  an_kind_t = (
    end_ob, if_ob, then_ob, begin_ob, else_ob, do_ob, with_ob, in_ob,
    of_ob, while_ob, case_ob, repeat_ob, until_ob, procedure_ob, var_ob,
    for_ob, array_ob, record_ob, set_ob, to_ob, downto_ob, mod_ob, or_ob,
    and_ob, not_ob, div_ob, const_ob, type_ob, function_ob, program_ob,
    packed_ob, label_ob, goto_ob, file_ob, forward_ob, static_ob,
    external_ob, define_ob, module_ob, val_param_ob, exit_ob, next_ob,
    internal_ob, return_ob, otherwise_ob, cast_ob, univ_ob, implies_ob,
    out_ob, up_to_ob, bus_ob, period_ob, becomes_ob, colon_ob, le_ob,
    ne_ob, lt_ob, eq_ob, ge_ob, gt_ob, sub_ob, open_ob, close_ob,
    comma_ob, semicolon_ob, star_ob, slash_ob, plus_ob, minus_ob,
    ampersand_ob, excl_ob, arrow_ob, eom_ob, error_ob, tilde_ob,
    badchar_ob, id_ob, blogical_ob, slogical_ob, llogical_ob,
    sinteger_ob, integer_ob, linteger_ob, usinteger_ob, uinteger_ob,
    ulinteger_ob, ubinteger_ob, char_ob, real_ob, dpreal_ob, complex_ob,
    varying_ob, char_string_ob, char32_string_ob, nil_ob, starstar_ob,
    routine_option_ob, attribute_ob, begin_critical_ob,
    end_critical_ob, library_ob, char16_ob, const_cob, volatile_cob,
    signed_cob, program_blk, module_blk, procedure_blk, function_blk,
    var_name, fortran_symbol, common_block_name, fdim_info, fdata_nlist,
    fdata_clist, equiv_stmt, const_name, label_name, type_name,
    field_name, pfield_name, param_name, integer_type, real_type,
    bool_type, kind_char_type, char_string_con_type, char_array_type,
    subr_type, enum_type, ptr_type, array_type, record_type, file_type,
    set_type, univ_ptr_type, null_set_type, tree_node, gen_tree_node,
    eval_node, assign_node, branch_node, cbranch_node, cmp_tree_node,
    label_node, dindex_node, ptr_node, disp_node, block_entry_node,
    blk_end_node, nlbranch_node, return_node, alloc_temp, sb_register,
    db_register, display_register, set_con_ob, def_const_ob, std_func,
    lib_dsc, ref_list, state_save, lnum_entry, addr_con, cs_node,
    cs_temp, fdata_do, entry_blk, param_list, ftn_xref, ptr_hdr,
    cc_call, inner_blk, proc__type, func__type, pf_call, rec_const_ob,
    offset_type, reg_assign_ob, actparam, ext_state_save, dead_temp,
    procedure_section, data_section, inline_constant, namelist_id_ob,
    lnref_ob, variant_ob, use_def_ob, cse_use_ob, cse_parent_ob,
    reg_list_ob, transfer_vector, proc_reloc, external_ref,
    reloc_absolute_addr_con, varying_type, parray_type, dpcomplex_ob,
    m68k_unpacked, binteger_ob, routine_option_name, attribute_name,
    physical_register_ob, argument_block_location_ob, sym_disp_node,
    dynamic_array_type, dope_vector, at_lib_dsc, blockdata_blk,
    kind_void_type, ap_register, namelist_constant_ob, undefined_object,
    case_node_range_check, case_node_no_range_check, defaulted_info,
    char16_type, char16_array_type, isc_fetch, isc_convert,
    fdata_default_seq, exception_frame, exception_handler_entry,
    raise_exception, release_dynamic_space, exception_register,
    insert_bit_field, bit_field_assign, lb_register, virt_var_name,
    spine_mark, isc_share, pa_mmu_bip, cc_func_returning_type,
    indexed_reference, union_ob);

  { The 12 bytes from +4 copy_tree copies whole. }
  an_hdr_t = array [1..3] of integer32;

  { A node as this unit reads and builds it, by kind. }
  an_ptr_t = ^an_node_t;
  an_node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      { A tree node (137 TREE_NODE, 138, 143 CMP_TREE_NODE). }
      1: (phase: add_node_$phase_t;     { +4 }
          w8: integer;                  { +8 }
          regs: integer;                { +10: the registers its
                                          evaluation needs (add_tn) }
          l12: integer32;               { +12 }
          uses: integer;                { +16: the use count }
          w18: integer;                 { +18 }
          desc: add_node_$desc_t;       { +20 }
          op: integer;                  { +36: the operator }
          count: integer;               { +38: the operands }
          opnd: array [1..64] of il_$node_ptr_t);  { +40 }
      { A reference: 145 DINDEX_NODE, 146 PTR_NODE, 147 DISP_NODE, 205
        SYM_DISP_NODE. }
      2: (rf_phase: add_node_$phase_t;  { +4 }
          rf_w8: integer;               { +8 }
          rf_w10: integer;              { +10 }
          rf_w12: integer;              { +12 }
          rf_w14: integer;              { +14 }
          rf_w16: integer;              { +16 }
          rf_w18: integer;              { +18 }
          rf_w20: integer;              { +20 }
          align: char;                  { +22 }
          b23: char;                    { +23 }
          base: il_$node_ptr_t;         { +24 }
          sym: il_$node_ptr_t;          { +28 }
          disp: integer32;              { +32 }
          index: il_$node_ptr_t;        { +36 }
          rf_w40: integer;              { +40 }
          len: integer);                { +42 }
      3: (hdr: an_hdr_t;                { +4 }
          w16: integer32);              { +16: the use count and +18 }
      { An integer constant (77..87, 101, 200). }
      4: (ic_next: il_$node_ptr_t;      { +4 }
          int_value: integer32);        { +8 }
      { A real constant (88 REAL_OB, 89 DPREAL_OB). }
      5: (rc_next: il_$node_ptr_t;      { +4 }
          rc_unused_8: integer32;       { +8 }
          real_value: double);          { +12 }
      { The attributes getphase reads: a variable's (109 VAR_NAME, +32),
        kind 110's (+24), a type name's (118, +36), a field's (119,
        120: +20, its type +16) and a parameter's type (121, +16). }
      6: (at_unused_4: an_hdr_t;        { +4 }
          at_node: il_$node_ptr_t;      { +16 }
          at_20: add_node_$phase_t;     { +20 }
          at_24: add_node_$phase_t;     { +24 }
          at_unused_28: integer32;      { +28 }
          at_32: add_node_$phase_t;     { +32 }
          at_36: add_node_$phase_t);    { +36 }
      { By offset, as il.ins.pas's views. }
      9: (xp: array [1..94] of il_$node_ptr_t);     { +4 }
      11: (xl: array [1..94] of integer32);         { +4 }
      12: (xl2_pad: integer;                        { +4 }
           xl2: array [1..93] of integer32);        { +6 }
      13: (xw: array [2..189] of integer);          { +4 }
      14: (xc: array [4..379] of char);             { +4 }
  end;

  { A double and its two longwords (add_tn's division by a power of
    two). }
  an_dbl_t = record
    case integer of
      1: (d: double);
      2: (hi: integer32;
          lo: integer32);
  end;

  { A descriptor's 16 bytes (add_tn clears them one by one). }
  an_bytes_t = array [1..16] of char;
  an_bytes_ptr_t = ^an_bytes_t;

{ REG_SAVE - lang/lang/source/reg_save.pas 0x0ED478 (cc.a88k's
  target_at_dummies.pas 0x27B6C0, which returns []): the registers the
  statement or object n preserves; add_tn tests 18..23 of a call's.
  Declared here: add_node opens no insert of reg_save's. }
function reg_save(
    n: il_$node_ptr_t): add_node_$phase_t; options(val_param); extern;

{ KFOLD - kfold.pas 0x0AF444 (cc.a88k 0x0AF6C4): fold the constants of
  the tree t, whose parent (by address) add_tn passes as a nil constant.
  Declared here as in c_syntax: no kfold insert is known
  (docs/questions.md 64). }
procedure kfold(
    in parent: il_$node_ptr_t;
    var t: il_$node_ptr_t); extern;

type
  an_std_lib_words_ptr_t = ^an_std_lib_words_t;
  an_std_lib_words_t = array [0..365] of integer;  { std_lib as words }

var
  { +0: the condition code of a comparison whose operands add_tn
    swaps, by the code (a code of a word less, 6 and 7 equal and not
    equal kept: cc.m68k .rwdi at 0x2C2080). }
  swap_cc: array [0..15] of integer := [0, 1, 5, 4, 3, 2, 6, 7, 8, 9,
                                        15, 14, 15, 14, 13, 12];
  { +0x20: the bytes beyond 20 of the call node (171 CC_CALL) copy_tree
    copies, set from the call tree that holds it (its operands' 4 bytes
    each after the first). }
  cc_call_len: integer32;
  { +0x28: four longwords the unit does not read. }
  an_limits: array [1..4] of integer32 := [127, 32767, 255, 65535];

  { The section std_lib (lang/dervobjs std_lib.pas, cc.m68k 0x2D2B68,
    0x2DC bytes, no routines) is the prelude's std_lib_rtns
    (globals_from_backend.ins.pas); copy_tree reads the word at +706 +
    2 * the call's result class, through this view of it. }

{ get_next_symbol - nothing (the C compiler's stand-in).

  0x09F9A4, 0x2 bytes: `rts'.

  Not known from the original:
  - the parameters, if any. }

procedure get_next_symbol;
begin
end;

{ char_maxlen - the greatest length of a character call's result: 0
  (the C compiler's stand-in).

  0x09F9A6, 0x16 bytes, link #-4: `clr.w D0'; copy_tree passes the call
  (`pea (A0)' of the node).

  Not known from the original:
  - the parameter's name and type. }

function char_maxlen(
    t: il_$node_ptr_t): integer; options(val_param);
begin
  char_maxlen := 0;
end;

{ make_temp - a temporary of the class cls: nil (the C compiler's
  stand-in).

  0x09F9BC, 0x1A bytes, link #-4: `movea.l #0,A0'.

  Not known from the original:
  - the parameter's name. }

function make_temp(
    cls: integer): il_$node_ptr_t; options(val_param);
begin
  make_temp := nil;
end;

{ make_char_temp - a character temporary of len characters: nil (the C
  compiler's stand-in).

  0x09F9D6, 0x1A bytes, link #-4: `movea.l #0,A0'.

  Not known from the original:
  - the parameter's name. }

function make_char_temp(
    len: integer): il_$node_ptr_t; options(val_param);
begin
  make_char_temp := nil;
end;

{ init_aux_ftn - set up the descriptor d for the class cls: nothing
  (the C compiler's stand-in).

  0x09F9F0, 0x2 bytes: `rts'; copy_tree passes an assignment's +48 by
  address and a word.

  Not known from the original:
  - the names. }

procedure init_aux_ftn(
    var d: univ add_node_$desc_t;
    cls: integer); options(val_param);
begin
end;

{ add_top_node - a new top-level node of kind, size bytes, chained in
  after the others (c_stmt_sem's link_top).

  0x09F9F2, 0x4C bytes, link #-12: kind and size by address (copy_tree
  passes constants), size through a frame word; gspace(size), the kind
  at +2, link_top; the node in A0.

  Not known from the original:
  - the names. }

function add_top_node(
    in kind: integer;
    in size: integer): il_$node_ptr_t;
var
  n: il_$node_ptr_t;
begin
  n := gspace(size);
  n^.kind := kind;
  link_top(n);
  add_top_node := n;
end;

{ push - push the tree n on the expression stack (cexs_stack, top
  cexs_23bc).

  0x09FA3E, 0x30 bytes, link #0: n by address; `addq.w #1' of the top,
  the entry `lsl.w #6' (64 bytes an entry).

  Not known from the original:
  - the names. }

procedure push(
    in n: il_$node_ptr_t);
begin
  cexs_23bc := cexs_23bc + 1;
  cexs_stack[cexs_23bc].node := n;
end;

{ phasefromvatt - the phase that a variable's attributes v give.

  0x09FA6E, 0x66 bytes, no frame, no A5: v at (4,SP); bit 0 gives
  16#10002 (assigned), then bit 3 adds 3, 4 adds 4, 1 adds 0, 2 adds 19,
  5 adds 20, 8 adds 2, 12 adds 1 (`btst; beq; ori.l'); the result in D0.

  Not known from the original:
  - the names; what the attributes are. }

function phasefromvatt(
    v: add_node_$phase_t): add_node_$phase_t; internal; options(val_param);
var
  p: add_node_$phase_t;
begin
  p := [];
  if 0 in v then
    p := [1, 16];
  if 3 in v then
    p := p + [3];
  if 4 in v then
    p := p + [4];
  if 1 in v then
    p := p + [0];
  if 2 in v then
    p := p + [19];
  if 5 in v then
    p := p + [20];
  if 8 in v then
    p := p + [2];
  if 12 in v then
    p := p + [1];
  phasefromvatt := p;
end;

{ getphase - see add_node.ins.pas.

  0x09FAD4, 0xC0 bytes, link #-12: nil gives 0; the kinds in the set at
  0x09FB94 (137, 138, 143, 145..147, 164, 171, 175, 189, 205: `move.w
  #207; sub.w; bcs; btst') give +4; else a jump table over 109..121:
  109 phasefromvatt(+32), 118 (+36), 110 (+24), 121 getphase(+16), 119
  and 120 getphase(+16) + phasefromvatt(+20) (`or.l' with a frame
  temporary); the others 0.

  Not known from the original:
  - the names. }

function getphase;
var
  t: an_ptr_t;
begin
  t := n;
  if t = nil then
    getphase := []
  else if t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    getphase := t^.phase
  else
    case t^.kind of
      109: getphase := phasefromvatt(t^.at_32);
      118: getphase := phasefromvatt(t^.at_36);
      121: getphase := getphase(t^.at_node);
      119, 120: getphase := getphase(t^.at_node) + phasefromvatt(t^.at_20);
      110: getphase := phasefromvatt(t^.at_24);
      otherwise
        getphase := [];
    end;
end;

{ walk_it - apply walker to the tree n (by address) and then to each
  tree below it, by kind.

  0x09FBAE, 0x35A bytes, link #-8: nil returns; `jsr (A0)' of the
  walker; then a jump table over 137..233 (`subi.w #137; cmpi.w #97'):
  148 BLOCK_ENTRY_NODE +48; 144 LABEL_NODE +64, +68; 150, 141, 224,
  225, 151, 233 +48; 142 CBRANCH_NODE +48, +56; 139 EVAL_NODE the +50
  operands from +52 (`clr.l; move.w': unsigned); 140 ASSIGN_NODE +64,
  +68; 227 +64, +68, +72; 228 +48, +52, +56, +60, +64; 137, 138, 143
  the +38 operands from +40 (`ext.l'); 164 +20, +24; 175 +16, +20; 171
  +16; 219, 220 +4; 205, 147, 146 +24, +28; 145 +24, +28, +36; others
  nothing.  The loops count 32 bits (`dbf' and a borrow).  No caller
  outside itself.

  Not known from the original:
  - the names. }

procedure walk_it(
    var n: il_$node_ptr_t;
    walker: c_walker_t); options(val_param);
var
  i: integer32;
begin
  if n = nil then
    return;
  walker^(n);
  case n^.kind of
    148: walk_it(n^.xp[12], walker);
    144: begin
      walk_it(n^.xp[16], walker);
      walk_it(n^.xp[17], walker);
    end;
    150: walk_it(n^.xp[12], walker);
    141: walk_it(n^.xp[12], walker);
    142: begin
      walk_it(n^.xp[12], walker);
      walk_it(n^.xp[14], walker);
    end;
    224: walk_it(n^.xp[12], walker);
    225: walk_it(n^.xp[12], walker);
    151: walk_it(n^.xp[12], walker);
    233: walk_it(n^.xp[12], walker);
    139:
      for i := 1 to c_top_ptr_t(n)^.eval_count do
        walk_it(n^.xp[12 + i], walker);
    140: begin
      walk_it(n^.xp[16], walker);
      walk_it(n^.xp[17], walker);
    end;
    227: begin
      walk_it(n^.xp[16], walker);
      walk_it(n^.xp[17], walker);
      walk_it(n^.xp[18], walker);
    end;
    228: begin
      walk_it(n^.xp[12], walker);
      walk_it(n^.xp[13], walker);
      walk_it(n^.xp[14], walker);
      walk_it(n^.xp[15], walker);
      walk_it(n^.xp[16], walker);
    end;
    137, 138, 143:
      for i := 1 to an_ptr_t(n)^.count do
        walk_it(n^.xp[9 + i], walker);
    164: begin
      walk_it(n^.xp[5], walker);
      walk_it(n^.xp[6], walker);
    end;
    175: begin
      walk_it(n^.xp[4], walker);
      walk_it(n^.xp[5], walker);
    end;
    171: walk_it(n^.xp[4], walker);
    219, 220: walk_it(n^.xp[1], walker);
    205: begin
      walk_it(n^.xp[6], walker);
      walk_it(n^.xp[7], walker);
    end;
    147: begin
      walk_it(n^.xp[6], walker);
      walk_it(n^.xp[7], walker);
    end;
    146: begin
      walk_it(n^.xp[6], walker);
      walk_it(n^.xp[7], walker);
    end;
    145: begin
      walk_it(n^.xp[6], walker);
      walk_it(n^.xp[7], walker);
      walk_it(n^.xp[9], walker);
    end;
    otherwise ;
  end;
end;

{ copy_tree - see add_node.ins.pas.

  0x09FF08, 0x5A8 bytes, link #-64: nil, and kinds outside the set at
  0x0A04B0 (137, 138, 143, 145..147, 164, 171, 175, 205), give n; then
  by kind (compares in the order 171, 137, 143, 146, 145, 147, 205,
  175, 164):
  - 171 CC_CALL: gspace of cc_call_len's low word (+0x22) + 20,
    lib_$data_move of cc_call_len + 20 bytes (a frame longword) from n
    to it, n set to it, its +16 copied;
  - 137, 143: an operator 16 (a call) when il_180's calling convention
    (+377 bits 6..4) is 2: the call's class and length from what it
    calls (110 +10 bits 3..0 and +8; 159 LIB_DSC std_lib's word for the
    call's result class (+24) and char_maxlen; 108 FUNCTION_BLK its
    +96's; a dereference (146) of a dereference of a 110 that one's;
    else cgerr_no_source(28, strtk('Bad call to copy_tree?', 22)));
    the call copied (count * 4 + 40 bytes: +2, the 12 bytes from +4,
    +16 cleared, the 16 bytes from +20, +36, +38, each operand copied),
    a temporary (make_char_temp for class 7, else make_temp), an
    assignment top-level node (add_top_node(140, 80): the constants by
    address, 0x0A04CA) with init_aux_ftn(+48, class), +64 the
    temporary, +68 the call, +76 11 for the classes 4, 5, 6, 13
    (`move.w #0x2070; btst'), 6 with +48 the length and +58 bit 2 for
    7, else 0; adjust_uc(assignment, 1); n and the result the
    temporary;
  - 137, 143 otherwise: copied likewise; an operator 16 or 15 whose
    first operand is a 171 sets cc_call_len to (count - 1) * 4 first;
  - 146: 32 bytes: +2, the 12 bytes from +4, +16 cleared, +20, +22,
    +23, +24 and +28 copied;
  - 145: 44 bytes: as 146, +32, +36 copied, +40, +42;
  - 147, 205: 36 bytes: as 146, +32;
  - 175 PF_CALL: 24 bytes: the 12 bytes from +4, +16 and +20 copied;
  - 164 CS_NODE: 32 bytes: +16 cleared, +20 and +24 copied, +28, +30;
  - others (138): n.
  The result in A0.

  Not known from the original:
  - the names; what the classes are. }

function copy_tree;
var
  c: an_ptr_t;                          { A4 }
  t: an_ptr_t;
  tmp: il_$node_ptr_t;                  { -16 }
  top: c_top_ptr_t;
  f, g: an_ptr_t;
  size: integer32;                      { -64 }
  cls: integer;
  len: integer;
  i: integer32;
begin
  if n = nil then begin
    copy_tree := n;
    return;
  end;
  t := an_ptr_t(n);
  if not (t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 205]) then
  begin
    copy_tree := n;
    return;
  end;
  case t^.kind of
    171: begin
      tmp := gspace(cc_call_len + 20);
      size := cc_call_len + 20;
      lib_$data_move(n, tmp, size);
      n := tmp;
      an_ptr_t(tmp)^.xp[4] := copy_tree(an_ptr_t(n)^.xp[4]);
      copy_tree := tmp;
    end;
    137, 143:
      if (t^.op = 16) and (c_blk_ptr_t(il_180)^.bits.conv = 2) then begin
        f := an_ptr_t(t^.opnd[1]);
        case f^.kind of
          110: begin
            cls := ord(f^.xc[10]) & 15;
            if cls = 7 then
              len := f^.xw[4];
          end;
          159: begin
            cls := an_std_lib_words_ptr_t(addr(std_lib_rtns))^[353 + t^.desc.rlen];
            if cls = 7 then
              len := char_maxlen(n);
          end;
          108: begin
            g := an_ptr_t(f^.xp[24]);
            cls := ord(g^.xc[10]) & 15;
            if cls = 7 then
              len := g^.xw[4];
          end;
          146: begin
            g := an_ptr_t(f^.base);
            if g^.kind = 146 then begin
              g := an_ptr_t(g^.base);
              if g^.kind = 110 then begin
                cls := ord(g^.xc[10]) & 15;
                if cls = 7 then
                  len := g^.xw[4];
              end
              else
                cgerr_no_source(28,
                    integer32(strtk('Bad call to copy_tree?', 22)));
            end
            else
              cgerr_no_source(28,
                  integer32(strtk('Bad call to copy_tree?', 22)));
          end;
          otherwise
            cgerr_no_source(28,
                integer32(strtk('Bad call to copy_tree?', 22)));
        end;
        c := gspace(an_ptr_t(n)^.count * 4 + 40);
        c^.kind := an_ptr_t(n)^.kind;
        c^.hdr := an_ptr_t(n)^.hdr;
        c^.w16 := 0;
        c^.desc := an_ptr_t(n)^.desc;
        c^.op := an_ptr_t(n)^.op;
        c^.count := an_ptr_t(n)^.count;
        for i := 1 to c^.count do
          c^.opnd[i] := copy_tree(an_ptr_t(n)^.opnd[i]);
        if cls = 7 then
          tmp := make_char_temp(len)
        else
          tmp := make_temp(cls);
        top := c_top_ptr_t(add_top_node(140, 80));
        init_aux_ftn(top^.asg_desc, cls);
        top^.asg_lhs := tmp;
        top^.asg_rhs := il_$node_ptr_t(c);
        if cls in [4..6, 13] then
          top^.asg_op := 11
        else if cls = 7 then begin
          top^.asg_op := 6;
          top^.asg_desc.size := len;
          top^.asg_desc.flags.b2 := true;
        end
        else
          top^.asg_op := 0;
        adjust_uc(il_$node_ptr_t(top), 1);
        n := tmp;
        copy_tree := tmp;
      end
      else begin
        c := gspace(t^.count * 4 + 40);
        c^.kind := an_ptr_t(n)^.kind;
        if ((an_ptr_t(n)^.op = 16) or (an_ptr_t(n)^.op = 15)) and
           (an_ptr_t(n)^.opnd[1]^.kind = 171) then
          cc_call_len := (an_ptr_t(n)^.count - 1) * 4;
        c^.hdr := an_ptr_t(n)^.hdr;
        c^.w16 := 0;
        c^.desc := an_ptr_t(n)^.desc;
        c^.op := an_ptr_t(n)^.op;
        c^.count := an_ptr_t(n)^.count;
        for i := 1 to c^.count do
          c^.opnd[i] := copy_tree(an_ptr_t(n)^.opnd[i]);
        copy_tree := il_$node_ptr_t(c);
      end;
    146: begin
      c := gspace(32);
      c^.kind := 146;
      c^.hdr := an_ptr_t(n)^.hdr;
      c^.w16 := 0;
      c^.rf_w20 := an_ptr_t(n)^.rf_w20;
      c^.align := an_ptr_t(n)^.align;
      c^.b23 := an_ptr_t(n)^.b23;
      c^.base := copy_tree(an_ptr_t(n)^.base);
      c^.sym := copy_tree(an_ptr_t(n)^.sym);
      copy_tree := il_$node_ptr_t(c);
    end;
    145: begin
      c := gspace(44);
      c^.kind := 145;
      c^.hdr := an_ptr_t(n)^.hdr;
      c^.w16 := 0;
      c^.rf_w20 := an_ptr_t(n)^.rf_w20;
      c^.align := an_ptr_t(n)^.align;
      c^.b23 := an_ptr_t(n)^.b23;
      c^.base := copy_tree(an_ptr_t(n)^.base);
      c^.sym := copy_tree(an_ptr_t(n)^.sym);
      c^.disp := an_ptr_t(n)^.disp;
      c^.index := copy_tree(an_ptr_t(n)^.index);
      c^.rf_w40 := an_ptr_t(n)^.rf_w40;
      c^.len := an_ptr_t(n)^.len;
      copy_tree := il_$node_ptr_t(c);
    end;
    147, 205: begin
      c := gspace(36);
      c^.kind := t^.kind;
      c^.hdr := an_ptr_t(n)^.hdr;
      c^.w16 := 0;
      c^.rf_w20 := an_ptr_t(n)^.rf_w20;
      c^.align := an_ptr_t(n)^.align;
      c^.b23 := an_ptr_t(n)^.b23;
      c^.base := copy_tree(an_ptr_t(n)^.base);
      c^.sym := copy_tree(an_ptr_t(n)^.sym);
      c^.disp := an_ptr_t(n)^.disp;
      copy_tree := il_$node_ptr_t(c);
    end;
    175: begin
      c := gspace(24);
      c^.kind := 175;
      c^.hdr := an_ptr_t(n)^.hdr;
      c^.xp[4] := copy_tree(an_ptr_t(n)^.xp[4]);
      c^.xp[5] := copy_tree(an_ptr_t(n)^.xp[5]);
      copy_tree := il_$node_ptr_t(c);
    end;
    164: begin
      c := gspace(32);
      c^.kind := 164;
      c^.hdr := an_ptr_t(n)^.hdr;
      c^.w16 := 0;
      c^.xp[5] := copy_tree(an_ptr_t(n)^.xp[5]);
      c^.xp[6] := copy_tree(an_ptr_t(n)^.xp[6]);
      c^.xw[14] := an_ptr_t(n)^.xw[14];
      c^.xw[15] := an_ptr_t(n)^.xw[15];
      copy_tree := il_$node_ptr_t(c);
    end;
    otherwise
      copy_tree := n;
  end;
end;

{ invariant_sizeof_top_level - the bytes of a top-level node of kind.

  0x0A04E4, 0xEC bytes, no frame, no A5: kind at (4,SP); kinds outside
  the set at 0x0A05D0 (139..142, 144, 148..151, 188, 191, 214, 215,
  223..225, 227, 228, 231, 233; of 0..239 without a range check,
  docs/rev889-patterns.md 41) give 52; then compares: 144 84, 148 52,
  140 80, 139 52, 141 56, 142 64, 150 52, 151 52, 188 60, 191 336, 149
  48, 223 76, 224 60, 225 52, 227 80, 228 68, 215 and 214 68, 231 56,
  233 56, else 52; the result in D0 (a longword).

  Not known from the original:
  - the names. }

function invariant_sizeof_top_level(
    kind: integer): integer32; internal; options(val_param);
begin
  if not (kind in [139..142, 144, 148..151, 188, 191, 214, 215, 223..225, 227, 228, 231, 233]) then
    invariant_sizeof_top_level := 52
  else
    case kind of
      144: invariant_sizeof_top_level := 84;
      148: invariant_sizeof_top_level := 52;
      140: invariant_sizeof_top_level := 80;
      139: invariant_sizeof_top_level := 52;
      141: invariant_sizeof_top_level := 56;
      142: invariant_sizeof_top_level := 64;
      150: invariant_sizeof_top_level := 52;
      151: invariant_sizeof_top_level := 52;
      188: invariant_sizeof_top_level := 60;
      191: invariant_sizeof_top_level := 336;
      149: invariant_sizeof_top_level := 48;
      223: invariant_sizeof_top_level := 76;
      224: invariant_sizeof_top_level := 60;
      225: invariant_sizeof_top_level := 52;
      227: invariant_sizeof_top_level := 80;
      228: invariant_sizeof_top_level := 68;
      215, 214: invariant_sizeof_top_level := 68;
      231: invariant_sizeof_top_level := 56;
      233: invariant_sizeof_top_level := 56;
      otherwise
        invariant_sizeof_top_level := 52;
    end;
end;

{ add_node_$dispose_top_level - see add_node.ins.pas.

  0x0A05EE, 0xB8 bytes, link #0: a kind outside the top-level set
  (0x0A05D0) is written to the run time's file at (-4,A5): 'Compiler
  internal warning - requested node (' (44 characters, PAS_$WRITE
  code 51), the kind as an enumerated value (code 3877 with the name
  table at 0x0A06A6, its width 0), ') is not top-level.' (19), writeln;
  then pas_$dispose(n, invariant_sizeof_top_level(kind) + extra).

  Not known from the original:
  - the names. }

procedure add_node_$dispose_top_level;
begin
  if not (n^.kind in [139..142, 144, 148..151, 188, 191, 214, 215, 223..225, 227, 228, 231, 233]) then
    writeln('Compiler internal warning - requested node (',
            an_kind_t(n^.kind), ') is not top-level.');
  pas_$dispose(n, invariant_sizeof_top_level(n^.kind) + extra);
end;

{ add_node_$new_top_level - see add_node.ins.pas.

  0x0A1190, 0xD2 bytes, link #-16: a kind outside the top-level set
  written as in add_node_$dispose_top_level (the kind stored in its
  parameter's slot to be passed by address); pas_$new(p,
  invariant_sizeof_top_level(kind) + extra) into a frame longword
  (-12); unless nil, the 11 longwords from +4 cleared (`moveq #11; beq;
  clr.l (A1)+; subq.l #1; bne') and the kind at +2; the node left in
  A0 (docs/rev889-patterns.md 32).

  Not known from the original:
  - the names; how the 44 bytes were cleared (a loop here). }

function add_node_$new_top_level;
var
  p: il_$node_ptr_t;                    { -12 }
  i: integer;
begin
  if not (kind in [139..142, 144, 148..151, 188, 191, 214, 215, 223..225, 227, 228, 231, 233]) then
    writeln('Compiler internal warning - requested node (',
            an_kind_t(kind), ') is not top-level.');
  pas_$new(p, invariant_sizeof_top_level(kind) + extra);
  if p <> nil then begin
    for i := 1 to 11 do
      p^.xl[i] := 0;
    p^.kind := kind;
  end;
  add_node_$new_top_level := p;
end;

{ add_routine_reference - enter the routine rtn in the references of
  the routine blk (or of the routine an inner block, 172 INNER_BLK, is
  in): a list from blk's +256 of 12-byte nodes (160 REF_LIST: +4 the
  routine, +8 the next), new ones in front.

  0x0A1262, 0x9E bytes, link #-8: blk of kind 172 goes up +8 until 108
  or 107; rtn of kind 107, 110 or 108 only; the list searched for +4 =
  rtn (a byte flag, `st'); gspace(12) when not found.

  Not known from the original:
  - the names. }

procedure add_routine_reference(
    blk: il_$node_ptr_t;
    rtn: il_$node_ptr_t); options(val_param);
var
  r: il_$node_ptr_t;                    { -4 }
  found: boolean;
begin
  if blk^.kind = 172 then
    repeat
      blk := blk^.xp[2];
    until (blk^.kind = 108) or (blk^.kind = 107);
  if (rtn^.kind = 107) or (rtn^.kind = 110) or (rtn^.kind = 108) then begin
    found := false;
    r := blk^.xp[64];
    while r <> nil do begin
      if r^.xp[1] = rtn then begin
        found := true;
        exit;
      end;
      r := r^.xp[2];
    end;
    if not found then begin
      r := gspace(12);
      r^.kind := 160;
      r^.xp[1] := rtn;
      r^.xp[2] := blk^.xp[64];
      blk^.xp[64] := r;
    end;
  end;
end;

{ add_disp_node - see add_node.ins.pas.

  0x0A1300, 0xD6 bytes, link #-28: the phase getphase(base) +
  getphase(sym) without 5, 8, 9 (`andi.w #0xFCDF'); a base of kind 147
  whose +7 bit 5 is clear gives its +24 and adds its +32 to disp; base
  itself when force is false (`tst.b; bmi'), disp 0 and the phase
  empty; else gspace(36): 147, the phase at +4 (computed again after,
  +7 bit 1 set when bit 2 is), +10..+17 cleared, +24 base, +28 sym, +32
  disp, +22 and +23 cleared.  The result in A0.

  Not known from the original:
  - the names; why the phase is stored twice. }

function add_disp_node;
var
  ph: add_node_$phase_t;
  x: an_ptr_t;
begin
  ph := (getphase(base) + getphase(sym)) - [5, 8, 9];
  if (base^.kind = 147) and not (5 in an_ptr_t(base)^.rf_phase) then begin
    disp := disp + an_ptr_t(base)^.disp;
    base := an_ptr_t(base)^.base;
  end;
  if not force and (disp = 0) and (ph = []) then begin
    add_disp_node := base;
    return;
  end;
  x := gspace(36);
  x^.kind := 147;
  x^.rf_phase := ph;
  if 2 in x^.rf_phase then
    x^.rf_phase := x^.rf_phase + [1];
  x^.rf_phase := (getphase(base) + getphase(sym)) - [5, 8, 9];
  x^.xl2[2] := 0;
  x^.xl2[3] := 0;
  x^.base := base;
  x^.sym := sym;
  x^.disp := disp;
  x^.align := chr(0);
  x^.b23 := chr(0);
  add_disp_node := il_$node_ptr_t(x);
end;

{ add_dn - see add_node.ins.pas.

  0x0A13D6, 0x28 bytes, link #-4: add_disp_node(base, sym, disp,
  false); its A0 left as the result.

  Not known from the original:
  - the names. }

function add_dn;
begin
  add_dn := add_disp_node(base, sym, disp, false);
end;

{ add_sdn - see add_node.ins.pas.

  0x0A13FE, 0xFA bytes, link #-32: a base of kind 147 is kept (D3) and
  its +24 taken; gspace(36): 205, the phase getphase(base) +
  getphase(sym) - [5, 8, 9] (computed twice, the first unused), +7 bit
  1 when 2 is in it, +10..+17 cleared, +24 base, +28 sym, +32 v, +22,
  +23 cleared; v of kind 110 gets +24 bit 4, of kind 109 whose +20 is
  il_180 +32 bit 4; with the kept node add_dn(new, its +28, its +32).
  The result in A0.

  Not known from the original:
  - the names; what the bits mark. }

function add_sdn;
var
  dn: an_ptr_t;                         { D3 }
  b: il_$node_ptr_t;                    { A3 }
  x: an_ptr_t;                          { A2 }
  res: il_$node_ptr_t;                  { D5 }
  ph: add_node_$phase_t;
  vv: an_ptr_t;
begin
  if base^.kind = 147 then begin
    dn := an_ptr_t(base);
    b := dn^.base;
  end
  else begin
    dn := nil;
    b := base;
  end;
  ph := (getphase(b) + getphase(sym)) - [5, 8, 9];
  x := gspace(36);
  res := il_$node_ptr_t(x);
  x^.kind := 205;
  x^.rf_phase := (getphase(b) + getphase(sym)) - [5, 8, 9];
  if 2 in x^.rf_phase then
    x^.rf_phase := x^.rf_phase + [1];
  x^.xl2[2] := 0;
  x^.xl2[3] := 0;
  x^.base := b;
  x^.sym := sym;
  x^.disp := integer32(v);
  x^.align := chr(0);
  x^.b23 := chr(0);
  vv := v;
  if vv^.kind = 110 then
    vv^.at_24 := vv^.at_24 + [28]
  else if (vv^.kind = 109) and (vv^.xp[5] = il_180) then
    vv^.at_32 := vv^.at_32 + [28];
  if dn <> nil then
    res := add_dn(res, dn^.sym, dn^.disp);
  add_sdn := res;
end;

{ add_dindexn - see add_node.ins.pas.

  0x0A14F8, 0x15A bytes, link #-60: the phase getphase(base) +
  getphase(item) without 5 and 9 (`andi.w #0xFDDF'); gspace(44): 145,
  the phase again, +7 bit 1 when 2 is in it, +12 cleared; type_exp(item)
  into a frame record: a size over 32767, -INDEXL (cargs +0x27B bit 3)
  or cpu 6 (+0x284 bit 0) set +6 bit 0 (a long index); +10 1, +16
  cleared, +22 align, +23 b23, +24 base, +32 cleared, +28 item when it
  is a variable (109) of an array type (131 ARRAY_TYPE) else int_type
  (c_globals +0x2398), +36 index, +42 len, +40 cleared; disp other than
  0 gives add_dn(node, item, disp); an index that is a tree of class
  5 or 4 (+24) sets +6 bit 0 and +42 4 (in the 145 node, after).  The
  result in A0 (add_dn's or the node).

  Not known from the original:
  - the names; what +10, +16 and +6 bit 0 mean beyond the long index. }

function add_dindexn;
var
  ph: add_node_$phase_t;                { D5 }
  x: an_ptr_t;                          { -40 }
  te: type_exp_t;                       { -32 }
  res: il_$node_ptr_t;
begin
  ph := (getphase(base) + getphase(item)) - [5, 9];
  x := gspace(44);
  x^.kind := 145;
  x^.rf_phase := (getphase(base) + getphase(item)) - [5, 9];
  if 2 in ph then
    x^.rf_phase := x^.rf_phase + [1];
  x^.xl[3] := 0;
  type_exp(item, addr(te));
  if (te.size > 32767) or cargs_$options.indexl or
     (6 in cargs_$options.cpu) then
    x^.rf_phase := x^.rf_phase + [8];
  x^.rf_w10 := 1;
  x^.rf_w16 := 0;
  x^.align := chr(align);
  x^.b23 := chr(b23);
  x^.base := base;
  x^.disp := 0;
  if (an_ptr_t(item)^.kind = 109) and
     (an_ptr_t(item)^.xp[7]^.kind = 131) then
    x^.sym := item
  else
    x^.sym := il_$node_ptr_t(int_type);
  x^.index := index;
  x^.len := len;
  x^.rf_w40 := 0;
  if disp <> 0 then
    res := add_dn(il_$node_ptr_t(x), item, disp)
  else
    res := il_$node_ptr_t(x);
  if index <> nil then
    if index^.kind = 137 then
      if (an_ptr_t(index)^.desc.rlen = 5) or
         (an_ptr_t(index)^.desc.rlen = 4) then begin
        x^.rf_phase := x^.rf_phase + [8];
        x^.len := 4;
      end;
  add_dindexn := res;
end;

{ add_pn - see add_node.ins.pas.

  0x0A1652, 0x228 bytes, link #-24: an address node (137, operator 26)
  gives add_disp_node(its operand, item, 0, true); an address sum (137,
  operator 13 or 1, class 5 at +24) of an operand in the set at
  0x0A18AE (109, 110, 137, 146, 147, 153, 154) and one in the set at
  0x0A187A (constants, 109, 110, 137, 146, 147), of different kinds,
  and for 13 a source class (+26) of 5 or 4: add_dindexn(first, item,
  second, 0, 4, align, b23) for a constant second, else for a first of
  kind 137 add_dindexn(second, item, first, 0, its class, ...) with +6
  bit 0, else add_dindexn(first, item, second, 0, its class, ...) with
  +6 bit 0 and +42 4; otherwise gspace(32): 146, the phase
  getphase(base) + getphase(item) - [5, 8, 9] (bit 1 becomes bit 2
  unless base is a 109 of +72 5), +10..+17 cleared, +24 base, +22
  align, +23 b23, +28 int_type.  Then a 145, or a 147 of a 145, gets
  +28 item when item is a 109 of type 131.  The result in A0.

  Not known from the original:
  - the names. }

function add_pn;
var
  x: an_ptr_t;                          { D5 }
  ph: add_node_$phase_t;
  b: an_ptr_t;
  o1, o2: il_$node_ptr_t;
  done: boolean;
begin
  b := an_ptr_t(base);
  if (base^.kind = 137) and (b^.op = 26) then begin
    add_pn := add_disp_node(b^.opnd[1], item, 0, true);
    return;
  end;
  ph := (getphase(base) + getphase(item)) - [5, 8, 9];
  done := false;
  if base <> nil then
    if base^.kind = 137 then
      if ((b^.op = 13) or (b^.op = 1)) and (b^.desc.rlen = 5) then begin
        o1 := b^.opnd[1];
        o2 := b^.opnd[2];
        if (o1^.kind in [109, 110, 137, 146, 147, 153, 154]) and
           (o2^.kind in [77..87, 101, 109, 110, 137, 146, 147, 200]) and
           (o2^.kind <> o1^.kind) then
          if (b^.op <> 13) or (b^.desc.w6 = 5) or (b^.desc.w6 = 4) then
          begin
            if o2^.kind in [77..87, 101, 200] then begin
              x := an_ptr_t(add_dindexn(o1, item, o2, 0, 4, align, b23));
              x^.rf_phase := x^.rf_phase + [8];
              x^.len := 4;
            end
            else if o1^.kind = 137 then begin
              x := an_ptr_t(add_dindexn(o2, item, o1, 0,
                                        an_ptr_t(o1)^.desc.rlen, align,
                                        b23));
              x^.rf_phase := x^.rf_phase + [8];
            end
            else begin
              x := an_ptr_t(add_dindexn(o1, item, o2, 0,
                                        an_ptr_t(o2)^.desc.rlen, align,
                                        b23));
              x^.rf_phase := x^.rf_phase + [8];
              x^.len := 4;
            end;
            done := true;
          end;
      end;
  if not done then begin
    x := gspace(32);
    x^.kind := 146;
    ph := (getphase(base) + getphase(item)) - [5, 8, 9];
    if 1 in ph then
      if (base^.kind <> 109) or (base^.xw[36] <> 5) then
        ph := ph - [1] + [2];
    x^.rf_phase := ph;
    x^.xl2[2] := 0;
    x^.xl2[3] := 0;
    x^.base := base;
    x^.align := chr(align);
    x^.b23 := chr(b23);
    x^.sym := il_$node_ptr_t(int_type);
  end;
  if (x^.kind = 145) or
     ((x^.kind = 147) and (x^.base^.kind = 145)) then
    if (an_ptr_t(item)^.kind = 109) and
       (an_ptr_t(item)^.xp[7]^.kind = 131) then
      x^.sym := item;
  add_pn := il_$node_ptr_t(x);
end;

{ add_tn - see add_node.ins.pas.

  0x0A1ABC, 0x30AE bytes, link #-372, with distribute nested.  r over
  128 is cgerr(24, entry l's line, strtk(' Expression stack overflow,
  simplify your program and recompile', 63)).  Then, in the image's
  order:
  - operators 1, 10, 34, 20 call distribute;
  - the operators in the set at 0x0A4B6A (1, 3, 9, 10, 19, 20, 34, 36),
    neither operand a tree with phase 21 (the flag at -230), and for 3
    the descriptor's classes (+4, +6, +8) equal: a tree of the same
    operator and descriptor (16 bytes, `cmpm.l' four times) whose
    second operand is a constant (the set at 0x0A4BDE) moves the
    constant out ((x op c) op y as (x op y) op c, or both constants
    combined when y is a tree like it), or y such a tree;
  - the operators in the set at 0x0A4BD8 (1, 3, 9, 10, 19, 20, 34, 36,
    44..46) with a left tree and a right constant (the set at
    0x0A4BBE): 19 or 9 over 20 or 10, and 34 or 1 under 3, 36 or 27,
    with a constant second operand, distribute the constant;
  - the registers (+10 of the operands with a phase, for the right one
    only under the operators in the set at 0x0A4BB8): 6 for calls (15,
    16), the greater, or one more when equal; the operands are swapped
    when the right one needs more (commutative operators; for 3 the
    classes +6 and +8 swap, for the comparisons 12, 23, 40, 24 the
    condition code goes through swap_cc);
  - 26, the address: of a bit offset (14) by a multiple of 8 an
    add_dn, of a dereference its operand;
  - with constant folding on (cargs opt_on 2, +0x283 bit 3), the
    operators in the set at 0x0A4C4C: address sums of an address node,
    an address constant (163, 195) and an integer; 39 from a real (a
    clean-up handler: an overflow is diagnostic 19 and 0); 39 of a
    complex to a complex; all constants (the jump table at 0x0A26FC;
    unsigned operands for an unsigned type, M$...IU$; the remainder
    made non-negative under cargs +0x27C bit 1; 43 the power; the
    comparisons 12 by the condition code; 39 to a real by class); the
    identities of not, negation, 11 (a bit field's byte), 12 (unsigned
    comparisons with 0, a test of one bit), 9 and 10 of two nots, 1
    and 2 of negations; a constant right operand (3, 4, 9, 2, 10, 44,
    28, 27, 50, 49, 1); the real operators in the set at 0x0A4B90
    (34..38, 40, 41) of constants, under a clean-up handler, and their
    identities; 51 of a constant condition; 24 of equal operands; 18
    conversions of conversions and of constants, and widening a
    reference by add_dn (not of common blocks under opt_on 18); 63;
    then calls (15, 16) entered in il_180's references;
  - with folding on, a multiplication or shift (3, 27) of a sum or a
    conversion of one by a constant is kfold-ed;
  - the node itself: gspace(4 * (r - l + 1) + 40), 137, the operands
    from the stack and the phase their getphase without 5, 8, 9 (calls
    without 0..4, 16, 19; 1 becomes 2 except for 26; 12 for the
    operators in the set at 0x0A4C38), +10 the registers, +12 cleared,
    +36 op, +20 d, +16 0, +38 the count; the operators 34..41 set
    il_180's +376 bit 7, as do calls whose registers saved (reg_save)
    miss one of 18..23;
  - the result in entry l; an integer constant of an integer type
    narrows the entry's type: its low and high the value, its size 1
    or 2 when the value fits (signed or not, unless the class is 4);
    the stack cut back to l.

  The real arithmetic is the FPP emulator's (docs/rev889-patterns.md
  19; 0x0074 load, 0x0080 store, 0x0084 +, 0x008C -, 0x009C *, 0x00A4
  /, 0x006C negate, 0x0070 abs, 0x0154 0x0068 round, 0x00D0 trunc,
  0x0110 arctan, 0x0100 cos, 0x00E8 exp, 0x00F0 ln, 0x00F8 sin, 0x00E0
  sqrt, 0x00B4 compare, 0x00B8 compare with an immediate, 0xFF34 test,
  0x00C4/0x01D8 load a signed/unsigned longword; ftn_$dlog10 for 5).

  Not known from the original:
  - the names, the labels; the meaning of the operator codes and
    condition codes (kfold.pas folds the same ones); whether the
    sign and zero extensions (the frame bytes and words at -180 and
    -184) were variant records (arithmetic here). }

procedure add_tn;
label
  10, 20, 30, 40, 50, 60, 61, 70, 75, 80;
var
  flag: boolean;                        { -230 }
  regs: integer;                        { -224 }
  k1, k2: integer;                      { -216, -214 }
  t208: il_$node_ptr_t;                 { -208 }
  res: il_$node_ptr_t;                  { -204 }
  v1: integer32;                        { -200 }
  status: status_$t;                    { -176 }
  a: double;                            { -168 }
  b: double;                            { -160 }
  bb: an_dbl_t;                         { -152 }
  dd: add_node_$desc_t;                 { -144 }
  crec: pfm_$cleanup_rec;               { -128 }
  e: c_exp_t;                           { -64 }
  rr: double;                           { -368 }
  x, y: an_ptr_t;
  wl, wr: integer;
  w: integer;
  v2: integer32;
  uv1, uv2: linteger;
  m, cv, xx: integer32;
  c: integer;
  i: integer;
  uns: boolean;
  ph: add_node_$phase_t;               { D4 }

{ distribute - for operators 1, 10, 34 and 20 over two trees of one
  operator (19 or 9 under 20 or 10; 36 or 3 of one class under 34 or
  1) and one descriptor sharing an operand: (x * y) + (x * z) as x *
  (y + z).  The other two operands are combined first (add_tn on the
  stack's top two), then add_tn goes on with the shared operand, the
  inner operator and its descriptor.  Nothing when either has phase 21.

  0x0A18C2, 0x1FA bytes, link #-16: add_tn's frame from (A6); the
  entries indexed `lsl.w #6' (16-bit).

  Not known from the original:
  - the names. }

  procedure distribute;
  var
    p, q: an_ptr_t;
  begin
    p := an_ptr_t(cexs_stack[l].node);
    q := an_ptr_t(cexs_stack[r].node);
    flag := false;
    if 21 in p^.phase then
      flag := true
    else if 21 in q^.phase then
      flag := true;
    if flag then
      return;
    if (cexs_stack[l].node^.kind <> 137) or
       (cexs_stack[r].node^.kind <> 137) or (p^.op <> q^.op) then
      return;
    if not ((((op = 20) or (op = 10)) and ((p^.op = 19) or (p^.op = 9)))
            or ((p^.desc.w6 = p^.desc.rlen) and
                (p^.desc.w6 = p^.desc.w8) and
                ((op = 34) or (op = 1)) and
                ((p^.op = 36) or (p^.op = 3)))) then
      return;
    if p^.desc <> q^.desc then
      return;
    if p^.opnd[1] = q^.opnd[2] then begin
      cexs_stack[l].node := p^.opnd[1];
      cexs_stack[r].node := p^.opnd[2];
      push(q^.opnd[1]);
    end
    else if p^.opnd[2] = q^.opnd[1] then begin
      cexs_stack[l].node := p^.opnd[2];
      cexs_stack[r].node := p^.opnd[1];
      push(q^.opnd[2]);
    end
    else if p^.opnd[1] = q^.opnd[1] then begin
      cexs_stack[l].node := p^.opnd[1];
      cexs_stack[r].node := p^.opnd[2];
      push(q^.opnd[2]);
    end
    else if p^.opnd[2] = q^.opnd[2] then begin
      cexs_stack[l].node := p^.opnd[2];
      cexs_stack[r].node := p^.opnd[1];
      push(q^.opnd[1]);
    end
    else
      return;
    add_tn(op, d, cexs_23bc - 1, cexs_23bc);
    op := p^.op;
    d := p^.desc;
  end;

begin { add_tn }
  if r > 128 then
    cgerr(24, cexs_stack[l].line,
          strtk(' Expression stack overflow, simplify your program and recompile',
                63));
  flag := false;
  if (op = 1) or (op = 10) or (op = 34) or (op = 20) then
    distribute;

  { Constants moved out of trees of the same operator. }
  if op in [1, 3, 9, 10, 19, 20, 34, 36] then begin
    x := an_ptr_t(cexs_stack[l].node);
    y := an_ptr_t(cexs_stack[r].node);
    if (x^.kind = 137) and (21 in x^.phase) then
      flag := true
    else if (y^.kind = 137) and (21 in y^.phase) then
      flag := true;
    if not flag then
      if (op <> 3) or ((d.rlen = d.w6) and (d.rlen = d.w8)) then
        if (x^.kind = 137) and (op = x^.op) then begin
          if (op <> 3) or (d = x^.desc) then
            if x^.opnd[2]^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then begin
              if y^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then
              begin
                push(x^.opnd[2]);
                add_tn(op, d, r, cexs_23bc);
                cexs_stack[l].node := x^.opnd[1];
              end
              else if (y^.kind = 137) and (op = y^.op) then begin
                if d = y^.desc then begin
                  push(x^.opnd[1]);
                  add_tn(op, d, r, cexs_23bc);
                  push(x^.opnd[2]);
                  add_tn(op, d, r, cexs_23bc);
                  cexs_stack[l].node := cexs_stack[r].node;
                  cexs_23bc := l;
                  return;
                end;
              end
              else begin
                res := x^.opnd[2];
                cexs_stack[l].node := x^.opnd[1];
                add_tn(op, d, l, r);
                push(res);
              end;
            end
            else if (y^.kind = 137) and (op = y^.op) and (d = y^.desc) then
            begin
              res := y^.opnd[2];
              cexs_stack[r].node := y^.opnd[1];
              add_tn(op, d, l, r);
              push(res);
            end;
        end
        else if (y^.kind = 137) and (y^.op = op) and (d = y^.desc) then begin
          res := y^.opnd[2];
          cexs_stack[r].node := y^.opnd[1];
          add_tn(op, d, l, r);
          push(res);
        end;
  end;

  { A constant distributed over a tree. }
  if op in [1, 3, 9, 10, 19, 20, 34, 36, 44..46] then begin
    flag := false;
    x := an_ptr_t(cexs_stack[l].node);
    y := an_ptr_t(cexs_stack[r].node);
    if (x^.kind = 137) and (21 in x^.phase) then
      flag := true
    else if (y^.kind = 137) and (21 in y^.phase) then
      flag := true;
    if not flag and (x^.kind = 137) and
       (y^.kind in [77..89, 101, 156, 200]) then
      if (((op = 19) or (op = 9)) and ((x^.op = 20) or (x^.op = 10))) or
         (((x^.op = 34) or (x^.op = 1)) and
          ((op = 3) or (op = 36) or (op = 27))) then
        if x^.opnd[2]^.kind in [77..87, 101, 200] then begin
          cexs_stack[l].node := x^.opnd[1];
          cexs_stack[r].node := il_$node_ptr_t(y);
          dd := d;
          dd.w6 := x^.desc.rlen;
          add_tn(op, dd, l, r);
          push(x^.opnd[2]);
          t208 := il_$node_ptr_t(y);
          push(t208);
          add_tn(op, d, cexs_23bc - 1, cexs_23bc);
          op := x^.op;
          d.w6 := 0;
          d.w8 := 0;
        end;
  end;

  { The registers, and the operands swapped for the costlier first. }
  wl := 0;
  wr := 0;
  if op in [1..6, 9, 10, 12, 13, 19..21, 23..25, 27, 28, 34..37, 40, 44..46] then
    if cexs_stack[r].node^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
      wr := cexs_stack[r].node^.xw[5];
  if cexs_stack[l].node^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    wl := cexs_stack[l].node^.xw[5];
  if (op = 15) or (op = 16) then
    regs := 6
  else if wl = wr then
    regs := wl + 1
  else if wl > wr then
    regs := wl
  else begin
    if (op in [1, 3, 9, 10, 19, 20, 34, 36, 44..46]) or (op = 12) or
       (op = 23) or (op = 40) or (op = 24) then begin
      res := cexs_stack[l].node;
      cexs_stack[l].node := cexs_stack[r].node;
      cexs_stack[r].node := res;
      if op = 3 then begin
        w := d.w6;
        d.w6 := d.w8;
        d.w8 := w;
      end
      else if (op = 12) or (op = 23) or (op = 40) or (op = 24) then
        d.w8 := swap_cc[d.w8];
    end;
    regs := wr;
  end;

  { The address of a bit offset or of a dereference. }
  if op = 26 then begin
    res := cexs_stack[l].node;
    x := an_ptr_t(res);
    if (res^.kind = 137) and (x^.op = 14) and
       (x^.opnd[2]^.kind in [77..87, 101, 200]) then
      if an_ptr_t(x^.opnd[2])^.int_value mod 8 = 0 then begin
        cexs_stack[l].node := add_dn(x^.opnd[1], cexs_stack[l].sym,
                                     an_ptr_t(x^.opnd[2])^.int_value div 8);
        goto 20;
      end;
    if res^.kind = 146 then begin
      res := x^.base;
      goto 40;
    end;
    goto 20;
  end;

  { Constant folding. }
  if not (2 in cargs_$options.opt_on) then
    goto 30;
  if not (op in [1..4, 6..10, 12, 27..29, 39, 43..46, 48..50, 52, 53, 57]) then
    goto 80;

  { Address sums. }
  if (op = 2) or (op = 1) then begin
    x := an_ptr_t(cexs_stack[l].node);
    y := an_ptr_t(cexs_stack[r].node);
    if (x^.kind = 137) and (x^.op = 26) and
       (y^.kind in [80..86, 200]) and (abs(y^.int_value) <= 32700) then
    begin
      dd := x^.desc;
      cexs_23bc := cexs_23bc + 1;
      cexs_stack[cexs_23bc].node := x^.opnd[1];
      dd.rlen := 0;
      add_tn(26, dd, cexs_23bc, cexs_23bc);
      an_ptr_t(cexs_stack[cexs_23bc].node)^.desc.rlen := x^.desc.rlen;
      res := cexs_stack[cexs_23bc].node;
      cexs_23bc := cexs_23bc - 1;
      v1 := y^.int_value;
      if op = 2 then
        v1 := -v1;
      an_ptr_t(res)^.opnd[1] := add_dn(an_ptr_t(res)^.opnd[1],
                                       an_ptr_t(res)^.opnd[1], v1);
      goto 40;
    end;
    if (x^.kind = 163) and (y^.kind in [80..86, 200]) then begin
      v1 := y^.int_value;
      if op = 2 then
        v1 := -v1;
      v1 := v1 + x^.xl[3];
      if x^.xc[20] <> chr(0) then
        res := make_new_addr_con(ord(x^.xc[20]), x^.xp[2], v1,
                                 find_ac_dsect(il_$node_ptr_t(x)), false)
      else
        res := make_xdynm_ptr(x^.xp[2], v1);
      goto 40;
    end;
    if (x^.kind = 195) and (y^.kind in [80..86, 200]) then begin
      v1 := y^.int_value;
      if op = 2 then
        v1 := -v1;
      v1 := v1 + x^.xl[4];
      res := make_new_addr_con(x^.xw[10], x^.xp[3], v1, nil, false);
      goto 40;
    end;
  end;

  { A real constant to an integer. }
  if (op = 39) and (d.rlen <= 4) then
    with cexs_stack[l] do begin
      if node^.kind in [77..87, 101, 200] then begin
        res := node;
        goto 40;
      end;
      if node^.kind = 137 then
        if an_ptr_t(node)^.op = 41 then
          if an_ptr_t(node)^.desc.w6 = 10 then
            node := an_ptr_t(node)^.opnd[1];
      if (node^.kind <> 89) and (node^.kind <> 88) then
        goto 20;
      status := pfm_$cleanup(crec);
      if status.all <> pfm_$cleanup_set then
        if (status.subsys = 5) or (status.subsys = 0) then begin
          pfm_$enable;
          cgerr(19, line, node);
          error_$print_format(status, 2, '?', 'compiler', 8, '%$');
          v1 := 0;
          res := smcontk(81, v1);
          goto 40;
        end
        else
          pfm_$signal(status);
      if d.flags.signed then
        v1 := trunc(node^.real_value)
      else if node^.real_value <= 2147483647.0 then
        v1 := trunc(node^.real_value)
      else
        v1 := trunc(node^.real_value - 2147483647.0 - 1.0) - 16#80000000;
      pfm_$rls_cleanup(crec, status);
      res := smcontk(81, v1);
      goto 40;
    end;

  { A complex constant to a complex. }
  if (op = 39) and ((d.rlen = 12) or (d.rlen = 8)) then
    if (cexs_stack[l].node^.kind = 198) or
       (cexs_stack[l].node^.kind = 90) then begin
      res := cexs_stack[l].node;
      goto 40;
    end;

  { All constants. }
  k2 := 81;
  k1 := 81;
  for i := l to r do
    if cexs_stack[i].node^.kind in [77..87, 101, 200] then
      if i = l then begin
        v1 := cexs_stack[i].node^.int_value;
        uv1 := v1;
        k1 := cexs_stack[i].node^.kind;
      end
      else begin
        v2 := cexs_stack[i].node^.int_value;
        uv2 := v2;
        k2 := cexs_stack[i].node^.kind;
      end
    else
      goto 50;
  uns := not cexs_stack[l].typ.base^.signed;
  case op of
    1: v1 := v1 + v2;
    2: v1 := v1 - v2;
    9: v1 := v1 & v2;
    10: v1 := v1 ! v2;
    7: v1 := -v1;
    29:
      if v1 < 0 then
        v1 := -v1;
    8: begin
      v1 := ~v1;
      if cexs_stack[l].typ.base^.kind = 124 then
        v1 := v1 & 255;
    end;
    3:
      if uns then
        v1 := uv1 * uv2
      else
        v1 := v1 * v2;
    4: begin
      if v2 = 0 then
        goto 20;
      if uns then
        v1 := uv1 div uv2
      else
        v1 := v1 div v2;
    end;
    44: v1 := xor(v1, v2);
    6: begin
      if v2 = 0 then
        goto 20;
      if uns then
        v1 := uv1 mod uv2
      else
        v1 := v1 mod v2;
      if cargs_$options.b27c_1 and (v1 < 0) then
        v1 := v1 + v2;
    end;
    46:
      if v2 < v1 then
        v1 := v2;
    45:
      if v2 > v1 then
        v1 := v2;
    43:
      if v2 < 0 then
        v1 := 0
      else if v2 = 0 then begin
        if v1 <> 0 then
          v1 := 1
        else
          v1 := 0;
      end
      else begin
        xx := v1;
        for i := 2 to v2 do
          v1 := v1 * xx;
      end;
    27, 49: v1 := lshft(v1, v2);
    28: v1 := rshft(v1, v2);
    50: v1 := arshft(v1, v2);
    53:
      if (v1 <> 0) and (v2 <> 0) then
        v1 := 1
      else
        v1 := 0;
    52:
      if (v1 = 0) and (v2 = 0) then
        v1 := 0
      else
        v1 := 1;
    57:
      if v1 <> 0 then
        v1 := 0
      else
        v1 := 1;
    39: begin
      if d.flags.signed then begin
        if d.w6 = 1 then begin
          v1 := v1 & 16#FF;
          if v1 > 127 then
            v1 := v1 - 256;
        end
        else if d.w6 = 2 then begin
          v1 := v1 & 16#FFFF;
          if v1 > 32767 then
            v1 := v1 - 65536;
        end
        else if d.w6 <> 4 then
          return;
      end
      else if d.w6 = 1 then
        v1 := v1 & 16#FF
      else if d.w6 = 2 then
        v1 := v1 & 16#FFFF
      else if d.w6 <> 4 then
        return;
      if d.flags.signed then rr := v1 else if v1 < 0 then rr := v1 + 4294967296.0 else rr := v1;
      a := rr;
      if d.rlen = 7 then
        res := dpcontk(a)
      else if d.rlen = 6 then
        res := rlcontk(a)
      else
        goto 50;
      goto 40;
    end;
    12:
      case d.w8 of
        7: if v1 = v2 then v1 := 255 else v1 := 0;
        6: if v1 <> v2 then v1 := 255 else v1 := 0;
        13: if v1 < v2 then v1 := 255 else v1 := 0;
        14: if v1 > v2 then v1 := 255 else v1 := 0;
        15: if v1 <= v2 then v1 := 255 else v1 := 0;
        12: if v1 >= v2 then v1 := 255 else v1 := 0;
        3: if uv1 <= uv2 then v1 := 255 else v1 := 0;
        4: if uv1 >= uv2 then v1 := 255 else v1 := 0;
        5: if uv1 < uv2 then v1 := 255 else v1 := 0;
        2: if uv1 > uv2 then v1 := 255 else v1 := 0;
        otherwise ;
      end;
    otherwise ;
  end;
  if k2 > k1 then
    k1 := k2;
  if (d.rlen = 4) or (v1 < -32768) or (v1 > 32767) then
    k1 := 82;
  res := smcontk(k1, v1);
  goto 40;

  { Not all constants: identities. }
50:
  if (op = 8) or (op = 7) then begin
    res := cexs_stack[l].node;
    x := an_ptr_t(res);
    if res^.kind <> 137 then
      goto 60;
    if x^.op = op then begin
      res := x^.opnd[1];
      goto 40;
    end;
    if (x^.op = 11) and (op = 8) then begin
      if x^.desc.w8 < 0 then
        c := -1
      else
        c := 1;
      if abs(x^.desc.w8) = 6 then
        x^.desc.w8 := c * 7
      else
        x^.desc.w8 := c * 6;
      goto 40;
    end;
    if (op = 7) and (x^.op = 1) and
       (x^.opnd[2]^.kind in [77..87, 101, 200]) then
      if an_ptr_t(x^.opnd[2])^.int_value = 1 then begin
        cexs_stack[l].node := x^.opnd[1];
        add_tn(8, d, l, l);
        cexs_23bc := l;
        return;
      end;
  end
  else if (6 in cargs_$options.cpu) and
          ((op = 3) or (op = 6) or (op = 4)) then begin
    if d.w6 = d.w8 then
      goto 60;
    for i := 1 to 16 do
      an_bytes_ptr_t(addr(dd))^[i] := chr(0);
    if d.w6 > d.w8 then
      w := d.w6
    else
      w := d.w8;
    dd.rlen := w;
    dd.size := w;
    dd.flags.signed := d.flags.signed;
    dd.w8 := 0;
    if dd.size <> d.w6 then begin
      dd.w6 := d.w6;
      add_tn(18, dd, l, l);
      d.w6 := w;
    end;
    if dd.size <> d.w8 then begin
      dd.w6 := d.w8;
      add_tn(18, dd, r, r);
      d.w8 := w;
    end;
  end
  else if op = 11 then begin
    y := an_ptr_t(cexs_stack[r].node);
    if (y^.kind = 137) and (y^.op = 14) and
       (y^.opnd[2]^.kind in [77..87, 101, 200]) then
      if (an_ptr_t(y^.opnd[2])^.int_value mod 8 = 0) and
         (y^.desc.w8 = 8) then begin
        d.size := 1;
        m := an_ptr_t(y^.opnd[2])^.int_value div 8;
        cexs_stack[r].node := y^.opnd[1];
        if m <> 0 then
          cexs_stack[r].node := add_dn(cexs_stack[r].node,
                                       cexs_stack[r].sym, m);
      end
      else if (cexs_stack[l].node^.kind in [77..87, 101, 200]) and
              (y^.desc.w6 <= 4) and
              (y^.desc.w8 >= cexs_stack[l].node^.int_value) then begin
        v1 := y^.desc.w6 * 8 - y^.desc.w8 + cexs_stack[l].node^.int_value -
              an_ptr_t(y^.opnd[2])^.int_value;
        with cexs_stack[l] do begin
          m := v1 mod 8;
          node := smcontk(81, m);
          typ.low := m;
          typ.high := m;
        end;
        with cexs_stack[r] do begin
          node := an_ptr_t(node)^.opnd[1];
          node := add_dn(node, sym, y^.desc.w6 - v1 div 8 - 1);
          typ.size := 1;
        end;
        d.size := 1;
      end;
  end
  else if op = 12 then begin
    if cexs_stack[l].node = cexs_stack[r].node then begin
      if (d.w8 >= 0) and (d.w8 <= 31) and (d.w8 in [3, 4, 7, 12, 15]) then
        v1 := 255
      else
        v1 := 0;
      res := smcontk(81, v1);
      goto 40;
    end;
    if (d.w8 = 2) or (d.w8 = 3) or (d.w8 = 5) or (d.w8 = 4) then
      if not ((cexs_stack[l].node^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) and
              (an_ptr_t(cexs_stack[l].node)^.phase * [2, 12] <> [])) then
        if (cexs_stack[r].node^.kind in [77..87, 101, 200]) and
           (cexs_stack[r].node^.int_value = 0) then
          case d.w8 of
            3: d.w8 := 7;
            2: d.w8 := 6;
            5: begin
              v1 := 0;
              res := smcontk(81, v1);
              goto 40;
            end;
            4: begin
              v1 := 255;
              res := smcontk(81, v1);
              goto 40;
            end;
          end
        else if (cexs_stack[l].node^.kind in [77..87, 101, 200]) and
                (cexs_stack[l].node^.int_value = 0) then
          case d.w8 of
            4: d.w8 := 7;
            5: d.w8 := 6;
            2: begin
              v1 := 0;
              res := smcontk(81, v1);
              goto 40;
            end;
            3: begin
              v1 := 255;
              res := smcontk(81, v1);
              goto 40;
            end;
          end;
    x := an_ptr_t(cexs_stack[l].node);
    if ((d.w8 = 7) or (d.w8 = 6)) and (x^.kind = 137) and (x^.op = 9) and
       (x^.opnd[2]^.kind in [77..87, 101, 200]) and
       (cexs_stack[r].node^.kind in [77..87, 101, 200]) then begin
      m := an_ptr_t(x^.opnd[2])^.int_value;
      cv := cexs_stack[r].node^.int_value;
      if m = 0 then
        goto 60;
      if ((m - 1) & m) <> 0 then
        goto 60;
      if (m <> cv) and (cv <> 0) then
        goto 60;
      w := 0;
      while not odd(m) do begin
        m := rshft(m, 1);
        w := w + 1;
      end;
      cexs_stack[l].node := smcontk(81, w);
      if cv <> 0 then
        if d.w8 = 7 then
          d.w8 := 6
        else
          d.w8 := 7;
      d.size := d.w6;
      d.w6 := 1;
      cexs_stack[r].node := x^.opnd[1];
      op := 11;
      goto 60;
    end;
    if (d.w8 = 7) or (d.w8 = 6) then
      if (cexs_stack[l].node^.kind in [77..87, 101, 200]) and
         (cexs_stack[l].node^.int_value = 0) then begin
        y := an_ptr_t(cexs_stack[r].node);
        if (y^.kind = 137) and (y^.op = 18) and (y^.desc.w6 = 1) then begin
          res := y^.opnd[1];
          goto 40;
        end;
      end;
  end
  else if (op = 9) or (op = 10) then begin
    x := an_ptr_t(cexs_stack[l].node);
    y := an_ptr_t(cexs_stack[r].node);
    if (x^.kind = 137) and (x^.op = 8) and (y^.kind = 137) and
       (y^.op = 8) then begin
      cexs_stack[l].node := x^.opnd[1];
      cexs_stack[r].node := y^.opnd[1];
      if op = 9 then
        op := 10
      else
        op := 9;
      add_tn(op, d, l, r);
      add_tn(8, d, l, l);
      return;
    end;
  end
  else if (op = 1) or (op = 2) then begin
    x := an_ptr_t(cexs_stack[l].node);
    y := an_ptr_t(cexs_stack[r].node);
    if op = 1 then
      c := 0
    else
      c := 4;
    if (x^.kind = 137) and (x^.op = 7) then
      c := c + 2;
    if (y^.kind = 137) and (y^.op = 7) then
      c := c + 1;
    if (c <> 0) and (c <> 4) then begin
      case c of
        5, 1: cexs_stack[r].node := y^.opnd[1];
        6, 2: cexs_stack[l].node := x^.opnd[1];
        7, 3: begin
          cexs_stack[l].node := x^.opnd[1];
          cexs_stack[r].node := y^.opnd[1];
        end;
        otherwise ;
      end;
      case c of
        2, 1: op := 2;
        6, 5: op := 1;
        otherwise ;
      end;
      if (c = 2) or (c = 7) then begin
        e := cexs_stack[l];
        cexs_stack[l] := cexs_stack[r];
        cexs_stack[r] := e;
        cexs_stack[l].typ := cexs_stack[r].typ;
      end;
      add_tn(op, d, l, r);
      if (c = 3) or (c = 6) then
        add_tn(7, d, l, l);
      return;
    end;
  end;

  { A constant right operand. }
60:
  res := cexs_stack[r].node;
  if not (res^.kind in [77..87, 101, 200]) then
    goto 10;
  case op of
    3:
      if res^.int_value = 1 then
        goto 61
      else if res^.int_value = -1 then begin
        add_tn(7, d, l, l);
        cexs_23bc := l;
        return;
      end
      else if res^.int_value <> 0 then
        goto 10
      else if 12 in getphase(cexs_stack[l].node) then
        goto 10
      else
        goto 40;
    4:
      if res^.int_value = 1 then
        goto 61
      else if res^.int_value = -1 then begin
        add_tn(7, d, l, l);
        cexs_23bc := l;
        return;
      end
      else if d.rlen = 1 then begin
        if (res^.int_value < 256) and (res^.int_value >= -128) then
          goto 20;
        res := smcontk(81, 0);
        goto 40;
      end
      else if d.rlen = 2 then begin
        if (res^.int_value < 65536) and (res^.int_value >= -32768) then
          goto 20;
        res := smcontk(81, 0);
        goto 40;
      end
      else
        goto 20;
    9: begin
      if res^.int_value = 0 then
        if not (12 in getphase(cexs_stack[l].node)) then
          goto 40;
      if res^.int_value <> -1 then
        goto 10;
      goto 61;
    end;
    2:
      if res^.int_value = 1 then begin
        x := an_ptr_t(cexs_stack[l].node);
        if (x^.kind = 137) and (x^.op = 7) then begin
          cexs_stack[l].node := x^.opnd[1];
          add_tn(8, d, l, l);
          cexs_23bc := l;
          return;
        end;
        goto 20;
      end
      else if res^.int_value <> 0 then
        goto 10
      else
        goto 61;
    10: begin
      if res^.int_value = -1 then
        if not (12 in getphase(cexs_stack[l].node)) then
          goto 40;
      if res^.int_value <> 0 then
        goto 10;
      goto 61;
    end;
    44:
      if res^.int_value = 0 then
        goto 61
      else if res^.int_value = -1 then begin
        add_tn(8, d, l, l);
        cexs_23bc := l;
        return;
      end
      else
        goto 10;
    28, 27, 50, 49, 1:
      if res^.int_value <> 0 then
        goto 10
      else
        goto 61;
    otherwise
      goto 10;
  end;
61:
  res := cexs_stack[l].node;
  goto 40;

  { The other operators: the real ones first. }
80:
  if op in [34..38, 40, 41] then begin
    { The real constants. }
    for i := l to r do begin
      x := an_ptr_t(cexs_stack[i].node);
      if (x^.kind <> 89) and (x^.kind <> 88) then
        if (i <> r) or not (x^.kind in [77..87, 101, 200]) or
           (op <> 42) then
          goto 70;
      if x^.kind in [77..87, 101, 200] then begin
        rr := x^.int_value;
        b := rr;
      end
      else if i = l then
        a := x^.real_value
      else
        b := x^.real_value;
    end;
    if op = 41 then
      if not ((d.w6 >= 0) and (d.w6 <= 31) and
              (d.w6 in [0..2, 4..7, 9..11])) then
        goto 70;
    status := pfm_$cleanup(crec);
    if status.all <> pfm_$cleanup_set then
      if (status.subsys = 5) or (status.subsys = 0) then begin
        pfm_$enable;
        goto 20;
      end
      else
        pfm_$signal(status);
    case op of
      34: a := a + b;
      35: a := a - b;
      38: a := -a;
      36: a := a * b;
      37: a := a / b;
      40:
        case d.w8 of
          7: if a = b then v1 := 255 else v1 := 0;
          6: if a <> b then v1 := 255 else v1 := 0;
          5, 13: if a < b then v1 := 255 else v1 := 0;
          2, 14: if a > b then v1 := 255 else v1 := 0;
          3, 15: if a <= b then v1 := 255 else v1 := 0;
          4, 12: if a >= b then v1 := 255 else v1 := 0;
          otherwise ;
        end;
      41:
        case d.w6 of
          0: a := abs(a);
          11: begin
            if d.rlen >= 6 then begin
              pfm_$rls_cleanup(crec, status);
              goto 20;
            end;
            v1 := round(a);
          end;
          10: begin
            if d.rlen >= 6 then begin
              pfm_$rls_cleanup(crec, status);
              goto 20;
            end;
            v1 := trunc(a);
          end;
          7: a := arctan(a);
          2: a := cos(a);
          6: a := exp(a);
          4: a := ln(a);
          5: begin
            ftn_$dlog10(rr, a);
            a := rr;
          end;
          1: a := sin(a);
          9: a := sqrt(a);
          otherwise ;
        end;
      otherwise ;
    end;
    if (op = 40) or ((op = 41) and ((d.w6 = 11) or (d.w6 = 10))) then
      res := smcontk(81, v1)
    else if d.rlen = 7 then
      res := dpcontk(a)
    else
      res := rlcontk(a);
    pfm_$rls_cleanup(crec, status);
    goto 40;

    { Not all real constants: identities. }
70:
    if ((op = 35) or (op = 34)) and not flag then begin
      x := an_ptr_t(cexs_stack[l].node);
      y := an_ptr_t(cexs_stack[r].node);
      if op = 34 then
        c := 0
      else
        c := 4;
      if (x^.kind = 137) and (x^.op = 38) then
        c := c + 2;
      if (y^.kind = 137) and (y^.op = 38) then
        c := c + 1;
      if (c <> 0) and (c <> 4) then begin
        case c of
          5, 1: cexs_stack[r].node := y^.opnd[1];
          6, 2: cexs_stack[l].node := x^.opnd[1];
          7, 3: begin
            cexs_stack[l].node := x^.opnd[1];
            cexs_stack[r].node := y^.opnd[1];
          end;
          otherwise ;
        end;
        case c of
          2, 1: op := 35;
          6, 5: op := 34;
          otherwise ;
        end;
        if (c = 2) or (c = 7) then begin
          e := cexs_stack[l];
          cexs_stack[l] := cexs_stack[r];
          cexs_stack[r] := e;
          cexs_stack[l].typ := cexs_stack[r].typ;
        end;
        add_tn(op, d, l, r);
        if (c = 3) or (c = 6) then
          add_tn(38, d, l, l);
        return;
      end;
    end;
75:
    res := cexs_stack[r].node;
    y := an_ptr_t(res);
    if (op = 40) and (cexs_stack[l].node = cexs_stack[r].node) then begin
      if (d.w8 >= 0) and (d.w8 <= 31) and (d.w8 in [2, 5, 7, 12, 15]) then
        v1 := 255
      else
        v1 := 0;
      res := smcontk(81, v1);
      goto 40;
    end;
    if op = 41 then
      case d.w6 of
        9:
          if (res^.kind = 137) and (y^.op = 36) and
             (y^.opnd[1] = y^.opnd[2]) then begin
            res := y^.opnd[1];
            cexs_stack[l].node := res;
            d.w6 := 0;
            goto 20;
          end;
        6:
          if (res^.kind = 137) and (y^.op = 41) and (y^.desc.w6 = 4) then
          begin
            res := y^.opnd[1];
            goto 40;
          end;
        4:
          if (res^.kind = 137) and (y^.op = 41) and (y^.desc.w6 = 6) then
          begin
            res := y^.opnd[1];
            goto 40;
          end;
        7:
          if (res^.kind = 137) and (y^.op = 41) and (y^.desc.w6 = 3) then
          begin
            res := y^.opnd[1];
            goto 40;
          end;
        3:
          if (res^.kind = 137) and (y^.op = 41) and (y^.desc.w6 = 7) then
          begin
            res := y^.opnd[1];
            goto 40;
          end;
        otherwise ;
      end
    else if (op = 36) and (cexs_stack[l].node = cexs_stack[r].node) then
      if (res^.kind = 137) and (y^.op = 41) and (y^.desc.w6 = 9) then begin
        res := y^.opnd[1];
        goto 40;
      end;
    if (res^.kind <> 89) and (res^.kind <> 88) then
      goto 10;
    b := y^.real_value;
    case op of
      34, 35:
        if b = 0.0 then
          goto 61
        else
          goto 10;
      36: begin
        if b = 0.0 then
          goto 40;
        if b <> 1.0 then
          goto 10;
        goto 61;
      end;
      37: begin
        if b = 1.0 then
          goto 61;
        bb.d := b;
        if not ((bb.d <> 0.0) and (bb.lo = 0)) then
          goto 10;
        if (bb.hi & 16#FFFFF) <> 0 then
          goto 10;
        if res^.kind = 89 then
          cexs_stack[r].node := dpcontk(1.0 / b)
        else
          cexs_stack[r].node := rlcontk(1.0 / b);
        add_tn(36, d, l, r);
        return;
      end;
      otherwise
        goto 10;
    end;
    { The end of the real operators. }
  end
  else if op = 51 then begin
    if not (cexs_stack[l].node^.kind in [80..86, 200]) then
      goto 20;
    if cexs_stack[l].node^.int_value = 0 then
      res := cexs_stack[l + 2].node
    else
      res := cexs_stack[l + 1].node;
    goto 40;
  end
  else if (op = 24) and (cexs_stack[l].node = cexs_stack[r].node) then begin
    if (d.w8 >= 0) and (d.w8 <= 31) and (d.w8 in [3, 4, 7, 12, 15]) then
      v1 := 255
    else
      v1 := 0;
    res := smcontk(81, v1);
    goto 40;
  end
  else if op = 18 then begin
    res := cexs_stack[l].node;
    x := an_ptr_t(res);
    if res^.kind = 137 then begin
      if x^.op = 18 then begin
        if d.w6 < d.rlen then begin
          if (d.flags.signed <> x^.desc.flags.signed) and
             x^.desc.flags.signed then
            goto 10;
          if x^.desc.w6 >= x^.desc.rlen then
            goto 10;
          d.flags.signed := x^.desc.flags.signed;
          d.w6 := x^.desc.w6;
          cexs_stack[l].node := x^.opnd[1];
          goto 10;
        end;
        if d.rlen = x^.desc.w6 then begin
          res := x^.opnd[1];
          goto 40;
        end;
        if x^.desc.w6 <= d.rlen then
          goto 10;
        d.w6 := x^.desc.w6;
        cexs_stack[l].node := x^.opnd[1];
        goto 10;
      end;
      if x^.op <> 14 then
        goto 10;
      if d.flags.signed <> x^.desc.flags.signed then
        goto 10;
      if (x^.opnd[2]^.kind in [77..87, 101, 200]) and
         (an_ptr_t(x^.opnd[2])^.int_value = 0) and (x^.desc.w8 = 8) then
      begin
        d.w6 := 1;
        cexs_stack[l].node := x^.opnd[1];
        goto 10;
      end;
      cexs_stack[l].node := x^.opnd[1];
      op := 14;
      d.w6 := x^.desc.w6;
      d.w8 := x^.desc.w8;
      if cexs_23bc <> l then begin
        cexs_23bc := cexs_23bc + 1;
        cexs_stack[cexs_23bc] := cexs_stack[l];
      end;
      push(x^.opnd[2]);
      add_tn(14, d, cexs_23bc - 1, cexs_23bc);
      if cexs_23bc <> l then begin
        cexs_stack[l] := cexs_stack[cexs_23bc];
        cexs_23bc := cexs_23bc - 1;
      end;
      return;
    end;
    if res^.kind in [77..87, 101, 200] then begin
      v1 := x^.int_value;
      if d.flags.signed then begin
        if d.w6 = 1 then begin
          v1 := v1 & 16#FF;
          if v1 > 127 then
            v1 := v1 - 256;
        end
        else if d.w6 = 2 then begin
          v1 := v1 & 16#FFFF;
          if v1 > 32767 then
            v1 := v1 - 65536;
        end
        else if d.w6 <> 4 then
          return;
      end
      else if d.w6 = 1 then
        v1 := v1 & 16#FF
      else if d.w6 = 2 then
        v1 := v1 & 16#FFFF
      else if d.w6 <> 4 then
        return;
      res := smcontk(81, v1);
      goto 40;
    end;
    if (d.rlen < d.w6) and not (1 in getphase(res)) and
       (cexs_stack[l].node^.kind <> 195) then begin
      if (18 in cargs_$options.opt_on) and (cexs_stack[l].node <> nil) then
      begin
        x := an_ptr_t(cexs_stack[l].node);
        if (x^.kind = 146) or (x^.kind = 163) or (x^.kind = 147) then
          case x^.kind of
            147: begin
              y := an_ptr_t(x^.base);
              if y^.kind = 146 then begin
                x := an_ptr_t(y^.base);
                if (x^.kind = 195) or (x^.kind = 163) then
                  if (x^.kind <> 163) or (x^.xp[2]^.kind = 111) then begin
                    if x^.kind <> 195 then
                      goto 20;
                    if x^.xp[3]^.kind = 111 then
                      goto 20;
                  end;
              end;
            end;
            146: begin
              y := an_ptr_t(x^.base);
              if (y^.kind = 195) or (y^.kind = 163) then
                if (y^.kind <> 163) or (y^.xp[2]^.kind = 111) then begin
                  if y^.kind <> 195 then
                    goto 20;
                  if y^.xp[3]^.kind = 111 then
                    goto 20;
                end;
            end;
            163:
              if x^.xp[2]^.kind = 111 then
                goto 20;
          end;
      end;
      res := add_dn(cexs_stack[l].node, cexs_stack[l].sym, d.w6 - d.rlen);
      goto 40;
    end;
    if d.rlen = d.w6 then
      goto 40;
  end
  else if op = 63 then begin
    if not (cexs_stack[l].node^.kind in [109, 145..147, 164, 205]) then
      return;
    d.w8 := 0;
  end;

  { Calls entered in the routine's references. }
10:
  if (op = 16) or (op = 15) then
    add_routine_reference(il_180, cexs_stack[l].node);

  { A product or shift of a sum by a constant to kfold. }
20:
  if 2 in cargs_$options.opt_on then
    with cexs_stack[l] do
      if node^.kind = 137 then
        if (an_ptr_t(node)^.op = 3) or (an_ptr_t(node)^.op = 27) then begin
          x := an_ptr_t(an_ptr_t(node)^.opnd[1]);
          y := an_ptr_t(an_ptr_t(node)^.opnd[2]);
          if (x^.kind = 137) and (y^.kind in [77..87, 101, 200]) then
            if (x^.op = 1) or (x^.op = 18) or (x^.op = 2) then
              if (x^.op = 2) or (x^.op = 1) then
                kfold(nil, node)
              else if x^.opnd[1]^.kind = 137 then
                if (an_ptr_t(x^.opnd[1])^.op = 2) or
                   (an_ptr_t(x^.opnd[1])^.op = 1) then
                  kfold(nil, node);
        end;

  { The node. }
30:
  c := r - l + 1;
  res := gspace(c * 4 + 40);
  x := an_ptr_t(res);
  x^.kind := 137;
  x^.opnd[1] := cexs_stack[l].node;
  ph := getphase(x^.opnd[1]);
  w := 2;
  for i := l + 1 to r do begin
    x^.opnd[w] := cexs_stack[i].node;
    ph := ph + getphase(x^.opnd[w]);
    w := w + 1;
  end;
  ph := ph - [5, 8, 9];
  if (op = 16) or (op = 15) then
    ph := ph - [0..4, 16, 19];
  if (1 in ph) and (op <> 26) then
    ph := ph - [1] + [2];
  if op in [15, 16, 47, 48, 54, 55] then
    ph := ph + [12];
  x^.phase := ph;
  x^.regs := 0;
  x^.regs := regs;
  x^.l12 := 0;
  x^.op := op;
  x^.desc := d;
  x^.uses := 0;
  x^.count := c;
  if (op in [34..41]) and (il_180 <> nil) then
    c_blk_ptr_t(il_180)^.bits.b376_7 := true
  else if (op = 16) or (op = 15) then
    if reg_save(res) * [18..23] <> [18..23] then
      c_blk_ptr_t(il_180)^.bits.b376_7 := true;

  { The result. }
40:
  with cexs_stack[l] do begin
    node := res;
    if node^.kind in [80..86, 200] then
      if typ.base^.kind = 122 then begin
        typ.low := node^.int_value;
        typ.high := node^.int_value;
        if typ.base^.signed then begin
          if (d.rlen <> 4) and (typ.low >= -128) and (typ.low <= 127) then
            typ.size := 1
          else if (d.rlen <> 4) and (typ.low >= -32768) and
                  (typ.low <= 32767) then
            typ.size := 2;
        end
        else if ((typ.low & 16#FF) = typ.low) and (d.rlen <> 4) then
          typ.size := 1
        else if ((typ.low & 16#FFFF) = typ.low) and (d.rlen <> 4) then
          typ.size := 2;
      end;
  end;
  if l < r then
    cexs_23bc := l;
end;

{ buildtreenode - see add_node.ins.pas.

  0x0A4C54, 0xF4 bytes, link #-36: d copied to a frame record first;
  gspace(count * 4 + 40), 137; the operands copied from ops and their
  getphase or-ed; without 5, 8, 9; for calls (16, 15) without 0..4, 16,
  19; 1 becomes 2 unless op is 26; 12 added for the operators in the
  set at 0x0A4C38 (15, 16, 47, 48, 54, 55); +4 the phase, +10..+15
  cleared, +36 op, +20 d, +16 1 (the use count), +38 count.  The node
  in A0.

  Not known from the original:
  - the names. }

function buildtreenode;
var
  dl: add_node_$desc_t;                 { -16 }
  x: an_ptr_t;                          { -24 }
  ph: add_node_$phase_t;                { D5 }
  i: integer;
begin
  dl := d;
  x := gspace(count * 4 + 40);
  x^.kind := 137;
  ph := [];
  for i := 1 to count do begin
    x^.opnd[i] := ops[i];
    ph := ph + getphase(x^.opnd[i]);
  end;
  ph := ph - [5, 8, 9];
  if (op = 16) or (op = 15) then
    ph := ph - [0..4, 16, 19];
  if (1 in ph) and (op <> 26) then
    ph := ph - [1] + [2];
  if op in [15, 16, 47, 48, 54, 55] then
    ph := ph + [12];
  x^.phase := ph;
  x^.xl2[2] := 0;
  x^.xw[7] := 0;
  x^.op := op;
  x^.desc := dl;
  x^.uses := 1;
  x^.count := count;
  buildtreenode := il_$node_ptr_t(x);
end;
