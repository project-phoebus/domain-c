{ moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas - the generated ISC's private interface (a DSEE derived
  object of the iscg_input description; cc.a88k only): opened by the
  ISC units after isc_solution_fields.ins.pas and before
  isc_consts.ins.pas, so it can use the solutions and the inherited
  attributes but not isc_types.ins.pas (nodes are univ_ptr here).

  The routines the generator emits that the hand-written units call:
  the two passes' drivers (isc_pass_1_main's pass_1, isc_pass_2_main's
  pass_2) and isc_debug's printers.  The ~1080 unnamed pattern actions
  are not declared (docs/questions.md 151: they are to be rebuilt by a
  generator; docs/isc-notes.md).

  No Apollo copy survives; the headings are read off the routines'
  frames and their callers (translator PD).

  Not known from the original: the parameters' names. }

{ PASS_1 - the solutions pass 1 finds for node under the inherited
  attributes inh, whose kinds are among permissible (the pattern
  matcher's candidates, a list).  isc_pass_1_main 0x0F04BC, 0x646
  bytes; 290 call sites: node 8, inh 12, depth a word at 16 (the
  callers pass their own plus one), permissible a longword at 18; A0. }
function pass_1(
    node: univ_ptr;
    inh: inherited_attributes_ptr_t;
    depth: integer;
    permissible: solution$set_t): solution_list_ptr_t; options(val_param); extern;

{ PASS_2 - pass 2 over the solution sol and its children (in its
  eval_order, through its chain) and then the pass-2 action of its rule
  (isc_pass_2_main's table of action routines, by rule); marks it
  pass_2_done.  0x18C588, 0x218 bytes: sol 8, depth a word at 12. }
procedure pass_2(
    sol: isc_solution_ptr_t;
    depth: integer); options(val_param); extern;

{ DUMP_SOLUTION - sol printed on the standard output, indented by
  depth, its children too when deep.  isc_debug 0x0D6174, 0x23F6
  bytes: sol 8, depth a word at 12, deep a byte at 14. }
procedure dump_solution(
    sol: isc_solution_ptr_t;
    depth: integer;
    deep: boolean); options(val_param); extern;

{ ISC_PASS_1_BEGIN_COMPILATION - isc_pass_1_main's tables set up for
  the compilation.  0x0EFE96, 0x626 bytes; no parameters (called from
  isc_main's isc_$begin_compilation; translator PD2). }
procedure isc_pass_1_begin_compilation; extern;

{ The section isc_tool_generated_readonly_tables (cc.a88k 0x2BC13C, 3264
  bytes; defined by isc_vars, generated from the rule file by
  tools/iscg_gen.py; translator GB): result_kind, by rule 1..563, the
  kind of the solution the rule makes (hard_work's check_permissible
  test: `movea.l #0x2BC13C,A0; move.w (-2,A0,D0.l),D1'), then six maps
  by il$t of the opcode an operator is done with, which the pass-1
  actions read by the subject's il$t: reg-reg with the operands
  reversed (sub_top -> opc$rsub), reg-reg, immediate, double float,
  immediate negated, single float.  Not known from the original: the
  names. }
type
  isc_opcode_map_t = array [il$t] of integer;
  isc_tool_tables_t = record
    result_kind: array [1..563] of integer;     { +0 }
    opcode_rr_reversed: isc_opcode_map_t;       { +1126 }
    opcode_rr: isc_opcode_map_t;                { +1482 }
    opcode_immediate: isc_opcode_map_t;         { +1838 }
    opcode_double: isc_opcode_map_t;            { +2194 }
    opcode_immediate_negated: isc_opcode_map_t; { +2550 }
    opcode_single: isc_opcode_map_t;            { +2906 }
    pad: integer;                               { +3262: zero }
  end;

var (isc_tool_generated_readonly_tables)
  isc_tool_generated_readonly_tables: isc_tool_tables_t;
