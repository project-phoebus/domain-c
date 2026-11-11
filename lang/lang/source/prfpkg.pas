{ prfpkg - PRFPKG, the compiler's performance statistics: the CPU and
  elapsed time, page faults, disk and network I/O, the peak GSPACE space
  and the MRH space of each phase, printed into the listing by
  perfsummary (-STAT, with the options that affect code generation and
  the object module's sections) and to standard output (-METER).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0968D4  0x0982B4  perfinit
    0x096960  0x098340  perfstart
    0x0969FA  0x0983DA  perfstop
    0x096B00  0x0984E0  prfpkg_$activate_phase
    0x096B32  0x098512  prfpkg_$stop_active_phase
    0x096B58  0x098538  hhmmss
    0x096C58  0x098638  prtsection
    0x096CA8  0x098688  prt_section_stats
    0x096E28  0x098808  convert_time_$clock_t_to_hh_mm_ss
    0x096E64  0x098844  print_meter_results
    0x097648  0x099028  perfsummary
    A5 0x19CCE4 (cc.m68k), 0x31CD54 (cc.a88k): the module's data, to
    +0xE88: +0 proc2_$get_info's buffer (228 bytes), +0xE8 the 44
    phases' records (40 bytes each), +0x7C8 the process's UID, +0x7D0
    the listing line, +0x8D4..+0x8F7 the active phase's starting counts
    and clocks, +0x8F8 and +0x8FC prf_gspace_peak and prf_gspace_in_use,
    +0x900 the active phase (43: none), +0x908 the phases' names (32
    characters each, initialized; nothing else is).

  hhmmss, prtsection, convert_time_$clock_t_to_hh_mm_ss and
  print_meter_results do not load A5: hhmmss is internal, the others
  are nested (prtsection in prt_section_stats, the other two in
  perfsummary).

  Not known from the original: every name but the routines'.
}
module prfpkg;

%include 'us/us/ins/ubase.ins.pas';
%include '/sys/ins/fpp.ins.pas';
%include '/sys/ins/cal.ins.pas';
%include '/sys/ins/time.ins.pas';
%include '/sys/ins/proc1.ins.pas';
%include 'us/us/ins/proc2.ins.pas';
%include 'us/us/ins/unix_sig.ins.pas';
%include 'us/us/ins/unix_resource.ins.pas';
%include 'us/us/ins/fault.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';

type
  { cargs.ins.pas's options record, copied: the unit reads
    cargs_$options (meter, -STAT, the code-generation options,
    -SYSTYPE's name) by absolute address, and none of the inserts it
    opens is cargs.ins.pas (docs/questions.md).  The layout is that
    insert's, field for field. }
  cargs_$chars_t = array [1..1024] of char;
  cargs_$name_t = record
    length: integer;
    body: cargs_$chars_t;
  end;
  cargs_$options_t = packed record
    tree: 0..63;
    b278_1: boolean;
    b278_0: boolean;
    b279_7: boolean;
    b279_6: boolean;
    b279_5: boolean;
    bct: boolean;
    addr: boolean;
    na: boolean;
    nn: boolean;
    ra: boolean;
    b27a_7: boolean;
    b27a_6: boolean;
    sri: boolean;
    b27a_4: boolean;
    rd: boolean;
    force_inline: boolean;
    exp: boolean;
    map: boolean;
    imap: boolean;
    acmap: boolean;
    type_opt: boolean;
    b27b_4: boolean;
    indexl: boolean;
    subchk: boolean;
    i_star_2: boolean;
    b27b_0: boolean;
    l_star: 0..15;
    save: boolean;
    std: boolean;
    b27c_1: boolean;
    b27c_0: boolean;
    cond: boolean;
    warn: boolean;
    usrch: boolean;
    comchk: boolean;
    xrs: boolean;
    c: 0..3;
    x27d_0: 0..3;
    x27e_6: 0..3;
    b27e_4: boolean;
    b27e_3: boolean;
    b27e_2: boolean;
    b27e_1: boolean;
    fpra: boolean;
    b27f_7: boolean;
    frnd: boolean;
    opt: 0..15;
    info: 0..7;
    opt_on: set of 0..29;
    db: 0..3;
    dbh: boolean;
    cpu: set of 0..11;
    es: 0..3;
    flags_286: set of 0..20;
    b288_2: boolean;
    b288_1: boolean;
    b288_0: boolean;
    x289: 0..255;
    uc: boolean;
    u: boolean;
    ff: boolean;
    lcinc: boolean;
    b28a_3: boolean;
    alnchk: boolean;
    b28a_1: boolean;
    compress: boolean;
    ncompress: boolean;
    cd: boolean;
    xansi: boolean;
    ansi: boolean;
    nansi: boolean;
    stdc: boolean;
    natural: boolean;
    b28b_0: boolean;
    systype: cargs_$name_t;
    runtype: cargs_$name_t;
    l_name: cargs_$name_t;
    name_e92: cargs_$name_t;
    b_name: cargs_$name_t;
    esf_name: cargs_$name_t;
    cpp_name: cargs_$name_t;
    outputs: set of 0..6;
    meter: boolean;
    nclines: boolean;
    unwind: 0..1;
    name_1e9c: cargs_$name_t;
    b229e_7: boolean;
    name_22a0: cargs_$name_t;
  end;

const
  no_phase = 43;

type
  { A phase's statistics. }
  prf_phase_t = record
    cpu: time_$clock_t;                 { +0 }
    elapsed: time_$clock_t;             { +6 }
    faults: integer32;                  { +12 }
    align_traps: integer32;             { +16: set by nothing here }
    disk_io: integer32;                 { +20 }
    net_io: integer32;                  { +24 }
    dynamic: integer32;                 { +28: the peak GSPACE space }
    mrh_bytes: integer32;               { +32 }
    never: boolean;                     { +36: not run }
  end;

  prf_name_t = array [1..32] of char;

  { The object module's lists (IL's globals +0x10C, +0x110, +0x118):
    a node's next, name and sizes by offset. }
  prf_section_ptr_t = ^prf_section_t;
  prf_section_t = record
    case integer of
      1: (xp: array [0..7] of prf_section_ptr_t);
      2: (xl: array [0..7] of integer32);
  end;

define
  prf_gspace_in_use,                    { +0x8FC }
  prf_gspace_peak;                      { +0x8F8 }

var
  info: proc2_$info_t;                  { +0x0 }
  phases: array [0..43] of prf_phase_t; { +0xE8 }
  my_uid: uid_$t;                       { +0x7C8 }
  line: prtsub_$line_t;                 { +0x7D0 }
  start_faults: integer32;              { +0x8D4 }
  start_net_io: integer32;              { +0x8DC }
  start_disk_io: integer32;             { +0x8E0 }
  start_mrh_bytes: integer32;           { +0x8E4 }
  start_elapsed: time_$clock_t;         { +0x8E8 }
  start_cpu: time_$clock_t;             { +0x8F0 }
  active: integer;                      { +0x900 }
  phase_names: array [0..43] of prf_name_t := [   { +0x908 }
    'Syntax', 'Semantic Analysis', 'IL Decoding', 'IL Unit Analysis',
    'IL Translation', 'In-Line Expansion', 'High-Level Optimizer',
    '  Basic Block Analysis', '  Data Flow Analysis', '  Constant Motion',
    '  Loop Analysis', '  Strength Reduction', '  Common Subexpression',
    '  Lifetime Analysis', '  Assign Merging', '  Vector Transforms',
    '  Dead Code Elim', '  Register Allocation', '  Miscellaneous',
    'Code Generation', 'Peephole Optimization', 'Jump Branch Resolution',
    'Instruction Selection', 'Flow Graph Analysis', 'Memory Alias Analysis',
    'Data Flow Analysis', 'Constant Propagation', 'Graph Peepholes',
    'Lifetime Analysis', 'Common Optimizer', 'Induction Variables',
    'Loop Scheduler', 'Translate to Physical', 'Instruction Scheduling',
    'Register Allocation', 'Post Optimizer', 'Jump Branch Resolution',
    'Assemble Instructions', 'Record Debug Lifetimes',
    'Compress Instructions', 'BIN / LST  Production', 'Objmod',
    'Library Generation', 'Total'];

  { cargs.pas's data, A5 0x2C33EC + 0x278 (see the record above). }
  cargs_$options: extern cargs_$options_t;

  { IL's globals the section summary walks (il.pas's data, A5 0x169C70
    + 0x10C, + 0x110, + 0x118): il.ins.pas's il_10c, il_110 and il_118,
    declared here by their use, as this unit does not open il.ins.pas. }
  il_10c: extern prf_section_ptr_t;
  il_110: extern prf_section_ptr_t;
  il_118: extern prf_section_ptr_t;

{ perfinit - clear the statistics; no phase active; the process's UID.

  0x0968D4, 0x8C bytes: the GSPACE counts cleared; each phase's clocks
  and counts stored 0 (`move.l #0', `move.w #0': Rev 8.89's form here)
  and never set (`dbf' from 43). }

procedure perfinit;
var
  i: integer;
begin
  prf_gspace_in_use := 0;
  prf_gspace_peak := 0;
  for i := 0 to 43 do
    with phases[i] do begin
      cpu.high := 0;
      cpu.low := 0;
      elapsed.high := 0;
      elapsed.low := 0;
      faults := 0;
      align_traps := 0;
      disk_io := 0;
      net_io := 0;
      dynamic := 0;
      mrh_bytes := 0;
      never := true;
    end;
  active := no_phase;
  proc2_$who_am_i(my_uid);
end;

{ perfstart - phase becomes active: its starting clocks and counts.

  0x096960, 0x98 bytes: the four counts of the information buffer
  stored 0 before proc2_$get_info (228 bytes, a word constant); the
  GSPACE peak restarts at the space in use; MRH's chunks times 4096
  (`lsl.l #8; lsl.l #4'). }

procedure perfstart;
var
  status: status_$t;
begin
  active := phase;
  cal_$get_local_time(start_elapsed);
  proc1_$get_cput(start_cpu);
  info.faults_86 := 0;
  info.faults_90 := 0;
  info.disk_io := 0;
  info.net_io := 0;
  proc2_$get_info(my_uid, info, 228, status);
  start_disk_io := info.disk_io;
  start_net_io := info.net_io;
  start_faults := info.faults_86 + info.faults_90;
  prf_gspace_peak := prf_gspace_in_use;
  start_mrh_bytes := mrh_$chunks_in_use_max * 4096;
end;

{ perfstop - add phase's times and counts since perfstart.

  0x0969FA, 0x106 bytes: the elapsed and CPU clocks by cal_$sub_clock
  and cal_$add_clock (the phase's record at 40 * phase, `lsl.w #3' plus
  `lsl.w #2'); the dynamic space kept as a maximum; the MRH bytes stored
  (not added); never cleared; no phase active. }

procedure perfstop;
var
  now: time_$clock_t;                   { -12 }
  cpu_now: time_$clock_t;               { -20 }
  status: status_$t;                    { -24 }
begin
  cal_$get_local_time(now);
  discard(cal_$sub_clock(now, start_elapsed));
  cal_$add_clock(phases[phase].elapsed, now);
  proc1_$get_cput(cpu_now);
  discard(cal_$sub_clock(cpu_now, start_cpu));
  cal_$add_clock(phases[phase].cpu, cpu_now);
  proc2_$get_info(my_uid, info, 228, status);
  with phases[phase] do begin
    faults := faults + (info.faults_86 + info.faults_90 - start_faults);
    disk_io := disk_io + (info.disk_io - start_disk_io);
    net_io := net_io + (info.net_io - start_net_io);
    if prf_gspace_peak > dynamic then
      dynamic := prf_gspace_peak;
    mrh_bytes := mrh_$chunks_in_use_max * 4096 - start_mrh_bytes;
    never := false;
  end;
  active := no_phase;
end;

{ prfpkg_$activate_phase - stop the active phase, start phase.

  0x096B00, 0x32 bytes. }

procedure prfpkg_$activate_phase;
begin
  if active <> no_phase then
    perfstop(active);
  perfstart(phase);
end;

{ prfpkg_$stop_active_phase - stop the active phase.  0x096B32, 0x26
  bytes. }

procedure prfpkg_$stop_active_phase;
begin
  if active <> no_phase then
    perfstop(active);
end;

{ hhmmss - clock as hh:mm:ss.cc to the end of s.

  0x096B58, 0x100 bytes, no A5: cal_$decode_time, prtint of the hour,
  minute and second (width 2, zero filled) with ':' and '.'; the
  hundredths from cal_$float_clock's double, made single (FPP 0x0074
  0x00D4 0xFF3E), less its truncation (fpp_$eslv 0x0068), times 100.0
  (0x42C80000) and truncated (docs/rev889-patterns.md 19).

  Not known from the original: the locals' names; whether the
  hundredths were truncated or rounded (0x0068 taken for trunc). }

procedure hhmmss(
    in out s: prtsub_$line_t;
    in clock: time_$clock_t); internal;
var
  seconds: real;                        { -48, -44 }
  d: double;                            { -16 }
  tm: cal_$timedate_rec_t;              { -32 }
begin
  cal_$decode_time(clock, tm);
  prtint(s, tm.hour, 2, true);
  prtcatc(s, ':');
  prtint(s, tm.minute, 2, true);
  prtcatc(s, ':');
  prtint(s, tm.second, 2, true);
  prtcatc(s, '.');
  cal_$float_clock(clock, d);
  seconds := d;
  prtint(s, trunc((seconds - trunc(seconds)) * 100.0), 2, true);
end;

{ prt_section_stats - the object module's sections and their sizes into
  the listing.

  0x096CA8, 0x11C bytes: a heading (prttab(line, -1): no blanks), then
  three lists of IL: il_10c (next +4, name +8, size +12, printed when
  not 0), il_110 (next +4, name +8, size +20 - +16 + +24, when not 0)
  and il_118 (next +8, name +4, size +20, always).

  Not known from the original: what the three lists are. }

procedure prt_section_stats;
var
  p: prf_section_ptr_t;
  size: integer32;

  { prtsection - a section's name and size.  0x096C58, 0x50 bytes:
    prtobj of the name (6 bytes popped for 8 pushed,
    docs/rev889-patterns.md 11), its size at column 37 (width 10). }

  procedure prtsection(
      name: univ_ptr;
      size: integer32); options(val_param);
  begin
    prtobj(line, name);
    prttab(line, 37);
    prtint(line, size, 10, false);
    listln(line);
    line.length := 0;
  end;

begin
  prttab(line, -1);
  prtcats(line, '---------- Object Module Section Summary ----------', 51);
  listln(line);
  line.length := 0;
  listln(line);
  prtcats(line, '    Section Name                    Size (bytes)', 48);
  listln(line);
  line.length := 0;
  listln(line);
  p := il_10c;
  while p <> nil do begin
    if p^.xl[3] <> 0 then
      prtsection(p^.xp[2], p^.xl[3]);
    p := p^.xp[1];
  end;
  p := il_110;
  while p <> nil do begin
    size := p^.xl[5] - p^.xl[4] + p^.xl[6];
    if size <> 0 then
      prtsection(p^.xp[2], size);
    p := p^.xp[1];
  end;
  p := il_118;
  while p <> nil do begin
    prtsection(p^.xp[1], p^.xl[5]);
    p := p^.xp[2];
  end;
  listln(line);
end;

{ perfsummary - the statistics.

  0x097648, 0x982 bytes.  With -METER (cargs_$options.meter) first
  print_meter_results.  With -STAT (flags_286 element 9): a page of the
  phases that ran (name; for all but 6, the High-Level Optimizer
  heading, the CPU and elapsed times, page faults, disk/net I/O and the
  peak space in thousands, rounded, `m$dis$llw'), their totals (the
  peak's division unsigned, `m$diu$llw'), the sections (unless a library
  is being generated) and the options that affect code generation,
  then -SYSTYPE's name.  Strings are passed with their lengths;
  several share a tail with a longer one ('-DB ' in '-DB -OPT 4 ').

  Not known from the original: the locals' names; the form of the
  CPU chain (the image jumps to one prtcats call from each choice). }

procedure perfsummary;
var
  cpu_total: time_$clock_t;             { -36 }
  elapsed_total: time_$clock_t;         { -28 }
  faults_total: integer32;              { D2 }
  disk_io_total: integer32;             { D3 }
  net_io_total: integer32;              { D4 }
  dynamic_max: linteger;                { D5 }
  i: integer;                           { D6 }
  l: integer;

  { convert_time_$clock_t_to_hh_mm_ss - a clock's hours, minutes and
    seconds.  0x096E28, 0x3C bytes. }

  procedure convert_time_$clock_t_to_hh_mm_ss(
      in clock: time_$clock_t;
      out hh: integer;
      out mm: integer;
      out ss: integer);
  var
    tm: cal_$timedate_rec_t;            { -16 }
  begin
    cal_$decode_time(clock, tm);
    hh := tm.hour;
    mm := tm.minute;
    ss := tm.second;
  end;

  { print_meter_results - -METER: each phase that ran and the totals to
    standard output (PAS_$WRITE through the file at (-4,A5)).

    0x096E64, 0x744 bytes, the parent's frame from the dynamic link
    (the source line count at (8,A2)).  Times in seconds ((hh * 60 +
    mm) * 60 + ss).  The MRH bytes are printed as the change since the
    last phase printed (0 when unchanged, a longword literal).  Integer
    writes pass format codes 2681 and 2673 (the dynamic peak, the line
    count and the MRH change): the counts' types are not known.

    Not known from the original: the locals' names; the counts' types. }

  procedure print_meter_results;
  var
    cpu_sum: integer32;                 { -36 }
    elapsed_sum: integer32;             { -32 }
    faults_sum: integer32;              { -28 }
    traps_sum: integer32;               { -24 }
    disk_io_sum: integer32;             { -20 }
    net_io_sum: integer32;              { -16 }
    dynamic_most: integer32;            { -12 }
    last_mrh: integer32;                { -8 }
    hh, mm, ss: integer;                { -50, -48, -46 }
    cpu_seconds: integer32;             { D4 }
    elapsed_seconds: integer32;         { D2 }
    j: integer;
  begin
    write('print_meter_results:');
    writeln;
    write('  source path name: "');
    write(iosub_$source_pathname: iosub_$source_pathname_length);
    write('".');
    writeln;
    write('  source_line_count: ');
    write(source_line_count: 1);
    write('.');
    writeln;
    cpu_sum := 0;
    elapsed_sum := 0;
    faults_sum := 0;
    traps_sum := 0;
    disk_io_sum := 0;
    net_io_sum := 0;
    dynamic_most := 0;
    last_mrh := 0;
    for j := 0 to 43 do
      with phases[j] do
        if not never then begin
          write('  phase: ');
          write(phase_names[j]: 32);
          write(' ');
          convert_time_$clock_t_to_hh_mm_ss(cpu, hh, mm, ss);
          cpu_seconds := (hh * 60 + mm) * 60 + ss;
          write('cpu: ');
          write(cpu_seconds: 8);
          write(' ');
          convert_time_$clock_t_to_hh_mm_ss(elapsed, hh, mm, ss);
          elapsed_seconds := (hh * 60 + mm) * 60 + ss;
          write('elapsed: ');
          write(elapsed_seconds: 8);
          write(' ');
          write('faults: ');
          write(faults: 8);
          write(' ');
          write('align_traps: ');
          write(align_traps: 8);
          write(' ');
          write('diskio: ');
          write(disk_io: 8);
          write(' ');
          write('netio: ');
          write(net_io: 8);
          write(' ');
          write('dynamic: ');
          write(dynamic: 8);
          write(' ');
          if last_mrh = mrh_bytes then begin
            write('mrh_bytes: ');
            write(0: 8);
            write(' ');
          end
          else begin
            write('mrh_bytes: ');
            write(mrh_bytes - last_mrh: 8);
            write(' ');
            last_mrh := mrh_bytes;
          end;
          writeln;
          cpu_sum := cpu_sum + cpu_seconds;
          elapsed_sum := elapsed_sum + elapsed_seconds;
          faults_sum := faults_sum + faults;
          traps_sum := traps_sum + align_traps;
          disk_io_sum := disk_io_sum + disk_io;
          net_io_sum := net_io_sum + net_io;
          if dynamic > dynamic_most then
            dynamic_most := dynamic;
        end;
    write('  phase: ');
    write(phase_names[43]: 32);
    write(' ');
    write('cpu: ');
    write(cpu_sum: 8);
    write(' ');
    write('elapsed: ');
    write(elapsed_sum: 8);
    write(' ');
    write('faults: ');
    write(faults_sum: 8);
    write(' ');
    write('align_traps: ');
    write(traps_sum: 8);
    write(' ');
    write('diskio: ');
    write(disk_io_sum: 8);
    write(' ');
    write('netio: ');
    write(net_io_sum: 8);
    write(' ');
    write('dynamic: ');
    write(dynamic_most: 8);
    write(' ');
    write('mrh_bytes: ');
    write(last_mrh: 8);
    write(' ');
    writeln;
  end;

begin
  if cargs_$options.meter then
    print_meter_results;
  if 9 in cargs_$options.flags_286 then begin
    ejctln;
    line.length := 0;
    prttab(line, 28);
    prtcats(line, '-------- Compiler Performance Summary ---------', 46);
    listln(line);
    line.length := 0;
    listln(line);
    prttab(line, 4);
    prtcats(line, 'Compiler Phase           CPU Time        Elapsed Time    Page Faults    Disk-Net I/O       Memory Pages', 103);
    listln(line);
    line.length := 0;
    listln(line);
    cpu_total.high := 0;
    cpu_total.low := 0;
    elapsed_total.high := 0;
    elapsed_total.low := 0;
    faults_total := 0;
    disk_io_total := faults_total;
    net_io_total := faults_total;
    dynamic_max := faults_total;
    for i := 0 to 43 do
      with phases[i] do
        if not never then begin
          prtcats(line, phase_names[i], 22);
          if i <> 6 then begin
            prttab(line, 29);
            hhmmss(line, cpu);
            cal_$add_clock(cpu_total, cpu);
            prttab(line, 45);
            hhmmss(line, elapsed);
            cal_$add_clock(elapsed_total, elapsed);
            prttab(line, 61);
            prtint(line, faults, 8, false);
            faults_total := faults_total + faults;
            prttab(line, 76);
            prtint(line, disk_io, 8, false);
            prtcatc(line, '/');
            prtint(line, net_io, 8, false);
            disk_io_total := disk_io_total + disk_io;
            net_io_total := net_io_total + net_io;
            prttab(line, 95);
            prtint(line, (dynamic + 500) div 1000, 5, false);
            if dynamic > dynamic_max then
              dynamic_max := dynamic;
          end;
          listln(line);
          line.length := 0;
        end;
    prttab(line, 29);
    prtcats(line, '-------------------------------------------------------------------------', 73);
    listln(line);
    line.length := 0;
    prtcats(line, 'TOTALS', 6);
    prttab(line, 29);
    hhmmss(line, cpu_total);
    prttab(line, 45);
    hhmmss(line, elapsed_total);
    prttab(line, 61);
    prtint(line, faults_total, 8, false);
    prttab(line, 76);
    prtint(line, disk_io_total, 8, false);
    prtcatc(line, '/');
    prtint(line, net_io_total, 8, false);
    prttab(line, 95);
    prtint(line, (dynamic_max + 500) div 1000, 5, false);
    listln(line);
    line.length := 0;
    listln(line);
    listln(line);
    if not iosub_$generating_library then
      prt_section_stats;
    line.length := 0;
    prtcats(line, 'Compiler options affecting code-generation: ', 44);
    if iosub_$generating_library then
      prtcats(line, '-LIB ', 5)
    else
      with cargs_$options do begin
        if cond then
          prtcats(line, '-DEBUG ', 7);
        case opt of
          0, 1: prtcats(line, '-OPT 0 ', 7);
          3: prtcats(line, '-OPT 1 ', 7);
          5: prtcats(line, '-OPT 2 ', 7);
          6: prtcats(line, '-OPT 3 ', 7);
          9: prtcats(line, '-OPT 4 ', 7);
          otherwise ;
        end;
        if xrs then
          prtcats(line, '-XRS ', 5);
        if i_star_2 then
          prtcats(line, '-I*2 ', 5);
        l := l_star;
        if l = 8 then
          prtcats(line, '-L*1 ', 5)
        else if l = 9 then
          prtcats(line, '-L*2 ', 5);
        if save then
          prtcats(line, '-SAVE ', 6);
        case db of
          0: prtcats(line, '-NDB ', 5);
          1: prtcats(line, '-DB ', 4);
          2: prtcats(line, '-DBS ', 5);
          3: prtcats(line, '-DBA ', 5);
        end;
        if indexl then
          prtcats(line, '-INDEXL ', 8);
        if subchk then
          prtcats(line, '-SUBCHK ', 8);
        if (1 in cpu) and (3 in cpu) then
          prtcats(line, '-CPU M020 PEB ', 14)
        else if 2 in cpu then
          prtcats(line, '-CPU 660 460 160 ', 17)
        else if 9 in cpu then
          prtcats(line, '-CPU MATHLIB ', 13)
        else if 10 in cpu then
          prtcats(line, '-CPU MATHLIB_SR10 ', 18)
        else if (3 in cpu) and (4 in cpu) then begin
          prtcats(line, '-CPU MATHCHIP (5700 3000 580 570 560 330 90 FPU) ', 49);
          if 5 in cpu then
            prtcats(line, 'FPX ', 4);
        end
        else if (3 in cpu) and (8 in cpu) then
          prtcats(line, '-CPU 5700 3000 580 570 560 330 90 FPA ', 38)
        else if 4 in cpu then begin
          prtcats(line, '-CPU FPU ', 9);
          if 5 in cpu then
            prtcats(line, 'FPX ', 4);
        end
        else if 3 in cpu then
          prtcats(line, '-CPU 68020 ', 11)
        else if 7 in cpu then
          prtcats(line, '-CPU 10000TX ', 13)
        else if 1 in cpu then
          prtcats(line, '-CPU PEB ', 9);
        if 0 in flags_286 then
          prtcats(line, '-MGBL ', 6);
        if 2 in flags_286 then
          prtcats(line, '-ZERO ', 6);
        if 4 in flags_286 then
          prtcats(line, '-ALIGN ', 7);
        if 7 in flags_286 then begin
          if 8 in flags_286 then
            prtcats(line, '-AC ', 4)
          else
            prtcats(line, '-ABS ', 5);
        end
        else
          prtcats(line, '-PIC ', 5);
        if 14 in flags_286 then
          prtcats(line, '-SOME_FP ', 9);
        if 13 in flags_286 then
          prtcats(line, '-NO_FP ', 7);
        if frnd then
          prtcats(line, '-FRND ', 6);
        if 15 in flags_286 then
          prtcats(line, '-AEGIS10 ', 9);
        if uc then
          prtcats(line, '-UC ', 4);
        if u then
          prtcats(line, '-U ', 3);
        if ff then
          prtcats(line, '-FF ', 4);
        if lcinc then
          prtcats(line, '-LCINC ', 7);
        if 11 in flags_286 then
          prtcats(line, '-BSS ', 5);
        if 10 in flags_286 then
          prtcats(line, '-PROFILING ', 11);
        if 12 in flags_286 then
          prtcats(line, '-UMSG ', 6);
      end;
    listln(line);
    if cargs_$options.systype.length <> 0 then begin
      line.length := 0;
      prtcats(line, '-SYSTYPE ', 9);
      prtcats(line, cargs_$options.systype.body,
              cargs_$options.systype.length);
      listln(line);
    end;
    line.length := 0;
    listln(line);
  end;
end;
