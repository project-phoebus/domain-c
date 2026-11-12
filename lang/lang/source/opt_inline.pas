{ opt_inline - the optimizer's inliner (opt_on 24..26, -FORCE_INLINE):
  calls of routines of the compilation unit whose bodies may be copied
  are replaced by copies of the bodies.  The call graph's edges
  (runbackend's add_call_graph_edge: 36 bytes, a block's +244 edges
  out, +252 edges in) are walked depth first; a callee is judged
  (callee_status, call_status: recursion, size, opaque addressing, the
  language's rules), and each call site of an expandable callee gets a
  copy of the callee's statements, its variables and labels renamed
  into the caller, its parameters bound to the actuals (copied to
  temporaries or substituted), and its result assigned through a
  temporary; the copy's nodes are mapped through a hash table of the
  callee's nodes to their copies (get_hash_info, put_hash_info).
  inline_$mark_reference_params marks the variables passed by
  reference (also for opt_vector), and inline_$inline_expand, which
  runbackend calls, settles the blocks' flags afterwards.

  Image addresses (DOMAIN C 6.9):
    cc.m68k   cc.a88k
    0x08EC38  0x090618  inline_$is_fortran_asf
    0x08EC5A  0x09063A  assert_is_nonleaf_lvalue
    0x08EC90  0x090670  assert_is_a_routine_block
    0x08ECBC  0x09069C  assert_is_void_type
    0x08ECD4  0x0906B4  assert_routine_returns_void
    0x08ED22  0x090702  nil_out_dispinfo
    0x08ED36  0x090716  next_contained_block
    0x08EDCE  0x0907AE  find_block
    0x08EE28  0x090808  find_varn
    0x08EF54  0x090934  get_size_rlen
    0x08F3DA  0x090DBA  get_referenced_symbol
    0x08F49A  0x090E7A  inline_$mark_reference_params
    0x08F674  0x091054  function_return
    0x08F73C  0x09111C  current_ln
    0x08F756  0x091136  cleanup_hash
    0x08F79C  0x09117C  get_hash_info
    0x08F86A  0x09124A  put_hash_info
    0x08F95A  0x09133A  extend
    0x08FA6C  0x09144C  coerce
    0x08FC5C  0x09163C  start_il_stream
    0x08FCDA  0x0916BA  inline_$compatible_types
    0x08FD10  0x0916F0  patch_il
    0x08FF6E  0x09194E  put_on_il_stream
    0x08FF90  0x091970  actual_actual
    0x090012  0x0919F2  pass_method
    0x0901BC  0x091B9C  put_on_bct
    0x09023E  0x091C1E  copy_const
    0x090278  0x091C58  copy_var
    0x0903B8  0x091D98  align
    0x0903F2  0x091DD2  allocate_space
    0x09055C  0x091F3C  allocate_local_var
    0x09077A  0x09215A  set_address_exposed
    0x090848  0x092228  inliner_actual
    0x090862  0x092242  assign
    0x090968  0x092348  assign_name
    0x090A10  0x0923F0  ptr_variable
    0x090BBA  0x09259A  process_parameters
    0x0912AA  0x092C8A  process_display_ptrs
    0x09143E  0x092E1E  process_variables
    0x09179A  0x09317A  process_labels
    0x091822  0x093202  substitutee_sym_ind
    0x0918BA  0x09329A  get_sym_ind_info
    0x09192E  0x09330E  adjust_disp
    0x091956  0x093336  disp_offset
    0x09196A  0x09334A  apply_disp
    0x091A1E  0x0933FE  process_index_opr
    0x091CAE  0x09368E  process_opr_ind
    0x092228  0x093C08  process_operand
    0x092E20  0x094800  process_statements
    0x092EEC  0x0948CC  process_blocks
    0x0931FA  0x094BDA  cleanup_expansion
    0x093266  0x094C46  call_status
    0x0935F8  0x094FD8  remove_call_graph_edge
    0x09365C  0x09503C  dfs_walk
    0x093836  0x095216  check_call_sites_and_expand
    0x0938F0  0x0952D0  assert_is_symbolically_opaque_address
    0x093968  0x095348  assert_contains_symbolically_opaque_addressing
    0x093AC4  0x0954A4  assert_statement_contains_symbolically_opaque_addressing
    0x093BAE  0x09558E  assert_routine_contains_symbolically_opaque_addressing
    0x093C5E  0x09563E  callee_status
    0x093F76  0x095956  anything_to_expand
    0x094066  0x095A46  inline_$inline_expand
    A5 0x196DC8 (cc.m68k), 0x316E38 (cc.a88k): the module's data, 0x5EFC
    bytes, the same in both: the heap (+0, mrh) the copies' records
    come from, the hash table of 1009 chains (+0x18, 24-byte entries
    whose heads are in the table), the empty display record (+0x5EB0),
    the caller's block being expanded into (+0x5EC8), the statement
    stream being built (+0x5ED0 its head, an evaluation, +0x5ECC its
    tail), the callee's language (+0x5ED4) and status (+0x5ED6), the
    bytes of each register class (+0x5ED8, initialized), the names'
    serial (+0x5EF4, initialized 0) and the statement process_operand
    is in (+0x5EF8).

  The two binaries' code is the same but for the absolute addresses
  (il, cargs, target_properties, the module's data and the callees).
  Only inline_$mark_reference_params (opt_vector calls it),
  inline_$inline_expand (runbackend) and process_operand (recursive
  through its nested routines; no caller outside) load A5; the others
  do not and are internal (they run on inline_$inline_expand's A5).

  The unit opens neither g_opt.ins.pas nor runbackend's records: the
  call graph's edges are declared here (oi_edge_t, runbackend.pas's
  rb_edge_t), statements, blocks and other nodes are read by offset
  (il.ins.pas's views), a block's nesting level through oi_level_t.

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on node kind sets).

  Not known from the original: every name but the routines'.
}
module opt_inline;

%include '/sys/ins/base.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { A call graph edge (runbackend.pas's rb_edge_t, 36 bytes from
    gspace): in its caller's edges out (a block's +244, through
    caller_next) and its callee's edges in (+252, through
    callee_next). }
  oi_site_ptr_t = ^il_$node_ptr_t;
  oi_site_list_ptr_t = ^oi_site_list_t;
  oi_site_list_t = record
    site: oi_site_ptr_t;                { +0 }
    next: oi_site_list_ptr_t;           { +4 }
  end;
  oi_edge_ptr_t = ^oi_edge_t;
  oi_edge_t = record
    callee: il_$node_ptr_t;             { +0: the block called }
    ref: il_$node_ptr_t;                { +4 }
    caller: il_$node_ptr_t;             { +8 }
    ref_stmt: il_$node_ptr_t;           { +12 }
    call: il_$node_ptr_t;               { +16: the call (or reference) }
    stmt: il_$node_ptr_t;               { +20: the call's statement }
    sites: oi_site_list_ptr_t;          { +24: kind 16 calls' slots }
    callee_next: oi_edge_ptr_t;         { +28 }
    caller_next: oi_edge_ptr_t;         { +32 }
  end;

  { What a node of the callee becomes in the copy (24 bytes, kept by
    put_hash_info; the empty one at +0x5EB0, nil_out_dispinfo). }
  oi_info_ptr_t = ^oi_info_t;
  oi_info_t = record
    node: il_$node_ptr_t;               { +0 }
    i4: il_$node_ptr_t;                 { +4 }
    i8: il_$node_ptr_t;                 { +8 }
    i12: il_$node_ptr_t;                { +12 }
    i16: il_$node_ptr_t;                { +16 }
    i20: il_$node_ptr_t;                { +20 }
  end;

  { An entry of the hash table (24 bytes; the chains' heads are the
    table's elements, the others from the heap): node of the callee
    copied in the context ctx (an edge's caller), what it becomes
    (val, flags, info). }
  oi_flags_t = set of 0..15;
  oi_hash_ptr_t = ^oi_hash_t;
  oi_hash_t = record
    next: oi_hash_ptr_t;                { +0 }
    node: il_$node_ptr_t;               { +4 }
    ctx: il_$node_ptr_t;                { +8 }
    val: il_$node_ptr_t;                { +12 }
    info: oi_info_ptr_t;                { +16 }
    flags: oi_flags_t;                  { +20 }
    unused_22: integer;                 { +22 }
  end;

  { type_exp's result (c_objtype.ins.pas's type_exp_t, 28 bytes). }
  oi_texp_t = record
    base: il_$node_ptr_t;               { +0 }
    node: il_$node_ptr_t;               { +4 }
    low: integer32;                     { +8 }
    high: integer32;                    { +12 }
    size: integer32;                    { +16 }
    bytes: integer32;                   { +20 }
    flags: integer32;                   { +24 }
  end;

  { A block's nesting level, the signed byte at +294. }
  oi_level_ptr_t = ^oi_level_t;
  oi_level_t = packed record
    pad: packed array [0..293] of char;
    level: -128..127;                   { +294 }
  end;

  { A descriptor cleared bytewise (extend). }
  oi_desc_t = record
    case integer of
      1: (d: add_node_$desc_t);
      2: (b: array [1..16] of char);
  end;

var
  heap: mrh_$heap_t;                    { +0 }
  unused_14: integer32;                 { +0x14 }
  hash: array [0..1008] of oi_hash_t;   { +0x18 }
  empty_info: oi_info_t;                { +0x5EB0 }
  caller_blk: il_$node_ptr_t;           { +0x5EC8 }
  stream_tail: il_$node_ptr_t;          { +0x5ECC }
  stream_head: il_$node_ptr_t;          { +0x5ED0 }
  language: integer;                    { +0x5ED4: the callee's (its
                                          block's +377 bits 6..4) }
  status: integer;                      { +0x5ED6 }
  class_bytes: array [0..12] of integer := [0, 1, 2, 0, 4, 4, 4, 8, 8,
                                            0, 0, 0, 16];  { +0x5ED8 }
  unused_5ef2: integer;                 { +0x5EF2 }
  name_serial: integer32 := 0;          { +0x5EF4 }
  cur_stmt: il_$node_ptr_t;             { +0x5EF8 }

define
  inline_$mark_reference_params;

{ inline_$is_fortran_asf - b is a Fortran statement function: the
  callee's language 2 and b a routine block (108) with +376 bit 3.

  0x08EC38, 0x22 bytes, no frame (pattern 16): b at (4,SP), the
  result in D0. }

function inline_$is_fortran_asf(
    b: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if (language = 2) and (b^.kind = 108) then
    inline_$is_fortran_asf := (ord(b^.xc[376]) & 8) <> 0
  else
    inline_$is_fortran_asf := false;
end;

{ assert_is_nonleaf_lvalue - t is a reference other than a variable:
  205, 147, 146 or 145.

  0x08EC5A, 0x36 bytes, no frame: the comparisons evaluated whole
  (`seq', `or.b'). }

function assert_is_nonleaf_lvalue(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if t <> nil then
    assert_is_nonleaf_lvalue := (t^.kind = 205) or (t^.kind = 147) or
                                (t^.kind = 146) or (t^.kind = 145)
  else
    assert_is_nonleaf_lvalue := false;
end;

{ assert_is_a_routine_block - b is a routine's block (108, 107, 105).

  0x08EC90, 0x2C bytes, no frame. }

function assert_is_a_routine_block(
    b: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if b <> nil then
    assert_is_a_routine_block := (b^.kind = 108) or (b^.kind = 107) or
                                 (b^.kind = 105)
  else
    assert_is_a_routine_block := false;
end;

{ assert_is_void_type - t is the type void (210).

  0x08ECBC, 0x18 bytes, no frame. }

function assert_is_void_type(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if t <> nil then
    assert_is_void_type := t^.kind = 210
  else
    assert_is_void_type := false;
end;

{ assert_routine_returns_void - routine block b's type (+28) is void,
  or, without a result variable (+96), a type name (118) of void.

  0x08ECD4, 0x4E bytes: the second assert_is_void_type's answer left
  in D0 (pattern 87). }

function assert_routine_returns_void(
    b: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if b = nil then
    assert_routine_returns_void := false
  else if assert_is_void_type(b^.xp[7]) then
    assert_routine_returns_void := true
  else if (b^.xp[24] = nil) and (b^.xp[7] <> nil) then begin
    if b^.xp[7]^.kind = 118 then
      assert_routine_returns_void := assert_is_void_type(b^.xp[7]^.xp[7])
    else
      assert_routine_returns_void := false;
  end
  else
    assert_routine_returns_void := false;
end;

{ nil_out_dispinfo - d emptied.

  0x08ED22, 0x14 bytes, no frame: six `clr.l' through d's address. }

procedure nil_out_dispinfo(
    out d: oi_info_t); internal;
begin
  d.node := nil;
  d.i4 := nil;
  d.i8 := nil;
  d.i12 := nil;
  d.i16 := nil;
  d.i20 := nil;
end;

{ next_contained_block - the block after b (in the IL's order, +4)
  that lies within block outer (outer on its chain of enclosing
  blocks, +8), or nil: routine blocks (108, 107) without +264 and
  without +374 bit 3 are passed over with the blocks they contain
  (deeper levels, and kind 167 at their own level).

  0x08ED36, 0x98 bytes: both by value; the levels signed bytes. }

function next_contained_block(
    outer: il_$node_ptr_t;
    b: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r: il_$node_ptr_t;
  n: il_$node_ptr_t;
  p: il_$node_ptr_t;
  lev: integer;
  done: boolean;
begin
  r := nil;
  n := b^.xp[1];
  done := false;
  while (n <> nil) and not done do begin
    if ((n^.kind = 108) or (n^.kind = 107)) and (n^.xw[132] = 0) and
       ((ord(n^.xc[374]) & 8) = 0) then begin
      lev := oi_level_ptr_t(n)^.level;
      repeat
        n := n^.xp[1];
        if n = nil then
          lev := -1000
        else if oi_level_ptr_t(n)^.level < lev then
          lev := -1000
        else if oi_level_ptr_t(n)^.level = lev then
          if n^.kind <> 167 then
            lev := -1000;
      until lev = -1000;
    end
    else begin
      p := n^.xp[2];
      while p <> nil do begin
        if p = outer then
          exit;
        p := p^.xp[2];
      end;
      if p <> nil then
        r := n;
      done := true;
    end;
  end;
  next_contained_block := r;
end;

{ find_block - the block of list l (through +8) whose name (+296) is
  name; reported as unexpected (cgerr_no_source 28) when there is
  none.

  0x08EDCE, 0x40 bytes: the result not set on the reporting path
  (A0 left as cgerr_no_source's). }

function find_block(
    l: il_$node_ptr_t;
    name: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r: il_$node_ptr_t;
begin
  r := l;
  while r <> nil do begin
    if r^.xp[74] = name then begin
      find_block := r;
      return;
    end;
    r := r^.xp[2];
  end;
  cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
end;

{ find_varn - the variable (109) a reference n names: n itself, the
  variable of a 163 (+8) or 195 (+12), or the variable of blk or an
  enclosing block (+8) whose name (+4) is the name of a symbol (111),
  of a routine block (107, +296), of a parameter (121, +8) or the
  identifier n (76); other nodes reported (cgerr_no_source 28) and
  looked up with the name unset.

  0x08EE28, 0x12C bytes: both by value; the variables of a block from
  its +16 through their +16. }

function find_varn(
    blk: il_$node_ptr_t;
    n: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r: il_$node_ptr_t;
  name: il_$node_ptr_t;
  x: il_$node_ptr_t;
  v: il_$node_ptr_t;
begin
  r := nil;
  case n^.kind of
    109:
      r := n;
    163: begin
      x := n^.xp[2];
      if x^.kind = 111 then
        name := x^.xp[1]
      else if x^.kind = 109 then
        r := x
      else
        cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end;
    195: begin
      x := n^.xp[3];
      if x^.kind = 111 then
        name := x^.xp[1]
      else if x^.kind = 107 then
        name := x^.xp[74]
      else if x^.kind = 109 then
        r := x
      else
        cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end;
    121:
      name := n^.xp[2];
    76:
      name := n;
    otherwise
      cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
  end;
  if r = nil then
    while blk <> nil do begin
      v := blk^.xp[4];
      while v <> nil do begin
        if (v^.kind = 109) and (v^.xp[1] = name) then begin
          find_varn := v;
          return;
        end;
        v := v^.xp[4];
      end;
      blk := blk^.xp[2];
    end;
  find_varn := r;
end;

{ get_size_rlen - d's size and register class (rlen) for the value of
  n: of a variable's, parameter's or type name's type (type_exp: the
  integral 122 by size 1, 2, 4 or 11, floating 123 single 6 or double
  7, ...), of a register temporary (110) by its class (+10 bits 3..0),
  of a constant by its kind, of a tree (137, 143) its own; references
  (146, 145, 147, 205: +28), symbols (111: +12) and 195 (+12) followed;
  size -1 and rlen 0 when not known.

  0x08EF54, 0x486 bytes, link #-40: d by address (size +0, rlen +4;
  `move.w (2,A2),(4,A2)' the size's low word as the class); the
  temporary's classes by a jump table (12 does nothing); 81 by -I*2. }

procedure get_size_rlen(
    n: il_$node_ptr_t;
    out d: add_node_$desc_t); options(val_param); internal;
var
  te: oi_texp_t;
  next: il_$node_ptr_t;
begin
  d.size := -1;
  d.rlen := 0;
  while n <> nil do begin
    next := nil;
    case n^.kind of
      121, 109, 118: begin
        type_exp(n, addr(te));
        d.size := te.size;
        case te.base^.kind of
          122:
            if te.size = 1 then
              d.rlen := 1
            else if te.size = 2 then
              d.rlen := 2
            else if te.size = 4 then
              d.rlen := 4
            else
              d.rlen := 11;
          123:
            if d.size = 4 then
              d.rlen := 6
            else
              d.rlen := 7;
          124:
            d.rlen := 1;
          125:
            if d.size = 1 then
              d.rlen := 1
            else
              d.rlen := 9;
          126:
            d.rlen := 9;
          127:
            d.rlen := 11;
          128, 129:
            d.rlen := d.size;
          130, 135:
            d.rlen := d.size;
          131:
            d.rlen := 11;
          132:
            if d.size <= 4 then
              d.rlen := d.size
            else if d.size = 8 then
              d.rlen := 7
            else
              d.rlen := 11;
          136, 134:
            if d.size <= 4 then
              d.rlen := d.size
            else if d.size = 8 then
              d.rlen := 7
            else
              d.rlen := 11;
          196:
            d.rlen := 11;
          177:
            d.rlen := d.size;
          otherwise
            d.size := -1;
        end;
      end;
      110:
        case ord(n^.xc[10]) & 15 of
          1, 8: begin
            d.size := 1;
            d.rlen := 1;
          end;
          2, 9: begin
            d.size := 2;
            d.rlen := 2;
          end;
          3, 10: begin
            d.size := 4;
            d.rlen := 4;
          end;
          4: begin
            d.size := 4;
            d.rlen := 6;
          end;
          5: begin
            d.size := 8;
            d.rlen := 7;
          end;
          6: begin
            d.size := 8;
            d.rlen := 8;
          end;
          7: begin
            d.rlen := 1;
            if ord(n^.xc[10]) >= 128 then
              d.size := 0
            else if n^.xw[4] = -1 then
              d.size := 2
            else
              d.size := n^.xw[4];
          end;
          11: begin
            d.size := 4;
            d.rlen := 5;
          end;
          13: begin
            d.size := 16;
            d.rlen := 12;
          end;
          otherwise
            ;
        end;
      122: begin
        d.rlen := n^.xw[2];
        if d.rlen = 1 then
          d.size := 1
        else if d.rlen = 2 then
          d.size := 2
        else if d.rlen = 4 then
          d.size := 4;
      end;
      111:
        if n^.xp[3] <> nil then
          next := n^.xp[3]
        else begin
          d.size := n^.xl[5];
          if d.size <= 4 then
            d.rlen := d.size
          else if d.size = 8 then
            d.rlen := 7
          else
            d.rlen := 11;
        end;
      195:
        next := n^.xp[3];
      143, 137: begin
        d.size := n^.xl[5];
        d.rlen := n^.xw[12];
        if d.size = 8 then
          if d.rlen = 11 then
            d.rlen := 7;
      end;
      146, 145, 147, 205:
        next := n^.xp[7];
      164: begin
        d.size := n^.xw[15];
        d.rlen := 1;
      end;
      77, 200, 87: begin
        d.size := 1;
        d.rlen := 1;
      end;
      78, 80: begin
        d.size := 2;
        d.rlen := 2;
      end;
      79, 82: begin
        d.size := 4;
        d.rlen := 4;
      end;
      81:
        if cargs_$options.i_star_2 then begin
          d.size := 2;
          d.rlen := 2;
        end
        else begin
          d.size := 4;
          d.rlen := 4;
        end;
      88: begin
        d.size := 4;
        d.rlen := 6;
      end;
      89: begin
        d.size := 8;
        d.rlen := 7;
      end;
      90: begin
        d.size := 8;
        d.rlen := 8;
      end;
      198: begin
        d.size := 16;
        d.rlen := 12;
      end;
      otherwise
        ;
    end;
    n := next;
  end;
end;

{ inline_$mark_reference_params - the variables call t (an operator
  137 or 143 of op 15 or 16) passes by reference in statement s: each
  actual of a parameter whose class is above 6 that names a variable
  (get_referenced_symbol) is marked (a 109's +34 bit 5, a 110's +26
  bit 5), and s marked (+42 bit 6) unless the callee is a routine
  type (159).  The parameters' classes: a routine type's (159) the
  low nibble of its +11 + 2k, k moving on unless +10 + 2k's bit 7 (the
  last, repeated); a routine block's (167, 108, 107) its word +394 +
  2k (9 for language 4); 174 and 173 their +78 + 2k; 171 none (9).
  In a routine of language 2 (il_180) every actual is so marked
  (and s), unless the callee is a routine type.

  0x08F49A, 0x1C4 bytes, link #-20: both by value; loads A5; the
  callee's kind against the 22-byte set after the routine (107, 108,
  159, 167, 171, 173, 174); the loops count the operands from the
  second down with a frame word and `bcc', the Fortran one by `dbf'. }

procedure inline_$mark_reference_params(
    t: il_$node_ptr_t;
    s: il_$node_ptr_t);
    options(val_param);

  { get_referenced_symbol - the variable (109, 110) a reference t
    names: through an indexing or displacement's base (+28, else
    +24), a pointer's (146: +28 only), a 205's +32 (else +24), a
    164's +20, an address operator's (137 op 26) operand; nil
    otherwise.

    0x08F3DA, 0x0C0 bytes: recursive, no static link used. }

  function get_referenced_symbol(
      t: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
  var
    r: il_$node_ptr_t;
  begin
    if t = nil then
      get_referenced_symbol := nil
    else
      case t^.kind of
        110, 109: begin
          r := t;
          get_referenced_symbol := r;
        end;
        145, 147: begin
          if t^.xp[7] <> nil then begin
            r := t^.xp[7];
            if (r^.kind = 110) or (r^.kind = 109) then begin
              get_referenced_symbol := r;
              return;
            end;
          end;
          get_referenced_symbol := get_referenced_symbol(t^.xp[6]);
        end;
        146: begin
          r := nil;
          if t^.xp[7] <> nil then
            if (t^.xp[7]^.kind = 110) or (t^.xp[7]^.kind = 109) then
              r := t^.xp[7];
          get_referenced_symbol := r;
        end;
        205: begin
          if t^.xp[8] <> nil then begin
            r := t^.xp[8];
            if (r^.kind = 110) or (r^.kind = 109) then begin
              get_referenced_symbol := r;
              return;
            end;
          end;
          get_referenced_symbol := get_referenced_symbol(t^.xp[6]);
        end;
        164:
          get_referenced_symbol := get_referenced_symbol(t^.xp[5]);
        137:
          if t^.xw[18] = 26 then
            get_referenced_symbol := get_referenced_symbol(t^.xp[10])
          else
            get_referenced_symbol := nil;
        otherwise
          get_referenced_symbol := nil;
      end;
  end;

var
  n: integer;
  r: il_$node_ptr_t;
  v: il_$node_ptr_t;
  k: integer;
  j: integer;
  cls: integer;
begin
  if not ((t^.kind = 143) or (t^.kind = 137)) then
    return;
  if not ((t^.xw[18] = 16) or (t^.xw[18] = 15)) then
    return;
  n := t^.xw[19];
  r := t^.xp[10];
  if (r^.kind = 147) or (r^.kind = 146) then
    r := r^.xp[7];
  if r^.kind = 175 then
    r := r^.xp[5];
  if (rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2) and (r^.kind <> 159) then begin
    for j := 1 to n - 1 do begin
      v := get_referenced_symbol(t^.xp[10 + j]);
      if v <> nil then
        if v^.kind = 109 then begin
          v^.xc[34] := chr(ord(v^.xc[34]) ! 32);
          s^.xc[42] := chr(ord(s^.xc[42]) ! 64);
        end
        else if v^.kind = 110 then begin
          v^.xc[26] := chr(ord(v^.xc[26]) ! 32);
          s^.xc[42] := chr(ord(s^.xc[42]) ! 64);
        end;
    end;
    return;
  end;
  if not (r^.kind in [107, 108, 159, 167, 171, 173, 174]) then
    return;
  k := 1;
  for j := 1 to n - 1 do begin
    case r^.kind of
      159: begin
        cls := ord(r^.xc[11 + 2 * k]) & 15;
        if ord(r^.xc[10 + 2 * k]) < 128 then
          k := k + 1;
      end;
      167, 108, 107:
        if rshft(ord(r^.xc[377]) & 16#70, 4) = 4 then
          cls := 9
        else
          cls := r^.xw[197 + j];
      174, 173:
        cls := r^.xw[39 + j];
      otherwise
        cls := 9;
    end;
    if (cls & 16#FFFF) > 6 then begin
      v := get_referenced_symbol(t^.xp[10 + j]);
      if v <> nil then
        if v^.kind = 109 then begin
          v^.xc[34] := chr(ord(v^.xc[34]) ! 32);
          if r^.kind <> 159 then
            s^.xc[42] := chr(ord(s^.xc[42]) ! 64);
        end
        else if v^.kind = 110 then begin
          v^.xc[26] := chr(ord(v^.xc[26]) ! 32);
          if r^.kind <> 159 then
            s^.xc[42] := chr(ord(s^.xc[42]) ! 64);
        end;
    end;
  end;
end;

{ function_return - the variable routine block b's result is kept in:
  a 107's +96; none for a 108 returning void; else a 108's +96, or
  the variable of its list (+16) named as the routine (+296; in a
  Fortran callee the entry of its list, through +4, of +44 class 1
  and +11 class 5), reported (cgerr_no_source 28) when none.

  0x08F674, 0xC8 bytes. }

function function_return(
    b: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r: il_$node_ptr_t;
  v: il_$node_ptr_t;
begin
  if b^.kind = 107 then
    r := b^.xp[24]
  else if (b^.kind = 108) and assert_routine_returns_void(b) then
    r := nil
  else if b^.kind = 108 then begin
    r := b^.xp[24];
    if r = nil then begin
      v := b^.xp[4];
      while v <> nil do begin
        if language = 2 then begin
          if (rshft(ord(v^.xc[44]) & 16#F0, 4) = 1) and
             (rshft(ord(v^.xc[11]) & 16#F0, 4) = 5) then begin
            r := v;
            v := nil;
          end
          else
            v := v^.xp[1];
        end
        else if v^.xp[1] = b^.xp[74] then begin
          r := v;
          v := nil;
        end
        else
          v := v^.xp[4];
      end;
      if r = nil then
        cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end;
  end
  else
    r := nil;
  function_return := r;
end;

{ current_ln - the line of statement s or of the nearest statement
  before it (+4) that has one; 0 when none.

  0x08F73C, 0x1A bytes, no frame: the line in D0. }

function current_ln(
    s: il_$node_ptr_t): integer; options(val_param); internal;
var
  ln: integer;
begin
  ln := 0;
  while s <> nil do begin
    ln := s^.xw[10];
    if ln <> 0 then
      s := nil
    else
      s := s^.xp[1];
  end;
  current_ln := ln;
end;

{ cleanup_hash - the hash table's entries made in context ctx
  forgotten (their node cleared), but for those of flag 3 unless all.

  0x08F756, 0x46 bytes: all a word; the 1009 chains by `dbf', each
  from the table's element. }

procedure cleanup_hash(
    ctx: il_$node_ptr_t;
    all: integer); options(val_param); internal;
var
  i: integer;
  e: oi_hash_ptr_t;
begin
  for i := 0 to 1008 do begin
    e := addr(hash[i]);
    repeat
      if (all <> 0) or not (3 in e^.flags) then
        if e^.ctx = ctx then
          e^.node := nil;
      e := e^.next;
    until e = nil;
  end;
end;

{ get_hash_info - what node n of the callee becomes in the copy for
  edge e (the entry of n and e's caller): val, flags and the display
  record (empty when the entry has none); nothing (nil, no flags, the
  empty record) for nil or an unknown node.

  0x08F79C, 0xCE bytes, link #-12: the chain (n's address shifted
  right 3, mod 1009: M$OIS$WLW) searched from the table's element;
  the records copied by six `move.l'. }

procedure get_hash_info(
    e: oi_edge_ptr_t;
    n: il_$node_ptr_t;
    out val: il_$node_ptr_t;
    out flags: oi_flags_t;
    out info: oi_info_t); options(val_param); internal;
var
  h: integer;
  p: oi_hash_ptr_t;
begin
  if n = nil then begin
    val := nil;
    flags := [];
    info := empty_info;
    return;
  end;
  h := rshft(integer32(n), 3) mod 1009;
  p := addr(hash[h]);
  repeat
    if (p^.node = n) and (p^.ctx = e^.caller) then
      exit;
    p := p^.next;
  until p = nil;
  if p <> nil then begin
    val := p^.val;
    flags := p^.flags;
    if p^.info <> nil then
      info := p^.info^
    else
      info := empty_info;
  end
  else begin
    val := nil;
    flags := [];
    info := empty_info;
  end;
end;

{ put_hash_info - node n of the callee becomes val (with flags and
  the display record info) in the copy for edge e: its entry, or a
  free one of its chain, or a new one after the chain's head; an
  existing entry of flag 4 kept.  The record is kept (a copy from
  the heap) when it is n's own (its node n) or has +20.

  0x08F86A, 0xF0 bytes, link #-20: flags a word at (20,A6), info by
  address at (22,A6); `new or no node' evaluated whole (`seq', `or.b'). }

procedure put_hash_info(
    e: oi_edge_ptr_t;
    n: il_$node_ptr_t;
    val: il_$node_ptr_t;
    flags: oi_flags_t;
    in info: oi_info_t); options(val_param); internal;
var
  h: integer;
  head: oi_hash_ptr_t;
  p: oi_hash_ptr_t;
  new: boolean;
begin
  if n = nil then
    return;
  h := rshft(integer32(n), 3) mod 1009;
  head := addr(hash[h]);
  p := head;
  repeat
    if p^.node = nil then
      exit;
    if (p^.node = n) and (p^.ctx = e^.caller) then
      exit;
    p := p^.next;
  until p = nil;
  if p = nil then begin
    p := mrh_$alloc(heap, 24);
    p^.next := head^.next;
    head^.next := p;
    new := true;
  end
  else
    new := false;
  if new or (p^.node = nil) or not (4 in flags) then begin
    p^.node := n;
    p^.ctx := e^.caller;
    p^.val := val;
    p^.flags := flags;
    if (info.node = n) or (info.i20 <> nil) then begin
      p^.info := mrh_$alloc(heap, 24);
      p^.info^ := info;
    end
    else
      p^.info := nil;
  end;
end;

{ coerce - tree t, of class from, made of class to for edge e: from
  and to must be classes 1, 2, 4..8 or 12, and a pointer (5) meets
  only a longword or pointer outside languages 3 and 4 (else reported,
  cgerr_no_source 28); conversions between integers and reals go
  through a longword (4) or a single (6) or double (7) first.

  0x08FA6C, 0x1F0 bytes: the classes words, signed a byte; the class
  sets as `btst' of 0x11F6 and of 24 (languages 3, 4); the cases by a
  jump table of 12. }

procedure coerce(
    e: oi_edge_ptr_t;
    var t: il_$node_ptr_t;
    have: integer;
    want: integer;
    signed: boolean); options(val_param); internal;

  { extend - t, of class from, converted to class to: nothing when
    they are equal or both are longwords or pointers (4, 5); a
    conversion's operand when t converts it (op 39 or 18) from class
    to; else a conversion (39 between reals, 18 otherwise) of the
    class's bytes (class_bytes) built over t, e's caller's count of
    such nodes (+272) raised.

    0x08F95A, 0x112 bytes, link #-32: the descriptor cleared by a loop
    of 16 bytes. }

  procedure extend(
      e: oi_edge_ptr_t;
      var t: il_$node_ptr_t;
      have: integer;
      want: integer;
      signed: boolean); options(val_param);
  var
    op: integer;
    i: integer;
    d: oi_desc_t;
    n: il_$node_ptr_t;
  begin
    if have = want then
      return;
    if (want = 5) or (want = 4) then
      if (have = 5) or (have = 4) then
        return;
    n := t;
    if n^.kind = 137 then
      if (n^.xw[18] = 39) or (n^.xw[18] = 18) then
        if n^.xw[13] = want then begin
          t := n^.xp[10];
          return;
        end;
    e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
    for i := 1 to 16 do
      d.b[i] := chr(0);
    d.d.rlen := want;
    d.d.size := class_bytes[want];
    d.d.w6 := have;
    d.d.flags.signed := signed;
    if (have = 6) or (have = 7) or (have = 8) or (have = 12) or
       (want = 6) or (want = 7) or (want = 12) or (want = 8) then
      op := 39
    else
      op := 18;
    t := buildtreenode(op, d.d, t, 1);
  end;

begin
  if not (have in [1, 2, 4..8, 12]) then
    cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
  if not (want in [1, 2, 4..8, 12]) then
    cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
  if (have = 5) or (want = 5) then
    if not (language in [3, 4]) then
      if not (((have = 5) or (have = 4)) and ((want = 5) or (want = 4))) then
        cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
  case want of
    1, 2:
      if (have = 6) or (have = 7) or (have = 12) or (have = 8) then begin
        coerce(e, t, have, 4, signed);
        have := 4;
      end;
    4:
      if have = 8 then begin
        coerce(e, t, have, 6, signed);
        have := 6;
      end
      else if have = 12 then begin
        coerce(e, t, have, 7, signed);
        have := 7;
      end;
    6:
      if (have = 2) or (have = 1) then begin
        coerce(e, t, have, 4, signed);
        have := 4;
      end
      else if have = 12 then begin
        coerce(e, t, have, 7, signed);
        have := 7;
      end;
    7:
      if have = 8 then begin
        coerce(e, t, have, 6, signed);
        have := 6;
      end
      else if (have = 2) or (have = 1) then begin
        coerce(e, t, have, 4, signed);
        have := 4;
      end;
    8:
      if (have = 1) or (have = 2) or (have = 7) or (have = 4) then begin
        coerce(e, t, have, 6, signed);
        have := 6;
      end;
    12:
      if (have = 1) or (have = 2) or (have = 6) or (have = 4) then begin
        coerce(e, t, have, 7, signed);
        have := 7;
      end;
    otherwise
      ;
  end;
  extend(e, t, have, want, signed);
end;

{ start_il_stream - a new stream of statements for the copy at call
  s: its head an evaluation (139) of one operand, an integer constant
  node (81, 12 bytes), at s's line, flags +41..+42 0x8000 (+41 bit 7).

  0x08FC5C, 0x7E bytes: the first parameter not read; the header's
  flags stored as `andi.l #0xFF0000FF; or.l #0x800000' of the
  longword at +40. }

procedure start_il_stream(
    e: oi_edge_ptr_t;
    s: il_$node_ptr_t); options(val_param); internal;
begin
  stream_head := gspace(56);
  stream_head^.kind := 139;
  stream_head^.xw[25] := 1;
  stream_head^.xp[13] := gspace(12);
  stream_head^.xp[13]^.kind := 81;
  stream_head^.xl[10] := (stream_head^.xl[10] & 16#FF0000FF) ! 16#800000;
  stream_head^.xw[10] := s^.xw[4];
  stream_tail := stream_head;
end;

{ inline_$compatible_types - descriptors a and b (size, rlen) hold the
  same kind of value: the same class, or a block (11) of the other's
  size.

  0x08FCDA, 0x36 bytes, no frame: both by address. }

function inline_$compatible_types(
    in a: add_node_$desc_t;
    in b: add_node_$desc_t): boolean; internal;
begin
  if a.rlen = b.rlen then
    inline_$compatible_types := true
  else if (a.rlen = 11) and (a.size = b.size) then
    inline_$compatible_types := true
  else if b.rlen = 11 then
    inline_$compatible_types := b.size = a.size
  else
    inline_$compatible_types := false;
end;

{ patch_il - the stream built for edge e put in place of its call's
  statement (+20): when x's result (+4) is set, the stream goes
  before the statement and the call's slots (e's sites, through l)
  get the result (the value the callee's result variable became,
  get_hash_info, its operand when flags 1 or 2; converted to the
  call's class, coerce); a Fortran statement function's stream
  replaces the statement but for its last assignment, whose value is
  the result; without a result the statement is unlinked.  The
  caller's blocks' +100 and +104 then mapped (get_hash_info) and the
  caller's +100 set to the stream's first statement.

  0x08FD10, 0x25E bytes, link #-136: l by address (the loop's cursor);
  the descriptors at -88 and -96; the conversion's uses (+16) the
  call's. }

procedure patch_il(
    e: oi_edge_ptr_t;
    x: il_$node_ptr_t;
    var l: oi_site_list_ptr_t); options(val_param); internal;
var
  s: il_$node_ptr_t;
  v: il_$node_ptr_t;
  val: il_$node_ptr_t;
  flags: oi_flags_t;
  info: oi_info_t;
  d1: add_node_$desc_t;
  d2: add_node_$desc_t;
  b: il_$node_ptr_t;
begin
  if x^.xp[1] <> nil then begin
    if inline_$is_fortran_asf(e^.callee) then begin
      s := stream_tail;
      while s^.kind <> 140 do
        s := s^.xp[1];
      v := s^.xp[17];
      stream_head^.xp[1] := e^.stmt^.xp[1];
      stream_head^.xp[1]^.xp[2] := stream_head;
      stream_tail^.xp[2] := e^.stmt^.xp[2];
      stream_tail^.xp[2]^.xp[1] := stream_tail;
      e^.stmt^.xp[2] := s^.xp[2];
      e^.stmt^.xp[2]^.xp[1] := e^.stmt;
      e^.stmt^.xp[1] := s^.xp[1];
      e^.stmt^.xp[1]^.xp[2] := e^.stmt;
    end
    else begin
      get_hash_info(e, x^.xp[1], val, flags, info);
      v := val;
      if (flags * [1, 2]) <> [] then
        v := v^.xp[10];
      stream_head^.xp[1] := e^.stmt^.xp[1];
      stream_head^.xp[1]^.xp[2] := stream_head;
      stream_tail^.xp[2] := e^.stmt;
      stream_tail^.xp[2]^.xp[1] := stream_tail;
    end;
    get_size_rlen(v, d1);
    get_size_rlen(e^.call, d2);
    if not inline_$compatible_types(d1, d2) and (d2.rlen <> 0) then begin
      val := v;
      coerce(e, val, d1.rlen, d2.rlen, (ord(e^.call^.xc[30]) & 64) <> 0);
      v := val;
      if v^.kind = 137 then
        v^.xw[8] := e^.call^.xw[8];
    end;
    l := e^.sites;
    while l <> nil do begin
      l^.site^ := v;
      l := l^.next;
    end;
  end
  else begin
    if stream_head <> stream_tail then begin
      stream_head^.xp[1] := e^.stmt^.xp[1];
      stream_head^.xp[1]^.xp[2] := stream_head;
      stream_tail^.xp[2] := e^.stmt;
      stream_tail^.xp[2]^.xp[1] := stream_tail;
    end;
    e^.stmt^.xp[1]^.xp[2] := e^.stmt^.xp[2];
    e^.stmt^.xp[2]^.xp[1] := e^.stmt^.xp[1];
  end;
  b := caller_blk;
  repeat
    get_hash_info(e, b^.xp[25], b^.xp[25], flags, info);
    get_hash_info(e, b^.xp[26], b^.xp[26], flags, info);
    b := next_contained_block(caller_blk, b);
  until b = nil;
  caller_blk^.xp[25] := stream_head^.xp[2];
end;

{ put_on_il_stream - statement s appended to the stream (+41 bit 7
  set).

  0x08FF6E, 0x22 bytes, no frame. }

procedure put_on_il_stream(
    s: il_$node_ptr_t); options(val_param); internal;
begin
  s^.xp[1] := stream_tail;
  stream_tail^.xp[2] := s;
  stream_tail := s;
  stream_tail^.xc[41] := chr(ord(stream_tail^.xc[41]) ! 128);
end;

{ actual_actual - the object an actual t refers to through
  displacements (147: +24) and pointers (146: +24, or +28 when that is
  a 195 or 163), and its captured lvalue's indirection
  (alias_$ind_for_captured_lvalue, set only for a 147 or 146).

  0x08FF90, 0x82 bytes: ind by address. }

function actual_actual(
    t: il_$node_ptr_t;
    out ind: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r: il_$node_ptr_t;
  p: il_$node_ptr_t;
begin
  r := t;
  if (r^.kind = 147) or (r^.kind = 146) then begin
    while (r^.kind = 147) or (r^.kind = 146) do begin
      if r^.kind = 147 then
        r := r^.xp[6];
      if r^.kind = 146 then begin
        p := r^.xp[6];
        if (p^.kind = 195) or (p^.kind = 163) then
          r := r^.xp[7]
        else
          r := p;
      end;
    end;
    ind := alias_$ind_for_captured_lvalue(t);
  end;
  actual_actual := r;
end;
