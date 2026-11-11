{ lang/common/source/spos.ins.pas - SPOS_, source positions: the main
  source file and the include files read, as regions (up to 3000), and
  a source position encoded in a word (a line of the main file when not
  negative; else a position counted down through the include files'
  lines).

  No Apollo copy survives; the headings and cells are read off spos.pas
  (cc.m68k 0x071C70..0x073212, tools/cc_params.py) and its callers
  (c_lex_pp.pas, c_error.pas, c_sym_map.pas, error_listing.pas,
  unix_objmod.pas, debug_sym_dmp.pas, ...).  It stands alone (spos.pas
  opens it first).  Values by value (val_param); names are pointers
  kept as given.

  Not known from the original: every type, cell and parameter name here
  (the routine names are the binaries').
}

{ TODO(pascal) spos.pas is not translated yet

  The headings are complete; the region record and the rest of spos's
  data are for spos.pvt.pas when spos.pas is translated: +0 the base
  source position of each region (3000 longwords), +12004 and +12012
  the marked files' counts, +12008 the include files opened, +12016 the
  include depth, +12032 the marks locked; +12036 (0x14E778) the next
  position (a word) and +12038 the last region (a longword), then from
  +12044 the regions, 36 bytes each (user name, name used to open, full
  path name, unit name, dtm, base line, mark, root region, the next
  region of the file and the region's first position, a word). }

type
  { An encoded source position. }
  spos_$position_t = integer;

  { A region's number: compared unsigned with the last region. }
  spos_$region_t = 0..2147483647;

  { The routines SPOS_$APPLY_OVER_SOURCE_FILES and
    SPOS_$APPLY_OVER_MARKED_SOURCE_FILES call for each root region
    (`jsr (A0)' with the values pushed). }
  spos_$region_proc_t = ^procedure(
      region: integer32); options(val_param);
  spos_$marked_region_proc_t = ^procedure(
      region: integer32;
      mark: integer32); options(val_param);

var
  { spos.pas's data, A5 0x14B874 (cc.m68k), 0x2CB8E4 (cc.a88k). }
  spos_$line: extern integer32;                 { +0x2EF4: the line in
                                                  the current region }
  spos_$region: extern integer32;               { +0x2EF8: the current
                                                  region (0 the main
                                                  file) }
  spos_$null_position: extern integer;          { +0x2EFC: read by 15
                                                  units; spos clears it.
                                                  The position of no
                                                  source line: c_error's
                                                  cgerr_no_source reports
                                                  at it and its error_hdr
                                                  prints no line number
                                                  for it. }
  spos_$position: extern spos_$position_t;      { +0x2EFE: the current
                                                  line's position }

{ SPOS_$INIT_SOURCE_POSITION - the main source file (region 0).
  0x071C70: user_name and name_used_to_open must not be nil. }
procedure spos_$init_source_position(
    user_name: univ_ptr;
    name_used_to_open: univ_ptr;
    full_path_name: univ_ptr;
    dtm: integer32;
    unit_name: univ_ptr); options(val_param); extern;

{ SPOS_$NEXT_LINE - one line on.  0x071E32. }
procedure spos_$next_line; extern;

{ SPOS_$ENQUIRE_NEXT_LINE - the next line's position, not moving.
  0x071E5A. }
function spos_$enquire_next_line: spos_$position_t; extern;

{ SPOS_$SKIP_LINES - n lines on.  0x071E86. }
procedure spos_$skip_lines(
    n: integer32); options(val_param); extern;

{ SPOS_$START_INCLUDE_FILE - a new region for an include file.
  0x071EAE. }
procedure spos_$start_include_file(
    user_name: univ_ptr;
    name_used_to_open: univ_ptr;
    full_path_name: univ_ptr;
    dtm: integer32;
    unit_name: univ_ptr); options(val_param); extern;

{ SPOS_$MAY_START_INCLUDE_FILE - whether another region fits.
  0x072024. }
function spos_$may_start_include_file: boolean; extern;

{ SPOS_$RESUME_FILE - back in the file of region after an include file.
  0x07204A. }
procedure spos_$resume_file(
    region: spos_$region_t); options(val_param); extern;

{ SPOS_$CHANGE_FILE - a #line: a new region for the named file (or the
  same file) from line.  0x072378. }
procedure spos_$change_file(
    user_name: univ_ptr;
    name_used_to_open: univ_ptr;
    full_path_name: univ_ptr;
    dtm: integer32;
    unit_name: univ_ptr;
    line: integer32); options(val_param); extern;

{ SPOS_$IS_MAIN_SOURCE_FILE - region = 0.  0x07250C. }
function spos_$is_main_source_file(
    region: integer32): boolean; options(val_param); extern;

{ SPOS_$LINE_IS_IN_MAIN_SOURCE_FILE - position >= 0.  0x072528. }
function spos_$line_is_in_main_source_file(
    position: spos_$position_t): boolean; options(val_param); extern;

{ SPOS_$DECODE_SOURCE_POSITION - the region and line of a position.
  0x072544: position a word at (8,A6), region and line by address. }
procedure spos_$decode_source_position(
    position: spos_$position_t;
    out region: integer32;
    out line: integer32); options(val_param); extern;

{ SPOS_$ENCODE_SOURCE_POSITION - the position of line in the root
  region.  0x0725C4. }
function spos_$encode_source_position(
    region: spos_$region_t;
    line: integer32): spos_$position_t; options(val_param); extern;

{ SPOS_$LAST_SOURCE_REGION - 0x07278C. }
function spos_$last_source_region: integer32; extern;

{ The region's names (as given) and dtm.  0x0727A6..0x072A6C. }
function spos_$region_user_name(
    region: spos_$region_t): univ_ptr; options(val_param); extern;
function spos_$region_name_used_to_open(
    region: spos_$region_t): univ_ptr; options(val_param); extern;
function spos_$region_full_path_name(
    region: spos_$region_t): univ_ptr; options(val_param); extern;
function spos_$region_dtm(
    region: spos_$region_t): integer32; options(val_param); extern;
function spos_$region_unit_name(
    region: spos_$region_t): univ_ptr; options(val_param); extern;

{ SPOS_$MARK_SOURCE_FILE - the region's file marked; mark its number.
  0x072B1C. }
procedure spos_$mark_source_file(
    region: spos_$region_t;
    out mark: integer32); options(val_param); extern;

{ SPOS_$MARK_MAIN_SOURCE_FILE - SPOS_$MARK_SOURCE_FILE of region 0; the
  mark.  0x072C54. }
function spos_$mark_main_source_file: integer32; extern;

{ SPOS_$NUMBER_OF_SOURCE_FILES - the include files opened + 1.
  0x072C76. }
function spos_$number_of_source_files: integer32; extern;

{ SPOS_$LOCK_SOURCE_FILE_MARKS - no file may be marked newly.
  0x072C90. }
procedure spos_$lock_source_file_marks; extern;

{ SPOS_$NUMBER_OF_MARKED_SOURCE_FILES - 0x072CAA. }
function spos_$number_of_marked_source_files: integer32; extern;

{ SPOS_$APPLY_OVER_SOURCE_FILES, SPOS_$APPLY_OVER_MARKED_SOURCE_FILES -
  proc of each root region (of each marked one, with its mark).
  0x072CC2, 0x072D14. }
procedure spos_$apply_over_source_files(
    proc: spos_$region_proc_t); options(val_param); extern;
procedure spos_$apply_over_marked_source_files(
    proc: spos_$marked_region_proc_t); options(val_param); extern;

{ SPOS_$CAPTURE_FILE_MARKS - the marks kept as the base table.
  0x072D68. }
procedure spos_$capture_file_marks; extern;

{ SPOS_$REGION_IS_MARKED - 0x072DBA. }
function spos_$region_is_marked(
    region: spos_$region_t): boolean; options(val_param); extern;

{ The diagnostic dumps.  0x072E8E, 0x0730DC, 0x073164. }
procedure spos_$diag_dump_source_region(
    region: spos_$region_t;
    full: boolean); options(val_param); extern;
procedure spos_$diag_dump_source_position(
    position: spos_$position_t;
    full: boolean); options(val_param); extern;
procedure spos_$diag_dump_source_position_database(
    full: boolean); options(val_param); extern;
