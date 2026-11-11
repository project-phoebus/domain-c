{ il - IL's set-up for a compilation: initialize_module empties the
  identifier, constant and IL tables, makes the nodes every compilation
  shares, and enters the sections `.text' and `.data'.  The module
  defines IL's globals (il.ins.pas).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07D74C  0x07F12C  initialize_module
    A5 0x169C70 (cc.m68k), 0x2E9CE0 (cc.a88k): the module's data, 0x2D8
    bytes (to mrh's): IL's globals, +0x00..+0x187; the rest is used by
    no routine of any unit absolutely.

  initialize_module is global and loads A5.
}
module il;

%include 'us/us/ins/ubase.ins.pas';
%include '/sys/ins/fpp.ins.pas';
%include 'lang/lang/source/globals.ins.pas';

define
  il_tab_0, il_tab_40, il_tab_80,
  il_c0, il_c1, il_c2, il_c3, il_c4, il_c6, il_c8, il_cc, il_d0,
  il_d4, il_d8,
  il_node_155, il_node_154, il_node_153, il_node_211, il_node_226,
  il_f0, il_10c, il_110, il_114, il_118, il_11c, il_120, il_124,
  il_126, il_128, il_12c, il_130, il_134, il_138, il_13c, il_140,
  il_144, il_146, il_172, il_174, il_178, il_17c, il_180, il_184,
  initialize_module;

{ initialize_module - set up IL's and TOKEN's tables for a compilation.

  0x07D74C, 0x244 bytes, in this order:
  - TOKEN's integer chains (2176 longwords from 0x19E108), the
    identifier table (256 from 0x19DB8C), the two real tables (16 each
    from 0x19E088, 0x19E0C8), the pair, double complex and string chains
    (0x1A0310, 0x1A030C, 0x1A0308) and the set chains (62 from 0x19DF90)
    are emptied, each with `move.l #0' (nil) in a `dbf' loop;
  - il_tab_80, il_tab_0 and il_tab_40 in one loop of 16;
  - +0x184, +0x180, +0x17C cleared (`clr.l');
  - +0x178 := idntk(73, '----', 4), +0x174 := idntk(216, '-??-', 4)
    (the literals at 0x07D99C, 0x07D9A0);
  - +0xC0, +0xC2 := false; +0xCC := +0x178; +0xD4, +0xD8 cleared;
    +0x172 := 0; the 22 words at +0x146 := 0;
  - five 4-byte nodes from gspace (0x07D872..0x07D8E2) of kinds 155,
    154, 153, 211, 226 at +0xDC..+0xEC;
  - the 7 longwords at +0xF0 := nil; +0x144 := 0; +0x138, +0x13C, +0x140
    and +0x10C, +0x110 cleared; +0x118 := nil;
  - add_psect(idntk(76, '.text', 5)), add_dsect(idntk(76, '.data', 5))
    (0x07D940, 0x07D95E; the sections' nodes are not kept);
  - +0xC4 := 1; +0x11C := nil; +0x120, +0x124 and +0x126..+0x136
    cleared.

  Not known from the original:
  - the loops' index variable; whether the cleared cells were assigned 0
    or nil (the image uses `clr.l' for some pointers and `move.l #0' for
    others; the declared types decide here). }

procedure initialize_module;
var
  i: integer;
  t: il_$node_ptr_t;
begin
  for i := 0 to 2175 do
    token_integer_chains[i] := nil;
  for i := 0 to 255 do
    idnt_table[i] := nil;
  for i := 0 to 15 do
    token_real_chains[i] := nil;
  for i := 0 to 15 do
    token_dreal_chains[i] := nil;
  token_pair_chain := nil;
  token_dcomplex_chain := nil;
  token_string_chain := nil;
  for i := 3 to 64 do
    token_set_chains[i] := nil;
  for i := 0 to 15 do begin
    il_tab_80[i] := nil;
    il_tab_0[i] := nil;
    il_tab_40[i] := nil;
  end;
  il_184 := nil;
  il_180 := nil;
  il_17c := nil;
  il_178 := idntk(73, '----', 4);
  il_174 := idntk(216, '-??-', 4);
  il_c0 := false;
  il_c2 := false;
  il_cc := il_178;
  il_d4 := nil;
  il_d8 := nil;
  il_172 := 0;
  for i := 0 to 21 do
    il_146[i] := 0;
  il_node_155 := gspace(4);
  il_node_155^.kind := 155;
  il_node_154 := gspace(4);
  il_node_154^.kind := 154;
  il_node_153 := gspace(4);
  il_node_153^.kind := 153;
  il_node_211 := gspace(4);
  il_node_211^.kind := 211;
  il_node_226 := gspace(4);
  il_node_226^.kind := 226;
  for i := 0 to 6 do
    il_f0[i] := nil;
  il_144 := 0;
  il_138 := 0;
  il_13c := 0;
  il_140 := 0;
  il_10c := nil;
  il_110 := nil;
  il_118 := nil;
  t := add_psect(idntk(76, '.text', 5));
  t := add_dsect(idntk(76, '.data', 5));
  il_c4 := 1;
  il_11c := nil;
  il_120 := nil;
  il_124 := 0;
  il_126 := 0;
  il_128 := nil;
  il_12c := nil;
  il_130 := nil;
  il_134 := 0;
end;
