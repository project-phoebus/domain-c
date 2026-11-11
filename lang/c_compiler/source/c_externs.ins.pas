{ lang/c_compiler/source/c_externs.ins.pas - the C front end's routines
  that other units call: the lexer, the declaration and expression
  semantics, the error texts, the symbol map.  Opened after
  c_globals.ins.pas (c_def_sem, c_expr_sem and add_node open
  lang/lang/source/attributes.ins.pas between them) by the front-end
  units and by add_node, attributes and runbackend.

  The preprocessor's interfaces are in c_pre_proc.ins.pas,
  general_utl.ins.pas, macro_utl.ins.pas and macro_read.ins.pas;
  type_exp, cgerr, cgerr_no_source and advance_listing_to_line, which
  units outside the front end call without opening this insert, are in
  the prelude's globals_from_frontend.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Headings are read off the callee's frame and its call sites
  (tools/cc_params.py), narrowed where the callee is translated.

  Not known from the original: the parameter names.
}

{ TODO(pascal) c_externs.ins.pas is incomplete

  The headings of c_def_sem, c_expr_sem, c_expr_syn, c_stmt_sem and
  c_syntax's routines called from other units are added as those units
  are translated. }

{ GET_RLEN - the register length class of a type: 0 kind 210, 5 kinds
  130 and 135, the length word of kind 123, 9 kinds 126 and 127, else
  the size 1, 2 or 4, else 11.  c_get_rlen.pas 0x0532D8; callers in
  c_def_sem, c_expr_sem, c_stmt_sem, c_syntax and runbackend (and
  reg_life, which does not open this insert) pass the address of a
  type_exp_t and read D0 as a word. }
function get_rlen(
    in t: type_exp_t): integer; extern;

type
  { A diagnostic's text as c_lex_pp passes it to error_text and
    warning_text (by address, with its length). }
  cerr_text_t = array [1..256] of char;

{ ERROR_TEXT - an error at line whose message is text (len
  characters), listed and typed with the usual header.  c_error.pas
  0x049AC0; c_lex_pp. }
procedure error_text(
    line: integer;
    in text: univ cerr_text_t;
    len: integer); options(val_param); extern;

{ WARNING_TEXT - the same for a warning, only counted when warnings
  are off (-NWARN).  c_error.pas 0x049B2C; c_lex_pp. }
procedure warning_text(
    line: integer;
    in text: univ cerr_text_t;
    len: integer); options(val_param); extern;
