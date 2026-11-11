{ lang/lang/source/outbin.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/outbin.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ OUTBIN - the m68k back end's object code output (outcode, called
  by unix_objmod).  outbin.pas, cc.m68k only (0x0BBE28, A5 0x2D179C);
  cc.a88k's units open this insert too and use none of it, and cc.a88k
  has empty add_proc_reloc and outcode in
  lang2/source/be_com/target_at_dummies.pas (which opens no prelude),
  so those two are the back end's interface though only outbin calls
  add_proc_reloc.

  The headings of the 3 routines of the unit other units call (of its 70
  routines), read off the frames and the call sites (docs/core-plan.md,
  method change): the frame slots are given as offset:push/use, the push
  at the call sites (p an address, l a longword, w a word, b a byte in a
  word) and the routine's own use of the slot (a moved to an address
  register, l, w or b read as a value, p its address taken); a pointer
  is univ_ptr until its target is known, every slot is a value
  (val_param); a function is one whose callers read D0 or A0 after the
  call (A0 a pointer).

  Not known from the original: every parameter name and most types. }

{ TODO(pascal) outbin headings are read off the frames only

  Narrow the univ_ptr parameters and results to the node types, and name
  the parameters, when outbin.pas and its callers are translated.  A
  routine with no call site (0 call sites) is reached through a
  procedure pointer or not at all; its result is read off its epilogue. }

{ The unit's other global routines are called only within it (or not at
  all) and are left to the unit file: prtlabel 0x0BD00C, prt_bit_field
  0x0BD0BC, prt_expr_bit_field 0x0BD212, dump_bit_field 0x0BD2EA,
  dump_expr_bit_field 0x0BD56C, prt_int_regs 0x0BD696, prt_fp_regs
  0x0BD88C, prtads 0x0BDAE0, prtsiz 0x0BDF34, dbcod 0x0BDFEC,
  init_proc_reloc 0x0BF21C, dump_proc_reloc 0x0BF23E. }

{ GENFPINST - 0x0BEB32; frame 8:p/a; 7 call sites (banshee); result in
  D0. }
function genfpinst(
    p1: univ_ptr): integer; options(val_param); extern;

{ ADD_PROC_RELOC - 0x0BF472; frame 8:l 12:a 16:l 20:a; 1 call site. }
procedure add_proc_reloc(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32;
    p4: univ_ptr); options(val_param); extern;

{ OUTCODE - 0x0C1FC6; 1 call site (unix_objmod). }
procedure outcode; extern;
