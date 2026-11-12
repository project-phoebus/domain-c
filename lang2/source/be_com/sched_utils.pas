{ sched_utils - the instruction scheduler's utilities (cc.a88k only):
  the operand delays (how many cycles a value is late when an operand
  reads it: the opcode's latency for the operand, one more for a
  load's result read by its next instruction or by a branch-like
  instruction, the floating unit's latencies, with -CPU KODIAK its
  own for the divides and square roots), each block's precedence
  heights (the longest chain of delays from an instruction to the
  block's end, the scheduler's priority), and the snuggle moves: a
  copy put next to an instruction that writes or reads a physical
  register (an argument or result register of a call or of the entry)
  so that the physical register's live range stays as short as the
  instruction.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x279190  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x2791B2  sched_utils_$begin_compilation
    --------  0x2791B4  sched_utils_$init_for_routine
    --------  0x2791B6  sched_utils_$end_routine
    --------  0x2791B8  sched_utils_$end_compilation
    --------  0x2791BA  driving_instruction (internal)
    --------  0x2791E8  sched_utils_$kodiak_delay (internal)
    --------  0x279266  sched_utils_$operand_delay
    --------  0x279A42  sched_utils_$fill_in_operand_delays
    --------  0x279AB8  calculate_precedence (internal)
    --------  0x279BC4  sched_utils_$calculate_precedence
    --------  0x279D20  test_phys_lr (internal)
    --------  0x279D36  check_snuggle_writes (internal)
    --------  0x27A182  check_snuggle_reads (internal)
    --------  0x27A398  sched_utils_$insert_snuggle_moves
    A5 0x492E6C: one byte (+0), sched_utils_$calculate_precedence's
    second parameter, which nothing reads.

  The latencies come from the opcode tables: an operand's delay is
  bits 5..2 of its descriptor's third byte in instruction_attributes
  (+4k+2; none when bits 7..6 are 1 or 2), a condition code's bits
  7..4 of the opcode's +15.  During SCHED an instruction's +28 word is
  its precedence height (-1 while it is computed: a cycle is
  "deadlocked") and an operand's +2 bits 3..0 its delay (lst's cycle
  column later).  The snuggle checks' messages name
  COM_$PRESCAN_INST: they were com's once, most likely.

  Not known from the original: every local and parameter name; the
  flags' meaning (bit 0: a condition code read adds a cycle; bit 1:
  the delays are taken from the definition to its reader instead of
  from the reader back to its definition). }
module sched_utils;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

const
  { Instruction classes (instr_attr_t's class) as the image's masks
    group them. }
  su_branchy = [class$branch, class$call, class$fp_branch, class$jump,
      class$immediate, class$seq, class$trap, class$svc,
      class$return];                    { 0x1104366 }
  su_loads = [class$fp_control, class$load_pair, class$load,
      class$mfpr];                      { 0x419000 }
  su_implicit = [class$call, class$entry, class$seq, class$limit,
      class$svc, class$return];         { 0x1100A14 }
  su_fp_ops = [class$fp_double, class$immediate,
      class$fp_single];                 { 0x20108 }
  su_fp_users = [class$fp_control, class$store];    { 0x201000 }
  su_calls = [class$call, class$entry, class$svc, class$return];
                                        { 0x1100014 }
  su_branches = [class$branch, class$fp_branch, class$jump];    { 98 }
  su_unordered = [class$branch, class$fp_branch, class$jump,
      class$label];                     { 0x80062 }

type
  { instruction_attributes' operand descriptions as the delays read
    them: +4k+2 bits 7..6 (1 or 2: no delay) and the delay (bits
    5..2). }
  su_attr_opnd_t = packed record
    form: 0..255;                       { +4k }
    num: 0..255;                        { +4k+1 }
    kind2: 0..3;                        { +4k+2 .7..6 }
    delay: 0..15;                       { .5..2 }
    b2_1_0: 0..3;
    b3: 0..255;                         { +4k+3 }
  end;
  su_attr_ptr_t = ^su_attr_t;
  su_attr_t = record
    w0: 0..65535;                       { +0 }
    w2: 0..65535;                       { +2 }
    opnds: array [1..4] of su_attr_opnd_t;   { +4 }
  end;

  { An instruction's +28 as SCHED uses it (batch A's instr_t l28, the
    location after ASM): the precedence height, a word. }
  su_instr_ptr_t = ^su_instr_t;
  su_instr_t = record
    space0: array [0..27] of char;
    height: integer;                    { +28 }
  end;

var
  su_0: boolean;                        { +0 }

{ SCHED_UTILS_$BEGIN_COMPILATION, _INIT_FOR_ROUTINE, _END_ROUTINE,
  _END_COMPILATION - nothing.  0x2791B2, 0x2791B4, 0x2791B6, 0x2791B8,
  2 bytes each (no A5). }

procedure sched_utils_$begin_compilation;
begin
end;

procedure sched_utils_$init_for_routine;
begin
end;

procedure sched_utils_$end_routine;
begin
end;

procedure sched_utils_$end_compilation;
begin
end;

{ driving_instruction - the instruction that defines lts (its first
  reference's), nil when lts is nil, not written or not referred to.

  0x2791BA, 0x2E bytes, internal: lts by value; `moveq #12; and.w
  (A2)' (write, modify); A0. }

function driving_instruction(
    lts: lts_ptr_t): instr_ptr_t; options(val_param); internal;
begin
  if (lts = nil) or not ((rrp$write in lts^.rrp) or (rrp$modify in lts^.rrp)) or
     (lts^.refs = nil) then
    driving_instruction := nil
  else
    driving_instruction := utils_ins_$operands_instruction(lts^.refs);
end;

{ sched_utils_$kodiak_delay - the floating unit's latency of opc with
  -CPU KODIAK: for a floating operation (classes fp_double, immediate,
  fp_single) DIVI 9, SQRTS 8, DIVS 4, SQRTD 15, DIVD 8 and 0 for the
  others; d for any other opcode.

  0x2791E8, 0x7E bytes, internal (no A5): opc a word, d a longword;
  D0.  A jump table of 7 from 179 (`subi.w #179; cmpi.w #7; bcc'). }

function sched_utils_$kodiak_delay(
    opc: integer;
    d: integer32): integer32; options(val_param); internal;
begin
  if instruction_attributes[opc].class in su_fp_ops then
    case opc of
      179: d := 9;                      { divi }
      180: d := 8;                      { sqrts }
      182: d := 4;                      { divs }
      183: d := 15;                     { sqrtd }
      185: d := 8;                      { divd }
      otherwise
        d := 0;
    end;
  sched_utils_$kodiak_delay := d;
end;

{ SCHED_UTILS_$OPERAND_DELAY - the delay (cycles) of op, an operand of
  instr.  A register operand the listing shows takes its descriptor's
  delay; one it does not show (an implicit operand) takes that of the
  operand it modifies (the intend_to_modify read of the same live range
  before it; a pair's odd half its mate's).  With flags' bit 1 (from
  the definition): an integer result read by a branch-like
  instruction's operand 1, or a load's result read once by a single
  reader with a count, costs one more; a floating result one more when
  its single reader is a store or a floating control instruction.
  Without it (from the reader): an integer read with a count of a
  load's result costs one more, a store's or floating control's read
  of a floating operation's result too.  Condition codes take the
  opcode's delay (+15 bits 7..4), a read one more with flags' bit 0.

  0x279266, 0x5E8 bytes: instr, op by value, flags a word (its low
  byte tested: `btst #1,(17,A6)'); D0, a longword.  The opcode's
  attributes at -36, opc times 20 at -42; the operand kind's jump
  table of 29 (physical registers and kinds above 28 a bug check).
  KODIAK is cargs_$options.cpu's element 7 (`btst #1,0x4437F4').  The
  searches for the modified operand count down from the operand
  before op (`dbf'); without one, a bug check (and, for a pair, the
  flags' tests after it). }

function sched_utils_$operand_delay;
label
  50, 99;
var
  a: ^instr_attr_t;
  av: su_attr_ptr_t;
  n: integer32;
  d: integer32;
  k: integer32;
  j: integer32;
  i: instr_ptr_t;
  o: opnd_ptr_t;
  lr: lr_ptr_t;
begin
  a := addr(instruction_attributes[instr^.opc]);
  av := su_attr_ptr_t(a);
  n := a^.nresults;
  d := 0;
  case ord(op^.h.kind) of
    0, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
    26, 27, 28:
      ;

    1: begin                            { ip_reg }
      k := op^.h.num;
      if k <= n then begin
        if not (av^.opnds[k].kind2 in [1, 2]) then
          d := av^.opnds[k].delay;
        if 1 in flags then begin
          if op^.h.write then
            if op^.link <> nil then begin
              o := op^.link;
              if o^.h.num = 1 then begin
                if instruction_attributes[utils_ins_$operands_instruction(o)^.opc].class
                   in su_branchy then
                  d := d + 1;
              end
              else if a^.class in su_loads then
                if o^.link = nil then
                  if o^.h.count <> 0 then
                    d := d + 1;
            end;
        end
        else if op^.h.count <> 0 then begin
          i := driving_instruction(op^.lts);
          if i <> nil then
            if instruction_attributes[i^.opc].class in su_loads then
              d := d + 1;
        end;
      end
      else if not (a^.class in su_implicit) then
        if op^.h.modify then begin
          lr := op^.lts^.lr;
          for j := k - 1 downto 1 do
            if instr^.opnds[j].h.intend_to_modify and
               (instr^.opnds[j].h.kind = operand$ip_reg) and
               (instr^.opnds[j].lts^.lr = lr) then begin
              if j <= n then
                d := av^.opnds[j].delay;
              goto 99;
            end;
          bug_check('SCHED_UTILS_$OPERAND_DELAY -- could not find associate ip_reg read/intend_to_modify operand%$');
        end;
    end;

    2: begin                            { fp_reg }
      k := op^.h.num;
      if k <= n then begin
        if not (av^.opnds[k].kind2 in [1, 2]) then begin
          d := av^.opnds[k].delay;
          if 7 in cargs_$options.cpu then
            if op^.h.write or op^.h.modify then
              d := sched_utils_$kodiak_delay(instr^.opc, d);
        end;
        if 1 in flags then begin
          if op^.h.write or op^.h.modify then
            if a^.class in su_fp_ops then
              if op^.link <> nil then
                if op^.link^.link = nil then
                  if instruction_attributes[utils_ins_$operands_instruction(op^.link)^.opc].class
                     in su_fp_users then
                    d := d + 1;
        end
        else if a^.class in su_fp_users then begin
          i := driving_instruction(op^.lts);
          if i <> nil then
            if instruction_attributes[i^.opc].class in su_fp_ops then
              d := d + 1;
        end;
      end
      else if not (a^.class in su_implicit) then
        if op^.h.modify then begin
          lr := op^.lts^.lr;
          for j := k - 1 downto 1 do
            if instr^.opnds[j].h.intend_to_modify and
               (instr^.opnds[j].h.kind = operand$fp_reg) and
               (instr^.opnds[j].lts^.lr = lr) then begin
              if j <= n then begin
                d := av^.opnds[j].delay;
                if 7 in cargs_$options.cpu then
                  d := sched_utils_$kodiak_delay(instr^.opc, d);
              end;
              goto 99;
            end;
          bug_check('SCHED_UTILS_$OPERAND_DELAY -- could not find associate fp_reg read/intend_to_modify operand%$');
        end;
    end;

    3: begin                            { fp_reg_pair }
      k := op^.h.num;
      if k <= n then begin
        if op^.h.fp_reg_odd_only then
          bug_check('SCHED_UTILS_$OPERAND_DELAY -- explicit odd fp_reg_pair operand%$');
        if not (av^.opnds[k].kind2 in [1, 2]) then begin
          d := av^.opnds[k].delay;
          if 7 in cargs_$options.cpu then
            if op^.h.write or op^.h.modify then
              d := sched_utils_$kodiak_delay(instr^.opc, d);
        end;
      end
      else if not (a^.class in su_implicit) then begin
        if op^.h.fp_reg_odd_only then begin
          o := lir_utils_$find_mate_operand(op);
          d := av^.opnds[o^.h.num].delay;
          if 7 in cargs_$options.cpu then
            if op^.h.write or op^.h.modify then
              d := sched_utils_$kodiak_delay(instr^.opc, d);
        end
        else if op^.h.modify then begin
          lr := op^.lts^.lr;
          for j := k - 1 downto 1 do
            if instr^.opnds[j].h.intend_to_modify and
               (instr^.opnds[j].h.kind = operand$fp_reg_pair) and
               (instr^.opnds[j].lts^.lr = lr) then begin
              if j <= n then begin
                d := av^.opnds[j].delay;
                if 7 in cargs_$options.cpu then
                  d := sched_utils_$kodiak_delay(instr^.opc, d);
              end;
              goto 50;
            end;
          bug_check('SCHED_UTILS_$OPERAND_DELAY -- could not find associate fp_reg_pair read/intend_to_modify operand%$');
        end
        else
          bug_check('SCHED_UTILS_$OPERAND_DELAY -- non-explicit even / read or write (not modify) fp_reg_pair operand%$');
      end;
50:
      if 1 in flags then begin
        if op^.h.write or op^.h.modify then
          if a^.class in su_fp_ops then
            if op^.link <> nil then
              if op^.link^.link = nil then
                if instruction_attributes[utils_ins_$operands_instruction(op^.link)^.opc].class
                   in su_fp_users then
                  d := d + 1;
      end
      else if a^.class in su_fp_users then begin
        i := driving_instruction(op^.lts);
        if i <> nil then
          if instruction_attributes[i^.opc].class in su_fp_ops then
            d := d + 1;
      end;
    end;

    7: begin                            { ip_condition_codes }
      d := rshft(a^.b15, 4);
      if 0 in flags then
        if op^.h.read then
          d := d + 1;
    end;

    8:                                  { fp_condition_codes }
      d := rshft(a^.b15, 4);

    otherwise
      bug_check('SCHED_UTILS_$OPERAND_DELAY -- unknown operand kind%$');
  end;
99:
  sched_utils_$operand_delay := d;
end;

{ SCHED_UTILS_$FILL_IN_OPERAND_DELAYS - every operand of bb's
  instructions gets its delay (+2 bits 3..0).

  0x279A42, 0x76 bytes: bb, flags (a word; oli pushes 1 and trace 0
  as one longword, sched's pass 1 2 and the switches' sw9) and trace
  (a byte, not read). }

procedure sched_utils_$fill_in_operand_delays;
var
  i: instr_ptr_t;
  k: integer32;
begin
  i := bb^.first;
  while i <> nil do begin
    for k := 1 to i^.h.nopnds do
      i^.opnds[k].h.b2_3_0 :=
          sched_utils_$operand_delay(i, addr(i^.opnds[k]), flags) & 15;
    i := i^.next;
  end;
end;

{ calculate_precedence - the height of lts's definition: 1 for a
  segment not written (or not referred to); else the definition's
  delay plus its instruction's height, the largest over the registers
  and condition codes it reads of their heights plus their delays (at
  least 1), computed once (+28; -1 while it is computed: a cycle is
  reported).

  0x279AB8, 0x11C bytes, internal, recursive: lts by value; D0 a word.
  The reads: kinds 1..11 (the mask 4094), +1 bit 4; the largest by an
  unsigned compare (`cmp.w; bls'). }

function calculate_precedence(
    lts: lts_ptr_t): integer; options(val_param); internal;
var
  i: instr_ptr_t;
  k: integer32;
  best: integer;
  h: integer;
begin
  if (lts^.refs = nil) or not ((rrp$write in lts^.rrp) or (rrp$modify in lts^.rrp)) then begin
    calculate_precedence := 1;
    return;
  end;
  i := utils_ins_$operands_instruction(lts^.refs);
  if su_instr_ptr_t(i)^.height <> 0 then begin
    if su_instr_ptr_t(i)^.height = -1 then
      bug_check('SCHED_UTILS_$calculate_precedence: deadlocked on BB#%3ZWD:%3ZWD%$',
                lts^.bb^.num, i^.num);
  end
  else begin
    su_instr_ptr_t(i)^.height := -1;
    best := 1;
    for k := 1 to i^.h.nopnds do
      if i^.opnds[k].h.kind in [operand$ip_reg..operand$fp_condition_codes] then
        if i^.opnds[k].h.read then begin
          h := calculate_precedence(i^.opnds[k].lts) + i^.opnds[k].h.b2_3_0;
          if h > best then
            best := h;
        end;
    su_instr_ptr_t(i)^.height := best;
  end;
  calculate_precedence := lts^.refs^.h.b2_3_0 + su_instr_ptr_t(i)^.height;
end;

{ SCHED_UTILS_$CALCULATE_PRECEDENCE - the heights of bb's instructions:
  from the segments final in bb, and from the reads of the branches
  that end it; every instruction but a branch or a label must have
  one.

  0x279BC4, 0x118 bytes: bb, p2 (a byte, kept at A5+0).  The final
  segments from bb +66 (chained at +20); the branches (classes 1, 5,
  6: the mask 98) from bb +38 back (+8); the check's classes the mask
  0x80062. }

procedure sched_utils_$calculate_precedence;
var
  i: instr_ptr_t;
  lts: lts_ptr_t;
  k: integer32;
begin
  i := bb^.first;
  while i <> nil do begin
    su_instr_ptr_t(i)^.height := 0;
    i := i^.next;
  end;
  su_0 := p2;
  lts := bb^.finals;
  while lts <> nil do begin
    discard(calculate_precedence(lts));
    lts := lts^.next_final;
  end;
  i := bb^.last;
  while i <> nil do begin
    if not (instruction_attributes[i^.opc].class in su_branches) then
      exit;
    for k := 1 to i^.h.nopnds do
      if i^.opnds[k].h.kind in [operand$ip_reg..operand$fp_condition_codes] then
        if i^.opnds[k].h.read then
          discard(calculate_precedence(i^.opnds[k].lts));
    i := i^.prev;
  end;
  i := bb^.first;
  while i <> nil do begin
    if su_instr_ptr_t(i)^.height = 0 then
      if not (instruction_attributes[i^.opc].class in su_unordered) then
        bug_check('SCHED_UTILS_$calculate_precedence: no precedence on BB#%3ZWD:%3ZWD%$',
                  bb^.num, i^.num);
    i := i^.next;
  end;
end;

{ test_phys_lr - whether lr is a physical register's live range (+3
  bit 7) without +3 bit 5.

  0x279D20, 0x16 bytes, internal, no frame: `tst.b (3,A0); smi', `btst
  #5; seq', `and.b'. }

function test_phys_lr(
    lr: lr_ptr_t): boolean; options(val_param); internal;
begin
  test_phys_lr := lr^.f2.physical and not lr^.f2.serialize;
end;

{ check_snuggle_writes - an instruction writing a physical register
  (an operand 1..6 kind, neither read nor unconsumed, tied to a reader)
  has the copy moved next to it (lir_utils_$trans_insert_move on the
  readers of each physical result that a call, the entry, an SVC or a
  RETURN reads) when it writes something else too (before or after),
  or when a value it reads is modified there or is not the live
  range's first segment in the block and not final.  A modify of a
  physical register (but at a join birthpoint) and a physical result
  with more than one reader are reported, as is a physical result
  read by any other instruction.  A pair's odd half is skipped.

  0x279D36, 0x342 bytes, internal: instr by value; the write seen at
  -26, the operand's number at -24 (counted with -30).  The masks:
  1..11 4094, 1..6 126, the pair kinds 16456 (3, 6, 14), neither read
  nor unconsumed `and.w #80'.  The reader's +2 bit 6. }

procedure check_snuggle_writes(
    instr: instr_ptr_t); options(val_param); internal;
label
  50;
var
  seen: boolean;
  k: integer32;
  j: integer32;
  op: opnd_ptr_t;
  o: opnd_ptr_t;
  last: opnd_ptr_t;
  l: lts_ptr_t;
  lr: lr_ptr_t;
  n: integer32;
  r: instr_ptr_t;
begin
  seen := false;
  for k := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$fp_condition_codes] then
      if not ((op^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                              operand$fp_reg_pair_like]) and
              op^.h.fp_reg_odd_only) then begin
        if (op^.link <> nil) and
           (op^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical]) and
           ((opnd_bytes_ptr_t(op)^.rrp & 16#50) = 0) and
           test_phys_lr(op^.lts^.lr) then begin
          lr := op^.lts^.lr;
          if op^.h.modify then
            if instr^.opc <> ord(opc$join_bp) then begin
              n := op^.lts^.f2.num;
              instr_bug_check('COM_$PRESCAN_INST: Modify reference on physical register: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                              instr^, lr^.num, n, instr^.bb^.num, instr^.num);
            end;
          if op^.link^.link <> nil then begin
            n := op^.lts^.f2.num;
            instr_bug_check('COM_$PRESCAN_INST: Multiple physical outputs: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                            instr^, op^.lts^.lr^.num, n, instr^.bb^.num, instr^.num);
          end;
          if seen then
            goto 50;
          for j := k + 1 to instr^.h.nopnds do begin
            o := addr(instr^.opnds[j]);
            if o^.h.kind in [operand$ip_reg..operand$fp_condition_codes] then
              if o^.h.write or o^.h.modify then
                if not ((o^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                                       operand$fp_reg_pair_like]) and
                        o^.h.fp_reg_odd_only) then
                  goto 50;
          end;
          for j := 1 to instr^.h.nopnds do begin
            o := addr(instr^.opnds[j]);
            if o^.h.kind in [operand$ip_reg..operand$fp_condition_codes] then
              if o^.h.read then
                if not ((o^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                                       operand$fp_reg_pair_like]) and
                        o^.h.fp_reg_odd_only) then begin
                  last := o;
                  while last^.link <> nil do
                    last := last^.link;
                  if last^.h.intend_to_modify then
                    goto 50;
                  l := last^.lts;
                  if not l^.f2.first_in_bb then
                    if l^.lr^.id <> 0 then
                      if not l^.f2.final then
                        goto 50;
                end;
          end;
        end
        else if op^.h.write or op^.h.modify then
          seen := true;
      end;
  end;
  return;

50:
  for j := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[j]);
    if op^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
      if (opnd_bytes_ptr_t(op)^.rrp & 16#50) = 0 then
        if test_phys_lr(op^.lts^.lr) then
          if op^.link <> nil then
            if not ((op^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                                    operand$fp_reg_pair_like]) and
                    op^.h.fp_reg_odd_only) then begin
              r := utils_ins_$operands_instruction(op^.link);
              if r^.h.b2_6 then
                if instruction_attributes[r^.opc].class in su_calls then
                  lir_utils_$trans_insert_move(op)
                else if instr^.opc <> ord(opc$join_bp) then
                  instr_bug_check('COM_$PRESCAN_INST: Anomalous physical output: near line %LD%$',
                                  instr^);
            end;
  end;
end;

{ check_snuggle_reads - an instruction reading physical registers has
  each one's copy moved next to it unless every register it reads is
  physical and those of the register kinds come from one definition
  (an instruction, or reads: a definition that is itself a read); a
  condition code read always moves them.  The copy is made when the
  read is the segment's first reference or its definition is a call,
  the entry, an SVC, a RETURN or a join birthpoint; any other is
  reported, as is an intend_to_modify read of a physical register.

  0x27A182, 0x190 bytes, internal: instr by value; the definition
  found in A3 (the value 1 for a definition that reads, `movea.l
  #1,A0').  The condition codes the mask 384. }

procedure check_snuggle_reads(
    instr: instr_ptr_t); options(val_param); internal;
label
  50;
var
  src: integer32;
  s: integer32;
  k: integer32;
  op: opnd_ptr_t;
  def: opnd_ptr_t;
  d: instr_ptr_t;
begin
  src := 0;
  for k := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_condition_codes, operand$fp_condition_codes] then
      goto 50;
    if op^.h.kind in [operand$ip_reg..operand$fp_condition_codes] then
      if op^.h.read then begin
        if not test_phys_lr(op^.lts^.lr) then
          goto 50;
        if op^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
          def := op^.lts^.refs;
          if def^.h.read then
            s := 1
          else
            s := integer32(utils_ins_$operands_instruction(def));
          if src = 0 then
            src := s
          else if src <> s then
            goto 50;
        end;
      end;
  end;
  return;

50:
  for k := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
      if op^.h.read then
        if test_phys_lr(op^.lts^.lr) then begin
          if op^.h.intend_to_modify then
            instr_bug_check('COM_$PRESCAN_INST: Modify reference on physical register: near line %LD%$',
                            instr^);
          d := utils_ins_$operands_instruction(op^.lts^.refs);
          if (op^.lts^.refs = op) or
             (instruction_attributes[d^.opc].class in su_calls) or
             (d^.opc = ord(opc$join_bp)) then
            lir_utils_$trans_insert_move(op)
          else if d^.opc <> ord(opc$join_bp) then
            instr_bug_check('COM_$PRESCAN_INST: Anomalous physical input: near line %LD%$',
                            instr^);
        end;
  end;
end;

{ SCHED_UTILS_$INSERT_SNUGGLE_MOVES - the snuggle moves of every
  instruction but calls, entries, SVCs and RETURNs, in blocks without
  +17 bit 6, the blocks in rtn +72's order (chained at +114).

  0x27A398, 0x7E bytes: rtn by value. }

procedure sched_utils_$insert_snuggle_moves;
var
  bb: bb_ptr_t;
  i: instr_ptr_t;
begin
  bb := rtn^.bbs72;
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      if not (instruction_attributes[i^.opc].class in su_calls) then
        if not bb^.f.atomic then begin
          check_snuggle_writes(i);
          check_snuggle_reads(i);
        end;
      i := i^.next;
    end;
    bb := bb^.next114;
  end;
end;
