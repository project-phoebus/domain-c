{ lang/common/source/ecb.ins.pas - ECB_, a block's ECB in its dsect.

  No Apollo copy survives; the heading is read off ecb.pas (cc.m68k
  0x068808).  It stands alone: ecb.pas opens it first, before
  st.ins.pas, so the block is a univ_ptr here.

  Not known from the original: the parameter name.
}

{ ECB_$ALLOCATE_ECB - unless -ABS/-AC (cargs flags_286 element 7), room
  for the block's ECB at the end of its dsect, the block chained on the
  dsect's list.  0x068808: block by value at (8,A6). }
procedure ecb_$allocate_ecb(
    block: univ_ptr); options(val_param); extern;
