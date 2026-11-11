{ lang/common/source/token.ins.pas - TOKEN_, the common front ends'
  view of literal constants and identifiers: tokens made from scalar
  values, reals, character strings and names, their sizes, and a dump.

  No Apollo copy survives; the headings are read off token.pas (cc.m68k
  0x07353C..0x073990) and its callers (spos.pas).  It stands alone:
  token.pas opens it first, the units opening the prelude after it.  A
  token is an IL node (lang/lang/source/il.ins.pas), which this insert
  does not name: token.pas sees it through token.low.pas.  Values by
  value (val_param), strings by address.

  Not known from the original: every type and parameter name here.
}

type
  { A token: an IL constant or identifier node. }
  token_$t = univ_ptr;

  { A length: a non-negative longword (base's linteger); the routines
    compare it with their bound unsigned (`bls'). }
  token_$length_t = 0..2147483647;

  { The text of a string or a name. }
  token_$text_t = array [1..4096] of char;

const
  token_$max_text_length = 4096;        { the bound the routines check }

{ TOKEN_$CONSTANT_BYTE_SIZE - the bytes the constant token takes.
  0x07353C. }
function token_$constant_byte_size(
    t: token_$t): integer32; options(val_param); extern;

{ TOKEN_$DISCRETE_SCALAR - the integer constant token of value, of the
  scalar kind (1..6).  0x073688: kind a word at (8,A6), value at
  (10,A6). }
function token_$discrete_scalar(
    kind: integer;
    value: integer32): token_$t; options(val_param); extern;

{ TOKEN_$DISCRETE_SCALAR_TO_CONSTANT - the constant of a discrete
  scalar token (the token itself).  0x0736FE. }
function token_$discrete_scalar_to_constant(
    t: token_$t): token_$t; options(val_param); extern;

{ TOKEN_$SINGLE_FLOAT_TO_CONSTANT - the constant token of a
  single-precision real (by value).  0x073716. }
function token_$single_float_to_constant(
    r: real): token_$t; options(val_param); extern;

{ TOKEN_$DOUBLE_FLOAT_TO_CONSTANT - the constant token of a double
  (passed by address and copied).  0x073756. }
function token_$double_float_to_constant(
    d: double): token_$t; options(val_param); extern;

{ TOKEN_$CHAR_STRING - the string constant token of the len characters
  s (at most 4096).  0x073782. }
function token_$char_string(
    in s: univ token_$text_t;
    len: token_$length_t): token_$t; options(val_param); extern;

{ TOKEN_$IDENTIFIER - the identifier token of the len characters s (at
  most 4096), which must not be a reserved word.  0x073804. }
function token_$identifier(
    in s: univ token_$text_t;
    len: token_$length_t): token_$t; options(val_param); extern;

{ TOKEN_$DIAG_DUMP_CHAR_STRING - a string token's text in quotes to the
  diagnostic output, within `<token_$char_string: ...>' when bracketed.
  0x073902: t at (8,A6), bracketed a byte at (12,A6). }
procedure token_$diag_dump_char_string(
    t: token_$t;
    bracketed: boolean); options(val_param); extern;
