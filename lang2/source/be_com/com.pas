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
    --------  0x226E62  build_loads (internal)
    --------  0x22723E  build_stores (internal)
    --------  0x2274D0  replace_mem_instrs (internal)
    --------  0x227A0A  ip_mem_reference (internal)
    --------  0x227A8C  analyze_candidates (internal)
    --------  0x227C1A  add_lr_to_list (internal)
    --------  0x227C6A  add_lr_to_list_uniquely (internal)
    --------  0x227CB8  add_lrs_to_ssa_list (internal)
    --------  0x227D9C  is_invariant (internal)
    --------  0x227E04  loop_invariant_addr (internal)
    --------  0x227EDE  consider_mem_dependents (internal)
    --------  0x2282B8  partition_memory (internal)
    --------  0x2283A8  is_join_bp
    --------  0x2283DC  worth_hoisting (internal)
    --------  0x22841A  find_loop_memory_hoist_candidates (internal)
    --------  0x22876C  lr_unconsumed_in_loop (internal)
    --------  0x228836  lr_value_same_on_loop_exit (internal)
    --------  0x228968  suck_instrs_from_loop (internal)
    --------  0x228D58  collect_exit_blocks (internal)
    --------  0x228DF2  collect_loop_contents (internal)
    --------  0x228F50  entry_blocks_safe (internal)
    --------  0x228F8A  exit_blocks_safe (internal)
    --------  0x229074  loop_memory_analysis (internal)
    --------  0x22915E  cvt_short_load_to_32_bits (internal)
    --------  0x22930C  eliminate_load (internal)
    --------  0x22960E  attempt_load_elimination (internal)
    --------  0x2297D2  excise_a_store (internal)
    --------  0x2298D2  simple_mmt_seq_input (internal)
    --------  0x229968  get_the_right_instr (nested in ltss_on_stores_to_same_addr)
    --------  0x2299CA  ltss_on_stores_to_same_addr
    --------  0x229A9E  store_is_redundant
    --------  0x229B3A  get_mem_birthpoint
    --------  0x229BB2  safe_to_ignore_do_not_delete (internal)
    --------  0x229C96  convert_store_to_seq (internal)
    --------  0x229D86  attempt_store_elimination (internal)
    --------  0x22A03C  attempt_do_not_delete_removal (internal)
    --------  0x22A0B2  move_is_zero (internal)
    --------  0x22A19A  replace_zero_valued_lrs (internal)
    --------  0x22A224  calc_last_legal_dom_bb (internal)
    --------  0x22A276  def_dominates_use (internal)
    --------  0x22A2B8  bb_postdominates (internal)
    --------  0x22A2F6  maybe_hoist_instr_from_loop (internal)
    --------  0x22A6B4  connect_physical (internal)
    --------  0x22A760  call_cossin (internal)
    --------  0x22AEFC  safe_cc_write (internal)
    --------  0x22AFB0  operand_is_trapcc_input (internal)
    --------  0x22AFF0  destroy_instr (internal)
    --------  0x22B46C  process_instruction (internal)
    --------  0x22BEAA  optimize_block (internal)
    --------  0x22BFD2  com_$compute_cses
    --------  0x22C02A  com_$begin_compilation
    --------  0x22C064  com_$end_compilation
    --------  0x22C080  com_$end_routine
    --------  0x22C082  com_$process_routine
    A5 0x485E60: the module's data: com_heap (+0), com_name (+24, a
    varying string: the routine's fully qualified name), +284 (set to
    100), com_rtn (+288), com_level (+296), com_hoisted (+304),
    com_306 (+306), com_saw_do_not_delete (+308), com_mem_lr (+312),
    com_mem_lrs (+316).

  Fields of batch A's records read through views of this unit
  (offsets for batch A to name): a block's +42 (com_bb_v_t.l42, as
  trans's) and +142 (next142, com's block lists); the routine's IL
  node's +192 (the section of its address constants) and an address
  constant node's +16 (com_node_v_t); a call instruction's longword at
  +48 + 12 nopnds (the slot after its operands, its +4: result flags
  call_cossin clears); an instruction's alias descriptor at -24 when
  +2 bit 7 is set (as mmt's).  rtn_t's lr108 is the DB register's live
  range (call_cossin's message), lir_main_c4c the zero register's
  segment (move_is_zero), lir_3f94 .. lir_3f9c floating registers 1
  to 3's live ranges (lir_3f90's table).

  Not known from the original: every local, parameter and cell name. }

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

type
  { com's view of a block (fields batch A has not named; backend.ins.pas
    bb_t): l42 (+42) a longword the memory hoisting requires equal in
    a loop's entry blocks (trans's l42), next142 (+142) the chain of
    the block lists com builds (a loop's contents, entry and exit
    blocks). }
  com_bb_v_ptr_t = ^com_bb_v_t;
  com_bb_v_t = record
    space0: array [0..41] of char;
    l42: integer32;                     { +42 }
    space46: array [46..141] of char;
    next142: bb_ptr_t;                  { +142 }
  end;

  { The routine's IL node as call_cossin reads it: sect (+192) the
    section its address constants go in; an address constant's value
    (+16). }
  com_node_v_ptr_t = ^com_node_v_t;
  com_node_v_t = record
    space0: array [0..15] of char;
    l16: integer32;                     { +16 }
    space20: array [20..191] of char;
    sect: univ_ptr;                     { +192 }
  end;

  com_int_ptr_t = ^integer32;

  { A list of live ranges (512 bytes from com_heap): chunks of 126,
    the newest first. }
  com_lrs_ptr_t = ^com_lrs_t;
  com_lrs_t = record
    next: com_lrs_ptr_t;                { +0 }
    count: integer32;                   { +4 }
    lrs: array [1..126] of lr_ptr_t;    { +8 }
  end;

  { A join birthpoint's input (utils' ut_jbi_t): chained from the input
    segment's l44 (+0) and from the join's operand 3 (+4). }
  com_jbi_ptr_t = ^com_jbi_t;
  com_jbi_t = record
    next: com_jbi_ptr_t;                { +0 }
    next_op: com_jbi_ptr_t;             { +4 }
    lts: lts_ptr_t;                     { +8 }
    instr: instr_ptr_t;                 { +12: the join birthpoint }
  end;

  { An instruction in the hash table (8 bytes from com_heap). }
  com_entry_ptr_t = ^com_entry_t;
  com_entry_t = record
    next: com_entry_ptr_t;              { +0 }
    instr: instr_ptr_t;                 { +4 }
  end;

  { A block's hash table (optimize_block's frame, 264 bytes): the
    instructions available in the block by opcode mod 64; parent the
    table of its immediate dominator. }
  com_tab_ptr_t = ^com_tab_t;
  com_tab_t = record
    parent: com_tab_ptr_t;              { +0 }
    bb: bb_ptr_t;                       { +4 }
    buckets: array [0..63] of com_entry_ptr_t;   { +8 }
  end;

var
  com_heap: mrh_$heap_t;                { +0: the hash table's heap }
  com_20: integer32;                    { +20 }
  com_name: varying [256] of char;      { +24: the routine's name }
  com_284: integer32;                   { +284 (set to 100) }
  com_rtn: rtn_ptr_t;                   { +288 }
  com_292: integer32;                   { +292 }
  com_level: integer32;                 { +296: the switches' level }
  com_300: integer32;                   { +300 }
  com_hoisted: boolean;                 { +304: an instruction was
                                          hoisted out of a loop (another
                                          pass follows) }
  com_306: boolean;                     { +306: set by
                                          store_is_redundant }
  com_saw_do_not_delete: boolean;       { +308: a do_not_delete
                                          instruction was met }
  com_mem_lr: lr_ptr_t;                 { +312: the memory live range
                                          the hoisted loads' MMT_SEQs
                                          write }
  com_mem_lrs: lr_ptr_t;                { +316: the first of the memory
                                          live ranges the sunk stores'
                                          MMT_SEQs read }

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

{ build_loads - for a class of loads and stores of one loop invariant
  address (instrs, chained at their l24): a new complex live range of
  their register's kind (its node the whole variable's, from an alias
  descriptor that has one) that the loop will keep the value in, and
  at the end of each entry block a copy of the first load writing it
  (its memory operands made to read com_mem_lr, its condition codes
  dropped).  first: also put before each entry block's closing
  branches the MMT_SEQs that write com_mem_lr (a new memory live range,
  unless lrs holds a single one, which is used, or none) and read and
  modify the memory live ranges in lrs (at most 255 operands each).
  0x226E62, 0x3DC bytes, no A5: the alias descriptor at the
  instruction's -24 (+19 bit 2, +4, +0); the MMT_SEQ's opcode and
  `after' pushed as one longword (#0x00CA0000, pattern 105); the
  operands' kinds stored by `andi.b #-32; or.b'; the chunk index not
  reset for the next chunk (kept); A0. }

function build_loads(
    instrs: instr_ptr_t;
    entries: bb_ptr_t;
    lrs: com_lrs_ptr_t;
    first: boolean): lr_ptr_t; options(val_param); internal;
label
  1;
var
  kind: operand$t;
  nlr, res: lr_ptr_t;
  i, ld, j, s, c: instr_ptr_t;
  d: alias_$desc_ptr_t;
  mate_num, total, k, n, nk, idx, m: integer32;
  b: bb_ptr_t;
  p: com_lrs_ptr_t;
begin
  if first then
    if lrs = nil then begin
      com_mem_lr := nil;
      first := false;
    end
    else if (lrs^.next = nil) and (lrs^.count = 1) then begin
      com_mem_lr := lrs^.lrs[1];
      first := false;
    end
    else
      com_mem_lr := lir_$new_live_range;
  if instruction_attributes[instrs^.opc].class = class$load then
    kind := instrs^.opnds[3].h.kind
  else
    kind := instrs^.opnds[1].h.kind;
  nlr := lir_$new_live_range_for_kind(ord(no_reg_like_kinds(kind)));
  bv_$make_live_range_complex(com_rtn, nlr);
  res := nlr;
  i := instrs;
  while i <> nil do begin
    if i^.h.b2_7 then begin
      d := alias_$desc_ptr_t(integer32(i) - 24);
      if d^.whole then
        if d^.sym <> nil then
          nlr^.node20 := d^.sym
        else
          nlr^.node20 := d^.base;
    end;
    i := instr_ptr_t(i^.l24);
  end;
  ld := nil;
  i := instrs;
  while i <> nil do begin
    if instruction_attributes[i^.opc].class = class$load then begin
      ld := i;
      exit;
    end;
    i := instr_ptr_t(i^.l24);
  end;
  if (nlr^.mate = nil) or (ld = nil) then
    mate_num := 0
  else
    mate_num := utils_$find_mate_operand(addr(ld^.opnds[3]))^.h.num;
  b := entries;
  while b <> nil do begin
    if first then begin
      j := b^.last;
      while j^.prev <> nil do begin
        if not (instruction_attributes[j^.prev^.opc].class in
                [class$branch, class$fp_branch, class$jump,
                 class$return]) then
          exit;
        j := j^.prev;
      end;
      total := 0;
      p := lrs;
      while p <> nil do begin
        total := total + p^.count;
        p := p^.next;
      end;
      k := 1;
      p := lrs;
      idx := 1;
      while total > 0 do begin
        n := k + total;
        if n > 255 then
          n := 255;
        s := lir_$optimizer_new_n_opr_instr(j, ord(opc$mmt_seq), false, n);
        total := total - n + k;
        if k = 1 then begin
          opnd_bytes_ptr_t(addr(s^.opnds[1]))^.rrp := 8;
          s^.opnds[1].h.kind := operand$inscrutable_memory;
          s^.opnds[1].h.num := 1;
          s^.opnds[1].lts := lts_ptr_t(com_mem_lr);
          m := 2;
        end
        else begin
          opnd_bytes_ptr_t(addr(s^.opnds[1]))^.rrp := 16#30;
          s^.opnds[1].h.kind := operand$inscrutable_memory;
          s^.opnds[1].h.num := 1;
          s^.opnds[1].lts := lts_ptr_t(com_mem_lr);
          opnd_bytes_ptr_t(addr(s^.opnds[2]))^.rrp := 4;
          s^.opnds[2].h.kind := operand$inscrutable_memory;
          s^.opnds[2].h.num := 2;
          s^.opnds[2].lts := lts_ptr_t(com_mem_lr);
          m := 3;
        end;
        while p <> nil do begin
          for nk := idx to p^.count do begin
            opnd_bytes_ptr_t(addr(s^.opnds[m]))^.rrp := 16;
            s^.opnds[m].h.kind := operand$inscrutable_memory;
            s^.opnds[m].h.num := m;
            s^.opnds[m].lts := lts_ptr_t(p^.lrs[nk]);
            m := m + 1;
            if m = 256 then begin
              idx := nk + 1;
              goto 1;
            end;
          end;
          p := p^.next;
        end;
    1:  utils_$complete_copied_instr(s);
        k := 2;
      end;
    end;
    if ld <> nil then begin
      c := utils_$copy_instr_template_to_bb_end(ld, b);
      c^.opnds[3].lts := lts_ptr_t(nlr);
      if nlr^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only] = [] then
        opnd_bytes_ptr_t(addr(c^.opnds[3]))^.rrp :=
            opnd_bytes_ptr_t(addr(c^.opnds[3]))^.rrp & 16#FC;
      if mate_num <> 0 then
        c^.opnds[mate_num].lts := lts_ptr_t(nlr^.mate);
      for k := 1 to c^.h.nopnds do
        if c^.opnds[k].h.kind in [operand$argument_block_memory..
                                  operand$well_behaved_memory] then begin
          if com_mem_lr <> nil then begin
            c^.opnds[k].lts := lts_ptr_t(com_mem_lr);
            if first then
              c^.opnds[k].h.kind := operand$inscrutable_memory;
          end
          else
            c^.opnds[k].h.kind := operand$none;
        end
        else if c^.opnds[k].h.kind in [operand$ip_condition_codes,
                                       operand$fp_condition_codes] then begin
          c^.opnds[k].h.kind := operand$none;
          c^.opnds[k].lts := nil;
          c^.h.sets_cc := false;
          c^.h.b0_3 := false;
        end;
      utils_$complete_copied_instr(c);
    end;
    b := com_bb_v_ptr_t(b)^.next142;
  end;
  build_loads := res;
end;

{ build_stores - for the same class: at the head of each exit block a
  copy of the first store, storing the loop's live range nlr (its
  register kinds made plain, its memory operands made to read
  com_mem_lrs); first: also MMT_SEQs after the block's labels and join
  birthpoints that read com_mem_lrs (lrs's first, taken off it) and
  read and modify the rest of lrs (chained at their l52), each pair's
  first operand reading the previous live range.  0x22723E, 0x292
  bytes, no A5: the MMT_SEQ's opcode and `after' as one longword; the
  mate's kind made from operand 1's kind (+47), as the image does. }

procedure build_stores(
    instrs: instr_ptr_t;
    nlr: lr_ptr_t;
    lrs: lr_ptr_t;
    exits: bb_ptr_t;
    first: boolean); options(val_param); internal;
var
  i, st, j, s, c: instr_ptr_t;
  mate_num, n, cnt, k: integer32;
  b: bb_ptr_t;
  prev, lr: lr_ptr_t;
begin
  if first then begin
    com_mem_lrs := lrs;
    if lrs <> nil then
      lrs := lrs^.l52;
    first := lrs <> nil;
  end;
  st := nil;
  i := instrs;
  while i <> nil do begin
    if instruction_attributes[i^.opc].class = class$store then begin
      st := i;
      exit;
    end;
    i := instr_ptr_t(i^.l24);
  end;
  if (nlr^.mate = nil) or (st = nil) then
    mate_num := 0
  else
    mate_num := utils_$find_mate_operand(addr(st^.opnds[1]))^.h.num;
  b := exits;
  while b <> nil do begin
    if first then begin
      j := b^.first;
      while (j^.opc = ord(opc$join_bp)) or (j^.opc = ord(opc$label)) do
        j := j^.next;
      n := 0;
      lr := lrs;
      while lr <> nil do begin
        n := n + 2;
        lr := lr^.l52;
      end;
      prev := com_mem_lrs;
      lr := lrs;
      while n > 0 do begin
        cnt := n + 1;
        if cnt > 255 then
          cnt := 255;
        s := lir_$optimizer_new_n_opr_instr(j, ord(opc$mmt_seq), false, cnt);
        n := n - cnt + 1;
        opnd_bytes_ptr_t(addr(s^.opnds[1]))^.rrp := 16;
        s^.opnds[1].h.num := 1;
        s^.opnds[1].h.kind := operand$inscrutable_memory;
        s^.opnds[1].lts := lts_ptr_t(prev);
        k := 2;
        while (lr <> nil) and (k < 256) do begin
          opnd_bytes_ptr_t(addr(s^.opnds[k]))^.rrp := 16#30;
          s^.opnds[k].h.kind := operand$inscrutable_memory;
          s^.opnds[k].h.num := k;
          s^.opnds[k].lts := lts_ptr_t(lr);
          opnd_bytes_ptr_t(addr(s^.opnds[k + 1]))^.rrp := 4;
          s^.opnds[k + 1].h.kind := operand$inscrutable_memory;
          s^.opnds[k + 1].h.num := k + 1;
          s^.opnds[k + 1].lts := lts_ptr_t(lr);
          prev := lr;
          k := k + 2;
          lr := lr^.l52;
        end;
        utils_$complete_copied_instr_at_bb_head(s);
      end;
    end;
    if st <> nil then begin
      c := utils_$copy_instr_template_to_bb_head(st, b);
      c^.opnds[1].lts := lts_ptr_t(nlr);
      c^.opnds[1].h.kind := no_reg_like_kinds(c^.opnds[1].h.kind);
      if nlr^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only] = [] then
        opnd_bytes_ptr_t(addr(c^.opnds[1]))^.rrp :=
            opnd_bytes_ptr_t(addr(c^.opnds[1]))^.rrp & 16#FC;
      if mate_num <> 0 then begin
        c^.opnds[mate_num].lts := lts_ptr_t(nlr^.mate);
        c^.opnds[mate_num].h.kind := no_reg_like_kinds(c^.opnds[1].h.kind);
      end;
      for k := 1 to c^.h.nopnds do
        if c^.opnds[k].h.kind in [operand$argument_block_memory..
                                  operand$well_behaved_memory] then
          if com_mem_lrs <> nil then begin
            c^.opnds[k].lts := lts_ptr_t(com_mem_lrs);
            if first then
              c^.opnds[k].h.kind := operand$inscrutable_memory;
          end
          else
            c^.opnds[k].h.kind := operand$none;
      utils_$complete_copied_instr_at_bb_head(c);
    end;
    b := com_bb_v_ptr_t(b)^.next142;
  end;
end;

{ replace_mem_instrs - the class's loads and stores in the loop made
  preference moves from and to nlr (each new move marked and chained
  on repl at its l24): a load's result (and its mate's) now copied from
  nlr, its condition codes (its last operand) moved to the move; a
  store's value copied into nlr; the memory segment an instruction
  wrote (its last memory operand that writes, when the operand before
  it reads the same live range) excised, its readers given the read
  segment; the instruction excised.  Then in each block of contents
  the marked moves' operands of nlr (and its mate) given the block's
  own segments: readers its exposed segment (until a write), writers
  a new segment; the block's last ones put on the final list.
  0x2274D0, 0x53A bytes, no A5: the preference move's third argument
  pushed by `st' (true); the operand copied as three longwords. }

procedure replace_mem_instrs(
    instrs: instr_ptr_t;
    nlr: lr_ptr_t;
    contents: bb_ptr_t;
    var repl: instr_ptr_t); options(val_param); internal;
var
  m, k: integer32;
  i, nx, mv: instr_ptr_t;
  m2, o, p, q, last1, last2: opnd_ptr_t;
  from, e1, e2: lts_ptr_t;
  b: bb_ptr_t;
  created: boolean;
begin
  com_rtn^.marks := com_rtn^.marks + 1;
  m := com_rtn^.marks;
  i := instrs;
  while i <> nil do begin
    nx := instr_ptr_t(i^.l24);
    if i^.h.b2_6 then begin
      if instruction_attributes[i^.opc].class = class$load then begin
        mv := lir_utils_$create_preference_move(i^.opnds[3].h.kind,
                                                i, true);
        mv^.l24 := integer32(repl);
        repl := mv;
        mv^.opnds[1].lts := lts_ptr_t(nlr);
        mv^.opnds[2].link := i^.opnds[3].link;
        mv^.opnds[2].lts := i^.opnds[3].lts;
        mv^.opnds[2].lts^.refs := addr(mv^.opnds[2]);
        if nlr^.mate <> nil then begin
          mv^.opnds[3].lts := lts_ptr_t(nlr^.mate);
          m2 := utils_$find_mate_operand(addr(i^.opnds[3]));
          mv^.opnds[4].link := m2^.link;
          mv^.opnds[4].lts := m2^.lts;
          mv^.opnds[4].lts^.refs := addr(mv^.opnds[4]);
        end;
        if i^.opnds[i^.h.nopnds].h.kind in [operand$ip_condition_codes,
                                            operand$fp_condition_codes] then begin
          mv^.opnds[mv^.h.nopnds] := i^.opnds[i^.h.nopnds];
          mv^.opnds[mv^.h.nopnds].h.num := mv^.h.nopnds;
          mv^.opnds[mv^.h.nopnds].lts^.refs := addr(mv^.opnds[mv^.h.nopnds]);
          mv^.h.b0_6 := false;
          mv^.h.sets_cc := i^.h.sets_cc;
          mv^.h.b0_3 := i^.h.b0_3;
        end;
      end
      else begin
        mv := lir_utils_$create_preference_move(
            no_reg_like_kinds(i^.opnds[1].h.kind), i, true);
        mv^.l24 := integer32(repl);
        repl := mv;
        mv^.opnds[2].lts := lts_ptr_t(nlr);
        mv^.opnds[1].h.kind := i^.opnds[1].h.kind;
        mv^.opnds[1].link := i^.opnds[1].link;
        mv^.opnds[1].lts := i^.opnds[1].lts;
        i^.opnds[1].link := addr(mv^.opnds[1]);
        if mv^.opnds[1].h.kind in [operand$ip_reg_like, operand$fp_reg_like,
                                   operand$fp_reg_pair_like,
                                   operand$case_jump_base] then
          mv^.h.b0_6 := false;
        if nlr^.mate <> nil then begin
          mv^.opnds[4].lts := lts_ptr_t(nlr^.mate);
          m2 := utils_$find_mate_operand(addr(i^.opnds[1]));
          mv^.opnds[3].h.kind := m2^.h.kind;
          mv^.opnds[3].link := m2^.link;
          mv^.opnds[3].lts := m2^.lts;
          m2^.link := addr(mv^.opnds[3]);
        end;
      end;
      mv^.l16 := m;
      for k := i^.h.nopnds downto 1 do begin
        o := addr(i^.opnds[k]);
        if (o^.h.kind in [operand$argument_block_memory..
                          operand$well_behaved_memory])
            and ((opnd_bytes_ptr_t(o)^.rrp & 12) <> 0) then begin
          p := addr(i^.opnds[k - 1]);
          if p^.h.kind in [operand$argument_block_memory..
                           operand$well_behaved_memory] then
            if p^.h.read then
              if o^.lts^.lr = p^.lts^.lr then begin
                q := o^.link;
                while q <> nil do begin
                  q^.lts := p^.lts;
                  q := q^.link;
                end;
                p^.link := o^.link;
                o^.link := nil;
                if p^.lts^.rrp * [rrp$modify, rrp$write] = [] then
                  from := p^.lts^.l44
                else
                  from := p^.lts;
                utils_$move_definition(o^.lts, from, false);
                if o^.lts^.f2.final then begin
                  utils_$remove_lts_from_final_list(o^.lts);
                  utils_$put_lts_on_final_list(p^.lts);
                end;
                utils_$excise_lts_cleanly(o^.lts, true);
              end;
          exit;
        end;
      end;
      utils_$excise_instruction_cleanly(i, true);
    end;
    i := nx;
  end;
  b := contents;
  while b <> nil do begin
    e1 := nil;
    e2 := nil;
    last1 := nil;
    last2 := nil;
    i := b^.first;
    while i <> nil do begin
      if i^.l16 = m then
        for k := 1 to i^.h.nopnds do begin
          o := addr(i^.opnds[k]);
          if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
            if (o^.lts = lts_ptr_t(nlr))
                or ((nlr^.mate <> nil)
                    and (o^.lts = lts_ptr_t(nlr^.mate))) then
              if o^.h.read then begin
                if o^.lts = lts_ptr_t(nlr) then begin
                  if e1 = nil then begin
                    e1 := utils_$get_exposed_lts(nlr, b, created);
                    last1 := nil;
                  end;
                  o^.lts := e1;
                  if last1 = nil then
                    e1^.refs := o
                  else
                    last1^.link := o;
                  last1 := o;
                end
                else begin
                  if e2 = nil then begin
                    e2 := utils_$get_exposed_lts(nlr^.mate, b, created);
                    last2 := nil;
                  end;
                  o^.lts := e2;
                  if last2 = nil then
                    e2^.refs := o
                  else
                    last2^.link := o;
                  last2 := o;
                end;
                o^.lts^.rrp := o^.lts^.rrp + [rrp$read];
              end
              else begin
                if o^.lts = lts_ptr_t(nlr) then begin
                  e1 := utils_$get_new_lts(nlr, b, false);
                  o^.lts := e1;
                  e1^.refs := o;
                  last1 := o;
                end
                else begin
                  e2 := utils_$get_new_lts(nlr^.mate, b, false);
                  o^.lts := e2;
                  e2^.refs := o;
                  last2 := o;
                end;
                o^.lts^.rrp := o^.lts^.rrp + [rrp$write];
              end;
        end;
      i := i^.next;
    end;
    if e1 <> nil then
      utils_$put_lts_on_final_list(e1);
    if e2 <> nil then
      utils_$put_lts_on_final_list(e2);
    b := com_bb_v_ptr_t(b)^.next142;
  end;
end;

{ ip_mem_reference - a load's result (operand 3) or a store's value
  (operand 1) is an integer register.  0x227A0A, 0x58 bytes, no A5:
  the kinds `btst' in 16#21012. }

function ip_mem_reference(
    i: instr_ptr_t): boolean; options(val_param); internal;
var
  o: opnd_ptr_t;
begin
  if instruction_attributes[i^.opc].class = class$load then
    o := addr(i^.opnds[3])
  else if instruction_attributes[i^.opc].class = class$store then
    o := addr(i^.opnds[1])
  else
    bug_check('COM_$ip_mem_reference: not mem reference%$');
  ip_mem_reference := o^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                                    operand$ip_reg_like,
                                    operand$case_jump_base];
end;

{ analyze_candidates - c (the first of cands, the loop invariant loads
  and stores, chained at their l24), when its address is disjoint from
  every variant reference's: the class of references found the same as
  c's (head; their values all integer or all not) taken off cands,
  the disjoint ones kept there; a reference that may overlap (or of
  the other kind) gives no class, cands left in the order taken apart.
  The next candidate to try is returned.  0x227A8C, 0x162 bytes, no
  A5: mmt_utils_$addr_compare's report false a word; A0. }

function analyze_candidates(
    c: instr_ptr_t;
    var cands: instr_ptr_t;
    variant: instr_ptr_t;
    var head: instr_ptr_t): instr_ptr_t; options(val_param); internal;
label
  1, 9;
var
  nxt, p, q, qn, eqh, eqt, resth, restt: instr_ptr_t;
  disp: integer32;
  r: integer;
  ip: boolean;
begin
  nxt := instr_ptr_t(c^.l24);
  head := nil;
  if c^.h.b2_6 then begin
    p := variant;
    while p <> nil do begin
      if mmt_utils_$addr_compare(c, p, false, disp) <> 3 then
        goto 9;
      p := instr_ptr_t(p^.l24);
    end;
    eqh := nil;
    eqt := nil;
    resth := nil;
    restt := nil;
    nxt := instr_ptr_t(c^.l24);
    q := cands;
    while q <> nil do begin
      qn := instr_ptr_t(q^.l24);
      if q^.h.b2_6 then begin
        r := mmt_utils_$addr_compare(c, q, false, disp);
        if r = 1 then begin
          if eqt = nil then begin
            eqh := q;
            ip := ip_mem_reference(q);
          end
          else begin
            if ip_mem_reference(q) <> ip then
              goto 1;
            eqt^.l24 := integer32(q);
          end;
          q^.l24 := 0;
          eqt := q;
          if q = nxt then
            nxt := qn;
        end
        else if r = 3 then begin
          if restt = nil then
            resth := q
          else
            restt^.l24 := integer32(q);
          q^.l24 := 0;
          restt := q;
        end
        else begin
      1:  cands := eqh;
          if eqt = nil then
            cands := resth
          else
            eqt^.l24 := integer32(resth);
          if restt = nil then
            if eqt = nil then
              cands := q
            else
              eqt^.l24 := integer32(q)
          else
            restt^.l24 := integer32(q);
          goto 9;
        end;
      end;
      q := qn;
    end;
    cands := resth;
    if eqh = nil then
      bug_check('COM_$analyze_candidates: equiv_head is NIL%$');
    head := eqh;
  end;
9:
  analyze_candidates := nxt;
end;

{ add_lr_to_list - lr appended to list (a new chunk first when the
  list is empty or its first chunk full).  0x227C1A, 0x50 bytes, no
  A5: the chunk's count read as its low word for the index. }

procedure add_lr_to_list(
    lr: lr_ptr_t;
    var list: com_lrs_ptr_t); options(val_param); internal;
var
  n: com_lrs_ptr_t;
begin
  if (list = nil) or (list^.count = 126) then begin
    n := mrh_$alloc(com_heap, 512);
    n^.next := list;
    list := n;
  end;
  list^.count := list^.count + 1;
  list^.lrs[list^.count] := lr;
end;

{ add_lr_to_list_uniquely - lr appended to list unless it is there.
  0x227C6A, 0x4E bytes, no A5. }

procedure add_lr_to_list_uniquely(
    lr: lr_ptr_t;
    var list: com_lrs_ptr_t); options(val_param); internal;
var
  p: com_lrs_ptr_t;
  k: integer32;
begin
  p := list;
  while p <> nil do begin
    for k := 1 to p^.count do
      if p^.lrs[k] = lr then
        return;
    p := p^.next;
  end;
  add_lr_to_list(lr, list);
end;

{ add_lrs_to_ssa_list - the live ranges of lrs and of the chain marked
  (at their l52) added to ssa unless there (marked by +3 bit 2 while
  this runs).  0x227CB8, 0xE4 bytes, no A5. }

procedure add_lrs_to_ssa_list(
    lrs: com_lrs_ptr_t;
    marked: lr_ptr_t;
    var ssa: com_lrs_ptr_t); options(val_param); internal;
var
  p: com_lrs_ptr_t;
  k: integer32;
  lr: lr_ptr_t;
begin
  p := ssa;
  while p <> nil do begin
    for k := 1 to p^.count do
      p^.lrs[k]^.f2.b3_2 := true;
    p := p^.next;
  end;
  p := lrs;
  while p <> nil do begin
    for k := 1 to p^.count do begin
      lr := p^.lrs[k];
      if not lr^.f2.b3_2 then begin
        lr^.f2.b3_2 := true;
        add_lr_to_list(lr, ssa);
      end;
    end;
    p := p^.next;
  end;
  lr := marked;
  while lr <> nil do begin
    if not lr^.f2.b3_2 then
      add_lr_to_list(lr, ssa);
    lr := lr^.l52;
  end;
  p := ssa;
  while p <> nil do begin
    for k := 1 to p^.count do
      p^.lrs[k]^.f2.b3_2 := false;
    p := p^.next;
  end;
end;

{ is_invariant - o's value does not change in the loop (blocks marked
  mark): not a register or memory operand, a like register, or an
  exposed segment that no final segment of the loop reaches.
  0x227D9C, 0x68 bytes, no A5: o by address. }

function is_invariant(
    in o: opnd_t;
    mark: integer32): boolean; options(val_param); internal;
var
  l, f: lts_ptr_t;
begin
  if o.h.kind = operand$ip_reg_like then
    is_invariant := true
  else if not (o.h.kind in [operand$ip_reg..operand$well_behaved_memory]) then
    is_invariant := true
  else begin
    l := o.lts;
    if not l^.f2.exposed then
      is_invariant := false
    else begin
      f := l^.l44;
      if f = nil then
        is_invariant := true
      else if f^.bb^.mark146 = mark then
        is_invariant := false
      else
        is_invariant := true;
    end;
  end;
end;

{ loop_invariant_addr - i (a load or store) reads an address that does
  not change in the loop: not volatile or do_not_delete, both address
  operands invariant, and (for one with +2 bit 5) in a block of +20 bit
  2 with the entries' l42.  0x227E04, 0xA8 bytes, no A5: both operands
  tested, the results ANDed. }

function loop_invariant_addr(
    i: instr_ptr_t;
    mark: integer32;
    l42: integer32): boolean; options(val_param); internal;
var
  a, b: opnd_ptr_t;
  r: boolean;
begin
  loop_invariant_addr := false;
  if i^.h.b2_5 then begin
    if not i^.bb^.f20.b20_2 then
      return;
    if com_bb_v_ptr_t(i^.bb)^.l42 <> l42 then
      return;
  end;
  if i^.h.b2_4 then
    return;
  if i^.h.b2_3 then
    return;
  if instruction_attributes[i^.opc].class = class$load then begin
    a := addr(i^.opnds[1]);
    b := addr(i^.opnds[2]);
  end
  else if instruction_attributes[i^.opc].class = class$store then begin
    a := addr(i^.opnds[2]);
    b := addr(i^.opnds[3]);
  end
  else
    bug_check('COM_$loop_invariant_addr: expected LOAD or STORE%$');
  r := is_invariant(a^, mark);
  loop_invariant_addr := is_invariant(b^, mark) and r;
end;

{ consider_mem_dependents - the memory segment l and what depends on it
  in the loop (blocks marked mark) walked (segments marked m3): its
  loads and stores sorted into invar (address invariant) and variant
  (chained at their l24; instructions marked m3, or m2 when one fails),
  JOIN_BPs and MMT_SEQs passed over, any other reader of memory that is
  the loop's own fails it; the segments the readers write followed;
  for a simple memory live range the live ranges joined into it from
  outside the loop added to lrs, and those it leaves the loop by put
  on marked (chained at l52, +3 bit 2).  False when the memory cannot
  be kept in registers.  0x227EDE, 0x3DA bytes, no A5: recursive. }

function consider_mem_dependents(
    l: lts_ptr_t;
    mark: integer32;
    l42: integer32;
    m3: integer32;
    m2: integer32;
    var invar: instr_ptr_t;
    var variant: instr_ptr_t;
    var lrs: com_lrs_ptr_t;
    var marked: lr_ptr_t): boolean; options(val_param); internal;
label
  9;
var
  ok, simple: boolean;
  lr: lr_ptr_t;
  j, s, x: lts_ptr_t;
  ji, i: instr_ptr_t;
  inp: com_jbi_ptr_t;
  o, p: opnd_ptr_t;
  k: integer32;
begin
  ok := true;
  lr := l^.lr;
  simple := (lr^.rrp * [rrp$fp_reg, rrp$ip_reg] = []) and not lr^.f2.physical;
  if l^.mark = m3 then
    goto 9;
  if simple then begin
    if l^.refs = nil then
      j := nil
    else if l^.f2.exposed then
      j := l
    else begin
      ji := utils_ins_$operands_instruction(l^.refs);
      if ji^.opc = ord(opc$join_bp) then
        j := ji^.opnds[1].lts
      else
        j := nil;
    end;
    if j <> nil then
      if j^.refs <> nil then begin
        ji := utils_ins_$operands_instruction(j^.refs);
        if ji^.opc = ord(opc$join_bp) then begin
          inp := com_jbi_ptr_t(ji^.opnds[3].link);
          while inp <> nil do begin
            s := inp^.lts;
            if s^.mark <> m3 then
              if s^.bb^.mark146 <> mark then begin
                add_lr_to_list_uniquely(s^.lr, lrs);
                s^.mark := m3;
              end;
            inp := inp^.next_op;
          end;
        end
        else if j^.l44 <> nil then begin
          s := j^.l44;
          if s^.mark <> m3 then
            if s^.bb^.mark146 <> mark then begin
              add_lr_to_list_uniquely(s^.lr, lrs);
              s^.mark := m3;
            end;
        end;
      end;
  end;
  l^.lr^.l40 := mark;
  l^.mark := m3;
  o := l^.refs;
  if o = nil then
    goto 9;
  if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then
    o := o^.link;
  while o <> nil do begin
    i := utils_ins_$operands_instruction(o);
    if i^.l16 = m2 then begin
      ok := false;
      goto 9;
    end;
    if i^.l16 <> m3 then begin
      if instruction_attributes[i^.opc].class in [class$load, class$store] then begin
        i^.l16 := m3;
        if loop_invariant_addr(i, mark, l42) then begin
          i^.l24 := integer32(invar);
          invar := i;
        end
        else begin
          i^.l24 := integer32(variant);
          variant := i;
        end;
      end
      else if (i^.opc = ord(opc$join_bp)) or (i^.opc = ord(opc$mmt_seq)) then
        i^.l16 := m3
      else if simple then
        if not l^.f2.exposed then begin
          ok := false;
          goto 9;
        end
        else if l^.l44 <> nil then
          if lts_ptr_t(l^.l44)^.bb^.mark146 = mark then begin
            ok := false;
            goto 9;
          end;
      for k := 1 to i^.h.nopnds do begin
        p := addr(i^.opnds[k]);
        if (p^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
            and ((opnd_bytes_ptr_t(p)^.rrp & 12) <> 0) then begin
          if not consider_mem_dependents(p^.lts, mark, l42, m3, m2, invar,
                                         variant, lrs, marked) then begin
            ok := false;
            i^.l16 := m2;
            goto 9;
          end;
        end
        else if p^.h.kind in [operand$argument_block_memory..
                              operand$well_behaved_memory] then begin
          s := p^.lts;
          if s^.f2.exposed then
            if s^.l44 <> nil then
              if lts_ptr_t(s^.l44)^.bb^.mark146 = mark then
                s := s^.l44;
          if not consider_mem_dependents(s, mark, l42, m3, m2, invar,
                                         variant, lrs, marked) then begin
            ok := false;
            i^.l16 := m2;
            goto 9;
          end;
        end;
      end;
    end;
    o := o^.link;
  end;
  if l^.rrp * [rrp$modify, rrp$write] <> [] then
    if l^.f2.final then begin
      x := l^.l28;
      while x <> nil do begin
        if x^.bb^.mark146 = mark then begin
          if not consider_mem_dependents(x, mark, l42, m3, m2, invar,
                                         variant, lrs, marked) then begin
            ok := false;
            goto 9;
          end;
        end
        else if simple then
          if not l^.lr^.f2.b3_2 then begin
            l^.lr^.l52 := marked;
            marked := l^.lr;
            l^.lr^.f2.b3_2 := true;
          end;
        x := x^.l28;
      end;
      inp := com_jbi_ptr_t(l^.l44);
      while inp <> nil do begin
        ji := inp^.instr;
        if ji^.bb^.mark146 = mark then begin
          if not consider_mem_dependents(ji^.opnds[2].lts, mark, l42, m3,
                                         m2, invar, variant, lrs,
                                         marked) then begin
            ok := false;
            goto 9;
          end;
        end
        else if simple then
          if not l^.lr^.f2.b3_2 then begin
            l^.lr^.l52 := marked;
            marked := l^.lr;
            l^.lr^.f2.b3_2 := true;
          end;
        inp := inp^.next;
      end;
    end;
9:
  consider_mem_dependents := ok;
end;

{ partition_memory - the loads and stores that depend on l (a JOIN_BP's
  segment of a memory live range not yet looked at in this loop)
  sorted by consider_mem_dependents; invar is cleared when it fails;
  the live ranges it marked unmarked.  True when there are invariant
  candidates.  0x2282B8, 0xBA bytes, no A5. }

function partition_memory(
    l: lts_ptr_t;
    mark: integer32;
    l42: integer32;
    m2: integer32;
    var invar: instr_ptr_t;
    var variant: instr_ptr_t;
    var lrs: com_lrs_ptr_t;
    var marked: lr_ptr_t): boolean; options(val_param); internal;
var
  m3: integer32;
  lr: lr_ptr_t;
begin
  if l^.lr^.l40 = mark then begin
    partition_memory := false;
    return;
  end;
  if utils_ins_$operands_instruction(l^.refs)^.opc <> ord(opc$join_bp) then
    bug_check('COM_$partition_memory:  only JOIN_BP input permitted%$');
  invar := nil;
  variant := nil;
  lrs := nil;
  marked := nil;
  com_rtn^.marks := com_rtn^.marks + 1;
  m3 := com_rtn^.marks;
  if not consider_mem_dependents(l, mark, l42, m3, m2, invar, variant,
                                 lrs, marked) then
    invar := nil;
  lr := marked;
  while lr <> nil do begin
    lr^.f2.b3_2 := false;
    lr := lr^.l52;
  end;
  partition_memory := invar <> nil;
end;

{ is_join_bp - the operand o (a segment's refs, by address) is a
  JOIN_BP's.  0x2283A8, 0x34 bytes (loads A5: global, though no other
  unit calls it). }

function is_join_bp(
    in o: opnd_ptr_t): boolean;
begin
  if o = nil then
    is_join_bp := false
  else
    is_join_bp := utils_ins_$operands_instruction(o)^.opc = ord(opc$join_bp);
end;

{ worth_hoisting - the class (chained at l24) has a load, or a
  reference in a block of +20 bit 2 (one that every entry passes
  through).  0x2283DC, 0x3E bytes, no frame. }

function worth_hoisting(
    i: instr_ptr_t): boolean; options(val_param); internal;
begin
  while i <> nil do begin
    if (instruction_attributes[i^.opc].class = class$load)
        or i^.bb^.f20.b20_2 then begin
      worth_hoisting := true;
      return;
    end;
    i := instr_ptr_t(i^.l24);
  end;
  worth_hoisting := false;
end;

{ find_loop_memory_hoist_candidates - head's loop (its blocks marked
  mark and on contents; entries and exits its entry and exit blocks):
  the blocks every entry's postdominator chain reaches in the loop
  marked (+20 bit 2); for each memory live range entering the loop at a
  JOIN_BP (head's exposed segments), not looked at yet, its invariant
  loads and stores grouped into classes of one address
  (analyze_candidates) and each class worth it kept in a new live range
  (build_loads, build_stores, replace_mem_instrs), the head's exposed
  list then walked again; the new live ranges' SSA form and that of
  the memory live ranges touched recomputed; the replacing moves'
  copies eliminated (or, when nothing else reads their results,
  excised).  0x22841A, 0x352 bytes, no A5: the entries' l42 (-1 when
  they differ); the live range variable reused for the new live range
  (its l40 then set to mark, as the image does). }

procedure find_loop_memory_hoist_candidates(
    head: bb_ptr_t;
    mark: integer32;
    contents: bb_ptr_t;
    entries: bb_ptr_t;
    exits: bb_ptr_t); options(val_param); internal;
var
  b, p: bb_ptr_t;
  l42, m2, k: integer32;
  hmark: mrh_$mark_t;
  newlrs, lr, marked: lr_ptr_t;
  ssa, lrs: com_lrs_ptr_t;
  repl, invar, variant, c, eq, i, nx: instr_ptr_t;
  l, next: lts_ptr_t;
  any, simple: boolean;
  o: opnd_ptr_t;
begin
  b := contents;
  repeat
    b^.f20.b20_2 := false;
    b := com_bb_v_ptr_t(b)^.next142;
  until b = nil;
  b := entries;
  l42 := com_bb_v_ptr_t(b)^.l42;
  repeat
    p := b^.l58;
    while p <> nil do begin
      if p^.mark146 <> mark then
        exit;
      if p^.f20.b20_2 then
        exit;
      p^.f20.b20_2 := true;
      p := p^.l58;
    end;
    if l42 <> com_bb_v_ptr_t(b)^.l42 then
      l42 := -1;
    b := com_bb_v_ptr_t(b)^.next142;
  until b = nil;
  com_rtn^.marks := com_rtn^.marks + 1;
  m2 := com_rtn^.marks;
  hmark := mrh_$mark(com_heap);
  newlrs := nil;
  ssa := nil;
  repl := nil;
  l := head^.exposed;
  while l <> nil do begin
    lr := l^.lr;
    next := l^.next_exposed;
    if is_join_bp(l^.refs) then
      if lr^.rrp * [rrp$fp_reg, rrp$ip_reg] = [] then
        if lr^.l40 <> mark then
          if not lr^.f2.physical then
            if partition_memory(l, mark, l42, m2, invar, variant, lrs,
                                marked) then begin
              c := invar;
              any := false;
              while c <> nil do begin
                c := analyze_candidates(c, invar, variant, eq);
                if eq <> nil then
                  if worth_hoisting(eq) then begin
                    lr := build_loads(eq, entries, lrs, not any);
                    lr^.l52 := newlrs;
                    newlrs := lr;
                    if lr^.mate <> nil then begin
                      lr^.mate^.l52 := newlrs;
                      newlrs := lr^.mate;
                    end;
                    build_stores(eq, lr, marked, exits, not any);
                    replace_mem_instrs(eq, lr, contents, repl);
                    any := true;
                  end;
              end;
              if any then begin
                add_lrs_to_ssa_list(lrs, marked, ssa);
                next := head^.exposed;
              end;
            end;
    l := next;
    lr^.l40 := mark;
  end;
  if newlrs <> nil then begin
    lr := newlrs;
    while lr <> nil do begin
      fg_utils_$recompute_ssa_form_for_lr(lr);
      lr := lr^.l52;
    end;
    while ssa <> nil do begin
      for k := 1 to ssa^.count do
        fg_utils_$recompute_ssa_form_for_lr(ssa^.lrs[k]);
      ssa := ssa^.next;
    end;
    b := contents;
    while b <> nil do begin
      b^.mark146 := mark;
      b := com_bb_v_ptr_t(b)^.next142;
    end;
  end;
  mrh_$release_to_mark(com_heap, hmark);
  i := repl;
  while i <> nil do begin
    nx := instr_ptr_t(i^.l24);
    if i^.h.b2_6 then begin
      simple := true;
      for k := 1 to i^.h.nopnds do begin
        o := addr(i^.opnds[k]);
        if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
          if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then
            if o^.link <> nil then begin
              simple := false;
              exit;
            end
            else if o^.lts^.f2.final then
              if (o^.lts^.l28 <> nil) or (o^.lts^.l44 <> nil) then begin
                simple := false;
                exit;
              end;
      end;
      if not simple then
        tr_utils_$attempt_copy_elimination(com_rtn, i)
      else begin
        for k := 1 to i^.h.nopnds do begin
          o := addr(i^.opnds[k]);
          if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
            if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then
              utils_$excise_lts_cleanly(o^.lts, true);
        end;
        utils_$excise_instruction_cleanly(i, true);
      end;
    end;
    i := nx;
  end;
end;

{ lr_unconsumed_in_loop - l (the segment an instruction of the loop
  writes, final in its block, of a complex live range, read nowhere in
  the block) reaches no segment in a block of its own block's mark, and
  no JOIN_BP there or in exit whose other inputs come from such a
  block; found set when it reaches any.  0x22876C, 0xCA bytes, no A5:
  found set before each walk. }

function lr_unconsumed_in_loop(
    l: lts_ptr_t;
    exit_bb: bb_ptr_t;
    var found: boolean): boolean; options(val_param); internal;
var
  m: integer32;
  x: lts_ptr_t;
  j, q: com_jbi_ptr_t;
  ji: instr_ptr_t;
begin
  lr_unconsumed_in_loop := false;
  if l^.lr^.id = 0 then
    return;
  if l^.refs^.link <> nil then
    return;
  if not l^.f2.final then
    return;
  m := l^.bb^.mark146;
  x := l^.l28;
  if x <> nil then begin
    found := true;
    repeat
      if x^.bb^.mark146 = m then
        return;
      x := x^.l28;
    until x = nil;
  end;
  j := com_jbi_ptr_t(l^.l44);
  if j <> nil then begin
    found := true;
    repeat
      ji := j^.instr;
      if (ji^.bb^.mark146 = m) or (ji^.bb = exit_bb) then
        return;
      q := com_jbi_ptr_t(ji^.opnds[3].link);
      while q <> nil do begin
        if q <> j then
          if q^.lts^.bb^.mark146 = m then
            return;
        q := q^.next_op;
      end;
      j := j^.next;
    until j = nil;
  end;
  lr_unconsumed_in_loop := true;
end;

{ lr_value_same_on_loop_exit - the value the loop's instruction reads
  from l is the one that leaves the loop: for a simple live range, l
  is not meant to be modified; for a complex one, l is its live range's
  last segment in the block and its definition (l itself or the final
  segment reaching it) is of a marked (+3 bit 1) live range or outside
  the loop (mark), or it reaches a segment outside the loop, or a
  JOIN_BP outside it but in exit, or one at the head of an inner
  interval whose other inputs are all outside the loop (the definition's
  block one of +20 bit 2).  0x228836, 0x132 bytes, no A5. }

function lr_value_same_on_loop_exit(
    l: lts_ptr_t;
    exit_bb: bb_ptr_t;
    mark: integer32): boolean; options(val_param); internal;
label
  9;
var
  r, found: boolean;
  lr: lr_ptr_t;
  prev, d, x: lts_ptr_t;
  j, q: com_jbi_ptr_t;
  ji: instr_ptr_t;
begin
  lr := l^.lr;
  if lr^.id = 0 then
    r := not (rrp$intend_to_modify in l^.rrp)
  else begin
    r := false;
    if not l^.f2.first_in_bb then
      if utils_$find_last_lts_in_bb(lr, l^.bb, prev) <> l then
        goto 9;
    if l^.rrp * [rrp$modify, rrp$write] = [] then begin
      d := l^.l44;
      if d = nil then
        goto 9;
    end
    else
      d := l;
    if d^.lr^.f2.b3_1 or (d^.bb^.mark146 <> mark) then begin
      r := true;
      goto 9;
    end;
    if d^.f2.final then begin
      x := d^.l28;
      while x <> nil do begin
        if x^.bb^.mark146 <> mark then begin
          r := true;
          goto 9;
        end;
        x := x^.l28;
      end;
      j := com_jbi_ptr_t(d^.l44);
      while j <> nil do begin
        ji := j^.instr;
        if ji^.bb^.mark146 = mark then begin
          if d^.bb^.f20.b20_2 then
            if ji^.bb^.f.b18_6 then
              if not ji^.bb^.f.b18_5 then begin
                q := com_jbi_ptr_t(ji^.opnds[3].link);
                found := false;
                while q <> nil do begin
                  if q <> j then
                    if q^.lts^.bb^.mark146 = mark then begin
                      found := true;
                      exit;
                    end;
                  q := q^.next_op;
                end;
                if not found then begin
                  r := true;
                  goto 9;
                end;
              end;
        end
        else if ji^.bb <> exit_bb then begin
          r := true;
          goto 9;
        end;
        j := j^.next;
      end;
    end;
    r := false;
  end;
9:
  lr_value_same_on_loop_exit := r;
end;

{ suck_instrs_from_loop - for a loop of one exit block: the
  instructions of its blocks that every entry passes through (+20 bit
  2), from the last back, that do not branch, label or join, have only
  register, memory and constant operands, read only values the same on
  leaving the loop and write only values not used in the loop (but
  used after it): moved to the head of the exit block (after its labels
  and join birthpoints), each register or memory operand given the exit
  block's segment of its live range (made complex): a reader its exposed
  segment (made when there is none, reached from the old definition),
  a writer a new segment (or the exposed one it defined) to which the
  old segment's definition moves.  0x228968, 0x3BE bytes, no A5: head
  (8,A6) not read; the unlinking's `bne' on the flags of the store of
  the next link (pattern 111); the operand's rrp byte ORed into the
  segment's word. }

procedure suck_instrs_from_loop(
    head: bb_ptr_t;
    mark: integer32;
    contents: bb_ptr_t;
    exits: bb_ptr_t); options(val_param); internal;
label
  8;
var
  b, e: bb_ptr_t;
  i, prv, j, p: instr_ptr_t;
  found, r, created: boolean;
  k: integer32;
  o, q: opnd_ptr_t;
  lr: lr_ptr_t;
  ex, s: lts_ptr_t;
begin
  if contents = nil then
    return;
  if com_bb_v_ptr_t(exits)^.next142 <> nil then
    return;
  b := contents;
  repeat
    if b^.f20.b20_2 then begin
      i := b^.last;
      while i <> nil do begin
        prv := i^.prev;
        if instruction_attributes[i^.opc].class in
            [class$branch, class$fp_branch, class$jump, class$label,
             class$return, class$join_bp] then
          goto 8;
        if i^.h.b2_5 then
          if com_bb_v_ptr_t(b)^.l42 <> com_bb_v_ptr_t(exits)^.l42 then
            goto 8;
        found := false;
        for k := 1 to i^.h.nopnds do begin
          o := addr(i^.opnds[k]);
          if not (o^.h.kind in [operand$none..operand$fp_reg_pair,
                                operand$ip_condition_codes..operand$fp_reg_pair_like,
                                operand$displacement_routine..operand$immediate]) then
            goto 8;
          if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
            if o^.lts^.lr^.f2.physical then
              goto 8;
            if o^.h.read then
              r := lr_value_same_on_loop_exit(o^.lts, exits, mark)
            else
              r := lr_unconsumed_in_loop(o^.lts, exits, found);
            if not r then
              goto 8;
          end;
        end;
        if not found then
          goto 8;
        if i^.prev = nil then
          b^.first := i^.next
        else
          i^.prev^.next := i^.next;
        if i^.next = nil then
          b^.last := i^.prev
        else
          i^.next^.prev := i^.prev;
        e := exits;
        j := e^.first;
        while j <> nil do begin
          if (j^.opc <> ord(opc$join_bp)) and (j^.opc <> ord(opc$label)) then
            exit;
          j := j^.next;
        end;
        p := j^.prev;
        i^.prev := p;
        if p = nil then
          e^.first := i
        else
          p^.next := i;
        i^.next := j;
        j^.prev := i;
        i^.bb := e;
        for k := i^.h.nopnds downto 1 do begin
          o := addr(i^.opnds[k]);
          if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
            lr := o^.lts^.lr;
            if lr^.id = 0 then
              bv_$make_live_range_complex(com_rtn, lr);
            ex := utils_$find_exposed_lts(lr, exits);
            if o^.h.read then begin
              s := o^.lts;
              if s^.refs = o then
                s^.refs := o^.link
              else begin
                q := s^.refs;
                while q^.link <> o do
                  q := q^.link;
                q^.link := o^.link;
              end;
              if ex = nil then begin
                ex := utils_$get_exposed_lts(lr, exits, created);
                s := o^.lts;
                if s^.rrp * [rrp$modify, rrp$write] <> [] then
                  ex^.l44 := s
                else
                  ex^.l44 := s^.l44;
                if ex^.l44 <> nil then begin
                  ex^.l28 := lts_ptr_t(ex^.l44)^.l28;
                  lts_ptr_t(ex^.l44)^.l28 := ex;
                end;
                if o^.lts^.f2.final then begin
                  if ex^.f2.first_in_bb then
                    utils_$put_lts_on_final_list(ex);
                end
                else
                  utils_$put_lts_on_final_list(o^.lts);
              end;
            end
            else begin
              if ex <> nil then begin
                if ex^.l44 <> o^.lts then
                  bug_check('COM_$suck_instrs_from_loop: incorrect definition%$');
                s := o^.lts;
                if s^.l28 = ex then
                  s^.l28 := ex^.l28
                else begin
                  s := s^.l28;
                  while s^.l28 <> ex do
                    s := s^.l28;
                  s^.l28 := ex^.l28;
                end;
                ex^.l44 := nil;
                ex^.l28 := nil;
                ex^.l44 := nil;
                utils_$remove_lts_from_exposed_list(ex);
              end
              else
                ex := utils_$get_new_lts(lr, exits, true);
              utils_$move_definition(o^.lts, ex, false);
              if not ex^.f2.final then
                if (ex^.l28 <> nil) or (ex^.l44 <> nil) then
                  utils_$put_lts_on_final_list(ex);
              utils_$excise_lts_cleanly(o^.lts, false);
            end;
            o^.link := ex^.refs;
            ex^.refs := o;
            o^.lts := ex;
            ex^.rrp := rrp$set_t(integer(ex^.rrp) ! opnd_bytes_ptr_t(o)^.rrp);
          end;
        end;
    8:  i := prv;
      end;
    end;
    b := com_bb_v_ptr_t(b)^.next142;
  until b = nil;
end;

{ collect_exit_blocks - the blocks b's edges lead to outside the loop
  (not marked mark or mark - 1, and not reached by climbing the
  interval heads, l70, while their depth (+16) is at least head's)
  marked mark - 1 and pushed on exits; false when one is already an
  entry block (mark - 2).  0x228D58, 0x9A bytes, no A5: ok set again
  on the way out. }

function collect_exit_blocks(
    b: bb_ptr_t;
    head: bb_ptr_t;
    mark: integer32;
    var exits: bb_ptr_t): boolean; options(val_param); internal;
var
  e: fg_edge_ptr_t;
  t: bb_ptr_t;
  ok: boolean;
begin
  e := b^.succs;
  while e <> nil do begin
    t := e^.target;
    if (t^.mark146 <> mark - 1) and (t^.mark146 <> mark) then begin
      ok := true;
      while t^.f.b16 >= head^.f.b16 do begin
        if t = head then begin
          ok := false;
          exit;
        end;
        if t^.l70 = nil then begin
          ok := true;
          exit;
        end;
        t := t^.l70;
      end;
      if ok then begin
        if e^.target^.mark146 = mark - 2 then begin
          collect_exit_blocks := false;
          return;
        end;
        e^.target^.mark146 := mark - 1;
        com_bb_v_ptr_t(e^.target)^.next142 := exits;
        exits := e^.target;
      end;
    end;
    e := e^.next_succ;
  end;
  collect_exit_blocks := true;
end;

{ collect_loop_contents - the blocks of b's interval (l74, chained at
  l78, nested intervals' recursively) marked mark and put on contents
  in block order (last its tail), their exits collected; for the loop's
  head, the head put first, its exits collected and its predecessors
  outside the loop marked mark - 2 and pushed on entries.  False when an
  exit block is also an entry block.  0x228DF2, 0x15E bytes, no A5:
  recursive; the orders compared unsigned. }

function collect_loop_contents(
    b: bb_ptr_t;
    head: bb_ptr_t;
    mark: integer32;
    var contents: bb_ptr_t;
    var last: bb_ptr_t;
    var entries: bb_ptr_t;
    var exits: bb_ptr_t): boolean; options(val_param); internal;
var
  c, p, s: bb_ptr_t;
  e: fg_edge_ptr_t;
begin
  collect_loop_contents := false;
  b^.mark146 := mark;
  c := bb_ptr_t(b^.l74);
  while c <> nil do begin
    c^.mark146 := mark;
    if contents = nil then begin
      com_bb_v_ptr_t(c)^.next142 := nil;
      contents := c;
      last := c;
    end
    else if c^.order < contents^.order then begin
      com_bb_v_ptr_t(c)^.next142 := contents;
      contents := c;
    end
    else if c^.order > last^.order then begin
      com_bb_v_ptr_t(last)^.next142 := c;
      com_bb_v_ptr_t(c)^.next142 := nil;
      last := c;
    end
    else begin
      p := contents;
      while com_bb_v_ptr_t(p)^.next142 <> nil do begin
        if com_bb_v_ptr_t(p)^.next142^.order >= c^.order then
          exit;
        p := com_bb_v_ptr_t(p)^.next142;
      end;
      com_bb_v_ptr_t(c)^.next142 := com_bb_v_ptr_t(p)^.next142;
      com_bb_v_ptr_t(p)^.next142 := c;
    end;
    if c^.f.b18_6 then
      if not collect_loop_contents(c, head, mark, contents, last, entries,
                                   exits) then
        return;
    if c^.f.b18_1 then
      if not collect_exit_blocks(c, head, mark, exits) then
        return;
    c := c^.l78;
  end;
  if b = head then begin
    com_bb_v_ptr_t(b)^.next142 := contents;
    contents := b;
    if not collect_exit_blocks(b, head, mark, exits) then
      return;
    e := b^.preds;
    while e <> nil do begin
      s := e^.source;
      if (s^.mark146 <> mark) and (s^.mark146 <> mark - 2) then begin
        if s^.mark146 = mark - 1 then
          return;
        s^.mark146 := mark - 2;
        com_bb_v_ptr_t(e^.source)^.next142 := entries;
        entries := e^.source;
      end;
      e := e^.next_pred;
    end;
  end;
  collect_loop_contents := true;
end;

{ entry_blocks_safe - there are entry blocks and each ends in a JUMP and
  is not of kind 1 (+14).  0x228F50, 0x3A bytes, no frame: the last
  instruction tested for nil after its opcode is read (pattern 108). }

function entry_blocks_safe(
    var entries: bb_ptr_t): boolean; internal;
var
  b: bb_ptr_t;
  i: instr_ptr_t;
  ok: boolean;
begin
  if entries = nil then
    entry_blocks_safe := false
  else begin
    ok := true;
    b := entries;
    repeat
      i := b^.last;
      if (i^.opc <> ord(opc$jump)) or (b^.f14.b14 = 1) or (i = nil) then begin
        ok := false;
        exit;
      end;
      b := com_bb_v_ptr_t(b)^.next142;
    until b = nil;
    entry_blocks_safe := ok;
  end;
end;

{ exit_blocks_safe - no exit block is of kind 2 (+14), and each
  predecessor of an exit block outside the loop (mark) is a landing
  block of the loop (mark - 1, not the exit itself, one successor and
  one predecessor, nothing but labels before its JUMP), which is then
  taken off exits.  0x228F8A, 0xEA bytes, no A5. }

function exit_blocks_safe(
    var exits: bb_ptr_t;
    mark: integer32): boolean; options(val_param); internal;
var
  x, s, p: bb_ptr_t;
  e: fg_edge_ptr_t;
  i: instr_ptr_t;
begin
  exit_blocks_safe := false;
  x := exits;
  while x <> nil do begin
    if x^.f14.b14 = 2 then
      return;
    e := x^.preds;
    while e <> nil do begin
      s := e^.source;
      if s^.mark146 <> mark then begin
        if s = x then
          return;
        if s^.mark146 <> mark - 1 then
          return;
        if s^.succs = nil then
          return;
        if s^.succs^.next_succ <> nil then
          return;
        if s^.preds = nil then
          return;
        if s^.preds^.next_pred <> nil then
          return;
        i := s^.first;
        while i <> nil do begin
          if i^.opc <> ord(opc$label) then
            exit;
          i := i^.next;
        end;
        if i = nil then
          return;
        if i^.opc <> ord(opc$jump) then
          return;
        if exits = e^.source then
          exits := com_bb_v_ptr_t(e^.source)^.next142
        else begin
          p := exits;
          while p <> nil do begin
            if com_bb_v_ptr_t(p)^.next142 = e^.source then
              exit;
            p := com_bb_v_ptr_t(p)^.next142;
          end;
          if p = nil then
            return;
          com_bb_v_ptr_t(p)^.next142 := com_bb_v_ptr_t(e^.source)^.next142;
        end;
      end;
      e := e^.next_pred;
    end;
    x := com_bb_v_ptr_t(x)^.next142;
  end;
  exit_blocks_safe := true;
end;

{ loop_memory_analysis - the live ranges' +3 bit 2 cleared; for each
  loop (an interval head, +18 bit 6, not one of an outer interval's,
  bit 5, in bv's block order) whose contents, entry and exit blocks
  are collected and whose exits are safe: its invariant memory kept in
  registers (when its entries are safe too) and the instructions whose
  results only leave it sunk into its exit.  Three marks taken for each
  loop.  0x229074, 0xEA bytes, no A5. }

procedure loop_memory_analysis; internal;
var
  lr: lr_ptr_t;
  b, contents, last, entries, exits: bb_ptr_t;
  mark: integer32;
begin
  lr := com_rtn^.lrs;
  while lr <> nil do begin
    lr^.f2.b3_2 := false;
    lr := lr^.next;
  end;
  b := com_rtn^.bbs72;
  while b <> nil do begin
    if b^.f.b18_6 then
      if not b^.f.b18_5 then begin
        com_rtn^.marks := com_rtn^.marks + 3;
        mark := com_rtn^.marks;
        contents := nil;
        last := nil;
        entries := nil;
        exits := nil;
        if collect_loop_contents(b, b, mark, contents, last, entries,
                                 exits) then
          if exit_blocks_safe(exits, mark) then begin
            if entry_blocks_safe(entries) then
              find_loop_memory_hoist_candidates(b, mark, contents, entries,
                                                exits);
            suck_instrs_from_loop(b, mark, contents, exits);
          end;
      end;
    b := b^.next114;
  end;
end;

{ cvt_short_load_to_32_bits - the extract of width bits at shift that
  turns the stored longword into the value a short load ld read: the
  load's single reader when it is already that EXTRACTU (or the
  BE_EXTRACTU of 31 - shift); nil for shift 0 when no reader of the
  load (not final) needs more than width low bits; else a new EXTRACTU
  after ld, reading a new integer register live range that ld now
  writes and writing ld's old result.  0x22915E, 0x1AE bytes, no A5:
  the operand's link and segment copied as two longwords; A0. }

function cvt_short_load_to_32_bits(
    ld: instr_ptr_t;
    width: integer32;
    shift: integer32): instr_ptr_t; options(val_param); internal;
label
  1;
var
  x: instr_ptr_t;
  p: opnd_ptr_t;
  nlr: lr_ptr_t;
begin
  if (ld^.opnds[3].link <> nil) and (ld^.opnds[3].link^.link = nil)
      and not ld^.opnds[3].lts^.f2.final then
    x := utils_ins_$operands_instruction(ld^.opnds[3].link)
  else
    x := nil;
  if x <> nil then begin
    if x^.opc = ord(opc$extractu) then
      if x^.h.width = width then
        if x^.opnds[2].h.kind = operand$immediate then
          if x^.opnds[2].value = shift then begin
            cvt_short_load_to_32_bits := x;
            return;
          end;
    if x^.opc = ord(opc$be_extractu) then
      if x^.h.width = width then
        if x^.opnds[2].h.kind = operand$immediate then
          if x^.opnds[2].value = 31 - shift then begin
            cvt_short_load_to_32_bits := x;
            return;
          end;
  end;
  if shift = 0 then
    if not ld^.opnds[3].lts^.f2.final then begin
      p := ld^.opnds[3].link;
      while p <> nil do begin
        if sem_utils_$number_of_relevant_low_order_bits(p) > width then
          goto 1;
        p := p^.link;
      end;
      cvt_short_load_to_32_bits := nil;
      return;
    end;
1:
  x := lir_$optimizer_new_instruction(ld, ord(opc$extractu), true);
  x^.h.width := width;
  x^.opnds[2].h.num := 2;
  opnd_bytes_ptr_t(addr(x^.opnds[2]))^.rrp := 16;
  x^.opnds[2].h.kind := operand$immediate;
  x^.opnds[2].value := shift;
  x^.opnds[3].h.num := 3;
  x^.opnds[3].h.write := true;
  x^.opnds[3].h.kind := ld^.opnds[3].h.kind;
  x^.opnds[3].link := ld^.opnds[3].link;
  x^.opnds[3].lts := ld^.opnds[3].lts;
  x^.opnds[3].lts^.refs := addr(x^.opnds[3]);
  x^.opnds[1].h.num := 1;
  x^.opnds[1].h.read := true;
  x^.opnds[1].h.kind := ld^.opnds[3].h.kind;
  nlr := lir_$new_live_range_ip_reg;
  lir_utils_$add_lts_to_lr(24, nlr, x^.bb, x^.opnds[1].lts);
  ld^.opnds[3].lts := x^.opnds[1].lts;
  ld^.opnds[3].link := addr(x^.opnds[1]);
  x^.opnds[1].lts^.refs := addr(ld^.opnds[3]);
  cvt_short_load_to_32_bits := x;
end;

{ eliminate_load - the load ld, which reads (offset bytes into it)
  what the store st wrote, replaced by st's value: when ld also set
  condition codes, a TST (TSTS, TSTD) of its result after it takes
  them over; unless mode is 1 (the same address) and ld is at least a
  longword (instruction_attributes +19 bits 2..0), the extract that
  narrows the value (cvt_short_load_to_32_bits); ld's readers given
  st's value (com_$replace_oprs_value) and ld excised; the extract and
  the test simplified.  0x22930C, 0x28C bytes, no A5: the operand
  copied as three longwords; com_$replace_oprs_value's arguments popped
  by `lea (10,SP)' (pattern 51). }

procedure eliminate_load(
    st: instr_ptr_t;
    ld: instr_ptr_t;
    offset: integer32;
    mode: integer); options(val_param); internal;
var
  op: integer;
  t, x: instr_ptr_t;
  m: opnd_ptr_t;
  w: integer32;
begin
  if instruction_attributes[ld^.opc].b14_0
      and (ld^.h.sets_cc or ld^.h.b0_3) then begin
    if ld^.h.sets_cc then
      op := ord(opc$tst)
    else if ld^.opc = ord(opc$loads) then
      op := ord(opc$tsts)
    else if ld^.opc = ord(opc$loadd) then
      op := ord(opc$tstd)
    else
      bug_check('COM_$eliminate_load:  can''t figure out which TST to use%$');
    t := lir_$optimizer_new_instruction(ld, op, true);
    t^.num := ld^.num;
    t^.h.sets_cc := ld^.h.sets_cc;
    t^.h.b0_3 := ld^.h.b0_3;
    if not (ld^.opnds[3].h.kind in [operand$ip_reg..operand$fp_reg_pair_physical,
                                    operand$ip_reg_like..operand$fp_reg_pair_like,
                                    operand$case_jump_base]) then
      bug_check('COM_$eliminate_load: losing LOAD.CC into reg_like object.%$');
    t^.opnds[1].h.num := 1;
    t^.opnds[1].h.kind := ld^.opnds[3].h.kind;
    opnd_bytes_ptr_t(addr(t^.opnds[1]))^.rrp :=
        (opnd_bytes_ptr_t(addr(ld^.opnds[3]))^.rrp & 16#F7) ! 16;
    t^.opnds[1].lts := ld^.opnds[3].lts;
    t^.opnds[1].link := ld^.opnds[3].link;
    ld^.opnds[3].link := addr(t^.opnds[1]);
    if op = ord(opc$tstd) then begin
      m := utils_$find_mate_operand(addr(ld^.opnds[3]));
      t^.opnds[2].h.num := 2;
      t^.opnds[2].h.kind := m^.h.kind;
      opnd_bytes_ptr_t(addr(t^.opnds[2]))^.rrp :=
          (opnd_bytes_ptr_t(m)^.rrp & 16#F7) ! 16;
      t^.opnds[2].lts := m^.lts;
      t^.opnds[2].link := m^.link;
      m^.link := addr(t^.opnds[2]);
    end;
    t^.opnds[t^.h.nopnds] := ld^.opnds[ld^.h.nopnds];
    t^.opnds[t^.h.nopnds].h.num := t^.h.nopnds;
    t^.opnds[t^.h.nopnds].lts^.refs := addr(t^.opnds[t^.h.nopnds]);
  end
  else
    t := nil;
  if (mode = 1) and ((instruction_attributes[ld^.opc].w18 & 7) >= 2) then
    x := nil
  else begin
    w := lshft(8, instruction_attributes[ld^.opc].w18 & 7);
    x := cvt_short_load_to_32_bits(ld, w,
        lshft(8, instruction_attributes[st^.opc].w18 & 7) - w - offset * 8);
  end;
  com_$replace_oprs_value(addr(st^.opnds[1]), addr(ld^.opnds[3]), ld);
  utils_$excise_instruction_cleanly(ld, true);
  if x <> nil then
    trans_$kill_silly_extract(x);
  if t <> nil then
    tr_utils_$attempt_test_elimination(com_rtn, t);
end;

{ attempt_load_elimination - ld (a load whose memory operands all
  read) eliminated when its memory's birthpoint is a store's write to
  the same address (or, for an integer register result, one that
  contains it: mode 4), of the same result kind, not of a physical
  register, not in a block of +17 bit 6, ld not modifying its base or
  setting condition codes for a short load, a LOADD's a STORED's, a
  LOADS's a STORES's (and not into a register pair).  0x22960E, 0x1C4
  bytes, no A5: ld's memory segment the lowest numbered memory
  operand's (the loop runs from the last). }

function attempt_load_elimination(
    ld: instr_ptr_t): boolean; options(val_param); internal;
label
  9;
var
  r, phys: boolean;
  m: lts_ptr_t;
  k, disp: integer32;
  bp: utils_$birthpoint_t;
  st: instr_ptr_t;
  c: integer;
begin
  r := false;
  if instruction_attributes[ld^.opc].class = class$load then begin
    m := nil;
    for k := ld^.h.nopnds downto 1 do
      if ld^.opnds[k].h.kind in [operand$argument_block_memory..
                                 operand$well_behaved_memory] then begin
        if not ld^.opnds[k].h.read then
          goto 9;
        m := ld^.opnds[k].lts;
      end;
    if m = nil then
      goto 9;
    utils_$get_canonical_birthpoint(m, 0, bp);
    if bp.lts = nil then
      goto 9;
    if bp.lts^.rrp * [rrp$modify, rrp$write] = [] then
      goto 9;
    st := utils_ins_$operands_instruction(bp.lts^.refs);
    if instruction_attributes[st^.opc].class <> class$store then
      goto 9;
    if (instruction_attributes[st^.opc].class = class$store)
        and (st^.opnds[1].h.kind in [operand$ip_reg..operand$well_behaved_memory]) then
      phys := st^.opnds[1].lts^.lr^.f2.physical
    else
      phys := false;
    if ld^.h.sets_cc and ((instruction_attributes[ld^.opc].w18 & 7) < 2) then
      goto 9;
    if cell_head_ptr_t(ld)^.modify <> 0 then
      goto 9;
    if ld^.opnds[3].h.kind <> st^.opnds[1].h.kind then
      goto 9;
    if phys then
      goto 9;
    if st^.bb^.f.b17_6 then
      goto 9;
    if (ld^.opc = ord(opc$loadd)) and (st^.opc <> ord(opc$stored)) then
      goto 9;
    if ld^.opc = ord(opc$loads) then begin
      if st^.opc <> ord(opc$stores) then
        goto 9;
      if ld^.opnds[3].lts^.lr^.mate <> nil then
        goto 9;
    end;
    c := mmt_utils_$addr_compare(st, ld, false, disp);
    if c <> 1 then
      if c = 4 then begin
        if not (rrp$ip_reg in ld^.opnds[3].lts^.lr^.rrp) then
          goto 9;
      end
      else
        goto 9;
    eliminate_load(st, ld, disp, c);
    r := true;
  end;
9:
  attempt_load_elimination := r;
end;

{ excise_a_store - st taken out: the segment its (last) memory write
  defines handed over to the segment after it on its live range's list
  (its readers, and the reach when it was final: from that segment, or
  from the final segment reaching it when it does not write), the
  memory operand before the write given the readers' chain, the
  segment and st excised.  0x2297D2, 0x100 bytes, no A5: the segment
  after it is the written segment's +8. }

procedure excise_a_store(
    st: instr_ptr_t); options(val_param); internal;
var
  o, q: opnd_ptr_t;
  k: integer32;
  s, r: lts_ptr_t;
begin
  o := nil;
  for k := st^.h.nopnds downto 1 do
    if (st^.opnds[k].h.kind in [operand$argument_block_memory..
                                operand$well_behaved_memory])
        and ((opnd_bytes_ptr_t(addr(st^.opnds[k]))^.rrp & 12) <> 0) then begin
      o := addr(st^.opnds[k]);
      exit;
    end;
  s := o^.lts;
  r := s^.next;
  st^.opnds[o^.h.num - 1].link := o^.link;
  q := o^.link;
  while q <> nil do begin
    q^.lts := r;
    q := q^.link;
  end;
  o^.link := nil;
  if o^.lts^.f2.final then begin
    if r^.rrp * [rrp$modify, rrp$write] <> [] then
      utils_$move_definition(o^.lts, r, false)
    else
      utils_$move_definition(o^.lts, r^.l44, false);
    utils_$excise_lts_cleanly(o^.lts, false);
    utils_$put_lts_on_final_list(r);
  end
  else
    utils_$excise_lts_cleanly(o^.lts, false);
  utils_$excise_instruction_cleanly(st, true);
end;

{ simple_mmt_seq_input - for an MMT_SEQ with one operand that reads and
  at most one that writes: the segment it reads, when that is written
  by an instruction and read by nothing else; nil otherwise.  0x2298D2,
  0x96 bytes, no A5: A0. }

function simple_mmt_seq_input(
    s: instr_ptr_t): lts_ptr_t; options(val_param); internal;
label
  9;
var
  res, l: lts_ptr_t;
  rd, wr, o: opnd_ptr_t;
  k: integer32;
begin
  res := nil;
  if s^.opc = ord(opc$mmt_seq) then begin
    rd := nil;
    wr := nil;
    for k := 1 to s^.h.nopnds do begin
      o := addr(s^.opnds[k]);
      if o^.h.kind <> operand$none then
        if o^.h.read then begin
          if rd <> nil then
            goto 9;
          rd := o;
        end
        else begin
          if wr <> nil then
            goto 9;
          wr := o;
        end;
    end;
    if rd <> nil then begin
      l := rd^.lts;
      if l^.rrp * [rrp$modify, rrp$write] <> [] then
        if l^.refs^.link^.link = nil then
          res := l;
    end;
  end;
9:
  simple_mmt_seq_input := res;
end;

{ ltss_on_stores_to_same_addr - a and b (memory segments) are written by
  stores of one opcode to the same address (looking through a JOIN_BP's
  first input and a simple MMT_SEQ), neither modifying its base nor
  volatile: well behaved memory of one live range, or addresses
  mmt_utils_$addr_compare finds the same.  0x2299CA, 0xD4 bytes (loads
  A5: a utils_$pair_func_t, passed to utils_$apply_func_to_all_uses by
  store_is_redundant); addr_compare's report a register holding false. }

function ltss_on_stores_to_same_addr(
    a: lts_ptr_t;
    b: lts_ptr_t): boolean; options(val_param);
label
  9;
var
  r: boolean;
  ia, ib: instr_ptr_t;
  disp: integer32;

  { get_the_right_instr - the instruction that defines l: through a
    JOIN_BP to its first input's, through a simple MMT_SEQ to its
    input's.  0x229968, 0x62 bytes (nested): A0. }

  function get_the_right_instr(
      l: lts_ptr_t): instr_ptr_t; options(val_param);
  var
    i: instr_ptr_t;
    s: lts_ptr_t;
  begin
    i := utils_ins_$operands_instruction(l^.refs);
    if i^.opc = ord(opc$join_bp) then
      if i^.opnds[2].link <> nil then
        i := utils_ins_$operands_instruction(i^.opnds[2].link);
    if i^.opc = ord(opc$mmt_seq) then begin
      s := simple_mmt_seq_input(i);
      if s <> nil then
        i := utils_ins_$operands_instruction(s^.refs);
    end;
    get_the_right_instr := i;
  end;

begin
  r := false;
  if a^.refs = nil then
    goto 9;
  if b^.refs = nil then
    goto 9;
  ia := get_the_right_instr(a);
  ib := get_the_right_instr(b);
  if cell_head_ptr_t(ib)^.modify <> 0 then
    goto 9;
  if cell_head_ptr_t(ia)^.modify <> 0 then
    goto 9;
  if ib^.h.b2_4 then
    goto 9;
  if ia^.h.b2_4 then
    goto 9;
  if ia^.opc <> ib^.opc then
    goto 9;
  if instruction_attributes[ia^.opc].class <> class$store then
    goto 9;
  if (a^.refs^.h.kind = operand$well_behaved_memory) and (a^.lr = b^.lr) then
    r := true
  else if mmt_utils_$addr_compare(ia, ib, false, disp) = 1 then
    r := true;
9:
  ltss_on_stores_to_same_addr := r;
end;

{ store_is_redundant - always true (go on with the walk): when the
  store that defines a (through a simple MMT_SEQ) writes the same
  address as b's, is not do_not_delete, a is not read, and every use
  of a is such a segment too, the store is excised and com_306 set.
  0x229A9E, 0x9C bytes (loads A5: a utils_$pair_func_t, passed to
  utils_$apply_func_to_all_defs by attempt_store_elimination). }

function store_is_redundant(
    a: lts_ptr_t;
    b: lts_ptr_t): boolean; options(val_param);
label
  9;
var
  s: lts_ptr_t;
  i: instr_ptr_t;
begin
  s := a;
  if a^.refs <> nil then begin
    i := utils_ins_$operands_instruction(a^.refs);
    if i^.opc = ord(opc$mmt_seq) then begin
      s := simple_mmt_seq_input(i);
      if s = nil then
        goto 9;
    end;
  end;
  if ltss_on_stores_to_same_addr(s, b) then begin
    i := utils_ins_$operands_instruction(s^.refs);
    if not i^.h.b2_3 then
      if not (rrp$read in a^.rrp) then
        if utils_$apply_func_to_all_uses(com_rtn,
               addr(ltss_on_stores_to_same_addr), a) then begin
          excise_a_store(i);
          com_306 := true;
        end;
  end;
9:
  store_is_redundant := true;
end;

{ get_mem_birthpoint - the birthpoint (following everything, 7) of the
  memory i reads (its last memory operand that reads); false when it
  reads none.  0x229B3A, 0x78 bytes (loads A5: global, though no other
  unit calls it). }

function get_mem_birthpoint(
    i: instr_ptr_t;
    var bp: utils_$birthpoint_t): boolean; options(val_param);
var
  k: integer32;
begin
  for k := i^.h.nopnds downto 1 do
    if i^.opnds[k].h.kind in [operand$argument_block_memory..
                              operand$well_behaved_memory] then
      if i^.opnds[k].h.read then begin
        utils_$get_canonical_birthpoint(i^.opnds[k].lts, 7, bp);
        get_mem_birthpoint := true;
        return;
      end;
  get_mem_birthpoint := false;
end;

{ safe_to_ignore_do_not_delete - the do_not_delete store st may go: it
  is in ld's block, stores the value (both halves of a pair) ld loads,
  and nothing but ld reads the memory it reads.  0x229BB2, 0xE4 bytes,
  no A5: the pair kinds `btst' in 16#4048. }

function safe_to_ignore_do_not_delete(
    st: instr_ptr_t;
    ld: instr_ptr_t): boolean; options(val_param); internal;
label
  9;
var
  r: boolean;
  m, p: opnd_ptr_t;
  k: integer32;
begin
  r := false;
  if ld^.bb <> st^.bb then
    goto 9;
  if utils_ins_$operands_instruction(st^.opnds[1].lts^.refs) <> ld then
    goto 9;
  if st^.opnds[1].h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                             operand$fp_reg_pair_like] then begin
    m := utils_$find_mate_operand(addr(st^.opnds[1]));
    if utils_ins_$operands_instruction(m^.lts^.refs) <> ld then
      goto 9;
  end;
  for k := st^.h.nopnds downto 1 do
    if st^.opnds[k].h.kind in [operand$argument_block_memory..
                               operand$well_behaved_memory] then
      if st^.opnds[k].h.read then begin
        p := st^.opnds[k].lts^.refs;
        while p <> nil do begin
          if (opnd_bytes_ptr_t(p)^.rrp & 16#30) = 16 then
            if utils_ins_$operands_instruction(p) <> ld then
              goto 9;
          p := p^.link;
        end;
        exit;
      end;
  r := true;
9:
  safe_to_ignore_do_not_delete := r;
end;

{ convert_store_to_seq - a store that writes no register made a SEQ (not
  do_not_delete) whose address operands are dropped; false for anything
  else.  0x229C96, 0xF0 bytes, no A5: the second
  utils_$remove_reader_from_lts's arguments left on the stack. }

function convert_store_to_seq(
    st: instr_ptr_t): boolean; options(val_param); internal;
var
  k: integer32;
begin
  convert_store_to_seq := false;
  if instruction_attributes[st^.opc].class <> class$store then
    return;
  for k := 1 to st^.h.nopnds do
    if st^.opnds[k].h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if (opnd_bytes_ptr_t(addr(st^.opnds[k]))^.rrp & 12) <> 0 then
        if not (st^.opnds[k].h.kind in [operand$argument_block_memory..
                                        operand$well_behaved_memory]) then
          return;
  st^.opc := ord(opc$seq);
  st^.h.b2_3 := false;
  if st^.opnds[2].h.kind in [operand$ip_reg..operand$well_behaved_memory] then
    utils_$remove_reader_from_lts(addr(st^.opnds[2]), true);
  st^.opnds[2].h.kind := operand$none;
  opnd_bytes_ptr_t(addr(st^.opnds[2]))^.rrp := 0;
  if st^.opnds[3].h.kind in [operand$ip_reg..operand$well_behaved_memory] then
    utils_$remove_reader_from_lts(addr(st^.opnds[3]), true);
  st^.opnds[3].h.kind := operand$none;
  opnd_bytes_ptr_t(addr(st^.opnds[3]))^.rrp := 0;
  convert_store_to_seq := true;
end;

{ attempt_store_elimination - st (a store) taken out when it is
  redundant: first the earlier stores to its address whose memory only
  st reads (store_is_redundant over the definitions reaching a join or
  exposed memory segment, st made do_not_delete meanwhile, repeated
  while it excises one; a single earlier store mmt_utils_$addr_compare
  finds the same or covered, 1 or 5, excised); then, unless volatile
  (or, with respect_dnd, do_not_delete), when st stores back what a
  load of the same address (and memory birthpoint) loaded: excised, or
  made a SEQ when do_not_delete and not safe to ignore.  0x229D86,
  0x2B6 bytes, no A5: the loop's test of the memory operand, which does
  not change; the birthpoints 24 bytes apart. }

function attempt_store_elimination(
    st: instr_ptr_t;
    respect_dnd: boolean): boolean; options(val_param); internal;
label
  1, 9;
var
  r, dnd, r1, r2: boolean;
  mo, m, m2: opnd_ptr_t;
  k, disp: integer32;
  i, ld: instr_ptr_t;
  c: integer;
  bp, bp2, bpa, bpb: utils_$birthpoint_t;
begin
  r := false;
  mo := nil;
  for k := st^.h.nopnds downto 1 do
    if st^.opnds[k].h.kind in [operand$argument_block_memory..
                               operand$well_behaved_memory] then
      if st^.opnds[k].h.read then begin
        mo := addr(st^.opnds[k]);
        exit;
      end;
  while mo <> nil do begin
    i := utils_ins_$operands_instruction(mo^.lts^.refs);
    if mo^.lts^.f2.exposed or (i^.opc = ord(opc$join_bp)) then begin
      com_306 := false;
      dnd := st^.h.b2_3;
      st^.h.b2_3 := true;
      discard(utils_$apply_func_to_all_defs(com_rtn, addr(store_is_redundant),
                                            mo^.lts));
      st^.h.b2_3 := dnd;
      if not com_306 then
        goto 1;
    end
    else begin
      if instruction_attributes[i^.opc].class <> class$store then
        goto 1;
      if i^.h.b2_3 then
        goto 1;
      if mo^.lts^.refs^.link <> mo then
        goto 1;
      if mo^.link <> nil then
        goto 1;
      c := mmt_utils_$addr_compare(i, st, false, disp);
      if not (c in [1, 5]) then
        goto 1;
      excise_a_store(i);
    end;
  end;
1:
  if st^.h.b2_4 then
    goto 9;
  if respect_dnd then
    if st^.h.b2_3 then
      goto 9;
  utils_$get_canonical_birthpoint(st^.opnds[1].lts, 0, bp);
  if bp.lts = nil then
    goto 9;
  if bp.lts^.refs = nil then
    goto 9;
  ld := utils_ins_$operands_instruction(bp.lts^.refs);
  if instruction_attributes[ld^.opc].class <> class$load then
    goto 9;
  if bp.lts^.refs^.h.num <> 3 then
    goto 9;
  if st^.opnds[1].h.kind <> ld^.opnds[3].h.kind then
    goto 9;
  if mmt_utils_$addr_compare(ld, st, false, disp) <> 1 then
    goto 9;
  if st^.opnds[1].h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                             operand$fp_reg_pair_like] then begin
    m := utils_$find_mate_operand(addr(st^.opnds[1]));
    utils_$get_canonical_birthpoint(m^.lts, 0, bp2);
    m2 := utils_$find_mate_operand(bp.lts^.refs);
    if bp2.lts = nil then
      goto 9;
    if bp2.lts^.refs <> m2 then
      goto 9;
  end;
  r1 := get_mem_birthpoint(ld, bpa);
  r2 := get_mem_birthpoint(st, bpb);
  if not (r2 and r1) then
    goto 9;
  if not utils_$compare_birthpoints(bpa, bpb) then
    goto 9;
  if st^.h.b2_3 then
    if not safe_to_ignore_do_not_delete(st, ld) then begin
      r := convert_store_to_seq(st);
      goto 9;
    end;
  excise_a_store(st);
  r := true;
9:
  attempt_store_elimination := r;
end;

{ attempt_do_not_delete_removal - every do_not_delete store that is not
  volatile tried again, do_not_delete not respected.  0x22A03C, 0x76
  bytes, no A5. }

procedure attempt_do_not_delete_removal; internal;
var
  b: bb_ptr_t;
  i, nx: instr_ptr_t;
begin
  b := com_rtn^.bbs;
  while b <> nil do begin
    i := b^.first;
    while i <> nil do begin
      nx := i^.next;
      if i^.h.b2_3 then
        if not i^.h.b2_4 then
          if instruction_attributes[i^.opc].class = class$store then
            discard(attempt_store_elimination(i, false));
      i := nx;
    end;
    b := b^.next;
  end;
end;

{ move_is_zero - mv, a MOVE of zero into an integer register live range
  that is neither modified nor physical (and simple, or marked +3 bit
  1): every operand of the live range made the zero register (kind
  ip_reg_like, lir_main_c4c's segment), the MOVEs that copy it treated
  the same way (recursively, made not snuggle), the segments excised,
  and mv excised unless it sets condition codes.  0x22A0B2, 0xE8 bytes,
  no A5: the excision a procedure call. }

procedure move_is_zero(
    mv: instr_ptr_t); options(val_param); internal;
var
  lr: lr_ptr_t;
  l, nx: lts_ptr_t;
  o: opnd_ptr_t;
  i: instr_ptr_t;
begin
  if mv^.opnds[2].h.kind <> operand$ip_reg then
    return;
  lr := mv^.opnds[2].lts^.lr;
  if (rrp$modify in lr^.rrp) or lr^.f2.physical then
    return;
  if lr^.id <> 0 then
    if not lr^.f2.b3_1 then
      return;
  l := lr^.ltss;
  while l <> nil do begin
    o := l^.refs;
    while o <> nil do begin
      o^.lts := lts_ptr_t(lir_main_c4c);
      o^.h.kind := operand$ip_reg_like;
      if o^.h.read then
        if o^.h.num = 1 then begin
          i := utils_ins_$operands_instruction(o);
          if i^.opc = ord(opc$move) then begin
            i^.h.b0_6 := false;
            move_is_zero(i);
          end;
        end;
      o := o^.link;
    end;
    nx := l^.next;
    utils_$excise_lts_cleanly(l, true);
    l := nx;
  end;
  lr^.ltss := nil;
  if not mv^.h.sets_cc then
    lir_utils_$excise_inst(mv);
end;

{ replace_zero_valued_lrs - every live MOVE of an immediate 0, or of the
  zero register (a physical like register whose register, +2, is
  target_properties' +0x14), handed to move_is_zero.  0x22A19A, 0x8A
  bytes, no A5. }

procedure replace_zero_valued_lrs; internal;
var
  b: bb_ptr_t;
  i: instr_ptr_t;
  lr: lr_ptr_t;
begin
  b := com_rtn^.bbs;
  while b <> nil do begin
    i := b^.first;
    while i <> nil do begin
      if i^.h.b2_6 then
        if i^.opc = ord(opc$move) then
          if (i^.opnds[1].h.kind = operand$immediate)
              and (i^.opnds[1].value = 0) then
            move_is_zero(i)
          else if i^.opnds[1].h.kind = operand$ip_reg_like then begin
            lr := i^.opnds[1].lts^.lr;
            if lr^.f2.physical then
              if lr^.f2.reg = target_properties.p_14[0] then
                move_is_zero(i);
          end;
      i := i^.next;
    end;
    b := b^.next;
  end;
end;

{ calc_last_legal_dom_bb - b is on the dominator chain (l54) from d:
  last becomes b when it comes before last, else last must come before
  b there.  0x22A224, 0x52 bytes, no A5. }

function calc_last_legal_dom_bb(
    b: bb_ptr_t;
    var last: bb_ptr_t;
    d: bb_ptr_t): boolean; options(val_param); internal;
begin
  while d <> nil do begin
    if b = d then begin
      last := b;
      calc_last_legal_dom_bb := true;
      return;
    end;
    if last = d then begin
      d := d^.l54;
      while d <> nil do begin
        if b = d then begin
          calc_last_legal_dom_bb := true;
          return;
        end;
        d := d^.l54;
      end;
      calc_last_legal_dom_bb := false;
      return;
    end;
    d := d^.l54;
  end;
  calc_last_legal_dom_bb := false;
end;

{ def_dominates_use - l's block dominates the block of its live range's
  first segment (or that segment is not exposed).  0x22A276, 0x42
  bytes, no A5. }

function def_dominates_use(
    l: lts_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  b, d: bb_ptr_t;
  f: lts_ptr_t;
begin
  r := false;
  b := l^.bb;
  f := l^.lr^.ltss;
  if not f^.f2.exposed then
    r := true
  else begin
    d := f^.bb;
    while d <> nil do begin
      if d = b then
        exit;
      d := d^.l54;
    end;
    if d <> nil then
      r := true;
  end;
  def_dominates_use := r;
end;

{ bb_postdominates - a is on b's postdominator chain (l58) and has its
  l42.  0x22A2B8, 0x3E bytes, no A5. }

function bb_postdominates(
    a: bb_ptr_t;
    b: bb_ptr_t): boolean; options(val_param); internal;
var
  p: bb_ptr_t;
begin
  if com_bb_v_ptr_t(b)^.l42 <> com_bb_v_ptr_t(a)^.l42 then begin
    bb_postdominates := false;
    return;
  end;
  p := b^.l58;
  while p <> nil do begin
    if p = a then begin
      bb_postdominates := true;
      return;
    end;
    p := p^.l58;
  end;
  bb_postdominates := false;
end;

{ maybe_hoist_instr_from_loop - i (in a loop) moved before the closing
  branches of the highest dominator (l54) of a lower depth (+16) that
  is not of kind 1 (+14) and that it may go to: its operands registers,
  memory or constants that neither modify nor mean to modify, its reads
  of exposed segments only (that no instruction of the loop writes,
  below the definitions' blocks), its writes of marked (+3 bit 1)
  live ranges that are not physical; a block i's block does not
  postdominate is taken only when i writes nothing its definition does
  not dominate and has no +2 bit 5.  Its readers then read the
  segments entering the new block (made when there are none), its
  writers write the live ranges' final segments there, the old written
  segments made exposed in the old block, written from there.
  0x22A2F6, 0x3BE bytes, no A5. }

function maybe_hoist_instr_from_loop(
    i: instr_ptr_t): boolean; options(val_param); internal;
label
  1;
var
  dom, last, t, bb, tgt: bb_ptr_t;
  anywrite, created: boolean;
  k: integer32;
  o, p: opnd_ptr_t;
  s, x, f: lts_ptr_t;
  lr: lr_ptr_t;
  j: instr_ptr_t;
begin
  maybe_hoist_instr_from_loop := false;
  dom := i^.bb^.l54;
  if dom = nil then
    return;
  last := nil;
  anywrite := false;
  for k := 1 to i^.h.nopnds do begin
    o := addr(i^.opnds[k]);
    if not (o^.h.kind in [operand$none..operand$fp_reg_pair,
                          operand$ip_condition_codes..operand$fp_reg_pair_like,
                          operand$displacement_routine..operand$immediate]) then
      return;
    if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      if (opnd_bytes_ptr_t(o)^.rrp & 16#24) <> 0 then
        return;
      if o^.h.read then begin
        s := o^.lts;
        if not s^.f2.exposed then
          return;
        if s^.rrp * [rrp$modify, rrp$write, rrp$intend_to_modify] <> [] then
          return;
        if s^.l44 <> nil then begin
          t := last;
          if not calc_last_legal_dom_bb(lts_ptr_t(s^.l44)^.bb, t, dom) then
            return;
          last := t;
        end;
      end
      else if o^.h.write then begin
        lr := o^.lts^.lr;
        if not lr^.f2.b3_1 then
          return;
        if lr^.f2.physical then
          return;
        if not def_dominates_use(o^.lts) then
          anywrite := true;
      end;
    end;
  end;
  bb := i^.bb;
  tgt := bb;
  if last <> tgt then
    while dom <> nil do begin
      if dom^.f.b16 < tgt^.f.b16 then
        if bb_postdominates(bb, dom)
            or (not anywrite and not i^.h.b2_5) then begin
          tgt := dom;
          if tgt^.f.b16 = 0 then
            goto 1;
        end;
      if dom = last then
        goto 1;
      dom := dom^.l54;
    end;
1:
  if tgt = nil then
    return;
  if tgt^.f.b16 >= bb^.f.b16 then
    return;
  if tgt^.f14.b14 = 1 then
    return;
  if bb^.first = i then
    bb^.first := i^.next
  else
    i^.prev^.next := i^.next;
  if bb^.last = i then
    bb^.last := i^.prev
  else
    i^.next^.prev := i^.prev;
  j := tgt^.last;
  while j <> nil do begin
    if not (instruction_attributes[j^.opc].class in
            [class$branch, class$fp_branch, class$jump, class$return]) then
      exit;
    j := j^.prev;
  end;
  if j = nil then begin
    i^.next := tgt^.first;
    tgt^.first := i;
    i^.prev := nil;
  end
  else begin
    i^.next := j^.next;
    j^.next := i;
    i^.prev := j;
  end;
  if i^.next = nil then
    tgt^.last := i
  else
    i^.next^.prev := i;
  i^.bb := tgt;
  for k := 1 to i^.h.nopnds do begin
    o := addr(i^.opnds[k]);
    if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      s := o^.lts;
      if s^.refs = o then
        s^.refs := o^.link
      else begin
        p := s^.refs;
        while p^.link <> o do
          p := p^.link;
        p^.link := o^.link;
      end;
      if o^.h.read then begin
        x := s^.lr^.ltss;
        while x <> nil do begin
          if x^.bb = tgt then
            exit;
          x := x^.next;
        end;
        if x = nil then
          x := make_entering_lts(s^.lr, tgt, s^.l44);
        x^.rrp := rrp$set_t(integer(x^.rrp) ! (opnd_bytes_ptr_t(o)^.rrp & 3));
        opnd_bytes_ptr_t(o)^.rrp := opnd_bytes_ptr_t(o)^.rrp
                                    ! (integer(x^.rrp) & 3);
        o^.lts := x;
        if x^.refs = nil then begin
          x^.refs := o;
          o^.link := nil;
        end
        else begin
          o^.link := x^.refs^.link;
          x^.refs^.link := o;
        end;
      end
      else if o^.h.write then begin
        lr := s^.lr;
        if lr^.id = 0 then
          bv_$make_live_range_complex(com_rtn, lr);
        f := utils_$get_final_lts(lr, tgt, created);
        f^.rrp := rrp$set_t(integer(f^.rrp) ! ((integer(s^.rrp) & 3) ! 8));
        o^.lts := f;
        o^.link := nil;
        f^.refs := o;
        s^.rrp := s^.rrp - [rrp$write];
        s^.lr^.f2.b3_1 := true;
        s^.f2.exposed := true;
        s^.next_exposed := bb^.exposed;
        bb^.exposed := s;
        utils_$move_definition(s, f, true);
      end;
    end;
  end;
  maybe_hoist_instr_from_loop := true;
end;

{ connect_physical - the one reader of src (a physical register's
  definition, made none) made a reader of dst's segment, after dst,
  with dst's even/odd bits.  0x22A6B4, 0x62 bytes, no A5. }

procedure connect_physical(
    dst: opnd_ptr_t;
    src: opnd_ptr_t); options(val_param); internal;
var
  r: opnd_ptr_t;
begin
  r := src^.link;
  if r <> nil then begin
    src^.link := nil;
    src^.h.kind := operand$none;
    if r^.link <> nil then
      bug_check('COM_$connect_physical:  destination physical LTS has more than 1 reader.%$');
    r^.link := dst^.link;
    r^.lts := dst^.lts;
    dst^.link := r;
    opnd_bytes_ptr_t(r)^.rrp := (opnd_bytes_ptr_t(r)^.rrp & 16#FC)
                                ! (opnd_bytes_ptr_t(dst)^.rrp & 3);
  end;
end;

{ call_cossin - two calls of one block, a (kept) and b (removed), of
  the sine and cosine library routine for one argument, made one call
  of a88k_$cossin (a88k_$dcossin for a register pair) computing both:
  when a computed only one, the second result's physical registers
  (lir_3f94, or the pair lir_3f98 and lir_3f9c, operands 5 or 7 and 8)
  added to it and the call's result flags (+4 of the slot after its
  operands) cleared; b's result readers connected to a's matching
  results (through a snuggle move when a computed both); a's kind bits
  (+3 bits 1..0) made 3; the call's address: the DB relative LOADL that
  feeds only it given the new address constant, else a new LOADL of it
  from the DB live range's segment in a's block (the old load excised
  when nothing else reads it); b's results and b excised.  0x22A760,
  0x65C bytes, no A5: the descriptors are at_lib_dsc +0xB10 and +0xB7C;
  the new LOADL's opcode and `after' pushed as one longword (#0x00690000,
  pattern 105); lir_$new_live_range_ip_reg called between
  lir_utils_$add_lts_to_lr's pushes (pattern 103). }

procedure call_cossin(
    a: instr_ptr_t;
    b: instr_ptr_t); options(val_param); internal;
label
  8;
var
  pair, ok: boolean;
  l, db: lts_ptr_t;
  r1, r2, s1, s2, x, r, p, o1: opnd_ptr_t;
  m, k: integer32;
  xi, d, di, n: instr_ptr_t;
  ac: com_node_v_ptr_t;
  bp: utils_$birthpoint_t;
  flags: com_int_ptr_t;
begin
  if com_level > 0 then
    vfmt_$write('Replacing instruction %3ZWD with COSSIN instruction %3ZWD%.',
                b^.num, a^.num);
  if a^.bb <> b^.bb then
    bug_check('COM_$call_cossin: instructions must be in same basic block.%$');
  pair := a^.opnds[3].h.kind in [operand$fp_reg_pair,
                                 operand$fp_reg_pair_physical,
                                 operand$fp_reg_pair_like];
  if (a^.h.width & 3) <> 3 then begin
    flags := com_int_ptr_t(integer32(a) + 48 + 12 * a^.h.nopnds);
    if pair then begin
      lir_utils_$add_lts_to_lr(24, lr_ptr_t(lir_3f98), a^.bb, l);
      a^.opnds[7].h.kind := operand$fp_reg_pair;
      a^.opnds[7].h.num := 7;
      opnd_bytes_ptr_t(addr(a^.opnds[7]))^.rrp := 9;
      a^.opnds[7].lts := l;
      l^.refs := addr(a^.opnds[7]);
      lir_utils_$add_lts_to_lr(24, lr_ptr_t(lir_3f9c), a^.bb, l);
      a^.opnds[8].h.kind := operand$fp_reg_pair;
      a^.opnds[8].h.num := 8;
      opnd_bytes_ptr_t(addr(a^.opnds[8]))^.rrp := 10;
      a^.opnds[8].lts := l;
      l^.refs := addr(a^.opnds[8]);
      flags^ := flags^ & ~12;
    end
    else begin
      lir_utils_$add_lts_to_lr(24, lr_ptr_t(lir_3f94), a^.bb, l);
      a^.opnds[5].h.kind := operand$fp_reg;
      a^.opnds[5].h.num := 5;
      opnd_bytes_ptr_t(addr(a^.opnds[5]))^.rrp := 10;
      a^.opnds[5].lts := l;
      l^.refs := addr(a^.opnds[5]);
      flags^ := flags^ & ~2;
    end;
  end;
  if pair then begin
    r1 := addr(a^.opnds[4]);
    r2 := addr(a^.opnds[6]);
    s1 := addr(a^.opnds[7]);
    s2 := addr(a^.opnds[8]);
  end
  else begin
    r1 := addr(a^.opnds[4]);
    r2 := nil;
    s1 := addr(a^.opnds[5]);
    s2 := nil;
  end;
  m := a^.h.width & 3;
  if m = 3 then begin
    if (b^.h.width & 3) = 1 then
      x := r2
    else begin
      r1 := s1;
      x := s2;
    end;
    if r1^.link <> nil then begin
      xi := utils_ins_$operands_instruction(r1^.link);
      if xi^.h.b0_6 then
        r1 := addr(xi^.opnds[r1^.link^.h.num + 1]);
    end;
    connect_physical(r1, addr(b^.opnds[4]));
    if x <> nil then
      connect_physical(x, addr(b^.opnds[6]));
    goto 8;
  end;
  if m = 2 then begin
    if r1^.link <> nil then begin
      r := r1^.link;
      r^.lts := s1^.lts;
      opnd_bytes_ptr_t(r)^.rrp := (opnd_bytes_ptr_t(r)^.rrp & 16#FC)
                                  ! (opnd_bytes_ptr_t(s1)^.rrp & 3);
      s1^.link := r1^.link;
      r1^.link := nil;
    end;
    if r2 <> nil then
      if r2^.link <> nil then begin
        r := r2^.link;
        r^.lts := s2^.lts;
        opnd_bytes_ptr_t(r)^.rrp := (opnd_bytes_ptr_t(r)^.rrp & 16#FC)
                                    ! (opnd_bytes_ptr_t(s2)^.rrp & 3);
        s2^.link := r2^.link;
        r2^.link := nil;
      end;
  end;
  if (b^.h.width & 3) = 1 then begin
    connect_physical(r1, addr(b^.opnds[4]));
    if r2 <> nil then
      connect_physical(r2, addr(b^.opnds[6]));
  end
  else begin
    connect_physical(s1, addr(b^.opnds[4]));
    if s2 <> nil then
      connect_physical(s2, addr(b^.opnds[6]));
  end;
  a^.h.width := a^.h.width ! 3;
  if pair then
    ac := com_node_v_ptr_t(make_new_addr_con(2, addr(at_lib_dsc[16#B7C]), 0,
                           com_node_v_ptr_t(com_rtn^.node)^.sect, false))
  else
    ac := com_node_v_ptr_t(make_new_addr_con(2, addr(at_lib_dsc[16#B10]), 0,
                           com_node_v_ptr_t(com_rtn^.node)^.sect, false));
  p := a^.opnds[1].lts^.refs;
  d := utils_ins_$operands_instruction(p);
  if p^.h.write then
    if d^.opnds[2].h.kind = operand$ip_reg then
      if d^.opnds[1].h.kind = operand$immediate then
        if d^.opc = ord(opc$loadl) then
          if p^.link^.link = nil then
            if p^.lts^.lr^.id = 0 then
              if d^.opnds[2].lts^.lr = com_rtn^.lr108 then begin
                d^.opnds[1].value := ac^.l16;
                d^.opnds[1].link := opnd_ptr_t(ac);
                goto 8;
              end;
  utils_$get_canonical_birthpoint(a^.opnds[1].lts, 0, bp);
  if (bp.lts = nil) or (bp.lts^.refs = nil) then
    bug_check('COM_$call_cossin: unable to find birth_lts for addr_con load.%$');
  d := utils_ins_$operands_instruction(bp.lts^.refs);
  if (d^.opc <> ord(opc$loadl))
      or (d^.opnds[2].lts^.lr^.node20 <> com_rtn^.lr108^.node20) then
    bug_check('COM_$call_cossin: addr_con birthpoint isn''t a DB relative LOADL.%$');
  db := d^.opnds[2].lts;
  if d^.bb <> a^.bb then
    db := make_entering_lts(db^.lr, a^.bb,
                            utils_$locate_definition(db^.lr, a^.bb));
  o1 := addr(a^.opnds[1]);
  if o1 = p then
    p^.lts^.refs := p^.link
  else begin
    while p^.link <> o1 do
      p := p^.link;
    p^.link := p^.link^.link;
    di := utils_ins_$operands_instruction(p);
    ok := true;
    for k := 1 to di^.h.nopnds do
      if di^.opnds[k].h.kind in [operand$ip_reg..operand$well_behaved_memory] then
        if not di^.opnds[k].h.read then
          if (di^.opnds[k].link <> nil) or di^.opnds[k].lts^.f2.final then begin
            ok := false;
            exit;
          end;
    if ok then
      utils_$excise_instruction_cleanly(di, true);
  end;
  n := lir_$optimizer_new_instruction(a, ord(opc$loadl), false);
  n^.opnds[1].h.num := 1;
  n^.opnds[1].h.kind := operand$immediate;
  n^.opnds[1].value := ac^.l16;
  n^.opnds[1].link := opnd_ptr_t(ac);
  opnd_bytes_ptr_t(addr(n^.opnds[1]))^.rrp := 16;
  n^.opnds[2].h.num := 2;
  n^.opnds[2].h.kind := operand$ip_reg;
  opnd_bytes_ptr_t(addr(n^.opnds[2]))^.rrp := 16;
  n^.opnds[2].lts := db;
  if db^.refs = nil then
    db^.refs := addr(n^.opnds[2])
  else begin
    n^.opnds[2].link := db^.refs^.link;
    db^.refs^.link := addr(n^.opnds[2]);
  end;
  n^.opnds[3].h.num := 3;
  n^.opnds[3].h.kind := operand$ip_reg;
  opnd_bytes_ptr_t(addr(n^.opnds[3]))^.rrp := 8;
  lir_utils_$add_lts_to_lr(24, lir_$new_live_range_ip_reg, a^.bb, l);
  n^.opnds[3].lts := l;
  l^.refs := addr(n^.opnds[3]);
  n^.opnds[3].link := o1;
  a^.opnds[1].link := nil;
  a^.opnds[1].lts := l;
8:
  for k := 1 to b^.h.nopnds do
    if b^.opnds[k].h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if b^.opnds[k].h.write then begin
        if b^.opnds[k].link <> nil then
          bug_check('COM_$call_cossin -- consumed operand remains on dying instruction%$');
        utils_$excise_lts_cleanly(b^.opnds[k].lts, false);
      end;
  utils_$excise_instruction_cleanly(b, true);
end;

{ safe_cc_write - a condition code result o may be taken over by another
  instruction's: it writes, and its segment, when not final, has no
  reader (then exposed false) or a single trap's (trap true, exposed
  false); true also when its segment is the last of its block.  exposed
  starts true, trap false.  0x22AEFC, 0xB4 bytes, no A5. }

function safe_cc_write(
    o: opnd_ptr_t;
    var exposed: boolean;
    var trap: boolean): boolean; options(val_param); internal;
var
  s: lts_ptr_t;
begin
  trap := false;
  exposed := true;
  if not (o^.h.kind in [operand$ip_condition_codes, operand$fp_condition_codes])
      or ((opnd_bytes_ptr_t(o)^.rrp & 12) = 0) then begin
    safe_cc_write := false;
    return;
  end;
  if not o^.lts^.f2.final then begin
    if o^.link = nil then begin
      safe_cc_write := true;
      exposed := false;
      return;
    end;
    if o^.link^.link = nil then
      if instruction_attributes[utils_ins_$operands_instruction(o^.link)^.opc].class
          = class$trap_cond then begin
        trap := true;
        exposed := false;
        safe_cc_write := true;
        return;
      end;
  end;
  s := o^.lts;
  if (s^.next = nil) or (s^.bb <> s^.next^.bb) then
    safe_cc_write := true
  else
    safe_cc_write := false;
end;

{ operand_is_trapcc_input - o means to modify and is a conditional
  trap's.  0x22AFB0, 0x40 bytes, no A5. }

function operand_is_trapcc_input(
    o: opnd_ptr_t): boolean; options(val_param); internal;
var
  i: instr_ptr_t;
begin
  i := utils_ins_$operands_instruction(o);
  if o^.h.intend_to_modify then
    operand_is_trapcc_input := instruction_attributes[i^.opc].class
                               = class$trap_cond
  else
    operand_is_trapcc_input := false;
end;

{ destroy_instr - i, found the same as c, taken out: two calls of the
  sine/cosine routine computing different halves merged (call_cossin);
  else each result of i given to c's: a condition code result's trap
  (its intend_to_modify operands' segments merged with the modified
  ones') excised and the result's segment's readers moved to c's (made
  final), or the segment excised; a register or memory result's readers
  made to read c's (through the trap's operand 2 when c's result feeds a
  conditional trap).  0x22AFF0, 0x3F4 bytes, no A5: the live range
  whose marks are cleared read from a slot set only on one path (as the
  image does). }

procedure destroy_instr(
    c: instr_ptr_t;
    i: instr_ptr_t); options(val_param); internal;
var
  wc, wi: integer;
  k, j, m: integer32;
  oi, oc, p, q, r, x: opnd_ptr_t;
  exposed, trap, fin, w, ok, md: boolean;
  t: instr_ptr_t;
  s: lts_ptr_t;
  lr: lr_ptr_t;
begin
  if c^.opc = ord(opc$call) then begin
    wc := c^.h.width & 3;
    wi := i^.h.width & 3;
    if wc <> wi then
      if wc <> 0 then
        if wi in [1, 2] then begin
          call_cossin(c, i);
          com_hoisted := true;
          return;
        end;
  end;
  if com_level > 0 then
    vfmt_$write('Replacing instruction %3ZWD with result computed by instruction %3ZWD%.',
                i^.num, c^.num);
  for k := 1 to i^.h.nopnds do begin
    oi := addr(i^.opnds[k]);
    oc := addr(c^.opnds[k]);
    if com_level >= 6 then
      vfmt_$write('check operand %LD%.', k);
    if (opnd_bytes_ptr_t(oi)^.rrp & 12) <> 0 then
      if oi^.h.kind in [operand$ip_condition_codes,
                        operand$fp_condition_codes] then begin
        if not safe_cc_write(oi, exposed, trap) then
          bug_check('COM_$destroy_instr:  can''t handle CC write%$');
        if trap then begin
          t := utils_ins_$operands_instruction(oi^.link);
          for j := 1 to t^.h.nopnds do begin
            p := addr(t^.opnds[j]);
            if p^.h.intend_to_modify then begin
              for m := j + 1 to t^.h.nopnds do begin
                q := addr(t^.opnds[m]);
                if q^.h.modify then
                  if p^.lts^.lr = q^.lts^.lr then begin
                    if p^.lts^.rrp * [rrp$modify, rrp$write] <> [] then
                      utils_$move_definition(q^.lts, p^.lts, false)
                    else
                      utils_$move_definition(q^.lts, p^.lts^.l44, false);
                    r := q^.link;
                    while r <> nil do begin
                      r^.lts := p^.lts;
                      r := r^.link;
                    end;
                    x := p;
                    while x^.link <> nil do
                      x := x^.link;
                    x^.link := q^.link;
                    if not (rrp$intend_to_modify in q^.lts^.rrp) then
                      p^.lts^.rrp := p^.lts^.rrp - [rrp$intend_to_modify];
                    fin := q^.lts^.f2.final;
                    utils_$excise_lts_cleanly(q^.lts, false);
                    if fin then
                      utils_$put_lts_on_final_list(p^.lts);
                    q^.h.kind := operand$none;
                    opnd_bytes_ptr_t(q)^.rrp := 0;
                    exit;
                  end;
              end;
              w := false;
              ok := true;
              md := false;
              s := p^.lts^.lr^.ltss;
              while s <> nil do begin
                if rrp$modify in s^.rrp then begin
                  md := true;
                  ok := false;
                  exit;
                end;
                if rrp$write in s^.rrp then begin
                  if w then begin
                    ok := false;
                    exit;
                  end;
                  w := true;
                end;
                s := s^.next;
              end;
              if w and ok then begin
                lr := p^.lts^.lr;
                lr^.f2.b3_1 := true;
              end;
              if not md then
                lr^.rrp := lr^.rrp - [rrp$modify, rrp$intend_to_modify];
            end;
          end;
          utils_$excise_instruction_cleanly(t, true);
        end;
        if exposed then begin
          s := oi^.lts;
          s^.rrp := s^.rrp - [rrp$modify, rrp$write];
          s^.refs := s^.refs^.link;
          oc^.lts^.f2.final := true;
          utils_$move_definition(oi^.lts, oc^.lts, true);
          if oi^.lts^.refs <> nil then
            utils_$put_lts_on_exposed_list(oi^.lts)
          else
            utils_$excise_lts_cleanly(oi^.lts, true);
        end
        else if i^.h.b2_6 then
          utils_$excise_lts_cleanly(oi^.lts, true);
        oi^.h.kind := operand$none;
        opnd_bytes_ptr_t(oi)^.rrp := 0;
      end
      else if oi^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
        if c^.h.sets_cc and (oc^.link <> nil)
            and operand_is_trapcc_input(oc^.link) then begin
          t := utils_ins_$operands_instruction(oc^.link);
          com_$replace_oprs_value(addr(t^.opnds[2]), oi, i);
        end
        else
          com_$replace_oprs_value(oc, oi, i);
  end;
  if i^.opc = ord(opc$call) then
    com_hoisted := true;
  if i^.h.b2_6 then
    utils_$excise_instruction_cleanly(i, true);
end;

{ process_instruction - i looked up in the hash tables of its block and
  its dominators (tab, up to the block that defines one of its inputs:
  marked with this pass's serial number): an earlier instruction of the
  same opcode, size and operands (each input with the same canonical
  birthpoint, condition codes safe to take over, constants equal; a
  call's kind bits may differ) makes it redundant (destroy_instr), as
  long as one of its inputs is a read or every output may be shared.
  Else a load or store is tried for elimination, an instruction in a
  loop for hoisting (com_hoisted), and i entered in its (new) block's
  table.  Atomic, volatile, do_not_delete (com_saw_do_not_delete),
  modifying loads and stores, branch-like classes and operands other
  than registers, memory and constants are not looked up.  0x22B46C,
  0x888 bytes, no A5: the classes and kinds by jump tables; the inputs'
  birthpoints cached in a frame array (20 bytes apart, the operand
  numbers seen kept in a register as a set of 0..31). }

procedure process_instruction(
    i: instr_ptr_t;
    tab: com_tab_ptr_t); options(val_param); internal;
label
  20, 30, 40;
var
  hash: integer;
  phys, same, ok, exposed, trap, r: boolean;
  k, m, n, offset, lnum: integer32;
  seen: set of 0..31;
  o, a2, a3: opnd_ptr_t;
  bp, bp2: utils_$birthpoint_t;
  bps: array [0..31] of utils_$birthpoint_t;
  t: com_tab_ptr_t;
  e: com_entry_ptr_t;
  c: instr_ptr_t;
  lr: lr_ptr_t;
  ed: fg_edge_ptr_t;
  kind: operand$t;
begin
  if com_level >= 3 then
    vfmt_$write('Examining instruction %3ZWD%.', i^.num);
  case instruction_attributes[i^.opc].class of
    class$alu, class$call, class$fp_double, class$immediate,
    class$fp_control, class$load_pair, class$load, class$fp_single,
    class$pmove, class$store, class$mfpr, class$mtpr:
      ;
    otherwise begin
      if com_level >= 4 then
        vfmt_$write('Fail: wrong opcode%.');
      return;
    end;
  end;
  if i^.h.b0_7 or i^.h.b2_4 then begin
    if com_level >= 4 then
      vfmt_$write('Fail: atomic or volatile.%.');
    return;
  end;
  if i^.h.b2_3 then begin
    com_saw_do_not_delete := true;
    if com_level >= 4 then
      vfmt_$write('Fail: do_not_delete.%.');
    return;
  end;
  if instruction_attributes[i^.opc].class in [class$load, class$store] then
    if (cell_head_ptr_t(i)^.modify <> 0)
        or not (cell_head_ptr_t(i)^.lsq in [0, 3]) then begin
      if com_level >= 4 then
        vfmt_$write('Fail: address mode%.');
      return;
    end;
  hash := i^.opc & 63;
  phys := false;
  for k := 1 to i^.h.nopnds do begin
    if com_level >= 6 then
      vfmt_$write('check operand %LD%.', k);
    o := addr(i^.opnds[k]);
    if not (o^.h.kind in [operand$none..operand$fp_reg_pair,
                          operand$ip_condition_codes..operand$fp_reg_pair_like,
                          operand$displacement_routine..operand$immediate]) then begin
      if com_level >= 4 then
        vfmt_$write('Fail: wrong operand kind%.');
      return;
    end;
    if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical,
                     operand$argument_block_memory..operand$well_behaved_memory] then
      if o^.lts^.lr^.f2.physical then begin
        if com_level >= 4 then
          vfmt_$write('Warn: physical%.');
        phys := true;
      end;
    if o^.h.modify then
      goto 40;
  end;
  if at_backend_switches.sw11 then
    if i^.h.nopnds = 4 then
      if i^.opnds[2].h.kind = operand$ip_reg then
        if i^.opnds[1].h.read then
          if i^.opnds[1].h.kind = operand$immediate then
            if (i^.opc = ord(opc$add)) or (i^.opc = ord(opc$sub)) then begin
              if i^.opc = ord(opc$add) then
                offset := i^.opnds[1].value
              else
                offset := -i^.opnds[1].value;
              utils_$get_canonical_birthpoint(i^.opnds[2].lts, 7, bp2);
              if bp2.lts <> nil then
                if bp2.offset <> 0 then
                  if com_level >= 4 then begin
                    lnum := bp2.lts^.f2.num;
                    vfmt_$write('Found immediate sub %3ZWD, offset is %SLD, birth offset is %SLD, new LTS is %3ZWD.%2ZLD%.',
                                i^.num, offset, bp2.offset, bp2.lts^.lr^.num,
                                lnum);
                  end;
            end;
  if phys then
    if (i^.opc <> ord(opc$call)) or ((i^.h.width & 8) <> 0) then
      return;
  if com_level >= 4 then
    vfmt_$write('Really examining instruction %3ZWD%.', i^.num);
  com_rtn^.marks := com_rtn^.marks + 1;
  n := com_rtn^.marks;
  seen := [];
  t := tab;
  repeat
    e := t^.buckets[hash];
    while e <> nil do begin
      c := e^.instr;
      if c^.h.b2_6 then begin
        if com_level >= 5 then
          vfmt_$write('Comparing against instruction %3ZWD in BB %3ZWD%.',
                      c^.num, t^.bb^.num);
        if (c^.h.nopnds <> i^.h.nopnds) or (c^.opc <> i^.opc) then
          goto 20;
        if c^.h.width <> i^.h.width then
          if c^.opc <> ord(opc$call) then
            goto 20;
        same := false;
        ok := true;
        for k := 1 to i^.h.nopnds do begin
          if com_level >= 6 then
            vfmt_$write('check operand %LD%.', k);
          a2 := addr(i^.opnds[k]);
          a3 := addr(c^.opnds[k]);
          kind := a2^.h.kind;
          if kind <> a3^.h.kind then begin
            if not a3^.h.write then
              goto 20;
            if kind <> operand$none then
              goto 20;
            if not (a3^.h.kind in [operand$ip_condition_codes,
                                   operand$fp_condition_codes]) then
              goto 20;
          end
          else begin
            if a2^.h.count <> a3^.h.count then
              goto 20;
            if opnd_bytes_ptr_t(a2)^.rrp <> opnd_bytes_ptr_t(a3)^.rrp then
              goto 20;
          end;
          case kind of
            operand$none:
              ;
            operand$ip_reg, operand$fp_reg, operand$fp_reg_pair,
            operand$ip_condition_codes, operand$fp_condition_codes,
            operand$inscrutable_memory, operand$well_behaved_memory:
              if a2^.h.read then begin
                same := true;
                if com_level >= 6 then begin
                  lnum := a2^.lts^.f2.num;
                  vfmt_$write('Checking operand %LD of inst, LTS is %3ZWD.%2ZLD%.',
                              k, a2^.lts^.lr^.num, lnum);
                end;
                if (k <= 31) and (k in seen) then
                  m := k
                else begin
                  if k > 31 then
                    m := 0
                  else begin
                    m := k;
                    seen := seen + [k];
                  end;
                  utils_$get_canonical_birthpoint(a2^.lts, 3, bps[m]);
                  if not bps[m].has_base then
                    if bps[m].lts <> nil then
                      bps[m].lts^.bb^.mark146 := n;
                end;
                if com_level >= 6 then begin
                  lnum := a3^.lts^.f2.num;
                  vfmt_$write('Checking operand %LD of tto, LTS is %3ZWD.%2ZLD%.',
                              k, a3^.lts^.lr^.num, lnum);
                end;
                utils_$get_canonical_birthpoint(a3^.lts, 3, bp);
                if not utils_$compare_birthpoints(bps[m], bp) then begin
                  if i^.bb <> c^.bb then
                    goto 20;
                  if k <> 1 then
                    goto 20;
                  if i^.opc <> ord(opc$call) then
                    goto 20;
                  if (i^.h.width & 3) = (c^.h.width & 3) then
                    goto 20;
                  if not ((i^.h.width & 3) in [1, 2]) then
                    goto 20;
                  if (c^.h.width & 3) = 0 then
                    goto 20;
                end;
              end
              else if kind in [operand$ip_condition_codes,
                               operand$fp_condition_codes] then begin
                if not safe_cc_write(a2, exposed, trap) then
                  goto 20;
                if trap then begin
                  if not safe_cc_write(a3, exposed, trap) then
                    goto 20;
                  if not trap then
                    goto 20;
                end
                else if exposed then begin
                  ed := i^.bb^.preds;
                  if ed = nil then
                    goto 20;
                  if ed^.next_pred <> nil then
                    goto 20;
                  if ed^.source <> t^.bb then
                    goto 20;
                  if not a3^.lts^.f2.first_in_bb then
                    goto 20;
                end;
              end
              else begin
                if kind in [operand$fp_reg, operand$fp_reg_physical,
                            operand$fp_reg_like] then
                  if a2^.lts^.lr^.mate <> nil then
                    if not a2^.lts^.lr^.f2.physical then
                      goto 20;
                if a2^.lts^.f2.final
                    or (rrp$intend_to_modify in a2^.lts^.rrp) then
                  ok := false;
              end;
            operand$ip_reg_like, operand$fp_reg_like, operand$fp_reg_pair_like:
              if a2^.lts <> a3^.lts then
                goto 20;
            operand$displacement_routine, operand$displacement_arg_block,
            operand$displacement_stack_frame, operand$displacement_XSB_base:
              if (a2^.link <> a3^.link) or (a2^.value <> a3^.value) then
                goto 20;
            operand$displacement_literal_pool: begin
              if a2^.value <> a3^.value then
                goto 20;
              if (opnd_bytes_ptr_t(a2)^.b3 & 16#E0)
                  <> (opnd_bytes_ptr_t(a3)^.b3 & 16#E0) then
                goto 20;
              if com_int_ptr_t(a2^.link)^ <> com_int_ptr_t(a3^.link)^ then
                goto 20;
            end;
            operand$immediate: begin
              if a2^.value <> a3^.value then
                goto 20;
              if a2^.value = 0 then
                ok := false;
              if c^.opc = ord(opc$move) then
                if c^.opnds[2].h.kind = operand$ip_reg then begin
                  lr := c^.opnds[2].lts^.lr;
                  if (rrp$modify in lr^.rrp) or lr^.f2.physical then
                    ok := false
                  else if lr^.id <> 0 then
                    if not lr^.f2.b3_1 then
                      ok := false;
                end;
            end;
            otherwise
              goto 20;
          end;
        end;
        if not (ok or same) then
          return;
        destroy_instr(c, i);
        return;
      end;
  20: e := e^.next;
    end;
    if t^.bb^.mark146 = n then
      goto 40;
    t := t^.parent;
  until t = nil;
40:
  if instruction_attributes[i^.opc].class = class$load then
    r := attempt_load_elimination(i)
  else if instruction_attributes[i^.opc].class = class$store then
    r := attempt_store_elimination(i, true)
  else
    goto 30;
  if r then
    return;
30:
  t := tab;
  if i^.bb^.f.b16 <> 0 then
    if maybe_hoist_instr_from_loop(i) then begin
      com_hoisted := true;
      t := tab;
      while t <> nil do begin
        if t^.bb = i^.bb then
          exit;
        t := t^.parent;
      end;
      if t = nil then
        return;
    end;
  e := mrh_$alloc_fixed(com_heap);
  e^.instr := i;
  e^.next := t^.buckets[hash];
  t^.buckets[hash] := e;
end;

{ optimize_block - bb's instructions processed against its hash table
  (cleared; parent the table of its immediate dominator) unless the
  block has +17 bit 6, then its children in the dominator tree (l46,
  chained at l50).  0x22BEAA, 0xD6 bytes, no A5: recursive; the
  table's address hoisted into a frame slot; the buckets cleared by
  `move.l #0' (pattern 82). }

procedure optimize_block(
    bb: bb_ptr_t;
    parent: com_tab_ptr_t); options(val_param); internal;
var
  tab: com_tab_t;
  k: integer32;
  i, nx: instr_ptr_t;
  b: bb_ptr_t;
begin
  if com_level >= 2 then
    vfmt_$write('Scanning BB %3ZWD%.', bb^.num);
  tab.parent := parent;
  tab.bb := bb;
  for k := 0 to 63 do
    tab.buckets[k] := nil;
  if not bb^.f.b17_6 then begin
    i := bb^.first;
    while i <> nil do begin
      nx := i^.next;
      if i^.h.b2_6 then
        process_instruction(i, addr(tab));
      i := nx;
    end;
  end;
  if com_level >= 2 then
    vfmt_$write('Recursing down the dominator tree%.');
  b := bb^.l46;
  while b <> nil do begin
    optimize_block(b, addr(tab));
    b := b^.l50;
  end;
  if com_level >= 2 then
    vfmt_$write('End of scan of BB %3ZWD%.', bb^.num);
end;

{ com_$compute_cses - one pass of common subexpression elimination over
  rtn's dominator tree (from its first block) at the debug level, the
  hash tables in com_heap released afterwards; com_saw_do_not_delete and
  com_hoisted cleared first.  0x22BFD2, 0x58 bytes (iv calls it). }

procedure com_$compute_cses(
    rtn: rtn_ptr_t;
    level: integer32);
var
  m: mrh_$mark_t;
begin
  com_rtn := rtn;
  com_level := level;
  com_saw_do_not_delete := false;
  m := mrh_$mark(com_heap);
  com_hoisted := false;
  optimize_block(rtn^.bbs, nil);
  mrh_$release_to_mark(com_heap, m);
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

{ com_$process_routine - the COM phase: the routine's name and the
  debug level noted, the routine checked; unless switch 15 (with the
  debug switch 's' 15) the snuggle moves inserted and the segments'
  properties repaired (a dump with switch 3); unless switches 15 or 14:
  a first CSE pass, the instructions renumbered; unless switch 12 the
  antialiasing phase (unless switch 9 the memory model's analysis),
  the loops' memory analysis, and further passes while instructions are
  hoisted; the do_not_delete stores tried again; the global walk, the
  motions, the zero valued live ranges, LIFE and copy elimination, each
  with the level's messages and dumps.  0x22C082, 0x33A bytes: the
  pass number counted from 2 in a register, written by address. }

procedure com_$process_routine(
    rtn: rtn_ptr_t);
var
  pass: integer32;
begin
  com_rtn := rtn;
  discard(sym_$fully_qualified_routine_name(addr(com_name), com_rtn^.node, -1));
  com_level := at_backend_switches.level;
  lir_utils_$sanity_check(com_rtn);
  com_284 := 100;
  if not at_backend_switches.sw15 or (cargs_$debug_switches['s'] >= 0) then begin
    sched_utils_$insert_snuggle_moves(rtn);
    lir_utils_$repair_lts_properties(com_rtn);
    if at_backend_switches.sw3 then begin
      vfmt_$write('%/%/DUMP OF ROUTINE "%A" AFTER SNUGGLE MOVE INSERTION%/%.',
                  com_name.body, com_name.length);
      dmp_$whole_routine(rtn, at_backend_switches.sw5, false);
    end;
  end;
  if at_backend_switches.sw15 then
    return;
  if at_backend_switches.sw14 then
    return;
  if com_level > 0 then
    vfmt_$write('Enter common optimizer phase!!!!!!!!%.');
  com_$compute_cses(rtn, com_level);
  clean_up_this_mess_right_now_young_man(rtn);
  if not at_backend_switches.sw12 then begin
    if com_level >= 4 then begin
      vfmt_$write('%/%/DUMP OF ROUTINE "%A" AFTER FIRST CSE PASS%/%.',
                  com_name.body, com_name.length);
      dmp_$whole_routine(rtn, at_backend_switches.sw5, true);
    end;
    if com_level > 0 then
      vfmt_$write('Enter common optimizer antialiasing phase!!!!!!!!%.');
    if not at_backend_switches.sw9 then begin
      if com_level > 0 then
        vfmt_$write('Enter antialiasing MMT analysis!!%.');
      mmt_utils_$analyze_blocks(rtn, com_level);
      if com_level > 0 then
        vfmt_$write('End of antialiasing MMT analysis!!%.');
      if com_level >= 4 then begin
        vfmt_$write('%/%/DUMP OF ROUTINE "%A" AFTER MMT ANTIALIAS ANALYSIS%/%.',
                    com_name.body, com_name.length);
        dmp_$whole_routine(rtn, at_backend_switches.sw5, true);
      end;
    end;
    loop_memory_analysis;
    if com_level > 0 then
      vfmt_$write('End of common optimizer antialiasing phase!!!!!!!!%.');
    if com_level >= 4 then begin
      vfmt_$write('%/%/DUMP OF ROUTINE "%A" AFTER FIRST LOOP MEMORY ANALYSIS%/%.',
                  com_name.body, com_name.length);
      dmp_$whole_routine(rtn, at_backend_switches.sw5, true);
    end;
    pass := 2;
    repeat
      if com_level > 0 then
        vfmt_$write('Enter common optimizer pass %d!!!!!!!!%.', pass);
      com_$compute_cses(rtn, com_level);
      loop_memory_analysis;
      pass := pass + 1;
    until not com_hoisted;
  end;
  if com_saw_do_not_delete then
    attempt_do_not_delete_removal;
  if com_level >= 4 then begin
    vfmt_$write('%/%/DUMP OF ROUTINE "%A" BEFORE DF_UTILS:GLOBAL_WALK%/%.',
                com_name.body, com_name.length);
    dmp_$whole_routine(rtn, at_backend_switches.sw5, true);
  end;
  df_utils_$global_walk(rtn, rtn^.l192, 1, com_level);
  if com_level >= 4 then begin
    vfmt_$write('%/%/DUMP OF ROUTINE "%A" AFTER DF_UTILS:GLOBAL_WALK%/%.',
                com_name.body, com_name.length);
    dmp_$whole_routine(rtn, at_backend_switches.sw5, true);
  end;
  lir_utils_$sanity_check(com_rtn);
  trans_$alpha_motions(rtn);
  trans_$omega_motions(rtn);
  replace_zero_valued_lrs;
  life_$process_routine(rtn);
  trans_$copy_elimination(rtn);
  if com_level > 0 then
    vfmt_$write('End of common optimizer phase!!!!!!!!%.');
end;
