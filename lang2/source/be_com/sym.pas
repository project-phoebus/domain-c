{ sym - the back end's view of the IL's symbols (cc.a88k only): labels
  attached to the top-level spine's label nodes, the routine's local
  symbols initialized (common members given copies with live ranges,
  the variables referenced uplevel listed), qualified routine names and
  symbols' print names, displacements and sizes, static allocation,
  and literals reformatted for the literal pools (lit_t).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x27A680  attach_label (internal)
    --------  0x27A770  sym_$initialize_this_local_symbol
    --------  0x27AACA  sym_$initialize_local_symbols
    --------  0x27AB3A  sym_$backend_label_for_case_jump
    --------  0x27AB62  sym_$fully_qualified_routine_name
    --------  0x27ABF6  add_arrow (internal)
    --------  0x27AC22  sym_$append_symbol_print_name
    --------  0x27AD88  sym_$display_symbol_print_name
    --------  0x27ADF2  sym_$has_print_name
    --------  0x27AE70  sym_$object_with_immediate_disp
    --------  0x27AEC8  sym_$is_static_vat
    --------  0x27AF0C  sym_$has_displacement
    --------  0x27AF3E  sym_$displacement_literal_pool
    --------  0x27AF82  sym_$displacement
    --------  0x27B1A0  sym_$allocation_size_in_bytes
    --------  0x27B2C6  sym_$allocate_static_variable
    --------  0x27B41C  make_properly_sized_copy (internal)
    --------  0x27B47A  sym_$reformat_literal
    --------  0x27B66C  sym_$reformat_literal_operand
    A5 0x492E74: sym_line (+0), the print name sym_$display_symbol_print_
    name builds (a varying string of 256).

  The IL nodes are read through il.ins.pas's views (xp, xl, xw, xc by
  offset) and, for the two fields at offsets no view reaches (+42's
  middle bytes, +66), sym_n66_t and bytes.  Kinds: 109 a variable (+72
  its vat, +32 its flags, +56 its displacement, +44 its alignment's
  log), 110 a common member (+11 bits 7..4 its vat, +24 its flags, +12
  its displacement, +28 the next member of its common, +44 bits 7..4
  its storage class), 117 a label symbol, 144 a label node of the
  spine (+80 its label, +60 its code cell, +64 its symbol), 163 a
  constant's address, 214/215 a displacement table, 223 a handler; the
  vats: 1 static, 2 the frame, 5 by reference.  A label (lir_$new_label,
  sym_label_t): +4 its label instruction, +10 bit 7 marked required,
  bit 5 its block known, +12 the block.

  Not known from the original: every local and parameter name; the
  view types. }

module sym;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';

type
  { A label (lir_$new_label's). }
  sym_label_ptr_t = ^sym_label_t;
  sym_label_t = record
    next: sym_label_ptr_t;              { +0: on the routine's lists
                                          (rtn +4, +8) }
    instr: instr_ptr_t;                 { +4: its label instruction }
    w8: integer;                        { +8 }
    f10: packed record                  { +10 }
      required: boolean;                { .7 }
      b6: boolean;
      in_bb: boolean;                   { .5: bb is set }
      b4_0: 0..31;
      b11: 0..255;
      end;
    bb: bb_ptr_t;                       { +12 }
  end;

  { A node's longword at +66 (the uplevel-referenced common members'
    chain). }
  sym_n66_ptr_t = ^sym_n66_t;
  sym_n66_t = record
    space0: array [0..65] of char;
    next66: il_$node_ptr_t;             { +66 }
  end;

  { A routine's name node (its +296): the name's length at +16, its
    characters from +18. }
  sym_name_ptr_t = ^sym_name_t;
  sym_name_t = record
    space0: array [0..15] of char;
    len: 0..65535;                      { +16 }
    chars: array [1..256] of char;      { +18 }
  end;

  { An instruction's source position (+32): its line, a word. }
  sym_ipos_ptr_t = ^sym_ipos_t;
  sym_ipos_t = record
    line: 0..65535;                     { +32 }
    w2: integer;
  end;

  sym_line_ptr_t = ^prtsub_$line_t;
  sym_words_ptr_t = ^sym_words_t;
  sym_words_t = array [0..32767] of integer;

  { A literal pool's entries list (sym_$displacement_literal_pool's
    second argument: +44). }
  sym_pool_ptr_t = ^sym_pool_t;
  sym_pool_t = record
    space0: array [0..43] of char;
    entries: lpe_ptr_t;                 { +44 }
  end;

var
  sym_line: prtsub_$line_t;             { +0 }

{ attach_label - node's label (a label node of the spine, kind 144:
  bug_check otherwise), made the first time (lir_$new_label, node +80),
  with its label instruction made the first time
  (zzzzz_$preallocate_label, node +60; its source line node +42's
  bits 23..8; put first in the label's block when that is known); its
  symbol sym (node +64, the instruction's operand 1 link) when sym is
  given.

  0x27A680, 0xB6 bytes, no A5: sym (8) in D2, node (12) in D4; the
  label in D3, A0. }

function attach_label(
    sym: il_$node_ptr_t;
    node: il_$node_ptr_t): sym_label_ptr_t; options(val_param, internal);
var
  lab: sym_label_ptr_t;
  li: instr_ptr_t;
  first: instr_ptr_t;
  b: bb_ptr_t;
begin
  if node^.kind <> label_node then
    bug_check('SYM_\ATTACH_LABEL -- unexpected kind on top-level spine%$');
  lab := sym_label_ptr_t(node^.xp[20]);
  if lab = nil then begin
    lab := lir_$new_label;
    node^.xp[20] := il_$node_ptr_t(lab);
  end;
  li := lab^.instr;
  if li = nil then begin
    li := zzzzz_$preallocate_label;
    lab^.instr := li;
    node^.xp[15] := il_$node_ptr_t(li);
    sym_ipos_ptr_t(addr(li^.l32))^.line :=
      (ord(node^.xc[43]) * 256) ! ord(node^.xc[44]);
    if lab^.f10.in_bb then begin
      b := lab^.bb;
      first := b^.first;
      li^.bb := b;
      li^.next := first;
      b^.first := li;
      if first = nil then
        b^.last := li
      else
        first^.prev := li;
    end;
  end;
  if sym <> nil then begin
    node^.xp[16] := sym;
    li^.opnds[1].link := opnd_ptr_t(sym);
  end;
  attach_label := lab;
end;

{ sym_$initialize_this_local_symbol - one local symbol of rtn readied;
  the next on its list.
  - A common member (110, the next its +4): its block (+40) the
    routine's node unless its class (+44 bits 7..4) is 1.  Of class 3:
    its flags' bits 29, 27..25, 19, 18 cleared and, the first time (bit
    24 then set), when it is not bit 13's, has no next member (+28) and
    its +44 bit 3 is clear, and either its +44 bit 2 is set or the
    routine has handlers (il_180's +379 bit 4) and it is static: +44
    bit 2 set, made a frame member (vat 2, +44 bit 3 and flag 6
    cleared) for the routine, and, when the ISC gave it a live range
    (isc_$get_il_live_range), a copy (gspace, its name's length + 75
    rounded to 4; unlinked, displacement to a multiple of 4, no next
    member, +36, +58, +62 cleared; size code 3 when smaller than 4)
    made that live range's memory home (lir_main_c8c set), which keeps
    the old vat, +44 bit 3 and flag 6 and gets flag 22 (26 cleared);
    with flag 8, a frame member or one of flag 30 is chained on the
    routine's uplevel list (rtn +12, through +66).  Of class 6: its
    label node (+48, kind 144) given a label with this symbol, put on
    the routine's +4 list (+45 bit 6) or +8 list (+44 bit 0) and marked
    required (and its instruction's +3 bit 7) unless it is.
  - A variable (109, the next its +16): its flags (+32) likewise, the
    first time a frame variable of flag 8 without flag 10 chained on
    the uplevel list (through +76), bug_check when its alignment is
    beyond a quadword.
  - A label symbol (117): its label node (+28) given a label, put on
    the +8 list when its +37 bit 6 is set.

  0x27A770, 0x318 bytes: rtn (8) in D6, node (12); the flags in D2, +44
  bit 3 in D3 (`sne'), the old vat in D4, the copy in D7, its size in
  D5 (copied by longwords, `subq.l #4; tst.l; bgt': at least once).
  The mask 16#D1F3FFFF (`andi.l #-772538369'). }

function sym_$initialize_this_local_symbol(
    rtn: rtn_ptr_t;
    node: il_$node_ptr_t): il_$node_ptr_t;
var
  f: integer32;
  b3: boolean;
  vat: integer;
  lr: lr_ptr_t;
  copy: il_$node_ptr_t;
  n: integer32;
  k: integer32;
  ln: il_$node_ptr_t;
  lab: sym_label_ptr_t;
begin
  case node^.kind of
    fortran_symbol: begin
      if (ord(node^.xc[44]) & 16#F0) div 16 <> 1 then
        node^.xp[10] := rtn^.node;
      case (ord(node^.xc[44]) & 16#F0) div 16 of
        3: begin
          f := node^.xl[6] & 16#D1F3FFFF;
          if (f & 16#01000000) <> 0 then
            node^.xl[6] := f
          else begin
            f := f ! 16#01000000;
            node^.xl[6] := f;
            b3 := (ord(node^.xc[44]) & 8) <> 0;
            if ((f & 16#2000) = 0) and (node^.xl[7] = 0) and not b3 then
              if ((ord(node^.xc[44]) & 4) <> 0)
                 or (((ord(il_180^.xc[379]) & 16#10) <> 0)
                     and ((ord(node^.xc[11]) & 16#F0) div 16 = 1)) then begin
                node^.xc[44] := chr(ord(node^.xc[44]) ! 4);
                vat := (ord(node^.xc[11]) & 16#F0) div 16;
                node^.xc[11] := chr((ord(node^.xc[11]) & 15) ! 16#20);
                node^.xc[44] := chr(ord(node^.xc[44]) & 16#F7);
                node^.xl[6] := f & 16#FFFFFFBF;
                lr := isc_$get_il_live_range(node);
                if lr = nil then
                  copy := node
                else begin
                  lir_main_c8c := true;
                  n := ((node^.xw[35] & 16#FFFF) + 75) & 16#FFFFFFFC;
                  copy := gspace(n);
                  lr^.memory_home := copy;
                  k := 1;
                  repeat
                    copy^.xl[k - 1] := node^.xl[k - 1];
                    k := k + 1;
                    n := n - 4;
                  until n <= 0;
                  copy^.xp[1] := nil;
                  copy^.xl[3] := node^.xl[3] & 16#FFFFFFFC;
                  copy^.xl[7] := 0;
                  copy^.xl[9] := 0;
                  copy^.xw[29] := 0;
                  copy^.xw[30] := 0;
                  copy^.xw[31] := 0;
                  copy^.xw[32] := 0;
                  if sym_$allocation_size_in_bytes(copy) < 4 then
                    copy^.xc[10] := chr((ord(copy^.xc[10]) & 16#F0) ! 3);
                end;
                copy^.xc[11] := chr((ord(copy^.xc[11]) & 15) ! (vat * 16));
                copy^.xc[44] := chr((ord(copy^.xc[44]) & 16#F7) ! (ord(b3) * 8));
                copy^.xl[6] := (copy^.xl[6] & 16#FBFFFFFF) ! (f & 64)
                               ! 16#00400000;
              end;
            if (f & 16#100) <> 0 then
              if ((ord(node^.xc[11]) & 16#F0) div 16 = 2)
                 or (var_$local_copy in node^.fs_attr) then begin
                sym_n66_ptr_t(node)^.next66 := rtn^.l12;
                rtn^.l12 := node;
              end;
          end;
        end;
        6: begin
          ln := node^.xp[12];
          if ln^.kind = label_node then begin
            lab := attach_label(node, ln);
            if not lab^.f10.required then
              if (ord(node^.xc[45]) & 64) <> 0 then begin
                lab^.next := rtn^.l4;
                rtn^.l4 := lab;
                cell_head_ptr_t(lab^.instr)^.b3_7 := true;
                lab^.f10.required := true;
              end
              else if (ord(node^.xc[44]) & 1) <> 0 then begin
                lab^.next := rtn^.l8;
                rtn^.l8 := lab;
                cell_head_ptr_t(lab^.instr)^.b3_7 := true;
                lab^.f10.required := true;
              end;
          end;
        end;
        otherwise
          ;
      end;
      sym_$initialize_this_local_symbol := node^.xp[1];
    end;
    var_name: begin
      f := node^.xl[8] & 16#D1F3FFFF;
      if (f & 16#01000000) <> 0 then
        node^.xl[8] := f
      else begin
        node^.xl[8] := f ! 16#01000000;
        if ((f & 16#100) <> 0) and (node^.xw[36] = 2)
           and ((f & 16#400) = 0) then begin
          node^.xp[19] := rtn^.l12;
          rtn^.l12 := node;
          if node^.xw[22] > 3 then
            bug_check('SYM_$VARS_UPLEVEL_REFERENCED -- alignment greater than quadword%$');
        end;
      end;
      sym_$initialize_this_local_symbol := node^.xp[4];
    end;
    label_name: begin
      lab := attach_label(node, node^.xp[7]);
      if (ord(node^.xc[37]) & 64) <> 0 then
        if not lab^.f10.required then begin
          lab^.next := rtn^.l8;
          rtn^.l8 := lab;
          cell_head_ptr_t(lab^.instr)^.b3_7 := true;
          lab^.f10.required := true;
        end;
      sym_$initialize_this_local_symbol := node^.xp[4];
    end;
    otherwise
      sym_$initialize_this_local_symbol := node^.xp[4];
  end;
end;

{ sym_$initialize_local_symbols - every local symbol of rtn readied:
  the routine block's (node +180, each entry's +24, chained at +4),
  then the symbols (+16) of the block and of each nested block of kind
  172 after it (chained at +4); lir_main_c8c cleared first.

  0x27AACA, 0x70 bytes: rtn (8) in A3, the block A2, the entry A4 (its
  +24 passed through -8). }

procedure sym_$initialize_local_symbols(
    rtn: rtn_ptr_t);
var
  blk: il_$node_ptr_t;
  s: il_$node_ptr_t;
begin
  lir_main_c8c := false;
  blk := rtn^.node;
  s := blk^.xp[45];
  while s <> nil do begin
    discard(sym_$initialize_this_local_symbol(rtn, s^.xp[6]));
    s := s^.xp[1];
  end;
  repeat
    s := blk^.xp[4];
    while s <> nil do
      s := sym_$initialize_this_local_symbol(rtn, s);
    blk := blk^.xp[1];
  until (blk = nil) or else (blk^.kind <> inner_blk);
end;

{ sym_$backend_label_for_case_jump - node's label (no symbol), its
  instruction's +3 bit 7 set.  0x27AB3A, 0x28 bytes: node (8); A0 left
  holding the label. }

function sym_$backend_label_for_case_jump(
    nd: univ_ptr): univ_ptr;
var
  node: il_$node_ptr_t;
  lab: sym_label_ptr_t;
begin
  node := nd;
  lab := attach_label(nil, node);
  cell_head_ptr_t(lab^.instr)^.b3_7 := true;
  sym_$backend_label_for_case_jump := lab;
end;

{ sym_$fully_qualified_routine_name - node's routine name after its
  parents' (from the outermost, +8), joined by '\', to the end of buf
  (cleared first when top), up to 256 characters; only routines (107)
  and procedures (108) and the top node contribute.

  0x27AB62, 0x94 bytes: buf (8) in D3, node (12) in A2, top (16) a byte
  in D2; recursive with false (`clr.w -(SP)'); the name (+296) its
  length at +16 and characters from +18.  No result (batch A, PA4: was
  a function, top a word; bin and com follow). }

procedure sym_$fully_qualified_routine_name(
    buf: univ_ptr;
    nd: univ_ptr;
    top: boolean);
var
  node: il_$node_ptr_t;
  s: sym_line_ptr_t;
  nm: sym_name_ptr_t;
  n: integer32;
  i: integer32;
begin
  node := nd;
  s := buf;
  if top then
    s^.length := 0;
  if node^.xp[2] <> nil then
    sym_$fully_qualified_routine_name(buf, node^.xp[2], false);
  if (node^.kind = procedure_blk) or top
      or (node^.kind = function_blk) then begin
    n := s^.length;
    if n <> 0 then begin
      n := n + 1;
      s^.body[n] := '\';
    end;
    nm := sym_name_ptr_t(node^.xp[74]);
    i := 0;
    while (i < nm^.len) and (n < 256) do begin
      n := n + 1;
      i := i + 1;
      s^.body[n] := nm^.chars[i];
    end;
    s^.length := n;
  end;
end;

{ add_arrow - '->' to the end of s, as far as it fits.  0x27ABF6, 0x2C
  bytes, no frame: s (4,SP) in A0. }

procedure add_arrow(
    s: sym_line_ptr_t); options(val_param, internal);
var
  n: integer32;
begin
  n := s^.length;
  if n < 256 then begin
    n := n + 1;
    s^.body[n] := '-';
  end;
  if n < 256 then begin
    n := n + 1;
    s^.body[n] := '>';
  end;
  s^.length := n;
end;

{ sym_$append_symbol_print_name - node's print name to the end of buf
  (prtobj), '->' first for what is reached through a pointer (a
  variable of vat 5 with a name, a common member of class 1 or 3 and
  vat 5, a constant's address of a label node: the label's symbol), a
  trailing parenthesized part removed; '-><displacement table>' for a
  constant's address of a displacement table; false for nil and for
  what has no print name (a variable or label symbol without a name,
  other kinds but routines, procedures, 167 and a few with a name
  (+296)).

  0x27AC22, 0x13C bytes: buf (8) in A2, node (12) in A3; the kinds'
  set [105..108, 167] after the routine (0x27AD5E, bound 175); prtcats
  given 20 after add_arrow's pad (`addq.l #2,SP; move.w #20,-(SP)',
  docs/rev889-patterns.md 51). }

function sym_$append_symbol_print_name(
    buf: univ_ptr;
    nd: univ_ptr): boolean;
label
  10, 20;
var
  node: il_$node_ptr_t;
  s: sym_line_ptr_t;
  n: integer32;
begin
  node := nd;
  s := buf;
  sym_$append_symbol_print_name := false;
  if node = nil then
    return;
  if (node^.kind = var_name) and (node^.xp[1] <> nil) then begin
    if node^.xw[36] <> 5 then
      goto 10;
    add_arrow(s);
    goto 10;
  end
  else if node^.kind = fortran_symbol then begin
    if not ((ord(node^.xc[44]) & 16#F0) div 16 in [1, 3]) then
      goto 10;
    if (ord(node^.xc[11]) & 16#F0) div 16 <> 5 then
      goto 10;
    add_arrow(s);
    goto 10;
  end
  else if node^.kind = addr_con then
    if node^.xp[2]^.kind = label_node then begin
      add_arrow(s);
      node := node^.xp[2]^.xp[16];
      goto 10;
    end;
  if node^.kind = label_name then
    if node^.xp[1] <> nil then
      goto 10;
  if node^.kind in [program_blk..function_blk, entry_blk] then
    if node^.xp[74] <> nil then
      goto 10;
  if node^.kind = addr_con then
    if node^.xp[2]^.kind in [case_node_range_check,
                             case_node_no_range_check] then begin
      add_arrow(s);
      prtcats(s^, '<displacement table>', 20);
      goto 20;
    end;
  return;
10:
  prtobj(s^, node);
20:
  n := s^.length;
  if s^.body[n] = ')' then begin
    repeat
      n := n - 1;
    until s^.body[n] = '(';
    s^.length := n - 1;
  end;
  sym_$append_symbol_print_name := true;
end;

{ sym_$display_symbol_print_name - node's print name written (vfmt_$ws
  '%a': to lst_140's stream in the BIN phase, else stream 1); whether it
  has one.

  0x27AD88, 0x66 bytes: node (8); sym_line (A5 +0); the stream a word at
  -2, the length a longword at -12. }

function sym_$display_symbol_print_name(
    nd: univ_ptr): boolean;
var
  node: il_$node_ptr_t;
  ok: boolean;
  stream: integer;
  n: integer32;
begin
  node := nd;
  sym_line.length := 0;
  ok := sym_$append_symbol_print_name(addr(sym_line), node);
  if ok then begin
    if at_backend_phase = phase$bin then
      stream := lst_140
    else
      stream := 1;
    n := sym_line.length;
    vfmt_$ws(stream, '%a%$', sym_line.body, n);
  end;
  sym_$display_symbol_print_name := ok;
end;

{ sym_$has_print_name - whether node has a print name: not for nil and
  the kinds 138, 143, 144, 152, 165, 214, 215; a variable or label
  symbol when it has a name, a common member when its name is not
  empty; any other kind.  0x27ADF2, 0x62 bytes (nothing calls it; no
  heading in backend.ins.pas): the set after the routine (0x27AE54,
  bound 223). }

function sym_$has_print_name(
    node: il_$node_ptr_t): boolean;
begin
  if node = nil then
    sym_$has_print_name := false
  else if node^.kind in [gen_tree_node, cmp_tree_node, label_node, alloc_temp,
                         cs_temp, case_node_range_check,
                         case_node_no_range_check] then
    sym_$has_print_name := false
  else if (node^.kind = var_name) or (node^.kind = label_name) then
    sym_$has_print_name := node^.xp[1] <> nil
  else if node^.kind = fortran_symbol then
    sym_$has_print_name := node^.xw[35] <> 0
  else
    sym_$has_print_name := true;
end;

{ sym_$object_with_immediate_disp - node when an immediate displacement
  names it: a variable with a name of nonzero length (+16 of its
  name), a common member with a name, a constant's address; else nil.
  0x27AE70, 0x58 bytes: node (8) in A1, the result A0. }

function sym_$object_with_immediate_disp(
    nd: univ_ptr): univ_ptr;
var
  node: il_$node_ptr_t;
  r: il_$node_ptr_t;
begin
  node := nd;
  r := nil;
  if node <> nil then
    case node^.kind of
      var_name:
        if node^.xp[1] <> nil then
          if node^.xp[1]^.xw[8] <> 0 then
            r := node;
      fortran_symbol:
        if node^.xw[35] <> 0 then
          r := node;
      addr_con:
        r := node;
      otherwise
        ;
    end;
  sym_$object_with_immediate_disp := r;
end;

{ sym_$is_static_vat - whether node (a variable or common member; else
  vat 2) is static (vat 1).  0x27AEC8, 0x44 bytes. }

function sym_$is_static_vat(
    nd: univ_ptr): boolean;
var
  node: il_$node_ptr_t;
  vat: integer;
begin
  node := nd;
  if node^.kind = var_name then
    vat := node^.xw[36]
  else if node^.kind = fortran_symbol then
    vat := (ord(node^.xc[11]) & 16#F0) div 16
  else
    vat := 2;
  sym_$is_static_vat := vat = 1;
end;

{ sym_$has_displacement - whether node is a variable or a common
  member.  0x27AF0C, 0x32 bytes. }

function sym_$has_displacement(
    nd: univ_ptr): boolean;
var
  node: il_$node_ptr_t;
begin
  node := nd;
  if node^.kind = var_name then
    sym_$has_displacement := true
  else if node^.kind = fortran_symbol then
    sym_$has_displacement := true
  else
    sym_$has_displacement := false;
end;

{ sym_$displacement_literal_pool - the address in pool of the entry
  whose literal is node's (0 when none, or no pool).  0x27AF3E, 0x44
  bytes: node (8) in A0, pool (12): its entries at +44 (lpe_t, chained
  at +0; the literal's +0 the node). }

function sym_$displacement_literal_pool(
    p1: univ_ptr;
    p2: univ_ptr): integer32;
var
  e: lpe_ptr_t;
  d: integer32;
begin
  d := 0;
  if p2 <> nil then begin
    e := sym_pool_ptr_t(p2)^.entries;
    while e <> nil do begin
      if e^.lit^.p0 = p1 then begin
        d := e^.addr;
        exit;
      end;
      e := e^.next;
    end;
  end;
  sym_$displacement_literal_pool := d;
end;

{ sym_$displacement - node's displacement: a variable's +56, a common
  member's +12, a constant's address's +16, a label's or a handler's
  asynchronous entry's code cell's location (+8; bug_check when it is
  not marked required, +3 bit 7, or listed as not in the cells: +3 bit
  6 without bit 5), a displacement table's (+52's +8); bug_check for
  other kinds (D0 left as it is).

  0x27AF82, 0xEC bytes: node (8) in A0; the cells through cell_t's h. }

function sym_$displacement(
    p: univ_ptr): integer32;
var
  node: il_$node_ptr_t;
  c: cell_ptr_t;
begin
  node := p;
  if node^.kind = var_name then
    sym_$displacement := node^.xl[14]
  else if node^.kind = fortran_symbol then
    sym_$displacement := node^.xl[3]
  else if node^.kind = addr_con then
    sym_$displacement := node^.xl[4]
  else if node^.kind = label_node then begin
    c := cell_ptr_t(node^.xp[15]);
    if not c^.h.b3_7 then
      bug_check('SYM_$DISPLACEMENT -- label is not marked required%$');
    if c^.h.b3_6 and not c^.h.is_label then
      bug_check('SYM_$DISPLACEMENT -- label is not on the list of code cells%$');
    sym_$displacement := c^.l8;
  end
  else if (node^.kind = case_node_range_check)
      or (node^.kind = case_node_no_range_check) then
    sym_$displacement := cell_ptr_t(node^.xp[13])^.l8
  else if node^.kind = exception_handler_entry then begin
    c := cell_ptr_t(node^.xp[13]);
    if c = nil then
      bug_check('SYM_$DISPLACEMENT -- handler has no asynchronous entry label%$');
    if c^.h.b3_6 and not c^.h.is_label then
      bug_check('SYM_$DISPLACEMENT -- handler asynchronous entry label is not on the list of code cells%$');
    sym_$displacement := c^.l8;
  end
  else
    bug_check('SYM_$DISPLACEMENT -- unknown object type%.');
end;

{ sym_$allocation_size_in_bytes - the bytes node occupies: 4 for what
  is reached through a pointer (vat 5) or flag 17; a variable's bits
  (+36) in bytes rounded up to its alignment (+44, a log); a common
  member's sz_fsym, or with members after it (+28, round to it) the
  span from the lowest displacement to the highest end among them;
  bug_check for other kinds.

  0x27B1A0, 0xF0 bytes: node (8) in A2; the lowest in D3, the highest
  end in D2. }

function sym_$allocation_size_in_bytes(
    nd: univ_ptr): integer32;
var
  node: il_$node_ptr_t;
  m: il_$node_ptr_t;
  a: integer32;
  lo: integer32;
  hi: integer32;
  e: integer32;
begin
  node := nd;
  if node^.kind = var_name then begin
    if node^.xw[36] = 5 then
      sym_$allocation_size_in_bytes := 4
    else if var_$strength_reduction in node^.vr_attr then
      sym_$allocation_size_in_bytes := 4
    else begin
      a := lshft(1, node^.xw[22]) - 1;
      sym_$allocation_size_in_bytes :=
        (rshft(node^.xl[9] + 7, 3) + a) & ~a;
    end;
  end
  else if node^.kind = fortran_symbol then begin
    if (ord(node^.xc[11]) & 16#F0) div 16 = 5 then
      sym_$allocation_size_in_bytes := 4
    else if var_$strength_reduction in node^.fs_attr then
      sym_$allocation_size_in_bytes := 4
    else if node^.xp[7] = nil then
      sym_$allocation_size_in_bytes := sz_fsym(node)
    else begin
      lo := node^.xl[3];
      hi := sz_fsym(node) + node^.xl[3];
      m := node^.xp[7];
      while m <> node do begin
        if lo > m^.xl[3] then
          lo := m^.xl[3];
        e := sz_fsym(m) + m^.xl[3];
        if hi < e then
          hi := e;
        m := m^.xp[7];
      end;
      sym_$allocation_size_in_bytes := hi - lo;
    end;
  end
  else
    bug_check('SYM_$ALLOCATION_SIZE_IN_BYTES -- unknown object type%$');
end;

{ sym_$allocate_static_variable - sym (a variable or common member not
  yet static) placed in the routine block's static data (il_180's
  +192, its +20 the next free byte): aligned by its size (masks 0, 1,
  3, 7; a variable's own alignment when larger), made static (vat 1),
  its displacement set; bug_check for other kinds and when the data
  pass 32767 bytes.

  0x27B2C6, 0xE4 bytes: sym (8), size (12) in D2; the mask D0, the
  displacement D4 (`add.l (20,A2); subq.l #1; and.l' with the mask's
  complement: the free byte plus the mask less one, kept). }

procedure sym_$allocate_static_variable(
    sym: univ_ptr;
    size: integer32);
var
  node: il_$node_ptr_t;
  blk: il_$node_ptr_t;
  mask: integer32;
  m: integer32;
  off: integer32;
  e: integer32;
begin
  node := sym;
  if size <= 1 then
    mask := 0
  else if size = 2 then
    mask := 1
  else if size <= 4 then
    mask := 3
  else
    mask := 7;
  blk := il_180^.xp[48];
  if node^.kind = var_name then begin
    m := lshft(1, node^.xw[22]) - 1;
    if mask < m then
      mask := m;
  end;
  off := (mask + blk^.xl[5] - 1) & ~mask;
  if node^.kind = var_name then begin
    if node^.xw[36] = 1 then
      return;
    node^.xw[36] := 1;
    node^.xl[14] := off;
  end
  else if node^.kind = fortran_symbol then begin
    if (ord(node^.xc[11]) & 16#F0) div 16 = 1 then
      return;
    node^.xc[11] := chr((ord(node^.xc[11]) & 15) ! 16#10);
    node^.xl[3] := off;
  end
  else
    bug_check('SYM_$ALLOCATE_STATIC_VARIABLE -- unexpect variable kind%$');
  e := size + off;
  if e > 32767 then
    bug_check('SYM_$ALLOCATE_STATIC_VARIABLE -- data section overflow%$');
  blk^.xl[5] := e;
end;

{ make_properly_sized_copy - a string literal for node (its length +16,
  characters from +18): 12 bytes and the characters (pas_$new), the
  length at +6, node's +12 at +8, the characters from +12 copied by
  words.  0x27B41C, 0x5E bytes, no A5: node (8) in A2; the literal in
  A0. }

function make_properly_sized_copy(
    node: il_$node_ptr_t): lit_ptr_t; options(val_param, internal);
var
  l: lit_ptr_t;
  i: integer32;
begin
  pas_$new(l, (node^.xw[8] & 16#FFFF) + 12);
  for i := 1 to ((node^.xw[8] & 16#FFFF) + 1) div 2 do
    sym_words_ptr_t(l)^[5 + i] := sym_words_ptr_t(node)^[8 + i];
  l^.len := node^.xw[8];
  l^.value := node^.xl[3];
  make_properly_sized_copy := l;
end;

{ sym_$reformat_literal - a literal (lit_t, pas_$new of its size) for a
  constant node: the integer kinds 81, 80, 200, 82, 84, 83, 86, 85, 78,
  77, 79, 87 (lit kinds 0..11, 12 bytes, the value from +8), the reals
  88, 89, 90 (12..14, 16 bytes, +12 and +16), 198 (15, 24 bytes, +12 ..
  +24), the strings 92 and 156 (19 and 20, make_properly_sized_copy),
  212 (16, 6 bytes); nil for others.  Its +0 the node.

  0x27B47A, 0x1F2 bytes: node (8) in A2, its kind in D2; the kinds
  tested as compare chains, twice for the integers (the lit kind in
  D0). }

function sym_$reformat_literal(
    nd: univ_ptr): univ_ptr;
var
  node: il_$node_ptr_t;
  k: il_$kind_t;
  l: lit_ptr_t;
  lk: integer;
begin
  node := nd;
  k := node^.kind;
  if (k = char_ob) or (k = llogical_ob) or (k = blogical_ob)
      or (k = slogical_ob) or (k = ulinteger_ob) or (k = ubinteger_ob)
     or (k = usinteger_ob) or (k = uinteger_ob) or (k = linteger_ob)
         or (k = binteger_ob) or (k = sinteger_ob)
     or (k = integer_ob) then begin
    pas_$new(l, 12);
    if k = integer_ob then lk := 0
    else if k = sinteger_ob then lk := 1
    else if k = binteger_ob then lk := 2
    else if k = linteger_ob then lk := 3
    else if k = uinteger_ob then lk := 4
    else if k = usinteger_ob then lk := 5
    else if k = ubinteger_ob then lk := 6
    else if k = ulinteger_ob then lk := 7
    else if k = slogical_ob then lk := 8
    else if k = blogical_ob then lk := 9
    else if k = llogical_ob then lk := 10
    else if k = char_ob then lk := 11;
    l^.value := node^.xl[2];
  end
  else if (k = real_ob) or (k = dpreal_ob) or (k = complex_ob) then begin
    pas_$new(l, 16);
    if k = real_ob then
      lk := 12
    else if k = dpreal_ob then
      lk := 13
    else
      lk := 14;
    l^.value := node^.xl[3];
    l^.l12 := node^.xl[4];
  end
  else if k = dpcomplex_ob then begin
    pas_$new(l, 24);
    lk := 15;
    l^.value := node^.xl[3];
    l^.l12 := node^.xl[4];
    l^.l16 := node^.xl[5];
    l^.l20 := node^.xl[6];
  end
  else if k = char_string_ob then begin
    l := make_properly_sized_copy(node);
    lk := 19;
  end
  else if k = set_con_ob then begin
    l := make_properly_sized_copy(node);
    lk := 20;
  end
  else if k = namelist_constant_ob then begin
    pas_$new(l, 6);
    lk := 16;
  end
  else begin
    sym_$reformat_literal := nil;
    return;
  end;
  l^.kind := lk;
  l^.p0 := node;
  sym_$reformat_literal := l;
end;

{ sym_$reformat_literal_operand - op made a literal pool displacement of
  node's literal (sym_$reformat_literal): its .bytes (+3 bits 7..5)
  bytes, its link the literal, its value value; whether node is a
  literal.  0x27B66C, 0x54 bytes: node (8), bytes (12) in D4, value
  (16) in D3, op (20) in A2. }

function sym_$reformat_literal_operand(
    node: univ_ptr;
    bytes: integer32;
    value: integer32;
    op: opnd_ptr_t): boolean;
var
  ok: boolean;
  l: univ_ptr;
begin
  ok := false;
  l := sym_$reformat_literal(node);
  if l <> nil then begin
    op^.h.bytes := bytes & 7;
    op^.link := l;
    op^.value := value;
    ok := true;
  end;
  sym_$reformat_literal_operand := ok;
end;
