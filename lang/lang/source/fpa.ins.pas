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

{ EMIT_NEG - the FPA's negation of size size of operand b into a
  (cg_tree's generate).  fpa 0x0B849C: 8 a word, 10 and 14 the
  descriptors' addresses. }
procedure emit_neg(
    size: integer;
    in out a: codegen_$uads_t;
    in out b: codegen_$uads_t); options(val_param); extern;

{ EMIT_FMATH_TOP - the 68881's math function op (cg_tree's
  tree_fn_inst) of size size on operand b into a.  fpa 0x0B8652: 8 and
  10 words, 12 and 16 the descriptors' addresses. }
procedure emit_fmath_top(
    op: integer;
    size: integer;
    in out a: codegen_$uads_t;
    in out b: codegen_$uads_t); options(val_param); extern;

{ EMIT_EXTEND - a conversion of operand b of size from to a of size
  size (FPA1).  fpa 0x0B8864: 8 a word, 10 and 14 the descriptors'
  addresses, 18 a word. }
procedure emit_extend(
    size: integer;
    in out a: codegen_$uads_t;
    in out b: codegen_$uads_t;
    from: integer); options(val_param); extern;

{ EMIT_COMPARE - the FPA1 comparison of size size of operands a and b
  for condition cc (cg_tree's f_compare_proc).  fpa 0x0B8B7E: 8 a word,
  10 and 14 the descriptors' addresses, 18 a word. }
procedure emit_compare(
    size: integer;
    in out a: codegen_$uads_t;
    in out b: codegen_$uads_t;
    cc: integer); options(val_param); extern;

{ EMIT_JSR - a call of the FPA's routine op of size size (x: a
  comparison's condition).  fpa 0x0B8E0A: three words. }
procedure emit_jsr(
    op: integer;
    size: integer;
    x: integer); options(val_param); extern;

{ EMIT_CLR_FP1 - the FPA's register FP1 cleared for size size.  fpa
  0x0B996E: a word. }
procedure emit_clr_fp1(
    size: integer); options(val_param); extern;

{ FPA_FOP_PROC - the FPA operation of tree node n (cg_fp's fop_proc's
  operands).  fpa 0x0B9A0C: 8 a pointer, 12 and 14 words. }
procedure fpa_fop_proc(
    n: il_$node_ptr_t;
    op1: integer;
    op2: integer); options(val_param); extern;

{ FPA_TEMP - node n's FPA value kept in its temporary t (as cg_fp's
  fp_temp).  fpa 0x0B9BBC: two pointers. }
procedure fpa_temp(
    n: il_$node_ptr_t;
    t: il_$node_ptr_t); options(val_param); extern;
