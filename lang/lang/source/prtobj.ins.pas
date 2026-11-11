{ lang/lang/source/prtobj.ins.pas - PRTOBJ, printing the compiler's
  objects (identifiers, constants, types, variables, registers, ...)
  into a PRTSUB line (lang/lang/source/prtobj.pas).  prtobj.pas opens
  it before prtsub.ins.pas, and prfpkg without the prelude, so it
  declares its own line type and takes the object as a univ_ptr.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: the parameter names; the type name.
}

type
  { A printed line, as PRTSUB builds it (prtsub_$line_t's layout). }
  prtobj_$line_t = varying [256] of char;

{ PRTOBJ_$PRTOBJ_FULL - obj (an IL node), whatever it is, to the end of
  s; with full, the node's kind after it (`(integer)', `(varn)', ...)
  and, for a constant, its value.  0x0AF55A: s by address, obj a
  pointer and full a byte by value (il_utils's print_object_ptr). }
procedure prtobj_$prtobj_full(
    in out s: univ prtobj_$line_t;
    obj: univ_ptr;
    full: boolean); options(val_param); extern;

{ PRTOBJ - prtobj_$prtobj_full(s, obj, false).  0x0B08B0: s by
  address, obj a pointer by value (53 call sites). }
procedure prtobj(
    in out s: univ prtobj_$line_t;
    obj: univ_ptr); options(val_param); extern;
