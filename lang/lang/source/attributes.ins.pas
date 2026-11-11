{ lang/lang/source/attributes.ins.pas - the interface of
  lang/lang/source/attributes.pas: the C front end's data attributes
  (#attribute, __attribute: volatile, device, address, register, size,
  aligned, ...), alignment and the #pragma alignment stack, and a
  routine's options.  Opened by c_lex_pp and c_main right after the
  prelude (before c_objtype.ins.pas: so it names none of c_objtype's
  types), and after the prelude, c_objtype.ins.pas, c_globals.ins.pas
  and c_externs.ins.pas by attributes (and c_def_sem, c_expr_sem,
  c_syntax).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (the unit is the same in both).  Every heading is read off the
  routine's frame and its callers (tools/cc_params.py); attr_packed_size
  and the internal find_conflict and attr_calc_align are called only
  within attributes.pas and are declared there.  The records taken by
  address are univ: the front end passes its own records of the same
  bytes (c_objtype's c_dattr_t and c_attr_t for attr_tattr_t, c_blk_t's
  ropts for attr_rtn_opts_t).

  Not known from the original: every name but the routines'.
}

type
  { A set of attribute bits (the same as c_objtype's c_flags_t: c_main
    and c_lex_pp open this insert before c_objtype.ins.pas, so it
    declares its own types). }
  attr_bits_t = set of 0..31;

  { A type's attributes (a typedef's, kind 121's at +24, a block's at
    +312, kind 174's at +12; parse_attributes builds them, merge_attribs
    adds those of a type to them).  The form tattr_to_vattr turns into a
    variable's (c_objtype's c_attr_t: the longwords at +0 and +4
    exchanged, and the words at +8 and +10).

    The bits, by the keyword find_conflict names for each: 0 volatile,
    1 physical, 2 atomic, 3 device(read), 4 device(write), 5 address,
    6 immediate, 7 reference, 8 processor_register, 9
    fp_internal_register, 10 register, 11 size, 12 aligned, 13 natural,
    14 no_fp, 15 save_db, 16 section, 17 resident_procedure; 18 one of
    5..10 (the storage attributes, value holding its operand) was
    given; 19 const; 20 (merged from the type, not named).  The codes
    add_attribute takes are these bit numbers.

    Not known from the original: the names; +14. }
  attr_tattr_ptr_t = ^attr_tattr_t;
  attr_tattr_t = record
    bits: attr_bits_t;                  { +0 }
    size: integer32;                    { +4: in bits (Size(n)) }
    natural: integer;                   { +8: the natural alignment
                                          (log2 of bytes,
                                          attr_calc_align) }
    align: integer;                     { +10: the alignment used
                                          (Aligned(n)'s n; -1
                                          unaligned) }
    min_align: integer;                 { +12: the least alignment the
                                          type asks (-1 none) }
    unused_14: integer;                 { +14 }
    case integer of
      1: (value: integer32);            { +16: address(n),
                                          processor_register(n),
                                          fp_internal_register(n) }
      { immediate(n), reference(n), register(n): the operand's halves }
      2: (value_lo: integer;            { +16 }
          value_hi: integer);           { +18 }
  end;

  { A variable's form of the attributes (a variable's, a field's, a
    pointer's, an array's or a structure's: c_objtype's c_attr_t, which
    names +0 other_bits). }
  attr_vattr_t = record
    size: integer32;                    { +0: in bits }
    bits: attr_bits_t;                  { +4 }
    align: integer;                     { +8 }
    natural: integer;                   { +10 }
    min_align: integer;                 { +12 }
  end;

  { A routine's options (a block's +332, 42 bytes, laid out as
    target_properties_$mode_t, whose user_mode holds the defaults):
    three sets of 0..63, three of 0..31, and the routine's convention
    (+40, an element of the first three sets).

    Not known from the original: every name; what the sets hold. }
  attr_rtn_opts_t = record
    opts_0: set of 0..63;               { +0 }
    opts_8: set of 0..63;               { +8 }
    opts_16: set of 0..63;              { +16 }
    opts_24: set of 0..31;              { +24 }
    opts_28: set of 0..31;              { +28 }
    opts_32: set of 0..31;              { +32 }
    unused_36: integer;                 { +36 }
    given: set of 0..15;                { +38: 13 the convention was
                                          given }
    convention: integer;                { +40 }
  end;

  { A block (kind 107, 108) as attr_compute_routine_options reads it. }
  attr_block_ptr_t = ^attr_block_t;
  attr_block_t = record
    unused: array [0..82] of integer32; { +0..+331 }
    opts: attr_rtn_opts_t;              { +332 }
  end;

{ ATTR_ALIGN_MESSAGES - whether attr_check_align warns.  0x0A4E84
  (cc.a88k 0x0A6864): a byte by value.  No caller in either binary. }
procedure attr_align_messages(
    on: boolean); options(val_param); extern;

{ ATTR_CHECK_ALIGN - warn (once) of the k-th expression stack entry's
  misalignment.  0x0A4E9E (cc.a88k 0x0A687E): a word by value; c_expr_sem
  reference_operand and func_call_stat. }
procedure attr_check_align(
    k: integer); options(val_param); extern;

{ ATTR_NATURAL_ALIGN_FROM_BYTES - log2 of the size in bytes, at most 3.
  0x0A4F38 (cc.a88k 0x0A6918): a longword by value, the result a word in
  D0; c_def_sem def_alloc_var, c_stmt_sem temp_alloc. }
function attr_natural_align_from_bytes(
    bytes: integer32): integer; options(val_param); extern;

{ ATTR_SET_ALIGN_DSC - texp's alignment from node's attributes.
  0x0A503C (cc.a88k 0x0A6A1C): node by value, the address of texp (a
  c_objtype type_exp_t, which this insert cannot name) (14 callers:
  type_exp, ...). }
procedure attr_set_align_dsc(
    node: il_$node_ptr_t;
    texp: univ_ptr); options(val_param); extern;

{ ADD_ATTRIBUTE - add attribute code with its operand value to attr,
  name naming it in diagnostics.  0x0A5466 (cc.a88k 0x0A6E46): a word,
  an address, a longword, a pointer (10 callers: parse_attributes,
  ...). }
procedure add_attribute(
    code: integer;
    var attr: univ attr_tattr_t;
    value: integer32;
    name: il_$node_ptr_t); options(val_param); extern;

{ ATTR_VALIDATE - report the attributes attr holds that node's kind does
  not take.  0x0A564E (cc.a88k 0x0A702E): attr by address, node by value
  (9 callers: update_attr, def_typn, ...). }
procedure attr_validate(
    in attr: univ attr_tattr_t;
    node: il_$node_ptr_t); options(val_param); extern;

{ ATTR_TATTR_TO_VATTR - a type's attributes in a variable's form.
  0x0A59F0 (cc.a88k 0x0A73D0): both by address, t first (8 callers:
  def_resolve_incomplete_types, update_attr, ...). }
procedure attr_tattr_to_vattr(
    in t: univ attr_tattr_t;
    out v: univ attr_vattr_t); extern;

{ MERGE_ATTRIBS_NATURAL - add typ's attributes to attr and settle its
  size and alignment; the result the flags of a symbol so attributed.
  0x0A5A26 (cc.a88k 0x0A7406): attr by address, typ by value, the result
  in D0 (9 callers: def_resolve_incomplete_types, def_typn, ...). }
function merge_attribs_natural(
    var attr: univ attr_tattr_t;
    typ: il_$node_ptr_t): attr_bits_t; options(val_param); extern;

{ MERGE_ATTRIBS - merge_attribs_natural, the alignment then limited
  under word alignment.  0x0A628C (cc.a88k 0x0A7C6C) (8 callers:
  update_attr, ...). }
function merge_attribs(
    var attr: univ attr_tattr_t;
    typ: il_$node_ptr_t): attr_bits_t; options(val_param); extern;

{ ATTR_PUSH_ALIGN - save the alignment environment (#pragma
  push_alignment).  0x0A62FA (cc.a88k 0x0A7CDA): no parameters. }
procedure attr_push_align; extern;

{ ATTR_POP_ALIGN - restore the saved one (#pragma pop_alignment).
  0x0A634C (cc.a88k 0x0A7D2C). }
procedure attr_pop_align; extern;

{ ATTR_AL_STK_EMPTY - no saved alignment remains (c_lex_pp's get at
  the end of the source).  0x0A63A8 (cc.a88k 0x0A7D88): D0 read as a
  byte. }
function attr_al_stk_empty: boolean; extern;

{ ATTR_SET_ALIGN_ENV - the alignment environment: 1 natural, 0 word
  (#pragma natural_alignment, word_alignment).  0x0A63C4 (cc.a88k
  0x0A7DA4): a word by value. }
procedure attr_set_align_env(
    env: integer); options(val_param); extern;

{ ATTR_CURR_ALIGN_ENV - the alignment environment (1 natural, 0 word).
  0x0A63F6 (cc.a88k 0x0A7DD6): a word in D0 (7 callers:
  def_resolve_incomplete_types, def_fld, ...). }
function attr_curr_align_env: integer; extern;

{ ATTR_COMPUTE_ROUTINE_OPTIONS - complete a routine's options from its
  enclosing block's (or the target's).  0x0A6412 (cc.a88k 0x0A7DF2):
  opts by address, parent by value (c_def_sem def_blk_skeleton: the new
  block's +332 and il_180). }
procedure attr_compute_routine_options(
    var opts: univ attr_rtn_opts_t;
    parent: il_$node_ptr_t); options(val_param); extern;
