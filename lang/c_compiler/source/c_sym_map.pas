{ c_sym_map - the symbol map of the listing (-MAP, -IMAP, -ACMAP): one
  line for each block (its number, name, kind, procedure address, ECB,
  stack size and sections), then each identifier of the main source
  file in alphabetical order with its meanings (variables with their
  allocation, attributes and type; constants, labels, typedefs), and
  with -ACMAP the address constants.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x060584  0x060804  sym_map
    0x05F294  0x05F514  print_10
    0x05F2C0  0x05F540  print_con
    0x05F37A  0x05F5FA  tattr_to_vattr
    0x05F39E  0x05F61E  print_attr
    0x05F59C  0x05F81C  print_type
    0x05FB4A  0x05FDCA  print_block
    0x05FDD6  0x060056  print_vat
    0x05FF4C  0x0601CC  print_ac_key
    0x0600B8  0x060338  print_ac_ref
    0x0601BE  0x06043E  print_addr_cons
    A5 0x14AC94 (cc.m68k), 0x2CAC94 (cc.a88k): the module has no data;
    the address is c_syntax's (the next module's), and sym_map uses
    nothing of it.

  sym_map is global (c_main's cc calls it) and loads A5; the others
  are nested in it and print into its line (-264,A6), reached through
  A1 (print_block and print_addr_cons, called only by sym_map, take
  its frame from their own dynamic link).

  IL nodes the prelude does not name yet (blocks, sections, address
  constants) are read through il.ins.pas's views by offset (xp, xl,
  xw, xc; docs/questions.md 13).
}
module c_sym_map;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';

{ sym_map - the map.

  0x060584, 0x42C bytes, link #-340.  The locals: the line (-264, a
  PRTSUB line), the -MAP# counter (-272, cleared first), the byte
  print_type keeps whether a structure was printed before in (-298)
  and the attributes tattr_to_vattr converts a typedef's into (-340).

  First ejctln, and each block on il_184's chain (+4) whose 2-bit field
  at +376 (`andi.w #0x180; lsr.w #7') is 0 is numbered (+288, a word
  counted in D2) and printed (print_block).  Then ejctln, and for each
  identifier sortidentifiers returns (chained by idnt_next), each
  symbol on its chain (+8, linked by +12):

  - a variable (109) is shown unless flag 14 is set, its name is one
    of the four identifiers cc made (end_of_for, end_of_while, `@',
    <string-constant>; `cmpa.l abs.l'), its type is a procedure or
    function (108, 107), it is extern (vat 3) outside the main source
    file (`not.b' of spos_$line_is_in_main_source_file's result, `seq'
    and `and.b': both evaluated), or its block is nil, il_184 or
    il_178 (tested in turn, `or else'); the block printed is the one
    enclosing any kind 172 scopes (+8);
  - any other symbol is shown when it is in the main source file and
    its block is not il_184.

  A line: the block's number (prtint, 3 digits, zero filled), a blank,
  the identifier, a blank, blanks to column 12 (`cmpi.w #12; bcs',
  after at least one), then by kind (a jump table over 109..118):
  var( with extern, or the offset (+56) plus the external section's
  offset (vat 7, 8: the block's data section's +20) or the frame's
  (vat 6: the block's +112 less its +176), signed, in 6 hexadecimal
  digits, `/' and S (vat 2, 6), A (5), the section's name (10) or D,
  then `): ', the attributes and the type (print_type, indent 2);
  const= and the value; label( and the label's address/P or ------,
  `)'; typedef= with the converted attributes and the type (indent 6);
  else prtobj of the symbol.  Last, with -ACMAP (cargs +0x27B bit 6),
  print_addr_cons.

  Not known from the original:
  - the locals' names; whether the vat tests were a case statement
    (the image compares in turn: 3, then 7, 8, 6, then 2, 6, 5, 10);
  - how the +376 field was declared (a packed field of a block
    record). }

procedure sym_map;
var
  vattr: c_attr_t;                      { -340 }
  seen: boolean;                        { -298 }
  map_count: integer32;                 { -272 }
  line: prtsub_$line_t;                 { -264 }
  n: integer;
  b, blk, ids: il_$node_ptr_t;
  sym: c_sym_ptr_t;
  show: boolean;
  off: integer32;

  { print_10 - n characters of s to the line.

    0x05F294, 0x2C bytes: prtcats(line, s, n), the line through A1.

    Not known from the original:
    - the parameters' names; why the name. }

  procedure print_10(
      in s: univ prtsub_$chars_t;
      n: integer); options(val_param);
  begin
    prtcats(line, s, n);
  end;

  { print_con - the constant c of type t: for an enumeration (129),
    the name of its constant of c's value with the value in braces,
    or il_178 when none has it; else c.

    0x05F2C0, 0xBA bytes.  The value is c's +8 (int_value); a `dbf'
    loop over the enumeration's +6 constants (the list at +16, from 1)
    skips il_178 entries and compares each constant's value node's +8
    (`cmp.l (8,A4),D2'); the first match is printed (+4, the name) and
    returns.

    Not known from the original:
    - the parameters' and locals' names. }

  procedure print_con(
      t: c_type_ptr_t;
      c: il_$node_ptr_t); options(val_param);
  var
    i: integer;
    v: integer32;
    e: il_$node_ptr_t;
  begin
    if t^.kind = 129 then begin
      v := c^.int_value;
      for i := 1 to t^.enum_count do begin
        e := t^.enum_list^[i];
        if e <> il_178 then
          if c_sym_ptr_t(e)^.con_value^.int_value = v then begin
            prtobj(line, c_sym_ptr_t(e)^.name);
            prtcatc(line, '{');
            prtint(line, v, 10, false);
            prtcatc(line, '}');
            return;
          end;
      end;
      prtobj(line, il_178);
    end
    else
      prtobj(line, c);
  end;

  { tattr_to_vattr - a typedef's attributes t in a variable's form v.

    0x05F37A, 0x24 bytes, no frame (docs/rev889-patterns.md 14): v at
    (4,SP), t at (8,SP); v+0 := t+4, v+4 := t+0, v+8 := t+10, v+10 :=
    t+8, v+12 := t+12.

    Not known from the original:
    - the parameters' names; the two forms' declarations (c_objtype's
      c_attr_t). }

  procedure tattr_to_vattr(
      out v: c_attr_t;
      in t: c_attr_t);
  begin
    v.other_bits := t.bits;
    v.bits := t.other_bits;
    v.align := t.unused_10;
    v.unused_10 := t.align;
    v.unused_12 := t.unused_12;
  end;

  { print_attr - the attributes: Aligned([natural-]n) when a's +4 has
    12 or 13 (`andi.l #0x3000'), then Volatile, Const, Atomic, the
    Device forms and Uplevel Addressed from flags (by value) or a's
    bits.

    0x05F39E, 0x190 bytes.  Aligned( and natural- (13: `btst #13' of
    the word at +6), the alignment (+8, prtint width 2), `) '; Volatile
    for flags 0 or a 0 (`btst #0,(7,A2)'), Const for flags 31 (`tst.l;
    bmi') or a 19, Atomic for flags 1 or a 2; Device(Read,Write) for
    (flags 3 or a 3) and (flags 4 or a 4), else Device(Read), else
    Device(Write); Uplevel Addressed for flags 8.  Each test branches
    as soon as it is decided (`or else', `and then').

    Not known from the original:
    - the parameters' names; the bits' names. }

  procedure print_attr(
      flags: c_flags_t;
      in a: c_attr_t); options(val_param);
  begin
    if (a.bits * [12, 13]) <> [] then begin
      prtcats(line, 'Aligned(', 8);
      if 13 in a.bits then
        prtcats(line, 'natural-', 8);
      prtint(line, a.align, 2, false);
      prtcats(line, ') ', 2);
    end;
    if (0 in flags) or else (0 in a.bits) then
      prtcats(line, 'Volatile ', 9);
    if (31 in flags) or else (19 in a.bits) then
      prtcats(line, 'Const ', 6);
    if (1 in flags) or else (2 in a.bits) then
      prtcats(line, 'Atomic ', 7);
    if ((3 in flags) or else (3 in a.bits)) and then
       ((4 in flags) or else (4 in a.bits)) then
      prtcats(line, 'Device(Read,Write) ', 19)
    else if (3 in flags) or else (3 in a.bits) then
      prtcats(line, 'Device(Read) ', 13)
    else if (4 in flags) or else (4 in a.bits) then
      prtcats(line, 'Device(Write) ', 14);
    if 8 in flags then
      prtcats(line, 'Uplevel Addressed ', 18);
  end;

  { print_type - the type t; a structure's fields go on lines of their
    own, indented indent + 2.

    0x05F59C, 0x52A bytes.  A kind 121 is looked through (+16).  Then
    a compare chain on the kind: 122 char, short int (len 2) or long
    int; 123 float (len 6) or double; 234 func ret and the result
    (+8); 128 low..high (print_con of the base, +4, with +8 and +12);
    129 short enum (the integral type +20 is short_type) or long enum,
    then the constants' names in parentheses, separated by commas,
    the line written and refilled with blanks to the column after
    the `(' when it is longer than 66 (`cmpi.w #66; bls'); 130 ptr to,
    the attributes (+12) and the target (+4); 127 and 131 array[, the
    index type (+8), `] of ', the attributes (+16), the element (+4);
    134 set of and the base; 118 the typedef's name (+4); 132
    struct/union( size `)', -MAP# and its number (+44, given from the
    counter the first time), then, the first time only, each field
    (+4, by +4) not named `@' (id_at) on a new line: its name, blanks
    to column indent + 12 (a longword compare, the length
    zero-extended), (offset[,width,position,s or u] (a bit field, 120:
    +48 bits 5..0, +49, +48 bit 6), the attributes (+20, +24) and the
    type (+16) at indent + 2; 107 procedure; 108 function; else
    prtobj.

    Not known from the original:
    - the parameters' and locals' names; whether the chain was a case
      statement (written so here: no two labels share code but 127
      and 131). }

  procedure print_type(
      t: c_type_ptr_t;
      indent: integer); options(val_param);
  var
    i, j: integer;
    start: integer;
    inner: integer;
    col: integer32;
    f: c_field_ptr_t;
    e: il_$node_ptr_t;
  begin
    if t^.kind = 121 then
      t := t^.wrap_type;
    case t^.kind of
      122:
        if t^.len = 1 then
          print_10('char', 4)
        else if t^.len = 2 then
          print_10('short int', 9)
        else
          print_10('long int', 8);
      123:
        if t^.len = 6 then
          print_10('float', 5)
        else
          print_10('double', 6);
      234: begin
        print_10('func ret ', 9);
        print_type(t^.fn_result, indent);
      end;
      128: begin
        print_con(t^.sub_base, t^.sub_low);
        prtcatc(line, '.');
        prtcatc(line, '.');
        print_con(t^.sub_base, t^.sub_high);
      end;
      129: begin
        if t^.enum_int = short_type then
          print_10('short enum ', 11)
        else
          print_10('long enum ', 10);
        prtcatc(line, '(');
        start := line.length;
        if t^.enum_count = 0 then
          prtcatc(line, ')')
        else
          for i := 1 to t^.enum_count do begin
            if line.length > 66 then begin
              listln(line);
              for j := 1 to start do
                line.body[j] := ' ';
              line.length := start;
            end;
            e := t^.enum_list^[i];
            if e <> il_178 then
              prtobj(line, c_sym_ptr_t(e)^.name)
            else
              prtobj(line, il_178);
            if i = t^.enum_count then
              prtcatc(line, ')')
            else
              prtcatc(line, ',');
          end;
      end;
      130: begin
        print_10('ptr to ', 7);
        print_attr([], t^.ptr_attr);
        print_type(t^.ptr_to, indent);
      end;
      127, 131: begin
        print_10('array[', 6);
        print_type(t^.arr_index, indent);
        print_10('] of ', 5);
        print_attr([], t^.arr_attr);
        print_type(t^.arr_elem, indent);
      end;
      134: begin
        print_10('set of ', 7);
        print_type(t^.set_base, indent);
      end;
      118:
        prtobj(line, t^.tn_name);
      132: begin
        print_10('struct/union(', 13);
        prtint(line, t^.su_size, 10, false);
        prtcatc(line, ')');
        if t^.su_map = 0 then begin
          seen := false;
          map_count := map_count + 1;
          t^.su_map := map_count;
        end
        else
          seen := true;
        print_10('-MAP#', 5);
        prtint(line, t^.su_map, 10, false);
        if not seen then begin
          col := indent + 12;
          f := t^.su_fields;
          while f <> nil do begin
            if f^.name <> id_at then begin
              listln(line);
              inner := indent + 2;
              for j := 1 to inner do
                line.body[j] := ' ';
              line.length := inner;
              prtobj(line, f^.name);
              prtcatc(line, ' ');
              repeat
                prtcatc(line, ' ');
              until line.length >= col;
              prtcatc(line, '(');
              prtint(line, f^.offset, 10, false);
              if f^.kind = 120 then begin
                prtcatc(line, ',');
                prtint(line, f^.bits.width, 2, false);
                prtcatc(line, ',');
                prtint(line, f^.bits.at, 2, false);
                prtcatc(line, ',');
                if f^.bits.signed then
                  prtcatc(line, 's')
                else
                  prtcatc(line, 'u');
              end;
              prtcatc(line, ')');
              prtcatc(line, ' ');
              print_attr(f^.flags, f^.attr);
              print_type(f^.ftype, inner);
            end;
            f := f^.next;
          end;
        end;
      end;
      107:
        print_10('procedure', 9);
      108:
        print_10('function', 8);
      otherwise
        prtobj(line, t);
    end;
  end;

  { print_block - the block b's line, unless it is an inner scope
    (172).

    0x05FB4A, 0x24C bytes.  The line emptied; the number (+288, prtint
    3 digits zero filled), the name (+296), the kind (a jump table over
    105..108: program, module, procedure, function), `('; for all but a
    module: Proc = and the procedure's address (+100's +56 when it is a
    placed label, 144, else ------), Ecb = the block's +108 less its
    data section's +16 (6 hexadecimal digits), Stack Size = minus +80
    (prtint width 8); then Psect = and Dsect = the names (+8) of the
    sections at +188 and +192, `)', and the line written.

    Not known from the original:
    - the parameter's and local's names. }

  procedure print_block(
      b: il_$node_ptr_t); options(val_param);
  var
    p: il_$node_ptr_t;
  begin
    line.length := 0;
    if b^.kind <> 172 then begin
      prtint(line, b^.xw[144], 3, true);
      prtcatc(line, ' ');
      prtobj(line, b^.xp[74]);
      prtcatc(line, ' ');
      case b^.kind of
        105: print_10('program', 7);
        106: print_10('module', 6);
        107: print_10('procedure', 9);
        108: print_10('function', 8);
      end;
      prtcatc(line, '(');
      if b^.kind <> 106 then begin
        print_10('Proc = ', 7);
        p := b^.xp[25];
        if p^.kind = 144 then
          prthex(line, p^.xl[14], 6)
        else
          print_10('------', 6);
        prtcatc(line, ',');
        print_10('Ecb = ', 6);
        prthex(line, b^.xl[27] - b^.xp[48]^.xl[4], 6);
        prtcatc(line, ',');
        print_10('Stack Size', 10);
        print_10(' = ', 3);
        prtint(line, -b^.xl[20], 8, false);
        prtcatc(line, ',');
      end;
      print_10('Psect = ', 8);
      prtobj(line, b^.xp[47]^.xp[2]);
      prtcatc(line, ',');
      print_10('Dsect = ', 8);
      prtobj(line, b^.xp[48]^.xp[2]);
      prtcatc(line, ')');
      listln(line);
    end;
  end;

  { print_vat - `, vat=' and the allocation's name (9 characters).

    0x05FDD6, 0xF8 bytes: a jump table over 0..11 (`cmpi.w #12; bcc'
    past the end).

    Not known from the original:
    - the parameter's name. }

  procedure print_vat(
      vat: c_vat_t); options(val_param);
  begin
    prtcats(line, ', vat=', 6);
    case vat of
      vat_local: prtcats(line, 'local    ', 9);
      vat_stat: prtcats(line, 'stat     ', 9);
      vat_dynm: prtcats(line, 'dynm     ', 9);
      vat_ext: prtcats(line, 'ext      ', 9);
      vat_extdef: prtcats(line, 'extdef   ', 9);
      vat_param: prtcats(line, 'param    ', 9);
      vat_xdynm: prtcats(line, 'xdynm    ', 9);
      vat_xstat: prtcats(line, 'xstat    ', 9);
      vat_xextdef: prtcats(line, 'xextdef  ', 9);
      vat_based: prtcats(line, 'based    ', 9);
      vat_sect: prtcats(line, 'sect     ', 9);
      vat_abs: prtcats(line, 'abs      ', 9);
    end;
  end;

  { print_ac_key - `, key=' and an address constant's key (9
    characters): 0 xsb, 1 xdb, 2 ext, 3 comm, 4 xproc_arg, 5
    lproc_arg, 6 proc, 7 jmp, 8 nil, 9 lproc, 10 db, 11 str.

    0x05FF4C, 0xF8 bytes: a jump table over 0..11 (the literal `ext
    ' is print_vat's).

    Not known from the original:
    - the parameter's name; whether the keys were an enumeration (the
      callers pass a word and a byte zero-extended). }

  procedure print_ac_key(
      key: integer); options(val_param);
  begin
    prtcats(line, ', key=', 6);
    case key of
      0: prtcats(line, 'xsb      ', 9);
      1: prtcats(line, 'xdb      ', 9);
      2: prtcats(line, 'ext      ', 9);
      3: prtcats(line, 'comm     ', 9);
      4: prtcats(line, 'xproc_arg', 9);
      5: prtcats(line, 'lproc_arg', 9);
      6: prtcats(line, 'proc     ', 9);
      7: prtcats(line, 'jmp      ', 9);
      8: prtcats(line, 'nil      ', 9);
      9: prtcats(line, 'lproc    ', 9);
      10: prtcats(line, 'db       ', 9);
      11: prtcats(line, 'str      ', 9);
    end;
  end;

  { print_ac_ref - what an address constant refers to: r, blanks to
    column 16, and r's kind: varn with its vat (109), comblk (111),
    proc/func (107, 108), dsect (183), psect (182).

    0x0600B8, 0xCA bytes.  The blanks are a while loop (`cmpi.w #16;
    bcs' tested first); then a compare chain on the kind.

    Not known from the original:
    - the parameter's name. }

  procedure print_ac_ref(
      r: il_$node_ptr_t); options(val_param);
  begin
    prtobj(line, r);
    while line.length < 16 do
      prtcatc(line, ' ');
    case r^.kind of
      109: begin
        prtcats(line, ',       varn', 12);
        print_vat(c_sym_ptr_t(r)^.var_vat);
      end;
      111: prtcats(line, ',     comblk', 12);
      107, 108: prtcats(line, ',  proc/func', 12);
      183: prtcats(line, ',      dsect', 12);
      182: prtcats(line, ',      psect', 12);
    end;
  end;

  { print_addr_cons - the address constants (-ACMAP), on a new page:
    ABSOLUTE ADDR_CONS (il_130's chain, by +4: the reference +12, the
    key a word at +20, the displacement +16), XDYNM ADDR_CONS (of each
    block printed by sym_map (+376's field 0), the chain at +180: the
    reference +8, the key a byte at +20, disp +16 and pdisp +12) and
    PIC ADDR_CONS/ECBs (for each entry of il_110's chain, the list at
    +12: address constants (163) as for XDYNM, linked by +4, and other
    nodes printed with ` - ECB?', linked by +116).  Each heading is
    followed by an empty line, each list by an empty line.

    0x0601BE, 0x374 bytes.  Each entry's line begins with prtcats of
    the 3-blank literal with a length of 4 (the literal is padded with
    a NUL to an even length; `move.w #4' at 0x06021C).

    Not known from the original:
    - the locals' names; whether the original passed 4 for a
      3-character string (or a 4-character one whose last character
      was a NUL). }

  procedure print_addr_cons;
  var
    a, p: il_$node_ptr_t;
  begin
    ejctln;
    line.length := 0;
    prtcats(line, 'ABSOLUTE ADDR_CONS', 18);
    listln(line);
    line.length := 0;
    listln(line);
    a := il_130;
    while a <> nil do begin
      line.length := 0;
      prtcats(line, '   ', 4);
      print_ac_ref(a^.xp[3]);
      print_ac_key(a^.xw[10]);
      prtcats(line, ',  disp=', 8);
      prtint(line, a^.xl[4], 8, false);
      listln(line);
      a := a^.xp[1];
    end;
    line.length := 0;
    listln(line);
    prtcats(line, 'XDYNM ADDR_CONS', 15);
    listln(line);
    line.length := 0;
    listln(line);
    a := il_184;
    a := a^.xp[1];
    while a <> nil do begin
      if (a^.xw[188] & 16#180) = 0 then begin
        p := a^.xp[45];
        while p <> nil do begin
          line.length := 0;
          prtcats(line, '   ', 4);
          print_ac_ref(p^.xp[2]);
          print_ac_key(ord(p^.xc[20]));
          prtcats(line, ',  disp=', 8);
          prtint(line, p^.xl[4], 8, false);
          prtcats(line, ',  pdisp=', 9);
          prtint(line, p^.xl[3], 8, false);
          listln(line);
          p := p^.xp[1];
        end;
      end;
      a := a^.xp[1];
    end;
    line.length := 0;
    listln(line);
    prtcats(line, 'PIC ADDR_CONS/ECBs', 18);
    listln(line);
    line.length := 0;
    listln(line);
    a := il_110;
    while a <> nil do begin
      p := a^.xp[3];
      while p <> nil do
        if p^.kind = 163 then begin
          line.length := 0;
          prtcats(line, '   ', 4);
          print_ac_ref(p^.xp[2]);
          print_ac_key(ord(p^.xc[20]));
          prtcats(line, ',  disp=', 8);
          prtint(line, p^.xl[4], 8, false);
          prtcats(line, ',  pdisp=', 9);
          prtint(line, p^.xl[3], 8, false);
          listln(line);
          p := p^.xp[1];
        end
        else begin
          line.length := 0;
          prtcats(line, '   ', 4);
          prtobj(line, p);
          prtcats(line, ' - ECB?', 7);
          listln(line);
          p := p^.xp[29];
        end;
      a := a^.xp[1];
    end;
  end;

begin
  map_count := 0;
  ejctln;
  n := 0;
  b := il_184;
  b := b^.xp[1];
  while b <> nil do begin
    if (b^.xw[188] & 16#180) = 0 then begin
      n := n + 1;
      b^.xw[144] := n;
      print_block(b);
    end;
    b := b^.xp[1];
  end;
  ejctln;
  ids := sortidentifiers;
  while ids <> nil do begin
    sym := c_sym_ptr_t(ids^.xp[2]);
    while sym <> nil do begin
      blk := sym^.block;
      if sym^.kind = 109 then begin
        if (14 in sym^.var_flags) or else
           (sym^.name = id_end_of_for) or else
           (sym^.name = id_end_of_while) or else
           (sym^.name = id_at) or else
           (sym^.name = id_string_constant) or else
           (sym^.var_type^.kind = 108) or else
           (sym^.var_type^.kind = 107) or else
           ((not spos_$line_is_in_main_source_file(sym^.line)) and
            (sym^.var_vat = vat_ext)) or else
           (blk = nil) or else (blk = il_184) or else (blk = il_178) then
          show := false
        else begin
          show := true;
          blk := sym^.block;
          while blk^.kind = 172 do
            blk := blk^.xp[2];
        end;
      end
      else if not spos_$line_is_in_main_source_file(sym^.line) or else
              (sym^.block = il_184) then
        show := false
      else
        show := true;
      if show then begin
        line.length := 0;
        prtint(line, blk^.xw[144], 3, true);
        prtcatc(line, ' ');
        prtobj(line, ids);
        prtcatc(line, ' ');
        repeat
          prtcatc(line, ' ');
        until line.length >= 12;
        case sym^.kind of
          109: begin
            print_10('var(', 4);
            if sym^.var_vat = vat_ext then
              print_10('extern', 6)
            else begin
              if (sym^.var_vat = vat_xstat) or
                 (sym^.var_vat = vat_xextdef) then
                off := blk^.xp[48]^.xl[5]
              else if sym^.var_vat = vat_xdynm then
                off := blk^.xl[28] - blk^.xl[44]
              else
                off := 0;
              off := off + sym^.var_offset;
              if off >= 0 then
                prtcatc(line, '+')
              else begin
                prtcatc(line, '-');
                off := -off;
              end;
              prthex(line, off, 6);
              prtcatc(line, '/');
              if (sym^.var_vat = vat_dynm) or
                 (sym^.var_vat = vat_xdynm) then
                prtcatc(line, 'S')
              else if sym^.var_vat = vat_param then
                prtcatc(line, 'A')
              else if sym^.var_vat = vat_sect then
                prtobj(line, sym^.var_sect^.xp[1])
              else
                prtcatc(line, 'D');
            end;
            prtcats(line, '): ', 3);
            print_attr(sym^.var_flags, sym^.var_attr);
            print_type(sym^.var_type, 2);
          end;
          116: begin
            print_10('const=', 6);
            print_con(sym^.con_type, sym^.con_value);
          end;
          117: begin
            print_10('label(', 6);
            if sym^.lab_node^.kind <> 144 then
              print_10('------', 6)
            else begin
              prthex(line, sym^.lab_node^.xl[14], 6);
              prtcatc(line, '/');
              prtcatc(line, 'P');
            end;
            prtcatc(line, ')');
          end;
          118: begin
            print_10('typedef= ', 9);
            tattr_to_vattr(vattr, sym^.td_attr);
            print_attr(sym^.td_flags, vattr);
            print_type(sym^.td_type, 6);
          end;
          otherwise
            prtobj(line, sym);
        end;
        listln(line);
      end;
      sym := sym^.next;
    end;
    ids := ids^.idnt_next;
  end;
  if cargs_$options.acmap then
    print_addr_cons;
end;
