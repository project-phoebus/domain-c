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

  { A live range as the ISC marks it (lr_t is batch A's,
    backend.ins.pas): +10 bit 7 isc_is_cse, set by isc_user_routines'
    set_isc_is_cse_on_live_range_if_local_cse and by the CSEs' pass 2
    (lr_t's l8 covers the byte). }
  isc_lr_ptr_t = ^isc_lr_t;
  isc_lr_t = record
    space0: array [0..9] of char;       { +0 }
    f10: packed record                  { +10 }
      isc_is_cse: boolean;              { .7 }
      b6_0: 0..127;
      end;
  end;

  { The IL nodes as the ISC reads them (kind at +2; the kinds are
    add_node.pas's an_kind_t ordinals, written as numbers). }
  isc_node_ptr_t = ^isc_node_t;
  isc_sr_info_ptr_t = ^isc_sr_info_t;  { below }
  isc_node_t = record
    rewritten: boolean;                 { +0: list_tree's flag (rewrite)
                                          sets it) }
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
      { A variable (109 VAR_NAME; translator PD2, isc_user_routines):
        p4 (+4) its initializer (local_initialize_var_name tests for a
        163 ADDR_CON there) or, for the ISC's well-known registers'
        variables, the identifier naming them, typ (+28) its type, attr (+32) its attributes (bit
        25 initialized for the ISC, 26 given a home solution, 17 has
        strength-reduction information, 10 a declared register: reg
        (+56) the register (class in the high word: 0 integer, 1
        floating, 2 floating pair) or the address bits; the ISC also
        reads bits 6, 11, 14, 28 and the masks 16#10400041 and
        16#12400041), bits (+36) its size in bits, align (+44)
        alignment_from_il_node's cache, sr (+52) the strength-reduction
        information, home (+60) its home solution, vat (+72) its
        allocation (5 a register; 2, 11 by address). }
      9: (vn_p4: isc_node_ptr_t;        { +4 }
          vn_x8: array [2..4] of integer32;         { +8 }
          vn_block: univ_ptr;           { +20: its routine's block
                                          (make_expression_temporary:
                                          il_180) }
          vn_l24: integer32;            { +24 }
          vn_type: isc_node_ptr_t;      { +28 }
          vn_attr: integer32;           { +32 }
          vn_bits: integer32;           { +36 }
          vn_l40: integer32;            { +40 }
          vn_align: integer;            { +44 }
          vn_w46: integer;              { +46 }
          vn_l48: integer32;            { +48 }
          vn_sr: isc_sr_info_ptr_t;     { +52 }
          vn_reg: integer32;            { +56 }
          vn_home: isc_solution_ptr_t;  { +60 }
          vn_x64: array [16..17] of integer32;      { +64 }
          vn_vat: integer;              { +72 }
          vn_serial: integer);          { +74: a temporary's number
                                          (make_expression_temporary) }
      { A FORTRAN symbol (110 FORTRAN_SYMBOL, a common member or a
        FORTRAN variable; translator PD2): f10 its class (low nibble
        of +10; bit 7 its size is not computed) and storage (high
        nibble of +11: 5 a register, 11 by address), disp (+12), attr
        (+24, as a variable's +32), home (+36), f44 its kind (high
        nibble: 1 and 3 dummy and common kinds whose size sz_fsym
        computes), sr (+46). }
      10: (fs_x4: integer32;            { +4 }
           fs_w8: integer;              { +8 }
           fs_f10: packed record        { +10 }
             b7: boolean;               { .7 }
             b6_4: 0..7;
             cls: 0..15;                { .3..0 }
             sto: 0..15;                { +11 .7..4 }
             b11_3_0: 0..15;
             end;
           fs_disp: integer32;          { +12 }
           fs_x16: array [4..5] of integer32;       { +16 }
           fs_attr: integer32;          { +24 }
           fs_l28: integer32;           { +28 }
           fs_l32: integer32;           { +32 }
           fs_home: isc_solution_ptr_t; { +36 }
           fs_l40: integer32;           { +40 }
           fs_f44: packed record        { +44 }
             kind: 0..15;               { .7..4 }
             b3_0: 0..15;
             b45: 0..255;
             end;
           fs_sr: isc_sr_info_ptr_t);   { +46 }
      { An assignment (139 ASSIGN_NODE; translator PD2): rhs (+68) its
        value, op (+76) the assignment operator (an aop, as
        isc_user_routines' printers name them). }
      11: (as_x4: array [1..16] of integer32;       { +4 }
           as_rhs: isc_node_ptr_t;      { +68 }
           as_l72: integer32;           { +72 }
           as_op: integer);             { +76 }
      { A type node (translator PD2): +35 bit 7 of a kind 132 (a
        structure that local_initialize_symbol keeps in memory). }
      12: (ty_x4: array [4..34] of char;            { +4 }
           ty_f35: packed record        { +35 }
             b7: boolean;
             b6_0: 0..127;
             end);
      { Any node by offset, as il.ins.pas's il_$node_t has it (xp[k]
        the pointer and xl[k] the longword at +4k, xw[k] the word at
        +2k), for the kinds read once or twice (translator PD2). }
      13: (xp: array [1..94] of isc_node_ptr_t);    { +4 }
      14: (xl: array [1..94] of integer32);         { +4 }
      15: (xw: array [2..189] of integer);          { +4 }
  end;

  { A variable's strength-reduction information (a VAR_NAME's +52, a
    FORTRAN_SYMBOL's +46; isc_user_routines' alignment_from_sr_info,
    translator PD2): reduced (+0) the reduced expression (a tree of op
    1 add, 3 mul or 27 lshift whose second operand is a literal),
    inclist (+8) the increments (assignments by add_to or sub_from),
    initial (+12) the initial assignment. }
  isc_sr_cell_ptr_t = ^isc_sr_cell_t;
  isc_sr_cell_t = record
    node: isc_node_ptr_t;               { +0 }
    next: isc_sr_cell_ptr_t;            { +4 }
  end;
  isc_sr_info_t = record
    reduced: isc_node_ptr_t;            { +0 }
    l4: integer32;                      { +4 }
    inclist: isc_sr_cell_ptr_t;         { +8 }
    initial: isc_node_ptr_t;            { +12 }
  end;

  { The section isc_readonly_tables (cc.a88k 0x2BCDFC, 3120 bytes; the
    tables the ISC keeps by hand, overlaid in the units that declare
    it): the views isc_user_routines reads (translator PD2).  masks[k]
    (+0xAA8) has the k low bits set (0..32); rlen_bits (+0x174) and
    rlen_w (+0x140) are indexed by register class codes
    (isc_$precision_from_rlen_and_size, rlen_code_from_type_node).  Not
    known from the original: the names, and how the original declared
    the section (here an extern view; the bytes stay the image's). }
  isc_readonly_tables_t = record
    x0: array [0..159] of char;         { +0x000 }
    rlen_w: array [0..25] of integer;   { +0x0A0 = 160 }
    x0d4: array [0..159] of char;       { +0x0D4 }
    rlen_bits: array [0..19] of integer32;  { +0x174 }
    x1c4: array [0..2275] of char;      { +0x1C4 }
    masks: array [0..32] of integer32;  { +0xAA8 }
    xb2c: array [0..255] of char;       { +0xB2C }
  end;

  { A longword of attribute bits (isc_user_routines' printers of a
    type's and a variable's attributes; translator PD2). }
  isc_attr_set_t = set of 0..31;

var
  isc_readonly_tables: extern isc_readonly_tables_t;
