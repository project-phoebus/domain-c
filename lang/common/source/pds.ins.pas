{ lang/common/source/pds.ins.pas - PDS_, the program's debugging symbol
  records (the .symbols sections of the debugging tables): records made
  for names, locations, types, variables, entries, signatures, files,
  labels, constants and the auxiliary records, scopes begun and ended,
  and the sections built and written.

  No Apollo copy survives.  pds.pas (cc.m68k 0x069B08..0x071B78, both
  binaries) is not translated yet; these headings are read off its
  frames and call sites (tools/cc_params.py) and declare the routines
  another unit calls: every caller outside pds.pas is debug_sym_dmp.pas
  (get_type_rep, get_record_rep, get_signature_rep,
  debug_sym_dmp_$add_loc_info, ...).  The convention of the core's
  headings read off frames (docs/core-plan.md): univ_ptr for every
  pointer, p1..pn for names, the slot's width for the rest, val_param;
  a result read from D0 is a longword (the records are addressed as
  integers: callers `movea.l D0'), from A0 a pointer.  Narrow them
  from pds.pas's bodies.

  pds.pas opens it after /us/ins/ubase.ins.pas and /sys/ins/dst.ins.pas
  (us/us/sys/ins/dst.ins.pas, the DST records: no customer copy here),
  so it names no type of another insert.

  The global routines only pds.pas calls are not here (declare them in
  pds.pas):
    pds_$make_src_loc, pds_$make_implicit_enum_rec,
    pds_$add_implicit_enum_element, pds_$make_string_rec,
    pds_$make_aux_size_rec, pds_$make_aux_var_bound_rec,
    pds_$make_aux_type_deriv_rec, pds_$make_aux_lifetime_rec,
    pds_$make_aux_ptr_base_rec, pds_$add_aux_rec.

  Not known from the original: every type and parameter name here.
}

{ PDS_$MAKE_NAME - 0x069C60 (frame 8:a 12:w).  Called from get_name_rep.
  }
function pds_$make_name(
    p1: univ_ptr;
    p2: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_LOC - 0x069DB4 (frame 8:al 12:l).  Called from
  get_sect_rel_location_rep, get_var_location_rep. }
function pds_$make_loc(
    p1: univ_ptr;
    p2: integer32): integer32; options(val_param); extern;

{ PDS_$MAKE_TYPE - 0x069EB4 (frame 8:w 10:a).  Called from get_type_rep.
  }
function pds_$make_type(
    p1: integer;
    p2: univ_ptr): integer32; options(val_param); extern;

{ PDS_$MAKE_POINTER_REC - 0x069FE2 (frame 8:l 12:a 16:l).  Called from
  get_type_rep. }
function pds_$make_pointer_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32): integer32; options(val_param); extern;

{ PDS_$MAKE_VAR_ATTR - 0x06A082 (no parameters).  Called from
  get_variable_rep. }
function pds_$make_var_attr: univ_ptr; extern;

{ PDS_$ADD_VAR_ATTR - 0x06A0A4 (frame 8:a 12:w).  Called from
  get_memory_loc. }
procedure pds_$add_var_attr(
    p1: univ_ptr;
    p2: integer); options(val_param); extern;

{ PDS_$MAKE_VARIABLE_REC - 0x06A18C (frame 8:l 12:l 16:a 20:l 24:l).
  Called from get_variable_rep. }
function pds_$make_variable_rec(
    p1: integer32;
    p2: integer32;
    p3: univ_ptr;
    p4: integer32;
    p5: integer32): integer32; options(val_param); extern;

{ PDS_$ADD_VAR_LOC - 0x06A284 (frame 8:a 12:a).  Called from
  debug_sym_dmp_$add_loc_info. }
procedure pds_$add_var_loc(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_ENTRY_REC - 0x06A324 (frame 8:l 12:l 16:a 20:l 24:w).
  Called from get_entry_rep. }
function pds_$make_entry_rec(
    p1: integer32;
    p2: integer32;
    p3: univ_ptr;
    p4: integer32;
    p5: integer): integer32; options(val_param); extern;

{ PDS_$ADD_ENTRY_POINT_LOC - 0x06A410 (frame 8:a 12:a).  Called from
  debug_sym_dmp_$add_loc_info. }
procedure pds_$add_entry_point_loc(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_SIGNATURE_REC - 0x06A4B8 (frame 8:l 12:a 16:l 20:w).  Called
  from get_signature_rep, get_type_rep. }
function pds_$make_signature_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_ARG_ATTR - 0x06A524 (no parameters).  Called from
  get_signature_rep, get_type_rep. }
function pds_$make_arg_attr: univ_ptr; extern;

{ PDS_$ADD_ARG_ATTR - 0x06A546 (frame 8:a 12:w).  Called from
  get_signature_rep. }
procedure pds_$add_arg_attr(
    p1: univ_ptr;
    p2: integer); options(val_param); extern;

{ PDS_$MAKE_ARG - 0x06A5EA (frame 8:l 12:a).  Called from
  get_signature_rep, get_type_rep. }
function pds_$make_arg(
    p1: integer32;
    p2: univ_ptr): integer32; options(val_param); extern;

{ PDS_$ADD_ARG_TO_SIGNATURE - 0x06A66C (frame 8:a 12:w 14:a).  Called
  from get_signature_rep, get_type_rep. }
procedure pds_$add_arg_to_signature(
    p1: univ_ptr;
    p2: integer;
    p3: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_ALIAS_REC - 0x06A7D4 (frame 8:l 12:a).  Called from
  get_alias_rep. }
function pds_$make_alias_rec(
    p1: integer32;
    p2: univ_ptr): integer32; options(val_param); extern;

{ PDS_$ADD_DEPENDENT_TYPE_TO_ALIAS_REC - 0x06A864 (frame 8:a 12:a).
  Called from get_alias_rep. }
procedure pds_$add_dependent_type_to_alias_rec(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_FILE_ENTRY - 0x06A994 (frame 8:a 12:l).  Called from
  add_file_entry. }
function pds_$make_file_entry(
    p1: univ_ptr;
    p2: integer32): integer32; options(val_param); extern;

{ PDS_$MAKE_FILE_TABLE - 0x06AA0C (frame 8:w 10:w).  Called from
  debug_sym_dmp_$init. }
function pds_$make_file_table(
    p1: integer;
    p2: integer): integer32; options(val_param); extern;

{ PDS_$ADD_FILE_ENTRY - 0x06AA7C (frame 8:a 12:w 14:a).  Called from
  add_file_entry. }
procedure pds_$add_file_entry(
    p1: univ_ptr;
    p2: integer;
    p3: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_LABEL_REC - 0x06ABF4 (frame 8:l 12:l 16:a).  Called from
  get_label_rep. }
function pds_$make_label_rec(
    p1: integer32;
    p2: integer32;
    p3: univ_ptr): integer32; options(val_param); extern;

{ PDS_$ADD_LABEL_LOC - 0x06AC84 (frame 8:a 12:a).  Called from
  debug_sym_dmp_$add_loc_info. }
procedure pds_$add_label_loc(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_CONSTANT_VALUE - 0x06AD2C (frame 8:a 12:w).  Called from
  get_const_rep. }
function pds_$make_constant_value(
    p1: univ_ptr;
    p2: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_CONSTANT_REC - 0x06AD80 (frame 8:l 12:a 16:l 20:l).  Called
  from get_const_rep. }
function pds_$make_constant_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: integer32): integer32; options(val_param); extern;

{ PDS_$MAKE_SET_REC - 0x06AEA8 (frame 8:l 12:a 16:l 20:w 22:w).  Called
  from get_type_rep. }
function pds_$make_set_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: integer;
    p5: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_SUBRANGE_REC - 0x06AFC0 (frame 8:l 12:a 16:l 20:l 24:l
  28:w).  Called from get_type_rep. }
function pds_$make_subrange_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: integer32;
    p5: integer32;
    p6: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_FILE_REC - 0x06B0B4 (frame 8:l 12:a 16:l).  Called from
  get_type_rep. }
function pds_$make_file_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32): integer32; options(val_param); extern;

{ PDS_$MAKE_OFFSET_REC - 0x06B154 (frame 8:l 12:a 16:l 20:l 24:l 28:l
  32:w 34:l 38:w).  Called from get_type_rep. }
function pds_$make_offset_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: integer32;
    p5: integer32;
    p6: integer32;
    p7: integer;
    p8: integer32;
    p9: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_EXPLICIT_ENUM_REC - 0x06B510 (frame 8:l 12:a 16:w 18:w).
  Called from get_enum_rep. }
function pds_$make_explicit_enum_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer;
    p4: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_EXPLICIT_ENUM_ELEMENT - 0x06B57C (frame 8:a 12:l).  Called
  from get_enum_rep. }
function pds_$make_explicit_enum_element(
    p1: univ_ptr;
    p2: integer32): integer32; options(val_param); extern;

{ PDS_$ADD_EXPLICIT_ENUM_ELEMENT - 0x06B600 (frame 8:a 12:w 14:a).
  Called from get_enum_rep. }
procedure pds_$add_explicit_enum_element(
    p1: univ_ptr;
    p2: integer;
    p3: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_SHORT_RECORD_REC - 0x06B780 (frame 8:l 12:a 16:l 20:w).
  Called from get_record_rep. }
function pds_$make_short_record_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_SHORT_FIELD - 0x06B810 (frame 8:a 12:a 16:l).  Called from
  get_record_rep. }
function pds_$make_short_field(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer32): integer32; options(val_param); extern;

{ PDS_$ADD_SHORT_FIELD - 0x06B8CA (frame 8:a 12:w 14:a).  Called from
  get_record_rep. }
procedure pds_$add_short_field(
    p1: univ_ptr;
    p2: integer;
    p3: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_RECORD_REC - 0x06BA4C (frame 8:l 12:a 16:l 20:w).  Called
  from get_record_rep. }
function pds_$make_record_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_FIELD - 0x06BADC (frame 8:a 12:a 16:w 18:l 22:w 24:w 26:b).
  Called from get_record_rep. }
function pds_$make_field(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer;
    p4: integer32;
    p5: integer;
    p6: integer;
    p7: boolean): integer32; options(val_param); extern;

{ PDS_$ADD_FIELD - 0x06BC7C (frame 8:a 12:w 14:a).  Called from
  get_record_rep. }
procedure pds_$add_field(
    p1: univ_ptr;
    p2: integer;
    p3: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_ARRAY_REC - 0x06BE00 (frame 8:l 12:a 16:l 20:l 24:l 28:l
  32:l 36:l 40:b 42:b 44:b 46:w 48:b 50:w).  Called from get_type_rep. }
function pds_$make_array_rec(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: integer32;
    p5: integer32;
    p6: integer32;
    p7: integer32;
    p8: integer32;
    p9: boolean;
    p10: boolean;
    p11: boolean;
    p12: integer;
    p13: boolean;
    p14: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_AUX_REG_VAL_REC - 0x06C02E (frame 8:w 10:a).  Called from
  debug_sym_dmp_$add_loc_info. }
function pds_$make_aux_reg_val_rec(
    p1: integer;
    p2: univ_ptr): integer32; options(val_param); extern;

{ PDS_$MAKE_AUX_FIELD_SIZE_REC - 0x06C0DC (frame 8:w 10:l).  Called from
  may_need_common_aux. }
function pds_$make_aux_field_size_rec(
    p1: integer;
    p2: integer32): integer32; options(val_param); extern;

{ PDS_$MAKE_AUX_ALIGN_REC - 0x06C15C (frame 8:w).  Called from
  may_need_common_aux; a function as its
  siblings (its caller branches to the store they share). }
function pds_$make_aux_align_rec(
    p1: integer): integer32; options(val_param); extern;

{ PDS_$MAKE_AUX_FIELD_ALIGN_REC - 0x06C18A (frame 8:w 10:w).  Called
  from may_need_common_aux. }
function pds_$make_aux_field_align_rec(
    p1: integer;
    p2: integer): integer32; options(val_param); extern;

{ PDS_$GET_SCOPE_OFFSET_WITHIN_SECTION - 0x06C4AC (frame 8:a).  Called
  from write_blocks. }
function pds_$get_scope_offset_within_section(
    p1: univ_ptr): integer32; options(val_param); extern;

{ PDS_$INITIALIZE - 0x06C9A0 (frame 8:b).  Called from
  debug_sym_dmp_$init. }
procedure pds_$initialize(
    p1: boolean); options(val_param); extern;

{ PDS_$ENTER_MAIN_FILE_TABLE - 0x06CADC (frame 8:a).  Called from
  debug_sym_dmp_$init. }
procedure pds_$enter_main_file_table(
    p1: univ_ptr); options(val_param); extern;

{ PDS_$FINALIZE - 0x06CBE8 (no parameters).  Called from
  debug_sym_dmp_$finalize. }
procedure pds_$finalize; extern;

{ PDS_$BEGIN_SCOPE - 0x06CC1E (no parameters).  Called from
  process_debug_symbols; process_symbols_rec
  reads its result as a word. }
function pds_$begin_scope: integer; extern;

{ PDS_$ENTER_NAMED_RECORD_CURRENT_SCOPE - 0x06D68C (frame 8:a).  Called
  from process_named_objects. }
procedure pds_$enter_named_record_current_scope(
    p1: univ_ptr); options(val_param); extern;

{ PDS_$END_SCOPE - 0x06D790 (frame 8:a).  Called from
  process_debug_symbols. }
procedure pds_$end_scope(
    p1: univ_ptr); options(val_param); extern;

{ PDS_$CREATE_SYMBOLS_SECTIONS - 0x070FD8 (frame 8:a).  Called from
  debug_sym_dmp_$create_symbols_sections. }
procedure pds_$create_symbols_sections(
    p1: univ_ptr); options(val_param); extern;

{ PDS_$DUMP_SYMBOLS_SECTION - 0x071966 (frame 8:al 12:l 16:l 20:a 24:a
  28:a).  Called from debug_sym_dmp_$dump_symbols_section. }
procedure pds_$dump_symbols_section(
    p1: univ_ptr;
    p2: integer32;
    p3: integer32;
    p4: univ_ptr;
    p5: univ_ptr;
    p6: univ_ptr); options(val_param); extern;
