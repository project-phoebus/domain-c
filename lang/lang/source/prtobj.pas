{ prtobj - PRTOBJ, an IL node printed into a PRTSUB line: identifiers by
  name, constants by value (integers, logicals, characters, strings,
  reals, complexes), types, variables, temporaries, address constants
  and the registers; with `full' the node's kind follows in parentheses.
  Listings, diagnostics and the dumps use it.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0AF478  0x0B0E58  prt_logical
    0x0AF514  0x0B0EF4  add_kind_if_full
    0x0AF55A  0x0B0F3A  prtobj_$prtobj_full
    0x0B08B0  0x0B2290  prtobj
    A5 0x2C33B0 (cc.m68k), 0x443420 (cc.a88k): runbackend's data (the
    unit has none of its own; the global routines load A5 and use
    nothing there).

  prt_logical and add_kind_if_full are nested in prtobj_$prtobj_full and
  take its frame from their dynamic link (docs/rev889-patterns.md 25):
  its s (8) and full (16).

  The nodes are read by offset (il.ins.pas's xp, xl, xw, xc); the kinds
  are numbers.

  Not known from the original: every name but the routines'; the kinds'
  names.
}
module prtobj;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'us/us/ins/cvfp.ins.pas';

type
  { The kind's name add_kind_if_full prints, up to its `)'. }
  prtobj_kind_t = array [1..32] of char;

  prtobj_real_ptr_t = ^real;

{ prtobj_$prtobj_full - obj to the end of s.

  0x0AF55A, 0xFA4 bytes.  nil: '<NIL>'.  With -TREE ADDR (cargs_$options
  .addr, `btst #3,0x2C3665') and a node not of kind 76, its address in
  hexadecimal (prthex, 8) and ':'.  nil again: '<NULL>' (the test
  repeated).  The kinds up to 76 (`cmpi.w #76; bls') and 91, 94, 102,
  103, 104 (a set of 0..111 at 0x0B0700, tested with `btst' for the
  kinds 77..111): 75 'BAD CHAR: ', the character in quotes when
  printable and its code in '<' '>'; the others their name (+16 the
  length, +18 the characters) and '(id)'.  Else a `case' on the kind
  (a table of 162 entries from 73, 0x0AF6B0; kind 73 is in it though
  the test before takes it); the kinds not in it '<KIND ' n '>'.  Each
  path that names its kind ends with add_kind_if_full of the name (one
  `bsr', 0x0B0492); the others end at the epilogue.  The by-address
  arguments of lib_$cv_dfp_out and lib_$cv_sfp_out are pushed as three
  longwords, 20 bytes popped as 18 (docs/rev889-patterns.md 11).

  Not known from the original:
  - the form of the kind tests before the `case' (a set test is
    written; the image's constant holds only 91..104's bits); the
    or-ed compares of kinds 145..147 and 138/143 (written as
    equalities); the quote character kept in a frame byte (-42) for
    kind 92;
  - how a single (kinds 90's halves, integer32 fields in il.ins.pas)
    was passed to lib_$cv_sfp_out: a pointer transfer here. }

procedure prtobj_$prtobj_full(
    in out s: univ prtobj_$line_t;
    obj: univ_ptr;
    full: boolean);
var
  line: ^prtsub_$line_t;
  n: il_$node_ptr_t;
  p: il_$node_ptr_t;
  kind: integer;
  c: char;
  w: integer;
  len: integer;
  d: integer32;
  quote: char;
  buf: array [1..24] of char;
  t: il_$node_ptr_t;

  { prt_logical - '.TRUE.' or '.FALSE.' as v is not 0; with full its
    value in '<' '>' as well.

    0x0AF478, 0x8C bytes: v (8) in D2, full (the parent's (16,A2)) in
    D3; prtcats '.FALSE.' (7) or '.TRUE.' (6); with full ' <', prtint
    (v, 10), '>'. }

  procedure prt_logical(
      v: integer32); options(val_param);
  begin
    if v = 0 then
      prtcats(line^, '.FALSE.', 7)
    else
      prtcats(line^, '.TRUE.', 6);
    if full then begin
      prtcats(line^, ' <', 2);
      prtint(line^, v, 10, false);
      prtcatc(line^, '>');
    end;
  end;

  { add_kind_if_full - with full, kind up to and with its ')'.

    0x0AF514, 0x46 bytes: i from 2 (`moveq #2'; the test at the loop's
    end first) until kind[i] = ')' (`cmpi.b #41'), prtcats(s, kind,
    i). }

  procedure add_kind_if_full(
      in kind_name: univ prtobj_kind_t);
  var
    i: integer32;
  begin
    if full then begin
      i := 2;
      while kind_name[i] <> ')' do
        i := i + 1;
      prtcats(line^, kind_name, i);
    end;
  end;

begin
  line := addr(s);
  n := obj;
  if n = nil then begin
    prtcats(line^, '<NIL>', 5);
    return;
  end;
  if cargs_$options.addr and (n^.kind <> 76) then begin
    prthex(line^, integer32(n), 8);
    prtcatc(line^, ':');
  end;
  if n = nil then begin
    prtcats(line^, '<NULL>', 6);
    return;
  end;
  kind := n^.kind;
  if (kind <= 76) or (kind in [91, 94, 102..104]) then begin
    if kind = 75 then begin
      prtcats(line^, 'BAD CHAR: ', 10);
      c := n^.xc[18];
      if (c >= ' ') and (c <= '~') then begin
        prtcatc(line^, '''');
        prtcatc(line^, c);
        prtcats(line^, ''' ', 2);
      end;
      prtcatc(line^, '<');
      prtint(line^, ord(c), 10, false);
      prtcatc(line^, '>');
    end
    else begin
      prtcats(line^, n^.idnt_name, n^.idnt_len);
      add_kind_if_full('(id)');
    end;
    return;
  end;
  case kind of
    82: begin
      prtint(line^, n^.xl[2], 10, false);
      add_kind_if_full('(long)');
    end;
    85: begin
      prtint(line^, n^.xl[2], 10, false);
      add_kind_if_full('(uns long)');
    end;
    80: begin
      prtint(line^, n^.xl[2], 10, false);
      add_kind_if_full('(short)');
    end;
    83: begin
      prtint(line^, n^.xl[2], 10, false);
      add_kind_if_full('(uns short)');
    end;
    81: begin
      prtint(line^, n^.xl[2], 10, false);
      add_kind_if_full('(integer)');
    end;
    84: begin
      prtint(line^, n^.xl[2], 10, false);
      add_kind_if_full('(uns integer)');
    end;
    200: begin
      prtint(line^, n^.xl[2], 10, false);
      add_kind_if_full('(byte)');
    end;
    86: begin
      prtint(line^, n^.xl[2], 10, false);
      add_kind_if_full('(uns byte)');
    end;
    77: begin
      prt_logical(n^.xl[2]);
      add_kind_if_full('(byte logical)');
    end;
    78: begin
      prt_logical(n^.xl[2]);
      add_kind_if_full('(word logical)');
    end;
    79: begin
      prt_logical(n^.xl[2]);
      add_kind_if_full('(long logical)');
    end;
    87: begin
      w := n^.xw[5];
      if (w < 32) or (w > 126) then begin
        prtcats(line^, 'CHAR <', 6);
        prtint(line^, w, 6, false);
        prtcatc(line^, '>');
      end
      else begin
        prtcatc(line^, '''');
        prtcatc(line^, chr(w));
        prtcatc(line^, '''');
      end;
      add_kind_if_full('(char)');
    end;
    92: begin
      quote := '"';
      len := n^.str_len;
      if n^.str_chars[len] = chr(0) then
        len := len - 1;
      prtcatc(line^, quote);
      prtcats(line^, n^.str_chars, len);
      prtcatc(line^, quote);
    end;
    88: begin
      lib_$cv_dfp_out(buf, n^.real_value, 2, 14, 7, 4, 1, false);
      prtcats(line^, buf, 14);
      add_kind_if_full('(real)');
    end;
    89: begin
      lib_$cv_dfp_out(buf, n^.real_value, 2, 23, 16, 4, 1, false);
      prtcats(line^, buf, 23);
      add_kind_if_full('(dp real)');
    end;
    90: begin
      prtcatc(line^, '(');
      lib_$cv_sfp_out(buf, prtobj_real_ptr_t(addr(n^.pair_a))^,
                      2, 14, 7, 4, 1, false);
      prtcats(line^, buf, 14);
      prtcatc(line^, ',');
      lib_$cv_sfp_out(buf, prtobj_real_ptr_t(addr(n^.pair_b))^,
                      2, 14, 7, 4, 1, false);
      prtcats(line^, buf, 14);
      prtcatc(line^, ')');
      add_kind_if_full('(complex)');
    end;
    198: begin
      prtcatc(line^, '(');
      lib_$cv_dfp_out(buf, n^.dcx_re, 2, 23, 16, 4, 1, false);
      prtcats(line^, buf, 14);
      prtcatc(line^, ',');
      lib_$cv_dfp_out(buf, n^.dcx_im, 2, 23, 16, 4, 1, false);
      prtcats(line^, buf, 14);
      prtcatc(line^, ')');
      add_kind_if_full('(dp complex)');
    end;
    184:
      prtobj(line^, n^.xp[2]^.xp[10]);
    212:
      prtcats(line^, '<namelist descriptor>', 21);
    156:
      prtcats(line^, '<set constant>', 14);
    110: begin
      prtcats(line^, n^.xc[72], n^.xw[35]);
      add_kind_if_full('(fsym)');
    end;
    111: begin
      prtobj(line^, n^.xp[1]);
      add_kind_if_full('(common)');
    end;
    116: begin
      prtobj(line^, n^.xp[1]);
      add_kind_if_full('(const name)');
    end;
    118: begin
      prtobj(line^, n^.xp[1]);
      add_kind_if_full('(type name)');
    end;
    117: begin
      prtobj(line^, n^.xp[1]);
      add_kind_if_full('(label)');
    end;
    109:
      if n^.xp[1] <> nil then begin
        prtobj(line^, n^.xp[1]);
        add_kind_if_full('(varn)');
      end
      else begin
        prtcats(line^, '<anonymous variable #', 21);
        prtint(line^, n^.xw[37], 6, false);
        prtcats(line^, ', size= ', 8);
        prtint(line^, n^.xl[9], 6, false);
        prtcats(line^, ' bits>', 6);
      end;
    119: begin
      prtobj(line^, n^.xp[2]);
      add_kind_if_full('(pfield)');
    end;
    120: begin
      prtobj(line^, n^.xp[2]);
      add_kind_if_full('(field)');
    end;
    107: begin
      prtobj(line^, n^.xp[74]);
      add_kind_if_full('(proc)');
    end;
    108: begin
      prtobj(line^, n^.xp[74]);
      add_kind_if_full('(func)');
    end;
    172: begin
      prtobj(line^, n^.xp[74]);
      add_kind_if_full('(inner_blk)');
    end;
    106: begin
      prtobj(line^, n^.xp[74]);
      add_kind_if_full('(module)');
    end;
    105: begin
      prtobj(line^, n^.xp[74]);
      add_kind_if_full('(program)');
    end;
    167: begin
      prtobj(line^, n^.xp[74]);
      add_kind_if_full('(fortran alternate entry)');
    end;
    209: begin
      prtobj(line^, n^.xp[74]);
      add_kind_if_full('(blkdata)');
    end;
    145, 146, 147: begin
      w := n^.xp[6]^.kind;
      if (w = 138) or (w = 147) or (w = 146) then
        prtcatc(line^, '~');
      if n^.xp[7] <> nil then begin
        p := n^.xp[7];
        w := p^.kind;
        if (w = 122) or (w = 174) or (w = 173) then
          prtcats(line^, '<*>', 3)
        else if w >= 76 then
          prtobj(line^, p);
      end;
    end;
    164: begin
      t := n^.xp[5];
      prtcatc(line^, '~');
      prtobj(line^, t);
      add_kind_if_full('(cs_node)');
    end;
    157: begin
      prtcatc(line^, '=');
      prtint(line^, n^.xl[4], 10, false);
      add_kind_if_full('(def_const)');
    end;
    152: begin
      prtcatc(line^, 'T');
      prtcatc(line^, '$');
      prtint(line^, n^.xl[1], 5, true);
      add_kind_if_full('(alloc_temp)');
    end;
    138, 143:
      if (n^.xw[18] = 16) and (n^.xw[12] = 9) then
        prtobj(line^, n^.xp[11])
      else begin
        prtcatc(line^, 'T');
        prtcatc(line^, '$');
        p := n^.xp[10];
        if p^.kind = 152 then
          prtint(line^, p^.xl[1], 5, true)
        else
          prtint(line^, integer32(p), 6, true);
      end;
    144: begin
      prtcatc(line^, chr((ord(n^.xc[72]) div 2) mod 32 + ord('A')));
      prtcatc(line^, '$');
      prtint(line^, n^.xw[24], 4, true);
    end;
    159: begin
      prtcats(line^, n^.xc[12 + 2 * n^.xw[5]], n^.xw[4]);
      add_kind_if_full('(lib_dsc)');
    end;
    208: begin
      prtcats(line^, n^.xc[50], ord(n^.xc[49]));
      add_kind_if_full('(at_lib_dsc)');
    end;
    163: begin
      prtcats(line^, '->', 2);
      d := n^.xl[3];
      if n^.xc[20] = chr(0) then
        prtcats(line^, '/XSB/', 5)
      else if n^.xc[20] = chr(1) then begin
        d := d + n^.xp[2]^.xl[5];
        prtcats(line^, '/DB/', 4);
      end
      else
        prtobj(line^, n^.xp[2]);
      if d <> 0 then begin
        if d > 0 then
          prtcatc(line^, '+');
        prtint(line^, d, 10, false);
      end;
      add_kind_if_full('(addr_con)');
    end;
    195: begin
      prtcats(line^, '->', 2);
      prtobj(line^, n^.xp[3]);
      d := n^.xl[4];
      if d <> 0 then begin
        if d > 0 then
          prtcatc(line^, '+');
        prtint(line^, d, 10, false);
      end;
      add_kind_if_full('(reloc_abs_addr_con)');
    end;
    165: begin
      prtcats(line^, 'CS$', 3);
      prtint(line^, integer32(n), 6, true);
      add_kind_if_full('(cs_temp)');
    end;
    210:
      prtcats(line^, '<void>', 6);
    122: begin
      prtcatc(line^, '<');
      if ord(n^.xc[6]) < 128 then
        prtcats(line^, 'unsigned ', 9);
      if n^.xw[2] = 1 then
        prtcats(line^, 'char', 4)
      else if n^.xw[2] = 2 then
        prtcats(line^, 'short int', 9)
      else if n^.xw[2] = 4 then
        prtcats(line^, 'long int', 8)
      else if n^.xw[2] = 5 then
        prtcats(line^, 'address', 7)
      else begin
        prtcats(line^, 'rlen=', 5);
        prtint(line^, n^.xw[2], 10, false);
      end;
      prtcatc(line^, '>');
    end;
    123:
      if n^.xw[2] = 6 then
        prtcats(line^, '<float>', 7)
      else
        prtcats(line^, '<double>', 8);
    129: begin
      p := n^.xp[5];
      if p^.xw[2] = 4 then
        prtcats(line^, '<enum>', 6)
      else if p^.xw[2] = 2 then
        prtcats(line^, '<short enum>', 12)
      else if p^.xw[2] = 1 then
        prtcats(line^, '<char enum>', 11);
    end;
    130: begin
      prtcats(line^, '<pointer to ', 12);
      prtobj_$prtobj_full(line^, n^.xp[1], full);
      prtcatc(line^, '>');
    end;
    127, 131: begin
      prtcats(line^, '<array of ', 10);
      prtobj_$prtobj_full(line^, n^.xp[1], full);
      prtcatc(line^, '>');
    end;
    132:
      prtcats(line^, '<record/struct type>', 20);
    234: begin
      prtcats(line^, '<function returning ', 20);
      prtobj_$prtobj_full(line^, n^.xp[2], full);
      prtcatc(line^, '>');
    end;
    73:
      prtcats(line^, 'erroneous entity', 16);
    154:
      prtcats(line^, '<DB_REGISTER>', 13);
    226:
      prtcats(line^, '<EXCEPTION_REGISTER>', 20);
    153:
      prtcats(line^, '<SF/SB_REGISTER>', 16);
    155:
      prtcats(line^, '<SL/DISPLAY_REGISTER>', 21);
    211:
      prtcats(line^, '<AP(ARGUMENT)_REGISTER>', 23);
    182, 183: begin
      prtcatc(line^, '|');
      prtobj(line^, n^.xp[2]);
      prtcatc(line^, '|');
    end;
    192: begin
      prtcats(line^, '<transfer vector> ', 18);
      prtobj(line^, n^.xp[2]);
    end;
    194: begin
      prtcats(line^, '<external reference> ', 21);
      prtobj(line^, n^.xp[2]);
    end;
    204: begin
      prtcats(line^, '<ARGUMENT_BLOCK_LOCATION>+', 26);
      prtint(line^, n^.xl[1], 10, false);
    end;
    203: begin
      case n^.xw[2] of
        0: prtcatc(line^, '.');
        1: prtcats(line^, '.FS', 3);
        2: prtcats(line^, '.FD', 3);
        3: prtcats(line^, '.FQ', 3);
        4: prtcats(line^, 'ArgBlock', 8);
        otherwise begin
          prtcats(line^, 'ord(loc)=', 9);
          prtint(line^, n^.xw[2], 10, false);
          prtcats(line^, ',reg=', 5);
        end;
      end;
      prtint(line^, n^.xw[3], 10, false);
      if full then
        add_kind_if_full('(PHYSICAL_REGISTER)');
    end;
    otherwise begin
      prtcats(line^, '<KIND ', 6);
      prtint(line^, kind, 10, false);
      prtcatc(line^, '>');
    end;
  end;
end;

{ prtobj - prtobj_$prtobj_full(s, obj, false).

  0x0B08B0, 0x2C bytes (`clr.w -(SP)' for full). }

procedure prtobj;
begin
  prtobj_$prtobj_full(s, obj, false);
end;
