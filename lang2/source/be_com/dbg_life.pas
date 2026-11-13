{ dbg_life - the DBG_LIFE phase of the PRISM back end (at_backend's
  phase table entry 17): after the assembler has laid the code out,
  where each source variable lives over the routine's code, for the
  debugger (-DBS and -DBA only: cargs_$options.db >= 2).

  A variable (an IL VAR_NAME, kind 109, or a FORTRAN symbol, kind 110:
  a live range's node20) may be in a register over some locations and
  in a spill slot (a stack frame temporary the register allocator
  made, its node's +74 the slot's number) over others.  The phase
  numbers the spill slots after the routine's complex live ranges in a
  new set of bit vectors (bv_$initialize_bit_vectors with seven
  vectors a block, the dumps' names: EXPOSED_USE +90, LIVE_ON_ENTRY
  +94, NOT_KILLED +110, LIVE_ON_EXIT +86, GEN_LOCAL +130,
  AVAIL_ON_ENTRY +122, AVAIL_ON_EXIT +126), computes from the
  instructions (writes of registers, spill loads and stores, the
  registers a call clobbers) which values are live and which still
  available on entry to each block (dbg_life_$initialize), then walks
  the code opening and closing a pc range for each register's and each
  slot's variable (dbg_life_$find_symbols), and finally turns the
  ranges into one debug record for each home of each variable,
  chained from the variable's node (dbg_life_$compact; arguments in
  memory get one AP-relative record covering the whole routine,
  dbg_life_$mark_ap_relative_vars).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x22C638  spill_find_next (internal)
    --------  0x22C6AE  is_spill_instruction (internal)
    --------  0x22C804  underlying_spill_location (internal)
    --------  0x22C82A  loc_after (internal)
    --------  0x22C864  instr_is_pmove (internal)
    --------  0x22C894  interesting_variable (internal)
    --------  0x22C8D4  initialize_not_killed_array (in dbg_life_$initialize)
    --------  0x22C938  fill_not_killed_sets (in dbg_life_$initialize)
    --------  0x22CB0A  write_spilled_var (in dbg_life_$initialize)
    --------  0x22CB6C  read_spilled_var (in dbg_life_$initialize)
    --------  0x22CBCC  kill_spilled_var (in dbg_life_$initialize)
    --------  0x22CC30  write_register (in dbg_life_$initialize)
    --------  0x22CD24  dbg_life_$initialize (internal)
    --------  0x22D32A  dbg_life_$close_pc_range (internal)
    --------  0x22D38A  dbg_life_$close_spill_pc_range (internal)
    --------  0x22D3D0  dbg_life_$close_all_pc_ranges (internal)
    --------  0x22D470  dbg_life_$open_pc_range (internal)
    --------  0x22D610  map_physical_to_virtual_lr
    --------  0x22D7E8  dbg_life_$find_symbols (internal)
    --------  0x22DF2A  add_live_range (in dbg_life_$compact)
    --------  0x22DFF8  dbg_life_$compact (internal)
    --------  0x22E16C  dbg_life_$mark_ap_relative_vars (internal)
    --------  0x22E2BC  dbg_life_$process_routine
    --------  0x22E562  dbg_life_$end_routine
    A5 0x485FA0: the module's data (0xD4 bytes): the phase's heap (+0,
    the pc ranges), the spill slots' and the live ranges' words in the
    vectors (+28, +32), the live ranges that have pc ranges (+36,
    chained through their next), the spill slots' records (+40), the
    open ranges by register (+44 floating, +48 integer) and the masks
    of the bits from k up (+56, initialized).  +20..+27 and +52..+55
    are not referenced (declared, to keep the offsets), nor is
    +184..+211.

  This unit opens the lang prelude (its .blocks list: globals.ins.pas
  and its members), so cargs_$options and the IL node types are
  reached directly (the launch notes said otherwise: docs/questions.md
  174 does not apply here).  The live ranges' and the IL nodes' fields
  the phase keeps its data in are read through unit-local views
  (dbg_lr_t, dbg_sym_t, dbg_rtn_t, dbg_conv_t): batch A owns lr_t and
  rtn_t.

  After the ASM phase an operand's +0 is its register and its +8 its
  live range (asm.pas); the condition code and floating registers a
  call clobbers follow its operands (+44 + 12n: floating 32..63, 0..31,
  integer).

  Not known from the original: every local, parameter, type and module
  variable name; the views' field names. }
module dbg_life;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';

type
  { A pc range (12 bytes, from the module's heap): the locations
    [start, stop) over which a register or a slot holds a variable. }
  dbg_range_ptr_t = ^dbg_range_t;
  dbg_range_t = record
    next: dbg_range_ptr_t;              { +0 }
    start: integer32;                   { +4 }
    stop: integer32;                    { +8 }
  end;

  { A variable's debug record (gspace, 20 bytes and 8 for each range),
    chained from its node (+68 of a VAR_NAME, +54 of a FORTRAN symbol):
    where it is over its ranges.  slot_sym the spill slot's node (nil
    for a register), offset its AP-relative offset (an argument in
    memory), kind the register's file (0 integer, 1 floating, 2 a
    floating pair), reg the register, mode 1 for a variable of storage
    class 5 in a register or slot, 2 AP-relative, 3 AP-relative of
    class 5. }
  dbg_pair_t = record
    start: integer32;
    stop: integer32;
  end;
  dbg_rec_ptr_t = ^dbg_rec_t;
  dbg_rec_t = record
    next: dbg_rec_ptr_t;                { +0 }
    slot_sym: univ_ptr;                 { +4 }
    offset: integer32;                  { +8 }
    f12: packed record                  { +12 }
      kind: 0..255;
      reg: 0..63;                       { +13 .7..2 }
      mode: 0..3;                       { .1..0 }
      end;
    space14: array [14..17] of char;
    count: integer;                     { +18 }
    ranges: array [1..4096] of dbg_pair_t;   { +20 }
  end;

  { The fields of an IL node of a variable the phase reads and keeps
    its data in: a VAR_NAME (109; flags +32: bit 29 a spill slot, bit
    14 not of interest to the debugger) or a FORTRAN symbol (110; flags
    +24).  var_of the variable a slot (a VAR_NAME) was made for; slot
    its number; last_bb the block the phase last saw it written in;
    spills its slots' records; dbg its debug records; class its storage
    class (5 is noted in the debug records); offset its address. }
  dbg_sym_ptr_t = ^dbg_sym_t;
  dbg_spill_ptr_t = ^dbg_spill_t;
  dbg_flags_t = set of 0..31;
  dbg_sym_t = record
    unused_0: integer;                  { +0 }
    kind: il_$kind_t;                   { +2 }
    case integer of
      1: (v_space4: array [4..27] of char;
          var_of: dbg_sym_ptr_t;        { +28 }
          vflags: dbg_flags_t;          { +32 }
          v_space36: array [36..55] of char;
          voffset: integer32;           { +56 }
          vlast_bb: bb_ptr_t;           { +60 }
          vspills: dbg_spill_ptr_t;     { +64 }
          vdbg: dbg_rec_ptr_t;          { +68 }
          vclass: integer;              { +72 }
          vslot: integer);              { +74 }
      2: (f_space4: array [4..9] of char;
          f10: packed record            { +10 }
            b10: 0..255;
            fclass: 0..15;              { +11 .7..4 }
            b11_3_0: 0..15;
            end;
          foffset: integer32;           { +12 }
          fslot: integer;               { +16 }
          f_space18: array [18..23] of char;
          fflags: dbg_flags_t;          { +24 }
          f_space28: array [28..35] of char;
          flast_bb: bb_ptr_t;           { +36 }
          f_space40: array [40..49] of char;
          fspills: dbg_spill_ptr_t;     { +50 }
          fdbg: dbg_rec_ptr_t);         { +54 }
  end;

  { A spill slot's record (28 bytes, one for each slot: A5+40, from 1):
    the slot's node, the variable in it, the next slot of the variable,
    the slot's number, its pc ranges (first, the one being extended),
    and +24: the register file's operand kind (the register spilled),
    the ranges' count, whether a range is open. }
  dbg_spill_t = record
    sym: dbg_sym_ptr_t;                 { +0 }
    var_sym: dbg_sym_ptr_t;             { +4 }
    next: dbg_spill_ptr_t;              { +8 }
    slot: integer32;                    { +12 }
    first: dbg_range_ptr_t;             { +16 }
    current: dbg_range_ptr_t;           { +20 }
    f24: packed record                  { +24 }
      kind: 0..31;                      { .31..27 }
      count: 0..65535;                  { .26..11 }
      open: boolean;                    { .10 }
      b9_0: 0..1023;
      end;
  end;
  dbg_spills_ptr_t = ^dbg_spills_t;
  dbg_spills_t = array [1..10000] of dbg_spill_t;
  dbg_longs_ptr_t = ^dbg_longs_t;
  dbg_longs_t = array [1..70000] of integer32;

  { batch A's lr_t where the phase keeps its data: kind (+8, a byte:
    the operand kind of its register, set on the live ranges
    map_physical_to_virtual_lr makes; lr_t's l8), the first and the
    current of its pc ranges (+44, +48: l44, l48) and their count (+72:
    lr_t's exposed). }
  dbg_lr_ptr_t = ^dbg_lr_t;
  dbg_lr_t = record
    space0: array [0..7] of char;
    kind: char;                         { +8 }
    space9: array [9..43] of char;
    first: dbg_range_ptr_t;             { +44 }
    current: dbg_range_ptr_t;           { +48 }
    space52: array [52..71] of char;
    nranges: integer32;                 { +72 }
  end;

  { A routine's arguments (its calling conventions: rtn +16, and the
    routine's IL node's +128): nargs (+22) and, from +60 + 26, a record
    for each: w0 (nonzero: not one), sym its node, loc where it is
    passed (arg_loc_t, a byte), reg its register, flag (an argument in
    memory with it set has no AP-relative record). }
  dbg_arg_t = record
    w0: integer;                        { +0 }
    space2: array [2..5] of char;
    sym: dbg_sym_ptr_t;                 { +6 }
    space10: array [10..11] of char;
    loc: char;                          { +12 }
    space13: array [13..16] of char;
    reg: char;                          { +17 }
    flag: boolean;                      { +18 }
    space19: array [19..25] of char;
  end;
  dbg_conv_ptr_t = ^dbg_conv_t;
  dbg_conv_t = record
    space0: array [0..21] of char;
    nargs: integer;                     { +22 }
    space24: array [24..59] of char;
    args: array [0..255] of dbg_arg_t;  { +60 }
  end;

  { batch A's rtn_t where it has not named what the phase reads: the
    arguments (+16: the routine's calling conventions), the stack
    frame's live range (+116) and the stack frame's register (+208,
    dmp's sf_reg). }
  dbg_rtn_ptr_t = ^dbg_rtn_t;
  dbg_rtn_t = record
    space0: array [0..15] of char;
    conv: dbg_conv_ptr_t;               { +16 }
    space20: array [20..115] of char;
    sf_lr: lr_ptr_t;                    { +116 }
    space120: array [120..207] of char;
    sf_reg: integer;                    { +208 }
  end;

  { The registers a call clobbers, after its operands (+44 + 12n). }
  dbg_clob_ptr_t = ^dbg_clob_t;
  dbg_clob_t = record
    fp_hi: bv_word_t;                   { +0: 32..63 }
    fp_lo: bv_word_t;                   { +4: 0..31 }
    ip: bv_word_t;                      { +8 }
  end;

  { lir's physical live ranges by register (lir_4090, lir_3f90). }
  dbg_phys_ptr_t = ^dbg_phys_t;
  dbg_phys_t = array [0..63] of lr_ptr_t;

  { The open pc ranges by register. }
  dbg_open_ptr_t = ^dbg_open_t;
  dbg_open_t = array [0..63] of dbg_range_ptr_t;

  { The not-killed vectors by register (dbg_life_$initialize). }
  dbg_vecs_t = array [0..63] of bv_ptr_t;
  dbg_vecs_ptr_t = ^dbg_vecs_t;

var
  dl_heap: mrh_$heap_t;                 { +0: the pc ranges }
  dl_14: integer32;                     { +20: not referenced }
  dl_18: integer32;                     { +24: not referenced }
  dl_spill_words: integer32;            { +28: the spill slots' words in
                                          a vector }
  dl_lr_words: integer32;               { +32: the complex live ranges'
                                          words, before the slots' }
  dl_lrs: lr_ptr_t;                     { +36: the live ranges that have
                                          pc ranges (chained through
                                          their next) }
  dl_spills: dbg_spills_ptr_t;          { +40 }
  dl_fp_open: dbg_open_ptr_t;           { +44: 64 }
  dl_ip_open: dbg_open_ptr_t;           { +48: 32 }
  dl_34: integer32;                     { +52: not referenced }
  dl_masks: array [0..31] of bv_word_t := [   { +56: bits k..31 }
    [0..31], [1..31], [2..31], [3..31], [4..31], [5..31], [6..31],
    [7..31], [8..31], [9..31], [10..31], [11..31], [12..31], [13..31],
    [14..31], [15..31], [16..31], [17..31], [18..31], [19..31],
    [20..31], [21..31], [22..31], [23..31], [24..31], [25..31],
    [26..31], [27..31], [28..31], [29..31], [30..31], [31]];

{ spill_find_next - the next spill slot after k whose bit is set in v
  (a vector's slot words), or 0.

  0x22C638, 0x76 bytes, internal: rtn (not read), v and k (a word) by
  value; D0 a word.  The word of bit k + 1 against dl_spill_words
  (`cmp.l (28,A5)'), its bits from k + 1 up by the mask (`move.l
  (0x38,A5,D3.w)'; `and.l'), then the next nonzero words; the bit
  found from the low end (`btst D2,D5' upward). }

function spill_find_next(
    rtn: rtn_ptr_t;
    v: bv_ptr_t;
    k: integer): integer; options(val_param); internal;
label
  99;
var
  i, w, b: integer;
  bits: bv_word_t;
begin
  i := k + 1;
  w := i div 32;
  if w >= dl_spill_words then
    goto 99;
  b := i mod 32;
  bits := dl_masks[b] * v^[w];
  if bits = [] then begin
    repeat
      w := w + 1;
      if w >= dl_spill_words then
        goto 99;
      bits := v^[w];
    until bits <> [];
    b := 0;
  end;
  while not (b in bits) do
    b := b + 1;
  spill_find_next := w * 32 + b;
  return;
99:
  spill_find_next := 0;
end;

{ is_spill_instruction - whether instr is a spill load or store: a load
  (class 16) from the stack frame (operand 1 a stack frame
  displacement, operand 2 the stack frame's live range, rtn +116) into
  operand 3, or a store (class 21) of operand 1 there (operands 2, 3),
  whose slot's node (the displacement's link) is a spill slot (flags
  bit 29) made for the register's variable (its live range's node20),
  or is that variable.  Then is_load, the slot's node, the variable
  and the slot's number; a variable not a slot itself takes the slot's
  number.

  0x22C6AE, 0x156 bytes, internal: instr, rtn by value, the four
  results by address.  The class from instruction_attributes
  (0x2B8C3C + 20 opc, +7); the operands' kinds at +47, +59, +71
  (`moveq #31; and.b'), 12 ip_reg_like and 20 displacement_stack_frame;
  `st' or `move.b D0' (D0 cleared) for is_load; the slot's node from
  +48 or +60 (the displacement's link), the variable from the
  register's live range (+52 or +76) +20.  A VAR_NAME's flags `btst
  #29' of +32, a FORTRAN symbol's of +24. }

function is_spill_instruction(
    instr: instr_ptr_t;
    rtn: rtn_ptr_t;
    out is_load: boolean;
    out sym: dbg_sym_ptr_t;
    out var_sym: dbg_sym_ptr_t;
    out slot: integer): boolean; options(val_param); internal;
var
  s, v: dbg_sym_ptr_t;
  c: integer;
begin
  is_spill_instruction := false;
  c := instruction_attributes[instr^.opc].class;
  if (c = class$load) and
     (instr^.opnds[2].h.kind = operand$ip_reg_like) and
     (lr_ptr_t(instr^.opnds[2].ptr) = dbg_rtn_ptr_t(rtn)^.sf_lr) and
     (instr^.opnds[1].h.kind = operand$displacement_stack_frame) then begin
    is_load := true;
    s := dbg_sym_ptr_t(instr^.opnds[1].link);
    v := lr_ptr_t(instr^.opnds[3].ptr)^.node20;
  end
  else if (c = class$store) and
     (instr^.opnds[3].h.kind = operand$ip_reg_like) and
     (lr_ptr_t(instr^.opnds[3].ptr) = dbg_rtn_ptr_t(rtn)^.sf_lr) and
     (instr^.opnds[2].h.kind = operand$displacement_stack_frame) then begin
    is_load := false;
    s := dbg_sym_ptr_t(instr^.opnds[2].link);
    v := lr_ptr_t(instr^.opnds[1].ptr)^.node20;
  end
  else
    s := nil;
  if s <> nil then
    if v <> nil then
      if s^.kind = var_name then begin
        if 29 in s^.vflags then
          if (s = v) or (s^.var_of = v) then begin
            is_spill_instruction := true;
            sym := s;
            var_sym := v;
            slot := s^.vslot;
            if v^.kind = var_name then begin
              if not (29 in v^.vflags) then
                v^.vslot := s^.vslot;
            end
            else if v^.kind = fortran_symbol then
              if not (29 in v^.fflags) then
                v^.fslot := s^.vslot;
          end;
      end
      else if s^.kind = fortran_symbol then
        if s = v then
          if 29 in s^.fflags then begin
            is_spill_instruction := true;
            sym := v;
            var_sym := v;
            slot := v^.fslot;
          end;
end;

{ underlying_spill_location - the spill slots' records of lr's
  variable (nil without one).

  0x22C804, 0x26 bytes, internal, no frame: lr at (4,SP); A0.  A
  VAR_NAME's +64, any other node's +50. }

function underlying_spill_location(
    lr: lr_ptr_t): dbg_spill_ptr_t; options(val_param); internal;
var
  v: dbg_sym_ptr_t;
begin
  if lr^.node20 = nil then
    underlying_spill_location := nil
  else begin
    v := lr^.node20;
    if v^.kind = var_name then
      underlying_spill_location := v^.vspills
    else
      underlying_spill_location := v^.fspills;
  end;
end;

{ loc_after - the location after instr: its own for a PMOVE (class 18,
  no space), 8 on for an instruction that continues into the next word
  (+0 bit 2), 4 otherwise.

  0x22C82A, 0x3A bytes, internal, no frame: instr at (4,SP); D0.  The
  location is the instruction's +28 (docs/questions.md 178). }

function loc_after(
    instr: instr_ptr_t): integer32; options(val_param); internal;
begin
  if instruction_attributes[instr^.opc].class = class$pmove then
    loc_after := instr^.l28
  else if instr^.h.grouped then
    loc_after := instr^.l28 + 8
  else
    loc_after := instr^.l28 + 4;
end;

{ instr_is_pmove - whether instr's opcode has b6_0 or is of class 18.

  0x22C864, 0x30 bytes, internal, no frame: `btst #0,(6,A0)'; `sne',
  `seq', `or.b'. }

function instr_is_pmove(
    instr: instr_ptr_t): boolean; options(val_param); internal;
var
  a: instr_attr_t;
begin
  a := instruction_attributes[instr^.opc];
  instr_is_pmove := a.b6_0 or (a.class = class$pmove);
end;

{ interesting_variable - whether lr holds a variable the debugger is
  told about: a VAR_NAME without flags bit 14 (`btst #14' of the word
  at +34), or a FORTRAN symbol.

  0x22C894, 0x40 bytes, internal, no frame. }

function interesting_variable(
    lr: lr_ptr_t): boolean; options(val_param); internal;
var
  v: dbg_sym_ptr_t;
begin
  if lr = nil then
    interesting_variable := false
  else if lr^.node20 = nil then
    interesting_variable := false
  else begin
    v := lr^.node20;
    if v^.kind = var_name then
      interesting_variable := not (14 in v^.vflags)
    else if v^.kind = fortran_symbol then
      interesting_variable := true
    else
      interesting_variable := false;
  end;
end;

{ dbg_life_$initialize - the phase's data flow: a live range or slot is
  GEN_LOCAL in a block when the block writes it (an assignment to its
  register, a spill store) and nothing after kills it, NOT_KILLED when
  no write of its register (any value) or of the slot reaches the
  block's end, EXPOSED_USE when it is read before being killed (a
  register read, a spill load); live and available values are
  propagated, and AVAIL_ON_ENTRY becomes what is available on entry,
  not live there and not killed in the block: the variables a block
  passes through unchanged.  The not-killed vectors by register
  (ip_nk, fp_nk, pair_nk: all the live ranges allocated to a register,
  less those allocated to it) are each register's mask.

  0x22CD24, 0x5A2 bytes, internal (`pea (A2); bsr.w', `addq.l #2,SP':
  pattern 51): rtn by value; an 868-byte frame its nested routines
  reach through the dynamic link (`movea.l (A6),A0', pattern 25): the
  three arrays at -776, -520, -264, the heap at -780, the pending
  call at -784, the block's vectors at -820 (NOT_KILLED), -824
  (GEN_LOCAL), -828 (EXPOSED_USE).  The classes load and store are
  the mask 0x210000 (`btst D1,D3'); the register operands the kinds
  1..6 (the mask 126); read is the operand's +1 bit 4, write and
  modify the mask 12.  A call (opcode 129) with +3 bit 7 (its delay
  slot run on sequential flow; docs/prism-isa.md) is taken after the next
  instruction.  The final loop's bounds are the vectors' live range
  and slot words (`dbf' over longword counts). }

procedure dbg_life_$initialize(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  ip_nk: dbg_vecs_t;                    { -776 }
  fp_nk: dbg_vecs_t;                    { -520 }
  pair_nk: dbg_vecs_t;                  { -264 }
  heap: univ_ptr;                       { -780 }
  last_call: instr_ptr_t;               { -784 }
  status: status_$t;                    { -792 }
  sym: dbg_sym_ptr_t;                   { -800 }
  mask: bv_word_t;                      { -804 }
  arrp: dbg_vecs_ptr_t;                 { -808 }
  instr: instr_ptr_t;                   { -812 }
  nk: bv_ptr_t;                         { -820 }
  gen: bv_ptr_t;                        { -824 }
  eu: bv_ptr_t;                         { -828 }
  bb: bb_ptr_t;                         { -832 }
  var_sym: dbg_sym_ptr_t;               { -836 }
  slot: integer;                        { -838 }
  i: integer;                           { -840 }
  is_load: boolean;                     { -846 }
  pending: boolean;
  spilled: boolean;
  pm: boolean;
  lr: lr_ptr_t;
  rec: dbg_spill_ptr_t;
  s: dbg_spill_ptr_t;
  v: dbg_sym_ptr_t;
  c: dbg_clob_ptr_t;
  k: integer32;
  r: integer32;
  w: integer32;

  { initialize_not_killed_array - arr[0..count] each a vector of n
    words of ones from base on (with all false, the odd entries nil and
    no vector: the pairs); the space after them.

    0x22C8D4, 0x64 bytes, nested (reads nothing of its parent's): base,
    n, count by value, all a byte, arr by address; the result in its
    slot at -20 (A0).  The words by `move.l D5,(A0)+' while n counts
    down; the entries by `dbf' over count. }

  function initialize_not_killed_array(
      base: bv_ptr_t;
      n: integer32;
      count: integer32;
      all: boolean;
      var arr: dbg_vecs_t): bv_ptr_t; options(val_param);
  var
    i: integer32;
    j: integer32;
  begin
    for i := 0 to count do
      if not all and odd(i) then
        arr[i] := nil
      else begin
        arr[i] := base;
        j := n;
        while j > 0 do begin
          base^[0] := [0..31];
          base := addr(base^[1]);
          j := j - 1;
        end;
      end;
    initialize_not_killed_array := base;
  end;

  { fill_not_killed_sets - the not-killed vectors by register: 30
    integer, 64 floating and 32 pairs of (l192 + 32) div 32 words from
    one rws heap block (504 bytes a word), all ones; then each complex
    live range with a register is cleared from its register's (both
    halves' and the pair's for a pair, the single's and its pair's for
    a single), except the registers' own physical live ranges (lir's
    tables, lir +0x4090 and +0x3F90), whose node20 is cleared, as that
    of an integer live range above register 29.

    0x22C938, 0x1D2 bytes, nested, no parameters: rtn and the arrays
    through the parent's frame (`movea.l (A6),A3'); the live ranges
    from rtn +60 by complex id (1 .. rtn +194, a word); the register
    their +2, ip_reg their rrp's sign bit (`tst.w (A2)'). }

  procedure fill_not_killed_sets;
  var
    n: integer32;
    size: integer32;
    p: bv_ptr_t;
    i: integer;
    r: integer32;
    lr: lr_ptr_t;
    ip_phys: dbg_phys_ptr_t;
    fp_phys: dbg_phys_ptr_t;
  begin
    n := (rtn^.l192 + 32) div 32;
    size := n * 504;
    p := rws_$alloc_heap(size);
    heap := p;
    p := initialize_not_killed_array(p, n, 29, true, ip_nk);
    p := initialize_not_killed_array(p, n, 63, true, fp_nk);
    p := initialize_not_killed_array(p, n, 63, false, pair_nk);
    ip_phys := univ_ptr(addr(lir_4090));
    fp_phys := univ_ptr(addr(lir_3f90));
    for i := 1 to rtn^.l192 do begin
      lr := rtn^.lr_map^[i];
      r := lr^.f2.physical_register_number;
      if rrp$ip_reg in lr^.rrp then begin
        if (ip_phys^[r] = lr) or (r > 29) then begin
          lr^.node20 := nil;
          next;
        end;
      end
      else if fp_phys^[r] = lr then begin
        lr^.node20 := nil;
        next;
      end;
      if rrp$ip_reg in lr^.rrp then
        bv_$clear(ip_nk[r], lr)
      else if lr^.mate <> nil then begin
        if not odd(r) then begin
          bv_$clear(fp_nk[r], lr);
          bv_$clear(fp_nk[r + 1], lr);
          bv_$clear(pair_nk[r], lr);
          bv_$clear(fp_nk[r], lr^.mate);
          bv_$clear(fp_nk[r + 1], lr^.mate);
          bv_$clear(pair_nk[r], lr^.mate);
        end;
      end
      else begin
        bv_$clear(fp_nk[r], lr);
        bv_$clear(pair_nk[r & (~1)], lr);
      end;
    end;
  end;

  { write_spilled_var - a spill store to slot: its bit (after the live
    ranges' words) set in GEN_LOCAL and cleared from NOT_KILLED.

    0x22CB0A, 0x62 bytes, nested: slot a word; the bit number in a
    word (`move.w (34,A5),D1; lsl.w #5': dl_lr_words' low word), the
    bit's set built in a frame longword (`bset'). }

  procedure write_spilled_var(
      slot: integer); options(val_param);
  var
    bit: integer;
    w: integer;
    t: bv_word_t;
  begin
    bit := slot + dl_lr_words * 32;
    w := bit div 32;
    t := [bit mod 32];
    gen^[w] := gen^[w] + t;
    nk^[w] := nk^[w] - t;
  end;

  { read_spilled_var - a spill load from slot: its bit set in
    EXPOSED_USE when it is not killed yet in the block.

    0x22CB6C, 0x60 bytes, nested: slot a word. }

  procedure read_spilled_var(
      slot: integer); options(val_param);
  var
    bit: integer;
    w: integer;
    b: integer;
  begin
    bit := slot + dl_lr_words * 32;
    b := bit mod 32;
    w := bit div 32;
    if b in nk^[w] then
      eu^[w] := eu^[w] + [b];
  end;

  { kill_spilled_var - slot's value overwritten (a write of a register
    whose variable has the slot): its bit cleared from NOT_KILLED and
    GEN_LOCAL.

    0x22CBCC, 0x64 bytes, nested: slot a word, the bit number a
    longword here (`ext.l D0; move.l (32,A5),D1; lsl.l #5'). }

  procedure kill_spilled_var(
      slot: integer); options(val_param);
  var
    bit: integer32;
    w: integer32;
    t: bv_word_t;
  begin
    bit := slot + dl_lr_words * 32;
    w := bit div 32;
    t := [bit mod 32];
    nk^[w] := nk^[w] - t;
    gen^[w] := gen^[w] - t;
  end;

  { write_register - a write of register reg of the file kind (1
    integer, 2 floating, else a pair): every live range allocated
    elsewhere stays not killed and generated only through the
    register's mask; lr (the half that is a pair's even register) is
    generated.  Integer registers above 29 are ignored.

    0x22CC30, 0xF4 bytes, nested: reg, kind words, lr; the array in
    the parent's -808, the mask in -804, the index in -840 (a word,
    counted to dl_lr_words' low word less one, tested at the bottom:
    pattern 109); lr's odd half by its rrp's +1 bit 1. }

  procedure write_register(
      reg: integer;
      kind: integer;
      lr: lr_ptr_t); options(val_param);
  var
    v: bv_ptr_t;
  begin
    if kind = 1 then begin
      if reg > 29 then
        return;
      arrp := addr(ip_nk);
    end
    else if kind = 2 then
      arrp := addr(fp_nk)
    else
      arrp := addr(pair_nk);
    v := arrp^[reg];
    for i := 0 to dl_lr_words - 1 do begin
      mask := v^[i];
      gen^[i] := gen^[i] * mask;
      nk^[i] := nk^[i] * mask;
    end;
    if lr <> nil then begin
      if lr^.mate <> nil then
        if rrp$fp_reg_odd_only in lr^.rrp then
          lr := lr^.mate;
      if lr^.id <> 0 then
        bv_$set(gen, lr);
    end;
  end;

begin
  fill_not_killed_sets;
  lr := rtn^.lrs;
  while lr <> nil do begin
    dbg_lr_ptr_t(lr)^.first := nil;
    dbg_lr_ptr_t(lr)^.current := nil;
    dbg_lr_ptr_t(lr)^.nranges := 0;
    if lr^.node20 <> nil then begin
      v := lr^.node20;
      if v^.kind = var_name then
        v^.vlast_bb := nil
      else if v^.kind = fortran_symbol then
        v^.flast_bb := nil;
      if lr^.mate <> nil then
        if lr^.mate^.node20 = nil then
          lr^.mate^.node20 := lr^.node20;
    end;
    lr := lr^.next;
  end;

  last_call := nil;
  pending := false;
  bb := rtn^.bbs;
  while bb <> nil do begin
    gen := bb^.avail_gen;
    nk := bb^.transparent;
    eu := bb^.live_gen;
    instr := bb^.first;
    while instr <> nil do begin
      spilled := false;
      if instruction_attributes[instr^.opc].class in [class$load, class$store] then
        if is_spill_instruction(instr, rtn, is_load, sym, var_sym, slot) then begin
          rec := addr(dl_spills^[slot]);
          if rec^.slot = 0 then begin
            rec^.sym := sym;
            rec^.var_sym := var_sym;
            rec^.slot := slot;
            if var_sym^.kind = var_name then begin
              rec^.next := var_sym^.vspills;
              var_sym^.vspills := rec;
              var_sym^.vlast_bb := nil;
            end
            else if var_sym^.kind = fortran_symbol then begin
              rec^.next := var_sym^.fspills;
              var_sym^.fspills := rec;
              var_sym^.flast_bb := nil;
            end;
          end;
          if is_load then begin
            rec^.f24.kind := ord(instr^.opnds[3].h.kind);
            read_spilled_var(slot);
          end
          else begin
            rec^.f24.kind := ord(instr^.opnds[1].h.kind);
            write_spilled_var(slot);
          end;
          spilled := true;
        end;
      pm := instr_is_pmove(instr);
      for k := 1 to instruction_attributes[instr^.opc].nresults do
        with instr^.opnds[k] do
          if h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
            if h.read then begin
              lr := ptr;
              if lr^.id <> 0 then
                bv_$set_if_not_killed(nk, lr, eu);
            end
            else if h.write or h.modify then begin
              if pm then
                if not interesting_variable(ptr) then
                  next;
              write_register(h.num, ord(h.kind), ptr);
              if not spilled then begin
                s := underlying_spill_location(ptr);
                while s <> nil do begin
                  kill_spilled_var(s^.slot);
                  s := s^.next;
                end;
              end;
            end;
      if instr^.opc = ord(opc$call) then
        if cell_head_ptr_t(instr)^.b3_7 then
          pending := true
        else
          last_call := instr;
      if last_call <> nil then begin
        c := addr(last_call^.opnds[last_call^.h.nopnds + 1]);
        for r := 0 to 29 do
          if r in c^.ip then
            write_register(r, 1, nil);
        for r := 0 to 31 do
          if r in c^.fp_lo then
            write_register(r, 2, nil);
        for r := 32 to 63 do
          if r - 32 in c^.fp_hi then
            write_register(r, 2, nil);
        last_call := nil;
      end;
      if pending then begin
        pending := false;
        last_call := instr;
      end;
      instr := instr^.next;
    end;
    bb := bb^.next;
  end;

  bv_$propagate_lifetimes((dl_lr_words + dl_spill_words) * 32, rtn);
  bv_$propagate_availability((dl_lr_words + dl_spill_words) * 32, rtn, false);

  if at_backend_switches.sw9 then begin
    bb := rtn^.bbs;
    while bb <> nil do begin
      vfmt_$write(' BB#%3ZWD%$', bb^.num);
      dmp_$complex_lr_bit_vector_header(rtn);
      vfmt_$write('%.');
      dmp_$complex_lr_bit_vector(rtn, 'EXPOSED_USE', 11, bb^.live_gen);
      dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_ENTRY', 13, bb^.live_in);
      dmp_$complex_lr_bit_vector(rtn, 'NOT_KILLED', 10, bb^.transparent);
      dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_EXIT', 12, bb^.live_out);
      dmp_$complex_lr_bit_vector(rtn, 'GEN_LOCAL', 9, bb^.avail_gen);
      dmp_$complex_lr_bit_vector(rtn, 'AVAIL_ON_ENTRY', 14, bb^.avail_in);
      dmp_$complex_lr_bit_vector(rtn, 'AVAIL_ON_EXIT', 13, bb^.avail_out);
      vfmt_$write('%.');
      bb := bb^.next;
    end;
  end;

  bb := rtn^.bbs;
  while bb <> nil do begin
    for w := 0 to dl_lr_words - 1 do begin
      bb^.live_in^[w] := bb^.live_in^[w] * bb^.avail_in^[w];
      bb^.avail_in^[w] := bb^.avail_in^[w] *
          (bb^.transparent^[w] - bb^.live_in^[w]);
    end;
    for w := dl_lr_words to dl_lr_words + dl_spill_words - 1 do
      bb^.avail_in^[w] := bb^.avail_in^[w] *
          (bb^.transparent^[w] - bb^.live_in^[w]);
    bb := bb^.next;
  end;

  if heap <> nil then
    rws_$release_heap(heap, status);
end;

{ dbg_life_$close_pc_range - the register reg's open range (of the file
  kind: 1 integer, else floating) ends at at.

  0x22D32A, 0x60 bytes, internal: at, kind and reg words; the open
  ranges from A5+48 or A5+44. }

procedure dbg_life_$close_pc_range(
    at: integer32;
    kind: integer;
    reg: integer); options(val_param); internal;
var
  r: dbg_range_ptr_t;
begin
  if kind = 1 then begin
    r := dl_ip_open^[reg];
    dl_ip_open^[reg] := nil;
  end
  else begin
    r := dl_fp_open^[reg];
    dl_fp_open^[reg] := nil;
  end;
  if r <> nil then
    r^.stop := at;
end;

{ dbg_life_$close_spill_pc_range - slot's open range ends at at.

  0x22D38A, 0x46 bytes, internal: at, slot longwords; the open flag
  `btst #2' and `bclr #10' of the record's +26. }

procedure dbg_life_$close_spill_pc_range(
    at: integer32;
    slot: integer32); options(val_param); internal;
begin
  if dl_spills^[slot].f24.open then begin
    dl_spills^[slot].f24.open := false;
    dl_spills^[slot].current^.stop := at;
  end;
end;

{ dbg_life_$close_all_pc_ranges - every open range ends at at: the
  registers' (32 integer, 64 floating) and the slots' (1 .. rtn +196,
  its low word).

  0x22D3D0, 0xA0 bytes, internal: rtn, at by value. }

procedure dbg_life_$close_all_pc_ranges(
    rtn: rtn_ptr_t;
    at: integer32); options(val_param); internal;
var
  i: integer;
begin
  for i := 0 to 31 do
    if dl_ip_open^[i] <> nil then begin
      dl_ip_open^[i]^.stop := at;
      dl_ip_open^[i] := nil;
    end;
  for i := 0 to 63 do
    if dl_fp_open^[i] <> nil then begin
      dl_fp_open^[i]^.stop := at;
      dl_fp_open^[i] := nil;
    end;
  for i := 1 to rtn^.spills do
    if dl_spills^[i].f24.open then begin
      dl_spills^[i].current^.stop := at;
      dl_spills^[i].f24.open := false;
    end;
end;

{ dbg_life_$open_pc_range - a range from start opened for slot's
  variable (slot nonzero) or lr's register (kind 1 integer, 2
  floating; a pair's even half, kind 3): the current range continues
  when it ends at start or at at, else a new one (from the heap,
  cleared) is chained after it (the first of a live range puts the
  live range on dl_lrs).  An integer register above 29 has none.  A
  register already open (not a pair) is reported.

  0x22D470, 0x16A bytes, internal: start, at longwords, slot a word,
  lr, kind a word.  The count of a slot's ranges `addi.l #2048' to its
  record's +24, a live range's `addq.l #1' to its +72; the open flag
  `bset #10' of +26.  The message's register by a frame word (-22).
  The test of slot after the slot's branch has returned is the
  image's (always true). }

procedure dbg_life_$open_pc_range(
    start: integer32;
    at: integer32;
    slot: integer;
    lr: lr_ptr_t;
    kind: integer); options(val_param); internal;
var
  cur: dbg_range_ptr_t;
  r: dbg_range_ptr_t;
  openp: ^dbg_range_ptr_t;
  reg: integer;
begin
  if lr <> nil then
    if lr^.mate <> nil then begin
      if rrp$fp_reg_odd_only in lr^.rrp then
        lr := lr^.mate;
      kind := 3;
    end;
  if slot <> 0 then
    cur := dl_spills^[slot].current
  else begin
    if kind = 1 then
      if lr^.f2.physical_register_number > 29 then
        return;
    cur := dbg_lr_ptr_t(lr)^.current;
  end;
  if (cur = nil) or ((cur^.stop <> start) and (cur^.stop <> at)) then begin
    r := mrh_$alloc_fixed(dl_heap);
    r^.start := start;
    if cur <> nil then
      cur^.next := r
    else if slot <> 0 then
      dl_spills^[slot].first := r
    else begin
      dbg_lr_ptr_t(lr)^.first := r;
      lr^.next := dl_lrs;
      dl_lrs := lr;
    end;
    cur := r;
    if slot <> 0 then begin
      dl_spills^[slot].current := cur;
      dl_spills^[slot].f24.count := dl_spills^[slot].f24.count + 1;
    end
    else begin
      dbg_lr_ptr_t(lr)^.current := cur;
      dbg_lr_ptr_t(lr)^.nranges := dbg_lr_ptr_t(lr)^.nranges + 1;
    end;
  end;
  if slot <> 0 then
    dl_spills^[slot].f24.open := true
  else begin
    if kind = 1 then
      openp := addr(dl_ip_open^[lr^.f2.physical_register_number])
    else
      openp := addr(dl_fp_open^[lr^.f2.physical_register_number]);
    if openp^ <> nil then
      if kind <> 3 then
        if (slot <> 0) or (lr^.mate = nil) then begin
          reg := lr^.f2.physical_register_number;
          vfmt_$write('DBG_LIFE_$OPEN_PC_RANGE: Register %wd already open.%.',
              reg);
        end;
    openp^ := cur;
  end;
end;

{ map_physical_to_virtual_lr - at the routine's entry, an argument's
  physical register (lr, lir's live range of the register) is followed
  to the first instruction from instr on that reads it and writes a
  variable's live range: when the two are the same register, the
  variable's range opens at instr; otherwise a live range is made (a
  copy of the register's: kind, register and rrp, with the variable
  and the mate of the one written) for the register, open from instr
  to the copying instruction.

  0x22D610, 0x1D8 bytes, loads A5 (not internal); instr and lr by
  address (no val_param: `movea.l (8,A6),A3; movea.l (A3),A2').  The
  reads (+1 mask 48, read or intend_to_modify) and writes (mask 12)
  among the operands the attributes count (+11 bits 2..0), the found
  operands' numbers in D2, D6; `bra' out of both loops.  The live
  range from gspace(88) (lr_t's size), its +8 the kind (a byte), +2
  the register, +0 the rrp, +20 and +16 from the written one. }

procedure map_physical_to_virtual_lr(
    instr: instr_ptr_t;
    lr: lr_ptr_t);
label
  10;
var
  kind: integer;
  i: instr_ptr_t;
  k, j: integer32;
  kf, jf: integer32;
  n: integer32;
  v: dbg_sym_ptr_t;
  vlr: lr_ptr_t;
  nlr: lr_ptr_t;
begin
  if rrp$ip_reg in lr^.rrp then
    kind := 1
  else
    kind := 2;
  i := instr;
  while i <> nil do begin
    n := instruction_attributes[i^.opc].nresults;
    for k := 1 to n do
      if i^.opnds[k].h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
        if i^.opnds[k].h.read or i^.opnds[k].h.intend_to_modify then
          if lr_ptr_t(i^.opnds[k].ptr) = lr then
            for j := k + 1 to n do
              if i^.opnds[j].h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
                if i^.opnds[j].h.write or i^.opnds[j].h.modify then begin
                  v := lr_ptr_t(i^.opnds[j].ptr)^.node20;
                  if v <> nil then
                    if (v^.kind = fortran_symbol)
                        or (v^.kind = var_name) then begin
                      kf := k;
                      jf := j;
                      goto 10;
                    end;
                end;
    i := i^.next;
  end;
10:
  if i <> nil then
    if i^.opnds[kf].h.num = i^.opnds[jf].h.num then begin
      vlr := i^.opnds[jf].ptr;
      dbg_life_$open_pc_range(instr^.l28, instr^.l28, 0, vlr, kind);
    end
    else begin
      nlr := gspace(88);
      dbg_lr_ptr_t(nlr)^.kind := chr(kind);
      nlr^.f2.physical_register_number := lr_ptr_t(i^.opnds[kf].ptr)^.f2.physical_register_number;
      nlr^.rrp := lr_ptr_t(i^.opnds[kf].ptr)^.rrp;
      nlr^.node20 := lr_ptr_t(i^.opnds[jf].ptr)^.node20;
      nlr^.mate := lr_ptr_t(i^.opnds[jf].ptr)^.mate;
      dbg_life_$open_pc_range(instr^.l28, instr^.l28, 0, nlr, kind);
      dbg_life_$close_pc_range(i^.l28, kind, nlr^.f2.physical_register_number);
    end;
end;

{ dbg_life_$find_symbols - the pc ranges: in each block, the variables
  live on entry (live ranges and slots) open at its first instruction;
  at each instruction an argument's register is followed (the entry),
  a spill store opens its slot after it and closes its register, a
  spill load closes its register, a write of a register closes the
  register (both halves of a pair) and opens the variable written
  after the instruction (unless the call before it clobbered the
  register) and closes its slots unless the write is a spill; a call's
  clobbered registers close after the next instruction (a squashing
  call's after the one after); at the block's end the variables
  available on entry that the block did not write open at its first
  instruction, and everything open closes at the next block's first
  instruction (or the block's last).

  0x22D7E8, 0x742 bytes, internal: rtn by value; the call at -12, the
  pending flag -52, the block -40, the instruction -32.  The entry is
  opcode 196; the arguments' records from rtn +16 (dbg_conv_t), loc 0
  (ip_reg) by lir_4090, 1 or 2 (the mask 6) by lir_3f90.  The test of
  the call is inside the loop over the operands (an instruction
  without operands is never taken for a call).  The floating clobber
  tests of the image read register r (above 31) in the set of 0..31
  (+48, never true) and r (up to 31) in that of 32..63 (+44): kept
  (the integer and the final close loops use +44 for 32..63). }

procedure dbg_life_$find_symbols(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  last_call: instr_ptr_t;               { -12 }
  sym: dbg_sym_ptr_t;                   { -24 }
  lr: lr_ptr_t;                         { -28 }
  instr: instr_ptr_t;                   { -32 }
  bb: bb_ptr_t;                         { -40 }
  var_sym: dbg_sym_ptr_t;               { -44 }
  slot: integer;                        { -46 }
  kind: integer;                        { -48 }
  pending: boolean;                     { -52 }
  spilled: boolean;                     { -54 }
  is_load: boolean;                     { -56 }
  pm: boolean;
  clobbered: boolean;
  s: integer;
  k: integer32;
  r: integer;
  reg: integer;
  conv: dbg_conv_ptr_t;
  c: dbg_clob_ptr_t;
  set32: bv_word_t;
  v: dbg_sym_ptr_t;
  sp: dbg_spill_ptr_t;
  at: integer32;
  lb: bb_ptr_t;
  ip_phys: dbg_phys_ptr_t;
  fp_phys: dbg_phys_ptr_t;
begin
  last_call := nil;
  pending := false;
  bb := rtn^.bbs;
  while bb <> nil do begin
    if bb^.first <> nil then begin
      lr := bv_$find_next(rtn, bb^.live_in, nil);
      while lr <> nil do begin
        if lr^.node20 <> nil then begin
          v := lr^.node20;
          if (v^.kind = fortran_symbol) or (v^.kind = var_name) then begin
            if rrp$fp_reg in lr^.rrp then
              kind := 2
            else
              kind := 1;
            dbg_life_$open_pc_range(bb^.first^.l28, bb^.first^.l28, 0, lr, kind);
          end;
        end;
        lr := bv_$find_next(rtn, bb^.live_in, lr);
      end;
      s := spill_find_next(rtn, addr(bb^.live_in^[dl_lr_words]), 0);
      while s <> 0 do begin
        dbg_life_$open_pc_range(bb^.first^.l28, bb^.first^.l28, s, nil,
            dl_spills^[s].f24.kind);
        s := spill_find_next(rtn, addr(bb^.live_in^[dl_lr_words]), s);
      end;
    end;

    instr := bb^.first;
    while instr <> nil do begin
      if instr^.opc = ord(opc$entry) then begin
        conv := dbg_rtn_ptr_t(rtn)^.conv;
        ip_phys := univ_ptr(addr(lir_4090));
        fp_phys := univ_ptr(addr(lir_3f90));
        for k := 1 to conv^.nargs do
          if ord(conv^.args[k].loc) = ord(arg_loc$ip_reg) then begin
            lr := ip_phys^[ord(conv^.args[k].reg)];
            map_physical_to_virtual_lr(instr, lr);
          end
          else if ord(conv^.args[k].loc) in [ord(arg_loc$fp_reg), ord(arg_loc$fp_reg_pair)] then begin
            lr := fp_phys^[ord(conv^.args[k].reg)];
            map_physical_to_virtual_lr(instr, lr);
          end;
      end;

      spilled := false;
      if instruction_attributes[instr^.opc].class in [class$load, class$store] then
        if is_spill_instruction(instr, rtn, is_load, sym, var_sym, slot) then begin
          if is_load then
            dbg_life_$close_pc_range(instr^.l28, ord(instr^.opnds[3].h.kind),
                instr^.opnds[3].h.num)
          else begin
            dbg_life_$close_pc_range(instr^.l28, ord(instr^.opnds[1].h.kind),
                instr^.opnds[1].h.num);
            dbg_life_$open_pc_range(loc_after(instr), instr^.l28, slot, nil,
                ord(instr^.opnds[1].h.kind));
          end;
          v := sym^.var_of;
          if v^.kind = var_name then
            v^.vlast_bb := bb
          else if v^.kind = fortran_symbol then
            v^.flast_bb := bb;
          spilled := true;
        end;

      pm := instr_is_pmove(instr);
      for k := 1 to instruction_attributes[instr^.opc].nresults do begin
        with instr^.opnds[k] do
          if h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
            lr := ptr;
            if lr^.node20 <> nil then begin
              v := lr^.node20;
              if v^.kind = var_name then
                v^.vlast_bb := bb
              else if v^.kind = fortran_symbol then
                v^.flast_bb := bb;
            end;
            if h.write or h.modify then
              if not pm or interesting_variable(ptr) then begin
                dbg_life_$close_pc_range(instr^.l28, ord(h.kind), h.num);
                lr := ptr;
                if lr^.mate <> nil then
                  if h.fp_reg_even_only then
                    dbg_life_$close_pc_range(instr^.l28, ord(h.kind), h.num + 1)
                  else
                    dbg_life_$close_pc_range(instr^.l28, ord(h.kind), h.num - 1);
                lr := ptr;
                if lr^.node20 <> nil then begin
                  v := lr^.node20;
                  if (v^.kind = fortran_symbol)
                      or (v^.kind = var_name) then begin
                    clobbered := false;
                    if last_call <> nil then begin
                      c := addr(last_call^.opnds[last_call^.h.nopnds + 1]);
                      reg := h.num;
                      case ord(h.kind) of
                        1:
                          clobbered := reg in c^.ip;
                        2:
                          if reg > 31 then
                            clobbered := reg in c^.fp_lo
                          else
                            clobbered := reg in c^.fp_hi;
                        3: begin
                          if reg > 31 then
                            set32 := c^.fp_lo
                          else
                            set32 := c^.fp_hi;
                          clobbered := (reg in set32) or (reg + 1 in set32);
                        end;
                        otherwise
                      end;
                    end;
                    if not clobbered then begin
                      dbg_life_$open_pc_range(loc_after(instr), instr^.l28, 0,
                          lr, ord(h.kind));
                      if not spilled then begin
                        sp := underlying_spill_location(ptr);
                        while sp <> nil do begin
                          dbg_life_$close_spill_pc_range(instr^.l28, sp^.slot);
                          sp := sp^.next;
                        end;
                      end;
                    end;
                  end;
                end;
              end;
          end;
        if instr^.opc = ord(opc$call) then
          if cell_head_ptr_t(instr)^.b3_7 then
            pending := true
          else
            last_call := instr;
      end;

      if last_call <> nil then begin
        c := addr(last_call^.opnds[last_call^.h.nopnds + 1]);
        for r := 0 to 29 do
          if r in c^.ip then
            dbg_life_$close_pc_range(instr^.l28, 1, r);
        for r := 0 to 31 do
          if r in c^.fp_lo then
            dbg_life_$close_pc_range(instr^.l28, 2, r);
        for r := 32 to 63 do
          if r - 32 in c^.fp_hi then
            dbg_life_$close_pc_range(instr^.l28, 2, r);
        last_call := nil;
      end;
      if pending then begin
        pending := false;
        last_call := instr;
      end;
      instr := instr^.next;
    end;

    if bb^.first <> nil then begin
      lr := bv_$find_next(rtn, bb^.avail_in, nil);
      while lr <> nil do begin
        if lr^.node20 <> nil then begin
          v := lr^.node20;
          if (v^.kind = fortran_symbol) or (v^.kind = var_name) then begin
            if v^.kind = var_name then
              lb := v^.vlast_bb
            else
              lb := v^.flast_bb;
            if lb <> bb then begin
              if rrp$ip_reg in lr^.rrp then
                kind := 1
              else if lr^.mate = nil then
                kind := 2
              else
                kind := 3;
              dbg_life_$open_pc_range(bb^.first^.l28, bb^.first^.l28, 0, lr, kind);
            end;
          end;
        end;
        lr := bv_$find_next(rtn, bb^.avail_in, lr);
      end;
      s := spill_find_next(rtn, addr(bb^.avail_in^[dl_lr_words]), 0);
      while s <> 0 do begin
        v := dl_spills^[s].var_sym;
        if v^.kind = var_name then
          lb := v^.vlast_bb
        else
          lb := v^.flast_bb;
        if lb <> bb then
          dbg_life_$open_pc_range(bb^.first^.l28, bb^.first^.l28, s, nil,
              dl_spills^[s].f24.kind);
        s := spill_find_next(rtn, addr(bb^.avail_in^[dl_lr_words]), s);
      end;
    end;

    if bb^.next <> nil then
      if bb^.next^.first <> nil then
        at := bb^.next^.first^.l28
      else
        at := bb^.last^.l28
    else
      at := bb^.last^.l28;
    dbg_life_$close_all_pc_ranges(rtn, at);
    bb := bb^.next;
  end;
end;

{ dbg_life_$compact - the debug records: one for each live range with
  pc ranges (dl_lrs) and each slot used, from its ranges less the
  empty ones (a range closed before it opened); a range of one
  location at the routine's first instruction is made one long.

  0x22DFF8, 0x174 bytes, internal: rtn by value; the routine's first
  location at -8, which add_live_range reads through the dynamic
  link.  A live range's record: slot_sym nil, the register, the file
  (0 integer, 1 single, 2 pair), mode 1 for storage class 5 (a
  VAR_NAME's +72, a FORTRAN symbol's +11 bits 7..4); a slot's: its
  node, the same mode test on the slot's node. }

procedure dbg_life_$compact(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  first_loc: integer32;                 { -8 }
  bb: bb_ptr_t;
  lr: lr_ptr_t;
  r: dbg_rec_ptr_t;
  v: dbg_sym_ptr_t;
  c: integer;
  i: integer;
  rec: dbg_spill_ptr_t;

  { add_live_range - a debug record of count ranges (those of the list
    that are not empty), chained first on sym's records; nil when none
    is left.  p4 is not read.

    0x22DF2A, 0xCE bytes, nested: ranges, count (a word), sym, p4 (a
    boolean pushed as a word); A0.  gspace(8 count + 20). }

  function add_live_range(
      ranges: dbg_range_ptr_t;
      count: integer;
      sym: dbg_sym_ptr_t;
      p4: boolean): dbg_rec_ptr_t; options(val_param);
  var
    r: dbg_range_ptr_t;
    prev: dbg_range_ptr_t;
    rec: dbg_rec_ptr_t;
    i: integer;
  begin
    r := ranges;
    prev := nil;
    while r <> nil do begin
      if r^.stop < r^.start then begin
        count := count - 1;
        if prev = nil then
          ranges := r^.next
        else
          prev^.next := r^.next;
      end
      else if (r^.start = first_loc) and (r^.stop = first_loc) then begin
        r^.stop := r^.stop + 1;
        prev := r;
      end
      else
        prev := r;
      r := r^.next;
    end;
    if count = 0 then begin
      add_live_range := nil;
      return;
    end;
    rec := gspace(count * 8 + 20);
    for i := 1 to count do begin
      rec^.ranges[i].start := ranges^.start;
      rec^.ranges[i].stop := ranges^.stop;
      ranges := ranges^.next;
    end;
    rec^.count := count;
    if sym^.kind = var_name then begin
      rec^.next := sym^.vdbg;
      sym^.vdbg := rec;
    end
    else begin
      rec^.next := sym^.fdbg;
      sym^.fdbg := rec;
    end;
    add_live_range := rec;
  end;

begin
  first_loc := 0;
  bb := rtn^.bbs;
  while bb <> nil do begin
    if bb^.first <> nil then begin
      first_loc := bb^.first^.l28;
      exit;
    end;
    bb := bb^.next;
  end;
  lr := dl_lrs;
  while lr <> nil do begin
    r := add_live_range(dbg_lr_ptr_t(lr)^.first, dbg_lr_ptr_t(lr)^.nranges,
        lr^.node20, true);
    if r <> nil then begin
      r^.slot_sym := nil;
      r^.f12.reg := lr^.f2.physical_register_number;
      if rrp$ip_reg in lr^.rrp then
        r^.f12.kind := 0
      else if lr^.mate = nil then
        r^.f12.kind := 1
      else
        r^.f12.kind := 2;
      v := lr^.node20;
      if v^.kind = var_name then
        c := v^.vclass
      else
        c := v^.f10.fclass;
      if c = 5 then
        r^.f12.mode := 1;
    end;
    lr := lr^.next;
  end;
  for i := 1 to rtn^.spills do begin
    rec := addr(dl_spills^[i]);
    if rec^.first <> nil then begin
      r := add_live_range(rec^.first, rec^.f24.count, rec^.var_sym, false);
      if r <> nil then begin
        r^.slot_sym := rec^.sym;
        v := rec^.sym;
        if v^.kind = var_name then
          c := v^.vclass
        else
          c := v^.f10.fclass;
        if c = 5 then
          r^.f12.mode := 1;
      end;
    end;
  end;
end;

{ dbg_life_$mark_ap_relative_vars - when the routine's argument
  pointer may be read after the RETURN (rtn +226 bit 0), each argument
  passed in memory gets one debug record (replacing its chain) that
  places it AP-relative (the stack frame's register, rtn +209; its
  offset from the node's +56 or +12) from the routine's first
  location to its last instruction's.

  0x22E16C, 0x150 bytes, internal: rtn by value.  The arguments from
  the routine's IL node's +128 (dbg_conv_t: 26 bytes each, from 1);
  loc 4 (arg_loc$memory) and not flag in one test (`seq; not.b; and.b;
  bpl'); the last block from rtn +72 (chained at +114: code order
  backwards).  gspace(28): one range; mode 3 by `ori.w #3,(12,A0)'. }

procedure dbg_life_$mark_ap_relative_vars(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  bb: bb_ptr_t;
  start: integer32;
  stop: integer32;
  conv: dbg_conv_ptr_t;
  k: integer32;
  v: dbg_sym_ptr_t;
  off: integer32;
  c: integer;
  r: dbg_rec_ptr_t;
begin
  if rtn^.f226.needs_frame then begin
    bb := rtn^.bbs;
    while bb^.first = nil do
      bb := bb^.next;
    start := bb^.first^.l28;
    bb := rtn^.bbs72;
    while bb^.last = nil do
      bb := bb^.next114;
    stop := bb^.last^.l28;
    conv := dbg_conv_ptr_t(il_$node_ptr_t(rtn^.node)^.xp[32]);
    for k := 1 to conv^.nargs do
      if conv^.args[k].sym <> nil then
        if (ord(conv^.args[k].loc) = ord(arg_loc$memory)) and
           not conv^.args[k].flag then
          if conv^.args[k].w0 = 0 then begin
            v := conv^.args[k].sym;
            if v^.kind <> fortran_symbol then begin
              off := v^.voffset;
              c := v^.vclass;
            end
            else begin
              c := v^.f10.fclass;
              off := v^.foffset;
            end;
            r := gspace(28);
            r^.f12.kind := 0;
            r^.f12.reg := dbg_rtn_ptr_t(rtn)^.sf_reg;
            if c = 5 then
              r^.f12.mode := 3
            else
              r^.f12.mode := 2;
            r^.offset := off;
            r^.count := 1;
            r^.ranges[1].start := start;
            r^.ranges[1].stop := stop;
            if conv^.args[k].sym^.kind <> fortran_symbol then
              conv^.args[k].sym^.vdbg := r
            else
              conv^.args[k].sym^.fdbg := r;
          end;
  end;
end;

{ DBG_LIFE_$PROCESS_ROUTINE - the phase, with -DBS or -DBA (the
  options' db, cargs +0x283 bit 0 and +0x284 bit 7: `and.l #0x18000'
  of the longword at 0x4437F2, `cmpi.w #2; bcs').  The vectors hold
  the complex live ranges and then the spill slots (rtn +196), each
  rounded up to 32 bits; the slots' records from an rws heap block
  (cleared), the open ranges' arrays from the phase's heap (12-byte
  fixed pieces, cleared).  With the switches' sw10 the slots are
  listed: number, bit and the variable.

  0x22E2BC, 0x25A bytes; loads A5: rtn by value (A2).  The slot's
  number goes to '%3ZLD' as a word in a frame longword (-14: vfmt
  reads its high half), the bit as a longword (-24); rws_$release_heap
  takes A5+40 by address and a status at -4. }

procedure dbg_life_$process_routine;
var
  size: integer32;
  i: integer;
  id: integer32;
  status: status_$t;
  v: dbg_sym_ptr_t;
begin
  if cargs_$options.db >= 2 then begin
    mrh_$initialize(dl_heap, 1, 12, 'DBG_LIFE heap%');
    dl_lr_words := (rtn^.l192 + 32) div 32;
    dl_spill_words := (rtn^.spills + 32) div 32;
    bv_$initialize_bit_vectors(rtn, (dl_spill_words + dl_lr_words) * 32, 7, false);
    size := (rtn^.spills * 28 + 3) & (~3);
    if size <> 0 then begin
      dl_spills := rws_$alloc_heap(size);
      for i := 1 to size div 4 do
        dbg_longs_ptr_t(dl_spills)^[i] := 0;
    end
    else
      dl_spills := nil;
    dbg_life_$initialize(rtn);
    dl_ip_open := mrh_$alloc(dl_heap, 128);
    dl_fp_open := mrh_$alloc(dl_heap, 256);
    dl_lrs := nil;
    dbg_life_$find_symbols(rtn);
    for i := 1 to rtn^.spills do begin
      v := dl_spills^[i].var_sym;
      if v <> nil then
        if v^.kind = var_name then
          v^.vspills := nil
        else
          v^.fspills := nil;
    end;
    dbg_life_$compact(rtn);
    dbg_life_$mark_ap_relative_vars(rtn);
    if at_backend_switches.sw10 then begin
      vfmt_$write('SPILLED LIVE RANGES:%.');
      for i := 1 to rtn^.spills do
        if dl_spills^[i].sym <> nil then begin
          vfmt_$write('%.');
          vfmt_$write('%3ZLD%$', i);
          id := dl_spills^[i].sym^.vslot + dl_lr_words * 32;
          vfmt_$write(', SPILLED, ID = %LD%$', id);
          if dl_spills^[i].var_sym <> nil then begin
            vfmt_$write('  "%$');
            discard(sym_$display_symbol_print_name(dl_spills^[i].var_sym));
            vfmt_$write('"%$');
          end;
          vfmt_$write('%.');
        end;
    end;
    bv_$release_bit_vectors(rtn);
    mrh_$release_all(dl_heap);
    if dl_spills <> nil then
      rws_$release_heap(dl_spills, status);
  end;
end;

{ DBG_LIFE_$END_ROUTINE - nothing.  0x22E562, 0x2 bytes (no A5). }

procedure dbg_life_$end_routine;
begin
end;
