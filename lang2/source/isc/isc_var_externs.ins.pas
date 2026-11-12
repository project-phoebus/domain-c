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
  isc_user_routines_258: extern solution_t;        { +0x258: the
                                          solution lir_$build_operand
                                          takes for a form with no action
                                          that a constant may fill (its
                                          action 17; batch A, PA7) }
  isc_user_routines_31c: extern solution_ptr_t;    { +0x31C: set to +0x320
                                          by lir_$begin_compilation (batch
                                          A, PA6) }
  isc_user_routines_320: extern solution_ptr_t;    { +0x320: register 31's
                                          physical solution (lir_3e60[31];
                                          lir_$begin_compilation) }
  isc_user_routines_328: extern solution_ptr_t;    { +0x328: the return
                                          address register's (lir_main) }
  isc_user_routines_32c: extern solution_ptr_t;    { +0x32C (lir_main:
                                          the conventions' w12 register's
                                          home) }
  isc_user_routines_330: extern solution_ptr_t;    { +0x330 (0x481130) }
  isc_user_routines_338: extern solution_ptr_t;    { +0x338: the DB
                                          register's home (lir_main) }
  isc_user_routines_334: extern solution_ptr_t;    { +0x334: the well-known
                                          register LB's (lir_$begin_
                                          compilation; batch A, PA6) }
  isc_user_routines_33c: extern solution_ptr_t;    { +0x33C: the argument
                                          pointer's (lir_main) }
  isc_user_routines_340: extern solution_ptr_t;    { +0x340 (0x481140) }
  isc_user_routines_344: extern univ_ptr;          { +0x344, +0x348: the
                                          other well-known type nodes
                                          (isc_$init_well_known_types' first
                                          two; batch A, PA6) }
  isc_user_routines_348: extern univ_ptr;
  isc_user_routines_34c: extern univ_ptr;          { +0x34C: a well-known
                                          type node
                                          (isc_$init_well_known_types; the
                                          type lir_main gives an XSB
                                          pointer's variable) }
  isc_user_routines_358: extern boolean;           { +0x358 (lir_main_$begin_routine:
                                          neither -NO_FP nor il_180's
                                          +374 bit 4) }
