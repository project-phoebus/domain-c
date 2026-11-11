{ lang/lang/source/gspace.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/gspace.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ GSPACE - the compilers' arena allocator.  Space is cut from chunks of
  at least 131008 bytes, cleared when obtained, and given back only in
  bulk: GSPACE_$MARK notes where the next allocation will be and
  GSPACE_$RELEASE frees everything allocated since.  Headings read off
  gspace.pas (cc.m68k 0x07D4C8..0x07D74C) and its callers; the sizes and
  counts are by value (val_param), the results pointers in A0. }

{ GSPACE_$OPEN - start with no chunks.  0x07D4C8. }
procedure gspace_$open; extern;

{ GSPACE - n bytes (a 16-bit count) of cleared space.  0x07D4F2. }
function gspace(
    n: integer): univ_ptr; options(val_param); extern;

{ GSPACE32 - n bytes of cleared space, aligned to 8, 4 or 2 bytes when n
  is at least that.  0x07D51C. }
function gspace32(
    n: integer32): univ_ptr; options(val_param); extern;

{ GSPACE_$MARK - where the next allocation will be, for
  GSPACE_$RELEASE.  0x07D64E. }
function gspace_$mark: univ_ptr; extern;

{ GSPACE_$RELEASE - free what was allocated since mark (all, when mark
  is nil).  0x07D66C: mark passed by address. }
procedure gspace_$release(
    in mark: univ_ptr); extern;

{ GSPACE_$CLOSE - free everything.  0x07D72C. }
procedure gspace_$close; extern;
