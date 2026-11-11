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

## Data layout

9. **Module-level byte variables packed.**  il.pas's data has four
   booleans at +0xC0..+0xC3 (each read as a byte by other units), then a
   word at +0xC4; dpc gives each boolean its own word, so every later
   global of the module lies 4 bytes higher in dpc's layout than in the
   image.  The layout is internal to the program, so best effort keeps
   separate variables; a dpc profile would pack them.  (The image also
   leaves +0x142..+0x143 unused, where dpc puts the next word.)
10. **Consecutive stores of one constant to packed fields merged.**
    Statements that store the same constant to fields of one byte, word
    or longword become one `andi` (false, 0) or `ori` (true), the mask
    the union of the fields, adjacent or not:
    cargs_$init_option_defaults (cc.m68k 0x0B4AA8 `andi.w #0xFFE0`
    clears +0x27B bits 4..0, five booleans; cc.a88k, whose default sets
    bit 3, has `bclr #4; bset #3; andi.w #0xFFF8`), 0x0B4ABE `andi.w
    #0xF17F` (+0x27C bits 3..1 and +0x27D bit 7, +0x27C bit 0 not
    stored), 0x0B4A94 `andi.l #0x7FF` (a 6-bit field and 15 booleans);
    parse_options -IMAP `ori.w #0x180` (map and imap), -ANSI `or.w`
    0x34, -NANSI `andi.w #0xFFEB` after a separate `bclr` and `bset` of
    the same word (the run breaks at a store of the other value).  The
    language reference (3.15.3 p. 3-57) documents the merging for whole
    objects (dpc `--merge-constant-stores`), not for packed fields.  dpc
    stores each field.
11. **Calls that pop 2 bytes fewer than they push** (observed, not
    explained): iosub_$init_all 0x0B58F8 pushes 44 bytes for
    cargs_$parse_command_line_options and pops 42 (`lea (42,SP),SP`);
    prtobj_$prtobj_full 0x0AFA04 pushes 20 for lib_$cv_dfp_out and pops
    18; outbin's call of add_proc_reloc pops 14 for a 16-byte frame.
    The frame's `unlk` restores SP, so the drift is harmless.
12. **Trampolines for nested routines passed as parameters.**  Where a
    nested routine is passed as a procedure parameter, the code builds
    `lea abs.l,A0; lea abs.l,A1; jmp abs.l` in the frame (move.w #0x41F9,
    #0x43F9, #0x4EF9 and the addresses) and calls cache_$clear through
    the transfer vector (debug_sym_dmp, reg_color_68k); no source-level
    call, so no unit declares cache_$clear.
13. **An empty global procedure is a lone `rts`**: no `link`, no saves
    and no A5 load, though the module has data and other routines are
    called from outside (fe_cc_hooks_to_backend's dump_namelist 0x067378,
    which unix_objmod calls, and coproc_$suppress_warnings 0x06737A).
    The exception to 1; dpc emits the same `rts`.
14. **No frame for an internal routine without locals or calls.**
    c_macro_utl's end_of_text_chain 0x059C84 reads its parameter at
    (4,SP) and returns in A0 with no `link`; c_cond_read's
    push_current_state 0x0409C0 and pop_current_state 0x0409D2 (no
    parameters) are three instructions and `rts'.  An internal routine
    that calls (c_macro_utl's hash_value) or has locals gets a frame.

## Data layout (records)

15. **A character array after a byte field is not word-aligned.**
    c_macro_utl's macro record (4110 bytes from PAS_$NEW) has a byte
    at +12 and the 4096-character name at +13 (mu_$lookup_name 0x058F76
    `pea (13,A3)'); dpc aligns the array to +14.

