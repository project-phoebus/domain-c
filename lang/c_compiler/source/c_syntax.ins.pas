{ lang/c_compiler/source/c_syntax.ins.pas - the parser's routines
  c_expr_syn calls (c_syntax.pas).  Opened after c_externs.ins.pas by
  c_expr_syn and c_syntax.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: the parameter names.
}

{ DATA_INIT - the initializer of the variable v of type t, allocated as
  vat, in the declaration context ctx (0 at file level).  c_syntax.pas
  0x063C6C (cc.a88k 0x063EEC): c_syntax's declaration_stmts and
  c_expr_syn's do_c_string (a string's array, vat_stat). }
procedure data_init(
    ctx: integer;
    v: c_sym_ptr_t;
    t: c_type_ptr_t;
    vat: c_vat_t); options(val_param); extern;

{ C_TYPE_NAME - after a `(', a type name to d (d.dtype the type,
  d.flags its qualifiers) and is_type true, or is_type false when what
  follows is not a type name.  c_syntax.pas 0x067286 (cc.a88k
  0x067506): c_expr_syn's unary_expr passes its follow set, a 40-byte
  frame record and a byte, all by address, and reads neither D0 nor
  A0. }
procedure c_type_name(
    in follow: c_tokset_t;
    out d: c_decl_t;
    out is_type: boolean); extern;
