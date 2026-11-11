{ lang/lang/source/gen_unwind.ins.pas - the interface of
  lang/lang/source/gen_unwind.pas (the unwind and exception tables).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries:
  gen_unwind's frames and its callers' (outbin and unix_objmod in
  cc.m68k; be_com's bin.pas and unix_objmod in cc.a88k).

  Not known from the original: the parameter names; the names of the
  scope's fields (read off the stores and tests; cc.a88k's bin.pas
  prints most of the a88k ones under a description). }

type
  { A scope of a routine's code, as the back ends describe it to
    gen_unwind_$add_scope (46 bytes, copied whole): the start and length
    of the code, then the target's description of the frame, laid out
    by target (gen_unwind's +36, the target given to
    gen_unwind_$begin_compilation):
    - 0, m68k (outbin.pas's begin_unwind_scope and end_unwind_scope, at
      its A5 + 0xD60): the offset of the saved registers (the block's
      +224), the registers saved (a set each of the address, data and
      floating registers; outbin's from the block's +220);
    - 2, PA (no back end of either binary describes one: the fields
      gen_unwind reads);
    - 3, a88k (cc.a88k bin.pas's add_unwind_rec, which prints them:
      the IP and FP registers saved, the SF offset of the saved
      registers, the PC offsets when the registers are saved and when
      the stack frame is pushed, the return PC register, ...).
    1 is the i860 (gen_unwind: 'i860 unimplemented'). }
  gen_unwind_$scope_t = record
    start: integer32;                   { +0 }
    len: integer32;                     { +4 }
    case integer of
      0: (x8: integer32;                { +8: the saved registers'
                                          offset (the block's +224) }
          x12: integer32;               { +12 }
          aregs: set of 0..15;          { +16 }
          dregs: set of 0..15;          { +18 }
          fregs: set of 0..15;          { +20 }
          b22: boolean;                 { +22 }
          b23: boolean;                 { +23 }
          b24: boolean;                 { +24 }
          rest: array [1..21] of char); { +25: to 46 bytes }
      2: (pa_gregs: integer32;          { +8: the general registers
                                          saved, bit n register n }
          pa_fregs_hi: integer32;       { +12: the floating registers
                                          saved, a 64-bit mask }
          pa_fregs_lo: integer32;       { +16 }
          pa_frame_size: integer32;     { +20 }
          pa_save_off: integer32;       { +24 }
          pa_regs_pc: integer;          { +28 }
          pa_w30: integer;              { +30 }
          pa_w32: integer;              { +32 }
          pa_rp_reg: integer;           { +34 }
          pa_b36: boolean;              { +36 }
          pa_b37: boolean);             { +37 }
      3: (a_gregs: integer32;           { +8: the IP registers saved }
          a_fregs1: integer32;          { +12: the FP registers saved }
          a_fregs2: integer32;          { +16 }
          a_x20: integer32;             { +20 }
          a_sf_offset: integer32;       { +24: the SF offset of the
                                          saved registers }
          a_regs_pc: integer;           { +28: the PC offset when the
                                          registers are saved }
          a_frame_pc: integer;          { +30: the PC offset when the
                                          stack frame is pushed }
          a_x32: integer;               { +32 }
          a_rp_reg: integer;            { +34: the return PC register }
          a_b36: boolean;               { +36 }
          a_rp_saved: boolean;          { +37: the return PC is saved }
          a_sf4_reg: integer;           { +38: the register saved at
                                          [SF,4], -1 for none }
          a_sf12_reg: integer;          { +40: at [SF,12] }
          a_frame_pushed: boolean;      { +42: the stack frame is
                                          pushed }
          a_b43: boolean;               { +43: the stack frame register
                                          above 23 }
          a_b44: boolean);              { +44 }
  end;

{ GEN_UNWIND_$BEGIN_COMPILATION - the unwind table started: the unwind
  section's record (unix_objmod's, 6156 bytes; its relocations are
  noted against it) and the target (0 m68k, 2 PA, 3 a88k), a word by
  value.  cc.m68k 0x07A884. }
procedure gen_unwind_$begin_compilation(
    sect: univ_ptr;
    isp: integer); options(val_param); extern;

{ GEN_UNWIND_$ADD_SCOPE - a scope added to the unwind table of the
  section whose symbol is symndx; base the address of the longword
  added to the section's addresses (cc.a88k's bin.pas passes the
  section's +56, outbin nil).  0x07A920: the scope by address, two
  longwords by value. }
procedure gen_unwind_$add_scope(
    in scope: gen_unwind_$scope_t;
    base_addr: univ_ptr;
    sym: integer32); options(val_param); extern;

{ GEN_UNWIND_$DUMP_UNWIND_TABLE - the unwind table written at offset
  pos of the object file (mode not above 0: only sized); its size in
  D0.  The exception table's records (when there were exceptions) are
  relocated against data_sym and table_sym, table_addr the table's
  address; form 0 the SR10.0 records, 1 the SR10.3 ones.  0x07C0AE:
  five longwords and a word by value (unix_objmod passes 2 and three
  -1 when there is no exception table). }
function gen_unwind_$dump_unwind_table(
    pos: integer32;
    mode: integer32;
    data_sym: integer32;
    table_sym: integer32;
    table_addr: integer32;
    form: integer): integer32; options(val_param); extern;

{ GEN_UNWIND_$ADD_EXCEPTION_TABLE_ENTRY - the exception frame of the
  code from start, len bytes, added to the last scope.  0x07C12E: five
  longwords, the first by address (cc.a88k's bin.pas passes its own
  frame parameter's address, then -1); only the last three are read. }
procedure gen_unwind_$add_exception_table_entry(
    in p1: univ_ptr;
    p2: integer32;
    start: integer32;
    len: integer32;
    frame: univ_ptr); options(val_param); extern;

{ GEN_UNWIND_$DUMP_EXCEPTION_TABLE - the exception table written at
  offset pos; its size in D0.  0x07C2D2: reads only pos; unix_objmod
  passes 2 as well. }
function gen_unwind_$dump_exception_table(
    pos: integer32;
    mode: integer32): integer32; options(val_param); extern;

{ GEN_UNWIND_$END_COMPILATION - the exception table's tuple and handler
  addresses stored into the unwind table's first exception record.
  0x07C392: two longwords by value. }
procedure gen_unwind_$end_compilation(
    tuple_addr: integer32;
    handler_addr: integer32); options(val_param); extern;
