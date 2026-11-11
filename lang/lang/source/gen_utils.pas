{ gen_utils - GEN_UTILS, code generation helpers: the libraries the
  program is bound with (-inlib, through OBJUTIL_), address constants
  (kind 163 nodes in a section's chain, absolute ones of kind 195 in
  il_130's), a routine's dynamic-area pointers, sections (182 code in
  il_10c's chain, 183 data in il_110's), transfer vectors (192, il_128)
  and external references (194, il_12c).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07C3C4  0x07DDA4  inlib_error
    0x07C552  0x07DF32  inlib_init
    0x07C582  0x07DF62  inlib_term
    0x07C59C  0x07DF7C  inlib_add
    0x07C5C6  0x07DFA6  make_abs_addr_con
    0x07C63E  0x07E01E  check_for_addr_con
    0x07C8EC  0x07E2CC  get_addr_con
    0x07C966  0x07E346  change_name_lower_case
    0x07C9F8  0x07E3D8  make_new_addr_con
    0x07CD52  0x07E732  get_proc_addr_con
    0x07CE7A  0x07E85A  find_ac_dsect
    0x07CECE  0x07E8AE  get_xdynm_ptr
    0x07CF2E  0x07E90E  make_xdynm_ptr
    0x07D022  0x07EA02  name_match (in check_section_name)
    0x07D0C4  0x07EAA4  check_section_name
    0x07D15C  0x07EB3C  add_psect
    0x07D1D4  0x07EBB4  add_dsect
    0x07D24E  0x07EC2E  get_id_name (in get_transfer_vector)
    0x07D2EE  0x07ECCE  get_transfer_vector
    0x07D3B6  0x07ED96  get_external_ref
    0x07D414  0x07EDF4  gen_utils_$alloc_new_addr_con
    A5 0x169C64 (cc.m68k): the module's data, 0xC bytes no routine uses
    (every cell the unit reads is another unit's, absolutely).

  Every module-level routine is global and loads A5.  The nodes' fields
  are read through il.ins.pas's views by offset.
}
module gen_utils;

%include 'lang/lang/source/globals.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/loader.ins.pas';
%include '/sys/ins/loader.ins.pas';
%include 'us/us/ins/fault.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include 'us/us/ins/unix_sig.ins.pas';
%include 'us/us/ins/pgm.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include 'us/us/ins/error.ins.pas';
%include '/sys/ins/error.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'us/us/ins/objutil.ins.pas';
%include 'us/us/ins/uid_list.ins.pas';
%include '/sys/ins/type_uids.ins.pas';
%include 'lang/lang/source/unix_objmod.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';

{ inlib_error - report an error of OBJUTIL_.

  0x07C3C4, 0x17A bytes.  The lengths of name and msg (to their NUL,
  loops counting from 1).  A line (-264) gets msg; when name has
  characters, ` (file ', name, and when line is not 0 `, line ' and
  line in 5 digits (prtint, the width and zero_fill pushed as one
  longword 16#50000), then `)'.  A blank follows when the current
  routine (il_184) has +377 bits 6..4 = 3.  Then cgerr_no_source(30 for
  severity 0, 31 for 1, else 32, strtk(the line)).

  Not known from the original:
  - the locals' names. }

procedure inlib_error(
    in severity: integer;
    in line: integer;
    in name: univ gen_utils_$cstring_t;
    in msg: univ gen_utils_$cstring_t);
var
  nlen, mlen: integer;
  s: prtsub_$line_t;
  rb: il_$node_ptr_t;
  code: integer;
  t: il_$node_ptr_t;
begin
  nlen := 1;
  while name[nlen] <> chr(0) do
    nlen := nlen + 1;
  nlen := nlen - 1;
  mlen := 1;
  while msg[mlen] <> chr(0) do
    mlen := mlen + 1;
  mlen := mlen - 1;
  s.length := 0;
  prtcats(s, msg, mlen);
  if nlen > 0 then begin
    prtcats(s, ' (file ', 7);
    prtcats(s, name, nlen);
    if line <> 0 then begin
      prtcats(s, ', line ', 7);
      prtint(s, line, 5, false);
    end;
    prtcats(s, ')', 1);
  end;
  rb := il_184;
  if rb <> nil then
    if rshft(ord(rb^.xc[377]) & 16#70, 4) = 3 then
      prtcats(s, ' ', 1);
  if severity = 0 then
    code := 30
  else if severity = 1 then
    code := 31
  else
    code := 32;
  t := strtk(s.body, s.length);
  cgerr_no_source(code, integer32(t));
end;

{ inlib_init - start reading the -inlib libraries.

  0x07C552, 0x2C bytes: objutil_$inlib_init(inlib_error's address (a
  constant after the routine, 0x07C57E), target_magic's result (a local,
  -4)). }

procedure inlib_init;
var
  magic: integer32;
begin
  magic := target_magic;
  objutil_$inlib_init(addr(inlib_error), magic);
end;

{ inlib_term - 0x07C582, 0x1A bytes: objutil_$inlib_terminate. }

procedure inlib_term;
begin
  objutil_$inlib_terminate;
end;

{ inlib_add - 0x07C59C, 0x2A bytes: objutil_$inlib_libname(name, len). }

procedure inlib_add(
    in name: univ cargs_$chars_t;
    len: integer);
begin
  objutil_$inlib_libname(name, len);
end;

{ make_abs_addr_con - the kind 195 node of (kind, sym, value).

  0x07C5C6, 0x78 bytes: il_130's chain (+4) is searched for +12 = sym,
  +16 = value, +20 = kind; else a new node (22 bytes) is put at its
  head with +8 nil and the three.

  Not known from the original:
  - the local's name. }

function make_abs_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32): il_$node_ptr_t;
var
  p: il_$node_ptr_t;
begin
  p := il_130;
  while p <> nil do begin
    if (sym = p^.xp[3]) and (value = p^.xl[4]) and (kind = p^.xw[10]) then
    begin
      make_abs_addr_con := p;
      return;
    end;
    p := p^.xp[1];
  end;
  p := gspace(22);
  p^.kind := 195;
  p^.xp[1] := il_130;
  il_130 := p;
  p^.xp[2] := nil;
  p^.xp[3] := sym;
  p^.xl[4] := value;
  p^.xw[10] := kind;
  make_abs_addr_con := p;
end;

{ check_for_addr_con - the address constant of sym, or of a symbol of
  the same name, with value in sect's chain.

  0x07C63E, 0x2AE bytes.  The chain from sect's +12 (an entry not of
  kind 163 goes on at +116, one of 163 at +4).  An entry with value
  (+12), sym (+8) and kind (+20, a byte; kind 8 matches any) is the
  result.  Else when one of the two symbols is a kind 159 and the other
  of kind 109, 110 or 159 (`seq' or'd and and'd), with value and kind
  matching, both names are copied to locals (4096 bytes each, -8192 and
  -4096; kind 109: its identifier's, +4; 110: +70 characters from +72;
  159: +8 characters from +12 + 2 * +10), made lower case and compared
  (compare_bytes): equal names give the entry.  Else nil.

  Not known from the original:
  - the locals' names; whether the name copies were written as a nested
    routine (the image repeats them). }

function check_for_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32;
    sect: il_$node_ptr_t): il_$node_ptr_t;
var
  p, q: il_$node_ptr_t;
  k, sk: integer;
  related: boolean;
  len1, len2: integer32;
  buf1, buf2: array [1..4096] of char;
  i: integer;
begin
  p := sect^.xp[3];
  while p <> nil do begin
    if p^.kind <> 163 then
      p := p^.xp[29]
    else begin
      if (p^.xl[3] = value) and (sym = p^.xp[2]) and
         ((kind = 8) or (ord(p^.xc[20]) = kind)) then begin
        check_for_addr_con := p;
        return;
      end;
      q := p^.xp[2];
      k := q^.kind;
      sk := sym^.kind;
      related := ((k = 159) or (k = 110) or (k = 109)) and (sk = 159);
      if not related then
        related := (k = 159) and ((sk = 109) or (sk = 159) or (sk = 110));
      if related and (p^.xl[3] = value) and
         ((kind = 8) or (ord(p^.xc[20]) = kind)) then begin
        if sk = 109 then begin
          len1 := sym^.xp[1]^.idnt_len;
          for i := 1 to len1 do
            buf1[i] := sym^.xp[1]^.idnt_name[i];
        end
        else if sk = 110 then begin
          len1 := sym^.xw[35];
          for i := 1 to len1 do
            buf1[i] := sym^.xc[71 + i];
        end
        else if sk = 159 then begin
          len1 := sym^.xw[4];
          for i := 0 to len1 - 1 do
            buf1[i + 1] := sym^.xc[12 + 2 * sym^.xw[5] + i];
        end;
        q := p^.xp[2];
        if q^.kind = 109 then begin
          len2 := q^.xp[1]^.idnt_len;
          for i := 1 to len2 do
            buf2[i] := q^.xp[1]^.idnt_name[i];
        end
        else if q^.kind = 110 then begin
          len2 := q^.xw[35];
          for i := 1 to len2 do
            buf2[i] := q^.xc[71 + i];
        end
        else if q^.kind = 159 then begin
          len2 := q^.xw[4];
          for i := 0 to len2 - 1 do
            buf2[i + 1] := q^.xc[12 + 2 * q^.xw[5] + i];
        end;
        for i := 1 to len1 do
          if buf1[i] in ['A'..'Z'] then
            buf1[i] := chr(ord(buf1[i]) + 32);
        for i := 1 to len2 do
          if buf2[i] in ['A'..'Z'] then
            buf2[i] := chr(ord(buf2[i]) + 32);
        if compare_bytes(buf1, len1, buf2, len2) = 0 then begin
          check_for_addr_con := p;
          return;
        end;
      end;
      p := p^.xp[1];
    end;
  end;
  check_for_addr_con := nil;
end;

{ get_addr_con - make_new_addr_con at offset rounded.

  0x07C8EC, 0x7A bytes.  r := 0 when offset is 0, else (offset + al div
  2) div al * al, al := target_properties.p_88 (`lsr.l #1', M$DIS,
  M$MIS); offset loses r.  sym is passed as nil for kind 8.

  Not known from the original:
  - the locals' names. }

function get_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    var offset: integer32;
    sect: il_$node_ptr_t;
    no_inlib: boolean): il_$node_ptr_t;
var
  r: integer32;
  s: il_$node_ptr_t;
begin
  if offset = 0 then
    r := 0
  else begin
    r := (rshft(target_properties.p_88, 1) + offset) div target_properties.p_88
         * target_properties.p_88;
    offset := offset - r;
  end;
  if kind = 8 then
    s := nil
  else
    s := sym;
  get_addr_con := make_new_addr_con(kind, s, r, sect, no_inlib);
end;

{ change_name_lower_case - id's characters to buf.

  0x07C966, 0x92 bytes: with cargs_$options.b28a_6 (`btst #6,0x2C3676')
  copied as they are, else A..Z made lower case (32-bit `dbf' loops). }

procedure change_name_lower_case(
    in id: il_$node_ptr_t;
    out buf: univ cargs_$chars_t);
var
  i: integer32;
  c: char;
begin
  if not cargs_$options.b28a_6 then begin
    for i := 1 to id^.idnt_len do begin
      c := id^.idnt_name[i];
      if c in ['A'..'Z'] then
        buf[i] := chr(ord(c) + 32)
      else
        buf[i] := c;
    end;
  end
  else
    for i := 1 to id^.idnt_len do
      buf[i] := id^.idnt_name[i];
end;

{ make_new_addr_con - the address constant of sym and value in sect.

  0x07C9F8, 0x344 bytes.  debug_sym_dmp_1090 := false.  Unless no_inlib,
  with element 7 of cargs_$options.flags_286 (-AC, `btst #2,0x2C3673'):
  sym's name is taken (a `case' on kinds 107..111: 109, 111 their
  identifier, +4; 107, 108 +296's; 110 idntk(76, +72, +70)) lower case
  (change_name_lower_case) into a local (-12296); the lookups' flags
  word gets 1 with element 8 (`btst #3').  A kind 109 named stext, end,
  etext or edata, or a kind 110 named etext or stext, is not looked up.
  Kind 111: a section found (objutil_$inlib_lookup_section, flags 2)
  sets debug_sym_dmp_1090 and +54.  Kind 4 of a 107 or 108 with +376
  bits 8..7 = 2 (flags 4), kind 4 of a 110 (flags 4, then 2), and a 109
  with +72 = 3 (flags 2): a symbol found (objutil_$inlib_lookup_symbol)
  sets debug_sym_dmp_1090.  Else kind 11 clears debug_sym_dmp_1090,
  and other kinds are absolute: make_abs_addr_con.  The found and
  passed-over cases: check_for_addr_con, else
  gen_utils_$alloc_new_addr_con.

  Not known from the original:
  - the locals' names; whether the passed-over cases were written with
    goto (the image branches to the common tail). }

function make_new_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32;
    sect: il_$node_ptr_t;
    no_inlib: boolean): il_$node_ptr_t;
label
  in_section;
var
  name: cargs_$chars_t;
  info: array [1..280] of char;
  flags: integer;
  opt: integer;
  t, p: il_$node_ptr_t;
begin
  debug_sym_dmp_1090 := false;
  if not no_inlib and (7 in cargs_$options.flags_286) then begin
    case sym^.kind of
      109, 111:
        change_name_lower_case(sym^.xp[1], name);
      107, 108:
        change_name_lower_case(sym^.xp[74], name);
      110: begin
        t := idntk(76, sym^.xc[72], sym^.xw[35]);
        change_name_lower_case(t, name);
      end;
      otherwise
    end;
    if 8 in cargs_$options.flags_286 then
      opt := 1
    else
      opt := 0;
    if sym^.kind = 109 then begin
      if compare_bytes(name, sym^.xp[1]^.idnt_len, 'stext', 5) = 0 then
        goto in_section;
      if compare_bytes(name, sym^.xp[1]^.idnt_len, 'end', 3) = 0 then
        goto in_section;
      if compare_bytes(name, sym^.xp[1]^.idnt_len, 'etext', 5) = 0 then
        goto in_section;
      if compare_bytes(name, sym^.xp[1]^.idnt_len, 'edata', 5) = 0 then
        goto in_section;
    end;
    if sym^.kind = 110 then begin
      if compare_bytes(name, sym^.xw[35], 'etext', 5) = 0 then
        goto in_section;
      if compare_bytes(name, sym^.xw[35], 'stext', 5) = 0 then
        goto in_section;
    end;
    if sym^.kind = 111 then begin
      flags := 2 ! opt;
      if objutil_$inlib_lookup_section(name, sym^.xp[1]^.idnt_len,
                                       sym^.xl[5], flags) then begin
        debug_sym_dmp_1090 := true;
        sym^.xc[54] := chr(16#FF);
        goto in_section;
      end;
    end;
    if (kind = 4) and ((sym^.kind = 108) or (sym^.kind = 107)) and
       (rshft(sym^.xw[188] & 384, 7) = 2) then begin
      flags := 4 ! opt;
      if objutil_$inlib_lookup_symbol(name, sym^.xp[74]^.idnt_len, flags,
                                      info) then begin
        debug_sym_dmp_1090 := true;
        goto in_section;
      end;
    end;
    if (kind = 4) and (sym^.kind = 110) then begin
      flags := 4 ! opt;
      if objutil_$inlib_lookup_symbol(name, sym^.xw[35], flags, info) then
      begin
        debug_sym_dmp_1090 := true;
        goto in_section;
      end;
    end;
    if (kind = 4) and (sym^.kind = 110) then begin
      flags := 2 ! opt;
      if objutil_$inlib_lookup_symbol(name, sym^.xw[35], flags, info) then
      begin
        debug_sym_dmp_1090 := true;
        goto in_section;
      end;
    end;
    if (sym^.kind = 109) and (sym^.xw[36] = 3) then begin
      flags := 2 ! opt;
      if objutil_$inlib_lookup_symbol(name, sym^.xp[1]^.idnt_len, flags,
                                      info) then begin
        debug_sym_dmp_1090 := true;
        goto in_section;
      end;
    end;
    if kind = 11 then begin
      debug_sym_dmp_1090 := false;
      goto in_section;
    end;
    make_new_addr_con := make_abs_addr_con(kind, sym, value);
    return;
  end;
in_section:
  p := check_for_addr_con(kind, sym, value, sect);
  if p = nil then
    p := gen_utils_$alloc_new_addr_con(kind, sym, value, sect);
  make_new_addr_con := p;
end;

{ get_proc_addr_con - the procedure address constant of sym and value.

  0x07CD52, 0x10E bytes.  sect's chain (from +12; not kind 163 goes on
  at +116) is searched for sym (+8), kind (+20) and value (+24).  Else a
  new node (28 bytes, kind 163) gets kind, the chain as its next, sym,
  +12 0 and value; sect's offset (+16) drops 4 for kinds 6 and 12
  (`move.w #0x1040; btst'), 8 for 7, else cgerr_no_source(26, sym); the
  node gets the offset, below target_properties.p_60 reported (code
  11); kind 12 of a constant kind (77..87, 101, 200: the set at
  0x07CE60) is reported (26); the node becomes the chain's head.

  Not known from the original:
  - the locals' names. }

function get_proc_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32;
    sect: il_$node_ptr_t): il_$node_ptr_t;
var
  p, t: il_$node_ptr_t;
begin
  p := sect^.xp[3];
  while p <> nil do begin
    if p^.kind <> 163 then
      p := p^.xp[29]
    else begin
      if (sym = p^.xp[2]) and (ord(p^.xc[20]) = kind) and
         (value = p^.xl[6]) then begin
        get_proc_addr_con := p;
        return;
      end;
      p := p^.xp[1];
    end;
  end;
  t := gspace(28);
  t^.kind := 163;
  t^.xc[20] := chr(kind);
  t^.xp[1] := sect^.xp[3];
  t^.xp[2] := sym;
  t^.xl[3] := 0;
  t^.xl[6] := value;
  if (kind = 6) or (kind = 12) then
    sect^.xl[4] := sect^.xl[4] - 4
  else if kind = 7 then
    sect^.xl[4] := sect^.xl[4] - 8
  else
    cgerr_no_source(26, integer32(sym));
  t^.xl[4] := sect^.xl[4];
  if sect^.xl[4] < target_properties.p_60 then
    cgerr_no_source(11, integer32(sym));
  if kind = 12 then
    if sym^.kind in [77..87, 101, 200] then
      cgerr_no_source(26, integer32(sym));
  sect^.xp[3] := t;
  get_proc_addr_con := t;
end;

{ find_ac_dsect - the data section whose chain holds ac.

  0x07CE7A, 0x54 bytes: each section of il_110's chain (+4), each entry
  of its chain (+12; kind 163 goes on at +4, others at +116). }

function find_ac_dsect(
    ac: il_$node_ptr_t): il_$node_ptr_t;
var
  s, p: il_$node_ptr_t;
begin
  s := il_110;
  while s <> nil do begin
    p := s^.xp[3];
    while p <> nil do
      if p^.kind = 163 then begin
        if p = ac then begin
          find_ac_dsect := s;
          return;
        end;
        p := p^.xp[1];
      end
      else
        p := p^.xp[29];
    s := s^.xp[1];
  end;
  find_ac_dsect := nil;
end;

{ get_xdynm_ptr - make_xdynm_ptr at offset rounded.

  0x07CECE, 0x60 bytes: the rounding of get_addr_con. }

function get_xdynm_ptr(
    blk: il_$node_ptr_t;
    var offset: integer32): il_$node_ptr_t;
var
  r: integer32;
begin
  if offset = 0 then
    r := 0
  else begin
    r := (rshft(target_properties.p_88, 1) + offset) div target_properties.p_88
         * target_properties.p_88;
    offset := offset - r;
  end;
  get_xdynm_ptr := make_xdynm_ptr(blk, r);
end;

{ make_xdynm_ptr - the dynamic-area address constant of blk at value.

  0x07CF2E, 0xF4 bytes.  blk's chain (+180) is sorted by value (+12):
  an equal entry is the result, a greater one stops the search.  A new
  node (28 bytes when target_properties.p_7f, else 24; kind 163) gets
  +20 0, blk, value, and blk's offset (+80) less 4; with p_7f a kind 109
  variable node (84 bytes) at +24 gets the constant (+4), blk (+20),
  runbackend_0c (+28), +72 2, +32 16#44000, +36 32 and +44 2.  It is
  linked in before the greater entry.

  Not known from the original:
  - the locals' names; the variable's fields' meaning. }

function make_xdynm_ptr(
    blk: il_$node_ptr_t;
    value: integer32): il_$node_ptr_t;
var
  p, prev, t, v: il_$node_ptr_t;
begin
  prev := nil;
  p := blk^.xp[45];
  while p <> nil do begin
    if p^.xl[3] > value then
      exit;
    if p^.xl[3] = value then begin
      make_xdynm_ptr := p;
      return;
    end;
    prev := p;
    p := p^.xp[1];
  end;
  if target_properties.p_7f then
    t := gspace(28)
  else
    t := gspace(24);
  t^.kind := 163;
  t^.xc[20] := chr(0);
  t^.xp[2] := blk;
  t^.xl[3] := value;
  blk^.xl[20] := blk^.xl[20] - 4;
  t^.xl[4] := blk^.xl[20];
  if target_properties.p_7f then begin
    v := gspace(84);
    t^.xp[6] := v;
    v^.kind := 109;
    v^.xp[1] := t;
    v^.xp[5] := blk;
    v^.xp[7] := runbackend_0c;
    v^.xw[36] := 2;
    v^.xl[8] := 16#44000;
    v^.xl[9] := 32;
    v^.xw[22] := 2;
  end;
  if prev = nil then begin
    t^.xp[1] := blk^.xp[45];
    blk^.xp[45] := t;
  end
  else begin
    t^.xp[1] := prev^.xp[1];
    prev^.xp[1] := t;
  end;
  make_xdynm_ptr := t;
end;

{ check_section_name - the section named as name, else name.

  0x07D0C4, 0x98 bytes: il_10c's chain (+4; name +8), then il_110's,
  then il_118's (next +8, name +4), each by name_match (0x07D0E6). }

function check_section_name(
    name: il_$node_ptr_t): il_$node_ptr_t;
var
  s: il_$node_ptr_t;

  { name_match - whether identifiers a and b are the same name.

    0x07D022, 0xA2 bytes (no A5).  The lengths (+16) equal and each
    character: with element 0 of cargs_$options.flags_286 (`btst
    #3,0x2C3674') compared as it is; else a letter of a's opposite in
    case to b's is changed to b's case first. }

  function name_match(
      a: il_$node_ptr_t;
      b: il_$node_ptr_t): boolean;
  var
    i: integer;
    c, d: char;
  begin
    name_match := false;
    if a^.idnt_len = b^.idnt_len then begin
      for i := 1 to a^.idnt_len do begin
        c := a^.idnt_name[i];
        if not (0 in cargs_$options.flags_286) then begin
          d := b^.idnt_name[i];
          if (c in ['A'..'Z']) and (d in ['a'..'z']) then
            c := chr(ord(c) + 32)
          else if (c in ['a'..'z']) and (d in ['A'..'Z']) then
            c := chr(ord(c) - 32);
        end;
        if c <> b^.idnt_name[i] then
          return;
      end;
      name_match := true;
    end;
  end;

begin
  s := il_10c;
  while s <> nil do begin
    if name_match(s^.xp[2], name) then begin
      check_section_name := s;
      return;
    end;
    s := s^.xp[1];
  end;
  s := il_110;
  while s <> nil do begin
    if name_match(s^.xp[2], name) then begin
      check_section_name := s;
      return;
    end;
    s := s^.xp[1];
  end;
  s := il_118;
  while s <> nil do begin
    if name_match(s^.xp[1], name) then begin
      check_section_name := s;
      return;
    end;
    s := s^.xp[2];
  end;
  s := name;
  check_section_name := s;
end;

{ add_psect - enter a code section named name.

  0x07D15C, 0x78 bytes: check_section_name: nil gives nil, a kind 182
  section itself; the name (kind 76) a new section (92 bytes, kind 182)
  with the name (+8), il_10c's chain as next, +12, +20, +52 cleared,
  made the chain's head; anything else nil.

  Not known from the original:
  - the locals' names. }

function add_psect(
    name: il_$node_ptr_t): il_$node_ptr_t;
var
  s, t: il_$node_ptr_t;
begin
  s := check_section_name(name);
  if s = nil then
    t := nil
  else if s^.kind = 182 then
    t := s
  else if s^.kind = 76 then begin
    t := gspace(92);
    t^.kind := 182;
    t^.xp[2] := s;
    t^.xp[1] := il_10c;
    t^.xl[3] := 0;
    t^.xl[5] := 0;
    t^.xl[13] := 0;
    il_10c := t;
  end
  else
    t := nil;
  add_psect := t;
end;

{ add_dsect - enter a data section named name.

  0x07D1D4, 0x7A bytes: as add_psect with kind 183, 52 bytes, il_110's
  chain and +12..+28 cleared (five `clr.l'). }

function add_dsect(
    name: il_$node_ptr_t): il_$node_ptr_t;
var
  s, t: il_$node_ptr_t;
begin
  s := check_section_name(name);
  if s = nil then
    t := nil
  else if s^.kind = 183 then
    t := s
  else if s^.kind = 76 then begin
    t := gspace(52);
    t^.kind := 183;
    t^.xp[2] := s;
    t^.xp[1] := il_110;
    t^.xl[3] := 0;
    t^.xl[4] := 0;
    t^.xl[5] := 0;
    t^.xl[6] := 0;
    t^.xl[7] := 0;
    il_110 := t;
  end
  else
    t := nil;
  add_dsect := t;
end;

{ get_transfer_vector - the transfer vector entry of sym.

  0x07D2EE, 0xC8 bytes.  il_128's chain (+4, symbol +8): sym's entry is
  the result; one of the same name (get_id_name of both, compared as
  identifier nodes): a kind 159 entry with sym of kind 108 or 107 takes
  sym and is the result; otherwise it is the result unless the current
  routine's (il_184) +377 bits 6..4 are 6 and sym is not of kind 159.
  Else a new entry (20 bytes, kind 192) with sym and +12, +16 cleared
  becomes the chain's head.

  Not known from the original:
  - the locals' names. }

function get_transfer_vector(
    sym: il_$node_ptr_t): il_$node_ptr_t;
var
  p, n, m: il_$node_ptr_t;
  rb: il_$node_ptr_t;

  { get_id_name - the identifier of a symbol node.

    0x07D24E, 0x7E bytes (no A5): 108, 107 +296; 159 idntk(76, the +8
    characters from +12 + 2 * +10); 110 idntk(76, +70 characters from
    +72); else cgerr_no_source(28, strtk('Unknown transfer vector
    reference', 33)) and il_178. }

  function get_id_name(
      t: il_$node_ptr_t): il_$node_ptr_t;
  var
    s: il_$node_ptr_t;
  begin
    case t^.kind of
      108, 107:
        get_id_name := t^.xp[74];
      159:
        get_id_name := idntk(76, t^.xc[12 + 2 * t^.xw[5]], t^.xw[4]);
      110:
        get_id_name := idntk(76, t^.xc[72], t^.xw[35]);
      otherwise begin
        s := strtk('Unknown transfer vector reference', 33);
        cgerr_no_source(28, integer32(s));
        get_id_name := il_178;
      end;
    end;
  end;

begin
  p := il_128;
  while p <> nil do begin
    if sym = p^.xp[2] then begin
      get_transfer_vector := p;
      return;
    end;
    n := get_id_name(p^.xp[2]);
    m := get_id_name(sym);
    if m = n then begin
      if (p^.xp[2]^.kind = 159) and ((sym^.kind = 108) or (sym^.kind = 107))
      then begin
        p^.xp[2] := sym;
        get_transfer_vector := p;
        return;
      end;
      rb := il_184;
      if (rshft(ord(rb^.xc[377]) & 16#70, 4) <> 6) or (sym^.kind = 159) then
      begin
        get_transfer_vector := p;
        return;
      end;
    end;
    p := p^.xp[1];
  end;
  p := gspace(20);
  p^.kind := 192;
  p^.xp[1] := il_128;
  p^.xp[2] := sym;
  p^.xl[3] := 0;
  p^.xl[4] := 0;
  il_128 := p;
  get_transfer_vector := p;
end;

{ get_external_ref - enter sym as an external reference.

  0x07D3B6, 0x5E bytes: il_12c's chain (+4, symbol +8); when sym is not
  there a new entry (14 bytes, kind 194) with sym and +12 (a word)
  cleared becomes the head. }

procedure get_external_ref(
    sym: il_$node_ptr_t);
var
  p: il_$node_ptr_t;
begin
  p := il_12c;
  while p <> nil do begin
    if sym = p^.xp[2] then
      return;
    p := p^.xp[1];
  end;
  p := gspace(14);
  p^.kind := 194;
  p^.xp[1] := il_12c;
  p^.xp[2] := sym;
  p^.xw[6] := 0;
  il_12c := p;
end;

{ gen_utils_$alloc_new_addr_con - a new address constant.

  0x07D414, 0xB2 bytes.  A kind not in [1..6, 8..11] (`move.w #0xF7E;
  btst') is reported (cgerr_no_source(26, sym)).  The node (24 bytes,
  kind 163) gets kind (+20), sect's chain as next (it becomes the head),
  sym, value; sect's offset (+16) drops by a kind 11 string constant's
  length rounded up to 4, else by 4; the node gets the offset, below
  target_properties.p_60 reported (code 11). }

function gen_utils_$alloc_new_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32;
    sect: il_$node_ptr_t): il_$node_ptr_t;
var
  t: il_$node_ptr_t;
begin
  if not (kind in [1..6, 8..11]) then
    cgerr_no_source(26, integer32(sym));
  t := gspace(24);
  t^.kind := 163;
  t^.xc[20] := chr(kind);
  t^.xp[1] := sect^.xp[3];
  sect^.xp[3] := t;
  t^.xp[2] := sym;
  t^.xl[3] := value;
  if (kind = 11) and (sym^.kind = 92) then
    sect^.xl[4] := sect^.xl[4] - ((sym^.str_len + 3) & 16#FFFFFFFC)
  else
    sect^.xl[4] := sect^.xl[4] - 4;
  t^.xl[4] := sect^.xl[4];
  if sect^.xl[4] < target_properties.p_60 then
    cgerr_no_source(11, integer32(sym));
  gen_utils_$alloc_new_addr_con := t;
end;
