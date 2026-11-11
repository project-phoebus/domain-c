{ lang/c_compiler/source/c_syntax.ins.pas - the parser's routines
  c_expr_syn calls (c_syntax.pas).  Opened after c_externs.ins.pas by
  c_expr_syn and c_syntax.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: the parameter names.
}

{ TODO(pascal) read off the frames only (see c_externs.ins.pas) }

{ DATA_INIT - c_syntax.pas 0x063C6C (cc.a88k 0x063EEC). }
procedure data_init(
    p8: integer;
    p10: univ_ptr;
    p14: univ_ptr;
    p18: integer); options(val_param); extern;

{ C_TYPE_NAME - c_syntax.pas 0x067286 (cc.a88k 0x067506). }
function c_type_name(
    p8: univ_ptr;
    p12: univ_ptr;
    p16: univ_ptr): integer32; options(val_param); extern;
