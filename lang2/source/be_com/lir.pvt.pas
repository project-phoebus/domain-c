{ lang2/source/be_com/lir.pvt.pas - the LIR builder's private insert (cc.a88k only): opened by lir,
  lir_main, lir_utils and ra_utils, after the ISC inserts and
  isc_var_externs.ins.pas.  It holds what those four share and the
  other units do not reach: lir.pas's cells at +0x3B80..+0x3C48,
  +0x41F0..+0x4216 (lir_main, lir_utils, ra_utils), lir_main.pas's
  +0x250..+0xAC0 and +0xDA0 (lir, lir_utils), ra_utils.pas's +0x10..
  +0x7C (lir, lir_utils), and the headings of the routines only they
  call (docs/backend-plan.md).

  No Apollo copy survives.  Created as a stub with the back end's core
  (translator MM); filled by batch A as lir_utils, lir_main and lir were
  translated (complete with lir: translator PA7).

  Not known from the original: everything about its contents. }

type
  { batch A (PA4): how a spill or store-through load or store is made
    (the section spill_instr_forms; lir_utils_$flesh_out_new_load_or_
    store, ra_utils_$add_spill_code): its register operand's form
    (form2 the odd half's, for a pair), the solution kind of the
    register (solution$...: 2, 3 a pair's halves, 8 fp_reg, 9
    fp_reg_pair, 11 ip_reg), the opcode, and the rrp the register's
    segment (and the odd half's) gets. }
  spill_desc_ptr_t = ^spill_desc_t;
  spill_desc_t = record
    form: instr_attr_opnd_t;            { +0 }
    form2: instr_attr_opnd_t;           { +4 }
    kind: integer;                      { +8 }
    opc: integer;                       { +10 }
    rrp: 0..65535;                      { +12 }
    rrp2: 0..65535;                     { +14 }
  end;

  { The section spill_instr_forms (cc.a88k 0x513E30, 264 bytes,
    initialized: lir_utils.pas's define): the forms of a load's or
    store's address operands (forms: the base register's at +4, the
    address's at +12; lir_utils and ra_utils set their operand numbers,
    +1, +5, +9, +13, before each use), the loads (single, a pair's
    halves, pair, then byte, half and word integer: loads, pointed to
    by load_ptrs in the order pair, even, odd, single, word, half, byte)
    and the stores (single, halves, pair, word: stores, pointed to by
    store_ptrs in the order pair, even, odd, single, word). }
  spill_instr_forms_t = record
    forms: array [0..3] of instr_attr_opnd_t;   { +0x00 }
    loads: array [0..6] of spill_desc_t;        { +0x10 }
    load_ptrs: array [0..6] of spill_desc_ptr_t;    { +0x80 }
    stores: array [0..4] of spill_desc_t;       { +0x9C }
    store_ptrs: array [0..4] of spill_desc_ptr_t;   { +0xEC }
    l100: integer32;                    { +0x100 }
    l104: integer32;                    { +0x104 }
  end;

  { batch A (PA5): the attributes a top-level node's instructions
    inherit (lir.pas +0x3B80, 40 bytes): lir_main's
    top_level_inherited_attributes sets node and clears l12, then
    lir_$complete_top_level_node_inherited_attrs fills it;
    clean_up_canned_inherited clears l4, l12 and w34.  The address is
    what lir_$get_new_instruction_no_exceptions and the
    lir_$..._instruction routines take as their first argument. }
  lir_inherited_ptr_t = ^lir_inherited_t;
  lir_inherited_t = record
    node: univ_ptr;                     { +0 }
    l4: integer32;                      { +4 }
    l8: integer32;                      { +8 }
    l12: integer32;                     { +12 }
    l16: integer32;                     { +16 }
    l20: integer32;                     { +20: what begin_instruction
                                          keeps in lir_41ec (batch A,
                                          PA7) }
    l24: integer32;                     { +24 }
    l28: integer32;                     { +28 }
    w32: integer;                       { +32: the node's +20 word
                                          (lir_$complete_top_level_node_
                                          inherited_attrs; batch A, PA6) }
    w34: integer;                       { +34: the node's +43..+44
                                          word (likewise) }
    l36: integer32;                     { +36 }
  end;

  { The physical registers' solutions (lir +0x3C60, +0x3D60: by
    floating register; lir_3e60 by integer register). }
  lir_sol_tab_t = array [0..63] of solution_ptr_t;

var (spill_instr_forms)
  spill_instr_forms: spill_instr_forms_t;

var
  { lir.pas's data (A5 0x487180). }
  lir_3c00: extern mrh_$heap_t;         { +0x3C00 (0x48AD80): the fixed
                                          heap of lifetime segments
                                          (lir_utils_$add_lts_to_lr,
                                          _add_lts_after_lts:
                                          mrh_$alloc_fixed) }
  lir_3b80: extern lir_inherited_t;     { +0x3B80 (0x48AD00): the
                                          inherited attributes lir_utils'
                                          new loads are made with
                                          (begin_instruction's first
                                          argument; batch A, PA4; PA5: a
                                          record) }
  lir_3c18: extern mrh_$heap_t;         { +0x3C18: a fixed heap of
                                          segments (the memory's, lir_main's
                                          prologue stores) }
  lir_3c30: extern mrh_$heap_t;         { +0x3C30, +0x3C48: heaps
                                          lir_main_$build_initial_epilog
                                          releases }
  lir_3c48: extern mrh_$heap_t;
  lir_3c60: extern lir_sol_tab_t;       { +0x3C60: by floating register,
                                          the solution of its pair }
  lir_3d60: extern lir_sol_tab_t;       { +0x3D60: by floating register,
                                          the solution of its physical
                                          live range }
  lir_41f0: extern bb_ptr_t;            { +0x41F0: the entry block (the
                                          ENTRY's block is its successor) }
  lir_41f4: extern integer32;           { +0x41F4: the RETURN's operands
                                          beyond the registers }
  lir_41f8: extern bb_ptr_t;            { +0x41F8: the exit block }
  lir_41fc: extern bb_ptr_t;            { +0x41FC: the current block (the
                                          last made: lir_main's return
                                          block; PA7) }
  lir_4216: extern integer;             { +0x4216: rrp bits new register
                                          operands' live ranges get }
  lir_3ba8: extern lr_t;                { +0x3BA8 (0x48AD28): the live
                                          range of the memory the
                                          store-through loads and stores
                                          read and write (their
                                          inscrutable_memory operands;
                                          batch A, PA4) }

  { lir_main.pas's data (A5 0x48B3AC). }
  lir_main_250: extern solution_t;      { +0x250: the address solution of
                                          a frame or memory home access
                                          (lir_utils: +0x280 its disp,
                                          +0x288 its w56) }
  lir_main_760: extern solution_t;      { +0x760: the address solution of
                                          a static home's access through
                                          the DB register (+0x790 disp);
                                          lir_main: of the frame (the
                                          formals' and saves' slots) }
  lir_main_400: extern solution_t;      { +0x400: a register's (lir_main:
                                          a formal's home) }
  lir_main_5b0: extern solution_t;      { +0x5B0: an argument register's }
  lir_main_910: extern solution_t;      { +0x910 (lir: kind 3) }
  lir_main_da0: extern solution_ptr_t;  { +0xDA0: the solution of the
                                          ENTRY's and RETURN's symbol
                                          operand (set by lir) }

{ LIR_UTILS_$FLESH_OUT_NEW_LOAD_OR_STORE - the operands of a new load or
  store instr made from desc (spill_desc_t): reg (and
  reg2, a pair's odd half) the register of segment lts (lts2), addr
  the address (home's, through the DB register for a static home,
  else through the frame), base the address's base register; its
  instruction's position copied from pos.  0x24D34C, 0x288 bytes;
  called from lir_utils ra_utils.  Frame 8..56 (13 longwords).  No
  result (batch A, PA4: was a function with p1..p13; ra_utils' read of
  D0 is the register's other use). }
procedure lir_utils_$flesh_out_new_load_or_store(
    reg: opnd_ptr_t;
    reg2: opnd_ptr_t;
    addr_op: opnd_ptr_t;
    base: opnd_ptr_t;
    home: univ_ptr;
    lts: lts_ptr_t;
    lts2: lts_ptr_t;
    desc: spill_desc_ptr_t;
    instr: instr_ptr_t;
    pos: instr_ptr_t;
    var db_lts: lts_ptr_t;
    var db_last: opnd_ptr_t;
    function new_db_lts: lts_ptr_t); options(val_param); extern;

