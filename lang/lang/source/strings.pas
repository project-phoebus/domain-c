{ strings - STRINGS, byte strings and the identifier table: comparing
  (with or without case, the shorter string taken as padded with blanks),
  comparing and copying n bytes, and IDNTK, which gives the one entry of
  each identifier, entering it when it is new.  The table is 256 hash
  chains, an identifier's hash the sum of its bytes mod 256.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0987BC  0x09A19C  compare_bytes_case (internal)
    0x0988A0  0x09A280  compare_bytes
    0x0988DC  0x09A2BC  strings_$compare_bytes_nocase
    0x098918  0x09A2F8  strings_$memcmp
    0x098970  0x09A350  strings_$memmove
    0x0989A4  0x09A384  strings_$memcpy
    0x0989D6  0x09A3B6  idntk
    A5 0x19DB8C (cc.m68k): the module's data, 0x400 bytes (to time's): the
    hash table.

  The global routines load A5; compare_bytes_case, which does not, is
  internal.
}
module strings;

%include 'lang/lang/source/globals.ins.pas';

var
  { +0: the identifier entries, chained by hash. }
  idnt_table: array [0..255] of il_$node_ptr_t;

{ compare_bytes_case - a (alen characters) against b (blen): -1, 0 or 1,
  with a-z taken as A-Z when nocase; the shorter taken as padded with
  blanks.

  0x0987BC, 0xD2 bytes, internal.  n := alen or blen, the smaller (a
  frame word at (-22,A6)); i (D2) from 1 while i <= n: a's and b's bytes
  (both by pointers stepped each pass), when nocase each less 32 if in
  ['a'..'z'] (the set constant at 0x098890, 16 bytes: members 0..127);
  unequal bytes give -1 when a's is lower (`bcc': unsigned), else 1.
  Then when alen > blen (and alen > 0) the rest of a is compared with
  blanks (a lower byte -1, a higher 1), when blen > alen (and blen > 0)
  the rest of b (the other way round); else 0.

  Not known from the original:
  - the parameter and local names; whether the bytes were indexed or
    reached by pointers (the optimizer steps pointers either way). }

function compare_bytes_case(
    in a: univ strings_$bytes_t;
    alen: integer;
    in b: univ strings_$bytes_t;
    blen: integer;
    nocase: boolean): integer; internal;
var
  n: integer;
  i: integer;
  ca, cb: char;
begin
  n := alen;
  if n > blen then
    n := blen;
  i := 1;
  while i <= n do begin
    ca := a[i];
    cb := b[i];
    if nocase then begin
      if ca in ['a'..'z'] then
        ca := chr(ord(ca) - 32);
      if cb in ['a'..'z'] then
        cb := chr(ord(cb) - 32);
    end;
    if ca <> cb then begin
      if ca < cb then
        compare_bytes_case := -1
      else
        compare_bytes_case := 1;
      return;
    end;
    i := i + 1;
  end;
  if alen > blen then begin
    while i <= alen do begin
      if a[i] <> ' ' then begin
        if a[i] < ' ' then
          compare_bytes_case := -1
        else
          compare_bytes_case := 1;
        return;
      end;
      i := i + 1;
    end;
  end
  else if alen < blen then begin
    while i <= blen do begin
      if b[i] <> ' ' then begin
        if b[i] > ' ' then
          compare_bytes_case := -1
        else
          compare_bytes_case := 1;
        return;
      end;
      i := i + 1;
    end;
  end;
  compare_bytes_case := 0;
end;

{ compare_bytes - compare_bytes_case with case.

  0x0988A0, 0x3C bytes: compare_bytes_case(a, alen, b, blen, false)
  (`clr.w -(SP)': false in a word slot; the 14 bytes of arguments padded
  to 16). }

function compare_bytes(
    in a: univ strings_$bytes_t;
    alen: integer;
    in b: univ strings_$bytes_t;
    blen: integer): integer;
begin
  compare_bytes := compare_bytes_case(a, alen, b, blen, false);
end;

{ strings_$compare_bytes_nocase - compare_bytes_case without case.

  0x0988DC, 0x3C bytes: as compare_bytes with `st -(SP)'. }

function strings_$compare_bytes_nocase(
    in a: univ strings_$bytes_t;
    alen: integer;
    in b: univ strings_$bytes_t;
    blen: integer): integer;
begin
  strings_$compare_bytes_nocase := compare_bytes_case(a, alen, b, blen, true);
end;

{ strings_$memcmp - the first difference of n bytes, or 0.

  0x098918, 0x58 bytes: a `for' over n (a 32-bit `dbf' loop); at the
  first unequal byte the result is a's byte less b's, both zero-extended
  to longwords. }

function strings_$memcmp(
    in a: univ strings_$bytes_t;
    in b: univ strings_$bytes_t;
    n: integer32): integer32;
var
  i: integer32;
begin
  for i := 1 to n do
    if a[i] <> b[i] then begin
      strings_$memcmp := ord(a[i]) - ord(b[i]);
      return;
    end;
  strings_$memcmp := 0;
end;

{ strings_$memmove - n bytes from src to dst, first to last.

  0x098970, 0x34 bytes: `move.b (A1)+,(A0)+' in a 32-bit `dbf' loop: not
  safe for a dst overlapping src from above, whatever the name says. }

procedure strings_$memmove(
    out dst: univ strings_$bytes_t;
    in src: univ strings_$bytes_t;
    n: integer32);
var
  i: integer32;
begin
  for i := 1 to n do
    dst[i] := src[i];
end;

{ strings_$memcpy - strings_$memmove.

  0x0989A4, 0x32 bytes: the arguments passed on (`bsr' 0x0989C4). }

procedure strings_$memcpy(
    out dst: univ strings_$bytes_t;
    in src: univ strings_$bytes_t;
    n: integer32);
begin
  strings_$memmove(dst, src, n);
end;

{ idntk - the identifier entry of the len characters s, entered with
  kind when new.

  0x0989D6, 0xB6 bytes.  The hash (D3, a byte) is the sum of s's bytes
  (a `for' over len, `add.b (A0)+,D3'); its chain (idnt_table, the
  hash times 4 off A5) is searched for an entry of len characters
  (+16) that strings_$memcmp (0x098A20) finds equal to s (+18): the
  first is the result.  Else a new entry of len + 18 bytes (gspace,
  0x098A46) gets kind at +2, 0 at +8 and +12, is put at the head of the
  chain, gets len at +16 and s copied to +18 (strings_$memmove,
  0x098A7A).

  Not known from the original:
  - the locals' names; the image keeps the comparison's outcome in a
    byte (`seq D5; tst.b D5') before testing it. }

function idntk(
    kind: integer;
    in s: univ strings_$bytes_t;
    len: integer): il_$node_ptr_t;
var
  hash: 0..255;
  i: integer;
  p: il_$node_ptr_t;
  found: boolean;
begin
  hash := 0;
  for i := 1 to len do
    hash := (hash + ord(s[i])) mod 256;
  p := idnt_table[hash];
  while p <> nil do begin
    if p^.idnt_len = len then begin
      found := strings_$memcmp(p^.idnt_name, s, len) = 0;
      if found then begin
        idntk := p;
        return;
      end;
    end;
    p := p^.idnt_next;
  end;
  p := gspace(len + 18);
  p^.kind := kind;
  p^.idnt_unused_8 := 0;
  p^.idnt_unused_12 := 0;
  p^.idnt_next := idnt_table[hash];
  idnt_table[hash] := p;
  p^.idnt_len := len;
  strings_$memmove(p^.idnt_name, s, len);
  idntk := p;
end;
