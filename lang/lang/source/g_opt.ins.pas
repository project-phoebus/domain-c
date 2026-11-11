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

  Add the optimizer's other cells (opt_main +0x14, +0x20, +0x24,
  +0x4C, +0x5A, +0x60, +0x62, read by opt_reachdef, opt_strength, the
  reg_ units) and headings as their units are translated; the record
  fields are named by use. }

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
    no_prune (.1) keeps an evaluation's operands (make_cse_parent
    sets it on a statement given a cse); region (+43, a word) its
    entry of opt_4009c, 0 for a statement of no region (cse looks
    for the nearest one); block (+16) the basic block of an empty
    evaluation (a loop's mark, cse); cses (+26) the cse parents (190)
    made at it.

    A statement with a region number is opt_4009c's entry of that
    number (opt_livevar: the entry's kind, operands and variable are
    the statement's): vars (+22) its table of the region's variables,
    by number (find_var), each with its def-use chains; regs (+30) the
    registers free over it (varcheck: reg_save of each node); vset
    (+34) the variables it uses (buildsets, build_du_chains).  hdr
    (+38..+45): vnum (+38) the variable it assigns (its number in
    vars, 0 none: assign_elim clears it when the store is removed),
    num (+39) its number in il_120, two bytes of flags (+41, +42: the
    image reads and writes them as one 16-bit field, assign_elim
    `andi.l #0xFF0000FF; ori.l #0x10000' of the longword at +40 for
    deleted alone, `or.w #2' and `or.w #8' of the word for first and
    last: perhaps a set in the original), region (+43) and a byte. }
  g_opt_block_ptr_t = ^g_opt_block_t;
  g_opt_stmt_ptr_t = ^g_opt_stmt_t;
  g_opt_vars_ptr_t = ^g_opt_vars_t;
  g_opt_varset_ptr_t = ^g_opt_varset_t;
  g_opt_regs_t = set of 0..31;
  g_opt_stmt_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    prev: g_opt_stmt_ptr_t;             { +4 }
    next: g_opt_stmt_ptr_t;             { +8 }
    unused_12: integer32;               { +12 }
    block: g_opt_block_ptr_t;           { +16 }
    line: integer;                      { +20 }
    vars: g_opt_vars_ptr_t;             { +22 }
    cses: il_$node_ptr_t;               { +26 }
    regs: g_opt_regs_t;                 { +30 }
    vset: g_opt_varset_ptr_t;           { +34 }
    hdr: packed record                  { +38 }
      vnum: 0..255;                     { +38 }
      num: 0..65535;                    { +39 }
      b7: boolean;                      { +41 .7: report_removal
                                          stays quiet }
      b6: boolean;                      { .6: for_check's assignment
                                          (a for loop's index) }
      b5: boolean;                      { .5: report_removal stays
                                          quiet }
      b4, b3: boolean;
      counted: boolean;                 { .2: liveanalysis took the
                                          statement off its variable's
                                          count }
      no_prune: boolean;                { .1 }
      deleted: boolean;                 { .0 }
      b42_7, b42_6: boolean;            { +42 }
      kills: boolean;                   { .5: buildsets: kills the
                                          variables (109) whose address
                                          may be taken }
      b42_4: boolean;
      last: boolean;                    { .3: its block's last_stmt }
      b42_2: boolean;
      first: boolean;                   { .1: its block's first_stmt }
      b42_0: boolean;
      region: 0..65535;                 { +43 }
      b45: 0..255;                      { +45 }
    end;
    unused_46: integer;                 { +46 }
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
      { 140: the stored value's descriptor (asg_size .. asg_flags) as
        a whole (assign_elim passes it to buildtreenode). }
      4: (asg_desc: add_node_$desc_t);  { +48 }
      { 148 (a call): the routine called; 151, 188: the operand. }
      5: (x48: il_$node_ptr_t);         { +48 }
  end;

  { An IL tree node (137 an operator, 143, ...; kfold's kf_tree_t, cg's
    cg_tree_t): flags the longword at +4 (element k its bit k: 3, 4 and
    12 mark a tree to keep, 6 that the node stands for its statement,
    whose number is stmt; 2 a node not to be made a cse), owner its
    statement, uses the use count, size .. dflags its value's
    descriptor (rlen the register class: 6 single, 7 double), op the
    operator (36, 37 the multiplication and division
    is_scale_candidate looks for). }
  g_opt_tree_ptr_t = ^g_opt_tree_t;
  g_opt_tree_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    flags: set of 0..31;                { +4 }
    unused_8: integer;                  { +8 }
    stmt: g_opt_num_t;                  { +10 }
    owner: g_opt_stmt_ptr_t;            { +12 }
    uses: integer;                      { +16 }
    unused_18: integer;                 { +18 }
    size: integer32;                    { +20 }
    rlen: integer;                      { +24 }
    w26: g_opt_num_t;                   { +26 }
    w28: g_opt_num_t;                   { +28 }
    dflags: packed record               { +30 }
      b7: boolean;
      signed: boolean;                  { .6 }
      b5, b4, b3, b2, b1, b0: boolean;
      b31: 0..255;                      { +31 }
    end;
    unused_32: integer32;               { +32 }
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

  { A constant a loop uses (opt_loop's add_constant, 10 bytes from new):
    count its uses. }
  g_opt_const_ptr_t = ^g_opt_const_t;
  g_opt_const_t = record
    node: il_$node_ptr_t;               { +0 }
    next: g_opt_const_ptr_t;            { +4 }
    count: integer;                     { +8 }
  end;

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
    consts: g_opt_const_ptr_t;          { +20: the constants a loop's
                                          blocks use (add_constant) }
    unused_24: integer32;               { +24 }
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
    first_stmt: g_opt_stmt_ptr_t;       { +84 }
    last_stmt: g_opt_stmt_ptr_t;        { +88 }
    link: g_opt_block_ptr_t;            { +92 }
    serial: integer;                    { +96 }
    cse_serial: integer;                { +98: cse's walk }
    regs: g_opt_regs_t;                 { +100: the registers free over
                                          the block (varcheck,
                                          liveanalysis: reg_save) }
    unused_104: integer;                { +104 }
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

  { A def-use or use-def chain's cell (8 bytes from mem_$alloc of
    opt_main_18): the statement defining or using a variable. }
  g_opt_chain_ptr_t = ^g_opt_chain_t;
  g_opt_chain_t = record
    next: g_opt_chain_ptr_t;            { +0 }
    stmt: g_opt_stmt_ptr_t;             { +4 }
  end;

  { A variable's entry in a statement's table (vars; find_var looks in
    opt_region's): node the variable (109, 110); count the statements
    using it (addvaruse); ud the statements whose values of it reach
    this one, du those this one's value reaches (build_du_chains,
    elim_chains); flags (a word): the uses' kinds or-ed in by addvaruse
    (bit 0 the value is read, 1 and 5 as an operand, 2 by address
    (varcheck), 3, 4), 16#100 a chain was cut (elim_chains: no report
    of the removal). }
  g_opt_var_ptr_t = ^g_opt_var_t;
  g_opt_var_t = record
    node: il_$node_ptr_t;               { +0: the variable (109, 110) }
    unused_4: integer;                  { +4 }
    count: integer;                     { +6 }
    ud: g_opt_chain_ptr_t;              { +8 }
    du: g_opt_chain_ptr_t;              { +12 }
    flags: integer;                     { +16 }
  end;
  g_opt_vars_t = array [1..255] of g_opt_var_ptr_t;  { a byte index is a
                                          word (`lsl.w #2') }

  { A set of variables by number (32 bytes: opt_livevar's per block
    and per statement sets). }
  g_opt_varset_t = set of 0..255;
  g_opt_varsets_t = array [1..16383] of g_opt_varset_t;
  g_opt_varsets_ptr_t = ^g_opt_varsets_t;

  { cse's nodes: a use (189, 36 bytes; +4..+15 copied from the tree it
    stands for, flag 6 set, stmt its number) of a common
    subexpression whose value a parent (190, 28 bytes) keeps; the
    parent stands for the tree in il_120 and is listed at its
    statement (cses, next). }
  g_opt_cse_ptr_t = ^g_opt_cse_t;
  g_opt_cse_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      { 189 }
      1: (u_hdr: array [1..3] of integer32;  { +4..+15 }
          u_parent: g_opt_cse_ptr_t;    { +16 }
          u_tree: il_$node_ptr_t;       { +20 }
          u_ent: g_opt_stmt_ptr_t;      { +24: opt_4009c's entry }
          u_next: g_opt_cse_ptr_t;      { +28: the parent's next use }
          u_x: il_$node_ptr_t);         { +32 }
      { 190 }
      2: (p_tree: il_$node_ptr_t;       { +4 }
          p_next: g_opt_cse_ptr_t;      { +8: the statement's next }
          p_stmt: g_opt_stmt_ptr_t;     { +12 }
          p_num: g_opt_num_t;           { +16: the tree's number }
          p_unused_18: integer;         { +18 }
          p_uses: g_opt_cse_ptr_t;      { +20 }
          p_24: integer32);             { +24 }
  end;

  { A basic block's record as the code generator reads it (il_11c
    points to the blocks by number, from 1; select_block_list and
    select_loop return lists of them through +92).  cg_top's
    initialize_tree and basicblock. }
  g_opt_loop_ptr_t = ^g_opt_loop_t;
  g_opt_loop_t = record
    unused_0: array [0..40] of integer; { +0 }
    head: integer;                      { +82: select_loop's argument }
  end;
  g_opt_bb_ptr_t = ^g_opt_bb_t;
  { The code generator's view of a basic block (cg_top), the same
    record as g_opt_block_t, the optimizer's: after optimization the
    code generator keeps its own data in some of the optimizer's words
    (+12, +24, +100..+108).  select_block_list's and select_loop's
    results are converted to it. }
  g_opt_bb_t = record
    flags: char;                        { +0: bits 3 and 2 tested
                                          (initialize_tree: a block with
                                          bit 2 and not 3 heads a loop) }
    unused_1: array [1..11] of char;    { +1 }
    regs_in: univ_ptr;                  { +12: nil when no register
                                          contents carry into the block
                                          (basicblock) }
    unused_16: array [1..2] of integer32;  { +16 }
    cache_in: univ_ptr;                 { +24: the object cache the
                                          block starts with (basicblock:
                                          cg_addr's entries from +4) }
    unused_28: array [1..16] of integer32;  { +28 }
    next: g_opt_bb_ptr_t;               { +92: the select lists' link }
    unused_96: integer32;               { +96 }
    regs: set of 0..31;                 { +100: the registers free over
                                          the block (initialize_tree) }
    unused_104: integer32;              { +104 }
    loop: ^g_opt_loop_ptr_t;            { +108 }
  end;
  g_opt_bb_list_ptr_t = ^array [1..16383] of g_opt_bb_ptr_t;

var
  { opt_main.pas's data +0x8 (cc.m68k 0x2D2EF8, reached absolutely):
    a memory pool cg_top's codegen empties at the end. }
  opt_main_8: extern univ_ptr;

  { opt_main.pas's +0x18 (cc.m68k 0x2D2F08): the memory pool
    (mem_$pool_t) the chains are allocated from (opt_livevar's
    build_du_chains, opt_loop, opt_reachdef, opt_strength). }
  opt_main_18: extern univ_ptr;

  { opt_main.pas's +0x40, +0x44, +0x48 (cc.m68k 0x2D2F30, 0x2D2F34,
    0x2D2F38): by block number (from 1), the variables live at the
    block's exit, those it does not assign, and those it uses before
    assigning them (opt_livevar's buildsets and lvanalyze; reg_life,
    reg_cost_68k). }
  opt_live_out: extern g_opt_varsets_ptr_t;
  opt_not_killed: extern g_opt_varsets_ptr_t;
  opt_used: extern g_opt_varsets_ptr_t;

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
  opt_4009c: extern array [0..65535] of g_opt_stmt_ptr_t;  { +0x4009C
                                          (0x312F8C, 0x4D3938, reached
                                          absolutely, from 0: `lea
                                          (0,A1,D3.l)'; 13 units) }

  { opt_loop.pas's +4 (cc.m68k 0x2D2EE4, cc.a88k 0x493890): by node
    number, the block the node could be hoisted to (opt_cse's
    cse_$set_hoistability and cse, opt_main). }
  opt_loop_hoist: extern g_opt_nums_ptr_t;

  { opt_cse.pas's +0x88 (cc.m68k 0x2D2ED0, cc.a88k 0x49387C): how many
    nodes cse looks back from each candidate (opt_main's g_opt sets
    it). }
  cse_limit: extern integer;

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

{ opt_cse.pas (cc.m68k 0x0D4748, cc.a88k 0x2A1938). }

{ CSECLEANUP - make the common subexpressions found explicit: each
  tree standing for an earlier one gets a parent (190) and uses (189)
  (opt_main's g_opt). }
procedure csecleanup; extern;

{ MOVED_CHECK - t, or the statement node it stands for (flag 6)
  (opt_loop's do_move_check, checkcses). }
procedure moved_check(
    var t: il_$node_ptr_t); extern;

{ CSE - find the common subexpressions of the routine's blocks
  (opt_main's g_opt). }
procedure cse; extern;

{ opt_livevar.pas (cc.m68k 0x0D6A8C, cc.a88k 0x2A3C7C). }

{ LIVEANALYSIS - the def-use chains and the removal of dead stores
  (under opt_on 12 or 13), each block's and statement's free registers
  and the variables' uses, then the live variables (opt_main's g_opt). }
procedure liveanalysis; extern;

{ opt_loop.pas (cc.m68k 0x0D8960, cc.a88k 0x2A5B50). }

{ ADD_CONSTANT - count constant t once more among block b's constants
  (opt_livevar's varcheck, opt_loop).  0x0D935E: both by address
  (varcheck passes a frame copy of t and a statement's +16). }
procedure add_constant(
    in t: il_$node_ptr_t;
    in b: g_opt_block_ptr_t); extern;

{ LOOPOPT - move the loops' invariant trees to their preheaders' marks
  (under opt_on 16..18), then checkcses (opt_main's g_opt). }
procedure loopopt; extern;

{ MOTION_CONSTANTS - move the loops' real constants out (under opt_on
  17; opt_main's g_opt). }
procedure motion_constants; extern;

{ opt_main.pas (cc.m68k 0x0DB2C6 for opt_main_$ensure_var_set). }

{ OPT_MAIN_$ENSURE_VAR_SET - give s a set (32 bytes from mem_$alloc of
  opt_main's +0x1C pool) when it has none (opt_loop's fixupchildren
  passes a statement's vset). }
procedure opt_main_$ensure_var_set(
    var s: g_opt_varset_ptr_t); extern;

{ opt_reachdef.pas (cc.m68k 0x0E2868 for make_motioned_ud_chain). }

{ MAKE_MOTIONED_UD_CHAIN - the use-def chain of variable v at
  statement s, region r (make_ud_chain of r's block number, s and v;
  opt_loop's fixupchildren: all three by address, v and r words). }
procedure make_motioned_ud_chain(
    in v: integer;
    in r: integer;
    in s: g_opt_stmt_ptr_t); extern;

{ opt_strength.pas (cc.m68k 0x0E78B8 for delparent). }

{ DELPARENT - take the cse parent p (190) off its statement's list of
  parents (opt_livevar's check_cse_uses: p by address, a frame copy;
  `in' until opt_strength is translated). }
procedure delparent(
    in p: g_opt_cse_ptr_t); extern;
