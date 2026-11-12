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

{ SOLUTION_LIST$DELETE - sol's cell taken out of list (translator PD2).
  0x0D989A, 0x74 bytes: list 8, sol 12. }
procedure solution_list$delete(
    list: solution_list_ptr_t;
    sol: isc_solution_ptr_t); options(val_param); extern;

{ The phase's entry points (at_backend's phase table names the four
  ISC_$ routines there; isc_user_routines' process_eval_node calls
  isc_$process_statement): ISC_$BEGIN_COMPILATION - 0x0D9A52;
  ISC_$INITIALIZE_ROUTINE - 0x0D9B92; ISC_$PROCESS_STATEMENT - 0x0D9C6C,
  the statement node under inh selected and its code emitted;
  ISC_$BEGIN_ROUTINE - 0x0DA1E4; ISC_$END_ROUTINE - 0x0DA27E;
  ISC_$END_COMPILATION - 0x0DB25A (translator PD2). }
procedure isc_$begin_compilation; extern;
procedure isc_$initialize_routine; extern;
procedure isc_$process_statement(
    node: univ_ptr;
    inh: inherited_attributes_ptr_t); options(val_param); extern;
procedure isc_$begin_routine(
    rtn: rtn_ptr_t); options(val_param); extern;
procedure isc_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;
procedure isc_$end_compilation; extern;

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

{ The printers the traces use: each writes its object on the standard
  output and returns a blank, which the callers write (`write(x_to_
  string(...))'). }

{ SOLUTION_TO_STRING - isc_user_routines 0x219FA6, 0xA86 bytes (frame):
  sol 8; D0. }
function solution_to_string(
    sol: isc_solution_ptr_t): char; options(val_param); extern;

{ LABEL_TO_STRING - isc_user_routines 0x21998C, 0x68 bytes (frame):
  8; D0. }
function label_to_string(
    lab: univ_ptr): char; options(val_param); extern;

{ INSTRUCTION_TO_STRING - isc_user_routines 0x219924, 0x40 bytes
  (frame): 8; D0. }
function instruction_to_string(
    instr: univ_ptr): char; options(val_param); extern;

{ IL_NODE_TO_STRING - isc_user_routines 0x21805C, 0x13EA bytes (frame):
  8; D0. }
function il_node_to_string(
    node: univ_ptr): char; options(val_param); extern;

{ ISC_$GET_MEMORY_HOME - sym's memory home for an access of bits bits
  as a kind node (122 an integral type, 123 a real one), or nil.
  0x213DE8, 0xCE bytes (frame): sym 8, kind a word at 12, bits 14; A0.
  Called from rewrite. }
function isc_$get_memory_home(
    sym: univ_ptr;
    kind: integer;
    bits: integer32): univ_ptr; options(val_param); extern;

{ ISC_$PRECISION_FROM_RLEN_AND_SIZE - the bits of a value of register
  class rlen and size bytes.  0x214BF6, 0x48 bytes (frame): rlen a word
  at 8, size 10; D0.  225 call sites (the patterns, rewrite). }
function isc_$precision_from_rlen_and_size(
    rlen: integer;
    size: integer32): integer32; options(val_param); extern;

{ isc_to_lir.pas: the phase's traces (isc_main calls them) and the
  debug_lir_ wrappers of the LIR's instruction builders (the pass-2
  actions call them; most defer the call to end_statement). }

{ GUARANTEE_HAS_LIVE_RANGE - isc_to_lir 0x2088B0. }
procedure guarantee_has_live_range(
    s: isc_solution_ptr_t); options(val_param); extern;

{ REQUESTS_TO_STRING - isc_to_lir 0x208BB4. }
function requests_to_string(
    r: integer32): char; options(val_param); extern;

{ BEGIN_COMPILATION - isc_to_lir 0x209168. }
procedure begin_compilation; extern;

{ END_COMPILATION - isc_to_lir 0x20928C. }
procedure end_compilation; extern;

{ BEGIN_ROUTINE - isc_to_lir 0x20933A. }
procedure begin_routine; extern;

{ END_ROUTINE - isc_to_lir 0x2093F2. }
procedure end_routine; extern;

{ BEGIN_BASIC_BLOCK - isc_to_lir 0x20949C. }
procedure begin_basic_block(
    n: integer); options(val_param); extern;

{ END_BASIC_BLOCK - isc_to_lir 0x2095D2. }
procedure end_basic_block(
    n: integer); options(val_param); extern;

{ BEGIN_STATEMENT - isc_to_lir 0x2096B2. }
procedure begin_statement; extern;

{ END_STATEMENT - isc_to_lir 0x209796. }
procedure end_statement; extern;

{ DEBUG_LIR_$BEGIN_CALL_OR_SVC - isc_to_lir 0x20B1A4. }
function debug_lir_$begin_call_or_svc(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    n: integer32): univ_ptr; options(val_param); extern;

{ DEBUG_LIR_$BEGIN_FORTRAN_IO_SEQUENCE - isc_to_lir 0x20B3FA. }
procedure debug_lir_$begin_fortran_io_sequence(
    p: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_$BRANCH_INSTRUCTION - isc_to_lir 0x20B500. }
procedure debug_lir_$branch_instruction(
    inh: inherited_attributes_ptr_t;
    target: univ_ptr;
    opc: integer;
    requests: integer32); options(val_param); extern;

{ DEBUG_LIR_$BREAK_BASIC_BLOCK - isc_to_lir 0x20B6E8. }
procedure debug_lir_$break_basic_block; extern;

{ DEBUG_LIR_$COMMON_LHS_RHS_TOKEN - isc_to_lir 0x20B824. }
procedure debug_lir_$common_lhs_rhs_token(
    inh: inherited_attributes_ptr_t); options(val_param); extern;

{ DEBUG_LIR_$DISJOINT_LHS_AND_RHS_TOKENS - isc_to_lir 0x20B972. }
procedure debug_lir_$disjoint_lhs_and_rhs_tokens(
    inh: inherited_attributes_ptr_t;
    lhs: univ_ptr;
    rhs: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_$DISPATCH_INSTRUCTION - isc_to_lir 0x20BACE. }
procedure debug_lir_$dispatch_instruction(
    inh: inherited_attributes_ptr_t;
    op1: isc_solution_ptr_t;
    opc: integer;
    requests: integer32); options(val_param); extern;

{ DEBUG_LIR_$EMIT_CALL_OR_SVC - isc_to_lir 0x20BCB2. }
procedure debug_lir_$emit_call_or_svc(
    inh: inherited_attributes_ptr_t;
    node: univ_ptr;
    call: univ_ptr;
    requests: integer32;
    sol: isc_solution_ptr_t;
    ret: solution_ptr_t); options(val_param); extern;

{ DEBUG_LIR_$END_CALL_OR_SVC - isc_to_lir 0x20BF38. }
procedure debug_lir_$end_call_or_svc(
    inh: inherited_attributes_ptr_t;
    call: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_$FIELD_INSTRUCTION - isc_to_lir 0x20C0BE. }
procedure debug_lir_$field_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    siz: integer32;
    src: isc_solution_ptr_t;
    pos: isc_solution_ptr_t;
    dst: isc_solution_ptr_t); options(val_param); extern;

{ DEBUG_LIR_$LABEL - isc_to_lir 0x20C388. }
procedure debug_lir_$label(
    inh: inherited_attributes_ptr_t;
    target: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_$LOAD_INSTRUCTION - isc_to_lir 0x20C4D4. }
procedure debug_lir_$load_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    index: isc_solution_ptr_t;
    base: isc_solution_ptr_t;
    result: isc_solution_ptr_t;
    tree: univ_ptr;
    disp_off_tree: integer32;
    bits_known: integer32;
    bits_trusted: integer32); options(val_param); extern;

{ DEBUG_LIR_$SIMPLE_INSTRUCTION - isc_to_lir 0x20C924. }
procedure debug_lir_$simple_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    op1: isc_solution_ptr_t;
    op2: isc_solution_ptr_t;
    op3: isc_solution_ptr_t); options(val_param); extern;

{ DEBUG_LIR_$STORE_INSTRUCTION - isc_to_lir 0x20CB8C. }
procedure debug_lir_$store_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    source: isc_solution_ptr_t;
    index: isc_solution_ptr_t;
    base: isc_solution_ptr_t;
    tree: univ_ptr;
    disp_off_tree: integer32;
    bits_known: integer32;
    bits_trusted: integer32); options(val_param); extern;

{ DEBUG_LIR_$MFPR_INSTRUCTION - isc_to_lir 0x20CF8E. }
procedure debug_lir_$mfpr_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    index: isc_solution_ptr_t;
    base: isc_solution_ptr_t;
    result: isc_solution_ptr_t;
    var_name: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_$MTPR_INSTRUCTION - isc_to_lir 0x20D2C2. }
procedure debug_lir_$mtpr_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    source: isc_solution_ptr_t;
    index: isc_solution_ptr_t;
    base: isc_solution_ptr_t;
    var_name: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_$OPERATE_AND_BRANCH_INSTRUCTION - isc_to_lir 0x20D5FC. }
procedure debug_lir_$operate_and_branch_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    op1: isc_solution_ptr_t;
    op2: isc_solution_ptr_t;
    target: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_MAIN_$ENTRY - isc_to_lir 0x20D850. }
procedure debug_lir_main_$entry(
    node: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_MAIN_$HANDLER_REENTRY - isc_to_lir 0x20D994. }
procedure debug_lir_main_$handler_reentry(
    node: univ_ptr); options(val_param); extern;

{ DEBUG_LIR_$PA_RISC_SHIFT_DOUBLE_INSTRUCTION - isc_to_lir 0x20DAE2. }
procedure debug_lir_$pa_risc_shift_double_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    op3: isc_solution_ptr_t;
    op1: isc_solution_ptr_t;
    op2: isc_solution_ptr_t;
    op4: isc_solution_ptr_t); options(val_param); extern;

{ isc_call_handling.pas: the generated actions of the call operators
  call these. }

{ PASS_1_ISC_CALL - pass 1 of the call tree node (the call begun, the
  inputs', routine's, hidden temporary's and outputs' solutions kept in
  the node).  0x0BA006. }
procedure pass_1_isc_call(
    node: isc_node_ptr_t;
    rclass: integer;
    inh: inherited_attributes_ptr_t;
    depth: integer); options(val_param); extern;

{ PASS_1_ISC_CALL_ADDR_OF_TEMP - the call tree node's hidden temporary's
  solution.  0x0BA2E0. }
function pass_1_isc_call_addr_of_temp(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ PASS_2_ISC_CALL - pass 2 of the call tree node and the call emitted.
  0x0BA2FC. }
procedure pass_2_isc_call(
    node: isc_node_ptr_t;
    async: boolean;
    ftn_io: boolean;
    pfm: boolean;
    inh: inherited_attributes_ptr_t;
    depth: integer); options(val_param); extern;

{ isc_cse_handling.pas: the generated actions of the CSE nodes call
  these. }

{ CHOOSE_ONE_CSE_SOLUTION - the solution of list a CSE is given (a
  literal, an address mode, a register).  0x0BA574. }
function choose_one_cse_solution(
    list: solution_list_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ MAP_CSE_USE_OB_TO_CSE_PARENT_OB - a CSE use's parent.  0x0BA698. }
function map_cse_use_ob_to_cse_parent_ob(
    node: isc_node_ptr_t): isc_node_ptr_t; options(val_param); extern;

{ SOLUTION_KIND_OF_CSE - the kind of the CSE's chosen solution.
  0x0BA70C. }
function solution_kind_of_cse(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_OB, PASS_1_CSE_USE_OB - pass 1 of a CSE's tree,
  reached through its parent or a use.  0x0BA7B0, 0x0BB4E8. }
procedure pass_1_cse_parent_ob(
    parent: isc_node_ptr_t;
    tree: isc_node_ptr_t;
    inh: inherited_attributes_ptr_t); options(val_param); extern;
procedure pass_1_cse_use_ob(
    use: isc_node_ptr_t;
    tree: isc_node_ptr_t;
    inh: inherited_attributes_ptr_t); options(val_param); extern;

{ PASS_2_CSE_PARENT_OB, PASS_2_CSE_USE_OB - pass 2 of a CSE, reached
  through its parent or a use, in the statement of index stmt.
  0x0BC6AC, 0x0BCE46. }
procedure pass_2_cse_parent_ob(
    parent: isc_node_ptr_t;
    stmt: integer); options(val_param); extern;
procedure pass_2_cse_use_ob(
    use: isc_node_ptr_t;
    stmt: integer); options(val_param); extern;

{ The accessors of the CSE's chosen solution (bug_check and 0, false or
  nil when there is none). }

{ PASS_1_CSE_PARENT_BITS_KNOWN - 0x0BA918: the bits_known of the solution
  chosen for the CSE whose parent is node. }
function pass_1_cse_parent_bits_known(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ PASS_1_CSE_PARENT_BITS_TRUSTED - 0x0BA9AC: the bits_trusted of the
  solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_bits_trusted(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ PASS_1_CSE_PARENT_CODE_BYTES - 0x0BAA42: the code_bytes of the solution
  chosen for the CSE whose parent is node. }
function pass_1_cse_parent_code_bytes(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_DELAY - 0x0BAAD8: the delay of the solution chosen for
  the CSE whose parent is node. }
function pass_1_cse_parent_delay(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_DISP - 0x0BAB68: the disp of the solution chosen for
  the CSE whose parent is node. }
function pass_1_cse_parent_disp(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ PASS_1_CSE_PARENT_EMBEDDED_SR_TEMP - 0x0BABF6: the embedded_sr_temp of
  the solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_embedded_sr_temp(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PASS_1_CSE_PARENT_EVAL_ORDER - 0x0BAC94: the eval_order of the solution
  chosen for the CSE whose parent is node. }
function pass_1_cse_parent_eval_order(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_LIT_VALUE - 0x0BAD28: the lit_value of the solution
  chosen for the CSE whose parent is node. }
function pass_1_cse_parent_lit_value(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ PASS_1_CSE_PARENT_IP_REG_MAX - 0x0BADBC: the ip_reg_max of the solution
  chosen for the CSE whose parent is node. }
function pass_1_cse_parent_ip_reg_max(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_IP_REG_RESULT - 0x0BAE50: the ip_reg_result of the
  solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_ip_reg_result(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_FP_REG_MAX - 0x0BAEE8: the fp_reg_max of the solution
  chosen for the CSE whose parent is node. }
function pass_1_cse_parent_fp_reg_max(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_FP_REG_RESULT - 0x0BAF7C: the fp_reg_result of the
  solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_fp_reg_result(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_FP_REG_PAIR_MAX - 0x0BB014: the fp_reg_pair_max of the
  solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_fp_reg_pair_max(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_FP_REG_PAIR_RESULT - 0x0BB0AE: the fp_reg_pair_result
  of the solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_fp_reg_pair_result(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_FP_REG_QUAD_MAX - 0x0BB14C: the fp_reg_quad_max of the
  solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_fp_reg_quad_max(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_FP_REG_QUAD_RESULT - 0x0BB1E6: the fp_reg_quad_result
  of the solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_fp_reg_quad_result(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_MEMORY_REFS - 0x0BB284: the memory_refs of the
  solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_memory_refs(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_PARENT_HAS_SYM_DISP - 0x0BB31A: the has_sym_disp of the
  solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_has_sym_disp(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PASS_1_CSE_PARENT_USES_DISP - 0x0BB3B2: the uses_disp of the solution
  chosen for the CSE whose parent is node. }
function pass_1_cse_parent_uses_disp(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PASS_1_CSE_PARENT_USES_INDEX_REG - 0x0BB44C: the uses_index_reg of the
  solution chosen for the CSE whose parent is node. }
function pass_1_cse_parent_uses_index_reg(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PASS_1_CSE_USE_BITS_KNOWN - 0x0BB652: the bits_known of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_bits_known(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ PASS_1_CSE_USE_BITS_TRUSTED - 0x0BB6FC: the bits_trusted of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_bits_trusted(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ PASS_1_CSE_USE_CODE_BYTES - 0x0BB7A8: the code_bytes of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_code_bytes(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_DELAY - 0x0BB852: the delay of the solution chosen for
  the CSE of node (a use, or its parent). }
function pass_1_cse_use_delay(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_DISP - 0x0BB8F8: the disp of the solution chosen for the
  CSE of node (a use, or its parent). }
function pass_1_cse_use_disp(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ PASS_1_CSE_USE_EMBEDDED_SR_TEMP - 0x0BB99C: the embedded_sr_temp of the
  solution chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_embedded_sr_temp(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PASS_1_CSE_USE_EVAL_ORDER - 0x0BBA50: the eval_order of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_eval_order(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_LIT_VALUE - 0x0BBAFA: the lit_value of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_lit_value(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ PASS_1_CSE_USE_IP_REG_MAX - 0x0BBBA4: the ip_reg_max of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_ip_reg_max(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_IP_REG_RESULT - 0x0BBC4E: the ip_reg_result of the
  solution chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_ip_reg_result(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_FP_REG_MAX - 0x0BBCFC: the fp_reg_max of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_fp_reg_max(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_FP_REG_RESULT - 0x0BBDA6: the fp_reg_result of the
  solution chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_fp_reg_result(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_FP_REG_PAIR_MAX - 0x0BBE54: the fp_reg_pair_max of the
  solution chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_fp_reg_pair_max(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_FP_REG_PAIR_RESULT - 0x0BBF02: the fp_reg_pair_result of
  the solution chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_fp_reg_pair_result(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_FP_REG_QUAD_MAX - 0x0BBFB4: the fp_reg_quad_max of the
  solution chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_fp_reg_quad_max(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_FP_REG_QUAD_RESULT - 0x0BC062: the fp_reg_quad_result of
  the solution chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_fp_reg_quad_result(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_MEMORY_REFS - 0x0BC114: the memory_refs of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_memory_refs(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ PASS_1_CSE_USE_HAS_SYM_DISP - 0x0BC1BE: the has_sym_disp of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_has_sym_disp(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PASS_1_CSE_USE_USES_DISP - 0x0BC26C: the uses_disp of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_uses_disp(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PASS_1_CSE_USE_USES_INDEX_REG - 0x0BC318: the uses_index_reg of the
  solution chosen for the CSE of node (a use, or its parent). }
function pass_1_cse_use_uses_index_reg(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PASS_2_CSE_PARENT_BASE_REG - 0x0BC3CA: the base_reg of the solution
  chosen for the CSE whose parent is node. }
function pass_2_cse_parent_base_reg(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param); extern;

{ PASS_2_CSE_PARENT_INDEX_REG - 0x0BC45C: the index_reg of the solution
  chosen for the CSE whose parent is node. }
function pass_2_cse_parent_index_reg(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param); extern;

{ PASS_2_CSE_PARENT_OBJ_W_NAME - 0x0BC4F0: the obj_w_name of the solution
  chosen for the CSE whose parent is node. }
function pass_2_cse_parent_obj_w_name(
    node: isc_node_ptr_t): univ_ptr; options(val_param); extern;

{ PASS_2_CSE_PARENT_HOME_SOLUTION - 0x0BC584: the home_solution of the
  solution chosen for the CSE whose parent is node. }
function pass_2_cse_parent_home_solution(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ PASS_2_CSE_PARENT_LIVE_RANGE - 0x0BC618: the live_range of the solution
  chosen for the CSE whose parent is node. }
function pass_2_cse_parent_live_range(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param); extern;

{ PASS_2_CSE_USE_BASE_REG - 0x0BCAFE: the base_reg of the solution chosen
  for the CSE of node (a use, or its parent). }
function pass_2_cse_use_base_reg(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param); extern;

{ PASS_2_CSE_USE_INDEX_REG - 0x0BCBA6: the index_reg of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_2_cse_use_index_reg(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param); extern;

{ PASS_2_CSE_USE_OBJ_W_NAME - 0x0BCC4E: the obj_w_name of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_2_cse_use_obj_w_name(
    node: isc_node_ptr_t): univ_ptr; options(val_param); extern;

{ PASS_2_CSE_USE_HOME_SOLUTION - 0x0BCCF6: the home_solution of the
  solution chosen for the CSE of node (a use, or its parent). }
function pass_2_cse_use_home_solution(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ PASS_2_CSE_USE_LIVE_RANGE - 0x0BCD9C: the live_range of the solution
  chosen for the CSE of node (a use, or its parent). }
function pass_2_cse_use_live_range(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param); extern;

{ isc_user_routines.pas: the rest of its global routines (translator
  PD2), the routines the generated pattern actions call, in address
  order; the unit's comments describe them. }

{ LITERAL_BASE_REGISTER - 0x20DD7C: the register literals are addressed
  from (nil for none); A0. }
function literal_base_register: solution_ptr_t; extern;

{ IS_IN_RANGE - 0x20DDC4: whether lo <= v <= hi. }
function is_in_range(
    v: integer32;
    lo: integer32;
    hi: integer32): boolean; options(val_param); extern;

{ LOCAL_CREATE_SOLN_FOR_IP_REG, _FP_REG, _FP_REG_PAIR, _FP_REG_QUAD -
  0x20DDF4, 0x20DE28, 0x20DE5C, 0x20DE90: a register's solution from
  heap; A0. }
function local_create_soln_for_ip_reg(
    in out heap: mrh_$heap_t): isc_solution_ptr_t; extern;
function local_create_soln_for_fp_reg(
    in out heap: mrh_$heap_t): isc_solution_ptr_t; extern;
function local_create_soln_for_fp_reg_pair(
    in out heap: mrh_$heap_t): isc_solution_ptr_t; extern;
function local_create_soln_for_fp_reg_quad(
    in out heap: mrh_$heap_t): isc_solution_ptr_t; extern;

{ INITIALIZE_WELL_KNOWN_SYMBOL - 0x20E892: sym's home solution made in
  the compilation's heap. }
procedure initialize_well_known_symbol(
    sym: isc_node_ptr_t;
    cand: boolean); options(val_param); extern;

{ NUMBER_OF_ONE_BITS - 0x20E8D2: the bits set in x; D0. }
function number_of_one_bits(
    x: integer32): integer32; options(val_param); extern;

{ ALIGNMENT_FROM_SR_INFO - 0x20E908: the alignment a variable under
  strength reduction keeps (info: its +52 or +46, by address); D0. }
function alignment_from_sr_info(
    in info: isc_sr_info_ptr_t): integer; extern;

{ LIR_$CAN_ENCODE_AS_IMMEDIATE_POSTINCREMENT - 0x2105D4: whether v fits
  a postincrement's immediate under the literal model.  The pass-1
  actions pass the instruction's opcode too (`movew #105,-(SP)' after a
  pad, before v: 0x0F82A2), which the routine does not read
  (translator GE). }
function lir_$can_encode_as_immediate_postincrement(
    v: integer32;
    opc: integer): boolean; options(val_param); extern;

{ AVAILABLE_PRECISION_FUNCTION - 0x210B06: the bits available in sol. }
function available_precision_function(
    sol: isc_solution_ptr_t): integer32; options(val_param); extern;

{ IS_ALL_ZEROES - 0x210B36: whether node is a set constant of zeroes. }
function is_all_zeroes(
    node: il_$node_ptr_t): boolean; options(val_param); extern;

{ FETCH_PRECISION_TO_BITS_TRUSTED - 0x210B88: the alignment mask a
  fetch of p bits may trust. }
function fetch_precision_to_bits_trusted(
    p: integer32): integer32; options(val_param); extern;

{ MAKE_BIT_MASK_1 - 0x210CF2: n one bits from bit lsb. }
function make_bit_mask_1(
    n: integer32;
    lsb: integer32): integer32; options(val_param); extern;

{ MAKE_BIT_MASK_2 - 0x210EA0: the bits msb down to lsb. }
function make_bit_mask_2(
    msb: integer32;
    lsb: integer32): integer32; options(val_param); extern;

{ BITS_KNOWN_FUNCTION - 0x211014: the bits known of op's result from
  its operands' a and b. }
function bits_known_function(
    op: il$t;
    a: integer32;
    b: integer32): integer32; options(val_param); extern;

{ IL_NODE_HAS_INTEGER_VALUE - 0x2121E6: whether node is an integer
  literal (D0); IL_NODE_TO_INTEGER_VALUE - 0x212260: its value. }
function il_node_has_integer_value(
    node: isc_node_ptr_t): boolean; options(val_param); extern;
function il_node_to_integer_value(
    node: isc_node_ptr_t): integer32; options(val_param); extern;

{ NUMBER_OF_RIGHTMOST_ZEROES - 0x212FC2: the low zero bits of x. }
function number_of_rightmost_zeroes(
    x: integer32): integer32; options(val_param); extern;

{ VALIDATE_SHIFT_COUNT - 0x216D8E: n checked as a shift count. }
function validate_shift_count(
    n: integer32): integer32; options(val_param); extern;

{ BITS_TO_ALIGNMENT - 0x211DC0: the low bits trusted and known zero;
  a word. }
function bits_to_alignment(
    known: integer32;
    trusted: integer32): integer; options(val_param); extern;

{ BITS_TRUSTED_FUNCTION - 0x211DFA: the bits trusted of op's result
  from its operands' a and b. }
function bits_trusted_function(
    op: il$t;
    a: integer32;
    b: integer32): integer32; options(val_param); extern;

{ BITS_TRUSTED_OF_FORTRAN_SYMBOL, BITS_TRUSTED_OF_VAR_NAME - 0x212058,
  0x2120CE: the trusted low bits of a symbol's address (both by
  address; x unused). }
function bits_trusted_of_fortran_symbol(
    in sym: isc_node_ptr_t;
    in x: integer32): integer32; extern;
function bits_trusted_of_var_name(
    in sym: isc_node_ptr_t;
    in x: integer32): integer32; extern;

{ BITS_TRUSTED_OF_SYMBOL - 0x21213C: either, by sym's kind. }
function bits_trusted_of_symbol(
    sym: isc_node_ptr_t;
    x: integer32): integer32; options(val_param); extern;

{ GET_KIND_OF_HOME_SOLUTION - 0x21217C: the kind of sym's home solution
  (0 for none); a word. }
function get_kind_of_home_solution(
    sym: univ_ptr): integer; options(val_param); extern;

{ IL_NODE_HAS_FLOAT_VALUE - 0x2121AE: whether node is a real constant. }
function il_node_has_float_value(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ ASSERT_KIND_IS_LABEL_NODE - 0x2122D4: node, checked to be a label. }
function assert_kind_is_label_node(
    node: isc_node_ptr_t): isc_node_ptr_t; options(val_param); extern;

{ CS_TEMP_TO_VAR_NAME - 0x2123D0: the temporary variable of a common
  subexpression's node. }
function cs_temp_to_var_name(
    node: il_$node_ptr_t): univ_ptr; options(val_param); extern;

{ LEGAL_EVALUATION_ORDERS - 0x212410: the orders two operands'
  solutions allow (bit 0 left to right, bit 1 right to left). }
function legal_evaluation_orders(
    s1: isc_solution_ptr_t;
    s2: isc_solution_ptr_t): integer; options(val_param); extern;

{ EVALUATION_ORDER_FUNCTION - 0x212450: the order op's operands are
  evaluated in (n1, n2 the operands' needs; legal the allowed orders). }
function evaluation_order_function(
    op: il$t;
    n1: integer;
    n2: integer;
    legal: integer): integer; options(val_param); extern;

{ SIMILAR_SOLUTIONS, CLEARLY_DOMINATES - 0x21255A, 0x2126A2: two
  candidate solutions compared. }
function similar_solutions(
    a: isc_solution_ptr_t;
    b: isc_solution_ptr_t): boolean; options(val_param); extern;
function clearly_dominates(
    a: isc_solution_ptr_t;
    b: isc_solution_ptr_t): boolean; options(val_param); extern;

{ IS_SEQUENCE_OF_ONES, IS_SEQUENCE_OF_ONES_RIGHT_JUSTIFIED,
  IS_SEQUENCE_OF_ZEROES - 0x21288C, 0x21292A, 0x2129C8: x's bits as one
  run. }
function is_sequence_of_ones(
    x: integer32): boolean; options(val_param); extern;
function is_sequence_of_ones_right_justified(
    x: integer32): boolean; options(val_param); extern;
function is_sequence_of_zeroes(
    x: integer32): boolean; options(val_param); extern;

{ LENGTH_OF_SEQUENCE_OF_ONES, LENGTH_OF_SEQUENCE_OF_ZEROES - 0x212A68,
  0x212AF4: x's one (zero) bits counted. }
function length_of_sequence_of_ones(
    x: integer32): integer32; options(val_param); extern;
function length_of_sequence_of_zeroes(
    x: integer32): integer32; options(val_param); extern;

{ IL_NODE_IS_LITERAL_SEQUENCE_OF_ONES, _ZEROES - 0x212B84, 0x212BFA:
  node a constant whose bits are one run. }
function il_node_is_literal_sequence_of_ones(
    node: isc_node_ptr_t): boolean; options(val_param); extern;
function il_node_is_literal_sequence_of_zeroes(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ IN_INTERVAL_AT_COMPILE_TIME - 0x212C8E: s1's known value within 0 ..
  s2's (unsigned) in size bytes. }
function in_interval_at_compile_time(
    size: integer;
    s1: isc_solution_ptr_t;
    s2: isc_solution_ptr_t): boolean; options(val_param); extern;

{ IS_DEVICE - 0x212D5E: node a device (volatile) object. }
function is_device(
    node: il_$node_ptr_t): boolean; options(val_param); extern;

{ SIGN_EXTEND - 0x212E02: v's low bits bits sign-extended. }
function sign_extend(
    v: integer32;
    bits: integer32): integer32; options(val_param); extern;

{ INTEGER32_FROM_CHAR_STRING_OB - 0x212E44: a character constant's
  value. }
function integer32_from_char_string_ob(
    node: il_$node_ptr_t): integer32; options(val_param); extern;

{ GET_UPARROW_DOT_KIND - 0x212EB8: node's kind; a word. }
function get_uparrow_dot_kind(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ NOT_PERMISSIBLE_FUNCTION - 0x212ED4: the register kinds an integer
  operator's tree node may not be given (w12 unused). }
function not_permissible_function(
    node: isc_node_ptr_t;
    w12: integer;
    permissible: solution$set_t): solution$set_t; options(val_param); extern;

{ NUMBER_OF_LEFTMOST_ZEROES, _LEFTMOST_ONES, _RIGHTMOST_ONES - 0x212F3A,
  0x212F80, 0x213004 (number_of_rightmost_zeroes above). }
function number_of_leftmost_zeroes(
    x: integer32): integer32; options(val_param); extern;
function number_of_leftmost_ones(
    x: integer32): integer32; options(val_param); extern;
function number_of_rightmost_ones(
    x: integer32): integer32; options(val_param); extern;

{ WELL_KNOWN_LITERAL - 0x213042: a new literal solution of v (the
  compilation's heap). }
function well_known_literal(
    v: integer32): isc_solution_ptr_t; options(val_param); extern;

{ FIND_WELL_KNOWN_LITERAL_SOLUTION - 0x21309E: the literal solution of
  v. }
function find_well_known_literal_solution(
    v: integer32): isc_solution_ptr_t; options(val_param); extern;

{ CREATE_SOLUTION_FOR_LITERAL_32_BITS - 0x213C68: a new literal
  solution of v. }
function create_solution_for_literal_32_bits(
    v: integer32): isc_solution_ptr_t; options(val_param); extern;

{ INITIALIZE_SYMBOL, ISC_$INITIALIZE_SYMBOL - 0x2130E8, 0x213120: sym's
  home solution made; ISC_$INITIALIZE_PARAMETER - 0x213158: a formal's,
  a register candidate when cand. }
procedure initialize_symbol(
    sym: isc_node_ptr_t); options(val_param); extern;
procedure isc_$initialize_symbol(
    sym: isc_node_ptr_t); options(val_param); extern;
procedure isc_$initialize_parameter(
    sym: isc_node_ptr_t;
    cand: boolean); options(val_param); extern;

{ IP_REG_TO_IP_REG_SCALED, IP_REG_SCALED_TO_IP_REG - 0x21342A,
  0x213462: an integer register's solution copied as scaled by shift,
  and back. }
function ip_reg_to_ip_reg_scaled(
    sol: isc_solution_ptr_t;
    shift: integer): isc_solution_ptr_t; options(val_param); extern;
function ip_reg_scaled_to_ip_reg(
    sol: isc_solution_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ HIGH_HALF_OF_FP_REG_PAIR, LOW_HALF_OF_FP_REG_PAIR,
  HIGH_HALF_OF_FP_REG_QUAD, LOW_HALF_OF_FP_REG_QUAD - 0x213490,
  0x2134DC, 0x213594, 0x2135D0: a register pair's (quad's) halves. }
function high_half_of_fp_reg_pair(
    sol: isc_solution_ptr_t): isc_solution_ptr_t; options(val_param); extern;
function low_half_of_fp_reg_pair(
    sol: isc_solution_ptr_t): isc_solution_ptr_t; options(val_param); extern;
function high_half_of_fp_reg_quad(
    sol: isc_solution_ptr_t): isc_solution_ptr_t; options(val_param); extern;
function low_half_of_fp_reg_quad(
    sol: isc_solution_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ ADDRESS_MODE_FOR_EXPRESSION_TEMPORARY - 0x21368E: an address mode of
  the frame temporary sym. }
function address_mode_for_expression_temporary(
    sym: univ_ptr;
    precision: integer32;
    known: integer32;
    trusted: integer32): isc_solution_ptr_t; options(val_param); extern;

{ ADDRESS_MODE_FOR_SINGLE_VALUE, _DOUBLE_VALUE, _INTEGER32_VALUE -
  0x213718, 0x2137CC, 0x213878: an address mode of a literal in the
  literal pool (the double by address). }
function address_mode_for_single_value(
    v: real): isc_solution_ptr_t; options(val_param); extern;
function address_mode_for_double_value(
    in d: double): isc_solution_ptr_t; extern;
function address_mode_for_integer32_value(
    v: integer32): isc_solution_ptr_t; options(val_param); extern;

{ COMPUTE_NUMBER_LOADED_BYTES - 0x213922: the loads an access of n
  bytes takes at an address of the alignment known and trusted give. }
function compute_number_loaded_bytes(
    n: integer32;
    known: integer32;
    trusted: integer32): integer32; options(val_param); extern;

{ CREATE_SOLUTION_FOR_ADDRESS_MODE, _IP_REG, _IP_REG_SCALED, _FP_REG,
  _FP_REG_PAIR, _FP_REG_QUAD - 0x2139BE, 0x213A2A, 0x213A58, 0x213A8A,
  0x213B62, 0x213C3A: a new solution of that kind (the ISC heap). }
function create_solution_for_address_mode: isc_solution_ptr_t; extern;
function create_solution_for_ip_reg: isc_solution_ptr_t; extern;
function create_solution_for_ip_reg_scaled: isc_solution_ptr_t; extern;
function create_solution_for_fp_reg: isc_solution_ptr_t; extern;
function create_solution_for_fp_reg_pair: isc_solution_ptr_t; extern;
function create_solution_for_fp_reg_quad: isc_solution_ptr_t; extern;

{ CREATE_SOLUTION_FOR_CASE_JUMP_BASE - 0x2139EC: a case jump's base
  (+12 the case node's +52). }
function create_solution_for_case_jump_base(
    node: il_$node_ptr_t): isc_solution_ptr_t; options(val_param); extern;

{ CREATE_SOLUTION_FOR_FP_REG_PHYSICAL, _FP_REG_PAIR_PHYSICAL - 0x213AB8,
  0x213B90: a floating register's (pair's) solution in register r. }
function create_solution_for_fp_reg_physical(
    r: integer): isc_solution_ptr_t; options(val_param); extern;
function create_solution_for_fp_reg_pair_physical(
    r: integer): isc_solution_ptr_t; options(val_param); extern;

{ DUPLICATE_ADDRESS_MODE - 0x213CA4: a copy of the address mode sol;
  DUPLICATE_ADDRESS_MODE_ADDING_BYTE_OFFSET - 0x213CDE: one displaced by
  offset (sol itself for 0). }
function duplicate_address_mode(
    sol: isc_solution_ptr_t): isc_solution_ptr_t; options(val_param); extern;
function duplicate_address_mode_adding_byte_offset(
    sol: isc_solution_ptr_t;
    offset: integer32): isc_solution_ptr_t; options(val_param); extern;

{ GET_LIVE_RANGE_ASSIGNED, _NO_MODIFY, _REGISTER, _SERIALIZE -
  0x2140D0, 0x2140F6, 0x21411E, 0x214144: a live range's flags and
  register (false, -1 for nil). }
function get_live_range_assigned(
    lr: lr_ptr_t): boolean; options(val_param); extern;
function get_live_range_no_modify(
    lr: lr_ptr_t): boolean; options(val_param); extern;
function get_live_range_register(
    lr: lr_ptr_t): integer; options(val_param); extern;
function get_live_range_serialize(
    lr: lr_ptr_t): boolean; options(val_param); extern;

{ GET_LIVE_RANGE_OF_IMAGINARY_PART - 0x21416C: the second live range of
  a FORTRAN symbol's or CSE's home solution. }
function get_live_range_of_imaginary_part(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param); extern;

{ IL_KIND_FUNCTION - 0x2144CE: node's kind; a word. }
function il_kind_function(
    node: isc_node_ptr_t): integer; options(val_param); extern;

{ POSSIBLY_MAKE_EXPRESSION_TEMPORARY - 0x214598: a temporary of type
  kind tkind and bits for a register solution kind skind (or a wide
  integral value), else nil. }
function possibly_make_expression_temporary(
    skind: integer;
    tkind: integer;
    bits: integer32): univ_ptr; options(val_param); extern;

{ VERIFY_BITS, VERIFY_ANY_BITS - 0x2145EE, 0x214916: whether the field
  of width bits at position holds expected in all (any) of its bits. }
function verify_bits(
    known: integer32;
    trusted: integer32;
    position: integer32;
    width: integer32;
    expected: integer32): boolean; options(val_param); extern;
function verify_any_bits(
    known: integer32;
    trusted: integer32;
    position: integer32;
    width: integer32;
    expected: integer32): boolean; options(val_param); extern;

{ RETURN_VALUE_NEEDS_ASSIGN_NODE - 0x214C3E: whether a value returned
  into sym needs an assignment (dest the value's own node). }
function return_value_needs_assign_node(
    sym: isc_node_ptr_t;
    dest: isc_node_ptr_t): boolean; options(val_param); extern;

{ RLEN_CODE_FROM_TYPE_NODE - 0x214CCC: the register class code of the
  type node t; a word. }
function rlen_code_from_type_node(
    t: isc_node_ptr_t): integer; options(val_param); extern;

{ PATTERN_MATCH_ERROR - 0x215660: a pattern matching failure pme
  reported for an IL node of kind kind (math: an f_math_top's kind) at
  source line line. }
procedure pattern_match_error(
    pme: integer;
    kind: il$t;
    math: integer;
    line: integer); options(val_param); extern;

{ PC_RELATIVE_LITERAL_SIZE_TO_BITS_TRUSTED - 0x2166F8: the alignment
  mask of a literal of n bytes. }
function pc_relative_literal_size_to_bits_trusted(
    n: integer32): integer32; options(val_param); extern;

{ SET_ISC_IS_CSE_ON_LIVE_RANGE_IF_LOCAL_CSE - 0x216736: lr marked a
  CSE's when local. }
procedure set_isc_is_cse_on_live_range_if_local_cse(
    local: boolean;
    lr: isc_lr_ptr_t); options(val_param); extern;

{ SIDE_EFFECT_SET_VAR_$ADDRESS_EXPOSED - 0x21675A: the variable sym
  marked address-exposed. }
procedure side_effect_set_var_$address_exposed(
    sym: isc_node_ptr_t); options(val_param); extern;

{ SIDE_EFFECT_FORTRAN_SYMBOL_FILL_IN_SIZE, SIDE_EFFECT_VAR_NAME_FILL_IN_SIZE
  - 0x216778, 0x216844: a symbol's size set (both by address); true.
  SIDE_EFFECT_SYMBOL_FILL_IN_SIZE - 0x21686A: either. }
function side_effect_fortran_symbol_fill_in_size(
    in sym: isc_node_ptr_t;
    in size: integer32): boolean; extern;
function side_effect_var_name_fill_in_size(
    in sym: isc_node_ptr_t;
    in size: integer32): boolean; extern;
function side_effect_symbol_fill_in_size(
    sym: isc_node_ptr_t;
    size: integer32): boolean; options(val_param); extern;

{ IS_POWER_OF_2, LOG_2 - 0x2168A8, 0x216934: x among the powers of two,
  and its index. }
function is_power_of_2(
    x: integer32): boolean; options(val_param); extern;
function log_2(
    x: integer32): integer32; options(val_param); extern;

{ INVERTIBLE_IN_SP, INVERTIBLE_IN_DP - 0x2168D8, 0x216906: a double
  constant's flags +20, +21. }
function invertible_in_sp(
    node: il_$node_ptr_t): boolean; options(val_param); extern;
function invertible_in_dp(
    node: il_$node_ptr_t): boolean; options(val_param); extern;

{ WARNING_UNALIGNED_ATOMIC_ACCESS - 0x21696E: an unaligned atomic
  access at line reported. }
procedure warning_unaligned_atomic_access(
    line: integer); options(val_param); extern;

{ WIDEN_CHAR_STRING_OB - 0x216A1E: a string constant widened to 4
  characters. }
function widen_char_string_ob(
    node: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ EXPRESSION_HAS_SIDE_EFFECTS - 0x216A80: whether node may have side
  effects. }
function expression_has_side_effects(
    node: isc_node_ptr_t): boolean; options(val_param); extern;

{ PROCESS_EVAL_NODE - 0x216B04: an EVAL_NODE's children with side
  effects given to the ISC as statements. }
procedure process_eval_node(
    eval: isc_node_ptr_t;
    parent: isc_node_ptr_t); options(val_param); extern;

{ VALUE_TOP_OVER - 0x216D34: a VALUE_TOP tree over node. }
function value_top_over(
    node: isc_node_ptr_t;
    rlen: integer;
    size: integer32): isc_node_ptr_t; options(val_param); extern;

{ SOLUTION_KIND_OF_SYMBOL - 0x216E8A: the kind of sym's home solution;
  a word. }
function solution_kind_of_symbol(
    sym: univ_ptr): integer; options(val_param); extern;


{ The printers (each writes and returns a blank): ARG_LOC_T_TO_STRING -
  0x216EC8; BASIC_BLOCK_TO_STRING - 0x216FC8; BLOCK_REC_TO_STRING -
  0x217004; CASE_INDEX_ARRAY_TO_STRING - 0x2170BE;
  IL_NODE_TO_EMPTY_STRING - 0x2170D4. }
function arg_loc_t_to_string(
    loc: integer): char; options(val_param); extern;
function basic_block_to_string: char; extern;
function block_rec_to_string(
    b: il_$node_ptr_t): char; options(val_param); extern;
{ ISC: case_index_array_to_string's parameter (translator PE): isc_
  debug's dump_solution passes a solution's +136 by address (`pea
  (136,A0)'), the rules' byte locals from +136 to the pointer locals
  at +352 less the seven already_ flags (+342 .. +348); the routine
  does not read it. }
type
  isc_case_index_array_t = array [136..341] of 0..255;

function case_index_array_to_string(
    var case_value: isc_case_index_array_t): char; extern;
function il_node_to_empty_string(
    node: univ_ptr): char; options(val_param); extern;

{ More printers: INSTRUCTION_TO_STRING (0x219924), LABEL_TO_STRING
  (0x21998C) and IL_NODE_TO_STRING (0x21805C) above; LIVE_RANGE_TO_STRING
  - 0x219A02; PHASE_SET_TO_STRING - 0x219AB6; RELATIONAL_TO_STRING -
  0x219E3A; SOLUTION_TO_STRING (0x219FA6) above;
  TYPE_ATTR_SET_TO_STRING - 0x21AC0C; VATT_REC_TO_STRING - 0x21AF9E;
  VATT_SET_TO_STRING - 0x21B17A. }
function live_range_to_string(
    lr: lr_ptr_t): char; options(val_param); extern;
function phase_set_to_string(
    p: add_node_$phase_t): char; options(val_param); extern;
function relational_to_string(
    r: integer): char; options(val_param); extern;
function type_attr_set_to_string(
    t: isc_attr_set_t): char; options(val_param); extern;
function vatt_rec_to_string(
    v: isc_node_ptr_t): char; options(val_param); extern;
function vatt_set_to_string(
    a: isc_attr_set_t): char; options(val_param); extern;


