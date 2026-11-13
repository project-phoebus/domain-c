{ reg_cost_68k - the register allocator's weights: for each live range
  the uses and assignments of its value in each basic block it spans,
  weighed by the square of the block's loop depth less the loads and
  stores the range would cost at its edges, the cost per statement
  spanned (priority), the class of register the range may have
  (address, data or floating) and the ranges that get none.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0C5C5C  --------  reg_cost_$compute_max_loop_depth
    0x0C5CC8  --------  reg_cost_$wasteful_param_load
    0x0C5D4A  --------  compute_costs
    A5 0x2D2580 (cc.m68k): the module's data, 16 bytes (no .rwdi
    record): +0 the loads and stores counted for the range being
    weighed, +4 the range and +8 its number (set and not read).

  compute_max_loop_depth and wasteful_param_load do not load A5 and are
  internal; compute_costs is global (reg_alloc.ins.pas).

  The ranges are reg_alloc.ins.pas's reg_range_t; the statements,
  blocks, variables and cses are read through g_opt.ins.pas's views,
  the variables (109, 110) and other nodes by offset (il.ins.pas).
  The class of a parameter (110) is the nibble +11.7..4, of a
  variable (109) the word +72; a value's size class the nibble
  +10.3..0 (1..3 integers, 4 and 5 reals).

  Not known from the original: the names of the module's variables, the
  locals and the parameters.

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the node kind sets).
}
module reg_cost_68k;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/reg_alloc.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';

var
  loads: integer32;                     { +0 }
  cur_range: reg_range_ptr_t;           { +4 }
  cur_num: integer;                     { +8 }

define
  compute_costs;

{ reg_cost_$compute_max_loop_depth - r's depth: the deepest loop of a
  statement that variable v's value reaches from r's first statement
  (v's def-use chain there).

  0x0C5C5C, 0x6C bytes, link #-12: the first statement's number (+18)
  zero-extended, the chain's statements' blocks' depths sign-extended
  and compared with the range's (`cmp.l; bge'), the larger stored each
  time. }

procedure reg_cost_$compute_max_loop_depth(
    r: reg_range_ptr_t;
    v: integer); options(val_param); internal;
var
  c: g_opt_chain_ptr_t;
  d: integer32;
begin
  if opt_4009c[r^.first]^.vars^[v] <> nil then begin
    c := opt_4009c[r^.first]^.vars^[v]^.du;
    while c <> nil do begin
      d := c^.stmt^.block^.depth;
      if d < r^.depth then
        d := r^.depth;
      r^.depth := d;
      c := c^.next;
    end;
  end;
end;

{ reg_cost_$wasteful_param_load - whether r is a parameter or variable
  outside every loop, assigned at most once, whose register would be
  loaded for one use (or up to four when il_180's +379 bit 3 is set),
  when its +34 (a variable) or +26 (a parameter) bit 10 is set.

  0x0C5CC8, 0x82 bytes, link #-8: the two kind tests evaluated whole
  (`seq; seq; or.b; bpl', docs/rev889-patterns.md 29); the result in
  D0. }

function reg_cost_$wasteful_param_load(
    r: reg_range_ptr_t): boolean; options(val_param); internal;
var
  t: il_$node_ptr_t;
begin
  reg_cost_$wasteful_param_load := false;
  if r^.depth <= 0 then
    if r^.defs <= 1 then
      if r^.node <> nil then begin
        t := r^.node;
        if (t^.kind = fortran_symbol) or (t^.kind = var_name) then
          if (t^.kind <> var_name) or ((t^.xw[17] & 16#400) <> 0) then
            if (t^.kind <> fortran_symbol) or ((t^.xw[13] & 16#400) <> 0) then
              if r^.uses <= 1 then
                reg_cost_$wasteful_param_load := true
              else if r^.uses <= 4 then
                if il_180^.blk_atts.b379_3 then
                  reg_cost_$wasteful_param_load := true;
      end;
end;

{ compute_costs - weigh the n ranges r^[1..n].

  For each range: its variable's number v (find_var); whether a
  statement of the range other than a call (188) assigns the variable
  (assigned: not for a variable of class 2 or 5, or 1 in a routine
  block of kind 105; parameters of class 0, 2, or 1 likewise); then
  over each block it spans (or its statements as a whole when it has
  no blocks), unless the block neither uses v before assigning it nor
  assigns it: at each statement s whose points 2s and 2s + 1 the range
  covers, the uses of v there (a branch (142) that does not use it
  counts 2), the assignments, the loads and stores at the range's
  edges (loads), the class of register (a function's result prefers
  D0, or A0 for a pointer returned in C), a cse parent's uses and
  assignment, a constant's uses counted by the block's constants;
  the block's cost (6 uses + 4 assignments - 4 loads) times the square
  of its loop depth + 1.  Then the ranges that get no register
  (flags element 0: a variable only calls use outside C, a parameter
  with +24 bit 21, wasteful_param_load, a floating value cheaper than
  10 assigned once and used at most twice, no cost), the strength
  reduction temporaries' class, the priority (cost times the
  routine's statements, divided by the statements spanned + 1) and
  the classes of cse parents and constants (Fortran's constants
  (145..147) under opt_on 18 in a data or floating register when
  their variable allows it, else an address register).

  0x0C5D4A, 0xF3C bytes, link #-100: the ranges indexed from 1 by a
  64-byte stride (fp@(-92)); v kept twice (fp@(-34), fp@(-36), written
  once here); has_skip (fp@(-60)) any block from opt_first_block to
  opt_last_block marked skip; the first pass of the block loop enters
  in its middle when the range has no blocks (`tst.l; bne' to the
  head, which the loop's end jumps to directly); a function's result
  of C and the others share the tail that clears the variable's
  read flag (docs/rev889-patterns.md 23); the products by M$MIS$LLL,
  the priority by M$DIS$LLL of the statements spanned + 1 made
  positive (`bpl; neg.l'). }

procedure compute_costs(
    r: reg_ranges_ptr_t;
    n: integer);
var
  bn: reg_num_t;
  has_skip: boolean;
  k: integer;
  rr: reg_range_ptr_t;
  v: integer;
  b: reg_blk_ptr_t;
  len: reg_num_t;
  only_calls: boolean;
  assigned: boolean;
  s1: reg_num_t;
  s2: reg_num_t;
  s: reg_num_t;
  depth: integer32;
  uses: integer32;
  defs: integer32;
  st: g_opt_stmt_ptr_t;
  x: g_opt_stmt_ptr_t;
  touched: boolean;
  scan: boolean;
  c: g_opt_const_ptr_t;
  u: g_opt_cse_ptr_t;
  nb: g_opt_block_ptr_t;
  j: integer;
  t: il_$node_ptr_t;
  t2: il_$node_ptr_t;
  t3: il_$node_ptr_t;
  cls: integer;
  lang: integer;
begin
  has_skip := false;
  for bn := opt_first_block to opt_last_block do
    if g_opt_blocks_ptr_t(il_11c)^[bn]^.flags.skip then begin
      has_skip := true;
      exit;
    end;
  for k := 1 to n do begin
    rr := addr(r^[k]);
    cur_range := rr;
    cur_num := k;
    v := find_var(rr^.node);
    b := rr^.blocks;
    len := 0;
    t := rr^.node;
    only_calls := not (t^.kind in [real_ob..dpreal_ob, dindex_node..disp_node,
                                   addr_con, cse_parent_ob,
                                   reloc_absolute_addr_con]);
    if il_utils_$is_strength_reduction_temp(t) then
      only_calls := false;
    assigned := false;
    if t^.kind = var_name then begin
      cls := ord(t^.vr_vat);
      if (cls = 2) or ((cls = 1) and (il_180^.kind = program_blk))
          or (cls = 5) then
        assigned := false
      else
        for s := rr^.first to rr^.last do
          if (opt_4009c[s]^.hdr.vnum = v)
              and (opt_4009c[s]^.kind <> use_def_ob) then begin
            assigned := true;
            exit;
          end;
    end
    else if t^.kind = fortran_symbol then begin
      cls := rshft(ord(t^.xc[11]) & 16#F0, 4);
      if (cls in [0, 2]) or ((cls = 1) and (il_180^.kind = program_blk)) then
        assigned := false
      else
        for s := rr^.first to rr^.last do
          if (opt_4009c[s]^.hdr.vnum = v)
              and (opt_4009c[s]^.kind <> use_def_ob) then begin
            assigned := true;
            exit;
          end;
    end;

    if b = nil then begin
      s1 := rr^.first;
      s2 := rr^.last;
      depth := opt_4009c[s1]^.block^.depth;
    end;
    repeat
      if b <> nil then begin
        nb := g_opt_blocks_ptr_t(il_11c)^[b^.bnum];
        s1 := nb^.first_stmt^.hdr.region;
        s2 := nb^.last_stmt^.hdr.region;
        depth := opt_4009c[s1]^.block^.depth;
        bn := b^.bnum;
        if s2 = 0 then begin
          x := g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.last_stmt;
          while x^.hdr.region = 0 do
            x := x^.next;
          s2 := x^.hdr.region;
        end;
        if (s1 = 0) and (bn <> 1) then begin
          x := g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.first_stmt;
          while x^.hdr.region = 0 do
            x := x^.prev;
          s1 := x^.hdr.region;
        end;
      end;
      len := len + (s2 - s1) + 1;
      uses := 0;
      defs := 0;
      loads := 0;
      scan := true;
      if b <> nil then
        if v <> 0 then
          if not (v in opt_used^[bn]) then
            if v in opt_not_killed^[bn] then
              scan := false;
      if scan then
        if s1 <= s2 then
          for s := s1 to s2 do begin
            touched := false;
            st := opt_4009c[s];
            if st^.block^.flags.latch then
              if (rr^.node^.kind = fortran_symbol)
                  or (rr^.node^.kind = var_name) then
                if il_utils_$is_strength_reduction_temp(rr^.node) then
                  if (st^.kind = assign_node) and (st^.asg_op = scalar_aop) and
                     (st^.asg_rlen = rlen_addr) and (st^.asg_lhs = rr^.node) then
                    rr^.flags := rr^.flags + [2];
            if not test_stmt(rr, 2 * s) then
              if not test_stmt(rr, 2 * s + 1) then
                len := len - 1;

            { The uses of v at s. }
            if st^.vset <> nil then
              if v in st^.vset^ then
                if test_stmt(rr, 2 * s) then begin
                  rr^.uses := rr^.uses + st^.vars^[v]^.count;
                  uses := uses + st^.vars^[v]^.count;
                  if not st^.hdr.ends_basic_block then
                    if not test_stmt(rr, 2 * s + 1) then
                      if assigned then
                        loads := loads + 1;
                  if (st^.vars^[v]^.count = 0)
                      and (st^.kind = cbranch_node) then begin
                    rr^.uses := rr^.uses + 2;
                    uses := uses + 2;
                  end;
                  if st^.kind <> use_def_ob then
                    only_calls := false;
                  touched := true;
                end;

            { Its assignment at s. }
            if v <> 0 then
              if st^.hdr.vnum = v then
                if test_stmt(rr, 2 * s + 1) then begin
                  rr^.defs := rr^.defs + 1;
                  defs := defs + 1;
                  if not test_stmt(rr, 2 * s) and (st^.vars^[v]^.du <> nil) and
                     (((st^.vset <> nil) and (v in st^.vset^)) or
                      (st^.kind = use_def_ob)) then
                    loads := loads + 1
                  else if (st^.kind = use_def_ob)
                      and (st^.vars^[v]^.du <> nil) then
                    if test_stmt(rr, 2 * s) then
                      loads := loads + 1;
                  if st^.kind <> use_def_ob then
                    rr^.flags := rr^.flags + [8];
                  touched := true;
                end;

            { The class of register. }
            if touched then begin
              if il_180^.kind = function_blk then
                if rr^.node = il_180^.xp[24] then begin
                  lang := il_180^.blk_atts.call;
                  if lang = 3 then begin
                    x := opt_4009c[opt_region];
                    x^.vars^[v]^.flags := x^.vars^[v]^.flags & ~1;
                    rr^.flags := rr^.flags + [3];
                    rr^.prefer := rr^.prefer + [0];
                  end
                  else if opt_4009c[runbackend_16 - 1]^.kind = return_node then begin
                    if opt_4009c[runbackend_16 - 1]^.asg_rlen = rlen_addr then begin
                      rr^.flags := rr^.flags + [2];
                      rr^.prefer := rr^.prefer + [8];
                    end
                    else begin
                      x := opt_4009c[opt_region];
                      x^.vars^[v]^.flags := x^.vars^[v]^.flags & ~1;
                      rr^.flags := rr^.flags + [3];
                      rr^.prefer := rr^.prefer + [0];
                    end;
                  end;
                end;
              if ((st^.vars^[v]^.flags & 1) <> 0) or
                 ((opt_4009c[opt_region]^.vars^[v]^.flags & 1) <> 0) then
                rr^.flags := rr^.flags + [2]
              else if rr^.node^.kind = var_name then begin
                if (v <> 0) and (opt_var_types^[v].base <> nil) then begin
                  if opt_var_types^[v].base^.kind = real_type then
                    rr^.flags := rr^.flags + [4]
                  else if opt_var_types^[v].base^.kind = ptr_type then
                    rr^.flags := rr^.flags + [2]
                  else
                    rr^.flags := rr^.flags + [3];
                end
                else
                  rr^.flags := rr^.flags + [3];
              end
              else if rr^.node^.kind = fortran_symbol then begin
                if rshft(ord(rr^.node^.xc[11]) & 16#F0, 4) = 5 then
                  rr^.flags := rr^.flags + [2]
                else if (ord(rr^.node^.xc[10]) & 15) in [4, 5] then begin
                  if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
                    rr^.flags := rr^.flags + [4]
                  else
                    rr^.flags := rr^.flags + [0];
                end
                else
                  rr^.flags := rr^.flags + [3];
              end;
              if (st^.vars^[v]^.flags & 8) <> 0 then
                rr^.flags := rr^.flags + [0]
              else if 2 in rr^.flags then
                if rr^.flags * [3, 4] <> [] then
                  if v <> 0 then
                    if opt_var_types^[v].base <> nil then
                      if opt_var_types^[v].base^.kind = ptr_type then
                        rr^.flags := rr^.flags - [3, 4];
            end;

            { A cse parent's uses and its assignment at s. }
            if rr^.node^.kind = cse_parent_ob then begin
              u := g_opt_cse_ptr_t(rr^.node)^.p_uses;
              while u <> nil do begin
                if u^.u_ent^.hdr.region = s then begin
                  rr^.uses := rr^.uses + 1;
                  uses := uses + 1;
                end;
                u := u^.u_next;
              end;
              if g_opt_cse_ptr_t(rr^.node)^.p_stmt^.hdr.region = s then begin
                defs := 1;
                loads := loads + 1;
                rr^.defs := 1;
              end;
            end;

            { A constant's uses: its count among the block's constants. }
            if uses = 0 then
              if (rr^.node^.kind in [real_ob..dpreal_ob,
                                     dindex_node..disp_node, addr_con,
                                     reloc_absolute_addr_con]) or
                 ((v = 0) and ((rr^.node^.kind = fortran_symbol) or
                               (rr^.node^.kind = var_name))) then begin
                rr^.defs := 1;
                c := st^.block^.consts;
                if c <> nil then begin
                  while c <> nil do begin
                    t2 := c^.node;
                    if t2 = rr^.node then
                      exit;
                    if t2^.kind in [tree_node..gen_tree_node, cmp_tree_node,
                                    dindex_node..disp_node, cs_node, cc_call,
                                    pf_call,
                                    cse_use_ob, sym_disp_node] then
                      if phase_cse in g_opt_tree_ptr_t(t2)^.flags then
                        if g_opt_nodes_ptr_t(il_120)^[g_opt_tree_ptr_t(t2)^.stmt] =
                           rr^.node then
                          exit;
                    c := c^.next;
                  end;
                  if c <> nil then begin
                    uses := c^.count;
                    rr^.uses := rr^.uses + c^.count;
                    if st^.block^.flags.latch then
                      defs := defs + 1
                    else if (rr^.node^.kind = fortran_symbol)
                        or (rr^.node^.kind = var_name) then begin
                      x := g_opt_blocks_ptr_t(il_11c)^[bn]^.first_stmt;
                      repeat
                        if (x^.kind = assign_node)
                            and (x^.asg_lhs = rr^.node) then
                          defs := defs + 1;
                        if g_opt_blocks_ptr_t(il_11c)^[bn]^.last_stmt = x then
                          exit;
                        x := x^.next;
                      until x = nil;
                    end;
                  end;
                end;
              end;
          end;

      depth := depth + 1;
      if b <> nil then begin
        { A load at each successor the range does not reach. }
        if v <> 0 then
          if assigned or (8 in rr^.flags) then begin
            nb := g_opt_blocks_ptr_t(il_11c)^[bn];
            if test_stmt(rr, 2 * nb^.last_stmt^.hdr.region) then
              if nb^.nsucc <> 0 then
                for j := 1 to nb^.nsucc do
                  if not test_stmt(rr, 2 * nb^.succ^[j]^.first_stmt^.hdr.region) then
                    loads := loads + 1;
          end;
        depth := depth * depth;
        b^.cost := (uses * 6 + defs * 4 - loads * 4) * depth;
        rr^.cost := rr^.cost + b^.cost;
        b := b^.next;
      end
      else if rr^.blocks = nil then begin
        depth := depth * depth;
        rr^.cost := (uses * 6 + defs * 4 - loads * 4) * depth;
      end;
    until b = nil;

    { The ranges that get no register. }
    if v <> 0 then
      reg_cost_$compute_max_loop_depth(rr, v);
    if v <> 0 then
      if only_calls then
        if il_180^.blk_atts.call <> call_c then
          rr^.flags := rr^.flags + [0];
    if rr^.node^.kind = fortran_symbol then
      if var_$nooptimize in rr^.node^.fs_attr then
        rr^.flags := rr^.flags + [0];
    if v <> 0 then
      if reg_cost_$wasteful_param_load(rr) then
        rr^.flags := rr^.flags + [0];
    if (rr^.node^.kind = fortran_symbol) or (rr^.node^.kind = var_name) then
      if (v <> 0) and (4 in rr^.flags) and (rr^.cost < 10) and
         (rr^.defs = 1) and (rr^.uses <= 2) then
        rr^.flags := rr^.flags + [0];
    if 0 in rr^.flags then begin
      rr^.node := nil;
      rr^.blocks := nil;
    end
    else begin
      { A strength reduction temporary's class. }
      if il_utils_$is_strength_reduction_temp(rr^.node) then
        if not (2 in rr^.flags) then
          if rr^.node^.kind = var_name then
            rr^.flags := [3]
          else begin
            cls := ord(rr^.node^.xc[10]) & 15;
            if cls in [1, 2, 3] then
              rr^.flags := [3]
            else if cls in [4, 5] then
              if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
                rr^.flags := [4]
              else
                rr^.flags := rr^.flags + [0];
          end;

      rr^.priority := ((runbackend_16 - opt_region + 1) * rr^.cost) div
                      abs(len + 1);

      { A cse parent's class: its tree's register class. }
      if rr^.node^.kind = cse_parent_ob then begin
        t2 := g_opt_cse_ptr_t(rr^.node)^.p_tree;
        if (t2^.kind = tree_node) or (t2^.kind = cmp_tree_node) then begin
          cls := g_opt_tree_ptr_t(t2)^.rlen;
          if (cls = 6) or (cls = 8) or (cls = 7) then begin
            if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
              rr^.flags := rr^.flags + [4]
            else
              rr^.flags := rr^.flags + [0];
          end
          else if cls = 5 then
            rr^.flags := rr^.flags + [2]
          else
            rr^.flags := rr^.flags + [3];
        end
        else
          rr^.flags := rr^.flags + [0];
      end;

      { The constants' classes. }
      if (rr^.node^.kind = reloc_absolute_addr_con)
          or (rr^.node^.kind = addr_con) then
        rr^.flags := rr^.flags + [2];
      if (rr^.node^.kind = dpreal_ob) or (rr^.node^.kind = real_ob) then
        if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
          rr^.flags := rr^.flags + [4]
        else
          rr^.flags := rr^.flags + [0];
      if (rr^.node^.kind = dindex_node) or (rr^.node^.kind = disp_node) or
         (rr^.node^.kind = ptr_node) then begin
        lang := il_180^.blk_atts.call;
        if has_skip or not (18 in cargs_$options.opt_on) or (lang <> 2) or
           (rr^.node^.kind = dindex_node) then
          rr^.flags := rr^.flags + [2]
        else begin
          t := rr^.node;
          t2 := t^.xp[7];
          if (t2 <> nil) and (t2^.kind = fortran_symbol) and (t^.xp[6] <> nil)
              and
             ((t^.xp[6]^.kind = ptr_node)
              or (t^.xp[6]^.kind = reloc_absolute_addr_con) or
              (t^.xp[6]^.kind = addr_con)) and
             (rshft(ord(t2^.xc[44]) & 16#F0, 4) = 3) and
             (t2^.xl[7] = 0) and (t2^.xl[8] = 0) and (t2^.xl2[14] <> 0) and
             ((ord(t2^.xc[10]) & 15) in [1..5]) then begin
            cls := ord(t2^.xc[10]) & 15;
            if (t^.xp[6]^.kind = ptr_node) and
               ((t^.xp[6]^.xp[6]^.kind = cse_parent_ob) or
                (t^.xp[6]^.xp[6]^.kind = tree_node)) then
              rr^.flags := rr^.flags + [2]
            else if (cls in [1, 2, 3]) and
                    not opt_4009c[rr^.first]^.hdr.loophascalls then
              rr^.flags := rr^.flags + [3]
            else if (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and
                    not opt_4009c[rr^.first]^.hdr.loophascalls then
              rr^.flags := rr^.flags + [4]
            else
              rr^.flags := rr^.flags + [2];
          end
          else if (t^.kind = ptr_node) and (t2^.kind = common_block_name) and
                  (t2^.xp[3]^.xl[8] = 0) and (t2^.xp[3]^.xl[7] = 0) and
                  not opt_4009c[rr^.first]^.hdr.loophascalls then begin
            t3 := t2^.xp[3];
            if (t^.xp[6]^.kind = cse_parent_ob)
                or (t^.xp[6]^.kind = tree_node) then
              rr^.flags := rr^.flags + [2]
            else if (t3^.kind = fortran_symbol) and
                    ((ord(t3^.xc[10]) & 15) in [1, 2, 3]) then
              rr^.flags := rr^.flags + [3]
            else if (t3^.kind = fortran_symbol) and
                    ((ord(t3^.xc[10]) & 15) in [4, 5]) and
                    (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) then
              rr^.flags := rr^.flags + [4]
            else
              rr^.flags := rr^.flags + [2];
          end
          else
            rr^.flags := rr^.flags + [2];
        end;
      end;
      { No register for a variable of no cost. }
      if (rr^.node^.kind = fortran_symbol) or (rr^.node^.kind = var_name) then
        if (rr^.priority = 0) and (rr^.cost = 0) then
          rr^.flags := rr^.flags + [0];
    end;
  end;
end;
