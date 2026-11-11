{ lang/lang/source/strings.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/strings.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ STRINGS - byte strings and the identifier table.  Headings read off
  strings.pas (cc.m68k 0x0987BC..0x098A8C) and its callers: lengths and
  counts by value (val_param), the strings by address. }

type
  { Characters as STRINGS takes them; the length is a separate
    argument.  Not known from the original: the name. }
  strings_$bytes_t = array [1..32767] of char;

{ COMPARE_BYTES - a (alen characters) against b (blen): -1, 0 or 1, the
  shorter taken as padded with blanks.  0x0988A0. }
function compare_bytes(
    in a: univ strings_$bytes_t;
    alen: integer;
    in b: univ strings_$bytes_t;
    blen: integer): integer; options(val_param); extern;

{ STRINGS_$COMPARE_BYTES_NOCASE - compare_bytes with a-z taken as A-Z.
  0x0988DC. }
function strings_$compare_bytes_nocase(
    in a: univ strings_$bytes_t;
    alen: integer;
    in b: univ strings_$bytes_t;
    blen: integer): integer; options(val_param); extern;

{ STRINGS_$MEMCMP - the first difference of n bytes, b's byte taken from
  a's (unsigned), or 0.  0x098918. }
function strings_$memcmp(
    in a: univ strings_$bytes_t;
    in b: univ strings_$bytes_t;
    n: integer32): integer32; options(val_param); extern;

{ STRINGS_$MEMMOVE - n bytes from src to dst, first to last.  0x098970. }
procedure strings_$memmove(
    out dst: univ strings_$bytes_t;
    in src: univ strings_$bytes_t;
    n: integer32); options(val_param); extern;

{ STRINGS_$MEMCPY - strings_$memmove.  0x0989A4. }
procedure strings_$memcpy(
    out dst: univ strings_$bytes_t;
    in src: univ strings_$bytes_t;
    n: integer32); options(val_param); extern;

{ IDNTK - the identifier entry of the len characters s, created with kind
  when there is none.  0x0989D6. }
function idntk(
    kind: integer;
    in s: univ strings_$bytes_t;
    len: integer): il_$node_ptr_t; options(val_param); extern;
