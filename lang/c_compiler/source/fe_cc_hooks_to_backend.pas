{ fe_cc_hooks_to_backend - what the back ends ask of the C front end:
  the well-known types for cc.a88k's isc back end, and two hooks only
  other front ends fill (a FORTRAN namelist dump, coprocessor
  warnings).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x067378  0x0675F8  dump_namelist
    0x06737A  0x0675FA  coproc_$suppress_warnings
    0x06737C  0x0675FC  isc_$init_well_known_types
    A5 0x14AEC8 (cc.m68k), 0x2CAEC8 (cc.a88k): the module's data, 4
    bytes no routine reads.

  dump_namelist and coproc_$suppress_warnings are a lone `rts' each:
  Pascal Rev 8.89 gives an empty global procedure no frame and no A5
  load (docs/rev889-patterns.md 13); unix_objmod calls dump_namelist,
  so they are not internal.  isc_$init_well_known_types is global and
  loads A5.
}
module fe_cc_hooks_to_backend;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';

{ dump_namelist - nothing: C has no namelists.

  0x067378, 2 bytes: `rts'.  unix_objmod's unix_obj_gen calls it
  (0x0A0C4E) with no arguments.

  Not known from the original:
  - whether it took parameters (none is pushed). }

procedure dump_namelist;
begin
end;

{ coproc_$suppress_warnings - nothing.

  0x06737A, 2 bytes: `rts'; no caller in either binary. }

procedure coproc_$suppress_warnings;
begin
end;

{ isc_$init_well_known_types - the front end's int, float and double
  type nodes, for cc.a88k's isc back end.

  0x06737C, 0x38 bytes: the three by-address parameters (8, 12, 16) to
  A0, A1, A2 and c_expr_sem's +0x2398, +0x23A8, +0x23AC stored through
  them in that order.

  Not known from the original:
  - the parameters' names. }

procedure isc_$init_well_known_types(
    out int_type_node: univ_ptr;
    out float_type_node: univ_ptr;
    out double_type_node: univ_ptr);
begin
  int_type_node := int_type;
  float_type_node := float_type;
  double_type_node := double_type;
end;
