{ lang/lang/source/il.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/il.pas (initialize_module) and the IL node types.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ The compiler's nodes.  Every node begins with a word not yet
  identified and the node's kind at +2 (il.pas initialize_module 0x07D882
  sets +2 of each node it creates; idntk sets it in each identifier
  entry it creates).  The variants are added as the units that build and
  read them are translated.

  Not known from the original: every name here. }

{ TODO(pascal) the node kinds and most variants are not declared yet

  Kinds are written as numbers where they occur (81 an integer constant,
  88/89 reals, 90 a pair, 92 a string, 198 a double complex, 73 the
  identifiers il.pas enters, 76 a section name, 153..155, 211, 216 and
  226 the nodes initialize_module makes).  IL's globals below are named by
  their offset in il.pas's data until their users are translated. }

type
  il_$node_ptr_t = ^il_$node_t;
  il_$node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      { An identifier, entered by idntk (strings.pas). }
      1: (idnt_next: il_$node_ptr_t;    { +4: the hash chain }
          idnt_unused_8: integer32;     { +8: cleared by idntk }
          idnt_unused_12: integer32;    { +12: cleared by idntk }
          idnt_len: integer;            { +16 }
          idnt_name: array [1..1024] of char);  { +18 }
      { An integer constant (smcontk; 12 bytes). }
      2: (int_next: il_$node_ptr_t;     { +4: the sorted chain }
          int_value: integer32);        { +8 }
      { A real constant (floating_token; 24 bytes). }
      3: (real_next: il_$node_ptr_t;    { +4 }
          real_unused_8: integer32;     { +8 }
          real_value: double;           { +12 }
          real_single_exact: boolean;   { +20: exactly a single }
          real_single_range: boolean);  { +21: in a single's range }
      { A pair of singles, a complex constant (kind 90; 20 bytes). }
      4: (pair_next: il_$node_ptr_t;    { +4 }
          pair_unused_8: integer32;     { +8: cleared }
          pair_a: integer32;            { +12 }
          pair_b: integer32);           { +16 }
      { A double complex constant (kind 198; 28 bytes). }
      5: (dcx_next: il_$node_ptr_t;     { +4 }
          dcx_unused_8: integer32;      { +8: cleared }
          dcx_re: double;               { +12 }
          dcx_im: double);              { +20 }
  end;

var
  { IL's globals: il.pas's data, A5 0x169C70 (cc.m68k), 0x2E9CE0
    (cc.a88k).  Widths from every unit's accesses (docs/globals-cc.*.md;
    `pointer' where some unit loads the cell into an address register);
    initialize_module (il.pas) sets them up. }
  il_tab_0: extern array [0..15] of univ_ptr;          { +0x00 }
  il_tab_40: extern array [0..15] of univ_ptr;         { +0x40 }
  il_tab_80: extern array [0..15] of univ_ptr;         { +0x80 }
  il_c0: extern boolean;                               { +0xC0 }
  il_c1: extern boolean;                               { +0xC1 }
  il_c2: extern boolean;                               { +0xC2 }
  il_c3: extern boolean;                               { +0xC3 }
  il_c4: extern integer;                               { +0xC4 }
  il_c6: extern integer;                               { +0xC6 }
  il_c8: extern univ_ptr;                              { +0xC8 }
  il_cc: extern il_$node_ptr_t;                        { +0xCC }
  il_d0: extern integer;                               { +0xD0 }
  il_d4: extern univ_ptr;                              { +0xD4 }
  il_d8: extern univ_ptr;                              { +0xD8 }
  il_node_155: extern il_$node_ptr_t;                  { +0xDC }
  il_node_154: extern il_$node_ptr_t;                  { +0xE0 }
  il_node_153: extern il_$node_ptr_t;                  { +0xE4 }
  il_node_211: extern il_$node_ptr_t;                  { +0xE8 }
  il_node_226: extern il_$node_ptr_t;                  { +0xEC }
  il_f0: extern array [0..6] of univ_ptr;              { +0xF0 }
  il_10c: extern univ_ptr;                             { +0x10C }
  il_110: extern univ_ptr;                             { +0x110 }
  il_114: extern integer32;                            { +0x114 }
  il_118: extern univ_ptr;                             { +0x118 }
  il_11c: extern univ_ptr;                             { +0x11C }
  il_120: extern univ_ptr;                             { +0x120 }
  il_124: extern integer;                              { +0x124 }
  il_126: extern integer;                              { +0x126 }
  il_128: extern univ_ptr;                             { +0x128 }
  il_12c: extern univ_ptr;                             { +0x12C }
  il_130: extern univ_ptr;                             { +0x130 }
  il_134: extern integer32;                            { +0x134 }
  il_138: extern integer32;                            { +0x138 }
  il_13c: extern integer32;                            { +0x13C }
  il_140: extern integer;                              { +0x140 }
  il_144: extern integer;                              { +0x144 }
  il_146: extern array [0..21] of integer;             { +0x146 }
  il_172: extern integer;                              { +0x172 }
  il_174: extern il_$node_ptr_t;                       { +0x174 }
  il_178: extern il_$node_ptr_t;                       { +0x178 }
  il_17c: extern univ_ptr;                             { +0x17C }
  il_180: extern univ_ptr;                             { +0x180: 37 units }
  il_184: extern univ_ptr;                             { +0x184 }

{ INITIALIZE_MODULE - set up IL's and TOKEN's tables and globals for a
  compilation.  il.pas 0x07D74C. }
procedure initialize_module; extern;

