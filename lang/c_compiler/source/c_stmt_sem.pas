{ c_stmt_sem - the statements' semantics: the top-level IL nodes
  (evaluations, assignments, branches, labels) the parser's statements
  become, chained from il_d4 to il_d8; the labels of if, switch and the
  loops (a stack of three per loop), user labels and gotos, break and
  continue, a routine's body (with the profiling calls of -PROF) and
  its end; temporaries; and walk_tree, which lowers an expression's
  tree into statements: assignments, the conditional and logical
  operators (branches around assignments to a temporary), calls and
  post-increments (summed per statement).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x05BEF8  0x05C178  link_top
    0x05BFA0  0x05C220  add_top_node
    0x05BFD4  0x05C254  add_be_eval
    0x05BFFE  0x05C27E  add_eval
    0x05C0B6  0x05C336  add_ldfn
    0x05C304  0x05C584  def_def_label
    0x05C33C  0x05C5BC  add_brn
    0x05C428  0x05C6A8  add_cbranch
    0x05C6C4  0x05C944  add_cbrn
    0x05C6FA  0x05C97A  fnd_labl
    0x05C746  0x05C9C6  dcl_labl
    0x05C7B4  0x05CA34  def_labl
    0x05C86A  0x05CAEA  push_lbl
    0x05C896  0x05CB16  pop_lbl
    0x05C8CA  0x05CB4A  if_s
    0x05C900  0x05CB80  else_s
    0x05C94A  0x05CBCA  endif_s
    0x05C994  0x05CC14  case_ini
    0x05C9F8  0x05CC78  case_con
    0x05CB26  0x05CDA6  case_s
    0x05CC7C  0x05CEFC  case_default
    0x05CDA4  0x05D024  case_e
    0x05CDFA  0x05D07A  while_label
    0x05CE3E  0x05D0BE  while_s
    0x05CE6E  0x05D0EE  while_e
    0x05CEBC  0x05D13C  for_start_lab
    0x05CF00  0x05D180  for_s
    0x05CF30  0x05D1B0  for_next_lab
    0x05CF66  0x05D1E6  for_e
    0x05CFB4  0x05D234  repeat_s
    0x05CFF8  0x05D278  repeat_e
    0x05D05C  0x05D2DC  call_s
    0x05D62C  0x05D8AC  body_s
    0x05D232  0x05D4B2  setup_profiling
    0x05D42C  0x05D6AC  do_monstartup
    0x05D7CE  0x05DA4E  body_e
    0x05D698  0x05D918  finish_profiling
    0x05D9F8  0x05DC78  nxtext_s
    0x05DA8A  0x05DD0A  return_s
    0x05DAAC  0x05DD2C  goto_s
    0x05DB3A  0x05DDBA  temp_alloc
    0x05DD02  0x05DF82  build_assign
    0x05DF6A  0x05E1EA  extend_boolean
    0x05E02A  0x05E2AA  build_not_expr
    0x05E24A  0x05E4CA  build_cond_expr
    0x05E1CE  0x05E44E  eval_tree_nodes
    0x05E57E  0x05E7FE  only_logical
    0x05E624  0x05E8A4  find_post_opnd
    0x05E6D0  0x05E950  add_or_update
    0x05E750  0x05E9D0  fix_post_id
    0x05E938  0x05EBB8  walk_tree
    0x05E8B6  0x05EB36  is_post_incr_candidate
    A5 0x14A694 (cc.m68k), 0x2CA694 (cc.a88k), 0x600 bytes: the
    post-increment table (+0x0, 128 entries of 8 bytes), the two
    identifiers cc enters (+0x400, +0x408, c_globals.ins.pas), the
    label stack (40 entries of 12 bytes from +0x410, the depth at
    +0x5FA), the temporaries' count (+0x5F0), the stack size (+0x5F4),
    the post-increment depth (+0x5F8).

  The routines c_syntax, c_main and add_node call load A5; the others
  are internal (add_or_update, fix_post_id and push_lbl reach the
  module's data on their callers' A5).  setup_profiling and
  do_monstartup are nested in body_s, finish_profiling in body_e
  (setup_profiling and finish_profiling use their parent's frame),
  eval_tree_nodes in build_cond_expr, is_post_incr_candidate in
  walk_tree.

  IL nodes are reached through c_objtype.ins.pas's views (c_top_t, a
  top-level node; c_tree_t, a tree node; c_sym_t, c_blk_t) by type
  transfer, and il.ins.pas's xp/xw views (kinds 145..147, 205: the
  operand at +24).

  Probable slips of the original kept (docs/questions.md): case_default
  stores the selector's size into the entry below the one it pushes.
}
module c_stmt_sem;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include '/sys/ins/base.ins.pas';

define
  id_end_of_for;                        { +0x400 (c_globals.ins.pas) }
  cst_404;                              { +0x404 }
  id_end_of_while;                      { +0x408 }
  cst_40c;                              { +0x40C }
  cst_stack_size;                       { +0x5F4 }
  cst_5fa;                              { +0x5FA }

type
  { A variable's post-increments within one statement (pas_$new, 16
    bytes): the increment and how many times it was applied. }
  post_ptr_t = ^post_t;
  post_t = record
    next: post_ptr_t;                   { +0 }
    pvar: il_$node_ptr_t;               { +4 }
    incr: integer32;                    { +8 }
    count: integer32;                   { +12 }
  end;

  { One statement's post-increments (walk_tree's depth indexes them). }
  post_ent_t = record
    list: post_ptr_t;                   { +0 }
    total: integer32;                   { +4: increments beyond the
                                          first of each variable }
  end;

  { A loop's (or switch's) labels: continue's, break's and the loop's
    top. }
  lbl_ent_t = record
    cont: il_$node_ptr_t;               { +0 }
    brk: il_$node_ptr_t;                { +4 }
    top: il_$node_ptr_t;                { +8 }
  end;

var
  post_tab: array [1..128] of post_ent_t;  { +0x0 }
  lbl_stack: array [1..40] of lbl_ent_t;   { +0x410 }
  temp_count: integer32;                { +0x5F0 }
  post_depth: integer;                  { +0x5F8 }

{ link_top - see c_externs.ins.pas: a label node (144) makes the next
  statement reachable (il_c2); otherwise a pending label is defined
  first (il_c0, def_def_label), or il_c2 is set.  The node's line is
  il_d0 once when il_c3 is set (c_main), else spos_$null_position; +43
  and +44 cleared (one `andi.l #0xFF0000FF': docs/rev889-patterns.md
  10), +45 the nesting (il_172's low byte).

  0x05BEF8, 0xA8 bytes, link #-4.

  Not known from the original:
  - the names. }

procedure link_top;
var
  t: c_top_ptr_t;
begin
  if n^.kind = 144 then
    il_c2 := true
  else if il_c0 then
    def_def_label
  else if not il_c2 then
    il_c2 := true;
  if il_d8 = nil then
    il_d4 := n
  else
    c_top_ptr_t(il_d8)^.next := n;
  t := c_top_ptr_t(n);
  if il_c3 then begin
    t^.line := il_d0;
    il_c3 := false;
  end
  else
    t^.line := spos_$null_position;
  t^.prev := il_d8;
  t^.next := nil;
  t^.hdr.level := il_172;
  t^.hdr.b43 := 0;
  t^.hdr.b44 := 0;
  il_d8 := n;
end;

{ add_top_node - a top-level node of kind and size bytes, linked.

  0x05BFA0, 0x34 bytes, link #-12; A0.

  Not known from the original:
  - the names. }

function add_top_node(
    kind: integer;
    size: integer): il_$node_ptr_t; options(val_param); internal;
var
  n: il_$node_ptr_t;
begin
  n := gspace(size);
  n^.kind := kind;
  link_top(n);
  add_top_node := n;
end;

{ add_be_eval - an empty evaluation node (139, 92 bytes: no operands,
  ten slots cleared) that makes the next statement reachable.

  0x05BFD4, 0x2A bytes, link #-12: add_top_node(139, 92) pushed as one
  longword; the slots by a `dbf' loop of 10 (+52..+88).

  Not known from the original:
  - why the slots are cleared (gspace clears). }

procedure add_be_eval; internal;
var
  n: il_$node_ptr_t;
  i: integer;
begin
  il_c2 := true;
  n := add_top_node(139, 92);
  c_top_ptr_t(n)^.eval_count := 0;
  for i := 1 to 10 do
    c_top_ptr_t(n)^.eval_opnd[i] := nil;
end;

{ add_eval - the expression stack's entries lo..hi lowered (walk_tree)
  and evaluated by one node (139, 52 + 4 operands bytes), then
  adjust_uc(1) and delay_$shrink_top_level_node.

  0x05BFFE, 0xB8 bytes, link #-16: two `dbf' loops over hi - lo + 1
  entries (none when hi < lo).

  Not known from the original:
  - the names. }

procedure add_eval(
    lo: integer;
    hi: integer); options(val_param); internal;
var
  i: integer;
  n: il_$node_ptr_t;
begin
  for i := lo to hi do
    cexs_stack[i].node := walk_tree(cexs_stack[i].node, nil, nil);
  n := add_top_node(139, (hi - lo + 1) * 4 + 52);
  c_top_ptr_t(n)^.eval_count := 0;
  for i := lo to hi do
    with c_top_ptr_t(n)^ do begin
      eval_count := eval_count + 1;
      eval_opnd[eval_count] := cexs_stack[i].node;
    end;
  adjust_uc(n, 1);
  delay_$shrink_top_level_node(n);
end;

{ add_ldfn - place the label lab (by address) here.  A conditional
  branch over an unconditional one to it, just made, is folded
  (unless forced, inside a switch body (csyn_1e8^.active), or -DBA):
  the branch reversed.  Otherwise a label placed right after another
  joins it (il_c8 its chain); with forced (or in a switch body) a
  label node (144, 84 bytes) is made at once (lkind kind, its number
  from il_146[kind]), else it stays pending (il_c0, def_def_label).
  Then the branches waiting on the chain (141, 142, 150) are pointed at
  the label, and
  lab becomes it.

  0x05C0B6, 0x24E bytes, link #-28.  The fold's test is evaluated whole
  (`not.b; and.b; seq; and.b'), -DBA `andi.l #0x18000' of cargs'
  +0x282 (cargs_$options.db = 3); the label's flags `bclr #7; bset #6;
  andi.b #0xC1; or.b' (the kind's low byte doubled).

  Not known from the original:
  - the names; il_c1's role (il_c2 saved when a label is pending). }

procedure add_ldfn(
    var lab: il_$node_ptr_t;
    kind: integer;
    forced: boolean;
    fold: boolean); options(val_param); internal;
var
  make: boolean;
  a, p, q, n: il_$node_ptr_t;
begin
  make := forced;
  if csyn_1e8 <> nil then
    if csyn_1e8^.active then
      make := true;
  if (not make and fold and (lab^.kind = 142)) and
     (cargs_$options.db <> 3) then begin
    a := lab;
    if (il_d8^.kind = 141) and
       (c_top_ptr_t(a)^.br_target = il_178) and
       (c_top_ptr_t(a)^.next = il_d8) then begin
      il_d8^.kind := 142;
      c_top_ptr_t(il_d8)^.br_sense := not c_top_ptr_t(a)^.br_sense;
      c_top_ptr_t(il_d8)^.br_cond := c_top_ptr_t(a)^.br_cond;
      c_top_ptr_t(il_d8)^.line := c_top_ptr_t(a)^.line;
      c_top_ptr_t(il_d8)^.prev := c_top_ptr_t(a)^.prev;
      c_top_ptr_t(c_top_ptr_t(a)^.prev)^.next := il_d8;
      il_c2 := true;
      return;
    end;
  end;
  if not make and (lab = il_178) then
    return;
  if (il_d8 <> nil) and then (il_d8^.kind = 144) then
    il_c8 := lab
  else begin
    if il_c0 then begin
      if lab <> il_178 then begin
        a := lab;
        while c_top_ptr_t(a)^.br_target <> il_178 do
          a := c_top_ptr_t(a)^.br_target;
        c_top_ptr_t(a)^.br_target := il_c8;
        il_c8 := lab;
      end;
    end
    else begin
      il_c1 := il_c2;
      il_c8 := lab;
    end;
    il_c6 := kind;
    il_c2 := true;
    if make then begin
      il_c0 := false;
      n := gspace(84);
      n^.kind := 144;
      with c_top_ptr_t(n)^ do begin
        lab_bits.placed := false;
        lab_bits.pending := true;
        lab_bits.lkind := il_c6;
        lab_num := il_146[il_c6];
        il_146[il_c6] := lab_num + 1;
        lab_addr := -1;
        lab_64 := 0;
        lab_80 := 0;
        lab_w50 := 0;
        lab_74 := false;
        lab_75 := false;
      end;
      link_top(n);
    end
    else
      il_c0 := true;
  end;
  if not il_c0 then begin
    p := il_c8;
    while p <> il_178 do begin
      if not ((p^.kind = 150) or (p^.kind = 142) or (p^.kind = 141)) then
        exit;
      q := c_top_ptr_t(p)^.br_target;
      c_top_ptr_t(p)^.br_target := il_d8;
      p := q;
    end;
    if make then
      lab := il_d8;
  end;
end;

{ def_def_label - see c_externs.ins.pas: add_ldfn(il_c8, il_c6, true,
  true) when a label is pending.

  0x05C304, 0x38 bytes, link #0. }

procedure def_def_label;
begin
  if il_c0 then begin
    il_c0 := false;
    add_ldfn(il_c8, il_c6, true, true);
  end;
end;

{ add_brn - a branch to lab: when a label is pending here (and not
  -DBA), the branches waiting for it are sent to lab instead (or
  chained to it) and no branch is made unless il_c1; else a branch
  node (141, 64 bytes) to lab, lab (unless a label) becoming the chain
  of branches waiting.  The next statement is unreachable (il_c2
  false).

  0x05C33C, 0xEC bytes, link #-16.  A label's pending flag `bclr #6,
  (72)'.

  Not known from the original:
  - the names; the goto (the image falls into the branch's code after
    the il_c1 test). }

procedure add_brn(
    var lab: il_$node_ptr_t); internal;
label
  20;
var
  p, q, n: il_$node_ptr_t;
begin
  if il_c0 and (cargs_$options.db <> 3) then begin
    il_c0 := false;
    if lab^.kind = 144 then begin
      p := il_c8;
      while p <> il_178 do begin
        q := c_top_ptr_t(p)^.br_target;
        c_top_ptr_t(p)^.br_target := lab;
        p := q;
      end;
      c_top_ptr_t(lab)^.lab_bits.pending := false;
    end
    else if lab <> il_178 then begin
      p := lab;
      while c_top_ptr_t(p)^.br_target <> il_178 do
        p := c_top_ptr_t(p)^.br_target;
      c_top_ptr_t(p)^.br_target := il_c8;
    end
    else
      lab := il_c8;
    if not il_c1 then
      goto 20;
  end;
  n := gspace(64);
  n^.kind := 141;
  c_top_ptr_t(n)^.br_target := lab;
  if lab^.kind = 144 then
    c_top_ptr_t(lab)^.lab_bits.pending := false
  else
    lab := n;
  link_top(n);
20:
  il_c2 := false;
end;

{ add_cbranch - a branch to lab when the condition t is sense: under
  -XANSI t is first folded (cc_walk_it with call_kfold).  A constant
  condition is a branch or nothing; `&&' (52) and `||' (53) branch on
  each operand (the first through a join label of their own, placed
  after: add_ldfn kind 17); `!' (57) reverses the sense; `== 0' (12
  with class 6, a zero constant 80..82) of a logical operator tests
  that operator reversed; else the condition is lowered (walk_tree;
  kinds 11, 12, 23, 24, 40, 78, 79, 84 become 143) and a branch node
  (142, 64 bytes) made.  Other trees (kind not 137) are only lowered.

  0x05C428, 0x274 bytes, link #-16.  The constant test is `in [77..87,
  101, 200]' (`ble'), the operators' `in [11, 12, 23, 24, 40, 78, 79,
  84]' (a set of 0..95, `beq'); docs/dpc-gaps.md 8.  The join label in
  D4 (`move.l D4, (-12,A6)' around the calls that take it).

  Not known from the original:
  - the names. }

procedure add_cbranch(
    t: il_$node_ptr_t;
    var lab: il_$node_ptr_t;
    sense: boolean); options(val_param); internal;
var
  join, n: il_$node_ptr_t;
  tr: c_tree_ptr_t;
begin
  if cargs_$options.xansi then begin
    adjust_uc(t, 1);
    cc_walk_it(t, addr(call_kfold), false);
    adjust_uc(t, -1);
  end;
  if t^.kind in [77..87, 101, 200] then begin
    if not ((t^.int_value <> 0) and not sense) then
      if not (sense and (t^.int_value = 0)) then
        add_brn(lab);
    return;
  end;
  join := il_178;
  if t^.kind <> 137 then begin
    discard(walk_tree(t, nil, nil));
    return;
  end;
  tr := c_tree_ptr_t(t);
  case tr^.op of
    52: if sense then begin
          add_cbranch(tr^.opnd[1], lab, true);
          add_cbranch(tr^.opnd[2], lab, true);
        end
        else begin
          add_cbranch(tr^.opnd[1], join, true);
          add_cbranch(tr^.opnd[2], lab, false);
        end;
    53: if sense then begin
          add_cbranch(tr^.opnd[1], join, false);
          add_cbranch(tr^.opnd[2], lab, true);
        end
        else begin
          add_cbranch(tr^.opnd[1], lab, false);
          add_cbranch(tr^.opnd[2], lab, false);
        end;
    57: add_cbranch(tr^.opnd[1], lab, not sense);
    otherwise
      if (tr^.op = 12) and (tr^.desc.w8 = 6) and
         ((tr^.opnd[2]^.kind = 80) or (tr^.opnd[2]^.kind = 82) or
          (tr^.opnd[2]^.kind = 81)) and
         (tr^.opnd[2]^.int_value = 0) and
         (tr^.opnd[1]^.kind = 137) and
         ((c_tree_ptr_t(tr^.opnd[1])^.op = 52) or
          (c_tree_ptr_t(tr^.opnd[1])^.op = 57) or
          (c_tree_ptr_t(tr^.opnd[1])^.op = 53)) then
        add_cbranch(tr^.opnd[1], lab, sense)
      else begin
        if tr^.op in [11, 12, 23, 24, 40, 78, 79, 84] then
          t^.kind := 143;
        t := walk_tree(t, nil, nil);
        n := gspace(64);
        n^.kind := 142;
        c_top_ptr_t(n)^.br_target := lab;
        c_top_ptr_t(n)^.br_sense := sense;
        c_top_ptr_t(n)^.br_cond := t;
        adjust_uc(n, 1);
        delay_$shrink_top_level_node(n);
        if lab^.kind = 144 then
          c_top_ptr_t(lab)^.lab_bits.pending := false
        else
          lab := n;
        link_top(n);
      end;
  end;
  if join <> il_178 then
    add_ldfn(join, 17, false, true);
end;

{ add_cbrn - a branch to lab on the top of the expression stack (popped)
  being sense.

  0x05C6C4, 0x36 bytes, link #-8. }

procedure add_cbrn(
    var lab: il_$node_ptr_t;
    sense: boolean); options(val_param); internal;
begin
  add_cbranch(cexs_stack[cexs_23bc].node, lab, sense);
  cexs_23bc := cexs_23bc - 1;
end;

{ fnd_labl - the label symbol of name in the current routine (il_180
  past its kind 172 scopes: the block's +24 chain through +16), else
  il_178.

  0x05C6FA, 0x4C bytes, link #-16; A0.

  Not known from the original:
  - the names. }

function fnd_labl(
    in name: c_name_t): il_$node_ptr_t; internal;
var
  b, s: il_$node_ptr_t;
begin
  b := il_180;
  while b^.kind = 172 do
    b := b^.xp[2];
  s := il_$node_ptr_t(c_blk_ptr_t(b)^.labels);
  while (s <> nil) and then (c_sym_ptr_t(s)^.name <> name.id) do
    s := c_sym_ptr_t(s)^.blk_next;
  if s = nil then
    s := il_178;
  fnd_labl := s;
end;

{ dcl_labl - a label symbol (117, 40 bytes) for name in cdef_50's
  chain; il_178 for an unnamed one.

  0x05C746, 0x6E bytes, link #-16; A0.  The name pair copied whole to
  +4 (`move.l (A1)+; move.l (A1)').

  Not known from the original:
  - the names. }

function dcl_labl(
    in name: c_name_t): il_$node_ptr_t; internal;
var
  s: c_sym_ptr_t;
begin
  if name.id = il_178 then
    dcl_labl := il_178
  else begin
    s := gspace(40);
    s^.kind := 117;
    s^.lab_line := spos_$null_position;
    s^.lab_node := il_178;
    s^.lab_bits.used := false;
    s^.name := name.id;
    s^.line := name.line;
    s^.uplevel := name.uplevel;
    s^.unused_11 := name.unused_7;
    s^.block := il_$node_ptr_t(cdef_50);
    s^.blk_next := il_$node_ptr_t(cdef_50^.labels);
    cdef_50^.labels := s;
    dcl_labl := il_$node_ptr_t(s);
  end;
end;

{ def_labl - see c_externs.ins.pas: 23 when no symbol can be made, 57
  when the name is not a label, 56 when it is already placed (with its
  line), else add_ldfn(its label, 11, true, true).

  0x05C7B4, 0xB6 bytes, link #-4. }

procedure def_labl;
var
  s: il_$node_ptr_t;
begin
  s := fnd_labl(name);
  if s = il_178 then
    s := dcl_labl(name);
  if s = il_178 then
    error1(23, name.line, name.id)
  else if s^.kind <> 117 then
    error1(57, name.line, name.id)
  else if c_sym_ptr_t(s)^.lab_node^.kind = 144 then
    error2(56, name.line, name.id,
           smcontk(81, c_top_ptr_t(c_sym_ptr_t(s)^.lab_node)^.line))
  else
    add_ldfn(c_sym_ptr_t(s)^.lab_node, 11, true, true);
end;

{ push_lbl - a new label stack entry, all il_178.

  0x05C86A, 0x2C bytes: no frame (docs/rev889-patterns.md 14), the
  module's data through its caller's A5. }

procedure push_lbl; internal;
begin
  cst_5fa := cst_5fa + 1;
  lbl_stack[cst_5fa].cont := il_178;
  lbl_stack[cst_5fa].brk := il_178;
  lbl_stack[cst_5fa].top := il_178;
end;

{ pop_lbl - place the top entry's break label (kind) and pop it; one
  nesting level less (il_172).

  0x05C896, 0x34 bytes, link #-4. }

procedure pop_lbl(
    kind: integer); options(val_param); internal;
begin
  il_172 := il_172 - 1;
  add_ldfn(lbl_stack[cst_5fa].brk, kind, false, true);
  cst_5fa := cst_5fa - 1;
end;

{ if_s - both labels il_178, a branch to else_lab when the condition
  (the stack's top) is false.

  0x05C8CA, 0x36 bytes, link #0. }

procedure if_s;
begin
  else_lab := il_178;
  end_lab := il_178;
  add_cbrn(else_lab, false);
end;

{ else_s - a branch to end_lab (when reachable), else_lab placed (kind
  0) and cleared.

  0x05C900, 0x4A bytes, link #0. }

procedure else_s;
begin
  if il_c2 then
    add_brn(end_lab);
  add_ldfn(else_lab, 0, false, true);
  else_lab := il_178;
end;

{ endif_s - both labels placed (kind 1).

  0x05C94A, 0x4A bytes, link #0: the kind and false pushed as one
  longword (`move.l #65536'). }

procedure endif_s;
begin
  add_ldfn(else_lab, 1, false, true);
  add_ldfn(end_lab, 1, false, true);
end;

{ case_ini - the switch's type (diagnostic 43 unless a pointer, an
  integral type or an enumeration), no constants, the line.

  0x05C994, 0x64 bytes, link #-4.

  Not known from the original:
  - the names. }

procedure case_ini(
    line: integer;
    sel_type: univ_ptr;
    var c: c_case_t); options(val_param); internal;
begin
  type_exp(sel_type, addr(c.typ));
  if not ((c.typ.base^.kind = 130) or (c.typ.base^.kind = 122) or
          (c.typ.base^.kind = 129)) then begin
    error1(43, line, c.typ.base);
    c.typ.base := c_type_ptr_t(il_178);
  end;
  c.list := nil;
  c.line := line;
end;

{ case_con - see c_externs.ins.pas: a negative constant for an
  unsigned selector is diagnostic 45, a repeated one 46 (with the
  first's line); a new value is appended to c.list; after a
  diagnostic (or with no type) cx is cleared to il_178.

  0x05C9F8, 0x12E bytes, link #-24: the failure flag in D3 (`st' first,
  `clr.b' once appended); push's name pair at -8.

  Not known from the original:
  - the names. }

procedure case_con;
label
  10;
var
  bad: boolean;
  v: integer32;
  prev, p, n: c_caselist_ptr_t;
  name: c_name_t;
begin
  bad := true;
  if (cx.sym <> il_178) and (il_$node_ptr_t(c.typ.base) <> il_178) then begin
    v := cx.value^.int_value;
    if (c.typ.low >= 0) and (v < 0) then
      error1(45, cx.line, cx.sym);
    prev := nil;
    p := c.list;
    while p <> nil do begin
      if v = p^.value then begin
        error2(46, cx.line, smcontk(81, v), smcontk(81, p^.line));
        goto 10;
      end;
      prev := p;
      p := p^.next;
    end;
    bad := false;
    n := gspace(10);
    n^.next := nil;
    n^.value := v;
    n^.line := cx.line;
    if prev = nil then
      c.list := n
    else
      prev^.next := n;
  end;
10:
  if bad then begin
    cx.value := il_178;
    cx.ctype := c_type_ptr_t(il_178);
    cx.sym := il_178;
  end;
  if push then begin
    name.id := cx.value;
    name.line := cx.line;
    body_opr(8, addr(name));
    cexs_stack[cexs_23bc].typ.base := cx.ctype;
  end;
end;

{ case_s - see c_externs.ins.pas: the selector (the stack's top) made
  an argument (expr_op 22), a byte selector coerced to 2 bytes, its
  value evaluated by its own node (add_tn 17, add_eval) and copied to
  c.sel; a label entry pushed whose continue label is nil (continue
  looks further out); one nesting level more.

  0x05CB26, 0x156 bytes, link #-64: the copy of the type at -40 (26
  bytes), the auxiliary descriptor at -56; init_aux's call pops 6 of 8
  bytes (docs/rev889-patterns.md 11); the copy to c.sel is 62 bytes.

  Not known from the original:
  - the names; coerce's result is not read. }

procedure case_s;
var
  name: c_name_t;
  tt: type_exp_t;
  aux: c_desc_t;
begin
  case_ini(il_d0, cexs_stack[cexs_23bc].typ.base, c);
  name.id := il_178;
  expr_op(22, addr(name), 1);
  with cexs_stack[cexs_23bc] do
    if typ.size = 1 then begin
      tt := typ;
      tt.size := 2;
      discard(coerce(tt, cexs_23bc, true));
    end;
  init_aux(addr(aux), addr(cexs_stack[cexs_23bc].typ));
  add_tn(17, addr(aux), cexs_23bc, cexs_23bc);
  add_eval(cexs_23bc, cexs_23bc);
  c.first := il_d8;
  c.x4 := il_178;
  c.started := true;
  c.has_default := false;
  c.sel := cexs_stack[cexs_23bc];
  cexs_23bc := cexs_23bc - 1;
  push_lbl;
  lbl_stack[cst_5fa].cont := nil;
  il_172 := il_172 + 1;
end;

{ case_default - see c_externs.ins.pas: the code goes after the
  selector's evaluation node (c.first, il_d8 and il_d0 switched to it
  meanwhile): for the default a branch to the label, else a test of
  the selector (pushed back from c.sel) == the constant on the stack
  (expr_op 0 with `=='s token, test_ne_zero) branching to it; c.first
  advances; the label placed here (kind 15).

  0x05CC7C, 0x128 bytes, link #-28.  The pushed entry is copied from
  c.sel (62 bytes), then c.sel's typ.size is stored at -0x54 from the
  new top's end, the entry below's typ.size (kept as the image has
  it).

  Not known from the original:
  - the names. }

procedure case_default;
var
  save_last, first, nxt: il_$node_ptr_t;
  save_line: integer;
  lab: il_$node_ptr_t;
  name: c_name_t;
begin
  save_last := il_d8;
  first := c.first;
  save_line := il_d0;
  nxt := c_top_ptr_t(first)^.next;
  il_d8 := first;
  il_d0 := c_top_ptr_t(first)^.line;
  il_c2 := true;
  lab := il_178;
  if is_default then begin
    add_brn(lab);
    il_c2 := true;
  end
  else begin
    name.id := lex_tokens[ctk_eq];
    name.line := cexs_stack[cexs_23bc].line;
    cexs_23bc := cexs_23bc + 1;
    cexs_stack[cexs_23bc] := c.sel;
    cexs_stack[cexs_23bc - 1].typ.size := c.sel.typ.size;
    expr_op(0, addr(name), 2);
    test_ne_zero;
    add_cbrn(lab, true);
  end;
  if is_default then
    c.first := first
  else
    c.first := il_d8;
  c_top_ptr_t(il_d8)^.next := nxt;
  if nxt <> nil then begin
    c_top_ptr_t(nxt)^.prev := il_d8;
    il_d8 := save_last;
  end;
  il_d0 := save_line;
  add_ldfn(lab, 15, false, false);
  if is_default then
    c.has_default := true;
end;

{ case_e - a default (to the end) unless one was given, then the break
  label placed (kind 16) and the entry popped.

  0x05CDA4, 0x56 bytes, link #0. }

procedure case_e;
begin
  if not c.has_default then
    case_default(c, true);
  add_ldfn(lbl_stack[cst_5fa].brk, 16, false, true);
  cst_5fa := cst_5fa - 1;
end;

{ The loops: while_label (a new entry, its continue label placed: kind
  3), while_s (a branch to break when the condition is false),
  while_e (end_of_while's statement, a branch back, break placed:
  kind 4); for_start_lab (top placed: 8), for_s, for_next_lab
  (continue placed: 9), for_e (end_of_for, a branch to top, break:
  10); repeat_s (top placed: 5), repeat_e (continue placed: 6, a
  branch to top while true, break: 7).  Each starts and ends with an
  empty evaluation node (add_be_eval) and changes the nesting level.

  0x05CDFA..0x05D05B; each link #0 and A5.  while_e and for_e pop 2
  bytes after add_brn (`addq.l #2'; docs/rev889-patterns.md 11). }

procedure while_label;
begin
  add_be_eval;
  push_lbl;
  il_172 := il_172 + 1;
  add_ldfn(lbl_stack[cst_5fa].cont, 3, true, true);
end;

procedure while_s;
begin
  add_cbrn(lbl_stack[cst_5fa].brk, false);
end;

procedure while_e;
begin
  il_cc := id_end_of_while;
  il_d0 := lex_line;
  add_brn(lbl_stack[cst_5fa].cont);
  pop_lbl(4);
  add_be_eval;
end;

procedure for_start_lab;
begin
  add_be_eval;
  push_lbl;
  il_172 := il_172 + 1;
  add_ldfn(lbl_stack[cst_5fa].top, 8, true, true);
end;

procedure for_s;
begin
  add_cbrn(lbl_stack[cst_5fa].brk, false);
end;

procedure for_next_lab;
begin
  add_ldfn(lbl_stack[cst_5fa].cont, 9, true, true);
end;

procedure for_e;
begin
  il_cc := id_end_of_for;
  il_d0 := lex_line;
  add_brn(lbl_stack[cst_5fa].top);
  pop_lbl(10);
  add_be_eval;
end;

procedure repeat_s;
begin
  add_be_eval;
  push_lbl;
  add_ldfn(lbl_stack[cst_5fa].top, 5, true, true);
  il_172 := il_172 + 1;
end;

procedure repeat_e;
begin
  add_ldfn(lbl_stack[cst_5fa].cont, 6, false, true);
  add_cbrn(lbl_stack[cst_5fa].top, true);
  pop_lbl(7);
  add_be_eval;
end;

{ call_s - see c_externs.ins.pas: once per call node (bit 11 of its +6
  then set): a designator (171) whose function is not a block is
  lowered; each argument lowered, except an address (137, 26) of a
  variable, which is marked (var_flags 8) instead; an argument whose
  class differs from the designator's parameter class (its word at
  +14 + 4i) is converted (buildtreenode 39 for 6 and 7, else 18; the
  size 4 and 8 for them); then evaluated (add_eval).

  0x05D05C, 0x1D6 bytes, link #-284: the conversion's descriptor at
  -16, its operand list at -272, the operator at -274; the argument's
  offset 4i in D4 (`(0x24,A2,D4.l)').

  Not known from the original:
  - the names. }

procedure call_s;
label
  10;
var
  t: c_tree_ptr_t;
  fn, a, v: il_$node_ptr_t;
  i, k, op: integer;
  d: c_desc_t;
  opl: array [1..64] of il_$node_ptr_t;
begin
  t := c_tree_ptr_t(cexs_stack[cexs_23bc].node);
  if t^.bits.done then
    return;
  t^.bits.done := true;
  fn := t^.opnd[1];
  if (fn^.kind = 171) and then (fn^.xp[4]^.kind <> 108) then
    fn^.xp[4] := walk_tree(fn^.xp[4], nil, nil);
  for i := 2 to t^.count do begin
    a := t^.opnd[i];
    if (a^.kind = 137) and (c_tree_ptr_t(a)^.op = 26) then begin
      v := c_tree_ptr_t(a)^.opnd[1];
      if v^.kind = 109 then begin
        c_sym_ptr_t(v)^.var_flags := c_sym_ptr_t(v)^.var_flags + [8];
        goto 10;
      end;
      if (v^.kind = 147) and then (v^.xp[6]^.kind = 109) then begin
        c_sym_ptr_t(v^.xp[6])^.var_flags :=
            c_sym_ptr_t(v^.xp[6])^.var_flags + [8];
        goto 10;
      end;
      if (v^.kind = 146) and then (v^.xp[6]^.kind = 109) and then
         (c_sym_ptr_t(v^.xp[6])^.var_vat = vat_param) then begin
        c_sym_ptr_t(v^.xp[6])^.var_flags :=
            c_sym_ptr_t(v^.xp[6])^.var_flags + [8];
        goto 10;
      end;
    end;
    t^.opnd[i] := walk_tree(a, nil, nil);
10:
    if (c_tree_ptr_t(t^.opnd[1])^.kind = 171) and
       (t^.opnd[i]^.kind = 137) then begin
      k := t^.opnd[1]^.xw[7 + 2 * i];
      a := t^.opnd[i];
      if k <> c_tree_ptr_t(a)^.desc.rlen then begin
        if (k = 7) or (k = 6) then
          op := 39
        else
          op := 18;
        opl[1] := a;
        d.rlen := k;
        d.w6 := c_tree_ptr_t(a)^.desc.rlen;
        d.w8 := 0;
        d.size := k;
        d.flags.b6 := c_tree_ptr_t(a)^.desc.flags.b6;
        d.flags.b7 := false;
        if k = 6 then
          d.size := 4
        else if k = 7 then
          d.size := 8;
        t^.opnd[i] := buildtreenode(op, addr(d), addr(opl), 1);
        c_tree_ptr_t(t^.opnd[i])^.w16 := 0;
      end;
    end;
  end;
  add_eval(cexs_23bc, cexs_23bc);
end;

{ body_s - see c_externs.ins.pas: no temporaries yet, the entry label
  placed (13), a start node (148, 52 bytes) for cdef_50; under -PROF
  (cargs_$options.flags_286 element 10) monstartup's call for a
  program (il_180 of kind 105) and mcount's.

  0x05D62C, 0x6C bytes, link #-48 (-46: setup_profiling's saved
  -TYPE flag).

  Not known from the original:
  - the names. }

procedure body_s;
var
  saved_type_opt: boolean;
  n: il_$node_ptr_t;

  { setup_profiling - a static pointer <hidden_mcount> (def_varn 1,
    allocated, initialized to 0) and the call mcount(&<hidden_mcount>)
    (mcount declared a function returning int when unknown), -TYPE off
    meanwhile.

    0x05D232, 0x1E4 bytes, link #-132: body_s's frame from its dynamic
    link (`movea.l (A6),A2'; docs/rev889-patterns.md 25); the names at
    -120 and -128, the declarations at -72 and -112, the type at -32.

    Not known from the original:
    - the names. }

  procedure setup_profiling;
  var
    hm, mc: c_name_t;
    decl, d2: c_decl_t;
    tt: type_exp_t;
    v: c_sym_ptr_t;
  begin
    hm.id := idntk(ctk_identifier, '<hidden_mcount>', 15);
    hm.line := lex_line;
    decl.dtype := def_ptr(int_type, nil);
    type_exp(decl.dtype, addr(tt));
    decl.name := hm.id;
    decl.line := lex_line;
    decl.flags := [];
    decl.size_bits := tt.bytes;
    decl.unused_8 := 0;
    v := def_varn(hm, decl, vat_stat, true);
    type_exp(v^.var_type, addr(tt));
    def_alloc_var(v, tt.bytes);
    def_data(v, 0, smcontk(82, 0));
    saved_type_opt := cargs_$options.type_opt;
    cargs_$options.type_opt := false;
    mc.id := idntk(ctk_identifier, 'mcount', 6);
    mc.line := lex_line;
    if fnd_name(mc, true, false) = il_178 then begin
      d2.flags := [];
      d2.dtype := int_type;
      d2.name := mc.id;
      d2.line := mc.line;
      def_blk_skeleton(108, mc, 2, d2, nil, nil, false, 3, 0,
                       nil);
    end;
    body_opr(1, addr(mc));
    body_opr(5, addr(mc));
    body_opr(1, addr(hm));
    body_opr(5, addr(hm));
    expr_op(17, addr(hm), 1);
    expr_op(18, addr(mc), 2);
    call_s;
    cexs_23bc := cexs_23bc - 1;
    cargs_$options.type_opt := saved_type_opt;
  end;

  { do_monstartup - the call monstartup(&stext, &etext) (the two
    declared extern ints, monstartup a function returning int when
    unknown), -TYPE off meanwhile.

    0x05D42C, 0x1EA bytes, link #-144: the saved flag in D2; the names
    at -136, -128, -120 (their lines set together), the declarations
    at -72 (+16 the type's size) and -112.

    Not known from the original:
    - the names. }

  procedure do_monstartup;
  var
    saved: boolean;
    ms, st, et: c_name_t;
    decl, d2: c_decl_t;
    tt: type_exp_t;
    line: integer;
  begin
    saved := cargs_$options.type_opt;
    cargs_$options.type_opt := false;
    ms.id := idntk(ctk_identifier, 'monstartup', 10);
    st.id := idntk(ctk_identifier, 'stext', 5);
    et.id := idntk(ctk_identifier, 'etext', 5);
    line := lex_line;
    st.line := line;
    et.line := line;
    ms.line := line;
    decl.dtype := int_type;
    type_exp(decl.dtype, addr(tt));
    decl.line := lex_line;
    decl.flags := [];
    decl.size_bits := tt.size;
    decl.unused_8 := 0;
    if fnd_name(ms, true, false) = il_178 then begin
      d2.flags := [];
      d2.dtype := int_type;
      d2.name := ms.id;
      d2.line := ms.line;
      def_blk_skeleton(108, ms, 2, d2, nil, nil, false, 3, 0,
                       nil);
    end;
    body_opr(1, addr(ms));
    decl.name := st.id;
    discard(def_varn(st, decl, vat_ext, false));
    body_opr(1, addr(st));
    body_opr(5, addr(st));
    expr_op(17, addr(st), 1);
    decl.name := et.id;
    discard(def_varn(et, decl, vat_ext, false));
    body_opr(1, addr(et));
    body_opr(5, addr(et));
    expr_op(17, addr(et), 1);
    expr_op(18, addr(ms), 3);
    call_s;
    cexs_23bc := cexs_23bc - 1;
    cargs_$options.type_opt := saved;
  end;

begin
  temp_count := 0;
  add_ldfn(cdef_50^.entry_lab, 13, true, true);
  n := add_top_node(148, 52);
  c_top_ptr_t(n)^.blk := il_$node_ptr_t(cdef_50);
  if 10 in cargs_$options.flags_286 then begin
    if c_blk_ptr_t(il_180)^.kind = 105 then
      do_monstartup;
    setup_profiling;
  end;
end;

{ body_e - see c_externs.ins.pas: the return label placed (12); under
  -PROF monexit's call; when the end is reachable a return node (151,
  56 bytes, flag ret) with the result's class (11 for none) and, for a
  dynamic result variable, the variable; the end node (149, 52 bytes)
  kept in cdef_50's end_node; each label never placed is diagnostic 97
  (a used one marks its IL label's +74); the frame (|+112| + +176)
  against the stack size (123 beyond it, 122 within 32768 of it);
  il_180 back to the outer block.

  0x05D7CE, 0x22A bytes, link #-52: the node at -48 (finish_profiling
  stores fnd_name's result there), the type at -32; the size in D2
  (`bpl; neg.l').

  Not known from the original:
  - the names. }

procedure body_e;
label
  10;
var
  n: il_$node_ptr_t;
  tt: type_exp_t;
  p: c_sym_ptr_t;
  l: il_$node_ptr_t;
  size: integer32;

  { finish_profiling - the call monexit(&<hidden_mcount>) (monexit a
    function returning int when unknown), -TYPE off meanwhile.

    0x05D698, 0x12E bytes, link #-64: body_e's frame from its dynamic
    link, its -48 given fnd_name's result; the names at -56, -48, the
    declaration at -40; the flag in D2.

    Not known from the original:
    - the names; why the parent's slot. }

  procedure finish_profiling;
  var
    hm, mx: c_name_t;
    decl: c_decl_t;
    saved: boolean;
  begin
    hm.id := idntk(ctk_identifier, '<hidden_mcount>', 15);
    hm.line := lex_line;
    saved := cargs_$options.type_opt;
    cargs_$options.type_opt := false;
    mx.id := idntk(ctk_identifier, 'monexit', 7);
    mx.line := lex_line;
    n := fnd_name(mx, true, false);
    if n = il_178 then begin
      decl.flags := [];
      decl.dtype := int_type;
      decl.name := mx.id;
      decl.line := mx.line;
      def_blk_skeleton(108, mx, 2, decl, nil, nil, false, 3, 0,
                       nil);
    end;
    body_opr(1, addr(mx));
    body_opr(1, addr(hm));
    expr_op(18, addr(mx), 2);
    body_opr(5, addr(mx));
    call_s;
    cexs_23bc := cexs_23bc - 1;
    cargs_$options.type_opt := saved;
  end;

begin
  add_ldfn(cdef_50^.ret_lab, 12, false, true);
  if 10 in cargs_$options.flags_286 then
    finish_profiling;
  if il_c2 then begin
    n := add_top_node(151, 56);
    c_top_ptr_t(n)^.hdr.ret := true;
    if cdef_50^.ret_var = nil then
      c_top_ptr_t(n)^.ret_rlen := 11
    else begin
      type_exp(cdef_50^.ret_var^.var_type, addr(tt));
      c_top_ptr_t(n)^.ret_rlen := get_rlen(tt);
      if cdef_50^.ret_var^.var_vat = vat_dynm then begin
        c_top_ptr_t(n)^.ret_var := il_$node_ptr_t(cdef_50^.ret_var);
        goto 10;
      end;
    end;
    c_top_ptr_t(n)^.ret_var := nil;
10:
    adjust_uc(n, 1);
    delay_$shrink_top_level_node(n);
  end;
  il_c2 := true;
  n := add_top_node(149, 52);
  c_top_ptr_t(n)^.blk := il_$node_ptr_t(cdef_50);
  cdef_50^.end_node := n;
  p := cdef_50^.labels;
  while p <> nil do begin
    l := p^.lab_node;
    if l^.kind <> 144 then
      error1(97, p^.line, p^.name)
    else if p^.lab_bits.used then
      c_top_ptr_t(l)^.lab_74 := true;
    p := c_sym_ptr_t(p^.blk_next);
  end;
  with c_blk_ptr_t(il_180)^ do begin
    x228 := 0;
    size := abs(frame_size) + x176;
    if size > cst_stack_size then
      error3(123, lex_line, name.id, smcontk(82, size),
             smcontk(82, cst_stack_size))
    else if cst_stack_size - 32768 < size then
      error3(122, lex_line, name.id, smcontk(82, size),
             smcontk(82, cst_stack_size));
  end;
  c_blk_ptr_t(il_180)^.end_line := lex_line;
  il_180 := cdef_outer_block;
  c_blk_ptr_t(il_180)^.x196 := 0;
end;

{ nxtext_s - see c_externs.ins.pas: outside a loop diagnostic 88; break
  branches to the innermost entry's break label, continue to the
  innermost continue label that is not nil (a switch's).

  0x05D9F8, 0x92 bytes, link #-8: the entry's end in A2 (`lea
  (1040,A0)'), the search index in D2.

  Not known from the original:
  - the names; the goto (the image's diagnostic comes first). }

procedure nxtext_s;
label
  10;
var
  k: integer;
begin
  if cst_5fa = 0 then
    goto 10;
  if il_cc^.kind = ctk_continue then begin
    if lbl_stack[cst_5fa].cont <> nil then
      add_brn(lbl_stack[cst_5fa].cont)
    else begin
      k := cst_5fa;
      repeat
        k := k - 1;
        if k = 0 then
          goto 10;
      until lbl_stack[k].cont <> nil;
      add_brn(lbl_stack[k].cont);
    end;
  end
  else
    add_brn(lbl_stack[cst_5fa].brk);
  return;
10:
  error1(88, il_d0, il_cc);
end;

{ return_s - a branch to the return label.  0x05DA8A, 0x22 bytes. }

procedure return_s;
begin
  add_brn(cdef_50^.ret_lab);
end;

{ goto_s - see c_externs.ins.pas: the label (declared when new) gets the
  goto's line; a label of another routine is diagnostic 38.

  0x05DAAC, 0x8E bytes, link #-8. }

procedure goto_s;
var
  s: il_$node_ptr_t;
begin
  s := fnd_labl(name);
  if s = il_178 then
    s := dcl_labl(name);
  if s <> il_178 then begin
    c_sym_ptr_t(s)^.lab_line := name.line;
    if c_sym_ptr_t(s)^.block = il_$node_ptr_t(cdef_50) then
      add_brn(c_sym_ptr_t(s)^.lab_node)
    else
      error2(38, il_d0, name.id, smcontk(81, name.line));
  end;
end;

{ temp_alloc - see c_externs.ins.pas: named <stack-temp-NNN> (the
  count zero-filled to 3 digits, PRTSUB), a dynamic variable (add_varn
  2) of the class's basic type (a jump table of 12: 0 void, 1 char, 2
  short, 4 int, 5 int *, 6 float, 7 double, 11 int with size bytes and
  their natural alignment), entered first in the identifier's chain,
  flag 14, allocated, its +80 the size's constant; an uplevel one
  (vat 6) is reached through the expression stack (body_opr 10, its
  node).

  0x05DB3A, 0x1BC bytes, link #-324: the line at -304, the name pair
  at -312, the declaration at -40, the allocation word at -318.

  Not known from the original:
  - the names. }

function temp_alloc;
var
  line: prtsub_$line_t;
  name: c_name_t;
  vat: c_vat_t;
  decl: c_decl_t;
  v: c_sym_ptr_t;
begin
  temp_count := temp_count + 1;
  line.length := 0;
  prtcats(line, '<stack-temp-', 12);
  prtint(line, temp_count, 3, true);
  prtcatc(line, '>');
  name.id := idntk(ctk_identifier, line.body, line.length);
  name.line := spos_$null_position;
  vat := vat_dynm;
  decl.flags := [];
  decl.unused_28 := 0;
  case kind of
    0: decl.dtype := void_type;
    1: decl.dtype := char_type;
    2: decl.dtype := short_type;
    4: decl.dtype := int_type;
    5: decl.dtype := def_ptr(int_type, nil);
    6: decl.dtype := float_type;
    7: decl.dtype := double_type;
    11: decl.dtype := int_type;
  end;
  v := add_varn(name.id, decl, vat);
  if kind = 11 then begin
    v^.var_attr.size_bits := size * 8;
    v^.var_attr.align := attr_natural_align_from_bytes(size);
  end;
  v^.next := c_sym_ptr_t(name.id^.idnt_unused_8);
  name.id^.idnt_unused_8 := integer32(v);
  v^.var_flags := v^.var_flags + [14];
  def_alloc_var(v, size);
  v^.var_sect := smcontk(81, size);
  temp_alloc := il_$node_ptr_t(v);
  if v^.var_vat = vat_xdynm then begin
    body_opr(10, addr(name));
    temp_alloc := cexs_stack[cexs_23bc].node;
    cexs_23bc := cexs_23bc - 1;
  end;
end;

{ build_assign - an assignment node (140, 80 bytes) from the tree a
  (an assignment, `='), unless its class is 0: a string's array
  assigned (or assigned from) with another size is first converted
  (add_tn 18 on the right operand, through the expression stack); the
  descriptor, the operands, the kind (+18; the third operand for 29
  and 30); `x = x op y' (op 1, 2, 9, 10, 44 on the same left operand)
  becomes the kind 1..5 with y.

  0x05DD02, 0x262 bytes, link #-76: the descriptor copy at -48, the
  type at -32; the size's low word rounded up to even (`btst #0;
  addq.w #1'); the operators' `in [1, 2, 9, 10, 44]' (a set of 0..47,
  `ble'; docs/dpc-gaps.md 8).

  Not known from the original:
  - the names. }

procedure build_assign(
    var a: c_tree_t); internal;
var
  lhs, rhs, n: il_$node_ptr_t;
  k: integer;
  d: c_desc_t;
  tt: type_exp_t;
  r: c_tree_ptr_t;
begin
  if a.desc.rlen = 0 then
    return;
  rhs := a.opnd[2];
  lhs := a.opnd[1];
  if (rhs^.kind = 109) and then (14 in c_sym_ptr_t(rhs)^.var_flags) and then
     (c_sym_ptr_t(rhs)^.name <> id_string_constant) then begin
    k := a.desc.size;
    if odd(k) then
      k := k + 1;
    if k <> c_sym_ptr_t(rhs)^.var_sect^.int_value then begin
      d := a.desc;
      d.w6 := c_sym_ptr_t(rhs)^.var_sect^.int_value;
      cexs_23bc := cexs_23bc + 1;
      cexs_stack[cexs_23bc].node := a.opnd[2];
      add_tn(18, addr(d), cexs_23bc, cexs_23bc);
      a.opnd[2] := cexs_stack[cexs_23bc].node;
      cexs_23bc := cexs_23bc - 1;
    end;
  end
  else if (lhs^.kind = 109) and (rhs^.kind = 109) and then
          (14 in c_sym_ptr_t(lhs)^.var_flags) and then
          (c_sym_ptr_t(lhs)^.name <> id_string_constant) then begin
    k := a.desc.size;
    type_exp(c_sym_ptr_t(rhs)^.var_type, addr(tt));
    if tt.flags.ranged and (k <> tt.size) then begin
      d := a.desc;
      d.w6 := tt.size;
      cexs_23bc := cexs_23bc + 1;
      cexs_stack[cexs_23bc].node := a.opnd[2];
      add_tn(18, addr(d), cexs_23bc, cexs_23bc);
      a.opnd[2] := cexs_stack[cexs_23bc].node;
      cexs_23bc := cexs_23bc - 1;
    end;
  end;
  n := add_top_node(140, 80);
  with c_top_ptr_t(n)^ do begin
    asg_lhs := a.opnd[1];
    asg_rhs := a.opnd[2];
    asg_desc := a.desc;
    k := a.w18;
    asg_op := k;
    if (k = 30) or (k = 29) then
      asg_x := a.opnd[3]
    else
      asg_x := nil;
    if (asg_op <> 10) and (asg_rhs^.kind = 137) then begin
      r := c_tree_ptr_t(asg_rhs);
      if (r^.op in [1, 2, 9, 10, 44]) and (r^.opnd[1] = asg_lhs) then begin
        case r^.op of
          1: asg_op := 1;
          2: asg_op := 2;
          9: asg_op := 3;
          10: asg_op := 4;
          44: asg_op := 5;
        end;
        asg_rhs := r^.opnd[2];
      end;
    end;
  end;
  adjust_uc(n, 1);
  delay_$shrink_top_level_node(n);
end;

{ extend_boolean - the stack entry top (a logical value of descriptor
  d) as a class 1 value (add_tn 18; a floating one with 39, first
  through class 2 for -CPU ANY or PEB: cpu elements 0 and 1, `andi.w
  #0x3FFC' of the word at cargs' +0x284, `lsr.w #2; andi.w #3'); its
  node.

  0x05DF6A, 0xC0 bytes, link #-28: the copy at -24.

  Not known from the original:
  - the names. }

function extend_boolean(
    in d: c_desc_t;
    top: integer): il_$node_ptr_t; options(val_param); internal;
var
  e: c_desc_t;
begin
  if d.rlen <> 1 then begin
    e := d;
    e.w6 := 1;
    e.flags.b6 := true;
    if (d.rlen = 6) or (d.rlen = 7) then begin
      if cargs_$options.cpu * [0, 1] <> [] then begin
        e.rlen := 2;
        add_tn(18, addr(e), top, top);
        e.rlen := d.rlen;
        e.w6 := 2;
      end;
      add_tn(39, addr(e), top, top);
    end
    else
      add_tn(18, addr(e), top, top);
  end;
  extend_boolean := cexs_stack[top].node;
end;

{ build_not_expr - dest := !t's operand (t `!', 57): through any number
  of `== 0' of a `!' (each reversing), the operand lowered, pushed as
  a char, compared (add_tn 8 unless a `== 0' of class 6 can become 7)
  and negated (add_tn 7), extended to d's class, assigned (a tree of
  `=' built in the frame, build_assign).

  0x05E02A, 0x1A4 bytes, link #-360: the assignment tree at -344, the
  auxiliary descriptor at -48; the reversal flag in D2 (`not.b').

  Not known from the original:
  - the names. }

procedure build_not_expr(
    dest: il_$node_ptr_t;
    in d: c_desc_t;
    t: il_$node_ptr_t;
    parent: il_$node_ptr_t); options(val_param); internal;
var
  pos: boolean;
  n, o: c_tree_ptr_t;
  a: c_tree_t;
  aux: c_desc_t;
begin
  pos := true;
  n := c_tree_ptr_t(t);
  o := c_tree_ptr_t(n^.opnd[1]);
  while (o^.kind = 137) and then (o^.op = 12) and then
        (o^.desc.w8 = 6) and then
        ((o^.opnd[2]^.kind = 80) or (o^.opnd[2]^.kind = 82) or
         (o^.opnd[2]^.kind = 81)) and then
        (o^.opnd[2]^.int_value = 0) and then
        (o^.opnd[1]^.kind = 137) and then
        (c_tree_ptr_t(o^.opnd[1])^.op = 57) do begin
    pos := not pos;
    n := c_tree_ptr_t(o^.opnd[1]);
    o := c_tree_ptr_t(n^.opnd[1]);
  end;
  n^.opnd[1] := walk_tree(n^.opnd[1], parent, nil);
  a.kind := 137;
  a.op := 54;
  if (parent <> nil) and then (parent^.kind = 137) and then
     (c_tree_ptr_t(parent)^.op = 54) then
    a.w18 := c_tree_ptr_t(parent)^.w18
  else
    a.w18 := n^.w18;
  a.desc := d;
  a.count := 2;
  a.opnd[1] := dest;
  cexs_23bc := cexs_23bc + 1;
  with cexs_stack[cexs_23bc] do begin
    node := n^.opnd[1];
    type_exp(char_type, addr(typ));
    init_aux(addr(aux), addr(typ));
    if pos then begin
      if (node^.kind = 137) and (c_tree_ptr_t(node)^.op = 12) and
         (c_tree_ptr_t(node)^.desc.w8 = 6) then
        c_tree_ptr_t(node)^.desc.w8 := 7
      else
        add_tn(8, addr(aux), cexs_23bc, cexs_23bc);
    end;
  end;
  add_tn(7, addr(aux), cexs_23bc, cexs_23bc);
  a.opnd[2] := extend_boolean(d, cexs_23bc);
  cexs_23bc := cexs_23bc - 1;
  build_assign(a);
end;

{ build_cond_expr - dest := t, a conditional (51 `?:') or logical (52
  `&&', 53 `||') operator: branches on the condition (add_cbranch to
  the false label, sense true for `&&'), the true value assigned (the
  second operand lowered: for `?:' to a temporary unless the parent
  assignment is t's own left side, for the logical ones 1 unless the
  operand is itself a `== 0' of a logical operator), a branch to the
  end, the false label placed (0), the false value (`?:''s third
  operand lowered; 0 for `&&', 1 for `||', as a double, a single or an
  int by dest's class) assigned, the end placed (1).

  0x05E24A, 0x324 bytes, link #-368: the labels at -356 (false) and
  -352 (end), the assignment tree at -344, the auxiliary descriptor
  at -48, the sense at -360; the constants 0.0 and 1.0 after the
  routine (`pea (0x05E56E,PC)', dpcontk or rlcontk; docs/dpc-gaps.md
  7).  The pending operand trees are evaluated first (eval_tree_nodes).

  Not known from the original:
  - the names. }

procedure build_cond_expr(
    var dest: il_$node_ptr_t;
    in d: c_desc_t;
    t: il_$node_ptr_t;
    parent: il_$node_ptr_t); options(val_param); internal;
var
  flab, elab: il_$node_ptr_t;
  sense, skip: boolean;
  a: c_tree_t;
  aux: c_desc_t;
  tr, o: c_tree_ptr_t;

  { eval_tree_nodes - evaluate the operator nodes (137, 143) within n
    (through 145's two operands and 146, 147, 205's one) by their own
    evaluation nodes.

    0x05E1CE, 0x7C bytes, link #-8.

    Not known from the original:
    - the names. }

  procedure eval_tree_nodes(
      n: il_$node_ptr_t); options(val_param);
  begin
    case n^.kind of
      143, 137: begin
        cexs_23bc := cexs_23bc + 1;
        cexs_stack[cexs_23bc].node := n;
        add_eval(cexs_23bc, cexs_23bc);
        cexs_23bc := cexs_23bc - 1;
      end;
      146, 147, 205:
        eval_tree_nodes(n^.xp[6]);
      145: begin
        eval_tree_nodes(n^.xp[6]);
        eval_tree_nodes(n^.xp[9]);
      end;
      otherwise
    end;
  end;

begin
  flab := il_178;
  elab := il_178;
  tr := c_tree_ptr_t(t);
  if dest <> nil then
    eval_tree_nodes(dest);
  if tr^.op = 52 then
    sense := true
  else
    sense := false;
  add_cbranch(tr^.opnd[1], flab, sense);
  a.kind := 137;
  a.op := 54;
  if (parent <> nil) and then (parent^.kind = 137) and then
     (c_tree_ptr_t(parent)^.op = 54) then
    a.w18 := c_tree_ptr_t(parent)^.w18
  else
    a.w18 := tr^.w18;
  a.desc := d;
  a.count := 2;
  a.opnd[1] := dest;
  skip := false;
  if tr^.op <> 51 then begin
    o := c_tree_ptr_t(tr^.opnd[2]);
    if (o^.kind = 137) and (o^.op = 12) and (o^.desc.w8 = 6) and
       ((o^.opnd[2]^.kind = 80) or (o^.opnd[2]^.kind = 82) or
        (o^.opnd[2]^.kind = 81)) and
       (o^.opnd[2]^.int_value = 0) and
       (o^.opnd[1]^.kind = 137) and
       ((c_tree_ptr_t(o^.opnd[1])^.op = 52) or
        (c_tree_ptr_t(o^.opnd[1])^.op = 57) or
        (c_tree_ptr_t(o^.opnd[1])^.op = 53)) then
      skip := true;
  end;
  tr^.opnd[2] := walk_tree(tr^.opnd[2], parent, nil);
  if not skip then begin
    if tr^.op = 51 then begin
      a.opnd[2] := tr^.opnd[2];
      if not ((parent <> nil) and then (parent^.kind = 137) and then
              (c_tree_ptr_t(parent)^.opnd[2] = t)) then begin
        a.w18 := tr^.w18;
        dest := temp_alloc(tr^.desc.size, tr^.desc.rlen);
        a.opnd[1] := dest;
        a.desc := tr^.desc;
      end;
    end
    else begin
      cexs_23bc := cexs_23bc + 1;
      with cexs_stack[cexs_23bc] do begin
        node := tr^.opnd[2];
        type_exp(char_type, addr(typ));
        init_aux(addr(aux), addr(typ));
        if not ((node^.kind = 82) or (node^.kind = 81) or
                (node^.kind = 80)) then begin
          add_tn(7, addr(aux), cexs_23bc, cexs_23bc);
          a.opnd[2] := extend_boolean(d, cexs_23bc);
        end
        else if node^.int_value <> 0 then
          a.opnd[2] := smcontk(81, 1)
        else
          a.opnd[2] := node;
      end;
      cexs_23bc := cexs_23bc - 1;
    end;
    build_assign(a);
  end;
  add_brn(elab);
  add_ldfn(flab, 0, true, true);
  case tr^.op of
    53: if d.rlen = 7 then
          a.opnd[2] := dpcontk(0.0)
        else if d.rlen = 6 then
          a.opnd[2] := rlcontk(0.0)
        else
          a.opnd[2] := smcontk(81, 0);
    52: if d.rlen = 7 then
          a.opnd[2] := dpcontk(1.0)
        else if d.rlen = 6 then
          a.opnd[2] := rlcontk(1.0)
        else
          a.opnd[2] := smcontk(81, 1);
    51: begin
      tr^.opnd[3] := walk_tree(tr^.opnd[3], parent, nil);
      a.opnd[2] := tr^.opnd[3];
    end;
    otherwise
  end;
  build_assign(a);
  add_ldfn(elab, 1, true, true);
end;

{ only_logical - whether t computes only logical values: operators
  (137, 143) among 12, 18, 39, 51..55, 57 whose operands (from the
  second for `?:') are so; 145..147 and 205 by their operand; anything
  else true.

  0x05E57E, 0x9E bytes, link #-12: the operators' `in' a set of 0..63
  (`bgt'; docs/dpc-gaps.md 8); the result in D2.

  Not known from the original:
  - the names. }

function only_logical(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  i, first: integer;
begin
  r := true;
  case t^.kind of
    137, 143:
      if not (c_tree_ptr_t(t)^.op in [12, 18, 39, 51..55, 57]) then
        r := false
      else begin
        if c_tree_ptr_t(t)^.op = 51 then
          first := 2
        else
          first := 1;
        for i := first to c_tree_ptr_t(t)^.count do
          if not only_logical(c_tree_ptr_t(t)^.opnd[i]) then begin
            r := false;
            exit;
          end;
      end;
    145, 146, 147, 205:
      r := only_logical(t^.xp[6]);
    otherwise
  end;
  only_logical := r;
end;

{ find_post_opnd - the operand of t's post-increment (1, 2, 34, 35:
  the first operand), searching the operands (the last one's answer
  stands) and 145..147, 205's; il_178 for other kinds.

  0x05E624, 0xAC bytes, link #-12: the result left in A0 from the last
  recursive call (docs/rev889-patterns.md 32), undefined for an
  operator without operands.

  Not known from the original:
  - the names. }

function find_post_opnd(
    t: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  i: integer;
  r: il_$node_ptr_t;
begin
  case t^.kind of
    137, 143:
      if (c_tree_ptr_t(t)^.op = 1) or (c_tree_ptr_t(t)^.op = 2) or
         (c_tree_ptr_t(t)^.op = 35) or (c_tree_ptr_t(t)^.op = 34) then
        r := c_tree_ptr_t(t)^.opnd[1]
      else
        for i := 1 to c_tree_ptr_t(t)^.count do
          r := find_post_opnd(c_tree_ptr_t(t)^.opnd[i]);
    145: begin
      discard(find_post_opnd(t^.xp[6]));
      r := find_post_opnd(t^.xp[9]);
    end;
    146, 147, 205:
      r := find_post_opnd(t^.xp[6]);
    otherwise
      r := il_178;
  end;
  find_post_opnd := r;
end;

{ add_or_update - count one more post-increment of v (by incr) in the
  current statement's table.

  0x05E6D0, 0x80 bytes, link #-20; the module's data through the
  caller's A5; a new entry from new (pas_$new, 16 bytes;
  docs/dpc-gaps.md 3).

  Not known from the original:
  - the names; that a new entry does not count in total. }

procedure add_or_update(
    v: il_$node_ptr_t;
    incr: integer32); options(val_param); internal;
var
  prev, p: post_ptr_t;
begin
  with post_tab[post_depth] do begin
    prev := nil;
    p := list;
    while p <> nil do begin
      if v = p^.pvar then
        exit;
      prev := p;
      p := p^.next;
    end;
    if p <> nil then begin
      p^.count := p^.count + 1;
      total := total + 1;
    end
    else begin
      new(p);
      p^.next := nil;
      p^.pvar := v;
      p^.incr := incr;
      p^.count := 1;
      if prev <> nil then
        prev^.next := p
      else
        list := p;
    end;
  end;
end;

{ fix_post_id - within t, a variable incremented more than once in the
  statement gets the sum of its increments (incr * count, the count
  then one less): in a 147 over a 146 its displacement (+32), in a 146
  over a 13 operator the constant added (+44).

  0x05E750, 0x166 bytes, link #-20: a jump table over kinds 137..147;
  M$MIS$LLL for the product.

  Not known from the original:
  - the names. }

procedure fix_post_id(
    t: il_$node_ptr_t); options(val_param); internal;
var
  i: integer;
  a, v: il_$node_ptr_t;
  p: post_ptr_t;
begin
  with post_tab[post_depth] do begin
    if total <= 0 then
      return;
    case t^.kind of
      137, 143:
        for i := 1 to c_tree_ptr_t(t)^.count do
          fix_post_id(c_tree_ptr_t(t)^.opnd[i]);
      145: begin
        fix_post_id(t^.xp[6]);
        fix_post_id(t^.xp[9]);
      end;
      147: begin
        a := t^.xp[6];
        if a^.kind = 146 then begin
          v := a^.xp[6];
          p := list;
          while (p <> nil) and then (v <> p^.pvar) do
            p := p^.next;
          if (p <> nil) and then (p^.count > 1) then begin
            t^.xl[8] := p^.incr * p^.count;
            p^.count := p^.count - 1;
            total := total - 1;
          end;
        end;
        fix_post_id(t^.xp[6]);
      end;
      146: begin
        a := t^.xp[6];
        if (a^.kind = 137) and (c_tree_ptr_t(a)^.op = 13) then begin
          v := c_tree_ptr_t(a)^.opnd[1];
          p := list;
          while (p <> nil) and then (v <> p^.pvar) do
            p := p^.next;
          if (p <> nil) and then (p^.count > 1) then begin
            c_tree_ptr_t(t^.xp[6])^.opnd[2] :=
                smcontk(82, p^.incr * p^.count);
            p^.count := p^.count - 1;
            total := total - 1;
          end;
        end;
        fix_post_id(t^.xp[6]);
      end;
      otherwise
    end;
  end;
end;

{ walk_tree - see c_externs.ins.pas.  A statement (up nil, or an
  assignment `=', 54) gets its own post-increment table (128 deep:
  error_exit 'compiler stack overflow; post incr/decr'), summed into
  its variables (fix_post_id) and freed at the end.  By operator:
  `=' (54) its operands lowered (the right one under t when only
  logical), then an assignment built unless it is x = x (through
  conversions 18, 39); 55 (a post-increment `x = x + c') becomes an
  assignment, its value x's old value: under a 146 the increment is
  folded into the address (add_pn, add_dn; a large one through a 13
  operator), else the operand is evaluated first; 56 (the comma) its
  second operand; 51..53 and 57 an assignment to a temporary (or to
  the parent's left operand) through build_cond_expr or build_not_expr;
  16 (a call) call_s; 14 through a post-increment; 12 an assignment's
  conversion of a floating value (40 with 39); 68..70 (2 or 3
  operands, else diagnostic 313) an evaluation node of the stack's
  first entry; the others' operands (an address, 26, marks its
  variable: var_flags 12); 145, 146 (once: bit 11 of +6), 147, 205
  their operands.

  0x05E938, 0x92E bytes, link #-368: the result in D4; the type at
  -32, the auxiliary descriptor at -304 (-288 buildtreenode's
  operand), the parent passed on at -332, the kind at -336.  The
  dispatch is a compare chain over the kinds and then the operators
  (54, 55, 56, 53, 52, 57, 51, 16, 14, 12, 70, 68, 69).  The entry
  test tests D5 (`move.l (16,A6),D5'; the `movea.l' after it sets no
  flags).

  Not known from the original:
  - the names; that the 68..70 nodes evaluate the stack's first entry
    (`move.l 0x140440'); the gotos. }

function walk_tree;
var
  r, a: c_tree_ptr_t;
  res, par, tmp, n: il_$node_ptr_t;
  same, self_src: boolean;
  incr: integer32;
  k: integer;
  tt: type_exp_t;
  aux: c_desc_t;
  opl: array [1..64] of il_$node_ptr_t;
  p, q: post_ptr_t;
  i: integer;

  { is_post_incr_candidate - x is a 146 and y an increment `v = v + c'
    of a variable v by an integer constant c (137 55 over 109 and 137 1
    over a constant `in [77..87, 101, 200]', `ble').

    0x05E8B6, 0x82 bytes, link #-8; the result in D0. }

  function is_post_incr_candidate(
      x: il_$node_ptr_t;
      y: il_$node_ptr_t): boolean; options(val_param);
  begin
    is_post_incr_candidate := false;
    if x <> nil then
      if (x^.kind = 146) and (y^.kind = 137) and then
         (c_tree_ptr_t(y)^.op = 55) and then
         (c_tree_ptr_t(y)^.opnd[1]^.kind = 109) and then
         (c_tree_ptr_t(y)^.opnd[2]^.kind = 137) and then
         (c_tree_ptr_t(c_tree_ptr_t(y)^.opnd[2])^.op = 1) then
        if c_tree_ptr_t(c_tree_ptr_t(y)^.opnd[2])^.opnd[2]^.kind in [77..87, 101, 200] then
          is_post_incr_candidate := true;
  end;

begin
  if (up = nil) or ((t^.kind = 137) and (c_tree_ptr_t(t)^.op = 54)) then begin
    post_depth := post_depth + 1;
    if post_depth > 128 then
      error_exit(0, 'compiler stack overflow; post incr/decr', 39);
    post_tab[post_depth].list := nil;
    post_tab[post_depth].total := 0;
  end;
  res := t;
  r := c_tree_ptr_t(t);
  case t^.kind of
    137, 143:
      case r^.op of
        54: begin
          same := r^.opnd[1] = r^.opnd[2];
          self_src := false;
          a := c_tree_ptr_t(r^.opnd[2]);
          while (a^.kind = 137) and ((a^.op = 18) or (a^.op = 39)) do
            a := c_tree_ptr_t(a^.opnd[1]);
          if il_$node_ptr_t(a) = r^.opnd[1] then
            self_src := true;
          if only_logical(r^.opnd[2]) then
            par := t
          else
            par := parent;
          r^.opnd[1] := walk_tree(r^.opnd[1], parent, t);
          r^.opnd[2] := walk_tree(r^.opnd[2], par, t);
          k := r^.w18;
          if (k = 30) or (k = 29) then
            r^.opnd[3] := walk_tree(r^.opnd[3], par, t);
          if self_src then
            build_assign(r^)
          else if same or (r^.opnd[1] <> r^.opnd[2]) then begin
            a := c_tree_ptr_t(r^.opnd[2]);
            while (a^.kind = 137) and ((a^.op = 18) or (a^.op = 39)) do
              a := c_tree_ptr_t(a^.opnd[1]);
            if il_$node_ptr_t(a) <> r^.opnd[1] then
              build_assign(r^);
          end;
          res := r^.opnd[1];
        end;
        55: begin
          r^.opnd[1] := walk_tree(r^.opnd[1], parent, t);
          r^.opnd[2] := walk_tree(r^.opnd[2], parent, t);
          if r^.opnd[2] = r^.opnd[1] then begin
            build_assign(r^);
            res := r^.opnd[1];
          end
          else if is_post_incr_candidate(up, t) then begin
            build_assign(r^);
            a := c_tree_ptr_t(r^.opnd[2]);
            incr := -a^.opnd[2]^.int_value;
            type_exp(r^.opnd[1], addr(tt));
            add_or_update(a^.opnd[1], incr);
            if (incr < -32700) or (incr > 32700) then begin
              init_aux(addr(aux), addr(tt));
              aux.rlen := 5;
              aux.w6 := 4;
              aux.size := 0;
              cexs_23bc := cexs_23bc + 1;
              cexs_stack[cexs_23bc].node := a^.opnd[1];
              cexs_23bc := cexs_23bc + 1;
              cexs_stack[cexs_23bc].node := smcontk(81, incr);
              add_tn(13, addr(aux), cexs_23bc - 1, cexs_23bc);
              c_tree_ptr_t(cexs_stack[cexs_23bc].node)^.bits.post := true;
              n := cexs_stack[cexs_23bc].node;
              cexs_23bc := cexs_23bc - 1;
              incr := 0;
            end
            else
              n := a^.opnd[1];
            n := add_pn(n, a^.opnd[1], tt.flags.align, 0);
            if incr <> 0 then
              res := add_dn(n, integer32(n), incr)
            else
              res := n;
          end
          else begin
            cexs_23bc := cexs_23bc + 1;
            with cexs_stack[cexs_23bc] do begin
              node := find_post_opnd(r^.opnd[2]);
              aux := r^.desc;
              if (node^.kind = 137) and (c_tree_ptr_t(node)^.op = 14) then
                aux.rlen := c_tree_ptr_t(node)^.desc.rlen;
              add_tn(17, addr(aux), cexs_23bc, cexs_23bc);
              add_eval(cexs_23bc, cexs_23bc);
              res := node;
            end;
            cexs_23bc := cexs_23bc - 1;
            build_assign(r^);
          end;
        end;
        56: begin
          r^.opnd[1] := walk_tree(r^.opnd[1], parent, t);
          r^.opnd[2] := walk_tree(r^.opnd[2], parent, t);
          res := r^.opnd[2];
        end;
        53, 52, 57, 51: begin
          if parent <> nil then begin
            if parent^.kind = 137 then begin
              aux := c_tree_ptr_t(parent)^.desc;
              tmp := c_tree_ptr_t(parent)^.opnd[1];
            end
            else begin
              if r^.op = 51 then
                aux := r^.desc
              else begin
                type_exp(int_type, addr(tt));
                init_aux(addr(aux), addr(tt));
              end;
              tmp := parent;
            end;
          end
          else begin
            if r^.op = 51 then
              tmp := nil
            else begin
              type_exp(int_type, addr(tt));
              init_aux(addr(aux), addr(tt));
              tmp := temp_alloc(4, aux.rlen);
            end;
            parent := tmp;
          end;
          if r^.op = 57 then
            build_not_expr(tmp, aux, t, parent)
          else
            build_cond_expr(tmp, aux, t, parent);
          res := tmp;
        end;
        16: begin
          cexs_23bc := cexs_23bc + 1;
          cexs_stack[cexs_23bc].node := t;
          call_s;
          cexs_23bc := cexs_23bc - 1;
        end;
        14:
          if (r^.opnd[1]^.kind = 137) and
             (c_tree_ptr_t(r^.opnd[1])^.op = 55) then
            res := walk_tree(r^.opnd[1], parent, t)
          else
            r^.opnd[1] := walk_tree(r^.opnd[1], parent, t);
        12: begin
          r^.opnd[1] := walk_tree(r^.opnd[1], parent, t);
          r^.opnd[2] := walk_tree(r^.opnd[2], parent, t);
          if (parent <> nil) and then (parent^.kind = 137) and then
             (c_tree_ptr_t(parent)^.op = 54) and then
             (c_tree_ptr_t(parent)^.opnd[1] = r^.opnd[1]) and then
             (r^.desc.w6 <> c_tree_ptr_t(parent)^.desc.rlen) then begin
            aux := r^.desc;
            r^.desc.size := c_tree_ptr_t(parent)^.desc.size;
            k := c_tree_ptr_t(parent)^.desc.rlen;
            r^.desc.w6 := k;
            if (k = 7) or (k = 6) then begin
              r^.op := 40;
              opl[1] := r^.opnd[2];
              aux.w6 := aux.rlen;
              aux.rlen := c_tree_ptr_t(parent)^.desc.rlen;
              r^.opnd[2] := buildtreenode(39, addr(aux), addr(opl), 1);
              c_tree_ptr_t(r^.opnd[2])^.w16 := 0;
            end;
          end;
        end;
        70, 68, 69: begin
          if r^.op = 70 then begin
            if r^.count = 3 then begin
              r^.opnd[1] := walk_tree(r^.opnd[1], parent, t);
              r^.opnd[2] := walk_tree(r^.opnd[2], parent, t);
              r^.opnd[3] := walk_tree(r^.opnd[3], parent, t);
            end
            else begin
              error0(313, lex_line);
              r^.count := 3;
              r^.opnd[1] := il_178;
              r^.opnd[2] := il_178;
              r^.opnd[3] := il_178;
            end;
          end
          else if r^.op = 68 then begin
            if r^.count = 2 then begin
              r^.opnd[1] := walk_tree(r^.opnd[1], parent, t);
              r^.opnd[2] := walk_tree(r^.opnd[2], parent, t);
            end
            else begin
              error0(313, lex_line);
              r^.count := 2;
              r^.opnd[1] := il_178;
              r^.opnd[2] := il_178;
            end;
          end
          else
            r^.opnd[1] := walk_tree(r^.opnd[1], parent, t);
          n := add_top_node(139, 56);
          c_top_ptr_t(n)^.eval_opnd[1] := cexs_stack[1].node;
          adjust_uc(n, 1);
          delay_$shrink_top_level_node(n);
        end;
        otherwise
          for i := 1 to r^.count do begin
            if r^.op = 26 then begin
              n := r^.opnd[i];
              if n^.kind = 109 then
                c_sym_ptr_t(n)^.var_flags := c_sym_ptr_t(n)^.var_flags + [12]
              else if (n^.kind = 147) and then (n^.xp[6]^.kind = 109) then
                c_sym_ptr_t(n^.xp[6])^.var_flags :=
                    c_sym_ptr_t(n^.xp[6])^.var_flags + [12]
              else if (n^.kind = 146) and then (n^.xp[6]^.kind = 109) and then
                      (c_sym_ptr_t(n^.xp[6])^.var_vat = vat_param) then
                c_sym_ptr_t(n^.xp[6])^.var_flags :=
                    c_sym_ptr_t(n^.xp[6])^.var_flags + [12];
            end;
            r^.opnd[i] := walk_tree(r^.opnd[i], parent, t);
          end;
      end;
    145: begin
      t^.xp[6] := walk_tree(t^.xp[6], parent, t);
      t^.xp[9] := walk_tree(t^.xp[9], nil, t);
    end;
    146:
      if r^.bits.done then
        res := t^.xp[6]
      else if is_post_incr_candidate(t, t^.xp[6]) then begin
        res := walk_tree(t^.xp[6], parent, t);
        t^.xp[6] := res;
        r^.bits.done := true;
      end
      else
        t^.xp[6] := walk_tree(t^.xp[6], parent, t);
    147, 205:
      t^.xp[6] := walk_tree(t^.xp[6], parent, t);
    otherwise
  end;
  if (up = nil) or ((t^.kind = 137) and (c_tree_ptr_t(t)^.op = 54)) then begin
    if post_tab[post_depth].total > 0 then
      fix_post_id(t);
    p := post_tab[post_depth].list;
    while p <> nil do begin
      q := p;
      p := p^.next;
      dispose(q);
    end;
    post_depth := post_depth - 1;
  end;
  walk_tree := res;
end;
