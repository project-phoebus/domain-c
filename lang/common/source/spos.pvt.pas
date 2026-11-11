{ lang/common/source/spos.pvt.pas - spos.pas's private declarations:
  the region record and the module's data.

  No Apollo copy survives; read off spos.pas (cc.m68k 0x071C70..
  0x073212).  spos.pas opens it after cail.ins.pas; it uses spos.ins.pas's
  types.

  Module data as the image has it (A5 0x14B874 in cc.m68k; the cells
  from +12020 on are declared in spos.pas, after its `define', so that
  dpc lays them out in the image's order):
    +0      the captured marks, 3001 longwords (.rwdi: 0, repeated 3001
            times)
    +12004  the captured marks' count   \
    +12008  the include files opened     | .rwdi: 16 bytes of 0
    +12012  the marked files' count      |
    +12016  the include depth           /
    +12020  spos_$line, +12024 spos_$region, +12028 spos_$null_position,
            +12030 spos_$position (spos.ins.pas)
    +12032  the marks locked (.rwdi: 0)
    +12036  the regions' database (108044 bytes), addressed absolutely
            (0x14E778): its offsets pass 16 bits, so Rev 8.89 does not
            reach it from A5.  The next position (a word), the last
            region (a longword), and from +8 the regions [0..3000].  dpc
            puts the array at +6 (after the longword at +2); the layout
            is private to the unit.

  Not known from the original: every name here; whether the database
  was one record (taken from its absolute addressing: the cells before
  it, as small, are A5-relative); what the image's +6..+7 hold.
}

const
  { The last region's bound: SPOS_$RESUME_FILE's invariant (`cmpi.l
    #3000; bcs', 0x0720DE) lets the last region reach 3000;
    SPOS_$MAY_START_INCLUDE_FILE compares with 2999. }
  spos_max_region = 3000;

type
  { A region: a stretch of one source file's lines (36 bytes).  A file
    resumed after an include file gets a new region, the next of its
    previous one; the root region is the file's first. }
  spos_region_t = record
    user_name: univ_ptr;                { +0: as given (a string token) }
    name_used_to_open: univ_ptr;        { +4 }
    full_path_name: univ_ptr;           { +8 }
    unit_name: univ_ptr;                { +12 }
    dtm: integer32;                     { +16 }
    line: spos_$line_t;                 { +20: the line before the
                                          region's first ("Base Line
                                          Number") }
    mark: integer32;                    { +24: the file's mark, 0 for
                                          none (kept in the root) }
    root: spos_$region_t;               { +28: the file's root region }
    next: integer;                      { +32: the file's next region,
                                          -1 for none }
    position: spos_$position_t;         { +34: the position before the
                                          region's first line ("Base
                                          Source Position") }
  end;

var
  captured_marks: array [0..spos_max_region] of integer32 := [* of 0];
                                        { +0: each root region's mark when
                                          SPOS_$CAPTURE_FILE_MARKS ran;
                                          SPOS_$INIT_SOURCE_POSITION and
                                          SPOS_$START_INCLUDE_FILE start
                                          a region's mark from it }
  captured_count: integer32 := 0;       { +12004 }
  include_files: integer32 := 0;        { +12008: the include files
                                          opened }
  marked_count: integer32 := 0;         { +12012 }
  include_depth: integer32 := 0;        { +12016 }
