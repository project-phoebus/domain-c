{ ivory/volume_4/report/source/report.ins.pas - the compilers' report
  of a compilation (do_report.pas), and the library routine that writes
  it.  No copy survives.

  Not known from the original: everything about its contents but what
  do_report.pas uses.
}

type
  report_$byte_t = char;

  { The compiler's version: get_little_version's three words, passed by
    the address of the first. }
  report_$version_t = record
    major: integer;
    minor: integer;
    edit: integer;
  end;

  { do_report's first argument: c_main passes a word constant (2) by
    address and do_report passes on the address of its low-order byte. }
  report_$word_t = packed record
    high: report_$byte_t;
    low: report_$byte_t;
  end;

  report_$chars_t = array [1..1024] of char;

{ COMPILER_$WRITE_REPORT - write the report.  A library routine
  (transfer vector); the heading is read off do_report (cc.m68k
  0x0792B2): seven arguments by address: the language (a byte), the
  version, two the caller passes on, the option flags (a longword), and
  the source pathname's length and characters (iosub's).

  Not known from the original: the parameters' names and types. }
procedure compiler_$write_report(
    in language: report_$byte_t;
    in version: report_$version_t;
    in p3: univ integer32;
    in flags: integer32;
    in p5: univ integer32;
    in path_length: integer;
    in path: univ report_$chars_t); extern;
