{ error_listing - ERROR_LISTING, reporting errors: error0..error3 pass an
  error code, its line and 0 to 3 arguments to the front end's errorlst,
  first saving the error in a list when the listing is wanted with -EXP;
  print_error reports a line's saved errors again as the listing reaches
  it.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0AC634  0x0AE014  save_errors
    0x0AC728  0x0AE108  error0
    0x0AC78A  0x0AE16A  error1
    0x0AC7F2  0x0AE1D2  error2
    0x0AC862  0x0AE242  error3
    0x0AC8E0  0x0AE2C0  print_error
    A5 0x2C3168 (cc.m68k), 0x4431D8 (cc.a88k): the module's data, 0x10
    bytes (to inc_list's): +0 print_error's place in the list, +4 the
    list's last entry, +8 its first (error_listing_first), +0xC
    error_listing_0c.  Nothing is initialized.

  Every routine is global and loads A5.
}
module error_listing;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';

define
  error_listing_first,                  { +0x8 }
  error_listing_0c;                     { +0xC }

var
  cursor: error_listing_$ptr_t;         { +0x0 }
  last: error_listing_$ptr_t;           { +0x4 }

{ save_errors - append an error to the list unless it repeats the last.

  0x0AC634, 0xF4 bytes.  With no list (error_listing_first nil, `tst.l
  (8,A5)') the first entry is obtained with pas_$new (`pea 0x1a': 26
  bytes) into last, and first and cursor are set to it.  Else an error
  equal to last's in line (+20), code (+16), the three arguments, nargs
  (+18) and +22 is dropped; otherwise last^.next gets a new entry and
  last moves to it.  The entry: the arguments cleared (three `clr.l'),
  code, the arguments copied (12 bytes), nargs, line, +22, next nil,
  printed false.

  Not known from the original:
  - whether the size was written as a number or with sizeof (26: dpc
    pads the record to 28); why the arguments are cleared before they
    are copied. }

procedure save_errors(
    in line: integer;
    in code: integer;
    in args: error_listing_$args_t;
    in nargs: integer;
    in x16: integer);
begin
  if error_listing_first = nil then begin
    pas_$new(last, 26);
    error_listing_first := last;
    cursor := error_listing_first;
  end
  else begin
    if (line = last^.line) and (code = last^.code) and
       (args[1] = last^.args[1]) and (args[2] = last^.args[2]) and
       (args[3] = last^.args[3]) and (nargs = last^.nargs) and
       (x16 = last^.x16) then
      return;
    pas_$new(last^.next, 26);
    last := last^.next;
  end;
  last^.args[1] := nil;
  last^.args[2] := nil;
  last^.args[3] := nil;
  last^.code := code;
  last^.args := args;
  last^.nargs := nargs;
  last^.line := line;
  last^.x16 := x16;
  last^.next := nil;
  last^.printed := false;
end;

{ error0 - report code at line.

  0x0AC728, 0x5E bytes: unless error_listing_0c (`tst.b (12,A5); bmi'),
  only with cargs_$options.exp (+0x27A bit 1, `btst #1,0x2C3666') and
  unless cerr_quiet (`tst.b 0x1400AC'), save_errors(line, code, args,
  0, 63) (the constants at 0x0AC788 and 0x0AC786); then errorlst(code,
  line, args, 0).  args is a local array (-16) no routine sets here.

  Not known from the original:
  - the local's name; what 63 means. }

procedure error0(
    code: integer;
    line: integer);
var
  args: error_listing_$args_t;
begin
  if not error_listing_0c and cargs_$options.exp and not cerr_quiet then
    save_errors(line, code, args, 0, 63);
  errorlst(code, line, args, 0);
end;

{ error1 - report code at line with a1.

  0x0AC78A, 0x66 bytes: as error0, with a1 copied to args[1] first and
  nargs 1 (0x0AC7F0). }

procedure error1(
    code: integer;
    line: integer;
    a1: univ_ptr);
var
  args: error_listing_$args_t;
begin
  args[1] := a1;
  if not error_listing_0c and cargs_$options.exp and not cerr_quiet then
    save_errors(line, code, args, 1, 63);
  errorlst(code, line, args, 1);
end;

{ error2 - report code at line with a1 and a2.

  0x0AC7F2, 0x6E bytes: as error1 with args[2] := a2 and nargs 2
  (0x0AC860). }

procedure error2(
    code: integer;
    line: integer;
    a1: univ_ptr;
    a2: univ_ptr);
var
  args: error_listing_$args_t;
begin
  args[1] := a1;
  args[2] := a2;
  if not error_listing_0c and cargs_$options.exp and not cerr_quiet then
    save_errors(line, code, args, 2, 63);
  errorlst(code, line, args, 2);
end;

{ error3 - report code at line with a1, a2 and a3.

  0x0AC862, 0x7C bytes: as error2 with args[3] := a3 and nargs 3
  (0x0AC8DE). }

procedure error3(
    code: integer;
    line: integer;
    a1: univ_ptr;
    a2: univ_ptr;
    a3: univ_ptr);
var
  args: error_listing_$args_t;
begin
  args[1] := a1;
  args[2] := a2;
  args[3] := a3;
  if not error_listing_0c and cargs_$options.exp and not cerr_quiet then
    save_errors(line, code, args, 3, 63);
  errorlst(code, line, args, 3);
end;

{ print_error - report again the saved errors of line.

  0x0AC8E0, 0xDC bytes.  Nothing when line equals spos_$null_position (`cmp.w
  0x14E770') or there is no cursor.  From the cursor, entries of lower
  lines are passed while there is a next (a missing next leaves the
  loop); the cursor moves to the entry reached only when it is line's.
  Then while the cursor's line is line: an entry not printed (`tst.b
  (24,A0); bmi') is reported with error0..error3 by nargs (tested 0, 1,
  2, else 3), its code and line; at the last entry the routine returns,
  else the cursor moves to the next.

  Not known from the original:
  - the local's name; whether the walk was written with exit (the image
    branches from the nil test to the comparison after the loop). }

procedure print_error(
    in line: integer);
var
  p: error_listing_$ptr_t;
begin
  if (line <> spos_$null_position) and (cursor <> nil) then begin
    p := cursor;
    while p^.line < line do begin
      if p^.next = nil then
        exit;
      p := p^.next;
    end;
    if p^.line = line then
      cursor := p;
    while cursor^.line = line do begin
      if not cursor^.printed then begin
        if cursor^.nargs = 0 then
          error0(cursor^.code, line)
        else if cursor^.nargs = 1 then
          error1(cursor^.code, line, cursor^.args[1])
        else if cursor^.nargs = 2 then
          error2(cursor^.code, line, cursor^.args[1], cursor^.args[2])
        else
          error3(cursor^.code, line, cursor^.args[1], cursor^.args[2],
                 cursor^.args[3]);
      end;
      if cursor^.next = nil then
        return;
      cursor := cursor^.next;
    end;
  end;
end;
