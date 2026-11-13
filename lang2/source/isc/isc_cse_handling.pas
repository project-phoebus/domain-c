{ isc_cse_handling - the ISC's common subexpressions.  The optimizer
  leaves a CSE as a parent node (190 CSE_PARENT_OB, over the expression
  tree) and its uses (189 CSE_USE_OB, each pointing at the parent).
  Pass 1 of whichever comes first finds the tree's solutions (an
  address mode, a register or a 32-bit literal), chooses one
  (choose_one_cse_solution: a literal, else an address mode, else a
  register that is not physical; the cheapest of its kind), preserves
  it as the parent's chosen_solution and marks the tree done (kind 138
  GEN_TREE_NODE).  The generated patterns read the chosen solution's
  fields through the pass_1_cse_* and pass_2_cse_* accessors (named
  after the field).  Pass 2 in the CSE's own statement generates it
  into a live range (pass_2_cse_parent_ob, pass_2_cse_use_ob); if a use
  came first it has already been given a live range, so the value is
  then moved from the new one to it; in another statement a register
  solution only gets a live range if it has none.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x0BA574  choose_one_cse_solution
    --------  0x0BA698  map_cse_use_ob_to_cse_parent_ob
    --------  0x0BA70C  solution_kind_of_cse
    --------  0x0BA7B0  pass_1_cse_parent_ob
    --------  0x0BA918  pass_1_cse_parent_bits_known
    --------  0x0BA9AC  pass_1_cse_parent_bits_trusted
    --------  0x0BAA42  pass_1_cse_parent_code_bytes
    --------  0x0BAAD8  pass_1_cse_parent_delay
    --------  0x0BAB68  pass_1_cse_parent_disp
    --------  0x0BABF6  pass_1_cse_parent_embedded_sr_temp
    --------  0x0BAC94  pass_1_cse_parent_eval_order
    --------  0x0BAD28  pass_1_cse_parent_lit_value
    --------  0x0BADBC  pass_1_cse_parent_ip_reg_max
    --------  0x0BAE50  pass_1_cse_parent_ip_reg_result
    --------  0x0BAEE8  pass_1_cse_parent_fp_reg_max
    --------  0x0BAF7C  pass_1_cse_parent_fp_reg_result
    --------  0x0BB014  pass_1_cse_parent_fp_reg_pair_max
    --------  0x0BB0AE  pass_1_cse_parent_fp_reg_pair_result
    --------  0x0BB14C  pass_1_cse_parent_fp_reg_quad_max
    --------  0x0BB1E6  pass_1_cse_parent_fp_reg_quad_result
    --------  0x0BB284  pass_1_cse_parent_memory_refs
    --------  0x0BB31A  pass_1_cse_parent_has_sym_disp
    --------  0x0BB3B2  pass_1_cse_parent_uses_disp
    --------  0x0BB44C  pass_1_cse_parent_uses_index_reg
    --------  0x0BB4E8  pass_1_cse_use_ob
    --------  0x0BB652  pass_1_cse_use_bits_known
    --------  0x0BB6FC  pass_1_cse_use_bits_trusted
    --------  0x0BB7A8  pass_1_cse_use_code_bytes
    --------  0x0BB852  pass_1_cse_use_delay
    --------  0x0BB8F8  pass_1_cse_use_disp
    --------  0x0BB99C  pass_1_cse_use_embedded_sr_temp
    --------  0x0BBA50  pass_1_cse_use_eval_order
    --------  0x0BBAFA  pass_1_cse_use_lit_value
    --------  0x0BBBA4  pass_1_cse_use_ip_reg_max
    --------  0x0BBC4E  pass_1_cse_use_ip_reg_result
    --------  0x0BBCFC  pass_1_cse_use_fp_reg_max
    --------  0x0BBDA6  pass_1_cse_use_fp_reg_result
    --------  0x0BBE54  pass_1_cse_use_fp_reg_pair_max
    --------  0x0BBF02  pass_1_cse_use_fp_reg_pair_result
    --------  0x0BBFB4  pass_1_cse_use_fp_reg_quad_max
    --------  0x0BC062  pass_1_cse_use_fp_reg_quad_result
    --------  0x0BC114  pass_1_cse_use_memory_refs
    --------  0x0BC1BE  pass_1_cse_use_has_sym_disp
    --------  0x0BC26C  pass_1_cse_use_uses_disp
    --------  0x0BC318  pass_1_cse_use_uses_index_reg
    --------  0x0BC3CA  pass_2_cse_parent_base_reg
    --------  0x0BC45C  pass_2_cse_parent_index_reg
    --------  0x0BC4F0  pass_2_cse_parent_obj_w_name
    --------  0x0BC584  pass_2_cse_parent_home_solution
    --------  0x0BC618  pass_2_cse_parent_live_range
    --------  0x0BC6AC  pass_2_cse_parent_ob
    --------  0x0BCAFE  pass_2_cse_use_base_reg
    --------  0x0BCBA6  pass_2_cse_use_index_reg
    --------  0x0BCC4E  pass_2_cse_use_obj_w_name
    --------  0x0BCCF6  pass_2_cse_use_home_solution
    --------  0x0BCD9C  pass_2_cse_use_live_range
    --------  0x0BCE46  pass_2_cse_use_ob
  A5 0x44E7FC: the module has no data of its own (every routine loads
  A5; PAS_$WRITE's file is at (-4,A5)).  Each routine's messages follow
  its code.

  The writes are dpc gap 4 (docs/dpc-gaps.md 4).

  Not known from the original: the parameters' and locals' names. }
module isc_cse_handling;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas';
%include 'lang2/source/isc/isc_consts.ins.pas';
%include 'lang2/source/isc/isc_types.ins.pas';
%include 'lang2/source/isc/isc_routine_externs.ins.pas';
%include 'lang2/source/isc/isc_var_externs.ins.pas';

{ choose_one_cse_solution - the solution of list a CSE is given: the
  32-bit literal, else the address mode, else the register solution
  that is not physical, of least code_bytes plus delay (the first of
  the least), of least memory_references among those of equal cost.

  0x0BA574, 0xF6 bytes: list 8 (bug_check when nil); the three
  candidates in D6, D7 and (-20,A6), their costs in D3, D5, D4; the
  cost from zero-extended words (`clr.l; move.w'); a candidate taken
  when none yet, `blt' on the cost, or equal cost and memory_references
  lower (`bcc' to skip: unsigned); the kinds compared with 14 and 5;
  physical `btst #3,(83,A2)'. }

function choose_one_cse_solution(
    list: solution_list_ptr_t): isc_solution_ptr_t; options(val_param);
var
  lit, am, reg: isc_solution_ptr_t;
  lit_cost, am_cost, reg_cost: integer32;
  cost: integer32;
  cell: solution_cell_ptr_t;
  s: isc_solution_ptr_t;
begin
  if list = nil then
    bug_check('ISC: choose_one_cse_solution: list is nil.%$');
  lit := nil;
  am := lit;
  reg := lit;
  cell := list^.first;
  while cell <> nil do begin
    s := cell^.sol;
    cost := s^.code_bytes + s^.delay;
    if s^.kind = solution$literal_32_bits then begin
      if (lit = nil) or (cost < lit_cost)
         or ((cost = lit_cost) and (s^.memory_references < lit^.memory_references)) then begin
        lit := s;
        lit_cost := cost;
      end;
    end
    else if s^.kind = solution$address_mode then begin
      if (am = nil) or (cost < am_cost)
         or ((cost = am_cost) and (s^.memory_references < am^.memory_references)) then begin
        am := s;
        am_cost := cost;
      end;
    end
    else if is_a_register_solution(s) and not s^.f76.physical_register then begin
      if (reg = nil) or (cost < reg_cost)
         or ((cost = reg_cost) and (s^.memory_references < reg^.memory_references)) then begin
        reg := s;
        reg_cost := cost;
      end;
    end;
    cell := cell^.next;
  end;
  if lit <> nil then
    choose_one_cse_solution := lit
  else if am <> nil then
    choose_one_cse_solution := am
  else
    choose_one_cse_solution := reg;
end;

{ map_cse_use_ob_to_cse_parent_ob - the parent of the CSE use node
  (bug_check and nil when node is not a 189).

  0x0BA698, 0x32 bytes: +16 into A0. }

function map_cse_use_ob_to_cse_parent_ob(
    node: isc_node_ptr_t): isc_node_ptr_t; options(val_param);
begin
  if node^.kind <> cse_use_ob then begin
    bug_check('ISC: map_cse_use_ob_to_cse_parent_ob: il is not a cse_use_ob.%$');
    map_cse_use_ob_to_cse_parent_ob := nil;
  end
  else
    map_cse_use_ob_to_cse_parent_ob := node^.cu_parent;
end;

{ solution_kind_of_cse - the kind of the solution chosen for the CSE of
  node (a use, or its parent).

  0x0BA70C, 0x4C bytes: node 8, mapped when its kind is 189; the kind a
  word (+108); bug_check and solution$none when there is no solution. }

function solution_kind_of_cse(
    node: isc_node_ptr_t): solution$t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: solution_kind_of_cse: chosen_solution is nil, meaning cse has not yet been coded.%$');
    solution_kind_of_cse := solution$none;
  end
  else
    solution_kind_of_cse := s^.kind;
end;

{ pass_1_cse_parent_ob - pass 1 of a CSE's tree under inh (once: tree
  is a 138 when done): the tree's solutions among an address mode, the
  floating registers, an integer register and a 32-bit literal, under
  inh's copy with the tree's arithmetic, precision (required_precision
  and fetch_precision both precision_from_il_node's), statement
  exception_frame, line and index, immediate_parent_wants_lvalue clear
  and inside_a_cse set (depth 0); one chosen
  (choose_one_cse_solution), preserved and kept as parent's
  chosen_solution, and tree marked 138; bug_check with inh's line
  when none.

  0x0BA7B0, 0xFE bytes: parent 8, tree 12, inh 16; the copy of inh
  over the new attributes (ten longwords: `move.l (A0)+,(A1)+' twice,
  `dbf' 4); precision_from_il_node called twice (+28 then +24); the
  index `and.l #16#FFFF00; lsr.l #8'; `bclr #5; bset #2' at +39; the
  permissible set `pea 16#4F20'. }

procedure pass_1_cse_parent_ob(
    parent: isc_node_ptr_t;
    tree: isc_node_ptr_t;
    inh: inherited_attributes_ptr_t); options(val_param);
var
  inh2: inherited_attributes_ptr_t;
  sols: solution_list_ptr_t;
  s: isc_solution_ptr_t;
begin
  if tree^.kind <> gen_tree_node then begin
    inh2 := new_inherited_attributes(isc_heap, tree);
    inh2^ := inh^;
    inh2^.f38.required_arithmetic := ord(arithmetic_from_il_node(tree));
    inh2^.required_precision := precision_from_il_node(tree);
    inh2^.fetch_precision := precision_from_il_node(tree);
    inh2^.exception_frame := tree^.tr_top^.st_top;
    inh2^.pos.source_line_number := tree^.tr_top^.st_line;
    inh2^.pos.stmt_number := rshft(tree^.tr_top^.st_l42 & 16#FFFF00, 8);
    inh2^.f38.immediate_parent_wants_lvalue := false;
    inh2^.f38.inside_a_cse := true;
    sols := pass_1(tree, inh2, 0,
        [solution$address_mode, solution$fp_reg, solution$fp_reg_pair,
         solution$fp_reg_quad, solution$ip_reg, solution$literal_32_bits]);
    s := choose_one_cse_solution(sols);
    if s = nil then
      bug_check('ISC: source line %wd: pass_1_cse_parent_ob: chosen_solution is nil, meaning cse has not yet been coded.%$',
          inh^.pos.source_line_number)
    else begin
      s := preserve_solution(s);
      parent^.cp_chosen_solution := s;
      tree^.kind := gen_tree_node;
    end;
  end;
end;

{ pass_1_cse_parent_bits_known - the bits_known of the solution chosen for
  the CSE whose parent is node.  0x0BA918, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.l (32). }

function pass_1_cse_parent_bits_known(
    node: isc_node_ptr_t): integer32; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_bits_known: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_bits_known := 0;
  end
  else
    pass_1_cse_parent_bits_known := s^.bits_known;
end;

{ pass_1_cse_parent_bits_trusted - the bits_trusted of the solution chosen
  for the CSE whose parent is node.  0x0BA9AC, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.l (36). }

function pass_1_cse_parent_bits_trusted(
    node: isc_node_ptr_t): integer32; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_bits_trusted: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_bits_trusted := 0;
  end
  else
    pass_1_cse_parent_bits_trusted := s^.bits_trusted;
end;

{ pass_1_cse_parent_code_bytes - the code_bytes of the solution chosen for
  the CSE whose parent is node.  0x0BAA42, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (92). }

function pass_1_cse_parent_code_bytes(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_code_bytes: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_code_bytes := 0;
  end
  else
    pass_1_cse_parent_code_bytes := s^.code_bytes;
end;

{ pass_1_cse_parent_delay - the delay of the solution chosen for the CSE
  whose parent is node.  0x0BAAD8, 0x34 bytes: node 8; chosen_solution
  (+24) nil: bug_check and 0; else move.w (94). }

function pass_1_cse_parent_delay(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_delay: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_delay := 0;
  end
  else
    pass_1_cse_parent_delay := s^.delay;
end;

{ pass_1_cse_parent_disp - the disp of the solution chosen for the CSE
  whose parent is node.  0x0BAB68, 0x34 bytes: node 8; chosen_solution
  (+24) nil: bug_check and 0; else move.l (48). }

function pass_1_cse_parent_disp(
    node: isc_node_ptr_t): integer32; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_disp: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_disp := 0;
  end
  else
    pass_1_cse_parent_disp := s^.literal_32_bits_value;
end;

{ pass_1_cse_parent_embedded_sr_temp - the embedded_sr_temp of the
  solution chosen for the CSE whose parent is node.  0x0BABF6, 0x38 bytes:
  node 8; chosen_solution (+24) nil: bug_check and false; else btst
  #1,(81). }

function pass_1_cse_parent_embedded_sr_temp(
    node: isc_node_ptr_t): boolean; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_embedded_sr_temp: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_embedded_sr_temp := false;
  end
  else
    pass_1_cse_parent_embedded_sr_temp := s^.f76.embedded_strength_reduction_temporary;
end;

{ pass_1_cse_parent_eval_order - the eval_order of the solution chosen for
  the CSE whose parent is node.  0x0BAC94, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (96). }

function pass_1_cse_parent_eval_order(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_eval_order: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_eval_order := 0;
  end
  else
    pass_1_cse_parent_eval_order := s^.evaluation_order;
end;

{ pass_1_cse_parent_lit_value - the lit_value of the solution chosen for
  the CSE whose parent is node.  0x0BAD28, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.l (48), the disp
  field. }

function pass_1_cse_parent_lit_value(
    node: isc_node_ptr_t): integer32; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_lit_value: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_lit_value := 0;
  end
  else
    pass_1_cse_parent_lit_value := s^.literal_32_bits_value;
end;

{ pass_1_cse_parent_ip_reg_max - the ip_reg_max of the solution chosen for
  the CSE whose parent is node.  0x0BADBC, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (70). }

function pass_1_cse_parent_ip_reg_max(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_ip_reg_max: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_ip_reg_max := 0;
  end
  else
    pass_1_cse_parent_ip_reg_max := s^.ip_reg_max;
end;

{ pass_1_cse_parent_ip_reg_result - the ip_reg_result of the solution
  chosen for the CSE whose parent is node.  0x0BAE50, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (72). }

function pass_1_cse_parent_ip_reg_result(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_ip_reg_result: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_ip_reg_result := 0;
  end
  else
    pass_1_cse_parent_ip_reg_result := s^.ip_reg_result;
end;

{ pass_1_cse_parent_fp_reg_max - the fp_reg_max of the solution chosen for
  the CSE whose parent is node.  0x0BAEE8, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (58). }

function pass_1_cse_parent_fp_reg_max(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_fp_reg_max: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_fp_reg_max := 0;
  end
  else
    pass_1_cse_parent_fp_reg_max := s^.fp_reg_max;
end;

{ pass_1_cse_parent_fp_reg_result - the fp_reg_result of the solution
  chosen for the CSE whose parent is node.  0x0BAF7C, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (60). }

function pass_1_cse_parent_fp_reg_result(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_fp_reg_result: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_fp_reg_result := 0;
  end
  else
    pass_1_cse_parent_fp_reg_result := s^.fp_reg_result;
end;

{ pass_1_cse_parent_fp_reg_pair_max - the fp_reg_pair_max of the solution
  chosen for the CSE whose parent is node.  0x0BB014, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (62). }

function pass_1_cse_parent_fp_reg_pair_max(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_fp_reg_pair_max: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_fp_reg_pair_max := 0;
  end
  else
    pass_1_cse_parent_fp_reg_pair_max := s^.fp_reg_pair_max;
end;

{ pass_1_cse_parent_fp_reg_pair_result - the fp_reg_pair_result of the
  solution chosen for the CSE whose parent is node.  0x0BB0AE, 0x34 bytes:
  node 8; chosen_solution (+24) nil: bug_check and 0; else move.w (64). }

function pass_1_cse_parent_fp_reg_pair_result(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_fp_reg_pair_result: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_fp_reg_pair_result := 0;
  end
  else
    pass_1_cse_parent_fp_reg_pair_result := s^.fp_reg_pair_result;
end;

{ pass_1_cse_parent_fp_reg_quad_max - the fp_reg_quad_max of the solution
  chosen for the CSE whose parent is node.  0x0BB14C, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (66). }

function pass_1_cse_parent_fp_reg_quad_max(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_fp_reg_quad_max: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_fp_reg_quad_max := 0;
  end
  else
    pass_1_cse_parent_fp_reg_quad_max := s^.fp_reg_quad_max;
end;

{ pass_1_cse_parent_fp_reg_quad_result - the fp_reg_quad_result of the
  solution chosen for the CSE whose parent is node.  0x0BB1E6, 0x34 bytes:
  node 8; chosen_solution (+24) nil: bug_check and 0; else move.w (68). }

function pass_1_cse_parent_fp_reg_quad_result(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_fp_reg_quad_result: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_fp_reg_quad_result := 0;
  end
  else
    pass_1_cse_parent_fp_reg_quad_result := s^.fp_reg_quad_result;
end;

{ pass_1_cse_parent_memory_refs - the memory_refs of the solution chosen
  for the CSE whose parent is node.  0x0BB284, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and 0; else move.w (110). }

function pass_1_cse_parent_memory_refs(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_memory_refs: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_memory_refs := 0;
  end
  else
    pass_1_cse_parent_memory_refs := s^.memory_references;
end;

{ pass_1_cse_parent_has_sym_disp - the has_sym_disp of the solution chosen
  for the CSE whose parent is node.  0x0BB31A, 0x36 bytes: node 8;
  chosen_solution (+24) nil: bug_check and false; else tst.b (82); smi. }

function pass_1_cse_parent_has_sym_disp(
    node: isc_node_ptr_t): boolean; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_has_sym_disp: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_has_sym_disp := false;
  end
  else
    pass_1_cse_parent_has_sym_disp := s^.f76.has_a_symbolic_displacement;
end;

{ pass_1_cse_parent_uses_disp - the uses_disp of the solution chosen for
  the CSE whose parent is node.  0x0BB3B2, 0x38 bytes: node 8;
  chosen_solution (+24) nil: bug_check and false; else btst #6,(84). }

function pass_1_cse_parent_uses_disp(
    node: isc_node_ptr_t): boolean; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_uses_disp: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_uses_disp := false;
  end
  else
    pass_1_cse_parent_uses_disp := s^.f76.uses_the_displacement;
end;

{ pass_1_cse_parent_uses_index_reg - the uses_index_reg of the solution
  chosen for the CSE whose parent is node.  0x0BB44C, 0x38 bytes: node 8;
  chosen_solution (+24) nil: bug_check and false; else btst #5,(84). }

function pass_1_cse_parent_uses_index_reg(
    node: isc_node_ptr_t): boolean; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_parent_uses_index_reg: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_parent_uses_index_reg := false;
  end
  else
    pass_1_cse_parent_uses_index_reg := s^.f76.uses_the_index_register;
end;

{ pass_1_cse_use_ob - pass 1 of a CSE's tree reached through the use
  node under inh: as pass_1_cse_parent_ob, the solution kept in use's
  parent.

  0x0BB4E8, 0x104 bytes: use 8, tree 12, inh 16; pass_1_cse_parent_
  ob's code, the parent mapped (map_cse_use_ob_to_cse_parent_ob)
  before preserve_solution. }

procedure pass_1_cse_use_ob(
    use: isc_node_ptr_t;
    tree: isc_node_ptr_t;
    inh: inherited_attributes_ptr_t); options(val_param);
var
  inh2: inherited_attributes_ptr_t;
  sols: solution_list_ptr_t;
  s: isc_solution_ptr_t;
  parent: isc_node_ptr_t;
begin
  if tree^.kind <> gen_tree_node then begin
    inh2 := new_inherited_attributes(isc_heap, tree);
    inh2^ := inh^;
    inh2^.f38.required_arithmetic := ord(arithmetic_from_il_node(tree));
    inh2^.required_precision := precision_from_il_node(tree);
    inh2^.fetch_precision := precision_from_il_node(tree);
    inh2^.exception_frame := tree^.tr_top^.st_top;
    inh2^.pos.source_line_number := tree^.tr_top^.st_line;
    inh2^.pos.stmt_number := rshft(tree^.tr_top^.st_l42 & 16#FFFF00, 8);
    inh2^.f38.immediate_parent_wants_lvalue := false;
    inh2^.f38.inside_a_cse := true;
    sols := pass_1(tree, inh2, 0,
        [solution$address_mode, solution$fp_reg, solution$fp_reg_pair,
         solution$fp_reg_quad, solution$ip_reg, solution$literal_32_bits]);
    s := choose_one_cse_solution(sols);
    if s = nil then
      bug_check('ISC: source line %wd: pass_1_cse_use_ob: chosen_solution is nil, meaning cse has not yet been coded.%$',
          inh^.pos.source_line_number)
    else begin
      parent := map_cse_use_ob_to_cse_parent_ob(use);
      s := preserve_solution(s);
      parent^.cp_chosen_solution := s;
      tree^.kind := gen_tree_node;
    end;
  end;
end;

{ pass_1_cse_use_bits_known - the bits_known of the solution chosen for
  the CSE of node (a use, or its parent).  0x0BB652, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_bits_known. }

function pass_1_cse_use_bits_known(
    node: isc_node_ptr_t): integer32; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_bits_known: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_bits_known := 0;
  end
  else
    pass_1_cse_use_bits_known := s^.bits_known;
end;

{ pass_1_cse_use_bits_trusted - the bits_trusted of the solution chosen
  for the CSE of node (a use, or its parent).  0x0BB6FC, 0x4C bytes: node
  8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_bits_trusted. }

function pass_1_cse_use_bits_trusted(
    node: isc_node_ptr_t): integer32; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_bits_trusted: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_bits_trusted := 0;
  end
  else
    pass_1_cse_use_bits_trusted := s^.bits_trusted;
end;

{ pass_1_cse_use_code_bytes - the code_bytes of the solution chosen for
  the CSE of node (a use, or its parent).  0x0BB7A8, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_code_bytes. }

function pass_1_cse_use_code_bytes(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_code_bytes: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_code_bytes := 0;
  end
  else
    pass_1_cse_use_code_bytes := s^.code_bytes;
end;

{ pass_1_cse_use_delay - the delay of the solution chosen for the CSE of
  node (a use, or its parent).  0x0BB852, 0x4C bytes: node 8, mapped to
  its parent when its kind is 189; then as pass_1_cse_parent_delay. }

function pass_1_cse_use_delay(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_delay: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_delay := 0;
  end
  else
    pass_1_cse_use_delay := s^.delay;
end;

{ pass_1_cse_use_disp - the disp of the solution chosen for the CSE of
  node (a use, or its parent).  0x0BB8F8, 0x4C bytes: node 8, mapped to
  its parent when its kind is 189; then as pass_1_cse_parent_disp. }

function pass_1_cse_use_disp(
    node: isc_node_ptr_t): integer32; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_disp: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_disp := 0;
  end
  else
    pass_1_cse_use_disp := s^.literal_32_bits_value;
end;

{ pass_1_cse_use_embedded_sr_temp - the embedded_sr_temp of the solution
  chosen for the CSE of node (a use, or its parent).  0x0BB99C, 0x50
  bytes: node 8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_embedded_sr_temp. }

function pass_1_cse_use_embedded_sr_temp(
    node: isc_node_ptr_t): boolean; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_embedded_sr_temp: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_embedded_sr_temp := false;
  end
  else
    pass_1_cse_use_embedded_sr_temp := s^.f76.embedded_strength_reduction_temporary;
end;

{ pass_1_cse_use_eval_order - the eval_order of the solution chosen for
  the CSE of node (a use, or its parent).  0x0BBA50, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_eval_order. }

function pass_1_cse_use_eval_order(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_eval_order: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_eval_order := 0;
  end
  else
    pass_1_cse_use_eval_order := s^.evaluation_order;
end;

{ pass_1_cse_use_lit_value - the lit_value of the solution chosen for the
  CSE of node (a use, or its parent).  0x0BBAFA, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_lit_value. }

function pass_1_cse_use_lit_value(
    node: isc_node_ptr_t): integer32; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_lit_value: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_lit_value := 0;
  end
  else
    pass_1_cse_use_lit_value := s^.literal_32_bits_value;
end;

{ pass_1_cse_use_ip_reg_max - the ip_reg_max of the solution chosen for
  the CSE of node (a use, or its parent).  0x0BBBA4, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_ip_reg_max. }

function pass_1_cse_use_ip_reg_max(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_ip_reg_max: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_ip_reg_max := 0;
  end
  else
    pass_1_cse_use_ip_reg_max := s^.ip_reg_max;
end;

{ pass_1_cse_use_ip_reg_result - the ip_reg_result of the solution chosen
  for the CSE of node (a use, or its parent).  0x0BBC4E, 0x4C bytes: node
  8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_ip_reg_result. }

function pass_1_cse_use_ip_reg_result(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_ip_reg_result: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_ip_reg_result := 0;
  end
  else
    pass_1_cse_use_ip_reg_result := s^.ip_reg_result;
end;

{ pass_1_cse_use_fp_reg_max - the fp_reg_max of the solution chosen for
  the CSE of node (a use, or its parent).  0x0BBCFC, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_fp_reg_max. }

function pass_1_cse_use_fp_reg_max(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_fp_reg_max: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_fp_reg_max := 0;
  end
  else
    pass_1_cse_use_fp_reg_max := s^.fp_reg_max;
end;

{ pass_1_cse_use_fp_reg_result - the fp_reg_result of the solution chosen
  for the CSE of node (a use, or its parent).  0x0BBDA6, 0x4C bytes: node
  8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_fp_reg_result. }

function pass_1_cse_use_fp_reg_result(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_fp_reg_result: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_fp_reg_result := 0;
  end
  else
    pass_1_cse_use_fp_reg_result := s^.fp_reg_result;
end;

{ pass_1_cse_use_fp_reg_pair_max - the fp_reg_pair_max of the solution
  chosen for the CSE of node (a use, or its parent).  0x0BBE54, 0x4C
  bytes: node 8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_fp_reg_pair_max. }

function pass_1_cse_use_fp_reg_pair_max(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_fp_reg_pair_max: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_fp_reg_pair_max := 0;
  end
  else
    pass_1_cse_use_fp_reg_pair_max := s^.fp_reg_pair_max;
end;

{ pass_1_cse_use_fp_reg_pair_result - the fp_reg_pair_result of the
  solution chosen for the CSE of node (a use, or its parent).  0x0BBF02,
  0x4C bytes: node 8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_fp_reg_pair_result. }

function pass_1_cse_use_fp_reg_pair_result(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_fp_reg_pair_result: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_fp_reg_pair_result := 0;
  end
  else
    pass_1_cse_use_fp_reg_pair_result := s^.fp_reg_pair_result;
end;

{ pass_1_cse_use_fp_reg_quad_max - the fp_reg_quad_max of the solution
  chosen for the CSE of node (a use, or its parent).  0x0BBFB4, 0x4C
  bytes: node 8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_fp_reg_quad_max. }

function pass_1_cse_use_fp_reg_quad_max(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_fp_reg_quad_max: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_fp_reg_quad_max := 0;
  end
  else
    pass_1_cse_use_fp_reg_quad_max := s^.fp_reg_quad_max;
end;

{ pass_1_cse_use_fp_reg_quad_result - the fp_reg_quad_result of the
  solution chosen for the CSE of node (a use, or its parent).  0x0BC062,
  0x4C bytes: node 8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_fp_reg_quad_result. }

function pass_1_cse_use_fp_reg_quad_result(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_fp_reg_quad_result: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_fp_reg_quad_result := 0;
  end
  else
    pass_1_cse_use_fp_reg_quad_result := s^.fp_reg_quad_result;
end;

{ pass_1_cse_use_memory_refs - the memory_refs of the solution chosen for
  the CSE of node (a use, or its parent).  0x0BC114, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_memory_refs. }

function pass_1_cse_use_memory_refs(
    node: isc_node_ptr_t): integer; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_memory_refs: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_memory_refs := 0;
  end
  else
    pass_1_cse_use_memory_refs := s^.memory_references;
end;

{ pass_1_cse_use_has_sym_disp - the has_sym_disp of the solution chosen
  for the CSE of node (a use, or its parent).  0x0BC1BE, 0x4E bytes: node
  8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_has_sym_disp. }

function pass_1_cse_use_has_sym_disp(
    node: isc_node_ptr_t): boolean; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_has_sym_disp: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_has_sym_disp := false;
  end
  else
    pass_1_cse_use_has_sym_disp := s^.f76.has_a_symbolic_displacement;
end;

{ pass_1_cse_use_uses_disp - the uses_disp of the solution chosen for the
  CSE of node (a use, or its parent).  0x0BC26C, 0x50 bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_uses_disp. }

function pass_1_cse_use_uses_disp(
    node: isc_node_ptr_t): boolean; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_uses_disp: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_uses_disp := false;
  end
  else
    pass_1_cse_use_uses_disp := s^.f76.uses_the_displacement;
end;

{ pass_1_cse_use_uses_index_reg - the uses_index_reg of the solution
  chosen for the CSE of node (a use, or its parent).  0x0BC318, 0x50
  bytes: node 8, mapped to its parent when its kind is 189; then as
  pass_1_cse_parent_uses_index_reg. }

function pass_1_cse_use_uses_index_reg(
    node: isc_node_ptr_t): boolean; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_1_cse_use_uses_index_reg: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_1_cse_use_uses_index_reg := false;
  end
  else
    pass_1_cse_use_uses_index_reg := s^.f76.uses_the_index_register;
end;

{ pass_2_cse_parent_base_reg - the base_reg of the solution chosen for the
  CSE whose parent is node.  0x0BC3CA, 0x34 bytes: node 8; chosen_solution
  (+24) nil: bug_check and nil; else movea.l (4). }

function pass_2_cse_parent_base_reg(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_parent_base_reg: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_2_cse_parent_base_reg := nil;
  end
  else
    pass_2_cse_parent_base_reg := s^.base_register;
end;

{ pass_2_cse_parent_index_reg - the index_reg of the solution chosen for
  the CSE whose parent is node.  0x0BC45C, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and nil; else movea.l (8). }

function pass_2_cse_parent_index_reg(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_parent_index_reg: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_2_cse_parent_index_reg := nil;
  end
  else
    pass_2_cse_parent_index_reg := s^.index_register;
end;

{ pass_2_cse_parent_obj_w_name - the obj_w_name of the solution chosen for
  the CSE whose parent is node.  0x0BC4F0, 0x32 bytes: node 8;
  chosen_solution (+24) nil: bug_check and nil; else movea.l (A0). }

function pass_2_cse_parent_obj_w_name(
    node: isc_node_ptr_t): univ_ptr; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_parent_obj_w_name: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_2_cse_parent_obj_w_name := nil;
  end
  else
    pass_2_cse_parent_obj_w_name := s^.object_with_name;
end;

{ pass_2_cse_parent_home_solution - the home_solution of the solution
  chosen for the CSE whose parent is node.  0x0BC584, 0x2E bytes: node 8;
  chosen_solution (+24) nil: bug_check and nil; else the solution itself.
  }

function pass_2_cse_parent_home_solution(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_parent_home_solution: chosen_solution is nil, meaning cse has not yet been coded.%$');
    s := nil;
  end;
  pass_2_cse_parent_home_solution := s;
end;

{ pass_2_cse_parent_live_range - the live_range of the solution chosen for
  the CSE whose parent is node.  0x0BC618, 0x34 bytes: node 8;
  chosen_solution (+24) nil: bug_check and nil; else movea.l (20). }

function pass_2_cse_parent_live_range(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_parent_live_range: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_2_cse_parent_live_range := nil;
  end
  else
    pass_2_cse_parent_live_range := s^.live_range;
end;

{ pass_2_cse_parent_ob - pass 2 of the CSE whose parent is parent, in the statement of
  index stmt.  In the tree's own statement and not yet
  done: pass 2 over the chosen solution (home), its live range marked
  isc_is_cse, home printed when either ISC trace is on; if home already
  had a live range (a use was generated first), the value is then
  moved from the new live range to that one (a copy of home holding
  the old live range; the move by home's kind: opc$none for an address
  mode, copys, copyd, move; bug_check for another kind, the move then
  made with an unset opcode).  In another statement a home without a
  live range is given a new one of its kind (nothing for an address
  mode).

  0x0BC6AC, 0x344 bytes: parent 8, stmt a word at 12; the tree's statement index
  `and.l #16#FFFF00; lsr.l #8' against stmt (`cmp.w'); already_through_pass_2
  `btst #3,(115)'; the old live range in a register; isc_is_cse
  `bset #7,(10)'; the copy in A4; the opcode in a frame word (the case
  `sub.w #5' and a table of 7); debug_lir_$simple_instruction(home's
  inherited attributes, opc, 0, home, copy, nil).

  Not known from the original: whether the unset opcode after the bug
  check was meant (the image's). }

procedure pass_2_cse_parent_ob(
    parent: isc_node_ptr_t;
    stmt: integer); options(val_param);
var
  home: isc_solution_ptr_t;
  old: lr_ptr_t;
  copy: isc_solution_ptr_t;
  opc: integer;
begin
  home := parent^.cp_chosen_solution;
  if rshft(parent^.cp_tree^.tr_top^.st_l42 & 16#FFFF00, 8) = stmt then begin
    if not home^.f114.already_through_pass_2 then begin
      old := home^.live_range;
      if old <> nil then begin
        pass_2(home, 0);
        if home^.live_range <> nil then
          isc_lr_ptr_t(home^.live_range)^.f10.isc_is_cse := true;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          writeln('pass_2_cse_parent_ob:');
          writeln;
          writeln('Chosen solution after pass 2:');
          writeln;
          dump_solution(home, 0, true);
          writeln;
        end;
        copy := duplicate_solution(isc_heap, home);
        copy^.live_range := old;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          writeln('pass_2_cse_parent_ob:');
          writeln;
          writeln('This cse was used before it was defined.');
          writeln('Move the cse value from the live_range where it was defined,');
          writeln('to the live_range where the previous use expected it to be.');
          writeln;
        end;
        case home^.kind of
          solution$address_mode: opc := ord(opc$none);
          solution$fp_reg: opc := ord(opc$copys);
          solution$fp_reg_pair: opc := ord(opc$copyd);
          solution$ip_reg: opc := ord(opc$move);
          otherwise
            bug_check('ISC: pass_2_cse_parent_ob: unknown home_solution^.kind.%$');
        end;
        debug_lir_$simple_instruction(home^.inherited_attributes, opc, 0, home, copy, nil);
      end
      else begin
        pass_2(home, 0);
        if home^.live_range <> nil then
          isc_lr_ptr_t(home^.live_range)^.f10.isc_is_cse := true;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          writeln('pass_2_cse_parent_ob:');
          writeln;
          writeln('Chosen solution after pass 2:');
          writeln;
          dump_solution(home, 0, true);
          writeln;
        end;
      end;
    end;
  end
  else if home^.live_range = nil then
    case home^.kind of
      solution$address_mode: ;
      solution$fp_reg: home^.live_range := lir_$new_live_range_fp_reg;
      solution$fp_reg_pair: home^.live_range := lir_$new_live_range_fp_reg_pair;
      solution$ip_reg: home^.live_range := lir_$new_live_range_ip_reg;
      otherwise
        bug_check('ISC: pass_2_cse_parent_ob: unknown home_solution^.kind.%$');
    end;
end;

{ pass_2_cse_use_base_reg - the base_reg of the solution chosen for the
  CSE of node (a use, or its parent).  0x0BCAFE, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_2_cse_parent_base_reg. }

function pass_2_cse_use_base_reg(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_use_base_reg: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_2_cse_use_base_reg := nil;
  end
  else
    pass_2_cse_use_base_reg := s^.base_register;
end;

{ pass_2_cse_use_index_reg - the index_reg of the solution chosen for the
  CSE of node (a use, or its parent).  0x0BCBA6, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_2_cse_parent_index_reg. }

function pass_2_cse_use_index_reg(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_use_index_reg: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_2_cse_use_index_reg := nil;
  end
  else
    pass_2_cse_use_index_reg := s^.index_register;
end;

{ pass_2_cse_use_obj_w_name - the obj_w_name of the solution chosen for
  the CSE of node (a use, or its parent).  0x0BCC4E, 0x4A bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_2_cse_parent_obj_w_name. }

function pass_2_cse_use_obj_w_name(
    node: isc_node_ptr_t): univ_ptr; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_use_obj_w_name: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_2_cse_use_obj_w_name := nil;
  end
  else
    pass_2_cse_use_obj_w_name := s^.object_with_name;
end;

{ pass_2_cse_use_home_solution - the home_solution of the solution chosen
  for the CSE of node (a use, or its parent).  0x0BCCF6, 0x46 bytes: node
  8, mapped to its parent when its kind is 189; then as
  pass_2_cse_parent_home_solution. }

function pass_2_cse_use_home_solution(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_use_home_solution: chosen_solution is nil, meaning cse has not yet been coded.%$');
    s := nil;
  end;
  pass_2_cse_use_home_solution := s;
end;

{ pass_2_cse_use_live_range - the live_range of the solution chosen for
  the CSE of node (a use, or its parent).  0x0BCD9C, 0x4C bytes: node 8,
  mapped to its parent when its kind is 189; then as
  pass_2_cse_parent_live_range. }

function pass_2_cse_use_live_range(
    node: isc_node_ptr_t): lr_ptr_t; options(val_param);
var
  s: isc_solution_ptr_t;
begin
  if node^.kind = cse_use_ob then
    node := map_cse_use_ob_to_cse_parent_ob(node);
  s := node^.cp_chosen_solution;
  if s = nil then begin
    bug_check('ISC: pass_2_cse_use_live_range: chosen_solution is nil, meaning cse has not yet been coded.%$');
    pass_2_cse_use_live_range := nil;
  end
  else
    pass_2_cse_use_live_range := s^.live_range;
end;

{ pass_2_cse_use_ob - pass 2 of the CSE of the use node use, in the statement of
  index stmt (the statement of the tree it is used in).  In the tree's own statement and not yet
  done: pass 2 over the chosen solution (home), its live range marked
  isc_is_cse, home printed when either ISC trace is on; if home already
  had a live range (a use was generated first), the value is then
  moved from the new live range to that one (a copy of home holding
  the old live range; the move by home's kind: opc$none for an address
  mode, copys, copyd, move; bug_check for another kind, the move then
  made with an unset opcode).  In another statement a home without a
  live range is given a new one of its kind (nothing for an address
  mode).

  0x0BCE46, 0x34E bytes: use 8, stmt a word at 12; the tree's statement index
  `and.l #16#FFFF00; lsr.l #8' against stmt (`cmp.w'); already_through_pass_2
  `btst #3,(115)'; the old live range in a register; isc_is_cse
  `bset #7,(10)'; the copy in A4; the opcode in a frame word (the case
  `sub.w #5' and a table of 7); debug_lir_$simple_instruction(home's
  inherited attributes, opc, 0, home, copy, nil).

  Not known from the original: whether the unset opcode after the bug
  check was meant (the image's). }

procedure pass_2_cse_use_ob(
    use: isc_node_ptr_t;
    stmt: integer); options(val_param);
var
  home: isc_solution_ptr_t;
  old: lr_ptr_t;
  copy: isc_solution_ptr_t;
  opc: integer;
begin
  home := map_cse_use_ob_to_cse_parent_ob(use)^.cp_chosen_solution;
  if rshft(use^.cu_tree^.tr_top^.st_l42 & 16#FFFF00, 8) = stmt then begin
    if not home^.f114.already_through_pass_2 then begin
      old := home^.live_range;
      if old <> nil then begin
        pass_2(home, 0);
        if home^.live_range <> nil then
          isc_lr_ptr_t(home^.live_range)^.f10.isc_is_cse := true;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          writeln('pass_2_cse_use_ob:');
          writeln;
          writeln('Chosen solution after pass 2:');
          writeln;
          dump_solution(home, 0, true);
          writeln;
        end;
        copy := duplicate_solution(isc_heap, home);
        copy^.live_range := old;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          writeln('pass_2_cse_use_ob:');
          writeln;
          writeln('This cse was used before it was defined.');
          writeln('Move the cse value from the live_range where it was defined,');
          writeln('to the live_range where the previous use expected it to be.');
          writeln;
        end;
        case home^.kind of
          solution$address_mode: opc := ord(opc$none);
          solution$fp_reg: opc := ord(opc$copys);
          solution$fp_reg_pair: opc := ord(opc$copyd);
          solution$ip_reg: opc := ord(opc$move);
          otherwise
            bug_check('ISC: pass_2_cse_use_ob: unknown home_solution^.kind.%$');
        end;
        debug_lir_$simple_instruction(home^.inherited_attributes, opc, 0, home, copy, nil);
      end
      else begin
        pass_2(home, 0);
        if home^.live_range <> nil then
          isc_lr_ptr_t(home^.live_range)^.f10.isc_is_cse := true;
        if isc_user_routines_356 or isc_user_routines_354 then begin
          writeln('pass_2_cse_use_ob:');
          writeln;
          writeln('Chosen solution after pass 2:');
          writeln;
          dump_solution(home, 0, true);
          writeln;
        end;
      end;
    end;
  end
  else if home^.live_range = nil then
    case home^.kind of
      solution$address_mode: ;
      solution$fp_reg: home^.live_range := lir_$new_live_range_fp_reg;
      solution$fp_reg_pair: home^.live_range := lir_$new_live_range_fp_reg_pair;
      solution$ip_reg: home^.live_range := lir_$new_live_range_ip_reg;
      otherwise
        bug_check('ISC: pass_2_cse_use_ob: unknown home_solution^.kind.%$');
    end;
end;
