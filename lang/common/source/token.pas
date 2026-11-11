{ token - TOKEN_, the common front ends' literal constants and
  identifiers: tokens are the IL nodes lang/lang's TOKEN and STRINGS
  enter once each (smcontk, rlcontk, dpcontk, strtk, idntk); this unit
  checks the arguments, picks the node kinds, sizes constants and dumps
  string tokens.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07353C  0x074F1C  token_$constant_byte_size
    0x073688  0x075068  token_$discrete_scalar
    0x0736FE  0x0750DE  token_$discrete_scalar_to_constant
    0x073716  0x0750F6  token_$single_float_to_constant
    0x073756  0x075136  token_$double_float_to_constant
    0x073782  0x075162  token_$char_string
    0x073804  0x0751E4  token_$identifier
    0x073902  0x0752E2  token_$diag_dump_char_string
    A5 0x168D8C (cc.m68k), 0x2E8DFC (cc.a88k): the module's data; no
    routine here reads it.

  Every routine is global and loads A5; none is nested.  A function
  whose result is its last call's leaves it in A0 (no store to the
  result slot).
}
module token;

%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/common/source/token.low.pas';
%include 'lang/lang/source/real_globals.ins.pas';
%include 'lang/lang/source/token.ins.pas';
%include 'lang/lang/source/strings.ins.pas';
%include 'lang/lang/source/list_tree.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/diag.ins.pas';
%include '/sys/ins/base.ins.pas';

{ token_$constant_byte_size - the bytes the constant takes.

  0x07353C, 0xEC bytes: t in A2; `cmpa.w #0; bne', else
  ass_$precondition_fail('TOKEN_$CONSTANT_BYTE_SIZE -- nil node%$')
  (0x073660).  Then a compare chain on the kind (+2) in the order
  below; the result in D0: 1, 2, 4, 8, 16, the word at +16
  zero-extended (kinds 92 and 156 share the code), the longword at +8
  (kind 176).  Kind 163: when the byte at +20 is 11 and the node at +8
  is of kind 92, that node's length rounded up to a multiple of 4
  (`addq.l #3; andi.b #-4'), else 4 (`bne' past the second test: `and
  then').  Any other kind:
  ass_$precondition_fail('... -- node is not a constant%$') (0x073628),
  D0 not set.

  Not known from the original:
  - the order of the case labels beyond the chain's (kinds 92 and 156
    may have been one arm), and how the rounding was written. }

function token_$constant_byte_size(
    t: token_$t): integer32;
var
  node: il_$node_ptr_t;
begin
  node := t;
  if node = nil then
    ass_$precondition_fail('TOKEN_$CONSTANT_BYTE_SIZE -- nil node%$');
  case node^.kind of
    92:
      token_$constant_byte_size := node^.idnt_len;
    77, 87:
      token_$constant_byte_size := 1;
    78, 80, 81:
      token_$constant_byte_size := 2;
    195, 88, 79, 82:
      token_$constant_byte_size := 4;
    163:
      if (node^.ref_class = chr(11)) and then (node^.ref_node^.kind = 92) then
        token_$constant_byte_size := (node^.ref_node^.idnt_len + 3) & (~3)
      else
        token_$constant_byte_size := 4;
    90, 89:
      token_$constant_byte_size := 8;
    198:
      token_$constant_byte_size := 16;
    156:
      token_$constant_byte_size := node^.idnt_len;
    176:
      token_$constant_byte_size := node^.sized_bytes;
    otherwise
      ass_$precondition_fail(
        'TOKEN_$CONSTANT_BYTE_SIZE -- node is not a constant%$');
  end;
end;

{ token_$discrete_scalar - the integer constant of value, of the scalar
  kind.

  0x073688, 0x76 bytes: kind (a word) less 1 indexes a jump table of 6
  (`cmpi.w #6; bcc' past it): the node kind 87, 77, 80, 78, 82, 79 in a
  word at (-2,A6); then SMCONTK (0x0736F0) of that word and value, its
  result left in A0.

  Not known from the original:
  - the scalar kinds' names (1..6: two 1-byte, two 2-byte and two
    4-byte kinds by token_$constant_byte_size); an out-of-range kind
    leaves the node kind unset, as here. }

function token_$discrete_scalar(
    kind: integer;
    value: integer32): token_$t;
var
  node_kind: integer;                   { (-2,A6) }
begin
  case kind of
    1: node_kind := 87;
    2: node_kind := 77;
    3: node_kind := 80;
    4: node_kind := 78;
    5: node_kind := 82;
    6: node_kind := 79;
  end;
  token_$discrete_scalar := smcontk(node_kind, value);
end;

{ token_$discrete_scalar_to_constant - a discrete scalar token is its
  own constant.

  0x0736FE, 0x18 bytes: `movea.l (8,A6),A0'. }

function token_$discrete_scalar_to_constant(
    t: token_$t): token_$t;
begin
  token_$discrete_scalar_to_constant := t;
end;

{ token_$single_float_to_constant - the constant of a single real.

  0x073716, 0x40 bytes: r by value at (8,A6), widened to a double by
  FPP_$ESLV (0x07372C, the emulated conversion: an inline operation word
  follows the call) into (-20,A6), copied to (-8,A6), whose address goes
  to RLCONTK (0x073746). }

function token_$single_float_to_constant(
    r: real): token_$t;
begin
  token_$single_float_to_constant := rlcontk(r);
end;

{ token_$double_float_to_constant - the constant of a double.

  0x073756, 0x2C bytes: d by address, copied to (-8,A6) (a value
  parameter), whose address goes to DPCONTK (0x073774). }

function token_$double_float_to_constant(
    d: double): token_$t;
begin
  token_$double_float_to_constant := dpcontk(d);
end;

{ token_$char_string - the string constant of the len characters s.

  0x073782, 0x4C bytes: len in D2, s in A2; `cmpi.l #4096,D2; bls'
  (unsigned: token_$length_t), else
  ass_$precondition_fail('TOKEN_$CHAR_STRING -- string text too long
  (%lsd)%$', len) with `pea (12,A6)'.  STRTK (0x0737B8) of s's address
  and len as a word, its result left in A0. }

function token_$char_string(
    in s: univ token_$text_t;
    len: token_$length_t): token_$t;
begin
  if len > token_$max_text_length then
    ass_$precondition_fail(
      'TOKEN_$CHAR_STRING -- string text too long (%lsd)%$', len);
  token_$char_string := strtk(addr(s), len);
end;

{ token_$identifier - the identifier of the len characters s.

  0x073804, 0x76 bytes: as token_$char_string, the message
  'TOKEN_$IDENTIFIER -- string text too long ("%a")%$' with s and len;
  IDNTK (0x07383E) of kind 76, s and len as a word into A3.  When the
  entry's kind (+2) is not 76: its kind zero-extended into (-12,A6) and
  ass_$precondition_fail('TOKEN_$IDENTIFIER -- identifier "%a" already
  declared as a reserved word (ord(%lsd))%$', s, len, that longword)
  (0x0738AC).  The result the entry, in A0.

  Not known from the original:
  - the local's name. }

function token_$identifier(
    in s: univ token_$text_t;
    len: token_$length_t): token_$t;
var
  node: il_$node_ptr_t;
  node_kind: integer32;                 { (-12,A6) }
begin
  if len > token_$max_text_length then
    ass_$precondition_fail(
      'TOKEN_$IDENTIFIER -- string text too long ("%a")%$', s, len);
  node := idntk(76, s, len);
  if node^.kind <> 76 then begin
    node_kind := node^.kind;
    ass_$precondition_fail(
      'TOKEN_$IDENTIFIER -- identifier "%a" already declared as a reserved word (ord(%lsd))%$',
      s, len, node_kind);
  end;
  token_$identifier := node;
end;

{ token_$diag_dump_char_string - a string token's text in quotes.

  0x073902, 0x8E bytes: bracketed (a byte) in D2.  A nil token:
  DIAG_$WRITE('<NIL token_$char_string>%$') (0x073990).  A node not of
  kind 92: DIAG_$WRITE('<not a token_$char_string>%$') (0x0739AC), then
  LIST_TREE_$PRINT_TREE(t, 0).  Else, when bracketed,
  DIAG_$WRITE('<token_$char_string: %$') (0x0739CC);
  STD_$DIAG_DUMP_ANY_STRING(the characters at +18, the length at +16
  zero-extended, true (`st')); when bracketed DIAG_$WRITE('>%$')
  (0x0739C8). }

procedure token_$diag_dump_char_string(
    t: token_$t;
    bracketed: boolean);
var
  node: il_$node_ptr_t;
begin
  node := t;
  if node = nil then
    diag_$write('<NIL token_$char_string>%$')
  else if node^.kind <> 92 then begin
    diag_$write('<not a token_$char_string>%$');
    list_tree_$print_tree(node, 0);
  end
  else begin
    if bracketed then
      diag_$write('<token_$char_string: %$');
    std_$diag_dump_any_string(node^.idnt_name, node^.idnt_len, true);
    if bracketed then
      diag_$write('>%$');
  end;
end;
