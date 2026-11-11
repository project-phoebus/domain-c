{ do_report - report the compilation (compiler_$write_report): the
  language, the compiler's version, the source line count, the options
  as flags and the source file's pathname.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07916C  0x07AB4C  do_report
    A5 0x169A7C (cc.m68k), 0x2E9AEC (cc.a88k).

  Not known from the original: the parameters' and locals' names and
  types; what the flags mean beyond the options they come from.
}
module do_report;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/pfm.ins.pas';
%include 'ivory/volume_4/report/source/report.ins.pas';

{ do_report - the report, under a clean-up handler (pfm_$cleanup; on a
  fault, nothing).

  0x07916C, 0x168 bytes, called by c_main's cc with a word constant 2
  (the language) by address, the address of the source line count and a
  frame address, the last two passed on as they are.  The flags
  (`clr.l D2' then one `ori.l' each): processors 1..5 to bits 31..27,
  processor 6 to bit 25 and 8 to bit 26 (the first one stored with
  `move.l'), -DBS (db 2) bit 19, and the optimization level as 7 (-OPT
  level 0), 1 (3 and 4), 2 (5), 3 (6 to 8), 4 (9) in the low bits (a
  case on cargs_$options.opt, `cmpi.w #10; bcc'). }

procedure do_report(
    in language: report_$word_t;
    in lines: univ integer32;
    in p3: univ integer32);
var
  crec: pfm_$cleanup_rec;               { -64 }
  status: status_$t;                    { -72 }
  flags: integer32;                     { -68 }
  version: report_$version_t;           { -80 }
begin
  status := pfm_$cleanup(crec);
  if status.all = pfm_$cleanup_set then begin
    get_little_version(version.major, version.minor, version.edit);
    flags := 0;
    with cargs_$options do begin
      if 1 in cpu then
        flags := 16#80000000;
      if 2 in cpu then
        flags := flags ! 16#40000000;
      if 3 in cpu then
        flags := flags ! 16#20000000;
      if 4 in cpu then
        flags := flags ! 16#10000000;
      if 5 in cpu then
        flags := flags ! 16#08000000;
      if 6 in cpu then
        flags := flags ! 16#02000000;
      if 8 in cpu then
        flags := flags ! 16#04000000;
      if db = 2 then
        flags := flags ! 16#00080000;
      case opt of
        0: flags := flags ! 7;
        3, 4: flags := flags ! 1;
        5: flags := flags ! 2;
        6, 7, 8: flags := flags ! 3;
        9: flags := flags ! 4;
        otherwise ;
      end;
    end;
    compiler_$write_report(language.low, version, lines, flags, p3,
                           iosub_$source_pathname_length,
                           iosub_$source_pathname);
    pfm_$rls_cleanup(crec, status);
  end;
end;
