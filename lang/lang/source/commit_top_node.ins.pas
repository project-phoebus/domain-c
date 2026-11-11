{ lang/lang/source/commit_top_node.ins.pas - the interface of
  lang/lang/source/commit_top_node.pas (COMMIT_TOP_: assignment
  operators turned into stores to memory).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Opened after an insert that declares il_$node_ptr_t (the prelude).

  Not known from the original: the parameter names.
}

{ COMMIT_TOP_$CONVERT_AOPS_TO__AOP_TO_MEM - cc.m68k 0x075FB8 (cc.a88k
  0x077998): a node by value (runbackend's normalize_il, opt_main's
  general_opts). }
procedure commit_top_$convert_aops_to__aop_to_mem(
    t: il_$node_ptr_t); options(val_param); extern;
