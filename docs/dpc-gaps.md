# dpc gaps met translating the DOMAIN C 6.9 compiler

Constructs the language reference allows and the image needs that dpc
refuses.  The Pascal keeps the construct; `tools/cc_check.sh` compiles a
scratch copy with the rewrite listed in `tools/cc_gap_rewrites.txt`, so
that the unit's other routines are still compared.  Report these to the
domain-pascal project (and to `../source/docs/pascal-translation-notes.md`
when this tree is merged).

## Status (dpc fixes)

- **Gaps 2, 8, 12, 24: fixed in domain-pascal eaddf6c; their remaining
  variants (`in' on a set expression of more than a longword, any
  calling right operand of plain `and'/`or', two pointer functions'
  results compared) in 72d3ee3 (2026-11-11).**
- **Gap 3 (short-form `new'/`dispose') and gap 15 (a parameter assigned
  to a pointer result): fixed in fad3e37.**  The long form of `new'
  with tag constants is still refused.
- **Gaps 9 (nested `forward'), 11 (`nil' as a pointer function's
  result) and 23 (`in' on a one-word constant set with a char, byte or
  4-byte element; a boolean element is still refused): fixed in
  6aabd92 and 1240eb7.**  Their 18 rules removed.
- **Gaps 13 (packed boolean arrays: tests up to 65536 elements,
  constant indices, values under and/or) and 21 (routine parameters):
  fixed in 307a0fb and 78f475b.**  An integer32 variable as a packed
  boolean index: a228d3c.  Still refused: nested or internal routines
  passed as routine parameters (reg_color_68k, debug_sym_dmp; the
  image builds an 18-byte trampoline in the parent's frame, sent to
  domain-pascal), whose rules are marked "[still needed with dpc
  78f475b]".
- **Gaps 17 (string constant to a varying string), 18 (string constant
  to a varying parameter), 22 (`ord' of a boolean), 33 (a function
  returning a 4-byte array) and 34 (string constants to short char
  arrays): fixed in 3e7b09c and ca0dd28.**  Their rules removed, but
  for cg_call's gap 22 rule: without it the routine meets gap 28.
- **Gap 30 (`in' on a set held in a register, as a value or under
  `and'): fixed in 8cd3f59.**  Its rules (reg_save, com, dbg_life)
  removed.
- **Gap 35 (the internal error): fixed in c83ade9** (a plain bug fix:
  a call inside another unit's array index cleared the held array
  bases).  sched_utils' temporary removed.
- **Gap 36 (a pointer result of a call through a routine pointer or
  parameter): fixed in 3bad22b.**  Its rule removed (lir_utils still
  needs gap 21's stand-in for the nested new_db_lts).
- Gap 28 is gap 25 in another form (domain-pascal's diagnosis): the
  spiller finds values to spill but runs out of virtual register
  numbers (240 per class) adding the reloads, and the colouring's
  message is reported.  Widening the numbering, with the
  domain-pascal owner as part of 25, would cover both.
- Gap 32 is queued in domain-pascal; `while true do' is refused on
  purpose (the image cannot tell it from `repeat ... until false'):
  write such loops with a label.
- All compile best effort (a warning; `--strict' still refuses).  Their
  rewrites are gone from tools/cc_gap_rewrites.txt (283 rules removed in all);
  the full gate is clean without them.
- Gaps 4 (write/writeln) and 7 (real arithmetic) are not being worked
  on in dpc for now (the domain-pascal owner's choice).

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
   Rev 8.89 builds the table (also runbackend.pas normalize_il, cc.m68k
   0x0B1AC0: 10, 11, 15, 21 over 10..21, a table of 12).  Reproducer:

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

   Also delay.pas delay_$shrink_top_level_node (0x07907E): a case on a
   node's kind of 4 labels (140, 139, 142, 151) over a range of 13, a
   compare chain in the image (`cmpi.w #140; beq; cmpi.w #139; ...').
   dpc: "a `case` of 4 labels over a range of 13 ... is not supported
   yet"; the check adds empty labels for the other 9.

   Also cg_addr.pas address (cc.m68k 0x0F1C38: `subi.w #77; cmpi.w
   #136; bcc', a 136-entry jump table on the node's kind): 46 labels
   over 77..212.  dpc: "a `case` of 46 labels over a range of 136
   ... is not supported yet"; the check adds the otherwise's 90 kinds
   as labels of the cgerr.

   Also cg_tree.pas compare_proc (cc.m68k 0x10386E, translator DD):
   `case n^.desc.w6 of 2, 3, 12, 13' as a jump table of 12 from 2
   (six labels added for the check).

   Also zzzzz.pas zzzzz_$process_routine (cc.a88k 0x2882A8, translator
   MM): the -EXP listing's case on the opcode, 75, 79, 81, 88, 89, as a
   jump table of 15 from 75 (`subi.w #75; cmpi.w #15; bcc'); dpc: "a
   `case` of 5 labels over a range of 15"; the check adds the other ten
   as empty labels.
   Also opt_strength.pas (translator FF): ptrsub's case of 139, 140,
   142, 151 (a compare chain at 0x0E7786).

   Also final.pas (translator JJ): deltest's `case' of the op (cc.m68k
   0x10C8B0: a table of 22 from 102) with 8 labels (102..104, 107..109,
   119, 123); the check adds the otherwise's 14 ops as labels.

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

   Also opt_strength.pas (translator FF): newexpr, newindvar (new of
   8-byte list cells, PAS_$NEW 8) and strengthreduce (dispose).

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

   Also opt_main.pas (translator II): realloc_postorder_node_list's
   `trunc(old * 1.05)' (0x0DB07C) and convert_exponentiation's
   `trunc(e^.real_value)' compared back with the real (0x0DE046):
   "undefined identifier `trunc`", and under --check-only "operands of
   the comparison are not compatible" for the integer compared with a
   double.
   Also final.pas floatop (translator JJ, cc.m68k 0x10FB84): `n^.real_value
   = 0.0' (FPP 0x0074 0xFF34), `iv := trunc(v.d)' (0x0074 0x00D0), `iv
   <> v.d' (0x00C4 0x00B4), and the copy of a double into a variant
   record, `v.d := n^.real_value' (dpc: "a 8-byte value is not
   supported yet"); the check compares and copies the longwords.
   Also lst.pas lst_$display_literal (translator PB, cc.a88k
   0x251878): a single literal held as a double converted for
   lib_$cv_sfp_out (FPP 0x0074 0x00D4 0xFF3E); the check leaves it
   unset.
   Also ra_utils.pas (translator PB5): spill costs stored as single
   real constants (`cost.r := 0.0', `:= 1.0': `clr.l', `move.l
   #0x3F800000'), and `round(n * 0.9)', `round(n * 0.75)', `round(n *
   0.6)' of integers (FPP 0x00BC or 0x00C4, 0x00A0 <double>, 0x0154
   0x0068): "a real constant is not supported yet", "undefined
   identifier `round`"; the check stores the bits and uses integer
   arithmetic.

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
   Also lst.pas lst_$display_code_cell (translator PB, cc.a88k
   0x251172, 0x2511CE, 0x251684): an operand's symbol's kind against a
   26-byte constant of IL kinds ([45..58, 60, 61, 69, 156, 176, 198,
   200]); one rule rewrites the three into comparisons.

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

11. **`nil` as a pointer function's result.**  cargs.pas
   arg_option_parameter (cc.m68k 0x0B27AC): `arg_option_parameter :=
   nil' on one path (the image `suba.l A0,A0', 0x0B27F2).  dpc: "`nil`
   as a pointer result where every assignment of the result is the last
   statement of a path ... is not supported yet".  Reproducer:

       module g11;
       type p_t = ^integer;
       var q: p_t; b: boolean;
       function f: p_t;
       begin
         if b then
           f := q
         else
           f := nil;

   Also met by translator S in add_node.pas: a pointer function whose
   body is the one statement `f := nil' (make_temp 0x09F9BC,
   make_char_temp 0x09F9D6: `movea.l #0,A0' between the A5 load and
   the restore).  dpc: "a pointer function body of the one statement
   `f := nil` (no site; ...) is not supported yet".  Reproducer:

       module g11s;
       type p_t = ^integer;
       function f(n: integer): p_t; options(val_param);
       begin
         f := nil;
       end;

12. **A pointer function's result compared with a variable.**
   `get_bucket(main_index) = b` (pds.pas append_root_rec_to_bucket,
   cc.m68k 0x06CF9C: `bsr.w get_bucket; cmpa.l A3,A0; bne'; also
   append_to_merge_list 0x070BE6, 0x070C62).  dpc: "comparing the value
   of a function whose result is in A0 other than `=` / `<>` with a
   constant is not supported yet".  Reproducer:

       module g12;
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

   Also met by translator H in c_lex_pp/c_main (same refusal):
   **A pointer function's result compared with a variable.**
      c_lex_pp.pas ppio_$get_line (0x0562AE): `if
      spos_$region_user_name(spos_$region) = std_include_tok' (`jsr;
      addq.w #4,SP; cmpa.l (10972,A5),A0').  dpc: "comparing the value of
      a function whose result is in A0 other than `=` / `<>` with a
      constant is not supported yet".  Reproducer:
   
          module g12h;
          var p: univ_ptr; b: boolean;
          function f(n: integer32): univ_ptr; options(val_param); extern;
          procedure q;
          begin
            b := f(1) = p;
          end;

   Also utils.pas (translator PA): utils_$remove_lts_from_exposed_list
   and _final_list's `if utils_$find_exposed_lts(lr, bb) <> lts'
   (cc.a88k 0x284D58: `bsr.w; addq.w #8,SP; cmpa.l A2,A0; beq'); the
   rewrite swaps the operands.

13. **Testing an element of a packed array of more than 256 booleans.**
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

       module g13;
       type bits_t = packed array [1..2048] of boolean;
       var b: ^bits_t; n: integer;
       procedure p(i: integer); options(val_param);
       begin
         if b^[i] then n := 1;
       end;
   Also bin.pas (translator PB, cc.a88k): a routine's statement bits
   (`packed array [0..65535] of boolean' through a pointer) in
   map_statement_to_src_loc_and_offset (0x223396: `btst' of 7 less
   stmt mod 8 in the byte stmt div 8) and, with the constant index 0,
   put_procedure_start (0x223C1C: `tst.b (A0); bpl'): dpc "an element
   of a packed array of booleans with a constant index (no site in the
   image, codegen-patterns 5.2) is not supported yet" for the second.

14. **A non-local `goto`.**  c_lex_pp.pas: get_character (cc.m68k
   0x054DBA), get_comment (0x054DFA) and get_identifier (0x055336),
   nested in get, leave get for its end (0x055F20) at the end of the
   source: `pea label; move.l frame,-(SP); jsr pas_$nlg2' with get's
   frame (from A1, kept at (-4,A6), or the routine's dynamic link);
   get keeps A5 at (-16,A6) and reloads it at the label.  dpc: "a
   `goto` to a label of an enclosing routine (a non-local `goto`, ref
   p. 4-97; its frame unwinding has not been looked for in the image)
   is not supported yet".  Reproducer:

       module g14;
       var n: integer;
       procedure p;
       label 9;
         procedure q;
         begin
           if n > 0 then goto 9;
           n := 1;
         end;
       begin
         q;
         n := 2;
       9:
         n := 3;
       end;

15. **A pointer result assigned from a parameter.**  c_lex_pp.pas
   clex_$catstring (0x055FE4): `clex_$catstring := s1' (or s2) on the
   paths that give up (`movea.l A2,A0' / `movea.l A3,A0' and a branch
   to the epilogue).  dpc: "a pointer result in a body of several
   statements assigned other than a pointer function's result, a
   variable or `nil` ... is not supported yet".  Reproducer:

       module g15;
       type p_t = ^integer;
       var n: integer;
       function f(a: p_t; b: p_t): p_t; options(val_param);
       begin
         if a = nil then begin
           f := b;
           return;
         end;
         n := 1;
         f := a;
       end;

16. **`ptoc` and `ctop`** (reference 4-149, 4-61).  c_main.pas addarg
   (cc.m68k 0x05A5D2: `pea (-1040,A6); jsr pas_$ptoc' on the copy of
   its varying parameter), preprocess (0x05A99E pas_$ptoc, 0x05ACBE
   pas_$ctop).  dpc: "undefined identifier `ptoc`".  Reproducer:

       module g16;
       var s: varying [1024] of char;
       procedure p;
       begin
         ptoc(s);
         ctop(s);
       end;

17. **A string constant assigned to a varying string.**  c_main.pas
   preprocess: `arg := '-D__apollo'' and nine others (cc.m68k 0x05AB2A:
   the length word and the characters copied from a literal laid out
   as a varying string, `lea (lit,PC),A0; move.l (A0)+,(A1)+ ...').
   dpc: "Assignment statement expression is not compatible with the
   assignment variable (arg_t := string of 10 characters)".
   Reproducer:

       module g17;
       var s: varying [1024] of char;
       procedure p;
       begin
         s := '-D__apollo';
       end;

18. **A string constant passed to a varying parameter.**
   commit_top_node.pas commit_top_$convert_aops_to__aop_to_mem (cc.m68k
   0x0760B8) passes 'Compiler may not guarantee atomic behavior.' to
   token_$make_string_token's `in s: univ token_$vstring_t': the image
   passes a varying constant (the word 43, then the text, at 0x07613A).
   The reference converts a string constant to a varying string in
   assignments and value/`in' arguments (3.11.4).  dpc refuses it for a
   varying parameter ("Assignment statement expression is not
   compatible with the assignment variable (v_t := string of 16
   characters)") and passes the characters alone (no length word) for a
   univ one, which the translation uses (no rewrite).  Reproducer:

       module g18;
       type v_t = varying [32767] of char;
       procedure f(in s: v_t); extern;
       procedure p;
       begin
         f('Compiler may not');
       end;

19. **A function returning a single real.**  kfold.pas's dbl_to_real
   (cc.m68k 0x0ACDC2) returns the single in D0; unix_objmod.pas
   emit_constant (0x09A450: `jsr dbl_to_real; move.l D0,(-32,A6)')
   stores it in a real local and emits its four bytes.  dpc: "functions
   returning real are not supported yet (codegen-patterns 3: result
   convention unknown)".  Reproducer:

       module g19;
       var s: real;
       function f(n: integer): real; options(val_param); extern;
       procedure p;
       begin
         s := f(1);
20. **A set expression passed to an `in` parameter.**  c_expr_syn.pas
   func_call_stat `check(102, follow + [ctk_lparen])' (cc.m68k 0x050970:
   the 14-byte set formed in a frame temporary with `or.l'/`or.w' and
   `pea' of it) and primary_expr `eval_expr(s + [ctk_rparen])'
   (0x050FAC).  dpc: "a 14-byte expression passed by address is not
   supported yet".  Reproducer:

       module g20;
       type s_t = set of 0..111;
       procedure q(in s: s_t); extern;
       procedure p(in f: s_t);
       begin
         q(f + [61]);
       end;

21. **A routine parameter** (reference 5.4).  c_syntax's cc_walk_it
   takes a routine (c_stmt_sem's add_cbranch and c_expr_sem pass
   call_kfold: `move.l #0x066162,-(SP)'), declared in c_externs.ins.pas
   as a routine pointer by value (c_walker_t, `^procedure(var n:
   il_$node_ptr_t)', called as walker^(t)) and given addr(call_kfold),
   which dpc compiles the same way.  dpc: "a routine parameter (ref 5.4) is not supported
   yet".  Reproducer:

       module g21;
       type p_t = ^integer;
       procedure kf(var n: p_t); extern;
       procedure walk(var t: p_t; procedure f(var n: p_t); b: boolean);
           options(val_param); extern;
       procedure q(t: p_t); options(val_param);
       begin
         walk(t, kf, false);

   Also ra_utils.pas ra_utils_$add_spill_code (translator PB5): its
   nested new_db_lts passed to lir_utils_$flesh_out_new_load_or_store
   (the image's 18-byte trampoline at -148, then cache_$clear), as in
   lir_utils' fix_store_through_lrs: "the address of a nested routine
   cannot be taken"; the check passes a module-level stand-in.
22. **`ord` of a boolean.**  attributes.pas attr_curr_align_env
   (cc.m68k 0x0A63F6: `moveq #1,D0; and.b 0x2C3677,D0', the packed
   boolean cargs_$options.b28b_0 as 0 or 1 in a word result).  The
   reference defines `ord' for any ordinal type, boolean included
   (false 0, true 1).  dpc: "this predeclared function is not
   supported yet" (for an unpacked boolean too).  Reproducer:

       module g22;
       var r: packed record a: boolean; b: boolean; end;
         b: boolean; n: integer;
       procedure p;
       begin
         n := ord(b);
         n := ord(r.b);
       end;
   Also bin.pas (translator PB, cc.a88k): add_unwind_rec's and
   bin_$emit_compilation_pure_text's traces print booleans as 0 or 1
   (`lsr.b #7' of the byte, 0x223874, 0x22455C).

23. **`in` on a one-word constant set with a byte element.**  The
   alias descriptor's class, a byte of a packed record (0..255):
   alias.pas alias_ptr_node `d.class in [alias_xdb_relative,
   alias_xsf_relative]' (cc.m68k 0x073BC8: `clr.w D0; move.l #0xC000,D1;
   move.b (18,A3),D0; btst D0,D1'), check_the_ind, get_alias_desc,
   alias_$ind_for_captured_lvalue, formal_may_alias_actual.  dpc: "`in`
   on a one-word constant set with a one-byte element (boolean, char,
   `[byte]`: no site ...) is not supported yet" (the longword sets of
   the same element pass).  Reproducer:

       module g23;
       var r: packed record c: 0..255; f: boolean; end; b: boolean;
       procedure p;
       begin
         b := r.c in [14, 15];
       end;

24. **A function call as a right operand of `or'.**  alias.pas
   get_alias_desc (cc.m68k 0x0740CA: `cmpi.w #153; beq; cmpi.w #211;
   beq; cmpi.w #154; beq; pea; bsr.w is_display_ptr; tst.b D0; bpl'):
   `(y^.kind = 153) or (y^.kind = 211) or (y^.kind = 154) or
   is_display_ptr(y)'.  dpc: "a right operand of a plain `and`/`or`
   with a call other than a comparison of the function's result is not
   supported yet" (`... or (is_display_ptr(y) = true)' passes).
   Reproducer:

       module g24;
       var k: integer; b: boolean;
       function f(n: integer): boolean; options(val_param); extern;
       procedure p;
       begin
         if (k = 1) or f(k) then b := true;
       end;

   Also opt_inline.pas (translator KK): function_return's `(b^.kind =
   108) and assert_routine_returns_void(b)' (cc.m68k 0x08F690);
   process_operand's `(t^.xp[17]^.kind = 155) and not
   inline_$is_fortran_asf(e^.caller)' (translator NN, 0x0924F6).
   Also opt_strength.pas (translator FF): `and check_tree_node(t)'
   (checkauto 0x0E7F92), `and opt_str_$is_loop_constant_integer(...)'
   (recognize_induction_variables 0x0EA862), `and
   il_utils_$is_strength_reduction_temp(...)' (reduce 0x0EB03E).

   Also final.pas (translator JJ): a negated call as an operand, `... and
   not testcc(p, 15)' in try_long_extend_opts (0x111130) and `and not
   has_untouchable_mem_attrs(c^.ads2)' in final_$try_reducing_literal
   (0x10A492): the generic rule's `not ((f(...)) = true)' is refused
   too; a second rule makes it `((f(...)) = false)'.

Gap 21 (a routine parameter, reference 5.4; translator L's entry) also
met in debug_sym_dmp.pas (translator N), where it differs in two ways:

- The routines passed are nested (write_files' add_file_table_entry,
  write_string_for_file_table_entry, add_unit_table_entry and
  debug_sym_dmp_$init's add_file_entry, passed to
  spos_$apply_over_marked_source_files and spos_$apply_over_source_files:
  `pea' of a trampoline built in the parent's frame,
  docs/rev889-patterns.md 12), so L's way out (a univ_ptr given
  addr(routine)) is closed: the reference forbids the address of a
  nested routine (3.13.3, p. 3-50; dpc: "the address of a nested
  routine cannot be taken").  The headings must take a routine
  parameter.
- The heading is in a shared insert (lang/common/source/spos.ins.pas,
  opened by every unit that opens spos), and dpc refuses the
  declaration even where nothing calls it, so a rewrite of the unit
  alone cannot keep the other units checked.  tools/cc_check.sh now
  applies tools/cc_gap_rewrites.txt rules naming an insert to a scratch
  copy of the insert, which every unit's compilation finds first (dpc
  looks in its working directory before the -I directories); the spos
  headings go back to the routine pointer types spos_$region_proc_t and
  spos_$marked_region_proc_t there, spos.pas calls them with `^', and
  debug_sym_dmp's calls pass nil.  Reproducer (the nested routine):

      module g21n;
      procedure apply(procedure proc(region: integer32)); extern;
      procedure p;
      var n: integer32;
        procedure q(region: integer32); options(val_param);
        begin
          n := region;
        end;
      begin
        apply(q);
      end;

  The reference gives no syntax for the options of a routine
  parameter's own parameters (the routines passed are val_param; the
  only trace is the error "Incompatible routine OPTIONS"), so the
  headings give none (a TODO in spos.ins.pas).
   Also reg_color_68k.pas (translator EE): color_graph passes its
   nested targetfunctionresult, computecommonregs, setcommonregs and
   paint's nested checkout to walkconflicts (cc.m68k 0x0C51C0, `pea'
   of a trampoline at -52, -74, -92, -36); walkconflicts is the unit's
   own, so the rewrite gives it a routine pointer (rc_walk_t, called
   with `^') and the calls pass nil.
   Also cg_tree.pas (translator AA): `or assert_is_f_math_op(...)',
   `and consecutivebits(...)' (needs_lib_support 0x0FF0AA, const_mul
   0x0FFF22).  And (translator DD) `or unaligned(...)' (agg_compare_proc
   0x101674) and `and (peek(...) in [16..23])' (generate's floating
   negation, 0x10606E: the check keeps the lower bound).
   Also cg_assign.pas (translator AA): `and not (k in getphase(n))',
   `and not check_use(...)', `or unaligned(...)', `and
   register_tickle(...)', `and zero_check(...)' and `(rlen = 5) and
   ((peek(...) <> 31) or ...)' (assign_proc 0x0F469E, agg_assign_proc
   0x0F3826): the rewrites compare the results with true or false, or
   put the call first.
   Also reg_save.pas (translator HH): `or cg_call_$is_proc_var_call(...)'
   (registers_consumed_by_tree_operator, cc.m68k 0x0EC8E6) and
   `unaligned(...) or unaligned(...)' (registers_consumed_by_agg_aop
   0x0ECB9C, evaluated whole); the rewrites compare with true.
   And emit.pas: fnl_slct's `chk_op_restr(...) and chk_op_restr(...)
   and chk_sz_restr(...)' (cc.m68k 0x0B750A, evaluated whole).

25. **A routine needing more virtual registers than dpc numbers.**
   c_expr_sem.pas expr_op (cc.m68k 0x04CDBA, 0x2B7A bytes of code, some
   900 lines of Pascal in one body) exhausts dpc's virtual register
   numbers (regs.rs new_reg: VBASE plus a u8 counter per class, never
   reused within a routine) about a third of the way through: "a
   routine needing this many registers is not supported yet".  The
   check compiles expr_op with its cases from subtraction on left out
   (a conditional variable that is not set: tools/cc_gap_rewrites.txt).
   kfold.pas kfold_$general (0x0AD1A0, 0x223C bytes) likewise: its
   integer operators and everything from its real operators on are left
   out.  Reproducer: any procedure of a few hundred statements that each
   index a record array, e.g.

       module g25;
       type e = record a, b: integer32; end;
       var t: array [1..100] of e; k: integer;
       procedure p;
       begin
         t[k].a := t[k + 1].b;   { ... repeated 300 times }
       end;

   Also met by translator Q in outbin (wr_instr, refused as a whole; the
   rewrite drops its operand-listing case):
   **A routine needing more registers than dpc allocates.**  outbin.pas
      wr_instr (cc.m68k 0x0C0464, 0x171A bytes, nested in outcode): with
      its listing of the operands (a `case' of 56 kinds at the end) dpc
      reports "a routine needing this many registers is not supported yet"
      at whatever statement comes last (moving with the code; reusing
      locals does not help); without that `case' the routine compiles.
      The rewrite drops the listing `case' from the scratch copy.  No small
      reproducer found (the size of the routine seems to matter).


   Also cg_tree.pas generate (cc.m68k 0x10484E, 0x3B38 bytes, a
   `case' of 74 operators; translator DD): its floating operators'
   arms (34 .. 42) are left out of the check (a conditional variable
   that is not set); tools/cc_typecheck.sh type-checks them.

   Also cg_assign.pas assign_proc (cc.m68k 0x0F469E, 0x2224 bytes):
   three conditional regions are left out of the check (the memory
   path's constant masks, unary operators and shifts; the register
   path's record of the register's new contents; the floating store
   through a floating register).

   Also ra_utils.pas ra_utils_$add_spill_code (translator PB5, cc.a88k
   0x270F0C, 0xD5E bytes): the reads that keep their live range or are
   narrowed to a smaller load (moves, TST/TSTB/TSTW, EXTEND7/15,
   EXTRACTU, floating control) are left out of the check; gap 28
   follows once they are.

26. **`substr`** (reference 4-189, an extension).  outbin.pas
   assert_is_an_fpx_command_instr (cc.m68k 0x0BBE28): `substr(chars, 1,
   len) = 'CommandCIR'' of a string constant's characters (pas_$ctov of
   120 characters into a varying temporary, pas_$substr from 1,
   pas_$str_compare with the varying constant at 0x0BBEE2).  dpc:
   "undefined identifier `substr`".  The rewrite compares the length.
   Reproducer:

       module g26;
       type c_t = array [1..120] of char;
       var b: boolean; a: c_t; n: integer;
       procedure p;
       begin
         b := substr(a, 1, n) = 'CommandCIR';
       end;


27. **A set constant passed to an `in` parameter.**  c_syntax.pas stat
   `error(101, [ctk_if, ...])' (cc.m68k 0x065630: `pea' of the 14-byte
   constant after the routine), enum_list `identifier([ctk_rbrace,
   ctk_assign, ctk_comma], 117, nm)', function_def `body([])',
   array_decl's constant_expr, parse_attributes and declaration's
   error and identifier calls.  dpc: "a 14-byte set constant passed by
   address (no site known) is not supported yet".  The rewrite
   (tools/cc_gap_rewrites.txt) declares a module variable gap25_s in
   the scratch copy and passes it for every set constant argument.
   Reproducer:

       module g27;
       type s_t = set of 0..111;
       procedure q(in s: s_t); extern;
       procedure p;
       begin
         q([1, 2, 100]);
       end;

   c_syntax also meets gap 8 (`in' on constant sets, and on `cases +
   [... 200]', a set expression), gap 20 (set expressions passed by
   address) and gap 7 (a real compared with 0.0, an integer converted
   to a double, trunc, double assignments); its rules are generic over
   the whole file (BEGIN { undef $/ }, the sets span lines).
28. **A routine whose values outlive dpc's registers and spill slots.**
   cg_call.pas gen_call (cc.m68k 0x0F720A, 0x15D2 bytes, some 750
   lines of Pascal in one body with two nested routines that use its
   locals): dpc reports "more values live at once than there are
   registers" at the routine's heading (regs.rs's colouring, then
   spill.rs's `choose' finding nothing to spill).  No one region is to
   blame: dropping either the call's code (the static link and the
   five ways of calling) or the loop over the registers after it
   (reg_save's set, the aliases of the arguments) lets it compile, any
   smaller cut does not.  The rewrite drops the loop over the
   registers.  Reproducer: gen_call itself (no small one found; the
   size of the routine seems to matter, as in gap 25's wr_instr).
   Also add_node.pas add_tn (0x0A1ABC, 0x30AE bytes): its reassociations
   and its constant folding are left out of the check (two conditional
   regions); the gap 8 rule for add_node rewrites every `in' on a
   constant set into comparisons with one perl substitution (`/e').
   Also lst.pas lst_$display_code_cell (translator PB, cc.a88k
   0x250A0A, 0xD28 bytes): the classic form's registers' column (a
   loop of three) is left out of the check.
   Also ra_utils.pas ra_utils_$add_spill_code (translator PB5, cc.a88k
   0x270F0C, 0xD5E bytes, after gap 25's cut): the linking of a
   store's later readers to the stored register is left out of the
   check (a conditional variable that is not set).

29. **`in` on a 32-byte set variable with an element beyond 0..255.**
   list_tree.pas print_top_node (cc.m68k 0x08356A): `i in
   t^.st_used^' with i a longword loop index and the set `set of
   0..255' behind a pointer, tested as `move.w #255,D0; sub.w D4,D0;
   bcs; lsr.w #3,D0; btst D4,(A0,D0.w)' (the guarded test).  dpc:
   "`in` on a 32-byte set with an element whose type reaches beyond
   the set's 256 bits (the guarded test, NAME_$INIT 0xE3183E,
   codegen-patterns 5.1) is not supported yet".  The check replaces
   the test with `i <= 255'.  Reproducer:

       module g29;
       type s_t = set of 0..255;
       var s: ^s_t; i: integer32; b: boolean;
       procedure p;
       begin
         b := i in s^;
       end;

30. **`in' on a set held in a register as an operand of `and'.**
   reg_save.pas tally_extra_temp_regs_needed (cc.m68k 0x0EBF4E): `if
   (b in s) and (b in [27..29]) then ... else if (b in s) and (b in
   [24..26]) ...' with s a value parameter (a set of 0..31, kept in D0;
   the image tests `btst D2,D0' before each class's mask).  dpc: "`in`
   on a set held in a register, as a value, is not supported yet".
   The rewrite drops the `b in s' tests from the scratch copy.
   Reproducer:

       module g30;
       type s_t = set of 0..31;
       var n: integer;
       procedure p(s: s_t; b: integer); options(val_param);
       begin
         if (b in s) and (b in [27..29]) then
           n := 1;
       end;

   Also com.pas process_instruction (translator PC4, cc.a88k 0x22B46C):
   a local `seen: set of 0..31' (the operand numbers whose birthpoints
   are cached) that the image keeps in D6 (`btst D5,D6' after `cmpi.l
   #31,D5; bgt'; an element added by `bset' into a cleared frame
   longword and `or.l' into D6): `if (k <= 31) and (k in seen) then'
   draws the same message.  The rewrite makes the test `k <= 0' (never
   cached) in the scratch copy.  Reproducer:

       module g30b;
       var n: integer32;
       procedure p(k: integer32); options(val_param);
       var s: set of 0..31;
       begin
         s := [];
         if (k <= 31) and (k in s) then
           n := 1;
         s := s + [k];
       end;
   Also dbg_life.pas dbg_life_$find_symbols (cc.a88k 0x22DC08, translator
   PB4): `clobbered := (reg in set32) or (reg + 1 in set32)' with set32
   a local set of 0..31 (the image keeps it in D5: `btst D0,D5' and
   `btst D6,D5'); same message.  The rewrite tests the record's set.

31. **A set expression of more than a longword compared with `[]'.**
   final.pas floatop (cc.m68k 0x10FDF0): a double's low 29 bits tested
   as `v.s * [0..28] = []' with v.s a `set of 0..63' view of the real
   (`and.l' of the 8 bytes with a constant 0x00000000 0x1FFFFFFF in a
   frame temporary, `tst.l' of both longwords).  dpc: "comparing a set
   of more than a longword that is not a variable (no site known,
   codegen-patterns 5.1) is not supported yet".  The check masks the
   low longword.  Reproducer:

       module g31;
       type s_t = set of 0..63;
       var s: s_t; b: boolean;
       procedure p;
       begin
         b := s * [0..28] = [];
       end;

32. **An initialized overlay section named as its variable.**  The
   back end's named sections (`var (instruction_assembly)
   instruction_assembly: ...' in backend.ins.pas) are given their data
   by the .init files with a `define' statement (reference 7.2.2,
   method 2; docs/questions.md 161): asm.pas defines
   instruction_assembly, operand_string and operand_string_length,
   lst.pas instruction_mnemonic and instruction_mnemonic_length.  In
   Apollo's object module the variable is the section itself (offset
   0); dpc emits a global label for the variable beside the section's
   symbol and refuses the clash: "an overlay section named like a
   routine or variable symbol of the unit (`INSTRUCTION_MNEMONIC`) is
   not supported yet" (an uninitialized section, a .comm, passes).
   The gate renames the five sections (`_s') in backend.ins.pas's
   scratch copy.  Reproducer:

       module g32;
       var (tab) tab: array [0..1] of integer;
       define tab := [1, 2];
       procedure p;
       begin
         tab[0] := tab[1];
       end;

   Translator PB2 (asm.pas) also met gaps 22 (the traces' flags as 0
   or 1) and 25 (asm_$process_routine, 0x19A2 bytes: the check leaves
   out pass 1's literal and pipeline-kind code, from `{ Its
   literals. }' to label 2, and pass 2's immediate forms, `case form
   of' to `{ The forms done. }').  dpc refused `while true do' in
   dump_literal_pool (codegen-patterns 7.2: written with a label).

Translator PC (cc.a88k tr_utils) met gaps 8 (`opc in [77, 79..83]', a
word element: tst_elim_within_bb, validate_lts_for_tst), 11
(index_operand, base_operand: `:= nil' last), 12 (a pointer function
compared with a variable: bb_interval, base_operand,
utils_ins_$operands_instruction), 15 (bb_interval and
find_suitable_driving_lts_for_tst returning a parameter) and 24 (calls
as right operands of `and'); the rewrites are in
tools/cc_gap_rewrites.txt under tr_utils.

33. **A function returning a 4-character array.**
   dmp_$three_char_lr_name_from_lr (cc.a88k 0x232010) returns a live
   range's name, `packed array [1..4] of char', in D0 (`move.l
   (-8,A6),D0'; the callers store D0 and pass its address to vfmt).
   dpc: "functions returning dmp_$lr_name_t are not supported yet
   (codegen-patterns 3: result convention unknown)".  The gate
   rewrites the type to integer32 in backend.ins.pas (dmp.pas reads
   and writes the result through a variant).  Reproducer:

       module g33;
       type n_t = packed array [1..4] of char;
       var m: n_t;
       function f(i: integer): n_t; options(val_param);
       var r: n_t;
       begin
         r[1] := 'a'; r[2] := 'b'; r[3] := 'c'; r[4] := chr(i);
         f := r;
       end;
       procedure p;
       begin
         m := f(32);
       end;

34. **A string constant assigned to a short character array.**
   dmp's print_memory_home (0x2304E8) names a vat with 9-character
   constants, dmp_$instr_print_single_line a literal's kind with
   7-character ones (copied `move.l (A1)+; move.w (A1)+; move.b
   (A1)+'), print_lts_list tags with 4-character ones stored as
   longword immediates (`move.l #0x4A425020,(-36,A6)', 'JBP ').  dpc:
   "assigning a record or array that is not a variable is not
   supported yet" (7, 9 characters) and "a 4-character string constant
   as a 4-byte scalar value is not supported yet".  The gate stores one
   character instead.  Reproducer:

       module g34;
       var a: packed array [1..9] of char;
           b: packed array [1..4] of char;
       procedure p;
       begin
         a := 'externdef';
         b := 'JBP ';
       end;

Translator PB3 (dmp.pas) also met gap 4 (dmp_$instruction writes an
IL node kind as an enumerated value: `write('<object.kind= ',
an_kind_t(...), '>')', PAS_$WRITE with the run time's name table).

35. **An internal error on a function result dereferenced inside an
   index inside an `in' test, in a large routine.**
   sched_utils.pas sched_utils_$operand_delay (cc.a88k 0x279266, 0x5E8
   bytes, translator PB4): `if instruction_attributes[
   utils_ins_$operands_instruction(o)^.opc].class in su_branchy then'
   in one arm of a long `case'.  dpc panics: "internal error: insertion
   index (is 1) should be <= len (is 0) (at .../alloc/src/vec/mod.rs:
   1972; please report)", at the routine's first line.  The same
   expression elsewhere in the routine compiles, and so does the whole
   routine when any one arm is removed; no small reproducer was found.
   Worked around in the source with a temporary
   (`i := utils_ins_$operands_instruction(o)'), which the image's code
   allows (the result is in A0 either way); no gate rule.
36. **A pointer result of a call through a routine parameter.**
   lir_utils_$flesh_out_new_load_or_store (translator PA4, cc.a88k
   0x24D34C) takes `function new_db_lts: lts_ptr_t' (fix_store_through_
   lrs passes its nested routine, through a trampoline) and calls it
   for the DB register's segment (`jsr (A1)', the result in A0).  dpc:
   "a pointer result of a call through a routine pointer is not
   supported yet".  The rewrite assigns nil.  Reproducer:

       module g35;
       type p_t = ^integer;
       procedure q(var r: p_t; function f: p_t); options(val_param);
       begin
         r := f;
       end;

   Translator PA4 also met gap 21's nested case (new_db_lts passed;
   the rewrite passes a module-level stand-in), gap 7 (dpcontk(0.0)),
   gap 25 (fix_store_through_lrs: the stores after a written
   store-through register left out of the check) and gap 32
   (lir.pvt.pas's section spill_instr_forms).

37. **Byte module variables given a word each.**  lir_main's data
   (translator PA5, cc.a88k A5 0x48B3AC) has boolean cells at
   consecutive bytes (+0xC88, +0xC89, +0xC8B..+0xC8E), as Rev 8.89
   lays out byte variables; dpc pads every boolean or char module
   variable (own or defined) to two bytes, so the define list cannot
   reproduce the layout.  No rewrite: the translation keeps the cells
   (they shift by a byte or more, docs/questions.md 282).  Reproducer:

       module g37;
       var a: extern boolean; b: extern boolean; c: extern integer;
       define a, b, c;
       procedure p;
       begin
         a := b; c := 1;
       end;

   (A at +0, B at +2, C at +4 in dpc's output; the image's layout
   would put B at +1.)

