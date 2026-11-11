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

    A pointer's attributes (+12) hold a size in bits at +0: c_expr_syn's
    unary_expr and primary_expr take a dereferenced pointer's storage
    size as (+0 + 7) div 8 (`addq.l #7; bpl; addq.l #7; asr.l #3').

    Not known from the original: whether the two forms were distinct
    types; the meaning of +0, +10 and +12. }
  c_attr_t = record
    case integer of
      1: (other_bits: c_flags_t;        { +0 }
          bits: c_flags_t;              { +4 }
          align: integer;               { +8: Aligned(n)'s n }
          unused_10: integer;           { +10 }
          unused_12: integer);          { +12 }
      2: (size_bits: integer32);        { +0: the vattr form's size }
  end;

  { A set of token classes (the ctk_ constants of c_globals.ins.pas, 0..111):
    the follow sets the parser passes down (14 bytes, by address;
    c_expr_syn's routines `or' constants into a copy, `btst' with the
    byte index (111 - k) div 8). }
  c_tokset_t = set of 0..111;

  { How a variable is allocated (c_sym_t's var_vat, a word; c_sym_map's
    print_vat names them in this order: local, stat, dynm, ext, extdef,
    param, xdynm, xstat, xextdef, based, sect, abs). }
  c_vat_t = (vat_local, vat_stat, vat_dynm, vat_ext, vat_extdef,
             vat_param, vat_xdynm, vat_xstat, vat_xextdef, vat_based,
             vat_sect, vat_abs);

  c_field_ptr_t = ^c_field_t;
  c_sym_ptr_t = ^c_sym_t;
  c_type_ptr_t = ^c_type_t;
  c_tag_ptr_t = ^c_tag_t;
  c_parm_ptr_t = ^c_parm_t;

  { A declaration's attributes as the parser collects them (c_decl_t's
    +12..+31, 20 bytes; a typedef's +40, a routine block's +312, the
    structure being laid out's +8): c_def_sem copies them whole into a
    frame record, merges the type's into them (merge_attribs,
    merge_attribs_natural) and converts them to a symbol's form
    (attr_tattr_to_vattr: the size in bits first).  def_fld stores w10
    as a field's alignment, def_arr and def_rec raise it to x12.

    Not known from the original: the names; w14. }
  c_dattr_ptr_t = ^c_dattr_t;
  c_dattr_t = record
    flags: c_flags_t;                   { +0: 3 device read, 4 device
                                          write (or-ed into a
                                          structure's), 5 address(n)
                                          given (x16 the address), 12
                                          an alignment was given, 16
                                          section(name) given (x16
                                          the name), 20 a bit field
                                          declared signed }
    size_bits: integer32;               { +4: 0 for the type's }
    align: integer;                     { +8: the alignment wanted (a
                                          power of 2) }
    w10: integer;                       { +10: the alignment met }
    x12: integer;                       { +12: the least alignment }
    w14: integer;                       { +14 }
    x16: integer32;                     { +16 }
  end;

  { A routine's parameter types (a function type's fn_params, a block's
    params): a word, the count at +2, then the types from +4 (kind 31,
    an ellipsis, ends a variable list; c_expr_syn's func_call_stat
    checks arguments against them under -TYPE).  c_expr_syn's
    c_expr_syn_$begin_compilation builds the builtins' lists with
    gspace(4 + 4n). }
  c_parlist_ptr_t = ^c_parlist_t;
  c_parlist_t = record
    unused_0: integer;                  { +0 }
    count: integer;                     { +2 }
    types: array [1..1024] of c_type_ptr_t;  { +4 }
  end;

  { An enumeration's constants (c_type_t's enum_list), from 1: symbols
    of kind 116, or il_178. }
  c_enum_list_t = array [1..16383] of il_$node_ptr_t;

  { A type node as the front end reads it: the IL node header (a word,
    the kind at +2), then by kind.  The fields below are those the
    translated units read; type_exp (c_def_sem.pas 0x04590A) shows more
    (kind 118 a name whose type is at +28; 109, 119, 120, 121 with a
    bit size and an attribute longword). }
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
      { An enumeration (129; 60 bytes from c_def_sem's
        def_enum_skeleton): its constants and the integral type that
        holds it (short_type for a `short enum'; def_enum_list widens
        it to the unsigned type when the values need it), and the
        values' extremes, signed and unsigned (def_enum_list). }
      3: (enum_unused_4: integer;       { +4 }
          enum_count: integer;          { +6 }
          enum_unused_8: integer32;     { +8 }
          enum_unused_12: integer32;    { +12 }
          enum_list: ^c_enum_list_t;    { +16 }
          enum_int: c_type_ptr_t;       { +20 }
          enum_unused_24: integer32;    { +24 }
          enum_high: integer32;         { +28 }
          enum_low: integer32;          { +32 }
          enum_uhigh: integer32;        { +36: compared unsigned }
          enum_ulow: integer32);        { +40: compared unsigned }
      { A pointer (130; 36 bytes from def_ptr): the type pointed to, its
        attributes (+20 the alignment add_pn is given when the pointer
        is dereferenced, +16 bits 19 const and 0 volatile), and a
        boolean c_expr_syn tests under -TYPE (cargs_$options.type_opt):
        such a pointer is dereferenced where it is used (body_opr 3 after
        a name or a call; a cast to it takes the address first), a
        reference. }
      4: (ptr_to: c_type_ptr_t;         { +4: a forward pointer's
                                          (c_def_sem's def_fwd_ptr) is
                                          the structure tag's identifier
                                          (76) until it is resolved }
          ptr_fwd_next: c_type_ptr_t;   { +8: the forward pointers'
                                          chain (cdef_4c) }
          ptr_attr: c_attr_t;           { +12 }
          ptr_unused_26: integer;       { +26 }
          ptr_unused_28: integer32;     { +28 }
          ptr_line: integer;            { +32: a forward pointer's }
          ptr_reference: boolean);      { +34: `tst.b; bpl' }
      { An array (127, 131; 44 bytes from c_def_sem's def_arr): the
        element and index types (il_178 for no bound), the element's
        size and the array's (+40; type_exp). }
      5: (arr_elem: c_type_ptr_t;       { +4 }
          arr_index: c_type_ptr_t;      { +8 }
          arr_elsize: integer32;        { +12: bytes (0 until the
                                          element is complete:
                                          fix_array_decl) }
          arr_attr: c_attr_t;           { +16 }
          arr_unused_30: integer;       { +30 }
          arr_unused_32: integer32;     { +32 }
          arr_unused_36: integer32;     { +36 }
          arr_size: integer32);         { +40 }
      { A set (134): its base type; the size at +8 (type_exp). }
      6: (set_base: c_type_ptr_t;       { +4 }
          set_size: integer32;          { +8 }
          set_unused_12: integer32);    { +12 }
      { A structure or union (132; 56 bytes from c_def_sem's def_rec):
        its fields (nil while it is incomplete), its size, its
        attributes (+12 the size in bits), whether it holds an array,
        its tag (c_tag_t) and the number c_sym_map's map gives it when
        it first prints it (`-MAP#n'; 0 until then). }
      7: (su_fields: c_field_ptr_t;     { +4 }
          su_size: integer32;           { +8 }
          su_attr: c_attr_t;            { +12 }
          su_unused_26: integer;        { +26 }
          su_unused_28: integer32;      { +28 }
          su_unused_32: integer;        { +32 }
          su_unused_34: boolean;        { +34 }
          su_has_arr: boolean;          { +35 }
          su_tag: c_tag_ptr_t;          { +36 }
          su_unused_40: integer32;      { +40 }
          su_map: integer32);           { +44 }
      { Kind 121: print_type looks through it to the type at +16. }
      8: (wrap_unused: array [1..3] of integer32;  { +4..+15 }
          wrap_type: c_type_ptr_t);     { +16 }
      { A function returning (234; 58 bytes from c_expr_syn's
        alloc_builtins): the result type, the parameters' types (nil
        when there is no prototype) and a word alloc_builtins sets to 3
        and func_call_stat pushes on c_syntax's context stack (csyn_60)
        for the call (a block's calling context, c_blk_t's conv). }
      9: (fn_unused_4: integer32;       { +4: cleared }
          fn_result: c_type_ptr_t;      { +8 }
          fn_params: c_parlist_ptr_t;   { +12 }
          fn_unused_16: integer32;      { +16 }
          fn_unused_20: integer32;      { +20 }
          fn_conv: integer);            { +24 }
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
    line: integer;                      { +12: where it was declared
                                          (c_expr_syn's `&' of a bit
                                          field reports it) }
    unused_14: integer;                 { +14 }
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
    uplevel: boolean;                   { +10: found from an inner block
                                          (c_def_sem's blk_fnd_name) }
    unused_11: char;                    { +11 }
    next: c_sym_ptr_t;                  { +12: the identifier's next
                                          meaning }
    blk_next: il_$node_ptr_t;           { +16: the block's chain of its
                                          variables (add_varn) or labels
                                          (c_stmt_sem's dcl_labl) }
    block: il_$node_ptr_t;              { +20: the block (a kind 172
                                          scope's +8 is the block
                                          enclosing it) }
    unused_24: integer32;               { +24 }
    case integer of
      { A variable (109). }
      1: (var_type: c_type_ptr_t;       { +28 }
          var_flags: c_flags_t;         { +32: print_attr's flags;
                                          sym_map omits a variable
                                          with 14 (c_expr_syn's
                                          do_c_string sets it for a
                                          string's array); c_expr_syn
                                          sets 22 for a constant
                                          subscript within bounds
                                          and tests 10 (c_def_sem's
                                          def_blk_params sets it for a
                                          parameter); c_def_sem: 6 an
                                          initializer was given, 16
                                          allocated in .bss (offset
                                          the bss size before it), 18
                                          allocated (def_alloc_var) }
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
          var_unused_76: integer;       { +76 }
          var_78: integer;              { +78: -1 when made (def_varn,
                                          add_varn) }
          var_sect: il_$node_ptr_t;     { +80: vat_sect's section (111),
                                          +4 its name; il_178 when made
                                          (only the 88-byte variables
                                          of kinds stat, ext and extdef
                                          have it and the next field) }
          var_sect_next: c_sym_ptr_t);  { +84: the section's next
                                          variable (c_def_sem's
                                          make_comblk_sect) }
      { A typedef (118). }
      2: (td_type: c_type_ptr_t;        { +28 }
          td_unused_32: integer32;      { +32 }
          td_flags: c_flags_t;          { +36 }
          td_attr: c_attr_t);           { +40: the other form }
      { A constant (116; an enumeration's constants). }
      3: (con_type: c_type_ptr_t;       { +28 }
          con_value: il_$node_ptr_t);   { +32: the value's constant
                                          node }
      { A label (117): its IL label (kind 144 once defined, +56 its
        address once placed; il_178 or a chain of branches before),
        the line of the last goto (spos_$null_position at first), and
        a flag body_e copies to the IL label's +74 (cleared by
        dcl_labl). }
      4: (lab_node: il_$node_ptr_t;     { +28 }
          lab_line: integer;            { +32 }
          lab_unused_34: integer;       { +34 }
          lab_bits: packed record       { +36 }
            b36: 0..255;
            used: boolean;              { +37.7 }
            rest: 0..127;
          end);
      { A block-local name of an outer variable (230, 28 bytes from
        c_def_sem's def_virt_varn: an extern declared in a block under
        -XANSI): blk_fnd_name answers the variable instead. }
      5: (virt_sym: c_sym_ptr_t);       { +28 }
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

    The byte at +6 is where a symbol (c_sym_t's +4..+11) or a structure
    tag (c_tag_t's +20..+27), which copy their name whole, keep their
    uplevel flag: c_def_sem's blk_fnd_name and lookup_su set it when
    the name is found in an enclosing block, def_name clears it.

    Not known from the original: the names; +7. }
  c_name_t = record
    id: il_$node_ptr_t;                 { +0 }
    line: integer;                      { +4 }
    uplevel: boolean;                   { +6 }
    unused_7: char;                     { +7 }
  end;

  { What def_blk_skeleton takes as its fourth argument (c_main's cc,
    +0x400 of its data, and make_main_pgm, a frame record): 40 bytes,
    of which these are set.

    +12..+31 are the attributes (c_dattr_t, the variant attr: c_def_sem
    copies them whole); def_fwd_ptr takes +8, when set, as the
    structure tag a pointer is declared to.

    Not known from the original: everything but the offsets. }
  c_decl_t = record
    dtype: univ_ptr;                    { +0: int_type or il_178; a
                                          type (def_subr, def_arr and
                                          c_type_name fill it) }
    name: univ_ptr;                     { +4 }
    unused_8: integer32;                { +8 }
    case integer of
    1: (
    flags: c_flags_t;                   { +12: cleared; c_type_name's
                                          qualifiers (19 const, 0
                                          volatile: c_expr_syn's cast
                                          copies them to type_exp_t's
                                          b25_5 and b25_4) }
    size_bits: integer32;               { +16: an element's size in
                                          bits (do_c_string: 8, 32) }
    align: integer;                     { +20: do_c_string: 0, 2 for
                                          a wide string's element }
    unused_22: integer;                 { +22 }
    unused_24: integer32;               { +24 }
    unused_28: integer32;               { +28: cleared by do_c_string
                                          (add_varn copies +12..+31,
                                          the attributes) }
    line: integer;                      { +32 }
    unused_34: integer;                 { +34 }
    unused_36: integer32);              { +36 }
    2: (
    attr: c_dattr_t);                   { +12..+31 }
  end;

  { An entry of c_expr_sem's expression stack (cexs_stack, 64 bytes;
    cexs_23bc the top).  c_expr_syn reads and sets these fields.

    Not known from the original: the names; +12..+23, +54..+57, +60,
    +62. }
  c_exp_t = record
    node: il_$node_ptr_t;               { +0: the operand's tree (a
                                          constant node, a variable
                                          symbol (109), a tree node
                                          (137, 143, 146, ...)) }
    sym: il_$node_ptr_t;                { +4: what diagnostics name: a
                                          symbol (c_sym_t), a field
                                          (c_field_t, 120) }
    item: il_$node_ptr_t;               { +8: the variable (109) or
                                          string (92) the operand
                                          names, or the type a
                                          dereference gives }
    unused_12: integer32;               { +12 }
    unused_16: integer32;               { +16 }
    unused_20: integer32;               { +20 }
    disp: integer32;                    { +24: compared with 0 and with
                                          typ.size by unary_expr's
                                          `*' }
    typ: type_exp_t;                    { +28..+53: the operand's type
                                          (type_exp) }
    unused_54: integer;                 { +54 }
    unused_56: integer;                 { +56 }
    line: integer;                      { +58: where the operand was
                                          met }
    unused_60: char;                    { +60 }
    flag_61: boolean;                   { +61: `tst.b; bpl' in
                                          unary_expr's `*' }
    unused_62: integer;                 { +62 }
  end;

  { A constant expression's value as c_syntax's constant_expr gives it
    and def_subr takes its bounds (14 bytes, copied as three longwords
    and a word; c_expr_syn's do_c_string builds two).

    Not known from the original: the names. }
  c_cexp_t = record
    ctype: c_type_ptr_t;                { +0 }
    value: il_$node_ptr_t;              { +4: the constant node }
    sym: il_$node_ptr_t;                { +8: what diagnostics name }
    line: integer;                      { +12 }
  end;

  { A block (kinds 105..108; 107 and 108 also the types of routines) as
    the front end reads it: by offset (il.ins.pas's xp, xw views name
    the same words, docs/questions.md 13).

    Not known from the original: the names; the fields not named. }
  c_reglist_ptr_t = ^c_reglist_t;
  c_reglist_t = record                  { a block's register variables;
                                          a tag's incomplete users }
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    rvar: il_$node_ptr_t;               { +4: the variable (109) }
    next: c_reglist_ptr_t;              { +8 }
  end;
  c_blk_ptr_t = ^c_blk_t;
  c_blk_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    next_blk: c_blk_ptr_t;              { +4: the next block made (from
                                          il_17c, def_blk_skeleton) }
    outer: c_blk_ptr_t;                 { +8: the enclosing block
                                          (cdef_outer_block for a
                                          function) }
    old_parms: c_parm_ptr_t;            { +12: the parameters (kind 121,
                                          by name, from add_parm) }
    syms: il_$node_ptr_t;               { +16: its variables (through
                                          c_sym_t's blk_next) }
    unused_20: integer32;               { +20 }
    labels: c_sym_ptr_t;                { +24: its labels (c_stmt_sem) }
    result: c_type_ptr_t;               { +28: a function's result
                                          type (func_call_stat) }
    unused_32: array [8..19] of integer32;  { +32..+79 }
    saved_frame: integer32;             { +80: frame_size between
                                          allocations (c_def_sem's
                                          alloc_on_stk) }
    x84: integer32;                     { +84: 16#FF000000 when made }
    x88: integer32;                     { +88: -1 when made }
    ret_lab: il_$node_ptr_t;            { +92: the return label (return_s
                                          branches to it, body_e places
                                          it) }
    ret_var: c_sym_ptr_t;               { +96: the result's variable (nil
                                          for none; body_e) }
    entry_lab: il_$node_ptr_t;          { +100: placed by body_s }
    end_node: il_$node_ptr_t;           { +104: body_e's 149 node }
    x108: integer32;                    { +108: its data section's +16
                                          (def_blk_params, without
                                          -ABS) }
    frame_size: integer32;              { +112: body_e takes its
                                          absolute value }
    sect_next: il_$node_ptr_t;          { +116: the next block of its
                                          data section's chain (the
                                          section's +12) }
    unused_120: array [30..43] of integer32;  { +120..+175 }
    x176: integer32;                    { +176: added to frame_size }
    unused_180: array [45..46] of integer32;  { +180..+187 }
    code_sect: il_$node_ptr_t;          { +188 (c_main) }
    data_sect: il_$node_ptr_t;          { +192 (c_main; primary_expr
                                          compares it with il_180's) }
    x196: integer32;                    { +196: cleared by body_e in
                                          the outer block }
    unused_200: array [50..56] of integer32;  { +200..+227 }
    x228: integer32;                    { +228: cleared by body_e }
    unused_232: array [58..66] of integer32;  { +232..+267 }
    unused_268: integer;                { +268 }
    end_line: integer;                  { +270: body_e }
    unused_272: array [68..71] of integer32;  { +272..+287 }
    parm_size: integer;                 { +288: the parameters' bytes
                                          (def_blk_params) }
    unused_290: integer;                { +290 }
    lev: packed record                  { +292 }
      b292: 0..255;
      nparms: 0..255;                   { +293: the parameters by name
                                          (def_blk_params); a
                                          prototyped flag (0 or 255)
                                          until then }
      level: -128..127;                 { +294: the nesting (-1 a
                                          module, -2 a declaration
                                          only, 0, 1, a scope's
                                          enclosing block's + 1) }
      b295: 0..255;
    end;
    name: c_name_t;                     { +296: the routine's name
                                          (body_e's diagnostics; a
                                          module's #module name) }
    unused_304: array [76..77] of integer32;  { +304..+311 }
    attr: c_dattr_t;                    { +312: its declaration's }
    ropts: array [83..92] of integer32; { +332..+371: filled by
                                          attributes's
                                          attr_compute_routine_options }
    unused_372: integer;                { +372 }
    bits: packed record                 { +374 }
    case integer of
    1: (
      b374_7: boolean;
      b374_6: boolean;                  { .6: set by unary_expr's `&'
                                          of a variable with flag 10 }
      b374_5: boolean;
      b374_4: boolean;
      b374_3: boolean;
      b374_2: boolean;
      b374_1: boolean;
      b374_0: boolean;
      b375_7: boolean;                  { +375 }
      main_int: boolean;                { .6: main returns int (c_syntax's
                                          body sets it before testing
                                          the result type) }
      b375_5_0: 0..63;
      b376_7: boolean;                  { +376 }
      b376_6: boolean;
      b376_5: boolean;
      db_adjusted: boolean;             { .4: adjust_blk_for_db was
                                          called for it (primary_expr) }
      b376_3: boolean;                  { .3 }
      b376_2: boolean;
      b376_1: boolean;
      x376_0: 0..3;                     { .0 to +377.7 (c_main,
                                          c_sym_map: `andi.w #0x180'):
                                          def_blk_skeleton's class (2 a
                                          declaration only) }
      conv: 0..7;                       { +377 .6..4: the calling
                                          context func_call_stat pushes
                                          on csyn_60 }
      b377_3_0: 0..15);                 { .3..0 }
    { The routine's options (def_blk_skeleton: 1, 2 by the block's
      kind, 4 for setjmp and the like, the caller's; 1024 inside
      #pragma begin_inline, 2048 begin_noinline). }
    2: (
      opts: 0..2097151;                 { +374.7 to +376.3 }
      opts_rest: 0..2047);
    end;
    b378: packed record                 { +378 }
      made: boolean;                    { .7: set by def_blk_skeleton }
      rest: 0..32767;
    end;
    unused_380: integer32;              { +380 }
    reg_vars: c_reglist_ptr_t;          { +384: its register variables
                                          (add_reg_var; unary_expr's
                                          `&') }
    tags: c_tag_ptr_t;                  { +388: its structure, union and
                                          enumeration tags (add_su) }
    params: c_parlist_ptr_t;            { +392: the parameters' types
                                          (func_call_stat) }
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

  { The 16-byte descriptor of an IL tree node's value (a tree node's
    +20, an assignment node's +48; c_expr_sem's init_aux makes one from
    a type_exp_t): the size, the register length class (get_rlen's: 1
    char, 2 short, 4 int, 5 pointer, 6 float, 7 double, 11 other), a
    second class (the source's, in conversions) and flags.

    Not known from the original: the names; +8, +11..+15. }
  c_desc_t = record
    size: integer32;                    { +0 }
    rlen: integer;                      { +4 }
    w6: integer;                        { +6 }
    w8: integer;                        { +8 }
    flags: packed record                { +10 }
      b7: boolean;                      { .7: cleared by call_s }
      b6: boolean;                      { .6: call_s copies it from the
                                          argument's; extend_boolean
                                          sets it }
      rest: 0..63;
      b11: 0..255;                      { +11 }
    end;
    unused_12: integer32;               { +12 }
  end;

  { An IL tree node as c_stmt_sem reads and builds it (kinds 137 an
    operator, 143, 171 a call's designator, ...; c_stmt_sem's
    build_not_expr and build_cond_expr build one in their frames for
    build_assign).  Kinds 145, 146, 147 and 205 have their operand at
    +24 (il.ins.pas's xp[6]) instead.

    Not known from the original: the names; +4, +8..+15. }
  c_tree_ptr_t = ^c_tree_t;
  c_tree_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: integer;                  { +4 }
    bits: packed record                 { +6 }
      b15, b14, b13, b12: boolean;
      done: boolean;                    { .3 (bit 11): call_s, walk_tree
                                          have walked it }
      b10, b9: boolean;
      post: boolean;                    { .0 (bit 8): walk_tree's
                                          post-increment sum }
      b7_0: 0..255;
    end;
    unused_8: integer32;                { +8 }
    unused_12: integer32;               { +12 }
    w16: integer;                       { +16: cleared after
                                          buildtreenode }
    w18: integer;                       { +18: an assignment's kind (29,
                                          30 with a third operand; 10) }
    desc: c_desc_t;                     { +20 }
    op: integer;                        { +36: the operator (54 `=',
                                          12, 13, 14, 16 a call, 18 and
                                          39 conversions, 26 address,
                                          51..57 the logical ones) }
    count: integer;                     { +38: the operands }
    opnd: array [1..64] of il_$node_ptr_t;  { +40: from 1 }
  end;

  { A top-level IL node (c_stmt_sem's add_top_node; chained by
    link_top from il_d4 to il_d8) by kind: 139 an evaluation, 140 an
    assignment, 141 a branch, 142 a conditional branch, 144 a label, 148
    and 149 a routine's start and end, 150, 151 a return.

    Not known from the original: the names; the fields not named. }
  c_top_ptr_t = ^c_top_t;
  c_top_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    prev: il_$node_ptr_t;               { +4 }
    next: il_$node_ptr_t;               { +8 }
    unused_12: integer32;               { +12 }
    unused_16: integer32;               { +16 }
    line: integer;                      { +20 }
    unused_22: integer;                 { +22 }
    unused_24: array [6..9] of integer32;  { +24..+39 }
    hdr: packed record                  { +40 }
      b40: 0..255;
      b41_7, b41_6: boolean;            { +41 }
      ret: boolean;                     { .5: body_e's return node }
      b41_rest: 0..31;
      b42: 0..255;                      { +42 }
      b43: 0..255;                      { +43: cleared by link_top }
      b44: 0..255;                      { +44: cleared by link_top }
      level: 0..255;                    { +45: il_172 (link_top) }
    end;
    unused_46: integer;                 { +46 }
    case integer of
      { 139: the operands evaluated. }
      1: (eval_unused_48: integer;      { +48 }
          eval_count: integer;          { +50 }
          eval_opnd: array [1..64] of il_$node_ptr_t);  { +52 }
      { 140. }
      2: (asg_desc: c_desc_t;           { +48 }
          asg_lhs: il_$node_ptr_t;      { +64 }
          asg_rhs: il_$node_ptr_t;      { +68 }
          asg_x: il_$node_ptr_t;        { +72 }
          asg_op: integer);             { +76 }
      { 141, 142, 150: the label branched to (or, while it is not
        placed, the next branch waiting for it); 142's condition and
        sense. }
      3: (br_target: il_$node_ptr_t;    { +48 }
          br_unused_52: integer32;      { +52 }
          br_cond: il_$node_ptr_t;      { +56 }
          br_sense: boolean);           { +60 }
      { 144 (84 bytes). }
      4: (lab_num: integer;             { +48: il_146's count for its
                                          kind }
          lab_w50: integer;             { +50 }
          lab_unused_52: integer32;     { +52 }
          lab_addr: integer32;          { +56: -1 until placed }
          lab_unused_60: integer32;     { +60 }
          lab_64: integer32;            { +64 }
          lab_unused_68: integer32;     { +68 }
          lab_bits: packed record       { +72 }
            placed: boolean;            { .7 }
            pending: boolean;           { .6: cleared once a branch
                                          reaches it }
            lkind: 0..31;               { .5..1: add_ldfn's kind }
            b0: boolean;
            b73: 0..255;
          end;
          lab_74: boolean;              { +74: body_e (a label symbol's
                                          used) }
          lab_75: boolean;              { +75 }
          lab_unused_76: integer32;     { +76 }
          lab_80: integer32);           { +80 }
      { 148, 149: the block. }
      5: (blk: il_$node_ptr_t);         { +48 }
      { 151: the result variable (nil) and its class. }
      6: (ret_var: il_$node_ptr_t;      { +48 }
          ret_rlen: integer);           { +52 }
  end;

  { A switch statement's record (c_syntax's frame; c_stmt_sem's
    case_s, case_con, case_default, case_e), 112 bytes.

    Not known from the original: the names; +38..+43. }
  c_caselist_ptr_t = ^c_caselist_t;
  c_caselist_t = record                 { 10 bytes from gspace }
    next: c_caselist_ptr_t;             { +0 }
    value: integer32;                   { +4 }
    line: integer;                      { +8 }
  end;
  c_case_t = record
    first: il_$node_ptr_t;              { +0: the evaluation node of the
                                          selector (add_eval) }
    x4: il_$node_ptr_t;                 { +4: il_178 }
    list: c_caselist_ptr_t;             { +8: the constants so far }
    typ: type_exp_t;                    { +12: the selector's type }
    unused_38: integer;                 { +38 }
    unused_40: integer32;               { +40 }
    sel: c_exp_t;                       { +44: the selector's stack
                                          entry (62 bytes copied) }
    line: integer;                      { +108 }
    started: boolean;                   { +110: set by case_s }
    has_default: boolean;               { +111 }
  end;

  { The switch statements being parsed (c_syntax's push_switch and
    pop_switch, csyn_1e8 the innermost): 124 bytes from gspace, kept
    for reuse once popped.  c_stmt_sem's add_cbranch tests active.

    Not known from the original: the names. }
  c_switch_ptr_t = ^c_switch_t;
  c_switch_t = record
    next: c_switch_ptr_t;               { +0: the one made for a switch
                                          inside it }
    prev: c_switch_ptr_t;               { +4: the enclosing one }
    c: c_case_t;                        { +8: case_s .. case_e's }
    active: boolean;                    { +120: inside the switch's
                                          body: stat takes case and
                                          default }
    has_default: boolean;               { +121: its default seen }
  end;

  { A parameter declared by name (121, 56 bytes from c_def_sem's
    add_parm), chained from a block's old_parms (fnd_param looks names
    up in it, def_blk_params makes each a variable): as type_exp sees a
    kind 121 node, its type at +16 and its attributes at +24.

    Not known from the original: the names; what w44 and b46 hold (the
    parser's: c_syntax's declaration and function_prototype). }
  c_parm_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    next: c_parm_ptr_t;                 { +4 }
    pname: c_name_t;                    { +8 }
    ptype: c_type_ptr_t;                { +16: il_178 until declared
                                          (def_blk_params makes it int) }
    flags: c_flags_t;                   { +20: merge_attribs's }
    attr: c_dattr_t;                    { +24 }
    w44: integer;                       { +44 }
    b46: boolean;                       { +46 }
    reg: boolean;                       { +47: declared register
                                          (def_blk_params: add_reg_var) }
    unused_48: array [12..13] of integer32;  { +48..+55 }
  end;

  { A structure, union or enumeration tag (28 bytes from c_def_sem's
    def_su; a block's tags): its kind, then the rest, which
    def_resolve_incomplete_types takes by address (c_syntax's
    struct_union_type passes the tag's +4).

    Not known from the original: the names. }
  c_tag_body_t = record
    next: c_tag_ptr_t;                  { +4: the block's next tag }
    stype: c_type_ptr_t;                { +8: the type (il_178 until
                                          defined) }
    block: c_blk_ptr_t;                 { +12 }
    incomplete: c_reglist_ptr_t;        { +16: the variables, typedefs
                                          and arrays declared with the
                                          type while it was incomplete
                                          (kind 160 entries,
                                          add_incomplete_type) }
    name: c_name_t;                     { +20: its uplevel byte (+26)
                                          set by lookup_su }
  end;
  c_tag_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    body: c_tag_body_t;                 { +4 }
  end;

  { A structure or union being laid out (c_syntax's struct_union_type
    frame; c_def_sem's def_fld adds each field, def_rec makes the
    type).

    Not known from the original: the names. }
  c_fldlist_ptr_t = ^c_fldlist_t;
  c_fldlist_t = record
    first: c_field_ptr_t;               { +0 }
    tag: c_tag_ptr_t;                   { +4 }
    attr: c_dattr_t;                    { +8: device read and write
                                          or-ed in from the fields;
                                          align, w10 and x12 their
                                          greatest }
    size: integer32;                    { +28: bytes so far (a union's:
                                          the largest) }
    bitoff: integer;                    { +32: bits past size }
    has_bf: boolean;                    { +34: a bit field was laid out }
    has_arr: boolean;                   { +35: a field is an array }
  end;

  { A dynamic initializer waiting for the routine's code (68 bytes from
    c_def_sem's def_dynm_data, chained from cdef_44): the expression
    stack's top entry. }
  c_dynm_ptr_t = ^c_dynm_t;
  c_dynm_t = record
    next: c_dynm_ptr_t;                 { +0 }
    e: c_exp_t;                         { +4: 62 bytes copied }
  end;

  { An enumeration's constants as c_syntax's enum__type collects them
    (a 4104-byte frame record; c_def_sem's def_enum_list). }
  c_enumset_t = record
    syms: array [1..1024] of c_sym_ptr_t;  { +0: constants (116) }
    count: integer;                     { +4096 }
  end;
