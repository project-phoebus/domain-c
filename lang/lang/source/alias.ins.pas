{ lang/lang/source/alias.ins.pas - the interface of
  lang/lang/source/alias.pas: alias descriptors (what storage an IL
  reference may touch) and the relations between them, for the
  optimizer (opt_*, cse, assign_opt, use_def_proc, process_parameters,
  ...).  Opened after the prelude.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (the unit is the same in both).  The headings are read off the
  routines' frames and their callers (tools/cc_params.py); the internal
  routines and build_alias_desc are declared in alias.pas.

  Not known from the original: the type, field and parameter names.
}

const
  { A descriptor's class (alias.pas's table of names, in this order). }
  alias_never_invalidated = 0;
  alias_common_block = 1;
  alias_external = 2;
  alias_static = 3;
  alias_unaliased_static = 4;
  alias_xstatic = 5;
  alias_unaliased_xstatic = 6;
  alias_dynamic = 7;
  alias_unaliased_dynamic = 8;
  alias_xdynamic = 9;
  alias_unaliased_xdynamic = 10;
  alias_dynamic_param_ptr = 11;
  alias_ref_thru_param_ptr = 12;
  alias_random_pointer = 13;
  alias_xdb_relative = 14;
  alias_xsf_relative = 15;
  alias_argument_block = 16;

type
  { An alias descriptor: 20 bytes (the callers' frame temporaries;
    alias.pas copies them as five longwords).  The class and flags
    share a word (build_alias_desc clears five flags with one `andi.w
    #0xFF43' on +18, the class and a flag with `andi.w #0x00F7').

    Not known from the original: every name; the meaning of +19 bits
    3 and 4. }
  alias_$desc_ptr_t = ^alias_$desc_t;
  alias_$desc_t = packed record
    base: il_$node_ptr_t;               { +0: the variable, block,
                                          section or pointer node }
    sym: il_$node_ptr_t;                { +4: a common block's member,
                                          or the variable a pointer was
                                          taken from }
    disp: integer32;                    { +8: from base }
    size: integer32;                    { +12 }
    levels: integer;                    { +16: indirections (negative:
                                          an address) }
    class: 0..255;                      { +18: alias_ constants }
    inexact: boolean;                   { +19.7: the displacement or
                                          extent is not known }
    valid: boolean;                     { +19.6: build_alias_desc
                                          succeeded }
    uplevel: boolean;                   { +19.5: of another routine's
                                          frame (or a display) }
    phase_34: boolean;                  { +19.4: getphase gave 3 or 4 }
    f19_3: boolean;                     { +19.3: flag 13 of the
                                          variable }
    whole: boolean;                     { +19.2: the same as the whole
                                          variable's descriptor }
    f19_1: boolean;                     { +19.1 }
    f19_0: boolean;                     { +19.0 }
  end;

{ ALIAS_$GET_ALIAS_DESC - d for a reference to n of size bytes; false
  when no descriptor can be made.  0x0745A4 (cc.a88k 0x075F84): n and
  size by value, d by address, the result in D0 (a byte). }
function alias_$get_alias_desc(
    n: il_$node_ptr_t;
    size: integer32;
    var d: alias_$desc_t): boolean; options(val_param); extern;

{ ALIAS_$ALIAS_DESC_WITH_SIZE - alias_$get_alias_desc, the result
  dropped.  0x074688 (cc.a88k 0x076068) (17 callers: assign_opt, ...). }
procedure alias_$alias_desc_with_size(
    n: il_$node_ptr_t;
    size: integer32;
    var d: alias_$desc_t); options(val_param); extern;

{ ALIAS_$BASIC_ALIAS_DESC - the descriptor of n of size 123456780.
  0x0746B4 (cc.a88k 0x076094) (36 callers). }
procedure alias_$basic_alias_desc(
    n: il_$node_ptr_t;
    var d: alias_$desc_t); options(val_param); extern;

{ ALIAS_$ADD_DISP - add n to a valid descriptor's displacement.
  0x0746E2 (cc.a88k 0x0760C2); no caller in either binary. }
function alias_$add_disp(
    var d: alias_$desc_t;
    n: integer32): boolean; options(val_param); extern;

{ ALIAS_$IND_FOR_CAPTURED_LVALUE - the storage n's address points into,
  or nil.  0x074710 (cc.a88k 0x0760F0): the result in A0 (7 callers:
  actual_actual, process_parameters, ...). }
function alias_$ind_for_captured_lvalue(
    n: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ ALIAS_$RELATIONSHIP - 0 unrelated, 1 the same storage, 2 may
  overlap.  0x074964 (cc.a88k 0x076344): both by address, a word in
  D0. }
function alias_$relationship(
    var a: alias_$desc_t;
    var b: alias_$desc_t): integer; extern;

{ ALIAS_$RELATED - the relationship is not 0.  0x074CE6 (cc.a88k
  0x0766C6) (33 callers). }
function alias_$related(
    var a: alias_$desc_t;
    var b: alias_$desc_t): boolean; extern;

{ ALIAS_$UNRELATED_OR_EXACT - the relationship is not 2.  0x074D1A
  (cc.a88k 0x0766FA); no caller in either binary. }
function alias_$unrelated_or_exact(
    var a: alias_$desc_t;
    var b: alias_$desc_t): boolean; extern;

{ ALIAS_$CLASSES_MAY_BE_RELATED - as alias_$relationship, for two
  classes.  0x074D50 (cc.a88k 0x076730): two words by value; no caller
  in either binary. }
function alias_$classes_may_be_related(
    c1: integer;
    c2: integer): integer; options(val_param); extern;

{ ALIAS_$REF_MAY_GENERATE_EXCEPTION - a reference through d may fault.
  0x074E34 (cc.a88k 0x076814); no caller in either binary. }
function alias_$ref_may_generate_exception(
    var d: alias_$desc_t): boolean; extern;

{ ALIAS_$DESCRIPTORS_ARE_IDENTICAL - every field but phase_34 equal.
  0x074E7A (cc.a88k 0x07685A). }
function alias_$descriptors_are_identical(
    var a: alias_$desc_t;
    var b: alias_$desc_t): boolean; extern;

{ ALIAS_$RELATED_CALL - the call n may touch d's storage.  0x074F46
  (cc.a88k 0x076926): d by address, n by value (5 callers: cse,
  use_def_proc, ...). }
function alias_$related_call(
    var d: alias_$desc_t;
    n: il_$node_ptr_t): boolean; options(val_param); extern;
