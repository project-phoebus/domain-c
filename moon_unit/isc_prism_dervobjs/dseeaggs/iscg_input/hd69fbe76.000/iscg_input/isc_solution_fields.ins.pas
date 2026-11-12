{ moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas - the ISC generator's solution fields (a DSEE derived object; cc.a88k
  only): opened after isc_attribute_records.ins.pas by lir, lir_main,
  lir_utils, ra_utils, call_conv and the ISC units.

  A solution is the synthesized attribute record pass 1 builds for an
  IL node (432 bytes, isc_main's new_solution; lir_$build_operand makes
  an operand from one).  backend.ins.pas declares it as batch A's
  solution_t (the fields the LIR units read); the ISC units read it
  through isc_solution_t below, the whole record as the ISC sees it,
  cast from solution_ptr_t where a batch A heading takes one.  The two
  views are kept (backend.ins.pas is opened by units that open no ISC
  insert, and solution_t's packed groups f78 and f84 differ from f76
  here), and both carry the image's names for the fields they name
  (docs/questions.md 267).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k (translator PD).  The solution kinds are the SOLUTION$
  identifiers (tools/cc_enumnames.py: the table at cc.a88k 0x24526E,
  25 names, written by lir_$build_operand, and its copies in
  guarantee_has_live_range, local_initialize_symbol and dump_solution).
  The fields' names are the image's: dump_solution (isc_debug) prints
  each attribute after its name (docs/questions.md 267).

  Not known from the original: the record's and the unnamed fields'
  names (by offset; f76 and f114 group the packed bytes), the kind
  set's name. }

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

  { A solution as the ISC reads it (432 bytes; see above).  The
    fields carry the image's names (dump_solution prints each attribute
    after its name, docs/questions.md 267; the generator's attribute
    declarations, rules/declarations.isc, use the same names); those
    named by offset are fields dump_solution does not print. }
  isc_solution_ptr_t = ^isc_solution_t;
  isc_solution_t = record
    object_with_name: univ_ptr;         { +0: the object (node) }
    base_register: lr_ptr_t;            { +4: new_solution sets it and
                                          index_register to
                                          isc_user_routines_31c (a
                                          solution: docs/questions.md
                                          262) }
    index_register: lr_ptr_t;           { +8 }
    l12: integer32;                     { +12 }
    false_label: integer32;             { +16 }
    live_range: lr_ptr_t;               { +20 }
    live_range_of_imaginary_part: lr_ptr_t;     { +24 }
    advancing_displacement: integer32;  { +28 }
    bits_known: integer32;              { +32 }
    bits_trusted: integer32;            { +36 }
    bits_known_of_fetched_value: integer32;     { +40 }
    bits_trusted_of_fetched_value: integer32;   { +44 }
    literal_32_bits_value: integer32;   { +48: a displacement or a
                                          literal's value (the CSE
                                          accessors _disp and
                                          _lit_value) }
    pass_1_size: integer32;             { +52 }
    bytes: integer;                     { +56 }
    fp_reg_max: integer;                { +58 }
    fp_reg_result: integer;             { +60 }
    fp_reg_pair_max: integer;           { +62 }
    fp_reg_pair_result: integer;        { +64 }
    fp_reg_quad_max: integer;           { +66 }
    fp_reg_quad_result: integer;        { +68 }
    ip_reg_max: integer;                { +70 }
    ip_reg_result: integer;             { +72 }
    n_bytes_to_back_up: integer;        { +74 }
    f76: packed record                  { +76 }
      bit_position_of_lsb: 0..255;      { +76 }
      field_precision: 0..255;          { +77: 32 when made }
      physical_register_number: 0..255; { +78 }
      scale: 0..255;                    { +79 }
      slevel_attribute: 0..255;         { +80 }
      all_zeroes_or_all_ones: boolean;  { +81 .7 }
      arg_block_location: boolean;      { .6 }
      bit_7_was_sign_extended: boolean; { .5 }
      bit_15_was_sign_extended: boolean;    { .4 }
      dead_end: boolean;                { .3 }
      derived_from_literal: boolean;    { .2 }
      embedded_strength_reduction_temporary: boolean;   { .1 }
      field_requires_sign_extend: boolean;  { .0 }
      has_a_symbolic_displacement: boolean; { +82 .7 }
      is_atomic: boolean;               { .6 }
      is_complex: boolean;              { .5 }
      is_destroyable: boolean;          { .4: set when made }
      is_dynm_vat: boolean;             { .3 }
      is_entire_object: boolean;        { .2: set when made }
      is_physical: boolean;             { .1 }
      is_set_temporary: boolean;        { .0 }
      is_volatile: boolean;             { +83 .7 }
      literal_64_bits_value_is_zero: boolean;   { .6 }
      literal_derived_from_floating_constant: boolean;  { .5 }
      materialize_true_as_1: boolean;   { .4 }
      physical_register: boolean;       { .3 }
      physical_register_from_function_call: boolean;    { .2 }
      physical_register_is_no_modify: boolean;  { .1 }
      physical_register_user_declared: boolean; { .0 }
      uses_the_base_register: boolean;  { +84 .7 }
      uses_the_displacement: boolean;   { .6 }
      uses_the_index_register: boolean; { .5 }
      b84_4_0: 0..31;
      b85: 0..255;                      { +85 }
      b86: 0..255;                      { +86 }
      b87: 0..255;                      { +87 }
      end;
    before_transform: isc_solution_ptr_t;   { +88: the solution this
                                          one was made from, which
                                          pass_2 passes on to }
    code_bytes: 0..65535;               { +92 (unsigned:
                                          choose_one_cse_solution) }
    delay: 0..65535;                    { +94 }
    evaluation_order: integer;          { +96: 1 the children left to
                                          right, 2 right to left
                                          (pass_2); 1 when made }
    il_kind: integer;                   { +98: il$t's ordinal
                                          (new_solution's last
                                          argument) }
    il: univ_ptr;                       { +100 }
    inherited_attributes: inherited_attributes_ptr_t;   { +104 }
    kind: integer;                      { +108: solution$t's ordinal }
    memory_references: 0..65535;        { +110 (compared `bcc') }
    which_transform: integer;           { +112: the pattern's number
                                          (pass_2 calls the pass-2
                                          action of this number) }
    f114: packed record                 { +114 }
      number_of_children: 0..255;       { +114: at most 5 }
      already_preserved: boolean;       { +115 .7: preserve_solution's
                                          copy }
      builtin_could_deadlock_sched: boolean;    { .6 }
      builtin_is_local_cse: boolean;    { .5 }
      builtin_local_cse_has_been_preserved: boolean;    { .4 }
      already_through_pass_2: boolean;  { .3 }
      b2, b1, b0: boolean;
      end;
    children: array [1..5] of isc_solution_ptr_t;  { +116 }
    space136: array [136..351] of char; { +136: the rules' own byte
                                          locals (case_value +136,
                                          already_address_mode ..
                                          already_processor_reg +342
                                          .. +348: isc_debug's
                                          ds_solution_t) }
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

