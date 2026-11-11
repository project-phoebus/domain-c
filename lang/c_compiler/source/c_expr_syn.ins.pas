{ lang/c_compiler/source/c_expr_syn.ins.pas - the expression parser's
  routines c_syntax calls (c_expr_syn.pas).  Opened after
  c_syntax.ins.pas by c_expr_syn and c_syntax.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (checked against c_expr_syn.pas's bodies).

  The parsing routines take the follow set (by address), a label name
  and a context word (both by address): the context is 2 once an
  operator has been taken; while it is not 2, an identifier followed by
  `:' is a label: primary_expr stores its name in lab and sets the
  context to 1 (the statement parser's test).

  Not known from the original: the parameter names.
}

{ NOT_AN_LVALUE - the expression stack's top entry is not an lvalue;
  with addr_op false an array parameter's name is taken as its
  pointer.  c_expr_syn.pas 0x0506B0 (cc.a88k 0x050930). }
function not_an_lvalue(
    addr_op: boolean): boolean; options(val_param); extern;

{ IDENTIFIER - an identifier to name (with the current line), else
  il_178 and diagnostic code.  c_expr_syn.pas 0x05090E (cc.a88k
  0x050B8E). }
procedure identifier(
    in follow: c_tokset_t;
    code: integer;
    out name: c_name_t); options(val_param); extern;

{ COND_EXPR - a conditional expression.  c_expr_syn.pas 0x052BA0
  (cc.a88k 0x052E20). }
procedure cond_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); extern;

{ ASN_EXPR - an assignment expression.  c_expr_syn.pas 0x052CD4
  (cc.a88k 0x052F54). }
procedure asn_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); extern;

{ C_EXPR - an expression (with commas).  c_expr_syn.pas 0x052DE4
  (cc.a88k 0x053064). }
procedure c_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); extern;

{ EVAL_EXPR - an expression where no label can be.  c_expr_syn.pas
  0x052EC8 (cc.a88k 0x053148). }
procedure eval_expr(
    in follow: c_tokset_t); extern;
