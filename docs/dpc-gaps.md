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

2. **A `case` whose labels are too sparse for dpc's jump table and too
   dense for its compare chain.**  errorlst's case on the character
   after '@' (c_error.pas, cc.m68k 0x0498B0: `subi.w #48; cmpi.w #35;
   bcc' and a 35-entry jump table at 0x0498C8) has 12 labels ('0'..'9',
   'L', 'R') over the range '0'..'R'.  dpc: "a `case` of 12 labels over
   a range of 35 (between the sparsest jump table and the densest
   compare chain seen, codegen-patterns 7.3) is not supported yet".
   Rev 8.89 builds the table.  Reproducer:

       module g2;
       var n: integer;
       procedure p(c: char);
       begin
         case c of
           '0', '1', '2', '3', '4', '5', '6', '7', '8', '9': n := 1;
           'L': n := 2;
           'R': n := 3;
           otherwise n := 4;
         end;
       end;

3. **`new` and `dispose`.**  c_macro_utl's mu_$enter_name (cc.m68k
   0x058FDC: PAS_$NEW with 0x100E), mu_$alloc_tle (0x05993C, 134182)
   and mu_$initialize (0x059220, PAS_$DISPOSE).  dpc: "undefined
   identifier `new`".  Reproducer:

       module g3;
       type r_t = record a: integer; end;
       var p: ^r_t;
       procedure q;
       begin
         new(p);
         dispose(p);
       end;

4. **`write` and `writeln` to standard output, and field widths.**
   c_macro_utl's messages and mu_$dump (PAS_$WRITE, PAS_$WRITELN on the
   file at (-4,A5); `write(m^.name:m^.name_len)' passes the array, its
   size and the width).  dpc: "undefined identifier `writeln`"; with a
   width, "expected `)`, found `:`".  Also lang/bind/source/objio.pas's
   check_init (0x088028, PAS_$WRITE and PAS_$WRITELN).  Reproducer:

       module g4;
       var s: array [1..10] of char; n: integer;
       procedure q;
       begin
         writeln('text');
         write(s:n);
         writeln;
       end;

5. **A field displacement beyond 16 bits.**  c_macro_utl's text list
   block (134182 bytes) has its flags at +0x20C04 and its bitmap at
   +0x20C06 (mu_$alloc_tle 0x05983A: `move.l #134148,D0; tst.b
   (0,A0,D0.l)').  dpc: "a displacement beyond 16 bits is not supported
   yet".  Reproducer:

       module g5;
       type b_t = record a: array [0..70000] of char; f: boolean; end;
       var p: ^b_t;
       procedure q;
       begin
         p^.f := true;
       end;

6. **A single real where a double is expected.**  `rlcontk(r)` with
   `r: real` and rlcontk's `in value: double` (token.pas
   `token_$single_float_to_constant`, 0x073716: the image widens r with
   FPP_$ESLV into a temporary and passes its address).  The reference
   allows single and double to mix (its UNIV example assigns `(s + t) /
   2.0` of singles to a double).  dpc: "Assignment statement expression
   is not compatible with the assignment variable (double := real)"
   (token.pas:143); `d := r` and real constants are refused too
   ("a real constant is not supported yet").  Reproducer:

       module g6;
       function rlcontk(in value: double): univ_ptr; extern;
       function f(r: real): univ_ptr; options(val_param);
       begin
         f := rlcontk(r);
7. **Real arithmetic.**  A real constant (`1.0`), real division, and
   the assignment of a double to a single (`real := double`, the
   conversion Rev 8.89 does with `jsr fpp_$`): token.pas get_reciprocal
   0x098E48 (`r := 1.0 / t^.real_value'), token_$make_real_lit_pair
   0x098F2E (`sa.r := a').  dpc: "a real constant is not supported
   yet", "real arithmetic is not supported yet", "Assignment statement
   expression is not compatible with the assignment variable (real :=
   double)".  Reproducer:

       module g7;
       var d, e: double; s: real;
       procedure p;
       begin
         d := 1.0 / e;
         s := d;
       end;

8. **`in` on a constant set with a word element.**  `t^.kind in [77..87,
   101, 200]` (token.pas set_is_nil 0x09930E: `move.w #207,D0; sub.w
   kind,D0; bcs; lsr.w #3,D0; btst kind,(set,D0.w); ble', the set a
   26-byte constant after the routine).  dpc: "`in` on a constant set of
   more than a longword with an element of more than a byte ... is not
   supported yet" (it names the `ble').  Reproducer:

       module g8;
       var k: integer; b: boolean;
       procedure p;
       begin
         b := k in [77..87, 101, 200];
       end;

9. **A nested routine declared `forward`.**  il_utils.pas: search_point
   (0x07E206) and search_walk (0x07E252), nested in
   il_utils_$search_tree_for_node, call each other; search_point comes
   first in the image, so search_walk is declared forward.  dpc: "a
   nested routine declared `forward` ... is not supported yet".
   Reproducer:

       module g9;
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

10. **Ordering arrays of char.**  `a[i]^.idnt_name > pivot^.idnt_name`,
   two `array [1..4096] of char` (sortidntk.pas qsort 0x098598: `move.w
   #4095,D0; cmpm.b (A0)+,(A1)+; dbne D0' then `bhi', `bcs', `bls').
   dpc: "ordering records is not supported yet" (with a best-effort
   warning on comparing arrays).  Reproducer:

       module g10;
       type n_t = record len: integer; name: array [1..4096] of char; end;
       var a, b: ^n_t; r: boolean;
       procedure p;
       begin
         r := a^.name > b^.name;
       end;

11. **A pointer function's result compared with a variable.**
   `get_bucket(main_index) = b` (pds.pas append_root_rec_to_bucket,
   cc.m68k 0x06CF9C: `bsr.w get_bucket; cmpa.l A3,A0; bne'; also
   append_to_merge_list 0x070BE6, 0x070C62).  dpc: "comparing the value
   of a function whose result is in A0 other than `=` / `<>` with a
   constant is not supported yet".  Reproducer:

       module g11;
       type r_t = record a: integer; end;
         r_p = ^r_t;
       var g: r_p; n: integer;
       function f(i: integer): r_p; options(val_param);
       begin
         f := g;
       end;
       procedure p(b: r_p); options(val_param);
       begin
         if f(1) = b then n := 1;
       end;

12. **Testing an element of a packed array of more than 256 booleans.**
   pds.pas's bitmaps of the files a bucket or a scope refers to
   (`packed array [1..2048] of boolean', reached through a pointer):
   `if (i <> main_index) and scope_refs^[i]' (pds_$end_scope 0x06D7C6:
   `subq.w #1; lsr.l #3; andi.b #7; moveq #7; sub.b; btst Dn,(0,A1,D2.l)'),
   dag_visit 0x070D9C, build_dependency_graph 0x070EC4, and do_merge's
   `m^.refs^[i] := m^.refs^[i] or node^.bucket^.refs^[i]' (0x070B0E).
   dpc: "testing an element of a packed array of more than 256 booleans
   (the byte arithmetic of the 64-element sites would not reach it,
   codegen-patterns 5.2) is not supported yet"; as an operand of
   `and'/`or', "an element of a packed array of booleans as a value
   other than a condition ...".  Reproducer:

       module g12;
       type bits_t = packed array [1..2048] of boolean;
       var b: ^bits_t; n: integer;
       procedure p(i: integer); options(val_param);
       begin
         if b^[i] then n := 1;
       end;
