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

{ LIR_$ISC_BUGCHECK - the ISC's pass 2 failure reported ('ISC pass 2
  failure').  lir.pas 0x242820, 0x1E bytes: no parameters.  batch A
  (PA6). }
procedure lir_$isc_bugcheck; extern;

type
  { A well-known register's name (four characters, blank-filled: 'R12 ',
    'F3  ', 'X10 ', 'PC  ', 'AP  ', ...).  batch A (PA6). }
  isc_$reg_name_t = packed array [1..4] of char;

{ ISC_$INIT_WELL_KNOWN_IP_REG - the solution of the integer register k
  (-1 for a symbolic register: AP, DB, RPC, SL, ER, LB, SF) named name.
  isc_user_routines 0x214296: name by address at 8 (its third character
  tested for a blank), k a longword at 12; A0.  batch A (PA6, lir). }
function isc_$init_well_known_ip_reg(
    in name: isc_$reg_name_t;
    k: integer32): solution_ptr_t; options(val_param); extern;

{ ISC_$INIT_WELL_KNOWN_FP_REG - likewise a floating register's
  (isc_user_routines 0x21435A). }
function isc_$init_well_known_fp_reg(
    in name: isc_$reg_name_t;
    k: integer32): solution_ptr_t; options(val_param); extern;

{ ISC_$INIT_WELL_KNOWN_FP_REG_PAIR - likewise an even floating register's
  pair (isc_user_routines 0x214414). }
function isc_$init_well_known_fp_reg_pair(
    in name: isc_$reg_name_t;
    k: integer32): solution_ptr_t; options(val_param); extern;
