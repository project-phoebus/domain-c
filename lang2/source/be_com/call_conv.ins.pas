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

  The conventions of a call (or of the routine being compiled:
  at_backend's get_calling_conventions keeps the routine's in
  at_backend_4fc), as at_call_conv builds them: one record from the
  heap, the header (80 bytes) and an argument descriptor (26 bytes) for
  the result, when there is one, and each argument.  A call
  instruction points to its call's (the longword after its operand
  slots: mmt's mmt_call_info_t reads +31, +33..+40).

  Not known from the original: the types' and fields' names but those
  the memory model's reading gives (async, no_reads ...); the presets'
  meaning beyond how at_call_conv combines them. }

type
  { A conventions preset (42 bytes): call_conv's module data has four
    (the routines with the other conventions, the ordinary ones,
    ftn_$stop's, the run-time library's), a block of language 1 or 5
    its own at +332 (c_blk_t's ropts), a kind 208 call node its own at
    +4.  The register sets: fp_* two longwords (the floating registers
    32..63, then 0..31), ip_* one (the integer registers); flags (a
    word, element k bit k): 6 the arguments are placed by prototype, 7
    the call is nested, 8 asynchronous, 10 the record's b29. }
  call_conv_$preset_ptr_t = ^call_conv_$preset_t;
  call_conv_$preset_t = record
    fp_preserved: array [0..1] of integer32;   { +0 }
    fp_clobbered: array [0..1] of integer32;   { +8 }
    fp16: array [0..1] of integer32;    { +16 }
    ip_preserved: integer32;            { +24 }
    ip_clobbered: integer32;            { +28 }
    ip32: integer32;                    { +32 }
    w36: integer;                       { +36 }
    flags: set of 0..15;                { +38 }
    reg40: integer;                     { +40: a register (26, 23):
                                          the record's w20 }
  end;

  { An argument descriptor (26 bytes; the result's first): offset (+0)
    its place in the argument area (aligned to its end for one of
    fewer than 4 bytes), num (+4) the argument's number (0 the result),
    size (+8) in bytes, sym (+12) the formal's symbol or the node of
    its temporary, rlen (+16) its register class (add_node's rlen: 1
    byte .. 7 double, 9 a string, 11 an aggregate, 12 a double complex),
    loc (+18) where it goes (arg_loc_t's ordinal: 0 an integer register,
    1 a single's floating register, 2 a pair, 3 a quad, 4 memory), kind
    (+20: 1, 2, 5, 6 a FORTRAN string's or length's, 0 otherwise), mode
    (+22: 0 by value, 1 by reference, 2 by descriptor, 3 the result's
    or a run-time library argument's), reg (+23) its register, by_value
    (+24: passed by value, as an aggregate may be split across
    registers), b25 (+25: of an unprototyped or variable argument). }
  call_conv_$arg_ptr_t = ^call_conv_$arg_t;
  call_conv_$arg_t = record
    offset: integer32;                  { +0 }
    num: integer;                       { +4 }
    w6: integer;                        { +6 }
    size: integer32;                    { +8 }
    sym: univ_ptr;                      { +12 }
    f16: packed record                  { +16 }
      rlen: 0..255;
      b17: 0..255;
      end;
    f18: packed record                  { +18 }
      loc: 0..255;
      b19: 0..255;
      end;
    f20: packed record                  { +20 }
      kind: 0..255;
      b21: 0..255;
      end;
    f22: packed record                  { +22 }
      mode: 0..255;
      reg: 0..255;
      end;
    by_value: boolean;                  { +24 }
    b25: boolean;                       { +25 }
  end;

  { The conventions: args_size (+0) the argument area's bytes; link
    (+4) the block a nested callee's static link reaches; data_sect (+8)
    the callee's data section; w14 (22, or the 208 node's) and w20 (the
    preset's reg40) two registers: w14's is clobbered, w20's in ip76;
    nargs (+22) the descriptors; the booleans from +26: nested, b27 the
    callee is defined here, b28 it may touch memory (cleared with
    no_reads), b30 its block was made, async (+31: a cleanup handler,
    pfm_$cleanup, or the preset's flag 8), cleanup (+32), the memory
    model's +33..+40 and b41, b42 (from the callee's rtn_t when it was
    compiled first); the register sets as the presets', the callee's own
    clobbers moved from preserved to clobbered.  batch A (PA3); the
    memory model's names from mmt.pas's mmt_call_info_t (question 171). }
  call_conv_$ptr_t = ^call_conv_$t;
  call_conv_$t = record
    args_size: integer32;               { +0 }
    link: univ_ptr;                     { +4 }
    data_sect: univ_ptr;                { +8 }
    w12: integer;                       { +12: 3 }
    w14: integer;                       { +14 }
    w16: integer;                       { +16: 2 or 21 }
    w18: integer;                       { +18: 21 }
    w20: integer;                       { +20 }
    nargs: integer;                     { +22 }
    w24: integer;                       { +24: -1, or the 208 node's }
    nested: boolean;                    { +26 }
    b27: boolean;                       { +27 }
    b28: boolean;                       { +28 }
    b29: boolean;                       { +29 }
    b30: boolean;                       { +30 }
    async: boolean;                     { +31 }
    cleanup: boolean;                   { +32 }
    no_reads: boolean;                  { +33 }
    no_writes: boolean;                 { +34 }
    no_reads_16: boolean;               { +35 }
    no_writes_16: boolean;              { +36 }
    own_only: boolean;                  { +37 }
    no_class_1: boolean;                { +38 }
    no_static: boolean;                 { +39 }
    no_dynamic: boolean;                { +40 }
    b41: boolean;                       { +41 }
    b42: boolean;                       { +42 }
    pad43: char;                        { +43 }
    fp_preserved: array [0..1] of integer32;   { +44 }
    fp_clobbered: array [0..1] of integer32;   { +52 }
    fp60: array [0..1] of integer32;    { +60 }
    ip_preserved: integer32;            { +68 }
    ip_clobbered: integer32;            { +72 }
    ip76: integer32;                    { +76 }
    args: array [1..1000] of call_conv_$arg_t;   { +80 }
  end;

{ GET_RLEN_AND_SIZE - an IL node's register class and size in bytes (0
  and 0 for what has none), by the node's kind.  0x0B3F48, 0x30A bytes;
  called from rewrite: t by value, rlen (a word) and size (a longword)
  by address. }
procedure get_rlen_and_size(
    t: il_$node_ptr_t;
    out rlen: integer;
    out size: integer32); options(val_param); extern;

{ AT_CALL_CONV - the calling conventions of a call node or a routine.
  0x0B4604, 0x1B3C bytes; called from at_backend
  (get_calling_conventions) and rewrite: the node by value; the record
  in A0. }
function at_call_conv(
    node: il_$node_ptr_t): call_conv_$ptr_t; options(val_param); extern;
