{ isc_user_routines - the ISC's hand-written helpers: the routines the
  generated pattern actions (isc_pass_1_main, isc_pass_2_main,
  isc_pattern_matcher) call to test and compute the attributes of IL
  nodes and solutions (bits known and trusted, alignments, precisions,
  literals and their bit patterns, evaluation orders, the choice among
  candidate solutions), the solutions of symbols' homes and of
  well-known registers and literals, the solution constructors, and the
  printers the ISC's traces use.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x20DD7C  literal_base_register
    --------  0x20DDC4  is_in_range
    --------  0x20DDF4  local_create_soln_for_ip_reg
    --------  0x20DE28  local_create_soln_for_fp_reg
    --------  0x20DE5C  local_create_soln_for_fp_reg_pair
    --------  0x20DE90  local_create_soln_for_fp_reg_quad
    --------  0x20DEC4  local_initialize_symbol (internal)
    --------  0x20E6AA  local_initialize_fortran_symbol (internal)
    --------  0x20E7E4  local_initialize_var_name (internal)
    --------  0x20E892  initialize_well_known_symbol
    --------  0x20E8D2  number_of_one_bits
    --------  0x20E908  alignment_from_sr_info
    --------  0x2105D4  lir_$can_encode_as_immediate_postincrement
    --------  0x210628  alignment_from_il_node
    --------  0x210B06  available_precision_function
    --------  0x210B36  is_all_zeroes
    --------  0x210B88  fetch_precision_to_bits_trusted
    --------  0x210CF2  make_bit_mask_1
    --------  0x210EA0  make_bit_mask_2
    --------  0x211014  bits_known_function
    --------  0x211DC0  bits_to_alignment
    --------  0x211DFA  bits_trusted_function
    --------  0x212058  bits_trusted_of_fortran_symbol
    --------  0x2120CE  bits_trusted_of_var_name
    --------  0x21213C  bits_trusted_of_symbol
    --------  0x21217C  get_kind_of_home_solution
    --------  0x2121AE  il_node_has_float_value
    --------  0x2121E6  il_node_has_integer_value
    --------  0x212260  il_node_to_integer_value
    --------  0x2122D4  assert_kind_is_label_node
    --------  0x2123D0  cs_temp_to_var_name
    --------  0x212410  legal_evaluation_orders
    --------  0x212450  evaluation_order_function
    --------  0x21255A  similar_solutions
    --------  0x2126A2  clearly_dominates
    --------  0x2127E8  choose_one_solution
    --------  0x21288C  is_sequence_of_ones
    --------  0x21292A  is_sequence_of_ones_right_justified
    --------  0x2129C8  is_sequence_of_zeroes
    --------  0x212A68  length_of_sequence_of_ones
    --------  0x212AF4  length_of_sequence_of_zeroes
    --------  0x212B84  il_node_is_literal_sequence_of_ones
    --------  0x212BFA  il_node_is_literal_sequence_of_zeroes
    --------  0x212C8E  in_interval_at_compile_time
    --------  0x212D5E  is_device
    --------  0x212E02  sign_extend
    --------  0x212E44  integer32_from_char_string_ob
    --------  0x212EB8  get_uparrow_dot_kind
    --------  0x212ED4  not_permissible_function
    --------  0x212F3A  number_of_leftmost_zeroes
    --------  0x212F80  number_of_leftmost_ones
    --------  0x212FC2  number_of_rightmost_zeroes
    --------  0x213004  number_of_rightmost_ones
    --------  0x213042  well_known_literal
    --------  0x21309E  find_well_known_literal_solution
    --------  0x2130E8  initialize_symbol
    --------  0x213120  isc_$initialize_symbol
    --------  0x213158  isc_$initialize_parameter
    --------  0x213198  isc_$is_a_register_candidate
    --------  0x2133F4  is_a_register_solution
    --------  0x21342A  ip_reg_to_ip_reg_scaled
    --------  0x213462  ip_reg_scaled_to_ip_reg
    --------  0x213490  high_half_of_fp_reg_pair
    --------  0x2134DC  low_half_of_fp_reg_pair
    --------  0x213594  high_half_of_fp_reg_quad
    --------  0x2135D0  low_half_of_fp_reg_quad
    --------  0x21368E  address_mode_for_expression_temporary
    --------  0x213718  address_mode_for_single_value
    --------  0x2137CC  address_mode_for_double_value
    --------  0x213878  address_mode_for_integer32_value
    --------  0x213922  compute_number_loaded_bytes
    --------  0x2139BE  create_solution_for_address_mode
    --------  0x2139EC  create_solution_for_case_jump_base
    --------  0x213A2A  create_solution_for_ip_reg
    --------  0x213A58  create_solution_for_ip_reg_scaled
    --------  0x213A8A  create_solution_for_fp_reg
    --------  0x213AB8  create_solution_for_fp_reg_physical
    --------  0x213B62  create_solution_for_fp_reg_pair
    --------  0x213B90  create_solution_for_fp_reg_pair_physical
    --------  0x213C3A  create_solution_for_fp_reg_quad
    --------  0x213C68  create_solution_for_literal_32_bits
    --------  0x213CA4  duplicate_address_mode
    --------  0x213CDE  duplicate_address_mode_adding_byte_offset
    --------  0x213D22  isc_$get_home_solution
    --------  0x213DE8  isc_$get_memory_home
    --------  0x213EB6  isc_$get_il_live_range
    --------  0x2140D0  get_live_range_assigned
    --------  0x2140F6  get_live_range_no_modify
    --------  0x21411E  get_live_range_register
    --------  0x214144  get_live_range_serialize
    --------  0x21416C  get_live_range_of_imaginary_part
    --------  0x214296  isc_$init_well_known_ip_reg
    --------  0x21435A  isc_$init_well_known_fp_reg
    --------  0x214414  isc_$init_well_known_fp_reg_pair
    --------  0x2144CE  il_kind_function
    --------  0x2144EA  make_expression_temporary
    --------  0x214598  possibly_make_expression_temporary
    --------  0x2145EE  verify_bits
    --------  0x214916  verify_any_bits
    --------  0x214BF6  isc_$precision_from_rlen_and_size
    --------  0x214C3E  return_value_needs_assign_node
    --------  0x214CCC  rlen_code_from_type_node
    --------  0x214F7E  arithmetic_from_il_node
    --------  0x21529C  precision_from_il_node
    --------  0x2155C2  isc_$get_label
    --------  0x215660  pattern_match_error
    --------  0x2166F8  pc_relative_literal_size_to_bits_trusted
    --------  0x216736  set_isc_is_cse_on_live_range_if_local_cse
    --------  0x21675A  side_effect_set_var_$address_exposed
    --------  0x216778  side_effect_fortran_symbol_fill_in_size
    --------  0x216844  side_effect_var_name_fill_in_size
    --------  0x21686A  side_effect_symbol_fill_in_size
    --------  0x2168A8  is_power_of_2
    --------  0x2168D8  invertible_in_sp
    --------  0x216906  invertible_in_dp
    --------  0x216934  log_2
    --------  0x21696E  warning_unaligned_atomic_access
    --------  0x216A1E  widen_char_string_ob
    --------  0x216A80  expression_has_side_effects
    --------  0x216B04  process_eval_node
    --------  0x216D34  value_top_over
    --------  0x216D8E  validate_shift_count
    --------  0x216E8A  solution_kind_of_symbol
    --------  0x216EC8  arg_loc_t_to_string
    --------  0x216FC8  basic_block_to_string
    --------  0x217004  block_rec_to_string
    --------  0x2170BE  case_index_array_to_string
    --------  0x2170D4  il_node_to_empty_string
    --------  0x21805C  il_node_to_string
    --------  0x219924  instruction_to_string
    --------  0x21998C  label_to_string
    --------  0x219A02  live_range_to_string
    --------  0x219AB6  phase_set_to_string
    --------  0x219E3A  relational_to_string
    --------  0x219FA6  solution_to_string
    --------  0x21AC0C  type_attr_set_to_string
    --------  0x21AF9E  vatt_rec_to_string
    --------  0x21B17A  vatt_set_to_string
  A5 0x480E00: the module's data, 0x35C bytes, every cell declared
  extern (isc_var_externs.ins.pas's and the unit's own below) and
  defined here in address order (as lir_main does): +0x0 the powers of
  two, +0x80 the type descriptor of a FORTRAN symbol, +0x9C .. +0x35A
  isc_main's, isc_to_lir's, lir's and this unit's cells.  The byte
  cells (+0x354, +0x356, +0x358) each have a spare byte after them in
  the image, so dpc's two bytes a byte cell (docs/dpc-gaps.md 37) keep
  every cell at its address.

  The traces (isc_user_routines_354 or _356 set) write with Pascal
  `write': dpc gap 4 (docs/dpc-gaps.md 4).  An enumerated value is
  written with its type's name table (PAS_$WRITE code 3941, width 1):
  the IL node kinds (an_kind_t, as add_node declares them), the tree
  and assignment operators (ur_top_t, ur_aop_t) and il$t.

  Not known from the original: the parameters' and locals' names (the
  traces give some), the types' names declared here. }
module isc_user_routines;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
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
  { The IL node kinds, as the image names them (the name table after
    alignment_from_sr_info, 0x20F27A: add_node.pas's an_kind_t). }
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

  { The tree operators (a tree node's +36; the name table at
    0x20FD9A, 90 names). }
  ur_top_t = (
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

  { The assignment operators (an assignment's +76; the name table at
    0x210354, 38 names). }
  ur_aop_t = (
    scalar_aop, add_to_aop, sub_from_aop, and_to_aop, or_to_aop,
    eor_to_aop, agg_aop, set_and_to_aop, set_or_to_aop,
    set_diff_from_aop, pack_aop, fp_aop, field_aop, not_to_aop,
    neg_to_aop, lshft_to_aop, rshft_to_aop, bset_to_aop, bclr_to_aop,
    f_add_to_aop, f_sub_from_aop, f_mul_to_aop, f_div_by_aop,
    mul_to_aop, div_by_aop, agg_len_aop, isc_mul_to_aop, strcat_aop,
    strcpy_aop, strncat_aop, strncpy_aop, isc_agg_aop, isc_slice_aop,
    isc_agg_zero_aop, isc_fill_aop, range_check_to_aop,
    f_range_check_to_aop, illegal_aop);

  { A FORTRAN symbol's data class (the name table il_node_to_string
    writes it with, 0x21959A). }
  ur_fdtype_t = (
    none, xbinteger, xsinteger, xlinteger, xreal, xdoubleprecision,
    xcomplex, xcharacter, xblogical, xslogical, xllogical, xaddress,
    nomore, xdpcomplex);

  { A type as the front end's type_exp describes it (c_objtype's
    type_exp_t, 26 bytes; this unit does not open c_objtype.ins.pas):
    base (+0) the type node with names expanded. }
  ur_type_exp_ptr_t = ^ur_type_exp_t;
  ur_type_exp_t = record
    base: isc_node_ptr_t;               { +0 }
    node: univ_ptr;                     { +4 }
    low: integer32;                     { +8 }
    high: integer32;                    { +12 }
    size: integer32;                    { +16 }
    bytes: integer32;                   { +20 }
    flags: integer;                     { +24 }
  end;

  ur_solution_ptr_ptr_t = ^isc_solution_ptr_t;

  { An instruction as isc_$get_label reaches it (backend.ins.pas's
    instr_t: +3 bit 7, next, prev, block, and the halfword +32, the
    high half of its l32). }
  ur_instr_view_ptr_t = ^ur_instr_view_t;
  ur_instr_view_t = record
    b0: char;                           { +0 }
    b1: char;                           { +1 }
    b2: char;                           { +2 }
    f3: packed record                   { +3 }
      b7: boolean;
      b6_0: 0..127;
      end;
    next: ur_instr_view_ptr_t;          { +4 }
    prev: ur_instr_view_ptr_t;          { +8 }
    bb: bb_ptr_t;                       { +12 }
    x16: array [4..7] of integer32;     { +16 }
    w32: integer;                       { +32 }
  end;

  { A LIR label (lir.pvt.pas's lir_label_t, which this unit does not
    open): instr (+4) its label instruction, +10 bit 5 placed in a
    block, bb (+12) that block. }
  ur_label_ptr_t = ^ur_label_t;
  ur_label_t = record
    l0: integer32;                      { +0 }
    instr: ur_instr_view_ptr_t;         { +4 }
    w8: integer;                        { +8 }
    f10: packed record                  { +10 }
      b7, b6: boolean;
      in_block: boolean;                { .5 }
      b4_0: 0..31;
      end;
    b11: char;                          { +11 }
    bb: bb_ptr_t;                       { +12 }
  end;

var
  { lir.pas's tables of the floating registers' solutions (lir.pvt.pas,
    which this unit does not open, declares them as lir_sol_tab_t). }
  lir_3c60: extern array [0..63] of solution_ptr_t;
  lir_3d60: extern array [0..63] of solution_ptr_t;

  { The module's own cells (see the header; isc_var_externs.ins.pas
    declares the others). }
  ur_powers: extern array [0..31] of integer32;     { +0x000: 2 ** k }
  ur_fortran_type: extern ur_type_exp_t;   { +0x080: the type
                                          local_initialize_fortran_symbol
                                          describes a FORTRAN symbol by
                                          (base: one of the well-known
                                          type nodes +0x344, +0x348,
                                          +0x34C; low -32768, high 32767) }
  ur_unused_9a: extern integer;         { +0x09A }

  ur_unused_314: extern array [0..1] of integer32;  { +0x314 }
  ur_unused_35a: extern integer;        { +0x35A }

define
  ur_powers := [16#1, 16#2, 16#4, 16#8, 16#10, 16#20, 16#40, 16#80,
                16#100, 16#200, 16#400, 16#800, 16#1000, 16#2000, 16#4000,
                16#8000, 16#10000, 16#20000, 16#40000, 16#80000, 16#100000,
                16#200000, 16#400000, 16#800000, 16#1000000, 16#2000000,
                16#4000000, 16#8000000, 16#10000000, 16#20000000,
                16#40000000, 16#80000000];
  ur_fortran_type := [nil, nil, -32768, 32767, 0, 0, 0];
  ur_unused_9a, isc_user_routines_9c,
  isc_user_routines_18c, isc_user_routines_1cc, isc_user_routines_20c,
  isc_preserve_heap, isc_heap, isc_literal_solutions,
  isc_user_routines_2dc, isc_user_routines_2e0, isc_user_routines_2e4,
  isc_user_routines_2e8, isc_user_routines_2ec, isc_user_routines_2f0,
  isc_user_routines_2f4, isc_user_routines_2f8, isc_user_routines_2fc,
  isc_user_routines_300, isc_user_routines_304, isc_user_routines_308,
  isc_user_routines_30c, isc_user_routines_310, ur_unused_314,
  isc_user_routines_31c, isc_user_routines_320, isc_user_routines_324,
  isc_user_routines_328, isc_user_routines_32c, isc_user_routines_330,
  isc_user_routines_334, isc_user_routines_338, isc_user_routines_33c,
  isc_user_routines_340, isc_user_routines_344, isc_user_routines_348,
  isc_user_routines_34c, isc_user_routines_350, isc_user_routines_352,
  isc_user_routines_354, isc_user_routines_356, isc_user_routines_358,
  ur_unused_35a;

{ literal_base_register - the register literals are addressed from, by
  the literal model (isc_user_routines_352: 1 the register of +0x330,
  2 and 3 LB's, +0x334); nil for another model.

  0x20DD7C, 0x48 bytes: the word compared with 1, 2, 3; A0. }

function literal_base_register;
begin
  case isc_user_routines_352 of
    1: literal_base_register := isc_user_routines_330;
    2: literal_base_register := isc_user_routines_334;
    3: literal_base_register := isc_user_routines_334;
    otherwise literal_base_register := nil;
  end;
end;

{ is_in_range - whether lo <= v <= hi.

  0x20DDC4, 0x30 bytes: v 8, lo 12, hi 16 (`sge', `sle', `and.b'). }

function is_in_range;
begin
  is_in_range := (v >= lo) and (v <= hi);
end;

{ local_create_soln_for_ip_reg, _fp_reg, _fp_reg_pair, _fp_reg_quad -
  a new solution of kind 11, 8, 9 or 10 (an integer register, a
  floating register, pair, quad) from heap, with no children,
  attributes or symbol.

  0x20DDF4, 0x20DE28, 0x20DE5C, 0x20DE90, 0x34 bytes each: heap 8 (by
  address); new_solution's result left in A0. }

function local_create_soln_for_ip_reg;
begin
  local_create_soln_for_ip_reg := new_solution(heap, 11, 0, nil, nil, 0);
end;

function local_create_soln_for_fp_reg;
begin
  local_create_soln_for_fp_reg := new_solution(heap, 8, 0, nil, nil, 0);
end;

function local_create_soln_for_fp_reg_pair;
begin
  local_create_soln_for_fp_reg_pair := new_solution(heap, 9, 0, nil, nil, 0);
end;

function local_create_soln_for_fp_reg_quad;
begin
  local_create_soln_for_fp_reg_quad := new_solution(heap, 10, 0, nil, nil, 0);
end;

{ local_initialize_symbol - a symbol's home solution made (once): the
  new attributes returned (attr with bit 25, initialized, and bit 26,
  has a home solution) and the home stored in home^ (nil for a symbol
  kept in memory).

  A declared register (l12 bit 10) is homed in that register's
  physical solution (reg: the class in the high word, 0 lir_3e60, 1
  lir_3d60, 2 lir_3c60; the number in the low word).  Otherwise the
  symbol is a register candidate when it is declared so (cand) or
  allocated to a register (vat 5), or when it is none of: a volatile
  (cargs -DBA with bit 14 clear, or any -DBA), a structure (kind 131,
  or 132 with +35 bit 7 for vat 1 or 7), a global of a vat other than
  2 and 6 (or 1 and 7 in a routine of kind 105), an address-taken
  (b34) or aliased (b38) symbol, larger than 32 bits (unless +0x358 lets
  a real of 64 or 128 bits through), a kind 133 or 127, a symbol with
  attributes 16#10400041 (or 16#10400040 when b40), or one with bit 6
  or -ZERO in vat 1 or 7.  A candidate gets a register solution from
  the compilation's heap (+0x20C) when b36, else from the preserved
  heap (+0x224): an integer register, or by bits a floating register,
  pair or quad for a real (type kind 123); with a new live range (pair
  live ranges for the complex classes 6 and 13: the imaginary part's
  in the solution's +24, mated with the real part's for class 6).

  0x20DEC4, 0x4E8 bytes, no A5 (internal): attr 8, l12 12, reg 16, typ
  20 (by address), bits 24, vat a word at 28, cls a word at 30, cand,
  b34, b36, b38, b40 bytes at 32..40, sym 42, home 46 (the address of
  the symbol's home cell); the attributes in D0.  The candidate flag
  in (-28,A6); the kind's case is a jump table over 8..11; the two
  tests of cargs' db (`and.l #16#18000' of +0x282) are the image's. }

function local_initialize_symbol(
    attr: integer32;
    l12: integer32;
    reg: integer32;
    typ: ur_type_exp_ptr_t;
    bits: integer32;
    vat: integer;
    cls: integer;
    cand: boolean;
    b34: boolean;
    b36: boolean;
    b38: boolean;
    b40: boolean;
    sym: univ_ptr;
    home: ur_solution_ptr_ptr_t): integer32; internal; options(val_param);
var
  sol: isc_solution_ptr_t;
  lr: lr_ptr_t;
  lr2: lr_ptr_t;
  is_cand: boolean;
  big_struct: boolean;
  is_struct: boolean;
  n: integer32;
begin
  attr := attr ! 16#02000000;
  if (l12 & 16#400) <> 0 then begin
    n := reg & 16#FFFF;
    case rshft(reg, 16) of
      0: sol := isc_solution_ptr_t(lir_3e60[n]);
      1: sol := isc_solution_ptr_t(lir_3d60[n]);
      2: sol := isc_solution_ptr_t(lir_3c60[n]);
      otherwise bug_check('ISC: local_initialize_symbol: Unrecognized reg_types.%$');
    end;
    attr := attr ! 16#04000000;
  end
  else begin
    is_cand := false;
    if cand or (vat = 5) then
      is_cand := true
    else if not b34 then begin
      big_struct := (typ^.base^.kind = 132) and typ^.base^.ty_f35.b7;
      is_struct := (vat in [1, 7]) and ((typ^.base^.kind = 131) or big_struct);
      if (vat in [2, 6])
         or ((vat in [1, 7]) and (isc_node_ptr_t(il_180)^.kind = 105)) then
        if not big_struct and not is_struct and not b38 then
          if (((attr & 16#4000) <> 0) or (cargs_$options.db <> 3))
             and (cargs_$options.db <> 3) then
            if bits > 0 then
              if (bits <= 32)
                 or (isc_user_routines_358 and (typ^.base^.kind = 123)
                     and ((bits = 64) or (bits = 128))) then
                if (typ^.base^.kind <> 133) and (typ^.base^.kind <> 127) then
                  if ((attr & 16#10400041) = 0)
                     or (b40 and ((attr & 16#10400040) = 0)) then
                    if not ((((attr & 16#40) <> 0) or (2 in cargs_$options.flags_286))
                            and (vat in [1, 7])) then
                      is_cand := true;
    end;
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('====>>>> local_initialize_symbol(');
      write(il_node_to_string(sym));
      write('): is_a_register_candidate = ');
      write(is_cand:1);
      write('.');
      writeln;
      writeln;
    end;
    if not is_cand then
      sol := nil
    else begin
      if b36 then begin
        if (vat = 5) or (typ^.base^.kind <> 123) then
          sol := local_create_soln_for_ip_reg(isc_user_routines_20c)
        else if bits = 32 then
          sol := local_create_soln_for_fp_reg(isc_user_routines_20c)
        else if bits = 64 then
          sol := local_create_soln_for_fp_reg_pair(isc_user_routines_20c)
        else if bits = 128 then
          sol := local_create_soln_for_fp_reg_quad(isc_user_routines_20c)
        else
          bug_check('ISC: local_initialize_symbol: Unrecognized register candidate size.%$');
      end
      else if vat = 5 then
        sol := local_create_soln_for_ip_reg(isc_preserve_heap)
      else if typ^.base^.kind <> 123 then
        sol := local_create_soln_for_ip_reg(isc_preserve_heap)
      else if bits = 32 then
        sol := local_create_soln_for_fp_reg(isc_preserve_heap)
      else if bits = 64 then
        sol := local_create_soln_for_fp_reg_pair(isc_preserve_heap)
      else if bits = 128 then
        sol := local_create_soln_for_fp_reg_quad(isc_preserve_heap)
      else
        bug_check('ISC: local_initialize_symbol: Unrecognized register candidate size.%$');
      sol^.object_with_name := sym;
      case sol^.kind of
        11: lr := lir_$new_live_range_ip_reg;
        9: if cls = 6 then
             lr := lir_$new_live_range_fp_reg
           else
             lr := lir_$new_live_range_fp_reg_pair;
        8: lr := lir_$new_live_range_fp_reg;
        10: lr := lir_$new_live_range_fp_reg_pair;
        otherwise bug_check('ISC: local_initialize_symbol: Unrecognized home^.kind.%$');
      end;
      lr^.node20 := sym;
      if (attr & 16#800) <> 0 then
        lr^.rrp := lr^.rrp + [rrp$unique_value];
      sol^.live_range := lr;
      if (vat <> 5) and (cls in [6, 13]) then begin
        case sol^.kind of
          9: lr2 := lir_$new_live_range_fp_reg;
          10: lr2 := lir_$new_live_range_fp_reg_pair;
          otherwise bug_check('ISC: local_initialize_symbol: Unrecognized home^.kind.%$');
        end;
        lr2^.node20 := sym;
        if (attr & 16#800) <> 0 then
          lr2^.rrp := lr2^.rrp + [rrp$unique_value];
        sol^.live_range_of_imaginary_part := lr2;
        if cls = 6 then begin
          lr^.mate := lr2;
          lr2^.mate := lr;
        end;
      end;
      attr := attr ! 16#04000000;
      if isc_user_routines_356 or isc_user_routines_354 then begin
        write('====>>>> local_initialize_symbol(');
        write(il_node_to_string(sym));
        write('): home^.kind = ');
        write(solution$t(sol^.kind):1);
        write('.');
        writeln;
        writeln;
      end;
    end;
  end;
  home^ := sol;
  local_initialize_symbol := attr;
end;

{ local_initialize_fortran_symbol - a FORTRAN symbol's home solution
  made unless it has one (attributes bit 25): described by the
  module's type record (ur_fortran_type, whose base is the well-known
  type of its class: +0x344 for classes 13, 6, 5, +0x348 for 4, +0x34C
  otherwise), 129 bits unless its size is computed (sz_fsym, for a
  common member without +32 or a kind 1 with +40), aliased when it is
  of kind 1 or 3 with +28, address-taken (b34) when a common member of
  class 7.

  0x20E6AA, 0x13A bytes, no A5 (internal; the type record is (128,A5),
  the caller's A5): sym 8, cand a byte at 12, b36 a byte at 14. }

procedure local_initialize_fortran_symbol(
    sym: isc_node_ptr_t;
    cand: boolean;
    b36: boolean); internal; options(val_param);
var
  addr_taken: boolean;
  aliased: boolean;
  bits: integer32;
  attr: integer32;
begin
  attr := sym^.fs_attr;
  if (attr & 16#02000000) = 0 then begin
    addr_taken := false;
    if sym^.fs_f10.cls = 13 then
      ur_fortran_type.base := isc_user_routines_344
    else if sym^.fs_f10.cls = 6 then
      ur_fortran_type.base := isc_user_routines_344
    else if sym^.fs_f10.cls = 5 then
      ur_fortran_type.base := isc_user_routines_344
    else if sym^.fs_f10.cls = 4 then
      ur_fortran_type.base := isc_user_routines_348
    else
      ur_fortran_type.base := isc_user_routines_34c;
    bits := 129;
    if not sym^.fs_f10.b7 then
      if ((sym^.fs_f44.kind = 3) and (sym^.fs_l32 = 0))
         or ((sym^.fs_f44.kind = 1) and (sym^.fs_l40 <> 0)) then
        bits := sz_fsym(il_$node_ptr_t(sym)) * 8;
    if (sym^.fs_f44.kind = 3) and (sym^.fs_f10.cls = 7) then
      addr_taken := true;
    aliased := false;
    if (sym^.fs_f44.kind in [1, 3]) and (sym^.fs_l28 <> 0) then
      aliased := true;
    sym^.fs_attr := local_initialize_symbol(attr, 0, sym^.fs_disp,
        addr(ur_fortran_type), bits, sym^.fs_f10.sto, sym^.fs_f10.cls,
        cand, addr_taken, b36, aliased, false, sym, addr(sym^.fs_home));
  end;
end;

{ local_initialize_var_name - a variable's home solution made unless
  it has one (attributes bit 25): described by type_exp, address-taken
  never, a candidate also when its initializer is an address (163
  ADDR_CON) and +34 bit 8 is clear, b40 for a parameter (type kind 121)
  of +44 2.

  0x20E7E4, 0xAE bytes, no A5 (internal): sym 8, cand a byte at 12
  (assigned: `st (12,A6)'), b36 a byte at 14; the type record in
  (-32,A6). }

procedure local_initialize_var_name(
    sym: isc_node_ptr_t;
    cand: boolean;
    b36: boolean); internal; options(val_param);
var
  addr_taken: boolean;
  param: boolean;
  t: ur_type_exp_t;
  attr: integer32;
begin
  attr := sym^.vn_attr;
  if (attr & 16#02000000) = 0 then begin
    addr_taken := false;
    type_exp(sym, addr(t));
    if (sym^.vn_type^.kind = 121) and (sym^.vn_type^.vn_align = 2) then
      param := true
    else
      param := false;
    if sym^.vn_p4 <> nil then
      if (sym^.vn_p4^.kind = 163) and ((sym^.vn_attr & 16#100) = 0) then
        cand := true;
    sym^.vn_attr := local_initialize_symbol(attr, sym^.vn_l40, sym^.vn_reg,
        addr(t), sym^.vn_bits, sym^.vn_vat, 0, cand, addr_taken, b36,
        false, param, sym, addr(sym^.vn_home));
  end;
end;

{ initialize_well_known_symbol - the home solution of a variable or
  FORTRAN symbol made in the compilation's heap.

  0x20E892, 0x40 bytes: sym 8, cand a byte at 12; b36 true (`st'). }

procedure initialize_well_known_symbol;
begin
  if sym^.kind = 109 then
    local_initialize_var_name(sym, cand, true)
  else
    local_initialize_fortran_symbol(sym, cand, true);
end;

{ number_of_one_bits - the bits set in x.

  0x20E8D2, 0x36 bytes: x 8; a loop of 32 (`dbf' from 31) shifting by
  the bit's index (`lsr.l D2,D4; lsr.b #1,D4; bcc'), none for 0. }

function number_of_one_bits;
var
  n: integer32;
  i: integer;
begin
  n := 0;
  if x <> 0 then
    for i := 0 to 31 do
      if odd(rshft(x, i)) then
        n := n + 1;
  number_of_one_bits := n;
end;

{ alignment_from_sr_info - the alignment (low zero bits) a variable
  under strength reduction keeps: the least of its initial value's
  and its increments' (an increment that is not a literal: 0), plus
  what the reduced expression adds (lshift by n: n; mul by n: n's low
  zero bits; add: 0); then lowered by each increment of a list of more
  than one (an add_to or sub_from by a literal; another operator is
  reported).  Traced throughout.

  0x20E908, 0x8D8 bytes: info 8 (by address: a symbol's +52 or +46);
  the result a word in D0.  The step's alignment (D2) is not set
  before the first loop: an increment that is a literal compares with
  whatever D2 holds (`ext.l D2; cmp.l D0,D2; ble'); kept as the image
  has it.  An unrecognized operator is printed unconditionally, then
  either reported (a trace) or bug_check'ed.  The node's address is
  written as an integer32 (code 2673). }

function alignment_from_sr_info;
var
  sr: isc_sr_info_ptr_t;
  p: isc_sr_cell_ptr_t;
  n: isc_node_ptr_t;
  v: integer32;
  init_align: integer;
  step_align: integer;
  reduced_align: integer;
  a: integer;
  trace: boolean;
begin
  sr := info;
  if isc_user_routines_356 or isc_user_routines_354 then begin
    write('alignment_from_sr_info:');
    writeln;
  end;
  n := sr^.initial^.as_rhs;
  if il_node_has_integer_value(n) then begin
    v := il_node_to_integer_value(n);
    init_align := number_of_rightmost_zeroes(v);
  end
  else
    init_align := 0;
  if isc_user_routines_356 or isc_user_routines_354 then begin
    write('   alignment_of_initial = ');
    write(init_align:1);
    write('.');
    writeln;
  end;
  p := sr^.inclist;
  while p <> nil do begin
    n := p^.node^.as_rhs;
    if il_node_has_integer_value(n) then begin
      v := il_node_to_integer_value(n);
      if step_align > number_of_rightmost_zeroes(v) then
        step_align := number_of_rightmost_zeroes(v);
    end
    else
      step_align := 0;
    p := p^.next;
  end;
  trace := isc_user_routines_356 or isc_user_routines_354;
  if trace then begin
    write('   alignment_of_step    = ');
    write(step_align:1);
    write('.');
    writeln;
  end;
  n := sr^.reduced;
  if n = nil then
    reduced_align := 0
  else
    case n^.tr_op of
      27: begin
        v := il_node_to_integer_value(n^.tr_opnd[2]);
        reduced_align := v;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          write('   reduced = lshift(xxx, ');
          write(v:1);
          write(').');
          writeln;
        end;
      end;
      3: begin
        v := il_node_to_integer_value(n^.tr_opnd[2]);
        reduced_align := number_of_rightmost_zeroes(v);
        if isc_user_routines_356 or isc_user_routines_354 then begin
          write('   reduced = mul(xxx, ');
          write(v:1);
          write(').');
          writeln;
        end;
      end;
      1: begin
        v := il_node_to_integer_value(n^.tr_opnd[2]);
        reduced_align := 0;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          write('   reduced = add(xxx, ');
          write(v:1);
          write(').');
          writeln;
        end;
      end;
      otherwise begin
        write('*******************************************************************');
        writeln;
        write('The unrecognized reduce operator is: ');
        write(ur_top_t(n^.tr_op):1);
        write('.');
        writeln;
        write('*******************************************************************');
        writeln;
        if trace then begin
          write('ISC: alignment_from_sr_info: Unrecognized reduced operator.');
          writeln;
        end
        else
          bug_check('ISC: alignment_from_sr_info: Unrecognized reduced operator.%$');
      end;
    end;
  trace := isc_user_routines_356 or isc_user_routines_354;
  if trace then begin
    write('   alignment_of_reduced = ');
    write(reduced_align:1);
    write('.');
    writeln;
  end;
  if step_align > init_align then
    step_align := init_align;
  step_align := step_align + reduced_align;
  if trace then begin
    write('   result  = ');
    write(step_align:1);
    write('.');
    writeln;
  end;
  if sr^.inclist <> nil then
    if sr^.inclist^.next <> nil then begin
      if trace then begin
        write('   Walking inclist:');
        writeln;
      end;
      p := sr^.inclist;
      while p <> nil do begin
        n := p^.node;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          write('    node @ ');
          write(integer32(n):1);
          write(':');
          writeln;
          write('      kind = ');
          write(an_kind_t(n^.kind):1);
          write('.');
          writeln;
          write('      op   = ');
          write(ur_aop_t(n^.as_op):1);
          write('.');
          writeln;
          write('      rhs  = ');
          write(il_node_to_string(n^.as_rhs));
          write('.');
          writeln;
        end;
        if (n^.as_op = 2) or (n^.as_op = 1) then begin
          if il_node_has_integer_value(n^.as_rhs) then begin
            v := il_node_to_integer_value(n^.as_rhs);
            a := number_of_rightmost_zeroes(v);
          end
          else
            a := 0;
          trace := isc_user_routines_356 or isc_user_routines_354;
          if trace then begin
            write('   alignment_of_step = ');
            write(a:1);
            write('.');
            writeln;
          end;
          if a < step_align then begin
            step_align := a;
            if trace then begin
              write('   WARNING! result has been decreased!');
              writeln;
            end;
          end;
        end
        else begin
          write('*******************************************************************');
          writeln;
          write('The unrecognized increment operator is: ');
          write(ur_aop_t(n^.as_op):1);
          write('.');
          writeln;
          write('*******************************************************************');
          writeln;
          if isc_user_routines_356 or isc_user_routines_354 then begin
            write('ISC: alignment_from_sr_info: Unrecognized increment operator.');
            writeln;
          end
          else
            bug_check('ISC: alignment_from_sr_info: Unrecognized increment operator.%$');
        end;
        p := p^.next;
      end;
    end;
  trace := isc_user_routines_356 or isc_user_routines_354;
  if trace then begin
    write('   result  = ');
    write(step_align:1);
    write('.');
    writeln;
  end;
  alignment_from_sr_info := step_align;
end;

{ lir_$can_encode_as_immediate_postincrement - whether v fits a
  postincrement's immediate by the literal model
  (isc_user_routines_352: 1 a signed byte, 2 a signed halfword, 3
  -15..8191); false for another.

  0x2105D4, 0x54 bytes: v 8; the bounds pushed (`pea'), one call of
  is_in_range. }

function lir_$can_encode_as_immediate_postincrement;
var
  r: boolean;
begin
  r := false;
  case isc_user_routines_352 of
    1: r := is_in_range(v, -128, 127);
    2: r := is_in_range(v, -32768, 32767);
    3: r := is_in_range(v, -15, 8191);
    otherwise ;
  end;
  lir_$can_encode_as_immediate_postincrement := r;
end;

{ alignment_from_il_node - the known alignment of node (the low bits of
  its address that are zero): by kind, a constant for the scalar types
  and some objects, a size class for set and string constants, a type's
  or symbol's alignment field; for a variable (109) 2 when allocated
  to a register, else (computing its +44 from its size first, for a
  static or by-address one) its declared register's or address bits'
  low zero bits, or +44; for a FORTRAN symbol 2 in a register, else
  get_alignment's.  Reported (or bug_check'ed) for nil (-1) and for an
  unrecognized kind (0).

  0x210628, 0x3C8 bytes: node 8; a word in D0; the case a chain of
  comparisons in the order 78, 83, 80, 79, 85, 82, 84, 81, 87, 77, 86,
  200, 156, 212, 92, 163, 131, ...; the sizes compared unsigned
  (`bhi').  get_alignment's longword result is returned as it is. }

function alignment_from_il_node;
var
  il: isc_node_ptr_t;
  a: integer;
begin
  il := node;
  if il = nil then begin
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: alignment_from_il_node: ''il'' was NIL.');
      writeln;
    end
    else
      bug_check('ISC: alignment_from_il_node: ''il'' was NIL.%$');
    a := -1;
  end
  else
    case il^.kind of
      77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 200: a := 2;
      156, 212, 92:
        if il_$node_ptr_t(il)^.set_len <= 1 then
          a := 0
        else if il_$node_ptr_t(il)^.set_len <= 2 then
          a := 1
        else if il_$node_ptr_t(il)^.set_len <= 4 then
          a := 3
        else
          a := 7;
      163: a := 2;
      131: a := il_$node_ptr_t(il)^.xw[12];
      111: a := 3;
      90: a := 3;
      198: a := 3;
      89: a := 3;
      119: a := il_$node_ptr_t(il)^.xw[16];
      174: a := il_$node_ptr_t(il)^.xw[11];
      122:
        case il_$node_ptr_t(il)^.xw[2] of
          1: a := 0;
          2: a := 1;
          4: a := 2;
          otherwise a := 0;
        end;
      121: a := il_$node_ptr_t(il)^.xw[17];
      197: a := il_$node_ptr_t(il)^.xw[12];
      120: a := il_$node_ptr_t(il)^.xw[16];
      173: a := il_$node_ptr_t(il)^.xw[11];
      88: a := 2;
      132: a := il_$node_ptr_t(il)^.xw[10];
      118: a := il_$node_ptr_t(il)^.xw[25];
      109:
        if il^.vn_vat = 5 then
          a := 2
        else begin
          if ((il^.vn_attr & 16#10000000) <> 0)
             or (((il^.vn_attr & 16#400) = 0) and (il^.vn_vat = 2)
                 and ((il^.vn_attr & 16#04000000) = 0)) then
            if il^.vn_bits <= 16 then
              il^.vn_align := 1
            else if il^.vn_bits <= 32 then
              il^.vn_align := 2
            else
              il^.vn_align := 3;
          if (il^.vn_attr & 16#400) <> 0 then
            a := number_of_rightmost_zeroes(il^.vn_reg)
          else
            a := il^.vn_align;
        end;
      110:
        if il^.fs_f10.sto = 5 then
          a := 2
        else
          a := get_alignment(il);
      otherwise begin
        write('*******************************************************');
        writeln;
        write('ISC: The illegal IL node kind is: ');
        write(an_kind_t(il^.kind):1);
        write('.');
        writeln;
        write('*******************************************************');
        writeln;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          write('ISC: alignment_from_il_node: illegal IL node kind.');
          writeln;
        end
        else
          bug_check('ISC: alignment_from_il_node: illegal IL node kind.%$');
        a := 0;
      end;
    end;
  alignment_from_il_node := a;
end;

{ available_precision_function - the bits available in sol: a field's
  width (+77) for a register field (kind 12), else its inherited
  attributes' +24.

  0x210B06, 0x30 bytes: sol 8; D0. }

function available_precision_function;
begin
  if sol^.kind = 12 then
    available_precision_function := sol^.f76.field_precision
  else
    available_precision_function := sol^.inherited_attributes^.fetch_precision;
end;

{ is_all_zeroes - whether node is a set constant (156) whose words are
  all zero.

  0x210B36, 0x52 bytes: node 8; the words from +18, (len + 1) div 2 of
  them (`dbf' and the 32-bit count's high word); D0. }

function is_all_zeroes;
var
  r: boolean;
  i: integer32;
begin
  if node^.kind = 156 then begin
    r := true;
    for i := 1 to (node^.set_len + 1) div 2 do
      if node^.set_words[i] <> 0 then
        r := false;
  end
  else
    r := false;
  is_all_zeroes := r;
end;

{ fetch_precision_to_bits_trusted - the alignment mask a fetch of p
  bits may trust: 0 for up to 8, 1 for 16, 3 for 32, 7 for 64; another
  value reported or bug_check'ed (the result then unset).

  0x210B88, 0xCE bytes: p 8 (written and passed to bug_check by
  address). }

function fetch_precision_to_bits_trusted;
begin
  if p <= 8 then
    fetch_precision_to_bits_trusted := 0
  else if p <= 16 then
    fetch_precision_to_bits_trusted := 1
  else if p <= 32 then
    fetch_precision_to_bits_trusted := 3
  else if p <= 64 then
    fetch_precision_to_bits_trusted := 7
  else if isc_user_routines_356 or isc_user_routines_354 then begin
    write('ISC: fetch_precision_to_bits_trusted: Unrecognized fetch_precision value (');
    write(p:1);
    write(').');
    writeln;
  end
  else
    bug_check('ISC: fetch_precision_to_bits_trusted: Unrecognized fetch_precision value (%wd).%$', p);
end;

{ make_bit_mask_1 - n one bits shifted to start at bit lsb (n in 0..32,
  lsb in 0..31; otherwise reported or bug_check'ed, and 0).

  0x210CF2, 0x138 bytes: n 8, lsb 12 (both written by address); the
  shifts' counts from validate_shift_count. }

function make_bit_mask_1;
var
  m: integer32;
begin
  if is_in_range(n, 0, 32) and is_in_range(lsb, 0, 31) then begin
    if n = 0 then
      m := 0
    else if n = 32 then
      m := -1
    else
      m := lshft(1, validate_shift_count(n)) - 1;
    if lsb > 0 then
      m := lshft(m, validate_shift_count(lsb));
  end
  else begin
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: make_bit_mask_1: number_of_one_bits = ');
      write(n:1);
      write(' and bit_position_of_lsb = ');
      write(lsb:1);
      write('.');
      writeln;
    end
    else
      bug_check('ISC: make_bit_mask_1 has invalid arguments.%$');
    m := 0;
  end;
  make_bit_mask_1 := m;
end;

{ make_bit_mask_2 - the bits msb down to lsb set (both in 0..31, msb
  >= lsb; otherwise reported or bug_check'ed, and 0).

  0x210EA0, 0x11E bytes: msb 8, lsb 12; make_bit_mask_1's arguments
  stored first in (-8,A6) and (-4,A6). }

function make_bit_mask_2;
begin
  if is_in_range(msb, 0, 31) and is_in_range(lsb, 0, 31) and (msb >= lsb) then
    make_bit_mask_2 := make_bit_mask_1(msb - lsb + 1, lsb)
  else begin
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: make_bit_mask_2: msb = ');
      write(msb:1);
      write(' and lsb = ');
      write(lsb:1);
      write('.');
      writeln;
    end
    else
      bug_check('ISC: make_bit_mask_2 has invalid arguments.%$');
    make_bit_mask_2 := 0;
  end;
end;

{ bits_known_function - the bits known of op's result from its
  operands' known bits a and b (the generated patterns' bits_known
  attribute): +, and, eor, or, -, and-not, mod, div (0 for a zero b)
  by the operator, a for expon, the negation and complement of a, 0
  for the ISC's signed and unsigned mod and rem; another operator
  reported or bug_check'ed (0).

  0x211014, 0x23A bytes: op a word at 8 (il$t; written by address),
  a 10, b 14; a jump table over il_add_top .. il_unsigned_mod_top
  (105..173); mod and div by the run time's m$ois$lll and m$dis$lll. }

function bits_known_function;
var
  r: integer32;
begin
  case op of
    il_add_top, il_index_top: r := a + b;
    il_and_top, il_set_and_top: r := a & b;
    il_eor_top: r := xor(a, b);
    il_or_top, il_set_or_top: r := a ! b;
    il_sub_top: r := a - b;
    il_set_diff_top: r := a & ~b;
    il_expon_top: r := a;
    il_signed_mod_top, il_unsigned_mod_top:
      if b = 0 then r := 0 else r := a mod b;
    il_signed_div_top, il_unsigned_div_top:
      if b = 0 then r := 0 else r := a div b;
    il_isc_signed_mod_top, il_isc_signed_rem_top, il_isc_unsigned_mod_top,
    il_isc_unsigned_rem_top:
      r := 0;
    il_neg_top: r := -a;
    il_not_top: r := ~a;
    otherwise begin
      write('*******************************************************');
      writeln;
      write('ISC: The illegal IL node kind is: ');
      write(op:1);
      write('.');
      writeln;
      write('*******************************************************');
      writeln;
      if isc_user_routines_356 or isc_user_routines_354 then begin
        write('ISC: bits_known_function: illegal IL node kind.');
        writeln;
      end
      else
        bug_check('ISC: bits_known_function: illegal IL node kind.%$');
      r := 0;
    end;
  end;
  bits_known_function := r;
end;

{ bits_to_alignment - the low bits of a value that are trusted and
  known zero: counted while trusted's low bit is set and known's is
  clear.

  0x211DC0, 0x3A bytes: known 8, trusted 12, shifted right together; a
  word in D0. }

function bits_to_alignment;
var
  n: integer;
begin
  n := 0;
  while odd(trusted) and not odd(known) do begin
    n := n + 1;
    trusted := rshft(trusted, 1);
    known := rshft(known, 1);
  end;
  bits_to_alignment := n;
end;

{ bits_trusted_function - the bits trusted of op's result from its
  operands' trusted bits a and b: both's for the logical and set
  operators; for add, index and sub both's below the lowest bit not
  trusted (a's alone for neg); a's for not; none for expon, the ISC's
  mod and rem, div and mod; another operator reported or bug_check'ed
  (0).

  0x211DFA, 0x1F8 bytes: op a word at 8 (il$t), a 10, b 14; a jump
  table over 105..173; the lowest clear bit found by a mask shifted
  left until it is zero. }

function bits_trusted_function;
var
  r: integer32;
  m: integer32;
begin
  case op of
    il_and_top, il_eor_top, il_or_top, il_set_and_top, il_set_diff_top,
    il_set_or_top:
      r := a & b;
    il_add_top, il_index_top, il_sub_top: begin
      r := a & b;
      m := 1;
      repeat
        if (r & m) = 0 then begin
          r := r & (m - 1);
          exit;
        end;
        m := lshft(m, 1);
      until m = 0;
    end;
    il_neg_top: begin
      r := a;
      m := 1;
      repeat
        if (r & m) = 0 then begin
          r := r & (m - 1);
          exit;
        end;
        m := lshft(m, 1);
      until m = 0;
    end;
    il_expon_top, il_isc_signed_mod_top, il_isc_signed_rem_top,
    il_isc_unsigned_mod_top, il_isc_unsigned_rem_top, il_signed_div_top,
    il_signed_mod_top, il_unsigned_div_top, il_unsigned_mod_top:
      r := 0;
    il_not_top: r := a;
    otherwise begin
      write('*******************************************************');
      writeln;
      write('ISC: The illegal IL node kind is: ');
      write(op:1);
      write('.');
      writeln;
      write('*******************************************************');
      writeln;
      if isc_user_routines_356 or isc_user_routines_354 then begin
        write('ISC: bits_trusted_function: illegal IL node kind.');
        writeln;
      end
      else
        bug_check('ISC: bits_trusted_function: illegal IL node kind.%$');
      r := 0;
    end;
  end;
  bits_trusted_function := r;
end;

{ bits_trusted_of_fortran_symbol - the low bits of a FORTRAN symbol's
  address that may be trusted (isc_readonly_tables' mask of its
  alignment): from its strength reduction (attributes bit 17), none for
  a register candidate, from its displacement for storage 11, else
  alignment_from_il_node's.

  0x212058, 0x76 bytes: sym 8 and x 12 by address (x unused); the mask
  `move.l (2728,A1)' of 0x2BCDFC + 4 * alignment. }

function bits_trusted_of_fortran_symbol;
var
  s: isc_node_ptr_t;
  a: integer;
begin
  s := sym;
  if (s^.fs_attr & 16#20000) <> 0 then
    a := alignment_from_sr_info(s^.fs_sr)
  else if isc_$is_a_register_candidate(s) then begin
    bits_trusted_of_fortran_symbol := 0;
    return;
  end
  else if s^.fs_f10.sto = 11 then
    a := number_of_rightmost_zeroes(s^.fs_disp)
  else
    a := alignment_from_il_node(s);
  bits_trusted_of_fortran_symbol := isc_readonly_tables.masks[a];
end;

{ bits_trusted_of_var_name - likewise a variable's (attributes +32,
  strength reduction +52, vat 11 by its +56).

  0x2120CE, 0x6E bytes: as bits_trusted_of_fortran_symbol. }

function bits_trusted_of_var_name;
var
  s: isc_node_ptr_t;
  a: integer;
begin
  s := sym;
  if (s^.vn_attr & 16#20000) <> 0 then
    a := alignment_from_sr_info(s^.vn_sr)
  else if isc_$is_a_register_candidate(s) then begin
    bits_trusted_of_var_name := 0;
    return;
  end
  else if s^.vn_vat = 11 then
    a := number_of_rightmost_zeroes(s^.vn_reg)
  else
    a := alignment_from_il_node(s);
  bits_trusted_of_var_name := isc_readonly_tables.masks[a];
end;

{ bits_trusted_of_symbol - bits_trusted_of_var_name for a variable
  (109), else bits_trusted_of_fortran_symbol.

  0x21213C, 0x40 bytes: sym 8, x 12, both passed on by address. }

function bits_trusted_of_symbol;
begin
  if sym^.kind = 109 then
    bits_trusted_of_symbol := bits_trusted_of_var_name(sym, x)
  else
    bits_trusted_of_symbol := bits_trusted_of_fortran_symbol(sym, x);
end;

{ get_kind_of_home_solution - the kind of sym's home solution (0 when
  sym is not a register candidate).

  0x21217C, 0x32 bytes: sym 8; a word in D0. }

function get_kind_of_home_solution;
begin
  if isc_$is_a_register_candidate(sym) then
    get_kind_of_home_solution :=
        isc_solution_ptr_t(isc_$get_home_solution(sym))^.kind
  else
    get_kind_of_home_solution := 0;
end;

{ il_node_has_float_value - whether node is a real constant (88, 89;
  false for nil).

  0x2121AE, 0x38 bytes: node 8. }

function il_node_has_float_value;
begin
  if node = nil then
    il_node_has_float_value := false
  else if (node^.kind = 88) or (node^.kind = 89) then
    il_node_has_float_value := true
  else
    il_node_has_float_value := false;
end;

{ il_node_has_integer_value - whether node is an integer constant (77
  .. 87, 200; false for nil).

  0x2121E6, 0x7A bytes: node 8; the case compiled as a chain (81, 84,
  85, 82, 83, 80, 86, 200, 79, 78, 77, then 87 with an action of its
  own: two arms with the same action). }

function il_node_has_integer_value;
begin
  if node = nil then
    il_node_has_integer_value := false
  else
    case node^.kind of
      77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 200:
        il_node_has_integer_value := true;
      87: il_node_has_integer_value := true;
      otherwise il_node_has_integer_value := false;
    end;
end;

{ il_node_to_integer_value - an integer constant's value (+8; 0 for
  another node).

  0x212260, 0x74 bytes: node 8; the case as il_node_has_integer_value's. }

function il_node_to_integer_value;
begin
  case node^.kind of
    77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 200:
      il_node_to_integer_value := il_$node_ptr_t(node)^.int_value;
    87: il_node_to_integer_value := il_$node_ptr_t(node)^.int_value;
    otherwise il_node_to_integer_value := 0;
  end;
end;

{ assert_kind_is_label_node - node, reported (or bug_check'ed) unless it
  is a label (144).

  0x2122D4, 0x66 bytes: node 8; A0. }

function assert_kind_is_label_node;
begin
  if node^.kind <> 144 then
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: assert_kind_is_label_node: il^.fsym.ecr.lbl_root^.kind <> label_node.');
      writeln;
    end
    else
      bug_check('ISC: assert_kind_is_label_node: il^.fsym.ecr.lbl_root^.kind <> label_node.%$');
  assert_kind_is_label_node := node;
end;

{ cs_temp_to_var_name - the variable a common subexpression's
  temporary (+24) stands for, made on first use (an integral
  temporary of 8 times +22 bits).

  0x2123D0, 0x40 bytes: node 8; A0. }

function cs_temp_to_var_name;
begin
  if node^.xp[6] = nil then
    node^.xp[6] := make_expression_temporary(122, node^.xw[11] * 8);
  cs_temp_to_var_name := node^.xp[6];
end;

{ legal_evaluation_orders - the orders (bit 0 left to right, bit 1
  right to left) two operands' solutions allow: a solution with +83
  bits 3 and 2 set takes bit 0 (the first) or bit 1 (the second)
  away.

  0x212410, 0x40 bytes: s1 8, s2 12; a word in D0 (3, then 2, minus
  2). }

function legal_evaluation_orders;
var
  r: integer;
begin
  r := 3;
  if s1^.f76.physical_register and s1^.f76.physical_register_from_function_call then
    r := 2;
  if s2^.f76.physical_register and s2^.f76.physical_register_from_function_call then
    r := r - 2;
  legal_evaluation_orders := r;
end;

{ evaluation_order_function - the order op's operands are evaluated in
  (1 left to right, 2 right to left, 0 none): for the operators whose
  operands do not commute (bit_test, f_div, f_sub, set_diff, the divs
  and mods, sub) 2 when legal allows it, else none; when both are
  legal the operand needing more (n2 > n1) first; else the one legal
  order.  None is reported under the traces.

  0x212450, 0xD6 bytes: op 8 (il$t), n1 10, n2 12, legal 14, words;
  number_of_one_bits of the unsigned word. }

function evaluation_order_function;
var
  r: integer;
begin
  if op in [il_unsigned_mod_top, il_unsigned_div_top, il_sub_top,
            il_signed_mod_top, il_signed_div_top, il_set_diff_top,
            il_f_sub_top, il_f_div_top, il_bit_test_top] then begin
    if (legal & 2) <> 0 then
      r := 2
    else
      r := 0;
  end
  else if ((legal & 1) <> 0) and ((legal & 2) <> 0) then begin
    if n2 > n1 then
      r := 2
    else
      r := 1;
  end
  else if number_of_one_bits(legal & 16#FFFF) = 1 then
    r := legal
  else
    r := 0;
  if r = 0 then
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: evaluation_order_function: result = eval_none.');
      writeln;
    end;
  evaluation_order_function := r;
end;

{ similar_solutions - whether a and b cost the same and leave the same:
  the registers they need and leave (+58..+72), code bytes, memory
  references, delay, is_destroyable, physical_register,
  uses_the_displacement, uses_the_index_register and bits_trusted; for
  a register field (12) also field_requires_sign_extend,
  bit_position_of_lsb and field_precision; for kind 16 also the low
  two bits of bits_trusted and bits_known.

  0x21255A, 0x148 bytes: a 8, b 12; the flags compared as `sne' bytes. }

function similar_solutions;
var
  r: boolean;
begin
  r := false;
  if (a^.ip_reg_max = b^.ip_reg_max)
     and (a^.ip_reg_result = b^.ip_reg_result)
     and (a^.fp_reg_max = b^.fp_reg_max)
     and (a^.fp_reg_result = b^.fp_reg_result)
     and (a^.fp_reg_pair_max = b^.fp_reg_pair_max)
     and (a^.fp_reg_pair_result = b^.fp_reg_pair_result)
     and (a^.code_bytes = b^.code_bytes)
     and (a^.memory_references = b^.memory_references)
     and (a^.delay = b^.delay)
     and (a^.f76.is_destroyable = b^.f76.is_destroyable)
     and (a^.f76.physical_register = b^.f76.physical_register)
     and (a^.f76.uses_the_displacement = b^.f76.uses_the_displacement)
     and (a^.f76.uses_the_index_register = b^.f76.uses_the_index_register)
     and (a^.bits_trusted = b^.bits_trusted) then
    r := true;
  if (a^.kind = 12) and r then
    if (a^.f76.field_requires_sign_extend <> b^.f76.field_requires_sign_extend) or (a^.f76.bit_position_of_lsb <> b^.f76.bit_position_of_lsb)
       or (a^.f76.field_precision <> b^.f76.field_precision) then
      r := false;
  if (a^.kind = 16) and r then
    if ((a^.bits_trusted & 3) <> (b^.bits_trusted & 3))
       or ((a^.bits_known & 3) <> (b^.bits_known & 3)) then
      r := false;
  similar_solutions := r;
end;

{ clearly_dominates - whether a costs no more than b in every respect
  (delay, memory references, code bytes, the registers +58..+72,
  compared unsigned) and is otherwise interchangeable with it: not
  with is_destroyable clear where b's is set; the same bits_trusted,
  uses_the_index_register, physical_register and
  uses_the_displacement; the kind 12 and 16 tests of
  similar_solutions.

  0x2126A2, 0x146 bytes: a 8, b 12 (`bhi'). }

function clearly_dominates;
var
  r: boolean;
begin
  r := false;
  if (a^.delay <= b^.delay)
     and (a^.memory_references <= b^.memory_references)
     and (a^.code_bytes <= b^.code_bytes)
     and (a^.fp_reg_pair_result <= b^.fp_reg_pair_result)
     and (a^.fp_reg_pair_max <= b^.fp_reg_pair_max)
     and (a^.fp_reg_result <= b^.fp_reg_result)
     and (a^.fp_reg_max <= b^.fp_reg_max)
     and (a^.ip_reg_max <= b^.ip_reg_max)
     and (a^.ip_reg_result <= b^.ip_reg_result) then
    r := true;
  if not a^.f76.is_destroyable and r then
    if b^.f76.is_destroyable then
      r := false;
  if r then
    if (a^.bits_trusted <> b^.bits_trusted)
       or (a^.f76.uses_the_index_register <> b^.f76.uses_the_index_register)
       or (a^.f76.physical_register <> b^.f76.physical_register)
       or (a^.f76.uses_the_displacement <> b^.f76.uses_the_displacement) then
      r := false;
  if (a^.kind = 12) and r then
    if (a^.f76.field_requires_sign_extend <> b^.f76.field_requires_sign_extend) or (a^.f76.bit_position_of_lsb <> b^.f76.bit_position_of_lsb)
       or (a^.f76.field_precision <> b^.f76.field_precision) then
      r := false;
  if (a^.kind = 16) and r then
    if ((a^.bits_trusted & 3) <> (b^.bits_trusted & 3))
       or ((a^.bits_known & 3) <> (b^.bits_known & 3)) then
      r := false;
  clearly_dominates := r;
end;

{ choose_one_solution - the cheapest of list's solutions (code bytes
  plus delay, then fewer memory references), passing over flow (7) and
  proper-subtree (22) solutions; nil when there is none.  bug_check
  for a nil list.

  0x2127E8, 0x7C bytes: list 8; the costs unsigned words, summed as
  longwords; A0. }

function choose_one_solution;
var
  best: isc_solution_ptr_t;
  c: solution_cell_ptr_t;
  s: isc_solution_ptr_t;
  cost: integer32;
  best_cost: integer32;
begin
  if list = nil then
    bug_check('ISC: choose_one_solution: list is nil.%$');
  best := nil;
  c := list^.first;
  while c <> nil do begin
    s := c^.sol;
    if (s^.kind <> 7) and (s^.kind <> 22) then begin
      cost := s^.code_bytes + s^.delay;
      if (best = nil) or (cost < best_cost)
         or ((cost = best_cost) and (s^.memory_references < best^.memory_references)) then begin
        best := s;
        best_cost := cost;
      end;
    end;
    c := c^.next;
  end;
  choose_one_solution := best;
end;

{ is_sequence_of_ones - whether x's one bits are one run (true for -1,
  false for 0): bits 0..31 scanned through four states (0 below the
  run, 1 in it, 2 above it, 3 a second run).

  0x21288C, 0x9E bytes: x 8; each state's successor by a jump table of
  four (the bit set: 1, 1, 3, 3; clear: 0, 2, 2, 3); the result state
  <> 3. }

function is_sequence_of_ones;
var
  state: integer;
  i: integer;
begin
  if x = 0 then
    is_sequence_of_ones := false
  else if x = -1 then
    is_sequence_of_ones := true
  else begin
    state := 0;
    for i := 0 to 31 do
      if odd(rshft(x, i)) then
        case state of
          0: state := 1;
          1: state := 1;
          2: state := 3;
          3: state := 3;
        end
      else
        case state of
          0: state := 0;
          1: state := 2;
          2: state := 2;
          3: state := 3;
        end;
    is_sequence_of_ones := state <> 3;
  end;
end;

{ is_sequence_of_ones_right_justified - whether x is one run of ones
  ending at bit 0 (true for -1, false for 0): the states of
  is_sequence_of_ones over bits 31..0, ending in state 1.

  0x21292A, 0x9E bytes: x 8. }

function is_sequence_of_ones_right_justified;
var
  state: integer;
  i: integer;
begin
  if x = 0 then
    is_sequence_of_ones_right_justified := false
  else if x = -1 then
    is_sequence_of_ones_right_justified := true
  else begin
    state := 0;
    for i := 31 downto 0 do
      if odd(rshft(x, i)) then
        case state of
          0: state := 1;
          1: state := 1;
          2: state := 3;
          3: state := 3;
        end
      else
        case state of
          0: state := 0;
          1: state := 2;
          2: state := 2;
          3: state := 3;
        end;
    is_sequence_of_ones_right_justified := state = 1;
  end;
end;

{ is_sequence_of_zeroes - whether x's zero bits are one run (true for
  0, false for -1): is_sequence_of_ones' states with the bits'
  meanings exchanged.

  0x2129C8, 0xA0 bytes: x 8. }

function is_sequence_of_zeroes;
var
  state: integer;
  i: integer;
begin
  if x = 0 then
    is_sequence_of_zeroes := true
  else if x = -1 then
    is_sequence_of_zeroes := false
  else begin
    state := 0;
    for i := 0 to 31 do
      if odd(rshft(x, i)) then
        case state of
          0: state := 0;
          1: state := 2;
          2: state := 2;
          3: state := 3;
        end
      else
        case state of
          0: state := 1;
          1: state := 1;
          2: state := 3;
          3: state := 3;
        end;
    is_sequence_of_zeroes := state <> 3;
  end;
end;

{ length_of_sequence_of_ones - the one bits of x (0 for 0), counted
  while is_sequence_of_ones' states are kept (and not used).

  0x212A68, 0x8C bytes: x 8. }

function length_of_sequence_of_ones;
var
  n: integer32;
  state: integer;
  i: integer;
begin
  n := 0;
  if x <> 0 then begin
    state := 0;
    for i := 0 to 31 do
      if odd(rshft(x, i)) then begin
        n := n + 1;
        case state of
          0: state := 1;
          1: state := 1;
          2: state := 3;
          3: state := 3;
        end;
      end
      else
        case state of
          0: state := 0;
          1: state := 2;
          2: state := 2;
          3: state := 3;
        end;
  end;
  length_of_sequence_of_ones := n;
end;

{ length_of_sequence_of_zeroes - the zero bits of x (32 for 0), with
  the same unused states.

  0x212AF4, 0x90 bytes: x 8. }

function length_of_sequence_of_zeroes;
var
  n: integer32;
  state: integer;
  i: integer;
begin
  n := 0;
  if x = 0 then
    n := 32
  else begin
    state := 0;
    for i := 0 to 31 do
      if odd(rshft(x, i)) then
        case state of
          0: state := 1;
          1: state := 1;
          2: state := 3;
          3: state := 3;
        end
      else begin
        n := n + 1;
        case state of
          0: state := 0;
          1: state := 2;
          2: state := 2;
          3: state := 3;
        end;
      end;
  end;
  length_of_sequence_of_zeroes := n;
end;

{ il_node_is_literal_sequence_of_ones - whether node is an integer
  constant whose value is one run of ones.

  0x212B84, 0x76 bytes: node 8; the kinds compared as a chain from 87. }

function il_node_is_literal_sequence_of_ones;
begin
  case node^.kind of
    77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 200:
      il_node_is_literal_sequence_of_ones :=
          is_sequence_of_ones(il_$node_ptr_t(node)^.int_value);
    otherwise il_node_is_literal_sequence_of_ones := false;
  end;
end;

{ il_node_is_literal_sequence_of_zeroes - whether node is an integer
  constant whose zero bits are one run, or a real constant equal to
  zero.

  0x212BFA, 0x94 bytes: node 8; the real's test `pea (12,A2); jsr
  fpp_$' with the operation words 0x0074 0xFF34, `seq' (dpc gap 7). }

function il_node_is_literal_sequence_of_zeroes;
begin
  case node^.kind of
    77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 200:
      il_node_is_literal_sequence_of_zeroes :=
          is_sequence_of_zeroes(il_$node_ptr_t(node)^.int_value);
    88, 89:
      il_node_is_literal_sequence_of_zeroes := il_$node_ptr_t(node)^.real_value = 0.0;
    otherwise il_node_is_literal_sequence_of_zeroes := false;
  end;
end;

{ in_interval_at_compile_time - whether the value of s1 lies in 0 ..
  that of s2, compared unsigned, when both are known in their size
  bytes (bits_trusted all ones in the low byte, halfword or longword
  for size 1, 2, 4); false otherwise.

  0x212C8E, 0xD0 bytes: size a word at 8, s1 10, s2 14; the known
  values the bytes and halfwords at +35 and +34 (bits_known's low
  ones); a negative upper bound (`bmi') tests `lo >= 0 or lo <= hi'. }

function in_interval_at_compile_time;
var
  lo: integer32;
  hi: integer32;
  r: boolean;
begin
  if (((s2^.bits_trusted + 1) & 16#FF) = 0) and (size = 1)
     and (((s1^.bits_trusted + 1) & 16#FF) = 0) then begin
    lo := s1^.bits_known & 16#FF;
    hi := s2^.bits_known & 16#FF;
    r := (lo >= 0) and (lo <= hi);
  end
  else if (((s2^.bits_trusted + 1) & 16#FFFF) = 0) and (size = 2)
          and (((s1^.bits_trusted + 1) & 16#FFFF) = 0) then begin
    lo := arshft(lshft(s1^.bits_known, 16), 16);
    hi := arshft(lshft(s2^.bits_known, 16), 16);
    if hi < 0 then
      r := (lo >= 0) or (lo <= hi)
    else
      r := (lo >= 0) and (lo <= hi);
  end
  else if (s2^.bits_trusted + 1 = 0) and (size = 4)
          and (s1^.bits_trusted + 1 = 0) then begin
    lo := s1^.bits_known;
    hi := s2^.bits_known;
    if hi < 0 then
      r := (lo <= hi) or (lo >= 0)
    else
      r := (lo <= hi) and (lo >= 0);
  end
  else
    r := false;
  in_interval_at_compile_time := r;
end;

{ is_device - whether node refers to a device (volatile) object: for a
  tree or reference node (kinds 137, 138, 143, 145..147, 164, 171,
  175, 189, 205) its +7 bits 3 or 4, for a FORTRAN symbol its
  attributes' bits 3 or 4 (+27), for a variable likewise (+35); false
  for nil and other kinds.

  0x212D5E, 0x8A bytes: node 8; the kinds' set after the code
  (0x212DE8, bits by 207 - kind). }

function is_device;
begin
  if node = nil then
    is_device := false
  else if node^.kind in [137, 138, 143, 145, 146, 147, 164, 171, 175, 189, 205] then
    is_device := ((node^.xl[1] & 8) <> 0) or ((node^.xl[1] & 16#10) <> 0)
  else if node^.kind = 110 then
    is_device := ((node^.xl[6] & 8) <> 0) or ((node^.xl[6] & 16#10) <> 0)
  else if node^.kind = 109 then
    is_device := ((node^.xl[8] & 8) <> 0) or ((node^.xl[8] & 16#10) <> 0)
  else
    is_device := false;
end;

{ sign_extend - v's low bits bits (8 or 16) sign-extended; v itself
  for another size.

  0x212E02, 0x42 bytes: v 8, bits 12 (`swap; clr.w; lsl.l #8; swap;
  ext.l; asr.l #8' for a byte, `swap; clr.w; swap; ext.l' for a
  halfword). }

function sign_extend;
begin
  if bits = 8 then
    sign_extend := arshft(lshft(v, 24), 24)
  else if bits = 16 then
    sign_extend := arshft(lshft(v, 16), 16)
  else
    sign_extend := v;
end;

{ integer32_from_char_string_ob - a character constant's value: its
  characters as the bytes of a longword, high first, sign-extended
  from its size when shorter than 4.

  0x212E44, 0x74 bytes: node 8, the length an unsigned word at +16,
  the characters from +18. }

function integer32_from_char_string_ob;
var
  r: integer32;
  n: integer32;
  i: integer32;
begin
  r := 0;
  n := node^.str_len;
  for i := 1 to n do
    r := lshft(r, 8) ! ord(node^.str_chars[i]);
  if n < 4 then
    if rshft(r, validate_shift_count(n * 8 - 1)) = 1 then
      r := r ! make_bit_mask_2(31, n * 8);
  integer32_from_char_string_ob := r;
end;

{ get_uparrow_dot_kind - node's kind.

  0x212EB8, 0x1C bytes: node 8; a word in D0. }

function get_uparrow_dot_kind;
begin
  get_uparrow_dot_kind := node^.kind;
end;

{ not_permissible_function - the register kinds a tree node of an
  integer operator (add, sub, neg, not, and, or, eor: ops 1, 2, 7..10,
  44) may not be given: integer register (bit 11) when permissible
  lacks it, floating register (bit 8) likewise; none otherwise.

  0x212ED4, 0x60 bytes: node 8, w12 a word (unused), permissible 14;
  the operators' set after the code (0x212F34, bits by 47 - op). }

function not_permissible_function;
var
  r: solution$set_t;
begin
  r := [];
  if (node^.kind = 137) and (node^.tr_op in [1, 2, 7, 8, 9, 10, 44]) then begin
    if not (solution$ip_reg in permissible) then
      r := [solution$ip_reg];
    if not (solution$fp_reg in permissible) then
      r := r + [solution$fp_reg];
  end;
  not_permissible_function := r;
end;

{ number_of_leftmost_zeroes - the zero bits above x's highest one (32
  for 0).

  0x212F3A, 0x46 bytes: x 8; a loop of 32 with a found flag. }

function number_of_leftmost_zeroes;
var
  n: integer32;
  i: integer32;
  found: boolean;
begin
  n := 0;
  if x = 0 then
    n := 32
  else begin
    found := false;
    for i := 0 to 31 do
      if not found then
        if odd(rshft(x, 31 - i)) then begin
          found := true;
          n := i;
        end;
  end;
  number_of_leftmost_zeroes := n;
end;

{ number_of_leftmost_ones - the one bits above x's highest zero (0 for
  0, and for -1).

  0x212F80, 0x42 bytes: x 8. }

function number_of_leftmost_ones;
var
  n: integer32;
  i: integer32;
  found: boolean;
begin
  n := 0;
  if x <> 0 then begin
    found := false;
    for i := 0 to 31 do
      if not found then
        if not odd(rshft(x, 31 - i)) then begin
          found := true;
          n := i;
        end;
  end;
  number_of_leftmost_ones := n;
end;

{ number_of_rightmost_zeroes - the zero bits below x's lowest one (32
  for 0).

  0x212FC2, 0x42 bytes: x 8. }

function number_of_rightmost_zeroes;
var
  n: integer32;
  i: integer32;
  found: boolean;
begin
  n := 0;
  if x = 0 then
    n := 32
  else begin
    found := false;
    for i := 0 to 31 do
      if not found then
        if odd(rshft(x, i)) then begin
          found := true;
          n := i;
        end;
  end;
  number_of_rightmost_zeroes := n;
end;

{ number_of_rightmost_ones - the one bits below x's lowest zero (0 for
  0, and for -1).

  0x213004, 0x3E bytes: x 8. }

function number_of_rightmost_ones;
var
  n: integer32;
  i: integer32;
  found: boolean;
begin
  n := 0;
  if x <> 0 then begin
    found := false;
    for i := 0 to 31 do
      if not found then
        if not odd(rshft(x, i)) then begin
          found := true;
          n := i;
        end;
  end;
  number_of_rightmost_ones := n;
end;

{ well_known_literal - a literal solution of v (kind 14, from the
  compilation's heap: symbol the integer constant smcontk(81, v),
  il_kind 78; every bit known and trusted, literal_32_bits_value v),
  for the table
  find_well_known_literal_solution reads.

  0x213042, 0x5C bytes: v 8; A0. }

function well_known_literal;
var
  c: il_$node_ptr_t;
  s: isc_solution_ptr_t;
begin
  c := smcontk(81, v);
  s := new_solution(isc_user_routines_20c, 14, 0, nil, c, 78);
  s^.bits_known := v;
  s^.bits_trusted := -1;
  s^.literal_32_bits_value := v;
  well_known_literal := s;
end;

{ find_well_known_literal_solution - the literal solution of v: the
  well-known one for -1 .. 32 (isc_literal_solutions, +0x254), else a
  new one (create_solution_for_literal_32_bits).

  0x21309E, 0x4A bytes: v 8; `movea.l (4,A1,D0.l)' of 0x481054 + 4 *
  v; A0. }

function find_well_known_literal_solution;
begin
  if is_in_range(v, -1, 32) then
    find_well_known_literal_solution := isc_solution_ptr_t(isc_literal_solutions[v])
  else
    find_well_known_literal_solution := create_solution_for_literal_32_bits(v);
end;

{ initialize_symbol, isc_$initialize_symbol - sym's home solution made
  (in the preserved heap, not as a declared candidate).

  0x2130E8, 0x213120, 0x38 bytes each: sym 8; the two bytes pushed as
  one `clr.l'. }

procedure initialize_symbol;
begin
  if sym^.kind = 109 then
    local_initialize_var_name(sym, false, false)
  else
    local_initialize_fortran_symbol(sym, false, false);
end;

procedure isc_$initialize_symbol;
begin
  if sym^.kind = 109 then
    local_initialize_var_name(sym, false, false)
  else
    local_initialize_fortran_symbol(sym, false, false);
end;

{ isc_$initialize_parameter - a formal's home solution made, a
  register candidate when cand.

  0x213158, 0x40 bytes: sym 8, cand a byte at 12. }

procedure isc_$initialize_parameter;
begin
  if sym^.kind = 109 then
    local_initialize_var_name(sym, cand, false)
  else
    local_initialize_fortran_symbol(sym, cand, false);
end;

{ isc_$is_a_register_candidate - whether the variable or FORTRAN symbol
  sym has a home solution (attributes bit 26, after its home is made);
  false for another node.  Traced with the home's kind.

  0x213198, 0x21E bytes: sym 8; the result in D2, written as a boolean
  (code 3924); the home in A3 (unset when there is none: only written
  when there is one). }

function isc_$is_a_register_candidate;
var
  s: isc_node_ptr_t;
  r: boolean;
  home: isc_solution_ptr_t;
begin
  s := sym;
  if s^.kind = 109 then begin
    isc_$initialize_symbol(s);
    r := (s^.vn_attr & 16#04000000) <> 0;
  end
  else if s^.kind = 110 then begin
    isc_$initialize_symbol(s);
    r := (s^.fs_attr & 16#04000000) <> 0;
  end
  else
    r := false;
  if r then
    home := isc_solution_ptr_t(isc_$get_home_solution(s));
  if isc_user_routines_356 or isc_user_routines_354 then begin
    write('====>>>> isc_$is_a_register_candidate(');
    write(il_node_to_string(s));
    write('): returns: ');
    write(r:1);
    write('.');
    writeln;
    if r then begin
      write('====>>>> isc_$is_a_register_candidate(');
      write(il_node_to_string(s));
      write('): home^.kind = ');
      write(solution$t(home^.kind):1);
    end
    else begin
      write('====>>>> isc_$is_a_register_candidate(');
      write(il_node_to_string(s));
      write('): home^.kind = ');
      write('meaningless');
    end;
    write('.');
    writeln;
    writeln;
  end;
  isc_$is_a_register_candidate := r;
end;

{ is_a_register_solution - whether sol is a register's (kinds 8..11).

  0x2133F4, 0x36 bytes: sol 8; the kinds' mask 16#F00. }

function is_a_register_solution;
begin
  if sol = nil then
    is_a_register_solution := false
  else
    is_a_register_solution := solution$t(sol^.kind)
        in [solution$fp_reg, solution$fp_reg_pair, solution$fp_reg_quad,
            solution$ip_reg];
end;

{ ip_reg_to_ip_reg_scaled - a copy (from the ISC heap) of the integer
  register's solution sol as a scaled one (kind 13) shifted by shift.

  0x21342A, 0x38 bytes: sol 8, shift a word at 12 (stored as the byte
  +79); A0. }

function ip_reg_to_ip_reg_scaled;
var
  d: isc_solution_ptr_t;
begin
  d := duplicate_solution(isc_heap, sol);
  d^.kind := 13;
  d^.f76.scale := shift;
  ip_reg_to_ip_reg_scaled := d;
end;

{ ip_reg_scaled_to_ip_reg - a copy of the scaled register's solution
  sol as a plain integer register (kind 11, shift 0).

  0x213462, 0x2E bytes: sol 8; A0. }

function ip_reg_scaled_to_ip_reg;
var
  d: isc_solution_ptr_t;
begin
  d := duplicate_solution(isc_heap, sol);
  d^.kind := 11;
  d^.f76.scale := 0;
  ip_reg_scaled_to_ip_reg := d;
end;

{ high_half_of_fp_reg_pair - a copy of the floating pair's solution sol
  (given a pair live range first if it has none) as its high half
  (kind 2); nil for nil.

  0x213490, 0x4C bytes: sol 8; A0. }

function high_half_of_fp_reg_pair;
var
  d: isc_solution_ptr_t;
begin
  if sol = nil then
    d := nil
  else begin
    if sol^.live_range = nil then
      sol^.live_range := lir_$new_live_range_fp_reg_pair;
    d := duplicate_solution(isc_heap, sol);
    d^.kind := 2;
  end;
  high_half_of_fp_reg_pair := d;
end;

{ low_half_of_fp_reg_pair - likewise its low half (kind 3), with the
  pair's mate live range and that live range's physical, no_modify,
  serialize and register.

  0x2134DC, 0xB8 bytes: sol 8; the three flags copied bit by bit into
  +83 (`smi'/`sne', `lsr.b #7', shifted, `andi.b', `or.b'); A0. }

function low_half_of_fp_reg_pair;
var
  d: isc_solution_ptr_t;
begin
  if sol = nil then
    d := nil
  else begin
    if sol^.live_range = nil then
      sol^.live_range := lir_$new_live_range_fp_reg_pair;
    d := duplicate_solution(isc_heap, sol);
    d^.kind := 3;
    d^.live_range := sol^.live_range^.mate;
    d^.f76.physical_register := d^.live_range^.f2.physical;
    d^.f76.physical_register_is_no_modify := d^.live_range^.f2.no_modify;
    d^.f76.physical_register_user_declared := d^.live_range^.f2.serialize;
    d^.f76.physical_register_number := d^.live_range^.f2.reg;
  end;
  low_half_of_fp_reg_pair := d;
end;

{ high_half_of_fp_reg_quad - a copy of the floating quad's solution sol
  as its high pair (kind 9); nil for nil.

  0x213594, 0x3C bytes: sol 8; A0. }

function high_half_of_fp_reg_quad;
var
  d: isc_solution_ptr_t;
begin
  if sol = nil then
    d := nil
  else begin
    d := duplicate_solution(isc_heap, sol);
    d^.kind := 9;
  end;
  high_half_of_fp_reg_quad := d;
end;

{ low_half_of_fp_reg_quad - a copy (from the compilation's heap) of the
  floating quad's solution sol as its low pair (kind 9), whose live
  range is sol's second (+24, made if missing), with that live range's
  flags and register.

  0x2135D0, 0xBE bytes: sol 8; A0.  For a nil sol the copy is nil but
  the routine goes on to read sol's +24 and write the copy's fields
  (the nil test guards only the copy); kept as the image has it. }

function low_half_of_fp_reg_quad;
var
  d: isc_solution_ptr_t;
begin
  if sol = nil then
    d := nil
  else begin
    d := duplicate_solution(isc_user_routines_20c, sol);
    d^.kind := 9;
  end;
  if sol^.live_range_of_imaginary_part = nil then
    sol^.live_range_of_imaginary_part := lir_$new_live_range_fp_reg_pair;
  d^.live_range := sol^.live_range_of_imaginary_part;
  d^.f76.physical_register := d^.live_range^.f2.physical;
  d^.f76.physical_register_is_no_modify := d^.live_range^.f2.no_modify;
  d^.f76.physical_register_user_declared := d^.live_range^.f2.serialize;
  d^.f76.physical_register_number := d^.live_range^.f2.reg;
  low_half_of_fp_reg_quad := d;
end;

{ address_mode_for_expression_temporary - an address mode (kind 5) of
  the temporary sym in the frame (base +0x340, no index, displacement
  0 from the symbol), under new attributes of precision bits, with the
  known and trusted bits given.

  0x21368E, 0x8A bytes: sym 8, precision 12, known 16, trusted 20;
  il_kind 176; uses_the_base_register and uses_the_displacement set
  (`ori.b #-64'), uses_the_index_register cleared; A0. }

function address_mode_for_expression_temporary;
var
  inh: inherited_attributes_ptr_t;
  s: isc_solution_ptr_t;
begin
  inh := new_inherited_attributes(isc_heap, sym);
  inh^.fetch_precision := precision;
  s := new_solution(isc_heap, 5, 0, inh, sym, 176);
  s^.bits_known := known;
  s^.bits_trusted := trusted;
  s^.f76.has_a_symbolic_displacement := true;
  s^.literal_32_bits_value := 0;
  s^.f76.uses_the_base_register := true;
  s^.f76.uses_the_displacement := true;
  s^.f76.uses_the_index_register := false;
  s^.base_register := lr_ptr_t(isc_user_routines_340);
  s^.index_register := lr_ptr_t(isc_user_routines_31c);
  s^.object_with_name := sym;
  address_mode_for_expression_temporary := s;
end;

{ address_mode_for_single_value - an address mode of the literal pool's
  single real v (rlcontk of v widened: its node the symbol, precision
  32, low two bits trusted zero), from the literal base register.

  0x213718, 0xB4 bytes: v 8 (a single, by value); the widening
  `fpp_$eslv' into (-32,A6), copied to (-8,A6) and passed by address;
  il_kind 93; A0. }

function address_mode_for_single_value;
var
  d: double;
  c: il_$node_ptr_t;
  inh: inherited_attributes_ptr_t;
  s: isc_solution_ptr_t;
begin
  d := v;                              { fpp_$eslv: dpc gap 6 }
  c := rlcontk(d);
  inh := new_inherited_attributes(isc_heap, c);
  inh^.fetch_precision := 32;
  s := new_solution(isc_heap, 5, 0, inh, c, 93);
  s^.bits_known := 0;
  s^.bits_trusted := 3;
  s^.f76.has_a_symbolic_displacement := true;
  s^.literal_32_bits_value := 0;
  s^.f76.uses_the_base_register := true;
  s^.f76.uses_the_displacement := true;
  s^.f76.uses_the_index_register := false;
  s^.base_register := lr_ptr_t(literal_base_register);
  s^.index_register := lr_ptr_t(isc_user_routines_31c);
  s^.object_with_name := c;
  address_mode_for_single_value := s;
end;

{ address_mode_for_double_value - likewise for the double d (dpcontk;
  precision 64, low three bits trusted zero; il_kind 70).

  0x2137CC, 0xAC bytes: d 8 (by address, copied to (-8,A6) first). }

function address_mode_for_double_value;
var
  t: double;
  c: il_$node_ptr_t;
  inh: inherited_attributes_ptr_t;
  s: isc_solution_ptr_t;
begin
  t := d;                              { a double copied: dpc gap 7 }
  c := dpcontk(t);
  inh := new_inherited_attributes(isc_heap, c);
  inh^.fetch_precision := 64;
  s := new_solution(isc_heap, 5, 0, inh, c, 70);
  s^.bits_known := 0;
  s^.bits_trusted := 7;
  s^.f76.has_a_symbolic_displacement := true;
  s^.literal_32_bits_value := 0;
  s^.f76.uses_the_base_register := true;
  s^.f76.uses_the_displacement := true;
  s^.f76.uses_the_index_register := false;
  s^.base_register := lr_ptr_t(literal_base_register);
  s^.index_register := lr_ptr_t(isc_user_routines_31c);
  s^.object_with_name := c;
  address_mode_for_double_value := s;
end;

{ address_mode_for_integer32_value - likewise for the integer v
  (smcontk(81, v); precision left at 32; bits_known_of_fetched_value
  v, bits_trusted_of_fetched_value -1, bytes 4; il_kind 78).

  0x213878, 0xAA bytes: v 8; A0. }

function address_mode_for_integer32_value;
var
  c: il_$node_ptr_t;
  inh: inherited_attributes_ptr_t;
  s: isc_solution_ptr_t;
begin
  c := smcontk(81, v);
  inh := new_inherited_attributes(isc_heap, c);
  s := new_solution(isc_heap, 5, 0, inh, c, 78);
  s^.bits_known := 0;
  s^.bits_trusted := 3;
  s^.bits_known_of_fetched_value := v;
  s^.bits_trusted_of_fetched_value := -1;
  s^.bytes := 4;
  s^.f76.has_a_symbolic_displacement := true;
  s^.literal_32_bits_value := 0;
  s^.f76.uses_the_base_register := true;
  s^.f76.uses_the_displacement := true;
  s^.f76.uses_the_index_register := false;
  s^.base_register := lr_ptr_t(literal_base_register);
  s^.index_register := lr_ptr_t(isc_user_routines_31c);
  s^.object_with_name := c;
  address_mode_for_integer32_value := s;
end;

{ compute_number_loaded_bytes - the loads (1..4) an access of n bytes
  takes at an address whose low bits known and trusted give its
  alignment (8, 4, 2 or 1 bytes): 1 for one byte or within the
  alignment, 2 within 8 more bytes, 3 within 16 more, else 4.

  0x213922, 0x9C bytes: n 8, known 12, trusted 16. }

function compute_number_loaded_bytes;
var
  a: integer32;
begin
  if n = 1 then
    compute_number_loaded_bytes := 1
  else begin
    if ((known & 7) = 0) and ((trusted & 7) = 7) then
      a := 3
    else if ((known & 3) = 0) and ((trusted & 3) = 3) then
      a := 2
    else if not odd(known) and odd(trusted) then
      a := 1
    else
      a := 0;
    a := lshft(1, a);
    if n <= a then
      compute_number_loaded_bytes := 1
    else if n <= a + 8 then
      compute_number_loaded_bytes := 2
    else if n <= a + 16 then
      compute_number_loaded_bytes := 3
    else
      compute_number_loaded_bytes := 4;
  end;
end;

{ create_solution_for_address_mode, _ip_reg, _ip_reg_scaled, _fp_reg,
  _fp_reg_pair, _fp_reg_quad - a new solution of kind 5, 11, 13 (shift
  0), 8, 9, 10 from the ISC heap, with no children, attributes or
  symbol.

  0x2139BE, 0x213A2A, 0x213A58, 0x213A8A, 0x213B62, 0x213C3A: no
  parameters; A0. }

function create_solution_for_address_mode;
begin
  create_solution_for_address_mode := new_solution(isc_heap, 5, 0, nil, nil, 0);
end;

{ create_solution_for_case_jump_base - a case jump's base (kind 1),
  +12 the case node's +52.

  0x2139EC, 0x3E bytes: node 8; A0. }

function create_solution_for_case_jump_base;
var
  s: isc_solution_ptr_t;
begin
  s := new_solution(isc_heap, 1, 0, nil, nil, 0);
  s^.l12 := node^.xl[13];
  create_solution_for_case_jump_base := s;
end;

function create_solution_for_ip_reg;
begin
  create_solution_for_ip_reg := new_solution(isc_heap, 11, 0, nil, nil, 0);
end;

function create_solution_for_ip_reg_scaled;
var
  s: isc_solution_ptr_t;
begin
  s := new_solution(isc_heap, 13, 0, nil, nil, 0);
  s^.f76.scale := 0;
  create_solution_for_ip_reg_scaled := s;
end;

function create_solution_for_fp_reg;
begin
  create_solution_for_fp_reg := new_solution(isc_heap, 8, 0, nil, nil, 0);
end;

{ create_solution_for_fp_reg_physical - a floating register's solution
  in the physical register r: its live range lir_3f90[r], with that
  live range's physical, no_modify, serialize and register.

  0x213AB8, 0xAA bytes: r a word at 8; A0. }

function create_solution_for_fp_reg_physical;
var
  s: isc_solution_ptr_t;
begin
  s := new_solution(isc_heap, 8, 0, nil, nil, 0);
  s^.live_range := lir_3f90[r];
  s^.f76.physical_register := s^.live_range^.f2.physical;
  s^.f76.physical_register_is_no_modify := s^.live_range^.f2.no_modify;
  s^.f76.physical_register_user_declared := s^.live_range^.f2.serialize;
  s^.f76.physical_register_number := s^.live_range^.f2.reg;
  create_solution_for_fp_reg_physical := s;
end;

function create_solution_for_fp_reg_pair;
begin
  create_solution_for_fp_reg_pair := new_solution(isc_heap, 9, 0, nil, nil, 0);
end;

{ create_solution_for_fp_reg_pair_physical - likewise a pair's (kind
  9) in the physical register r.

  0x213B90, 0xAA bytes: r a word at 8; A0. }

function create_solution_for_fp_reg_pair_physical;
var
  s: isc_solution_ptr_t;
begin
  s := new_solution(isc_heap, 9, 0, nil, nil, 0);
  s^.live_range := lir_3f90[r];
  s^.f76.physical_register := s^.live_range^.f2.physical;
  s^.f76.physical_register_is_no_modify := s^.live_range^.f2.no_modify;
  s^.f76.physical_register_user_declared := s^.live_range^.f2.serialize;
  s^.f76.physical_register_number := s^.live_range^.f2.reg;
  create_solution_for_fp_reg_pair_physical := s;
end;

function create_solution_for_fp_reg_quad;
begin
  create_solution_for_fp_reg_quad := new_solution(isc_heap, 10, 0, nil, nil, 0);
end;

{ create_solution_for_literal_32_bits - a literal solution (kind 14) of
  v (disp).

  0x213C68, 0x3C bytes: v 8; A0. }

function create_solution_for_literal_32_bits;
var
  s: isc_solution_ptr_t;
begin
  s := new_solution(isc_heap, 14, 0, nil, nil, 0);
  s^.literal_32_bits_value := v;
  create_solution_for_literal_32_bits := s;
end;

{ duplicate_address_mode - a new address mode's solution, a copy of
  sol.

  0x213CA4, 0x3A bytes: sol 8; the 432 bytes copied by a `dbf' loop
  of 27 times four longwords; A0. }

function duplicate_address_mode;
var
  d: isc_solution_ptr_t;
begin
  d := create_solution_for_address_mode;
  d^ := sol^;
  duplicate_address_mode := d;
end;

{ duplicate_address_mode_adding_byte_offset - sol itself for offset 0,
  else a copy displaced by offset (bits_known and
  literal_32_bits_value; uses_the_displacement set when the
  displacement is not zero).

  0x213CDE, 0x44 bytes: sol 8, offset 12; A0. }

function duplicate_address_mode_adding_byte_offset;
var
  d: isc_solution_ptr_t;
begin
  if offset = 0 then
    d := sol
  else begin
    d := duplicate_address_mode(sol);
    d^.bits_known := d^.bits_known + offset;
    d^.literal_32_bits_value := d^.literal_32_bits_value + offset;
    if d^.literal_32_bits_value <> 0 then
      d^.f76.uses_the_displacement := true;
  end;
  duplicate_address_mode_adding_byte_offset := d;
end;

{ isc_$get_home_solution - the home solution of a variable (+60) or a
  FORTRAN symbol (+36), made first; of a CSE (its parent's chosen
  solution, +24, reached from a use), bug_check'ed when it has none;
  nil for another node.

  0x213D22, 0x82 bytes: sym 8; A0. }

function isc_$get_home_solution;
var
  s: isc_node_ptr_t;
  h: isc_solution_ptr_t;
begin
  s := sym;
  if s^.kind = 109 then begin
    isc_$initialize_symbol(s);
    h := s^.vn_home;
  end
  else if s^.kind = 110 then begin
    isc_$initialize_symbol(s);
    h := s^.fs_home;
  end
  else if (s^.kind = 190) or (s^.kind = 189) then begin
    if s^.kind = 189 then
      s := map_cse_use_ob_to_cse_parent_ob(s);
    h := s^.cp_chosen_solution;
    if h = nil then
      bug_check('ISC: isc_$get_home_solution: il^.cse_parent^.home_solution = nil.%$');
  end
  else
    h := nil;
  isc_$get_home_solution := solution_ptr_t(h);
end;

{ isc_$get_memory_home - the memory home of sym for an access of bits
  bits as a kind node (122 integral: 32 bits; 123 real): for a CSE
  without a solution a new temporary; for a symbol with a live range
  that live range's memory home (a new temporary on first use, shared
  with its mate); else sym itself when a variable or FORTRAN symbol of
  32 bits or more not in phase 20; nil otherwise.

  0x213DE8, 0xCE bytes: sym 8, kind a word at 12, bits 14; the
  temporary's size in (-12,A6); getphase's bit 20 (`btst #20'). }

function isc_$get_memory_home;
var
  s: isc_node_ptr_t;
  lr: lr_ptr_t;
  b: integer32;
begin
  if kind = 122 then
    b := 32
  else
    b := bits;
  s := sym;
  if s^.kind = 189 then
    s := map_cse_use_ob_to_cse_parent_ob(s);
  if (s^.kind = 190) and (s^.cp_chosen_solution = nil) then begin
    isc_$get_memory_home := make_expression_temporary(kind, b);
    return;
  end;
  lr := isc_$get_il_live_range(s);
  if lr <> nil then begin
    if lr^.memory_home = nil then begin
      lr^.memory_home := make_expression_temporary(kind, b);
      if lr^.mate <> nil then
        lr^.mate^.memory_home := lr^.memory_home;
    end;
    isc_$get_memory_home := lr^.memory_home;
  end
  else if ((s^.kind = 109) or (s^.kind = 110)) and (bits >= 32)
          and not (20 in getphase(s)) then
    isc_$get_memory_home := s
  else
    isc_$get_memory_home := nil;
end;

{ isc_$get_il_live_range - the live range of node: a symbol's or CSE's
  home solution's (made on first use by the home's kind and given node,
  bug_check'ed for another kind or none; nil without a home); a
  physical register's (203, or a tree of op 31: class 0 lir_4090, 1 and
  2 lir_3f90 by number; +4 and +6 words, a tree's bytes +10 and +11);
  the well-known registers' for 211, 154, 155, 229, 153, 226 (+0x33C,
  +0x338, +0x32C, +0x334, +0x340, +0x328); nil otherwise.

  0x213EB6, 0x1B2 bytes: node 8; the home's kind by a jump table over
  8..11; A0. }

function isc_$get_il_live_range;
var
  n: isc_node_ptr_t;
  h: isc_solution_ptr_t;
  lr: lr_ptr_t;
  cls: integer;
  num: integer;
begin
  n := node;
  case n^.kind of
    109, 110, 189, 190: begin
      h := isc_solution_ptr_t(isc_$get_home_solution(n));
      if h = nil then
        lr := nil
      else begin
        lr := h^.live_range;
        if lr = nil then begin
          case h^.kind of
            11: lr := lir_$new_live_range_ip_reg;
            8: lr := lir_$new_live_range_fp_reg;
            9, 10: lr := lir_$new_live_range_fp_reg_pair;
            otherwise
              bug_check('ISC: isc_$get_il_live_range: unknown home_solution^.kind.%$');
          end;
          if lr = nil then
            bug_check('ISC: isc_$get_il_live_range: result = nil.%$');
          lr^.node20 := n;
          h^.live_range := lr;
        end;
      end;
    end;
    203, 137:
      if n^.tr_op <> 31 then
        lr := nil
      else begin
        if n^.kind = 137 then begin
          cls := rshft(il_$node_ptr_t(n)^.xw[5], 8) & 16#FF;
          num := il_$node_ptr_t(n)^.xw[5] & 16#FF;
        end
        else begin
          cls := il_$node_ptr_t(n)^.xw[2];
          num := il_$node_ptr_t(n)^.xw[3];
        end;
        case cls of
          0: lr := lir_4090[num];
          2, 1: lr := lir_3f90[num];
          otherwise lr := nil;
        end;
      end;
    211: lr := isc_solution_ptr_t(isc_user_routines_33c)^.live_range;
    154: lr := isc_solution_ptr_t(isc_user_routines_338)^.live_range;
    155: lr := isc_solution_ptr_t(isc_user_routines_32c)^.live_range;
    229: lr := isc_solution_ptr_t(isc_user_routines_334)^.live_range;
    153: lr := isc_solution_ptr_t(isc_user_routines_340)^.live_range;
    226: lr := isc_solution_ptr_t(isc_user_routines_328)^.live_range;
    otherwise lr := nil;
  end;
  isc_$get_il_live_range := lr;
end;

{ get_live_range_assigned, get_live_range_no_modify,
  get_live_range_serialize - the live range's physical (+3 bit 7),
  no_modify (bit 6) and serialize (bit 5) flags; false for nil.
  get_live_range_register - its register (+2; -1 for nil).

  0x2140D0, 0x2140F6, 0x214144, 0x21411E: lr 8; D0. }

function get_live_range_assigned;
begin
  if lr = nil then
    get_live_range_assigned := false
  else
    get_live_range_assigned := lr^.f2.physical;
end;

function get_live_range_no_modify;
begin
  if lr = nil then
    get_live_range_no_modify := false
  else
    get_live_range_no_modify := lr^.f2.no_modify;
end;

function get_live_range_register;
begin
  if lr = nil then
    get_live_range_register := -1
  else
    get_live_range_register := lr^.f2.reg;
end;

function get_live_range_serialize;
begin
  if lr = nil then
    get_live_range_serialize := false
  else
    get_live_range_serialize := lr^.f2.serialize;
end;

{ get_live_range_of_imaginary_part - the second live range (+24) of the
  home solution of a FORTRAN symbol or CSE (a complex value's
  imaginary part), made on first use as isc_$get_il_live_range makes
  the first; nil for another node (a variable included).

  0x21416C, 0xAE bytes: node 8; A0. }

function get_live_range_of_imaginary_part;
var
  h: isc_solution_ptr_t;
  lr: lr_ptr_t;
begin
  if (node^.kind = 110) or (node^.kind = 189) or (node^.kind = 190) then begin
    h := isc_solution_ptr_t(isc_$get_home_solution(node));
    lr := h^.live_range_of_imaginary_part;
    if lr = nil then begin
      case h^.kind of
        11: lr := lir_$new_live_range_ip_reg;
        8: lr := lir_$new_live_range_fp_reg;
        9, 10: lr := lir_$new_live_range_fp_reg_pair;
        otherwise
          bug_check('ISC: get_live_range_of_imaginary_part: unknown home_solution^.kind.%$');
      end;
      if lr = nil then
        bug_check('ISC: get_live_range_of_imaginary_part: result = nil.%$');
      lr^.node20 := node;
      h^.live_range_of_imaginary_part := lr;
    end;
  end
  else
    lr := nil;
  get_live_range_of_imaginary_part := lr;
end;

{ isc_$init_well_known_ip_reg - the solution of a well-known integer
  register named name (two or three characters: an identifier node,
  kind 76, from the compilation's heap), the home of a variable made
  for it (kind 109, integral type +0x34C, vat 2, 32 bits, its +4 the
  identifier) by initialize_well_known_symbol; physical in register k
  when k >= 0 (-1 for a symbolic register).

  0x214296, 0xBA bytes: name by address at 8 (its third character
  compared with a blank), k 12; the identifier's 10 bytes at +2 from a
  template after the code (0x214350: kind 76, the rest zero), its
  length at +16 and characters at +18; A0. }

function isc_$init_well_known_ip_reg;
var
  len: integer;
  id: il_$node_ptr_t;
  v: isc_node_ptr_t;
  h: isc_solution_ptr_t;
begin
  if name[3] = ' ' then
    len := 2
  else
    len := 3;
  id := mrh_$alloc(isc_user_routines_20c, 22);
  id^.kind := 76;
  id^.idnt_next := nil;
  id^.idnt_unused_8 := 0;
  id^.idnt_len := len;
  id^.idnt_name[1] := name[1];
  id^.idnt_name[2] := name[2];
  id^.idnt_name[3] := name[3];
  v := mrh_$alloc(isc_user_routines_20c, 84);
  v^.kind := 109;
  v^.vn_p4 := isc_node_ptr_t(id);
  v^.vn_type := isc_user_routines_34c;
  v^.vn_vat := 2;
  v^.vn_bits := 32;
  initialize_well_known_symbol(v, true);
  h := v^.vn_home;
  if k >= 0 then begin
    h^.f76.physical_register := true;
    h^.f76.physical_register_number := k;
  end;
  isc_$init_well_known_ip_reg := solution_ptr_t(h);
end;

{ isc_$init_well_known_fp_reg - likewise a floating register's (the
  single real type +0x348, 32 bits).

  0x21435A, 0xBA bytes. }

function isc_$init_well_known_fp_reg;
var
  len: integer;
  id: il_$node_ptr_t;
  v: isc_node_ptr_t;
  h: isc_solution_ptr_t;
begin
  if name[3] = ' ' then
    len := 2
  else
    len := 3;
  id := mrh_$alloc(isc_user_routines_20c, 22);
  id^.kind := 76;
  id^.idnt_next := nil;
  id^.idnt_unused_8 := 0;
  id^.idnt_len := len;
  id^.idnt_name[1] := name[1];
  id^.idnt_name[2] := name[2];
  id^.idnt_name[3] := name[3];
  v := mrh_$alloc(isc_user_routines_20c, 84);
  v^.kind := 109;
  v^.vn_p4 := isc_node_ptr_t(id);
  v^.vn_type := isc_user_routines_348;
  v^.vn_vat := 2;
  v^.vn_bits := 32;
  initialize_well_known_symbol(v, true);
  h := v^.vn_home;
  if k >= 0 then begin
    h^.f76.physical_register := true;
    h^.f76.physical_register_number := k;
  end;
  isc_$init_well_known_fp_reg := solution_ptr_t(h);
end;

{ isc_$init_well_known_fp_reg_pair - likewise an even floating
  register's pair (the double type +0x344, 64 bits).

  0x214414, 0xBA bytes. }

function isc_$init_well_known_fp_reg_pair;
var
  len: integer;
  id: il_$node_ptr_t;
  v: isc_node_ptr_t;
  h: isc_solution_ptr_t;
begin
  if name[3] = ' ' then
    len := 2
  else
    len := 3;
  id := mrh_$alloc(isc_user_routines_20c, 22);
  id^.kind := 76;
  id^.idnt_next := nil;
  id^.idnt_unused_8 := 0;
  id^.idnt_len := len;
  id^.idnt_name[1] := name[1];
  id^.idnt_name[2] := name[2];
  id^.idnt_name[3] := name[3];
  v := mrh_$alloc(isc_user_routines_20c, 84);
  v^.kind := 109;
  v^.vn_p4 := isc_node_ptr_t(id);
  v^.vn_type := isc_user_routines_344;
  v^.vn_vat := 2;
  v^.vn_bits := 64;
  initialize_well_known_symbol(v, true);
  h := v^.vn_home;
  if k >= 0 then begin
    h^.f76.physical_register := true;
    h^.f76.physical_register_number := k;
  end;
  isc_$init_well_known_fp_reg_pair := solution_ptr_t(h);
end;

{ il_kind_function - node's kind (what the pattern matcher dispatches
  on).

  0x2144CE, 0x1C bytes: node 8; a word in D0. }

function il_kind_function;
begin
  il_kind_function := node^.kind;
end;

{ make_expression_temporary - a new temporary variable (kind 109, from
  the compilation's heap, in il_180's block) of the type node kind
  (122 integral: the integral type +0x34C; else by bits the single or
  double type, +0x348 or +0x344) and size bits: vat 2, attributes
  16#404000, alignment 2 (3 above 32 bits), numbered by the
  temporaries' count (isc_user_routines_310, counted first; its low
  halfword).

  0x2144EA, 0xAE bytes: kind a word at 8, bits 10; the kind and +4
  stored as one longword (`move.l #16#6D0000,(2,A0)'), +6 cleared; A0. }

function make_expression_temporary;
var
  t: isc_node_ptr_t;
  v: isc_node_ptr_t;
begin
  isc_user_routines_310 := isc_user_routines_310 + 1;
  if kind = 122 then
    t := isc_user_routines_34c
  else if bits = 32 then
    t := isc_user_routines_348
  else
    t := isc_user_routines_344;
  v := mrh_$alloc(isc_user_routines_20c, 84);
  v^.kind := 109;
  v^.vn_p4 := nil;
  v^.vn_block := il_180;
  v^.vn_type := t;
  v^.vn_vat := 2;
  v^.vn_attr := 16#404000;
  v^.vn_bits := bits;
  if bits > 32 then
    v^.vn_align := 3
  else
    v^.vn_align := 2;
  v^.vn_serial := isc_user_routines_310;
  make_expression_temporary := v;
end;

{ possibly_make_expression_temporary - a temporary (of type kind tkind
  and bits) when the solution kind skind is a register's (12, 11, 8)
  or an integral value wider than 32 bits is wanted; nil otherwise.

  0x214598, 0x56 bytes: skind a word at 8, tkind a word at 10, bits
  12; A0. }

function possibly_make_expression_temporary;
begin
  if ((tkind = 122) and (bits > 32)) or (skind = 12) or (skind = 11)
     or (skind = 8) then
    possibly_make_expression_temporary := make_expression_temporary(tkind, bits)
  else
    possibly_make_expression_temporary := nil;
end;

{ verify_bits - whether the field of width bits at bit position, all
  trusted, holds expected (0: all zero, 1: all one) in known; true
  (with a note under the traces) for width 0 or a negative position, a
  right-justified object; other invalid arguments reported or
  bug_check'ed (false).

  0x2145EE, 0x24C bytes: known 8, trusted 12, position 16, width 20,
  expected 24 (the last three written by address); the three ranges'
  tests `and.b'-ed into (-14,A6). }

function verify_bits;
var
  m: integer32;
  ok: boolean;
begin
  ok := is_in_range(width, 1, 32);
  ok := is_in_range(position, 0, 31) and ok;
  if is_in_range(expected, 0, 1) and ok then begin
    known := known & trusted;
    m := make_bit_mask_1(width, position);
    if (trusted & m) <> m then
      verify_bits := false
    else
      verify_bits := ((expected = 0) and ((known & m) = 0))
                     or ((expected = 1) and ((known & m) = m));
  end
  else if (width = 0) or (position < 0) then begin
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: verify_bits: field_width = ');
      write(width:1);
      write(', bit_position = ');
      write(position:1);
      write('; I assume this means the object is right-justified.');
      writeln;
    end;
    verify_bits := true;
  end
  else begin
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: verify_bits: bit_position = ');
      write(position:1);
      write(' and field_width = ');
      write(width:1);
      write(' and expected_value = ');
      write(expected:1);
      write('.');
      writeln;
    end
    else
      bug_check('ISC: verify_bits has invalid arguments.%$');
    verify_bits := false;
  end;
end;

{ verify_any_bits - whether some bit of the field (width bits at bit
  position) is trusted and equal to expected in known: each bit's mask
  a halfword (`lsl.w': a bit above 15 is lost) and compared, masked,
  with expected itself; false when no bit is trusted.  Invalid
  arguments as verify_bits'.

  0x214916, 0x268 bytes: as verify_bits; the result in (-14,A6), the
  loop `dbf' over width - 1 .. 0 with the bit's index in D3 from 1. }

function verify_any_bits;
var
  m: integer32;
  b: integer32;
  i: integer;
  ok: boolean;
  r: boolean;
begin
  ok := is_in_range(width, 1, 32);
  ok := is_in_range(position, 0, 31) and ok;
  if is_in_range(expected, 0, 1) and ok then begin
    m := make_bit_mask_1(width, position);
    if (trusted & m) = 0 then
      r := false
    else begin
      r := false;
      for i := 1 to width do begin
        b := lshft(1, i + position - 1) & 16#FFFF;
        if ((b & trusted) <> 0) and ((b & known) = expected) then
          r := true;
      end;
    end;
  end
  else if (width = 0) or (position < 0) then begin
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: verify_any_bits: field_width = ');
      write(width:1);
      write(', bit_position = ');
      write(position:1);
      write('; I assume this means the object is right-justified.');
      writeln;
    end;
    r := true;
  end
  else begin
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: verify_any_bits: bit_position = ');
      write(position:1);
      write(' and field_width = ');
      write(width:1);
      write(' and expected_value = ');
      write(expected:1);
      write('.');
      writeln;
    end
    else
      bug_check('ISC: verify_any_bits has invalid arguments.%$');
    r := false;
  end;
  verify_any_bits := r;
end;

{ isc_$precision_from_rlen_and_size - the bits of a value of register
  class rlen (isc_readonly_tables' rlen_bits; -2 there: by size, 8
  bits a byte, 32 for a negative size).

  0x214BF6, 0x48 bytes: rlen a word at 8, size 10; `move.l (372,A1)'
  of 0x2BCDFC + 4 * rlen. }

function isc_$precision_from_rlen_and_size;
var
  p: integer32;
begin
  p := isc_readonly_tables.rlen_bits[rlen];
  if p = -2 then
    if size >= 0 then
      p := size * 8
    else
      p := 32;
  isc_$precision_from_rlen_and_size := p;
end;

{ return_value_needs_assign_node - whether a value returned into sym
  needs an assignment: false for nil or for sym = dest; for a FORTRAN
  symbol false when it is the result variable (+96) of one of the
  routine's ENTRY blocks (kind 167, chained from il_180 at +4; nested
  function blocks, 108 of level above 0, passed over; the walk stops at
  another kind); true otherwise.

  0x214C3E, 0x8E bytes: sym 8, dest 12; the stop flag in D1. }

function return_value_needs_assign_node;
var
  r: boolean;
  done: boolean;
  n: isc_node_ptr_t;
begin
  if sym = nil then
    r := false
  else if sym = dest then
    r := false
  else if sym^.kind = 110 then begin
    r := true;
    n := isc_node_ptr_t(il_180)^.xp[1];
    repeat
      done := false;
      if n = nil then
        done := true
      else if not ((n^.kind = 108) and (n^.bk_f294.slevel > 0)) then
        if n^.kind <> 167 then
          done := true
        else if n^.xp[24] = sym then begin
          r := false;
          done := true;
        end;
      n := n^.xp[1];
    until done;
  end
  else
    r := true;
  return_value_needs_assign_node := r;
end;

{ rlen_code_from_type_node - the register class code of the type node
  t (through the named, array, pointer-like kinds to their base: 131,
  133, 177, 197, 134, 128 at +4, 234 at +8, 121 at +16, 118 at +28):
  1 for 124 and 125, 2 for 129, 4 for 122, 5 for 130 and 135, 7 for
  123, 0 for 210, 132, 196, 126, 127, 136; another kind reported or
  bug_check'ed (0).

  0x214CCC, 0x248 bytes: t 8; a word in D0. }

function rlen_code_from_type_node;
var
  r: integer;
begin
  case t^.kind of
    131, 133, 177, 197, 134, 128: r := rlen_code_from_type_node(t^.xp[1]);
    234: r := rlen_code_from_type_node(t^.xp[2]);
    121: r := rlen_code_from_type_node(t^.xp[4]);
    118: r := rlen_code_from_type_node(t^.xp[7]);
    124, 125: r := 1;
    129: r := 2;
    122: r := 4;
    130, 135: r := 5;
    123: r := 7;
    210, 132, 196, 126, 127, 136: r := 0;
    otherwise begin
      write('*******************************************************');
      writeln;
      write('ISC: The illegal IL node kind is: ');
      write(an_kind_t(t^.kind):1);
      write('.');
      writeln;
      write('*******************************************************');
      writeln;
      if isc_user_routines_356 or isc_user_routines_354 then begin
        write('ISC: rlen_code_from_type_node: illegal IL node kind.');
        writeln;
      end
      else
        bug_check('ISC: rlen_code_from_type_node: illegal IL node kind.%$');
      r := 0;
    end;
  end;
  rlen_code_from_type_node := r;
end;

{ arithmetic_from_il_node - how node's value is computed: by its
  register class (isc_readonly_tables' rlen_w; trees +24, 140 and 151
  +52, 145 +42, 143 +24; a variable's type's class, address for a
  register variable), through a CSE to its tree, address for
  references (146, 147) and aggregate constants (156, 176, 92), integer
  and real for the constants, by class for a FORTRAN symbol (1..3 and
  7..10 integer, 4 and 5 real, 6 and others meaningless), meaningless
  for another kind.  Reported under the traces unless integer, real or
  address.

  0x214F7E, 0x290 bytes: node 8; the result a word (D2); the FORTRAN
  classes by a jump table over 1..10. }

function arithmetic_from_il_node;
var
  n: isc_node_ptr_t;
  a: integer;
begin
  n := node;
  case n^.kind of
    140: a := isc_readonly_tables.rlen_w[n^.xw[26]];
    143: a := isc_readonly_tables.rlen_w[n^.xw[12]];
    190: a := ord(arithmetic_from_il_node(n^.xp[1]));
    189: a := ord(arithmetic_from_il_node(n^.xp[5]));
    145: a := isc_readonly_tables.rlen_w[n^.xw[21]];
    151: a := isc_readonly_tables.rlen_w[n^.xw[26]];
    138, 137: a := isc_readonly_tables.rlen_w[n^.xw[12]];
    146, 147: a := 3;
    156, 176, 92: a := 3;
    78, 83, 80, 79, 85, 82, 84, 81, 87, 77, 86, 200: a := 1;
    88, 89, 198, 90: a := 2;
    109:
      if n^.vn_vat = 5 then
        a := 3
      else
        a := isc_readonly_tables.rlen_w[rlen_code_from_type_node(n^.vn_type)];
    110:
      case n^.fs_f10.cls of
        1, 2, 3, 7, 8, 9, 10: a := 1;
        4, 5: a := 2;
        otherwise a := 4;
      end;
    otherwise a := 4;
  end;
  if (a <> 2) and (a <> 1) and (a <> 3) then
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: arithmetic_from_il_node: il node kind ');
      write(an_kind_t(n^.kind):1);
      write(' has arithmetic ');
      write(arith$t(a):1);
      write('.');
      writeln;
    end;
  arithmetic_from_il_node := arith$t(a);
end;

{ precision_from_il_node - the bits of node's value: from its register
  class and size (isc_$precision_from_rlen_and_size: trees +24 and
  +20, 140 +52 and +48, 143 +24 and +20, 145 +42 and 151 +52 with no
  size), through a CSE to its tree, a pointer's (146) target's, a
  displacement's (147) target's less 8 times its +32; a string or set
  constant's bytes (a halfword) and 176's longword times 8; the
  constants' sizes; a variable's bits (32 in a register); a FORTRAN
  symbol's size (-1 for class 7 with +10 bit 7); -1 for another kind,
  reported under the traces.

  0x21529C, 0x2EC bytes: node 8; D0. }

function precision_from_il_node;
var
  n: isc_node_ptr_t;
  p: integer32;
begin
  n := node;
  case n^.kind of
    140: p := isc_$precision_from_rlen_and_size(n^.xw[26], n^.xl[12]);
    143: p := isc_$precision_from_rlen_and_size(n^.xw[12], n^.xl[5]);
    190: p := precision_from_il_node(n^.xp[1]);
    189: p := precision_from_il_node(n^.xp[5]);
    145: p := isc_$precision_from_rlen_and_size(n^.xw[21], -1);
    151: p := isc_$precision_from_rlen_and_size(n^.xw[26], -1);
    138, 137: p := isc_$precision_from_rlen_and_size(n^.xw[12], n^.xl[5]);
    147: p := precision_from_il_node(n^.xp[6]) - n^.xl[8] * 8;
    146: p := precision_from_il_node(n^.xp[6]);
    92: p := (il_$node_ptr_t(n)^.str_len * 8) & 16#FFFF;
    176: p := n^.xl[2] * 8;
    156: p := (il_$node_ptr_t(n)^.set_len * 8) & 16#FFFF;
    200, 86, 77, 87: p := 8;
    80, 83, 78: p := 16;
    81, 84, 82, 85, 79: p := 32;
    90: p := 64;
    198: p := 128;
    89: p := 64;
    88: p := 32;
    109:
      if n^.vn_vat = 5 then
        p := 32
      else
        p := n^.vn_bits;
    110:
      if (n^.fs_f10.cls = 7) and n^.fs_f10.b7 then
        p := -1
      else
        p := sz_fsym(il_$node_ptr_t(n)) * 8;
    otherwise p := -1;
  end;
  if p = -1 then
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: precision_from_il_node: il node kind ');
      write(an_kind_t(n^.kind):1);
      write(' has precision ');
      write(p:1);
      write('.');
      writeln;
    end;
  precision_from_il_node := p;
end;

{ isc_$get_label - the LIR label of the label symbol node (+80), made
  on first use (lir_$new_label); for a label whose +75 bit 7 is set
  its instruction too (zzzzz_$preallocate_label, the label's +4 and the
  node's +60), numbered by the node's statement index (the
  instruction's halfword +32), and put first in the label's block when
  the label has one (its +10 bit 5); the instruction then marked (+3
  bit 7).

  0x2155C2, 0x9E bytes: node 8; the label's and the instruction's
  fields through ur_label_t and ur_instr_view_t; A0. }

function isc_$get_label;
var
  n: isc_node_ptr_t;
  lab: ur_label_ptr_t;
  instr: ur_instr_view_ptr_t;
  bb: bb_ptr_t;
  first: ur_instr_view_ptr_t;
begin
  n := node;
  lab := ur_label_ptr_t(n^.xp[20]);
  if lab = nil then begin
    lab := lir_$new_label;
    n^.xp[20] := isc_node_ptr_t(lab);
    if (n^.xw[37] & 16#80) <> 0 then begin
      instr := lab^.instr;
      if instr = nil then begin
        instr := ur_instr_view_ptr_t(zzzzz_$preallocate_label);
        lab^.instr := instr;
        n^.xp[15] := isc_node_ptr_t(instr);
        instr^.w32 := rshft(n^.st_l42 & 16#FFFF00, 8);
        if lab^.f10.in_block then begin
          bb := lab^.bb;
          first := ur_instr_view_ptr_t(bb^.first);
          instr^.bb := bb;
          instr^.next := first;
          bb^.first := instr_ptr_t(instr);
          if first = nil then
            bb^.last := instr_ptr_t(instr)
          else
            first^.prev := instr;
        end;
      end;
      instr^.f3.b7 := true;
    end;
  end;
  isc_$get_label := lab;
end;

{ pattern_match_error - a pattern matching failure reported: the IL
  node kind (il$t) between stars, then by pme (the failure) a message
  with the source line: under the traces written, else bug_check'ed;
  the byte-aligned accesses (2 and 3) only written; for an unsupported
  f_math_top (8) its math kind is named first.

  0x215660, 0x89E bytes: pme a word at 8, kind 10 (il$t), math a word
  at 12, line a word at 14 (passed to bug_check by address); jump tables
  over pme 1..15 (6 the default's) and math 0..15. }

procedure pattern_match_error;
var
  trace: boolean;
begin
  write('*******************************************************');
  writeln;
  write('ISC: The IL node kind is: ');
  write(kind:1);
  write('.');
  writeln;
  write('*******************************************************');
  writeln;
  trace := isc_user_routines_356 or isc_user_routines_354;
  case pme of
    1:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': scalar_aop mixes ip_reg and fp_reg.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: scalar_aop mixes ip_reg and fp_reg.%$', line);
    2: begin
      write('ISC: source line ');
      write(line:1);
      write(': Attempt to load or store a byte-aligned longword.');
      writeln;
    end;
    3: begin
      write('ISC: source line ');
      write(line:1);
      write(': Attempt to load or store a byte-aligned word.');
      writeln;
    end;
    4:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': Double-precision floating registers are currently unsupported.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: Double-precision floating registers are currently unsupported.%$', line);
    5:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': FP instruction emitted, but [no_fp] set.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: FP instruction emitted, but [no_fp] set.%$', line);
    7:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': set_sr builtin function is meaningless on the AT.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: set_sr builtin function is meaningless on the AT.%$', line);
    8: begin
      write('**********************************************************');
      writeln;
      write('ISC: The unsupported f_math_top kind is: ');
      case math of
        0: write('abs_math');
        1: write('sin_math');
        2: write('cos_math');
        3: write('tan_math');
        4: write('log_math');
        5: write('log10_math');
        6: write('exp_math');
        7: write('atan_math');
        8: write('atan2_math');
        9: write('sqrt_math');
        10: write('trunc_math');
        11: write('nint_math');
        12: write('max_math');
        13: write('min_math');
        14: write('conjg_math');
        15: write('aimag_math');
        otherwise ;
      end;
      write('.');
      writeln;
      write('**********************************************************');
      writeln;
      if isc_user_routines_356 or isc_user_routines_354 then begin
        write('ISC: source line ');
        write(line:1);
        write(': This flavor of f_math_top is unsupported.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: This flavor of f_math_top is unsupported.%$', line);
    end;
    9:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': This IL node kind is currently unsupported.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: This IL node kind is currently unsupported.%$', line);
    10:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': Attempt to load or store with an invalid precision.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: Attempt to load or store with an invalid precision.%$', line);
    11:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': This compare operator is not supported.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: This compare operator is not supported.%$', line);
    12:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': [ enable / disable / set_sr builtin function ] is meaningless or unsupported on this machine.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: [ enable / disable / set_sr builtin function ] is meaningless or unsupported on this machine.%$', line);
    13:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': processor register is meaningless or unsupported on this machine.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: processor register is meaningless or unsupported on this machine.%$', line);
    14:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': floating point is currently unsupported on this machine.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: floating point is currently unsupported on this machine.%$', line);
    15:
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': Attempt to load or store an unaligned floating point.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: Attempt to load or store an unaligned floating point.%$', line);
    otherwise
      if trace then begin
        write('ISC: source line ');
        write(line:1);
        write(': Unexpected pme$ value.');
        writeln;
      end
      else
        bug_check('ISC: source line %wd: Unexpected pme$ value.%$', line);
  end;
end;

{ pc_relative_literal_size_to_bits_trusted - the alignment mask of a
  literal of n bytes: 0, 1, 3 for up to 1, 2, 4 bytes, else 7.

  0x2166F8, 0x3E bytes: n 8. }

function pc_relative_literal_size_to_bits_trusted;
begin
  if n <= 1 then
    pc_relative_literal_size_to_bits_trusted := 0
  else if n <= 2 then
    pc_relative_literal_size_to_bits_trusted := 1
  else if n <= 4 then
    pc_relative_literal_size_to_bits_trusted := 3
  else
    pc_relative_literal_size_to_bits_trusted := 7;
end;

{ set_isc_is_cse_on_live_range_if_local_cse - lr marked a CSE's (+10
  bit 7) when local.

  0x216736, 0x24 bytes: local a byte at 8, lr 10. }

procedure set_isc_is_cse_on_live_range_if_local_cse;
begin
  if local then
    lr^.f10.isc_is_cse := true;
end;

{ side_effect_set_var_$address_exposed - the variable sym marked
  address-exposed (attributes bit 12, `bset #4,(34,A0)').

  0x21675A, 0x1E bytes: sym 8. }

procedure side_effect_set_var_$address_exposed;
begin
  sym^.vn_attr := sym^.vn_attr ! 16#1000;
end;

{ side_effect_fortran_symbol_fill_in_size - a FORTRAN symbol's class
  set from its size in bits (8: 7, 16: 2, 32: 3, 64: 5; another size
  bug_check'ed); true.

  0x216778, 0x8A bytes: sym 8 and size 12 by address; the class the
  low nibble of +10. }

function side_effect_fortran_symbol_fill_in_size;
var
  s: isc_node_ptr_t;
begin
  s := sym;
  case size of
    8: s^.fs_f10.cls := 7;
    16: s^.fs_f10.cls := 2;
    32: s^.fs_f10.cls := 3;
    64: s^.fs_f10.cls := 5;
    otherwise
      bug_check('ISC: side_effect_fortran_symbol_fill_in_size: unrecognized size.%$');
  end;
  side_effect_fortran_symbol_fill_in_size := true;
end;

{ side_effect_var_name_fill_in_size - a variable's size in bits set;
  true.

  0x216844, 0x26 bytes: sym 8 and size 12 by address. }

function side_effect_var_name_fill_in_size;
var
  s: isc_node_ptr_t;
begin
  s := sym;
  s^.vn_bits := size;
  side_effect_var_name_fill_in_size := true;
end;

{ side_effect_symbol_fill_in_size - either, by sym's kind.

  0x21686A, 0x3E bytes: sym 8, size 12, passed on by address. }

function side_effect_symbol_fill_in_size;
begin
  if sym^.kind = 109 then
    side_effect_symbol_fill_in_size := side_effect_var_name_fill_in_size(sym, size)
  else
    side_effect_symbol_fill_in_size := side_effect_fortran_symbol_fill_in_size(sym, size);
end;

{ is_power_of_2 - whether x is one of the module's powers of two
  (ur_powers, +0x0: 2 ** 0 .. 2 ** 31).

  0x2168A8, 0x30 bytes: x 8; the table walked from A5 (`movea.l A5,A0;
  cmp.l (A0),D2'), all 32 compared. }

function is_power_of_2;
var
  r: boolean;
  i: integer;
begin
  r := false;
  for i := 0 to 31 do
    if x = ur_powers[i] then
      r := true;
  is_power_of_2 := r;
end;

{ invertible_in_sp, invertible_in_dp - a double constant's (89) flags
  +20 and +21 (exact as a single, in a single's range: il.ins.pas's
  names); false for nil.  For another kind the result is not set.

  0x2168D8, 0x216906, 0x2E bytes each: node 8; D0. }

function invertible_in_sp;
begin
  if node = nil then
    invertible_in_sp := false
  else if node^.kind = 89 then
    invertible_in_sp := node^.real_single_exact;
end;

function invertible_in_dp;
begin
  if node = nil then
    invertible_in_dp := false
  else if node^.kind = 89 then
    invertible_in_dp := node^.real_single_range;
end;

{ log_2 - the index of x among the powers of two (the result is not
  set when x is none of them).

  0x216934, 0x3A bytes: x 8; all 32 compared. }

function log_2;
var
  n: integer32;
  i: integer32;
begin
  for i := 0 to 31 do
    if x = ur_powers[i] then
      n := i;
  log_2 := n;
end;

{ warning_unaligned_atomic_access - an unaligned atomic access at
  source line line: written under the traces, else the front end's
  error 51 (cgerr).

  0x21696E, 0x8C bytes: line a word at 8 (written by address). }

procedure warning_unaligned_atomic_access;
begin
  if isc_user_routines_356 or isc_user_routines_354 then begin
    write('ISC: source line ');
    write(line:1);
    write(': Warning: Unaligned atomic access.');
    writeln;
  end
  else
    cgerr(51, line, nil);
end;

{ widen_char_string_ob - a string constant of fewer than 4 characters
  widened to 4 (NULs after its characters: a new strtk node); the node
  itself otherwise.

  0x216A1E, 0x5E bytes: node 8; the four bytes from a zero constant
  after the code (0x216A7C); A0 (node, when no new one is made). }

function widen_char_string_ob;
var
  buf: array [1..4] of char;
  i: integer;
  r: il_$node_ptr_t;
begin
  r := node;
  if node^.str_len < 4 then begin
    buf[1] := chr(0);
    buf[2] := chr(0);
    buf[3] := chr(0);
    buf[4] := chr(0);
    for i := 1 to node^.str_len do
      buf[i] := node^.str_chars[i];
    r := strtk(buf, 4);
  end;
  widen_char_string_ob := r;
end;

{ expression_has_side_effects - whether node may have side effects:
  through a displacement (147), symbolic displacement (205) or pointer
  (146) to its base (+24), through a dindex (145) to its base or index
  (+36); otherwise true (the image tests the reference kinds' set
  (is_device's) and kinds 110 and 109, every path ending in `st').

  0x216A80, 0x84 bytes: node 8; D0. }

function expression_has_side_effects;
var
  r: boolean;
begin
  if (node^.kind = 147) or (node^.kind = 205) or (node^.kind = 146) then
    r := expression_has_side_effects(node^.xp[6])
  else if node^.kind = 145 then begin
    r := expression_has_side_effects(node^.xp[6]);
    r := expression_has_side_effects(node^.xp[9]) or r;
  end
  else if node^.kind in [137, 138, 143, 145, 146, 147, 164, 171, 175, 189, 205] then
    r := true
  else if node^.kind = 110 then
    r := true
  else if node^.kind = 109 then
    r := true
  else
    r := true;
  expression_has_side_effects := r;
end;

{ process_eval_node - each child of the EVAL_NODE eval (+50 of them,
  from +52) that may have side effects given to the ISC as a statement
  of its own (isc_$process_statement), under new attributes: the
  eval's top (+12) and line (+20) and index (+43..+44), parent's
  statement (+12), the child's arithmetic and precision (32 unless a
  positive precision of up to 32 bits, a real of 64 or 128, or an
  address); a child without them reported under the traces.

  0x216B04, 0x1D2 bytes: eval 8, parent 12; the child in (-12,A6). }

procedure process_eval_node;
var
  i: integer;
  c: isc_node_ptr_t;
  a: arith$t;
  p: integer32;
  inh: inherited_attributes_ptr_t;
begin
  for i := 1 to eval^.xw[25] do begin
    c := eval^.xp[i + 12];
    if expression_has_side_effects(c) then begin
      a := arithmetic_from_il_node(c);
      p := precision_from_il_node(c);
      if p <= 0 then
        p := 32
      else if p > 32 then
        if not (((a = arith_real) and ((p = 64) or (p = 128)))
                or (a = arith_address)) then
          p := 32;
      inh := new_inherited_attributes(isc_heap, c);
      inh^.exception_frame := eval^.xp[3];
      inh^.fetch_precision := p;
      inh^.original_il := parent^.xp[3];
      inh^.f38.required_arithmetic := ord(arithmetic_from_il_node(c));
      inh^.required_precision := p;
      inh^.pos.source_line_number := eval^.xw[10];
      inh^.pos.stmt_number := rshft(eval^.st_l42 & 16#FFFF00, 8);
      isc_$process_statement(c, inh);
    end
    else if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: process_eval_node: source line ');
      write(eval^.xw[10]:1);
      write(', child #');
      write(i:1);
      write(', IL node ');
      write(il_node_to_string(c));
      write(', is presumed to have no side-effects.');
      writeln;
    end;
  end;
end;

{ value_top_over - a new VALUE_TOP tree (137, op 17; from the ISC heap)
  over node, of register class rlen and size.

  0x216D34, 0x5A bytes: node 8, rlen a word at 12, size 14; +4
  16#400000, the opmods cleared as one longword; A0. }

function value_top_over;
var
  t: isc_node_ptr_t;
begin
  t := mrh_$alloc(isc_heap, 44);
  t^.kind := 137;
  t^.tr_op := 17;
  t^.tr_opmod1 := 0;
  t^.tr_opmod2 := 0;
  t^.tr_rlen := rlen;
  t^.tr_size := size;
  t^.tr_l4 := 16#400000;
  t^.tr_opnd[1] := node;
  value_top_over := t;
end;

{ validate_shift_count - n when it is a shift count (0..31); else
  reported or bug_check'ed, and 0.

  0x216D8E, 0xB0 bytes: n 8 (written by address). }

function validate_shift_count;
begin
  if is_in_range(n, 0, 31) then
    validate_shift_count := n
  else begin
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('ISC: validate_shift_count(');
      write(n:1);
      write(').');
      writeln;
    end
    else
      bug_check('ISC: validate_shift_count has invalid arguments.%$');
    validate_shift_count := 0;
  end;
end;

{ solution_kind_of_symbol - the kind of sym's home solution (0 when sym
  is not a register candidate or has none).

  0x216E8A, 0x3E bytes: sym 8; a word in D0. }

function solution_kind_of_symbol;
var
  k: integer;
  h: isc_solution_ptr_t;
begin
  k := 0;
  if isc_$is_a_register_candidate(sym) then begin
    h := isc_solution_ptr_t(isc_$get_home_solution(sym));
    if h <> nil then
      k := h^.kind;
  end;
  solution_kind_of_symbol := k;
end;

{ The printers.  Each writes its object on the standard output (no
  newline) and returns a blank, which the traces write after it
  (`write(x_to_string(...))'); il_node_to_string returns the
  identifier's printer's result for a named variable. }

{ arg_loc_t_to_string - an argument location by name (ip_reg, fp_reg,
  fp_reg_pair, memory; another, quad included, as unrecognized).

  0x216EC8, 0x72 bytes: loc a word at 8; a jump table over 0..4; the
  name written with PAS_$WRITE code 3877 (no width). }

function arg_loc_t_to_string;
begin
  case loc of
    0, 1, 2, 4: write(arg_loc_t(loc));
    otherwise write('<unrecognized arg_loc_t>');
  end;
  arg_loc_t_to_string := ' ';
end;

{ basic_block_to_string - 0x216FC8, 0x2C bytes: no parameters. }

function basic_block_to_string;
begin
  write('<a basic block>');
  basic_block_to_string := ' ';
end;

{ block_rec_to_string - a routine block's name (+296, an identifier)
  between quotes.

  0x217004, 0x9A bytes: b 8. }

function block_rec_to_string;
var
  name: il_$node_ptr_t;
  i: integer;
begin
  if b = nil then begin
    write('<nil block_rec>');
  end
  else begin
    write('<block_rec: "');
    name := b^.xp[74];
    for i := 1 to name^.idnt_len do
      write(name^.idnt_name[i]);
    write('">');
  end;
  block_rec_to_string := ' ';
end;

{ case_index_array_to_string - nothing written.  0x2170BE, 0x16 bytes. }

function case_index_array_to_string;
begin
  case_index_array_to_string := ' ';
end;

{ il_node_to_empty_string - nothing written but for nil.  0x2170D4: 0x2E
  bytes of code, then the name tables of the IL node kinds (0x21710A)
  and the tree operators (0x217BB4) that il_node_to_string writes
  with. }

function il_node_to_empty_string;
begin
  if node = nil then
    write('<nil il_node>');
  il_node_to_empty_string := ' ';
end;

{ il_node_to_string - an IL node by kind: a constant's value, a name
  between quotes (identifiers, strings, FORTRAN symbols, library
  descriptors), a block's name, a type's description, a tree's
  operator, a variable's name (the identifier's printer's result
  returned) or an anonymous temporary's number and size; another kind
  its address and kind name.

  0x21805C, 0x13EA bytes: node 8; the case a jump table over 76..234;
  every arm's last write shares one `jsr' (0x219434); the result in D4
  (a blank, or the identifier's). }

function il_node_to_string;
var
  n: il_$node_ptr_t;
  r: char;
  i: integer;
begin
  n := node;
  r := ' ';
  if n = nil then begin
    write('<nil il_node>');
  end
  else
    case n^.kind of
      163: begin
        write('<addr_con = ');
        write(il_node_to_string(n^.xp[2]));
        write('>');
      end;
      211: write('<ap_register>');
      204: begin
        write('<arg_blk_locn = ');
        write(n^.xl[1]:1);
        write('>');
      end;
      140: begin
        write('<assign_node = ');
        write(ur_aop_t(n^.xw[38]));
        write('>');
      end;
      208: begin
        write('<at_lib_dsc = ');
        write('"');
        for i := 1 to ord(n^.xc[49]) do
          write(n^.xc[49 + i]);
        write('"');
        write('>');
      end;
      200, 77, 87, 81, 82, 79, 80, 78, 86, 84, 85, 83:
        write(n^.int_value:1);
      149: write('<blk_end_node>');
      148: write('<block_entry_node>');
      209: begin
        write('<blockdata_blk = ');
        write(il_node_to_string(n^.xp[74]));
        write('>');
      end;
      141: write('<branch_node>');
      214: write('<case_node_range_check>');
      215: write('<case_node_no_range_check>');
      142: write('<cbranch_node>');
      171: write('<cc_call>');
      92: begin
        write('<char_string_ob = ');
        write('"');
        for i := 1 to n^.str_len do
          write(n^.str_chars[i]);
        write('"');
        write('>');
      end;
      143: begin
        write('<cmp_tree_node = ');
        write(ur_top_t(n^.xw[18]));
        write('>');
      end;
      111: begin
        write('<common_block_name = ');
        write(il_node_to_string(n^.xp[1]));
        write('>');
      end;
      90: write('<complex_ob>');
      164: write('<cs_node>');
      165: write('<cs_temp>');
      190: write('<cse_parent_ob>');
      189: write('<cse_use_ob>');
      183: begin
        write('<data section = ');
        write(il_node_to_string(n^.xp[2]));
        write('>');
      end;
      154: write('<db_register>');
      145: write('<dindex_node>');
      147: begin
        write('<disp = ');
        write(n^.xl[8]:1);
        write('>');
      end;
      155: write('<display_register>');
      198: write('<dpcomplex_ob>');
      89, 88: write(n^.real_value:1);
      167: write('<entry_blk>');
      139: write('<eval_node>');
      110:
        if n^.xw[35] = 0 then begin
          write('<anonymous fortran_symbol #');
          write(n^.xw[8]:1);
          write(', dataclass = ');
          write(ur_fdtype_t(isc_node_ptr_t(n)^.fs_f10.cls):1);
          write('>');
        end
        else begin
          write('<fortran_symbol = ');
          write('"');
          for i := 1 to n^.xw[35] do
            write(n^.xc[71 + i]);
          write('"');
          write('>');
        end;
      108: begin
        write('<function_blk = ');
        write(il_node_to_string(n^.xp[74]));
        write('>');
      end;
      76: begin
        write('"');
        for i := 1 to n^.idnt_len do
          write(n^.idnt_name[i]);
        write('"');
      end;
      172: begin
        write('<inner_blk = ');
        write(il_node_to_string(n^.xp[74]));
        write('>');
      end;
      144: write('<label_node>');
      229: write('<lb_register>');
      159: begin
        write('<lib_dsc = ');
        write('"');
        for i := 1 to n^.xw[4] do
          write(n^.xc[11 + 2 * n^.xw[5] + i]);
        write('"');
        write('>');
      end;
      106: begin
        write('<module_blk = ');
        write(il_node_to_string(n^.xp[74]));
        write('>');
      end;
      212: write('<namelist_constant_ob>');
      150: write('<nlbranch_node>');
      175: write('<pf_call>');
      203: begin
        case n^.xw[2] of
          0: write('R');
          1: write('S');
          2: write('D');
          otherwise write('<unknown arg_loc for physical_register_ob>');
        end;
        write(n^.xw[3]:1);
      end;
      107: begin
        write('<procedure_blk = ');
        write(il_node_to_string(n^.xp[74]));
        write('>');
      end;
      105: begin
        write('<program_blk = ');
        write(il_node_to_string(n^.xp[74]));
        write('>');
      end;
      146: write('<ptr_node>');
      151: write('<return_node>');
      153: write('<sb_register>');
      156: write('<set_con_ob>');
      205: begin
        write('<sym_disp = ');
        write(il_node_to_string(n^.xp[8]));
        write('>');
      end;
      137: begin
        write(ur_top_t(n^.xw[18]):1);
        write('(');
        write(')');
      end;
      188: write('<use_def_ob>');
      109:
        if n^.xp[1] = nil then begin
          write('<anonymous variable #');
          write(n^.xw[37]:1);
          write(', size = ');
          write(n^.xl[9]:1);
          write(' bits>');
        end
        else
          r := il_node_to_string(n^.xp[1]);
      131: begin
        write('array[');
        write(il_node_to_string(n^.xp[2]));
        write('] of ');
        write(il_node_to_string(n^.xp[1]));
      end;
      124: write('bool');
      234: begin
        write('function_returning(');
        write(il_node_to_string(n^.xp[2]));
        write(')');
      end;
      127: write('char_array');
      126: write('char_string_con');
      125: write('char');
      206: begin
        write('dynamic ');
        write('array[');
        write(il_node_to_string(n^.xp[2]));
        write('] of ');
        write(il_node_to_string(n^.xp[1]));
      end;
      129: begin
        write('enum(');
        write(n^.xw[3]:1);
        write(')');
      end;
      133: begin
        write('file(');
        write(il_node_to_string(n^.xp[1]));
        write(')');
      end;
      174: begin
        write('function_returning(');
        write(il_node_to_string(n^.xp[2]));
        write(')');
      end;
      122: begin
        write('integer(rlen = ');
        write(n^.xw[2]:1);
        write(', signed = ');
        write((n^.xc[6] <> chr(0)):1);
        write(')');
      end;
      136: write('null_set');
      177: write('offset');
      197: write('parray');
      173: write('procedure');
      130: begin
        write('ptr(');
        write(il_node_to_string(n^.xp[1]));
        write(')');
      end;
      123: begin
        write('real(rlen = ');
        write(n^.xw[2]:1);
        write(')');
      end;
      132: begin
        write('record(..., size = ');
        write(n^.xl[2]:1);
        write(')');
      end;
      134: begin
        write('set(elements = ');
        write(n^.xw[6]:1);
        write(', size = ');
        write(n^.xl[2]:1);
        write(') of ');
        write(il_node_to_string(n^.xp[1]));
      end;
      128: begin
        write('subrange [');
        write(il_node_to_string(n^.xp[2]));
        write('..');
        write(il_node_to_string(n^.xp[3]));
        write('] of ');
        write(il_node_to_string(n^.xp[1]));
      end;
      118: begin
        write('type_name == ');
        write(il_node_to_string(n^.xp[7]));
      end;
      135: write('univ_ptr');
      196: begin
        write('varying[');
        write(n^.xl[2]:1);
        write(']');
      end;
      210: write('void');
      otherwise begin
        write('<il node: address = ');
        write(integer32(n):1);
        write(', kind = ');
        write(an_kind_t(n^.kind):1);
        write('>');
      end;
    end;
  il_node_to_string := r;
end;

{ instruction_to_string - 0x219924, 0x40 bytes: instr 8 (only tested
  for nil). }

function instruction_to_string;
begin
  if instr = nil then begin
    write('<nil instruction>');
  end
  else begin
    write('<non-nil instruction>');
  end;
  instruction_to_string := ' ';
end;

{ label_to_string - a LIR label as L$ and its number (+8).

  0x21998C, 0x68 bytes: lab 8. }

function label_to_string;
begin
  if lab = nil then begin
    write('<nil label>');
  end
  else begin
    write('L$');
    write(ur_label_ptr_t(lab)^.w8:1);
  end;
  label_to_string := ' ';
end;

{ live_range_to_string - a live range by number (+6), marked when it
  holds a CSE (+10 bit 7).

  0x219A02, 0xA0 bytes: lr 8. }

function live_range_to_string;
begin
  if lr = nil then begin
    write('<nil LR>');
  end
  else begin
    write('<LR ');
    write(lr^.num:1);
    if isc_lr_ptr_t(lr)^.f10.isc_is_cse then begin
      write(' == CSE');
    end;
    write('>');
  end;
  live_range_to_string := ' ';
end;

{ phase_set_to_string - a node's phase bits by name (getphase's set:
  0 atomic_address .. 22 local_cse).

  0x219AB6, 0x2AA bytes: p 8 (a longword; bits 7 and 15 tested by
  `tst.b' and `tst.w'). }

function phase_set_to_string;
begin
  write('( ');
  if 0 in p then write('atomic_address ');
  if 1 in p then write('voladdr ');
  if 2 in p then write('volexpr ');
  if 3 in p then write('devread ');
  if 4 in p then write('devwrite ');
  if 5 in p then write('visited ');
  if 6 in p then write('iscse ');
  if 7 in p then write('align_arg_list ');
  if 8 in p then write('indexlong ');
  if 9 in p then write('delayed ');
  if 10 in p then write('wasbound ');
  if 11 in p then write('was_walked ');
  if 12 in p then write('sideeffects ');
  if 13 in p then write('targetright ');
  if 14 in p then write('targetleft ');
  if 15 in p then write('invariant ');
  if 19 in p then write('physical_address ');
  if 20 in p then write('processor_reg_address ');
  if 22 in p then write('local_cse ');
  write(')');
  phase_set_to_string := ' ';
end;

{ relational_to_string - a relation as a branch mnemonic (0 b, 1
  bnever, 2 bhi .. 15 ble).

  0x219E3A, 0x112 bytes: r a word at 8; a jump table over 0..15. }

function relational_to_string;
begin
  case r of
    0: write('b');
    1: write('bnever');
    2: write('bhi');
    3: write('bls');
    4: write('bcc');
    5: write('bcs');
    6: write('bne');
    7: write('beq');
    8: write('bvc');
    9: write('bvs');
    10: write('bpl');
    11: write('bmi');
    12: write('bge');
    13: write('blt');
    14: write('bgt');
    15: write('ble');
    otherwise write('<unknown relational type>');
  end;
  relational_to_string := ' ';
end;

{ solution_to_string - a solution: the well-known registers by name
  (AP, DB, LB, SF: the solution or, but for AP, its live range or
  register), then by kind: an address mode's index or literal
  displacement, a physical register as R, S or D and its number (the
  last physical match among 32 or 64), a register otherwise by its live
  range (with its field, shift, physical register), a literal's value
  twice (the second with code 4214, perhaps another radix), a local
  routine's, a processor register's, the other kinds by name.

  0x219FA6, 0xA86 bytes: s 8; a jump table over 0..23 (6 and 17..19
  the unrecognized); every arm's last write shares one `jsr'
  (0x21AA1A). }

function solution_to_string;
var
  r: integer;
  i: integer;
begin
  if sol = nil then begin
    write('<nil solution>');
  end
  else if solution_ptr_t(sol) = isc_user_routines_33c then begin
    write('AP');
  end
  else if (solution_ptr_t(sol) = isc_user_routines_338)
          or (sol^.live_range = isc_solution_ptr_t(isc_user_routines_338)^.live_range) then begin
    write('DB');
  end
  else if (solution_ptr_t(sol) = isc_user_routines_334)
          or (sol^.live_range = isc_solution_ptr_t(isc_user_routines_334)^.live_range) then begin
    write('LB');
  end
  else if (solution_ptr_t(sol) = isc_user_routines_340)
          or ((sol^.f76.physical_register_number = isc_solution_ptr_t(isc_user_routines_340)^.f76.physical_register_number)
              and (sol^.kind = 11) and sol^.f76.physical_register) then begin
    write('SF');
  end
  else
    case sol^.kind of
      5: begin
        write('<address_mode: ');
        if sol^.f76.uses_the_index_register then begin
          write('index_reg = ');
          write(solution_to_string(isc_solution_ptr_t(sol^.index_register)));
        end
        else if sol^.f76.uses_the_displacement then begin
          write('literal_32_bits_value = ');
          if sol^.f76.has_a_symbolic_displacement then begin
            write('sym_disp(');
            write(il_node_to_string(sol^.object_with_name));
            write(') + ');
          end;
          write(sol^.literal_32_bits_value:1);
        end;
        write('>');
      end;
      7: write('<solution$flow>');
      8: begin
        r := -1;
        for i := 0 to 63 do
          if sol^.f76.physical_register and (sol^.f76.physical_register_number = i) then
            r := i;
        if r <> -1 then begin
          write('S');
          write(r:1);
          if sol^.object_with_name <> nil then begin
            write(' == ');
            write(il_node_to_string(sol^.object_with_name));
          end;
        end
        else begin
          write('<fp_reg: ');
          write(live_range_to_string(sol^.live_range));
          if sol^.object_with_name <> nil then begin
            write(' == ');
            write(il_node_to_string(sol^.object_with_name));
          end;
          if sol^.f76.physical_register then begin
            write(', physical #');
            write(sol^.f76.physical_register_number:1);
          end;
          write('>');
        end;
      end;
      2, 3, 9: begin
        r := -1;
        for i := 0 to 63 do
          if sol^.f76.physical_register and (sol^.f76.physical_register_number = i) then
            r := i;
        if r <> -1 then begin
          write('D');
          write(r:1);
          if sol^.object_with_name <> nil then begin
            write(' == ');
            write(il_node_to_string(sol^.object_with_name));
          end;
          if sol^.kind = 2 then begin
            write(' HIGH');
          end
          else if sol^.kind = 3 then begin
            write(' LOW');
          end;
        end
        else begin
          write('<fp_reg_pair: ');
          write(live_range_to_string(sol^.live_range));
          if sol^.object_with_name <> nil then begin
            write(' == ');
            write(il_node_to_string(sol^.object_with_name));
          end;
          if sol^.f76.physical_register then begin
            write(', physical #');
            write(sol^.f76.physical_register_number:1);
          end;
          if sol^.kind = 2 then begin
            write(' HIGH');
          end
          else if sol^.kind = 3 then begin
            write(' LOW');
          end;
          write('>');
        end;
      end;
      11, 12, 13: begin
        r := -1;
        for i := 0 to 31 do
          if sol^.f76.physical_register and (sol^.f76.physical_register_number = i) then
            r := i;
        if r <> -1 then begin
          write('R');
          write(r:1);
          if sol^.kind = 12 then begin
            write(', bit_posn_of_lsb = ');
            write(sol^.f76.bit_position_of_lsb:1);
          end;
          if sol^.kind = 13 then begin
            write(' << ');
            write(sol^.f76.scale:1);
          end;
          if (isc_user_routines_352 = 1) and (r = 30) then begin
            write(' == PC');
          end;
        end
        else begin
          write('<');
          if sol^.kind = 11 then begin
            write('ip_reg: ');
          end
          else if sol^.kind = 12 then begin
            write('ip_reg_field: ');
          end
          else if sol^.kind = 13 then begin
            write('ip_reg_scaled: ');
          end;
          write(live_range_to_string(sol^.live_range));
          if sol^.object_with_name <> nil then begin
            write(' == ');
            write(il_node_to_string(sol^.object_with_name));
          end;
          if sol^.kind = 12 then begin
            write(', ');
            write(sol^.f76.field_precision:1);
            write('@');
            write(sol^.f76.bit_position_of_lsb:1);
          end;
          if sol^.kind = 13 then begin
            write(' << ');
            write(sol^.f76.scale:1);
          end;
          if sol^.f76.physical_register then begin
            write(', physical #');
            write(sol^.f76.physical_register_number:1);
          end;
          write('>');
        end;
      end;
      14: begin
        write('# ');
        write(sol^.literal_32_bits_value:1);
        write(' / ');
        write(sol^.literal_32_bits_value:1);
      end;
      4: begin
        write('<local_routine');
        if sol^.object_with_name <> nil then begin
          write(' == ');
          write(il_node_to_string(sol^.object_with_name));
        end;
        write('>');
      end;
      16: begin
        write('<processor_reg: ');
        write('literal_32_bits_value = ');
        write(sol^.literal_32_bits_value:1);
        write(', index = ');
        write(solution_to_string(isc_solution_ptr_t(sol^.index_register)));
        write('>');
      end;
      20: write('<solution$any_solution>');
      1: write('<solution$case_jump_base>');
      10: write('<solution$fp_reg_quad>');
      21: write('<solution$irrelevant>');
      15: write('<solution$literal_64_bits>');
      0: write('<solution$none>');
      22: write('<solution$proper_subtree>');
      23: write('<solution$void>');
      otherwise write('<UNRECOGNIZED SOLUTION KIND>');
    end;
  solution_to_string := ' ';
end;

{ type_attr_set_to_string - a type's attribute bits by name (0
  volatile .. 18 overlay_set).

  0x21AC0C, 0x2AA bytes: t 8 (a longword). }

function type_attr_set_to_string;
begin
  write('(');
  if 0 in t then write(' volatile');
  if 1 in t then write(' physical');
  if 2 in t then write(' atomic');
  if 3 in t then write(' devread');
  if 4 in t then write(' devwrite');
  if 5 in t then write(' address');
  if 6 in t then write(' immediate');
  if 7 in t then write(' reference');
  if 8 in t then write(' processor_register');
  if 9 in t then write(' fp_internal_register');
  if 10 in t then write(' register');
  if 11 in t then write(' size_specified');
  if 12 in t then write(' align_specified');
  if 13 in t then write(' natural_specified');
  if 14 in t then write(' no_fp');
  if 15 in t then write(' save_db');
  if 16 in t then write(' section');
  if 17 in t then write(' resident_procedure');
  if 18 in t then write(' overlay_set');
  write(' )');
  type_attr_set_to_string := ' ';
end;

{ vatt_rec_to_string - a variable's alignment record: its strength
  reduction (initial, first step and reduced expression) when it has
  one (attributes bit 17), else its alignment (+44) and natural
  alignment (+46).

  0x21AF9E, 0x1A2 bytes: v 8; the reduced expression's character
  written through the alignment arm's last `jsr'. }

function vatt_rec_to_string;
begin
  if (v^.vn_attr & 16#20000) <> 0 then begin
    write('<');
    write('initial = ');
    write(il_node_to_string(v^.vn_sr^.initial^.as_rhs));
    write(', step = ');
    write(il_node_to_string(v^.vn_sr^.inclist^.node^.as_rhs));
    write(', reduced = ');
    write(il_node_to_string(v^.vn_sr^.reduced));
  end
  else begin
    write('<');
    write('alignment = ');
    write(v^.vn_align:1);
    write(', nat_align = ');
    write(v^.vn_w46:1);
  end;
  write('>');
  vatt_rec_to_string := ' ';
end;

{ vatt_set_to_string - a variable's attribute bits by name, in the
  names' alphabetical order (18 allocated, 1 atomic, 16 bss, 17
  strength_reduction_temp, ..., 25 isc_was_here, 26
  is_a_register_candidate, ..., 0 volatile).

  0x21B17A, 0x36A bytes: a 8 (a longword). }

function vatt_set_to_string;
begin
  write('(');
  if 18 in a then write(' allocated');
  if 1 in a then write(' atomic');
  if 16 in a then write(' bss');
  if 17 in a then write(' strength_reduction_temp');
  if 3 in a then write(' dev_read');
  if 4 in a then write(' dev_write');
  if 22 in a then write(' force_to_memory');
  if 7 in a then write(' forloopindex');
  if 20 in a then write(' induction');
  if 6 in a then write(' initialized');
  if 26 in a then write(' is_a_register_candidate');
  if 10 in a then write(' is_formal_parameter');
  if 25 in a then write(' isc_was_here');
  if 9 in a then write(' loop_trip_count');
  if 24 in a then write(' marked_init_local_symbols');
  if 28 in a then write(' mentioned_in_sym_disp');
  if 21 in a then write(' nooptimize');
  if 2 in a then write(' physical');
  if 5 in a then write(' processor_reg');
  if 15 in a then write(' register');
  if 27 in a then write(' seen_in_ra');
  if 29 in a then write(' spilled_to_memory');
  if 14 in a then write(' temporary');
  if 8 in a then write(' uplevel');
  if 0 in a then write(' volatile');
  write(' )');
  vatt_set_to_string := ' ';
end;
