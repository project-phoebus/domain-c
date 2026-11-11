{ lang/lang/source/il.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/il.pas (initialize_module) and the IL node types.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ The compiler's nodes.  Every node begins with a word not yet
  identified and the node's kind at +2 (il.pas initialize_module 0x07D882
  sets +2 of each node it creates; idntk sets it in each identifier
  entry it creates).  The variants are added as the units that build and
  read them are translated.

  Not known from the original: every name here. }

{ TODO(pascal) il.ins.pas holds only the node header and the identifier

  The node kinds, the other variants and IL's globals (il.pas's data,
  +0xC4..+0x184, docs/globals-cc.m68k.md) are still to be declared. }

type
  il_$node_ptr_t = ^il_$node_t;
  il_$node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      { An identifier, entered by idntk (strings.pas). }
      1: (idnt_next: il_$node_ptr_t;    { +4: the hash chain }
          idnt_unused_8: integer32;     { +8: cleared by idntk }
          idnt_unused_12: integer32;    { +12: cleared by idntk }
          idnt_len: integer;            { +16 }
          idnt_name: array [1..1024] of char);  { +18 }
  end;
