{ us/us/ins/coff.ins.pas - Apollo's internal COFF object-format insert
  (//us/us/ins): the file and optional headers, section headers, symbols
  and their auxiliary entries, relocation and line number entries, and
  the .sri and .mir records.

  No copy survives.  The declarations are the source repository's
  com/bind/coff.ins.pas reconstruction (the records as the SR10.2
  /com/bind reads them; names from lib/pmlib/ins/coff.ins.pas and the C
  headers), which objio.pas and objutil.pas (lang/bind/source) read.

  Include /sys/ins/base.ins.pas (us/us/ins/ubase.ins.pas) before it.

  Not known from the original: everything about its contents.
}

const
  coff_$magic = 16#197;                 { f_magic: m68k }
  coff_$magic_a88k = 16#194;            { f_magic: a88k }
  coff_$aout_magic = 1;                 { the optional header's magic }
  coff_$aout_size = 44;                 { and its size }

  coff_$filhsz = 20;                    { the file header's size }
  coff_$scnhsz = 40;                    { a section header's }
  coff_$symesz = 18;                    { a symbol's }
  coff_$relsz = 10;                     { a relocation entry's }
  coff_$linesz = 6;                     { a line number entry's }

  { f_flags members. }
  coff_$f_relflg = 0;                   { no relocation entries }
  coff_$f_exec = 1;                     { executable }
  coff_$f_stripped = 14;                { no symbols }
  coff_$f_pic = 15;                     { position independent }

  { s_flags members. }
  coff_$styp_text = 5;                  { 16#20 }
  coff_$styp_data = 6;                  { 16#40 }
  coff_$styp_bss = 7;                   { 16#80 }
  coff_$styp_info = 9;                  { 16#200: not allocated }
  coff_$styp_lib = 11;                  { 16#800 }
  coff_$styp_relocated_not_loaded = 16; { 16#10000 }
  coff_$styp_debug = 17;                { 16#20000 }
  coff_$styp_overlay = 18;              { 16#40000: overlaid, not
                                          concatenated }
  coff_$styp_instruction = 21;          { 16#200000: code }
  coff_$styp_zero = 23;                 { 16#800000: zero filled }
  coff_$styp_define = 25;               { its name is a global }
  coff_$styp_lookup = 26;               { look its name up first }
  coff_$styp_secalign1 = 27;            { 16#8000000 }
  coff_$styp_secalign2 = 28;            { 16#10000000: both page aligned,
                                          this alone quad, neither long }
  coff_$styp_compressed = 29;           { 16#20000000: no data, but
                                          initialization directives }

  { s_nreloc: the first relocation entry holds the count. }
  coff_$nreloc_ovfl = 16#FFFF;

  { r_type }
  coff_$r_abs = 0;                      { nothing to relocate }
  coff_$r_dir32 = 6;
  coff_$r_count = 512;                  { r_vaddr is the entries' count }

  { n_type's derived type }
  coff_$dt_fcn = 2;

  { n_sclass }
  coff_$c_ext = 2;
  coff_$c_stat = 3;
  coff_$c_file = 103;
  coff_$c_ext_unmarked = 110;
  coff_$c_ext_expunged = 111;

  { mir_kind }
  coff_$maker_mir_kind = 1;
  coff_$module_name_mir_kind = 2;

  { A .sri entry's kind. }
  coff_$sri_load_attrs = 2;
  coff_$sri_systype = 3;
  coff_$sri_default_systype = 5;
  coff_$sri_stack_size = 6;

  { The load attributes' members. }
  coff_$sri_no_main_addrs = 2;
  coff_$sri_page_break = 3;

  { A .sri entry's rule: how the binder combines the entries of a kind
    that its input modules give. }
  coff_$sri_rule_each = 0;              { every module's entry is kept }
  coff_$sri_rule_sum = 1;
  coff_$sri_rule_max = 2;
  coff_$sri_rule_min = 3;
  coff_$sri_rule_or = 4;
  coff_$sri_rule_last = 6;              { the last module's value }
  coff_$sri_rule_unique = 7;            { one value only }
  coff_$sri_rule_systype = 8;           { a system type: one only }

type
  coff_$long_name_t = array[1..32000] of char;

  { A name: eight characters, or (zeroes 0) the name's offset in the
    string table, or once read, where it is. }
  coff_$name_t = packed record          { 8 bytes }
    case integer of
      1: (chars: array[1..8] of char);
      2: (zeroes: integer32;
          case integer of
            1: (offset: integer32);
            2: (str: ^coff_$long_name_t));
  end;

  coff_$filehdr_t = record              { 20 bytes }
    f_magic: 0..65535;                  { 0x00 }
    f_nscns: 0..65535;                  { 0x02 }
    f_timdat: integer32;                { 0x04 }
    f_symptr: integer32;                { 0x08 }
    f_nsyms: integer32;                 { 0x0C }
    f_opthdr: 0..65535;                 { 0x10 }
    f_flags: set of 0..15;              { 0x12 }
  end;
  coff_$filehdr_ptr_t = ^coff_$filehdr_t;

  { Apollo's optional header. }
  coff_$aouthdr_t = record              { 44 bytes }
    magic: integer;                     { 0x00 }
    vstamp: integer;                    { 0x02 }
    tsize: integer32;                   { 0x04 }
    dsize: integer32;                   { 0x08 }
    bsize: integer32;                   { 0x0C }
    entry: integer32;                   { 0x10 }
    text_start: integer32;              { 0x14 }
    data_start: integer32;              { 0x18 }
    sri_ptr: integer32;                 { 0x1C }
    inlib_ptr: integer32;               { 0x20: the library list's offset }
    vid: uid_$t;                        { 0x24: the version's }
  end;
  coff_$aouthdr_ptr_t = ^coff_$aouthdr_t;

  coff_$scnhdr_t = record               { 40 bytes }
    s_name: coff_$name_t;               { 0x00 }
    s_paddr: integer32;                 { 0x08 }
    s_vaddr: integer32;                 { 0x0C }
    s_size: integer32;                  { 0x10 }
    s_scnptr: integer32;                { 0x14 }
    s_relptr: integer32;                { 0x18 }
    s_lnnoptr: integer32;               { 0x1C }
    s_nreloc: 0..65535;                 { 0x20 }
    s_nlnno: 0..65535;                  { 0x22 }
    s_flags: set of 0..31;              { 0x24 }
  end;
  coff_$scnhdr_ptr_t = ^coff_$scnhdr_t;

  coff_$type_t = packed record          { 2 bytes }
    d_rest: 0..1023;
    dt: 0..3;                           { the first derived type }
    bt: 0..15;                          { the base type }
  end;

  coff_$syment_t = packed record        { 18 bytes }
    n_name: coff_$name_t;               { 0x00 }
    n_value: integer32;                 { 0x08 }
    n_scnum: integer;                   { 0x0C }
    n_type: coff_$type_t;               { 0x0E }
    n_sclass: -128..127;                { 0x10 }
    n_numaux: -128..127;                { 0x11 }
  end;
  coff_$syment_ptr_t = ^coff_$syment_t;

  { An auxiliary entry: a file's name, or a function's. }
  coff_$auxent_t = record               { 18 bytes }
    case integer of
      1: (x_fname: coff_$name_t);       { 0x00 }
      2: (x_tagndx: integer32;          { 0x00 }
          x_fsize: integer32;           { 0x04 }
          x_lnnoptr: integer32;         { 0x08 }
          x_endndx: integer32;          { 0x0C }
          x_tvndx: 0..65535);           { 0x10 }
  end;
  coff_$auxent_ptr_t = ^coff_$auxent_t;

  coff_$reloc_t = record                { 10 bytes }
    r_vaddr: integer32;                 { 0x00 }
    r_symndx: integer32;                { 0x04 }
    r_type: integer;                    { 0x08 }
  end;
  coff_$reloc_ptr_t = ^coff_$reloc_t;

  { A line number entry: a function's first (l_lnno 0, its symbol's
    index), or a line's address. }
  coff_$lineno_t = record               { 6 bytes }
    l_addr: record                      { 0x00 }
      case integer of
        1: (l_symndx: integer32);
        2: (l_paddr: integer32);
    end;
    l_lnno: 0..65535;                   { 0x04 }
  end;
  coff_$lineno_ptr_t = ^coff_$lineno_t;

  { The library list (the optional header's inlib_ptr): a count, then
    16-byte entries, each the string table offset of a pathname. }
  coff_$inlib_entry_t = record          { 16 bytes }
    unused_0: integer32;
    unused_4: integer32;
    unused_8: integer32;
    name_ptr: integer32;
  end;
  coff_$inlib_entry_ptr_t = ^coff_$inlib_entry_t;

  { A .sri entry (after the section's count). }
  coff_$sri_entry_t = record            { 8 bytes }
    kind: integer;                      { 0x00 }
    rule: integer;                      { 0x02 }
    case integer of                     { 0x04 }
      1: (value: integer32);
      2: (selector: integer;            { a system type }
          release: integer);
  end;

  { A .mir record (after the section's count). }
  coff_$mir_t = record
    kind: integer;                      { 0x00 }
    mir_size: integer;                  { 0x02 }
    case integer of
      1: (version: integer;             { 0x04: maker }
          creation_time: integer32;     { 0x06 }
          maker_name_offset: integer32);  { 0x0A }
      2: (module_name_offset: integer32);  { 0x04: module name }
  end;
  coff_$mir_ptr_t = ^coff_$mir_t;
