{ lang/lang/source/list_tree.ins.pas - LIST_TREE, the IL tree dumps
  (lang/lang/source/list_tree.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  The routines other units call.  list_tree_$print_rlen,
  list_tree_$print_aux and list_tree_$sanity_check, which no unit
  calls, are declared in list_tree.pas.  Opened after an insert that
  declares il_$node_ptr_t (il.ins.pas, or token.low.pas in
  lang/common/source/token.pas).

  Not known from the original: the parameter and type names.
}

{ LIST_TREE_$PRINT_TREE - the tree under t, its lines through the
  routine emit (a pointer to a routine taking the line by address, as
  listln; nil: diag_$writeln).  cc.m68k 0x085CDA: t at (8,A6) (`cmpa.w
  #0'), emit at (12,A6) passed to initialise_list_tree; token.pas passes
  nil.  emit is univ_ptr: the routine's line type (iosub's) is not
  declared where this insert is opened. }
procedure list_tree_$print_tree(
    t: il_$node_ptr_t;
    emit: univ_ptr); options(val_param); extern;

{ LIST_TREE_$PRINT_WHOLE_IL - the whole IL to the listing (-TREE).
  cc.m68k 0x085ABA (cc.a88k 0x08749A): no parameters (runbackend,
  commit_top_node, ...). }
procedure list_tree_$print_whole_il; extern;
