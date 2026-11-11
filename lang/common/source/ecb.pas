{ ecb - ECB_: a block's ECB, allocated at the end of the block's dsect
  (the dsect's size lowered by the ECB's) and the block chained on the
  dsect's list of blocks with ECBs.  Nothing is done under -ABS/-AC.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x068808  0x068A88  ecb_$allocate_ecb
    A5 0x14B2F4 (cc.m68k), 0x2CB2F4 (cc.a88k): no data of its own (htm's
    data begin at the same address).

  The routine loads A5 although the module has no data
  (docs/rev889-patterns.md 1).
}
module ecb;

%include 'lang/common/source/ecb.ins.pas';
%include 'lang/common/source/st.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/diag.ins.pas';
%include '/sys/ins/base.ins.pas';
%include 'lang/lang/source/real_globals.ins.pas';
%include 'lang/lang/source/cargs.ins.pas';

{ ecb_$allocate_ecb - the block's ECB.

  0x068808, 0xB2 bytes:
    btst #2,(cargs +0x287); bne out   unless 7 in flags_286 (-ABS/-AC):
    cmpa.w #0,A2; bne                 nil block: precondition failure
                                        'ECB_$ALLOCATE_ECB -- NIL block%$'
    tst.l (192,A2); bne               no dsect: precondition failure
                                        '... -- block has no dsect
                                        (%a)%$' with the name entry's
                                        characters (+296 -> +18) and its
                                        length zero-extended in (-16,A6)
    btst #0,(cargs +0x284); beq       6 in cpu (cc.a88k's ALL/10000):
    subq 24 from (16,A0)                size := size - 24
    else size - 12, and 4 more when   else 12, and 4 more when db <> 0
      (cargs +0x282).l & 16#18000       (+0x283.0 and +0x284.7, -DB...)
      shifted down 15 is not 0
    +108 := dsect +16; +116 := dsect +12; dsect +12 := block.

  Not known from the original:
  - what the 24, 12 and 4 bytes are, and the locals' names. }

procedure ecb_$allocate_ecb(
    block: univ_ptr);
var
  b: st_$block_ptr_t;
  dsect: st_$dsect_ptr_t;
  name_length: integer32;               { (-16,A6) }
begin
  if not (7 in cargs_$options.flags_286) then begin
    b := block;
    if b = nil then
      ass_$precondition_fail('ECB_$ALLOCATE_ECB -- NIL block%$');
    if b^.dsect = nil then begin
      name_length := b^.name^.len;
      ass_$precondition_fail('ECB_$ALLOCATE_ECB -- block has no dsect (%a)%$',
                             b^.name^.name, name_length);
    end;
    dsect := b^.dsect;
    if 6 in cargs_$options.cpu then
      dsect^.size := dsect^.size - 24
    else begin
      dsect^.size := dsect^.size - 12;
      if cargs_$options.db <> 0 then
        dsect^.size := dsect^.size - 4;
    end;
    b^.ecb_offset := dsect^.size;
    b^.next_ecb_block := dsect^.ecb_blocks;
    dsect^.ecb_blocks := b;
  end;
end;
