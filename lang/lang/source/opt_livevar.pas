{ opt_livevar - the optimizer's live variables and dead stores: the
  def-use chains of each region statement's variables (build_du_chains,
  from the use-def chains opt_reachdef leaves), the removal of
  assignments whose value no statement uses (assign_elim, repeated
  until nothing more goes: the store becomes an evaluation of its
  right side when that has effects, else it is unlinked, its chains
  cut by elim_chains and the removal reported unless the variable is
  a parameter's copy or a temporary), then for each block and statement
  the registers free over it and the variables' uses (varcheck), each
  block's sets of used, not assigned and live variables (buildsets,
  lvanalyze), the warning for a for loop's index used after the loop
  (for_check), the marking of the variables live into the routine's
  entry blocks, and the cse parents left with one use put back
  (remove_bad_parents).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0D6A8C  0x2A3C7C  opt_livevar_$find_nearest_spos_node
    0x0D6AC2  0x2A3CB2  opt_livevar_$formal_value_param_copy
    0x0D6B10  0x2A3D00  opt_livevar_$store_to_stack_temp
    0x0D6B46  0x2A3D36  opt_livevar_$report_removal
    0x0D6BA6  0x2A3D96  bad_parent
    0x0D6BD0  0x2A3DC0  ensure_parental_correctness
    0x0D6C08  0x2A3DF8  pwalk
    0x0D6D1E  0x2A3F0E  remove_bad_parents
    0x0D6E24  0x2A4014  check_cse_uses
    0x0D6ED0  0x2A40C0  build_du_chains
    0x0D70BA  0x2A42AA  elim_chains
    0x0D71BC  0x2A43AC  stmtwalk
    0x0D7302  0x2A44F2  assign_elim
    0x0D7A2C  0x2A4C1C  addvaruse
    0x0D7ACE  0x2A4CBE  varcheck
    0x0D7E8A  0x2A507A  buildsets
    0x0D80AE  0x2A529E  lvanalyze
    0x0D8240  0x2A5430  for_check
    0x0D83AE  0x2A559E  liveanalysis
    A5 0x2D2ED8 (cc.m68k), 0x493884 (cc.a88k): the module's data, 8
    bytes (opt_general, before it, has none): +0..+3 not addressed,
    +4 the region whose statement varcheck charges (a word), +6 a
    word liveanalysis sets and nothing reads.

  check_cse_uses, build_du_chains, elim_chains, assign_elim, varcheck
  and liveanalysis load A5 (liveanalysis is global, g_opt.ins.pas; the
  others only this unit calls); the other routines do not and are
  internal (find_nearest_spos_node, store_to_stack_temp and bad_parent
  leaf routines without a frame, docs/rev889-patterns.md 16).

  The statements of a region are opt_4009c's entries
  (g_opt.ins.pas's g_opt_stmt_t: vars, regs, vset and hdr), trees are
  read through g_opt_tree_t and the other nodes by offset (il.ins.pas).
  reg_save (reg_save.pas, cg.ins.pas, which this unit does not open)
  is declared here.

  dpc gaps (docs/dpc-gaps.md): 2 (sparse cases on the node kinds), 8
  (`in' on the node kind sets).
}
module opt_livevar;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';

{ REG_SAVE - reg_save.pas 0x0ED478 (cc.a88k 0x2BA668): the registers
  a call of r preserves, as cg.ins.pas declares it. }
function reg_save(
    r: il_$node_ptr_t): integer32; options(val_param); extern;

type
  lv_head_t = array [1..21] of integer;  { a statement's +4..+45 }
  lv_head_ptr_t = ^lv_head_t;

var
  unused_0: integer32;                  { +0 }
  cur: g_opt_num_t;                     { +4: the region of the
                                          statement varcheck charges }
  depth: integer;                       { +6 }

define
  liveanalysis;

{ opt_livevar_$find_nearest_spos_node - s, or when s has no source
  line (spos_$null_position) the nearest statement from start back
  that has one and is not marked b7 (the first statement when none).

  0x0D6A8C, 0x36 bytes, no frame: s at (4,SP), start at (8,SP); the
  result in A0. }

function opt_livevar_$find_nearest_spos_node(
    s: g_opt_stmt_ptr_t;
    start: g_opt_stmt_ptr_t): g_opt_stmt_ptr_t; options(val_param); internal;
var
  p: g_opt_stmt_ptr_t;
begin
  p := s;
  if s^.line = spos_$null_position then begin
    p := start;
    while (p^.prev <> nil) and
          ((p^.line = spos_$null_position) or p^.hdr.b7) do
      p := p^.prev;
  end;
  opt_livevar_$find_nearest_spos_node := p;
end;

{ opt_livevar_$formal_value_param_copy - s stores a value parameter
  into its copy: its left side a variable (109) whose +28 is a
  parameter (121), its right side the contents (146) of a variable of
  storage class 5.

  0x0D6AC2, 0x4E bytes: the result in D0 from `clr.b', `st'. }

function opt_livevar_$formal_value_param_copy(
    s: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
var
  v: il_$node_ptr_t;
begin
  opt_livevar_$formal_value_param_copy := false;
  if s^.asg_lhs^.kind = 109 then
    if s^.asg_lhs^.xp[7]^.kind = 121 then
      if s^.asg_rhs^.kind = 146 then begin
        v := s^.asg_rhs^.xp[6];
        if v^.kind = 109 then
          if v^.xw[36] = 5 then
            opt_livevar_$formal_value_param_copy := true;
      end;
end;

{ opt_livevar_$store_to_stack_temp - s stores into a variable marked
  as a stack temporary (bit 14 of a 109's word at +34, of a 110's at
  +26).

  0x0D6B10, 0x36 bytes, no frame: the result in D0. }

function opt_livevar_$store_to_stack_temp(
    s: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
var
  v: il_$node_ptr_t;
begin
  v := s^.asg_lhs;
  opt_livevar_$store_to_stack_temp := false;
  if (v^.kind = 109) and ((v^.xw[17] & 16#4000) <> 0) then
    opt_livevar_$store_to_stack_temp := true
  else if (v^.kind = 110) and ((v^.xw[13] & 16#4000) <> 0) then
    opt_livevar_$store_to_stack_temp := true;
end;

{ opt_livevar_$report_removal - the warning (cgerr 29) that the
  assignment s was removed, at the nearest statement with a source
  line, unless s is marked b7 or b5 or stores a parameter's copy or a
  temporary.

  0x0D6B46, 0x60 bytes: b7 and b5 tested together (`and.l #0xFFFF00'
  of the longword at +40, `lsr.l #8', `andi.w #0xA000'). }

procedure opt_livevar_$report_removal(
    s: g_opt_stmt_ptr_t;
    start: g_opt_stmt_ptr_t); options(val_param); internal;
var
  p: g_opt_stmt_ptr_t;
begin
  if not (s^.hdr.b7 or s^.hdr.b5) then
    if not opt_livevar_$formal_value_param_copy(s) then
      if not opt_livevar_$store_to_stack_temp(s) then begin
        p := opt_livevar_$find_nearest_spos_node(s, start);
        cgerr(29, p^.line, s^.asg_lhs);
      end;
end;

{ bad_parent - p is a cse parent (190) whose tree is used at most once
  and that has no uses left.

  0x0D6BA6, 0x2A bytes, no frame: the result in D0. }

function bad_parent(
    p: g_opt_cse_ptr_t): boolean; options(val_param); internal;
begin
  bad_parent := false;
  if p <> nil then
    if p^.kind = 190 then
      if g_opt_tree_ptr_t(p^.p_tree)^.uses <= 1 then
        if p^.p_uses = nil then
          bad_parent := true;
end;

{ ensure_parental_correctness - a bad parent t is replaced by its tree,
  in t and in il_120.

  0x0D6BD0, 0x38 bytes: t by address. }

procedure ensure_parental_correctness(
    var t: il_$node_ptr_t); internal;
begin
  if bad_parent(g_opt_cse_ptr_t(t)) then begin
    g_opt_nodes_ptr_t(il_120)^[g_opt_cse_ptr_t(t)^.p_num] :=
      g_opt_cse_ptr_t(t)^.p_tree;
    t := g_opt_cse_ptr_t(t)^.p_tree;
  end;
end;

{ pwalk - put back the bad parents among the operands of tree t (a
  parent's own tree is walked; a use is left).

  0x0D6C08, 0x116 bytes: recursive; the kinds compared in turn; 175
  and 171 separate copies. }

procedure pwalk(
    t: il_$node_ptr_t); options(val_param); internal;
var
  k: integer;
begin
  if t^.kind <> 189 then begin
    if t^.kind = 190 then
      t := t^.xp[1];
    case t^.kind of
      137, 143:
        for k := 1 to g_opt_tree_ptr_t(t)^.count do begin
          pwalk(g_opt_tree_ptr_t(t)^.opnd[k]);
          ensure_parental_correctness(g_opt_tree_ptr_t(t)^.opnd[k]);
        end;
      147, 205, 146: begin
        pwalk(t^.xp[6]);
        ensure_parental_correctness(t^.xp[6]);
      end;
      175: begin
        pwalk(t^.xp[4]);
        ensure_parental_correctness(t^.xp[4]);
      end;
      145: begin
        pwalk(t^.xp[6]);
        pwalk(t^.xp[9]);
        ensure_parental_correctness(t^.xp[6]);
        ensure_parental_correctness(t^.xp[9]);
      end;
      164: begin
        pwalk(t^.xp[5]);
        pwalk(t^.xp[6]);
        ensure_parental_correctness(t^.xp[5]);
        ensure_parental_correctness(t^.xp[6]);
      end;
      171: begin
        pwalk(t^.xp[4]);
        ensure_parental_correctness(t^.xp[4]);
      end;
      otherwise
    end;
  end;
end;

{ remove_bad_parents - pwalk over the trees of every statement from the
  first block's first statement up to (not including) the last
  block's last one.

  0x0D6D1E, 0x106 bytes: the kinds compared in turn (140, 142, 139,
  151); il.pas's +0xC0 loaded and not used (docs/rev889-patterns.md
  70, 53). }

procedure remove_bad_parents; internal;
var
  s: g_opt_stmt_ptr_t;
  k: integer;
begin
  s := g_opt_blocks_ptr_t(il_11c)^[opt_first_block]^.first_stmt;
  repeat
    case s^.kind of
      140: begin
        pwalk(s^.asg_rhs);
        pwalk(s^.asg_lhs);
        if s^.asg_x <> nil then begin
          pwalk(s^.asg_x);
          ensure_parental_correctness(s^.asg_x);
        end;
        ensure_parental_correctness(s^.asg_rhs);
        ensure_parental_correctness(s^.asg_lhs);
      end;
      142: begin
        pwalk(s^.br_cond);
        ensure_parental_correctness(s^.br_cond);
      end;
      139:
        for k := 1 to s^.eval_count do begin
          pwalk(s^.eval_opnd[k]);
          ensure_parental_correctness(s^.eval_opnd[k]);
        end;
      151:
        if s^.x48 <> nil then begin
          pwalk(s^.x48);
          ensure_parental_correctness(s^.x48);
        end;
      otherwise
    end;
    s := s^.next;
  until s = g_opt_blocks_ptr_t(il_11c)^[opt_last_block]^.last_stmt;
end;

{ check_cse_uses - drop the cse parents made at statement r's entry
  whose uses are all in deleted statements or in evaluations of one
  integer constant (81), and clear the statement's no_prune when none
  is left.

  0x0D6E24, 0xAC bytes: r by address (a frame copy of assign_elim's
  region number); delparent given a frame copy of the parent. }

procedure check_cse_uses(
    in r: g_opt_num_t);
var
  p: g_opt_cse_ptr_t;
  u: g_opt_cse_ptr_t;
  us: g_opt_stmt_ptr_t;
  dead: boolean;
begin
  p := g_opt_cse_ptr_t(opt_4009c[r]^.cses);
  while p <> nil do begin
    u := p^.p_uses;
    dead := true;
    while u <> nil do begin
      us := u^.u_ent;
      if not us^.hdr.deleted then
        if not ((us^.kind = 139) and (us^.eval_count = 1) and
                (us^.eval_opnd[1]^.kind = 81)) then
          dead := false;
      u := u^.u_next;
    end;
    if dead then
      delparent(p);
    p := p^.p_next;
  end;
  if opt_4009c[r]^.cses = nil then
    opt_4009c[r]^.hdr.no_prune := false;
end;

{ build_du_chains - for each region statement r (from opt_region on, in
  block order, while the statement is in the block) and each variable
  k it uses (vset): every statement on k's use-def chain gets r on its
  def-use chain for k, once (cells from mem_$alloc of opt_main_18).

  0x0D6ED0, 0x1EA bytes, link #-72: r a word sign-extended and
  compared with runbackend_16 zero-extended (`bgt'); a region past
  runbackend_16 ends the routine; the variables counted with il_180's
  +290. }

procedure build_du_chains;
var
  r: integer;
  i: g_opt_num_t;
  b: g_opt_block_ptr_t;
  e: g_opt_stmt_ptr_t;
  d: g_opt_stmt_ptr_t;
  k: integer;
  c: g_opt_chain_ptr_t;
  p: g_opt_chain_ptr_t;
begin
  r := opt_region;
  for i := opt_first_block to opt_last_block do begin
    b := g_opt_blocks_ptr_t(il_11c)^[i];
    if r > runbackend_16 then
      exit;
    while (r <= runbackend_16) and
          (opt_4009c[r]^.block^.num = b^.num) do begin
      e := opt_4009c[r];
      if e^.vset <> nil then
        if e^.vset^ <> [] then
          for k := 1 to il_180^.xw[145] do
            if k in e^.vset^ then begin
              c := e^.vars^[k]^.ud;
              while c <> nil do begin
                d := c^.stmt;
                if d^.vars^[k]^.du = nil then begin
                  d^.vars^[k]^.du := mem_$alloc(opt_main_18, 8);
                  d^.vars^[k]^.du^.next := nil;
                  d^.vars^[k]^.du^.stmt := opt_4009c[r];
                end
                else begin
                  p := d^.vars^[k]^.du;
                  while (p^.next <> nil) and (opt_4009c[r] <> p^.stmt) do
                    p := p^.next;
                  if p <> nil then
                    if opt_4009c[r] <> p^.stmt then begin
                      p^.next := mem_$alloc(opt_main_18, 8);
                      p := p^.next;
                      p^.next := nil;
                      p^.stmt := opt_4009c[r];
                    end;
                end;
                c := c^.next;
              end;
            end;
      r := r + 1;
    end;
  end;
end;

{ elim_chains - statement s is gone: take it off the def-use chain, for
  each variable it uses, of every statement on its use-def chain, and
  mark that statement's entry (flags 16#100).

  0x0D70BA, 0x102 bytes: s by address; nothing for a routine of kind
  167; the variables counted with il_180's +290; the entry's flag set
  with `bset #0' of its byte at +16. }

procedure elim_chains(
    in s: g_opt_stmt_ptr_t);
var
  k: integer;
  c: g_opt_chain_ptr_t;
  d: g_opt_stmt_ptr_t;
  p: g_opt_chain_ptr_t;
  q: g_opt_chain_ptr_t;
begin
  if il_180^.kind <> 167 then
    for k := 1 to il_180^.xw[145] do
      if s^.vset <> nil then
        if k in s^.vset^ then begin
          c := s^.vars^[k]^.ud;
          while c <> nil do begin
            d := c^.stmt;
            q := d^.vars^[k]^.du;
            p := q;
            while p <> nil do begin
              if p^.stmt = s then begin
                if (p^.next = nil) and (d^.vars^[k]^.du = p) then
                  d^.vars^[k]^.du := nil
                else if (p^.next <> nil) and (d^.vars^[k]^.du = p) then
                  d^.vars^[k]^.du := d^.vars^[k]^.du^.next
                else
                  q^.next := p^.next;
                d^.vars^[k]^.flags := d^.vars^[k]^.flags ! 16#100;
                exit;
              end;
              q := p;
              p := p^.next;
            end;
            c := c^.next;
          end;
        end;
end;

{ stmtwalk - the nodes of tree t owned by statement old (its trees'
  owner, a parent's statement, a use's entry) are given to new.

  0x0D71BC, 0x12C bytes: recursive; the owner replaced for the kinds
  of the 26-byte set after the routine (137, 138, 143, 145..147, 164,
  171, 175, 189, 205); then the kinds compared in turn. }

procedure stmtwalk(
    t: il_$node_ptr_t;
    new: g_opt_stmt_ptr_t;
    old: g_opt_stmt_ptr_t); options(val_param); internal;
var
  k: integer;
begin
  if t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    if g_opt_tree_ptr_t(t)^.owner = old then
      g_opt_tree_ptr_t(t)^.owner := new;
  case t^.kind of
    143, 137:
      for k := 1 to g_opt_tree_ptr_t(t)^.count do
        stmtwalk(g_opt_tree_ptr_t(t)^.opnd[k], new, old);
    205, 146, 147:
      stmtwalk(t^.xp[6], new, old);
    145: begin
      stmtwalk(t^.xp[6], new, old);
      stmtwalk(t^.xp[9], new, old);
    end;
    164: begin
      stmtwalk(t^.xp[5], new, old);
      stmtwalk(t^.xp[6], new, old);
    end;
    175:
      stmtwalk(t^.xp[4], new, old);
    171:
      stmtwalk(t^.xp[4], new, old);
    190: begin
      if g_opt_cse_ptr_t(t)^.p_stmt = old then
        g_opt_cse_ptr_t(t)^.p_stmt := new;
      stmtwalk(t^.xp[1], new, old);
    end;
    189:
      if g_opt_cse_ptr_t(t)^.u_ent = old then
        g_opt_cse_ptr_t(t)^.u_ent := new;
    otherwise
  end;
end;

{ assign_elim - one pass of dead store removal over the blocks in
  depth-first order from the last, each block's region statements from
  the last: an assignment (140, not of operators 27..30) of variable
  v that no statement uses (du nil; a store in a loop whose only use
  is itself, with a right side of no effects, counts as unused) is
  removed unless the variable may be seen elsewhere (storage classes
  5, 1, 3, 4, 7, 8, 10, 11 outside a routine of kind 105, addresses
  taken, a C routine's store of a constant to its result variable,
  ...); a 188 with no use loses its variable.  A removed store whose
  right side has effects (phase 1, 2 or 12), or that is its block's
  only statement or keeps cses, becomes an evaluation (139) of its
  right side (a conversion, op 17, for phases 1 and 2; an evaluation
  of 0 for a lone store of no effects) put in its place; else it is
  unlinked, its block's first or last statement moved to its
  neighbour.  The result is true when nothing was unlinked or emptied
  (another pass is not needed).

  0x0D7302, 0x72A bytes, link #-60: the blocks' and regions' loops
  counted down (`dbf'); the region found from the first statement
  backwards (except for block 1) and from the last forwards; the
  operator test `btst' on 0x78000000; the phases' test `andi.l
  #0x1006'; the 42 bytes +4..+45 of the store copied to the
  evaluation (ten `move.l' pairs and a `move.w'); hdr's flags set to
  deleted alone with `andi.l #0xFF0000FF; or.l #0x10000' of the
  longword at +40, and first or last of the neighbour's entry set as
  a word (`or.w #2', `or.w #8').  report_removal is passed s and
  opt_4009c[r], the same statement.

  Not known from the original:
  - how the flags were written (a 16-bit set, perhaps; written here as
    the booleans of g_opt.ins.pas);
  - whether the neighbour searches were loops of this form. }

function assign_elim: boolean;
var
  i: g_opt_num_t;
  bn: g_opt_num_t;
  b: g_opt_block_ptr_t;
  p: g_opt_stmt_ptr_t;
  first: integer;
  last: integer;
  r: integer;
  s: g_opt_stmt_ptr_t;
  t: g_opt_stmt_ptr_t;
  v: integer;
  vi: g_opt_var_ptr_t;
  n: il_$node_ptr_t;
  f: integer;
  k: integer;
  keep: boolean;
  ph: add_node_$phase_t;
  x: il_$node_ptr_t;
  rr: g_opt_num_t;
  nr: integer;
  done: boolean;
begin
  done := true;
  if opt_last_block >= opt_first_block then
    for i := opt_last_block downto opt_first_block do begin
      bn := opt_dfs_block^[i];
      b := g_opt_blocks_ptr_t(il_11c)^[bn];
      first := b^.first_stmt^.hdr.region;
      last := b^.last_stmt^.hdr.region;
      if (bn <> 1) and (first = 0) then begin
        p := b^.first_stmt;
        while p^.hdr.region = 0 do
          p := p^.prev;
        first := p^.hdr.region;
      end;
      if last = 0 then begin
        p := g_opt_blocks_ptr_t(il_11c)^[bn]^.last_stmt;
        while p^.hdr.region = 0 do
          p := p^.next;
        last := p^.hdr.region;
      end;
      for r := last downto first do begin
        s := opt_4009c[r];
        v := s^.hdr.vnum;
        if v = 0 then
          next;
        if s^.kind = 188 then
          if s^.vars^[v]^.du = nil then begin
            s^.hdr.vnum := 0;
            next;
          end;
        if s^.kind <> 140 then
          next;
        if s^.asg_op in [27..30] then
          next;
        vi := s^.vars^[v];
        if s^.vset <> nil then
          if v in s^.vset^ then
            if s^.vset^ <> [] then
              if s^.block^.depth <> 0 then
                if vi^.du <> nil then
                  if vi^.du^.next = nil then
                    if vi^.du^.stmt = opt_4009c[r] then
                      if getphase(s^.asg_rhs) * [1, 2, 12] = [] then
                        vi^.du := nil;
        if vi^.du <> nil then
          next;

        { Whether the variable may be seen elsewhere. }
        n := vi^.node;
        keep := false;
        if n^.kind = 109 then begin
          if n^.xw[36] = 5 then
            keep := true
          else if (n^.xl[8] & 16#201101) <> 0 then
            keep := true
          else begin
            if n^.xw[36] in [1, 3, 4, 7, 8, 10, 11] then
              if (il_180^.kind <> 105) or
                 ((ord(n^.xc[35]) & 16#40) <> 0) then
                keep := true;
            if not keep then
              if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 3 then
                if s^.asg_rhs^.kind = 81 then
                  if n^.xp[1] = il_180^.xp[74] then
                    keep := true;
          end;
        end
        else if n^.kind = 110 then begin
          if rshft(ord(n^.xc[44]) & 16#F0, 4) = 3 then begin
            f := rshft(ord(n^.xc[11]) & 16#F0, 4);
            if (f = 5) or ((n^.xl[6] & 16#201101) <> 0) or
               ((ord(n^.xc[44]) & 16#04) <> 0) then
              keep := true
            else if f in [1, 3, 4, 7, 8, 10, 11] then
              if (il_180^.kind <> 105) or
                 ((ord(n^.xc[44]) & 16#08) <> 0) then
                keep := true;
          end;
          if not keep then
            if s^.asg_rhs^.kind = 137 then
              if g_opt_tree_ptr_t(s^.asg_rhs)^.op = 26 then
                keep := true;
        end;
        if keep then
          next;

        { The store goes. }
        if (vi^.flags & 16#100) = 0 then
          opt_livevar_$report_removal(s, opt_4009c[r]);
        s^.hdr.vnum := 0;
        adjust_uc(s^.asg_lhs, -1);
        ph := getphase(s^.asg_rhs);
        if (ph * [1, 2, 12] <> []) or
           (s^.hdr.first and s^.hdr.last) or s^.hdr.no_prune then begin
          { An evaluation of the right side in its place. }
          x := s^.asg_rhs;
          if ph * [1, 2] <> [] then begin
            x := buildtreenode(17, s^.asg_desc, x, 1);
            g_opt_tree_ptr_t(x)^.owner := opt_4009c[r];
          end;
          t := gspace(56);
          t^.kind := 139;
          t^.eval_count := 1;
          t^.eval_opnd[1] := x;
          lv_head_ptr_t(addr(t^.prev))^ := lv_head_ptr_t(addr(opt_4009c[r]^.prev))^;
          t^.hdr.vnum := 0;
          if ph * [1, 2, 12] = [] then
            if s^.hdr.no_prune then begin
              rr := r;
              check_cse_uses(rr);
            end;
          if (ph * [1, 2, 12] = []) and s^.hdr.first and s^.hdr.last and
             not s^.hdr.no_prune then begin
            { A lone store of no effects: an evaluation of 0. }
            opt_4009c[r] := t;
            t^.prev^.next := t;
            t^.next^.prev := t;
            g_opt_nodes_ptr_t(il_120)^[s^.hdr.num] := il_$node_ptr_t(t);
            s^.block^.first_stmt := t;
            s^.block^.last_stmt := t;
            opt_4009c[r]^.eval_opnd[1] := smcontk(81, 0);
            if s^.vset <> nil then
              s^.vset^ := [];
          end
          else begin
            opt_4009c[r] := t;
            t^.prev^.next := t;
            t^.next^.prev := t;
            g_opt_nodes_ptr_t(il_120)^[s^.hdr.num] := il_$node_ptr_t(t);
            if s^.hdr.first then
              s^.block^.first_stmt := t;
            if s^.hdr.last then
              s^.block^.last_stmt := t;
            opt_4009c[r]^.eval_opnd[1] := x;
          end;
          if t <> nil then
            if t^.kind = 139 then begin
              stmtwalk(t^.eval_opnd[1], t, s);
              opt_gen_$prune_eval_operands(t);
              if t^.eval_opnd[1] <> nil then
                if t^.eval_opnd[1]^.kind = 81 then
                  if t^.eval_opnd[1]^.int_value = 0 then begin
                    with s^.hdr do begin
                      b7 := false; b6 := false; b5 := false; b4 := false;
                      b3 := false; counted := false; no_prune := false;
                      deleted := true;
                      b42_7 := false; b42_6 := false; kills := false;
                      b42_4 := false; last := false; b42_2 := false;
                      first := false; b42_0 := false;
                    end;
                    if s^.vset <> nil then
                      if s^.vset^ <> [] then begin
                        done := false;
                        elim_chains(s);
                      end;
                  end;
            end;
        end
        else begin
          { Unlinked. }
          adjust_uc(s^.asg_rhs, -1);
          if s^.hdr.first then begin
            nr := s^.next^.hdr.region;
            s^.hdr.first := false;
            if (nr = 0) and (s^.next^.kind = 140) and
               il_utils_$is_strength_reduction_temp(s^.next^.asg_lhs) then begin
              s^.block^.first_stmt := s^.next;
              s^.next^.hdr.first := true;
            end
            else begin
              opt_4009c[nr]^.hdr.first := true;
              s^.block^.first_stmt := opt_4009c[nr];
            end;
          end
          else if s^.hdr.last then begin
            nr := s^.prev^.hdr.region;
            s^.hdr.last := false;
            if (nr = 0) and (s^.prev^.kind = 140) and
               il_utils_$is_strength_reduction_temp(s^.prev^.asg_lhs) then
              s^.block^.last_stmt := s^.prev
            else begin
              opt_4009c[nr]^.hdr.last := true;
              s^.block^.last_stmt := opt_4009c[nr];
            end;
          end;
          if s^.vset <> nil then
            if s^.vset^ <> [] then begin
              done := false;
              elim_chains(opt_4009c[r]);
            end;
          s^.prev^.next := s^.next;
          s^.next^.prev := s^.prev;
          if s^.vset <> nil then
            s^.vset^ := [];
          with s^.hdr do begin
            b7 := false; b6 := false; b5 := false; b4 := false;
            b3 := false; counted := false; no_prune := false;
            deleted := true;
            b42_7 := false; b42_6 := false; kills := false;
            b42_4 := false; last := false; b42_2 := false;
            first := false; b42_0 := false;
          end;
        end;
      end;
    end;
  assign_elim := done;
end;

{ addvaruse - variable v is used (flags f, or-ed into its entries): in
  opt_region's table, and counted in the table of statement cur.

  0x0D7A2C, 0xA2 bytes: v and f words; nothing for v <= 0. }

procedure addvaruse(
    v: integer;
    f: integer); options(val_param); internal;
begin
  if v > 0 then begin
    opt_4009c[opt_region]^.vars^[v]^.flags :=
      opt_4009c[opt_region]^.vars^[v]^.flags ! f;
    if opt_4009c[cur]^.vars <> nil then
      if opt_4009c[cur]^.vars^[v] <> nil then
        with opt_4009c[cur]^.vars^[v]^ do begin
          flags := flags ! f;
          count := count + 1;
        end;
  end;
end;

{ varcheck - walk tree t of statement cur in block b: the registers a
  node does not preserve (reg_save) are taken from the block's and
  the statement's free registers (except below a shared node of
  another statement, a cse's own subtree marked 6 and trees no longer
  used); each variable reached is recorded as used with flags f (34
  an operand, 33/34 the two sides of a 145, 10 a 164's first, 8 under
  operator 26, ...), its constant (bit 17) added to the statement's
  block's constants.

  0x0D7ACE, 0x39A bytes, link #-24: all three by address (the callers
  pass a frame copy of the block and the flags as frame words or
  constants after the routine: 10, 34, 33, 8); the kinds of the
  26-byte sets after stmtwalk and after this routine; the operators
  compared in turn (26, 13). }

procedure varcheck(
    in t: il_$node_ptr_t;
    in b: g_opt_block_ptr_t;
    in f: integer);
var
  n: il_$node_ptr_t;
  bb: g_opt_block_ptr_t;
  ff: integer;
  rs: g_opt_regs_t;
  k: integer;
  v: integer;
  c: il_$node_ptr_t;
begin
  bb := b;
  n := t;
  ff := f;
  if n = nil then
    return;
  if n^.kind = 189 then
    return;
  if n^.kind = 190 then
    n := n^.xp[1];
  if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then begin
    if 6 in g_opt_tree_ptr_t(n)^.flags then
      return;
    if g_opt_tree_ptr_t(n)^.owner <> nil then
      if g_opt_tree_ptr_t(n)^.owner <> opt_4009c[cur] then
        if n^.kind = 137 then
          return;
    if n^.kind in [137, 138, 143, 145..147, 164, 189, 205] then
      if g_opt_tree_ptr_t(n)^.uses = 0 then
        return;
  end;
  rs := g_opt_regs_t(reg_save(n));
  bb^.regs := bb^.regs * rs;
  opt_4009c[cur]^.regs := opt_4009c[cur]^.regs * rs;
  case n^.kind of
    137, 143:
      case g_opt_tree_ptr_t(n)^.op of
        26:
          varcheck(g_opt_tree_ptr_t(n)^.opnd[1], bb, 8);
        13: begin
          varcheck(g_opt_tree_ptr_t(n)^.opnd[1], bb, 33);
          varcheck(g_opt_tree_ptr_t(n)^.opnd[2], bb, 34);
        end;
        otherwise
          for k := 1 to g_opt_tree_ptr_t(n)^.count do
            varcheck(g_opt_tree_ptr_t(n)^.opnd[k], bb, 34);
      end;
    147, 205: begin
      ff := ff ! 34;
      varcheck(n^.xp[6], bb, ff);
    end;
    164: begin
      varcheck(n^.xp[5], bb, 10);
      varcheck(n^.xp[6], bb, 34);
    end;
    146: begin
      ff := (ff & ~8) ! 33;
      varcheck(n^.xp[6], bb, ff);
    end;
    145: begin
      ff := ff & ~12;
      varcheck(n^.xp[6], bb, ff ! 33);
      varcheck(n^.xp[9], bb, ff ! 34);
    end;
    110: begin
      v := find_var(n);
      if rshft(ord(n^.xc[44]) & 16#F0, 4) = 3 then
        if 17 in g_opt_regs_t(n^.xl[6]) then begin
          c := n;
          add_constant(c, opt_4009c[cur]^.block);
        end;
      if v <> 0 then
        if rshft(ord(n^.xc[44]) & 16#F0, 4) <> 6 then
          addvaruse(v, ff);
    end;
    109: begin
      v := find_var(n);
      if 17 in g_opt_regs_t(n^.xl[8]) then begin
        c := n;
        add_constant(c, opt_4009c[cur]^.block);
      end;
      if v <> 0 then begin
        if (n^.xl[8] & 16#201001) <> 0 then
          if not odd(ff) then
            return;
        if (opt_4009c[opt_region]^.vars^[v]^.flags & 4) <> 0 then
          ff := ff ! 4;
        if n^.xw[36] = 5 then
          ff := ff ! 1;
        addvaruse(v, ff);
      end;
    end;
    otherwise
  end;
end;

{ buildsets - each block's used variables (opt_used: used by a
  statement before any assignment in the block) and not assigned
  (opt_not_killed: neither assigned nor, for statements marked kills,
  a variable whose address may be taken), its live set cleared; the
  region statements walked from opt_region in block order.

  0x0D7E8A, 0x224 bytes, link #-248: a 32-byte frame set for each
  single element added or removed; the first statement of each block
  is reached without the test against runbackend_16 (`bra' into the
  loop's block test). }

procedure buildsets; internal;
var
  r: integer;
  k: g_opt_num_t;
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  v: integer;
  n: il_$node_ptr_t;
begin
  r := opt_region;
  for k := opt_first_block to opt_last_block do begin
    b := g_opt_blocks_ptr_t(il_11c)^[k];
    opt_used^[k] := [];
    opt_not_killed^[k] := [0..255];
    opt_live_out^[k] := [];
    while opt_4009c[r]^.block^.num = b^.num do begin
      s := opt_4009c[r];
      for v := 1 to il_180^.xw[145] do begin
        if s^.vset <> nil then
          if v in s^.vset^ then
            if v in opt_not_killed^[k] then
              opt_used^[k] := opt_used^[k] + [v];
        if s^.hdr.vnum = v then
          opt_not_killed^[k] := opt_not_killed^[k] - [v];
        if s^.hdr.kills then begin
          n := opt_4009c[opt_region]^.vars^[v]^.node;
          if n^.kind = 109 then
            if (n^.xl[8] & 16#201101) <> 0 then
              opt_not_killed^[k] := opt_not_killed^[k] - [v];
        end;
      end;
      r := r + 1;
      if r > runbackend_16 then
        exit;
    end;
  end;
end;

{ lvanalyze - the variables live at each block's exit (opt_live_out):
  the union over its successors of what they use and what is live
  through them, repeated over the blocks in reverse depth-first order
  until nothing changes; in a C routine (il_180's +377 bits 6..4 = 2)
  everything is live at a block ending in a 150.

  0x0D80AE, 0x192 bytes, link #-280: the depth-first numbers counted
  down to opt_first_block - 1 (compared as longwords, no test before
  the first); the union formed in two frame sets. }

procedure lvanalyze; internal;
var
  is_c: boolean;
  stable: boolean;
  i: g_opt_num_t;
  bn: g_opt_num_t;
  b: g_opt_block_ptr_t;
  j: integer;
  sn: g_opt_num_t;
  live: g_opt_varset_t;
begin
  is_c := rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2;
  repeat
    stable := true;
    i := opt_last_block;
    repeat
      bn := opt_dfs_block^[i];
      b := g_opt_blocks_ptr_t(il_11c)^[bn];
      if is_c and (b^.last_stmt^.kind = 150) then
        live := [0..255]
      else begin
        live := [];
        for j := 1 to b^.nsucc do begin
          sn := b^.succ^[j]^.num;
          live := live + (opt_live_out^[sn] * opt_not_killed^[sn]) +
                  opt_used^[sn];
        end;
      end;
      if live <> opt_live_out^[bn] then begin
        opt_live_out^[bn] := live;
        stable := false;
      end;
      i := i - 1;
    until i = opt_first_block - 1;
  until stable;
end;

{ for_check - the warning (cgerr 18) that the index of the for loop
  headed by block h is used after the loop: the assignment marked b6
  before the header (in the block two before it) whose variable is
  live into the one block the loop leaves to.

  0x0D8240, 0x16E bytes, link #-44: h a word; select_loop called
  before the test of the assignment's block; the exits counted by the
  serial select_loop gave the loop's blocks; the line from the nearest
  statement with one (spos_$null_position's address in A0). }

procedure for_check(
    h: g_opt_num_t); options(val_param); internal;
var
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  lhs: il_$node_ptr_t;
  v: integer;
  l: g_opt_block_ptr_t;
  ser: integer;
  nexits: integer;
  nlive: integer;
  j: integer;
  x: g_opt_block_ptr_t;
begin
  b := g_opt_blocks_ptr_t(il_11c)^[h];
  s := b^.first_stmt;
  repeat
    s := s^.prev;
    if s = opt_4009c[opt_region] then
      return;
    if s = nil then
      return;
  until (s^.kind = 140) and s^.hdr.b6;
  lhs := s^.asg_lhs;
  v := s^.hdr.vnum;
  if v <= 0 then
    return;
  l := select_loop(h);
  ser := b^.serial;
  if h <> s^.block^.num + 2 then
    return;
  nexits := 0;
  nlive := 0;
  while l <> nil do begin
    for j := 1 to l^.nsucc do begin
      x := l^.succ^[j];
      if ser <> x^.serial then begin
        nexits := nexits + 1;
        if (v in opt_used^[x^.num]) or
           ((v in opt_live_out^[x^.num]) and
            (v in opt_not_killed^[x^.num])) then
          nlive := nlive + 1;
      end;
    end;
    l := l^.link;
  end;
  if (nexits = 1) and (nlive <> 0) then begin
    while s^.line = spos_$null_position do
      s := s^.prev;
    cgerr(18, s^.line, lhs);
  end;
end;

{ liveanalysis - see the unit's comment.  The per-block sets are
  cleared; under opt_on 12 or 13 (cargs +0x282 bits 5, 6) the chains
  are built and assign_elim repeated until it reports nothing more
  to do; the first block loses its skip mark; each statement of each
  block (in the region of its own number, or of the nearest statement
  before it (a latch block) or after it that has one; a label of no
  region charges region 0) is walked by varcheck and its variable's
  count taken off once; when the routine has variables, the sets are
  built and solved, the for loops checked (opt_on 11, in a routine
  whose +377 bits 6..4 are 1 or 6, at a header starting with a label
  of class 8), and the variables live into a block marked b7 or skip
  marked as such (+33 bit 5 of a 109, +25 bit 5 of a 110); then the
  bad cse parents are put back.

  0x0D83AE, 0x5B2 bytes, link #-80: the operators of a 140 for which
  the left side counts as read too (flags 50, else 18) `btst' on
  0x01FFE3BE; the flags passed by address from a frame word; il_180
  set to a call's routine (148) when it is not of kind 167 or 172;
  the latch flag +0 bit 2, the header +0 bit 1, b7 tested `bmi'. }

procedure liveanalysis;
var
  k: g_opt_num_t;
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  p: g_opt_stmt_ptr_t;
  bb: g_opt_block_ptr_t;
  f: integer;
  rs: g_opt_regs_t;
  e: g_opt_stmt_ptr_t;
  j: integer;
  n: il_$node_ptr_t;
  v: integer;
begin
  for k := opt_first_block to opt_last_block do begin
    opt_live_out^[k] := [];
    opt_used^[k] := [];
    opt_not_killed^[k] := [];
  end;
  if (12 in cargs_$options.opt_on) or (13 in cargs_$options.opt_on) then begin
    build_du_chains;
    repeat
    until assign_elim;
  end;
  g_opt_blocks_ptr_t(il_11c)^[opt_first_block]^.flags.skip := false;
  cur := opt_region;
  for k := opt_first_block to opt_last_block do begin
    b := g_opt_blocks_ptr_t(il_11c)^[k];
    depth := b^.depth + 1;
    s := b^.first_stmt;
    repeat
      cur := s^.hdr.region;
      if (cur = 0) and (s^.kind <> 144) then begin
        p := s;
        if b^.flags.latch then
          while cur = 0 do begin
            cur := p^.hdr.region;
            p := p^.prev;
          end
        else
          while cur = 0 do begin
            cur := p^.hdr.region;
            p := p^.next;
          end;
      end;
      rs := g_opt_regs_t(reg_save(il_$node_ptr_t(s)));
      b^.regs := b^.regs * rs;
      opt_4009c[cur]^.regs := opt_4009c[cur]^.regs * rs;
      bb := g_opt_blocks_ptr_t(il_11c)^[k];
      case s^.kind of
        140: begin
          if s^.asg_x <> nil then begin
            f := 34;
            varcheck(s^.asg_x, bb, f);
          end;
          f := 34;
          varcheck(s^.asg_rhs, bb, f);
          f := 18;
          if s^.asg_op in [1..5, 7..9, 13..24] then
            f := 50;
          varcheck(s^.asg_lhs, bb, f);
          if s^.asg_op in [1..5, 7..9, 13..24] then begin
            if (s^.asg_lhs^.kind = 110) and (s^.asg_lhs^.xw[8] <> 0) then
              varcheck(s^.asg_lhs, bb, f);
            if (s^.asg_lhs^.kind = 109) and (s^.asg_lhs^.xw[37] <> 0) then
              varcheck(s^.asg_lhs, bb, f);
          end;
        end;
        188: begin
          if (s^.x48^.kind = 109) and (s^.x48^.xw[36] = 5) then
            f := 1
          else
            f := 34;
          varcheck(s^.x48, bb, f);
        end;
        139: begin
          f := 34;
          for j := 1 to s^.eval_count do
            varcheck(s^.eval_opnd[j], bb, f);
        end;
        142: begin
          f := 34;
          varcheck(s^.br_cond, bb, f);
        end;
        148: begin
          n := s^.x48;
          if (n^.kind <> 167) and (n^.kind <> 172) then begin
            il_180 := n;
            f := 34;
            if n^.kind = 108 then
              varcheck(n^.xp[24], bb, f);
          end;
        end;
        141, 150, 144:
          ;
        151: begin
          f := 34;
          varcheck(s^.x48, bb, f);
        end;
        otherwise
      end;
      e := opt_4009c[cur];
      if e^.hdr.vnum <> 0 then
        if not e^.hdr.counted then begin
          e^.hdr.counted := true;
          if e^.vars <> nil then
            if e^.vars^[e^.hdr.vnum] <> nil then
              with e^.vars^[e^.hdr.vnum]^ do
                if count <> 0 then
                  count := count - 1;
        end;
      s := s^.next;
    until s = b^.last_stmt^.next;
  end;
  if il_180^.xw[145] > 0 then begin
    buildsets;
    lvanalyze;
    for k := opt_first_block to opt_last_block do begin
      b := g_opt_blocks_ptr_t(il_11c)^[k];
      if b^.flags.header then
        if 11 in cargs_$options.opt_on then
          if (rshft(ord(il_180^.xc[377]) & 16#70, 4) = 1) or
             (rshft(ord(il_180^.xc[377]) & 16#70, 4) = 6) then
            if b^.first_stmt^.kind = 144 then
              if rshft(ord(il_$node_ptr_t(b^.first_stmt)^.xc[72]) & 16#3E, 1) = 8 then
                for_check(k);
      if b^.flags.b7 or b^.flags.skip then
        for v := 1 to il_180^.xw[145] do
          if (v in opt_used^[k]) or
             ((v in opt_live_out^[k]) and (v in opt_not_killed^[k])) then begin
            n := opt_4009c[opt_region]^.vars^[v]^.node;
            if n^.kind = 109 then
              n^.xc[33] := chr(ord(n^.xc[33]) ! 16#20)
            else if n^.kind = 110 then
              n^.xc[25] := chr(ord(n^.xc[25]) ! 16#20);
          end;
    end;
    remove_bad_parents;
  end;
end;
