{ com - the PRISM back end's common subexpression phase (COM): the
  blocks' instructions optimized (cses, loads and stores eliminated,
  instructions hoisted out of loops, memory references in loops kept
  in registers), the memory model analyzed, then the motions (trans),
  life and copy elimination.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x225DF4  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x225E16  clean_up_this_mess_right_now_young_man (internal)
    --------  0x225E48  operand_reg_like_kind
    --------  0x225E82  local_replace_output (internal)
    --------  0x226514  find_exit_writer (internal)
    --------  0x22670C  make_entering_lts (internal)
    --------  0x22676E  find_calls_snuggle_move (internal)
    --------  0x226898  com_$replace_oprs_value (internal)
    --------  0x226E38  no_reg_like_kinds (internal)
    --------  0x22C02A  com_$begin_compilation
    --------  0x22C064  com_$end_compilation
    --------  0x22C080  com_$end_routine
    A5 0x485E60: the module's data: com_heap (+0), com_name (+24, a
    varying string: the routine's fully qualified name), +284 (set to
    100), com_rtn (+288), com_level (+296), +304 and +308 (booleans),
    +306, +312, +316.

  Not known from the original: every local, parameter and cell name. }

{ TODO(pascal) com: 12 of the image's 63 routines.  Remaining, in
  address order: build_loads (0x226E62),
  build_stores (0x22723E), replace_mem_instrs (0x2274D0),
  ip_mem_reference (0x227A0A), analyze_candidates (0x227A8C),
  add_lr_to_list (0x227C1A), add_lr_to_list_uniquely (0x227C6A),
  add_lrs_to_ssa_list (0x227CB8), is_invariant (0x227D9C),
  loop_invariant_addr (0x227E04), consider_mem_dependents (0x227EDE),
  partition_memory (0x2282B8), is_join_bp (0x2283A8, global),
  worth_hoisting (0x2283DC), find_loop_memory_hoist_candidates
  (0x22841A), lr_unconsumed_in_loop (0x22876C),
  lr_value_same_on_loop_exit (0x228836), suck_instrs_from_loop
  (0x228968), collect_exit_blocks (0x228D58), collect_loop_contents
  (0x228DF2), entry_blocks_safe (0x228F50), exit_blocks_safe
  (0x228F8A), loop_memory_analysis (0x229074), cvt_short_load_to_32_bits
  (0x22915E), eliminate_load (0x22930C), attempt_load_elimination
  (0x22960E), excise_a_store (0x2297D2), simple_mmt_seq_input
  (0x2298D2) with get_the_right_instr (0x229968, nested),
  ltss_on_stores_to_same_addr (0x2299CA, global), store_is_redundant
  (0x229A9E, global), get_mem_birthpoint (0x229B3A, global),
  safe_to_ignore_do_not_delete (0x229BB2), convert_store_to_seq
  (0x229C96), attempt_store_elimination (0x229D86),
  attempt_do_not_delete_removal (0x22A03C), move_is_zero (0x22A0B2),
  replace_zero_valued_lrs (0x22A19A), calc_last_legal_dom_bb
  (0x22A224), def_dominates_use (0x22A276), bb_postdominates
  (0x22A2B8), maybe_hoist_instr_from_loop (0x22A2F6), connect_physical
  (0x22A6B4), call_cossin (0x22A760: lir_3f94 .. lir_3f9c), safe_cc_write
  (0x22AEFC), operand_is_trapcc_input (0x22AFB0), destroy_instr
  (0x22AFF0), process_instruction (0x22B46C, 0x888 bytes),
  optimize_block (0x22BEAA), com_$compute_cses (0x22BFD2: sets com_rtn
  and com_level, clears +308 and +304, optimize_block(rtn^.bbs, nil)
  between mrh_$mark and mrh_$release_to_mark of com_heap),
  com_$process_routine (0x22C082: the name, the level, +284 := 100,
  sanity check; unless switches 15 (and cargs +0x4437D4) the snuggle
  moves and lts properties, a dump with switch 3; unless switches 15 or
  14: compute_cses, clean_up_this_mess..., unless switch 12 the memory
  analysis (unless switch 9 mmt_utils_$analyze_blocks), then
  loop_memory_analysis and compute_cses again while +304; with +308
  attempt_do_not_delete_removal; the global walk, the motions,
  replace_zero_valued_lrs, life, copy elimination, each with the
  level's messages and dumps). }
module com;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang/lang/source/at_lib_dsc.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

var
  com_heap: mrh_$heap_t;                { +0: the hash table's heap }
  com_20: integer32;                    { +20 }
  com_name: varying [256] of char;      { +24: the routine's name }
  com_284: integer32;                   { +284 (set to 100) }
  com_rtn: rtn_ptr_t;                   { +288 }
  com_292: integer32;                   { +292 }
  com_level: integer32;                 { +296: the switches' level }
  com_300: integer32;                   { +300 }
  com_304: boolean;                     { +304 }
  com_306: integer;                     { +306 }
  com_308: boolean;                     { +308 }
  com_312: integer32;                   { +312 }
  com_316: integer32;                   { +316 }

{ clean_up_this_mess_right_now_young_man - rtn's instructions numbered
  again from 1 in code order.  0x225E16, 0x32 bytes, no frame: the
  count a longword stored as a word. }

procedure clean_up_this_mess_right_now_young_man(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  n: integer32;
  b: bb_ptr_t;
  i: instr_ptr_t;
begin
  n := 1;
  b := rtn^.bbs;
  while b <> nil do begin
    i := b^.first;
    while i <> nil do begin
      i^.num := n;
      n := n + 1;
      i := i^.next;
    end;
    b := b^.next;
  end;
end;

{ operand_reg_like_kind - the like kind of a register kind (ip_reg,
  fp_reg, fp_reg_pair), any other kind itself.  0x225E48, 0x3A bytes
  (loads A5: global, though no other unit calls it): k by address. }

function operand_reg_like_kind(
    in k: operand$t): operand$t;
var
  r: operand$t;
begin
  r := k;
  case k of
    operand$ip_reg:
      r := operand$ip_reg_like;
    operand$fp_reg:
      r := operand$fp_reg_like;
    operand$fp_reg_pair:
      r := operand$fp_reg_pair_like;
  end;
  operand_reg_like_kind := r;
end;

{ local_replace_output - o's value (o and, for a register pair, its
  mate operand writing into l2) given to the segment l (and l2) instead
  of its own: when the even/odd requirements of o's readers allow,
  neither segment means to modify, and the live ranges are simple (or
  replace, or may_merge and marked +3 bit 1), o's readers simply join
  l's (and the mate's l2's); when they cannot join (a paired floating
  live range, a physical register's, replace, a segment or live range
  that means to modify or is final), a preference MOVE at `at' copies
  l (l2) into o's segment(s), its sources reg-like kinds with replace;
  when the requirements fail, l (l2) and their live ranges are made
  read, a preference MOVE after the later of their definitions (or at
  the head of at's block) copies them into new segments of a new live
  range of o's kind, which are tried again (may_merge then true,
  replace false).  The segment that holds the value is returned.

  0x225E82, 0x612 bytes, no A5: the kinds `btst' in 16#4048, 16#2024
  and 16#21012; may_merge's register reused for o's kind once past
  the tests; operand_reg_like_kind's argument a frame word, its second
  call's argument left on the stack. }

function local_replace_output(
    l: lts_ptr_t;
    l2: lts_ptr_t;
    o: opnd_ptr_t;
    at: instr_ptr_t;
    may_merge: boolean;
    replace: boolean): lts_ptr_t; options(val_param); internal;
var
  res, res2, nl, nl2: lts_ptr_t;
  m, p, def, def2: opnd_ptr_t;
  eo, rrp: integer;
  mv, a, i: instr_ptr_t;
  lr, nlr: lr_ptr_t;
  after, done, ok: boolean;
  k: operand$t;
begin
  res := l;
  if l2 <> nil then
    res2 := l2
  else
    res2 := res;
  if o^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                   operand$fp_reg_pair_like] then begin
    m := lir_utils_$find_mate_operand(o);
    if (l2 = nil) or (m = nil) or (rrp$fp_reg_odd_only in res^.rrp)
        or (rrp$fp_reg_even_only in res2^.rrp) or o^.h.fp_reg_odd_only
        or m^.h.fp_reg_even_only then
      bug_check('COM_$local_replace_output: unreasonable reg_pair requirements.%$');
    eo := 0;
  end
  else if o^.h.kind in [operand$fp_reg, operand$fp_reg_physical,
                        operand$fp_reg_like] then begin
    if o^.lts^.f2.final then
      eo := opnd_bytes_ptr_t(o)^.rrp & 3
    else begin
      eo := 0;
      p := o^.link;
      while p <> nil do begin
        eo := eo ! (opnd_bytes_ptr_t(p)^.rrp & 3);
        p := p^.link;
      end;
      if eo = 3 then
        bug_check('COM_$local_replace_output: unreasonable fp_reg requirements.%$');
    end;
    m := o;
  end
  else begin
    m := o;
    eo := 0;
  end;
  repeat
    done := true;
    ok := ((~eo & integer(res^.rrp) & 3) = 0) or (eo = 0);
    if ok then
      if (rrp$intend_to_modify in res2^.rrp)
          or (rrp$intend_to_modify in res^.rrp) then
        ok := false;
    if ok then begin
      lr := res^.lr;
      if not ((lr^.id = 0) or replace or (may_merge and lr^.f2.b3_1)) then
        ok := false
      else begin
        lr := res2^.lr;
        if not ((lr^.id = 0) or replace) then
          if not may_merge then
            ok := false
          else if not lr^.f2.b3_1 then
            ok := false;
      end;
    end;
    if ok then begin
      if o^.h.kind in [operand$fp_reg, operand$fp_reg_physical,
                       operand$fp_reg_like] then
        ok := o^.lts^.lr^.mate <> nil
      else
        ok := false;
      lr := o^.lts^.lr;
      if not ok and not lr^.f2.physical and not replace
          and not (rrp$intend_to_modify in m^.lts^.rrp)
          and not (rrp$intend_to_modify in lr^.rrp)
          and not lr^.f2.b3_4 and not m^.lts^.f2.final then begin
        { o's readers join l's }
        p := res^.refs;
        if p = nil then begin
          res^.refs := o^.link;
          p := o^.link;
        end
        else begin
          while p^.link <> nil do
            p := p^.link;
          p^.link := o^.link;
        end;
        rrp := integer(res^.rrp) & 3;
        o^.link := nil;
        while p <> nil do begin
          p^.lts := res;
          opnd_bytes_ptr_t(p)^.rrp := (opnd_bytes_ptr_t(p)^.rrp & 16#FC) ! rrp;
          p := p^.link;
        end;
        if o <> m then begin
          p := res2^.refs;
          if p = nil then begin
            res2^.refs := m^.link;
            p := m^.link;
          end
          else begin
            while p^.link <> nil do
              p := p^.link;
            p^.link := m^.link;
          end;
          m^.link := nil;
          while p <> nil do begin
            p^.lts := res2;
            p := p^.link;
          end;
        end;
      end
      else begin
        { a preference move copies l into o's segment }
        mv := lir_utils_$create_preference_move(o^.h.kind, at, false);
        mv^.opnds[1].lts := res;
        if not replace then begin
          p := res^.refs;
          if p = nil then
            res^.refs := addr(mv^.opnds[1])
          else begin
            mv^.opnds[1].link := p^.link;
            p^.link := addr(mv^.opnds[1]);
          end;
        end
        else begin
          k := operand_reg_like_kind(o^.h.kind);
          mv^.opnds[1].h.kind := k;
          mv^.h.b0_6 := false;
        end;
        opnd_bytes_ptr_t(addr(mv^.opnds[2]))^.rrp :=
            opnd_bytes_ptr_t(addr(mv^.opnds[2]))^.rrp ! eo;
        mv^.opnds[2].link := o^.link;
        mv^.opnds[2].lts := o^.lts;
        o^.lts^.refs := addr(mv^.opnds[2]);
        if o <> m then begin
          mv^.opnds[3].lts := res2;
          if not replace then begin
            p := res2^.refs;
            if p = nil then
              res2^.refs := addr(mv^.opnds[3])
            else begin
              mv^.opnds[3].link := p^.link;
              p^.link := addr(mv^.opnds[3]);
            end;
          end
          else begin
            k := operand_reg_like_kind(o^.h.kind);
            mv^.opnds[3].h.kind := k;
          end;
          mv^.opnds[4].link := m^.link;
          mv^.opnds[4].lts := m^.lts;
          m^.lts^.refs := addr(mv^.opnds[4]);
        end;
      end;
    end
    else begin
      { copied into a new live range, tried again }
      res^.rrp := res^.rrp + [rrp$read];
      res^.lr^.rrp := res^.lr^.rrp + [rrp$read];
      if res <> res2 then begin
        res2^.rrp := res2^.rrp + [rrp$read];
        res2^.lr^.rrp := res2^.lr^.rrp + [rrp$read];
      end;
      def := res^.refs;
      a := nil;
      def2 := res2^.refs;
      if def <> nil then
        if (opnd_bytes_ptr_t(def)^.rrp & 12) <> 0 then
          a := utils_ins_$operands_instruction(def);
      if def2 <> def then
        if def2 <> nil then
          if (opnd_bytes_ptr_t(def2)^.rrp & 12) <> 0 then begin
            i := utils_ins_$operands_instruction(def2);
            if a = nil then
              a := i
            else if a^.num < i^.num then
              a := i;
          end;
      if a = nil then begin
        a := at^.bb^.first;
        while (a^.opc = ord(opc$join_bp)) or (a^.opc = ord(opc$label)) do
          a := a^.next;
        after := false;
      end
      else
        after := true;
      if after then
        mv := lir_utils_$create_preference_move(o^.h.kind, a, true)
      else
        mv := lir_utils_$create_preference_move(o^.h.kind, a, false);
      if (def = nil) or ((opnd_bytes_ptr_t(def)^.rrp & 12) = 0) then begin
        mv^.opnds[1].link := def;
        res^.refs := addr(mv^.opnds[1]);
      end
      else begin
        mv^.opnds[1].link := def^.link;
        def^.link := addr(mv^.opnds[1]);
      end;
      mv^.opnds[1].lts := res;
      if res <> res2 then begin
        if (def2 = nil) or ((opnd_bytes_ptr_t(def2)^.rrp & 12) = 0) then begin
          mv^.opnds[3].link := def2;
          res2^.refs := addr(mv^.opnds[3]);
        end
        else begin
          mv^.opnds[3].link := def2^.link;
          def2^.link := addr(mv^.opnds[3]);
        end;
        mv^.opnds[3].lts := res2;
      end;
      if res <> res2 then
        nlr := lir_$new_live_range_fp_reg_pair
      else if o^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                            operand$ip_reg_like, operand$case_jump_base] then
        nlr := lir_$new_live_range_ip_reg
      else if o^.h.kind in [operand$fp_reg, operand$fp_reg_physical,
                            operand$fp_reg_like] then
        nlr := lir_$new_live_range_fp_reg
      else
        nlr := lir_$new_live_range;
      lir_utils_$add_lts_to_lr(24, nlr, o^.lts^.bb, nl);
      if nlr^.mate <> nil then
        lir_utils_$add_lts_to_lr(24, nlr^.mate, o^.lts^.bb, nl2);
      mv^.opnds[2].link := nil;
      opnd_bytes_ptr_t(addr(mv^.opnds[2]))^.rrp :=
          opnd_bytes_ptr_t(addr(mv^.opnds[2]))^.rrp ! eo;
      mv^.opnds[2].lts := nl;
      nl^.refs := addr(mv^.opnds[2]);
      if nlr^.mate <> nil then begin
        mv^.opnds[4].link := nil;
        mv^.opnds[4].lts := nl2;
        nl2^.refs := addr(mv^.opnds[4]);
      end;
      nlr^.f2.b3_1 := true;
      res := nl;
      if nlr^.mate = nil then
        res2 := nl
      else begin
        nlr^.mate^.f2.b3_1 := true;
        res2 := nl2;
      end;
      may_merge := true;
      replace := false;
      done := false;
    end;
  until done;
  local_replace_output := res;
end;

{ find_exit_writer - the segment o (and its mate o2 of a register
  pair) writes, when it can carry the value out of its block: already
  final and marked (+3 bit 1) for both, or made so (a simple live range
  that is not modified made complex, the segment put on its block's
  final list and its live range marked); else the segment found the
  same way through a MOVE, COPYS or COPYD (marked +0 bit 6) whose first
  operand is a plain reader of o's (and o2's, the same instruction)
  segment; nil when there is none.  0x226514, 0x1F8 bytes, no A5:
  recursive; com_rtn read through the caller's A5; the kinds `btst' in
  4094 and 16#4048. }

function find_exit_writer(
    o: opnd_ptr_t;
    o2: opnd_ptr_t): lts_ptr_t; options(val_param); internal;
var
  pair, ok: boolean;
  l: lts_ptr_t;
  lr2, lr: lr_ptr_t;
  i, ip, iq: instr_ptr_t;
  b: bb_ptr_t;
  p, q: opnd_ptr_t;
  r: lts_ptr_t;
begin
  if o2 <> nil then
    pair := true
  else begin
    pair := false;
    o2 := o;
  end;
  l := o2^.lts;
  lr2 := l^.lr;
  if lr2^.f2.b3_1 and l^.f2.final and o^.lts^.f2.final
      and o^.lts^.lr^.f2.b3_1 then begin
    find_exit_writer := o^.lts;
    return;
  end;
  if not (rrp$modify in lr2^.rrp) and (lr2^.id = 0) then begin
    lr := o^.lts^.lr;
    if (lr^.id = 0) and not (rrp$modify in lr^.rrp) then begin
      bv_$make_live_range_complex(com_rtn, lr);
      i := utils_ins_$operands_instruction(o);
      b := i^.bb;
      l := o^.lts;
      l^.f2.final := true;
      l^.lr^.f2.b3_1 := true;
      l^.next_final := b^.finals;
      b^.finals := l;
      if pair then begin
        l := o2^.lts;
        l^.f2.final := true;
        l^.lr^.f2.b3_1 := true;
        l^.next_final := b^.finals;
        b^.finals := l;
      end;
      find_exit_writer := o^.lts;
      return;
    end;
  end;
  q := l^.refs;
  p := o^.lts^.refs;
  while p <> nil do begin
    if ((opnd_bytes_ptr_t(q)^.rrp & 16#30) = 16#10)
        and (q^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
        and (p^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
        and ((opnd_bytes_ptr_t(p)^.rrp & 16#30) = 16#10) then begin
      ip := utils_ins_$operands_instruction(p);
      iq := utils_ins_$operands_instruction(q);
      if ((ip = iq) or not pair) and ip^.h.b0_6 and (p^.h.num = 1) then begin
        r := nil;
        ok := false;
        case ip^.opc of
          75:                           { move }
            ok := true;
          144:                          { copys }
            ok := not pair;
          161:                          { copyd }
            if pair then
              if q^.h.num = 3 then begin
                r := find_exit_writer(addr(ip^.opnds[2]), addr(ip^.opnds[4]));
                if r <> nil then begin
                  find_exit_writer := r;
                  return;
                end;
              end;
          otherwise
            ;
        end;
        if ok then begin
          r := find_exit_writer(addr(ip^.opnds[2]), nil);
          if r <> nil then begin
            find_exit_writer := r;
            return;
          end;
        end;
      end;
    end;
    if not pair then begin
      p := p^.link;
      q := p;
    end
    else begin
      p := p^.link;
      while p <> nil do begin
        if p^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                         operand$fp_reg_pair_like] then begin
          q := lir_utils_$find_mate_operand(p);
          if q <> nil then
            exit;
        end;
        p := p^.link;
      end;
    end;
  end;
  find_exit_writer := nil;
end;

{ make_entering_lts - lr's exposed segment in bb (made when it has
  none: chained to f, the final segment that reaches it, when f is of
  another block), marked read and its live range +3 bit 4.  0x22670C,
  0x62 bytes, no A5: the result utils_$get_exposed_lts's, left in A0
  (pattern 32; a function: com_$replace_oprs_value reads A0). }

function make_entering_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    f: lts_ptr_t): lts_ptr_t; options(val_param); internal;
var
  l: lts_ptr_t;
  created: boolean;
begin
  l := utils_$get_exposed_lts(lr, bb, created);
  l^.rrp := l^.rrp + [rrp$read];
  l^.lr^.f2.b3_4 := true;
  if created then
    if f <> nil then
      if f^.bb <> bb then begin
        l^.l44 := f;
        l^.l28 := f^.l28;
        f^.l28 := l;
      end;
  make_entering_lts := l;
end;

{ find_calls_snuggle_move - o's instruction when o has no reader; else
  (o a physical register's, read once) the instruction of its reader,
  when that is a snuggle move (+0 bit 6; for a register pair one whose
  opcode's +19 bits 2..0 are 3), or one inserted for it
  (lir_utils_$trans_insert_move).  0x22676E, 0xAE bytes, no A5. }

function find_calls_snuggle_move(
    o: opnd_ptr_t): instr_ptr_t; options(val_param); internal;
var
  i: instr_ptr_t;
begin
  if o^.link = nil then begin
    find_calls_snuggle_move := utils_ins_$operands_instruction(o);
    return;
  end;
  if not o^.lts^.lr^.f2.physical or (o^.link^.link <> nil) then
    bug_check('COM_$find_calls_snuggle_move:  physical operand looks funny.%$');
  i := utils_ins_$operands_instruction(o^.link);
  if i^.h.b0_6 then begin
    if not (o^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                          operand$fp_reg_pair_like]) then begin
      find_calls_snuggle_move := i;
      return;
    end;
    if (instruction_attributes[i^.opc].w18 & 7) = 3 then begin
      find_calls_snuggle_move := i;
      return;
    end;
  end;
  lir_utils_$trans_insert_move(o^.link);
  i := utils_ins_$operands_instruction(o^.link);
  if not i^.h.b0_6 then
    bug_check('COM_$find_calls_snuggle_move:  failed to find snuggle move.%$');
  find_calls_snuggle_move := i;
end;

{ com_$replace_oprs_value - the readers of old's value (and of its mate
  for a register pair) made to read new's instead, at `at': nothing
  when old's segments have no readers and are not final; a call's
  operands replaced by those of their snuggle moves (the move unlinked
  from its block afterwards); a value that is not in a register given
  to old's readers directly when old's segments are neither final nor
  meant to be modified; else new's segment (or the segment a new
  complex live range gets from a preference MOVE after new's
  instruction, or the one find_exit_writer finds, when new is of
  another block than at) entering at's block is given old's readers
  (local_replace_output); old's mate cleared.  0x226898, 0x536 bytes,
  no A5: com_rtn read through the caller's A5; the kinds `btst' in
  16#4048, 126, 16#21012 and 16#2024; the mate's readers relabelled
  from the mate operand itself. }

procedure com_$replace_oprs_value(
    new: opnd_ptr_t;
    old: opnd_ptr_t;
    at: instr_ptr_t); options(val_param); internal;
var
  nm, om, p: opnd_ptr_t;
  snug, i, mv: instr_ptr_t;
  fin, itm, notreg, merge: boolean;
  w, nl, nl2, e1, e2, f: lts_ptr_t;
  nlr: lr_ptr_t;
  b: bb_ptr_t;
begin
  merge := false;
  if new^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                     operand$fp_reg_pair_like] then
    nm := lir_utils_$find_mate_operand(new)
  else
    nm := nil;
  if old^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                     operand$fp_reg_pair_like] then
    om := lir_utils_$find_mate_operand(old)
  else
    om := nil;
  if old^.link = nil then
    if (old^.lts^.lr^.id = 0) or not old^.lts^.f2.final then begin
      if om = nil then
        return;
      if om^.link = nil then begin
        if om^.lts^.lr^.id = 0 then
          return;
        if not om^.lts^.f2.final then
          return;
      end;
    end;
  if om <> nil then
    if nm = nil then
      bug_check('COM_$replace_oprs_value: dst is reg_pair bug src is not.%$');
  snug := nil;
  if old^.lts^.lr^.f2.physical then begin
    i := utils_ins_$operands_instruction(old);
    if i^.opc = ord(opc$call) then begin
      snug := find_calls_snuggle_move(old);
      if snug = i then
        snug := nil
      else begin
        old^.link := nil;
        old := addr(snug^.opnds[2]);
        if om <> nil then begin
          om^.link := nil;
          om := lir_utils_$find_mate_operand(old);
          if om = nil then
            bug_check('COM_$replace_oprs_value:  failed to find mate.%$');
        end;
      end;
    end;
  end;
  if new^.lts^.lr^.f2.physical then
    if utils_ins_$operands_instruction(new)^.opc = ord(opc$call) then begin
      new := addr(find_calls_snuggle_move(new)^.opnds[2]);
      if nm <> nil then begin
        nm := lir_utils_$find_mate_operand(new);
        if nm = nil then
          bug_check('COM_$replace_oprs_value:  failed to find mate.%$');
      end;
    end;
  fin := old^.lts^.f2.final;
  itm := rrp$intend_to_modify in old^.lts^.rrp;
  if om <> nil then begin
    if om^.lts^.f2.final then
      fin := true;
    if rrp$intend_to_modify in om^.lts^.rrp then
      itm := true;
  end;
  notreg := not (new^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical]);
  if notreg and not fin and not itm then begin
    p := old^.link;
    while p <> nil do begin
      p^.h.kind := new^.h.kind;
      p^.ptr := new^.ptr;
      utils_ins_$operands_instruction(p)^.h.b0_6 := false;
      p := p^.link;
    end;
    old^.link := nil;
    if om <> nil then begin
      om := lir_utils_$find_mate_operand(old);
      p := om;
      while p <> nil do begin
        p^.h.kind := nm^.h.kind;
        p^.ptr := nm^.ptr;
        p := p^.link;
      end;
      om^.link := nil;
    end;
    return;
  end;
  if not notreg and (new^.lts^.bb <> at^.bb) then begin
    w := find_exit_writer(new, nm);
    if w <> nil then begin
      nlr := w^.lr;
      f := w;
    end
    else begin
      if new^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                         operand$ip_reg_like, operand$case_jump_base] then
        nlr := lir_$new_live_range_ip_reg
      else if new^.h.kind in [operand$fp_reg, operand$fp_reg_physical,
                              operand$fp_reg_like] then
        nlr := lir_$new_live_range_fp_reg
      else if new^.h.kind in [operand$fp_reg_pair,
                              operand$fp_reg_pair_physical,
                              operand$fp_reg_pair_like] then
        nlr := lir_$new_live_range_fp_reg_pair
      else
        nlr := lir_$new_live_range;
      lir_utils_$add_lts_to_lr(8, nlr, new^.lts^.bb, nl);
      if nlr^.mate <> nil then
        lir_utils_$add_lts_to_lr(8, nlr^.mate, new^.lts^.bb, nl2);
      bv_$make_live_range_complex(com_rtn, nlr);
      nl^.f2.first_in_bb := true;
      nlr^.f2.b3_1 := true;
      nl^.f2.final := true;
      nl^.next_final := new^.lts^.bb^.finals;
      new^.lts^.bb^.finals := nl;
      if nlr^.mate <> nil then begin
        nl2^.f2.first_in_bb := true;
        nlr^.mate^.f2.b3_1 := true;
        nl2^.f2.final := true;
        nl2^.next_final := new^.lts^.bb^.finals;
        new^.lts^.bb^.finals := nl2;
      end;
      mv := lir_utils_$create_preference_move(new^.h.kind,
          utils_ins_$operands_instruction(new), true);
      opnd_bytes_ptr_t(addr(mv^.opnds[1]))^.rrp :=
          opnd_bytes_ptr_t(addr(mv^.opnds[1]))^.rrp
          ! (opnd_bytes_ptr_t(new)^.rrp & 3);
      mv^.opnds[1].lts := new^.lts;
      mv^.opnds[1].link := new^.link;
      new^.link := addr(mv^.opnds[1]);
      mv^.opnds[2].link := nil;
      mv^.opnds[2].lts := nl;
      nl^.refs := addr(mv^.opnds[2]);
      if nlr^.mate <> nil then begin
        mv^.opnds[3].lts := nm^.lts;
        mv^.opnds[3].link := nm^.link;
        nm^.link := addr(mv^.opnds[3]);
        mv^.opnds[4].link := nil;
        mv^.opnds[4].lts := nl2;
        nl2^.refs := addr(mv^.opnds[4]);
      end;
      f := nl;
    end;
    if f^.f2.exposed then
      f := f^.l44;
    e1 := make_entering_lts(nlr, at^.bb, f);
    if nlr^.mate = nil then
      e2 := nil
    else
      e2 := make_entering_lts(nlr^.mate, at^.bb,
                              utils_$locate_definition(nlr^.mate, at^.bb));
    merge := true;
  end
  else begin
    e1 := new^.lts;
    if nm = nil then
      e2 := nil
    else
      e2 := nm^.lts;
  end;
  discard(local_replace_output(e1, e2, old, at, merge, notreg));
  if om <> nil then
    om^.h.kind := operand$none;
  if snug <> nil then begin
    snug^.h.b2_6 := false;
    b := snug^.bb;
    if snug^.prev = nil then
      b^.first := snug^.next
    else
      snug^.prev^.next := snug^.next;
    if snug^.next = nil then
      b^.last := snug^.prev
    else
      snug^.next^.prev := snug^.prev;
  end;
end;

{ no_reg_like_kinds - the register kind of a like kind (ip_reg_like,
  fp_reg_like, fp_reg_pair_like), any other kind itself.  0x226E38,
  0x2A bytes, no frame: k a word on the stack. }

function no_reg_like_kinds(
    k: operand$t): operand$t; options(val_param); internal;
begin
  case k of
    operand$ip_reg_like:
      no_reg_like_kinds := operand$ip_reg;
    operand$fp_reg_like:
      no_reg_like_kinds := operand$fp_reg;
    operand$fp_reg_pair_like:
      no_reg_like_kinds := operand$fp_reg_pair;
    otherwise
      no_reg_like_kinds := k;
  end;
end;

{ com_$begin_compilation - com_heap made (flags 1, items of 8 bytes).
  0x22C02A, 0x26 bytes: the flags and size pushed as one longword
  (pattern 105). }

procedure com_$begin_compilation;
begin
  mrh_$initialize(com_heap, 1, 8, 'COM hash table heap%');
end;

{ com_$end_compilation - com_heap released.  0x22C064, 0x1C bytes. }

procedure com_$end_compilation;
begin
  mrh_$release_all(com_heap);
end;

{ com_$end_routine - nothing.  0x22C080, 2 bytes. }

procedure com_$end_routine(
    rtn: rtn_ptr_t);
begin
end;
