{ cg_top - the m68k code generator's driver: codegen walks each
  routine's statements, compiling them pass after pass until the
  register state at every label is settled, the last pass emitting the
  code (at_backend_506); then the peephole pass and the branches' setup.
  The statements' routines: the routine's entry (block_entry_proc: the
  frame, the saved registers, the parameters copied) and return
  (return_proc), labels (label_proc), conditional branches
  (cbranch_proc), switch tables (case_proc), register lists
  (reg_list_proc).

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0FBC4C  --------  skip_reg_list
    0x0FBC5E  --------  updateregassign
    0x0FBCA8  --------  f_initialize
    0x0FBDDA  --------  initialize
    0x0FBE64  --------  initialize_node
    0x0FC07E  --------  initialize_tree
    0x0FC348  --------  basicblock
    0x0FC47E  --------  reg_list_proc
    0x0FC70C  --------  csetotree
    0x0FC734  --------  case_proc
    0x0FCBCE  --------  cbranch_proc
    0x0FCE84  --------  block_entry_proc
    0x0FD7C0  --------  updatestacksize
    0x0FD968  --------  emit_terminating_line_no
    0x0FD9D8  --------  return_proc
    0x0FE168  --------  label_proc
    0x0FE5B2  --------  emit_a_line_eop
    0x0FE62A  --------  codegen
    A5 0x356314 (cc.m68k), 0x14C bytes: +0 the push operand -(SP)
    (.rwdi: f1 9, f2 15, f3 31), +0x18 the object cache entries a
    register list saves for the next assignment, +0xD8 the floating
    registers' save mask constant, +0xE0 and +0xF8 two operands,
    +0x100 + k for k in 16..23 a floating register holding a double
    (FPA), +0x118 the routine's first statement, +0x11C the code cell
    before its code, +0x124 the cell of the floating save mask's `pea',
    +0x128 the frame slot of the data register, +0x12C (cg_stmt) ..
    +0x148 (at_backend_506): cg.ins.pas's cells and outbin's
    cg_top_130.

  Every routine is nested in codegen but skip_reg_list (internal),
  updateregassign and f_initialize (global).  The statement routines
  that codegen hands a node to by its +4 (`pea (4,A0)': cbranch_proc,
  block_entry_proc, return_proc, cg_assign's assign_proc) take the
  statement from there (top_cbranch_t, top_entry_t, top_return_t).

  emit's generic instructions (docs/questions.md 77, 78) as cg_top uses
  them: 0 move, 1 add, 2 subtract, 18 compare, 20 a conditional branch
  (x the condition), 21 branch, 22 lea, 23 pea, 25 link, 26 unlk, 27
  rts, 32 a label, 34 and 35 movem from and to memory, 37 jmp, 40 the
  jump through a switch table, 41 a switch table's entry, 42 a floating
  branch, 68 fmovem; the operands' modes (f1) 1 register, 2 d(An), 6
  d(PC,Xn) (f3 the index register, f4 its scale).

  Not known from the original: the names of the module's variables
  (but those other units read), of the types, the locals and the
  parameters; the IL statements' fields (by offset). }
module cg_top;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/final.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/lang/source/fpa.ins.pas';
%include 'lang/lang/source/fop.ins.pas';

type
  { A section (il_10c's list, a routine block's +188): its code cells'
    list, from the head cell f_initialize makes, and the last cell. }
  top_sect_ptr_t = ^top_sect_t;
  top_sect_t = record
    unused_0: integer32;                { +0 }
    next: top_sect_ptr_t;               { +4 }
    unused_8: array [1..3] of integer32;  { +8 }
    head: codegen_$cell_ptr_t;          { +20 }
    tail: codegen_$cell_ptr_t;          { +24 }
    c28: array [1..4] of integer32;     { +28: cleared }
  end;

  { A basic block's object cache (g_opt_bb_t's +24): cg_addr's entries
    from +4. }
  top_cache_in_ptr_t = ^top_cache_in_t;
  top_cache_in_t = record
    unused_0: integer32;                { +0 }
    ent: array [0..23] of cg_cache_t;   { +4 }
  end;

  { The line table (+0x130; outbin.pas's outbin_ln_bb_t): each basic
    block's number and first line. }
  top_line_t = record
    blk_no: integer32;                  { +0 }
    line: integer;                      { +4 }
    pad: integer;                       { +6 }
  end;
  top_line_ptr_t = ^array [1..4000] of top_line_t;

  { A register list statement (kind 191): count entries of a register,
    its object and class, and flags (0 the register gets the object, 1
    it holds it live across, 3 store it back, 5 forget it). }
  top_reg_ent_t = record
    obj: il_$node_ptr_t;                { +0 }
    reg: integer;                       { +4: 31 ends the list }
    size: integer;                      { +6 }
    flags: set of 0..15;                { +8 }
    unused_10: integer;                 { +10 }
  end;
  top_reg_list_ptr_t = ^top_reg_list_t;
  top_reg_list_t = record
    unused_0: array [0..24] of integer; { +0 }
    count: integer;                     { +50 }
    ents: array [1..64] of top_reg_ent_t;  { +52 }
  end;

  { A conditional branch statement (kind 142) from its +4. }
  top_cbranch_t = record
    prev: il_$node_ptr_t;               { +4 }
    next: il_$node_ptr_t;               { +8 }
    unused_12: array [1..9] of integer32;  { +12 }
    target: il_$node_ptr_t;             { +48: the label }
    unused_52: integer32;               { +52 }
    cond: il_$node_ptr_t;               { +56: the condition's tree }
    sense: boolean;                     { +60: branch when true }
  end;

  { A routine's (or block's) entry statement (kind 148) from its +4. }
  top_entry_t = record
    prev: il_$node_ptr_t;               { +4 }
    next: il_$node_ptr_t;               { +8 }
    unused_12: array [1..2] of integer32;  { +12 }
    line: integer;                      { +20 }
    unused_22: integer;                 { +22 }
    unused_24: array [1..6] of integer32;  { +24 }
    blk: il_$node_ptr_t;                { +48: the block (172 an inner
                                          block, 167 ...) }
  end;

  { A return statement (kind 151) from its +4. }
  top_return_t = record
    prev: il_$node_ptr_t;               { +4 }
    next: il_$node_ptr_t;               { +8 }
    unused_12: array [1..9] of integer32;  { +12 }
    value: il_$node_ptr_t;              { +48: nil for none }
    size: integer;                      { +52: its class }
  end;

  { The floating registers' save mask as a set constant (setcontk of 8
    bytes): the kind of floating unit, the mask, the save area's
    offset. }
  top_fpsave_t = record
    kind: integer;                      { +0: 1 the 68881, 2 the PEB, 3
                                          the FPA }
    mask: integer;                      { +2 }
    off: integer32;                     { +4 }
  end;

var
  cg_push_ads: codegen_$uads_t := [f1 := 9, f2 := 15, f3 := 31, f4 := 0,
      f5 := 0, f6 := 0, x := 0, y := 0];        { +0: -(SP) }
  cg_top_save: array [0..23] of cg_cache_t;     { +0x18 }
  cg_top_fpsave: top_fpsave_t;                  { +0xD8 }
  cg_top_e0: codegen_$uads_t;                   { +0xE0 }
  cg_top_f8: codegen_$uads_t;                   { +0xF8 }
  cg_top_fp_long: array [16..23] of boolean;    { +0x110: from +0x100 +
                                                  16; initialize clears
                                                  18..23 }
  cg_top_118: il_$node_ptr_t;                   { +0x118 }
  cg_top_11c: codegen_$cell_ptr_t;              { +0x11C }
  cg_top_124: codegen_$cell_ptr_t;              { +0x124 }
  cg_top_128: integer32;                        { +0x128 }
  cg_top_130: extern top_line_ptr_t;            { +0x130: outbin.pas
                                                  declares it }
  cg_top_138: integer;                          { +0x138: the statement's
                                                  line }
  cg_top_13c: cg_count_t;                       { +0x13C: the routine's
                                                  first block number }
  cg_top_13e: cg_count_t;                       { +0x13E: the current
                                                  block number }

define
  cg_stmt, cg_code_bytes, cg_top_13a, cg_data_reg, cg_pass, cg_line,
  cg_settled, at_backend_506, cg_top_130,
  updateregassign, f_initialize, codegen;

{ skip_reg_list - the statement after n, past register lists (191).

  0x0FBC4C, 0x12 bytes: no frame (docs/rev889-patterns.md 16); the
  pointer stepped in A0, the result.  Not known from the original:
  whether a local (p) or the parameter was stepped. }

function skip_reg_list(
    n: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  p: il_$node_ptr_t;
begin
  p := n;
  repeat
    p := p^.xp[2];
  until p^.kind <> 191;
  skip_reg_list := p;
end;

{ updateregassign - the object cache entries reg_list_proc kept back
  for the assignment that follows a register list put into cg_addr's
  cache (object and class) and dropped.

  0x0FBC5E, 0x4A bytes: `dbf' of 24. }

procedure updateregassign;
var
  i: integer;
begin
  for i := 0 to 23 do
    if cg_top_save[i].obj <> nil then begin
      cg_addr_cache[i].obj := cg_top_save[i].obj;
      cg_addr_cache[i].size := cg_top_save[i].size;
      cg_top_save[i].obj := nil;
    end;
end;

{ f_initialize - the code generator set up for a compilation: the
  cells' pools, each section's cell list (a head cell, getcodecell(1)),
  cg_misc's label, the immediate 0 (cg_zero_ads), cg_tree's 147 node,
  the object caches (D registers class 4, A registers 5, the others 0)
  and cg_addr's 181 node.

  0x0FBCA8, 0x130 bytes: the cell kind 1 a word after the routine
  (0x0FBDD8), passed by address; the section's +20 and +24 stored from
  A0. }

procedure f_initialize;
var
  s: top_sect_ptr_t;
  i: integer;
begin
  init_celpkg;
  s := il_10c;
  while s <> nil do begin
    s^.head := getcodecell(1);
    s^.tail := s^.head;
    s^.c28[1] := 0;
    s^.c28[2] := 0;
    s^.c28[3] := 0;
    s^.c28[4] := 0;
    s := s^.next;
  end;
  cg_misc_label := create_temp_label;
  address(smcontk(81, 0), 0, cg_zero_ads);
  cg_tree_1b4 := gspace(36);
  cg_tree_1b4^.kind := 147;
  cg_tree_1b4^.xp[6] := nil;
  cg_tree_1b4^.xp[7] := nil;
  cg_tree_1b4^.xp[1] := nil;
  for i := 0 to 23 do begin
    cg_addr_cache[i].obj := nil;
    if i < 8 then
      cg_addr_cache[i].size := 4
    else if i < 16 then
      cg_addr_cache[i].size := 5
    else
      cg_addr_cache[i].size := 0;
    cg_addr_cache[i].param_alias := false;
    cg_top_save[i].obj := nil;
    cg_top_save[i].size := 0;
    cg_top_save[i].param_alias := false;
    cg_top_save[i].b6 := chr(0);
  end;
  cg_addr_2ac := gspace(4);
  cg_addr_2ac^.kind := 181;
  cg_code_bytes := 0;
end;

{ codegen - the code of every routine: for each, from its first
  statement (IL's il_d4 chain through +8), passes over the statements
  until a pass ends with the register state settled (cg_settled),
  then a last pass that emits (at_backend_506); each statement's line
  noted, the registers' records checked (objects a statement changes
  forgotten, locks left over reported, cgerr 4) and the statement
  compiled by its kind; at the routine's end (149) the frame's size
  and saves settled and its line emitted; then the peephole pass and
  the branches' setup, and the section's last cell, the blocks' table
  and the line table kept in the block.  The optimizer's pool emptied
  at the end.

  0x0FE62A, 0x972 bytes: cg_top_13e the line table loop's index
  (docs/rev889-patterns.md 43); the kinds' set at 0x0FEF9C (gap 8);
  'FP stack is not empty' at 0x0FEFB8 a varying string; the routine's
  end jumps to the pass loop's head directly when the pass does not
  emit (the `until' threaded); the registers' loop index (-12) is also
  initialize's loop index and an expression's register.  Not known
  from the original: how the statement loop was left (`exit' here). }

procedure codegen;
var
  nxt: il_$node_ptr_t;                  { -4 }
  size: integer;                        { -10 }
  r: integer;                           { -12 }
  movem_min: integer;                   { -14: the fewest registers
                                          saved with movem }
  k: integer;
  lab: il_$node_ptr_t;
  p: il_$node_ptr_t;

  { initialize - a pass begun: the registers and temporaries
    forgotten, the floating stack empty, no PEB operation pending,
    movem from 3 registers with -CPU MATHLIB (else 4); the first pass
    also clears the floating registers' double marks.

    0x0FBDDA, 0x88 bytes: codegen's locals through the dynamic link
    (`movea.l (A6),A2'; docs/rev889-patterns.md 25), -12 as the loop's
    index. }

  procedure initialize;
  begin
    cg_addr_$init_regs(false);
    cg_addr_2ba := 0;
    init_temp;
    cg_top_128 := 0;
    if 9 in cargs_$options.cpu then
      movem_min := 3
    else
      movem_min := 4;
    cg_fp_count := 0;
    cg_fp_result := nil;
    cg_fp_long := false;
    init_peb;
    if cg_pass = 1 then
      for r := 18 to 23 do
        cg_top_fp_long[r] := false;
  end;

  { initialize_node - the trees under node n made ready for a pass:
    each value tree's (137, 138 made 137, 143) use count (+16) from
    its count of uses (+18; the first pass copies +16 to +18 and sets
    the register +10 to 31 none; the last restores +16 only), through
    lists (152, 190, 171, 175), conditional and comma nodes (145,
    146, 147, 164); a variable's (109, 110) bit 0 cleared at the first
    pass, a label's +80 cleared.

    0x0FBE64, 0x21A bytes: a loop over the list's links (`bra' back to
    the case), the recursion on the operands; abs as `bpl', `neg'. }

  procedure initialize_node(
      n: il_$node_ptr_t); options(val_param);
  var
    i: integer;
  begin
    repeat
      case n^.kind of
        152: n := n^.xp[4];
        190: n := n^.xp[1];
        138, 143, 137: begin
          if n^.kind = 138 then
            n^.kind := 137;
          for i := 1 to cg_tree_ptr_t(n)^.count do
            initialize_node(cg_tree_ptr_t(n)^.opnd[i]);
          if cg_pass = 1 then begin
            n^.xw[5] := 31;
            cg_tree_ptr_t(n)^.w18 := cg_tree_ptr_t(n)^.uses;
          end
          else if at_backend_506 then
            cg_tree_ptr_t(n)^.uses := abs(cg_tree_ptr_t(n)^.w18)
          else begin
            cg_tree_ptr_t(n)^.uses := abs(cg_tree_ptr_t(n)^.w18);
            cg_tree_ptr_t(n)^.w18 := cg_tree_ptr_t(n)^.uses;
          end;
          exit;
        end;
        144: begin
          n^.xl[20] := 0;
          exit;
        end;
        147, 146: begin
          if cg_pass = 1 then begin
            cg_tree_ptr_t(n)^.w18 := cg_tree_ptr_t(n)^.uses;
            n^.xw[5] := 31;
          end
          else if at_backend_506 then
            cg_tree_ptr_t(n)^.uses := abs(cg_tree_ptr_t(n)^.w18)
          else begin
            cg_tree_ptr_t(n)^.uses := abs(cg_tree_ptr_t(n)^.w18);
            cg_tree_ptr_t(n)^.w18 := cg_tree_ptr_t(n)^.uses;
          end;
          n := n^.xp[6];
        end;
        145: begin
          initialize_node(n^.xp[6]);
          if cg_pass = 1 then begin
            cg_tree_ptr_t(n)^.w18 := cg_tree_ptr_t(n)^.uses;
            n^.xw[5] := 31;
          end
          else if at_backend_506 then
            cg_tree_ptr_t(n)^.uses := abs(cg_tree_ptr_t(n)^.w18)
          else begin
            cg_tree_ptr_t(n)^.uses := abs(cg_tree_ptr_t(n)^.w18);
            cg_tree_ptr_t(n)^.w18 := cg_tree_ptr_t(n)^.uses;
          end;
          n := n^.xp[9];
        end;
        164: begin
          initialize_node(n^.xp[5]);
          if cg_pass = 1 then begin
            cg_tree_ptr_t(n)^.w18 := cg_tree_ptr_t(n)^.uses;
            n^.xw[5] := 31;
          end
          else if at_backend_506 then
            cg_tree_ptr_t(n)^.uses := abs(cg_tree_ptr_t(n)^.w18)
          else begin
            cg_tree_ptr_t(n)^.uses := abs(cg_tree_ptr_t(n)^.w18);
            cg_tree_ptr_t(n)^.w18 := cg_tree_ptr_t(n)^.uses;
          end;
          n := n^.xp[6];
        end;
        171: n := n^.xp[4];
        175: n := n^.xp[4];
        109: begin
          if cg_pass = 1 then
            n^.xc[32] := chr(ord(n^.xc[32]) & 16#FE);
          exit;
        end;
        110: begin
          if cg_pass = 1 then
            n^.xc[24] := chr(ord(n^.xc[24]) & 16#FE);
          exit;
        end;
        otherwise
          exit;
      end;
    until false;
  end;

  { initialize_tree - the routine's statements made ready for a pass,
    up to its end (a 149 not of an inner block): each statement's trees
    (initialize_node for the kinds it handles); a label's state marked
    not reached (and its saved copy dropped at the first pass); at the
    routine's entry (148, not of an inner block) il_180 set and, at the
    first pass, no registers saved, the data reached through A5 (13),
    cg_addr's free set 0..23 and no register killed, and with basic
    blocks the routine's first block's free registers those common to
    its predecessors (select_block_list), a loop's head's those common
    to the loop (select_loop), cg_addr_2b0 less the first block's.

    0x0FC07E, 0x29A bytes: a jump table of 12 on the kind less 139;
    the sets at 0x0FC318 and 0x0FC330 (gap 8: the second without 144);
    [2..7, 10..12, 18..23] as #0xFC1CFC; il_11c's blocks from 1
    (`-4(A1,D2.l)'). }

  procedure initialize_tree;
  var
    t: il_$node_ptr_t;
    b: il_$node_ptr_t;
    i: integer;
    j: integer;
    s: cg_regset_t;
    l: g_opt_bb_ptr_t;
    bb: g_opt_bb_ptr_t;
  begin
    t := cg_top_118;
    repeat
      if t^.kind = 149 then
        if t^.xp[12]^.kind <> 172 then
          exit;
      case t^.kind of
        139:
          for i := 1 to t^.xw[25] do
            if t^.xp[12 + i]^.kind in [109, 110, 137, 138, 143, 144, 145,
                146, 147, 152, 164, 171, 175, 190] then
              initialize_node(t^.xp[12 + i]);
        140: begin
          if t^.xp[17]^.kind in [109, 110, 137, 138, 143, 144, 145, 146,
              147, 152, 164, 171, 175, 190] then
            initialize_node(t^.xp[17]);
          if t^.xp[16]^.kind in [109, 110, 137, 138, 143, 144, 145, 146,
              147, 152, 164, 171, 175, 190] then
            initialize_node(t^.xp[16]);
          if t^.xp[18] <> nil then
            if t^.xp[18]^.kind in [109, 110, 137, 138, 143, 144, 145, 146,
                147, 152, 164, 171, 175, 190] then
              initialize_node(t^.xp[18]);
        end;
        142:
          if t^.xp[14]^.kind in [109, 110, 137, 138, 143, 144, 145, 146,
              147, 152, 164, 171, 175, 190] then
            initialize_node(t^.xp[14]);
        144: begin
          if t^.xp[16] <> nil then
            cg_state_ptr_t(t^.xp[16])^.b7 := false;
          if cg_pass = 1 then
            t^.xp[17] := nil;
        end;
        148: begin
          b := t^.xp[12];
          if (b^.kind <> 167) and (b^.kind <> 172) then begin
            il_180 := b;
            if cg_pass = 1 then begin
              cg_blk_regs_ptr_t(b)^.saved := [];
              cg_data_reg := 13;
              cg_addr_2b0 := [0..23];
              for i := 0 to 31 do
                cg_addr_killed[i] := false;
              if il_124 <> 0 then begin
                s := [2..7, 10..12, 18..23];
                l := g_opt_bb_ptr_t(select_block_list(cg_top_13e + 1, cg_top_13e));
                while l <> nil do begin
                  s := s * l^.regs;
                  l := l^.next;
                end;
                g_opt_bb_list_ptr_t(il_11c)^[cg_top_13e + 1]^.regs := s;
                cg_addr_2b0 := cg_addr_2b0 - s;
                for j := cg_top_13e + 2 to il_124 do begin
                  bb := g_opt_bb_list_ptr_t(il_11c)^[j];
                  if not odd(rshft(ord(bb^.flags), 3)) and
                      odd(rshft(ord(bb^.flags), 2)) then begin
                    l := g_opt_bb_ptr_t(select_loop(bb^.loop^^.head));
                    s := bb^.regs;
                    while l <> nil do begin
                      s := s * l^.regs;
                      l := l^.next;
                    end;
                    bb^.regs := s;
                  end;
                end;
              end;
            end;
          end;
        end;
        150:
          if t^.xp[12]^.kind in [109, 110, 137, 138, 143, 145, 146, 147,
              152, 164, 171, 175, 190] then
            initialize_node(t^.xp[12]);
        otherwise ;
      end;
      t := t^.xp[2];
    until false;
  end;

  { basicblock - the next basic block begun: its first line noted in
    the line table; the object cache emptied when no registers carry
    into it, else taken from the block's (each register given its
    object again, unless it holds it already: setresult; the record's
    second object and w8 set, the entry marked).

    0x0FC348, 0x136 bytes: the cache entries copied as two longwords
    from the block's (+4 + 8k). }

  procedure basicblock;
  var
    bb: g_opt_bb_ptr_t;
    i: integer;
  begin
    cg_top_13e := cg_top_13e + 1;
    if cg_top_130 <> nil then
      cg_top_130^[cg_top_13e].line := cg_line;
    bb := g_opt_bb_list_ptr_t(il_11c)^[cg_top_13e];
    if bb^.regs_in = nil then
      for i := 0 to 23 do begin
        cg_addr_cache[i].obj := nil;
        cg_addr_cache[i].param_alias := false;
      end;
    if bb^.cache_in = nil then
      for i := 0 to 23 do begin
        cg_addr_cache[i].obj := nil;
        cg_addr_cache[i].param_alias := false;
      end
    else
      for i := 0 to 23 do begin
        cg_addr_cache[i] := top_cache_in_ptr_t(bb^.cache_in)^.ent[i];
        if cg_addr_cache[i].obj <> nil then begin
          if (cg_addr_regs[i].size = top_cache_in_ptr_t(bb^.cache_in)^.ent[i].size) and
              ((top_cache_in_ptr_t(bb^.cache_in)^.ent[i].obj = cg_addr_regs[i].obj) or
              (top_cache_in_ptr_t(bb^.cache_in)^.ent[i].obj = cg_addr_regs[i].obj2)) then
            cg_addr_regs[i].w14 := 0
          else
            setresult(i, top_cache_in_ptr_t(bb^.cache_in)^.ent[i].obj,
                top_cache_in_ptr_t(bb^.cache_in)^.ent[i].size);
          cg_addr_regs[i].obj2 := top_cache_in_ptr_t(bb^.cache_in)^.ent[i].obj;
          cg_addr_regs[i].w8 := cg_addr_2ba;
          cg_addr_cache[i].param_alias := true;
        end;
      end;
  end;

  { reg_list_proc - register list n (191): first each entry to store
    back (flag 3, its register still holding the object: the value
    moved to the object, cgerr 23 when another register holds it) or
    forget (5); then each entry giving a register its object (0: the
    cache entry set, or kept back in cg_top_save when the next
    statement assigns that object; the register killed; another
    register holding the object forgotten) or holding it live (1:
    load_live_registers after the list).  A D register's class 5
    becomes 4.  An entry of register 31 ends either loop.

    0x0FC47E, 0x28E bytes: the flags a word (`and.w #40', `btst #3' of
    its low byte); the second loop counted in a frame word (`subq.w
    #1; bcc'); cargs' address loaded and not used (docs/rev889-
    patterns.md 53). }


  procedure reg_list_proc(
      n: il_$node_ptr_t); options(val_param);
  var
    a: codegen_$uads_t;                 { -24 }
    v: codegen_$uads_t;                 { -48 }
    nx: il_$node_ptr_t;                 { -56 }
    size: integer;                      { -62 }
    live: boolean;                      { -68 }
    i: integer;
    reg: integer;
    x: integer;
    obj: il_$node_ptr_t;
    keep: boolean;
    l: top_reg_list_ptr_t;
  begin
    l := top_reg_list_ptr_t(n);
    for i := 1 to l^.count do begin
      reg := l^.ents[i].reg;
      if reg = 31 then
        exit;
      if l^.ents[i].flags * [3, 5] <> [] then begin
        obj := l^.ents[i].obj;
        size := l^.ents[i].size;
        if obj^.kind = 190 then
          obj := obj^.xp[1];
        if cg_addr_cache[reg].obj = obj then begin
          if 3 in l^.ents[i].flags then begin
            address(obj, 0, v);
            if peek(obj, size) <> reg then
              cgerr(23, cg_line, obj);
            address_reg(reg, a);
            if (8 in cargs_$options.cpu) and ((v.f1 = 13) or (a.f1 = 13)) then
              emit_assign(size, v, a)
            else
              emit(0, size, v, a, 0);
            unlock(v);
          end;
          if 5 in l^.ents[i].flags then begin
            cg_addr_cache[reg].obj := nil;
            cg_addr_cache[reg].param_alias := false;
          end;
        end;
      end;
    end;
    live := false;
    nx := skip_reg_list(n);
    for i := 1 to l^.count do begin
      reg := l^.ents[i].reg;
      if reg = 31 then
        exit;
      if l^.ents[i].flags * [0, 1] <> [] then begin
        obj := l^.ents[i].obj;
        size := l^.ents[i].size;
        if obj^.kind = 190 then
          obj := obj^.xp[1];
        if 1 in l^.ents[i].flags then
          keep := false
        else if (nx^.kind = 140) and (nx^.xp[16] = obj) then
          keep := true
        else
          keep := false;
        if (size = 5) and (reg in [0..7]) then
          size := 4;
        if 0 in l^.ents[i].flags then begin
          x := chk_assign(obj, size);
          if (x <> reg) and (x <> 31) then begin
            cg_addr_cache[x].obj := nil;
            cg_addr_cache[x].param_alias := false;
          end;
          if keep then begin
            cg_top_save[reg].obj := obj;
            cg_top_save[reg].size := size;
            cg_top_save[reg].param_alias := false;
            cg_top_save[reg].b6 := chr(0);
          end
          else begin
            cg_addr_cache[reg].obj := obj;
            cg_addr_cache[reg].size := size;
            cg_addr_cache[reg].param_alias := false;
            cg_addr_cache[reg].b6 := chr(0);
          end;
          cg_addr_killed[reg] := true;
          setobjcache(l^.ents[i].obj, reg);
        end;
        if 1 in l^.ents[i].flags then begin
          cg_addr_cache[reg].obj := obj;
          cg_addr_cache[reg].size := size;
          cg_addr_cache[reg].b6 := chr(255);
          cg_addr_cache[reg].param_alias := false;
          live := true;
        end;
      end;
    end;
    if live then
      load_live_registers;
  end;

  { csetotree - the tree of common subexpression n (nil stays nil):
    through a 190's +4 or a 189's +20.

    0x0FC70C, 0x28 bytes: no frame, the parameter at (4,SP) and the
    result in A0 (docs/rev889-patterns.md 16). }

  function csetotree(
      n: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
  var
    p: il_$node_ptr_t;
  begin
    p := n;
    if p <> nil then
      case p^.kind of
        190: p := p^.xp[1];
        189: p := p^.xp[5];
        otherwise ;
      end;
    csetotree := p;
  end;

  { case_proc - a switch as a jump table: when statement cur (an
    expression list's first expression, a 138 of op 17 used at least 4
    times) is followed by as many conditional branches (142, on an
    equality 143 of that expression with a constant, operands swapped
    when the constant comes first) and the constants' range is
    positive, under 4096 and at most 4 per case less 5, the register
    lists between are done, the default label is the goto after them
    (141) or a new one, the table of the range's labels built, the
    selector less the lowest constant compared unsigned (18, branch 4
    to the default), and `move.w (6,PC,Xn*2),Xn; jmp (2,PC,Xn)' (the
    index doubled with an add on the 68000) with the table's entries
    (41) after its label; each target's state merged, the default
    label's defined here when new; the expression's uses cleared and
    cur advanced to the statement before the last branch.

    0x0FC734, 0x49A bytes: cur by address (codegen's cg_stmt); maxint
    and -maxint - 1 as the bounds' start; the table from gspace of
    (range + 1) * 4 bytes; a new default label's field at +72 bits 5..1
    set to 14 (`andi.b #0xC1; or.b #28'); il_11c reached as +92 from
    il_c0's address (docs/rev889-patterns.md 53). }

  procedure case_proc(
      var cur: il_$node_ptr_t);
  type
    tab_t = array [0..4095] of il_$node_ptr_t;
  var
    lab_a: codegen_$uads_t;             { -24 }
    t: codegen_$uads_t;                 { -48 }
    sel: codegen_$uads_t;               { -72 }
    s: il_$node_ptr_t;                  { -76 }
    deflab: il_$node_ptr_t;             { -92 }
    tablab: il_$node_ptr_t;             { -108 }
    nx: il_$node_ptr_t;                 { -112 }
    size: integer;                      { -116 }
    lo: integer32;
    hi: integer32;
    range: integer32;
    v: integer32;
    n: integer;
    i: integer;
    c: il_$node_ptr_t;
    q: il_$node_ptr_t;
    is_goto: boolean;
    tab: ^tab_t;
  begin
    if cur = nil then
      return;
    if cur^.kind = 139 then
      if cur^.xw[25] = 0 then
        return;
    s := csetotree(cur^.xp[13]);
    if s^.kind <> 138 then
      return;
    if cg_tree_ptr_t(s)^.uses < 4 then
      return;
    if cg_tree_ptr_t(s)^.op <> 17 then
      return;
    lo := 2147483647;
    hi := -2147483647 - 1;
    nx := skip_reg_list(cur);
    for i := 1 to cg_tree_ptr_t(s)^.uses do begin
      if nx^.kind <> 142 then
        return;
      if ord(nx^.xc[60]) < 128 then     { the sense false }
        return;
      c := nx^.xp[14];
      if c^.kind <> 143 then
        return;
      if csetotree(cg_tree_ptr_t(c)^.opnd[1]) = s then begin
        q := cg_tree_ptr_t(c)^.opnd[1];
        cg_tree_ptr_t(c)^.opnd[1] := cg_tree_ptr_t(c)^.opnd[2];
        cg_tree_ptr_t(c)^.opnd[2] := q;
      end
      else if csetotree(cg_tree_ptr_t(c)^.opnd[2]) <> s then
        return;
      v := cg_tree_ptr_t(c)^.opnd[1]^.int_value;
      if v < lo then
        lo := v;
      if v > hi then
        hi := v;
      nx := skip_reg_list(nx);
    end;
    range := hi - lo;
    if range >= 4096 then
      return;
    if range <= 0 then
      return;
    if cg_tree_ptr_t(s)^.uses * 4 - 5 < range then
      return;
    n := range;
    q := cur;
    repeat
      q := q^.xp[2];
      if q^.kind = 191 then
        reg_list_proc(q);
    until q^.xp[2] = nx;
    is_goto := nx^.kind = 141;
    if is_goto then begin
      deflab := nx^.xp[12];
      nx := skip_reg_list(nx);
    end
    else
      deflab := templabel;
    tab := gspace((n + 1) * 4);
    for i := 0 to n do
      tab^[i] := deflab;
    c := skip_reg_list(cur);
    for i := 1 to cg_tree_ptr_t(s)^.uses do begin
      tab^[cg_tree_ptr_t(c^.xp[14])^.opnd[1]^.xw[5] - lo] := c^.xp[12];
      c := skip_reg_list(c);
    end;
    size := cg_tree_ptr_t(s)^.desc.rlen;
    address(s, size, sel);
    release(sel);
    kill_register(sel.f2);
    if lo <> 0 then begin
      anyconst(abs(lo), size, t);
      if lo > 0 then
        emit(2, size, sel, t, 0)
      else
        emit(1, size, sel, t, 0);
      unlock(t);
    end;
    anyconst(range + 1, size, t);
    emit(18, size, sel, t, 0);
    unlock(t);
    address(deflab, 0, t);
    emit(20, 5, t, cg_null_ads, 4);
    tablab := templabel;
    address(tablab, 0, t);
    t.f1 := 6;
    t.y := 6;
    t.f4 := 0;
    if 3 in cargs_$options.cpu then
      t.f4 := 1
    else
      emit(1, 2, sel, sel, 0);
    t.f3 := sel.f2;
    emit(0, 2, sel, t, 0);
    t.y := 2;
    t.f4 := 0;
    emit(40, 5, t, cg_null_ads, 0);
    address(tablab, 0, t);
    emit(32, 5, t, cg_null_ads, 0);
    for i := 0 to n do begin
      address(tab^[i], 0, lab_a);
      emit(41, 5, lab_a, t, 0);
      if tab^[i] <> deflab then
        merge_state(tab^[i]);
    end;
    if is_goto then
      merge_state(deflab)
    else begin
      deflab^.xc[72] := chr(ord(deflab^.xc[72]) & 16#C1 ! 28);
      address(deflab, 0, t);
      emit(32, 5, t, cg_null_ads, 0);
    end;
    cg_tree_ptr_t(s)^.uses := 0;
    repeat
      cur := cur^.xp[2];
      if odd(rshft(ord(cur^.xc[42]), 1)) and (il_11c <> nil) then
        basicblock;
    until cur^.xp[2] = nx;
  end;

  { cbranch_proc - conditional branch b: an integer constant's test
    decided here (a branch, 21, when its truth is the sense); another
    tree's value tested as a byte (18 with the immediate 0, branch 11
    or 10); a comparison (143, walker) by its condition (the tree's
    desc.w8, negative for the unsigned forms: abs; reversed when the
    sense is false), with the FPA's unordered conditions (7, 13, 14
    make 5 and the others 4) when the comparison is the floating one
    cg_fp_1000 names or of a double (desc.w6 8 or 12), and 6 or 7 for
    an FPA value tree of those classes; the branch (20, or 42 for a
    68881 comparison) omitted to the next statement; the target's
    state merged and the floating stack emptied.

    0x0FCBCE, 0x29C bytes: the statement from codegen's node + 4; the
    constants' set at 0x0FCE6A (gap 8); the condition zero-extended
    for emit's x. }

  procedure cbranch_proc(
      in out b: univ top_cbranch_t);
  var
    t: codegen_$uads_t;                 { -24 }
    cc: integer;
  begin
    cg_fp_1000 := nil;
    if b.cond^.kind <> 143 then begin
      tree_walk(b.cond);
      if b.cond^.kind in [77..87, 101, 200] then begin
        address(b.target, 0, t);
        if (ord(b.cond^.xc[11]) >= 128) = b.sense then begin
          emit(21, 5, t, cg_null_ads, 0);
          merge_state(b.target);
        end;
        return;
      end;
      if b.sense then
        cc := 11
      else
        cc := 10;
      address(b.cond, 1, cg_top_e0);
      emit(18, 1, cg_top_e0, cg_zero_ads, 0);
      release(cg_top_e0);
    end
    else begin
      walker(b.cond);
      cc := 4;
      if b.sense then begin
        if (8 in cargs_$options.cpu) and ((cg_fp_1000 = b.cond) or
            (cg_tree_ptr_t(b.cond)^.desc.w6 = 12) or
            (cg_tree_ptr_t(b.cond)^.desc.w6 = 8)) then begin
          if (cg_tree_ptr_t(b.cond)^.desc.w8 = 7) or
              (cg_tree_ptr_t(b.cond)^.desc.w8 = 14) or
              (cg_tree_ptr_t(b.cond)^.desc.w8 = 13) then
            cc := 5;
        end
        else
          cc := abs(cg_tree_ptr_t(b.cond)^.desc.w8);
      end
      else begin
        if (8 in cargs_$options.cpu) and ((cg_fp_1000 = b.cond) or
            (cg_tree_ptr_t(b.cond)^.desc.w6 = 12) or
            (cg_tree_ptr_t(b.cond)^.desc.w6 = 8)) then begin
          if not ((cg_tree_ptr_t(b.cond)^.desc.w8 = 14) or
              (cg_tree_ptr_t(b.cond)^.desc.w8 = 13) or
              (cg_tree_ptr_t(b.cond)^.desc.w8 = 7)) then
            cc := 5;
        end
        else
          cc := reverse_cc(abs(cg_tree_ptr_t(b.cond)^.desc.w8));
      end;
    end;
    if (8 in cargs_$options.cpu) and ((cg_tree_ptr_t(b.cond)^.desc.w6 = 12) or
        (cg_tree_ptr_t(b.cond)^.desc.w6 = 8)) then
      if (b.cond^.kind = 137) or (b.cond^.kind = 143) or
          (b.cond^.kind = 138) then
        if cc = 4 then
          cc := 6
        else
          cc := 7;
    address(b.target, 0, t);
    if b.target <> b.next then
      if (cg_fp_1000 = b.cond) and not (8 in cargs_$options.cpu) then
        emit(42, 5, t, cg_null_ads, cc)
      else
        emit(20, 5, t, cg_null_ads, cc);
    merge_state(b.target);
    if cg_fp_count <> 0 then
      purge_fp;
  end;

  { block_entry_proc - the entry of routine block e.blk (an inner
    block, 172, only gets its line in the last pass): il_180 set, the
    entry's line cell moved before the previous cell; a routine whose
    first statement returns its result gets an `rts' (27) first; the
    registers forgotten and A1 given the display (level > 0 with +292);
    the callee-saved registers left alone (+216) from those killed, A5
    among them unless the block needs its own (+375 bit 3 and +376 bit
    4, the data reached through A0 when A0 is free); the floating
    registers' save mask pushed (a `pea' of the immediate 0 that codegen
    patches at the end, or 0); `link' (25); the stack adjusted by +176
    (rounded to 4 with -ALIGN) on the 68000; the saved registers pushed
    (the floating ones by fmovem with the 68881, one by one with the
    PEB or FPA, the general ones one by one under movem_min, else by
    movem); the data register set up (A0, or lea of the block's +192)
    and kept in the frame for a nested goto target (+376 bit 6); the
    parameters copied (+180's list: lea of the arguments, each moved,
    from a register stepped by the offsets' differences).

    0x0FCE84, 0x93C bytes: codegen's frame kept at -236 for movem_min;
    the sets as #0xFC3CFC and #0xFC1CFC; the two flags' test a longword
    (+374, `lsr.l #8; lsr.l #3; andi.l #258'), the second test of it
    redundant; A1's lock count raised around get_register; the floating
    mask's bits in a word zero-extended. }

  procedure block_entry_proc(
      in out e: univ top_entry_t);
  var
    zero: codegen_$uads_t;              { -24 }
    sp_a: codegen_$uads_t;              { -48 }
    ra: codegen_$uads_t;                { -96 }
    a: codegen_$uads_t;                 { -120 }
    kc: codegen_$uads_t;                { -144 }
    fr: codegen_$uads_t;                { -192 }
    saves: cg_regset_t;                 { -200 }
    nbytes: integer32;                  { -204 }
    b: top_sect_ptr_t;
    c: codegen_$cell_ptr_t;
    last: codegen_$cell_ptr_t;
    i: integer;
    n: integer;
    m: cg_count_t;
    mask: cg_count_t;
    bit: cg_count_t;
    first: boolean;
    prev: integer32;
    v: integer32;
    p: il_$node_ptr_t;
    g: il_$node_ptr_t;
  begin
    if e.blk^.kind = 172 then begin
      if at_backend_506 then begin
        address(e.blk, 0, a);
        emit_line_eop(cg_null_ads, a, e.line);
      end;
      return;
    end;
    cg_top_124 := nil;
    if e.blk^.kind <> 167 then begin
      il_180 := e.blk;
      cg_addr_2a8 := nil;
      cg_top_13a := 0;
      if at_backend_506 then begin
        address(e.blk, 0, a);
        emit_line_eop(cg_null_ads, a, e.prev^.xw[10]);
        b := top_sect_ptr_t(il_180^.xp[47]);
        c := b^.tail;
        last := c^.prev;
        delink(c);
        after(last^.prev, b^.tail);
        b^.tail := last;
      end;
    end;
    if (e.next^.kind = 151) and (e.next^.xp[12] = il_180^.xp[24]) and
        (cargs_$options.db <> 3) and at_backend_506 then begin
      emit_line_eop(cg_null_ads, cg_null_ads, e.next^.xw[10]);
      b := top_sect_ptr_t(il_180^.xp[47]);
      c := b^.tail;
      last := c^.prev;
      delink(c);
      after(last^.prev, b^.tail);
      b^.tail := last;
      emit(27, 5, cg_null_ads, cg_null_ads, 0);
    end;
    cg_addr_$init_regs(false);
    if cg_level_ptr_t(il_180)^.level > 0 then
      if ord(il_180^.xc[292]) <> 0 then begin
        cg_addr_killed[9] := true;
        setresult(9, il_node_155, 5);
      end;
    cg_blk_regs_ptr_t(il_180)^.unused := [2..7, 10..13, 18..23];
    for i := 2 to 23 do
      if cg_addr_killed[i] then
        cg_blk_regs_ptr_t(il_180)^.unused :=
            cg_blk_regs_ptr_t(il_180)^.unused - [i];
    il_180^.xc[375] := chr(ord(il_180^.xc[375]) ! 8);
    if (rshft(il_180^.xl2[93], 11) & 258) <> 258 then
      cg_blk_regs_ptr_t(il_180)^.unused :=
          cg_blk_regs_ptr_t(il_180)^.unused + [13]
    else if ((rshft(il_180^.xl2[93], 11) & 258) = 258) and
        at_backend_506 and not cg_addr_killed[8] and
        (cargs_$options.db <= 1) then
      cg_blk_regs_ptr_t(il_180)^.unused :=
          cg_blk_regs_ptr_t(il_180)^.unused + [13]
    else
      cg_blk_regs_ptr_t(il_180)^.unused :=
          cg_blk_regs_ptr_t(il_180)^.unused - [13];
    if (ord(il_180^.xc[376]) >= 128) and
        (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) then begin
      m := 0;
      n := 0;
      for i := 18 to 23 do
        if not (i in cg_blk_regs_ptr_t(il_180)^.unused) then begin
          n := n + 1;
          m := m + rshft(128, i - 16);
        end;
      if (n = 0) or odd(ord(il_180^.xc[375])) then begin
        anyconst(0, 4, zero);
        emit(0, 4, cg_push_ads, zero, 0);
        unlock(zero);
      end
      else begin
        cg_top_fpsave.mask := m;
        emit(23, 5, cg_zero_ads, cg_null_ads, 0);
        if at_backend_506 then
          cg_top_124 := top_sect_ptr_t(il_180^.xp[47])^.tail;
      end;
    end;
    address_reg(14, cg_top_f8);
    address(il_180, 0, fr);
    emit(25, 5, fr, cg_top_f8, 0);
    release(fr);
    if il_180^.xl[44] <> 0 then begin
      if ((il_180^.xl[44] & 3) <> 0) and (4 in cargs_$options.flags_286) then
        il_180^.xl[44] := (il_180^.xl[44] & (-4)) + 4;
      if not (3 in cargs_$options.cpu) then begin
        address_reg(15, sp_a);
        address(smcontk(81, il_180^.xl[44]), 0, kc);
        emit(2, 5, sp_a, kc, 0);
        unlock(sp_a);
      end;
    end;
    nbytes := 0;
    if odd(ord(il_180^.xc[375])) then
      cg_blk_regs_ptr_t(il_180)^.unused :=
          cg_blk_regs_ptr_t(il_180)^.unused + [2..7, 10..12, 18..23];
    if cg_blk_regs_ptr_t(il_180)^.unused <> [2..7, 10..13, 18..23] then begin
      saves := [2..7, 10..13, 18..23] - cg_blk_regs_ptr_t(il_180)^.unused;
      if 4 in cargs_$options.cpu then begin
        mask := 0;
        bit := 4;
        n := 0;
        for i := 18 to 23 do begin
          if i in saves then begin
            mask := mask ! bit;
            n := n + 1;
          end;
          bit := lshft(bit, 1);
        end;
        if n > 0 then begin
          address(smcontk(81, mask), 0, kc);
          kc.f6 := 0;
          emit(68, 7, cg_push_ads, kc, 0);
        end;
        nbytes := n * 12;
      end
      else if cargs_$options.cpu * [2, 8] <> [] then
        for i := 23 downto 18 do
          if i in saves then begin
            address_reg(i, fr);
            if 8 in cargs_$options.cpu then begin
              if cg_top_fp_long[i] then begin
                emit_assign(7, cg_push_ads, fr);
                nbytes := nbytes + 8;
              end
              else begin
                emit_assign(6, cg_push_ads, fr);
                nbytes := nbytes + 4;
              end;
            end
            else begin
              emit(0, 7, cg_push_ads, fr, 0);
              nbytes := nbytes + 8;
            end;
          end;
      mask := 0;
      bit := 8192;
      n := 0;
      for i := 2 to 13 do begin
        if i in saves then begin
          n := n + 1;
          mask := mask ! bit;
        end;
        bit := rshft(bit, 1);
      end;
      nbytes := nbytes + n * 4;
      if mask <> 0 then
        if n < movem_min then begin
          for i := 13 downto 2 do
            if i in saves then begin
              address_reg(i, ra);
              emit(0, 4, cg_push_ads, ra, 0);
            end;
        end
        else begin
          address(smcontk(81, mask), 0, kc);
          kc.f6 := 1;
          emit(35, 4, cg_push_ads, kc, 0);
        end;
    end;
    if ((rshft(il_180^.xl2[93], 11) & 258) = 258) and at_backend_506 then begin
      if not cg_addr_killed[8] and (cargs_$options.db <= 1) then
        cg_data_reg := 8;
      if 7 in cargs_$options.flags_286 then begin
        g := il_180^.xp[48];
        if g^.xl[6] + g^.xl[5] - g^.xl[4] = 0 then
          g^.xl[4] := g^.xl[4] - 4;
        address_reg(cg_data_reg, fr);
        address(il_180^.xp[48], 0, cg_top_f8);
        emit(22, 5, fr, cg_top_f8, 0);
      end
      else begin
        address_reg(cg_data_reg, fr);
        address_reg(8, cg_top_f8);
        emit(0, 5, fr, cg_top_f8, 0);
      end;
    end;
    if odd(rshft(ord(il_180^.xc[376]), 6)) then begin
      address_reg(cg_data_reg, cg_top_f8);
      address_reg(14, fr);
      if cg_top_128 = 0 then begin
        il_180^.xl[20] := il_180^.xl[20] - 4;
        v := il_180^.xl[28];
        if v > il_180^.xl[20] then
          v := il_180^.xl[20];
        il_180^.xl[28] := v;
        cg_top_128 := il_180^.xl[20];
      end;
      fr.f1 := 2;
      fr.y := cg_top_128;
      emit(0, 4, fr, cg_top_f8, 0);
    end;
    if il_180^.xl[44] <> 0 then begin
      address_reg(15, sp_a);
      sp_a.f1 := 2;
      sp_a.y := nbytes;
      get_register(nil, 5, ra);
      emit(22, 5, ra, sp_a, 0);
      sp_a := ra;
      first := true;
      p := il_180^.xp[45];
      while p <> nil do begin
        address(p, 0, a);
        if p^.xl[3] = 0 then
          emit(0, 5, a, sp_a, 0)
        else begin
          if first then begin
            first := false;
            if cg_level_ptr_t(il_180)^.level > 0 then
              if ord(il_180^.xc[292]) <> 0 then
                cg_addr_locks[9] := cg_addr_locks[9] + 1;
            get_register(nil, 5, ra);
            if cg_level_ptr_t(il_180)^.level > 0 then
              if ord(il_180^.xc[292]) <> 0 then
                cg_addr_locks[9] := cg_addr_locks[9] - 1;
            emit(0, 5, ra, sp_a, 0);
            prev := 0;
          end;
          address(smcontk(81, p^.xl[3] - prev), 0, kc);
          emit(1, 5, ra, kc, 0);
          emit(0, 5, a, ra, 0);
          prev := p^.xl[3];
        end;
        p := p^.xp[1];
      end;
      if not first then
        unlock(ra);
      unlock(sp_a);
    end;
  end;

  { updatestacksize - in the last pass, the routine's frame settled:
    its size (+112) the deepest of +80, rounded with -ALIGN; the
    registers to save (+220: the callee-saved ones not left alone, A5
    by the block's two flags, not A5 when the data is reached through
    A0, no floating ones without a floating unit); the floating saves'
    offset (+228: 8 bytes each with the PEB, 4 or 8 by cg_top_fp_long
    with the FPA, 12 with the 68881) below the frame less +176, the
    general ones' (+224: 4 each) below it.

    0x0FD7C0, 0x1A8 bytes: il_180 reloaded in the counting loops;
    the floating registers' byte (+221) cleared. }

  procedure updatestacksize;
  var
    frame: integer32;
    n: integer;
    m: integer;
    i: integer;
  begin
    if at_backend_506 then begin
      if il_180^.xl[20] < il_180^.xl[28] then
        il_180^.xl[28] := il_180^.xl[20];
      if ((il_180^.xl[28] & 3) <> 0) and (4 in cargs_$options.flags_286) then
        il_180^.xl[28] := il_180^.xl[28] - 2;
      frame := il_180^.xl[28] - il_180^.xl[44];
      cg_blk_regs_ptr_t(il_180)^.saved :=
          [2..7, 10..13, 18..23] - cg_blk_regs_ptr_t(il_180)^.unused;
      if (rshft(il_180^.xl2[93], 11) & 258) = 258 then
        cg_blk_regs_ptr_t(il_180)^.saved :=
            cg_blk_regs_ptr_t(il_180)^.saved + [13]
      else
        cg_blk_regs_ptr_t(il_180)^.saved :=
            cg_blk_regs_ptr_t(il_180)^.saved - [13];
      if cg_data_reg = 8 then
        cg_blk_regs_ptr_t(il_180)^.saved :=
            cg_blk_regs_ptr_t(il_180)^.saved - [13];
      if cargs_$options.cpu * [2, 4, 8, 9, 10] = [] then
        cg_blk_regs_ptr_t(il_180)^.saved :=
            cg_blk_regs_ptr_t(il_180)^.saved - [16..23];
      n := 0;
      for i := 16 to 23 do
        if i in cg_blk_regs_ptr_t(il_180)^.saved then
          n := n + 1;
      if n = 0 then
        cg_blk_regs_ptr_t(il_180)^.fp_save_off := 0
      else if 2 in cargs_$options.cpu then
        cg_blk_regs_ptr_t(il_180)^.fp_save_off := frame - n * 8
      else if 8 in cargs_$options.cpu then begin
        m := 0;
        for i := 18 to 23 do
          if cg_top_fp_long[i] then
            m := m + 8;
        cg_blk_regs_ptr_t(il_180)^.fp_save_off :=
            frame - (m + (n - m div 8) * 4);
      end
      else
        cg_blk_regs_ptr_t(il_180)^.fp_save_off := frame - n * 12;
      n := 0;
      for i := 0 to 13 do
        if i in cg_blk_regs_ptr_t(il_180)^.saved then
          n := n + 1;
      if n = 0 then
        cg_blk_regs_ptr_t(il_180)^.save_off := 0
      else if cg_blk_regs_ptr_t(il_180)^.fp_save_off = 0 then
        cg_blk_regs_ptr_t(il_180)^.save_off := frame - n * 4
      else
        cg_blk_regs_ptr_t(il_180)^.save_off :=
            cg_blk_regs_ptr_t(il_180)^.fp_save_off - n * 4;
    end;
  end;

  { emit_terminating_line_no - in the last pass, a line cell for line
    (the block's last line, +270, for none) unless the section's last
    cell is that line's, and that cell marked as a return's.

    0x0FD968, 0x70 bytes. }

  procedure emit_terminating_line_no(
      line: integer); options(val_param);
  var
    c: codegen_$cell_ptr_t;
  begin
    if at_backend_506 then begin
      if line = spos_$null_position then
        line := il_180^.xw[135];
      c := top_sect_ptr_t(il_180^.xp[47])^.tail;
      if (c^.kind <> 24) or (c^.line <> line) then
        emit_line_eop(cg_null_ads, cg_null_ads, line);
      top_sect_ptr_t(il_180^.xp[47])^.tail^.ret := true;
    end;
  end;

  { return_proc - return statement r: its value moved to D0 (or A0 for
    a pointer, class 5; to both for a block of +375 bit 4 and not bit 2,
    or with +375 bit 2 a pointer to D0 too; a value already in the
    register not moved; the register that holds it of the other class
    preferred; an FPA value stored with emit_load_store), the line
    cell, the frame settled (updatestacksize), the saved registers
    restored (the floating ones by fmovem with the 68881, one by one
    with the PEB or FPA; the general ones one by one under movem_min,
    else movem; offsets beyond 32K through A1), `unlk', the save mask
    popped, `rts' (27).

    0x0FD9D8, 0x790 bytes: codegen's frame from the dynamic link for
    movem_min; the save area's operand built in three copies; +377
    bits 6..4 (the result's form: 3 a pointer in D0 only). }

  procedure return_proc(
      in out r: univ top_return_t;
      line: integer); options(val_param);
  var
    d0a: codegen_$uads_t;               { -24 }
    k48: codegen_$uads_t;               { -48 }
    a96: codegen_$uads_t;               { -96 }
    a0a: codegen_$uads_t;               { -120 }
    size: integer;
    both: boolean;
    mask: cg_count_t;
    bit: cg_count_t;
    n: integer;
    i: integer;
  begin
    if r.value <> nil then begin
      address_reg(0, d0a);
      address_reg(8, a0a);
      if (rshft(ord(il_180^.xc[377]) & 112, 4) = 3) and (r.size = 5) and
          not odd(rshft(ord(il_180^.xc[375]), 4)) then begin
        address(r.value, 4, cg_top_f8);
        if not ((cg_top_f8.f1 = 1) and (cg_top_f8.f2 = 0)) then
          emit(0, 4, d0a, cg_top_f8, 0);
      end
      else begin
        size := r.size;
        both := false;
        if (size < 5) and ((rshft(il_180^.xl2[93], 11) & 640) = 512) then
          if size = 4 then
            size := 5
          else
            both := true;
        if peek(r.value, size) = 31 then begin
          if (size = 5) and (peek(r.value, 4) <> 31) then
            address(r.value, 4, cg_top_f8)
          else if (size = 4) and (peek(r.value, 5) <> 31) then
            address(r.value, 5, cg_top_f8)
          else
            address(r.value, size, cg_top_f8);
        end
        else
          address(r.value, size, cg_top_f8);
        if size = 5 then begin
          if not ((cg_top_f8.f1 = 1) and (cg_top_f8.f2 = 8)) then
            emit(0, 5, a0a, cg_top_f8, 0);
          if odd(rshft(ord(il_180^.xc[375]), 2)) then
            if not ((cg_top_f8.f1 = 1) and (cg_top_f8.f2 = 0)) then
              emit(0, 4, d0a, a0a, 0);
        end
        else if both then begin
          if cg_top_f8.f1 = 1 then
            emit(0, 5, a0a, cg_top_f8, 0)
          else begin
            if (8 in cargs_$options.cpu) and (cg_top_f8.f1 = 13) then
              emit_assign(r.size, d0a, cg_top_f8)
            else
              emit(0, r.size, d0a, cg_top_f8, 0);
            emit(0, 5, a0a, d0a, 0);
          end;
        end
        else begin
          if not ((cg_top_f8.f1 = 1) and (cg_top_f8.f2 = 0)) then
            if (8 in cargs_$options.cpu) and (cg_top_f8.f1 = 13) then
              emit_load_store(497, cg_top_f8, d0a, size)
            else
              emit(0, size, d0a, cg_top_f8, 0);
          if odd(rshft(ord(il_180^.xc[375]), 4)) then
            if not ((cg_top_f8.f1 = 1) and (cg_top_f8.f2 = 8)) then
              emit(0, 4, a0a, d0a, 0);
        end;
      end;
      release(cg_top_f8);
    end;
    emit_terminating_line_no(line);
    updatestacksize;
    if cg_blk_regs_ptr_t(il_180)^.saved <> [] then begin
      if 4 in cargs_$options.cpu then begin
        mask := 0;
        bit := 128;
        for i := 16 to 23 do begin
          if i in cg_blk_regs_ptr_t(il_180)^.saved then
            mask := mask ! bit;
          bit := rshft(bit, 1);
        end;
        if mask <> 0 then begin
          if cg_blk_regs_ptr_t(il_180)^.fp_save_off < -32768 then begin
            address_reg(9, a96);
            address_reg(14, cg_top_f8);
            emit(0, 5, a96, cg_top_f8, 0);
            address(smcontk(81, cg_blk_regs_ptr_t(il_180)^.fp_save_off), 0,
                cg_top_f8);
            emit(1, 5, a96, cg_top_f8, 0);
            a96.f1 := 2;
          end
          else begin
            address_reg(14, a96);
            a96.f1 := 2;
            a96.y := cg_blk_regs_ptr_t(il_180)^.fp_save_off;
          end;
          address(smcontk(81, mask), 0, k48);
          k48.f6 := 0;
          emit(68, 7, k48, a96, 0);
        end;
      end;
      if cargs_$options.cpu * [2, 8] <> [] then begin
        if cg_blk_regs_ptr_t(il_180)^.fp_save_off < -32768 then begin
          address_reg(9, a96);
          address_reg(14, cg_top_f8);
          emit(0, 5, a96, cg_top_f8, 0);
          address(smcontk(81, cg_blk_regs_ptr_t(il_180)^.fp_save_off), 0,
              cg_top_f8);
          emit(1, 5, a96, cg_top_f8, 0);
          a96.f1 := 2;
        end
        else begin
          address_reg(14, a96);
          a96.f1 := 2;
          a96.y := cg_blk_regs_ptr_t(il_180)^.fp_save_off;
        end;
        for i := 16 to 23 do
          if i in cg_blk_regs_ptr_t(il_180)^.saved then begin
            address_reg(i, cg_top_f8);
            if 8 in cargs_$options.cpu then begin
              if cg_top_fp_long[i] then begin
                emit_assign(7, cg_top_f8, a96);
                a96.y := a96.y + 8;
              end
              else begin
                emit_assign(6, cg_top_f8, a96);
                a96.y := a96.y + 4;
              end;
            end
            else begin
              emit(0, 7, cg_top_f8, a96, 0);
              a96.y := a96.y + 8;
            end;
          end;
      end;
      mask := 0;
      bit := 1;
      n := 0;
      for i := 0 to 13 do begin
        if i in cg_blk_regs_ptr_t(il_180)^.saved then begin
          mask := mask ! bit;
          n := n + 1;
        end;
        bit := lshft(bit, 1);
      end;
      if mask <> 0 then begin
        if cg_blk_regs_ptr_t(il_180)^.save_off < -32768 then begin
          address_reg(9, a96);
          address_reg(14, cg_top_f8);
          emit(0, 5, a96, cg_top_f8, 0);
          address(smcontk(81, cg_blk_regs_ptr_t(il_180)^.save_off), 0,
              cg_top_f8);
          emit(1, 5, a96, cg_top_f8, 0);
          a96.f1 := 2;
        end
        else begin
          address_reg(14, a96);
          a96.f1 := 2;
          a96.y := cg_blk_regs_ptr_t(il_180)^.save_off;
        end;
        if n < movem_min then begin
          for i := 0 to 13 do
            if i in cg_blk_regs_ptr_t(il_180)^.saved then begin
              address_reg(i, cg_top_f8);
              emit(0, 4, cg_top_f8, a96, 0);
              a96.y := a96.y + 4;
            end;
        end
        else begin
          address(smcontk(81, mask), 0, k48);
          k48.f6 := 1;
          emit(34, 4, k48, a96, 0);
        end;
      end;
    end;
    address_reg(14, cg_top_f8);
    emit(26, 5, cg_top_f8, cg_null_ads, 0);
    if (ord(il_180^.xc[376]) >= 128) and
        (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) then begin
      address_reg(15, cg_top_f8);
      address(smcontk(81, 4), 0, a96);
      emit(1, 5, cg_top_f8, a96, 0);
    end;
    emit(27, 5, cg_null_ads, cg_null_ads, 0);
  end;

  { label_proc - label lab: no PEB operation pending; a label reached
    other than by a goto (+74, or +72 bit 6 clear) counted
    (cg_top_13a); the state falling into it merged unless the previous
    statement is a goto (150, 141); without a saved state (or +74) the
    registers forgotten first; at the first pass the state's records
    checked (edit_register); with -C 2 listed; the state taken as the
    current one (marked reached) and with -C kept at the first pass in
    a copy (+68: a 180 node, or 161 without the floating registers) or
    compared with that copy (cgerr 13 when they differ); the state
    given back to runbackend's free list (+0x8) once a label of +72
    bit 6 or the last pass is done with it; the label defined (32); a
    nested goto's target (+75) reloads the data register from the
    frame and kills D0..A4 and marks the block (+376 bit 6); cached
    objects marked for their registers given back to them.

    0x0FE168, 0x44A bytes: the state reloaded from the label (+64) at
    each use; the copies as longword pairs (49, or 32 and one); the
    records compared field by field (the classes may differ when
    neither object is set). }

  procedure label_proc(
      lab: il_$node_ptr_t); options(val_param);
  var
    a24: codegen_$uads_t;               { -24 }
    a48: codegen_$uads_t;               { -48 }
    s: cg_state_ptr_t;                  { -60 }
    c: cg_state_ptr_t;
    i: integer;
    fp: boolean;
    same: boolean;
  begin
    init_peb;
    if (ord(lab^.xc[74]) >= 128) or not odd(rshft(ord(lab^.xc[72]), 6)) then
      cg_top_13a := cg_top_13a + 1;
    if lab^.xp[1] <> nil then
      if not ((lab^.xp[1]^.kind = 150) or (lab^.xp[1]^.kind = 141)) then
        merge_state(cg_stmt);
    if (lab^.xp[16] = nil) or (ord(lab^.xc[74]) >= 128) then begin
      cg_addr_$init_regs(false);
      merge_state(cg_stmt);
    end;
    if (cg_pass = 1) and not odd(rshft(ord(lab^.xc[72]), 6)) then begin
      for i := 0 to 15 do
        edit_register(i, cg_state_ptr_t(lab^.xp[16])^.regs[i]);
      if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
        for i := 16 to 23 do
          edit_register(i, cg_state_ptr_t(lab^.xp[16])^.fp_regs[i]);
    end;
    if cargs_$options.c = 2 then
      show_label(cg_stmt);
    s := cg_state_ptr_t(lab^.xp[16]);
    s^.b7 := true;
    cg_addr_2b8 := ord(s^.b4);
    cg_addr_2b6 := ord(s^.b6);
    for i := 0 to 15 do
      cg_addr_regs[i] := s^.regs[i];
    fp := cargs_$options.cpu * [2, 4, 8, 9, 10] <> [];
    if fp then begin
      cg_addr_2b4 := s^.w266;
      for i := 16 to 23 do
        cg_addr_regs[i] := s^.fp_regs[i];
    end;
    if cargs_$options.c >= 1 then
      if cg_pass = 1 then begin
        if fp then begin
          lab^.xp[17] := gspace(396);
          lab^.xp[17]^.kind := 180;
          c := cg_state_ptr_t(lab^.xp[17]);
          c^.b4 := s^.b4;
          c^.b5 := s^.b5;
          c^.b6 := s^.b6;
          c^.b7 := s^.b7;
          for i := 0 to 15 do
            c^.regs[i] := s^.regs[i];
          c^.w264 := s^.w264;
          c^.w266 := s^.w266;
          for i := 16 to 23 do
            c^.fp_regs[i] := s^.fp_regs[i];
        end
        else begin
          lab^.xp[17] := gspace(264);
          lab^.xp[17]^.kind := 161;
          c := cg_state_ptr_t(lab^.xp[17]);
          c^.b4 := s^.b4;
          c^.b5 := s^.b5;
          c^.b6 := s^.b6;
          c^.b7 := s^.b7;
          for i := 0 to 15 do
            c^.regs[i] := s^.regs[i];
        end;
      end
      else begin
        c := cg_state_ptr_t(lab^.xp[17]);
        same := (s^.b4 = c^.b4) and (s^.b6 = c^.b6);
        i := 0;
        while same and (i <= 15) do begin
          if (c^.regs[i].obj <> s^.regs[i].obj) or
              (c^.regs[i].obj2 <> s^.regs[i].obj2) then
            same := false
          else if c^.regs[i].size <> s^.regs[i].size then
            if (c^.regs[i].obj <> nil) or (c^.regs[i].obj2 <> nil) then
              same := false;
          i := i + 1;
        end;
        if same and fp then begin
          if s^.w266 <> c^.w266 then
            same := false;
          i := 16;
          while same and (i <= 23) do begin
            if (c^.fp_regs[i].obj <> s^.fp_regs[i].obj) or
                (c^.fp_regs[i].obj2 <> s^.fp_regs[i].obj2) then
              same := false
            else if c^.fp_regs[i].size <> s^.fp_regs[i].size then
              if (c^.fp_regs[i].obj <> nil) or
                  (c^.fp_regs[i].obj2 <> nil) then
                same := false;
            i := i + 1;
          end;
        end;
        if not same then
          cgerr(13, cg_line, cg_stmt);
      end;
    if odd(rshft(ord(lab^.xc[72]), 6)) or at_backend_506 then begin
      cg_state_ptr_t(lab^.xp[16])^.regs[0].obj := runbackend_08;
      runbackend_08 := lab^.xp[16];
      lab^.xp[16] := nil;
    end;
    address(cg_stmt, 0, cg_top_f8);
    emit(32, 5, cg_top_f8, cg_null_ads, 0);
    if ord(lab^.xc[75]) >= 128 then begin
      address_reg(cg_data_reg, a48);
      address_reg(14, a24);
      a24.f1 := 2;
      a24.y := cg_top_128;
      emit(0, 5, a48, a24, 0);
      for i := 0 to 12 do
        cg_addr_killed[i] := true;
    end;
    for i := 0 to 23 do
      if cg_addr_cache[i].obj <> nil then
        if cg_addr_cache[i].param_alias then begin
          if peek(cg_addr_cache[i].obj, cg_addr_cache[i].size) <> i then begin
            setresult(i, cg_addr_cache[i].obj, cg_addr_cache[i].size);
            cg_addr_regs[i].obj2 := cg_addr_cache[i].obj;
          end;
          cg_addr_regs[i].w14 := 0;
        end;
    if ord(cg_stmt^.xc[75]) >= 128 then
      il_180^.xc[376] := chr(ord(il_180^.xc[376]) ! 16#40);
  end;

  { emit_a_line_eop - in the last pass, the statement's line cell when
    its line is known, unless the statement is a routine's entry or end
    (148, 149 not of an inner block) or the next is an entry.

    0x0FE5B2, 0x78 bytes: cg_null_ads pushed twice (`move.l (SP),-(SP)'). }

  procedure emit_a_line_eop;
  begin
    if at_backend_506 and (spos_$null_position <> cg_top_138) then
      if (cg_stmt^.kind <> 148) or (cg_stmt^.xp[12]^.kind = 172) then
        if (cg_stmt^.kind <> 149) or (cg_stmt^.xp[12]^.kind = 172) then
          if (cg_stmt^.xp[2]^.kind <> 148) or
              (cg_stmt^.xp[2]^.xp[12]^.kind = 172) then
            emit_line_eop(cg_null_ads, cg_null_ads, cg_top_138);
  end;

begin
  if (il_11c <> nil) and cargs_$options.exp then begin
    cg_top_130 := gspace32(il_124 * 8);
    for cg_top_13e := 1 to il_124 do begin
      cg_top_130^[cg_top_13e].line := spos_$null_position;
      cg_top_130^[cg_top_13e].blk_no := cg_top_13e;
    end;
  end
  else
    cg_top_130 := nil;
  cg_top_13c := 1;
  cg_top_118 := il_d4;
  while cg_top_118 <> nil do begin
    perfstart(19);
    cg_pass := 0;
    cg_settled := false;
    repeat
      at_backend_506 := cg_settled;
      cg_settled := true;
      cg_pass := cg_pass + 1;
      cg_stmt := cg_top_118;
      cg_top_13e := cg_top_13c - 1;
      initialize;
      initialize_tree;
      cg_top_11c := top_sect_ptr_t(il_180^.xp[47])^.tail;
      repeat
        for r := 0 to 23 do begin
          if cg_addr_regs[r].obj <> nil then
            if cg_addr_regs[r].obj^.kind in [137, 138, 143, 145, 146, 147,
                164, 171, 175, 189, 205] then
              if (cg_addr_regs[r].obj^.xl[1] & 14) <> 0 then
                if not (((cg_addr_regs[r].obj^.kind = 138) or
                    (cg_addr_regs[r].obj^.kind = 137)) and
                    (cg_tree_ptr_t(cg_addr_regs[r].obj)^.op = 17)) then
                  cg_addr_regs[r].obj := nil;
          if cg_addr_regs[r].obj2 <> nil then
            if cg_addr_regs[r].obj2^.kind in [137, 138, 143, 145, 146, 147,
                164, 171, 175, 189, 205] then
              if (cg_addr_regs[r].obj2^.xl[1] & 22) <> 0 then
                if not (((cg_addr_regs[r].obj2^.kind = 138) or
                    (cg_addr_regs[r].obj2^.kind = 137)) and
                    (cg_tree_ptr_t(cg_addr_regs[r].obj2)^.op = 17)) then
                  cg_addr_regs[r].obj2 := nil;
          if cg_addr_regs[r].obj <> nil then
            if cg_addr_regs[r].obj^.kind = 109 then
              if (cg_addr_regs[r].obj^.xl[8] & 9) <> 0 then
                cg_addr_regs[r].obj := nil;
          if cg_addr_regs[r].obj2 <> nil then
            if cg_addr_regs[r].obj2^.kind = 109 then
              if (cg_addr_regs[r].obj2^.xl[8] & 17) <> 0 then
                cg_addr_regs[r].obj2 := nil;
          if cg_addr_regs[r].obj <> nil then
            if cg_addr_regs[r].obj^.kind = 110 then
              if (cg_addr_regs[r].obj^.xl[6] & 9) <> 0 then
                cg_addr_regs[r].obj := nil;
          if cg_addr_regs[r].obj2 <> nil then
            if cg_addr_regs[r].obj2^.kind = 110 then
              if (cg_addr_regs[r].obj2^.xl[6] & 17) <> 0 then
                cg_addr_regs[r].obj2 := nil;
          if cg_addr_locks[r] <> 0 then begin
            cgerr(4, cg_line, nil);
            cg_addr_locks[r] := 0;
          end;
        end;
        if cg_fp_count <> 0 then
          cgerr(28, cg_line, token_$make_string_token('FP stack is not empty'));
        cg_top_138 := cg_stmt^.xw[10];
        if cg_top_138 <> spos_$null_position then
          cg_line := cg_top_138;
        emit_a_line_eop;
        if cargs_$options.c = 2 then
          show_state;
        if cargs_$options.db = 3 then
          cg_addr_$init_regs(false)
        else if cargs_$options.frnd then
          cg_addr_$init_regs(true);
        if odd(rshft(ord(cg_stmt^.xc[42]), 1)) and (il_11c <> nil) then
          basicblock;
        case cg_stmt^.kind of
          191: reg_list_proc(cg_stmt);
          140: assign_proc(cg_stmt^.xp[1]);
          139: begin
            if (cg_stmt^.xp[2]^.kind = 149) and
                (cg_stmt^.xp[2]^.xp[12]^.kind <> 172) and
                (cg_stmt^.xw[25] <> 0) and
                (cg_stmt^.xp[13]^.kind = 137) and
                (cg_tree_ptr_t(cg_stmt^.xp[13])^.op = 15) and
                (cg_tree_ptr_t(cg_stmt^.xp[13])^.opnd[1]^.kind = 159) then
              emit_terminating_line_no(cg_top_138);
            for k := 1 to cg_stmt^.xw[25] do
              if cg_stmt^.xp[12 + k]^.kind <> 189 then begin
                if cg_stmt^.xp[12 + k]^.kind = 137 then begin
                  tree_walk(cg_stmt^.xp[12 + k]);
                  if cg_tree_ptr_t(cg_stmt^.xp[12 + k])^.op = 26 then begin
                    size := cg_tree_ptr_t(cg_stmt^.xp[12 + k])^.desc.rlen;
                    r := chk_assign(cg_stmt^.xp[12 + k], size);
                    if r <> 31 then begin
                      if peek(cg_stmt^.xp[12 + k], size) <> r then begin
                        address(cg_stmt^.xp[12 + k], 5, cg_top_e0);
                        address_reg(r, cg_top_f8);
                        if (8 in cargs_$options.cpu) and
                            ((cg_top_f8.f1 = 13) or (cg_top_e0.f1 = 13)) then
                          emit_assign(size, cg_top_f8, cg_top_e0)
                        else
                          emit(0, size, cg_top_f8, cg_top_e0, 0);
                        setresult(r, cg_stmt^.xp[12 + k], size);
                        unlock(cg_top_e0);
                      end;
                      cg_addr_cache[r].param_alias := true;
                    end;
                  end;
                end
                else
                  tree_walk(cg_stmt^.xp[12 + k]);
                if cg_fp_count <> 0 then
                  purge_fp;
                address_reg(14, cg_top_f8);
                cg_top_f8.x := integer32(cg_stmt^.xp[12 + k]);
                release(cg_top_f8);
              end;
            nxt := skip_reg_list(cg_stmt);
            if (nxt^.kind = 142) and (cg_stmt^.xw[25] <> 0) then
              case_proc(cg_stmt);
          end;
          148: block_entry_proc(cg_stmt^.xp[1]);
          141: begin
            merge_state(cg_stmt^.xp[12]);
            address(cg_stmt^.xp[12], 0, cg_top_f8);
            if cg_stmt^.xp[12] <> cg_stmt^.xp[2] then
              emit(21, 5, cg_top_f8, cg_null_ads, 0);
          end;
          150: begin
            il_180^.xc[375] := chr(ord(il_180^.xc[375]) ! 8);
            if cg_stmt^.xp[12]^.kind <> 117 then begin
              cg_addr_$merge_state_of_assigned_goto_targets(cg_stmt);
              load_operand(cg_stmt^.xp[12], 5, cg_top_f8);
              cg_top_f8.f1 := 2;
              emit(37, 5, cg_top_f8, cg_null_ads, 0);
              release(cg_top_f8);
            end
            else begin
              lab := cg_stmt^.xp[12]^.xp[7];
              if lab^.kind = 144 then
                lab^.xc[75] := chr(255);
              while (lab^.kind <> 148) or (lab^.xp[12]^.kind = 172) do
                lab := lab^.xp[1];
              if lab^.xp[12]^.xp[47] <> il_180^.xp[47] then
                cgerr(25, cg_line, cg_stmt^.xp[12]);
              address(cg_stmt^.xp[12]^.xp[7], 0, cg_top_f8);
              emit(23, 5, cg_top_f8, cg_null_ads, 0);
              p := il_180^.xp[60];
              for k := 2 to cg_level_ptr_t(il_180)^.level -
                  cg_level_ptr_t(cg_stmt^.xp[12]^.xp[5])^.level do
                p := p^.xp[3];
              address(p, 5, cg_top_f8);
              unlock(cg_top_f8);
              emit(0, 5, cg_push_ads, cg_top_f8, 0);
              gen_call(nil, std_lib_rtns[17]);
            end;
          end;
          142: cbranch_proc(cg_stmt^.xp[1]);
          144: label_proc(cg_stmt);
          149: begin
            if cg_stmt^.xp[12]^.kind = 172 then begin
              if at_backend_506 then begin
                address(cg_stmt^.xp[12], 0, cg_top_f8);
                emit_line_eop(cg_top_f8, cg_null_ads, cg_top_138);
              end;
            end
            else begin
              if cg_addr_killed[13] or (cg_code_bytes >= 5000) then
                il_180^.xc[375] := chr(ord(il_180^.xc[375]) ! 8);
              if at_backend_506 then begin
                updatestacksize;
                if cg_top_124 <> nil then begin
                  if 4 in cargs_$options.cpu then
                    cg_top_fpsave.kind := 1
                  else if 2 in cargs_$options.cpu then
                    cg_top_fpsave.kind := 2
                  else if 8 in cargs_$options.cpu then begin
                    cg_top_fpsave.kind := 3;
                    cg_top_fpsave.mask := lshft(cg_top_fpsave.mask, 8);
                  end;
                  cg_top_fpsave.off := cg_blk_regs_ptr_t(il_180)^.fp_save_off;
                  cg_top_124^.ads2.x := integer32(setcontk(cg_top_fpsave, 0, 8));
                  cg_top_124^.ads2.y := 1;
                end;
                il_180^.xl[20] := il_180^.xl[28];
                address(il_180, 0, cg_top_f8);
                emit_line_eop(cg_top_f8, cg_null_ads, cg_top_138);
              end;
              exit;
            end;
          end;
          151: return_proc(cg_stmt^.xp[1], cg_top_138);
          188: ;
          otherwise
            cgerr(1, cg_line, cg_stmt);
        end;
        cg_stmt := cg_stmt^.xp[2];
      until false;
    until at_backend_506;
    perfstop(19);
    perfstart(20);
    peepholer(il_180^.xp[47], cg_top_11c^.next);
    perfstop(20);
    perfstart(21);
    jmp_br_setup(il_180^.xp[47], cg_top_11c^.next);
    perfstop(21);
    top_sect_ptr_t(il_180^.xp[47])^.tail :=
        top_sect_ptr_t(il_180^.xp[47])^.head^.prev;
    il_180^.xp[41] := il_11c;
    il_180^.xp[30] := il_$node_ptr_t(cg_top_130);
    il_180^.xw[137] := il_124;
    cg_top_118 := cg_stmt^.xp[2];
    cg_top_13c := cg_top_13e + 1;
  end;
  mem_$empty_pool(opt_main_8);
end;
