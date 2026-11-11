{ opt_general - the optimizer's general clean-ups over a routine's
  nodes: constant folding of every statement's trees (kfold), an
  assignment of a negative constant added or subtracted turned round,
  two consecutive assignments of constants to the same variable with
  the same operator merged into one, an evaluation statement's unused
  operands dropped; the variable numbers of a region (find_var) and
  the real multiplications by a power of two (is_scale_candidate).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0D6274  0x2A3464  assert_is_a_variable
    0x0D6296  0x2A3486  assert_is_scrutable_tree_not_used_elsewhere
    0x0D62CA  0x2A34BA  assert_is_explicitly_useless_object
    0x0D6312  0x2A3502  assert_is_useless_under_eval
    0x0D6334  0x2A3524  squash_this_eval_operand
    0x0D6356  0x2A3546  opt_gen_$prune_eval_operands
    0x0D63D4  0x2A35C4  is_scale_candidate
    0x0D64F2  0x2A36E2  general_opts
    0x0D6A0E  0x2A3BFE  find_var
    A5 0x2D2ED8 (cc.m68k), 0x493884 (cc.a88k): the unit has no data
    (opt_livevar's block follows).

  The four global routines (g_opt.ins.pas) load A5; the assertions and
  squash_this_eval_operand do not and are internal (the first three are
  leaf routines without a frame, docs/rev889-patterns.md 16).  The
  nodes are read through g_opt.ins.pas's views (statements, trees,
  basic blocks) and il.ins.pas's by offset.

  kfold is declared here: no insert the unit opens holds its heading
  (kfold.pas, docs/questions.md 64).  Its first parameter is `in' (the
  statement copied to a frame temporary before each call when it is in
  a register, general_opts 0x0D6614), as c_syntax declares it.

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the node kind sets), 7
  (is_scale_candidate's real arithmetic), 3 (none: no `new').
}
module opt_general;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/commit_top_node.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';

{ KFOLD - kfold.pas 0x0AF444 (cc.a88k 0x0B0E24): fold the constants of
  tree t, a tree of statement stmt. }
procedure kfold(
    in stmt: il_$node_ptr_t;
    var t: il_$node_ptr_t); extern;

define
  opt_gen_$prune_eval_operands, is_scale_candidate, general_opts,
  find_var;

{ assert_is_a_variable - t is a variable (109, 110).

  0x0D6274, 0x22 bytes, no frame: t at (4,SP); nil is not; the two
  comparisons evaluated whole (`seq; seq; or.b'). }

function assert_is_a_variable(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if t = nil then
    assert_is_a_variable := false
  else
    assert_is_a_variable := (t^.kind = 110) or (t^.kind = 109);
end;

{ assert_is_scrutable_tree_not_used_elsewhere - t is a tree (143 or
  137) used once and not marked to be kept.

  0x0D6296, 0x34 bytes, no frame: `andi.l #0x1018' of the longword at
  +4 (flags 3, 4 and 12). }

function assert_is_scrutable_tree_not_used_elsewhere(
    t: g_opt_tree_ptr_t): boolean; options(val_param); internal;
begin
  if t = nil then
    assert_is_scrutable_tree_not_used_elsewhere := false
  else if ((t^.kind = 143) or (t^.kind = 137)) and (t^.uses = 1) then
    assert_is_scrutable_tree_not_used_elsewhere := t^.flags * [3, 4, 12] = []
  else
    assert_is_scrutable_tree_not_used_elsewhere := false;
end;

{ assert_is_explicitly_useless_object - t is a tree or a reference
  (the kinds of the 26-byte set after the routine) used nowhere.

  0x0D62CA, 0x2E bytes, no frame: `btst' on the set of 0..207 (137,
  138, 143, 145..147, 164, 205; docs/dpc-gaps.md 8), then `tst.w
  (16,A0); seq'. }

function assert_is_explicitly_useless_object(
    t: g_opt_tree_ptr_t): boolean; options(val_param); internal;
begin
  if t = nil then
    assert_is_explicitly_useless_object := false
  else if t^.kind in [137, 138, 143, 145..147, 164, 205] then
    assert_is_explicitly_useless_object := t^.uses = 0
  else
    assert_is_explicitly_useless_object := false;
end;

{ assert_is_useless_under_eval - evaluating t has no effect.

  0x0D6312, 0x22 bytes: the second call only when the first is false
  (`bmi' to `st d0'). }

function assert_is_useless_under_eval(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_a_variable(t) then
    assert_is_useless_under_eval := true
  else
    assert_is_useless_under_eval :=
        assert_is_scrutable_tree_not_used_elsewhere(g_opt_tree_ptr_t(t));
end;

{ squash_this_eval_operand - replace operand t by the constant 0.

  0x0D6334, 0x22 bytes: smcontk(81, 0) (`clr.l; move.w #81'). }

procedure squash_this_eval_operand(
    var t: il_$node_ptr_t); internal;
begin
  t := smcontk(81, 0);
end;

{ opt_gen_$prune_eval_operands - fold each operand of evaluation
  statement s and replace the useless ones by 0 (their use counts
  given back).

  0x0D6356, 0x7E bytes.  Nothing when s's no_prune flag (+41 bit 1)
  is set.  The operands are +52.. (count at +50, a `dbf' loop); an
  operand already useless is squashed at once (`bmi' to the shared
  squash_this_eval_operand call, docs/rev889-patterns.md 23); kfold
  is given s's frame slot (`pea (8,A6)'), adjust_uc -1. }

procedure opt_gen_$prune_eval_operands(
    s: g_opt_stmt_ptr_t);
var
  j: integer;
begin
  if not s^.hdr.no_prune then
    for j := 1 to s^.eval_count do
      if assert_is_explicitly_useless_object(
             g_opt_tree_ptr_t(s^.eval_opnd[j])) then
        squash_this_eval_operand(s^.eval_opnd[j])
      else begin
        kfold(il_$node_ptr_t(s), s^.eval_opnd[j]);
        if assert_is_useless_under_eval(s^.eval_opnd[j]) then begin
          adjust_uc(s^.eval_opnd[j], -1);
          squash_this_eval_operand(s^.eval_opnd[j]);
        end;
      end;
end;

{ is_scale_candidate - t multiplies or divides a real (single or
  double) by a constant that is a power of two, or whose reciprocal
  is, within 5.0e-307..4.0e307: only with cpu element 4 and none of
  5, 9, 10 (cargs +0x285 bit 6; `andi.w #0x620' of the cpu field).

  0x0D63D4, 0x11E bytes, link #-32.  The operators 37 and 36 and the
  classes 7 and 6 compared whole (`seq; seq; or.b'); the constant
  (88 or 89, +12) copied to a frame double at -8, its absolute value
  stored at -24 (fpp_$ 0x0074 0x0070 0x007C) and compared with the
  immediates (0x00B8: 0x0056789E3750F78D, `bmi'; 0x7FCC7B1F3CAC7434,
  `bgt'); a power of two has a zero mantissa (the low longword and the
  high one's 20 low bits); the reciprocal (0x0078 1.0 0x00A4 0x0080)
  is stored at -32 and copied back to -8 (docs/rev889-patterns.md 19).

  Not known from the original:
  - the constants as written (the image's are 4.999999999999997e-307
    and 4.0000000000000004e307); whether the tests were nested ifs. }

function is_scale_candidate(
    t: g_opt_tree_ptr_t): boolean;
type
  bits_t = record
    case integer of
      1: (d: double);
      2: (hi: integer32;
          lo: integer32);
  end;
var
  x: bits_t;
  a: double;
  r: double;
  c: il_$node_ptr_t;
  ok: boolean;
begin
  ok := false;
  if 4 in cargs_$options.cpu then
    if cargs_$options.cpu * [5, 9, 10] = [] then
      if t^.kind = 137 then
        if (t^.op = 37) or (t^.op = 36) then
          if (t^.rlen = 7) or (t^.rlen = 6) then begin
            c := t^.opnd[2];
            if (c^.kind = 88) or (c^.kind = 89) then begin
              x.d := c^.real_value;
              a := abs(x.d);
              if a >= 5.0e-307 then
                if a <= 4.0e307 then
                  if (x.lo = 0) and ((x.hi & 16#FFFFF) = 0) then
                    ok := true
                  else begin
                    r := 1.0 / x.d;
                    x.d := r;
                    if (x.lo = 0) and ((x.hi & 16#FFFFF) = 0) then
                      ok := true;
                  end;
            end;
          end;
  is_scale_candidate := ok;
end;

{ general_opts - fold the constants of every node of the routine's
  blocks (opt_first_block's first node to opt_last_block's last) and
  simplify its assignments.

  0x0D64F2, 0x4CA bytes, link #-336.  The loop counts the nodes with a
  word (`subq.w #1; bcc'; first..last compared unsigned, `bcs').  With
  opt_track_lines, a statement (the 30-byte set of 0..239 at 0x0D69BC,
  tested without a range check, docs/rev889-patterns.md 41) whose line
  (+20) is not spos_$null_position becomes il_d0, and il_d0 is reset
  at the end.  A tree or reference standing for its statement (flag 6,
  +7 bit 6; the set at 0x0D69F4) is followed to it (+10, the node's
  number) unless that is a 190.  Then by kind (a compare chain in this
  order): 143 and 137 fold each operand; 145 its +36; 147, 205 and 146
  their +24; 142 its condition (+56), a one-character string (92,
  length 1) becoming its code (smcontk(81, ...)); 140 its right side,
  left side and +72 (when set), then commit_top_$convert_aops_to__
  aop_to_mem; 139 opt_gen_$prune_eval_operands.

  For an assignment with an operator in [1..5, 15, 16] (`btst' on
  0x1803E after a range check) of a constant (the set at 0x0D69DA):
  a negative constant added (1) or subtracted (2) is negated and the
  operator swapped (the two arms share the smcontk tail).  When the
  statement before is an assignment too, neither's left side has
  getphase elements 1 or 2 (`andi.l #6' of the or-ed sets) nor a
  number in the region (find_var), both store to the same variable
  (through a 190's +4 or a 189's +20), with the same operator and a
  constant: the two constants are combined into the first assignment
  (their widths' difference in bytes shifting the narrower one, an and
  mask filled with ones below; not for additions of different widths:
  `btst' on 0x18006, `bhi'), by a jump table on the operator (1, 2, 15,
  16 add, 3 and, 4 or, 5 exclusive or; an and giving 0, an or giving
  -1 or an exclusive or with 0 make the operator 0), the first's left
  side gives back a use, and the second is marked deleted (+41 bit 0)
  and unlinked.

  Not known from the original:
  - the locals' names; whether the negation was a case (the image's
    shared tail) or an if. }

procedure general_opts;
var
  last: g_opt_block_ptr_t;
  first: g_opt_block_ptr_t;
  i: g_opt_num_t;
  t: il_$node_ptr_t;
  st: g_opt_stmt_ptr_t;
  tr: g_opt_tree_ptr_t;
  p: g_opt_stmt_ptr_t;
  a: il_$node_ptr_t;
  b: il_$node_ptr_t;
  c: il_$node_ptr_t;
  j: integer;
  diff: integer32;
  sh: integer32;
  v: integer32;
  w: integer32;
begin
  last := g_opt_blocks_ptr_t(il_11c)^[opt_last_block];
  first := g_opt_blocks_ptr_t(il_11c)^[opt_first_block];
  for i := first^.first to last^.last do begin
    t := g_opt_nodes_ptr_t(il_120)^[i];
    if opt_track_lines then
      if (t^.kind in [139..142, 144, 148..151, 188, 191, 214, 215,
                      223..225, 227, 228, 231, 233]) and
         (g_opt_stmt_ptr_t(t)^.line <> spos_$null_position) then
        il_d0 := g_opt_stmt_ptr_t(t)^.line;
    if (t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) and
       (6 in g_opt_tree_ptr_t(t)^.flags) then
      while 6 in g_opt_tree_ptr_t(t)^.flags do begin
        t := g_opt_nodes_ptr_t(il_120)^[g_opt_tree_ptr_t(t)^.stmt];
        if t^.kind = 190 then
          exit;
      end;
    case t^.kind of
      143, 137: begin
        tr := g_opt_tree_ptr_t(t);
        for j := 1 to tr^.count do
          kfold(t, tr^.opnd[j]);
      end;
      145:
        kfold(t, t^.xp[9]);
      147:
        kfold(t, t^.xp[6]);
      205:
        kfold(t, t^.xp[6]);
      146:
        kfold(t, t^.xp[6]);
      142: begin
        st := g_opt_stmt_ptr_t(t);
        kfold(t, st^.br_cond);
        if st^.br_cond <> nil then
          if (st^.br_cond^.kind = 92) and (st^.br_cond^.str_len = 1) then
            st^.br_cond := smcontk(81, ord(st^.br_cond^.str_chars[1]));
      end;
      140: begin
        st := g_opt_stmt_ptr_t(t);
        kfold(t, st^.asg_rhs);
        kfold(t, st^.asg_lhs);
        if st^.asg_x <> nil then
          kfold(t, st^.asg_x);
        commit_top_$convert_aops_to__aop_to_mem(t);
        if (st^.asg_op in [1..5, 15, 16]) and
           (st^.asg_rhs^.kind in [77..87, 101, 200]) then begin
          if st^.asg_rhs^.int_value < 0 then
            case st^.asg_op of
              1: begin
                st^.asg_op := 2;
                st^.asg_rhs := smcontk(81, -st^.asg_rhs^.int_value);
              end;
              2: begin
                st^.asg_op := 1;
                st^.asg_rhs := smcontk(81, -st^.asg_rhs^.int_value);
              end;
              otherwise ;
            end;
          p := st^.prev;
          if p^.kind = 140 then
            if (getphase(p^.asg_lhs) + getphase(p^.asg_rhs)) * [1, 2] = [] then
              if (find_var(st^.asg_lhs) = 0) and
                 (find_var(p^.asg_lhs) = 0) then begin
                a := st^.asg_lhs;
                if a^.kind = 190 then
                  a := a^.xp[1]
                else if a^.kind = 189 then
                  a := a^.xp[5];
                b := p^.asg_lhs;
                if b^.kind = 190 then
                  b := b^.xp[1]
                else if b^.kind = 189 then
                  b := b^.xp[5];
                if (a = b) and (p^.asg_op = st^.asg_op) then begin
                  c := p^.asg_rhs;
                  if c^.kind in [77..87, 101, 200] then begin
                    diff := p^.asg_rlen - st^.asg_rlen;
                    if (diff = 0) or
                       not (st^.asg_op in [1, 2, 15, 16]) then begin
                      v := c^.int_value;
                      w := st^.asg_rhs^.int_value;
                      if diff > 0 then begin
                        sh := diff * 8;
                        w := lshft(w, sh);
                        if st^.asg_op = 3 then
                          w := w ! rshft(-1, 32 - sh);
                      end
                      else if diff < 0 then begin
                        sh := abs(diff) * 8;
                        v := lshft(v, sh);
                        if st^.asg_op = 3 then
                          v := v ! rshft(-1, 32 - sh);
                        p^.asg_rlen := st^.asg_rlen;
                      end;
                      case p^.asg_op of
                        1, 2, 15, 16:
                          v := v + w;
                        3: begin
                          v := v & w;
                          if v = 0 then
                            p^.asg_op := 0;
                        end;
                        4: begin
                          v := v ! w;
                          if v = -1 then
                            p^.asg_op := 0;
                        end;
                        5:
                          if (v = 0) or (w = 0) then begin
                            v := v ! w;
                            p^.asg_op := 0;
                          end
                          else
                            v := (v & ~w) ! (~v & w);
                        otherwise ;
                      end;
                      p^.asg_rhs := smcontk(81, v);
                      adjust_uc(p^.asg_lhs, -1);
                      st^.hdr.deleted := true;
                      p^.next := st^.next;
                      st^.next^.prev := p;
                    end;
                  end;
                end;
              end;
        end;
      end;
      139:
        opt_gen_$prune_eval_operands(g_opt_stmt_ptr_t(t));
      otherwise ;
    end;
  end;
  if opt_track_lines then
    il_d0 := spos_$null_position;
end;

{ find_var - the number of variable v (a 109's +74, a 110's +16) when
  it lies in 1..the routine's count (il_180's +290) and opt_region's
  entry of opt_4009c records v under it; else 0.

  0x0D6A0E, 0x7C bytes: the result kept in D0 from the start (`clr.w
  D0'); another kind returns at once (`bra'); the table entry tested
  for nil, then its node compared with v. }

function find_var(
    v: il_$node_ptr_t): integer;
var
  n: integer;
begin
  find_var := 0;
  if v <> nil then begin
    case v^.kind of
      109: n := v^.xw[37];
      110: n := v^.xw[8];
      otherwise
        return;
    end;
    if (n > 0) and (n <= il_180^.xw[145]) then
      if opt_4009c[opt_region]^.vars^[n] <> nil then
        if opt_4009c[opt_region]^.vars^[n]^.node = v then
          find_var := n;
  end;
end;
