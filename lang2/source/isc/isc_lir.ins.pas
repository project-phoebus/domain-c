{ lang2/source/isc/isc_lir.ins.pas - the ISC's interface to the LIR (cc.a88k only): opened after the
  opcode enumeration (and call_conv.ins.pas) by lir, lir_main,
  lir_utils, ra_utils, call_conv and the ISC units.

  No Apollo copy survives.  Created as a stub with the back end's core
  (translator MM); batch A fills it as its units call the ISC.

  Not known from the original: everything about its contents but the
  routines' names. }

{ TODO(pascal) isc_lir.ins.pas: what lir and the ISC share }

{ MAKE_EXPRESSION_TEMPORARY - a new temporary variable (a kind 109
  node from isc_user_routines' heap, in il_180's block) of the type
  node kind (122 an integral type) and size in bits (32).
  isc_user_routines 0x2144EA, 0xAE bytes; 11 call sites (call_conv's
  at_call_conv: `pea 0x20; move.w #122'): kind a word at 8, bits a
  longword at 10; the node in A0.  batch A (PA3). }
function make_expression_temporary(
    kind: integer;
    bits: integer32): univ_ptr; options(val_param); extern;
