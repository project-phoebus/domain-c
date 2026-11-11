{ c_get_rlen - GET_RLEN, the register length class of a C type: what
  the front end and the back end's register code use to choose an
  operand length.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0532D8  0x053558  get_rlen
    A5 0x142524 (cc.m68k), 0x2C2524 (cc.a88k): the module has no data
    (c_initdate.c's and c_lex_pp's A5 is the same address).

  get_rlen is global and loads A5 though it uses no data
  (docs/rev889-patterns.md 1).
}
module c_get_rlen;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';

{ get_rlen - t's register length class: 0 for kind 210, 5 for kinds 135
  and 130, the length word of a kind 123 (floating) type, 9 for kinds
  126 and 127; otherwise t's size when it is 1, 2 or 4, else 11.

  0x0532D8, 0x7C bytes: t's address from (8,A6) (a by-address
  parameter; the callers `pea' a type_exp_t), base (+0) to A1 and its
  kind (+2) compared with 210, 135, 130, 123, 126, 127 in that order (a
  case statement compiled as a compare chain); `clr.w D0', `moveq #5',
  `move.w (4,A1),D0', `moveq #9'.  The otherwise arm compares size
  (+16) with 1, 2 and 4 (`cmp.l (16,A0),D1') in an if chain; 11 last.

  Not known from the original:
  - the parameter's name; whether t was `in' or `var' (it is only
    read). }

function get_rlen(
    in t: type_exp_t): integer;
begin
  case t.base^.kind of
    210:
      get_rlen := 0;
    135, 130:
      get_rlen := 5;
    123:
      get_rlen := t.base^.len;
    126, 127:
      get_rlen := 9;
    otherwise
      if t.size = 1 then
        get_rlen := 1
      else if t.size = 2 then
        get_rlen := 2
      else if t.size = 4 then
        get_rlen := 4
      else
        get_rlen := 11;
  end;
end;
