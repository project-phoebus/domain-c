{ lir_main - the LIR's frame code (cc.a88k only): a routine's ENTRY
  instruction (the registers it defines) and its formals moved to
  their homes, the second entries and exception handlers' re-entries,
  the RETURN instruction (the registers it reads) and the formals
  moved back, the silly register candidates (a variable whose every
  reference is to its memory home) dropped, and, after register
  allocation, the frame laid out and the preserved registers saved and
  restored around it.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x248A80  zero (internal)
    --------  0x248A98  count_registers (internal)
    --------  0x248AD2  top_level_inherited_attributes (internal)
    --------  0x248B00  clean_up_canned_inherited (internal)
    --------  0x248B1E  formal_local_transfer_setup (internal)
    --------  0x249020  lir_main_$add_live_range
    --------  0x249086  lir_main_$add_ip_reg_physical_lr
    --------  0x249106  lir_main_$reinit_physical_regs
    --------  0x249288  lir_main_$begin_routine
    --------  0x249592  make_xsb_a_register_candidate (internal)
    --------  0x249610  lir_main_$entry
    --------  0x24A124  lir_main_$handler_reentry
    --------  0x24A1E0  fix_silly_register_candidates (internal)
    --------  0x24A508  by_branch_prologs_for_handler (internal)
    --------  0x24A6F8  build_fp_reg_pair_odd_operand (internal)
    --------  0x24A746  lir_main_$build_initial_epilog
    --------  0x24AEE8  pick_register (internal)
    --------  0x24AF62  complete_prolog_store (internal)
    --------  0x24B03A  add_prolog_register_read (internal)
    --------  0x24B0B4  prolog_store_instruction (internal)
    --------  0x24B298  complete_epilog_load (internal)
    --------  0x24B346  add_epilog_register_write (internal)
    --------  0x24B42E  epilog_load_pair_instruction (internal)
    --------  0x24B4BE  epilog_load_instruction (internal)
    --------  0x24B618  lir_main_$save_and_restore_code
    A5 0x48B3AC: the module's data, 0xDB8 bytes, every cell declared
    extern (backend.ins.pas's, lir.pvt.pas's, the unit's own lm_ ones
    below) and defined here in address order (dpc lays defined cells
    out in define-list order after any own variables, so the unit has
    none; the gaps no instruction addresses are lm_unused_ cells).
    dpc gives each byte cell two bytes (docs/dpc-gaps.md 37), so the
    boolean cells +0xC89 and +0xC8B..+0xC8E lie at +0xC8A, +0xC8C ..
    +0xC92 here; every other cell is at its address (the cells after
    a boolean that the image packs with it are left out: +0xC8A,
    +0xC8F, +0xDA5, +0xDA9, +0xDAB, +0xDB5).
    The section lir_main_readonly_tables (0x2BE0C0, 72 bytes): five
    tables by arg_loc_t.

  The registers: an integer register k's physical live range is
  lir_4090[k], its solution lir_3e60[k]; a floating register k's
  (0..63) lir_3f90[k] and lir_3d60[k] (its pair's lir_3c60[k]).  The
  ENTRY instruction defines them (operands 3.. for integer registers
  0..29, 33.. for the floating ones) and the RETURN reads them; the
  frame's slots are reached through lir_main_760 (the frame base, disp
  the offset) and lir_main_250 (a formal's home, disp its offset).

  Not known from the original: every local and parameter name, the lm_
  cells' names. }

module lir_main;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/common/source/exs.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'lang2/source/isc/isc_var_externs.ins.pas';
%include 'lang2/source/be_com/lir.pvt.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  { How a formal is moved between its register and its home
    (formal_local_transfer_setup fills one: lm_prolog_xfer for the
    ENTRY's side, lm_epilog_xfer for the RETURN's): sol the home's
    solution, opc the register move's opcode, ldst the load's or
    store's, prolog set in lm_prolog_xfer only, split a double by value
    whose slot is not quadword aligned (moved as two singles), quad a
    quad's register (arg_loc$fp_reg_quad), b11 the variable's flag 30. }
  lm_xfer_ptr_t = ^lm_xfer_t;
  lm_xfer_t = record
    sol: solution_ptr_t;                { +0 }
    opc: integer;                       { +4 }
    ldst: integer;                      { +6 }
    prolog: boolean;                    { +8 }
    split: boolean;                     { +9 }
    quad: boolean;                      { +10 }
    b11: boolean;                       { +11 }
  end;

  { The loads or stores by size: byte, half, word, single, double. }
  lm_opc5_ptr_t = ^lm_opc5_t;
  lm_opc5_t = array [0..4] of integer;

  lm_by_loc_t = array [0..6] of integer;

  lm_ops_t = array [0..63] of opnd_ptr_t;

  { A block's +134..+153 while save_and_restore_code puts stores after
    its ENTRY (bb_t's l134, space138, next142, mark146, l150 hold
    other things in other phases): ins the instruction stores go after
    (first the ENTRY), rd the operand that read the memory the ENTRY
    wrote (its link), mem the memory's segment now, last its last
    reference, next_ins the instruction that followed the ENTRY. }
  lm_bbv_ptr_t = ^lm_bbv_t;
  lm_bbv_t = record
    space0: array [0..133] of char;     { +0 }
    ins: instr_ptr_t;                   { +134 }
    rd: opnd_ptr_t;                     { +138 }
    mem: lts_ptr_t;                     { +142 }
    last: opnd_ptr_t;                   { +146 }
    next_ins: instr_ptr_t;              { +150 }
  end;

  { A label (lir_$new_label's; sym.pas's sym_label_t). }
  lm_label_ptr_t = ^lm_label_t;
  lm_label_t = record
    next: lm_label_ptr_t;               { +0 }
    instr: instr_ptr_t;                 { +4 }
    w8: integer;                        { +8 }
    f10: packed record                  { +10 }
      required: boolean;                { .7 }
      b6: boolean;                      { .6: the node's +68 bit 7 }
      in_bb: boolean;
      b4_0: 0..31;
      b11: 0..255;
      end;
  end;

  { An operand before its segments are made: +4 its rrp (lir_$build_
    operand's), +8 its live range. }
  lm_opw_ptr_t = ^lm_opw_t;
  lm_opw_t = record
    h: opnd_hdr_t;                      { +0 }
    rrp: integer;                       { +4 }
    w6: integer;                        { +6 }
    lr: lr_ptr_t;                       { +8 }
  end;

  lm_heap_ptr_t = ^mrh_$heap_t;

var
  lm_ip_ops: extern lm_ops_t;           { +0x000: by integer register,
                                          the RETURN's operand that reads
                                          it (build_initial_epilog;
                                          cleared for each routine) }
  lm_fp_ops: extern lm_ops_t;           { +0x100: likewise by floating
                                          register }
  lm_stores: extern lm_opc5_t;          { +0x200 }
  lm_unused_20a: extern array [0..2] of integer;     { +0x20A }
  lm_loads: extern lm_opc5_t;           { +0x210 }
  lm_unused_21a: extern array [0..2] of integer;     { +0x21A }
  lm_epilog_xfer: extern lm_xfer_t;     { +0x220 }
  lm_unused_22c: extern integer32;      { +0x22C }
  lm_prolog_xfer: extern lm_xfer_t;     { +0x230 }
  lm_unused_23c: extern array [0..1] of integer32;   { +0x23C }
  lm_convs: extern array [1..2] of call_conv_$ptr_t; { +0x244: the
                                          conventions whose formals the
                                          RETURN reads back: the routine's,
                                          or a FORTRAN routine's entries'
                                          with the largest register and
                                          memory formals (lm_nconvs) }
  lm_unused_24c: extern integer32;      { +0x24C }
  lir_main_c8b: extern boolean;         { +0xC8B: a block of kind 167 (an
                                          ENTRY statement's) among the
                                          routine's entries }
  lm_unused_c94: extern array [0..211] of char;      { +0xC90 in the
                                          image (+0xC94 here: dpc gives
                                          each byte cell two bytes,
                                          docs/dpc-gaps.md 37) }
  lm_forms: extern array [0..6] of instr_attr_opnd_t;    { +0xD68: the
                                          operand forms of the ENTRY's
                                          and RETURN's registers: 0 an
                                          integer, 1 a pair, 2 a single
                                          (each read 16#C0), 3..5 the same
                                          without, 6 set as needed (num
                                          set before each use) }
  lm_edges: extern fg_edge_ptr_t;       { +0xD84: the entry block's
                                          edges (to the ENTRY blocks) }
  lm_nconvs: extern integer32;          { +0xD88: lm_convs' count }
  lm_opnd_num: extern integer32;        { +0xD8C: the LIMIT's operands
                                          given so far }
  lm_last_ref: extern opnd_ptr_t;       { +0xD90: the last reference of
                                          the RETURN block's memory segment }
  lm_mem_lts: extern lts_ptr_t;         { +0xD94: that segment }
  lm_ret_bb: extern bb_ptr_t;           { +0xD98: the RETURN's block }
  lm_second_entry: extern univ_ptr;     { +0xD9C: a second entry's
                                          statement (rewrite_$entry) }
  lm_unused_da6: extern integer;        { +0xDA6 }
  lm_mem_formals: extern boolean;       { +0xDA8: a formal is kept in
                                          memory (sets needs_frame) }
  lm_no_return: extern boolean;         { +0xDAA: the routine has no
                                          RETURN block (no epilog loads) }
  lm_entry_node: extern univ_ptr;       { +0xDAC: the routine's entry
                                          statement }
  lm_entry_instr: extern instr_ptr_t;   { +0xDB0: its ENTRY instruction }
  lm_no_xsb: extern boolean;            { +0xDB4: set by rewrite_$entry:
                                          the XSB bases are not loaded
                                          from the frame }
  lm_unused_db6: extern integer;        { +0xDB6 }

define
  lm_ip_ops, lm_fp_ops;
  lm_stores := [ord(opc$storeb), ord(opc$storew), ord(opc$storel),
                ord(opc$stores), ord(opc$stored)];
  lm_unused_20a;
  lm_loads := [ord(opc$loadbu), ord(opc$loadwu), ord(opc$loadl),
               ord(opc$loads), ord(opc$loadd)];
  lm_unused_21a;
  lm_epilog_xfer := [nil, 0, 0, false, false, false, false];
  lm_unused_22c;
  lm_prolog_xfer := [nil, 0, 0, true, false, false, false];
  lm_unused_23c, lm_convs, lm_unused_24c,
  lir_main_250, lir_main_400, lir_main_5b0, lir_main_760, lir_main_910,
  lir_main_ac0, lir_main_b40,
  lir_main_c40, lir_main_c44, lir_main_c48, lir_main_c4c, lir_main_c50,
  lir_main_c54, lir_main_c58, lir_main_c5c, lir_main_c60, lir_main_c64,
  lir_main_c68, lir_main_c6c, lir_main_c70, lir_main_heap, lir_main_c78,
  lir_main_c7c, lir_main_c80, lir_main_c84, lir_main_c86, lir_main_c88,
  lir_main_c89, lir_main_c8b, lir_main_c8c, lir_main_c8d, lir_main_c8e,
  lm_unused_c94;
  lm_forms := [[ord(of$ip_reg), 0, 16#C0, 0], [ord(of$fp_reg_pair), 0, 16#C0, 0],
               [ord(of$fp_reg), 0, 16#C0, 0], [ord(of$ip_reg), 0, 0, 0],
               [ord(of$fp_reg_pair), 0, 0, 0], [ord(of$fp_reg), 0, 0, 0],
               [0, 0, 0, 0]];
  lm_edges, lm_nconvs, lm_opnd_num, lm_last_ref, lm_mem_lts, lm_ret_bb,
  lm_second_entry, lir_main_da0, lir_main_da4, lm_unused_da6,
  lm_mem_formals, lm_no_return, lm_entry_node, lm_entry_instr, lm_no_xsb,
  lm_unused_db6;

{ The section lir_main_readonly_tables (0x2BE0C0, from the image's
  bytes): by where a formal is passed (arg_loc_t: ip_reg, fp_reg,
  fp_reg_pair, fp_reg_quad, memory, ctl_reg, sr_reg), the load, the
  register move, the store, the operand form and the solution kind of
  its register.  Not known from the original: the names. }
var (lir_main_readonly_tables)
  lm_load_by_loc: lm_by_loc_t := [0, ord(opc$loads), ord(opc$loadd),
                                  ord(opc$loadd), 0, 0, 0];
  lm_move_by_loc: lm_by_loc_t := [ord(opc$move), ord(opc$copys),
                                  ord(opc$copyd), ord(opc$copyd), 0, 0, 0];
  lm_store_by_loc: lm_by_loc_t := [0, ord(opc$stores), ord(opc$stored),
                                   ord(opc$stored), 0, 0, 0];
  lm_form_by_loc: lm_by_loc_t := [ord(of$ip_reg), ord(of$fp_reg),
                                  ord(of$fp_reg_pair), ord(of$fp_reg_pair),
                                  0, 0, 0];
  lm_kind_by_loc: lm_by_loc_t := [11, 8, 9, 9, 0, 0, 0];

{ zero - n bytes from p cleared, a longword at a time ((n + 3) div 4 of
  them; nothing for 0).

  0x248A80, 0x18 bytes, no frame (pattern 100). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param, internal);
type
  longs_t = array [1..65536] of integer32;
var
  q: ^longs_t;
  k: integer32;
begin
  if n <> 0 then begin
    q := p;
    for k := 1 to (n + 3) div 4 do
      q^[k] := 0;
  end;
end;

{ count_registers - the registers in the set s.

  0x248A98, 0x3A bytes, no A5: s (8) in D2; bits 31 down to 0 tested
  (`subq.w #1; and.w #31; btst; sne'), the count in D0. }

function count_registers(
    s: integer32): integer32; options(val_param, internal);
var
  n: integer32;
  k: integer;
begin
  n := 0;
  k := 32;
  repeat
    k := k - 1;
    n := n + ord((k & 31) in bv_word_t(s));
  until k = 0;
  count_registers := n;
end;

{ top_level_inherited_attributes - lir_3b80 made the inherited
  attributes of node's instructions; its address.

  0x248AD2, 0x2E bytes, no A5. }

function top_level_inherited_attributes(
    node: univ_ptr): univ_ptr; options(val_param, internal);
begin
  lir_3b80.il := node;
  lir_3b80.original_il := 0;
  lir_$complete_top_level_node_inherited_attrs(addr(lir_3b80));
  top_level_inherited_attributes := addr(lir_3b80);
end;

{ clean_up_canned_inherited - lir_3b80's exception_frame,
  original_il and stmt_number cleared.

  0x248B00, 0x1E bytes, no frame. }

procedure clean_up_canned_inherited; options(internal);
begin
  lir_3b80.exception_frame := 0;
  lir_3b80.original_il := 0;
  lir_3b80.stmt_number := 0;
end;

{ formal_local_transfer_setup - xfer filled for the formal arg (a
  call_conv_$arg_t): a register candidate passed in a register that
  is not otherwise used (no_modify) and whose variable is of class 5
  or passed by descriptor gets the register's solution as its home;
  the home's solution, the register move, the load (loads) or store
  (stores) by the formal's size; lir_main_400 the home's register
  solution, lir_main_5b0 the argument register's; lir_main_250's node
  and disp the variable and the formal's w6.  The result says how the
  formal moves:
    0 a memory formal without a home, 1 the same of flag 30;
    2 a memory formal split in two singles, 3 a memory formal loaded
      into its home register;
    4 a register formal without a home, stored (5 split, 6 of flag 30
      or not flag 10);
    7 a register formal moved to its home, 8 moved into an integer
      register home of kind 8 or 9 (a pair's halves);
    9 a register formal whose home is a physical register (the callers
      bug-check it).

  0x248B1E, 0x4BA bytes, no A5: xfer (8), arg (12) in D4, loads (16)
  in D3, stores (20); the home in A2, the size in bits in D1 (then the
  load or store), the variable's flags in D0, the result in D0. }

function formal_local_transfer_setup(
    xfer: lm_xfer_ptr_t;
    arg: call_conv_$arg_ptr_t;
    loads: lm_opc5_ptr_t;
    stores: lm_opc5_ptr_t): integer; options(val_param, internal);
var
  cand: boolean;
  sym: il_$node_ptr_t;
  sol: solution_ptr_t;
  home: solution_ptr_t;
  r: integer;
  vat: integer;
  n: integer32;
  flags: integer32;
  in_reg: boolean;
  result: integer;
begin
  if arg^.b25 then
    lm_mem_formals := true;
  cand := isc_$is_a_register_candidate(arg^.sym);
  if arg^.f18.loc <> ord(arg_loc$fp_reg_quad) then
    xfer^.quad := false
  else if xfer^.prolog then
    bug_check('LIR_MAIN: LOCAL_FORMAL_TRANSFER_SETUP -- arg_loc$fp_reg_quad in prolog%$')
  else
    xfer^.quad := true;
  if cand and xfer^.prolog then begin
    sym := arg^.sym;
    if (sym^.kind = var_name) and ((sym^.xw[36] = 5)
                                   or (arg^.f22.mode = 2)) then begin
      sol := nil;
      r := arg^.f22.reg;
      if arg^.f18.loc = ord(arg_loc$ip_reg) then begin
        if lir_4090[r]^.f2.physical_register_is_no_modify then
          sol := lir_3e60[r];
      end
      else if arg^.f18.loc = ord(arg_loc$fp_reg) then begin
        if lir_3f90[r]^.f2.physical_register_is_no_modify then
          sol := lir_3d60[r];
      end
      else if arg^.f18.loc = ord(arg_loc$fp_reg_pair) then begin
        if lir_3f90[r]^.f2.physical_register_is_no_modify then
          if lir_3f90[r ! 1 - (r & 1)]^.f2.physical_register_is_no_modify then
            sol := lir_3d60[r & 16#FFFE];
      end
      else if xfer^.quad then begin
        if lir_3f90[r]^.f2.physical_register_is_no_modify then
          if lir_3f90[r ! 1 - (r & 1)]^.f2.physical_register_is_no_modify then
            if lir_3f90[r + 2]^.f2.physical_register_is_no_modify then
              if lir_3f90[(r ! 1 - (r & 1)) + 2]^.f2.physical_register_is_no_modify then
                sol := lir_3d60[r & 16#FFFE];
      end;
      if sol <> nil then begin
        sym := arg^.sym;
        sol^.object_with_name := sym;
        sol^.live_range^.node20 := sym;
        sym^.xp[15] := il_$node_ptr_t(sol);
        sym^.xc[32] := chr(ord(sym^.xc[32]) ! 2);
      end;
    end;
  end;
  home := isc_$get_home_solution(arg^.sym);
  xfer^.sol := home;
  if not arg^.by_value then
    xfer^.split := false
  else if ((arg^.size + arg^.offset) & 4) = 0 then
    xfer^.split := false
  else if arg^.f16.rlen = 7 then
    xfer^.split := true
  else if home = nil then
    xfer^.split := false
  else
    xfer^.split := home^.kind = 9;
  xfer^.opc := lm_move_by_loc[arg^.f18.loc];
  sym := arg^.sym;
  if sym^.kind = var_name then begin
    vat := sym^.xw[36];
    if vat = 5 then
      n := 32
    else
      n := sym^.xl[9];
    flags := sym^.xl[8];
  end
  else begin
    vat := (ord(sym^.xc[11]) & 16#F0) div 16;
    if vat = 5 then
      n := 32
    else
      n := sz_fsym(sym) * 8;
    flags := sym^.xl[6];
  end;
  in_reg := (vat = 5) or ((flags & 16#800) <> 0);
  xfer^.b11 := (flags & 16#40000000) <> 0;
  lir_main_400.kind := lm_kind_by_loc[arg^.f18.loc];
  lir_main_400.live_range := nil;
  lir_main_400.object_with_name := nil;
  if arg^.f18.loc = ord(arg_loc$memory) then begin
    if home = nil then begin
      if (flags & 16#40000000) <> 0 then
        result := 1
      else
        result := 0;
    end
    else begin
      lir_main_400.object_with_name := home^.object_with_name;
      lir_main_400.live_range := home^.live_range;
      lir_main_400.live_range_of_imaginary_part := home^.live_range_of_imaginary_part;
      if xfer^.split then begin
        result := 2;
        n := loads^[3];
      end
      else begin
        result := 3;
        if xfer^.quad or (home^.kind = 9) then
          n := loads^[4]
        else if home^.kind = 8 then
          n := loads^[3]
        else if n > 16 then
          n := loads^[2]
        else if n > 8 then
          n := loads^[1]
        else
          n := loads^[0];
      end;
    end;
  end
  else begin
    lir_main_5b0.f78.physical_register_number := arg^.f22.reg;
    lir_main_5b0.kind := lm_kind_by_loc[arg^.f18.loc];
    lir_main_5b0.live_range := nil;
    if home <> nil then begin
      lir_main_400.object_with_name := home^.object_with_name;
      lir_main_400.live_range := home^.live_range;
      lir_main_400.live_range_of_imaginary_part := home^.live_range_of_imaginary_part;
      if (home^.kind = 8) and (arg^.f18.loc = ord(arg_loc$ip_reg)) then
        result := 8
      else if (home^.kind = 9) and (arg^.f18.loc = ord(arg_loc$ip_reg)) then begin
        if arg^.w6 = 0 then
          lir_main_400.kind := 2
        else begin
          lir_main_400.object_with_name := nil;
          lir_main_400.kind := 3;
        end;
        lir_main_400.live_range := home^.live_range;
        result := 8;
      end
      else if home^.f78.physical_register then
        result := 9
      else begin
        if xfer^.quad then
          xfer^.sol := addr(lir_main_400);
        result := 7;
      end;
    end
    else begin
      lm_mem_formals := true;
      if ((flags & 16#400) = 0) or ((flags & 16#40000000) <> 0) then
        result := 6
      else if xfer^.split then
        result := 5
      else
        result := 4;
    end;
    if xfer^.split then
      n := stores^[3]
    else if xfer^.quad or (arg^.f18.loc = ord(arg_loc$fp_reg_pair)) then
      n := stores^[4]
    else if arg^.f18.loc = ord(arg_loc$fp_reg) then
      n := stores^[3]
    else if n > 16 then
      n := stores^[2]
    else if n > 8 then
      n := stores^[1]
    else
      n := stores^[0];
  end;
  if in_reg then begin
    if lir_main_400.live_range <> nil then
      lir_main_400.live_range^.rrp := lir_main_400.live_range^.rrp + [rrp$unique_value];
    if lir_main_400.live_range_of_imaginary_part <> nil then
      lir_main_400.live_range_of_imaginary_part^.rrp := lir_main_400.live_range_of_imaginary_part^.rrp + [rrp$unique_value];
  end;
  lir_main_250.object_with_name := arg^.sym;
  lir_main_250.literal_32_bits_value := arg^.w6;
  xfer^.ldst := n;
  formal_local_transfer_setup := result;
end;

{ lir_main_$add_live_range - a new live range for sol, its node sol's;
  a physical register's (reg its number, no_modify and serialize
  clear in both) when reg is not negative, else an integer register's
  with unique_value and safe_base_address; sol's live_range.

  0x249020, 0x66 bytes: sol (8) in A2, reg (12) in D2; the live range
  in A0. }

function lir_main_$add_live_range(
    sol: solution_ptr_t;
    reg: integer32): lr_ptr_t;
var
  lr: lr_ptr_t;
begin
  lr := lir_$new_live_range;
  if reg < 0 then begin
    lr^.rrp := [rrp$unique_value, rrp$safe_base_address, rrp$ip_reg];
    sol^.f78.physical_register := false;
  end
  else begin
    lr^.f2.physical_register := true;
    lr^.f2.physical_register_number := reg;
    lr^.f2.physical_register_is_no_modify := false;
    lr^.f2.physical_register_user_declared := false;
    sol^.f78.physical_register := true;
    sol^.f78.physical_register_number := reg;
    sol^.f78.physical_register_is_no_modify := false;
    sol^.f78.physical_register_user_declared := false;
  end;
  lr^.node20 := sol^.object_with_name;
  sol^.live_range := lr;
  lir_main_$add_live_range := lr;
end;

{ lir_main_$add_ip_reg_physical_lr - integer register reg's physical
  live range given sol's object_with_name and to sol (physical, its register, its
  no_modify and serialize copied).

  0x249086, 0x80 bytes: sol (8) in A0, reg (12) in D0; A0. }

function lir_main_$add_ip_reg_physical_lr(
    sol: solution_ptr_t;
    reg: integer32): lr_ptr_t;
var
  lr: lr_ptr_t;
begin
  lr := lir_4090[reg];
  lr^.node20 := sol^.object_with_name;
  lr^.rrp := [rrp$unique_value, rrp$safe_base_address, rrp$ip_reg];
  sol^.f78.physical_register := true;
  sol^.f78.physical_register_number := reg;
  sol^.f78.physical_register_is_no_modify := lr^.f2.physical_register_is_no_modify;
  sol^.f78.physical_register_user_declared := lr^.f2.physical_register_user_declared;
  sol^.live_range := lr;
  lir_main_$add_ip_reg_physical_lr := lr;
end;

{ lir_main_$reinit_physical_regs - for which 0, integer registers 0..31
  (lir_3e60, lir_4090: rrp ip_reg, the node lir_main_ac0's); 1,
  floating registers 0..63 (lir_3d60, lir_3f90: the node lir_main_b40's);
  -1, the floating pairs: an odd register's live range and the even
  one's made mates (rrp fp_reg and odd or even only), the even one's
  pair solution (lir_3c60) its live range's.  A register the
  conventions read (ip76 less bit 31, fp60 for 32..63, the next
  longword for 0..31) gets no_modify in its live range and solution.

  0x249106, 0x182 bytes: conv (12), which (16) in D2; the register in
  D4, the six tables walked by frame pointers (-28 .. -48); the set
  tests `and.w #31; cmp.w; bcs; btst; shi'. }

procedure lir_main_$reinit_physical_regs(
    rtn: rtn_ptr_t;
    conv: univ_ptr;
    which: integer32);
var
  k: integer32;
  sol: solution_ptr_t;
  lr: lr_ptr_t;
  lr0: lr_ptr_t;
  regs: integer32;
  cv: call_conv_$ptr_t;
  skip: boolean;
begin
  cv := conv;
  for k := 0 to 63 do begin
    skip := false;
    if which = 0 then begin
      if k > 31 then
        skip := true
      else begin
        sol := lir_3e60[k];
        sol^.object_with_name := lir_main_ac0[k];
        lr := lir_main_$add_live_range(sol, k);
        lir_4090[k] := lr;
        lr^.rrp := [rrp$ip_reg];
        lr^.node20 := lir_main_ac0[k];
        regs := cv^.ip76 & 16#7FFFFFFF;
      end;
    end
    else begin
      if which > 0 then begin
        sol := lir_3d60[k];
        sol^.object_with_name := lir_main_b40[k];
        lr := lir_main_$add_live_range(sol, k);
        lr^.node20 := lir_main_b40[k];
        lir_3f90[k] := lr;
      end
      else if odd(k) then begin
        lr := lir_3f90[k];
        lr0 := lir_3f90[k - 1];
        lr^.rrp := [rrp$fp_reg_odd_only, rrp$fp_reg];
        lr^.mate := lr0;
        lr0^.rrp := [rrp$fp_reg_even_only, rrp$fp_reg];
        lr0^.mate := lr;
        skip := true;
      end
      else begin
        sol := lir_3c60[k];
        sol^.f78.physical_register := true;
        sol^.f78.physical_register_number := k;
        sol^.object_with_name := lir_main_b40[k];
        lr := lir_3f90[k];
        sol^.live_range := lr;
      end;
      if k >= 32 then
        regs := cv^.fp60[0]
      else
        regs := cv^.fp60[1];
    end;
    if not skip then begin
      lr^.f2.physical_register_is_no_modify := (k & 31) in bv_word_t(regs);
      sol^.f78.physical_register_is_no_modify := (k & 31) in bv_word_t(regs);
    end;
  end;
end;

{ lir_main_$begin_routine - lir readied for rtn (lir_$reinitialize),
  isc_user_routines_358 set unless -NO_FP or il_180's +374 bit 4;
  lm_convs[1] the routine's conventions.  For a FORTRAN routine (the
  block's +377 bits 6..4 2) whose +294 is not positive, each of its
  entries (the block and those chained at +4 of kind 167 or +294
  positive; their +294 positive skipped) gives its formals' symbols
  their places: a variable or common member formal (kinds 0..2) its
  offset at +58 the first time (flag 19), flag 30 when it differs; a
  string's (3, 4: register formals chained at +28 by register, the
  entry with the highest register kept; memory formals chained by size,
  the entry with the largest kept) and a string length's (5, 6: chained,
  the largest size) sizes at +62.  The chains are made rings and each
  member given its offset from the largest (+12).  The entries kept
  are lm_convs[1..2].  Then the local symbols (sym).

  0x249288, 0x30A bytes: the block in (-52); the jump table at
  0x249376 (the kinds 0..6); the chains' heads at (-24) (register
  strings), (-8) (memory strings), (-32) (lengths), the largest at
  D5, (-36); the entries kept at (-44), (-40).  The test of kind 4 in
  the lengths' arm (5, 6) is never true (kept). }

procedure lir_main_$begin_routine(
    rtn: rtn_ptr_t);
var
  blk: il_$node_ptr_t;
  conv: call_conv_$ptr_t;
  ent_reg: call_conv_$ptr_t;
  ent_mem: call_conv_$ptr_t;
  regs: il_$node_ptr_t;
  mems: il_$node_ptr_t;
  lens: il_$node_ptr_t;
  mem_max: integer32;
  len_max: integer32;
  reg_max: integer;
  j: integer32;
  arg: call_conv_$arg_ptr_t;
  sym: il_$node_ptr_t;
  p: il_$node_ptr_t;
begin
  lir_$reinitialize(rtn);
  isc_user_routines_358 := not ((13 in cargs_$options.flags_286)
                                or ((ord(il_180^.xc[374]) & 16#10) <> 0));
  lir_main_c8b := false;
  lm_second_entry := nil;
  blk := rtn^.node;
  lm_nconvs := 1;
  lm_convs[1] := call_conv_$ptr_t(blk^.xp[32]);
  if ((ord(blk^.xc[377]) & 16#70) div 16 = 2)
     and not ((ord(blk^.xc[294]) > 0) and (ord(blk^.xc[294]) < 128)) then begin
    ent_reg := nil;
    ent_mem := nil;
    lens := nil;
    len_max := 0;
    regs := nil;
    mems := nil;
    mem_max := 0;
    repeat
      if not ((ord(blk^.xc[294]) > 0) and (ord(blk^.xc[294]) < 128)) then begin
        if blk^.kind = entry_blk then
          lir_main_c8b := true;
        conv := call_conv_$ptr_t(blk^.xp[32]);
        for j := 1 to conv^.nargs do begin
          arg := addr(conv^.args[j]);
          if (arg^.w6 = 0) and (arg^.f20.kind < 7) then
            case arg^.f20.kind of
              0, 1, 2: begin
                sym := arg^.sym;
                if (sym^.xl[6] & 16#80000) = 0 then begin
                  sym^.xc[25] := chr(ord(sym^.xc[25]) ! 8);
                  sym^.xl2[14] := arg^.offset;
                end;
                if ((sym^.xw[13] & 16#100) <> 0) or (sym^.xl2[14] <> arg^.offset) then
                  sym^.xc[24] := chr(ord(sym^.xc[24]) ! 16#40);
              end;
              3, 4: begin
                p := arg^.sym;
                if arg^.f18.loc = 0 then begin
                  if arg^.f20.kind = 4 then
                    p^.xl2[15] := 4
                  else
                    p^.xl2[15] := sz_fsym(p);
                  if mem_max < p^.xl2[15] then begin
                    mem_max := p^.xl2[15];
                    ent_mem := conv;
                  end;
                  p^.xp[7] := mems;
                  mems := p;
                end
                else begin
                  if (ent_reg = nil) or (arg^.f18.loc > reg_max) then begin
                    reg_max := arg^.f18.loc;
                    ent_reg := conv;
                  end;
                  p^.xp[7] := regs;
                  regs := p;
                end;
              end;
              5, 6: begin
                p := arg^.sym;
                if arg^.f20.kind = 4 then
                  p^.xl2[15] := 4
                else
                  p^.xl2[15] := sz_fsym(p);
                if p^.xl2[15] > len_max then
                  len_max := p^.xl2[15];
                if lens <> p then
                  p^.xp[7] := lens;
                lens := p;
              end;
            end;
        end;
      end;
      blk := blk^.xp[1];
    until (blk = nil)
          or ((blk^.kind <> entry_blk)
              and not ((ord(blk^.xc[294]) > 0) and (ord(blk^.xc[294]) < 128)));
    if (ent_reg <> nil) or (ent_mem <> nil) then begin
      lm_nconvs := 0;
      if ent_reg <> nil then begin
        lm_nconvs := lm_nconvs + 1;
        lm_convs[lm_nconvs] := ent_reg;
      end;
      if ent_mem <> nil then begin
        lm_nconvs := lm_nconvs + 1;
        lm_convs[lm_nconvs] := ent_mem;
      end;
    end;
    if regs <> nil then
      if regs^.xp[7] <> nil then begin
        p := regs;
        repeat
          p^.xl[3] := 0;
          if p^.xp[7] <> nil then
            p := p^.xp[7];
        until p^.xp[7] = nil;
        p^.xp[7] := regs;
      end;
    if mems <> nil then
      if mems^.xp[7] <> nil then begin
        p := mems;
        repeat
          p^.xl[3] := mem_max - p^.xl2[15];
          if p^.xp[7] <> nil then
            p := p^.xp[7];
        until p^.xp[7] = nil;
        p^.xp[7] := mems;
      end;
    if lens <> nil then
      if lens^.xp[7] <> nil then begin
        p := lens;
        repeat
          p^.xl[3] := len_max - p^.xl2[15];
          if p^.xp[7] <> nil then
            p := p^.xp[7];
        until p^.xp[7] = nil;
        p^.xp[7] := lens;
      end;
  end;
  lm_mem_formals := false;
  sym_$initialize_local_symbols(rtn);
end;

{ make_xsb_a_register_candidate - the XSB pointer x's variable (+24)
  given the type isc_user_routines_34c; one that may not live in a
  register replaced by a new temporary (kind 122, 32 bits, flag 14,
  its +4 x) whose live range keeps the old variable as its memory home
  (else none); the live range unique_value and safe_base_address.

  0x249592, 0x7E bytes, no A5: x (8) in A3, the variable in A2, the
  home in A4. }

procedure make_xsb_a_register_candidate(
    x: il_$node_ptr_t); options(val_param, internal);
var
  v: il_$node_ptr_t;
  home: il_$node_ptr_t;
  lr: lr_ptr_t;
begin
  v := x^.xp[6];
  v^.xp[7] := isc_user_routines_34c;
  if isc_$is_a_register_candidate(v) then
    home := nil
  else begin
    home := v;
    v := make_expression_temporary(122, 32);
    x^.xp[6] := v;
    v^.xp[1] := x;
    v^.xl[8] := 16#4000;
    v^.xp[7] := isc_user_routines_34c;
  end;
  lr := isc_$get_home_solution(v)^.live_range;
  lr^.memory_home := home;
  lr^.rrp := lr^.rrp + [rrp$unique_value, rrp$safe_base_address];
end;

{ lir_main_$entry - the entry statement node: for the routine's first
  entry the ENTRY instruction (106 operands: 1 the block, 2 the symbol
  operand, 3.. the integer registers 0..29, 33.. the floating
  registers 0..63; its block an entry, an edge to it from lir_41f0) and
  its LIMIT (96 operands, the ENTRY's operand 1); the conventions'
  registers counted for sched and ra (an odd floating register not
  read and its even mate are a pair, the others counted); the argument
  pointer and DB register moves, and each formal moved to its home
  (formal_local_transfer_setup's cases); the XSB pointers made register
  candidates; rewrite_$entry.  For a second entry (lm_second_entry) the
  node is put in place of the first one's on the statement chain and
  the XSB bases (+180, chained at +4) loaded from the frame, each from
  the one before (an XSB displacement beyond 32767 through a scaled or
  constant index), the ENTRY's integer registers 0..29 and floating
  registers not serialized whose live ranges are not true_write
  dropped from it (kind none).

  0x249610, 0xAC4 bytes: node (8); the block (-64), the routine A4,
  the conventions (-56), the inherited attributes (-40); the jump table
  at 0x2499FC.  In the case 8 arm the next formal's loc is read with
  the formal's index register still 26 times its number (`cmpi.b
  #4,(0x62,A1,D4.l)'): conv^.args[j + 1].  The set loop ors into
  frame copies (-32, -28) the registers never stores (pattern 143). }

procedure lir_main_$entry(
    node: univ_ptr);
var
  nd: il_$node_ptr_t;
  blk: il_$node_ptr_t;
  rtn: rtn_ptr_t;
  inh: univ_ptr;
  conv: call_conv_$ptr_t;
  ins: instr_ptr_t;
  ins2: instr_ptr_t;
  k: integer32;
  n: integer32;
  s1: bv_word_t;
  s2: bv_word_t;
  r: integer;
  j: integer32;
  arg: call_conv_$arg_ptr_t;
  v: il_$node_ptr_t;
  first: boolean;
  prev: integer32;
  prev_sol: solution_ptr_t;
  sol: solution_ptr_t;
  d: integer32;
  sh: integer32;
  done: boolean;
begin
  nd := node;
  blk := nd^.xp[12];
  if blk^.kind = entry_blk then
    rtn := rtn_ptr_t(blk^.xp[37]^.xp[31])
  else
    rtn := rtn_ptr_t(blk^.xp[31]);
  inh := top_level_inherited_attributes(nd);
  if nd <> lm_second_entry then begin
    lm_entry_node := nd;
    conv := call_conv_$ptr_t(blk^.xp[32]);
    n := conv^.args_size + 16;
    if n > rtn^.l176 then
      rtn^.l176 := n;
    ins := lir_$get_new_instruction_no_exceptions(nil, ord(opc$entry), 0, nil, 106);
    lm_entry_instr := ins;
    ins^.opnds[1].h.kind := operand$symbol_definition;
    ins^.opnds[1].h.num := 1;
    ins^.opnds[1].link := opnd_ptr_t(blk);
    lir_4216 := 0;
    lm_forms[0].num := 2;
    lir_$build_operand(addr(ins^.opnds[2]), lir_main_da0, lm_forms[0]);
    for k := 0 to 29 do begin
      lm_forms[0].num := k + 3;
      lir_$build_operand(addr(ins^.opnds[k + 3]), lir_3e60[k], lm_forms[0]);
    end;
    for k := 0 to 63 do begin
      lm_forms[2].num := k + 33;
      lir_$build_operand(addr(ins^.opnds[k + 33]), lir_3d60[k], lm_forms[2]);
    end;
    n := 0;
    s1 := [];
    s2 := [];
    r := 31;
    repeat
      if (r & 31) in bv_word_t(conv^.fp60[0]) then
        s1 := s1 + [r & 31] + [(r - 1) & 31]
      else
        n := n + 1;
      if (r & 31) in bv_word_t(conv^.fp60[1]) then
        s2 := s2 + [r & 31] + [(r - 1) & 31]
      else
        n := n + 1;
      r := r - 2;
    until r < 0;
    sched_3158 := n;
    ra_658 := integer32(s1);
    ra_654 := integer32(s2);
    lir_$complete_instruction(ins);
    ins^.bb^.f.entry := true;
    discard(lir_$add_flow_graph_edge(lir_41f0, ins^.bb));
    ins2 := lir_$get_new_instruction_no_exceptions(nil, ord(opc$limit), 0, nil, 96);
    ins^.opnds[1].ptr := ins2;
    lir_$complete_instruction(ins2);
    lir_4216 := 1024;
    lir_$simple_instruction(inh, ord(opc$move), 16#2000000, lir_3e60[1],
                            isc_user_routines_33c, nil, nil);
    if not rtn^.db_lr^.f2.physical_register_is_no_modify then
      lir_$simple_instruction(inh, ord(opc$move), 16#2000000,
                              lir_3e60[conv^.w16], isc_user_routines_338, nil, nil);
    if not conv^.b30 then
      lir_$simple_instruction(inh, ord(opc$move), 0, lir_3e60[conv^.w12],
                              isc_user_routines_32c, nil, nil);
    for j := 1 to conv^.nargs do begin
      arg := addr(conv^.args[j]);
      if not arg^.by_value or (arg^.num <> 0) then begin
        lir_main_760.literal_32_bits_value := arg^.offset + 16;
        lir_main_400.kind := 11;
        lir_main_400.live_range := nil;
        lir_main_250.object_with_name := arg^.sym;
        if arg^.w6 = 0 then begin
          v := arg^.sym;
          if v^.kind = var_name then
            v^.xl[14] := arg^.offset + 16
          else
            v^.xl[3] := arg^.offset + 16;
        end;
        done := false;
        case formal_local_transfer_setup(addr(lm_prolog_xfer), arg,
                                         addr(lm_loads), addr(lm_stores)) of
          0:
            done := true;
          1: begin
            lir_$load_instruction(inh, ord(opc$loadl), 0, addr(lir_main_760),
                                  isc_user_routines_33c, addr(lir_main_400), nil, 0, 0, 7);
            lir_$store_instruction(inh, ord(opc$storel), 0, addr(lir_main_400),
                                   addr(lir_main_250), isc_user_routines_340,
                                   arg^.sym, arg^.w6, arg^.w6, 7);
            done := true;
          end;
          6: begin
            lir_$store_instruction(inh, ord(opc$storel), 0, addr(lir_main_5b0),
                                   addr(lir_main_250), isc_user_routines_340,
                                   arg^.sym, arg^.w6, arg^.w6, 7);
            done := true;
          end;
          3: begin
            lir_main_760.il := arg^.sym;
            lir_$load_instruction(inh, lm_prolog_xfer.ldst, 0, addr(lir_main_760),
                                  isc_user_routines_33c, lm_prolog_xfer.sol,
                                  arg^.sym, arg^.w6, arg^.w6, 7);
            lir_main_760.il := nil;
            if lm_prolog_xfer.b11 then
              lir_$store_instruction(inh, ord(opc$storel), 0, lm_prolog_xfer.sol,
                                     addr(lir_main_250), isc_user_routines_340,
                                     nil, 0, 0, 7);
            done := true;
          end;
          2: begin
            lir_main_760.il := arg^.sym;
            if arg^.w6 = 0 then begin
              lir_main_400.kind := 2;
              lir_$load_instruction(inh, lm_prolog_xfer.ldst, 0, addr(lir_main_760),
                                    isc_user_routines_33c, addr(lir_main_400),
                                    arg^.sym, arg^.w6, lir_main_760.literal_32_bits_value,
                                    7);
              lir_main_760.literal_32_bits_value := lir_main_760.literal_32_bits_value + 4;
            end;
            lir_main_400.kind := 3;
            lir_$load_instruction(inh, lm_prolog_xfer.ldst, 0, addr(lir_main_760),
                                  isc_user_routines_33c, addr(lir_main_400),
                                  arg^.sym, arg^.w6, lir_main_760.literal_32_bits_value,
                                  7);
            lir_main_760.il := nil;
            done := true;
          end;
          4: begin
            lir_$store_instruction(inh, lm_prolog_xfer.ldst, 0, addr(lir_main_5b0),
                                   addr(lir_main_250), isc_user_routines_33c,
                                   arg^.sym, arg^.w6, arg^.w6, 7);
            done := true;
          end;
          5: begin
            lir_$simple_instruction(inh, ord(opc$copyd), 0, addr(lir_main_5b0),
                                    addr(lir_main_400), nil, nil);
            lir_main_400.kind := 2;
            lir_$store_instruction(inh, ord(opc$stores), 0, addr(lir_main_400),
                                   addr(lir_main_250), isc_user_routines_33c,
                                   arg^.sym, arg^.w6, arg^.w6, 7);
            lir_main_400.kind := 3;
            lir_main_250.literal_32_bits_value := 4;
            lir_$store_instruction(inh, ord(opc$stores), 0, addr(lir_main_400),
                                   addr(lir_main_250), isc_user_routines_33c,
                                   arg^.sym, arg^.w6 + 4, arg^.w6 + 4,
                                   7);
            lir_main_250.literal_32_bits_value := 0;
            done := true;
          end;
          7:
            lir_$simple_instruction(inh, lm_prolog_xfer.opc, 0, addr(lir_main_5b0),
                                    lm_prolog_xfer.sol, nil, nil);
          8: begin
            lir_$simple_instruction(inh, ord(opc$mtfp), 0, addr(lir_main_5b0),
                                    addr(lir_main_400), nil, nil);
            if (lm_prolog_xfer.sol^.kind = 9) and (arg^.w6 = 0) and (arg^.size <= 4) then
              if conv^.args[j + 1].f18.loc <> 4 then
                done := true;
          end;
          otherwise begin
            bug_check('LIR_MAIN_$BEGIN_ROUTINE -- unexpected result from formal_local_transfer_setup%$');
            done := true;
          end;
        end;
        if not done and arg^.b25 then begin
          if lm_prolog_xfer.split then begin
            lir_main_760.il := arg^.sym;
            lir_main_400.kind := 2;
            lir_$store_instruction(inh, ord(opc$stores), 0, addr(lir_main_400),
                                   addr(lir_main_760), isc_user_routines_33c,
                                   arg^.sym, arg^.w6, arg^.w6, 7);
            lir_main_400.kind := 3;
            lir_main_760.literal_32_bits_value := lir_main_760.literal_32_bits_value + 4;
            lir_$store_instruction(inh, ord(opc$stores), 0, addr(lir_main_400),
                                   addr(lir_main_760), isc_user_routines_33c,
                                   arg^.sym, arg^.w6 + 4, arg^.w6 + 4,
                                   7);
            lir_main_760.il := nil;
          end
          else if lm_prolog_xfer.b11 then
            lir_$store_instruction(inh, ord(opc$storel), 0, lm_prolog_xfer.sol,
                                   addr(lir_main_250), isc_user_routines_340,
                                   nil, 0, 0, 7)
          else
            lir_$store_instruction(inh, lm_prolog_xfer.ldst, 0, lm_prolog_xfer.sol,
                                   addr(lir_main_760), isc_user_routines_33c,
                                   nil, 0, 0, 7);
        end;
      end;
    end;
    v := blk^.xp[45];
    while v <> nil do begin
      make_xsb_a_register_candidate(v);
      v := v^.xp[1];
    end;
    rewrite_$entry(nd, lm_no_xsb, lm_second_entry);
  end
  else begin
    il_$node_ptr_t(lm_entry_node)^.xp[2] := nd^.xp[2];
    nd^.xp[2]^.xp[1] := lm_entry_node;
    if blk^.kind = entry_blk then
      blk := blk^.xp[37];
    v := blk^.xp[45];
    if v <> nil then begin
      rtn^.f226.needs_frame := true;
      if not lm_no_xsb then
        if v^.xl[3] - blk^.xl[28] * 2 > 32767 then begin
          discard(make_xdynm_ptr(blk, 0));
          v := blk^.xp[45];
        end;
      prev_sol := isc_user_routines_340;
      first := true;
      prev := 0;
      repeat
        sol := isc_$get_home_solution(v^.xp[6]);
        if not (first and lm_no_xsb) then begin
          d := v^.xl[3] - prev;
          if d <= 32767 then begin
            lir_main_760.literal_32_bits_value := d;
            lir_$simple_instruction(inh, ord(opc$add), 0, addr(lir_main_760),
                                    prev_sol, sol, nil);
            if first then
              lir_41fc^.last^.opnds[1].h.kind := operand$displacement_XSB_base;
          end
          else begin
            lir_main_400.kind := 11;
            lir_main_400.live_range := nil;
            sh := -1;
            if (d <= 262143) and ((d & 7) = 0) then
              sh := 3
            else if (d <= 131071) and ((d & 3) = 0) then
              sh := 2
            else if (d <= 65535) and not odd(d) then
              sh := 1
            else begin
              lir_main_250.object_with_name := smcontk(linteger_ob, d);
              lir_main_250.bytes := 4;
              lir_$load_instruction(inh, ord(opc$loadl), 0, addr(lir_main_250),
                                    isc_user_routines_330, addr(lir_main_400),
                                    nil, 0, 0, 3);
            end;
            if sh >= 0 then begin
              lir_main_760.literal_32_bits_value := rshft(d, sh);
              lir_$simple_instruction(inh, ord(opc$move), 0, addr(lir_main_400),
                                      addr(lir_main_760), nil, nil);
              lir_main_400.kind := 13;
              lir_main_400.f78.scale := sh;
            end;
            lir_$simple_instruction(inh, ord(opc$add), 0, addr(lir_main_400),
                                    prev_sol, sol, nil);
            lir_main_400.kind := 11;
            lir_main_400.f78.scale := 0;
          end;
        end;
        if sol^.live_range <> nil then
          if sol^.live_range^.memory_home <> nil then begin
            lir_main_250.object_with_name := sol^.live_range^.memory_home;
            lir_$store_instruction(inh, ord(opc$storel), 0, sol,
                                   addr(lir_main_250), isc_user_routines_340,
                                   sol^.live_range^.memory_home, 0, 0, 0);
          end;
        first := false;
        prev_sol := sol;
        prev := v^.xl[3];
        v := v^.xp[1];
      until v = nil;
    end;
    ins := lm_entry_instr;
    for k := 0 to 63 do begin
      if k <= 29 then
        if not lir_4090[k]^.f2.physical_register_user_declared then
          if not (rrp$true_write in ins^.opnds[k + 3].lts^.lr^.rrp) then
            ins^.opnds[k + 3].h.kind := operand$none;
      if not lir_3f90[k]^.f2.physical_register_user_declared then
        if not (rrp$true_write in ins^.opnds[k + 33].lts^.lr^.rrp) then
          ins^.opnds[k + 33].h.kind := operand$none;
    end;
  end;
  clean_up_canned_inherited;
end;

{ lir_main_$handler_reentry - the exception handler statement node's
  re-entry label (node +60, a new label with the node's +68 bit 7 in
  its flags, its label instruction preallocated and given the node's
  line) placed, the return address register reloaded from its home
  (isc_user_routines_328), and the node's +64 label (made when there is
  none) placed.

  0x24A124, 0xBC bytes: node (8) in A3; `addq.l #2,SP' after the first
  lir_$label (pattern 130). }

procedure lir_main_$handler_reentry(
    node: univ_ptr);
var
  nd: il_$node_ptr_t;
  lab: lm_label_ptr_t;
  li: instr_ptr_t;
begin
  nd := node;
  lab := lir_$new_label;
  nd^.xp[15] := il_$node_ptr_t(lab);
  lab^.f10.b6 := ord(nd^.xc[68]) >= 128;
  li := zzzzz_$preallocate_label;
  lab^.instr := li;
  nd^.xp[13] := il_$node_ptr_t(li);
  li^.l32 := (li^.l32 & 16#FFFF) ! lshft(rshft(nd^.xl2[10] & 16#FFFF00, 8), 16);
  lir_$label(nd^.xp[15]);
  lir_$simple_instruction(top_level_inherited_attributes(nd), ord(opc$move), 0,
                          lir_3e60[0], isc_user_routines_328, nil, nil);
  lir_main_760.il := nil;
  clean_up_canned_inherited;
  if nd^.xp[16] = nil then
    nd^.xp[16] := lir_$new_label;
  lir_$label(nd^.xp[16]);
end;

{ fix_silly_register_candidates - a live range with a memory home, not
  physical and not marked (+3 bit 0) yet, whose every reference is an
  instruction that refers to the memory home and none volatile, is
  marked (traced when the switches' level has bit 2).  Then a marked
  live range whose mate is not marked is unmarked, and on the memory
  live range (rtn +140) each segment written by a store of a marked
  live range's register is dropped: its readers moved to the next
  segment (their rrp bits ored into it), the next segment dropped too
  when it has no references, and the store's memory operands cleared
  from the last until the one that reads.  The memory live range's rrp
  bits 5..2 become those of its remaining segments ored (the other bits
  ored in as well).

  0x24A1E0, 0x2DA bytes, no A5: rtn (8) in D4; changed in D2; the
  instruction of an operand computed inline (patterns 121, 131); the
  previous segment in D5; the store in (-24). }

procedure fix_silly_register_candidates(
    rtn: rtn_ptr_t); options(val_param, internal);
label
  1;
var
  changed: boolean;
  lr: lr_ptr_t;
  lts: lts_ptr_t;
  op: opnd_ptr_t;
  instr: instr_ptr_t;
  v: il_$node_ptr_t;
  nm: il_$node_ptr_t;
  rn: il_$node_ptr_t;
  acc: integer;
  prev: lts_ptr_t;
  first_ref: opnd_ptr_t;
  a: opnd_ptr_t;
  bits: integer;
  k: integer32;
  t: integer;
begin
  changed := false;
  lr := rtn^.lrs;
  while lr <> nil do begin
    if lr^.memory_home <> nil then
      if not lr^.f2.b3_0 then
        if not lr^.f2.physical_register then begin
          lts := lr^.ltss;
          while lts <> nil do begin
            op := lts^.refs;
            while op <> nil do begin
              instr := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
              if not utils_$instr_is_ref_to_memory_home(instr) then
                goto 1;
              if instr^.h.volatile_location then
                goto 1;
              op := op^.link;
            end;
            lts := lts^.next;
          end;
          changed := true;
          lr^.f2.b3_0 := true;
          if (at_backend_switches.level & 4) <> 0 then begin
            v := lr^.memory_home;
            rn := il_180^.xp[74];
            if v^.kind = fortran_symbol then
              vfmt_$write('Silly register candidate in %A: %A%.',
                          rn^.str_chars, rn^.str_len, v^.xc[72], v^.xw[35])
            else begin
              nm := v^.xp[1];
              if nm = nil then
                nm := il_$node_ptr_t(lr^.node20)^.xp[1];
              if nm = nil then
                vfmt_$write('Anonymous silly register candidate in %A%.',
                            rn^.str_chars, rn^.str_len)
              else
                vfmt_$write('Silly register candidate in %A: %A%.',
                            rn^.str_chars, rn^.str_len, nm^.str_chars, nm^.str_len);
            end;
          end;
        end;
  1:
    lr := lr^.next;
  end;
  if changed then begin
    lr := rtn^.lrs;
    while lr <> nil do begin
      if lr^.f2.b3_0 then
        if lr^.mate <> nil then
          if not lr^.mate^.f2.b3_0 then
            lr^.f2.b3_0 := false;
      lr := lr^.next;
    end;
    prev := nil;
    acc := 0;
    lts := rtn^.lr140^.ltss;
    while lts <> nil do begin
      if (integer(lts^.rrp) & 12) <> 0 then begin
        first_ref := lts^.refs;
        instr := instr_ptr_t(integer32(first_ref) - 32 - 12 * first_ref^.h.num);
        if instruction_attributes[instr^.opc].class = class$store then
          if lts_ptr_t(instr^.opnds[1].lts)^.lr^.f2.b3_0 then begin
            lts := lts^.next;
            prev^.next := lts;
            a := lts^.refs;
            bits := 0;
            if a^.link = nil then begin
              a := first_ref^.link;
              lts^.refs := a;
            end
            else begin
              while a^.link^.link <> nil do begin
                bits := bits ! opnd_bytes_ptr_t(a)^.rrp;
                a := a^.link;
              end;
              a^.link := first_ref^.link;
            end;
            while a <> nil do begin
              bits := bits ! opnd_bytes_ptr_t(a)^.rrp;
              a^.lts := lts;
              a := a^.link;
            end;
            bits := (integer(lts^.rrp) & 16#FFC3) ! (bits & 60);
            lts^.rrp := rrp$set_t(bits);
            if lts^.refs = nil then
              prev^.next := lts^.next;
            for k := instr^.h.nopnds downto 1 do
              if instr^.opnds[k].h.kind in [operand$argument_block_memory..operand$well_behaved_memory] then begin
                instr^.opnds[k].lts := nil;
                instr^.opnds[k].h.kind := operand$none;
                instr^.opnds[k].h.num := 0;
                t := opnd_bytes_ptr_t(addr(instr^.opnds[k]))^.rrp;
                opnd_bytes_ptr_t(addr(instr^.opnds[k]))^.rrp := 0;
                if (t & 16) <> 0 then
                  exit;
              end;
            lts := prev;
          end;
      end;
      acc := acc ! integer(lts^.rrp);
      prev := lts;
      lts := lts^.next;
    end;
    acc := (integer(rtn^.lr140^.rrp) & 16#FFC3) ! acc;
    rtn^.lr140^.rrp := rrp$set_t(acc);
  end;
end;

{ by_branch_prologs_for_handler - the handler h's prologs that its
  branches reach (h +56, chained at +0): each one's label placed, its
  exception variable (+8, a VAR_NAME) loaded into the return address
  register: a static one (vat 3, 7, 8: through an address constant of
  kind 2 for vat 3, else 1) loaded from the address constant's
  displacement, a frame one (vat 1, 4) its address added to the frame;
  then a jump to h's +64 label.

  0x24A508, 0x150 bytes, no A5: h (8) in A3; the prologs in A2. }

procedure by_branch_prologs_for_handler(
    h: il_$node_ptr_t); options(val_param, internal);
type
  { A prolog of the handler (h +56): next (+0), its label (+4), the
    exception's variable (+8). }
  prolog_ptr_t = ^prolog_t;
  prolog_t = record
    next: prolog_ptr_t;
    lab: univ_ptr;
    v: il_$node_ptr_t;
  end;
var
  inh: univ_ptr;
  p: prolog_ptr_t;
  v: il_$node_ptr_t;
  vat: integer;
  off: integer32;
  kind: integer;
begin
  inh := top_level_inherited_attributes(h);
  p := prolog_ptr_t(h^.xp[14]);
  while p <> nil do begin
    lir_$label(p^.lab);
    v := p^.v;
    if v^.kind <> var_name then
      bug_check('LIR_MAIN_\BY_BRANCH_PROLOGS_FOR_HANDLER -- exception not identified by a var_name%$');
    vat := v^.xw[36];
    if vat in [3, 7, 8] then begin
      off := 0;
      if vat = 3 then
        kind := 2
      else
        kind := 1;
      v := get_addr_con(kind, v, off, il_180^.xp[48], true);
      lir_main_760.il := v;
      lir_main_760.literal_32_bits_value := v^.xl[4];
      lir_$load_instruction(inh, ord(opc$loadl), 16#1000, addr(lir_main_760),
                            isc_user_routines_338, isc_user_routines_328,
                            nil, 0, v^.xl[4], 7);
    end
    else if vat in [1, 4] then begin
      lir_main_760.il := v;
      lir_main_760.literal_32_bits_value := v^.xl[14];
      lir_$simple_instruction(inh, ord(opc$add), 0, addr(lir_main_760),
                              isc_user_routines_338, isc_user_routines_328, nil);
    end
    else
      bug_check('LIR_MAIN_\BY_BRANCH_PROLOGS_FOR_HANDLER -- exception has unexpected .vat%$');
    lir_$branch_instruction(inh, h^.xp[16], ord(opc$jump), 0);
    p := p^.next;
  end;
  lir_main_760.il := nil;
  clean_up_canned_inherited;
end;

{ build_fp_reg_pair_odd_operand - dst made src's odd half: src's first
  longword with num one more, rrp fp_reg_odd_only for even_only (in
  +1 and in the rrp word at +4), the live range src's mate (+8), which
  gets lir_4216's bits.

  0x24A6F8, 0x4E bytes, no A5: src (8) in A1, dst (12) in A0. }

procedure build_fp_reg_pair_odd_operand(
    src: lm_opw_ptr_t;
    dst: lm_opw_ptr_t); options(val_param, internal);
var
  m: lr_ptr_t;
  bits: integer;
begin
  dst^.h := src^.h;
  dst^.h.num := src^.h.num + 1;
  opnd_bytes_ptr_t(dst)^.rrp := (opnd_bytes_ptr_t(dst)^.rrp & 16#FE) ! 2;
  dst^.rrp := (src^.rrp & 16#FFFE) ! 2;
  m := src^.lr^.mate;
  dst^.lr := m;
  bits := integer(m^.rrp) ! lir_4216;
  m^.rrp := rrp$set_t(bits);
end;

{ lir_main_$build_initial_epilog - the routine's RETURN (rtn +96): its
  operands the symbol operand (lir_main_da0), the argument pointer
  (isc_user_routines_340), the formals moved back from their homes for
  each of lm_convs' conventions (formal_local_transfer_setup with
  lm_epilog_xfer, the loads and stores swapped: cases 4, 6 a load from
  the home, 7 a move; a quad's second pair 2 registers on), the
  argument pointer's home when it is read, the preserved integer
  registers 0..29 (lm_ip_ops) and floating registers 0..63
  (lm_fp_ops), each read without 16#C0 when serialized; the operands
  written of a register kind dropped; the return block (lir_41fc) of
  kind and path return; the handlers' prologs; the exit block
  (lir_41f8) numbered after the others and made the return block's
  next and only (hidden) successor; two heaps released; the silly
  register candidates.  First the DB register restored when the
  routine has its own (internal_db) and the register is not
  no_modify.

  0x24A746, 0x74C bytes: rtn (8); the conventions A2 then (-48), the
  RETURN (-8), the operand number D4 (D3 its offset), the operands
  counted in D2. }

procedure lir_main_$build_initial_epilog(
    rtn: rtn_ptr_t);
var
  conv: call_conv_$ptr_t;
  n: integer32;
  e: integer32;
  j: integer32;
  arg: call_conv_$arg_ptr_t;
  sym: il_$node_ptr_t;
  ret: instr_ptr_t;
  num: integer32;
  f: instr_attr_opnd_t;
  op: opnd_ptr_t;
  k: integer32;
  b: bb_ptr_t;
  b2: bb_ptr_t;
  h: il_$node_ptr_t;
  takes: boolean;
begin
  zero(addr(lm_fp_ops), 256);
  zero(addr(lm_ip_ops), 256);
  if lm_mem_formals then
    rtn^.f226.needs_frame := true;
  conv := rtn^.conv;
  clean_up_canned_inherited;
  n := lir_41f4;
  n := n + count_registers(conv^.fp_preserved[0]);
  n := n + count_registers(conv^.fp_preserved[1]);
  n := n + count_registers(conv^.ip_preserved);
  if rtn^.f226.internal_db then
    if not lir_4090[conv^.w16]^.f2.physical_register_is_no_modify then begin
      lir_$simple_instruction(addr(lir_3b80), ord(opc$move), 0,
                              isc_user_routines_338, lir_3e60[conv^.w16], nil, nil);
      n := n + 1;
    end;
  n := n + 4;
  for e := 1 to lm_nconvs do
    for j := 1 to lm_convs[e]^.nargs do begin
      arg := addr(lm_convs[e]^.args[j]);
      if (arg^.num = 0) and arg^.by_value then
        if arg^.f18.loc <> ord(arg_loc$memory) then begin
          sym := arg^.sym;
          if (sym^.kind = fortran_symbol)
             or ((sym^.kind = var_name)
                 and ((sym^.xl[8] & 16#12400041) <> 0)) then
            if arg^.f18.loc = ord(arg_loc$fp_reg_quad) then
              n := n + 4
            else if arg^.f18.loc = ord(arg_loc$fp_reg_pair) then
              n := n + 2
            else
              n := n + 1;
        end;
    end;
  ret := lir_$get_new_instruction_no_exceptions(nil, ord(opc$return), 0, nil, n);
  rtn^.return_instr := ret;
  lir_$build_operand(addr(ret^.opnds[1]), lir_main_da0,
      instr_attr_view_ptr_t(addr(instruction_attributes[ord(opc$return)]))^.opnds[1]);
  lm_forms[3].num := 2;
  lir_$build_operand(addr(ret^.opnds[2]), isc_user_routines_340, lm_forms[3]);
  num := 3;
  for e := 1 to lm_nconvs do begin
    conv := lm_convs[e];
    for j := 1 to conv^.nargs do begin
      arg := addr(conv^.args[j]);
      takes := false;
      if (arg^.num = 0) and arg^.by_value then
        if arg^.f18.loc <> ord(arg_loc$memory) then begin
          sym := arg^.sym;
          takes := (sym^.kind = fortran_symbol)
                   or ((sym^.kind = var_name)
                       and ((sym^.xl[8] & 16#12400041) <> 0));
        end;
      if takes then begin
        case formal_local_transfer_setup(addr(lm_epilog_xfer), arg,
                                         addr(lm_stores), addr(lm_loads)) of
          4:
            lir_$load_instruction(addr(lir_3b80), lm_epilog_xfer.ldst, 0,
                                  addr(lir_main_250), isc_user_routines_33c,
                                  addr(lir_main_5b0),
                                  arg^.sym,
                                  arg^.w6, arg^.w6, 7);
          6: begin
            lir_$load_instruction(addr(lir_3b80), lm_epilog_xfer.ldst, 0,
                                  addr(lir_main_250), isc_user_routines_340,
                                  addr(lir_main_5b0),
                                  arg^.sym,
                                  arg^.w6, arg^.w6, 7);
            if lm_epilog_xfer.quad then begin
              lir_main_5b0.f78.physical_register_number := lir_main_5b0.f78.physical_register_number + 2;
              lir_main_5b0.live_range := nil;
              lir_main_250.literal_32_bits_value := 8;
              lir_$load_instruction(addr(lir_3b80), lm_epilog_xfer.ldst, 0,
                                    addr(lir_main_250), isc_user_routines_340,
                                    addr(lir_main_5b0),
                                    arg^.sym,
                                    arg^.w6, arg^.w6, 7);
              lir_main_250.literal_32_bits_value := 0;
            end;
          end;
          7: begin
            lir_$simple_instruction(addr(lir_3b80), lm_epilog_xfer.opc, 0,
                                    lm_epilog_xfer.sol, addr(lir_main_5b0), nil, nil);
            if lm_epilog_xfer.quad then begin
              lir_main_5b0.f78.physical_register_number := lir_main_5b0.f78.physical_register_number + 2;
              lir_main_5b0.live_range := nil;
              lir_main_400.live_range := lir_main_400.live_range_of_imaginary_part;
              lir_$simple_instruction(addr(lir_3b80), lm_epilog_xfer.opc, 0,
                                      addr(lir_main_400), addr(lir_main_5b0), nil, nil);
            end;
          end;
          otherwise
            bug_check('LIR_MAIN_$BUILD_INITIAL_EPILOG -- unexpected result from formal_local_transfer_setup%$');
        end;
        if lm_epilog_xfer.quad then begin
          lir_main_5b0.f78.physical_register_number := lir_main_5b0.f78.physical_register_number - 2;
          lir_main_5b0.live_range := lir_3f90[lir_main_5b0.f78.physical_register_number];
          num := num + 1;
          lm_forms[6].num := num;
          lm_forms[6].form := lm_form_by_loc[arg^.f18.loc];
          lir_$build_operand(addr(ret^.opnds[num]), addr(lir_main_5b0), lm_forms[6]);
          build_fp_reg_pair_odd_operand(univ_ptr(addr(ret^.opnds[num])),
                                        univ_ptr(addr(ret^.opnds[num + 1])));
          num := num + 1;
          lir_main_5b0.f78.physical_register_number := lir_main_5b0.f78.physical_register_number + 2;
          lir_main_5b0.live_range := lir_3f90[lir_main_5b0.f78.physical_register_number];
        end;
        num := num + 1;
        lm_forms[6].num := num;
        lm_forms[6].form := lm_form_by_loc[arg^.f18.loc];
        lir_$build_operand(addr(ret^.opnds[num]), addr(lir_main_5b0), lm_forms[6]);
        if lir_main_5b0.kind = 9 then begin
          build_fp_reg_pair_odd_operand(univ_ptr(addr(ret^.opnds[num])),
                                        univ_ptr(addr(ret^.opnds[num + 1])));
          num := num + 1;
        end;
      end;
    end;
  end;
  conv := rtn^.conv;
  if rrp$read in rtn^.ap_lr^.rrp then begin
    lm_forms[3].num := 3;
    lir_$build_operand(addr(ret^.opnds[3]), isc_user_routines_33c, lm_forms[3]);
  end;
  lir_4216 := 0;
  for k := 0 to 29 do begin
    takes := true;
    if lir_4090[k]^.f2.physical_register_user_declared then
      f := lm_forms[3]
    else if (k & 31) in bv_word_t(conv^.ip_preserved) then begin
      if (conv^.w16 = k) and rtn^.f226.internal_db
         and not lir_4090[conv^.w16]^.f2.physical_register_is_no_modify then
        f := lm_forms[3]
      else
        f := lm_forms[0];
    end
    else
      takes := false;
    if takes then begin
      num := num + 1;
      f.num := num;
      op := addr(ret^.opnds[num]);
      lm_ip_ops[k] := op;
      lir_$build_operand(op, lir_3e60[k], f);
    end;
  end;
  for k := 0 to 63 do begin
    takes := true;
    if lir_3f90[k]^.f2.physical_register_user_declared then
      f := lm_forms[5]
    else if k <= 31 then begin
      if (k & 31) in bv_word_t(conv^.fp_preserved[1]) then
        f := lm_forms[2]
      else
        takes := false;
    end
    else if (k & 31) in bv_word_t(conv^.fp_preserved[0]) then
      f := lm_forms[2]
    else
      takes := false;
    if takes then begin
      num := num + 1;
      f.num := num;
      op := addr(ret^.opnds[num]);
      lm_fp_ops[k] := op;
      lir_$build_operand(op, lir_3d60[k], f);
    end;
  end;
  lir_$complete_instruction(ret);
  for k := 1 to ret^.h.nopnds do
    if ret^.opnds[k].h.write then
      if ret^.opnds[k].h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then
        ret^.opnds[k].h.kind := operand$none;
  b := lir_41fc;
  b^.f14.kind := ord(block$return);
  b^.f14.path_to := ord(block$return);
  if ord(target_properties.p_bf[2]) >= 128 then begin
    exs_$start_all_exception_handlers_of_routine_enquiry;
    h := exs_$routines_next_exception_handler;
    while h <> nil do begin
      by_branch_prologs_for_handler(h);
      h := exs_$routines_next_exception_handler;
    end;
  end;
  b2 := lir_41f8;
  rtn^.nbbs := rtn^.nbbs + 1;
  rtn^.l188 := rtn^.l188 + 1;
  b2^.num := rtn^.l188 & 16#FFFF;
  b^.l134 := b2;
  b^.next := b2;
  b^.f.hidden_successor_edges := true;
  discard(lir_$add_flow_graph_edge(b, b2));
  mrh_$release_all(lir_3c48);
  mrh_$release_all(lir_3c30);
  fix_silly_register_candidates(rtn);
end;

{ pick_register - the first preserved integer register the routine
  saves (rtn +160) from rtn +222 (or +224 when that is negative) up to
  31 that is not avoid, taken out of the set; -1 for none.

  0x24AEE8, 0x7A bytes, no A5: rtn (8) in A0, avoid (12) in D1; the
  register in D0. }

function pick_register(
    rtn: rtn_ptr_t;
    avoid: integer32): integer32; options(val_param, internal);
var
  r: integer32;
begin
  pick_register := -1;
  r := rtn^.w222;
  if r < 0 then
    r := rtn^.w224;
  if r <= 31 then
    repeat
      if ((r & 31) in bv_word_t(rtn^.saved_ip)) and (avoid <> r) then begin
        rtn^.saved_ip := integer32(bv_word_t(rtn^.saved_ip) - [r & 31]);
        pick_register := r;
        return;
      end;
      r := r + 1;
    until r = 32;
end;

{ complete_prolog_store - the prologue store instr finished in the
  ENTRY block bb: its last two operands the memory read (the block's
  current memory segment, chained after its last reference) and
  written (a new segment of the memory live range lir_3ba8, numbered
  by its count, from lir_3c18), and instr put after the block's
  insertion point (lm_bbv_t).

  0x24AF62, 0xD8 bytes, no A5: bb (8) in D3, instr (12) in D2. }

procedure complete_prolog_store(
    bb: lm_bbv_ptr_t;
    instr: instr_ptr_t); options(val_param, internal);
var
  n: integer;
  lts: lts_ptr_t;
begin
  n := instr^.h.nopnds - 2;
  instr^.opnds[n].h.kind := operand$inscrutable_memory;
  opnd_bytes_ptr_t(addr(instr^.opnds[n]))^.rrp := 16;
  instr^.opnds[n].h.num := n;
  instr^.opnds[n].lts := bb^.mem;
  bb^.last^.link := addr(instr^.opnds[n]);
  bb^.last := addr(instr^.opnds[n]);
  instr^.opnds[n + 1].h.kind := operand$inscrutable_memory;
  opnd_bytes_ptr_t(addr(instr^.opnds[n + 1]))^.rrp := 8;
  instr^.opnds[n + 1].h.num := n + 1;
  lts := mrh_$alloc_fixed(lir_3c18);
  lir_3ba8.w56 := lir_3ba8.w56 + 1;
  lts^.f2.num := lir_3ba8.w56 & 255;
  lts^.lr := addr(lir_3ba8);
  lts^.bb := bb_ptr_t(bb);
  lts^.rrp := lts^.rrp + [rrp$write, rrp$read];
  instr^.opnds[n + 1].lts := lts;
  lts^.refs := addr(instr^.opnds[n + 1]);
  bb^.mem := lts;
  bb^.last := addr(instr^.opnds[n + 1]);
  instr^.bb := bb_ptr_t(bb);
  bb^.ins^.next := instr;
  bb^.ins := instr;
end;

{ add_prolog_register_read - the ENTRY's register operand def made an
  ip_reg or fp_reg one (by its segment's rrp), the store's operand op
  and the LIMIT's operand lim readers of its segment chained after it
  (read, not write), the segment and its live range read.

  0x24B03A, 0x7A bytes, no A5: def (8), op (12), lim (16). }

procedure add_prolog_register_read(
    def: opnd_ptr_t;
    op: opnd_ptr_t;
    lim: opnd_ptr_t); options(val_param, internal);
var
  lts: lts_ptr_t;
  lr: lr_ptr_t;
begin
  lts := def^.lts;
  lr := lts^.lr;
  if rrp$ip_reg in lts^.rrp then
    def^.h.kind := operand$ip_reg
  else
    def^.h.kind := operand$fp_reg;
  op^.h := def^.h;
  opnd_bytes_ptr_t(op)^.rrp := (opnd_bytes_ptr_t(def)^.rrp & 16#F7) ! 16;
  op^.lts := lts;
  def^.link := op;
  lim^.h := op^.h;
  lim^.lts := lts;
  op^.link := lim;
  lts^.rrp := lts^.rrp + [rrp$read];
  lr^.rrp := lr^.rrp + [rrp$read];
end;

{ prolog_store_instruction - in each ENTRY block (the entry block's
  edges' targets), a store of opcode opc (bug_check unless a store) of
  the ENTRY's operand k (and k2, the odd half, for STORED) at disp in
  the frame, its register operands readers of the ENTRY's (and of the
  LIMIT's next operands, lm_opnd_num); the store marked (+2 bits 6, 1,
  0, its +3 bits 3..1 disp's low three bits).

  0x24B0B4, 0x1A6 bytes, no A5: opc (8) a word in D3, disp (10) in D4,
  k (14), k2 (18) in D6; lir_$get_new_instruction_no_exceptions given
  three of its arguments (pattern 132); the constant 12 at 0x24B294
  (pattern 116). }

procedure prolog_store_instruction(
    opc: integer;
    disp: integer32;
    k: integer32;
    k2: integer32); options(val_param, internal);
var
  attr: instr_attr_view_ptr_t;
  num: integer32;
  e: fg_edge_ptr_t;
  b: bb_ptr_t;
  ins: instr_ptr_t;
  entry: instr_ptr_t;
  lim: instr_ptr_t;
begin
  attr := addr(instruction_attributes[opc]);
  if instruction_attributes[opc].class <> class$store then
    bug_check('LIR_MAIN: PROLOG_STORE_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  num := lm_opnd_num + 1;
  e := lm_edges;
  while e <> nil do begin
    b := e^.target;
    if b^.f.entry then begin
      ins := lir_$get_new_instruction_no_exceptions(nil, opc, 0, nil, 0);
      ins^.h.b2_6 := true;
      ins^.h.width := (ins^.h.width & 16#F1) ! ((disp * 2) & 14);
      ins^.h.b2_1 := true;
      ins^.h.b2_0 := true;
      entry := b^.first;
      lim := instr_ptr_t(entry^.opnds[1].ptr);
      add_prolog_register_read(addr(entry^.opnds[k]), addr(ins^.opnds[1]),
                               addr(lim^.opnds[num]));
      ins^.opnds[1].h.num := 1;
      lir_main_760.literal_32_bits_value := disp;
      lir_$build_operand(addr(ins^.opnds[2]), addr(lir_main_760), attr^.opnds[2]);
      lir_$build_operand(addr(ins^.opnds[3]), isc_user_routines_340, attr^.opnds[3]);
      if opc = ord(opc$stored) then begin
        ins^.opnds[1].h.kind := operand$fp_reg_pair;
        add_prolog_register_read(addr(entry^.opnds[k2]), addr(ins^.opnds[4]),
                                 addr(lim^.opnds[num + 1]));
        ins^.opnds[4].h.kind := operand$fp_reg_pair;
        ins^.opnds[4].h.num := 4;
      end;
      complete_prolog_store(univ_ptr(b), ins);
    end;
    e := e^.next_succ;
  end;
  if opc = ord(opc$stored) then
    num := num + 1;
  lm_opnd_num := num;
end;

{ complete_epilog_load - the epilogue load instr finished: its last
  operand (but one when the opcode's b14_0 is set) a reader of the
  RETURN block's memory segment (lm_mem_lts, chained after
  lm_last_ref), and instr appended to the RETURN block (lm_ret_bb).

  0x24B298, 0xAE bytes, no A5: instr (8) in A0. }

procedure complete_epilog_load(
    instr: instr_ptr_t); options(val_param, internal);
var
  n: integer;
  op: opnd_ptr_t;
  b: bb_ptr_t;
begin
  n := instr^.h.nopnds;
  if instruction_attributes[instr^.opc].b14_0 then
    n := n - 1;
  instr^.opnds[n].h.kind := operand$inscrutable_memory;
  opnd_bytes_ptr_t(addr(instr^.opnds[n]))^.rrp := 16;
  instr^.opnds[n].h.num := n;
  instr^.opnds[n].lts := lm_mem_lts;
  instr^.opnds[n].link := nil;
  op := addr(instr^.opnds[n]);
  if lm_last_ref <> nil then
    lm_last_ref^.link := op
  else
    lm_mem_lts^.refs := op;
  lm_last_ref := op;
  b := lm_ret_bb;
  instr^.bb := b;
  if b^.last = nil then
    b^.first := instr
  else
    b^.last^.next := instr;
  b^.last := instr;
end;

{ add_epilog_register_write - the RETURN's register operand use made
  the load's operand op its definition (write, chained before it; the
  segment and live range written), use made an ip_reg or fp_reg read;
  a no_modify register's two operands built instead from its physical
  solution (lm_forms 3 and 0).

  0x24B346, 0xE8 bytes, no A5: use (8) in A2, op (12); the segment A0,
  its live range D2. }

procedure add_epilog_register_write(
    use: opnd_ptr_t;
    op: opnd_ptr_t); options(val_param, internal);
var
  lts: lts_ptr_t;
  lr: lr_ptr_t;
begin
  lts := use^.lts;
  lr := lts^.lr;
  if rrp$ip_reg in lts^.rrp then begin
    if lr^.f2.physical_register_is_no_modify then begin
      opnd_bytes_ptr_t(use)^.num := 0;
      opnd_bytes_ptr_t(use)^.rrp := 0;
      opnd_bytes_ptr_t(use)^.b2 := 0;
      opnd_bytes_ptr_t(use)^.b3 := 0;
      lir_$build_operand(use, lir_3e60[lr^.f2.physical_register_number], lm_forms[3]);
      lir_$build_operand(op, lir_3e60[lr^.f2.physical_register_number], lm_forms[0]);
      return;
    end;
    use^.h.kind := operand$ip_reg;
  end
  else begin
    if lr^.f2.physical_register_is_no_modify then begin
      opnd_bytes_ptr_t(use)^.num := 0;
      opnd_bytes_ptr_t(use)^.rrp := 0;
      opnd_bytes_ptr_t(use)^.b2 := 0;
      opnd_bytes_ptr_t(use)^.b3 := 0;
      lir_$build_operand(use, lir_3d60[lr^.f2.physical_register_number], lm_forms[3]);
      lir_$build_operand(op, lir_3d60[lr^.f2.physical_register_number], lm_forms[0]);
      return;
    end;
    use^.h.kind := operand$fp_reg;
  end;
  op^.h := use^.h;
  opnd_bytes_ptr_t(op)^.rrp := (opnd_bytes_ptr_t(use)^.rrp & 16#EF) ! 8;
  op^.lts := lts;
  op^.link := use;
  opnd_bytes_ptr_t(use)^.rrp := (opnd_bytes_ptr_t(use)^.rrp & 16#F7) ! 16;
  lts^.rrp := lts^.rrp + [rrp$write];
  lr^.rrp := lr^.rrp + [rrp$write];
  lts^.refs := op;
end;

{ epilog_load_pair_instruction - unless the routine has no RETURN, a
  LOAD_PAIR at disp (its +3) through the argument pointer
  (isc_user_routines_340) into the registers the RETURN's operands use
  and use2 read.

  0x24B42E, 0x90 bytes, no A5: disp (8) in D2. }

procedure epilog_load_pair_instruction(
    disp: integer32;
    use: opnd_ptr_t;
    use2: opnd_ptr_t); options(val_param, internal);
var
  ins: instr_ptr_t;
begin
  if not lm_no_return then begin
    ins := lir_$get_new_instruction_no_exceptions(nil, ord(opc$load_pair), 0, nil, 0);
    ins^.h.b2_6 := true;
    ins^.h.width := disp & 255;
    lir_$build_operand(addr(ins^.opnds[1]), isc_user_routines_340,
        instr_attr_view_ptr_t(addr(instruction_attributes[ord(opc$load_pair)]))^.opnds[1]);
    add_epilog_register_write(use, addr(ins^.opnds[2]));
    ins^.opnds[2].h.num := 2;
    add_epilog_register_write(use2, addr(ins^.opnds[3]));
    ins^.opnds[3].h.num := 3;
    complete_epilog_load(ins);
  end;
end;

{ epilog_load_instruction - unless the routine has no RETURN, a load
  of opcode opc (bug_check unless a load) at disp in the frame into the
  register the RETURN's operand use reads (and use2's, the odd half,
  for LOADD); marked as prolog_store_instruction's stores.

  0x24B4BE, 0x120 bytes, no A5: opc (8) a word in D3, disp (10) in D2,
  use (14), use2 (18). }

procedure epilog_load_instruction(
    opc: integer;
    disp: integer32;
    use: opnd_ptr_t;
    use2: opnd_ptr_t); options(val_param, internal);
var
  attr: instr_attr_view_ptr_t;
  ins: instr_ptr_t;
begin
  if not lm_no_return then begin
    attr := addr(instruction_attributes[opc]);
    if instruction_attributes[opc].class <> class$load then
      bug_check('LIR_MAIN: EPILOG_LOAD_INSTRUCTION -- illegal opcode: %a%$',
                instruction_mnemonic[opc], 12);
    ins := lir_$get_new_instruction_no_exceptions(nil, opc, 0, nil, 0);
    ins^.h.b2_6 := true;
    ins^.h.width := (ins^.h.width & 16#F1) ! ((disp * 2) & 14);
    ins^.h.b2_1 := true;
    ins^.h.b2_0 := true;
    lir_main_760.literal_32_bits_value := disp;
    lir_$build_operand(addr(ins^.opnds[1]), addr(lir_main_760), attr^.opnds[1]);
    lir_$build_operand(addr(ins^.opnds[2]), isc_user_routines_340, attr^.opnds[2]);
    add_epilog_register_write(use, addr(ins^.opnds[3]));
    ins^.opnds[3].h.num := 3;
    if opc = ord(opc$loadd) then begin
      ins^.opnds[3].h.kind := operand$fp_reg_pair;
      add_epilog_register_write(use2, addr(ins^.opnds[4]));
      ins^.opnds[4].h.num := 4;
      ins^.opnds[4].h.kind := operand$fp_reg_pair;
    end;
    complete_epilog_load(ins);
  end;
end;

{ lir_main_$save_and_restore_code - after register allocation: the
  preserved registers the routine writes (rtn +148..+159 less the
  conventions' preserved sets) moved to rtn +160..+171; the save area
  counted (floating pairs quadword aligned, singles, integer registers,
  the static link and return address slots), the frame laid out (the
  block's +176 dynamic area, the save area from rtn +218, needs_frame
  for a routine that calls or whose frame is over 24 bytes, the frame
  pointer and return address kept in registers when pick_register
  finds free ones), its size in rtn +48 (lir_main_c40 less the dynamic
  area, the block's +112 its negation), and, unless the routine has no
  RETURN, the stores after each ENTRY (the old frame pointer, the
  return address, the integer registers by pairs, the floating pairs,
  the singles) and the loads before the RETURN, the RETURN's modify
  bits and the frame pointer reloaded; the ENTRY blocks' memory chains
  closed; lir_3f60 released.

  0x24B618, 0xA20 bytes: rtn (8); the conventions (-116), the pairs
  (-52), singles (-16) and integer registers D3 counted, the frame
  size D2, the save area's start D4, the RETURN block (-120), the save
  area's end (-36).  The singles' test `cmpi.l #-1' of the register is
  never true (kept); a pair of a RETURN with no RETURN block reads the
  block slot unset (as the image). }

procedure lir_main_$save_and_restore_code(
    rtn: rtn_ptr_t);
var
  conv: call_conv_$ptr_t;
  blk: il_$node_ptr_t;
  npairs: integer32;
  nsingles: integer32;
  nregs: integer32;
  r: integer32;
  r2: integer32;
  ev: boolean;
  od: boolean;
  sl: boolean;
  size: integer32;
  dyn: integer32;
  base: integer32;
  save_rpc: boolean;
  save_end: integer32;
  fsize: integer32;
  e: fg_edge_ptr_t;
  bv: lm_bbv_ptr_t;
  b: bb_ptr_t;
  ins: instr_ptr_t;
  ret: instr_ptr_t;
  k: integer32;
  j: integer32;
  found: boolean;
  s: integer32;
begin
  lm_opnd_num := 0;
  lm_no_return := rtn^.f226.no_return_block;
  conv := rtn^.conv;
  rtn^.saved_fp[0] := rtn^.written_fp[0] & conv^.fp_preserved[0];
  rtn^.written_fp[0] := rtn^.written_fp[0] & ~conv^.fp_preserved[0];
  rtn^.saved_fp[1] := rtn^.written_fp[1] & conv^.fp_preserved[1];
  rtn^.written_fp[1] := rtn^.written_fp[1] & ~conv^.fp_preserved[1];
  rtn^.saved_ip := rtn^.written_ip & conv^.ip_preserved;
  rtn^.written_ip := rtn^.written_ip & ~conv^.ip_preserved;
  npairs := 0;
  nsingles := 0;
  nregs := 0;
  r := 30;
  r2 := 31;
  repeat
    ev := (r & 31) in bv_word_t(rtn^.saved_fp[0]);
    od := (r2 & 31) in bv_word_t(rtn^.saved_fp[0]);
    npairs := npairs + ord(ev and od);
    if not (ev and od) then
      nsingles := nsingles + ord(ev or od);
    ev := (r & 31) in bv_word_t(rtn^.saved_fp[1]);
    od := (r2 & 31) in bv_word_t(rtn^.saved_fp[1]);
    npairs := npairs + ord(ev and od);
    if not (ev and od) then
      nsingles := nsingles + ord(ev or od);
    nregs := nregs + ord((r & 31) in bv_word_t(rtn^.saved_ip))
                   + ord((r2 & 31) in bv_word_t(rtn^.saved_ip));
    r := r - 2;
    r2 := r2 - 2;
  until r < 0;
  blk := rtn^.node;
  sl := ((ord(blk^.xc[378]) & 16#20) <> 0) and not conv^.b30;
  nregs := nregs + ord(sl);
  nregs := nregs + ord((ord(blk^.xc[378]) & 8) <> 0);
  if npairs <> 0 then begin
    if nsingles = 0 then
      nregs := nregs + (nregs & 1)
    else if nregs < 2 then
      nregs := 2
    else if odd(nregs) then
      nregs := nregs + (nregs & 1);
    nregs := nregs + npairs * 2;
  end;
  nregs := nregs + nsingles;
  nregs := nregs + (ord(rtn^.f226.quad_aligned) & nregs);
  size := nregs * 4 + rtn^.frame_size;
  dyn := blk^.xl[44];
  if dyn <> 0 then begin
    size := (size + 7) & ~7;
    dyn := (dyn + 7) & ~7;
    blk^.xl[44] := dyn;
    size := size + dyn;
  end;
  if not rtn^.f226.needs_frame then
    base := 16
  else
    base := ((blk^.xw[134] + 7) & ~7) + 16;
  rtn^.f226.save_rpc := rtn^.f226.save_rpc or rtn^.f226.contains_call;
  save_rpc := rtn^.f226.save_rpc;
  if not rtn^.f226.contains_call then
    if (size <= 24) and not rtn^.f226.needs_frame then
      save_rpc := false
    else
      rtn^.f226.needs_frame := true;
  rtn^.w218 := base;
  rtn^.w222 := -1;
  rtn^.w224 := -1;
  if rtn^.f226.needs_frame then begin
    if not sl then
      rtn^.w222 := pick_register(rtn, conv^.w14);
    if (ord(blk^.xc[378]) & 8) = 0 then
      rtn^.w224 := pick_register(rtn, conv^.w14);
    if rtn^.f226.quad_aligned or (npairs <> 0) then begin
      if rtn^.w222 >= 0 then
        if rtn^.w224 >= 0 then
          size := size - 8;
    end
    else begin
      if rtn^.w222 >= 0 then
        size := size - 4;
      if rtn^.w224 >= 0 then
        size := size - 4;
    end;
  end;
  nregs := nregs - ord(rtn^.w222 >= 0) - ord(rtn^.w224 >= 0);
  save_end := nregs * 4 + base;
  fsize := 0;
  if size < 0 then
    bug_check('LIR_MAIN_$SAVE_AND_RESTORE_CODE -- negative stack space requirement%$')
  else if (size = 0) and not rtn^.f226.needs_frame then
    fsize := 0
  else
    fsize := (base + size + 7) & ~7;
  rtn^.frame_size := fsize;
  lir_main_c40 := fsize - dyn;
  blk^.xl[28] := -(fsize - dyn);
  rtn^.f226.shares_frame := not rtn^.f226.needs_frame and conv^.b30;
  if rtn^.f226.needs_frame then
    rtn^.l172 := fsize
  else if fsize > rtn^.l176 then
    rtn^.l176 := fsize;
  e := rtn^.bbs^.succs;
  lm_edges := e;
  while e <> nil do begin
    b := e^.target;
    if b^.f.entry then begin
      ins := b^.first;
      if ins^.opc <> ord(opc$entry) then
        bug_check('LIR_MAIN_$SAVE_AND_RESTORE_CODE -- missing ENTRY instruction%$');
      bv := univ_ptr(b);
      bv^.ins := ins;
      bv^.next_ins := ins^.next;
      bv^.last := nil;
      for k := ins^.h.nopnds downto 1 do
        if ins^.opnds[k].h.kind = operand$inscrutable_memory then
          if (opnd_bytes_ptr_t(addr(ins^.opnds[k]))^.rrp & 12) <> 0 then begin
            bv^.last := addr(ins^.opnds[k]);
            bv^.mem := ins^.opnds[k].lts;
            bv^.rd := ins^.opnds[k].link;
          end;
    end;
    e := e^.next_succ;
  end;
  if rtn^.f226.no_return_block then
    ret := nil
  else begin
    ret := rtn^.return_instr;
    for k := ret^.h.nopnds downto 1 do
      if ret^.opnds[k].h.kind = operand$inscrutable_memory then
        if ret^.opnds[k].h.read then begin
          lm_last_ref := addr(ret^.opnds[k]);
          lm_mem_lts := ret^.opnds[k].lts;
          b := ret^.opnds[k].lts^.bb;
        end;
    if b^.first = ret then
      b^.last := nil
    else begin
      ins := b^.first;
      while ins^.next <> ret do
        ins := ins^.next;
      b^.last := ins;
    end;
    lm_ret_bb := b;
  end;
  r := rtn^.w222;
  if r > 0 then
    if r < 32 then
      prolog_store_instruction(ord(opc$storel), 4, r + 3, 0)
    else
      prolog_store_instruction(ord(opc$stores), 4, r + 1, 0);
  if save_rpc then begin
    prolog_store_instruction(ord(opc$storel), 8, 2, 0);
    rtn^.saved_ip := integer32(bv_word_t(rtn^.saved_ip) - [conv^.w14 & 31]);
  end;
  r := rtn^.w224;
  if r < 0 then begin
    if save_rpc then
      epilog_load_instruction(ord(opc$loadl), 8, addr(ret^.opnds[1]), nil);
  end
  else if r >= 32 then begin
    prolog_store_instruction(ord(opc$stores), 12, r + 1, 0);
    if save_rpc then
      epilog_load_instruction(ord(opc$loadl), 8, addr(ret^.opnds[1]), nil);
    epilog_load_instruction(ord(opc$loads), 12, lm_fp_ops[r - 32], nil);
  end
  else begin
    prolog_store_instruction(ord(opc$storel), 12, r + 3, 0);
    if save_rpc then
      epilog_load_pair_instruction(8, addr(ret^.opnds[1]), lm_ip_ops[r])
    else
      epilog_load_instruction(ord(opc$loadl), 12, lm_ip_ops[r], nil);
  end;
  k := 0;
  while k < 30 do begin
    if (k & 31) in bv_word_t(rtn^.saved_ip) then begin
      prolog_store_instruction(ord(opc$storel), base, k + 3, 0);
      j := k + 1;
      found := false;
      while (j < 30) and not found do
        if (j & 31) in bv_word_t(rtn^.saved_ip) then begin
          prolog_store_instruction(ord(opc$storel), base + 4, j + 3, 0);
          if base <= 127 then
            epilog_load_pair_instruction(base, lm_ip_ops[k], lm_ip_ops[j])
          else begin
            epilog_load_instruction(ord(opc$loadl), base, lm_ip_ops[k], nil);
            epilog_load_instruction(ord(opc$loadl), base + 4, lm_ip_ops[j], nil);
          end;
          j := j + 1;
          base := base + 8;
          k := j;
          found := true;
        end
        else
          j := j + 1;
      if not found then begin
        epilog_load_instruction(ord(opc$loadl), base, lm_ip_ops[k], nil);
        base := base + 4;
        k := k + 1;
      end;
    end
    else
      k := k + 1;
  end;
  if npairs <> 0 then begin
    base := (base + 7) & ~7;
    r := 0;
    r2 := 1;
    repeat
      if r < 32 then
        s := rtn^.saved_fp[1]
      else
        s := rtn^.saved_fp[0];
      if ((r & 31) in bv_word_t(s)) and ((r2 & 31) in bv_word_t(s)) then begin
        prolog_store_instruction(ord(opc$stored), base, r + 33, r2 + 33);
        epilog_load_instruction(ord(opc$loadd), base, lm_fp_ops[r], lm_fp_ops[r2]);
        base := base + 8;
      end;
      r := r + 2;
      r2 := r2 + 2;
    until r >= 64;
  end;
  r := 0;
  r2 := 1;
  repeat
    if r < 32 then
      s := rtn^.saved_fp[1]
    else
      s := rtn^.saved_fp[0];
    ev := (r & 31) in bv_word_t(s);
    od := (r2 & 31) in bv_word_t(s);
    if ev <> od then begin
      j := ord(od) + r;
      if j <> -1 then begin
        prolog_store_instruction(ord(opc$stores), base, j + 33, 0);
        epilog_load_instruction(ord(opc$loads), base, lm_fp_ops[j], nil);
        base := base + 4;
      end;
    end;
    r := r + 2;
    r2 := r2 + 2;
  until r >= 64;
  if base > save_end then
    bug_check('LIR_MAIN_$SAVE_AND_RESTORE_CODE -- register save area overflow%$');
  if rtn^.f226.quad_aligned then
    base := (base + 7) & ~7;
  rtn^.save_end := base;
  lir_main_c6c := base;
  if not rtn^.f226.no_return_block then begin
    if b^.last <> nil then
      b^.last^.next := ret;
    b^.last := ret;
    if not rtn^.f226.needs_frame then begin
      rtn^.frame_size := 0;
      blk^.xl[28] := 0;
    end
    else begin
      ret^.h.modify := 3;
      if rtn^.w222 < 0 then
        epilog_load_instruction(ord(opc$loadl), 0, addr(ret^.opnds[2]), nil)
      else
        epilog_load_pair_instruction(0, addr(ret^.opnds[2]), lm_ip_ops[rtn^.w222]);
    end;
  end;
  e := lm_edges;
  while e <> nil do begin
    b := e^.target;
    if b^.f.entry then begin
      bv := univ_ptr(b);
      if bv^.rd <> nil then
        bv^.rd^.lts := bv^.mem;
      bv^.last^.link := bv^.rd;
      bv^.ins^.next := bv^.next_ins;
    end;
    e := e^.next_succ;
  end;
  mrh_$release_all(lm_heap_ptr_t(addr(lir_3f60))^);
end;
