{ lang/c_compiler/source/c_objtype.ins.pas - the C front end's object
  types: what the front end's units (and add_node, attributes,
  error_listing, inc_list and runbackend, which open it after the
  prelude) share beyond the prelude's IL node.

  Every front-end unit opens it first after the prelude, then
  c_globals.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: every name here.
}

{ TODO(pascal) c_objtype.ins.pas is incomplete

  The front end's type nodes (kinds 109, 118..136, 210, c_type_t)
  and the symbol table records are added as c_def_sem, c_expr_sem and
  c_syntax are translated. }

type
  { A type node as the front end reads it: the IL node header (a word,
    the kind at +2), then by kind.  The fields below are those the
    translated units read; type_exp (c_def_sem.pas 0x04590A) shows more
    (kind 118 a name whose type is at +28; 128 an enumeration, +4 its
    base, +8 and +12 its bounds' constant nodes; 129 with the integral
    node at +20; 109, 119, 120, 121 with a bit size and an attribute
    longword; 127 and 131 arrays, +40 the size; 132 and 134 sizes at
    +8, +12). }
  c_type_ptr_t = ^c_type_t;
  c_type_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      { Integral (122) and floating (123) types. }
      1: (len: integer;                 { +4: integral: 1, 2 or 4
                                          bytes; floating: 6 the
                                          single (type_exp: size 4),
                                          else the double }
          sign_flags: packed record     { +6 }
            signed: boolean;            { .7: type_exp's range test }
            b6_6: boolean;
            b6_5: boolean;
            b6_4: boolean;
            b6_3: boolean;
            b6_2: boolean;
            b6_1: boolean;
            b6_0: boolean;
          end);
  end;

  { What type_exp (c_def_sem.pas 0x04590A) makes of a type node: the
    callers pass the address of a 28-byte frame temporary (def_blk_params
    0x048B70 `pea (-72,A6)'; c_expr_sem's basic types are 64-byte
    entries at +0x36C of its data, each beginning with one).  type_exp
    stores +0 and +4, copies 12 bytes of defaults to +8..+19 (0x045926),
    sets +24.1 and clears +25.6 before dispatching on the node's kind.

    get_rlen (c_get_rlen.pas) reads base^.kind, base's word at +4 (kind
    123) and size. }
  type_exp_ptr_t = ^type_exp_t;
  type_exp_t = record
    base: c_type_ptr_t;                 { +0: the type with names
                                          expanded (type_exp recurses
                                          through kind 118 and stores
                                          the inner node here) }
    node: c_type_ptr_t;                 { +4: the type node passed }
    low: integer32;                     { +8: the least value (integral
                                          kinds 122 and 129: -32768
                                          for a 2-byte signed type) }
    high: integer32;                    { +12: the greatest (32767,
                                          255, 65535, 16#7FFFFFFF) }
    size: integer32;                    { +16: bytes (1, 2, 4; 8 for a
                                          kind 123 of length other than
                                          6; 128 for kind 136; 0 for
                                          kind 210) }
    bytes: integer32;                   { +20: the storage size in
                                          bytes (from a bit size, +7
                                          div 8), else size }
    flags: packed record
      align: -16..15;                   { +24.7..3: an alignment
                                          (attr_set_align_dsc may raise
                                          it; type_exp lowers it back) }
      b24_2: boolean;                   { .2 }
      b24_1: boolean;                   { .1: set by type_exp, cleared
                                          when align is lowered }
      b24_0: boolean;                   { .0 }
      b25_7: boolean;                   { +25.7 }
      ranged: boolean;                  { .6: low and high are known
                                          (integral kinds) }
      b25_5: boolean;                   { .5: from the node's attribute
                                          bit 19 }
      b25_4: boolean;                   { .4: from the node's attribute
                                          bit 0 of its last byte }
      b25_3: boolean;
      b25_2: boolean;
      b25_1: boolean;
      b25_0: boolean;
    end;
  end;
