{ utils - the back end's utilities for the LIR (cc.a88k only): taking
  instructions and lifetime segments out cleanly, the segments' exposed
  and final lists (by block, or by live range with hints:
  lir_main_c86), new segments, the statement numbers an instruction
  carries, instruction templates copied into blocks and completed,
  birthpoints (where a value was born, through copies and the
  operations that keep it) and the join birthpoints' inputs, the walks
  over a value's definitions and uses, and small questions about
  instructions.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x28491C  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x28493E  utils_$begin_compilation
    --------  0x2849A6  utils_$end_compilation
    --------  0x2849C2  utils_$excise_instruction_cleanly
    --------  0x284B90  utils_$excise_instruction_if_unconsumed
    --------  0x284C0E  utils_$remove_reader_from_lts
    --------  0x284D3A  utils_$remove_lts_from_exposed_list
    --------  0x284E36  utils_$remove_lts_from_final_list
    --------  0x284F28  utils_$excise_lts_cleanly
    --------  0x285050  add_statement_number (in utils_$maybe_merge_source_statements)
    --------  0x285110  utils_$maybe_merge_source_statements
    --------  0x28521E  utils_$guarantee_instr_sequence
    --------  0x285274  utils_$resequence_inserted_instruction
    --------  0x2852CE  utils_$initialize_lts_hint_pointers
    --------  0x28530C  utils_$find_exposed_lts
    --------  0x2853F6  utils_$find_final_lts
    --------  0x2854E0  utils_$put_lts_on_exposed_list
    --------  0x2855FC  utils_$put_lts_on_final_list
    --------  0x285714  utils_$find_last_lts_in_bb
    --------  0x2857BE  utils_$get_new_lts
    --------  0x285898  utils_$get_exposed_lts
    --------  0x28590A  utils_$get_final_lts
    --------  0x285986  utils_$compare_birthpoints
    --------  0x2859F6  unique_input (internal)
    --------  0x285ABA  utils_$get_canonical_birthpoint
    --------  0x285F16  utils_$set_instruction_opcode
    --------  0x285F5A  copy_instr_template_to_bb (internal)
    --------  0x286128  utils_$copy_instr_template_to_bb_end
    --------  0x28618A  utils_$copy_instr_template_to_bb_head
    --------  0x2861DA  get_last_lts_in_bb (internal)
    --------  0x286230  utils_$complete_copied_instr
    --------  0x28637E  utils_$complete_copied_instr_at_bb_head
    --------  0x286564  look_for_path (internal)
    --------  0x2865F0  no_path_through_target_bb
    --------  0x286626  utils_$remove_spurious_active_on_exit
    --------  0x286700  utils_$strip_extraneous_modifies
    --------  0x286930  jbi_input_exists (internal)
    --------  0x286968  utils_$drop_jbi_input
    --------  0x286A22  utils_$move_definition
    --------  0x286AF8  find_definition (internal)
    --------  0x286B88  utils_$locate_definition
    --------  0x286C5A  utils_$find_join_bp
    --------  0x286CA2  utils_$add_birthpoint
    --------  0x286E4C  add_use_def (internal)
    --------  0x286EB8  consider_all_defs (internal)
    --------  0x286FDA  utils_$apply_func_to_all_defs
    --------  0x287150  consider_all_uses (internal)
    --------  0x28720E  utils_$apply_func_to_all_uses
    --------  0x28733A  utils_$find_mate_operand
    --------  0x287608  utils_$instr_is_ref_to_argument_block
    --------  0x28763C  utils_$instr_is_ref_to_memory_home
    --------  0x2877D2  utils_$instrs_consume_identical_symbols
    --------  0x28793E  utils_$strip_may_gen_exception
    --------  0x2879EE  utils_$find_unused_operand_slot
    A5 0x492FA8: the module's data (0x40 bytes): the use/def heap (+0),
    the statement number heap (+24), look_for_path's target block and
    marks, the bounds of find_definition's walk, two flags.

  utils_$remove_spurious_active_on_exit (no caller in the image) and
  utils_$drop_jbi_input (called only here) load A5 and are global;
  no_path_through_target_bb is passed to utils_$apply_func_to_all_uses
  by address (`move.l #0x2865F0'), so it is global too.

  An instruction's operands: k-th at its +32 + 12k (backend.ins.pas);
  a register or memory operand (kinds 1..11) refers to a segment (+8),
  and the operands that refer to a segment are chained from its refs
  (+4, the definition first) through their link (+4).  An instruction
  with +2 bit 7 set has a 20-byte alias descriptor 24 bytes before it.
  Instruction +0 bit 1: +32 points to a list of statement numbers
  (ut_stmt_t) instead of holding two words; +2 bit 6: may be excised;
  +2 bit 5: may raise an exception; +0 bit 6: the first result is
  tied to the operand before it.  Opcodes: 202 a copy, 203 a join
  birthpoint (its operand 2 the joined segment, operand 3 the inputs,
  kind 27), 199 another head-of-block opcode, 79 and 81 add and
  subtract an immediate, 75 a load of an address, 129 one with an
  extra operand.

  Not known from the original: every local and parameter name; the
  module variables' names; the views' names (ut_...); the names of the
  fields backend.ins.pas gives by role. }
module utils;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  { A join birthpoint's input: chained from the input segment's l44
    (+0) and from the join instruction's operand 3 (+4). }
  ut_jbi_ptr_t = ^ut_jbi_t;
  ut_jbi_t = record
    next: ut_jbi_ptr_t;                 { +0 }
    next_op: ut_jbi_ptr_t;              { +4 }
    lts: lts_ptr_t;                     { +8 }
    instr: instr_ptr_t;                 { +12: the join birthpoint }
  end;

  { Statement numbers past an instruction's two (8 bytes from the
    statement number heap). }
  ut_stmt_ptr_t = ^ut_stmt_t;
  ut_stmt_t = record
    next: ut_stmt_ptr_t;                { +0 }
    s1: 0..65535;                       { +4 }
    s2: 0..65535;                       { +6 }
  end;

  { An instruction's +32. }
  ut_pos_ptr_t = ^ut_pos_t;
  ut_pos_t = record
    case integer of
      1: (s1: 0..65535;                 { +32 }
          s2: 0..65535);                { +34 }
      2: (list: ut_stmt_ptr_t);
  end;

  { The pairs a walk collects (248 bytes from the use/def heap). }
  ut_pair_t = record
    x: lts_ptr_t;
    y: lts_ptr_t;
  end;
  ut_use_def_ptr_t = ^ut_use_def_t;
  ut_use_def_t = record
    next: ut_use_def_ptr_t;             { +0 }
    count: integer32;                   { +4 }
    e: array [1..30] of ut_pair_t;      { +8 }
  end;

  { A live range's node20, as utils reads it. }
  ut_sym_ptr_t = ^ut_sym_t;
  ut_sym_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: array [4..23] of char;    { +4 }
    flags24: integer32;                 { +24 }
    unused_28: integer32;               { +28 }
    flags32: integer32;                 { +32 }
  end;

  { An opcode's attributes as bytes (each result's 4 bytes from +4). }
  ut_attr_ptr_t = ^ut_attr_t;
  ut_attr_t = packed array [0..19] of 0..255;

  { An operand's first longword as bytes (+1 the low byte of an
    rrp$set_t). }
  ut_opnd_bytes_ptr_t = ^ut_opnd_bytes_t;
  ut_opnd_bytes_t = packed record
    num: 0..255;
    rrp: 0..255;
    b2: 0..255;
    b3: 0..255;
  end;

  { at_backend_4fc's record (get_calling_conventions'): two live ranges
    a memory home is reached through. }
  ut_conv_ptr_t = ^ut_conv_t;
  ut_conv_t = record
    unused_0: array [0..107] of char;   { +0 }
    lr108: lr_ptr_t;                    { +108 }
    unused_112: integer32;              { +112 }
    lr116: lr_ptr_t;                    { +116 }
  end;

var
  use_def_heap: mrh_$heap_t;            { +0 }
  unused_20: integer32;                 { +20 }
  stmt_heap: mrh_$heap_t;               { +24 }
  target_bb: bb_ptr_t;                  { +44: look_for_path's }
  lo_bb: bb_ptr_t;                      { +48: find_definition's walk }
  hi_bb: bb_ptr_t;                      { +52 }
  path_mark: integer32;                 { +56: look_for_path's (and the
                                          next) }
  in_unique: boolean;                   { +60: unique_input compares }
  excising: boolean;                    { +62 }

procedure utils_$drop_jbi_input(
    j: ut_jbi_ptr_t); options(val_param); forward;

{ utils_$begin_compilation - 0x28493E, 0x44 bytes: the heaps
  initialized (flags 1, sizes 8 and 248: `move.l #0x10008', `move.l
  #0x100F8'); in_unique `move.b #0'. }

procedure utils_$begin_compilation;
begin
  mrh_$initialize(stmt_heap, 1, 8, 'statement number heap%');
  mrh_$initialize(use_def_heap, 1, 248, 'use/def heap%');
  in_unique := false;
end;

{ utils_$end_compilation - 0x2849A6, 0x1C bytes. }

procedure utils_$end_compilation;
begin
  mrh_$release_all(use_def_heap);
end;

{ utils_$excise_instruction_cleanly - instr's operands taken off their
  segments: a reading operand from its segment's refs (the segment
  excised when nothing refers to it any more; with one non-reading
  reference left, that instruction excised if nothing uses what it
  writes); a writing one, when this is a nested excision, its segment
  excised (bug_check if something still reads it); a join's inputs
  from their segments (an input segment left final without uses taken
  off the final list and, with cascade, its definition excised if
  unused).  Then lir_utils_$excise_inst.

  0x2849C2, 0x18E bytes: excising saved (D4) and set; +2 bit 6
  cleared; the operands by `dbf' with D5 12k; kinds 1..11 by `btst' in
  #4094; the join's inputs (kind 27) along their +4. }

procedure utils_$excise_instruction_cleanly(
    instr: instr_ptr_t;
    cascade: boolean);
var
  was: boolean;
  k: integer32;
  op: opnd_ptr_t;
  lts: lts_ptr_t;
  p: opnd_ptr_t;
  r: opnd_ptr_t;
  j: ut_jbi_ptr_t;
  q: ut_jbi_ptr_t;
  jl: lts_ptr_t;
begin
  was := excising;
  excising := true;
  instr^.h.b2_6 := false;
  for k := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      if op^.h.read then begin
        lts := op^.lts;
        if lts^.refs = op then
          lts^.refs := op^.link
        else begin
          p := lts^.refs;
          while p^.link <> op do
            p := p^.link;
          p^.link := op^.link;
        end;
        lts := op^.lts;
        r := lts^.refs;
        if r = nil then
          utils_$excise_lts_cleanly(lts, cascade)
        else if not lts^.f2.final and not r^.h.read and (r^.link = nil) then
          discard(utils_$excise_instruction_if_unconsumed(
                    utils_ins_$operands_instruction(r), cascade));
      end
      else if was then begin
        if op^.link <> nil then
          bug_check('UTILS_$EXCISE_INSTRUCTION_CLEANLY:  writer still has consumers%$');
        utils_$excise_lts_cleanly(op^.lts, false);
      end;
    end
    else if op^.h.kind = operand$join_birthpoint_inputs then begin
      j := ut_jbi_ptr_t(op^.link);
      while j <> nil do begin
        jl := j^.lts;
        if jl^.l44 = j then
          jl^.l44 := j^.next
        else begin
          q := jl^.l44;
          while q^.next <> j do
            q := q^.next;
          q^.next := j^.next;
        end;
        if jl^.f2.final and (jl^.l28 = nil) and (jl^.l44 = nil) then begin
          utils_$remove_lts_from_final_list(jl);
          if cascade then
            discard(utils_$excise_instruction_if_unconsumed(
                      utils_ins_$operands_instruction(jl^.refs), true));
        end;
        j := j^.next_op;
      end;
    end;
  end;
  discard(lir_utils_$excise_inst(instr));
  excising := was;
end;

{ utils_$excise_instruction_if_unconsumed - instr excised (true) when
  no operand it writes has a reader or a final segment and its +2 bit
  6 allows; else false.

  0x284B90, 0x7E bytes. }

function utils_$excise_instruction_if_unconsumed(
    instr: instr_ptr_t;
    cascade: boolean): boolean;
var
  k: integer32;
  op: opnd_ptr_t;
begin
  utils_$excise_instruction_if_unconsumed := false;
  for k := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[k]);
    if (op^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
       and not op^.h.read then
      if (op^.link <> nil) or op^.lts^.f2.final then
        return;
  end;
  if instr^.h.b2_6 then begin
    utils_$excise_instruction_cleanly(instr, cascade);
    utils_$excise_instruction_if_unconsumed := true;
  end;
end;

{ utils_$remove_reader_from_lts - op (a reading register or memory
  operand: bug_check else) taken off its segment's refs; the segment
  excised when that was the last, else, when the segment is written
  and one reference is left, that instruction excised if unused.

  0x284C0E, 0xC0 bytes: `andi.w #12' of +1 (write, modify). }

procedure utils_$remove_reader_from_lts(
    op: opnd_ptr_t;
    cascade: boolean);
var
  lts: lts_ptr_t;
  p: opnd_ptr_t;
begin
  if op^.h.write or op^.h.modify then
    bug_check('UTILS_$REMOVE_READER_FROM_LTS:  writer not permitted%$');
  if not (op^.h.kind in [operand$ip_reg..operand$well_behaved_memory]) then
    bug_check('UTILS_$REMOVE_READER_FROM_LTS:  illegal operand kind%$');
  lts := op^.lts;
  if lts^.refs = op then
    lts^.refs := op^.link
  else begin
    p := lts^.refs;
    while p^.link <> op do
      p := p^.link;
    p^.link := op^.link;
  end;
  if lts^.refs = nil then
    utils_$excise_lts_cleanly(lts, cascade)
  else if ([rrp$modify, rrp$write] * lts^.rrp <> [])
          and (lts^.refs^.link = nil) then
    discard(utils_$excise_instruction_if_unconsumed(
              utils_ins_$operands_instruction(lts^.refs), cascade));
end;

{ utils_$remove_lts_from_exposed_list - lts off its exposed list (its
  block's, or its live range's at the hint utils_$find_exposed_lts
  leaves); nothing when it is not there and its live range is not
  complex, bug_check when it is.

  0x284D3A, 0xB6 bytes: the arguments the live range's number (by
  address, +6) and the segment's (+2, zero-extended to a frame
  longword). }

procedure utils_$remove_lts_from_exposed_list(
    lts: lts_ptr_t);
var
  lr: lr_ptr_t;
  bb: bb_ptr_t;
  p: lts_ptr_t;
  n: integer32;
begin
  lr := lts^.lr;
  bb := lts^.bb;
  if utils_$find_exposed_lts(lr, bb) <> lts then begin
    if lr^.id = 0 then
      return;
    n := lts^.f2.num;
    bug_check('UTILS_$remove_lts_from_exposed_list:  indecent exposure %3ZWD.%2ZLD%$',
              lr^.num, n);
  end;
  if lir_main_c86 = 0 then begin
    if bb^.exposed = lts then
      bb^.exposed := lts^.next_exposed
    else begin
      p := bb^.exposed;
      while p^.next_exposed <> lts do
        p := p^.next_exposed;
      p^.next_exposed := lts^.next_exposed;
    end;
  end
  else if lr^.exposed_prev = nil then
    lr^.exposed := lts^.next_exposed
  else
    lr^.exposed_prev^.next_exposed := lts^.next_exposed;
  lts^.f2.exposed := false;
  lts^.next_exposed := nil;
  lr^.exposed_hint := nil;
  lr^.exposed_prev := nil;
end;

{ utils_$remove_lts_from_final_list - as the exposed list's, for the
  final lists.

  0x284E36, 0xB6 bytes. }

procedure utils_$remove_lts_from_final_list(
    lts: lts_ptr_t);
var
  lr: lr_ptr_t;
  bb: bb_ptr_t;
  p: lts_ptr_t;
  n: integer32;
begin
  lr := lts^.lr;
  bb := lts^.bb;
  if utils_$find_final_lts(lr, bb) <> lts then begin
    if lr^.id = 0 then
      return;
    n := lts^.f2.num;
    bug_check('UTILS_$remove_lts_from_final_list:  not final %3ZWD.%2ZLD%$',
              lr^.num, n);
  end;
  if lir_main_c86 = 0 then begin
    if bb^.finals = lts then
      bb^.finals := lts^.next_final
    else begin
      p := bb^.finals;
      while p^.next_final <> lts do
        p := p^.next_final;
      p^.next_final := lts^.next_final;
    end;
  end
  else if lr^.final_prev = nil then
    lr^.finals := lts^.next_final
  else
    lr^.final_prev^.next_final := lts^.next_final;
  lts^.f2.final := false;
  lts^.next_final := nil;
  lr^.final_hint := nil;
  lr^.final_prev := nil;
end;

{ utils_$excise_lts_cleanly - lts taken out of everything: the next
  segment in the block becomes the first when lts was (complex live
  ranges only); off the exposed list and off the list of the
  definition that reached it (which, left final with nothing to
  reach, leaves the final list and, with cascade, has its definition
  excised if unused); off the final list; off its live range's list;
  +24 cleared in phase 9; freed (lir_$free_lifetime_segment).

  0x284F28, 0x128 bytes: `cmpi.w #9,0x485D32'. }

procedure utils_$excise_lts_cleanly(
    lts: lts_ptr_t;
    cascade: boolean);
var
  lr: lr_ptr_t;
  d: lts_ptr_t;
  p: lts_ptr_t;
begin
  lr := lts^.lr;
  if (lts^.next <> nil) and lts^.f2.first_in_bb and (lr^.id <> 0) then
    if lts^.next^.bb = lts^.bb then
      lts^.next^.f2.first_in_bb := true;
  if lts^.f2.exposed then begin
    utils_$remove_lts_from_exposed_list(lts);
    d := lts^.l44;
    if d <> nil then begin
      if d^.l28 = lts then
        d^.l28 := lts^.l28
      else begin
        p := d^.l28;
        while p^.l28 <> lts do
          p := p^.l28;
        p^.l28 := lts^.l28;
      end;
      if d^.f2.final and (d^.l28 = nil) and (d^.l44 = nil) then begin
        utils_$remove_lts_from_final_list(d);
        if cascade then
          discard(utils_$excise_instruction_if_unconsumed(
                    utils_ins_$operands_instruction(d^.refs), true));
      end;
    end;
  end;
  if lts^.f2.final then
    utils_$remove_lts_from_final_list(lts);
  if lr^.ltss = lts then
    lr^.ltss := lts^.next
  else begin
    p := lr^.ltss;
    while p^.next <> lts do
      p := p^.next;
    p^.next := lts^.next;
  end;
  if at_backend_phase = 9 then
    lts^.l24 := 0;
  lir_$free_lifetime_segment(lts);
end;

{ utils_$maybe_merge_source_statements - when src writes (write or
  modify) a register or memory operand whose live range's node20 (a
  VAR_NAME's flags at +32, kind 110's at +24) has neither bit 14 nor
  bit 17 (`andi.l #0x24000'), src's statement numbers are added to
  dst's.

  0x285110, 0x10E bytes. }

procedure utils_$maybe_merge_source_statements(
    dst: instr_ptr_t;
    src: instr_ptr_t);
var
  merge: boolean;
  k: integer32;
  op: opnd_ptr_t;
  sym: ut_sym_ptr_t;
  flags: integer32;
  pos: ut_pos_ptr_t;
  p: ut_stmt_ptr_t;

{ add_statement_number - n among instr's statement numbers unless it is
  there: in the second word when it is free, else in the list (made
  from the two words when there is none), in a free second word of its
  last record or a new record.

  0x285050, 0xC0 bytes, nested (no static link: the parent's frame is
  not used): instr (8), n (12) compared with the zero-extended words;
  mrh_$alloc_fixed(stmt_heap) through the caller's A5. }

  procedure add_statement_number(
      instr: instr_ptr_t;
      n: integer32); options(val_param);
  var
    pos: ut_pos_ptr_t;
    p: ut_stmt_ptr_t;
    q: ut_stmt_ptr_t;
  begin
    pos := addr(instr^.l32);
    if not instr^.h.b0_1 then begin
      if (pos^.s1 = n) or (pos^.s2 = n) then
        return;
      if pos^.s2 = 0 then
        pos^.s2 := n
      else begin
        p := mrh_$alloc_fixed(stmt_heap);
        p^.s1 := pos^.s1;
        p^.s2 := pos^.s2;
        q := mrh_$alloc_fixed(stmt_heap);
        p^.next := q;
        q^.s1 := n;
        instr^.h.b0_1 := true;
        pos^.list := p;
      end;
    end
    else begin
      p := pos^.list;
      repeat
        if (p^.s1 = n) or (p^.s2 = n) then
          return;
        if p^.next = nil then
          exit;
        p := p^.next;
      until false;
      if p^.s2 = 0 then
        p^.s2 := n
      else begin
        q := mrh_$alloc_fixed(stmt_heap);
        p^.next := q;
        q^.s1 := n;
      end;
    end;
  end;

begin
  merge := false;
  for k := 1 to src^.h.nopnds do begin
    op := addr(src^.opnds[k]);
    if (op^.h.write or op^.h.modify)
       and (op^.h.kind in [operand$ip_reg..operand$well_behaved_memory]) then begin
      sym := op^.lts^.lr^.node20;
      if sym <> nil then begin
        if sym^.kind = 109 then
          flags := sym^.flags32
        else if sym^.kind = 110 then
          flags := sym^.flags24
        else
          next;
        if flags & 16#24000 = 0 then begin
          merge := true;
          exit;
        end;
      end;
    end;
  end;
  if merge then begin
    pos := addr(src^.l32);
    if not src^.h.b0_1 then begin
      if pos^.s1 <> 0 then
        add_statement_number(dst, pos^.s1);
      if pos^.s2 <> 0 then
        add_statement_number(dst, pos^.s2);
    end
    else begin
      p := pos^.list;
      while p <> nil do begin
        if p^.s1 <> 0 then
          add_statement_number(dst, p^.s1);
        if p^.s2 <> 0 then
          add_statement_number(dst, p^.s2);
        p := p^.next;
      end;
    end;
  end;
end;

{ utils_$guarantee_instr_sequence - every block's instruction numbers
  made increasing.

  0x28521E, 0x56 bytes: the numbers zero-extended (`clr.l; move.w'). }

procedure utils_$guarantee_instr_sequence(
    rtn: rtn_ptr_t);
var
  bb: bb_ptr_t;
  i: instr_ptr_t;
  n: integer32;
begin
  bb := rtn^.bbs;
  while bb <> nil do begin
    i := bb^.first;
    if i <> nil then begin
      n := i^.num;
      i := i^.next;
      while i <> nil do begin
        if i^.num <= n then
          i^.num := n + 1;
        n := i^.num;
        i := i^.next;
      end;
    end;
    bb := bb^.next;
  end;
end;

{ utils_$resequence_inserted_instruction - instr numbered after the one
  before it (1 first), and the ones after renumbered until one is
  already greater.

  0x285274, 0x5A bytes. }

procedure utils_$resequence_inserted_instruction(
    instr: instr_ptr_t);
var
  n: integer32;
  i: instr_ptr_t;
begin
  if instr^.prev <> nil then
    instr^.num := instr^.prev^.num + 1
  else
    instr^.num := 1;
  n := instr^.num;
  i := instr^.next;
  while i <> nil do begin
    if i^.num > n then
      exit;
    n := n + 1;
    i^.num := n;
    i := i^.next;
  end;
end;

{ utils_$initialize_lts_hint_pointers - lir_main_c8d set, every live
  range's hints cleared.

  0x2852CE, 0x3E bytes. }

procedure utils_$initialize_lts_hint_pointers(
    rtn: rtn_ptr_t);
var
  lr: lr_ptr_t;
begin
  lir_main_c8d := true;
  lr := rtn^.lrs;
  while lr <> nil do begin
    lr^.exposed_hint := nil;
    lr^.exposed_prev := nil;
    lr^.final_hint := nil;
    lr^.final_prev := nil;
    lr := lr^.next;
  end;
end;

{ utils_$find_exposed_lts - lr's exposed segment in bb, or nil: on the
  block's list (lir_main_c86 0; the hints cleared), else on the live
  range's list, kept in decreasing block order, from the hint when it
  is not past bb (and the one before it still leads to it) or from
  the one before the hint when that is before bb, else from the
  start; the hints left at the place found and the one before it.

  0x28530C, 0xEA bytes: the orders zero-extended words, compared
  signed as longwords. }

function utils_$find_exposed_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t;
var
  l: lts_ptr_t;
  prev: lts_ptr_t;
  ord: integer32;
begin
  if lir_main_c86 = 0 then begin
    l := bb^.exposed;
    while (l <> nil) and then (l^.lr <> lr) do
      l := l^.next_exposed;
    lr^.exposed_hint := nil;
    lr^.exposed_prev := nil;
    utils_$find_exposed_lts := l;
    return;
  end;
  ord := bb^.order;
  l := nil;
  prev := nil;
  if lir_main_c8d then begin
    if (lr^.exposed_hint <> nil) and then
       (lr^.exposed_hint^.bb^.order >= ord) then begin
      l := lr^.exposed_hint;
      prev := lr^.exposed_prev;
      if (prev <> nil) and then (prev^.next_exposed <> l) then
        l := nil;
    end
    else if (lr^.exposed_prev <> nil) and then
            (lr^.exposed_prev^.bb^.order > ord) then begin
      l := lr^.exposed_prev;
      prev := nil;
    end;
  end;
  if l = nil then begin
    l := lr^.exposed;
    prev := nil;
  end;
  while (l <> nil) and then (l^.bb^.order > ord) do begin
    prev := l;
    l := l^.next_exposed;
  end;
  lr^.exposed_hint := l;
  lr^.exposed_prev := prev;
  if (l <> nil) and then (l^.bb <> bb) then
    l := nil;
  utils_$find_exposed_lts := l;
end;

{ utils_$find_final_lts - as utils_$find_exposed_lts for the final
  lists (the live range's kept in increasing block order).

  0x2853F6, 0xEA bytes. }

function utils_$find_final_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t;
var
  l: lts_ptr_t;
  prev: lts_ptr_t;
  ord: integer32;
begin
  if lir_main_c86 = 0 then begin
    l := bb^.finals;
    while (l <> nil) and then (l^.lr <> lr) do
      l := l^.next_final;
    lr^.final_hint := nil;
    lr^.final_prev := nil;
    utils_$find_final_lts := l;
    return;
  end;
  ord := bb^.order;
  l := nil;
  prev := nil;
  if lir_main_c8d then begin
    if (lr^.final_hint <> nil) and then
       (lr^.final_hint^.bb^.order <= ord) then begin
      l := lr^.final_hint;
      prev := lr^.final_prev;
      if (prev <> nil) and then (prev^.next_final <> l) then
        l := nil;
    end
    else if (lr^.final_prev <> nil) and then
            (lr^.final_prev^.bb^.order < ord) then begin
      l := lr^.final_prev;
      prev := nil;
    end;
  end;
  if l = nil then begin
    l := lr^.finals;
    prev := nil;
  end;
  while (l <> nil) and then (l^.bb^.order < ord) do begin
    prev := l;
    l := l^.next_final;
  end;
  lr^.final_hint := l;
  lr^.final_prev := prev;
  if (l <> nil) and then (l^.bb <> bb) then
    l := nil;
  utils_$find_final_lts := l;
end;

{ utils_$put_lts_on_exposed_list - lts on its block's exposed list
  (first), or on its live range's in order (lir_main_c86 1: after the
  place utils_$find_exposed_lts leaves; bug_check when one is there
  already); bug_check when it is exposed already.

  0x2854E0, 0xDC bytes. }

procedure utils_$put_lts_on_exposed_list(
    lts: lts_ptr_t);
var
  lr: lr_ptr_t;
  p: lts_ptr_t;
  n: integer32;
begin
  lr := lts^.lr;
  if lts^.f2.exposed then begin
    n := lts^.f2.num;
    bug_check('UTILS_$put_lts_on_exposed_list:  indecent exposure %3ZWD.%2ZLD%$',
              lr^.num, n);
  end;
  if lir_main_c86 = 1 then begin
    if utils_$find_exposed_lts(lr, lts^.bb) <> nil then begin
      n := lts^.f2.num;
      bug_check('UTILS_$put_lts_on_exposed_list:  indecent exposure %3ZWD.%2ZLD%$',
                lr^.num, n);
    end;
    p := lr^.exposed_prev;
    if p = nil then begin
      lts^.next_exposed := lr^.exposed;
      lr^.exposed := lts;
    end
    else begin
      lts^.next_exposed := p^.next_exposed;
      p^.next_exposed := lts;
    end;
    lr^.exposed_hint := lts;
  end
  else begin
    lts^.next_exposed := lts^.bb^.exposed;
    lts^.bb^.exposed := lts;
    lr^.exposed_hint := nil;
    lr^.exposed_prev := nil;
  end;
  lts^.f2.exposed := true;
end;

{ utils_$put_lts_on_final_list - as utils_$put_lts_on_exposed_list for
  the final lists; final and first_in_bb set.

  0x2855FC, 0xDE bytes: the two flags by one `or.w #0x50' on +2. }

procedure utils_$put_lts_on_final_list(
    lts: lts_ptr_t);
var
  lr: lr_ptr_t;
  p: lts_ptr_t;
  n: integer32;
begin
  lr := lts^.lr;
  if lts^.f2.final then begin
    n := lts^.f2.num;
    bug_check('UTILS_$put_lts_on_final_list:  already final %3ZWD.%2ZLD%$',
              lr^.num, n);
  end;
  if lir_main_c86 = 1 then begin
    if utils_$find_final_lts(lr, lts^.bb) <> nil then begin
      n := lts^.f2.num;
      bug_check('UTILS_$put_lts_on_final_list:  already final %3ZWD.%2ZLD%$',
                lr^.num, n);
    end;
    p := lr^.final_prev;
    if p = nil then begin
      lts^.next_final := lr^.finals;
      lr^.finals := lts;
    end
    else begin
      lts^.next_final := p^.next_final;
      p^.next_final := lts;
    end;
    lr^.final_hint := lts;
  end
  else begin
    lts^.next_final := lts^.bb^.finals;
    lts^.bb^.finals := lts;
    lr^.final_hint := nil;
    lr^.final_prev := nil;
  end;
  lts^.f2.first_in_bb := true;
  lts^.f2.final := true;
end;

{ utils_$find_last_lts_in_bb - lr's first segment in bb (nil when it
  has none there), prev the last one before it: along the live
  range's segments (in block order) from the exposed list's previous
  hint when it is before bb, or from the final hint when it is not
  past bb, else from the first.

  0x285714, 0xAA bytes. }

function utils_$find_last_lts_in_bb(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    var prev: lts_ptr_t): lts_ptr_t;
var
  l: lts_ptr_t;
  p: lts_ptr_t;
  ord: integer32;
begin
  ord := bb^.order;
  p := nil;
  if lir_main_c8d then begin
    if (lr^.exposed_prev <> nil) and then
       (lr^.exposed_prev^.bb^.order < ord) then begin
      p := lr^.exposed_prev;
      l := p^.next;
    end
    else if (lr^.final_hint <> nil) and then
            (lr^.final_hint^.bb^.order <= ord) then begin
      p := lr^.final_hint;
      l := p^.next;
    end;
  end;
  if p = nil then
    l := lr^.ltss;
  while l <> nil do
    if l^.bb^.order < ord then begin
      p := l;
      l := l^.next;
    end
    else begin
      if l^.bb^.order <> ord then
        l := nil;
      exit;
    end;
  prev := p;
  utils_$find_last_lts_in_bb := l;
end;

{ utils_$get_new_lts - a new segment of lr in bb
  (lir_$new_lifetime_segment), put in the live range's list before
  its segments in bb (after them with at_end); for a complex live
  range the first in the block when nothing of the live range is
  before it there, the next one then no longer the first.

  0x2857BE, 0xDA bytes: first_in_bb from `sne', `lsr.b #7', `lsl.b
  #6', `andi.b #-65; or.b'. }

function utils_$get_new_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    at_end: boolean): lts_ptr_t;
var
  new: lts_ptr_t;
  l: lts_ptr_t;
  p: lts_ptr_t;
  ord: integer32;
begin
  new := lir_$new_lifetime_segment(lr);
  new^.bb := bb;
  l := utils_$find_last_lts_in_bb(lr, bb, p);
  if at_end then begin
    ord := bb^.order;
    while l <> nil do begin
      if l^.bb^.order > ord then
        exit;
      p := l;
      l := l^.next;
    end;
  end;
  if p = nil then begin
    new^.next := lr^.ltss;
    lr^.ltss := new;
  end
  else begin
    new^.next := p^.next;
    p^.next := new;
  end;
  if lr^.id <> 0 then begin
    if p <> nil then
      new^.f2.first_in_bb := p^.bb <> new^.bb
    else
      new^.f2.first_in_bb := true;
    if new^.next <> nil then
      if new^.next^.bb = new^.bb then
        new^.next^.f2.first_in_bb := false;
  end;
  utils_$get_new_lts := new;
end;

{ utils_$get_exposed_lts - lr's exposed segment in bb, made (at the end
  of the block's) and put on the exposed list, the hints valid
  meanwhile, when there is none (created); nil for a nil live range.

  0x285898, 0x72 bytes. }

function utils_$get_exposed_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    var created: boolean): lts_ptr_t;
var
  l: lts_ptr_t;
  saved: boolean;
begin
  if lr = nil then begin
    utils_$get_exposed_lts := nil;
    return;
  end;
  l := utils_$find_exposed_lts(lr, bb);
  if l = nil then begin
    saved := lir_main_c8d;
    lir_main_c8d := true;
    l := utils_$get_new_lts(lr, bb, true);
    utils_$put_lts_on_exposed_list(l);
    lir_main_c8d := saved;
    created := true;
  end
  else
    created := false;
  utils_$get_exposed_lts := l;
end;

{ utils_$get_final_lts - lr's final segment in bb, made (before the
  block's others) and put on the final list when there is none; the
  exposed hints cleared when the hints were not valid.

  0x28590A, 0x7C bytes. }

function utils_$get_final_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    var created: boolean): lts_ptr_t;
var
  l: lts_ptr_t;
  saved: boolean;
begin
  if lr = nil then begin
    utils_$get_final_lts := nil;
    return;
  end;
  l := utils_$find_final_lts(lr, bb);
  if l = nil then begin
    saved := lir_main_c8d;
    if not saved then begin
      lir_main_c8d := true;
      lr^.exposed_hint := nil;
      lr^.exposed_prev := nil;
    end;
    l := utils_$get_new_lts(lr, bb, false);
    utils_$put_lts_on_final_list(l);
    lir_main_c8d := saved;
    created := true;
  end
  else
    created := false;
  utils_$get_final_lts := l;
end;

{ utils_$compare_birthpoints - the same segment and offset, and a
  segment or the same unique live range; or both with the same base.

  0x285986, 0x70 bytes: the first two compares by `seq; and.b'. }

function utils_$compare_birthpoints(
    in a: utils_$birthpoint_t;
    in b: utils_$birthpoint_t): boolean;
begin
  if (a.lts = b.lts) and (a.offset = b.offset) then
    if (a.lts <> nil) or ((a.lr <> nil) and (a.lr = b.lr)) then begin
      utils_$compare_birthpoints := true;
      return;
    end;
  utils_$compare_birthpoints := a.has_base and b.has_base
                                and (a.base = b.base);
end;

{ unique_input - whether instr's reading operands all have the same
  canonical birthpoint (res the first; nil and false when none reads
  or they differ, or when this is already inside such a comparison).

  0x2859F6, 0xC4 bytes, internal (the caller's A5): the birthpoints in
  the frame (-24, -48); the first one's computed once (D2). }

function unique_input(
    instr: instr_ptr_t;
    follow: integer;
    var res: opnd_ptr_t): boolean; options(val_param); internal;
var
  have_first: boolean;
  k: integer32;
  bp2: utils_$birthpoint_t;
  bp1: utils_$birthpoint_t;
begin
  have_first := false;
  res := nil;
  for k := 1 to instr^.h.nopnds do
    if instr^.opnds[k].h.read then begin
      if res = nil then
        res := addr(instr^.opnds[k])
      else begin
        if in_unique then begin
          res := nil;
          unique_input := false;
          return;
        end;
        in_unique := true;
        if not have_first then begin
          have_first := true;
          utils_$get_canonical_birthpoint(res^.lts, follow, bp1);
        end;
        utils_$get_canonical_birthpoint(instr^.opnds[k].lts, follow, bp2);
        in_unique := false;
        if not utils_$compare_birthpoints(bp1, bp2) then begin
          res := nil;
          unique_input := false;
          return;
        end;
      end;
    end;
  unique_input := res <> nil;
end;

{ utils_$get_canonical_birthpoint - from lts back to the segment that
  gave it its value: a unique-valued live range ends the walk (its
  exposed segment's definition, or nil); a segment read first goes to
  its definition (l44), nil when there is none; through copies (202)
  whose inputs agree (unless the walk must keep to memory homes and
  the copy changes live range); through a tied first result; with
  follow bit 1 through a load of well-behaved memory (remembered) and
  a store's source (the mate of an odd fp register pair); with bit 2
  through a join's modified operand of the same live range; with bit 0
  through adds and subtracts of immediates (the offset kept).  A
  memory-home walk does not end in a register-free live range when a
  load gave a memory birthpoint with pair constraints.  A definition
  by a load of an address (75) of an immediate gives the base.

  0x285ABA, 0x400 bytes: bp cleared first; memory_only (D4) the live
  range's +3 bit 7 clear and neither fp_reg nor ip_reg (`andi.w
  #-16384'); the segment at -8, the load's at -16; class 16 and 21 by
  the section instruction_attributes (`movea.l #0x2B8C3C'). }

procedure utils_$get_canonical_birthpoint(
    lts: lts_ptr_t;
    follow: integer;
    var bp: utils_$birthpoint_t);
label
  10, 20, 30, 99;
var
  memory_only: boolean;
  mem: lts_ptr_t;
  cur: lts_ptr_t;
  lr: lr_ptr_t;
  d: opnd_ptr_t;
  i: instr_ptr_t;
  src: opnd_ptr_t;
  k: integer32;
  op: opnd_ptr_t;
  r: opnd_ptr_t;
  j: instr_ptr_t;
  n: integer32;
begin
  bp.offset := 0;
  bp.lts := nil;
  bp.lr := nil;
  bp.has_base := false;
  bp.base := 0;
  lr := lts^.lr;
  memory_only := (not lr^.f2.b3_7)
                 and ([rrp$fp_reg, rrp$ip_reg] * lr^.rrp = []);
  mem := nil;
  cur := lts;
  repeat
    lr := cur^.lr;
    if rrp$unique_value in lr^.rrp then begin
      bp.lr := lr;
      if (cur^.refs = nil) or else cur^.refs^.h.read then
        if cur^.f2.exposed then
          cur := cur^.l44
        else
          cur := nil;
      bp.lts := cur;
      goto 99;
    end;
    d := cur^.refs;
    if d = nil then
      goto 30;
    if d^.h.read then begin
      if (cur^.l44 = nil) or not cur^.f2.exposed then
        goto 30;
      cur := cur^.l44;
      next;
    end;
    i := utils_ins_$operands_instruction(d);
    if i^.opc = 202 then
      if unique_input(i, follow, src) then begin
        if not memory_only and (cur^.lr <> src^.lts^.lr) then begin
          bp.lts := cur;
          goto 20;
        end;
        cur := src^.lts;
        next;
      end;
    if i^.h.b0_6 then begin
      cur := i^.opnds[d^.h.num - 1].lts;
      next;
    end;
    if not (rrp$modify in cur^.rrp) and ((follow & 2) <> 0)
       and (instruction_attributes[i^.opc].class = class$load) then begin
      mem := cur;
      src := nil;
      for k := i^.h.nopnds downto 1 do begin
        op := addr(i^.opnds[k]);
        if (op^.h.kind in [operand$argument_block_memory..operand$well_behaved_memory])
           and op^.h.read then begin
          src := op;
          exit;
        end;
      end;
      if src = nil then
        goto 10;
      if src^.h.kind <> operand$well_behaved_memory then
        goto 10;
      cur := src^.lts;
      next;
    end;
    if (d^.h.kind = operand$well_behaved_memory) and not memory_only
       and ((follow & 2) <> 0)
       and (instruction_attributes[i^.opc].class = class$store) then begin
      if (rrp$fp_reg_odd_only in lts^.rrp)
         and ((instruction_attributes[i^.opc].w18 & 7) = 3) then
        cur := opnd_ptr_t(lir_utils_$find_mate_operand(addr(i^.opnds[1])))^.lts
      else
        cur := i^.opnds[2].lts;
      next;
    end;
    if (instruction_attributes[i^.opc].class = class$trap_cond)
       and ((follow & 4) <> 0) and d^.h.modify then
      if i^.opnds[d^.h.num - 1].h.intend_to_modify then
        if cur^.lr = i^.opnds[d^.h.num - 1].lts^.lr then begin
          cur := i^.opnds[d^.h.num - 1].lts;
          next;
        end;
    if (i^.h.nopnds = 4) and (d^.h.num = 3) and ((follow & 1) <> 0) then begin
      if (i^.opc = 79) and (i^.opnds[1].h.kind = operand$immediate)
         and (i^.opnds[2].h.kind = operand$ip_reg) then begin
        cur := i^.opnds[2].lts;
        bp.offset := bp.offset + i^.opnds[1].value;
        next;
      end;
      if (i^.opc = 81) and (i^.opnds[1].h.kind = operand$immediate)
         and (i^.opnds[2].h.kind = operand$ip_reg) then begin
        cur := i^.opnds[2].lts;
        bp.offset := bp.offset - i^.opnds[1].value;
        next;
      end;
    end;
10:
    bp.lts := cur;
20:
    if not memory_only and (mem <> nil)
       and ([rrp$fp_reg_even_only, rrp$fp_reg_odd_only] * mem^.rrp <> []) then
      if (not bp.lts^.lr^.f2.b3_7)
         and ([rrp$fp_reg, rrp$ip_reg] * bp.lts^.lr^.rrp = []) then begin
        if mem = nil then begin
          n := lts^.f2.num;
          bug_check('UTILS_$GET_CANONICAL_BIRTHPOINT -- shouldn''t return memory birthpoint for LTS %3ZWD.%2ZLD%$',
                    lts^.lr^.num, n);
        end;
        bp.lts := mem;
      end;
    if bp.lts <> nil then begin
      r := bp.lts^.refs;
      if r^.h.write then begin
        j := utils_ins_$operands_instruction(r);
        if (j^.opc = 75) and (j^.opnds[1].h.kind = operand$immediate) then begin
          bp.base := j^.opnds[1].value + bp.offset;
          bp.has_base := true;
        end;
      end;
    end;
    goto 99;
  until false;
30:
  bp.lts := nil;
  bp.lr := nil;
99:
end;

{ utils_$set_instruction_opcode - the opcode and its class (+40).

  0x285F16, 0x44 bytes. }

procedure utils_$set_instruction_opcode(
    instr: instr_ptr_t;
    opc: integer);
begin
  instr^.opc := opc;
  instr^.class := chr(instruction_attributes[opc].class);
end;

{ copy_instr_template_to_bb - a copy of template in bb before before
  (at the end for nil): room for its operands (one more for a call or
  an SVC, class 2 or 20, and for opcode 129) and its alias descriptor,
  copied; the header, source position and number copied, the opcode
  set; a register or memory operand's link cleared and its segment
  field given the segment's live range (the copy is completed later),
  a flow graph edge's a new edge from bb to its target; the extra
  operands copied as they are.

  0x285F5A, 0x1CE bytes, internal: mrh_$alloc(lir_main_heap^, size);
  the classes by `btst' in #0x100004; the descriptor five longwords. }

function copy_instr_template_to_bb(
    template: instr_ptr_t;
    bb: bb_ptr_t;
    before: instr_ptr_t): instr_ptr_t; options(val_param); internal;
type
  desc_ptr_t = ^alias_$desc_t;
  heap_ptr_t = ^mrh_$heap_t;
var
  n: integer32;
  size: integer;
  new: instr_ptr_t;
  p: integer32;
  k: integer32;
  op: opnd_ptr_t;
  e: fg_edge_ptr_t;
  cls: integer;
begin
  n := template^.h.nopnds;
  cls := instruction_attributes[template^.opc].class;
  if cls in [class$call, class$svc] then
    n := n + 1;
  if template^.opc = 129 then
    n := n + 1;
  size := n * 12 + 44;
  if template^.h.b2_7 then
    size := size + 24;
  p := integer32(mrh_$alloc(heap_ptr_t(lir_main_heap)^, size));
  if template^.h.b2_7 then begin
    desc_ptr_t(p)^ := desc_ptr_t(integer32(template) - 24)^;
    p := p + 24;
  end;
  new := instr_ptr_t(p);
  new^.h := template^.h;
  new^.l32 := template^.l32;
  new^.num := template^.num;
  new^.bb := bb;
  utils_$set_instruction_opcode(new, template^.opc);
  new^.prev := before^.prev;
  if new^.prev = nil then
    bb^.first := new
  else
    new^.prev^.next := new;
  new^.next := before;
  if before = nil then
    bb^.last := new
  else
    before^.prev := new;
  for k := 1 to template^.h.nopnds do begin
    new^.opnds[k] := template^.opnds[k];
    op := addr(new^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      op^.link := nil;
      op^.ptr := op^.lts^.lr;
    end
    else if op^.h.kind = operand$flow_graph_edge then begin
      e := op^.ptr;
      op^.ptr := lir_$add_flow_graph_edge(bb, e^.target);
    end;
  end;
  for k := template^.h.nopnds + 1 to n do
    new^.opnds[k] := template^.opnds[k];
  copy_instr_template_to_bb := new;
end;

{ utils_$copy_instr_template_to_bb_end - before the branches and jumps
  (classes 1, 5, 6) that end bb, the last instruction itself at
  least.

  0x286128, 0x62 bytes: `moveq #98; btst'. }

function utils_$copy_instr_template_to_bb_end(
    template: instr_ptr_t;
    bb: bb_ptr_t): instr_ptr_t;
var
  before: instr_ptr_t;
  cls: integer;
begin
  before := bb^.last;
  while before^.prev <> nil do begin
    cls := instruction_attributes[before^.prev^.opc].class;
    if not (cls in [class$branch, class$fp_branch, class$jump]) then
      exit;
    before := before^.prev;
  end;
  utils_$copy_instr_template_to_bb_end :=
    copy_instr_template_to_bb(template, bb, before);
end;

{ utils_$copy_instr_template_to_bb_head - after the join birthpoints
  (203) and 199s that begin bb.

  0x28618A, 0x50 bytes. }

function utils_$copy_instr_template_to_bb_head(
    template: instr_ptr_t;
    bb: bb_ptr_t): instr_ptr_t;
var
  before: instr_ptr_t;
begin
  before := bb^.first;
  while (before <> nil) and then
        ((before^.opc = 203) or (before^.opc = 199)) do
    before := before^.next;
  utils_$copy_instr_template_to_bb_head :=
    copy_instr_template_to_bb(template, bb, before);
end;

{ get_last_lts_in_bb - lr's final segment in bb, else its segment
  there (the final hints set to it when the lists are by block and the
  hints valid).

  0x2861DA, 0x56 bytes, internal. }

function get_last_lts_in_bb(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t; options(val_param); internal;
var
  l: lts_ptr_t;
  prev: lts_ptr_t;
begin
  l := utils_$find_final_lts(lr, bb);
  if l = nil then begin
    l := utils_$find_last_lts_in_bb(lr, bb, prev);
    if lir_main_c8d and (lir_main_c86 = 0) then begin
      lr^.final_prev := prev;
      lr^.final_hint := l;
    end;
  end;
  get_last_lts_in_bb := l;
end;

{ utils_$complete_copied_instr - a copied instruction's register and
  memory operands given segments in its block: a reader the live
  range's last segment there, else a final segment (when made, its
  definition located and linked and the segment exposed); a writer a
  new final segment (the old one off the final list); the operand's
  properties or-ed into the segment's, the operand put last on the
  segment's refs.

  0x286230, 0x14E bytes: `clr.w; move.b (33,A2); or.w' the properties.
  }

procedure utils_$complete_copied_instr(
    instr: instr_ptr_t);
var
  k: integer32;
  op: opnd_ptr_t;
  l: lts_ptr_t;
  d: lts_ptr_t;
  f: lts_ptr_t;
  created: boolean;
  p: opnd_ptr_t;
begin
  for k := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      op^.link := nil;
      if op^.h.read then begin
        l := get_last_lts_in_bb(op^.ptr, instr^.bb);
        if l <> nil then
          op^.lts := l
        else begin
          op^.lts := utils_$get_final_lts(op^.ptr, instr^.bb, created);
          if created then begin
            d := utils_$locate_definition(op^.lts^.lr, instr^.bb);
            if d <> nil then begin
              op^.lts^.l44 := d;
              op^.lts^.l28 := d^.l28;
              d^.l28 := op^.lts;
            end;
            utils_$put_lts_on_exposed_list(op^.lts);
          end;
        end;
      end
      else begin
        f := utils_$find_final_lts(op^.ptr, instr^.bb);
        if f <> nil then
          utils_$remove_lts_from_final_list(f);
        op^.lts := utils_$get_final_lts(op^.ptr, instr^.bb, created);
      end;
      op^.lts^.rrp := op^.lts^.rrp
                      + rrp$set_t(integer(ut_opnd_bytes_ptr_t(op)^.rrp));
      if op^.lts^.refs = nil then
        op^.lts^.refs := op
      else begin
        p := op^.lts^.refs;
        while p^.link <> nil do
          p := p^.link;
        p^.link := op;
      end;
    end;
  end;
end;

{ utils_$complete_copied_instr_at_bb_head - as utils_$complete_copied_
  instr for an instruction at the head of its block, the operands from
  the last: a reader the live range's exposed segment (when made, its
  definition located and linked, and put on the final list when the
  operand's live range's +3 bit 6 is set; when the segment is a join
  birthpoint's, the operand joins the join's operand 2 instead); a
  writer takes over the block's exposed segment (a join birthpoint's
  segment, the join excised; else unlinked from its definition and
  taken off the exposed list) or a new segment at the block's end
  (put on the final list when it is the first in the block); the
  operand put first on the segment's refs.

  0x28637E, 0x1E6 bytes: the made segment's test shares the new
  segment's tail (`bra' to its `beq'); the join's segment loses write
  and modify (`andi.w #-13'). }

procedure utils_$complete_copied_instr_at_bb_head(
    instr: instr_ptr_t);
label
  10, 20;
var
  k: integer32;
  op: opnd_ptr_t;
  l: lts_ptr_t;
  d: lts_ptr_t;
  p: lts_ptr_t;
  j: instr_ptr_t;
  created: boolean;
begin
  for k := instr^.h.nopnds downto 1 do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      if op^.h.read then begin
        l := utils_$get_exposed_lts(op^.ptr, instr^.bb, created);
        if created then begin
          d := utils_$locate_definition(op^.ptr, instr^.bb);
          if d <> nil then begin
            l^.l44 := d;
            l^.l28 := d^.l28;
            d^.l28 := l;
          end;
          if lts_ptr_t(op^.ptr)^.f2.first_in_bb then
            utils_$put_lts_on_final_list(l);
          goto 10;
        end;
        if l^.refs <> nil then begin
          j := utils_ins_$operands_instruction(l^.refs);
          if j^.opc = 203 then begin
            op^.lts := j^.opnds[2].lts;
            op^.link := j^.opnds[2].link;
            j^.opnds[2].link := op;
            goto 20;
          end;
        end;
      end
      else begin
        l := utils_$find_exposed_lts(op^.ptr, instr^.bb);
        if l <> nil then begin
          if l^.refs <> nil then begin
            j := utils_ins_$operands_instruction(l^.refs);
            if j^.opc = 203 then begin
              l := j^.opnds[2].lts;
              l^.refs := j^.opnds[2].link;
              utils_$excise_instruction_cleanly(j, false);
              l^.rrp := l^.rrp - [rrp$modify, rrp$write];
              goto 10;
            end;
          end;
          d := l^.l44;
          if d <> nil then begin
            if d^.l28 = l then
              d^.l28 := l^.l28
            else begin
              p := d^.l28;
              while (p <> nil) and then (p^.l28 <> l) do
                p := p^.l28;
              if p <> nil then
                p^.l28 := l^.l28;
            end;
            l^.l44 := nil;
          end;
          utils_$remove_lts_from_exposed_list(l);
        end
        else begin
          l := utils_$get_new_lts(op^.ptr, instr^.bb, true);
          if l^.f2.first_in_bb then
            utils_$put_lts_on_final_list(l);
        end;
      end;
10:
      op^.lts := l;
      op^.link := l^.refs;
      l^.refs := op;
20:
      op^.lts^.rrp := op^.lts^.rrp
                      + rrp$set_t(integer(ut_opnd_bytes_ptr_t(op)^.rrp));
    end;
  end;
end;

{ look_for_path - from bb `to' back through the predecessors (but not
  through a block's edge from itself): true at target_bb, false at
  from; target_bb's mark146 path_mark (false) or path_mark + 1 (true)
  answers at once; a block is marked with its answer.

  0x286564, 0x8C bytes, internal (the caller's A5). }

function look_for_path(
    from: bb_ptr_t;
    to_bb: bb_ptr_t): boolean; options(val_param); internal;
var
  e: fg_edge_ptr_t;
begin
  look_for_path := false;
  if to_bb = from then
    return;
  if to_bb = target_bb then begin
    look_for_path := true;
    return;
  end;
  if target_bb^.mark146 = path_mark then
    return;
  if path_mark + 1 = target_bb^.mark146 then begin
    look_for_path := true;
    return;
  end;
  e := to_bb^.preds;
  while (e <> nil) and then (e^.source <> to_bb) do begin
    if look_for_path(from, e^.source) then begin
      to_bb^.mark146 := path_mark + 1;
      look_for_path := true;
      return;
    end;
    e := e^.next_pred;
  end;
  to_bb^.mark146 := path_mark;
end;

{ no_path_through_target_bb - utils_$remove_spurious_active_on_exit's
  test of a use: not look_for_path(a's block, b's block).

  0x2865F0, 0x36 bytes (passed by address). }

function no_path_through_target_bb(
    a: lts_ptr_t;
    b: lts_ptr_t): boolean; options(val_param);
begin
  no_path_through_target_bb := not look_for_path(a^.bb, b^.bb);
end;

{ utils_$remove_spurious_active_on_exit - bb's final segments that are
  not live on exit taken off its final list: written ones that reach
  nothing, and read-only ones none of whose uses has a path through bb
  (bug_check unless the lists are by block).

  0x286626, 0xA0 bytes: the marks two at a time from the routine's
  +180 when first needed (`addq.l #2'). }

procedure utils_$remove_spurious_active_on_exit(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t); options(val_param);
var
  l: lts_ptr_t;
  n: lts_ptr_t;
begin
  if lir_main_c86 <> 0 then
    bug_check('UTILS_$REMOVE_SPURIOUS_ACTIVE_ON_EXIT: efl must be on BB%$');
  path_mark := 0;
  target_bb := bb;
  l := bb^.finals;
  while l <> nil do begin
    n := l^.next_final;
    if [rrp$modify, rrp$write] * l^.rrp <> [] then begin
      if (l^.l28 = nil) and (l^.l44 = nil) then
        utils_$remove_lts_from_final_list(l);
    end
    else begin
      if path_mark = 0 then begin
        rtn^.marks := rtn^.marks + 2;
        path_mark := rtn^.marks - 1;
      end;
      if (l^.l44 = nil) or else
         utils_$apply_func_to_all_uses(rtn, addr(no_path_through_target_bb),
                                       l^.l44) then
        utils_$remove_lts_from_final_list(l);
    end;
    l := n;
  end;
end;

{ utils_$strip_extraneous_modifies - each result operand (by the
  opcode's attributes) that is a register meaning to modify, whose
  attribute bits 7..6 are 0 and whose live range's +3 bit 7 is clear:
  intend_to_modify dropped (and on the mate of a pair); the last
  result then a write instead of a modify (bug_check when it was not a
  modify), its mate's too.  Every instruction's block set on the way.

  0x286700, 0x19A bytes: the results' attribute bytes from +6, 4
  apart; kinds 1..6 by `btst' in #126. }

procedure utils_$strip_extraneous_modifies(
    rtn: rtn_ptr_t);
var
  bb: bb_ptr_t;
  i: instr_ptr_t;
  attr: ut_attr_ptr_t;
  k: integer32;
  nr: integer32;
  op: opnd_ptr_t;
  m: opnd_ptr_t;
  dst: opnd_ptr_t;
begin
  bb := rtn^.bbs;
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      i^.bb := bb;
      attr := addr(instruction_attributes[i^.opc]);
      for k := 1 to instruction_attributes[i^.opc].nresults do begin
        op := addr(i^.opnds[k]);
        if (op^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical])
           and op^.h.intend_to_modify
           and (rshft(attr^[6 + 4 * (k - 1)], 6) = 0)
           and (not op^.lts^.lr^.f2.b3_7) then begin
          if op^.h.kind = operand$fp_reg_pair then begin
            m := lir_utils_$find_mate_operand(op);
            m^.lts^.rrp := m^.lts^.rrp - [rrp$intend_to_modify];
            m^.h.intend_to_modify := false;
          end;
          op^.lts^.rrp := op^.lts^.rrp - [rrp$intend_to_modify];
          op^.h.intend_to_modify := false;
          nr := instruction_attributes[i^.opc].nresults;
          dst := addr(i^.opnds[nr]);
          if not dst^.h.modify then
            bug_check('UTILS_$STRIP_EXTRANEOUS_MODIFIES -- destination is not a modify access%$');
          if op^.h.kind = operand$fp_reg_pair then begin
            m := lir_utils_$find_mate_operand(dst);
            if not m^.h.modify then
              bug_check('UTILS_$STRIP_EXTRANEOUS_MODIFIES -- mate destination is not a modify access%$');
            m^.lts^.rrp := m^.lts^.rrp - [rrp$modify] + [rrp$write];
            m^.h.modify := false;
            m^.h.write := true;
          end;
          dst^.lts^.rrp := dst^.lts^.rrp - [rrp$modify] + [rrp$write];
          dst^.h.modify := false;
          dst^.h.write := true;
        end;
      end;
      i := i^.next;
    end;
    bb := bb^.next;
  end;
end;

{ jbi_input_exists - whether lts (an exposed join segment; true for
  nil) has an input from the join instruction instr.

  0x286930, 0x38 bytes, internal, no frame: instr at (4,SP), lts at
  (8,SP). }

function jbi_input_exists(
    instr: instr_ptr_t;
    lts: lts_ptr_t): boolean; options(val_param); internal;
var
  j: ut_jbi_ptr_t;
begin
  jbi_input_exists := true;
  if lts = nil then
    return;
  if not lts^.f2.exposed then begin
    jbi_input_exists := false;
    return;
  end;
  j := lts^.l44;
  while j <> nil do begin
    if j^.instr = instr then
      return;
    j := j^.next;
  end;
  jbi_input_exists := false;
end;

{ utils_$drop_jbi_input - j off its join's inputs; a join left with one
  input excised, its segment then defined by that input directly
  (exposed, not written; its transparent bit cleared when it is the
  first in its block and there are bit vectors).

  0x286968, 0xBA bytes. }

procedure utils_$drop_jbi_input;
var
  i: instr_ptr_t;
  q: ut_jbi_ptr_t;
  l: lts_ptr_t;
  input: lts_ptr_t;
begin
  i := j^.instr;
  if ut_jbi_ptr_t(i^.opnds[3].link) = j then
    i^.opnds[3].link := opnd_ptr_t(j^.next_op)
  else begin
    q := ut_jbi_ptr_t(i^.opnds[3].link);
    while q^.next_op <> j do
      q := q^.next_op;
    q^.next_op := j^.next_op;
  end;
  i := j^.instr;
  q := ut_jbi_ptr_t(i^.opnds[3].link);
  if q <> nil then
    if q^.next_op = nil then begin
      l := i^.opnds[2].lts;
      input := q^.lts;
      utils_$excise_instruction_cleanly(i, false);
      l^.refs := l^.refs^.link;
      l^.rrp := l^.rrp - [rrp$modify, rrp$write];
      utils_$move_definition(l, input, true);
      utils_$put_lts_on_exposed_list(l);
      if l^.f2.first_in_bb and (lir_main_c84 > 0) then
        bv_$clear(l^.bb^.transparent, l^.lr);
    end;
end;

{ utils_$move_definition - the exposed segments lts reached now reached
  by def (appended to def's), lts's join inputs moved to def (dropped
  when def has one from the same join); with relink lts itself reached
  by def.

  0x286A22, 0xD6 bytes: the inputs' test jbi_input_exists(input's
  join, def). }

procedure utils_$move_definition(
    lts: lts_ptr_t;
    def: lts_ptr_t;
    relink: boolean);
var
  p: lts_ptr_t;
  j: ut_jbi_ptr_t;
  n: ut_jbi_ptr_t;
begin
  if def <> nil then
    if def^.l28 = nil then
      def^.l28 := lts^.l28
    else begin
      p := def^.l28;
      while p^.l28 <> nil do
        p := p^.l28;
      p^.l28 := lts^.l28;
    end;
  p := lts^.l28;
  lts^.l28 := nil;
  while p <> nil do begin
    p^.l44 := def;
    p := p^.l28;
  end;
  j := lts^.l44;
  lts^.l44 := nil;
  while j <> nil do begin
    n := j^.next;
    if not jbi_input_exists(j^.instr, def) then begin
      j^.next := def^.l44;
      def^.l44 := j;
      j^.lts := def;
    end
    else
      utils_$drop_jbi_input(j);
    j := n;
  end;
  lts^.l28 := nil;
  if relink then begin
    lts^.l44 := def;
    if def <> nil then begin
      lts^.l28 := def^.l28;
      def^.l28 := lts;
    end
    else
      lts^.l44 := nil;
  end
  else
    lts^.l44 := nil;
end;

{ find_definition - lr's segment written in bb, else (bb marked: +19
  bit 1, and the walk's bounds by block order widened) in the unmarked
  predecessors', depth first; nil.

  0x286AF8, 0x90 bytes, internal (the caller's A5): the orders
  compared unsigned (`bls', `bcc'). }

function find_definition(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t; options(val_param); internal;
var
  l: lts_ptr_t;
  e: fg_edge_ptr_t;
begin
  l := utils_$find_final_lts(lr, bb);
  if l <> nil then
    if [rrp$modify, rrp$write] * l^.rrp <> [] then begin
      find_definition := l;
      return;
    end;
  bb^.f.b19_1 := true;
  if lo_bb = nil then begin
    lo_bb := bb;
    hi_bb := bb;
  end
  else begin
    if lo_bb^.order > bb^.order then
      lo_bb := bb;
    if hi_bb^.order < bb^.order then
      hi_bb := bb;
  end;
  e := bb^.preds;
  while e <> nil do begin
    if not e^.source^.f.b19_1 then begin
      l := find_definition(lr, e^.source);
      if l <> nil then begin
        find_definition := l;
        return;
      end;
    end;
    e := e^.next_pred;
  end;
  find_definition := nil;
end;

{ utils_$locate_definition - lr's segment written in one of the blocks
  on bb's l54 list, else find_definition from bb's predecessors (the
  marks cleared after, along +114 from the lowest block to the
  highest); the hints valid meanwhile; nil when lir_main_c8e is
  clear.

  0x286B88, 0xD2 bytes. }

function utils_$locate_definition(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t;
var
  saved: boolean;
  b: bb_ptr_t;
  l: lts_ptr_t;
  prev: lts_ptr_t;
  r: lts_ptr_t;
  e: fg_edge_ptr_t;
begin
  if not lir_main_c8e then begin
    utils_$locate_definition := nil;
    return;
  end;
  saved := lir_main_c8d;
  if not saved then begin
    lir_main_c8d := true;
    lr^.final_hint := nil;
    lr^.final_prev := nil;
  end;
  b := bb^.l54;
  while b <> nil do begin
    l := utils_$find_last_lts_in_bb(lr, b, prev);
    if l <> nil then
      if [rrp$modify, rrp$write] * l^.rrp <> [] then begin
        lir_main_c8d := saved;
        utils_$locate_definition := l;
        return;
      end;
    b := b^.l54;
  end;
  lo_bb := nil;
  hi_bb := nil;
  r := nil;
  e := bb^.preds;
  while e <> nil do begin
    r := find_definition(lr, e^.source);
    if r <> nil then
      exit;
    e := e^.next_pred;
  end;
  b := lo_bb;
  while b <> nil do begin
    b^.f.b19_1 := false;
    if b = hi_bb then
      exit;
    b := b^.next114;
  end;
  lir_main_c8d := saved;
  utils_$locate_definition := r;
end;

{ utils_$find_join_bp - the join birthpoint (203) that defines lts
  (exposed, its first reference the join's), or nil.

  0x286C5A, 0x48 bytes. }

function utils_$find_join_bp(
    lts: lts_ptr_t): instr_ptr_t;
var
  i: instr_ptr_t;
begin
  utils_$find_join_bp := nil;
  if (lts^.refs <> nil) and lts^.f2.exposed then begin
    i := utils_ins_$operands_instruction(lts^.refs);
    if i^.opc = 203 then
      utils_$find_join_bp := i;
  end;
end;

{ utils_$add_birthpoint - def a definition of its live range's exposed
  segment in bb (bug_check when there is none): linked as its
  definition when it has neither a definition nor a join; else a join
  made when it has only a definition (another one: the old definition
  its first input, its transparent bit cleared with clear_transparent)
  and def added as an input unless it is one.

  0x286CA2, 0x12A bytes: the messages TRANS_'s; fg_utils_$insert_join_
  birthpoint(lr, bb), fg_utils_$add_jbi(join, segment). }

procedure utils_$add_birthpoint(
    def: lts_ptr_t;
    bb: bb_ptr_t;
    clear_transparent: boolean);
var
  lr: lr_ptr_t;
  l: lts_ptr_t;
  jbp: instr_ptr_t;
  d: lts_ptr_t;
  p: lts_ptr_t;
begin
  if def = nil then
    return;
  lr := def^.lr;
  l := utils_$find_exposed_lts(lr, bb);
  if l = nil then
    bug_check('TRANS_$add_birthpoint: no instance of LR %3ZWD in BB %3ZWD%$',
              lr^.num, bb^.num);
  jbp := utils_$find_join_bp(l);
  if (jbp = nil) and (l^.l44 = nil) then begin
    l^.l44 := def;
    l^.l28 := def^.l28;
    def^.l28 := l;
    return;
  end;
  if (jbp <> nil) and (l^.l44 <> nil) then
    bug_check('TRANS_$add_birthpoint: join/definition conflict LR %3ZWD, BB %3ZWD%$',
              lr^.num, bb^.num);
  if jbp = nil then begin
    d := l^.l44;
    if d = def then
      return;
    l^.l44 := nil;
    if d^.l28 = l then
      d^.l28 := l^.l28
    else begin
      p := d^.l28;
      while p^.l28 <> l do
        p := p^.l28;
      p^.l28 := l^.l28;
    end;
    jbp := fg_utils_$insert_join_birthpoint(lr, bb);
    if clear_transparent then
      bv_$clear(bb^.transparent, lr);
    fg_utils_$add_jbi(jbp, d);
  end;
  if not jbi_input_exists(jbp, def) then
    fg_utils_$add_jbi(jbp, def);
end;

{ add_use_def - the pair (x, y) added to the list (a new record of 30
  first when the first is full).

  0x286E4C, 0x6C bytes, internal (the caller's A5): the count a
  longword, the index its low word (`move.w (6,A0)', `lsl.w #3'). }

procedure add_use_def(
    var list: ut_use_def_ptr_t;
    x: lts_ptr_t;
    y: lts_ptr_t); options(val_param); internal;
var
  p: ut_use_def_ptr_t;
begin
  if list = nil then
    list := mrh_$alloc_fixed(use_def_heap)
  else if list^.count = 30 then begin
    p := mrh_$alloc_fixed(use_def_heap);
    p^.next := list;
    list := p;
  end;
  list^.count := list^.count + 1;
  list^.e[list^.count].x := x;
  list^.e[list^.count].y := y;
end;

{ consider_all_defs - the definitions that reach a use of orig, from
  lts back through the join birthpoints (each segment once a walk:
  mark), as pairs (definition, orig); false at a segment without
  references.

  0x286EB8, 0xD2 bytes, internal: the join's operand 3 must be its
  inputs (bug_check with the opcode's mnemonic, 12 characters). }

function consider_all_defs(
    var list: ut_use_def_ptr_t;
    lts: lts_ptr_t;
    orig: lts_ptr_t;
    mark: integer32): boolean; options(val_param); internal;
var
  i: instr_ptr_t;
  j: ut_jbi_ptr_t;
begin
  consider_all_defs := false;
  if lts = nil then
    return;
  if lts^.refs = nil then
    return;
  consider_all_defs := true;
  if lts^.mark = mark then
    return;
  lts^.mark := mark;
  i := utils_ins_$operands_instruction(lts^.refs);
  if i^.opc <> 203 then begin
    add_use_def(list, lts, orig);
    return;
  end;
  if i^.opnds[3].h.kind <> operand$join_birthpoint_inputs then
    bug_check('UTILS_$consider_all_defs:  operand 3 of inst %3ZWD:%3ZWD %a should be JBI%$',
              i^.bb^.num, i^.num, instruction_mnemonic[i^.opc], 12);
  j := ut_jbi_ptr_t(i^.opnds[3].link);
  while j <> nil do begin
    if not consider_all_defs(list, j^.lts, orig, mark) then begin
      consider_all_defs := false;
      return;
    end;
    j := j^.next_op;
  end;
end;

{ utils_$apply_func_to_all_defs - f applied to every (definition, lts)
  pair that reaches lts (through its join birthpoint, when it is
  defined by one, else from its exposed segment's definition); false
  when there is none or f answers false.

  0x286FDA, 0x134 bytes: a new mark from the routine's +180; the pairs
  in the use/def heap, released to its mark after; f called with
  `jsr (A3)'. }

function utils_$apply_func_to_all_defs(
    rtn: rtn_ptr_t;
    f: utils_$pair_func_t;
    lts: lts_ptr_t): boolean;
var
  l: lts_ptr_t;
  d: lts_ptr_t;
  i: instr_ptr_t;
  mark: integer32;
  m: mrh_$mark_t;
  list: ut_use_def_ptr_t;
  ok: boolean;
  k: integer32;
  n: integer32;
begin
  if (lts^.refs = nil) or lts^.f2.exposed then
    l := lts
  else begin
    i := utils_ins_$operands_instruction(lts^.refs);
    if i^.opc = 203 then
      l := i^.opnds[1].lts
    else
      l := lts;
  end;
  if not l^.f2.exposed then begin
    n := l^.f2.num;
    bug_check('UTILS_$apply_func_to_all_defs: expected exposed LTS %3ZWD.%2ZLD%$',
              l^.lr^.num, n);
  end;
  if l^.refs = nil then
    d := l^.l44
  else begin
    i := utils_ins_$operands_instruction(l^.refs);
    if i^.opc = 203 then
      d := i^.opnds[1].lts
    else
      d := l^.l44;
  end;
  if d = nil then begin
    utils_$apply_func_to_all_defs := false;
    return;
  end;
  rtn^.marks := rtn^.marks + 1;
  mark := rtn^.marks;
  m := mrh_$mark(use_def_heap);
  list := nil;
  if not consider_all_defs(list, d, lts, mark) then
    ok := false
  else begin
    ok := true;
    while ok and (list <> nil) do begin
      for k := 1 to list^.count do
        if not f^(list^.e[k].x, list^.e[k].y) then begin
          ok := false;
          exit;
        end;
      list := list^.next;
    end;
  end;
  mrh_$release_to_mark(use_def_heap, m);
  utils_$apply_func_to_all_defs := ok;
end;

{ consider_all_uses - the uses orig reaches from lts (its other
  references, the exposed segments it reaches and, through the joins
  it is an input of, theirs), as pairs (orig, use), each segment once
  a walk; true at a segment without references.

  0x287150, 0xBE bytes, internal: a join is marked on its operand 1's
  segment and followed into its operand 2's. }

function consider_all_uses(
    var list: ut_use_def_ptr_t;
    lts: lts_ptr_t;
    orig: lts_ptr_t;
    mark: integer32): boolean; options(val_param); internal;
var
  e: lts_ptr_t;
  n: lts_ptr_t;
  j: ut_jbi_ptr_t;
  jn: ut_jbi_ptr_t;
  i: instr_ptr_t;
begin
  consider_all_uses := true;
  if lts^.refs = nil then
    return;
  lts^.mark := mark;
  if lts <> orig then
    if lts^.refs^.link <> nil then
      add_use_def(list, orig, lts);
  if lts^.f2.final then begin
    e := lts^.l28;
    while e <> nil do begin
      n := e^.l28;
      if e^.mark <> mark then begin
        e^.mark := mark;
        add_use_def(list, orig, e);
      end;
      e := n;
    end;
    j := lts^.l44;
    while j <> nil do begin
      jn := j^.next;
      i := j^.instr;
      if i^.opnds[1].lts^.mark <> mark then begin
        i^.opnds[1].lts^.mark := mark;
        if not consider_all_uses(list, i^.opnds[2].lts, orig, mark) then begin
          consider_all_uses := false;
          return;
        end;
      end;
      j := jn;
    end;
  end;
end;

{ utils_$apply_func_to_all_uses - f applied to every (lts, use) pair
  (lts must be final: bug_check); false when nothing is reached or f
  answers false.

  0x28720E, 0xEA bytes. }

function utils_$apply_func_to_all_uses(
    rtn: rtn_ptr_t;
    f: utils_$pair_func_t;
    lts: lts_ptr_t): boolean;
var
  mark: integer32;
  m: mrh_$mark_t;
  list: ut_use_def_ptr_t;
  ok: boolean;
  k: integer32;
  n: integer32;
begin
  if not lts^.f2.final then begin
    n := lts^.f2.num;
    bug_check('UTILS_$apply_func_to_all_uses: expected exposed LTS %3ZWD.%2ZLD%$',
              lts^.lr^.num, n);
  end;
  if (lts^.l28 = nil) and (lts^.l44 = nil) then begin
    utils_$apply_func_to_all_uses := false;
    return;
  end;
  rtn^.marks := rtn^.marks + 1;
  mark := rtn^.marks;
  m := mrh_$mark(use_def_heap);
  list := nil;
  if not consider_all_uses(list, lts, lts, mark) then
    ok := false
  else begin
    ok := true;
    while ok and (list <> nil) do begin
      for k := 1 to list^.count do
        if not f^(list^.e[k].x, list^.e[k].y) then begin
          ok := false;
          exit;
        end;
      list := list^.next;
    end;
  end;
  mrh_$release_to_mark(use_def_heap, m);
  utils_$apply_func_to_all_uses := ok;
end;

{ utils_$find_mate_operand - for an fp_reg_pair operand, the other
  operand of its pair in the instruction: an even_only pair operand
  and the next odd_only one after it (the inner search going on from
  where the last stopped); instr_bug_check when none is found or the
  two differ in read, write, modify or intend_to_modify (+1 and
  #60); nil for another kind.

  0x28733A, 0x182 bytes: the instruction computed inline (as
  utils_ins_$operands_instruction); the operands walked by their own
  numbers (+0) against nopnds. }

function utils_$find_mate_operand(
    op: opnd_ptr_t): opnd_ptr_t;
label
  10, 20;
var
  i: instr_ptr_t;
  n: integer32;
  a: opnd_ptr_t;
  b: opnd_ptr_t;
  res: opnd_ptr_t;
  ln: integer32;
begin
  if op^.h.kind <> operand$fp_reg_pair then begin
    utils_$find_mate_operand := nil;
    return;
  end;
  i := utils_ins_$operands_instruction(op);
  n := i^.h.nopnds;
  a := addr(i^.opnds[1]);
  b := a;
  while a^.h.num <= n do begin
    if (a^.h.kind = operand$fp_reg_pair) and a^.h.fp_reg_even_only then begin
      while b^.h.num < n do begin
        b := opnd_ptr_t(integer32(b) + 12);
        if (b^.h.kind = operand$fp_reg_pair) and b^.h.fp_reg_odd_only then begin
          if a = op then begin
            res := b;
            goto 10;
          end;
          if b = op then begin
            res := a;
            goto 10;
          end;
          goto 20;
        end;
      end;
      ln := op^.lts^.f2.num;
      instr_bug_check('UTILS_$FIND_MATE_OPERAND -- fp_reg_pair odd_only operand not found: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                      i^, op^.lts^.lr^.num, ln, i^.bb^.num, i^.num);
    end;
20:
    a := opnd_ptr_t(integer32(a) + 12);
  end;
  ln := op^.lts^.f2.num;
  instr_bug_check('UTILS_$FIND_MATE_OPERAND -- search failed: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                  i^, op^.lts^.lr^.num, ln, i^.bb^.num, i^.num);
10:
  if ut_opnd_bytes_ptr_t(a)^.rrp & 60 <> ut_opnd_bytes_ptr_t(b)^.rrp & 60 then begin
    ln := op^.lts^.f2.num;
    instr_bug_check('UTILS_$FIND_MATE_OPERAND -- found operand but properties don''t match: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                    i^, op^.lts^.lr^.num, ln, i^.bb^.num, i^.num);
  end;
  utils_$find_mate_operand := res;
end;

{ utils_$instr_is_ref_to_argument_block - whether instr's alias
  descriptor (when it has one, +2 bit 7) is of the argument block.

  0x287608, 0x34 bytes: `cmpi.b #16,(18,A0)' 24 bytes before. }

function utils_$instr_is_ref_to_argument_block(
    instr: instr_ptr_t): boolean;
begin
  if not instr^.h.b2_7 then
    utils_$instr_is_ref_to_argument_block := false
  else
    utils_$instr_is_ref_to_argument_block :=
      alias_$desc_ptr_t(integer32(instr) - 24)^.class = alias_argument_block;
end;

{ utils_$instr_is_ref_to_memory_home - whether a load (class 16:
  operand 3 the data) or store (21: operand 1) addresses its data's
  live range's own home: the base register (the operand after the
  memory operand) one of the conventions' two (at_backend_4fc +108,
  +116) and safe, the memory operand a stack frame displacement or an
  immediate (from its symbol's displacement) of the data's symbol,
  and the displacement and size fit the access (by the opcode's
  attribute +19 bits 2..0).

  0x28763C, 0x196 bytes: the size by sym_$allocation_size_in_bytes;
  the access kinds a jump table of 4. }

function utils_$instr_is_ref_to_memory_home(
    instr: instr_ptr_t): boolean;
var
  cls: integer;
  data: lts_ptr_t;
  k: integer32;
  base: lr_ptr_t;
  conv: ut_conv_ptr_t;
  lr: lr_ptr_t;
  op: opnd_ptr_t;
  disp: integer32;
  s: univ_ptr;
  size: integer32;
begin
  utils_$instr_is_ref_to_memory_home := false;
  cls := instruction_attributes[instr^.opc].class;
  if cls = class$load then begin
    data := instr^.opnds[3].lts;
    k := 1;
  end
  else if cls = class$store then begin
    data := instr^.opnds[1].lts;
    k := 2;
  end
  else
    return;
  base := instr^.opnds[k + 1].lts^.lr;
  if not (rrp$safe_base_address in base^.rrp) then
    return;
  conv := at_backend_4fc;
  if (conv^.lr116 <> base) and (conv^.lr108 <> base) then
    return;
  lr := data^.lr;
  op := addr(instr^.opnds[k]);
  if op^.h.kind = operand$displacement_stack_frame then begin
    disp := op^.value;
    s := op^.link;
  end
  else if op^.h.kind = operand$immediate then begin
    if op^.link = nil then
      disp := op^.value
    else
      disp := sym_$displacement(op^.link) - op^.value;
    s := op^.link;
  end
  else
    return;
  if (s = nil) or (s <> lr^.sym) then
    return;
  size := sym_$allocation_size_in_bytes(s);
  case instruction_attributes[instr^.opc].w18 & 7 of
    0:
      utils_$instr_is_ref_to_memory_home := (size = 4)
        and ((cls = class$store) and (disp = 3));
    1:
      utils_$instr_is_ref_to_memory_home := (size = 4)
        and ((cls = class$store) and (disp = 2));
    2:
      utils_$instr_is_ref_to_memory_home := ((disp = 0) and (size = 4))
        or ((disp = 4) and (size = 8) and (rrp$fp_reg_odd_only in lr^.rrp));
    3:
      utils_$instr_is_ref_to_memory_home := (size = 8) and (disp = 0);
    otherwise
      ;
  end;
end;

{ utils_$instrs_consume_identical_symbols - the same opcode, operand
  count and width, and operand by operand the same kind, count (+2
  bits 5..4) and properties (+1), reading registers and memory of the
  same live ranges, the same immediates (and symbols), displacements
  and literal pool entries; false at a reading physical register or
  anything else read.

  0x2877D2, 0x16C bytes: the width a signed byte (`ext.w'); the kinds a
  jump table of 24 (0x287890). }

function utils_$instrs_consume_identical_symbols(
    a: instr_ptr_t;
    b: instr_ptr_t): boolean;
type
  sym_ptr_t = ^univ_ptr;
var
  k: integer32;
  o1: opnd_ptr_t;
  o2: opnd_ptr_t;
begin
  utils_$instrs_consume_identical_symbols := false;
  if (a^.opc <> b^.opc) or (a^.h.nopnds <> b^.h.nopnds)
     or (a^.h.width <> b^.h.width) then
    return;
  for k := 1 to a^.h.nopnds do begin
    o1 := addr(a^.opnds[k]);
    o2 := addr(b^.opnds[k]);
    if (o1^.h.kind <> o2^.h.kind) or (o1^.h.count <> o2^.h.count)
       or (ut_opnd_bytes_ptr_t(o1)^.rrp <> ut_opnd_bytes_ptr_t(o2)^.rrp) then
      return;
    case o1^.h.kind of
      operand$ip_reg, operand$fp_reg, operand$fp_reg_pair,
      operand$inscrutable_memory, operand$well_behaved_memory,
      operand$ip_reg_like, operand$fp_reg_like, operand$fp_reg_pair_like:
        if o1^.h.read then
          if o1^.lts^.lr <> o2^.lts^.lr then
            return;
      operand$immediate: begin
        if o1^.link <> o2^.link then
          return;
        if o1^.value <> o2^.value then
          return;
      end;
      operand$displacement_routine, operand$displacement_arg_block,
      operand$displacement_stack_frame, operand$displacement_XSB_base:
        if o1^.value <> o2^.value then
          return;
      operand$displacement_literal_pool: begin
        if sym_ptr_t(o1^.link)^ <> sym_ptr_t(o2^.link)^ then
          return;
        if o1^.value <> o2^.value then
          return;
      end;
      operand$none:
        ;
      otherwise
        if o1^.h.read then
          return;
    end;
  end;
  utils_$instrs_consume_identical_symbols := true;
end;

{ utils_$strip_may_gen_exception - +2 bit 5 cleared for a load, store
  or load pair whose address cannot fault: a base of a safe live range
  with a memory operand of the kinds #0x10FF7001 lists (a load pair's
  always), or an alias descriptor alias_$ref_may_generate_exception
  answers false for.

  0x28793E, 0xB0 bytes. }

procedure utils_$strip_may_gen_exception(
    instr: instr_ptr_t);
var
  cls: integer;
  kind: operand$t;
  base: lts_ptr_t;
begin
  cls := instruction_attributes[instr^.opc].class;
  if cls = class$load then begin
    kind := instr^.opnds[1].h.kind;
    base := instr^.opnds[2].lts;
  end
  else if cls = class$store then begin
    kind := instr^.opnds[2].h.kind;
    base := instr^.opnds[3].lts;
  end
  else if cls = class$load_pair then begin
    kind := operand$immediate;
    base := instr^.opnds[1].lts;
  end
  else
    return;
  if (kind in [operand$none, operand$ip_reg_like..operand$fp_reg_pair_like,
               operand$flow_graph_edge..operand$immediate,
               operand$exception_information])
     and (rrp$safe_base_address in base^.lr^.rrp) then
    instr^.h.b2_5 := false
  else if instr^.h.b2_7 then
    if not alias_$ref_may_generate_exception(
             alias_$desc_ptr_t(integer32(instr) - 24)^) then
      instr^.h.b2_5 := false;
end;

{ utils_$find_unused_operand_slot - 0x2879EE, 0x80 bytes: the message's
  mnemonic and its length as consider_all_defs's (the same pooled 12).
  }

function utils_$find_unused_operand_slot(
    instr: instr_ptr_t;
    first: integer32): integer32;
var
  k: integer32;
begin
  k := first;
  if k <= 0 then
    k := 1;
  while instr^.opnds[k].h.kind <> operand$none do
    k := k + 1;
  if instr^.h.nopnds < k then
    bug_check('UTILS_$FIND_UNUSED_OPERAND_SLOT -- all slots in use inst in %3ZWD:%3ZWD %a%$',
              instr^.bb^.num, instr^.num, instruction_mnemonic[instr^.opc], 12);
  utils_$find_unused_operand_slot := k;
end;
