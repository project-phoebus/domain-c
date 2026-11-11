{ lang/lang/source/target_properties.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/target_properties.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ TARGET_PROPERTIES - the description of the machine the code is for: one
  record (target_properties.pas's data), copied at the start of each
  compilation from one of four read-only entries and then adjusted for
  kernel-mode code and the CPU revision.  The layout is the same in
  cc.m68k and cc.a88k (their tables differ).

  Field names: what the image says of a field is only its offset and
  width, so the fields are named by offset until the units that use them
  are translated (the users of each are in docs/globals-cc.*.md).

  Not known from the original: every name here. }

{ TODO(pascal) target_properties_$t's fields are named by offset

  The record is 326 bytes (begin_compilation copies 27 x 12 + 2; the
  read-only entries are 328 apart).  A char array of two or more is word
  aligned, so odd single bytes are declared as chars on their own.  The fields declared are those some
  routine reads or writes with their widths; the spans between are byte
  arrays.  Name and type them as their users are translated. }

type
  { 42 bytes, copied whole by kernel_mode_code (+0x100 to +0xD0):
    attributes.pas takes the addresses of +0, +8, +0x10 and reads
    longwords at +0x18..+0x20. }
  target_properties_$mode_t = record
    m_0: array [0..7] of char;          { +0 }
    m_8: array [0..7] of char;          { +8 }
    m_10: array [0..7] of char;         { +0x10 }
    m_18: integer32;                    { +0x18 }
    m_1c: integer32;                    { +0x1C }
    m_20: integer32;                    { +0x20 }
    m_24: array [0..4] of char;         { +0x24 }
    m_29: char;                         { +0x29 }
  end;

  target_properties_$t = record
    p_0: array [0..15] of char;         { +0 }
    p_10: integer32;                    { +0x10: 6 units (debug_sym_dmp
                                          reads the word at +0x12) }
    p_14: array [0..16] of integer32;   { +0x14 (cc.a88k's back end reads
                                          words and longwords here) }
    p_58: integer32;                    { +0x58 }
    p_5c: integer32;                    { +0x5C: cpu_rev_specific: 32767 }
    p_60: integer32;                    { +0x60: -32768 }
    p_64: array [0..7] of char;         { +0x64 }
    p_6c: integer32;                    { +0x6C: 32767 }
    p_70: integer32;                    { +0x70: -32768 }
    p_74: array [0..10] of char;        { +0x74 }
    p_7f: boolean;                      { +0x7F: a boolean (tst.b, bmi), 7
                                          units }
    p_80: array [0..3] of char;         { +0x80 }
    p_84: char;                         { +0x84 }
    p_85: char;                         { +0x85 }
    p_86: array [0..1] of char;         { +0x86 }
    p_88: integer32;                    { +0x88 }
    p_8c: integer32;                    { +0x8C }
    p_90: integer32;                    { +0x90 }
    p_94: array [0..23] of char;        { +0x94 }
    p_ac: univ_ptr;                     { +0xAC: into at_lib_dsc }
    p_b0: array [0..19] of char;        { +0xB0 }
    p_c4: array [0..2] of integer32;    { +0xC4: three limits }
    user_mode: target_properties_$mode_t;    { +0xD0 }
    p_fa: array [0..5] of char;         { +0xFA }
    kernel_mode: target_properties_$mode_t;  { +0x100 }
    p_12a: array [0..5] of char;        { +0x12A }
    p_130: char;                        { +0x130 }
    p_131: char;                        { +0x131 }
    p_132: array [0..7] of char;        { +0x132 }
    p_13a: char;                        { +0x13A }
    p_13b: char;                        { +0x13B }
    p_13c: array [0..9] of char;        { +0x13C }
  end;

var
  { target_properties.pas's data, +0. }
  target_properties: extern target_properties_$t;

{ TARGET_PROPERTIES$BEGIN_COMPILATION - take the description of target
  (0..3).  0x0B6328: target a word by value. }
procedure target_properties$begin_compilation(
    target: integer); options(val_param); extern;

{ TARGET_PROPERTIES$KERNEL_MODE_CODE - describe kernel-mode code.
  0x0B637E. }
procedure target_properties$kernel_mode_code; extern;

{ TARGET_PROPERTIES$CPU_REV_SPECIFIC - adjust for the CPU revision flags.
  0x0B63B2: flags a word by value. }
procedure target_properties$cpu_rev_specific(
    flags: integer); options(val_param); extern;
