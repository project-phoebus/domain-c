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
  23 routines), read off the frames and the call sites (docs/core-
  plan.md, method change): the frame slots are given as offset:push/use,
  the push at the call sites (p an address, l a longword, w a word, b a
  byte in a word) and the routine's own use of the slot (a moved to an
  address register, l, w or b read as a value, p its address taken); a
  pointer is univ_ptr until its target is known, every slot is a value
  (val_param); a function is one whose callers read D0 or A0 after the
  call (A0 a pointer).

  Not known from the original: every parameter name and most types. }

{ TODO(pascal) add_node headings are read off the frames only

  Narrow the univ_ptr parameters and results to the node types, and name
  the parameters, when add_node.pas and its callers are translated.  A
  routine with no call site (0 call sites) is reached through a
  procedure pointer or not at all; its result is read off its epilogue. }

{ The unit's other global routines are called only within it (or not at
  all) and are left to the unit file: char_maxlen 0x09F9A6, make_temp
  0x09F9BC, make_char_temp 0x09F9D6, add_top_node 0x09F9F2, push
  0x09FA3E, walk_it 0x09FBAE, add_routine_reference 0x0A1262. }

{ GETPHASE - 0x09FAD4, cc.a88k 0x0A14B4; frame 8:l/a; 69 call sites
  (alias, c_expr_sem, cg_addr, cg_assign, cg_tree, commit_top_node,
  ...); result in D0. }
function getphase(
    p1: univ_ptr): integer32; options(val_param); extern;

{ COPY_TREE - 0x09FF08, cc.a88k 0x0A18E8; frame 8:p/a; 30 call sites
  (opt_main, opt_vector); result in A0. }
function copy_tree(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ ADD_NODE_$DISPOSE_TOP_LEVEL - 0x0A05EE, cc.a88k 0x0A1FCE; frame 8:a
  12:l; 0 call sites. }
procedure add_node_$dispose_top_level(
    p1: univ_ptr;
    p2: integer32); options(val_param); extern;

{ ADD_NODE_$NEW_TOP_LEVEL - 0x0A1190, cc.a88k 0x0A2B70; frame 8:w/pw
  10:p/l; 1 call site (opt_main); result in A0. }
function add_node_$new_top_level(
    p1: integer;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ ADD_DISP_NODE - 0x0A1300, cc.a88k 0x0A2CE0; frame 8:p/a 12:l/l 16:l/l
  20:b/b; 4 call sites (c_expr_sem, kfold); result in A0. }
function add_disp_node(
    p1: univ_ptr;
    p2: integer32;
    p3: integer32;
    p4: boolean): univ_ptr; options(val_param); extern;

{ ADD_DN - 0x0A13D6, cc.a88k 0x0A2DB6; frame 8:l/l 12:l/l 16:l/l (all
  passed on to add_disp_node, 8 to its pointer); 21 call sites
  (c_expr_sem, c_stmt_sem, c_syntax, delay, opt_inline, opt_main);
  result in A0. }
function add_dn(
    p1: univ_ptr;
    p2: integer32;
    p3: integer32): univ_ptr; options(val_param); extern;

{ ADD_SDN - 0x0A13FE, cc.a88k 0x0A2DDE; frame 8:l/a 12:l/l 16:l/l; 2
  call sites (c_expr_sem, opt_inline); result in A0. }
function add_sdn(
    p1: univ_ptr;
    p2: integer32;
    p3: integer32): univ_ptr; options(val_param); extern;

{ ADD_DINDEXN - 0x0A14F8, cc.a88k 0x0A2ED8; frame 8:p/l 12:l/a 16:p/al
  20:l/l 24:w/w 26:w/w 28:w/w; 5 call sites (c_expr_sem, opt_main);
  result in A0. }
function add_dindexn(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr;
    p4: integer32;
    p5: integer;
    p6: integer;
    p7: integer): univ_ptr; options(val_param); extern;

{ ADD_PN - 0x0A1652, cc.a88k 0x0A3032; frame 8:l/a 12:l/l 16:w/w 18:w/w;
  10 call sites (c_expr_sem, c_expr_syn, c_stmt_sem, opt_inline,
  opt_strength); result in A0. }
function add_pn(
    p1: univ_ptr;
    p2: integer32;
    p3: integer;
    p4: integer): univ_ptr; options(val_param); extern;

{ ADD_TN - 0x0A1ABC, cc.a88k 0x0A349C; frame 8:w/w 10:p/al 14:w/w
  16:w/w; 52 call sites (c_expr_sem, c_stmt_sem). }
procedure add_tn(
    p1: integer;
    p2: univ_ptr;
    p3: integer;
    p4: integer); options(val_param); extern;

{ BUILDTREENODE - 0x0A4C54, cc.a88k 0x0A6634; frame 8:w/w 10:p/a 14:p/a
  18:w/w; 41 call sites (c_stmt_sem, commit_top_node, kfold, opt_inline,
  opt_livevar, opt_main, ...); result in A0. }
function buildtreenode(
    p1: integer;
    p2: univ_ptr;
    p3: univ_ptr;
    p4: integer): univ_ptr; options(val_param); extern;
