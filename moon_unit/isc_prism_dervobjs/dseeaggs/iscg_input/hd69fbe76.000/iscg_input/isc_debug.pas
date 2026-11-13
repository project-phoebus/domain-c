{ isc_debug - the ISC's printers (a DSEE derived object of the iscg_input
  description; cc.a88k only): an IL node with its static and inherited
  attributes (isc_print_il_node, pass_1's trace under sw12/sw13), a
  solution with its attributes (dump_solution, the traces of isc_main,
  isc_call_handling and isc_cse_handling), a set of solution kinds
  (print_permissible_solution_kinds, pass_1's trace) and the
  indentation they share.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x0BD1DC  isc_print_il_node
    --------  0x0D6110  indent
    --------  0x0D6174  dump_solution
    --------  0x0D8E1A  print_permissible_solution_kinds
  A5 0x44E9A8: no module variables.  (-4,A5) is the run time's output.
  Below it, from A5-436, eight bytes nothing reads and 53 eight-byte
  cells (A5-428 .. A5-12) each holding `jmp abs.l' to a far part of
  isc_print_il_node (docs/rev889-patterns.md 164): the compiler's,
  initialized by .rwdi, not the source's.

  The span after isc_print_il_node's code (0x0D3A9C .. 0x0D6110) holds
  its strings and the identifier tables of its writes (il$t's at
  0x0D4FA4, il_$kind_t's, the operators' ...); a copy of several tables
  also sits among its arms (tools/cc_enumnames.py), where the code of
  more than 32 KB keeps them within reach.

  What the generator emits (docs/questions.md 151, 270; docs/iscg-
  design.md 5 and "isc_debug's generated regions"): the regions between
  the comments `iscg: begin ...' and `iscg: end' are derived from the
  generator's input and will be written by it; the rest is fixed text
  (translated as usual).  isc_print_il_node's arms are one per IL node
  kind of il$t (isc_enumeration.ins.pas), in il$t's (alphabetical)
  order: the code's arms lie in that order and its compare chain for
  the comparison operators tests them in that order.  Each arm writes
  the node's static attributes under their names, then every node gets
  the inherited attributes.  The view records (pin_<kind>_t,
  ds_solution_t) carry the attribute names the image prints; their
  field offsets are read off the code.

  The writes are dpc gap 4 (docs/dpc-gaps.md 4): the check drops them,
  which also keeps isc_print_il_node below 32 KB; at its full size dpc
  refuses it (docs/dpc-gaps.md 46: the far arms Rev 8.89 reaches
  through the thunks).

  Not known from the original: the parameters' and locals' names, the
  types' names, the view records' unnamed fillers. }
module isc_debug;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas';
%include 'lang2/source/isc/isc_consts.ins.pas';
%include 'lang2/source/isc/isc_types.ins.pas';
%include 'lang2/source/isc/isc_routine_externs.ins.pas';
%include 'lang2/source/isc/isc_var_externs.ins.pas';

type

  { The tree operators (a tree node's +36; the name table at

    0x20FD9A, 90 names). }
  pin_top_t = (
    nop_top, add_top, sub_top, mul_top, div_top, divide_top, mod_top,
    neg_top, not_top, and_top, or_top, bit_test_top, compare_top,
    index_top, unpack_top, call_top, func_call_top, value_top,
    extend_top, set_and_top, set_or_top, set_diff_top, set_extend_top,
    set_compare_top, agg_compare_top, bit_set_top, addr_top, lshf_top,
    rshf_top, abs_top, isc_call_top, isc_func_call_top,
    isc_func_call_hidden_temp_top, isc_mul_top, f_add_top, f_sub_top,
    f_mul_top, f_div_top, f_neg_top, f_extend_top, f_compare_top,
    f_math_top, f_expon_top, expon_top, eor_top, max_top, min_top,
    sr_top, chk_top, alshf_top, arshf_top, cc_c3expr_ptop, cc_logor_ptop,
    cc_logand_ptop, cc_assign_ptop, cc_post_id_ptop, cc_comma_ptop,
    cc_lognot_ptop, ref_expr_top, signed_div_top, unsigned_div_top,
    signed_mod_top, unsigned_mod_top, align_top, isc_addr_top,
    allocate_dynamic_space_top, cache_top, isc_fio_init, strcmp_top,
    strlen_top, strncmp_top, isc_select, set_bit_in_set_top,
    set_range_in_set_top, isc_signed_rem_top, isc_unsigned_rem_top,
    isc_signed_mod_top, isc_unsigned_mod_top, isc_agg_cmp_top,
    isc_agg_lex_cmp_top, range_check_top, f_range_check_top,
    mark_dynamic_space_top, extract_bit_field_top, bit_field_cmp_top,
    physical_top, ada_expon_top, f_ada_expon_top, pas_get_chk_ptop,
    illegal_top);

  { The assignment operators (an assignment's +76; the name tables at
    0x210354 and 0x0BE472, 38 names). }
  pin_aop_t = (
    scalar_aop, add_to_aop, sub_from_aop, and_to_aop, or_to_aop,
    eor_to_aop, agg_aop, set_and_to_aop, set_or_to_aop,
    set_diff_from_aop, pack_aop, fp_aop, field_aop, not_to_aop,
    neg_to_aop, lshft_to_aop, rshft_to_aop, bset_to_aop, bclr_to_aop,
    f_add_to_aop, f_sub_from_aop, f_mul_to_aop, f_div_by_aop,
    mul_to_aop, div_by_aop, agg_len_aop, isc_mul_to_aop, strcat_aop,
    strcpy_aop, strncat_aop, strncpy_aop, isc_agg_aop, isc_slice_aop,
    isc_agg_zero_aop, isc_fill_aop, range_check_to_aop,
    f_range_check_to_aop, illegal_aop);
  { The FORTRAN symbol kinds, data classes, variables' and blocks'
    allocation kinds and address constants' keys, as the image names
    them (isc_print_il_node's identifier tables 0x0C8A5A, 0x0C8AD2,
    0x0C7A7C, 0x0C8500, 0x0BD23A). }
  pin_fsym_kind_t = (
    xnone, routine, symbolic_constant, variable, alternate_return,
    common, xlabel, namelist_groupname, stmt_func);
  pin_fdtype_t = (
    none, xbinteger, xsinteger, xlinteger, xreal, xdoubleprecision,
    xcomplex, xcharacter, xblogical, xslogical, xllogical, xaddress,
    nomore, xdpcomplex);
  pin_vat_t = (
    local_vat, static_vat, dynm_vat, extern_vat, externdef_vat,
    param_vat, xdynm_vat, xstatic_vat, xextrndef_vat, based_vat,
    sect_vat, absolute_vat);
  pin_bat_t = (
    local_bat, forward_bat, extern_bat, param_bat);
  pin_ac_t = (
    xsb_ac, xdb_ac, extern_ac, common_ac, ext_proc_arg_ac,
    lcl_proc_arg_ac, proc_ac, jmp_ac, nil_ac, lcl_proc_ac, db_ac,
    str_ac, literal_ac);

  { Any IL node: its kind (+2). }
  pin_node_ptr_t = ^pin_node_t;
  pin_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
  end;

  { iscg: begin print_il_node views }
  { One view per IL node kind isc_print_il_node prints, named and laid
    out as its static attributes (the generator's description of the
    IL; only the fields printed are named). }
  { addr_con }
  pin_addr_con_ptr_t = ^pin_addr_con_t;
  pin_addr_con_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    ref: univ_ptr;                  { +8 }
    pdisp: integer32;               { +12 }
    disp: integer32;                { +16 }
    f20: packed record              { +20 }
      key: 0..255;                  { +20 .7 .. +20 .0 }
      x21_7: 0..255;
      end;
  end;

  { argument_block_location_ob }
  pin_argument_block_location_ob_ptr_t = ^pin_argument_block_location_ob_t;
  pin_argument_block_location_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    offset: integer32;              { +4 }
  end;

  { assign_node }
  pin_assign_node_ptr_t = ^pin_assign_node_t;
  pin_assign_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
    x46: array [46..47] of char;    { +46 }
    size: 0..16#7FFFFFFF;           { +48 }
    rlen: 0..65535;                 { +52 }
    opmod: 0..65535;                { +54 }
    opmod1: 0..65535;               { +56 }
    f58: packed record              { +58 }
      overflow_check: boolean;      { +58 .7 }
      signed: boolean;              { +58 .6 }
      x58_5: 0..16383;
      end;
    x60: array [60..75] of char;    { +60 }
    op: pin_aop_t;                  { +76 }
  end;

  { binteger_ob }
  pin_binteger_ob_ptr_t = ^pin_binteger_ob_t;
  pin_binteger_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { ubinteger_ob }
  pin_ubinteger_ob_ptr_t = ^pin_ubinteger_ob_t;
  pin_ubinteger_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { bit_field_assign }
  pin_bit_field_assign_ptr_t = ^pin_bit_field_assign_t;
  pin_bit_field_assign_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
  end;

  { blk_end_node }
  pin_blk_end_node_ptr_t = ^pin_blk_end_node_t;
  pin_blk_end_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..47] of char;    { +16 }
    bp: ^pin_procedure_blk_t;       { +48 }
  end;

  { block_entry_node }
  pin_block_entry_node_ptr_t = ^pin_block_entry_node_t;
  pin_block_entry_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
  end;

  { blogical_ob }
  pin_blogical_ob_ptr_t = ^pin_blogical_ob_t;
  pin_blogical_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { branch_node }
  pin_branch_node_ptr_t = ^pin_branch_node_t;
  pin_branch_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
  end;

  { case_node_range_check }
  pin_case_node_range_check_ptr_t = ^pin_case_node_range_check_t;
  pin_case_node_range_check_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
  end;

  { case_node_no_range_check }
  pin_case_node_no_range_check_ptr_t = ^pin_case_node_no_range_check_t;
  pin_case_node_no_range_check_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
  end;

  { cbranch_node }
  pin_cbranch_node_ptr_t = ^pin_cbranch_node_t;
  pin_cbranch_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
    x46: array [46..59] of char;    { +46 }
    sense: boolean;                 { +60 }
  end;

  { cc_call }
  pin_cc_call_ptr_t = ^pin_cc_call_t;
  pin_cc_call_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..15] of char;      { +4 }
    blkp: ^pin_procedure_blk_t;     { +16 }
  end;

  { char_ob }
  pin_char_ob_ptr_t = ^pin_char_ob_t;
  pin_char_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { char_string_ob }
  pin_char_string_ob_ptr_t = ^pin_char_string_ob_t;
  pin_char_string_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..15] of char;      { +4 }
    len: 0..65535;                  { +16 }
  end;

  { cmp_tree_node }
  pin_cmp_tree_node_ptr_t = ^pin_cmp_tree_node_t;
  pin_cmp_tree_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..19] of char;      { +4 }
    size: 0..16#7FFFFFFF;           { +20 }
    x24: array [24..25] of char;    { +24 }
    opmod: 0..65535;                { +26 }
    opmod1: 0..65535;               { +28 }
    f30: packed record              { +30 }
      x30_7: boolean;
      signed: boolean;              { +30 .6 }
      x30_5: 0..7;
      range_chk: boolean;           { +30 .2 }
      x30_1: 0..1023;
      end;
    x32: array [32..35] of char;    { +32 }
    op: pin_top_t;                  { +36 }
  end;

  { complex_ob }
  pin_complex_ob_ptr_t = ^pin_complex_ob_t;
  pin_complex_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..11] of char;      { +4 }
    real: integer32;                { +12 }
    imag: integer32;                { +16 }
  end;

  { cs_node }
  pin_cs_node_ptr_t = ^pin_cs_node_t;
  pin_cs_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..27] of char;      { +4 }
    len_rlen: 0..65535;             { +28 }
    maxlen: integer;                { +30 }
  end;

  { cs_temp }
  pin_cs_temp_ptr_t = ^pin_cs_temp_t;
  pin_cs_temp_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..15] of char;      { +4 }
    disp: integer32;                { +16 }
    vat: pin_vat_t;                 { +20 }
    size: integer;                  { +22 }
  end;

  { cse_parent_ob }
  pin_cse_parent_ob_ptr_t = ^pin_cse_parent_ob_t;
  pin_cse_parent_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    cse_parent: univ_ptr;           { +4 }
  end;

  { cse_use_ob }
  pin_cse_use_ob_ptr_t = ^pin_cse_use_ob_t;
  pin_cse_use_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    phase_state: add_node_$phase_t; { +4 }
    x8: array [8..19] of char;      { +8 }
    cse_parent: univ_ptr;           { +20 }
  end;

  { dindex_node }
  pin_dindex_node_ptr_t = ^pin_dindex_node_t;
  pin_dindex_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    phase_state: add_node_$phase_t; { +4 }
    x8: array [8..21] of char;      { +8 }
    f22: packed record              { +22 }
      alignment: -128..127;         { +22 .7 .. +22 .0 }
      addr_bits: 0..255;            { +23 .7 .. +23 .0 }
      end;
    x24: array [24..31] of char;    { +24 }
    disp: integer32;                { +32 }
    x36: array [36..39] of char;    { +36 }
    scaled_index: 0..65535;         { +40 }
    rlen: 0..65535;                 { +42 }
  end;

  { disp_node }
  pin_disp_node_ptr_t = ^pin_disp_node_t;
  pin_disp_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    phase_state: add_node_$phase_t; { +4 }
    x8: array [8..21] of char;      { +8 }
    f22: packed record              { +22 }
      x22_7: 0..255;
      addr_bits: 0..255;            { +23 .7 .. +23 .0 }
      end;
    x24: array [24..31] of char;    { +24 }
    disp: integer32;                { +32 }
  end;

  { dpcomplex_ob }
  pin_dpcomplex_ob_ptr_t = ^pin_dpcomplex_ob_t;
  pin_dpcomplex_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..11] of char;      { +4 }
    real1: integer32;               { +12 }
    real2: integer32;               { +16 }
    imag1: integer32;               { +20 }
    imag2: integer32;               { +24 }
  end;

  { dpreal_ob }
  pin_dpreal_ob_ptr_t = ^pin_dpreal_ob_t;
  pin_dpreal_ob_t = record
    case integer of
      1: (
          b0: char;                 { +0 }
          b1: char;                 { +1 }
          kind: il_$kind_t;         { +2 }
          x4: array [4..11] of char; { +4 }
          value: double);           { +12 }
      2: (
          a2_x0: array [0..11] of char; { +0 }
          high_32_bits: integer32); { +12 }
      3: (
          a3_x0: array [0..15] of char; { +0 }
          low_32_bits: integer32);  { +16 }
  end;

  { entry_blk }
  pin_entry_blk_ptr_t = ^pin_entry_blk_t;
  pin_entry_blk_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..107] of char;     { +4 }
    ecb_offset: integer32;          { +108 }
    x112: array [112..187] of char; { +112 }
    psect: univ_ptr;                { +188 }
    dsect: univ_ptr;                { +192 }
    x196: array [196..293] of char; { +196 }
    f294: packed record             { +294 }
      slevel: -128..127;            { +294 .7 .. +294 .0 }
      x295_7: 0..255;
      end;
    x296: array [296..375] of char; { +296 }
    f376: packed record             { +376 }
      x376_7: 0..127;
      bat: 0..3;                    { +376 .0 .. +377 .7 }
      x377_6: 0..127;
      end;
  end;

  { eval_node }
  pin_eval_node_ptr_t = ^pin_eval_node_t;
  pin_eval_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
    x46: array [46..49] of char;    { +46 }
    oc: 0..65535;                   { +50 }
  end;

  { fortran_symbol }
  pin_fortran_symbol_ptr_t = ^pin_fortran_symbol_t;
  pin_fortran_symbol_t = record
    case integer of
      1: (
          b0: char;                 { +0 }
          b1: char;                 { +1 }
          kind: il_$kind_t;         { +2 }
          x4: array [4..9] of char; { +4 }
          f10: packed record        { +10 }
            x10_7: 0..15;
            dataclass: 0..15;       { +10 .3 .. +10 .0 }
            vat: 0..15;             { +11 .7 .. +11 .4 }
            x11_3: 0..15;
            end;
          address: integer32;       { +12 }
          x16: array [16..23] of char; { +16 }
          vattributes: isc_attr_set_t; { +24 }
          equiv_link: univ_ptr;     { +28 }
          x32: array [32..39] of char; { +32 }
          blk_ptr: univ_ptr;        { +40 }
          f44: packed record        { +44 }
            entity: 0..15;          { +44 .7 .. +44 .4 }
            x44_3: 0..3;
            by_value: boolean;      { +44 .1 }
            x44_0: 0..511;
            end;
          x46: array [46..47] of char; { +46 }
          lbl_root: univ_ptr);      { +48 }
      2: (
          a2_x0: array [0..11] of char; { +0 }
          disp: integer32);         { +12 }
  end;

  { function_blk }
  pin_function_blk_ptr_t = ^pin_function_blk_t;
  pin_function_blk_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..107] of char;     { +4 }
    ecb_offset: integer32;          { +108 }
    x112: array [112..187] of char; { +112 }
    psect: univ_ptr;                { +188 }
    dsect: univ_ptr;                { +192 }
    x196: array [196..293] of char; { +196 }
    f294: packed record             { +294 }
      slevel: -128..127;            { +294 .7 .. +294 .0 }
      x295_7: 0..255;
      end;
    x296: array [296..375] of char; { +296 }
    f376: packed record             { +376 }
      x376_7: 0..127;
      bat: 0..3;                    { +376 .0 .. +377 .7 }
      x377_6: 0..127;
      end;
  end;

  { insert_bit_field }
  pin_insert_bit_field_ptr_t = ^pin_insert_bit_field_t;
  pin_insert_bit_field_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
    x46: array [46..51] of char;    { +46 }
    rlen: 0..65535;                 { +52 }
    x54: array [54..75] of char;    { +54 }
    bit_size: 0..16#7FFFFFFF;       { +76 }
  end;

  { integer_ob }
  pin_integer_ob_ptr_t = ^pin_integer_ob_t;
  pin_integer_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { uinteger_ob }
  pin_uinteger_ob_ptr_t = ^pin_uinteger_ob_t;
  pin_uinteger_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { label_node }
  pin_label_node_ptr_t = ^pin_label_node_t;
  pin_label_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
  end;

  { linteger_ob }
  pin_linteger_ob_ptr_t = ^pin_linteger_ob_t;
  pin_linteger_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { ulinteger_ob }
  pin_ulinteger_ob_ptr_t = ^pin_ulinteger_ob_t;
  pin_ulinteger_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { llogical_ob }
  pin_llogical_ob_ptr_t = ^pin_llogical_ob_t;
  pin_llogical_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { namelist_constant_ob }
  pin_namelist_constant_ob_ptr_t = ^pin_namelist_constant_ob_t;
  pin_namelist_constant_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..15] of char;      { +4 }
    len: 0..65535;                  { +16 }
  end;

  { nlbranch_node }
  pin_nlbranch_node_ptr_t = ^pin_nlbranch_node_t;
  pin_nlbranch_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
  end;

  { physical_register_ob }
  pin_physical_register_ob_ptr_t = ^pin_physical_register_ob_t;
  pin_physical_register_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    loc: arg_loc_t;                 { +4 }
    reg: 0..65535;                  { +6 }
  end;

  { procedure_blk }
  pin_procedure_blk_ptr_t = ^pin_procedure_blk_t;
  pin_procedure_blk_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..107] of char;     { +4 }
    ecb_offset: integer32;          { +108 }
    x112: array [112..187] of char; { +112 }
    psect: univ_ptr;                { +188 }
    dsect: univ_ptr;                { +192 }
    x196: array [196..293] of char; { +196 }
    f294: packed record             { +294 }
      slevel: -128..127;            { +294 .7 .. +294 .0 }
      x295_7: 0..255;
      end;
    x296: array [296..375] of char; { +296 }
    f376: packed record             { +376 }
      x376_7: 0..127;
      bat: 0..3;                    { +376 .0 .. +377 .7 }
      x377_6: 0..127;
      end;
    f378: packed record             { +378 }
      x378_7: 0..63;
      returns_dynamic_results: boolean; { +378 .1 }
      x378_0: 0..511;
      end;
  end;

  { ptr_node }
  pin_ptr_node_ptr_t = ^pin_ptr_node_t;
  pin_ptr_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    phase_state: add_node_$phase_t; { +4 }
    x8: array [8..21] of char;      { +8 }
    f22: packed record              { +22 }
      alignment: -128..127;         { +22 .7 .. +22 .0 }
      addr_bits: 0..255;            { +23 .7 .. +23 .0 }
      end;
  end;

  { raise_exception }
  pin_raise_exception_ptr_t = ^pin_raise_exception_t;
  pin_raise_exception_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
  end;

  { real_ob }
  pin_real_ob_ptr_t = ^pin_real_ob_t;
  pin_real_ob_t = record
    case integer of
      1: (
          b0: char;                 { +0 }
          b1: char;                 { +1 }
          kind: il_$kind_t;         { +2 }
          x4: array [4..11] of char; { +4 }
          value: double);           { +12 }
      2: (
          a2_x0: array [0..11] of char; { +0 }
          high_32_bits: integer32); { +12 }
      3: (
          a3_x0: array [0..15] of char; { +0 }
          low_32_bits: integer32);  { +16 }
  end;

  { release_dynamic_space }
  pin_release_dynamic_space_ptr_t = ^pin_release_dynamic_space_t;
  pin_release_dynamic_space_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
  end;

  { return_node }
  pin_return_node_ptr_t = ^pin_return_node_t;
  pin_return_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    next: univ_ptr;                 { +8 }
    static_exception_frame: univ_ptr; { +12 }
    x16: array [16..41] of char;    { +16 }
    f42: packed record              { +42 }
      x42_7: 0..255;
      stmt_no: 0..65535;            { +43 .7 .. +44 .0 }
      x45_7: 0..255;
      end;
    x46: array [46..47] of char;    { +46 }
    opr: univ_ptr;                  { +48 }
    rlen: 0..65535;                 { +52 }
  end;

  { set_con_ob }
  pin_set_con_ob_ptr_t = ^pin_set_con_ob_t;
  pin_set_con_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..15] of char;      { +4 }
    len: 0..65535;                  { +16 }
  end;

  { slogical_ob }
  pin_slogical_ob_ptr_t = ^pin_slogical_ob_t;
  pin_slogical_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { sinteger_ob }
  pin_sinteger_ob_ptr_t = ^pin_sinteger_ob_t;
  pin_sinteger_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { usinteger_ob }
  pin_usinteger_ob_ptr_t = ^pin_usinteger_ob_t;
  pin_usinteger_ob_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    x4: array [4..7] of char;       { +4 }
    value: integer32;               { +8 }
  end;

  { sym_disp_node }
  pin_sym_disp_node_ptr_t = ^pin_sym_disp_node_t;
  pin_sym_disp_node_t = record
    b0: char;                       { +0 }
    b1: char;                       { +1 }
    kind: il_$kind_t;               { +2 }
    phase_state: add_node_$phase_t; { +4 }
    x8: array [8..21] of char;      { +8 }
    f22: packed record              { +22 }
      x22_7: 0..255;
      addr_bits: 0..255;            { +23 .7 .. +23 .0 }
      end;
    x24: array [24..31] of char;    { +24 }
    sym: univ_ptr;                  { +32 }
  end;

  { tree_node }
  pin_tree_node_ptr_t = ^pin_tree_node_t;
  pin_tree_node_t = record
    case integer of
      1: (
          b0: char;                 { +0 }
          b1: char;                 { +1 }
          kind: il_$kind_t;         { +2 }
          phase_state: add_node_$phase_t; { +4 }
          x8: array [8..9] of char; { +8 }
          f10: packed record        { +10 }
            phase_loc: 0..255;      { +10 .7 .. +10 .0 }
            phase_reg: 0..255;      { +11 .7 .. +11 .0 }
            end;
          f12: packed record        { +12 }
            phase_ftn_io_abnormal_flow: boolean; { +12 .7 }
            x12_6: 0..127;
            phase_asynchronous_return: boolean; { +13 .7 }
            x13_6: 0..127;
            end;
          f14: packed record        { +14 }
            phase_pfm_cleanup: boolean; { +14 .7 }
            x14_6: 0..32767;
            end;
          x16: array [16..19] of char; { +16 }
          size: 0..16#7FFFFFFF;     { +20 }
          rlen: 0..65535;           { +24 }
          opmod: 0..65535;          { +26 }
          opmod1: 0..65535;         { +28 }
          f30: packed record        { +30 }
            overflow_check: boolean; { +30 .7 }
            signed: boolean;        { +30 .6 }
            x30_5: 0..7;
            range_chk: boolean;     { +30 .2 }
            x30_1: 0..1023;
            end;
          x32: array [32..35] of char; { +32 }
          op: pin_top_t;            { +36 }
          oc: integer);             { +38 }
      2: (
          a2_x0: array [0..27] of char; { +0 }
          source_signed: 0..65535); { +28 }
  end;

  { var_name }
  pin_var_name_ptr_t = ^pin_var_name_t;
  pin_var_name_t = record
    case integer of
      1: (
          b0: char;                 { +0 }
          b1: char;                 { +1 }
          kind: il_$kind_t;         { +2 }
          x4: array [4..27] of char; { +4 }
          typ: univ_ptr;            { +28 }
          vattributes: isc_attr_set_t; { +32 }
          size: integer32;          { +36 }
          attributes: isc_attr_set_t; { +40 }
          alignment: integer;       { +44 }
          x46: array [46..55] of char; { +46 }
          address: integer32;       { +56 }
          x60: array [60..71] of char; { +60 }
          vat: pin_vat_t);          { +72 }
      2: (
          a2_x0: array [0..55] of char; { +0 }
          disp: integer32);         { +56 }
      3: (
          a3_x0: array [0..55] of char; { +0 }
          processor_register_address: integer32); { +56 }
  end;
  { iscg: end }

  { iscg: begin dump_solution view }
  { A solution as dump_solution prints it: the generator's attribute
    declarations (docs/iscg-design.md 2.4).  The names are
    isc_solution_fields.ins.pas's isc_solution_t's (docs/questions.md
    267) and, since questions 312 and 313, its types for kind, il_kind,
    base_register, index_register and false_label and the rules' byte
    locals (case_value, the already_ flags).  This view differs only in
    the words it prints unsigned (bytes .. n_bytes_to_back_up,
    evaluation_order, which_transform: 0..65535 where isc_solution_t has
    integer), +86 as one word,
    before_transform and children as its own pointers and the rules'
    pointer locals as univ_ptr; so it stays (docs/questions.md 313). }
  ds_solution_ptr_t = ^ds_solution_t;
  ds_solution_t = record
    object_with_name: univ_ptr;     { +0 }
    base_register: isc_solution_ptr_t;  { +4 }
    index_register: isc_solution_ptr_t; { +8 }
    l12: integer32;                 { +12 }
    false_label: univ_ptr;          { +16 }
    live_range: lr_ptr_t;           { +20 }
    live_range_of_imaginary_part: lr_ptr_t;     { +24 }
    advancing_displacement: integer32;          { +28 }
    bits_known: integer32;          { +32 }
    bits_trusted: integer32;        { +36 }
    bits_known_of_fetched_value: integer32;     { +40 }
    bits_trusted_of_fetched_value: integer32;   { +44 }
    literal_32_bits_value: integer32;           { +48 }
    pass_1_size: integer32;         { +52 }
    bytes: 0..65535;                { +56 }
    fp_reg_max: 0..65535;           { +58 }
    fp_reg_result: 0..65535;        { +60 }
    fp_reg_pair_max: 0..65535;      { +62 }
    fp_reg_pair_result: 0..65535;   { +64 }
    fp_reg_quad_max: 0..65535;      { +66 }
    fp_reg_quad_result: 0..65535;   { +68 }
    ip_reg_max: 0..65535;           { +70 }
    ip_reg_result: 0..65535;        { +72 }
    n_bytes_to_back_up: 0..65535;   { +74 }
    f76: packed record              { +76 }
      bit_position_of_lsb: 0..255;  { +76 }
      field_precision: 0..255;      { +77 }
      physical_register_number: 0..255;         { +78 }
      scale: 0..255;                { +79 }
      slevel_attribute: 0..255;     { +80 }
      all_zeroes_or_all_ones: boolean;          { +81 .7 }
      arg_block_location: boolean;  { .6 }
      bit_7_was_sign_extended: boolean;         { .5 }
      bit_15_was_sign_extended: boolean;        { .4 }
      dead_end: boolean;            { .3 }
      derived_from_literal: boolean;            { .2 }
      embedded_strength_reduction_temporary: boolean;   { .1 }
      field_requires_sign_extend: boolean;      { .0 }
      has_a_symbolic_displacement: boolean;     { +82 .7 }
      is_atomic: boolean;           { .6 }
      is_complex: boolean;          { .5 }
      is_destroyable: boolean;      { .4 }
      is_dynm_vat: boolean;         { .3 }
      is_entire_object: boolean;    { .2 }
      is_physical: boolean;         { .1 }
      is_set_temporary: boolean;    { .0 }
      is_volatile: boolean;         { +83 .7 }
      literal_64_bits_value_is_zero: boolean;   { .6 }
      literal_derived_from_floating_constant: boolean;  { .5 }
      materialize_true_as_1: boolean;           { .4 }
      physical_register: boolean;   { .3 }
      physical_register_from_function_call: boolean;    { .2 }
      physical_register_is_no_modify: boolean;  { .1 }
      physical_register_user_declared: boolean; { .0 }
      uses_the_base_register: boolean;          { +84 .7 }
      uses_the_displacement: boolean;           { .6 }
      uses_the_index_register: boolean;         { .5 }
      b84_4_0: 0..31;
      b85: 0..255;                  { +85 }
      end;
    x86: integer;                   { +86: isc_solution_t's f76.b86, b87 }
    before_transform: ds_solution_ptr_t;        { +88 }
    code_bytes: 0..65535;           { +92 }
    delay: 0..65535;                { +94 }
    evaluation_order: 0..65535;     { +96 }
    il_kind: il$t;                  { +98 }
    il: univ_ptr;                   { +100 }
    inherited_attributes: inherited_attributes_ptr_t;   { +104 }
    kind: solution$t;               { +108 }
    memory_references: 0..65535;    { +110 }
    which_transform: 0..65535;      { +112 }
    f114: packed record             { +114 }
      number_of_children: 0..255;   { +114 }
      already_preserved: boolean;   { +115 .7 }
      builtin_could_deadlock_sched: boolean;    { .6 }
      builtin_is_local_cse: boolean;            { .5 }
      builtin_local_cse_has_been_preserved: boolean;    { .4 }
      already_through_pass_2: boolean;          { .3 }
      b2, b1, b0: boolean;
      end;
    children: array [1..5] of ds_solution_ptr_t;        { +116 }
    case_value: isc_case_index_array_t;         { +136: the rules' own
                                          byte locals (docs/iscg-design.md
                                          2.6) }
    already_address_mode: boolean;  { +342 }
    already_fp_reg: boolean;        { +343 }
    already_fp_reg_pair: boolean;   { +344 }
    already_fp_reg_quad: boolean;   { +345 }
    already_ip_reg: boolean;        { +346 }
    already_ip_reg_field: boolean;  { +347 }
    already_processor_reg: boolean; { +348 }
    x349: array [349..351] of char; { +349 }
    fields: array [0..19] of univ_ptr;          { +352: the rules'
                                          pointer locals }
  end;
  { iscg: end }

procedure indent(
    depth: integer); options(val_param); internal; forward;

{ isc_print_il_node - node written on the standard output, indented by
  depth: its kind and address, its static attributes (by its kind; a
  tree, comparison or assignment by its operator too), then the
  inherited attributes inh; `NIL' for nil.  bug_check for a kind with
  no arm (with inh's source line), the inherited attributes written
  after it.

  0x0BD1DC, 0x168C0 bytes: node 8, inh 12, depth a longword at 16
  (read as its low word at 18: `move.w (18,A6),-(SP)' for indent;
  pass_1 pushes `clr.l'), frame -8 (the write temporaries); no
  registers saved.  `case' by `sub.w #77; cmp.w #153; bcs' and a
  word jump table of 153 entries, each a `jmp (-n,A5)' (pattern 164):
  77 .. 229, the 89 kinds without an arm to the otherwise arm
  (0x0D3366, bug_check), the 10 empty arms to the case's end
  (0x0D337A, the inherited attributes).  Every arm ends `jmp
  (-380,A5)' or `bra 0x0D3358' (writeln, then `bra' to the inherited
  attributes); the nil arm `jmp (-12,A5)' to the last write's
  `jsr pas_$write; writeln; return' (0x0D3A80).  The operators: the
  assignment's (+76) by a jump table of 37 (38 and above to the end),
  the tree's (+36) by one of 88, the comparison's (+36) by a chain of
  `cmp.w #k; beq' in the arms' order (24, 84, 11, 12, 40, 23);
  operators without an arm write nothing more.  The source line in an
  assignment's `static source_line_number' is the inherited one
  (inh +32).

  Not known from the original: whether the arms were written in one
  `case' (as here) or the kinds without an arm were listed; whether
  depth is one longword or two words of which the first is unused
  (pass_1's `clr.l' would push both). }

procedure isc_print_il_node;
begin
  if node = nil then begin
    indent(depth);
    writeln('NIL');
  end
  else begin
    indent(depth);
    write('Node ', pin_node_ptr_t(node)^.kind:1, ': address = ', integer32(node):1);
    writeln('.');
    case pin_node_ptr_t(node)^.kind of
      { iscg: begin static attributes by IL node kind }
      addr_con:
        begin
        indent(depth);
        write('static key: ', pin_ac_t(ord(pin_addr_con_ptr_t(node)^.f20.key)):1);
        writeln('.');
        indent(depth);
        write('static pdisp: ', pin_addr_con_ptr_t(node)^.pdisp:1);
        writeln('.');
        indent(depth);
        write('static disp: ', pin_addr_con_ptr_t(node)^.disp:1);
        writeln('.');
        indent(depth);
        write('static ref: ', il_node_to_string(pin_addr_con_ptr_t(node)^.ref));
        writeln('.');
        end;
      argument_block_location_ob:
        begin
        indent(depth);
        write('static offset: ', pin_argument_block_location_ob_ptr_t(node)^.offset:1);
        writeln('.');
        end;
      assign_node:
        begin
        indent(depth);
        writeln('Sub node ', pin_assign_node_ptr_t(node)^.op:1, ':');
        case pin_assign_node_ptr_t(node)^.op of
          add_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          agg_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_assign_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          agg_len_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          and_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          div_by_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_assign_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_assign_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_assign_node_ptr_t(node)^.f58.signed:1);
            writeln('.');
            end;
          eor_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          f_add_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          f_div_by_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          f_mul_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          f_range_check_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          f_sub_from_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          fp_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_assign_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          isc_agg_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          isc_agg_zero_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          isc_fill_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          isc_mul_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_assign_node_ptr_t(node)^.f58.signed:1);
            writeln('.');
            end;
          isc_slice_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          lshft_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_assign_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_assign_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          mul_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_assign_node_ptr_t(node)^.f58.signed:1);
            writeln('.');
            end;
          neg_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          not_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          or_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          pack_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_assign_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_assign_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          range_check_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          rshft_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_assign_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_assign_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          scalar_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_assign_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_and_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_diff_from_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_or_to_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          strcat_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          strcpy_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          strncat_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          strncpy_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_assign_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          sub_from_aop:
            begin
            indent(depth);
            write('static static_exception_frame: ', il_node_to_string(pin_assign_node_ptr_t(node)^.static_exception_frame));
            writeln('.');
            indent(depth);
            write('static next: ', il_node_to_string(pin_assign_node_ptr_t(node)^.next));
            writeln('.');
            indent(depth);
            write('static source_line_number: ', inh^.pos.source_line_number:1);
            writeln('.');
            indent(depth);
            write('static stmt_no: ', pin_assign_node_ptr_t(node)^.f42.stmt_no:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_assign_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_assign_node_ptr_t(node)^.f58.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_assign_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          end;
        end;
      binteger_ob:
        begin
        indent(depth);
        write('static value: ', pin_binteger_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      ubinteger_ob:
        begin
        indent(depth);
        write('static value: ', pin_ubinteger_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      bit_field_assign:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_bit_field_assign_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_bit_field_assign_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_bit_field_assign_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        end;
      blk_end_node:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_blk_end_node_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_blk_end_node_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static bp: ', il_node_to_string(pin_blk_end_node_ptr_t(node)^.bp));
        writeln('.');
        indent(depth);
        write('static block_kind: ', pin_blk_end_node_ptr_t(node)^.bp^.kind:1);
        writeln('.');
        indent(depth);
        write('static returns_dynamic_results: ', pin_blk_end_node_ptr_t(node)^.bp^.f378.returns_dynamic_results:1);
        writeln('.');
        end;
      block_entry_node:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_block_entry_node_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_block_entry_node_ptr_t(node)^.next));
        writeln('.');
        end;
      blogical_ob:
        begin
        indent(depth);
        write('static value: ', pin_blogical_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      branch_node:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_branch_node_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_branch_node_ptr_t(node)^.next));
        writeln('.');
        end;
      case_node_range_check:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_case_node_range_check_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_case_node_range_check_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_case_node_range_check_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        end;
      case_node_no_range_check:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_case_node_no_range_check_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_case_node_no_range_check_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_case_node_no_range_check_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        end;
      cbranch_node:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_cbranch_node_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_cbranch_node_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_cbranch_node_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        indent(depth);
        write('static sense: ', pin_cbranch_node_ptr_t(node)^.sense:1);
        writeln('.');
        end;
      cc_call:
        begin
        indent(depth);
        write('static blkp: ', il_node_to_string(pin_cc_call_ptr_t(node)^.blkp));
        writeln('.');
        indent(depth);
        write('static psect: ', il_node_to_string(pin_cc_call_ptr_t(node)^.blkp^.psect));
        writeln('.');
        indent(depth);
        write('static slevel: ', pin_cc_call_ptr_t(node)^.blkp^.f294.slevel:1);
        writeln('.');
        end;
      char_ob:
        begin
        indent(depth);
        write('static value: ', pin_char_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      char_string_ob:
        begin
        indent(depth);
        write('static len: ', pin_char_string_ob_ptr_t(node)^.len:1);
        writeln('.');
        end;
      cmp_tree_node:
        begin
        indent(depth);
        writeln('Sub node ', pin_cmp_tree_node_ptr_t(node)^.op:1, ':');
        case pin_cmp_tree_node_ptr_t(node)^.op of
          agg_compare_top:
            begin
            indent(depth);
            write('static op: ', pin_cmp_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_cmp_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_cmp_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_cmp_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          bit_field_cmp_top:
            begin
            indent(depth);
            write('static op: ', pin_cmp_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_cmp_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            end;
          bit_test_top:
            begin
            indent(depth);
            write('static op: ', pin_cmp_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_cmp_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_cmp_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static range_chk: ', pin_cmp_tree_node_ptr_t(node)^.f30.range_chk:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_cmp_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_cmp_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          compare_top:
            begin
            indent(depth);
            write('static op: ', pin_cmp_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_cmp_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_cmp_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_cmp_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          f_compare_top:
            begin
            indent(depth);
            write('static op: ', pin_cmp_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_cmp_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_cmp_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_cmp_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          set_compare_top:
            begin
            indent(depth);
            write('static op: ', pin_cmp_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_cmp_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_cmp_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          end;
        end;
      complex_ob:
        begin
        indent(depth);
        write('static real: ', pin_complex_ob_ptr_t(node)^.real:1);
        writeln('.');
        indent(depth);
        write('static imag: ', pin_complex_ob_ptr_t(node)^.imag:1);
        writeln('.');
        end;
      cs_node:
        begin
        indent(depth);
        write('static len_rlen: ', pin_cs_node_ptr_t(node)^.len_rlen:1);
        writeln('.');
        indent(depth);
        write('static maxlen: ', pin_cs_node_ptr_t(node)^.maxlen:1);
        writeln('.');
        end;
      cs_temp:
        begin
        indent(depth);
        write('static vat: ', pin_cs_temp_ptr_t(node)^.vat:1);
        writeln('.');
        indent(depth);
        write('static disp: ', pin_cs_temp_ptr_t(node)^.disp:1);
        writeln('.');
        indent(depth);
        write('static size: ', pin_cs_temp_ptr_t(node)^.size:1);
        writeln('.');
        end;
      cse_parent_ob:
        begin
        indent(depth);
        write('static cse_parent: ', il_node_to_string(pin_cse_parent_ob_ptr_t(node)^.cse_parent));
        writeln('.');
        end;
      cse_use_ob:
        begin
        indent(depth);
        write('static phase_state: ', phase_set_to_string(pin_cse_use_ob_ptr_t(node)^.phase_state));
        writeln('.');
        indent(depth);
        write('static cse_parent: ', il_node_to_string(pin_cse_use_ob_ptr_t(node)^.cse_parent));
        writeln('.');
        end;
      dindex_node:
        begin
        indent(depth);
        write('static phase_state: ', phase_set_to_string(pin_dindex_node_ptr_t(node)^.phase_state));
        writeln('.');
        indent(depth);
        write('static addr_bits: ', pin_dindex_node_ptr_t(node)^.f22.addr_bits:1);
        writeln('.');
        indent(depth);
        write('static alignment: ', pin_dindex_node_ptr_t(node)^.f22.alignment:1);
        writeln('.');
        indent(depth);
        write('static disp: ', pin_dindex_node_ptr_t(node)^.disp:1);
        writeln('.');
        indent(depth);
        write('static rlen: ', pin_dindex_node_ptr_t(node)^.rlen:1);
        writeln('.');
        indent(depth);
        write('static scaled_index: ', pin_dindex_node_ptr_t(node)^.scaled_index:1);
        writeln('.');
        end;
      disp_node:
        begin
        indent(depth);
        write('static phase_state: ', phase_set_to_string(pin_disp_node_ptr_t(node)^.phase_state));
        writeln('.');
        indent(depth);
        write('static addr_bits: ', pin_disp_node_ptr_t(node)^.f22.addr_bits:1);
        writeln('.');
        indent(depth);
        write('static disp: ', pin_disp_node_ptr_t(node)^.disp:1);
        writeln('.');
        end;
      dpcomplex_ob:
        begin
        indent(depth);
        write('static real1: ', pin_dpcomplex_ob_ptr_t(node)^.real1:1);
        writeln('.');
        indent(depth);
        write('static real2: ', pin_dpcomplex_ob_ptr_t(node)^.real2:1);
        writeln('.');
        indent(depth);
        write('static imag1: ', pin_dpcomplex_ob_ptr_t(node)^.imag1:1);
        writeln('.');
        indent(depth);
        write('static imag2: ', pin_dpcomplex_ob_ptr_t(node)^.imag2:1);
        writeln('.');
        end;
      dpreal_ob:
        begin
        indent(depth);
        write('static high_32_bits: ', pin_dpreal_ob_ptr_t(node)^.high_32_bits:1);
        writeln('.');
        indent(depth);
        write('static low_32_bits: ', pin_dpreal_ob_ptr_t(node)^.low_32_bits:1);
        writeln('.');
        indent(depth);
        write('static value: ', pin_dpreal_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      entry_blk:
        begin
        indent(depth);
        write('static bat: ', pin_bat_t(ord(pin_entry_blk_ptr_t(node)^.f376.bat)):1);
        writeln('.');
        indent(depth);
        write('static dsect: ', il_node_to_string(pin_entry_blk_ptr_t(node)^.dsect));
        writeln('.');
        indent(depth);
        write('static ecb_offset: ', pin_entry_blk_ptr_t(node)^.ecb_offset:1);
        writeln('.');
        indent(depth);
        write('static psect: ', il_node_to_string(pin_entry_blk_ptr_t(node)^.psect));
        writeln('.');
        indent(depth);
        write('static slevel: ', pin_entry_blk_ptr_t(node)^.f294.slevel:1);
        writeln('.');
        end;
      eval_node:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_eval_node_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_eval_node_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_eval_node_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        indent(depth);
        write('static oc: ', pin_eval_node_ptr_t(node)^.oc:1);
        writeln('.');
        end;
      exception_handler_entry:
        begin
        indent(depth);
        write('static exception_frame: ', inh^.exception_frame);
        writeln('.');
        end;
      fortran_symbol:
        begin
        indent(depth);
        write('static address: ', pin_fortran_symbol_ptr_t(node)^.address:1);
        writeln('.');
        indent(depth);
        write('static blk_ptr: ', il_node_to_empty_string(pin_fortran_symbol_ptr_t(node)^.blk_ptr));
        writeln('.');
        indent(depth);
        write('static by_value: ', pin_fortran_symbol_ptr_t(node)^.f44.by_value:1);
        writeln('.');
        indent(depth);
        write('static dataclass: ', pin_fdtype_t(ord(pin_fortran_symbol_ptr_t(node)^.f10.dataclass)):1);
        writeln('.');
        indent(depth);
        write('static disp: ', pin_fortran_symbol_ptr_t(node)^.disp:1);
        writeln('.');
        indent(depth);
        write('static entity: ', pin_fsym_kind_t(ord(pin_fortran_symbol_ptr_t(node)^.f44.entity)):1);
        writeln('.');
        indent(depth);
        write('static equiv_link: ', il_node_to_empty_string(pin_fortran_symbol_ptr_t(node)^.equiv_link));
        writeln('.');
        indent(depth);
        write('static lbl_root: ', il_node_to_empty_string(pin_fortran_symbol_ptr_t(node)^.lbl_root));
        writeln('.');
        indent(depth);
        write('static vat: ', pin_vat_t(ord(pin_fortran_symbol_ptr_t(node)^.f10.vat)):1);
        writeln('.');
        indent(depth);
        write('static vattributes: ', vatt_set_to_string(pin_fortran_symbol_ptr_t(node)^.vattributes));
        writeln('.');
        end;
      function_blk:
        begin
        indent(depth);
        write('static bat: ', pin_bat_t(ord(pin_function_blk_ptr_t(node)^.f376.bat)):1);
        writeln('.');
        indent(depth);
        write('static dsect: ', il_node_to_string(pin_function_blk_ptr_t(node)^.dsect));
        writeln('.');
        indent(depth);
        write('static ecb_offset: ', pin_function_blk_ptr_t(node)^.ecb_offset:1);
        writeln('.');
        indent(depth);
        write('static psect: ', il_node_to_string(pin_function_blk_ptr_t(node)^.psect));
        writeln('.');
        indent(depth);
        write('static slevel: ', pin_function_blk_ptr_t(node)^.f294.slevel:1);
        writeln('.');
        end;
      insert_bit_field:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_insert_bit_field_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_insert_bit_field_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_insert_bit_field_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        indent(depth);
        write('static rlen: ', pin_insert_bit_field_ptr_t(node)^.rlen:1);
        writeln('.');
        indent(depth);
        write('static bit_size: ', pin_insert_bit_field_ptr_t(node)^.bit_size:1);
        writeln('.');
        end;
      integer_ob:
        begin
        indent(depth);
        write('static value: ', pin_integer_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      uinteger_ob:
        begin
        indent(depth);
        write('static value: ', pin_uinteger_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      label_node:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_label_node_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_label_node_ptr_t(node)^.next));
        writeln('.');
        end;
      linteger_ob:
        begin
        indent(depth);
        write('static value: ', pin_linteger_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      ulinteger_ob:
        begin
        indent(depth);
        write('static value: ', pin_ulinteger_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      llogical_ob:
        begin
        indent(depth);
        write('static value: ', pin_llogical_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      namelist_constant_ob:
        begin
        indent(depth);
        write('static len: ', pin_namelist_constant_ob_ptr_t(node)^.len:1);
        writeln('.');
        end;
      nlbranch_node:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_nlbranch_node_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_nlbranch_node_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_nlbranch_node_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        end;
      physical_register_ob:
        begin
        indent(depth);
        write('static loc: ', pin_physical_register_ob_ptr_t(node)^.loc:1);
        writeln('.');
        indent(depth);
        write('static reg: ', pin_physical_register_ob_ptr_t(node)^.reg:1);
        writeln('.');
        end;
      procedure_blk:
        begin
        indent(depth);
        write('static bat: ', pin_bat_t(ord(pin_procedure_blk_ptr_t(node)^.f376.bat)):1);
        writeln('.');
        indent(depth);
        write('static dsect: ', il_node_to_string(pin_procedure_blk_ptr_t(node)^.dsect));
        writeln('.');
        indent(depth);
        write('static ecb_offset: ', pin_procedure_blk_ptr_t(node)^.ecb_offset:1);
        writeln('.');
        indent(depth);
        write('static psect: ', il_node_to_string(pin_procedure_blk_ptr_t(node)^.psect));
        writeln('.');
        indent(depth);
        write('static slevel: ', pin_procedure_blk_ptr_t(node)^.f294.slevel:1);
        writeln('.');
        end;
      ptr_node:
        begin
        indent(depth);
        write('static phase_state: ', phase_set_to_string(pin_ptr_node_ptr_t(node)^.phase_state));
        writeln('.');
        indent(depth);
        write('static addr_bits: ', pin_ptr_node_ptr_t(node)^.f22.addr_bits:1);
        writeln('.');
        indent(depth);
        write('static alignment: ', pin_ptr_node_ptr_t(node)^.f22.alignment:1);
        writeln('.');
        end;
      raise_exception:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_raise_exception_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_raise_exception_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_raise_exception_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        end;
      real_ob:
        begin
        indent(depth);
        write('static high_32_bits: ', pin_real_ob_ptr_t(node)^.high_32_bits:1);
        writeln('.');
        indent(depth);
        write('static low_32_bits: ', pin_real_ob_ptr_t(node)^.low_32_bits:1);
        writeln('.');
        indent(depth);
        write('static value: ', pin_real_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      release_dynamic_space:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_release_dynamic_space_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_release_dynamic_space_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_release_dynamic_space_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        end;
      return_node:
        begin
        indent(depth);
        write('static static_exception_frame: ', il_node_to_string(pin_return_node_ptr_t(node)^.static_exception_frame));
        writeln('.');
        indent(depth);
        write('static next: ', il_node_to_string(pin_return_node_ptr_t(node)^.next));
        writeln('.');
        indent(depth);
        write('static source_line_number: ', inh^.pos.source_line_number:1);
        writeln('.');
        indent(depth);
        write('static stmt_no: ', pin_return_node_ptr_t(node)^.f42.stmt_no:1);
        writeln('.');
        indent(depth);
        write('static opr: ', il_node_to_string(pin_return_node_ptr_t(node)^.opr));
        writeln('.');
        indent(depth);
        write('static rlen: ', pin_return_node_ptr_t(node)^.rlen:1);
        writeln('.');
        end;
      set_con_ob:
        begin
        indent(depth);
        write('static len: ', pin_set_con_ob_ptr_t(node)^.len:1);
        writeln('.');
        end;
      slogical_ob:
        begin
        indent(depth);
        write('static value: ', pin_slogical_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      sinteger_ob:
        begin
        indent(depth);
        write('static value: ', pin_sinteger_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      usinteger_ob:
        begin
        indent(depth);
        write('static value: ', pin_usinteger_ob_ptr_t(node)^.value:1);
        writeln('.');
        end;
      sym_disp_node:
        begin
        indent(depth);
        write('static phase_state: ', phase_set_to_string(pin_sym_disp_node_ptr_t(node)^.phase_state));
        writeln('.');
        indent(depth);
        write('static addr_bits: ', pin_sym_disp_node_ptr_t(node)^.f22.addr_bits:1);
        writeln('.');
        indent(depth);
        write('static sym: ', il_node_to_string(pin_sym_disp_node_ptr_t(node)^.sym));
        writeln('.');
        end;
      tree_node:
        begin
        indent(depth);
        writeln('Sub node ', pin_tree_node_ptr_t(node)^.op:1, ':');
        case pin_tree_node_ptr_t(node)^.op of
          abs_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          ada_expon_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          add_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          addr_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          agg_compare_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          align_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          allocate_dynamic_space_top:
            begin
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            end;
          alshf_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          and_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          arshf_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          bit_field_cmp_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            end;
          bit_set_top:
            begin
            indent(depth);
            write('static oc: ', pin_tree_node_ptr_t(node)^.oc:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          bit_test_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static range_chk: ', pin_tree_node_ptr_t(node)^.f30.range_chk:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          cache_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          call_top:
            begin
            indent(depth);
            write('static oc: ', pin_tree_node_ptr_t(node)^.oc:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          chk_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          compare_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          div_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          eor_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          expon_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          extend_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            indent(depth);
            write('static source_signed: ', pin_tree_node_ptr_t(node)^.source_signed:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          extract_bit_field_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          f_ada_expon_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          f_add_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          f_compare_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          f_div_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          f_expon_top:
            begin
            indent(depth);
            write('static oc: ', pin_tree_node_ptr_t(node)^.oc:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          f_extend_top:
            begin
            indent(depth);
            write('static oc: ', pin_tree_node_ptr_t(node)^.oc:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          f_math_top:
            begin
            indent(depth);
            write('static oc: ', pin_tree_node_ptr_t(node)^.oc:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          f_mul_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          f_neg_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          f_range_check_top:
            begin
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          f_sub_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          func_call_top:
            begin
            indent(depth);
            write('static phase_loc: ', arg_loc_t_to_string(pin_tree_node_ptr_t(node)^.f10.phase_loc));
            writeln('.');
            indent(depth);
            write('static phase_reg: ', pin_tree_node_ptr_t(node)^.f10.phase_reg:1);
            writeln('.');
            indent(depth);
            write('static oc: ', pin_tree_node_ptr_t(node)^.oc:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          index_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          isc_addr_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          isc_agg_cmp_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            end;
          isc_agg_lex_cmp_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            end;
          isc_call_top:
            begin
            indent(depth);
            write('static phase_ftn_io_abnormal_flow: ', pin_tree_node_ptr_t(node)^.f12.phase_ftn_io_abnormal_flow:1);
            writeln('.');
            indent(depth);
            write('static phase_asynchronous_return: ', pin_tree_node_ptr_t(node)^.f12.phase_asynchronous_return:1);
            writeln('.');
            indent(depth);
            write('static phase_pfm_cleanup: ', pin_tree_node_ptr_t(node)^.f14.phase_pfm_cleanup:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          isc_fio_init:
            begin
            indent(depth);
            write('static oc: ', pin_tree_node_ptr_t(node)^.oc:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          isc_func_call_hidden_temp_top:
            begin
            indent(depth);
            write('static phase_ftn_io_abnormal_flow: ', pin_tree_node_ptr_t(node)^.f12.phase_ftn_io_abnormal_flow:1);
            writeln('.');
            indent(depth);
            write('static phase_asynchronous_return: ', pin_tree_node_ptr_t(node)^.f12.phase_asynchronous_return:1);
            writeln('.');
            indent(depth);
            write('static phase_pfm_cleanup: ', pin_tree_node_ptr_t(node)^.f14.phase_pfm_cleanup:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          isc_func_call_top:
            begin
            indent(depth);
            write('static phase_ftn_io_abnormal_flow: ', pin_tree_node_ptr_t(node)^.f12.phase_ftn_io_abnormal_flow:1);
            writeln('.');
            indent(depth);
            write('static phase_asynchronous_return: ', pin_tree_node_ptr_t(node)^.f12.phase_asynchronous_return:1);
            writeln('.');
            indent(depth);
            write('static phase_pfm_cleanup: ', pin_tree_node_ptr_t(node)^.f14.phase_pfm_cleanup:1);
            writeln('.');
            indent(depth);
            write('static phase_loc: ', arg_loc_t_to_string(pin_tree_node_ptr_t(node)^.f10.phase_loc));
            writeln('.');
            indent(depth);
            write('static phase_reg: ', pin_tree_node_ptr_t(node)^.f10.phase_reg:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          isc_mul_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          isc_signed_mod_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            end;
          isc_signed_rem_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            end;
          isc_unsigned_mod_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          isc_unsigned_rem_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          lshf_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          max_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          min_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          mod_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          mul_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          neg_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          nop_top:
            begin
            indent(depth);
            write('static phase_state: ', phase_set_to_string(pin_tree_node_ptr_t(node)^.phase_state));
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          not_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          or_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          range_check_top:
            begin
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          rshf_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            end;
          set_and_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_bit_in_set_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_compare_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_diff_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_extend_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_or_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          set_range_in_set_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          signed_div_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          signed_mod_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          sr_top:
            begin
            indent(depth);
            write('static oc: ', pin_tree_node_ptr_t(node)^.oc:1);
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          strcmp_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          strlen_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          strncmp_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          sub_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          unpack_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static signed: ', pin_tree_node_ptr_t(node)^.f30.signed:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          unsigned_div_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          unsigned_mod_top:
            begin
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static opmod: ', pin_tree_node_ptr_t(node)^.opmod:1);
            writeln('.');
            indent(depth);
            write('static opmod1: ', pin_tree_node_ptr_t(node)^.opmod1:1);
            writeln('.');
            indent(depth);
            write('static overflow_check: ', pin_tree_node_ptr_t(node)^.f30.overflow_check:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            end;
          value_top:
            begin
            indent(depth);
            write('static phase_state: ', phase_set_to_string(pin_tree_node_ptr_t(node)^.phase_state));
            writeln('.');
            indent(depth);
            write('static op: ', pin_tree_node_ptr_t(node)^.op:1);
            writeln('.');
            indent(depth);
            write('static rlen: ', pin_tree_node_ptr_t(node)^.rlen:1);
            writeln('.');
            indent(depth);
            write('static size: ', pin_tree_node_ptr_t(node)^.size:1);
            writeln('.');
            end;
          end;
        end;
      var_name:
        begin
        indent(depth);
        write('static address: ', pin_var_name_ptr_t(node)^.address:1);
        writeln('.');
        indent(depth);
        write('static alignment: ', pin_var_name_ptr_t(node)^.alignment:1);
        writeln('.');
        indent(depth);
        write('static attributes: ', type_attr_set_to_string(pin_var_name_ptr_t(node)^.attributes));
        writeln('.');
        indent(depth);
        write('static disp: ', pin_var_name_ptr_t(node)^.disp:1);
        writeln('.');
        indent(depth);
        write('static processor_register_address: ', pin_var_name_ptr_t(node)^.processor_register_address:1);
        writeln('.');
        indent(depth);
        write('static size: ', pin_var_name_ptr_t(node)^.size:1);
        writeln('.');
        indent(depth);
        write('static spelling: ', il_node_to_string(node));
        writeln('.');
        indent(depth);
        write('static typ: ', il_node_to_string(pin_var_name_ptr_t(node)^.typ));
        writeln('.');
        indent(depth);
        write('static vat: ', pin_var_name_ptr_t(node)^.vat:1);
        writeln('.');
        indent(depth);
        write('static vatt_rec: ', vatt_rec_to_string(node));
        writeln('.');
        indent(depth);
        write('static vattributes: ', vatt_set_to_string(pin_var_name_ptr_t(node)^.vattributes));
        writeln('.');
        end;
      { The kinds without static attributes (their table entries all go
        to the case's end, so their places among the arms are not
        known). }
      ap_register, at_lib_dsc, db_register, display_register,
      exception_register, lb_register, lib_dsc, pf_call, sb_register,
      use_def_ob:
        ;
      { iscg: end }
    otherwise
      bug_check('ISC: source line %wd: isc_print_il_node: unknown node type.%$', inh^.pos);
    end;
    { iscg: begin inherited attributes }
    { The inherited attributes under the generator's names, which are
      inherited_attributes_t's (docs/questions.md 271). }
    indent(depth);
    write('inherited call_instruction_ptr: ', instruction_to_string(inh^.call_instruction_ptr));
    writeln('.');
    indent(depth);
    write('inherited conditional_sense: ', inh^.f38.conditional_sense:1);
    writeln('.');
    indent(depth);
    write('inherited conditional_target: ', label_to_string(univ_ptr(inh^.conditional_target)));
    writeln('.');
    indent(depth);
    write('inherited exception_frame: ', integer32(inh^.exception_frame));
    writeln('.');
    indent(depth);
    write('inherited fetch_precision: ', inh^.fetch_precision:1);
    writeln('.');
    indent(depth);
    write('inherited immediate_parent_has_signed: ', inh^.f38.immediate_parent_has_signed:1);
    writeln('.');
    indent(depth);
    write('inherited immediate_parent_wants_lvalue: ', inh^.f38.immediate_parent_wants_lvalue:1);
    writeln('.');
    indent(depth);
    write('inherited immediate_parent_wants_set_temporary: ', inh^.f38.immediate_parent_wants_set_temporary:1);
    writeln('.');
    indent(depth);
    write('inherited immediate_parent_wants_signed: ', inh^.f38.immediate_parent_wants_signed:1);
    writeln('.');
    indent(depth);
    write('inherited inside_a_cse: ', inh^.f38.inside_a_cse:1);
    writeln('.');
    indent(depth);
    write('inherited original_il: ', integer32(inh^.original_il));
    writeln('.');
    indent(depth);
    write('inherited parent_il_kind: ', il$t(ord(inh^.parent_il_kind)):1);
    writeln('.');
    indent(depth);
    write('inherited required_arithmetic: ', arith$t(ord(inh^.f38.required_arithmetic)):1);
    writeln('.');
    indent(depth);
    write('inherited required_precision: ', inh^.required_precision:1);
    writeln('.');
    indent(depth);
    write('inherited source_line_number: ', inh^.pos.source_line_number:1);
    writeln('.');
    indent(depth);
    write('inherited stmt_number: ', inh^.pos.stmt_number:1);
    writeln('.');
    indent(depth);
    write('inherited il: ', integer32(inh));
    writeln('.');
    { iscg: end }
  end;
end;

{ indent - depth bars (`|  ').

  0x0D6110, 0x60 bytes: depth a word at 8; the `for' count and index
  in the frame (-4, -2). }

procedure indent;
var
  i: integer;
begin
  for i := 1 to depth do
    write('|  ');
end;

{ dump_solution - sol written on the standard output, indented by
  depth: its address, kind, il_kind and rule (which_transform), at
  debug level 7 every attribute; then its children (each by
  dump_solution one deeper) and, when deep, the solution it was made
  from (before_transform).  `NIL' for nil.

  0x0D6174, 0x23F6 bytes: sol 8, depth a word at 12, deep a byte at 14;
  D2 saved; the level `moveq #7; and.b 0x485D31; cmp.w #7; bne'
  (at_backend_switches.level); the children's `for' by the byte +114,
  its count and index in the frame (-4, -2); deep `tst.b; bpl', then
  before_transform `tst.l; beq'.  The pointers base_register,
  index_register (solutions), false_label, object_with_name and the
  live ranges are written by isc_user_routines' printers; before_
  transform, il and inherited_attributes as integers without a width. }

procedure dump_solution;
var
  i: integer;
begin
  if sol = nil then begin
    indent(depth);
    writeln('NIL');
  end
  else begin
    indent(depth);
    write('solution @ ', integer32(sol):1);
    writeln('.');
    indent(depth);
    write('kind = ', ds_solution_ptr_t(sol)^.kind:1);
    writeln('.');
    indent(depth);
    write('il_kind = ', ds_solution_ptr_t(sol)^.il_kind:1);
    writeln('.');
    indent(depth);
    write('which_transform = ', ds_solution_ptr_t(sol)^.which_transform:1);
    writeln('.');
    if at_backend_switches.level = 7 then begin
      { iscg: begin dump_solution fields }
      indent(depth);
      write('advancing_displacement = ', ds_solution_ptr_t(sol)^.advancing_displacement:1);
      writeln('.');
      indent(depth);
      write('all_zeroes_or_all_ones = ', ds_solution_ptr_t(sol)^.f76.all_zeroes_or_all_ones:1);
      writeln('.');
      indent(depth);
      write('arg_block_location = ', ds_solution_ptr_t(sol)^.f76.arg_block_location:1);
      writeln('.');
      indent(depth);
      write('bit_7_was_sign_extended = ', ds_solution_ptr_t(sol)^.f76.bit_7_was_sign_extended:1);
      writeln('.');
      indent(depth);
      write('bit_15_was_sign_extended = ', ds_solution_ptr_t(sol)^.f76.bit_15_was_sign_extended:1);
      writeln('.');
      indent(depth);
      write('bit_position_of_lsb = ', ds_solution_ptr_t(sol)^.f76.bit_position_of_lsb:1);
      writeln('.');
      indent(depth);
      write('bits_known = ', ds_solution_ptr_t(sol)^.bits_known:1);
      writeln('.');
      indent(depth);
      write('bits_trusted = ', ds_solution_ptr_t(sol)^.bits_trusted:1);
      writeln('.');
      indent(depth);
      write('bits_known_of_fetched_value = ', ds_solution_ptr_t(sol)^.bits_known_of_fetched_value:1);
      writeln('.');
      indent(depth);
      write('bits_trusted_of_fetched_value = ', ds_solution_ptr_t(sol)^.bits_trusted_of_fetched_value:1);
      writeln('.');
      indent(depth);
      write('bytes = ', ds_solution_ptr_t(sol)^.bytes:1);
      writeln('.');
      indent(depth);
      write('dead_end = ', ds_solution_ptr_t(sol)^.f76.dead_end:1);
      writeln('.');
      indent(depth);
      write('derived_from_literal = ', ds_solution_ptr_t(sol)^.f76.derived_from_literal:1);
      writeln('.');
      indent(depth);
      write('embedded_strength_reduction_temporary = ', ds_solution_ptr_t(sol)^.f76.embedded_strength_reduction_temporary:1);
      writeln('.');
      indent(depth);
      write('field_precision = ', ds_solution_ptr_t(sol)^.f76.field_precision:1);
      writeln('.');
      indent(depth);
      write('field_requires_sign_extend = ', ds_solution_ptr_t(sol)^.f76.field_requires_sign_extend:1);
      writeln('.');
      indent(depth);
      write('fp_reg_max = ', ds_solution_ptr_t(sol)^.fp_reg_max:1);
      writeln('.');
      indent(depth);
      write('fp_reg_result = ', ds_solution_ptr_t(sol)^.fp_reg_result:1);
      writeln('.');
      indent(depth);
      write('fp_reg_pair_max = ', ds_solution_ptr_t(sol)^.fp_reg_pair_max:1);
      writeln('.');
      indent(depth);
      write('fp_reg_pair_result = ', ds_solution_ptr_t(sol)^.fp_reg_pair_result:1);
      writeln('.');
      indent(depth);
      write('fp_reg_quad_max = ', ds_solution_ptr_t(sol)^.fp_reg_quad_max:1);
      writeln('.');
      indent(depth);
      write('fp_reg_quad_result = ', ds_solution_ptr_t(sol)^.fp_reg_quad_result:1);
      writeln('.');
      indent(depth);
      write('has_a_symbolic_displacement = ', ds_solution_ptr_t(sol)^.f76.has_a_symbolic_displacement:1);
      writeln('.');
      indent(depth);
      write('ip_reg_max = ', ds_solution_ptr_t(sol)^.ip_reg_max:1);
      writeln('.');
      indent(depth);
      write('ip_reg_result = ', ds_solution_ptr_t(sol)^.ip_reg_result:1);
      writeln('.');
      indent(depth);
      write('is_atomic = ', ds_solution_ptr_t(sol)^.f76.is_atomic:1);
      writeln('.');
      indent(depth);
      write('is_complex = ', ds_solution_ptr_t(sol)^.f76.is_complex:1);
      writeln('.');
      indent(depth);
      write('is_destroyable = ', ds_solution_ptr_t(sol)^.f76.is_destroyable:1);
      writeln('.');
      indent(depth);
      write('is_dynm_vat = ', ds_solution_ptr_t(sol)^.f76.is_dynm_vat:1);
      writeln('.');
      indent(depth);
      write('is_entire_object = ', ds_solution_ptr_t(sol)^.f76.is_entire_object:1);
      writeln('.');
      indent(depth);
      write('is_physical = ', ds_solution_ptr_t(sol)^.f76.is_physical:1);
      writeln('.');
      indent(depth);
      write('is_set_temporary = ', ds_solution_ptr_t(sol)^.f76.is_set_temporary:1);
      writeln('.');
      indent(depth);
      write('is_volatile = ', ds_solution_ptr_t(sol)^.f76.is_volatile:1);
      writeln('.');
      indent(depth);
      write('literal_32_bits_value = ', ds_solution_ptr_t(sol)^.literal_32_bits_value:1);
      writeln('.');
      indent(depth);
      write('literal_64_bits_value_is_zero = ', ds_solution_ptr_t(sol)^.f76.literal_64_bits_value_is_zero:1);
      writeln('.');
      indent(depth);
      write('literal_derived_from_floating_constant = ', ds_solution_ptr_t(sol)^.f76.literal_derived_from_floating_constant:1);
      writeln('.');
      indent(depth);
      write('materialize_true_as_1 = ', ds_solution_ptr_t(sol)^.f76.materialize_true_as_1:1);
      writeln('.');
      indent(depth);
      write('n_bytes_to_back_up = ', ds_solution_ptr_t(sol)^.n_bytes_to_back_up:1);
      writeln('.');
      indent(depth);
      write('pass_1_size = ', ds_solution_ptr_t(sol)^.pass_1_size:1);
      writeln('.');
      indent(depth);
      write('physical_register = ', ds_solution_ptr_t(sol)^.f76.physical_register:1);
      writeln('.');
      indent(depth);
      write('physical_register_from_function_call = ', ds_solution_ptr_t(sol)^.f76.physical_register_from_function_call:1);
      writeln('.');
      indent(depth);
      write('physical_register_number = ', ds_solution_ptr_t(sol)^.f76.physical_register_number:1);
      writeln('.');
      indent(depth);
      write('physical_register_is_no_modify = ', ds_solution_ptr_t(sol)^.f76.physical_register_is_no_modify:1);
      writeln('.');
      indent(depth);
      write('physical_register_user_declared = ', ds_solution_ptr_t(sol)^.f76.physical_register_user_declared:1);
      writeln('.');
      indent(depth);
      write('scale = ', ds_solution_ptr_t(sol)^.f76.scale:1);
      writeln('.');
      indent(depth);
      write('slevel_attribute = ', ds_solution_ptr_t(sol)^.f76.slevel_attribute:1);
      writeln('.');
      indent(depth);
      write('uses_the_base_register = ', ds_solution_ptr_t(sol)^.f76.uses_the_base_register:1);
      writeln('.');
      indent(depth);
      write('uses_the_displacement = ', ds_solution_ptr_t(sol)^.f76.uses_the_displacement:1);
      writeln('.');
      indent(depth);
      write('uses_the_index_register = ', ds_solution_ptr_t(sol)^.f76.uses_the_index_register:1);
      writeln('.');
      indent(depth);
      write('before_transform = ', integer32(ds_solution_ptr_t(sol)^.before_transform));
      writeln('.');
      indent(depth);
      write('code_bytes = ', ds_solution_ptr_t(sol)^.code_bytes:1);
      writeln('.');
      indent(depth);
      write('delay = ', ds_solution_ptr_t(sol)^.delay:1);
      writeln('.');
      indent(depth);
      write('evaluation_order = ', ds_solution_ptr_t(sol)^.evaluation_order:1);
      writeln('.');
      indent(depth);
      write('il_kind = ', ds_solution_ptr_t(sol)^.il_kind:1);
      writeln('.');
      indent(depth);
      write('il = ', integer32(ds_solution_ptr_t(sol)^.il));
      writeln('.');
      indent(depth);
      write('inherited_attributes = ', integer32(ds_solution_ptr_t(sol)^.inherited_attributes));
      writeln('.');
      indent(depth);
      write('kind = ', ds_solution_ptr_t(sol)^.kind:1);
      writeln('.');
      indent(depth);
      write('memory_references = ', ds_solution_ptr_t(sol)^.memory_references:1);
      writeln('.');
      indent(depth);
      write('which_transform = ', ds_solution_ptr_t(sol)^.which_transform:1);
      writeln('.');
      indent(depth);
      write('number_of_children = ', ds_solution_ptr_t(sol)^.f114.number_of_children:1);
      writeln('.');
      indent(depth);
      write('already_preserved = ', ds_solution_ptr_t(sol)^.f114.already_preserved:1);
      writeln('.');
      indent(depth);
      write('builtin_could_deadlock_sched = ', ds_solution_ptr_t(sol)^.f114.builtin_could_deadlock_sched:1);
      writeln('.');
      indent(depth);
      write('builtin_is_local_cse = ', ds_solution_ptr_t(sol)^.f114.builtin_is_local_cse:1);
      writeln('.');
      indent(depth);
      write('builtin_local_cse_has_been_preserved = ', ds_solution_ptr_t(sol)^.f114.builtin_local_cse_has_been_preserved:1);
      writeln('.');
      indent(depth);
      write('case_value = ', case_index_array_to_string(ds_solution_ptr_t(sol)^.case_value));
      writeln('.');
      indent(depth);
      write('already_address_mode = ', ds_solution_ptr_t(sol)^.already_address_mode:1);
      writeln('.');
      indent(depth);
      write('already_fp_reg = ', ds_solution_ptr_t(sol)^.already_fp_reg:1);
      writeln('.');
      indent(depth);
      write('already_fp_reg_pair = ', ds_solution_ptr_t(sol)^.already_fp_reg_pair:1);
      writeln('.');
      indent(depth);
      write('already_fp_reg_quad = ', ds_solution_ptr_t(sol)^.already_fp_reg_quad:1);
      writeln('.');
      indent(depth);
      write('already_ip_reg = ', ds_solution_ptr_t(sol)^.already_ip_reg:1);
      writeln('.');
      indent(depth);
      write('already_ip_reg_field = ', ds_solution_ptr_t(sol)^.already_ip_reg_field:1);
      writeln('.');
      indent(depth);
      write('already_processor_reg = ', ds_solution_ptr_t(sol)^.already_processor_reg:1);
      writeln('.');
      indent(depth);
      write('base_register = ', solution_to_string(ds_solution_ptr_t(sol)^.base_register));
      writeln('.');
      indent(depth);
      write('index_register = ', solution_to_string(ds_solution_ptr_t(sol)^.index_register));
      writeln('.');
      indent(depth);
      write('false_label = ', label_to_string(ds_solution_ptr_t(sol)^.false_label));
      writeln('.');
      indent(depth);
      write('object_with_name = ', il_node_to_string(ds_solution_ptr_t(sol)^.object_with_name));
      writeln('.');
      indent(depth);
      write('live_range = ', live_range_to_string(ds_solution_ptr_t(sol)^.live_range));
      writeln('.');
      indent(depth);
      write('live_range_of_imaginary_part = ', live_range_to_string(ds_solution_ptr_t(sol)^.live_range_of_imaginary_part));
      writeln('.');
      indent(depth);
      write('already_through_pass_2 = ', ds_solution_ptr_t(sol)^.f114.already_through_pass_2:1);
      writeln('.');
      { iscg: end }
    end;
    for i := 1 to ds_solution_ptr_t(sol)^.f114.number_of_children do begin
      indent(depth);
      writeln('children[', i:1, ']:');
      dump_solution(isc_solution_ptr_t(ds_solution_ptr_t(sol)^.children[i]), depth + 1, deep);
    end;
    if deep and (ds_solution_ptr_t(sol)^.before_transform <> nil) then begin
      indent(depth);
      writeln('before_transform:');
      dump_solution(isc_solution_ptr_t(ds_solution_ptr_t(sol)^.before_transform), depth + 1, deep);
    end;
  end;
end;

{ print_permissible_solution_kinds - the kinds of kinds written on the
  standard output: `any_solution' for every kind but none
  (16#FFFFFE), else an opening brace and a blank, each kind's name and
  a blank, and a closing brace.

  0x0D8E1A, 0x388 bytes: kinds a longword at 8 (bit k kind k, tested
  by `btst' on its low byte, word or longword); the any_solution
  write and the closing brace's share the `jsr pas_$write'
  (cross-jumping). }

procedure print_permissible_solution_kinds;
begin
  if kinds = [solution$case_jump_base..solution$void] then begin
    write('any_solution');
  end
  else begin
    write('{ ');
    { iscg: begin solution kinds }
    if solution$case_jump_base in kinds then write('case_jump_base ');
    if solution$fp_reg_pair_high in kinds then write('fp_reg_pair_high ');
    if solution$fp_reg_pair_low in kinds then write('fp_reg_pair_low ');
    if solution$local_routine in kinds then write('local_routine ');
    if solution$address_mode in kinds then write('address_mode ');
    if solution$ctl_reg in kinds then write('ctl_reg ');
    if solution$flow in kinds then write('flow ');
    if solution$fp_reg in kinds then write('fp_reg ');
    if solution$fp_reg_pair in kinds then write('fp_reg_pair ');
    if solution$fp_reg_quad in kinds then write('fp_reg_quad ');
    if solution$ip_reg in kinds then write('ip_reg ');
    if solution$ip_reg_field in kinds then write('ip_reg_field ');
    if solution$ip_reg_scaled in kinds then write('ip_reg_scaled ');
    if solution$literal_32_bits in kinds then write('literal_32_bits ');
    if solution$literal_64_bits in kinds then write('literal_64_bits ');
    if solution$processor_reg in kinds then write('processor_reg ');
    if solution$sc_reg in kinds then write('sc_reg ');
    if solution$sr_reg in kinds then write('sr_reg ');
    if solution$dummy in kinds then write('dummy ');
    if solution$any_solution in kinds then write('any_solution ');
    if solution$irrelevant in kinds then write('irrelevant ');
    if solution$proper_subtree in kinds then write('proper_subtree ');
    if solution$void in kinds then write('void ');
    { iscg: end }
    write('}');
  end;
end;
