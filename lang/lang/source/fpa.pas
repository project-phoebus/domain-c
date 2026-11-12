{ fpa - the m68k code generator's code for the FPA1 floating-point
  accelerator (-CPU FPA1): its operations are moves to and from the
  accelerator's command addresses (an FPA register operand, mode 16,
  whose y is the command: the operation's base from fpa_ops plus the
  registers' fields), between its registers (emit_reg_reg) or with
  memory (emit_mem_reg, emit_load_store, by halves for a double); the
  assignments, arithmetic, negation, math functions, conversions and
  comparisons the code generator asks for.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0B7A8C  --------  ra_fpreg
    0x0B7AAC  --------  rb_fpreg
    0x0B7ACA  --------  check_postincr
    0x0B7AEC  --------  check_ads
    0x0B7B58  --------  emit_reg_reg
    0x0B7C8E  --------  emit_load_store
    0x0B7F54  --------  emit_assign
    0x0B805A  --------  emit_mem_reg
    0x0B8246  --------  emit_mul_add
    0x0B831C  --------  emit_div_sub
    0x0B849C  --------  emit_neg
    0x0B8652  --------  emit_fmath_top
    0x0B8864  --------  emit_extend
    0x0B8B7E  --------  emit_compare
    0x0B8E0A  --------  emit_jsr
    0x0B9314  --------  load_c16_part
    0x0B9472  --------  push_fpa_opr
    0x0B996E  --------  emit_clr_fp1
    0x0B9A0C  --------  fpa_fop_proc
    0x0B9BBC  --------  fpa_temp
    A5 0x2CE7CC (cc.m68k): the module's data, 0xF0 bytes, all set by
    .rwdi: +0x0 fpa_ops, the commands' bases of the FPA operations
    461..501 (read as A5 - 1844 + op * 4, -1840 for op + 1; +0x80..
    +0x88 by name: 493..495); +0xA8, +0xC0, +0xD8 three operand
    descriptors 24 bytes apart (a data register, the FPA register
    operand whose f2, f3, f6 and y the routines set, the
    register-to-register operations' other operand).

  Every routine loads A5 (global); those only this unit calls are
  declared here, the others in fpa.ins.pas.  The FPA registers' flags
  of cg_top's data (+0x110, cg_top_fp_long: a double kept in the
  register) are set absolutely.

  Not known from the original: the names of the module's variables
  and of the locals; the meaning of the commands' fields (ra_fpreg's
  and rb_fpreg's shifts) and of the FPA operation numbers (461..501).

  dpc gaps (docs/dpc-gaps.md): 7 (the constant -1.0), 8 (`in' on
  emit_jsr's operations).
}

{ TODO(pascal) fpa.pas is unfinished: four routines not written

  push_fpa_opr (0x0B9472, 0x4FC bytes), emit_clr_fp1 (0x0B996E, 0x96),
  fpa_fop_proc (0x0B9A0C, 0x1B0) and fpa_temp (0x0B9BBC, 0x94) are not
  translated yet (fpa.ins.pas declares them). }

module fpa;

%include 'us/us/ins/ubase.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/fpa.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

var
  { The module's data (A5 0x2CE7CC). }
  fpa_ops: array [461..501] of integer32 := [
      16#8006, 16#8002, 16#801E, 16#801A, 16#8001, 16#8005, 16#8009,
      16#800D, 16#8011, 16#8015, 16#8001, 16#800D, 16#8000, 16#8004,
      16#8008, 16#800C, 16#801C, 16#8024, 16#8028, 16#8010, 16#8010,
      16#8014, 16#8018, 16#8000, 16#8004, 16#8008, 16#8000, 16#8004,
      16#8008, 16#801C, 16#8024, 16#8028, 16#800C, 16#8014, 16#8018,
      16#802C, 16#8014, 16#8018, 16#802C, 16#8016, 16#8012];  { +0x0 }
  fpa_a4: integer32 := 0;               { +0xA4: not addressed }
  fpa_dreg: codegen_$uads_t := [f1 := 1, f2 := 31, f3 := 31, f4 := 0,
      f5 := 5, f6 := 0, x := 0, y := 0];        { +0xA8: a data register
                                                  (emit_compare's
                                                  condition) }
  fpa_bc: integer32 := 0;               { +0xBC: not addressed }
  fpa_reg: codegen_$uads_t := [f1 := 16, f2 := 31, f3 := 31, f4 := 0,
      f5 := 5, f6 := 0, x := 0, y := 0];        { +0xC0: the FPA register
                                                  operand }
  fpa_d4: integer32 := 0;               { +0xD4: not addressed }
  fpa_none: codegen_$uads_t := [f1 := 0, f2 := 31, f3 := 31, f4 := 0,
      f5 := 5, f6 := 0, x := 0, y := 0];        { +0xD8: the other operand
                                                  of a register-to-register
                                                  operation }
  fpa_ec: integer32 := 0;               { +0xEC: not addressed }

  { cg_top.pas's data +0x110 (0x356424, absolute): the FPA registers
    holding a double. }
  cg_top_fp_long: extern array [16..23] of boolean;

{ ra_fpreg, rb_fpreg - FPA register r's field in a command: (r - 16)
  shifted left 10 (the first register) or 6 (the second).

  0x0B7A8C, 0x20 bytes; 0x0B7AAC, 0x1E bytes: link #-4, A5 loaded;
  `lsl.w #8; lsl.w #2', `lsl.w #6'. }

function ra_fpreg(
    r: integer): integer; options(val_param);
begin
  ra_fpreg := lshft(r - 16, 10);
end;

function rb_fpreg(
    r: integer): integer; options(val_param);
begin
  rb_fpreg := lshft(r - 16, 6);
end;

{ check_postincr - operand a's displacement less 4 for mode 8 (the
  second half of a double through (An)+).

  0x0B7ACA, 0x22 bytes, link #0: `subq.l #4,(16,A0)'. }

procedure check_postincr(
    var a: codegen_$uads_t);
begin
  if a.f1 = 8 then
    a.y := a.y - 4;
end;

{ check_ads - operand a of mode 9 (-(An)) made (An) after the address
  register is lowered by 8 (emit 2 of a word: a register operand t and
  the immediate 8).

  0x0B7AEC, 0x6C bytes, link #-48: t's f1, f2, x, f4 and f5 stored (f3,
  f6 and y not); anyconst(8, 1, c); emit's operation and size pushed as
  one longword (docs/rev889-patterns.md 54). }

procedure check_ads(
    var a: codegen_$uads_t);
var
  c: codegen_$uads_t;
  t: codegen_$uads_t;
begin
  if a.f1 = 9 then begin
    t.f1 := 1;
    t.f2 := a.f2;
    t.x := 0;
    t.f4 := 0;
    t.f5 := 0;
    anyconst(8, 1, c);
    emit(2, 2, t, c, 0);
    a.f1 := 2;
  end;
end;

{ emit_reg_reg - FPA operation op of size size between registers a and
  b (f6 the form): the command fpa_ops[op] plus a's and b's fields (the
  register fields swapped for 461..464, 500, 501), emitted as emit
  operation eop with the FPA register operand as the source of a move
  to the data register fpa_dreg (to_dreg: a comparison) or as the
  destination with fpa_none; a double, and 470..472, mark both
  registers' cg_top_fp_long.

  0x0B7B58, 0x136 bytes, link #-4: every parameter by address; the
  operations compared in turn (462, 461, 501, 500, 464, 463; 471,
  472, 470); the sum's first part kept at -4; the flags `st' through
  0x356424 - 16. }

procedure emit_reg_reg(
    in op: integer;
    in size: integer;
    in a: codegen_$uads_t;
    in b: codegen_$uads_t;
    in f6: integer;
    in eop: integer;
    in to_dreg: boolean);
var
  y: integer32;
begin
  fpa_reg.f2 := a.f2;
  fpa_reg.f3 := b.f2;
  fpa_reg.f6 := f6;
  if (op = 462) or (op = 461) or (op = 501) or (op = 500) or (op = 464) or
     (op = 463) then begin
    y := rb_fpreg(a.f2) + fpa_ops[op];
    fpa_reg.y := ra_fpreg(b.f2) + y;
  end
  else begin
    y := ra_fpreg(a.f2) + fpa_ops[op];
    fpa_reg.y := rb_fpreg(b.f2) + y;
  end;
  if to_dreg then
    emit(eop, size, fpa_dreg, fpa_reg, 0)
  else
    emit(eop, size, fpa_reg, fpa_none, 0);
  if (size = 7) or (op = 471) or (op = 472) or (op = 470) then begin
    cg_top_fp_long[a.f2] := true;
    cg_top_fp_long[b.f2] := true;
  end;
end;

{ emit_load_store - see fpa.ins.pas: a plain move (emit 0) unless a is
  an FPA register (13); else FPA operation op (493 load, 496 a load of
  an integer, 497 and 499 stores) of FPA register a with memory
  operand b: an integer narrower than a long through a scratch data
  register extended to a long (its register's lock count raised when b
  is one); a double's second half first (op + 1, size 6, at y + 4 or the
  constant's second longword +16), then the first (the constant's
  +12); 494, 495 and 498 nothing; a double or 496 marks the register's
  cg_top_fp_long.

  0x0B7C8E, 0x298 bytes, link #-76: b copied to t (-24) twice; the
  size compared unsigned (`bcc', `bcs'); a constant's halves through
  smcontk(81, ...) and f6 2; bug_check of 'Unimplemented FPA
  instruction (%4ZWD,%2ZWD)%.' with op and size for another operation
  of a double; a jump table of 7 from 493; the emits' operation and
  size pushed as one longword (0 and 6, 0 and 7). }

procedure emit_load_store;
var
  t: codegen_$uads_t;
  r: codegen_$uads_t;
begin
  if a.f1 <> 13 then begin
    emit(0, size, a, b, 0);
    return;
  end;
  t := b;
  fpa_reg.f2 := a.f2;
  fpa_reg.f3 := 31;
  fpa_reg.f6 := 1;
  if (size < 4) and (op = 496) then begin
    if t.f1 = 1 then
      unlock(t);
    get_temp_register(il_$node_ptr_t(t.x), size, r);
    if not ((t.f1 = 1) and (t.f2 = r.f2)) then
      emit(0, size, r, t, 0);
    s_extend(r, size, 4);
    unlock(r);
    if b.f1 = 1 then
      cg_addr_locks[b.f2] := cg_addr_locks[b.f2] + 1;
  end
  else if size >= 7 then begin
    if t.f1 = 3 then begin
      t.x := integer32(smcontk(81, il_$node_ptr_t(b.x)^.xl[4]));
      t.f6 := 2;
      t.y := 0;
    end
    else if t.f1 <> 9 then begin
      check_postincr(t);
      t.y := t.y + 4;
    end;
    fpa_reg.y := ra_fpreg(a.f2) + fpa_ops[op + 1];
    case op of
      497:
        emit(0, 6, t, fpa_reg, 0);
      493:
        emit(0, 6, fpa_reg, t, 0);
      otherwise
        bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
    end;
    t := b;
    if t.f1 = 3 then
      t.x := integer32(smcontk(81, il_$node_ptr_t(b.x)^.xl[3]));
  end;
  fpa_reg.y := ra_fpreg(a.f2) + fpa_ops[op];
  case op of
    499:
      emit(0, size, t, fpa_reg, 0);
    497:
      emit(0, 7, t, fpa_reg, 0);
    496:
      if size < 4 then
        emit(0, size, fpa_reg, r, 0)
      else
        emit(0, size, fpa_reg, t, 0);
    493:
      emit(0, 7, fpa_reg, t, 0);
    otherwise
      ;
  end;
  if (size = 7) or (op = 496) then
    cg_top_fp_long[a.f2] := true;
end;

{ emit_assign - see fpa.ins.pas: a plain move when neither operand is
  an FPA register; between two, FPA 500 (sizes 1, 2, 4, 6: of size 6)
  or 501 (of the size); a store (499, 497 for a double) from one, a
  load (496 of an integer, 493) into one.

  0x0B7F54, 0x100 bytes, link #-4: a jump table of 6 on the size from
  1; the size compared unsigned (`bhi'); emit_reg_reg's constants after
  emit_load_store's code (0x0B8054 false, 0x0B8056 6, 0x0B8058 0),
  the 0 passed twice (`move.l (SP),-(SP)', docs/rev889-patterns.md
  69). }

procedure emit_assign;
var
  op: integer;
begin
  if (dst.f1 <> 13) and (src.f1 <> 13) then
    emit(0, size, dst, src, 0)
  else if (dst.f1 = 13) and (src.f1 = 13) then begin
    case size of
      1, 2, 4, 6:
        op := 500;
      otherwise
        op := 501;
    end;
    if size <= 4 then
      emit_reg_reg(op, 6, dst, src, 0, 0, false)
    else
      emit_reg_reg(op, size, dst, src, 0, 0, false);
  end
  else if (size = 1) or (size = 2) or (size = 4) then begin
    if src.f1 = 13 then
      emit_load_store(499, src, dst, size)
    else
      emit_load_store(496, dst, src, size);
  end
  else if src.f1 = 13 then
    emit_load_store(497, src, dst, size)
  else
    emit_load_store(493, dst, src, size);
end;

{ emit_mem_reg - FPA operation op of size size on FPA register a and
  memory operand b, emitted as emit operation eop: a single at once
  (the command with a's fields twice); a double by a load of its first
  half (fpa_ops[495] + 0x3C00, emit 77) and the operation on its second
  (the constant's +16, or y + 4); a double marks a's cg_top_fp_long.

  0x0B805A, 0x1EC bytes, link #-52: every parameter by address; the
  command's first part kept at -52; b copied to t (-24) and checked
  (check_ads), its copy u (-48) taken field by field; the two emits
  share their call (0x0B821E). }

procedure emit_mem_reg(
    in op: integer;
    in size: integer;
    in a: codegen_$uads_t;
    in b: codegen_$uads_t;
    in eop: integer);
var
  t: codegen_$uads_t;
  u: codegen_$uads_t;
  y: integer32;
begin
  if size = 6 then begin
    fpa_reg.f2 := a.f2;
    fpa_reg.f3 := 31;
    y := fpa_ops[op] + ra_fpreg(a.f2);
    fpa_reg.y := y + rb_fpreg(a.f2);
    fpa_reg.f6 := 1;
    emit(eop, size, fpa_reg, b, 0);
  end
  else begin
    t := b;
    check_ads(t);
    fpa_reg.y := fpa_ops[495] + 16#3C00;
    fpa_reg.f2 := a.f2;
    fpa_reg.f3 := 31;
    fpa_reg.f6 := 1;
    if t.f1 = 3 then begin
      t.x := integer32(smcontk(81, il_$node_ptr_t(b.x)^.xl[3]));
      t.f6 := 2;
      t.y := 0;
    end;
    emit(77, size, fpa_reg, t, 0);
    check_postincr(t);
    fpa_reg.f2 := a.f2;
    y := fpa_ops[op] + ra_fpreg(a.f2);
    fpa_reg.y := y + rb_fpreg(a.f2);
    fpa_reg.f6 := 1;
    u := t;
    if t.f1 = 3 then
      u.x := integer32(smcontk(81, il_$node_ptr_t(b.x)^.xl[4]))
    else
      u.y := t.y + 4;
    emit(eop, size, fpa_reg, u, 0);
  end;
  if size = 7 then
    cg_top_fp_long[a.f2] := true;
end;

{ emit_mul_add - see fpa.ins.pas: multiplication (45) or addition (43)
  of a single (473, 474; from memory 487, 488) or a double (477, 478;
  491... 490, 491) into FPA register a; another operator leaves the
  operation unset.

  0x0B8246, 0xD4 bytes, link #-28: the operators compared in turn;
  emit_reg_reg's constants 1 (0x0B831A) and false (0x0B8054); op
  passed by its slot. }

procedure emit_mul_add;
var
  fop: integer;
begin
  if b.f1 = 13 then begin
    case op of
      45:
        if size = 6 then
          fop := 473
        else
          fop := 477;
      43:
        if size = 6 then
          fop := 474
        else
          fop := 478;
      otherwise
        ;
    end;
    emit_reg_reg(fop, size, a, b, 1, op, false);
  end
  else begin
    case op of
      45:
        if size = 6 then
          fop := 487
        else
          fop := 490;
      43:
        if size = 6 then
          fop := 488
        else
          fop := 491;
      otherwise
        ;
    end;
    emit_mem_reg(fop, size, a, b, op);
  end;
end;

{ emit_div_sub - see fpa.ins.pas: division (46) or subtraction (44)
  into FPA register a: from a register 476, 475 (singles) or 480, 479;
  a subtraction from memory 489 or 492; a division by memory through a
  register loaded with it (476, 480: b loaded, the register divided
  into a).  bug_check of 'Unimplemented FPA instruction
  (%4ZWD,%2ZWD)%.' with op and size otherwise.

  0x0B831C, 0x180 bytes, link #-28: the operators and sizes compared in
  turn; the register (-24) from get_register for b's node. }

procedure emit_div_sub;
var
  r: codegen_$uads_t;
  fop: integer;
begin
  if b.f1 = 13 then begin
    case op of
      46:
        if size = 6 then
          fop := 476
        else
          fop := 480;
      44:
        if size = 6 then
          fop := 475
        else
          fop := 479;
      otherwise
        bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
    end;
    emit_reg_reg(fop, size, a, b, 1, op, false);
  end
  else if op = 44 then begin
    case size of
      6:
        fop := 489;
      7:
        fop := 492;
      otherwise
        bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
    end;
    emit_mem_reg(fop, size, a, b, op);
  end
  else begin
    case size of
      6:
        fop := 476;
      7:
        fop := 480;
      otherwise
        bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
    end;
    get_register(il_$node_ptr_t(b.x), size, r);
    emit_load_store(493, r, b, size);
    emit_reg_reg(fop, size, a, r, 1, op, false);
    unlock(r);
  end;
end;

{ emit_neg - see fpa.ins.pas: a multiplied by the constant -1 (487 or
  490, emit 45) after b is moved into it (from memory by 493 through
  a's register, locked; between registers 500 or 501).  bug_check of
  'Unimplemented FPA instruction (%4ZWD,%2ZWD)%.' (49 and the size) or
  'Unimplemented FPA assign (%2ZWD)%.' for another size.

  0x0B849C, 0x182 bytes, link #-76: -1.0 the double after the routine
  (0x0B8646) through rlcontk or dpcontk; 49 a longword constant there
  (0x0B864E); 45 the word at 0x0B861E; b's copy checked (check_ads,
  `addq.l #2' leaving the next call's pad, docs/rev889-patterns.md
  51). }

procedure emit_neg;
var
  k: codegen_$uads_t;
  t: codegen_$uads_t;
  r: codegen_$uads_t;
  fop: integer;
begin
  case size of
    6: begin
      fop := 487;
      address(rlcontk(-1.0), 0, k);
    end;
    7: begin
      fop := 490;
      address(dpcontk(-1.0), 0, k);
    end;
    otherwise
      bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', 49, size);
  end;
  if b.f1 <> 13 then begin
    t := b;
    check_ads(t);
    address_reg(a.f2, r);
    cg_addr_locks[r.f2] := cg_addr_locks[r.f2] + 1;
    emit_load_store(493, r, t, size);
    emit_mem_reg(fop, size, r, k, 45);
    unlock(r);
  end
  else begin
    if b.f2 <> a.f2 then
      case size of
        6:
          emit_reg_reg(500, size, a, b, 0, 0, false);
        7:
          emit_reg_reg(501, size, a, b, 0, 0, false);
        otherwise
          bug_check('Unimplemented FPA assign (%2ZWD)%.', size);
      end;
    emit_mem_reg(fop, size, a, k, 45);
  end;
end;

{ emit_fmath_top - see fpa.ins.pas: the 68881 math functions the FPA
  does, 50 (463, 464), 59 (461, 462), 76 (466, 465: single, double): of
  FPA register b into a; from memory through a's register (locked);
  76 always from a's register, loaded first (500, 501 from another FPA
  register, which then also names the operation: the variable is
  reused).  bug_check of 'Unimplemented FPA operation (%4ZWD,%2ZWD)%.'
  with op and size otherwise.

  0x0B8652, 0x1E6 bytes, link #-52: the operators compared in turn;
  76's register-to-register case joins the others' (0x0B8794: written
  twice, docs/rev889-patterns.md 23); the operation's word at -50 overwritten by 500/501; the register (-48)
  unlocked at the end of the paths that took it. }

procedure emit_fmath_top;
var
  t: codegen_$uads_t;
  r: codegen_$uads_t;
  fop: integer;
begin
  case op of
    50:
      if size = 6 then
        fop := 463
      else
        fop := 464;
    59:
      if size = 6 then
        fop := 461
      else
        fop := 462;
    76:
      if size = 6 then
        fop := 466
      else
        fop := 465;
    otherwise
      bug_check('Unimplemented FPA operation (%4ZWD,%2ZWD)%.', op, size);
  end;
  if op = 76 then begin
    if (b.f1 = 13) and (b.f2 = a.f2) then begin
      emit_reg_reg(fop, size, a, b, 0, op, false);
      return;
    end;
    t := b;
    check_ads(t);
    address_reg(a.f2, r);
    cg_addr_locks[r.f2] := cg_addr_locks[r.f2] + 1;
    if t.f1 = 13 then begin
      if size = 7 then
        fop := 501
      else
        fop := 500;
      emit_reg_reg(fop, size, r, t, 0, 0, false);
    end
    else
      emit_load_store(493, r, t, size);
  end
  else if b.f1 = 13 then begin
    emit_reg_reg(fop, size, a, b, 0, op, false);
    return;
  end
  else begin
    t := b;
    check_ads(t);
    address_reg(a.f2, r);
    cg_addr_locks[r.f2] := cg_addr_locks[r.f2] + 1;
    emit_load_store(493, r, t, size);
  end;
  emit_reg_reg(fop, size, a, r, 0, op, false);
  unlock(r);
end;

{ emit_extend - see fpa.ins.pas: from a single or double (from 8 with
  size 6 or 7) a plain emit_assign; else the conversion (to a long or
  a word 467, 468 (of a single), emit 72; to a double 469 (of a
  double) or 471, emit 71; to a single 470 (of a single) or 471, emit
  70) in a register: a's when a is an FPA register (locked), else b's
  own when its object is not cached there and not live (taken over,
  killed), else a new one for b's node; b moved in first (500 of size
  6 for a single source, 501 of size 7 else; from memory 496 for an
  integer, 493), the conversion done in place, the result stored to a
  when a is not one; a single from a long or narrower also gets 469
  with 71.  bug_check of 'Unimplemented FPA extend (%2ZWD,%2ZWD)%.'
  with from and size for another size.

  0x0B8864, 0x2EC bytes, link #-52: a jump table of 6 on the size
  from 2 and one of 6 on from from 1; cg_addr_cache's live tested
  `tst.b (7,A0,D1.w)'; a's register tested `btst' in 0x00FF0000; the
  last call's constants after the routine (0x0B8B50 7, 0x0B8B52 469,
  0x0B8B54 71); from compared unsigned (`bhi'). }

procedure emit_extend;
label
  1;
var
  t: codegen_$uads_t;
  r: codegen_$uads_t;
  o: integer;
  g: integer;
begin
  if (from = 8) and ((size = 7) or (size = 6)) then begin
    emit_assign(size, a, b);
    return;
  end;
  case size of
    7: begin
      if from = 6 then
        o := 470
      else
        o := 471;
      g := 70;
    end;
    6: begin
      if from = 7 then
        o := 469
      else
        o := 471;
      g := 71;
    end;
    2, 4: begin
      if from = 6 then
        o := 468
      else
        o := 467;
      g := 72;
    end;
    otherwise
      bug_check('Unimplemented FPA extend (%2ZWD,%2ZWD)%.', from, size);
  end;
  if (b.f1 = 13) and (b.f2 = a.f2) then
    emit_reg_reg(o, from, a, b, 0, g, false)
  else begin
    t := b;
    check_ads(t);
    if a.f2 in [16..23] then begin
      address_reg(a.f2, r);
      cg_addr_locks[r.f2] := cg_addr_locks[r.f2] + 1;
    end
    else begin
      if t.f1 = 13 then
        if chk_assign(il_$node_ptr_t(t.x), from) <> t.f2 then
          if not cg_addr_cache[t.f2].live then begin
            address_reg(t.f2, r);
            cg_addr_locks[r.f2] := cg_addr_locks[r.f2] + 1;
            kill_register(r.f2);
            goto 1;
          end;
      get_register(il_$node_ptr_t(t.x), from, r);
    end;
  1:
    if (t.f1 = 13) and (t.f2 <> r.f2) then
      case from of
        1, 2, 4, 6:
          emit_reg_reg(500, 6, r, t, 0, 0, false);
        otherwise
          emit_reg_reg(501, 7, r, t, 0, 0, false);
      end
    else if t.f1 <> 13 then
      if (from = 1) or (from = 2) or (from = 4) then
        emit_load_store(496, r, t, from)
      else
        emit_load_store(493, r, t, from);
    emit_reg_reg(o, from, r, r, 0, g, false);
    if a.f1 <> 13 then
      emit_assign(size, a, r);
    unlock(r);
  end;
  if (size = 6) and (from <= 4) then
    emit_reg_reg(469, 7, a, a, 0, 71, false);
end;

{ emit_compare - see fpa.ins.pas: the comparison (cc 6, 7: 484, 481;
  12, 13: 485, 482; 14, 15: 486, 483; single, double) of a and b, each
  first loaded into an FPA register from memory (493), its result
  moved to a data register (fpa_dreg) and tested against 2 (emit 13 of
  a word, x 3); the registers taken for the operands unlocked.
  bug_check of 'Unimplemented FPA branch (%4ZWD,%2ZWD)%.' with cc and
  size for another condition.

  0x0B8B7E, 0x262 bytes, link #-100: a jump table of 10 from 6; emit's
  operation and size one longword (13, 2); true the byte 0xFF after
  the routine (0x0B8DE0); a and b copied (-72, -96) and each copy's
  checked copy at -48. }

procedure emit_compare;
var
  k: codegen_$uads_t;
  t: codegen_$uads_t;
  ra: codegen_$uads_t;
  rb: codegen_$uads_t;
  g: integer;
  o: integer;
begin
  get_register(nil, 2, fpa_dreg);
  address(smcontk(81, 2), 0, k);
  case cc of
    6, 7: begin
      if size = 6 then
        o := 484
      else
        o := 481;
      g := 73;
    end;
    14, 15: begin
      if size = 6 then
        o := 486
      else
        o := 483;
      g := 75;
    end;
    12, 13: begin
      if size = 6 then
        o := 485
      else
        o := 482;
      g := 74;
    end;
    otherwise
      bug_check('Unimplemented FPA branch (%4ZWD,%2ZWD)%.', cc, size);
  end;
  if (b.f1 = 13) and (a.f1 = 13) then
    emit_reg_reg(o, size, a, b, 1, g, true)
  else begin
    rb := b;
    ra := a;
    if rb.f1 <> 13 then begin
      t := rb;
      check_ads(t);
      get_register(il_$node_ptr_t(t.x), size, rb);
      emit_load_store(493, rb, t, size);
    end;
    if ra.f1 <> 13 then begin
      t := ra;
      check_ads(t);
      get_register(il_$node_ptr_t(t.x), size, ra);
      emit_load_store(493, ra, t, size);
    end;
    emit_reg_reg(o, size, ra, rb, 1, g, true);
    if ra.f2 <> a.f2 then
      unlock(ra);
    if rb.f2 <> b.f2 then
      unlock(rb);
  end;
  emit(13, 2, fpa_dreg, k, 3);
  release(k);
  unlock(fpa_dreg);
end;

{ emit_jsr - see fpa.ins.pas: a call (gen_call) of the run-time library
  routine (std_lib_rtns) for operation op of size size: by op and size
  (6 single, 7 double, 8 and 12 the extended forms), 86 (a comparison)
  by its condition x; for the extended forms of 10, 19, 28, 37, 46, 55
  and 86 the stack is then popped of the operand's 8 or 16 bytes (emit 1
  of a word on A7).  bug_check of 'Unimplemented FPA instruction
  (%4ZWD,%2ZWD)%.' with op and size for another operation or size;
  86's conditions 8..11 and others leave the routine unset.

  0x0B8E0A, 0x4FE bytes, link #-52: the operations by a compare chain
  (10, 19, 28, 37, 46, 55, 71, 73, 143, 75, 77, 86, 94, ..., 160; 71,
  143 and 145 straight to the bug_check, here the otherwise); the sizes
  by jump tables of 7 from 6 or compared in turn, every bug_check one
  tail (0x0B9250); the routine's index in D4; the operations popped
  tested `btst' in the set at 0x0B9308 (0..95); emit's operation and
  size one longword (1, 2). }

procedure emit_jsr;
var
  k: integer;
  c: codegen_$uads_t;
  sp: codegen_$uads_t;
begin
  case op of
    10:
      case size of
        6: k := 103;
        7: k := 104;
        8: k := 68;
        12: k := 78;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    19:
      case size of
        8: k := 69;
        12: k := 79;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    28:
      case size of
        6: k := 105;
        7: k := 106;
        8: k := 70;
        12: k := 80;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    37:
      case size of
        8: k := 71;
        12: k := 81;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    46:
      case size of
        6: k := 107;
        7: k := 108;
        8: k := 72;
        12: k := 82;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    55:
      case size of
        8: k := 73;
        12: k := 83;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    73:
      case size of
        6: k := 109;
        7: k := 110;
        8: k := 111;
        12: k := 112;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    75:
      k := 92;
    77:
      k := 93;
    86:
      case x of
        6, 7:
          if size = 8 then
            k := 77
          else
            k := 87;
        12, 13:
          if size = 8 then
            k := 76
          else
            k := 86;
        14, 15:
          if size = 8 then
            k := 75
          else
            k := 85;
        otherwise
          ;
      end;
    94:
      k := 97;
    96:
      k := 96;
    98:
      k := 98;
    100:
      case size of
        6: k := 100;
        7: k := 99;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    106:
      case size of
        6: k := 56;
        7: k := 57;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    108:
      case size of
        6: k := 54;
        7: k := 55;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    110:
      case size of
        6: k := 58;
        7: k := 59;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    112:
      case size of
        6: k := 64;
        7: k := 65;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    114:
      case size of
        6: k := 66;
        7: k := 67;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    116:
      case size of
        6: k := 62;
        7: k := 63;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    118:
      case size of
        6: k := 60;
        7: k := 61;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    121:
      case size of
        6: k := 101;
        7: k := 102;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    127:
      case size of
        6: k := 90;
        7: k := 91;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    129:
      case size of
        6: k := 88;
        7: k := 89;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    141:
      case size of
        8: k := 74;
        12: k := 84;
        otherwise
          bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
      end;
    155:
      k := 94;
    156:
      k := 95;
    159:
      k := 113;
    160:
      k := 114;
    otherwise
      bug_check('Unimplemented FPA instruction (%4ZWD,%2ZWD)%.', op, size);
  end;
  gen_call(nil, std_lib_rtns[k]);
  if (size = 12) or (size = 8) then
    if op in [10, 19, 28, 37, 46, 55, 86] then begin
      if size = 8 then
        address(smcontk(81, 8), 0, c)
      else
        address(smcontk(81, 16), 0, c);
      address_reg(15, sp);
      emit(1, 2, sp, c, 0);
    end;
end;

{ load_c16_part - half part (0 the first, else the second) of a 16-byte
  operand src moved into FPA register dst: a constant by its longwords
  (+12 and +16, or +20 and +24) as two singles into the register's
  halves (fpa_ops[493] and [494] in a copy of dst; the second longword
  read from the first's new node, as the image does); another FPA
  register by 501; memory (8 bytes further for the second part) by 493
  of a double.

  0x0B9314, 0x15E bytes, link #-48: both operands copied (-48 src,
  -24 dst); part a word by address; emit_reg_reg's constants after
  other routines (0x0B8B50 7, 0x0B8642 501). }

procedure load_c16_part(
    in dst: codegen_$uads_t;
    in src: codegen_$uads_t;
    in part: integer);
var
  s: codegen_$uads_t;
  d: codegen_$uads_t;
begin
  s := src;
  d := dst;
  if s.f1 = 3 then begin
    s.f6 := 2;
    s.y := 0;
    d.y := ra_fpreg(d.f2) + fpa_ops[493];
    if part = 0 then
      s.x := integer32(smcontk(81, il_$node_ptr_t(s.x)^.xl[3]))
    else
      s.x := integer32(smcontk(81, il_$node_ptr_t(s.x)^.xl[5]));
    emit_assign(6, d, s);
    d.y := ra_fpreg(d.f2) + fpa_ops[494];
    if part = 0 then
      s.x := integer32(smcontk(81, il_$node_ptr_t(s.x)^.xl[4]))
    else
      s.x := integer32(smcontk(81, il_$node_ptr_t(s.x)^.xl[6]));
    emit_assign(6, d, s);
  end
  else if s.f1 = 13 then
    emit_reg_reg(501, 7, dst, s, 0, 0, false)
  else begin
    if part <> 0 then
      s.y := s.y + 8;
    d.y := ra_fpreg(d.f2) + fpa_ops[493];
    emit_load_store(493, d, s, 7);
  end;
end;
