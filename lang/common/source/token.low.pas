{ lang/common/source/token.low.pas - TOKEN_'s low-level view: the IL
  node behind a token.

  Private to token.pas, which opens it before the lang/lang inserts
  that name the IL node (token.ins.pas, strings.ins.pas,
  list_tree.ins.pas) but does not open lang/lang/source/il.ins.pas (its
  .blocks file list): so the node pointer and the fields token.pas reads
  are declared here, under il.ins.pas's names and at its offsets.  A
  unit never opens both.

  No Apollo copy survives.  Not known from the original: everything
  about its contents but the offsets token.pas uses.
}

{ TODO(pascal) keep in step with il.ins.pas

  The identifier and string variant is il.ins.pas's variant 1 (strtk
  builds kind 92 nodes as idntk builds identifiers: +16 the length, +18
  the characters).  The other two are seen only here so far.  token.pas
  zero-extends the length (`clr.l; move.w (16,An)'), so it is a 0..65535
  value here; il.ins.pas has integer (strtk compares it signed).  So is
  the kind (token_$identifier passes it on as a longword). }

type
  il_$node_ptr_t = ^il_$node_t;
  il_$node_t = record
    unused_0: integer;                  { +0 }
    kind: 0..65535;                     { +2: zero-extended (0x073850) }
    case integer of
      { An identifier (idntk) or a string constant (kind 92, strtk). }
      1: (idnt_next: il_$node_ptr_t;    { +4 }
          idnt_unused_8: integer32;     { +8 }
          idnt_unused_12: integer32;    { +12 }
          idnt_len: 0..65535;           { +16: zero-extended }
          idnt_name: array [1..4096] of char);  { +18 }
      { Kind 163: a constant made from another node; when its class at
        +20 is 11 and that node a string, the string's bytes. }
      2: (ref_unused_4: integer32;      { +4 }
          ref_node: il_$node_ptr_t;     { +8 }
          ref_unused_12: integer32;     { +12 }
          ref_unused_16: integer32;     { +16 }
          ref_class: char);             { +20: a byte, compared with 11 }
      { Kind 176: a constant of a given size in bytes. }
      3: (sized_unused_4: integer32;    { +4 }
          sized_bytes: integer32);      { +8 }
  end;
