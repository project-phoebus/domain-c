{ objio - OBJ_, the binder's object file I/O: object files are opened as
  channels and read and written by mapping the parts asked for; a file
  written under a name that exists is kept apart until it is closed.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x088028  0x089A08  check_init
    0x0880A8  0x089A88  obj_$remove_free
    0x088122  0x089B02  delete_free_list_entry
    0x08816C  0x089B4C  obj_$add_free
    0x0881C4  0x089BA4  obj_$init_io
    0x0882A4  0x089C84  obj_$validate_object_module
    0x0883EA  0x089DCA  obj_$get_my_obj_info
    0x08888C  0x08A26C  make_chan
    0x088966  0x08A346  find_chan
    0x0889DE  0x08A3BE  map_portion
    0x088B50  0x08A530  make_bak_name
    0x088BD4  0x08A5B4  obj_$put
    0x088DFC  0x08A7DC  obj_$inq_type_uid
    0x088E3E  0x08A81E  obj_$inq_ts
    0x088F2A  0x08A90A  obj_$inq_unix_ts
    0x089010  0x08A9F0  obj_$open
    0x089178  0x08AB58  num_to_hex (in create_temp_file)
    0x089198  0x08AB78  create_temp_file
    0x089270  0x08AC50  copy_the_sucker
    0x089332  0x08AD12  copy_back
    0x0893D2  0x08ADB2  obj_$open_w
    0x0894C8  0x08AEA8  obj_$open_wl
    0x08966E  0x08B04E  obj_$open_t
    0x089AB4  0x08B494  obj_$open_r_tag
    0x089C7E  0x08B65E  obj_$open_r
    0x089E96  0x08B876  obj_$close
    0x08A11E  0x08BAFE  obj_$free
    0x08A1CA  0x08BBAA  obj_$get
    0x08A3BC  0x08BD9C  obj_$get_name
    0x08A46E  0x08BE4E  obj_$map
    0x08A550  0x08BF30  obj_$set_length
    0x08A59A  0x08BF7A  search_apollo_section_tables
    0x08A746  0x08C126  search_apollo_global_tables
    0x08A8F0  0x08C2D0  objio_cleanup_handler
    A5 0x18E788 (cc.m68k), 0x30E7F8 (cc.a88k): the module's data
    (+1504 the copy buffer, 32 KB, addressed absolutely); the cells below
    A5 hold the addresses of the externals the module reads (pas_$output,
    uid_$nil, the type UIDs).

  This is the source repository's translation of the SR10.2 /com/bind
  objio (com/bind/objio.pas, whose SR10.2 addresses follow), changed
  where DOMAIN C 6.9's (compiled by Pascal Rev 8.89, with Apollo's
  internal inserts) differs; each routine's header names its cc.m68k
  address and what differs from SR10.2.  The differences:
  - the window's alignment and size are no longer the constants 32 KB
    and 192 KB: obj_$init_io sets them from SEG_SIZE (page_size, +1436)
    and page_size + 160 KB (window_size, +1440), which SR10.2's data had
    as two unused longwords; obj_$put, obj_$get and map_portion use them;
  - two more longwords follow (+1444, +1448, unused), so every later
    cell lies 8 bytes higher than in SR10.2; the zeros of temp_chan,
    free_count, last_chan, put_chan, get_chan and initialized are
    initialized data (.rwdi);
  - a channel takes 2104 bytes (rws_$alloc_rw, 0x088962), not 2102;
  - make_chan clears a channel's windows (maps), not its length.
  The rest is Rev 8.89 code generation (docs/rev889-patterns.md).

  SR10.2:
    sr10.2  PROCEDURE$+0x0D61C  check_init
    sr10.2  PROCEDURE$+0x0D698  obj_$remove_free
    sr10.2  PROCEDURE$+0x0D708  delete_free_list_entry
    sr10.2  PROCEDURE$+0x0D750  obj_$add_free
    sr10.2  PROCEDURE$+0x0D798  obj_$init_io
    sr10.2  PROCEDURE$+0x0D830  obj_$validate_object_module
    sr10.2  PROCEDURE$+0x0D968  obj_$get_my_obj_info
    sr10.2  PROCEDURE$+0x0DDF4  make_chan
    sr10.2  PROCEDURE$+0x0DEC2  find_chan
    sr10.2  PROCEDURE$+0x0DF3A  map_portion
    sr10.2  PROCEDURE$+0x0E0AA  make_bak_name
    sr10.2  PROCEDURE$+0x0E12E  obj_$put
    sr10.2  PROCEDURE$+0x0E328  obj_$inq_type_uid
    sr10.2  PROCEDURE$+0x0E35E  obj_$inq_ts
    sr10.2  PROCEDURE$+0x0E454  obj_$inq_unix_ts
    sr10.2  PROCEDURE$+0x0E546  obj_$open
    sr10.2  PROCEDURE$+0x0E6A2  num_to_hex (in create_temp_file)
    sr10.2  PROCEDURE$+0x0E6C8  create_temp_file
    sr10.2  PROCEDURE$+0x0E796  copy_the_sucker
    sr10.2  PROCEDURE$+0x0E84E  copy_back
    sr10.2  PROCEDURE$+0x0E8E4  obj_$open_w
    sr10.2  PROCEDURE$+0x0E9CC  obj_$open_wl
    sr10.2  PROCEDURE$+0x0EB66  obj_$open_t
    sr10.2  PROCEDURE$+0x0EF96  obj_$open_r_tag
    sr10.2  PROCEDURE$+0x0F150  obj_$open_r
    sr10.2  PROCEDURE$+0x0F360  obj_$close
    sr10.2  PROCEDURE$+0x0F5D6  obj_$free
    sr10.2  PROCEDURE$+0x0F67A  obj_$get
    sr10.2  PROCEDURE$+0x0F858  obj_$get_name
    sr10.2  PROCEDURE$+0x0F908  obj_$map
    sr10.2  PROCEDURE$+0x0F9E2  obj_$set_length
    sr10.2  PROCEDURE$+0x0FA2A  search_apollo_section_tables
    sr10.2  PROCEDURE$+0x0FBC6  search_apollo_global_tables
    sr10.2  PROCEDURE$+0x0FD58  objio_cleanup_handler
    sr10.2  DATA$+0x05470       the module's data (0x85D8 bytes)

  - A channel is a number: those of the files opened to write count up
    from 1 (four at a time), those of the files opened to read from 5;
    the first 100 are a table, the others hang off its entries.
  - What is read or written is mapped in windows of 192 KB that start
    on a 32 KB boundary of the file, each mapped once and counted; the
    last ten windows given back stay mapped on a free list until they
    are needed again or pushed off it.
  - An OBJ file (type object_file_$uid) is mapped after its 32-byte
    Aegis header; a COFF file from its start, with a header of its own
    in storage.  In a compound executable the part with the tag is
    used.
  - A file that cannot be written in place (its name is a link the file
    system will not resolve) is written to a temporary file and copied
    back when it is closed.
}
module objio;

%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/pfm.ins.pas';
%include 'us/us/ins/time.ins.pas';
%include 'us/us/ins/file.ins.pas';
%include 'us/us/ins/vol.ins.pas';
%include 'us/us/ins/term.ins.pas';
%include 'us/us/ins/streams.ins.pas';
%include 'us/us/ins/ios.ins.pas';
%include '/sys/ins/ios.ins.pas';
%include 'us/us/ins/ios_nr.ins.pas';
%include 'us/us/ins/prot.ins.pas';
%include '/sys/ins/mutex.ins.pas';
%include 'us/us/ins/rws.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include 'us/us/ins/ms.ins.pas';
%include 'us/us/ins/pgm.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include 'us/us/ins/mst.ins.pas';
%include 'us/us/ins/error.ins.pas';
%include '/sys/ins/error.ins.pas';
%include 'us/us/ins/name.ins.pas';
%include 'us/us/ins/name.pvt.pas';
%include 'misc_server/misc1/ios/mgrs/dfile/stream_bypass.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'misc_server/clib/ins/unix_time.ins.pas';
%include 'us/us/ins/strl.ins.pas';
%include 'us/us/ins/coff.ins.pas';
%include 'us/us/ins/cmpexe.ins.pas';
%include 'us/us/ins/uid_list.ins.pas';
%include '/sys/ins/type_uids.ins.pas';
%include 'us/us/ins/vfmt.ins.pas';
%include '/sys/ins/vfmt.ins.pas';

{ SEG_SIZE (lang2/source/lt_utils/source/seg_size.pas, which has no
  insert): the system's segment size. }
function seg_size: integer32; extern;

const
  objio_max_chans = 100;                { the channel table }
  objio_max_write = 4;                  { files open to write at once }
  objio_first_read = 5;                 { the first channel to read }
  objio_free_max = 10;                  { windows kept on the free list }
  objio_window_extra = 163840;          { a window's size past
                                          page_size (SR10.2: the window
                                          16#30000, the page 32768) }
  objio_put_max = 163808;               { the most one get or put maps }
  objio_map_all = 4194304;              { what obj_$map maps }
  objio_aegis_hdr_size = 32;
  objio_buf_size = 32768;               { copy_the_sucker's buffer }

  { objio_chan_t.mode }
  objio_closed = 0;
  objio_read = 1;
  objio_write = 2;

type
  { The Aegis header an OBJ file starts with; a COFF channel has one in
    storage, which gets the length. }
  objio_aegis_hdr_t = record            { 32 bytes }
    hdr_len: integer;                   { +0: 32 }
    version: integer;                   { +2: 1 }
    check: integer32;                   { +4 }
    unused_8: integer32;                { +8 }
    eof: linteger;                      { +12: the file's length }
    flags: packed record                { +16 }
      bits_7_6: 0..3;
      rec_type: 0..3;                   { 2 }
      bit_3: boolean;
      bits_2_0: 0..7;
    end;
    unused_17: array[17..31] of char;   { +17 }
  end;
  objio_aegis_hdr_ptr_t = ^objio_aegis_hdr_t;

  { A window of a file. }
  objio_map_ptr_t = ^objio_map_t;
  objio_map_t = record                  { 32 bytes }
    va: univ_ptr;                       { +0: where it is mapped }
    va_len: linteger;                   { +4 }
    in_use: boolean;                    { +8: mapped }
    unused_9: char;                     { +9 }
    unused_10: integer;                 { +10 }
    file_off: linteger;                 { +12: its offset in the file }
    refs: integer;                      { +16: the gets and puts on it }
    chan_no: pinteger;                  { +18 }
    next_map: objio_map_ptr_t;          { +20: the channel's windows }
    free_next: objio_map_ptr_t;         { +24: the free list }
    free_prev: objio_map_ptr_t;         { +28 }
  end;

  { A channel. }
  objio_chan_ptr_t = ^objio_chan_t;
  objio_chan_t = record                 { 2102 bytes }
    uid: uid_$t;                        { +0: the object's }
    type_uid: uid_$t;                   { +8 }
    hdr: objio_aegis_hdr_ptr_t;         { +16 }
    skip: integer;                      { +20: 32 (OBJ), or 0 }
    unused_22: integer;                 { +22 }
    base: integer32;                    { +24: the part, in a compound
                                          executable }
    obj_len: linteger;                  { +28 }
    strid: ios_$id_t;                   { +32 }
    mode: integer;                      { +34 }
    number: pinteger;                   { +36: the channel's }
    unused_38: integer;                 { +38 }
    maps: objio_map_ptr_t;              { +40 }
    next_chan: objio_chan_ptr_t;        { +44: channels past 100 }
    fname_len: integer;                 { +48 }
    fname: obj_$pname_t;                { +50: the name opened }
    temp: boolean;                      { +1074: written to a temporary
                                          file }
    path: obj_$pname_t;                 { +1075: the temporary file's }
    path_len: integer;                  { +2100 }
    unused_2102: integer;               { +2102: cc's channel is 2104
                                          bytes (SR10.2: 2102); nothing
                                          reads it }
  end;

  { What search_apollo_section_tables and search_apollo_global_tables
    map. }
  objio_obj_t = record
    case integer of
      1: (fhdr: obj_$file_hdr_t);
      2: (mhdr: obj_$mod_hdr_t);
      3: (sect: obj_$sect_t);
      4: (sym: obj_$sym_t);
  end;
  objio_obj_ptr_t = ^objio_obj_t;

  { What obj_$get_my_obj_info maps: a .mir section, or a name. }
  objio_mapped_t = record
    case integer of
      1: (count: integer32;
          mirs: coff_$mir_t);
      2: (chars: array[1..32] of char);
  end;
  objio_mapped_ptr_t = ^objio_mapped_t;

{ The module's data, in its order (A5+offset, cc's; SR10.2's from +1444
  on lie 8 bytes lower). }
var
  bak_path: obj_$pname_t;               { +0: obj_$open_t's renamed file }
  chans: array[1..objio_max_chans] of objio_chan_ptr_t;  { +1024 }
  tmp_count: linteger;                  { +1424: the temporary files' }
  chain_tail: objio_chan_ptr_t;         { +1428 }
  saved_last_p: objio_chan_ptr_t;       { +1432 }
  page_size: integer32;                 { +1436: where windows start
                                          (SEG_SIZE) }
  window_size: integer32;               { +1440: a window's size }
  unused_1444: integer32;               { +1444 }
  unused_1448: integer32;               { +1448 }
  free_tail: objio_map_ptr_t;           { +1452: the free list's ends }
  free_head: objio_map_ptr_t;           { +1456 }
  last_p: objio_chan_ptr_t;             { +1460: find_chan's last }
  put_p: objio_chan_ptr_t;              { +1464 }
  get_p: objio_chan_ptr_t;              { +1468 }
  bak_path_len: integer;                { +1472 }
  saved_last_chan: pinteger;            { +1474 }
  temp_chan: pinteger := 0;             { +1476: obj_$open_t's channel }
  gpath_form: integer;                  { +1478 }
  free_count: pinteger := 0;            { +1480 }
  last_chan: pinteger := 0;             { +1482 }
  put_chan: pinteger := 0;              { +1484 }
  get_chan: pinteger := 0;              { +1486 }
  next_write: pinteger := 1;            { +1488 }
  next_read: pinteger := objio_first_read;  { +1490 }
  initialized: boolean := false;        { +1492 }
  unused_1493: char;                    { +1493 }
  bak_made: boolean;                    { +1494 }
  unused_1495: char;                    { +1495 }
  sect_p: objio_obj_ptr_t;              { +1496 }
  glob_p: objio_obj_ptr_t;              { +1500 }
  buf: array[1..objio_buf_size] of char;  { +1504 }

procedure objio_cleanup_handler(
    in arg1: univ_ptr;
    in arg2: univ_ptr;
    in arg3: univ_ptr;
    in arg4: univ_ptr); forward;

{ check_init - stop the program if obj_$init_io was not called.

  cc.m68k 0x088028, 0x52 bytes: as SR10.2 (PAS_$WRITE and PAS_$WRITELN on
  the output at (-4,A5); dpc refuses writeln, docs/dpc-gaps.md 4). }

procedure check_init;
var
  status: status_$t;
begin
  if not initialized then begin
    writeln('Fatal Error! objio has not been initialized!');
    status.all := 16#80000004;
    pfm_$signal(status);
  end;
end;

{ obj_$remove_free - take a window off the free list.

  cc.m68k 0x0880A8, 0x7A bytes: as SR10.2. }

procedure obj_$remove_free(
    var m: objio_map_ptr_t;
    out status: status_$t); internal;
begin
  check_init;
  if free_count <> 0 then
    free_count := free_count - 1
  else
    free_count := 0;
  if free_head^.free_next = free_tail then
    free_tail^.free_prev := free_head
  else if (m^.free_next <> nil) and (m^.free_prev <> nil) then
    with m^ do begin
      free_next^.free_prev := free_prev;
      free_prev^.free_next := free_next;
      free_next := nil; free_prev := nil;
    end;
  status.all := status_$ok;
end;

{ delete_free_list_entry - unmap the first window of the free list and
  take it off.

  cc.m68k 0x088122, 0x4A bytes: as SR10.2. }

procedure delete_free_list_entry(
    out status: status_$t); internal;
var
  m: objio_map_ptr_t;
begin
  m := free_head^.free_next;
  m^.in_use := false;
  ms_$unmap(m^.va, m^.va_len, status);
  m^.va := nil;
  m^.refs := 0;
  obj_$remove_free(free_head^.free_next, status);
end;

{ obj_$add_free - put a window no longer used at the end of the free
  list, pushing the first one off when the list is full.

  cc.m68k 0x08816C, 0x58 bytes: as SR10.2. }

procedure obj_$add_free(
    var m: objio_map_ptr_t;
    out status: status_$t); internal;
begin
  check_init;
  if free_count >= objio_free_max then
    delete_free_list_entry(status);
  free_tail^.free_prev^.free_next := m;
  m^.free_prev := free_tail^.free_prev;
  free_tail^.free_prev := m;
  m^.free_next := free_tail;
  free_count := free_count + 1;
end;

{ obj_$init_io - start the module.

  cc.m68k 0x0881C4, 0xD8 bytes: as SR10.2, then page_size := SEG_SIZE
  (`jsr seg_size', 0x088280) and window_size := page_size + 163840
  (`addi.l #163840', 0x08828A), which SR10.2 does not have. }

procedure obj_$init_io;
var
  status: status_$t;
begin
  initialized := true;
  pfm_$static_cleanup(addr(objio_cleanup_handler), status);
  if status.all <> status_$ok then
    pfm_$signal(status);
  next_read := objio_first_read;
  next_write := 1;
  get_chan := 0;
  get_p := nil;
  put_chan := 0;
  put_p := nil;
  last_chan := 0;
  last_p := nil;
  free_head := rws_$alloc_rw(sizeof(objio_map_t));
  free_tail := rws_$alloc_rw(sizeof(objio_map_t));
  free_head^.free_next := free_tail;
  free_tail^.free_prev := free_head;
  free_head^.free_prev := nil;
  free_tail^.free_next := nil;
  free_count := 0;
  temp_chan := 0;
  page_size := seg_size;
  window_size := page_size + objio_window_extra;
end;

{ obj_$validate_object_module - whether a file is, or can be written
  as, an object file.

  cc.m68k 0x0882A4, 0x13E bytes: as SR10.2. }

procedure obj_$validate_object_module(
    in name: univ obj_$pname_t;
    in name_len: integer;
    in uid: uid_$t;
    out status: status_$t);
var
  strid: ios_$id_t;
  magic: integer;
  attr: file_$attr_t;
  n: integer32;
begin
  if uid <> uid_$nil then begin
    file_$attributes(uid, attr, status);
    status.fail := false;
    if (status.all <> status_$ok) and
       (status.all <> name_$file_not_directory) then
      return;
  end
  else
    attr.type_uid := unstruct_$uid;
  if (attr.type_uid = coff_$uid) or (attr.type_uid = object_file_$uid) or
     (attr.type_uid = cmpexe_$uid) then
    return;
  if attr.type_uid = unstruct_$uid then begin
    strid := ios_$open(name, name_len, [], status);
    if status.all <> status_$ok then return;
    n := ios_$get(strid, [ios_$no_rec_bndry_opt], magic, 2, status);
    if (status.all <> status_$ok) or (n <> 2) then
      status.fail := true
    else if (magic <> coff_$magic) and (magic <> coff_$magic_a88k) then begin
      ios_$close(strid, status);
      status.all := obj_$not_an_object;
      return;
    end;
    ios_$close(strid, status);
    return;
  end;
  status.all := obj_$not_an_object;
end;

{ obj_$get_my_obj_info - the running program's module name, version and
  time, from the object file it was loaded from (in a compound
  executable, the m68k part): a COFF file's module name from its .mir
  section, its optional header's version stamp and its file header's
  time; an OBJ file's module header's.

  cc.m68k 0x0883EA, 0x474 bytes: as SR10.2. }

procedure obj_$get_my_obj_info(
    in key: integer;
    out name: univ obj_$name_t;
    out version: integer;
    out time: integer32;
    out failed: boolean);
label
  done;
const
  text_marker = 'Something in .text';
var
  st: status_$t;
  va: univ_ptr;
  uid: uid_$t;
  offset: integer32;
  attr: file_$attr_t;
  base: integer32;
  part_len: integer32;
  part_type: uid_$t;
  file_va: univ_ptr;
  hdr_len: linteger;
  coff: coff_$filehdr_ptr_t;
  obj: obj_$file_hdr_ptr_t;
  aout: coff_$aouthdr_ptr_t;
  name_off: integer32;
  scns: coff_$scnhdr_ptr_t;
  scn: coff_$scnhdr_ptr_t;
  len: linteger;
  p: objio_mapped_ptr_t;
  mir_len: linteger;
  mir: coff_$mir_ptr_t;
  count: integer32;
  i: integer32;
  j: integer32;
  k: integer32;
  mhdr: obj_$mod_hdr_ptr_t;
  v: record
    case integer of
      1: (major: char;
          minor: char);
      2: (word: integer);
  end;
  clock: time_$clock_t;
  tv: unix_time_$timeval_t;
begin
  va := addr(text_marker); base := 0;
  mst_$get_uid(va, uid, offset, st);
  if st.all <> status_$ok then begin
    failed := true;
    return;
  end;

  file_$attributes(uid, attr, st);
  if st.all <> status_$ok then return;
  if attr.type_uid = cmpexe_$uid then begin
    cmpexe_$find_by_tag_uid(uid, 'm68k', 4, base, part_len, part_type,
                            st);
    if st.all <> status_$ok then return;
  end;
  file_va := ms_$mapl_uid(uid, base, 32768, ms_$conc_mode_t(2), ms_$r,
                          false, hdr_len, st);
  if st.all <> status_$ok then begin
    failed := true;
    return;
  end;
  coff := file_va; obj := univ_ptr(integer32(file_va) + objio_aegis_hdr_size);

  if (coff^.f_magic = coff_$magic) or (coff^.f_magic = coff_$magic_a88k)
  then begin
    name_off := 0;
    name := '????????????????????????????????';
    time := coff^.f_timdat;
    aout := univ_ptr(integer32(coff) + coff_$filhsz);
    version := aout^.vstamp;
    scns := ms_$mapl_uid(uid, coff^.f_opthdr + base + coff_$filhsz,
                         coff^.f_nscns * coff_$scnhsz, ms_$conc_mode_t(2),
                         ms_$r, false, len, st);
    if st.all <> status_$ok then begin
      failed := true;
      goto done;
    end;
    scn := scns; for i := 1 to coff^.f_nscns do begin
      if strl_$eq(scn^.s_name, 4, '.mir', 4) then begin
        p := ms_$mapl_uid(uid, base + scn^.s_scnptr, scn^.s_size,
                          ms_$conc_mode_t(2), ms_$r, false, mir_len, st);
        if st.all <> status_$ok then begin
          failed := true;
          ms_$unmap(coff, len, st);
          goto done;
        end;
        count := p^.count; mir := addr(p^.mirs);
        for j := 1 to count do
          if mir^.kind <> coff_$module_name_mir_kind then
            mir := univ_ptr(integer32(mir) + mir^.mir_size)
          else
            name_off := mir^.module_name_offset;
        exit;
      end;
      scn := univ_ptr(integer32(scn) + coff_$scnhsz);
    end;
    ms_$unmap(scns, len, st);
    ms_$unmap(p, mir_len, st);
    if name_off > 0 then begin
      p := ms_$mapl_uid(uid, name_off + base + coff^.f_symptr +
                        coff^.f_nsyms * coff_$symesz, 4096,
                        ms_$conc_mode_t(2), ms_$r, false, len, st);
      if st.all <> status_$ok then begin
        failed := true;
        goto done;
      end;
      for i := 1 to 32 do
        if p^.chars[i] <> chr(0) then
          name[i] := p^.chars[i]
        else begin
          for k := i to 32 do
            name[k] := ' ';
          ms_$unmap(p, len, st);
          goto done;
        end;
      ms_$unmap(p, len, st);
    end;
    failed := false;
  end

  else begin
    if linteger(obj) + objio_aegis_hdr_size > linteger(file_va) + hdr_len
    then begin
      failed := true;
      goto done;
    end;
    if not ((obj^.kind in [obj_$kind_module, obj_$kind_bkpts,
                           obj_$kind_absolute]) and
            ((obj^.version = 3) or (obj^.version = 2))) then begin
      failed := true;
      goto done;
    end;
    mhdr := univ_ptr(integer32(obj) + obj^.mod_hdr); len := 0;
    if linteger(mhdr) + sizeof(obj_$mod_hdr_t) > hdr_len then begin
      mhdr := ms_$mapl_uid(uid, base + obj^.mod_hdr + objio_aegis_hdr_size,
                           sizeof(obj_$mod_hdr_t), ms_$conc_mode_t(2),
                           ms_$r, false, len, st);
      if st.all <> status_$ok then begin
        failed := true;
        goto done;
      end;
    end;
    name := mhdr^.name;
    v.minor := chr(mhdr^.version_minor);
    v.major := chr(mhdr^.version_major);
    version := v.word;
    clock.high := mhdr^.time;
    clock.low := 0;
    unix_time_$clock_to_timeval(1, clock, tv);
    time := tv.sec;
    failed := false;
    if len <> 0 then begin
      ms_$unmap(mhdr, len, st);
      st.all := status_$ok;
    end;
  end;

done:
  ms_$unmap(file_va, hdr_len, st);
end;

{ make_chan - a new channel: the next to write (four at most) or to
  read; the caller counts it.

  cc.m68k 0x08888C, 0xD6 bytes: rws_$alloc_rw of 2104 bytes (the constant
  at 0x088962; SR10.2 2102); `clr.l (40,A0)' (0x0888E6): maps := nil
  where SR10.2 cleared obj_len (+28). }

function make_chan(
    write: boolean;
    out status: status_$t): objio_chan_ptr_t; internal;
var
  n: pinteger;
  p: objio_chan_ptr_t;
  q: objio_chan_ptr_t;
begin
  status.all := status_$ok;
  if write then begin
    if next_write > objio_max_write then begin
      status.all := obj_$too_many_channels;
      return;
    end;
    n := next_write;
  end
  else
    n := next_read;
  p := rws_$alloc_rw(sizeof(objio_chan_t));
  if p = nil then begin
    status.all := obj_$no_rw_storage;
    return;
  end;
  with p^ do begin
    mode := objio_closed;
    number := n;
    maps := nil;
    base := 0;
    temp := false;
  end;
  if n <= objio_max_chans then
    chans[n] := p
  else begin
    q := chans[(n - 1) mod objio_max_chans + 1];
    while q^.next_chan <> nil do
      q := q^.next_chan;
    chain_tail := q;
    saved_last_chan := last_chan;
    saved_last_p := last_p;
    q^.next_chan := p;
    last_chan := n;
    last_p := p;
  end;
  make_chan := p;
end;

{ find_chan - the channel of a number.

  cc.m68k 0x088966, 0x78 bytes: as SR10.2. }

function find_chan(
    chan: pinteger;
    out status: status_$t): objio_chan_ptr_t; internal;
var
  p: objio_chan_ptr_t;
begin
  status.all := status_$ok;
  if chan = 0 then
    status.all := obj_$bad_channel
  else if chan <= objio_max_chans then
    find_chan := chans[chan]
  else if chan = last_chan then begin
    find_chan := last_p;
    return;
  end
  else begin
    p := chans[(chan - 1) mod objio_max_chans + 1]^.next_chan;
    while p^.number <> chan do
      p := p^.next_chan;
    last_chan := chan;
    last_p := p;
    find_chan := p;
  end;
end;

{ map_portion - map a window of a channel's file from offset (want: its
  length, 0 for whatever is there), without a lock to write.  To read,
  a file another process has locked is mapped without a lock if the
  channel is one to write; the first window gives the file's header
  address.

  cc.m68k 0x0889DE, 0x172 bytes: both mappings ask for window_size - skip
  (`move.l (1440,A5)', 0x088A46 and 0x088AAE) where SR10.2 asked for
  16#30000 - skip. }

procedure map_portion(
    offset: linteger;
    want: linteger;
    in uid: uid_$t;
    var map: objio_map_ptr_t;
    out base: objio_aegis_hdr_ptr_t;
    write: boolean;
    out status: status_$t); internal;
var
  c: objio_chan_ptr_t;
  conc: ms_$conc_mode_t;
  access: ms_$acc_mode_t;
  mapped: linteger;
begin
  with map^ do begin
    c := find_chan(chan_no, status);
    if status.all <> status_$ok then return;

    if write then begin
      conc := ms_$conc_mode_t(2);
      access := ms_$wr;
    end
    else begin
      conc := ms_$nr_xor_1w;
      access := ms_$r;
    end;
    va := ms_$mapl_uid(uid, c^.skip + offset + c^.base,
                       window_size - c^.skip, conc, access, write, mapped,
                       status);

    if (status.all = ms_$in_use) and not write and
       (c^.mode = objio_write) then begin
      conc := ms_$conc_mode_t(2);
      access := ms_$wr;
      va := ms_$mapl_uid(uid, c^.skip + offset + c^.base,
                         window_size - c^.skip, conc, access, write,
                         mapped, status);
    end;

    if not write and (file_off = 0) then begin
      base := va;
      base := univ_ptr(integer32(base) - c^.skip);
    end;
    in_use := true;
    refs := 1;
    free_next := nil; free_prev := nil;
    if (want = 0) or (want = mapped) then
      va_len := mapped
    else if status.all = status_$ok then
      status.all := obj_$outside_file;
    if (va = nil) or (status.all <> status_$ok) then begin
      in_use := false;
      refs := 0;
      if status.all = ms_$no_space then
        status.all := obj_$no_rw_storage;
    end;
  end;
end;

{ make_bak_name - a pathname with .bak added to its leaf (whose last
  characters it replaces past 28).

  cc.m68k 0x088B50, 0x84 bytes: as SR10.2. }

procedure make_bak_name(
    in name: univ obj_$pname_t;
    len: pinteger;
    leaf_len: pinteger;
    out bak: univ obj_$pname_t;
    out bak_len: integer); internal;
var
  i: pinteger;
  j: pinteger;
begin
  for i := 1 to len do
    bak[i] := name[i];
  if leaf_len > 28 then
    j := len - leaf_len + 29
  else
    j := len + 1;
  bak[j] := '.';
  j := j + 1;
  bak[j] := 'b';
  j := j + 1;
  bak[j] := 'a';
  j := j + 1;
  bak[j] := 'k';
  bak_len := j;
end;

{ obj_$put - map len bytes of a file opened to write, from offset; the
  file's length grows to cover them.

  cc.m68k 0x088BD4, 0x228 bytes: start := (offset div page_size) *
  page_size (M$DIU$LLL and M$MIU$LLL by (1436,A5), 0x088CF6) where
  SR10.2 divided by 32768 (shifts).  Rev 8.89 shares the tails of the
  window's cases (0x088D98) and passes searching's register for the
  constant true (0x088D74). }

function obj_$put(
    in chan: pinteger;
    in offset: linteger;
    in len: linteger;
    out status: status_$t): univ_ptr;
var
  searching: boolean;
  p: objio_chan_ptr_t;
  m: objio_map_ptr_t;
  old: objio_map_ptr_t;
  start: linteger;
  last: linteger;
begin
  check_init;
  status.all := status_$ok;
  searching := true; if len > objio_put_max then begin
    status.all := obj_$outside_file;
    return;
  end;
  if put_chan <> chan then
    p := find_chan(chan, status)
  else
    p := put_p;
  if status.all <> status_$ok then return;
  with p^ do begin
    if mode <> objio_write then begin
      status.all := obj_$not_open_for_write;
      return;
    end;
    status.all := status_$ok;

    if (maps = nil) or (offset + len > maps^.va_len + maps^.file_off) or
       (offset < maps^.file_off) then begin
      m := maps;
      while searching and (m <> nil) do
        with m^ do
          if (offset + len <= file_off + va_len) and (offset >= file_off)
          then
            searching := false
          else
            m := next_map;

      if m = nil then begin
        old := maps;
        maps := rws_$alloc_rw(sizeof(objio_map_t));
        if maps = nil then begin
          status.all := obj_$no_rw_storage;
          return;
        end;
        m := maps; maps^.chan_no := chan;
        maps^.next_map := old;
        start := (offset div page_size) * page_size;
        maps^.file_off := start;
        map_portion(start, 0, uid, maps, hdr, true, status);
        if status.all <> status_$ok then return;
      end
      else
        with m^ do
          if not in_use then begin
            map_portion(file_off, va_len, uid, m, hdr, true, status);
            if status.all <> status_$ok then return;
          end
          else begin
            refs := refs + 1;
            if refs = 1 then
              obj_$remove_free(m, status);
          end;
    end

    else
      with maps^ do begin
        m := maps;
        if not in_use then begin
          map_portion(file_off, va_len, uid, maps, hdr, true, status);
          if status.all <> status_$ok then return;
        end
        else begin
          refs := refs + 1;
          if refs = 1 then
            obj_$remove_free(m, status);
        end;
      end;

    last := offset + len + skip;
    if last > hdr^.eof then begin
      hdr^.eof := last;
      obj_len := last - skip;
    end;
    with m^ do
      obj_$put := univ_ptr(integer32(va) + offset - file_off);
  end;
end;

{ obj_$inq_type_uid - the type of a channel's file.

  cc.m68k 0x088DFC, 0x42 bytes: as SR10.2. }

procedure obj_$inq_type_uid(
    in chan: pinteger;
    out type_uid: uid_$t);
var
  status: status_$t;
  p: objio_chan_ptr_t;
begin
  check_init;
  p := find_chan(chan, status);
  type_uid := p^.type_uid;
end;

{ obj_$inq_ts - an object file's time, as the high 32 bits of the
  Apollo clock.

  cc.m68k 0x088E3E, 0xE4 bytes: as SR10.2. }

function obj_$inq_ts(in chan: pinteger): integer32;
var
  type_uid: uid_$t;
  status: status_$t;
  fhdr: obj_$file_hdr_ptr_t;
  mhdr: obj_$mod_hdr_ptr_t;
  coff: coff_$filehdr_ptr_t;
  tv: unix_time_$timeval_t;
  clock: time_$clock_t;
  ts: integer32;
begin
  check_init;
  obj_$inq_type_uid(chan, type_uid);
  if type_uid = object_file_$uid then begin
    fhdr := obj_$get(chan, 0, sizeof(obj_$file_hdr_t), status);
    mhdr := obj_$get(chan, fhdr^.mod_hdr, sizeof(obj_$mod_hdr_t), status);
    obj_$free(chan, fhdr, status);
    ts := mhdr^.time;
    obj_$free(chan, mhdr, status);
  end
  else begin
    coff := obj_$get(chan, 0, coff_$filhsz, status);
    tv.sec := coff^.f_timdat;
    tv.usec := 0;
    unix_time_$timeval_to_clock(1, tv, clock);
    ts := clock.high;
    obj_$free(chan, coff, status);
  end;
  obj_$inq_ts := ts;
end;

{ obj_$inq_unix_ts - an object file's time, in Unix seconds.

  cc.m68k 0x088F2A, 0xE6 bytes: as SR10.2. }

function obj_$inq_unix_ts(in chan: pinteger): integer32;
var
  type_uid: uid_$t;
  status: status_$t;
  fhdr: obj_$file_hdr_ptr_t;
  mhdr: obj_$mod_hdr_ptr_t;
  coff: coff_$filehdr_ptr_t;
  tv: unix_time_$timeval_t;
  clock: time_$clock_t;
  ts: integer32;
begin
  check_init;
  obj_$inq_type_uid(chan, type_uid);
  if type_uid = object_file_$uid then begin
    fhdr := obj_$get(chan, 0, sizeof(obj_$file_hdr_t), status);
    mhdr := obj_$get(chan, fhdr^.mod_hdr, sizeof(obj_$mod_hdr_t), status);
    obj_$free(chan, fhdr, status);
    clock.high := mhdr^.time;
    clock.low := 0;
    unix_time_$clock_to_timeval(1, clock, tv);
    ts := tv.sec;
    obj_$free(chan, mhdr, status);
  end
  else begin
    coff := obj_$get(chan, 0, coff_$filhsz, status);
    ts := coff^.f_timdat;
    obj_$free(chan, coff, status);
  end;
  obj_$inq_unix_ts := ts;
end;

{ obj_$open - finish opening a channel to write on its stream: its
  object, its type, its header; the next channel to write is its.

  cc.m68k 0x089010, 0x162 bytes: as SR10.2. }

procedure obj_$open(
    p: objio_chan_ptr_t;
    out chan: pinteger;
    out status: status_$t); internal;
label
  error;
var
  len: linteger;
  junk: univ_ptr;
begin
  check_init;
  if p^.temp then begin
    ios_$inq_path_name(p^.strid, ios_$root_name, p^.path, p^.path_len,
                       status);
    if status.all <> status_$ok then goto error;
  end;
  ios_$inq_obj_uid(p^.strid, p^.uid, status);
  if status.all <> status_$ok then goto error;
  ios_$inq_type_uid(p^.strid, p^.type_uid, status);
  if status.all <> status_$ok then goto error;

  if p^.type_uid <> object_file_$uid then begin
    p^.hdr := rws_$alloc_rw(sizeof(objio_aegis_hdr_t));
    p^.skip := 0;
  end
  else
    p^.skip := objio_aegis_hdr_size;
  if p^.type_uid = object_file_$uid then begin
    p^.skip := objio_aegis_hdr_size;
    p^.hdr := ms_$mapl_uid(p^.uid, 0, p^.skip, ms_$conc_mode_t(2), ms_$wr,
                           true, len, status);
  end;
  with p^.hdr^ do begin
    unused_8 := 0; eof := 0;
    flags.rec_type := 2;
    flags.bit_3 := false;
  end;

  chan := next_write;
  put_chan := next_write;
  put_p := p;
  p^.mode := objio_write;
  p^.next_chan := nil;
  junk := obj_$put(p^.number, 0, 10, status);
  return;

error:
  chans[next_write] := nil;
end;

{ create_temp_file - create a new temporary file to write,
  /tmp/obj<8 hex digits>.tmp.

  cc.m68k 0x089198, 0xC2 bytes: as SR10.2. }

function create_temp_file: ios_$id_t;
var
  name: name_$pname_t;
  i: integer;
  strid: ios_$id_t;
  status: status_$t;

  { num_to_hex - a hexadecimal digit.

    cc.m68k 0x089178, 0x20 bytes: as SR10.2; no frame (a leaf that reads its
    parameters at (4,SP) and (8,SP): docs/rev889-patterns.md 16). }

  procedure num_to_hex(
      out c: char;
      n: integer);
  begin
    if n < 10 then
      c := chr(n + ord('0'))
    else
      c := chr(n + 55);
  end;

begin
  name := '/tmp/obj%%%%%%%%.tmp';
  repeat
    for i := 1 to 8 do
      num_to_hex(name[i + 8], rshft(tmp_count, (8 - i) * 4) & 16#F);
    ios_$create(name, 20, unstruct_$uid, ios_$no_pre_exist_mode,
                [ios_$write_opt], strid, status);
    if status.all = ios_$already_exists then
      tmp_count := tmp_count + 1
    else if status.all <> status_$ok then
      pfm_$signal(status);
  until status.all = status_$ok;
  create_temp_file := strid;
end;

{ copy_the_sucker - copy one stream to another, to its end.

  cc.m68k 0x089270, 0xC2 bytes: as SR10.2; the buffer (+1504) is addressed
  absolutely (`pea 0x18ED68': docs/rev889-patterns.md 20). }

procedure copy_the_sucker(
    from_strid: ios_$id_t;
    to_strid: ios_$id_t);
var
  n: integer32;
  status: status_$t;
begin
  n := ios_$get(from_strid, [ios_$no_rec_bndry_opt], buf, objio_buf_size,
                status);
  if status.all = status_$ok then
    repeat
      ios_$put(to_strid, [ios_$partial_record_opt], buf, n, status);
      if status.all <> status_$ok then
        pfm_$signal(status);
      n := ios_$get(from_strid, [ios_$no_rec_bndry_opt], buf,
                    objio_buf_size, status);
    until status.all <> status_$ok;
  if status.all <> ios_$end_of_file then
    pfm_$signal(status);
end;

{ copy_back - copy an object (by its UID) to a stream.

  cc.m68k 0x089332, 0x9E bytes: as SR10.2. }

procedure copy_back(
    uid: uid_$t;
    strid: ios_$id_t);
var
  path: name_$long_pname_t;
  len: integer;
  status: status_$t;
  s: ios_$id_t;
begin
  name_$gpath_lc(uid, 4, 1023, path, len, status);
  if status.all <> status_$ok then
    pfm_$signal(status);
  s := ios_$open(path, len, [ios_$write_opt], status);
  copy_the_sucker(s, strid);
  ios_$close(s, status);
end;

{ obj_$open_w - create an object file, truncating one of the name, and
  open it to write.

  cc.m68k 0x0893D2, 0xF4 bytes: as SR10.2. }

procedure obj_$open_w(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    out status: status_$t);
var
  p: objio_chan_ptr_t;
  i: pinteger;
begin
  check_init;
  chan := 0;
  p := make_chan(true, status);
  if status.all <> status_$ok then return;
  with p^ do begin
    ios_$create(name, name_len, coff_$uid, ios_$truncate_mode,
                [ios_$write_opt], strid, status);
    if status.all <> status_$ok then begin
      chans[next_write] := nil;
      return;
    end;

    for i := 1 to name_len do
      fname[i] := name[i];
    fname_len := name_len;
    name_$resolve(name, name_len, uid, status);
    if status.all = name_$file_not_directory then begin
      temp := true;
      ios_$close(strid, status);
      strid := create_temp_file;
    end;
    obj_$open(p, chan, status);
    if status.all <> status_$ok then begin
      chans[next_write] := nil;
      return;
    end;
    next_write := next_write + 1;
  end;
end;

{ obj_$open_wl - open an object file to write, creating it if there is
  none (existed false).

  cc.m68k 0x0894C8, 0x1A6 bytes: as SR10.2. }

procedure obj_$open_wl(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    out existed: boolean;
    out status: status_$t);
var
  attr: file_$attr_t;
  p: objio_chan_ptr_t;
  s: ios_$id_t;
  i: pinteger;
begin
  check_init;
  existed := false;
  chan := 0;
  p := make_chan(true, status);
  if status.all <> status_$ok then return;
  with p^ do begin
    s := ios_$open(name, name_len, [], status);
    if status.all = ios_$name_not_found then begin
      ios_$create(name, name_len, coff_$uid, ios_$no_pre_exist_mode,
                  [ios_$unregulated_opt], strid, status);
      existed := false;
    end
    else if status.all <> status_$ok then begin
      chans[next_write] := nil;
      return;
    end
    else begin
      strid := ios_$open(name, name_len, [ios_$unregulated_opt], status);
      existed := true;
    end;
    if status.all <> status_$ok then begin
      chans[next_write] := nil;
      return;
    end;

    for i := 1 to name_len do
      fname[i] := name[i];
    fname_len := name_len;
    name_$resolve(name, name_len, uid, status);
    if status.all = name_$file_not_directory then begin
      ios_$close(strid, status);
      strid := create_temp_file;
      temp := true;
      if existed then begin
        copy_the_sucker(s, strid);
        ios_$close(s, status);
      end;
    end;
    obj_$open(p, chan, status);
    if existed then begin
      file_$attributes(uid, attr, status);
      hdr^.eof := attr.cur_len;
      p^.obj_len := attr.cur_len;
    end;
    ios_$close(strid, status);
    if status.all <> status_$ok then begin
      chans[next_write] := nil;
      return;
    end;
    next_write := next_write + 1;
  end;
end;

{ obj_$open_t - open a new object file to write.  A file of the name
  that is not in use is renamed .bak (and deleted at the close); the new
  file has no name until it is closed.

  cc.m68k 0x08966E, 0x444 bytes: as SR10.2; Rev 8.89 shares the two
  branches' tail (ios_$change_path_name, obj_$open: 0x089A3C). }

procedure obj_$open_t(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    out status: status_$t);
label
  restore, fail;
var
  p: objio_chan_ptr_t;
  old_uid: uid_$t;
  lock: file_$lock_user_t;
  s: ios_$id_t;
  s2: ios_$id_t;
  st2: status_$t;
  saved: boolean;
  leaf: obj_$pname_t;
  leaf_len: integer;
  full_len: integer;
  bak: obj_$pname_t;
  bak_len: integer;
  i: pinteger;
begin
  check_init;
  chan := 0;
  p := make_chan(true, status);
  if status.all <> status_$ok then return;
  if temp_chan <> 0 then begin
    status.all := obj_$temp_file_open;
    goto restore;
  end;

  with p^ do begin
    for i := 1 to name_len do
      fname[i] := name[i];
    fname_len := name_len;
    bak_made := false;
    name_$resolve(name, name_len, old_uid, status);
    if status.all <> status_$ok then begin
      old_uid := uid_$nil;
      if status.all = name_$file_not_directory then
        p^.temp := true;
    end;
    s := ios_$open(name, name_len, [ios_$inquire_only_opt], status);
    ios_$close(s, st2);

    if status.all = status_$ok then begin
      { The file exists: rename it .bak. }
      bak_made := true;
      obj_$validate_object_module(name, name_len, old_uid, status);
      if status.all <> status_$ok then goto fail;
      status.all := status_$ok;
      if old_uid <> uid_$nil then
        file_$read_lock_entryu(old_uid, lock, status)
      else
        status.all := file_$object_not_locked_by_this_process;
      if status.all <> file_$object_not_locked_by_this_process then begin
        if status.all <> status_$ok then goto restore;
        status.all := file_$object_in_use;
        goto restore;
      end;
      status.all := status_$ok;

      s := ios_$open(name, name_len, [], status);
      if status.all <> status_$ok then
        pfm_$signal(status);
      ios_$inq_path_name(s, ios_$root_name, fname, fname_len, status);
      if status.all <> status_$ok then goto restore;
      saved := name_$force_mixcase(true);
      ios_$inq_path_name(s, ios_$leaf_name, leaf, leaf_len, status);
      ios_$inq_path_name(s, ios_$root_name, leaf, full_len, status);
      if status.all <> status_$ok then goto restore;
      make_bak_name(leaf, full_len, leaf_len, bak, bak_len);
      ios_$change_path_name(s, bak, bak_len, status);
      if status.all <> status_$ok then begin
        { A .bak of the name already: delete it first. }
        status.fail := false;
        if (status.all <> name_$already_exists) and
           (status.all <> ios_$already_exists) then
          goto restore;
        s2 := ios_$open(bak, bak_len, [ios_$write_opt], status);
        if status.all <> status_$ok then goto restore;
        ios_$delete(s2, status);
        if status.all <> status_$ok then goto restore;
        ios_$change_path_name(s, bak, bak_len, status);
        if status.all <> status_$ok then goto restore;
      end;
      ios_$inq_path_name(s, ios_$root_name, bak_path, bak_path_len, status);
      if status.all <> status_$ok then goto restore;
      ios_$close(s, status);

      ios_$create(name, name_len, coff_$uid, ios_$no_pre_exist_mode,
                  [ios_$unregulated_opt], strid, status);
      if status.all <> status_$ok then goto restore;
      if temp then begin
        ios_$close(strid, status);
        strid := create_temp_file;
      end
      else begin
        name_$resolve(name, name_len, uid, status);
        if status.all <> status_$ok then goto restore;
      end;
      if not temp then begin
        ios_$change_path_name(strid, name, 0, status);
        if status.all <> status_$ok then goto restore;
      end;
    end

    else if status.all = ios_$name_not_found then begin
      bak_made := false;
      status.all := status_$ok;
      saved := name_$force_mixcase(false);
      discard(name_$force_mixcase(saved));
      ios_$create(name, name_len, coff_$uid, ios_$no_pre_exist_mode,
                  [ios_$unregulated_opt], strid, status);
      if status.all <> status_$ok then goto restore;
      name_$resolve(name, name_len, uid, status);
      if status.all = name_$file_not_directory then
        temp := true
      else if status.all <> status_$ok then
        goto restore;
      ios_$inq_path_name(strid, ios_$root_name, fname, fname_len, status);
      if status.all <> status_$ok then goto restore;
      if temp then begin
        ios_$close(strid, status);
        strid := create_temp_file;
      end
      else begin
        ios_$change_path_name(strid, name, 0, status);
        if status.all <> status_$ok then goto restore;
      end;
    end

    else
      goto fail;

    obj_$open(p, chan, status);
    if status.all <> status_$ok then goto restore;
    temp_chan := chan;
    next_write := next_write + 1;
    status.all := status_$ok;
    discard(name_$force_mixcase(saved));
    return;
  end;

restore:
  discard(name_$force_mixcase(saved));
fail:
  chans[next_write] := nil;
  temp_chan := 0;
end;

{ obj_$open_r_tag - open an object file to read; in a compound
  executable, the part with the tag.

  cc.m68k 0x089AB4, 0x1C8 bytes: as SR10.2; Rev 8.89 computes (n - 1) mod
  100 with M$OIU$WLW (unsigned: a pinteger). }

procedure obj_$open_r_tag(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    in tag: univ obj_$string_t;
    in tag_len: integer;
    out len: integer32;
    out status: status_$t);
label
  error;
var
  p: objio_chan_ptr_t;
  tag_buf: obj_$string_t;
  tag_buf_len: integer;
  attr: file_$attr_t;
  part_len: integer32;
  i: pinteger;
begin
  check_init;
  if tag_len <> 0 then
    strl_$copy(tag, tag_len, tag_buf, tag_buf_len, 256)
  else
    strl_$copy('m68k', 4, tag_buf, tag_buf_len, 256);
  chan := 0;
  p := make_chan(false, status);
  if status.all <> status_$ok then return;

  with p^ do begin
    mode := objio_read;
    get_chan := next_read;
    get_p := p;
    chan := next_read;
    next_chan := nil;
    for i := 1 to name_len do
      fname[i] := name[i];
    fname_len := name_len;
    name_$resolve(name, name_len, uid, status);
    if status.all <> status_$ok then goto error;
    file_$attributes(uid, attr, status);
    if attr.type_uid = cmpexe_$uid then begin
      cmpexe_$find_by_tag_uid(uid, tag_buf, tag_buf_len, base, part_len,
                              type_uid, status);
      if status.all <> status_$ok then goto error;
    end
    else begin
      type_uid := attr.type_uid;
      part_len := attr.cur_len;
    end;
    if type_uid = object_file_$uid then
      skip := objio_aegis_hdr_size
    else
      skip := 0;
    len := part_len - skip;
    obj_len := len;

    next_read := next_read + 1;
    if (next_read > objio_max_chans) and
       ((next_read - 1) mod objio_max_chans + 1 = 1) then
      next_read := next_read + objio_max_write;
    return;

  error:
    if number > objio_max_chans then begin
      last_chan := saved_last_chan;
      last_p := saved_last_p;
      chain_tail^.next_chan := nil;
    end;
  end;
end;

{ obj_$open_r - open an object file to read.

  cc.m68k 0x089C7E, 0x218 bytes: as SR10.2; Rev 8.89 computes (n - 1) mod
  100 with M$OIU$WLW (unsigned: a pinteger). }

procedure obj_$open_r(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    out len: integer32;
    out status: status_$t);
label
  error;
var
  p: objio_chan_ptr_t;
  s: ios_$id_t;
  i: pinteger;
begin
  check_init;
  chan := 0;
  p := make_chan(false, status);
  if status.all <> status_$ok then return;

  with p^ do begin
    mode := objio_read;
    get_chan := next_read;
    get_p := p;
    chan := next_read;
    next_chan := nil;
    for i := 1 to name_len do
      fname[i] := name[i];
    fname_len := name_len;
    s := ios_$open(name, name_len, [], status);
    if status.all <> status_$ok then goto error;
    name_$resolve(name, name_len, uid, status);
    if status.all = name_$file_not_directory then begin
      uid := uid_$nil;
      temp := true;
    end;
    ios_$inq_type_uid(s, type_uid, status);
    if status.all <> status_$ok then
      pfm_$signal(status);
    if type_uid = object_file_$uid then
      skip := objio_aegis_hdr_size
    else
      skip := 0;
    len := ios_$inq_byte_pos(s, ios_$eof, status) - skip;
    obj_len := len;

    if temp then begin
      strid := create_temp_file;
      copy_the_sucker(s, strid);
      ios_$inq_path_name(strid, ios_$root_name, path, path_len, status);
      if status.all <> status_$ok then return;
      ios_$close(s, status);
    end
    else
      strid := s;
    ios_$inq_obj_uid(strid, uid, status);
    if status.all <> status_$ok then return;
    ios_$close(strid, status);

    next_read := next_read + 1;
    if (next_read > objio_max_chans) and
       ((next_read - 1) mod objio_max_chans + 1 = 1) then
      next_read := next_read + objio_max_write;
    return;

  error:
    if number > objio_max_chans then begin
      last_chan := saved_last_chan;
      last_p := saved_last_p;
      chain_tail^.next_chan := nil;
    end;
  end;
end;

{ obj_$close - close a channel.  A file written gets its length; under
  obj_$open_t it gets its name and the .bak is deleted; a temporary file
  is copied back and deleted.

  cc.m68k 0x089E96, 0x288 bytes: as SR10.2. }

procedure obj_$close(
    in chan: pinteger;
    out status: status_$t);
label
  unmap_all;
var
  p: objio_chan_ptr_t;
  m: objio_map_ptr_t;
  st: status_$t;
  old_strid: ios_$id_t;
  s: ios_$id_t;
  saved: boolean;
begin
  check_init;
  status.all := status_$ok;
  if chan <= objio_max_chans then
    p := chans[chan]
  else begin
    p := find_chan(chan, status);
    if status.all <> status_$ok then return;
  end;

  with p^ do begin
    if mode = objio_closed then return;

    if (temp_chan <> 0) and (temp_chan = chan) then begin
      temp_chan := 0;
      st.all := status_$ok;
      old_strid := strid;
      if not temp then begin
        saved := name_$force_mixcase(true);
        ios_$change_path_name(strid, fname, fname_len, status);
        if status.all = ios_$cant_set_prot then
          status.all := status_$ok;
        if status.all <> status_$ok then begin
          discard(name_$force_mixcase(saved));
          goto unmap_all;
        end;
      end;
      if bak_made then begin
        s := ios_$open(bak_path, bak_path_len, [ios_$write_opt], status);
        if status.all <> status_$ok then goto unmap_all;
        ios_$delete(s, status);
        if status.all <> status_$ok then goto unmap_all;
      end;
      discard(name_$force_mixcase(saved));
    end;

    while maps <> nil do begin
      m := maps;
      if m^.in_use then
        ms_$unmap(m^.va, m^.va_len, status);
      m^.va := nil;
      if m^.free_next <> nil then
        obj_$remove_free(maps, status);
      maps := m^.next_map;
    end;

    if mode = objio_write then begin
      next_write := chan;
      file_$set_len(uid, hdr^.eof, status);
      ios_$set_obj_flag(strid, ios_$of_ascii, false, status);
      ios_$close(strid, status);
      if status.all <> status_$ok then return;
      if temp then begin
        s := ios_$open(fname, fname_len, [ios_$write_opt], status);
        if status.all <> status_$ok then
          pfm_$signal(status);
        copy_back(uid, s);
        ios_$close(s, status);
      end;
    end;
    if temp then begin
      s := ios_$open(path, path_len, [ios_$write_opt], status);
      if status.all <> status_$ok then
        pfm_$signal(status);
      ios_$delete(s, status);
      if status.all <> status_$ok then
        pfm_$signal(status);
    end;
    mode := objio_closed;
    return;

  unmap_all:
    while maps <> nil do begin
      m := maps;
      if m^.in_use then
        ms_$unmap(m^.va, m^.va_len, st);
      m^.va := nil;
      if m^.free_next <> nil then
        obj_$remove_free(maps, st);
      maps := m^.next_map;
    end;
  end;
end;

{ obj_$free - give back what obj_$get or obj_$put mapped: the window
  holding the address (the channel's last if none), on the free list
  when nothing else uses it.

  cc.m68k 0x08A11E, 0xAC bytes: as SR10.2. }

procedure obj_$free(
    in chan: pinteger;
    in ptr: univ_ptr;
    out status: status_$t);
var
  p: objio_chan_ptr_t;
  m: objio_map_ptr_t;
begin
  check_init;
  status.all := status_$ok;
  if get_chan = chan then
    p := get_p
  else if put_chan = chan then
    p := put_p
  else
    p := find_chan(chan, status);
  if status.all <> status_$ok then return;

  m := p^.maps;
  while m^.next_map <> nil do begin
    if (linteger(ptr) >= linteger(m^.va)) and
       (integer32(m^.va) + m^.va_len - 1 >= integer32(ptr)) then
      exit;
    m := m^.next_map;
  end;
  with m^ do begin
    refs := refs - 1;
    if (refs = 0) and (free_next = nil) then begin
      obj_$add_free(m, status);
      refs := 0;
    end;
  end;
end;

{ obj_$get - map len bytes of a file from offset (less at its end).

  cc.m68k 0x08A1CA, 0x1F2 bytes: start := (offset div page_size) *
  page_size (M$DIU$LLL and M$MIU$LLL by (1436,A5)) where SR10.2 divided
  by 32768 (shifts). }

function obj_$get(
    in chan: pinteger;
    in offset: linteger;
    in len: linteger;
    out status: status_$t): univ_ptr;
var
  searching: boolean;
  p: objio_chan_ptr_t;
  m: objio_map_ptr_t;
  old: objio_map_ptr_t;
  start: linteger;
  n: linteger;
begin
  check_init;
  status.all := status_$ok;
  searching := true;
  if get_chan <> chan then
    p := find_chan(chan, status)
  else
    p := get_p;
  if status.all <> status_$ok then return;
  with p^ do begin
    if (len > objio_put_max) or (offset > obj_len) then begin
      status.all := obj_$outside_file;
      return;
    end;
    status.all := status_$ok;
    if offset + len > obj_len then
      n := obj_len - offset
    else
      n := len;

    if (maps = nil) or (n + offset > maps^.va_len + maps^.file_off) or
       (offset < maps^.file_off) then begin
      m := maps;
      while searching and (m <> nil) do
        with m^ do
          if (n + offset <= file_off + va_len) and (offset >= file_off)
          then
            searching := false
          else
            m := next_map;

      if m = nil then begin
        old := maps;
        maps := rws_$alloc_rw(sizeof(objio_map_t));
        if maps = nil then begin
          status.all := obj_$no_rw_storage;
          return;
        end;
        m := maps; maps^.chan_no := chan;
        maps^.next_map := old;
        start := (offset div page_size) * page_size;
        maps^.file_off := start;
        map_portion(start, 0, uid, maps, hdr, false, status);
        if status.all <> status_$ok then return;
      end
      else
        with m^ do
          if not in_use then begin
            map_portion(file_off, va_len, uid, m, hdr, false, status);
            if status.all <> status_$ok then return;
          end
          else begin
            refs := refs + 1;
            if refs = 1 then
              obj_$remove_free(m, status);
          end;
    end

    else
      with maps^ do begin
        m := maps;
        if not in_use then begin
          map_portion(file_off, va_len, uid, maps, hdr, false, status);
          if status.all <> status_$ok then return;
        end
        else begin
          refs := refs + 1;
          if refs = 1 then
            obj_$remove_free(m, status);
        end;
      end;

    with m^ do
      obj_$get := univ_ptr(integer32(va) + offset - file_off);
  end;
end;

{ obj_$get_name - the pathname of a channel's file.

  cc.m68k 0x08A3BC, 0xB0 bytes: as SR10.2. }

procedure obj_$get_name(
    in chan: pinteger;
    out name: univ obj_$pname_t;
    out name_len: integer;
    out status: status_$t);
var
  p: objio_chan_ptr_t;
  s: ios_$id_t;
begin
  check_init;
  status.all := status_$ok;
  p := find_chan(chan, status);
  if status.all <> status_$ok then return;
  with p^ do
    if mode = objio_closed then
      status.all := obj_$channel_not_open
    else begin
      gpath_form := 1;
      if not temp then
        name_$gpath_lc(uid, gpath_form, 1024, name, name_len, status)
      else begin
        s := ios_$open(fname, fname_len, [ios_$inquire_only_opt], status);
        if status.all <> status_$ok then
          pfm_$signal(status);
        ios_$inq_path_name(s, ios_$wdir_name, name, name_len, status);
      end;
    end;
end;

{ obj_$map - map a channel's file whole (4 MB of it) to write.

  cc.m68k 0x08A46E, 0xE2 bytes: as SR10.2. }

function obj_$map(
    in chan: pinteger;
    out len: linteger;
    out status: status_$t): univ_ptr;
var
  p: objio_chan_ptr_t;
begin
  check_init;
  status.all := status_$ok;
  p := find_chan(chan, status);
  if status.all <> status_$ok then return;
  with p^ do begin
    maps := rws_$alloc_rw(sizeof(objio_map_t));
    if maps = nil then begin
      status.all := obj_$no_rw_storage;
      return;
    end;
    with maps^ do begin
      va := ms_$mapl_uid(uid, skip, objio_map_all - skip, ms_$conc_mode_t(2),
                         ms_$wr, true, va_len, status);
      if va = nil then begin
        error_$print(status);
        status.all := obj_$no_rw_storage;
        return;
      end;
      hdr := univ_ptr(integer32(hdr) - skip);
      in_use := true;
      chan_no := number;
      next_map := nil;
      free_next := nil; free_prev := nil;
      file_off := 0; refs := 1;
      obj_$map := va;
    end;
    len := maps^.va_len;
  end;
end;

{ obj_$set_length - the length a file written gets at its close.

  cc.m68k 0x08A550, 0x4A bytes: as SR10.2. }

procedure obj_$set_length(
    in chan: pinteger;
    in len: integer32;
    out status: status_$t);
var
  p: objio_chan_ptr_t;
begin
  check_init;
  status.all := status_$ok;
  p := find_chan(chan, status);
  if status.all <> status_$ok then return;
  p^.hdr^.eof := p^.skip + len;
end;

{ search_apollo_section_tables - whether an OBJ file has a section, its
  name a global, of the name.

  cc.m68k 0x08A59A, 0x1A0 bytes: as SR10.2. }

function search_apollo_section_tables(
    in chan: pinteger;
    in file_name: univ obj_$pname_t;
    in file_name_len: integer;
    in name: univ obj_$name_t;
    in name_len: integer): boolean;
var
  status: status_$t;
  off: integer32;
  n: integer32;
  i: integer;
  j: integer;
  nm: obj_$name_t;
  nm_len: integer32;
begin
  search_apollo_section_tables := true;
  sect_p := obj_$get(chan, 0, sizeof(obj_$file_hdr_t), status);
  if status.all <> status_$ok then begin
    error_$std_format(status, '"%LA"%$', file_name, file_name_len);
    pgm_$set_severity(pgm_$output_invalid);
    pgm_$exit;
  end;
  off := sect_p^.fhdr.mod_hdr;
  sect_p := obj_$get(chan, off, sizeof(obj_$mod_hdr_t), status);
  if status.all <> status_$ok then begin
    error_$std_format(status, '"%LA"%$', file_name, file_name_len);
    pgm_$set_severity(pgm_$output_invalid);
    pgm_$exit;
  end;
  off := off + sizeof(obj_$mod_hdr_t); n := sect_p^.mhdr.sect_count;
  for i := 1 to n do begin
    sect_p := obj_$get(chan, off, sizeof(obj_$sect_t), status);
    if status.all <> status_$ok then begin
      error_$std_format(status, '"%LA"%$', file_name, file_name_len);
      pgm_$set_severity(pgm_$output_invalid);
      pgm_$exit;
    end;
    if obj_$sect_install in sect_p^.sect.flags then begin
      nm := sect_p^.sect.name;
      for j := 1 to 32 do begin
        nm_len := j;
        if nm[j] = ' ' then begin
          nm_len := nm_len - 1;
          exit;
        end;
      end;
      if strl_$eq(name, name_len, nm, nm_len) then return;
    end;
    off := off + sizeof(obj_$sect_t);
  end;
  search_apollo_section_tables := false;
end;

{ search_apollo_global_tables - whether an OBJ file defines a global
  symbol, not hidden, of the name.

  cc.m68k 0x08A746, 0x1A6 bytes: as SR10.2. }

function search_apollo_global_tables(
    in chan: pinteger;
    in file_name: univ obj_$pname_t;
    in file_name_len: integer;
    in name: univ obj_$name_t;
    in name_len: integer): boolean;
var
  status: status_$t;
  mod_off: integer32;
  off: integer32;
  n: integer32;
  i: integer;
  j: integer;
  nm: obj_$name_t;
  nm_len: integer32;
begin
  search_apollo_global_tables := true;
  glob_p := obj_$get(chan, 0, sizeof(obj_$file_hdr_t), status);
  if status.all <> status_$ok then begin
    error_$std_format(status, '"%LA"%$', file_name, file_name_len);
    pgm_$set_severity(pgm_$output_invalid);
    pgm_$exit;
  end;
  mod_off := glob_p^.fhdr.mod_hdr;
  glob_p := obj_$get(chan, mod_off, sizeof(obj_$mod_hdr_t), status);
  if status.all <> status_$ok then begin
    error_$std_format(status, '"%LA"%$', file_name, file_name_len);
    pgm_$set_severity(pgm_$output_invalid);
    pgm_$exit;
  end;
  off := glob_p^.mhdr.syms;
  n := glob_p^.mhdr.sym_count;
  for i := 1 to n do begin
    glob_p := obj_$get(chan, off, sizeof(obj_$sym_t), status);
    if status.all <> status_$ok then begin
      error_$std_format(status, '"%LA"%$', file_name, file_name_len);
      pgm_$set_severity(pgm_$output_invalid);
      pgm_$exit;
    end;
    if not glob_p^.sym.hidden then
      if glob_p^.sym.section <> 0 then begin
        nm := glob_p^.sym.name;
        for j := 1 to 32 do begin
          nm_len := j;
          if nm[j] = ' ' then begin
            nm_len := nm_len - 1;
            exit;
          end;
        end;
        if strl_$eq(name, name_len, nm, nm_len) then return;
      end;
    off := off + sizeof(obj_$sym_t);
  end;
  search_apollo_global_tables := false;
end;

{ objio_cleanup_handler - when the program ends: unmap every channel's
  windows and delete its temporary file.

  cc.m68k 0x08A8F0, 0xF6 bytes: as SR10.2. }

procedure objio_cleanup_handler;
var
  st: status_$t;
  i: integer;
  p: objio_chan_ptr_t;
  m: objio_map_ptr_t;
  s: ios_$id_t;
begin
  st.all := status_$ok;
  for i := 1 to objio_max_chans do begin
    p := chans[i];
    while p <> nil do begin
      with p^ do
        if mode <> objio_closed then begin
          while maps <> nil do begin
            m := maps;
            if m^.in_use then
              ms_$unmap(m^.va, m^.va_len, st);
            m^.va := nil;
            if m^.free_next <> nil then
              obj_$remove_free(maps, st);
            maps := m^.next_map;
          end;
          if temp then begin
            ios_$close(strid, st);
            s := ios_$open(path, path_len, [ios_$write_opt], st);
            if st.all <> status_$ok then
              error_$print(st);
            ios_$delete(s, st);
            if st.all <> status_$ok then
              error_$print(st);
          end;
        end;
      p := p^.next_chan;
    end;
  end;
end;
