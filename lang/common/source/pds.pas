{ pds - PDS_, the program's debugging symbols: the records debug_sym_dmp
  makes for the compilation's names, types, variables, entries, ...,
  sorted into buckets (one per file: a record goes to its source file's
  bucket under -CD, else to the main file's), the include files'
  buckets merged where they refer to each other (a DAG of strongly
  connected components) and ordered so that a section is written after
  the sections it refers to; each bucket is written as a section of
  DST records (dst.ins.pas): a header, the string table, the include
  table, the local file table, the records in their order with their
  auxiliary records, the location pool (the main section), then each
  record's references filled in.  An include file's section is named
  `.s.' and the CRC of its bytes, the main one `.symbols'.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x069B08  0x06B4E8  alloc_rec (internal)
    0x069B78  0x06B558  alloc_aux_rec (internal)
    0x069BEC  0x06B5CC  make_aux_field_off_rec (internal)
    0x069C60  0x06B640  pds_$make_name
    0x069CE8  0x06B6C8  pds_$make_src_loc
    0x069DB4  0x06B794  pds_$make_loc
    0x069EB4  0x06B894  pds_$make_type
    0x069FE2  0x06B9C2  pds_$make_pointer_rec
    0x06A082  0x06BA62  pds_$make_var_attr
    0x06A0A4  0x06BA84  pds_$add_var_attr
    0x06A18C  0x06BB6C  pds_$make_variable_rec
    0x06A284  0x06BC64  pds_$add_var_loc
    0x06A324  0x06BD04  pds_$make_entry_rec
    0x06A410  0x06BDF0  pds_$add_entry_point_loc
    0x06A4B8  0x06BE98  pds_$make_signature_rec
    0x06A524  0x06BF04  pds_$make_arg_attr
    0x06A546  0x06BF26  pds_$add_arg_attr
    0x06A5EA  0x06BFCA  pds_$make_arg
    0x06A66C  0x06C04C  pds_$add_arg_to_signature
    0x06A7D4  0x06C1B4  pds_$make_alias_rec
    0x06A864  0x06C244  pds_$add_dependent_type_to_alias_rec
    0x06A994  0x06C374  pds_$make_file_entry
    0x06AA0C  0x06C3EC  pds_$make_file_table
    0x06AA7C  0x06C45C  pds_$add_file_entry
    0x06ABF4  0x06C5D4  pds_$make_label_rec
    0x06AC84  0x06C664  pds_$add_label_loc
    0x06AD2C  0x06C70C  pds_$make_constant_value
    0x06AD80  0x06C760  pds_$make_constant_rec
    0x06AEA8  0x06C888  pds_$make_set_rec
    0x06AFC0  0x06C9A0  pds_$make_subrange_rec
    0x06B0B4  0x06CA94  pds_$make_file_rec
    0x06B154  0x06CB34  pds_$make_offset_rec
    0x06B2A8  0x06CC88  pds_$make_implicit_enum_rec
    0x06B390  0x06CD70  pds_$add_implicit_enum_element
    0x06B510  0x06CEF0  pds_$make_explicit_enum_rec
    0x06B57C  0x06CF5C  pds_$make_explicit_enum_element
    0x06B600  0x06CFE0  pds_$add_explicit_enum_element
    0x06B780  0x06D160  pds_$make_short_record_rec
    0x06B810  0x06D1F0  pds_$make_short_field
    0x06B8CA  0x06D2AA  pds_$add_short_field
    0x06BA4C  0x06D42C  pds_$make_record_rec
    0x06BADC  0x06D4BC  pds_$make_field
    0x06BC7C  0x06D65C  pds_$add_field
    0x06BE00  0x06D7E0  pds_$make_array_rec
    0x06BF2E  0x06D90E  pds_$make_string_rec
    0x06C02E  0x06DA0E  pds_$make_aux_reg_val_rec
    0x06C0B0  0x06DA90  pds_$make_aux_size_rec
    0x06C0DC  0x06DABC  pds_$make_aux_field_size_rec
    0x06C15C  0x06DB3C  pds_$make_aux_align_rec
    0x06C18A  0x06DB6A  pds_$make_aux_field_align_rec
    0x06C20C  0x06DBEC  pds_$make_aux_var_bound_rec
    0x06C24A  0x06DC2A  pds_$make_aux_type_deriv_rec
    0x06C2D8  0x06DCB8  pds_$make_aux_lifetime_rec
    0x06C346  0x06DD26  pds_$make_aux_ptr_base_rec
    0x06C400  0x06DDE0  pds_$add_aux_rec
    0x06C4AC  0x06DE8C  pds_$get_scope_offset_within_section
    0x06C6B4  0x06E094  get_offset_within_section (internal)
    0x06C834  0x06E214  get_bucket (internal)
    0x06C8AE  0x06E28E  make_incl_start_scope_rec (internal)
    0x06C96C  0x06E34C  make_incl_end_scope_rec (internal)
    0x06C986  0x06E366  make_end_scope_rec (internal)
    0x06C9A0  0x06E380  pds_$initialize
    0x06CADC  0x06E4BC  pds_$enter_main_file_table
    0x06CBE8  0x06E5C8  pds_$finalize
    0x06CC1E  0x06E5FE  pds_$begin_scope
    0x06CC64  0x06E644  get_bucket_index (internal)
    0x06CD08  0x06E6E8  get_name_p (internal)
    0x06CE2C  0x06E80C  memcmp (internal)
    0x06CE6A  0x06E84A  compare_bytes_case (internal)
    0x06CF68  0x06E948  append_root_rec_to_bucket (internal)
    0x06CFBC  0x06E99C  order_root_rec_in_bucket (internal)
    0x06D1B0  0x06EB90  process_symbols_rec (internal)
    0x06D68C  0x06F06C  pds_$enter_named_record_current_scope
    0x06D790  0x06F170  pds_$end_scope
    0x06D892  0x06F272  allocate_dst_rec (internal)
    0x06D97C  0x06F35C  hash_it (internal)
    0x06D9A6  0x06F386  downcase_string (internal)
    0x06D9EA  0x06F3CA  add_str (internal)
    0x06DA9C  0x06F47C  add_string (internal)
    0x06DABE  0x06F49E  add_file_string (internal)
    0x06DADE  0x06F4BE  pool_strings (internal)
    0x06DC7C  0x06F65C  create_new_crc_table_entry (internal)
    0x06DD52  0x06F732  get_include_table_index (internal)
    0x06DDCE  0x06F7AE  add_crc_entry (internal)
    0x06DE06  0x06F7E6  add_crc_entry_for_type_ref (internal)
    0x06DF50  0x06F930  pool_crc_entries (internal)
    0x06E16C  0x06FB4C  dump_string_table (internal)
    0x06E310  0x06FCF0  dump_loc_pool (internal)
    0x06E386  0x06FD66  dump_aux_recs (internal)
    0x06E606  0x06FFE6  dump_rec (internal)
    0x06EA3A  0x07041A  get_dtc (internal)
    0x06EB0C  0x0704EC  get_arg_attrs (internal)
    0x06EBEA  0x0705CA  get_var_attrs (internal)
    0x06ECC2  0x0706A2  make_include_rec_ref (internal)
    0x06EE2E  0x07080E  make_relative_ref (internal)
    0x06EE74  0x070854  make_rec_ref (internal)
    0x06EFF6  0x0709D6  make_type_ref (internal)
    0x06F254  0x070C34  make_name_ref (internal)
    0x06F31A  0x070CFA  make_loc_ref (internal)
    0x06F3EA  0x070DCA  make_loc_ref_from_aux (internal)
    0x06F4CC  0x070EAC  make_name_ref_from_aux (internal)
    0x06F5A4  0x070F84  make_rec_ref_from_aux (internal)
    0x06F79A  0x07117A  make_type_ref_from_aux (internal)
    0x06F9EE  0x0713CE  add_aux_references (internal)
    0x06FC9C  0x07167C  add_references (internal)
    0x0707C2  0x0721A2  dump_incl_table (internal)
    0x07090E  0x0722EE  sprinkle_incl_end_scope_recs (internal)
    0x07096C  0x07234C  do_dfs_ordering (internal)
    0x070A74  0x072454  do_merge (internal)
    0x070BA6  0x072586  append_to_merge_list (internal)
    0x070D0A  0x0726EA  add_to_dag (internal)
    0x070D42  0x072722  dag_visit (internal)
    0x070E8E  0x07286E  build_dependency_graph (internal)
    0x070F4A  0x07292A  construct_a_dag (internal)
    0x070FD8  0x0729B8  pds_$create_symbols_sections
    0x0711B2  0x072B92  calculate_crc (internal)
    0x071346  0x072D26  add_local_file_entry (internal)
    0x07147C  0x072E5C  pool_local_file_table_entries (internal)
    0x07158C  0x072F6C  dump_section_header (internal)
    0x0715CA  0x072FAA  dump_local_file_table (internal)
    0x0716DE  0x0730BE  append_ordered_rec_to_bucket (internal)
    0x07172A  0x07310A  order_this_rec (internal)
    0x07192A  0x07330A  construct_ordered_rec_list (internal)
    0x071966  0x073346  pds_$dump_symbols_section
    A5 0x14B814 (cc.m68k), 0x2CB884 (cc.a88k): the module's data, 96
    bytes (below).

  Module data (as the image lays it out; dpc gives the boolean at +80
  its own word, so the cells after it lie 2 bytes higher there):
    +0 the DAG's tail, +4 its head (lists of buckets); +8 the DAG
    stack, +12 the visit numbers (words); +16 the bucket being written;
    +20 the section order's tail, +24 its head; +28 the main file
    table; +32 the location pool's offset in the object file; +36 the
    location pool; +40 the dump_loc function (stored only); +44 the
    object file's allocator; +48 the current scope's first record;
    +52 the merge pool, +56 the scope's mark, +60 the scope pool, +64
    the general pool; +68 the files the scope refers to; +72 the
    buckets (by file); +76 the number of files; +78 the main file's
    index; +80 whether names compare ignoring case; +84 the merge
    list's tail, +88 its head; +92 the DAG stack's depth; +94 the visit
    counter.

  Every routine named PDS_$ is global and loads A5; the others do not
  (internal).  Every check is a BUG_CHECK with the routine's name in
  the message (the internal routines' names written `\\PDS_\name').

  Not known from the original: the names of the module's variables and
  of every local; the parameter names but those the messages give.
  Range checks the image makes unsigned (`bls', `bhi') are written as
  comparisons of the headings' signed types; the values the callers
  pass are in range.

  dpc gaps: a pointer function's result compared with a variable
  (docs/dpc-gaps.md 11: append_root_rec_to_bucket,
  append_to_merge_list); tests of the 2048-element bitmaps
  (docs/dpc-gaps.md 12: pds_$end_scope, do_merge, dag_visit,
  build_dependency_graph).
}
module pds;

%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/sys/ins/dst.ins.pas';
%include 'lang/common/source/pds.ins.pas';
%include 'lang/common/source/pds.pvt.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'us1/us1/lib/dblib/loc/src/loc_build.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cargs.ins.pas';
%include 'lang/lang/source/real_globals.ins.pas';
%include 'lang/lang/source/config_misc.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'lang/common/source/htm.ins.pas';

var
  dag_tail: bucket_list_p_t;            { +0 }
  dag_head: bucket_list_p_t;            { +4 }
  dag_stack: words_p_t;                 { +8 }
  visit_numbers: words_p_t;             { +12 }
  current_bucket: bucket_p_t;           { +16 }
  dfs_tail: bucket_p_t;                 { +20 }
  dfs_head: bucket_p_t;                 { +24 }
  main_file_table: file_table_p_t;      { +28 }
  loc_pool_base: integer32;             { +32 }
  loc_pool: univ_ptr;                   { +36 }
  dump_loc_func: univ_ptr;              { +40 }
  alloc_obj_func: pds_$alloc_obj_func_t;    { +44 }
  scope_start: rec_p_t;                 { +48 }
  merge_pool: mem_$pool_t;              { +52 }
  scope_mark: mem_$mark_t;              { +56 }
  scope_pool: mem_$pool_t;              { +60 }
  general_pool: mem_$pool_t;            { +64 }
  scope_refs: bits_p_t;                 { +68 }
  bucket_table: bucket_table_p_t;       { +72 }
  nfiles: integer;                      { +76 }
  main_index: integer;                  { +78 }
  case_fold: boolean;                   { +80 }
  merge_tail: bucket_list_p_t;          { +84 }
  merge_head: bucket_list_p_t;          { +88 }
  dag_depth: integer;                   { +92 }
  visit_count: integer;                 { +94 }

{ alloc_rec - a record of size bytes from the general pool, its kind
  set.

  0x069B08, 0x4A bytes: MEM_$ALLOC of the size (zero-extended); a nil
  result is a BUG_CHECK; the kind stored at +0; the result in A0. }

function alloc_rec(
    kind: integer;
    size: rec_size_t): rec_p_t; options(val_param); internal;
var
  r: rec_p_t;
begin
  r := mem_$alloc(general_pool, size);
  if r = nil then
    bug_check('\\PDS_\ALLOC_REC -- No free space.%$');
  r^.kind := kind;
  alloc_rec := r;
end;

{ alloc_aux_rec - an auxiliary record, as alloc_rec.  0x069B78, 0x4A
  bytes. }

function alloc_aux_rec(
    kind: integer;
    size: rec_size_t): aux_p_t; options(val_param); internal;
var
  a: aux_p_t;
begin
  a := mem_$alloc(general_pool, size);
  if a = nil then
    bug_check('\\PDS_\ALLOC_AUX_REC -- No free space.%$');
  a^.kind := kind;
  alloc_aux_rec := a;
end;

{ make_aux_field_off_rec - a field offset too large for its record.

  0x069BEC, 0x3E bytes: alloc_aux_rec(3, 26) (`move.l #0x3001A'); the
  field's number at +20, the offset at +22; the result left in A0. }

function make_aux_field_off_rec(
    field_num: integer;
    offset: integer32): aux_p_t; options(val_param); internal;
var
  a: aux_p_t;
begin
  if field_num = 0 then
    bug_check('\\PDS_\MAKE_AUX_FIELD_OFF_REC -- field num is zero.%$');
  a := alloc_aux_rec(aux_field_off, 26);
  a^.w20 := field_num;
  a^.l22 := offset;
  make_aux_field_off_rec := a;
end;

{ pds_$make_name - 0x069C60, 0x60 bytes: len + 6 bytes (word arithmetic,
  zero-extended); the length at +0, the characters from +6 (a `for'
  from 1, `dbf'); the result in D0. }

function pds_$make_name(
    in chars: univ pds_$chars_t;
    len: integer): univ_ptr;
var
  n: name_p_t;
  i: integer;
begin
  if len = 0 then
    bug_check('PDS_$MAKE_NAME -- zero length string.%$');
  n := mem_$alloc(general_pool, len + 6);
  n^.len := len;
  for i := 1 to n^.len do
    n^.chars[i] := chars[i];
  pds_$make_name := n;
end;

{ pds_$make_src_loc - 0x069CE8, 0x64 bytes: file_index above 2047 and
  line above 1048575 (unsigned) are BUG_CHECKs; 6 bytes: the index at
  +0, the line at +2. }

function pds_$make_src_loc(
    file_index: integer;
    line: integer32): univ_ptr;
var
  s: src_loc_p_t;
begin
  if file_index > 2047 then
    bug_check('PDS_$MAKE_SRC_LOC -- file_index is out of range.%$');
  if line > 1048575 then
    bug_check('PDS_$MAKE_SRC_LOC -- line_number is out of range.%$');
  s := mem_$alloc(general_pool, 6);
  s^.file_index := file_index;
  s^.line := line;
  pds_$make_src_loc := s;
end;

{ pds_$make_loc - 0x069DB4, 0x80 bytes: the first pool is kept (+36);
  another one is a BUG_CHECK; 8 bytes: the pool, the offset. }

function pds_$make_loc(
    loc_pool_handle: univ_ptr;
    offset: integer32): univ_ptr;
var
  l: loc_p_t;
begin
  if loc_pool_handle = nil then
    bug_check('PDS$MAKE_LOC -- loc_pool_handle is NIL.%$');
  if offset < 0 then
    bug_check('PDS$MAKE_LOC -- negative offset.%$');
  if (loc_pool <> nil) and (loc_pool <> loc_pool_handle) then
    bug_check('PDS$MAKE_LOC -- No support for multiple loc pools.%$');
  if loc_pool = nil then
    loc_pool := loc_pool_handle;
  l := mem_$alloc(general_pool, 8);
  l^.pool := loc_pool_handle;
  l^.offset := offset;
  pds_$make_loc := l;
end;

{ pds_$make_type - 0x069EB4, 0x80 bytes: three checks of the code (22,
  user defined, compared unsigned for the range); 6 bytes: the code,
  the record. }

function pds_$make_type(
    type_code: integer;
    rec_p: univ_ptr): univ_ptr;
var
  t: type_p_t;
begin
  if (type_code <> user_type_code) and (rec_p <> nil) then
    bug_check('PDS_$MAKE_TYPE -- std types don''t have dependent record.%$');
  if (type_code = user_type_code) and (rec_p = nil) then
    bug_check('PDS_$MAKE_TYPE -- Must have dependent record for user defined types.%$');
  if type_code > user_type_code then
    bug_check('PDS_$MAKE_TYPE -- type_code is out of range.%$');
  t := mem_$alloc(general_pool, 6);
  t^.code := type_code;
  t^.rec := rec_p;
  pds_$make_type := t;
end;

{ pds_$make_pointer_rec - 0x069FE2, 0x6A bytes: a nil source location
  is pds_$make_src_loc(0, 0) (`bsr', the result from D0); alloc_rec(0,
  44), the size through a local (`move.w #44,(-10,A6)'); +32 the name,
  +36 the location, +40 the type. }

function pds_$make_pointer_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if type_desc_p = nil then
    bug_check('PDS_$MAKE_POINTER_REC -- type_desc_p may not be NIL.%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 44;
  r := alloc_rec(pointer_kind, size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  r^.type_p := type_desc_p;
  pds_$make_pointer_rec := r;
end;

{ pds_$make_var_attr - 0x06A082, 0x22 bytes: 2 bytes from the general
  pool, the result left in A0 (a typed pointer). }

function pds_$make_var_attr: pds_$attrs_p_t;
begin
  pds_$make_var_attr := mem_$alloc(general_pool, 2);
end;

{ pds_$add_var_attr - 0x06A0A4, 0x66 bytes: the variable's attribute set
  (+48) or'd with the bit (`bset Dn,D0; or.w D0,(A0)'); attrib above 4
  (unsigned) a BUG_CHECK. }

procedure pds_$add_var_attr(
    var_p: univ_ptr;
    attrib: integer);
var
  r: rec_p_t;
begin
  r := var_p;
  if r = nil then
    bug_check('PDS_$ADD_VAR_ATTR -- var_p is NIL.%$');
  if r^.kind <> variable_kind then
    bug_check('PDS_$ADD_VAR_ATTR -- var_p is not a variable.%$');
  if attrib > 4 then
    bug_check('PDS_$ADD_VAR_ATTR -- attrib is out of range.%$');
  r^.var_attrs^ := r^.var_attrs^ + [attrib];
end;

{ pds_$make_variable_rec - 0x06A18C, 0x8A bytes: alloc_rec(14, 52); +32
  the name, +36 the location, +40 the source location, +44 the type,
  +48 the attributes. }

function pds_$make_variable_rec(
    name_p: univ_ptr;
    loc_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr;
    attr_p: pds_$attrs_p_t): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_VARIABLE_REC -- variable with no name???%$');
  if type_desc_p = nil then
    bug_check('PDS_$MAKE_VARIABLE_REC -- type_desc_p may not be NIL.%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 52;
  r := alloc_rec(variable_kind, size);
  r^.name := name_p;
  r^.loc := loc_p;
  r^.obj_src_loc := src_loc_p;
  r^.var_type := type_desc_p;
  r^.var_attrs := attr_p;
  pds_$make_variable_rec := r;
end;

{ pds_$add_var_loc - 0x06A284, 0x4E bytes. }

procedure pds_$add_var_loc(
    var_p: univ_ptr;
    loc_p: univ_ptr);
var
  r: rec_p_t;
begin
  r := var_p;
  if r = nil then
    bug_check('PDS_$ADD_VAR_LOC -- var_p is NIL.%$');
  if r^.kind <> variable_kind then
    bug_check('PDS_$ADD_VAR_LOC -- var_p is not a variable.%$');
  r^.loc := loc_p;
end;

{ pds_$make_entry_rec - 0x06A324, 0x8A bytes: alloc_rec(16, 50); +32 the
  name, +36 the location, +40 the source location, +44 the signature,
  +48 the word. }

function pds_$make_entry_rec(
    name_p: univ_ptr;
    loc_p: univ_ptr;
    src_loc_p: univ_ptr;
    sig_p: univ_ptr;
    w48: integer): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_ENTRY_REC -- entry with no name???%$');
  if sig_p = nil then
    bug_check('PDS_$MAKE_ENTRY_REC -- no signature description??%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 50;
  r := alloc_rec(entry_kind, size);
  r^.name := name_p;
  r^.loc := loc_p;
  r^.obj_src_loc := src_loc_p;
  r^.signature := sig_p;
  r^.entry_w48 := w48;
  pds_$make_entry_rec := r;
end;

{ pds_$add_entry_point_loc - 0x06A410, 0x4E bytes. }

procedure pds_$add_entry_point_loc(
    entry_p: univ_ptr;
    loc_p: univ_ptr);
var
  r: rec_p_t;
begin
  r := entry_p;
  if r = nil then
    bug_check('PDS_$ADD_ENTRY_LOC -- entry_p is NIL.%$');
  if r^.kind <> entry_kind then
    bug_check('PDS_$ADD_ENTRY_LOC -- entry_p is not an entry.%$');
  r^.loc := loc_p;
end;

{ pds_$make_signature_rec - 0x06A4B8, 0x6C bytes: alloc_rec(17, nargs *
  4 + 46) (word arithmetic); +32 the name, +36 the source location,
  +40 the result, +44 nargs. }

function pds_$make_signature_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    result_p: univ_ptr;
    nargs: integer): univ_ptr;
var
  r: rec_p_t;
  s: src_loc_p_t;
  size: integer;
begin
  if src_loc_p = nil then
    s := pds_$make_src_loc(0, 0)
  else
    s := src_loc_p;
  size := nargs * 4 + 46;
  r := alloc_rec(signature_kind, size);
  r^.name := name_p;
  r^.sig_src_loc := s;
  r^.sig_result := result_p;
  r^.nargs := nargs;
  pds_$make_signature_rec := r;
end;

{ pds_$make_arg_attr - 0x06A524, 0x22 bytes: as pds_$make_var_attr. }

function pds_$make_arg_attr: pds_$attrs_p_t;
begin
  pds_$make_arg_attr := mem_$alloc(general_pool, 2);
end;

{ pds_$add_arg_attr - 0x06A546, 0x50 bytes: attrib above 5 (unsigned) a
  BUG_CHECK. }

procedure pds_$add_arg_attr(
    attr_p: pds_$attrs_p_t;
    attrib: integer);
begin
  if attr_p = nil then
    bug_check('PDS_$ADD_ARG_ATTR -- attr_p is NIL.%$');
  if attrib > 5 then
    bug_check('PDS_$ADD_ARG_ATTR -- attrib is out of range.%$');
  attr_p^ := attr_p^ + [attrib];
end;

{ pds_$make_arg - 0x06A5EA, 0x54 bytes: 8 bytes, the variable and the
  attributes. }

function pds_$make_arg(
    var_p: univ_ptr;
    attr_p: pds_$attrs_p_t): univ_ptr;
var
  a: arg_p_t;
begin
  if attr_p = nil then
    bug_check('PDS_$MAKE_ARG -- arg must have attribute.%$');
  a := mem_$alloc(general_pool, 8);
  a^.var_rec := var_p;
  a^.attrs := attr_p;
  pds_$make_arg := a;
end;

{ pds_$add_arg_to_signature - 0x06A66C, 0x74 bytes: arg_num compared
  unsigned with nargs (+44); the argument at +42 + 4 * arg_num. }

procedure pds_$add_arg_to_signature(
    sig_p: univ_ptr;
    arg_num: integer;
    arg_p: univ_ptr);
var
  r: rec_p_t;
begin
  r := sig_p;
  if r = nil then
    bug_check('PDS_$ADD_ARG_TO_SIGNATURE -- sig_p is NIL.%$');
  if r^.kind <> signature_kind then
    bug_check('PDS_$ADD_ARG_TO_SIGNATURE -- sig_p does not point to a signature.%$');
  if arg_num > r^.nargs then
    bug_check('PDS_$ADD_ARG_TO_SIGNATURE -- arg_num is greater than number of params in signature.%$');
  if arg_p = nil then
    bug_check('PDS_$ADD_ARG_TO_SIGNATURE -- arg_p is NIL.%$');
  r^.args[arg_num] := arg_p;
end;

{ pds_$make_alias_rec - 0x06A7D4, 0x6A bytes: alloc_rec(11, 44). }

function pds_$make_alias_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_ALIAS_REC -- no name????.%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 44;
  r := alloc_rec(alias_kind, size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  pds_$make_alias_rec := r;
end;

{ pds_$add_dependent_type_to_alias_rec - 0x06A864, 0x60 bytes: the type
  at +40. }

procedure pds_$add_dependent_type_to_alias_rec(
    rec_p: univ_ptr;
    type_desc_p: univ_ptr);
var
  r: rec_p_t;
begin
  r := rec_p;
  if r = nil then
    bug_check('PDS_$ADD_DEPENDENT_TYPE_TO_ALIAS_REC -- rec_p may not be NIL.%$');
  if r^.kind <> alias_kind then
    bug_check('PDS_$ADD_DEPENDENT_TYPE_TO_ALIAS_REC -- rec_p is not an alias record.%$');
  if type_desc_p = nil then
    bug_check('PDS_$ADD_DEPENDENT_TYPE_TO_ALIAS_REC -- type_desc_p may not be NIL.%$');
  r^.type_p := type_desc_p;
end;

{ pds_$make_file_entry - 0x06A994, 0x50 bytes: 8 bytes, the id and the
  name. }

function pds_$make_file_entry(
    name_p: univ_ptr;
    id: integer32): univ_ptr;
var
  e: file_entry_p_t;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_FILE_ENTRY -- name_p is NIL.%$');
  e := mem_$alloc(general_pool, 8);
  e^.id := id;
  e^.name := name_p;
  pds_$make_file_entry := e;
end;

{ pds_$make_file_table - 0x06AA0C, 0x4C bytes: nfiles * 4 + 4 bytes
  (word arithmetic); the main index stored first. }

function pds_$make_file_table(
    nfiles: integer;
    main_index: integer): univ_ptr;
var
  t: file_table_p_t;
begin
  if nfiles = 0 then
    bug_check('PDS_$MAKE_FILE_TABLE -- 0 files???%$');
  t := mem_$alloc(general_pool, nfiles * 4 + 4);
  t^.main_index := main_index;
  t^.nfiles := nfiles;
  pds_$make_file_table := t;
end;

{ pds_$add_file_entry - 0x06AA7C, 0x80 bytes: index above 2047 and above
  nfiles compared unsigned. }

procedure pds_$add_file_entry(
    file_table_p: univ_ptr;
    index: integer;
    file_entry_p: univ_ptr);
var
  t: file_table_p_t;
begin
  t := file_table_p;
  if t = nil then
    bug_check('PDS_$ADD_FILE_ENTRY -- file_table_p is NIL.%$');
  if file_entry_p = nil then
    bug_check('PDS_$ADD_FILE_ENTRY -- file_entry_p is NIL.%$');
  if index > 2047 then
    bug_check('PDS_$ADD_FILE_ENTRY -- file index is out of range.%$');
  if index = 0 then
    bug_check('PDS_$ADD_FILE_ENTRY -- file index is NIL.%$');
  if index > t^.nfiles then
    bug_check('PDS_$ADD_FILE_ENTRY -- file index exceeds number of files.%$');
  t^.entries[index] := file_entry_p;
end;

{ pds_$make_label_rec - 0x06ABF4, 0x6A bytes: alloc_rec(15, 44); +32
  the name, +36 the location, +40 the source location. }

function pds_$make_label_rec(
    name_p: univ_ptr;
    loc_p: univ_ptr;
    src_loc_p: univ_ptr): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_LABEL_REC -- no name????.%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 44;
  r := alloc_rec(label_kind, size);
  r^.name := name_p;
  r^.loc := loc_p;
  r^.obj_src_loc := src_loc_p;
  pds_$make_label_rec := r;
end;

{ pds_$add_label_loc - 0x06AC84, 0x4E bytes. }

procedure pds_$add_label_loc(
    label_p: univ_ptr;
    loc_p: univ_ptr);
var
  r: rec_p_t;
begin
  r := label_p;
  if r = nil then
    bug_check('PDS_$ADD_LABEL_LOC -- label_p is NIL.%$');
  if r^.kind <> label_kind then
    bug_check('PDS_$ADD_LABEL_LOC -- label_p is not a label.%$');
  r^.loc := loc_p;
end;

{ pds_$make_constant_value - 0x06AD2C, 0x54 bytes: len + 2 bytes (word
  arithmetic); the length, the bytes from +2. }

function pds_$make_constant_value(
    in bytes: univ pds_$chars_t;
    len: integer): univ_ptr;
var
  v: value_p_t;
  i: integer;
begin
  v := mem_$alloc(general_pool, len + 2);
  v^.len := len;
  for i := 1 to v^.len do
    v^.bytes[i] := bytes[i];
  pds_$make_constant_value := v;
end;

{ pds_$make_constant_rec - 0x06AD80, 0x92 bytes: alloc_rec(13, 48); +40
  the type, +44 the value. }

function pds_$make_constant_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr;
    value_p: univ_ptr): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_CONSTANT_REC -- no name????.%$');
  if type_desc_p = nil then
    bug_check('PDS_$MAKE_CONSTANT_REC -- type_desc_p may not be NIL.%$');
  if value_p = nil then
    bug_check('PDS_$MAKE_CONSTANT_REC -- value_p may not be NIL.%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 48;
  r := alloc_rec(constant_kind, size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  r^.type_p := type_desc_p;
  r^.value := value_p;
  pds_$make_constant_rec := r;
end;

{ pds_$make_set_rec - 0x06AEA8, 0x9C bytes: alloc_rec(4, 48); +44 the
  elements, +46 the size. }

function pds_$make_set_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr;
    size: integer;
    nelements: integer): univ_ptr;
var
  r: rec_p_t;
  rec_size: integer;
begin
  if type_desc_p = nil then
    bug_check('PDS_$MAKE_SET_REC -- type_desc_p may not be NIL.%$');
  if size = 0 then
    bug_check('PDS_$MAKE_SET_REC -- zero size???%$');
  if nelements = 0 then
    bug_check('PDS_$MAKE_SET_REC -- no elements???%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  rec_size := 48;
  r := alloc_rec(set_kind, rec_size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  r^.type_p := type_desc_p;
  r^.set_nelements := nelements;
  r^.set_size := size;
  pds_$make_set_rec := r;
end;

{ pds_$make_subrange_rec - 0x06AFC0, 0x94 bytes: alloc_rec(3, 54); +44,
  +48 the bounds' longwords, +52 the size. }

function pds_$make_subrange_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr;
    l44: integer32;
    l48: integer32;
    size: integer): univ_ptr;
var
  r: rec_p_t;
  rec_size: integer;
begin
  if type_desc_p = nil then
    bug_check('PDS_$MAKE_SUBRANGE_REC -- type_desc_p may not be NIL.%$');
  if size = 0 then
    bug_check('PDS_$MAKE_SUBRANGE_REC -- zero size???%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  rec_size := 54;
  r := alloc_rec(subrange_kind, rec_size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  r^.type_p := type_desc_p;
  r^.sub_l44 := l44;
  r^.sub_l48 := l48;
  r^.sub_size := size;
  pds_$make_subrange_rec := r;
end;

{ pds_$make_file_rec - 0x06B0B4, 0x6C bytes: alloc_rec(9, 44). }

function pds_$make_file_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    type_desc_p: univ_ptr): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if type_desc_p = nil then
    bug_check('PDS_$MAKE_FILE_REC -- type_desc_p may not be NIL.%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 44;
  r := alloc_rec(file_kind, size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  r^.type_p := type_desc_p;
  pds_$make_file_rec := r;
end;

{ pds_$make_offset_rec - 0x06B154, 0x9C bytes: alloc_rec(10, 64); +40
  the area's type, +44 the base's, +48, +52, +56 longwords, +60 a word,
  +62 the size. }

function pds_$make_offset_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    area_type_desc_p: univ_ptr;
    base_type_desc_p: univ_ptr;
    l48: integer32;
    l52: integer32;
    w60: integer;
    l56: integer32;
    size: integer): univ_ptr;
var
  r: rec_p_t;
  rec_size: integer;
begin
  if area_type_desc_p = nil then
    bug_check('PDS_$MAKE_OFFSET_REC -- area_type_desc_p may not be NIL.%$');
  if base_type_desc_p = nil then
    bug_check('PDS_$MAKE_OFFSET_REC -- base_type_desc_p may not be NIL.%$');
  if size = 0 then
    bug_check('PDS_$MAKE_OFFSET_REC -- zero size???%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  rec_size := 64;
  r := alloc_rec(offset_kind, rec_size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  r^.type_p := area_type_desc_p;
  r^.type2 := base_type_desc_p;
  r^.l48 := l48;
  r^.l52 := l52;
  r^.l56 := l56;
  r^.w60 := w60;
  r^.w62 := size;
  pds_$make_offset_rec := r;
end;

{ pds_$make_implicit_enum_rec - 0x06B2A8, 0x88 bytes: alloc_rec(5,
  nelements * 4 + 44) (word arithmetic); +40 the elements, +42 the
  size. }

function pds_$make_implicit_enum_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    size: integer;
    nelements: integer): univ_ptr;
var
  r: rec_p_t;
  rec_size: integer;
begin
  if size = 0 then
    bug_check('PDS_$MAKE_IMPLICIT_ENUM_REC -- zero size???%$');
  if nelements = 0 then
    bug_check('PDS_$MAKE_IMPLICIT_ENUM_REC -- no elements???%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  rec_size := nelements * 4 + 44;
  r := alloc_rec(implicit_enum_kind, rec_size);
  r^.name := name_p;
  r^.agg_src_loc := src_loc_p;
  r^.enum_nelements := nelements;
  r^.enum_size := size;
  pds_$make_implicit_enum_rec := r;
end;

{ pds_$add_implicit_enum_element - 0x06B390, 0x78 bytes: one check of
  nil and the kind (`beq' to the same BUG_CHECK); enum_pos compared
  unsigned; the name at +40 + 4 * enum_pos. }

procedure pds_$add_implicit_enum_element(
    enum_rec_p: univ_ptr;
    enum_pos: integer;
    name_p: univ_ptr);
var
  r: rec_p_t;
begin
  r := enum_rec_p;
  if (r = nil) or (r^.kind <> implicit_enum_kind) then
    bug_check('PDS_$ADD_IMPLICIT_ENUM_ELEMENT -- enum_rec_p must point to an implicit enum rec.%$');
  if enum_pos = 0 then
    bug_check('PDS_$ADD_IMPLICIT_ENUM_ELEMENT -- enum_pos is zero (NIL).%$');
  if enum_pos > r^.enum_nelements then
    bug_check('PDS_$ADD_IMPLICIT_ENUM_ELEMENT -- enum_pos exceeds number of elements.%$');
  if name_p = nil then
    bug_check('PDS_$ADD_IMPLICIT_ENUM_ELEMENT -- name_p is NIL.%$');
  r^.implicit[enum_pos] := name_p;
end;

{ pds_$make_explicit_enum_rec - 0x06B510, 0x6C bytes: alloc_rec(6,
  nelements * 8 + 44) (8 bytes an element, though each takes a
  pointer); no checks. }

function pds_$make_explicit_enum_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    size: integer;
    nelements: integer): univ_ptr;
var
  r: rec_p_t;
  s: src_loc_p_t;
  rec_size: integer;
begin
  if src_loc_p = nil then
    s := pds_$make_src_loc(0, 0)
  else
    s := src_loc_p;
  rec_size := nelements * 8 + 44;
  r := alloc_rec(explicit_enum_kind, rec_size);
  r^.name := name_p;
  r^.agg_src_loc := s;
  r^.enum_nelements := nelements;
  r^.enum_size := size;
  pds_$make_explicit_enum_rec := r;
end;

{ pds_$make_explicit_enum_element - 0x06B57C, 0x50 bytes: 8 bytes, the
  name and the value. }

function pds_$make_explicit_enum_element(
    name_p: univ_ptr;
    value: integer32): univ_ptr;
var
  e: element_p_t;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_EXPLICIT_ENUM_ELEMENT -- name_p is NIL.%$');
  e := mem_$alloc(general_pool, 8);
  e^.name := name_p;
  e^.value := value;
  pds_$make_explicit_enum_element := e;
end;

{ pds_$add_explicit_enum_element - 0x06B600, 0x78 bytes: as the
  implicit one's. }

procedure pds_$add_explicit_enum_element(
    enum_rec_p: univ_ptr;
    enum_pos: integer;
    enum_p: univ_ptr);
var
  r: rec_p_t;
begin
  r := enum_rec_p;
  if (r = nil) or (r^.kind <> explicit_enum_kind) then
    bug_check('PDS_$ADD_EXPLICIT_ENUM_ELEMENT -- enum_rec_p must point to an explicit enum rec.%$');
  if enum_pos = 0 then
    bug_check('PDS_$ADD_EXPLICIT_ENUM_ELEMENT -- enum_pos is zero (NIL).%$');
  if enum_pos > r^.enum_nelements then
    bug_check('PDS_$ADD_EXPLICIT_ENUM_ELEMENT -- enum_pos exceeds number of elements.%$');
  if enum_p = nil then
    bug_check('PDS_$ADD_EXPLICIT_ENUM_ELEMENT -- enum_p is NIL.%$');
  r^.explicit[enum_pos] := enum_p;
end;

{ pds_$make_short_record_rec - 0x06B780, 0x90 bytes: alloc_rec(7,
  nfields * 4 + 44); +40 the size (a word), +42 nfields; a size above
  65535 (unsigned) goes to pds_$make_aux_size_rec's record (`bsr', kept
  in (-4,A6)) and +40 is cleared. }

function pds_$make_short_record_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    size: integer32;
    nfields: integer): univ_ptr;
var
  r: rec_p_t;
  s: src_loc_p_t;
  rec_size: integer;
  aux: univ_ptr;
begin
  if src_loc_p = nil then
    s := pds_$make_src_loc(0, 0)
  else
    s := src_loc_p;
  rec_size := nfields * 4 + 44;
  r := alloc_rec(short_record_kind, rec_size);
  r^.name := name_p;
  r^.agg_src_loc := s;
  r^.rec_size := size;
  r^.rec_nfields := nfields;
  if size > 65535 then begin
    aux := pds_$make_aux_size_rec(size);
    pds_$add_aux_rec(r, aux);
    r^.rec_size := 0;
  end;
  pds_$make_short_record_rec := r;
end;

{ pds_$make_short_field - 0x06B810, 0x62 bytes: 12 bytes, the name, the
  type, the offset. }

function pds_$make_short_field(
    name_p: univ_ptr;
    type_desc_p: univ_ptr;
    offset: integer32): univ_ptr;
var
  f: short_field_p_t;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_SHORT_FIELD -- name_p is NIL.%$');
  if type_desc_p = nil then
    bug_check('PDS_$MAKE_SHORT_FIELD -- type_desc_p is NIL.%$');
  f := mem_$alloc(general_pool, 12);
  f^.name := name_p;
  f^.type_p := type_desc_p;
  f^.offset := offset;
  pds_$make_short_field := f;
end;

{ pds_$add_short_field - 0x06B8CA, 0xA2 bytes: an offset above 65535
  (unsigned) goes to make_aux_field_off_rec's record (kept in (-4,A6)),
  the field's offset cleared. }

procedure pds_$add_short_field(
    rec_p: univ_ptr;
    field_num: integer;
    short_field_p: univ_ptr);
var
  r: rec_p_t;
  f: short_field_p_t;
  aux: aux_p_t;
begin
  r := rec_p;
  f := short_field_p;
  if (r = nil) or (r^.kind <> short_record_kind) then
    bug_check('PDS_$ADD_SHORT_FIELD -- rec_p must point to a short record.%$');
  if field_num = 0 then
    bug_check('PDS_$ADD_SHORT_FIELD -- field_num is zero (NIL).%$');
  if field_num > r^.rec_nfields then
    bug_check('PDS_$ADD_SHORT_FIELD -- field_num exceeds number of elements.%$');
  if f = nil then
    bug_check('PDS_$ADD_SHORT_FIELD -- short_field_p is NIL.%$');
  if f^.offset > 65535 then begin
    aux := make_aux_field_off_rec(field_num, f^.offset);
    f^.offset := 0;
    pds_$add_aux_rec(r, aux);
  end;
  r^.short_fields[field_num] := f;
end;

{ pds_$make_record_rec - 0x06BA4C, 0x90 bytes: as
  pds_$make_short_record_rec, alloc_rec(8, ...). }

function pds_$make_record_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    size: integer32;
    nfields: integer): univ_ptr;
var
  r: rec_p_t;
  s: src_loc_p_t;
  rec_size: integer;
  aux: univ_ptr;
begin
  if src_loc_p = nil then
    s := pds_$make_src_loc(0, 0)
  else
    s := src_loc_p;
  rec_size := nfields * 4 + 44;
  r := alloc_rec(record_kind, rec_size);
  r^.name := name_p;
  r^.agg_src_loc := s;
  r^.rec_size := size;
  r^.rec_nfields := nfields;
  if size > 65535 then begin
    aux := pds_$make_aux_size_rec(size);
    pds_$add_aux_rec(r, aux);
    r^.rec_size := 0;
  end;
  pds_$make_record_rec := r;
end;

{ pds_$make_field - 0x06BADC, 0xBE bytes: 20 bytes; format 0 stops after
  the format; format 1 checks nbits (above 63, unsigned) and
  start_bit_num (above 7) and stores them and the flag; another format
  is a BUG_CHECK. }

function pds_$make_field(
    name_p: univ_ptr;
    type_desc_p: univ_ptr;
    format: integer;
    offset: integer32;
    start_bit_num: integer;
    nbits: integer;
    flag: boolean): univ_ptr;
var
  f: field_p_t;
begin
  if name_p = nil then
    bug_check('PDS_$MAKE_FIELD -- name_p is NIL.%$');
  if type_desc_p = nil then
    bug_check('PDS_$MAKE_FIELD -- type_desc_p is NIL.%$');
  f := mem_$alloc(general_pool, 20);
  f^.name := name_p;
  f^.type_p := type_desc_p;
  f^.offset := offset;
  f^.format := format;
  if format <> 0 then
    if format = 1 then begin
      if nbits > 63 then
        bug_check('PDS_$MAKE_FIELD -- nbits is out of range.%$');
      f^.nbits := nbits;
      f^.flag := flag;
      if start_bit_num > 7 then
        bug_check('PDS_$MAKE_FIELD -- start_bit_num is out of range.%$');
      f^.start_bit := start_bit_num;
    end
    else
      bug_check('PDS_$MAKE_FIELD -- No support for this field format.%$');
  pds_$make_field := f;
end;

{ pds_$add_field - 0x06BC7C, 0xC6 bytes: the offset is too large (a
  boolean in D0, `st') above 16#3FFFFFFF for format 0, above 65535 for
  format 1 (both unsigned); then as pds_$add_short_field. }

procedure pds_$add_field(
    rec_p: univ_ptr;
    field_num: integer;
    field_p: univ_ptr);
var
  r: rec_p_t;
  f: field_p_t;
  aux: aux_p_t;
  too_large: boolean;
begin
  r := rec_p;
  f := field_p;
  if (r = nil) or (r^.kind <> record_kind) then
    bug_check('PDS_$ADD_FIELD -- rec_p must point to a record.%$');
  if field_num = 0 then
    bug_check('PDS_$ADD_FIELD -- field_num is zero (NIL).%$');
  if field_num > r^.rec_nfields then
    bug_check('PDS_$ADD_FIELD -- field_num exceeds number of elements.%$');
  if f = nil then
    bug_check('PDS_$ADD_FIELD -- field_p is NIL.%$');
  too_large := false;
  if (f^.format = 0) and (f^.offset > 16#3FFFFFFF) then
    too_large := true
  else if (f^.format = 1) and (f^.offset > 65535) then
    too_large := true;
  if too_large then begin
    aux := make_aux_field_off_rec(field_num, f^.offset);
    f^.offset := 0;
    pds_$add_aux_rec(r, aux);
  end;
  r^.fields[field_num] := f;
end;

{ pds_$make_array_rec - 0x06BE00, 0xCA bytes: alloc_rec(2, 74). }

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
    w72: integer): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if elem_type_desc_p = nil then
    bug_check('PDS_$MAKE_ARRAY_REC -- elem_type_desc_p is NIL.%$');
  if indx_type_desc_p = nil then
    bug_check('PDS_$MAKE_ARRAY_REC -- indx_type_desc_p is NIL.%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 74;
  r := alloc_rec(array_kind, size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  r^.type_p := elem_type_desc_p;
  r^.type2 := indx_type_desc_p;
  r^.l48 := l48;
  r^.l52 := l52;
  r^.l56 := l56;
  r^.l60 := l60;
  r^.b64 := b64;
  r^.b65 := b65;
  r^.b66 := b66;
  r^.span := span;
  r^.b70 := b70;
  r^.w72 := w72;
  pds_$make_array_rec := r;
end;

{ pds_$make_string_rec - 0x06BF2E, 0x9C bytes: alloc_rec(12, 60). }

function pds_$make_string_rec(
    name_p: univ_ptr;
    src_loc_p: univ_ptr;
    elem_type_desc_p: univ_ptr;
    indx_type_desc_p: univ_ptr;
    l48: integer32;
    l52: integer32;
    l56: integer32): univ_ptr;
var
  r: rec_p_t;
  size: integer;
begin
  if elem_type_desc_p = nil then
    bug_check('PDS_$MAKE_STRING_REC -- elem_type_desc_p is NIL.%$');
  if indx_type_desc_p = nil then
    bug_check('PDS_$MAKE_STRING_REC -- indx_type_desc_p is NIL.%$');
  if src_loc_p = nil then
    src_loc_p := pds_$make_src_loc(0, 0);
  size := 60;
  r := alloc_rec(string_kind, size);
  r^.name := name_p;
  r^.src_loc := src_loc_p;
  r^.type_p := elem_type_desc_p;
  r^.type2 := indx_type_desc_p;
  r^.l48 := l48;
  r^.l52 := l52;
  r^.l56 := l56;
  pds_$make_string_rec := r;
end;

{ The auxiliary record makers: alloc_aux_rec(kind, size) with the
  kind and size pushed as one longword (`move.l #...,-(SP)'). }

{ pds_$make_aux_reg_val_rec - 0x06C02E, 0x50 bytes: (10, 26). }

function pds_$make_aux_reg_val_rec(
    reg: integer;
    location_p: univ_ptr): univ_ptr;
var
  a: aux_p_t;
begin
  if location_p = nil then
    bug_check('PDS_$MAKE_AUX_REG_VAL_REC -- location_p is NIL.%$');
  a := alloc_aux_rec(aux_reg_val, 26);
  a^.w20 := reg;
  a^.p22 := location_p;
  pds_$make_aux_reg_val_rec := a;
end;

{ pds_$make_aux_size_rec - 0x06C0B0, 0x2C bytes: (0, 24) (`pea
  0x18'). }

function pds_$make_aux_size_rec(
    size: integer32): univ_ptr;
var
  a: aux_p_t;
begin
  a := alloc_aux_rec(aux_size, 24);
  a^.l20 := size;
  pds_$make_aux_size_rec := a;
end;

{ pds_$make_aux_field_size_rec - 0x06C0DC, 0x4C bytes: (2, 26). }

function pds_$make_aux_field_size_rec(
    field_num: integer;
    size: integer32): univ_ptr;
var
  a: aux_p_t;
begin
  if field_num = 0 then
    bug_check('PDS_$MAKE_AUX_FIELD_SIZE_REC -- field num is zero.%$');
  a := alloc_aux_rec(aux_field_size, 26);
  a^.w20 := field_num;
  a^.l22 := size;
  pds_$make_aux_field_size_rec := a;
end;

{ pds_$make_aux_align_rec - 0x06C15C, 0x2E bytes: (1, 22). }

function pds_$make_aux_align_rec(
    align: integer): univ_ptr;
var
  a: aux_p_t;
begin
  a := alloc_aux_rec(aux_align, 22);
  a^.w20 := align;
  pds_$make_aux_align_rec := a;
end;

{ pds_$make_aux_field_align_rec - 0x06C18A, 0x4C bytes: (4, 24). }

function pds_$make_aux_field_align_rec(
    field_num: integer;
    align: integer): univ_ptr;
var
  a: aux_p_t;
begin
  if field_num = 0 then
    bug_check('PDS_$MAKE_AUX_FIELD_ALIGN_REC -- field num is zero.%$');
  a := alloc_aux_rec(aux_field_align, 24);
  a^.w20 := field_num;
  a^.w22 := align;
  pds_$make_aux_field_align_rec := a;
end;

{ pds_$make_aux_var_bound_rec - 0x06C20C, 0x3E bytes: (6, 26). }

function pds_$make_aux_var_bound_rec(
    bound: integer;
    rec_p: univ_ptr): univ_ptr;
var
  a: aux_p_t;
begin
  a := alloc_aux_rec(aux_var_bound, 26);
  a^.w20 := bound;
  a^.p22 := rec_p;
  pds_$make_aux_var_bound_rec := a;
end;

{ pds_$make_aux_type_deriv_rec - 0x06C24A, 0x50 bytes: (7, 28). }

function pds_$make_aux_type_deriv_rec(
    parent_type_desc_p: univ_ptr;
    w24: integer;
    flag: boolean): univ_ptr;
var
  a: aux_p_t;
begin
  if parent_type_desc_p = nil then
    bug_check('PDS_$MAKE_AUX_TYPE_DERIV_REC -- parent_type_desc_p is NIL.%$');
  a := alloc_aux_rec(aux_type_deriv, 28);
  a^.p20 := parent_type_desc_p;
  a^.w24 := w24;
  a^.b26 := flag;
  pds_$make_aux_type_deriv_rec := a;
end;

{ pds_$make_aux_lifetime_rec - 0x06C2D8, 0x40 bytes: (8, 24). }

function pds_$make_aux_lifetime_rec(
    loc_p: univ_ptr): univ_ptr;
var
  a: aux_p_t;
begin
  if loc_p = nil then
    bug_check('PDS_$MAKE_AUX_LIFETIME_REC -- loc_p is NIL.%$');
  a := alloc_aux_rec(aux_lifetime, 24);
  a^.p20 := loc_p;
  pds_$make_aux_lifetime_rec := a;
end;

{ pds_$make_aux_ptr_base_rec - 0x06C346, 0x52 bytes: (9, 24). }

function pds_$make_aux_ptr_base_rec(
    var_p: univ_ptr): univ_ptr;
var
  r: rec_p_t;
  a: aux_p_t;
begin
  r := var_p;
  if r = nil then
    bug_check('PDS_$MAKE_AUX_PTR_BASE_REC -- var_p is NIL.%$');
  if r^.kind <> variable_kind then
    bug_check('PDS_$MAKE_AUX_PTR_BASE_REC -- var_p is not a variable.%$');
  a := alloc_aux_rec(aux_ptr_base, 24);
  a^.p20 := r;
  pds_$make_aux_ptr_base_rec := a;
end;

{ pds_$add_aux_rec - 0x06C400, 0x64 bytes: appended at the list's tail
  (+6), the head +2. }

procedure pds_$add_aux_rec(
    rec_p: univ_ptr;
    aux_p: univ_ptr);
var
  r: rec_p_t;
  a: aux_p_t;
begin
  r := rec_p;
  a := aux_p;
  if r = nil then
    bug_check('PDS_$ADD_AUX_REC -- rec_p is NIL.%$');
  if a = nil then
    bug_check('PDS_$ADD_AUX_REC -- aux_p is NIL.%$');
  if r^.aux_head = nil then
    r^.aux_head := a
  else
    r^.aux_tail^.next := a;
  r^.aux_tail := a;
end;

{ pds_$get_scope_offset_within_section - 0x06C4AC, 0x88 bytes: the
  lowest record's offset (+28, +24) less the section's base (the
  bucket's +1058). }

function pds_$get_scope_offset_within_section(
    rec_p: univ_ptr): integer32;
var
  r: rec_p_t;
begin
  r := rec_p;
  if r = nil then
    bug_check('PDS_$GET_SCOPE_OFFSET_WITHIN_SECTION -- nil rec_p.%$');
  if r^.kind > max_kind then
    bug_check('PDS_$GET_SCOPE_OFFSET_WITHIN_SECTION -- rec_type is out of range.%$');
  if not (written_flag in r^.flags) then
    bug_check('PDS_$GET_SCOPE_OFFSET_WITHIN_SECTION -- can''t get offset, record has not been written.%$');
  if r^.bucket = nil then
    bug_check('PDS_$GET_SCOPE_OFFSET_WITHIN_SECTION -- can''t get offset, bucket back pointer is NIL.%$');
  if r^.lowest = nil then
    bug_check('PDS_$GET_SCOPE_OFFSET_WITHIN_SECTION -- can''t get offset, lowest rec pointer is NIL.%$');
  pds_$get_scope_offset_within_section := r^.lowest^.offset - r^.bucket^.base;
end;

{ get_offset_within_section - 0x06C6B4, 0x66 bytes: the record's offset
  less its section's base. }

function get_offset_within_section(
    r: rec_p_t): integer32; options(val_param); internal;
begin
  if r = nil then
    bug_check('\\PDS_\GET_OFFSET_WITHIN_SECTION -- nil rec_p.%$');
  if r^.kind > max_kind then
    bug_check('\\PDS_\GET_OFFSET_WITHIN_SECTION -- rec_type is out of range.%$');
  if not (written_flag in r^.flags) then
    bug_check('\\PDS_\GET_OFFSET_WITHIN_SECTION -- can''t get offset, record has not been written.%$');
  if r^.bucket = nil then
    bug_check('\\PDS_\GET_OFFSET_WITHIN_SECTION -- can''t get offset, bucket back pointer is NIL.%$');
  get_offset_within_section := r^.offset - r^.bucket^.base;
end;

{ get_bucket - the bucket of file index, made when new.

  0x06C834, 0x7A bytes: the table's entry index - 1 (`(-4,A0,D2.w)');
  a new bucket is 3154 bytes (`pea 0xC52') and a bitmap of (nfiles + 7)
  div 8 bytes (zero-extended, `lsr.l #3'); +0 whether index is not the
  main file's (`sne'); +3144 cleared; +3122 -1. }

function get_bucket(
    index: integer): bucket_p_t; options(val_param); internal;
var
  b: bucket_p_t;
begin
  if bucket_table^[index] <> nil then
    b := bucket_table^[index]
  else begin
    b := mem_$alloc(general_pool, 3154);
    b^.refs := mem_$alloc(general_pool, (nfiles + 7) div 8);
    b^.is_include := index <> main_index;
    b^.pending_succs := 0;
    b^.first_offset := -1;
    bucket_table^[index] := b;
  end;
  get_bucket := b;
end;

{ make_incl_start_scope_rec - an include file's scope (its bucket's
  first root record) entered in the main file's records.

  0x06C8AE, 0x50 bytes: alloc_rec(21, 36); get_bucket; a nil first root
  is a BUG_CHECK (no `addq' after it). }

function make_incl_start_scope_rec(
    index: integer): rec_p_t; options(val_param); internal;
var
  r: rec_p_t;
  b: bucket_p_t;
  size: integer;
begin
  size := 36;
  r := alloc_rec(incl_start_scope_kind, size);
  b := get_bucket(index);
  if b^.first_root = nil then
    bug_check('\\PDS_\MAKE_INCL_START_SCOPE_REC --  Should not happen since this is the reason we''re creating this record.%$');
  r^.root := b^.first_root;
  make_incl_start_scope_rec := r;
end;

{ make_incl_end_scope_rec - 0x06C96C, 0x1A bytes: alloc_rec(22, 32). }

function make_incl_end_scope_rec: rec_p_t; internal;
var
  size: integer;
begin
  size := 32;
  make_incl_end_scope_rec := alloc_rec(incl_end_scope_kind, size);
end;

{ make_end_scope_rec - 0x06C986, 0x1A bytes: alloc_rec(20, 32). }

function make_end_scope_rec: rec_p_t; internal;
var
  size: integer;
begin
  size := 32;
  make_end_scope_rec := alloc_rec(end_scope_kind, size);
end;

{ pds_$initialize - 0x06C9A0, 0x92 bytes: MEM_$OPEN_POOL three times
  (MRH pools); the cells cleared (`move.l #0' each), +80 set. }

procedure pds_$initialize(
    fold_case: boolean);
begin
  mem_$open_pool(general_pool, 'Process Debug Symbols -- general heap%', false);
  mem_$open_pool(scope_pool,
    'Process Debug Symbols -- blocks include scope mark/release heap%', false);
  mem_$open_pool(merge_pool,
    'Process Debug Symbols -- bucket merge thread mark/release heap%', false);
  loc_pool := nil;
  case_fold := fold_case;
  dfs_head := nil;
  dfs_tail := nil;
  visit_numbers := nil;
  dag_stack := nil;
  dag_head := nil;
  dag_tail := nil;
end;

{ pds_$enter_main_file_table - 0x06CADC, 0x82 bytes: every entry (1 ..
  nfiles, `dbf') must be set; +28 the table, +78 its main index, +76
  its count; the bucket table nfiles * 4 bytes (word arithmetic). }

procedure pds_$enter_main_file_table(
    file_table_p: univ_ptr);
var
  t: file_table_p_t;
  i: integer;
begin
  t := file_table_p;
  if t = nil then
    bug_check('PDS_$ENTER_MAIN_FILE_TABLE -- file table pointer is NIL.%$');
  for i := 1 to t^.nfiles do
    if t^.entries[i] = nil then
      bug_check('PDS_$ENTER_MAIN_FILE_TABLE -- Number of entries doesn''t agree with file table.%$');
  main_file_table := t;
  main_index := main_file_table^.main_index;
  nfiles := main_file_table^.nfiles;
  bucket_table := mem_$alloc(general_pool, nfiles * 4);
end;

{ pds_$finalize - 0x06CBE8, 0x36 bytes. }

procedure pds_$finalize;
begin
  mem_$empty_pool(general_pool);
  mem_$empty_pool(scope_pool);
  mem_$empty_pool(merge_pool);
end;

{ pds_$begin_scope - 0x06CC1E, 0x46 bytes: MEM_$MARK of the scope pool;
  the scope's bitmap from it ((nfiles + 7) div 8, unsigned); +48
  cleared.  No result: the caller reads none. }

procedure pds_$begin_scope;
begin
  scope_mark := mem_$mark(scope_pool);
  scope_refs := mem_$alloc(scope_pool, (nfiles + 7) div 8);
  scope_start := nil;
end;

{ get_bucket_index - the file whose bucket gets the record: the source
  location's file for the types and constants (kinds 0..13), 0 for a
  signature, the main file for the rest; the main file unless -CD.

  0x06CC64, 0x72 bytes: a `case' by jump table (0..19); `btst
  #6,0x2C3677' (cargs_$options.cd).  The result in D0. }

function get_bucket_index(
    r: rec_p_t): integer; options(val_param); internal;
var
  index: integer;
begin
  case r^.kind of
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13:
      index := r^.src_loc^.file_index;
    signature_kind:
      index := 0;
    variable_kind, label_kind, entry_kind, 18, 19:
      index := main_index;
    otherwise
      bug_check('\\PDS_\GET_BUCKET_INDEX -- unknown pds rec_type.%$');
  end;
  if not cargs_$options.cd then
    index := main_index;
  get_bucket_index := index;
end;

{ get_name_p - a record's name (+32): kinds 0..17; nil for 18..22.

  0x06CD08, 0xD4 bytes: a jump table of 23; the result in A0. }

function get_name_p(
    r: rec_p_t): name_p_t; options(val_param); internal;
begin
  if r = nil then
    bug_check('\\PDS_\GET_NAME_P -- rec_p is NIL.%$');
  case r^.kind of
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17:
      get_name_p := r^.name;
    18, 19, 20, 21, 22:
      get_name_p := nil;
    otherwise
      bug_check('\\PDS_\GET_NAME_P -- Unknown named rec.%$');
  end;
end;

{ memcmp - the difference of the first bytes of a and b that differ
  (unsigned), else 0.  0x06CE2C, 0x3E bytes. }

function memcmp(
    in a: univ pds_$chars_t;
    in b: univ pds_$chars_t;
    n: integer): integer32; options(val_param); internal;
var
  i: integer;
begin
  for i := 1 to n do
    if a[i] <> b[i] then begin
      memcmp := ord(a[i]) - ord(b[i]);
      return;
    end;
  memcmp := 0;
end;

{ compare_bytes_case - -1, 0 or 1 as a sorts before, with or after b,
  letters folded to upper case when fold; the longer one's extra
  characters compared with blanks.

  0x06CE6A, 0xEC bytes: n the smaller length (unsigned); `in
  ['a'..'z']' by a 16-byte constant set after the routine; the loops
  compare a word counter with a longword limit. }

function compare_bytes_case(
    in a: univ pds_$chars_t;
    alen: integer;
    in b: univ pds_$chars_t;
    blen: integer;
    fold: boolean): integer; options(val_param); internal;
var
  i: integer;
  n: integer32;
  c1, c2: char;
begin
  i := 1;
  n := alen;
  if alen > blen then
    n := blen;
  while i <= n do begin
    c1 := a[i];
    c2 := b[i];
    if fold then begin
      if c1 in ['a'..'z'] then
        c1 := chr(ord(c1) - 32);
      if c2 in ['a'..'z'] then
        c2 := chr(ord(c2) - 32);
    end;
    if c1 <> c2 then begin
      if c1 < c2 then
        compare_bytes_case := -1
      else
        compare_bytes_case := 1;
      return;
    end;
    i := i + 1;
  end;
  if alen > blen then begin
    while i <= alen do begin
      if a[i] <> ' ' then begin
        if a[i] < ' ' then
          compare_bytes_case := -1
        else
          compare_bytes_case := 1;
        return;
      end;
      i := i + 1;
    end;
  end
  else if alen < blen then begin
    while i <= blen do begin
      if b[i] <> ' ' then begin
        if b[i] < ' ' then
          compare_bytes_case := 1
        else
          compare_bytes_case := -1;
        return;
      end;
      i := i + 1;
    end;
  end;
  compare_bytes_case := 0;
end;

{ append_root_rec_to_bucket - the record at the end of the bucket's
  root list; the main bucket's first one starts the scope.

  0x06CF68, 0x54 bytes. }

procedure append_root_rec_to_bucket(
    b: bucket_p_t;
    r: rec_p_t); options(val_param); internal;
begin
  if b^.first_root = nil then
    b^.first_root := r
  else
    b^.last_root^.next := r;
  b^.last_root := r;
  r^.flags := r^.flags + [in_bucket_flag];
  if (get_bucket(main_index) = b) and (scope_start = nil) then
    scope_start := r;
end;

{ order_root_rec_in_bucket - a named record entered in its bucket: the
  main file's at the end, an include file's in name order.

  0x06CFBC, 0x106 bytes: an unnamed record is left out; the insertion
  point found with compare_bytes_case (stops at the first name after
  the record's); the record's flag set on both paths. }

procedure order_root_rec_in_bucket(
    r: rec_p_t;
    index: integer); options(val_param); internal;
var
  name, name2: name_p_t;
  b: bucket_p_t;
  p, prev: rec_p_t;
begin
  if in_bucket_flag in r^.flags then
    bug_check('\\PDS_\ORDER_ROOT_REC_IN_BUCKET -- Record already in bucket.%$');
  name := get_name_p(r);
  if name = nil then
    return;
  b := get_bucket(index);
  if index = main_index then
    append_root_rec_to_bucket(b, r)
  else if b^.first_root = nil then
    append_root_rec_to_bucket(b, r)
  else begin
    p := b^.first_root;
    prev := nil;
    while p <> nil do begin
      name2 := get_name_p(p);
      if name2 = nil then
        bug_check('\\PDS_\ORDER_ROOT_REC_IN_BUCKET -- at this point, all root records within .s. sections are supposed to have a name.%$');
      if compare_bytes_case(name^.chars, name^.len, name2^.chars,
          name2^.len, case_fold) < 0 then
        exit;
      prev := p;
      p := p^.next;
    end;
    if b^.first_root = nil then
      bug_check('\\PDS_\ORDER_ROOT_REC_IN_BUCKET -- Should never happen.%$');
    if prev = nil then begin
      r^.next := b^.first_root;
      b^.first_root := r;
      r^.flags := r^.flags + [in_bucket_flag];
    end
    else begin
      prev^.next := r;
      r^.next := p;
      if p = nil then
        b^.last_root := r;
      r^.flags := r^.flags + [in_bucket_flag];
    end;
  end;
end;

{ process_symbols_rec - a record and those it refers to entered in
  their buckets; the bucket of bucket_index marked as referring to
  each one's file.

  0x06D1B0, 0x2D2 bytes: get_bucket(bucket_index) with its result
  unused, then the table's entry (`(-4,A1)') and its bitmap; a jump
  table of 18 (kinds 0..17); the loops over the elements check each is
  set (an offset register from 4, `dbf'). }

procedure process_symbols_rec(
    r: rec_p_t;
    bucket_index: integer); options(val_param); internal;
var
  index: integer;
  i: integer;
  b: bucket_p_t;
begin
  if r = nil then
    return;
  index := get_bucket_index(r);
  if index = 0 then begin
    index := bucket_index;
    if index = 0 then
      bug_check('\\PDS_\PROCESS_SYMBOLS_REC -- bucket index is NIL.%$');
  end;
  b := get_bucket(bucket_index);
  bucket_table^[bucket_index]^.refs^[index] := true;
  if processed_flag in r^.flags then
    return;
  r^.flags := r^.flags + [processed_flag];
  case r^.kind of
    pointer_kind:
      process_symbols_rec(r^.type_p^.rec, index);
    variable_kind:
      process_symbols_rec(r^.var_type^.rec, index);
    entry_kind:
      process_symbols_rec(r^.signature, index);
    signature_kind: begin
      process_symbols_rec(r^.sig_result, index);
      for i := 1 to r^.nargs do begin
        if r^.args[i] = nil then
          bug_check('\\PDS_\PROCESS_SYMBOLS_REC -- Number of args in signature doesn''t match nargs.%$');
        process_symbols_rec(r^.args[i]^.var_rec, index);
      end;
    end;
    alias_kind:
      process_symbols_rec(r^.type_p^.rec, index);
    array_kind: begin
      process_symbols_rec(r^.type_p^.rec, index);
      process_symbols_rec(r^.type2^.rec, index);
    end;
    string_kind: begin
      process_symbols_rec(r^.type_p^.rec, index);
      process_symbols_rec(r^.type2^.rec, index);
    end;
    constant_kind:
      process_symbols_rec(r^.type_p^.rec, index);
    short_record_kind:
      for i := 1 to r^.rec_nfields do begin
        if r^.short_fields[i] = nil then
          bug_check('\\PDS_\PROCESS_SYMBOLS_REC -- Number of fields in short record doesn''t match nfields.%$');
        process_symbols_rec(r^.short_fields[i]^.type_p^.rec, index);
      end;
    record_kind:
      for i := 1 to r^.rec_nfields do begin
        if r^.fields[i] = nil then
          bug_check('\\PDS_\PROCESS_SYMBOLS_REC -- Number of fields in record doesn''t match nfields.%$');
        process_symbols_rec(r^.fields[i]^.type_p^.rec, index);
      end;
    set_kind:
      process_symbols_rec(r^.type_p^.rec, index);
    file_kind:
      process_symbols_rec(r^.type_p^.rec, index);
    offset_kind: begin
      process_symbols_rec(r^.type_p^.rec, index);
      process_symbols_rec(r^.type2^.rec, index);
    end;
    subrange_kind:
      process_symbols_rec(r^.type_p^.rec, index);
    implicit_enum_kind:
      for i := 1 to r^.enum_nelements do
        if r^.implicit[i] = nil then
          bug_check('\\PDS_\PROCESS_SYMBOLS_REC -- Number of elems in implicit enum doesn''t match nelems.%$');
    explicit_enum_kind:
      for i := 1 to r^.enum_nelements do
        if r^.explicit[i] = nil then
          bug_check('\\PDS_\PROCESS_SYMBOLS_REC -- Number of elems in explicit enum doesn''t match nelems.%$');
    label_kind:
      ;
    otherwise
      bug_check('\\PDS_\PROCESS_SYMBOLS_REC -- not implt yet.%$');
  end;
  order_root_rec_in_bucket(r, index);
end;

{ pds_$enter_named_record_current_scope - 0x06D68C, 0x82 bytes: the
  record's file (the main one for 0) marked in the scope's bitmap
  (+68); process_symbols_rec. }

procedure pds_$enter_named_record_current_scope(
    rec_p: univ_ptr);
var
  r: rec_p_t;
  index: integer;
begin
  r := rec_p;
  if r = nil then
    bug_check('PDS_$ENTER_NAMED_RECORD_CURRENT_SCOPE -- rec_p is NIL.%$');
  if get_name_p(r) = nil then
    bug_check('PDS_$ENTER_NAMED_RECORD_CURRENT_SCOPE -- rec_p is not a named record.%$');
  index := get_bucket_index(r);
  if index = 0 then
    index := main_index;
  scope_refs^[index] := true;
  process_symbols_rec(r, index);
end;

{ pds_$end_scope - 0x06D790, 0xD8 bytes: for each include file the
  scope refers to, an include start record appended to the main bucket
  and the main bucket marked as referring to the file; an end of scope
  record; the scope's first record returned; MEM_$RELEASE of the
  scope's mark. }

procedure pds_$end_scope(
    out symbols_start: univ_ptr);
var
  main: bucket_p_t;
  r: rec_p_t;
  i: integer;
begin
  main := get_bucket(main_index);
  for i := 1 to nfiles do
    if (i <> main_index) and scope_refs^[i] then begin
      r := make_incl_start_scope_rec(i);
      append_root_rec_to_bucket(main, r);
      bucket_table^[main_index]^.refs^[i] := true;
    end;
  r := make_end_scope_rec;
  append_root_rec_to_bucket(main, r);
  if scope_start = nil then
    bug_check('PDS_$END_SCOPE -- symbols start is NIL.%$');
  symbols_start := scope_start;
  mem_$release(scope_mark);
end;

{ allocate_dst_rec - size bytes of the object file for a DST record,
  counted in the bucket's size (its first offset kept).

  0x06D892, 0x76 bytes: size above 163808 (unsigned) a BUG_CHECK; the
  allocator (+44) called with pos's address and the size; its D0
  result returned in A0 (through two locals). }

function allocate_dst_rec(
    b: bucket_p_t;
    in out pos: integer32;
    size: integer32): dst_$rec_p_t; options(val_param); internal;
var
  start: integer32;
  addr: integer32;
  written: integer32;
begin
  if b = nil then
    bug_check(' \\PDS_\ALLOCATE_DST_REC -- bucket_p is NIL.%$');
  if size > max_dst_rec_size then
    bug_check(' \\PDS_\ALLOCATE_DST_REC -- size exceeds file mapping capabilities.%$');
  start := pos;
  addr := alloc_obj_func^(pos, size);
  written := pos - start;
  if b^.first_offset = -1 then
    b^.first_offset := start;
  b^.size := b^.size + written;
  allocate_dst_rec := dst_$rec_p_t(addr);
end;

{ hash_it - the sum of len bytes (a word; callers take its low byte).
  0x06D97C, 0x2A bytes. }

function hash_it(
    in s: univ pds_$chars_t;
    len: integer): integer; options(val_param); internal;
var
  sum: integer;
  i: integer;
begin
  sum := 0;
  for i := 1 to len do
    sum := sum + ord(s[i]);
  hash_it := sum;
end;

{ downcase_string - 0x06D9A6, 0x44 bytes: 'A'..'Z' (unsigned compares)
  plus 32. }

procedure downcase_string(
    in out s: univ pds_$chars_t;
    len: integer); options(val_param); internal;
var
  i: integer;
  c: char;
begin
  for i := 1 to len do begin
    c := s[i];
    if (c >= 'A') and (c <= 'Z') then
      c := chr(ord(c) + 32);
    s[i] := c;
  end;
end;

{ add_str - a name entered in the bucket's string pool (folded first
  when fold); a name already there replaces it.

  0x06D9EA, 0xB2 bytes: the chain of the hash's low byte (+26); a new
  node (8 bytes) at the chain's head; the pool's size (+1050) counts
  each name and a terminating byte. }

procedure add_str(
    b: bucket_p_t;
    in out name: name_p_t;
    fold: boolean); options(val_param); internal;
var
  h: integer;
  node: string_node_p_t;
begin
  if name = nil then
    return;
  if fold then
    downcase_string(name^.chars, name^.len);
  h := hash_it(name^.chars, name^.len) & 16#FF;
  node := b^.strings[h];
  while node <> nil do begin
    if node^.name^.len = name^.len then
      if memcmp(node^.name^.chars, name^.chars, name^.len) = 0 then begin
        name := node^.name;
        return;
      end;
    node := node^.next;
  end;
  node := mem_$alloc(general_pool, 8);
  node^.name := name;
  node^.next := b^.strings[h];
  b^.strings[h] := node;
  b^.string_size := b^.string_size + node^.name^.len + 1;
end;

{ add_string - a record's name in the pool, folded as the module says.
  0x06DA9C, 0x22 bytes. }

procedure add_string(
    b: bucket_p_t;
    in out name: name_p_t); options(val_param); internal;
begin
  add_str(b, name, case_fold);
end;

{ add_file_string - a file's name in the pool, not folded.  0x06DABE,
  0x20 bytes. }

procedure add_file_string(
    b: bucket_p_t;
    in out name: name_p_t); options(val_param); internal;
begin
  add_str(b, name, false);
end;

{ pool_strings - a record's names in its bucket's pool.

  0x06DADE, 0x174 bytes: a jump table of 23; the implicit enumeration's
  elements passed by their slots' addresses (`pea (40,A2,D3.l)'), the
  other elements and fields by their records' (the name at +0); 20..22
  nothing. }

procedure pool_strings(
    b: bucket_p_t;
    r: rec_p_t); options(val_param); internal;
var
  i: integer;
begin
  case r^.kind of
    0, 1, 2, 3, 4, 9, 10, 11, 12, 13, 14, 15, 16:
      add_string(b, r^.name);
    implicit_enum_kind: begin
      add_string(b, r^.name);
      for i := 1 to r^.enum_nelements do
        add_string(b, r^.implicit[i]);
    end;
    explicit_enum_kind: begin
      add_string(b, r^.name);
      for i := 1 to r^.enum_nelements do
        add_string(b, r^.explicit[i]^.name);
    end;
    short_record_kind: begin
      add_string(b, r^.name);
      for i := 1 to r^.rec_nfields do
        add_string(b, r^.short_fields[i]^.name);
    end;
    record_kind: begin
      add_string(b, r^.name);
      for i := 1 to r^.rec_nfields do
        add_string(b, r^.fields[i]^.name);
    end;
    signature_kind: begin
      add_string(b, r^.name);
      if r^.sig_result <> nil then
        add_string(b, r^.sig_result^.name);
      for i := 1 to r^.nargs do
        if r^.args[i]^.var_rec <> nil then
          add_string(b, r^.args[i]^.var_rec^.name);
    end;
    end_scope_kind, incl_start_scope_kind, incl_end_scope_kind:
      ;
    otherwise
      bug_check('\\PDS_\POOL_STRINGS -- Uknown rec type.%$');
  end;
end;

{ create_new_crc_table_entry - another section referred to (at an
  offset's high word) entered in the bucket's include table.

  0x06DC7C, 0x78 bytes: the hash of the other bucket's 64 bytes from +2
  (`move.w #64; pea (2,A3)'); a node of 12 bytes; its index the count
  (+2094) less 1 after the count is incremented. }

procedure create_new_crc_table_entry(
    b: bucket_p_t;
    other: bucket_p_t;
    offset: integer); options(val_param); internal;
var
  h: integer;
  node: crc_node_p_t;
begin
  if b = other then
    bug_check('\\PDS_\CREATE_NEW_CRC_TABLE_ENTRY -- reference to object in same section, why new entry????%$');
  h := hash_it(other^.crc1, 64) & 16#FF;
  node := mem_$alloc(general_pool, 12);
  node^.bucket := other;
  node^.offset := offset;
  b^.crc_count := b^.crc_count + 1;
  node^.index := b^.crc_count - 1;
  node^.next := b^.crcs[h];
  b^.crcs[h] := node;
end;

{ get_include_table_index - whether the bucket's include table has the
  other section at offset, and its index.

  0x06DD52, 0x7C bytes: the result a byte (`st', `clr.b'); index
  cleared when not found. }

function get_include_table_index(
    b: bucket_p_t;
    other: bucket_p_t;
    offset: integer;
    out index: integer): boolean; options(val_param); internal;
var
  node: crc_node_p_t;
begin
  node := b^.crcs[hash_it(other^.crc1, 64) & 16#FF];
  while node <> nil do begin
    if memcmp(node^.bucket^.crc1, other^.crc1, 64) = 0 then
      if node^.offset = offset then begin
        index := node^.index;
        get_include_table_index := true;
        return;
      end;
    node := node^.next;
  end;
  index := 0;
  get_include_table_index := false;
end;

{ add_crc_entry - 0x06DDCE, 0x38 bytes: the index into (-6,A6),
  unused. }

procedure add_crc_entry(
    b: bucket_p_t;
    other: bucket_p_t;
    offset: integer); options(val_param); internal;
var
  index: integer;
begin
  if not get_include_table_index(b, other, offset, index) then
    create_new_crc_table_entry(b, other, offset);
end;

{ add_crc_entry_for_type_ref - a user defined type of another section
  entered in the bucket's include table, at its offset's high word.

  0x06DE06, 0x86 bytes: the offset into (-8,A6) and its first word
  pushed (`move.w (-8,A6)'). }

procedure add_crc_entry_for_type_ref(
    b: bucket_p_t;
    t: type_p_t); options(val_param); internal;
var
  offset: split_t;
begin
  if t = nil then
    bug_check('\\PDS_\ADD_CRC_ENTRY_FOR_TYPE_REF -- typ_p is NIL.%$');
  if t^.code = user_type_code then begin
    if t^.rec = nil then
      bug_check('\\PDS_\ADD_CRC_ENTRY_FOR_TYPE_REF -- user defined type with nil rec_p.%$');
    if t^.rec^.bucket = nil then
      bug_check('\\PDS_\ADD_CRC_ENTRY_FOR_TYPE_REF -- rec_p has no bucket back pointer.%$');
    if t^.rec^.bucket <> b then begin
      offset.all := get_offset_within_section(t^.rec);
      add_crc_entry(b, t^.rec^.bucket, offset.high);
    end;
  end;
end;

{ pool_crc_entries - under -CD, the other sections a record's types
  refer to entered in its bucket's include table.

  0x06DF50, 0x1A4 bytes: a jump table of 23; the include start record's
  root bucket loaded before its record is checked. }

procedure pool_crc_entries(
    b: bucket_p_t;
    r: rec_p_t); options(val_param); internal;
var
  i: integer;
  other: bucket_p_t;
  offset: split_t;
begin
  if not cargs_$options.cd then
    return;
  case r^.kind of
    pointer_kind:
      add_crc_entry_for_type_ref(b, r^.type_p);
    variable_kind:
      add_crc_entry_for_type_ref(b, r^.var_type);
    constant_kind:
      add_crc_entry_for_type_ref(b, r^.type_p);
    signature_kind: begin
      if r^.sig_result <> nil then
        add_crc_entry_for_type_ref(b, r^.sig_result^.var_type);
      for i := 1 to r^.nargs do
        if r^.args[i]^.var_rec <> nil then
          add_crc_entry_for_type_ref(b, r^.args[i]^.var_rec^.var_type);
    end;
    alias_kind:
      add_crc_entry_for_type_ref(b, r^.type_p);
    incl_start_scope_kind: begin
      other := r^.root^.bucket;
      if other <> r^.bucket then begin
        if r^.root = nil then
          bug_check('\\PDS_\POOL_CRC_ENTRIES -- Include start rec points to NIL root record.%$');
        offset.all := get_offset_within_section(r^.root^.lowest);
        add_crc_entry(b, other, offset.high);
      end;
    end;
    short_record_kind:
      for i := 1 to r^.rec_nfields do
        add_crc_entry_for_type_ref(b, r^.short_fields[i]^.type_p);
    record_kind:
      for i := 1 to r^.rec_nfields do
        add_crc_entry_for_type_ref(b, r^.fields[i]^.type_p);
    set_kind:
      add_crc_entry_for_type_ref(b, r^.type_p);
    file_kind:
      add_crc_entry_for_type_ref(b, r^.type_p);
    offset_kind: begin
      add_crc_entry_for_type_ref(b, r^.type_p);
      add_crc_entry_for_type_ref(b, r^.type2);
    end;
    array_kind: begin
      add_crc_entry_for_type_ref(b, r^.type_p);
      add_crc_entry_for_type_ref(b, r^.type2);
    end;
    string_kind: begin
      add_crc_entry_for_type_ref(b, r^.type_p);
      add_crc_entry_for_type_ref(b, r^.type2);
    end;
    subrange_kind:
      add_crc_entry_for_type_ref(b, r^.type_p);
    implicit_enum_kind, explicit_enum_kind, label_kind, entry_kind,
    end_scope_kind, incl_end_scope_kind:
      ;
    otherwise
      bug_check('\\PDS_\POOL_CRC_ENTRIES -- unknown rec type.%$');
  end;
end;

{ dump_string_table - the bucket's string pool written as string table
  records (each at most 163802 characters), each name's offset set.

  0x06E16C, 0x14E bytes: the 256 chains linked into one list (the
  tails found by walking each chain); per record: kind 27, flags
  cleared, the text's offset (the record's +6) computed from pos
  before; a name that does not fit ends the record (the count taken
  back, pos rounded down to even after taking back the name's
  characters copied, `andi.b #-2') and starts the next one. }

procedure dump_string_table(
    b: bucket_p_t;
    in out pos: integer32); options(val_param); internal;
label
  record_full;
var
  tail, node, p: string_node_p_t;
  i, j: integer;
  total, remaining, chunk, start, text_offset, n, limit: integer32;
  r: dst_$rec_p_t;
begin
  if b^.string_size = 0 then
    return;
  tail := nil;
  node := nil;
  for i := 0 to 255 do begin
    p := b^.strings[i];
    if (tail <> nil) and (p <> nil) then
      tail^.next := p;
    if (node = nil) and (p <> nil) then
      node := p;
    if p <> nil then begin
      while (p <> nil) and then (p^.next <> nil) do
        p := p^.next;
      tail := p;
    end;
  end;
  total := 0;
  remaining := b^.string_size;
  while remaining <> 0 do begin
    chunk := remaining;
    if chunk > 163802 then
      chunk := 163802;
    start := pos;
    r := allocate_dst_rec(b, pos, chunk + 6);
    r^.kind := dst_$string_table;
    r^.flags := [];
    text_offset := start + 6;
    n := 0;
    limit := chunk - 1;
    while node <> nil do begin
      node^.name^.offset := n + text_offset;
      for j := 1 to node^.name^.len do begin
        n := n + 1;
        if n > limit then begin
          n := n - j;
          pos := (pos - j + 1) & (-2);
          goto record_full;
        end;
        r^.text[n] := node^.name^.chars[j];
      end;
      n := n + 1;
      r^.text[n] := chr(0);
      node := node^.next;
    end;
  record_full:
    r^.text_len := n;
    total := total + n;
    remaining := remaining - n;
  end;
  if total <> b^.string_size then
    bug_check('\\PDS_\DUMP_STRING_TABLE -- text size doesn''t agree with bucket''s string table size.%$');
end;

{ dump_loc_pool - the location pool written (an even size) after a
  location pool record (kind 45); its offset kept (+32) for the
  locations' references.

  0x06E310, 0x76 bytes: LOC_BUILD__POOL_SIZE; allocate_dst_rec of 6;
  LOC_BUILD__DUMP_POOL(pool, 0, offset); pos moved past the pool. }

procedure dump_loc_pool(
    b: bucket_p_t;
    in out pos: integer32); options(val_param); internal;
var
  size: integer32;
  start: integer32;
  r: dst_$rec_p_t;
begin
  if loc_pool <> nil then begin
    size := loc_build__pool_size(loc_pool);
    if odd(size) then
      size := size + 1;
    start := pos;
    r := allocate_dst_rec(b, pos, 6);
    r^.kind := dst_$loc_pool;
    r^.flags := [];
    r^.text_len := size;
    loc_pool_base := start + 6;
    loc_build__dump_pool(loc_pool, 0, loc_pool_base);
    pos := pos + size;
  end;
end;

{ dump_aux_recs - a written record's auxiliary records allocated after
  it (their kinds and offsets set), the record and the last one
  flagged.

  0x06E386, 0x214 bytes: a jump table of 11; each size through a local
  ((-8,A6)); the register value record's flags cleared, the others'
  left. }

procedure dump_aux_recs(
    b: bucket_p_t;
    r: rec_p_t;
    in out pos: integer32); options(val_param); internal;
var
  a: aux_p_t;
  size: integer32;
begin
  if r^.aux_head = nil then
    return;
  if not (written_flag in r^.flags) then
    bug_check('\\PDS_\DUMP_AUX_RECS -- primary record has not yet been written.%$');
  r^.dst^.flags := r^.dst^.flags + [dst_$has_aux];
  a := r^.aux_head;
  while a <> nil do begin
    a^.offset := pos;
    a^.flags := a^.flags + [written_flag];
    a^.bucket := b;
    case a^.kind of
      aux_size: begin
        size := 6;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_size;
      end;
      aux_align: begin
        size := 4;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_align;
      end;
      aux_field_size: begin
        size := 8;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_field_size;
      end;
      aux_field_off: begin
        size := 8;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_field_off;
      end;
      aux_field_align: begin
        size := 6;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_field_align;
      end;
      aux_name: begin
        size := 6;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_name;
      end;
      aux_var_bound: begin
        size := 8;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_var_bound;
      end;
      aux_type_deriv: begin
        size := 10;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_type_deriv;
      end;
      aux_lifetime: begin
        size := 6;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_lifetime;
      end;
      aux_ptr_base: begin
        size := 6;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_ptr_base;
      end;
      aux_reg_val: begin
        size := 8;
        a^.dst := allocate_dst_rec(b, pos, size);
        a^.dst^.kind := dst_$aux_reg_val;
        a^.dst^.flags := [];
      end;
      otherwise
        bug_check('\\PDS_\DUMP_AUX_RECS -- unknown aux rec.%$');
    end;
    a := a^.next;
  end;
  r^.aux_tail^.dst^.flags := r^.aux_tail^.dst^.flags + [dst_$last_aux];
end;

{ dump_rec - a record's DST record allocated at pos (its kind set, the
  flags of some cleared), then its auxiliary records'.

  0x06E606, 0x396 bytes: a jump table of 23; each size through a local
  ((-8,A6)); the sizes of the variable-length ones from their counts
  (unsigned); kinds 1, 18 and 19 a BUG_CHECK, then the auxiliary
  records as for the others. }

procedure dump_rec(
    b: bucket_p_t;
    r: rec_p_t;
    in out pos: integer32); options(val_param); internal;
var
  size: integer32;
begin
  if b <> r^.bucket then
    bug_check('\\PDS_\DUMP_REC -- record does not belong to this section.%$');
  if not (ordered_flag in r^.flags) then
    bug_check('\\PDS_\DUMP_REC -- record is not in object file order.%$');
  if written_flag in r^.flags then
    return;
  r^.flags := r^.flags + [written_flag];
  r^.offset := pos;
  case r^.kind of
    pointer_kind: begin
      size := 14;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$pointer;
      r^.dst^.flags := [];
    end;
    end_scope_kind: begin
      size := 2;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$end_scope;
    end;
    variable_kind: begin
      size := 20;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$variable;
      r^.dst^.flags := [];
    end;
    constant_kind: begin
      size := r^.value^.len + 16;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$constant;
      r^.dst^.flags := [];
    end;
    label_kind: begin
      size := 14;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$label;
      r^.dst^.flags := [];
    end;
    entry_kind: begin
      size := 20;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$entry;
      r^.dst^.flags := [];
    end;
    signature_kind: begin
      size := r^.nargs * 6 + 16;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$signature;
      r^.dst^.flags := [];
    end;
    alias_kind: begin
      size := 14;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$alias;
      r^.dst^.flags := [];
    end;
    incl_start_scope_kind: begin
      size := 6;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$incl_start_scope;
      r^.dst^.flags := [];
    end;
    incl_end_scope_kind: begin
      size := 2;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$incl_end_scope;
    end;
    short_record_kind: begin
      size := r^.rec_nfields * 10 + 14;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$short_record;
    end;
    record_kind: begin
      size := r^.rec_nfields * 12 + 14;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$record;
    end;
    set_kind: begin
      size := 18;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$set;
    end;
    file_kind: begin
      size := 14;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$file;
    end;
    offset_kind: begin
      size := 34;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$offset;
    end;
    array_kind: begin
      size := 36;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$array;
    end;
    string_kind: begin
      size := 30;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$string;
    end;
    implicit_enum_kind: begin
      size := r^.enum_nelements * 4 + 14;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$implicit_enum;
    end;
    explicit_enum_kind: begin
      size := r^.enum_nelements * 8 + 14;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$explicit_enum;
    end;
    subrange_kind: begin
      size := 24;
      r^.dst := allocate_dst_rec(b, pos, size);
      r^.dst^.kind := dst_$subrange;
    end;
    otherwise
      bug_check('\\PDS_\DUMP_REC -- NOT IMPLEMENTED YET.%$');
  end;
  dump_aux_recs(b, r, pos);
end;

{ get_dtc - the DST code of a standard type: the same number (0..21).
  0x06EA3A, 0xAE bytes: a jump table of 22 `moveq's. }

function get_dtc(
    type_code: integer): integer; options(val_param); internal;
begin
  case type_code of
    0: get_dtc := 0;
    1: get_dtc := 1;
    2: get_dtc := 2;
    3: get_dtc := 3;
    4: get_dtc := 4;
    5: get_dtc := 5;
    6: get_dtc := 6;
    7: get_dtc := 7;
    8: get_dtc := 8;
    9: get_dtc := 9;
    10: get_dtc := 10;
    11: get_dtc := 11;
    12: get_dtc := 12;
    13: get_dtc := 13;
    14: get_dtc := 14;
    15: get_dtc := 15;
    16: get_dtc := 16;
    17: get_dtc := 17;
    18: get_dtc := 18;
    19: get_dtc := 19;
    20: get_dtc := 20;
    21: get_dtc := 21;
    otherwise
      bug_check('\\PDS_\GET_DTC -- Unknown std type%$');
  end;
end;

{ get_arg_attrs - an argument's attributes as the DST's (the same
  numbers, 0..5).  0x06EB0C, 0x84 bytes: a `for' over 0..5 with a jump
  table of 6 in it; the result a word in D0. }

function get_arg_attrs(
    attrs: attrs_p_t): flags_t; options(val_param); internal;
var
  i, d: integer;
  result: flags_t;
begin
  if attrs = nil then
    bug_check('\\PDS_\GET_ARG_ATTRS -- attributes_p is NIL.%$');
  result := [];
  for i := 0 to 5 do begin
    case i of
      0: d := 0;
      1: d := 1;
      2: d := 2;
      3: d := 3;
      4: d := 4;
      5: d := 5;
      otherwise
        bug_check('\\PDS_\GET_ARG_ATTRS -- Unknown arg attr.%$');
    end;
    if i in attrs^ then
      result := result + [d];
  end;
  get_arg_attrs := result;
end;

{ get_var_attrs - a variable's attributes (0..4) likewise.  0x06EBEA,
  0x7E bytes. }

function get_var_attrs(
    attrs: attrs_p_t): flags_t; options(val_param); internal;
var
  i, d: integer;
  result: flags_t;
begin
  if attrs = nil then
    bug_check('\\PDS_\GET_VAR_ATTRS -- attributes_p is NIL.%$');
  result := [];
  for i := 0 to 4 do begin
    case i of
      0: d := 0;
      1: d := 1;
      2: d := 2;
      3: d := 3;
      4: d := 4;
      otherwise
        bug_check('\\PDS_\GET_VAR_ATTRS -- Unknown var attr.%$');
    end;
    if i in attrs^ then
      result := result + [d];
  end;
  get_var_attrs := result;
end;

{ make_include_rec_ref - a reference through the include table: the
  index of the dependent record's section (at its offset's high word)
  and the offset's low word.

  0x06ECC2, 0xB6 bytes: the offset in (-8,A6), its first word passed
  (`move.w (-8,A6)'), its second stored (`move.w (-6,A6),(-12,A6)');
  tag 1 (`ori.b #64'), the index or'd into the first word's low 14
  bits; the result from (-14,A6) in D0. }

function make_include_rec_ref(
    base: rec_p_t;
    dep: rec_p_t): dst_$rel_t; options(val_param); internal;
var
  offset: split_t;
  index: integer;
  ref: dst_$rel_t;
begin
  if not cargs_$options.cd then
    bug_check('\\PDS_\MAKE_INCLUDE_REC_REF -- Should never get here.%$');
  if base^.bucket = nil then
    bug_check('\\PDS_\MAKE_INCLUDE_REC_REF -- NIL bucket back pointer.%$');
  if dep^.bucket = nil then
    bug_check('\\PDS_\MAKE_INCLUDE_REC_REF -- NIL bucket back pointer.%$');
  offset.all := get_offset_within_section(dep);
  if not get_include_table_index(base^.bucket, dep^.bucket, offset.high, index) then
    bug_check('\\PDS_\MAKE_INCLUDE_REC_REF -- unable to find include table index.%$');
  ref.incl_tag := dst_$rel_include;
  ref.incl_index := index;
  ref.incl_offset := offset.low;
  make_include_rec_ref := ref;
end;

{ make_relative_ref - target less base, tagged by its sign.

  0x06EE2E, 0x46 bytes: the difference in (-8,A6); tag 3 (`ori.b
  #-64') or 0 (`andi.b #63'); the low 30 bits or'd in; the result in
  D0. }

function make_relative_ref(
    base: integer32;
    target: integer32): dst_$rel_t; options(val_param); internal;
var
  diff: integer32;
  ref: dst_$rel_t;
begin
  diff := target - base;
  if diff < 0 then
    ref.tag := dst_$rel_negative
  else
    ref.tag := dst_$rel_positive;
  ref.offset := diff;
  make_relative_ref := ref;
end;

{ make_rec_ref - a written record's reference to another (relative in
  the same section, else through the include table; a nil one 0).
  0x06EE74, 0xAE bytes. }

function make_rec_ref(
    base: rec_p_t;
    dep: rec_p_t): dst_$rel_t; options(val_param); internal;
var
  ref: dst_$rel_t;
begin
  if base = nil then
    bug_check('\\PDS_\MAKE_REC_REF -- NIL base rec pointer.%$');
  if not (written_flag in base^.flags) then
    bug_check('\\PDS_\MAKE_REC_REF -- base rec has not been written.%$');
  if dep <> nil then begin
    if not (written_flag in dep^.flags) then
      bug_check('\\PDS_\MAKE_REC_REF -- dependent rec has not been written.%$');
    if base^.bucket = nil then
      bug_check('\\PDS_\MAKE_REC_REF -- NIL bucket back pointer.%$');
    if dep^.bucket = nil then
      bug_check('\\PDS_\MAKE_REC_REF -- NIL bucket back pointer.%$');
    if base^.bucket = dep^.bucket then
      ref := make_relative_ref(base^.offset, dep^.offset)
    else
      ref := make_include_rec_ref(base, dep);
  end
  else
    ref := make_relative_ref(0, 0);
  make_rec_ref := ref;
end;

{ make_type_ref - a type's reference: a standard type's code (the top
  24 bits cleared, `andi.l #255'), or the user defined type's record
  reference retagged (0 to 2, 1 and 3 kept; `move.w #192; and.b; lsr.w
  #6' and compares).  0x06EFF6, 0x11A bytes. }

function make_type_ref(
    base: rec_p_t;
    t: type_p_t): dst_$type_ref_t; options(val_param); internal;
var
  r: dst_$rel_t;
  ref: dst_$type_ref_t;
begin
  if base = nil then
    bug_check('\\PDS_\MAKE_TYPE_REF -- NIL base rec pointer.%$');
  if t = nil then
    bug_check('\\PDS_\MAKE_TYPE_REF -- typ_p is NIL.%$');
  if not (written_flag in base^.flags) then
    bug_check('\\PDS_\MAKE_TYPE_REF -- base rec has not been written.%$');
  if t^.code = user_type_code then begin
    if t^.rec = nil then
      bug_check('\\PDS_\MAKE_TYPE_REF -- user defined type with nil rec_p.%$');
    if not (written_flag in t^.rec^.flags) then
      bug_check('\\PDS_\MAKE_TYPE_REF -- dependent type rec has not been written.%$');
    r := make_rec_ref(base, t^.rec);
    case r.tag of
      dst_$rel_positive: ref.tag := dst_$rel_type_positive;
      dst_$rel_include: ref.tag := dst_$rel_include;
      dst_$rel_negative: ref.tag := dst_$rel_negative;
      otherwise
        bug_check('\\PDS_\MAKE_TYPE_REF -- Unknown dst_rel_offset tag.%$');
    end;
    ref.offset := r.offset;
  end
  else begin
    ref.std_zero := 0;
    ref.std_dtc := get_dtc(t^.code);
  end;
  make_type_ref := ref;
end;

{ make_name_ref - a written record's reference to a name in the string
  table (nil: 0).  0x06F254, 0x5E bytes. }

function make_name_ref(
    base: rec_p_t;
    name: name_p_t): dst_$rel_t; options(val_param); internal;
begin
  if base = nil then
    bug_check('\\PDS_\MAKE_NAME_REF -- NIL base rec pointer.%$');
  if not (written_flag in base^.flags) then
    bug_check('\\PDS_\MAKE_NAME_REF -- base rec has not been written.%$');
  if name <> nil then
    make_name_ref := make_relative_ref(base^.offset, name^.offset)
  else
    make_name_ref := make_relative_ref(0, 0);
end;

{ make_loc_ref - a written record's reference to a location in the
  location pool (+32 its offset); nil is -1 (`clr.l -(SP); pea 0x1').
  0x06F31A, 0x6A bytes. }

function make_loc_ref(
    base: rec_p_t;
    loc: loc_p_t): dst_$rel_t; options(val_param); internal;
var
  target: integer32;
begin
  if base = nil then
    bug_check('\\PDS_\MAKE_LOC_REF -- NIL base rec pointer.%$');
  if not (written_flag in base^.flags) then
    bug_check('\\PDS_\MAKE_LOC_REF -- base rec has not been written.%$');
  if loc <> nil then begin
    target := loc^.offset + loc_pool_base;
    make_loc_ref := make_relative_ref(base^.offset, target);
  end
  else
    make_loc_ref := make_relative_ref(1, 0);
end;

{ make_loc_ref_from_aux - as make_loc_ref from an auxiliary record.
  0x06F3EA, 0x6A bytes. }

function make_loc_ref_from_aux(
    base: aux_p_t;
    loc: loc_p_t): dst_$rel_t; options(val_param); internal;
var
  target: integer32;
begin
  if base = nil then
    bug_check('\\PDS_\MAKE_LOC_REF_FROM_AUX -- NIL base rec pointer.%$');
  if not (written_flag in base^.flags) then
    bug_check('\\PDS_\MAKE_LOC_REF_FROM_AUX -- base rec has not been written.%$');
  if loc <> nil then begin
    target := loc^.offset + loc_pool_base;
    make_loc_ref_from_aux := make_relative_ref(base^.offset, target);
  end
  else
    make_loc_ref_from_aux := make_relative_ref(1, 0);
end;

{ make_name_ref_from_aux - 0x06F4CC, 0x5E bytes. }

function make_name_ref_from_aux(
    base: aux_p_t;
    name: name_p_t): dst_$rel_t; options(val_param); internal;
begin
  if base = nil then
    bug_check('\\PDS_\MAKE_NAME_REF_FROM_AUX -- NIL base rec pointer.%$');
  if not (written_flag in base^.flags) then
    bug_check('\\PDS_\MAKE_NAME_REF_FROM_AUX -- base rec has not been written.%$');
  if name <> nil then
    make_name_ref_from_aux := make_relative_ref(base^.offset, name^.offset)
  else
    make_name_ref_from_aux := make_relative_ref(0, 0);
end;

{ make_rec_ref_from_aux - only within the section (another section's
  record a BUG_CHECK, the result then left unset).  0x06F5A4, 0xB0
  bytes. }

function make_rec_ref_from_aux(
    base: aux_p_t;
    dep: rec_p_t): dst_$rel_t; options(val_param); internal;
var
  ref: dst_$rel_t;
begin
  if base = nil then
    bug_check('\\PDS_\MAKE_REC_REF_FROM_AUX -- NIL base rec pointer.%$');
  if not (written_flag in base^.flags) then
    bug_check('\\PDS_\MAKE_REC_REF_FROM_AUX -- base rec has not been written.%$');
  if dep <> nil then begin
    if not (written_flag in dep^.flags) then
      bug_check('\\PDS_\MAKE_REC_REF_FROM_AUX -- dependent rec has not been written.%$');
    if base^.bucket = nil then
      bug_check('\\PDS_\MAKE_REC_REF_FROM_AUX -- NIL bucket back pointer.%$');
    if dep^.bucket = nil then
      bug_check('\\PDS_\MAKE_REC_REF_FROM_AUX -- NIL bucket back pointer.%$');
    if base^.bucket = dep^.bucket then
      ref := make_relative_ref(base^.offset, dep^.offset)
    else
      bug_check('\\PDS_\MAKE_REC_REF_FROM_AUX -- No support for incl reference from aux rec.%$');
  end
  else
    ref := make_relative_ref(0, 0);
  make_rec_ref_from_aux := ref;
end;

{ make_type_ref_from_aux - as make_type_ref; its unknown tag message is
  make_type_ref's (the same constant, `pea' of 0x06F152;
  docs/rev889-patterns.md 26).  0x06F79A,
  0x11A bytes. }

function make_type_ref_from_aux(
    base: aux_p_t;
    t: type_p_t): dst_$type_ref_t; options(val_param); internal;
var
  r: dst_$rel_t;
  ref: dst_$type_ref_t;
begin
  if base = nil then
    bug_check('\\PDS_\MAKE_TYPE_REF_FROM_AUX -- NIL base rec pointer.%$');
  if t = nil then
    bug_check('\\PDS_\MAKE_TYPE_REF_FROM_AUX -- typ_p is NIL.%$');
  if not (written_flag in base^.flags) then
    bug_check('\\PDS_\MAKE_TYPE_REF_FROM_AUX -- base rec has not been written.%$');
  if t^.code = user_type_code then begin
    if t^.rec = nil then
      bug_check('\\PDS_\MAKE_TYPE_REF_FROM_AUX -- user defined type with nil rec_p.%$');
    if not (written_flag in t^.rec^.flags) then
      bug_check('\\PDS_\MAKE_TYPE_REF_FROM_AUX -- dependent type rec has not been written.%$');
    r := make_rec_ref_from_aux(base, t^.rec);
    case r.tag of
      dst_$rel_positive: ref.tag := dst_$rel_type_positive;
      dst_$rel_include: ref.tag := dst_$rel_include;
      dst_$rel_negative: ref.tag := dst_$rel_negative;
      otherwise
        bug_check('\\PDS_\MAKE_TYPE_REF -- Unknown dst_rel_offset tag.%$');
    end;
    ref.offset := r.offset;
  end
  else begin
    ref.std_zero := 0;
    ref.std_dtc := get_dtc(t^.code);
  end;
  make_type_ref_from_aux := ref;
end;

{ add_aux_references - a written record's auxiliary records filled in.

  0x06F9EE, 0x1BE bytes: a jump table of 11; the type derivation's flag
  the boolean's top bit (`andi.b #-128') and the word's other 15 bits
  cleared. }

procedure add_aux_references(
    r: rec_p_t); options(val_param); internal;
var
  a: aux_p_t;
begin
  if r^.aux_head <> nil then begin
    if not (written_flag in r^.flags) then
      bug_check('\\PDS_\ADD_AUX_REFERENCES -- primary record has not yet been written.%$');
    a := r^.aux_head;
    while a <> nil do begin
      if not (written_flag in a^.flags) then
        bug_check('\\PDS_\ADD_AUX_REFERENCES -- aux record has not yet been written.%$');
      case a^.kind of
        aux_reg_val: begin
          a^.dst^.aux_w2 := a^.w20;
          a^.dst^.aux_ref4 := make_loc_ref_from_aux(a, a^.p22);
        end;
        aux_size:
          a^.dst^.aux_l2 := a^.l20;
        aux_align:
          a^.dst^.aux_w2 := a^.w20;
        aux_field_size, aux_field_off: begin
          a^.dst^.aux_w2 := a^.w20;
          a^.dst^.aux_l4 := a^.l22;
        end;
        aux_field_align: begin
          a^.dst^.aux_w2 := a^.w20;
          a^.dst^.aux_w4 := a^.w22;
        end;
        aux_name:
          a^.dst^.aux_ref2 := make_name_ref_from_aux(a, a^.p20);
        aux_var_bound: begin
          case a^.w20 of
            0: a^.dst^.aux_w2 := 0;
            1: a^.dst^.aux_w2 := 1;
            otherwise
              bug_check('\\PDS_\ADD_AUX_REFERENCES -- Unkown var bound aux.%$');
          end;
          a^.dst^.aux_ref4 := make_rec_ref_from_aux(a, a^.p22);
        end;
        aux_type_deriv: begin
          a^.dst^.aux_ref2 := make_type_ref_from_aux(a, a^.p20);
          a^.dst^.aux_w6 := a^.w24;
          a^.dst^.aux_deriv_flags.flag := a^.b26;
          a^.dst^.aux_deriv_flags.zero := 0;
        end;
        aux_lifetime:
          a^.dst^.aux_ref2 := make_loc_ref_from_aux(a, a^.p20);
        aux_ptr_base:
          a^.dst^.aux_ref2 := make_rec_ref_from_aux(a, a^.p20);
        otherwise
          bug_check('\\PDS_\ADD_AUX_REFERENCES -- unknown aux rec.%$');
      end;
      a := a^.next;
    end;
  end;
end;

{ add_references - a written record's DST record filled in: its name,
  source location (the file index in bits 30..20, the line in 19..0),
  locations, types and the kind's values; then its auxiliary records.

  0x06FC9C, 0xA14 bytes: a jump table of 23; every reference after its
  record is written; the bit fields stored by `andi'/`or' (the array's
  flags' byte, a bit field record field's position); kinds 1, 18 and
  19 a BUG_CHECK. }

procedure add_references(
    r: rec_p_t); options(val_param); internal;
var
  i: integer;
  d: dst_$rec_p_t;
begin
  if not (written_flag in r^.flags) then
    bug_check('\\PDS_\ADD_REFERENCES -- record has not yet been written.%$');
  d := r^.dst;
  case r^.kind of
    pointer_kind, alias_kind, file_kind: begin
      d^.name := make_name_ref(r, r^.name);
      d^.src_loc.file_index := r^.src_loc^.file_index;
      d^.src_loc.line := r^.src_loc^.line;
      d^.type_ref := make_type_ref(r, r^.type_p);
    end;
    variable_kind: begin
      d^.obj_name := make_name_ref(r, r^.name);
      d^.obj_loc := make_loc_ref(r, r^.loc);
      d^.obj_src_loc.file_index := r^.obj_src_loc^.file_index;
      d^.obj_src_loc.line := r^.obj_src_loc^.line;
      d^.var_type_ref := make_type_ref(r, r^.var_type);
      d^.var_attrs := get_var_attrs(r^.var_attrs);
    end;
    constant_kind: begin
      d^.con_name := make_name_ref(r, r^.name);
      d^.con_src_loc.file_index := r^.src_loc^.file_index;
      d^.con_src_loc.line := r^.src_loc^.line;
      d^.con_type_ref := make_type_ref(r, r^.type_p);
      d^.con_len := r^.value^.len;
      for i := 1 to r^.value^.len do
        d^.con_value[i] := r^.value^.bytes[i];
    end;
    label_kind: begin
      d^.obj_name := make_name_ref(r, r^.name);
      d^.obj_loc := make_loc_ref(r, r^.loc);
      d^.obj_src_loc.file_index := r^.obj_src_loc^.file_index;
      d^.obj_src_loc.line := r^.obj_src_loc^.line;
    end;
    entry_kind: begin
      d^.obj_name := make_name_ref(r, r^.name);
      d^.obj_loc := make_loc_ref(r, r^.loc);
      d^.obj_src_loc.file_index := r^.obj_src_loc^.file_index;
      d^.obj_src_loc.line := r^.obj_src_loc^.line;
      d^.entry_signature := make_rec_ref(r, r^.signature);
      d^.entry_b18 := r^.entry_w48 & 16#FF;
      d^.entry_b19 := 0;
    end;
    signature_kind: begin
      d^.sig_name := make_name_ref(r, r^.name);
      d^.sig_src_loc.file_index := r^.sig_src_loc^.file_index;
      d^.sig_src_loc.line := r^.sig_src_loc^.line;
      d^.sig_result := make_rec_ref(r, r^.sig_result);
      d^.sig_nargs := r^.nargs;
      for i := 1 to d^.sig_nargs do begin
        d^.sig_args[i].var_ref := make_rec_ref(r, r^.args[i]^.var_rec);
        d^.sig_args[i].attrs := get_arg_attrs(r^.args[i]^.attrs);
      end;
    end;
    incl_start_scope_kind: begin
      if r^.root = nil then
        bug_check('\\PDS_\ADD_REFERENCES -- Include start rec points to NIL root record.%$');
      d^.scope_root := make_rec_ref(r, r^.root^.lowest);
    end;
    short_record_kind: begin
      d^.agg_name := make_name_ref(r, r^.name);
      d^.agg_src_loc.file_index := r^.agg_src_loc^.file_index;
      d^.agg_src_loc.line := r^.agg_src_loc^.line;
      d^.agg_w10 := r^.rec_size;
      d^.agg_w12 := r^.rec_nfields;
      for i := 1 to r^.rec_nfields do begin
        d^.short_fields[i].name := make_name_ref(r, r^.short_fields[i]^.name);
        d^.short_fields[i].type_ref := make_type_ref(r, r^.short_fields[i]^.type_p);
        d^.short_fields[i].offset := r^.short_fields[i]^.offset & 16#FFFF;
      end;
    end;
    record_kind: begin
      d^.agg_name := make_name_ref(r, r^.name);
      d^.agg_src_loc.file_index := r^.agg_src_loc^.file_index;
      d^.agg_src_loc.line := r^.agg_src_loc^.line;
      d^.agg_w10 := r^.rec_size;
      d^.agg_w12 := r^.rec_nfields;
      for i := 1 to r^.rec_nfields do begin
        d^.fields[i].name := make_name_ref(r, r^.fields[i]^.name);
        d^.fields[i].type_ref := make_type_ref(r, r^.fields[i]^.type_p);
        if r^.fields[i]^.format = 0 then begin
          d^.fields[i].loc.tag := 0;
          d^.fields[i].loc.offset := r^.fields[i]^.offset;
        end
        else if r^.fields[i]^.format = 1 then begin
          d^.fields[i].loc.bf_tag := 1;
          d^.fields[i].loc.nbits := r^.fields[i]^.nbits;
          d^.fields[i].loc.flag := r^.fields[i]^.flag;
          d^.fields[i].loc.start_bit := r^.fields[i]^.start_bit;
          d^.fields[i].loc.zero := 0;
          d^.fields[i].loc.bf_offset := r^.fields[i]^.offset & 16#FFFF;
        end
        else
          bug_check('\\PDS_\ADD_REFERENCES -- Unknown field format.%$');
      end;
    end;
    set_kind: begin
      d^.set_name := make_name_ref(r, r^.name);
      d^.set_src_loc.file_index := r^.src_loc^.file_index;
      d^.set_src_loc.line := r^.src_loc^.line;
      d^.set_type_ref := make_type_ref(r, r^.type_p);
      d^.set_nelements := r^.set_nelements;
      d^.set_size := r^.set_size;
    end;
    offset_kind: begin
      d^.name := make_name_ref(r, r^.name);
      d^.src_loc.file_index := r^.src_loc^.file_index;
      d^.src_loc.line := r^.src_loc^.line;
      d^.type_ref := make_type_ref(r, r^.type_p);
      d^.type_ref2 := make_type_ref(r, r^.type2);
      d^.l18 := r^.l48;
      d^.l22 := r^.l52;
      d^.l26 := r^.l56;
      d^.offset_w30 := r^.w60;
      d^.offset_w32 := r^.w62;
    end;
    array_kind: begin
      d^.name := make_name_ref(r, r^.name);
      d^.src_loc.file_index := r^.src_loc^.file_index;
      d^.src_loc.line := r^.src_loc^.line;
      d^.type_ref := make_type_ref(r, r^.type_p);
      d^.type_ref2 := make_type_ref(r, r^.type2);
      d^.l18 := r^.l48;
      d^.l22 := r^.l52;
      d^.l26 := r^.l56;
      d^.l30 := r^.l60;
      d^.array_b7 := r^.b64;
      d^.array_b6 := r^.b65;
      d^.array_b5 := r^.b66;
      case r^.span of
        0: d^.array_span := 0;
        1: d^.array_span := 1;
        2: d^.array_span := 2;
        otherwise
          bug_check('\\PDS_\ADD_REFERENCES -- Unknown span kind.%$');
      end;
      d^.array_b2 := r^.b70;
      d^.array_zero := 0;
      d^.array_b35 := r^.w72 & 16#FF;
    end;
    string_kind: begin
      d^.name := make_name_ref(r, r^.name);
      d^.src_loc.file_index := r^.src_loc^.file_index;
      d^.src_loc.line := r^.src_loc^.line;
      d^.type_ref := make_type_ref(r, r^.type_p);
      d^.type_ref2 := make_type_ref(r, r^.type2);
      d^.l18 := r^.l48;
      d^.l22 := r^.l52;
      d^.l26 := r^.l56;
    end;
    implicit_enum_kind: begin
      d^.agg_name := make_name_ref(r, r^.name);
      d^.agg_src_loc.file_index := r^.agg_src_loc^.file_index;
      d^.agg_src_loc.line := r^.agg_src_loc^.line;
      d^.agg_w10 := r^.enum_nelements;
      d^.agg_w12 := r^.enum_size;
      for i := 1 to r^.enum_nelements do
        d^.implicit[i] := make_name_ref(r, r^.implicit[i]);
    end;
    explicit_enum_kind: begin
      d^.agg_name := make_name_ref(r, r^.name);
      d^.agg_src_loc.file_index := r^.agg_src_loc^.file_index;
      d^.agg_src_loc.line := r^.agg_src_loc^.line;
      d^.agg_w10 := r^.enum_nelements;
      d^.agg_w12 := r^.enum_size;
      for i := 1 to r^.enum_nelements do begin
        d^.explicit[i].name := make_name_ref(r, r^.explicit[i]^.name);
        d^.explicit[i].value := r^.explicit[i]^.value;
      end;
    end;
    subrange_kind: begin
      d^.sub_name := make_name_ref(r, r^.name);
      d^.sub_src_loc.file_index := r^.src_loc^.file_index;
      d^.sub_src_loc.line := r^.src_loc^.line;
      d^.sub_type_ref := make_type_ref(r, r^.type_p);
      d^.sub_l14 := r^.sub_l44;
      d^.sub_l18 := r^.sub_l48;
      d^.sub_w22 := r^.sub_size;
    end;
    end_scope_kind, incl_end_scope_kind:
      ;
    otherwise
      bug_check('\\PDS_\ADD_REFERENCES -- NOT IMPLEMENTED YET.%$');
  end;
  add_aux_references(r);
end;

{ dump_incl_table - under -CD, the bucket's include table written (kind
  55, 10 bytes an entry at its index: the offset's high word and the
  section's CRC), and the header's reference to it (none: 0).

  0x0707C2, 0xEC bytes: the size count * 10 + 4 (unsigned); the entries
  counted while written and checked against the count; the reference
  from the header's offset (+1066) to the table's. }

procedure dump_incl_table(
    b: bucket_p_t;
    in out pos: integer32); options(val_param); internal;
var
  size, start: integer32;
  r: dst_$rec_p_t;
  n, i: integer;
  node: crc_node_p_t;
begin
  if cargs_$options.cd then begin
    if b^.crc_count = 0 then
      b^.header^.hdr_incl_table := make_relative_ref(0, 0)
    else begin
      size := b^.crc_count * 10 + 4;
      start := pos;
      r := allocate_dst_rec(b, pos, size);
      r^.kind := dst_$incl_table;
      r^.incl_count := b^.crc_count;
      n := 0;
      for i := 0 to 255 do begin
        node := b^.crcs[i];
        while node <> nil do begin
          n := n + 1;
          r^.incl[node^.index].crc1 := node^.bucket^.crc1;
          r^.incl[node^.index].crc2 := node^.bucket^.crc2;
          r^.incl[node^.index].offset := node^.offset;
          node := node^.next;
        end;
      end;
      if n <> b^.crc_count then
        bug_check('\\PDS_\DUMP_STRING_TABLE -- include table size doesn''t agree with bucket''s include table size.%$');
      b^.header^.hdr_incl_table := make_relative_ref(b^.header_offset, start);
    end;
  end;
end;

{ sprinkle_incl_end_scope_recs - under -CD, an include end record
  appended to every include file's bucket.  0x07090E, 0x5E bytes. }

procedure sprinkle_incl_end_scope_recs; internal;
var
  i: integer;
  r: rec_p_t;
  b: bucket_p_t;
begin
  if cargs_$options.cd then
    for i := 1 to nfiles do
      if i <> main_index then begin
        r := make_incl_end_scope_rec;
        b := get_bucket(i);
        append_root_rec_to_bucket(b, r);
      end;
end;

{ do_dfs_ordering - the buckets in depth first order: a bucket after
  the buckets it refers to, appended to the order (+20, +24) once none
  is left pending; its referrers' counts taken down.

  0x07096C, 0x9E bytes: +3135 bit 0 visited, bit 1 on the list. }

procedure do_dfs_ordering(
    node: bucket_p_t); options(val_param); internal;
var
  e: bucket_list_p_t;
begin
  if node = nil then
    bug_check('\\PDS_\DO_DFS_ORDERING -- node_p is NIL.%$');
  if visited_flag in node^.dfs_flags then
    return;
  node^.dfs_flags := node^.dfs_flags + [visited_flag];
  e := node^.succs;
  while e <> nil do begin
    do_dfs_ordering(e^.bucket);
    e := e^.next;
  end;
  if node^.pending_succs = 0 then begin
    node^.dfs_next := nil;
    node^.dfs_prev := dfs_tail;
    if dfs_head = nil then
      dfs_head := node
    else
      dfs_tail^.dfs_next := node;
    dfs_tail := node;
    node^.dfs_flags := node^.dfs_flags + [on_dfs_list_flag];
    e := node^.preds;
    while e <> nil do begin
      e^.bucket^.pending_succs := e^.bucket^.pending_succs - 1;
      e := e^.next;
    end;
  end
  else
    bug_check('\\PDS_\DO_DFS_ORDERING --- Supposed to be a DAG by this point.%$');
end;

{ do_merge - the buckets of the merge list (head to tail) merged into
  one new bucket (one alone is itself): their root lists joined, their
  bitmaps or'd, an include file only if all are; the bucket table's
  entries changed to it.

  0x070A74, 0x132 bytes: the new bucket 3154 bytes (`st (A3)', +3122
  -1, the bitmap); the bits or'd one by one (`btst', `sne', `or.b' and
  the masked store). }

function do_merge(
    head: bucket_list_p_t;
    tail: bucket_list_p_t): bucket_p_t; options(val_param); internal;
var
  node: bucket_list_p_t;
  m: bucket_p_t;
  i: integer;
begin
  if head = tail then begin
    do_merge := head^.bucket;
    return;
  end;
  node := head;
  m := mem_$alloc(general_pool, 3154);
  m^.is_include := true;
  m^.first_offset := -1;
  m^.refs := mem_$alloc(general_pool, (nfiles + 7) div 8);
  while node <> nil do begin
    m^.is_include := m^.is_include and node^.bucket^.is_include;
    if m^.first_root = nil then
      m^.first_root := node^.bucket^.first_root
    else
      m^.last_root^.next := node^.bucket^.first_root;
    m^.last_root := node^.bucket^.last_root;
    for i := 1 to nfiles do begin
      m^.refs^[i] := m^.refs^[i] or node^.bucket^.refs^[i];
      if bucket_table^[i] = node^.bucket then
        bucket_table^[i] := m;
    end;
    node := node^.next;
  end;
  do_merge := m;
end;

{ append_to_merge_list - a bucket entered in the merge list (from the
  merge pool): the main file's at the end, an include file's in the
  order of its first root record's name.

  0x070BA6, 0xF2 bytes: the search stops at the main file's bucket or
  at the first name after this one's. }

procedure append_to_merge_list(
    b: bucket_p_t;
    in out head: bucket_list_p_t;
    in out tail: bucket_list_p_t); options(val_param); internal;
var
  node, p, prev: bucket_list_p_t;
  name, name2: name_p_t;
begin
  node := mem_$alloc(merge_pool, 8);
  node^.bucket := b;
  if head = nil then begin
    head := node;
    tail := node;
  end
  else if get_bucket(main_index) = b then begin
    tail^.next := node;
    tail := node;
  end
  else begin
    name := get_name_p(b^.first_root);
    prev := nil;
    p := head;
    while (p <> nil) and then (get_bucket(main_index) <> p^.bucket) do begin
      name2 := get_name_p(p^.bucket^.first_root);
      if name2 = nil then
        bug_check('\\PDS_\APPEND_TO_MERGE_LIST -- at this point, all root records within .s. sections are supposed to have a name.%$');
      if compare_bytes_case(name^.chars, name^.len, name2^.chars,
          name2^.len, case_fold) < 0 then
        exit;
      prev := p;
      p := p^.next;
    end;
    if prev = nil then begin
      node^.next := head;
      head := node;
    end
    else begin
      prev^.next := node;
      node^.next := p;
      if p = nil then
        tail := node;
    end;
  end;
end;

{ add_to_dag - a bucket appended to the DAG's list (+0, +4).
  0x070D0A, 0x38 bytes. }

procedure add_to_dag(
    b: bucket_p_t); options(val_param); internal;
var
  node: bucket_list_p_t;
begin
  node := mem_$alloc(general_pool, 8);
  node^.bucket := b;
  if dag_head = nil then
    dag_head := node
  else
    dag_tail^.next := node;
  dag_tail := node;
end;

{ dag_visit - Tarjan's walk from file index: the strongly connected
  sets of buckets (files referring to each other) merged, each set
  added to the DAG; its lowest visit number returned.

  0x070D42, 0x14C bytes: the visit number (+94) in (+12)[index]; the
  stack (+8) indexed by its depth before the push (a 1-based array:
  depth 0 is the word before it); a set's members popped into the
  merge list from the merge pool (mark and release around it), their
  numbers set to 32767; the numbers compared unsigned. }

function dag_visit(
    index: integer): integer; options(val_param); internal;
var
  low, v, i: integer;
  b: bucket_p_t;
  mark: mem_$mark_t;
  merged: bucket_p_t;
begin
  visit_count := visit_count + 1;
  visit_numbers^[index] := visit_count;
  low := visit_count;
  dag_stack^[dag_depth] := index;
  dag_depth := dag_depth + 1;
  b := get_bucket(index);
  for i := 1 to nfiles do
    if (i <> index) and b^.refs^[i] then begin
      if visit_numbers^[i] = 0 then
        v := dag_visit(i)
      else
        v := visit_numbers^[i];
      if v < low then
        low := v;
    end;
  if low = visit_numbers^[index] then begin
    merge_head := nil;
    merge_tail := nil;
    mark := mem_$mark(merge_pool);
    repeat
      dag_depth := dag_depth - 1;
      append_to_merge_list(get_bucket(dag_stack^[dag_depth]), merge_head,
        merge_tail);
      visit_numbers^[dag_stack^[dag_depth]] := 32767;
    until dag_stack^[dag_depth] = index;
    merged := do_merge(merge_head, merge_tail);
    mem_$release(mark);
    add_to_dag(merged);
  end;
  dag_visit := low;
end;

{ build_dependency_graph - each DAG bucket's edges to the buckets it
  refers to (its successors, counted) and back; the main file's bucket
  returned.

  0x070E8E, 0xBC bytes: get_bucket for every file; the edges from the
  general pool; the result from (-12,A6), unset when every bucket is an
  include file's. }

function build_dependency_graph: bucket_p_t; internal;
var
  node, e: bucket_list_p_t;
  b, other, root: bucket_p_t;
  i: integer;
begin
  node := dag_head;
  while node <> nil do begin
    b := node^.bucket;
    for i := 1 to nfiles do begin
      other := get_bucket(i);
      if (other <> b) and b^.refs^[i] then begin
        e := mem_$alloc(general_pool, 8);
        e^.bucket := other;
        e^.next := b^.succs;
        b^.succs := e;
        b^.pending_succs := b^.pending_succs + 1;
        e := mem_$alloc(general_pool, 8);
        e^.bucket := b;
        e^.next := other^.preds;
        other^.preds := e;
      end;
    end;
    if not b^.is_include then
      root := b;
    node := node^.next;
  end;
  build_dependency_graph := root;
end;

{ construct_a_dag - the visit numbers and the stack (nfiles words
  each); dag_visit from the root file; the graph built.  0x070F4A,
  0x62 bytes. }

function construct_a_dag(
    root_index: integer): bucket_p_t; options(val_param); internal;
var
  low: integer;
begin
  visit_numbers := mem_$alloc(general_pool, nfiles * 2);
  dag_stack := mem_$alloc(general_pool, nfiles * 2);
  low := dag_visit(root_index);
  if dag_head = nil then
    bug_check('\\PDS_\CONSTRUCT_A_DAG -- dag_head is NIL.%$');
  construct_a_dag := build_dependency_graph;
end;

{ pds_$create_symbols_sections - 0x070FD8, 0xC0 bytes: the DAG built
  from the main file and ordered; a section made for each bucket from
  the order's tail back (the main bucket first), its number at +1054;
  one bucket only unless -CD; the first to write the order's head.
  Two of the messages end in `%' alone. }

procedure pds_$create_symbols_sections(
    create_section: pds_$create_section_func_t);
var
  root, b: bucket_p_t;
  count: integer;
begin
  sprinkle_incl_end_scope_recs;
  root := construct_a_dag(main_index);
  do_dfs_ordering(root);
  if (dfs_head = nil) or (dfs_tail = nil) then
    bug_check('PDS_$CREATE_SYMBOLS_SECTIONS --- dfs_order_head/tail = NIL.%$');
  if dfs_tail^.is_include then
    bug_check('PDS_$CREATE_SYMBOLS_SECTIONS --- dfs_order_tail should always be the root bucket.%$');
  count := 0;
  b := dfs_tail;
  while b <> nil do begin
    if not (on_dfs_list_flag in b^.dfs_flags) then
      bug_check('PDS_$CREATE_SYMBOLS_SECTIONS --- bucket should be marked as on dfs list.%');
    b^.section := create_section^(b^.is_include);
    b := b^.dfs_prev;
    count := count + 1;
  end;
  if not cargs_$options.cd then
    if count <> 1 then
      bug_check('PDS_$CREATE_SYMBOLS_SECTIONS --- Should only have one bucket.%');
  current_bucket := dfs_head;
end;

{ calculate_crc - under -CD, the two CRCs (the section's name) of the
  bucket's bytes in the object file, read back through the allocator
  in pieces of at most 163808 bytes.

  0x0711B2, 0x134 bytes: per piece both CRCs start at -1; for each 128
  bytes (`lsr.l #7') one 16-byte block is hashed (two quads, one to
  each CRC: HTM_$HASH_RUNNING_QUAD_MULTIPLE), then the rest (`and 127',
  odd a BUG_CHECK) a byte to each in turn
  (HTM_$HASH_RUNNING_BYTE_MULTIPLE); the last values (D4, D3) stored at
  +2 and +6. }

procedure calculate_crc(
    b: bucket_p_t); options(val_param); internal;
var
  pos, size, chunk, len, rest: integer32;
  crc1, crc2: integer32;
  addr: integer32;
  blocks: crc_blocks_p_t;
  bytes: crc_bytes_p_t;
  nblocks, i, k: integer;
begin
  if not cargs_$options.cd then
    bug_check('\\PDS_\CALCULATE_CRC --- Should never get here.%$');
  pos := b^.first_offset;
  size := b^.size;
  while size <> 0 do begin
    chunk := size;
    if chunk > max_dst_rec_size then
      chunk := max_dst_rec_size;
    len := pos;
    addr := alloc_obj_func^(pos, chunk);
    len := pos - len;
    rest := len & 127;
    nblocks := rshft(len, 7);
    crc1 := -1;
    crc2 := -1;
    blocks := crc_blocks_p_t(addr);
    for i := 1 to nblocks do begin
      crc1 := htm_$hash_running_quad_multiple(crc1, blocks^[i].q0, blocks^[i].q1);
      crc2 := htm_$hash_running_quad_multiple(crc2, blocks^[i].q2, blocks^[i].q3);
    end;
    if odd(rest) then
      bug_check('\\PDS_\CALCULATE_CRC --- Odd section size??.%$');
    bytes := crc_bytes_p_t(addr + nblocks * 16);
    k := 0;
    for i := 1 to rshft(rest, 1) do begin
      crc1 := htm_$hash_running_byte_multiple(crc1, bytes^[k + 1]);
      crc2 := htm_$hash_running_byte_multiple(crc2, bytes^[k + 2]);
      k := k + 2;
    end;
    size := size - chunk;
  end;
  b^.crc1 := crc1;
  b^.crc2 := crc2;
end;

{ add_local_file_entry - a source location's file entered in the
  bucket's local file table (an include file's section: by name and
  id), the location's index changed to the table's.

  0x071346, 0x100 bytes: the main table's entry (+28)[file_index]; the
  chain of the name's hash (+2096); a new node of 14 bytes (the entry
  copied, the index the incremented count +3120); the name entered
  through a local copy (add_file_string). }

procedure add_local_file_entry(
    b: bucket_p_t;
    r: rec_p_t;
    s: src_loc_p_t); options(val_param); internal;
var
  name, name_copy: name_p_t;
  id: integer32;
  h: integer;
  node: lf_node_p_t;
begin
  if s^.file_index <> 0 then begin
    name := main_file_table^.entries[s^.file_index]^.name;
    id := main_file_table^.entries[s^.file_index]^.id;
    if name = nil then
      bug_check('\\PDS_\ADD_LOCAL_FILE_TABLE_ENTRY -- name_p is NIL.%$');
    h := hash_it(name^.chars, name^.len) & 16#FF;
    node := b^.local_files[h];
    while node <> nil do begin
      if id = node^.entry.id then
        if node^.entry.name^.len = name^.len then
          if memcmp(node^.entry.name^.chars, name^.chars, name^.len) = 0 then begin
            s^.file_index := node^.index;
            return;
          end;
      node := node^.next;
    end;
    name_copy := name;
    add_file_string(b, name_copy);
    node := mem_$alloc(general_pool, 14);
    node^.entry := main_file_table^.entries[s^.file_index]^;
    b^.local_file_count := b^.local_file_count + 1;
    node^.index := b^.local_file_count;
    node^.next := b^.local_files[h];
    b^.local_files[h] := node;
    s^.file_index := node^.index;
  end;
end;

{ pool_local_file_table_entries - under -CD, a record's source file in
  its bucket's local file table.  0x07147C, 0xD4 bytes: a jump table
  of 23 (the location at +40 for variables, labels and entries, +36
  for the others). }

procedure pool_local_file_table_entries(
    b: bucket_p_t;
    r: rec_p_t); options(val_param); internal;
begin
  if cargs_$options.cd then
    case r^.kind of
      variable_kind, label_kind, entry_kind:
        add_local_file_entry(b, r, r^.obj_src_loc);
      0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17:
        add_local_file_entry(b, r, r^.src_loc);
      end_scope_kind, incl_start_scope_kind, incl_end_scope_kind:
        ;
      otherwise
        bug_check('\\PDS_\POOL_LOCAL_FILE_TABLE_ENTRIES -- unknown rec type.%$');
    end;
end;

{ dump_section_header - under -CD, the section's header (kind 58, 10
  bytes), its offset kept (+1066).  0x07158C, 0x3E bytes. }

procedure dump_section_header(
    b: bucket_p_t;
    in out pos: integer32); options(val_param); internal;
begin
  if cargs_$options.cd then begin
    b^.header_offset := pos;
    b^.header := allocate_dst_rec(b, pos, 10);
    b^.header^.kind := dst_$section_header;
  end;
end;

{ dump_local_file_table - under -CD, the local file table (kind 3, 8
  bytes an entry at its index: the id and the name's reference) and
  the header's reference to it (none: 0).

  0x0715CA, 0xE4 bytes: the size count * 8 + 4 (word arithmetic). }

procedure dump_local_file_table(
    b: bucket_p_t;
    in out pos: integer32); options(val_param); internal;
var
  start: integer32;
  r: dst_$rec_p_t;
  i: integer;
  node: lf_node_p_t;
begin
  if cargs_$options.cd then begin
    if b^.local_file_count = 0 then
      b^.header^.hdr_local_files := make_relative_ref(0, 0)
    else begin
      start := pos;
      r := allocate_dst_rec(b, pos, b^.local_file_count * 8 + 4);
      r^.kind := dst_$local_file_table;
      r^.lft_count := b^.local_file_count;
      for i := 0 to 255 do begin
        node := b^.local_files[i];
        while node <> nil do begin
          r^.lft[node^.index].id := node^.entry.id;
          if node^.entry.name = nil then
            bug_check('\\PDS_\DUMP_LOCAL_FILE_TABLE -- name_p is NIL.%$');
          r^.lft[node^.index].name := make_relative_ref(start, node^.entry.name^.offset);
          node := node^.next;
        end;
      end;
      b^.header^.hdr_local_files := make_relative_ref(b^.header_offset, start);
    end;
  end;
end;

{ append_ordered_rec_to_bucket - a record at the end of the bucket's
  ordered list (sharing the root list's link), its bucket set; the
  first under a root is the root's lowest.  0x0716DE, 0x4C bytes. }

procedure append_ordered_rec_to_bucket(
    b: bucket_p_t;
    root: rec_p_t;
    r: rec_p_t); options(val_param); internal;
begin
  if b^.first_ordered = nil then
    b^.first_ordered := r
  else
    b^.last_ordered^.next := r;
  b^.last_ordered := r;
  r^.bucket := b;
  r^.flags := r^.flags + [ordered_flag];
  if root^.lowest = nil then
    root^.lowest := r;
end;

{ order_this_rec - a record ordered after the records it refers to
  (the same root's); one already ordered or still on a root list is
  skipped.

  0x07172A, 0x1D4 bytes: `moveq #6; and.w (10,A2)' (flags 1 and 2); a
  jump table of 23; the signature's loop indexes from 1. }

procedure order_this_rec(
    b: bucket_p_t;
    root: rec_p_t;
    r: rec_p_t); options(val_param); internal;
var
  i: integer;
begin
  if r = nil then
    return;
  if r^.flags * [in_bucket_flag, ordering_flag] <> [] then
    return;
  r^.flags := r^.flags + [ordering_flag];
  case r^.kind of
    pointer_kind:
      order_this_rec(b, root, r^.type_p^.rec);
    variable_kind:
      order_this_rec(b, root, r^.var_type^.rec);
    constant_kind:
      order_this_rec(b, root, r^.type_p^.rec);
    signature_kind: begin
      order_this_rec(b, root, r^.sig_result);
      for i := 1 to r^.nargs do
        order_this_rec(b, root, r^.args[i]^.var_rec);
    end;
    alias_kind:
      order_this_rec(b, root, r^.type_p^.rec);
    entry_kind:
      order_this_rec(b, root, r^.signature);
    short_record_kind, record_kind:
      for i := 1 to r^.rec_nfields do
        order_this_rec(b, root, r^.short_fields[i]^.type_p^.rec);
    set_kind:
      order_this_rec(b, root, r^.type_p^.rec);
    file_kind:
      order_this_rec(b, root, r^.type_p^.rec);
    offset_kind, array_kind, string_kind: begin
      order_this_rec(b, root, r^.type_p^.rec);
      order_this_rec(b, root, r^.type2^.rec);
    end;
    subrange_kind:
      order_this_rec(b, root, r^.type_p^.rec);
    implicit_enum_kind, explicit_enum_kind, label_kind, end_scope_kind,
    incl_start_scope_kind, incl_end_scope_kind:
      ;
    otherwise
      bug_check('\\PDS_\ORDER_THIS_REC -- unknown rec type.%$');
  end;
  append_ordered_rec_to_bucket(b, root, r);
end;

{ construct_ordered_rec_list - each root record (its root list flag
  cleared) ordered under itself.  0x07192A, 0x3C bytes. }

procedure construct_ordered_rec_list(
    b: bucket_p_t); options(val_param); internal;
var
  r: rec_p_t;
begin
  r := b^.first_root;
  while r <> nil do begin
    r^.flags := r^.flags - [in_bucket_flag];
    order_this_rec(b, r, r);
    r := r^.next;
  end;
end;

{ pds_$dump_symbols_section - 0x071966, 0x212 bytes: the allocator kept
  (+44) and dump_loc_func_p (+40, not used); the bucket to write must
  be the section's; its records ordered; for each, the local file
  table (an include file's), the include table and the strings pooled;
  the header, string table, include table, local file table, records
  (pos through (-276,A6)), the location pool (the main section), the
  references; the section named: `.symbols', or `.s.' and the two CRCs
  in hexadecimal (PRTCATS, PRTHEX into (-264,A6)) folded to lower
  case; the next bucket in order (+3146). }

procedure pds_$dump_symbols_section(
    section: integer32;
    start_offset: integer32;
    out end_offset: integer32;
    alloc_obj_func_p: pds_$alloc_obj_func_t;
    dump_loc_func_p: univ_ptr;
    add_section_name_p: pds_$add_section_name_func_t);
var
  pos: integer32;
  is_main: boolean;
  r: rec_p_t;
  name: prtsub_$line_t;
begin
  if alloc_obj_func_p = nil then
    bug_check('PDS_$DUMP_SYMBOLS_SECTION -- alloc_obj_func_p is NIL.%$');
  if dump_loc_func_p = nil then
    bug_check('PDS_$DUMP_SYMBOLS_SECTION -- dump_loc_func_p is NIL.%$');
  if add_section_name_p = nil then
    bug_check('PDS_$DUMP_SYMBOLS_SECTION -- add_section_name_p is NIL.%$');
  alloc_obj_func := alloc_obj_func_p;
  dump_loc_func := dump_loc_func_p;
  if current_bucket^.section <> section then
    bug_check('PDS_$DUMP_SYMBOLS_SECTION -- Must dump sections in dfs order!!!%$');
  construct_ordered_rec_list(current_bucket);
  is_main := not current_bucket^.is_include;
  r := current_bucket^.first_ordered;
  while r <> nil do begin
    if not is_main then
      pool_local_file_table_entries(current_bucket, r);
    pool_crc_entries(current_bucket, r);
    pool_strings(current_bucket, r);
    r := r^.next;
  end;
  current_bucket^.base := start_offset;
  pos := start_offset;
  dump_section_header(current_bucket, pos);
  dump_string_table(current_bucket, pos);
  dump_incl_table(current_bucket, pos);
  dump_local_file_table(current_bucket, pos);
  r := current_bucket^.first_ordered;
  while r <> nil do begin
    dump_rec(current_bucket, r, pos);
    r := r^.next;
  end;
  if is_main then
    dump_loc_pool(current_bucket, pos);
  r := current_bucket^.first_ordered;
  while r <> nil do begin
    add_references(r);
    r := r^.next;
  end;
  if is_main then
    add_section_name_p^(section, '.symbols', 8)
  else begin
    calculate_crc(current_bucket);
    name.length := 0;
    prtcats(name, '.s.', 3);
    prthex(name, current_bucket^.crc1, 8);
    prthex(name, current_bucket^.crc2, 8);
    downcase_string(name.body, name.length);
    add_section_name_p^(section, name.body, name.length);
  end;
  current_bucket := current_bucket^.dfs_next;
  end_offset := pos;
end;
