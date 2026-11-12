{ lang2/source/be_com/ra.pvt.pas - the register allocator's private insert (cc.a88k only): opened by
  ra and ra_utils (after call_conv.ins.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  For now only the headings of ra's and ra_utils' global routines that the other calls, read off the frames and
  the callers' pushes (a pointer univ_ptr, a longword integer32, a word
  integer, a byte boolean; p1..pn); the units' translators add the
  types and cells the units share (docs/backend-plan.md).

  Not known from the original: every parameter name. }

{ TODO(pascal) ra.pvt.pas: the shared types and cells }

{ ra.pas (cc.a88k). }

{ RA_$CLEAN_BB_AND_INIT_BIT_VECTORS - 0x267048, 0x25A bytes; called from
  ra_utils.  Frame 8:al; 12:al; 16:bw. }
procedure ra_$clean_bb_and_init_bit_vectors(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer); options(val_param); extern;

{ RA_$BUILD_CONFLICT_GRAPH - 0x2696C2, 0x1000 bytes; called from ra_utils.
  Frame 8:al; 12:al; 15:?; 16:b. }
procedure ra_$build_conflict_graph(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer32;
    p4: boolean); options(val_param); extern;

{ ra_utils.pas (cc.a88k). }

{ RA_UTILS_$COMPUTE_COMPLEX_LIFETIMES - 0x26DFC0, 0x82 bytes; called from
  ra.  Frame 8:al. }
procedure ra_utils_$compute_complex_lifetimes(
    p1: univ_ptr); options(val_param); extern;

{ RA_UTILS_$REMATERIALIZE - 0x26F6EE, 0x2E8 bytes; called from ra.  Frame
  8:l; 12:al; 16:bw.  Result: A0 (callers: A05). }
function ra_utils_$rematerialize(
    p1: integer32;
    p2: univ_ptr;
    p3: integer): univ_ptr; options(val_param); extern;

{ RA_UTILS_$ADD_SPILL_CODE - 0x270F0C, 0xD5E bytes; called from ra.  Frame
  8:al; 12:w; 14:w. }
procedure ra_utils_$add_spill_code(
    p1: univ_ptr;
    p2: integer;
    p3: integer); options(val_param); extern;
