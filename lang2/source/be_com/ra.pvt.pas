{ lang2/source/be_com/ra.pvt.pas - the register allocator's private insert (cc.a88k only): opened by
  ra and ra_utils (after call_conv.ins.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  The headings of ra's and ra_utils' global routines that the
  other calls, and the cells they share.  batch B (PB5): ra_utils'
  headings narrowed from its bodies, ra's from ra_utils' calls.

  Not known from the original: every parameter and cell name. }

var
  { ra.pas's data (A5 0x48F488). }
  ra_650: extern integer32;             { +0x650 (0x48FAD8): the debug
                                          level, at_backend_switches'
                                          (ra_utils_$spill_pass_through_lrs
                                          sets it) }

{ ra.pas (cc.a88k). }

{ RA_$CLEAN_BB_AND_INIT_BIT_VECTORS - 0x267048, 0x25A bytes; called from
  ra_utils (bb, 14, false).  Frame 8:al; 12:al; 16:bw. }
procedure ra_$clean_bb_and_init_bit_vectors(
    bb: bb_ptr_t;
    p2: integer32;
    p3: boolean); options(val_param); extern;

{ RA_$BUILD_CONFLICT_GRAPH - 0x2696C2, 0x1000 bytes; called from ra_utils
  (rtn, 14, true: 12 bytes of arguments).  Frame 8:al; 12:al; 16:b. }
procedure ra_$build_conflict_graph(
    rtn: rtn_ptr_t;
    p2: integer32;
    p3: boolean); options(val_param); extern;

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
