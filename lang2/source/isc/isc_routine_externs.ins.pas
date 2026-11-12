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

