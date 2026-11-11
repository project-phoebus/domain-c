{ opt_vector - the vector idioms of C loops (opt_on 19): a counted loop
  (a branch 142 back to a label of class 10 on index <= limit, the
  index a register variable) whose body is one assignment of doubles
  or singles (rlen 7 or 6) to an array element indexed by the loop's
  index is replaced by a call of a run-time library routine
  (std_lib_rtns): a copy, an initialization, a zeroing, an addition or
  subtraction of two vectors, the addition or multiplication of a
  constant, a multiply-add, and the reductions sum and dot into a
  scalar.  The loop's statements are unlinked, the call put in the
  loop's mark (an evaluation) and the index given its final value
  (the trip count).

  Image addresses (DOMAIN C 6.9):
    cc.m68k   cc.a88k
    0x094208  0x095BE8  opt_vec_$obj_is_float_const
    0x09423E  0x095C1E  get_increment
    0x0942B0  0x095C90  prolog
    0x094322  0x095D02  epilog
    0x094544  0x095F24  opt_vec_$copy_vector
    0x094662  0x096042  opt_vec_$init_vector
    0x094780  0x096160  opt_vec_$zero_vector
    0x094898  0x096278  sum
    0x094AC4  0x0964A4  dot
    0x094C70  0x096650  mult_add
    0x094E7C  0x09685C  addconst
    0x094FDE  0x0969BE  mult_constant
    0x095140  0x096B20  addvector
    0x095268  0x096C48  subvector
    0x095390  0x096D70  bad_dindex
    0x09556C  0x096F4C  compare_disp
    0x095612  0x096FF2  compare_dindex
    0x0956B8  0x097098  process_candidate
    0x0967C0  0x0981A0  opt_vec_$process_loop
    0x096854  0x098234  opt_vec_$process_routine
    A5 0x19CCC4 (cc.m68k), 0x31CD34 (cc.a88k): the module's data: +20
    the index assignment's width (a word), +24 a byte set when the
    indexing is a strided one (bad_dindex; mult_add calls the strided
    routines then); +0..+19 not addressed.

  process_loop and process_routine load A5; the others do not and are
  internal (they run on process_loop's A5: bad_dindex sets +24,
  mult_add reads it).  No caller of process_routine was found in
  cc.m68k (its address is not taken by an instruction either).

  The unit does not open g_opt.ins.pas: statements and trees are read
  through the views ov_stmt_t and ov_tree_t below (g_opt.ins.pas's
  layouts) and other nodes by offset.  inline_$mark_reference_params
  (opt_inline.pas, no insert this unit opens) is declared here.

  The transforms' library routines (std_lib_rtns, by the element's
  width 6 or 7): copy 46/47, init 48/49, zero 52/53, sum 42/43, dot
  44/45, mult_add 34/35 (strided 156/157), addconst 26/27,
  mult_constant 38/39, addvector 30/31, subvector 50/51.

  The unit opens cg.ins.pas before codegen.ins.pas (globals.ins.pas's
  codegen_uads_declared lets either declare the descriptor type).

  dpc gaps (docs/dpc-gaps.md): 7 (a comparison with 0.0), 8 (`in' on
  the node kind sets).
}
module opt_vector;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include '/sys/ins/base.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/delay.ins.pas';

type
  { A top-level statement (g_opt.ins.pas's g_opt_stmt_t): 139 an
    evaluation, 140 an assignment (op 11 a plain store of asg_desc's
    class), 142 a conditional branch, 144 a label (+72 bits 5..1 its
    class), 148 a call; flags at +41 (b7 no line report, b5 an
    assignment the front end made for a loop's index). }
  ov_stmt_ptr_t = ^ov_stmt_t;
  ov_stmt_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    prev: ov_stmt_ptr_t;                { +4 }
    next: ov_stmt_ptr_t;                { +8 }
    unused_12: array [3..4] of integer32;  { +12 }
    line: integer;                      { +20 }
    unused_22: array [11..19] of integer;  { +22..+39 }
    hdr: packed record                  { +40 }
      b40: char;
      b7, b6, b5, b4, b3, b2, b1, b0: boolean;  { +41 }
      b42: char;                        { +42 }
      b43: char;                        { +43 }
    end;
    unused_44: array [22..23] of integer;  { +44 }
    case integer of
      1: (eval_unused_48: integer;      { +48 }
          eval_count: integer;          { +50 }
          eval_opnd: array [1..64] of il_$node_ptr_t);  { +52 }
      2: (asg_desc: add_node_$desc_t;   { +48: rlen at +52 }
          asg_lhs: il_$node_ptr_t;      { +64 }
          asg_rhs: il_$node_ptr_t;      { +68 }
          asg_x: il_$node_ptr_t;        { +72 }
          asg_op: integer);             { +76 }
      3: (br_target: ov_stmt_ptr_t;     { +48 }
          br_unused_52: integer32;      { +52 }
          br_cond: il_$node_ptr_t);     { +56 }
      4: (x48: il_$node_ptr_t);         { +48: a call's routine }
  end;

  { A tree node (g_opt.ins.pas's g_opt_tree_t): an operator (137, 143:
    op 34 addition, 35 subtraction, 36 multiplication; opnd), a
    reference (145, 146, 147: base at +24, +28, index at +36, by
    offset). }
  ov_tree_ptr_t = ^ov_tree_t;
  ov_tree_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    flags: set of 0..31;                { +4 }
    unused_8: integer32;                { +8 }
    unused_12: integer32;               { +12 }
    uses: integer;                      { +16 }
    unused_18: integer;                 { +18 }
    desc: add_node_$desc_t;             { +20 }
    op: integer;                        { +36 }
    count: integer;                     { +38 }
    opnd: array [1..64] of il_$node_ptr_t;  { +40 }
  end;

  { A statement's or tree's +4..+15 (compare_disp, compare_dindex: a
    12-byte comparison). }
  ov_head_t = record
    a, b, c: integer32;
  end;
  ov_head_ptr_t = ^ov_head_t;

  ov_ops_t = array [1..9] of il_$node_ptr_t;

  { An operand's alias descriptor in process_candidate's frame (24
    bytes apart; docs/questions.md 90). }
  ov_desc_t = record
    d: alias_$desc_t;
    unused_20: integer32;
  end;

var
  unused_0: array [0..4] of integer32;  { +0 }
  width: integer;                       { +20 }
  unused_22: integer;                   { +22 }
  strided: boolean;                     { +24 }

{ INLINE_$MARK_REFERENCE_PARAMS - opt_inline.pas 0x08F49A (cc.a88k
  0x090E7A): the parameters call t passes by reference, of statement
  s. }
procedure inline_$mark_reference_params(
    t: il_$node_ptr_t;
    s: univ_ptr); options(val_param); extern;

define
  opt_vec_$process_loop, opt_vec_$process_routine;

{ opt_vec_$obj_is_float_const - t is a real constant (88, 89), a
  register variable (110) or the contents (146) of one.

  0x094208, 0x36 bytes, no frame: the result in D0. }

function opt_vec_$obj_is_float_const(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if (t^.kind = 88) or (t^.kind = 110) or (t^.kind = 89) then
    opt_vec_$obj_is_float_const := true
  else if t^.kind = 146 then
    opt_vec_$obj_is_float_const := t^.xp[6]^.kind = 110
  else
    opt_vec_$obj_is_float_const := false;
end;

{ get_increment - the step between the elements an indexing (145)
  through a pointer variable (110) reaches: 1 for an array of one
  dimension... (the type's +6 count 1), else the type's span (its +24
  - +12 + 1, an integer constant 82) when its +32 bit 7 is set, or
  its +36; nil otherwise.

  0x09423E, 0x72 bytes: the result in A0. }

function get_increment(
    t: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r: il_$node_ptr_t;
  d: il_$node_ptr_t;
begin
  r := nil;
  if t <> nil then
    if t^.kind = 145 then
      if t^.xp[7] <> nil then
        if t^.xp[7]^.kind = 110 then begin
          d := t^.xp[7]^.xp[8];
          if d^.xw[3] = 1 then
            r := smcontk(82, 1)
          else if (d^.xw[3] & 16#FFFF) > 1 then
            if (ord(d^.xc[32]) & 16#80) <> 0 then
              r := smcontk(82, d^.xl[6] - d^.xl[3] + 1)
            else
              r := d^.xp[9];
        end;
  get_increment := r;
end;

{ prolog - the loop's parts the transforms use: from the loop's head
  branch s, its index's step (the assignment before s) and start (the
  one before that); the statement before the closing branch x; the
  start's descriptor, as a 4-byte integer.

  0x0942B0, 0x72 bytes: body, lhs and a not read; the start's
  operand's +64 copied to a local not read. }

procedure prolog(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t;
    out a: il_$node_ptr_t;
    out step: il_$node_ptr_t;
    out start: il_$node_ptr_t;
    out xp: ov_stmt_ptr_t;
    out d: add_node_$desc_t); options(val_param); internal;
var
  unused: il_$node_ptr_t;
begin
  start := s^.prev^.prev^.asg_rhs;
  step := s^.prev^.asg_rhs;
  xp := x^.prev;
  d := s^.prev^.asg_desc;
  unused := start^.xp[16];
  d.size := 4;
  d.rlen := 4;
end;

{ epilog - after the call was made in the loop's mark m: the call kept
  (flag 12, its +24 cleared); the loop's statements unlinked (the
  statement after the mark linked to the index's last assignment,
  before the closing branch, and that to what follows the loop), the
  index's assignment made a plain store of the trip count (start + 1,
  of the start's class), at the line of the nearest statement with
  one, and the note cgerr 52 unless that statement is marked b7.

  0x094322, 0x1BC bytes, link #-304: m by address; the start's kinds
  of the 26-byte sets after the routine (constants: 77..90, 92, 93,
  101, 156, 176, 198, 200; trees and variables: 110, 137, 146, 147,
  205), else bug_check with the message after them. }

procedure epilog(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t;
    out a: il_$node_ptr_t;
    var m: ov_stmt_ptr_t;
    start: il_$node_ptr_t;
    xp: ov_stmt_ptr_t); options(val_param); internal;
var
  n: ov_stmt_ptr_t;
  c: il_$node_ptr_t;
  ops: ov_ops_t;
  d: add_node_$desc_t;
  p: ov_stmt_ptr_t;
begin
  if m^.kind = 139 then begin
    ov_tree_ptr_t(m^.eval_opnd[1])^.desc.rlen := 0;
    ov_tree_ptr_t(m^.eval_opnd[1])^.flags :=
      ov_tree_ptr_t(m^.eval_opnd[1])^.flags + [12];
  end;
  n := m^.next;
  n^.next := x^.prev^.prev;
  n^.next^.prev := n;
  n^.next^.next := x^.next^.next;
  x^.next^.next^.prev := n^.next;
  n := n^.next;
  n^.asg_op := 0;
  if start^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then
    c := smcontk(81, start^.int_value + 1)
  else if start^.kind in [110, 137, 146, 147, 205] then begin
    ops[1] := delay_$splice(copy_tree(start), 4, true,
                            s^.prev^.prev^.asg_desc.rlen, false);
    ops[2] := smcontk(81, 1);
    d := s^.prev^.prev^.asg_desc;
    c := buildtreenode(1, d, ops, 2);
    ov_tree_ptr_t(c)^.uses := 0;
    il_utils_$adjust_uc(c, 1);
  end
  else
    bug_check('vector_transform: bad kind for loop_trip_count%.');
  n^.asg_rhs := delay_$splice(c, n^.asg_desc.rlen, false,
                              xp^.asg_desc.rlen, false);
  p := s;
  while p^.line = spos_$null_position do
    p := p^.prev;
  m^.line := p^.line;
  if not p^.hdr.b7 then
    cgerr(52, p^.line, nil);
end;

{ opt_vec_$copy_vector - a[i] := b[i]: the call (operator 15) of the
  copy routine with b, a and the trip count.

  0x094544, 0x11E bytes, link #-316: the mark (the evaluation two
  after s) given one operand; the count a copy of the start converted
  to 4 bytes (delay_$splice); the call's use count 0, the mark's
  counts raised (il_utils_$adjust_uc). }

procedure opt_vec_$copy_vector(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  ops: ov_ops_t;
  m: ov_stmt_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  m := s^.next^.next;
  m^.eval_count := 1;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[46]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[47];
  ops[2] := body^.asg_rhs;
  ops[3] := body^.asg_lhs;
  ops[4] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  m^.eval_opnd[1] := buildtreenode(15, body^.asg_desc, ops, 4);
  ov_tree_ptr_t(m^.eval_opnd[1])^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(m), 1);
  tmp := m;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(tmp^.eval_opnd[1], tmp);
end;

{ opt_vec_$init_vector - a[i] := c: the init routine with a, the count
  and c.

  0x094662, 0x11E bytes: as copy_vector. }

procedure opt_vec_$init_vector(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  ops: ov_ops_t;
  m: ov_stmt_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  m := s^.next^.next;
  m^.eval_count := 1;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[48]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[49];
  ops[2] := body^.asg_lhs;
  ops[3] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  ops[4] := body^.asg_rhs;
  m^.eval_opnd[1] := buildtreenode(15, body^.asg_desc, ops, 4);
  ov_tree_ptr_t(m^.eval_opnd[1])^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(m), 1);
  tmp := m;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(tmp^.eval_opnd[1], tmp);
end;

{ opt_vec_$zero_vector - a[i] := 0.0: the zero routine with a and the
  count.

  0x094780, 0x118 bytes: as copy_vector. }

procedure opt_vec_$zero_vector(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  ops: ov_ops_t;
  m: ov_stmt_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  m := s^.next^.next;
  m^.eval_count := 1;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[52]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[53];
  ops[2] := body^.asg_lhs;
  ops[3] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  m^.eval_opnd[1] := buildtreenode(15, body^.asg_desc, ops, 3);
  ov_tree_ptr_t(m^.eval_opnd[1])^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(m), 1);
  tmp := m;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(tmp^.eval_opnd[1], tmp);
end;

{ sum - acc := acc + a[i]: the mark replaced by a new assignment (op
  11, 80 bytes from gspace, its +4..+45 copied from the mark, of the
  body's variable and descriptor, marked b5) of acc plus (operator 34)
  the sum routine's result (operator 16) on a and the count; acc the
  accumulator operand (a contents of, or, a register variable) or the
  whole right side.

  0x094898, 0x22C bytes, link #-572: prolog's call pops 34 of its 36
  bytes (docs/rev889-patterns.md 11). }

procedure sum(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
type
  head_t = array [1..21] of integer;    { +4..+45 }
  head_ptr_t = ^head_t;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  g: ov_stmt_ptr_t;
  ops: ov_ops_t;
  ops2: ov_ops_t;
  o2: il_$node_ptr_t;
  acc: il_$node_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  g := gspace(80);
  g^.kind := 140;
  g^.asg_op := 11;
  head_ptr_t(addr(g^.prev))^ := head_ptr_t(addr(s^.next^.next^.prev))^;
  s^.next^.next := g;
  g^.next^.prev := g;
  g^.asg_lhs := body^.asg_lhs;
  g^.asg_desc := body^.asg_desc;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[42]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[43];
  acc := body^.asg_rhs;
  o2 := ov_tree_ptr_t(acc)^.opnd[2];
  if o2^.kind = 145 then
    ops[2] := o2
  else if (o2^.kind = 147) and (o2^.xp[6]^.kind = 145) then
    ops[2] := o2
  else
    ops[2] := ov_tree_ptr_t(acc)^.opnd[1];
  if o2^.kind = 146 then
    if o2^.xp[6]^.kind = 110 then
      acc := o2;
  if ov_tree_ptr_t(body^.asg_rhs)^.opnd[1]^.kind = 146 then
    if ov_tree_ptr_t(body^.asg_rhs)^.opnd[1]^.xp[6]^.kind = 110 then
      acc := ov_tree_ptr_t(body^.asg_rhs)^.opnd[1];
  if o2^.kind = 110 then
    acc := o2;
  if ov_tree_ptr_t(body^.asg_rhs)^.opnd[1]^.kind = 110 then
    acc := ov_tree_ptr_t(body^.asg_rhs)^.opnd[1];
  ops[3] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  ops2[1] := buildtreenode(16, body^.asg_desc, ops, 3);
  ops2[2] := acc;
  g^.asg_rhs := buildtreenode(34, body^.asg_desc, ops2, 2);
  ov_tree_ptr_t(ops2[1])^.uses := 0;
  ov_tree_ptr_t(g^.asg_rhs)^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(g), 1);
  g^.hdr.b5 := true;
  tmp := g;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(ops2[1], tmp);
end;

{ dot - acc := acc + a[i] * b[i]: as sum, the dot routine's result
  (operator 16) on a, b and the count added to acc (the right side's
  second operand).

  0x094AC4, 0x1AC bytes, link #-572: the operands' array reused for
  the addition. }

procedure dot(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
type
  head_t = array [1..21] of integer;    { +4..+45 }
  head_ptr_t = ^head_t;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  g: ov_stmt_ptr_t;
  ops: ov_ops_t;
  mm: il_$node_ptr_t;
  t: il_$node_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  g := gspace(80);
  g^.kind := 140;
  g^.asg_op := 11;
  head_ptr_t(addr(g^.prev))^ := head_ptr_t(addr(s^.next^.next^.prev))^;
  s^.next^.next := g;
  g^.next^.prev := g;
  g^.asg_lhs := body^.asg_lhs;
  g^.asg_desc := body^.asg_desc;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[44]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[45];
  mm := ov_tree_ptr_t(body^.asg_rhs)^.opnd[1];
  ops[2] := ov_tree_ptr_t(mm)^.opnd[1];
  ops[3] := ov_tree_ptr_t(mm)^.opnd[2];
  ops[4] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  t := buildtreenode(16, body^.asg_desc, ops, 4);
  ov_tree_ptr_t(t)^.uses := 0;
  ops[1] := ov_tree_ptr_t(body^.asg_rhs)^.opnd[2];
  ops[2] := t;
  g^.asg_rhs := buildtreenode(34, body^.asg_desc, ops, 2);
  ov_tree_ptr_t(g^.asg_rhs)^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(g), 1);
  g^.hdr.b5 := true;
  tmp := g;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(ops[2], tmp);
end;

{ mult_add - a[i] := b[i] + c * d[i]: the multiply-add routine with b,
  d, the count, c and a; for a strided indexing (strided) the strided
  routine, each vector followed by its step (get_increment).

  0x094C70, 0x20C bytes, link #-316: strided read through the
  caller's A5 (+24). }

procedure mult_add(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  ops: ov_ops_t;
  m: ov_stmt_ptr_t;
  r: il_$node_ptr_t;
  n: integer;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  m := s^.next^.next;
  m^.eval_count := 1;
  if body^.asg_desc.rlen = 6 then begin
    if strided then
      ops[1] := std_lib_rtns[156]
    else
      ops[1] := std_lib_rtns[34];
  end
  else if body^.asg_desc.rlen = 7 then begin
    if strided then
      ops[1] := std_lib_rtns[157]
    else
      ops[1] := std_lib_rtns[35];
  end;
  r := body^.asg_rhs;
  if not strided then begin
    ops[2] := ov_tree_ptr_t(r)^.opnd[2];
    ops[3] := ov_tree_ptr_t(ov_tree_ptr_t(r)^.opnd[1])^.opnd[1];
    ops[4] := delay_$splice(copy_tree(start), 4, true,
                            s^.prev^.prev^.asg_desc.rlen, false);
    ops[5] := ov_tree_ptr_t(ov_tree_ptr_t(body^.asg_rhs)^.opnd[1])^.opnd[2];
    ops[6] := body^.asg_lhs;
    n := 6;
  end
  else begin
    ops[2] := ov_tree_ptr_t(r)^.opnd[2];
    ops[3] := get_increment(ov_tree_ptr_t(r)^.opnd[2]^.xp[6]);
    ops[4] := ov_tree_ptr_t(ov_tree_ptr_t(body^.asg_rhs)^.opnd[1])^.opnd[1];
    ops[5] := get_increment(ov_tree_ptr_t(ov_tree_ptr_t(body^.asg_rhs)^.opnd[1])^.opnd[1]^.xp[6]);
    ops[6] := delay_$splice(copy_tree(start), 4, true,
                            s^.prev^.prev^.asg_desc.rlen, false);
    ops[7] := ov_tree_ptr_t(ov_tree_ptr_t(body^.asg_rhs)^.opnd[1])^.opnd[2];
    ops[8] := body^.asg_lhs;
    ops[9] := get_increment(body^.asg_lhs^.xp[6]);
    n := 9;
  end;
  m^.eval_opnd[1] := buildtreenode(15, body^.asg_desc, ops, n);
  ov_tree_ptr_t(m^.eval_opnd[1])^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(m), 1);
  tmp := m;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(tmp^.eval_opnd[1], tmp);
end;

{ addconst - a[i] := b[i] + c: the routine with b, the count, c and a
  (b the operand that is an element, 147 of a 145).

  0x094E7C, 0x162 bytes, link #-316. }

procedure addconst(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  ops: ov_ops_t;
  m: ov_stmt_ptr_t;
  r: il_$node_ptr_t;
  o1: il_$node_ptr_t;
  o2: il_$node_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  m := s^.next^.next;
  m^.eval_count := 1;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[26]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[27];
  r := body^.asg_rhs;
  o1 := ov_tree_ptr_t(r)^.opnd[1];
  if (o1^.kind = 147) and (o1^.xp[6]^.kind = 145) then begin
    ops[2] := o1;
    ops[4] := ov_tree_ptr_t(r)^.opnd[2];
  end
  else begin
    o2 := ov_tree_ptr_t(r)^.opnd[2];
    if (o2^.kind = 147) and (o2^.xp[6]^.kind = 145) then begin
      ops[2] := o2;
      ops[4] := o1;
    end;
  end;
  ops[3] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  ops[5] := body^.asg_lhs;
  m^.eval_opnd[1] := buildtreenode(15, body^.asg_desc, ops, 5);
  ov_tree_ptr_t(m^.eval_opnd[1])^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(m), 1);
  tmp := m;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(tmp^.eval_opnd[1], tmp);
end;

{ mult_constant - a[i] := b[i] * c: as addconst, the multiplication
  routine.

  0x094FDE, 0x162 bytes, link #-316. }

procedure mult_constant(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  ops: ov_ops_t;
  m: ov_stmt_ptr_t;
  r: il_$node_ptr_t;
  o1: il_$node_ptr_t;
  o2: il_$node_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  m := s^.next^.next;
  m^.eval_count := 1;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[38]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[39];
  r := body^.asg_rhs;
  o1 := ov_tree_ptr_t(r)^.opnd[1];
  if (o1^.kind = 147) and (o1^.xp[6]^.kind = 145) then begin
    ops[2] := o1;
    ops[4] := ov_tree_ptr_t(r)^.opnd[2];
  end
  else begin
    o2 := ov_tree_ptr_t(r)^.opnd[2];
    if (o2^.kind = 147) and (o2^.xp[6]^.kind = 145) then begin
      ops[2] := o2;
      ops[4] := o1;
    end;
  end;
  ops[3] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  ops[5] := body^.asg_lhs;
  m^.eval_opnd[1] := buildtreenode(15, body^.asg_desc, ops, 5);
  ov_tree_ptr_t(m^.eval_opnd[1])^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(m), 1);
  tmp := m;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(tmp^.eval_opnd[1], tmp);
end;

{ addvector - a[i] := b[i] + c[i]: the routine with b, c, the count
  and a.

  0x095140, 0x128 bytes, link #-316. }

procedure addvector(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  ops: ov_ops_t;
  m: ov_stmt_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  m := s^.next^.next;
  m^.eval_count := 1;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[30]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[31];
  ops[2] := ov_tree_ptr_t(body^.asg_rhs)^.opnd[1];
  ops[3] := ov_tree_ptr_t(body^.asg_rhs)^.opnd[2];
  ops[4] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  ops[5] := body^.asg_lhs;
  m^.eval_opnd[1] := buildtreenode(15, body^.asg_desc, ops, 5);
  ov_tree_ptr_t(m^.eval_opnd[1])^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(m), 1);
  tmp := m;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(tmp^.eval_opnd[1], tmp);
end;

{ subvector - a[i] := b[i] - c[i]: as addvector, the subtraction
  routine.

  0x095268, 0x128 bytes, link #-312. }

procedure subvector(
    var body: ov_stmt_ptr_t;
    lhs: il_$node_ptr_t;
    s: ov_stmt_ptr_t;
    x: ov_stmt_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  step: il_$node_ptr_t;
  start: il_$node_ptr_t;
  xp: ov_stmt_ptr_t;
  d: add_node_$desc_t;
  ops: ov_ops_t;
  m: ov_stmt_ptr_t;
  tmp: ov_stmt_ptr_t;
begin
  prolog(body, lhs, s, x, a, step, start, xp, d);
  m := s^.next^.next;
  m^.eval_count := 1;
  if body^.asg_desc.rlen = 6 then
    ops[1] := std_lib_rtns[50]
  else if body^.asg_desc.rlen = 7 then
    ops[1] := std_lib_rtns[51];
  ops[2] := ov_tree_ptr_t(body^.asg_rhs)^.opnd[1];
  ops[3] := ov_tree_ptr_t(body^.asg_rhs)^.opnd[2];
  ops[4] := delay_$splice(copy_tree(start), 4, true,
                          s^.prev^.prev^.asg_desc.rlen, false);
  ops[5] := body^.asg_lhs;
  m^.eval_opnd[1] := buildtreenode(15, body^.asg_desc, ops, 5);
  ov_tree_ptr_t(m^.eval_opnd[1])^.uses := 0;
  il_utils_$adjust_uc(il_$node_ptr_t(m), 1);
  tmp := m;
  epilog(body, lhs, s, x, a, tmp, start, xp);
  inline_$mark_reference_params(tmp^.eval_opnd[1], tmp);
end;

{ bad_dindex - the indexing t (145) is not by the loop's index v: its
  index (+36) is v, the contents of v (147), or v added to (operators
  27, 18, 3) something; a strided index (27 of (3 of v and an integer
  constant) plus (1) a constant, through a pointer variable (110), or
  the like through a register temporary marked 14) sets strided and
  counts as good.

  0x095390, 0x1C2 bytes: the result in D0 (`st' at entry); the
  operators 27, 18, 3 tested together (`seq'/`or.b'); the constants
  of the 26-byte set after the routine (77..87, 101, 200).

  Not known from the original:
  - what the operators 27, 18, 3 and 1 are (scale, index, ...). }

function bad_dindex(
    v: il_$node_ptr_t;
    t: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  i: il_$node_ptr_t;
  a: il_$node_ptr_t;
  k: integer;
  b: il_$node_ptr_t;
  c: il_$node_ptr_t;
begin
  r := true;
  if t <> nil then
    if t^.kind = 145 then
      if t^.xp[9] = v then
        r := false
      else begin
        i := t^.xp[9];
        if i^.kind = 147 then begin
          if i^.xp[6] = v then
            r := false;
        end
        else if i^.kind = 137 then
          if (ov_tree_ptr_t(i)^.op = 27) or (ov_tree_ptr_t(i)^.op = 18) or
             (ov_tree_ptr_t(i)^.op = 3) then
            if ov_tree_ptr_t(i)^.opnd[1] = v then
              r := false
            else begin
              a := ov_tree_ptr_t(i)^.opnd[1];
              k := a^.kind;
              if (k = 147) or (k = 146) then begin
                if a^.xp[6] = v then
                  r := false;
              end
              else begin
                if ov_tree_ptr_t(i)^.op = 27 then
                  if k = 137 then
                    if ov_tree_ptr_t(a)^.op = 1 then
                      if ov_tree_ptr_t(a)^.opnd[2]^.kind in [77..87, 101, 200] then begin
                        b := ov_tree_ptr_t(a)^.opnd[1];
                        if b^.kind = 137 then
                          if ov_tree_ptr_t(b)^.op = 3 then
                            if ov_tree_ptr_t(b)^.opnd[1] = v then
                              if ov_tree_ptr_t(b)^.opnd[2]^.kind in [77..87, 101, 200] then
                                if t^.xp[7]^.kind = 110 then begin
                                  strided := true;
                                  r := false;
                                end;
                      end;
                if r then begin
                  i := t^.xp[9];
                  if ov_tree_ptr_t(i)^.op = 27 then
                    if k = 137 then begin
                      a := ov_tree_ptr_t(i)^.opnd[1];
                      if ov_tree_ptr_t(a)^.op = 1 then
                        if ov_tree_ptr_t(a)^.opnd[2]^.kind in [77..87, 101, 200] then begin
                          b := ov_tree_ptr_t(a)^.opnd[1];
                          if b^.kind = 137 then
                            if ov_tree_ptr_t(b)^.op = 3 then begin
                              c := ov_tree_ptr_t(b)^.opnd[1];
                              if c^.kind = 137 then begin
                                b := ov_tree_ptr_t(b)^.opnd[2];
                                if b^.kind = 110 then
                                  if (b^.xw[13] & 16#4000) <> 0 then
                                    if ov_tree_ptr_t(c)^.op = 1 then
                                      if ov_tree_ptr_t(c)^.opnd[1] = v then
                                        if ov_tree_ptr_t(c)^.opnd[2]^.kind in [77..87, 101, 200] then begin
                                          strided := true;
                                          r := false;
                                        end;
                              end;
                            end;
                        end;
                    end;
                end;
              end;
            end;
      end;
  bad_dindex := r;
end;

{ compare_disp - references a and b (147) are the same: the same node,
  or the same +4..+15, +16, +28, +32 and kind of base (+24), and with
  same the same base.

  0x09556C, 0xA6 bytes: same a byte by value; the result in D0. }

function compare_disp(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t;
    same: boolean): boolean; options(val_param); internal;
begin
  compare_disp := false;
  if a <> nil then
    if b <> nil then
      if (a^.kind = 147) and (b^.kind = 147) then
        if a = b then
          compare_disp := true
        else if ov_head_ptr_t(addr(a^.xl[1]))^ = ov_head_ptr_t(addr(b^.xl[1]))^ then
          if a^.xw[8] = b^.xw[8] then
            if a^.xp[7] = b^.xp[7] then
              if a^.xl[8] = b^.xl[8] then
                if a^.xp[6] <> nil then
                  if b^.xp[6] <> nil then
                    if a^.xp[6]^.kind = b^.xp[6]^.kind then
                      if not same or (a^.xp[6] = b^.xp[6]) then
                        compare_disp := true;
end;

{ compare_dindex - indexings a and b (145) are the same but for their
  indexes: the same node, or the same +4..+15, +16, +28, +32, +40,
  +42 and kind of index (+36).

  0x095612, 0xA6 bytes: the result in D0 (the last test `seq'). }

function compare_dindex(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  compare_dindex := false;
  if a <> nil then
    if b <> nil then
      if (a^.kind = 145) and (b^.kind = 145) then
        if a = b then
          compare_dindex := true
        else if ov_head_ptr_t(addr(a^.xl[1]))^ = ov_head_ptr_t(addr(b^.xl[1]))^ then
          if a^.xw[8] = b^.xw[8] then
            if a^.xp[7] = b^.xp[7] then
              if a^.xl[8] = b^.xl[8] then
                if a^.xw[20] = b^.xw[20] then
                  if a^.xw[21] = b^.xw[21] then
                    if a^.xp[9] <> nil then
                      if b^.xp[9] <> nil then
                        compare_dindex := a^.xp[9]^.kind = b^.xp[9]^.kind;
end;

{ process_candidate - the loop headed by branch s (its index
  assignments, b5, before it; its mark, an empty evaluation, and its
  label after it; the closing branch x back to that label) whose body
  is one store (140, op 11) of doubles or singles: classify the store
  (the kinds below), check that the vectors are indexed by the loop's
  index (bad_dindex) and do not overlap the result (alias_$related,
  unless the trees are the same, il_utils_$trees_equivalent above
  1), that the index's last assignment and the closing branch follow
  (a label of class 11 between them skipped), then transform: 1
  addconst, 2 addvector, 3 mult_add, 4 mult_constant, 5 sum, 6 dot,
  7 copy, 8 init, 9 subvector, 10 zero; only mult_add when strided.

  0x0956B8, 0x1108 bytes, link #-124: s in D6, x in D7; the kind in D1
  and a jump table of 11 entries (0 none); the index's width and the
  real constant's zero test (inline fpp_$ words 0x0074, 0xFF34);
  descriptors at -88, -64, -40 (24 bytes apart); trees_equivalent's
  result compared with 1 (`bls'); an addition with the product second
  turned round (its operands swapped), a product with the constant
  first likewise; a store whose right side's first operand matches no
  form reaches the dispatch with that operand's kind as the transform
  (no case: nothing done, written here as 0).

  Not known from the original:
  - the transforms' numbering (an enumeration, perhaps) and how the
    shared tails were written (gotos here). }

procedure process_candidate(
    s: ov_stmt_ptr_t); options(val_param); internal;
label
  9, 99;
var
  x: ov_stmt_ptr_t;
  p: ov_stmt_ptr_t;
  lhs: il_$node_ptr_t;
  st: ov_stmt_ptr_t;
  body: ov_stmt_ptr_t;
  ref: il_$node_ptr_t;
  da: ov_desc_t;
  db: ov_desc_t;
  dc: ov_desc_t;
  t1: il_$node_ptr_t;
  t2: il_$node_ptr_t;
  t3: il_$node_ptr_t;
  r: il_$node_ptr_t;
  a: il_$node_ptr_t;
  o: il_$node_ptr_t;
  k: integer;
  kind: integer;
  b1: boolean;
begin
  strided := false;
  x := s;
  repeat
    x := x^.next;
  until (x^.kind = 142) and (x^.br_target = s^.next^.next^.next);
  if not s^.prev^.hdr.b5 then
    return;
  p := x^.prev^.prev;
  if p^.kind <> 140 then
    return;
  if not p^.hdr.b5 then
    if p^.asg_lhs = s^.prev^.asg_lhs then
      return;
  lhs := s^.prev^.asg_lhs;
  a := p^.asg_rhs;
  width := s^.prev^.asg_desc.rlen;
  if (width & 16#FFFF) > 4 then
    return;
  if not (a^.kind in [77..87, 101, 200]) then
    return;
  if a^.int_value <> 1 then
    return;
  if lhs^.kind <> 110 then
    return;
  k := ord(lhs^.xc[10]) & 15;
  if not (k in [1..3]) then
    return;
  st := s^.next;
  if st^.kind <> 140 then
    return;
  if st^.asg_lhs^.kind <> 110 then
    return;
  if (st^.asg_lhs^.xw[13] & 16#200) = 0 then
    return;
  st := st^.next;
  if st^.kind <> 139 then
    return;
  if st^.eval_count <> 0 then
    return;
  st := st^.next;
  if st^.kind <> 144 then
    return;
  st := st^.next;
  if st^.kind <> 140 then
    return;
  if st^.asg_op <> 11 then
    return;
  if not ((st^.asg_desc.rlen = 7) or (st^.asg_desc.rlen = 6)) then
    return;
  body := st;

  { The store to an element. }
  a := st^.asg_lhs;
  if a^.kind = 145 then
    ref := a
  else if (a^.kind = 147) and (a^.xp[6]^.kind = 145) then
    ref := a^.xp[6]
  else
    goto 99;
  if bad_dindex(lhs, ref) then
    return;
  if st^.asg_op <> 11 then
    goto 99;

  { Copy, init, zero: a[i] := b[i] or a constant. }
  if opt_vec_$obj_is_float_const(st^.asg_rhs) then begin
    if st^.asg_lhs <> st^.asg_rhs then begin
      alias_$basic_alias_desc(st^.asg_lhs, da.d);
      alias_$basic_alias_desc(st^.asg_rhs, db.d);
      if alias_$related(da.d, db.d) then
        return;
    end;
    r := st^.asg_rhs;
    kind := 8;
    if (r^.kind = 89) or (r^.kind = 88) then
      if r^.real_value = 0.0 then
        kind := 10;
    goto 9;
  end;
  r := st^.asg_rhs;
  if r^.kind = 147 then
    if r^.xp[6]^.kind = 145 then
      if not bad_dindex(lhs, r^.xp[6]) then begin
        if st^.asg_lhs <> st^.asg_rhs then
          if il_utils_$trees_equivalent(st^.asg_lhs, st^.asg_rhs) > 1 then begin
            alias_$basic_alias_desc(st^.asg_lhs, da.d);
            alias_$basic_alias_desc(st^.asg_rhs, db.d);
            if alias_$related(da.d, db.d) then
              return;
          end;
        kind := 7;
        goto 9;
      end;
  if r^.kind <> 137 then
    return;

  { mult_constant: a[i] := b[i] * c or c * b[i]. }
  if ov_tree_ptr_t(r)^.op = 36 then
    if ov_tree_ptr_t(r)^.opnd[1]^.kind = 147 then
      if opt_vec_$obj_is_float_const(ov_tree_ptr_t(r)^.opnd[2]) then
        if not bad_dindex(lhs, ov_tree_ptr_t(r)^.opnd[1]^.xp[6]) then
          if ov_tree_ptr_t(r)^.opnd[1]^.xp[6]^.kind = 145 then begin
            o := ov_tree_ptr_t(r)^.opnd[1];
            if o <> st^.asg_lhs then
              if il_utils_$trees_equivalent(st^.asg_lhs, o) > 1 then begin
                alias_$basic_alias_desc(st^.asg_lhs, da.d);
                alias_$basic_alias_desc(ov_tree_ptr_t(st^.asg_rhs)^.opnd[1], db.d);
                if alias_$related(da.d, db.d) then
                  return;
              end;
            kind := 4;
            goto 9;
          end;
  r := st^.asg_rhs;
  if ov_tree_ptr_t(r)^.op = 36 then
    if ov_tree_ptr_t(r)^.opnd[2]^.kind = 147 then
      if ov_tree_ptr_t(r)^.opnd[2]^.xp[6]^.kind = 145 then
        if not bad_dindex(lhs, ov_tree_ptr_t(r)^.opnd[2]^.xp[6]) then
          if opt_vec_$obj_is_float_const(ov_tree_ptr_t(r)^.opnd[1]) then begin
            o := ov_tree_ptr_t(r)^.opnd[2];
            if st^.asg_lhs <> o then
              if il_utils_$trees_equivalent(st^.asg_lhs, o) > 1 then begin
                alias_$basic_alias_desc(st^.asg_lhs, da.d);
                alias_$basic_alias_desc(ov_tree_ptr_t(st^.asg_rhs)^.opnd[2], db.d);
                if alias_$related(da.d, db.d) then
                  return;
              end;
            kind := 4;
            goto 9;
          end;

  { subvector: a[i] := b[i] - c[i]. }
  r := st^.asg_rhs;
  if ov_tree_ptr_t(r)^.op = 35 then
    if ov_tree_ptr_t(r)^.opnd[1]^.kind = 147 then
      if ov_tree_ptr_t(r)^.opnd[1]^.xp[6]^.kind = 145 then
        if ov_tree_ptr_t(r)^.opnd[2]^.kind = 147 then
          if ov_tree_ptr_t(r)^.opnd[2]^.xp[6]^.kind = 145 then
            if not bad_dindex(lhs, ov_tree_ptr_t(r)^.opnd[2]^.xp[6]) then
              if not bad_dindex(lhs, ov_tree_ptr_t(r)^.opnd[1]^.xp[6]) then begin
                t1 := st^.asg_lhs;
                t2 := ov_tree_ptr_t(r)^.opnd[1];
                t3 := ov_tree_ptr_t(r)^.opnd[2];
                alias_$basic_alias_desc(t1, da.d);
                alias_$basic_alias_desc(t2, db.d);
                alias_$basic_alias_desc(t3, dc.d);
                b1 := true;
                if (t1^.kind = 147) and (t1^.xp[6]^.kind = 145) then
                  if il_utils_$trees_equivalent(t1, t2) <= 1 then
                    b1 := false;
                if b1 then
                  if alias_$related(da.d, db.d) then
                    return;
                b1 := true;
                if (t1^.kind = 147) and (t1^.xp[6]^.kind = 145) then
                  if il_utils_$trees_equivalent(t1, t3) <= 1 then
                    b1 := false;
                if b1 then
                  if alias_$related(da.d, dc.d) then
                    return;
                if (t1 = t2) or (t1 = t3) then begin
                  b1 := true;
                  if (t2^.kind = 147) and (t2^.xp[6]^.kind = 145) then
                    if il_utils_$trees_equivalent(t2, t3) <= 1 then
                      b1 := false;
                  if b1 then
                    if alias_$related(dc.d, db.d) then
                      return;
                end;
                kind := 9;
                goto 9;
              end;

  { The additions. }
  r := st^.asg_rhs;
  if ov_tree_ptr_t(r)^.op <> 34 then
    return;
  { addvector: a[i] := b[i] + c[i]. }
  if ov_tree_ptr_t(r)^.opnd[1]^.kind = 147 then
    if ov_tree_ptr_t(r)^.opnd[1]^.xp[6]^.kind = 145 then
      if ov_tree_ptr_t(r)^.opnd[2]^.kind = 147 then
        if ov_tree_ptr_t(r)^.opnd[2]^.xp[6]^.kind = 145 then
          if not bad_dindex(lhs, ov_tree_ptr_t(r)^.opnd[1]^.xp[6]) then
            if not bad_dindex(lhs, ov_tree_ptr_t(r)^.opnd[2]^.xp[6]) then begin
              t1 := st^.asg_lhs;
              t2 := ov_tree_ptr_t(r)^.opnd[1];
              t3 := ov_tree_ptr_t(r)^.opnd[2];
              alias_$basic_alias_desc(t1, da.d);
              alias_$basic_alias_desc(t2, db.d);
              alias_$basic_alias_desc(t3, dc.d);
              b1 := true;
              if (t1^.kind = 147) and (t1^.xp[6]^.kind = 145) then
                if il_utils_$trees_equivalent(t1, t2) <= 1 then
                  b1 := false;
              if b1 then
                if alias_$related(da.d, db.d) then
                  return;
              b1 := true;
              if (t1^.kind = 147) and (t1^.xp[6]^.kind = 145) then
                if il_utils_$trees_equivalent(t1, t3) <= 1 then
                  b1 := false;
              if b1 then
                if alias_$related(da.d, dc.d) then
                  return;
              if (t1 = t2) or (t1 = t3) then begin
                b1 := true;
                if (t2^.kind = 147) and (t2^.xp[6]^.kind = 145) then
                  if il_utils_$trees_equivalent(t2, t3) <= 1 then
                    b1 := false;
                if b1 then
                  if alias_$related(dc.d, db.d) then
                    return;
              end;
              kind := 2;
              goto 9;
            end;
  { addconst: a[i] := b[i] + c. }
  r := st^.asg_rhs;
  if ov_tree_ptr_t(r)^.opnd[1]^.kind = 147 then
    if ov_tree_ptr_t(r)^.opnd[1]^.xp[6]^.kind = 145 then
      if opt_vec_$obj_is_float_const(ov_tree_ptr_t(r)^.opnd[2]) then
        if not bad_dindex(lhs, ov_tree_ptr_t(r)^.opnd[1]^.xp[6]) then begin
          t1 := st^.asg_lhs;
          b1 := true;
          if (t1^.kind = 147) and (t1^.xp[6]^.kind = 145) then
            if il_utils_$trees_equivalent(t1, ov_tree_ptr_t(r)^.opnd[1]) <= 1 then
              b1 := false;
          if b1 then begin
            alias_$basic_alias_desc(ov_tree_ptr_t(st^.asg_rhs)^.opnd[1], da.d);
            alias_$basic_alias_desc(st^.asg_lhs, db.d);
            if alias_$related(da.d, db.d) then
              return;
          end;
          kind := 1;
          goto 9;
        end;

  { mult_add: a[i] := b[i] + c * d[i] (the product turned first). }
  r := st^.asg_rhs;
  if r^.kind = 137 then
    if ov_tree_ptr_t(r)^.op = 34 then
      if ov_tree_ptr_t(r)^.opnd[2]^.kind = 137 then
        if ov_tree_ptr_t(ov_tree_ptr_t(r)^.opnd[2])^.op = 36 then begin
          o := ov_tree_ptr_t(r)^.opnd[2];
          ov_tree_ptr_t(r)^.opnd[2] := ov_tree_ptr_t(r)^.opnd[1];
          ov_tree_ptr_t(st^.asg_rhs)^.opnd[1] := o;
        end;
  r := st^.asg_rhs;
  a := ov_tree_ptr_t(r)^.opnd[1];
  if a^.kind <> 137 then
    return;
  if ov_tree_ptr_t(a)^.op <> 36 then
    return;
  o := ov_tree_ptr_t(r)^.opnd[2];
  k := o^.kind;
  if not ((k = 147) or (k = 145)) then
    return;
  if k = 147 then begin
    if o^.xp[6]^.kind <> 145 then
      return;
    if bad_dindex(lhs, o^.xp[6]) then
      return;
  end;
  o := ov_tree_ptr_t(st^.asg_rhs)^.opnd[2];
  if o^.kind = 145 then
    if bad_dindex(lhs, o) then
      return;
  a := ov_tree_ptr_t(st^.asg_rhs)^.opnd[1];
  o := ov_tree_ptr_t(a)^.opnd[1];
  if (o^.kind = 147) and (o^.xp[6]^.kind = 145) then begin
    if bad_dindex(lhs, o^.xp[6]) then
      return;
    if not opt_vec_$obj_is_float_const(ov_tree_ptr_t(a)^.opnd[2]) then
      return;
  end
  else begin
    o := ov_tree_ptr_t(a)^.opnd[2];
    if o^.kind <> 147 then
      return;
    if o^.xp[6]^.kind <> 145 then
      return;
    if bad_dindex(lhs, o^.xp[6]) then
      return;
    if not opt_vec_$obj_is_float_const(ov_tree_ptr_t(a)^.opnd[1]) then
      return;
    o := ov_tree_ptr_t(a)^.opnd[2];
    ov_tree_ptr_t(a)^.opnd[2] := ov_tree_ptr_t(a)^.opnd[1];
    ov_tree_ptr_t(a)^.opnd[1] := o;
  end;
  t1 := st^.asg_lhs;
  t2 := ov_tree_ptr_t(st^.asg_rhs)^.opnd[2];
  t3 := ov_tree_ptr_t(ov_tree_ptr_t(st^.asg_rhs)^.opnd[1])^.opnd[1];
  alias_$basic_alias_desc(t1, da.d);
  alias_$basic_alias_desc(t2, db.d);
  alias_$basic_alias_desc(t3, dc.d);
  if t1 <> nil then
    if (t1^.kind = 145) or (t1^.kind = 146) or (t1^.kind = 205) or
       (t1^.kind = 147) then
      if t1^.xp[6] <> nil then
        if t1^.xp[6]^.kind <> 145 then
          return;
  if (t2^.kind = 147) and (t2 <> t1) then
    if not compare_disp(t1, t2, false) then
      if not compare_dindex(t1^.xp[6], t2^.xp[6]) then
        if il_utils_$trees_equivalent(t1^.xp[6]^.xp[9], t2^.xp[6]^.xp[9]) > 1 then
          if alias_$related(da.d, db.d) then
            return;
  if (t2^.kind = 145) and (t2 <> t1) then
    if not compare_disp(t1, t2, false) then
      if not compare_dindex(t1^.xp[6], t2^.xp[6]) then
        if il_utils_$trees_equivalent(t1^.xp[6]^.xp[9], t2^.xp[9]) > 1 then
          if alias_$related(da.d, db.d) then
            return;
  if t3 <> t1 then
    if not compare_disp(t1, t3, false) then
      if not compare_dindex(t1^.xp[6], t3^.xp[6]) then
        if il_utils_$trees_equivalent(t1^.xp[6]^.xp[9], t3^.xp[6]^.xp[9]) > 1 then
          if alias_$related(da.d, dc.d) then
            return;
  if (il_utils_$trees_equivalent(t1, t2) <= 1) or
     (il_utils_$trees_equivalent(t1, t3) <= 1) then begin
    if t2^.kind = 147 then
      if not (compare_disp(t2, t3, false) or
              compare_dindex(t2^.xp[6], t3^.xp[6])) then
        if il_utils_$trees_equivalent(t2, t3) > 1 then
          if alias_$related(db.d, dc.d) then
            return;
    if t2^.kind = 145 then
      if not compare_disp(t2, t3, false) then
        if not compare_dindex(t2^.xp[6], t3^.xp[6]) then
          if il_utils_$trees_equivalent(t2^.xp[9], t3^.xp[6]^.xp[9]) > 1 then
            if alias_$related(db.d, dc.d) then
              return;
  end;
  kind := 3;
  goto 9;

  { The reductions: acc := acc + ... (a scalar, 146 of a 110, or a
    110). }
99:
  if st^.asg_op <> 11 then
    return;
  a := st^.asg_lhs;
  k := a^.kind;
  if not ((k = 146) or (k = 110)) then
    return;
  if k = 146 then
    if a^.xp[6]^.kind <> 110 then
      return;
  r := st^.asg_rhs;
  if r^.kind <> 137 then
    return;
  if ov_tree_ptr_t(r)^.op <> 34 then
    return;
  o := ov_tree_ptr_t(r)^.opnd[1];
  k := o^.kind;
  if (k = 146) or (k = 110) then begin
    { sum: acc + b[i]. }
    if o <> a then
      return;
    if k = 146 then
      if o^.xp[6]^.kind <> 110 then
        return;
    o := ov_tree_ptr_t(r)^.opnd[2];
    if o^.kind <> 147 then
      return;
    if o^.xp[6]^.kind <> 145 then
      return;
    if bad_dindex(lhs, o^.xp[6]) then
      return;
    alias_$basic_alias_desc(st^.asg_lhs, da.d);
    alias_$basic_alias_desc(ov_tree_ptr_t(st^.asg_rhs)^.opnd[2], db.d);
    if alias_$related(da.d, db.d) then
      return;
    kind := 5;
    goto 9;
  end;
  if (k = 147) and (o^.xp[6]^.kind = 145) then begin
    { sum: b[i] + acc. }
    if bad_dindex(lhs, o^.xp[6]) then
      return;
    o := ov_tree_ptr_t(st^.asg_rhs)^.opnd[2];
    k := o^.kind;
    if not ((k = 146) or (k = 110)) then begin
      kind := 0;
      goto 9;
    end;
    if k = 146 then
      if o^.xp[6]^.kind <> 110 then
        return;
    if o <> st^.asg_lhs then begin
      if k <> 146 then
        return;
      if st^.asg_lhs^.kind <> 146 then
        return;
      if o^.xp[6] <> st^.asg_lhs^.xp[6] then
        return;
    end;
    alias_$basic_alias_desc(st^.asg_lhs, da.d);
    alias_$basic_alias_desc(ov_tree_ptr_t(st^.asg_rhs)^.opnd[1], db.d);
    if alias_$related(da.d, db.d) then
      return;
    kind := 5;
    goto 9;
  end;
  { dot: b[i] * c[i] + acc. }
  if k <> 137 then
    return;
  if ov_tree_ptr_t(o)^.op <> 36 then
    return;
  t2 := ov_tree_ptr_t(o)^.opnd[1];
  if t2^.kind <> 147 then
    return;
  if t2^.xp[6]^.kind <> 145 then
    return;
  t3 := ov_tree_ptr_t(o)^.opnd[2];
  if t3^.kind <> 147 then
    return;
  if t3^.xp[6]^.kind <> 145 then
    return;
  if bad_dindex(lhs, t2^.xp[6]) then
    return;
  if bad_dindex(lhs, ov_tree_ptr_t(ov_tree_ptr_t(st^.asg_rhs)^.opnd[1])^.opnd[2]^.xp[6]) then
    return;
  o := ov_tree_ptr_t(st^.asg_rhs)^.opnd[2];
  k := o^.kind;
  if not ((k = 146) or (k = 110)) then
    return;
  if k = 146 then
    if o^.xp[6]^.kind <> 110 then
      return;
  if o <> st^.asg_lhs then begin
    if k <> 146 then
      return;
    if st^.asg_lhs^.kind <> 146 then
      return;
    if o^.xp[6] <> st^.asg_lhs^.xp[6] then
      return;
  end;
  t1 := st^.asg_lhs;
  o := ov_tree_ptr_t(st^.asg_rhs)^.opnd[1];
  t2 := ov_tree_ptr_t(o)^.opnd[1];
  t3 := ov_tree_ptr_t(o)^.opnd[2];
  alias_$basic_alias_desc(t1, da.d);
  alias_$basic_alias_desc(t2, db.d);
  alias_$basic_alias_desc(t3, dc.d);
  if alias_$related(da.d, db.d) then
    return;
  if alias_$related(da.d, dc.d) then
    return;
  kind := 6;

  { The loop's end: the index's last assignment and the closing
    branch. }
9:
  if strided and (kind <> 3) then
    return;
  st := st^.next;
  if st^.kind = 144 then
    if rshft(ord(il_$node_ptr_t(st)^.xc[72]) & 16#3E, 1) = 11 then
      st := st^.next;
  if st^.kind <> 140 then
    return;
  if not st^.hdr.b5 then
    return;
  if st^.asg_lhs <> lhs then
    return;
  st := st^.next;
  if st^.kind <> 140 then
    return;
  if st^.asg_lhs^.kind <> 110 then
    return;
  if (st^.asg_lhs^.xw[13] & 16#200) = 0 then
    return;
  st := st^.next;
  if x <> st then
    return;
  case kind of
    3: mult_add(body, lhs, s, x);
    6: dot(body, lhs, s, x);
    5: sum(body, lhs, s, x);
    1: addconst(body, lhs, s, x);
    2: addvector(body, lhs, s, x);
    4: mult_constant(body, lhs, s, x);
    9: subvector(body, lhs, s, x);
    7: opt_vec_$copy_vector(body, lhs, s, x);
    8: opt_vec_$init_vector(body, lhs, s, x);
    10: opt_vec_$zero_vector(body, lhs, s, x);
    otherwise
  end;
end;

{ opt_vec_$process_loop - under opt_on 19, in a C routine: s a branch
  (142) on an `<=' (143, op 12) of a register variable (110 marked 14
  and 9) to a label of class 10 is a candidate.

  0x0967C0, 0x94 bytes: b (true from process_routine) not read. }

procedure opt_vec_$process_loop(
    s: il_$node_ptr_t;
    b: boolean); options(val_param);
var
  c: il_$node_ptr_t;
  l: il_$node_ptr_t;
begin
  if 19 in cargs_$options.opt_on then
    if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
      if s^.kind = 142 then begin
        c := ov_stmt_ptr_t(s)^.br_cond;
        if c^.kind = 143 then
          if ov_tree_ptr_t(c)^.op = 12 then begin
            l := il_$node_ptr_t(ov_stmt_ptr_t(s)^.br_target);
            if l^.kind = 144 then
              if rshft(ord(l^.xc[72]) & 16#3E, 1) = 10 then begin
                c := ov_tree_ptr_t(c)^.opnd[1];
                if c^.kind = 110 then
                  if (c^.xw[13] & 16#4000) <> 0 then
                    if (c^.xw[13] & 16#200) <> 0 then
                      process_candidate(ov_stmt_ptr_t(s));
              end;
          end;
      end;
end;

{ opt_vec_$process_routine - under opt_on 19, each branch (142) of the
  top-level statements (from il_d4) is put through process_loop; a
  call (148) of a routine (not 172 or 167) makes it the current
  routine (il_180), and the walk ends at a routine not in C.

  0x096854, 0x7E bytes: 172 and 167 tested together. }

procedure opt_vec_$process_routine;
var
  s: il_$node_ptr_t;
  r: il_$node_ptr_t;
begin
  if 19 in cargs_$options.opt_on then begin
    s := il_d4;
    while s <> nil do begin
      if s^.kind = 148 then begin
        r := ov_stmt_ptr_t(s)^.x48;
        if not ((r^.kind = 172) or (r^.kind = 167)) then begin
          il_180 := r;
          if rshft(ord(r^.xc[377]) & 16#70, 4) <> 2 then
            return;
        end;
      end;
      if s^.kind = 142 then
        opt_vec_$process_loop(s, true);
      s := il_$node_ptr_t(ov_stmt_ptr_t(s)^.next);
    end;
  end;
end;
