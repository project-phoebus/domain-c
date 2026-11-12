{ moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas - the ISC generator's solution fields (a DSEE derived object; cc.a88k
  only): opened after isc_attribute_records.ins.pas by lir, lir_main,
  lir_utils, ra_utils, call_conv and the ISC units.

  A solution is the synthesized attribute record pass 1 builds for an
  IL node (432 bytes, isc_main's new_solution; lir_$build_operand makes
  an operand from one).  backend.ins.pas declares it as batch A's
  solution_t (the fields the LIR units read); the ISC units read it
  through isc_solution_t below, the whole record as the ISC sees it,
  cast from solution_ptr_t where a batch A heading takes one (batch A
  owns solution_t's names: docs/translator-brief.md).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k (translator PD).  The solution kinds are the SOLUTION$
  identifiers (tools/cc_enumnames.py: the table at cc.a88k 0x24526E,
  25 names, written by lir_$build_operand, and its copies in
  guarantee_has_live_range, local_initialize_symbol and dump_solution).
  The field names marked "(cse)" are the image's: isc_cse_handling's
  accessors are named pass_1_cse_parent_<field> and
  pass_2_cse_parent_<field> after the field they return.

  Not known from the original: the record's and the unnamed fields'
  names (by offset), the kind set's name. }

type
  { The kinds of solution (+108). }
  solution$t = (
    solution$none,                      { 0 }
    solution$case_jump_base,
    solution$fp_reg_pair_high,
    solution$fp_reg_pair_low,
    solution$local_routine,
    solution$address_mode,              { 5 }
    solution$ctl_reg,
    solution$flow,
    solution$fp_reg,
    solution$fp_reg_pair,
    solution$fp_reg_quad,               { 10 }
    solution$ip_reg,
    solution$ip_reg_field,
    solution$ip_reg_scaled,
    solution$literal_32_bits,
    solution$literal_64_bits,           { 15 }
    solution$processor_reg,
    solution$sc_reg,
    solution$sr_reg,
    solution$dummy,
    solution$any_solution,              { 20 }
    solution$irrelevant,
    solution$proper_subtree,
    solution$void,
    solution$k_max);

  { The solution kinds a node may be given (pass_1's last argument, a
    longword: kind k is bit k; isc_debug's print_permissible_solution_
    kinds prints one). }
  solution$set_t = set of solution$t;

  { A solution as the ISC reads it (432 bytes; see above).  The names
    batch A gave in solution_t are kept where they agree. }
  isc_solution_ptr_t = ^isc_solution_t;
  isc_solution_t = record
    obj_w_name: univ_ptr;               { +0 (cse): the object (node) }
    base_reg: lr_ptr_t;                 { +4 (cse): new_solution sets
                                          it and index_reg to
                                          isc_user_routines_31c }
    index_reg: lr_ptr_t;                { +8 (cse) }
    l12: integer32;                     { +12 }
    l16: integer32;                     { +16 }
    live_range: lr_ptr_t;               { +20 (cse; solution_t's lr) }
    lr2: lr_ptr_t;                      { +24 }
    l28: integer32;                     { +28 }
    bits_known: integer32;              { +32 (cse) }
    bits_trusted: integer32;            { +36 (cse) }
    l40: integer32;                     { +40 }
    l44: integer32;                     { +44 }
    disp: integer32;                    { +48 (cse: disp and lit_value) }
    l52: integer32;                     { +52 }
    w56: integer;                       { +56 }
    fp_reg_max: integer;                { +58 (cse) }
    fp_reg_result: integer;             { +60 (cse) }
    fp_reg_pair_max: integer;           { +62 (cse) }
    fp_reg_pair_result: integer;        { +64 (cse) }
    fp_reg_quad_max: integer;           { +66 (cse) }
    fp_reg_quad_result: integer;        { +68 (cse) }
    ip_reg_max: integer;                { +70 (cse) }
    ip_reg_result: integer;             { +72 (cse) }
    w74: integer;                       { +74 }
    f76: packed record                  { +76 }
      b76: 0..255;                      { +76 }
      b77: 0..255;                      { +77: 32 when made }
      reg: 0..255;                      { +78 }
      shift: 0..255;                    { +79 }
      b80: 0..255;                      { +80 }
      b81_7_2: 0..63;                   { +81 }
      embedded_sr_temp: boolean;        { .1 (cse) }
      b81_0: boolean;
      has_sym_disp: boolean;            { +82 .7 (cse) }
      b82_6, b82_5: boolean;
      b82_4: boolean;                   { .4: set when made }
      b82_3: boolean;
      b82_2: boolean;                   { .2: set when made }
      b82_1, b82_0: boolean;
      b83_7_4: 0..15;                   { +83 }
      physical: boolean;                { .3 }
      b83_2: boolean;
      no_modify: boolean;               { .1 }
      serialize: boolean;               { .0 }
      b84_7: boolean;                   { +84 }
      uses_disp: boolean;               { .6 (cse) }
      uses_index_reg: boolean;          { .5 (cse) }
      b84_4_0: 0..31;
      b85: 0..255;                      { +85 }
      b86: 0..255;                      { +86 }
      b87: 0..255;                      { +87 }
      end;
    chain: isc_solution_ptr_t;          { +88: the solution this one
                                          passes pass 2 on to (pass_2) }
    code_bytes: 0..65535;               { +92 (cse; unsigned:
                                          choose_one_cse_solution) }
    delay: 0..65535;                    { +94 (cse) }
    eval_order: integer;                { +96 (cse): 1 the children
                                          left to right, 2 right to left
                                          (pass_2); 1 when made }
    w98: integer;                       { +98: new_solution's last
                                          argument }
    sym: univ_ptr;                      { +100 }
    inherited: inherited_attributes_ptr_t;  { +104 }
    kind: integer;                      { +108: solution$t's ordinal }
    memory_refs: 0..65535;              { +110 (cse; compared `bcc') }
    rule: integer;                      { +112: the pattern's number
                                          (pass_2 calls the pass-2
                                          action of this number) }
    f114: packed record                 { +114 }
      nchildren: 0..255;                { +114: at most 5 }
      copied: boolean;                  { +115 .7: preserve_solution's
                                          copy }
      b6: boolean;                      { .6 }
      b5: boolean;                      { .5 }
      preserved: boolean;               { .4 }
      pass_2_done: boolean;             { .3 }
      b2, b1, b0: boolean;
      end;
    children: array [1..5] of isc_solution_ptr_t;  { +116 }
    space136: array [136..351] of char; { +136 }
    fields: array [0..19] of isc_solution_ptr_t;   { +352: the
                                          rule's own fields, laid out
                                          per rule (preserve_solution
                                          copies pointers at +352..+376
                                          and, for rules 114 and 115,
                                          +358: a variant record in the
                                          original; docs/isc-notes.md) }
  end;

  { A list of solutions (isc_main's solution_list$...: an 8-byte head
    and 8-byte cells from the ISC heap). }
  solution_cell_ptr_t = ^solution_cell_t;
  solution_cell_t = record
    sol: isc_solution_ptr_t;            { +0 }
    next: solution_cell_ptr_t;          { +4 }
  end;
  solution_list_ptr_t = ^solution_list_t;
  solution_list_t = record
    first: solution_cell_ptr_t;         { +0 }
    last: solution_cell_ptr_t;          { +4 }
  end;

  { A deferred LIR call (isc_to_lir: each debug_lir_ wrapper but
    begin_call_or_svc and begin_fortran_io_sequence appends one, 108
    bytes from the ISC heap, to the current statement's list;
    end_statement replays the list).  kind (+0) says which lir_ routine:
    1 branch, 2 break_basic_block, 3 common_lhs_rhs_token, 4
    disjoint_lhs_and_rhs_tokens, 5 dispatch, 6 emit_call_or_svc, 7
    end_call_or_svc, 8 field, 9 label, 10 load, 11 mfpr, 12 mtpr, 13
    operate_and_branch, 14 a four-operand simple instruction
    (pa_risc_shift_double), 15 simple, 16 store, 17 lir_main_$entry, 18
    lir_main_$handler_reentry.  The fields are named after the
    wrappers' parameters; a statement's head record (begin_statement)
    uses only next.  Here rather than in isc_types.ins.pas because
    isc_var_externs.ins.pas (opened by lir_main and lir_utils too, which
    do not open isc_types.ins.pas) declares the tables of them. }
  lir_request_ptr_t = ^lir_request_t;
  lir_request_t = record
    kind: integer;                      { +0 }
    opc: integer;                       { +2 }
    prev: lir_request_ptr_t;            { +4 }
    next: lir_request_ptr_t;            { +8 }
    target: univ_ptr;                   { +12: a label }
    bits_known: integer32;              { +16 }
    bits_trusted: integer32;            { +20 }
    disp_off_tree: integer32;           { +24 }
    siz: integer32;                     { +28 }
    node: univ_ptr;                     { +32: the entry statement }
    inh: inherited_attributes_ptr_t;    { +36 }
    call: univ_ptr;                     { +40 }
    lhs: univ_ptr;                      { +44 }
    linkage_reg: solution_ptr_t;        { +48 }
    l52: integer32;                     { +52 }
    op1: isc_solution_ptr_t;            { +56 }
    op2: isc_solution_ptr_t;            { +60 }
    op3: isc_solution_ptr_t;            { +64 }
    op4: isc_solution_ptr_t;            { +68 }
    index: isc_solution_ptr_t;          { +72: index/disp }
    base: isc_solution_ptr_t;           { +76 }
    requests: integer32;                { +80 }
    result: isc_solution_ptr_t;         { +84 }
    rhs: univ_ptr;                      { +88 }
    l92: integer32;                     { +92 }
    source: isc_solution_ptr_t;         { +96 }
    tree: univ_ptr;                     { +100: the IL tree (emit: the
                                          call node) }
    var_name: univ_ptr;                 { +104 }
  end;
  lir_request_tab_t = array [1..16] of lir_request_ptr_t;

