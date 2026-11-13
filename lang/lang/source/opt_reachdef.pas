{ opt_reachdef - reaching definitions: for each region statement that
  assigns a variable (its vnum), a bit in sets of the statements by
  region number (rd sets: longwords of `set of 0..31', bit k - opt_region
  + 1); per basic block the definitions it generates and kills
  (genkill), those reaching its top (compute_rd, iterated over the
  depth-first order until nothing changes), then, block by block, the
  constants the variables are known to hold propagated into their uses
  (evalforeffect, propagate: a use of a variable whose only reaching
  definition stores a constant becomes the constant, folded by kfold),
  each statement's set of the variables it uses (markuses), the use-def
  chains of each statement's variables (build_ud_chains, make_ud_chain)
  and the warning (cgerr 21) for a variable used before it is assigned;
  -DUMP68 RD prints the sets (dumprd).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0E18E0  0x2AEAD0  stmt_index_from_rdset
    0x0E1908  0x2AEAF8  basic_block_of_def
    0x0E193E  0x2AEB2E  assert_def_dominates_use
    0x0E1980  0x2AEB70  assert_uninitialized_value_can_reach
    0x0E1A98  0x2AEC88  assert_nonempty_var_use_set
    0x0E1AB6  0x2AECA6  assert_this_definition_on_ud_chain
    0x0E1AF4  0x2AECE4  pt
    0x0E1B26  0x2AED16  dbs
    0x0E1BF0  0x2AEDE0  dumprdset
    0x0E1CC8  0x2AEEB8  dumprd
    0x0E1DDC  0x2AEFCC  adjust_ptr
    0x0E1E16  0x2AF006  zero_longwords
    0x0E1E2A  0x2AF01A  zero_bytes
    0x0E1E80  0x2AF070  bset
    0x0E1EC8  0x2AF0B8  bclr
    0x0E1F12  0x2AF102  releaserd
    0x0E1F66  0x2AF156  alloc_rdset (in initrd)
    0x0E2020  0x2AF210  initrd
    0x0E21E0  0x2AF3D0  add_def_stmt
    0x0E22A4  0x2AF494  genkill
    0x0E235C  0x2AF54C  paramclass
    0x0E24D4  0x2AF6C4  compute_rd
    0x0E26E6  0x2AF8D6  make_ud_chain
    0x0E2868  0x2AFA58  make_motioned_ud_chain
    0x0E28B0  0x2AFAA0  build_ud_chains
    0x0E2A82  0x2AFC72  walk_tree (in markuses)
    0x0E2E94  0x2B0084  markuses
    0x0E308E  0x2B027E  propagate (in evalforeffect)
    0x0E328C  0x2B047C  evalforeffect
    0x0E40CE  0x2B12BE  assert_no_predecessors
    0x0E40E4  0x2B12D4  assert_predecessor_is_me
    0x0E4102  0x2B12F2  assert_block_is_entrypoint
    0x0E4120  0x2B1310  assert_is_dominated_by_some_entrypoint
    0x0E4158  0x2B1348  statement_contained_by_unreachable_basic_block
    0x0E4250  0x2B1440  ftn_data_init (in reachingdefinitions)
    0x0E4316  0x2B1506  init_block (in reachingdefinitions)
    0x0E462C  0x2B181C  reachingdefinitions
    A5 0x352F8C (cc.m68k), 0x513938 (cc.a88k): the module's data, 328
    bytes: +0 the dump's line (a length and 256 characters; +258
    unused), +260.. the tables by variable number and by block
    (pointers into opt_main's +0x14 pool), +316.. the sets'
    sizes, the statement at hand (+322), the region's variables
    (+324) and markuses' flag (+326).  No other unit reads them.

  adjust_ptr, releaserd, initrd, paramclass, make_motioned_ud_chain,
  markuses and reachingdefinitions load A5 (g_opt.ins.pas: opt_main,
  opt_loop, cg_call and opt_strength call them); the other routines do
  not and are internal (stmt_index_from_rdset .. assert_this_definition_
  on_ud_chain, the dump's, the set helpers, add_def_stmt, genkill,
  compute_rd, make_ud_chain, build_ud_chains, evalforeffect and the
  asserts run on the caller's A5; zero_longwords, assert_nonempty_var_
  use_set and the three block asserts are leaf routines without a frame,
  docs/rev889-patterns.md 16).  walk_tree and propagate take their
  parent's frame from the dynamic link, ftn_data_init in A1 (called by
  reachingdefinitions and by init_block).

  Region statements are read through g_opt.ins.pas's g_opt_stmt_t, trees
  through g_opt_tree_t, the other nodes by offset (il.ins.pas).  kfold
  is declared here (opt_general's heading, docs/questions.md 88).

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the node kind sets), 12
  (basic_block_of_def's result compared), 24 (paramclass and
  alias_$related_call as right operands of `and', `or'), 25
  (evalforeffect: a call's operands left out of the check).

  Not known from the original: every name but the routines'.
}
module opt_reachdef;

%include '/sys/ins/base.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';

{ KFOLD - kfold.pas 0x0AF444 (cc.a88k 0x0B0E24): fold the constants of
  tree t, a tree of statement stmt (opt_general's heading). }
procedure kfold(
    in stmt: il_$node_ptr_t;
    var t: il_$node_ptr_t); extern;

type
  { The dump's line: a length word and 256 characters, 258 bytes (the
    image's tables begin 260 bytes on, at +260; a varying [256] of char
    takes 262, language reference 3.11.4.1).  Passed to PRTSUB's
    routines and listln as univ.  docs/questions.md 279. }
  rd_line_t = record
    length: integer;
    body: prtsub_$chars_t;
  end;

  { An rd set: bit b of longword w stands for the statement of region
    number opt_region - 1 + b + 32 * (w - 1) (bset, bclr,
    stmt_index_from_rdset); rd_words longwords allocated, rd_used of
    them used. }
  rd_set_t = array [1..2047] of set of 0..31;
  rd_set_ptr_t = ^rd_set_t;
  { A table of rd sets by block number (alloc_rdset's, from 1; moved
    by adjust_ptr to be indexed from opt_first_block). }
  rd_sets_t = array [1..16383] of rd_set_ptr_t;
  rd_sets_ptr_t = ^rd_sets_t;
  { Tables by variable number, from 0. }
  rd_varsets_t = array [0..255] of rd_set_ptr_t;
  rd_varsets_ptr_t = ^rd_varsets_t;
  rd_flags_t = array [0..255] of boolean;
  rd_flags_ptr_t = ^rd_flags_t;
  rd_nodes_t = array [0..255] of il_$node_ptr_t;
  rd_nodes_ptr_t = ^rd_nodes_t;
  { A variable's definitions in the block at hand (add_def_stmt; 6
    bytes from mem_$alloc): stmt 0 ends the list. }
  rd_def_ptr_t = ^rd_def_t;
  rd_def_t = record
    stmt: g_opt_num_t;                  { +0 }
    next: rd_def_ptr_t;                 { +2 }
  end;
  rd_defs_t = array [0..255] of rd_def_ptr_t;
  rd_defs_ptr_t = ^rd_defs_t;
  { build_ud_chains' records by variable (4 bytes). }
  rd_mark_t = record
    stmt: g_opt_num_t;                  { +0 }
    set_: boolean;                      { +2 }
    unused_3: char;                     { +3 }
  end;
  rd_marks_t = array [0..255] of rd_mark_t;
  rd_marks_ptr_t = ^rd_marks_t;
  { Raw memory (zero_longwords, zero_bytes). }
  rd_longs_ptr_t = ^integer32;
  rd_bytes_ptr_t = ^char;

var
  line: rd_line_t;                      { +0: the dump's line }
  unused_258: integer;                  { +258 }
  assigned: rd_flags_ptr_t;             { +260: the variables some block
                                          assigns (reachingdefinitions) }
  last_use: rd_marks_ptr_t;             { +264: build_ud_chains: the last
                                          statement of the block whose
                                          chain of the variable was built }
  last_def: rd_marks_ptr_t;             { +268: the last statement of
                                          the block assigning it }
  value: rd_nodes_ptr_t;                { +272: the constant (or tree) a
                                          variable is known to hold, nil
                                          when none }
  seen: rd_flags_ptr_t;                 { +276: the variable's value at
                                          this point is decided (value
                                          says which) }
  var_defs: rd_varsets_ptr_t;           { +280: by variable, the
                                          statements assigning it; [0]
                                          all the assignments }
  in_base: rd_sets_ptr_t;               { +284 }
  rd_in: rd_sets_ptr_t;                 { +288: by block, the definitions
                                          reaching its top }
  rd_tmp: rd_set_ptr_t;                 { +292: compute_rd's union }
  kill_base: rd_sets_ptr_t;             { +296 }
  rd_kill: rd_sets_ptr_t;               { +300: by block, the definitions
                                          it kills }
  gen_base: rd_sets_ptr_t;              { +304 }
  rd_gen: rd_sets_ptr_t;                { +308: by block, those it
                                          generates }
  defs: rd_defs_ptr_t;                  { +312: by variable, its
                                          definitions in the block }
  rd_words: integer;                    { +316: longwords allocated to
                                          an rd set }
  nvars2: integer;                      { +318 }
  rd_used: integer;                     { +320: longwords used }
  cur: g_opt_num_t;                     { +322: the statement at hand,
                                          its region number }
  nvars: integer;                       { +324: the routine's variables
                                          (il_180's +290) }
  on_lhs: boolean;                      { +326: walk_tree is walking an
                                          assignment's left side }

define
  adjust_ptr, releaserd, initrd, paramclass, make_motioned_ud_chain,
  markuses, reachingdefinitions;

{ stmt_index_from_rdset - the region number of bit b of longword w of an
  rd set.

  0x0E18E0, 0x28 bytes: word arithmetic; the result in D0. }

function stmt_index_from_rdset(
    b: integer;
    w: integer): integer; options(val_param); internal;
begin
  stmt_index_from_rdset := b + (opt_region - 1) + (w - 1) * 32;
end;

{ basic_block_of_def - the block of variable v's first definition in
  the block at hand.

  0x0E1908, 0x36 bytes: the result in A0. }

function basic_block_of_def(
    v: integer): g_opt_block_ptr_t; options(val_param); internal;
begin
  basic_block_of_def := opt_4009c[defs^[v]^.stmt]^.block;
end;

{ assert_def_dominates_use - variable v's definition in the block at
  hand dominates block b (false for no variable).

  0x0E193E, 0x42 bytes: dom's D0 left as the result. }

function assert_def_dominates_use(
    v: integer;
    b: integer): boolean; options(val_param); internal;
begin
  if v = 0 then
    assert_def_dominates_use := false
  else
    assert_def_dominates_use :=
      dom(basic_block_of_def(v), g_opt_blocks_ptr_t(il_11c)^[b]);
end;

{ assert_uninitialized_value_can_reach - a use of variable v in block b
  can see another value than its definition in the block at hand: the
  definition is in another block that does not dominate b, and every
  definition of v reaching b's top (but opt_region's) is it.

  0x0E1980, 0x118 bytes: the result in a frame byte (-16), true after
  the loops; the definitions' region numbers compared unsigned with
  opt_region and runbackend_16; `bit in' range-checked (`moveq #31;
  cmp.w; bcs'). }

function assert_uninitialized_value_can_reach(
    v: integer;
    b: integer): boolean; options(val_param); internal;
label
  done;
var
  r: boolean;
  w, bit, k: integer;
  s: g_opt_stmt_ptr_t;
begin
  r := false;
  if v <> 0 then
    if basic_block_of_def(v) <> g_opt_blocks_ptr_t(il_11c)^[b] then
      if not assert_def_dominates_use(v, b) then begin
        for w := 1 to rd_used do begin
          if rd_in^[b]^[w] <> [] then
            for bit := 0 to 31 do
              if bit in rd_in^[b]^[w] then begin
                k := stmt_index_from_rdset(bit, w);
                if k <> opt_region then
                  if k <= runbackend_16 then begin
                    s := opt_4009c[k];
                    if s^.hdr.vnum = v then
                      if s^.hdr.region <> defs^[v]^.stmt then
                        goto done;
                  end;
              end;
        end;
        r := true;
      end;
done:
  assert_uninitialized_value_can_reach := r;
end;

{ assert_nonempty_var_use_set - s is a set holding some variable.

  0x0E1A98, 0x1E bytes, no frame: the eight longwords tested in turn
  (`tst.l (A1)+; dbne'). }

function assert_nonempty_var_use_set(
    s: g_opt_varset_ptr_t): boolean; options(val_param); internal;
begin
  if s = nil then
    assert_nonempty_var_use_set := false
  else
    assert_nonempty_var_use_set := s^ <> [];
end;

{ assert_this_definition_on_ud_chain - statement r is on chain c.

  0x0E1AB6, 0x3E bytes: the whole chain walked; region numbers read as
  the word at +43. }

function assert_this_definition_on_ud_chain(
    c: g_opt_chain_ptr_t;
    r: integer): boolean; options(val_param); internal;
var
  found: boolean;
begin
  found := false;
  while c <> nil do begin
    if c^.stmt <> nil then
      if c^.stmt^.hdr.region = r then
        found := true;
    c := c^.next;
  end;
  assert_this_definition_on_ud_chain := found;
end;

{ pt - n characters of s to the dump's line, the line printed and
  emptied.

  0x0E1AF4, 0x32 bytes; '' is passed as the address of a routine after
  the call (docs/rev889-patterns.md 31). }

procedure pt(
    in s: univ prtsub_$chars_t;
    n: integer); options(val_param); internal;
begin
  prtcats(line, s, n);
  listln(line);
  line.length := 0;
end;

{ dbs - the region numbers of rd set s, between braces and separated
  by commas, a new line (at column 10) after 100 characters.

  0x0E1B26, 0xC6 bytes: the bits tested without a range check; the
  number computed as a longword; prtint's width and zero_fill pushed as
  one longword (#0x50000). }

procedure dbs(
    s: rd_set_ptr_t); options(val_param); internal;
var
  w, bit: integer;
begin
  prtcatc(line, '{');
  for w := 1 to rd_used do
    for bit := 0 to 31 do begin
      if bit in s^[w] then begin
        prtint(line, bit + (w - 1) * 32 + opt_region - 1, 5, false);
        prtcatc(line, ',');
      end;
      if line.length > 100 then begin
        pt('', 0);
        prttab(line, 10);
      end;
    end;
  pt('}', 1);
end;

{ dumprdset - the title and the rd set of each block.

  0x0E1BF0, 0xD4 bytes: the title printed without pt (prtcats, listln,
  the length cleared). }

procedure dumprdset(
    sets: rd_sets_ptr_t;
    in title: univ prtsub_$chars_t;
    n: integer); options(val_param); internal;
var
  b: g_opt_num_t;
begin
  pt('', 0);
  prtcats(line, title, n);
  listln(line);
  line.length := 0;
  pt('', 0);
  for b := opt_first_block to opt_last_block do begin
    prtcatc(line, '[');
    prtint(line, b, 5, false);
    prtcats(line, ']   ', 3);
    dbs(sets^[b]);
  end;
  pt('', 0);
end;

{ dumprd - -DUMP68 RD: each variable's definitions, then each block's
  KILL, GEN and reaching (RDTOP) sets.

  0x0E1CC8, 0xF4 bytes. }

procedure dumprd; internal;
var
  v: integer;
begin
  line.length := 0;
  pt('RD Dump', 7);
  pt('', 0);
  pt('RD VARs', 7);
  for v := 1 to nvars do begin
    prttab(line, 8);
    prtobj(line, opt_4009c[opt_region]^.vars^[v]^.node);
    dbs(var_defs^[v]);
    pt('', 0);
  end;
  dumprdset(rd_kill, 'KILL', 4);
  dumprdset(rd_gen, 'GEN', 3);
  dumprdset(rd_in, 'RDTOP', 5);
end;

{ adjust_ptr - see g_opt.ins.pas.

  0x0E1DDC, 0x3A bytes: (opt_first_block - 1) * k by M$MIS$LLW; the
  result in A0. }

function adjust_ptr(
    p: univ_ptr;
    k: integer): univ_ptr;
begin
  adjust_ptr := univ_ptr(integer32(p) - (opt_first_block - 1) * k);
end;

{ zero_longwords - n longwords from p cleared.

  0x0E1E16, 0x14 bytes, no frame: `clr.l (A0)+' while n > 0. }

procedure zero_longwords(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
var
  q: rd_longs_ptr_t;
begin
  q := p;
  while n > 0 do begin
    q^ := 0;
    q := rd_longs_ptr_t(integer32(q) + 4);
    n := n - 1;
  end;
end;

{ zero_bytes - n bytes from p cleared: the longwords, then the rest.

  0x0E1E2A, 0x56 bytes: n div 4 and n mod 4 signed (M$OIS$WLW). }

procedure zero_bytes(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
var
  q: rd_bytes_ptr_t;
  k: integer32;
begin
  zero_longwords(p, n div 4);
  q := rd_bytes_ptr_t(integer32(p) + (n & (-4)));
  k := n mod 4;
  while k > 0 do begin
    q^ := chr(0);
    q := rd_bytes_ptr_t(integer32(q) + 1);
    k := k - 1;
  end;
end;

{ bset - statement k into rd set s.

  0x0E1E80, 0x48 bytes: k + 1 - opt_region as a longword, its longword
  (+ 32, `lsr.l #5') and bit (`and.w #31'). }

procedure bset(
    s: rd_set_ptr_t;
    k: g_opt_num_t); options(val_param); internal;
var
  i: integer32;
begin
  i := k + 1 - opt_region;
  s^[rshft(i + 32, 5)] := s^[rshft(i + 32, 5)] + [i & 31];
end;

{ bclr - statement k out of rd set s.

  0x0E1EC8, 0x4A bytes: as bset, `not.l; and.l'. }

procedure bclr(
    s: rd_set_ptr_t;
    k: g_opt_num_t); options(val_param); internal;
var
  i: integer32;
begin
  i := k + 1 - opt_region;
  s^[rshft(i + 32, 5)] := s^[rshft(i + 32, 5)] - [i & 31];
end;

{ releaserd - opt_main's +0x14 pool emptied, unless initrd allocated
  nothing (no blocks, no variables, or il_180 a function block, kind
  108, with +376 bit 3 and the convention (+377 bits 6..4) 2).

  0x0E1F12, 0x54 bytes. }

procedure releaserd;
begin
  if il_124 <> 0 then
    if opt_max_vars > 0 then
      if not ((il_180^.kind = function_blk) and
              il_180^.blk_atts.local_name_only and
              (il_180^.blk_atts.call = call_ftn)) then
        mem_$empty_pool(opt_main_14);
end;

{ initrd - the tables, for opt_max_vars variables and opt_max_stmts
  statements, from opt_main's +0x14 pool (under releaserd's
  conditions).

  0x0E2020, 0x1C0 bytes: the sizes signed (`ext.l'), the loop from 0;
  the pool read as opt_main's +0x14 through its data's address in the
  loop (`movea.l #0x2D2EF0,A2', (20,A2): docs/rev889-patterns.md 70). }

procedure initrd;
var
  size: integer32;
  v: integer;

  { alloc_rdset - a table of opt_nblocks rd sets of rd_words longwords
    (rd_words set from opt_max_stmts + opt_max_vars).

    0x0E1F66, 0xBA bytes: nested, no static link used; the products by
    M$MIS$LLL; the result in A0. }

  function alloc_rdset: rd_sets_ptr_t;
  var
    t: rd_sets_ptr_t;
    base: univ_ptr;
    n: integer32;
    i: g_opt_num_t;
  begin
    t := mem_$alloc(opt_main_14, opt_nblocks * 4);
    n := (opt_max_stmts + opt_max_vars + 1) div 32 + 1;
    rd_words := n;
    n := n * 4;
    base := mem_$alloc(opt_main_14, opt_nblocks * n);
    for i := 1 to opt_nblocks do
      t^[i] := univ_ptr(integer32(base) + (i - 1) * n);
    alloc_rdset := t;
  end;

begin
  if il_124 <> 0 then
    if opt_max_vars > 0 then
      if not ((il_180^.kind = function_blk) and
              il_180^.blk_atts.local_name_only and
              (il_180^.blk_atts.call = call_ftn)) then begin
        var_defs := mem_$alloc(opt_main_14, (opt_max_vars + 1) * 4);
        kill_base := alloc_rdset;
        gen_base := alloc_rdset;
        in_base := alloc_rdset;
        value := mem_$alloc(opt_main_14, (opt_max_vars + 1) * 4);
        seen := mem_$alloc(opt_main_14, opt_max_vars + 1);
        assigned := mem_$alloc(opt_main_14, opt_max_vars + 1);
        defs := mem_$alloc(opt_main_14, (opt_max_vars + 1) * 4);
        last_use := mem_$alloc(opt_main_14, (opt_max_vars + 1) * 4);
        last_def := mem_$alloc(opt_main_14, (opt_max_vars + 1) * 4);
        rd_tmp := mem_$alloc(opt_main_14, rd_words * 4);
        size := (rd_words + 1) * 4;
        for v := 0 to opt_max_vars do begin
          var_defs^[v] := mem_$alloc(opt_main_14, size);
          defs^[v] := mem_$alloc(opt_main_14, 6);
        end;
      end;
end;

{ add_def_stmt - the statement at hand added to variable v's
  definitions in the block (in the first cell whose stmt is 0, the
  cells kept for reuse).

  0x0E21E0, 0xC4 bytes: the cells from opt_main's +0x14 pool. }

procedure add_def_stmt(
    v: integer); options(val_param); internal;
var
  p: rd_def_ptr_t;
begin
  if defs^[v]^.stmt = 0 then
    defs^[v]^.stmt := cur
  else if defs^[v]^.next <> nil then begin
    p := defs^[v]^.next;
    while p^.stmt <> 0 do begin
      if p^.next = nil then begin
        p^.next := mem_$alloc(opt_main_14, 6);
        p^.next^.stmt := 0;
        p^.next^.next := nil;
      end;
      p := p^.next;
    end;
    p^.stmt := cur;
  end
  else begin
    defs^[v]^.next := mem_$alloc(opt_main_14, 6);
    defs^[v]^.next^.stmt := cur;
    defs^[v]^.next^.next := nil;
  end;
end;

{ genkill - statement s of block b assigns variable v: the block kills
  every definition of v and generates s alone among them.

  0x0E22A4, 0xB8 bytes. }

procedure genkill(
    b: g_opt_num_t;
    s: g_opt_num_t;
    v: integer); options(val_param); internal;
var
  w: integer;
begin
  if v <> 0 then begin
    for w := 1 to rd_used do begin
      rd_kill^[b]^[w] := rd_kill^[b]^[w] + var_defs^[v]^[w];
      rd_gen^[b]^[w] := rd_gen^[b]^[w] - var_defs^[v]^[w];
    end;
    bset(rd_gen^[b], s);
    bclr(rd_kill^[b], s);
  end;
end;

{ paramclass - see g_opt.ins.pas.  The routine called is n's first
  operand (through a 147, 205 or 146 its +28, a 175's +20): a routine
  constant (171) passes by value (2); a pointer to a routine (173, 174)
  and a routine block (107, 108, 167) give the parameter's own class
  (+44 of the k-th of the chain from +4, from +12 for a block) for
  conventions 1 and 6, by value (2) past the parameters when +76 (a
  block's +377) bit 1 allows more, 2 for convention 3; a 159 the low
  nibble of its k-th word from +12 (the last past its count, +10): below
  10 by value (2), 10 is 1, above 3.  4 otherwise.

  0x0E235C, 0x178 bytes: the conventions by two jump tables of 6
  entries (`subq.w #1; cmpi.w #6; bcc'); the k-th by `dbf' (k - 1
  steps). }

function paramclass(
    n: il_$node_ptr_t;
    k: integer): integer;
var
  r, p: il_$node_ptr_t;
  c, i: integer;
begin
  c := 4;
  r := g_opt_tree_ptr_t(n)^.opnd[1];
  case r^.kind of
    disp_node, sym_disp_node, ptr_node:
      r := r^.xp[7];
    pf_call:
      r := r^.xp[5];
    otherwise
  end;
  case r^.kind of
    cc_call:
      c := 2;
    func__type, proc__type:
      case rshft(ord(r^.xc[76]) & 16#38, 3) of
        1, 6:
          if k <= r^.xw[37] then begin
            p := r^.xp[1];
            for i := 2 to k do
              p := p^.xp[1];
            c := p^.xw[22];
          end
          else if (ord(r^.xc[76]) & 2) <> 0 then
            c := 2;
        3:
          c := 2;
        otherwise
      end;
    entry_blk, function_blk, procedure_blk:
      case r^.blk_atts.call of
        1, 6:
          if k <= ord(r^.xc[293]) then begin
            p := r^.xp[3];
            for i := 2 to k do
              p := p^.xp[1];
            c := p^.xw[22];
          end
          else if r^.blk_atts.val_param_flag then
            c := 2;
        3:
          c := 2;
        otherwise
      end;
    lib_dsc: begin
      if k > r^.xw[5] then
        i := r^.xw[5]
      else
        i := k;
      c := ord(r^.xc[11 + 2 * i]) & 15;
      if c < 10 then
        c := 2
      else if c = 10 then
        c := 1
      else
        c := 3;
    end;
    otherwise
  end;
  paramclass := c;
end;

{ compute_rd - the definitions reaching each block's top: an entry
  block (flags.skip) is reached by every assignment, the others by none
  at first; then over the blocks in depth-first order, the union of the
  predecessors' outs (gen + (in - kill)) becomes the block's in, until
  no in changes.

  0x0E24D4, 0x212 bytes: the blocks reached through il.pas's +0xC0
  (`movea.l #0x169D30', (92,A3): docs/rev889-patterns.md 70); the
  comparison stops at the first longword that differs, copying from
  there. }

procedure compute_rd; internal;
var
  b, i: g_opt_num_t;
  w, w2, j: integer;
  stable: boolean;
  blk, p: g_opt_block_ptr_t;
begin
  for b := opt_first_block to opt_last_block do
    if g_opt_blocks_ptr_t(il_11c)^[b]^.flags.skip then
      for w := 1 to rd_used do
        rd_in^[b]^[w] := var_defs^[0]^[w]
    else
      zero_longwords(rd_in^[b], rd_used);
  repeat
    stable := true;
    for i := opt_first_block to opt_last_block do begin
      b := opt_dfs_block^[i];
      blk := g_opt_blocks_ptr_t(il_11c)^[b];
      if not blk^.flags.skip and (blk^.npreds <> 0) then begin
        p := blk^.pred[1];
        for w := 1 to rd_used do
          rd_tmp^[w] := (rd_in^[p^.num]^[w] - rd_kill^[p^.num]^[w]) +
                        rd_gen^[p^.num]^[w];
        for j := 2 to blk^.npreds do begin
          p := blk^.pred[j];
          for w := 1 to rd_used do
            rd_tmp^[w] := rd_tmp^[w] +
                          ((rd_in^[p^.num]^[w] - rd_kill^[p^.num]^[w]) +
                           rd_gen^[p^.num]^[w]);
        end;
        for w := 1 to rd_used do
          if rd_tmp^[w] <> rd_in^[b]^[w] then begin
            for w2 := w to rd_used do
              rd_in^[b]^[w2] := rd_tmp^[w2];
            stable := false;
            exit;
          end;
      end;
    end;
  until stable;
end;

{ make_ud_chain - the use-def chain of variable v at statement s, a
  statement of block b: each definition of v reaching b's top (a region
  statement whose vnum is v) appended to s's entry of v once.

  0x0E26E6, 0x182 bytes: cur set to each definition; region numbers
  compared unsigned; `bit in' range-checked. }

procedure make_ud_chain(
    b: g_opt_num_t;
    s: g_opt_stmt_ptr_t;
    v: integer); options(val_param); internal;
var
  w, bit: integer;
  e: g_opt_var_ptr_t;
  c: g_opt_chain_ptr_t;
begin
  for w := 1 to rd_used do
    if rd_in^[b]^[w] <> [] then
      for bit := 0 to 31 do
        if bit in rd_in^[b]^[w] then begin
          cur := opt_region - 1 + bit + (w - 1) * 32;
          if cur >= opt_region then
            if cur <= runbackend_16 then
              if opt_4009c[cur]^.hdr.vnum = v then begin
                e := s^.vars^[v];
                if e^.ud = nil then begin
                  e^.ud := mem_$alloc(opt_main_18, 8);
                  e^.ud^.next := nil;
                  e^.ud^.stmt := opt_4009c[cur];
                end
                else if not assert_this_definition_on_ud_chain(e^.ud, cur) then begin
                  c := e^.ud;
                  while c^.next <> nil do
                    c := c^.next;
                  c^.next := mem_$alloc(opt_main_18, 8);
                  c := c^.next;
                  c^.next := nil;
                  c^.stmt := opt_4009c[cur];
                end;
              end;
        end;
end;

{ make_motioned_ud_chain - see g_opt.ins.pas.

  0x0E2868, 0x48 bytes. }

procedure make_motioned_ud_chain(
    in v: integer;
    in r: integer;
    in s: g_opt_stmt_ptr_t);
begin
  make_ud_chain(opt_4009c[r]^.block^.num, s, v);
end;

{ build_ud_chains - the use-def chains of every region statement's
  variables (those in its vset): within a block a use after another
  use with no assignment between shares that use's chain, a use after
  an assignment in the block gets that assignment alone, the first use
  the definitions reaching the block (make_ud_chain).

  0x0E28B0, 0x1D2 bytes: the regions compared unsigned. }

procedure build_ud_chains; internal;
var
  r, bn, lastbn: g_opt_num_t;
  v: integer;
  s: g_opt_stmt_ptr_t;
  e: g_opt_var_ptr_t;
begin
  lastbn := 0;
  for r := opt_region to runbackend_16 do begin
    s := opt_4009c[r];
    bn := s^.block^.num;
    if bn <> lastbn then begin
      for v := 1 to nvars do begin
        last_def^[v].set_ := false;
        last_def^[v].stmt := 0;
        last_use^[v].set_ := false;
        last_use^[v].stmt := 0;
      end;
      lastbn := bn;
    end;
    for v := 1 to nvars do begin
      if assert_nonempty_var_use_set(s^.vset) then
        if v in s^.vset^ then begin
          if last_use^[v].set_ then
            s^.vars^[v]^.ud := opt_4009c[last_use^[v].stmt]^.vars^[v]^.ud
          else begin
            if last_def^[v].set_ then begin
              e := s^.vars^[v];
              e^.ud := mem_$alloc(opt_main_18, 8);
              e^.ud^.next := nil;
              e^.ud^.stmt := opt_4009c[last_def^[v].stmt];
            end
            else
              make_ud_chain(bn, s, v);
            last_use^[v].set_ := true;
            last_use^[v].stmt := r;
          end;
        end;
      if s^.hdr.vnum = v then begin
        last_def^[v].set_ := true;
        last_def^[v].stmt := r;
        last_use^[v].set_ := false;
        last_use^[v].stmt := 0;
      end;
    end;
  end;
end;

{ markuses - each region statement's vset: the variables its trees
  use (walk_tree), an operand of 151 and, for an assignment whose
  operator reads its left side (1..5, 7..9, 13..24), the variable
  assigned; from opt_region's statement up to runbackend_16's.

  0x0E2E94, 0x1FA bytes: the kinds compared in turn; the singleton sets
  built in a frame temporary and or-ed in. }

procedure markuses;
var
  s: g_opt_stmt_ptr_t;
  v: integer;
  n: il_$node_ptr_t;

  { walk_tree - the variables of tree t into statement s's vset (a
    variable with an entry in opt_region's table; on an assignment's
    left side the variable stored is not a use), with an entry of its
    own in s's table (a copy of opt_region's, count 0); a shared tree
    (uses > 1) walked once (flags element 5 set by evalforeffect,
    cleared here); an index's (145) variable at +28 is a use.

    0x0E2A82, 0x3C4 bytes: nested, the parent's frame not used;
    recursive; the kinds compared in turn; a call's (operators 15,
    16) operands from the second (the first when the first operand is
    a 175), constants and variables with an entry skipped. }

  procedure walk_tree(
      s: g_opt_stmt_ptr_t;
      t: il_$node_ptr_t); options(val_param);
  var
    k, first: integer;
    o: il_$node_ptr_t;
    v: integer;
  begin
    if t = nil then
      return;
    if t^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                   dindex_node..disp_node, cs_node, cc_call, pf_call,
                   cse_use_ob, sym_disp_node] then
      if not (phase_vis in g_opt_tree_ptr_t(t)^.flags) then
        if t^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                       dindex_node..disp_node, cs_node, sym_disp_node] then
          if g_opt_tree_ptr_t(t)^.uses > 1 then
            if not ((t^.kind = sym_disp_node) or (t^.kind = disp_node) or
                    (t^.kind = ptr_node) or (t^.kind = dindex_node)) then
              return;
    case t^.kind of
      cmp_tree_node, tree_node:
        if (g_opt_tree_ptr_t(t)^.op = func_call_top) or (g_opt_tree_ptr_t(t)^.op = call_top) then begin
          first := 2;
          if g_opt_tree_ptr_t(t)^.opnd[1]^.kind = pf_call then
            first := 1;
          for k := first to g_opt_tree_ptr_t(t)^.count do begin
            o := g_opt_tree_ptr_t(t)^.opnd[k];
            if o <> nil then
              if not (o^.kind in [blogical_ob..complex_ob, char_string_ob,
                                  char32_string_ob, char16_ob, set_con_ob,
                                  rec_const_ob, dpcomplex_ob,
                                  binteger_ob]) then
                if not (((o^.kind = fortran_symbol) or (o^.kind = var_name))
                        and
                        (find_var(o) <> 0)) then
                  walk_tree(s, o);
          end;
        end
        else
          for k := 1 to g_opt_tree_ptr_t(t)^.count do
            walk_tree(s, g_opt_tree_ptr_t(t)^.opnd[k]);
      disp_node:
        walk_tree(s, t^.xp[6]);
      sym_disp_node:
        walk_tree(s, t^.xp[6]);
      ptr_node:
        walk_tree(s, t^.xp[6]);
      dindex_node: begin
        walk_tree(s, t^.xp[6]);
        walk_tree(s, t^.xp[9]);
        if t^.xp[7] <> nil then
          if (t^.xp[7]^.kind = fortran_symbol)
              or (t^.xp[7]^.kind = var_name) then begin
            v := find_var(t^.xp[7]);
            if v <> 0 then begin
              opt_main_$ensure_var_set(s^.vset);
              s^.vset^ := s^.vset^ + [v];
            end;
          end;
      end;
      cs_node: begin
        walk_tree(s, t^.xp[5]);
        walk_tree(s, t^.xp[6]);
      end;
      pf_call:
        walk_tree(s, t^.xp[4]);
      cc_call:
        walk_tree(s, t^.xp[4]);
      var_name, fortran_symbol: begin
        v := find_var(t);
        if v = 0 then
          return;
        if (s^.kind = assign_node) and on_lhs then begin
          if s^.asg_lhs <> t then
            if not ((s^.asg_lhs^.kind = disp_node)
                    and (s^.asg_lhs^.xp[6] = t)) then begin
              opt_main_$ensure_var_set(s^.vset);
              s^.vset^ := s^.vset^ + [v];
            end;
        end
        else begin
          opt_main_$ensure_var_set(s^.vset);
          s^.vset^ := s^.vset^ + [v];
        end;
        if assert_nonempty_var_use_set(s^.vset) then
          if v in s^.vset^ then
            if s^.vars <> nil then
              if s^.vars^[v] = nil then begin
                s^.vars^[v] := mem_$alloc(opt_main_18, 18);
                s^.vars^[v]^ := opt_4009c[opt_region]^.vars^[v]^;
                s^.vars^[v]^.count := 0;
              end;
      end;
      otherwise
    end;
    if t^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                   dindex_node..disp_node, cs_node, cc_call, pf_call,
                   cse_use_ob, sym_disp_node] then
      g_opt_tree_ptr_t(t)^.flags := g_opt_tree_ptr_t(t)^.flags - [phase_vis];
  end;

begin
  on_lhs := false;
  s := opt_4009c[opt_region];
  while s <> nil do begin
    if not s^.hdr.stmt_eliminated then
      case s^.kind of
        nlbranch_node, label_node, use_def_ob:
          ;
        return_node:
          if s^.x48 <> nil then begin
            n := s^.x48;
            if (n^.kind = var_name) or (n^.kind = ptr_node)
                or (n^.kind = fortran_symbol) then begin
              v := 0;
              if n^.kind <> ptr_node then
                v := find_var(n)
              else if n^.xp[6] <> nil then
                if (n^.xp[6]^.kind = fortran_symbol)
                    or (n^.xp[6]^.kind = var_name) then
                  v := find_var(n^.xp[6]);
              if v <> 0 then begin
                opt_main_$ensure_var_set(s^.vset);
                s^.vset^ := s^.vset^ + [v];
              end;
            end;
          end;
        assign_node: begin
          on_lhs := false;
          walk_tree(s, s^.asg_rhs);
          if s^.asg_x <> nil then
            walk_tree(s, s^.asg_x);
          on_lhs := true;
          walk_tree(s, s^.asg_lhs);
          on_lhs := false;
          if s^.asg_op in [add_to_aop..eor_to_aop, set_and_to_aop..set_diff_from_aop, not_to_aop..div_by_aop] then begin
            v := s^.hdr.vnum;
            if v <> 0 then begin
              opt_main_$ensure_var_set(s^.vset);
              s^.vset^ := s^.vset^ + [v];
            end;
          end;
        end;
        eval_node:
          for v := 1 to s^.eval_count do
            walk_tree(s, s^.eval_opnd[v]);
        cbranch_node:
          walk_tree(s, s^.br_cond);
        otherwise
      end;
    s := s^.next;
    if s = opt_4009c[runbackend_16] then
      exit;
  end;
end;

{ evalforeffect - the constants known at tree t's uses put in (kfold
  folding what they make constant; depth bounds the recursion, the
  statement level passes 32767), the variables a statement assigns
  noted in value and seen (an assignment (op 0 or 11) of a constant
  makes its variable known; op 0 of an integer constant is narrowed to
  the variable's type), a call (operators 15, 16) or an operator 47 kills
  what it may change; a shared tree (flags element 5) is done once.

  0x0E328C, 0xE28 bytes: t by address; the kinds compared in turn (the
  tree kinds 137, 143, 164, 145 before each kfold); a tree's operator
  compared in turn (26, 47, 16, 15, 11); the second of two calls takes
  the first's pad (docs/rev889-patterns.md 51); the integer constant's
  narrowing through a byte or word in the frame (-48 signed, -44
  unsigned), written here with masks; il_180's convention (+377 bits
  6..4). }

procedure evalforeffect(
    var t: univ il_$node_ptr_t;
    depth: integer); options(val_param); internal;
label
  known, done;
var
  d: alias_$desc_t;
  s, a, o: il_$node_ptr_t;
  v, i, j: integer;
  k: integer32;
  vt: g_opt_vtypes_ptr_t;

  { propagate - variable v's known value put in the parent's t (a use
    of v), unless v is a reference parameter's copy, its value is not
    known, or the variable is volatile or alike (+32 of a 109, +24 of a
    110: elements 0, 8, 12, 21); warned (cgerr 61) when another value
    may reach the use; the use counts moved to the value; v's
    definitions in the block marked (16#100: a chain was cut).

    0x0E308E, 0x1FE bytes: nested, the parent's frame from the dynamic
    link (`move.l (A6),D4'). }

  procedure propagate(
      v: integer); options(val_param);
  var
    bn: integer;
    c: rd_def_ptr_t;
  begin
    if t^.kind = var_name then
      if t^.vr_vat = param_vat then
        if t^.xp[7]^.kind = param_name then
          if t^.xp[7]^.xw[22] in [1, 3, 4] then
            return;
    if not seen^[v] then
      return;
    if value^[v] = nil then
      return;
    if t^.kind = var_name then
      if t^.vr_attr * [var_$volatile, var_$uplevel, var_$address_exposed,
                       var_$nooptimize] <> [] then
        return;
    if t^.kind = fortran_symbol then
      if t^.fs_attr * [var_$volatile, var_$uplevel, var_$address_exposed,
                       var_$nooptimize] <> [] then
        return;
    bn := opt_4009c[cur]^.block^.num;
    if (t^.kind = fortran_symbol) or (t^.kind = var_name) then
      if assert_uninitialized_value_can_reach(v, bn) then
        cgerr(61, il_utils_$src_line(il_$node_ptr_t(opt_4009c[cur])), t);
    adjust_uc(t, -1);
    if opt_4009c[cur]^.vset <> nil then
      opt_4009c[cur]^.vset^ := opt_4009c[cur]^.vset^ - [v];
    t := value^[v];
    if defs^[v]^.stmt <> 0 then begin
      c := defs^[v];
      while c <> nil do begin
        if c^.stmt <> 0 then
          opt_4009c[c^.stmt]^.vars^[v]^.flags :=
            opt_4009c[c^.stmt]^.vars^[v]^.flags ! 16#100;
        c := c^.next;
      end;
    end;
    adjust_uc(t, 1);
  end;

begin
  if depth < 0 then
    return;
  if t = nil then
    return;
  if t^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                 dindex_node..disp_node, cs_node, cc_call, pf_call, cse_use_ob,
                 sym_disp_node] then begin
    if g_opt_tree_ptr_t(t)^.uses > 1 then
      if phase_vis in g_opt_tree_ptr_t(t)^.flags then
        if (t^.kind = cmp_tree_node) or (t^.kind = tree_node) then
          return;
    if phase_vis in g_opt_tree_ptr_t(t)^.flags then
      if not ((t^.kind = cmp_tree_node) or (t^.kind = tree_node)) then
        return;
  end;
  case t^.kind of
    var_name, fortran_symbol: begin
      v := find_var(t);
      if v = 0 then
        return;
      propagate(v);
    end;
    ptr_node: begin
      s := t;
      v := find_var(s^.xp[6]);
      a := s^.xp[6];
      if v = 0 then
        evalforeffect(s^.xp[6], depth - 1)
      else if t^.xp[6]^.kind = var_name then
        if t^.xp[6]^.vr_vat = param_vat then
          if t^.xp[6]^.xp[7]^.kind = param_name then
            if t^.xp[6]^.xp[7]^.xw[22] in [1, 3, 4] then
              propagate(v);
      if t^.kind = ptr_node then
        if (a^.kind = fortran_symbol) or (a^.kind = var_name) then
          if t^.xp[6]^.kind = tree_node then
            if g_opt_tree_ptr_t(t)^.uses > 1 then
              adjust_uc(t^.xp[6], g_opt_tree_ptr_t(t)^.uses - 1);
      if s^.xp[6]^.kind in [tree_node, cmp_tree_node, cs_node,
                            dindex_node] then
        kfold(t, s^.xp[6]);
    end;
    disp_node: begin
      a := t^.xp[6];
      if find_var(t^.xp[6]) = 0 then
        evalforeffect(t^.xp[6], depth - 1);
      if t^.kind = disp_node then
        if (a^.kind = fortran_symbol) or (a^.kind = var_name) then
          if t^.xp[6]^.kind = tree_node then
            if g_opt_tree_ptr_t(t)^.uses > 1 then
              adjust_uc(t^.xp[6], g_opt_tree_ptr_t(t)^.uses - 1);
      if t^.kind = disp_node then
        if t^.xp[6]^.kind in [blogical_ob..char_ob, char16_ob,
                              binteger_ob] then
          if a^.kind = ptr_node then
            if (a^.xp[6]^.kind = fortran_symbol)
                or (a^.xp[6]^.kind = var_name) then
              t := t^.xp[6];
    end;
    sym_disp_node: begin
      a := t^.xp[6];
      if find_var(t^.xp[6]) = 0 then
        evalforeffect(t^.xp[6], depth - 1);
      if t^.kind = sym_disp_node then
        if (a^.kind = fortran_symbol) or (a^.kind = var_name) then
          if t^.xp[6]^.kind = tree_node then
            if g_opt_tree_ptr_t(t)^.uses > 1 then
              adjust_uc(t^.xp[6], g_opt_tree_ptr_t(t)^.uses - 1);
    end;
    dindex_node: begin
      s := t;
      a := s^.xp[6];
      if find_var(a) = 0 then
        evalforeffect(s^.xp[6], depth - 1);
      if t^.kind = dindex_node then
        if (a^.kind = fortran_symbol) or (a^.kind = var_name) then
          if t^.xp[6]^.kind = tree_node then
            if g_opt_tree_ptr_t(t)^.uses > 1 then
              adjust_uc(t^.xp[6], g_opt_tree_ptr_t(t)^.uses - 1);
      a := s^.xp[9];
      evalforeffect(s^.xp[9], depth - 1);
      if t^.kind = dindex_node then
        if (a^.kind = fortran_symbol) or (a^.kind = var_name) then
          if t^.xp[9]^.kind = tree_node then
            if g_opt_tree_ptr_t(t)^.uses > 1 then
              adjust_uc(t^.xp[9], g_opt_tree_ptr_t(t)^.uses - 1);
      if s^.xp[6]^.kind in [tree_node, cmp_tree_node, cs_node,
                            dindex_node] then
        kfold(t, s^.xp[6]);
      if s^.xp[9]^.kind in [tree_node, cmp_tree_node, cs_node,
                            dindex_node] then
        kfold(t, s^.xp[9]);
    end;
    cs_node: begin
      s := t;
      evalforeffect(s^.xp[5], depth - 1);
      if s^.xp[5] <> nil then
        if s^.xp[5]^.kind in [tree_node, cmp_tree_node, cs_node,
                              dindex_node] then
          kfold(t, s^.xp[5]);
      evalforeffect(s^.xp[6], depth - 1);
      if s^.xp[6] <> nil then
        if s^.xp[6]^.kind in [tree_node, cmp_tree_node, cs_node,
                              dindex_node] then
          kfold(t, s^.xp[6]);
    end;
    assign_node: with g_opt_stmt_ptr_t(t)^ do begin
      evalforeffect(asg_rhs, depth - 1);
      if asg_rhs^.kind in [tree_node, cmp_tree_node, cs_node, dindex_node] then
        kfold(t, asg_rhs);
      if asg_rhs <> nil then
        if asg_rhs^.kind = char_string_ob then
          if asg_rhs^.str_len = 1 then
            asg_rhs := smcontk(integer_ob, ord(asg_rhs^.str_chars[1]));
      if asg_x <> nil then begin
        evalforeffect(asg_x, depth - 1);
        if asg_x^.kind in [tree_node, cmp_tree_node, cs_node, dindex_node] then
          kfold(t, asg_x);
      end;
      a := asg_lhs;
      if (a^.kind = ptr_node) and (a^.xp[6]^.kind = var_name) and
         (a^.xp[6]^.vr_vat = param_vat) and
         (a^.xp[6]^.xp[7]^.kind = param_name) and
         (a^.xp[6]^.xp[7]^.xw[22] in [1, 3, 4]) then begin
        v := a^.xp[6]^.xw[37];
        if v <> 0 then
          if not opt_var_types^[v].flags.ranged then
            return;
      end
      else
        v := find_var(a);
      if v = 0 then begin
        evalforeffect(asg_lhs, depth - 1);
        if asg_lhs^.kind in [tree_node, cmp_tree_node, cs_node,
                             dindex_node] then
          kfold(t, asg_lhs);
        return;
      end;
      if asg_lhs^.kind in [tree_node, cmp_tree_node, cs_node, dindex_node] then
        kfold(t, asg_lhs);
      if seen^[v] then begin
        if depth <= 0 then
          value^[v] := nil
        else if value^[v] <> asg_rhs then
          if ((asg_op = fp_aop) or (asg_op = scalar_aop)) and
             (asg_rhs^.kind in [blogical_ob..complex_ob, char_string_ob,
                                char32_string_ob, char16_ob, set_con_ob,
                                rec_const_ob, dpcomplex_ob, binteger_ob]) then
            goto known
          else
            value^[v] := nil;
        goto done;
      end;
    known:
      seen^[v] := true;
      if not ((asg_op = fp_aop) or (asg_op = scalar_aop)) then
        value^[v] := nil
      else if asg_rhs^.kind in [blogical_ob..complex_ob, char_string_ob,
                                char32_string_ob, char16_ob, set_con_ob,
                                rec_const_ob, dpcomplex_ob,
                                binteger_ob] then begin
        if depth > 0 then
          add_def_stmt(v);
        if (asg_op = scalar_aop) and (asg_rhs^.kind in [blogical_ob..char_ob, char16_ob,
                                               binteger_ob]) then begin
          k := asg_rhs^.int_value;
          vt := opt_var_types;
          if (vt^[v].low < 0) or (vt^[v].base^.kind = bool_type) then
            case vt^[v].size of
              1: begin
                k := k & 16#FF;
                if k > 127 then
                  k := k - 256;
              end;
              2: begin
                k := k & 16#FFFF;
                if k > 32767 then
                  k := k - 65536;
              end;
              otherwise
            end
          else
            case vt^[v].size of
              1: k := k & 16#FF;
              2: k := k & 16#FFFF;
              otherwise
            end;
          value^[v] := smcontk(integer_ob, k);
        end
        else
          value^[v] := asg_rhs;
      end
      else
        value^[v] := nil;
    end;
    cmp_tree_node, tree_node: begin
      s := t;
      case g_opt_tree_ptr_t(s)^.op of
        addr_top:
          if find_var(g_opt_tree_ptr_t(s)^.opnd[1]) = 0 then
            evalforeffect(g_opt_tree_ptr_t(s)^.opnd[1], depth - 1);
        sr_top:
          for v := 1 to nvars do begin
            seen^[v] := true;
            value^[v] := nil;
          end;
        func_call_top, call_top: begin
          for i := 2 to g_opt_tree_ptr_t(s)^.count do begin
            j := find_var(g_opt_tree_ptr_t(s)^.opnd[i]);
            if j = 0 then begin
              a := g_opt_tree_ptr_t(s)^.opnd[i];
              if a^.kind = disp_node then
                if a^.xp[6]^.kind = ptr_node then
                  if (a^.xp[6]^.xp[6]^.kind = fortran_symbol) or
                     (a^.xp[6]^.xp[6]^.kind = var_name) then
                    a := a^.xp[6];
              if (a^.kind = ptr_node) and (a^.xp[6]^.kind = var_name) and
                 (a^.xp[6]^.vr_vat = param_vat) and
                 (a^.xp[6]^.xp[7]^.kind = param_name) and
                 (a^.xp[6]^.xp[7]^.xw[22] in [1, 3, 4]) and
                 ((il_180^.blk_atts.call = call_pas) or
                  (il_180^.blk_atts.call = 6)) and
                 (paramclass(t, i - 1) in [1, 3, 4]) then begin
                v := find_var(a^.xp[6]);
                if v <> 0 then begin
                  seen^[v] := true;
                  value^[v] := nil;
                end;
              end
              else if not ((a^.kind = fortran_symbol) or
                           (((a^.kind = disp_node) or (a^.kind = ptr_node)) and
                            (a^.xp[6]^.kind = fortran_symbol))) then
                evalforeffect(g_opt_tree_ptr_t(s)^.opnd[i], depth - 1);
              if g_opt_tree_ptr_t(s)^.opnd[i]^.kind in [tree_node,
                  cmp_tree_node, cs_node, dindex_node] then
                kfold(t, g_opt_tree_ptr_t(s)^.opnd[i]);
              if a^.kind = tree_node then
                if find_var(g_opt_tree_ptr_t(s)^.opnd[i]) <> 0 then
                  g_opt_tree_ptr_t(s)^.opnd[i] :=
                    buildtreenode(value_top, g_opt_tree_ptr_t(a)^.size,
                                  g_opt_tree_ptr_t(s)^.opnd[i], 1);
            end
            else if paramclass(t, i - 1) <> 2 then begin
              seen^[j] := true;
              value^[j] := nil;
            end;
          end;
          for v := 1 to nvars do
            if not seen^[v] or (value^[v] <> nil) then begin
              alias_$basic_alias_desc(opt_4009c[opt_region]^.vars^[v]^.node, d);
              if (opt_4009c[cur]^.hdr.vnum = v) or
                 alias_$related_call(d, t) then begin
                seen^[v] := true;
                value^[v] := nil;
              end;
            end;
        end;
        bit_test_top: begin
          evalforeffect(g_opt_tree_ptr_t(s)^.opnd[1], depth - 1);
          evalforeffect(g_opt_tree_ptr_t(s)^.opnd[2], depth - 1);
        end;
        otherwise
          for i := 1 to g_opt_tree_ptr_t(s)^.count do
            evalforeffect(g_opt_tree_ptr_t(s)^.opnd[i], depth - 1);
      end;
      for i := 1 to g_opt_tree_ptr_t(s)^.count do
        if g_opt_tree_ptr_t(s)^.opnd[i]^.kind in [tree_node, cmp_tree_node,
                                                  cs_node, dindex_node] then
          kfold(t, g_opt_tree_ptr_t(s)^.opnd[i]);
    end;
    cbranch_node: with g_opt_stmt_ptr_t(t)^ do begin
      evalforeffect(br_cond, depth - 1);
      if br_cond^.kind in [tree_node, cmp_tree_node, cs_node, dindex_node] then
        kfold(t, br_cond);
      if br_cond <> nil then
        if br_cond^.kind = tree_node then
          if g_opt_tree_ptr_t(br_cond)^.op = f_compare_top then
            if g_opt_tree_ptr_t(br_cond)^.uses = 1 then
              br_cond^.kind := cmp_tree_node;
      if br_cond <> nil then
        if br_cond^.kind = char_string_ob then
          if br_cond^.str_len = 1 then
            br_cond := smcontk(integer_ob, ord(br_cond^.str_chars[1]));
    end;
    eval_node: with g_opt_stmt_ptr_t(t)^ do
      for i := 1 to eval_count do begin
        evalforeffect(eval_opnd[i], depth - 1);
        if eval_opnd[i]^.kind in [tree_node, cmp_tree_node, cs_node,
                                  dindex_node] then
          kfold(t, eval_opnd[i]);
      end;
    return_node: with g_opt_stmt_ptr_t(t)^ do
      if il_180^.blk_atts.call <> call_c then
        evalforeffect(x48, depth - 1)
      else begin
        if x48 <> nil then
          v := find_var(x48)
        else
          v := 0;
        if v <> 0 then
          if not seen^[v] then begin
            x48 := nil;
            if assert_nonempty_var_use_set(opt_4009c[cur]^.vset) then
              opt_4009c[cur]^.vset^ := opt_4009c[cur]^.vset^ - [v];
          end;
      end;
    otherwise
  end;
done:
  if t^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                 dindex_node..disp_node, cs_node, cc_call, pf_call, cse_use_ob,
                 sym_disp_node] then
    if (t^.kind = cmp_tree_node) or (t^.kind = tree_node) then begin
      if g_opt_tree_ptr_t(t)^.uses > 1 then
        g_opt_tree_ptr_t(t)^.flags := g_opt_tree_ptr_t(t)^.flags + [phase_vis];
    end
    else
      g_opt_tree_ptr_t(t)^.flags := g_opt_tree_ptr_t(t)^.flags + [phase_vis];
end;

{ assert_no_predecessors - b has no predecessor.

  0x0E40CE, 0x16 bytes, no frame. }

function assert_no_predecessors(
    b: g_opt_block_ptr_t): boolean; options(val_param); internal;
begin
  if b = nil then
    assert_no_predecessors := false
  else
    assert_no_predecessors := b^.npreds = 0;
end;

{ assert_predecessor_is_me - b's only predecessor is b.

  0x0E40E4, 0x1E bytes, no frame. }

function assert_predecessor_is_me(
    b: g_opt_block_ptr_t): boolean; options(val_param); internal;
begin
  if b = nil then
    assert_predecessor_is_me := false
  else if b^.npreds = 1 then
    assert_predecessor_is_me := b^.pred[1] = b
  else
    assert_predecessor_is_me := false;
end;

{ assert_block_is_entrypoint - b is an entry of the routine (flags
  bit 6 or 3).

  0x0E4102, 0x1E bytes, no frame: `(flags & 0xFE) >> 1 & 36'. }

function assert_block_is_entrypoint(
    b: g_opt_block_ptr_t): boolean; options(val_param); internal;
begin
  if b = nil then
    assert_block_is_entrypoint := false
  else
    assert_block_is_entrypoint := b^.flags.b6 or b^.flags.run;
end;

{ assert_is_dominated_by_some_entrypoint - some dominator of b (up the
  dom links) is an entry block.

  0x0E4120, 0x38 bytes. }

function assert_is_dominated_by_some_entrypoint(
    b: g_opt_block_ptr_t): boolean; options(val_param); internal;
begin
  while b <> nil do begin
    if b^.dom <> nil then
      if assert_block_is_entrypoint(b^.dom) then
        exit;
    b := b^.dom;
  end;
  assert_is_dominated_by_some_entrypoint := b <> nil;
end;

{ statement_contained_by_unreachable_basic_block - top-level statement
  s is in a block no entry reaches (none of its predecessors, only
  itself, or no entry dominating it); a block marked skip or an entry
  is reachable.

  0x0E4158, 0x84 bytes: the kinds by a set of 0..239 without a range
  check (docs/rev889-patterns.md 41). }

function statement_contained_by_unreachable_basic_block(
    s: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
begin
  if s = nil then
    bug_check('OPT_REACHDEF\STATEMENT_CONTAINED_BY_UNREACHABLE_BASIC_BLOCK -- not a top_level node%.')
  else if not (s^.kind in [eval_node..cbranch_node, label_node,
                           block_entry_node..return_node, use_def_ob,
                           reg_list_ob, case_node_range_check,
                           case_node_no_range_check,
                           exception_handler_entry..release_dynamic_space,
                               insert_bit_field, bit_field_assign, spine_mark,
                               pa_mmu_bip]) then
    bug_check('OPT_REACHDEF\STATEMENT_CONTAINED_BY_UNREACHABLE_BASIC_BLOCK -- not a top_level node%.');
  statement_contained_by_unreachable_basic_block := false;
  if s^.block <> nil then
    if not s^.block^.flags.skip then
      if not assert_block_is_entrypoint(s^.block) then
        statement_contained_by_unreachable_basic_block :=
          assert_no_predecessors(s^.block) or
          assert_predecessor_is_me(s^.block) or
          not assert_is_dominated_by_some_entrypoint(s^.block);
end;

{ reachingdefinitions - the rd sets of the routine's blocks (each
  region statement assigning a variable a definition; a store through
  a pointer to a variable (147 of a 109, 110, or a 76 whose variables
  share the base) marks it), compute_rd, then block by block in
  depth-first order the known values propagated (evalforeffect from
  the definitions reaching the block, init_block), markuses and
  build_ud_chains; then (unless opt_track_lines) the uses of each
  variable no definition reaches before the use are warned (cgerr 21,
  16#400 set on the entry), and for a convention other than 2 the
  reference parameters with a type range never assigned.

  0x0E462C, 0x10A8 bytes: il_d0 kept in D7 and put back at the end;
  the region numbers compared unsigned (`bcs', `bhi'); `w in vset'
  without a range check; flags masks 16#201001 (+32 of a 109, +24 of a
  110: elements 0, 12, 21), 16#4000 (element 14).  The cgerr 21 after
  the use-def walk is reached with the frame byte -46 true (each
  `ok := false' jumps straight to the next variable). }

procedure reachingdefinitions;
var
  st: g_opt_stmt_ptr_t;                 { -4 in the image }
  s: g_opt_stmt_ptr_t;                  { -24: init_block's statement }
  blk: g_opt_block_ptr_t;               { -28 }
  v: integer;                           { -32: ftn_data_init's variable }
  bn: g_opt_num_t;                      { -44: init_block's block }
  ok: boolean;                          { -46 }
  i, b, r, r2, last: g_opt_num_t;
  w, conv: integer;
  saved_line: integer;
  s0, d: g_opt_stmt_ptr_t;
  n: il_$node_ptr_t;
  c: g_opt_chain_ptr_t;
  p: rd_def_ptr_t;
  mark: boolean;

  { ftn_data_init - a DATA initializer (il_110's lists from +28, il_118's
    from +36: an entry's +8 the variable, +16 the value) gives variable
    v a constant: the parent's v becomes known with it.

    0x0E4250, 0xC6 bytes: nested, the parent's frame in A1 (from
    init_block too, which passes its own static link). }

  function ftn_data_init(
      n: il_$node_ptr_t): boolean; options(val_param);
  label
    found;
  var
    p, q: il_$node_ptr_t;
  begin
    ftn_data_init := false;
    p := il_110;
    while p <> nil do begin
      q := p^.xp[7];
      while q <> nil do begin
        if q^.xp[2] = n then
          if q^.xp[4]^.kind in [blogical_ob..complex_ob, char_string_ob,
                                char32_string_ob, char16_ob, set_con_ob,
                                rec_const_ob, dpcomplex_ob, binteger_ob] then
            goto found;
        q := q^.xp[1];
      end;
      p := p^.xp[1];
    end;
    p := il_118;
    while p <> nil do begin
      q := p^.xp[9];
      while q <> nil do begin
        if q^.xp[2] = n then
          if q^.xp[4]^.kind in [blogical_ob..complex_ob, char_string_ob,
                                char32_string_ob, char16_ob, set_con_ob,
                                rec_const_ob, dpcomplex_ob, binteger_ob] then
            goto found;
        q := q^.xp[1];
      end;
      p := p^.xp[2];
    end;
    return;
  found:
    seen^[v] := true;
    value^[v] := q^.xp[4];
    ftn_data_init := true;
  end;

  { init_block - the values known at block bn's top from the
    definitions reaching it: a definition storing a constant (for an
    operator that does not read the left side) marks the statement
    (hdr.constant_assign); a call (188) of a Fortran COMMON variable (110, +44 bit
    3) not stored through a pointer takes its DATA value when it has
    one; a marked definition whose value the variable already holds is
    added to its definitions, a first one evaluated (the variable's
    value set by evalforeffect at depth 0); anything else leaves the
    variable known with no value.

    0x0E4316, 0x316 bytes: nested, the parent's frame from the dynamic
    link kept at -24; `bit in' without a range check. }

  procedure init_block;
  var
    w, bit, vv: integer;
    a: il_$node_ptr_t;
  begin
    for w := 1 to rd_used do
      if rd_in^[bn]^[w] <> [] then
        for bit := 0 to 31 do
          if bit in rd_in^[bn]^[w] then begin
            cur := stmt_index_from_rdset(bit, w);
            if (cur >= opt_region) and (cur <= runbackend_16) then begin
              s := opt_4009c[cur];
              vv := s^.hdr.vnum;
              if vv <> 0 then begin
                if (s^.kind = assign_node) and
                   not (s^.asg_op in [add_to_aop..eor_to_aop, set_and_to_aop..set_diff_from_aop, not_to_aop..div_by_aop]) and
                   (s^.asg_rhs^.kind in [blogical_ob..complex_ob,
                                         char_string_ob, char32_string_ob,
                                         char16_ob, set_con_ob, rec_const_ob,
                                         dpcomplex_ob, binteger_ob]) then
                  s^.hdr.constant_assign := true
                else if s^.kind = use_def_ob then
                  if s^.arg_call = nil then begin
                    a := s^.x48;
                    if a^.kind = fortran_symbol then
                      if (ord(a^.xc[44]) & 8) <> 0 then
                        if (opt_4009c[opt_region]^.vars^[vv]^.flags & 16) = 0 then begin
                          case s^.x48^.kind of
                            fortran_symbol:
                              if (ord(s^.x48^.xc[44]) & 8) <> 0 then
                                if (ord(s^.x48^.xc[44]) & 4) = 0 then
                                  if ftn_data_init(s^.x48) then
                                    next;
                            var_name:
                              { var_$initialized as an integer one-bit
                                test: the image loads the longword,
                                `move.l (32,A4),D1; btst #6,D1' (cc.m68k
                                0x0E4540), where `in' tests the byte
                                (codegen-patterns 5.1) }
                              if (integer32(s^.x48^.vr_attr) & 16#40) <> 0 then
                                if ftn_data_init(s^.x48) then
                                  next;
                            otherwise
                          end;
                          seen^[vv] := true;
                          value^[vv] := nil;
                        end;
                  end;
                if s^.hdr.constant_assign then begin
                  if seen^[vv] then begin
                    if value^[vv] = s^.asg_rhs then
                      add_def_stmt(vv)
                    else
                      value^[vv] := nil;
                  end
                  else begin
                    defs^[vv]^.stmt := cur;
                    value^[vv] := nil;
                    evalforeffect(s, 0);
                  end;
                end
                else begin
                  seen^[vv] := true;
                  value^[vv] := nil;
                end;
              end;
            end;
          end;
  end;

begin
  nvars := il_180^.xw[145];
  nvars2 := nvars;
  rd_used := (runbackend_16 - opt_region + nvars2 + 34) div 32;
  if il_180^.xw[145] = 0 then
    return;
  for v := 0 to nvars do begin
    for w := 1 to rd_words do
      var_defs^[v]^[w] := [];
    value^[v] := nil;
    seen^[v] := false;
    defs^[v]^.stmt := 0;
    defs^[v]^.next := nil;
  end;
  for r := opt_region to runbackend_16 do
    if opt_4009c[r]^.hdr.vnum <> 0 then begin
      bset(var_defs^[0], r);
      bset(var_defs^[opt_4009c[r]^.hdr.vnum], r);
    end;
  rd_gen := adjust_ptr(gen_base, 4);
  rd_kill := adjust_ptr(kill_base, 4);
  rd_in := adjust_ptr(in_base, 4);
  zero_bytes(assigned, opt_max_vars + 1);

  { The blocks' gen and kill sets. }
  for b := opt_first_block to opt_last_block do begin
    blk := g_opt_blocks_ptr_t(il_11c)^[b];
    zero_longwords(rd_gen^[b], rd_used);
    zero_longwords(rd_kill^[b], rd_used);
    if blk^.first_stmt <> nil then
      if blk^.last_stmt <> nil then
        if blk^.last_stmt^.hdr.region >= blk^.first_stmt^.hdr.region then begin
          last := blk^.last_stmt^.hdr.region;
          for r := blk^.first_stmt^.hdr.region to last do
            if opt_4009c[r]^.block = blk then begin
              s := opt_4009c[r];
              case s^.kind of
                assign_node:
                  if (s^.asg_lhs^.kind = disp_node) and
                     ((s^.asg_lhs^.xp[7]^.kind = id_ob) or
                      (s^.asg_lhs^.xp[7]^.kind = fortran_symbol) or
                      (s^.asg_lhs^.xp[7]^.kind = var_name)) then begin
                    if s^.hdr.vnum <> 0 then begin
                      genkill(b, r, s^.hdr.vnum);
                      assigned^[s^.hdr.vnum] := true;
                    end;
                    if s^.asg_lhs^.xp[7]^.kind = id_ob then begin
                      for v := 1 to nvars do
                        if opt_4009c[opt_region]^.vars^[v]^.node^.xp[1] =
                           s^.asg_lhs^.xp[7] then
                          opt_4009c[opt_region]^.vars^[v]^.flags :=
                            opt_4009c[opt_region]^.vars^[v]^.flags ! 16;
                    end
                    else begin
                      v := find_var(s^.asg_lhs^.xp[7]);
                      if v <> 0 then
                        opt_4009c[opt_region]^.vars^[v]^.flags :=
                          opt_4009c[opt_region]^.vars^[v]^.flags ! 16;
                    end;
                  end
                  else begin
                    v := s^.hdr.vnum;
                    if v <> 0 then begin
                      genkill(b, r, v);
                      assigned^[v] := true;
                      opt_4009c[opt_region]^.vars^[v]^.flags :=
                        opt_4009c[opt_region]^.vars^[v]^.flags ! 16;
                    end;
                  end;
                label_node, block_entry_node:
                  ;
                otherwise begin
                  v := s^.hdr.vnum;
                  if v <> 0 then begin
                    genkill(b, r, v);
                    mark := true;
                    if s^.kind = use_def_ob then
                      if s^.arg_call = nil then begin
                        n := s^.x48;
                        if n^.kind = fortran_symbol then
                          mark := (var_$display_ptr in n^.fs_attr) or
                                  (n^.xp[7] <> nil) or
                                  (rshft(ord(n^.xc[11]) & 16#F0, 4) <> 1)
                        else if n^.kind = var_name then
                          mark := (n^.vr_vat <> static_vat) or
                                  (var_$display_ptr in n^.vr_attr)
                        else
                          mark := false;
                      end;
                    if mark then begin
                      assigned^[v] := true;
                      opt_4009c[opt_region]^.vars^[v]^.flags :=
                        opt_4009c[opt_region]^.vars^[v]^.flags ! 16;
                    end;
                  end;
                end;
              end;
            end;
        end;
  end;
  compute_rd;
  if cargs_$options.rd then
    dumprd;

  { The known values, block by block. }
  saved_line := il_d0;
  il_d0 := 0;
  for i := opt_first_block to opt_last_block do begin
    bn := opt_dfs_block^[i];
    blk := g_opt_blocks_ptr_t(il_11c)^[bn];
    r := blk^.first_stmt^.hdr.region;
    for v := 1 to nvars do begin
      seen^[v] := false;
      value^[v] := nil;
      defs^[v]^.stmt := 0;
      p := defs^[v]^.next;
      while p <> nil do begin
        p^.stmt := 0;
        p := p^.next;
      end;
    end;
    if blk^.flags.skip then
      for v := 1 to nvars do
        seen^[v] := true
    else
      init_block;
    while opt_4009c[r]^.block = blk do begin
      d := opt_4009c[r];
      if d^.line <> 0 then
        il_d0 := d^.line;
      cur := r;
      if not ((d^.kind = block_entry_node) or (d^.kind = branch_node)
              or (d^.kind = label_node) or
              (d^.kind = nlbranch_node) or (d^.kind = use_def_ob)) then begin
        st := d;
        evalforeffect(st, 32767);
        d := st;
      end;
      if d^.hdr.vnum <> 0 then begin
        v := d^.hdr.vnum;
        if (d^.kind = assign_node) and ((d^.asg_op = fp_aop) or (d^.asg_op = scalar_aop))
            and
           ((d^.asg_lhs^.kind = var_name) or (d^.asg_lhs^.kind = ptr_node) or
            (d^.asg_lhs^.kind = fortran_symbol)) and
           (d^.asg_rhs^.kind in [blogical_ob..complex_ob, char_string_ob,
                                 char32_string_ob, char16_ob, set_con_ob,
                                 rec_const_ob, dpcomplex_ob,
                                 binteger_ob]) then begin
          seen^[v] := false;
          value^[v] := nil;
          st := d;
          evalforeffect(st, 32767);
        end
        else begin
          mark := true;
          if d^.kind = use_def_ob then
            if d^.arg_call = nil then
              if (d^.vars^[v]^.flags & 16) = 0 then begin
                n := d^.x48;
                if n^.kind = fortran_symbol then begin
                  if (ord(n^.xc[44]) & 8) <> 0 then
                    if not assigned^[n^.xw[8]] then
                      if ftn_data_init(d^.x48) then
                        mark := false;
                end
                else if n^.kind = var_name then
                  if (ord(n^.xc[35]) & 16#40) <> 0 then
                    if not assigned^[n^.xw[37]] then
                      if ftn_data_init(d^.x48) then
                        mark := false;
              end;
          if mark then begin
            seen^[v] := true;
            value^[v] := nil;
          end;
        end;
      end;
      r := r + 1;
      if r > runbackend_16 then
        exit;
    end;
  end;
  markuses;
  build_ud_chains;
  if opt_track_lines then begin
    il_d0 := 0;
    return;
  end;

  { The uses no assignment reaches. }
  s0 := opt_4009c[opt_region];
  for v := 1 to nvars do begin
    seen^[v] := false;
    n := s0^.vars^[v]^.node;
    if n^.kind = var_name then begin
      conv := il_180^.blk_atts.call;
      if conv in [3, 4] then
        if n^.xp[1] = il_180^.xp[74] then
          seen^[v] := true;
      if n^.vr_vat = param_vat then
        seen^[v] := true
      else if n^.xp[7]^.kind = param_name then
        if n^.xp[7]^.xw[22] <> 3 then
          seen^[v] := true;
    end;
  end;
  il_d0 := opt_4009c[opt_region - 1]^.line;
  for r := opt_region to runbackend_16 do begin
    d := opt_4009c[r];
    if d^.line <> 0 then
      il_d0 := d^.line;
    if d^.vset <> nil then
      if (d^.vset^ <> []) or (d^.hdr.vnum <> 0) then
        if not ((d^.kind = use_def_ob) and (d^.arg_num > 0) and
                (paramclass(d^.arg_call, d^.arg_num - 1) in [1, 4])) then
          for v := 1 to nvars do
            if v in d^.vset^ then begin
              if d^.hdr.vnum = v then
                if d^.hdr.compiler_generated_stmt or
                   d^.hdr.inliner_generated_stmt then
                  next;
              conv := il_180^.blk_atts.call;
              if conv = 2 then
                { var_$temporary as an integer one-bit test, as the
                  variable's below (`move.l (24,A3),D0; btst #14,D0',
                  0x0E501E) }
                if (integer32(d^.vars^[v]^.node^.fs_attr) & 16#4000) <> 0 then
                  next;
              if conv <> 2 then
                { var_$temporary as an integer one-bit test: `move.l
                  (32,A4),D0; btst #14,D0' (cc.m68k 0x0E5046), where
                  `in' loads the word at +34 (codegen-patterns 5.1) }
                if (integer32(d^.vars^[v]^.node^.vr_attr) & 16#4000) <> 0 then
                  next;
              if (d^.vars^[v]^.ud = nil) and
                 ((s0^.vars^[v]^.flags & 16#80) = 0) and
                 not seen^[v] then begin
                n := s0^.vars^[v]^.node;
                if (conv = 2) and
                   (rshft(ord(n^.xc[44]) & 16#F0, 4) = 3) and
                   ((rshft(ord(n^.xc[11]) & 16#F0, 4) = 5) or
                    ((ord(n^.xc[44]) & 4) <> 0)) then begin
                  seen^[v] := true;
                  s0^.vars^[v]^.flags := s0^.vars^[v]^.flags ! 16#80;
                  next;
                end;
                if n^.kind = var_name then begin
                  if n^.vr_attr * [var_$volatile, var_$address_exposed,
                                   var_$nooptimize] = [] then
                    if not d^.hdr.inliner_generated_stmt then
                      if not statement_contained_by_unreachable_basic_block(d) then
                        cgerr(21, il_d0, d^.vars^[v]^.node);
                end
                else if n^.kind = fortran_symbol then begin
                  if n^.fs_attr * [var_$volatile, var_$address_exposed,
                                   var_$nooptimize] = [] then
                    if not d^.hdr.inliner_generated_stmt then
                      if not statement_contained_by_unreachable_basic_block(d) then
                        cgerr(21, il_d0, d^.vars^[v]^.node);
                end
                else
                  next;
                seen^[v] := true;
                d^.vars^[v]^.flags := d^.vars^[v]^.flags ! 16#400;
                next;
              end;
              if (s0^.vars^[v]^.flags & 16#80) <> 0 then
                next;
              if d^.vars^[v]^.ud = nil then
                next;
              n := d^.vars^[v]^.node;
              if n^.kind = var_name then
                if n^.vr_vat = param_vat then
                  next;
              if n^.kind = var_name then
                if n^.xp[7]^.kind = param_name then
                  if n^.xp[7]^.xw[22] <> 3 then
                    next;
              if conv in [3, 4] then
                if n^.xp[1] = il_180^.xp[74] then
                  next;
              if n^.kind = var_name then
                if n^.vr_attr * [var_$volatile, var_$address_exposed,
                                 var_$nooptimize] <> [] then
                  next;
              if n^.kind = fortran_symbol then begin
                if n^.fs_attr * [var_$volatile, var_$address_exposed,
                                 var_$nooptimize] <> [] then
                  next;
                if (ord(n^.xc[44]) & 4) <> 0 then
                  next;
                if (n^.xw[13] & 16#100) <> 0 then
                  next;
              end;
              c := d^.vars^[v]^.ud;
              ok := true;
              bn := d^.block^.num;
              while c <> nil do begin
                if c^.stmt^.block^.num = bn then begin
                  if c^.stmt^.hdr.region < r then begin
                    ok := false;
                    exit;
                  end;
                  if c^.stmt = d then begin
                    if d^.kind = assign_node then begin
                      n := d^.asg_rhs;
                      if n^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                                     dindex_node..disp_node, cs_node, cc_call,
                                     pf_call, cse_use_ob, sym_disp_node] then
                        if phase_sd_eff in g_opt_tree_ptr_t(n)^.flags then begin
                          ok := false;
                          exit;
                        end;
                    end;
                  end
                  else if conv = 1 then
                    if c^.stmt^.kind = assign_node then
                      if c^.stmt^.hdr.pascal_for_loop then
                        if c^.stmt^.hdr.vnum = v then begin
                          ok := false;
                          exit;
                        end;
                end
                else if not dom(g_opt_blocks_ptr_t(il_11c)^[bn],
                                g_opt_blocks_ptr_t(il_11c)^[c^.stmt^.block^.num]) then begin
                  ok := false;
                  exit;
                end;
                c := c^.next;
              end;
              if ok then begin
                if not statement_contained_by_unreachable_basic_block(d) then
                  cgerr(21, il_d0, d^.vars^[v]^.node);
                d^.vars^[v]^.flags := d^.vars^[v]^.flags ! 16#400;
              end;
            end
            else if d^.hdr.vnum = v then
              seen^[v] := true;
  end;
  if il_180^.blk_atts.call <> call_ftn then
    for v := 1 to nvars do
      if not seen^[v] then begin
        n := s0^.vars^[v]^.node;
        if n^.kind = var_name then
          if n^.xp[7]^.kind = param_name then
            if n^.xp[7]^.xw[22] = 3 then
              if opt_var_types^[v].flags.ranged then
                cgerr(21, opt_4009c[runbackend_16 - 1]^.line, n);
      end;
  il_d0 := saved_line;
end;
