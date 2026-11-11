{ lang/common/source/st.ins.pas - ST (no unit of this name in DOMAIN C
  6.9): by its users, the front ends' symbol-table blocks.

  No Apollo copy survives.  Only what the translated units use is
  declared so far: the block and dsect fields ecb.pas
  (ecb_$allocate_ecb) reads and writes, at their offsets.  It stands
  alone (ecb.pas opens it after ecb.ins.pas only).

  Not known from the original: every name here.
}

{ TODO(pascal) st.ins.pas is incomplete

  The records below give only the fields ecb.pas uses; the rest is
  padding named by offset.  The name entry is an IL identifier node
  (lang/lang/source/il.ins.pas's variant 1), which ecb.pas sees without
  opening il.ins.pas. }

type
  st_$block_ptr_t = ^st_$block_t;

  { An identifier entry: +16 the length, +18 the characters. }
  st_$name_ptr_t = ^st_$name_t;
  st_$name_t = record
    unused_0: array [0..3] of integer32;        { +0 }
    len: 0..65535;                              { +16: zero-extended }
    name: array [1..4096] of char;              { +18 }
  end;

  { A dsect: the blocks given ECBs in it are chained from +12; +16 the
    size, which each ECB lowers. }
  st_$dsect_ptr_t = ^st_$dsect_t;
  st_$dsect_t = record
    unused_0: array [0..2] of integer32;        { +0 }
    ecb_blocks: st_$block_ptr_t;                { +12 }
    size: integer32;                            { +16 }
  end;

  { A block. }
  st_$block_t = record
    unused_0: array [0..26] of integer32;       { +0 }
    ecb_offset: integer32;                      { +108 }
    unused_112: integer32;                      { +112 }
    next_ecb_block: st_$block_ptr_t;            { +116 }
    unused_120: array [0..17] of integer32;     { +120 }
    dsect: st_$dsect_ptr_t;                     { +192 }
    unused_196: array [0..24] of integer32;     { +196 }
    name: st_$name_ptr_t;                       { +296 }
  end;
