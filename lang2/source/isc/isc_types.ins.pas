{ lang2/source/isc/isc_types.ins.pas - the ISC's types (cc.a88k only): opened by the ISC units
  (isc_call_handling, isc_cse_handling, isc_to_lir, isc_user_routines,
  rewrite and the generated units) after isc_consts.ins.pas and before
  isc_routine_externs.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k (translator PD).

  Not known from the original: every name here but arith$t's elements
  (arithmetic_from_il_node writes them: the identifier table at cc.a88k
  0x21520E).  The IL node views are the reconstruction's: the ISC reads
  the front end's nodes by offset, as the other back-end units do
  (il.ins.pas's il_$node_t has no variant for these kinds). }

type
  { How a node's value is computed (arithmetic_from_il_node; the
    inherited attributes' +38). }
  arith$t = (
    arith_none, arith_integer, arith_real, arith_address,
    arith_meaningless, arith$t_max);

  { The IL nodes as the ISC reads them (kind at +2; the kinds are
    add_node.pas's an_kind_t ordinals, written as numbers). }
  isc_node_ptr_t = ^isc_node_t;
  isc_node_t = record
    flags: char;                        { +0 }
    b1: char;                           { +1 }
    kind: integer;                      { +2 }
    case integer of
      { A tree node (137 TREE_NODE, 138 GEN_TREE_NODE: the ISC sets a
        CSE's tree to 138 once it has its solution): top (+12) its
        statement, size, rlen and opmods (+20..+28) the descriptor, op
        (+36) the operator, count (+38) the operands. }
      1: (tr_l4: integer32;             { +4 }
          tr_l8: integer32;             { +8 }
          tr_top: isc_node_ptr_t;       { +12 }
          tr_l16: integer32;            { +16 }
          tr_size: integer32;           { +20 }
          tr_rlen: integer;             { +24 }
          tr_opmod1: integer;           { +26 }
          tr_opmod2: integer;           { +28 }
          tr_w30: integer;              { +30 }
          tr_l32: integer32;            { +32 }
          tr_op: integer;               { +36 }
          tr_count: integer;            { +38 }
          tr_opnd: array [1..64] of isc_node_ptr_t);    { +40 }
      { A call tree (op 30 ISC_CALL, 31 ISC_FUNC_CALL, 32
        ISC_FUNC_CALL_HIDDEN_TEMP; rewrite_$routine_call makes them):
        its operands (+40 the routine, +44 the inputs and +48 the
        outputs, chained at +8, +56 the hidden temporary) and what
        isc_call_handling's pass 1 records for pass 2: +60 the
        routine's solution, +64 and +68 the inputs' and outputs'
        solution lists, +72 the temporary's, +76 the call (debug_lir_$
        begin_call_or_svc's record).  opmod1 (+26) indexes lir_3e60. }
      2: (cl_x4: array [1..8] of integer32;         { +4 }
          cl_l36: integer32;            { +36: op, count }
          cl_routine: isc_node_ptr_t;   { +40 }
          cl_inputs: isc_node_ptr_t;    { +44 }
          cl_outputs: isc_node_ptr_t;   { +48 }
          cl_l52: integer32;            { +52 }
          cl_temp: isc_node_ptr_t;      { +56 }
          cl_solution: isc_solution_ptr_t;              { +60 }
          cl_input_solutions: solution_list_ptr_t;      { +64 }
          cl_output_solutions: solution_list_ptr_t;     { +68 }
          cl_temp_solution: isc_solution_ptr_t;         { +72 }
          cl_call: univ_ptr);           { +76 }
      { An argument of a call (the inputs' and outputs' chains): next
        (+8) the next one, loc (+64) where it is passed: a 203
        PHYSICAL_REGISTER_OB or 204 ARGUMENT_BLOCK_LOCATION_OB node,
        whose +4 (lo_class) counts its registers (2 a pair, 3 a quad). }
      3: (ar_l4: integer32;             { +4 }
          ar_next: isc_node_ptr_t;      { +8 }
          ar_x12: array [3..15] of integer32;           { +12 }
          ar_loc: isc_node_ptr_t);      { +64 }
      4: (lo_class: integer);           { +4 }
      { A statement (a top-level node): line (+20), +42 a longword whose
        middle bytes (+43..+44) are its index (isc_pos_t). }
      5: (st_x4: array [1..2] of integer32;         { +4 }
          st_top: univ_ptr;             { +12 }
          st_l16: integer32;            { +16 }
          st_line: integer;             { +20 }
          st_x22: array [22..41] of char;           { +22 }
          st_l42: integer32);           { +42 }
      { A CSE's parent (190 CSE_PARENT_OB): tree (+4) the expression,
        chosen_solution (+24, the bug checks' name) its solution. }
      6: (cp_tree: isc_node_ptr_t;      { +4 }
          cp_x8: array [2..5] of integer32;         { +8 }
          cp_chosen_solution: isc_solution_ptr_t);  { +24 }
      { A use of a CSE (189 CSE_USE_OB): parent (+16) its 190 node, tree
        (+20) the tree it is used in. }
      7: (cu_x4: array [1..3] of integer32;         { +4 }
          cu_parent: isc_node_ptr_t;    { +16 }
          cu_tree: isc_node_ptr_t);     { +20 }
      { A routine (107 PROCEDURE_BLK, 108 FUNCTION_BLK): slevel (+294, a
        byte) its nesting level, atts (+376) attributes (bit 6: il_180's
        tested by the calls). }
      8: (bk_x4: array [4..293] of char;            { +4 }
          bk_f294: packed record        { +294 }
            slevel: -128..127;
            b295: 0..255;
            end;
          bk_x296: array [296..375] of char;        { +296 }
          bk_atts: packed record        { +376 }
            b7: boolean;
            b6: boolean;                { .6 }
            b5_0: 0..63;
            end);
  end;
