{ lang/c_compiler/source/c_objtype.ins.pas - the C front end's object
  types: what the front end's units (and add_node, attributes,
  error_listing, inc_list and runbackend, which open it after the
  prelude) share beyond the prelude's IL node.

  Every front-end unit opens it first after the prelude, then
  c_globals.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: every name here.
}

{ TODO(pascal) c_objtype.ins.pas is incomplete

  The type nodes' variants, the symbols (c_sym_t) and the structure
  fields (c_field_t) hold the fields c_sym_map reads; the other fields
  are named unused_N by offset until c_def_sem, c_expr_sem and
  c_syntax are translated (kinds 124..126, 133, 135, 136 and 210 have
  no variant yet).  The kinds named by c_sym_map's map: 105 program,
  106 module, 107 procedure, 108 function (blocks, and the types of
  routines), 109 variable, 116 constant, 117 label, 118 typedef, 119
  and 120 fields (120 a bit field), 121 (a type wrapping +16), 122
  integral, 123 floating, 127 and 131 arrays, 128 subrange, 129
  enumeration, 130 pointer, 132 structure or union, 134 set, 172 a
  block's inner scope (+8 the enclosing block), 234 function
  returning. }

type
  { A longword of attribute bits, tested by number (`btst', element k
    the k-th bit from the low-order end): a variable's, a field's or a
    typedef's flags (c_sym_map's print_attr: 0 volatile, 1 atomic, 3
    device read, 4 device write, 8 uplevel addressed, 31 const), and
    c_attr_t's sets. }
  c_flags_t = set of 0..31;

  { Attributes: a 14-byte record.  c_sym_map's print_attr reads +4 (a
    set: 0 volatile, 2 atomic, 3 device read, 4 device write, 12 and 13
    aligned, 13 naturally aligned, 19 const; `btst' on the bytes and
    words that hold them, `andi.l #0x3000') and the alignment at +8 (a
    word) of a variable's attributes (+36), a pointer's (+12), an
    array's (+16) and a field's (+24).  A typedef keeps the other form
    (c_sym_map's tattr_to_vattr: the longwords at +0 and +4 exchanged,
    and the words at +8 and +10).

    Not known from the original: whether the two forms were distinct
    types; the meaning of +0, +10 and +12. }
  c_attr_t = record
    other_bits: c_flags_t;              { +0 }
    bits: c_flags_t;                    { +4 }
    align: integer;                     { +8: Aligned(n)'s n }
    unused_10: integer;                 { +10 }
    unused_12: integer;                 { +12 }
  end;

  { How a variable is allocated (c_sym_t's var_vat, a word; c_sym_map's
    print_vat names them in this order: local, stat, dynm, ext, extdef,
    param, xdynm, xstat, xextdef, based, sect, abs). }
  c_vat_t = (vat_local, vat_stat, vat_dynm, vat_ext, vat_extdef,
             vat_param, vat_xdynm, vat_xstat, vat_xextdef, vat_based,
             vat_sect, vat_abs);

  c_field_ptr_t = ^c_field_t;
  c_sym_ptr_t = ^c_sym_t;

  { An enumeration's constants (c_type_t's enum_list), from 1: symbols
    of kind 116, or il_178. }
  c_enum_list_t = array [1..16383] of il_$node_ptr_t;

  { A type node as the front end reads it: the IL node header (a word,
    the kind at +2), then by kind.  The fields below are those the
    translated units read; type_exp (c_def_sem.pas 0x04590A) shows more
    (kind 118 a name whose type is at +28; 109, 119, 120, 121 with a
    bit size and an attribute longword). }
  c_type_ptr_t = ^c_type_t;
  c_type_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      { Integral (122) and floating (123) types. }
      1: (len: integer;                 { +4: integral: 1, 2 or 4
                                          bytes; floating: 6 float,
                                          7 double (init_basic_types;
                                          type_exp: size 4, 8) }
          signed: boolean);             { +6: integral: signed
                                          (init_basic_types `st',
                                          `clr.b'; type_exp `tst.b;
                                          bpl') }
      { A subrange (128): its base type and its bounds' constant nodes
        (c_sym_map's print_type prints low..high with print_con). }
      2: (sub_base: c_type_ptr_t;       { +4 }
          sub_low: il_$node_ptr_t;      { +8 }
          sub_high: il_$node_ptr_t);    { +12 }
      { An enumeration (129): its constants and the integral type that
        holds it (short_type for a `short enum'). }
      3: (enum_unused_4: integer;       { +4 }
          enum_count: integer;          { +6 }
          enum_unused_8: integer32;     { +8 }
          enum_unused_12: integer32;    { +12 }
          enum_list: ^c_enum_list_t;    { +16 }
          enum_int: c_type_ptr_t);      { +20 }
      { A pointer (130). }
      4: (ptr_to: c_type_ptr_t;         { +4 }
          ptr_unused_8: integer32;      { +8 }
          ptr_attr: c_attr_t);          { +12 }
      { An array (127, 131): the element and index types; the size at
        +40 (type_exp). }
      5: (arr_elem: c_type_ptr_t;       { +4 }
          arr_index: c_type_ptr_t;      { +8 }
          arr_unused_12: integer32;     { +12 }
          arr_attr: c_attr_t;           { +16 }
          arr_unused_30: integer;       { +30 }
          arr_unused_32: integer32;     { +32 }
          arr_unused_36: integer32;     { +36 }
          arr_size: integer32);         { +40 }
      { A set (134): its base type; the size at +12 (type_exp). }
      6: (set_base: c_type_ptr_t;       { +4 }
          set_unused_8: integer32;      { +8 }
          set_size: integer32);         { +12 }
      { A structure or union (132): its fields, its size, and the number
        c_sym_map's map gives it when it first prints it (`-MAP#n'; 0
        until then). }
      7: (su_fields: c_field_ptr_t;     { +4 }
          su_size: integer32;           { +8 }
          su_unused: array [3..10] of integer32;  { +12..+43 }
          su_map: integer32);           { +44 }
      { Kind 121: print_type looks through it to the type at +16. }
      8: (wrap_unused: array [1..3] of integer32;  { +4..+15 }
          wrap_type: c_type_ptr_t);     { +16 }
      { A function returning (234). }
      9: (fn_unused_4: integer32;       { +4 }
          fn_result: c_type_ptr_t);     { +8 }
      { A typedef's symbol used as a type (118, a c_sym_t): its name;
        its type at +28. }
      10: (tn_name: il_$node_ptr_t);    { +4 }
  end;

  { A structure's or union's field (119; 120 a bit field), chained
    from su_fields.  c_sym_map's print_type prints the name (unless it
    is csyn_50), the offset, a bit field's width, position and
    signedness, the attributes and the type. }
  c_field_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    next: c_field_ptr_t;                { +4 }
    name: il_$node_ptr_t;               { +8: the identifier }
    unused_12: integer32;               { +12 }
    ftype: c_type_ptr_t;                { +16 }
    flags: c_flags_t;                   { +20: print_attr's flags }
    attr: c_attr_t;                     { +24 }
    unused_38: integer;                 { +38 }
    unused_40: integer32;               { +40 }
    offset: integer32;                  { +44 }
    bits: packed record                 { +48: a bit field's }
      unused_7: boolean;                { .7 }
      signed: boolean;                  { .6: `btst #6' }
      width: 0..63;                     { .5..0: `moveq #63; and.b' }
      at: 0..255;                       { +49: the bit position }
    end;
  end;

  { A symbol: an entry of an identifier's chain of meanings (the
    identifier's +8, idnt_unused_8 in il.ins.pas), linked through
    next.  c_sym_map's sym_map prints variables (109), constants (116),
    labels (117) and typedefs (118), and the other kinds with prtobj. }
  c_sym_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    name: il_$node_ptr_t;               { +4: the identifier }
    line: integer;                      { +8: where it was declared
                                          (spos's encoding) }
    unused_10: integer;                 { +10 }
    next: c_sym_ptr_t;                  { +12: the identifier's next
                                          meaning }
    unused_16: integer32;               { +16 }
    block: il_$node_ptr_t;              { +20: the block (a kind 172
                                          scope's +8 is the block
                                          enclosing it) }
    unused_24: integer32;               { +24 }
    case integer of
      { A variable (109). }
      1: (var_type: c_type_ptr_t;       { +28 }
          var_flags: c_flags_t;         { +32: print_attr's flags;
                                          sym_map omits a variable
                                          with 14 }
          var_attr: c_attr_t;           { +36 }
          var_unused_50: integer;       { +50 }
          var_unused_52: integer32;     { +52 }
          var_offset: integer32;        { +56: from its base (sym_map
                                          adds the frame's or
                                          section's offset) }
          var_unused_60: integer32;     { +60 }
          var_unused_64: integer32;     { +64 }
          var_unused_68: integer32;     { +68 }
          var_vat: c_vat_t;             { +72 }
          var_unused_74: integer;       { +74 }
          var_unused_76: integer32;     { +76 }
          var_sect: il_$node_ptr_t);    { +80: vat_sect's section, +4
                                          its name }
      { A typedef (118). }
      2: (td_type: c_type_ptr_t;        { +28 }
          td_unused_32: integer32;      { +32 }
          td_flags: c_flags_t;          { +36 }
          td_attr: c_attr_t);           { +40: the other form }
      { A constant (116; an enumeration's constants). }
      3: (con_type: c_type_ptr_t;       { +28 }
          con_value: il_$node_ptr_t);   { +32: the value's constant
                                          node }
      { A label (117): its IL label (kind 144, +56 its address once
        placed). }
      4: (lab_node: il_$node_ptr_t);    { +28 }
  end;

  { What type_exp (c_def_sem.pas 0x04590A) makes of a type node: the
    callers pass the address of a 28-byte frame temporary (def_blk_params
    0x048B70 `pea (-72,A6)'; c_expr_sem's basic types are 64-byte
    entries at +0x36C of its data, each beginning with one).  type_exp
    stores +0 and +4, copies 12 bytes of defaults to +8..+19 (0x045926),
    sets +24.1 and clears +25.6 before dispatching on the node's kind.

    get_rlen (c_get_rlen.pas) reads base^.kind, base's word at +4 (kind
    123) and size. }
  type_exp_ptr_t = ^type_exp_t;
  type_exp_t = record
    base: c_type_ptr_t;                 { +0: the type with names
                                          expanded (type_exp recurses
                                          through kind 118 and stores
                                          the inner node here) }
    node: c_type_ptr_t;                 { +4: the type node passed }
    low: integer32;                     { +8: the least value (integral
                                          kinds 122 and 129: -32768
                                          for a 2-byte signed type) }
    high: integer32;                    { +12: the greatest (32767,
                                          255, 65535, 16#7FFFFFFF) }
    size: integer32;                    { +16: bytes (1, 2, 4; 8 for a
                                          kind 123 of length other than
                                          6; 128 for kind 136; 0 for
                                          kind 210) }
    bytes: integer32;                   { +20: the storage size in
                                          bytes (from a bit size, +7
                                          div 8), else size }
    flags: packed record
      align: -16..15;                   { +24.7..3: the alignment (log2
                                          of bytes; attr_set_align_dsc
                                          sets it from the attributes
                                          and may lower it to the
                                          type's; type_exp lowers it
                                          back) }
      align_attr: boolean;              { .2: an Aligned attribute set
                                          it (attr_set_align_dsc);
                                          attr_check_align warns of it
                                          only at -INFO 4 and above }
      align_ok: boolean;                { .1: aligned at least
                                          naturally, or not worth a
                                          warning (set by type_exp and
                                          attr_set_align_dsc, and by
                                          attr_check_align once it has
                                          warned) }
      b24_0: boolean;                   { .0: cleared by
                                          attr_set_align_dsc for
                                          variables, kind 121, 108 and
                                          174; attr_check_align does not
                                          warn while it is set }
      b25_7: boolean;                   { +25.7 }
      ranged: boolean;                  { .6: low and high are known
                                          (integral kinds) }
      b25_5: boolean;                   { .5: from the node's attribute
                                          bit 19 }
      b25_4: boolean;                   { .4: from the node's attribute
                                          bit 0 of its last byte }
      b25_3: boolean;
      b25_2: boolean;
      b25_1: boolean;
      b25_0: boolean;
    end;
  end;

  { An identifier with the line it was met on: 8 bytes (c_lex_pp's
    module_sem copies two longwords into a module block; c_main's
    make_main_pgm and cc pass them by address to def_blk_skeleton,
    fnd_name and body_opr; c_def_sem's, c_syntax's and c_stmt_sem's
    data hold such pairs).

    Not known from the original: the names; +6. }
  c_name_t = record
    id: il_$node_ptr_t;                 { +0 }
    line: integer;                      { +4 }
    unused_6: integer;                  { +6 }
  end;

  { What def_blk_skeleton takes as its fourth argument (c_main's cc,
    +0x400 of its data, and make_main_pgm, a frame record): 40 bytes,
    of which these are set.

    Not known from the original: everything but the offsets. }
  c_decl_t = record
    dtype: univ_ptr;                    { +0: int_type or il_178 }
    name: univ_ptr;                     { +4 }
    unused_8: integer32;                { +8 }
    unused_12: integer32;               { +12: cleared }
    unused_16: array [4..7] of integer32;  { +16..+31 }
    line: integer;                      { +32 }
    unused_34: integer;                 { +34 }
    unused_36: integer32;               { +36 }
  end;

  { An entry of c_expr_sem's expression stack (cexs_stack, 64 bytes):
    c_main's make_main_pgm sets the top entry's node from its +28;
    attributes's attr_check_align names +4 in its diagnostic and reads
    and sets the flags of the type_exp_t at +28 (+52; the brief's
    `table at +0x354' is +4 of these entries).  c_expr_sem's basic
    types are such entries (their type_exp_t at +0x36C).

    Not known from the original: everything but the offsets; whether
    +28 was one field (the symbol c_main reads is where a type_exp_t's
    base lies). }
  c_exp_t = record
    node: il_$node_ptr_t;               { +0 }
    name: il_$node_ptr_t;               { +4: what the operand is called
                                          (attr_check_align's error1
                                          argument) }
    unused_8: array [3..7] of integer32;   { +8..+27 }
    case integer of
      1: (sym: il_$node_ptr_t);         { +28 }
      2: (texp: type_exp_t;             { +28..+53: the operand's type }
          unused_54: integer;           { +54 }
          unused_56: array [15..16] of integer32);  { +56..+63 }
  end;

  { An identifier entry as a block of its own: the kind and the rest
    (c_main copies an identifier's +4..+4113 into c_lex_pp's
    kw_options and kw_attribute after setting their kinds), laid out as
    il.ins.pas's identifier variant. }
  c_kw_body_t = record
    next: il_$node_ptr_t;               { +4 }
    unused_8: integer32;                { +8 }
    unused_12: integer32;               { +12 }
    len: integer;                       { +16 }
    name: array [1..4096] of char;      { +18 }
  end;
  c_kw_node_ptr_t = ^c_kw_node_t;
  c_kw_node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    body: c_kw_body_t;                  { +4 }
  end;
