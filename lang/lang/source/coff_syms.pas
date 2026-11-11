{ coff_syms - COFF_SYMS, the object module's symbol table: the symbols
  numbered (number_coff_syms: the routines, two each and two more for an
  entry's second name, the sections, the externals in the order they are
  first met) and written (coff_sym_dmp: .file, the routines with their
  function auxiliaries, the sections with theirs, the globals and
  externals), the externals kept in a list of 100-entry blocks so that
  each name gets one symbol.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0A65F0  0x0A7FD0  find_extern (internal)
    0x0A676E  0x0A814E  flush_externs (internal)
    0x0A67B4  0x0A8194  count_global_sym (in number_coff_syms)
    0x0A6A48  0x0A8428  count_tvs (in number_coff_syms)
    0x0A6AC2  0x0A84A2  number_coff_syms
    0x0A6F52  0x0A8932  get_coff_type (in coff_sym_dmp)
    0x0A6FB6  0x0A8996  get_lnno_ptr (in coff_sym_dmp)
    0x0A7036  0x0A8A16  get_section_no (in coff_sym_dmp)
    0x0A708E  0x0A8A6E  get_section_hdr (in coff_sym_dmp)
    0x0A70BA  0x0A8A9A  map_name (in coff_sym_dmp)
    0x0A70F8  0x0A8AD8  put_name (in coff_sym_dmp)
    0x0A7154  0x0A8B34  put_sect_sym (in coff_sym_dmp)
    0x0A721C  0x0A8BFC  put_global_sym (in coff_sym_dmp)
    0x0A79D2  0x0A93B2  put_tvs (in coff_sym_dmp)
    0x0A7A5A  0x0A943A  put_func_def (in coff_sym_dmp)
    0x0A7CA4  0x0A9684  coff_sym_dmp
    A5 0x2C20BC (cc.m68k), 0x44212C (cc.a88k): the module's data, 16
    bytes: +0 the first external's number, +4 the first section's,
    +8 the externals' blocks, +12 the next symbol number (a word).

  number_coff_syms and coff_sym_dmp are global (their headings in
  unix_objmod.ins.pas); find_extern and flush_externs do not load A5
  (internal).  The routines nested in coff_sym_dmp reach its symbol
  being written (size -24, offset -20, mapping -16), its loop index
  (-28) and its '_' flag (-32): put_sect_sym and put_func_def through
  their dynamic link, the others in A1.  unix_objmod's cells are read
  absolutely (unix_objmod.ins.pas).  The nodes' fields are read through
  il.ins.pas's views by offset.

  Not known from the original:
  - the names of the module's variables, the locals and the parameters;
    the symbol records' type names. }
module coff_syms;

%include 'lang/lang/source/globals.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'lang/lang/source/unix_objmod.ins.pas';
%include 'us/us/ins/strl.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';

type
  { A block of the externals' list (806 bytes from PAS_$NEW). }
  coff_syms_$extern_ptr_t = ^coff_syms_$extern_t;
  coff_syms_$extern_t = record
    count: integer;                     { +0 }
    e: array [1..100] of record         { +2 }
      node: il_$node_ptr_t;
      symndx: integer32;
    end;
    next: coff_syms_$extern_ptr_t;      { +802 }
  end;

  { A COFF symbol (18 bytes) and its auxiliary entries. }
  coff_syms_$syment_ptr_t = ^coff_syms_$syment_t;
  coff_syms_$syment_t = record
    case integer of
      1: (n_name: unix_objmod_$name_t;  { +0 }
          n_value: integer32;           { +8 }
          n_scnum: integer;             { +12 }
          n_type: integer;              { +14 }
          n_sclass: char;               { +16 }
          n_numaux: char);              { +17 }
      { A section's auxiliary entry. }
      2: (x_scnlen: integer32;          { +0 }
          x_nreloc: integer;            { +4 }
          x_nlinno: integer);           { +6 }
      { A function's. }
      3: (x_tagndx: integer32;          { +0 }
          x_fsize: integer32;           { +4 }
          x_lnnoptr: integer32;         { +8 }
          x_endndx: integer32);         { +12 }
      { The .file name (14 characters, or in the string table). }
      4: (x_fname: array [1..14] of char);
  end;

  coff_syms_$words_ptr_t = ^array [1..16384] of integer;

  unix_objmod_$linenos_ptr_t = ^array [0..65535] of unix_objmod_$lineno_t;

  { The externals of a code section (its +52 list): 8-byte entries,
    the node second. }
  coff_syms_$refs_ptr_t = ^coff_syms_$refs_t;
  coff_syms_$refs_t = record
    unused_0: integer32;                { +0 }
    next: coff_syms_$refs_ptr_t;        { +4 }
    unused_8: integer;                  { +8 }
    count: integer;                     { +10 }
    e: array [1..1000] of record        { +12 }
      unused: integer32;
      node: il_$node_ptr_t;
    end;
  end;

  { type_exp's result (c_objtype.ins.pas's type_exp_t, which this unit
    does not open): the size at +20. }
  coff_syms_$type_exp_t = record
    unused: array [0..4] of integer32;  { +0 }
    size: integer32;                    { +20 }
    unused_24: array [0..1] of integer32;
  end;

var
  first_extern: integer32;              { +0 }
  first_section: integer32;             { +4 }
  externs: coff_syms_$extern_ptr_t;     { +8 }
  next_sym: integer;                    { +12 }

{ find_extern - the symbol of external p (by identity, or for a kind 110
  by name, case ignored), entered when new; with want_index false the
  result is 0 for a known one and -1 for a new one.

  0x0A65F0, 0x17E bytes (no A5: internal).  want_index a byte, p a
  pointer, by value.  The blocks from +8 (+802 next): a match returns
  its +6 (or 0).  A new one goes into the first block (a new block of
  806 bytes from PAS_$NEW, nil reported, put at the head when none or
  the first is full at 100), its number the next symbol (+12, then
  incremented) when wanted.

  Not known from the original:
  - the names. }

function find_extern(
    want_index: boolean;
    p: il_$node_ptr_t): integer32; options(val_param); internal;
var
  b: coff_syms_$extern_ptr_t;
  i: integer32;
  q: il_$node_ptr_t;
  match: boolean;
begin
  if externs <> nil then begin
    b := externs;
    while b <> nil do begin
      for i := 1 to b^.count do begin
        q := b^.e[i].node;
        match := q = p;
        if not match then
          if q^.kind = 110 then
            match := strings_$compare_bytes_nocase(q^.xc[72], q^.xw[35],
                                                   p^.xc[72], p^.xw[35]) = 0;
        if match then begin
          if want_index then
            find_extern := b^.e[i].symndx
          else
            find_extern := 0;
          return;
        end;
      end;
      b := b^.next;
    end;
  end;
  if externs = nil then begin
    pas_$new(externs, 806);
    if externs = nil then
      cgerr_no_source(9, 0);
    externs^.next := nil;
    externs^.count := 1;
    externs^.e[1].node := p;
    if want_index then begin
      externs^.e[1].symndx := next_sym;
      find_extern := next_sym;
      next_sym := next_sym + 1;
    end
    else
      find_extern := -1;
  end
  else if externs^.count = 100 then begin
    pas_$new(b, 806);
    if b = nil then
      cgerr_no_source(9, 0);
    b^.next := nil;
    b^.count := 1;
    b^.e[1].node := p;
    if want_index then begin
      b^.e[1].symndx := next_sym;
      find_extern := next_sym;
      next_sym := next_sym + 1;
    end
    else
      find_extern := -1;
    b^.next := externs;
    externs := b;
  end
  else begin
    externs^.count := externs^.count + 1;
    externs^.e[externs^.count].node := p;
    if want_index then begin
      externs^.e[externs^.count].symndx := next_sym;
      find_extern := next_sym;
      next_sym := next_sym + 1;
    end
    else
      find_extern := -1;
  end;
end;

{ flush_externs - give the blocks back.

  0x0A676E, 0x46 bytes (no A5: internal): each block disposed (806
  bytes), the head cleared. }

procedure flush_externs; internal;
var
  b: coff_syms_$extern_ptr_t;
begin
  if externs <> nil then begin
    b := externs^.next;
    while externs <> nil do begin
      pas_$dispose(externs, 806);
      externs := b;
      if b <> nil then
        b := b^.next;
    end;
    externs := nil;
  end;
end;

{ number_coff_syms - number the symbols: from 2 the routines of il_184's
  chain (105, 107, 167, 108; +266, two each, two more for a second entry
  name +304), the code sections with code (+64), the exception
  section (unix_objmod +0x5D2C), the unwind section (+0x5D38), the data
  sections (+44), the commons (+32); then (+0 the first external's) the
  transfer vectors' section (+0x5D6C), il_114's .bss, the .rwdi
  (+0x5D40), with -DB .lines (+0x5D3C), .symbols (+0x5D30, -DBS/-DBA)
  and .blocks (+0x5D34); then the externals by count_global_sym: a class
  3 module's variables of class 1 or 7 and its commons, the variables of
  class 4, 8 and of class 3 with bit 16 of +32 (il_144 of them; class
  10 ones of a class 3 module take their +80's +32), the address
  constants' targets (form 2; form 4 a kind 110, or its +40 when a
  common's, or an external routine), the transfer vectors, the external
  references (il_12c: commons only, else reported 'CASE'), the absolute
  address constants' and the code sections' external routines and
  commons.  The count to unix_objmod +0x5DC8; the blocks freed.

  0x0A6AC2, 0x48C bytes.

  Not known from the original:
  - the names. }

procedure number_coff_syms;
var
  r: il_$node_ptr_t;
  a: il_$node_ptr_t;
  v: il_$node_ptr_t;
  n: integer;
  db: integer;

  { count_global_sym - give external p its symbol (find_extern): a
    variable's +76 (its name +4, or the Modula-2 native name for a class
    6 module with +24 bit 9), a routine's +266 (+296), a kind 110's +66,
    a 111's +32 (+4); a transfer vector's name (159) and a 208's are
    entered in unix_objmod's tables (256 each: 'LIB_DSC_TBL OVERFLOW',
    'AT_LIB_DSC_TBL OVERFLOW') with the identifier of the name.  Other
    kinds are reported ('UNKNOWN SYM TYPE IN COUNT_GLOBAL_SYM').

    0x0A67B4, 0x244 bytes.  p a pointer by value (its slot's address
    passed to modify_m2_native_external_name).

    Not known from the original:
    - the names. }

  procedure count_global_sym(
      p: il_$node_ptr_t); options(val_param);
  var
    id: il_$node_ptr_t;
  begin
    if p = nil then
      return;
    case p^.kind of
      109:
        if ((ord(il_184^.xc[377]) & 16#70) div 16 = 6) and
           ((p^.xw[12] & 16#200) <> 0) then
          p^.xw[38] := find_extern(true, modify_m2_native_external_name(addr(p)))
        else
          p^.xw[38] := find_extern(true, p^.xp[1]);
      167, 105, 107, 108:
        if (ord(il_184^.xc[377]) & 16#70) div 16 = 6 then
          p^.xw[133] := find_extern(true, modify_m2_native_external_name(addr(p)))
        else
          p^.xw[133] := find_extern(true, p^.xp[74]);
      110:
        p^.xw[33] := find_extern(true, p);
      159: begin
        id := idntk(76, p^.xc[12 + 2 * p^.xw[5]], p^.xw[4]);
        uobj_global_name_count.l := uobj_global_name_count.l + 1;
        if uobj_global_name_count.l > 256 then
          cgerr_no_source(24, integer32(strtk('LIB_DSC_TBL OVERFLOW', 20)));
        uobj_global_names[uobj_global_name_count.low].name := p;
        uobj_global_names[uobj_global_name_count.low].symndx :=
          find_extern(true, id);
        uobj_global_names[uobj_global_name_count.low].ident := id;
      end;
      208: begin
        id := idntk(76, p^.xc[50], ord(p^.xc[49]));
        uobj_local_name_count.l := uobj_local_name_count.l + 1;
        if uobj_local_name_count.l > 256 then
          cgerr_no_source(24, integer32(strtk('AT_LIB_DSC_TBL OVERFLOW', 23)));
        uobj_local_names[uobj_local_name_count.low].name := p;
        uobj_local_names[uobj_local_name_count.low].symndx :=
          find_extern(true, id);
        uobj_local_names[uobj_local_name_count.low].ident := id;
      end;
      111:
        p^.xw[16] := find_extern(true, p^.xp[1]);
      otherwise
        cgerr_no_source(28, integer32(strtk(
          'UNKNOWN SYM TYPE IN COUNT_GLOBAL_SYM', 36)));
    end;
  end;

  { count_tvs - count_global_sym for each distinct transfer vector
    target (il_128, +18 against a word list from gspace of 2 * the
    count's low word, unix_objmod +0x5D72).

    0x0A6A48, 0x7A bytes.

    Not known from the original:
    - the names. }

  procedure count_tvs;
  var
    n: integer32;
    i: integer32;
    seen: coff_syms_$words_ptr_t;
    tv: il_$node_ptr_t;
    found: boolean;
  begin
    n := 0;
    seen := gspace(2 * uobj_ntvs.low);
    tv := il_128;
    while tv <> nil do begin
      found := false;
      if n > 0 then
        for i := 1 to n do
          if seen^[i] = tv^.xw[9] then begin
            found := true;
            exit;
          end;
      if not found then begin
        count_global_sym(tv^.xp[2]);
        n := n + 1;
        seen^[n] := tv^.xw[9];
      end;
      tv := tv^.xp[1];
    end;
  end;

begin
  externs := nil;
  first_extern := 0;
  next_sym := 2;
  r := il_184;
  while r <> nil do begin
    if (r^.kind = 105) or (r^.kind = 107) or (r^.kind = 167) or
       (r^.kind = 108) then begin
      r^.xw[133] := next_sym;
      next_sym := next_sym + 2;
      if r^.xl[76] <> 0 then
        next_sym := next_sym + 2;
    end;
    r := r^.xp[1];
  end;
  first_section := next_sym;
  r := il_10c;
  while r <> nil do begin
    if r^.xl[3] <> 0 then begin
      r^.xw[32] := next_sym;
      next_sym := next_sym + 2;
    end;
    r := r^.xp[1];
  end;
  if il_13c <> 0 then begin
    uobj_exc_symndx.l := next_sym;
    next_sym := next_sym + 2;
  end;
  uobj_5d38 := next_sym;
  next_sym := next_sym + 2;
  r := il_110;
  while r <> nil do begin
    r^.xw[22] := next_sym;
    next_sym := next_sym + 2;
    r := r^.xp[1];
  end;
  r := il_118;
  while r <> nil do begin
    r^.xw[16] := next_sym;
    next_sym := next_sym + 2;
    r := r^.xp[2];
  end;
  first_extern := next_sym;
  if uobj_ntvs.l > 0 then begin
    uobj_5d6c.l := next_sym;
    next_sym := next_sym + 2;
  end;
  if il_114 > 0 then
    next_sym := next_sym + 2;
  if uobj_headers_counted then begin
    uobj_5d40 := next_sym;
    next_sym := next_sym + 2;
  end;
  db := cargs_$options.db;
  if db <> 0 then begin
    if il_d4 <> nil then begin
      uobj_5d3c := next_sym;
      next_sym := next_sym + 2;
    end;
    if db >= 2 then begin
      uobj_5d30 := next_sym;
      next_sym := next_sym + 2;
    end;
    uobj_5d34 := next_sym;
    next_sym := next_sym + 2;
  end;
  if (ord(il_184^.xc[377]) & 16#70) div 16 = 3 then begin
    r := il_184;
    while r <> nil do begin
      if (r^.kind = 105) or (r^.kind = 106) then begin
        v := r^.xp[4];
        while v <> nil do begin
          if (v^.kind = 109) and ((v^.xw[36] = 1) or (v^.xw[36] = 7)) then
            count_global_sym(v);
          v := v^.xp[4];
        end;
      end;
      r := r^.xp[1];
    end;
  end;
  if (ord(il_184^.xc[377]) & 16#70) div 16 = 3 then begin
    r := il_118;
    while r <> nil do begin
      count_global_sym(r);
      r := r^.xp[2];
    end;
  end;
  n := il_144;
  r := il_184;
  while (r <> nil) and (n <> 0) do begin
    v := r^.xp[4];
    while (v <> nil) and (n <> 0) do begin
      if (v^.kind = 109) and
         ((v^.xw[36] = 4) or (v^.xw[36] = 8) or
          ((v^.xw[36] = 3) and ((v^.xl[8] & 16#10000) <> 0))) then begin
        count_global_sym(v);
        n := n - 1;
      end
      else if (v^.kind = 109) and (v^.xw[36] = 10) and
              ((ord(il_184^.xc[377]) & 16#70) div 16 = 3) then
        v^.xw[38] := v^.xp[20]^.xw[16];
      v := v^.xp[4];
    end;
    r := r^.xp[1];
  end;
  r := il_110;
  while r <> nil do begin
    a := r^.xp[3];
    while a <> nil do
      if a^.kind <> 163 then
        a := a^.xp[29]
      else begin
        if ord(a^.xc[20]) = 2 then
          count_global_sym(a^.xp[2])
        else if (ord(a^.xc[20]) = 4) and (a^.xp[2]^.kind = 110) then begin
          v := a^.xp[2];
          if ((ord(v^.xc[44]) & 16#F0) div 16 = 1) and (v^.xp[10] <> nil) then
            a^.xp[2] := v^.xp[10]
          else
            count_global_sym(v);
        end
        else if (ord(a^.xc[20]) = 4) and
                ((a^.xp[2]^.xw[188] & 384) div 128 = 2) then
          count_global_sym(a^.xp[2]);
        a := a^.xp[1];
      end;
    r := r^.xp[1];
  end;
  count_tvs;
  r := il_12c;
  while r <> nil do begin
    if not ((r^.xp[2]^.kind = 109) and (r^.xp[2]^.xw[36] = 3)) then
      cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
    if (r^.xp[2]^.kind = 109) and ((r^.xp[2]^.xl[8] & 16#10000) = 0) then
      count_global_sym(r^.xp[2]);
    r := r^.xp[1];
  end;
  r := il_130;
  while r <> nil do begin
    v := r^.xp[3];
    if ((v^.kind = 105) or (v^.kind = 107) or (v^.kind = 167) or
        (v^.kind = 108)) and ((v^.xw[188] & 384) div 128 = 2) then
      count_global_sym(v)
    else if (v^.kind = 109) and (v^.xw[36] = 3) and
            ((v^.xl[8] & 16#10000) = 0) then
      count_global_sym(v)
    else if v^.kind = 110 then
      count_global_sym(v);
    r := r^.xp[1];
  end;
  r := il_10c;
  while r <> nil do begin
    if (r^.kind = 108) or (r^.kind = 107) then begin
      if (r^.xw[188] & 384) div 128 = 2 then
        count_global_sym(r);
    end
    else if r^.kind = 109 then
      if (r^.xw[36] = 3) and ((r^.xl[8] & 16#10000) = 0) then
        count_global_sym(r);
    r := r^.xp[1];
  end;
  uobj_nsyms_coff := next_sym;
  flush_externs;
end;

{ coff_sym_dmp - write the symbol table at unix_objmod +0x5D60.

  0x0A7CA4, 0x66C bytes (a 52-byte frame).  The entry size 18 (made
  even); '.file' (value 2, section -2, class 103, one auxiliary) and its
  auxiliary: the source's pathname (iosub), in the string table for more
  than 14 characters.  Then: each routine of il_184's chain and its
  second entry name (put_func_def); the code sections with code, the
  exception and unwind sections, the data sections, the commons, .aptv,
  .bss, .rwdi, .lines, .symbols, .blocks (put_sect_sym; the numbers
  from unix_objmod); the globals and externals in number_coff_syms's
  order (put_global_sym, defined for a class 3 module's variables and
  commons and the other variables, undefined for the rest); put_tvs;
  the code sections' externals (+52 list).  The blocks freed;
  unix_objmod +0x5DC4 the table's size (M$MIS$LLW).

  Not known from the original:
  - the names. }

procedure coff_sym_dmp;
var
  te: coff_syms_$type_exp_t;
  add_underscore: boolean;
  i: integer;
  size: integer;
  pos: integer32;
  map: coff_syms_$syment_ptr_t;
  r: il_$node_ptr_t;
  v: il_$node_ptr_t;
  a: il_$node_ptr_t;
  refs: coff_syms_$refs_ptr_t;
  s: il_$node_ptr_t;
  n: integer;
  db: integer;
  form: integer;
  undefined: boolean;

  { get_coff_type - a symbol's n_type: a variable's from its type (+28);
    else DT_FCN (32) for a routine (kinds 105, 107, 108, 159, 167, 208,
    234, a bit set after the routine), or-ed with T_INT (4).

    0x0A6F52, 0x46 bytes (recursive).

    Not known from the original:
    - the names. }

  function get_coff_type(
      p: il_$node_ptr_t): integer; options(val_param);
  var
    t: integer;
  begin
    t := 0;
    if p^.kind = 109 then
      t := get_coff_type(p^.xp[7])
    else begin
      if p^.kind in [105, 107, 108, 159, 167, 208, 234] then
        t := 32;
      t := t ! 4;
    end;
    get_coff_type := t;
  end;

  { get_lnno_ptr - the file offset of the line number entry of symbol
    sym (line 0), or 0.

    0x0A6FB6, 0x80 bytes.  The entries (unix_objmod +0x5D64 of them at
    +0x5D68) mapped with getobj and searched (count + 1 passes, `dbf'
    from the count).

    Not known from the original:
    - the names. }

  function get_lnno_ptr(
      sym: integer32): integer32; options(val_param);
  var
    l: unix_objmod_$linenos_ptr_t;
    p: integer32;
    i: integer32;
  begin
    p := 0;
    if uobj_nlnnos.l <> 0 then begin
      l := getobj(uobj_lnno_start, uobj_nlnnos.l * 6);
      for i := 0 to uobj_nlnnos.l do
        if (l^[i].l_lnno = 0) and (l^[i].l_addr = sym) then begin
          p := i * 6 + uobj_lnno_start;
          exit;
        end;
      freeobj(l);
    end;
    get_lnno_ptr := p;
  end;

  { get_section_no - the section number of symbol sym, read back from
    the table (M$MIS$LLW by the entry size, the parent's -24).

    0x0A7036, 0x58 bytes; the parent's frame in A1. }

  function get_section_no(
      sym: integer32): integer32; options(val_param);
  var
    e: coff_syms_$syment_ptr_t;
    n: integer32;
  begin
    e := getobj(sym * size + uobj_symptr, size);
    n := e^.n_scnum;
    freeobj(e);
    get_section_no := n;
  end;

  { get_section_hdr - section n's header mapped (getobj, 40 bytes at
    64 + (n - 1) * 40: after the file and optional headers).

    0x0A708E, 0x2C bytes: the pointer in A0. }

  function get_section_hdr(
      n: integer32): unix_objmod_$scnhdr_ptr_t; options(val_param);
  begin
    get_section_hdr := getobj((n - 1) * 40 + 64, 40);
  end;

  { map_name - the len characters of s folded to lower case, in place.

    0x0A70BA, 0x3E bytes.  s by address, len a word by value. }

  procedure map_name(
      in out s: univ strings_$bytes_t;
      len: integer); options(val_param);
  var
    i: integer;
    c: char;
  begin
    for i := 1 to len do begin
      c := s[i];
      if (c >= 'A') and (c <= 'Z') then
        s[i] := chr(ord(c) + 32);
    end;
  end;

  { put_name - the symbol being written (the parent's -16) gets id's
    name: in place for 8 characters or fewer (a NUL after fewer, `bcc'
    unsigned), else in the string table.

    0x0A70F8, 0x5C bytes; the parent's frame in A1; id by value (its
    slot passed by address to string_table). }

  procedure put_name(
      id: il_$node_ptr_t); options(val_param);
  var
    i: integer;
  begin
    if id^.idnt_len <= 8 then begin
      for i := 1 to id^.idnt_len do
        map^.n_name.chars[i] := id^.idnt_name[i];
      if id^.idnt_len < 8 then
        map^.n_name.chars[id^.idnt_len + 1] := chr(0);
    end
    else
      string_table(map^.n_name, id);
  end;

  { put_sect_sym - the symbol of section n named name (static, one
    auxiliary: the section's size, relocation and line counts).

    0x0A7154, 0xC8 bytes; the parent's frame from the dynamic link.
    n and name by value; the header mapped by get_section_hdr. }

  procedure put_sect_sym(
      n: integer32;
      name: il_$node_ptr_t); options(val_param);
  var
    h: unix_objmod_$scnhdr_ptr_t;
  begin
    h := get_section_hdr(n);
    pos := pos + size;
    map := putobj(pos, size);
    put_name(name);
    map^.n_value := h^.s_paddr;
    map^.n_scnum := n;
    map^.n_type := 0;
    map^.n_sclass := chr(3);
    map^.n_numaux := chr(1);
    freeobj(map);
    pos := pos + size;
    map := putobj(pos, size);
    map^.x_scnlen := h^.s_size;
    map^.x_nreloc := h^.s_nreloc;
    map^.x_nlinno := h^.s_nlnno;
    freeobj(h);
    freeobj(map);
  end;

  { put_global_sym - the symbol of external or global p (class 2), defined
    here (its section and address, its type) or not.

    0x0A721C, 0x79A bytes; the parent's frame in A1; p a pointer (its
    slot passed to modify_m2_native_external_name) and defined a byte by
    value.  For the kinds in [105, 107..111, 159, 167, 208] (a bit set
    after the routine) only a name find_extern does not know (result
    not 0: the first time) is written (159 and 208 through the next
    entry of unix_objmod's tables).  The name: a routine's +296 (folded
    unless -U by map_name; with -UC a '_' added when it has no '$' and
    neither begins nor ends with '_'; the Modula-2 native name for a
    class 6 module); 159 and 208 their names (section 0); 110 its +72
    (the '_' rule unless +26 bit 14; section 0; the address moved by
    il_184's section for +11 bits 7..4 7 or 1); a variable its +4 and by
    class (+72, a jump table): 1 its section and offset (static), 3 a
    common's size (type_exp, when +32 bit 16), 4, 8 its section and
    offset (+20 for 8), 7 static with +20, 10 its +80's section; 111 its
    +4.

    Not known from the original:
    - the names; the result for a kind not in the set (the image tests
      D0 as the last call left it). }

  procedure put_global_sym(
      p: il_$node_ptr_t;
      defined: boolean); options(val_param);
  var
    r: integer32;
    sec: integer32;
    h: unix_objmod_$scnhdr_ptr_t;
    id: il_$node_ptr_t;
    s: il_$node_ptr_t;
    j: integer;
    found: boolean;
  begin
    r := 1;
    if p^.kind in [105, 107, 108, 109, 110, 111, 159, 167, 208] then begin
      case p^.kind of
        109:
          if ((ord(il_184^.xc[377]) & 16#70) div 16 = 6) and
             ((p^.xw[12] & 16#200) <> 0) then
            r := find_extern(false, modify_m2_native_external_name(addr(p)))
          else
            r := find_extern(false, p^.xp[1]);
        167, 105, 107, 108:
          if (ord(il_184^.xc[377]) & 16#70) div 16 = 6 then
            r := find_extern(false, modify_m2_native_external_name(addr(p)))
          else
            r := find_extern(false, p^.xp[74]);
        110:
          r := find_extern(false, p);
        111:
          r := find_extern(false, p^.xp[1]);
        159: begin
          uobj_global_name_count.l := uobj_global_name_count.l + 1;
          if uobj_global_name_count.l > 256 then
            cgerr_no_source(24, integer32(strtk('LIB_DSC_TBL OVERFLOW', 20)));
          r := find_extern(false,
                           uobj_global_names[uobj_global_name_count.low].ident);
        end;
        208: begin
          uobj_local_name_count.l := uobj_local_name_count.l + 1;
          if uobj_local_name_count.l > 256 then
            cgerr_no_source(24, integer32(strtk('AT_LIB_DSC_TBL OVERFLOW', 23)));
          r := find_extern(false,
                           uobj_local_names[uobj_local_name_count.low].ident);
        end;
      end;
      if r = 0 then
        return;
    end;
    pos := pos + size;
    map := putobj(pos, size);
    if defined then begin
      if (p^.kind = 105) or (p^.kind = 107) or (p^.kind = 167) or
         (p^.kind = 108) then
        sec := get_section_no(p^.xw[133])
      else if p^.kind = 111 then begin
        sec := p^.xw[17];
        map^.n_scnum := sec;
      end
      else begin
        if p^.kind = 110 then
          s := il_184
        else
          s := p^.xp[5];
        sec := s^.xp[48]^.xw[23];
      end;
      h := get_section_hdr(sec);
      map^.n_value := h^.s_paddr;
      freeobj(h);
      map^.n_type := get_coff_type(p);
    end
    else begin
      map^.n_scnum := 0;
      map^.n_value := 0;
      map^.n_type := 0;
    end;
    map^.n_sclass := chr(2);
    map^.n_numaux := chr(0);
    case p^.kind of
      167, 108, 107, 105:
        if not cargs_$options.u then begin
          id := idntk(76, p^.xp[74]^.idnt_name, p^.xp[74]^.idnt_len);
          map_name(id^.idnt_name, id^.idnt_len);
          put_name(id);
        end
        else if cargs_$options.uc then begin
          found := false;
          for j := 1 to p^.xp[74]^.idnt_len do
            if p^.xp[74]^.idnt_name[j] = '$' then begin
              found := true;
              exit;
            end;
          if not found then
            if (p^.xp[74]^.idnt_name[p^.xp[74]^.idnt_len] <> '_') and
               (p^.xp[74]^.idnt_name[1] <> '_') then
              add_underscore := true;
          if add_underscore then begin
            id := idntk(76, p^.xp[74]^.idnt_name, p^.xp[74]^.idnt_len + 1);
            id^.idnt_name[id^.idnt_len] := '_';
          end
          else
            id := idntk(76, p^.xp[74]^.idnt_name, p^.xp[74]^.idnt_len);
          put_name(id);
          add_underscore := false;
        end
        else if (ord(il_184^.xc[377]) & 16#70) div 16 = 6 then
          put_name(modify_m2_native_external_name(addr(p)))
        else
          put_name(p^.xp[74]);
      159: begin
        if not cargs_$options.u then begin
          id := idntk(76, p^.xc[12 + 2 * p^.xw[5]], p^.xw[4]);
          map_name(id^.idnt_name, id^.idnt_len);
          put_name(id);
        end
        else
          put_name(idntk(76, p^.xc[12 + 2 * p^.xw[5]], p^.xw[4]));
        map^.n_scnum := 0;
      end;
      208: begin
        if not cargs_$options.u then begin
          id := idntk(76, p^.xc[50], ord(p^.xc[49]));
          map_name(id^.idnt_name, id^.idnt_len);
          put_name(id);
        end
        else
          put_name(idntk(76, p^.xc[50], ord(p^.xc[49])));
        map^.n_scnum := 0;
      end;
      110: begin
        if not cargs_$options.uc then
          id := idntk(76, p^.xc[72], p^.xw[35])
        else begin
          found := false;
          for j := 1 to p^.xw[35] do
            if p^.xc[71 + j] = '$' then begin
              found := true;
              exit;
            end;
          if not found then
            if (p^.xc[71 + p^.xw[35]] <> '_') and (p^.xc[72] <> '_') then
              add_underscore := true;
          if (p^.xw[13] & 16#4000) <> 0 then
            add_underscore := false;
          if add_underscore then begin
            id := idntk(76, p^.xc[72], p^.xw[35] + 1);
            id^.idnt_name[id^.idnt_len] := '_';
          end
          else
            id := idntk(76, p^.xc[72], p^.xw[35]);
          add_underscore := false;
        end;
        if not cargs_$options.u then
          map_name(id^.idnt_name, id^.idnt_len);
        put_name(id);
        map^.n_scnum := 0;
        if (ord(p^.xc[11]) & 16#F0) div 16 = 7 then
          map^.n_value := map^.n_value + il_184^.xp[48]^.xl[5] -
                          il_184^.xp[48]^.xl[4]
        else if (ord(p^.xc[11]) & 16#F0) div 16 = 1 then
          map^.n_value := map^.n_value - il_184^.xp[48]^.xl[4];
      end;
      109: begin
        if not cargs_$options.u then begin
          id := idntk(76, p^.xp[1]^.idnt_name, p^.xp[1]^.idnt_len);
          map_name(id^.idnt_name, id^.idnt_len);
          put_name(id);
        end
        else if ((ord(il_184^.xc[377]) & 16#70) div 16 = 6) and
                ((p^.xw[12] & 16#200) <> 0) then
          put_name(modify_m2_native_external_name(addr(p)))
        else
          put_name(p^.xp[1]);
        case p^.xw[36] of
          1: begin
            s := p^.xp[5]^.xp[48];
            map^.n_scnum := s^.xw[23];
            map^.n_value := map^.n_value + p^.xl[14] - s^.xl[4];
            map^.n_sclass := chr(3);
          end;
          7: begin
            s := p^.xp[5]^.xp[48];
            map^.n_scnum := s^.xw[23];
            map^.n_value := map^.n_value + p^.xl[14] + s^.xl[5] - s^.xl[4];
            map^.n_sclass := chr(3);
          end;
          3: begin
            map^.n_scnum := 0;
            if (p^.xl[8] & 16#10000) <> 0 then begin
              type_exp(p, addr(te));
              map^.n_value := te.size;
            end;
          end;
          4, 8: begin
            s := p^.xp[5]^.xp[48];
            map^.n_scnum := s^.xw[23];
            if p^.xw[36] = 4 then
              map^.n_value := map^.n_value + p^.xl[14] - s^.xl[4]
            else
              map^.n_value := map^.n_value + p^.xl[14] + s^.xl[5] - s^.xl[4];
          end;
          10:
            map^.n_scnum := p^.xp[20]^.xw[17];
          otherwise
            ;
        end;
      end;
      111:
        if not cargs_$options.u then begin
          id := idntk(76, p^.xp[1]^.idnt_name, p^.xp[1]^.idnt_len);
          map_name(id^.idnt_name, id^.idnt_len);
          put_name(id);
        end
        else
          put_name(p^.xp[1]);
      otherwise
        ;
    end;
    freeobj(map);
  end;

  { put_tvs - put_global_sym (undefined) for each distinct transfer
    vector target, as count_tvs.

    0x0A79D2, 0x88 bytes; the parent's frame from the dynamic link,
    passed on in A1. }

  procedure put_tvs;
  var
    n: integer32;
    i: integer32;
    seen: coff_syms_$words_ptr_t;
    tv: il_$node_ptr_t;
    found: boolean;
  begin
    n := 0;
    seen := gspace(2 * uobj_ntvs.low);
    tv := il_128;
    while tv <> nil do begin
      found := false;
      if n > 0 then
        for i := 1 to n do
          if seen^[i] = tv^.xw[9] then begin
            found := true;
            exit;
          end;
      if not found then begin
        put_global_sym(tv^.xp[2], false);
        n := n + 1;
        seen^[n] := tv^.xw[9];
      end;
      tv := tv^.xp[1];
    end;
  end;

  { put_func_def - the symbol of routine p's entry name (one auxiliary):
    its address (with an entry control block its +108 less its section's
    +16 plus the section's address, else its +188 section's address plus
    +100's +56), its name (folded unless -U; the Modula-2 native name for
    a class 6 module; the '_' rule under -UC, the loop's index the
    parent's -28), its type, its section, class 3 for +376 bit 3 else 2;
    the auxiliary: size +160, the line numbers (get_lnno_ptr of +266),
    the next symbol +266 + 2.

    0x0A7A5A, 0x24A bytes; the parent's frame from the dynamic link; p
    (its slot passed to modify_m2_native_external_name) and name by
    value.

    Not known from the original:
    - the names. }

  procedure put_func_def(
      p: il_$node_ptr_t;
      name: il_$node_ptr_t); options(val_param);
  var
    h: unix_objmod_$scnhdr_ptr_t;
    v: integer32;
    n: il_$node_ptr_t;
    flag: boolean;
    found: boolean;
  begin
    if has_ecb(p) then begin
      h := get_section_hdr(p^.xp[48]^.xw[23]);
      v := p^.xl[27] - p^.xp[48]^.xl[4] + h^.s_paddr;
    end
    else begin
      h := get_section_hdr(p^.xp[47]^.xw[33]);
      v := h^.s_paddr + p^.xp[25]^.xl[14];
    end;
    freeobj(h);
    pos := pos + size;
    map := putobj(pos, 18);
    if not cargs_$options.u then begin
      n := idntk(76, name^.idnt_name, name^.idnt_len);
      map_name(n^.idnt_name, n^.idnt_len);
    end
    else if (ord(il_184^.xc[377]) & 16#70) div 16 = 6 then
      n := modify_m2_native_external_name(addr(p))
    else
      n := name;
    flag := false;
    if cargs_$options.uc then begin
      found := flag;
      for i := 1 to n^.idnt_len do
        if n^.idnt_name[i] = '$' then begin
          found := true;
          exit;
        end;
      if not found then
        if (n^.idnt_name[n^.idnt_len] <> '_') and (n^.idnt_name[1] <> '_') then
          flag := true;
    end;
    if flag then begin
      n := idntk(76, n^.idnt_name, n^.idnt_len + 1);
      n^.idnt_name[n^.idnt_len] := '_';
    end;
    put_name(n);
    map^.n_value := v;
    map^.n_type := get_coff_type(p);
    if not has_ecb(p) then
      map^.n_scnum := p^.xp[47]^.xw[33]
    else
      map^.n_scnum := p^.xp[48]^.xw[23];
    if (ord(p^.xc[376]) & 8) <> 0 then
      map^.n_sclass := chr(3)
    else
      map^.n_sclass := chr(2);
    map^.n_numaux := chr(1);
    freeobj(map);
    pos := pos + size;
    map := putobj(pos, size);
    map^.x_tagndx := 0;
    map^.x_fsize := p^.xl[40];
    map^.x_lnnoptr := get_lnno_ptr(p^.xw[133]);
    map^.x_endndx := p^.xw[133] + 2;
    freeobj(map);
  end;

begin
  add_underscore := false;
  uobj_global_name_count.l := 0;
  uobj_local_name_count.l := 0;
  size := 18;
  if odd(size) then
    size := size + 1;
  pos := uobj_symptr;
  map := putobj(pos, size);
  map^.n_name.chars := '.file   ';
  map^.n_value := 2;
  map^.n_scnum := -2;
  map^.n_type := 0;
  map^.n_sclass := chr(103);
  map^.n_numaux := chr(1);
  freeobj(map);
  pos := pos + size;
  map := putobj(pos, size);
  if iosub_$source_pathname_length > 14 then
    string_table(map^.n_name,
                 strtk(iosub_$source_pathname, iosub_$source_pathname_length))
  else
    for i := 1 to iosub_$source_pathname_length do
      map^.x_fname[i] := iosub_$source_pathname[i];
  freeobj(map);
  r := il_184;
  while r <> nil do begin
    if (r^.kind = 105) or (r^.kind = 107) or (r^.kind = 167) or
       (r^.kind = 108) then begin
      put_func_def(r, r^.xp[74]);
      if r^.xp[76] <> nil then
        put_func_def(r, r^.xp[76]);
    end;
    r := r^.xp[1];
  end;
  r := il_10c;
  while r <> nil do begin
    if r^.xl[3] <> 0 then
      put_sect_sym(r^.xw[33], r^.xp[2]);
    r := r^.xp[1];
  end;
  if il_13c <> 0 then
    put_sect_sym(uobj_exception_sect, strtk('.exception_table', 16));
  put_sect_sym(uobj_unwind_sect, strtk('.unwind', 7));
  r := il_110;
  while r <> nil do begin
    put_sect_sym(r^.xw[23], r^.xp[2]);
    r := r^.xp[1];
  end;
  r := il_118;
  while r <> nil do begin
    put_sect_sym(r^.xw[17], r^.xp[1]);
    r := r^.xp[2];
  end;
  if uobj_ntvs.l > 0 then
    put_sect_sym(uobj_aptv_sect, strtk('.aptv', 5));
  if il_114 > 0 then
    put_sect_sym(uobj_bss_sect, strtk('.bss', 4));
  if uobj_headers_counted then
    put_sect_sym(uobj_rwdi_sect, strtk('.rwdi', 5));
  db := cargs_$options.db;
  if db <> 0 then begin
    if il_d4 <> nil then
      put_sect_sym(uobj_lines_sect, strtk('.lines', 6));
    if cargs_$options.db >= 2 then
      put_sect_sym(uobj_symbols_sect, strtk('.symbols', 8));
    put_sect_sym(uobj_blocks_sect, strtk('.blocks', 7));
  end;
  if (ord(il_184^.xc[377]) & 16#70) div 16 = 3 then begin
    r := il_184;
    while r <> nil do begin
      if (r^.kind = 105) or (r^.kind = 106) then begin
        v := r^.xp[4];
        while v <> nil do begin
          if (v^.kind = 109) and ((v^.xw[36] = 1) or (v^.xw[36] = 7)) then
            put_global_sym(v, true);
          v := v^.xp[4];
        end;
      end;
      r := r^.xp[1];
    end;
  end;
  if (ord(il_184^.xc[377]) & 16#70) div 16 = 3 then begin
    r := il_118;
    while r <> nil do begin
      put_global_sym(r, true);
      r := r^.xp[2];
    end;
  end;
  n := il_144;
  r := il_184;
  while (r <> nil) and (n <> 0) do begin
    v := r^.xp[4];
    while (v <> nil) and (n <> 0) do begin
      if (v^.kind = 109) and
         ((v^.xw[36] = 4) or (v^.xw[36] = 8) or
          ((v^.xw[36] = 3) and ((v^.xl[8] & 16#10000) <> 0))) then begin
        put_global_sym(v, true);
        n := n - 1;
      end;
      v := v^.xp[4];
    end;
    r := r^.xp[1];
  end;
  r := il_110;
  while r <> nil do begin
    a := r^.xp[3];
    while a <> nil do
      if a^.kind <> 163 then
        a := a^.xp[29]
      else begin
        form := ord(a^.xc[20]);
        undefined := form = 2;
        if not undefined and (form = 4) then
          undefined := (a^.xp[2]^.kind = 110) or
                       ((a^.xp[2]^.xw[188] & 384) div 128 = 2);
        if undefined then
          put_global_sym(a^.xp[2], false);
        a := a^.xp[1];
      end;
    r := r^.xp[1];
  end;
  put_tvs;
  r := il_12c;
  while r <> nil do begin
    if not ((r^.xp[2]^.kind = 109) and (r^.xp[2]^.xw[36] = 3)) then
      cgerr_no_source(20, integer32(idntk(76, 'CASE', 4)));
    if (r^.xp[2]^.kind = 109) and ((r^.xp[2]^.xl[8] & 16#10000) = 0) then
      put_global_sym(r^.xp[2], false);
    r := r^.xp[1];
  end;
  r := il_130;
  while r <> nil do begin
    v := r^.xp[3];
    if ((v^.kind = 105) or (v^.kind = 107) or (v^.kind = 167) or
        (v^.kind = 108)) and ((v^.xw[188] & 384) div 128 = 2) then
      put_global_sym(v, false)
    else if (v^.kind = 109) and (v^.xw[36] = 3) and
            ((v^.xl[8] & 16#10000) = 0) then
      put_global_sym(v, false)
    else if v^.kind = 110 then
      put_global_sym(v, false);
    r := r^.xp[1];
  end;
  s := il_10c;
  while s <> nil do begin
    refs := coff_syms_$refs_ptr_t(s^.xp[13]);
    while refs <> nil do begin
      for i := 1 to refs^.count do begin
        v := refs^.e[i].node;
        if (v^.kind = 108) or (v^.kind = 107) then begin
          if (v^.xw[188] & 384) div 128 = 2 then
            put_global_sym(v, false);
        end
        else if v^.kind = 109 then
          if (v^.xw[36] = 3) and ((v^.xl[8] & 16#10000) = 0) then
            put_global_sym(v, false);
      end;
      refs := refs^.next;
    end;
    s := s^.xp[1];
  end;
  flush_externs;
  uobj_syms_size := uobj_nsyms_coff * size;
end;
