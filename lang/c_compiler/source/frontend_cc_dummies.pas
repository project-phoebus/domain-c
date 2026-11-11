{ frontend_cc_dummies - the entries the common code calls that only
  other front ends (Modula-2, FORTRAN) give a meaning: dummies in the C
  compiler.  Each returns false or reads a longword through the pointer
  1, a reference that faults if a dummy is ever reached where a value
  matters.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0673B4  0x067634  get_alignment
    0x0673D0  0x067650  create_m2_native_external_name
    0x0673EC  0x06766C  modify_m2_native_external_name
    0x067408  0x067688  pass_char_len_diff
    A5 0x14AECC (cc.m68k), 0x2CAECC (cc.a88k): the module has no data
    (ass.pas's A5 is the same address).

  The unit opens no insert (its .blocks file list is empty), so its
  headings are its own: they are not checked against the declarations
  the callers see (globals_from_frontend.ins.pas declares
  modify_m2_native_external_name as returning a pointer, which coff_syms
  reads from A0, and get_alignment).  Every routine is global and loads
  A5 though the module has no data.
}
module frontend_cc_dummies;

type
  frontend_cc_dummies_ptr_t = ^integer32;

{ get_alignment - a dummy.

  0x0673B4, 0x1C bytes: `link #-8' (the result slot and a 4-byte
  local); `movea.l #1,A0; move.l (A0),D0'.  cc.a88k's
  alignment_from_il_node 0x2108F2 passes an address (`pea (A2)'); the
  dummy does not read it.  dpc gives the same code for a local pointer
  set to 1 and dereferenced into the result.

  Not known from the original:
  - the parameter's name and type; the local's name; how the pointer 1
    was written (a constant, a cast). }

function get_alignment(
    in p: integer32): integer32;
var
  bad: frontend_cc_dummies_ptr_t;
begin
  bad := frontend_cc_dummies_ptr_t(1);
  get_alignment := bad^;
end;

{ create_m2_native_external_name - a dummy, as get_alignment.

  0x0673D0, 0x1C bytes; no caller in either binary.

  Not known from the original:
  - the parameter (none is read; one is given, as for
    modify_m2_native_external_name); the local's name. }

function create_m2_native_external_name(
    in name: integer32): integer32;
var
  bad: frontend_cc_dummies_ptr_t;
begin
  bad := frontend_cc_dummies_ptr_t(1);
  create_m2_native_external_name := bad^;
end;

{ modify_m2_native_external_name - a dummy, as get_alignment.

  0x0673EC, 0x1C bytes: the result in D0, though coff_syms's callers
  (count_global_sym 0x0A6834, put_global_sym 0x0A72C0) pass an address
  (`pea (8,A6)') and read A0: the C compiler never calls it with
  anything to modify.

  Not known from the original:
  - the parameter's name and type; the local's name. }

function modify_m2_native_external_name(
    in name: integer32): integer32;
var
  bad: frontend_cc_dummies_ptr_t;
begin
  bad := frontend_cc_dummies_ptr_t(1);
  modify_m2_native_external_name := bad^;
end;

{ pass_char_len_diff - false: no character length is passed apart.

  0x067408, 0x16 bytes: `link #-4' (the result slot); `clr.b D0'.
  cg_call's gen_call (0x0F7480, 0x0F75CA; cc.a88k's at_call_conv) passes
  an address (`pea (-172,A6)') and tests D0 (`tst.b').

  Not known from the original:
  - the parameter's name and type. }

function pass_char_len_diff(
    in p: integer32): boolean;
begin
  pass_char_len_diff := false;
end;
