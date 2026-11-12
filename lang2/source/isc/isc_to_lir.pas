{ isc_to_lir - the ISC's way to the LIR: the debug_lir_ wrappers the
  pass-2 actions call instead of the lir_ instruction builders.  Each
  traces its arguments under the phase switch sw14 and, but for
  begin_call_or_svc and begin_fortran_io_sequence (called at once),
  appends a deferred call (lir_request_t, isc_solution_fields.ins.pas)
  to the current statement's list; begin_statement starts a list (one
  per statement depth: isc_user_routines +0x1CC the heads, +0x18C the
  last), end_statement first drops each preference move that only
  copies the previous instruction's result into another live range
  (giving that instruction the move's destination), then replays the
  list through the lir_ routines (unless sw11) and returns to the
  enclosing statement.  Also the phase's begin and end traces (sw3),
  requests_to_string and guarantee_has_live_range.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x2088B0  guarantee_has_live_range
    --------  0x208BB4  requests_to_string
    --------  0x209168  begin_compilation
    --------  0x20928C  end_compilation
    --------  0x20933A  begin_routine
    --------  0x2093F2  end_routine
    --------  0x20949C  begin_basic_block
    --------  0x2095D2  end_basic_block
    --------  0x2096B2  begin_statement
    --------  0x209796  end_statement
    --------  0x20B1A4  debug_lir_$begin_call_or_svc
    --------  0x20B3FA  debug_lir_$begin_fortran_io_sequence
    --------  0x20B500  debug_lir_$branch_instruction
    --------  0x20B6E8  debug_lir_$break_basic_block
    --------  0x20B824  debug_lir_$common_lhs_rhs_token
    --------  0x20B972  debug_lir_$disjoint_lhs_and_rhs_tokens
    --------  0x20BACE  debug_lir_$dispatch_instruction
    --------  0x20BCB2  debug_lir_$emit_call_or_svc
    --------  0x20BF38  debug_lir_$end_call_or_svc
    --------  0x20C0BE  debug_lir_$field_instruction
    --------  0x20C388  debug_lir_$label
    --------  0x20C4D4  debug_lir_$load_instruction
    --------  0x20C924  debug_lir_$simple_instruction
    --------  0x20CB8C  debug_lir_$store_instruction
    --------  0x20CF8E  debug_lir_$mfpr_instruction
    --------  0x20D2C2  debug_lir_$mtpr_instruction
    --------  0x20D5FC  debug_lir_$operate_and_branch_instruction
    --------  0x20D850  debug_lir_main_$entry
    --------  0x20D994  debug_lir_main_$handler_reentry
    --------  0x20DAE2  debug_lir_$pa_risc_shift_double_instruction
  A5 0x480DFC: the module has no data of its own (PAS_$WRITE's file at
  (-4,A5)); the deferred calls' tables are isc_user_routines'.

  end_statement writes an opcode with Pascal `write', so the opcodes'
  identifier table follows it in the image (0x209FEE: the source of
  opcode_enumeration.ins.pas's names); guarantee_has_live_range writes
  a solution kind (0x20898A).  The writes are dpc gap 4
  (docs/dpc-gaps.md 4): each is one line, dropped for the check.

  The lir_ headings (backend.ins.pas, batch A's) are read off frames:
  the deferred calls pass pointers as integer32 where they declare
  one.  Readings for batch A (the wrappers have the lir_ routines'
  parameters, inh first): branch (inh, label, opc, requests), dispatch
  (inh, op1, opc, requests), field (inh, opc, requests, siz, src, pos,
  dst), load (inh, opc, requests, index, base, result, tree,
  disp_off_tree, bits_known, bits_trusted), store (inh, opc, requests,
  source, index, base, tree, disp_off_tree, bits_known, bits_trusted),
  mfpr (inh, opc, requests, index, base, result, var_name), mtpr (inh,
  opc, requests, source, index, base, var_name), operate_and_branch
  (inh, opc, requests, op1, op2, target), simple (inh, opc, requests,
  op1, op2, op3[, op4]), emit_call_or_svc (inh, node, call, requests,
  routine's solution, linkage register's), end_call_or_svc (inh, call),
  disjoint_lhs_and_rhs_tokens (inh, lhs, rhs), common_lhs_rhs_token
  (inh), label (label), begin_call_or_svc (opc, requests, n).

  Not known from the original: the parameters' and locals' names (the
  traces' labels are used where they name them). }
module isc_to_lir;

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

const
  { The traces' rules (begin_compilation's and end_statement's constants,
    shared by the routines after them). }
  tl_rule = '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
  tl_bb_rule = '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
  tl_star_rule = '**************************************************************';

{ guarantee_has_live_range - a register solution without a live range
  given a new one of its kind (floating, pair, integer, an integer
  field's integer); nothing for a literal (14) or 17; the kind printed
  for any other.

  0x2088B0, 0xDA bytes: s 8; the case on the kind less 8 (a table of
  10); the kind written as solution$t (its identifier table follows,
  0x20898A). }

procedure guarantee_has_live_range(
    s: isc_solution_ptr_t); options(val_param);
begin
  if s <> nil then
    if s^.live_range = nil then
      case s^.kind of
        11, 12: s^.live_range := lir_$new_live_range_ip_reg;
        8: s^.live_range := lir_$new_live_range_fp_reg;
        9: s^.live_range := lir_$new_live_range_fp_reg_pair;
        14, 17: ;
        otherwise begin
          write('guarantee_has_live_range: unrecognized s^.kind "');
          write(solution$t(s^.kind));
          write('".');
          writeln;
        end;
      end;
end;

{ requests_to_string - the requests r listed by name between brackets
  (bits 0..24, then 27, 25, 26), on the standard output; a blank
  returned (the callers write it).

  0x208BB4, 0x3CA bytes: r 8 in D2 (`btst #k,D2', bit 7 `tst.b', bit 15
  `tst.w'); `moveq #32,D0'. }

function requests_to_string(
    r: integer32): char; options(val_param);
begin
  write('[ ');
  if (r & request$set_condition_codes) <> 0 then write('set_condition_codes ');
  if (r & request$set_signed_relational_ccs) <> 0 then write('set_signed_relational_ccs ');
  if (r & request$set_unsigned_relational_ccs) <> 0 then write('set_unsigned_relational_ccs ');
  if (r & request$set_equality_ccs) <> 0 then write('set_equality_ccs ');
  if (r & request$premodify) <> 0 then write('premodify ');
  if (r & request$postmodify) <> 0 then write('postmodify ');
  if (r & request$advancing_address_mode) <> 0 then write('advancing_address_mode ');
  if (r & request$physical) <> 0 then write('physical ');
  if (r & request$lock) <> 0 then write('lock ');
  if (r & request$unlock) <> 0 then write('unlock ');
  if (r & request$and_zero) <> 0 then write('and_zero ');
  if (r & request$inscrutable) <> 0 then write('inscrutable ');
  if (r & request$invariant) <> 0 then write('invariant ');
  if (r & request$has_alias_descriptor) <> 0 then write('has_alias_descriptor ');
  if (r & request$widen_in_place) <> 0 then write('widen_in_place ');
  if (r & request$call_or_svc_argument) <> 0 then write('call_or_svc_argument ');
  if (r & request$may_cause_non_local_return) <> 0 then write('may_cause_non_local_return ');
  if (r & request$may_cause_ftn_io_return) <> 0 then write('may_cause_ftn_io_return ');
  if (r & request$ftn_assigned_goto) <> 0 then write('ftn_assigned_goto ');
  if (r & request$asynchronous_return) <> 0 then write('asynchronous_return ');
  if (r & request$pfm_cleanup) <> 0 then write('pfm_cleanup ');
  if (r & request$assert_inside_atomic_block) <> 0 then write('assert_inside_atomic_block ');
  if (r & request$volatile_location) <> 0 then write('volatile_location ');
  if (r & request$case_dispatch) <> 0 then write('case_dispatch ');
  if (r & request$hidden_index) <> 0 then write('hidden_index ');
  if (r & request$do_not_delete) <> 0 then write('do_not_delete ');
  if (r & request$prolog_base_register_init) <> 0 then write('prolog_base_register_init ');
  if (r & request$preference_move) <> 0 then write('preference_move ');
  write(']');
  requests_to_string := ' ';
end;

{ begin_compilation - traced under sw3; the compilation's solution of
  kind 17 (isc_user_routines +0x324, from the heap +0x20C).

  0x209168, 0xBC bytes: `btst #3,0x485D31'; new_solution(heap, 17, 0,
  nil, nil, 0) (`move.l #16#110000'). }

procedure begin_compilation;
begin
  if at_backend_switches.sw3 then begin
    writeln(tl_rule);
    writeln('Beginning compilation.');
    writeln(tl_rule);
    writeln;
  end;
  isc_user_routines_324 := new_solution(isc_user_routines_20c, 17, 0, nil,
                                        nil, 0);
end;

{ end_compilation - traced under sw3.

  0x20928C, 0x9A bytes. }

procedure end_compilation;
begin
  if at_backend_switches.sw3 then begin
    writeln(tl_rule);
    writeln('Ending compilation.');
    writeln(tl_rule);
    writeln;
  end;
end;

{ begin_routine - traced under sw3; the statement depth (+0x30C) and
  +0x310 cleared.

  0x20933A, 0xA6 bytes. }

procedure begin_routine;
begin
  if at_backend_switches.sw3 then begin
    writeln(tl_rule);
    writeln('Beginning routine.');
    writeln(tl_rule);
    writeln;
  end;
  isc_user_routines_310 := 0;
  isc_user_routines_30c := 0;
end;

{ end_routine - traced under sw3.

  0x2093F2, 0x9A bytes. }

procedure end_routine;
begin
  if at_backend_switches.sw3 then begin
    writeln(tl_rule);
    writeln('Ending routine.');
    writeln(tl_rule);
    writeln;
  end;
end;

{ begin_basic_block - traced under sw3 with the block's number.

  0x20949C, 0xCC bytes: n a word at 8 (written by address, width 1). }

procedure begin_basic_block(
    n: integer); options(val_param);
begin
  if at_backend_switches.sw3 then begin
    writeln(tl_bb_rule);
    write('Beginning basic block ');
    write(n:1);
    write('.');
    writeln;
    writeln(tl_bb_rule);
    writeln;
  end;
end;

{ end_basic_block - traced under sw3 with the block's number.

  0x2095D2, 0xCC bytes: n a word at 8. }

procedure end_basic_block(
    n: integer); options(val_param);
begin
  if at_backend_switches.sw3 then begin
    writeln(tl_bb_rule);
    write('Ending basic block ');
    write(n:1);
    write('.');
    writeln;
    writeln(tl_bb_rule);
    writeln;
  end;
end;

{ begin_statement - traced under sw3; one statement deeper, with a new
  empty list (its head both the first and the last).

  0x2096B2, 0xD0 bytes: `addq.l #1,0x48110C'; 108 bytes from the ISC
  heap; the tables indexed by the depth's low word. }

procedure begin_statement;
var
  h: lir_request_ptr_t;
begin
  if at_backend_switches.sw3 then begin
    writeln(tl_rule);
    writeln('Beginning statement.');
    writeln(tl_rule);
    writeln;
  end;
  isc_user_routines_30c := isc_user_routines_30c + 1;
  h := mrh_$alloc(isc_heap, 108);
  isc_user_routines_1cc[isc_user_routines_30c] := h;
  isc_user_routines_18c[isc_user_routines_30c] := h;
end;

{ end_statement - traced under sw3; the statement's deferred calls: a
  simple move (move, copyd or copys) requesting preference_move whose
  source's live range is the live range of the previous call's result
  (by its kind: a field's dst, a load's or mfpr's result, a simple
  instruction's last result) is dropped, the previous call given the
  move's destination instead, when that call is of kind 1, 5, 8, 10,
  11, 12, 15 or 16, its opcode's result operand is fully written
  (instruction_attributes' operand b2 bits 7..6 = 3), the live range
  is not a CSE's (isc_is_cse) and at most one of the solutions
  involved is marked (+115 bit 6); traced (isc traces or sw14).  Then,
  unless sw11, the list replayed through the lir_ routines; one
  statement up.

  0x209796, 0x804 bytes: the list from the head's next (+8), the
  previous call through +4; the kinds' set `move.l #105762' (bits 1,
  5, 8, 10..12, 15, 16); the marked solutions counted over the previous
  call's +48, +56..+76, +84, +92, +96 and the move's op1 and op2; the
  replay a case of 18 on the kind less 1; `subq.l #1,0x48110C'.

  Not known from the original: why +48 and +92 (the linkage register,
  unused) are counted. }

procedure end_statement;
var
  q: lir_request_ptr_t;
  p: lir_request_ptr_t;
  attr: instr_attr_view_ptr_t;
  nres: integer32;
  res: isc_solution_ptr_t;
  lr: isc_lr_ptr_t;
  n: integer32;
  dst: isc_solution_ptr_t;
  s: isc_solution_ptr_t;
begin
  if at_backend_switches.sw3 then begin
    writeln(tl_rule);
    writeln('Ending statement.');
    writeln(tl_rule);
    writeln;
  end;

  { the preference moves }
  q := isc_user_routines_1cc[isc_user_routines_30c]^.next;
  while q <> nil do begin
    p := q^.prev;
    attr := instr_attr_view_ptr_t(addr(instruction_attributes[p^.opc]));
    nres := instruction_attributes[p^.opc].nresults;
    case p^.kind of
      8: res := p^.op3;
      10: res := p^.result;
      11: res := p^.result;
      15:
        if nres = 2 then
          res := p^.op2
        else
          res := p^.op3;
      otherwise
        res := nil;
    end;
    if (q^.kind = 15)
       and ((q^.opc = ord(opc$move)) or (q^.opc = ord(opc$copyd))
            or (q^.opc = ord(opc$copys)))
       and ((q^.requests & request$preference_move) <> 0)
       and (p <> isc_user_routines_1cc[isc_user_routines_30c])
       and (p^.kind in [1, 5, 8, 10, 11, 12, 15, 16])
       and (rshft(attr^.opnds[nres].b2 & 16#C0, 6) = 3)
       and (res <> nil) then begin
      dst := q^.op1;
      lr := isc_lr_ptr_t(res^.live_range);
      if (res^.live_range = dst^.live_range) and not lr^.f10.isc_is_cse then begin
        n := 0;
        s := isc_solution_ptr_t(p^.linkage_reg);
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := p^.op1;
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := p^.op2;
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := p^.op3;
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := p^.op4;
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := p^.index;
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := p^.base;
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := p^.result;
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := isc_solution_ptr_t(p^.l92);
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        s := p^.source;
        if s <> nil then
          if s^.f114.builtin_could_deadlock_sched then
            n := n + 1;
        if dst^.f114.builtin_could_deadlock_sched then
          n := n + 1;
        if q^.op2^.f114.builtin_could_deadlock_sched then
          n := n + 1;
        if n <= 1 then begin
          case p^.kind of
            8: p^.op3 := q^.op2;
            10: p^.result := q^.op2;
            11: p^.result := q^.op2;
            15:
              if nres = 2 then
                p^.op2 := q^.op2
              else
                p^.op3 := q^.op2;
            otherwise
              bug_check('ISC: end_statement: Unexpected prev^.kind.%$');
          end;
          p^.next := q^.next;
          if isc_user_routines_18c[isc_user_routines_30c] = q then
            isc_user_routines_18c[isc_user_routines_30c] := p;
          if isc_user_routines_354 or isc_user_routines_356
             or at_backend_switches.sw14 then begin
            writeln;
            writeln(tl_star_rule);
            write('ISC: end_statement: source line ');
            write(q^.inh^.pos.source_line_number:1);
            write(':');
            writeln;
            write('ISC:   ');
            write(opc$t(p^.opc):1);
            write(' ..., <LR ');
            write(res^.live_range^.num:1);
            write('>');
            writeln;
            write('ISC:   ');
            write(opc$t(q^.opc):1);
            write(' <LR ');
            write(dst^.live_range^.num:1);
            write('>, ...');
            writeln;
            writeln('ISC: the preference move was eliminated.');
            writeln(tl_star_rule);
            writeln;
          end;
        end;
      end;
    end;
    q := q^.next;
  end;

  { the replay }
  if not at_backend_switches.sw11 then begin
    q := isc_user_routines_1cc[isc_user_routines_30c]^.next;
    while q <> nil do begin
      case q^.kind of
        1: lir_$branch_instruction(q^.inh, q^.target, q^.opc, q^.requests);
        2: lir_$break_basic_block;
        3: lir_$common_lhs_rhs_token(q^.inh);
        4: lir_$disjoint_lhs_and_rhs_tokens(q^.inh, q^.lhs, q^.rhs);
        5: lir_$dispatch_instruction(q^.inh, solution_ptr_t(q^.op1), q^.opc,
               q^.requests);
        6: lir_$emit_call_or_svc(q^.inh, q^.tree, q^.call, q^.requests,
               solution_ptr_t(q^.op1), q^.linkage_reg);
        7: lir_$end_call_or_svc(integer32(q^.inh), q^.call);
        8: lir_$field_instruction(q^.inh, q^.opc, q^.requests, q^.siz,
               solution_ptr_t(q^.op1), solution_ptr_t(q^.op2), solution_ptr_t(q^.op3));
        9: lir_$label(q^.target);
        10: lir_$load_instruction(q^.inh, q^.opc, q^.requests,
                solution_ptr_t(q^.index), solution_ptr_t(q^.base), solution_ptr_t(q^.result), q^.tree,
                q^.disp_off_tree, q^.bits_known, q^.bits_trusted);
        11: lir_$mfpr_instruction(q^.inh, q^.opc, q^.requests,
                solution_ptr_t(q^.index), solution_ptr_t(q^.base), solution_ptr_t(q^.result), q^.var_name);
        12: lir_$mtpr_instruction(q^.inh, q^.opc, q^.requests,
                solution_ptr_t(q^.source), solution_ptr_t(q^.index), solution_ptr_t(q^.base), q^.var_name);
        13: lir_$operate_and_branch_instruction(q^.inh, q^.opc,
                q^.requests, solution_ptr_t(q^.index), solution_ptr_t(q^.base), q^.target);
        14: lir_$simple_instruction(q^.inh, q^.opc, q^.requests,
                solution_ptr_t(q^.op1), solution_ptr_t(q^.op2), solution_ptr_t(q^.op3), solution_ptr_t(q^.op4));
        15: lir_$simple_instruction(q^.inh, q^.opc, q^.requests,
                solution_ptr_t(q^.op1), solution_ptr_t(q^.op2), solution_ptr_t(q^.op3), nil);
                                        { the image pushes six arguments }
        16: lir_$store_instruction(q^.inh, q^.opc, q^.requests,
                solution_ptr_t(q^.source), solution_ptr_t(q^.index), solution_ptr_t(q^.base), q^.tree,
                q^.disp_off_tree, q^.bits_known, q^.bits_trusted);
        17: lir_main_$entry(q^.node);
        18: lir_main_$handler_reentry(q^.node);
        otherwise
          bug_check('ISC: end_statement: Unexpected p^.kind.%$');
      end;
      q := q^.next;
    end;
  end;
  isc_user_routines_30c := isc_user_routines_30c - 1;
end;

{ debug_lir_$begin_call_or_svc - lir_$begin_call_or_svc's record for a
  call of opcode opc with requests and n operands (at once, unless
  sw11: then nil), traced under sw14.

  0x20B1A4, 0x1FA bytes: inh 8, opc a word at 12, requests 14, n 18;
  `btst #3,0x485D30' (sw11); the record in A2. }

function debug_lir_$begin_call_or_svc(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    n: integer32): univ_ptr; options(val_param);
var
  c: univ_ptr;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write('debug_lir_$begin_call_or_svc: ');
    write('opcode = ');
    write(opc$t(opc):10);
    write(', n_operands = ');
    write(n:1);
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  if not at_backend_switches.sw11 then
    c := lir_$begin_call_or_svc(opc, requests, n)
  else
    c := nil;
  if at_backend_switches.sw14 then begin
    write('        instruction = ');
    write(instruction_to_string(c));
    writeln;
  end;
  debug_lir_$begin_call_or_svc := c;
end;

{ debug_lir_$begin_fortran_io_sequence - lir_$begin_fortran_io_sequence
  at once (unless sw11), traced under sw14.

  0x20B3FA, 0xDC bytes: p 8. }

procedure debug_lir_$begin_fortran_io_sequence(
    p: univ_ptr); options(val_param);
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(0:5);
    write(' / ');
    write(0:5);
    write(') ');
    write('debug_lir_$begin_fortran_io_sequence: ');
    writeln;
  end;
  if not at_backend_switches.sw11 then
    lir_$begin_fortran_io_sequence(p);
end;

{ debug_lir_$branch_instruction - a branch of opcode opc to the label target deferred (kind 1;
  none for opc$bnever).

  0x20B500, 0x1DE bytes: inh 8, target 12, opc a word at 16, requests 18;
  `cmpi.w #1,D3; beq' past the record. }

procedure debug_lir_$branch_instruction(
    inh: inherited_attributes_ptr_t;
    target: univ_ptr;
    opc: integer;
    requests: integer32); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write('label: ');
    write(label_to_string(target));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  if opc <> ord(opc$bnever) then begin
    r := mrh_$alloc(isc_heap, 108);
    r^.kind := 1;
    r^.inh := inh;
    r^.target := target;
    r^.opc := opc;
    r^.requests := requests;
    isc_user_routines_18c[isc_user_routines_30c]^.next := r;
    r^.prev := isc_user_routines_18c[isc_user_routines_30c];
    isc_user_routines_18c[isc_user_routines_30c] := r;
  end;
end;

{ debug_lir_$break_basic_block - the basic block broken (deferred, kind 2).

  0x20B6E8, 0x11E bytes: no parameters. }

procedure debug_lir_$break_basic_block;
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(0:5);
    write(' / ');
    write(0:5);
    write(') ');
    write('debug_lir_$break_basic_block: ');
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 2;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$common_lhs_rhs_token - the common left- and right-hand side token (deferred,
  kind 3).

  0x20B824, 0x12C bytes: inh 8. }

procedure debug_lir_$common_lhs_rhs_token(
    inh: inherited_attributes_ptr_t); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write('debug_lir_$common_lhs_rhs_token: ');
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 3;
  r^.inh := inh;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$disjoint_lhs_and_rhs_tokens - disjoint left- and right-hand side tokens
  (deferred, kind 4).

  0x20B972, 0x134 bytes: inh 8, lhs 12, rhs 16. }

procedure debug_lir_$disjoint_lhs_and_rhs_tokens(
    inh: inherited_attributes_ptr_t;
    lhs: univ_ptr;
    rhs: univ_ptr); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write('debug_lir_$disjoint_lhs_and_rhs_tokens: ');
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 4;
  r^.inh := inh;
  r^.lhs := lhs;
  r^.rhs := rhs;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$dispatch_instruction - a dispatch (an indirect jump) of opcode opc through
  op1 (deferred, kind 5).

  0x20BACE, 0x1D8 bytes: inh 8, op1 12, opc a word at 16, requests 18. }

procedure debug_lir_$dispatch_instruction(
    inh: inherited_attributes_ptr_t;
    op1: isc_solution_ptr_t;
    opc: integer;
    requests: integer32); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write('operand_1: ');
    write(solution_to_string(op1));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 5;
  r^.inh := inh;
  r^.op1 := op1;
  r^.opc := opc;
  r^.requests := requests;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$emit_call_or_svc - the call emitted (deferred, kind 6): the call node, the
  call's record, the routine's solution, the linkage register's.

  0x20BCB2, 0x242 bytes: inh 8, node 12, call 16, requests 20, sol
  24, ret 28. }

procedure debug_lir_$emit_call_or_svc(
    inh: inherited_attributes_ptr_t;
    node: univ_ptr;
    call: univ_ptr;
    requests: integer32;
    sol: isc_solution_ptr_t;
    ret: solution_ptr_t); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write('debug_lir_$emit_call_or_svc: ');
    write('instr = ');
    write(instruction_to_string(call));
    write(', operand_1 = ');
    write(solution_to_string(sol));
    write(', linkage_reg = ');
    write(solution_to_string(isc_solution_ptr_t(ret)));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 6;
  r^.inh := inh;
  r^.tree := node;
  r^.call := call;
  r^.requests := requests;
  r^.op1 := sol;
  r^.linkage_reg := ret;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$end_call_or_svc - the call finished (deferred, kind 7).

  0x20BF38, 0x16A bytes: inh 8, call 12. }

procedure debug_lir_$end_call_or_svc(
    inh: inherited_attributes_ptr_t;
    call: univ_ptr); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write('debug_lir_$end_call_or_svc: ');
    write('instr = ');
    write(instruction_to_string(call));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 7;
  r^.inh := inh;
  r^.call := call;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$field_instruction - a field instruction (insert or extract) of siz bits
  at pos (deferred, kind 8); dst given a live range first.

  0x20C0BE, 0x2AC bytes: inh 8, opc a word at 12, requests 14, siz 18,
  src 22, pos 26, dst 30. }

procedure debug_lir_$field_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    siz: integer32;
    src: isc_solution_ptr_t;
    pos: isc_solution_ptr_t;
    dst: isc_solution_ptr_t); options(val_param);
var
  r: lir_request_ptr_t;
begin
  guarantee_has_live_range(dst);
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write('src: ');
    write(solution_to_string(src));
    write(', siz: ');
    write(siz:1);
    write(', pos: ');
    write(solution_to_string(pos));
    write(', dst: ');
    write(solution_to_string(dst));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 8;
  r^.inh := inh;
  r^.opc := opc;
  r^.requests := requests;
  r^.siz := siz;
  r^.op1 := src;
  r^.op2 := pos;
  r^.op3 := dst;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$label - the label target placed (deferred, kind 9).

  0x20C388, 0x14C bytes: inh 8, target 12. }

procedure debug_lir_$label(
    inh: inherited_attributes_ptr_t;
    target: univ_ptr); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(label_to_string(target));
    write(':');
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 9;
  r^.inh := inh;
  r^.target := target;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$load_instruction - a load of opcode opc from base + index/disp into
  result (deferred, kind 10); result given a live range first.

  0x20C4D4, 0x3EA bytes: inh 8, opc a word at 12, requests 14,
  index 18, base 22, result 26, tree 30, disp_off_tree 34, bits_known 38,
  bits_trusted 42; the index's object written (its +0). }

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
    bits_trusted: integer32); options(val_param);
var
  r: lir_request_ptr_t;
begin
  guarantee_has_live_range(result);
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write('[ base: ');
    write(solution_to_string(base));
    write(' + ');
    write('index/disp: ');
    write(solution_to_string(index));
    write(' ]');
    write(' == ');
    write(il_node_to_string(index^.object_with_name));
    write(', bits_known = ');
    write(bits_known:1);
    write(', bits_trusted = ');
    write(bits_trusted:1);
    write(', tree = ');
    write(il_node_to_string(tree));
    write(', disp_off_tree = ');
    write(disp_off_tree:1);
    write(', result: ');
    write(solution_to_string(result));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 10;
  r^.inh := inh;
  r^.opc := opc;
  r^.requests := requests;
  r^.index := index;
  r^.base := base;
  r^.result := result;
  r^.tree := tree;
  r^.disp_off_tree := disp_off_tree;
  r^.bits_known := bits_known;
  r^.bits_trusted := bits_trusted;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$simple_instruction - an instruction of opcode opc on op1..op3 (deferred,
  kind 15; none for opc$costly and opc$adj_move); the result (op3, or
  op2 without one) given a live range first.

  0x20C924, 0x268 bytes: inh 8, opc a word at 12, requests 14,
  op1 18, op2 22, op3 26; `cmpi.w #211; cmpi.w #208'. }

procedure debug_lir_$simple_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    op1: isc_solution_ptr_t;
    op2: isc_solution_ptr_t;
    op3: isc_solution_ptr_t); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if op3 <> nil then
    guarantee_has_live_range(op3)
  else
    guarantee_has_live_range(op2);
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write(solution_to_string(op1));
    write(', ');
    write(solution_to_string(op2));
    write(', ');
    write(solution_to_string(op3));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  if (opc <> ord(opc$adj_move)) and (opc <> ord(opc$costly)) then begin
    r := mrh_$alloc(isc_heap, 108);
    r^.kind := 15;
    r^.inh := inh;
    r^.opc := opc;
    r^.requests := requests;
    r^.op1 := op1;
    r^.op2 := op2;
    r^.op3 := op3;
    isc_user_routines_18c[isc_user_routines_30c]^.next := r;
    r^.prev := isc_user_routines_18c[isc_user_routines_30c];
    isc_user_routines_18c[isc_user_routines_30c] := r;
  end;
end;

{ debug_lir_$store_instruction - a store of opcode opc of source to base +
  index/disp (deferred, kind 16).

  0x20CB8C, 0x3FA bytes: inh 8, opc a word at 12, requests 14,
  source 18, index 22, base 26, tree 30, disp_off_tree 34, bits_known 38,
  bits_trusted 42. }

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
    bits_trusted: integer32); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write('source: ');
    write(solution_to_string(source));
    write(', ');
    write('[ base: ');
    write(solution_to_string(base));
    write(' + ');
    write('index/disp: ');
    write(solution_to_string(index));
    write(' ]');
    write(' == ');
    write(il_node_to_string(index^.object_with_name));
    write(', bits_known = ');
    write(bits_known:1);
    write(', bits_trusted = ');
    write(bits_trusted:1);
    write(', tree = ');
    write(il_node_to_string(tree));
    write(', disp_off_tree = ');
    write(disp_off_tree:1);
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 16;
  r^.inh := inh;
  r^.opc := opc;
  r^.requests := requests;
  r^.source := source;
  r^.index := index;
  r^.base := base;
  r^.tree := tree;
  r^.disp_off_tree := disp_off_tree;
  r^.bits_known := bits_known;
  r^.bits_trusted := bits_trusted;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$mfpr_instruction - a move from a processor register (deferred, kind
  11); result given a live range first.

  0x20CF8E, 0x328 bytes: inh 8, opc a word at 12, requests 14,
  index 18, base 22, result 26, var_name 30. }

procedure debug_lir_$mfpr_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    index: isc_solution_ptr_t;
    base: isc_solution_ptr_t;
    result: isc_solution_ptr_t;
    var_name: univ_ptr); options(val_param);
var
  r: lir_request_ptr_t;
begin
  guarantee_has_live_range(result);
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write('[ base: ');
    write(solution_to_string(base));
    write(' + ');
    write('index/disp: ');
    write(solution_to_string(index));
    write(' ]');
    write(' == ');
    write(il_node_to_string(index^.object_with_name));
    write(', var_name: ');
    write(il_node_to_string(var_name));
    write(', result: ');
    write(solution_to_string(result));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 11;
  r^.inh := inh;
  r^.opc := opc;
  r^.requests := requests;
  r^.index := index;
  r^.base := base;
  r^.result := result;
  r^.var_name := var_name;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$mtpr_instruction - a move to a processor register (deferred, kind 12).

  0x20D2C2, 0x33A bytes: inh 8, opc a word at 12, requests 14,
  source 18, index 22, base 26, var_name 30. }

procedure debug_lir_$mtpr_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    source: isc_solution_ptr_t;
    index: isc_solution_ptr_t;
    base: isc_solution_ptr_t;
    var_name: univ_ptr); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write('source: ');
    write(solution_to_string(source));
    write(', ');
    write('[ base: ');
    write(solution_to_string(base));
    write(' + ');
    write('index/disp: ');
    write(solution_to_string(index));
    write(' ]');
    write(' == ');
    write(il_node_to_string(index^.object_with_name));
    write(', var_name: ');
    write(il_node_to_string(var_name));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 12;
  r^.inh := inh;
  r^.opc := opc;
  r^.requests := requests;
  r^.source := source;
  r^.index := index;
  r^.base := base;
  r^.var_name := var_name;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$operate_and_branch_instruction - an operate-and-branch of opcode opc on
  op1 and op2 to target (deferred, kind 13; the operands in the
  record's index and base).

  0x20D5FC, 0x24A bytes: inh 8, opc a word at 12, requests 14,
  op1 18, op2 22, target 26. }

procedure debug_lir_$operate_and_branch_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    op1: isc_solution_ptr_t;
    op2: isc_solution_ptr_t;
    target: univ_ptr); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write(solution_to_string(op1));
    write(', ');
    write(solution_to_string(op2));
    write(', target: ');
    write(label_to_string(target));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 13;
  r^.inh := inh;
  r^.opc := opc;
  r^.requests := requests;
  r^.index := op1;
  r^.base := op2;
  r^.target := target;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_main_$entry - lir_main_$entry for the entry statement node (deferred,
  kind 17).

  0x20D850, 0x12C bytes: node 8. }

procedure debug_lir_main_$entry(
    node: univ_ptr); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(0:5);
    write(' / ');
    write(0:5);
    write(') ');
    write('debug_lir_main_$entry: ');
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 17;
  r^.node := node;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_main_$handler_reentry - lir_main_$handler_reentry for the statement
  node (deferred, kind 18).

  0x20D994, 0x12C bytes: node 8. }

procedure debug_lir_main_$handler_reentry(
    node: univ_ptr); options(val_param);
var
  r: lir_request_ptr_t;
begin
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(0:5);
    write(' / ');
    write(0:5);
    write(') ');
    write('debug_lir_main_$handler_reentry: ');
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 18;
  r^.node := node;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;

{ debug_lir_$pa_risc_shift_double_instruction - an instruction of opcode opc on four
  operands (deferred, kind 14: a simple instruction with op4); op4
  given a live range first.

  0x20DAE2, 0x298 bytes: inh 8, opc a word at 12,
  requests 14, op3 18, op1 22, op2 26, op4 30 (stored at +64, +56, +60,
  +68). }

procedure debug_lir_$pa_risc_shift_double_instruction(
    inh: inherited_attributes_ptr_t;
    opc: integer;
    requests: integer32;
    op3: isc_solution_ptr_t;
    op1: isc_solution_ptr_t;
    op2: isc_solution_ptr_t;
    op4: isc_solution_ptr_t); options(val_param);
var
  r: lir_request_ptr_t;
begin
  guarantee_has_live_range(op4);
  if at_backend_switches.sw14 then begin
    write('stmt(');
    write(inh^.pos.source_line_number:5);
    write(' / ');
    write(inh^.pos.stmt_number:5);
    write(') ');
    write(opc$t(opc):10);
    write(' ');
    write(solution_to_string(op1));
    write(', ');
    write(solution_to_string(op2));
    write(', ');
    write(solution_to_string(op3));
    write(', ');
    write(solution_to_string(op4));
    write(', ');
    write(requests_to_string(requests));
    writeln;
  end;
  r := mrh_$alloc(isc_heap, 108);
  r^.kind := 14;
  r^.inh := inh;
  r^.opc := opc;
  r^.requests := requests;
  r^.op1 := op1;
  r^.op2 := op2;
  r^.op3 := op3;
  r^.op4 := op4;
  isc_user_routines_18c[isc_user_routines_30c]^.next := r;
  r^.prev := isc_user_routines_18c[isc_user_routines_30c];
  isc_user_routines_18c[isc_user_routines_30c] := r;
end;
