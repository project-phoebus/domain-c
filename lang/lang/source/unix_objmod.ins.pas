{ lang/lang/source/unix_objmod.ins.pas - the interface of
  lang/lang/source/unix_objmod.pas (the COFF object module writer) and
  of lang/lang/source/coff_syms.pas (its symbol table), which has no
  insert of its own.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  The units that open this insert (coff_syms, debug_sym_dmp, gen_debug's
  users, gen_utils, outbin, ...) do not open us/us/ins/coff.ins.pas, so
  the COFF records the object module is built from are declared here
  (as unix_objmod_$...; their layout is the one coff.ins.pas gives).

  The cells: unix_objmod.pas's data (cc.m68k A5 0x1A0314, 0x121D6C bytes
  to add_node's; cc.a88k A5 0x320384), the ones other units read
  absolutely (tools/cc_globals.py BINARY --unit unix_objmod), by
  offset.  The large tables lie beyond 32K and are reached absolutely
  in the image: the global names at +0xFA064 (cc.m68k 0x29A378, coff_syms
  and outbin; the first after the 1000000-byte data buffer at +0x5E24),
  the string table at +0xFAC64 (0x29AF78, unix_objmod only).  dpc lays
  out the variables in the order of their declarations (the `define'd
  ones first) and refuses a scalar beyond 32K, so the global names are
  declared last here and the unit's large buffers last in the unit.

  Not known from the original: every name here but the routines'; the
  parameter names; which of these the original insert declared. }

const
  { s_flags members (us/us/ins/coff.ins.pas's coff_$styp_...). }
  unix_objmod_$styp_text = 5;
  unix_objmod_$styp_data = 6;
  unix_objmod_$styp_bss = 7;
  unix_objmod_$styp_info = 9;
  unix_objmod_$styp_lib = 11;
  unix_objmod_$styp_relocated_not_loaded = 16;
  unix_objmod_$styp_debug = 17;
  unix_objmod_$styp_overlay = 18;
  unix_objmod_$styp_instruction = 21;
  unix_objmod_$styp_zero = 23;
  unix_objmod_$styp_lookup = 26;
  unix_objmod_$styp_secalign2 = 28;
  unix_objmod_$styp_compressed = 29;

  { r_type }
  unix_objmod_$r_dir32 = 6;
  unix_objmod_$r_count = 512;           { r_vaddr is the entries' count }

  { f_flags members }
  unix_objmod_$f_pic = 15;

type
  { A COFF name: eight characters, or (zeroes 0) its offset in the
    string table. }
  unix_objmod_$name_t = record          { 8 bytes }
    case integer of
      1: (chars: array [1..8] of char);
      2: (zeroes: integer32;
          offset: integer32);
  end;

  unix_objmod_$filehdr_t = record       { 20 bytes }
    f_magic: integer;                   { +0x00 }
    f_nscns: integer;                   { +0x02 }
    f_timdat: integer32;                { +0x04 }
    f_symptr: integer32;                { +0x08 }
    f_nsyms: integer32;                 { +0x0C }
    f_opthdr: integer;                  { +0x10 }
    f_flags: set of 0..15;              { +0x12 }
  end;
  unix_objmod_$filehdr_ptr_t = ^unix_objmod_$filehdr_t;

  { Apollo's optional header. }
  unix_objmod_$aouthdr_t = record       { 44 bytes }
    magic: integer;                     { +0x00 }
    vstamp: integer;                    { +0x02 }
    tsize: integer32;                   { +0x04 }
    dsize: integer32;                   { +0x08 }
    bsize: integer32;                   { +0x0C }
    entry: integer32;                   { +0x10 }
    text_start: integer32;              { +0x14 }
    data_start: integer32;              { +0x18 }
    sri_ptr: integer32;                 { +0x1C }
    inlib_ptr: integer32;               { +0x20 }
    vid_high: integer32;                { +0x24 }
    vid_low: integer32;                 { +0x28 }
  end;
  unix_objmod_$aouthdr_ptr_t = ^unix_objmod_$aouthdr_t;

  unix_objmod_$scnhdr_t = record        { 40 bytes }
    s_name: unix_objmod_$name_t;        { +0x00 }
    s_paddr: integer32;                 { +0x08 }
    s_vaddr: integer32;                 { +0x0C }
    s_size: integer32;                  { +0x10 }
    s_scnptr: integer32;                { +0x14 }
    s_relptr: integer32;                { +0x18 }
    s_lnnoptr: integer32;               { +0x1C }
    s_nreloc: integer;                  { +0x20 }
    s_nlnno: integer;                   { +0x22 }
    s_flags: set of 0..31;              { +0x24 }
  end;
  unix_objmod_$scnhdr_ptr_t = ^unix_objmod_$scnhdr_t;

  unix_objmod_$coff_reloc_t = record    { 10 bytes }
    r_vaddr: integer32;                 { +0 }
    r_symndx: integer32;                { +4 }
    r_type: integer;                    { +8 }
  end;
  unix_objmod_$coff_reloc_ptr_t = ^unix_objmod_$coff_reloc_t;

  unix_objmod_$lineno_t = record        { 6 bytes }
    l_addr: integer32;                  { +0: the symbol for line 0 }
    l_lnno: integer;                    { +4 }
  end;
  unix_objmod_$lineno_ptr_t = ^unix_objmod_$lineno_t;

  { A count kept as a longword whose low word other units (and the
    section headers' 16-bit counts) read. }
  unix_objmod_$count_t = record
    case integer of
      1: (l: integer32);
      2: (high: integer;
          low: integer);
  end;

  { A relocation to make (add_reloc; 20 bytes from PAS_$NEW): of the
    longword at vaddr of sect, against symbol symndx; target the node
    gen_proc_relocs resolves it with, or nil. }
  unix_objmod_$reloc_ptr_t = ^unix_objmod_$reloc_t;
  unix_objmod_$reloc_t = record
    sect: il_$node_ptr_t;               { +0 }
    vaddr: integer32;                   { +4 }
    symndx: integer32;                  { +8 }
    target: il_$node_ptr_t;             { +12 }
    next: unix_objmod_$reloc_ptr_t;     { +16 }
  end;

  { A line number to write (the list +0x5D84 / +0x5D88; 18 bytes, built
    by outbin's ln_begin and ln_number). }
  unix_objmod_$lnno_ptr_t = ^unix_objmod_$lnno_t;
  unix_objmod_$lnno_t = record
    sect: il_$node_ptr_t;               { +0 }
    addr: integer32;                    { +4 }
    symndx: integer32;                  { +8 }
    line: integer;                      { +12 }
    next: unix_objmod_$lnno_ptr_t;      { +14 }
  end;

  { An entry of the name tables (12 bytes, coff_syms's count_global_sym
    fills them): the node, its COFF symbol and the identifier of its
    name. }
  unix_objmod_$sym_entry_t = record
    name: il_$node_ptr_t;               { +0 }
    symndx: integer32;                  { +4 }
    ident: il_$node_ptr_t;              { +8 }
  end;

  { The routine run_backend's caller passes for unix_obj_gen (c_main's
    do_lex_for_listings, by value: `move.l #addr,-(SP)'), run before
    the object module is written under -EXP. }
  unix_objmod_$lex_proc_t = runbackend_$lex_proc_t;  { the prelude's }

var
  { A5 +0x5020 (cc.m68k 0x1A5334): the names of kind 208 (count +0x5D54)
    with their symbols (coff_syms's count_global_sym and put_global_sym
    fill it). }
  uobj_local_names: extern array [1..256] of unix_objmod_$sym_entry_t;
  uobj_lines_addr: extern integer32;     { +0x5C20: the .lines section's
                                           address (debug_sym_dmp) }
  uobj_unwind_addr: extern integer32;    { +0x5C24: the .unwind
                                           section's (debug_sym_dmp) }
  uobj_symbols_addr: extern integer32;   { +0x5C28: the .symbols
                                           section's (debug_sym_dmp) }
  uobj_exc_symndx: extern unix_objmod_$count_t;  { +0x5D2C: coff_syms }
  uobj_5d30: extern integer32;           { +0x5D30: coff_syms,
                                           debug_sym_dmp }
  uobj_5d34: extern integer32;           { +0x5D34: coff_syms }
  uobj_5d38: extern integer32;           { +0x5D38: coff_syms,
                                           debug_sym_dmp }
  uobj_5d3c: extern integer32;           { +0x5D3C: coff_syms,
                                           debug_sym_dmp }
  uobj_5d40: extern integer32;           { +0x5D40: coff_syms }
  uobj_direct_index: extern integer32;   { +0x5D44: the index in the
                                           piece of the object file mapped
                                           for direct data output (outbin) }
  uobj_direct_left: extern integer32;    { +0x5D48: what is left of the
                                           section (outbin) }
  uobj_local_name_count: extern unix_objmod_$count_t;   { +0x5D54 }
  uobj_global_name_count: extern unix_objmod_$count_t;  { +0x5D58 }
  uobj_symptr: extern integer32;         { +0x5D60: the symbol table's
                                           offset (coff_syms) }
  uobj_nlnnos: extern unix_objmod_$count_t;  { +0x5D64: line numbers
                                           written (coff_syms) }
  uobj_lnno_start: extern integer32;     { +0x5D68: coff_syms }
  uobj_5d6c: extern unix_objmod_$count_t;    { +0x5D6C: coff_syms,
                                           outbin }
  uobj_ntvs: extern unix_objmod_$count_t;    { +0x5D70: transfer vectors
                                           (coff_syms) }
  uobj_addr_bias: extern integer32;      { +0x5D74: added to an object
                                           offset for its address
                                           (outbin) }
  uobj_code_scnhdr_pos: extern integer32;   { +0x5D78: outbin }
  uobj_lnno_scnhdr_pos: extern integer32;   { +0x5D7C: outbin }
  uobj_scnhdr_pos: extern integer32;     { +0x5D80: the next section
                                           header's offset (outbin) }
  uobj_lnno_list: extern unix_objmod_$lnno_ptr_t;   { +0x5D84: outbin }
  uobj_lnno_head: extern unix_objmod_$lnno_ptr_t;   { +0x5D88: outbin }
  uobj_sym_sect: extern il_$node_ptr_t;  { +0x5D8C: the debugging
                                           symbols' relocations' section
                                           (gen_section_table) }
  uobj_reloc_tail: extern unix_objmod_$reloc_ptr_t;  { +0x5D98: outbin }
  uobj_reloc_head: extern unix_objmod_$reloc_ptr_t;  { +0x5D9C: outbin }
  uobj_obj_map: extern univ_ptr;         { +0x5DA0: outbin }
  uobj_code_size: extern integer32;      { +0x5DA4: outbin }
  uobj_reloc_scnhdr_pos: extern integer32;   { +0x5DA8: outbin }
  uobj_direct_base: extern integer32;    { +0x5DB4: outbin }
  uobj_obj_pos: extern integer32;        { +0x5DB8: the object file's
                                           offset being written (outbin) }
  uobj_pad_from: extern integer32;       { +0x5DBC: outbin }
  uobj_sect_start: extern integer32;     { +0x5DC0: outbin }
  uobj_syms_size: extern integer32;      { +0x5DC4: the symbol table's
                                           size (coff_syms) }
  uobj_nsyms_coff: extern integer32;     { +0x5DC8: its symbols
                                           (coff_syms) }
  { +0x5DD0 and +0x5E16 (uobj_hp_standard, uobj_systype_2: the front
    end sets them) are declared in lang/c_compiler/source/c_globals.ins.pas,
    which runbackend opens with this insert; unix_objmod.pas, which
    opens neither, declares them itself. }
  uobj_exception_sect: extern integer;   { +0x5DEC: the section numbers
                                           (coff_syms) }
  uobj_inlib_sect: extern integer;       { +0x5DEE }
  uobj_lines_sect: extern integer;       { +0x5DF0 }
  uobj_rwdi_sect: extern integer;        { +0x5DF2 }
  uobj_mir_sect: extern integer;         { +0x5DF4 }
  uobj_sri_sect: extern integer;         { +0x5DF6 }
  uobj_unwind_sect: extern integer;      { +0x5DF8 }
  uobj_symbols_sect: extern integer;     { +0x5DFA }
  uobj_blocks_sect: extern integer;      { +0x5DFC }
  uobj_bss_sect: extern integer;         { +0x5DFE }
  uobj_aptv_sect: extern integer;        { +0x5E00 }
  uobj_nsects: extern integer;           { +0x5E02 }
  uobj_nsyms: extern integer;            { +0x5E04: the next symbol's
                                           number (outbin) }
  uobj_headers_counted: extern boolean;  { +0x5E10: coff_syms }
  { +0xFA064 (cc.m68k 0x29A378): the transfer vectors' names (kind 159)
    with their symbols, count +0x5D58 (coff_syms fills it; outbin's
    get_reloc_symndx reads it). }
  uobj_global_names: extern array [1..256] of unix_objmod_$sym_entry_t;

{ TARGET_MAGIC - the COFF magic number of the target (404..407 by
  target_properties.p_10).  unix_objmod.pas 0x09949A (cc.m68k): no
  parameters, the result in D0. }
function target_magic: integer32; extern;

{ HAS_ECB - whether routine p has an entry control block.  0x099456: a
  pointer by value (debug_sym_dmp, coff_syms's put_func_def). }
function has_ecb(
    p: il_$node_ptr_t): boolean; options(val_param); extern;

{ ADD_RELOC - note a relocation at vaddr of sect against symndx (target
  the node to resolve it with, or nil).  0x0997DE: four by value
  (gen_unwind). }
procedure add_reloc(
    vaddr: integer32;
    sect: il_$node_ptr_t;
    symndx: integer32;
    target: il_$node_ptr_t); options(val_param); extern;

{ EMIT_16 - a word of data.  0x099C04: by address (outbin). }
procedure emit_16(
    in w: integer); extern;

{ STRING_TABLE - name refers to the string table, where id's characters
  go.  0x099C9E: both by address (coff_syms). }
procedure string_table(
    out name: unix_objmod_$name_t;
    in id: il_$node_ptr_t); extern;

{ UNIX_PUT_OBJ_NAME - the COFF name of identifier id.  0x099D06: name by
  address, id a pointer by value (outbin). }
procedure unix_put_obj_name(
    out name: unix_objmod_$name_t;
    id: il_$node_ptr_t); options(val_param); extern;

{ UNIX_OBJ_INIT - set up the object module.  cc.m68k 0x09F952 (cc.a88k
  0x0A1332): no parameters (run_backend). }
procedure unix_obj_init; extern;

{ UNIX_OBJ_GEN - write the object module.  cc.m68k 0x09F128 (cc.a88k
  0x0A0B08): a routine pointer by value at (8,A6), called through
  (`jsr (A0)', with no arguments, under -EXP; run_backend passes its
  own). }
procedure unix_obj_gen(
    do_lex: unix_objmod_$lex_proc_t); options(val_param); extern;

{ NUMBER_COFF_SYMS, COFF_SYM_DMP - coff_syms.pas 0x0A6AC2 and 0x0A7CA4
  (cc.m68k): no parameters (unix_objmod's output_data_info and
  unix_obj_gen). }
procedure number_coff_syms; extern;
procedure coff_sym_dmp; extern;
