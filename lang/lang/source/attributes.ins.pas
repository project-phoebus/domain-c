{ lang/lang/source/attributes.ins.pas - the interface of
  lang/lang/source/attributes.pas (data alignment and attributes).
  Opened by c_lex_pp and c_main (and c_def_sem, c_expr_sem, add_node)
  after the prelude.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  A stub: only what the translated units call, the headings read off
  attributes.pas's frames (tools/cc_params.py) and the call sites.

  Not known from the original: the parameter names.
}

{ TODO(pascal) attributes.ins.pas is a stub

  The rest of the interface is added when attributes.pas and its
  callers are translated. }

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

{ ATTR_SET_ALIGN_DSC - adjust t's alignment in d (type_exp_t's align)
  for the node n.  0x0A503C (cc.a88k 0x0A6A1C): the node and the
  descriptor's address by value (type_exp, c_expr_syn; c_main and
  c_lex_pp open this insert before c_objtype.ins.pas, so the
  descriptor is a univ_ptr). }
procedure attr_set_align_dsc(
    n: univ_ptr;
    d: univ_ptr); options(val_param); extern;

{ ATTR_CHECK_ALIGN - check the alignment of the expression stack's
  entry top.  0x0A4E9E (cc.a88k 0x0A687E): a word by value (c_expr_sem,
  c_expr_syn's func_call_stat). }
procedure attr_check_align(
    top: integer); options(val_param); extern;

{ ATTR_CURR_ALIGN_ENV - the alignment environment: cargs_$options'
  b28b_0 as 0 or 1 (`moveq #1; and.b').  0x0A63F6 (cc.a88k 0x0A7DD6);
  callers `tst.w D0; seq'. }
function attr_curr_align_env: integer; extern;

{ ATTR_NATURAL_ALIGN_FROM_BYTES - the natural alignment of an object of
  n bytes.  0x0A4F38 (cc.a88k 0x0A6918): a longword by value; D0 read as
  a word (c_stmt_sem's temp_alloc). }
function attr_natural_align_from_bytes(
    n: integer32): integer; options(val_param); extern;

{ The attribute records' routines (c_def_sem): a is the address of a
  declaration's attributes (c_objtype.ins.pas's c_dattr_t, 20 bytes;
  univ_ptr since c_main and c_lex_pp open this insert before
  c_objtype.ins.pas), t a type node, n a symbol or type node. }

{ MERGE_ATTRIBS - merge t's attributes into a; the flags (a longword
  set, c_flags_t) of the object declared.  0x0A628C (cc.a88k
  0x0A7C6C): two longwords by value; D0 stored as a longword
  (c_def_sem's update_attr, add_varn, def_ptr, def_blk_skeleton,
  def_blk_params). }
function merge_attribs(
    a: univ_ptr;
    t: univ_ptr): integer32; options(val_param); extern;

{ MERGE_ATTRIBS_NATURAL - the same under natural alignment rules.
  0x0A5A26 (cc.a88k 0x0A7406): c_def_sem's def_typn, def_fld, def_arr,
  def_resolve_incomplete_types; c_syntax. }
function merge_attribs_natural(
    a: univ_ptr;
    t: univ_ptr): integer32; options(val_param); extern;

{ ATTR_TATTR_TO_VATTR - convert a declaration's attributes a to a
  symbol's or a type's form at v (the size in bits first).  0x0A59F0
  (cc.a88k 0x0A73D0). }
procedure attr_tattr_to_vattr(
    a: univ_ptr;
    v: univ_ptr); options(val_param); extern;

{ ATTR_VALIDATE - check the attributes a given for the object n.
  0x0A564E (cc.a88k 0x0A702E). }
procedure attr_validate(
    a: univ_ptr;
    n: univ_ptr); options(val_param); extern;

{ ATTR_COMPUTE_ROUTINE_OPTIONS - fill a routine block's options area
  (its +332) from the enclosing block's.  0x0A6412 (cc.a88k 0x0A7DF2):
  c_def_sem's def_blk_skeleton; D0 not read. }
procedure attr_compute_routine_options(
    opts: univ_ptr;
    outer: univ_ptr); options(val_param); extern;
