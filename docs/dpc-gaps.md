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
   width, "expected `)`, found `:`".  Reproducer:

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
       end;
