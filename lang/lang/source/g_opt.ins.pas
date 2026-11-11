{ lang/lang/source/g_opt.ins.pas - the global optimizer's insert
  (opt_*), opened by the optimizer's units, kfold, cg_call and others.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  The optimizer's code is in the section opt$procedure (cc.m68k 0x0D393C,
  cc.a88k 0x2A0B2C); its data in opt$data, mostly opt_main.pas's block
  (A5 0x2D2EF0 in cc.m68k, 0x49389C in cc.a88k, 0x8009C bytes; the same
  offsets in both binaries).

  The optimizer works on the IL's nodes (il_120^, from 1: a routine's
  top-level statements and their trees, each statement's trees before
  it) cut into basic blocks (il_11c^[1..il_124]): opt_select builds the
  depth-first orders, the dominator tree and the loops over them.

  Not known from the original: every name here but the routines'. }

{ TODO(pascal) g_opt.ins.pas holds what the translated units need

  Add the optimizer's other cells (opt_main +0x8, +0x14, +0x18, +0x20,
  +0x24, +0x40..+0x4C, +0x5A, +0x60, +0x62, read by opt_livevar,
  opt_reachdef, opt_strength, the reg_ units and cg_top) and headings
  as their units are translated; the record fields are named by use. }

type
  { Block, node and variable numbers: words, zero-extended where read
    (`clr.l; move.w'), compared unsigned. }
  g_opt_num_t = 0..65535;

  { il_120^: the IL's nodes by number (kfold's kf_nodes_t). }
  g_opt_nodes_t = array [1..16383] of il_$node_ptr_t;
  g_opt_nodes_ptr_t = ^g_opt_nodes_t;

  { A top-level statement node as the optimizer reads it (c_objtype's
    c_top_t): 139 evaluate, 140 assign, 141/142/150 branches, 144 a
    label, ...  hdr's second byte (+41): deleted (.0) set when
    general_opts merges an assignment into the one before it,
    no_prune (.1) keeps an evaluation's operands. }
  g_opt_stmt_ptr_t = ^g_opt_stmt_t;
  g_opt_stmt_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    prev: g_opt_stmt_ptr_t;             { +4 }
    next: g_opt_stmt_ptr_t;             { +8 }
    unused_12: integer32;               { +12 }
    unused_16: integer32;               { +16 }
    line: integer;                      { +20 }
    unused_22: integer;                 { +22 }
    unused_24: array [6..9] of integer32;  { +24..+39 }
    hdr: packed record                  { +40 }
      b40: 0..255;
      b7, b6, b5, b4, b3, b2: boolean;  { +41 }
      no_prune: boolean;                { .1 }
      deleted: boolean;                 { .0 }
    end;
    unused_42: array [1..3] of integer; { +42..+47 }
    case integer of
      { 139: the operands evaluated. }
      1: (eval_unused_48: integer;      { +48 }
          eval_count: integer;          { +50 }
          eval_opnd: array [1..64] of il_$node_ptr_t);  { +52 }
      { 140: lhs := lhs op rhs, op 0 a plain store (1, 2, 15, 16
        additions, 3 and, 4 or, 5 exclusive or, as general_opts folds
        them; 6 and 25 block moves of size bytes; merge_assignments
        also folds 2 a subtraction, 10 a bit field, 13 not, 14
        negation, 15 a left shift); rlen the stored width's class (1,
        2, 4; 11 a block; delay's table gives the bytes). }
      2: (asg_size: integer32;          { +48 }
          asg_rlen: g_opt_num_t;        { +52 }
          asg_w54: g_opt_num_t;         { +54: a bit field's (op 10) }
          asg_w56: g_opt_num_t;         { +56: likewise }
          asg_flags: packed record      { +58 }
            b7, b6, b5, b4, b3: boolean;
            chars: boolean;             { .2: a block move (op 6) of
                                          characters (assign_opt) }
            b1, b0: boolean;
            b59: 0..255;                { +59 }
          end;
          asg_unused_60: integer32;     { +60 }
          asg_lhs: il_$node_ptr_t;      { +64 }
          asg_rhs: il_$node_ptr_t;      { +68 }
          asg_x: il_$node_ptr_t;        { +72 }
          asg_op: integer);             { +76 }
      { 141, 142, 150: the branch's target; 142's condition. }
      3: (br_target: il_$node_ptr_t;    { +48 }
          br_unused_52: integer32;      { +52 }
          br_cond: il_$node_ptr_t);     { +56 }
  end;

  { An IL tree node (137 an operator, 143, ...; kfold's kf_tree_t, cg's
    cg_tree_t): flags the longword at +4 (element k its bit k: 3, 4 and
    12 mark a tree to keep, 6 that the node stands for its statement,
    whose number is stmt), uses the use count, rlen the value's
    register class (6 single, 7 double), op the operator (36, 37 the
    multiplication and division is_scale_candidate looks for). }
  g_opt_tree_ptr_t = ^g_opt_tree_t;
  g_opt_tree_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    flags: set of 0..31;                { +4 }
    unused_8: integer;                  { +8 }
    stmt: g_opt_num_t;                  { +10 }
    unused_12: integer32;               { +12 }
    uses: integer;                      { +16 }
    unused_18: integer;                 { +18 }
    size: integer32;                    { +20 }
    rlen: integer;                      { +24 }
    unused_26: array [1..5] of integer; { +26..+35 }
    op: integer;                        { +36 }
    count: integer;                     { +38 }
    opnd: array [1..64] of il_$node_ptr_t;  { +40 }
  end;

  { A routine's block (il_180^) as depth_first_dom keeps its orders:
    the basic blocks in preorder (first, last) and in postorder. }
  g_opt_rtn_ptr_t = ^g_opt_rtn_t;

  { A flow edge (16 bytes): in its source's successor list (succs,
    next_succ) and its target's predecessor list (preds_list,
    next_pred).  dominators' buckets reuse it (dest, next_pred). }
  g_opt_edge_ptr_t = ^g_opt_edge_t;

  { A basic block (il_11c^[num]).  flags (+0, bit 7 first): visited
    (.5) by dfs, last (.4) the last block of a straight run, run (.3)
    the first block of one, latch (.2) the loop header's dominator
    is one of its predecessors, header (.1) a loop's header, skip
    (.0) not looked at by find_loops.  first..last: its nodes (il_120's
    numbers).  idom and dom: the immediate dominator (dominators;
    dom kept); parent .. sdno: the dominator computation's working
    fields (Lengauer and Tarjan's); pre_no, post_no: the depth-first
    numbers (depth_first_dom); link and serial: select_loop's and
    select_block_list's lists; succ: the successors (dfs), pred: the
    predecessors (512 at most for find_loops). }
  g_opt_block_ptr_t = ^g_opt_block_t;
  g_opt_blocks_t = array [1..16383] of g_opt_block_ptr_t;
  g_opt_blocks_ptr_t = ^g_opt_blocks_t;
  g_opt_block_t = record
    flags: packed record                { +0 }
      b7, b6: boolean;
      visited: boolean;                 { .5 }
      last: boolean;                    { .4 }
      run: boolean;                     { .3 }
      latch: boolean;                   { .2 }
      header: boolean;                  { .1 }
      skip: boolean;                    { .0 }
      b1: 0..255;                       { +1 }
    end;
    depth: integer;                     { +2: loops around it }
    dom: g_opt_block_ptr_t;             { +4 }
    first: g_opt_num_t;                 { +8 }
    last: g_opt_num_t;                  { +10 }
    loop: g_opt_block_ptr_t;            { +12: its innermost loop's
                                          header }
    preheader: g_opt_block_ptr_t;       { +16: a header's dominator }
    unused_20: array [5..6] of integer32;  { +20..+27 }
    succs: g_opt_edge_ptr_t;            { +28 }
    preds_list: g_opt_edge_ptr_t;       { +32 }
    idom: g_opt_block_ptr_t;            { +36 }
    pre_next: g_opt_block_ptr_t;        { +40 }
    pre_prev: g_opt_block_ptr_t;        { +44 }
    post_next: g_opt_block_ptr_t;       { +48 }
    post_prev: g_opt_block_ptr_t;       { +52 }
    parent: g_opt_block_ptr_t;          { +56: in the depth-first tree }
    bucket: g_opt_edge_ptr_t;           { +60 }
    ancestor: g_opt_block_ptr_t;        { +64 }
    lbl: g_opt_block_ptr_t;             { +68 }
    semi: g_opt_block_ptr_t;            { +72 }
    sdno: g_opt_num_t;                  { +76: semi's preorder number
                                          (the block's own at first) }
    post_no: g_opt_num_t;               { +78 }
    pre_depth: g_opt_num_t;             { +80 }
    num: g_opt_num_t;                   { +82 }
    unused_84: array [21..22] of integer32;  { +84..+91 }
    link: g_opt_block_ptr_t;            { +92 }
    serial: integer;                    { +96 }
    unused_98: array [1..4] of integer; { +98..+105 }
    nsucc: integer;                     { +106 }
    succ: g_opt_blocks_ptr_t;           { +108 }
    nfwd: integer;                      { +112: predecessors not
                                          reached by a back edge }
    npreds: integer;                    { +114 }
    pred: array [1..512] of g_opt_block_ptr_t;  { +116 }
  end;

  g_opt_edge_t = record
    dest: g_opt_block_ptr_t;            { +0 }
    src: g_opt_block_ptr_t;             { +4 }
    next_succ: g_opt_edge_ptr_t;        { +8 }
    next_pred: g_opt_edge_ptr_t;        { +12 }
  end;

  g_opt_rtn_t = record
    unused_0: array [0..32] of integer32;  { +0..+131 }
    pre_first: g_opt_block_ptr_t;       { +132 }
    pre_last: g_opt_block_ptr_t;        { +136 }
    post_first: g_opt_block_ptr_t;      { +140 }
    post_last: g_opt_block_ptr_t;       { +144 }
  end;

  { A row of the dominance matrix: [a] true when block a dominates the
    row's block (dom). }
  g_opt_dom_row_t = array [0..65535] of boolean;
  g_opt_dom_row_ptr_t = ^g_opt_dom_row_t;

  { Word tables by block number or depth-first number. }
  g_opt_nums_t = array [1..32767] of g_opt_num_t;
  g_opt_nums_ptr_t = ^g_opt_nums_t;

  { A variable's entry in a region's table (find_var). }
  g_opt_var_ptr_t = ^g_opt_var_t;
  g_opt_var_t = record
    node: il_$node_ptr_t;               { +0: the variable (109, 110) }
  end;
  g_opt_vars_t = array [1..16383] of g_opt_var_ptr_t;
  g_opt_vars_ptr_t = ^g_opt_vars_t;

  { An entry of opt_main's table at +0x4009C (kfold's node_number, by
    a node's number at +43; find_var, by opt_region): range a block
    whose first..last are the entry's nodes, vars its variables by
    number. }
  g_opt_range_ptr_t = ^g_opt_range_t;
  g_opt_range_t = record
    unused_0: array [1..4] of integer;  { +0 }
    first: integer;                     { +8 }
    last: integer;                      { +10 }
  end;
  g_opt_ent_ptr_t = ^g_opt_ent_t;
  g_opt_ent_t = record
    unused_0: array [1..4] of integer32;  { +0 }
    range: g_opt_range_ptr_t;           { +16 }
    unused_20: integer;                 { +20 }
    vars: g_opt_vars_ptr_t;             { +22 }
  end;

var
  { opt_main.pas's cells (A5 0x2D2EF0 in cc.m68k, 0x49389C in cc.a88k)
    read by the other units, absolutely.  opt_main defines them. }
  opt_dfs_number: extern g_opt_nums_ptr_t;  { +0x50: by block number,
                                          its depth-first number (dfs;
                                          find_loops) }
  opt_dfs_block: extern g_opt_nums_ptr_t;   { +0x54: by depth-first
                                          number, the block (dfs counts
                                          down; find_loops; 6 units) }
  opt_region: extern g_opt_num_t;       { +0x5E: the entry of opt_4009c
                                          find_var looks in (10 units) }
  opt_last_block: extern g_opt_num_t;   { +0x68: the routine's last
                                          basic block (11 units) }
  opt_first_block: extern g_opt_num_t;  { +0x6A: its first (11 units) }
  opt_track_lines: extern boolean;      { +0x6C: general_opts keeps
                                          il_d0 at each statement's line
                                          (opt_reachdef) }
  opt_dom: extern array [0..65535] of g_opt_dom_row_ptr_t;  { +0x9C
                                          (0x2D2F8C, 0x493938): by block
                                          number, its row of the dominance
                                          matrix (dom; opt_main) }
  opt_4009c: extern array [0..65535] of g_opt_ent_ptr_t;  { +0x4009C
                                          (0x312F8C, 0x4D3938, reached
                                          absolutely, from 0: `lea
                                          (0,A1,D3.l)'; 13 units) }

{ PARAMCLASS - the class of argument k of call n (cg_call's
  kill_any_param_alias tests 1, 3 and 4: the arguments passed by
  reference).  opt_reachdef 0x0E235C: 8 a pointer, 12 a word; D0 a
  word. }
function paramclass(
    n: il_$node_ptr_t;
    k: integer): integer; options(val_param); extern;

{ opt_general.pas (cc.m68k 0x0D6274, cc.a88k 0x2A3464). }

{ OPT_GEN_$PRUNE_EVAL_OPERANDS - drop the operands of an evaluation
  statement (139) whose value is not used (opt_main's general_opts,
  opt_livevar's assign_elim). }
procedure opt_gen_$prune_eval_operands(
    s: g_opt_stmt_ptr_t); options(val_param); extern;

{ IS_SCALE_CANDIDATE - a real multiplication or division by a power of
  two (opt_loop's walkt, cg_tree). }
function is_scale_candidate(
    t: g_opt_tree_ptr_t): boolean; options(val_param); extern;

{ GENERAL_OPTS - constant folding over the routine's nodes and the
  merging of consecutive assignments of constants (opt_main's g_opt). }
procedure general_opts; extern;

{ FIND_VAR - the number of variable v in opt_region's table, 0 when it
  has none (33 call sites: the opt_ and reg_ units). }
function find_var(
    v: il_$node_ptr_t): integer; options(val_param); extern;

{ opt_select.pas (cc.m68k 0x0E56D4, cc.a88k 0x2B28C4). }

{ DOM - whether block a dominates block b (strictly: false for a = b
  or nil) (opt_cse, opt_loop, opt_reachdef, opt_strength, reg_life). }
function dom(
    a: g_opt_block_ptr_t;
    b: g_opt_block_ptr_t): boolean; options(val_param); extern;

{ SELECT_BLOCK_LIST - the blocks from block first back to block stop
  (opt_cse, cg_top), linked through link. }
function select_block_list(
    first: g_opt_num_t;
    stop: g_opt_num_t): g_opt_block_ptr_t; options(val_param); extern;

{ SELECT_LOOP - the blocks of the loop headed by block h, linked
  through link (opt_livevar, opt_loop, opt_strength, reg_life,
  cg_top). }
function select_loop(
    h: g_opt_num_t): g_opt_block_ptr_t; options(val_param); extern;

{ NEW_BLOCK - whether statement t starts a basic block (opt_main,
  opt_strength). }
function new_block(
    t: g_opt_stmt_ptr_t): boolean; options(val_param); extern;

{ DFS - number the blocks reached from b in depth-first postorder,
  counting n down (opt_main). }
procedure dfs(
    b: g_opt_block_ptr_t;
    var n: g_opt_num_t); options(val_param); extern;

{ DEPTH_FIRST_DOM - the preorder and postorder lists of rtn's blocks
  from b, for dominators (opt_main). }
procedure depth_first_dom(
    var rtn: il_$node_ptr_t;
    var b: g_opt_block_ptr_t); extern;

{ DOMINATORS - the immediate dominators of rtn's blocks, root the
  first (opt_main). }
procedure dominators(
    var rtn: il_$node_ptr_t;
    root: g_opt_block_ptr_t); options(val_param); extern;

{ FIND_LOOPS - mark the loop headers and the loops' blocks (opt_main). }
procedure find_loops; extern;

{ opt_assign.pas (cc.m68k 0x0D393C, cc.a88k 0x2A0B2C). }

{ ASSIGN_OPT - merge the run of assignments from start on to adjacent
  storage into one (opt_livevar's coalesce_adjacent_and_eliminate_
  dead_assignments). }
procedure assign_opt(
    start: g_opt_stmt_ptr_t); options(val_param); extern;
