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

var
  at_lib_dsc: extern array [0..16#159B] of char;
