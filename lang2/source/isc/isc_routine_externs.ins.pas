{ lang2/source/isc/isc_routine_externs.ins.pas - the ISC's routines (cc.a88k only): opened by the ISC
  units after isc_types.ins.pas and before isc_var_externs.ins.pas.

  The headings of the ISC units' global routines that another ISC unit
  (or a generated pattern action) calls: isc_main's (the solutions, the
  inherited attributes, the solution lists), isc_to_lir's (the
  debug_lir_ wrappers of the LIR's instruction builders),
  isc_user_routines' (the routines the patterns call),
  isc_call_handling's and isc_cse_handling's.  The ISC's entry points
  that the rest of the back end calls are in isc_lir.ins.pas (batch A's
  lines and the ISC blocks) and backend.ins.pas
  (isc_$get_il_live_range).

  No Apollo copy survives; the headings are read off the routines'
  frames and bodies (translator PD).  A routine whose body is not
  translated yet has its heading read off its frame and callers (as
  the back end's core did): such parameters are marked "frame".

  Not known from the original: the parameters' names. }

{ isc_main.pas (moon_unit). }

{ NEW_INHERITED_ATTRIBUTES - new inherited attributes from heap for
  node: node and stmt node, precision and available 32, arith
  arith_integer, the rest clear.  0x0D92C8, 0x50 bytes: heap 8 (by
  address; every caller passes the ISC heap, isc_user_routines +0x23C),
  node 12; A0.  299 call sites. }
function new_inherited_attributes(
    in out heap: mrh_$heap_t;
    node: univ_ptr): inherited_attributes_ptr_t; options(val_param); extern;

{ NEW_SOLUTION - a new solution from heap of kind kind with nchildren
  children (bug_check above 5), made under inh, for sym.  0x0D9318,
  0xAA bytes: heap 8, kind a word at 12, nchildren a word at 14, inh
  16, sym 20, w98 a word at 24; A0. }
function new_solution(
    in out heap: mrh_$heap_t;
    kind: integer;
    nchildren: integer;
    inh: inherited_attributes_ptr_t;
    sym: univ_ptr;
    w98: integer): isc_solution_ptr_t; options(val_param); extern;

{ DUPLICATE_SOLUTION - a copy of sol from heap (nil for nil).
  0x0D93FC, 0x62 bytes: heap 8, sol 12; A0. }
function duplicate_solution(
    in out heap: mrh_$heap_t;
    sol: isc_solution_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ DUPLICATE_INHERITED_ATTRIBUTES - a copy of inh from heap (nil for
  nil).  0x0D945E, 0x48 bytes: heap 8, inh 12; A0. }
function duplicate_inherited_attributes(
    in out heap: mrh_$heap_t;
    inh: inherited_attributes_ptr_t): inherited_attributes_ptr_t;
    options(val_param); extern;

{ PRESERVE_SOLUTION - sol and the solutions it holds copied into the
  ISC's preserved heap (isc_user_routines +0x224) once; the copy.
  0x0D94A6, 0x340 bytes: sol 8; A0. }
function preserve_solution(
    sol: isc_solution_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ SOLUTION_LIST$NEW - an empty list from the ISC heap.  0x0D97E6; A0. }
function solution_list$new: solution_list_ptr_t; extern;

{ SOLUTION_LIST$APPEND - sol put at list's end (bug_check for a nil
  list).  0x0D980C, 0x64 bytes: list 8, sol 12. }
procedure solution_list$append(
    list: solution_list_ptr_t;
    sol: isc_solution_ptr_t); options(val_param); extern;

{ SOLUTION_LIST$EMPTY - whether list has no solutions (bug_check for a
  nil list).  0x0D9938, 0x30 bytes: list 8; D0. }
function solution_list$empty(
    list: solution_list_ptr_t): boolean; options(val_param); extern;

{ SOLUTION_LIST$PRESERVE - list and its solutions copied into the
  preserved heap.  0x0D9992, 0x94 bytes: list 8; A0. }
function solution_list$preserve(
    list: solution_list_ptr_t): solution_list_ptr_t; options(val_param); extern;

{ APPLY_PASS_1_AND_CHOOSE_TO_LIST - one chosen solution for each node
  of the chain from node (linked at +8) under inh, as a list.
  0x0D9DDC, 0x276 bytes: node 8, inh 12; A0. }
function apply_pass_1_and_choose_to_list(
    node: univ_ptr;
    inh: inherited_attributes_ptr_t): solution_list_ptr_t;
    options(val_param); extern;

{ APPLY_PASS_2_TO_LIST - pass 2 over each solution of list.  0x0DA0BE,
  0xE6 bytes: list 8. }
procedure apply_pass_2_to_list(
    list: solution_list_ptr_t); options(val_param); extern;

{ isc_user_routines.pas. }

{ CHOOSE_ONE_SOLUTION - the solution chosen among list's.  0x2127E8,
  0x7C bytes (frame): list 8; A0. }
function choose_one_solution(
    list: solution_list_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ IS_A_REGISTER_SOLUTION - whether sol is a register's.  0x2133F4, 0x36
  bytes (frame): sol 8; D0. }
function is_a_register_solution(
    sol: isc_solution_ptr_t): boolean; options(val_param); extern;

{ ARITHMETIC_FROM_IL_NODE - how node's value is computed.  0x214F7E,
  0x290 bytes (frame): node 8; D0 (a byte). }
function arithmetic_from_il_node(
    node: univ_ptr): arith$t; options(val_param); extern;

{ PRECISION_FROM_IL_NODE - the bits of node's value.  0x21529C, 0x2EC
  bytes (frame): node 8; D0. }
function precision_from_il_node(
    node: univ_ptr): integer32; options(val_param); extern;

{ isc_to_lir.pas: the debug_lir_ wrappers (each traces its arguments
  when the ISC's trace is on and calls the lir_ routine of its name). }

{ DEBUG_LIR_$BEGIN_CALL_OR_SVC - the call's record, for an instruction
  of opcode opc with requests and count operands.  0x20B1A4, 0x1FA
  bytes (frame): inh 8, opc a word at 12, requests 14, count 18; A0. }
function debug_lir_$begin_call_or_svc(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    count: integer32): univ_ptr; options(val_param); extern;

{ DEBUG_LIR_$EMIT_CALL_OR_SVC - the call node's call (its record call)
  emitted: the routine's solution sol, the return address register's
  solution ret.  0x20BCB2, 0x242 bytes (frame): inh 8, node 12, call
  16, requests 20, sol 24, ret 28. }
procedure debug_lir_$emit_call_or_svc(
    inh: inherited_attributes_ptr_t;
    node: univ_ptr;
    call: univ_ptr;
    requests: integer32;
    sol: isc_solution_ptr_t;
    ret: solution_ptr_t); options(val_param); extern;

{ DEBUG_LIR_$END_CALL_OR_SVC - the call finished.  0x20BF38, 0x16A bytes
  (frame): inh 8, call 12. }
procedure debug_lir_$end_call_or_svc(
    inh: inherited_attributes_ptr_t;
    call: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_$SIMPLE_INSTRUCTION - an instruction of opcode opc on the
  operands' solutions.  0x20C924, 0x268 bytes (frame): inh 8, opc a
  word at 12, requests 14, op1 18, op2 22, op3 26. }
procedure debug_lir_$simple_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    op1: isc_solution_ptr_t;
    op2: isc_solution_ptr_t;
    op3: isc_solution_ptr_t); options(val_param); extern;
