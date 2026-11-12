{ sem_utils - the semantics of instructions: how many of an input
  operand's low-order bits the instruction reads (com and konst use it
  to narrow loads and constants).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x27A418  sem_utils_$begin_compilation
    --------  0x27A41A  sem_utils_$init_for_routine
    --------  0x27A41C  sem_utils_$end_routine
    --------  0x27A41E  sem_utils_$end_compilation
    --------  0x27A420  contiguous_high_order_zero_bits (internal)
    --------  0x27A44E  contiguous_high_order_one_bits (internal)
    --------  0x27A47E  sem_utils_$number_of_relevant_low_order_bits
    A5 0x492E74 (sym's): the module has no data.

  The four entry points are a lone `rts' each (at_backend calls them,
  init_for_routine and end_routine with the routine).  The unit opens utils.ins.pas but has
  no copy of utils_ins_$operands_instruction: number_of_relevant_low_
  order_bits computes the operand's instruction itself.

  Not known from the original: the parameters' and locals' names. }
module sem_utils;

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

{ sem_utils_$begin_compilation - nothing.  0x27A418, 2 bytes. }

procedure sem_utils_$begin_compilation;
begin
end;

{ sem_utils_$init_for_routine - nothing.  0x27A41A, 2 bytes (at_backend
  passes the routine). }

procedure sem_utils_$init_for_routine(
    rtn: rtn_ptr_t);
begin
end;

{ sem_utils_$end_routine - nothing.  0x27A41C, 2 bytes (at_backend
  passes the routine). }

procedure sem_utils_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ sem_utils_$end_compilation - nothing.  0x27A41E, 2 bytes. }

procedure sem_utils_$end_compilation;
begin
end;

{ contiguous_high_order_zero_bits - the number of contiguous one bits
  at the top of x (the name says zero: the routine stops at the first
  zero bit).

  0x27A420, 0x2E bytes, internal: x by value; the mask from 16#80000000
  shifted right (`lsr.l #1') while `and.l' with x is nonzero; the count
  in D1, then D0. }

function contiguous_high_order_zero_bits(
    x: integer32): integer32; options(val_param); internal;
var
  mask: integer32;
  n: integer32;
begin
  mask := 16#80000000;
  n := 0;
  while (x & mask) <> 0 do begin
    n := n + 1;
    mask := rshft(mask, 1);
    if mask = 0 then
      exit;
  end;
  contiguous_high_order_zero_bits := n;
end;

{ contiguous_high_order_one_bits - the number of contiguous zero bits
  at the top of x (the name says one: the routine stops at the first
  one bit).

  0x27A44E, 0x30 bytes, internal: as contiguous_high_order_zero_bits
  with the test reversed (`bne' out). }

function contiguous_high_order_one_bits(
    x: integer32): integer32; options(val_param); internal;
var
  mask: integer32;
  n: integer32;
begin
  mask := 16#80000000;
  n := 0;
  while (x & mask) = 0 do begin
    n := n + 1;
    mask := rshft(mask, 1);
    if mask = 0 then
      exit;
  end;
  contiguous_high_order_one_bits := n;
end;

{ sem_utils_$number_of_relevant_low_order_bits - how many low-order
  bits of input operand o the instruction reads: 32 unless the opcode
  says less (and, or, bic with an immediate mask; extend0/7/15, widenb,
  tstb, tstw; lsl by an immediate; insert, clrins and the extracts by
  the field width), 5 for an operand whose form is
  of$ip_reg_or_u_immed5 among the opcode's results, less o's count.

  0x27A47E, 0x1B8 bytes: the instruction from o's address less 32 and
  12 times its num (`move.b (A0)', times 12 by `lsl.l #2' and the
  double added); its opcode in D2.  bug_check unless o's read bit
  (`btst #4,(1,A0)').  For operand 1: the case on the opcode as a
  compare chain (84 and, 85 or, 214 bic, 87 extend0, 88 extend7, 98
  widenb, 71 tstb, 89 extend15, 72 tstw, 92 lsl, 96 insert, 94 clrins,
  97 extractu, 95 transfer, 93 isolate) testing operand 2's kind
  (`moveq #31; and.b (59,A2)' against 23, immediate) and value (+64);
  for operand 2, and/or/bic test operand 1's (+47, +52).  The masks'
  counts are subtracted from 32 (`moveq #32; sub.l').  Then the
  opcode's attributes (instruction_attributes, 20 bytes each): if o's
  num <= nresults (+11 bits 2..0) and the form byte at +4 * num is 16,
  5.  Last o's count (+2 bits 5..4, `and.b #48; lsr.l #4') subtracted. }

function sem_utils_$number_of_relevant_low_order_bits(
    o: opnd_ptr_t): integer32; options(val_param);
var
  k: integer32;
  instr: instr_ptr_t;
  opc: opc$w_t;
  n: integer32;
begin
  k := o^.h.num;
  instr := instr_ptr_t(integer32(o) - 32 - k * 12);
  opc := instr^.opc;
  if not o^.h.read then
    bug_check('SEM_UTILS_$NUMBER_OF_RELEVANT_LOW_ORDER_BITS -- operand is not an input%$');
  n := 32;
  if k = 1 then begin
    case opc of
      84:                               { and }
        if instr^.opnds[2].h.kind = operand$immediate then
          n := 32 - contiguous_high_order_zero_bits(instr^.opnds[2].value);
      85, 214:                          { or, bic }
        if instr^.opnds[2].h.kind = operand$immediate then
          n := 32 - contiguous_high_order_one_bits(instr^.opnds[2].value);
      87:                               { extend0 }
        n := 1;
      88, 98, 71:                       { extend7, widenb, tstb }
        n := 8;
      89, 72:                           { extend15, tstw }
        n := 16;
      92:                               { lsl }
        if instr^.opnds[2].h.kind = operand$immediate then
          n := 32 - instr^.opnds[2].value;
      96, 94:                           { insert, clrins }
        n := instr^.h.width;
      97, 95, 93:                       { extractu, transfer, isolate }
        if (instr^.opnds[2].h.kind = operand$immediate)
           and (instr^.opnds[2].value = 0) then
          n := instr^.h.width;
      otherwise
    end;
  end
  else if k = 2 then begin
    case opc of
      84:
        if instr^.opnds[1].h.kind = operand$immediate then
          n := 32 - contiguous_high_order_zero_bits(instr^.opnds[1].value);
      85, 214:
        if instr^.opnds[1].h.kind = operand$immediate then
          n := 32 - contiguous_high_order_one_bits(instr^.opnds[1].value);
      otherwise
    end;
  end;
  with instruction_attributes[opc] do
    if (nresults >= k) and (k >= 1) and (k <= 4) then begin
      case k of
        1: if b4 = 16 then n := 5;
        2: if form2 = 16 then n := 5;
        3: if b12 = 16 then n := 5;
        4: if b16 = 16 then n := 5;
      end;
    end;
  sem_utils_$number_of_relevant_low_order_bits := n - o^.h.count;
end;
