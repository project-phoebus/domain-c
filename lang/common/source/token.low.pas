{ lang/common/source/token.low.pas - TOKEN_'s low-level view: the IL
  node behind a token.

  Private to token.pas, which opens it before the lang/lang inserts
  that name the IL node (token.ins.pas, strings.ins.pas,
  list_tree.ins.pas) but does not open lang/lang/source/il.ins.pas (its
  .blocks file list): so the node pointer and the fields token.pas reads
  are declared here, under il.ins.pas's names and at its offsets.  A
  unit never opens both.

  No Apollo copy survives.  Not known from the original: everything
  about its contents but the offsets token.pas uses.
}

{ TODO(pascal) keep in step with il.ins.pas

  The identifier and string variant is il.ins.pas's variant 1 (strtk
  builds kind 92 nodes as idntk builds identifiers: +16 the length, +18
  the characters).  The other two are seen only here so far.  token.pas
  zero-extends the length (`clr.l; move.w (16,An)'), so it is a 0..65535
  value here; il.ins.pas has integer (strtk compares it signed).  So is
  the kind (token_$identifier passes it on as a longword, `clr.l'
  before the word; dpc extends ord() of an il_$kind_t with `ext.l',
  docs/questions.md 316), so the unit compares numbers. }

type
  { il.ins.pas's il_$kind_t, the IL node kinds (copied: the unit does not
    open il.ins.pas), for the kinds token.pas passes to smcontk and
    idntk. }
  il_$kind_t = (
    end_ob, if_ob, then_ob, begin_ob, else_ob, do_ob, with_ob, in_ob, of_ob,
    while_ob, case_ob, repeat_ob, until_ob, procedure_ob, var_ob, for_ob,
    array_ob, record_ob, set_ob, to_ob, downto_ob, mod_ob, or_ob, and_ob,
    not_ob, div_ob, const_ob, type_ob, function_ob, program_ob, packed_ob,
    label_ob, goto_ob, file_ob, forward_ob, static_ob, external_ob,
    define_ob, module_ob, val_param_ob, exit_ob, next_ob, internal_ob,
    return_ob, otherwise_ob, cast_ob, univ_ob, implies_ob, out_ob, up_to_ob,
    bus_ob, period_ob, becomes_ob, colon_ob, le_ob, ne_ob, lt_ob, eq_ob,
    ge_ob, gt_ob, sub_ob, open_ob, close_ob, comma_ob, semicolon_ob,
    star_ob, slash_ob, plus_ob, minus_ob, ampersand_ob, excl_ob, arrow_ob,
    eom_ob, error_ob, tilde_ob, badchar_ob, id_ob, blogical_ob, slogical_ob,
    llogical_ob, sinteger_ob, integer_ob, linteger_ob, usinteger_ob,
    uinteger_ob, ulinteger_ob, ubinteger_ob, char_ob, real_ob, dpreal_ob,
    complex_ob, varying_ob, char_string_ob, char32_string_ob, nil_ob,
    starstar_ob, routine_option_ob, attribute_ob, begin_critical_ob,
    end_critical_ob, library_ob, char16_ob, const_cob, volatile_cob,
    signed_cob, program_blk, module_blk, procedure_blk, function_blk,
    var_name, fortran_symbol, common_block_name, fdim_info, fdata_nlist,
    fdata_clist, equiv_stmt, const_name, label_name, type_name, field_name,
    pfield_name, param_name, integer_type, real_type, bool_type, char_type,
    char_string_con_type, char_array_type, subr_type, enum_type, ptr_type,
    array_type, record_type, file_type, set_type, univ_ptr_type,
    null_set_type, tree_node, gen_tree_node, eval_node, assign_node,
    branch_node, cbranch_node, cmp_tree_node, label_node, dindex_node,
    ptr_node, disp_node, block_entry_node, blk_end_node, nlbranch_node,
    return_node, alloc_temp, sb_register, db_register, display_register,
    set_con_ob, def_const_ob, std_func, lib_dsc, ref_list, state_save,
    lnum_entry, addr_con, cs_node, cs_temp, fdata_do, entry_blk, param_list,
    ftn_xref, ptr_hdr, cc_call, inner_blk, proc__type, func__type, pf_call,
    rec_const_ob, offset_type, reg_assign_ob, actparam, ext_state_save,
    dead_temp, procedure_section, data_section, inline_constant,
    namelist_id_ob, lnref_ob, variant_ob, use_def_ob, cse_use_ob,
    cse_parent_ob, reg_list_ob, transfer_vector, proc_reloc, external_ref,
    reloc_absolute_addr_con, varying_type, parray_type, dpcomplex_ob,
    m68k_unpacked, binteger_ob, routine_option_name, attribute_name,
    physical_register_ob, argument_block_location_ob, sym_disp_node,
    dynamic_array_type, dope_vector, at_lib_dsc, blockdata_blk, void_type,
    ap_register, namelist_constant_ob, undefined_object,
    case_node_range_check, case_node_no_range_check, defaulted_info,
    char16_type, char16_array_type, isc_fetch, isc_convert,
    fdata_default_seq, exception_frame, exception_handler_entry,
    raise_exception, release_dynamic_space, exception_register,
    insert_bit_field, bit_field_assign, lb_register, virt_var_name,
    spine_mark, isc_share, pa_mmu_bip, cc_func_returning_type,
    indexed_reference, union_ob);

  il_$node_ptr_t = ^il_$node_t;
  il_$node_t = record
    unused_0: integer;                  { +0 }
    kind: 0..65535;                     { +2: zero-extended (0x073850) }
    case integer of
      { An identifier (idntk) or a string constant (kind 92, strtk). }
      1: (idnt_next: il_$node_ptr_t;    { +4 }
          idnt_unused_8: integer32;     { +8 }
          idnt_unused_12: integer32;    { +12 }
          idnt_len: 0..65535;           { +16: zero-extended }
          idnt_name: array [1..4096] of char);  { +18 }
      { Kind 163: a constant made from another node; when its class at
        +20 is 11 and that node a string, the string's bytes. }
      2: (ref_unused_4: integer32;      { +4 }
          ref_node: il_$node_ptr_t;     { +8 }
          ref_unused_12: integer32;     { +12 }
          ref_unused_16: integer32;     { +16 }
          ref_class: char);             { +20: a byte, compared with 11 }
      { Kind 176: a constant of a given size in bytes. }
      3: (sized_unused_4: integer32;    { +4 }
          sized_bytes: integer32);      { +8 }
  end;
