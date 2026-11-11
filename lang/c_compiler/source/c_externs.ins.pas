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

{ TODO(pascal) the front end's cross-unit headings are read off the frames only

  Generated from tools/cc_params.py (cc.m68k; the cc.a88k address
  given with each): a slot moved to an address register is univ_ptr by
  value, a word integer, a byte boolean, a longword integer32 (all
  val_param); a gap between slots a placeholder; a function when most
  callers read A0 (univ_ptr) or D0 (by their next instruction: char,
  boolean, integer or integer32).  A routine that merely leaves a
  register its callers happen to read may be declared a function
  wrongly.  Narrow the types, the modes and the names (and replace pN)
  when each owner is translated: c_def_sem, c_expr_sem, c_stmt_sem,
  c_syntax, c_lex_pp, c_sym_map. }

{ c_lex_pp.pas: the lexer (checked against its bodies). }

{ INIT_LEX - start reading the source file.  c_lex_pp.pas 0x05351A
  (cc.a88k 0x05379A); c_main's cc and do_lex_for_listings. }
procedure init_lex; extern;

{ GET - the next token to lex_token, its class to token_kind.
  c_lex_pp.pas 0x0557EA (cc.a88k 0x055A6A); 188 call sites. }
procedure get; extern;

{ CLEX_$UNGET - make tok (of class kind) the current token, the current
  one to come back from the next get.  c_lex_pp.pas 0x055FB0 (cc.a88k
  0x056230); c_expr_syn's primary_expr and c_syntax's array_dim_init
  pass a node's kind and the node. }
procedure clex_$unget(
    kind: integer;
    tok: il_$node_ptr_t); options(val_param); extern;

{ CLEX_$CATSTRING - the string of s1's characters (less its final NUL)
  then s2's, of s1's kind (adjacent string literals); s1 when s2 is not
  a string (92, 93) or the result would pass 4095 characters, s2 when
  s1 is nil or not a string.  c_lex_pp.pas 0x055FE4 (cc.a88k
  0x056264); primary_expr and array_dim_init read A0. }
function clex_$catstring(
    s1: il_$node_ptr_t;
    s2: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ c_def_sem.pas: declarations (called from c_expr_sem, c_expr_syn,
  c_main, c_stmt_sem, c_syntax and runbackend). }

{ FND_PARAM - c_def_sem.pas 0x0452A4 (cc.a88k 0x045524). }
function fnd_param(
    p8: univ_ptr;
    p12: univ_ptr): univ_ptr; options(val_param); extern;

{ BLK_FND_NAME - c_def_sem.pas 0x045302 (cc.a88k 0x045582): the
  name's address, two booleans and a block (c_expr_syn's alloc_builtins
  passes il_180). }
function blk_fnd_name(
    p8: univ_ptr;
    p12: boolean;
    p14: boolean;
    p16: univ_ptr): univ_ptr; options(val_param); extern;

{ FND_NAME - c_def_sem.pas 0x045390 (cc.a88k 0x045610). }
function fnd_name(
    p8: univ_ptr;
    p12: boolean;
    p14: boolean): univ_ptr; options(val_param); extern;

{ DEF_LNKTBL_CLEAR - c_def_sem.pas 0x045582 (cc.a88k 0x045802). }
procedure def_lnktbl_clear; extern;

{ DEF_DROP_TNAMES - c_def_sem.pas 0x045622 (cc.a88k 0x0458A2). }
function def_drop_tnames(
    p8: univ_ptr): univ_ptr; options(val_param); extern;

{ DEF_INCOMPLETE_SU - c_def_sem.pas 0x045650 (cc.a88k 0x0458D0). }
function def_incomplete_su(
    p8: univ_ptr;
    p12: univ_ptr): boolean; options(val_param); extern;

{ DEF_RESOLVE_INCOMPLETE_TYPES - c_def_sem.pas 0x04576E (cc.a88k 0x0459EE). }
procedure def_resolve_incomplete_types(
    p8: univ_ptr); options(val_param); extern;

{ CHECK_TYPES - c_def_sem.pas 0x046162 (cc.a88k 0x0463E2). }
function check_types(
    p8: univ_ptr;
    p12: univ_ptr;
    p16: boolean): boolean; options(val_param); extern;

{ DEF_VARN - c_def_sem.pas 0x046742 (cc.a88k 0x0469C2). }
function def_varn(
    p8: integer32;
    p12: integer32;
    p16: integer;
    p18: boolean): univ_ptr; options(val_param); extern;

{ ADD_VARN - a variable (109) named name, of decl's type and
  attributes, allocated as vat, entered in il_180's chain.
  c_def_sem.pas 0x046D98 (cc.a88k 0x047018): name and vat by value,
  decl by address (its +0 and +12..+31 read); A0. }
function add_varn(
    name: univ_ptr;
    in decl: c_decl_t;
    vat: c_vat_t): c_sym_ptr_t; options(val_param); extern;

{ ADD_REG_VAR - c_def_sem.pas 0x046E60 (cc.a88k 0x0470E0). }
procedure add_reg_var(
    p8: univ_ptr); options(val_param); extern;

{ ADD_PARM - c_def_sem.pas 0x046EC4 (cc.a88k 0x047144). }
procedure add_parm(
    p8: integer32;
    p12: integer32;
    p16: integer32;
    p20: integer;
    p22: boolean); options(val_param); extern;

{ LOOKUP_SU - c_def_sem.pas 0x046F7C (cc.a88k 0x0471FC). }
function lookup_su(
    p8: univ_ptr): univ_ptr; options(val_param); extern;

{ ADD_SU - c_def_sem.pas 0x046FDC (cc.a88k 0x04725C). }
procedure add_su(
    p8: univ_ptr;
    p12: univ_ptr); options(val_param); extern;

{ DEF_SU - c_def_sem.pas 0x047012 (cc.a88k 0x047292). }
function def_su(
    p8: univ_ptr;
    p12: integer): univ_ptr; options(val_param); extern;

{ DEF_DATA - c_def_sem.pas 0x04717A (cc.a88k 0x0473FA). }
procedure def_data(
    p8: univ_ptr;
    p12: integer32;
    p16: integer32); options(val_param); extern;

{ DEF_DYNM_DATA - c_def_sem.pas 0x0471CE (cc.a88k 0x04744E). }
procedure def_dynm_data; extern;

{ DEF_TYPN - c_def_sem.pas 0x047230 (cc.a88k 0x0474B0). }
procedure def_typn(
    p8: integer32;
    p12: univ_ptr); options(val_param); extern;

{ DEF_CONN - c_def_sem.pas 0x0472C6 (cc.a88k 0x047546). }
procedure def_conn(
    p8: integer32;
    p12: univ_ptr;
    p16: integer32); options(val_param); extern;

{ DEF_ENUM_SKELETON - c_def_sem.pas 0x04731A (cc.a88k 0x04759A). }
function def_enum_skeleton(
    p8: univ_ptr): univ_ptr; options(val_param); extern;

{ DEF_ENUM_LIST - c_def_sem.pas 0x04734E (cc.a88k 0x0475CE). }
procedure def_enum_list(
    p8: univ_ptr;
    p12: univ_ptr); options(val_param); extern;

{ DEF_SUBR - a subrange type (128) of low's type from low's value to
  high's, to d.dtype.  c_def_sem.pas 0x0475C2 (cc.a88k 0x047842):
  three addresses. }
procedure def_subr(
    in low: c_cexp_t;
    in high: c_cexp_t;
    var d: c_decl_t); extern;

{ DEF_PTR - c_def_sem.pas 0x047614 (cc.a88k 0x047894). }
function def_ptr(
    p8: univ_ptr;
    p12: univ_ptr): univ_ptr; options(val_param); extern;

{ DEF_FWD_PTR - c_def_sem.pas 0x0476DC (cc.a88k 0x04795C). }
function def_fwd_ptr(
    p8: integer32): univ_ptr; options(val_param); extern;

{ DEF_RESOLVE_FWD_PTRS - c_def_sem.pas 0x047738 (cc.a88k 0x0479B8). }
procedure def_resolve_fwd_ptrs; extern;

{ DEF_FINAL_RES_FWD_PTRS - c_def_sem.pas 0x04780C (cc.a88k 0x047A8C). }
procedure def_final_res_fwd_ptrs; extern;

{ DEF_FUNC - c_def_sem.pas 0x0478B4 (cc.a88k 0x047B34). }
function def_func(
    p8: integer32;
    p12: univ_ptr;
    p16: integer;
    p18: integer32;
    p22: integer32;
    p26: integer32;
    p30: integer32): univ_ptr; options(val_param); extern;

{ DEF_FLD - c_def_sem.pas 0x047956 (cc.a88k 0x047BD6). }
procedure def_fld(
    p8: univ_ptr;
    p12: univ_ptr;
    p16: univ_ptr;
    p20: integer;
    p22: univ_ptr); options(val_param); extern;

{ DEF_REC - c_def_sem.pas 0x047FDC (cc.a88k 0x04825C). }
function def_rec(
    p8: univ_ptr;
    p12: univ_ptr): univ_ptr; options(val_param); extern;

{ DEF_ARR - an array type indexed by index's type of elem's.
  c_def_sem.pas 0x0480A4 (cc.a88k 0x048324): the declarations by
  address, a longword and a byte by value; c_expr_syn's do_c_string
  reads A0. }
function def_arr(
    in index: c_decl_t;
    in elem: c_decl_t;
    p16: integer32;
    p20: boolean): univ_ptr; options(val_param); extern;

{ DEF_BLK_SKELETON - c_def_sem.pas 0x0484F8 (cc.a88k 0x048778):
  p24 a parameter list (c_expr_syn's alloc_builtins; nil from c_main
  and primary_expr). }
procedure def_blk_skeleton(
    p8: integer;
    p10: univ_ptr;
    p14: integer;
    p16: univ_ptr;
    p20: univ_ptr;
    p24: univ_ptr;
    p28: boolean;
    p30: integer;
    p32: integer32;
    p36: univ_ptr); options(val_param); extern;

{ DEF_BLK_PARAMS - c_def_sem.pas 0x048A96 (cc.a88k 0x048D16). }
procedure def_blk_params(
    p8: boolean); options(val_param); extern;

{ DEF_ALLOC_VAR - c_def_sem.pas 0x048FE0 (cc.a88k 0x049260). }
procedure def_alloc_var(
    p8: univ_ptr;
    p12: integer32); options(val_param); extern;

{ c_expr_sem.pas: expressions. }

{ INIT_EXP_TBL - c_expr_sem.pas 0x049BB8 (cc.a88k 0x049E38). }
procedure init_exp_tbl; extern;

{ INIT_AUX - c_expr_sem.pas 0x049C0A (cc.a88k 0x049E8A). }
procedure init_aux(
    p8: univ_ptr;
    p12: univ_ptr); options(val_param); extern;

{ COERCE - c_expr_sem.pas 0x04A678 (cc.a88k 0x04A8F8): c_expr_syn
  pushes a type_exp_t's address, the expression stack's top (a word)
  and a byte, and tests D0 (`tst.b; bmi'). }
function coerce(
    in t: type_exp_t;
    top: integer;
    p14: boolean): boolean; options(val_param); extern;

{ BODY_OPR - c_expr_sem.pas 0x04B5E0 (cc.a88k 0x04B860). }
procedure body_opr(
    p8: integer;
    p10: univ_ptr); options(val_param); extern;

{ PUSH_CON - c_expr_sem.pas 0x04BC90 (cc.a88k 0x04BF10). }
procedure push_con(
    p8: integer32); options(val_param); extern;

{ PUSH_FCON - c_expr_sem.pas 0x04BCD0 (cc.a88k 0x04BF50): c_expr_syn
  and test_ne_zero pass a double constant's address (`pea (lit,PC)'). }
procedure push_fcon(
    in value: double); extern;

{ EXPR_OP - c_expr_sem.pas 0x04CDBA (cc.a88k 0x04D03A). }
procedure expr_op(
    p8: integer;
    p10: univ_ptr;
    p14: integer); options(val_param); extern;

{ ADJUST_PARM - c_expr_sem.pas 0x04F974 (cc.a88k 0x04FBF4): a
  boolean by address (`tst.b (A0)'). }
procedure adjust_parm(
    in conv: boolean); extern;

{ TEST_NE_ZERO - c_expr_sem.pas 0x04FA40 (cc.a88k 0x04FCC0). }
procedure test_ne_zero; extern;

{ ADJUST_BLK_FOR_DB - c_expr_sem.pas 0x04FC62 (cc.a88k 0x04FEE2): a
  block pointer by address (`movea.l (8,A6); move.l (A0)'). }
procedure adjust_blk_for_db(
    var blk: c_type_ptr_t); extern;

{ c_expr_syn.pas: called from c_main. }

{ C_EXPR_SYN_$BEGIN_COMPILATION - c_expr_syn.pas 0x04FDFC (cc.a88k 0x05007C). }
procedure c_expr_syn_$begin_compilation; extern;

{ c_stmt_sem.pas: statements (add_node calls link_top). }

{ LINK_TOP - c_stmt_sem.pas 0x05BEF8 (cc.a88k 0x05C178). }
function link_top(
    p8: univ_ptr): univ_ptr; options(val_param); extern;

{ DEF_DEF_LABEL - c_stmt_sem.pas 0x05C304 (cc.a88k 0x05C584). }
procedure def_def_label; extern;

{ DEF_LABL - c_stmt_sem.pas 0x05C7B4 (cc.a88k 0x05CA34). }
procedure def_labl(
    p8: univ_ptr); options(val_param); extern;

{ IF_S - c_stmt_sem.pas 0x05C8CA (cc.a88k 0x05CB4A). }
procedure if_s(
    p8: univ_ptr;
    p12: univ_ptr); options(val_param); extern;

{ ELSE_S - c_stmt_sem.pas 0x05C900 (cc.a88k 0x05CB80). }
procedure else_s(
    p8: univ_ptr;
    p12: univ_ptr); options(val_param); extern;

{ ENDIF_S - c_stmt_sem.pas 0x05C94A (cc.a88k 0x05CBCA). }
procedure endif_s(
    p8: univ_ptr;
    p12: univ_ptr); options(val_param); extern;

{ CASE_CON - c_stmt_sem.pas 0x05C9F8 (cc.a88k 0x05CC78). }
procedure case_con(
    p8: univ_ptr;
    p12: integer32;
    p16: boolean); options(val_param); extern;

{ CASE_S - c_stmt_sem.pas 0x05CB26 (cc.a88k 0x05CDA6). }
procedure case_s(
    p8: univ_ptr); options(val_param); extern;

{ CASE_DEFAULT - c_stmt_sem.pas 0x05CC7C (cc.a88k 0x05CEFC). }
procedure case_default(
    p8: univ_ptr;
    p12: boolean); options(val_param); extern;

{ CASE_E - c_stmt_sem.pas 0x05CDA4 (cc.a88k 0x05D024). }
procedure case_e(
    p8: univ_ptr); options(val_param); extern;

{ WHILE_LABEL - c_stmt_sem.pas 0x05CDFA (cc.a88k 0x05D07A). }
procedure while_label; extern;

{ WHILE_S - c_stmt_sem.pas 0x05CE3E (cc.a88k 0x05D0BE). }
function while_s: univ_ptr; extern;

{ WHILE_E - c_stmt_sem.pas 0x05CE6E (cc.a88k 0x05D0EE). }
procedure while_e; extern;

{ FOR_START_LAB - c_stmt_sem.pas 0x05CEBC (cc.a88k 0x05D13C). }
procedure for_start_lab; extern;

{ FOR_S - c_stmt_sem.pas 0x05CF00 (cc.a88k 0x05D180). }
procedure for_s; extern;

{ FOR_NEXT_LAB - c_stmt_sem.pas 0x05CF30 (cc.a88k 0x05D1B0). }
procedure for_next_lab; extern;

{ FOR_E - c_stmt_sem.pas 0x05CF66 (cc.a88k 0x05D1E6). }
procedure for_e; extern;

{ REPEAT_S - c_stmt_sem.pas 0x05CFB4 (cc.a88k 0x05D234). }
function repeat_s: univ_ptr; extern;

{ REPEAT_E - c_stmt_sem.pas 0x05CFF8 (cc.a88k 0x05D278). }
procedure repeat_e; extern;

{ CALL_S - c_stmt_sem.pas 0x05D05C (cc.a88k 0x05D2DC). }
procedure call_s; extern;

{ BODY_S - c_stmt_sem.pas 0x05D62C (cc.a88k 0x05D8AC). }
procedure body_s; extern;

{ BODY_E - c_stmt_sem.pas 0x05D7CE (cc.a88k 0x05DA4E). }
procedure body_e; extern;

{ NXTEXT_S - c_stmt_sem.pas 0x05D9F8 (cc.a88k 0x05DC78). }
procedure nxtext_s; extern;

{ RETURN_S - c_stmt_sem.pas 0x05DA8A (cc.a88k 0x05DD0A). }
procedure return_s; extern;

{ GOTO_S - c_stmt_sem.pas 0x05DAAC (cc.a88k 0x05DD2C). }
procedure goto_s(
    p8: univ_ptr); options(val_param); extern;

{ TEMP_ALLOC - c_stmt_sem.pas 0x05DB3A (cc.a88k 0x05DDBA). }
function temp_alloc(
    p8: integer;
    p10: integer): univ_ptr; options(val_param); extern;

{ WALK_TREE - c_stmt_sem.pas 0x05E938 (cc.a88k 0x05EBB8). }
function walk_tree(
    p8: univ_ptr;
    p12: univ_ptr;
    p16: integer32): univ_ptr; options(val_param); extern;

{ c_syntax.pas: called from c_main, c_expr_sem, c_stmt_sem and c_lex_pp. }

{ SYNTAX - c_syntax.pas 0x0609D8 (cc.a88k 0x060C58). }
procedure syntax; extern;

{ CC_WALK_IT - c_syntax.pas 0x0661BC (cc.a88k 0x06643C). }
procedure cc_walk_it(
    p8: univ_ptr;
    p12: univ_ptr;
    p16: boolean); options(val_param); extern;

{ PP_CONSTANT - c_syntax.pas 0x066E54 (cc.a88k 0x0670D4). }
function pp_constant: integer32; extern;

{ INITDATE - c_initdate.c 0x053354 (cc.a88k 0x0535D4): fills
  macro_read.ins.pas's mr_date and mr_time; c_main's cc calls it with
  no arguments. }
procedure initdate; extern;

{ c_sym_map.pas: the symbol map (c_main). }

{ SYM_MAP - the listing's symbol map (-MAP): c_main's cc calls it at
  the end.  c_sym_map.pas 0x060584 (cc.a88k 0x060804); checked
  against its body. }
procedure sym_map; extern;
