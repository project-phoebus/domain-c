{ seg_size - the size of the system's address-space segments: what the
  known global seg_size (looked up through LOADER_$KG_LOOKUP and
  called) returns, or 32768 when there is none; looked up once.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x09852C  0x099F0C  seg_size
    A5 0x19DB7C (cc.m68k), 0x31DBEC (cc.a88k): the module's data, 12
    bytes to sortidntk's.

  Module data as the image uses it: +0 the size (a longword), +4 a byte,
  true once it is known.

  Callers (mrh.pas, objio.pas) declare it themselves: no insert of its
  own is opened.
}
module seg_size;

%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/loader.ins.pas';
%include '/sys/ins/loader.ins.pas';
%include 'us/us/ins/fault.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include 'us/us/ins/unix_sig.ins.pas';

type
  { The global seg_size's entry. }
  seg_size_function_t = ^function: integer32;

var
  size: integer32;                      { +0 }
  size_known: boolean;                  { +4 }

{ seg_size - the segment size.

  0x09852C, 0x5A bytes: `tst.b (4,A5); bpl': when known, D0 := size.
  Else LOADER_$KG_LOOKUP (0x098556) of 'seg_size' (0x098590), the word
  8 (0x098588), the longword -1 (0x09858C, loader_$kg_symbol), the set
  word 6 (0x098586: public_only and function_only) and (-4,A6); when
  the result has bit 1 (loader_$sym_known), the address found is called
  (`jsr (A0)') and its D0 kept, else 32768; size_known := true (`st').
  The result in D0 and A0.

  Not known from the original:
  - the locals' names, and whether the result was written as size in
    both paths (the image loads it from +0 in each). }

function seg_size: integer32;
var
  address: univ_ptr;                    { (-4,A6) }
  system_seg_size: seg_size_function_t;
begin
  if size_known then
    seg_size := size
  else begin
    if loader_$sym_known in
       loader_$kg_lookup('seg_size', 8, loader_$kg_symbol,
                         [loader_$kg_public_only, loader_$kg_function_only],
                         address) then begin
      system_seg_size := address;
      size := system_seg_size^;
    end
    else
      size := 32768;
    size_known := true;
    seg_size := size;
  end;
end;
