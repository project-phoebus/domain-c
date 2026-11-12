{ at_backend - the PRISM back end's driver (cc.a88k only): runbackend's
  entry points (at_backend_$begin_compilation, codegen,
  at_backend_$end_compilation), the phase table (20 phases, ISC 0 ..
  BIN 19: their debug switch letters, the flags that turn a phase off
  at low optimization, the prfpkg phase numbers and their four
  routines), each routine's run through the phases (run_phase, then
  end_phase in reverse), the routine record get_calling_conventions
  makes (at_backend_4fc: the routine being compiled), the statement
  map lst and bin print lines from, and the bug checks that name the
  phase or the instruction's source line.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x221A60  zero (internal)
    --------  0x221A78  instr_bug_check
    --------  0x221B18  phase_bug_check
    --------  0x221B7E  phase_instr_bug_check
    --------  0x221C2A  query_user_for_routine_name (internal)
    --------  0x221CAC  query_user (internal)
    --------  0x221D3C  at_backend_$begin_compilation
    --------  0x221F4C  build_source_statement_map (internal)
    --------  0x2221BA  at_backend_$end_compilation
    --------  0x2222D6  get_calling_conventions (internal)
    --------  0x22235A  at_backend_$initialize_ftn_entry
    --------  0x222376  at_backend_$can_load_module_db
    --------  0x2223A0  run_phase (internal)
    --------  0x222618  end_phase (internal)
    --------  0x222756  codegen
    A5 0x485830 (0x508 bytes): the phase table (+0, 20 entries of 36
    bytes, initialized), the routine's qualified name (+720, a varying
    string), the name the 'R' switch asks for (+984), the routine heap
    (+1248), +1268 and +1272 (cleared only), the routine record
    (+0x4FC), the phase's switches (+0x500), the phase (+0x502), the
    'R' switch's flag (+0x504) and runbackend's at_backend_506.

  The internal routines that load A5 (run_phase, end_phase,
  get_calling_conventions, build_source_statement_map, the queries)
  reach the module's data through the caller's A5; zero has no frame.

  Not known from the original: every local, parameter, type and module
  variable name but the routines' and those other units declared
  (at_backend_4fc, at_backend_switches, at_backend_phase,
  at_backend_506); the phase entry's field names. }
module at_backend;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'lang/common/source/exs.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  at_targets_t = set of 0..15;
  at_compilation_proc_t = ^procedure;
  at_routine_proc_t = ^procedure(
      rtn: rtn_ptr_t); options(val_param);

  { A phase (36 bytes): its debug switches' letter (cargs_$debug_switches
    by letter), whether it runs when turned off (+1: MMT, TRANS, LIFE,
    COM, SCHED, POST) and whether low optimization turns it off (+2:
    those and KONST, IV, OLI), +3 the complement of +2 (not read), the
    targets it is skipped for (+4, bit target_properties +0x12: none),
    its prfpkg phase (+6), its routines (nil where it has none) and its
    name. }
  at_phase_ptr_t = ^at_phase_t;
  at_phase_t = record
    letter: char;                       { +0 }
    runs_off: boolean;                  { +1 }
    off_low_opt: boolean;               { +2 }
    b3: char;                           { +3 }
    targets: 0..65535;                  { +4 }
    prf: char;                          { +6 }
    b7: char;                           { +7 }
    begin_compilation: at_compilation_proc_t;    { +8 }
    process_routine: at_routine_proc_t; { +12 }
    end_routine: at_routine_proc_t;     { +16 }
    end_compilation: at_compilation_proc_t;      { +20 }
    name: array [1..12] of char;        { +24 }
  end;

  { An IL statement node as the statement map reads it: +2 its kind
    (148/149 the start/end of an inner block, whose +48 is the block,
    kind 172), +4/+8 the list's links, +20 its source line, +41 bit 5,
    +42 bits 23..8 its statement number (set here). }
  at_stmt_ptr_t = ^at_stmt_t;
  at_stmt_t = record
    space0: array [0..1] of char;
    kind: integer;                      { +2 }
    prev: at_stmt_ptr_t;                { +4 }
    next: at_stmt_ptr_t;                { +8 }
    space12: array [12..19] of char;
    line: integer;                      { +20 }
    space22: array [22..40] of char;
    f41: packed record                  { +41 }
      b7, b6: boolean;
      b5: boolean;
      b4_0: 0..31;
      end;
    l42: integer32;                     { +42 }
    space46: array [46..47] of char;
    blk: at_stmt_ptr_t;                 { +48 }
  end;

  { The routine record's fields the map fills (rtn_t +20 .. +36: the
    first statement, the line of each statement, its block number, the
    bits of the statements that start a line, the blocks). }
  at_rtn_ptr_t = ^at_rtn_t;
  at_rtn_t = record
    space0: array [0..19] of char;
    stmt: at_stmt_ptr_t;                { +20 }
    lines: univ_ptr;                    { +24 }
    starts: univ_ptr;                   { +28 }
    blocks: univ_ptr;                   { +32 }
    blks: univ_ptr;                     { +36 }
    next: rtn_ptr_t;                    { +40: the next routine record of
                                          its block }
  end;

  at_words_ptr_t = ^at_words_t;
  at_words_t = array [0..16#3FFFFFF] of 0..65535;
  at_bytes_ptr_t = ^at_bytes_t;
  at_bytes_t = array [0..16#7FFFFFF] of 0..255;
  at_ptrs_ptr_t = ^at_ptrs_t;
  at_ptrs_t = array [0..16#3FFFFFF] of univ_ptr;

  { The IL nodes get_calling_conventions and codegen read: +2 the kind
    (167 an entry, whose block is +148), +124 the block's routine
    record, +128 its conventions, +188 the routine block's list of
    records (+20 the first, +24 the last), +268 a word. }
  at_node_ptr_t = ^at_node_t;
  at_node_t = record
    space0: array [0..1] of char;
    kind: integer;                      { +2 }
    space4: array [4..123] of char;
    rtn: rtn_ptr_t;                     { +124 }
    conv: call_conv_$ptr_t;             { +128 }
    space132: array [132..147] of char;
    blk: at_node_ptr_t;                 { +148 }
    space152: array [152..187] of char;
    rtns: ^at_rtns_t;                   { +188 }
    space192: array [192..267] of char;
    w268: integer;                      { +268 }
  end;
  at_rtns_t = record
    space0: array [0..19] of char;
    first: rtn_ptr_t;                   { +20 }
    last: rtn_ptr_t;                    { +24 }
  end;

{ The ISC's entry points the table names (isc_main; not translated). }
procedure isc_$begin_compilation; extern;
procedure isc_$begin_routine(
    rtn: rtn_ptr_t); options(val_param); extern;
procedure isc_$end_routine(
    rtn: rtn_ptr_t); options(val_param); extern;
procedure isc_$end_compilation; extern;

var
  at_phases: array [0..19] of at_phase_t := [
      ['i', false, false, chr(255), 0, chr(22), chr(0),
       addr(isc_$begin_compilation), addr(isc_$begin_routine),
       addr(isc_$end_routine), addr(isc_$end_compilation), 'ISC         '],
      ['f', false, false, chr(255), 0, chr(23), chr(0),
       addr(fga_$begin_compilation), addr(fga_$process_routine),
       addr(fga_$end_routine), addr(fga_$end_compilation), 'FGA         '],
      ['m', true, true, chr(0), 0, chr(24), chr(0),
       addr(mmt_$begin_compilation), addr(mmt_$process_routine),
       addr(mmt_$end_routine), addr(mmt_$end_compilation), 'MMT         '],
      ['d', false, false, chr(255), 0, chr(25), chr(0),
       addr(dfa_$begin_compilation), addr(dfa_$process_routine),
       addr(dfa_$end_routine), addr(dfa_$end_compilation), 'DFA         '],
      ['k', false, true, chr(0), 0, chr(26), chr(0),
       addr(konst_$begin_compilation), addr(konst_$process_routine),
       addr(konst_$end_routine), addr(konst_$end_compilation), 'KONST       '],
      ['h', false, false, chr(255), 0, chr(23), chr(0),
       addr(hal_$begin_compilation), addr(hal_$process_routine),
       addr(hal_$end_routine), addr(hal_$end_compilation), 'HAL         '],
      ['t', true, true, chr(0), 0, chr(27), chr(0),
       addr(trans_$begin_compilation), addr(trans_$process_routine),
       addr(trans_$end_routine), addr(trans_$end_compilation), 'TRANS       '],
      ['l', true, true, chr(0), 0, chr(34), chr(0),
       addr(life_$begin_compilation), addr(life_$process_routine),
       addr(life_$end_routine), addr(life_$end_compilation), 'LIFE        '],
      ['c', true, true, chr(0), 0, chr(29), chr(0),
       addr(com_$begin_compilation), addr(com_$process_routine),
       addr(com_$end_routine), addr(com_$end_compilation), 'COM         '],
      ['v', false, true, chr(0), 0, chr(30), chr(0),
       addr(iv_$begin_compilation), addr(iv_$process_routine),
       addr(iv_$end_routine), addr(iv_$end_compilation), 'IV          '],
      ['o', false, true, chr(0), 0, chr(31), chr(0),
       addr(oli_$begin_compilation), addr(oli_$process_routine),
       addr(oli_$end_routine), addr(oli_$end_compilation), 'OLI         '],
      ['x', false, false, chr(255), 0, chr(32), chr(0),
       addr(xtp_$begin_compilation), addr(xtp_$process_routine),
       addr(xtp_$end_routine), addr(xtp_$end_compilation), 'XTP         '],
      ['s', true, true, chr(0), 0, chr(33), chr(0),
       addr(sched_$begin_compilation), addr(sched_$process_routine),
       addr(sched_$end_routine), addr(sched_$end_compilation), 'SCHED       '],
      ['r', false, false, chr(255), 0, chr(34), chr(0),
       addr(ra_$begin_compilation), addr(ra_$process_routine),
       addr(ra_$end_routine), addr(ra_$end_compilation), 'RA          '],
      ['p', true, true, chr(0), 0, chr(35), chr(0),
       addr(post_$begin_compilation), addr(post_$process_routine),
       addr(post_$end_routine), addr(post_$end_compilation), 'POST        '],
      ['j', false, false, chr(255), 0, chr(36), chr(0),
       addr(jbr_$begin_compilation), addr(jbr_$process_routine),
       addr(jbr_$end_routine), addr(jbr_$end_compilation), 'JBR         '],
      ['a', false, false, chr(255), 0, chr(40), chr(0),
       addr(asm_$begin_compilation), addr(asm_$process_routine),
       addr(asm_$end_routine), addr(asm_$end_compilation), 'ASM         '],
      ['g', false, false, chr(255), 0, chr(40), chr(0),
       nil, addr(dbg_life_$process_routine),
       addr(dbg_life_$end_routine), nil, 'DBG_LIFE    '],
      ['z', false, false, chr(255), 0, chr(40), chr(0),
       addr(zzzzz_$begin_compilation), addr(zzzzz_$process_routine),
       nil, nil, 'ZZZZZ       '],
      ['b', false, false, chr(255), 0, chr(40), chr(0),
       addr(bin_$begin_compilation), nil, nil, nil, 'BIN         ']];
                                        { +0 }
  at_name: prtsub_$line_t;              { +720: the routine's qualified
                                          name }
  at_query_name: prtsub_$line_t;        { +984: the routine the 'R'
                                          switch asked for }
  at_heap: mrh_$heap_t;                 { +1248: "at_backend routine
                                          heap" }
  at_4f4: integer32;                    { +0x4F4 }
  at_4f8: integer32;                    { +0x4F8 }
  at_query: boolean;                    { +0x504: the 'R' switch on }

define
  at_backend_4fc;                       { +0x4FC }
  at_backend_switches;                  { +0x500 }
  at_backend_phase;                     { +0x502 }
  at_backend_506;                       { +0x506 }

{ zero - n bytes from p cleared, a longword at a time: rev889-patterns
  100.  0x221A60, 0x18 bytes, internal, no frame. }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  longs_t = array [1..16#3FFFFFF] of integer32;
var
  q: ^longs_t;
  k: integer32;
begin
  if n <> 0 then begin
    q := p;
    for k := 1 to rshft(n + 3, 2) do
      q^[k] := 0;
  end;
end;

{ INSTR_BUG_CHECK - bug_check with instr's source line first.
  0x221A78, 0xA0 bytes (A5): the line's lookup inline; the nine
  arguments passed on as they came. }

procedure instr_bug_check;
var
  line: integer32;
  i: instr_ptr_t;
begin
  line := 0;
  i := addr(instr);
  if i <> nil then begin
    if i^.h.b0_1 then
      line := at_words_ptr_t(univ_ptr(i^.l32))^[2]
    else
      line := at_words_ptr_t(univ_ptr(addr(i^.l32)))^[0];
    if lst_13c <> nil then
      line := at_words_ptr_t(lst_13c)^[line]
    else
      line := 99999;
  end;
  bug_check(control_string, line, a1, a2, a3, a4, a5, a6, a7, a8, a9);
end;

{ PHASE_BUG_CHECK - bug_check with the running phase's name first.
  0x221B18, 0x66 bytes (A5). }

procedure phase_bug_check;
begin
  bug_check(control_string, at_phases[at_backend_phase].name, a1, a2, a3,
      a4, a5, a6, a7, a8, a9);
end;

{ PHASE_INSTR_BUG_CHECK - bug_check with the phase's name and instr's
  source line first.  0x221B7E, 0xAC bytes (A5). }

procedure phase_instr_bug_check;
var
  line: integer32;
  i: instr_ptr_t;
begin
  line := 0;
  i := addr(instr);
  if i <> nil then begin
    if i^.h.b0_1 then
      line := at_words_ptr_t(univ_ptr(i^.l32))^[2]
    else
      line := at_words_ptr_t(univ_ptr(addr(i^.l32)))^[0];
    if lst_13c <> nil then
      line := at_words_ptr_t(lst_13c)^[line]
    else
      line := 99999;
  end;
  bug_check(control_string, at_phases[at_backend_phase].name, line, a1,
      a2, a3, a4, a5, a6, a7, a8);
end;

{ query_user_for_routine_name - the routine whose phases are to be
  traced, read from the terminal into name.

  0x221C2A, 0x48 bytes, internal: stream 2 a word constant; the length
  in and out (-10, 256). }

procedure query_user_for_routine_name(
    var name: prtsub_$line_t); options(val_param); internal;
var
  cnt, len: integer;
  status: status_$t;
begin
  vfmt_$ws(2, 'Enable diagnostic output for what routine? %$');
  len := 256;
  vfmt_$read2('%""%eka%.', cnt, status, name.body, len);
  name.length := len;
end;

{ query_user - whether to trace this routine (the terminal's answer
  'Y').  0x221CAC, 0x5C bytes, internal. }

function query_user: boolean; internal;
var
  cnt, len: integer;
  status: status_$t;
  ans: char;
  n: integer32;
begin
  n := at_name.length;
  vfmt_$ws(2, 'Enable diagnostic output for routine "%a"? %$', at_name.body,
      n);
  len := 1;
  ans := chr(0);
  vfmt_$read2('%kua%.', cnt, status, ans, len);
  query_user := ans = 'Y';
end;

{ AT_BACKEND_$BEGIN_COMPILATION - the compilation's start: lir_main's
  flags and cells cleared, lir_main_da4 set for low optimization (-OPT
  3 or less) or -DBA; each phase's switches get the 'E' switches, and
  sw15 (off) when low optimization turns the phase off; the routine
  heap; with the 'R' switch the routine to trace asked for; each
  phase's begin_compilation (with the 'i' switches' sw11, ISC's alone;
  traced with sw8), lir's after ISC's; the utilities'; exs initialized
  (lang 5: exceptions).

  0x221D3C, 0x1B0 bytes (A5): lir_main +0xDA4 (4 bytes) and +0xC40
  (0x128) cleared by zero; cargs' opt (+0x27F bits 5..2) and db
  (+0x282 bits 16..15); the phases' loops `dbf' over 20. }

procedure at_backend_$begin_compilation;
var
  low: boolean;
  k: integer;
  c: char;
begin
  zero(addr(lir_main_da4), 4);
  zero(addr(lir_main_c40), 16#128);
  at_4f8 := 0;
  at_4f4 := 0;
  low := (cargs_$options.opt <= 3) or (cargs_$options.db = 3);
  lir_main_da4 := low;
  for k := 0 to 19 do begin
    c := at_phases[k].letter;
    cargs_$debug_switches[c] := cargs_$debug_switches[c] !
        cargs_$debug_switches['E'];
    if low and at_phases[k].off_low_opt then
      cargs_$debug_switches[c] := cargs_$debug_switches[c] ! (-32768);
  end;
  mrh_$initialize(at_heap, 1, 232, 'at_backend routine heap%');
  at_query := cargs_$debug_switches['R'] <> 0;
  if at_query then
    query_user_for_routine_name(at_query_name);
  for k := 0 to 19 do
    with at_phases[k] do begin
      if begin_compilation <> nil then
        if (k = 0) or ((cargs_$debug_switches['i'] & 16#800) = 0) then begin
          if (cargs_$debug_switches[letter] & 16#100) <> 0 then
            vfmt_$write('CALLING:  %m12a_$BEGIN_COMPILATION%.', name);
          begin_compilation^;
          if (cargs_$debug_switches[letter] & 16#100) <> 0 then
            vfmt_$write('RETURNED: %m12a_$BEGIN_COMPILATION%.', name);
        end;
      if k = 0 then
        lir_$begin_compilation;
    end;
  df_utils_$begin_compilation;
  fg_utils_$begin_compilation;
  mmt_utils_$begin_compilation;
  ra_utils_$begin_compilation;
  sched_utils_$begin_compilation;
  sem_utils_$begin_compilation;
  tm_utils_$begin_compilation;
  tr_utils_$begin_compilation;
  utils_$begin_compilation;
  exs_$initialise(p in [5], p in [5]);
end;

{ build_source_statement_map - the routine's statements numbered (each
  statement node's +42 bits 23..8) and mapped: for each the source
  line (+24), whether it starts a line (+28's bit, not for a statement
  of +41 bit 5), its inner block's number (+32); the blocks (+36, the
  routine's node first); the inner blocks' start and end nodes taken
  off the list.  Unbalanced blocks are a bug check.

  0x221F4C, 0x24C bytes, internal: one allocation for the four tables
  (4 by block, 2 and 2 by statement, a bit by statement; runbackend_16
  the statements), a stack of block numbers from the heap; the
  statement number's field `andi.l #0xFFFF00'. }

procedure build_source_statement_map(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  opened, closed: integer;
  p, nx: at_stmt_ptr_t;
  n, size, stmt, blkno, depth, cur, bit: integer32;
  r: at_rtn_ptr_t;
  blks: at_ptrs_ptr_t;
  blocks, lines, stack: at_words_ptr_t;
  starts: at_bytes_ptr_t;
  line: integer;
  status: status_$t;
begin
  r := at_rtn_ptr_t(rtn);
  opened := 1;
  closed := 1;
  p := at_stmt_ptr_t(il_d4);
  while p <> nil do begin
    if (p^.kind = 148) and (p^.blk^.kind = 172) then
      opened := opened + 1
    else if (p^.kind = 149) and (p^.blk^.kind = 172) then
      closed := closed + 1;
    p := p^.next;
  end;
  if opened <> closed then
    bug_check('Inner blocks incorrectly nested.%$');
  n := opened;
  size := 4 * n + 2 * (runbackend_16 + 1) + 2 * (runbackend_16 + 1) +
      rshft(runbackend_16 + 8, 3);
  blks := rws_$alloc_heap(size);
  r^.blks := blks;
  blocks := univ_ptr(integer32(blks) + 4 * n);
  r^.blocks := blocks;
  lines := univ_ptr(integer32(blocks) + 2 * (runbackend_16 + 1));
  r^.lines := lines;
  starts := univ_ptr(integer32(lines) + 2 * (runbackend_16 + 1));
  r^.starts := starts;
  size := 2 * n;
  stack := rws_$alloc_heap(size);
  line := 0;
  blkno := 0;
  cur := 0;
  depth := 0;
  stmt := 0;
  stack^[0] := 0;
  p := at_stmt_ptr_t(il_d4);
  while p <> nil do begin
    if ((p^.kind = 149) or (p^.kind = 148)) and (p^.blk^.kind = 172) then begin
      if p^.kind = 148 then begin
        blkno := blkno + 1;
        blks^[blkno] := p^.blk;
        cur := blkno;
        depth := depth + 1;
        stack^[depth] := cur;
      end
      else begin
        depth := depth - 1;
        cur := stack^[depth];
      end;
      if p^.prev <> nil then
        p^.prev^.next := p^.next;
      if p^.next <> nil then
        p^.next^.prev := p^.prev;
    end
    else begin
      p^.l42 := (p^.l42 & (~16#FFFF00)) ! (lshft(stmt, 8) & 16#FFFF00);
      if p^.line <> 0 then
        line := p^.line;
      bit := rshft(128, stmt & 7);
      starts^[stmt div 8] := (starts^[stmt div 8] & (~bit)) !
          (ord((p^.line <> 0) and not p^.f41.b5) * bit);
      lines^[stmt] := line;
      blocks^[stmt] := cur;
      stmt := stmt + 1;
    end;
    p := p^.next;
  end;
  rws_$release_heap(stack, status);
  lines^[0] := 0;
  starts^[0] := starts^[0] & 127;
  blks^[0] := rtn^.node;
  blocks^[0] := 0;
end;

{ AT_BACKEND_$END_COMPILATION - each phase's end_compilation (with the
  'i' switches' sw11, ISC's alone; traced with sw8), the utilities',
  exs's; the phase left at 19 with BIN's switches.

  0x2221BA, 0xD8 bytes (A5). }

procedure at_backend_$end_compilation;
var
  k: integer;
begin
  for k := 0 to 19 do
    with at_phases[k] do
      if end_compilation <> nil then begin
        at_backend_switches := at_switches_t(cargs_$debug_switches[letter]);
        if (k = 0) or ((cargs_$debug_switches['i'] & 16#800) = 0) then begin
          if at_backend_switches.sw8 then
            vfmt_$write('CALLING:  %m12a_$END_COMPILATION%.', name);
          end_compilation^;
          if at_backend_switches.sw8 then
            vfmt_$write('RETURNED: %m12a_$END_COMPILATION%.', name);
        end;
      end;
  df_utils_$end_compilation;
  fg_utils_$end_compilation;
  mmt_utils_$end_compilation;
  ra_utils_$end_compilation;
  sched_utils_$end_compilation;
  sem_utils_$end_compilation;
  tm_utils_$end_compilation;
  tr_utils_$end_compilation;
  utils_$end_compilation;
  exs_$finalise;
  at_backend_phase := 19;
  at_backend_switches := at_switches_t(cargs_$debug_switches['b']);
end;

{ get_calling_conventions - node's conventions (at_call_conv's, kept at
  the node's +128) and its block's routine record (an entry's block is
  +148), made from the routine heap the first time (the conventions'
  clobbers as the routine's written sets, needs_db, the conventions,
  the node) and kept at the node's +124; at_backend_4fc set to it.

  0x2222D6, 0x84 bytes, internal: the record looked up at the block's
  +124 but stored at the node's. }

function get_calling_conventions(
    node: univ_ptr): call_conv_$ptr_t; options(val_param); internal;
var
  nd, blk: at_node_ptr_t;
  conv: call_conv_$ptr_t;
  r: rtn_ptr_t;
begin
  nd := node;
  conv := nd^.conv;
  if conv = nil then begin
    conv := at_call_conv(node);
    nd^.conv := conv;
    nd^.w268 := 0;
  end;
  if nd^.kind <> 167 then
    blk := nd
  else begin
    blk := nd^.blk;
    nd^.rtn := nil;
  end;
  r := blk^.rtn;
  if r = nil then begin
    r := mrh_$alloc_fixed(at_heap);
    r^.written_fp[0] := conv^.fp_clobbered[0];
    r^.written_fp[1] := conv^.fp_clobbered[1];
    r^.written_ip := conv^.ip_clobbered;
    r^.f226.needs_db := true;
    r^.conv := conv;
    r^.node := node;
    nd^.rtn := r;
  end;
  at_backend_4fc := r;
  get_calling_conventions := conv;
end;

{ AT_BACKEND_$INITIALIZE_FTN_ENTRY - a FORTRAN entry's conventions and
  record made.  0x22235A, 0x1C bytes (A5). }

procedure at_backend_$initialize_ftn_entry;
begin
  discard(get_calling_conventions(p));
end;

{ AT_BACKEND_$CAN_LOAD_MODULE_DB - whether the routine may load the
  module's DB register itself: its conventions' w18 is not among the
  registers calls read (ip76).  0x222376, 0x2A bytes (A5). }

function at_backend_$can_load_module_db;
var
  conv: call_conv_$ptr_t;
begin
  conv := get_calling_conventions(p);
  at_backend_$can_load_module_db :=
      not ((conv^.w18 & 31) in bv_word_t(conv^.ip76));
end;

{ run_phase - phase k's process_routine on rtn: skipped for the target
  (+4) or when turned off (unless it runs when off); without all only
  the off switch kept; the switches given to dmp too; dumps before
  (sw3) and after (sw4, not for ZZZZZ and BIN) and traces (sw8, with
  the 'M' switch the memory used); timed by prfpkg; ISC's preceded by
  lir_main_$begin_routine and, without sw11, followed by
  lir_main_$build_initial_epilog.

  0x2223A0, 0x1B8 bytes, internal: target_properties +0x12 as the bit
  of +4; lir_main_c8d cleared; the name's varying string for %A as its
  body and length. }

procedure run_phase(
    rtn: rtn_ptr_t;
    all: boolean;
    k: integer); options(val_param); internal;
var
  e: at_phase_ptr_t;
  n: integer32;
begin
  e := addr(at_phases[k]);
  if (target_properties.p_10 & 16#FFFF) in at_targets_t(e^.targets) then
    return;
  at_backend_phase := k;
  lir_main_c8d := false;
  at_backend_switches := at_switches_t(cargs_$debug_switches[e^.letter]);
  if at_backend_switches.sw15 then
    if not e^.runs_off then
      return;
  if not all then
    at_backend_switches := at_switches_t(integer(at_backend_switches) &
        (-32768));
  dmp_3c2 := at_backend_switches;
  if at_backend_switches.sw3 then begin
    n := at_name.length;
    vfmt_$write('%/%/DUMP OF PROCEDURE "%A" PRIOR TO PHASE "%m12a"%/%.',
        at_name.body, n, e^.name);
    dmp_$whole_routine(rtn, at_backend_switches.sw5, false);
  end;
  if at_backend_switches.sw8 then begin
    n := at_name.length;
    vfmt_$write('CALLING:  %m12a_$PROCESS_ROUTINE( %a )%.', e^.name,
        at_name.body, n);
  end;
  perfstart(ord(e^.prf));
  if k = 0 then
    lir_main_$begin_routine(rtn);
  e^.process_routine^(rtn);
  if k = 0 then
    if not at_backend_switches.sw11 then
      lir_main_$build_initial_epilog(rtn);
  perfstop(ord(e^.prf));
  if at_backend_switches.sw8 then begin
    n := at_name.length;
    vfmt_$write('RETURNED: %m12a_$PROCESS_ROUTINE( %a )%.', e^.name,
        at_name.body, n);
    if cargs_$debug_switches['M'] <> 0 then
      dmp_$memory_usage;
  end;
  if k < 18 then
    if at_backend_switches.sw4 then begin
      n := at_name.length;
      vfmt_$write('%/%/DUMP OF PROCEDURE "%A" SUBSEQUENT TO PHASE "%m12a"%/%.',
          at_name.body, n, e^.name);
      dmp_$whole_routine(rtn, at_backend_switches.sw5, true);
    end;
end;

{ end_phase - phase k's end_routine on rtn, as run_phase decides
  (without the dumps); traced with sw8.

  0x222618, 0x13E bytes, internal. }

procedure end_phase(
    rtn: rtn_ptr_t;
    all: boolean;
    k: integer); options(val_param); internal;
var
  e: at_phase_ptr_t;
  n: integer32;
begin
  e := addr(at_phases[k]);
  if (target_properties.p_10 & 16#FFFF) in at_targets_t(e^.targets) then
    return;
  at_backend_switches := at_switches_t(cargs_$debug_switches[e^.letter]);
  if at_backend_switches.sw15 then
    if not e^.runs_off then
      return;
  if not all then
    at_backend_switches := at_switches_t(integer(at_backend_switches) &
        (-32768));
  dmp_3c2 := at_backend_switches;
  if e^.end_routine <> nil then begin
    if at_backend_switches.sw8 then begin
      n := at_name.length;
      vfmt_$write('CALLING:  %m12a_$END_ROUTINE( %a )%.', e^.name,
          at_name.body, n);
    end;
    perfstart(ord(e^.prf));
    e^.end_routine^(rtn);
    perfstop(ord(e^.prf));
    if at_backend_switches.sw8 then begin
      n := at_name.length;
      vfmt_$write('RETURNED: %m12a_$END_ROUTINE( %a )%.', e^.name,
          at_name.body, n);
    end;
  end;
end;

{ CODEGEN - one routine through the back end: its conventions and
  record (the first statement after il_d4's, whose +48 is the routine
  node), the statement map (lst_13c the lines), il_180 the node, the
  record on its block's list; its qualified name; whether to trace it
  (the 'R' switch's name, else the 'Q' switch's question, else always
  without 'R'); exs's subprogram; ISC, then (with at_backend_506 and
  without the 'i' switches' sw11) the utilities' init_for_routine,
  phases 1..18, their end_routine in reverse and the utilities'
  end_routine; ISC's end_routine, lir_$end_routine, exs's end; the
  phase left at 19.

  0x222756, 0x3E6 bytes (A5): every phase's call written out (no
  loop); lir_$end_routine called with no argument (pattern 132; rtn
  passed here). }

procedure codegen;
var
  stmt: at_stmt_ptr_t;
  node: univ_ptr;
  rtn: rtn_ptr_t;
  rl: ^at_rtns_t;
  trace: boolean;
begin
  stmt := at_stmt_ptr_t(il_d4)^.next;
  node := stmt^.blk;
  discard(get_calling_conventions(node));
  rtn := at_backend_4fc;
  at_rtn_ptr_t(rtn)^.stmt := stmt;
  build_source_statement_map(rtn);
  lst_13c := at_rtn_ptr_t(rtn)^.lines;
  il_180 := node;
  rl := at_node_ptr_t(node)^.rtns;
  if rl^.first = nil then
    rl^.first := rtn
  else
    at_rtn_ptr_t(rl^.last)^.next := rtn;
  rl^.last := rtn;
  sym_$fully_qualified_routine_name(addr(at_name), rtn^.node, true);
  if at_query and prtsub_$equal(at_name, at_query_name) then
    trace := true
  else if cargs_$debug_switches['Q'] = 0 then
    trace := not at_query
  else
    trace := query_user;
  exs_$start_subprogram(node);
  run_phase(rtn, trace, 0);
  if at_backend_506 and ((cargs_$debug_switches['i'] & 16#800) = 0) then begin
    df_utils_$init_for_routine(rtn);
    fg_utils_$init_for_routine(rtn);
    mmt_utils_$init_for_routine(rtn);
    ra_utils_$init_for_routine(rtn);
    sched_utils_$init_for_routine(rtn);
    sem_utils_$init_for_routine(rtn);
    tm_utils_$init_for_routine(rtn);
    tr_utils_$init_for_routine(rtn);
    run_phase(rtn, trace, 1);
    run_phase(rtn, trace, 2);
    run_phase(rtn, trace, 3);
    run_phase(rtn, trace, 4);
    run_phase(rtn, trace, 5);
    run_phase(rtn, trace, 6);
    run_phase(rtn, trace, 7);
    run_phase(rtn, trace, 8);
    run_phase(rtn, trace, 9);
    run_phase(rtn, trace, 10);
    run_phase(rtn, trace, 11);
    run_phase(rtn, trace, 12);
    run_phase(rtn, trace, 13);
    run_phase(rtn, trace, 14);
    run_phase(rtn, trace, 15);
    run_phase(rtn, trace, 16);
    run_phase(rtn, trace, 17);
    run_phase(rtn, trace, 18);
    end_phase(rtn, trace, 18);
    end_phase(rtn, trace, 17);
    end_phase(rtn, trace, 16);
    end_phase(rtn, trace, 15);
    end_phase(rtn, trace, 14);
    end_phase(rtn, trace, 13);
    end_phase(rtn, trace, 12);
    end_phase(rtn, trace, 11);
    end_phase(rtn, trace, 10);
    end_phase(rtn, trace, 9);
    end_phase(rtn, trace, 8);
    end_phase(rtn, trace, 7);
    end_phase(rtn, trace, 6);
    end_phase(rtn, trace, 5);
    end_phase(rtn, trace, 4);
    end_phase(rtn, trace, 3);
    end_phase(rtn, trace, 2);
    end_phase(rtn, trace, 1);
    tr_utils_$end_routine(rtn);
    tm_utils_$end_routine(rtn);
    sem_utils_$end_routine(rtn);
    sched_utils_$end_routine(rtn);
    ra_utils_$end_routine(rtn);
    mmt_utils_$end_routine(rtn);
    fg_utils_$end_routine(rtn);
    df_utils_$end_routine(rtn);
  end;
  end_phase(rtn, trace, 0);
  lir_$end_routine(rtn);
  exs_$end_current_subprogram;
  at_backend_phase := 19;
end;
