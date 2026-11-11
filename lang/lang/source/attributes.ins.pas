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
