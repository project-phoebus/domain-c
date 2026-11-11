{ spos - SPOS_, source positions.  The main source file and each
  include file read are regions (up to 3001, region 0 the main file);
  a file resumed after an include file gets a new region chained to its
  previous one (the file's root region keeps its mark).  A source
  position is a word: a line of the main file when not negative; the
  include files' lines are numbered down from 0 across all of them, so
  that a negative position names a region (the last one whose base
  position lies above it) and a line in it.  Files can be marked (the
  files of the debugging tables), the marks locked and captured for the
  next compilation's regions.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x071C70  0x073650  spos_$init_source_position
    0x071DA0  0x073780  calculate_source_position (internal)
    0x071E32  0x073812  spos_$next_line
    0x071E5A  0x07383A  spos_$enquire_next_line
    0x071E86  0x073866  spos_$skip_lines
    0x071EAE  0x07388E  spos_$start_include_file
    0x072024  0x073A04  spos_$may_start_include_file
    0x07204A  0x073A2A  spos_$resume_file
    0x072378  0x073D58  spos_$change_file
    0x07250C  0x073EEC  spos_$is_main_source_file
    0x072528  0x073F08  spos_$line_is_in_main_source_file
    0x072544  0x073F24  spos_$decode_source_position
    0x0725C4  0x073FA4  spos_$encode_source_position
    0x07278C  0x07416C  spos_$last_source_region
    0x0727A6  0x074186  spos_$region_user_name
    0x072856  0x074236  spos_$region_name_used_to_open
    0x07290E  0x0742EE  spos_$region_full_path_name
    0x0729C2  0x0743A2  spos_$region_dtm
    0x072A6C  0x07444C  spos_$region_unit_name
    0x072B1C  0x0744FC  spos_$mark_source_file
    0x072C54  0x074634  spos_$mark_main_source_file
    0x072C76  0x074656  spos_$number_of_source_files
    0x072C90  0x074670  spos_$lock_source_file_marks
    0x072CAA  0x07468A  spos_$number_of_marked_source_files
    0x072CC2  0x0746A2  spos_$apply_over_source_files
    0x072D14  0x0746F4  spos_$apply_over_marked_source_files
    0x072D68  0x074748  spos_$capture_file_marks
    0x072DBA  0x07479A  spos_$region_is_marked
    0x072E8E  0x07486E  spos_$diag_dump_source_region
    0x0730DC  0x074ABC  spos_$diag_dump_source_position
    0x073164  0x074B44  spos_$diag_dump_source_position_database
    A5 0x14B874 (cc.m68k), 0x2CB8E4 (cc.a88k): the module's data
    (spos.pvt.pas gives the layout), 120080 bytes.

  The global routines load A5; calculate_source_position, which does
  not, is internal.  Every check is an ASS_ call with the routine's name
  in its message.
}
module spos;

%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/common/source/spos.pvt.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/diag.ins.pas';
%include '/sys/ins/base.ins.pas';

define
  spos_$line,                           { +12020 }
  spos_$region,                         { +12024 }
  spos_$null_position,                  { +12028 }
  spos_$position;                       { +12030 }

var
  marks_locked: boolean := false;       { +12032 }
  db: record                            { +12036 (0x14E778) }
    next_position: spos_$position_t;    { +0: the last position given
                                          to an include file's line;
                                          they count down from 0 }
    last_region: spos_$region_t;        { +2 }
    regions: array [0..spos_max_region] of spos_region_t;
                                        { +8 in the image }
  end;

{ spos_$init_source_position - region 0 for the main source file, at
  line 0 and position 0.

  0x071C70, 0xCC bytes: user_name and name_used_to_open tested against
  nil (`cmpa.w #0'; `tst.l') with an ASS_$PRECONDITION_FAIL each;
  spos_$line := 0; the next position (`move.w #0' through A1 = 0x14E778)
  and the last region (`move.l #0' at (2,A1)) cleared; the region at
  0x14E778 + 8 + 36 * last region: position 0, line spos_$line, the
  names and dtm (unit_name from (24,A6) at +12, dtm from (20,A6) at
  +16), the mark from the captured marks (`move.w (4,A1)': the last
  region's low word as the index), root the last region, next -1; the
  include depth 0, the marks unlocked, the marked count the captured
  count, spos_$position the next position, spos_$region the last
  region, spos_$null_position 0.

  Not known from the original:
  - whether the region was reached through `with' (its address is
    computed once). }

procedure spos_$init_source_position(
    user_name: univ_ptr;
    name_used_to_open: univ_ptr;
    full_path_name: univ_ptr;
    dtm: integer32;
    unit_name: univ_ptr);
begin
  if user_name = nil then
    ass_$precondition_fail('SPOS_$INIT_SOURCE_POSITION -- NIL user_name%$');
  if name_used_to_open = nil then
    ass_$precondition_fail(
      'SPOS_$INIT_SOURCE_POSITION -- NIL name_used_to_open%$');
  spos_$line := 0;
  db.next_position := 0;
  db.last_region := 0;
  db.regions[db.last_region].position := 0;
  db.regions[db.last_region].line := spos_$line;
  db.regions[db.last_region].user_name := user_name;
  db.regions[db.last_region].name_used_to_open := name_used_to_open;
  db.regions[db.last_region].full_path_name := full_path_name;
  db.regions[db.last_region].unit_name := unit_name;
  db.regions[db.last_region].dtm := dtm;
  db.regions[db.last_region].mark := captured_marks[db.last_region];
  db.regions[db.last_region].root := db.last_region;
  db.regions[db.last_region].next := -1;
  include_depth := 0;
  marks_locked := false;
  marked_count := captured_count;
  spos_$position := db.next_position;
  spos_$region := db.last_region;
  spos_$null_position := 0;
end;

{ calculate_source_position - the line and position n lines on from
  the current one; when advance, they become the current ones.

  0x071DA0, 0x92 bytes, internal: n at (8,A6), advance a byte at
  (12,A6), line and position by address (14,A6), (18,A6).  The line:
  `move.l #32767; sub.l n; cmp.l spos_$line; bge' (32767 - n <
  spos_$line, signed) gives 32767, else spos_$line + n.  Region 0
  (`tst.l' spos_$region): the position is the line's low word (`move.w
  (2,A1)'); an include file: the next position (0x14E778, extended)
  `cmp.l' with n - 32767, below it -32767 (0x8001), else the next
  position less n (`sub.w').  advance (`tst.b; bpl') stores the
  position in spos_$position (and in the next position for an include
  file) and the line in spos_$line.

  Not known from the original:
  - the parameters' names; what the 4-byte frame slot (`link #-4') was
    for: the routine uses none. }

procedure calculate_source_position(
    n: integer32;
    advance: boolean;
    out line: spos_$line_t;
    out position: spos_$position_t); options(val_param); internal;
begin
  if 32767 - n < spos_$line then
    line := 32767
  else
    line := spos_$line + n;
  if spos_$region = 0 then begin
    position := line;
    if advance then begin
      spos_$position := position;
      spos_$line := line;
    end;
  end
  else begin
    if db.next_position < n - 32767 then
      position := -32767
    else
      position := db.next_position - n;
    if advance then begin
      db.next_position := position;
      spos_$position := db.next_position;
      spos_$line := line;
    end;
  end;
end;

{ spos_$next_line - one line on.

  0x071E32, 0x28 bytes: calculate_source_position(1, true, line,
  position) with the locals at -4 and -6 (`subq.l #2,SP' first: the
  arguments padded to 16 bytes). }

procedure spos_$next_line;
var
  line: spos_$line_t;
  position: spos_$position_t;
begin
  calculate_source_position(1, true, line, position);
end;

{ spos_$enquire_next_line - the next line's position, not moving.

  0x071E5A, 0x2C bytes: calculate_source_position(1, false, ...)
  (`clr.w'), the result the word at -6. }

function spos_$enquire_next_line: spos_$position_t;
var
  line: spos_$line_t;
  position: spos_$position_t;
begin
  calculate_source_position(1, false, line, position);
  spos_$enquire_next_line := position;
end;

{ spos_$skip_lines - n lines on.

  0x071E86, 0x28 bytes: calculate_source_position(n, true, ...). }

procedure spos_$skip_lines(
    n: integer32);
var
  line: spos_$line_t;
  position: spos_$position_t;
begin
  calculate_source_position(n, true, line, position);
end;

{ spos_$start_include_file - a new region for an include file, at line
  0 and the next position.

  0x071EAE, 0xE2 bytes: the nil tests of user_name and name_used_to_open
  and SPOS_$MAY_START_INCLUDE_FILE (`bsr', `tst.b; bmi') with an
  ASS_$PRECONDITION_FAIL each; in the main file (`tst.l' spos_$region)
  spos_$line is kept in region 0's line (0x14E794); the include depth,
  the last region (0x14E77A) and the include files opened go up by one;
  spos_$line := 0, spos_$position := the next position, spos_$region :=
  the last region; that region's fields as SPOS_$INIT_SOURCE_POSITION's
  (the mark indexed by spos_$region, `move.l (0,A5,D1.l)').

  Not known from the original:
  - whether the region was reached through `with' (its address is
    computed once). }

procedure spos_$start_include_file(
    user_name: univ_ptr;
    name_used_to_open: univ_ptr;
    full_path_name: univ_ptr;
    dtm: integer32;
    unit_name: univ_ptr);
begin
  if user_name = nil then
    ass_$precondition_fail('SPOS_$START_INCLUDE_FILE -- NIL user_name%$');
  if name_used_to_open = nil then
    ass_$precondition_fail(
      'SPOS_$START_INCLUDE_FILE -- NIL name_used_to_open%$');
  if not spos_$may_start_include_file then
    ass_$precondition_fail(
      'SPOS_$START_INCLUDE_FILE -- too many include files%$');
  if spos_$region = 0 then
    db.regions[0].line := spos_$line;
  include_depth := include_depth + 1;
  db.last_region := db.last_region + 1;
  include_files := include_files + 1;
  spos_$line := 0;
  spos_$position := db.next_position;
  spos_$region := db.last_region;
  db.regions[spos_$region].position := spos_$position;
  db.regions[spos_$region].line := spos_$line;
  db.regions[spos_$region].user_name := user_name;
  db.regions[spos_$region].name_used_to_open := name_used_to_open;
  db.regions[spos_$region].full_path_name := full_path_name;
  db.regions[spos_$region].unit_name := unit_name;
  db.regions[spos_$region].dtm := dtm;
  db.regions[spos_$region].mark := captured_marks[spos_$region];
  db.regions[spos_$region].root := spos_$region;
  db.regions[spos_$region].next := -1;
end;

{ spos_$may_start_include_file - whether a region is left for another
  include file (and the resumptions of the files open).

  0x072024, 0x26 bytes: `move.l #2999; sub.l' the include depth; `cmp.l'
  with the last region; `sgt'. }

function spos_$may_start_include_file: boolean;
begin
  spos_$may_start_include_file := 2999 - include_depth > db.last_region;
end;

{ spos_$resume_file - back in the file of region after an include file
  ends.  In the main file, at the line kept when the include began;
  in an include file, a new region of it (the next of region) at the
  line after the include and the next position.

  0x07204A, 0x164 bytes: region `cmp.l' with the last region, `bcs'
  (region < last region) and the include depth not 0, each else an
  ASS_$PRECONDITION_FAIL with region and the last region (by address);
  the depth goes down (`subq.l #1').  Region 0 (`tst.l'): the depth must
  be 0 (ASS_$PRECONDITION_FAIL with it); spos_$line := region 0's line,
  spos_$position := it or 32767 when above (`cmpi.l #32767; bls');
  spos_$region := 0.  Otherwise ASS_$INVARIANT_FAIL unless the last
  region is below 3000 (`cmpi.l #3000; bcs'), ASS_$PRECONDITION_FAIL
  when the depth is 0; the last region up by one; spos_$line := region's
  position less the next region's (+78: region + 1's, both extended)
  plus region's line; spos_$position := region + 1's position; the new
  region: position the next position, line spos_$line, the names and
  dtm copied from region (+8..+24), the mark from the captured marks,
  region's root, next -1; region's next := the last region (`move.w
  (4,A2)'); spos_$region := the last region.

  Not known from the original:
  - the spelling `resumming' is the image's. }

procedure spos_$resume_file(
    region: spos_$region_t);
begin
  if region >= db.last_region then
    ass_$precondition_fail(
      'SPOS_$RESUME_FILE -- file region being resummed (%lsd) is not less than current region (%lsd)%$',
      region, db.last_region);
  if include_depth = 0 then
    ass_$precondition_fail(
      'SPOS_$RESUME_FILE -- no include files currently active (file region being resummed %lsd, current region %lsd)%$',
      region, db.last_region);
  include_depth := include_depth - 1;
  if region = 0 then begin
    if include_depth <> 0 then
      ass_$precondition_fail(
        'SPOS_$RESUME_FILE -- resumming main source region when still %lsd include files active%$',
        include_depth);
    spos_$line := db.regions[0].line;
    if spos_$line > 32767 then
      spos_$position := 32767
    else
      spos_$position := spos_$line;
    spos_$region := 0;
  end
  else begin
    if db.last_region >= spos_max_region then
      ass_$invariant_fail(
        'SPOS_$RESUME_FILE -- no more source regions to record resumming of include file%$');
    if include_depth = 0 then
      ass_$precondition_fail(
        'SPOS_$RESUME_FILE -- resumming an include file when no include files active%$');
    db.last_region := db.last_region + 1;
    spos_$line := db.regions[region].position -
                  db.regions[region + 1].position +
                  db.regions[region].line;
    spos_$position := db.regions[region + 1].position;
    with db.regions[db.last_region] do begin
      position := db.next_position;
      line := spos_$line;
      user_name := db.regions[region].user_name;
      name_used_to_open := db.regions[region].name_used_to_open;
      full_path_name := db.regions[region].full_path_name;
      unit_name := db.regions[region].unit_name;
      dtm := db.regions[region].dtm;
      mark := captured_marks[db.last_region];
      root := db.regions[region].root;
      next := -1;
    end;
    db.regions[region].next := db.last_region;
    spos_$region := db.last_region;
  end;
end;

{ spos_$change_file - a #line: from line on, the current file's lines
  are numbered as line's; with names, region 0 takes them.

  0x072378, 0xAE bytes: (user_name = nil) `seq' compared with
  (name_used_to_open = nil) `seq' (`cmp.b; beq'); user_name nil with
  unit_name not (`tst.l'); line 0 (`tst.l; bne': the type unsigned)
  with line by address: an ASS_$PRECONDITION_FAIL each.  With user_name
  (`cmpa.w #0; beq'), region 0 (0x14E778 + 8..+24, not the current
  region) takes the names and dtm.  spos_$line := line - 1 (`subq.l
  #1'), spos_$position := it or 32767 when above (`bls').

  Not known from the original:
  - how the line test was written (`line <= 0' of a non-negative type
    tests 0). }

procedure spos_$change_file(
    user_name: univ_ptr;
    name_used_to_open: univ_ptr;
    full_path_name: univ_ptr;
    dtm: integer32;
    unit_name: univ_ptr;
    line: spos_$line_t);
begin
  if (user_name = nil) <> (name_used_to_open = nil) then
    ass_$precondition_fail(
      'SPOS_$CHANGE_FILE -- user_name and name_used_to_open must either both be NIL or both non-NIL%$');
  if (user_name = nil) and (unit_name <> nil) then
    ass_$precondition_fail(
      'SPOS_$CHANGE_FILE -- unit_name cannot be specified if user_name not specified%$');
  if line = 0 then
    ass_$precondition_fail(
      'SPOS_$CHANGE_FILE -- non-positive line number (%lsd)%$', line);
  if user_name <> nil then begin
    db.regions[0].user_name := user_name;
    db.regions[0].name_used_to_open := name_used_to_open;
    db.regions[0].full_path_name := full_path_name;
    db.regions[0].unit_name := unit_name;
    db.regions[0].dtm := dtm;
  end;
  spos_$line := line - 1;
  if spos_$line > 32767 then
    spos_$position := 32767
  else
    spos_$position := spos_$line;
end;

{ spos_$is_main_source_file - region = 0.

  0x07250C, 0x1C bytes: `tst.l (8,A6)' (`move.l'), `seq'. }

function spos_$is_main_source_file(
    region: integer32): boolean;
begin
  spos_$is_main_source_file := region = 0;
end;

{ spos_$line_is_in_main_source_file - position >= 0.

  0x072528, 0x1C bytes: `move.w (8,A6)', `sge'. }

function spos_$line_is_in_main_source_file(
    position: spos_$position_t): boolean;
begin
  spos_$line_is_in_main_source_file := position >= 0;
end;

{ spos_$decode_source_position - the region and line of a position.

  0x072544, 0x80 bytes: position (a word) `bmi'; not negative: region
  0, line the position extended.  Negative: from the last region down
  while above 1 (`cmpi.l #1; bhi', the test at the loop's foot), the
  loop left at the first region whose position lies above the given one
  (`cmp.w (42,A0,D0.l),D1; blt'); line := the region's position less
  the given one (extended, kept at -8) plus the region's line.

  Not known from the original:
  - the local's name; whether the loop was a `while' with `exit'. }

procedure spos_$decode_source_position(
    position: spos_$position_t;
    out region: integer32;
    out line: integer32);
var
  r: spos_$region_t;
begin
  if position >= 0 then begin
    region := 0;
    line := position;
  end
  else begin
    r := db.last_region;
    while r > 1 do begin
      if position < db.regions[r].position then
        exit;
      r := r - 1;
    end;
    region := r;
    line := db.regions[r].position - position + db.regions[r].line;
  end;
end;

{ spos_$encode_source_position - the position of a line of the file
  whose root region is region: the region of the file that holds the
  line, the line kept within the file's lines read.

  0x0725C4, 0x116 bytes: region above the last region (`bls') and
  region not its own root (+36) fail with ASS_$PRECONDITION_FAIL.
  Region 0: the last line, spos_$line in the main file or region 0's
  line (0x14E794); line above it (`bhi') gives the last line, else line
  (D0 already holds the last line).  Otherwise along the file's next
  regions (+40, -1 ends) while line is above the next one's line (`bls'
  leaves); the region's last line its line plus its position less the
  next region's (+78), or the next position for the last region; the
  line kept to the last line (`bhi') and above the region's line (else
  that line + 1); the position: the region's position less the line's
  distance from the region's line (`sub.w').

  Not known from the original:
  - the locals; the loop's form (`and then' for the test of next
    before its use). }

function spos_$encode_source_position(
    region: spos_$region_t;
    line: spos_$line_t): spos_$position_t;
var
  r: spos_$region_t;
  last_line: spos_$line_t;
  l: spos_$line_t;
  next_position: spos_$position_t;
begin
  if region > db.last_region then
    ass_$precondition_fail(
      'SPOS_$ENCODE_SOURCE_POSITION -- root region supplied (%lsd) is not less than current region (%lsd)%$',
      region, db.last_region);
  if db.regions[region].root <> region then
    ass_$precondition_fail(
      'SPOS_$ENCODE_SOURCE_POSITION -- region supplied (%lsd) is not a root region%$',
      region);
  if region = 0 then begin
    if spos_$region = 0 then
      last_line := spos_$line
    else
      last_line := db.regions[0].line;
    if line > last_line then
      spos_$encode_source_position := last_line
    else
      spos_$encode_source_position := line;
  end
  else begin
    r := region;
    while (db.regions[r].next <> -1) and then
          (line > db.regions[db.regions[r].next].line) do
      r := db.regions[r].next;
    if r = db.last_region then
      next_position := db.next_position
    else
      next_position := db.regions[r + 1].position;
    last_line := db.regions[r].position - next_position +
                 db.regions[r].line;
    if line > last_line then
      l := last_line
    else if line > db.regions[r].line then
      l := line
    else
      l := db.regions[r].line + 1;
    spos_$encode_source_position :=
      db.regions[r].position - (l - db.regions[r].line);
  end;
end;

{ spos_$last_source_region - 0x07278C, 0x1A bytes: the longword at
  0x14E77A. }

function spos_$last_source_region: integer32;
begin
  spos_$last_source_region := db.last_region;
end;

{ spos_$region_user_name - the region's user name.

  0x0727A6, 0x4E bytes: region above the last region (`bls') fails
  with ASS_$PRECONDITION_FAIL (region and the last region by address);
  the longword at +8 in A0.  The four routines after it are the same
  but for the field and the name in the message. }

function spos_$region_user_name(
    region: spos_$region_t): univ_ptr;
begin
  if region > db.last_region then
    ass_$precondition_fail(
      'SPOS_$REGION_USER_NAME -- requested region (%lsd) is greater that current maximum region (%lsd)%$',
      region, db.last_region);
  spos_$region_user_name := db.regions[region].user_name;
end;

{ spos_$region_name_used_to_open - 0x072856, 0x4E bytes: +12. }

function spos_$region_name_used_to_open(
    region: spos_$region_t): univ_ptr;
begin
  if region > db.last_region then
    ass_$precondition_fail(
      'SPOS_$REGION_NAME_USED_TO_OPEN -- requested region (%lsd) is greater that current maximum region (%lsd)%$',
      region, db.last_region);
  spos_$region_name_used_to_open := db.regions[region].name_used_to_open;
end;

{ spos_$region_full_path_name - 0x07290E, 0x4E bytes: +16. }

function spos_$region_full_path_name(
    region: spos_$region_t): univ_ptr;
begin
  if region > db.last_region then
    ass_$precondition_fail(
      'SPOS_$REGION_FULL_PATH_NAME -- requested region (%lsd) is greater that current maximum region (%lsd)%$',
      region, db.last_region);
  spos_$region_full_path_name := db.regions[region].full_path_name;
end;

{ spos_$region_dtm - 0x0729C2, 0x4E bytes: +24, in D0. }

function spos_$region_dtm(
    region: spos_$region_t): integer32;
begin
  if region > db.last_region then
    ass_$precondition_fail(
      'SPOS_$REGION_DTM -- requested region (%lsd) is greater that current maximum region (%lsd)%$',
      region, db.last_region);
  spos_$region_dtm := db.regions[region].dtm;
end;

{ spos_$region_unit_name - 0x072A6C, 0x4E bytes: +20. }

function spos_$region_unit_name(
    region: spos_$region_t): univ_ptr;
begin
  if region > db.last_region then
    ass_$precondition_fail(
      'SPOS_$REGION_UNIT_NAME -- requested region (%lsd) is greater that current maximum region (%lsd)%$',
      region, db.last_region);
  spos_$region_unit_name := db.regions[region].unit_name;
end;

{ spos_$mark_source_file - the file of region marked, numbered in
  order; mark its number.

  0x072B1C, 0x86 bytes: the range test as SPOS_$REGION_USER_NAME's; A3
  := the root region (+36 of region); an unmarked one (`tst.l (32,A3)')
  fails when the marks are locked (`tst.b; bpl'), else the marked count
  goes up and is its mark; mark := the root's mark.

  Not known from the original:
  - the local (the image keeps the root's address in A3). }

procedure spos_$mark_source_file(
    region: spos_$region_t;
    out mark: integer32);
var
  root: spos_$region_t;
begin
  if region > db.last_region then
    ass_$precondition_fail(
      'SPOS_$MARK_SOURCE_FILE -- requested region (%lsd) is greater that current maximum region (%lsd)%$',
      region, db.last_region);
  root := db.regions[region].root;
  if db.regions[root].mark = 0 then begin
    if marks_locked then
      ass_$precondition_fail(
        'SPOS_$MARK_SOURCE_FILE -- requested unmarked file when marks have been locked%$');
    marked_count := marked_count + 1;
    db.regions[root].mark := marked_count;
  end;
  mark := db.regions[root].mark;
end;

{ spos_$mark_main_source_file - SPOS_$MARK_SOURCE_FILE(0, m); m.

  0x072C54, 0x22 bytes: m the longword at -4. }

function spos_$mark_main_source_file: integer32;
var
  m: integer32;
begin
  spos_$mark_source_file(0, m);
  spos_$mark_main_source_file := m;
end;

{ spos_$number_of_source_files - the include files opened + 1.

  0x072C76, 0x1A bytes. }

function spos_$number_of_source_files: integer32;
begin
  spos_$number_of_source_files := include_files + 1;
end;

{ spos_$lock_source_file_marks - 0x072C90, 0x1A bytes: `move.b #-1'
  to +12032. }

procedure spos_$lock_source_file_marks;
begin
  marks_locked := true;
end;

{ spos_$number_of_marked_source_files - 0x072CAA, 0x18 bytes. }

function spos_$number_of_marked_source_files: integer32;
begin
  spos_$number_of_marked_source_files := marked_count;
end;

{ spos_$apply_over_source_files - proc of each root region, from 0.

  0x072CC2, 0x52 bytes: D2 from 0; each pass `cmp.l (36,A0),D2'
  (the region its own root) then `jsr (A1)' with D2 pushed; then `cmp.l
  (2,A2),D2; beq' (the last region, read again each pass: not a `for')
  and `addq.l #1'.

  Not known from the original:
  - the local's name; the loop's form. }

procedure spos_$apply_over_source_files(
    proc: spos_$region_proc_t);
var
  r: spos_$region_t;
begin
  r := 0;
  repeat
    if db.regions[r].root = r then
      proc^(r);
    if r = db.last_region then
      exit;
    r := r + 1;
  until false;
end;

{ spos_$apply_over_marked_source_files - proc of each marked root
  region, with its mark.

  0x072D14, 0x54 bytes: as SPOS_$APPLY_OVER_SOURCE_FILES, the call
  also when the mark is not 0 (`tst.l (32,A3)'), pushing the mark, then
  the region. }

procedure spos_$apply_over_marked_source_files(
    proc: spos_$marked_region_proc_t);
var
  r: spos_$region_t;
begin
  r := 0;
  repeat
    if (db.regions[r].root = r) and (db.regions[r].mark <> 0) then
      proc^(r, db.regions[r].mark);
    if r = db.last_region then
      exit;
    r := r + 1;
  until false;
end;

{ spos_$capture_file_marks - each root region's mark kept for the next
  SPOS_$INIT_SOURCE_POSITION's regions, and the marked count.

  0x072D68, 0x52 bytes: the loop of SPOS_$APPLY_OVER_SOURCE_FILES (D1),
  `move.l (32,A0),(0,A5,D0.l)'; then +12012 to +12004. }

procedure spos_$capture_file_marks;
var
  r: spos_$region_t;
begin
  r := 0;
  repeat
    if db.regions[r].root = r then
      captured_marks[r] := db.regions[r].mark;
    if r = db.last_region then
      exit;
    r := r + 1;
  until false;
  captured_count := marked_count;
end;

{ spos_$region_is_marked - whether the file of region is marked.

  0x072DBA, 0x72 bytes: the range test; the root's mark `tst.l; bne'
  (`st', else `clr.b'). }

function spos_$region_is_marked(
    region: spos_$region_t): boolean;
begin
  if region > db.last_region then
    ass_$precondition_fail(
      'SPOS_$REGION_IS_MARKED -- requested region (%lsd) is greater that current maximum region (%lsd)%$',
      region, db.last_region);
  spos_$region_is_marked := db.regions[db.regions[region].root].mark <> 0;
end;

{ spos_$diag_dump_source_region - the region to the diagnostic output;
  full adds its number, positions, user name, mark, root and next.

  0x072E8E, 0x14C bytes: DIAG_$ASSURE_FRESH_LINE; a region above the
  last region writes `Region: %lsd (out of range)' and goes on (A2 :=
  the region all the same); else, when full, `Region: %lsd'.  When full:
  DIAG_$INDENT(4) (the old length at -2), the position (extended to a
  longword at -12), the line, the user name (TOKEN_$DIAG_DUMP_CHAR_STRING
  with `clr.w': not bracketed).  Always the name used to open (+12) and
  the unit name (+20).  When full: the mark, the root, the next
  (extended at -12), DIAG_$DROP_PREFIX.

  Not known from the original:
  - the locals' names; the `with'. }

procedure spos_$diag_dump_source_region(
    region: spos_$region_t;
    full: boolean);
var
  old_length: integer;
  v: integer32;
begin
  diag_$assure_fresh_line;
  if region > db.last_region then
    diag_$write('Region: %lsd (out of range)%$', region)
  else if full then
    diag_$write('Region: %lsd%$', region);
  with db.regions[region] do begin
    if full then begin
      diag_$assure_fresh_line;
      diag_$indent(4, old_length);
      v := position;
      diag_$writeln('Base Source Position: %lsd%$', v);
      diag_$writeln('Base Line Number: %lsd%$', line);
      diag_$write('User Supplied File Name: %$');
      token_$diag_dump_char_string(user_name, false);
    end;
    diag_$assure_fresh_line;
    diag_$write('File Name Used to Open: %$');
    token_$diag_dump_char_string(name_used_to_open, false);
    diag_$assure_fresh_line;
    diag_$write('Compilation Unit Name: %$');
    token_$diag_dump_char_string(unit_name, false);
    if full then begin
      diag_$assure_fresh_line;
      diag_$writeln('Mark: %lsd%$', mark);
      diag_$writeln('Root Region for this file: %lsd%$', root);
      v := next;
      diag_$writeln('Next Region for this file: %lsd%$', v);
      diag_$drop_prefix(old_length);
    end;
  end;
end;

{ spos_$diag_dump_source_position - the position's region and line to
  the diagnostic output (the image's `Undefine' for position 0).

  0x0730DC, 0x62 bytes: position (a word) `bne'; 0 writes `Undefine
  Source Position'; else SPOS_$DECODE_SOURCE_POSITION into -8 (region)
  and -4 (line), SPOS_$DIAG_DUMP_SOURCE_REGION(region, full),
  DIAG_$ASSURE_FRESH_LINE, `Line: %lsd'.

  Not known from the original:
  - the locals' names. }

procedure spos_$diag_dump_source_position(
    position: spos_$position_t;
    full: boolean);
var
  region: integer32;
  line: integer32;
begin
  if position = 0 then
    diag_$write('Undefine Source Position%$')
  else begin
    spos_$decode_source_position(position, region, line);
    spos_$diag_dump_source_region(region, full);
    diag_$assure_fresh_line;
    diag_$writeln('Line: %lsd%$', line);
  end;
end;

{ spos_$diag_dump_source_position_database - the current position,
  region and line; full adds the next position and every region.

  0x073164, 0xAE bytes: spos_$position extended at -16 with spos_$region
  and spos_$line (by address); when full (`tst.b; bpl'): the heading,
  DIAG_$INDENT(4) (old length at -6), the next position (0x14E778,
  extended), a `for' over the regions 0 to the last region (`dbf' and
  the borrow from the high word, docs/rev889-patterns.md 17) of
  SPOS_$DIAG_DUMP_SOURCE_REGION(r, full), DIAG_$DROP_PREFIX.

  Not known from the original:
  - the locals' names. }

procedure spos_$diag_dump_source_position_database(
    full: boolean);
var
  v: integer32;
  old_length: integer;
  r: spos_$region_t;
begin
  diag_$assure_fresh_line;
  v := spos_$position;
  diag_$writeln(
    'Current Source Position: position=%lsd, region=%lsd, line=%lsd%$',
    v, spos_$region, spos_$line);
  if full then begin
    diag_$writeln('Source Position Database:%$');
    diag_$indent(4, old_length);
    v := db.next_position;
    diag_$writeln('base: %lsd%$', v);
    for r := 0 to db.last_region do
      spos_$diag_dump_source_region(r, full);
    diag_$drop_prefix(old_length);
  end;
end;
