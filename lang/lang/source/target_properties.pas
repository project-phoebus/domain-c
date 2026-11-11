{ target_properties - TARGET_PROPERTIES, the description of the machine
  the code is for.  Each compilation starts from one of four read-only
  descriptions (the section target_properties_read_only); kernel-mode
  code takes the kernel's register conventions in place of the user's;
  some CPU revisions limit three values to 16 bits.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0B6328  0x0B9DF0  target_properties$begin_compilation
    0x0B637E  0x0B9E46  target_properties$kernel_mode_code
    0x0B63B2  0x0B9E7A  target_properties$cpu_rev_specific
    A5 0x2CE528 (cc.m68k), 0x44E6AC (cc.a88k): the module's data, the
    current description (+0, 326 bytes) and 58 bytes no routine here uses
    (0x180 to emit's data).
    Section target_properties_read_only: cc.m68k 0x354A24, 0x520 bytes,
    four entries 328 bytes apart.

  Every routine is global and loads A5.
}
module target_properties;

%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/coff.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/at_lib_dsc.ins.pas';

{ TODO(pascal) the read-only descriptions' contents

  The four entries are built by .rwdi; `tools/cc_data.py
  ctape/install/ri.apollo.cc.v.6.9.m/cc.m68k 354a24 1312' (and cc.a88k's
  section) prints them.  They are declared here without their
  initializer until target_properties_$t's fields are typed. }

define
  target_properties;                    { +0 (declared extern in
                                          target_properties.ins.pas) }

var (target_properties_read_only)
  target_table: array [0..3] of target_properties_$t;

{ target_properties$begin_compilation - take the description of target.

  0x0B6328, 0x56 bytes: target (a word) times 328 (`lsl.w #3' twice,
  `lsl.w #2', the sums) indexes the table at 0x354A24 (`movea.l #');
  326 bytes are copied to +0 (27 passes of 12 bytes and a word); then
  +0xAC := the address 0x35470C (at_lib_dsc + 0x1284). }

procedure target_properties$begin_compilation(
    target: integer);
begin
  target_properties := target_table[target];
  target_properties.p_ac := addr(at_lib_dsc[16#1284]);
end;

{ target_properties$kernel_mode_code - describe kernel-mode code.

  0x0B637E, 0x34 bytes: the 42 bytes at +0x100 copied to +0xD0 (5 passes
  of 8 and a word); +0x129 to +0x13A, +0x130 to +0x13B. }

procedure target_properties$kernel_mode_code;
begin
  target_properties.user_mode := target_properties.kernel_mode;
  target_properties.p_13a := target_properties.kernel_mode.m_29;
  target_properties.p_13b := target_properties.p_130;
end;

{ target_properties$cpu_rev_specific - adjust for the CPU revision flags.

  0x0B63B2, 0x9C bytes.  Only when +0x10 is 0: with flag bit 0, +0x5C and
  +0x6C := 32767, +0x60 and +0x70 := -32768, +0xC4 := 16#5FFF, 16#77FF,
  16#7FFF (12 bytes copied from the constant at 0x0B644E), +0x58 := 0 and
  +0x84 := 0; else +0x58 := 0 unless bit 3, and with bit 9 or 10
  (16#600) the same 16-bit limits as for bit 0.

  Not known from the original:
  - how the three limits were written (the image copies a 12-byte
    constant; written here as three assignments). }

procedure target_properties$cpu_rev_specific(
    flags: integer);
begin
  if target_properties.p_10 = 0 then begin
    if (flags & 1) <> 0 then begin
      target_properties.p_5c := 32767;
      target_properties.p_60 := -32768;
      target_properties.p_6c := 32767;
      target_properties.p_70 := -32768;
      target_properties.p_c4[0] := 16#5FFF;
      target_properties.p_c4[1] := 16#77FF;
      target_properties.p_c4[2] := 16#7FFF;
      target_properties.p_58 := 0;
      target_properties.p_84 := chr(0);
    end
    else begin
      if (flags & 8) = 0 then
        target_properties.p_58 := 0;
      if (flags & 16#600) <> 0 then begin
        target_properties.p_5c := 32767;
        target_properties.p_60 := -32768;
        target_properties.p_6c := 32767;
        target_properties.p_70 := -32768;
        target_properties.p_c4[0] := 16#5FFF;
        target_properties.p_c4[1] := 16#77FF;
        target_properties.p_c4[2] := 16#7FFF;
      end;
    end;
  end;
end;
