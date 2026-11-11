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

  { What cc_walk_it applies to each tree (call_kfold): a routine
    taking the tree by address. }
  c_walker_t = ^procedure(var n: il_$node_ptr_t);

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
  c_main, c_stmt_sem, c_syntax and runbackend; checked against
  c_def_sem.pas's bodies).  A name is a c_name_t passed by address
  (univ where a caller passes a symbol's +4 or an identifier cell);
  a symbol looked up is il_178 when there is none. }

{ FND_PARAM - the parameter of the list (by name, from a block's
  old_parms) named as name, else il_178.  c_def_sem.pas 0x0452A4
  (cc.a88k 0x045524); c_syntax's declaration_stmts. }
function fnd_param(
    in name: c_name_t;
    list: c_parm_ptr_t): c_parm_ptr_t; options(val_param); extern;

{ BLK_FND_NAME - the symbol of the name declared in blk (or, unless
  local, in the blocks enclosing it); diagnostic 23 when there is none
  and report is set and local is not.  c_def_sem.pas 0x045302 (cc.a88k
  0x045582): runbackend passes a node's +8 (a symbol's name), c_expr_syn's
  alloc_builtins il_180. }
function blk_fnd_name(
    in name: univ c_name_t;
    local: boolean;
    report: boolean;
    blk: c_blk_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ FND_NAME - blk_fnd_name in the current block (il_180).
  c_def_sem.pas 0x045390 (cc.a88k 0x045610). }
function fnd_name(
    in name: univ c_name_t;
    local: boolean;
    report: boolean): il_$node_ptr_t; options(val_param); extern;

{ DEF_LNKTBL_CLEAR - move the externs declared in blocks to the
  outermost block.  c_def_sem.pas 0x045582 (cc.a88k 0x045802);
  c_main's fe_cc_$end_compilation. }
procedure def_lnktbl_clear; extern;

{ DEF_DROP_TNAMES - t with its typedef names (118) looked through.
  c_def_sem.pas 0x045622 (cc.a88k 0x0458A2). }
function def_drop_tnames(
    t: c_type_ptr_t): c_type_ptr_t; options(val_param); extern;

{ DEF_INCOMPLETE_SU - t (through typedefs and arrays) is a structure
  or union not yet complete: its tag to holder.  c_def_sem.pas
  0x045650 (cc.a88k 0x0458D0). }
function def_incomplete_su(
    t: c_type_ptr_t;
    var holder: c_tag_ptr_t): boolean; options(val_param); extern;

{ DEF_RESOLVE_INCOMPLETE_TYPES - complete what was declared with the
  tag's type while it was incomplete.  c_def_sem.pas 0x04576E (cc.a88k
  0x0459EE): c_syntax's struct_union_type passes the tag's +4. }
procedure def_resolve_incomplete_types(
    var tag: c_tag_body_t); extern;

{ CHECK_TYPES - a and b are compatible types (loose: a pointer to void
  matches any pointer).  c_def_sem.pas 0x046162 (cc.a88k 0x0463E2). }
function check_types(
    a: c_type_ptr_t;
    b: c_type_ptr_t;
    loose: boolean): boolean; options(val_param); extern;

{ DEF_VARN - declare the variable name of decl's type allocated as
  vat (init: it has an initializer), or merge the declaration into an
  existing one; the symbol.  c_def_sem.pas 0x046742 (cc.a88k
  0x0469C2): decl's type may be replaced by the existing one's. }
function def_varn(
    in name: c_name_t;
    var decl: c_decl_t;
    vat: c_vat_t;
    init: boolean): c_sym_ptr_t; options(val_param); extern;

{ ADD_VARN - a variable (109) named name, of decl's type and
  attributes, allocated as vat, entered in il_180's chain.
  c_def_sem.pas 0x046D98 (cc.a88k 0x047018). }
function add_varn(
    name: il_$node_ptr_t;
    in decl: c_decl_t;
    vat: c_vat_t): c_sym_ptr_t; options(val_param); extern;

{ ADD_REG_VAR - add v (unless il_178) to il_180's register variables.
  c_def_sem.pas 0x046E60 (cc.a88k 0x0470E0). }
procedure add_reg_var(
    v: c_sym_ptr_t); options(val_param); extern;

{ ADD_PARM - append a parameter named name of decl's type to list
  (diagnostic 36 for a second of the name).  c_def_sem.pas 0x046EC4
  (cc.a88k 0x047144): c_syntax's declaration (w44 0, b46 its byte) and
  function_prototype (w44 its word, b46 false). }
procedure add_parm(
    var list: c_parm_ptr_t;
    in name: c_name_t;
    in decl: c_decl_t;
    w44: integer;
    b46: boolean); options(val_param); extern;

{ LOOKUP_SU - the tag named id in il_180 or the blocks enclosing it,
  else nil.  c_def_sem.pas 0x046F7C (cc.a88k 0x0471FC). }
function lookup_su(
    id: il_$node_ptr_t): c_tag_ptr_t; options(val_param); extern;

{ ADD_SU - append the tag t to list (a block's tags).  c_def_sem.pas
  0x046FDC (cc.a88k 0x04725C). }
procedure add_su(
    t: c_tag_ptr_t;
    var list: c_tag_ptr_t); options(val_param); extern;

{ DEF_SU - a tag of kind named name in il_180.  c_def_sem.pas 0x047012
  (cc.a88k 0x047292). }
function def_su(
    in name: c_name_t;
    kind: integer): c_tag_ptr_t; options(val_param); extern;

{ DEF_DATA - initialize v's bytes at offset with the constant con.
  c_def_sem.pas 0x04717A (cc.a88k 0x0473FA): c_stmt_sem's
  setup_profiling, c_syntax's data_init. }
procedure def_data(
    v: c_sym_ptr_t;
    offset: integer32;
    con: il_$node_ptr_t); options(val_param); extern;

{ DEF_DYNM_DATA - keep the expression stack's top for a dynamic
  initializer (cdef_dynm_inits).  c_def_sem.pas 0x0471CE (cc.a88k
  0x04744E). }
procedure def_dynm_data; extern;

{ DEF_TYPN - a typedef name of decl's type.  c_def_sem.pas 0x047230
  (cc.a88k 0x0474B0). }
procedure def_typn(
    in name: c_name_t;
    in decl: c_decl_t); options(val_param); extern;

{ DEF_CONN - an enumeration constant name of ctype with the constant
  node value; the symbol.  c_def_sem.pas 0x0472C6 (cc.a88k 0x047546):
  c_syntax's enum_list does not read it. }
function def_conn(
    in name: c_name_t;
    ctype: c_type_ptr_t;
    value: il_$node_ptr_t): c_sym_ptr_t; options(val_param); extern;

{ DEF_ENUM_SKELETON - an enumeration type held in int_t.
  c_def_sem.pas 0x04731A (cc.a88k 0x04759A). }
function def_enum_skeleton(
    int_t: c_type_ptr_t): c_type_ptr_t; options(val_param); extern;

{ DEF_ENUM_LIST - give the enumeration t its constants and the range
  of their values (diagnostic 28 for a value its type cannot hold).
  c_def_sem.pas 0x04734E (cc.a88k 0x0475CE). }
procedure def_enum_list(
    in list: c_enumset_t;
    t: c_type_ptr_t); options(val_param); extern;

{ DEF_SUBR - a subrange type (128) of low's type from low's value to
  high's, to d.dtype.  c_def_sem.pas 0x0475C2 (cc.a88k 0x047842):
  three addresses. }
procedure def_subr(
    in low: c_cexp_t;
    in high: c_cexp_t;
    var d: c_decl_t); extern;

{ DEF_PTR - a pointer type to target (into, when not nil, is filled
  instead of a new node).  c_def_sem.pas 0x047614 (cc.a88k 0x047894). }
function def_ptr(
    target: c_type_ptr_t;
    into: c_type_ptr_t): c_type_ptr_t; options(val_param); extern;

{ DEF_FWD_PTR - a pointer to a structure tag not yet defined, chained
  in cdef_fwd_ptrs.  c_def_sem.pas 0x0476DC (cc.a88k 0x04795C):
  c_syntax's declaration passes a declaration's address. }
function def_fwd_ptr(
    in d: c_decl_t): c_type_ptr_t; options(val_param); extern;

{ DEF_RESOLVE_FWD_PTRS - point the forward pointers whose tags are now
  defined at their structures.  c_def_sem.pas 0x047738 (cc.a88k
  0x0479B8). }
procedure def_resolve_fwd_ptrs; extern;

{ DEF_FINAL_RES_FWD_PTRS - resolve the rest, to void when the tag was
  never defined.  c_def_sem.pas 0x04780C (cc.a88k 0x047A8C). }
procedure def_final_res_fwd_ptrs; extern;

{ DEF_FUNC - a function type (234) returning d's type.  c_def_sem.pas
  0x0478B4 (cc.a88k 0x047B34): c_expr_sem's expr_op, c_syntax's
  declaration. }
function def_func(
    in d: c_decl_t;
    into: c_type_ptr_t;
    conv: integer;
    x4: integer32;
    params: c_parlist_ptr_t;
    x16: integer32;
    x20: integer32): c_type_ptr_t; options(val_param); extern;

{ DEF_FLD - lay out a field named name of decl's type (width.value its
  bit width, when given) in st; kind 16 for a union.  c_def_sem.pas
  0x047956 (cc.a88k 0x047BD6); c_syntax's struct_union_type. }
procedure def_fld(
    var st: c_fldlist_t;
    in name: c_name_t;
    in decl: c_decl_t;
    kind: integer;
    in width: c_cexp_t); options(val_param); extern;

{ DEF_REC - the structure or union type st has laid out.
  c_def_sem.pas 0x047FDC (cc.a88k 0x04825C). }
function def_rec(
    in st: c_fldlist_t;
    into: c_type_ptr_t): c_type_ptr_t; options(val_param); extern;

{ DEF_ARR - an array type indexed by index's type of elem's (word_env:
  the word alignment environment, c_expr_syn's `attr_curr_align_env =
  0').  c_def_sem.pas 0x0480A4 (cc.a88k 0x048324); into, when not nil,
  is filled instead of a new node (def_resolve_incomplete_types). }
function def_arr(
    in index: c_decl_t;
    in elem: c_decl_t;
    into: c_type_ptr_t;
    word_env: boolean): c_type_ptr_t; options(val_param); extern;

{ DEF_BLK_SKELETON - a block of kind (105 program, 106 module, 108
  function, 172 scope) named name: for a function, its symbol in the
  outermost block, checked against an earlier declaration; class 2
  declares it only.  parms the parameters by name, protos the
  prototype's types.  c_def_sem.pas 0x0484F8 (cc.a88k 0x048778): c_main,
  c_expr_syn, c_stmt_sem and c_syntax pass the name and the declaration
  by address. }
procedure def_blk_skeleton(
    kind: integer;
    in name: c_name_t;
    cls: integer;
    in decl: c_decl_t;
    parms: c_parm_ptr_t;
    protos: c_parlist_ptr_t;
    p28: boolean;
    conv: integer;
    opts: integer32;
    into: c_blk_ptr_t); options(val_param); extern;

{ DEF_BLK_PARAMS - il_180's parameters and result as variables.
  c_def_sem.pas 0x048A96 (cc.a88k 0x048D16): promote set for an
  old-style definition (c_main passes false). }
procedure def_blk_params(
    promote: boolean); options(val_param); extern;

{ DEF_ALLOC_VAR - allocate v's size bytes (static data, the frame).
  c_def_sem.pas 0x048FE0 (cc.a88k 0x049260). }
procedure def_alloc_var(
    v: c_sym_ptr_t;
    size: integer32); options(val_param); extern;

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

{ c_stmt_sem.pas: statements (add_node calls link_top; c_syntax the
  others; checked against c_stmt_sem.pas's bodies).  The labels are
  IL nodes passed by address: il_178 until a label (144) or a chain of
  branches waiting for one is made. }

{ LINK_TOP - append the top-level node n to IL's chain (il_d4..il_d8),
  defining a pending label first.  c_stmt_sem.pas 0x05BEF8 (cc.a88k
  0x05C178). }
procedure link_top(
    n: il_$node_ptr_t); options(val_param); extern;

{ DEF_DEF_LABEL - make the pending label (il_c8) a label node.
  c_stmt_sem.pas 0x05C304 (cc.a88k 0x05C584). }
procedure def_def_label; extern;

{ DEF_LABL - define the label name here (diagnostics 23, 57, 56).
  c_stmt_sem.pas 0x05C7B4 (cc.a88k 0x05CA34). }
procedure def_labl(
    in name: c_name_t); extern;

{ IF_S, ELSE_S, ENDIF_S - an if statement's branches around its
  parts: else_lab and end_lab in the caller's frame.  c_stmt_sem.pas
  0x05C8CA, 0x05C900, 0x05C94A (cc.a88k 0x05CB4A, 0x05CB80,
  0x05CBCA). }
procedure if_s(
    var else_lab: il_$node_ptr_t;
    var end_lab: il_$node_ptr_t); extern;

procedure else_s(
    var else_lab: il_$node_ptr_t;
    var end_lab: il_$node_ptr_t); extern;

procedure endif_s(
    var else_lab: il_$node_ptr_t;
    var end_lab: il_$node_ptr_t); extern;

{ CASE_CON - a case constant of the switch c (diagnostics 45, 46); with
  push its value is pushed on the expression stack.  c_stmt_sem.pas
  0x05C9F8 (cc.a88k 0x05CC78). }
procedure case_con(
    var cx: c_cexp_t;
    var c: c_case_t;
    push: boolean); options(val_param); extern;

{ CASE_S, CASE_DEFAULT, CASE_E - a switch statement's start (the
  selector on the stack), a case or the default label, the end.
  c_stmt_sem.pas 0x05CB26, 0x05CC7C, 0x05CDA4 (cc.a88k 0x05CDA6,
  0x05CEFC, 0x05D024). }
procedure case_s(
    var c: c_case_t); extern;

procedure case_default(
    var c: c_case_t;
    is_default: boolean); options(val_param); extern;

procedure case_e(
    var c: c_case_t); extern;

{ The loops' labels: WHILE_LABEL, WHILE_S, WHILE_E (c_stmt_sem.pas
  0x05CDFA, 0x05CE3E, 0x05CE6E), FOR_START_LAB, FOR_S, FOR_NEXT_LAB,
  FOR_E (0x05CEBC, 0x05CF00, 0x05CF30, 0x05CF66), REPEAT_S, REPEAT_E
  (0x05CFB4, 0x05CFF8); cc.a88k 0x280 higher. }
procedure while_label; extern;
procedure while_s; extern;
procedure while_e; extern;
procedure for_start_lab; extern;
procedure for_s; extern;
procedure for_next_lab; extern;
procedure for_e; extern;
procedure repeat_s; extern;
procedure repeat_e; extern;

{ CALL_S - the call on the top of the stack as a statement.
  c_stmt_sem.pas 0x05D05C (cc.a88k 0x05D2DC). }
procedure call_s; extern;

{ BODY_S, BODY_E - a routine's body begins (the profiling calls under
  -PROF) and ends.  c_stmt_sem.pas 0x05D62C, 0x05D7CE (cc.a88k
  0x05D8AC, 0x05DA4E). }
procedure body_s; extern;
procedure body_e; extern;

{ NXTEXT_S - break or continue (il_cc the token, il_d0 the line).
  c_stmt_sem.pas 0x05D9F8 (cc.a88k 0x05DC78). }
procedure nxtext_s; extern;

{ RETURN_S - c_stmt_sem.pas 0x05DA8A (cc.a88k 0x05DD0A). }
procedure return_s; extern;

{ GOTO_S - goto name.  c_stmt_sem.pas 0x05DAAC (cc.a88k 0x05DD2C). }
procedure goto_s(
    in name: c_name_t); extern;

{ TEMP_ALLOC - a temporary variable <stack-temp-n> of size bytes and
  register class kind (its node).  c_stmt_sem.pas 0x05DB3A (cc.a88k
  0x05DDBA). }
function temp_alloc(
    size: integer;
    kind: integer): il_$node_ptr_t; options(val_param); extern;

{ WALK_TREE - lower the tree t (assignments, conditional and logical
  operators, calls, post-increments to statements) under parent; the
  tree's value.  c_stmt_sem.pas 0x05E938 (cc.a88k 0x05EBB8). }
function walk_tree(
    t: il_$node_ptr_t;
    parent: il_$node_ptr_t;
    up: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ c_syntax.pas: called from c_main, c_expr_sem, c_stmt_sem and c_lex_pp. }

{ SYNTAX - c_syntax.pas 0x0609D8 (cc.a88k 0x060C58). }
procedure syntax; extern;

{ CC_WALK_IT - apply walker to the IL tree t (by address) and to each of
  its operands' trees, before them when pre is set, else after; under
  the logical operators (51 ?:, 52 ||, 53 &&) a constant first operand
  decides the result (a one-character string taken as its character
  first).  c_syntax.pas 0x0661BC (cc.a88k 0x06643C): c_stmt_sem's
  add_cbranch and c_expr_sem pass call_kfold's address (`move.l
  #0x066162'), a routine parameter in the original (ref 5.4); declared
  as a routine pointer by value (the same frame) since dpc has no
  routine parameters (docs/dpc-gaps.md 21). }
procedure cc_walk_it(
    var t: il_$node_ptr_t;
    walker: c_walker_t;
    pre: boolean); options(val_param); extern;

{ CALL_KFOLD - fold the constants of the tree n (kfold with no parent).
  c_syntax.pas 0x066162 (cc.a88k 0x0663E2): no call site, its address
  passed to cc_walk_it. }
procedure call_kfold(
    var n: il_$node_ptr_t); extern;

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
