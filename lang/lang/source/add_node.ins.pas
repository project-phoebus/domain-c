{ lang/lang/source/add_node.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/add_node.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ ADD_NODE - building and copying IL tree nodes (add_tn,
  buildtreenode, add_dn, add_pn, ...), the phase attributes of a node
  (getphase) and the top-level nodes.  add_node.pas (cc.m68k
  0x09F9A4, A5 0x2C2080; cc.a88k 0x0A1384, A5 0x4420F0).

  The headings of the 11 routines of the unit other units call (of its
  23 routines), checked against add_node.pas's bodies.  Parameters the
  callers pass several types for are univ_ptr or univ.

  Not known from the original: every parameter name. }

{ The unit's other global routines are called only within it (or not at
  all) and are declared in the unit file: get_next_symbol 0x09F9A4,
  char_maxlen 0x09F9A6, make_temp 0x09F9BC, make_char_temp 0x09F9D6,
  init_aux_ftn 0x09F9F0, add_top_node 0x09F9F2 (c_stmt_sem and c_syntax
  have internal routines of that name), push 0x09FA3E, walk_it
  0x09FBAE, add_routine_reference 0x0A1262. }

type
  { GETPHASE's result, a node's phase (+4 of the nodes that have one):
    callers test its elements (commit_top_node's `lsr.b #1' for 0,
    `btst #20,D0' for 20; runbackend's normalize_il). }
  add_node_$phase_t = set of 0..31;

  { A tree node's descriptor (its 16 bytes at +20; c_objtype's
    c_desc_t, kfold's kf_desc_t), which add_tn and buildtreenode take
    by address: the size, the register class of the result (+4), of
    the operands or the builtin's function (+6), a comparison's
    condition code (+8), the flags (+10: bit 6 signed). }
  add_node_$desc_t = record
    size: integer32;                    { +0 }
    rlen: integer;                      { +4 }
    w6: integer;                        { +6 }
    w8: integer;                        { +8 }
    flags: packed record                { +10 }
      b7: boolean;
      signed: boolean;                  { .6 }
      b5, b4, b3: boolean;
      b2: boolean;                      { .2 }
      b1, b0: boolean;
      b11: 0..255;                      { +11 }
    end;
    unused_12: integer32;               { +12 }
  end;

  { buildtreenode's operands, by address. }
  add_node_$opnds_t = array [1..64] of il_$node_ptr_t;

{ GETPHASE - the phase of the node n: tree nodes and the other nodes
  that have one keep it at +4; a variable (109), kind 110, a type name
  (118), a field (119, 120) and a parameter (121) make it from their
  attributes; other nodes and nil have none.  0x09FAD4, cc.a88k
  0x0A14B4; 69 call sites (alias, c_expr_sem, cg_addr, cg_assign,
  cg_tree, commit_top_node, ...); result in D0.  univ_ptr: c_expr_sem
  passes a type. }
function getphase(
    n: univ_ptr): add_node_$phase_t; options(val_param); extern;

{ COPY_TREE - a copy of the tree n (by address): tree nodes, references
  and calls are copied, and under one calling convention a call is
  moved to a temporary assigned before it; other nodes are shared.
  0x09FF08, cc.a88k 0x0A18E8; 30 call sites (opt_main, opt_vector);
  result in A0. }
function copy_tree(
    var n: il_$node_ptr_t): il_$node_ptr_t; extern;

{ ADD_NODE_$DISPOSE_TOP_LEVEL - dispose of the top-level node n (by
  address), extra bytes longer than its kind's size.  0x0A05EE, cc.a88k
  0x0A1FCE; 0 call sites. }
procedure add_node_$dispose_top_level(
    var n: il_$node_ptr_t;
    extra: integer32); options(val_param); extern;

{ ADD_NODE_$NEW_TOP_LEVEL - a new top-level node of kind, extra bytes
  longer than its kind's size, its header cleared.  0x0A1190, cc.a88k
  0x0A2B70; 1 call site (opt_main); result in A0. }
function add_node_$new_top_level(
    kind: integer;
    extra: integer32): il_$node_ptr_t; options(val_param); extern;

{ ADD_DISP_NODE - the displacement node (147) disp bytes from base for
  the symbol sym (a displacement node as base gives its own base and
  displacement); base itself when disp is 0, the phase empty and force
  not set.  0x0A1300, cc.a88k 0x0A2CE0; 4 call sites (c_expr_sem,
  kfold); result in A0. }
function add_disp_node(
    base: il_$node_ptr_t;
    sym: univ_ptr;
    disp: integer32;
    force: boolean): il_$node_ptr_t; options(val_param); extern;

{ ADD_DN - add_disp_node without force.  0x0A13D6, cc.a88k 0x0A2DB6;
  21 call sites (c_expr_sem, c_stmt_sem, c_syntax, delay, opt_inline,
  opt_main); result in A0 (add_disp_node's, left there). }
function add_dn(
    base: il_$node_ptr_t;
    sym: univ_ptr;
    disp: integer32): il_$node_ptr_t; options(val_param); extern;

{ ADD_SDN - the symbolic displacement node (205) of base (a displacement
  node's base, its displacement added after) for the symbol sym and the
  variable v.  0x0A13FE, cc.a88k 0x0A2DDE; 2 call sites (c_expr_sem,
  opt_inline); result in A0. }
function add_sdn(
    base: il_$node_ptr_t;
    sym: univ_ptr;
    v: univ_ptr): il_$node_ptr_t; options(val_param); extern;

{ ADD_DINDEXN - the indexed reference node (145) of base by the tree
  index, len bytes an element, for item (a variable or a type: a large
  type wants a long index), then disp bytes on.  0x0A14F8, cc.a88k
  0x0A2ED8; 5 call sites (c_expr_sem, opt_main); result in A0. }
function add_dindexn(
    base: il_$node_ptr_t;
    item: univ_ptr;
    index: il_$node_ptr_t;
    disp: integer32;
    len: integer;
    align: integer;
    b23: integer): il_$node_ptr_t; options(val_param); extern;

{ ADD_PN - the pointer dereference node (146) of base for item (the
  type a dereferenced pointer points to); an address node gives its
  operand, an address sum an indexed reference.  0x0A1652, cc.a88k
  0x0A3032; 10 call sites (c_expr_sem, c_expr_syn, c_stmt_sem,
  opt_inline, opt_strength); result in A0. }
function add_pn(
    base: il_$node_ptr_t;
    item: univ_ptr;
    align: integer;
    b23: integer): il_$node_ptr_t; options(val_param); extern;

{ ADD_TN - the tree node of operator op over the expression stack's
  entries l..r (c_globals' cexs_stack), left in entry l and the stack
  cut back to it; constants are folded and operands reassociated where
  they can be, and d may be changed.  0x0A1ABC, cc.a88k 0x0A349C; 52
  call sites (c_expr_sem, c_stmt_sem). }
procedure add_tn(
    op: integer;
    var d: univ add_node_$desc_t;
    l: integer;
    r: integer); options(val_param); extern;

{ BUILDTREENODE - a tree node (137) of operator op with descriptor d
  over the count operands ops, its phase the operands'.  0x0A4C54,
  cc.a88k 0x0A6634; 41 call sites (c_stmt_sem, commit_top_node, kfold,
  opt_inline, opt_livevar, opt_main, ...); result in A0. }
function buildtreenode(
    op: integer;
    in d: univ add_node_$desc_t;
    in ops: univ add_node_$opnds_t;
    count: integer): il_$node_ptr_t; options(val_param); extern;
