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

{ ISC_$IS_A_REGISTER_CANDIDATE - whether the variable (109) or common
  member (110) sym may live in a register.  isc_user_routines 0x213198;
  called from lir_main.  Result: D0.  batch A (PA5). }
function isc_$is_a_register_candidate(
    sym: univ_ptr): boolean; options(val_param); extern;

{ ISC_$GET_HOME_SOLUTION - the solution of sym's home (a variable's
  +60).  isc_user_routines 0x213D22; called from lir_main.  Result: A0. }
function isc_$get_home_solution(
    sym: univ_ptr): solution_ptr_t; options(val_param); extern;

{ REWRITE_$ENTRY - rewrite.pas 0x21D926; called from lir_main_$entry
  with the entry statement, lir_main +0xDB4 and +0xD9C (set there:
  no_xsb a boolean, second the node of a second entry). }
procedure rewrite_$entry(
    node: univ_ptr;
    var no_xsb: boolean;
    var second: univ_ptr); options(val_param); extern;
