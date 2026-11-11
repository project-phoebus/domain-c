{ lang/lang/source/gen_unwind.ins.pas - the interface of
  lang/lang/source/gen_unwind.pas (the unwind and exception tables).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  A stub: only what lang/lang/source/unix_objmod.pas calls is declared,
  read off gen_unwind's frames (tools/cc_params.py) and unix_objmod's
  call sites.

  Not known from the original: the parameter names; the meaning of the
  parameters gen_unwind does not read.
}

{ TODO(pascal) gen_unwind.ins.pas is a stub

  Add the rest of the interface when gen_unwind.pas is translated. }

{ GEN_UNWIND_$BEGIN_COMPILATION - cc.m68k 0x07A884: the unwind section's
  record (unix_objmod's, 6156 bytes) and the target (0..3, a word), by
  value. }
procedure gen_unwind_$begin_compilation(
    sect: univ_ptr;
    target: integer); options(val_param); extern;

{ GEN_UNWIND_$DUMP_UNWIND_TABLE - the unwind table written at offset
  pos; its size in D0.  0x07C0AE: reads only pos (8) and the unwind
  form (28, a word); unix_objmod passes 2, the exception section's
  symbol, unix_objmod +0x5D2C and the exception table's address (or
  three -1) between. }
function gen_unwind_$dump_unwind_table(
    pos: integer32;
    p2: integer32;
    p3: integer32;
    p4: integer32;
    p5: integer32;
    form: integer): integer32; options(val_param); extern;

{ GEN_UNWIND_$DUMP_EXCEPTION_TABLE - the exception table written at
  offset pos; its size in D0.  0x07C2D2: reads only pos; unix_objmod
  passes 2 as well. }
function gen_unwind_$dump_exception_table(
    pos: integer32;
    p2: integer32): integer32; options(val_param); extern;

{ GEN_UNWIND_$END_COMPILATION - 0x07C392: two longwords by value (the
  exception tuple's and handler's addresses). }
procedure gen_unwind_$end_compilation(
    a: integer32;
    b: integer32); options(val_param); extern;

type
  { A scope of a routine's code (outbin.pas's begin_unwind_scope and
    end_unwind_scope fill one, at its A5 + 0xD60; gen_unwind_$add_scope
    copies 46 bytes of it): the start and length of the code, the
    registers saved (a set each of the address, data and floating
    registers; outbin's from the block's +220). }
  gen_unwind_$scope_t = record
    start: integer32;                   { +0 }
    len: integer32;                     { +4 }
    x8: integer32;                      { +8: the block's +224 }
    x12: integer32;                     { +12 }
    aregs: set of 0..15;                { +16 }
    dregs: set of 0..15;                { +18 }
    fregs: set of 0..15;                { +20 }
    b22: boolean;                       { +22 }
    b23: boolean;                       { +23 }
    b24: boolean;                       { +24 }
    rest: array [1..21] of char;        { +25: to 46 bytes }
  end;

{ GEN_UNWIND_$ADD_SCOPE - a scope added to the unwind table.  0x07A920:
  the scope by address, two longwords by value (outbin's end_unwind_scope
  passes 0 and the block's section's +64). }
procedure gen_unwind_$add_scope(
    in scope: gen_unwind_$scope_t;
    p2: integer32;
    p3: integer32); options(val_param); extern;
