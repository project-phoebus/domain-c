{ lang2/source/be_com/at_base.ins.pas - opened, before backend.ins.pas,
  by asm, at_backend, bin, dmp, jbr, konst, lst, sym, xtp, zzzzz and the
  ISC units isc_call_handling and rewrite (not by the other 27 be_com
  units).  The name and its users (the units that meet the front end's
  or the object module's view of the target: the assembler listing, the
  binary, the symbols, the phases' driver) suggest the base types of
  the "AT" interface that at_backend's entry points (globals_from_
  backend.ins.pas: at_backend_$begin_compilation, ...) and the
  at_lib_dsc section serve.

  No Apollo copy survives.  Of the units that open it, those translated
  so far (jbr, xtp, zzzzz) use nothing that backend.ins.pas or the
  prelude does not declare.

  Not known from the original: everything about its contents. }

{ TODO(pascal) at_base.ins.pas: its declarations, as asm, at_backend,
  bin, dmp, konst, lst and sym are translated }
