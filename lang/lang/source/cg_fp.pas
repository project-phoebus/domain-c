{ cg_fp - the m68k code generator's floating-point operations: a stack
  of pending operations (push_fop) that purge_fp turns into a call of
  the run-time library's floating routine (the operands pushed, the
  operations as inline words), or done at once in the PEB's registers
  (cpu PEB) or the 68881's (cpu 2 or 4); the floating temporaries and
  the results' registers.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0F87FC  --------  skip_zero_disps
    0x0F882E  --------  cg_fp_$push_fop
    0x0F8904  --------  init_peb
    0x0F8926  --------  fp_rlen
    0x0F8976  --------  test_peb_busy
    0x0F8A0E  --------  purge_fp
    0x0F90EE  --------  stack_fp
    0x0F955E  --------  fp_temp
    0x0F95FA  --------  fop_proc
    A5 0x3552F8 (cc.m68k; cg_call.pas, which has no data, loads the
    same): +0 the stack of operations (512 entries of 8 bytes: the
    operation, its size, its operand), +0x1000..+0x1014 the cells
    cg.ins.pas declares (read and set by cg_addr, cg_assign, cg_call,
    cg_top, cg_tree).  No .rwdi record.

  skip_zero_disps and cg_fp_$push_fop do not load A5 and are internal
  (push_fop runs on its caller's A5); the others are global.

  Operations (the stack's and the PEB's) are IL operator numbers (63 a
  store, 1 a load, 75 and 77 the loads into the PEB, 129 and 130 the
  conversions, 148 the library call's end, ...); purge_fp adds 1, 2 or
  3 for the operand's size (the operation words of the library's
  interpreter, docs/rev889-patterns.md 19).  The generic instructions
  given to emit (0 move, 4, 18, 20, 23, 32, 36, 39) are emit's numbers.

  Not known from the original: the names of the module's variables, the
  locals and the parameters; the meaning of most operation numbers. }
module cg_fp;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cg.ins.pas';

type
  { A pending floating operation: op on operand node (nil: the
    previous result) of class size. }
  fp_fop_t = record
    op: integer;                        { +0 }
    size: integer;                      { +2 }
    node: il_$node_ptr_t;               { +4 }
  end;

var
  fops: array [1..512] of fp_fop_t;     { +0 }

  { delay.pas's data (cc.m68k 0x169968, absolute; outbin.pas declares
    it the same way): a word for each register class, the bytes
    invalidate is given. }
  delay_378: extern array [0..15] of integer;

{ The cells other units read (cg.ins.pas), laid out after the stack in
  this order: +0x1000, +0x1004, +0x1008, +0x100C, +0x1010, +0x1012,
  +0x1014. }
define
  cg_fp_1000, cg_fp_last_store, cg_fp_result, cg_fp_in_peb, cg_fp_count,
  cg_fp_last_op, cg_fp_long,
  init_peb, fp_rlen, test_peb_busy, purge_fp, stack_fp, fp_temp,
  fop_proc;


{ skip_zero_disps - n, or its base when n is a displacement of 0 (kind
  147, +32 zero) and the current block's +377 field (bits 6..4) is 2.

  0x0F87FC, 0x32 bytes, no frame: n at (4,SP), the result in A0
  (docs/rev889-patterns.md 16).

  Not known from the original:
  - what the block's field is. }

function skip_zero_disps(
    n: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  m: il_$node_ptr_t;
begin
  m := n;
  if m <> nil then
    if (m^.kind = 147) and (m^.xl[8] = 0) then
      if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
        m := m^.xp[6];
  skip_zero_disps := m;
end;

{ cg_fp_$push_fop - operation op of size size on n pushed on the stack
  (cgerr 24 when it holds 512); FP0's contents forgotten, no operand
  kept in the PEB.

  0x0F882E, 0x80 bytes, no A5 load (its caller's): the message a varying
  constant at 0x0F88AE passed to token_$make_string_token
  (docs/dpc-gaps.md 18); the entry at A5 + 8 * count - 8. }

procedure cg_fp_$push_fop(
    op: integer;
    size: integer;
    n: il_$node_ptr_t); options(val_param); internal;
begin
  if cg_fp_count = 512 then
    cgerr(24, cg_line, token_$make_string_token(
        'Expression involving floating-point quantities too complex, simplify and recompile.'));
  cg_fp_count := cg_fp_count + 1;
  fops[cg_fp_count].op := op;
  fops[cg_fp_count].size := size;
  fops[cg_fp_count].node := n;
  kill_register(16);
  cg_fp_last_store := nil;
  cg_fp_in_peb := nil;
  cg_fp_last_op := op;
end;

{ init_peb - no PEB operation pending.

  0x0F8904, 0x22 bytes. }

procedure init_peb;
begin
  cg_fp_last_op := 147;
  cg_fp_in_peb := nil;
  cg_fp_last_store := nil;
end;

{ fp_rlen - the register class of d for operand k: w6 (k 1) or w8 (k 2)
  when not 0, else rlen.

  0x0F8926, 0x50 bytes. }

function fp_rlen;
begin
  if k = 1 then begin
    if d.w6 = 0 then
      fp_rlen := d.rlen
    else
      fp_rlen := d.w6;
  end
  else if k = 2 then begin
    if d.w8 = 0 then
      fp_rlen := d.rlen
    else
      fp_rlen := d.w8;
  end
  else
    fp_rlen := d.rlen;
end;

{ test_peb_busy - the wait for the PEB: a temporary label's address
  (32, size 5), the PEB's status (operation 147 of mode 11) tested
  against cg_tree_188 (18, size 2), and the branch back (20, x 11).

  0x0F8976, 0x98 bytes: the status descriptor built in the frame (-48:
  f1 11, f5 5, x 0, y 147); templabel's node to address (size 0, -24);
  the instruction and size words pushed as one longword (#0x00200005,
  #0x00120002, #0x00140005; docs/rev889-patterns.md 54). }

procedure test_peb_busy;
var
  status: codegen_$uads_t;
  lab: codegen_$uads_t;
begin
  status.f1 := 11;
  status.x := 0;
  status.f5 := 5;
  status.y := 147;
  address(templabel, 0, lab);
  emit(32, 5, lab, cg_null_ads, 0);
  emit(18, 2, status, cg_tree_188, 0);
  emit(20, 5, lab, cg_null_ads, 11);
end;

{ purge_fp - the stack's operations generated and the stack emptied.
  The last operation, unless it ends the sequence (a store, 67, 71,
  73, 86, 145, 159), gets a library end (148) of its size (6 for a
  conversion of more than 4 bytes); a 148 of up to 4 bytes (or after a
  short conversion) becomes 71 (size 2) or 73.  Each entry, last first:
  its operation adjusted for its operand's size, then the operand
  pushed (`-(SP)', a value from its register or its address, 23); a
  constant's adds 1.  Then the library call (gen_call of std_lib's
  routine: +0x54 with an extended operand, else by the first
  operation, 0 +0x4C, 1 +0x50, 2 +0x58, other +0x48 with an `inline'
  word of the first operation, 36), the operations' words (39) for each
  entry from the second with a constant (the constant's operand) or
  invalidating its object (the size classes' table at 0x169968, delay's
  data), and the result: without the PEB setresult in FP0 (16) or in
  D0 (0) for 71 and 73.

  0x0F8A0E, 0x69C bytes: sets after the code (`btst'): [67, 71, 73, 86,
  145, 159] (0x0F90C6), [63, 67, 75, 77, 157, 159] (0x0F90DA), [0..2,
  63, 67, 71, 73, 129] (0x0F90AA), [63..65, 67..69] (0x0F90BC); a jump
  table on size - 2 (0..10); the flag `pushed by value' in D0; the
  loops count down and up with `dbf' (A3 stepping 8); the class
  table's address in D5 (`movea.l D5,A0; move.w (0,A0,D1.w)', a word
  for each class).

  Not known from the original:
  - the operation numbers' meanings, std_lib's routines;
  - the class table (delay_$...'s, cc.m68k 0x169968: delay.pas +0x378,
    outbin.pas's delay_378). }

procedure purge_fp;
var
  i: integer;
  by_value: boolean;
  push: codegen_$uads_t;
  a: codegen_$uads_t;
  v: codegen_$uads_t;
  n: il_$node_ptr_t;
  rlen: integer;
begin
  if cg_fp_count = 0 then
    return;
  with fops[cg_fp_count] do begin
    if op = 63 then
      op := 67;
    if not (op in [67, 71, 73, 86, 145, 159]) then begin
      if ((op = 130) or (op = 129)) and (size <= 4) then
        stack_fp(148, size, nil)
      else
        stack_fp(148, 6, nil);
    end;
  end;
  if fops[cg_fp_count].op = 148 then
    if (fops[cg_fp_count].size <= 4) or
        ((cg_fp_count > 1) and
         ((fops[cg_fp_count - 1].op = 130) or
          (fops[cg_fp_count - 1].op = 129)) and
         (fops[cg_fp_count - 1].size <= 4)) then
      case fops[cg_fp_count].size of
        2: fops[cg_fp_count].op := 71;
        4: fops[cg_fp_count].op := 73;
        otherwise fops[cg_fp_count].op := 73;
      end;

  address_reg(15, push);
  push.f1 := 9;
  for i := cg_fp_count downto 1 do
    with fops[i] do begin
      by_value := false;
      if (size <= 6) and (node <> nil) and (op <> 63) and (op <> 67) and
          (op <> 159) then begin
        if size = 6 then begin
          if not ((node^.kind = 190) or (node^.kind = 189) or
                  (node^.kind = 138) or (node^.kind = 88)) then
            by_value := true;
        end
        else
          by_value := true;
      end;
      if (op <> 156) and (op <> 155) then begin
        if node <> nil then
          if not (op in [63, 67, 75, 77, 157, 159]) then
            case size of
              12: op := op + 3;
              8: op := op + 2;
              7: op := op + 1;
              otherwise ;
            end;
        case size of
          2, 4: begin
            if not ((op = 98) or (op = 94)) then begin
              if op in [0..2, 63, 67, 71, 73, 129] then begin
                if by_value then
                  op := op - 1;
              end
              else if size = 4 then
                op := op + 1;
            end;
          end;
          6: begin
            if by_value then
              op := op - 1;
          end;
          7: op := op + 1;
          8: begin
            if not ((op = 143) or (op = 141) or (op = 83)) then
              op := op + 2;
          end;
          12: begin
            if not ((op = 143) or (op = 141) or (op = 83)) then
              op := op + 3;
          end;
          otherwise ;
        end;
      end;
      if node <> nil then begin
        if (node^.kind = 88) or (node^.kind = 89) or (node^.kind = 198) or
            (node^.kind = 90) then
          op := op + 1
        else begin
          if by_value then begin
            address(node, size, a);
            emit(0, size, push, a, 0);
          end
          else begin
            if ((2 in cargs_$options.cpu) or (4 in cargs_$options.cpu)) and
                ((node^.kind = 109) or (node^.kind = 110) or
                 (node^.kind = 147) or (node^.kind = 146)) and
                (chk_assign(node, size) in [16..23]) and
                (peek(node, size) in [16..23]) then begin
              address(node, size, v);
              address(node, 0, a);
              emit(0, size, a, v, 0);
              unlock(v);
            end
            else
              address(node, 0, a);
            emit(23, size, a, cg_null_ads, 0);
          end;
          release(a);
        end;
      end;
    end;

  if cg_fp_long then begin
    gen_call(nil, std_lib_rtns[21]);
    emit(36, 2, cg_null_ads, cg_null_ads, fops[1].op);
  end
  else if fops[1].op = 0 then
    gen_call(nil, std_lib_rtns[19])
  else if fops[1].op = 1 then
    gen_call(nil, std_lib_rtns[20])
  else if fops[1].op = 2 then
    gen_call(nil, std_lib_rtns[22])
  else begin
    gen_call(nil, std_lib_rtns[18]);
    emit(36, 2, cg_null_ads, cg_null_ads, fops[1].op);
  end;

  n := fops[1].node;
  if n <> nil then
    if (n^.kind = 88) or (n^.kind = 89) or (n^.kind = 198) or
        (n^.kind = 90) then begin
      address(n, 0, a);
      emit(39, fops[1].size, a, cg_null_ads, 0);
      release(a);
    end;

  for i := 2 to cg_fp_count do
    with fops[i] do begin
      emit(36, 2, cg_null_ads, cg_null_ads, op);
      if node <> nil then begin
        if (node^.kind = 88) or (node^.kind = 89) or
            (node^.kind = 198) or (node^.kind = 90) then begin
          address(node, 0, a);
          emit(39, size, a, cg_null_ads, 0);
          release(a);
        end
        else if (op in [63..65, 67..69]) and (node <> nil) and
            (node^.kind <> 152) then begin
          a.x := integer32(node);
          invalidate(a, delay_378[size]);
        end;
      end;
    end;

  if 1 in cargs_$options.cpu then
    cg_fp_last_store := cg_fp_result
  else begin
    if (fops[cg_fp_count].op = 73) or (fops[cg_fp_count].op = 71) then
      setresult(0, cg_fp_result, fops[cg_fp_count].size)
    else if (2 in cargs_$options.cpu) or (4 in cargs_$options.cpu) then
      begin
      if cg_fp_result <> nil then
        rlen := cg_tree_ptr_t(cg_fp_result)^.desc.rlen
      else
        rlen := 0;
      setresult(16, cg_fp_result, rlen);
    end;
  end;
  cg_fp_count := 0;
  cg_fp_in_peb := nil;
  cg_fp_result := nil;
  cg_fp_long := false;
end;

{ stack_fp - floating operation op of size size on operand n (a
  displacement of 0 taken as its base).  A conversion to the PEB's
  register (75, 77) of a value just converted is dropped; a store of a
  temporary (63 to a 152) while operations are pending is stacked.
  With the 68881 (cpu 2 or 4) a single or double load or store: the
  value moved to FP0 (a load: setresult) unless already there.  An
  extended operand (8, 12) marks the stack.  With the PEB (cpu 1) and
  an operation it does (a set at 0x0F953C), the pending stack purged:
  the operand addressed (a double by its address, `(An)+'; a word
  extended to a longword), the PEB waited for unless the last
  operation needs no wait (a set at 0x0F954A), and the operand moved
  to or from the PEB's operation register (mode 11, operation op, +1
  for a single or long, +2 for a double's or long's first word...),
  twice for a double; the PEB's register's contents noted.  Otherwise
  the operation is pushed.

  0x0F90EE, 0x44E bytes: the sets [1, 10, 19, 28, 37, 46, 55, 63, 75,
  77, 79, 83, 104] and [1, 63, 83, 104, 149, 157, 159] after the code;
  `cpu * [2, 4]' as `andi.w #0x3FFC; lsr.w #2; andi.w #20' of the
  word at +0x284; every path that pushes ends in one `bsr'
  (docs/rev889-patterns.md 23); a double store to a temporary
  addresses its second longword through cg_tree_1b4 (+16 1, +24 and
  +28 the temporary, +32 4).

  Not known from the original:
  - the operations' meanings and the sets' members' names;
  - the meaning of FP0's w14 in cg_addr's register table. }

procedure stack_fp;
var
  m: il_$node_ptr_t;
  r: codegen_$uads_t;
  t: codegen_$uads_t;
begin
  m := skip_zero_disps(n);
  if ((op = 77) or (op = 75)) and (size <= 4) and (m <> nil) then
    if (m^.kind = 138) or (m^.kind = 137) then
      if (cg_tree_ptr_t(m)^.op = 41) and
          (cg_tree_ptr_t(m)^.desc.w6 = 11) then
        if (fops[cg_fp_count].op = 130) or (fops[cg_fp_count].op = 129)
            then
          return;
  if (m <> nil) and (op = 63) and (m^.kind = 152) and (cg_fp_count <> 0)
      then begin
    cg_fp_$push_fop(op, size, m);
    return;
  end;
  if ((2 in cargs_$options.cpu) or (4 in cargs_$options.cpu)) and
      ((size = 7) or (size = 6)) and ((op = 63) or (op = 1)) and
      not cg_fp_long then begin
    if cg_fp_count <> 0 then begin
      cg_fp_$push_fop(op, size, m);
      return;
    end;
    if op = 1 then
      if peek(m, size) = 16 then
        if cg_addr_regs[16].w14 <> 2 then
          return;
    address_reg(16, r);
    if op <> 1 then
      return;
    address(m, size, t);
    emit(0, size, r, t, size);
    release(t);
    setresult(16, m, size);
    return;
  end;
  if (size = 12) or (size = 8) then
    cg_fp_long := true;
  if not (1 in cargs_$options.cpu) or cg_fp_long or
      not (op in [1, 10, 19, 28, 37, 46, 55, 63, 75, 77, 79, 83, 104]) then
      begin
    cg_fp_$push_fop(op, size, m);
    return;
  end;

  if cg_fp_count <> 0 then
    purge_fp;
  if check_use(cg_fp_in_peb, m) and (size = 4) then begin
    m := nil;
    if op = 75 then
      op := 152
    else if op = 77 then
      op := 153;
  end;
  if op = 1 then
    if check_use(cg_fp_last_store, m) then
      return;
  if m <> nil then begin
    if size = 7 then begin
      if (m^.kind = 152) and (op = 63) then
        address(m, 0, t)
      else begin
        load_address(m, t);
        kill_register(t.f2);
        t.f1 := 8;
      end;
    end
    else if size = 2 then begin
      inquire(m, size, t);
      if t.f1 = 0 then
        load_operand(m, size, t);
      s_extend(t, 2, 4);
      size := 4;
    end
    else if op = 63 then
      address(m, 0, t)
    else
      address(m, size, t);
  end;
  r.f1 := 11;
  r.f5 := 5;
  r.x := 0;
  if not (cg_fp_last_op in [1, 63, 83, 104, 149, 157, 159]) then
    test_peb_busy;
  if (size = 7) or (size = 4) then begin
    if (m = nil) or (op = 63) or (op = 77) or (op = 75) then
      r.y := op + 1
    else
      r.y := op + 2;
  end
  else
    r.y := op;
  if m = nil then
    emit(18, 2, r, cg_tree_188, 0)
  else begin
    if op = 63 then
      emit(0, 4, t, r, 0)
    else
      emit(0, 4, r, t, 0);
    if size = 7 then begin
      r.y := r.y + 1;
      if op = 63 then begin
        if (m^.kind = 152) and (op = 63) then begin
          cg_tree_1b4^.xw[8] := 1;
          cg_tree_1b4^.xp[6] := m;
          cg_tree_1b4^.xp[7] := m;
          cg_tree_1b4^.xl[8] := 4;
          address(cg_tree_1b4, 4, t);
        end;
        emit(0, 4, t, r, 0);
      end
      else
        emit(0, 4, r, t, 0);
    end;
    if (size <> 7) or ((m^.kind = 152) and (op = 63)) then
      release(t)
    else
      unlock(t);
  end;
  if (op = 75) or (op = 77) then begin
    if size = 4 then
      cg_fp_in_peb := m
    else
      cg_fp_in_peb := nil;
  end;
  if op = 63 then begin
    t.x := integer32(m);
    invalidate(t, size);
  end;
end;

{ fp_temp - node n's floating value kept: with operations pending it is
  the stack's result, else (cpu PEB) the last store's; t (n's
  temporary, through a 190's +4 or a 189's +20) of a negative +18,
  when at_backend_506, is made a 138 and stored to (a 152 store's
  temporary itself, else a new temporary from get_temp) with 63.

  0x0F955E, 0x9C bytes. }

procedure fp_temp;
var
  v: il_$node_ptr_t;
begin
  v := n;
  if cg_fp_count <> 0 then
    cg_fp_result := v
  else if 1 in cargs_$options.cpu then
    cg_fp_last_store := v;
  if v^.kind = 190 then
    v := v^.xp[1]
  else if v^.kind = 189 then
    v := v^.xp[5];
  if v^.xw[9] < 0 then
    if at_backend_506 then begin
      v^.kind := 138;
      if t^.kind = 152 then
        stack_fp(63, v^.xw[12], t)
      else begin
        get_temp(v, false);
        stack_fp(63, v^.xw[12], v^.xp[10]);
      end;
    end;
end;

{ fop_proc - floating tree node n: its class (the second operand's,
  +26, for a conversion 40); its first operand stacked (load, 1, of
  class: a conversion 41 from 11 its +28) unless it is the stack's
  result, or the second when the first is that result or the last
  store (cpu PEB) and op2 is not 104 (then op2 replaces op1); the
  other operand with op1 or op2 (nil for one operand; a 152's +16);
  the result (a conversion 130 or 129 of up to 4 bytes) is the stack's
  result, else fp_temp with n's temporary (+40).

  0x0F95FA, 0x140 bytes: the operand k at (0x24 + 4k,A2) (opnd[k]), the
  other at (36 + 4(3 - k),A2).

  Not known from the original:
  - the operations' names. }

procedure fop_proc;
var
  t: cg_tree_ptr_t;
  rlen: integer;
  rlen1: integer;
  k: integer;
  op: integer;
  first: il_$node_ptr_t;
  m: il_$node_ptr_t;
begin
  t := cg_tree_ptr_t(n);
  if t^.op = 40 then
    rlen := t^.desc.w6
  else
    rlen := t^.desc.rlen;
  if (t^.op = 41) and (t^.desc.w6 = 11) then
    rlen1 := t^.desc.w8
  else
    rlen1 := rlen;
  k := 1;
  op := op1;
  if (k < t^.count) and (op2 <> 104) then begin
    first := skip_zero_disps(t^.opnd[2]);
    if check_use(cg_fp_result, first) or
        (check_use(cg_fp_last_store, first) and
         (1 in cargs_$options.cpu)) then begin
      op := op2;
      k := 2;
    end;
  end;
  m := skip_zero_disps(t^.opnd[k]);
  if m^.kind = 152 then
    m := m^.xp[4];
  if not check_use(cg_fp_result, m) then
    stack_fp(1, rlen1, m);
  if t^.count = 1 then
    stack_fp(op, rlen, nil)
  else if t^.opnd[3 - k]^.kind = 152 then
    stack_fp(op, rlen, t^.opnd[3 - k]^.xp[4])
  else
    stack_fp(op, rlen, t^.opnd[3 - k]);
  if not (((op = 130) or (op = 129)) and (t^.desc.rlen <= 4)) then
    fp_temp(n, t^.opnd[1])
  else
    cg_fp_result := n;
end;
