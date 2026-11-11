{ lang/common/source/pds.pvt.pas - pds.pas's private declarations: the
  records PDS_ builds (one per debugging symbol, with its auxiliary
  records), and the buckets that hold them (one per file whose records
  go to their own section, the main file's being the .symbols
  section's).

  No Apollo copy survives; read off pds.pas (cc.m68k 0x069B08..
  0x071C70, the same in cc.a88k).  pds.pas opens it after pds.ins.pas
  and dst.ins.pas, whose types it uses.

  A record (rec_t) is a 32-byte header and the kind's fields from +32:
  its kind, its auxiliary records' list, flags, the bucket's list link,
  the bucket, the DST record written for it, its offset in the object
  file, and (for a root record) the lowest record ordered under it.

  Not known from the original: every name here.
}

const
  { Record kinds (rec_t.kind; get_bucket_index, dump_rec, ...). }
  pointer_kind = 0;
  kind_1 = 1;                   { accepted by get_name_p only }
  array_kind = 2;
  subrange_kind = 3;
  set_kind = 4;
  implicit_enum_kind = 5;
  explicit_enum_kind = 6;
  short_record_kind = 7;
  record_kind = 8;
  file_kind = 9;
  offset_kind = 10;
  alias_kind = 11;
  string_kind = 12;
  constant_kind = 13;
  variable_kind = 14;
  label_kind = 15;
  entry_kind = 16;
  signature_kind = 17;
  end_scope_kind = 20;
  incl_start_scope_kind = 21;
  incl_end_scope_kind = 22;
  max_kind = 22;

  { Auxiliary record kinds (aux_t.kind). }
  aux_size = 0;
  aux_align = 1;
  aux_field_size = 2;
  aux_field_off = 3;
  aux_field_align = 4;
  aux_name = 5;
  aux_var_bound = 6;
  aux_type_deriv = 7;
  aux_lifetime = 8;
  aux_ptr_base = 9;
  aux_reg_val = 10;

  { rec_t.flags and aux_t.flags elements. }
  processed_flag = 0;           { process_symbols_rec has seen it }
  in_bucket_flag = 1;           { on its bucket's root list }
  ordering_flag = 2;            { order_this_rec has seen it }
  ordered_flag = 3;             { on its bucket's ordered list }
  written_flag = 4;             { its DST record allocated }

  { bucket_t.dfs_flags elements. }
  visited_flag = 0;
  on_dfs_list_flag = 1;

  { The type code of a user defined type (one with a record). }
  user_type_code = 22;

  { The most a single DST record may take (the object file's mapping). }
  max_dst_rec_size = 163808;

type
  flags_t = set of 0..15;

  name_p_t = ^name_t;
  name_t = record
    len: 0..65535;                      { +0 }
    offset: integer32;                  { +2: in the object file (the
                                          string table's text) }
    chars: array [1..4096] of char;     { +6 }
  end;

  src_loc_p_t = ^src_loc_t;
  src_loc_t = record
    file_index: integer;                { +0 }
    line: integer32;                    { +2 }
  end;

  loc_p_t = ^loc_t;
  loc_t = record
    pool: univ_ptr;                     { +0: the location pool }
    offset: integer32;                  { +4 }
  end;

  rec_p_t = ^rec_t;
  bucket_p_t = ^bucket_t;
  aux_p_t = ^aux_t;

  type_p_t = ^type_t;
  type_t = record
    code: integer;                      { +0: 0..22 }
    rec: rec_p_t;                       { +2: user_type_code's }
  end;

  attrs_p_t = pds_$attrs_p_t;

  { A record's size (alloc_rec zero-extends it). }
  rec_size_t = 0..65535;

  arg_p_t = ^arg_t;
  arg_t = record
    var_rec: rec_p_t;                   { +0: the argument's variable }
    attrs: attrs_p_t;                   { +4 }
  end;

  file_entry_p_t = ^file_entry_t;
  file_entry_t = record
    id: integer32;                      { +0 }
    name: name_p_t;                     { +4 }
  end;

  file_table_p_t = ^file_table_t;
  file_table_t = record
    nfiles: integer;                    { +0 }
    main_index: integer;                { +2 }
    entries: array [1..2047] of file_entry_p_t;     { +4 }
  end;

  value_p_t = ^value_t;
  value_t = record
    len: 0..65535;                      { +0 }
    bytes: array [1..32767] of char;    { +2 }
  end;

  element_p_t = ^element_t;
  element_t = record
    name: name_p_t;                     { +0 }
    value: integer32;                   { +4 }
  end;

  short_field_p_t = ^short_field_t;
  short_field_t = record
    name: name_p_t;                     { +0 }
    type_p: type_p_t;                   { +4 }
    offset: 0..2147483647;              { +8 }
  end;

  field_p_t = ^field_t;
  field_t = record
    name: name_p_t;                     { +0 }
    type_p: type_p_t;                   { +4 }
    offset: 0..2147483647;              { +8 }
    format: integer;                    { +12: 0 bytes, 1 bits }
    nbits: integer;                     { +14 }
    flag: boolean;                      { +16 }
    start_bit: integer;                 { +18 }
  end;

  rec_t = record
    kind: integer;                      { +0 }
    aux_head: aux_p_t;                  { +2 }
    aux_tail: aux_p_t;                  { +6 }
    flags: flags_t;                     { +10 }
    next: rec_p_t;                      { +12: the bucket's list }
    bucket: bucket_p_t;                 { +16 }
    dst: dst_$rec_p_t;                  { +20 }
    offset: integer32;                  { +24 }
    lowest: rec_p_t;                    { +28 }
    case integer of
      1: (name: name_p_t;               { +32 }
          case integer of
            { pointer, file, alias, subrange, set, array, string,
              offset, constant }
            1: (src_loc: src_loc_p_t;   { +36 }
                type_p: type_p_t;       { +40 }
                case integer of
                  1: (type2: type_p_t;  { +44: array, string, offset }
                      l48: integer32;   { +48 }
                      l52: integer32;   { +52 }
                      l56: integer32;   { +56 }
                      case integer of
                        1: (l60: integer32;         { +60: array }
                            b64: boolean;           { +64 }
                            b65: boolean;           { +65 }
                            b66: boolean;           { +66 }
                            span: integer;          { +68 }
                            b70: boolean;           { +70 }
                            w72: integer);          { +72 }
                        2: (w60: integer;           { +60: offset }
                            w62: integer));         { +62 }
                  2: (sub_l44: integer32;           { +44: subrange }
                      sub_l48: integer32;           { +48 }
                      sub_size: integer);           { +52 }
                  3: (set_nelements: integer;       { +44: set }
                      set_size: integer);           { +46 }
                  4: (value: value_p_t));           { +44: constant }
            { enumerations, records }
            2: (agg_src_loc: src_loc_p_t;           { +36 }
                case integer of
                  1: (enum_nelements: integer;      { +40 }
                      enum_size: integer;           { +42 }
                      case integer of
                        1: (implicit: array [1..8000] of name_p_t);
                        2: (explicit: array [1..8000] of element_p_t));
                  2: (rec_size: integer;            { +40 }
                      rec_nfields: integer;         { +42 }
                      case integer of
                        1: (short_fields: array [1..8000] of
                              short_field_p_t);     { +44 }
                        2: (fields: array [1..8000] of field_p_t)));
            { variable, label, entry: the location first }
            3: (loc: loc_p_t;                       { +36 }
                obj_src_loc: src_loc_p_t;           { +40 }
                case integer of
                  1: (var_type: type_p_t;           { +44 }
                      var_attrs: attrs_p_t);        { +48 }
                  2: (signature: rec_p_t;           { +44 }
                      entry_w48: integer));         { +48 }
            { signature }
            4: (sig_src_loc: src_loc_p_t;           { +36 }
                sig_result: rec_p_t;                { +40: a variable }
                nargs: integer;                     { +44 }
                args: array [1..8000] of arg_p_t)); { +46 }
      { include start scope }
      2: (root: rec_p_t);                           { +32 }
  end;

  aux_t = record
    kind: integer;                      { +0 }
    next: aux_p_t;                      { +2 }
    bucket: bucket_p_t;                 { +6 }
    dst: dst_$rec_p_t;                  { +10 }
    flags: flags_t;                     { +14 }
    offset: integer32;                  { +16 }
    case integer of
      1: (l20: integer32);              { +20: size }
      2: (w20: integer;                 { +20 }
          case integer of
            1: (l22: integer32);        { +22 }
            2: (w22: integer);
            3: (p22: univ_ptr));
      3: (p20: univ_ptr;                { +20 }
          w24: integer;                 { +24 }
          b26: boolean);                { +26 }
  end;

  { The buckets' string pool, include (CRC) table and local file
    table: hash chains. }
  string_node_p_t = ^string_node_t;
  string_node_t = record
    name: name_p_t;                     { +0 }
    next: string_node_p_t;              { +4 }
  end;

  crc_node_p_t = ^crc_node_t;
  crc_node_t = record
    bucket: bucket_p_t;                 { +0: the section referred to }
    offset: integer;                    { +4 }
    index: integer;                     { +6: from 0 }
    next: crc_node_p_t;                 { +8 }
  end;

  lf_node_p_t = ^lf_node_t;
  lf_node_t = record
    entry: file_entry_t;                { +0: a copy of the file's }
    index: integer;                     { +8: from 1 }
    next: lf_node_p_t;                  { +10 }
  end;

  { A list of buckets (the DAG's edges and nodes, the merge list). }
  bucket_list_p_t = ^bucket_list_t;
  bucket_list_t = record
    bucket: bucket_p_t;                 { +0 }
    next: bucket_list_p_t;              { +4 }
  end;

  { The files whose records a scope or a bucket refers to. }
  bits_p_t = ^bits_t;
  bits_t = packed array [1..2048] of boolean;

  bucket_t = record
    is_include: boolean;                { +0 }
    crc1: integer32;                    { +2 }
    crc2: integer32;                    { +6 }
    first_root: rec_p_t;                { +10 }
    last_root: rec_p_t;                 { +14 }
    first_ordered: rec_p_t;             { +18 }
    last_ordered: rec_p_t;              { +22 }
    strings: array [0..255] of string_node_p_t;     { +26 }
    string_size: integer32;             { +1050 }
    section: integer32;                 { +1054 }
    base: integer32;                    { +1058 }
    header: dst_$rec_p_t;               { +1062 }
    header_offset: integer32;           { +1066 }
    crcs: array [0..255] of crc_node_p_t;           { +1070 }
    crc_count: integer;                 { +2094 }
    local_files: array [0..255] of lf_node_p_t;     { +2096 }
    local_file_count: integer;          { +3120 }
    first_offset: integer32;            { +3122 }
    size: integer32;                    { +3126 }
    refs: bits_p_t;                     { +3130 }
    dfs_flags: flags_t;                 { +3134 }
    succs: bucket_list_p_t;             { +3136 }
    preds: bucket_list_p_t;             { +3140 }
    pending_succs: integer;             { +3144: successors not yet
                                          ordered }
    dfs_next: bucket_p_t;               { +3146 }
    dfs_prev: bucket_p_t;               { +3150 }
  end;

  { The DAG's visit numbers and stack (1-based arrays of words). }
  words_p_t = ^words_t;
  words_t = array [1..2048] of integer;

  bucket_table_p_t = ^bucket_table_t;
  bucket_table_t = array [1..2047] of bucket_p_t;

  { An offset in a section: an include table entry holds the high word,
    a reference through it the low word. }
  split_t = record
    case integer of
      1: (all: integer32);
      2: (high: integer;
          low: integer);
  end;

  { The object file's bytes a CRC is taken over. }
  crc_block_t = record
    q0, q1, q2, q3: integer32;
  end;
  crc_blocks_p_t = ^array [1..10238] of crc_block_t;
  crc_bytes_p_t = ^array [1..163808] of char;
