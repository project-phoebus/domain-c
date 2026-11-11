{ us/us/ins/lib.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  Apollo's internal /us/ins insert for the global library's LIB_
  routines (the compiler calls lib_$cv_fp_in, lib_$cv_sfp_out,
  lib_$cv_dfp_out and lib_$data_move).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ TODO(pascal) lib.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated
  (docs/core-plan.md). }
