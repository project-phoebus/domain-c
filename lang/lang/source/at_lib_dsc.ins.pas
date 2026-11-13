{ lang/lang/source/at_lib_dsc.ins.pas - the attribute library's
  descriptors: the read-only data in the sections at_lib_dsc (cc.m68k
  0x353488, 0x159C bytes) and at_lib_dsc_ptr (0x353398, 0xF0 bytes).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: every name here.
}

{ TODO(pascal) at_lib_dsc's contents

  Declared as bytes until the units that read them are translated;
  target_properties$begin_compilation takes the address of +0x1284
  (0x35470C). }

var (at_lib_dsc)
  { The section at_lib_dsc, shared by the units that declare it (as
    std_lib and mem_$data$ are).  The section's variables are taken as
    one array; at_lib_dsc itself is a node kind's name (208,
    il.ins.pas's il_$kind_t), so the array cannot be named after the
    section. }
  at_lib_dsc_bytes: array [0..16#159B] of char;

var
  { The section at_lib_dsc_ptr (cc.a88k 0x513D40, 240 bytes, initialized
    by the loader): 60 pointers to library descriptors (cc.a88k's
    rewrite_$routine_call takes the run-time routine of an operator from
    it: [34..41] by result class, [46..59] single routines; translator
    PD).  Not known from the original: the declaration. }
  at_lib_dsc_ptr: extern array [0..59] of il_$node_ptr_t;
