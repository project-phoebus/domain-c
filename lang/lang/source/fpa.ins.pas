{ lang/lang/source/fpa.ins.pas - the insert of the m68k back end's FPA
  code (lang/lang/source/fpa.pas, cc.m68k only), opened by cg_addr,
  cg_call, cg_top, cg_tree, emit.

  No Apollo copy survives.  A stub: only what cg_top and cg_assign need
  is declared.

  Not known from the original: everything about its contents.
}

{ TODO(pascal) fpa.ins.pas is a stub

  Declarations are added as fpa.pas and its callers are translated. }

{ EMIT_LOAD_STORE - an FPA load or store op of size size between
  operands a and b.  fpa 0x0B7C8E: 8 a word, 10 and 14 the descriptors'
  addresses, 18 a word (cg_top's return_proc passes 497 for the FPA
  register's value to D0). }
procedure emit_load_store(
    op: integer;
    in out a: codegen_$uads_t;
    in out b: codegen_$uads_t;
    size: integer); options(val_param); extern;

{ EMIT_MUL_ADD, EMIT_DIV_SUB - an FPA1 operation op of size size on
  operands a and b (cg_assign's floating assignment operators).  fpa
  0x0B8246, 0x0B831C: 8 and 10 words, 12 and 16 the descriptors'
  addresses. }
procedure emit_mul_add(
    op: integer;
    size: integer;
    in out a: codegen_$uads_t;
    in out b: codegen_$uads_t); options(val_param); extern;

procedure emit_div_sub(
    op: integer;
    size: integer;
    in out a: codegen_$uads_t;
    in out b: codegen_$uads_t); options(val_param); extern;

{ PUSH_FPA_OPR - node n's value of size size given to the FPA as
  operand k (x: cg_assign passes 16).  fpa 0x0B9472: 8 a pointer, 12,
  14, 16 words. }
procedure push_fpa_opr(
    n: il_$node_ptr_t;
    k: integer;
    size: integer;
    x: integer); options(val_param); extern;
