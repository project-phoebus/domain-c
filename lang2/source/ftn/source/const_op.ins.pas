{ lang2/source/ftn/source/const_op.ins.pas - the interface of the
  FORTRAN unit lang2/source/ftn/source/const_op.ftn (constant
  operations), opened by kfold.

  No Apollo copy survives; the headings are read off kfold's calls.

  Not known from the original: the parameter names.
}

{ TODO(pascal) const_op.ins.pas holds only what kfold calls }

{ R8_EXPON - r := a ** b of doubles.  const_op.ftn (cc.m68k 0x07648C):
  kfold_$general pushes b's, a's and r's addresses (r last). }
procedure r8_expon(
    out r: double;
    in a: double;
    in b: double); extern;

{ R8I4_EXPON - r := a ** e, e an integer32.  const_op.ftn (cc.m68k
  0x0764CE). }
procedure r8i4_expon(
    out r: double;
    in a: double;
    in e: integer32); extern;
