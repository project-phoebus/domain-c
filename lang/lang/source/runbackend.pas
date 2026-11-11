{ runbackend - RUN_BACKEND, the compilation after the front end: the
  back end's set-up, the call graph (which routines call which, from
  the top-level statements and the static initializers), the routines
  nobody calls deleted, the inline expansion, the IL normalized for the
  optimizer, then each routine optimized (g_opt) and coded (codegen;
  under a cleanup handler unless -X debug bits 0..2 are set, so that a
  failure in one routine is reported and the next one is coded), and
  last the final pass and the object module.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries,
  only the addresses of what it calls differ):
    cc.m68k   cc.a88k
    0x0B08DC  0x0B22BC  assert_is_a_tree_node
    0x0B08FE  0x0B22DE  assert_is_a_call_node
    0x0B0930  0x0B2310  assert_is_a_callable_block
    0x0B0966  0x0B2346  assert_is_fortran_array
    0x0B0984  0x0B2364  routine_reference_class
    0x0B0A5A  0x0B243A  is_routine_reference_addr_con
    0x0B0AD4  0x0B24B4  check_fdata
    0x0B0AFC  0x0B24DC  check_static_initializations
    0x0B0B42  0x0B2522  unconditionally_add_call_graph_edge
    0x0B0BD8  0x0B25B8  add_call_graph_edge
    0x0B0CB6  0x0B2696  detect_fortran_param_scalarity_mismatches
    0x0B0E50  0x0B2830  analyze_call_site_for_call_graph
    0x0B0F48  0x0B2928  build_call_graph_walk_il
    0x0B14E8  0x0B2EC8  build_call_graph_walk_block
    0x0B1582  0x0B2F62  build_call_graph
    0x0B15FC  0x0B2FDC  assert_is_inlineable_utility_routine_in_include_file
    0x0B1644  0x0B3024  delete_unreferenced_blocks
    0x0B174A  0x0B312A  assert_is_useless_disp
    0x0B17BA  0x0B319A  normalize_il
    0x0B1E70  0x0B3850  optimize_and_code
    0x0B20BE  0x0B3A9E  optimize_and_code_depth_first
    0x0B213E  0x0B3B1E  set_local_call_bits
    0x0B21FE  0x0B3BDE  adjust_disps_of_formals_for_fcw
    0x0B22CC  0x0B3CAC  run_backend
    A5 0x2C33B0 (cc.m68k), 0x443420 (cc.a88k): the module's data, laid
    out the same in both: +0x0 the top-level statement being walked,
    +0x4 the statement a call graph edge records (set from kinds 148
    and 149), +0x8..+0x16 the cells other units read
    (globals_from_backend.ins.pas), +0x18 fourteen words .rwdi
    initializes (0, 1, 2, 4, 6, 7, 8, 9, 1, 2, 4, 5, 0, 12) that
    other units read (runbackend_18: cg_call's alias_size_expand, the
    optimizer's add_range and add_con_range), +0x34 whether a routine has bit 7 of +376 set
    (set_local_call_bits), +0x36 whether coding a routine failed, +0x38
    the last source line normalize_il met (a longword; cgerr is passed
    its low word).  .rwdi also clears +0xC..+0x13.  prtobj.pas's
    routines load this A5 too (it has no data).

  run_backend is the only global routine; the others do not load A5
  (internal) and run on run_backend's.

  The blocks (kinds 105, 107, 108, 167, 172, 209) and the tree nodes
  are read by offset (il.ins.pas's views); a block's call graph edges
  (36 bytes from gspace) are rb_edge_t, reached through the block's
  +244 (first edge out), +248 (last edge out) and +252 (edges in).

  Not known from the original: every name but the routines' and the
  messages'; the edges' fields; the table at +0x18.
}
module runbackend;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'lang/lang/source/condcomp.ins.pas';
%include 'lang/lang/source/list_tree.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/commit_top_node.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include '/sys/ins/pfm.ins.pas';
%include '/sys/ins/errlog.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'lang/lang/source/unix_objmod.ins.pas';

type
  { The address of a call's operand slot (add_call_graph_edge keeps
    the address it is passed), and a list of them (8 bytes from
    gspace). }
  rb_site_ptr_t = ^il_$node_ptr_t;
  rb_site_list_ptr_t = ^rb_site_list_t;
  rb_site_list_t = record
    site: rb_site_ptr_t;                { +0 }
    next: rb_site_list_ptr_t;           { +4 }
  end;

  { A call graph edge (36 bytes from gspace). }
  rb_edge_ptr_t = ^rb_edge_t;
  rb_edge_t = record
    callee: il_$node_ptr_t;             { +0: the block called }
    ref: il_$node_ptr_t;                { +4: the node that names it }
    caller: il_$node_ptr_t;             { +8 }
    ref_stmt: il_$node_ptr_t;           { +12: module +0x4 }
    call: il_$node_ptr_t;               { +16: the call (or reference) }
    stmt: il_$node_ptr_t;               { +20: the statement (module +0x0) }
    sites: rb_site_list_ptr_t;          { +24: kind 16 calls' slots }
    callee_next: rb_edge_ptr_t;         { +28: the callee's edges in }
    caller_next: rb_edge_ptr_t;         { +32: the caller's edges out }
  end;

  { A block's nesting level, the signed byte at +294 (`move.b; ext.w'). }
  rb_level_ptr_t = ^rb_level_t;
  rb_level_t = packed record
    pad: packed array [0..293] of char;
    level: -128..127;                   { +294 }
  end;

define
  runbackend_08;                        { +0x8 }
  runbackend_0c := nil;                 { +0xC }
  runbackend_10 := nil;                 { +0x10 }
  runbackend_14;                        { +0x14 }
  runbackend_16;                        { +0x16 }
  runbackend_18 := [0, 1, 2, 4, 6, 7, 8, 9, 1, 2, 4, 5, 0, 12];  { +0x18 }

var
  cur_stmt: il_$node_ptr_t;             { +0x0 }
  ref_stmt: il_$node_ptr_t;             { +0x4 }
  fcw_seen: boolean;                    { +0x34 }
  backend_failed: boolean;              { +0x36 }
  last_line: integer32;                 { +0x38 }

procedure build_call_graph_walk_block(
    b: il_$node_ptr_t); options(val_param); internal; forward;

{ assert_is_a_tree_node - n is a tree node (kinds 143, 137).

  0x0B08DC, 0x22 bytes, no frame (docs/rev889-patterns.md 16): n at
  (4,SP); `seq; seq; or.b'. }

function assert_is_a_tree_node(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    assert_is_a_tree_node := (n^.kind = 143) or (n^.kind = 137)
  else
    assert_is_a_tree_node := false;
end;

{ assert_is_a_call_node - n is a tree node of operator 16 or 15 (+36).

  0x0B08FE, 0x32 bytes. }

function assert_is_a_call_node(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_a_tree_node(n) then
    assert_is_a_call_node := (n^.xw[18] = 16) or (n^.xw[18] = 15)
  else
    assert_is_a_call_node := false;
end;

{ assert_is_a_callable_block - n is a block that can be called (kinds
  167, 108, 107, 105).

  0x0B0930, 0x36 bytes, no frame. }

function assert_is_a_callable_block(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    assert_is_a_callable_block := (n^.kind = 167) or (n^.kind = 108) or
        (n^.kind = 107) or (n^.kind = 105)
  else
    assert_is_a_callable_block := false;
end;

{ assert_is_fortran_array - n is a Fortran symbol (110) with +32 set.

  0x0B0966, 0x1E bytes, no frame: the nil and kind tests branch to one
  `clr.b'; `tst.l (32,A0); sne'. }

function assert_is_fortran_array(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_fortran_array := false
  else if n^.kind <> 110 then
    assert_is_fortran_array := false
  else
    assert_is_fortran_array := n^.xp[8] <> nil;
end;

{ routine_reference_class - what n refers to: 0 a block with a body (its
  +100 a kind 144), 2 a block without, 1 a kind 159, 4 a kind 209, 3 a
  kind 146 or 175, 5 nothing; blk and ref the block and the node naming
  it (both nil for 3 and 5).

  0x0B0984, 0xD6 bytes: n a kind 171 goes to its +16, a Fortran symbol
  (110) of class 1 (+44 bits 7..4) to its +40 (2 when that is nil);
  then kinds 105, 108, 107 are the block, 167 its +148.  The class in
  D0, the stores shared by the paths (blk then ref). }

function routine_reference_class(
    n: il_$node_ptr_t;
    var blk: il_$node_ptr_t;
    var ref: il_$node_ptr_t): integer; options(val_param); internal;
var
  b: il_$node_ptr_t;
  class: integer;
begin
  if n <> nil then begin
    case n^.kind of
      171:
        n := n^.xp[4];
      110:
        if rshft(ord(n^.xc[44]) & 16#F0, 4) = 1 then begin
          if n^.xp[10] = nil then begin
            blk := n;
            ref := n;
            routine_reference_class := 2;
            return;
          end;
          n := n^.xp[10];
        end
        else begin
          blk := nil;
          ref := nil;
          routine_reference_class := 5;
          return;
        end;
      146, 175: begin
        blk := nil;
        ref := nil;
        routine_reference_class := 3;
        return;
      end;
      otherwise
        ;
    end;
    if (n^.kind = 105) or (n^.kind = 108) or (n^.kind = 107) then
      b := n
    else if n^.kind = 167 then
      b := n^.xp[37]
    else begin
      if n^.kind = 159 then
        class := 1
      else if n^.kind = 209 then
        class := 4
      else begin
        blk := nil;
        ref := nil;
        routine_reference_class := 5;
        return;
      end;
      blk := n;
      ref := n;
      routine_reference_class := class;
      return;
    end;
    if (b^.xp[25] <> nil) and then (b^.xp[25]^.kind = 144) then
      class := 0
    else
      class := 2;
    blk := b;
    ref := n;
    routine_reference_class := class;
  end
  else begin
    blk := nil;
    ref := nil;
    routine_reference_class := 5;
  end;
end;

{ is_routine_reference_addr_con - n, an address constant (195: class
  +20 a word, the block +12; 163: class +20 a byte, the block +8) of
  class 4, 5, 6 or 9 (`move.w #0x270; btst'), refers to a block with a
  body; that block's +374 bit 3 (referenced) is set.

  0x0B0A5A, 0x7A bytes: the class in D0, the node in (-8); the
  comparison with 0 kept in D2 (`seq', tested with `bpl'). }

function is_routine_reference_addr_con(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  target: il_$node_ptr_t;
  ref: il_$node_ptr_t;
  blk: il_$node_ptr_t;
  k: integer;
  is_routine: boolean;
begin
  if n^.kind = 195 then begin
    k := n^.xw[10];
    target := n^.xp[3];
  end
  else if n^.kind = 163 then begin
    k := ord(n^.xc[20]);
    target := n^.xp[2];
  end
  else begin
    is_routine_reference_addr_con := false;
    return;
  end;
  if k in [4, 5, 6, 9] then begin
    is_routine := routine_reference_class(target, blk, ref) = 0;
    if is_routine then begin
      blk^.xc[374] := chr(ord(blk^.xc[374]) ! 8);
      is_routine_reference_addr_con := true;
      return;
    end;
  end;
  is_routine_reference_addr_con := false;
end;

{ check_fdata - the address constants of a static initializer's list
  (+16 each, the chain at +4) marked.

  0x0B0AD4, 0x28 bytes: `link #-4' (a local; the result is not
  stored). }

procedure check_fdata(
    d: il_$node_ptr_t); options(val_param); internal;
var
  dummy: boolean;
begin
  while d <> nil do begin
    dummy := is_routine_reference_addr_con(d^.xp[4]);
    d := d^.xp[1];
  end;
end;

{ check_static_initializations - the initializers of il_118's chain
  (+36, the chain at +8) and il_110's (+28, the chain at +4).

  0x0B0AFC, 0x46 bytes. }

procedure check_static_initializations; internal;
var
  s: il_$node_ptr_t;
begin
  s := il_118;
  while s <> nil do begin
    check_fdata(s^.xp[9]);
    s := s^.xp[2];
  end;
  s := il_110;
  while s <> nil do begin
    check_fdata(s^.xp[7]);
    s := s^.xp[1];
  end;
end;

{ unconditionally_add_call_graph_edge - a new edge from caller to
  callee at the end of caller's edges out; a callable callee's call
  count (+264) counted.

  0x0B0B42, 0x78 bytes: the callable kinds a set of 0..223 after the
  routine (105..108, 172, 209; docs/dpc-gaps.md 8); gspace(36) left in
  A0 as the result (docs/rev889-patterns.md 32). }

function unconditionally_add_call_graph_edge(
    caller: il_$node_ptr_t;
    callee: il_$node_ptr_t;
    ref: il_$node_ptr_t): rb_edge_ptr_t; options(val_param); internal;
var
  e: rb_edge_ptr_t;
begin
  if callee <> nil then
    if callee^.kind in [105, 106, 107, 108, 172, 209] then
      callee^.xw[132] := callee^.xw[132] + 1;
  e := gspace(36);
  if caller^.xp[62] = nil then
    caller^.xp[61] := il_$node_ptr_t(e)
  else
    rb_edge_ptr_t(caller^.xp[62])^.caller_next := e;
  caller^.xp[62] := il_$node_ptr_t(e);
  e^.caller := caller;
  e^.callee := callee;
  e^.ref := ref;
  unconditionally_add_call_graph_edge := e;
end;

{ add_call_graph_edge - the edge from the current block (il_180) for
  the call in call's slot: found by the call, else made (with the
  statements, and on a callable callee's list of edges in); a kind 16
  call's slot added to the edge's sites unless there.

  0x0B0BD8, 0xDE bytes: call by address (the slot's address is
  compared and kept). }

procedure add_call_graph_edge(
    var call: il_$node_ptr_t;
    callee: il_$node_ptr_t;
    ref: il_$node_ptr_t); options(val_param); internal;
var
  e: rb_edge_ptr_t;
  s: rb_site_list_ptr_t;
begin
  e := rb_edge_ptr_t(il_180^.xp[61]);
  while e <> nil do begin
    if e^.call = call then
      exit;
    e := e^.caller_next;
  end;
  if e = nil then begin
    e := unconditionally_add_call_graph_edge(il_180, callee, ref);
    e^.ref_stmt := ref_stmt;
    e^.call := call;
    e^.stmt := cur_stmt;
    if callee <> nil then
      if callee^.kind in [105, 106, 107, 108, 172, 209] then begin
        e^.callee_next := rb_edge_ptr_t(callee^.xp[63]);
        callee^.xp[63] := il_$node_ptr_t(e);
      end;
  end;
  if call^.xw[18] = 16 then begin
    s := e^.sites;
    while s <> nil do begin
      if s^.site = addr(call) then
        exit;
      s := s^.next;
    end;
    if s = nil then begin
      s := gspace(8);
      s^.next := e^.sites;
      e^.sites := s;
      s^.site := addr(call);
    end;
  end;
end;

{ detect_fortran_param_scalarity_mismatches - a Fortran callee (its
  +12 a kind 168 whose 12-byte entries from +12 describe the formals)
  passed a scalar where it declares an array: the callee's +375 bit 6
  set and cgerr 62.

  0x0B0CB6, 0xEA bytes: the arguments 2..+38 (a word counter, `dbf'
  alone), the argument count less one compared with the callee's
  formal count (+293, a byte) as longwords. }

procedure detect_fortran_param_scalarity_mismatches(
    call: il_$node_ptr_t;
    callee: il_$node_ptr_t); options(val_param); internal;
var
  i: integer;
  a: il_$node_ptr_t;
begin
  if not assert_is_a_call_node(call) then
    bug_check('\\runbackend\detect_fortran_param_scalarity_mismatches -- call_tree not a call node%$');
  if not assert_is_a_callable_block(callee) then
    bug_check('\\runbackend\detect_fortran_param_scalarity_mismatches -- callee_bp not a callable block%$');
  if call^.xw[19] > 1 then
    if call^.xw[19] - 1 = ord(callee^.xc[293]) then
      if callee^.xp[3] <> nil then
        if callee^.xp[3]^.kind = 168 then
          for i := 2 to call^.xw[19] do begin
            a := call^.xp[6 + i];
            if a^.kind = 110 then
              if not assert_is_fortran_array(a) then
                if assert_is_fortran_array(callee^.xp[3]^.xp[3 * i - 3]) then begin
                  callee^.xc[375] := chr(ord(callee^.xc[375]) ! 16#40);
                  cgerr(62, il_utils_$src_line(cur_stmt), a);
                end;
          end;
end;

{ analyze_call_site_for_call_graph - the call in call's slot: its
  callee (+40) classified, an edge added; a callee with a body (class
  0) walked, a Fortran one (+377 bits 6..4 = 2) checked first; class 2
  marks the current block's +379 bit 5; class 4 is cgerr 59 and the
  statement unlinked (its line given to the next statement when that
  has none).

  0x0B0E50, 0xF8 bytes: a `case' on the class (a table of 5; classes
  1 and 3 share class 2's tail, docs/rev889-patterns.md 23). }

procedure analyze_call_site_for_call_graph(
    var call: il_$node_ptr_t); options(val_param); internal;
var
  callee: il_$node_ptr_t;
  ref: il_$node_ptr_t;
begin
  case routine_reference_class(call^.xp[10], callee, ref) of
    0: begin
      if rshft(ord(callee^.xc[377]) & 16#70, 4) = 2 then
        detect_fortran_param_scalarity_mismatches(call, callee);
      add_call_graph_edge(call, callee, ref);
      build_call_graph_walk_block(callee);
    end;
    1, 3:
      add_call_graph_edge(call, callee, ref);
    2: begin
      il_180^.xc[379] := chr(ord(il_180^.xc[379]) ! 16#20);
      add_call_graph_edge(call, callee, ref);
    end;
    4: begin
      cgerr(59, il_utils_$src_line(cur_stmt), callee);
      if cur_stmt^.xp[2]^.xw[10] = spos_$null_position then
        cur_stmt^.xp[2]^.xw[10] := cur_stmt^.xw[10];
      if cur_stmt^.xp[1] <> nil then begin
        cur_stmt^.xp[2]^.xp[1] := cur_stmt^.xp[1];
        cur_stmt^.xp[1]^.xp[2] := cur_stmt^.xp[2];
        cur_stmt^.xp[1] := nil;
      end;
    end;
    otherwise
      ;
  end;
end;

{ build_call_graph_walk_il - the tree in t's slot walked for calls and
  routine references.  A tree node already walked (+18 = -3) is only
  analyzed again as a kind 137 call (+36 16); else +18 := -3, and these
  and kinds 171, 175 and 189 count in the current block's +272.

  0x0B0F48, 0x3F0 bytes: the two kind sets of 0..207 after the routine
  (docs/dpc-gaps.md 8); a `case' on the kind (a table of 125 from 109);
  the calls' arguments walked last first for the operators in a set of
  0..47 (2, 4, 5, 6, 11, 15, 16, 21, 35, 37), else first first, from 2
  for operators 16 and 15 (calls, then analyzed); kind 139's operands
  (+50, a word zero-extended) last first from +34; kinds 148 and 149
  set module +0x4; checks of kinds 165, 109 and 110 as bug_checks.

  Not known from the original: whether kind 139's count is unsigned
  (`clr.l; move.w'). }

procedure build_call_graph_walk_il(
    var t: il_$node_ptr_t); options(val_param); internal;
var
  n: il_$node_ptr_t;
  first: integer32;
  i: integer32;
begin
  n := t;
  if n = nil then
    return;
  if n^.kind in [137, 138, 143, 145, 146, 147, 164, 205] then begin
    if n^.xw[9] = -3 then begin
      if n^.kind = 137 then
        if n^.xw[18] = 16 then
          analyze_call_site_for_call_graph(t);
      return;
    end;
    n^.xw[9] := -3;
    il_180^.xw[136] := il_180^.xw[136] + 1;
  end
  else if n^.kind in [137, 138, 143, 145, 146, 147, 164, 171, 175, 189,
                      205] then
    il_180^.xw[136] := il_180^.xw[136] + 1;
  case n^.kind of
    137, 138, 143: begin
      if (n^.xw[18] = 16) or (n^.xw[18] = 15) then
        first := 2
      else
        first := 1;
      if n^.xw[18] in [2, 4, 5, 6, 11, 15, 16, 21, 35, 37] then
        for i := n^.xw[19] downto first do
          build_call_graph_walk_il(n^.xp[6 + i])
      else
        for i := first to n^.xw[19] do
          build_call_graph_walk_il(n^.xp[6 + i]);
      if first = 2 then
        analyze_call_site_for_call_graph(t);
    end;
    139:
      for i := n^.xw[25] downto 1 do
        build_call_graph_walk_il(n^.xp2[i + 7]);
    140, 227: begin
      build_call_graph_walk_il(n^.xp[16]);
      build_call_graph_walk_il(n^.xp[17]);
      build_call_graph_walk_il(n^.xp[18]);
    end;
    142:
      build_call_graph_walk_il(n^.xp[14]);
    145: begin
      build_call_graph_walk_il(n^.xp[6]);
      build_call_graph_walk_il(n^.xp[9]);
    end;
    146, 147, 205:
      build_call_graph_walk_il(n^.xp[6]);
    148:
      ref_stmt := n^.xp[12];
    149:
      ref_stmt := n^.xp[12]^.xp[2];
    150, 151, 224, 225:
      build_call_graph_walk_il(n^.xp[12]);
    163:
      if ord(n^.xc[20]) in [4, 5, 6, 9] then
        if is_routine_reference_addr_con(n) then
          build_call_graph_walk_block(n^.xp[2]);
    164: begin
      build_call_graph_walk_il(n^.xp[5]);
      build_call_graph_walk_il(n^.xp[6]);
    end;
    165: begin
      if n^.xp[2] = nil then
        bug_check('\\runbackend\build_call_graph_walk_il -- cs_temp has NIL .cs_temp.bp%$');
      if n^.xw[11] = 0 then
        bug_check('\\runbackend\build_call_graph_walk_il -- cs_temp has 0 .cs_temp.size%$');
    end;
    171, 175:
      build_call_graph_walk_il(n^.xp[4]);
    195:
      if n^.xw[10] in [4, 5, 6, 9] then
        if is_routine_reference_addr_con(n) then
          build_call_graph_walk_block(n^.xp[3]);
    219, 220, 232:
      build_call_graph_walk_il(n^.xp[1]);
    228: begin
      build_call_graph_walk_il(n^.xp[12]);
      build_call_graph_walk_il(n^.xp[13]);
      build_call_graph_walk_il(n^.xp[14]);
      build_call_graph_walk_il(n^.xp[15]);
      build_call_graph_walk_il(n^.xp[16]);
    end;
    109: begin
      if n^.xp[5] = nil then
        bug_check('\\runbackend\build_call_graph_walk_il -- var_name has NIL .varn.n.bp%$');
      if n^.xl[9] = 0 then
        bug_check('\\runbackend\build_call_graph_walk_il -- var_name has 0 .varn.vattr_vals.size%$');
    end;
    110:
      if n^.xp[10] = nil then
        if rshft(ord(n^.xc[44]) & 16#F0, 4) = 3 then
          bug_check('\\runbackend\build_call_graph_walk_il -- fortran_symbol has NIL .fsym.ecr.blk_ptr%$');
    otherwise
      ;
  end;
end;

{ build_call_graph_walk_block - b, when it is a routine with a body
  (class 0) not yet walked (+379 bit 1), marked and its statements
  (from +100 to the kind 149 that ends it, its +48 b) walked as the
  current block (il_180, +272 cleared), module +0x0 the statement; the
  current block and the statements restored after.

  0x0B14E8, 0x9A bytes: b's own slot passed for routine_reference_
  class's blk (`pea (8,A6)'). }

procedure build_call_graph_walk_block;
var
  is_routine: boolean;
  ref: il_$node_ptr_t;
  saved_block: il_$node_ptr_t;
  saved_ref_stmt: il_$node_ptr_t;
  saved_stmt: il_$node_ptr_t;
  s: il_$node_ptr_t;
begin
  is_routine := routine_reference_class(b, b, ref) = 0;
  if is_routine then
    if (ord(b^.xc[379]) & 2) = 0 then begin
      b^.xc[379] := chr(ord(b^.xc[379]) ! 2);
      if b^.xp[25] <> nil then
        if b^.xp[25]^.kind = 144 then begin
          saved_block := il_180;
          saved_ref_stmt := ref_stmt;
          saved_stmt := cur_stmt;
          il_180 := b;
          b^.xw[136] := 0;
          s := b^.xp[25];
          repeat
            cur_stmt := s;
            build_call_graph_walk_il(cur_stmt);
            s := s^.xp[2];
          until (s = nil) or else ((s^.kind = 149) and (s^.xp[12] = b));
          il_180 := saved_block;
          ref_stmt := saved_ref_stmt;
          cur_stmt := saved_stmt;
        end;
    end;
end;

{ build_call_graph - every block's walked mark (+379 bit 1) and call
  count (+264) cleared, the routines that are entry points (kinds 105,
  108, 107 at level 0 (+294) without +371 bit 7) marked referenced
  (+374 bit 3); the static initializers checked; then the referenced
  blocks walked.

  0x0B1582, 0x7A bytes. }

procedure build_call_graph; internal;
var
  b: il_$node_ptr_t;
begin
  b := il_184;
  while b <> nil do begin
    b^.xc[379] := chr(ord(b^.xc[379]) & 16#FD);
    b^.xw[132] := 0;
    if (b^.kind = 105) or (b^.kind = 108) or (b^.kind = 107) then
      if rb_level_ptr_t(b)^.level = 0 then
        if ord(b^.xc[371]) < 128 then
          b^.xc[374] := chr(ord(b^.xc[374]) ! 8);
    b := b^.xp[1];
  end;
  check_static_initializations;
  b := il_184;
  while b <> nil do begin
    if (ord(b^.xc[374]) & 8) <> 0 then
      build_call_graph_walk_block(b);
    b := b^.xp[1];
  end;
end;

{ assert_is_inlineable_utility_routine_in_include_file - b is a routine
  (105, 108, 107) with +375 bit 5 whose line (+300) is not in the main
  source file.

  0x0B15FC, 0x48 bytes: `not.b' of spos_$line_is_in_main_source_file's
  byte. }

function assert_is_inlineable_utility_routine_in_include_file(
    b: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if b = nil then
    assert_is_inlineable_utility_routine_in_include_file := false
  else if ((b^.kind = 105) or (b^.kind = 108) or (b^.kind = 107)) and
          ((ord(b^.xc[375]) & 16#20) <> 0) then
    assert_is_inlineable_utility_routine_in_include_file :=
        not spos_$line_is_in_main_source_file(b^.xw[150])
  else
    assert_is_inlineable_utility_routine_in_include_file := false;
end;

{ delete_unreferenced_blocks - every routine (108, 107, 105) not called
  (+264 at most 0) nor referenced (+374 bit 3) removed: cgerr 46 (its
  line +300 and name +296) unless it has no line, is marked (+374 bit
  1) or is an inlineable utility routine in an include file; its
  statements (+100..+104) unlinked from the statement chain (+4, +8;
  il_d4 moved past them), and it and the blocks nested in it (a level,
  +294, above its own, and kind 167s at its level) taken out of the
  block chain (+4; the predecessor found from its parent, +8).

  0x0B1644, 0x106 bytes: `seq; seq; or.b' for the kinds (108, 107,
  105); the levels compared as signed bytes (`ext.w; blt'). }

procedure delete_unreferenced_blocks; internal;
var
  b: il_$node_ptr_t;
  p: il_$node_ptr_t;
  n: il_$node_ptr_t;
  first: il_$node_ptr_t;
  prev_stmt: il_$node_ptr_t;
  next_stmt: il_$node_ptr_t;
begin
  b := il_184;
  while b <> nil do begin
    if not (((b^.kind = 108) or (b^.kind = 107) or (b^.kind = 105)) and
            (b^.xw[132] <= 0) and ((ord(b^.xc[374]) & 8) = 0)) then
      b := b^.xp[1]
    else begin
      if b^.xw[150] <> 0 then
        if (ord(b^.xc[374]) & 2) = 0 then
          if not assert_is_inlineable_utility_routine_in_include_file(b) then
            cgerr(46, b^.xw[150], b^.xp[74]);
      p := b^.xp[2];
      while p^.xp[1] <> b do
        p := p^.xp[1];
      n := b;
      repeat
        n := n^.xp[1];
      until (n = nil) or else
            (rb_level_ptr_t(n)^.level < rb_level_ptr_t(b)^.level) or
            ((rb_level_ptr_t(n)^.level = rb_level_ptr_t(b)^.level) and
             (n^.kind <> 167));
      first := b^.xp[25];
      prev_stmt := first^.xp[1];
      next_stmt := b^.xp[26]^.xp[2];
      if prev_stmt <> nil then
        prev_stmt^.xp[2] := next_stmt;
      if next_stmt <> nil then
        next_stmt^.xp[1] := prev_stmt;
      if first = il_d4 then
        il_d4 := next_stmt;
      p^.xp[1] := n;
      b := n;
    end;
  end;
end;

{ assert_is_useless_disp - d is a displacement node (147) of 0 (+32)
  whose flags (+4, mask 16#19001F) are clear or whose operand (+24) is
  a constant (a set of 0..207 after the routine: 77..90, 92, 93, 101,
  156, 176, 198, 200; docs/dpc-gaps.md 8).

  0x0B174A, 0x56 bytes. }

function assert_is_useless_disp(
    d: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if d = nil then
    assert_is_useless_disp := false
  else if (d^.kind = 147) and (d^.xl[8] = 0) then begin
    if (d^.xl[1] & 16#19001F) <> 0 then
      assert_is_useless_disp := d^.xp[6]^.kind in [77..90, 92, 93, 101, 156,
                                                   176, 198, 200]
    else
      assert_is_useless_disp := true;
  end
  else
    assert_is_useless_disp := false;
end;

{ normalize_il - the tree in t's slot made ready for the optimizer:
  tree nodes' +16 cleared; a kind 41 operator's size (+28) from its
  type (+24: 8 for a 6-byte and 12 for any other kind 15, none for 10,
  11, 21); a kind 205 (an indirection) of a zero displacement folded
  into it, and with fold set turned into a displacement (147) of its
  variable's address; a displacement of a displacement merged, and with
  fold set a useless one replaced by its operand; assignment operators
  (140) committed to memory unless optimization 8 is on; the checks of
  kinds 165, 109, 110.  The line (+20) of the nodes in a set of 0..239
  (the statements; no range check) kept in module +0x38.

  0x0B17BA, 0x55E bytes: a `case' on the kind (a table of 125 from
  109); fold in D2, pushed as a byte in a word with the 2-byte pad
  kept between calls (`addq.l #6,SP'); the slot re-read after each
  call; kinds 205 and 147 share 147's tail (docs/rev889-patterns.md
  23); cgerr(28, 0, nil) as one longword `move.l #0x1C0000'; the set a
  docs/dpc-gaps.md 8 constant.

  Not known from the original: the reason for the size table (kind
  41's +26 the type's kind); whether +50's count is unsigned. }

procedure normalize_il(
    var t: il_$node_ptr_t;
    fold: boolean); options(val_param); internal;
var
  size: integer32;
  q: il_$node_ptr_t;
  tmp: il_$node_ptr_t;
  d: il_$node_ptr_t;
  i: integer32;
begin
  if t = nil then
    return;
  if t^.kind in [139..142, 144, 148..151, 188, 191, 214, 215, 223..225,
                 227, 228, 231, 233] then
    if t^.xw[10] <> 0 then
      last_line := t^.xw[10];
  case t^.kind of
    137, 138, 143: begin
      t^.xw[8] := 0;
      for i := t^.xw[19] downto 1 do
        normalize_il(t^.xp[6 + i], fold);
      if t^.xw[18] = 41 then begin
        size := t^.xw[12];
        case t^.xw[13] of
          10, 11, 21:
            ;
          15: begin
            if size = 6 then
              size := 8
            else
              size := 12;
            t^.xw[14] := size;
          end;
          otherwise
            t^.xw[14] := size;
        end;
      end;
    end;
    139:
      for i := t^.xw[25] downto 1 do
        normalize_il(t^.xp2[i + 7], fold);
    140: begin
      if not (8 in cargs_$options.opt_on) then
        if 0 in getphase(t^.xp[16]) then begin
          q := t^.xp[17];
          commit_top_$convert_aops_to__aop_to_mem(t);
          if t^.xp[17] <> q then begin
            tmp := q;
            normalize_il(tmp, fold);
          end;
        end;
      normalize_il(t^.xp[16], fold);
      normalize_il(t^.xp[17], fold);
      normalize_il(t^.xp[18], fold);
    end;
    142:
      normalize_il(t^.xp[14], fold);
    145: begin
      t^.xw[8] := 0;
      normalize_il(t^.xp[6], fold);
      normalize_il(t^.xp[9], fold);
    end;
    146: begin
      t^.xw[8] := 0;
      normalize_il(t^.xp[6], fold);
    end;
    147: begin
      t^.xw[8] := 0;
      normalize_il(t^.xp[6], fold);
      d := t^.xp[6];
      if d^.kind = 147 then begin
        t^.xl[8] := t^.xl[8] + d^.xl[8];
        t^.xl[1] := t^.xl[1] ! (d^.xl[1] & 16#19001F);
        t^.xp[6] := d^.xp[6];
        if t^.xp[7] = d then
          t^.xp[7] := d^.xp[6];
        if t^.xp[7] = nil then
          t^.xp[7] := d^.xp[7];
      end;
      if fold then
        if assert_is_useless_disp(t) then
          t := t^.xp[6];
    end;
    150, 151, 224, 225:
      normalize_il(t^.xp[12], fold);
    164: begin
      t^.xw[8] := 0;
      normalize_il(t^.xp[5], fold);
      normalize_il(t^.xp[6], fold);
    end;
    165: begin
      if t^.xp[2] = nil then
        bug_check('\\runbackend\normalize_il -- cs_temp has NIL .cs_temp.bp%$');
      if t^.xw[11] = 0 then
        bug_check('\\runbackend\normalize_il -- cs_temp has 0 .cs_temp.size%$');
    end;
    171, 175:
      normalize_il(t^.xp[4], fold);
    189:
      normalize_il(t^.xp[5], fold);
    190, 219, 220, 232:
      normalize_il(t^.xp[1], fold);
    205: begin
      t^.xw[8] := 0;
      d := t^.xp[6];
      if d^.kind = 147 then
        if d^.xl[8] = 0 then
          t^.xp[6] := d^.xp[6]
        else
          cgerr(28, last_line, nil);
      if not fold then
        normalize_il(t^.xp[6], fold)
      else begin
        t^.kind := 147;
        d := t^.xp[8];
        case d^.kind of
          109: t^.xp[8] := d^.xp[14];
          110: t^.xp[8] := d^.xp[3];
          163: t^.xp[8] := d^.xp[4];
          otherwise
            cgerr(28, 0, nil);
        end;
        normalize_il(t^.xp[6], fold);
        d := t^.xp[6];
        if d^.kind = 147 then begin
          t^.xl[8] := t^.xl[8] + d^.xl[8];
          t^.xl[1] := t^.xl[1] ! (d^.xl[1] & 16#19001F);
          t^.xp[6] := d^.xp[6];
          if t^.xp[7] = d then
            t^.xp[7] := d^.xp[6];
          if t^.xp[7] = nil then
            t^.xp[7] := d^.xp[7];
        end;
        if fold then
          if assert_is_useless_disp(t) then
            t := t^.xp[6];
      end;
    end;
    227: begin
      normalize_il(t^.xp[16], fold);
      normalize_il(t^.xp[17], fold);
      normalize_il(t^.xp[18], fold);
    end;
    228: begin
      normalize_il(t^.xp[12], fold);
      normalize_il(t^.xp[13], fold);
      normalize_il(t^.xp[14], fold);
      normalize_il(t^.xp[15], fold);
      normalize_il(t^.xp[16], fold);
    end;
    109: begin
      if t^.xp[5] = nil then
        bug_check('\\runbackend\normalize_il -- var_name has NIL .varn.n.bp%$');
      if t^.xl[9] = 0 then
        bug_check('\\runbackend\normalize_il -- var_name has 0 .varn.vattr_vals.size%$');
    end;
    110:
      if t^.xp[10] = nil then
        if rshft(ord(t^.xc[44]) & 16#F0, 4) = 3 then
          bug_check('\\runbackend\normalize_il -- fortran_symbol has NIL .fsym.ecr.blk_ptr%$');
    otherwise
      ;
  end;
end;

{ optimize_and_code - routine b, unless coded (+379 bit 2): its
  statements (+100 to the kind 149 ending it, cut off from the rest for
  the while; their count in runbackend_16) normalized (folding unless
  cpu 6), then g_opt and, without -TREE and unless b is an unused
  marked routine (+374 bit 1, not bit 3, no calls, kind 108 or 107),
  codegen; b and the blocks after it of kinds 172 and 167 marked coded.
  With -X bits 0..2 clear codegen runs under a cleanup handler: a fault
  reports the routine (its name, +296's identifier), a traceback with
  -X bit 15, the fault signalled again unless it is a bug_check's
  (16#7F000000, 16#7F000001), and module +0x36 set.

  0x0B1E70, 0x20C bytes (perfstart and perfstop phase 6): the count in
  D0 from 1 (`clr.l; addq.l #1' before the first step); every register
  saved for pfm_$cleanup; errlog_$traceback's arguments constants after
  the routine (stream 2, [errlog_$fault_tb], 30 frames); lex_errors not
  0 clears at_backend_506. }

procedure optimize_and_code(
    b: il_$node_ptr_t); options(val_param); internal;
var
  flag: boolean;
  last: il_$node_ptr_t;
  saved_next: il_$node_ptr_t;
  s: il_$node_ptr_t;
  status: status_$t;
  crec: pfm_$cleanup_rec;
  n: integer32;
begin
  if (ord(b^.xc[379]) & 4) = 0 then begin
    perfstart(6);
    n := 0;
    last := b^.xp[25];
    repeat
      n := n + 1;
      last := last^.xp[2];
    until (last^.kind = 149) and (last^.xp[12] = b);
    runbackend_16 := n;
    saved_next := last^.xp[2];
    last^.xp[2] := nil;
    il_180 := b;
    s := b^.xp[25];
    il_d4 := s;
    flag := not (6 in cargs_$options.cpu);
    repeat
      normalize_il(s, flag);
      s := s^.xp[2];
    until (s = nil) or else ((s^.kind = 149) and (s^.xp[12] = b));
    il_utils_$set_uc_walk_spine(b^.xp[25], b);
    g_opt;
    perfstop(6);
    if lex_errors <> 0 then
      at_backend_506 := false;
    if not (((ord(b^.xc[374]) & 2) <> 0) and ((ord(b^.xc[374]) & 8) = 0) and
            (b^.xw[132] = 0) and ((b^.kind = 108) or (b^.kind = 107))) then
      if cargs_$options.tree = 0 then begin
        if (cargs_$debug_switches['X'] & 7) <> 0 then
          codegen
        else begin
          status := pfm_$cleanup(crec);
          if status.all = pfm_$cleanup_set then begin
            codegen;
            pfm_$rls_cleanup(crec, status);
          end
          else begin
            vfmt_$write('Compiler backend failure while processing routine "%a" %.',
                b^.xp[74]^.idnt_name, b^.xp[74]^.idnt_len);
            if cargs_$debug_switches['X'] < 0 then
              errlog_$traceback(ios_$errout, [errlog_$fault_tb], 30);
            if (status.all <> 16#7F000000) and (status.all <> 16#7F000001) then
              pfm_$signal(status);
            pfm_$enable;
            backend_failed := true;
          end;
        end;
        repeat
          b^.xc[379] := chr(ord(b^.xc[379]) ! 4);
          b := b^.xp[1];
        until (b = nil) or else ((b^.kind <> 172) and (b^.kind <> 167));
      end;
    last^.xp[2] := saved_next;
  end;
end;

{ optimize_and_code_depth_first - the routines b calls (its edges out,
  callable and not yet marked, with a body) first, then b; b marked
  (+379 bit 1).

  0x0B20BE, 0x80 bytes: the callable kinds the set after
  unconditionally_add_call_graph_edge (docs/dpc-gaps.md 8). }

procedure optimize_and_code_depth_first(
    b: il_$node_ptr_t); options(val_param); internal;
var
  e: rb_edge_ptr_t;
  blk: il_$node_ptr_t;
  ref: il_$node_ptr_t;
  is_routine: boolean;
begin
  b^.xc[379] := chr(ord(b^.xc[379]) ! 2);
  e := rb_edge_ptr_t(b^.xp[61]);
  while e <> nil do begin
    if e^.callee <> nil then
      if e^.callee^.kind in [105, 106, 107, 108, 172, 209] then
        if (ord(e^.callee^.xc[379]) & 2) = 0 then begin
          is_routine := routine_reference_class(e^.callee, blk, ref) = 0;
          if is_routine then
            optimize_and_code_depth_first(e^.callee);
        end;
    e := e^.caller_next;
  end;
  optimize_and_code(b);
end;

{ set_local_call_bits - for each block's edges out to callable blocks
  not of class 1..3 in +376/+377 (bits 8..7 of the word): both ends'
  +379 bit 7 when the callee is in the caller's module (+192) and
  at_backend_$can_load_module_db, else bit 6; a kind 167's Fortran
  entry set up; module +0x34 set when a block has +376 bit 7.

  0x0B213E, 0xC0 bytes: the callable kinds the set after
  unconditionally_add_call_graph_edge (docs/dpc-gaps.md 8); the
  edge's ref (+4) is the block given bit 7 or 6 with the callee. }

procedure set_local_call_bits; internal;
var
  b: il_$node_ptr_t;
  e: rb_edge_ptr_t;
begin
  b := il_184;
  while b <> nil do begin
    e := rb_edge_ptr_t(b^.xp[61]);
    while e <> nil do begin
      if e^.callee <> nil then
        if e^.callee^.kind in [105, 106, 107, 108, 172, 209] then
          if rshft(e^.callee^.xw[188] & 16#180, 7) = 0 then
            if (b^.xp[48] = e^.callee^.xp[48]) and then
               at_backend_$can_load_module_db(b) then begin
              e^.callee^.xc[379] := chr(ord(e^.callee^.xc[379]) ! 16#80);
              e^.ref^.xc[379] := chr(ord(e^.ref^.xc[379]) ! 16#80);
            end
            else begin
              e^.callee^.xc[379] := chr(ord(e^.callee^.xc[379]) ! 16#40);
              e^.ref^.xc[379] := chr(ord(e^.ref^.xc[379]) ! 16#40);
            end;
      e := e^.caller_next;
    end;
    if b^.kind = 167 then
      at_backend_$initialize_ftn_entry(b);
    if ord(b^.xc[376]) >= 128 then
      fcw_seen := true;
    b := b^.xp[1];
  end;
end;

{ adjust_disps_of_formals_for_fcw - each formal (the chain at +12, +293
  of them) found as a variable (its +48 when its +44 is 0, else by
  blk_fnd_name of its +8) moved 4 bytes (+56); and the result's (+28,
  not il_178) when its register length is above 6: the block's +96
  moved too.

  0x0B21FE, 0xCE bytes: the count a byte (`dbf' with the borrow); the
  type's size from the bit size (+316, `addq.l #7; lsr.l #3') when
  +314 bit 11 is set; get_rlen compared unsigned (`shi'), the result
  kept in D2.

  Not known from the original: why the comparison is unsigned. }

procedure adjust_disps_of_formals_for_fcw(
    blk: il_$node_ptr_t); options(val_param); internal;
var
  f: il_$node_ptr_t;
  v: il_$node_ptr_t;
  t: il_$node_ptr_t;
  te: type_exp_t;
  i: integer32;
  big: boolean;
begin
  f := blk^.xp[3];
  for i := 1 to ord(blk^.xc[293]) do begin
    if (f^.xw[22] = 0) and (f^.xp[12] <> nil) then
      v := f^.xp[12]
    else
      v := blk_fnd_name(f^.xp[2], false, false, c_blk_ptr_t(blk));
    if v^.kind = 109 then
      v^.xl[14] := v^.xl[14] + 4;
    f := f^.xp[1];
  end;
  t := blk^.xp[7];
  if t <> nil then
    if t <> il_178 then begin
      type_exp(t, addr(te));
      if (blk^.xw[157] & 16#800) <> 0 then
        te.size := rshft(blk^.xl[79] + 7, 3);
      big := get_rlen(te) > 6;
      if big then
        blk^.xp[24]^.xl[14] := blk^.xp[24]^.xl[14] + 4;
    end;
end;

{ run_backend - the back end over the IL the front end made.

  0x0B22CC, 0x254 bytes: lang and line by address, do_lex by value (a
  routine pointer, called with -TREE after the listing and the source
  are released, and passed to unix_obj_gen), hook by address (read at
  entry, called after inline expansion when not nil).  With no
  statements (il_d4 nil) only the listing is advanced (-EXP).  -TREE 1,
  2 and 47 print the IL at those points and return; -DBA keeps the
  unreferenced routines; with cpu 2, 4, 8, 9 or 10 and a routine with
  +376 bit 7 (directly, or a kind 167's +148's) its formals moved for
  the floating-point context; with cpu 6 the routines are coded depth
  first.  The routines are those of the top-level statements (each
  statement's next's +48; the next statement after the block's last,
  +104).  bug_check after all of them when one failed; the object
  module unless -i debug bit 11.

  Not known from the original: the parameters' modes.  The frame (8,
  16 and 20 by address, 12 by value; c_main passes constants for 8 and
  20) is what a routine parameter gives (ref 5.4, `procedure do_lex' in
  a routine without options), which dpc does not support yet; written
  here as a val_param routine whose other parameters are univ `in'
  (ref Table 5-1: univ cancels val_param), docs/questions.md.  The form
  of the +376 bit 7 tests (`smi' into D0, then `tst.b; bpl'). }

procedure run_backend(
    in lang: univ integer;
    do_lex: unix_objmod_$lex_proc_t;
    in line: univ integer;
    in hook: univ unix_objmod_$lex_proc_t); options(val_param);
var
  h: unix_objmod_$lex_proc_t;
  l: integer;
  b: il_$node_ptr_t;
  first: il_$node_ptr_t;
  s: il_$node_ptr_t;
  fcw: boolean;
begin
  h := hook;
  l := lang;
  runbackend_14 := l;
  backend_failed := false;
  at_backend_506 := true;
  if cargs_$options.tree <> 0 then begin
    io_release(0);
    io_release(1);
    do_lex^;
  end;
  if cargs_$options.tree = 0 then
    unix_obj_init;
  at_backend_$begin_compilation(l);
  if il_d4 = nil then begin
    if cargs_$options.exp then
      advance_listing_to_line(line);
  end
  else begin
    isc_$set_source_language(l);
    runbackend_08 := nil;
    f_initialize;
    opt_main_$initialize;
    if cargs_$options.tree = 1 then begin
      list_tree_$print_whole_il;
      return;
    end;
    build_call_graph;
    if cargs_$options.db <> 3 then
      delete_unreferenced_blocks;
    inline_$inline_expand;
    if h <> nil then
      h^;
    fcw_seen := false;
    set_local_call_bits;
    if (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and fcw_seen then begin
      b := il_184;
      while b <> nil do begin
        if b^.kind = 167 then
          fcw := ord(b^.xp[37]^.xc[376]) >= 128
        else
          fcw := ord(b^.xc[376]) >= 128;
        if fcw then
          adjust_disps_of_formals_for_fcw(b);
        b := b^.xp[1];
      end;
    end;
    if cargs_$options.tree = 2 then begin
      list_tree_$print_whole_il;
      return;
    end;
    if 6 in cargs_$options.cpu then begin
      b := il_184;
      while b <> nil do begin
        b^.xc[379] := chr(ord(b^.xc[379]) & 16#FD);
        b := b^.xp[1];
      end;
    end;
    first := il_d4;
    s := first;
    while s <> nil do begin
      b := s^.xp[2]^.xp[12];
      if (cargs_$options.tree <> 47) and (6 in cargs_$options.cpu) then begin
        if (ord(b^.xc[379]) & 2) = 0 then
          optimize_and_code_depth_first(b);
      end
      else
        optimize_and_code(b);
      s := b^.xp[26]^.xp[2];
    end;
    il_d4 := first;
  end;
  if backend_failed then
    bug_check('All routines processed by backend - aborting due to previous errors%$');
  if cargs_$options.tree = 47 then begin
    list_tree_$print_whole_il;
    return;
  end;
  if il_d4 <> nil then
    finaldriver;
  at_backend_$end_compilation;
  if (cargs_$debug_switches['i'] & 16#800) = 0 then
    unix_obj_gen(do_lex);
end;
