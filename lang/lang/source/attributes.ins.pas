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
