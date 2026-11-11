{ lang/common/source/pds.ins.pas - PDS_, the program's debugging symbol
  records (the .symbols sections of the debugging tables): records made
  for names, locations, types, variables, entries, signatures, files,
  labels, constants and the auxiliary records, scopes begun and ended,
  and the sections built and written.

  No Apollo copy survives.  The headings are read off pds.pas (cc.m68k
  0x069B08..0x071C70, the same in cc.a88k) and its callers, which are
  all in debug_sym_dmp.pas (get_type_rep, get_record_rep,
  get_signature_rep, debug_sym_dmp_$add_loc_info, ...), and the global
  routines only pds.pas calls are here as well (pds_$make_src_loc,
  pds_$make_implicit_enum_rec, pds_$add_implicit_enum_element,
  pds_$make_string_rec, pds_$make_aux_size_rec,
  pds_$make_aux_var_bound_rec, pds_$make_aux_type_deriv_rec,
  pds_$make_aux_lifetime_rec, pds_$make_aux_ptr_base_rec,
  pds_$add_aux_rec).  Values by value (val_param).

  The records are opaque to the callers (pds.pvt.pas has them): every
  record, name, location, type and attribute set made here is a
  univ_ptr.  The image's routines return them in D0 (callers `movea.l
  D0'), but for the two attribute sets (a typed pointer, in A0): taken
  to be the Rev 8.89 convention for univ_ptr results
  (docs/rev889-patterns.md 25).

  pds.pas opens it after /us/ins/ubase.ins.pas and /sys/ins/dst.ins.pas
  (us/us/sys/ins/dst.ins.pas); it names no type of another insert.

  Not known from the original: every type and parameter name here (the
  parameters are named from pds.pas's messages where they have them).
}

type
  { The characters of a name, a constant's value, a section's name. }
  pds_$chars_t = array [1..32767] of char;

  { A variable's or an argument's attributes: var 0..4, arg 0..5. }
  pds_$attrs_t = set of 0..15;
  pds_$attrs_p_t = ^pds_$attrs_t;

  { The object file's allocator: size bytes at offset pos (pos moved
    past them), their address returned. }
  pds_$alloc_obj_func_t = ^function(
    in out pos: integer32;
    size: integer32): integer32; options(val_param);

  { A section made (an include file's when is_include), its number
    returned. }
  pds_$create_section_func_t = ^function(
    is_include: boolean): integer32; options(val_param);

  { The section's name given (len characters). }
  pds_$add_section_name_func_t = ^procedure(
    section: integer32;
    in name: univ pds_$chars_t;
    len: integer); options(val_param);

{ PDS_$MAKE_NAME - a name of len characters (not 0).  0x069C60. }
function pds_$make_name(
    in chars: univ pds_$chars_t;
    len: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_SRC_LOC - a source location: file_index up to 2047, line up
  to 1048575.  0x069CE8. }
function pds_$make_src_loc(
    file_index: integer;
    line: integer32): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_LOC - a location in the location pool (one pool only;
  offset not negative).  0x069DB4. }
function pds_$make_loc(
    loc_pool_handle: univ_ptr;
    offset: integer32): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_TYPE - a type: a standard type's code (0..21) without a
  record, or code 22 with the user defined type's record.  0x069EB4. }
function pds_$make_type(
    type_code: integer;
    rec_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_POINTER_REC - 0x069FE2.  A nil src_loc_p is line 0 of file
  0, here and in the other record makers. }
function pds_$make_pointer_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_VAR_ATTR - an empty set of variable attributes.  0x06A082. }
function pds_$make_var_attr: pds_$attrs_p_t; extern;

{ PDS_$ADD_VAR_ATTR - attrib (0..4) added to the variable's attributes.
  0x06A0A4. }
procedure pds_$add_var_attr(
    var_p: univ_ptr;
    attrib: integer); options(val_param); extern;

{ PDS_$MAKE_VARIABLE_REC - 0x06A18C. }
function pds_$make_variable_rec(
    name_p: univ_ptr;
    loc_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr;
    attr_p: pds_$attrs_p_t): univ_ptr; options(val_param); extern;

{ PDS_$ADD_VAR_LOC - the variable's location.  0x06A284. }
procedure pds_$add_var_loc(
    var_p: univ_ptr;
    loc_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_ENTRY_REC - 0x06A324. }
function pds_$make_entry_rec(
    name_p: univ_ptr;
    loc_p: univ_ptr;
    src_loc_p: univ_ptr;
    sig_p: univ_ptr;
    w48: integer): univ_ptr; options(val_param); extern;

{ PDS_$ADD_ENTRY_POINT_LOC - the entry's location.  0x06A410. }
procedure pds_$add_entry_point_loc(
    entry_p: univ_ptr;
    loc_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_SIGNATURE_REC - a signature of nargs arguments, its result
  a variable record.  0x06A4B8. }
function pds_$make_signature_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    result_p: univ_ptr;
    nargs: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_ARG_ATTR - an empty set of argument attributes.  0x06A524. }
function pds_$make_arg_attr: pds_$attrs_p_t; extern;

{ PDS_$ADD_ARG_ATTR - attrib (0..5) added to the set.  0x06A546. }
procedure pds_$add_arg_attr(
    attr_p: pds_$attrs_p_t;
    attrib: integer); options(val_param); extern;

{ PDS_$MAKE_ARG - an argument: its variable record and attributes.
  0x06A5EA. }
function pds_$make_arg(
    var_p: univ_ptr;
    attr_p: pds_$attrs_p_t): univ_ptr; options(val_param); extern;

{ PDS_$ADD_ARG_TO_SIGNATURE - argument arg_num of the signature.
  0x06A66C. }
procedure pds_$add_arg_to_signature(
    sig_p: univ_ptr;
    arg_num: integer;
    arg_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_ALIAS_REC - 0x06A7D4. }
function pds_$make_alias_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$ADD_DEPENDENT_TYPE_TO_ALIAS_REC - the alias's type.  0x06A864. }
procedure pds_$add_dependent_type_to_alias_rec(
    rec_p: univ_ptr;
    type_desc_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_FILE_ENTRY - a file table entry.  0x06A994. }
function pds_$make_file_entry(
    name_p: univ_ptr;
    id: integer32): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_FILE_TABLE - a table of nfiles entries (not 0).  0x06AA0C. }
function pds_$make_file_table(
    nfiles: integer;
    main_index: integer): univ_ptr; options(val_param); extern;

{ PDS_$ADD_FILE_ENTRY - entry index (1..nfiles) of the table.
  0x06AA7C. }
procedure pds_$add_file_entry(
    file_table_p: univ_ptr;
    index: integer;
    file_entry_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_LABEL_REC - 0x06ABF4. }
function pds_$make_label_rec(
    name_p: univ_ptr;
    loc_p: univ_ptr;
    src_loc_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$ADD_LABEL_LOC - the label's location.  0x06AC84. }
procedure pds_$add_label_loc(
    label_p: univ_ptr;
    loc_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_CONSTANT_VALUE - len bytes of a constant's value.
  0x06AD2C. }
function pds_$make_constant_value(
    in bytes: univ pds_$chars_t;
    len: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_CONSTANT_REC - 0x06AD80. }
function pds_$make_constant_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr;
    value_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_SET_REC - 0x06AEA8. }
function pds_$make_set_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr;
    size: integer;
    nelements: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_SUBRANGE_REC - 0x06AFC0. }
function pds_$make_subrange_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr;
    l44: integer32;
    l48: integer32;
    size: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_FILE_REC - 0x06B0B4. }
function pds_$make_file_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_OFFSET_REC - 0x06B154. }
function pds_$make_offset_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    area_type_desc_p: univ_ptr;
    base_type_desc_p: univ_ptr;
    l48: integer32;
    l52: integer32;
    w60: integer;
    l56: integer32;
    size: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_IMPLICIT_ENUM_REC - 0x06B2A8. }
function pds_$make_implicit_enum_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    size: integer;
    nelements: integer): univ_ptr; options(val_param); extern;

{ PDS_$ADD_IMPLICIT_ENUM_ELEMENT - element enum_pos's name.  0x06B390. }
procedure pds_$add_implicit_enum_element(
    enum_rec_p: univ_ptr;
    enum_pos: integer;
    name_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_EXPLICIT_ENUM_REC - 0x06B510. }
function pds_$make_explicit_enum_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    size: integer;
    nelements: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_EXPLICIT_ENUM_ELEMENT - a name and its value.  0x06B57C. }
function pds_$make_explicit_enum_element(
    name_p: univ_ptr;
    value: integer32): univ_ptr; options(val_param); extern;

{ PDS_$ADD_EXPLICIT_ENUM_ELEMENT - element enum_pos.  0x06B600. }
procedure pds_$add_explicit_enum_element(
    enum_rec_p: univ_ptr;
    enum_pos: integer;
    enum_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_SHORT_RECORD_REC - a record whose fields lie at byte
  offsets up to 65535; a size beyond 65535 goes to an auxiliary size
  record.  0x06B780. }
function pds_$make_short_record_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    size: integer32;
    nfields: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_SHORT_FIELD - 0x06B810. }
function pds_$make_short_field(
    name_p: univ_ptr;
    type_desc_p: univ_ptr;
    offset: integer32): univ_ptr; options(val_param); extern;

{ PDS_$ADD_SHORT_FIELD - field field_num of the short record.
  0x06B8CA. }
procedure pds_$add_short_field(
    rec_p: univ_ptr;
    field_num: integer;
    short_field_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_RECORD_REC - 0x06BA4C. }
function pds_$make_record_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    size: integer32;
    nfields: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_FIELD - a field: format 0 at a byte offset; format 1 a bit
  field (nbits up to 63, start_bit_num up to 7).  0x06BADC. }
function pds_$make_field(
    name_p: univ_ptr;
    type_desc_p: univ_ptr;
    format: integer;
    offset: integer32;
    start_bit_num: integer;
    nbits: integer;
    flag: boolean): univ_ptr; options(val_param); extern;

{ PDS_$ADD_FIELD - field field_num of the record.  0x06BC7C. }
procedure pds_$add_field(
    rec_p: univ_ptr;
    field_num: integer;
    field_p: univ_ptr); options(val_param); extern;

{ PDS_$MAKE_ARRAY_REC - 0x06BE00. }
function pds_$make_array_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    elem_type_desc_p: univ_ptr;
    indx_type_desc_p: univ_ptr;
    l48: integer32;
    l52: integer32;
    l56: integer32;
    l60: integer32;
    b64: boolean;
    b65: boolean;
    b66: boolean;
    span: integer;
    b70: boolean;
    w72: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_STRING_REC - 0x06BF2E. }
function pds_$make_string_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    elem_type_desc_p: univ_ptr;
    indx_type_desc_p: univ_ptr;
    l48: integer32;
    l52: integer32;
    l56: integer32): univ_ptr; options(val_param); extern;

{ The auxiliary records (added to a record by pds_$add_aux_rec). }

{ PDS_$MAKE_AUX_REG_VAL_REC - 0x06C02E. }
function pds_$make_aux_reg_val_rec(
    reg: integer;
    location_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_AUX_SIZE_REC - 0x06C0B0. }
function pds_$make_aux_size_rec(
    size: integer32): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_AUX_FIELD_SIZE_REC - field_num not 0.  0x06C0DC. }
function pds_$make_aux_field_size_rec(
    field_num: integer;
    size: integer32): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_AUX_ALIGN_REC - 0x06C15C. }
function pds_$make_aux_align_rec(
    align: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_AUX_FIELD_ALIGN_REC - field_num not 0.  0x06C18A. }
function pds_$make_aux_field_align_rec(
    field_num: integer;
    align: integer): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_AUX_VAR_BOUND_REC - bound 0 or 1, and a record.  0x06C20C. }
function pds_$make_aux_var_bound_rec(
    bound: integer;
    rec_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_AUX_TYPE_DERIV_REC - 0x06C24A. }
function pds_$make_aux_type_deriv_rec(
    parent_type_desc_p: univ_ptr;
    w24: integer;
    flag: boolean): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_AUX_LIFETIME_REC - 0x06C2D8. }
function pds_$make_aux_lifetime_rec(
    loc_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$MAKE_AUX_PTR_BASE_REC - 0x06C346. }
function pds_$make_aux_ptr_base_rec(
    var_p: univ_ptr): univ_ptr; options(val_param); extern;

{ PDS_$ADD_AUX_REC - aux_p appended to the record's auxiliary records.
  0x06C400. }
procedure pds_$add_aux_rec(
    rec_p: univ_ptr;
    aux_p: univ_ptr); options(val_param); extern;

{ PDS_$GET_SCOPE_OFFSET_WITHIN_SECTION - the offset in its section of
  the lowest record written under a root record.  0x06C4AC. }
function pds_$get_scope_offset_within_section(
    rec_p: univ_ptr): integer32; options(val_param); extern;

{ PDS_$INITIALIZE - the pools opened; names compared ignoring case
  when fold_case.  0x06C9A0. }
procedure pds_$initialize(
    fold_case: boolean); options(val_param); extern;

{ PDS_$ENTER_MAIN_FILE_TABLE - the compilation's file table.
  0x06CADC. }
procedure pds_$enter_main_file_table(
    file_table_p: univ_ptr); options(val_param); extern;

{ PDS_$FINALIZE - the pools emptied.  0x06CBE8. }
procedure pds_$finalize; extern;

{ PDS_$BEGIN_SCOPE - a scope begun (the include files it refers to
  cleared).  0x06CC1E. }
procedure pds_$begin_scope; extern;

{ PDS_$ENTER_NAMED_RECORD_CURRENT_SCOPE - a named record (and the
  records it refers to) entered in the current scope.  0x06D68C. }
procedure pds_$enter_named_record_current_scope(
    rec_p: univ_ptr); options(val_param); extern;

{ PDS_$END_SCOPE - the scope ended (its include files' scopes and the
  end of scope appended to the main file's records); its first record
  returned.  0x06D790. }
procedure pds_$end_scope(
    out symbols_start: univ_ptr); extern;

{ PDS_$CREATE_SYMBOLS_SECTIONS - the include files' buckets merged and
  ordered, a section made for each.  0x070FD8. }
procedure pds_$create_symbols_sections(
    create_section: pds_$create_section_func_t); options(val_param);
    extern;

{ PDS_$DUMP_SYMBOLS_SECTION - the next section (in order) written from
  start_offset; its end returned.  0x071966. }
procedure pds_$dump_symbols_section(
    section: integer32;
    start_offset: integer32;
    out end_offset: integer32;
    alloc_obj_func_p: pds_$alloc_obj_func_t;
    dump_loc_func_p: univ_ptr;
    add_section_name_p: pds_$add_section_name_func_t);
    options(val_param); extern;
