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

  Not known from the original: every name here; the fields named by
  offset are not read by the hand-written units translated so far. }

type
  { Where a node's instructions come from: the statement's line (a
    statement's +20) and its index in its block (a statement's +43..+44:
    `and.l #16#FFFF00' of its +42, `lsr.l #8').  Copied as one longword
    (`move.l (32,A3),(32,A0)'). }
  isc_pos_t = record
    line: integer;                      { +0 }
    stmt: integer;                      { +2 }
  end;

  { The inherited attributes: node (+0) the node they are made for,
    top (+4) its statement's +12 (lir: the statement's top-level
    record), stmt (+12) the statement node, call (+20) the call
    being built when the node is an argument (debug_lir_$begin_call_
    or_svc's record), precision (+24) and available (+28) bits (32 by
    default: precision_from_il_node's for a CSE), pos (+32) the
    statement's line and index (bug_check's %wd prints pos.line), arith
    (+38) the arithmetic (arith$t's ordinal: 1 arith_integer by
    default), flags (+39): b5 set for a call's routine operand and
    cleared for a CSE's tree, preserve (b2) the solutions made under
    them are preserved (preserve_solution, solution_list$preserve:
    copied from the parent's; set for a CSE's tree). }
  inherited_attributes_ptr_t = ^inherited_attributes_t;
  inherited_attributes_t = record
    node: univ_ptr;                     { +0 }
    top: univ_ptr;                      { +4 }
    l8: integer32;                      { +8 }
    stmt: univ_ptr;                     { +12 }
    l16: integer32;                     { +16 }
    call: univ_ptr;                     { +20 }
    precision: integer32;               { +24 }
    available: integer32;               { +28 }
    pos: isc_pos_t;                     { +32 }
    b36: char;                          { +36: cleared }
    b37: char;                          { +37 }
    f38: packed record                  { +38 }
      arith: 0..255;                    { +38: arith$t's ordinal }
      b7, b6: boolean;                  { +39 .7 .6 }
      b5: boolean;                      { .5 }
      b4, b3: boolean;                  { .4 .3 }
      preserve: boolean;                { .2 }
      b1, b0: boolean;                  { .1 .0 }
      end;
  end;
