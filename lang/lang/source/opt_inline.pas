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

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on node kind sets), 24
  (function_return's call as a right operand of `and', process_operand's
  `and not inline_$is_fortran_asf').  find_block,
  get_referenced_symbol, inliner_actual and substitutee_sym_ind set
  their pointer results from a local (gap 15).

  Not known from the original: every name but the routines'; the
  display record's (oi_info_t) and the context's (oi_ctx_t) fields
  are named by use.
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
    scope: il_$node_ptr_t;              { +12: the block the call is
                                          in (runbackend's ref_stmt) }
    call: il_$node_ptr_t;               { +16: the call (or reference) }
    stmt: il_$node_ptr_t;               { +20: the call's statement }
    sites: oi_site_list_ptr_t;          { +24: kind 16 calls' slots }
    callee_next: oi_edge_ptr_t;         { +28 }
    caller_next: oi_edge_ptr_t;         { +32 }
  end;

  { What a node of the callee becomes in the copy (24 bytes, kept by
    put_hash_info; the empty one at +0x5EB0, nil_out_dispinfo): the
    displacement still to be applied to the reference whose base node
    is node (adjust_disp, apply_disp: add_dn of disp_sym and disp,
    add_sdn of sdn_sym and sdn_var) and the actual's captured
    indirection (process_parameters). }
  oi_info_ptr_t = ^oi_info_t;
  oi_info_t = record
    node: il_$node_ptr_t;               { +0 }
    disp: integer32;                    { +4 }
    disp_sym: il_$node_ptr_t;           { +8 }
    sdn_var: il_$node_ptr_t;            { +12 }
    sdn_sym: il_$node_ptr_t;            { +16 }
    ind: il_$node_ptr_t;                { +20 }
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

  { A name's characters (assign_name), the pattern of the names made. }
  oi_chars_ptr_t = ^oi_chars_t;
  oi_chars_t = array [1..4096] of char;
  oi_pattern_t = array [1..11] of char;

  { A language 2 callee's parameters (its +12): 12 bytes each from
    [1], the parameter's symbol first. }
  oi_ftab_ptr_t = ^oi_ftab_t;
  oi_ftab_t = array [0..255] of record
    sym: il_$node_ptr_t;                { +0 }
    unused_4: integer32;                { +4 }
    unused_8: integer32;                { +8 }
  end;

  { What dfs_walk keeps of a call being expanded (its frame at -16):
    the block the statement being copied is in (process_operand, at
    each 148 and 149; never set before the first), the callee's result
    variable (call_status) and the call's line (current_ln). }
  oi_call_t = record
    blk: il_$node_ptr_t;                { +0 }
    result: il_$node_ptr_t;             { +4 }
    line: integer;                      { +8 }
  end;

  { A variable and the symbol it is reached by (get_sym_ind_info). }
  oi_symind_t = record
    v: il_$node_ptr_t;                  { +0 }
    sym: il_$node_ptr_t;                { +4 }
  end;

  { process_operand's context (30 bytes, by value): the reference
    being rebuilt (+0 the reference whose base is rebased, +4 the call
    whose routine operand is being copied, +8 its displacement node
    (147), +12 its symbolic displacement node (205), +16 and +20 the
    symbol and variable it is reached by (process_opr_ind), +24 the
    kind that set them), +26 the use count for the nodes made, +28 set
    when a substitution was made (substitutee_sym_ind). }
  oi_ctx_t = record
    base: il_$node_ptr_t;               { +0 }
    call: il_$node_ptr_t;               { +4 }
    dnode: il_$node_ptr_t;              { +8 }
    sdn: il_$node_ptr_t;                { +12 }
    sym: il_$node_ptr_t;                { +16 }
    v: il_$node_ptr_t;                  { +20 }
    kind: integer;                      { +24 }
    uses: integer;                      { +26 }
    subst: boolean;                     { +28 }
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
  inline_$mark_reference_params, inline_$inline_expand;

{ inline_$is_fortran_asf - b is a Fortran statement function: the
  callee's language 2 and b a routine block (108) with +376 bit 3.

  0x08EC38, 0x22 bytes, no frame (pattern 16): b at (4,SP), the
  result in D0. }

function inline_$is_fortran_asf(
    b: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if (language = 2) and (b^.kind = function_blk) then
    inline_$is_fortran_asf := b^.blk_atts.local_name_only
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
    assert_is_nonleaf_lvalue := (t^.kind = sym_disp_node)
        or (t^.kind = disp_node) or
                                (t^.kind = ptr_node) or (t^.kind = dindex_node)
  else
    assert_is_nonleaf_lvalue := false;
end;

{ assert_is_a_routine_block - b is a routine's block (108, 107, 105).

  0x08EC90, 0x2C bytes, no frame. }

function assert_is_a_routine_block(
    b: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if b <> nil then
    assert_is_a_routine_block := (b^.kind = function_blk)
        or (b^.kind = procedure_blk) or
                                 (b^.kind = program_blk)
  else
    assert_is_a_routine_block := false;
end;

{ assert_is_void_type - t is the type void (210).

  0x08ECBC, 0x18 bytes, no frame. }

function assert_is_void_type(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if t <> nil then
    assert_is_void_type := t^.kind = void_type
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
    if b^.xp[7]^.kind = type_name then
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
  d.disp := 0;
  d.disp_sym := nil;
  d.sdn_var := nil;
  d.sdn_sym := nil;
  d.ind := nil;
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
    if ((n^.kind = function_blk) or (n^.kind = procedure_blk))
        and (n^.xw[132] = 0) and
       (not n^.blk_atts.visible) then begin
      lev := oi_level_ptr_t(n)^.level;
      repeat
        n := n^.xp[1];
        if n = nil then
          lev := -1000
        else if oi_level_ptr_t(n)^.level < lev then
          lev := -1000
        else if oi_level_ptr_t(n)^.level = lev then
          if n^.kind <> entry_blk then
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
    var_name:
      r := n;
    addr_con: begin
      x := n^.xp[2];
      if x^.kind = common_block_name then
        name := x^.xp[1]
      else if x^.kind = var_name then
        r := x
      else
        cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end;
    reloc_absolute_addr_con: begin
      x := n^.xp[3];
      if x^.kind = common_block_name then
        name := x^.xp[1]
      else if x^.kind = procedure_blk then
        name := x^.xp[74]
      else if x^.kind = var_name then
        r := x
      else
        cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end;
    param_name:
      name := n^.xp[2];
    id_ob:
      name := n;
    otherwise
      cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
  end;
  if r = nil then
    while blk <> nil do begin
      v := blk^.xp[4];
      while v <> nil do begin
        if (v^.kind = var_name) and (v^.xp[1] = name) then begin
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
  d.rlen := rlen_null;
  while n <> nil do begin
    next := nil;
    case n^.kind of
      param_name, var_name, type_name: begin
        type_exp(n, addr(te));
        d.size := te.size;
        case te.base^.kind of
          integer_type:
            if te.size = 1 then
              d.rlen := rlen_byte
            else if te.size = 2 then
              d.rlen := rlen_word
            else if te.size = 4 then
              d.rlen := rlen_long
            else
              d.rlen := rlen_agg;
          real_type:
            if d.size = 4 then
              d.rlen := rlen_r4
            else
              d.rlen := rlen_r8;
          bool_type:
            d.rlen := rlen_byte;
          char_type:
            if d.size = 1 then
              d.rlen := rlen_byte
            else
              d.rlen := rlen_cs;
          char_string_con_type:
            d.rlen := rlen_cs;
          char_array_type:
            d.rlen := rlen_agg;
          subr_type, enum_type:
            d.rlen := d.size;
          ptr_type, univ_ptr_type:
            d.rlen := d.size;
          array_type:
            d.rlen := rlen_agg;
          record_type:
            if d.size <= 4 then
              d.rlen := d.size
            else if d.size = 8 then
              d.rlen := rlen_r8
            else
              d.rlen := rlen_agg;
          null_set_type, set_type:
            if d.size <= 4 then
              d.rlen := d.size
            else if d.size = 8 then
              d.rlen := rlen_r8
            else
              d.rlen := rlen_agg;
          varying_type:
            d.rlen := rlen_agg;
          offset_type:
            d.rlen := d.size;
          otherwise
            d.size := -1;
        end;
      end;
      fortran_symbol:
        case ord(n^.xc[10]) & 15 of
          1, 8: begin
            d.size := 1;
            d.rlen := rlen_byte;
          end;
          2, 9: begin
            d.size := 2;
            d.rlen := rlen_word;
          end;
          3, 10: begin
            d.size := 4;
            d.rlen := rlen_long;
          end;
          4: begin
            d.size := 4;
            d.rlen := rlen_r4;
          end;
          5: begin
            d.size := 8;
            d.rlen := rlen_r8;
          end;
          6: begin
            d.size := 8;
            d.rlen := rlen_c8;
          end;
          7: begin
            d.rlen := rlen_byte;
            if ord(n^.xc[10]) >= 128 then
              d.size := 0
            else if n^.xw[4] = -1 then
              d.size := 2
            else
              d.size := n^.xw[4];
          end;
          11: begin
            d.size := 4;
            d.rlen := rlen_addr;
          end;
          13: begin
            d.size := 16;
            d.rlen := rlen_c16;
          end;
          otherwise
            ;
        end;
      integer_type: begin
        d.rlen := n^.xw[2];
        if d.rlen = rlen_byte then
          d.size := 1
        else if d.rlen = rlen_word then
          d.size := 2
        else if d.rlen = rlen_long then
          d.size := 4;
      end;
      common_block_name:
        if n^.xp[3] <> nil then
          next := n^.xp[3]
        else begin
          d.size := n^.xl[5];
          if d.size <= 4 then
            d.rlen := d.size
          else if d.size = 8 then
            d.rlen := rlen_r8
          else
            d.rlen := rlen_agg;
        end;
      reloc_absolute_addr_con:
        next := n^.xp[3];
      cmp_tree_node, tree_node: begin
        d.size := n^.xl[5];
        d.rlen := n^.tr_rlen;
        if d.size = 8 then
          if d.rlen = rlen_agg then
            d.rlen := rlen_r8;
      end;
      ptr_node, dindex_node, disp_node, sym_disp_node:
        next := n^.xp[7];
      cs_node: begin
        d.size := n^.xw[15];
        d.rlen := rlen_byte;
      end;
      blogical_ob, binteger_ob, char_ob: begin
        d.size := 1;
        d.rlen := rlen_byte;
      end;
      slogical_ob, sinteger_ob: begin
        d.size := 2;
        d.rlen := rlen_word;
      end;
      llogical_ob, linteger_ob: begin
        d.size := 4;
        d.rlen := rlen_long;
      end;
      integer_ob:
        if cargs_$options.i_star_2 then begin
          d.size := 2;
          d.rlen := rlen_word;
        end
        else begin
          d.size := 4;
          d.rlen := rlen_long;
        end;
      real_ob: begin
        d.size := 4;
        d.rlen := rlen_r4;
      end;
      dpreal_ob: begin
        d.size := 8;
        d.rlen := rlen_r8;
      end;
      complex_ob: begin
        d.size := 8;
        d.rlen := rlen_c8;
      end;
      dpcomplex_ob: begin
        d.size := 16;
        d.rlen := rlen_c16;
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
        fortran_symbol, var_name: begin
          r := t;
          get_referenced_symbol := r;
        end;
        dindex_node, disp_node: begin
          if t^.xp[7] <> nil then begin
            r := t^.xp[7];
            if (r^.kind = fortran_symbol) or (r^.kind = var_name) then begin
              get_referenced_symbol := r;
              return;
            end;
          end;
          get_referenced_symbol := get_referenced_symbol(t^.xp[6]);
        end;
        ptr_node: begin
          r := nil;
          if t^.xp[7] <> nil then
            if (t^.xp[7]^.kind = fortran_symbol)
                or (t^.xp[7]^.kind = var_name) then
              r := t^.xp[7];
          get_referenced_symbol := r;
        end;
        sym_disp_node: begin
          if t^.xp[8] <> nil then begin
            r := t^.xp[8];
            if (r^.kind = fortran_symbol) or (r^.kind = var_name) then begin
              get_referenced_symbol := r;
              return;
            end;
          end;
          get_referenced_symbol := get_referenced_symbol(t^.xp[6]);
        end;
        cs_node:
          get_referenced_symbol := get_referenced_symbol(t^.xp[5]);
        tree_node:
          if t^.tr_op = addr_top then
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
  if not ((t^.kind = cmp_tree_node) or (t^.kind = tree_node)) then
    return;
  if not ((t^.tr_op = func_call_top) or (t^.tr_op = call_top)) then
    return;
  n := t^.xw[19];
  r := t^.xp[10];
  if (r^.kind = disp_node) or (r^.kind = ptr_node) then
    r := r^.xp[7];
  if r^.kind = pf_call then
    r := r^.xp[5];
  if (il_180^.blk_atts.call = call_ftn)
      and (r^.kind <> lib_dsc) then begin
    for j := 1 to n - 1 do begin
      v := get_referenced_symbol(t^.xp[10 + j]);
      if v <> nil then
        if v^.kind = var_name then begin
          v^.xc[34] := chr(ord(v^.xc[34]) ! 32);
          s^.st_flags.b42_6 := true;
        end
        else if v^.kind = fortran_symbol then begin
          v^.xc[26] := chr(ord(v^.xc[26]) ! 32);
          s^.st_flags.b42_6 := true;
        end;
    end;
    return;
  end;
  if not (r^.kind in [procedure_blk, function_blk, lib_dsc, entry_blk, cc_call,
                      proc__type, func__type]) then
    return;
  k := 1;
  for j := 1 to n - 1 do begin
    case r^.kind of
      lib_dsc: begin
        cls := ord(r^.xc[11 + 2 * k]) & 15;
        if ord(r^.xc[10 + 2 * k]) < 128 then
          k := k + 1;
      end;
      entry_blk, function_blk, procedure_blk:
        if r^.blk_atts.call = call_c_std then
          cls := 9
        else
          cls := r^.xw[197 + j];
      func__type, proc__type:
        cls := r^.xw[39 + j];
      otherwise
        cls := 9;
    end;
    if (cls & 16#FFFF) > 6 then begin
      v := get_referenced_symbol(t^.xp[10 + j]);
      if v <> nil then
        if v^.kind = var_name then begin
          v^.xc[34] := chr(ord(v^.xc[34]) ! 32);
          if r^.kind <> lib_dsc then
            s^.st_flags.b42_6 := true;
        end
        else if v^.kind = fortran_symbol then begin
          v^.xc[26] := chr(ord(v^.xc[26]) ! 32);
          if r^.kind <> lib_dsc then
            s^.st_flags.b42_6 := true;
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
  if b^.kind = procedure_blk then
    r := b^.xp[24]
  else if (b^.kind = function_blk) and assert_routine_returns_void(b) then
    r := nil
  else if b^.kind = function_blk then begin
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
    if (info.node = n) or (info.ind <> nil) then begin
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
    op: il_$top_t;
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
    if n^.kind = tree_node then
      if (n^.tr_op = f_extend_top) or (n^.tr_op = extend_top) then
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
      op := f_extend_top
    else
      op := extend_top;
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

{ start_il_stream - a new stream of statements for the copy of call
  x: its head an evaluation (139) of one operand, an integer constant
  node (81, 12 bytes), at x's line, flags +41..+42 0x8000 (+41 bit 7).

  0x08FC5C, 0x7E bytes: the first parameter not read; the header's
  flags stored as `andi.l #0xFF0000FF; or.l #0x800000' of the
  longword at +40. }

procedure start_il_stream(
    e: oi_edge_ptr_t;
    var x: oi_call_t); options(val_param); internal;
begin
  stream_head := gspace(56);
  stream_head^.kind := eval_node;
  stream_head^.xw[25] := 1;
  stream_head^.xp[13] := gspace(12);
  stream_head^.xp[13]^.kind := integer_ob;
  stream_head^.xl[10] := (stream_head^.xl[10] & 16#FF0000FF) ! 16#800000;
  stream_head^.xw[10] := x.line;
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
  else if (a.rlen = rlen_agg) and (a.size = b.size) then
    inline_$compatible_types := true
  else if b.rlen = rlen_agg then
    inline_$compatible_types := b.size = a.size
  else
    inline_$compatible_types := false;
end;

{ patch_il - the stream built for edge e put in place of its call's
  statement (+20): when x's result is set, the stream goes
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
    var x: oi_call_t;
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
  if x.result <> nil then begin
    if inline_$is_fortran_asf(e^.callee) then begin
      s := stream_tail;
      while s^.kind <> assign_node do
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
      get_hash_info(e, x.result, val, flags, info);
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
    if not inline_$compatible_types(d1, d2) and (d2.rlen <> rlen_null) then begin
      val := v;
      coerce(e, val, d1.rlen, d2.rlen, (ord(e^.call^.xc[30]) & 64) <> 0);
      v := val;
      if v^.kind = tree_node then
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
  stream_tail^.st_flags.inliner_generated_stmt := true;
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
  if (r^.kind = disp_node) or (r^.kind = ptr_node) then begin
    while (r^.kind = disp_node) or (r^.kind = ptr_node) do begin
      if r^.kind = disp_node then
        r := r^.xp[6];
      if r^.kind = ptr_node then begin
        p := r^.xp[6];
        if (p^.kind = reloc_absolute_addr_con) or (p^.kind = addr_con) then
          r := r^.xp[7]
        else
          r := p;
      end;
    end;
    ind := alias_$ind_for_captured_lvalue(t);
  end;
  actual_actual := r;
end;

{ pass_method - how actual a (formal f, parameter p, the k-th) of edge
  e is bound: 0 substituted, 1 by reference, 2 through its address, 3
  copied to a temporary.  Without p's mode (+44) a language 1 callee's
  parameter of class (+394 + 2k) 7 or more is by reference; a language
  1 parameter of mode 2 and class below 7, not +46 bit 7, is
  substituted; a language 2 actual whose class differs from the
  formal's (but for operators 12, 23, 40, 24), or a language 1
  parameter of +46 bit 7, is copied; constants (77..82, 87..90) and
  trees (137, 143, 198, 200) are substituted, other constants (83..86,
  92, 93, 101, 156, 176) copied, and references go through their
  address when they reach a variable (109, 110, 111, 163, 195).

  0x090012, 0x15E bytes, link #-32: k a word at (12,A6); the kinds
  against the 26- and 24-byte sets after the routine; the result a
  word in D0. }

function pass_method(
    e: oi_edge_ptr_t;
    k: integer;
    a: il_$node_ptr_t;
    f: il_$node_ptr_t;
    p: il_$node_ptr_t): integer; options(val_param); internal;
var
  r: integer;
  d1: add_node_$desc_t;
  d2: add_node_$desc_t;
  ind: il_$node_ptr_t;
  x: il_$node_ptr_t;
  done: boolean;
begin
  if (p = nil) or (p^.xw[22] = 0) then begin
    if (language = 1) and ((e^.callee^.xw[197 + k] & 16#FFFF) >= 7) then
      pass_method := 1
    else
      pass_method := 0;
    return;
  end;
  if (language = 1) and (p <> nil) then
    if p^.xw[22] = 2 then
      if (e^.callee^.xw[197 + k] & 16#FFFF) < 7 then
        if ord(p^.xc[46]) < 128 then begin
          pass_method := 0;
          return;
        end;
  if language = 2 then begin
    r := 3;
    get_size_rlen(a, d1);
    get_size_rlen(f, d2);
    if d1.rlen = rlen_null then begin
      pass_method := r;
      return;
    end;
    done := false;
    if a^.kind = tree_node then
      if (a^.tr_op = compare_top) or (a^.tr_op = set_compare_top)
          or (a^.tr_op = f_compare_top) or
         (a^.tr_op = agg_compare_top) then
        done := true;
    if not done then
      if d1.rlen <> d2.rlen then begin
        pass_method := r;
        return;
      end;
  end;
  if (language = 1) and (p <> nil) then
    if ord(p^.xc[46]) >= 128 then begin
      pass_method := 3;
      return;
    end;
  if a^.kind in [blogical_ob..linteger_ob, char_ob..complex_ob, tree_node,
                 cmp_tree_node, dpcomplex_ob, binteger_ob] then
    r := 0
  else if a^.kind in [usinteger_ob..ubinteger_ob, char_string_ob,
                      char32_string_ob, char16_ob, set_con_ob,
                      rec_const_ob] then
    r := 3
  else begin
    x := actual_actual(a, ind);
    if x^.kind in [var_name, fortran_symbol, common_block_name, addr_con,
                   reloc_absolute_addr_con] then
      r := 2
    else
      r := 3;
  end;
  pass_method := r;
end;

{ put_on_bct - variable v (109, or a temporary 110) added to the end
  of block b's variables (+16 first, +20 last; through a 109's +16, a
  110's +4), owned by e's caller (a 109's +20, a 110's +40 unless of
  class 1 by +44), whose count of variables (+290) is raised.

  0x0901BC, 0x82 bytes, link #-12. }

procedure put_on_bct(
    e: oi_edge_ptr_t;
    b: il_$node_ptr_t;
    v: il_$node_ptr_t); options(val_param); internal;
begin
  if v^.kind = fortran_symbol then begin
    v^.xp[1] := nil;
    if rshft(ord(v^.xc[44]) & 16#F0, 4) <> 1 then
      v^.xp[10] := e^.caller;
  end
  else begin
    v^.xp[4] := nil;
    v^.xp[5] := e^.caller;
  end;
  if b^.xp[5] = nil then
    b^.xp[4] := v
  else if b^.xp[5]^.kind = fortran_symbol then
    b^.xp[5]^.xp[1] := v
  else
    b^.xp[5]^.xp[4] := v;
  b^.xp[5] := v;
  e^.caller^.xw[145] := e^.caller^.xw[145] + 1;
end;

{ copy_const - a copy of constant c (40 bytes from gspace).

  0x09023E, 0x36 bytes: b not read (process_variables passes the
  caller's block); lib_$data_move from c's frame slot
  to a local holding the copy's address, the length a longword after
  the routine. }

function copy_const(
    b: il_$node_ptr_t;
    c: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  n: il_$node_ptr_t;
begin
  n := gspace(40);
  lib_$data_move(c, n, 40);
  copy_const := n;
end;

{ copy_var - a copy of variable v (109, 110) for the caller: in a
  language 2 callee 72 bytes and its +70 (rounded to longwords plus 4
  under -MAP), else 84 (92 for a language 1 variable of storage class
  10, +72); a parameter (121) stands for its +48 when it has one, and
  is made a variable (109: its fields moved to a variable's places,
  storage class 1 in the main program's block (105), else 2).  A
  variable's type that is a parameter becomes the parameter's (+16).

  0x090278, 0x140 bytes, link #-20: the length passed in a local
  longword, v stored back to its frame slot for lib_$data_move. }

function copy_var(
    e: oi_edge_ptr_t;
    v: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  size: integer;
  n: il_$node_ptr_t;
  len: integer32;
begin
  if language = 2 then begin
    if cargs_$options.map then
      size := lshft(rshft((v^.xw[35] & 16#FFFF) + 9, 2), 2) + 72
    else
      size := 72 + v^.xw[35];
  end
  else begin
    size := 84;
    if v^.kind = param_name then
      if v^.xp[12] <> nil then
        v := v^.xp[12];
    if language = 1 then
      if v^.kind = var_name then
        if v^.vr_vat = sect_vat then
          size := 92;
  end;
  n := gspace(size);
  if (v^.kind = fortran_symbol) or (v^.kind = var_name) then begin
    len := size;
    lib_$data_move(v, n, len);
  end
  else if v^.kind = param_name then begin
    n^.kind := var_name;
    n^.xp[7] := v^.xp[4];
    n^.xp[8] := v^.xp[5];
    n^.xp[1] := v^.xp[2];
    n^.xp[2] := v^.xp[3];
    n^.xp[9] := v^.xp[7];
    n^.xp[10] := v^.xp[6];
    n^.xw[23] := v^.xw[16];
    n^.xw[22] := v^.xw[17];
    n^.xw[24] := v^.xw[18];
    if e^.caller^.kind = program_blk then
      n^.vr_vat := static_vat
    else
      n^.vr_vat := dynm_vat;
  end;
  if n^.kind = var_name then
    if n^.xp[7] <> nil then
      if n^.xp[7]^.kind = param_name then
        n^.xp[7] := n^.xp[7]^.xp[4];
  copy_var := n;
end;

{ align - x aligned to 2**n bytes: up, or down when down is set.

  0x0903B8, 0x3A bytes: x by address, n and down words. }

procedure align(
    var x: integer32;
    n: integer;
    down: integer); options(val_param); internal;
var
  m: integer32;
begin
  m := lshft(-1, n) & x;
  if m <> x then
    if down = 0 then
      x := m + lshft(1, n)
    else
      x := m;
end;

{ allocate_space - size bytes for a variable of e's caller, aligned
  to 2**n: static ones from the data section's record (the caller's
  +192: +20 the offset, class 1; past 24K and too large for what is
  left, unless -CPU M020, its +24, class 7, reported as unexpected),
  others from the frame (the caller's +112, downward, class 2; past
  -24K likewise its +176, class 6, reported).

  0x0903F2, 0x16A bytes, link #-4: n a word at (16,A6), static a byte
  at (18,A6), class and offset by address; the limits' quarters by
  `lsr.l #2'. }

procedure allocate_space(
    e: oi_edge_ptr_t;
    size: integer32;
    n: integer;
    static: boolean;
    out class: integer;
    out offset: integer32); options(val_param); internal;
var
  d: il_$node_ptr_t;
  b: il_$node_ptr_t;
  t: integer32;
begin
  if static then begin
    d := e^.caller^.xp[48];
    if (size + d^.xl[5] > 24576) and
       (rshft(32768 - d^.xl[5], 2) < size) and
       not (3 in cargs_$options.cpu) then begin
      align(d^.xl[6], n, 0);
      offset := e^.caller^.xp[48]^.xl[6];
      e^.caller^.xp[48]^.xl[6] := e^.caller^.xp[48]^.xl[6] + size;
      class := 7;
      cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end
    else begin
      align(d^.xl[5], n, 0);
      offset := e^.caller^.xp[48]^.xl[5];
      e^.caller^.xp[48]^.xl[5] := e^.caller^.xp[48]^.xl[5] + size;
      class := 1;
    end;
  end
  else begin
    b := e^.caller;
    t := b^.xl[28] - size;
    if (t < -24576) and (rshft(b^.xl[28] + 31000, 2) < size) and
       not (3 in cargs_$options.cpu) then begin
      align(b^.xl[44], n, 0);
      offset := e^.caller^.xl[44];
      e^.caller^.xl[44] := e^.caller^.xl[44] + size;
      class := 6;
      cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end
    else begin
      b^.xl[28] := t;
      align(e^.caller^.xl[28], n, 1);
      offset := e^.caller^.xl[28];
      class := 2;
    end;
  end;
end;

{ allocate_local_var - variable v given storage in e's caller: its
  alignment by its class (get_size_rlen: 1, 2, 4 or 8 bytes; another
  class reported), static in the main program's block (105) unless
  +26 (language 2) or +34 bit 14; a language 2 variable takes the
  largest of its equivalence ring (+28; sz_fsym) from the ring's
  lowest offset (+12), and each member its class (+11 bits 7..4) and
  offset moved, +25 bit 2 and +44 bit 0 set (and v's +44 class 3);
  another its class (+72) and offset (+56), +33 bit 2.  The size is
  made even.

  0x09055C, 0x1E6 bytes, link #-40: the alignment by a jump table of
  13; the message's length 66 though the text is shorter. }

procedure allocate_local_var(
    e: oi_edge_ptr_t;
    v: il_$node_ptr_t); options(val_param); internal;
var
  d: add_node_$desc_t;
  static: boolean;
  n: integer;
  class: integer;
  offset: integer32;
  size: integer32;
  low: integer32;
  s: integer32;
  w: il_$node_ptr_t;
begin
  static := false;
  get_size_rlen(v, d);
  case d.rlen of
    rlen_null, rlen_byte:
      n := 0;
    rlen_word:
      n := 1;
    rlen_long, rlen_addr, rlen_r4:
      n := 2;
    rlen_r8, rlen_c8:
      n := 3;
    rlen_cs, rlen_vcs:
      n := 2;
    rlen_agg, rlen_c16:
      n := 3;
    otherwise
      cgerr_no_source(28, integer32(strtk(
        'Bad rlen encountered in \\opt_inline\allocate_local_var', 66)));
  end;
  if language = 2 then begin
    if e^.caller^.kind = program_blk then
      if (v^.xw[13] & 16#4000) = 0 then
        static := true;
    size := sz_fsym(v);
    low := v^.xl[3];
    w := v^.xp[7];
    if w <> nil then
      while w <> v do begin
        s := sz_fsym(w);
        if size < s then
          size := s;
        if low > w^.xl[3] then
          low := w^.xl[3];
        w := w^.xp[7];
      end;
  end
  else begin
    if e^.caller^.kind = program_blk then
      if (v^.xw[17] & 16#4000) = 0 then
        static := true;
    size := d.size;
  end;
  if odd(size) then
    size := size + 1;
  allocate_space(e, size, n, static, class, offset);
  if language = 2 then begin
    v^.xc[11] := chr((ord(v^.xc[11]) & 15) ! (lshft(class, 4) & 16#F0));
    v^.xl[3] := v^.xl[3] - low + offset;
    v^.xc[25] := chr(ord(v^.xc[25]) ! 4);
    v^.xc[44] := chr(ord(v^.xc[44]) ! 1);
    v^.xc[44] := chr((ord(v^.xc[44]) & 15) ! 16#30);
    w := v^.xp[7];
    if w <> nil then
      while w <> v do begin
        w^.xc[11] := chr((ord(w^.xc[11]) & 15) ! (lshft(class, 4) & 16#F0));
        w^.xl[3] := w^.xl[3] - low + offset;
        w^.xc[25] := chr(ord(w^.xc[25]) ! 4);
        w^.xc[44] := chr(ord(w^.xc[44]) ! 1);
        w := w^.xp[7];
      end;
  end
  else begin
    v^.vr_vat := il_$vat_t(class);
    v^.xl[14] := offset;
    v^.xc[33] := chr(ord(v^.xc[33]) ! 4);
  end;
end;

{ set_address_exposed - the variable whose address t takes (an
  operator 137 of op 26, else reported) marked address exposed: a
  110's +26 bit 4, a 109's +34 bit 4, directly or as the base (+28) of
  a reference (145, 146, 205, 147).

  0x09077A, 0x9E bytes, link #-8: the message a varying string
  constant after the routine (token_$make_string_token). }

procedure set_address_exposed(
    t: il_$node_ptr_t); options(val_param); internal;
var
  x: il_$node_ptr_t;
  y: il_$node_ptr_t;
begin
  if (t^.kind <> tree_node) or (t^.tr_op <> addr_top) then
    cgerr_no_source(28, integer32(token_$make_string_token(
      'set_address_exposed --- top is not addr_top.')));
  x := t^.xp[10];
  case x^.kind of
    fortran_symbol:
      x^.xc[26] := chr(ord(x^.xc[26]) ! 16);
    var_name:
      x^.xc[34] := chr(ord(x^.xc[34]) ! 16);
    dindex_node, ptr_node, sym_disp_node, disp_node: begin
      y := x^.xp[7];
      if y^.kind = fortran_symbol then
        y^.xc[26] := chr(ord(y^.xc[26]) ! 16)
      else if y^.kind = var_name then
        y^.xc[34] := chr(ord(y^.xc[34]) ! 16);
    end;
    otherwise
      ;
  end;
end;

{ inliner_actual - actual t, without the conversion (137 op 63) the
  front end wraps around it.

  0x090848, 0x1A bytes, no frame. }

function inliner_actual(
    t: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r: il_$node_ptr_t;
begin
  r := t;
  if r^.kind = tree_node then
    if r^.tr_op = align_top then
      r := r^.xp[10];
  inliner_actual := r;
end;

{ process_parameters - the callee's parameters bound for edge e (x the
  callee's display, its +4 the result variable): for each parameter
  (the callee's +293 of them; a language 2 callee's from the table at
  its +12, 12 bytes each, others the variables named by its parameter
  list, +12 through +4) the actual's binding by pass_method: 0 a copy
  of the parameter assigned the actual, 3 a pointer variable
  (ptr_variable) assigned its address (and, in language 2, a copy of
  the parameter based on it), 2 the actual's own variable (copied in
  its place: storage and flags), 1 the actual itself; the parameter
  then maps (put_hash_info) to what stands for it, with flags 1
  (substituted, or by address) or 2 (a by-reference parameter, mode
  0, passed through its address), 4 for a pointer of class 5, the
  address taken or the reference made as the binding needs, the
  actual's captured indirection in the display (+20).  The result
  variable is copied, allocated and mapped likewise.

  0x090BBA, 0x6F0 bytes, link #-384: the parameters counted down in
  a frame word and `bcc'; pass_method's answers by a jump table of 4;
  add_pn's two words pushed as one longword (#0x20000, pattern 54);
  the copies' +10 flags cleared `andi.w #-16387'. }

procedure process_parameters(
    e: oi_edge_ptr_t;
    var x: oi_call_t); options(val_param); internal;

  { assign - a new assignment (140) of rhs to lhs, its descriptor
    lhs's (get_size_rlen), rhs converted (coerce) to it from the k-th
    parameter's class of a routine type in languages 3 and 4 (the
    called routine's +18 + 4k) or from a tree's class; +76 the
    assignment's kind (11 a real, 6 a block, else 0); e's caller's
    count (+272) raised.

    0x090862, 0x106 bytes, link #-44: k a word; the result in A0. }

  function assign(
      e: oi_edge_ptr_t;
      lhs: il_$node_ptr_t;
      rhs: il_$node_ptr_t;
      k: integer): il_$node_ptr_t; options(val_param);
  var
    s: il_$node_ptr_t;
    d: add_node_$desc_t;
    w: integer;
    done: boolean;
  begin
    e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
    s := gspace(80);
    s^.kind := assign_node;
    s^.xp[17] := rhs;
    s^.xp[16] := lhs;
    get_size_rlen(lhs, d);
    s^.xl[12] := d.size;
    s^.xw[26] := d.rlen;
    if k > 0 then begin
      done := false;
      if language in [3, 4] then begin
        w := e^.call^.xp[10]^.xw[9 + 2 * k];
        if w <> d.rlen then begin
          coerce(e, s^.xp[17], w, d.rlen, true);
          done := true;
        end;
      end;
      if not done then
        if (rhs^.kind = cmp_tree_node) or (rhs^.kind = tree_node) then
          if rhs^.tr_rlen <> d.rlen then
            coerce(e, s^.xp[17], rhs^.tr_rlen, d.rlen,
                   (ord(rhs^.xc[30]) & 64) <> 0);
    end;
    if (s^.xw[26] = 6) or (s^.xw[26] = 7) or (s^.xw[26] = 12) or
       (s^.xw[26] = 8) then
      s^.asg_op := fp_aop
    else if s^.xw[26] = 11 then
      s^.asg_op := agg_aop
    else
      s^.asg_op := scalar_aop;
    assign := s;
  end;

  { ptr_variable - a new pointer variable for parameter f: in a
    language 2 callee a temporary (110, 92 bytes under -MAP else 83;
    +10 bit 5 and class 3, +44 class 3 and bit 0, +68 -1, +26 bit 6),
    else a variable (109) of a new pointer type (130, 4 bytes, its
    name a type name 118 of f's attributes), named after f
    (assign_name), allocated and put on e's block (+12).

    0x090A10, 0x1AA bytes, link #-32: the gspace size in a frame word;
    the pointer type's +20, +22 stored as one longword 0x20002. }

  function ptr_variable(
      e: oi_edge_ptr_t;
      f: il_$node_ptr_t): il_$node_ptr_t; options(val_param);

    { assign_name - dst (its length dlen) the name '<OI$nnnnn$' with
      the names' serial in its digits, then len characters of src,
      then '>'; the serial raised.

      0x090968, 0x98 bytes, link #-24: src and dst by value, dlen by
      address; the pattern copied from after the routine; the
      serial's low word (+0x5EF6) taken; the digits by `divs.w #10'. }

    procedure assign_name(
        src: univ_ptr;
        len: integer;
        dst: oi_chars_ptr_t;
        var dlen: integer); options(val_param);
    var
      i: integer;
      n: integer;
      pat: oi_pattern_t;
    begin
      pat := '<OI$00000$>';
      lib_$data_move(addr(pat), dst, 11);
      i := 9;
      n := name_serial;
      repeat
        dst^[i] := chr(n mod 10 + 48);
        i := i - 1;
        n := n div 10;
      until n = 0;
      lib_$data_move(src, addr(dst^[11]), len);
      len := len + 11;
      dlen := len;
      dst^[len] := '>';
      name_serial := name_serial + 1;
    end;

  var
    v: il_$node_ptr_t;
    n: il_$node_ptr_t;
    t: il_$node_ptr_t;
    size: integer;
  begin
    if language = 2 then begin
      if cargs_$options.map then
        size := 92
      else
        size := 83;
      v := gspace(size);
      v^.kind := fortran_symbol;
      v^.xc[10] := chr(ord(v^.xc[10]) ! 32);
      v^.xc[10] := chr((ord(v^.xc[10]) & 16#F0) ! 3);
      v^.xc[44] := chr((ord(v^.xc[44]) & 15) ! 16#30);
      v^.xc[44] := chr(ord(v^.xc[44]) ! 1);
      v^.xw[34] := -1;
      assign_name(addr(f^.xc[72]), f^.xw[35],
                  oi_chars_ptr_t(addr(v^.xc[72])), v^.xw[35]);
      allocate_local_var(e, v);
      v^.xc[26] := chr(ord(v^.xc[26]) ! 64);
      put_on_bct(e, e^.scope, v);
    end
    else begin
      v := gspace(84);
      v^.kind := var_name;
      v^.xp[1] := gspace(29);
      v^.xp[1]^.kind := id_ob;
      n := v^.xp[1];
      assign_name(addr(f^.xp[1]^.xc[18]), f^.xp[1]^.xw[8],
                  oi_chars_ptr_t(addr(n^.xc[18])), n^.xw[8]);
      t := gspace(36);
      v^.xp[7] := t;
      v^.xl[9] := 32;
      t^.kind := ptr_type;
      t^.xl[3] := 32;
      t^.xw[10] := 2;
      t^.xw[11] := 2;
      t^.xw[12] := -1;
      t^.xp[1] := gspace(60);
      n := t^.xp[1];
      n^.kind := type_name;
      n^.xp[1] := v^.xp[1];
      n^.xp[5] := e^.caller;
      n^.xp[7] := f^.xp[7]^.xp[4];
      n^.xl[11] := f^.xl[9];
      n^.xw[25] := f^.xw[22];
      n^.xw[24] := f^.xw[23];
      n^.xw[26] := f^.xw[24];
      n^.xl[10] := f^.xl[10];
      allocate_local_var(e, v);
      put_on_bct(e, e^.scope, v);
    end;
    ptr_variable := v;
  end;

var
  d: oi_desc_t;
  d3: add_node_$desc_t;
  p: il_$node_ptr_t;
  f: il_$node_ptr_t;
  a: il_$node_ptr_t;
  v: il_$node_ptr_t;
  pv: il_$node_ptr_t;
  c: il_$node_ptr_t;
  adr: il_$node_ptr_t;
  val: il_$node_ptr_t;
  ind: il_$node_ptr_t;
  ops1: il_$node_ptr_t;
  ops2: il_$node_ptr_t;
  ops3: il_$node_ptr_t;
  info: oi_info_t;
  i: integer;
  k: integer;
  m: integer;
  sub: integer;
  cls: integer;
  fl: oi_flags_t;
begin
  for i := 1 to 16 do
    d.b[i] := chr(0);
  p := nil;
  if language <> 2 then
    p := e^.callee^.xp[3];
  for k := 1 to ord(e^.callee^.xc[293]) do begin
    if language = 2 then
      f := oi_ftab_ptr_t(e^.callee^.xp[3])^[k].sym
    else
      f := find_varn(e^.callee, p);
    a := inliner_actual(e^.call^.xp[10 + k]);
    sub := 0;
    ind := nil;
    m := pass_method(e, k, a, f, p);
    case m of
      0: begin
        if language = 2 then begin
          v := copy_var(e, f);
          put_on_bct(e, caller_blk, v);
          v^.xw[5] := v^.xw[5] & 16#BFFD;
          v^.xc[44] := chr((ord(v^.xc[44]) & 15) ! 16#30);
        end
        else begin
          v := copy_var(e, f);
          put_on_bct(e, caller_blk, v);
          v^.xc[34] := chr(ord(v^.xc[34]) & 16#FB);
        end;
        allocate_local_var(e, v);
        val := v;
        put_on_il_stream(assign(e, v, a, k));
        if a^.kind = tree_node then
          if a^.tr_op = addr_top then
            set_address_exposed(a);
      end;
      3: begin
        if language = 2 then begin
          if (a^.kind = ptr_node) and (a^.xp[6]^.kind = fortran_symbol) then
            adr := a^.xp[6]
          else begin
            d.d.size := 4;
            d.d.rlen := rlen_long;
            ops1 := a;
            adr := buildtreenode(addr_top, d.d, ops1, 1);
          end;
          pv := ptr_variable(e, f);
          pv^.xp[8] := f^.xp[8];
          put_on_il_stream(assign(e, pv, adr, 0));
          c := copy_var(e, f);
          put_on_bct(e, caller_blk, c);
          c^.xw[5] := c^.xw[5] & 16#BFFD;
          if rshft(ord(c^.xc[44]) & 16#F0, 4) = 0 then
            c^.xc[44] := chr((ord(c^.xc[44]) & 15) ! 16#30);
          c^.xc[11] := chr((ord(c^.xc[11]) & 15) ! 16#90);
          c^.xp2[14] := pv;
        end
        else begin
          if (a^.kind = ptr_node) and (a^.xp[6]^.kind = var_name) then
            adr := a^.xp[6]
          else if (a^.kind = reloc_absolute_addr_con)
              or (a^.kind = addr_con) then
            adr := a
          else begin
            if (language = 1) and (a^.kind = integer_ob) then begin
              get_size_rlen(f, d3);
              if d3.rlen = rlen_byte then
                a := smcontk(binteger_ob, a^.xl[2])
              else if d3.rlen = rlen_word then
                a := smcontk(sinteger_ob, a^.xl[2]);
            end;
            ops2 := a;
            d.d.size := 4;
            d.d.rlen := rlen_addr;
            adr := buildtreenode(addr_top, d.d, ops2, 1);
          end;
          pv := ptr_variable(e, f);
          put_on_il_stream(assign(e, pv, adr, 0));
          c := pv;
        end;
        if adr^.kind = tree_node then
          if adr^.tr_op = addr_top then
            set_address_exposed(adr);
        sub := 1;
        val := pv;
        ind := alias_$ind_for_captured_lvalue(a);
      end;
      2: begin
        val := a;
        if language = 2 then begin
          a := actual_actual(a, ind);
          if a^.kind = fortran_symbol then begin
            v := copy_var(e, f);
            put_on_bct(e, caller_blk, v);
            v^.xc[11] := chr((ord(v^.xc[11]) & 16#FD) ! (ord(a^.xc[11]) & 2));
            v^.xc[10] := chr((ord(v^.xc[10]) & 16#BF) ! (ord(a^.xc[10]) & 64));
            v^.xc[11] := chr((ord(v^.xc[11]) & 15) ! (ord(a^.xc[11]) & 16#F0));
            v^.xl[3] := a^.xl[3];
            if (ord(v^.xc[11]) & 2) = 0 then
              v^.xc[44] := chr((ord(v^.xc[44]) & 15) ! 16#30);
            v^.xl[6] := (f^.xl[6] & 16#803FFFFF) ! a^.xl[6];
            v^.xl[8] := a^.xl[8];
          end;
        end
        else begin
          a := actual_actual(a, ind);
          if (a^.kind = reloc_absolute_addr_con) or (a^.kind = addr_con) then
            a := find_varn(e^.scope, a);
          if a^.kind = var_name then begin
            v := copy_var(e, f);
            put_on_bct(e, caller_blk, v);
            v^.vr_vat := a^.vr_vat;
            if v^.vr_vat = sect_vat then
              v^.vr_vat := dynm_vat;
            v^.xl[14] := a^.xl[14];
            v^.xl[8] := (f^.xl[8] & 16#803FFFFF) ! a^.xl[8];
          end;
        end;
      end;
      1:
        val := a;
      otherwise
        ;
    end;
    if f^.kind = fortran_symbol then
      cls := rshft(ord(f^.xc[11]) & 16#F0, 4)
    else
      cls := ord(f^.vr_vat);
    if (p <> nil) and (p^.xw[22] = 0) then begin
      if m = 1 then
        fl := [1]
      else
        fl := [0];
    end
    else if cls = 5 then
      fl := [2]
    else
      fl := [0];
    if (fl * [1, 2]) <> [] then
      sub := sub - 1;
    if sub = -1 then begin
      if val^.kind = ptr_node then
        val := val^.xp[6]
      else begin
        d.d.size := 4;
        if language = 2 then
          d.d.rlen := rlen_long
        else
          d.d.rlen := rlen_addr;
        val := buildtreenode(addr_top, d.d, val, 1);
      end;
    end
    else if sub = 1 then begin
      if (val^.kind = tree_node) and (val^.tr_op = addr_top) then
        val := val^.xp[10]
      else begin
        val := add_pn(val, c, 2, 0);
        val^.xw[8] := 1;
      end;
    end;
    nil_out_dispinfo(info);
    info.ind := ind;
    put_hash_info(e, f, val, fl, info);
    if language <> 2 then
      p := p^.xp[1];
  end;
  f := x.result;
  if f <> nil then begin
    v := copy_var(e, f);
    put_on_bct(e, e^.scope, v);
    if v^.kind = fortran_symbol then
      v^.xc[44] := chr((ord(v^.xc[44]) & 15) ! 16#30);
    allocate_local_var(e, v);
    if f^.kind = fortran_symbol then
      cls := rshft(ord(f^.xc[11]) & 16#F0, 4)
    else
      cls := ord(f^.vr_vat);
    if cls = 5 then
      fl := [2]
    else
      fl := [0];
    if fl = [2] then begin
      d.d.size := 4;
      if language = 2 then
        d.d.rlen := rlen_long
      else
        d.d.rlen := rlen_addr;
      ops3 := v;
      v := buildtreenode(addr_top, d.d, ops3, 1);
    end;
    put_hash_info(e, f, v, fl, empty_info);
  end;
end;

{ process_display_ptrs - the callee's display pointers (its +240,
  variables through +12, each naming a block by +4) mapped to the
  caller's: a Fortran statement function's single one to the caller's
  (reported when the caller has none); in a language 1 callee each
  pointer of a block other than the caller's to the caller's pointer
  of the same block, found in the caller's list (ordered by the
  blocks' levels, deepest first) or copied into it there (the
  caller's count +292 raised).

  0x0912AA, 0x194 bytes, link #-28: the levels signed bytes (+294). }

procedure process_display_ptrs(
    e: oi_edge_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  b: il_$node_ptr_t;
  d: il_$node_ptr_t;
  q: il_$node_ptr_t;
  prev: il_$node_ptr_t;
  blk: il_$node_ptr_t;
  v: il_$node_ptr_t;
  more: boolean;
begin
  if inline_$is_fortran_asf(e^.caller) then begin
    a := e^.callee^.xp[60];
    if a <> nil then begin
      b := e^.caller^.xp[60];
      if b <> nil then
        put_hash_info(e, a, b, [], empty_info)
      else
        cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end;
  end
  else if language = 1 then begin
    d := e^.callee^.xp[60];
    if d <> nil then begin
      prev := nil;
      q := e^.caller^.xp[60];
      while d <> nil do begin
        blk := find_block(e^.callee, d^.xp[1]);
        if blk^.xp[74] <> e^.caller^.xp[74] then begin
          more := true;
          while more do
            if q = nil then
              more := false
            else if q^.xp[1] = d^.xp[1] then
              more := false
            else if oi_level_ptr_t(find_block(e^.caller, q^.xp[1]))^.level <
                    oi_level_ptr_t(blk)^.level then
              more := false
            else begin
              prev := q;
              q := q^.xp[3];
            end;
          if (q <> nil) and (q^.xp[1] = d^.xp[1]) then
            put_hash_info(e, d, q, [], empty_info)
          else begin
            v := copy_var(e, d);
            put_on_bct(e, e^.caller, v);
            e^.caller^.xc[292] := chr(ord(e^.caller^.xc[292]) + 1);
            if prev <> nil then begin
              v^.xp[3] := prev^.xp[3];
              prev^.xp[3] := v;
            end
            else begin
              v^.xp[3] := e^.caller^.xp[60];
              e^.caller^.xp[60] := v;
            end;
            prev := v^.xp[3];
            put_hash_info(e, d, v, [], empty_info);
          end;
        end;
        d := d^.xp[3];
      end;
    end;
  end;
end;

{ process_variables - the variables of the callee and of the blocks it
  contains (next_contained_block), each block's copies put on the
  caller's block its own maps to (from caller_blk), mapped
  (put_hash_info) to copies: a language 2 callee's temporaries (110)
  of class 6 by +44 whose base (+48) has a copy (their copies based on
  it), and those of class 1, 2, 6 or 7 by +11 that are not +24 bit 23,
  with their equivalence rings (+28) copied (class 2 and 6 allocated);
  another callee's constants (116, copy_const) and variables (109) of
  class 1, 2, 6 or 7 by +72, not +32 bit 23 (class 2 and 6 allocated),
  with flag 3.  A variable already mapped with flag 3 ends the block's
  walk: the caller's block's list is joined to its copy and its last
  variable mapped to the block's (+20).  In language 2 the mapped
  variables without flags then get flag 3.

  0x09143E, 0x35C bytes, link #-80: the class sets by `btst' of 198
  and 68; the copies' value kept in D6 across get_hash_info (stored
  to the frame before each call); put_on_bct after copy_const pops 10
  (pattern 51). }

procedure process_variables(
    e: oi_edge_ptr_t); options(val_param); internal;
var
  b: il_$node_ptr_t;
  cb: il_$node_ptr_t;
  v: il_$node_ptr_t;
  nv: il_$node_ptr_t;
  x: il_$node_ptr_t;
  w: il_$node_ptr_t;
  c: il_$node_ptr_t;
  first: il_$node_ptr_t;
  last: il_$node_ptr_t;
  fl: oi_flags_t;
  info: oi_info_t;
  k: integer;
  joined: boolean;
begin
  b := e^.callee;
  cb := caller_blk;
  repeat
    v := b^.xp[4];
    joined := false;
    while (v <> nil) and not joined do begin
      get_hash_info(e, v, nv, fl, info);
      if 3 in fl then begin
        if cb^.xp[5] = nil then
          cb^.xp[4] := nv
        else if language = 2 then
          cb^.xp[5]^.xp[1] := nv
        else
          cb^.xp[5]^.xp[4] := nv;
        get_hash_info(e, cb^.xp[5], b^.xp[5], fl, info);
        joined := true;
      end
      else if language = 2 then begin
        if nv = nil then
          if (v^.kind = fortran_symbol) and (rshft(ord(v^.xc[44]) & 16#F0,
              4) = 6) then begin
            get_hash_info(e, v^.xp[12], x, fl, info);
            if x <> nil then begin
              nv := copy_var(e, v);
              put_on_bct(e, cb, nv);
              nv^.xp[12] := x;
              put_hash_info(e, v, nv, [], empty_info);
            end;
          end
          else if v^.kind = fortran_symbol then begin
            k := rshft(ord(v^.xc[11]) & 16#F0, 4);
            if k in [1, 2, 6, 7] then
              if not (var_$display_ptr in v^.fs_attr) then begin
                nv := copy_var(e, v);
                put_on_bct(e, cb, nv);
                if v^.xp[7] <> nil then begin
                  first := nv;
                  last := nv;
                  w := nv^.xp[7];
                  while w <> v do begin
                    c := copy_var(e, w);
                    put_on_bct(e, cb, c);
                    last^.xp[7] := c;
                    last := c;
                    w := w^.xp[7];
                  end;
                  last^.xp[7] := first;
                end;
                k := rshft(ord(v^.xc[11]) & 16#F0, 4);
                if k in [2, 6] then
                  allocate_local_var(e, nv);
                put_hash_info(e, v, nv, [], empty_info);
                if v^.xp[7] <> nil then begin
                  w := v^.xp[7];
                  c := nv^.xp[7];
                  while w <> v do begin
                    put_hash_info(e, w, c, [], empty_info);
                    w := w^.xp[7];
                    c := c^.xp[7];
                  end;
                end;
              end;
          end;
        v := v^.xp[1];
      end
      else begin
        if v^.kind = const_name then begin
          nv := copy_const(cb, v);
          put_on_bct(e, cb, nv);
          put_hash_info(e, v, nv, [3], empty_info);
        end
        else if (nv = nil) and (v^.kind = var_name) then
          if v^.vr_vat in [static_vat, dynm_vat, xdynm_vat, xstatic_vat] then
            if not (var_$display_ptr in v^.vr_attr) then begin
              nv := copy_var(e, v);
              put_on_bct(e, cb, nv);
              if v^.vr_vat in [dynm_vat, xdynm_vat] then
                allocate_local_var(e, nv);
              put_hash_info(e, v, nv, [3], empty_info);
            end;
        v := v^.xp[4];
      end;
    end;
    if language = 2 then begin
      w := b^.xp[4];
      while w <> nil do begin
        get_hash_info(e, w, nv, fl, info);
        if 3 in fl then
          w := nil
        else begin
          if (nv <> nil) and (fl = []) then
            put_hash_info(e, w, nv, [3], empty_info);
          w := w^.xp[1];
        end;
      end;
    end;
    b := next_contained_block(e^.callee, b);
    get_hash_info(e, b, cb, fl, info);
  until cb = nil;
end;

{ process_labels - the callee's labels (144) copied (84 bytes,
  lib_$data_move; e's caller's count +272 raised) and mapped, from
  the callee's first statement (+100) to its end (149 of the callee,
  +48).

  0x09179A, 0x84 bytes, link #-16: the length a longword after the
  routine. }

procedure process_labels(
    e: oi_edge_ptr_t); options(val_param); internal;
var
  s: il_$node_ptr_t;
  n: il_$node_ptr_t;
begin
  s := e^.callee^.xp[25];
  repeat
    if s^.kind = label_node then begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(84);
      lib_$data_move(s, n, 84);
      put_hash_info(e, s, n, [], empty_info);
    end;
    s := s^.xp[2];
  until (s^.kind = blk_end_node) and (s^.xp[12] = e^.callee);
end;

{ process_operand - statement or tree t of the callee, for edge e,
  copied into the caller (the copy left in t; nil for a statement that
  is dropped), its nodes mapped through the hash table; x is the call
  being expanded (x.blk the block the statement is in, followed at
  each 148 and 149), ctx the reference being rebuilt (by value: each
  operand gets the context of its tree), r the displacement still to
  be applied to the reference it names (r.node).

  Nothing for nil, nor for a routine block (108, 107) while a call's
  routine operand is copied (ctx.call).  Unless a substitution has
  been made, the use count is taken from the reference or tree (+16).
  A node the table maps (get_hash_info) becomes its value, with the
  displacement of its display record applied (apply_disp) when the
  record is the node's own; unless the value is a substitute (flags
  0..2) that is all.  Then by kind:
    148, 149  a block's begin and end: copied (52 bytes), its block
              (+48) mapped; x.blk entered (a 172's +76 keeping the
              block left, else cleared) or left (to that, else to
              the enclosing block, +8);
    140       an assignment: dropped when it assigns a parameter
              temporary (110 with +24 bit 23), or, but in a Fortran
              statement function, assigns the result of a 155 (its
              target mapped to il_node_153); else copied (80 bytes)
              with its three operands (+64, +68, +72);
    144       a label: the label's copy;
    139       an evaluation: copied (52 bytes and 4 an operand, but 92
              allocated for none) with its operands, last first;
    141, 142  copied (56, 64 bytes; 142 with its operand +56), the
              label (+48) mapped when the table has it;
    150       copied (52 bytes) with its operand (+48);
    151       dropped;
    137, 143  a tree: copied (40 bytes and 4 an operand), the use
              count put back when substituted; a call (op 15, 16) its
              routine operand under ctx.call, the other operands, and
              its reference parameters marked
              (inline_$mark_reference_params); an indexing (op 13) its
              array operand rebased (get_sym_ind_info,
              process_index_opr) and the indices; else each operand;
    145       an indexed reference (44 bytes): its index (+36) and its
              base (process_opr_ind), ctx.base set to it;
    146       a pointer reference (32 bytes): its base, `*&v' made v;
    147       a displacement (36 bytes): a chain of displacements merged
              into the callee's node first, ctx.dnode the copy, the
              displacement left in r applied after;
    205       a symbolic displacement (36 bytes): ctx.sdn the copy, its
              variable (+32) processed (a 146's base or a 137 op 26's
              operand taken), the node replaced by its base when the
              variable goes;
    175       copied (24 bytes) with its operands (+16, +20);
    171       copied (20 bytes and 4 for each of the call's operands
              but one) with its operand (+16);
    164       copied (32 bytes) with its operands (+20, +24);
    165       a temporary (28 bytes): given storage in the caller's
              frame (allocate_space, by its size +22, aligned to 2)
              and the caller its block (+8);
  other kinds are left as they are.  The trees and references are
  mapped to their copies (put_hash_info, flags none) or have r applied
  (when r is theirs); an entry of flag 4 is entered again for the copy
  without it.

  0x092228 (cc.a88k 0x093C08), 0xBD8 bytes, link #-108, loads A5:
  ctx (30 bytes) copied from its address (seven `move.l' and a
  `move.w'); the first `case' a compare chain whose arms are the same
  store (143 and 137 one arm); the kinds by a jump table of 69 from
  137 (the arms in the order 148, 149, 140, 144, 139, 141, 142, 150,
  151, 137/143, 146, 145, 147, 205, 175, 171, 164, 165); the copies'
  lengths longword constants after the routine, each passed with the
  callee's node and the new node's local by address (lib_$data_move);
  139's allocation a frame word, its length recomputed for the move
  (an expression passed to an in parameter: `ext.l' into a frame
  longword) and 137's computed once; the operand loops `dbf' with the
  index in another register; the flags of the first get_hash_info kept
  in D2 to the end (`btst #4', `andi.w #-17'); 147's process_opr_ind
  and 164's second process_operand pop 2 bytes short (pattern 51);
  140's `and not' of a call is docs/dpc-gaps.md 24.

  Not known from the original: the arms' order in the source (taken
  from the code's); the local names. }

procedure process_operand(
    e: oi_edge_ptr_t;
    var x: oi_call_t;
    var t: il_$node_ptr_t;
    ctx: oi_ctx_t;
    var r: oi_info_t); options(val_param);
var
  orig: il_$node_ptr_t;
  val: il_$node_ptr_t;
  flags: oi_flags_t;
  info: oi_info_t;
  val2: il_$node_ptr_t;
  flags2: oi_flags_t;
  n: il_$node_ptr_t;
  size: integer;
  i: integer;
  raw: oi_symind_t;
  sub: oi_symind_t;

  { get_sym_ind_info - the variable and symbol a reference is reached
    by (ctx.v, ctx.sym), as raw (an identifier, 76, looked up in x's
    block: find_varn, kept when not found) and as their substitutes
    for edge e (sub, substitutee_sym_ind; only when there is a
    variable).

    0x0918BA (cc.a88k 0x09329A), 0x74 bytes, link #-8: x, ctx, raw
    and sub by address; the symbol stored first; the test of the
    variable the `move.l' storing it. }

  procedure get_sym_ind_info(
      e: oi_edge_ptr_t;
      var x: oi_call_t;
      var ctx: oi_ctx_t;
      out raw: oi_symind_t;
      out sub: oi_symind_t); options(val_param);
  var
    v: il_$node_ptr_t;

    { substitutee_sym_ind - what n stands for in the copy for edge e:
      n itself when its entry has flag 1 or there is none, else its
      value, through an address (137 op 26: +40), a 195 (+12) and a
      displacement's or pointer reference's base (147, 146: +28);
      ctx.subst set when the entry has flags 0..2.

      0x091822 (cc.a88k 0x093202), 0x98 bytes, link #-48: ctx by
      address; flags 0..2 as `andi.w #7'; the result in A0. }

    function substitutee_sym_ind(
        e: oi_edge_ptr_t;
        n: il_$node_ptr_t;
        var ctx: oi_ctx_t): il_$node_ptr_t; options(val_param);
    var
      val: il_$node_ptr_t;
      flags: oi_flags_t;
      info: oi_info_t;
      s: il_$node_ptr_t;
    begin
      get_hash_info(e, n, val, flags, info);
      if (flags * [0, 1, 2]) <> [] then
        ctx.subst := true;
      if 1 in flags then
        s := n
      else begin
        s := n;
        if val <> nil then begin
          s := val;
          if (s^.kind = tree_node) and (s^.tr_op = addr_top) then
            s := s^.xp[10];
          if s^.kind = reloc_absolute_addr_con then
            s := s^.xp[3];
          if s^.kind = disp_node then
            s := s^.xp[7]
          else if s^.kind = ptr_node then
            s := s^.xp[7];
        end;
      end;
      substitutee_sym_ind := s;
    end;

  begin
    raw.sym := ctx.sym;
    raw.v := ctx.v;
    if raw.v <> nil then begin
      if raw.v^.kind = id_ob then begin
        v := find_varn(x.blk, raw.v);
        if v <> nil then
          raw.v := v;
      end;
      sub.sym := substitutee_sym_ind(e, raw.sym, ctx);
      sub.v := substitutee_sym_ind(e, raw.v, ctx);
    end;
  end;

  { adjust_disp - r made the displacement disp from symbol sym to be
    applied to the reference node.

    0x09192E (cc.a88k 0x09330E), 0x28 bytes, link #-4: r by address;
    the fields stored from the last. }

  procedure adjust_disp(
      disp: integer32;
      sym: il_$node_ptr_t;
      node: il_$node_ptr_t;
      var r: oi_info_t); options(val_param);
  begin
    r.disp_sym := sym;
    r.disp := disp;
    r.node := node;
  end;

  { disp_offset - the displacement of displacement node n (+32), 0
    for none.

    0x091956 (cc.a88k 0x093336), 0x14 bytes, no frame: n at (4,SP),
    the result in D0. }

  function disp_offset(
      n: il_$node_ptr_t): integer32; options(val_param);
  begin
    if n = nil then
      disp_offset := 0
    else
      disp_offset := n^.xl[8];
  end;

  { apply_disp - the displacement in info applied to t for edge e: a
    symbolic displacement node (add_sdn) over t, then the plain
    displacement put into ctx's displacement node when there is one,
    else a displacement node (add_dn) over t; the new nodes get ctx's
    use count and e's caller's count of nodes (+272) is raised for
    each.  When n is given it is mapped to t with info, and info is
    emptied.

    0x09196A (cc.a88k 0x09334A), 0xB4 bytes, link #-4: ctx, info and
    t by address. }

  procedure apply_disp(
      e: oi_edge_ptr_t;
      n: il_$node_ptr_t;
      var ctx: oi_ctx_t;
      var info: oi_info_t;
      var t: il_$node_ptr_t); options(val_param);
  begin
    if info.sdn_sym <> nil then begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      t := add_sdn(t, info.sdn_sym, info.sdn_var);
      t^.xw[8] := ctx.uses;
    end;
    if info.disp_sym <> nil then begin
      if ctx.dnode <> nil then
        ctx.dnode^.xl[8] := info.disp
      else begin
        e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
        t := add_dn(t, info.disp_sym, info.disp);
        t^.xw[8] := ctx.uses;
      end;
    end;
    if n <> nil then begin
      put_hash_info(e, n, t, [], info);
      nil_out_dispinfo(info);
    end;
  end;

  { process_index_opr - array operand t of an indexing for edge e,
    rebased when the array is reached by a variable a that stands for
    variable b in the copy (both variables, 109 or 110): when t is a
    153 or 211, a parameter temporary (110, +24 bit 23) of a callee
    nested deeper than the caller, a parameter variable (109, +32 bit
    23) named by the caller (+296), or the address (137 op 26) of a
    110 or 109, the displacement (of ctx.dnode, less a's offset when
    there is no symbolic displacement and t is not an address) plus
    b's offset goes into r for ctx.base and t becomes the base of b's
    storage: il_node_154 for classes 1 and 7 (ctx.sdn's variable
    dropped), il_node_153 for 2 and 6 (under -CPU 6 b's offset left
    out and, without ctx.sdn, b's variable and symbol made r's
    symbolic displacement; else for ctx.sdn, without b's offset, when
    there is one).  t is then processed.

    0x091A1E (cc.a88k 0x0933FE), 0x290 bytes, link #-72: ctx, a and b
    copied from their addresses (pattern 64); `kind is 110 or 109'
    evaluated whole (`seq', `or.b'); the offsets +12 (110) and +56
    (109), the classes +11 bits 7..4 (110) and +72 (109); the classes
    as `btst' of #130 and #68; -CPU 6 `btst #0' of cargs' +0x284; the
    paths that leave a's offset out branch past its subtraction. }

  procedure process_index_opr(
      e: oi_edge_ptr_t;
      var x: oi_call_t;
      var t: il_$node_ptr_t;
      ctx: oi_ctx_t;
      var r: oi_info_t;
      a: oi_symind_t;
      b: oi_symind_t); options(val_param);
  var
    n: il_$node_ptr_t;
    aoff: integer32;
    boff: integer32;
    d: integer32;
    cls: integer;
    found: boolean;
    rebase: boolean;
  begin
    if (a.v <> nil) and (b.v <> nil) and
       ((a.v^.kind = fortran_symbol) or (a.v^.kind = var_name)) and
       ((b.v^.kind = fortran_symbol) or (b.v^.kind = var_name)) then begin
      n := t;
      found := true;
      rebase := true;
      if (n^.kind = sb_register) or (n^.kind = ap_register) then begin
        if a.v^.kind = fortran_symbol then
          aoff := a.v^.xl[3]
        else
          aoff := a.v^.xl[14];
        if b.v^.kind = fortran_symbol then begin
          cls := rshft(ord(b.v^.xc[11]) & 16#F0, 4);
          boff := b.v^.xl[3];
        end
        else begin
          cls := ord(b.v^.vr_vat);
          boff := b.v^.xl[14];
        end;
      end
      else if (n^.kind = fortran_symbol) and
              (var_$display_ptr in n^.fs_attr) and
              (oi_level_ptr_t(e^.caller)^.level <
               oi_level_ptr_t(e^.callee)^.level) then begin
        boff := b.v^.xl[3];
        cls := rshft(ord(b.v^.xc[11]) & 16#F0, 4);
        aoff := a.v^.xl[3];
      end
      else if (n^.kind = var_name) and (var_$display_ptr in n^.vr_attr) and
              (n^.xp[1] = e^.caller^.xp[74]) then begin
        aoff := a.v^.xl[14];
        boff := b.v^.xl[14];
        cls := ord(b.v^.vr_vat);
      end
      else if (n^.kind = tree_node) and (n^.tr_op = addr_top) and
              (n^.xp[10]^.kind = fortran_symbol) then begin
        cls := rshft(ord(b.v^.xc[11]) & 16#F0, 4);
        boff := b.v^.xl[3];
        rebase := false;
      end
      else if (n^.kind = tree_node) and (n^.tr_op = addr_top) and
              (n^.xp[10]^.kind = var_name) then begin
        boff := b.v^.xl[14];
        cls := ord(b.v^.vr_vat);
        rebase := false;
      end
      else
        found := false;
      if found then begin
        if rebase and (ctx.sdn = nil) then
          d := disp_offset(ctx.dnode) - aoff
        else
          d := disp_offset(ctx.dnode);
        if cls in [1, 7] then begin
          adjust_disp(d + boff, b.sym, ctx.base, r);
          t := il_node_154;
          if ctx.sdn <> nil then
            ctx.sdn^.xp[8] := nil;
        end
        else if cls in [2, 6] then begin
          t := il_node_153;
          if 6 in cargs_$options.cpu then begin
            if ctx.sdn = nil then begin
              r.sdn_var := b.v;
              r.sdn_sym := b.sym;
              r.node := ctx.base;
            end;
            adjust_disp(d, b.sym, ctx.base, r);
          end
          else if ctx.sdn = nil then
            adjust_disp(d + boff, b.sym, ctx.base, r)
          else
            adjust_disp(d, b.sym, ctx.sdn, r);
        end;
      end;
    end;
    process_operand(e, x, t, ctx, r);
  end;

  { process_opr_ind - the base (+24) and symbol (+28) of reference t
    (205, 147, 146, 145; orig the callee's) processed for edge e.  The
    symbol becomes its display record's captured indirection when it
    has one.  The reference sets ctx's symbol and variable (a 205's
    +28 and +32; a 147's, a 146's (but under a 205) or a 145's (but
    under a 205 or 146) +28 when that is not a type, 122) and kind.
    Without both variables of get_sym_ind_info (109 or 110) the base
    and the symbol are processed as they are.  Else, for a pointer
    reference (146) whose base is a parameter temporary (110, +24 bit
    23, of a callee nested deeper than the caller) or a parameter
    variable (109, +32 bit 23, named by the caller), t becomes the
    variable reached (its displacement less the variable's offset
    into r for orig) or, with a symbolic displacement, that node's
    variable (+32, taken from it); likewise for a 146 over such a 146
    when the symbolic displacement's variable is a 110 or 109 of class
    2 or 5 at a positive offset; a 146 over an indexing (137 op 13) of
    a 153 by a variable of class 1 or 7 becomes an indexed reference
    (145, 44 bytes: the 146's first 32, the 153 its base, the index
    +36, the symbol +28, the tree's +26 at +42).  Each such t is
    processed again.  Otherwise the base is processed (an indexed
    reference's rebased, process_index_opr) and the symbol becomes the
    substitute's symbol (for a variable), the name (+4) of the
    variable an identifier stands for, or is processed.

    0x091CAE (cc.a88k 0x09368E), 0x576 bytes, link #-92: t, base, sym,
    ctx and r by address, orig by value; the kinds a compare chain;
    `kind is 205 or 146' and `kind is 110 or 109' evaluated whole;
    the new 145's first 32 bytes moved through two frame locals
    (lib_$data_move, the length a longword after process_operand);
    the displacement stored to a frame longword not read again; the
    five rebasings' process_operand one call (a shared tail, a `st'
    of the flag after it). }

  procedure process_opr_ind(
      e: oi_edge_ptr_t;
      var x: oi_call_t;
      var t: il_$node_ptr_t;
      var base: il_$node_ptr_t;
      var sym: il_$node_ptr_t;
      var ctx: oi_ctx_t;
      var r: oi_info_t;
      orig: il_$node_ptr_t); options(val_param);
  var
    val: il_$node_ptr_t;
    flags: oi_flags_t;
    info: oi_info_t;
    raw: oi_symind_t;
    sub: oi_symind_t;
    sym0: il_$node_ptr_t;
    off: integer32;
    cls: integer;
    d: integer32;
    done: boolean;
    w: il_$node_ptr_t;
    p: il_$node_ptr_t;
    n: il_$node_ptr_t;
  begin
    get_hash_info(e, sym, val, flags, info);
    if info.ind <> nil then
      sym := info.ind;
    case t^.kind of
      sym_disp_node: begin
        ctx.sym := t^.xp[7];
        ctx.v := t^.xp[8];
        ctx.kind := 205;
      end;
      disp_node:
        if t^.xp[7]^.kind <> integer_type then begin
          ctx.sym := t^.xp[7];
          ctx.v := t^.xp[7];
          ctx.kind := 147;
        end;
      ptr_node:
        if ctx.kind <> 205 then
          if t^.xp[7]^.kind <> integer_type then begin
            ctx.sym := t^.xp[7];
            ctx.v := t^.xp[7];
            ctx.kind := 146;
          end;
      dindex_node:
        if not ((ctx.kind = 205) or (ctx.kind = 146)) then
          if t^.xp[7]^.kind <> integer_type then begin
            ctx.sym := t^.xp[7];
            ctx.v := t^.xp[7];
            ctx.kind := 145;
          end;
      otherwise
        ;
    end;
    sym0 := sym;
    get_sym_ind_info(e, x, ctx, raw, sub);
    if (raw.v <> nil) and (sub.v <> nil) and
       ((raw.v^.kind = fortran_symbol) or (raw.v^.kind = var_name)) and
       ((sub.v^.kind = fortran_symbol) or (sub.v^.kind = var_name)) then begin
      if raw.v^.kind = fortran_symbol then
        off := raw.v^.xl[3]
      else
        off := raw.v^.xl[14];
      if sub.v^.kind = fortran_symbol then
        cls := rshft(ord(sub.v^.xc[11]) & 16#F0, 4)
      else
        cls := ord(sub.v^.vr_vat);
      get_hash_info(e, base, val, flags, info);
      if (flags * [0, 1, 2]) <> [] then
        ctx.subst := true;
      done := false;
      if (t^.kind = ptr_node) and (base^.kind = fortran_symbol) and
         (var_$display_ptr in base^.fs_attr) and
         (oi_level_ptr_t(e^.caller)^.level <
          oi_level_ptr_t(e^.callee)^.level) then begin
        if ctx.sdn = nil then begin
          d := disp_offset(ctx.dnode) - off;
          adjust_disp(d, sub.sym, orig, r);
          t := raw.v;
        end
        else begin
          t := ctx.sdn^.xp[8];
          ctx.sdn^.xp[8] := nil;
        end;
        process_operand(e, x, t, ctx, r);
        done := true;
      end
      else if (t^.kind = ptr_node) and (base^.kind = var_name) and
              (var_$display_ptr in base^.vr_attr) and
              (base^.xp[1] = e^.caller^.xp[74]) then begin
        if ctx.sdn = nil then begin
          d := disp_offset(ctx.dnode) - off;
          adjust_disp(d, sub.sym, orig, r);
          t := raw.v;
        end
        else begin
          t := ctx.sdn^.xp[8];
          ctx.sdn^.xp[8] := nil;
        end;
        process_operand(e, x, t, ctx, r);
        done := true;
      end
      else if (t^.kind = ptr_node) and (base^.kind = ptr_node) and
              (base^.xp[6]^.kind = fortran_symbol) and
              (var_$display_ptr in base^.xp[6]^.fs_attr) and
              (ctx.sdn <> nil) and (ctx.sdn^.xp[8]^.kind = fortran_symbol) and
              (integer(rshft(ord(ctx.sdn^.xp[8]^.xc[11]) & 16#F0, 4)) in [2, 5]) and
              (ctx.sdn^.xp[8]^.xl[3] > 0) and
              (oi_level_ptr_t(e^.caller)^.level <
               oi_level_ptr_t(e^.callee)^.level) then begin
        t := ctx.sdn^.xp[8];
        ctx.sdn^.xp[8] := nil;
        process_operand(e, x, t, ctx, r);
        done := true;
      end
      else if (t^.kind = ptr_node) and (base^.kind = ptr_node) and
              (base^.xp[6]^.kind = var_name) and
              (var_$display_ptr in base^.xp[6]^.vr_attr) and
              (ctx.sdn <> nil) and (ctx.sdn^.xp[8]^.kind = var_name) and
              (ctx.sdn^.xp[8]^.vr_vat in [dynm_vat, param_vat]) and
              (ctx.sdn^.xp[8]^.xl[14] > 0) and
              (base^.xp[6]^.xp[1] = e^.caller^.xp[74]) then begin
        t := ctx.sdn^.xp[8];
        ctx.sdn^.xp[8] := nil;
        process_operand(e, x, t, ctx, r);
        done := true;
      end
      else if (t^.kind = ptr_node) and (t^.xp[6]^.kind = tree_node) and
              (t^.xp[6]^.tr_op = index_top) and
              (t^.xp[6]^.xp[10]^.kind = sb_register) and (cls in [1,
                  7]) then begin
        p := t;
        w := p^.xp[6];
        n := gspace(44);
        lib_$data_move(p, n, 32);
        n^.kind := dindex_node;
        n^.xp[6] := w^.xp[10];
        n^.xp[9] := w^.xp[11];
        n^.xp[7] := sym0;
        n^.xw[21] := w^.xw[13];
        t := n;
        process_operand(e, x, t, ctx, r);
        done := true;
      end
      else if t^.kind = dindex_node then
        process_index_opr(e, x, base, ctx, r, raw, sub)
      else
        process_operand(e, x, base, ctx, r);
      if not done then
        if (sym0^.kind = fortran_symbol) or (sym0^.kind = var_name) then
          sym := sub.sym
        else if (sym0^.kind = id_ob) and (sub.sym <> nil) and
                (sub.sym^.kind = var_name) then
          sym := sub.sym^.xp[1]
        else begin
          sym := sym0;
          process_operand(e, x, sym, ctx, r);
        end;
    end
    else begin
      process_operand(e, x, base, ctx, r);
      process_operand(e, x, sym, ctx, r);
    end;
  end;

begin
  if t = nil then
    return;
  if ctx.call <> nil then
    if (t^.kind = function_blk) or (t^.kind = procedure_blk) then
      return;
  if not ctx.subst then
    case t^.kind of
      cmp_tree_node, tree_node:
        ctx.uses := t^.xw[8];
      ptr_node:
        ctx.uses := t^.xw[8];
      disp_node:
        ctx.uses := t^.xw[8];
      sym_disp_node:
        ctx.uses := t^.xw[8];
      dindex_node:
        ctx.uses := t^.xw[8];
      cs_node:
        ctx.uses := t^.xw[8];
      otherwise
        ;
    end;
  get_hash_info(e, t, val, flags, info);
  if (flags * [0, 1, 2]) <> [] then
    ctx.subst := true;
  orig := t;
  if val <> nil then begin
    t := val;
    if info.node = orig then
      apply_disp(e, nil, ctx, info, t);
    if not ctx.subst then
      return;
    orig := t;
  end;
  case t^.kind of
    block_entry_node: begin
      if orig^.xp[12]^.kind = inner_blk then
        orig^.xp[12]^.xp[19] := x.blk
      else
        orig^.xp[12]^.xp[19] := nil;
      x.blk := orig^.xp[12];
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(52);
      lib_$data_move(orig, n, 52);
      t := n;
      get_hash_info(e, orig^.xp[12], n^.xp[12], flags2, info);
    end;
    blk_end_node: begin
      if x.blk^.xp[19] <> nil then
        x.blk := x.blk^.xp[19]
      else
        x.blk := x.blk^.xp[2];
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(52);
      lib_$data_move(orig, n, 52);
      t := n;
      get_hash_info(e, orig^.xp[12], n^.xp[12], flags2, info);
    end;
    assign_node:
      if (orig^.xp[16]^.kind = fortran_symbol) and
         (var_$display_ptr in orig^.xp[16]^.fs_attr) then
        t := nil
      else if (t^.xp[17]^.kind = display_register) and
              not inline_$is_fortran_asf(e^.caller) then begin
        put_hash_info(e, t^.xp[16], il_node_153, [], empty_info);
        t := nil;
      end
      else begin
        e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
        n := gspace(80);
        lib_$data_move(t, n, 80);
        t := n;
        cur_stmt := n;
        process_operand(e, x, t^.xp[16], ctx, r);
        process_operand(e, x, t^.xp[17], ctx, r);
        process_operand(e, x, t^.xp[18], ctx, r);
      end;
    label_node:
      get_hash_info(e, orig, t, flags2, info);
    eval_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      if t^.xw[25] = 0 then
        size := 92
      else
        size := t^.xw[25] * 4 + 52;
      n := gspace(size);
      lib_$data_move(t, n, t^.xw[25] * 4 + 52);
      t := n;
      cur_stmt := n;
      for i := t^.xw[25] downto 1 do
        process_operand(e, x, t^.xp[12 + i], ctx, r);
    end;
    branch_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(56);
      lib_$data_move(orig, n, 56);
      t := n;
      cur_stmt := n;
      get_hash_info(e, orig^.xp[12], val2, flags2, info);
      if val2 <> nil then
        t^.xp[12] := val2;
    end;
    cbranch_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(64);
      lib_$data_move(t, n, 64);
      t := n;
      cur_stmt := n;
      process_operand(e, x, t^.xp[14], ctx, r);
      get_hash_info(e, orig^.xp[12], val2, flags2, info);
      if val2 <> nil then
        t^.xp[12] := val2;
    end;
    nlbranch_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(52);
      lib_$data_move(t, n, 52);
      t := n;
      cur_stmt := n;
      process_operand(e, x, t^.xp[12], ctx, r);
    end;
    return_node: begin
      t := nil;
      return;
    end;
    tree_node, cmp_tree_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      size := orig^.xw[19] * 4 + 40;
      n := gspace(size);
      lib_$data_move(t, n, size);
      t := n;
      if ctx.subst then
        t^.xw[8] := ctx.uses;
      if (t^.tr_op = func_call_top) or (t^.tr_op = call_top) then begin
        ctx.call := t;
        process_operand(e, x, t^.xp[10], ctx, r);
        ctx.call := nil;
        for i := 2 to t^.xw[19] do
          process_operand(e, x, t^.xp[9 + i], ctx, r);
        inline_$mark_reference_params(t, cur_stmt);
      end
      else if t^.tr_op = index_top then begin
        if ctx.base = nil then
          ctx.base := orig;
        get_sym_ind_info(e, x, ctx, raw, sub);
        process_index_opr(e, x, t^.xp[10], ctx, r, raw, sub);
        for i := 2 to t^.xw[19] do
          process_operand(e, x, t^.xp[9 + i], ctx, r);
      end
      else
        for i := 1 to t^.xw[19] do
          process_operand(e, x, t^.xp[9 + i], ctx, r);
      if r.node = orig then
        apply_disp(e, orig, ctx, r, t)
      else
        put_hash_info(e, orig, t, [], empty_info);
      if ctx.base = orig then
        ctx.base := nil;
    end;
    ptr_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(32);
      lib_$data_move(t, n, 32);
      t := n;
      if ctx.subst then
        t^.xw[8] := ctx.uses;
      process_opr_ind(e, x, t, t^.xp[6], t^.xp[7], ctx, r, orig);
      if (t^.kind = ptr_node) and (t^.xp[6]^.kind = tree_node) and
         (t^.xp[6]^.tr_op = addr_top) then
        t := t^.xp[6]^.xp[10];
      if r.node = orig then
        apply_disp(e, orig, ctx, r, t)
      else
        put_hash_info(e, orig, t, [], empty_info);
    end;
    dindex_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(44);
      lib_$data_move(t, n, 44);
      t := n;
      if ctx.subst then
        t^.xw[8] := ctx.uses;
      if ctx.base = nil then
        ctx.base := orig;
      process_operand(e, x, t^.xp[9], ctx, r);
      process_opr_ind(e, x, t, t^.xp[6], t^.xp[7], ctx, r, orig);
      if r.node = orig then
        apply_disp(e, orig, ctx, r, t)
      else
        put_hash_info(e, orig, t, [], empty_info);
      if ctx.base = orig then
        ctx.base := nil;
    end;
    disp_node: begin
      while t^.xp[6]^.kind = disp_node do begin
        t^.xl[8] := t^.xl[8] + t^.xp[6]^.xl[8];
        t^.xp[6] := t^.xp[6]^.xp[6];
      end;
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(36);
      lib_$data_move(t, n, 36);
      t := n;
      if ctx.subst then
        t^.xw[8] := ctx.uses;
      ctx.dnode := t;
      process_opr_ind(e, x, t, t^.xp[6], t^.xp[7], ctx, r, orig);
      put_hash_info(e, orig, t, [], empty_info);
      if r.disp <> 0 then begin
        apply_disp(e, nil, ctx, r, t);
        nil_out_dispinfo(r);
      end;
    end;
    sym_disp_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(36);
      lib_$data_move(t, n, 36);
      t := n;
      ctx.sdn := t;
      if ctx.subst then
        t^.xw[8] := ctx.uses;
      process_operand(e, x, t^.xp[8], ctx, r);
      if t^.xp[8]^.kind = ptr_node then
        t^.xp[8] := t^.xp[8]^.xp[6]
      else if (t^.xp[8]^.kind = tree_node) and
              (t^.xp[8]^.tr_op = addr_top) then
        t^.xp[8] := t^.xp[8]^.xp[10];
      process_opr_ind(e, x, t, t^.xp[6], t^.xp[7], ctx, r, orig);
      if t^.xp[8] = nil then
        t := t^.xp[6];
      put_hash_info(e, orig, t, [], empty_info);
    end;
    pf_call: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(24);
      lib_$data_move(t, n, 24);
      t := n;
      process_operand(e, x, t^.xp[4], ctx, r);
      process_operand(e, x, t^.xp[5], ctx, r);
    end;
    cc_call: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      size := (ctx.call^.xw[19] - 1) * 4 + 20;
      n := gspace(size);
      lib_$data_move(t, n, size);
      t := n;
      process_operand(e, x, t^.xp[4], ctx, r);
    end;
    cs_node: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(32);
      lib_$data_move(t, n, 32);
      t := n;
      if ctx.subst then
        t^.xw[8] := ctx.uses;
      process_operand(e, x, t^.xp[5], ctx, r);
      process_operand(e, x, t^.xp[6], ctx, r);
      put_hash_info(e, orig, t, [], empty_info);
    end;
    cs_temp: begin
      e^.caller^.xw[136] := e^.caller^.xw[136] + 1;
      n := gspace(28);
      lib_$data_move(t, n, 28);
      t := n;
      t^.xp[2] := e^.caller;
      allocate_space(e, t^.xw[11], 1, false, t^.xw[10], t^.xl[4]);
      put_hash_info(e, orig, t, [], empty_info);
    end;
    otherwise
      ;
  end;
  if 4 in flags then
    put_hash_info(e, orig, t, flags - [4], info);
end;

{ process_statements - the callee's statements, from its first (+100)
  to its end (149 of the callee, +48), copied (process_operand, the
  context empty but for a use count of 1) and put on the stream; a
  call with a line (x.line) reported (cgerr 37) first.

  0x092E20, 0xB0 bytes, link #-72: the context initialized from 28
  bytes after the routine (+27 the 1), +28 cleared; the display
  record the empty one's copy. }

procedure process_statements(
    e: oi_edge_ptr_t;
    var x: oi_call_t); options(val_param); internal;
var
  t: il_$node_ptr_t;
  ctx: oi_ctx_t;
  info: oi_info_t;
  s: il_$node_ptr_t;
begin
  if x.line <> 0 then
    cgerr(37, x.line, e^.callee^.xp[74]);
  ctx.base := nil;
  ctx.call := nil;
  ctx.dnode := nil;
  ctx.sdn := nil;
  ctx.sym := nil;
  ctx.v := nil;
  ctx.kind := 0;
  ctx.uses := 1;
  ctx.subst := false;
  info := empty_info;
  s := e^.callee^.xp[25];
  repeat
    t := s;
    process_operand(e, x, t, ctx, info);
    if t <> nil then
      put_on_il_stream(t);
    if (s^.kind = blk_end_node) and (s^.xp[12] = e^.callee) then
      exit;
    s := s^.xp[2];
  until false;
end;

{ process_blocks - the blocks of the copy: the callee's block becomes
  a new block (172, 396 bytes: the callee's name, +92, data section
  +188, +192, level, first and last statements; +374..+377 flags
  0x04000800 with the language's, +378 bit 7) the caller expands
  into (caller_blk); the callee's +264 lowered and +374 bit 1 set.
  Its first statement maps to the stream's head, its last (and each
  contained block's) to nothing (flag 4).  Each contained block is
  copied (396 bytes, and two per parameter in languages 1 and 2;
  its variables cleared) and the copies chained after caller_blk in
  the block list of e's block (+12), their enclosing blocks (+8) and
  levels (+294) moved by the depth.  e's block's last variable (+20)
  set when only its first is; the caller marked +376 bit 7 when the
  callee is.

  0x092EEC, 0x30E bytes, link #-76: the sizes by a jump table of 4
  on the language (another reported); put_hash_info's frames popped
  2 short (pattern 51). }

procedure process_blocks(
    e: oi_edge_ptr_t); options(val_param); internal;
var
  cal: il_$node_ptr_t;
  b: il_$node_ptr_t;
  n: il_$node_ptr_t;
  last: il_$node_ptr_t;
  p: il_$node_ptr_t;
  v: il_$node_ptr_t;
  w: il_$node_ptr_t;
  save: il_$node_ptr_t;
  dl: integer;
  size: integer;
  len: integer32;
  fl: oi_flags_t;
  info: oi_info_t;
begin
  e^.callee^.xw[132] := e^.callee^.xw[132] - 1;
  e^.callee^.blk_atts.inlined := true;
  cal := e^.callee;
  caller_blk := gspace(396);
  caller_blk^.kind := inner_blk;
  caller_blk^.xp[74] := cal^.xp[74];
  caller_blk^.xp[23] := cal^.xp[23];
  caller_blk^.xl2[93] := (caller_blk^.xl2[93] & 16#7FF) ! 16#04000800;
  caller_blk^.xw[188] := caller_blk^.xw[188] & 16#FE7F;
  caller_blk^.xc[377] := chr((ord(caller_blk^.xc[377]) & 16#8F) !
                             (ord(cal^.xc[377]) & 16#70));
  caller_blk^.blk_atts.sb_display := true;
  caller_blk^.xp[47] := cal^.xp[47];
  caller_blk^.xp[48] := cal^.xp[48];
  oi_level_ptr_t(caller_blk)^.level := oi_level_ptr_t(cal)^.level;
  caller_blk^.xp[25] := cal^.xp[25];
  caller_blk^.xp[26] := cal^.xp[26];
  put_hash_info(e, cal, caller_blk, [], empty_info);
  put_hash_info(e, cal^.xp[25], stream_head, [], empty_info);
  put_hash_info(e, cal^.xp[26], nil, [4], empty_info);
  dl := oi_level_ptr_t(e^.scope)^.level + 1 - oi_level_ptr_t(cal)^.level;
  b := next_contained_block(e^.callee, e^.callee);
  while b <> nil do begin
    case language of
      1, 2:
        size := ord(b^.xc[293]) * 2 + 396;
      3, 4:
        size := 396;
      otherwise
        cgerr_no_source(28, integer32(strtk('unexpected IL encountered', 25)));
    end;
    n := gspace(size);
    len := size;
    lib_$data_move(b, n, len);
    n^.xp[4] := nil;
    n^.xp[5] := nil;
    put_hash_info(e, b, n, [], empty_info);
    put_hash_info(e, b^.xp[25], nil, [4], empty_info);
    put_hash_info(e, b^.xp[26], nil, [4], empty_info);
    b := next_contained_block(e^.callee, b);
  end;
  save := e^.scope^.xp[1];
  e^.scope^.xp[1] := caller_blk;
  caller_blk^.xp[2] := e^.scope;
  oi_level_ptr_t(caller_blk)^.level := oi_level_ptr_t(caller_blk)^.level + dl;
  last := caller_blk;
  p := caller_blk;
  b := next_contained_block(e^.callee, e^.callee);
  while b <> nil do begin
    get_hash_info(e, b, last, fl, info);
    p^.xp[1] := last;
    if b^.xp[2] = e^.callee then
      last^.xp[2] := caller_blk
    else
      get_hash_info(e, b^.xp[2], last^.xp[2], fl, info);
    oi_level_ptr_t(last)^.level := oi_level_ptr_t(last)^.level + dl;
    p := p^.xp[1];
    b := next_contained_block(e^.callee, b);
  end;
  last^.xp[1] := save;
  if (e^.scope^.xp[4] <> nil) and (e^.scope^.xp[5] = nil) then begin
    v := e^.scope^.xp[4];
    repeat
      if v^.kind = fortran_symbol then
        w := v^.xp[1]
      else
        w := v^.xp[4];
      if w <> nil then
        v := w;
    until w = nil;
    e^.scope^.xp[5] := v;
  end;
  if e^.callee^.blk_atts.need_fp_fcw then
    e^.caller^.blk_atts.need_fp_fcw := true;
end;

{ cleanup_expansion - block b's storage after expansions: the data
  section's offsets (+192: +24, +20) aligned up to 4, the frame (+112)
  down to 4 and +176 up to 4; +80 the least of itself and the frame.

  0x0931FA, 0x6C bytes, link #-12: align's two words pushed as one
  longword (#0x20000, #0x20001, pattern 54). }

procedure cleanup_expansion(
    b: il_$node_ptr_t); options(val_param); internal;
var
  m: integer32;
begin
  align(b^.xp[48]^.xl[6], 2, 0);
  align(b^.xp[48]^.xl[5], 2, 0);
  align(b^.xl[28], 2, 1);
  align(b^.xl[44], 2, 0);
  m := b^.xl[28];
  if m > b^.xl[20] then
    m := b^.xl[20];
  b^.xl[20] := m;
end;

{ call_status - whether the call of edge e can be expanded (63) or
  why not: 27 the callee not inlinable (+375 bit 7 clear), 43 another
  data section (+188) unless forced (+375 bit 5), 40 the callee
  contains routines (107, 108) or has a variable whose address is
  exposed (+34 bit 8; in Fortran +26 bit 8) while another routine
  calls it too, 35 the parameters do not match (count, a Fortran
  statement function's temporary of class 7, +10 bit 7, or in
  languages 3 and 4 a real or block passed for a parameter of
  another class), 39 too large (variables past 255, counts past
  65535, the frame or static data past 24K, more than 100 nodes
  unless forced or -FORCE_INLINE).  x.result is set to the callee's
  result variable (function_return).

  0x093266, 0x392 bytes, link #-60: the parameters counted by `dbf';
  pass_method's answers by a jump table of 4 (3 adds 7 bytes); the
  sizes of the copies and the result summed with 7 bytes each; a
  dead `btst #3' of the callee's +374 before the last loop. }

function call_status(
    e: oi_edge_ptr_t;
    var x: oi_call_t): integer; options(val_param); internal;
var
  cal: il_$node_ptr_t;
  b: il_$node_ptr_t;
  f: il_$node_ptr_t;
  a: il_$node_ptr_t;
  p: il_$node_ptr_t;
  v: il_$node_ptr_t;
  ed: oi_edge_ptr_t;
  size: integer32;
  k: integer;
  w: integer;
  m: integer;
  d: add_node_$desc_t;
  found: boolean;
begin
  cal := e^.callee;
  if not cal^.blk_atts.inlineable then begin
    call_status := 27;
    return;
  end;
  if e^.caller^.xp[47] <> cal^.xp[47] then
    if not cal^.blk_atts.inline then begin
      call_status := 43;
      return;
    end;
  b := next_contained_block(cal, cal);
  while b <> nil do begin
    if (b^.kind = procedure_blk) or (b^.kind = function_blk) then begin
      call_status := 40;
      return;
    end;
    b := next_contained_block(e^.callee, b);
  end;
  if ord(cal^.xc[293]) <> e^.call^.xw[19] - 1 then begin
    call_status := 35;
    return;
  end;
  size := 0;
  p := nil;
  if language <> 2 then
    p := cal^.xp[3];
  for k := 1 to ord(cal^.xc[293]) do begin
    if language = 2 then
      f := oi_ftab_ptr_t(e^.callee^.xp[3])^[k].sym
    else
      f := find_varn(e^.callee, p);
    a := inliner_actual(e^.call^.xp[10 + k]);
    m := pass_method(e, k, a, f, p);
    case m of
      0: begin
        if language = 2 then
          if f^.kind = fortran_symbol then
            if (ord(f^.xc[10]) & 15) = 7 then
              if ord(f^.xc[10]) >= 128 then begin
                call_status := 35;
                return;
              end;
        get_size_rlen(f, d);
        size := size + d.size + 7;
        if language in [3, 4] then begin
          w := e^.call^.xp[10]^.xw[9 + 2 * k];
          if ((w = 7) or (w = 6)) and not ((d.rlen = rlen_r8) or (d.rlen = rlen_r4)) then begin
            call_status := 35;
            return;
          end;
          if (d.rlen = rlen_r8) or (d.rlen = rlen_r4) then
            if not ((w = 7) or (w = 6)) then begin
              call_status := 35;
              return;
            end;
          if (w = 11) and (d.rlen <> rlen_agg) then begin
            call_status := 35;
            return;
          end;
          if (d.rlen = rlen_agg) and (w <> 11) then begin
            call_status := 35;
            return;
          end;
        end;
      end;
      3:
        size := size + 7;
      otherwise
        ;
    end;
    if language <> 2 then
      p := p^.xp[1];
  end;
  x.result := function_return(e^.callee);
  if x.result <> nil then begin
    get_size_rlen(x.result, d);
    size := size + d.size + 7;
  end;
  b := e^.caller;
  cal := e^.callee;
  if b^.xw[145] + cal^.xw[145] > 255 then begin
    call_status := 39;
    return;
  end;
  if (b^.xw[136] & 16#FFFF) + (cal^.xw[136] & 16#FFFF) > 65535 then begin
    call_status := 39;
    return;
  end;
  if b^.kind = program_blk then begin
    if size + b^.xp[48]^.xl[5] + cal^.xl[44] - cal^.xl[28] > 24576 then begin
      call_status := 39;
      return;
    end;
  end
  else if b^.xl[28] - b^.xl[44] - size - cal^.xl[44] + cal^.xl[28] < -24576 then begin
    call_status := 39;
    return;
  end;
  if (not cal^.blk_atts.inline) and not cargs_$options.force_inline then
    if (cal^.xw[136] & 16#FFFF) > 100 then begin
      call_status := 39;
      return;
    end;
  v := cal^.xp[4];
  found := false;
  while (v <> nil) and not found do
    if e^.callee^.blk_atts.call = call_ftn then begin
      found := (v^.xw[13] & 16#100) <> 0;
      v := v^.xp[1];
    end
    else if (v^.kind = var_name)
        and (v^.xp[7]^.kind <> procedure_blk) then begin
      found := (v^.xw[17] & 16#100) <> 0;
      v := v^.xp[4];
    end
    else
      v := v^.xp[4];
  if found then begin
    b := il_184;
    while b <> nil do begin
      if b <> e^.caller then begin
        ed := oi_edge_ptr_t(b^.xp[61]);
        while ed <> nil do begin
          if ed^.callee = e^.callee then begin
            call_status := 40;
            return;
          end;
          ed := ed^.caller_next;
        end;
      end;
      b := b^.xp[1];
    end;
  end;
  call_status := 63;
end;

{ remove_call_graph_edge - edge e taken off its caller's edges out
  (+244, through caller_next) and its callee's edges in (+252,
  through callee_next).

  0x0935F8, 0x64 bytes, no frame. }

procedure remove_call_graph_edge(
    e: oi_edge_ptr_t); options(val_param); internal;
var
  p: oi_edge_ptr_t;
begin
  if oi_edge_ptr_t(e^.caller^.xp[61]) = e then
    e^.caller^.xp[61] := il_$node_ptr_t(e^.caller_next)
  else begin
    p := oi_edge_ptr_t(e^.caller^.xp[61]);
    while p <> nil do begin
      if p^.caller_next = e then begin
        p^.caller_next := e^.caller_next;
        exit;
      end;
      p := p^.caller_next;
    end;
  end;
  if oi_edge_ptr_t(e^.callee^.xp[63]) = e then
    e^.callee^.xp[63] := il_$node_ptr_t(e^.callee_next)
  else begin
    p := oi_edge_ptr_t(e^.callee^.xp[63]);
    while p <> nil do begin
      if p^.callee_next = e then begin
        p^.callee_next := e^.callee_next;
        exit;
      end;
      p := p^.callee_next;
    end;
  end;
end;

{ dfs_walk - the calls of routine block b (107, 108, 105; not yet
  visited, +374 bit 0) expanded, callees first: b marked visited and
  on the walk (+379 bit 1, cleared at the end); each edge out to a
  routine (105..108, 172, 209) not on the walk has its callee walked
  and, when call_status allows (63), the call expanded (the stream
  started, the blocks, parameters, display pointers, labels,
  variables and statements copied, the stream patched in, the hash
  table's entries for b forgotten, the edge removed); a call not
  expanded (a recursive one: 38) is reported at its line (cgerr)
  when the callee is inlinable (+375 bit 7) and forced (+375 bit 5,
  -FORCE_INLINE), but for 27, and its reference parameters marked.
  After any expansion b's storage is settled (cleanup_expansion) and
  the table cleared of b's entries.

  0x09365C, 0x1BE bytes, link #-28: the callee's kind against the
  28-byte set after the routine; the call's record at -16, the sites'
  cursor at -24; cleanup_expansion's frame popped 2 short (pattern
  51). }

procedure dfs_walk(
    b: il_$node_ptr_t); options(val_param); internal;
var
  ed: oi_edge_ptr_t;
  c: il_$node_ptr_t;
  st: integer;
  x: oi_call_t;
  l: oi_site_list_ptr_t;
  expanded: boolean;
begin
  if b = nil then
    return;
  if not ((b^.kind = procedure_blk) or (b^.kind = function_blk)
          or (b^.kind = program_blk)) then
    return;
  if b^.blk_atts.expanded then
    return;
  b^.blk_atts.expanded := true;
  b^.blk_atts.visited_depth_first := true;
  expanded := false;
  ed := oi_edge_ptr_t(b^.xp[61]);
  while ed <> nil do begin
    x.line := current_ln(ed^.stmt);
    st := 0;
    if ed^.callee <> nil then
      if ed^.callee^.kind in [program_blk..function_blk, inner_blk,
                              blockdata_blk] then begin
        c := ed^.callee;
        if c^.blk_atts.visited_depth_first then begin
          if c^.blk_atts.inline or cargs_$options.force_inline then
            if c^.blk_atts.inlineable then
              if x.line <> 0 then
                cgerr(38, x.line, c^.xp[74]);
        end
        else begin
          dfs_walk(c);
          st := call_status(ed, x);
          status := st;
          if st = 63 then begin
            expanded := true;
            start_il_stream(ed, x);
            process_blocks(ed);
            process_parameters(ed, x);
            process_display_ptrs(ed);
            process_labels(ed);
            process_variables(ed);
            process_statements(ed, x);
            patch_il(ed, x, l);
            cleanup_hash(b, 0);
            remove_call_graph_edge(ed);
          end
          else if st <> 27 then begin
            c := ed^.callee;
            if c^.blk_atts.inline or cargs_$options.force_inline then
              if c^.blk_atts.inlineable then
                if x.line <> 0 then
                  cgerr(st, x.line, c^.xp[74]);
          end;
        end;
      end;
    if st <> 63 then
      inline_$mark_reference_params(ed^.call, ed^.stmt);
    ed := ed^.caller_next;
  end;
  if expanded then begin
    cleanup_expansion(b);
    cleanup_hash(b, 1);
  end;
  b^.blk_atts.visited_depth_first := false;
end;

{ check_call_sites_and_expand - the heap set up ('opt_inline'), the
  hash table's heads cleared, each block's walk mark (+379 bit 1)
  cleared and its count of variables (+290) taken
  (il_utl_$count_vars), the empty display record cleared, and the
  routines marked +374 bit 3 walked (dfs_walk); the heap released.

  0x093836, 0xAE bytes, link #-12: the heads' two longwords stored by
  `move.l #0' (pattern 82); mrh_$initialize's two words pushed as one
  `clr.l'. }

procedure check_call_sites_and_expand; internal;
var
  i: integer;
  b: il_$node_ptr_t;
begin
  mrh_$initialize(heap, 0, 0, 'opt_inline%');
  for i := 0 to 1008 do begin
    hash[i].next := nil;
    hash[i].node := nil;
  end;
  b := il_184;
  while b <> nil do begin
    b^.blk_atts.visited_depth_first := false;
    b^.xw[145] := il_utl_$count_vars(b);
    b := b^.xp[1];
  end;
  nil_out_dispinfo(empty_info);
  b := il_184;
  while b <> nil do begin
    if b^.blk_atts.visible then
      dfs_walk(b);
    b := b^.xp[1];
  end;
  mrh_$release_all(heap);
end;

{ assert_is_symbolically_opaque_address - reference t (205, 147, 146,
  145) without a captured lvalue's indirection
  (alias_$ind_for_captured_lvalue) whose base (+28) is a field (120,
  119).

  0x0938F0, 0x78 bytes, link #-12: the kinds evaluated whole. }

function assert_is_symbolically_opaque_address(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  if t <> nil then
    if (t^.kind = sym_disp_node) or (t^.kind = disp_node)
        or (t^.kind = ptr_node) or
       (t^.kind = dindex_node) then
      if alias_$ind_for_captured_lvalue(t) = nil then begin
        if t^.xp[7] <> nil then
          r := (t^.xp[7]^.kind = pfield_name) or (t^.xp[7]^.kind = field_name);
      end
      else
        r := false;
  assert_is_symbolically_opaque_address := r;
end;

{ assert_contains_symbolically_opaque_addressing - tree t holds a
  symbolically opaque reference (assert_is_symbolically_opaque_address)
  not inside another reference (inside): through operators' operands
  (137, 143), references' bases (+24; an indexing's index +36), 175's
  and 171's +16, 164's +20 and +24.

  0x093968, 0x15C bytes, link #-16: inside a byte at (12,A6), stored
  back there; the operands' loop by `dbf'; the second operand looked
  at only when the first holds none. }

function assert_contains_symbolically_opaque_addressing(
    t: il_$node_ptr_t;
    inside: boolean): boolean; options(val_param); internal;
var
  r: boolean;
  k: integer;
begin
  r := false;
  if t = nil then begin
    assert_contains_symbolically_opaque_addressing := false;
    return;
  end;
  if (t^.kind = fortran_symbol) or (t^.kind = var_name) then begin
    assert_contains_symbolically_opaque_addressing := false;
    return;
  end;
  if not assert_is_nonleaf_lvalue(t) then
    inside := false
  else begin
    if not inside then
      if assert_is_symbolically_opaque_address(t) then begin
        assert_contains_symbolically_opaque_addressing := true;
        return;
      end;
    inside := true;
  end;
  case t^.kind of
    tree_node, cmp_tree_node:
      for k := 1 to t^.xw[19] do
        if assert_contains_symbolically_opaque_addressing(t^.xp[9 + k], inside) then begin
          assert_contains_symbolically_opaque_addressing := true;
          return;
        end;
    ptr_node, disp_node, sym_disp_node:
      r := assert_contains_symbolically_opaque_addressing(t^.xp[6], inside);
    dindex_node: begin
      r := assert_contains_symbolically_opaque_addressing(t^.xp[6], inside);
      if not r then
        r := assert_contains_symbolically_opaque_addressing(t^.xp[9], inside);
    end;
    pf_call:
      r := assert_contains_symbolically_opaque_addressing(t^.xp[4], inside);
    cc_call:
      r := assert_contains_symbolically_opaque_addressing(t^.xp[4], inside);
    cs_node: begin
      r := assert_contains_symbolically_opaque_addressing(t^.xp[5], inside);
      if not r then
        r := assert_contains_symbolically_opaque_addressing(t^.xp[6], inside);
    end;
    otherwise
      ;
  end;
  assert_contains_symbolically_opaque_addressing := r;
end;

{ assert_statement_contains_symbolically_opaque_addressing - statement
  s's trees hold a symbolically opaque reference: an evaluation's
  operands (139), an assignment's right, left and extra trees (140:
  +68, +64, +72), a branch's target or operand (141, 150, 151: +48;
  142: +48, +56).

  0x093AC4, 0xEA bytes, link #-16: the kinds 139..151 by a jump table
  of 13; `inside' false. }

function assert_statement_contains_symbolically_opaque_addressing(
    s: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  k: integer;
begin
  r := false;
  case s^.kind of
    eval_node:
      for k := 1 to s^.xw[25] do
        if assert_contains_symbolically_opaque_addressing(s^.xp[12 + k], false) then begin
          assert_statement_contains_symbolically_opaque_addressing := true;
          return;
        end;
    assign_node: begin
      r := assert_contains_symbolically_opaque_addressing(s^.xp[17], r);
      if not r then
        r := assert_contains_symbolically_opaque_addressing(s^.xp[16], r);
      if not r then
        r := assert_contains_symbolically_opaque_addressing(s^.xp[18], r);
    end;
    cbranch_node: begin
      r := assert_contains_symbolically_opaque_addressing(s^.xp[12], r);
      if not r then
        r := assert_contains_symbolically_opaque_addressing(s^.xp[14], r);
    end;
    branch_node, nlbranch_node, return_node:
      r := assert_contains_symbolically_opaque_addressing(s^.xp[12], r);
    otherwise
      ;
  end;
  assert_statement_contains_symbolically_opaque_addressing := r;
end;

{ assert_routine_contains_symbolically_opaque_addressing - a statement
  of routine block b (from +100) holds a symbolically opaque
  reference; b not a routine block is a bug (bug_check).

  0x093BAE, 0x54 bytes, link #-12: the message after the routine. }

function assert_routine_contains_symbolically_opaque_addressing(
    b: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  s: il_$node_ptr_t;
begin
  r := false;
  if not assert_is_a_routine_block(b) then
    bug_check('OPT_INLINE_\ASSERT_ROUTINE_CONTAINS_SYMBOLICALLY_OPAQUE_ADDRESSING -- not a routine block%.');
  s := b^.xp[25];
  while s <> nil do begin
    if assert_statement_contains_symbolically_opaque_addressing(s) then begin
      r := true;
      s := nil;
    end
    else
      s := s^.xp[2];
  end;
  assert_routine_contains_symbolically_opaque_addressing := r;
end;

{ callee_status - whether routine b (108, 107) may be expanded where
  it is called (63) or why not: 27 not a routine, marked +375 bit 6,
  or inlining not asked for it (opt_on 24, a statement function's 25;
  without +375 bit 5, 26), 39 too large (more than 255 variables, a
  frame past -24K, any +176, static data past 24K, unless -CPU M020;
  more than 100 nodes unless forced), 42 it contains a 167, 47 a
  Fortran variable of class 7 (+44), 44 a language 1 variable or
  parameter of type 133, 45 a variable of a type name of an array
  (132) with +34 bit 7, 41 a parameter that is a Fortran temporary of
  class 1 (or of class 7 and +10 bit 7 under -DBS) or a parameter of a
  routine type (174, 173), 36 a parameter of no class, +374 bit 5, a
  result of class 7 and +10 bit 7, or symbolically opaque addressing.

  0x093C5E, 0x318 bytes, link #-72: cargs' address loaded and not
  used (pattern 53); the nodes' count compared `cmpi.w #-1; bhi'. }

function callee_status(
    b: il_$node_ptr_t): integer; options(val_param); internal;
var
  n: il_$node_ptr_t;
  v: il_$node_ptr_t;
  f: il_$node_ptr_t;
  p: il_$node_ptr_t;
  te: oi_texp_t;
  d: add_node_$desc_t;
  k: integer;
begin
  callee_status := 27;
  if b = nil then
    return;
  if not ((b^.kind = function_blk) or (b^.kind = procedure_blk)) then
    return;
  if b^.blk_atts.noinline then
    return;
  if inline_$is_fortran_asf(b) then begin
    if not (25 in cargs_$options.opt_on) then
      return;
  end
  else begin
    if not (24 in cargs_$options.opt_on) then
      return;
    if not b^.blk_atts.inline then
      if not (26 in cargs_$options.opt_on) then
        return;
  end;
  callee_status := 39;
  if (b^.xw[136] & 16#FFFF) > 65535 then
    return;
  if b^.xw[145] > 255 then
    return;
  if b^.xl[28] < -24576 then
    if not (3 in cargs_$options.cpu) then
      return;
  if b^.xl[44] <> 0 then
    if not (3 in cargs_$options.cpu) then
      return;
  if b^.xp[48]^.xl[5] > 24576 then
    if not (3 in cargs_$options.cpu) then
      return;
  if (not b^.blk_atts.inline) and not cargs_$options.force_inline then
    if (b^.xw[136] & 16#FFFF) > 100 then
      return;
  n := b^.xp[1];
  while n <> nil do
    if oi_level_ptr_t(n)^.level < oi_level_ptr_t(b)^.level then
      n := nil
    else if (oi_level_ptr_t(n)^.level = oi_level_ptr_t(b)^.level) and
            (n^.kind <> entry_blk) then
      n := nil
    else if n^.kind = entry_blk then begin
      callee_status := 42;
      return;
    end
    else
      n := n^.xp[1];
  if language = 2 then begin
    v := b^.xp[4];
    while v <> nil do begin
      if rshft(ord(v^.xc[44]) & 16#F0, 4) = 7 then begin
        callee_status := 47;
        return;
      end;
      v := v^.xp[1];
    end;
  end
  else if language = 1 then begin
    v := b^.xp[4];
    while v <> nil do begin
      type_exp(v, addr(te));
      if te.base^.kind = file_type then begin
        callee_status := 44;
        return;
      end;
      if v^.kind = var_name then
        if v^.xp[7]^.kind = type_name then
          if v^.xp[7]^.xp[7]^.kind = record_type then
            if ord(v^.xp[7]^.xp[7]^.xc[34]) >= 128 then begin
              callee_status := 45;
              return;
            end;
      v := v^.xp[4];
    end;
    v := b^.xp[3];
    while v <> nil do begin
      type_exp(v, addr(te));
      if te.base^.kind = file_type then begin
        callee_status := 44;
        return;
      end;
      v := v^.xp[1];
    end;
  end;
  p := nil;
  if language <> 2 then
    p := b^.xp[3];
  for k := 1 to ord(b^.xc[293]) do begin
    if language = 2 then
      f := oi_ftab_ptr_t(b^.xp[3])^[k].sym
    else
      f := find_varn(b, p);
    if f^.kind = fortran_symbol then begin
      if rshft(ord(f^.xc[44]) & 16#F0, 4) = 1 then begin
        callee_status := 41;
        return;
      end;
      if cargs_$options.db = 2 then
        if (ord(f^.xc[10]) & 15) = 7 then
          if ord(f^.xc[10]) >= 128 then begin
            callee_status := 41;
            return;
          end;
    end
    else if f^.xp[7]^.kind = param_name then
      if (f^.xp[7]^.xp[4]^.kind = func__type)
          or (f^.xp[7]^.xp[4]^.kind = proc__type) then begin
        callee_status := 41;
        return;
      end;
    get_size_rlen(f, d);
    if d.rlen = rlen_null then begin
      callee_status := 36;
      return;
    end;
    if language <> 2 then
      p := p^.xp[1];
  end;
  callee_status := 36;
  if b^.blk_atts.resident_proc then
    return;
  v := function_return(b);
  if v <> nil then
    if v^.kind = fortran_symbol then
      if (ord(v^.xc[10]) & 15) = 7 then
        if ord(v^.xc[10]) >= 128 then
          return;
  if assert_routine_contains_symbolically_opaque_addressing(b) then
    return;
  callee_status := 63;
end;

{ anything_to_expand - whether the compilation has routines to expand:
  the IL's first node (il_d4) a label (144) followed by the call (148)
  of the main routine, whose language (+377 bits 6..4) is kept and
  must be 1..4, and inlining asked for (opt_on 24..26); then each
  block's callee_status kept (status): an expandable one marked +375
  bit 7, the others but 27 reported (cgerr, at the block's line +300)
  when forced (+375 bit 5, -FORCE_INLINE) and asked for (a statement
  function's opt_on 25, another's 24).

  0x093F76, 0xF0 bytes, link #-12: the language set by `btst' of 30;
  opt_on's elements by `andi.l #0x7FFFFFFE; lsr.l #1; andi.l
  #0x7000000' of cargs +0x280. }

function anything_to_expand: boolean; internal;
var
  any: boolean;
  s: il_$node_ptr_t;
  b: il_$node_ptr_t;
  report: boolean;
begin
  any := false;
  if il_d4 <> nil then
    if il_d4^.kind = label_node then
      if il_d4^.xp[2]^.kind = block_entry_node then begin
        b := il_d4^.xp[2]^.xp[12];
        language := b^.blk_atts.call;
        if language in [1..4] then
          if (cargs_$options.opt_on * [24..26]) <> [] then begin
            b := il_184;
            while b <> nil do begin
              status := callee_status(b);
              if status = 63 then begin
                b^.blk_atts.inlineable := true;
                any := true;
              end
              else if status <> 27 then
                if b^.blk_atts.inline or cargs_$options.force_inline then
                  if b^.xw[150] <> 0 then begin
                    if inline_$is_fortran_asf(b) then
                      report := 25 in cargs_$options.opt_on
                    else
                      report := false;
                    if not report then
                      report := 24 in cargs_$options.opt_on;
                    if report then
                      cgerr(status, b^.xw[150], b^.xp[74]);
                  end;
              b := b^.xp[1];
            end;
          end;
      end;
  anything_to_expand := any;
end;

{ inline_$inline_expand - runbackend's entry: the IL's block chain
  restarted (il_180 := il_184), the calls expanded when there is
  anything to expand, and the routines' flags settled: a routine
  block (105, 108, 107) without calls gets +379 bit 4 (a leaf) unless
  +379 bit 5, and +379 bit 3 cleared; with calls, each call's
  reference parameters are marked (inline_$mark_reference_params) and
  a call of itself sets +379 bit 3; the main program (105) is a leaf
  and not recursive; without target_properties' +0x10 every node gets
  +378 bit 4.  Then, until nothing changes, a routine all of whose
  callees are leaves (unless +379 bit 5), or all of whose callers are
  (unless +374 bit 3), becomes one; a 172 follows the routine before
  it.

  0x094066, 0x1A0 bytes, link #-24: loads A5; target_properties'
  address and il_184's loaded before the loops (patterns 5, 53); the
  last routine block kept in A0 for the 172s, unset before the first
  (pattern 84). }

procedure inline_$inline_expand;
var
  b: il_$node_ptr_t;
  ed: oi_edge_ptr_t;
  r: il_$node_ptr_t;
  all: boolean;
  done: boolean;
begin
  il_180 := il_184;
  if anything_to_expand then
    check_call_sites_and_expand;
  b := il_184;
  while b <> nil do begin
    ed := oi_edge_ptr_t(b^.xp[61]);
    if (b^.kind = program_blk) or (b^.kind = function_blk)
        or (b^.kind = procedure_blk) then begin
      if ed = nil then begin
        if not b^.blk_atts.calls_extern_non_lib_routine then
          b^.blk_atts.never_entered_recursively := true
        else
          b^.blk_atts.never_entered_recursively := false;
        b^.blk_atts.b379_3 := false;
      end
      else
        while ed <> nil do begin
          inline_$mark_reference_params(ed^.call, ed^.stmt);
          if ed^.callee = b then
            b^.blk_atts.b379_3 := true;
          ed := ed^.caller_next;
        end;
      if b^.kind = program_blk then begin
        b^.blk_atts.never_entered_recursively := true;
        b^.blk_atts.b379_3 := false;
      end;
    end;
    if target_properties.p_10 = 0 then
      b^.blk_atts.must_have_own_frame := true;
    b := b^.xp[1];
  end;
  repeat
    done := true;
    b := il_184;
    while b <> nil do begin
      if (b^.kind = program_blk) or (b^.kind = function_blk)
          or (b^.kind = procedure_blk) then begin
        if not b^.blk_atts.calls_extern_non_lib_routine then begin
          all := true;
          ed := oi_edge_ptr_t(b^.xp[61]);
          while ed <> nil do begin
            if all and (ed^.callee <> nil) then
              all := ed^.callee^.blk_atts.never_entered_recursively
            else
              all := false;
            ed := ed^.caller_next;
          end;
          if all and (not b^.blk_atts.never_entered_recursively) then begin
            b^.blk_atts.never_entered_recursively := true;
            done := false;
          end;
        end;
        if not b^.blk_atts.visible then begin
          all := true;
          ed := oi_edge_ptr_t(b^.xp[63]);
          while ed <> nil do begin
            all := all and ed^.caller^.blk_atts.never_entered_recursively;
            ed := ed^.callee_next;
          end;
          if all and (not b^.blk_atts.never_entered_recursively) then begin
            b^.blk_atts.never_entered_recursively := true;
            done := false;
          end;
        end;
        r := b;
      end;
      if b^.kind = inner_blk then
        if r^.blk_atts.never_entered_recursively then
          b^.blk_atts.never_entered_recursively := true;
      b := b^.xp[1];
    end;
  until done;
end;
