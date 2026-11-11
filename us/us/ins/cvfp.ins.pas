{ us/us/ins/cvfp.ins.pas - Apollo's internal insert of the floating-point
  conversions (//us/us/ins).  No copy survives.  prtobj.pas opens it
  last; the conversions prtobj calls (lib_$cv_dfp_out, lib_$cv_sfp_out)
  are declared in us/us/ins/lib.ins.pas, which the prelude opens first,
  so nothing is declared here.

  Not known from the original: everything about its contents.
}
