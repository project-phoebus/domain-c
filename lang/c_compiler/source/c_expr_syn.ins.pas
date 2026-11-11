{ lang/c_compiler/source/c_expr_syn.ins.pas - the expression parser's
  routines c_syntax calls (c_expr_syn.pas).  Opened after
  c_syntax.ins.pas by c_expr_syn and c_syntax.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: the parameter names.
}

{ TODO(pascal) read off the frames only (see c_externs.ins.pas) }

{ NOT_AN_LVALUE - c_expr_syn.pas 0x0506B0 (cc.a88k 0x050930). }
function not_an_lvalue(
    p8: boolean): boolean; options(val_param); extern;

{ IDENTIFIER - c_expr_syn.pas 0x05090E (cc.a88k 0x050B8E). }
procedure identifier(
    p8: univ_ptr;
    p12: integer;
    p14: univ_ptr); options(val_param); extern;

{ COND_EXPR - c_expr_syn.pas 0x052BA0 (cc.a88k 0x052E20). }
procedure cond_expr(
    p8: univ_ptr;
    p12: integer32;
    p16: univ_ptr); options(val_param); extern;

{ ASN_EXPR - c_expr_syn.pas 0x052CD4 (cc.a88k 0x052F54). }
procedure asn_expr(
    p8: univ_ptr;
    p12: integer32;
    p16: univ_ptr); options(val_param); extern;

{ C_EXPR - c_expr_syn.pas 0x052DE4 (cc.a88k 0x053064). }
procedure c_expr(
    p8: univ_ptr;
    p12: integer32;
    p16: univ_ptr); options(val_param); extern;

{ EVAL_EXPR - c_expr_syn.pas 0x052EC8 (cc.a88k 0x053148). }
procedure eval_expr(
    p8: univ_ptr); options(val_param); extern;
