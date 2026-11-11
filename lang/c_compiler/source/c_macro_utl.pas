{ c_macro_utl - MU_, the C preprocessor's macro utilities: the macro
  table (128 hash chains), the predefined macros, the text list
  elements macro bodies and pending text are kept in (cut from blocks
  of 256 with a bitmap of those in use), and binding actual parameters
  into a body.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x058F00  0x059180  hash_value
    0x058F42  0x0591C2  mu_$lookup_name
    0x058FB0  0x059230  mu_$enter_name
    0x05909C  0x05931C  mu_$cancel_name
    0x059128  0x0593A8  mu_$def_macro
    0x0591C8  0x059448  mu_$initialize
    0x059494  0x059714  mu_$dump
    0x05968C  0x05990C  mu_$convert_formal
    0x05973C  0x0599BC  mu_$compress_macro
    0x059812  0x059A92  mu_$alloc_tle
    0x059A44  0x059CC4  mu_$free_tle
    0x059B7A  0x059DFA  mu_$free_tle_list
    0x059BB2  0x059E32  mu_$find_hash_word
    0x059C84  0x059F04  end_of_text_chain
    0x059C98  0x059F18  copy_body
    0x059D08  0x059F88  mu_$copy_text_list
    0x059D36  0x059FB6  mu_$merge_line_tlp
    0x059E14  0x05A094  bind_backwards
    0x059EDC  0x05A15C  mu_$bind_params
    A5 0x1496B8 (cc.m68k), 0x2C96B8 (cc.a88k): the module's data, 0x20C
    bytes: the hash chains (+0x000), the block free_tle starts at
    (+0x200), the block mu_$alloc_tle starts at (+0x204), the first
    block (+0x208).  The routines that write to standard output reach
    the file through (-4,A5).

  hash_value, end_of_text_chain and copy_body do not load A5 (internal);
  bind_backwards is nested in mu_$bind_params; the others are global
  and load A5.
}
module c_macro_utl;

%include 'lang/lang/source/globals.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_pre_proc.ins.pas';
%include 'lang/c_compiler/source/general_utl.ins.pas';
%include 'lang/c_compiler/source/macro_read.ins.pas';
%include 'lang/c_compiler/source/macro_utl.ins.pas';

type
  { A block of 256 text list elements (PAS_$NEW of 134182 bytes):
    full when its bitmap had no free element at the last search; the
    bitmap is searched a word at a time.

    Not known from the original: the names; the form of the overlay of
    the set and its words. }
  mu_block_ptr_t = ^mu_block_t;
  mu_block_t = record
    next: mu_block_ptr_t;                       { +0 }
    tles: array [0..255] of mu_$tle_t;          { +4 }
    flags: packed record                        { +0x20C04 }
      full: boolean;                            { .15 (`bset #15',
                                                  `tst.b') }
      unused: 0..32767;
    end;
    case integer of                             { +0x20C06 }
      1: (used: set of 0..255);
      2: (used_words: array [0..15] of integer);
  end;

var
  hash_table: array [0..127] of mu_$macro_ptr_t;        { +0x000 }
  free_block: mu_block_ptr_t;                           { +0x200 }
  alloc_block: mu_block_ptr_t;                          { +0x204 }
  first_block: mu_block_ptr_t;                          { +0x208 }

{ hash_value - the chain of name: the sum of its characters mod 128.

  0x058F00, 0x42 bytes: a counted loop summing the bytes (zero-extended)
  into D2; math_mod(sum, 128).

  Not known from the original:
  - the parameters' and locals' names. }

function hash_value(
    len: integer;
    in name: univ pp_$line_t): integer; options(val_param); internal;
var
  h: integer;
  i: integer;
begin
  h := 0;
  for i := 1 to len do
    h := h + ord(name[i]);
  hash_value := math_mod(h, 128);
end;

{ mu_$lookup_name - find the macro called name.

  0x058F42, 0x6E bytes: the chain of hash_value(len, name); for each
  macro str_eql(its name_len, its name (+13), len, name) (0x058F7E); on
  a match m := the macro and true; false at the chain's end.

  Not known from the original:
  - the local's name. }

function mu_$lookup_name(
    len: integer;
    in name: univ pp_$line_t;
    out m: mu_$macro_ptr_t): boolean;
var
  p: mu_$macro_ptr_t;
begin
  p := hash_table[hash_value(len, name)];
  while p <> nil do begin
    if str_eql(p^.name_len, p^.name, len, name) then begin
      m := p;
      mu_$lookup_name := true;
      return;
    end;
    p := p^.next;
  end;
  mu_$lookup_name := false;
end;

{ mu_$enter_name - a new macro called name.

  0x058FB0, 0xA8 bytes: hash_value first; NEW of 4110 bytes (PAS_$NEW
  with 0x100E, 0x058FDC); a nil result writes 'Memory allocation of
  macro DEF buffer failed - check disk space.' (0x05905C, 64
  characters) and a newline to standard output and ends the program
  with severity 5 (pgm_$set_severity, the literal word at 0x059058;
  pgm_$exit).  Then the name (str_copy to +13), body nil, and the macro
  at its chain's head; the result in A0.

  Not known from the original:
  - the locals' names; how the message was written (a writeln of the
    literal). }

function mu_$enter_name(
    len: integer;
    in name: univ pp_$line_t): mu_$macro_ptr_t;
var
  h: integer;
  m: mu_$macro_ptr_t;
begin
  h := hash_value(len, name);
  new(m);
  if m = nil then begin
    writeln('Memory allocation of macro DEF buffer failed - check disk space.');
    pgm_$set_severity(5);
    pgm_$exit;
  end;
  m^.name_len := len;
  str_copy(len, name, m^.name);
  m^.body := nil;
  m^.next := hash_table[h];
  hash_table[h] := m;
  mu_$enter_name := m;
end;

{ mu_$cancel_name - take the macro called name off its chain.

  0x05909C, 0x8C bytes: the chain walked with the previous macro in A3
  (nil first); on a match the macro is unlinked (from the chain's head
  when there is no previous one) and its body's elements are given
  back one by one (mu_$free_tle, the element copied to a frame
  temporary first); the macro itself is not.

  Not known from the original:
  - the locals' names; how the walk was left (return). }

procedure mu_$cancel_name(
    len: integer;
    in name: univ pp_$line_t);
var
  h: integer;
  p, prev: mu_$macro_ptr_t;
  t, q: mu_$tle_ptr_t;
begin
  h := hash_value(len, name);
  p := hash_table[h];
  prev := nil;
  while p <> nil do begin
    if str_eql(p^.name_len, p^.name, len, name) then begin
      if prev = nil then
        hash_table[h] := p^.next
      else
        prev^.next := p^.next;
      t := p^.body;
      while t <> nil do begin
        q := t;
        t := t^.next;
        mu_$free_tle(q);
      end;
      return;
    end;
    prev := p;
    p := p^.next;
  end;
end;

{ mu_$def_macro - define a macro without parameters.

  0x059128, 0xA0 bytes: a name longer than 4096 is reported (error1(197,
  spos_$null_position, idntk(76, name, 4096)), 0x05916E) and clipped
  (the length in a frame word); mu_$enter_name, a body of one element
  (mu_$alloc_tle; str_copy to its text, its length); predefined (+12),
  nparams := -1; true (`st D0').

  Not known from the original:
  - the locals' names. }

function mu_$def_macro(
    name_len: integer;
    in name: univ pp_$line_t;
    body_len: integer;
    in body: univ pp_$line_t;
    predefined: boolean): boolean;
var
  n: integer;
  m: mu_$macro_ptr_t;
begin
  if name_len > 4096 then begin
    error1(197, spos_$null_position, idntk(76, name, 4096));
    n := 4096;
  end
  else
    n := name_len;
  m := mu_$enter_name(n, name);
  m^.body := mu_$alloc_tle;
  str_copy(body_len, body, m^.body^.text);
  m^.body^.len := body_len;
  m^.predefined := predefined;
  m^.nparams := -1;
  mu_$def_macro := true;
end;

{ mu_$initialize - an empty macro table with the predefined macros.

  0x0591C8, 0x240 bytes: the 128 chains nil (`move.l #0' in a `dbf'
  loop); +0x204 and +0x200 nil; with free_blocks the blocks are given
  back (DISPOSE of 134182 bytes, 0x059220) and +0x208 is nil either
  way.  Then, each with predefined true: __LINE__ '0', __FILE__ 'oops',
  __STDC__ '1' when -STDC is on (cargs +0x28B.2, `btst #2'), defined
  'defined', __DATE__ and __TIME__ (mr_date and mr_time between double
  quotes, built in frame buffers at -32 and -16), _APOLLO_SOURCE and
  _BFMT__COFF '1', and by the target's instruction set
  (target_properties +0x10, a jump table at 0x059382) _ISP__M68K,
  _ISP__I860, _ISP__PA_RISC or _ISP__A88K and _ISP__PRISM, '1'.  The
  literals at 0x059408..0x059493.

  Not known from the original:
  - the parameter's and locals' names. }

procedure mu_$initialize(
    free_blocks: boolean);
var
  i: integer;
  b, next: mu_block_ptr_t;
  date: array [1..13] of char;
  time: array [1..10] of char;
  ok: boolean;
begin
  for i := 0 to 127 do
    hash_table[i] := nil;
  alloc_block := nil;
  free_block := nil;
  if free_blocks then begin
    b := first_block;
    while b <> nil do begin
      next := b^.next;
      dispose(b);
      b := next;
    end;
  end;
  first_block := nil;
  ok := mu_$def_macro(8, '__LINE__', 1, '0', true);
  ok := mu_$def_macro(8, '__FILE__', 4, 'oops', true);
  if cargs_$options.stdc then
    ok := mu_$def_macro(8, '__STDC__', 1, '1', true);
  ok := mu_$def_macro(7, 'defined', 7, 'defined', true);
  date[1] := '"';
  str_copy(11, mr_date, date[2]);
  date[13] := '"';
  ok := mu_$def_macro(8, '__DATE__', 13, date, true);
  time[1] := '"';
  str_copy(8, mr_time, time[2]);
  time[10] := '"';
  ok := mu_$def_macro(8, '__TIME__', 10, time, true);
  ok := mu_$def_macro(14, '_APOLLO_SOURCE', 1, '1', true);
  ok := mu_$def_macro(11, '_BFMT__COFF', 1, '1', true);
  case target_properties.p_10 of
    0:
      ok := mu_$def_macro(10, '_ISP__M68K', 1, '1', true);
    1:
      ok := mu_$def_macro(10, '_ISP__I860', 1, '1', true);
    2:
      ok := mu_$def_macro(13, '_ISP__PA_RISC', 1, '1', true);
    3: begin
      ok := mu_$def_macro(10, '_ISP__A88K', 1, '1', true);
      ok := mu_$def_macro(11, '_ISP__PRISM', 1, '1', true);
    end;
    otherwise
  end;
end;

{ mu_$dump - the macro table to standard output.

  0x059494, 0x1AA bytes (PAS_$WRITE and PAS_$WRITELN on the file at
  (-4,A5)): '   Macro Symbol Table Dump' and a line of 29 '-'; then for
  each macro of each chain an empty line, its name (written to its
  length), its parameter list ('(f1', then ',f' and the digit for 2 ..
  nparams, ')'; '()' for none; nothing without parentheses), '  is  "',
  each element's text to its length, '"' and a newline.  The literals
  at 0x05963E.

  Not known from the original:
  - the locals' names; the write statements' exact form. }

procedure mu_$dump;
var
  i, j: integer;
  m: mu_$macro_ptr_t;
  t: mu_$tle_ptr_t;
begin
  writeln('   Macro Symbol Table Dump');
  writeln('-----------------------------');
  for i := 0 to 127 do begin
    m := hash_table[i];
    while m <> nil do begin
      writeln;
      write(m^.name:m^.name_len);
      if m^.nparams > 0 then begin
        write('(f1');
        for j := 2 to m^.nparams do begin
          write(',f');
          write(chr(ord('0') + j));
        end;
        write(')');
      end
      else if m^.nparams = 0 then begin
        write('()');
      end;
      write('  is  "');
      t := m^.body;
      while t <> nil do begin
        write(t^.text:t^.len);
        t := t^.next;
      end;
      write('"');
      writeln;
      m := m^.next;
    end;
  end;
end;

{ mu_$convert_formal - mark formal parameter index in a body.

  0x05968C, 0xB0 bytes: for each element, the identifiers
  str_locate_c_id finds (from 1, the flags false; 0x0596C0) are
  compared with formal (str_eql(formal_len, formal, min(n, 4096),
  text[i]), 0x0596F0); a match becomes the character 128 + index
  (`addi.b #-128') followed by characters 128; the search goes on past
  the identifier, to the next element when none is left.

  Not known from the original:
  - the locals' names; the form of the endless inner loop (repeat
    until false, left with exit). }

procedure mu_$convert_formal(
    index: integer;
    formal_len: integer;
    in formal: univ pp_$line_t;
    list: mu_$tle_ptr_t);
var
  p: mu_$tle_ptr_t;
  i, j, n: integer;
begin
  p := list;
  while p <> nil do begin
    i := 1;
    repeat
      i := str_locate_c_id(i, false, false, false, p^.len, p^.text, n);
      if i = 0 then
        exit;
      if str_eql(formal_len, formal, min(n, 4096), p^.text[i]) then begin
        p^.text[i] := chr(index + 128);
        for j := i + 1 to i + n - 1 do
          p^.text[j] := chr(128);
      end;
      i := i + n;
    until false;
    p := p^.next;
  end;
end;

{ mu_$compress_macro - squeeze a body.

  0x05973C, 0xD6 bytes: each element loses its characters 128 and 254
  (`cmpi.b #-128', `cmpi.b #-2'); then, after the first, it is appended
  to the element being filled when both fit in 512 (longwords, `bge')
  and unlinked, else the element being filled moves on (the previous
  one kept in D4); an element that is not the one being filled is
  given back.  At the end a newline closing the last element the
  filling moved past is dropped.

  Not known from the original:
  - the locals' names. }

procedure mu_$compress_macro(
    in out list: mu_$tle_ptr_t);
var
  prev, cur, p, tmp: mu_$tle_ptr_t;
  i, n: integer;
  c: char;
begin
  prev := nil;
  cur := list;
  p := cur;
  while p <> nil do begin
    n := 0;
    for i := 1 to p^.len do begin
      c := p^.text[i];
      if (c <> chr(128)) and (c <> chr(254)) then begin
        n := n + 1;
        p^.text[n] := c;
      end;
    end;
    p^.len := n;
    if cur = p then
      p := p^.next
    else begin
      if p^.len + cur^.len < mu_$text_max then begin
        str_copy(p^.len, p^.text, cur^.text[cur^.len + 1]);
        cur^.len := cur^.len + p^.len;
        cur^.next := p^.next;
      end
      else begin
        prev := cur;
        cur := cur^.next;
      end;
      if cur = p then
        p := p^.next
      else begin
        tmp := p;
        p := p^.next;
        mu_$free_tle(tmp);
      end;
    end;
  end;
  if prev <> nil then
    if prev^.text[prev^.len] = chr(10) then
      prev^.len := prev^.len - 1;
end;

{ mu_$alloc_tle - a cleared text list element.

  0x059812, 0x1D0 bytes.  The search starts at alloc_block (else the
  first block); full blocks are passed (the last kept in D4); in
  another, the bitmap's words are tried from the 16th down (`cmpi.w
  #-1'), and in a word that is not full its 16 elements in order (`btst'
  on the set); the first free one is added to the set (a 32-byte frame
  set ORed in), its next, len and +8 cleared, alloc_block := the block,
  and its address is the result.  A block with none is marked full;
  when it was alloc_block the search restarts at the first block with
  alloc_block nil.  When every block is full a new one (NEW of 134182
  bytes; a nil result writes 'Memory allocation of macro BLOCK buffer
  failed - check disk space.' and ends the program with severity 5) is
  linked at the end, not full, its set [0] (copied from 0x059A24), its
  first element given out.

  Not known from the original:
  - the locals' names; how the found element was returned (return). }

function mu_$alloc_tle: mu_$tle_ptr_t;
var
  b, last: mu_block_ptr_t;
  w, i: integer;
  t: mu_$tle_ptr_t;
begin
  if alloc_block <> nil then
    b := alloc_block
  else
    b := first_block;
  while b <> nil do begin
    if b^.flags.full then begin
      last := b;
      b := b^.next;
    end
    else begin
      for w := 15 downto 0 do
        if b^.used_words[w] <> -1 then
          for i := (15 - w) * 16 to (15 - w) * 16 + 15 do
            if not (i in b^.used) then begin
              b^.used := b^.used + [i];
              t := addr(b^.tles[i]);
              t^.len := 0;
              t^.next := nil;
              t^.w_8 := 0;
              alloc_block := b;
              mu_$alloc_tle := t;
              return;
            end;
      b^.flags.full := true;
      if b = alloc_block then begin
        b := first_block;
        alloc_block := nil;
      end;
    end;
  end;
  new(b);
  if b = nil then begin
    writeln('Memory allocation of macro BLOCK buffer failed - check disk space.');
    pgm_$set_severity(5);
    pgm_$exit;
  end;
  if first_block = nil then
    first_block := b
  else
    last^.next := b;
  b^.flags.full := false;
  b^.next := nil;
  b^.used := [0];
  b^.tles[0].next := nil;
  b^.tles[0].len := 0;
  b^.tles[0].w_8 := 0;
  alloc_block := b;
  mu_$alloc_tle := addr(b^.tles[0]);
end;

{ mu_$free_tle - give an element back.

  0x059A44, 0x108 bytes: the search starts at free_block (else the
  first block); the block whose first and last elements bound p (signed
  compares of the addresses) has p's number ((p - first) div 524,
  M$DIS$LLW) taken out of its set (a 32-byte frame set, `not.l',
  `and.l'), is no longer full, and becomes free_block; when free_block
  does not have it the search restarts at the first block with
  free_block nil.  An element of no block writes '***INTERNAL ERROR***
  Bad call to MU_FREE_TLE' (0x059B4C); either way p's next and len are
  cleared.

  Not known from the original:
  - the locals' names; how the search was left (goto). }

procedure mu_$free_tle(
    p: mu_$tle_ptr_t);
label
  found;
var
  b: mu_block_ptr_t;
  n: integer;
  first, last: mu_$tle_ptr_t;
begin
  if free_block <> nil then
    b := free_block
  else
    b := first_block;
  n := -1;
  while b <> nil do begin
    first := addr(b^.tles[0]);
    last := addr(b^.tles[255]);
    if (integer32(first) <= integer32(p)) and
       (integer32(last) >= integer32(p)) then begin
      n := (integer32(p) - integer32(first)) div 524;
      b^.used := b^.used - [n];
      b^.flags.full := false;
      free_block := b;
      goto found;
    end;
    if b = free_block then begin
      b := first_block;
      free_block := nil;
    end
    else
      b := b^.next;
  end;
found:
  if n = -1 then begin
    writeln('***INTERNAL ERROR*** Bad call to MU_FREE_TLE');
  end;
  p^.next := nil;
  p^.len := 0;
end;

{ mu_$free_tle_list - give a list back.

  0x059B7A, 0x38 bytes: each element in turn (copied to a frame
  temporary) to mu_$free_tle. }

procedure mu_$free_tle_list(
    p: mu_$tle_ptr_t);
var
  q: mu_$tle_ptr_t;
begin
  while p <> nil do begin
    q := p;
    p := p^.next;
    mu_$free_tle(q);
  end;
end;

{ mu_$find_hash_word - line is '#' word.

  0x059BB2, 0xC0 bytes: false (D4) unless word_len < len and line
  begins with '#'; a for loop over 2..len stops at the first character
  not a blank or tab (the index kept in D2); then str_eql(word_len,
  word, min(word_len, len - p + 1), line[p]) (0x059C22); after the word
  the line must end or not go on with an identifier character (the set
  at 0x059C74: 'a'..'z', 'A'..'Z', '0'..'9', '_', '$'); then true and,
  with strip, str_slide(len, line, p, 1).

  Not known from the original:
  - the locals' names. }

function mu_$find_hash_word(
    in out len: integer;
    in out line: univ pp_$line_t;
    word_len: integer;
    in word: univ pp_$line_t;
    strip: boolean): boolean;
var
  found: boolean;
  p: integer;
begin
  found := false;
  if (word_len < len) and then (line[1] = '#') then begin
    for p := 2 to len do
      if not ((line[p] = ' ') or (line[p] = chr(9))) then
        exit;
    if str_eql(word_len, word, min(word_len, len - p + 1), line[p]) then begin
      p := p + word_len;
      if (p > len) or else
         not (line[p] in ['a'..'z', 'A'..'Z', '0'..'9', '_', '$']) then begin
        found := true;
        if strip then
          str_slide(len, line, p, 1);
      end;
    end;
  end;
  mu_$find_hash_word := found;
end;

{ end_of_text_chain - the last element of a list (nil for none).

  0x059C84, 0x14 bytes: no frame at all (the parameter read at
  (4,SP); docs/rev889-patterns.md 14). }

function end_of_text_chain(
    p: mu_$tle_ptr_t): mu_$tle_ptr_t; options(val_param); internal;
var
  last: mu_$tle_ptr_t;
begin
  last := p;
  while p <> nil do begin
    last := p;
    p := p^.next;
  end;
  end_of_text_chain := last;
end;

{ copy_body - a copy of a list; tail is left at its last element.

  0x059C98, 0x70 bytes: the head in D2 (nil first), tail := nil; for
  each element a new one (mu_$alloc_tle) with its text and length,
  linked after tail.

  Not known from the original:
  - the parameters' and locals' names. }

function copy_body(
    src: mu_$tle_ptr_t;
    out tail: mu_$tle_ptr_t): mu_$tle_ptr_t; internal;
var
  head, t, p: mu_$tle_ptr_t;
begin
  head := nil;
  tail := nil;
  p := src;
  while p <> nil do begin
    t := mu_$alloc_tle;
    str_copy(p^.len, p^.text, t^.text);
    t^.len := p^.len;
    if head = nil then
      head := t
    else
      tail^.next := t;
    tail := t;
    p := p^.next;
  end;
  copy_body := head;
end;

{ mu_$copy_text_list - a copy of a list.

  0x059D08, 0x2E bytes: the result nil first (`suba.l A0,A0'), then
  copy_body unless p is nil (the tail in a frame longword). }

function mu_$copy_text_list(
    p: mu_$tle_ptr_t): mu_$tle_ptr_t;
var
  tail: mu_$tle_ptr_t;
begin
  mu_$copy_text_list := nil;
  if p <> nil then
    mu_$copy_text_list := copy_body(p, tail);
end;

{ mu_$merge_line_tlp - replace text[first..last] by a list.

  0x059D36, 0xDE bytes: with no list, str_slide(len, text, last + 1,
  first) and nil.  Else the tail after last goes to a new element
  linked after the list's end (end_of_text_chain), len := first - 1,
  and the list's elements are appended to text and given back while
  they fit (len + the element's length < 512, longwords, tested with a
  flag in D0 and a branch); the first that does not, or nil, is the
  result.

  Not known from the original:
  - the locals' names. }

function mu_$merge_line_tlp(
    in out len: integer;
    in out text: univ pp_$line_t;
    first: integer;
    last: integer;
    list: mu_$tle_ptr_t): mu_$tle_ptr_t;
var
  n: integer;
  t, q, tmp: mu_$tle_ptr_t;
  more: boolean;
  k: integer;
begin
  if list = nil then begin
    str_slide(len, text, last + 1, first);
    mu_$merge_line_tlp := nil;
    return;
  end;
  n := len - last;
  t := mu_$alloc_tle;
  str_copy(n, text[last + 1], t^.text);
  t^.len := n;
  end_of_text_chain(list)^.next := t;
  len := first - 1;
  q := list;
  more := true;
  k := q^.len;
  while more and then (k + len < mu_$text_max) do begin
    str_copy(k, q^.text, text[len + 1]);
    len := len + k;
    tmp := q;
    q := q^.next;
    mu_$free_tle(tmp);
    if q <> nil then begin
      k := q^.len;
      more := true;
    end
    else
      more := false;
  end;
  mu_$merge_line_tlp := q;
end;

{ mu_$bind_params - m's body with the actuals bound.

  0x059EDC, 0x38 bytes: copy_body of m's body (the tail at (-4,A6)),
  bind_backwards over the copy (the static link in A1), the copy.

  Not known from the original:
  - the locals' names. }

function mu_$bind_params(
    m: mu_$macro_ptr_t;
    nactuals: integer;
    in actuals: mu_$actuals_t): mu_$tle_ptr_t;
var
  tail: mu_$tle_ptr_t;
  body: mu_$tle_ptr_t;

  { bind_backwards - replace the formal parameters of p and the
    elements after it, the last first.

    0x059E14, 0xC8 bytes (nested; reads nactuals (12) and actuals (14)
    and passes tail (-4) of mu_$bind_params's frame): the rest of the
    list first (recursion); then p's characters from the last down: a
    character above 128 (`bls') is formal number c - 128; past
    nactuals it is removed (str_slide), else replaced by a copy of the
    actual (copy_body, mu_$merge_line_tlp(len, text, i, i, copy)), the
    part that did not fit linked in after p.

    Not known from the original:
    - the locals' names. }

  procedure bind_backwards(
      p: mu_$tle_ptr_t); options(val_param);
  var
    i, n: integer;
    copy, rest, e: mu_$tle_ptr_t;
  begin
    if p <> nil then begin
      if p^.next <> nil then
        bind_backwards(p^.next);
      for i := p^.len downto 1 do
        if ord(p^.text[i]) > 128 then begin
          n := ord(p^.text[i]) - 128;
          if n > nactuals then
            str_slide(p^.len, p^.text, i + 1, i)
          else begin
            copy := copy_body(actuals[n], tail);
            rest := mu_$merge_line_tlp(p^.len, p^.text, i, i, copy);
            if rest <> nil then begin
              e := rest;
              while e^.next <> nil do
                e := e^.next;
              e^.next := p^.next;
              p^.next := rest;
            end;
          end;
        end;
    end;
  end;

begin
  body := copy_body(m^.body, tail);
  bind_backwards(body);
  mu_$bind_params := body;
end;
