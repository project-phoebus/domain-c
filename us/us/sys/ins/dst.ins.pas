{ us/us/sys/ins/dst.ins.pas - DST_, the debugging symbol table: the
  records of a .symbols section (the main file's) and of the .s.
  sections (an include file's, named by its CRC) as the debugger reads
  them.

  The original is /sys/ins/dst.ins.pas (the units open
  //us/us/sys/ins/dst.ins.pas), an internal insert no SR10.x install
  or archive has; this reconstruction stands in for it at its //us path
  (docs/questions.md 15) and declares only what pds.pas and
  debug_sym_dmp.pas use, read off pds.pas (cc.m68k 0x069B08..0x071C70;
  the same in cc.a88k), which builds the records in place (each one
  from the object file's allocator, at an even offset).

  A record starts with its kind (a byte) and a byte of flags; the rest
  depends on the kind.  Other records, names (in the string table) and
  locations (in the location pool) are reached by 32-bit references:
  the 2-bit tag, then an offset relative to the referring record's
  start (dst_$rel_t); a type is a standard type's code or a reference
  to a type record (dst_$type_ref_t); a record of another section is
  reached through the include table (tag 1: the entry's index and the
  record's offset in that section).

  Not known from the original: every name here; the kinds' and the
  records' names are taken from pds.pas's messages where it has them.
}

const
  { Record kinds (the byte at +0).  dump_rec, dump_aux_recs and the
    table writers of pds.pas store them. }
  dst_$local_file_table = 3;
  dst_$pointer = 7;
  dst_$array = 8;
  dst_$subrange = 9;
  dst_$set = 10;
  dst_$implicit_enum = 11;
  dst_$explicit_enum = 12;
  dst_$short_record = 13;
  dst_$file = 17;
  dst_$offset = 18;
  dst_$alias = 19;
  dst_$signature = 20;
  dst_$end_scope = 24;
  dst_$string_table = 27;
  dst_$aux_size = 30;
  dst_$aux_align = 31;
  dst_$aux_field_size = 32;
  dst_$aux_field_off = 33;
  dst_$aux_field_align = 34;
  dst_$aux_name = 35;
  dst_$aux_var_bound = 36;
  dst_$string = 38;
  dst_$constant = 40;
  dst_$record = 42;
  dst_$aux_type_deriv = 44;
  dst_$loc_pool = 45;
  dst_$variable = 46;
  dst_$label = 47;
  dst_$entry = 48;
  dst_$aux_lifetime = 49;
  dst_$aux_ptr_base = 50;
  dst_$aux_reg_val = 52;
  dst_$incl_table = 55;
  dst_$incl_start_scope = 56;
  dst_$incl_end_scope = 57;
  dst_$section_header = 58;

  { Flags (the byte at +1): the record has auxiliary records after it;
    the last auxiliary record of a record. }
  dst_$has_aux = 0;
  dst_$last_aux = 1;

  { The tags of a reference (its top two bits). }
  dst_$rel_positive = 0;        { a relative offset, not negative }
  dst_$rel_include = 1;         { through the include table }
  dst_$rel_type_positive = 2;   { a type reference, offset not negative }
  dst_$rel_negative = 3;        { a negative relative offset }

type
  { A reference.  rel: a relative offset (tag 0 or 3, the offset's top
    bits the tag's); incl: an include table entry and an offset in its
    section (16 bits); std: a standard type's code (dst_$type_ref_t
    with tag 0). }
  dst_$rel_t = packed record
    case integer of
      1: (tag: 0..3;
          offset: -16#20000000..16#1FFFFFFF);
      2: (incl_tag: 0..3;
          incl_index: 0..16#3FFF;
          incl_offset: 0..65535);
      3: (std_zero: 0..16#FFFFFF;
          std_dtc: 0..255);
  end;
  dst_$type_ref_t = dst_$rel_t;

  { A source location: the file (an index of the section's local file
    table, or the main file table's) and the line. }
  dst_$src_loc_t = packed record
    unused: boolean;
    file_index: 0..2047;
    line: 0..16#FFFFF;
  end;

  { A record field's position: format 0 a byte offset; format 1 a bit
    field (its width, a flag, its first bit) and a byte offset of 16
    bits. }
  dst_$field_loc_t = packed record
    case integer of
      1: (tag: 0..3;
          offset: 0..16#3FFFFFFF);
      2: (bf_tag: 0..3;
          nbits: 0..63;
          flag: boolean;
          start_bit: 0..7;
          zero: 0..15;
          bf_offset: 0..65535);
  end;

  dst_$short_field_t = packed record
    name: dst_$rel_t;
    type_ref: dst_$type_ref_t;
    offset: 0..65535;
  end;

  dst_$field_t = packed record
    name: dst_$rel_t;
    type_ref: dst_$type_ref_t;
    loc: dst_$field_loc_t;
  end;

  dst_$explicit_element_t = packed record
    name: dst_$rel_t;
    value: integer32;
  end;

  dst_$arg_t = packed record
    var_ref: dst_$rel_t;
    attrs: set of 0..15;
  end;

  dst_$incl_entry_t = packed record
    offset: 0..65535;           { the section's offset in the referring
                                  section's references }
    crc1: integer32;            { the section's CRC (its name) }
    crc2: integer32;
  end;

  dst_$local_file_t = packed record
    id: integer32;
    name: dst_$rel_t;
  end;

  dst_$rec_p_t = ^dst_$rec_t;
  dst_$rec_t = packed record
    kind: 0..255;                               { +0 }
    flags: set of 0..7;                         { +1 }
    case integer of
      { pointer, file, alias (14 bytes) }
      1: (name: dst_$rel_t;                     { +2 }
          src_loc: dst_$src_loc_t;              { +6 }
          type_ref: dst_$type_ref_t;            { +10 }
          { array (36), string (30), offset (34) }
          type_ref2: dst_$type_ref_t;           { +14 }
          l18: integer32;                       { +18 }
          l22: integer32;                       { +22 }
          l26: integer32;                       { +26 }
          case integer of
            1: (l30: integer32;                 { +30: array }
                array_b7: boolean;              { +34 bit 7 }
                array_b6: boolean;              { bit 6 }
                array_b5: boolean;              { bit 5 }
                array_span: 0..3;               { bits 4..3: 0, 1 or 2
                                                  (pds: the span kind) }
                array_b2: boolean;              { bit 2 }
                array_zero: 0..3;               { bits 1..0 }
                array_b35: 0..255);             { +35 }
            2: (offset_w30: integer;            { +30: offset }
                offset_w32: integer));          { +32 }
      { subrange (24 bytes) }
      2: (sub_name: dst_$rel_t;
          sub_src_loc: dst_$src_loc_t;
          sub_type_ref: dst_$type_ref_t;
          sub_l14: integer32;                   { +14 }
          sub_l18: integer32;                   { +18 }
          sub_w22: integer);                    { +22 }
      { set (18 bytes) }
      3: (set_name: dst_$rel_t;
          set_src_loc: dst_$src_loc_t;
          set_type_ref: dst_$type_ref_t;
          set_nelements: integer;               { +14 }
          set_size: integer);                   { +16 }
      { implicit and explicit enumerations, short records, records:
        the size and the count, then the elements }
      4: (agg_name: dst_$rel_t;
          agg_src_loc: dst_$src_loc_t;
          agg_w10: integer;                     { +10: a record's size,
                                                  an enumeration's
                                                  elements }
          agg_w12: integer;                     { +12: a record's fields,
                                                  an enumeration's size }
          case integer of
            1: (implicit: array [1..8000] of dst_$rel_t);   { +14 }
            2: (explicit: array [1..4000] of dst_$explicit_element_t);
            3: (short_fields: array [1..3000] of dst_$short_field_t);
            4: (fields: array [1..2700] of dst_$field_t));
      { constant (16 bytes and the value) }
      5: (con_name: dst_$rel_t;
          con_src_loc: dst_$src_loc_t;
          con_type_ref: dst_$type_ref_t;
          con_len: integer;                     { +14 }
          con_value: array [1..32767] of char); { +16 }
      { variable (20), label (14), entry (20) }
      6: (obj_name: dst_$rel_t;                 { +2 }
          obj_loc: dst_$rel_t;                  { +6 }
          obj_src_loc: dst_$src_loc_t;          { +10 }
          case integer of
            1: (var_type_ref: dst_$type_ref_t;  { +14 }
                var_attrs: set of 0..15);       { +18 }
            2: (entry_signature: dst_$rel_t;    { +14 }
                entry_b18: 0..255;              { +18 }
                entry_b19: 0..255));            { +19 }
      { signature (16 bytes and 6 per argument) }
      7: (sig_name: dst_$rel_t;
          sig_src_loc: dst_$src_loc_t;
          sig_result: dst_$rel_t;               { +10 }
          sig_nargs: integer;                   { +14 }
          sig_args: array [1..4000] of dst_$arg_t);   { +16 }
      { include start scope (6 bytes) }
      8: (scope_root: dst_$rel_t);              { +2 }
      { string table, location pool (6 bytes and the text) }
      9: (text_len: integer32;                  { +2 }
          text: array [1..163802] of char);     { +6 }
      { include table (4 bytes and 10 per entry) }
      10: (incl_count: integer;                 { +2 }
           incl: array [0..2047] of dst_$incl_entry_t);   { +4 }
      { local file table (4 bytes and 8 per file) }
      11: (lft_count: integer;                  { +2 }
           lft: array [1..2047] of dst_$local_file_t);    { +4 }
      { section header (10 bytes) }
      12: (hdr_local_files: dst_$rel_t;         { +2 }
           hdr_incl_table: dst_$rel_t);         { +6 }
      { auxiliary records }
      13: (aux_l2: integer32);                  { size }
      14: (aux_w2: integer;                     { align, field size,
                                                  field offset, field
                                                  align, var bound,
                                                  reg val }
           case integer of
             1: (aux_l4: integer32);
             2: (aux_w4: integer);
             3: (aux_ref4: dst_$rel_t));
      15: (aux_ref2: dst_$rel_t;                { name, lifetime, ptr
                                                  base, type deriv }
           aux_w6: integer;                     { +6 }
           aux_deriv_flags: packed record       { +8 }
             flag: boolean;
             zero: 0..16#7FFF;
           end);
  end;
