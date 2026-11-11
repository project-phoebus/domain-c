{ iosub - IOSUB, the compilers' files: starting the compilation
  (iosub_$init_all: the memory pools, the options, the processor's
  properties; iosub_$init_io: the source, listing, object and library
  files named from the source name and the options), reading the source
  and writing the listing and the library, mapping the object file
  through OBJ_, the terminal, the include files, and closing everything
  at the end.

  Image addresses (DOMAIN C 6.9):
    cc.m68k   cc.a88k
    0x0B5024  0x0B8AEC  error_exit
    0x0B5090  0x0B8B58  stream_error
    0x0B50D4  0x0B8B9C  open_src_file
    0x0B518C  0x0B8C54  iosub_$init_default_properties
    0x0B51B8  0x0B8C82  match_suffix
    0x0B524C  0x0B8D14  append_string
    0x0B5272  0x0B8D3A  build_name
    0x0B53F4  0x0B8EBC  open_source_file
    0x0B54A4  0x0B8F6C  open_listing_file
    0x0B55CC  0x0B9094  open_bin_file
    0x0B5624  0x0B90EC  open_binary_file
    0x0B5684  0x0B914C  open_plb_file
    0x0B5790  0x0B9258  iosub_$init_io
    0x0B5896  0x0B935E  iosub_$init_all
    0x0B592C  0x0B93F4  get_listing_stream_id
    0x0B5950  0x0B9418  iosub_$redirect_source_input
    0x0B59CC  0x0B9494  iosub_$selected_io_term
    0x0B5B10  0x0B95D8  io_term
    0x0B5B38  0x0B9600  io_term_force
    0x0B5BDA  0x0B96A2  write_ln
    0x0B5C9A  0x0B9762  iosub_$write
    0x0B5D4A  0x0B9812  read_ln
    0x0B5DD6  0x0B989E  io_mark
    0x0B5E4A  0x0B9912  io_release
    0x0B5EBA  0x0B9982  typeln
    0x0B5F02  0x0B99CA  typemsg
    0x0B5F42  0x0B9A0A  listln
    0x0B5F6E  0x0B9A36  ejctln
    0x0B5FA8  0x0B9A70  set_obj_length
    0x0B5FD0  0x0B9A98  putobj
    0x0B6032  0x0B9AFA  getobj
    0x0B6094  0x0B9B5C  freeobj
    0x0B60D6  0x0B9B9E  open_include_file
    0x0B61EA  0x0B9CB2  iosub_$get_dtm
    0x0B6238  0x0B9D00  iosub_$get_full_path_name
    0x0B6306  0x0B9DCE  close_include_file
    A5 0x2CD7E4 (cc.m68k), 0x44D968 (cc.a88k): the module's data, 0xE90
    bytes (to celpkg's or the next module's), laid out the same in both:
    +0x0 the -USRCH directory (a length and 1024 characters: the source
    name's directory when -USRCH is given; cargs_$parse_command_line_
    options's `dot'), +0x408 a record per stream (8 bytes: a short key
    io_mark keeps, the stream id; 0 the source, 1 the listing, 3 the
    library being generated), +0x428 the source's full pathname, +0x828
    the source's leaf name (256 characters), +0x928 the object file's
    current offset, +0x92C its OBJ_ channel, +0x92E the source's stream,
    +0x930 and +0x932 the lengths of the pathname and the leaf name,
    +0x934 a byte nothing reads, +0x935 what is open
    (iosub_$state_t), +0x936 whether a library is generated, +0x938
    write_ln's and +0xB40 iosub_$write's buffers (514 characters: at
    most 513 and write_ln's newline), +0xD42 a form feed and a newline
    (ejctln).  .rwdi zeroes +0x930..+0x935 and sets +0xD42; the cells
    at -0x10..-0x4 are the addresses of case_hm_$uid, uid_$nil,
    uasc_$uid and directory_$uid.  +0xD44..+0xE8B: nothing in iosub
    reaches them.

  The binaries differ only in iosub_$init_default_properties: the
  target passed to target_properties$begin_compilation is 0 in cc.m68k
  and 3 in cc.a88k (`%if cc_a88k', as cargs.pas).

  stream_error and open_src_file do not load A5 (internal); match_suffix
  ... open_plb_file are nested in iosub_$init_io (open_bin_file in
  open_binary_file) and share its frame: the name being built (-1280,
  its length -1292), the leaf name (-256, its length -1290), the
  directory's length (-1288), whether the source name had the suffix
  (-1294); build_name gets the frame in A1, the others take it from
  their dynamic link (docs/rev889-patterns.md 25).  The others are
  global and load A5.

  Not known from the original: every name but the routines'; the
  record and type names.
}
module iosub;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include '/sys/ins/error.ins.pas';
%include '/sys/ins/ms.ins.pas';
%include '/sys/ins/ios.ins.pas';
%include 'us/us/ins/ios_nr.ins.pas';
%include 'us/us/ins/prot.ins.pas';
%include '/sys/ins/mutex.ins.pas';
%include 'us/us/ins/name.ins.pas';
%include 'us/us/ins/uid_list.ins.pas';
%include '/sys/ins/type_uids.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'us/us/ins/strl.ins.pas';

%var cc_a88k;

type
  { A stream's record (+0x408 + 8 * n): the short key io_mark keeps
    for io_release, and the stream id. }
  iosub_stream_t = record
    key: integer32;
    sid: integer;
    unused: integer;
  end;

  { The 256-character leaf names (name_$strip_leaf_lc's buffer). }
  iosub_leaf_t = array [1..256] of char;

  { write_ln's and iosub_$write's buffers. }
  iosub_buf_t = array [1..514] of char;

const
  { The streams write_ln, io_mark and io_release take. }
  source_stream = 0;
  listing_stream = 1;
  library_stream = 3;

define
  iosub_$source_pathname;                       { +0x428 }
  iosub_$source_stream;                         { +0x92E }
  iosub_$source_pathname_length := 0;           { +0x930 }
  iosub_$state := [];                           { +0x935 }
  iosub_$generating_library;                    { +0x936 }

var
  usrch_dir: cargs_$name_t;                     { +0x0 }
  streams: array [0..3] of iosub_stream_t;      { +0x408 }
  leaf_name: iosub_leaf_t;                      { +0x828 }
  obj_offset: integer32;                        { +0x928 }
  obj_chan: pinteger;                           { +0x92C }
  leaf_length: integer := 0;                    { +0x932 }
  byte_934: char := chr(0);                     { +0x934: not read }
  write_buf: iosub_buf_t;                       { +0x938 }
  put_buf: iosub_buf_t;                         { +0xB40 }
  eject: array [1..2] of char := [chr(12), chr(10)];  { +0xD42 }

{ error_exit - report status, or status and a name, and end the
  program.

  0x0B5024, 0x62 bytes: with len (`move.w (16,A6),D2; bne', the flags
  surviving the two `movea.l') error_$std_format(status, '"%a"%$',
  name, len) (len's slot by address); else, when status is not 0
  (`tst.l (A3)'), error_$std_format(status, '%$'); then
  pgm_$set_severity(5) (a word after the routine), pgm_$exit. }

procedure error_exit(
    in status: univ iosub_$status_t;
    in name: univ iosub_$name_t;
    len: integer);
begin
  if len <> 0 then
    error_$std_format(status, '"%a"%$', name, len)
  else if status <> 0 then
    error_$std_format(status, '%$');
  pgm_$set_severity(pgm_$internal_fatal);
  pgm_$exit;
end;

{ stream_error - error_exit for a failure on stream: with its name when
  ios_$inq_name gives one.

  0x0B5090, 0x44 bytes, no A5: ios_$inq_name(stream, a 256-character
  frame buffer, its length, a status); error_exit(status, the name, its
  length) when that status is 0, else error_exit(status, '', 0) (the
  literal's address is the next routine's, an empty string). }

procedure stream_error(
    status: status_$t;
    stream: integer); options(val_param); internal;
var
  name: iosub_leaf_t;
  name_len: integer;
  st: status_$t;
begin
  ios_$inq_name(stream, name, name_len, st);
  if st.all = 0 then
    error_exit(status, name, name_len)
  else
    error_exit(status, '', 0);
end;

{ open_src_file - open the source file named by the len characters of
  name, an ASCII file.

  0x0B50D4, 0x88 bytes, no A5: status cleared, the stream (+0x40C) :=
  ios_$open(name, len, [] (a word 0 after the routine), status); when
  status is 0: ios_$inq_obj_flags (a status cleared in the frame
  first) and `btst #2' (ios_$of_ascii); not ASCII: error_$std_format
  of 'Source file "%A" is not an ascii file.%$' (status 0, a longword
  after the routine; 16 bytes pushed and 14 popped,
  docs/rev889-patterns.md 11) and error_exit(0, '', 0); then the
  source is open (+0x935 bit 1) and its stream copied to +0x92E.

  Not known from the original:
  - why a status is cleared before ios_$inq_obj_flags. }

procedure open_src_file(
    in name: univ iosub_$name_t;
    len: integer;
    out status: status_$t); options(val_param); internal;
var
  st: status_$t;
  zero: status_$t;
begin
  status.all := 0;
  streams[source_stream].sid := ios_$open(name, len, [], status);
  if status.all = 0 then begin
    st.all := 0;
    if not (ios_$of_ascii in
            ios_$inq_obj_flags(streams[source_stream].sid, st)) then begin
      zero.all := 0;
      error_$std_format(zero,
          'Source file "%A" is not an ascii file.%$', name, len);
      error_exit(zero, '', 0);
    end;
    iosub_$state := iosub_$state + [iosub_$source_open];
    iosub_$source_stream := streams[source_stream].sid;
  end;
end;

{ iosub_$init_default_properties - the target's properties and the
  options' defaults.

  0x0B518C, 0x2C bytes (cc.a88k 0x2E): a frame word set to the target
  (`clr.w (-2,A6)', cc.a88k `move.w #3') and passed by value to
  target_properties$begin_compilation; cargs_$init_option_defaults.

  Not known from the original:
  - why the target goes through a frame word. }

procedure iosub_$init_default_properties;
var
  target: integer;
begin
%if cc_a88k %then
  target := 3;
%else
  target := 0;
%endif
  target_properties$begin_compilation(target);
  cargs_$init_option_defaults;
end;

{ iosub_$init_io - name and open the files: the source (its name with
  suffix unless it has it), the listing, the object file and the
  library, and start the -INLIB libraries.

  0x0B5790, 0x106 bytes: st cleared and the leaf's length set to 0;
  build_name(cargs_$source_name, suffix, suffix_len, false, ...) (the
  frame in A1); name_$strip_leaf_lc(name, len, 255 (a word after
  open_listing_file), the directory's length, the leaf, its length, st);
  with -USRCH (cargs +0x27D bit 5) and a directory (`ble'), the
  directory to +2 and its length to +0; unless open (+0x935 bits 1, 0;
  the -USRCH and listing tests on cargs_$options), open_source_file,
  open_listing_file (outputs element 0, or -ES/-ESF: es <> 0); with
  outputs element 1 open_binary_file; +0x936 := outputs element 3
  (`sne') and with it open_plb_file; once (+0x935 bit 4) inlib_init
  and, with outputs element 6 (-INLIB, `tst.b; bpl'), open_inlib_list.

  Not known from the original:
  - the locals' names. }

procedure iosub_$init_io(
    in suffix: univ iosub_$name_t;
    suffix_len: integer); options(val_param);
var
  st: status_$t;                                { -1284 }
  had_suffix: boolean;                          { -1294 }
  name_len: integer;                            { -1292 }
  leaf_len: integer;                            { -1290 }
  dir_len: integer;                             { -1288 }
  name: iosub_$name_t;                          { -1280 }
  leaf: iosub_leaf_t;                           { -256 }

  { match_suffix - whether the len characters of s end with suf (case
    ignored for letters) and are longer.

    0x0B51B8, 0x94 bytes (cc.a88k 0x92: a fill word less): result
    cleared; with slen > suf_len (`ble' past) a counted loop (`dbf',
    i in D1) comparing s[slen - suf_len + i] with suf[i] by their
    difference (a word): not 0, it must be -32 with suf[i] in 'a'..'z'
    (`bhi', `bcc') or 32 with suf[i] in 'A'..'Z' (`bhi', `bcs'), else
    the result stays false (a branch to the end); the loop done, the
    result true.

    Not known from the original:
    - how the mismatch leaves the loop (a `return' here). }

  function match_suffix(
      in s: univ iosub_$name_t;
      slen: integer;
      in suf: univ iosub_$name_t;
      suf_len: integer): boolean; options(val_param);
  var
    i: integer;
    diff: integer;
  begin
    match_suffix := false;
    if slen > suf_len then begin
      for i := 1 to suf_len do begin
        diff := ord(s[slen - suf_len + i]) - ord(suf[i]);
        if diff <> 0 then
          if not ((suf[i] <= 'z') and (diff = -32) and (suf[i] >= 'a')) then
            if (suf[i] > 'Z') or (diff <> 32) or (suf[i] < 'A') then
              return;
      end;
      match_suffix := true;
    end;
  end;

  { append_string - n characters of s to d.

    0x0B524C, 0x26 bytes, no frame (docs/rev889-patterns.md 16): the
    parameters read off (4,SP), (8,SP), (12,SP); a counted loop from
    1. }

  procedure append_string(
      out d: univ iosub_$name_t;
      in s: univ iosub_$name_t;
      n: integer); options(val_param);
  var
    i: integer;
  begin
    for i := 1 to n do
      d[i] := s[i];
  end;

  { build_name - the parent's name from a name option: the source's
    leaf name when the option is empty (the source's suffix replaced),
    else the option's name, under which, when check_dir and it names a
    directory, the leaf name; then suffix appended unless the name
    already ends with it (then has_suffix).

    0x0B5272, 0x180 bytes (the parent's frame in A1, moved to A2):
    has_suffix cleared; an empty name (`tst.w (A3)'): the leaf's length
    and characters (append_string), the source suffix (the parent's
    parameters (8,A2), (12,A2)) removed when it matches; else strl_$copy
    (name, its length, the parent's name and length, name's length as
    the maximum) and, with check_dir, ios_$open(..., [ios_$inquire_only_
    opt] (a word 0x0010 after the routine)), ios_$inq_type_uid,
    ios_$close; the type compared with directory_$uid (`cmpm.l' twice
    through (-4,A5)): '/', the leaf, the source suffix removed when it
    matches; these paths end appending suffix (0x0B53CC); the others
    (no check_dir, not opened, not a directory) set has_suffix and end
    when the name matches suffix, else append it.

    Not known from the original:
    - the shared tail as a `goto'. }

  procedure build_name(
      in opt_name: cargs_$name_t;
      in suf: univ iosub_$name_t;
      suf_len: integer;
      check_dir: boolean;
      out has_suffix: boolean); options(val_param);
  label
    10;
  var
    sid: integer;
    st: status_$t;
    uid: uid_$t;
  begin
    has_suffix := false;
    if opt_name.length = 0 then begin
      name_len := leaf_len;
      append_string(name, leaf, name_len);
      if match_suffix(name, name_len, suffix, suffix_len) then
        name_len := name_len - suffix_len;
      goto 10;
    end;
    strl_$copy(opt_name.body, opt_name.length, name, name_len,
               opt_name.length);
    if check_dir then begin
      sid := ios_$open(name, name_len, [ios_$inquire_only_opt], st);
      if st.all = 0 then begin
        ios_$inq_type_uid(sid, uid, st);
        ios_$close(sid, st);
        if uid = directory_$uid then begin
          name[name_len + 1] := '/';
          append_string(name[name_len + 2], leaf, leaf_len);
          name_len := name_len + leaf_len + 1;
          if match_suffix(name, name_len, suffix, suffix_len) then
            name_len := name_len - suffix_len;
          goto 10;
        end;
      end;
    end;
    if match_suffix(name, name_len, suf, suf_len) then begin
      has_suffix := true;
      return;
    end;
  10:
    append_string(name[name_len + 1], suf, suf_len);
    name_len := name_len + suf_len;
  end;

  { open_source_file - open the source and record its names.

    0x0B53F4, 0xB0 bytes: open_src_file(name, len, st); failing, and
    the name not having had the suffix (`bmi' past), the suffix is
    removed and the open tried again (on failure the suffix put back);
    still failing, error_exit(st, name, len).  Then +0x930 := len, the
    name to +0x428 (append_string), +0x932 := the leaf's length, the
    leaf to +0x828. }

  procedure open_source_file(
      name_had_suffix: boolean); options(val_param);
  label
    10;
  var
    st: status_$t;
  begin
    open_src_file(name, name_len, st);
    if st.all <> 0 then begin
      if not name_had_suffix then begin
        name_len := name_len - suffix_len;
        open_src_file(name, name_len, st);
        if st.all = 0 then
          goto 10;
        name_len := name_len + suffix_len;
      end;
      error_exit(st, name, name_len);
    end;
  10:
    iosub_$source_pathname_length := name_len;
    append_string(iosub_$source_pathname, name, name_len);
    leaf_length := leaf_len;
    append_string(leaf_name, leaf, leaf_len);
  end;

  { open_listing_file - name and create the listing.

    0x0B54A4, 0x11C bytes: st cleared.  With outputs element 0 (`btst
    #1'): with -USRCH and no -L name, the -B name split
    (strl_$copy, name_$strip_leaf_lc with 255) and two characters taken
    off the name's and the leaf's lengths; build_name(-L name, '.lst',
    4, true, ...).  Else with -ESF (es = 2): build_name(-ESF name,
    '.i', 2, true, ...) ('.i' and '.lst' one literal, 0x0B55C6).  Then
    with -ES (es = 1) the listing is standard output (+0x414 := 1);
    else ios_$create(name, len, uasc_$uid (through (-8,A5)),
    ios_$truncate_mode (a word 3), [ios_$write_opt] (a word 2),
    +0x414, st) and error_exit on failure.  The listing is open (+0x935
    bit 0).

    Not known from the original:
    - why -USRCH takes the -B name's leaf. }

  procedure open_listing_file;
  var
    st: status_$t;
  begin
    st.all := 0;
    if 0 in cargs_$options.outputs then begin
      if cargs_$options.usrch and (cargs_$options.l_name.length = 0) then
      begin
        strl_$copy(cargs_$options.b_name.body, cargs_$options.b_name.length,
                   name, name_len, cargs_$options.b_name.length);
        name_$strip_leaf_lc(name, name_len, 255, dir_len, leaf, leaf_len,
                            st);
        name_len := name_len - 2;
        leaf_len := leaf_len - 2;
      end;
      build_name(cargs_$options.l_name, '.lst', 4, true, had_suffix);
    end
    else if cargs_$options.es = 2 then
      build_name(cargs_$options.esf_name, '.i', 2, true, had_suffix);
    if cargs_$options.es = 1 then
      streams[listing_stream].sid := 1
    else begin
      ios_$create(name, name_len, uasc_$uid, ios_$truncate_mode,
                  [ios_$write_opt], streams[listing_stream].sid, st);
      if st.all <> 0 then
        error_exit(st, name, name_len);
    end;
    iosub_$state := iosub_$state + [iosub_$listing_open];
  end;

  { open_binary_file - name and open the object file.

    0x0B5624, 0x5A bytes: st cleared (not used); with -BX (outputs
    element 5, `btst #6') build_name(-B name, '', 0, false, ...) (the
    word and the byte pushed as one `clr.l'), else build_name(-B name,
    '.bin', 4, true, ...); open_bin_file(name, len). }

  procedure open_binary_file;
  var
    st: status_$t;

    { open_bin_file - obj_$init_io, obj_$open_t(+0x92C, name, len,
      st), error_exit on failure; the object file is open (+0x935 bit
      2) at offset 0 (+0x928).

      0x0B55CC, 0x58 bytes. }

    procedure open_bin_file(
        in bin_name: univ iosub_$name_t;
        bin_len: integer); options(val_param);
    var
      st: status_$t;
    begin
      st.all := 0;
      obj_$init_io;
      obj_$open_t(obj_chan, bin_name, bin_len, st);
      if st.all <> 0 then
        error_exit(st, bin_name, bin_len);
      iosub_$state := iosub_$state + [iosub_$object_open];
      obj_offset := 0;
    end;

  begin
    st.all := 0;
    if 5 in cargs_$options.outputs then
      build_name(cargs_$options.b_name, '', 0, false, had_suffix)
    else
      build_name(cargs_$options.b_name, '.bin', 4, true, had_suffix);
    open_bin_file(name, name_len);
  end;

  { open_plb_file - name and create the library being generated.

    0x0B5684, 0xF4 bytes: with outputs element 4 (`btst #5') build_name
    (the library's name, '', 0, false, ...); else when the leaf name
    ends with '.ins.pas' its 8 characters are removed and the suffix is
    '.plb.pas', otherwise '.plb' (build_name with check_dir); then
    ios_$create(name, len, uid_$nil (through (-12,A5)),
    ios_$truncate_mode, [ios_$write_opt], +0x424, st) and
    ios_$set_obj_flag(+0x424, ios_$of_delete_on_close, false, st), each
    followed by error_exit on failure ('.ins.pas', '.plb', '.plb.pas'
    one literal from 0x0B577C). }

  procedure open_plb_file;
  var
    st: status_$t;
  begin
    if 4 in cargs_$options.outputs then
      build_name(cargs_$options.name_e92, '', 0, false, had_suffix)
    else if match_suffix(leaf, leaf_len, '.ins.pas', 8) then begin
      leaf_len := leaf_len - 8;
      build_name(cargs_$options.name_e92, '.plb.pas', 8, true, had_suffix);
    end
    else
      build_name(cargs_$options.name_e92, '.plb', 4, true, had_suffix);
    ios_$create(name, name_len, uid_$nil, ios_$truncate_mode,
                [ios_$write_opt], streams[library_stream].sid, st);
    if st.all <> 0 then
      error_exit(st, name, name_len);
    ios_$set_obj_flag(streams[library_stream].sid, ios_$of_delete_on_close,
                      false, st);
    if st.all <> 0 then
      error_exit(st, name, name_len);
  end;

begin
  st.all := 0;
  leaf_len := 0;
  build_name(cargs_$source_name, suffix, suffix_len, false, had_suffix);
  name_$strip_leaf_lc(name, name_len, 255, dir_len, leaf, leaf_len, st);
  if cargs_$options.usrch and (dir_len > 0) then begin
    append_string(usrch_dir.body, name, dir_len);
    usrch_dir.length := dir_len;
  end;
  if not (iosub_$source_open in iosub_$state) then
    open_source_file(had_suffix);
  if not (iosub_$listing_open in iosub_$state) then
    if (0 in cargs_$options.outputs) or (cargs_$options.es <> 0) then
      open_listing_file;
  if 1 in cargs_$options.outputs then
    open_binary_file;
  iosub_$generating_library := 3 in cargs_$options.outputs;
  if iosub_$generating_library then
    open_plb_file;
  if not (iosub_$inlib_initialized in iosub_$state) then begin
    inlib_init;
    if 6 in cargs_$options.outputs then
      open_inlib_list;
    iosub_$state := iosub_$state + [iosub_$inlib_initialized];
  end;
end;

{ iosub_$init_all - start the compilation.

  0x0B5896, 0x96 bytes: mem_$initialise, gspace_$open,
  iosub_$init_default_properties,
  cargs_$parse_command_line_fixed_arguments,
  cargs_$parse_command_line_options with the parameters passed on and
  +0 (the -USRCH directory) as dot (44 bytes pushed, 42 popped:
  docs/rev889-patterns.md 11); target_properties$cpu_rev_specific of
  the processor set as a word (`andi.w #0x3FFC' of cargs +0x284, `lsr.w
  #2'); iosub_$init_io(suffix, suffix_len). }

procedure iosub_$init_all(
    in suffix: univ iosub_$name_t;
    suffix_len: integer;
    var ndef: integer;
    maxdef: integer;
    deflist: univ_ptr;
    var nidir: integer;
    maxidir: integer;
    idirlist: univ_ptr;
    var ninlib: integer;
    maxinlib: integer;
    inliblist: univ_ptr;
    var nundef: integer;
    maxundef: integer;
    undeflist: univ_ptr);
begin
  mem_$initialise;
  gspace_$open;
  iosub_$init_default_properties;
  cargs_$parse_command_line_fixed_arguments;
  cargs_$parse_command_line_options(ndef, maxdef, deflist, nidir, maxidir,
      idirlist, addr(usrch_dir), ninlib, maxinlib, inliblist, nundef,
      maxundef, undeflist);
  target_properties$cpu_rev_specific(integer(cargs_$options.cpu));
  iosub_$init_io(suffix, suffix_len);
end;

{ get_listing_stream_id - the listing's stream, -1 when it is not open.

  0x0B592C, 0x24 bytes: +0x935 bit 0, +0x414, `moveq #-1'. }

function get_listing_stream_id;
begin
  if iosub_$listing_open in iosub_$state then
    get_listing_stream_id := streams[listing_stream].sid
  else
    get_listing_stream_id := -1;
end;

{ iosub_$redirect_source_input - read the source from another file.

  0x0B5950, 0x7C bytes: an open source is closed (ios_$close,
  stream_error on failure, +0x935 bit 1 cleared); open_src_file(name,
  len, st), error_exit(st, name, len) on failure. }

procedure iosub_$redirect_source_input;
var
  st: status_$t;
begin
  if iosub_$source_open in iosub_$state then begin
    ios_$close(streams[source_stream].sid, st);
    if st.all <> 0 then
      stream_error(st, streams[source_stream].sid);
    iosub_$state := iosub_$state - [iosub_$source_open];
  end;
  open_src_file(name, len, st);
  if st.all <> 0 then
    error_exit(st, name, len);
end;

{ iosub_$selected_io_term - close the object file and, as asked, the
  listing and the source; end the -INLIB libraries.

  0x0B59CC, 0x12C bytes: an open object file with severity at most 2
  (`cmpi.w #2; bgt') is closed (obj_$close), a failure reported by
  error_$std_format(st, '"%LA"%$', 'binary file', 11) (the length a
  longword after the routine) and severity := 4; +0x935 bit 2 cleared
  in any case.  With close_listing (14) and the listing open: unless
  it is stream 1 or 2, ios_$truncate (a failure: its fail bit cleared,
  `bclr #7', and stream_error) and ios_$close (stream_error); bit 0
  cleared.  With close_source (12) and the source open: ios_$close
  (stream_error), bit 1 cleared.  inlib_term once (bit 4). }

procedure iosub_$selected_io_term;
var
  st: status_$t;
  len: integer32;
begin
  if (iosub_$object_open in iosub_$state) and (severity <= 2) then begin
    obj_$close(obj_chan, st);
    if st.all <> 0 then begin
      len := 11;
      error_$std_format(st, '"%LA"%$', 'binary file', len);
      severity := 4;
    end;
  end;
  iosub_$state := iosub_$state - [iosub_$object_open];
  if close_listing and (iosub_$listing_open in iosub_$state) then begin
    if (streams[listing_stream].sid <> 1) and
       (streams[listing_stream].sid <> 2) then begin
      ios_$truncate(streams[listing_stream].sid, st);
      if st.all <> 0 then begin
        st.fail := false;
        stream_error(st, streams[listing_stream].sid);
      end;
      ios_$close(streams[listing_stream].sid, st);
      if st.all <> 0 then
        stream_error(st, streams[listing_stream].sid);
    end;
    iosub_$state := iosub_$state - [iosub_$listing_open];
  end;
  if close_source and (iosub_$source_open in iosub_$state) then begin
    ios_$close(streams[source_stream].sid, st);
    if st.all <> 0 then
      stream_error(st, streams[source_stream].sid);
    iosub_$state := iosub_$state - [iosub_$source_open];
  end;
  if iosub_$inlib_initialized in iosub_$state then begin
    inlib_term;
    iosub_$state := iosub_$state - [iosub_$inlib_initialized];
  end;
end;

{ io_term - iosub_$selected_io_term(severity, true, true).

  0x0B5B10, 0x28 bytes (`st -(SP)' twice). }

procedure io_term;
begin
  iosub_$selected_io_term(severity, true, true);
end;

{ io_term_force - close everything, ignoring failures.

  0x0B5B38, 0xA2 bytes: as iosub_$selected_io_term with both closes
  and no reports; each bit of +0x935 cleared whether or not it was
  set. }

procedure io_term_force;
var
  st: status_$t;
begin
  if iosub_$object_open in iosub_$state then
    obj_$close(obj_chan, st);
  iosub_$state := iosub_$state - [iosub_$object_open];
  if iosub_$listing_open in iosub_$state then
    if (streams[listing_stream].sid <> 1) and
       (streams[listing_stream].sid <> 2) then begin
      ios_$truncate(streams[listing_stream].sid, st);
      ios_$close(streams[listing_stream].sid, st);
    end;
  iosub_$state := iosub_$state - [iosub_$listing_open];
  if iosub_$source_open in iosub_$state then
    ios_$close(streams[source_stream].sid, st);
  iosub_$state := iosub_$state - [iosub_$source_open];
  if iosub_$inlib_initialized in iosub_$state then
    inlib_term;
  iosub_$state := iosub_$state - [iosub_$inlib_initialized];
end;

{ write_ln - a line to the listing or the library.

  0x0B5BDA, 0xC0 bytes: (stream = 3 and +0x936: `seq; and.b; bmi') or
  (the listing open and stream = 1); n := len widened, at most 513
  (`cmpi.l #514; blt'); lib_$data_move(buf, the buffer's address in a
  frame temporary, n); a newline at buf[n + 1]; ios_$put(the stream's
  id (+0x40C + 8 * stream), [], the buffer, n + 1, st), stream_error on
  failure. }

procedure write_ln;
var
  n: integer32;
  st: status_$t;
begin
  if ((stream = library_stream) and iosub_$generating_library) or
     ((iosub_$listing_open in iosub_$state) and
      (stream = listing_stream)) then begin
    n := len;
    if n > 513 then
      n := 513;
    lib_$data_move(buf, addr(write_buf), n);
    n := n + 1;
    write_buf[n] := chr(10);
    ios_$put(streams[stream].sid, [], write_buf, n, st);
    if st.all <> 0 then
      stream_error(st, streams[stream].sid);
  end;
end;

{ iosub_$write - write_ln without the newline.

  0x0B5C9A, 0xB0 bytes: the same tests and copy, to the buffer at
  +0xB40, and ios_$put of n characters. }

procedure iosub_$write;
var
  n: integer32;
  st: status_$t;
begin
  if ((stream = library_stream) and iosub_$generating_library) or
     ((iosub_$listing_open in iosub_$state) and
      (stream = listing_stream)) then begin
    n := len;
    if n > 513 then
      n := 513;
    lib_$data_move(buf, addr(put_buf), n);
    ios_$put(streams[stream].sid, [], put_buf, n, st);
    if st.all <> 0 then
      stream_error(st, streams[stream].sid);
  end;
end;

{ read_ln - the next line of stream.

  0x0B5D4A, 0x8C bytes: len := ios_$get(stream, [], buf, maxlen
  widened in a frame temporary, st); status 0: a final newline dropped
  (buf[len] = chr(10): len - 1), false; ios_$end_of_file (0x01270009):
  true; otherwise stream_error unless ios_$buffer_too_small
  (0x0127FFFA), and the result the fail bit (`tst.l; slt'). }

function read_ln;
var
  st: status_$t;
  n: integer32;
begin
  n := maxlen;
  len := ios_$get(stream, [], buf, n, st);
  if st.all = 0 then begin
    if buf[len] = chr(10) then
      len := len - 1;
    read_ln := false;
  end
  else if st.all = ios_$end_of_file then
    read_ln := true
  else begin
    if st.all <> ios_$buffer_too_small then
      stream_error(st, stream);
    read_ln := st.fail;
  end;
end;

{ io_mark - remember stream's position.

  0x0B5DD6, 0x74 bytes: the record at +0x408 + 8 * stream (A2); for
  the listing only when its id is not 2, it is open and its id is not
  1; key := ios_$inq_short_key(id, ios_$current (a word 0), st),
  stream_error on failure. }

procedure io_mark;
var
  st: status_$t;
begin
  with streams[stream] do
    if (stream <> listing_stream) or
       ((sid <> 2) and (iosub_$listing_open in iosub_$state) and
        (sid <> 1)) then begin
      key := ios_$inq_short_key(sid, ios_$current, st);
      if st.all <> 0 then
        stream_error(st, sid);
    end;
end;

{ io_release - go back to the position io_mark kept.

  0x0B5E4A, 0x70 bytes: the same tests; ios_$seek_short_key(id, key,
  st), stream_error on failure. }

procedure io_release;
var
  st: status_$t;
begin
  with streams[stream] do
    if (stream <> listing_stream) or
       ((sid <> 2) and (iosub_$listing_open in iosub_$state) and
        (sid <> 1)) then begin
      ios_$seek_short_key(sid, key, st);
      if st.all <> 0 then
        stream_error(st, sid);
    end;
end;

{ typeln - s to error output.

  0x0B5EBA, 0x44 bytes: unless error_listing_0c (`tst.b 0x2C3174;
  bmi'), vfmt_$ws2(2 (a word constant shared with open_listing_file),
  '%a%.', s's characters, its length zero-extended to a longword in a
  frame temporary). }

procedure typeln;
var
  len: integer32;
begin
  if not error_listing_0c then begin
    len := s.length;
    vfmt_$ws2(stream_$errout, '%a%.', s.body, len);
  end;
end;

{ typemsg - s to standard output.

  0x0B5F02, 0x40 bytes: as typeln with vfmt_$write2. }

procedure typemsg;
var
  len: integer32;
begin
  if not error_listing_0c then begin
    len := s.length;
    vfmt_$write2('%a%.', s.body, len);
  end;
end;

{ listln - write_ln(1, s's characters, s's length).

  0x0B5F42, 0x2C bytes. }

procedure listln;
begin
  write_ln(listing_stream, addr(s.body), s.length);
end;

{ ejctln - a form feed and a newline to the open listing.

  0x0B5F6E, 0x36 bytes: ios_$put(+0x414, [], +0xD42, 2 (a longword
  after the routine), st); st not tested. }

procedure ejctln;
var
  st: status_$t;
begin
  if iosub_$listing_open in iosub_$state then
    ios_$put(streams[listing_stream].sid, [], eject, 2, st);
end;

{ set_obj_length - move the object file's offset on by len, to an even
  offset.

  0x0B5FA8, 0x28 bytes: `add.l' to +0x928; `btst #0' of its low byte,
  `addq.l #1'. }

procedure set_obj_length;
begin
  obj_offset := obj_offset + len;
  if odd(obj_offset) then
    obj_offset := obj_offset + 1;
end;

{ putobj - map len bytes of the object file at offset from its current
  offset, to write.

  0x0B5FD0, 0x62 bytes: obj_$put(+0x92C, the offset sum in a frame
  temporary, len (its slot), st); error_exit(st, 'binary file', 11) on
  failure; the address in A0 (globals_from_general.ins.pas). }

function putobj;
var
  st: status_$t;
  p: univ_ptr;
  where: integer32;
begin
  where := obj_offset + offset;
  p := obj_$put(obj_chan, where, len, st);
  if st.all <> 0 then
    error_exit(st, 'binary file', 11);
  putobj := p;
end;

{ getobj - putobj with obj_$get.

  0x0B6032, 0x62 bytes. }

function getobj;
var
  st: status_$t;
  p: univ_ptr;
  where: integer32;
begin
  where := obj_offset + offset;
  p := obj_$get(obj_chan, where, len, st);
  if st.all <> 0 then
    error_exit(st, 'binary file', 11);
  getobj := p;
end;

{ freeobj - obj_$free(+0x92C, p (its slot), st), error_exit(st, 'binary
  file', 11) on failure.

  0x0B6094, 0x42 bytes. }

procedure freeobj;
var
  st: status_$t;
begin
  obj_$free(obj_chan, p, st);
  if st.all <> 0 then
    error_exit(st, 'binary file', 11);
end;

{ open_include_file - open an include file.

  0x0B60D6, 0x110 bytes: in_first false (`bmi' past): strl_$copy(name,
  len, a 256-character frame buffer, its length, len) and ios_$open of
  the copy; else ios_$open(name, len, [], st) (the call shared); sid :=
  the stream.  Opened: ios_$inq_path_name_lc(sid, ios_$leaf_name (a
  word 0), 256 (a word after the routine), a frame name, its length,
  st), the result false for the leaf `.' (length 1), else true.  Not
  opened: false for ios_$no_rights, ios_$insufficient_rights,
  ios_$object_not_found, ios_$name_not_found, ios_$dir_not_found (a
  chain of `cmpi.l'); otherwise error_$std_format(st, '"%LA"%$', name,
  len), pgm_$set_severity(4) (a word after the routine), pgm_$exit.

  Not known from the original:
  - the locals' names; whether the five statuses were a `case' or a set
    test (the compare chain fits either). }

function open_include_file;
var
  copy: iosub_leaf_t;                           { -256 }
  copy_len: integer;                            { -520 }
  st: status_$t;                                { -516 }
  leaf: iosub_leaf_t;                           { -512 }
  leaf_len: integer;                            { -518 }
begin
  if not in_first then begin
    strl_$copy(name, len, copy, copy_len, len);
    sid := ios_$open(copy, copy_len, [], st);
  end
  else
    sid := ios_$open(name, len, [], st);
  if st.all = 0 then begin
    ios_$inq_path_name_lc(sid, ios_$leaf_name, 256, leaf, leaf_len, st);
    if (leaf_len = 1) and (leaf[1] = '.') then
      open_include_file := false
    else
      open_include_file := true;
  end
  else if (st.all = ios_$no_rights) or
          (st.all = ios_$insufficient_rights) or
          (st.all = ios_$object_not_found) or
          (st.all = ios_$name_not_found) or
          (st.all = ios_$dir_not_found) then
    open_include_file := false
  else begin
    error_$std_format(st, '"%LA"%$', name, len);
    pgm_$set_severity(pgm_$output_invalid);
    pgm_$exit;
  end;
end;

{ iosub_$get_dtm - the time sid's file was modified.

  0x0B61EA, 0x4E bytes: ios_$inq_file_attr(sid, a time, the result, the
  same time, the blocks, st) (the creation and use times in one frame
  longword); the result in D0 before stream_error on failure.

  Not known from the original:
  - the locals' names. }

function iosub_$get_dtm;
var
  t: time_$clockh_t;
  dtm: time_$clockh_t;
  blocks: integer32;
  st: status_$t;
begin
  ios_$inq_file_attr(sid, t, dtm, t, blocks, st);
  iosub_$get_dtm := dtm;
  if st.all <> 0 then
    stream_error(st, sid);
end;

{ iosub_$get_full_path_name - strtk of sid's file's pathname.

  0x0B6238, 0xCA bytes: ios_$inq_path_name_lc(sid, ios_$root_name (a
  word 4 shared with open_include_file's severity), 1024, a frame
  name, its length, st); then ios_$inq_type_uid(sid, uid, st) and, for
  case_hm_$uid (through (-16,A5)), ios_$inq_path_name_lc(...,
  ios_$resid_name (a word 6), ...) and the length less the residual
  name's and one; with status 0 strtk(name, length), else
  stream_error (the tests after each call threaded into the last). }

function iosub_$get_full_path_name;
var
  path: iosub_$name_t;                          { -2056 }
  path_len: integer;                            { -2064 }
  resid: iosub_$name_t;                         { -1032 }
  resid_len: integer;                           { -2062 }
  uid: uid_$t;                                  { -8 }
  st: status_$t;                                { -2060 }
  len: integer;
begin
  ios_$inq_path_name_lc(sid, ios_$root_name, 1024, path, path_len, st);
  len := path_len;
  if st.all = 0 then begin
    ios_$inq_type_uid(sid, uid, st);
    if st.all = 0 then
      if uid = case_hm_$uid then begin
        ios_$inq_path_name_lc(sid, ios_$resid_name, 1024, resid,
                              resid_len, st);
        if st.all = 0 then
          len := len - (resid_len + 1);
      end;
  end;
  if st.all = 0 then
    iosub_$get_full_path_name := strtk(path, len)
  else
    stream_error(st, sid);
end;

{ close_include_file - ios_$close(sid, st), st not tested.

  0x0B6306, 0x22 bytes. }

procedure close_include_file;
var
  st: status_$t;
begin
  ios_$close(sid, st);
end;
