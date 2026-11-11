{ il_utils - IL_UTILS, utilities over IL trees: classifying and counting
  a block's variables, keeping the use counts of tree nodes, substituting
  an operand, searching a tree for a node and comparing trees, and the
  source position of a top-level node.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07D9A4  0x07F384  il_utl_$classify_variable
    0x07DBA2  0x07F582  il_utl_$count_vars
    0x07DCF8  0x07F6D8  il_utils_$adjust_uc
    0x07E018  0x07F9F8  adjust_uc
    0x07E03A  0x07FA1A  il_utils_$set_uc_walk_spine
    0x07E092  0x07FA72  il_utils_$do_substitution
    0x07E184  0x07FB64  il_utils_$tree_node_operand_is_spine
    0x07E1CA  0x07FBAA  il_utils_$is_strength_reduction_temp
    0x07E206  0x07FBE6  search_point (in il_utils_$search_tree_for_node)
    0x07E252  0x07FC32  search_walk (in il_utils_$search_tree_for_node)
    0x07E3D4  0x07FDB4  il_utils_$search_tree_for_node
    0x07E3FE  0x07FDDE  il_utils_$source_generated_top_level_node
    0x07E4CC  0x07FEAC  il_utils_$src_line
    0x07E578  0x07FF58  il_utils_$trees_equivalent
    A5 0x169DF8 (cc.m68k): the module's data, +0 the spine
    set_uc_walk_spine keeps for adjust_uc (just after IL's globals in
    il.pas's region).

  Every module-level routine is global and loads A5.  The nodes' fields
  are read through il.ins.pas's views by offset (xp, xp2, xl, xl2, xw,
  xc) until their kinds' variants are declared.
}
module il_utils;

%include '/sys/ins/base.ins.pas';
%include 'lang/lang/source/il.ins.pas';
%include 'lang/lang/source/real_globals.ins.pas';
%include 'lang/lang/source/il_utils.ins.pas';
%include 'lang/lang/source/globals_from_frontend.ins.pas';
%include 'lang/lang/source/globals_from_general.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';

type
  { What a strength reduction temporary's node leads to (+46 of a kind
    110 node, +52 of a kind 109, then +4): its first field the node it
    was substituted for. }
  sr_info_ptr_t = ^sr_info_t;
  sr_info_t = record
    point: il_$node_ptr_t;              { +0 }
  end;

var
  kept_spine: il_$node_ptr_t;           { +0 }

{ il_utl_$classify_variable - the class of the variable node v of blk.

  0x07D9A4, 0x1FE bytes.  Kind 109 (next := +16): class 3 when its type
  (+28) is of kind 107; 2 when +32 has a bit of 16#201001 or +72 is 4;
  else, with is5 := +72 = 5 and the type of kind 121, the variable is of
  interest when is5, or info's +25 bit 6, or info's type of kind 134,
  130 or 123 (`seq' or'd); class 1 when not; then class 1 when blk is
  not of kind 105, blk's +379 bit 4 is clear and +72 is in [1, 3, 4, 7,
  8, 10, 11] (`move.w #0xD9A; btst'); else 4 when +72 is in that set,
  6 when is5, else 5.  Kind 110 (next := +4): with k := +44 bits 7..4:
  k = 6 gives 10 or 11 by +45 bit 4; blk's +376 bit 3 with blk not of
  kind 172 gives 9; k = 3 with +10 bits 3..0 = 7 gives 12, or 7 when
  +24 has a bit of 16#201001; k other than 3 gives 7 unless +44 bit 3,
  k = 1 and +45 bits 5..3 = 1; then 7 when +32 is set and +11 bits 7..4
  are not 5, or +28 or +58 is set, or +24 has a bit of 16#201001; else
  with n := +11 bits 7..4 in the set and blk's +379 bit 4 clear 7, in
  the set 13, 5 gives 15, else 14.  Other kinds: 0 (next := +16).

  Not known from the original:
  - every name; the classes' meaning. }

function il_utl_$classify_variable(
    v: il_$node_ptr_t;
    in info: il_utils_$type_info_t;
    blk: il_$node_ptr_t;
    out next: il_$node_ptr_t): integer;
var
  t: il_$node_ptr_t;
  is5, wanted: boolean;
  k, n: integer;
  res: integer;
begin
  if v^.kind = 109 then begin
    t := v^.xp[7];
    if t^.kind = 107 then
      res := 3
    else if ((v^.xl[8] & 16#201001) <> 0) or (v^.xw[36] = 4) then
      res := 2
    else begin
      is5 := (v^.xw[36] = 5) and (t^.kind = 121);
      if is5 or ((ord(info.c[25]) & 16#40) <> 0) then
        wanted := true
      else
        wanted := (info.tp^.kind = 134) or (info.tp^.kind = 130) or
                  (info.tp^.kind = 123);
      if not wanted then
        res := 1
      else if (blk^.kind <> 105) and ((ord(blk^.xc[379]) & 16#10) = 0) and
              (v^.xw[36] in [1, 3, 4, 7, 8, 10, 11]) then
        res := 1
      else if v^.xw[36] in [1, 3, 4, 7, 8, 10, 11] then
        res := 4
      else if is5 then
        res := 6
      else
        res := 5;
    end;
    next := v^.xp[4];
  end
  else if v^.kind = 110 then begin
    k := rshft(ord(v^.xc[44]) & 16#F0, 4);
    if k = 6 then begin
      if (ord(v^.xc[45]) & 16#10) <> 0 then
        res := 10
      else
        res := 11;
    end
    else if ((ord(blk^.xc[376]) & 8) <> 0) and (blk^.kind <> 172) then
      res := 9
    else if (k = 3) and ((ord(v^.xc[10]) & 15) = 7) then begin
      if (v^.xl[6] & 16#201001) = 0 then
        res := 12
      else
        res := 7;
    end
    else if (k <> 3) and
            not (((ord(v^.xc[44]) & 8) <> 0) and (k = 1) and
                 (rshft(ord(v^.xc[45]) & 16#38, 3) = 1)) then
      res := 7
    else begin
      n := rshft(ord(v^.xc[11]) & 16#F0, 4);
      if (v^.xp[8] <> nil) and (n <> 5) then
        res := 7
      else if (v^.xl[7] <> 0) or (v^.xl2[14] <> 0) then
        res := 7
      else if (v^.xl[6] & 16#201001) <> 0 then
        res := 7
      else if (n in [1, 3, 4, 7, 8, 10, 11]) and
              ((ord(blk^.xc[379]) & 16#10) = 0) then
        res := 7
      else if n in [1, 3, 4, 7, 8, 10, 11] then
        res := 13
      else if n = 5 then
        res := 15
      else
        res := 14;
    end;
    next := v^.xp[1];
  end
  else begin
    res := 0;
    next := v^.xp[4];
  end;
  il_utl_$classify_variable := res;
end;

{ il_utl_$count_vars - mark the variables of blk and of the kind 172
  blocks after it (+4) by class; the result is how many were marked -3
  (at most 255).

  0x07DBA2, 0x156 bytes.  For each variable from the block's +16 (while
  the count is under 255, `cmpi.l #255'): a kind 109 variable with no bit
  of 16#201001 in +32, unless +72 is 5 with a type of kind 121, gets its
  type described by type_exp (into a 32-byte local, -32); then by
  il_utl_$classify_variable (a `case' through a table of 16): 1 clears
  +74; 4..6 count +74 unless it is -3 and set it -3; 7 clears +16 unless
  it is -3; 8, 9 clear +16; 11 or's +44 bits 0 and 1 into the booleans
  +75 and +74 of the node at +48 (unless it is nil or il_178, `cmpa.l
  0x169DE8'); 12 sets +25 bit 5 and clears +16; 13..15 count +16 unless
  it is -3 and set it -3.

  Not known from the original:
  - the locals' names; the or into the booleans is written as setting
    them to true (the image or's 0 or 16#FF, `sne'). }

function il_utl_$count_vars(
    blk: il_$node_ptr_t): integer;
var
  n: integer32;
  b, v, next, q: il_$node_ptr_t;
  info: il_utils_$type_info_t;
begin
  n := 0;
  b := blk;
  while b <> nil do begin
    v := b^.xp[4];
    while (v <> nil) and (n < 255) do begin
      if (v^.kind = 109) and ((v^.xl[8] & 16#201001) = 0) and
         not ((v^.xw[36] = 5) and (v^.xp[7]^.kind = 121)) then
        type_exp(v, addr(info));
      case il_utl_$classify_variable(v, info, b, next) of
        1:
          v^.xw[37] := 0;
        4, 5, 6: begin
          if v^.xw[37] <> -3 then
            n := n + 1;
          v^.xw[37] := -3;
        end;
        7:
          if v^.xw[8] <> -3 then
            v^.xw[8] := 0;
        8, 9:
          v^.xw[8] := 0;
        11: begin
          q := v^.xp[12];
          if (q <> il_178) and (q <> nil) then begin
            if (ord(v^.xc[44]) & 1) <> 0 then
              q^.xc[75] := chr(16#FF);
            if (ord(v^.xc[44]) & 2) <> 0 then
              q^.xc[74] := chr(16#FF);
          end;
        end;
        12: begin
          v^.xc[25] := chr(ord(v^.xc[25]) ! 16#20);
          v^.xw[8] := 0;
        end;
        13, 14, 15: begin
          if v^.xw[8] <> -3 then
            n := n + 1;
          v^.xw[8] := -3;
        end;
        otherwise
      end;
      v := next;
    end;
    if (b^.xp[1] <> nil) and (b^.xp[1]^.kind = 172) then
      b := b^.xp[1]
    else
      b := nil;
  end;
  il_utl_$count_vars := n;
end;

{ il_utils_$adjust_uc - add delta to the use counts of the tree t.

  0x07DCF8, 0x320 bytes: a `case' on the kind (137..232, a table of 96;
  the image loops for the kinds that go on to one node instead of
  calling itself).  140, 227: the operands at +64, +68, +72; 139: the
  +50 operands from +34, last first; 150, 151, 214, 215, 224, 225: +48;
  142: +56; 228: +48..+64.  137, 138, 143: the count (+16) grows by
  delta; when it reaches 0 the +38 operands from +28 lose 1; when delta
  is positive and the count is delta (first use) they gain 1, an
  operand on the spine (tree_node_operand_is_spine of the operator at
  +36) through set_uc_walk_spine while a spine is kept.  164: likewise
  for +20 and +24.  145..147, 205: the count grows, +24 by delta (and
  +36 for 145).  175, 171 go on to +16, 190, 219, 220, 232 to +4, 189
  to +20.  Other kinds: nothing.

  Not known from the original:
  - the locals' names; whether the walk on was written as a loop; how
    the spine test was written (the image calls
    tree_node_operand_is_spine only while a spine is kept). }

procedure il_utils_$adjust_uc(
    t: il_$node_ptr_t;
    delta: integer);
var
  p: il_$node_ptr_t;
  i: integer;
  on_spine: boolean;
begin
  p := t;
  while p <> nil do
    case p^.kind of
      140, 227: begin
        il_utils_$adjust_uc(p^.xp[16], delta);
        il_utils_$adjust_uc(p^.xp[17], delta);
        il_utils_$adjust_uc(p^.xp[18], delta);
        return;
      end;
      139: begin
        for i := p^.xw[25] downto 1 do
          il_utils_$adjust_uc(p^.xp2[7 + i], delta);
        return;
      end;
      150, 151, 214, 215, 224, 225: begin
        il_utils_$adjust_uc(p^.xp[12], delta);
        return;
      end;
      142: begin
        il_utils_$adjust_uc(p^.xp[14], delta);
        return;
      end;
      228: begin
        il_utils_$adjust_uc(p^.xp[12], delta);
        il_utils_$adjust_uc(p^.xp[13], delta);
        il_utils_$adjust_uc(p^.xp[14], delta);
        il_utils_$adjust_uc(p^.xp[15], delta);
        il_utils_$adjust_uc(p^.xp[16], delta);
        return;
      end;
      137, 138, 143: begin
        p^.xw[8] := p^.xw[8] + delta;
        if p^.xw[8] = 0 then begin
          for i := 1 to p^.xw[19] do
            il_utils_$adjust_uc(p^.xp[6 + i], -1);
        end
        else if (delta > 0) and (delta = p^.xw[8]) then begin
          for i := 1 to p^.xw[19] do begin
            on_spine := false;
            if kept_spine <> nil then
              on_spine := il_utils_$tree_node_operand_is_spine(p^.xw[18], i);
            if on_spine then
              il_utils_$set_uc_walk_spine(p^.xp[6 + i], kept_spine)
            else
              il_utils_$adjust_uc(p^.xp[6 + i], 1);
          end;
        end;
        return;
      end;
      164: begin
        p^.xw[8] := p^.xw[8] + delta;
        if p^.xw[8] = 0 then begin
          il_utils_$adjust_uc(p^.xp[5], -1);
          il_utils_$adjust_uc(p^.xp[6], -1);
        end
        else if (delta > 0) and (delta = p^.xw[8]) then begin
          il_utils_$adjust_uc(p^.xp[5], 1);
          il_utils_$adjust_uc(p^.xp[6], 1);
        end;
        return;
      end;
      145, 146, 147, 205: begin
        p^.xw[8] := p^.xw[8] + delta;
        il_utils_$adjust_uc(p^.xp[6], delta);
        if p^.kind = 145 then
          il_utils_$adjust_uc(p^.xp[9], delta);
        return;
      end;
      175, 171:
        p := p^.xp[4];
      190, 219, 220, 232:
        p := p^.xp[1];
      189:
        p := p^.xp[5];
      otherwise
        return;
    end;
end;

{ adjust_uc - il_utils_$adjust_uc.

  0x07E018, 0x22 bytes: the arguments passed on (`bsr' 0x07E02E). }

procedure adjust_uc(
    t: il_$node_ptr_t;
    delta: integer);
begin
  il_utils_$adjust_uc(t, delta);
end;

{ il_utils_$set_uc_walk_spine - add 1 to the use counts along the chain
  from t.

  0x07E03A, 0x58 bytes: kept_spine := spine; each node from t along +8 gets
  il_utils_$adjust_uc(node, 1); the walk stops when t (not the node
  reached) is nil, or is of kind 149 with spine at +48; kept_spine :=
  nil.

  Not known from the original:
  - the local's name; whether the stop test was meant to look at the
    node reached (the image tests t, fp(8), each pass). }

procedure il_utils_$set_uc_walk_spine(
    t: il_$node_ptr_t;
    spine: il_$node_ptr_t);
var
  q: il_$node_ptr_t;
begin
  kept_spine := spine;
  q := t;
  while q <> nil do begin
    il_utils_$adjust_uc(q, 1);
    q := q^.xp[2];
    if t = nil then
      exit;
    if (t^.kind = 149) and (t^.xp[12] = spine) then
      exit;
  end;
  kept_spine := nil;
end;

{ il_utils_$do_substitution - put new in slot, an operand of old.

  0x07E092, 0xD8 bytes.  n := old's use count (+16) when its kind is in
  [137, 138, 143, 145..147, 164, 171, 175, 189, 205] (the set at
  0x07E16A), else 1; il_utils_$adjust_uc(old, -n); slot := new;
  il_utils_$adjust_uc(old, n).  A strength reduction temporary (kind 110
  with +24 bit 17, through +46; kind 109 with +32 bit 17, through +52;
  then +4) records old as its substitution point:
  opt_str_$set_substitution_point(new, old) when none or old is
  recorded, else opt_str_$add_substitution_point(new, old).

  Not known from the original:
  - the locals' names; why old, not new, gets the second adjustment. }

procedure il_utils_$do_substitution(
    old: il_$node_ptr_t;
    var slot: il_$node_ptr_t;
    new: il_$node_ptr_t);
var
  n: integer;
  info: sr_info_ptr_t;
begin
  if old^.kind in [137, 138, 143, 145, 146, 147, 164, 171, 175, 189, 205]
  then
    n := old^.xw[8]
  else
    n := 1;
  il_utils_$adjust_uc(old, -n);
  slot := new;
  il_utils_$adjust_uc(old, n);
  if new^.kind = 110 then begin
    if (new^.xl[6] & 16#20000) <> 0 then
      info := sr_info_ptr_t(new^.xp2[11]^.xp[1])
    else
      info := nil;
  end
  else if new^.kind = 109 then begin
    if (new^.xl[8] & 16#20000) <> 0 then
      info := sr_info_ptr_t(new^.xp[13]^.xp[1])
    else
      info := nil;
  end
  else
    info := nil;
  if info <> nil then
    if (info^.point = nil) or (info^.point = old) then
      opt_str_$set_substitution_point(new, old)
    else
      opt_str_$add_substitution_point(new, old);
end;

{ il_utils_$tree_node_operand_is_spine - whether operand i of operator op
  is on the spine.

  0x07E184, 0x46 bytes: op 30, 32 or 31 with i 3 or 2 (`seq' or'd);
  else false. }

function il_utils_$tree_node_operand_is_spine(
    op: integer;
    i: integer): boolean;
begin
  if (op = 30) or (op = 32) or (op = 31) then
    il_utils_$tree_node_operand_is_spine := (i = 3) or (i = 2)
  else
    il_utils_$tree_node_operand_is_spine := false;
end;

{ il_utils_$is_strength_reduction_temp - whether t is a strength
  reduction temporary.

  0x07E1CA, 0x3C bytes: bit 17 of +24 for kind 110, of +32 for kind 109;
  else false. }

function il_utils_$is_strength_reduction_temp(
    t: il_$node_ptr_t): boolean;
begin
  if t^.kind = 110 then
    il_utils_$is_strength_reduction_temp := (t^.xl[6] & 16#20000) <> 0
  else if t^.kind = 109 then
    il_utils_$is_strength_reduction_temp := (t^.xl[8] & 16#20000) <> 0
  else
    il_utils_$is_strength_reduction_temp := false;
end;

{ il_utils_$search_tree_for_node - the node of tree with node, or a tree
  equivalent to it, as an operand.

  0x07E3D4, 0x2A bytes: found (-4) := nil; search_walk(tree) (its static
  link in A1); the result is found.  The nested routines read node
  (12,A6) and same_only (16,A6) through the link. }

function il_utils_$search_tree_for_node(
    tree: il_$node_ptr_t;
    node: il_$node_ptr_t;
    same_only: boolean): il_$node_ptr_t;
var
  found: il_$node_ptr_t;

  procedure search_walk(t: il_$node_ptr_t); forward;

  { search_point - parent when t is node (or, unless same_only, a tree
    equivalent to it), else search on in t.

    0x07E206, 0x4C bytes: `cmpa.l (12,A4)'; same_only (`tst.b (16,A4)')
    skips il_utils_$trees_equivalent (t, node), 0 meaning equivalent; a
    match stores parent in found (-4,A4). }

  procedure search_point(
      parent: il_$node_ptr_t;
      t: il_$node_ptr_t);
  begin
    if t = node then
      found := parent
    else if same_only then
      search_walk(t)
    else if il_utils_$trees_equivalent(t, node) = 0 then
      found := parent
    else
      search_walk(t);
  end;

  { search_walk - search_point over t's operands while nothing is found.

    0x07E252, 0x182 bytes: nothing when found or t is nil; by kind
    (compared in turn): 139 the +50 operands from +34, last first; 142
    +56; 140 +68, +72, +64; 151, 188 +48; 143, 137 the +38 operands from
    +28; 147, 146, 205 +24; 145 +24, +36; 164 +20, +24; 175, 171 +16. }

  procedure search_walk;
  var
    i: integer32;
  begin
    if (found = nil) and (t <> nil) then
      case t^.kind of
        139:
          for i := t^.xw[25] downto 1 do
            search_point(t, t^.xp2[7 + i]);
        142:
          search_point(t, t^.xp[14]);
        140: begin
          search_point(t, t^.xp[17]);
          search_point(t, t^.xp[18]);
          search_point(t, t^.xp[16]);
        end;
        151, 188:
          search_point(t, t^.xp[12]);
        143, 137:
          for i := 1 to t^.xw[19] do
            search_point(t, t^.xp[6 + i]);
        147, 146, 205:
          search_point(t, t^.xp[6]);
        145: begin
          search_point(t, t^.xp[6]);
          search_point(t, t^.xp[9]);
        end;
        164: begin
          search_point(t, t^.xp[5]);
          search_point(t, t^.xp[6]);
        end;
        175, 171:
          search_point(t, t^.xp[4]);
        otherwise
      end;
  end;

begin
  found := nil;
  search_walk(tree);
  il_utils_$search_tree_for_node := found;
end;

{ il_utils_$source_generated_top_level_node - the first node from t
  (along +8) whose source position (+20) is not spos_$null_position, else t.

  0x07E3FE, 0x68 bytes: t nil or not a top-level kind (the 30-byte set
  at 0x07E466: [139..142, 144, 148..151, 188, 191, 214, 215, 223..225,
  227, 228, 231, 233]) is reported to bug_check (the string at 0x07E484)
  first.

  Not known from the original:
  - the local's name. }

function il_utils_$source_generated_top_level_node(
    t: il_$node_ptr_t): il_$node_ptr_t;
var
  p: il_$node_ptr_t;
begin
  if (t = nil) or
     not (t^.kind in [139, 140, 141, 142, 144, 148, 149, 150, 151, 188,
                      191, 214, 215, 223, 224, 225, 227, 228, 231, 233]) then
    bug_check('il_utils_$source_generated_top_level_node -- NIL or non-top level node%$');
  p := t;
  while (p <> nil) and (p^.xw[10] = spos_$null_position) do
    p := p^.xp[2];
  if p = nil then
    p := t;
  il_utils_$source_generated_top_level_node := p;
end;

{ il_utils_$src_line - the source position (+20) of the first node from
  t (along +4) that has one, else 0.

  0x07E4CC, 0x70 bytes: the same check as above (the string at
  0x07E53C); the walk skips nodes whose position is spos_$null_position
  (0x14E770). }

function il_utils_$src_line(
    t: il_$node_ptr_t): integer;
var
  p: il_$node_ptr_t;
begin
  p := t;
  if (p = nil) or
     not (p^.kind in [139, 140, 141, 142, 144, 148, 149, 150, 151, 188,
                      191, 214, 215, 223, 224, 225, 227, 228, 231, 233]) then
    bug_check('IL_UTILS_$\SRC_LINE --- tp^.kind is not a top_level node.%.');
  while (p <> nil) and (p^.xw[10] = spos_$null_position) do
    p := p^.xp[1];
  if p = nil then
    il_utils_$src_line := 0
  else
    il_utils_$src_line := p^.xw[10];
end;

{ il_utils_$trees_equivalent - 0 when a and b are the same tree, else 4.

  0x07E578, 0x23C bytes.  The same node: 0; different kinds: 4.  137,
  138, 143: the operators (+36) equal, the 16 bytes at +20 equal (`cmpm.l'
  four times), +4 equal under 16#1B611F and a's +4 without a bit of
  16#9001F; then an operator in the 12-byte set at 0x07E7B4 compares the
  +38 operands from +28, 48 and 26 compare +40, others are 4.  145: +42,
  +40, +32, +22, +23 equal, +4 under the mask, then +24 and +36
  equivalent.  147: +32 and +4 under the mask, then +24.  205: +24 and
  +32 equivalent.  146: +28 the same, then +24 and +28 equivalent.
  Other kinds (164, 165 named): 4.

  Not known from the original:
  - the index's name; how the 16 bytes were compared. }

function il_utils_$trees_equivalent(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): integer;
var
  i: integer;
  op: integer;
begin
  il_utils_$trees_equivalent := 4;
  if a = b then begin
    il_utils_$trees_equivalent := 0;
    return;
  end;
  if a^.kind <> b^.kind then
    return;
  case a^.kind of
    137, 138, 143: begin
      op := a^.xw[18];
      if op <> b^.xw[18] then
        return;
      for i := 5 to 8 do
        if a^.xl[i] <> b^.xl[i] then
          return;
      if (a^.xl[1] & 16#1B611F) <> (b^.xl[1] & 16#1B611F) then
        return;
      if (a^.xl[1] & 16#9001F) <> 0 then
        return;
      if op in [0..10, 13, 14, 17, 18, 27..29, 33..39, 41..46, 49..53,
                57, 59..62, 74..77, 86] then begin
        for i := 1 to a^.xw[19] do
          if il_utils_$trees_equivalent(a^.xp[6 + i], b^.xp[6 + i]) <> 0
          then
            return;
        il_utils_$trees_equivalent := 0;
      end
      else if (op = 48) or (op = 26) then
        il_utils_$trees_equivalent :=
          il_utils_$trees_equivalent(a^.xp[10], b^.xp[10]);
    end;
    145:
      if (a^.xw[21] = b^.xw[21]) and (a^.xw[20] = b^.xw[20]) and
         (a^.xl[8] = b^.xl[8]) and (a^.xc[22] = b^.xc[22]) and
         (a^.xc[23] = b^.xc[23]) and
         ((a^.xl[1] & 16#1B611F) = (b^.xl[1] & 16#1B611F)) then
        if il_utils_$trees_equivalent(a^.xp[6], b^.xp[6]) = 0 then
          if il_utils_$trees_equivalent(a^.xp[9], b^.xp[9]) = 0 then
            il_utils_$trees_equivalent := 0;
    147:
      if (a^.xl[8] = b^.xl[8]) and
         ((a^.xl[1] & 16#1B611F) = (b^.xl[1] & 16#1B611F)) then
        if il_utils_$trees_equivalent(a^.xp[6], b^.xp[6]) = 0 then
          il_utils_$trees_equivalent := 0;
    205:
      if il_utils_$trees_equivalent(a^.xp[6], b^.xp[6]) = 0 then
        if il_utils_$trees_equivalent(a^.xp[8], b^.xp[8]) = 0 then
          il_utils_$trees_equivalent := 0;
    146:
      if a^.xp[7] = b^.xp[7] then
        if il_utils_$trees_equivalent(a^.xp[6], b^.xp[6]) = 0 then
          if il_utils_$trees_equivalent(a^.xp[7], b^.xp[7]) = 0 then
            il_utils_$trees_equivalent := 0;
    otherwise
  end;
end;
