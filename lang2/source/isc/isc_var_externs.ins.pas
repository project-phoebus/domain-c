{ lang2/source/isc/isc_var_externs.ins.pas - the ISC's shared cells (cc.a88k only): isc_user_routines.pas's data
  (A5 0x480E00, +0x2F8..+0x358) that lir, lir_main, lir_utils and
  the ISC units reach; opened by them after the other ISC inserts.

  No Apollo copy survives.  A stub, created with the back end's core
  (translator MM) so that the parallel translators extend one file;
  nothing in it yet.

  Not known from the original: everything about its contents. }

{ TODO(pascal) isc_var_externs.ins.pas: isc_user_routines' cells }

var
  { batch A (PA4): solutions lir_utils_$flesh_out_new_load_or_store
    builds a memory home's address from (no home: +0x330, a frame
    temporary; a home that is not static: +0x340). }
  isc_user_routines_328: extern solution_ptr_t;    { +0x328: the return
                                          address register's (lir_main) }
  isc_user_routines_32c: extern solution_ptr_t;    { +0x32C (lir_main:
                                          the conventions' w12 register's
                                          home) }
  isc_user_routines_330: extern solution_ptr_t;    { +0x330 (0x481130) }
  isc_user_routines_338: extern solution_ptr_t;    { +0x338: the DB
                                          register's home (lir_main) }
  isc_user_routines_33c: extern solution_ptr_t;    { +0x33C: the argument
                                          pointer's (lir_main) }
  isc_user_routines_340: extern solution_ptr_t;    { +0x340 (0x481140) }
  isc_user_routines_34c: extern univ_ptr;          { +0x34C: a well-known
                                          type node
                                          (isc_$init_well_known_types; the
                                          type lir_main gives an XSB
                                          pointer's variable) }
  isc_user_routines_358: extern boolean;           { +0x358 (lir_main_$begin_routine:
                                          neither -NO_FP nor il_180's
                                          +374 bit 4) }
