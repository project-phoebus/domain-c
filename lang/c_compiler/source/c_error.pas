{ c_error - the C front end's diagnostics: the code generator's errors
  mapped to the C compiler's numbers (cgerr, cgerr_no_source), the
  listing and terminal form of every diagnostic error_listing reports
  (errorlst: the header, the message text with its arguments filled
  in, folded at 88 columns), the counts of errors, warnings and
  informational messages, and the end of the run on a fatal error.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0491EC  0x04946C  cgerr_no_source
    0x049212  0x049492  print_line_number
    0x04929C  0x04951C  error_hdr
    0x049508  0x049788  error_not_printed
    0x0495EC  0x04986C  errorlst
    0x049A00  0x049C80  cgerr
    0x049AC0  0x049D40  error_text
    0x049B2C  0x049DAC  warning_text
    A5 0x1400AC (cc.m68k), 0x2C00AC (cc.a88k): the module's data, 4
    bytes: cerr_quiet (+0x0, c_globals.ins.pas) and suppress_rest
    (+0x2).

  The diagnostics' tables and texts are c_data.asm's (c_globals.ins.pas);
  the counts and the current line's text are c_lex_pp's.
  print_line_number and error_hdr do not load A5 (internal, on their
  caller's A5); error_not_printed is nested in errorlst; the others are
  global and load A5.
}
module c_error;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pgm.ins.pas';

define
  cerr_quiet;                           { +0x0 (c_globals.ins.pas) }

type
  { What a '&n' in a message text reads of its argument: a line (a
    source position) at +10. }
  cerr_lined_ptr_t = ^cerr_lined_t;
  cerr_lined_t = record
    unused_0: array [0..4] of integer;  { +0 }
    line: integer;                      { +10 }
  end;

var
  { Set by diagnostics 48, 49, 51 and 95; errorlst then lists nothing
    else. }
  suppress_rest: boolean;               { +0x2 }

{ cgerr_no_source - cgerr with no source line.

  0x0491EC, 0x26 bytes: cgerr(code, spos_$null_position, arg) (the
  word at 0x14E770). }

procedure cgerr_no_source(
    code: integer;
    arg: integer32);
begin
  cgerr(code, spos_$null_position, univ_ptr(arg));
end;

{ print_line_number - pos's line number (5 columns) to buf, and the
  file's name when it is not the main source file or -UMSG is on.

  0x049212, 0x84 bytes: spos_$decode_source_position(pos, region,
  line) (frame longwords at -12 and -8); prtint(buf, line, 5, false);
  when spos_$is_main_source_file(region) is false, or it is true and
  the byte at 0x2C3673 (cargs +0x287.7, element 12 of flags_286,
  -UMSG) is set (`tst.b; bpl'), ' of ' (0x049298) and the region's
  user name (prtobj).

  Not known from the original:
  - the parameters' and locals' names; how the -UMSG test was written
    (`tst.b' on the set's byte). }

procedure print_line_number(
    pos: integer;
    in out buf: prtsub_$line_t); options(val_param); internal;
var
  region: integer32;
  line: integer32;
begin
  spos_$decode_source_position(pos, region, line);
  prtint(buf, line, 5, false);
  if not spos_$is_main_source_file(region) or
     (12 in cargs_$options.flags_286) then begin
    prtcats(buf, ' of ', 4);
    prtobj(buf, spos_$region_user_name(region));
  end;
end;

{ error_hdr - the header of a diagnostic in buf.

  0x04929C, 0x210 bytes.  First, once a line (lex_hdr_written) and when
  diagnostics are typed (lex_type_errors; `not.b', `and.b') and -ES is
  off (cargs +0x285 & 3): while fewer than 12 errors and warnings have
  been counted (unsigned longwords), a blank line ('  ', 0x0494AC) is
  typed (unless cerr_quiet); then, when with_text, the current line's
  text (at most 256 characters, `cmp.w (A2),D1; bcc') is copied to buf
  and typed.  Then buf is emptied and gets '******** Line ' (14
  characters, 0x0494EA), the line number (print_line_number) and ': '
  (two prtcatc), or '******** ' (9, 0x0494E0) when line is
  spos_$null_position; then, for a warning, '[Warning #' or 'Warning: '
  (code <> 0 or not), for information '[Information #' or
  'Information: ', else '[Error #' or 'Error: ', the matching count
  (lex_warnings, lex_infos, lex_errors) growing unless error_listing_0c
  or cerr_quiet is set; then, for a code, the code in 3 zero-filled
  digits and '] '.

  Not known from the original:
  - the parameters' and the index's names. }

procedure error_hdr(
    line: integer;
    warning: boolean;
    info: boolean;
    with_text: boolean;
    in out buf: prtsub_$line_t;
    code: integer); options(val_param); internal;
var
  i: integer;
begin
  if not lex_hdr_written and lex_type_errors then
    if cargs_$options.es = 0 then begin
      if lex_errors + lex_warnings < 12 then begin
        buf.length := 0;
        prtcats(buf, '  ', 2);
        if not cerr_quiet then
          typeln(buf);
      end;
      lex_hdr_written := true;
      if with_text then begin
        buf.length := lex_text.length;
        if buf.length > 256 then
          buf.length := 256;
        for i := 1 to buf.length do
          buf.body[i] := lex_text.body[i];
        if not cerr_quiet then
          typeln(buf);
      end;
    end;
  buf.length := 0;
  if line <> spos_$null_position then begin
    prtcats(buf, '******** Line ', 14);
    print_line_number(line, buf);
    prtcatc(buf, ':');
    prtcatc(buf, ' ');
  end
  else
    prtcats(buf, '******** ', 9);
  if warning then begin
    if code <> 0 then
      prtcats(buf, '[Warning #', 10)
    else
      prtcats(buf, 'Warning: ', 9);
    if not error_listing_0c and not cerr_quiet then
      lex_warnings := lex_warnings + 1;
  end
  else if info then begin
    if code <> 0 then
      prtcats(buf, '[Information #', 14)
    else
      prtcats(buf, 'Information: ', 13);
    if not error_listing_0c and not cerr_quiet then
      lex_infos := lex_infos + 1;
  end
  else begin
    if code <> 0 then
      prtcats(buf, '[Error #', 8)
    else
      prtcats(buf, 'Error: ', 7);
    if not error_listing_0c and not cerr_quiet then
      lex_errors := lex_errors + 1;
  end;
  if code <> 0 then begin
    prtint(buf, code, 3, true);
    prtcats(buf, '] ', 2);
  end;
end;

{ errorlst - list (and type) a diagnostic.

  0x0495EC, 0x410 bytes.  Locals: the output line at (-528,A6), the
  word being built at (-264,A6), relisted at (-540,A6).
  - An argument that is il_178 (the identifier '----', an error already
    reported) drops the diagnostic (a counted loop over nargs, `cmpa.l
    (A1),A3').
  - After a fatal one (lex_fatal) nothing more is listed
    (lex_fatal_suppressed := true).
  - Codes 51, 48, 49, 95 (a `cmpi.w' chain, in that order) set
    suppress_rest; otherwise suppress_rest drops the diagnostic.
  - The severity (cerr_messages, `-2(A1,D0.w)' with D0 = code * 4): a
    case (jump table at 0x049680): 0 a warning, 3..6 information of
    level severity - 2, else (1 fatal, 2 an error) neither.  A warning
    with warnings off (cargs +0x27D.6), or information above the
    -INFO level (cargs +0x27E's bits 17..15, `andi.l #0x38000; lsr'),
    is only counted (unless error_listing_0c or cerr_quiet).
    Severity 1 sets lex_fatal (and clears lex_fatal_suppressed).
  - The current line's text is written once (write_ln(1, ...),
    0x04973A) when -ES is off; then the header (error_hdr(line,
    warning, info, true, buf, code)); with -ES on, nothing else.
  - The text from cerr_messages[code].text_at, a character a pass
    until '.': '.' (appended to the word) and ' ' end a word, which
    goes to buf after a blank; before that, when buf and the word
    together pass 88 characters (unsigned longwords), buf is listed
    (unless error_listing_0c is set and error_not_printed is false)
    and typed (lex_type_errors, not cerr_quiet) and restarted with 8
    blanks.  '_' appends a blank, '@' a digit the argument (prtobj;
    '???' past nargs), '@L' '[', '@R' ']' (a jump table over '0'..'R'
    at 0x0498C8), another '@x' x; '&' and a digit n print the line of
    argument n (print_line_number of its word at +10; the character
    tested at the loop's end is still the '&').  Others are appended.
  - The last part of the line is listed when error_listing_0c is off,
    or error_not_printed is true, or relisted was set; then typed.

  Not known from the original:
  - the parameters' and locals' names; whether the drops were written
    with return (as here) or goto; the cases' exact form (a case
    statement or an if chain for the codes 51, 48, 49, 95). }

procedure errorlst(
    in code: integer;
    in line: integer;
    in args: cerr_args_t;
    in nargs: integer);
var
  buf: prtsub_$line_t;
  word: prtsub_$line_t;
  relisted: boolean;
  warning: boolean;
  info: boolean;
  level: integer;
  i: integer;
  at: integer;
  c: char;
  n: integer;

  { error_not_printed - this diagnostic is not among the saved ones
    already listed; a saved one found not yet listed is marked listed
    and relisted is set.

    0x049508, 0x138 bytes (nested: the static link at (-16,A6), through
    which relisted, (-540) of errorlst's frame, is set).  The result
    is held in D0, true first; found (a frame byte at -10) false.  The
    list (error_listing_first) is walked while an entry's line is not
    past line (`bge'); an entry of the same line, code and nargs (in
    that order) is compared argument by argument according to nargs
    (a case, jump table at 0x04955C: 0 found; 1, 2, 3 the arguments'
    addresses, `seq', `and.b'); when found, a listed entry makes the
    result false, else the entry is marked and relisted set; either
    way the walk ends.

    Not known from the original:
    - the parameters' and locals' names. }

  function error_not_printed(
      code: integer;
      line: integer;
      in args: cerr_args_t;
      nargs: integer): boolean; options(val_param);
  var
    found: boolean;
    p: error_listing_$ptr_t;
  begin
    error_not_printed := true;
    found := false;
    p := error_listing_first;
    while (p <> nil) and then (line >= p^.line) do begin
      if (p^.line = line) and then (p^.code = code) and then
         (p^.nargs = nargs) then begin
        case nargs of
          0:
            found := true;
          1:
            found := args[1] = p^.args[1];
          2:
            found := (args[1] = p^.args[1]) and (args[2] = p^.args[2]);
          3:
            found := (args[1] = p^.args[1]) and (args[2] = p^.args[2]) and
                     (args[3] = p^.args[3]);
          otherwise
        end;
        if found then begin
          if p^.printed then
            error_not_printed := false
          else begin
            relisted := true;
            p^.printed := true;
          end;
          return;
        end;
      end;
      p := p^.next;
    end;
  end;

begin
  for i := 1 to nargs do
    if args[i] = univ_ptr(il_178) then
      return;
  if lex_fatal then begin
    lex_fatal_suppressed := true;
    return;
  end;
  case code of
    51, 48, 49, 95:
      suppress_rest := true;
    otherwise
      if suppress_rest then
        return;
  end;
  case cerr_messages[code].severity of
    0: begin
      warning := true;
      info := false;
    end;
    3, 4, 5, 6: begin
      warning := false;
      level := cerr_messages[code].severity - 2;
      info := true;
    end;
    otherwise begin
      warning := false;
      info := false;
    end;
  end;
  if warning and not cargs_$options.warn then begin
    if not error_listing_0c and not cerr_quiet then
      lex_warnings := lex_warnings + 1;
    return;
  end;
  if info and (cargs_$options.info < level) then begin
    if not error_listing_0c and not cerr_quiet then
      lex_infos := lex_infos + 1;
    return;
  end;
  if cerr_messages[code].severity = 1 then begin
    lex_fatal := true;
    lex_fatal_suppressed := false;
  end;
  if not lex_text_written then
    if cargs_$options.es = 0 then begin
      write_ln(1, addr(lex_text.body), lex_text.length);
      lex_text_written := true;
    end;
  error_hdr(line, warning, info, true, buf, code);
  if cargs_$options.es <> 0 then
    return;
  at := cerr_messages[code].text_at - 1;
  word.length := 0;
  repeat
    at := at + 1;
    c := cerr_texts[at];
    case c of
      '.', ' ': begin
        if c = '.' then
          prtcatc(word, '.');
        if buf.length + word.length > 88 then begin
          relisted := false;
          if not error_listing_0c or else
             (error_not_printed(code, line, args, nargs) and
              error_listing_0c) then
            listln(buf);
          if lex_type_errors and not cerr_quiet then
            typeln(buf);
          for i := 1 to 8 do
            buf.body[i] := ' ';
          buf.length := 8;
        end;
        if word.length <> 0 then begin
          prtcatc(buf, ' ');
          prtcats(buf, word.body, word.length);
        end;
        word.length := 0;
      end;
      '_':
        prtcatc(word, ' ');
      '@': begin
        at := at + 1;
        c := cerr_texts[at];
        case c of
          '0', '1', '2', '3', '4', '5', '6', '7', '8', '9': begin
            n := ord(c) - ord('0');
            if n > nargs then
              prtcats(word, '???', 3)
            else
              prtobj(word, args[n]);
          end;
          'L':
            prtcatc(word, '[');
          'R':
            prtcatc(word, ']');
          otherwise
            prtcatc(word, c);
        end;
      end;
      '&': begin
        at := at + 1;
        print_line_number(
          cerr_lined_ptr_t(args[ord(cerr_texts[at]) - ord('0')])^.line,
          word);
      end;
      otherwise
        prtcatc(word, c);
    end;
  until c = '.';
  if not error_listing_0c or else
     (error_not_printed(code, line, args, nargs) and error_listing_0c) or else
     relisted then
    listln(buf);
  if lex_type_errors and not cerr_quiet then
    typeln(buf);
end;

{ cgerr - report the code generator's error code at line, with arg
  (nil or il_178 for none).

  0x049A00, 0xC0 bytes: lex_fatal cleared (two identical `move.b #0'
  stores), lex_text_written and lex_hdr_written set; the C compiler's
  number from cerr_code_map (0x040CD2); cerr_quiet cleared around
  error0 (no argument: arg nil, `cmpa.w #0', or il_178) or error1;
  then a fatal diagnostic (severity 1) ends the run: io_term(5),
  pgm_$set_severity(5), pgm_$exit (the 5 in a frame word, by address).

  Not known from the original:
  - the parameters' and locals' names; why lex_fatal is cleared twice
    (perhaps two names for the cell). }

procedure cgerr(
    code: integer;
    line: integer;
    arg: univ_ptr);
var
  number: integer;
  severity: integer;
begin
  lex_fatal := false;
  lex_fatal := false;
  lex_text_written := true;
  lex_hdr_written := true;
  number := cerr_code_map[code];
  cerr_quiet := false;
  if (arg = nil) or (arg = univ_ptr(il_178)) then
    error0(number, line)
  else
    error1(number, line, arg);
  cerr_quiet := true;
  if cerr_messages[number].severity = 1 then begin
    severity := 5;
    io_term(severity);
    pgm_$set_severity(severity);
    pgm_$exit;
  end;
end;

{ error_text - an error whose message is text.

  0x049AC0, 0x6C bytes: error_hdr(line, false, false, false, buf, 0)
  (a 264-byte frame line), prtcats(buf, text, len), listln(buf); typed
  when lex_type_errors and not cerr_quiet.

  Not known from the original:
  - the parameters' and the local's names. }

procedure error_text(
    line: integer;
    in text: univ cerr_text_t;
    len: integer);
var
  buf: prtsub_$line_t;
begin
  error_hdr(line, false, false, false, buf, 0);
  prtcats(buf, text, len);
  listln(buf);
  if lex_type_errors and not cerr_quiet then
    typeln(buf);
end;

{ warning_text - a warning whose message is text.

  0x049B2C, 0x8A bytes: with warnings off (`btst #6' of cargs +0x27D)
  only counted (unless error_listing_0c or cerr_quiet); else as
  error_text with error_hdr(line, true, ...).

  Not known from the original:
  - the parameters' and the local's names. }

procedure warning_text(
    line: integer;
    in text: univ cerr_text_t;
    len: integer);
var
  buf: prtsub_$line_t;
begin
  if not cargs_$options.warn then begin
    if not error_listing_0c and not cerr_quiet then
      lex_warnings := lex_warnings + 1;
  end
  else begin
    error_hdr(line, true, false, false, buf, 0);
    prtcats(buf, text, len);
    listln(buf);
    if lex_type_errors and not cerr_quiet then
      typeln(buf);
  end;
end;
