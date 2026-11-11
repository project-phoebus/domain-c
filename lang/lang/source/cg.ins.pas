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

  { cg_top's cells. }
  cg_line: extern integer;              { +0x144 (0x356458): the line
                                          being compiled (cgerr's) }

  { cg_tree's cells (A5 0x356460). }
  cg_tree_188: extern codegen_$uads_t;  { +0x188 (0x3565E8): set at run
                                          time; the PEB's status operand
                                          (test_peb_busy) }
  cg_null_ads: extern codegen_$uads_t;  { +0x1A0 (0x356600): .rwdi sets
                                          f2 and f3 to 31 (no register),
                                          the rest 0: no operand }
  cg_tree_1b4: extern il_$node_ptr_t;   { +0x1B4 (0x356614): a node built
                                          over (stack_fp: an operand's
                                          second longword) }

  { cg_addr's cells (A5 0x354FB8). }
  cg_addr_22e: extern integer;          { +0x22E (0x3551E6): stack_fp
                                          tests it for 2 when peek finds
                                          a value in FP0 (register 16) }

{ ---- cg_addr ---- }

{ ADDRESS - the operand of node n (size: its class, 0 its address) in
  a.  cg_addr 0x0F197E: 8 the node (a longword), 12 a word, 14 the
  descriptor's address; 264 call sites. }
procedure address(
    n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ ADDRESS_REG - register r's operand in a.  cg_addr 0x0EF5B0: 8 a word,
  10 the descriptor's address; 94 call sites. }
procedure address_reg(
    r: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ KILL_REGISTER - register r's contents forgotten.  cg_addr 0x0F00B6:
  8 a word; 93 call sites. }
procedure kill_register(
    r: integer); options(val_param); extern;

{ RELEASE, UNLOCK - operand a's registers released or unlocked.
  cg_addr 0x0F0AEA, 0x0EF600: the descriptor's address. }
procedure release(
    in out a: codegen_$uads_t); extern;

procedure unlock(
    in out a: codegen_$uads_t); extern;

{ CHK_ASSIGN, PEEK - the register holding node n's value of size size
  (D0: 16..23 the floating registers).  cg_addr 0x0EF6F8, 0x0EF9C2: 8
  the node, 12 a word; callers read D0. }
function chk_assign(
    n: il_$node_ptr_t;
    size: integer): integer; options(val_param); extern;

function peek(
    n: il_$node_ptr_t;
    size: integer): integer; options(val_param); extern;

{ CHECK_USE - whether a and b are the same object (190 and 189 nodes
  taken through +4 and +20).  cg_addr 0x0EF3BA: two pointers; D0. }
function check_use(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): boolean; options(val_param); extern;

{ INVALIDATE - the registers holding a's object of size size
  forgotten.  cg_addr 0x0F011C: 8 the descriptor's address, 12 a
  longword. }
procedure invalidate(
    in a: codegen_$uads_t;
    size: integer32); options(val_param); extern;

{ SETRESULT - register r holds node n's value of size size.  cg_addr
  0x0EF2BC: 8 a word, 10 a pointer, 14 a word. }
procedure setresult(
    r: integer;
    n: il_$node_ptr_t;
    size: integer); options(val_param); extern;

{ LOAD_ADDRESS - node n's address loaded into an address register,
  its operand in a.  cg_addr 0x0F1050: two pointers (the second a
  descriptor). }
procedure load_address(
    n: il_$node_ptr_t;
    out a: codegen_$uads_t); options(val_param); extern;

{ INQUIRE - node n's operand of size size in a if it is in a register
  (a.f1 0 when not).  cg_addr 0x0EFE7E: 8 a pointer, 12 a word, 14 the
  descriptor's address. }
procedure inquire(
    n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ LOAD_OPERAND - node n's value of size size loaded into a register,
  its operand in a.  cg_addr 0x0F0EA4: 8 a longword, 12 a word, 14 the
  descriptor's address. }
procedure load_operand(
    n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); extern;

{ GET_TEMP - a temporary for node n (a 138 node).  cg_addr 0x0F0740: 8
  a pointer, 12 a byte. }
procedure get_temp(
    n: il_$node_ptr_t;
    b: boolean); options(val_param); extern;

{ ---- cg_call ---- }

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

{ TEMPLABEL - a new temporary label node.  cg_misc 0x0F9BC8: no
  parameters, the node in A0; 48 call sites. }
function templabel: il_$node_ptr_t; extern;

{ S_EXTEND - operand a sign-extended from size from to size too.
  cg_misc 0x0F9D24: 8 the descriptor's address, 12 and 14 words. }
procedure s_extend(
    in out a: codegen_$uads_t;
    from: integer;
    too: integer); options(val_param); extern;

{ ---- emit ---- }

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
