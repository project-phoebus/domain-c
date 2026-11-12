{ moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas - the ISC generator's enumeration (a DSEE derived object of the
  iscg_input description; cc.a88k only): opened after isc_lir.ins.pas
  by lir, lir_main, lir_utils, ra_utils, call_conv and the ISC units.

  The generator's classification of the IL nodes it has patterns for:
  one element per node kind, tree operator (_TOP) and assignment
  operator (_AOP) that a pattern matches, in alphabetical order of the
  node kinds, each assignment or tree node kind followed by its
  operators (IL_ASSIGN_NODE by the _AOPs, IL_CMP_TREE_NODE by the
  comparisons, IL_TREE_NODE by the _TOPs), IL_NONE first and IL$K_MAX
  last.  isc_user_routines' il_kind_function gives a
  node's element (the pattern matcher dispatches on it).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k (translator PD): the names are the Pascal identifier table
  isc_debug's isc_print_il_node writes them with (cc.a88k 0x0D4FA4, 178
  names; the same table follows isc_main's isc_$end_routine, 0x0DA74A,
  and isc_user_routines' bits_known_function, 0x211280:
  tools/cc_enumnames.py).

  Not known from the original: the type's name (the generator's
  `<prefix>$t' convention, as solution$t and arith$t). }

type
  il$t = (
    il_none,  { 0 }
    il_addr_con,
    il_ap_register,
    il_argument_block_location_ob,
    il_assign_node,
    il_add_to_aop,
    il_agg_aop,
    il_agg_len_aop,
    il_and_to_aop,
    il_div_by_aop,
    il_eor_to_aop,  { 10 }
    il_f_add_to_aop,
    il_f_div_by_aop,
    il_f_mul_to_aop,
    il_f_range_check_to_aop,
    il_f_sub_from_aop,
    il_fp_aop,
    il_isc_agg_aop,
    il_isc_agg_zero_aop,
    il_isc_fill_aop,
    il_isc_mul_to_aop,  { 20 }
    il_isc_slice_aop,
    il_lshft_to_aop,
    il_mul_to_aop,
    il_neg_to_aop,
    il_not_to_aop,
    il_or_to_aop,
    il_pack_aop,
    il_range_check_to_aop,
    il_rshft_to_aop,
    il_scalar_aop,  { 30 }
    il_set_and_to_aop,
    il_set_diff_from_aop,
    il_set_or_to_aop,
    il_strcat_aop,
    il_strcpy_aop,
    il_strncat_aop,
    il_strncpy_aop,
    il_sub_from_aop,
    il_at_lib_dsc,
    il_binteger_ob,  { 40 }
    il_ubinteger_ob,
    il_bit_field_assign,
    il_blk_end_node,
    il_block_entry_node,
    il_blogical_ob,
    il_branch_node,
    il_case_node_range_check,
    il_case_node_no_range_check,
    il_cbranch_node,
    il_cc_call,  { 50 }
    il_char_ob,
    il_char_string_ob,
    il_cmp_tree_node,
    il_agg_compare_top,
    il_bit_field_cmp_top,
    il_bit_test_top,
    il_compare_top,
    il_f_compare_top,
    il_set_compare_top,
    il_complex_ob,  { 60 }
    il_cs_node,
    il_cs_temp,
    il_cse_parent_ob,
    il_cse_use_ob,
    il_db_register,
    il_dindex_node,
    il_disp_node,
    il_display_register,
    il_dpcomplex_ob,
    il_dpreal_ob,  { 70 }
    il_entry_blk,
    il_eval_node,
    il_exception_handler_entry,
    il_exception_register,
    il_fortran_symbol,
    il_function_blk,
    il_insert_bit_field,
    il_integer_ob,
    il_uinteger_ob,
    il_label_node,  { 80 }
    il_lb_register,
    il_lib_dsc,
    il_linteger_ob,
    il_ulinteger_ob,
    il_llogical_ob,
    il_namelist_constant_ob,
    il_nlbranch_node,
    il_pf_call,
    il_physical_register_ob,
    il_procedure_blk,  { 90 }
    il_ptr_node,
    il_raise_exception,
    il_real_ob,
    il_release_dynamic_space,
    il_return_node,
    il_sb_register,
    il_set_con_ob,
    il_slogical_ob,
    il_sinteger_ob,
    il_usinteger_ob,  { 100 }
    il_sym_disp_node,
    il_tree_node,
    il_abs_top,
    il_ada_expon_top,
    il_add_top,
    il_addr_top,
    il_align_top,
    il_allocate_dynamic_space_top,
    il_alshf_top,
    il_and_top,  { 110 }
    il_arshf_top,
    il_bit_set_top,
    il_cache_top,
    il_call_top,
    il_chk_top,
    il_div_top,
    il_eor_top,
    il_expon_top,
    il_extend_top,
    il_extract_bit_field_top,  { 120 }
    il_f_ada_expon_top,
    il_f_add_top,
    il_f_div_top,
    il_f_expon_top,
    il_f_extend_top,
    il_f_math_top,
    il_f_mul_top,
    il_f_neg_top,
    il_f_range_check_top,
    il_f_sub_top,  { 130 }
    il_func_call_top,
    il_index_top,
    il_isc_addr_top,
    il_isc_agg_cmp_top,
    il_isc_agg_lex_cmp_top,
    il_isc_call_top,
    il_isc_fio_init,
    il_isc_func_call_hidden_temp_top,
    il_isc_func_call_top,
    il_isc_mul_top,  { 140 }
    il_isc_signed_mod_top,
    il_isc_signed_rem_top,
    il_isc_unsigned_mod_top,
    il_isc_unsigned_rem_top,
    il_lshf_top,
    il_mark_dynamic_space_top,
    il_max_top,
    il_min_top,
    il_mod_top,
    il_mul_top,  { 150 }
    il_neg_top,
    il_nop_top,
    il_not_top,
    il_or_top,
    il_physical_top,
    il_range_check_top,
    il_rshf_top,
    il_set_and_top,
    il_set_bit_in_set_top,
    il_set_diff_top,  { 160 }
    il_set_extend_top,
    il_set_or_top,
    il_set_range_in_set_top,
    il_signed_div_top,
    il_signed_mod_top,
    il_sr_top,
    il_strcmp_top,
    il_strlen_top,
    il_strncmp_top,
    il_sub_top,  { 170 }
    il_unpack_top,
    il_unsigned_div_top,
    il_unsigned_mod_top,
    il_value_top,
    il_use_def_ob,
    il_var_name,
    il$k_max);
