{ lang2/source/be_com/ra.pvt.pas - the register allocator's private insert (cc.a88k only): opened by
  ra and ra_utils (after call_conv.ins.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  The headings of ra's and ra_utils' global routines that the
  other calls, and the cells they share.  batch B (PB5): ra_utils'
  headings narrowed from its bodies, ra's from ra_utils' calls.

  Not known from the original: every parameter and cell name. }

type
  { batch B (PB6): the register classes a pass treats, as a set (1 the
    integer registers, 2 the floating singles, 3 the floating pairs:
    ra.pas's ra_class), passed as a longword. }
  ra_classes_t = set of 0..31;

var
  { ra.pas's data (A5 0x48F488). }
  ra_650: extern integer32;             { +0x650 (0x48FAD8): the debug
                                          level, at_backend_switches'
                                          (ra_utils_$spill_pass_through_lrs
                                          sets it) }

{ ra.pas (cc.a88k). }

{ RA_$CLEAN_BB_AND_INIT_BIT_VECTORS - bb's instructions renumbered, its
  register operands of the classes asked for linked into their segments
  and live ranges (with first, the live ranges chained and numbered),
  the block's lifetime vectors set.  0x267048, 0x25A bytes; called from
  ra_utils (bb, [1..3], false).  Frame 8:al; 12:al; 16:bw (batch B,
  PB6: narrowed from ra.pas). }
procedure ra_$clean_bb_and_init_bit_vectors(
    bb: bb_ptr_t;
    classes: ra_classes_t;
    first: boolean); options(val_param); extern;

{ RA_$BUILD_CONFLICT_GRAPH - the conflict graph of the classes asked
  for, block by block, with the register pressure (each instruction's
  +28..+31, each block's counts, lir_main_c88/c89); with count_only the
  pressure alone (no matrices, no conflicts, aversions or preferences).
  0x2696C2, 0x1000 bytes; called from ra_utils (rtn, [1..3], true: 12
  bytes of arguments).  Frame 8:al; 12:al; 16:b (batch B, PB6:
  narrowed from ra.pas). }
procedure ra_$build_conflict_graph(
    rtn: rtn_ptr_t;
    classes: ra_classes_t;
    count_only: boolean); options(val_param); extern;

{ ra_utils.pas (cc.a88k). }

{ RA_UTILS_$COMPUTE_COMPLEX_LIFETIMES - each block's live_in and live_out
  narrowed to what is also available there.  0x26DFC0, 0x82 bytes;
  called from ra. }
procedure ra_utils_$compute_complex_lifetimes(
    rtn: rtn_ptr_t); options(val_param); extern;

{ RA_UTILS_$REMATERIALIZE - the instruction that recomputes lr's value
  (its one definition, or that of the live range it was split from),
  nil when it must be reloaded from memory.  0x26F6EE, 0x2E8 bytes;
  called from ra (twice, with false).  Frame 8:l; 12:al; 16:bw. }
function ra_utils_$rematerialize(
    rtn: rtn_ptr_t;
    lr: lr_ptr_t;
    any_load: boolean): instr_ptr_t; options(val_param); extern;

{ RA_UTILS_$ADD_SPILL_CODE - the reloads and stores of the spilled live
  ranges (+3 bit 0) of register kind kind (operand$ip_reg, _fp_reg or
  _fp_reg_pair); pass 0 the allocator's first.  0x270F0C, 0xD5E bytes;
  called from ra.  Frame 8:al; 12:w; 14:w. }
procedure ra_utils_$add_spill_code(
    rtn: rtn_ptr_t;
    kind: operand$t;
    pass: integer); options(val_param); extern;
