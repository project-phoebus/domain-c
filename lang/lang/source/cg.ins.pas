{ lang/lang/source/cg.ins.pas - the m68k code generator's routines and
  cells shared by its units (cc.m68k only): cg_addr, cg_assign,
  cg_call, cg_fp, cg_misc, cg_top, cg_tree, emit, fpa, ... open it after
  codegen.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  The headings are read off the routines' frames and their call sites
  (tools/cc_params.py): every value parameter is by value (val_param),
  a word slot an integer; a descriptor passed by address is an unpacked
  address descriptor (codegen_$uads_t, 20 bytes) unless shown.  Which
  insert of the back end declared each routine is not known: the
  routines of the cg_ units and emit, which every cg_ unit opens this
  insert to call, are declared here.

  The code generator's modules keep their data in the section
  codegen$data (cc.m68k 0x354FB8, 0x1DEC bytes): cg_addr at 0x354FB8,
  cg_call and cg_fp at 0x3552F8 (cg_call has none), cg_misc at
  0x356310, cg_top at 0x356314, cg_tree at 0x356460; their cells read
  by other units (absolutely) are declared here by owner.

  Not known from the original: every name here but the routines'. }

{ TODO(pascal) cg.ins.pas holds what the translated units need

  Add the other cg_ routines and cells as their units are translated;
  narrow the descriptors' modes (in, out, var) from the callees'
  bodies. }

type
  { codegen.ins.pas's unpacked address descriptor, for a unit that opens
    this insert first (opt_vector; globals.ins.pas's
    codegen_uads_declared). }
%if not codegen_uads_declared %then
%enable codegen_uads_declared;
  codegen_$uads_t = record
    f1: integer;                        { +0 }
    f2: integer;                        { +2 }
    f3: integer;                        { +4 }
    f4: integer;                        { +6 }
    f5: integer;                        { +8 }
    f6: integer;                        { +10 }
    x: integer32;                       { +12 }
    y: integer32;                       { +16 }
  end;
%endif

  { A value's descriptor in an IL tree node (+20; kfold.pas's kf_desc_t,
    c_objtype's c_desc_t): its size, its register class (rlen: 1 byte,
    2 word, 4 long, 5 address, 6 single, 7 double, 8 and 12 the
    extended forms, 11 an aggregate, as the code generator's switches
    on it read), two other classes (fp_rlen) and flags. }
  cg_desc_t = record
    size: integer32;                    { +0 }
    rlen: integer;                      { +4 }
    w6: integer;                        { +6 }
    w8: integer;                        { +8 }
    flags: integer;                     { +10 }
    unused_12: integer32;               { +12 }
  end;

  { An IL tree node as the code generator reads it (137 an operator,
    138 its value, ...): kfold.pas's kf_tree_t.  op: the operator (40,
    41 the conversions fop_proc tests). }
  cg_tree_ptr_t = ^cg_tree_t;
  cg_tree_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: integer32;                { +4 }
    unused_8: integer32;                { +8 }
    unused_12: integer32;               { +12 }
    uses: integer;                      { +16 }
    w18: integer;                       { +18 }
    desc: cg_desc_t;                    { +20 }
    op: integer;                        { +36 }
    count: integer;                     { +38: the operands }
    opnd: array [1..64] of il_$node_ptr_t;  { +40: from 1 }
  end;

  { A count, size or shift kind of up to 65535 (word parameters that
    are zero-extended and compared unsigned: shift, fill). }
  cg_count_t = 0..65535;

  { A node's words by offset (word k at +2k), for the blocks' fields
    beyond il_$node_t's xw (a routine block's +394, +396 parameter
    classes). }
  cg_words_t = array [0..16383] of integer;
  cg_words_ptr_t = ^cg_words_t;

  { A block's static nesting level, the signed byte at +294 (as
    runbackend.pas's rb_level_t). }
  cg_level_ptr_t = ^cg_level_t;
  cg_level_t = packed record
    pad: packed array [0..293] of char;
    level: -128..127;                   { +294 }
  end;

  { cg_addr's record of what a register holds (+0x120, 16 bytes each):
    obj the node whose value it holds (setresult; a 190 or 189 node's
    object), obj2 a second node with the same value (a variable the
    value was loaded from or stored to), the stamps (cg_addr_2ba) at
    which each was set (w12 obj's, w8 obj2's), its register class, and
    w14 the value's state (0 loaded; 2 not loaded yet: inquire loads
    it from obj when asked; 1 edit_register's mark of a label's
    register whose cached object is gone). }
  cg_reg_t = record
    obj: il_$node_ptr_t;                { +0: setresult's node }
    obj2: il_$node_ptr_t;               { +4 }
    w8: integer;                        { +8: obj2's stamp }
    size: integer;                      { +10: its register class }
    w12: integer;                       { +12: obj's stamp }
    w14: integer;                       { +14: the state }
  end;

  { cg_addr's object cache entries (+0, 8 bytes each): register k is
    the home of variable obj (a register variable of class size). }
  cg_cache_t = record
    obj: il_$node_ptr_t;                { +0 }
    size: integer;                      { +4 }
    load: boolean;                      { +6: load_live_registers loads
                                          obj into the register (and
                                          clears it) }
    live: boolean;                      { +7: the register holds obj's
                                          current value (weight 32767:
                                          not taken for a temporary);
                                          gen_call clears it when a
                                          call's argument may alias the
                                          object (kill_any_param_alias) }
  end;

  { A set of register numbers (0..7 D0-D7, 8..15 A0-A7, 16..23 the
    floating registers): element k is bit k of the longword (`btst'
    with the number in a register).  The callee-saved registers are
    [2..7, 10..13, 18..23]. }
  cg_regset_t = set of 0..31;

  { A routine block's register sets as the code generator keeps them
    (cg_top): +216 the callee-saved registers the routine leaves alone
    (block_entry_proc removes those cg_addr_used marks), +220 those
    its entry saves and its return restores (updatestacksize: the
    callee-saved less +216's), +224 and +228 the frame offsets of the
    saved general and floating registers. }
  cg_blk_regs_ptr_t = ^cg_blk_regs_t;
  cg_blk_regs_t = record
    pad: array [1..54] of integer32;    { +0 }
    unused: cg_regset_t;                { +216 }
    saved: cg_regset_t;                 { +220 }
    save_off: integer32;                { +224 }
    fp_save_off: integer32;             { +228 }
  end;

  { A label's register state (a label node's +64: a node of kind 161,
    264 bytes, or with the floating registers 180, 396 bytes, from
    gspace or runbackend_08's free list (+8 the link); cg_addr's
    merge_state, cg_top's label_proc and cg_misc's show_label): the
    low bytes of cg_addr_next_dreg (+4) and cg_addr_next_areg (+6),
    +7 set when the label is reached, the registers' records as
    cg_addr's table (+8: D0..A7; +268: the floating registers) and
    cg_addr_next_freg (+266). }
  cg_state_ptr_t = ^cg_state_t;
  cg_state_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    b4: char;                           { +4 }
    b5: char;                           { +5 }
    b6: char;                           { +6 }
    b7: boolean;                        { +7 }
    regs: array [0..15] of cg_reg_t;    { +8 }
    w264: integer;                      { +264 }
    w266: integer;                      { +266: cg_addr_next_freg }
    fp_regs: array [16..23] of cg_reg_t;  { +268 }
  end;

  { An IL statement node seen from its +4, as codegen passes it to the
    statement routines (`pea (4,An)': cg_assign's assign_proc): p[k]
    the pointer at node offset 4 + 4k, w[k] the word at 4 + 2k, c[k]
    the byte at 4 + k. }
  cg_stmt_t = record
    case integer of
      1: (p: array [0..63] of il_$node_ptr_t);
      2: (w: array [0..127] of integer);
      3: (c: array [0..255] of char);
  end;

  { An assignment statement (kind 140) seen from its +4, as codegen
    passes it to cg_assign's assign_proc (and cg_tree's generate passes
    multi_assign_proc a record of the same layout in its data, +0x248):
    the statements' chain (+4 the next statement: a register list,
    191, when one follows), the value's descriptor (+48: its size in
    bytes, rlen, w6 and w8 a bit field's offset and width or a shift
    count's class, flags), the destination (+64), the source (+68), a
    third tree walked first (+72: strncpy's count) and the assignment's
    operator (+76: 0 a plain store, 1 add, 2 subtract, 3 and, 4 or, 5
    exclusive or, 6 an aggregate, 7..9 sets, 10 and 12 bit fields, 11 a
    floating store, 13 and 14 the unary operators, 15 and 16 shifts, 19
    .. 22 floating arithmetic, 25 an aggregate of a length, 27 .. 30
    strcat, strcpy, strncat, strncpy; list_tree's names SCALAR ..). }
  cg_asn_t = record
    prev: il_$node_ptr_t;               { +4 }
    next: il_$node_ptr_t;               { +8 }
    unused_12: array [3..11] of integer32;  { +12 }
    desc: cg_desc_t;                    { +48 }
    left: il_$node_ptr_t;               { +64 }
    right: il_$node_ptr_t;              { +68 }
    extra: il_$node_ptr_t;              { +72 }
    asnop: integer;                     { +76 }
  end;

var
  { cg_fp's cells (A5 0x3552F8 + 0x1000..0x1014). }
  cg_fp_1000: extern il_$node_ptr_t;    { +0x1000: f_compare_proc sets it
                                          (cg_tree), cbranch_proc reads
                                          and clears it (cg_top) }
  cg_fp_last_store: extern il_$node_ptr_t;  { +0x1004: the variable the
                                          last floating result was
                                          stored to with the PEB (fp_temp;
                                          check_use against it) }
  cg_fp_result: extern il_$node_ptr_t;  { +0x1008: the node whose value
                                          the floating stack computes
                                          (fp_temp, fop_proc); purge_fp's
                                          setresult }
  cg_fp_in_peb: extern il_$node_ptr_t;  { +0x100C: the variable last
                                          loaded into the PEB's register
                                          (stack_fp) }
  cg_fp_count: extern integer;          { +0x1010: the entries on the
                                          floating stack (cg_assign,
                                          cg_call, cg_top, cg_tree test
                                          it) }
  cg_fp_last_op: extern integer;        { +0x1012: the last operation
                                          pushed (147 when none); a PEB
                                          operation outside a set waits
                                          for the PEB (test_peb_busy) }
  cg_fp_long: extern boolean;           { +0x1014: an operand of size 8
                                          or 12 was stacked: purge_fp
                                          calls the extended library
                                          routine }

  { cg_top's cells (A5 0x356314), defined in cg_top.pas (+0x130, the
    line table, outbin.pas declares itself as cg_top_130). }
  cg_stmt: extern il_$node_ptr_t;       { +0x12C (0x356440): the statement
                                          node being compiled (cg_addr,
                                          cg_assign, cg_tree) }
  cg_code_bytes: extern integer32;      { +0x134 (0x356448): emit's
                                          fnl_slct adds each instruction's
                                          length; codegen gives a routine
                                          past 5000 its own frame for A5
                                          (+375 bit 3) }
  cg_top_13a: extern integer;           { +0x13A (0x35644E): cleared at a
                                          routine's entry, counted up at
                                          a label (label_proc); cg_addr's
                                          allocate_temp keeps it in a
                                          temporary }
  cg_data_reg: extern integer;          { +0x140 (0x356454): the address
                                          register the module's data is
                                          reached through: 13 (A5), 8 (A0)
                                          when the entry copies A0 there
                                          (block_entry_proc); cg_addr's
                                          address, emit's chk_imd }
  cg_pass: extern integer;              { +0x142 (0x356456): the pass over
                                          the routine (codegen counts from
                                          1; show_state prints it, gen_call
                                          tests it for 1) }
  cg_line: extern integer;              { +0x144 (0x356458): the line
                                          being compiled (cgerr's) }
  cg_settled: extern boolean;           { +0x146 (0x35645A): set at each
                                          pass's start, cleared by
                                          cg_addr's merge_register when a
                                          label's state changes; a pass
                                          that leaves it set is followed
                                          by the last one, which emits
                                          (at_backend_506, +0x148) }

  { cg_misc's cell (A5 0x356310). }
  cg_misc_label: extern il_$node_ptr_t; { +0: the label templabel gives
                                          while at_backend_506 is false
                                          (cg_top's f_initialize sets
                                          it) }

  { cg_tree's cells (A5 0x356460). }
  cg_zero_ads: extern codegen_$uads_t;  { +0x188 (0x3565E8): set at run
                                          time; the immediate 0 (cg_misc's
                                          agg_opr gives it for an all-zero
                                          constant, strncpy stores it to
                                          pad, shift ands with it to
                                          clear a word; compared with
                                          it, a test) }
  cg_null_ads: extern codegen_$uads_t;  { +0x1A0 (0x356600): .rwdi sets
                                          f2 and f3 to 31 (no register),
                                          the rest 0: no operand }
  cg_tree_1b4: extern il_$node_ptr_t;   { +0x1B4 (0x356614): a node built
                                          over (stack_fp: an operand's
                                          second longword) }

  { cg_addr's cells (A5 0x354FB8, 0x2BC bytes), defined in cg_addr.pas
    in this order (+0x2A0 and +0x2A4 only cg_addr reads; declared here
    to keep the layout). }
  cg_addr_cache: extern array [0..23] of cg_cache_t;  { +0x0 }
  cg_addr_used: extern array [0..31] of boolean;  { +0xC0: the register
                                          is used in the routine (set by
                                          address_reg, inquire, address;
                                          gen_call after a call that does
                                          not save it); the entry saves
                                          those it must }
  cg_addr_locks: extern array [0..31] of integer;   { +0xE0
                                          (0x355098): a register's lock
                                          count (gen_call adds 1) }
  cg_addr_regs: extern array [0..23] of cg_reg_t;   { +0x120
                                          (0x3550D8); stack_fp tests FP0's
                                          w14 (0x3551E6) for 2 }
  cg_addr_half_blk: extern il_$node_ptr_t;  { +0x2A0 (0x355258): the
                                          routine block whose frame has
                                          the spare word cg_addr_half_disp }
  cg_addr_half_disp: extern integer32;  { +0x2A4 (0x35525C): a word of the
                                          frame left by aligning a
                                          temporary (allocate_temp gives
                                          it to the next one of 2 bytes);
                                          0 none }
  cg_addr_free_temps: extern il_$node_ptr_t;  { +0x2A8 (0x355260): the
                                          temporaries (152 nodes) free for
                                          reuse, through +12; cleared at
                                          a routine's entry
                                          (block_entry_proc) }
  cg_addr_2ac: extern il_$node_ptr_t;   { +0x2AC (0x355264): a node of
                                          kind 181 (cg_top's
                                          f_initialize) }
  cg_addr_2b0: extern cg_regset_t;      { +0x2B0 (0x355268): set to
                                          0..23 at a routine's first pass,
                                          less each basic block's
                                          registers (initialize_tree); an
                                          empty register outside it
                                          weighs 1, not 0 (weight) }
  cg_addr_next_freg: extern integer;    { +0x2B4 (0x35526C): the floating
                                          register get_register tries
                                          first (16..23, round robin);
                                          from a label's state +266 }
  cg_addr_next_areg: extern integer;    { +0x2B6 (0x35526E): the address
                                          register get_register tries
                                          first (8..12); gen_call stores
                                          8 before a call through a
                                          routine variable; from a
                                          label's state +6 }
  cg_addr_next_dreg: extern integer;    { +0x2B8 (0x355270): the data
                                          register get_register tries
                                          first (0..7); from a label's
                                          state +4 }
  cg_addr_2ba: extern integer;          { +0x2BA (0x355272): cleared by
                                          cg_top's initialize; the stamp
                                          setresult and inquire give a
                                          register record (w12, w8) }

{ ---- cg_addr ---- }

{ The headings are checked against cg_addr.pas's bodies (in its
  address order).  Register numbers: 0..7 D0-D7, 8..15 A0-A7, 16..23
  the floating registers, 31 none.  A size is a register class (the
  descriptors' rlen: 1 byte, 2 word, 4 long, 5 address, 6 single, 7
  double, 8 and 12 extended; 0 an address). }

{ SETOBJCACHE - node n (a 190's object and every node of its chain
  through +20, +28) marked as cached in register r unless it is
  already: the flag and the register in the node (+6 bit 10 and +10
  for the trees and references, +32 bit 24 and +74 for a 109
  variable, +24 bit 24 and +16 for a 110).  cg_addr 0x0EF112: 8 a
  pointer, 12 a word. }
procedure setobjcache(
    n: il_$node_ptr_t;
    r: integer); options(val_param); extern;

{ GETOBJCACHE - the register node n is marked as cached in (setobjcache),
  when that register's cache entry holds n, else the first entry that
  does; else the register in the node (31 none).  cg_addr 0x0EF1F2: a
  pointer; D0. }
function getobjcache(
    n: il_$node_ptr_t): integer; options(val_param); extern;

{ SETRESULT - register r holds node n's value (a 190's or 189's object)
  of class size (a long in a data register for an address, an address
  register's class 5): nothing when the register cannot hold that
  class.  cg_addr 0x0EF2BC: 8 a word, 10 a pointer, 14 a word. }
procedure setresult(
    r: integer;
    n: il_$node_ptr_t;
    size: integer); options(val_param); extern;

{ CHECK_USE - whether a and b are the same object (190 and 189 nodes
  taken through +4 and +20).  cg_addr 0x0EF3BA: two pointers; D0. }
function check_use(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): boolean; options(val_param); extern;

{ WEIGHT - the cost of taking register r for something else: 32767 for
  a live register variable, 16001 or 15001 less the uses for a tree's
  or a reference's value, 1 for a constant, else the stamp + 2; the
  larger of the two objects'; 1 for an empty register outside
  cg_addr_2b0.  cg_addr 0x0EF42A: a word; D0 (compared unsigned). }
function weight(
    r: integer): integer; options(val_param); extern;

{ ADDRESS_REG - register r's operand in a (mode 1, or 13 for a floating
  register), marked used.  cg_addr 0x0EF5B0: 8 a word, 10 the
  descriptor's address; 94 call sites. }
procedure address_reg(
    r: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ UNLOCK - operand a's registers (base and index) unlocked (cgerr 28
  for one not locked, but the data register and A7).  cg_addr
  0x0EF600: the descriptor's address. }
procedure unlock(
    in a: codegen_$uads_t); extern;

{ CHK_ASSIGN - the register that is the home of variable n (a 190's
  or 189's object) for class size (the same width; an address
  register exactly for size 5), 31 none.  cg_addr 0x0EF6F8: 8 the node
  (a longword), 12 a word; callers read D0. }
function chk_assign(
    n: il_$node_ptr_t;
    size: integer): integer; options(val_param); extern;

{ REGISTER_TICKLE - whether the current statement (past register
  lists) uses n so that it is worth keeping in a register: a 142 whose
  +56 is n or an add or subtract (12, 40) of n (not a constant 0 unless
  zero_ok), a 140 whose +68 is n; never for a constant 0, a string or
  a node of getphase element 1.  cg_addr 0x0EF7D2: 8 a pointer, 12 a
  byte; D0 (cg_assign's assign_proc, cg_tree). }
function register_tickle(
    n: il_$node_ptr_t;
    zero_ok: boolean): boolean; options(val_param); extern;

{ PEEK - the register holding node n's value of class size (D0: 16..23
  the floating registers, 31 none); for a byte or word of a reference
  (147) the register holding the word or long it is part of.  cg_addr
  0x0EF9C2: 8 the node, 12 a word; callers read D0. }
function peek(
    n: il_$node_ptr_t;
    size: integer): integer; options(val_param); extern;

{ CG_ADDR_$OPERAND_IN_REG_ANY_RLEN - the registers holding node n's
  value live (of any class; with a reference's base variable's), a set
  of register numbers as a longword.  cg_addr 0x0EFCD6: 8 a pointer;
  D0. }
function cg_addr_$operand_in_reg_any_rlen(
    n: il_$node_ptr_t): integer32; options(val_param); extern;

{ LOAD_LIVE_REGISTERS - the register variables marked to be loaded
  (cg_addr_cache's load) loaded and made live.  cg_addr 0x0EFD68: no
  parameters (cg_top's reg_list_proc). }
procedure load_live_registers; extern;

{ INQUIRE - node n's value of class size in a if a register holds it
  (locked and marked used; a value not loaded yet loaded first), else
  a.f1 0; the phase flags in a.f5 and n in a.x.  cg_addr 0x0EFE7E: 8 a
  pointer, 12 a word, 14 the descriptor's address. }
procedure inquire(
    n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ KILL_REGISTER - register r's contents forgotten (r up to 23).
  cg_addr 0x0F00B6: 8 a word; 93 call sites. }
procedure kill_register(
    r: integer); options(val_param); extern;

{ INIT_TEMP - no temporaries free and no spare frame word.  cg_addr
  0x0F00F4: no parameters (cg_top's initialize). }
procedure init_temp; extern;

{ INVALIDATE - the registers holding a value of an object that a's
  object of size bytes may change forgotten (and the floating unit's
  remembered variables).  cg_addr 0x0F011C: 8 the descriptor's address,
  12 a longword. }
procedure invalidate(
    in a: codegen_$uads_t;
    size: integer32); options(val_param); extern;

{ ALLOCATE_TEMP - a temporary (a 152 node: +4 its frame offset, +8 its
  size, +16 owner) of size bytes rounded to even, from the free list
  when reuse, else from the routine's frame.  cg_addr 0x0F0390: 8 a
  longword, 12 a byte, 14 a pointer; the node in A0. }
function allocate_temp(
    size: integer32;
    reuse: boolean;
    owner: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ CG_ADDR_$ADDR_OF_CSE, CG_ADDR_$LOAD_ADDR_OF_CSE - whether the common
  subexpression n (a 190 or 189, or a temporary of one) is an
  address kept, and its address loaded into an address register (the
  value stored in a temporary first), its operand in a.  cg_addr
  0x0F04C6 (the node's address; D0), 0x0F051A (the node's address, the
  descriptor's address). }
function cg_addr_$addr_of_cse(
    in n: il_$node_ptr_t): boolean; extern;

procedure cg_addr_$load_addr_of_cse(
    in n: il_$node_ptr_t;
    out a: codegen_$uads_t); extern;

{ GET_TEMP - tree n's temporary (its opnd[1]: a 152 node allocated
  when it is not one), its value stored there when store.  cg_addr
  0x0F0740: 8 a pointer, 12 a byte. }
procedure get_temp(
    n: il_$node_ptr_t;
    store: boolean); options(val_param); extern;

{ GET_AGG_TEMP - n made a 138 with a temporary.  cg_addr 0x0F09B6: a
  pointer (cg_tree's set_ops, generate). }
procedure get_agg_temp(
    n: il_$node_ptr_t); options(val_param); extern;

{ GET_CHILDS_AGG_TEMP - n made a 138 taking its operand's temporary
  when the operand is a set operation's tree (true), else a temporary
  of its own (false).  cg_addr 0x0F09E4: a pointer; D0 (cg_tree's
  set_range_in_set_proc, set_bit_in_set_proc). }
function get_childs_agg_temp(
    n: il_$node_ptr_t): boolean; options(val_param); extern;

{ RELEASE - operand a's registers unlocked and its nodes' uses counted
  down (a temporary freed at 0).  cg_addr 0x0F0AEA: the descriptor's
  address. }
procedure release(
    in a: codegen_$uads_t); extern;

{ GET_REGISTER - a register of class size for node n (nil: a scratch
  register; a 190's or 189's object): its home when free, else the
  lightest (weight) of the class, round robin; locked, its operand in
  a, holding n (setresult, setobjcache).  cg_addr 0x0F0C5A: 8 a
  pointer, 12 a word, 14 the descriptor's address. }
procedure get_register(
    n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ GET_TEMP_REGISTER - get_register for node n, or a scratch register
  when a register is n's live home.  cg_addr 0x0F0E42: 8 a pointer, 12
  a word, 14 the descriptor's address. }
procedure get_temp_register(
    n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ LOAD_OPERAND - node n's value of class size in a register, its
  operand in a.  cg_addr 0x0F0EA4: 8 a longword, 12 a word, 14 the
  descriptor's address. }
procedure load_operand(
    n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ LOAD_ADDRESS - node n's address in an address register, its operand
  in a.  cg_addr 0x0F1050: two pointers (the second a descriptor). }
procedure load_address(
    n: il_$node_ptr_t;
    out a: codegen_$uads_t); options(val_param); extern;

{ LOAD_MODIFIABLE - node n's value of class size (5 its address) in a
  register that may be changed, its operand in a.  cg_addr 0x0F11A8: 8
  the node's address, 12 the size's (load_dindex passes a constant),
  16 the descriptor's address. }
procedure load_modifiable(
    in n: il_$node_ptr_t;
    in size: integer;
    out a: codegen_$uads_t); extern;

{ CHK_ADDR - the register (A4 down to D0) whose live temporary holds
  node n's address (a 138 of operator 26), 31 none, its operand in a.
  cg_addr 0x0F18F4: 8 a pointer, 12 the descriptor's address; D0. }
function chk_addr(
    n: il_$node_ptr_t;
    out a: codegen_$uads_t): integer; options(val_param); extern;

{ ADDRESS - the operand of node n (size: its class, 0 its address) in
  a.  cg_addr 0x0F197E: 8 the node (a longword), 12 a word, 14 the
  descriptor's address; 264 call sites. }
procedure address(
    n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ LOAD_RESULT, LOAD_FP_RESULT - one of tree n's operands (1..k, or
  operand -k alone) loaded into a register for the result (a data or
  address register; a floating register), preferring one already in
  a register that may be changed, its operand in a, the tree's value
  (setresult, setobjcache).  cg_addr 0x0F226C, 0x0F2780: 8 a pointer,
  12 a word, 14 the descriptor's address (cg_tree's generate, ...). }
procedure load_result(
    n: il_$node_ptr_t;
    k: integer;
    out a: codegen_$uads_t); options(val_param); extern;

procedure load_fp_result(
    n: il_$node_ptr_t;
    k: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ ANYCONST - the operand of constant value of size size in a (a
  register holding it, or one holding a wider constant of the same
  low bytes, else the immediate).  cg_addr 0x0F26BA: 8 a longword, 12
  a word, 14 the descriptor's address; 62 call sites. }
procedure anyconst(
    value: integer32;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ MERGE_STATE - the register state at label lab merged with the
  current one (its state saved at the label's first branch).  cg_addr
  0x0F2BA8: a pointer by value. }
procedure merge_state(
    lab: il_$node_ptr_t); options(val_param); extern;

{ CG_ADDR_$MERGE_STATE_OF_ASSIGNED_GOTO_TARGETS - merge_state for every
  label a goto through a label variable (statement n) may reach.
  cg_addr 0x0F2D50: a pointer by value. }
procedure cg_addr_$merge_state_of_assigned_goto_targets(
    n: il_$node_ptr_t); options(val_param); extern;

{ CG_ADDR_$INIT_REGS - every register's contents forgotten (keep: the
  data and address registers kept, only the floating registers
  forgotten; cg_top passes true for -FRND...).  cg_addr 0x0F2EAA: a
  boolean by address (cg_top passes the constants at 0x0FBE62 and
  0x0FEFB6). }
procedure cg_addr_$init_regs(
    in keep: boolean); extern;

{ EDIT_REGISTER - register r's record from a label's state reg
  checked against what is still valid.  cg_addr 0x0F2F6C: 8 a word,
  10 the record's address. }
procedure edit_register(
    r: integer;
    in out reg: cg_reg_t); options(val_param); extern;

{ ---- cg_assign ---- }

{ The headings are checked against cg_assign.pas's bodies. }

{ CG_ASN_$INLINE_MOVE_IS_BEST - whether count moves inline take no
  more than half again a loop's code (the unit size is passed but not
  read).  cg_assign 0x0F30AE: 8 a longword, 12 a word; D0 (reg_save's
  registers_consumed_by_agg_aop, agg_assign_proc). }
function cg_asn_$inline_move_is_best(
    count: integer32;
    size: integer): boolean; options(val_param); extern;

{ CG_ASN_$BLOCK_MOVE - a loop moving count units of size from src to
  dst (r1 and r2 the loop's counter register and label, agg_loop_start's).
  cg_assign 0x0F30FA: 8 a longword, 12 a word, then four descriptors'
  addresses. }
procedure cg_asn_$block_move(
    count: integer32;
    size: integer;
    in out src: codegen_$uads_t;
    in out dst: codegen_$uads_t;
    in out r1: codegen_$uads_t;
    in out r2: codegen_$uads_t); options(val_param); extern;

{ FAULT_FREE_ASSIGN - a move of size size from src to dst (src copied
  first, as a value parameter is).  cg_assign 0x0F36F4: 8 a word, 10
  and 14 the descriptors' addresses. }
procedure fault_free_assign(
    size: integer;
    in out dst: codegen_$uads_t;
    in out src: codegen_$uads_t); options(val_param); extern;

{ MULTI_ASSIGN_PROC - a store of s's source to its destination: an
  aggregate's moves past 4 bytes (agg_assign_proc), else one move.
  cg_assign 0x0F3F28: the record's address (cg_tree's generate passes
  its data +0x248). }
procedure multi_assign_proc(
    in out s: univ cg_asn_t); extern;

{ ASSIGN_PROC - the code of an assignment statement s (node kind 140,
  passed from its +4).  cg_assign 0x0F469E: the address. }
procedure assign_proc(
    in out s: univ cg_asn_t); extern;

{ ---- cg_top ---- }

{ UPDATEREGASSIGN - cg_top's saved object cache entries (reg_list_proc's,
  for a register list before an assignment) put back into cg_addr's
  cache.  cg_top 0x0FBC5E: no parameters (cg_assign's assign_proc). }
procedure updateregassign; extern;

{ ---- cg_call ---- }

{ CG_CALL_$IS_PROC_VAR_CALL - the routine designator n is called
  through a variable (147, 146, a routine variable 107/108, a 171 of a
  non-routine, 175).  cg_call 0x0F6912: the node's address (reg_save's
  registers_consumed_by_tree_operator passes a tree's opnd[1]); D0. }
function cg_call_$is_proc_var_call(
    in n: il_$node_ptr_t): boolean; extern;

{ GEN_CALL - the call of node n (nil: of routine rtn, a library
  routine with its arguments already pushed).  cg_call 0x0F720A: two
  pointers. }
procedure gen_call(
    n: il_$node_ptr_t;
    rtn: il_$node_ptr_t); options(val_param); extern;

{ ---- cg_fp ---- }

{ INIT_PEB - no PEB operation pending.  cg_fp 0x0F8904: no parameters
  (cg_top's initialize and label_proc). }
procedure init_peb; extern;

{ FP_RLEN - the register class of descriptor d for operand k (1 or 2:
  w6 or w8 when set, else rlen).  cg_fp 0x0F8926: 8 the descriptor's
  address, 12 a word; D0. }
function fp_rlen(
    in d: cg_desc_t;
    k: integer): integer; options(val_param); extern;

{ TEST_PEB_BUSY - code waiting while the PEB is busy.  cg_fp 0x0F8976:
  no parameters (cg_addr's get_temp and address). }
procedure test_peb_busy; extern;

{ PURGE_FP - the floating stack's operations generated (a library call
  through std_lib, or the PEB's registers).  cg_fp 0x0F8A0E: no
  parameters; 38 call sites. }
procedure purge_fp; extern;

{ STACK_FP - floating operation op of size size on operand n stacked,
  or done at once with the PEB or the 68881.  cg_fp 0x0F90EE: 8 and 10
  words, 12 a pointer; 34 call sites. }
procedure stack_fp(
    op: integer;
    size: integer;
    n: il_$node_ptr_t); options(val_param); extern;

{ FP_TEMP - node n's floating value (its temporary t) kept: the stack's
  result, or stored.  cg_fp 0x0F955E: two pointers. }
procedure fp_temp(
    n: il_$node_ptr_t;
    t: il_$node_ptr_t); options(val_param); extern;

{ FOP_PROC - the floating operation of tree node n: its operands
  stacked (the second operation op2 when the operands are taken in
  the other order), then the operation op1.  cg_fp 0x0F95FA: 8 a
  pointer, 12 and 14 words (cg_tree's generate). }
procedure fop_proc(
    n: il_$node_ptr_t;
    op1: integer;
    op2: integer); options(val_param); extern;

{ ---- cg_misc ---- }

{ SHOW_STATE, SHOW_LABEL - the register state, and label lab with its
  saved state, listed (debugging dumps).  cg_misc 0x0F973C (no
  parameters), 0x0F99EC (a pointer). }
procedure show_state; extern;

procedure show_label(
    lab: il_$node_ptr_t); options(val_param); extern;

{ AGG_LEN_LOOP_START - the head of a loop over an aggregate of the
  length operand a addresses (the word moved to register r, plus 1,
  shifted left 2), its label in lab.  cg_misc 0x0F9DB8: a's address (copied:
  a value parameter), r's and lab's addresses. }
procedure agg_len_loop_start(
    a: codegen_$uads_t;
    in out r: codegen_$uads_t;
    in out lab: codegen_$uads_t); extern;

{ AGG_LOOP_START, AGG_LOOP_END - the head and the end of a loop of
  count iterations (`dbf' up to 65535, else a long count) in register
  r, its label in lab.  cg_misc 0x0F9EB2, 0x0F9F4A: 8 a longword, 12
  and 16 the descriptors' addresses. }
procedure agg_loop_start(
    count: integer32;
    in out r: codegen_$uads_t;
    in out lab: codegen_$uads_t); options(val_param); extern;

procedure agg_loop_end(
    count: integer32;
    in out r: codegen_$uads_t;
    in out lab: codegen_$uads_t); options(val_param); extern;

{ GENMASK - a mask of the bits lo + 1 .. n, set up to hi (from the
  most significant).  cg_misc 0x0FA012: three words; D0 a longword. }
function genmask(
    lo: integer;
    hi: integer;
    n: integer): integer32; options(val_param); extern;

{ SHIFT - operand a of size size shifted by count (how, emit's x: 0
  arithmetic right, 2 logical right, 1 and 3 left, as its forms for
  16 and for 1 show).  cg_misc 0x0FA050: 8 the descriptor's address,
  12, 14, 16 words (count and how zero-extended, compared unsigned). }
procedure shift(
    in out a: codegen_$uads_t;
    size: integer;
    count: cg_count_t;
    how: cg_count_t); options(val_param); extern;

{ AGG_OPR - the operand of aggregate node n for a block operation: the
  immediate 0 or a replicated byte for a constant of identical bytes,
  else its address in an address register as (An)+.  cg_misc 0x0FA27E:
  8 a pointer, 12 the descriptor's address (cg_assign's agg_assign_proc,
  cg_tree's agg_compare_proc). }
procedure agg_opr(
    n: il_$node_ptr_t;
    out a: codegen_$uads_t); options(val_param); extern;

{ FILL - len bytes at node n's address set to value.  cg_misc 0x0FA410:
  8 a pointer, 12 a longword, 16 a word (compared unsigned; cg_tree's
  generate). }
procedure fill(
    n: il_$node_ptr_t;
    value: integer32;
    len: cg_count_t); options(val_param); extern;

{ CBUILTIN_STRCPY, CBUILTIN_STRNCPY, CBUILTIN_STRCAT, CBUILTIN_STRNCAT -
  the inline code of the string builtin of tree n (byte loops; the
  operands at +60, +64 and the count at +68).  cg_misc 0x0FA580,
  0x0FA67C, 0x0FA95A, 0x0FAAFC: a pointer (cg_assign's assign_proc). }
procedure cbuiltin_strcpy(
    n: il_$node_ptr_t); options(val_param); extern;

procedure cbuiltin_strncpy(
    n: il_$node_ptr_t); options(val_param); extern;

procedure cbuiltin_strcat(
    n: il_$node_ptr_t); options(val_param); extern;

procedure cbuiltin_strncat(
    n: il_$node_ptr_t); options(val_param); extern;

{ CBUILTIN_STRLEN, CBUILTIN_STRCMP, CBUILTIN_STRNCMP - the inline code
  of the string builtin of tree n (its operands opnd[1..3]), its value
  left in a data register (setresult).  cg_misc 0x0FAD8A, 0x0FB42C,
  0x0FB7D6: a pointer (cg_tree's generate). }
procedure cbuiltin_strlen(
    n: il_$node_ptr_t); options(val_param); extern;

procedure cbuiltin_strcmp(
    n: il_$node_ptr_t); options(val_param); extern;

procedure cbuiltin_strncmp(
    n: il_$node_ptr_t); options(val_param); extern;

{ CG_MISC_$STRCMP_CAN_USE_LONGS - neither string operand of the strcmp
  tree n may be unaligned.  cg_misc 0x0FAEF0: a pointer; D0
  (reg_save's registers_consumed_by_tree_operator, cbuiltin_strcmp). }
function cg_misc_$strcmp_can_use_longs(
    n: il_$node_ptr_t): boolean; options(val_param); extern;

{ REVERSE_CC - the opposite condition of cc.  cg_misc 0x0F9BEE: a word;
  D0. }
function reverse_cc(
    cc: integer): integer; options(val_param); extern;

{ UNALIGNED - node n's storage may be at an odd address.  cg_misc
  0x0F9C16: a longword; D0. }
function unaligned(
    n: il_$node_ptr_t): boolean; options(val_param); extern;

{ ZERO_CHECK - node n is the integer constant 0.  cg_misc 0x0F9CD0: a
  pointer; D0. }
function zero_check(
    n: il_$node_ptr_t): boolean; options(val_param); extern;

{ TEMPLABEL - a new temporary label node.  cg_misc 0x0F9BC8: no
  parameters, the node in A0; 48 call sites. }
function templabel: il_$node_ptr_t; extern;

{ S_EXTEND - operand a sign-extended from size from to size too.
  cg_misc 0x0F9D24: 8 the descriptor's address, 12 and 14 words. }
procedure s_extend(
    in out a: codegen_$uads_t;
    from: integer;
    too: integer); options(val_param); extern;

{ ---- cg_tree ---- }

{ The headings are checked against cg_tree.pas's bodies. }

{ CG_TREE_$NEEDS_LIB_SUPPORT - whether floating tree t needs a library
  routine, rtn its index in std_lib_rtns (176 none).  cg_tree 0x0FF0AA:
  t and rtn by address (reg_save's registers_consumed_by_tree_operator
  passes its parameter's slot); D0. }
function cg_tree_$needs_lib_support(
    in t: il_$node_ptr_t;
    out rtn: integer): boolean; extern;

{ CG_TREE_$IS_DECOMPOSABLE_CONST_MUL - n is a multiplication by a
  constant done by shifts and adds.  cg_tree 0x10061E: a pointer
  (reg_save's registers_consumed_by_tree_operator); D0. }
function cg_tree_$is_decomposable_const_mul(
    n: il_$node_ptr_t): boolean; options(val_param); extern;

{ TREE_WALK - the code of IL tree n.  cg_tree 0x1085B4: a pointer. }
procedure tree_walk(
    n: il_$node_ptr_t); options(val_param); extern;

{ WALKER - the code of a comparison tree n whose condition a branch
  tests (cg_top's cbranch_proc for a 143).  cg_tree 0x108484: a
  pointer. }
procedure walker(
    n: il_$node_ptr_t); options(val_param); extern;

{ ---- reg_save ---- }

{ REG_SAVE - the registers a call of routine r preserves (a set of
  register numbers as a longword).  reg_save 0x0ED478: a pointer; D0. }
function reg_save(
    r: il_$node_ptr_t): integer32; options(val_param); extern;

{ ---- the front end ---- }

{ PASS_CHAR_LEN_DIFF - whether character lengths are passed apart (C:
  false).  frontend_cc_dummies 0x067408: the routine node's address
  (gen_call passes the address of its local); D0. }
function pass_char_len_diff(
    in r: univ il_$node_ptr_t): boolean; extern;

{ ---- emit ---- }

{ EMIT_LINE_EOP - a line number cell for line (a and b: the routine
  or block whose line it is, or no operand).  emit 0x0B79DE: 8 and 12
  the descriptors' addresses, 16 a word. }
procedure emit_line_eop(
    in a: codegen_$uads_t;
    in b: codegen_$uads_t;
    line: integer); options(val_param); extern;

{ EMIT_ASSIGN - a move of size size from src to dst (FPA1).  emit
  0x0B7F54: 8 a word, 10 and 14 the descriptors' addresses. }
procedure emit_assign(
    size: integer;
    in out dst: codegen_$uads_t;
    in out src: codegen_$uads_t); options(val_param); extern;

{ EMIT - a code cell of instruction op (the generic instruction:
  fnl_slct picks the machine instruction from op and size) on operands
  dst and src, with x.  emit 0x0B78C0: 8 and 10 words, 12 and 16 the
  descriptors' addresses, 20 a longword; 520 call sites. }
procedure emit(
    op: integer;
    size: integer;
    in dst: codegen_$uads_t;
    in src: codegen_$uads_t;
    x: integer32); options(val_param); extern;
