{ lang/lang/source/reg_alloc.ins.pas - the m68k register allocator's
  insert (cc.m68k only): opened by reg_action, reg_alloc,
  reg_color_68k, reg_cost_68k, reg_life and reg_vars (reg_save does
  not open it).  All but reg_life open it before codegen.ins.pas and
  g_opt.ins.pas, so it uses only the prelude's types.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.m68k.  The allocator works on the statements the optimizer
  numbered (opt_4009c, from opt_region to runbackend_16): each
  statement s has two points, 2s (before it) and 2s + 1 (after it),
  and a live range (reg_range_t) holds a bit for each point of the
  routine where its value is live (its bit vector, reg_words
  longwords, the point p at bit p - 2 * opt_region + 2).  reg_life
  builds the ranges (add_range, add_cse_ranges, add_con_range) and
  their interference (run_interference), reg_cost_68k weighs them,
  reg_color_68k colours the graph, reg_action puts the loads and
  stores in and reg_vars tells the debugger where the variables live.

  Not known from the original: every name here but the routines'. }

{ TODO(pascal) reg_alloc.ins.pas holds what the translated reg_ units
  need

  reg_range_t's w24 (an action's reg2) and w26 are named by position
  until reg_life is translated. }

type
  { Statement numbers (opt_4009c's), compared unsigned. }
  reg_num_t = 0..65535;

  { A set of registers: 0..7 D0..D7, 8..15 A0..A7, 16.. the floating
    registers (cg.ins.pas's cg_regset_t). }
  reg_regset_t = set of 0..31;

  { A range's bit vector: the points where it is live, 32 to a
    longword (test_stmt: `lsr.w #5; lsl.w #2', `btst' of the longword). }
  reg_bits_t = array [0..16383] of set of 0..31;
  reg_bits_ptr_t = ^reg_bits_t;

  { A basic block a range spans (add_block, 12 bytes from reg_pool):
    bnum the block's number (il_11c), cost the range's weighted uses
    in it (compute_costs), b10 cleared by add_block. }
  reg_blk_ptr_t = ^reg_blk_t;
  reg_blk_t = record
    next: reg_blk_ptr_t;                { +0 }
    cost: integer32;                    { +4 }
    bnum: reg_num_t;                    { +8 }
    b10: boolean;                       { +10 }
  end;

  { By block number (from 1), whether the block is on a range's list
    (add_block, assert_block_on_list). }
  reg_onlist_t = array [1..16383] of boolean;
  reg_onlist_ptr_t = ^reg_onlist_t;

  { What kind of register a range may get, and why it gets none
    (flags, a word: element k its bit k): 0 none (compute_costs: too
    cheap, a parameter loaded for nothing, a variable whose address
    is taken ...), 2 an address register, 3 a data register, 4 a
    floating register, 6 it can be coloured whatever its conflicts
    get (color_graph: fewer conflicts than registers; removeconflict:
    none left), 8 the range assigns its variable at a statement that
    is not a call (188). }
  reg_flags_t = set of 0..15;

  { A conflict (8 bytes from newconflict): the number num of a range
    that interferes with the range whose list it is on.  A range keeps
    its first conflict in its own cell (conflict, +12..+17) and the
    others in cells chained from conflict.next (add_conflict,
    walkconflicts). }
  reg_conflict_ptr_t = ^reg_conflict_t;
  reg_conflict_t = record
    next: reg_conflict_ptr_t;           { +0 }
    num: integer;                       { +4 }
  end;

  { A live range (64 bytes; reg_alloc allocates reg_nest of them
    from opt_main_20, reg_ranges^[1..]): node the variable (109, 110),
    cse parent (190) or constant (88, 89, 145..147, 163, 195) whose
    value it holds; num its number (compress_graph renumbers); degree
    the ranges it interferes with (conflict and the cells chained from
    it: add_conflict, removeconflict); blocks the basic blocks it
    spans; first and last the statements it spans; reg the register it
    is given (31 none); prefer the registers it would rather have (a
    function's result: D0 or A0; color_graph adds those its conflicts
    and the function's result leave it); rlen its value's register
    class (paint: 5 in an address register, 4 a data register); uses
    and defs the statements reading and assigning it; cost the
    weighted uses, depth the deepest loop of a statement that uses its
    value, priority the cost per statement spanned; live its bit
    vector; avail the registers it may have (availcolors); onlist its
    blocks by number. }
  reg_range_ptr_t = ^reg_range_t;
  reg_range_t = record
    node: il_$node_ptr_t;               { +0 }
    num: integer;                       { +4 }
    degree: integer;                    { +6 }
    blocks: reg_blk_ptr_t;              { +8 }
    conflict: reg_conflict_t;           { +12 }
    first: reg_num_t;                   { +18 }
    last: reg_num_t;                    { +20 }
    reg: integer;                       { +22 }
    w24: integer;                       { +24 }
    w26: integer;                       { +26 }
    prefer: reg_regset_t;               { +28 }
    rlen: integer;                      { +32 }
    uses: integer;                      { +34 }
    defs: integer;                      { +36 }
    flags: reg_flags_t;                 { +38 }
    cost: integer32;                    { +40 }
    depth: integer32;                   { +44 }
    priority: integer32;                { +48 }
    live: reg_bits_ptr_t;               { +52 }
    avail: reg_regset_t;                { +56 }
    onlist: reg_onlist_ptr_t;           { +60 }
  end;
  reg_ranges_t = array [1..16383] of reg_range_t;
  reg_ranges_ptr_t = ^reg_ranges_t;

  { reg_alloc's pool: chunks of 32768 bytes (opt_main_24), handed out
    from the end down (newconflict, add_block). }
  reg_chunk_ptr_t = ^reg_chunk_t;
  reg_chunk_t = record
    next: reg_chunk_ptr_t;              { +0 }
    free: integer32;                    { +4: the bytes left }
    data: array [0..32767] of char;     { +8 }
  end;

var
  { reg_alloc.pas's data (A5 0x2D256C, 16 bytes), reached absolutely
    by reg_color_68k, reg_life and reg_vars. }
  reg_pool: extern reg_chunk_ptr_t;     { +0x0: the current chunk }
  reg_ranges: extern reg_ranges_ptr_t;  { +0x4 }
  reg_nranges: extern integer;          { +0x8 }
  reg_nest: extern integer;             { +0xA: the ranges the routine
                                          may need (reg_alloc's count) }
  reg_words: extern integer;            { +0xC: the longwords of a bit
                                          vector }

{ reg_alloc.pas (cc.m68k 0x0C39A0). }

{ INITPOOL - a new chunk on reg_pool.  0x0C3D90. }
procedure initpool; extern;

{ NEWCONFLICT - 8 bytes of reg_pool for a conflict cell (a new chunk
  when fewer than 6 are left).  0x0C3E0A (reg_color_68k's
  add_conflict); A0. }
function newconflict: reg_conflict_ptr_t; extern;

{ TEST_STMT - whether point k (2s or 2s + 1 of statement s) is in r's
  live range.  0x0C4476: r a pointer, k a word; D0. }
function test_stmt(
    r: reg_range_ptr_t;
    k: integer): boolean; options(val_param); extern;

{ reg_color_68k.pas (cc.m68k 0x0C50AC). }

{ ADD_CONFLICT - range number k among r's conflicts (once).  0x0C50AC
  (reg_life's run_interference: r a pointer, k a word). }
procedure add_conflict(
    r: reg_range_ptr_t;
    k: integer); options(val_param); extern;

{ COLOR_GRAPH - give the n ranges r^[1..n] registers (reg; flags
  element 0 for those that get none).  0x0C5772 (reg_alloc). }
procedure color_graph(
    r: reg_ranges_ptr_t;
    n: integer); options(val_param); extern;

{ reg_life.pas (cc.m68k 0x0C6CD4). }

{ ADD_RANGE - the live ranges of variable v (its number in the
  statements' vars) from its assignment at statement s.  0x0C7EC2
  (reg_alloc: two words). }
procedure add_range(
    v: integer;
    s: integer); options(val_param); extern;

{ ADD_CSE_RANGES - the live ranges of the cse parents made at
  statement s.  0x0C7688 (reg_alloc: a word). }
procedure add_cse_ranges(
    s: integer); options(val_param); extern;

{ ADD_CON_RANGE - a live range for the constant (or strength
  reduction temporary) t a loop uses, from statement s.  0x0C8628
  (reg_alloc: s a word, t a pointer). }
procedure add_con_range(
    s: integer;
    t: il_$node_ptr_t); options(val_param); extern;

{ RANGES_INTERSECT - whether a's and b's bit vectors share a point.
  0x0C7074 (reg_alloc, run_interference); D0. }
function ranges_intersect(
    a: reg_range_ptr_t;
    b: reg_range_ptr_t): boolean; options(val_param); extern;

{ COMBINE_RANGES - b's points, blocks and uses joined to a's and b
  emptied.  0x0C7110 (reg_alloc). }
procedure combine_ranges(
    a: reg_range_ptr_t;
    b: reg_range_ptr_t); options(val_param); extern;

{ RUN_INTERFERENCE - the conflicts of the n ranges r^[1..n] (add_conflict
  of each pair whose bit vectors intersect).  0x0C72FA (reg_alloc). }
procedure run_interference(
    r: reg_ranges_ptr_t;
    n: integer); options(val_param); extern;

{ reg_cost_68k.pas (cc.m68k 0x0C5C5C). }

{ COMPUTE_COSTS - weigh the n ranges r^[1..n]: the uses and
  definitions in each block by the block's loop depth, the class of
  register each may have, and which get none.  0x0C5D4A (reg_alloc). }
procedure compute_costs(
    r: reg_ranges_ptr_t;
    n: integer); options(val_param); extern;

{ reg_action.pas (cc.m68k 0x0C241C). }

{ INSERT_REG_STMTS - put the loads and stores of the n ranges r^[1..n]
  that have registers into the routine (191 statements), and take the
  constants that got none back into their evaluations.  0x0C369A
  (reg_alloc). }
procedure insert_reg_stmts(
    r: reg_ranges_ptr_t;
    n: integer); options(val_param); extern;

{ reg_vars.pas (cc.m68k 0x0C8B28). }

{ STORE_DEBUG_INFO - under -DBS or -DBA, the debugger's ranges of the
  variables and parameters: where each lives in a register and where in
  memory, by source lines.  0x0C9E58 (reg_alloc: r by address, then
  reg_words and reg_nranges). }
procedure store_debug_info(
    var r: reg_ranges_ptr_t;
    words: integer;
    n: integer); options(val_param); extern;
