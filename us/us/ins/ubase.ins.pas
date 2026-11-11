{ us/us/ins/ubase.ins.pas - Apollo's internal base insert (//us/us/ins),
  which the compiler's units open where Apollo's customer programs open
  /sys/ins/base.ins.pas.

  No copy survives.  Units that open it open neither /sys/ins/base.ins.pas
  nor anything else that would declare base's types, so it declared them
  itself; until its own contents are known it stands in by including the
  customer insert.

  Not known from the original: everything about its contents.
}

%include '/sys/ins/base.ins.pas';
