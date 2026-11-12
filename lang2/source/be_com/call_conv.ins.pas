{ lang2/source/be_com/call_conv.ins.pas - call_conv.pas's insert
  (cc.a88k only): the calling conventions.  Opened after the opcode
  enumeration by asm, at_backend, com, dbg_life, lir, lir_main,
  lir_utils, mmt, ra, ra_utils, sched, call_conv itself and the ISC
  units isc_debug, isc_main and rewrite.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  call_conv.pas (0x0B3F48, 9 routines; it also opens the
  front end's c_objtype, c_globals and c_externs) is called from other
  units only by these two routines.  arg_loc_t, the argument locations,
  is backend.ins.pas's: isc_user_routines writes one without opening
  this insert.

  Not known from the original: the parameter names. }

{ TODO(pascal) call_conv.ins.pas: the conventions' records (at_call_conv's
  result, at_backend_4fc), when call_conv.pas is translated }

{ GET_RLEN_AND_SIZE - an IL type's length and size (rlen cleared, size
  cleared, then set by the kind at t's +2: a case on 77..200).
  0x0B3F48, 0x30A bytes; called from rewrite: t a pointer by value,
  rlen (a word) and size (a longword) by address. }
procedure get_rlen_and_size(
    t: il_$node_ptr_t;
    out rlen: integer;
    out size: integer32); options(val_param); extern;

{ AT_CALL_CONV - the calling conventions of a routine.  0x0B4604,
  0x1B3C bytes; called from at_backend (get_calling_conventions) and
  rewrite: a pointer by value; A0, a pointer. }
function at_call_conv(
    p1: univ_ptr): univ_ptr; options(val_param); extern;
