{ lang/lang/source/token.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/token.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ TOKEN - the literal constants' nodes, each value entered once: integer
  constants hashed into 2176 sorted chains, reals into 16 per precision,
  set constants by size, strings, complex values and real pairs in one
  sorted chain each.  token.pas (lang/lang/source, cc.m68k
  0x098BD4..0x09936E) defines the tables and the routines; il.pas's
  initialize_module clears the tables.  Headings from the routines'
  frames and their callers (tools/cc_params.py): values by value
  (val_param), reals and the set's bits by address, nodes as pointers.

  Not known from the original: every name here (the routine names are the
  binaries'). }

type
  token_$vstring_t = varying [32767] of char;
  token_$set_bits_t = array [0..4095] of integer;

var
  { token.pas's data, A5 0x19DF90 (cc.m68k), 0x2384 bytes. }
  token_set_chains: extern array [3..64] of il_$node_ptr_t;     { +0x0: by
                                          size mod 65, at least 3 }
  token_real_chains: extern array [0..15] of il_$node_ptr_t;    { +0xF8:
                                          kind 88 }
  token_dreal_chains: extern array [0..15] of il_$node_ptr_t;   { +0x138:
                                          the other real kinds }
  token_integer_chains: extern array [0..2175] of il_$node_ptr_t; { +0x178 }
  token_string_chain: extern il_$node_ptr_t;                    { +0x2378 }
  token_dcomplex_chain: extern il_$node_ptr_t;                  { +0x237C }
  token_pair_chain: extern il_$node_ptr_t;                      { +0x2380 }

{ SMCONTK - the integer constant node of kind with value (12 bytes).
  0x098BD4.  Kind 81 (the common one): value & 1023, or for a negative
  value 1024 + (value & 127); other kinds 1152 + (value & 1023). }
function smcontk(
    kind: integer;
    value: integer32): il_$node_ptr_t; options(val_param); extern;

{ RLCONTK - the node of a single-precision real (kind 88), the value
  first rounded to single precision when the option at cargs +0x27F bit
  6 is set.  0x098D82. }
function rlcontk(
    in value: double): il_$node_ptr_t; extern;

{ DPCONTK - the node of a double-precision real (kind 89).  0x098E1E. }
function dpcontk(
    in value: double): il_$node_ptr_t; extern;

{ GET_RECIPROCAL - the node of 1 / the real constant node's value, of
  the same kind.  0x098E48. }
function get_reciprocal(
    t: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ CMPLXTK - the node of a single-precision complex (kind 90): re and im
  as stored, -0 taken as 0.  0x098E8E. }
function cmplxtk(
    in re: real;
    in im: real): il_$node_ptr_t; extern;

{ TOKEN_$MAKE_REAL_LIT_PAIR - the kind 90 node of two doubles converted
  to single precision; found_swapped is set when the pair is found only
  the other way round and swapped_ok allows that.  0x098F2E. }
function token_$make_real_lit_pair(
    in a: double;
    in b: double;
    swapped_ok: boolean;
    found_swapped: univ_ptr): il_$node_ptr_t; options(val_param); extern;

{ DPCMPLXTK - the node of a double-precision complex (kind 198).
  0x099020: im's address passed as a value. }
function dpcmplxtk(
    in re: double;
    im: univ_ptr): il_$node_ptr_t; options(val_param); extern;

{ STRTK - the string constant node (kind 92) of the len characters s.
  0x0990F0. }
function strtk(
    s: univ_ptr;
    len: integer): il_$node_ptr_t; options(val_param); extern;

{ TOKEN_$MAKE_STRING_TOKEN - strtk of a varying string.  0x0991A6. }
function token_$make_string_token(
    in s: univ token_$vstring_t): il_$node_ptr_t; extern;

{ SETCONTK - the node of the set constant whose bits are lo..hi of bits
  (a word array): an integer constant node when it fits in 32 bits.
  0x0991D0. }
function setcontk(
    in bits: univ token_$set_bits_t;
    lo: integer;
    hi: integer): il_$node_ptr_t; options(val_param); extern;

{ SET_IS_NIL - whether the set constant node has no members.
  0x09930E. }
function set_is_nil(
    t: il_$node_ptr_t): boolean; options(val_param); extern;
