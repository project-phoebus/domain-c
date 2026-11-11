{ lang/common/source/spos.ins.pas - SPOS_, source positions: a word
  encoding a source region (the main file or an include file) and a
  line (lang/common/source/spos.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far; the headings
  are read off spos.pas's frames and its callers.

  Not known from the original: every name but the routines'.
}

{ TODO(pascal) spos.ins.pas is incomplete

  The rest of SPOS_'s interface is added when spos.pas and its other
  callers are translated. }

var
  { spos.pas's data, A5 0x14B874 (cc.m68k), +0x2EFC (0x14E770): a word
    15 units read; c_error's cgerr_no_source reports at it, and its
    error_hdr prints no line number for a line equal to it: the
    position of no source line. }
  spos_$null_position: extern integer;

{ SPOS_$DECODE_SOURCE_POSITION - pos's region and line.  0x072544:
  pos a word by value, region and line longwords by address. }
procedure spos_$decode_source_position(
    pos: integer;
    out region: integer32;
    out line: integer32); options(val_param); extern;

{ SPOS_$IS_MAIN_SOURCE_FILE - region is the main source file (region
  0: `seq').  0x07250C. }
function spos_$is_main_source_file(
    region: integer32): boolean; options(val_param); extern;

{ SPOS_$REGION_USER_NAME - the name of region's file as the user gave
  it, an object PRTOBJ prints (the result in A0).  0x0727A6. }
function spos_$region_user_name(
    region: integer32): univ_ptr; options(val_param); extern;
