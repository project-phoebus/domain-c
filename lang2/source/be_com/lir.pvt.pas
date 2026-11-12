{ lang2/source/be_com/lir.pvt.pas - the LIR builder's private insert (cc.a88k only): opened by lir,
  lir_main, lir_utils and ra_utils, after the ISC inserts and
  isc_var_externs.ins.pas.  It holds what those four share and the
  other units do not reach: lir.pas's cells at +0x3B80..+0x3C48,
  +0x41F0..+0x4216 (lir_main, lir_utils, ra_utils), lir_main.pas's
  +0x250..+0xAC0 and +0xDA0 (lir, lir_utils), ra_utils.pas's +0x10..
  +0x7C (lir, lir_utils), and the headings of the routines only they
  call (docs/backend-plan.md).

  No Apollo copy survives.  Created as a stub with the back end's core
  (translator MM); batch A fills it as its units are translated.

  Not known from the original: everything about its contents. }

{ TODO(pascal) lir.pvt.pas: the cells and headings listed above (lir,
  lir_main and ra_utils not translated yet) }

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

var (spill_instr_forms)
  spill_instr_forms: spill_instr_forms_t;

var
  { lir.pas's data (A5 0x487180). }
  lir_3c00: extern mrh_$heap_t;         { +0x3C00 (0x48AD80): the fixed
                                          heap of lifetime segments
                                          (lir_utils_$add_lts_to_lr,
                                          _add_lts_after_lts:
                                          mrh_$alloc_fixed) }
  lir_3b80: extern array [0..9] of integer32;  { +0x3B80 (0x48AD00): an
                                          IL node lir_utils' new loads
                                          are made for (begin_instruction's
                                          node; batch A, PA4) }
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
                                          the DB register (+0x790 disp) }

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

