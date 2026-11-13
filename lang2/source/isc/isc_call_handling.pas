{ isc_call_handling - the ISC's calls: pass 1 and pass 2 of a call tree
  (ISC_CALL, ISC_FUNC_CALL, ISC_FUNC_CALL_HIDDEN_TEMP), which the
  generated pattern actions for those operators hand over to.  Pass 1
  begins the LIR call (debug_lir_$begin_call_or_svc, with the number of
  argument registers and slots) and finds the solutions of the inputs,
  the routine, the hidden temporary and the outputs, keeping them in
  the call node; pass 2 runs pass 2 over them in order and emits the
  call between the inputs and the outputs.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x0B9F24  get_slevel
    --------  0x0B9F56  number_of_inputs
    --------  0x0B9FAE  number_of_outputs
    --------  0x0BA006  pass_1_isc_call
    --------  0x0BA2E0  pass_1_isc_call_addr_of_temp
    --------  0x0BA2FC  pass_2_isc_call
  A5 0x44E7F8: the module has no data of its own (every routine loads
  A5; PAS_$WRITE's file is at (-4,A5)).

  The writes are dpc gap 4 (docs/dpc-gaps.md 4).

  Not known from the original: the parameters' and locals' names. }
module isc_call_handling;

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

{ get_slevel - a routine's nesting level (0 for a node that is not a
  procedure or function block).

  0x0B9F24, 0x32 bytes: the kind compared with 107 and 108; the level a
  byte at +294 (`move.b (294,A0); ext.w'). }

function get_slevel(
    node: isc_node_ptr_t): integer; options(val_param);
begin
  if (node^.kind = procedure_blk) or (node^.kind = function_blk) then
    get_slevel := node^.bk_f294.slevel
  else
    get_slevel := 0;
end;

{ number_of_inputs - the argument registers and slots of a call's
  arguments, the chain from arg: one for each slot (204) or register
  (203), and one more for a register pair (class 2) or three more for
  a quad (class 3).

  0x0B9F56, 0x58 bytes: the count in D0; the chain through +8, each
  argument's location at +64. }

function number_of_inputs(
    arg: isc_node_ptr_t): integer32; options(val_param);
var
  n: integer32;
  loc: isc_node_ptr_t;
begin
  n := 0;
  while arg <> nil do begin
    loc := arg^.ar_loc;
    if loc^.kind = argument_block_location_ob then
      n := n + 1
    else if loc^.kind = physical_register_ob then begin
      n := n + 1;
      if loc^.lo_class = 2 then
        n := n + 1
      else if loc^.lo_class = 3 then
        n := n + 3;
    end;
    arg := arg^.ar_next;
  end;
  number_of_inputs := n;
end;

{ number_of_outputs - as number_of_inputs, for the outputs' chain.

  0x0B9FAE, 0x58 bytes: number_of_inputs' code. }

function number_of_outputs(
    arg: isc_node_ptr_t): integer32; options(val_param);
var
  n: integer32;
  loc: isc_node_ptr_t;
begin
  n := 0;
  while arg <> nil do begin
    loc := arg^.ar_loc;
    if loc^.kind = argument_block_location_ob then
      n := n + 1
    else if loc^.kind = physical_register_ob then begin
      n := n + 1;
      if loc^.lo_class = 2 then
        n := n + 1
      else if loc^.lo_class = 3 then
        n := n + 3;
    end;
    arg := arg^.ar_next;
  end;
  number_of_outputs := n;
end;

{ pass_1_isc_call - pass 1 of the call tree node under inh (once: the
  call is begun only when node has none yet): the LIR call of
  opc$call with the argument registers and slots (and, for an
  ISC_FUNC_CALL, the result's: 4 for a result class of 3, 2 for 2, 1
  otherwise), requesting may_cause_non_local_return when the callee is
  nested deeper than the routine being compiled and that routine's
  attribute bit 6 is set; then the inputs' solutions, the routine's
  (a local routine, an address mode or an integer register, under
  attributes with immediate_parent_wants_lvalue set), the hidden
  temporary's (an integer register) for an ISC_FUNC_CALL_HIDDEN_TEMP,
  and the outputs'; each under new attributes carrying the call, inh's
  exception_frame, original_il, pos and inside_a_cse, and preserved
  when inh asks.

  0x0BA006, 0x2DA bytes: node 8, rclass a word at 12, inh 14, depth a
  word at 18 (the generated actions pass 4 and 0); `tst.l (76,A0); bne'
  to the end; the level against il_180's byte at +294 (`ble'), its
  +376 bit 6; the operator against 31 (`clrl D3' otherwise); the counts
  added (`add.l D3,D0', `add.l (-32,A6),D0'); each permissible set
  stored in (-4,A6) (16#830, 16#800) and pushed with the depth plus one
  (kept in D3 for the temporary); preserve tested as `btst #2,(39,A3)'
  before each preserve call.

  Not known from the original: rclass's meaning (the generated callers
  pass 4). }

procedure pass_1_isc_call(
    node: isc_node_ptr_t;
    rclass: integer;
    inh: inherited_attributes_ptr_t;
    depth: integer); options(val_param);
var
  n: integer32;
  extra: integer32;
  nonlocal: integer32;
  call: univ_ptr;
  inh2: inherited_attributes_ptr_t;
  list: solution_list_ptr_t;
  sols: solution_list_ptr_t;
  sol: isc_solution_ptr_t;
  permissible: solution$set_t;
  depth1: integer;
begin
  if node^.cl_call = nil then begin
    if (get_slevel(node^.cl_routine) > isc_node_ptr_t(il_180)^.bk_f294.slevel)
       and isc_node_ptr_t(il_180)^.bk_atts.nlgoto then
      nonlocal := request$may_cause_non_local_return
    else
      nonlocal := 0;
    if node^.tr_op = isc_func_call_top then begin
      if rclass = 3 then
        extra := 4
      else if rclass = 2 then
        extra := 2
      else
        extra := 1;
    end
    else
      extra := 0;
    n := number_of_inputs(node^.cl_inputs) + extra;
    n := n + number_of_outputs(node^.cl_outputs);
    call := debug_lir_$begin_call_or_svc(inh, ord(opc$call), nonlocal, n);
    node^.cl_call := call;

    { the inputs }
    inh2 := new_inherited_attributes(isc_heap, node^.cl_inputs);
    inh2^.call_instruction_ptr := call;
    inh2^.exception_frame := inh^.exception_frame;
    inh2^.f38.inside_a_cse := inh^.f38.inside_a_cse;
    inh2^.original_il := inh^.original_il;
    inh2^.pos := inh^.pos;
    list := apply_pass_1_and_choose_to_list(node^.cl_inputs, inh2);
    if inh^.f38.inside_a_cse then
      list := solution_list$preserve(list);
    node^.cl_input_solutions := list;

    { the routine }
    inh2 := new_inherited_attributes(isc_heap, node^.cl_routine);
    inh2^.call_instruction_ptr := call;
    inh2^.exception_frame := inh^.exception_frame;
    inh2^.f38.immediate_parent_wants_lvalue := true;
    inh2^.f38.inside_a_cse := inh^.f38.inside_a_cse;
    inh2^.original_il := inh^.original_il;
    inh2^.pos := inh^.pos;
    permissible := [solution$local_routine, solution$address_mode,
                    solution$ip_reg];
    depth1 := depth + 1;
    sols := pass_1(node^.cl_routine, inh2, depth1, permissible);
    sol := choose_one_solution(sols);
    if inh^.f38.inside_a_cse then
      sol := preserve_solution(sol);
    node^.cl_solution := sol;

    { the hidden temporary }
    if node^.tr_op = isc_func_call_hidden_temp_top then begin
      inh2 := new_inherited_attributes(isc_heap, node^.cl_temp);
      inh2^.call_instruction_ptr := call;
      inh2^.exception_frame := inh^.exception_frame;
      inh2^.f38.inside_a_cse := inh^.f38.inside_a_cse;
      inh2^.original_il := inh^.original_il;
      inh2^.pos := inh^.pos;
      permissible := [solution$ip_reg];
      sols := pass_1(node^.cl_temp, inh2, depth1, permissible);
      sol := choose_one_solution(sols);
      if inh^.f38.inside_a_cse then
        sol := preserve_solution(sol);
      node^.cl_temp_solution := sol;
    end;

    { the outputs }
    inh2 := new_inherited_attributes(isc_heap, node^.cl_outputs);
    inh2^.call_instruction_ptr := call;
    inh2^.exception_frame := inh^.exception_frame;
    inh2^.f38.inside_a_cse := inh^.f38.inside_a_cse;
    inh2^.original_il := inh^.original_il;
    inh2^.pos := inh^.pos;
    list := apply_pass_1_and_choose_to_list(node^.cl_outputs, inh2);
    if inh^.f38.inside_a_cse then
      list := solution_list$preserve(list);
    node^.cl_output_solutions := list;
  end;
end;

{ pass_1_isc_call_addr_of_temp - the hidden temporary's solution of the
  call tree node.

  0x0BA2E0, 0x1C bytes: +72 into A0. }

function pass_1_isc_call_addr_of_temp(
    node: isc_node_ptr_t): isc_solution_ptr_t; options(val_param);
begin
  pass_1_isc_call_addr_of_temp := node^.cl_temp_solution;
end;

{ pass_2_isc_call - pass 2 of the call tree node: the inputs, the
  routine (printed when either ISC trace is on), the call emitted with
  its requests (pfm_cleanup, may_cause_non_local_return as in pass 1,
  asynchronous_return, may_cause_ftn_io_return, as the flags say) and
  the return address register's solution (lir_3e60 by the node's
  opmod1), the hidden temporary (printed likewise), the outputs; then
  the call ended.

  0x0BA2FC, 0x22E bytes: node 8, async, ftn_io and pfm bytes at 12, 14,
  16 (each tested `bpl'), inh 18, depth a word at 22; the requests
  added in the order written (`add.l D0,D1; add.l D3,D1; add.l D2,D1')
  and kept in (-8,A6); the traces `move.b +0x356; or.b +0x354; bpl';
  the temporary's solution kept in (-4,A6). }

procedure pass_2_isc_call(
    node: isc_node_ptr_t;
    async: boolean;
    ftn_io: boolean;
    pfm: boolean;
    inh: inherited_attributes_ptr_t;
    depth: integer); options(val_param);
var
  r_async: integer32;
  r_ftn_io: integer32;
  r_nonlocal: integer32;
  r_pfm: integer32;
  requests: integer32;
  depth1: integer;
  temp: isc_solution_ptr_t;
begin
  if async then
    r_async := request$asynchronous_return
  else
    r_async := 0;
  if ftn_io then
    r_ftn_io := request$may_cause_ftn_io_return
  else
    r_ftn_io := 0;
  if (get_slevel(node^.cl_routine) > isc_node_ptr_t(il_180)^.bk_f294.slevel)
     and isc_node_ptr_t(il_180)^.bk_atts.nlgoto then
    r_nonlocal := request$may_cause_non_local_return
  else
    r_nonlocal := 0;
  if pfm then
    r_pfm := request$pfm_cleanup
  else
    r_pfm := 0;
  requests := r_pfm + r_nonlocal + r_async + r_ftn_io;
  apply_pass_2_to_list(node^.cl_input_solutions);
  depth1 := depth + 1;
  pass_2(node^.cl_solution, depth1);
  if isc_user_routines_356 or isc_user_routines_354 then begin
    writeln('pass_2_isc_call:');
    writeln;
    writeln('Routine descriptor after pass 2:');
    writeln;
    dump_solution(node^.cl_solution, 0, true);
    writeln;
  end;
  debug_lir_$emit_call_or_svc(inh, node, node^.cl_call, requests,
      node^.cl_solution, lir_3e60[node^.tr_opmod1]);
  if node^.tr_op = isc_func_call_hidden_temp_top then begin
    temp := node^.cl_temp_solution;
    pass_2(temp, depth1);
    if isc_user_routines_356 or isc_user_routines_354 then begin
      writeln('pass_2_isc_call:');
      writeln;
      writeln('Hidden temp after pass 2:');
      writeln;
      dump_solution(temp, 0, true);
      writeln;
    end;
  end;
  apply_pass_2_to_list(node^.cl_output_solutions);
  debug_lir_$end_call_or_svc(inh, node^.cl_call);
end;
