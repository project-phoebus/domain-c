{ us/us/ins/objmod.ins.pas - Apollo's internal insert of the OBJ object
  module format (//us/us/ins), the format before COFF: the records
  objio.pas and objutil.pas read.

  No copy survives.  The records are the source repository's
  com/bind/objio.ins.pas reconstruction (the SR10.2 /com/bind's reading
  of them, with the names of lib/pmlib/ins/obj.ins.pas given the OBJ_$
  prefix), moved here because cc's objio.pas and objutil.pas open this
  insert before objio.ins.pas (their .blocks file lists); the routines
  and status codes stay in objio.ins.pas.

  Include /sys/ins/base.ins.pas (us/us/ins/ubase.ins.pas) before it.

  Not known from the original: which declarations this insert held;
  every name here (the source repository's).
}

const
  { obj_$file_hdr_t.kind }
  obj_$kind_module = 1;
  obj_$kind_bkpts = 4;                  { a debugger left breakpoints }
  obj_$kind_absolute = 5;

  { obj_$sect_t.flags members }
  obj_$sect_install = 9;                { its name is a global }

  obj_$lib_magic = 16#402DF854;         { obj_$lib_list_t.magic }

type
  obj_$name_t = array[1..32] of char;   { blank padded }

  { Body+0: the file header. }
  obj_$file_hdr_t = record              { 32 bytes }
    kind: integer;                      { +0x00 }
    version: integer;                   { +0x02 }
    pure_len: integer32;                { +0x04 }
    code_start: integer32;              { +0x08 }
    mod_hdr: integer32;                 { +0x0C: obj_$mod_hdr_t's offset }
    init_recs: integer32;               { +0x10 }
    mir: integer32;                     { +0x14 }
    routines: integer32;                { +0x18 }
    body_len: integer32;                { +0x1C }
  end;
  obj_$file_hdr_ptr_t = ^obj_$file_hdr_t;

  obj_$mod_hdr_t = record               { 74 bytes, then the sections }
    start_sect: integer;                { +0 }
    start_off: integer32;               { +2 }
    name: obj_$name_t;                  { +6 }
    version_major: integer;             { +38 }
    version_minor: integer;             { +40 }
    time: integer32;                    { +42 }
    sect_count: integer32;              { +46 }
    attrs: integer32;                   { +50 }
    attr_count: integer32;              { +54 }
    syms: integer32;                    { +58: obj_$sym_t's offset }
    sym_count: integer32;               { +62 }
    lib_list: integer32;                { +66: obj_$lib_list_t's, 0 none }
    abs_hdr: integer32;                 { +70 }
  end;
  obj_$mod_hdr_ptr_t = ^obj_$mod_hdr_t;

  obj_$sect_t = record                  { 42 bytes }
    file_off: integer32;                { +0 }
    size: integer32;                    { +4 }
    flags: set of 0..15;                { +8 }
    name: obj_$name_t;                  { +10 }
  end;
  obj_$sect_ptr_t = ^obj_$sect_t;

  obj_$sym_t = record                   { 54 bytes }
    index: pinteger;                    { +0 }
    section: integer;                   { +2: 0 undefined }
    value: integer32;                   { +4 }
    hidden: boolean;                    { +8 }
    flags_lo: char;                     { +9 }
    kind: integer;                      { +10 }
    unused_12: array[1..10] of char;    { +12 }
    name: obj_$name_t;                  { +22 }
  end;
  obj_$sym_ptr_t = ^obj_$sym_t;

  { The libraries the module asks for: a header, then the entries, each
    an obj_$lib_ent_t and the name (padded to even). }
  obj_$lib_list_t = record              { 20 bytes }
    magic: integer32;                   { +0: obj_$lib_magic }
    unused_4: integer;                  { +4 }
    count: integer;                     { +6 }
    unused_8: array[1..12] of char;     { +8 }
  end;
  obj_$lib_list_ptr_t = ^obj_$lib_list_t;

  obj_$lib_ent_t = record               { 12 bytes }
    unused_0: integer;                  { +0 }
    name_len: integer;                  { +2 }
    unused_4: integer32;                { +4 }
    unused_8: integer32;                { +8 }
  end;
  obj_$lib_ent_ptr_t = ^obj_$lib_ent_t;

