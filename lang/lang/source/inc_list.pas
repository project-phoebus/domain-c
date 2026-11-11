{ inc_list - INC_LIST, the include directories (-idir) and the libraries
  to bind with (-inlib): an include file is opened by its name when the
  name is absolute, else through the directories in order; each library
  is handed to inlib_add, a relative name made `./name'.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0AC9BC  0x0AE39C  find_file_name
    0x0ACA0C  0x0AE3EC  open_include_list
    0x0ACA4A  0x0AE42A  open_include_list_sub
    0x0ACC34  0x0AE614  open_inlib_list_sub
    0x0ACD52  0x0AE732  open_inlib_list
    A5 0x2C3178 (cc.m68k), 0x4431E8 (cc.a88k): the module's data, 0x214
    bytes (to kfold's): the two lists and their counts (inc_list.ins.pas),
    +0x210 a boolean only this unit uses.  Nothing is initialized.

  Every routine is global and loads A5.
}
module inc_list;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/c.ins.pas';
%include 'us/us/ins/pgm.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include 'us/us/ins/error.ins.pas';
%include '/sys/ins/error.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';

define
  inc_list_inlibs,                      { +0x0 }
  inc_list_idirs,                       { +0x108 }
  inc_list_ninlib,                      { +0x20C }
  inc_list_nidir;                       { +0x20E }

var
  { +0x210: passed as open_include_file's last argument (which it does
    not read); find_file_name clears it around its search and sets it
    after. }
  searching_flag: boolean;

{ find_file_name - the path of the include file named by name.

  0x0AC9BC, 0x50 bytes: +0x210 := false; open_include_list_sub(name,
  delim, a local stream (-2), path, pathlen, a local boolean (-4))
  (`bsr' 0x0ACA4A), its result not read; found := true (`st (A3)');
  +0x210 := true.

  Not known from the original:
  - the names; why the stream is not closed and found not taken from
    the result. }

procedure find_file_name(
    name: il_$node_ptr_t;
    delim: char;
    out path: univ cargs_$chars_t;
    out pathlen: integer;
    out found: boolean);
var
  sid: integer;
  in_first: boolean;
  ok: boolean;
begin
  searching_flag := false;
  ok := open_include_list_sub(name, delim, sid, path, pathlen, in_first);
  found := true;
  searching_flag := true;
end;

{ open_include_list - open_include_list_sub, found set whatever the
  outcome.

  0x0ACA0C, 0x3E bytes: the arguments passed on with a local boolean
  (-2) for in_first, the result not read; found := true.

  Not known from the original:
  - the names. }

procedure open_include_list(
    name: il_$node_ptr_t;
    delim: char;
    var sid: integer;
    out path: univ cargs_$chars_t;
    out pathlen: integer;
    out found: boolean);
var
  in_first: boolean;
  ok: boolean;
begin
  ok := open_include_list_sub(name, delim, sid, path, pathlen, in_first);
  found := true;
end;

{ open_include_list_sub - open the include file named by name.

  0x0ACA4A, 0x1A8 bytes.  The result (a frame byte, -42) starts true;
  in_first := false.  The absolute prefixes are a local set (-32)
  copied from one of two 32-byte constants: ['/'] (0x0ACBF4) when
  cargs_$options.usrch (+0x27D bit 5, `btst #5,0x2C3669'), else ['.',
  '/', '~'] (0x0ACC14).  A name whose first character is in it, or
  whose second is `(' with more than 2 characters and a first `$', is
  opened as it is (len - 1 characters: the delimiter dropped) with
  in_first false (`clr.w -(SP)'); when that fails the result is false,
  else the characters are copied to path.  Otherwise the directories
  from 2 when delim is `>' (`cmpi.b #62'), else from 1, to
  inc_list_nidir (a `dbf' loop): a directory of no characters ends the
  search (`ble' to the result's clearing); path := the directory, a `/'
  added unless it ends in `/' or `\', then the name less its delimiter,
  pathlen set as each character is stored; in_first := the index is 1;
  open_include_file (0x0ACBC8) succeeding returns true.  After the
  loop the result is false.

  Not known from the original:
  - the locals' names; whether the search's end was written with exit
    and return (the image branches out of the loop to the clearing of
    the result, and past it on success). }

function open_include_list_sub(
    name: il_$node_ptr_t;
    delim: char;
    var sid: integer;
    out path: univ cargs_$chars_t;
    out pathlen: integer;
    out in_first: boolean): boolean;
var
  found: boolean;
  absolute: set of char;
  first: integer;
  i, j: integer;
  len: integer;
  dir: inc_list_$name_ptr_t;
begin
  found := true;
  in_first := false;
  if cargs_$options.usrch then
    absolute := ['/']
  else
    absolute := ['.', '/', '~'];
  if (name^.str_chars[1] in absolute) or
     ((name^.str_chars[2] = '(') and (name^.str_len > 2) and
      (name^.str_chars[1] = '$')) then begin
    pathlen := name^.str_len - 1;
    if open_include_file(name^.str_chars, pathlen, sid, false,
                         searching_flag) then
      for j := 1 to pathlen do
        path[j] := name^.str_chars[j]
    else
      found := false;
  end
  else begin
    if delim = '>' then
      first := 2
    else
      first := 1;
    for i := first to inc_list_nidir do begin
      dir := inc_list_idirs[i];
      if dir^.length <= 0 then
        exit;
      len := dir^.length;
      for j := 1 to len do
        path[j] := dir^.body[j];
      if (path[len] <> '/') and (path[len] <> '\') then begin
        len := len + 1;
        path[len] := '/';
      end;
      len := len + 1;
      for j := 1 to name^.str_len - 1 do begin
        path[len] := name^.str_chars[j];
        pathlen := len;
        len := len + 1;
      end;
      if i = 1 then
        in_first := true
      else
        in_first := false;
      if open_include_file(path, pathlen, sid, in_first,
                           searching_flag) then begin
        open_include_list_sub := found;
        return;
      end;
    end;
    found := false;
  end;
  open_include_list_sub := found;
end;

{ open_inlib_list_sub - pass the i-th -inlib library to inlib_add.

  0x0ACC34, 0x11E bytes.  The library's kind (D0) starts 1 (relative);
  0 (as it is) when its first character is `/', or it has more than one
  character and begins `$('; with a first `.', 0 when the second is
  `/' (and there is one), else 2; with a first `~', when not
  cargs_$options.usrch and a second character not `/', 2.  A `case'
  (tested 1, 2, 0): 1 passes `./' and the name (a 1024-byte local at
  -1024), length + 2; 2 the first character, `/', then the characters
  from the second stored from the second position on, length + 1; 0
  the name itself.

  Not known from the original:
  - the locals' names.  Kind 2 overwrites the `/' it has just stored
    and passes one character more than it set (the copy's index starts
    at 2, `moveq #2,D2', where 3 would make `~/name'): kept as the
    image does it. }

procedure open_inlib_list_sub(
    in i: integer);
var
  lib: inc_list_$name_ptr_t;
  kind: integer;
  j, k: integer;
  buf: cargs_$chars_t;
begin
  lib := inc_list_inlibs[i];
  kind := 1;
  if lib^.body[1] = '/' then
    kind := 0
  else if (lib^.length > 1) and (lib^.body[1] = '$') and
          (lib^.body[2] = '(') then
    kind := 0
  else if lib^.body[1] = '.' then begin
    if (lib^.length > 1) and (lib^.body[2] = '/') then
      kind := 0
    else
      kind := 2;
  end
  else if lib^.body[1] = '~' then begin
    if not cargs_$options.usrch and (lib^.length > 1) and
       (lib^.body[2] <> '/') then
      kind := 2;
  end;
  case kind of
    1: begin
      buf[1] := '.';
      buf[2] := '/';
      j := 3;
      for k := 1 to lib^.length do begin
        buf[j] := lib^.body[k];
        j := j + 1;
      end;
      inlib_add(buf, lib^.length + 2);
    end;
    2: begin
      buf[1] := lib^.body[1];
      buf[2] := '/';
      j := 2;
      for k := 2 to lib^.length do begin
        buf[j] := lib^.body[k];
        j := j + 1;
      end;
      inlib_add(buf, lib^.length + 1);
    end;
    0: inlib_add(lib^.body, lib^.length);
  end;
end;

{ open_inlib_list - open each -inlib library.

  0x0ACD52, 0x40 bytes: a `for' from 1 to inc_list_ninlib (`dbf'), the
  index (D3) copied to a frame word (-2) whose address is passed to
  open_inlib_list_sub.

  Not known from the original:
  - the index's name. }

procedure open_inlib_list;
var
  i: integer;
begin
  for i := 1 to inc_list_ninlib do
    open_inlib_list_sub(i);
end;
