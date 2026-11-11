# dpc gaps met translating the DOMAIN C 6.9 compiler

Constructs the language reference allows and the image needs that dpc
refuses.  The Pascal keeps the construct; `tools/cc_check.sh` compiles a
scratch copy with the rewrite listed in `tools/cc_gap_rewrites.txt`, so
that the unit's other routines are still compared.  Report these to the
domain-pascal project (and to `../source/docs/pascal-translation-notes.md`
when this tree is merged).

1. **Assignment of a whole varying string longer than dpc copies.**
   `line_prefix := prefix` of two `varying [200] of char` module variables
   (diag.pas `about_to_write_to_line`, 0x068438: the image copies
   `(length + 2) / 4 + 1` longwords with `move.l (A0)+,(A1)+; dbf`).
   dpc: "a 206-byte value is not supported yet" (diag.pas:76).
   Reproducer:

       module g1;
       var a, b: varying [200] of char;
       procedure p;
       begin
         a := b;
       end;

2. **Real arithmetic.**  A real constant (`1.0`), real division, and
   the assignment of a double to a single (`real := double`, the
   conversion Rev 8.89 does with `jsr fpp_$`): token.pas get_reciprocal
   0x098E48 (`r := 1.0 / t^.real_value'), token_$make_real_lit_pair
   0x098F2E (`sa.r := a').  dpc: "a real constant is not supported
   yet", "real arithmetic is not supported yet", "Assignment statement
   expression is not compatible with the assignment variable (real :=
   double)".  Reproducer:

       module g2;
       var d, e: double; s: real;
       procedure p;
       begin
         d := 1.0 / e;
         s := d;
       end;

3. **`in` on a constant set with a word element.**  `t^.kind in [77..87,
   101, 200]` (token.pas set_is_nil 0x09930E: `move.w #207,D0; sub.w
   kind,D0; bcs; lsr.w #3,D0; btst kind,(set,D0.w); ble', the set a
   26-byte constant after the routine).  dpc: "`in` on a constant set of
   more than a longword with an element of more than a byte ... is not
   supported yet" (it names the `ble').  Reproducer:

       module g3;
       var k: integer; b: boolean;
       procedure p;
       begin
         b := k in [77..87, 101, 200];
       end;

4. **A nested routine declared `forward`.**  il_utils.pas: search_point
   (0x07E206) and search_walk (0x07E252), nested in
   il_utils_$search_tree_for_node, call each other; search_point comes
   first in the image, so search_walk is declared forward.  dpc: "a
   nested routine declared `forward` ... is not supported yet".
   Reproducer:

       module g4;
       procedure p;
         procedure b(n: integer); forward;
         procedure a(n: integer);
         begin
           if n > 0 then b(n - 1);
         end;
         procedure b;
         begin
           if n > 0 then a(n - 1);
         end;
       begin
         a(3);
       end;
