{ lang/lang/source/list_tree.ins.pas - LIST_TREE, the IL tree dumps
  (lang/lang/source/list_tree.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.  Opened after
  an insert that declares il_$node_ptr_t (il.ins.pas, or token.low.pas
  in lang/common/source/token.pas).

  Not known from the original: the parameter names.
}

{ LIST_TREE_$PRINT_TREE - the tree under t to the listing.  cc.m68k
  0x085CDA: t at (8,A6) (`cmpa.w #0'), the longword at (12,A6) passed
  to initialise_list_tree; token.pas passes 0. }
procedure list_tree_$print_tree(
    t: il_$node_ptr_t;
    p2: integer32); options(val_param); extern;

{ LIST_TREE_$PRINT_WHOLE_IL - the whole IL to the listing (-TREE).
  cc.m68k 0x085ABA (cc.a88k 0x08749A): no parameters (runbackend,
  commit_top_node, ...). }
procedure list_tree_$print_whole_il; extern;

{ TODO(pascal) list_tree.ins.pas is incomplete

  The rest of LIST_TREE's interface is added when list_tree.pas is
  translated. }
