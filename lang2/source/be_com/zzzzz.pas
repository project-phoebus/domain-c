{ zzzzz - the ZZZZZ phase of the PRISM back end (at_backend's phase
  table entry 18, 'z', "ZZZZZ"; no end_routine or end_compilation in
  the table): each routine's instructions made into the code cells bin,
  lst and asm emit, with the epilogues marked; and the allocators of
  labels, case tables and code cells the other units call.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x287F80  zero (internal)
    --------  0x287F98  zzzzz_$begin_compilation
    --------  0x287FC8  zzzzz_$end_compilation
    --------  0x287FCA  zzzzz_$preallocate_label
    --------  0x288022  zzzzz_$preallocate_case_table
    --------  0x288092  zzzzz_$new_code_cell
    --------  0x2880E8  basic_block_label (internal)
    --------  0x288164  mark_start_of_epilogue (internal)
    --------  0x288214  zzzzz_$process_routine
    A5 0x492FEC: the module's data (the code cells' heap, 20 bytes at
    +0); the section zzzzz_readonly_tables (0x2BE408, 384 bytes): the
    code cells' sizes by opcode (code_cell_size.init, an initializer
    the opcode generator made).

  A code cell is 20 bytes and 12 for each operand it carries
  (backend.ins.pas's cell_t); a label's instruction becomes its own
  cell (its first longword rewritten, +8/+16 the source position, +3
  bit 5).

  Not known from the original: every local and parameter name; the
  record the routine's IL node's +188 points to (zz_code_t: its +76
  heads the case tables, +84 gets the last code cell). }
module zzzzz;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';

type
  { What a routine's IL node's +188 points to, as zzzzz uses it. }
  zz_code_ptr_t = ^zz_code_t;
  zz_code_t = record
    unused_0: array [0..75] of char;    { +0 }
    tables: cell_ptr_t;                 { +76: the case tables }
    unused_80: integer32;               { +80 }
    last: cell_ptr_t;                   { +84: the last code cell }
  end;
  zz_node_ptr_t = ^zz_node_t;
  zz_node_t = record
    unused_0: array [0..187] of char;   { +0 }
    code: zz_code_ptr_t;                { +188 }
  end;

  { A flow graph edge (an operand of kind operand$flow_graph_edge's
    +8): its target block at +4. }
  zz_edge_ptr_t = ^zz_edge_t;
  zz_edge_t = record
    unused_0: integer32;                { +0 }
    target: bb_ptr_t;                   { +4 }
  end;

var
  heap: mrh_$heap_t;                    { +0: the code cells' heap }

var (zzzzz_readonly_tables)
  { The size of a code cell by opcode: 20 and 12 for each operand. }
  code_cell_size: packed array [0..383] of 0..255 := [
    0, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,  { 0 }
    32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,  { 16 }
    32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,  { 32 }
    32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,  { 48 }
    32, 32, 32, 32, 20, 32, 32, 32, 32, 32, 44, 44, 44, 44, 44, 56,  { 64 }
    56, 56, 56, 56, 56, 56, 56, 44, 44, 44, 56, 56, 56, 56, 56, 56,  { 80 }
    56, 56, 56, 56, 20, 20, 20, 56, 56, 56, 56, 56, 56, 56, 56, 32,  { 96 }
    32, 32, 32, 56, 44, 20, 56, 56, 56, 56, 56, 56, 56, 56, 44, 20,  { 112 }
    20, 44, 32, 44, 32, 44, 44, 44, 44, 56, 56, 56, 56, 56, 44, 44,  { 128 }
    44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 56, 56, 44, 32, 32, 56,  { 144 }
    56, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 56, 56, 44, 32, 32,  { 160 }
    56, 56, 56, 56, 44, 56, 56, 44, 56, 56, 44, 44, 44, 44, 44, 44,  { 176 }
    20, 20, 20, 44, 32, 20, 20, 20, 20, 20, 20, 20, 32, 32, 32, 32,  { 192 }
    20, 20, 20, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 208 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 224 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 240 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 256 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 272 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 288 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 304 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 320 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 336 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 352 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];  { 368 }

{ zero - n bytes from p cleared, a longword at a time ((n + 3) div 4 of
  them; nothing for 0).

  0x287F80, 0x18 bytes, internal, no frame: p at (4,SP), n at (8,SP);
  `addq.l #3; lsr.l #2', `clr.l (A0)+' until the count is 0. }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  longs_t = array [1..1000000] of integer32;
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

{ zzzzz_$begin_compilation - the code cells' heap entered.

  0x287F98, 0x22 bytes: mrh_$initialize(heap, 0, 0, "code cells%")
  (the two words pushed as one `clr.l'). }

procedure zzzzz_$begin_compilation;
begin
  mrh_$initialize(heap, 0, 0, 'code cells%');
end;

{ zzzzz_$end_compilation - nothing.  0x287FC8, 2 bytes. }

procedure zzzzz_$end_compilation;
begin
end;

{ zzzzz_$preallocate_label - a label instruction, not yet in a block.

  0x287FCA, 0x58 bytes: 56 bytes (44 and one operand) from the heap,
  cleared; nopnds 1, opc 199 (label), operand 1 of kind 25
  (symbol_definition, `and.b #-32; or.b') and num 1; A0. }

function zzzzz_$preallocate_label: instr_ptr_t;
var
  instr: instr_ptr_t;
begin
  instr := mrh_$alloc(heap, 56);
  zero(instr, 56);
  instr^.h.nopnds := 1;
  instr^.opc := 199;
  instr^.opnds[1].h.kind := operand$symbol_definition;
  instr^.opnds[1].h.num := 1;
  zzzzz_$preallocate_label := instr;
end;

{ zzzzz_$preallocate_case_table - a case table of n entries: a TABLEL
  code cell with room for them, chained on the current routine's
  tables.

  0x288022, 0x70 bytes: n by address; the size code_cell_size[207]
  (`move.b 0x2BE4D7') plus 4n, in a local passed to rws_$alloc_heap;
  the cell cleared, its opcode byte 0xCF (207, tablel), +12 n; il_180's
  +188 record's +76 chain (the cell's next, at +4); A0. }

function zzzzz_$preallocate_case_table(
    in n: integer32): cell_ptr_t;
var
  size: integer32;
  cell: cell_ptr_t;
  code: zz_code_ptr_t;
begin
  size := code_cell_size[207] + n * 4;
  cell := rws_$alloc_heap(size);
  zero(cell, size);
  cell^.h.opc := 207;
  cell^.l12 := n;
  code := zz_node_ptr_t(il_180)^.code;
  cell^.next := code^.tables;
  code^.tables := cell;
  zzzzz_$preallocate_case_table := cell;
end;

{ zzzzz_$new_code_cell - an empty code cell of opcode opc.

  0x288092, 0x56 bytes: opc (a word) by address; code_cell_size[opc]
  bytes from the heap; the first longword built in a local (cleared,
  the opcode's byte at +1) and stored; +4 .. +19 cleared (four `clr.l
  (A1)+'); the cell left in A0 from mrh_$alloc. }

function zzzzz_$new_code_cell(
    in opc: integer): cell_ptr_t;
var
  cell: cell_ptr_t;
  h: record
    case integer of
      1: (l: integer32);
      2: (h: cell_hdr_t);
  end;
begin
  cell := mrh_$alloc(heap, code_cell_size[opc]);
  h.l := 0;
  h.h.opc := opc;
  cell^.h := h.h;
  cell^.next := nil;
  cell^.l8 := 0;
  cell^.l12 := 0;
  cell^.l16 := 0;
  zzzzz_$new_code_cell := cell;
end;

{ basic_block_label - the label that starts block bb: its first
  instruction if that is of class$label, else a new LABEL$ put first
  (with the old first instruction's +28); in either case its +1 gets
  the opcode's byte, as a code cell's.

  0x2880E8, 0x7C bytes, internal: bb by value (A3); the class at the
  attributes' +7 (`cmpi.b #19'); 44 bytes from the heap, cleared, next
  the old first, +28 the old first's +28 (read even when bb was empty),
  opc 200; `move.b (21,A2),(1,A0)'; A0. }

function basic_block_label(
    bb: bb_ptr_t): instr_ptr_t; options(val_param); internal;
var
  instr: instr_ptr_t;
  have: boolean;
begin
  instr := bb^.first;
  have := false;
  if instr <> nil then
    have := instruction_attributes[instr^.opc].class = class$label;
  if not have then begin
    instr := mrh_$alloc(heap, 44);
    zero(instr, 44);
    instr^.next := bb^.first;
    instr^.l28 := bb^.first^.l28;
    instr^.opc := 200;
    bb^.first := instr;
  end;
  cell_ptr_t(instr)^.h.opc := instr^.opc;
  basic_block_label := instr;
end;

{ mark_start_of_epilogue - an EPILOGUE code cell put after pending (the
  first cell of the run that leads to the returning jump), or after prev
  when there is none, and chained on the routine's epilogue marks (at
  +12 of the last one, last; the routine's epilogues for the first).
  It takes the header and +8 of the cell after it, and its source
  position (+16), or the one of the cell after prev with that one's +0
  bit 1.

  0x288164, 0xB0 bytes, internal: rtn, last (by address), prev and
  pending by value; 20 bytes from the heap, cleared; the header copied
  and its opcode byte 0xC6 (198, epilogue). }

procedure mark_start_of_epilogue(
    rtn: rtn_ptr_t;
    var last: cell_ptr_t;
    prev: cell_ptr_t;
    pending: cell_ptr_t); options(val_param); internal;
var
  at: cell_ptr_t;
  cell: cell_ptr_t;
  next: cell_ptr_t;
begin
  if pending <> nil then
    at := pending
  else
    at := prev;
  cell := mrh_$alloc(heap, 20);
  zero(cell, 20);
  cell^.next := at^.next;
  at^.next := cell;
  next := cell^.next;
  cell^.h := next^.h;
  cell^.h.opc := 198;
  cell^.l8 := next^.l8;
  if next^.l16 <> 0 then
    cell^.l16 := next^.l16
  else begin
    next := prev^.next;
    cell^.l16 := next^.l16;
    cell^.h.b0_1 := next^.h.b0_1;
  end;
  if last = nil then
    rtn^.epilogues := cell
  else
    last^.l12 := integer32(cell);
  last := cell;
end;

{ zzzzz_$process_routine - the routine's code cells, block by block in
  code order: under -EXP the blocks that need one get a label, an
  instruction that sets the condition codes into register 31 is listed
  as the TST or CMP it is (move, extend7, extend15 as TST, TSTB, TSTW;
  sub of a register, add of an immediate, negated, as CMP), and a
  RETURN as a JUMP.  A label's instruction becomes its own cell (only
  the block's first label: a LABEL with no symbol is numbered as a
  LABEL$); LIMIT and PMOVE instructions get none; any other gets a cell
  of its opcode's size (-EXP) or of its results it must carry (20, 32
  or 44 bytes: a displacement or exception operand among them; ENTRY
  and LTORG 32), with its exception information operand after them.
  Under -EXP a flow graph edge operand becomes a label reference to its
  target block's label.  A returning jump (a branch, FP branch, jump or
  return whose operand 1 is the routine's return segment, +112) marks
  the epilogue before the run of cells that leads to it (pending: the
  first since the last cell with a source position, a NOP or an ENTRY
  aside).  The cells end up on the routine's cells (+88) and the last
  one on its IL node's +188 record's +84.

  0x288214, 0x436 bytes, a frame of 3152: the head cell is a local
  cell_t (3080 bytes at -3080, so its next at -3076), exp (-3146:
  cargs_$options.exp, `btst #1,0x4437EA'), label_seen (-3144), the
  block (-3140), last_mark (-3128), the header being built (-3124: the
  instruction's first longword, its opcode byte replaced and bits 7..5
  cleared; bit 7 a first result carried, 6 a second, 5 the exception
  operand), the instruction (-3116), prev (-3112), pending (-3108), the
  LABEL$ count (-3096).  The -EXP opcode rewrites are a jump table on
  opc - 75 (move 75, add 79, sub 81, extend7 88, extend15 89; register
  31 as an operand's +0 byte, `cmpi.b #31'); the classes are tested by
  `btst' in masks: 0x40800 (limit 11, pmove 18: no cell), 0x33C10D (the
  classes that may carry an exception operand: alu, call, fp_double,
  immediate, trap, load_pair, load, fp_single, svc, store), 0x1000062
  (branch, fp_branch, jump, return); the operand kinds in 0x103C0000
  (displacement_routine .. displacement_literal_pool,
  exception_information) and 4094 (ip_reg .. well_behaved_memory).
  The operands are copied 12 bytes at a time (three `move.l (A0)+'). }

procedure zzzzz_$process_routine(
    rtn: rtn_ptr_t);
var
  head: cell_t;
  exp: boolean;
  label_seen: boolean;
  bb: bb_ptr_t;
  last_mark: cell_ptr_t;
  hdr: record
    case integer of
      1: (i: instr_hdr_t);
      2: (c: cell_hdr_t);
  end;
  instr: instr_ptr_t;
  prev: cell_ptr_t;
  pending: cell_ptr_t;
  labels: integer32;
  opc: integer;
  nres: integer32;
  size: integer32;
  k: integer32;
  j: integer32;
  cell: cell_ptr_t;
begin
  exp := cargs_$options.exp;
  labels := 0;
  rtn^.epilogues := nil;
  last_mark := nil;
  head.next := nil;
  prev := addr(head);
  bb := rtn^.bbs;
  while bb <> nil do begin
    if exp and bb^.f.needs_label then
      discard(basic_block_label(bb));
    label_seen := false;
    pending := nil;
    instr := bb^.first;
    while instr <> nil do begin
      hdr.i := instr^.h;
      opc := instr^.opc;
      if exp then begin
        if instr^.h.sets_cc then begin
          case opc of
            75:                         { move }
              if instr^.opnds[2].h.num = 31 then
                opc := 73;              { tst }
            88:                         { extend7 }
              if instr^.opnds[2].h.num = 31 then
                opc := 71;              { tstb }
            89:                         { extend15 }
              if instr^.opnds[2].h.num = 31 then
                opc := 72;              { tstw }
            81:                         { sub }
              if (instr^.opnds[1].h.kind = operand$ip_reg)
                 and (instr^.opnds[3].h.num = 31) then
                opc := 74;              { cmp }
            79:                         { add }
              if (instr^.opnds[1].h.kind = operand$immediate)
                 and (instr^.opnds[3].h.num = 31) then begin
                opc := 74;
                instr^.opnds[1].value := -instr^.opnds[1].value;
              end;
            otherwise
          end;
        end
        else if opc = 132 then          { return }
          opc := 69;                    { jump }
      end;
      hdr.c.opc := opc;
      hdr.c.b0_7 := false;
      hdr.c.b0_6 := false;
      hdr.c.b0_5 := false;
      if instruction_attributes[opc].class = class$label then begin
        cell := cell_ptr_t(instr);
        cell^.h := hdr.c;
        cell^.l8 := instr^.l28;
        cell^.l16 := instr^.l32;
        cell^.h.is_label := true;
        if not label_seen then begin
          if opc = 199 then begin       { label }
            cell^.l12 := integer32(instr^.opnds[1].link);
            if cell^.l12 = 0 then begin
              opc := 200;               { label$ }
              hdr.c.opc := 200;
              cell^.h.opc := 200;
              instr^.opc := 200;
            end;
          end;
          if opc = 200 then begin
            labels := labels + 1;
            cell^.l12 := labels;
          end;
          label_seen := true;
          prev^.next := cell;
          prev := cell;
        end;
      end
      else if not (instruction_attributes[opc].class in
                   [class$limit, class$pmove]) then begin
        nres := instruction_attributes[opc].nresults;
        if exp then begin
          size := code_cell_size[opc];
          if nres > 0 then begin
            hdr.c.b0_7 := true;
            if nres >= 2 then
              hdr.c.b0_6 := true;
          end;
        end
        else if (opc = 204) or (opc = 196) then begin   { ltorg, entry }
          nres := 1;
          size := 32;
        end
        else if (nres >= 2) and (instr^.opnds[2].h.kind in
                 [operand$displacement_routine..operand$displacement_literal_pool,
                  operand$exception_information]) then begin
          hdr.c.b0_6 := true;
          nres := 2;
          size := 44;
        end
        else if (nres > 0) and (instr^.opnds[1].h.kind in
                 [operand$displacement_routine..operand$displacement_literal_pool,
                  operand$exception_information]) then begin
          hdr.c.b0_7 := true;
          nres := 1;
          size := 32;
        end
        else begin
          nres := 0;
          size := 20;
        end;
        k := 0;
        if instruction_attributes[opc].class in
           [class$alu, class$call, class$fp_double, class$immediate,
            class$trap, class$load_pair, class$load, class$fp_single,
            class$svc, class$store] then begin
          k := instruction_attributes[opc].nresults + 1;
          while k <= instr^.h.nopnds do begin
            if instr^.opnds[k].h.kind = operand$exception_information
            then begin
              hdr.c.b0_5 := true;
              size := size + 12;
              exit;
            end;
            k := k + 1;
          end;
        end;
        hdr.c.opc := opc;
        cell := mrh_$alloc(heap, size);
        for j := 1 to nres do begin
          if exp and (instr^.opnds[j].h.kind = operand$flow_graph_edge)
          then begin
            instr^.opnds[j].h.kind := operand$label_reference;
            instr^.opnds[j].link := opnd_ptr_t(basic_block_label(
                zz_edge_ptr_t(instr^.opnds[j].ptr)^.target));
          end;
          cell^.opnds[j] := instr^.opnds[j];
        end;
        if hdr.c.b0_5 then
          cell^.opnds[nres + 1] := instr^.opnds[k];
        cell^.h := hdr.c;
        cell^.l8 := instr^.l28;
        cell^.l12 := instr^.l24;
        cell^.l16 := instr^.l32;
        prev^.next := cell;
        if instruction_attributes[cell^.h.opc].class in
           [class$branch, class$fp_branch, class$jump, class$return] then begin
          if (instr^.opnds[1].h.kind in
              [operand$ip_reg..operand$well_behaved_memory])
             and (instr^.opnds[1].lts = rtn^.l112) then
            mark_start_of_epilogue(rtn, last_mark, prev, pending);
          pending := nil;
        end
        else if cell^.l16 <> 0 then
          pending := nil
        else if (pending = nil) and (cell^.h.opc <> 192)
                and (instruction_attributes[cell^.h.opc].class <> class$entry)
        then
          pending := prev;
        prev := cell;
      end;
      instr := instr^.next;
    end;
    bb := bb^.next;
  end;
  prev^.next := nil;
  rtn^.cells := head.next;
  zz_node_ptr_t(rtn^.node)^.code^.last := prev;
end;
