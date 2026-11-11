# Pascal Rev 8.89 code generation (cc.m68k / cc.a88k) vs dpc

The DOMAIN C 6.9 binaries were built with Pascal compiler Rev 8.89 (68K and
PRISM=>68K builds).  dpc models SR10.2's Rev 7.x (the kernel image).  This
translation runs dpc in best-effort mode; this file collects the Rev 8.89
forms met, with evidence, for a later dpc "Rev 8.89" profile.  Addresses are
cc.m68k unless marked.

## Prologue and epilogue

1. **A5 in every global routine of a module with data.**  A routine not
   declared `internal` loads its module's A5 (`lea abs.l,A5`) whether or
   not it uses it; `internal` and nested routines do not (they run on the
   caller's A5).  Over cc.m68k's module-level routines: referenced from
   another unit and loading A5 644, not loading 8; not referenced from
   another unit and not loading 877, loading 248 (taken to be global
   routines nobody outside calls).  `get_rlen` 0x0532D8 (uses no data),
   every `std_$` routine (std's data are 4 bytes no routine reads).
   SR10.2/dpc: A5 only when the routine uses the module's data.
   Consequence for the translation: a module-level routine with no A5 load
   was declared `internal`.
2. **Saves: one push each up to three registers, `movem` from four.**
   `pea (A5)` / `pea (An)` / `move.l Dn,-(SP)`, in the order A5, A4..A2,
   D7..D2 (`def_incomplete_su` 0x45650 `pea (A5); pea (A2); move.l
   D2,-(SP)`; `std_$round_up_to_multiple_of` 0x07333C `pea (A5); move.l
   D3,-(SP); move.l D2,-(SP)`); four or more `movem.l` (`std_$in_range_*`
   `movem.l D2-D4/A5,-(SP)`, `std_$append_integer` `movem.l
   D2-D5/A2/A5,-(SP)`).  The restores mirror it: one `move.l (d,A6),Rn` /
   `movea.l (d,A6),An` each, or `movem.l (d,A6),...`.  The `lea abs.l,A5`
   follows the saves.  SR10.2/dpc: `pea (A5)` only when A5 is the only
   register; otherwise `movem`.
3. **The result slot.**  A function's `link` reserves 4 bytes for the
   result (`link #-4`) though the result stays in D0
   (`std_$in_range_*`, `get_rlen`); a procedure with no locals has `link
   #0`.

## Code

4. **Loop heads aligned to 4 with 0x2048** (`movea.l A0,A0`, Apollo's fill
   word): `std_$append_string` 0x073466, `std_$append_integer` 0x0734C2,
   `def_incomplete_su` 0x04566E.  Not a difference: SR10.2 does the same
   and dpc emits `.balignw 4,0x2048` before a loop head.
5. **Loop-invariant addresses hoisted.**  `std_$append_integer` computes
   `s.body[start]`'s address once (`lea (1,A1,D2.l),A2`, 0x0734B2) before
   the repeat loop and stores each digit through A2.
6. **Value parameters loaded up front.**  Every by-value parameter the
   routine reads is loaded into a register at entry, last parameter first
   (`std_$in_range_*`: (16,A6), (12,A6), (8,A6) to D2, D0, D1;
   `diag_$write` 0x06845A loads all eleven); dpc reads them where used.
7. **Compare operands.**  `lower <= value` is `cmp.l value,lower; sle`
   with both in registers (std); dpc compares against the frame slot.
8. **Argument areas padded to a multiple of 4.**  A call whose arguments
   take 6, 10 or 14 bytes first does `subq.l #2,SP` and pops the rounded
   size: `gspace` 0x07D4F2 calling gspace32... (`subq.l #2,SP; move.w
   #4,-(SP)`, `addq.w #4,SP`), gspace32's `cgerr_no_source(28, 0)`
   0x07D530 (`subq.l #2,SP; clr.l -(SP); move.w #28,-(SP)`, `addq.w
   #8,SP`), compare_bytes 0x0988B4.  SR10.2/dpc push only the arguments.
