{ objutil - OBJUTIL_, the binder's reader of the libraries a program is
  bound against: a library's global symbols and global sections are read
  (once, when a name is first looked up) and the names kept, so that the
  binder can tell whether a global or a section will be found at run
  time.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x08A9E8  0x08C3C8  inlib_list_add
    0x08AAC0  0x08C4A0  object_target
    0x08AB08  0x08C4E8  get_coff_stringtab_info
    0x08AB78  0x08C558  get_string
    0x08AC40  0x08C620  free_string
    0x08AC62  0x08C642  extended_name_to_string
    0x08AD2A  0x08C70A  inlib_read_coff_inlib
    0x08C6C6  0x08E0A6  inlib_read_obj_inlib
    0x08E310  0x08FCF0  inlib_read_inlib
    0x08E83A  0x09021A  objutil_$inlib_init
    0x08E8B6  0x090296  objutil_$inlib_libname
    0x08E8E0  0x0902C0  objutil_$inlib_find_symbol
    0x08E916  0x0902F6  inlib_checklist (in objutil_$inlib_lookup_symbol)
    0x08E976  0x090356  objutil_$inlib_lookup_symbol
    0x08EA4A  0x09042A  objutil_$inlib_find_section
    0x08EA7A  0x09045A  inlib_checklist (in objutil_$inlib_lookup_section)
    0x08EADC  0x0904BC  objutil_$inlib_lookup_section
    0x08EB74  0x090554  objutil_$inlib_terminate
    A5 0x196D6C (cc.m68k), 0x316DDC (cc.a88k): the module's data, in
    SR10.2's layout (0x5C bytes).

  This is the source repository's translation of the SR10.2 /com/bind
  objutil (com/bind/objutil.pas, whose SR10.2 addresses follow); DOMAIN
  C 6.9's (compiled by Pascal Rev 8.89, with Apollo's internal inserts)
  was compared routine by routine (calls, constants, data offsets, the
  branches of the routines that differ in size) and found the same, but
  for Rev 8.89's code generation; the spans between the inlib_read_
  routines hold their message strings.  Each routine's header names its
  cc.m68k address.

  SR10.2:
    sr10.2  PROCEDURE$+0x0FE48  inlib_list_add
    sr10.2  PROCEDURE$+0x0FF14  object_target
    sr10.2  PROCEDURE$+0x0FF56  get_coff_stringtab_info
    sr10.2  PROCEDURE$+0x0FFC4  get_string
    sr10.2  PROCEDURE$+0x10080  free_string
    sr10.2  PROCEDURE$+0x1009A  extended_name_to_string
    sr10.2  PROCEDURE$+0x10162  inlib_read_coff_inlib
    sr10.2  PROCEDURE$+0x11A16  inlib_read_obj_inlib
    sr10.2  PROCEDURE$+0x1362E  inlib_read_inlib
    sr10.2  PROCEDURE$+0x13B46  objutil_$inlib_init
    sr10.2  PROCEDURE$+0x13B9E  objutil_$inlib_libname
    sr10.2  PROCEDURE$+0x13BBE  objutil_$inlib_find_symbol
    sr10.2  PROCEDURE$+0x13BE2  inlib_checklist (nested in
                                objutil_$inlib_lookup_symbol)
    sr10.2  PROCEDURE$+0x13C3C  objutil_$inlib_lookup_symbol
    sr10.2  PROCEDURE$+0x13D0A  objutil_$inlib_find_section
    sr10.2  PROCEDURE$+0x13D2E  inlib_checklist (nested in
                                objutil_$inlib_lookup_section)
    sr10.2  PROCEDURE$+0x13D92  objutil_$inlib_lookup_section
    sr10.2  PROCEDURE$+0x13E22  objutil_$inlib_terminate
    sr10.2  DATA$+0xDB94        the module's data (0x5C bytes)

  - The libraries to read are a list of names, each once; a library
    read can add the libraries it names itself (its COFF library list or
    OBJ library records) to the end.  A lookup reads the libraries not
    yet read, one by one, until the name is found.
  - A COFF library gives its sections that define a global and its
    external symbols that are defined, an OBJ library its sections whose
    names are globals and its symbols not hidden and defined; an OBJ
    name has its blanks taken off and its case turned over.
  - What cannot be read is reported through the error routine; the
    library is then skipped.
}
module objutil;

%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'us/us/ins/strl.ins.pas';
%include 'us/us/ins/rws.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include 'us/us/ins/objutil.ins.pas';
%include 'us/us/ins/coff.ins.pas';
%include 'us/us/ins/uid_list.ins.pas';
%include '/sys/ins/type_uids.ins.pas';
%include '/sys/ins/loader.ins.pas';

type
  objutil_string_ptr_t = ^objutil_$string_t;

  { A library to read. }
  objutil_lib_ptr_t = ^objutil_lib_t;
  objutil_lib_t = record                { 10 bytes }
    next: objutil_lib_ptr_t;            { +0 }
    name: objutil_string_ptr_t;         { +4: NUL-ended }
    len: integer;                       { +8: with the NUL }
  end;

  { A global a library defines. }
  objutil_name_ptr_t = ^objutil_name_t;
  objutil_name_t = record               { 10 bytes }
    next: objutil_name_ptr_t;           { +0 }
    name: objutil_string_ptr_t;         { +4 }
    len: integer;                       { +8 }
  end;

  { A section a library defines. }
  objutil_sect_ptr_t = ^objutil_sect_t;
  objutil_sect_t = record               { 14 bytes }
    next: objutil_sect_ptr_t;           { +0 }
    size: integer32;                    { +4 }
    name: objutil_string_ptr_t;         { +8 }
    len: integer;                       { +12 }
  end;

  { What a pointer from obj_$get points at, in an OBJ library. }
  objutil_obj_t = record
    case integer of
      1: (fhdr: obj_$file_hdr_t);
      2: (mhdr: obj_$mod_hdr_t);
      3: (libs: obj_$lib_list_t);
      4: (sect: obj_$sect_t);
      5: (sym: obj_$sym_t);
      6: (chars: objutil_$string_t);
  end;
  objutil_obj_ptr_t = ^objutil_obj_t;

{ The module's data, in its order (A5+offset). }
var
  { The targets object_target knows (the index is the target). }
  magics: array[0..2] of integer32 := [0, coff_$magic, coff_$magic_a88k];
                                        { +0 }
  unused_12: integer32;                 { +12 }
  sect_head: objutil_sect_t;            { +16: the sections' list head }
  sym_head: objutil_name_t;             { +32: the globals' list head }
  { The optional header's magic, by target. }
  aout_magics: array[0..2] of integer := [0, coff_$aout_magic,
                                          coff_$aout_magic];  { +44 }
  inlib_target: integer32;              { +52 }
  inlib_error_proc: objutil_$error_proc_t;  { +56 }
  lib_tail: objutil_lib_ptr_t;          { +60 }
  lib_cursor: objutil_lib_ptr_t;        { +64: the next library to read }
  lib_head: objutil_lib_ptr_t;          { +68 }
  sect_tail: objutil_sect_ptr_t;        { +72 }
  sym_tail: objutil_name_ptr_t;         { +76 }
  lib_count: integer;                   { +80 }
  lib_ent: obj_$lib_ent_ptr_t;          { +84 }
  objp: objutil_obj_ptr_t;              { +88 }

{ inlib_list_add - put a library on the list, unless it is there; its
  name is kept NUL-ended.

  cc.m68k 0x08A9E8, 0xD0 bytes: as SR10.2. }

procedure inlib_list_add(
    name: objutil_string_ptr_t;
    len: integer); internal;
var
  p: objutil_lib_ptr_t;
begin
  p := lib_head;
  while p <> nil do begin
    if strl_$eq(p^.name^, p^.len, name^, len) then exit;
    p := p^.next;
  end;
  if p = nil then begin
    p := rws_$alloc_heap(sizeof(objutil_lib_t));
    p^.name := rws_$alloc_heap(len + 1);
    strl_$copy(name^, len, p^.name^, p^.len, 1023);
    p^.name^[len + 1] := chr(0);
    p^.len := len + 1;
    if lib_tail = nil then begin
      p^.next := nil;
      lib_head := p;
    end
    else begin
      p^.next := lib_tail^.next;
      lib_tail^.next := p;
    end;
    lib_tail := p;
    if lib_cursor = nil then lib_cursor := p;
    lib_count := lib_count + 1;
  end;
end;

{ object_target - the target of a COFF file's magic number (0: none).

  cc.m68k 0x08AAC0, 0x48 bytes: as SR10.2. }

function object_target(in magic: integer32): integer;
var
  found: boolean;
  i: integer;
begin
  found := false;
  for i := 0 to 2 do
    if i <> 0 then
      if magics[i] = magic then begin
        found := true;
        exit;
      end;
  if not found then i := 0;
  object_target := i;
end;

{ get_coff_stringtab_info - where a COFF file's string table is (after
  the symbols) and its size (its first longword).

  cc.m68k 0x08AB08, 0x6C bytes: as SR10.2. }

procedure get_coff_stringtab_info(
    chan: integer;
    hdr: coff_$filehdr_ptr_t;
    out strtab_off: linteger;
    out strtab_size: linteger;
    out status: status_$t); internal;
var
  p: ^integer32;
begin
  status.all := 0;
  strtab_off := hdr^.f_nsyms * coff_$symesz + hdr^.f_symptr;
  p := obj_$get(chan, strtab_off, 4, status);
  if status.all = 0 then
    strtab_size := p^;
  obj_$free(chan, p, status);
end;

{ get_string - map a NUL-ended string of the string table: ptr is where
  it is mapped, len its length.  The mapping grows by 64 bytes at most
  until the NUL is in it.

  cc.m68k 0x08AB78, 0xC8 bytes: as SR10.2. }

procedure get_string(
    chan: integer;
    strtab_off: linteger;
    strtab_size: linteger;
    offset: linteger;
    out ptr: objutil_string_ptr_t;
    out len: integer;
    out status: status_$t); internal;
var
  chunk: integer32;
  want: integer;
  i: integer;
begin
  status.all := 0;
  if offset > strtab_size then begin
    status.all := obj_$outside_file;
    return;
  end;
  len := 0;
  chunk := min(strtab_size - offset, 64);
  repeat
    want := len + chunk;
    if want <= len then begin
      status.all := obj_$outside_file;
      return;
    end;
    ptr := obj_$get(chan, strtab_off + offset, want, status);
    if status.all <> 0 then return;
    for i := len + 1 to want do begin
      if ord(ptr^[i]) = 0 then exit;
      len := i;
    end;
    if want > len then return;
    obj_$free(chan, ptr, status);
  until status.all <> 0;
end;

{ free_string - give back what get_string mapped.

  cc.m68k 0x08AC40, 0x22 bytes: as SR10.2. }

procedure free_string(
    chan: integer;
    ptr: objutil_string_ptr_t;
    out status: status_$t); internal;
begin
  obj_$free(chan, ptr, status);
end;

{ extended_name_to_string - a COFF name, in storage of its own: the
  eight characters up to a NUL, or the string table's string.

  cc.m68k 0x08AC62, 0xC4 bytes: as SR10.2. }

procedure extended_name_to_string(
    chan: integer;
    strtab_off: linteger;
    strtab_size: linteger;
    in name: coff_$name_t;
    out str: objutil_string_ptr_t;
    out len: pinteger;
    out status: status_$t); internal;
var
  i: integer;
  p: objutil_string_ptr_t;
  copied: integer;
begin
  if name.zeroes <> 0 then begin
    str := rws_$alloc_heap(8);
    len := 0;
    for i := 1 to 8 do begin
      if ord(name.chars[i]) = 0 then exit;
      str^[i] := name.chars[i];
      len := i;
    end;
  end
  else begin
    get_string(chan, strtab_off, strtab_size, name.offset, p, len, status);
    if status.all = 0 then begin
      str := rws_$alloc_heap(len);
      strl_$copy(p^, len, str^, copied, len);
      free_string(chan, p, status);
    end;
  end;
end;

{ inlib_read_coff_inlib - read a COFF library: the libraries it names,
  its sections that define a global, its defined external symbols.

  cc.m68k 0x08AD2A, 0x57E bytes: as SR10.2. }

procedure inlib_read_coff_inlib(
    in chan: integer;
    in name: univ objutil_$string_t);
var
  offset: integer32;
  status: status_$t;
  hdr: coff_$filehdr_ptr_t;
  target: integer;
  nsyms: integer32;
  symptr: integer32;
  nscns: integer32;
  aout: coff_$aouthdr_ptr_t;
  inlib_ptr: integer32;
  strtab_off: linteger;
  strtab_size: linteger;
  count_ptr: ^integer32;
  count: integer32;
  i: integer;
  entry: coff_$inlib_entry_ptr_t;
  str: objutil_string_ptr_t;
  str_len: integer;
  scnoff: integer32;
  scn: coff_$scnhdr_ptr_t;
  s: objutil_sect_ptr_t;
  sym: coff_$syment_ptr_t;
  n: objutil_name_ptr_t;
begin
  offset := 0;
  hdr := obj_$get(chan, offset, coff_$filhsz, status);
  if status.all <> 0 then begin
    inlib_error_proc^(objutil_$skipped, 0, name, 'unable to read file' (0));
    obj_$free(chan, hdr, status);
    return;
  end;
  if hdr^.f_opthdr <> coff_$aout_size then begin
    inlib_error_proc^(objutil_$skipped, 0, name,
                      'wrong version of object format' (0));
    obj_$free(chan, hdr, status);
    return;
  end;
  target := object_target(hdr^.f_magic);
  if target = 0 then begin
    inlib_error_proc^(objutil_$skipped, 0, name, 'bad magic' (0));
    obj_$free(chan, hdr, status);
    return;
  end;
  if (hdr^.f_magic <> inlib_target) and (inlib_target <> 0) then
    inlib_error_proc^(objutil_$warning, 0, name,
                      'unexpected object target machine' (0));
  if not (coff_$f_pic in hdr^.f_flags) then
    inlib_error_proc^(objutil_$note, 0, name,
                      'file contains absolute code' (0));
  nsyms := hdr^.f_nsyms;
  symptr := hdr^.f_symptr; nscns := hdr^.f_nscns;
  obj_$free(chan, hdr, status);
  offset := coff_$filhsz;
  aout := obj_$get(chan, offset, coff_$aout_size, status);
  if status.all <> 0 then begin
    inlib_error_proc^(objutil_$skipped, 0, name, 'unable to read file' (0));
    obj_$free(chan, hdr, status);
    return;
  end;
  inlib_ptr := aout^.inlib_ptr;
  if aout^.magic <> aout_magics[target] then begin
    inlib_error_proc^(objutil_$skipped, 0, name,
                      'wrong version of object format' (0));
    return;
  end;
  obj_$free(chan, aout, status);
  get_coff_stringtab_info(chan, hdr, strtab_off, strtab_size, status);
  if status.all <> 0 then begin
    inlib_error_proc^(objutil_$skipped, 0, name, 'unable to read file' (0));
    obj_$free(chan, hdr, status);
    return;
  end;

  { The libraries it names. }
  if inlib_ptr <> 0 then begin
    count_ptr := obj_$get(chan, inlib_ptr, 4, status);
    if status.all <> 0 then begin
      inlib_error_proc^(objutil_$skipped, 0, name,
                        'unable to read file' (0));
      obj_$free(chan, count_ptr, status);
      return;
    end;
    count := count_ptr^;
    obj_$free(chan, count_ptr, status);
    inlib_ptr := inlib_ptr + 4;
    for i := 1 to count do begin
      entry := obj_$get(chan, inlib_ptr, sizeof(coff_$inlib_entry_t),
                        status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'unable to read file' (0));
        obj_$free(chan, entry, status);
        return;
      end;
      get_string(chan, strtab_off, strtab_size, entry^.name_ptr, str,
                 str_len, status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'unable to read file' (0));
        obj_$free(chan, entry, status);
        return;
      end;
      inlib_list_add(str, str_len);
      free_string(chan, str, status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'unable to read file' (0));
        obj_$free(chan, entry, status);
        return;
      end;
      obj_$free(chan, entry, status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'unable to read file' (0));
        obj_$free(chan, entry, status);
        return;
      end;
      inlib_ptr := inlib_ptr + sizeof(coff_$inlib_entry_t);
    end;
  end;

  { The sections that define a global. }
  scnoff := coff_$filhsz + coff_$aout_size;
  while nscns <> 0 do begin
    scn := obj_$get(chan, scnoff, coff_$scnhsz, status);
    if status.all <> 0 then begin
      inlib_error_proc^(objutil_$skipped, 0, name,
                        'unable to read file' (0));
      return;
    end;
    if coff_$styp_define in scn^.s_flags then begin
      s := rws_$alloc_heap(sizeof(objutil_sect_t));
      extended_name_to_string(chan, strtab_off, strtab_size, scn^.s_name,
                              s^.name, s^.len, status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'unable to read file' (0));
        obj_$free(chan, scn, status);
        return;
      end;
      s^.size := scn^.s_size;
      s^.next := sect_tail^.next;
      sect_tail^.next := s;
      sect_tail := s;
    end;
    obj_$free(chan, scn, status);
    scnoff := scnoff + coff_$scnhsz;
    nscns := nscns - 1;
  end;

  { The defined external symbols. }
  while nsyms <> 0 do begin
    sym := obj_$get(chan, symptr, coff_$symesz, status);
    if status.all <> 0 then begin
      inlib_error_proc^(objutil_$skipped, 0, name,
                        'unable to read file' (0));
      obj_$free(chan, entry, status);
      return;
    end;
    if (sym^.n_sclass = coff_$c_ext) and (sym^.n_scnum <> 0) and
       (sym^.n_value <> 0) then begin
      n := rws_$alloc_heap(sizeof(objutil_name_t));
      extended_name_to_string(chan, strtab_off, strtab_size, sym^.n_name,
                              n^.name, n^.len, status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'unable to read file' (0));
        obj_$free(chan, sym, status);
        return;
      end;
      n^.next := sym_tail^.next;
      sym_tail^.next := n;
      sym_tail := n;
    end;
    obj_$free(chan, sym, status);
    symptr := symptr + (sym^.n_numaux + 1) * coff_$symesz;
    nsyms := nsyms - (sym^.n_numaux + 1);
  end;
end;

{ inlib_read_obj_inlib - read an OBJ library: the libraries it names,
  its sections whose names are globals, its symbols not hidden and
  defined.

  cc.m68k 0x08C6C6, 0x41A bytes: as SR10.2. }

procedure inlib_read_obj_inlib(
    in chan: integer;
    in name: univ objutil_$string_t);
var
  status: status_$t;
  modoff: integer32;
  sectoff: integer32;
  symoff: integer32;
  nsyms: integer32;
  nsects: integer32;
  liboff: integer32;
  i: integer;
  j: integer;
  name32: obj_$name_t;
  len: integer32;
  s: objutil_sect_ptr_t;
  n: objutil_name_ptr_t;
begin
  objp := obj_$get(chan, 0, sizeof(obj_$file_hdr_t), status);
  if status.all <> 0 then begin
    inlib_error_proc^(objutil_$skipped, 0, name,
                      'cannot read header of inlibed file' (0));
    return;
  end;
  if (objp^.fhdr.kind <> obj_$kind_absolute) and
     (objp^.fhdr.kind <> obj_$kind_module) and
     (objp^.fhdr.kind <> obj_$kind_bkpts) then begin
    inlib_error_proc^(objutil_$warning, 0, name,
                      'file is not an object module' (0));
    return;
  end;
  if objp^.fhdr.mod_hdr <> 0 then begin
    modoff := objp^.fhdr.mod_hdr;
    sectoff := modoff + sizeof(obj_$mod_hdr_t);
    objp := obj_$get(chan, modoff, sizeof(obj_$mod_hdr_t), status);
    if status.all <> 0 then begin
      inlib_error_proc^(objutil_$skipped, 0, name,
                        'cannot read global info section' (0));
      return;
    end;
    symoff := objp^.mhdr.syms;
    nsyms := objp^.mhdr.sym_count;
    nsects := objp^.mhdr.sect_count;

    { The libraries it names. }
    if objp^.mhdr.lib_list <> 0 then begin
      liboff := objp^.mhdr.lib_list;
      objp := obj_$get(chan, liboff, sizeof(obj_$lib_list_t), status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'cannot read shared library info' (0));
        return;
      end;
      liboff := liboff + sizeof(obj_$lib_list_t);
      if objp^.libs.magic = obj_$lib_magic then
        for i := 1 to objp^.libs.count do begin
          lib_ent := obj_$get(chan, liboff, sizeof(obj_$lib_ent_t), status);
          if status.all <> 0 then begin
            inlib_error_proc^(objutil_$skipped, 0, name,
                              'cannot read shared library info' (0));
            exit;
          end;
          liboff := liboff + sizeof(obj_$lib_ent_t);
          objp := obj_$get(chan, liboff, lib_ent^.name_len, status);
          if status.all <> 0 then begin
            inlib_error_proc^(objutil_$skipped, 0, name,
                              'cannot read shared library info' (0));
            exit;
          end;
          liboff := liboff + lib_ent^.name_len;
          if odd(lib_ent^.name_len) then
            liboff := liboff + 1;
          inlib_list_add(addr(objp^.chars), lib_ent^.name_len);
        end;
    end;

    { The sections whose names are globals. }
    for i := 1 to nsects do begin
      objp := obj_$get(chan, sectoff, sizeof(obj_$sym_t), status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'cannot read secton table' (0));
        return;
      end;
      if obj_$sect_install in objp^.sect.flags then begin
        name32 := objp^.sect.name;
        s := rws_$alloc_heap(sizeof(objutil_sect_t));
        len := 32;
        for j := 1 to 32 do begin
          if name32[j] = ' ' then begin
            len := j - 1;
            exit;
          end;
          if name32[j] in ['a'..'z'] then
            name32[j] := chr(ord(name32[j]) - 32)
          else if name32[j] in ['A'..'Z'] then
            name32[j] := chr(ord(name32[j]) + 32);
        end;
        s^.name := rws_$alloc_heap(len);
        strl_$copy(name32, len, s^.name^, s^.len, len);
        s^.size := objp^.sect.size;
        s^.next := sect_tail^.next;
        sect_tail^.next := s;
        sect_tail := s;
      end;
      sectoff := sectoff + sizeof(obj_$sect_t);
    end;

    { The symbols not hidden and defined. }
    for i := 1 to nsyms do begin
      objp := obj_$get(chan, symoff, sizeof(obj_$sym_t), status);
      if status.all <> 0 then begin
        inlib_error_proc^(objutil_$skipped, 0, name,
                          'cannot read global table' (0));
        return;
      end;
      if not objp^.sym.hidden and (objp^.sym.section <> 0) then begin
        name32 := objp^.sym.name;
        n := rws_$alloc_heap(sizeof(objutil_name_t));
        len := 32;
        for j := 1 to 32 do begin
          if name32[j] = ' ' then begin
            len := j - 1;
            exit;
          end;
          if name32[j] in ['a'..'z'] then
            name32[j] := chr(ord(name32[j]) - 32)
          else if name32[j] in ['A'..'Z'] then
            name32[j] := chr(ord(name32[j]) + 32);
        end;
        n^.name := rws_$alloc_heap(len);
        strl_$copy(name32, len, n^.name^, n^.len, len);
        n^.next := sym_tail^.next;
        sym_tail^.next := n;
        sym_tail := n;
      end;
      symoff := symoff + sizeof(obj_$sym_t);
    end;
  end;
end;

{ inlib_read_inlib - open a library (in a compound executable, the part
  for the target) and read it as COFF or OBJ.  len counts the name's
  NUL.

  cc.m68k 0x08E310, 0x11E bytes: as SR10.2. }

procedure inlib_read_inlib(
    in name: univ objutil_$string_t;
    in len: integer);
var
  tag: obj_$string_t;
  tag_len: integer;
  chan: integer;
  status: status_$t;
  obj_len: integer32;
  type_uid: uid_$t;
begin
  if inlib_target = coff_$magic then
    strl_$copy('m68k', 4, tag, tag_len, 256)
  else if inlib_target = coff_$magic_a88k then
    strl_$copy('a88k', 4, tag, tag_len, 256)
  else begin
    tag := ' ';
    tag_len := 0;
  end;
  obj_$open_r_tag(chan, name, len - 1, tag, tag_len, obj_len, status);
  if status.all <> 0 then
    inlib_error_proc^(objutil_$warning, 0, name,
                      'cannot open referenced inlib file for reading' (0))
  else begin
    obj_$inq_type_uid(chan, type_uid);
    if type_uid = coff_$uid then
      inlib_read_coff_inlib(chan, name)
    else
      inlib_read_obj_inlib(chan, name);
    obj_$close(chan, status);
  end;
end;

{ objutil_$inlib_init - no libraries, no names read.

  cc.m68k 0x08E83A, 0x7C bytes: as SR10.2. }

procedure objutil_$inlib_init(
    in error_proc: objutil_$error_proc_t;
    in target: integer32);
begin
  lib_cursor := nil;
  lib_head := nil;
  lib_tail := nil;
  lib_count := 0;
  inlib_error_proc := error_proc;
  inlib_target := target;
  sym_tail := addr(sym_head);
  sym_head.next := nil;
  sym_head.len := 0;
  sect_tail := addr(sect_head);
  sect_head.next := nil;
  sect_head.len := 0;
  sect_head.size := 0;
end;

{ objutil_$inlib_libname - a library to read.

  cc.m68k 0x08E8B6, 0x2A bytes: as SR10.2. }

procedure objutil_$inlib_libname(
    in name: univ objutil_$string_t;
    in len: integer);
begin
  inlib_list_add(addr(name), len);
end;

{ objutil_$inlib_find_symbol - the libraries only.

  cc.m68k 0x08E8E0, 0x36 bytes: as SR10.2. }

function objutil_$inlib_find_symbol(
    in name: univ objutil_$string_t;
    in len: integer): boolean;
var
  kind: integer;
begin
  objutil_$inlib_find_symbol :=
    objutil_$inlib_lookup_symbol(name, len, [], kind);
end;

{ objutil_$inlib_lookup_symbol - the known global table first (with
  objutil_$lookup_kgt), then the globals read, reading the next library
  while the name is not among them.

  cc.m68k 0x08E976, 0xD0 bytes: as SR10.2. }

function objutil_$inlib_lookup_symbol(
    in name: univ objutil_$string_t;
    in len: integer;
    in opts: objutil_$lookup_opts_t;
    out kind: integer): boolean;
var
  kg_opts: loader_$kg_lookup_opts;
  last: objutil_name_ptr_t;
  address: univ_ptr;
  flags: loader_$sym_flags;

  { inlib_checklist - whether the globals read (after the last one
    checked) have the name.

    cc.m68k 0x08E916, 0x60 bytes: as SR10.2. }

  function inlib_checklist(
      in name: univ objutil_$string_t;
      len: integer): boolean;
  var
    p: objutil_name_ptr_t;
  begin
    if last <> nil then
      p := last
    else
      p := sym_head.next;
    while p <> nil do begin
      if strl_$eq(p^.name^, p^.len, name, len) then begin
        inlib_checklist := true;
        return;
      end;
      last := p;
      p := p^.next;
    end;
    inlib_checklist := false;
  end;

begin
  objutil_$inlib_lookup_symbol := true; kind := 0;
  kg_opts := [];
  last := nil;
  if objutil_$lookup_kgt in opts then begin
    if objutil_$lookup_data in opts then
      kg_opts := [loader_$kg_data_only]
    else if objutil_$lookup_function in opts then
      kg_opts := [loader_$kg_function_only];
    flags := loader_$kg_lookup(name, len, loader_$kg_symbol, kg_opts,
                               address);
    if loader_$sym_known in flags then begin
      if loader_$sym_function in flags then kind := objutil_$kind_function;
      if loader_$sym_data in flags then kind := objutil_$kind_data;
      return;
    end;
  end;
  while not inlib_checklist(name, len) do begin
    if lib_cursor = nil then begin
      objutil_$inlib_lookup_symbol := false;
      return;
    end;
    inlib_read_inlib(lib_cursor^.name^, lib_cursor^.len);
    lib_cursor := lib_cursor^.next;
  end;
end;

{ objutil_$inlib_find_section - the libraries only.

  cc.m68k 0x08EA4A, 0x30 bytes: as SR10.2. }

function objutil_$inlib_find_section(
    in name: univ objutil_$string_t;
    in len: integer;
    in size: integer32): boolean;
begin
  objutil_$inlib_find_section :=
    objutil_$inlib_lookup_section(name, len, size, []);
end;

{ objutil_$inlib_lookup_section - the known global table first (with
  objutil_$lookup_kgt), then the sections read, reading the next library
  while none of them is the name and at least size bytes long.

  cc.m68k 0x08EADC, 0x98 bytes: as SR10.2. }

function objutil_$inlib_lookup_section(
    in name: univ objutil_$string_t;
    in len: integer;
    in size: integer32;
    in opts: objutil_$lookup_opts_t): boolean;
var
  last: objutil_sect_ptr_t;
  address: univ_ptr;
  flags: loader_$sym_flags;

  { inlib_checklist - whether the sections read (after the last one
    checked) have the name, at least size bytes long.

    cc.m68k 0x08EA7A, 0x62 bytes: as SR10.2. }

  function inlib_checklist(
      in name: univ objutil_$string_t;
      len: integer;
      size: integer32): boolean;
  var
    p: objutil_sect_ptr_t;
  begin
    if last <> nil then
      p := last
    else
      p := sect_head.next;
    while p <> nil do begin
      if strl_$eq(p^.name^, p^.len, name, len) and (size <= p^.size) then
      begin
        inlib_checklist := true;
        return;
      end;
      last := p;
      p := p^.next;
    end;
    inlib_checklist := false;
  end;

begin
  objutil_$inlib_lookup_section := true;
  if objutil_$lookup_kgt in opts then begin
    flags := loader_$kg_lookup(name, len, size, [], address);
    if [loader_$sym_known, loader_$sym_section] <= flags then return;
  end;
  last := nil;
  while not inlib_checklist(name, len, size) do begin
    if lib_cursor = nil then begin
      objutil_$inlib_lookup_section := false;
      return;
    end;
    inlib_read_inlib(lib_cursor^.name^, lib_cursor^.len);
    lib_cursor := lib_cursor^.next;
  end;
end;

{ objutil_$inlib_terminate - give back the libraries' entries, and the
  globals' and sections' entries and names.

  cc.m68k 0x08EB74, 0xC2 bytes: as SR10.2. }

procedure objutil_$inlib_terminate;
var
  p: objutil_lib_ptr_t;
  st: status_$t;
  n, n2: objutil_name_ptr_t;
  s, s2: objutil_sect_ptr_t;
begin
  lib_cursor := nil;
  while lib_head <> nil do begin
    p := lib_head;
    lib_head := lib_head^.next;
    rws_$release_heap(p, st);
  end;
  if sym_head.next <> nil then begin
    n := sym_head.next;
    while n <> nil do begin
      n2 := n;
      n := n^.next;
      rws_$release_heap(n2^.name, st);
      rws_$release_heap(n2, st);
    end;
  end;
  if sect_head.next <> nil then begin
    s := sect_head.next;
    while s <> nil do begin
      s2 := s;
      s := s^.next;
      rws_$release_heap(s2^.name, st);
      rws_$release_heap(s2, st);
    end;
  end;
end;
