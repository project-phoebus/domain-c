{ lang/lang/source/prtobj.ins.pas - PRTOBJ, printing the compiler's
  objects (identifiers, constants, types, ...) into a PRTSUB line
  (lang/lang/source/prtobj.pas).  Opened after prtsub.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: the parameter names.
}

{ TODO(pascal) prtobj.ins.pas is incomplete

  The rest of PRTOBJ's interface is added when prtobj.pas and its
  callers are translated. }

{ PRTOBJ - obj, whatever it is, to the end of s.  0x0B08B0: s by
  address, obj a pointer by value (53 call sites). }
procedure prtobj(
    in out s: prtsub_$line_t;
    obj: univ_ptr); options(val_param); extern;
