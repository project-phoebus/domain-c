{ lang2/source/be_prism/target.ins.pas - the PRISM target's insert
  (cc.a88k only): opened by every be_com unit but target_at_dummies and
  exs, by call_conv and by the ISC units, after be_com/backend.ins.pas,
  lt_utils mrh.ins.pas and lang prtsub.ins.pas, and just before the
  opcode enumeration (so it cannot use opc$t).  The directory's name
  (be_prism, beside be_com) says it holds what is particular to the
  PRISM (DN10000) target of the common back end: by the opcode
  tables, the PA-RISC target shares be_com's opcode enumeration
  (opcode_enumeration.ins.pas).

  No Apollo copy survives.  Nothing the leaf units translated so far
  (dfa, jbr, sem_utils, xtp, zzzzz) needs could only come from here;
  the register file's sizes and the target's other constants belong
  here when the units that use them (ra, ra_utils, call_conv, sched,
  asm, bin) are translated.

  Not known from the original: everything about its contents. }

{ TODO(pascal) target.ins.pas: the PRISM's registers and other target
  constants, as the units that use them are translated }
