{ unix_objmod - UNIX_OBJMOD, the COFF object module writer: the file and
  optional headers, a section header for each code and data section, a
  common, the transfer vectors (.aptv), the exception and unwind tables,
  the compressed initializations (.rwdi), the debugging sections
  (.lines, .symbols, .blocks), .sri, .mir and .inlib; the initialized
  data (gathered in a 1000000-byte buffer and written in blocks with
  10-byte directives, or written straight into the mapped object file),
  the address constants and entry control blocks in them, the fixups and
  relocations, the line numbers and the string table.  The symbols are
  coff_syms's (number_coff_syms, coff_sym_dmp); the code outbin's
  (outcode) or, in cc.a88k, bin's.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x099388  0x09AD68  write_byte_to_temp_string_table
    0x099456  0x09AE36  has_ecb
    0x09949A  0x09AE7A  target_magic
    0x0994EC  0x09AECC  get_reloc_symndx
    0x09975A  0x09B13A  store_fixup_info
    0x0997DE  0x09B1BE  add_reloc
    0x09988A  0x09B26A  store_rel_info
    0x09991C  0x09B2FC  add_to_section_header
    0x09998A  0x09B36A  dump_data
    0x099B62  0x09B542  emit_8
    0x099C04  0x09B5E4  emit_16
    0x099C46  0x09B626  emit_32
    0x099C9E  0x09B67E  string_table
    0x099D06  0x09B6E6  unix_put_obj_name
    0x099E50  0x09B830  init_data (in unix_obj_gen)
    0x099EB6  0x09B896  emit_tree_node_const (in unix_obj_gen)
    0x09A27C  0x09BC5C  emit_data (in unix_obj_gen)
    0x09A348  0x09BD28  emit_constant (in unix_obj_gen)
    0x09A60C  0x09BFEC  find_global_id (in unix_obj_gen)
    0x09A668  0x09C048  emit_abs_addr_con (in unix_obj_gen)
    0x09AA82  0x09C462  emit_addr_con (in unix_obj_gen)
    0x09B306  0x09CCE6  emit_ecb (in unix_obj_gen)
    0x09B972  0x09D352  create_global_reference (in unix_obj_gen)
    0x09BB40  0x09D520  write_transfer_vectors (in unix_obj_gen)
    0x09BD26  0x09D706  get_load_addr (in unix_obj_gen)
    0x09BD6C  0x09D74C  get_section_id (in unix_obj_gen)
    0x09BE1E  0x09D7FE  gen_data_relocs (in unix_obj_gen)
    0x09BED0  0x09D8B0  gen_proc_relocs (in unix_obj_gen)
    0x09C51E  0x09DEFE  determine_section_headers_size (in unix_obj_gen)
    0x09C614  0x09DFF4  qsort (in sort_data_init_thread)
    0x09C7CE  0x09E1AE  ddisp (in sort_data_init_thread)
    0x09C8AC  0x09E28C  adjust_head_and_tail (in sort_data_init_thread)
    0x09C8D6  0x09E2B6  link_and_update_offset (in sort_data_init_thread)
    0x09C95A  0x09E33A  sort_data_init_thread (in dump_data_init_thread)
    0x09CC02  0x09E5E2  dump_data_init_thread (in data_sections)
    0x09CE9E  0x09E87E  align_data_position (in data_sections)
    0x09CED8  0x09E8B8  data_sections (in unix_obj_gen)
    0x09D426  0x09EE06  emit_rel (in unix_obj_gen)
    0x09D4A8  0x09EE88  line_numbers (in unix_obj_gen)
    0x09D520  0x09EF00  change_name_lower_case (in unix_obj_gen)
    0x09D598  0x09EF78  output_misc_sections (in unix_obj_gen)
    0x09DD42  0x09F722  create_tv_reloc_recs (in unix_obj_gen)
    0x09DDFE  0x09F7DE  output_data_info (in unix_obj_gen)
    0x09F0DA  0x0A0ABA  add_exception_addr_con_tuple (in unix_obj_gen)
    0x09F128  0x0A0B08  unix_obj_gen
    0x09F952  0x0A1332  unix_obj_init
    A5 0x1A0314 (cc.m68k), 0x320384 (cc.a88k): the module's data,
    0x121D6C bytes (to add_node's A5), laid out:
      +0x0     two tables of 4 longwords indexed by +0x5DD4 (1 or 2): the
               data's alignment and the code's base (both 0, 16#40000,
               16#80000; the fourth not initialized)
      +0x20    the externals (common blocks, routines): 2048 entries of
               10 bytes (find_global_id, create_global_reference)
      +0x5020  the kind 208 names (uobj_local_names)
      +0x5C20  the scalars, to +0x5E23 (+0x5DD0 and +0x5E16 the front
               end's)
      +0x5E24  the data buffer, 1000000 bytes (cc.m68k 0x1A6138,
               addressed absolutely)
      +0xFA064 the transfer vectors' names (uobj_global_names)
      +0xFAC64 the string table being built, 160008 bytes (0x29AF78;
               addressed absolutely as 0x29F198 - 16928 + the index)
    The cells other units read are declared in unix_objmod.ins.pas; the
    unit's own are named here by use (their offsets in the comments).

  Every module-level routine but write_byte_to_temp_string_table and
  get_reloc_symndx (no A5 load: internal) is global.  The rest is nested
  in unix_obj_gen (each running on its A5); sort_data_init_thread and
  link_and_update_offset take their parent's frame from the dynamic link
  (docs/rev889-patterns.md 25), qsort and adjust_head_and_tail get it in
  A1.  The nodes' fields are read through il.ins.pas's views by offset.

  Not known from the original:
  - the names of the module's variables, the locals and most
    parameters; the types of the records built in the object file;
  - the source order of the nested routines (emit_abs_addr_con and
    emit_addr_con are declared forward: docs/dpc-gaps.md 9). }
module unix_objmod;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/time.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/final.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'lang/lang/source/unix_objmod.ins.pas';
%include 'us/us/ins/name.ins.pas';
%include 'us/us/ins/streams.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include 'us/us/ins/loader.ins.pas';
%include '/sys/ins/loader.ins.pas';
%include 'us/us/ins/fault.ins.pas';
%include 'us/us/ins/unix_sig.ins.pas';
%include 'us/us/ins/ev.ins.pas';
%include 'us/us/ins/c.ins.pas';
%include 'us/us/ins/pgm.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include 'us/us/ins/proc2.ins.pas';
%include 'us/us/ins/unix_resource.ins.pas';
%include 'us/us/ins/pm.ins.pas';
%include '/sys/ins/pm.ins.pas';
%include 'us/us/ins/acl.ins.pas';
%include 'us/us/ins/strl.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'us/us/ins/time.ins.pas';
%include 'lang/lang/source/gen_debug.ins.pas';
%include 'lang/lang/source/gen_unwind.ins.pas';
%include 'us/us/sys/ins/unwind.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/common/source/spos.pvt.pas';

{ Foreign routines and cells the unit uses that none of its inserts
  declares (docs/questions.md): }

{ DUMP_NAMELIST - fe_cc_hooks_to_backend.pas 0x067378, an empty
  procedure (unix_obj_gen calls it). }
procedure dump_namelist; extern;

{ DBL_TO_REAL - kfold.pas 0x0ACDC2: the double constant p (its +12)
  made single, an overflow reported with line; p by value, line a word
  by value, the single in D0. }
function dbl_to_real(
    p: il_$node_ptr_t;
    line: integer): real; options(val_param); extern;

{ TIME - the C library's time(2), through the transfer vector: a nil
  pointer pushed, the seconds in D0. }
function time(
    t: univ_ptr): integer32; options(val_param); extern;

{ KG_$LOOKUP - the loader's known-global lookup: a 32-character blank
  padded name by address, the global's address (nil when unknown) in
  A0. }
function kg_$lookup(
    in name: univ obj_$name_t): univ_ptr; extern;

var
  { emit.pas's data (cc.m68k A5 0x2CE6A8) +0x108..+0x11B: the code's
    size (+0x108), the code's object offset (+0x114); unix_obj_init
    clears +0x108, +0x10C, +0x110 and +0x118 through one base address. }
  emit_108: extern record
    e108: integer32;
    e10c: integer32;
    e110: integer32;
    e114: integer32;
    e118: integer32;
  end;

  { +0x5DD0 and +0x5E16: the bits #pragma HP_STANDARD n sets and a
    #systype whose first version number is 2 (c_lex_pp, c_main).
    lang/c_compiler/source/c_globals.ins.pas declares them for the
    front end; this unit opens neither it nor anything that could
    declare them (runbackend opens c_globals.ins.pas with
    unix_objmod.ins.pas, so the insert cannot). }
  uobj_hp_standard: extern integer32;
  uobj_systype_2: extern boolean;

type
  { A fixup (store_fixup_info; 16 bytes from PAS_$NEW): value plus the
    base of sect to be stored at offset in the object file. }
  unix_objmod_$fixup_ptr_t = ^unix_objmod_$fixup_t;
  unix_objmod_$fixup_t = record
    sect: il_$node_ptr_t;               { +0 }
    offset: integer32;                  { +4 }
    value: integer32;                   { +8 }
    next: unix_objmod_$fixup_ptr_t;     { +12 }
  end;

  unix_objmod_$bytes_t = array [1..1000000] of char;
  unix_objmod_$bytes_ptr_t = ^unix_objmod_$bytes_t;
  unix_objmod_$words_ptr_t = ^array [1..16384] of integer;
  unix_objmod_$long_ptr_t = ^integer32;
  unix_objmod_$word_ptr_t = ^integer;

  { A data directive of the compressed form (10 bytes: kind 0, the
    address, the count of bytes that follow; or 6: kind 1, the repeat
    count of the block before). }
  unix_objmod_$directive_ptr_t = ^unix_objmod_$directive_t;
  unix_objmod_$directive_t = record
    kind: integer;                      { +0 }
    addr: integer32;                    { +2 }
    count: integer32;                   { +6 }
  end;

  { A word or longword taken apart into its bytes, high first. }
  unix_objmod_$word_bytes_t = record
    case integer of
      1: (w: integer);
      2: (c: array [1..2] of char);
  end;
  unix_objmod_$long_bytes_t = record
    case integer of
      1: (l: integer32);
      2: (c: array [1..4] of char);
  end;

  { An address constant within a record or array constant (kind 176's
    list at +4): where it is and how long the bytes before run. }
  unix_objmod_$rec_addr_ptr_t = ^unix_objmod_$rec_addr_t;
  unix_objmod_$rec_addr_t = record
    next: unix_objmod_$rec_addr_ptr_t;  { +0 }
    offset: integer32;                  { +4 }
    len: integer32;                     { +8 }
    node: il_$node_ptr_t;               { +12 }
  end;

  { A transfer vector's `jmp abs.l' (6 bytes). }
  unix_objmod_$jmp_ptr_t = ^unix_objmod_$jmp_t;
  unix_objmod_$jmp_t = record
    op: integer;                        { +0: 0x4EF9 }
    addr: integer32;                    { +2 }
  end;

  { An initialization and its displacement (sort_data_init_thread's
    array, 8 bytes each). }
  unix_objmod_$pair_t = record
    elem: il_$node_ptr_t;
    disp: integer32;
  end;
  unix_objmod_$pairs_ptr_t = ^array [1..65535] of unix_objmod_$pair_t;

  { A .sri entry (8 bytes): kind and rule, then a value or a system
    type's two numbers. }
  unix_objmod_$sri_ptr_t = ^unix_objmod_$sri_t;
  unix_objmod_$sri_t = record
    kind_rule: integer32;               { +0 }
    case integer of
      1: (value: integer32);            { +4 }
      2: (major: integer;               { +4 }
          minor: integer);              { +6 }
  end;

  { A .mir record: the maker's (14 bytes) or the module name's (8). }
  unix_objmod_$mir_ptr_t = ^unix_objmod_$mir_t;
  unix_objmod_$mir_t = record
    kind_size: integer32;               { +0 }
    case integer of
      1: (version: integer;             { +4 }
          creation_time: integer32;     { +6 }
          name_offset: integer32);      { +10 }
      2: (module_name_offset: integer32);  { +4 }
  end;

  { An .inlib entry (16 bytes). }
  unix_objmod_$inlib_ptr_t = ^unix_objmod_$inlib_t;
  unix_objmod_$inlib_t = record
    unused_0: integer32;
    unused_4: integer32;
    unused_8: integer32;
    name_ptr: integer32;                { +12: in the string table }
  end;

  { An external's entry (10 bytes): its name and block, its symbol. }
  unix_objmod_$common_t = record
    name: univ_ptr;                     { +0 }
    id: integer;                        { +4 }
    block: univ_ptr;                    { +6 }
  end;

define
  uobj_local_names,
  uobj_lines_addr,
  uobj_unwind_addr,
  uobj_symbols_addr,
  uobj_exc_symndx,
  uobj_5d30,
  uobj_5d34,
  uobj_5d38,
  uobj_5d3c,
  uobj_5d40,
  uobj_direct_index,
  uobj_direct_left,
  uobj_local_name_count,
  uobj_global_name_count,
  uobj_symptr,
  uobj_nlnnos,
  uobj_lnno_start,
  uobj_5d6c,
  uobj_ntvs,
  uobj_addr_bias,
  uobj_code_scnhdr_pos,
  uobj_lnno_scnhdr_pos,
  uobj_scnhdr_pos,
  uobj_lnno_list,
  uobj_lnno_head,
  uobj_sym_sect,
  uobj_reloc_tail,
  uobj_reloc_head,
  uobj_obj_map,
  uobj_code_size,
  uobj_reloc_scnhdr_pos,
  uobj_direct_base,
  uobj_obj_pos,
  uobj_pad_from,
  uobj_sect_start,
  uobj_syms_size,
  uobj_nsyms_coff,
  uobj_hp_standard,
  uobj_exception_sect,
  uobj_inlib_sect,
  uobj_lines_sect,
  uobj_rwdi_sect,
  uobj_mir_sect,
  uobj_sri_sect,
  uobj_unwind_sect,
  uobj_symbols_sect,
  uobj_blocks_sect,
  uobj_bss_sect,
  uobj_aptv_sect,
  uobj_nsects,
  uobj_nsyms,
  uobj_headers_counted,
  uobj_systype_2,
  uobj_global_names;

var
  target_aligns: array [0..3] of integer32 := [0, 16#40000, 16#80000];  { +0x0 }
  target_bases: array [0..3] of integer32 := [0, 16#40000, 16#80000];   { +0x10 }
  symbols_tail: univ_ptr;               { +0x5C2C }
  symbols_sections: il_$node_ptr_t;     { +0x5C30: debug_sym_dmp's
                                          symbols sections (+8 next) }
  exc_tuple: il_$node_ptr_t;            { +0x5C34 }
  exc_handler: il_$node_ptr_t;          { +0x5C38 }
  exc_data: il_$node_ptr_t;             { +0x5C3C: the exception data's
                                          section (il_110) }
  exc_text: il_$node_ptr_t;             { +0x5C40: a code section node
                                          for the exception table }
  npieces: integer32;                   { +0x5C44 }
  raw_data_start: integer32;            { +0x5C48 }
  data_5c4c: integer32;                 { +0x5C4C: the section's address }
  data_5c50: integer32;                 { +0x5C50: il_114's .bss size }
  data_5c54: integer32;                 { +0x5C54: the space of the
                                          sections without data }
  nrelocs_5c58: integer32;              { +0x5C58 }
  block_node: il_$node_ptr_t;           { +0x5C5C }
  block_sect: il_$node_ptr_t;           { +0x5C60: the .rwdi section's
                                          name, its relocations' section }
  block_start: integer32;               { +0x5C64 }
  nblock_relocs: integer32;             { +0x5C68 }
  data_5c6c: integer32;                 { +0x5C6C: the space of the
                                          sections of no contents }
  scnhdr_base: integer32;               { +0x5C70 }
  first_sym: integer32;                 { +0x5C74 }
  data_sym: integer32;                  { +0x5C78 }
  data_section: il_$node_ptr_t;         { +0x5C7C: the section whose
                                          data are emitted }
  sect_cursor: il_$node_ptr_t;          { +0x5C80 }
  nrels: unix_objmod_$count_t;          { +0x5C88 }
  obj_start: integer32;                 { +0x5C90 }
  data_start: integer32;                { +0x5C94 }
  data_5c98: integer32;                 { +0x5C98: the optional
                                          header's bsize }
  data_5c9c: integer32;                 { +0x5C9C: its dsize }
  filehdr_pos: integer32;               { +0x5CA0 }
  aouthdr_pos: integer32;               { +0x5CA4 }
  sect_from: integer32;                 { +0x5CA8 }
  nscns: unix_objmod_$count_t;          { +0x5CAC }
  ndirectives: integer32;               { +0x5CB4 }
  tv: il_$node_ptr_t;                   { +0x5CB8 }
  systype_value: ev_$string_ptr_t;      { +0x5CC4 }
  data_addr: integer32;                 { +0x5CC8: the block's address }
  data_repeat: integer32;               { +0x5CCC }
  repeat_node: il_$node_ptr_t;          { +0x5CD0 }
  ecb_cursor: il_$node_ptr_t;           { +0x5CDC }
  main_routine: il_$node_ptr_t;         { +0x5CE0 }
  data_cursor: il_$node_ptr_t;          { +0x5CE4 }
  global_index: integer32;              { +0x5CE8: get_reloc_symndx's
                                          and unix_obj_gen's loop index }
  strtab_cursor: integer32;             { +0x5CEC }
  tv_start: integer32;                  { +0x5CF0 }
  strtab_pos: integer32;                { +0x5CF4 }
  rwdi_scnhdr_pos: integer32;           { +0x5CF8 }
  inlib_start: integer32;               { +0x5D00 }
  mir_start: integer32;                 { +0x5D04 }
  sri_start: integer32;                 { +0x5D08 }
  symbols_scnhdr_pos: integer32;        { +0x5D0C }
  lnno_ptr: integer32;                  { +0x5D10 }
  scnhdr_map: univ_ptr;                 { +0x5D14 }
  obj_map_5d18: univ_ptr;               { +0x5D18 }
  scnhdr_start: integer32;              { +0x5D1C }
  fixup_tail: unix_objmod_$fixup_ptr_t; { +0x5D24 }
  fixup_head: unix_objmod_$fixup_ptr_t; { +0x5D28 }
  nreloc_5d4c: integer32;               { +0x5D4C: the unwind section's
                                          relocations }
  nreloc_5d50: integer32;               { +0x5D50: the symbols' }
  code_addr: integer32;                 { +0x5D5C }
  main_symbols: il_$node_ptr_t;         { +0x5D90 }
  sect_5d94: il_$node_ptr_t;            { +0x5D94: the unwind section
                                          (6156 bytes from PAS_$NEW) }
  rel_ptr: integer32;                   { +0x5DAC }
  data_count: linteger;                 { +0x5DB0: bytes in the buffer }
  temp_string_count: integer32;         { +0x5DCC }
  target_index: integer;                { +0x5DD4 }
  data_sect: integer;                   { +0x5DD6 }
  hp_bits: integer;                     { +0x5DD8 }
  systype_len: integer;                 { +0x5DDA }
  systype_minor: integer;               { +0x5DDC }
  systype_major: integer;               { +0x5DDE }
  ncommons: integer;                    { +0x5DE0 }
  nsri: integer;                        { +0x5DE8 }
  symbols_symndx: integer;              { +0x5DEA }
  block_reloc_made: boolean;            { +0x5E06 }
  compressed: boolean;                  { +0x5E08 }
  patched: boolean;                     { +0x5E0A }
  no_entry: boolean;                    { +0x5E0C }
  direct: boolean;                      { +0x5E0E: data straight into
                                          the object file }
  add_underscore: boolean;              { +0x5E12 }
  underscore_names: boolean;            { +0x5E14 }
  sect_size: integer32;                 { +0x5E1C }
  lnno_map: univ_ptr;                   { +0x5E20 }
  { The tables, after the scalars (dpc refuses a scalar beyond 32K). }
  commons: array [1..2048] of unix_objmod_$common_t;  { +0x20 }
  data_buffer: unix_objmod_$bytes_t;    { +0x5E24 }
  temp_string_table: array [0..160007] of char;  { +0xFAC64 }

{ write_byte_to_temp_string_table - c onto the string table being built.

  0x099388, 0x50 bytes (no A5: internal).  c a byte by value.  More than
  160000 bytes (`cmpi.l #160000; ble', signed) is reported
  (cgerr_no_source(24, strtk(...)), the message's 126 characters after
  the routine); then the byte is stored at the count and the count
  incremented.  The table is addressed absolutely (0x29F198 - 16928 +
  the count: the element of index 0 at 0x29AF78).

  Not known from the original:
  - the parameter's name. }

procedure write_byte_to_temp_string_table(
    c: char); options(val_param); internal;
begin
  if temp_string_count > 160000 then
    cgerr_no_source(24, integer32(strtk(
      'Variable namespace table exhausted (too many variables, or names too long, or both); try breaking program into smaller pieces ',
      126)));
  temp_string_table[temp_string_count] := c;
  temp_string_count := temp_string_count + 1;
end;

{ has_ecb - whether the routine of node p has an entry control block.

  0x099456, 0x44 bytes.  For a kind 167 node its +148 is taken instead.
  False when -AC/-ABS (flags_286 element 7, `btst #2' of +0x287) is set,
  or when target_properties +0x7F is set and the routine's +375 bit 3
  is clear; else true (`clr.b D0' / `st D0').

  Not known from the original:
  - the names. }

function has_ecb(
    p: il_$node_ptr_t): boolean; options(val_param);
begin
  if p^.kind = 167 then
    p := p^.xp[37];
  if 7 in cargs_$options.flags_286 then
    has_ecb := false
  else if target_properties.p_7f and ((ord(p^.xc[375]) & 8) = 0) then
    has_ecb := false
  else
    has_ecb := true;
end;

{ target_magic - the COFF magic number of the target.

  0x09949A, 0x52 bytes: a jump table on target_properties +0x10 (0..3,
  `cmpi.l #4; bcc' leaving D0 as it is for anything else): 0x197,
  0x196, 0x195, 0x194.

  Not known from the original:
  - how the out-of-range case was written (the image returns
    target_properties +0x10 itself). }

function target_magic: integer32;
begin
  case target_properties.p_10 of
    0: target_magic := 16#197;
    1: target_magic := 16#196;
    2: target_magic := 16#195;
    3: target_magic := 16#194;
    otherwise target_magic := target_properties.p_10;
  end;
end;

{ get_reloc_symndx - the COFF symbol index a relocation against node p
  uses; dflt for the labels.

  0x0994EC, 0x252 bytes (no A5: internal).  By p's kind: 167, 108, 107
  the word at +266; 192 and 194 the index of their +8; 183 +44; 182
  +64; 111 +32; 109 (a variable) +72 in [1, 7] (`btst D2' of 130) its
  block's (+20, +192) +44, else +76; 110 +66; 159 (a transfer vector
  name) the +4 of the first of the global names (0x29A378: 12-byte
  entries, count +0x5D58) whose name equals p's (strl_$eq of the +8
  characters at +12 + 2 * +10, for both), the loop's index the module
  variable +0x5CE8; 208 the +4 of the entry of the A5 table +0x5020
  (count +0x5D54) whose +0 is p; 184 its +4's +64; 215, 214, 144 dflt;
  163 (an address constant) the index of its +8 with, for a label
  target (144, 214, 215), its +24's +64 as dflt (else 0).  Any other
  kind is reported (cgerr_no_source(28, strtk('NO COFF SYMNO FOR THIS
  NODE ', 28))) and the result is not set (the image returns D2 as it
  stands).

  Not known from the original:
  - the names; the kinds' names. }

function get_reloc_symndx(
    p: il_$node_ptr_t;
    dflt: integer32): integer32; options(val_param); internal;
var
  r: integer32;
  q: il_$node_ptr_t;
begin
  case p^.kind of
    167, 108, 107:
      r := p^.xw[133];
    192, 194:
      r := get_reloc_symndx(p^.xp[2], 0);
    183:
      r := p^.xw[22];
    182:
      r := p^.xw[32];
    111:
      r := p^.xw[16];
    109:
      if p^.xw[36] in [1, 7] then
        r := p^.xp[5]^.xp[48]^.xw[22]
      else
        r := p^.xw[38];
    110:
      r := p^.xw[33];
    159:
      for global_index := 1 to uobj_global_name_count.l do begin
        q := uobj_global_names[global_index].name;
        if strl_$eq(p^.xc[12 + 2 * p^.xw[5]], p^.xw[4],
                    q^.xc[12 + 2 * q^.xw[5]], q^.xw[4]) then
          r := uobj_global_names[global_index].symndx;
      end;
    208:
      for global_index := 1 to uobj_local_name_count.l do
        if uobj_local_names[global_index].name = p then
          r := uobj_local_names[global_index].symndx;
    184:
      r := p^.xp[1]^.xw[32];
    215, 214, 144:
      r := dflt;
    163: begin
      q := p^.xp[2];
      if (q^.kind = 144) or (q^.kind = 214) or (q^.kind = 215) then
        r := get_reloc_symndx(q, p^.xp[6]^.xw[32])
      else
        r := get_reloc_symndx(q, 0);
    end;
    otherwise
      cgerr_no_source(28, integer32(strtk('NO COFF SYMNO FOR THIS NODE ', 28)));
  end;
  get_reloc_symndx := r;
end;
{ store_fixup_info - note a fixup: value to be stored at offset of
  sect when the module is finished.

  0x09975A, 0x84 bytes.  The three by address; a 16-byte record from
  PAS_$NEW (nil reported, cgerr_no_source(9, 0)) appended to the list
  +0x5D28 (head) / +0x5D24 (tail).

  Not known from the original:
  - the names. }

procedure store_fixup_info(
    in sect: il_$node_ptr_t;
    in offset: integer32;
    in value: integer32);
var
  f: unix_objmod_$fixup_ptr_t;
begin
  pas_$new(f, 16);
  if f = nil then
    cgerr_no_source(9, 0);
  f^.sect := sect;
  f^.offset := offset;
  f^.value := value;
  f^.next := nil;
  if fixup_head = nil then begin
    fixup_head := f;
    fixup_tail := fixup_head;
  end
  else begin
    fixup_tail^.next := f;
    fixup_tail := fixup_tail^.next;
  end;
end;

{ add_reloc - note a relocation of the longword at vaddr of sect
  against symbol symndx.

  0x0997DE, 0xAC bytes.  All four by value; a 20-byte record from
  PAS_$NEW appended to the list +0x5D9C (head) / +0x5D98 (tail); the
  count of sect's relocations grows: +0x5D50 for the section +0x5D8C,
  +0x5D4C for +0x5D94, else +68 of a code section (kind 182).

  Not known from the original:
  - the names; what the fourth parameter is (gen_unwind passes 0 or a
    longword; it is only stored). }

procedure add_reloc(
    vaddr: integer32;
    sect: il_$node_ptr_t;
    symndx: integer32;
    target: univ_ptr); options(val_param);
var
  r: unix_objmod_$reloc_ptr_t;
begin
  pas_$new(r, 20);
  if r = nil then
    cgerr_no_source(9, 0);
  r^.sect := sect;
  r^.vaddr := vaddr;
  r^.symndx := symndx;
  r^.target := target;
  r^.next := nil;
  if uobj_reloc_head = nil then begin
    uobj_reloc_head := r;
    uobj_reloc_tail := uobj_reloc_head;
  end
  else begin
    uobj_reloc_tail^.next := r;
    uobj_reloc_tail := uobj_reloc_tail^.next;
  end;
  if sect = uobj_sym_sect then
    nreloc_5d50 := nreloc_5d50 + 1
  else if sect = sect_5d94 then
    nreloc_5d4c := nreloc_5d4c + 1
  else if sect^.kind = 182 then
    sect^.xl[17] := sect^.xl[17] + 1;
end;

{ store_rel_info - a relocation at offset of the data being emitted
  for sect against symndx.

  0x09988A, 0x92 bytes.  The three by address.  In a compressed data
  section (+0x5E08) the block's own relocation (against +0x5C5C, at
  +0x5C50 + +0x5C54 + +0x5C64 + 2) is made first, once a block
  (+0x5E06), unless -NCOMPRESS; then the relocation at +0x5C50 +
  +0x5C54 + offset, and the count +0x5C68 grows by one for each
  (the second only in a compressed section).

  Not known from the original:
  - the names. }

procedure store_rel_info(
    in sect: il_$node_ptr_t;
    in offset: integer32;
    in symndx: integer32);
begin
  if compressed and not block_reloc_made and
     not cargs_$options.ncompress then begin
    add_reloc(data_5c50 + data_5c54 + block_start + 2, block_sect,
              get_reloc_symndx(block_node, 0), nil);
    nblock_relocs := nblock_relocs + 1;
    block_reloc_made := true;
  end;
  add_reloc(data_5c50 + data_5c54 + offset, sect, symndx, nil);
  if compressed then
    nblock_relocs := nblock_relocs + 1;
end;

{ add_to_section_header - set where a section's relocations (for_relocs)
  or line numbers are and how many.

  0x09991C, 0x6E bytes.  The three by address.  The section header (40
  bytes) at +0x5DA8 (relocations: s_relptr, s_nreloc) or +0x5D7C (line
  numbers: s_lnnoptr, s_nlnno) is mapped with putobj, set and freed.

  Not known from the original:
  - the names. }

procedure add_to_section_header(
    in ptr: integer32;
    in for_relocs: boolean;
    in n: integer);
var
  h: unix_objmod_$scnhdr_ptr_t;
begin
  if for_relocs then begin
    h := putobj(uobj_reloc_scnhdr_pos, 40);
    h^.s_relptr := ptr;
    h^.s_nreloc := n;
  end
  else begin
    h := putobj(uobj_lnno_scnhdr_pos, 40);
    h^.s_lnnoptr := ptr;
    h^.s_nlnno := n;
  end;
  freeobj(h);
end;

{ dump_data - write the data bytes gathered in the buffer to the object
  file.

  0x09998A, 0x1D8 bytes.  When there are bytes: in a compressed section
  the block's relocation unless made or -NCOMPRESS (as store_rel_info);
  a 10-byte directive (a word 0, the address +0x5CC8 + +0x5C4C, the
  count) at the object offset +0x5DB8; the bytes copied in pieces of
  163808 (`for' loops of the byte copy, the buffer's index kept across
  them in D2); the offset made even (`btst #0' of its low byte); a
  repeat count other than 1 (+0x5CCC, `cmpi.l #1; ble') as a 6-byte
  directive (word 1, the count; +0x5CB4 counts them); the address
  advanced by count times repeat (M$MIS$LLL).  Then the repeat is 1, no
  block relocation made, and the block starts at the object offset
  (+0x5C64).

  Not known from the original:
  - the locals' names. }

procedure dump_data;
var
  d: unix_objmod_$directive_ptr_t;
  b: unix_objmod_$bytes_ptr_t;
  left: integer32;
  j: integer32;
  i: integer32;
begin
  if data_count <> 0 then begin
    if not block_reloc_made and not cargs_$options.ncompress then begin
      block_reloc_made := true;
      add_reloc(data_5c50 + data_5c54 + block_start + 2, block_sect,
                get_reloc_symndx(block_node, 0), nil);
      nblock_relocs := nblock_relocs + 1;
    end;
    d := putobj(uobj_obj_pos, 10);
    uobj_obj_map := d;
    d^.kind := 0;
    d^.addr := data_addr + data_5c4c;
    d^.count := data_count;
    freeobj(uobj_obj_map);
    uobj_obj_pos := uobj_obj_pos + 10;
    left := data_count;
    j := 1;
    while left > 163808 do begin
      b := putobj(uobj_obj_pos, 163808);
      uobj_obj_map := b;
      for i := 1 to 163808 do begin
        b^[i] := data_buffer[j];
        j := j + 1;
      end;
      freeobj(uobj_obj_map);
      left := left - 163808;
      uobj_obj_pos := uobj_obj_pos + 163808;
    end;
    if left <> 0 then begin
      b := putobj(uobj_obj_pos, left);
      uobj_obj_map := b;
      for i := 1 to left do begin
        b^[i] := data_buffer[j];
        j := j + 1;
      end;
      freeobj(uobj_obj_map);
      uobj_obj_pos := uobj_obj_pos + left;
    end;
    if odd(uobj_obj_pos) then
      uobj_obj_pos := uobj_obj_pos + 1;
    if data_repeat > 1 then begin
      d := putobj(uobj_obj_pos, 6);
      uobj_obj_map := d;
      ndirectives := ndirectives + 1;
      d^.kind := 1;
      d^.addr := data_repeat;
      uobj_obj_pos := uobj_obj_pos + 6;
      freeobj(uobj_obj_map);
    end;
    data_addr := data_addr + data_repeat * data_count;
    data_count := 0;
  end;
  data_repeat := 1;
  block_reloc_made := false;
  block_start := uobj_obj_pos;
end;

{ emit_8 - one byte of data.

  0x099B62, 0x0A2 bytes.  b by address.  Into the buffer (dump_data
  first when it holds 999999 or more, `bls' unsigned) unless the data
  go straight to the object file (+0x5E0E): then into the mapped piece
  at +0x5D44, the next piece of 163808 bytes mapped when it is full
  (+0x5C44 counts the pieces, +0x5DB4 its object offset, +0x5D48 what
  is left; the piece mapped is at most what is left).

  Not known from the original:
  - the names. }

procedure emit_8(
    in b: char);
var
  c: char;
begin
  c := b;
  if not direct then begin
    if data_count > 999999 then
      dump_data;
    data_count := data_count + 1;
    data_buffer[data_count] := c;
  end
  else begin
    while uobj_direct_index >= 163808 do begin
      freeobj(uobj_obj_map);
      npieces := npieces + 1;
      uobj_direct_index := uobj_direct_index - 163808;
      uobj_direct_base := uobj_direct_base + 163808;
      uobj_direct_left := uobj_direct_left - 163808;
      if 163808 < uobj_direct_left then
        uobj_obj_map := putobj(uobj_direct_base, 163808)
      else
        uobj_obj_map := putobj(uobj_direct_base, uobj_direct_left);
    end;
    unix_objmod_$bytes_ptr_t(uobj_obj_map)^[uobj_direct_index + 1] := c;
    uobj_direct_index := uobj_direct_index + 1;
  end;
end;

{ emit_16 - a word of data, high byte first.

  0x099C04, 0x42 bytes.  w by address, copied to a frame word whose two
  bytes are passed to emit_8; dump_data first when the buffer holds
  more than 999998 (`bls').

  Not known from the original:
  - the names. }

procedure emit_16(
    in w: integer);
var
  t: unix_objmod_$word_bytes_t;
begin
  if data_count > 999998 then
    dump_data;
  t.w := w;
  emit_8(t.c[1]);
  emit_8(t.c[2]);
end;

{ emit_32 - a longword of data, high byte first.

  0x099C46, 0x58 bytes: as emit_16 (dump_data past 999996). }

procedure emit_32(
    in l: integer32);
var
  t: unix_objmod_$long_bytes_t;
begin
  if data_count > 999996 then
    dump_data;
  t.l := l;
  emit_8(t.c[1]);
  emit_8(t.c[2]);
  emit_8(t.c[3]);
  emit_8(t.c[4]);
end;

{ string_table - name refers to the string table, where id's characters
  are added (with a '_' when +0x5E12 says so) and a NUL.

  0x099C9E, 0x68 bytes.  name by address (zeroes 0, the offset the
  table's count + 4: the table's length word comes first in the file),
  id by address.

  Not known from the original:
  - the names. }

procedure string_table(
    out name: unix_objmod_$name_t;
    in id: il_$node_ptr_t);
var
  i: integer;
begin
  name.zeroes := 0;
  name.offset := temp_string_count + 4;
  for i := 1 to id^.idnt_len do
    write_byte_to_temp_string_table(id^.idnt_name[i]);
  if add_underscore then
    write_byte_to_temp_string_table('_');
  write_byte_to_temp_string_table(chr(0));
end;

{ unix_put_obj_name - the COFF name of the identifier id: in name's
  eight characters, NUL padded, or in the string table.

  0x099D06, 0x14A bytes.  name by address (the 8 bytes), id a pointer
  by value.  The identifier entry of id's characters (idntk(76, ...))
  is folded to lower case unless -U (`btst #6' of +0x28A), 'A'..'Z'
  unsigned.  With +0x5E14 and -UC a '_' is to be added (+0x5E12) when
  the name has no '$' (a loop left by `exit') and neither ends (at
  id's length) nor begins with '_'.  A name of more than 8 characters
  (`bhi', unsigned), or of 8 that gets the '_', goes to the string
  table (string_table, the entry passed through a frame slot); else the
  characters, the '_' and NULs to the eighth.  +0x5E12 is cleared.

  Not known from the original:
  - the names. }

procedure unix_put_obj_name(
    out name: univ unix_objmod_$name_t;
    id: il_$node_ptr_t); options(val_param);
var
  n: il_$node_ptr_t;
  i: integer32;
  c: char;
  found: boolean;
  target: integer;
begin
  n := idntk(76, id^.idnt_name, id^.idnt_len);
  if not cargs_$options.u then
    for i := 1 to n^.idnt_len do begin
      c := id^.idnt_name[i];
      if (c >= 'A') and (c <= 'Z') then
        n^.idnt_name[i] := chr(ord(c) + 32);
    end;
  if underscore_names and cargs_$options.uc then begin
    found := false;
    for i := 1 to n^.idnt_len do
      if n^.idnt_name[i] = '$' then begin
        found := true;
        exit;
      end;
    if not found then
      if (n^.idnt_name[id^.idnt_len] <> '_') and
         (n^.idnt_name[1] <> '_') then
        add_underscore := true;
  end;
  if (n^.idnt_len > 8) or (add_underscore and (n^.idnt_len = 8)) then
    string_table(name, n)
  else begin
    target := 0;
    for i := 1 to n^.idnt_len do
      name.chars[i] := n^.idnt_name[i];
    if add_underscore then begin
      name.chars[n^.idnt_len + 1] := '_';
      target := 1;
    end;
    for i := target + n^.idnt_len + 1 to 8 do
      name.chars[i] := chr(0);
  end;
  add_underscore := false;
end;

{ unix_obj_gen - write the object module.

  0x09F128, 0x76E bytes (with the nested routines from 0x099E50).
  do_lex a procedure pointer by value.  With an exception table
  (il_13c; one code and one data section only, and il_138 set, else
  reported) a code section node (gspace32(92), kind 182) for it
  (+0x5C40), the data section (+0x5C3C), the tuple of address constants
  (+0x5C34) and the handler's (+0x5C38, form 2 of il_138).  The data
  sections' starts and sizes aligned to target_properties +0x90;
  dump_namelist; the target's index +0x5DD4 (2 for cpu element 6, else
  1); the headers' positions from +0x5C90 (file header, +20 the
  optional header, +44 the section headers); the counters cleared,
  the next symbol 1; debug_sym_dmp_$init under -DB; the unwind section
  record (PAS_$NEW, 6156) and under -DB a 4-byte symbols section;
  under -DBS/-DBA debug_sym_dmp_$create_symbols_sections; under -EXP
  (not target_properties +0x7F) io_release(0), io_release(1),
  spos_$capture_file_marks and do_lex.  The relocation counts of the
  sections cleared; the externals entered (create_global_reference):
  the address constants of form 2 or 4 in the data sections (their
  +22), the transfer vectors (counted in +0x5D70; +18), the external
  references (il_12c: commons only, else reported; +12), the absolute
  address constants' external routines and commons.  Then
  determine_section_headers_size, output_data_info,
  gen_unwind_$end_compilation with the tuple's and the handler's
  addresses, coff_sym_dmp, the string table (its length, then the bytes
  one putobj each, the loop's index the module variable +0x5CE8), the
  optional header (entry from il_184's routine, its +17C or +4 for kind
  106; magic 1; tsize, dsize, bsize, text and data start, the .sri and
  .inlib offsets, a zero version) and the file header (target_magic,
  the section count's low word, time(nil), the symbols, 44, flags 3, 1
  without il_114, 15 without -AC/-ABS), and set_obj_length.

  Not known from the original:
  - the names. }

procedure unix_obj_gen;
var
  t: il_$node_ptr_t;
  d: integer32;
  l: unix_objmod_$long_ptr_t;
  b: unix_objmod_$bytes_ptr_t;
  a: unix_objmod_$aouthdr_ptr_t;
  f: unix_objmod_$filehdr_ptr_t;
  k: integer;

  { init_data - the data of section sect start at addr.

    0x099E50, 0x66 bytes.  sect a word and addr a longword by value.
    The index in the piece mapped for direct output is addr less the
    pieces passed ((+0x5C44 - 1) * 163808, by shifts and adds).  Unless
    direct, the gathered data are written (dump_data) and a new block
    begun when the block's address is odd, the section differs
    (+0x5DD6) or addr does not follow the bytes gathered.

    Not known from the original:
    - the names. }

  procedure init_data(
      sect: integer;
      addr: integer32); options(val_param);
  begin
    uobj_direct_index := addr - (npieces - 1) * 163808;
    if not direct then
      if odd(data_addr) or (sect <> data_sect) or
         (data_addr + data_count <> addr) then begin
        dump_data;
        data_sect := sect;
        data_addr := addr;
      end;
  end;

  procedure emit_abs_addr_con(p: il_$node_ptr_t; offset: integer32); options(val_param); forward;

  procedure emit_addr_con(p: il_$node_ptr_t; offset: integer32); options(val_param); forward;

  { emit_tree_node_const - the longword of an address expression in
    initialized data: an address constant, or a variable's or address
    constant's address plus the offsets on the way.

    0x099EB6, 0x3AC bytes.  The offsets of the kind 147 nodes from p's
    +40 down their +24 are summed; a kind 146 over an address constant
    (163) or an absolute one (195) is emitted by emit_addr_con or
    emit_abs_addr_con.  A variable (109): its class +72 7 or 8 (its
    block's +192 section, offset +56, plus the section's +20 less its
    +16) or 1 or 4 (without +20); the longword emitted, a fixup of it
    (at the piece's index + its object offset - 4 when direct, else the
    object offset + the bytes gathered + 6: past the block's 10-byte
    directive) and a relocation against the variable.  An address
    constant (163) is looked for in the chains of the data sections
    (il_110, +4; each section's constants from +12, by +4 for an
    address constant, +116 for other nodes); found, its +16 less the
    section's +16, with the fixup and a relocation against the
    section's +44 symbol.  Each relocation counts in +0x5C58.  Other
    kinds are reported (cgerr_no_source(20, idntk(76, 'var_name' or
    'addr_con' or 'tree_node'))); after 'addr_con' the image goes on
    with the section pointer nil.

    Not known from the original:
    - the names; whether the search was written with a goto. }

  procedure emit_tree_node_const(
      p: il_$node_ptr_t); options(val_param);
  label
    found;
  var
    sum: integer32;
    t: il_$node_ptr_t;
    v: il_$node_ptr_t;
    s: il_$node_ptr_t;
    a: il_$node_ptr_t;
    sect: il_$node_ptr_t;
    value: integer32;
    off: integer32;
    sym: integer32;
  begin
    sum := 0;
    t := p^.xp[10];
    while t^.kind = 147 do begin
      sum := sum + t^.xl[8];
      t := t^.xp[6];
    end;
    if (t^.kind = 146) and (t^.xp[6]^.kind = 163) then
      emit_addr_con(t^.xp[6], sum) { forward }
    else if (t^.kind = 146) and (t^.xp[6]^.kind = 195) then
      emit_abs_addr_con(t^.xp[6], sum) { forward }
    else if t^.kind = 109 then begin
      v := t;
      s := v^.xp[5]^.xp[48];
      if (v^.xw[36] = 7) or (v^.xw[36] = 8) then begin
        value := sum + v^.xl[14] + s^.xl[5] - s^.xl[4];
        emit_32(value);
      end
      else if (v^.xw[36] = 1) or (v^.xw[36] = 4) then begin
        value := sum + v^.xl[14] - s^.xl[4];
        emit_32(value);
      end
      else begin
        cgerr_no_source(20, integer32(idntk(76, 'var_name', 8)));
        return;
      end;
      sect := s;
      if direct then
        off := uobj_direct_index + uobj_direct_base - 4
      else
        off := uobj_obj_pos + data_count + 6;
      store_fixup_info(sect, off, value);
      sym := get_reloc_symndx(v, 0);
      store_rel_info(data_section, off, sym);
      nrelocs_5c58 := nrelocs_5c58 + 1;
    end
    else if t^.kind = 163 then begin
      s := il_110;
      while s <> nil do begin
        a := s^.xp[3];
        while a <> nil do
          if a^.kind = 163 then begin
            if a = t then
              goto found;
            a := a^.xp[1];
          end
          else
            a := a^.xp[29];
        s := s^.xp[1];
      end;
      cgerr_no_source(20, integer32(idntk(76, 'addr_con', 8)));
    found:
      value := sum + t^.xl[4] - s^.xl[4];
      emit_32(value);
      sect := s;
      if direct then
        off := uobj_direct_index + uobj_direct_base - 4
      else
        off := uobj_obj_pos + data_count + 6;
      store_fixup_info(sect, off, value);
      sym := s^.xw[22];
      store_rel_info(data_section, off, sym);
      nrelocs_5c58 := nrelocs_5c58 + 1;
    end
    else
      cgerr_no_source(20, integer32(idntk(76, 'tree_node', 9)));
  end;

  { emit_data - len bytes, repeat times.

    0x09A27C, 0xCC bytes.  bytes by address, len and repeat longwords
    by value.  Once: each byte to emit_8.  Repeated, when not direct
    and the repetition adds 6 bytes or more ((repeat - 1) * len >= 6,
    M$MIS$LLL): the gathered data written, the bytes gathered once and
    written as a block of repeat count repeat (+0x5CCC); else the bytes
    repeat times.

    Not known from the original:
    - the names. }

  procedure emit_data(
      in bytes: univ unix_objmod_$bytes_t;
      len: integer32;
      repeat_count: integer32); options(val_param);
  var
    i: integer32;
    r: integer32;
  begin
    if repeat_count = 1 then
      for i := 1 to len do
        emit_8(bytes[i])
    else if not direct and ((repeat_count - 1) * len >= 6) then begin
      dump_data;
      for i := 1 to len do
        emit_8(bytes[i]);
      data_repeat := repeat_count;
      dump_data;
    end
    else
      for r := 1 to repeat_count do
        for i := 1 to len do
          emit_8(bytes[i]);
  end;

  { emit_constant - constant p, repeat times, in initialized data.

    0x09A348, 0x2AC bytes.  p a pointer, repeat a longword, line a word,
    by value.  By kind: 92 (a string) its characters (+18, length +16
    unsigned); 77, 200 the low byte of the value (+11, through a frame
    byte); 78, 80, 81 its low word (+10); 79, 82 the longword (+8); 88
    a double made single (dbl_to_real, kfold); 90, 89 8 bytes from +12;
    198 16; 87 the low byte of +8; 156, 212 (sets) +16 bytes from +18;
    176 (a record or array constant) its +8 bytes from +12, or, with
    address constants (the list at +4: offset +4, length +8, node +12,
    next +0), for each repetition the bytes up to each constant, the
    constant (emit_addr_con, emit_abs_addr_con, or a kind 137 of class
    26 by emit_tree_node_const; else cgerr_no_source(20, idntk(76,
    'rec_const'))) and the rest; 195 and 163 one emit_abs_addr_con /
    emit_addr_con a repetition.  Other kinds are reported
    (cgerr(20, line, idntk(76, 'emit_constant'))).

    Not known from the original:
    - the names. }

  procedure emit_constant(
      p: il_$node_ptr_t;
      repeat_count: integer32;
      line: integer); options(val_param);
  var
    r: integer32;
    pos: integer32;
    c: unix_objmod_$rec_addr_ptr_t;
    t: il_$node_ptr_t;
    b: char;
    w: integer;
    single: real;
    l: unix_objmod_$long_bytes_t;
  begin
    case p^.kind of
      92:
        emit_data(p^.str_chars, p^.str_len, repeat_count);
      77: begin
        b := p^.xc[11];
        emit_data(b, 1, repeat_count);
      end;
      200: begin
        b := p^.xc[11];
        emit_data(b, 1, repeat_count);
      end;
      78, 80, 81: begin
        w := p^.xw[5];
        emit_data(w, 2, repeat_count);
      end;
      79, 82:
        emit_data(p^.xl[2], 4, repeat_count);
      88: begin
        single := dbl_to_real(p, line);
        emit_data(single, 4, repeat_count);
      end;
      90, 89:
        emit_data(p^.xl[3], 8, repeat_count);
      198:
        emit_data(p^.xl[3], 16, repeat_count);
      87: begin
        l.l := p^.xl[2];
        emit_data(l.c[4], 1, repeat_count);
      end;
      156, 212:
        emit_data(p^.set_words, p^.set_len, repeat_count);
      176:
        if p^.xp[1] = nil then
          emit_data(p^.xl[3], p^.xl[2], repeat_count)
        else
          for r := 1 to repeat_count do begin
            pos := 0;
            c := unix_objmod_$rec_addr_ptr_t(p^.xp[1]);
            repeat
              emit_data(p^.xc[12 + pos], c^.offset - pos, 1);
              t := c^.node;
              case t^.kind of
                163:
                  emit_addr_con(t, 0); { forward }
                195:
                  emit_abs_addr_con(t, 0); { forward }
                137:
                  if t^.xw[18] = 26 then
                    emit_tree_node_const(t)
                  else
                    cgerr_no_source(20, integer32(idntk(76, 'rec_const', 9)));
                otherwise
                  cgerr_no_source(20, integer32(idntk(76, 'rec_const', 9)));
              end;
              pos := c^.offset + c^.len;
              c := c^.next;
            until c = nil;
            if pos < p^.xl[2] then
              emit_data(p^.xc[12 + pos], p^.xl[2] - pos, 1);
          end;
      195:
        for r := 1 to repeat_count do
          emit_abs_addr_con(p, 0); { forward }
      163:
        for r := 1 to repeat_count do
          emit_addr_con(p, 0); { forward }
      otherwise
        cgerr(20, line, idntk(76, 'emit_constant', 13));
    end;
  end;

  { find_global_id - whether the pair (name, block) is in the table of
    common blocks' symbols (A5 +0x20: 10-byte entries, the count the
    word +0x5DE0), and the symbol's number.

    0x09A60C, 0x5C bytes.  name and block pointers by value, id a word
    by address; a word loop, left with the result true (`st') at the
    first match; else id 0 and false.

    Not known from the original:
    - the names. }

  function find_global_id(
      name: univ_ptr;
      out id: integer;
      block: univ_ptr): boolean; options(val_param);
  var
    i: integer;
  begin
    for i := 1 to ncommons do
      if (commons[i].name = name) and (commons[i].block = block) then begin
        id := commons[i].id;
        find_global_id := true;
        return;
      end;
    id := 0;
    find_global_id := false;
  end;

  { emit_abs_addr_con - the longword of absolute address constant p
    (kind 195) plus offset, with its fixup and relocation.

    0x09A668, 0x416 bytes.  The value starts as p's +16 + offset; by
    the target's (+12) kind: 109 a variable: class 3 (common) its
    common's symbol must be known (find_global_id of its +4 and, when
    il_184's +377 bits 6..4 are 6, its +20; else cgerr_no_source(20,
    idntk(76, 'CASE'))), with -BSS and bit 16 of its +32 its offset
    +56 added; class 7, 8 its offset and its section's +20 - +16, 1, 4
    without +20, 10 its offset (the fixup against its +80); 194
    nothing; 111 (the fixup against the target); 108, 107 (routines):
    bits 8..7 of +376 0 the routine's +100 +56 (the fixup against its
    +188), 2 its symbol must be known (+296, and +8), else reported;
    183 (a section) less its +16, plus its +20 when p's +20 is 1.  The
    fixups are at the piece's index + its object offset (direct) or the
    object offset + the bytes gathered + 10.  Then the longword, and a
    relocation against the target four bytes back (+0x5C58 counts it).

    Not known from the original:
    - the names. }

  procedure emit_abs_addr_con;
  var
    value: integer32;
    blk: integer32;
    t: il_$node_ptr_t;
    s: il_$node_ptr_t;
    id: integer;
    k: integer;
    v: integer32;
    off: integer32;
    sym: integer32;
  begin
    value := p^.xl[4] + offset;
    blk := 0;
    t := p^.xp[3];
    case t^.kind of
      109:
        if t^.xw[36] = 3 then begin
          if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 6 then
            blk := t^.xl[5];
          if not find_global_id(t^.xp[1], id, univ_ptr(blk)) then
            cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)))
          else if (11 in cargs_$options.flags_286) and
                  ((t^.xl[8] & 16#10000) <> 0) then
            value := value + t^.xl[14];
        end
        else if (t^.xw[36] = 7) or (t^.xw[36] = 8) then begin
          s := t^.xp[5]^.xp[48];
          value := value + t^.xl[14] + s^.xl[5] - s^.xl[4];
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(s, off, v);
        end
        else if (t^.xw[36] = 1) or (t^.xw[36] = 4) then begin
          s := t^.xp[5]^.xp[48];
          value := value + t^.xl[14] - s^.xl[4];
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(s, off, v);
        end
        else if t^.xw[36] = 10 then begin
          value := value + t^.xl[14];
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(t^.xp[20], off, v);
        end
        else
          cgerr_no_source(20, integer32(idntk(76, 'var_name', 8)));
      194:
        ;
      111: begin
        v := value;
        if direct then
          off := uobj_direct_index + uobj_direct_base
        else
          off := uobj_obj_pos + data_count + 10;
        store_fixup_info(p^.xp[3], off, v);
      end;
      108, 107: begin
        k := (t^.xw[188] & 384) div 128;
        if k = 0 then begin
          value := value + t^.xp[25]^.xl[14];
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(t^.xp[47], off, v);
        end
        else if k = 2 then begin
          if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 6 then
            blk := t^.xl[2];
          if not find_global_id(t^.xp[74], id, univ_ptr(blk)) then
            cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
        end
        else
          cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
      end;
      183: begin
        value := value - t^.xl[4];
        if p^.xw[10] = 1 then
          value := value + t^.xl[5];
        v := value;
        if direct then
          off := uobj_direct_index + uobj_direct_base
        else
          off := uobj_obj_pos + data_count + 10;
        store_fixup_info(p^.xp[3], off, v);
      end;
      otherwise
        cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
    end;
    v := value;
    emit_32(v);
    sym := get_reloc_symndx(p^.xp[3], 0);
    if direct then
      off := uobj_direct_index + uobj_direct_base - 4
    else
      off := uobj_obj_pos + data_count + 6;
    store_rel_info(data_section, off, sym);
    nrelocs_5c58 := nrelocs_5c58 + 1;
  end;
  { emit_addr_con - the longword (or other form) of address constant p
    (kind 163) plus offset, with its fixup and relocation.

    0x09AA82, 0x840 bytes.  The relocation's symbol: for a label target
    (+8 of kind 144, 214, 215) or form 12 the +24 node's +64; for forms
    8 and 11 none; else get_reloc_symndx of the target with the
    symbol's own slot (not yet set) as the default.  The value starts
    as offset + p's +12; a jump table on the form (the byte +20, 1..12;
    `clr.w D0; move.b'): 1 the target's +20 - +16 (a section's start);
    2 a variable of class 4 (its offset +56 less its section's +16, the
    symbol the section's), or of class 3 with -BSS and bit 16 of +32
    its offset; then, of class 10, the fixup against its +80; 3 as it
    is; 4 a routine (167, 108, 107) defined here (+376 bits 8..7 0),
    5 and 9 any: with an entry control block (has_ecb) the routine's
    +108 less its section's +16 (the fixup against +192), else its
    +100's +56 (against +188); 6 a routine's (107, 108) +100 +56 and its
    +188's symbol, a label's displacement (sym_$displacement when
    target_properties +0x7F, else +56), 184 its +8's +12, others
    reported (cgerr(7, il_d0, target)), the fixup against p's +24; 7 a
    `jmp' (0x4EF9), the target's +56 with its fixup and relocation, a
    zero word; 8 a zero longword; 10 less the target's +16; 11 a
    character's byte and three zeros, or a string's characters padded
    to a multiple of 4; 12 the literal pool's displacement
    (sym_$displacement_literal_pool of the target and +24's +88; not
    on this target without +0x7F, reported).  Other forms are reported
    (cgerr_no_source(20, idntk(76, 'CASE'))).  The fixups are where the
    longword will go; then the longword and its relocation, counted in
    +0x5C58.

    Not known from the original:
    - the names; the forms' names. }

  procedure emit_addr_con;
  var
    value: integer32;
    sym: integer32;
    v: integer32;
    off: integer32;
    t: il_$node_ptr_t;
    s: il_$node_ptr_t;
    k: integer32;
  begin
    t := p^.xp[2];
    if (t^.kind = 144) or (t^.kind = 214) or (t^.kind = 215) or
       (ord(p^.xc[20]) = 12) then
      sym := p^.xp[6]^.xw[32]
    else if (ord(p^.xc[20]) = 8) or (ord(p^.xc[20]) = 11) then
      sym := 0
    else
      sym := get_reloc_symndx(t, sym);
    value := offset + p^.xl[3];
    case ord(p^.xc[20]) of
      1: begin
        t := p^.xp[2];
        value := value + t^.xl[5] - t^.xl[4];
        v := value;
        if direct then
          off := uobj_direct_index + uobj_direct_base
        else
          off := uobj_obj_pos + data_count + 10;
        store_fixup_info(p^.xp[2], off, v);
      end;
      2: begin
        t := p^.xp[2];
        if (t^.kind = 109) and (t^.xw[36] = 4) then begin
          value := value + t^.xl[14];
          s := t^.xp[5]^.xp[48];
          value := value - s^.xl[4];
          sym := get_reloc_symndx(s, sym);
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(p^.xp[2]^.xp[5]^.xp[48], off, v);
        end
        else if (t^.kind = 109) and (t^.xw[36] = 3) and
                (11 in cargs_$options.flags_286) and
                ((t^.xl[8] & 16#10000) <> 0) then
          value := value + t^.xl[14];
        t := p^.xp[2];
        if (t^.kind = 109) and (t^.xw[36] = 10) then begin
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(t^.xp[20], off, v);
        end;
      end;
      3: begin
        v := value;
        if direct then
          off := uobj_direct_index + uobj_direct_base
        else
          off := uobj_obj_pos + data_count + 10;
        store_fixup_info(p^.xp[2], off, v);
      end;
      4: begin
        t := p^.xp[2];
        if ((t^.kind = 167) or (t^.kind = 108) or (t^.kind = 107)) and
           ((t^.xw[188] & 384) div 128 = 0) then
          if has_ecb(t) then begin
            t := p^.xp[2];
            value := t^.xl[27] - t^.xp[48]^.xl[4];
            v := value;
            if direct then
              off := uobj_direct_index + uobj_direct_base
            else
              off := uobj_obj_pos + data_count + 10;
            store_fixup_info(t^.xp[48], off, v);
          end
          else begin
            t := p^.xp[2];
            value := t^.xp[25]^.xl[14];
            v := value;
            if direct then
              off := uobj_direct_index + uobj_direct_base
            else
              off := uobj_obj_pos + data_count + 10;
            store_fixup_info(t^.xp[47], off, v);
          end;
      end;
      5, 9:
        if has_ecb(p^.xp[2]) then begin
          t := p^.xp[2];
          value := t^.xl[27] - t^.xp[48]^.xl[4];
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(t^.xp[48], off, v);
        end
        else begin
          t := p^.xp[2];
          value := t^.xp[25]^.xl[14];
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(t^.xp[47], off, v);
        end;
      6: begin
        t := p^.xp[2];
        if (t^.kind = 107) or (t^.kind = 108) then begin
          value := t^.xp[25]^.xl[14];
          sym := t^.xp[47]^.xw[32];
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(t^.xp[47], off, v);
        end
        else begin
          if (t^.kind = 144) or (t^.kind = 214) or (t^.kind = 215) then
            if target_properties.p_7f then
              value := sym_$displacement(t)
            else
              value := t^.xl[14]
          else if t^.kind = 184 then
            value := t^.xp[2]^.xl[3]
          else
            cgerr(7, il_d0, t);
          v := value;
          if direct then
            off := uobj_direct_index + uobj_direct_base
          else
            off := uobj_obj_pos + data_count + 10;
          store_fixup_info(p^.xp[6], off, v);
        end;
      end;
      7: begin
        emit_16(16#4EF9);
        v := p^.xp[2]^.xl[14];
        emit_32(v);
        if direct then
          off := uobj_direct_index + uobj_direct_base - 4
        else
          off := uobj_obj_pos + data_count + 6;
        store_fixup_info(p^.xp[6], off, v);
        store_rel_info(data_section, off, sym);
        nrelocs_5c58 := nrelocs_5c58 + 1;
        emit_16(0);
        return;
      end;
      8: begin
        emit_32(0);
        return;
      end;
      10: begin
        value := value - p^.xp[2]^.xl[4];
        v := value;
        if direct then
          off := uobj_direct_index + uobj_direct_base
        else
          off := uobj_obj_pos + data_count + 10;
        store_fixup_info(p^.xp[2], off, v);
      end;
      11: begin
        t := p^.xp[2];
        if t^.kind = 87 then begin
          emit_8(t^.xc[11]);
          emit_8(chr(0));
          emit_16(0);
        end
        else begin
          emit_data(t^.str_chars, t^.str_len, 1);
          if (t^.str_len & 3) <> 0 then
            for k := 1 to 4 - (t^.str_len & 3) do
              emit_8(chr(0));
        end;
        return;
      end;
      12: begin
        if not target_properties.p_7f then
          cgerr_no_source(28, integer32(strtk(
            'EMIT_ADDR_CON --- Not supported on this hardware platform', 57)));
        value := sym_$displacement_literal_pool(p^.xp[2], p^.xp[6]^.xp[22]);
        v := value;
        if direct then
          off := uobj_direct_index + uobj_direct_base
        else
          off := uobj_obj_pos + data_count + 10;
        store_fixup_info(p^.xp[6], off, v);
      end;
      otherwise
        cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
    end;
    v := value;
    emit_32(v);
    if direct then
      off := uobj_direct_index + uobj_direct_base - 4
    else
      off := uobj_obj_pos + data_count + 6;
    store_rel_info(data_section, off, sym);
    nrelocs_5c58 := nrelocs_5c58 + 1;
  end;
  { emit_ecb - the entry control block of routine r (in section sect)
    in the data.

    0x09B306, 0x620 bytes.  r and sect pointers by value.  Nothing when
    r's symbol (+188's +64) is not positive.  By target_properties
    +0x10: 3 the words 0x601E0014, 0x185E, -4 - r's +110, then by the
    frame's size (+176 - +112 of r, or of its +148 for a kind 167, made
    a multiple of 8: `andi.b #-8') a stack check, 0x13FF001F 0x24300000
    0x13FF001F for none, else a register save (0x103F0000 or-ed with
    the mask +372 when +370 bit 13, 0x103F201A for a class 3 routine
    (+377 bits 6..4) under -AEGIS10 (flags_286 element 15), else
    0x103F2017), 0x24300000 and the adjustment (128 - size added to
    0x38200000 with the mask in the high word, 0x383A0000 or
    0x38370000, or for more than 128 bytes 65536 - size / 8, unsigned,
    added to 0x181F0000); then r's start (+286 + its +100's +56) with
    a fixup against +188 and a relocation against its symbol.  0 a
    `lea abs.l,A0' (0x41F9) of the section's +36 - +16 (fixup against
    r's +192, value minus its +16; relocation against sect's +44
    symbol) unless r's +294 is positive and +376 bit 4 clear; a `jmp
    abs.l' (0x4EF9) to r's +100 +56 (fixup and relocation); a zero word
    and longword when the lea was left out; a zero longword more with
    -DB (cargs +0x282 bits 16..15 not 0).  2 the four words
    0xEBA00000, 0x4BBC0010, 0xEB80C000, 0x4BBD0018, then two zero
    longwords, the first fixed up to r's start (relocation against
    +188's symbol), the second to minus its section's +16 (relocation
    against +192's +44 symbol).  Others are reported
    (cgerr_no_source(28, strtk('EMIT_ECB --- Unsupported target
    isp.'))).  Each relocation counts in +0x5C58; the fixups are four
    bytes back (direct: the piece's index + its offset - 4; else the
    object offset + the bytes gathered + 6).

    Not known from the original:
    - the names; how the constants were written (the image takes them
      from the literal pool after the routine, the zeros shared with
      emit_addr_con's). }

  procedure emit_ecb(
      r: il_$node_ptr_t;
      sect: il_$node_ptr_t); options(val_param);
  var
    size: integer32;
    start: integer32;
    v: integer32;
    off: integer32;
    sym: integer32;
    w: integer;
  begin
    if r^.xp[47]^.xw[32] <= 0 then
      return;
    case target_properties.p_10 of
      3: begin
        emit_32(16#601E0014);
        emit_16(16#185E);
        w := -4 - r^.xw[55];
        emit_16(w);
        if r^.kind = 167 then
          size := r^.xp[37]^.xl[44] - r^.xp[37]^.xl[28]
        else
          size := r^.xl[44] - r^.xl[28];
        size := (size + 7) & 16#FFFFFFF8;
        if size = 0 then begin
          emit_32(16#13FF001F);
          emit_32(16#24300000);
          emit_32(16#13FF001F);
        end
        else begin
          if (r^.xw[185] & 16#2000) <> 0 then begin
            v := r^.xw[186] & 16#FFFF;
            v := v ! 16#103F0000;
            emit_32(v);
          end
          else if ((ord(r^.xc[377]) & 16#70) div 16 = 3) and
                  (15 in cargs_$options.flags_286) then
            emit_32(16#103F201A)
          else
            emit_32(16#103F2017);
          emit_32(16#24300000);
          if size <= 128 then begin
            if (r^.xw[185] & 16#2000) <> 0 then
              v := (lshft(r^.xw[186] & 16#FFFF, 16) ! 16#38200000) +
                   (128 - size)
            else if ((ord(r^.xc[377]) & 16#70) div 16 = 3) and
                    (15 in cargs_$options.flags_286) then
              v := 128 - size + 16#383A0000
            else
              v := 128 - size + 16#38370000;
          end
          else
            v := 65536 - rshft(size, 3) + 16#181F0000;
          emit_32(v);
        end;
        start := r^.xw[143] + r^.xp[25]^.xl[14];
        emit_32(start);
        if direct then
          off := uobj_direct_index + uobj_direct_base - 4
        else
          off := uobj_obj_pos + data_count + 6;
        store_fixup_info(r^.xp[47], off, start);
        sym := r^.xp[47]^.xw[32];
        store_rel_info(data_section, off, sym);
        nrelocs_5c58 := nrelocs_5c58 + 1;
      end;
      0: begin
        if (ord(r^.xc[294]) > 127) or (ord(r^.xc[294]) = 0) or
           ((ord(r^.xc[376]) & 16) <> 0) then begin
          emit_16(16#41F9);
          v := r^.xp[48]^.xl[9] - r^.xp[48]^.xl[4];
          emit_32(v);
          v := -r^.xp[48]^.xl[4];
          if direct then
            off := uobj_direct_index + uobj_direct_base - 4
          else
            off := uobj_obj_pos + data_count + 6;
          store_fixup_info(r^.xp[48], off, v);
          sym := sect^.xw[22];
          store_rel_info(data_section, off, sym);
          nrelocs_5c58 := nrelocs_5c58 + 1;
        end;
        emit_16(16#4EF9);
        emit_32(r^.xp[25]^.xl[14]);
        if direct then
          off := uobj_direct_index + uobj_direct_base - 4
        else
          off := uobj_obj_pos + data_count + 6;
        store_fixup_info(r^.xp[47], off, r^.xp[25]^.xl[14]);
        sym := r^.xp[47]^.xw[32];
        store_rel_info(data_section, off, sym);
        nrelocs_5c58 := nrelocs_5c58 + 1;
        if (ord(r^.xc[294]) > 0) and (ord(r^.xc[294]) <= 127) and
           ((ord(r^.xc[376]) & 16) = 0) then begin
          emit_16(0);
          emit_32(0);
        end;
        if cargs_$options.db <> 0 then
          emit_32(0);
      end;
      2: begin
        emit_32(16#EBA00000);
        emit_32(16#4BBC0010);
        emit_32(16#EB80C000);
        emit_32(16#4BBD0018);
        start := r^.xw[143] + r^.xp[25]^.xl[14];
        emit_32(0);
        if direct then
          off := uobj_direct_index + uobj_direct_base - 4
        else
          off := uobj_obj_pos + data_count + 6;
        store_fixup_info(r^.xp[47], off, start);
        sym := r^.xp[47]^.xw[32];
        store_rel_info(data_section, off, sym);
        nrelocs_5c58 := nrelocs_5c58 + 1;
        emit_32(0);
        v := -r^.xp[48]^.xl[4];
        if direct then
          off := uobj_direct_index + uobj_direct_base - 4
        else
          off := uobj_obj_pos + data_count + 6;
        store_fixup_info(r^.xp[48], off, v);
        sym := r^.xp[48]^.xw[22];
        store_rel_info(data_section, off, sym);
        nrelocs_5c58 := nrelocs_5c58 + 1;
      end;
      otherwise
        cgerr_no_source(28, integer32(strtk(
          'EMIT_ECB --- Unsupported target isp.', 36)));
    end;
  end;

  { create_global_reference - the COFF symbol number of the external p
    refers to, entered in the table of externals when new.

    0x09B972, 0x1BA bytes.  p a pointer by value, the number a word in
    D0.  A variable of class 4 its block's section's +40, of class 10
    its +80's +26; another variable its name +4 (and with il_184's +377
    bits 6..4 6 its +20 as the block); a routine (167, 108, 107)
    defined here 0, else its +296 (and +8); 110, 159 and 208 the
    identifier of their names (+72 for +70; +12 + 2 * +10 for +8; +50
    for the byte +49).  Other kinds are reported (cgerr_no_source(20,
    idntk(76, 'CASE'))).  Known (find_global_id): its number; else
    entered (more than 2048 reported, cgerr_no_source(24, strtk('too
    many externals '))) with the next symbol number (+0x5E04, then
    incremented).

    Not known from the original:
    - the names. }

  function create_global_reference(
      p: il_$node_ptr_t): integer; options(val_param);
  var
    blk: integer32;
    name: il_$node_ptr_t;
    id: integer;
  begin
    blk := 0;
    case p^.kind of
      109:
        if p^.xw[36] = 4 then begin
          create_global_reference := p^.xp[5]^.xp[48]^.xw[20];
          return;
        end
        else if p^.xw[36] = 10 then begin
          create_global_reference := p^.xp[20]^.xw[13];
          return;
        end
        else begin
          name := p^.xp[1];
          if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 6 then
            blk := p^.xl[5];
        end;
      167, 108, 107:
        if (p^.xw[188] & 384) div 128 = 0 then begin
          create_global_reference := 0;
          return;
        end
        else begin
          name := p^.xp[74];
          if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 6 then
            blk := p^.xl[2];
        end;
      110:
        name := idntk(76, p^.xc[72], p^.xw[35]);
      159:
        name := idntk(76, p^.xc[12 + 2 * p^.xw[5]], p^.xw[4]);
      208:
        name := idntk(76, p^.xc[50], ord(p^.xc[49]));
      otherwise
        cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
    end;
    if find_global_id(name, id, univ_ptr(blk)) then begin
      create_global_reference := id;
      return;
    end;
    ncommons := ncommons + 1;
    if ncommons > 2048 then
      cgerr_no_source(24, integer32(strtk('too many externals ', 19)));
    commons[ncommons].name := name;
    commons[ncommons].id := uobj_nsyms;
    commons[ncommons].block := univ_ptr(blk);
    create_global_reference := uobj_nsyms;
    uobj_nsyms := uobj_nsyms + 1;
  end;

  { write_transfer_vectors - the .aptv section: a `jmp abs.l' (6
    bytes) for each distinct transfer vector target, and its header.

    0x09BB40, 0x1D0 bytes.  Nothing without transfer vectors (+0x5D70).
    The section starts at the object offset (+0x5CF0); a word list of
    the targets seen (gspace of 2 * the count); for each transfer
    vector of il_128 (+4 the chain): a target seen (+18 against the
    list, a word loop left by `exit') shares that entry (its symbol
    +16 the base +0x5E04 + the index - 1, its address +12 the entry's);
    else a new entry: the symbol number, 0x4EF9 and a zero longword at
    the object offset, the address the offset + +0x5D74.  Then the
    section header at +0x5D80 (the relocations' header +0x5DA8 set to
    it when there is none), the size rounded up to 4: '.aptv'
    (unix_put_obj_name of strtk('.aptv')), physical and virtual address
    the start + +0x5D74 + +0x5C54, the size, the file offset, the rest
    zeros and flags 0x40 (STYP_DATA, a 16-byte constant copied);
    +0x5E02 counts the section, +0x5E00 its number; +0x5D80 moves past
    the header; +0x5C9C grows by the size.

    Not known from the original:
    - the names. }

  procedure write_transfer_vectors;
  var
    n: integer;
    i: integer;
    seen: unix_objmod_$words_ptr_t;
    base: integer;
    found: boolean;
    j: unix_objmod_$jmp_ptr_t;
    h: unix_objmod_$scnhdr_ptr_t;
    s: il_$node_ptr_t;
  begin
    n := 0;
    if uobj_ntvs.l <> 0 then begin
      tv_start := uobj_obj_pos;
      seen := gspace(2 * uobj_ntvs.low);
      base := uobj_nsyms;
      tv := il_128;
      while tv <> nil do begin
        found := false;
        for i := 1 to n do
          if tv^.xw[9] = seen^[i] then begin
            tv^.xw[8] := base + i - 1;
            tv^.xl[3] := (i - 1) * 6 + tv_start + uobj_addr_bias;
            found := true;
            exit;
          end;
        if not found then begin
          n := n + 1;
          j := putobj(uobj_obj_pos, 6);
          obj_map_5d18 := j;
          tv^.xw[8] := uobj_nsyms;
          uobj_nsyms := uobj_nsyms + 1;
          j^.op := 16#4EF9;
          tv^.xl[3] := uobj_obj_pos + uobj_addr_bias;
          j^.addr := 0;
          freeobj(obj_map_5d18);
          uobj_obj_pos := uobj_obj_pos + 6;
          seen^[n] := tv^.xw[9];
        end;
        tv := tv^.xp[1];
      end;
      if uobj_reloc_scnhdr_pos = 0 then
        uobj_reloc_scnhdr_pos := uobj_scnhdr_pos;
      if ((uobj_obj_pos - tv_start) & 3) <> 0 then
        uobj_obj_pos := (uobj_obj_pos & (-4)) + 4;
      h := putobj(uobj_scnhdr_pos, 40);
      scnhdr_map := h;
      s := strtk('.aptv', 5);
      unix_put_obj_name(h^.s_name, s);
      h^.s_paddr := tv_start + uobj_addr_bias + data_5c54;
      h^.s_vaddr := h^.s_paddr;
      h^.s_size := uobj_obj_pos - tv_start;
      h^.s_scnptr := tv_start;
      h^.s_relptr := 0;
      h^.s_lnnoptr := 0;
      h^.s_nreloc := 0;
      h^.s_nlnno := 0;
      h^.s_flags := [unix_objmod_$styp_data];
      uobj_nsects := uobj_nsects + 1;
      uobj_aptv_sect := uobj_nsects;
      uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
      freeobj(scnhdr_map);
      data_5c9c := data_5c9c + (uobj_obj_pos - tv_start);
    end;
  end;

  { get_load_addr - the virtual address of section n.

    0x09BD26, 0x46 bytes: the header at +0x5C70 + (n - 1) * 40 mapped,
    its s_vaddr, freed. }

  function get_load_addr(
      n: integer32): integer32; options(val_param);
  var
    h: unix_objmod_$scnhdr_ptr_t;
    a: integer32;
  begin
    h := putobj((n - 1) * 40 + scnhdr_base, 40);
    a := h^.s_vaddr;
    freeobj(h);
    get_load_addr := a;
  end;

  { get_section_id - the section number of what p refers to.

    0x09BD6C, 0xB2 bytes.  A variable its block's section's +46; 110
    by +44 bits 7..4: 1 its +40's section's, 3 its +58's +34 (or the
    first data section's +46); 183 its +46; 194 its target's; 108, 107
    the +188's +66; 111 its +34.  Otherwise the result is not set.

    Not known from the original:
    - the names. }

  function get_section_id(
      p: il_$node_ptr_t): integer32; options(val_param);
  var
    k: integer;
  begin
    case p^.kind of
      109:
        get_section_id := p^.xp[5]^.xp[48]^.xw[23];
      110: begin
        k := (ord(p^.xc[44]) & 16#F0) div 16;
        if k = 1 then
          get_section_id := p^.xp[10]^.xp[48]^.xw[23]
        else if k = 3 then
          if p^.xp2[14] <> nil then
            get_section_id := p^.xp2[14]^.xw[17]
          else
            get_section_id := il_$node_ptr_t(il_110)^.xw[23];
      end;
      183:
        get_section_id := p^.xw[23];
      194:
        get_section_id := get_section_id(p^.xp[2]);
      108, 107:
        get_section_id := p^.xp[47]^.xw[33];
      111:
        get_section_id := p^.xw[17];
      otherwise
        ;
    end;
  end;

  { gen_data_relocs - store the fixups' values in the object file.

    0x09BE1E, 0xB2 bytes.  Down the fixup list (the tail +0x5D24 used as
    the cursor): the longword at the fixup's offset mapped (putobj, 4)
    and set byte by byte (a frame longword copied with a 4-byte loop)
    to its value plus its section's base: +36 for 183, +56 for 182, +44
    for 111 (for another kind the value of the previous one).

    Not known from the original:
    - the names. }

  procedure gen_data_relocs;
  var
    b: unix_objmod_$bytes_ptr_t;
    t: unix_objmod_$long_bytes_t;
    v: integer32;
    s: il_$node_ptr_t;
    i: integer32;
  begin
    fixup_tail := fixup_head;
    while fixup_tail <> nil do begin
      b := putobj(fixup_tail^.offset, 4);
      s := fixup_tail^.sect;
      case s^.kind of
        183:
          v := fixup_tail^.value + s^.xl[9];
        182:
          v := fixup_tail^.value + s^.xl[14];
        111:
          v := fixup_tail^.value + s^.xl[11];
        otherwise
          ;
      end;
      t.l := v;
      for i := 1 to 4 do
        b^[i] := t.c[i];
      freeobj(b);
      fixup_tail := fixup_tail^.next;
    end;
  end;

  { gen_proc_relocs - resolve the relocations of section sect from the
    list at r: what the module defines is patched into the code (with
    the load addresses of the section headers), and each such patch
    and each external sets +0x5E0A; with only_externals the externals
    are entered (create_global_reference) and nothing is patched.

    0x09BED0, 0x640 bytes.  sect a longword, r by address (the cursor,
    left at nil), only_externals a byte, by value.  For each
    relocation of sect with a target (+12) the longword at its address
    (+4) is mapped (putobj, 4) and by the target's kind: 192 (a
    transfer vector) its address + +0x5C54; a variable of class 3 (a
    common) entered or looked up (find_global_id; unknown reported,
    'CASE'), with -BSS and bit 16 of +32 its offset added (the longword
    left mapped); class 1, 4 the section's load address + the
    longword + its offset - the section's +16, 7, 8 with +20 too, 10 its
    +80's section; other classes reported ('var_name'); 110 by +44 bits
    7..4 a common (1) as a variable's, else by +11 bits 7..4 1, 7 (with
    il_184's section) or 3, else reported ('fortran_'); 194 nothing to
    patch; 111 its section's address added; a routine defined here its
    entry (+188's section's address + +100's +56), an external (bits
    8..7 of +376 2) entered or looked up; 183 the section's address
    less its +16; 195 (form 1) its target's section's address + +16 +
    the target's +20 - +16.  Others are reported ('CASE').  The
    block found by find_global_id (-8) is cleared once, at entry.

    Not known from the original:
    - the names. }

  procedure gen_proc_relocs(
      sect: univ_ptr;
      var r: unix_objmod_$reloc_ptr_t;
      only_externals: boolean;
      hdr: integer32); options(val_param);
  var
    blk: integer32;
    t: il_$node_ptr_t;
    s: il_$node_ptr_t;
    q: unix_objmod_$reloc_ptr_t;
    p: unix_objmod_$long_ptr_t;
    id: integer;
    k: integer;
    k2: integer;
  begin
    blk := 0;
    while r <> nil do begin
      if r^.sect = sect then begin
        q := r;
        if q^.target <> nil then begin
          t := q^.target;
          case t^.kind of
            192:
              if not only_externals then begin
                p := putobj(q^.vaddr, 4);
                p^ := q^.target^.xl[3] + data_5c54;
                freeobj(p);
                patched := true;
              end;
            109:
              if t^.xw[36] = 3 then begin
                if only_externals then
                  k2 := create_global_reference(t)
                else begin
                  if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 6 then
                    blk := t^.xl[5];
                  if find_global_id(t^.xp[1], id, univ_ptr(blk)) then
                    patched := true
                  else
                    cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
                  if (11 in cargs_$options.flags_286) and
                     ((q^.target^.xl[8] & 16#10000) <> 0) then begin
                    p := putobj(q^.vaddr, 4);
                    p^ := p^ + q^.target^.xl[14];
                  end;
                end;
              end
              else if ((t^.xw[36] = 1) or (t^.xw[36] = 4)) and
                      not only_externals then begin
                s := t^.xp[5]^.xp[48];
                p := putobj(q^.vaddr, 4);
                p^ := get_load_addr(q^.target^.xp[5]^.xp[48]^.xw[23]) + p^ +
                      q^.target^.xl[14] - s^.xl[4];
                freeobj(p);
                patched := true;
              end
              else if ((t^.xw[36] = 7) or (t^.xw[36] = 8)) and
                      not only_externals then begin
                s := t^.xp[5]^.xp[48];
                p := putobj(q^.vaddr, 4);
                p^ := get_load_addr(q^.target^.xp[5]^.xp[48]^.xw[23]) + p^ +
                      q^.target^.xl[14] + s^.xl[5] - s^.xl[4];
                freeobj(p);
                patched := true;
              end
              else if t^.xw[36] = 10 then begin
                if not only_externals then begin
                  p := putobj(q^.vaddr, 4);
                  p^ := p^ + (get_load_addr(q^.target^.xp[20]^.xw[17]) +
                              q^.target^.xl[14]);
                  freeobj(p);
                  patched := true;
                end;
              end
              else if not only_externals then
                cgerr_no_source(20, integer32(idntk(76, 'var_name', 8)));
            110: begin
              k := (ord(t^.xc[44]) & 16#F0) div 16;
              if k = 1 then begin
                if only_externals then
                  k2 := create_global_reference(t)
                else if find_global_id(idntk(76, t^.xc[72], t^.xw[35]), id,
                                       univ_ptr(blk)) then
                  patched := true
                else
                  cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
              end
              else begin
                k2 := (ord(t^.xc[11]) & 16#F0) div 16;
                if (k2 = 1) and not only_externals then begin
                  s := il_$node_ptr_t(il_184)^.xp[48];
                  p := putobj(q^.vaddr, 4);
                  p^ := get_load_addr(get_section_id(q^.target)) + p^ +
                        q^.target^.xl[3] - s^.xl[4];
                  freeobj(p);
                  patched := true;
                end
                else if (k2 = 7) and not only_externals then begin
                  s := il_$node_ptr_t(il_184)^.xp[48];
                  p := putobj(q^.vaddr, 4);
                  p^ := get_load_addr(get_section_id(q^.target)) + p^ +
                        q^.target^.xl[3] + s^.xl[5] - s^.xl[4];
                  freeobj(p);
                  patched := true;
                end
                else if k2 = 3 then begin
                  if not only_externals then begin
                    p := putobj(q^.vaddr, 4);
                    p^ := p^ + (get_load_addr(get_section_id(q^.target)) +
                                q^.target^.xl[3]);
                    freeobj(p);
                    patched := true;
                  end;
                end
                else if not only_externals then
                  cgerr_no_source(20, integer32(idntk(76, 'fortran_', 8)));
              end;
            end;
            194:
              if not only_externals then
                patched := true;
            111:
              if not only_externals then begin
                p := putobj(q^.vaddr, 4);
                p^ := p^ + get_load_addr(q^.target^.xw[17]);
                freeobj(p);
                patched := true;
              end;
            167, 108, 107: begin
              k := (t^.xw[188] & 384) div 128;
              if (k = 0) and not only_externals then begin
                p := putobj(q^.vaddr, 4);
                p^ := get_load_addr(q^.target^.xp[47]^.xw[33]) +
                      q^.target^.xp[25]^.xl[14];
                freeobj(p);
                patched := true;
              end
              else if k = 2 then begin
                if only_externals then
                  k2 := create_global_reference(t)
                else begin
                  if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 6 then
                    blk := t^.xl[2];
                  if find_global_id(t^.xp[74], id, univ_ptr(blk)) then
                    patched := true
                  else
                    cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
                end;
              end
              else if not only_externals then
                cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
            end;
            183:
              if not only_externals then begin
                p := putobj(q^.vaddr, 4);
                p^ := get_load_addr(q^.target^.xw[23]) + p^ -
                      q^.target^.xl[4];
                freeobj(p);
                patched := true;
              end;
            195:
              if t^.xw[10] = 1 then begin
                if not only_externals then begin
                  s := t^.xp[3];
                  p := putobj(q^.vaddr, 4);
                  p^ := get_load_addr(get_section_id(q^.target^.xp[3])) + p^ +
                        q^.target^.xl[4] + s^.xl[5] - s^.xl[4];
                  freeobj(p);
                  patched := true;
                end;
              end
              else if not only_externals then
                cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
            otherwise
              if not only_externals then
                cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
          end;
        end;
      end;
      r := r^.next;
    end;
  end;
  { determine_section_headers_size - count the section headers and
    place the raw data after them.

    0x09C51E, 0xF6 bytes.  The count (+0x5CAC): each data section
    (il_110, +4), each code section with contents (il_10c, +12 not 0),
    each of il_118 (+8), one more (+0x5E10 set), one for il_114, with
    -DB one (and one for il_d4) and with -DBS or -DBA each symbols
    section of +0x5C30 (+8), one for il_13c, three, one with transfer
    vectors and one with -INLIB libraries.  The headers start at +0x5D1C
    (+0x5D80); the object offset and +0x5C48 after them.

    Not known from the original:
    - the names. }

  procedure determine_section_headers_size;
  var
    d: il_$node_ptr_t;
    c: il_$node_ptr_t;
    s: il_$node_ptr_t;
    db: integer;
  begin
    d := il_110;
    c := il_10c;
    s := il_118;
    nscns.l := 0;
    while d <> nil do begin
      nscns.l := nscns.l + 1;
      d := d^.xp[1];
    end;
    while c <> nil do begin
      if c^.xl[3] <> 0 then
        nscns.l := nscns.l + 1;
      c := c^.xp[1];
    end;
    while s <> nil do begin
      nscns.l := nscns.l + 1;
      s := s^.xp[2];
    end;
    uobj_headers_counted := true;
    nscns.l := nscns.l + 1;
    if il_114 <> 0 then
      nscns.l := nscns.l + 1;
    db := cargs_$options.db;
    if db >= 1 then begin
      nscns.l := nscns.l + 1;
      if il_d4 <> nil then
        nscns.l := nscns.l + 1;
      if db >= 2 then begin
        s := symbols_sections;
        while s <> nil do begin
          nscns.l := nscns.l + 1;
          s := s^.xp[2];
        end;
      end;
    end;
    if il_13c <> 0 then
      nscns.l := nscns.l + 1;
    nscns.l := nscns.l + 3;
    if uobj_ntvs.l > 0 then
      nscns.l := nscns.l + 1;
    if inc_list_ninlib <> 0 then
      nscns.l := nscns.l + 1;
    uobj_scnhdr_pos := scnhdr_start;
    uobj_obj_pos := nscns.l * 40 + uobj_scnhdr_pos;
    raw_data_start := uobj_obj_pos;
  end;

  { data_sections - write the data of section p (a data section, kind
    0, or a common, kind not 0) and, with make_header, its section
    header.

    0x09CED8, 0x548 bytes.  p a pointer, kind a word, with_data and
    make_header bytes, by value.  In a compressed section (+0x5E08) the
    first block's start (+0x5C64) is noted and the offset aligned to
    target_properties +0x90.  The size (+0x5E1C) is the section's +24 +
    +20 - +16 (a common's +20), aligned likewise; with data (and not
    compressed) the offset is aligned; +0x5DC0 its start; with
    make_header the section's address (+36, a common's +44) is the
    start + +0x5D74 + +0x5C54, and +0x5C4C the address.  With data: a
    data section without contents (+12, +28) named '.bss' (strl_$eq)
    gets address 0 and nothing else is done; without contents its size
    counts in +0x5C98; else the data go straight to the object file
    (+0x5E0E) under -NCOMPRESS (not under -COMPRESS, `btst #0' of
    +0x28A), mapped by pieces from the start, or through the buffer:
    for a data section the address constants and the entry control
    blocks of +12 (+4 for 163, +116 for routines; with target_properties
    +0x7F zero words up to the first), then the initializations (+28;
    a common's +36) by dump_data_init_thread, with the section's symbol
    (+44, a common's +32) in +0x5C78; the piece freed or the buffer
    written; align_data_position.  +48 gets the relocations counted
    (+0x5C58).  The header: '.name' of the section's +8 (a common's +4,
    with +0x5E14 for the '_'), its number (+46 / +34, +0x5E02) and
    symbol (+40 / +26, +0x5E04, incremented); file offset the data's
    start when there are data, addresses, size, flags: -ZERO
    STYP_ZERO; a data section: cpu element 6 bit 28, no contents
    STYP_ZERO + STYP_BSS (the size in +0x5C6C; direct output skips
    the space), with data STYP_DATA, else compressed + STYP_BSS; a
    common: overlay, cpu element 6 bit 28 for more than 4 bytes, the
    same three, and for a class 3 module (il_184's +377 bits 6..4) bit
    26 when p's +54 is set or not -AC/-ABS.  The relocations' header
    +0x5DA8 is the first written; +0x5D80 moves on.  Without data the
    size is added to +0x5C54.

    Not known from the original:
    - the names; the block's own variables (line, the constant list)
      that dump_data_init_thread reaches through the static link. }

  procedure data_sections(
      p: il_$node_ptr_t;
      kind: integer;
      with_data: boolean;
      make_header: boolean); options(val_param);
  label
    done;
  var
    start: integer32;
    line: integer;
    clist: il_$node_ptr_t;
    t: integer32;
    i: integer;
    n: integer32;
    h: unix_objmod_$scnhdr_ptr_t;
    e: il_$node_ptr_t;

    { align_data_position - pad the section's data to a multiple of 4
      from its start (not in a compressed section) and count its size
      in +0x5C9C.

      0x09CE9E, 0x3A bytes: no frame (pattern 14). }

    procedure align_data_position;
    begin
      if ((uobj_obj_pos - uobj_sect_start) & 3) <> 0 then
        if not compressed then begin
          uobj_pad_from := uobj_obj_pos;
          uobj_obj_pos := (uobj_obj_pos & (-4)) + 4;
          sect_size := sect_size + (uobj_obj_pos - uobj_pad_from);
        end;
      data_5c9c := data_5c9c + sect_size;
    end;

    { dump_data_init_thread - the initializations of thread, in address
      order.

      0x09CC02, 0x260 bytes.  thread by value, read only by
      sort_data_init_thread (through the dynamic link).  For each
      element of the sorted thread (+4): a kind 221 (an else clause
      left) is reported (cgerr_no_source(28, idntk(76, 'ELSE clause
      failure'))); the data start (init_data) at the target's (+8)
      address in its section: a kind 110 with +58 (a common) its +26 and
      the element's +12 + the target's +12, else by +11 bits 7..4: 1 or
      7 in il_184's section; a variable by class 1, 4, 7, 8 or 10 as
      ddisp computes; others are skipped.  The line (data_sections'
      local) is spos_$null_position, or a variable's +8.  The value
      (+16): a list (114: +8 the constant, +12 the count, +4 next) each
      by emit_constant; a constant ([77..90, 92, 93, 101, 156, 176,
      198, 200], a bit set after the routine) once; 163, 195, a 137 of
      class 26 by their emitters; else reported (cgerr(20, line,
      idntk(76, 'initial_value'))).

      Not known from the original:
      - the names. }

    procedure dump_data_init_thread(
        thread: il_$node_ptr_t); options(val_param);
    var
      e: il_$node_ptr_t;
      t: il_$node_ptr_t;
      s: il_$node_ptr_t;
      c: il_$node_ptr_t;
      k: integer;

      { sort_data_init_thread - the elements of thread as a new chain,
        in address order, the gaps of an aggregate's else clause (221)
        filled with its value.

        0x09C95A, 0x2A8 bytes.  The parent's frame from the dynamic
        link (`movea.l (A6),A2'), thread read there; the chain in A0.
        The displacements (ddisp) are checked for order on the way
        (a kind 221 counts as out of order); an array of (element,
        displacement) pairs from PAS_$NEW (nil reported, code 9)
        sorted by qsort when needed; then rebuilt: a 221 starts a
        range (its +12 to its +24); a gap or a later 221 gets a filler
        (kind 113, 24 bytes from gspace32: +8 the 221's, +12 the
        position, +16 its value and size) before it; the others are
        linked with the next element's offset (0 after the last).  A
        range left open gets a last filler, its value a repetition
        (kind 114, gspace(16), kept in +0x5CD0: +12 the count, +8 the
        value) when it does not reach the range's end.  The chain is
        ended (+4 nil) and the array disposed.

        Not known from the original:
        - the names. }

      function sort_data_init_thread: il_$node_ptr_t;
      var
        a: unix_objmod_$pairs_ptr_t;
        range: il_$node_ptr_t;
        range_end: integer32;
        pos: integer32;
        head: il_$node_ptr_t;
        tail: il_$node_ptr_t;
        temp: unix_objmod_$pair_t;
        n: integer32;
        i: integer32;
        d: integer32;
        sorted: boolean;
        q: il_$node_ptr_t;
        f: il_$node_ptr_t;

        { qsort - sort a[lo..hi] by displacement, a kind 221 after the
          others of its displacement.

          0x09C614, 0x1BA bytes.  lo and hi longwords by value; the
          parent's frame in A1 (the array -48, the swap temporary
          -24).  The middle element is swapped to hi as the pivot;
          the scans move over smaller (or equal and 221) and greater
          (or equal and not 221) elements; then the pivot is put in
          place and both sides sorted.

          Not known from the original:
          - the names. }

        procedure qsort(
            lo: integer32;
            hi: integer32); options(val_param);
        var
          i: integer32;
          j: integer32;
          mid: integer32;
          first: integer32;
          last: integer32;
        begin
          i := lo;
          first := lo;
          mid := (hi - lo) div 2 + lo;
          temp := a^[hi];
          a^[hi] := a^[mid];
          a^[mid] := temp;
          last := hi;
          j := hi - 1;
          repeat
            while (i < j) and
                  ((a^[i].disp < a^[last].disp) or
                   ((a^[i].disp = a^[last].disp) and
                    (a^[i].elem^.kind = 221))) do
              i := i + 1;
            while (i < j) and
                  ((a^[j].disp > a^[last].disp) or
                   ((a^[j].disp = a^[last].disp) and
                    (a^[j].elem^.kind <> 221))) do
              j := j - 1;
            if i < j then begin
              temp := a^[i];
              a^[i] := a^[j];
              a^[j] := temp;
            end;
          until i >= j;
          if i < last then
            if (a^[i].disp > a^[last].disp) or
               ((a^[i].disp = a^[last].disp) and
                (a^[last].elem^.kind = 221)) then begin
              temp := a^[i];
              a^[i] := a^[last];
              a^[last] := temp;
            end;
          i := i + 1;
          if i < last then
            qsort(i, last);
          if first < j then
            qsort(first, j);
        end;

        { ddisp - the displacement of element e: its +12 plus its
          target's offset in its section.

          0x09C7CE, 0xDE bytes (no use of the parent).  A kind 110
          target: with +58 its +12; else by +11 bits 7..4 1 (less
          il_184's section's +16) or 7 (plus its +20); a variable by
          class 1, 4 (offset +56 less its section's +16), 7, 8 (plus
          +20) or 10 (offset only); else 0.

          Not known from the original:
          - the names. }

        function ddisp(
            e: il_$node_ptr_t): integer32; options(val_param);
        var
          t: il_$node_ptr_t;
          s: il_$node_ptr_t;
          d: integer32;
          k: integer;
        begin
          d := 0;
          t := e^.xp[2];
          if t^.kind = 110 then begin
            if t^.xp2[14] <> nil then
              d := e^.xl[3] + t^.xl[3]
            else begin
              k := (ord(t^.xc[11]) & 16#F0) div 16;
              if k = 1 then
                d := e^.xl[3] + t^.xl[3] - il_$node_ptr_t(il_184)^.xp[48]^.xl[4]
              else if k = 7 then
                d := e^.xl[3] + t^.xl[3] + il_$node_ptr_t(il_184)^.xp[48]^.xl[5] -
                     il_$node_ptr_t(il_184)^.xp[48]^.xl[4];
            end;
          end
          else begin
            k := t^.xw[36];
            if (k = 1) or (k = 4) then begin
              s := t^.xp[5]^.xp[48];
              d := e^.xl[3] + t^.xl[14] - s^.xl[4];
            end
            else if (k = 7) or (k = 8) then begin
              s := t^.xp[5]^.xp[48];
              d := e^.xl[3] + t^.xl[14] + s^.xl[5] - s^.xl[4];
            end
            else if k = 10 then
              d := e^.xl[3] + t^.xl[14];
          end;
          ddisp := d;
        end;

        { adjust_head_and_tail - e onto the new chain.

          0x09C8AC, 0x2A bytes.  The parent's frame in A1 (head -32,
          tail -28). }

        procedure adjust_head_and_tail(
            e: il_$node_ptr_t); options(val_param);
        begin
          if head = nil then
            head := e
          else
            tail^.xp[1] := e;
          tail := e;
        end;

        { link_and_update_offset - e onto the chain; the position
          advances past it.

          0x09C8D6, 0x84 bytes.  The parent's frame from the dynamic
          link.  A repeated value (114) advances by its size less one
          repetition's (M$DIS$LLL); inside a range the position moves
          on by the range's element size, else it is next and the range
          is closed.

          Not known from the original:
          - the names. }

        procedure link_and_update_offset(
            e: il_$node_ptr_t;
            next: integer32); options(val_param);
        var
          d: integer32;
        begin
          adjust_head_and_tail(e);
          if e^.xp[4]^.kind = 114 then
            d := e^.xl[5] - e^.xl[5] div e^.xp[4]^.xl[3]
          else
            d := 0;
          pos := pos + d;
          if pos < range_end then
            pos := pos + range^.xl[5]
          else begin
            pos := next;
            range_end := pos;
            range := nil;
          end;
        end;

      begin
        if thread = nil then begin
          sort_data_init_thread := thread;
          return;
        end;
        d := ddisp(thread);
        q := thread^.xp[1];
        n := 1;
        sorted := true;
        while q <> nil do begin
          n := n + 1;
          if sorted then begin
            i := ddisp(q);
            if (i < d) or (q^.kind = 221) then
              sorted := false;
            d := i;
          end;
          q := q^.xp[1];
        end;
        pas_$new(a, n * 8);
        if a = nil then
          cgerr_no_source(9, 0);
        q := thread;
        for i := 1 to n do begin
          a^[i].elem := q;
          a^[i].disp := ddisp(q);
          q := q^.xp[1];
        end;
        if not sorted and (n > 1) then
          qsort(1, n);
        i := 1;
        head := nil;
        tail := nil;
        range := nil;
        pos := a^[1].elem^.xl[3];
        range_end := pos;
        while i <= n do begin
          q := a^[i].elem;
          if (q^.kind = 221) and (range = nil) then begin
            range := a^[i].elem;
            pos := q^.xl[3];
            range_end := q^.xl[6];
            i := i + 1;
          end
          else if (pos <> q^.xl[3]) or (q^.kind = 221) then begin
            f := gspace32(24);
            f^.kind := 113;
            f^.xp[1] := nil;
            f^.xl[2] := range^.xl[2];
            f^.xl[3] := pos;
            f^.xl[4] := range^.xl[4];
            f^.xl[5] := range^.xl[5];
            link_and_update_offset(f, a^[i].elem^.xl[3]);
          end
          else begin
            if i < n then
              link_and_update_offset(q, a^[i + 1].elem^.xl[3])
            else
              link_and_update_offset(q, 0);
            i := i + 1;
          end;
        end;
        if range <> nil then begin
          f := gspace32(24);
          f^.kind := 113;
          f^.xp[1] := nil;
          f^.xl[2] := range^.xl[2];
          f^.xl[3] := pos;
          if pos <> range^.xl[6] then begin
            repeat_node := gspace(16);
            repeat_node^.kind := 114;
            repeat_node^.xl[1] := 0;
            repeat_node^.xl[3] := (range^.xl[6] - pos) div range^.xl[5] + 1;
            repeat_node^.xp[2] := range^.xp[4];
            f^.xp[4] := repeat_node;
            f^.xl[5] := range^.xl[5] * repeat_node^.xl[3];
          end
          else begin
            f^.xl[4] := range^.xl[4];
            f^.xl[5] := range^.xl[5];
          end;
          adjust_head_and_tail(f);
        end;
        tail^.xp[1] := nil;
        q := head;
        pas_$dispose(a, n * 8);
        sort_data_init_thread := q;
      end;

    begin
      e := sort_data_init_thread;
      while e <> nil do begin
        if e^.kind = 221 then
          cgerr_no_source(28, integer32(idntk(76, 'ELSE clause failure', 19)));
        t := e^.xp[2];
        k := -1;
        if t^.kind = 110 then begin
          if t^.xp2[14] <> nil then
            init_data(t^.xp2[14]^.xw[13], e^.xl[3] + t^.xl[3])
          else begin
            k := (ord(t^.xc[11]) & 16#F0) div 16;
            s := il_$node_ptr_t(il_184)^.xp[48];
            if k = 1 then
              init_data(s^.xw[20], e^.xl[3] + t^.xl[3] - s^.xl[4])
            else if k = 7 then
              init_data(s^.xw[20], e^.xl[3] + t^.xl[3] + s^.xl[5] - s^.xl[4])
            else
              k := -2;
          end;
        end
        else begin
          k := t^.xw[36];
          if (k = 1) or (k = 4) then begin
            s := t^.xp[5]^.xp[48];
            init_data(s^.xw[20], e^.xl[3] + t^.xl[14] - s^.xl[4]);
          end
          else if (k = 7) or (k = 8) then begin
            s := t^.xp[5]^.xp[48];
            init_data(s^.xw[20], e^.xl[3] + t^.xl[14] + s^.xl[5] - s^.xl[4]);
          end
          else if k = 10 then
            init_data(t^.xp[20]^.xw[13], e^.xl[3] + t^.xl[14])
          else
            k := -2;
        end;
        if k <> -2 then begin
          line := spos_$null_position;
          if e^.xp[2]^.kind = 109 then
            line := e^.xp[2]^.xw[4];
          c := e^.xp[4];
          if c^.kind = 114 then begin
            clist := c;
            repeat
              emit_constant(clist^.xp[2], clist^.xl[3], line);
              clist := clist^.xp[1];
            until clist = nil;
          end
          else if c^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then
            emit_constant(c, 1, line)
          else if c^.kind = 163 then
            emit_addr_con(c, 0)
          else if c^.kind = 195 then
            emit_abs_addr_con(c, 0)
          else if (c^.kind = 137) and (c^.xw[18] = 26) then
            emit_tree_node_const(c)
          else
            cgerr(20, line, idntk(76, 'initial_value', 13));
        end;
        e := e^.xp[1];
      end;
    end;

  begin
    if compressed and (block_start = 0) then begin
      block_start := uobj_obj_pos;
      uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
                 (-target_properties.p_90);
    end;
    sect_size := 0;
    nrelocs_5c58 := 0;
    npieces := 0;
    if kind = 0 then begin
      if cargs_$options.compress then
        direct := false
      else if cargs_$options.ncompress then
        direct := true
      else
        direct := false;
      sect_size := p^.xl[6] + p^.xl[5] - p^.xl[4];
      t := sect_size + target_properties.p_90 - 1;
      sect_size := t & (-target_properties.p_90);
      if with_data and not compressed then
        uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
                   (-target_properties.p_90);
      uobj_sect_start := uobj_obj_pos;
      if make_header then
        p^.xl[9] := uobj_obj_pos + uobj_addr_bias + data_5c54;
      data_5c4c := p^.xl[9];
      if with_data then
        if (p^.xp[3] = nil) and (p^.xl[7] = 0) then begin
          if strl_$eq(p^.xp[2]^.idnt_name, p^.xp[2]^.idnt_len, '.bss', 4) then begin
            p^.xl[9] := 0;
            goto done;
          end;
          start := 0;
          data_5c98 := data_5c98 + sect_size;
        end
        else begin
          start := uobj_sect_start;
          if direct then begin
            data_count := 0;
            uobj_direct_index := 0;
            uobj_direct_left := sect_size;
            uobj_direct_base := uobj_obj_pos;
            if uobj_direct_left > 163808 then
              uobj_obj_map := putobj(uobj_direct_base, 163808)
            else
              uobj_obj_map := putobj(uobj_direct_base, uobj_direct_left);
            npieces := npieces + 1;
          end;
          init_data(p^.xw[20], 0);
          ecb_cursor := p^.xp[3];
          if target_properties.p_7f and (ecb_cursor <> nil) then begin
            if ecb_cursor^.kind = 163 then
              n := (ecb_cursor^.xl[4] - p^.xl[4]) div 2
            else
              n := (ecb_cursor^.xl[27] - p^.xl[4]) div 2;
            for i := 1 to n do
              emit_16(0);
          end;
          while ecb_cursor <> nil do
            if ecb_cursor^.kind = 163 then begin
              emit_addr_con(ecb_cursor, 0);
              ecb_cursor := ecb_cursor^.xp[1];
            end
            else begin
              emit_ecb(ecb_cursor, p);
              ecb_cursor := ecb_cursor^.xp[29];
            end;
          data_sym := p^.xw[22];
          dump_data_init_thread(p^.xp[7]);
          if direct then begin
            freeobj(uobj_obj_map);
            uobj_obj_pos := uobj_obj_pos + sect_size;
          end;
          if data_count <> 0 then
            dump_data;
          align_data_position;
        end;
      p^.xl[12] := nrelocs_5c58;
    end
    else begin
      direct := cargs_$options.ncompress;
      sect_size := p^.xl[5];
      sect_size := (target_properties.p_90 + sect_size - 1) &
                   (-target_properties.p_90);
      if with_data and not compressed then
        uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
                   (-target_properties.p_90);
      uobj_sect_start := uobj_obj_pos;
      if make_header then
        p^.xl[11] := uobj_obj_pos + uobj_addr_bias + data_5c54;
      data_5c4c := p^.xl[11];
      if with_data then
        if p^.xp[9] = nil then begin
          start := 0;
          data_5c98 := data_5c98 + sect_size;
        end
        else begin
          start := uobj_sect_start;
          if direct then begin
            data_count := 0;
            uobj_direct_index := 0;
            uobj_direct_left := p^.xl[5];
            uobj_direct_base := uobj_obj_pos;
            if uobj_direct_left > 163808 then
              uobj_obj_map := putobj(uobj_direct_base, 163808)
            else
              uobj_obj_map := putobj(uobj_direct_base, uobj_direct_left);
            npieces := npieces + 1;
          end;
          data_sym := p^.xw[16];
          dump_data_init_thread(p^.xp[9]);
          if direct then begin
            freeobj(uobj_obj_map);
            uobj_obj_pos := uobj_obj_pos + p^.xl[5];
          end;
          if data_count <> 0 then
            dump_data;
          align_data_position;
        end;
      p^.xl[12] := nrelocs_5c58;
    end;
    if make_header then begin
      scnhdr_map := putobj(uobj_scnhdr_pos, 40);
      if kind = 0 then begin
        uobj_nsects := uobj_nsects + 1;
        p^.xw[23] := uobj_nsects;
        p^.xw[20] := uobj_nsyms;
        unix_put_obj_name(unix_objmod_$scnhdr_ptr_t(scnhdr_map)^.s_name, p^.xp[2]);
      end
      else begin
        p^.xw[13] := uobj_nsyms;
        uobj_nsects := uobj_nsects + 1;
        p^.xw[17] := uobj_nsects;
        h := scnhdr_map;
        underscore_names := true;
        unix_put_obj_name(h^.s_name, p^.xp[1]);
        underscore_names := false;
      end;
      h := scnhdr_map;
      if with_data and (sect_size > 0) then
        h^.s_scnptr := start
      else
        h^.s_scnptr := 0;
      h^.s_paddr := uobj_sect_start + uobj_addr_bias + data_5c54;
      h^.s_vaddr := h^.s_paddr;
      h^.s_size := sect_size;
      h^.s_relptr := 0;
      h^.s_lnnoptr := 0;
      h^.s_nreloc := 0;
      h^.s_nlnno := 0;
      h^.s_flags := [];
      if 2 in cargs_$options.flags_286 then
        h^.s_flags := h^.s_flags + [unix_objmod_$styp_zero];
      if kind = 0 then begin
        if 6 in cargs_$options.cpu then
          h^.s_flags := h^.s_flags + [unix_objmod_$styp_secalign2];
        if (p^.xp[3] = nil) and (p^.xl[7] = 0) then begin
          h^.s_flags := h^.s_flags + [unix_objmod_$styp_zero, unix_objmod_$styp_bss];
          data_5c6c := data_5c6c + sect_size;
          if with_data and direct then begin
            uobj_obj_pos := uobj_obj_pos + p^.xl[5];
            align_data_position;
          end;
        end
        else if with_data then
          h^.s_flags := h^.s_flags + [unix_objmod_$styp_data]
        else
          h^.s_flags := h^.s_flags + [unix_objmod_$styp_compressed, unix_objmod_$styp_bss];
      end
      else begin
        h^.s_flags := h^.s_flags + [unix_objmod_$styp_overlay];
        if (6 in cargs_$options.cpu) and (h^.s_size > 4) then
          h^.s_flags := h^.s_flags + [unix_objmod_$styp_secalign2];
        if p^.xp[9] = nil then begin
          h^.s_flags := h^.s_flags + [unix_objmod_$styp_zero, unix_objmod_$styp_bss];
          data_5c6c := data_5c6c + sect_size;
        end
        else if with_data then
          h^.s_flags := h^.s_flags + [unix_objmod_$styp_data]
        else
          h^.s_flags := h^.s_flags + [unix_objmod_$styp_compressed, unix_objmod_$styp_bss];
        if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 3 then
          if (ord(p^.xc[54]) > 127) or
             not (7 in cargs_$options.flags_286) then
            h^.s_flags := h^.s_flags + [unix_objmod_$styp_lookup];
      end;
      if uobj_reloc_scnhdr_pos = 0 then
        uobj_reloc_scnhdr_pos := uobj_scnhdr_pos;
      uobj_nsyms := uobj_nsyms + 1;
      uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
      freeobj(scnhdr_map);
    end;
    if not with_data then
      data_5c54 := data_5c54 + sect_size;
  done:
  end;

  { emit_rel - the relocation entries of section sect, its code at base.

    0x09D426, 0x82 bytes.  sect and base longwords by value.  Down the
    relocation list from +0x5D98 (the cursor): for each of sect, +0x5C88
    counts it and a 10-byte entry is written at the object offset
    (r_vaddr base + its +4 + +0x5D74, r_symndx, r_type 6 = R_DIR32).

    Not known from the original:
    - the names. }

  procedure emit_rel(
      sect: univ_ptr;
      base: integer32); options(val_param);
  var
    r: unix_objmod_$coff_reloc_ptr_t;
  begin
    while uobj_reloc_tail <> nil do begin
      if uobj_reloc_tail^.sect = sect then begin
        nrels.l := nrels.l + 1;
        r := putobj(uobj_obj_pos, 10);
        r^.r_vaddr := base + uobj_reloc_tail^.vaddr + uobj_addr_bias;
        r^.r_symndx := uobj_reloc_tail^.symndx;
        r^.r_type := unix_objmod_$r_dir32;
        uobj_obj_pos := uobj_obj_pos + 10;
        freeobj(r);
      end;
      uobj_reloc_tail := uobj_reloc_tail^.next;
    end;
  end;

  { line_numbers - the line number entries of section sect.

    0x09D4A8, 0x78 bytes.  sect a pointer by value.  While the line
    list (+0x5D84; 18-byte records: +0 the section, +4 the address, +8
    the symbol, +12 the line, +14 next) is at an entry of sect: +0x5D64
    counts it, a 6-byte entry (the symbol for line 0, else the address +
    +0x5D74; the line) at the object offset (kept in +0x5E20).

    Not known from the original:
    - the names. }

  procedure line_numbers(
      sect: univ_ptr); options(val_param);
  var
    l: unix_objmod_$lineno_ptr_t;
  begin
    if uobj_lnno_list <> nil then
      while uobj_lnno_list^.sect = sect do begin
        uobj_nlnnos.l := uobj_nlnnos.l + 1;
        l := putobj(uobj_obj_pos, 6);
        lnno_map := l;
        if uobj_lnno_list^.line = 0 then
          l^.l_addr := uobj_lnno_list^.symndx
        else
          l^.l_addr := uobj_lnno_list^.addr + uobj_addr_bias;
        l^.l_lnno := uobj_lnno_list^.line;
        uobj_obj_pos := uobj_obj_pos + 6;
        freeobj(l);
        uobj_lnno_list := uobj_lnno_list^.next;
        if uobj_lnno_list = nil then
          exit;
      end;
  end;

  { change_name_lower_case - id's characters into s, folded to lower
    case unless -U.

    0x09D520, 0x78 bytes.  id a pointer, s by address.

    Not known from the original:
    - the names. }

  procedure change_name_lower_case(
      id: il_$node_ptr_t;
      out s: univ unix_objmod_$bytes_t); options(val_param);
  var
    i: integer32;
    c: char;
  begin
    if not cargs_$options.u then
      for i := 1 to id^.idnt_len do begin
        c := id^.idnt_name[i];
        if (c >= 'A') and (c <= 'Z') then
          s[i] := chr(ord(c) + 32)
        else
          s[i] := c;
      end
    else
      for i := 1 to id^.idnt_len do
        s[i] := id^.idnt_name[i];
  end;
  { output_misc_sections - the .sri, .mir and .inlib sections.

    0x09D598, 0x722 bytes (a 4160-byte frame: the module's name, 4096
    characters, at -4104).  .sri (from +0x5D08): a count (+0x5DE8) and
    8-byte entries (kind, rule, value): kind 1 rule 4 (or) for each bit
    of il_c4 (+0x5DD8, bit 0 cleared first; bits 1, 2, 3, 4, 5 and 8
    give 1, 2, 4, 16#20000, 16#10000, 16#8000, each bit cleared as it
    is used); with -XRS kind 2 rule 4 16#20000; kind 2 rule 4 16#40000;
    for #pragma HP_STANDARD (+0x5DD0) kind 8 rule 4 with its bits; for
    a class 3 module (il_184's +377 bits 6..4) whose loader knows
    EV_$GET_VAR and C_$DECODE_VERSION (kg_$lookup) kind 3 rule 8 the
    system type (2.2 after a #systype of version 2 (+0x5E16), else the
    COMPILESYSTYPE or SYSTYPE variable decoded, else 0.2) and kind 5
    rule 8 the -RUNTYPE one (the same words unless -RUNTYPE is given).
    Its header ('.sri', number +0x5DF6, flags STYP_INFO).  .mir (from
    +0x5D04): two records, the maker's (kind 1, 14 bytes: cargs_$2bd2,
    the timestamp, the version string's offset in the string table) and
    the module name's (kind 2, 8 bytes: the name of il_184's routine,
    its +4 for kind 106, il_17c for a class 3 kind 106, its +4 for any
    class 3; folded by change_name_lower_case); header '.mir' (number
    +0x5DF4).  .inlib (from +0x5D00, else 0) with -INLIB libraries:
    the count and a 16-byte entry each (zeros and the name's offset in
    the string table); header '.inlib' (+0x5DEE, flags STYP_LIB).  Each
    section is padded to 4 from its start; the header flags come from
    16-byte constants after the routine.

    Not known from the original:
    - the names. }

  procedure output_misc_sections;
  var
    cnt: unix_objmod_$long_ptr_t;
    e: unix_objmod_$sri_ptr_t;
    m: unix_objmod_$mir_ptr_t;
    l: unix_objmod_$inlib_ptr_t;
    h: unix_objmod_$scnhdr_ptr_t;
    r: il_$node_ptr_t;
    s: il_$node_ptr_t;
    i: integer32;
    j: integer32;
    name: array [1..4096] of char;
    ok: boolean;
  begin
    sri_start := uobj_obj_pos;
    nsri := 0;
    cnt := putobj(uobj_obj_pos, 4);
    uobj_obj_pos := uobj_obj_pos + 4;
    hp_bits := il_c4;
    if odd(hp_bits) then
      hp_bits := hp_bits & ~1;
    while hp_bits <> 0 do begin
      nsri := nsri + 1;
      e := putobj(uobj_obj_pos, 8);
      uobj_obj_pos := uobj_obj_pos + 8;
      e^.kind_rule := 16#00010004;
      if (hp_bits & 2) <> 0 then begin
        e^.value := 1;
        hp_bits := hp_bits & ~2;
      end
      else if (hp_bits & 4) <> 0 then begin
        e^.value := 2;
        hp_bits := hp_bits & ~4;
      end
      else if (hp_bits & 8) <> 0 then begin
        e^.value := 4;
        hp_bits := hp_bits & ~8;
      end
      else if (hp_bits & 16) <> 0 then begin
        e^.value := 16#20000;
        hp_bits := hp_bits & ~16;
      end
      else if (hp_bits & 32) <> 0 then begin
        e^.value := 16#10000;
        hp_bits := hp_bits & ~32;
      end
      else if (hp_bits & 16#100) <> 0 then begin
        e^.value := 16#8000;
        hp_bits := hp_bits & ~16#100;
      end;
      freeobj(e);
    end;
    if cargs_$options.xrs then begin
      nsri := nsri + 1;
      e := putobj(uobj_obj_pos, 8);
      uobj_obj_pos := uobj_obj_pos + 8;
      e^.kind_rule := 16#00020004;
      e^.value := 16#20000;
      freeobj(e);
    end;
    nsri := nsri + 1;
    e := putobj(uobj_obj_pos, 8);
    uobj_obj_pos := uobj_obj_pos + 8;
    e^.kind_rule := 16#00020004;
    e^.value := 16#40000;
    freeobj(e);
    if uobj_hp_standard <> 0 then begin
      nsri := nsri + 1;
      e := putobj(uobj_obj_pos, 8);
      uobj_obj_pos := uobj_obj_pos + 8;
      e^.kind_rule := 16#00080004;
      e^.value := uobj_hp_standard;
      freeobj(e);
    end;
    if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 3 then
      if (kg_$lookup('EV_$GET_VAR                     ') <> nil) and
         (kg_$lookup('C_$DECODE_VERSION               ') <> nil) then begin
        nsri := nsri + 1;
        e := putobj(uobj_obj_pos, 8);
        uobj_obj_pos := uobj_obj_pos + 8;
        e^.kind_rule := 16#00030008;
        if uobj_systype_2 then begin
          systype_major := 2;
          systype_minor := 2;
        end
        else if not (ev_$get_var('COMPILESYSTYPE', 14, systype_value,
                                 systype_len) and
                     c_$decode_version(systype_value^, systype_len,
                                       systype_major, systype_minor)) then
          if not (ev_$get_var('SYSTYPE', 7, systype_value, systype_len) and
                  c_$decode_version(systype_value^, systype_len,
                                    systype_major, systype_minor)) then begin
            systype_major := 0;
            systype_minor := 2;
          end;
        e^.major := systype_major;
        e^.minor := systype_minor;
        freeobj(e);
        nsri := nsri + 1;
        e := putobj(uobj_obj_pos, 8);
        uobj_obj_pos := uobj_obj_pos + 8;
        e^.kind_rule := 16#00050008;
        if cargs_$options.runtype.length <> 0 then
          ok := c_$decode_version(cargs_$options.runtype.body,
                            cargs_$options.runtype.length,
                            systype_major, systype_minor);
        e^.major := systype_major;
        e^.minor := systype_minor;
        freeobj(e);
      end;
    cnt^ := nsri & 16#FFFF;
    freeobj(cnt);
    scnhdr_map := putobj(uobj_scnhdr_pos, 40);
    uobj_nsects := uobj_nsects + 1;
    uobj_sri_sect := uobj_nsects;
    if ((uobj_obj_pos - sri_start) & 3) <> 0 then
      uobj_obj_pos := (uobj_obj_pos & (-4)) + 4;
    h := scnhdr_map;
    s := strtk('.sri', 4);
    unix_put_obj_name(h^.s_name, s);
    h^.s_paddr := 0;
    h^.s_vaddr := 0;
    h^.s_size := uobj_obj_pos - sri_start;
    h^.s_scnptr := sri_start;
    h^.s_relptr := 0;
    h^.s_lnnoptr := 0;
    h^.s_nreloc := 0;
    h^.s_nlnno := 0;
    h^.s_flags := [unix_objmod_$styp_info];
    uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
    freeobj(scnhdr_map);

    mir_start := uobj_obj_pos;
    cnt := putobj(uobj_obj_pos, 4);
    uobj_obj_pos := uobj_obj_pos + 4;
    m := putobj(uobj_obj_pos, 14);
    uobj_obj_pos := uobj_obj_pos + 14;
    m^.kind_size := 16#0001000E;
    m^.version := cargs_$2bd2;
    m^.creation_time := cargs_$timestamp;
    m^.name_offset := temp_string_count + 4;
    for i := 1 to cargs_$version_length do
      write_byte_to_temp_string_table(cargs_$version_string[i]);
    write_byte_to_temp_string_table(chr(0));
    freeobj(m);
    m := putobj(uobj_obj_pos, 8);
    uobj_obj_pos := uobj_obj_pos + 8;
    m^.kind_size := 16#00020008;
    m^.module_name_offset := temp_string_count + 4;
    r := il_184;
    if r^.kind = 106 then
      if (ord(r^.xc[377]) & 16#70) div 16 = 3 then
        r := il_17c
      else
        r := r^.xp[1];
    if (ord(il_$node_ptr_t(il_184)^.xc[377]) & 16#70) div 16 = 3 then
      r := il_$node_ptr_t(il_184)^.xp[1];
    change_name_lower_case(r^.xp[74], name);
    for i := 1 to r^.xp[74]^.idnt_len do
      write_byte_to_temp_string_table(name[i]);
    write_byte_to_temp_string_table(chr(0));
    freeobj(m);
    cnt^ := 2;
    freeobj(cnt);
    if ((uobj_obj_pos - mir_start) & 3) <> 0 then
      uobj_obj_pos := (uobj_obj_pos & (-4)) + 4;
    scnhdr_map := putobj(uobj_scnhdr_pos, 40);
    h := scnhdr_map;
    s := strtk('.mir', 4);
    unix_put_obj_name(h^.s_name, s);
    h^.s_paddr := 0;
    h^.s_vaddr := 0;
    h^.s_size := uobj_obj_pos - mir_start;
    h^.s_scnptr := mir_start;
    h^.s_relptr := 0;
    h^.s_lnnoptr := 0;
    h^.s_nreloc := 0;
    h^.s_nlnno := 0;
    h^.s_flags := [unix_objmod_$styp_info];
    uobj_nsects := uobj_nsects + 1;
    uobj_mir_sect := uobj_nsects;
    uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
    freeobj(scnhdr_map);

    if inc_list_ninlib <> 0 then begin
      inlib_start := uobj_obj_pos;
      cnt := putobj(uobj_obj_pos, 4);
      cnt^ := inc_list_ninlib & 16#FFFF;
      freeobj(cnt);
      uobj_obj_pos := uobj_obj_pos + 4;
      for i := 1 to inc_list_ninlib do begin
        l := putobj(uobj_obj_pos, 16);
        l^.unused_0 := 0;
        l^.unused_4 := 0;
        l^.unused_8 := 0;
        l^.name_ptr := temp_string_count + 4;
        for j := 1 to inc_list_inlibs[i]^.length do
          write_byte_to_temp_string_table(inc_list_inlibs[i]^.body[j]);
        write_byte_to_temp_string_table(chr(0));
        uobj_obj_pos := uobj_obj_pos + 16;
        freeobj(l);
      end;
      if ((uobj_obj_pos - inlib_start) & 3) <> 0 then
        uobj_obj_pos := (uobj_obj_pos & (-4)) + 4;
      scnhdr_map := putobj(uobj_scnhdr_pos, 40);
      uobj_nsects := uobj_nsects + 1;
      uobj_inlib_sect := uobj_nsects;
      h := scnhdr_map;
      s := strtk('.inlib', 6);
      unix_put_obj_name(h^.s_name, s);
      h^.s_paddr := 0;
      h^.s_vaddr := 0;
      h^.s_size := uobj_obj_pos - inlib_start;
      h^.s_scnptr := inlib_start;
      h^.s_relptr := 0;
      h^.s_lnnoptr := 0;
      h^.s_nreloc := 0;
      h^.s_nlnno := 0;
      h^.s_flags := [unix_objmod_$styp_lib];
      uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
      freeobj(scnhdr_map);
    end
    else
      inlib_start := 0;
  end;

  { create_tv_reloc_recs - the relocation entries of the .aptv
    section: a count entry (r_type 512) for 65535 or more, then one
    R_DIR32 at each `jmp''s address (+2) against its target's symbol.

    0x09DD42, 0xBC bytes.

    Not known from the original:
    - the names. }

  procedure create_tv_reloc_recs;
  var
    i: integer32;
    t: il_$node_ptr_t;
    r: unix_objmod_$coff_reloc_ptr_t;
  begin
    i := 0;
    if uobj_ntvs.l >= 65535 then begin
      r := putobj(uobj_obj_pos, 10);
      r^.r_vaddr := uobj_ntvs.l + 1;
      r^.r_symndx := i;
      r^.r_type := unix_objmod_$r_count;
      uobj_obj_pos := uobj_obj_pos + 10;
      freeobj(r);
    end;
    t := il_128;
    while t <> nil do begin
      r := putobj(uobj_obj_pos, 10);
      r^.r_vaddr := tv_start + uobj_addr_bias + i * 6 + data_5c54 + 2;
      r^.r_symndx := get_reloc_symndx(t^.xp[2], 0);
      r^.r_type := unix_objmod_$r_dir32;
      i := i + 1;
      uobj_obj_pos := uobj_obj_pos + 10;
      freeobj(r);
      t := t^.xp[1];
    end;
  end;
  { output_data_info - everything after the headers but the symbols:
    the code, the exception and unwind tables, the data, the .rwdi,
    debugging, .sri, .mir and .inlib sections, the relocations and line
    numbers, the fixups.

    0x09DDFE, 0x1224 bytes (a 120-byte frame).  In order:
    - the counters and positions cleared; the unwind form (-0x3C) from
      cargs +0x1E9B bit 6 (-NEW_UNWIND); the offset aligned to
      target_properties +0x90; +0x5D5C the code's address (the offset +
      the target's base, A5 +0x10 indexed by +0x5DD4), emit +0x114 the
      offset; +0x5D74 the base; coff_syms's number_coff_syms; direct
      output; the code sections with contents numbered (+66).
    - With routines (il_d4): perfstart(40); the target (-0x3A) from
      target_properties +0x10 (0..3; else reported, 'UNIX_OBJMOD_$
      output_data_info: unknown ISP'); gen_unwind_$begin_compilation of
      the unwind section (+0x5D94); with target_properties +0x7F the
      code by bin_$emit_compilation_pure_text (gen_debug begun first
      with mode [1, 15] under -DB), its size (emit +0x108) added, and a
      header for each code section with code (+20): its name, address
      (+16 + +0x5D5C, kept in +56), size (+12), file offset (the
      address less the base), flags 16#10200020; else outcode (gen_debug
      begun with [1, 7, 15]); perfstop(40).
    - The exception table (il_13c): gen_unwind_$dump_exception_table at
      the aligned offset, its section '.exception_table' (number
      +0x5DEC; text; cpu element 6 bit 28), its address in +0x5C40's
      +56 and +0x5D2E in its +64.  +0x5C24 the next address.
    - The unwind table (with routines): gen_unwind_$dump_unwind_table
      (the exception section's +44 symbol, +0x5D2C and +0x5C40's +56, or
      three -1), its section '.unwind' (+0x5DF8).
    - +0x5D74 moved to the data's alignment (A5 +0 indexed: M$OIS$LLL
      twice); the data sections (il_110, kind 0) and the commons
      (il_118, kind 2) by data_sections (with data under -NCOMPRESS
      without -COMPRESS for the first, under -NCOMPRESS for the second,
      headers made), the data's address (+0x5C94) and base fixed at the
      first; the transfer vectors under -AC/-ABS; the .bss of il_114
      (+0x5C50, header number +0x5DFE, its size from a 24-byte
      constant).
    - Without -NCOMPRESS the compressed initializations: each data
      section and common again (no header) into '.rwdi' (the block
      section +0x5C60 made once, idntk(76, '.rwdi')), header +0x5CF8,
      number +0x5DF2, flags 16#10000.
    - With routines and -DB: gen_debug_$end_pass, ready_output and
      end_compilation, '.lines' (+0x5DF0, 16#30000), else +0x5C20 and
      the number 0.
    - With -DB: under -DBS/-DBA debug_sym_dmp_$add_loc_info and each
      symbols section of +0x5C30 (+8) by
      debug_sym_dmp_$dump_symbols_section, named by its +4 ('.symbols'
      is the main one: +0x5D90, +0x5DFA, +0x5C28; the others overlay);
      then debug_sym_dmp_$block_dmp, '.blocks' (+0x5DFC) and
      debug_sym_dmp_$finalize.
    - output_misc_sections.
    - The relocations (the section headers from +0x5C70, +0x5DA8 the
      one being filled): each code section's (its count +68), the
      exception section's place, the unwind section's (+0x5D4C; the
      record disposed, 6156 bytes), +0x5D74 restored, the data sections'
      and commons' (+48) under -NCOMPRESS, the transfer vectors', the
      .bss's place, the .rwdi's (+0x5C68), with -DB the debugging
      sections' places and the symbols' (+0x5D50; disposed, 4 bytes).
      A count of 65535 or more gets a count entry and the header 65535.
    - gen_proc_relocs over the code sections, first for the externals,
      then patching (with the header position +0x5D78, moved on);
      gen_data_relocs; under -DBS/-DBA with lines (+0x5D88) and without
      -NCLINES the line numbers of each code section with code.

    Not known from the original:
    - the names; the locals (the base kept in D2 through the data
      sections). }

  procedure output_data_info;
  var
    s: il_$node_ptr_t;
    h: unix_objmod_$scnhdr_ptr_t;
    r: unix_objmod_$coff_reloc_ptr_t;
    hdr: unix_objmod_$reloc_ptr_t;
    cur: unix_objmod_$reloc_ptr_t;
    start: integer32;
    base: integer32;
    size: integer32;
    a: integer32;
    m: integer32;
    tgt: integer;
    unw: integer;
    db: integer;
    w: integer;
    is_main: boolean;
    p1: integer32;
    p3: integer32;
  begin
    data_repeat := 1;
    rel_ptr := 0;
    uobj_code_size := 0;
    data_5c9c := 0;
    data_5c98 := 0;
    code_addr := 0;
    data_start := 0;
    uobj_reloc_head := nil;
    uobj_lnno_head := nil;
    first_sym := uobj_nsyms;
    scnhdr_base := uobj_scnhdr_pos;
    uobj_addr_bias := 0;
    block_sect := nil;
    compressed := false;
    nblock_relocs := 0;
    block_start := 0;
    data_5c54 := 0;
    data_5c50 := 0;
    data_addr := 0;
    if cargs_$options.unwind = 0 then
      unw := 0
    else
      unw := 1;
    uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
               (-target_properties.p_90);
    code_addr := uobj_obj_pos + target_bases[target_index];
    emit_108.e114 := uobj_obj_pos;
    data_count := 0;
    uobj_addr_bias := target_bases[target_index];
    number_coff_syms;
    uobj_direct_index := 0;
    direct := true;
    sect_cursor := il_10c;
    while sect_cursor <> nil do begin
      if sect_cursor^.xl[3] <> 0 then begin
        uobj_nsects := uobj_nsects + 1;
        sect_cursor^.xw[33] := uobj_nsects;
      end;
      sect_cursor := sect_cursor^.xp[1];
    end;
    if il_d4 <> nil then begin
      perfstart(40);
      case target_properties.p_10 of
        0: tgt := 0;
        1: tgt := 1;
        2: tgt := 2;
        3: tgt := 3;
        otherwise
          cgerr_no_source(28, integer32(strtk(
            'UNIX_OBJMOD_$output_data_info: unknown ISP', 42)));
      end;
      gen_unwind_$begin_compilation(sect_5d94, tgt);
      if target_properties.p_7f then begin
        if cargs_$options.db <> 0 then begin
          gen_debug_$begin_compilation([1, 15]);
          gen_debug_$begin_pass;
        end;
        bin_$emit_compilation_pure_text;
        uobj_obj_pos := uobj_obj_pos + emit_108.e108;
        uobj_code_size := emit_108.e108;
        sect_cursor := il_10c;
        while sect_cursor <> nil do begin
          if sect_cursor^.xl[5] <> 0 then begin
            scnhdr_map := putobj((sect_cursor^.xw[33] - 1) * 40 + uobj_scnhdr_pos, 40);
            h := scnhdr_map;
            unix_put_obj_name(h^.s_name, sect_cursor^.xp[2]);
            h^.s_paddr := sect_cursor^.xl[4] + code_addr;
            h^.s_vaddr := h^.s_paddr;
            h^.s_size := sect_cursor^.xl[3];
            h^.s_scnptr := h^.s_paddr - target_bases[target_index];
            h^.s_relptr := 0;
            h^.s_lnnoptr := 0;
            h^.s_nreloc := 0;
            h^.s_nlnno := 0;
            h^.s_flags := [unix_objmod_$styp_text, unix_objmod_$styp_instruction,
                           unix_objmod_$styp_secalign2];
            sect_cursor^.xl[14] := h^.s_paddr;
            freeobj(scnhdr_map);
          end;
          sect_cursor := sect_cursor^.xp[1];
        end;
        uobj_scnhdr_pos := uobj_scnhdr_pos + uobj_nsects * 40;
      end
      else begin
        if (il_d4 <> nil) and (cargs_$options.db <> 0) then begin
          gen_debug_$begin_compilation([1, 7, 15]);
          gen_debug_$begin_pass;
        end;
        outcode;
      end;
      perfstop(40);
    end;
    start := (target_properties.p_90 + uobj_obj_pos - 1) &
             (-target_properties.p_90);
    uobj_obj_pos := start;
    if il_13c <> 0 then begin
      uobj_obj_pos := uobj_obj_pos + gen_unwind_$dump_exception_table(start, 2);
      uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
                 (-target_properties.p_90);
      scnhdr_map := putobj(uobj_scnhdr_pos, 40);
      uobj_nsects := uobj_nsects + 1;
      uobj_exception_sect := uobj_nsects;
      h := scnhdr_map;
      s := strtk('.exception_table', 16);
      unix_put_obj_name(h^.s_name, s);
      h^.s_paddr := start + uobj_addr_bias;
      h^.s_vaddr := start + uobj_addr_bias;
      h^.s_size := uobj_obj_pos - start;
      h^.s_scnptr := start;
      h^.s_relptr := 0;
      h^.s_lnnoptr := 0;
      h^.s_nreloc := 0;
      h^.s_nlnno := 0;
      h^.s_flags := [unix_objmod_$styp_text];
      if 6 in cargs_$options.cpu then
        h^.s_flags := h^.s_flags + [unix_objmod_$styp_secalign2];
      exc_text^.xl[14] := h^.s_paddr;
      exc_text^.xw[32] := uobj_exc_symndx.low;
      uobj_code_size := uobj_code_size + (uobj_obj_pos - start);
      uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
      freeobj(scnhdr_map);
    end;
    uobj_unwind_addr := uobj_obj_pos + uobj_addr_bias;
    base := uobj_obj_pos;
    if il_d4 <> nil then
      if il_13c <> 0 then
        uobj_obj_pos := uobj_obj_pos + gen_unwind_$dump_unwind_table(base, 2,
          exc_data^.xw[22], uobj_exc_symndx.l, exc_text^.xl[14], unw)
      else
        uobj_obj_pos := uobj_obj_pos + gen_unwind_$dump_unwind_table(base, 2,
          -1, -1, -1, unw);
    uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
               (-target_properties.p_90);
    scnhdr_map := putobj(uobj_scnhdr_pos, 40);
    uobj_nsects := uobj_nsects + 1;
    uobj_unwind_sect := uobj_nsects;
    h := scnhdr_map;
    s := strtk('.unwind', 7);
    unix_put_obj_name(h^.s_name, s);
    h^.s_paddr := base + uobj_addr_bias;
    h^.s_vaddr := base + uobj_addr_bias;
    h^.s_size := uobj_obj_pos - base;
    h^.s_scnptr := base;
    h^.s_relptr := 0;
    h^.s_lnnoptr := 0;
    h^.s_nreloc := 0;
    h^.s_nlnno := 0;
    h^.s_flags := [unix_objmod_$styp_text];
    if 6 in cargs_$options.cpu then
      h^.s_flags := h^.s_flags + [unix_objmod_$styp_secalign2];
    uobj_code_size := uobj_code_size + (uobj_obj_pos - base);
    uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
    freeobj(scnhdr_map);
    a := uobj_obj_pos + uobj_addr_bias - 1;
    m := target_aligns[target_index];
    uobj_addr_bias := a + (target_aligns[target_index] - a mod m) mod m;
    sect_cursor := il_110;
    while sect_cursor <> nil do begin
      if data_start = 0 then begin
        uobj_addr_bias := uobj_addr_bias - uobj_obj_pos;
        base := uobj_addr_bias;
        data_start := base + uobj_obj_pos;
      end;
      uobj_sect_start := 0;
      uobj_pad_from := 0;
      ndirectives := 0;
      data_count := 0;
      data_section := sect_cursor;
      if not cargs_$options.compress and cargs_$options.ncompress then
        data_sections(sect_cursor, 0, true, true)
      else
        data_sections(sect_cursor, 0, false, true);
      sect_cursor := sect_cursor^.xp[1];
    end;
    sect_cursor := il_118;
    while sect_cursor <> nil do begin
      if data_start = 0 then begin
        uobj_addr_bias := uobj_addr_bias - uobj_obj_pos;
        base := uobj_addr_bias;
        data_start := base + uobj_obj_pos;
      end;
      uobj_sect_start := 0;
      uobj_pad_from := 0;
      ndirectives := 0;
      data_count := 0;
      data_section := sect_cursor;
      data_sections(sect_cursor, 2, cargs_$options.ncompress, true);
      sect_cursor := sect_cursor^.xp[2];
    end;
    if data_start = 0 then begin
      uobj_addr_bias := uobj_addr_bias - uobj_obj_pos;
      base := uobj_addr_bias;
      data_start := base + uobj_obj_pos;
    end;
    if 7 in cargs_$options.flags_286 then
      write_transfer_vectors;
    if il_114 <> 0 then begin
      data_5c50 := il_114;
      data_5c50 := (data_5c50 + target_properties.p_90 - 1) &
                   (-target_properties.p_90);
      data_5c98 := data_5c98 + data_5c50;
      uobj_sect_start := uobj_obj_pos;
      if uobj_reloc_scnhdr_pos = 0 then
        uobj_reloc_scnhdr_pos := uobj_scnhdr_pos;
      scnhdr_map := putobj(uobj_scnhdr_pos, 40);
      uobj_nsects := uobj_nsects + 1;
      uobj_bss_sect := uobj_nsects;
      h := scnhdr_map;
      s := strtk('.bss', 4);
      unix_put_obj_name(h^.s_name, s);
      h^.s_paddr := uobj_sect_start + uobj_addr_bias + data_5c54;
      h^.s_vaddr := h^.s_paddr;
      h^.s_size := 0;
      h^.s_scnptr := 0;
      h^.s_relptr := 0;
      h^.s_lnnoptr := 0;
      h^.s_nreloc := 0;
      h^.s_nlnno := 0;
      h^.s_flags := [unix_objmod_$styp_bss];
      uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
      freeobj(scnhdr_map);
      data_5c6c := data_5c6c + data_5c50;
    end;
    start := uobj_obj_pos;
    if not cargs_$options.ncompress then begin
      sect_cursor := il_110;
      while sect_cursor <> nil do begin
        if block_sect = nil then begin
          block_sect := idntk(76, '.rwdi', 5);
          data_section := block_sect;
        end;
        compressed := true;
        uobj_pad_from := 0;
        uobj_sect_start := 0;
        ndirectives := 0;
        data_count := 0;
        data_addr := 0;
        block_node := sect_cursor;
        data_sections(sect_cursor, 0, true, false);
        sect_cursor := sect_cursor^.xp[1];
      end;
      sect_cursor := il_118;
      while sect_cursor <> nil do begin
        if block_sect = nil then begin
          block_sect := idntk(76, '.rwdi', 5);
          data_section := block_sect;
        end;
        compressed := true;
        uobj_pad_from := 0;
        uobj_sect_start := 0;
        ndirectives := 0;
        data_count := 0;
        data_addr := 0;
        block_node := sect_cursor;
        data_sections(sect_cursor, 2, true, false);
        sect_cursor := sect_cursor^.xp[2];
      end;
    end;
    if uobj_reloc_scnhdr_pos = 0 then
      uobj_reloc_scnhdr_pos := uobj_scnhdr_pos;
    rwdi_scnhdr_pos := uobj_scnhdr_pos;
    scnhdr_map := putobj(uobj_scnhdr_pos, 40);
    h := scnhdr_map;
    s := strtk('.rwdi', 5);
    unix_put_obj_name(h^.s_name, s);
    h^.s_paddr := start + uobj_addr_bias + data_5c54 + data_5c50;
    h^.s_vaddr := h^.s_paddr;
    h^.s_size := uobj_obj_pos - start;
    if start = uobj_obj_pos then
      h^.s_scnptr := 0
    else
      h^.s_scnptr := start;
    h^.s_relptr := 0;
    h^.s_lnnoptr := 0;
    h^.s_nreloc := 0;
    h^.s_nlnno := 0;
    h^.s_flags := [unix_objmod_$styp_relocated_not_loaded];
    uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
    freeobj(scnhdr_map);
    uobj_nsects := uobj_nsects + 1;
    uobj_rwdi_sect := uobj_nsects;
    compressed := false;
    uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
               (-target_properties.p_90);
    if (il_d4 <> nil) and (cargs_$options.db <> 0) then begin
      uobj_lines_addr := uobj_obj_pos + uobj_addr_bias + data_5c54 + data_5c50;
      sect_from := uobj_obj_pos;
      gen_debug_$end_pass(p1, size, p1);
      gen_debug_$ready_output(p1, uobj_obj_pos, p1);
      gen_debug_$end_compilation;
      uobj_obj_pos := uobj_obj_pos + size;
      uobj_pad_from := uobj_obj_pos;
      uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
                 (-target_properties.p_90);
      scnhdr_map := putobj(uobj_scnhdr_pos, 40);
      uobj_nsects := uobj_nsects + 1;
      uobj_lines_sect := uobj_nsects;
      h := scnhdr_map;
      s := strtk('.lines', 6);
      unix_put_obj_name(h^.s_name, s);
      h^.s_paddr := sect_from + uobj_addr_bias + data_5c54 + data_5c50;
      h^.s_vaddr := h^.s_paddr;
      h^.s_size := uobj_obj_pos - sect_from;
      h^.s_scnptr := sect_from;
      h^.s_relptr := 0;
      h^.s_lnnoptr := 0;
      h^.s_nreloc := 0;
      h^.s_nlnno := 0;
      h^.s_flags := [unix_objmod_$styp_relocated_not_loaded, unix_objmod_$styp_debug];
      uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
      freeobj(scnhdr_map);
    end
    else begin
      uobj_lines_addr := 0;
      uobj_lines_sect := 0;
    end;
    db := cargs_$options.db;
    if db <> 0 then begin
      if db >= 2 then begin
        debug_sym_dmp_$add_loc_info;
        s := symbols_sections;
        while s <> nil do begin
          sect_from := uobj_obj_pos;
          s^.xl[11] := sect_from + uobj_addr_bias + data_5c54 + data_5c50;
          debug_sym_dmp_$dump_symbols_section(s, uobj_obj_pos, addr(uobj_obj_pos));
          symbols_scnhdr_pos := uobj_scnhdr_pos;
          symbols_symndx := uobj_nsyms;
          uobj_nsyms := uobj_nsyms + 1;
          uobj_pad_from := uobj_obj_pos;
          uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
                     (-target_properties.p_90);
          s^.xl[5] := uobj_obj_pos - sect_from;
          scnhdr_map := putobj(uobj_scnhdr_pos, 40);
          uobj_nsects := uobj_nsects + 1;
          s^.xw[17] := uobj_nsects;
          if idntk(76, '.symbols', 8) = s^.xp[1] then begin
            is_main := false;
            main_symbols := s;
            uobj_symbols_sect := uobj_nsects;
            uobj_symbols_addr := sect_from + uobj_addr_bias + data_5c54 + data_5c50;
          end
          else
            is_main := true;
          h := scnhdr_map;
          unix_put_obj_name(h^.s_name,
                            strtk(s^.xp[1]^.idnt_name, s^.xp[1]^.idnt_len));
          h^.s_paddr := sect_from + uobj_addr_bias + data_5c54 + data_5c50;
          h^.s_vaddr := h^.s_paddr;
          h^.s_size := uobj_obj_pos - sect_from;
          h^.s_scnptr := sect_from;
          h^.s_relptr := 0;
          h^.s_lnnoptr := 0;
          h^.s_nreloc := 0;
          h^.s_nlnno := 0;
          h^.s_flags := [unix_objmod_$styp_relocated_not_loaded, unix_objmod_$styp_debug];
          if is_main then
            h^.s_flags := h^.s_flags + [unix_objmod_$styp_overlay];
          uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
          freeobj(scnhdr_map);
          s := s^.xp[2];
        end;
      end
      else
        uobj_symbols_addr := 0;
      start := uobj_obj_pos;
      debug_sym_dmp_$block_dmp(start, addr(uobj_obj_pos));
      uobj_pad_from := uobj_obj_pos;
      uobj_obj_pos := (target_properties.p_90 + uobj_obj_pos - 1) &
                 (-target_properties.p_90);
      data_5c9c := data_5c9c + (uobj_obj_pos - uobj_pad_from);
      scnhdr_map := putobj(uobj_scnhdr_pos, 40);
      uobj_nsects := uobj_nsects + 1;
      uobj_blocks_sect := uobj_nsects;
      h := scnhdr_map;
      s := strtk('.blocks', 7);
      unix_put_obj_name(h^.s_name, s);
      h^.s_paddr := start + uobj_addr_bias + data_5c54 + data_5c50;
      h^.s_vaddr := h^.s_paddr;
      h^.s_size := uobj_obj_pos - start;
      h^.s_scnptr := start;
      h^.s_relptr := 0;
      h^.s_lnnoptr := 0;
      h^.s_nreloc := 0;
      h^.s_nlnno := 0;
      h^.s_flags := [unix_objmod_$styp_relocated_not_loaded, unix_objmod_$styp_debug];
      uobj_scnhdr_pos := uobj_scnhdr_pos + 40;
      freeobj(scnhdr_map);
      debug_sym_dmp_$finalize;
    end;
    output_misc_sections;

    uobj_addr_bias := target_bases[target_index];
    uobj_reloc_tail := uobj_reloc_head;
    hdr := uobj_reloc_head;
    uobj_reloc_scnhdr_pos := scnhdr_base;
    s := il_10c;
    while s <> nil do begin
      uobj_reloc_tail := uobj_reloc_head;
      nrels.l := 0;
      rel_ptr := uobj_obj_pos;
      if s^.xl[17] >= 65535 then begin
        r := putobj(uobj_obj_pos, 10);
        r^.r_vaddr := s^.xl[17] + 1;
        r^.r_symndx := 0;
        r^.r_type := unix_objmod_$r_count;
        uobj_obj_pos := uobj_obj_pos + 10;
        freeobj(r);
      end;
      emit_rel(s, 0);
      if nrels.l <> 0 then begin
        if s^.xl[17] >= 65535 then
          nrels.l := 65535;
        add_to_section_header(rel_ptr, true, nrels.low);
      end;
      if s^.xl[3] <> 0 then
        uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
      s := s^.xp[1];
    end;
    if il_13c <> 0 then
      uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
    uobj_reloc_tail := uobj_reloc_head;
    nrels.l := 0;
    rel_ptr := uobj_obj_pos;
    if nreloc_5d4c >= 65535 then begin
      r := putobj(uobj_obj_pos, 10);
      r^.r_vaddr := nreloc_5d4c + 1;
      r^.r_symndx := 0;
      r^.r_type := unix_objmod_$r_count;
      uobj_obj_pos := uobj_obj_pos + 10;
      freeobj(r);
    end;
    emit_rel(sect_5d94, 0);
    if nrels.l <> 0 then begin
      if nreloc_5d4c >= 65535 then
        nrels.l := 65535;
      add_to_section_header(rel_ptr, true, nrels.low);
    end;
    uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
    pas_$dispose(sect_5d94, 6156);
    uobj_addr_bias := base;
    s := il_110;
    while s <> nil do begin
      if not cargs_$options.compress and cargs_$options.ncompress then begin
        uobj_reloc_tail := uobj_reloc_head;
        nrels.l := 0;
        rel_ptr := uobj_obj_pos;
        if s^.xl[12] >= 65535 then begin
          r := putobj(uobj_obj_pos, 10);
          r^.r_vaddr := s^.xl[12] + 1;
          r^.r_symndx := 0;
          r^.r_type := unix_objmod_$r_count;
          uobj_obj_pos := uobj_obj_pos + 10;
          freeobj(r);
        end;
        emit_rel(s, 0);
        if nrels.l <> 0 then begin
          if s^.xl[12] >= 65535 then
            nrels.l := 65535;
          add_to_section_header(rel_ptr, true, nrels.low);
        end;
      end;
      uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
      s := s^.xp[1];
    end;
    s := il_118;
    while s <> nil do begin
      if cargs_$options.ncompress then begin
        uobj_reloc_tail := uobj_reloc_head;
        nrels.l := 0;
        rel_ptr := uobj_obj_pos;
        if s^.xl[12] >= 65535 then begin
          r := putobj(uobj_obj_pos, 10);
          r^.r_vaddr := s^.xl[12] + 1;
          r^.r_symndx := 0;
          r^.r_type := unix_objmod_$r_count;
          uobj_obj_pos := uobj_obj_pos + 10;
          freeobj(r);
        end;
        emit_rel(s, 0);
        if nrels.l <> 0 then begin
          if s^.xl[12] >= 65535 then
            nrels.l := 65535;
          add_to_section_header(rel_ptr, true, nrels.low);
        end;
      end;
      uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
      s := s^.xp[2];
    end;
    if (7 in cargs_$options.flags_286) and (uobj_ntvs.l > 0) then begin
      rel_ptr := uobj_obj_pos;
      create_tv_reloc_recs;
      if uobj_ntvs.l >= 65535 then begin
        w := uobj_ntvs.low + 1;
        add_to_section_header(rel_ptr, true, w);
      end
      else
        add_to_section_header(rel_ptr, true, uobj_ntvs.low);
      uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
    end;
    if il_114 <> 0 then
      uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
    if nblock_relocs <> 0 then begin
      uobj_reloc_tail := uobj_reloc_head;
      nrels.l := 0;
      rel_ptr := uobj_obj_pos;
      if nblock_relocs >= 65535 then begin
        r := putobj(uobj_obj_pos, 10);
        r^.r_vaddr := nblock_relocs + 1;
        r^.r_symndx := 0;
        r^.r_type := unix_objmod_$r_count;
        uobj_obj_pos := uobj_obj_pos + 10;
        freeobj(r);
      end;
      emit_rel(block_sect, 0);
      if nblock_relocs >= 65535 then
        nrels.l := 65535;
      add_to_section_header(rel_ptr, true, nrels.low);
    end;
    uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
    db := cargs_$options.db;
    if db <> 0 then begin
      if il_d4 <> nil then
        uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
      if db >= 2 then begin
        s := symbols_sections;
        while s <> nil do begin
          uobj_reloc_scnhdr_pos := uobj_reloc_scnhdr_pos + 40;
          s := s^.xp[2];
        end;
      end;
      nrels.l := 0;
      rel_ptr := uobj_obj_pos;
      uobj_reloc_tail := uobj_reloc_head;
      if nreloc_5d50 >= 65535 then begin
        r := putobj(uobj_obj_pos, 10);
        r^.r_vaddr := nreloc_5d50 + 1;
        r^.r_symndx := 0;
        r^.r_type := unix_objmod_$r_count;
        uobj_obj_pos := uobj_obj_pos + 10;
        freeobj(r);
      end;
      emit_rel(uobj_sym_sect, data_5c54 + data_5c50);
      if nrels.l <> 0 then begin
        if nreloc_5d50 >= 65535 then
          nrels.l := 65535;
        add_to_section_header(rel_ptr, true, nrels.low);
      end;
      pas_$dispose(uobj_sym_sect, 4);
    end;
    s := il_10c;
    while s <> nil do begin
      if hdr <> nil then begin
        cur := hdr;
        gen_proc_relocs(s, cur, true, 0);
      end;
      s := s^.xp[1];
    end;
    s := il_10c;
    while s <> nil do begin
      if hdr <> nil then begin
        cur := hdr;
        gen_proc_relocs(s, cur, false, uobj_code_scnhdr_pos);
        uobj_code_scnhdr_pos := uobj_code_scnhdr_pos + 40;
      end;
      s := s^.xp[1];
    end;
    gen_data_relocs;
    if (cargs_$options.db >= 2) and (uobj_lnno_head <> nil) and
       not cargs_$options.nclines then begin
      uobj_addr_bias := target_bases[target_index];
      uobj_lnno_list := uobj_lnno_head;
      s := il_10c;
      uobj_lnno_start := uobj_obj_pos;
      while s <> nil do begin
        uobj_nlnnos.l := 0;
        lnno_ptr := uobj_obj_pos;
        if s^.xl[3] <> 0 then
          line_numbers(s);
        if uobj_nlnnos.l <> 0 then
          add_to_section_header(lnno_ptr, false, uobj_nlnnos.low);
        if s^.xl[3] <> 0 then
          uobj_lnno_scnhdr_pos := uobj_lnno_scnhdr_pos + 40;
        s := s^.xp[1];
      end;
    end;
  end;

  { add_exception_addr_con_tuple - the exception data tuple: address
    constants (gen_utils_$alloc_new_addr_con, in the exception data
    section +0x5C3C) of c (form 3), b (form 10) and a (form 3), in that
    order; the last one's node left in A0 as the result (pattern 32).

    0x09F0DA, 0x4E bytes: no locals but the frame.

    Not known from the original:
    - the names. }

  function add_exception_addr_con_tuple(
      a: il_$node_ptr_t;
      b: il_$node_ptr_t;
      c: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
  var
    n: il_$node_ptr_t;
  begin
    n := gen_utils_$alloc_new_addr_con(3, c, 0, exc_data);
    n := gen_utils_$alloc_new_addr_con(10, b, 0, exc_data);
    add_exception_addr_con_tuple :=
      gen_utils_$alloc_new_addr_con(3, a, 0, exc_data);
  end;
begin
  exc_text := nil;
  exc_data := nil;
  if il_13c <> 0 then begin
    if il_$node_ptr_t(il_10c)^.xp[1] <> nil then
      cgerr_no_source(28, integer32(strtk(
        'More than one text section.  Exception data tuple only handles one.', 67)));
    if il_$node_ptr_t(il_110)^.xp[1] <> nil then
      cgerr_no_source(28, integer32(strtk(
        'More than one data section.  Exception data tuple only handles one.', 67)));
    if il_138 = 0 then
      cgerr_no_source(28, integer32(strtk(
        'tbld.exception_processor_ptr is required to be set.', 51)));
    exc_text := gspace32(92);
    exc_text^.kind := 182;
    exc_data := il_110;
    exc_tuple := add_exception_addr_con_tuple(il_10c, il_110, exc_text);
    exc_handler := gen_utils_$alloc_new_addr_con(2, il_$node_ptr_t(il_138),
                                                 0, exc_data);
  end;
  data_cursor := il_110;
  while data_cursor <> nil do begin
    data_cursor^.xl[4] := data_cursor^.xl[4] & (-target_properties.p_90);
    data_cursor^.xl[5] := (data_cursor^.xl[5] + target_properties.p_90 - 1) &
                          (-target_properties.p_90);
    data_cursor := data_cursor^.xp[1];
  end;
  dump_namelist;
  if 6 in cargs_$options.cpu then
    target_index := 2
  else
    target_index := 1;
  filehdr_pos := obj_start;
  aouthdr_pos := filehdr_pos + 20;
  scnhdr_start := aouthdr_pos + 44;
  temp_string_count := 0;
  data_sect := 0;
  uobj_reloc_scnhdr_pos := 0;
  uobj_lnno_scnhdr_pos := 0;
  uobj_code_scnhdr_pos := 0;
  strtab_pos := 0;
  uobj_global_name_count.l := 0;
  uobj_local_name_count.l := 0;
  uobj_nsects := 0;
  data_5c6c := 0;
  patched := false;
  uobj_nsyms := 1;
  fixup_head := nil;
  data_section := nil;
  uobj_sym_sect := nil;
  main_symbols := nil;
  if cargs_$options.db <> 0 then
    debug_sym_dmp_$init;
  pas_$new(sect_5d94, 6156);
  if sect_5d94 = nil then
    cgerr_no_source(9, 0);
  if cargs_$options.db <> 0 then begin
    pas_$new(uobj_sym_sect, 4);
    if uobj_sym_sect = nil then
      cgerr_no_source(9, 0);
  end;
  if cargs_$options.db >= 2 then
    debug_sym_dmp_$create_symbols_sections(addr(symbols_sections),
                                           addr(symbols_tail))
  else begin
    symbols_sections := nil;
    symbols_tail := nil;
  end;
  if not target_properties.p_7f and cargs_$options.exp then begin
    io_release(0);
    io_release(1);
    spos_$capture_file_marks;
    do_lex^;
  end;
  nreloc_5d50 := 0;
  nreloc_5d4c := 0;
  ecb_cursor := il_10c;
  while ecb_cursor <> nil do begin
    ecb_cursor^.xl[17] := 0;
    ecb_cursor := ecb_cursor^.xp[1];
  end;
  ecb_cursor := il_110;
  while ecb_cursor <> nil do begin
    ecb_cursor^.xl[12] := 0;
    ecb_cursor := ecb_cursor^.xp[1];
  end;
  ecb_cursor := il_118;
  while ecb_cursor <> nil do begin
    ecb_cursor^.xl[12] := 0;
    ecb_cursor := ecb_cursor^.xp[2];
  end;
  ncommons := 0;
  data_cursor := il_110;
  while data_cursor <> nil do begin
    ecb_cursor := data_cursor^.xp[3];
    while ecb_cursor <> nil do
      if ecb_cursor^.kind <> 163 then
        ecb_cursor := ecb_cursor^.xp[29]
      else begin
        if (ord(ecb_cursor^.xc[20]) = 2) or (ord(ecb_cursor^.xc[20]) = 4) then
          ecb_cursor^.xw[11] := create_global_reference(ecb_cursor^.xp[2]);
        ecb_cursor := ecb_cursor^.xp[1];
      end;
    data_cursor := data_cursor^.xp[1];
  end;
  uobj_ntvs.l := 0;
  ecb_cursor := il_128;
  while ecb_cursor <> nil do begin
    uobj_ntvs.l := uobj_ntvs.l + 1;
    ecb_cursor^.xw[9] := create_global_reference(ecb_cursor^.xp[2]);
    ecb_cursor := ecb_cursor^.xp[1];
  end;
  ecb_cursor := il_12c;
  while ecb_cursor <> nil do begin
    if not ((ecb_cursor^.xp[2]^.kind = 109) and
            (ecb_cursor^.xp[2]^.xw[36] = 3)) then
      cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
    ecb_cursor^.xw[6] := create_global_reference(ecb_cursor^.xp[2]);
    ecb_cursor := ecb_cursor^.xp[1];
  end;
  ecb_cursor := il_130;
  while ecb_cursor <> nil do begin
    t := ecb_cursor^.xp[3];
    if (((t^.kind = 105) or (t^.kind = 107) or (t^.kind = 167) or
         (t^.kind = 108)) and ((t^.xw[188] & 384) div 128 = 2)) or
       ((t^.kind = 109) and (t^.xw[36] = 3)) then
      k := create_global_reference(t);
    ecb_cursor := ecb_cursor^.xp[1];
  end;
  determine_section_headers_size;
  output_data_info;
  if il_13c <> 0 then begin
    d := exc_data^.xl[9] - exc_data^.xl[4];
    gen_unwind_$end_compilation(d + exc_tuple^.xl[4], d + exc_handler^.xl[4]);
  end;
  scnhdr_start := uobj_obj_pos;
  uobj_symptr := scnhdr_start;
  coff_sym_dmp;
  if uobj_nsyms_coff = 0 then begin
    uobj_symptr := 0;
    strtab_pos := scnhdr_start;
  end
  else
    strtab_pos := uobj_symptr + uobj_syms_size;
  if temp_string_count <> 0 then begin
    l := putobj(strtab_pos, 4);
    obj_map_5d18 := l;
    l^ := temp_string_count + 4;
    strtab_pos := strtab_pos + 4;
    freeobj(obj_map_5d18);
    strtab_cursor := strtab_pos;
    for global_index := 0 to temp_string_count - 1 do begin
      b := putobj(strtab_cursor, 1);
      obj_map_5d18 := b;
      b^[1] := temp_string_table[global_index];
      freeobj(obj_map_5d18);
      strtab_cursor := strtab_cursor + 1;
    end;
  end;
  a := putobj(aouthdr_pos, 44);
  obj_map_5d18 := a;
  main_routine := il_184;
  if main_routine^.kind = 106 then
    if (ord(main_routine^.xc[377]) & 16#70) div 16 = 3 then
      main_routine := il_17c
    else
      main_routine := il_$node_ptr_t(il_184)^.xp[1];
  no_entry := false;
  if main_routine^.kind = 105 then begin
    if not has_ecb(main_routine) then
      a^.entry := main_routine^.xp[25]^.xl[14] + main_routine^.xp[47]^.xl[14]
    else
      a^.entry := main_routine^.xl[27] - main_routine^.xp[48]^.xl[4] +
                  main_routine^.xp[48]^.xl[9];
  end
  else begin
    a^.entry := 0;
    no_entry := true;
  end;
  a^.magic := 1;
  a^.vstamp := 0;
  a^.tsize := code_addr - target_bases[target_index] + uobj_code_size;
  a^.dsize := data_5c9c;
  a^.bsize := data_5c98;
  a^.text_start := target_bases[target_index];
  a^.data_start := data_start;
  a^.sri_ptr := sri_start;
  a^.inlib_ptr := inlib_start;
  a^.vid_high := 0;
  a^.vid_low := 0;
  freeobj(obj_map_5d18);
  f := putobj(filehdr_pos, 20);
  obj_map_5d18 := f;
  f^.f_magic := target_magic;
  f^.f_nscns := nscns.low;
  f^.f_timdat := time(nil);
  f^.f_symptr := uobj_symptr;
  f^.f_nsyms := uobj_nsyms_coff;
  f^.f_opthdr := 44;
  f^.f_flags := f^.f_flags + [3];
  if il_114 = 0 then
    f^.f_flags := f^.f_flags + [1];
  if not (7 in cargs_$options.flags_286) then
    f^.f_flags := f^.f_flags + [unix_objmod_$f_pic];
  freeobj(obj_map_5d18);
  set_obj_length(strtab_pos + temp_string_count);
end;

{ unix_obj_init - before the code: the object file's first 20 bytes
  mapped at 0 (+0x5C90), a zero word stored; emit +0x108's code
  counts cleared.

  0x09F952, 0x50 bytes.

  Not known from the original:
  - the names. }

procedure unix_obj_init;
var
  p: unix_objmod_$word_ptr_t;
begin
  obj_start := 0;
  p := putobj(obj_start, 20);
  p^ := 0;
  freeobj(p);
  emit_108.e108 := 0;
  emit_108.e10c := 0;
  emit_108.e110 := 0;
  emit_108.e118 := 0;
end;
