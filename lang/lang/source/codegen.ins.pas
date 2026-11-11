{ lang/lang/source/codegen.ins.pas - the m68k code generator's insert
  (cc.m68k's back end: cg_*, final, celpkg, ...).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  A stub: only what lang/lang/source/celpkg.pas (which opens it) needs
  is declared so far, the code cells, the address descriptors and
  CELPKG's routines (which insert of the back end declared them is not
  known; the cg_ and final units that call them open this one).

  Not known from the original: every name here but the routines'.
}

{ TODO(pascal) codegen.ins.pas is a stub

  Add the code generator's other declarations as its units are
  translated. }

type
  { An address descriptor, packed (12 bytes; the cells hold two): five
    small fields in the first three bytes, then two longwords.
    unpack_ads and pack_ads convert it to and from codegen_$uads_t. }
  codegen_$ads_t = packed record
    f1: 0..31;                          { +0.7..3 }
    f2: 0..31;                          { +0.2 to +1.6 }
    f3: 0..31;                          { +1.5..1 }
    f4: 0..3;                           { +1.0 to +2.7 }
    f5: 0..7;                           { +2.6..4 }
    f6: 0..7;                           { +2.3..1 }
    pad: 0..511;                        { +2.0 to +3.0: not used }
    x: integer32;                       { +4 (a label's node) }
    y: integer32;                       { +8 (a label's number) }
  end;

  { An address descriptor, unpacked (20 bytes). }
  codegen_$uads_t = record
    f1: integer;                        { +0 }
    f2: integer;                        { +2 }
    f3: integer;                        { +4 }
    f4: integer;                        { +6 }
    f5: integer;                        { +8 }
    f6: integer;                        { +10 }
    x: integer32;                       { +12 }
    y: integer32;                       { +16 }
  end;

  { A code cell (getcodecell: 52 bytes, 20 for kinds 24, 32, 33) or a
    reference cell (getrefcell: 16 bytes), on a circular list. }
  codegen_$cell_ptr_t = ^codegen_$cell_t;
  codegen_$cell_t = record
    next: codegen_$cell_ptr_t;          { +0 }
    prev: codegen_$cell_ptr_t;          { +4 }
    case integer of
      { A code cell. }
      1: (kind: integer;                { +8: the instruction's kind }
          c_10: array [1..7] of integer;  { +10: cleared, but for the
                                          small cells }
          ads1: codegen_$ads_t;         { +24 }
          ads2: codegen_$ads_t);        { +36: a label's (getlabcell) }
      { A reference cell, on its owner's list. }
      2: (target: integer32;            { +8 }
          owner: codegen_$cell_ptr_t);  { +12 }
      { The owner of reference cells: their list at +32. }
      3: (c3_8: array [1..12] of integer;   { +8 }
          refs: codegen_$cell_ptr_t);   { +32 }
  end;

{ INIT_CELPKG - no cells allocated.  0x0B645C (final's f_initialize). }
procedure init_celpkg; extern;

{ GETLABCELL - a label cell for lab (nil: a new numbered label).
  0x0B648E: lab a pointer by value, the cell in A0. }
function getlabcell(
    lab: il_$node_ptr_t): codegen_$cell_ptr_t; options(val_param); extern;

{ GETREFCELL - a reference cell to target on owner's list.  0x0B650A:
  target a longword and owner a pointer by value, the cell in A0. }
function getrefcell(
    target: integer32;
    owner: codegen_$cell_ptr_t): codegen_$cell_ptr_t;
    options(val_param); extern;

{ GETCODECELL - a code cell of kind.  0x0B6582: kind by address (22
  call sites, most passing a constant), the cell in A0. }
function getcodecell(
    in kind: integer): codegen_$cell_ptr_t; extern;

{ AFTER - link b after a.  0x0B6652: two pointers by value. }
procedure after(
    a: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t); options(val_param); extern;

{ DELINK - take c off its list.  0x0B6682: a pointer by value. }
procedure delink(
    c: codegen_$cell_ptr_t); options(val_param); extern;

{ JOIN - splice list b in after a.  0x0B66AE: two pointers by value. }
procedure join(
    a: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t); options(val_param); extern;

{ EMPTY - whether c's list holds only c.  0x0B66EE: no caller in
  cc.m68k. }
function empty(
    c: codegen_$cell_ptr_t): boolean; options(val_param); extern;

{ PACK_ADS, UNPACK_ADS - an address descriptor packed and unpacked.
  0x0B670A, 0x0B6838: both by address. }
procedure pack_ads(
    in u: codegen_$uads_t;
    out p: codegen_$ads_t); extern;

procedure unpack_ads(
    in p: codegen_$ads_t;
    out u: codegen_$uads_t); extern;

{ CREATE_TEMP_LABEL - a new temporary label node (kind 144).
  0x0B68AA: no parameters, the node in A0. }
function create_temp_label: il_$node_ptr_t; extern;
