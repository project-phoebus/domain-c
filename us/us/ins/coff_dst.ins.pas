{ us/us/ins/coff_dst.ins.pas - Apollo's internal insert of the COFF
  debugging records (//us/us/ins), opened by cc.a88k's bin.pas after
  objmod.ins.pas.

  No copy survives.  bin.pas uses nothing that only this insert could
  declare: it reaches the debugging tables through gen_debug's routines
  (gen_debug.ins.pas) and the unwind tables through gen_unwind's.

  Not known from the original: everything about its contents. }

{ TODO(pascal) coff_dst.ins.pas: its declarations, when a unit that
  uses them is translated }
