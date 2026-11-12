{ lang2/source/isc/isc_attribute_records.ins.pas - the ISC's attribute records (cc.a88k only): opened after
  isc_enumeration.ins.pas by lir, lir_main, lir_utils, ra_utils,
  call_conv and the ISC units.

  The ISC is an attribute-grammar instruction selector: pass 1 walks an
  IL tree top-down handing each node its inherited attributes (this
  record, 40 bytes from the ISC heap, isc_main's new_inherited_
  attributes) and builds the node's synthesized attributes bottom-up
  (the solutions, isc_solution_fields.ins.pas).  lir's lir_3b80
  (lir.pvt.pas lir_inherited_t, batch A's) is one of these records
  under another name: lir_$complete_top_level_node_inherited_attrs
  fills +4, +32 and +34 from a statement as the ISC's callers do.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k (translator PD: isc_main's new_inherited_attributes and
  duplicate_inherited_attributes, isc_call_handling, isc_cse_handling,
  lir's lir_$complete_top_level_node_inherited_attrs).

  The field names are the image's (isc_debug's isc_print_il_node
  prints each inherited attribute under its name: docs/questions.md
  271).  Not known from the original: the records' names, pos (the
  two words copied as one longword) and the fields named by offset
  (l8, b37, b1, b0: isc_print_il_node prints none of them). }

type
  { Where a node's instructions come from: the statement's line (a
    statement's +20) and its index in its block (a statement's +43..+44:
    `and.l #16#FFFF00' of its +42, `lsr.l #8').  Copied as one longword
    (`move.l (32,A3),(32,A0)'); bug_check's %wd prints its first word.
    The fields' names are the image's (isc_print_il_node), the record's
    is not. }
  isc_pos_t = record
    source_line_number: integer;        { +0 }
    stmt_number: integer;               { +2 }
  end;

  { The inherited attributes (field names the image's: isc_print_il_
    node prints each under its name, docs/questions.md 271): il (+0)
    the node they are made for, exception_frame (+4) its statement's
    +12 (lir: the statement's top-level record), original_il (+12) the
    statement node, conditional_target (+16) a label (label_to_string),
    call_instruction_ptr (+20) the call being built when the node is
    an argument (debug_lir_$begin_call_or_svc's record), fetch_precision
    (+24) and required_precision (+28) bits (32 by default: precision_
    from_il_node's for a CSE), pos (+32) the statement's line and index,
    parent_il_kind (+36) the parent's il$t ordinal (cleared by
    new_inherited_attributes), required_arithmetic (+38: arith$t's
    ordinal, 1 arith_integer by default), the flags of +39:
    conditional_sense (b7), immediate_parent_has_signed (b6),
    immediate_parent_wants_lvalue (b5: set for a call's routine operand,
    cleared for a CSE's tree), immediate_parent_wants_set_temporary
    (b4), immediate_parent_wants_signed (b3), inside_a_cse (b2: the
    solutions made under them are preserved: preserve_solution,
    solution_list$preserve; copied from the parent's, set for a CSE's
    tree). }
  inherited_attributes_ptr_t = ^inherited_attributes_t;
  inherited_attributes_t = record
    il: univ_ptr;                       { +0 }
    exception_frame: univ_ptr;          { +4 }
    l8: integer32;                      { +8 }
    original_il: univ_ptr;              { +12 }
    conditional_target: integer32;      { +16 }
    call_instruction_ptr: univ_ptr;     { +20 }
    fetch_precision: integer32;         { +24 }
    required_precision: integer32;      { +28 }
    pos: isc_pos_t;                     { +32: source_line_number,
                                          stmt_number }
    parent_il_kind: char;               { +36: cleared }
    b37: char;                          { +37 }
    f38: packed record                  { +38 }
      required_arithmetic: 0..255;      { +38: arith$t's ordinal }
      conditional_sense: boolean;       { +39 .7 }
      immediate_parent_has_signed: boolean;     { .6 }
      immediate_parent_wants_lvalue: boolean;   { .5 }
      immediate_parent_wants_set_temporary: boolean;    { .4 }
      immediate_parent_wants_signed: boolean;   { .3 }
      inside_a_cse: boolean;            { .2 }
      b1, b0: boolean;                  { .1 .0 }
      end;
  end;
