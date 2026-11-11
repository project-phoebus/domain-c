{ cg_call - the m68k code generator's calls: gen_call pushes a call's
  arguments (by the callee's parameter classes: a value of 1, 2 or 4
  bytes, a structure copied to the stack, an address), reserves the
  result's temporary, loads the static link, calls the routine (through
  a variable, a routine of the same section with A5 kept, a new section
  address, the transfer vector), pops the arguments, and forgets the
  registers the callee does not save and the objects an argument may
  alias; the result's register.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0F68E8  --------  cg_call_$is_a_nint
    0x0F6912  --------  cg_call_$is_proc_var_call
    0x0F69AC  --------  get_atts
    0x0F6A02  --------  cg_call_$att_in_any_entry
    0x0F6A46  --------  cg_call_$alias_size_expand
    0x0F6B18  --------  cg_call_$obj_is_modifiable_by_param
    0x0F6B5A  --------  cg_call_$kill_any_param_alias
    0x0F6BFA  --------  copy_to_stack (in gen_call)
    0x0F715C  --------  varargs_moveq_d0 (in gen_call)
    0x0F720A  --------  gen_call
    A5 0x3552F8 (cc.m68k): the module has no data; its global routines
    load cg_fp's A5 (the next unit's), which they do not use.

  cg_call_$is_proc_var_call and gen_call load A5 and are global; the
  others do not and are internal (cg_call_$is_a_nint and
  cg_call_$obj_is_modifiable_by_param have no frame,
  docs/rev889-patterns.md 16).  copy_to_stack and varargs_moveq_d0 are
  nested in gen_call and take its frame from their dynamic link
  (docs/rev889-patterns.md 25): its descriptors (-48 the push, -168,
  -144, -120, -96), -200 the callee, -256 a library call, -258 the
  result's temporary pushed.

  The nodes are read through il.ins.pas's views by offset and
  cg.ins.pas's tree view; a routine block's parameter classes (+394,
  +396 words), a routine type's (159: +10 the count, then a flag byte
  and a class nibble for each), a routine variable's type's (174, 173:
  +80) through cg_words_t.

  Not known from the original: every name but the routines'; the
  parameter classes' meanings (6 a structure by value, 7..9 constants'
  classes, 11 the result's address); the generic instructions given to
  emit (0 move, 1 add, 2, 22, 23 push the address, 24 jsr, 31). }
module cg_call;

%include '/sys/ins/base.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/fpa.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { The front end's type_exp result (c_objtype's type_exp_t, which this
    unit does not open): 32 bytes, its size at +16. }
  call_type_exp_t = array [1..8] of integer32;

  { A record whose first longword is a node (a variable's +52's +8). }
  call_link_ptr_t = ^call_link_t;
  call_link_t = record
    p: il_$node_ptr_t;
  end;

var
  { delay.pas's data (cc.m68k 0x169968 and 0x169988, absolute; outbin.pas
    declares them the same way): words by register class, the bytes of
    a class (+0x378) and the size an argument of a class is pushed in
    (+0x398). }
  delay_378: extern array [0..15] of integer;
  delay_398: extern array [0..15] of integer;

{ cg_call_$is_a_nint - n is a conversion (41) of class 11 (a 138 or 137
  tree).

  0x0F68E8, 0x2A bytes, no frame: n at (4,SP). }

function cg_call_$is_a_nint(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  cg_call_$is_a_nint := ((n^.kind = 138) or (n^.kind = 137)) and
      (cg_tree_ptr_t(n)^.op = 41) and (cg_tree_ptr_t(n)^.desc.w6 = 11);
end;

{ cg_call_$is_proc_var_call - the designator n is called through a
  variable: 147, 146; a routine variable (107, 108 with +376 bits 8..7
  3); a 171 whose +16 is not a routine (107, 108, 110, 159, 167); 175.

  0x0F6912, 0x84 bytes: the set [107..108, 110, 159, 167] at 0x0F6996
  (`btst'). }

function cg_call_$is_proc_var_call;
var
  r: boolean;
begin
  r := false;
  case n^.kind of
    147, 146: r := true;
    108, 107: begin
      if rshft(n^.xw[188] & 16#180, 7) = 3 then
        r := true;
    end;
    171: begin
      if not (n^.xp[4]^.kind in [107..108, 110, 159, 167]) then
        r := true;
    end;
    175: r := true;
    otherwise ;
  end;
  cg_call_$is_proc_var_call := r;
end;

{ get_atts - a routine's attributes: a block's (107, 108: +374 from bit
  11), a routine type's (174, 173: +76 bits 23..3), a 175's through its
  +20; else none.

  0x0F69AC, 0x56 bytes, no A5: recursive (`bsr.s'). }

function get_atts(
    n: il_$node_ptr_t): integer32; options(val_param); internal;
begin
  if (n^.kind = 108) or (n^.kind = 107) then
    get_atts := rshft(n^.xl2[93], 11)
  else if (n^.kind = 174) or (n^.kind = 173) then
    get_atts := rshft(n^.xl[19] & 16#FFFFF8, 3)
  else if n^.kind = 175 then
    get_atts := get_atts(n^.xp[5])
  else
    get_atts := 0;
end;

{ cg_call_$att_in_any_entry - attribute k of block n, or of its entry's
  block (a 167's +148).

  0x0F6A02, 0x44 bytes, no A5: `btst k' of the longword at +374 shifted
  right 11. }

function cg_call_$att_in_any_entry(
    k: integer;
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := (rshft(n^.xl2[93], 11) & lshft(1, k)) <> 0;
  if not r then
    if n^.kind = 167 then
      if n^.xp[37] <> nil then
        r := (rshft(n^.xp[37]^.xl2[93], 11) & lshft(1, k)) <> 0;
  cg_call_$att_in_any_entry := r;
end;

{ cg_call_$alias_size_expand - descriptor d of argument n given the
  object's size: in a block of language 2 (+377 bits 6..4) a common
  member's (110: its class, +10's low nibble, through runbackend_18) or
  the base's (a 110 likewise, a tree's class +24); else type_exp's
  size.

  0x0F6A46, 0xD2 bytes, no A5: the class tables at 0x2C33C8
  (runbackend_18) and 0x169968 (delay_378), absolute. }

procedure cg_call_$alias_size_expand(
    n: il_$node_ptr_t;
    var d: alias_$desc_t); options(val_param); internal;
var
  t: call_type_exp_t;
  v: il_$node_ptr_t;
begin
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then begin
    if d.class = 1 then begin
      if d.sym <> nil then
        if d.sym^.kind = 110 then
          d.size := delay_378[runbackend_18[ord(d.sym^.xc[10]) & 15]];
    end
    else if d.base <> nil then begin
      v := d.base;
      if v^.kind = 110 then
        d.size := delay_378[runbackend_18[ord(v^.xc[10]) & 15]]
      else if (v^.kind = 137) or (v^.kind = 143) or (v^.kind = 138) then
        d.size := delay_378[v^.xw[12]];
    end;
  end
  else begin
    type_exp(n, addr(t));
    d.size := t[5];
  end;
end;

{ cg_call_$obj_is_modifiable_by_param - n is not nil, not a constant
  and not a tree (the set [77..90, 92..93, 101, 137..138, 143, 156, 176,
  198, 200]).

  0x0F6B18, 0x28 bytes, no frame: the set at 0x0F6B40, `sle'. }

function cg_call_$obj_is_modifiable_by_param(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    cg_call_$obj_is_modifiable_by_param :=
        not (n^.kind in [77..90, 92..93, 101, 137..138, 143, 156, 176, 198, 200])
  else
    cg_call_$obj_is_modifiable_by_param := false;
end;

{ cg_call_$kill_any_param_alias - when an argument of call n (from the
  second, up to count - +26) that may be modified is related to d and
  passed by reference (paramclass 1, 3 or 4), flag cleared and p nil.

  0x0F6B5A, 0xA0 bytes, no A5: the argument at (0x24 + 4k,A2); `btst'
  of paramclass's result in 26. }

procedure cg_call_$kill_any_param_alias(
    n: il_$node_ptr_t;
    var d: alias_$desc_t;
    var flag: boolean;
    var p: il_$node_ptr_t); options(val_param); internal;
var
  k: integer;
  a: il_$node_ptr_t;
  d2: alias_$desc_t;
begin
  if n <> nil then
    for k := 2 to cg_tree_ptr_t(n)^.count - n^.xw[13] do begin
      a := cg_tree_ptr_t(n)^.opnd[k];
      if cg_call_$obj_is_modifiable_by_param(a) then begin
        alias_$basic_alias_desc(a, d2);
        cg_call_$alias_size_expand(a, d2);
        if alias_$related(d, d2) then
          if paramclass(n, k - 1) in [1, 3, 4] then begin
            flag := false;
            p := nil;
            return;
          end;
      end;
    end;
end;

{ gen_call - the call of tree n (its opnd[1] the callee, the arguments
  from opnd[2]), or of library routine rtn with n's operands (n nil:
  none) as its arguments.

  0x0F720A, 0x15D2 bytes, A5 (saves D2-D6/A2-A5): the arguments pushed
  last first (a counted loop on -266 with `bcc'); a 171 designator's
  arguments copied with their sizes from its +20 words; each argument's
  class (D5) from the callee (a routine type's flags and nibbles, a
  block's words at +394 or +396, a routine variable type's at +80) or
  from the constant's kind; classes below 6 pushed in delay_398's size
  (4 and 5 swapped when the other is in a register), 6 copied (its
  parameter's +28 bits rounded to even bytes), else an address (a
  register locked and moved, a 109 variable's value moved to a new
  temporary, a converted integer's likewise, a value in several
  registers stored back; `pea' in at most 5 bytes); the pushed bytes
  counted (2 for classes 0 and 1, 4 else); the result's temporary for
  a class of 7 or more but 9; the call: through A0 (a routine variable:
  `jsr (A0)'), the static link in A1, a routine of the same section
  and data (A5 from A5's register when it has several entries, a new
  section's address constant), `bsr' (31) to a routine of the same
  section, else A0 from the routine's address constant or `jsr' of
  the transfer vector (-ABS); with -ALIGN the call's +7 bit 7 for an
  argument area not a multiple of 4; the arguments popped (`add' to
  SP); the registers reg_save does not report kept are killed, and the
  cached objects arguments may alias dropped; the result in D0 or A0
  (a pointer function: A0 and D0, by the routine's attributes 7 and
  9).

  Not known from the original:
  - the classes' and the attributes' meanings;
  - the names of the locals. }

procedure gen_call;
var
  push: codegen_$uads_t;                { -48 }
  link: codegen_$uads_t;                { -72 }
  op4: codegen_$uads_t;                 { -96 }
  op2: codegen_$uads_t;                 { -120 }
  areg: codegen_$uads_t;                { -144 }
  op1: codegen_$uads_t;                 { -168 }
  desig: il_$node_ptr_t;                { -172 }
  callee: il_$node_ptr_t;               { -200 }
  params: il_$node_ptr_t;               { -204 }
  first: integer;                       { -250 }
  last: integer;                        { -242 }
  nparams: integer;                     { -244 }
  pushed: integer;                      { -240 }
  lib: boolean;                         { -256 }
  copied: boolean;                      { -254 }
  pass_len: boolean;                    { -252 }
  keep: boolean;                        { -262 }
  procvar: boolean;                     { -260 }
  result_temp: boolean;                 { -258 }
  called: boolean;
  i: integer;
  k: integer;
  cls: integer;
  size: integer32;
  w: integer;
  r: integer;
  arg: il_$node_ptr_t;
  v: il_$node_ptr_t;
  t: il_$node_ptr_t;
  saved: il_$node_ptr_t;
  regs: integer32;
  atts: integer32;
  offset: integer32;
  done: boolean;
  in_reg: boolean;
  moved: boolean;
  nint: boolean;
  go: boolean;
  b: boolean;
  d: alias_$desc_t;
  dummy: il_$node_ptr_t;

  { copy_to_stack - argument arg of size bytes pushed: up to 4 (1 made
    2) a constant, an address (26) or value (0) tree's operand (a kept
    common subexpression's address, `pea' of a constant in its size),
    else the value in its size (a 5 or 4 in a register) or a fault-free
    move; more (made even): a double in a floating register moved,
    else from the end of the object (an address register at +size,
    `move.l -(An)' size div 4 times, a block move for more than four,
    a `move.w' for the rest); a double constant as two longwords.

    0x0F6BFA, 0x548 bytes, nested: gen_call's frame from the dynamic
    link; the set [77..87, 101, 200] (integer constants) at 0x0F7142;
    cpu 3 (68020) or a displacement within the mode's range adds size
    to the operand's (`lea'), else `lea' and an add; cg_tree_1b4 built
    as the object's end (+16 1, +24 and +28 arg, +32 size).

    Not known from the original:
    - the generic instructions' names. }

  procedure copy_to_stack(
      var size: integer32;
      arg: il_$node_ptr_t); options(val_param);
  var
    w: integer;
    w24: integer;
    cnt: integer32;
    d: integer32;
    j: integer;
  begin
    if size <= 4 then begin
      if size = 1 then begin
        size := 2;
        w := 1;
      end
      else if size = 2 then
        w := 2
      else
        w := 4;
      if arg^.kind in [77..87, 101, 200] then begin
        address(arg, 0, op1);
        anyconst(arg^.xl[2], w, op1);
        emit(0, w, push, op1, 0);
      end
      else if (arg^.kind = 137) and ((cg_tree_ptr_t(arg)^.op = 26) or
          (cg_tree_ptr_t(arg)^.op = 0)) and (arg^.xw[8] = 1) then begin
        tree_walk(cg_tree_ptr_t(arg)^.opnd[1]);
        if cg_fp_count <> 0 then
          purge_fp;
        done := false;
        if cg_tree_ptr_t(arg)^.op = 26 then
          if cg_addr_$addr_of_cse(cg_tree_ptr_t(arg)^.opnd[1]) then begin
            cg_addr_$load_addr_of_cse(arg, op1);
            w24 := w;
            if (op1.f1 = 1) and (op1.f2 in [8..15]) then
              emit(0, w24, push, op1, 0)
            else
              emit(23, w24, op1, cg_null_ads, 0);
            done := true;
          end;
        if not done then begin
          address(cg_tree_ptr_t(arg)^.opnd[1], 0, op1);
          w24 := w;
          if op1.f1 = 3 then
            case il_$node_ptr_t(op1.x)^.kind of
              86, 200, 87: w24 := 1;
              83, 80: w24 := 2;
              85, 82: w24 := 4;
              otherwise ;
            end;
          emit(23, w24, op1, cg_null_ads, 0);
        end;
      end
      else begin
        tree_walk(arg);
        if cg_fp_count <> 0 then
          purge_fp;
        if peek(arg, 5) <> 31 then begin
          address(arg, 5, op1);
          emit(0, 5, push, op1, 0);
        end
        else if peek(arg, 4) <> 31 then begin
          address(arg, 4, op1);
          emit(0, 4, push, op1, 0);
        end
        else begin
          address(arg, w, op1);
          fault_free_assign(w, push, op1);
        end;
      end;
    end
    else begin
      if odd(size) then
        size := size + 1;
      tree_walk(arg);
      if cg_fp_count <> 0 then
        purge_fp;
      if size = 8 then
        if chk_assign(arg, 7) <> 31 then begin
          address(arg, 7, op1);
          if 8 in cargs_$options.cpu then
            emit_assign(7, push, op1)
          else
            emit(0, 7, push, op1, 0);
          return;
        end;
      if arg^.kind <> 89 then begin
        cg_tree_1b4^.xw[8] := 1;
        cg_tree_1b4^.xp[6] := arg;
        cg_tree_1b4^.xp[7] := arg;
        cg_tree_1b4^.xl[8] := size;
        address(arg, 0, areg);
        release(areg);
        get_temp_register(arg, 5, op1);
        d := areg.y + size;
        if (3 in cargs_$options.cpu) or
            (((areg.f1 = 4) or (areg.f1 = 6)) and (d < 128) and
             (d >= -128)) or
            ((areg.f1 = 2) and (d < 32768) and (d >= -32768)) then begin
          areg.y := d;
          emit(22, 1, op1, areg, 0);
        end
        else begin
          emit(22, 1, op1, areg, 0);
          anyconst(size, 4, areg);
          emit(1, 5, op1, areg, 0);
          unlock(areg);
        end;
        kill_register(op1.f2);
        op1.f1 := 9;
        cnt := size div 4 - 1;
        if cnt > 3 then begin
          cnt := cnt + 1;
          cg_asn_$block_move(cnt, 4, op1, push, op2, op4);
        end
        else if cnt >= 0 then
          for j := 0 to cnt do
            emit(0, 4, push, op1, 0);
        if size mod 4 <> 0 then
          emit(0, 2, push, op1, 0);
      end
      else begin
        address(smcontk(81, arg^.xl[4]), 4, op1);
        emit(0, 4, push, op1, 0);
        unlock(op1);
        address(smcontk(81, arg^.xl[3]), 4, op1);
        emit(0, 4, push, op1, 0);
      end;
    end;
  end;

  { varargs_moveq_d0 - with -VARARGS, for a call that is not a library
    routine's nor through a routine type (159): the count of n's
    arguments (negated when the result's temporary was pushed) moved
    to D0.

    0x0F715C, 0xAE bytes, nested: gen_call's frame from the dynamic
    link (-256, -258, -200); cargs +0x287 bit 0. }

  procedure varargs_moveq_d0(
      n: il_$node_ptr_t); options(val_param);
  var
    r: codegen_$uads_t;
    c: codegen_$uads_t;
  begin
    if 5 in cargs_$options.flags_286 then
      if not lib then
        if callee^.kind <> 159 then begin
          if result_temp then
            anyconst(-(cg_tree_ptr_t(n)^.count - n^.xw[13] - 1), 2, c)
          else
            anyconst(cg_tree_ptr_t(n)^.count - n^.xw[13] - 1, 2, c);
          address_reg(0, r);
          emit(0, 2, r, c, 0);
          unlock(c);
        end;
  end;

begin
  if rtn <> nil then begin
    callee := rtn;
    desig := rtn;
    first := 1;
    if n = nil then
      last := 0
    else
      last := cg_tree_ptr_t(n)^.count;
    lib := true;
  end
  else begin
    callee := cg_tree_ptr_t(n)^.opnd[1];
    desig := callee;
    first := 2;
    last := cg_tree_ptr_t(n)^.count;
    lib := false;
  end;
  if callee^.kind = 110 then
    if not ((rshft(ord(callee^.xc[45]) & 16#38, 3) = 1) and
            (rshft(ord(callee^.xc[45]) & 6, 1) = 0)) then
      if callee^.xp[10] <> nil then
        callee := callee^.xp[10];
  copied := false;
  keep := false;
  pushed := 0;
  address_reg(15, push);
  push.f1 := 9;
  procvar := cg_call_$is_proc_var_call(callee);
  if (callee^.kind = 147) or (callee^.kind = 146) then
    desig := callee^.xp[7]
  else if callee^.kind = 175 then begin
    desig := callee^.xp[5];
    callee := callee^.xp[4];
  end;
  if at_backend_506 and (n <> nil) then
    if (n^.kind = 137) and (ord(n^.xc[7]) >= 128) then begin
      address_reg(15, op1);
      address(smcontk(81, 2), 0, op2);
      emit(2, 4, op1, op2, 0);
      pushed := 2;
    end;

  if desig^.kind = 171 then begin
    for i := last downto first do begin
      arg := cg_tree_ptr_t(n)^.opnd[i];
      size := cg_words_ptr_t(desig)^[10 + 2 * (i - first)];
      copy_to_stack(size, arg);
      copied := true;
      unlock(op1);
      pushed := pushed + size;
    end;
    callee := desig^.xp[4];
  end
  else begin
    params := nil;
    if desig^.kind = 159 then begin
      if last - first + 1 > desig^.xw[5] then
        nparams := desig^.xw[5]
      else
        nparams := last - first + 1;
    end
    else if (desig^.kind = 108) or (desig^.kind = 107) then
      params := desig^.xp[3]
    else if (desig^.kind = 174) or (desig^.kind = 173) then
      params := desig^.xp[1];
    pass_len := false;
    if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
      if pass_char_len_diff(desig) and not lib then
        if (n^.xw[13] <> 0) and (n^.xw[12] = 9) then
          pass_len := true;

    for i := last downto first do begin
      if pass_len then begin
        if (last - n^.xw[13] + 1 < i) or (i = first) then
          arg := cg_tree_ptr_t(n)^.opnd[i]
        else if i = first + 1 then
          arg := cg_tree_ptr_t(n)^.opnd[last - n^.xw[13] + 1]
        else
          arg := cg_tree_ptr_t(n)^.opnd[i - 1];
      end
      else
        arg := cg_tree_ptr_t(n)^.opnd[i];
      if arg^.kind = 195 then begin
        v := arg^.xp[3];
        if v^.kind = 110 then
          if rshft(ord(v^.xc[44]) & 16#F0, 4) = 1 then
            if v^.xp[10] <> nil then
              arg^.xp[3] := v^.xp[10];
      end;

      { The argument's class. }
      b := false;
      if (i = first + 1) and pass_len then
        cls := 2
      else if (rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2) and not lib and
          (last - n^.xw[13] + ord(pass_len) < i) then begin
        if pass_char_len_diff(desig) then
          cls := 2
        else
          cls := 8;
      end
      else
        case desig^.kind of
          159: begin
            k := i - first + 1;
            if nparams < k then
              if ord(desig^.xc[10 + 2 * nparams]) < 128 then
                nparams := desig^.xw[5];
            cls := ord(desig^.xc[11 + 2 * nparams]) & 15;
            nparams := nparams - 1;
          end;
          167, 108, 107: begin
            if rshft(ord(desig^.xc[377]) & 16#70, 4) = 4 then
              b := true
            else if n^.xw[12] = 9 then begin
              if i = first then
                cls := 11
              else
                cls := cg_words_ptr_t(desig)^[197 + i - first];
            end
            else
              cls := cg_words_ptr_t(desig)^[198 + i - first];
          end;
          174, 173: cls := cg_words_ptr_t(desig)^[40 + i - first];
          otherwise b := true;
        end;
      if b then
        case arg^.kind of
          77, 86, 200, 87: cls := 7;
          78, 83, 80: cls := 8;
          84, 81: begin
            if ((desig^.kind = 107) or (desig^.kind = 167) or
                (desig^.kind = 108)) and
                (rshft(ord(desig^.xc[377]) & 16#70, 4) = 4) then
              cls := 8
            else if cargs_$options.i_star_2 then
              cls := 8
            else
              cls := 9;
          end;
          otherwise cls := 9;
        end;

      { The argument pushed. }
      done := false;
      if not lib and (cls <> 6) then begin
        if (arg^.kind = 137) and ((cg_tree_ptr_t(arg)^.op = 26) or
            (cg_tree_ptr_t(arg)^.op = 0)) and (arg^.xw[8] = 1) and
            (cls < 6) then begin
          tree_walk(cg_tree_ptr_t(arg)^.opnd[1]);
          if cg_fp_count <> 0 then
            purge_fp;
          address(cg_tree_ptr_t(arg)^.opnd[1], 0, op1);
          emit(23, 4, op1, cg_null_ads, 0);
          done := true;
        end
        else begin
          tree_walk(arg);
          if cg_fp_count <> 0 then
            purge_fp;
        end;
      end;
      if not done then begin
        if cls < 6 then begin
          w := delay_398[cls];
          if peek(arg, w) = 31 then begin
            if w = 5 then begin
              if peek(arg, 4) <> 31 then
                w := 4;
            end
            else if w = 4 then begin
              if peek(arg, 5) <> 31 then
                w := 5;
            end;
          end;
          address(arg, w, op1);
          fault_free_assign(w, push, op1);
        end
        else if cls = 6 then begin
          v := params;
          for k := 1 to i - first do
            v := v^.xp[1];
          size := (v^.xl[7] + 7) div 8;
          if odd(size) then
            size := size + 1;
          copy_to_stack(size, arg);
          copied := true;
          pushed := pushed + size;
        end
        else begin
          in_reg := chk_addr(arg, op1) <> 31;
          if in_reg then begin
            cg_addr_locks[op1.f2] := cg_addr_locks[op1.f2] + 1;
            emit(0, 4, push, op1, 0);
          end
          else if arg^.kind = 146 then begin
            if peek(arg^.xp[6], 4) <> 31 then begin
              address(arg^.xp[6], 4, op1);
              fault_free_assign(5, push, op1);
            end
            else begin
              if peek(arg^.xp[6], 4) = 31 then
                w := 5
              else
                w := 4;
              address(arg^.xp[6], w, op1);
              fault_free_assign(5, push, op1);
            end;
          end
          else begin
            moved := false;
            if (arg^.kind = 109) and ((arg^.xl[8] & 16#20000) <> 0) and
                (arg^.xp[14] = nil) and (cls >= 7) then begin
              w := call_link_ptr_t(arg^.xp[13]^.xp[2])^.p^.xw[26];
              if chk_assign(arg, w) <> 31 then begin
                t := nil;
                t := allocate_temp(w, true, t);
                r := peek(arg, w);
                address_reg(r, areg);
                address(t, 4, op1);
                emit(0, 5, op1, areg, 0);
                moved := true;
              end;
            end;
            if not moved then begin
              if arg^.kind = 190 then
                v := arg^.xp[1]
              else if arg^.kind = 189 then
                v := arg^.xp[5]
              else
                v := arg;
              w := v^.xw[12];
              r := peek(arg, w);
              nint := false;
              if (r <> 31) and (v^.kind = 138) then begin
                nint := cg_call_$is_a_nint(v);
                if not nint then
                  if cg_tree_ptr_t(v)^.op = 18 then
                    if cg_tree_ptr_t(v)^.opnd[1]^.kind = 138 then
                      nint := cg_call_$is_a_nint(cg_tree_ptr_t(v)^.opnd[1]);
              end;
              if nint then begin
                t := nil;
                t := allocate_temp(w, true, t);
                address_reg(r, areg);
                address(t, w, op1);
                emit(0, w, op1, areg, 0);
              end
              else begin
                address(arg, 0, op1);
                regs := cg_addr_$operand_in_reg_any_rlen(arg);
                if (arg^.kind = 147) and (regs <> 0) then
                  for r := 0 to 31 do
                    if (regs & lshft(1, r)) <> 0 then begin
                      if regs <> lshft(1, r) then
                        bug_check('Object in multiple registers%.');
                      address_reg(r, areg);
                      address(arg^.xp[6], 0, op2);
                      emit(0, cg_addr_regs[r].size, op2, areg, 0);
                      unlock(op2);
                    end;
              end;
            end;
            w := 5;
            if delay_398[cls] < 5 then
              w := delay_398[cls];
            emit(23, w, op1, cg_null_ads, 0);
          end;
        end;
      end;
      unlock(op1);
      if cls <= 1 then
        pushed := pushed + 2
      else if cls <> 6 then
        pushed := pushed + 4;
    end;
  end;

  { The result's temporary. }
  result_temp := false;
  if n <> nil then
    if (n^.xw[12] >= 7) and (n^.xw[12] <> 9) then begin
      get_temp(n, false);
      n^.kind := 138;
      address(n, 0, op1);
      emit(23, 4, op1, cg_null_ads, 0);
      pushed := pushed + 4;
      result_temp := true;
    end;
  if not cargs_$options.xrs or odd(ord(il_180^.xc[375])) then
    keep := true;
  if (callee^.kind = 108) or (callee^.kind = 107) then
    if odd(ord(callee^.xc[375])) then
      keep := true;
  if n <> nil then begin
    v := cg_tree_ptr_t(n)^.opnd[1];
    if v^.kind = 175 then begin
      t := v^.xp[5];
      if (t^.kind = 174) or (t^.kind = 173) then
        if (t^.xw[35] & 16#200) <> 0 then
          keep := true;
    end;
  end;
  if keep then
    setobjcache(callee, 8);
  tree_walk(callee);
  for i := last downto first do
    if (desig^.kind <> 171) or
        (cg_words_ptr_t(desig)^[10 + 2 * (i - first)] = 4) then
      if not copied then begin
        address_reg(14, op1);
        op1.x := integer32(cg_tree_ptr_t(n)^.opnd[i]);
        release(op1);
      end;

  { The call. }
  address_reg(8, areg);
  called := false;
  if procvar then begin
    if keep or not cargs_$options.xrs or odd(ord(il_180^.xc[375])) then
        begin
      cg_addr_2b6 := 8;
      address(callee, 5, op1);
      emit(22, 5, areg, op1, 0);
      release(op1);
      kill_register(areg.f2);
    end
    else
      address(callee, 5, areg);
    varargs_moveq_d0(n);
    areg.f1 := 2;
    emit(24, 5, areg, cg_null_ads, 0);
    if cargs_$options.xrs and not keep then
      release(areg);
    called := true;
  end
  else if (callee^.kind = 107) or (callee^.kind = 167) or
      (callee^.kind = 108) then begin
    if rshft(callee^.xw[188] & 16#180, 7) = 0 then
      if not cg_call_$att_in_any_entry(1, callee) then begin
        if (callee^.xw[189] & 4) <> 0 then begin
          if cg_call_$att_in_any_entry(8, callee) then
            il_180^.xc[375] := chr(ord(il_180^.xc[375]) ! 8);
        end
        else if callee <> il_180 then begin
          t := il_180^.xp[48];
          if (t^.xl[5] + t^.xl[6] - t^.xl[4] = 0) and
              (7 in cargs_$options.flags_286) then
            callee^.xc[376] := chr(ord(callee^.xc[376]) ! 16)
          else
            il_180^.xc[375] := chr(ord(il_180^.xc[375]) ! 8);
        end;
      end;
    if not cg_call_$att_in_any_entry(1, callee) and
        (cg_level_ptr_t(callee)^.level > 0) then
      if callee^.xp[48] <> il_180^.xp[48] then
        cgerr(27, cg_line, callee);
    if (ord(callee^.xc[378]) & 64) <> 0 then begin
      if cg_level_ptr_t(callee)^.level > cg_level_ptr_t(il_180)^.level then
        address_reg(14, op1)
      else begin
        t := il_180^.xp[60];
        for k := 1 to cg_level_ptr_t(il_180)^.level -
            cg_level_ptr_t(callee)^.level do
          t := t^.xp[3];
        address(t, 5, op1);
      end;
      address_reg(9, link);
      emit(0, 5, link, op1, 0);
      release(op1);
    end;
    if rshft(callee^.xw[188] & 16#180, 7) = 0 then begin
      if 7 in cargs_$options.flags_286 then begin
        if il_180^.xp[47] <> callee^.xp[47] then begin
          address(callee, 5, op1);
          varargs_moveq_d0(n);
          emit(24, 5, op1, cg_null_ads, 0);
          called := true;
        end;
      end
      else if il_180^.xp[47] = callee^.xp[47] then begin
        if il_180^.xp[48] = callee^.xp[48] then begin
          if cg_call_$att_in_any_entry(1, callee) then begin
            go := true;
            if (il_180 = callee) or ((callee^.xw[189] & 4) <> 0) then
              go := cg_call_$att_in_any_entry(8, callee);
            if go then begin
              address_reg(13, op1);
              address_reg(8, areg);
              emit(0, 5, areg, op1, 0);
              kill_register(8);
            end;
          end;
        end
        else begin
          go := true;
          if (callee = il_180) or ((callee^.xw[189] & 4) <> 0) then begin
            b := cg_call_$att_in_any_entry(8, callee);
            go := cg_call_$att_in_any_entry(1, callee) and b;
          end;
          if go then begin
            address(make_new_addr_con(10, callee^.xp[48], callee^.xl[27],
                il_180^.xp[48], false), 0, op1);
            emit(0, 5, areg, op1, 0);
            varargs_moveq_d0(n);
            areg.f1 := 2;
            emit(24, 5, areg, cg_null_ads, 0);
            called := true;
          end;
        end;
      end
      else begin
        if il_180^.xp[48] = callee^.xp[48] then begin
          address_reg(13, op1);
          op1.f1 := 2;
          op1.y := callee^.xl[27];
          emit(22, 5, areg, op1, 0);
        end
        else begin
          address(make_new_addr_con(10, callee^.xp[48], callee^.xl[27],
              il_180^.xp[48], false), 0, op1);
          emit(0, 5, areg, op1, 0);
        end;
        varargs_moveq_d0(n);
        areg.f1 := 2;
        emit(24, 5, areg, cg_null_ads, 0);
        called := true;
      end;
      if not called then begin
        address(callee, 0, areg);
        areg.f1 := 0;
        address(callee^.xp[25], 0, op1);
        varargs_moveq_d0(n);
        emit(31, 5, op1, areg, 0);
        called := true;
      end;
    end;
  end;
  if not called then begin
    if not (7 in cargs_$options.flags_286) then begin
      offset := 0;
      t := get_addr_con(2, callee, offset, il_180^.xp[48], false);
      address(t, 0, op1);
      kill_register(areg.f2);
      emit(0, 5, areg, op1, 0);
    end;
    varargs_moveq_d0(n);
    if 7 in cargs_$options.flags_286 then begin
      address(get_transfer_vector(callee), 0, op1);
      emit(24, 5, op1, cg_null_ads, 0);
    end
    else begin
      areg.f1 := 2;
      areg.x := integer32(callee);
      emit(24, 5, areg, cg_null_ads, 0);
    end;
  end;

  { The arguments popped. }
  if (4 in cargs_$options.flags_286) and (n <> nil) then
    if (n^.kind = 137) and (cg_top_142 = 1) then begin
      if (pushed & 3) <> 0 then
        n^.xc[7] := chr(ord(n^.xc[7]) ! 16#80)
      else
        n^.xc[7] := chr(ord(n^.xc[7]) & 16#7F);
    end;
  if pushed <> 0 then begin
    address_reg(15, op1);
    address(smcontk(81, pushed), 0, areg);
    emit(1, 2, op1, areg, 0);
  end;

  { The registers and objects the call may change. }
  regs := reg_save(desig);
  if desig^.kind <> 159 then
    cg_fp_last_op := 147;
  if n <> nil then begin
    saved := cg_tree_ptr_t(n)^.opnd[1];
    cg_tree_ptr_t(n)^.opnd[1] := desig;
  end;
  for r := 0 to 23 do
    if (regs & lshft(1, r)) = 0 then begin
      kill_register(r);
      cg_addr_killed[r] := true;
      cg_addr_cache[r].param_alias := false;
    end
    else if not lib then begin
      with cg_addr_regs[r] do begin
        if (obj <> nil) and (obj <> il_178) then
          if cg_call_$obj_is_modifiable_by_param(obj) then begin
            alias_$alias_desc_with_size(obj, delay_378[size], d);
            if (cg_addr_cache[r].obj <> nil) and
                (cg_addr_cache[r].obj = obj) and
                (cg_addr_cache[r].size = size) and
                cg_addr_cache[r].param_alias then
              cg_call_$kill_any_param_alias(n, d,
                  cg_addr_cache[r].param_alias, obj)
            else if alias_$related_call(d, n) then
              obj := nil;
          end;
        if (obj2 <> nil) and (obj2 <> il_178) then
          if cg_call_$obj_is_modifiable_by_param(obj2) then begin
            alias_$alias_desc_with_size(obj2, delay_378[size], d);
            if (cg_addr_cache[r].obj <> nil) and
                (cg_addr_cache[r].obj = obj2) and
                (cg_addr_cache[r].size = size) and
                cg_addr_cache[r].param_alias then
              cg_call_$kill_any_param_alias(n, d,
                  cg_addr_cache[r].param_alias, obj2)
            else if alias_$related_call(d, n) then
              obj2 := nil;
          end;
      end;
      with cg_addr_cache[r] do
        if (obj <> nil) and param_alias then
          if cg_call_$obj_is_modifiable_by_param(obj) then begin
            alias_$alias_desc_with_size(obj, delay_378[size], d);
            cg_call_$kill_any_param_alias(n, d, param_alias, dummy);
          end;
    end;

  { The result's register. }
  if n <> nil then begin
    cg_tree_ptr_t(n)^.opnd[1] := saved;
    w := n^.xw[12];
    if w <= 6 then
      if (w = 5) and (cg_tree_ptr_t(n)^.opnd[1]^.kind = 171) then begin
        t := cg_tree_ptr_t(n)^.opnd[1]^.xp[4];
        if t^.kind = 146 then begin
          v := t^.xp[6];
          while (v^.kind = 146) or (v^.kind = 147) do
            v := v^.xp[6];
          if v^.kind = 234 then begin
            if (v^.xw[3] & 16#200) = 0 then begin
              setresult(0, n, n^.xw[12]);
              cg_addr_regs[0].size := n^.xw[12];
            end
            else
              setresult(8, n, n^.xw[12]);
          end
          else
            setresult(0, n, n^.xw[12]);
        end
        else if (t^.kind = 108) or (t^.kind = 107) then begin
          if (ord(t^.xc[375]) & 16) = 0 then begin
            setresult(0, n, w);
            cg_addr_regs[0].size := n^.xw[12];
          end
          else
            setresult(8, n, w);
        end
        else
          setresult(0, n, w);
      end
      else begin
        atts := get_atts(cg_tree_ptr_t(n)^.opnd[1]);
        if n^.xw[12] = 5 then begin
          if ((atts & 16#200) <> 0) or ((atts & 16#80) = 0) then
            setresult(8, n, 5)
          else
            setresult(0, n, 4);
        end
        else if (atts & 16#280) = 16#200 then begin
          address_reg(8, op2);
          address_reg(0, op4);
          emit(0, 4, op4, op2, 0);
          setresult(0, n, n^.xw[12]);
        end
        else
          setresult(0, n, n^.xw[12]);
      end;
  end;
end;
