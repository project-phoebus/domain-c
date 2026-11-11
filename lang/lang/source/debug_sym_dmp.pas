{ debug_sym_dmp - DEBUG_SYM_DMP, the debugging symbol sections of the
  object module (-DB, -DBS, -DBA): the .symbols sections (PDS_ records
  made for each routine's named objects, their locations built with the
  debugger library's LOC_BUILD_ and fixed up once the code is placed)
  and the .blocks section (its header, the two string tables of the
  routines' names, the block tree with each block's code ranges and
  exception table entries, the section table and the local file table).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0A8350  0x0A9D30  sz_fsym
    0x0A83B0  0x0A9D90  allocfunc
    0x0A8428  0x0A9E08  dumpfunc
    0x0A847A  0x0A9E5A  obj_alloc
    0x0A84C0  0x0A9EA0  add_symbols_section
    0x0A8554  0x0A9F34  add_name_to_symbols_section
    0x0A8664  0x0AA044  varn_from_fortran_symbol
    0x0A8764  0x0AA144  label_from_fortran_symbol (internal)
    0x0A87F4  0x0AA1D4  get_include_file_index
    0x0A8864  0x0AA244  add_to_reloc_obj_list (internal)
    0x0A8984  0x0AA364  prep_sections (internal)
    0x0A8A14  0x0AA3F4  add_obj_to_loc_fixup_list (internal)
    0x0A8A50  0x0AA430  reg_translate_at (internal)
    0x0A8AD4  0x0AA4B4  reg_translate_68k (internal)
    0x0A8B0C  0x0AA4EC  get_memory_loc (internal)
    0x0A8FD8  0x0AA9B8  get_var_location_rep (internal)
    0x0A937C  0x0AAD5C  get_sect_rel_location_rep (internal)
    0x0A9458  0x0AAE38  debug_sym_dmp_$add_loc_info
    0x0A9700  0x0AB0E0  may_need_common_aux (internal)
    0x0A99B6  0x0AB396  is_simple_type (internal)
    0x0A9A6E  0x0AB44E  get_name_rep (internal)
    0x0A9B44  0x0AB524  get_src_loc_rep (internal)
    0x0A9B80  0x0AB560  get_alias_rep (internal)
    0x0A9BF8  0x0AB5D8  get_variable_rep (internal)
    0x0A9DA2  0x0AB782  get_signature_rep (internal)
    0x0A9F52  0x0AB932  get_tag (internal)
    0x0A9FBC  0x0AB99C  get_record_rep
    0x0AA2B6  0x0ABC96  get_enum_rep
    0x0AA422  0x0ABE02  get_type_rep (internal)
    0x0AAA88  0x0AC468  get_label_rep (internal)
    0x0AAB30  0x0AC510  get_const_rep (internal)
    0x0AAE5E  0x0AC83E  get_entry_rep (internal)
    0x0AAF30  0x0AC910  skip_unreferenced_include_object (internal)
    0x0AAFB6  0x0AC996  process_named_objects (internal)
    0x0AB344  0x0ACD24  process_debug_symbols (internal)
    0x0AB3B8  0x0ACD98  debug_sym_dmp_$create_symbols_sections
    0x0AB400  0x0ACDE0  debug_sym_dmp_$dump_symbols_section
    0x0AB440  0x0ACE20  create_string_table (internal)
    0x0AB45C  0x0ACE3C  dump_string_table (internal)
    0x0AB55E  0x0ACF3E  clear_emitted_marker (internal)
    0x0AB5C2  0x0ACFA2  force_add_string (internal)
    0x0AB656  0x0AD036  add_string (internal)
    0x0AB6AA  0x0AD08A  get_debug_offset (internal)
    0x0AB6E2  0x0AD0C2  get_src_loc (internal)
    0x0AB742  0x0AD122  make_relative_ref (internal)
    0x0AB78A  0x0AD16A  write_blocks (internal)
    0x0ABB62  0x0AD542  add_file_table_entry (in write_files)
    0x0ABC00  0x0AD5E0  write_string_for_file_table_entry (in write_files)
    0x0ABC52  0x0AD632  add_unit_table_entry (in write_files)
    0x0ABCAA  0x0AD68A  write_files (internal)
    0x0ABF66  0x0AD946  gen_section_table (internal)
    0x0AC156  0x0ADB36  build_block_list (internal)
    0x0AC20A  0x0ADBEA  debug_sym_dmp_$block_dmp
    0x0AC3BC  0x0ADD9C  add_file_entry (in debug_sym_dmp_$init)
    0x0AC44A  0x0ADE2A  debug_sym_dmp_$init
    0x0AC5E4  0x0ADFC4  debug_sym_dmp_$finalize
    A5 0x2C20CC (cc.m68k), 0x44213C (cc.a88k): the module's data, 4252
    bytes.  The binaries differ only in the absolute addresses (the
    cargs record's offsets are the same).

  Module data as the image lays it out (.rwdi where marked):
    +0     the block structure heap (MRH, 12-byte block list elements)
    +24    the (type, variable) pairs of the current routine's
           parameters (get_variable_rep), their count a word; the pairs
           from +26
    +4128  the loc fixup heap (MRH, 16-byte fixups), +4152 the locs heap
           (allocfunc's, LOC_BUILD_'s storage)
    +4176  and +4192 the two string tables (12 bytes each)
    +4204  the loc fixup list (.rwdi: nil), +4208 the .symbols sections
           made (.rwdi: nil), +4212 the object file offset being
           written, +4216 the routine whose named objects are processed,
           +4220/+4224 the current and first blocks of the relocated
           objects' list, +4228 the location pool, +4232 a longword
           (.rwdi: 0) whose address goes into indirect locations,
           +4236 the relocated objects' count (a word), +4238 the fold
           case flag, +4240 gen_utils's debug_sym_dmp_1090, +4242 a byte
           nothing reads (.rwdi: 0), +4244 and +4248 the variable and
           label nodes made for Fortran symbols (.rwdi: nil).
    Large variables lie at multiples of 8 (the heaps, the tables).

  The global routines load A5; the others (no A5 load) are internal.
  The routines nested in write_files and debug_sym_dmp_$init are passed
  to spos_$apply_over_marked_source_files and spos_$apply_over_source_
  files as routine parameters: Rev 8.89 builds a trampoline for each in
  the parent's frame (docs/rev889-patterns.md 12), the nested routine
  takes the parent's frame from A1 and loads A5 itself.  dpc refuses
  the routine parameter (docs/dpc-gaps.md 21); tools/cc_gap_rewrites.txt
  checks a copy that passes nil.

  The IL nodes are read through il.ins.pas's views by offset (kind 109
  a variable, 110 a Fortran symbol, 116 a constant, 117 a label, 118 a
  typedef, 105..108 the routines and blocks, 111 a section, 122..136,
  173, 174, 177, 196, 197, 210, 234 the types), with three local views
  for what they do not give: a byte as a boolean, an identifier's +12
  (the string tables' marks and its name's offset), a block's level
  (+294) and tags (+388).  The records written to the object file
  (the .blocks records) are declared here; the .symbols records are
  us/us/sys/ins/dst.ins.pas's (pds.pas builds them).

  Not known from the original:
  - every name but the routines'; the record and field names; the
    locals' names and order;
  - the loc_build headings' parameter names (a C library).
}
module debug_sym_dmp;

%include 'lang/lang/source/globals.ins.pas';
%include '/sys/ins/base.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'lang/lang/source/unix_objmod.ins.pas';
%include '/sys/ins/name.ins.pas';
%include '/sys/ins/ios.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';
%include 'us/us/ins/isp.ins.pas';
%include 'us/us/sys/ins/isp.ins.pas';
%include 'us/us/sys/ins/dst.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'us1/us1/lib/dblib/loc/src/loc_build.ins.pas';
%include 'us/us/ins/uid_list.ins.pas';
%include '/sys/ins/type_uids.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/common/source/spos.pvt.pas';
%include 'lang/lang/source/gen_debug.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/common/source/pds.ins.pas';

type
  { A string table (12 bytes): the bytes its names take (each with a
    null), the names (pushed at the head), the mark (0 or 1) a name
    entered carries in its +12 (add_string enters a name once), and
    whether the record written is a local one (kind 28; else 27). }
  dsd_$str_entry_p_t = ^dsd_$str_entry_t;
  dsd_$str_entry_t = record             { 8 bytes from PAS_$NEW }
    node: il_$node_ptr_t;               { +0: the identifier }
    next: dsd_$str_entry_p_t;           { +4 }
  end;

  dsd_$string_table_t = record
    size: integer32;                    { +0 }
    list: dsd_$str_entry_p_t;           { +4 }
    mark: integer;                      { +8 }
    is_local: boolean;                  { +10 }
  end;

  { An identifier's +12 (idntk clears it): the string tables it is
    entered in, and its name's offset in the object file (a signed 30
    bits, as the references to it are). }
  dsd_$idnt_ref_p_t = ^dsd_$idnt_ref_t;
  dsd_$idnt_ref_t = packed record
    pad: array [0..11] of char;
    entered: set of 0..1;               { +12 bits 7..6 }
    offset: -16#20000000..16#1FFFFFFF;  { +12 bits 29..0 }
  end;

  { A loc fixup (16 bytes from the fixup heap): an object whose
    location is made once the code is placed (add_loc_info), the block
    it belongs to and its PDS_ record. }
  dsd_$fixup_p_t = ^dsd_$fixup_t;
  dsd_$fixup_t = record
    obj: il_$node_ptr_t;                { +0 }
    blk: il_$node_ptr_t;                { +4 }
    rec: univ_ptr;                      { +8 }
    next: dsd_$fixup_p_t;               { +12 }
  end;

  { A block of the relocated objects' list (136 bytes from PAS_$NEW). }
  dsd_$relocs_p_t = ^dsd_$relocs_t;
  dsd_$relocs_t = record
    next: dsd_$relocs_p_t;              { +0 }
    count: integer32;                   { +4 }
    e: array [1..32] of il_$node_ptr_t; { +8 }
  end;

  { An element of the block tree (12 bytes from the block structure
    heap); the block's +260 points back to it. }
  dsd_$elt_p_t = ^dsd_$elt_t;
  dsd_$elt_t = record
    child: dsd_$elt_p_t;                { +0: the first nested block }
    next: dsd_$elt_p_t;                 { +4: the next sibling }
    block: il_$node_ptr_t;              { +8 }
  end;

  dsd_$pair_t = record
    typ: il_$node_ptr_t;                { the parameter's type node }
    v: il_$node_ptr_t;                  { its variable }
  end;

  dsd_$nodes_p_t = ^array [1..16383] of il_$node_ptr_t;

  { The bytes of a node as booleans (`tst.b; bmi', `st'). }
  dsd_$bools_p_t = ^array [0..399] of boolean;

  { A block's nesting level (the signed byte at +294) and its tags (the
    structures and enumerations declared in it, +388). }
  dsd_$block_p_t = ^dsd_$block_t;
  dsd_$block_t = packed record
    pad: packed array [0..293] of char;
    level: -128..127;                   { +294 }
  end;

  dsd_$tags_p_t = ^dsd_$tags_t;
  dsd_$tags_t = record
    pad: array [0..387] of char;
    tags: il_$node_ptr_t;               { +388 }
  end;

  { A variable's register and its ranges (a variable's +68 list): the
    register by itself (+4 nil) or a variable, the offset, the register
    type and number with an indirection count, and the pc ranges (or,
    when the target is not 1..3, the statement ranges: a position in
    the low 24 bits). }
  dsd_$range_t = packed record
    case integer of
      1: (lo: integer32;
          hi: integer32);
      2: (lo_byte: 0..255;
          lo_pos: 0..16#FFFFFF;
          hi_byte: 0..255;
          hi_pos: 0..16#FFFFFF);
  end;

  dsd_$reg_p_t = ^dsd_$reg_t;
  dsd_$reg_t = record
    next: dsd_$reg_p_t;                 { +0 }
    v: il_$node_ptr_t;                  { +4 }
    offset: integer32;                  { +8 }
    reg_type: char;                     { +12 }
    reg_ind: char;                      { +13: register << 2, the
                                          indirections }
    unused_14: integer32;               { +14 }
    count: integer;                     { +18 }
    ranges: array [1..1000] of dsd_$range_t;   { +20 }
  end;

  { type_exp's result (lang/c_compiler/source/c_objtype.ins.pas's
    type_exp_t, which this unit does not open). }
  dsd_$type_exp_t = record
    base: il_$node_ptr_t;               { +0 }
    node: il_$node_ptr_t;               { +4 }
    low: integer32;                     { +8 }
    high: integer32;                    { +12 }
    size: integer32;                    { +16 }
    bytes: integer32;                   { +20 }
    flags: integer32;                   { +24 }
    unused_28: integer32;               { +28 }
  end;

  { The .blocks records (written in place through obj_alloc's
    addresses). }
  dsd_$header_p_t = ^dsd_$header_t;
  dsd_$header_t = packed record         { 26 bytes }
    kind: 0..255;                       { +0: 1 }
    flags: set of 0..7;                 { +1 }
    b2: 0..255;                         { +2: 1 }
    b3: 0..255;                         { +3: 4 under -CD, else 3 }
    w4: integer;                        { +4: 1 for targets 1..3 }
    w6: integer;                        { +6: 3 }
    nblocks: integer;                   { +8 }
    blocks: integer32;                  { +10: the first block }
    sections: integer32;                { +14: the section table }
    files: integer32;                   { +18: the local file table }
    size: integer32;                    { +22: the section's size }
  end;

  dsd_$code_range_t = packed record     { 16 bytes }
    length: integer32;                  { +0 }
    sect: integer;                      { +4 }
    start: integer32;                   { +6 }
    one: integer;                       { +10 }
    exc: integer32;                     { +12: the exception table }
  end;

  dsd_$blk_rec_p_t = ^dsd_$blk_rec_t;
  dsd_$blk_rec_t = packed record        { 24 + 16 per range }
    kind: 0..255;                       { +0: 4 }
    flags: set of 0..7;                 { +1 }
    block_kind: 0..255;                 { +2 }
    b3: 0..255;                         { +3 }
    sibling: integer32;                 { +4: the previous sibling }
    child: integer32;                   { +8: the first nested block }
    name: integer32;                    { +12 }
    scope_kind: integer;                { +16: 3, or 0 }
    scope_offset: integer32;            { +18 }
    nranges: integer;                   { +22 }
    ranges: array [1..1000] of dsd_$code_range_t;   { +24 }
  end;

  { The block's auxiliary records: the source lines (kind 51) and the
    ranges' exception tables (kind 54). }
  dsd_$aux_lines_p_t = ^dsd_$aux_lines_t;
  dsd_$aux_lines_t = packed record      { 10 bytes }
    kind: 0..255;
    flags: set of 0..7;
    first: integer32;                   { +2: dst_$src_loc_t }
    last: integer32;                    { +6 }
  end;

  dsd_$aux_exc_entry_t = packed record
    present: integer;
    offset: integer32;
  end;

  dsd_$aux_exc_p_t = ^dsd_$aux_exc_t;
  dsd_$aux_exc_t = packed record        { 4 + 6 per range }
    kind: 0..255;
    flags: set of 0..7;
    b2: 0..255;
    count: 0..255;
    e: array [1..1000] of dsd_$aux_exc_entry_t;   { +4 }
  end;

  { A routine's code range (its +152 list). }
  dsd_$code_rng_p_t = ^dsd_$code_rng_t;
  dsd_$code_rng_t = record
    next: dsd_$code_rng_p_t;            { +0 }
    start: integer32;                   { +4 }
    finish: integer32;                  { +8 }
    unused_12: integer32;               { +12 }
    exc: integer32;                     { +16: in the exception table }
    entry: integer32;                   { +20: its exception entry, or
                                          negative }
  end;

  { The local file table (kind 3: dst_$local_file_table), its names as
    references. }
  dsd_$lft_p_t = ^dsd_$lft_t;
  dsd_$lft_t = packed record
    kind: 0..255;
    flags: set of 0..7;
    count: integer;                     { +2 }
    e: array [1..2047] of packed record { +4 }
      id: integer32;                    { the dtm }
      name: integer32;
    end;
  end;

  { The section table (kind 2) and the unit table (kind 53). }
  dsd_$table_p_t = ^dsd_$table_t;
  dsd_$table_t = packed record
    kind: 0..255;
    flags: set of 0..7;
    count: integer;                     { +2 }
    e: array [1..16000] of integer32;   { +4 }
  end;

  { get_src_loc's result. }
  dsd_$src_loc_t = record
    case integer of
      1: (loc: dst_$src_loc_t);
      2: (l: integer32);
  end;

  dsd_$rel_t = record
    case integer of
      1: (rel: dst_$rel_t);
      2: (l: integer32);
  end;

define
  debug_sym_dmp_1090;                   { +4240 }

var
  block_heap: mrh_$heap_t;              { +0 }
  npairs: integer;                      { +24 }
  pairs: array [1..512] of dsd_$pair_t; { +26 }
  fixup_heap: mrh_$heap_t;              { +4128 }
  locs_heap: mrh_$heap_t;               { +4152 }
  strings_27: dsd_$string_table_t;      { +4176 }
  strings_28: dsd_$string_table_t;      { +4192 }
  fixups: dsd_$fixup_p_t := nil;        { +4204 }
  sym_sections: il_$node_ptr_t := nil;  { +4208 }
  obj_offset: integer32;                { +4212 }
  cur_proc: il_$node_ptr_t;             { +4216 }
  reloc_cur: dsd_$relocs_p_t;           { +4220 }
  reloc_head: dsd_$relocs_p_t;          { +4224 }
  loc_pool: univ_ptr;                   { +4228 }
  indirect_cell: integer32 := 0;        { +4232 }
  nrelocs: integer;                     { +4236 }
  fold_case: boolean;                   { +4238 }
  unused_4242: boolean := false;        { +4242 }
  fortran_var: il_$node_ptr_t := nil;   { +4244 }
  fortran_label: il_$node_ptr_t := nil; { +4248 }

{ The unit's global routines no other unit calls (they load A5;
  debug_sym_dmp.ins.pas lists them). }
function obj_alloc(
    in out pos: integer32;
    size: integer32): integer32; options(val_param); forward;
function get_record_rep(
    var t: il_$node_ptr_t): univ_ptr; forward;
function get_enum_rep(
    var t: il_$node_ptr_t): univ_ptr; forward;

{ Internal routines called before their bodies. }
function get_type_rep(
    t: il_$node_ptr_t): univ_ptr; options(val_param); internal; forward;
procedure force_add_string(
    var tbl: dsd_$string_table_t;
    id: il_$node_ptr_t); options(val_param); internal; forward;

{ sz_fsym - a Fortran symbol's size: a stub.

  0x0A8350, 0x20 bytes: BUG_CHECK, then 0 in D0 (the parameter is not
  read). }

function sz_fsym;
begin
  bug_check('\\DEBUG_SYM_DMP_\SZ_FSYM --- This stub should never be called.%$');
  sz_fsym := 0;
end;

{ allocfunc - LOC_BUILD_'s allocator: size bytes from the locs heap.

  0x0A83B0, 0x4A bytes: MRH_$ALLOC(+4152, the size as a word); nil
  reported; the address returned in D0 (taken from A0, through the
  result slot: docs/rev889-patterns.md 33).  Passed to loc_build__init
  (debug_sym_dmp_$init). }

function allocfunc(
    size: integer32): univ_ptr; options(val_param);
var
  p: univ_ptr;
begin
  p := mrh_$alloc(locs_heap, size);
  if p = nil then
    bug_check('\\DEBUG_SYM_DMP_\ALLOCFUNC -- No free space.%$');
  allocfunc := p;
end;

{ dumpfunc - LOC_BUILD_'s writer: len bytes from data to the object
  file at offset.

  0x0A8428, 0x52 bytes: PUTOBJ(offset, len), LIB_$DATA_MOVE from the
  data's address (its slot's address passed), FREEOBJ; len returned in
  D0.  The first parameter is not read.  Passed to loc_build__init and
  as pds_$dump_symbols_section's dump_loc_func_p. }

function dumpfunc(
    pool: univ_ptr;
    offset: integer32;
    data: univ_ptr;
    len: integer32): integer32; options(val_param);
var
  dst: univ_ptr;
begin
  dst := putobj(offset, len);
  lib_$data_move(data, dst, len);
  freeobj(dst);
  dumpfunc := len;
end;

{ obj_alloc - size bytes of the object file at pos (moved past them,
  to an even offset); their address returned (pds_$dump_symbols_
  section's allocator, and this unit's).

  0x0A847A, 0x46 bytes: PUTOBJ(pos, size); `add.l D2,(A2)'; `btst #0,
  (3,A2)', `addq.l #1'; A0 moved to D0. }

function obj_alloc;
var
  p: univ_ptr;
begin
  p := putobj(pos, size);
  pos := pos + size;
  if odd(pos) then
    pos := pos + 1;
  obj_alloc := integer32(p);
end;

{ add_symbols_section - a .symbols section made (PDS_$CREATE_SYMBOLS_
  SECTIONS's create_section: the parameter is not read): a section
  node (kind 111, 56 bytes from gspace) named '.some_symbol_section'
  (add_name_to_symbols_section names it), pushed on the list +4208.

  0x0A84C0, 0x7E bytes: +12..+20 cleared, the byte +24, +26..+53
  cleared, +54 set; the node returned in D0 through the result slot. }

function add_symbols_section(
    is_include: boolean): integer32; options(val_param);
var
  s: il_$node_ptr_t;
begin
  s := gspace(56);
  s^.kind := 111;
  s^.xp[1] := idntk(76, '.some_symbol_section', 20);
  s^.xp[2] := sym_sections;
  s^.xl[3] := 0;
  s^.xl[4] := 0;
  s^.xl[5] := 0;
  dsd_$bools_p_t(s)^[24] := false;
  s^.xl2[6] := 0;
  s^.xl2[7] := 0;
  s^.xl2[8] := 0;
  s^.xl2[9] := 0;
  s^.xl2[10] := 0;
  s^.xl2[11] := 0;
  s^.xl2[12] := 0;
  dsd_$bools_p_t(s)^[54] := true;
  sym_sections := s;
  add_symbols_section := integer32(s);
end;

{ add_name_to_symbols_section - the section's name (PDS_$DUMP_SYMBOLS_
  SECTION's add_section_name).

  0x0A8554, 0x7C bytes: nil reported; a node not of kind 111 or not
  named '.some_symbol_section' (`cmpa.l (4,A2),A0' after IDNTK)
  reported; +4 := IDNTK(76, name, len). }

procedure add_name_to_symbols_section(
    section: integer32;
    in name: univ pds_$chars_t;
    len: integer); options(val_param);
var
  s: il_$node_ptr_t;
begin
  s := il_$node_ptr_t(section);
  if s = nil then
    bug_check('\\DEBUG_SYM_DMP_\ADD_NAME_TO_SECTION -- handle is NIL.%$');
  if (s^.kind <> 111) or
     (idntk(76, '.some_symbol_section', 20) <> s^.xp[1]) then
    bug_check('\\DEBUG_SYM_DMP_\ADD_NAME_TO_SECTION -- handle does not point to a section$debug section.%$');
  s^.xp[1] := idntk(76, name, len);
end;

{ varn_from_fortran_symbol - a variable node (kind 109, 88 bytes from
  gspace) standing for Fortran symbol sym of block blk (nil for nil):
  a new one when fresh, else the one kept at +4244 (made once).

  0x0A8664, 0x100 bytes: fresh a byte at (16,A6) (`bmi'); the second
  parameter (12) is not read.  +4 and +28 the symbol, +8 cleared, +20
  the symbol's block (+40, or its +148 for a kind 167); +72 from the
  symbol's +11 bits 7..4 (3 becomes 10, 5 with +44 bit 1 becomes 2);
  the rest copied from the symbol (+24, +46, +12, +16, +66, +50, +54,
  +58), +40 and +84 cleared.

  Not known from the original:
  - the second parameter's use. }

function varn_from_fortran_symbol;
var
  v: il_$node_ptr_t;
  b: il_$node_ptr_t;
  k: integer;
begin
  if sym = nil then begin
    varn_from_fortran_symbol := nil;
    return;
  end;
  if fortran_var = nil then begin
    fortran_var := gspace(88);
    fortran_var^.kind := 109;
  end;
  if fresh then begin
    v := gspace(88);
    v^.kind := 109;
  end
  else
    v := fortran_var;
  v^.xp[1] := sym;
  v^.xw[4] := 0;
  v^.xp[7] := sym;
  b := sym^.xp[10];
  if b <> nil then
    if b^.kind = 167 then
      b := b^.xp[37];
  v^.xp[5] := b;
  k := (ord(sym^.xc[11]) & 16#F0) div 16;
  if k = 3 then
    v^.xw[36] := 10
  else if (k = 5) and ((ord(sym^.xc[44]) & 2) <> 0) then
    v^.xw[36] := 2
  else
    v^.xw[36] := k;
  v^.xl[8] := sym^.xl[6];
  v^.xl[10] := 0;
  v^.xl[13] := sym^.xl2[11];
  v^.xl[14] := sym^.xl[3];
  v^.xw[37] := sym^.xw[8];
  v^.xw[38] := sym^.xw[33];
  v^.xl[16] := sym^.xl2[12];
  v^.xl[17] := sym^.xl2[13];
  v^.xl[20] := sym^.xl2[14];
  v^.xl[21] := 0;
  varn_from_fortran_symbol := v;
end;

{ label_from_fortran_symbol - the label node (kind 117, 40 bytes from
  gspace, made once at +4248) standing for Fortran symbol sym of block
  blk (nil for nil).

  0x0A8764, 0x90 bytes (no A5: internal; it reaches +4248 through its
  caller's A5).  +4 the symbol, +8 and +32 cleared, +20 the block, +28
  the symbol's +48; +37 bit 7 the symbol's +44 bit 1, bit 6 its bit 0
  (`sne', merged into the byte). }

function label_from_fortran_symbol(
    sym: il_$node_ptr_t;
    blk: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  l: il_$node_ptr_t;
begin
  if sym = nil then begin
    label_from_fortran_symbol := nil;
    return;
  end;
  if fortran_label = nil then begin
    fortran_label := gspace(40);
    fortran_label^.kind := 117;
  end;
  l := fortran_label;
  l^.xp[1] := sym;
  l^.xw[4] := 0;
  l^.xp[5] := blk;
  l^.xp[7] := sym^.xp[12];
  l^.xw[16] := 0;
  l^.xc[37] := chr((ord(l^.xc[37]) & 16#7F) ! ((ord(sym^.xc[44]) & 2) * 64));
  l^.xc[37] := chr((ord(l^.xc[37]) & 16#BF) ! ((ord(sym^.xc[44]) & 1) * 64));
  label_from_fortran_symbol := l;
end;

{ get_include_file_index - the file (its mark, 1 beyond 32767) and the
  line (at most 32767) of a source position.

  0x0A87F4, 0x70 bytes: SPOS_$DECODE_SOURCE_POSITION, SPOS_$MARK_SOURCE_
  FILE of the region; the mark and the line compared unsigned (`bls')
  with 32767. }

procedure get_include_file_index;
var
  region, line32, mark: integer32;
begin
  spos_$decode_source_position(position, region, line32);
  spos_$mark_source_file(region, mark);
  if mark > 32767 then
    file_index := 1
  else
    file_index := mark;
  if line32 > 32767 then
    line32 := 32767;
  line := line32;
end;

{ add_to_reloc_obj_list - obj's symbols relocation numbered (the count
  +4236 incremented: a section's word at +42 (kind 183) or +62 (182),
  a section node's +52 (111), a variable's +78 (109)) and obj appended
  to the list of 32-entry blocks (+4220 the current, +4224 the first).

  0x0A8864, 0xCA bytes (no A5: internal).  A new block (136 bytes from
  PAS_$NEW) when there is none or the current one is full, its next and
  count cleared. }

procedure add_to_reloc_obj_list(
    obj: il_$node_ptr_t); options(val_param); internal;
begin
  nrelocs := nrelocs + 1;
  case obj^.kind of
    183: obj^.xw[21] := nrelocs;
    182: obj^.xw[31] := nrelocs;
    111: obj^.xw[26] := nrelocs;
    109: obj^.xw[39] := nrelocs;
    otherwise
      bug_check('\\DEBUG_SYM_DMP_\ADD_TO_RELOC_OBJ_LIST -- Don''t know how to relocate this object.%$');
  end;
  if reloc_cur = nil then begin
    new(reloc_cur);
    reloc_head := reloc_cur;
    reloc_cur^.next := nil;
    reloc_cur^.count := 0;
  end
  else if reloc_cur^.count = 32 then begin
    new(reloc_cur^.next);
    reloc_cur := reloc_cur^.next;
    reloc_cur^.next := nil;
    reloc_cur^.count := 0;
  end;
  reloc_cur^.count := reloc_cur^.count + 1;
  reloc_cur^.e[reloc_cur^.count] := obj;
end;

{ prep_sections - the relocated objects' list started (the first three
  numbers are the .lines, .unwind and .symbols addresses'): the code
  sections of il_10c with code (+12), the data sections of il_110 with
  contents (+24 + +20 - +16 > 0), the commons of il_118 (+20, chained
  by +8).

  0x0A8984, 0x90 bytes (no A5: internal). }

procedure prep_sections; internal;
var
  s: il_$node_ptr_t;
begin
  reloc_head := nil;
  reloc_cur := nil;
  nrelocs := 3;
  s := il_10c;
  while s <> nil do begin
    if s^.xl[3] <> 0 then
      add_to_reloc_obj_list(s);
    s := s^.xp[1];
  end;
  s := il_110;
  while s <> nil do begin
    if s^.xl[6] + s^.xl[5] - s^.xl[4] > 0 then
      add_to_reloc_obj_list(s);
    s := s^.xp[1];
  end;
  s := il_118;
  while s <> nil do begin
    if s^.xl[5] <> 0 then
      add_to_reloc_obj_list(s);
    s := s^.xp[2];
  end;
end;

{ add_obj_to_loc_fixup_list - obj (of block blk, PDS_ record rec) to
  get its location in add_loc_info.

  0x0A8A14, 0x3C bytes (no A5: internal): MRH_$ALLOC_FIXED of +4128,
  pushed on +4204. }

procedure add_obj_to_loc_fixup_list(
    obj: il_$node_ptr_t;
    blk: il_$node_ptr_t;
    rec: univ_ptr); options(val_param); internal;
var
  f: dsd_$fixup_p_t;
begin
  f := mrh_$alloc_fixed(fixup_heap);
  f^.obj := obj;
  f^.blk := blk;
  f^.rec := rec;
  f^.next := fixups;
  fixups := f;
end;

{ reg_translate_at - the debugger's number of register reg of type
  reg_type (cc.a88k's register numbering: 0 the general registers as
  they are, 1 from 32, 2 the pairs from 96).

  0x0A8A50, 0x4A bytes (no A5: internal): the result in D0 (reg
  unless changed); reg zero-extended for the pairs (`andi.l #0xFFFF').
  An unknown type is reported. }

function reg_translate_at(
    reg: pinteger;
    reg_type: integer): integer; options(val_param); internal;
var
  r: integer;
begin
  r := reg;
  case reg_type of
    0: ;
    1: r := reg + 32;
    2: r := (reg + 1) div 2 + 96;
    otherwise
      bug_check('\\DEBUG_SYM_DMP_\REG_TRANSLATE_AT -- Uknown reg_type.%$');
  end;
  reg_translate_at := r;
end;

{ reg_translate_68k - the debugger's number of 68K register reg: the
  data and address registers (0..15) as they are; the floating point
  registers (16..23) from 33 with -CPU FPA1 (cpu element 8, +0x284 bit
  2).

  0x0A8AD4, 0x38 bytes (no A5: internal; no frame, the parameter at
  (4,SP), docs/rev889-patterns.md 16): unsigned compares of the
  ranges 0..7 and 8..15 (taken no further) before 16..23.

  Not known from the original:
  - the form of the tests of 0..7 and 8..15 (empty `then' parts or a
    `case' are refused, the reference allows no ranges in labels). }

function reg_translate_68k(
    reg: pinteger): pinteger; options(val_param); internal;
var
  r: pinteger;
begin
  r := reg;
  if (reg >= 16) and (reg <= 23) then
    if 8 in cargs_$options.cpu then
      r := 33 + reg - 16;
  reg_translate_68k := r;
end;

{ get_memory_loc - the location of variable v (kind 109) of block blk
  by its allocation class (+72); failed when it has none.

  0x0A8B0C, 0x44E bytes (no A5: internal).  Under flags_286 element 7
  (+0x287 bit 2) a static variable (class 3) is relocated (its number
  +78; failed without +32 bit 16).  Otherwise a jump table on the
  class 1..11: 1 and 7 the variable's section (+20 +192 +42) and
  offset, 8 and 4 the same with the name entered in the string table
  +4192 (4: the offset alone); 10 a common's (+80 +52); 2 and 5 the
  frame (register 14, 15 for a kind 121 type without +378 bit 4; the
  target's 1..3 the block's register +372) with an indirection through
  the offset or +4232; 6 relative to the block's frame (+72 +56, or
  +20's +80 - +176); 3 the address constant (CHECK_FOR_ADDR_CON, failed
  without one); 9 kind 4; 11 a register (+42 bit 10: +56's high word
  and +58) or kind 5.  The variable's attributes (+64's) get 2 (static)
  and 4 (allocated) where noted.  Every location ends in one
  loc_build__relative_loc (12, 16 or 20 bytes of arguments) or
  loc_build__register_loc.  The result (-36) is not set when failed.

  Not known from the original:
  - the classes' names; why class 3 under element 7 is relocated. }

function get_memory_loc(
    v: il_$node_ptr_t;
    blk: il_$node_ptr_t;
    var failed: boolean): univ_ptr; options(val_param); internal;
var
  flag: boolean;
  reg: integer;
  zero: integer32;
  con: il_$node_ptr_t;
  s: il_$node_ptr_t;
  loc: univ_ptr;
begin
  if (7 in cargs_$options.flags_286) and (v^.xw[36] = 3) then begin
    if (v^.xl[8] & 16#10000) = 0 then begin
      failed := true;
      return;
    end;
    failed := false;
    force_add_string(strings_28, v^.xp[1]);
    pds_$add_var_attr(v^.xp[16], 2);
    pds_$add_var_attr(v^.xp[16], 4);
    add_to_reloc_obj_list(v);
    loc := loc_build__relative_loc(1, v^.xw[39], 0, nil);
  end
  else begin
    failed := false;
    case v^.xw[36] of
      1: begin
        pds_$add_var_attr(v^.xp[16], 4);
        loc := loc_build__relative_loc(1, v^.xp[5]^.xp[48]^.xw[21],
                                       v^.xl[14], nil);
      end;
      2: begin
        flag := false;
        if (target_properties.p_10 >= 1) and
           (target_properties.p_10 <= 3) then begin
          reg := reg_translate_at(blk^.xw[186], 0);
          if ((ord(blk^.xc[378]) & 4) <> 0) and
             ((v^.xl[8] & 16#4000000) = 0) and
             ((v^.xl[8] & 16#400) <> 0) then
            flag := true;
        end
        else if ((ord(blk^.xc[378]) & 16) = 0) and
                (v^.xp[7]^.kind = 121) then
          reg := 15
        else
          reg := 14;
        if (v^.xp[7]^.kind = 121) and (v^.xp[7]^.xp[4]^.kind = 206) then
          loc := loc_build__relative_loc(2, reg, v^.xl[14],
                                         addr(indirect_cell), nil)
        else if flag then
          loc := loc_build__relative_loc(2, reg, 0, addr(v^.xl[14]), nil)
        else
          loc := loc_build__relative_loc(2, reg, v^.xl[14], nil);
      end;
      3: begin
        zero := 0;
        pds_$add_var_attr(v^.xp[16], 4);
        con := check_for_addr_con(8, v, zero, blk^.xp[48]);
        if con = nil then begin
          failed := true;
          return;
        end;
        if (v^.xl[14] <> 0) and ((v^.xl[8] & 16#10000) = 0) then
          bug_check('\\DEBUG_SYM_DMP_\GET_MEMORY_LOC -- Compiler failure, bad address constant.%$');
        loc := loc_build__relative_loc(1, blk^.xp[48]^.xw[21], con^.xl[4],
                                       addr(indirect_cell), nil);
      end;
      4: begin
        force_add_string(strings_28, v^.xp[1]);
        pds_$add_var_attr(v^.xp[16], 2);
        pds_$add_var_attr(v^.xp[16], 4);
        loc := loc_build__relative_loc(1, v^.xp[5]^.xp[48]^.xw[21],
                                       v^.xl[14], nil);
      end;
      5: begin
        flag := false;
        if (target_properties.p_10 >= 1) and
           (target_properties.p_10 <= 3) then begin
          reg := reg_translate_at(blk^.xw[186], 0);
          if ((ord(blk^.xc[378]) & 4) <> 0) and
             ((v^.xl[8] & 16#4000000) = 0) then
            flag := true;
        end
        else if (ord(blk^.xc[378]) & 16) = 0 then
          reg := 15
        else
          reg := 14;
        if flag then
          loc := loc_build__relative_loc(2, reg, 0, addr(v^.xl[14]),
                                         addr(indirect_cell), nil)
        else
          loc := loc_build__relative_loc(2, reg, v^.xl[14],
                                         addr(indirect_cell), nil);
      end;
      6: begin
        if (target_properties.p_10 >= 1) and
           (target_properties.p_10 <= 3) then begin
          reg := reg_translate_at(blk^.xw[186], 0);
          if blk^.xp[18] = nil then
            loc := loc_build__relative_loc(2, reg,
                                           v^.xl[14] - v^.xp[5]^.xl[28], nil)
          else
            loc := loc_build__relative_loc(2, reg, blk^.xp[18]^.xl[14],
                                           addr(v^.xl[14]), nil);
        end
        else begin
          reg := 14;
          s := v^.xp[5];
          loc := loc_build__relative_loc(2, reg,
                                         s^.xl[20] - s^.xl[44] + v^.xl[14],
                                         nil);
        end;
      end;
      7: begin
        pds_$add_var_attr(v^.xp[16], 4);
        s := v^.xp[5]^.xp[48];
        loc := loc_build__relative_loc(1, s^.xw[21], s^.xl[5] + v^.xl[14],
                                       nil);
      end;
      8: begin
        force_add_string(strings_28, v^.xp[1]);
        pds_$add_var_attr(v^.xp[16], 4);
        pds_$add_var_attr(v^.xp[16], 2);
        s := v^.xp[5]^.xp[48];
        loc := loc_build__relative_loc(1, s^.xw[21], s^.xl[5] + v^.xl[14],
                                       nil);
      end;
      9: loc := loc_build__relative_loc(4, 0, v^.xl[14], nil);
      10: begin
        force_add_string(strings_28, v^.xp[1]);
        pds_$add_var_attr(v^.xp[16], 2);
        pds_$add_var_attr(v^.xp[16], 4);
        loc := loc_build__relative_loc(1, v^.xp[20]^.xw[26], v^.xl[14],
                                       nil);
      end;
      11: begin
        if (v^.xw[21] & 16#400) <> 0 then begin
          reg := reg_translate_at(rshft(v^.xl[14] & 16#7FFF0000, 16),
                                  v^.xw[29]);
          loc := loc_build__register_loc(reg);
        end
        else begin
          pds_$add_var_attr(v^.xp[16], 4);
          loc := loc_build__relative_loc(5, 0, v^.xl[14], nil);
        end;
      end;
      otherwise
        bug_check('\\DEBUG_SYM_DMP_\GET_MEMORY_LOC -- Unknown vat.%$');
    end;
  end;
  get_memory_loc := loc;
end;

{ get_var_location_rep - the location record (PDS_$MAKE_LOC) of
  variable v of block blk: a list of its registers and ranges (+68)
  with its memory location as the default; nil for a variable of class
  0 or without either.

  0x0A8FD8, 0x306 bytes (no A5: internal).  Each register record: a
  variable (a Fortran symbol replaced by a fresh variable node) at its
  memory location, else the register (reg_translate_at of +13's bits
  7..2 and +12 for targets 1..3, else reg_translate_68k) with 0..3
  indirections (a jump table on +13's bits 1..0: the register, the
  offset from it, through the offset, through the offset and +4232);
  then its ranges: pc ranges for targets 1..3, else statement ranges
  (each end's position decoded by get_include_file_index, with its top
  byte).  The memory location (unless +32 bit 26) is the default; a
  failed one gives nil.  A negative offset from loc_build__close_list
  is reported.  The target_properties address is loaded into D7 at
  entry and not used (`move.l #0x2CE528,D7').

  Not known from the original:
  - what the records' +14 and +16 hold. }

function get_var_location_rep(
    v: il_$node_ptr_t;
    blk: il_$node_ptr_t): univ_ptr; options(val_param); internal;
var
  r: dsd_$reg_p_t;
  list: univ_ptr;
  loc: univ_ptr;
  have_list: boolean;
  failed: boolean;
  reg, reg_68k: integer;
  i: integer32;
  file1, line1, file2, line2: integer;
  n: integer32;
begin
  if v^.xw[36] = 0 then begin
    get_var_location_rep := nil;
    return;
  end;
  r := dsd_$reg_p_t(v^.xp[17]);
  if r <> nil then begin
    list := loc_build__open_list(loc_pool, blk^.xl[39],
                                 not ((target_properties.p_10 >= 1) and
                                      (target_properties.p_10 <= 3)));
    repeat
      if r^.v <> nil then begin
        if r^.v^.kind = 110 then
          r^.v := varn_from_fortran_symbol(r^.v, blk, true);
        loc := get_memory_loc(r^.v, blk, failed);
      end
      else begin
        if (target_properties.p_10 >= 1) and
           (target_properties.p_10 <= 3) then
          reg := reg_translate_at((ord(r^.reg_ind) & 252) div 4,
                                  ord(r^.reg_type))
        else begin
          reg_68k := (ord(r^.reg_ind) & 252) div 4;
          reg := reg_translate_68k(reg_68k);
        end;
        case ord(r^.reg_ind) & 3 of
          0: loc := loc_build__register_loc(reg);
          1: loc := loc_build__relative_loc(2, reg, r^.offset, nil);
          2: loc := loc_build__relative_loc(2, reg, 0, addr(r^.offset), nil);
          3: loc := loc_build__relative_loc(2, reg, 0, addr(r^.offset),
                                            addr(indirect_cell), nil);
          otherwise
            bug_check('\\DEBUG_SYM_DMP_\GET_VAR_LOCATION_REP -- Bad indirection count.%$');
        end;
      end;
      if (target_properties.p_10 >= 1) and
         (target_properties.p_10 <= 3) then begin
        for i := 1 to r^.count do
          loc_build__pc_range(list, loc, r^.ranges[i].lo, r^.ranges[i].hi);
      end
      else
        for i := 1 to r^.count do begin
          get_include_file_index(r^.ranges[i].lo_pos, file1, line1);
          get_include_file_index(r^.ranges[i].hi_pos, file2, line2);
          loc_build__stmt_range(list, loc, line1, file1,
                                r^.ranges[i].lo_byte, line2, file2,
                                r^.ranges[i].hi_byte);
        end;
      r := r^.next;
    until r = nil;
    have_list := true;
  end
  else
    have_list := false;
  if (v^.xl[8] & 16#4000000) = 0 then begin
    loc := get_memory_loc(v, blk, failed);
    if failed then begin
      get_var_location_rep := nil;
      return;
    end;
    if not have_list then
      list := loc_build__open_list(loc_pool, 0, false);
    loc_build__default(list, loc);
    have_list := true;
  end;
  if have_list then begin
    n := loc_build__close_list(list);
    if n < 0 then
      bug_check('\\DEBUG_SYM_DMP_\GET_VAR_LOCATION_REP -- Negative offset to loc string indicates an error.%$');
    get_var_location_rep := pds_$make_loc(loc_pool, n);
  end
  else
    get_var_location_rep := nil;
end;

{ get_sect_rel_location_rep - the location record of offset in section
  sect.

  0x0A937C, 0x7A bytes (no A5: internal): a list with the section
  relative location as its default. }

function get_sect_rel_location_rep(
    sect: integer;
    offset: integer32): univ_ptr; options(val_param); internal;
var
  list, loc: univ_ptr;
  n: integer32;
begin
  list := loc_build__open_list(loc_pool, 0, false);
  loc := loc_build__relative_loc(1, sect, offset, nil);
  loc_build__default(list, loc);
  n := loc_build__close_list(list);
  if n < 0 then
    bug_check('\\DEBUG_SYM_DMP_\GET_SECT_REL_LOCATION_REP -- Negative offset to loc string indicates an error.%$');
  get_sect_rel_location_rep := pds_$make_loc(loc_pool, n);
end;

{ debug_sym_dmp_$add_loc_info - the locations of the objects on the loc
  fixup list, once the code is placed.

  0x0A9458, 0x266 bytes: a jump table on the object's kind 105..117: a
  label (117) its section relative location (the block's +188 +62,
  the label's +28 +56); a variable (109) get_var_location_rep; a
  routine (105, 107, 108) its entry (the code section's +62 and +156
  without an entry control block (HAS_ECB), without +108 or at a level
  above 0 (+294, signed), else the data section's +42 and +108).  For a
  routine on a target other than 1..3: an auxiliary register value of
  8 (+374 bits 19 and 12 both set) or 13 for its data section's start
  when the section has contents (not under flags_286 element 7 with
  both bits), and one of 9 (register 14) when +240 and +378 bit 6.
  Other kinds are reported.

  Not known from the original:
  - the meaning of the register values 8, 9 and 13. }

procedure debug_sym_dmp_$add_loc_info;
var
  f: dsd_$fixup_p_t;
  r, s: il_$node_ptr_t;
  loc, aux, list: univ_ptr;
  regval: integer;
  n: integer32;
begin
  f := fixups;
  while f <> nil do begin
    case f^.obj^.kind of
      117: begin
        loc := get_sect_rel_location_rep(f^.blk^.xp[47]^.xw[31],
                                         f^.obj^.xp[7]^.xl[14]);
        pds_$add_label_loc(f^.rec, loc);
      end;
      109: begin
        loc := get_var_location_rep(f^.obj, f^.blk);
        pds_$add_var_loc(f^.rec, loc);
      end;
      105, 107, 108: begin
        r := f^.blk;
        if not has_ecb(f^.blk) or (r^.xl[27] = 0) or
           (dsd_$block_p_t(r)^.level > 0) then
          loc := get_sect_rel_location_rep(r^.xp[47]^.xw[31], r^.xl[39])
        else
          loc := get_sect_rel_location_rep(r^.xp[48]^.xw[21], r^.xl[27]);
        pds_$add_entry_point_loc(f^.rec, loc);
        if not ((target_properties.p_10 >= 1) and
                (target_properties.p_10 <= 3)) then begin
          r := f^.blk;
          if not (7 in cargs_$options.flags_286) or
             ((r^.xl2[93] & 16#81000) <> 16#81000) then begin
            s := r^.xp[48];
            if s^.xl[6] + s^.xl[5] - s^.xl[4] > 0 then begin
              if (r^.xl2[93] & 16#81000) = 16#81000 then
                regval := 8
              else
                regval := 13;
              loc := get_sect_rel_location_rep(s^.xw[21], 0);
              aux := pds_$make_aux_reg_val_rec(regval, loc);
              pds_$add_aux_rec(f^.rec, aux);
            end;
          end;
          r := f^.blk;
          if (r^.xl[60] <> 0) and ((ord(r^.xc[378]) & 16#40) <> 0) then begin
            regval := 9;
            list := loc_build__open_list(loc_pool, 0, false);
            loc := loc_build__register_loc(14);
            loc_build__default(list, loc);
            n := loc_build__close_list(list);
            loc := pds_$make_loc(loc_pool, n);
            aux := pds_$make_aux_reg_val_rec(regval, loc);
            pds_$add_aux_rec(f^.rec, aux);
          end;
        end;
      end;
      otherwise
        bug_check('DEBUG_SYM_DMP_$ADD_LOC_INFO --- Uknown object on loc fixup list.%$');
    end;
    f := f^.next;
  end;
end;

{ may_need_common_aux - the auxiliary size and alignment records of rec
  (a field's, when field_num is not 0) when typ's flags ask for them
  (bit 11 the size, in bytes from bits rounded up; bit 12 the
  alignment).

  0x0A9700, 0x1B4 bytes (no A5: internal).  The flags, the type, the
  size and the alignment by typ's kind (109 variables, 118 typedefs,
  121, 108 routines, 174, 119/120 fields (field_num must not be 0),
  133 files); a typedef's own flags (+40) are taken out of a typedef
  type's.  An unexpected kind is reported and its type is not set. }

procedure may_need_common_aux(
    rec_p: univ_ptr;
    typ_p: il_$node_ptr_t;
    field_num: integer); options(val_param); internal;
var
  flags: integer32;
  t: il_$node_ptr_t;
  size: integer32;
  align: integer;
  aux: univ_ptr;
begin
  if rec_p = nil then
    bug_check('\\DEBUG_SYM_DMP_\MAY_NEED_COMMON_AUX -- rec_p is NIL.%$');
  if typ_p = nil then
    bug_check('\\DEBUG_SYM_DMP_\MAY_NEED_COMMON_AUX -- typ_p is NIL.%$');
  case typ_p^.kind of
    109: begin
      flags := typ_p^.xl[10];
      t := typ_p^.xp[7];
      size := typ_p^.xl[9];
      align := typ_p^.xw[22];
    end;
    118: begin
      flags := typ_p^.xl[10];
      t := typ_p^.xp[7];
      size := typ_p^.xl[11];
      align := typ_p^.xw[25];
    end;
    121: begin
      flags := typ_p^.xl[6];
      t := typ_p^.xp[4];
      size := typ_p^.xl[7];
      align := typ_p^.xw[17];
    end;
    108: begin
      flags := typ_p^.xl[78];
      t := typ_p^.xp[7];
      size := typ_p^.xl[79];
      align := typ_p^.xw[161];
    end;
    174: begin
      flags := typ_p^.xl[3];
      t := typ_p^.xp[7];
      size := typ_p^.xl[4];
      align := typ_p^.xw[11];
    end;
    120, 119: begin
      if field_num = 0 then
        bug_check('\\DEBUG_SYM_DMP_\MAY_NEED_COMMON_AUX -- field_num may not be zero for fields.%$');
      flags := typ_p^.xl[7];
      t := typ_p^.xp[4];
      size := typ_p^.xl[6];
      align := typ_p^.xw[16];
    end;
    133: begin
      flags := typ_p^.xl[4];
      t := typ_p^.xp[1];
      size := typ_p^.xl[3];
      align := typ_p^.xw[10];
    end;
    otherwise
      bug_check('\\DEBUG_SYM_DMP_\MAY_NEED_COMMON_AUX -- Unexpected object kind.%$');
  end;
  if t^.kind = 118 then
    flags := flags & ~t^.xl[10];
  if (flags & 16#800) <> 0 then begin
    if field_num = 0 then
      aux := pds_$make_aux_size_rec((size + 7) div 8)
    else
      aux := pds_$make_aux_field_size_rec(field_num, (size + 7) div 8);
    pds_$add_aux_rec(rec_p, aux);
  end;
  if (flags & 16#1000) <> 0 then begin
    if field_num = 0 then
      aux := pds_$make_aux_align_rec(align)
    else
      aux := pds_$make_aux_field_align_rec(field_num, align);
    pds_$add_aux_rec(rec_p, aux);
  end;
end;

{ is_simple_type - whether type t has a standard type code (get_type_
  rep's codes without a record): the integral, floating and character
  kinds, 135, 136, 210, 234, the subranges -32767..32767 and -128..127
  of an integral type, a pointer to kind 210.

  0x0A99B6, 0x9A bytes (no A5: internal): the set test of 0..239 with
  no range check (docs/rev889-patterns.md 41; the set after the
  routine). }

function is_simple_type(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if t^.kind in [122..126, 135, 136, 210, 234] then
    is_simple_type := true
  else if (t^.kind = 128) and (t^.xp[1]^.kind = 122) and
          (((t^.xp[2]^.xl[2] = -32767) and (t^.xp[3]^.xl[2] = 32767)) or
           ((t^.xp[2]^.xl[2] = -128) and (t^.xp[3]^.xl[2] = 127))) then
    is_simple_type := true
  else if (t^.kind = 130) and (t^.xp[1]^.kind = 210) then
    is_simple_type := true
  else
    is_simple_type := false;
end;

{ get_name_rep - the PDS_ name of an identifier (76), a string (92) or
  a Fortran symbol (110: the name at +72, its length +70), less a final
  null.

  0x0A9A6E, 0x8A bytes (no A5: internal; the message names it
  GET_STRING_REP).  Another kind is reported (the result is not set). }

function get_name_rep(
    sp: il_$node_ptr_t): univ_ptr; options(val_param); internal;
var
  len: integer;
begin
  if sp^.kind = 76 then begin
    len := sp^.idnt_len;
    if sp^.idnt_name[len] = chr(0) then
      len := len - 1;
    get_name_rep := pds_$make_name(sp^.idnt_name, len);
  end
  else if sp^.kind = 92 then begin
    len := sp^.str_len;
    if sp^.str_chars[len] = chr(0) then
      len := len - 1;
    get_name_rep := pds_$make_name(sp^.str_chars, len);
  end
  else if sp^.kind = 110 then begin
    len := sp^.xw[35];
    if sp^.xc[71 + len] = chr(0) then
      len := len - 1;
    get_name_rep := pds_$make_name(sp^.xc[72], len);
  end
  else
    bug_check('\\DEBUG_SYM_DMP_\GET_STRING_REP -- sp must be an id_ob or char_string_ob.%$');
end;

{ get_src_loc_rep - the PDS_ source location of a source position.
  0x0A9B44, 0x3C bytes (no A5: internal). }

function get_src_loc_rep(
    position: integer): univ_ptr; options(val_param); internal;
var
  file_index, line: integer;
begin
  get_include_file_index(position, file_index, line);
  get_src_loc_rep := pds_$make_src_loc(file_index, line);
end;

{ get_alias_rep - the alias record of typedef a (kept at its +32).
  0x0A9B80, 0x78 bytes (no A5: internal): name +4, position +8, type
  +28. }

function get_alias_rep(
    a: il_$node_ptr_t): univ_ptr; options(val_param); internal;
var
  name, src, typ: univ_ptr;
  r: univ_ptr;
begin
  if a^.xp[8] <> nil then begin
    get_alias_rep := a^.xp[8];
    return;
  end;
  name := get_name_rep(a^.xp[1]);
  src := get_src_loc_rep(a^.xw[4]);
  r := pds_$make_alias_rec(name, src);
  a^.xp[8] := r;
  typ := get_type_rep(a^.xp[7]);
  pds_$add_dependent_type_to_alias_rec(r, typ);
  may_need_common_aux(r, a, 0);
  get_alias_rep := r;
end;

{ get_variable_rep - the variable record of vp (kind 109, else
  reported) of block blk (kept at +64), its location fixed up later;
  nil for nil.

  0x0A9BF8, 0x16E bytes (no A5: internal).  The type: +28, or its +16
  for a kind 121; the attributes 1 (+43 bit 0) and 3 (+32 bit 17); a
  Fortran symbol type gets the record at its +50.  A parameter (a kind
  121 type not over 207, or a Fortran symbol of class 5 or with +10
  bit 6) is entered in the pairs (+24, +26) for get_signature_rep. }

function get_variable_rep(
    vp: il_$node_ptr_t;
    blk: il_$node_ptr_t): univ_ptr; options(val_param); internal;
var
  name, src, typ: univ_ptr;
  attr: pds_$attrs_p_t;
  r: univ_ptr;
  t: il_$node_ptr_t;
begin
  if vp = nil then begin
    get_variable_rep := nil;
    return;
  end;
  if vp^.kind <> 109 then
    bug_check('\\DEBUG_SYM_DMP_\GET_VARIABLE_REP -- vp is not a var_name.%$');
  if vp^.xp[16] <> nil then begin
    get_variable_rep := vp^.xp[16];
    return;
  end;
  name := get_name_rep(vp^.xp[1]);
  attr := pds_$make_var_attr;
  src := get_src_loc_rep(vp^.xw[4]);
  t := vp^.xp[7];
  if t^.kind = 121 then
    typ := get_type_rep(t^.xp[4])
  else
    typ := get_type_rep(t);
  r := pds_$make_variable_rec(name, nil, src, typ, attr);
  add_obj_to_loc_fixup_list(vp, blk, r);
  if (ord(vp^.xc[43]) & 1) <> 0 then
    pds_$add_var_attr(r, 1);
  if (vp^.xl[8] & 16#20000) <> 0 then
    pds_$add_var_attr(r, 3);
  vp^.xp[16] := r;
  if vp^.xp[7]^.kind = 110 then
    vp^.xp[7]^.xp2[12] := r;
  t := vp^.xp[7];
  if ((t^.kind = 121) and then (t^.xp[4]^.kind <> 207)) or else
     ((t^.kind = 110) and then (((ord(t^.xc[11]) & 16#F0) div 16 = 5) or else
                                ((ord(t^.xc[10]) & 16#40) <> 0))) then begin
    npairs := npairs + 1;
    pairs[npairs].typ := vp^.xp[7];
    pairs[npairs].v := vp;
  end;
  may_need_common_aux(r, vp, 0);
  get_variable_rep := r;
end;

{ get_signature_rep - the signature record of routine r: its result
  (+96) and its arguments (+12, chained by +4), each with attributes by
  its passing (+44: 0 attribute 0, 1 and 4 attributes 3 and 4, 2 3, 3
  4); the current routine's arguments are matched with their variables
  in the pairs (one not found is reported and not added).

  0x0A9DA2, 0x15E bytes (no A5: internal): the arguments' count the
  byte +293; a jump table on +44 (compared unsigned with 5).  The
  found path jumps into the other's PDS_$MAKE_ARG (docs/rev889-
  patterns.md 23). }

function get_signature_rep(
    r: il_$node_ptr_t): univ_ptr; options(val_param); internal;
label
  10;
var
  src, res, sig, arg, v: univ_ptr;
  attr: pds_$attrs_p_t;
  nargs: integer;
  i, j: integer;
  a: il_$node_ptr_t;
begin
  src := get_src_loc_rep(r^.xw[150]);
  res := get_variable_rep(r^.xp[24], r);
  nargs := ord(r^.xc[293]);
  sig := pds_$make_signature_rec(nil, src, res, nargs);
  i := 1;
  a := r^.xp[3];
  while a <> nil do begin
    attr := pds_$make_arg_attr;
    case a^.xw[22] of
      0: pds_$add_arg_attr(attr, 0);
      1, 4: begin
        pds_$add_arg_attr(attr, 3);
        pds_$add_arg_attr(attr, 4);
      end;
      2: pds_$add_arg_attr(attr, 3);
      3: pds_$add_arg_attr(attr, 4);
      otherwise ;
    end;
    if r = cur_proc then begin
      for j := 1 to npairs do
        if pairs[j].typ = a then begin
          v := get_variable_rep(pairs[j].v, r);
          arg := pds_$make_arg(v, attr);
          pds_$add_arg_to_signature(sig, i, arg);
          goto 10;
        end;
      bug_check('\\DEBUG_SYM_DMP_\GET_SIGNATURE_REP -- Couldn''t find matching var_name for param.%$');
    end
    else begin
      arg := pds_$make_arg(nil, attr);
      pds_$add_arg_to_signature(sig, i, arg);
    end;
10:
    may_need_common_aux(sig, a, 0);
    a := a^.xp[1];
    i := i + 1;
  end;
  get_signature_rep := sig;
end;

{ get_tag - the tag naming structure or enumeration rec in scope (or an
  enclosing one): rec's own +36 for a kind 132, else the first tag of
  the blocks' +388 lists (chained by +4; the blocks by +8) whose +8 is
  rec, nil when its +20 is il_178; nil when none.

  0x0A9F52, 0x6A bytes (no A5: internal): the result kept in D0. }

function get_tag(
    rec: il_$node_ptr_t;
    scope: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  b, t: il_$node_ptr_t;
begin
  if (rec^.kind = 132) and (rec^.xp[9] <> nil) then begin
    get_tag := rec^.xp[9];
    return;
  end;
  get_tag := nil;
  b := scope;
  while b <> nil do begin
    t := dsd_$tags_p_t(b)^.tags;
    while t <> nil do begin
      if t^.xp[2] = rec then begin
        if t^.xp[5] <> il_178 then
          get_tag := t;
        return;
      end;
      t := t^.xp[1];
    end;
    b := b^.xp[2];
  end;
end;

{ get_record_rep - the record record of structure or union t (kind 196
  or 132, else reported; kept at its +40 when it has a tag): a short
  record unless a field is a bit field (kind 120), its fields (+4,
  chained by +4) named (+8) and typed (+16) at their offsets (+44; a
  bit field's +48 bits 5..3 added, its first bit bits 2..0, its width
  +49, its flag +48 bit 6), then their auxiliary records.

  0x0A9FBC, 0x2BE bytes (loads A5): t by address (the callers pass
  their variable's or field's address); the size from TYPE_EXP; the
  tag from get_tag in the current routine (+4216). }

function get_record_rep;
var
  has_bits: boolean;
  nfields: integer;
  f, tag: il_$node_ptr_t;
  te: dsd_$type_exp_t;
  name, src, typ, fld: univ_ptr;
  rec: univ_ptr;
  i: integer;
  offset: integer32;
begin
  if not ((t^.kind = 196) or (t^.kind = 132)) then
    bug_check('\\DEBUG_SYM_DMP_\GET_RECORD_REP -- object is not a record.%$');
  if t^.xp[10] <> nil then begin
    get_record_rep := t^.xp[10];
    return;
  end;
  has_bits := false;
  nfields := 0;
  f := t^.xp[1];
  while f <> nil do begin
    nfields := nfields + 1;
    if f^.kind = 120 then
      has_bits := true;
    f := f^.xp[1];
  end;
  type_exp(t, addr(te));
  if not has_bits then begin
    tag := get_tag(t, cur_proc);
    if tag = nil then
      rec := pds_$make_short_record_rec(nil, nil, te.size, nfields)
    else begin
      name := get_name_rep(tag^.xp[5]);
      src := get_src_loc_rep(tag^.xw[12]);
      rec := pds_$make_short_record_rec(name, src, te.size, nfields);
      t^.xp[10] := rec;
    end;
    i := 1;
    f := t^.xp[1];
    while f <> nil do begin
      name := get_name_rep(f^.xp[2]);
      typ := get_type_rep(f^.xp[4]);
      offset := f^.xl[11];
      fld := pds_$make_short_field(name, typ, offset);
      pds_$add_short_field(rec, i, fld);
      f := f^.xp[1];
      i := i + 1;
    end;
  end
  else begin
    tag := get_tag(t, cur_proc);
    if tag = nil then
      rec := pds_$make_record_rec(nil, nil, te.size, nfields)
    else begin
      name := get_name_rep(tag^.xp[5]);
      src := get_src_loc_rep(tag^.xw[12]);
      rec := pds_$make_record_rec(name, src, te.size, nfields);
      t^.xp[10] := rec;
    end;
    i := 1;
    f := t^.xp[1];
    while f <> nil do begin
      name := get_name_rep(f^.xp[2]);
      typ := get_type_rep(f^.xp[4]);
      if f^.kind = 120 then begin
        offset := (ord(f^.xc[48]) & 63) div 8 + f^.xl[11];
        fld := pds_$make_field(name, typ, 1, offset,
                               (ord(f^.xc[48]) & 63) & 7, ord(f^.xc[49]),
                               (ord(f^.xc[48]) & 16#40) <> 0);
      end
      else begin
        offset := f^.xl[11];
        fld := pds_$make_field(name, typ, 0, offset,
                               (ord(f^.xc[48]) & 63) & 7, ord(f^.xc[49]),
                               (ord(f^.xc[48]) & 16#40) <> 0);
      end;
      pds_$add_field(rec, i, fld);
      f := f^.xp[1];
      i := i + 1;
    end;
  end;
  i := 1;
  f := t^.xp[1];
  while f <> nil do begin
    may_need_common_aux(rec, f, i);
    f := f^.xp[1];
    i := i + 1;
  end;
  get_record_rep := rec;
end;

{ get_enum_rep - the enumeration record of t (kind 129, else reported;
  kept at its +12 when it has a tag): its +6 elements (+16, an array)
  with their names (+4) and values (+32's +8).

  0x0AA2B6, 0x132 bytes (loads A5): t by address; the size TYPE_EXP's
  (its low word). }

function get_enum_rep;
var
  te: dsd_$type_exp_t;
  tag, e: il_$node_ptr_t;
  name, src, rec, el: univ_ptr;
  value: integer32;
  i: integer;
begin
  if t^.kind <> 129 then
    bug_check('\\DEBUG_SYM_DMP_\GET_ENUM_REP -- object is not an enum.%$');
  if t^.xp[3] <> nil then begin
    get_enum_rep := t^.xp[3];
    return;
  end;
  type_exp(t, addr(te));
  tag := get_tag(t, cur_proc);
  if tag = nil then
    rec := pds_$make_explicit_enum_rec(nil, nil, te.size, t^.xw[3])
  else begin
    name := get_name_rep(tag^.xp[5]);
    src := get_src_loc_rep(tag^.xw[12]);
    rec := pds_$make_explicit_enum_rec(name, src, te.size, t^.xw[3]);
    t^.xp[3] := rec;
  end;
  for i := 1 to t^.xw[3] do begin
    e := dsd_$nodes_p_t(t^.xp[4])^[i];
    name := get_name_rep(e^.xp[1]);
    value := dsd_$nodes_p_t(t^.xp[4])^[i]^.xp[8]^.xl[2];
    el := pds_$make_explicit_enum_element(name, value);
    pds_$add_explicit_enum_element(rec, i, el);
  end;
  get_enum_rep := rec;
end;

{ get_type_rep - the PDS_ type of type t: a standard type's code (1..3
  the signed integral sizes 1, 2, other; 4..6 the unsigned; 7 a
  floating type of size 6, 8 the other; 15 kind 126, 14 kind 125, 11
  kind 124, 20 kind 210, 19 kind 234, 16 kind 135 and pointers to kind
  210 or 76, 17 kind 136, 2 and 1 the subranges -32767..32767 and
  -128..127 of an integral type, 14 the elements of a kind 127 array of
  a subrange or integral type), else code 22 with a record: an alias
  (118: a typedef of the outer block (il_184) of a simple type is its
  type), a pointer (130), a set (134), a subrange (128), a file (133),
  an array (197, 131, 127: its bounds from TYPE_EXP of the index type;
  197 a conformant one), an offset (177), an enumeration (129), a
  function type's signature (174, 173: its arguments as
  get_signature_rep's, without variables), a routine's signature (108,
  107), a structure (132, 196).  Another kind is reported.

  0x0AA422, 0x636 bytes (no A5: internal): a compare chain on the kind;
  every case ends in one PDS_$MAKE_TYPE; t's address passed to
  get_record_rep and get_enum_rep (by address). }

function get_type_rep;
var
  te, te2: dsd_$type_exp_t;
  r, et, it, at: univ_ptr;
  attr: pds_$attrs_p_t;
  arg: univ_ptr;
  i: integer;
  a: il_$node_ptr_t;
  conformant, b128: boolean;
  w120: integer;
  l68: integer32;
begin
  case t^.kind of
    122:
      if dsd_$bools_p_t(t)^[6] then
        case t^.xw[2] of
          1: get_type_rep := pds_$make_type(1, nil);
          2: get_type_rep := pds_$make_type(2, nil);
          otherwise get_type_rep := pds_$make_type(3, nil);
        end
      else
        case t^.xw[2] of
          1: get_type_rep := pds_$make_type(4, nil);
          2: get_type_rep := pds_$make_type(5, nil);
          otherwise get_type_rep := pds_$make_type(6, nil);
        end;
    123:
      if t^.xw[2] = 6 then
        get_type_rep := pds_$make_type(7, nil)
      else
        get_type_rep := pds_$make_type(8, nil);
    126: get_type_rep := pds_$make_type(15, nil);
    125: get_type_rep := pds_$make_type(14, nil);
    124: get_type_rep := pds_$make_type(11, nil);
    210: get_type_rep := pds_$make_type(20, nil);
    234: get_type_rep := pds_$make_type(19, nil);
    135: get_type_rep := pds_$make_type(16, nil);
    118:
      if (t^.xp[5] = il_184) and then is_simple_type(t^.xp[7]) then
        get_type_rep := get_type_rep(t^.xp[7])
      else begin
        r := get_alias_rep(t);
        get_type_rep := pds_$make_type(22, r);
      end;
    130:
      if (t^.xp[1]^.kind = 210) or (t^.xp[1]^.kind = 76) then
        get_type_rep := pds_$make_type(16, nil)
      else begin
        et := get_type_rep(t^.xp[1]);
        r := pds_$make_pointer_rec(nil, nil, et);
        get_type_rep := pds_$make_type(22, r);
      end;
    136: get_type_rep := pds_$make_type(17, nil);
    134: begin
      type_exp(t, addr(te));
      et := get_type_rep(t^.xp[1]);
      r := pds_$make_set_rec(nil, nil, et, te.size, t^.xw[6]);
      get_type_rep := pds_$make_type(22, r);
    end;
    128:
      if (t^.xp[1]^.kind = 122) and (t^.xp[2]^.xl[2] = -32767) and
         (t^.xp[3]^.xl[2] = 32767) then
        get_type_rep := pds_$make_type(2, nil)
      else if (t^.xp[1]^.kind = 122) and (t^.xp[2]^.xl[2] = -128) and
              (t^.xp[3]^.xl[2] = 127) then
        get_type_rep := pds_$make_type(1, nil)
      else begin
        type_exp(t, addr(te));
        et := get_type_rep(t^.xp[1]);
        r := pds_$make_subrange_rec(nil, nil, et, t^.xp[2]^.xl[2],
                                    t^.xp[3]^.xl[2], te.size);
        get_type_rep := pds_$make_type(22, r);
      end;
    133: begin
      et := get_type_rep(t^.xp[1]);
      r := pds_$make_file_rec(nil, nil, et);
      may_need_common_aux(r, t, 0);
      get_type_rep := pds_$make_type(22, r);
    end;
    197, 131, 127: begin
      type_exp(t^.xp[1], addr(te));
      if (t^.kind = 127) and
         ((te.base^.kind = 128) or (te.base^.kind = 122)) then
        et := pds_$make_type(14, nil)
      else
        et := get_type_rep(t^.xp[1]);
      it := get_type_rep(t^.xp[2]);
      type_exp(t^.xp[2], addr(te));
      if t^.kind = 197 then begin
        conformant := true;
        b128 := dsd_$bools_p_t(t)^[46];
        w120 := t^.xw[22];
        l68 := 1;
      end
      else begin
        conformant := false;
        b128 := false;
        w120 := 0;
        l68 := t^.xl[3];
      end;
      r := pds_$make_array_rec(nil, nil, et, it, te.low, te.high, l68,
                               t^.xl[10], false, conformant, b128, 0,
                               false, w120);
      get_type_rep := pds_$make_type(22, r);
    end;
    177: begin
      if t^.xp[9]^.kind = 76 then
        at := pds_$make_type(16, nil)
      else
        at := get_type_rep(t^.xp[9]);
      et := get_type_rep(t^.xp[10]);
      type_exp(t^.xp[10], addr(te2));
      type_exp(t, addr(te));
      r := pds_$make_offset_rec(nil, nil, at, et, te2.low, te2.high,
                                t^.xw[25], t^.xl[13], te.size);
      get_type_rep := pds_$make_type(22, r);
    end;
    129: begin
      r := get_enum_rep(t);
      get_type_rep := pds_$make_type(22, r);
    end;
    174, 173: begin
      r := pds_$make_signature_rec(nil, nil, nil, t^.xw[37]);
      i := 1;
      a := t^.xp[1];
      while a <> nil do begin
        attr := pds_$make_arg_attr;
        case a^.xw[22] of
          0: pds_$add_arg_attr(attr, 0);
          1, 4: begin
            pds_$add_arg_attr(attr, 3);
            pds_$add_arg_attr(attr, 4);
          end;
          2: pds_$add_arg_attr(attr, 3);
          3: pds_$add_arg_attr(attr, 4);
          otherwise ;
        end;
        arg := pds_$make_arg(nil, attr);
        pds_$add_arg_to_signature(r, i, arg);
        may_need_common_aux(r, a, 0);
        a := a^.xp[1];
        i := i + 1;
      end;
      get_type_rep := pds_$make_type(22, r);
    end;
    108, 107: begin
      r := get_signature_rep(t);
      get_type_rep := pds_$make_type(22, r);
    end;
    132, 196: begin
      r := get_record_rep(t);
      get_type_rep := pds_$make_type(22, r);
    end;
    otherwise
      bug_check('\\DEBUG_SYM_DMP_\GET_TYPE_REP -- Unknown type.%$');
  end;
end;

{ get_label_rep - the label record of lp (kind 117, else reported),
  its location fixed up later (its block +20).
  0x0AAA88, 0x6C bytes (no A5: internal). }

function get_label_rep(
    lp: il_$node_ptr_t): univ_ptr; options(val_param); internal;
var
  name, src, r: univ_ptr;
begin
  if lp^.kind <> 117 then
    bug_check('\\DEBUG_SYM_DMP_\GET_LABEL_REP -- lp is not a label_name.%$');
  name := get_name_rep(lp^.xp[1]);
  src := get_src_loc_rep(lp^.xw[4]);
  r := pds_$make_label_rec(name, nil, src);
  add_obj_to_loc_fixup_list(lp, lp^.xp[5], r);
  get_label_rep := r;
end;

{ get_const_rep - the constant record of c (a constant, 116, or a
  Fortran symbol, 110): its value's bytes (its +32 token: the integer
  kinds' value placed at the top of a longword for sizes 1 and 2, the
  reals' (88 from +16, 89 from +12), a string's characters, a set's
  words less the leading zero words, a pair's 8 bytes, a double
  complex's 16), its type (a string's code 15).

  0x0AAB30, 0x2DE bytes (no A5: internal; the message names it
  DUMP_CONST).  The size is TYPE_EXP's of +28, or the string's length
  (92, 212), or the set's (156) bytes less its leading zero words (2
  when all are zero), or sz_fsym's: they are stored into the type_exp
  record's size (-16), whose low word goes to PDS_$MAKE_CONSTANT_VALUE.
  An integer token's value is loaded when its kind is in [77..87, 101,
  200] (the set after the routine).  Another kind is reported (the
  value is not set). }

function get_const_rep(
    c: il_$node_ptr_t): univ_ptr; options(val_param); internal;
var
  te: dsd_$type_exp_t;
  v: il_$node_ptr_t;
  zeros, i: integer;
  len: integer32;
  value: integer32;
  shifted: integer32;
  single: integer32;
  pair: array [1..2] of integer32;
  quad: array [1..4] of integer32;
  name, src, typ, val: univ_ptr;
begin
  if c^.kind = 110 then
    te.size := sz_fsym(c)
  else begin
    v := c^.xp[8];
    if v^.kind = 92 then
      te.size := v^.str_len
    else if v^.kind = 212 then
      te.size := v^.str_len
    else if v^.kind = 156 then begin
      len := v^.set_len;
      zeros := 0;
      for i := 1 to (len + 1) div 2 do begin
        if v^.set_words[i] <> 0 then
          exit;
        zeros := zeros + 1;
      end;
      te.size := len - 2 * zeros;
      if te.size = 0 then begin
        te.size := 2;
        zeros := zeros - 1;
      end;
    end
    else
      type_exp(c^.xp[7], addr(te));
  end;
  name := get_name_rep(c^.xp[1]);
  src := get_src_loc_rep(c^.xw[4]);
  if c^.xp[8]^.kind = 92 then
    typ := pds_$make_type(15, nil)
  else
    typ := get_type_rep(c^.xp[7]);
  v := c^.xp[8];
  if v^.kind in [77..87, 101, 200] then
    value := v^.int_value;
  case v^.kind of
    77, 86, 200: begin
      shifted := lshft(value, 24);
      val := pds_$make_constant_value(shifted, te.size);
    end;
    78, 80, 83: begin
      shifted := lshft(value, 16);
      val := pds_$make_constant_value(shifted, te.size);
    end;
    79, 82, 85: begin
      single := value;
      val := pds_$make_constant_value(single, te.size);
    end;
    81:
      if te.size = 1 then begin
        shifted := lshft(value, 24);
        val := pds_$make_constant_value(shifted, te.size);
      end
      else if te.size = 2 then begin
        shifted := lshft(value, 16);
        val := pds_$make_constant_value(shifted, te.size);
      end
      else begin
        single := value;
        val := pds_$make_constant_value(single, te.size);
      end;
    88: val := pds_$make_constant_value(v^.xl[4], te.size);
    89: val := pds_$make_constant_value(v^.xl[3], te.size);
    87: begin
      shifted := lshft(v^.int_value, 24);
      val := pds_$make_constant_value(shifted, te.size);
    end;
    92: val := pds_$make_constant_value(v^.str_chars, te.size);
    156, 212: val := pds_$make_constant_value(v^.set_words[zeros + 1],
                                              te.size);
    90: begin
      pair[1] := v^.xl[3];
      pair[2] := v^.xl[4];
      val := pds_$make_constant_value(pair, te.size);
    end;
    198: begin
      quad[1] := v^.xl[3];
      quad[2] := v^.xl[4];
      quad[3] := v^.xl[5];
      quad[4] := v^.xl[6];
      val := pds_$make_constant_value(quad, te.size);
    end;
    otherwise
      bug_check('\\DEBUG_SYM_DMP_\DUMP_CONST -- Unknown constant ob.%$');
  end;
  get_const_rep := pds_$make_constant_rec(name, src, typ, val);
end;

{ get_entry_rep - the entry record of routine r (108, 107, 105, else
  reported): its name (+296), position (+300) and signature; its
  location fixed up later.
  0x0AAE5E, 0x9A bytes (no A5: internal): the last argument a cleared
  frame word. }

function get_entry_rep(
    r: il_$node_ptr_t): univ_ptr; options(val_param); internal;
var
  name, src, sig, e: univ_ptr;
begin
  if not ((r^.kind = 108) or (r^.kind = 107) or (r^.kind = 105)) then
    bug_check('\\DEBUG_SYM_DMP_\GET_ENTRY_REP -- unknown entry block.%$');
  name := get_name_rep(r^.xp[74]);
  src := get_src_loc_rep(r^.xw[150]);
  sig := get_signature_rep(r);
  e := pds_$make_entry_rec(name, nil, src, sig, 0);
  add_obj_to_loc_fixup_list(r, r, e);
  get_entry_rep := e;
end;

{ skip_unreferenced_include_object - whether object o (a typedef or
  constant, 118, 116: position +8, referenced +10; a tag, 6, 16, 17:
  +24, +26) comes from an include file and is not referenced; never
  under -CD (+0x28B bit 6) or -DBH.
  0x0AAF30, 0x86 bytes (no A5: internal). }

function skip_unreferenced_include_object(
    o: il_$node_ptr_t): boolean; options(val_param); internal;
var
  in_main, referenced: boolean;
begin
  if cargs_$options.cd or cargs_$options.dbh then
    skip_unreferenced_include_object := false
  else begin
    case o^.kind of
      118, 116: begin
        in_main := spos_$line_is_in_main_source_file(o^.xw[4]);
        referenced := dsd_$bools_p_t(o)^[10];
        in_main := not in_main;
        referenced := not referenced;
      end;
      6, 16, 17: begin
        in_main := spos_$line_is_in_main_source_file(o^.xw[12]);
        referenced := dsd_$bools_p_t(o)^[26];
        in_main := not in_main;
        referenced := not referenced;
      end;
      otherwise begin
        in_main := false;
        referenced := false;
      end;
    end;
    skip_unreferenced_include_object := in_main and referenced;
  end;
end;

{ process_named_objects - the named objects of block blk entered in the
  current scope: its objects (+16, then +24; a Fortran symbol chained
  by +4, the others by +16) not skipped: the variables (not +34 bit
  14, not routines, of a known block (+20 neither nil nor il_178), not
  a kind 121 class 5 of +44 0, not over kind 207), the typedefs (not
  those get_type_rep makes standard), the constants (not an
  enumeration's own elements, not a kind 137/138 token of +36 26), the
  labels named by an identifier, the Fortran symbols (variables of
  class 3 (unless +26 bit 14 and not the routine's result +96) and the
  routine's result of class 1 (made from a fresh variable; the result
  named and placed as the routine), constants of class 2, labels of
  class 6 with a +48 +56 other than -1); then its tags (+388); then the
  block itself when a routine.  A nil record is reported.

  0x0AAFB6, 0x30A bytes (no A5: internal; it reaches +24 through its
  caller's A5). }

procedure process_named_objects(
    blk: il_$node_ptr_t); options(val_param); internal;
label
  10;
var
  o, t, v, tg: il_$node_ptr_t;
  second: boolean;
  rec: univ_ptr;
  i: integer;
  cls: integer;
begin
  npairs := 0;
  second := false;
  o := blk^.xp[4];
  while o <> nil do begin
    if not skip_unreferenced_include_object(o) then begin
      if o^.kind = 109 then begin
        if (o^.xw[17] & 16#4000) <> 0 then
          goto 10;
        t := o^.xp[7];
        if (t^.kind = 108) or (t^.kind = 107) then
          goto 10;
        if (o^.xp[5] = il_178) or (o^.xp[5] = nil) then
          goto 10;
        if (o^.xw[36] = 5) and (t^.kind = 121) and (t^.xw[22] = 0) then
          goto 10;
        if (t^.kind = 121) and (t^.xp[4]^.kind = 207) then
          goto 10;
        rec := get_variable_rep(o, blk);
      end
      else if o^.kind = 118 then begin
        if (o^.xp[5] = il_184) and then is_simple_type(o^.xp[7]) then
          goto 10;
        rec := get_alias_rep(o);
      end
      else if o^.kind = 116 then begin
        v := o^.xp[8];
        if ((v^.kind = 138) or (v^.kind = 137)) and (v^.xw[18] = 26) then
          goto 10;
        t := o^.xp[7];
        if t^.kind = 129 then
          for i := 1 to t^.xw[3] do
            if dsd_$nodes_p_t(t^.xp[4])^[i] = o then
              goto 10;
        rec := get_const_rep(o);
      end
      else if (o^.kind = 117) and (o^.xp[1]^.kind = 76) then
        rec := get_label_rep(o)
      else if o^.kind = 110 then begin
        cls := (ord(o^.xc[44]) & 16#F0) div 16;
        if ((cls = 3) and (((o^.xw[13] & 16#4000) = 0) or
                           (o = blk^.xp[24]))) or
           ((cls = 1) and (o = blk^.xp[24])) then begin
          v := varn_from_fortran_symbol(o, blk, true);
          if (o = blk^.xp[24]) and
             ((ord(o^.xc[44]) & 16#F0) div 16 = 3) then begin
            v^.xp[1] := blk^.xp[74];
            v^.xw[4] := blk^.xw[150];
            v^.xl[8] := o^.xl[8] & ~16#4000;
          end;
          rec := get_variable_rep(v, blk);
        end
        else if cls = 2 then
          rec := get_const_rep(o)
        else if cls = 6 then begin
          if o^.xp[12]^.xl[14] = -1 then
            goto 10;
          rec := get_label_rep(label_from_fortran_symbol(o, blk));
        end
        else
          goto 10;
      end
      else
        goto 10;
      if rec = nil then
        bug_check('\\DEBUG_SYM_DMP_\PROCESS_NAMED_OBJECTS --- pds_rec_p is NIL.%$');
      pds_$enter_named_record_current_scope(rec);
    end;
10:
    if o^.kind = 110 then
      o := o^.xp[1]
    else
      o := o^.xp[4];
    if not second and (o = nil) then begin
      second := true;
      o := blk^.xp[6];
    end;
  end;
  tg := dsd_$tags_p_t(blk)^.tags;
  while tg <> nil do begin
    if (tg^.xp[2] <> nil) and (tg^.xp[5] <> il_178) and then
       not skip_unreferenced_include_object(tg) then begin
      if tg^.xp[2]^.kind = 132 then
        rec := get_record_rep(tg^.xp[2])
      else if tg^.xp[2]^.kind = 129 then
        rec := get_enum_rep(tg^.xp[2])
      else
        bug_check('\\DEBUG_SYM_DMP_\PROCESS_NAMED_OBJECTS --- Unknown kind on su chain.%$');
      if rec = nil then
        bug_check('\\DEBUG_SYM_DMP_\PROCESS_NAMED_OBJECTS --- pds_rec_p is NIL.%$');
      pds_$enter_named_record_current_scope(rec);
    end;
    tg := tg^.xp[1];
  end;
  if (blk^.kind = 105) or (blk^.kind = 108) or (blk^.kind = 107) then begin
    rec := get_entry_rep(blk);
    pds_$enter_named_record_current_scope(rec);
  end;
end;

{ process_debug_symbols - a scope for each routine of il_184's chain
  (from the outer block's first routine when the outer block (106)
  holds one: 106 or 105) that is the first or has +379 bit 2; its
  first record kept at its +208.
  0x0AB344, 0x74 bytes (no A5: internal). }

procedure process_debug_symbols; internal;
var
  b, first: il_$node_ptr_t;
begin
  b := il_184;
  if b <> nil then
    if b^.kind = 106 then
      if (b^.xp[1]^.kind = 106) or (b^.xp[1]^.kind = 105) then
        b := b^.xp[1];
  first := b;
  while b <> nil do begin
    if ((ord(b^.xc[379]) & 4) <> 0) or (b = first) then begin
      pds_$begin_scope;
      cur_proc := b;
      process_named_objects(b);
      pds_$end_scope(b^.xp[52]);
    end;
    b := b^.xp[1];
  end;
end;

{ debug_sym_dmp_$create_symbols_sections - the routines' symbols made
  and the .symbols sections created (add_symbols_section); the list
  (+4208, chained by +8) and its last section returned.

  0x0AB3B8, 0x48 bytes: first and last by address (unix_objmod's
  +0x5C30 and +0x5C2C). }

procedure debug_sym_dmp_$create_symbols_sections;
var
  s: il_$node_ptr_t;
begin
  process_debug_symbols;
  pds_$create_symbols_sections(addr(add_symbols_section));
  first := sym_sections;
  s := first;
  while (s <> nil) and (s^.xp[2] <> nil) do
    s := s^.xp[2];
  last := s;
end;

{ debug_sym_dmp_$dump_symbols_section - section written from
  start_offset; its end returned.

  0x0AB400, 0x40 bytes: PDS_$DUMP_SYMBOLS_SECTION with obj_alloc,
  dumpfunc and add_name_to_symbols_section (their addresses pushed). }

procedure debug_sym_dmp_$dump_symbols_section;
begin
  pds_$dump_symbols_section(integer32(section), start_offset, end_offset,
                            addr(obj_alloc), addr(dumpfunc),
                            addr(add_name_to_symbols_section));
end;

{ create_string_table - an empty string table of the mark.

  0x0AB440, 0x1C bytes (no A5: internal; no frame: the word and the
  byte at (4,SP) and (6,SP), the table's address at (8,SP)). }

procedure create_string_table(
    mark: integer;
    is_local: boolean;
    out tbl: dsd_$string_table_t); options(val_param); internal;
begin
  tbl.size := 0;
  tbl.list := nil;
  tbl.mark := mark;
  tbl.is_local := is_local;
end;

{ dump_string_table - the string table written at pos (a record of
  kind 28 when local, else 27: its size, then each name with a null,
  folded to lower case when fold), each identifier given its name's
  offset (its +12's low 30 bits); the entries disposed.

  0x0AB45C, 0x102 bytes (no A5: internal): nothing for an empty list.
  The offsets count from the record's text: computed as the text's
  address + the start - the record's address (`lea (6,A2),A0; add.l
  D2; sub.l A2'). }

procedure dump_string_table(
    var pos: integer32;
    var tbl: dsd_$string_table_t;
    fold: boolean); options(val_param); internal;
var
  start, base: integer32;
  r: dst_$rec_p_t;
  e, old: dsd_$str_entry_p_t;
  i, k: integer32;
  c: char;
begin
  if tbl.list = nil then
    return;
  start := pos;
  r := dst_$rec_p_t(obj_alloc(pos, tbl.size + 6));
  base := start + 6;
  if tbl.is_local then
    r^.kind := 28
  else
    r^.kind := 27;
  r^.flags := [];
  r^.text_len := tbl.size;
  e := tbl.list;
  i := 1;
  while e <> nil do begin
    dsd_$idnt_ref_p_t(e^.node)^.offset := i + base - 1;
    for k := 1 to e^.node^.idnt_len do begin
      r^.text[i] := e^.node^.idnt_name[k];
      if fold then begin
        c := r^.text[i];
        if (c >= 'A') and (c <= 'Z') then
          r^.text[i] := chr(ord('a') + ord(c) - ord('A'));
      end;
      i := i + 1;
    end;
    r^.text[i] := chr(0);
    i := i + 1;
    old := e;
    e := e^.next;
    dispose(old);
  end;
end;

{ clear_emitted_marker - id (a Fortran symbol's name looked up) not
  marked as entered in the table.
  0x0AB55E, 0x64 bytes (no A5: internal). }

procedure clear_emitted_marker(
    var tbl: dsd_$string_table_t;
    id: il_$node_ptr_t); options(val_param); internal;
begin
  if id^.kind = 110 then
    id := idntk(76, id^.xc[72], id^.xw[35]);
  dsd_$idnt_ref_p_t(id)^.entered := dsd_$idnt_ref_p_t(id)^.entered -
                                    [tbl.mark];
end;

{ force_add_string - id (a Fortran symbol's name looked up) entered in
  the table: a new entry (8 bytes from PAS_$NEW) at the head, its bytes
  (with the null) counted, the identifier marked.
  0x0AB5C2, 0x94 bytes (no A5: internal). }

procedure force_add_string;
var
  e: dsd_$str_entry_p_t;
begin
  new(e);
  if id^.kind <> 110 then
    e^.node := id
  else
    e^.node := idntk(76, id^.xc[72], id^.xw[35]);
  e^.next := tbl.list;
  tbl.list := e;
  tbl.size := tbl.size + (e^.node^.idnt_len + 1);
  dsd_$idnt_ref_p_t(e^.node)^.entered :=
    dsd_$idnt_ref_p_t(e^.node)^.entered + [tbl.mark];
end;

{ add_string - id entered in the table unless it is marked already.
  0x0AB656, 0x54 bytes (no A5: internal). }

procedure add_string(
    var tbl: dsd_$string_table_t;
    id: il_$node_ptr_t); options(val_param); internal;
begin
  if id^.kind = 110 then
    id := idntk(76, id^.xc[72], id^.xw[35]);
  if not (tbl.mark in dsd_$idnt_ref_p_t(id)^.entered) then
    force_add_string(tbl, id);
end;

{ get_debug_offset - the object file offset of id's name (dump_string_
  table's).  0x0AB6AA, 0x38 bytes (no A5: internal): `lsl.l #2; asr.l
  #2'. }

function get_debug_offset(
    id: il_$node_ptr_t): integer32; options(val_param); internal;
var
  n: il_$node_ptr_t;
begin
  if id^.kind <> 110 then
    n := id
  else
    n := idntk(76, id^.xc[72], id^.xw[35]);
  get_debug_offset := dsd_$idnt_ref_p_t(n)^.offset;
end;

{ get_src_loc - a source position as a dst_$src_loc_t.
  0x0AB6E2, 0x60 bytes (no A5: internal): built in a frame longword,
  returned in D0. }

function get_src_loc(
    position: integer): integer32; options(val_param); internal;
var
  file_index, line: integer;
  r: dsd_$src_loc_t;
begin
  get_include_file_index(position, file_index, line);
  r.loc.unused := false;
  r.loc.file_index := file_index;
  r.loc.line := line;
  get_src_loc := r.l;
end;

{ make_relative_ref - the reference from offset from to offset target
  (tag 3 when negative, else 0).
  0x0AB742, 0x48 bytes (no A5: internal). }

function make_relative_ref(
    target: integer32;
    from: integer32): integer32; options(val_param); internal;
var
  d: integer32;
  r: dsd_$rel_t;
begin
  d := target - from;
  if d < 0 then
    r.rel.tag := dst_$rel_negative
  else
    r.rel.tag := dst_$rel_positive;
  r.rel.offset := d;
  make_relative_ref := r.l;
end;

{ write_blocks - the block records of the tree's siblings from e, each
  followed (under -DBS/-DBA) by its auxiliary records (the scope's
  offset in its .symbols section, the source lines +300 and +270, the
  ranges' exception tables when one has one); the blocks counted in
  count; the last block's offset returned.

  0x0AB78A, 0x36C bytes (no A5: internal; recursive for the nested
  blocks).  The block's kind by its node's (106 0; 105 1, 3; 107 2, 2;
  108 3, 2; 172 and 167 9, 2; 209 5; another reported); its name (+296
  unless kind 73); a routine's code ranges (+152, chained by +0; each
  +4..+8 with the code section's +62, the exception table's offset
  (gen_debug_$exception_table_size) + +16, and its exception entry
  +20 when not negative), written last range first, or the routine's
  one range (+160, +156, +200).  The previous sibling's and the first
  nested block's references.

  Not known from the original:
  - what the bytes +2, +3 and the words at +16 and +34 mean. }

function write_blocks(
    e: dsd_$elt_p_t;
    var count: integer): integer32; options(val_param); internal;
var
  b: il_$node_ptr_t;
  r: dsd_$code_rng_p_t;
  prev, off, exc_size: integer32;
  has_exc: boolean;
  n: integer;
  k: integer;
  rec: dsd_$blk_rec_p_t;
  lines: dsd_$aux_lines_p_t;
  exc: dsd_$aux_exc_p_t;
begin
  if e = nil then
    bug_check('\\DEBUG_SYM_DMP_\WRITE_BLOCKS -- NIL block pointer.%$');
  prev := 0;
  exc_size := gen_debug_$exception_table_size;
  repeat
    count := count + 1;
    b := e^.block;
    off := obj_offset;
    has_exc := false;
    if not ((b^.kind = 209) or (b^.kind = 167) or (b^.kind = 106)) then begin
      if b^.xp[38] = nil then
        n := 1
      else begin
        n := 0;
        r := dsd_$code_rng_p_t(b^.xp[38]);
        repeat
          n := n + 1;
          if r^.entry >= 0 then
            has_exc := true;
          r := r^.next;
        until r = nil;
      end;
    end
    else
      n := 0;
    rec := dsd_$blk_rec_p_t(obj_alloc(obj_offset, n * 16 + 24));
    rec^.kind := 4;
    rec^.flags := [];
    if cargs_$options.db >= 2 then begin
      rec^.scope_kind := 3;
      rec^.scope_offset := pds_$get_scope_offset_within_section(b^.xp[52]);
      rec^.flags := rec^.flags + [dst_$has_aux];
      lines := dsd_$aux_lines_p_t(obj_alloc(obj_offset, 10));
      lines^.kind := 51;
      if has_exc then
        lines^.flags := []
      else
        lines^.flags := [dst_$last_aux];
      lines^.first := get_src_loc(b^.xw[150]);
      lines^.last := get_src_loc(b^.xw[135]);
    end
    else begin
      rec^.scope_kind := 0;
      rec^.scope_offset := 0;
    end;
    rec^.b3 := 0;
    case b^.kind of
      106: rec^.block_kind := 0;
      105: begin
        rec^.block_kind := 1;
        rec^.b3 := 3;
      end;
      107: begin
        rec^.block_kind := 2;
        rec^.b3 := 2;
      end;
      108: begin
        rec^.block_kind := 3;
        rec^.b3 := 2;
      end;
      172, 167: begin
        rec^.block_kind := 9;
        rec^.b3 := 2;
      end;
      209: rec^.block_kind := 5;
      otherwise
        bug_check('\\DEBUG_SYM_DMP_\WRITE_BLOCKS -- Unknown block kind.%$');
    end;
    if b^.xp[74] <> nil then
      if b^.xp[74]^.kind <> 73 then
        rec^.name := make_relative_ref(get_debug_offset(b^.xp[74]), off);
    if not ((b^.kind = 106) or (b^.kind = 209) or (b^.kind = 167)) then
      if b^.xp[38] <> nil then begin
        rec^.nranges := n;
        r := dsd_$code_rng_p_t(b^.xp[38]);
        if has_exc then begin
          exc := dsd_$aux_exc_p_t(obj_alloc(obj_offset, n * 6 + 4));
          exc^.kind := 54;
          exc^.flags := [dst_$last_aux];
          exc^.b2 := 0;
          exc^.count := n;
        end;
        k := n;
        repeat
          if has_exc then
            if r^.entry >= 0 then begin
              exc^.e[k].present := 1;
              exc^.e[k].offset := r^.entry;
            end
            else begin
              exc^.e[k].present := 0;
              exc^.e[k].offset := 0;
            end;
          rec^.ranges[k].length := r^.finish - r^.start;
          rec^.ranges[k].sect := b^.xp[47]^.xw[31];
          rec^.ranges[k].start := r^.start;
          rec^.ranges[k].one := 1;
          rec^.ranges[k].exc := exc_size + r^.exc;
          k := k - 1;
          r := r^.next;
        until r = nil;
      end
      else begin
        rec^.nranges := 1;
        rec^.ranges[1].length := b^.xl[40];
        rec^.ranges[1].sect := b^.xp[47]^.xw[31];
        rec^.ranges[1].start := b^.xl[39];
        rec^.ranges[1].one := 1;
        rec^.ranges[1].exc := b^.xl[50];
      end;
    if e^.child <> nil then
      rec^.child := make_relative_ref(write_blocks(e^.child, count), off)
    else
      rec^.child := make_relative_ref(0, 0);
    if prev <> 0 then
      rec^.sibling := make_relative_ref(prev, off);
    prev := off;
    e := e^.next;
  until e = nil;
  write_blocks := off;
end;

{ write_files - the local file table (kind 3) of the marked source
  files (their full path names, or the names used to open them, and
  their dtms; the main file's name from NAME_$GET_PATH_LC of the
  source pathname, or the pathname itself when that fails), preceded
  by its string table (a new one, mark 1, not local) and followed, when
  a file has a unit name, by the unit table (kind 53: the units' name
  references); the file table's offset returned.

  0x0ABCAA, 0x2BA bytes (no A5: internal).  The three nested routines
  are passed to SPOS_$APPLY_OVER_MARKED_SOURCE_FILES as routine
  parameters (trampolines at -1114, -1136, -1162, each followed by
  CACHE_$CLEAR); the names and dtms arrays from MEM_$ALLOC of the item
  pool (4 bytes per file), given back with MEM_$DISPOSE.  The file
  table's names are each identifier's offset (its +12, inline).
  NAME_$GET_PATH_LC's maximum length 1024 is the word after the
  routine (pattern 30).

  Not known from the original:
  - the locals' names. }

function write_files: integer32; internal;
type
  ids_p_t = ^array [1..16000] of il_$node_ptr_t;
  dtms_p_t = ^array [1..16000] of integer32;
var
  strtab: dsd_$string_table_t;
  path: array [1..1024] of char;
  status: status_$t;
  path_len: integer;
  nfiles: integer32;
  bytes: integer32;
  names: ids_p_t;
  dtms: dtms_p_t;
  has_units: boolean;
  lft: dsd_$lft_p_t;
  units: dsd_$table_p_t;
  units_base: integer32;
  base: integer32;
  i: integer32;
  m: integer32;

  { add_file_table_entry - region's file name (the full path name, or
    the name used to open it) and dtm kept at its mark, its unit name
    noted.  0x0ABB62, 0x9E bytes: the parent's frame from A1; loads
    A5. }

  procedure add_file_table_entry(
      region: integer32;
      mark: integer32); options(val_param);
  var
    u: il_$node_ptr_t;
  begin
    names^[mark] := spos_$region_full_path_name(region);
    if names^[mark] = nil then
      names^[mark] := spos_$region_name_used_to_open(region);
    clear_emitted_marker(strtab, names^[mark]);
    u := spos_$region_unit_name(region);
    if u <> nil then begin
      clear_emitted_marker(strtab, u);
      has_units := true;
    end;
    dtms^[mark] := spos_$region_dtm(region);
  end;

  { write_string_for_file_table_entry - the file's name and unit name
    entered in the string table.  0x0ABC00, 0x52 bytes: the parent's
    frame from A1; loads A5. }

  procedure write_string_for_file_table_entry(
      region: integer32;
      mark: integer32); options(val_param);
  var
    u: il_$node_ptr_t;
  begin
    u := spos_$region_unit_name(region);
    add_string(strtab, names^[mark]);
    if u <> nil then
      add_string(strtab, u);
  end;

  { add_unit_table_entry - the unit name's reference at the file's
    mark.  0x0ABC52, 0x58 bytes: the parent's frame from A1; loads
    A5. }

  procedure add_unit_table_entry(
      region: integer32;
      mark: integer32); options(val_param);
  var
    u: il_$node_ptr_t;
  begin
    u := spos_$region_unit_name(region);
    if u <> nil then
      units^.e[mark] := make_relative_ref(dsd_$idnt_ref_p_t(u)^.offset,
                                          units_base);
  end;

begin
  spos_$lock_source_file_marks;
  create_string_table(1, false, strtab);
  nfiles := spos_$number_of_marked_source_files;
  bytes := nfiles * 4;
  names := mem_$alloc(mem_$item_pool, bytes);
  dtms := mem_$alloc(mem_$item_pool, bytes);
  has_units := false;
  spos_$apply_over_marked_source_files(add_file_table_entry);
  if iosub_$source_pathname_length <> 0 then begin
    name_$get_path_lc(iosub_$source_pathname, iosub_$source_pathname_length,
                      1024, path, path_len, status);
    if status.all <> 0 then begin
      for i := 1 to iosub_$source_pathname_length do
        path[i] := iosub_$source_pathname[i];
      path_len := iosub_$source_pathname_length;
    end;
  end
  else
    path_len := 0;
  if spos_$region_is_marked(0) then begin
    m := spos_$mark_main_source_file;
    names^[m] := strtk(path, path_len);
    clear_emitted_marker(strtab, names^[m]);
    dtms^[m] := spos_$region_dtm(0);
  end;
  spos_$apply_over_marked_source_files(write_string_for_file_table_entry);
  dump_string_table(obj_offset, strtab, false);
  base := obj_offset;
  lft := dsd_$lft_p_t(obj_alloc(obj_offset, nfiles * 8 + 4));
  lft^.kind := dst_$local_file_table;
  lft^.flags := [];
  lft^.count := nfiles;
  for i := 1 to nfiles do begin
    lft^.e[i].id := dtms^[i];
    lft^.e[i].name :=
      make_relative_ref(dsd_$idnt_ref_p_t(names^[i])^.offset, base);
  end;
  if has_units then begin
    lft^.flags := lft^.flags + [dst_$has_aux];
    units_base := obj_offset;
    units := dsd_$table_p_t(obj_alloc(obj_offset, bytes + 4));
    units^.kind := 53;
    units^.flags := [dst_$last_aux];
    units^.count := nfiles;
    spos_$apply_over_marked_source_files(add_unit_table_entry);
  end;
  mem_$dispose(mem_$item_pool, names);
  mem_$dispose(mem_$item_pool, dtms);
  write_files := base;
end;

{ gen_section_table - the section table (kind 2): the .lines, .unwind
  and .symbols sections' addresses (unix_objmod +0x5C20..+0x5C28), then
  each relocated object's offset (a code section's +56, a section's +36
  - +16, a section node's +44, a variable's +56), each with a
  relocation against its symbol (+64, +44, +32, +76; .lines +0x5D3C
  when it is there, .unwind +0x5D38, .symbols +0x5D30 when it is there)
  in the debugging symbols' relocations' section (+0x5D8C); its offset
  returned.

  0x0ABF66, 0x1F0 bytes (no A5: internal): the entries' offsets from
  the record's +4 (computed as the address difference); the index a
  word; an object of another kind is CGERR 28. }

function gen_section_table: integer32; internal;
var
  start, first: integer32;
  rec: dsd_$table_p_t;
  b: dsd_$relocs_p_t;
  i: integer32;
  k: integer;
  o: il_$node_ptr_t;
begin
  start := obj_offset;
  rec := dsd_$table_p_t(obj_alloc(obj_offset, nrelocs * 4 + 4));
  rec^.kind := 2;
  rec^.flags := [];
  rec^.count := nrelocs;
  first := start + 4;
  rec^.e[1] := uobj_lines_addr;
  rec^.e[2] := uobj_unwind_addr;
  rec^.e[3] := uobj_symbols_addr;
  if uobj_lines_addr <> 0 then
    add_reloc(first, uobj_sym_sect, uobj_5d3c, nil);
  add_reloc(first + 4, uobj_sym_sect, uobj_5d38, nil);
  if uobj_symbols_addr <> 0 then
    add_reloc(first + 8, uobj_sym_sect, uobj_5d30, nil);
  k := 4;
  b := reloc_head;
  while b <> nil do begin
    for i := 1 to b^.count do begin
      o := b^.e[i];
      case o^.kind of
        182: begin
          rec^.e[k] := o^.xl[14];
          add_reloc(first + (k - 1) * 4, uobj_sym_sect, o^.xw[32], nil);
        end;
        183: begin
          rec^.e[k] := o^.xl[9] - o^.xl[4];
          add_reloc(first + (k - 1) * 4, uobj_sym_sect, o^.xw[22], nil);
        end;
        111: begin
          rec^.e[k] := o^.xl[11];
          add_reloc(first + (k - 1) * 4, uobj_sym_sect, o^.xw[16], nil);
        end;
        109: begin
          rec^.e[k] := o^.xl[14];
          add_reloc(first + (k - 1) * 4, uobj_sym_sect, o^.xw[38], nil);
        end;
        otherwise
          cgerr(28, 0, nil);
      end;
      k := k + 1;
    end;
    b := b^.next;
  end;
  gen_section_table := start;
end;

{ build_block_list - the block tree of il_184's chain (from the outer
  block's first routine as process_debug_symbols): each block (not 209;
  the first or with +379 bit 2) gets an element (the block heap, +260
  pointing back), at the head of the top list when it is the first or
  has no parent (+8), else at the head of its parent's nested list.
  0x0AC156, 0xB4 bytes (no A5: internal). }

procedure build_block_list(
    out head: dsd_$elt_p_t); internal;
var
  b, first: il_$node_ptr_t;
  e, p: dsd_$elt_p_t;
begin
  b := il_184;
  if b <> nil then
    if b^.kind = 106 then
      if (b^.xp[1]^.kind = 106) or (b^.xp[1]^.kind = 105) then
        b := b^.xp[1];
  first := b;
  head := nil;
  while b <> nil do begin
    if (b^.kind <> 209) and
       (((ord(b^.xc[379]) & 4) <> 0) or (b = first)) then begin
      e := mrh_$alloc_fixed(block_heap);
      e^.block := b;
      e^.child := nil;
      b^.xp[65] := il_$node_ptr_t(e);
      if head = nil then begin
        e^.next := nil;
        head := e;
      end
      else if b^.xp[2] = nil then begin
        e^.next := head;
        head := e;
      end
      else begin
        p := dsd_$elt_p_t(b^.xp[2]^.xp[65]);
        if p <> nil then begin
          e^.next := p^.child;
          p^.child := e;
        end;
      end;
    end;
    b := b^.xp[1];
  end;
end;

{ debug_sym_dmp_$block_dmp - the .blocks section written at offset
  (moved past it): the header (kind 1), the two string tables (+4192,
  then +4176 with the routines' names: a nested routine's (level above
  0) or one whose +376 bits 8..7 are 2 in +4176, else in +4192), the
  block tree, the section table, the local file table; the header's
  references from its own offset.

  0x0AC20A, 0x1B2 bytes: the first parameter (the same offset by
  value) is not read; the header +2 1, +3 4 under -CD (+0x28B bit 6)
  else 3, +4 1 for targets 1..3, +6 3, +8 the blocks' count, +22 the
  size. }

procedure debug_sym_dmp_$block_dmp;
var
  b, first: il_$node_ptr_t;
  head: dsd_$elt_p_t;
  hdr_off: integer32;
  hdr: dsd_$header_p_t;
  nblocks: integer;
begin
  create_string_table(1, false, strings_27);
  b := il_184;
  if b <> nil then
    if b^.kind = 106 then
      if (b^.xp[1]^.kind = 106) or (b^.xp[1]^.kind = 105) then
        b := b^.xp[1];
  first := b;
  while b <> nil do begin
    if ((ord(b^.xc[379]) & 4) <> 0) or (b = first) then
      if (dsd_$block_p_t(b)^.level > 0) or
         ((b^.xw[188] & 384) div 128 = 2) then
        add_string(strings_27, b^.xp[74])
      else
        force_add_string(strings_28, b^.xp[74]);
    b := b^.xp[1];
  end;
  obj_offset := offset;
  build_block_list(head);
  hdr_off := obj_offset;
  hdr := dsd_$header_p_t(obj_alloc(obj_offset, 26));
  hdr^.kind := 1;
  hdr^.flags := [];
  nblocks := 0;
  dump_string_table(obj_offset, strings_28, fold_case);
  dump_string_table(obj_offset, strings_27, fold_case);
  hdr^.b2 := 1;
  if cargs_$options.cd then
    hdr^.b3 := 4
  else
    hdr^.b3 := 3;
  hdr^.w6 := 3;
  if (target_properties.p_10 >= 1) and (target_properties.p_10 <= 3) then
    hdr^.w4 := 1
  else
    hdr^.w4 := nblocks;
  if head <> nil then
    hdr^.blocks := make_relative_ref(write_blocks(head, nblocks), hdr_off)
  else
    hdr^.blocks := make_relative_ref(0, 0);
  hdr^.nblocks := nblocks;
  hdr^.sections := make_relative_ref(gen_section_table, hdr_off);
  hdr^.files := make_relative_ref(write_files, hdr_off);
  hdr^.size := obj_offset - offset;
  offset := obj_offset;
end;

{ debug_sym_dmp_$init - set up for a compilation: names folded to lower
  case unless -U; the relocated objects' list started; under -DBS/-DBA
  the locs and fixup heaps, LOC_BUILD_ (allocfunc, dumpfunc; 2 for
  targets 1..3, else 1) and its pool, PDS_, the main file table (each
  root region's file entry at its mark); the block structure heap and
  the string table +4192 (mark 1, local).

  0x0AC44A, 0x13E bytes: add_file_entry passed to SPOS_$APPLY_OVER_
  SOURCE_FILES as a routine parameter (its trampoline at -24); the file
  table at -4. }

procedure debug_sym_dmp_$init;
var
  file_table: univ_ptr;
  kind: integer;

  { add_file_entry - region's file entry (its full path name, or the
    name used to open it, and its dtm) at its mark.  0x0AC3BC, 0x8E
    bytes: the parent's frame from A1; loads A5. }

  procedure add_file_entry(
      region: integer32); options(val_param);
  var
    mark: integer32;
    n: il_$node_ptr_t;
    name, fe: univ_ptr;
    dtm: integer32;
  begin
    spos_$mark_source_file(region, mark);
    n := spos_$region_full_path_name(region);
    if n = nil then
      n := spos_$region_name_used_to_open(region);
    name := get_name_rep(n);
    dtm := spos_$region_dtm(region);
    fe := pds_$make_file_entry(name, dtm);
    pds_$add_file_entry(file_table, mark, fe);
  end;

begin
  fold_case := not cargs_$options.u;
  prep_sections;
  if cargs_$options.db >= 2 then begin
    mrh_$initialize(locs_heap, 1, 0, 'debug_sym_dmp locs heap%.');
    mrh_$initialize(fixup_heap, 1, 16, 'debug_sym_dmp loc fixup heap%.');
    if (target_properties.p_10 >= 1) and (target_properties.p_10 <= 3) then
      kind := 2
    else
      kind := 1;
    loc_build__init(addr(allocfunc), nil, addr(dumpfunc), kind);
    loc_pool := loc_build__open_pool;
    pds_$initialize(fold_case);
    file_table := pds_$make_file_table(spos_$number_of_source_files,
                                       spos_$mark_main_source_file);
    spos_$apply_over_source_files(add_file_entry);
    pds_$enter_main_file_table(file_table);
  end;
  mrh_$initialize(block_heap, 1, 12, 'debug_sym_dmp block structure heap%');
  create_string_table(1, true, strings_28);
end;

{ debug_sym_dmp_$finalize - the heaps given back (under -DBS/-DBA the
  locs and fixup heaps and PDS_'s pools), then the block structure
  heap.  0x0AC5E4, 0x50 bytes. }

procedure debug_sym_dmp_$finalize;
begin
  if cargs_$options.db >= 2 then begin
    mrh_$release_all(locs_heap);
    mrh_$release_all(fixup_heap);
    pds_$finalize;
  end;
  mrh_$release_all(block_heap);
end;
