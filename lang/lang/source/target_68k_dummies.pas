{ target_68k_dummies - the entries of cc.a88k's back end (at_backend,
  bin, isc, sym) that the common code calls: dummies in cc.m68k.  The
  functions answer true (can_load_module_db) or 0 (the displacements);
  the procedures do nothing.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0CA220  --------  at_backend_$can_load_module_db
    0x0CA236  --------  at_backend_$initialize_ftn_entry
    0x0CA238  --------  at_backend_$begin_compilation
    0x0CA23A  --------  at_backend_$end_compilation
    0x0CA23C  --------  bin_$emit_compilation_pure_text
    0x0CA23E  --------  isc_$set_source_language
    0x0CA240  --------  sym_$displacement
    0x0CA256  --------  sym_$displacement_literal_pool
    A5 0x2D2654: the module has no data.

  The unit opens no insert (its .blocks file list is empty), so its
  headings are its own; they follow globals_from_backend.ins.pas's
  (read off cc.a88k's routines and the callers).  The functions load A5
  (`link #-4', the result slot); the procedures are a lone `rts'
  (docs/rev889-patterns.md 13).

  Not known from the original: the parameters' names and types (none is
  read).
}
module target_68k_dummies;

{ at_backend_$can_load_module_db - true.  0x0CA220, 0x16 bytes: `st D0'. }

function at_backend_$can_load_module_db(
    p: univ_ptr): boolean; options(val_param);
begin
  at_backend_$can_load_module_db := true;
end;

{ at_backend_$initialize_ftn_entry - nothing.  0x0CA236, 2 bytes. }

procedure at_backend_$initialize_ftn_entry(
    p: univ_ptr); options(val_param);
begin
end;

{ at_backend_$begin_compilation - nothing.  0x0CA238, 2 bytes. }

procedure at_backend_$begin_compilation(
    p: integer); options(val_param);
begin
end;

{ at_backend_$end_compilation - nothing.  0x0CA23A, 2 bytes. }

procedure at_backend_$end_compilation;
begin
end;

{ bin_$emit_compilation_pure_text - nothing.  0x0CA23C, 2 bytes. }

procedure bin_$emit_compilation_pure_text;
begin
end;

{ isc_$set_source_language - nothing.  0x0CA23E, 2 bytes. }

procedure isc_$set_source_language(
    lang: integer); options(val_param);
begin
end;

{ sym_$displacement - 0.  0x0CA240, 0x16 bytes: `clr.l D0'. }

function sym_$displacement(
    p: univ_ptr): integer32; options(val_param);
begin
  sym_$displacement := 0;
end;

{ sym_$displacement_literal_pool - 0.  0x0CA256, 0x16 bytes. }

function sym_$displacement_literal_pool(
    p1: univ_ptr;
    p2: univ_ptr): integer32; options(val_param);
begin
  sym_$displacement_literal_pool := 0;
end;
