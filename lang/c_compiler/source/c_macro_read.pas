{ c_macro_read - MR_, the C preprocessor's macro reader: it reads the
  source lines (through c_lex_pp's PPIO_), takes the comments out,
  processes #define and #undef, and expands the macros of the lines
  the conditional reader (c_cond_read) lets through; pieces of lines
  that come back from an expansion wait on a queue of text list
  elements, diagnostics on a second queue.  Before the first line it
  puts in an #include of /usr/include/apollo_$std.h when the file is
  there.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x05641C  0x05669C  mr_$initialize
    0x056472  0x0566F2  s_pick_off_name
    0x0565A8  0x056828  remove_q
    0x056622  0x0568A2  insert_q_tlp
    0x056640  0x0568C0  insert_q
    0x056686  0x056906  insert_error_q
    0x0566E2  0x056962  find_id
    0x056928  0x056BA8  text_identical
    0x056988  0x056C08  process_formals
    0x0569FA  0x056C7A  append_actual
    0x056A94  0x056D14  extract_params
    0x056E94  0x057114  get_decommented_line
    0x0573A0  0x057620  mr_$get_raw_line
    0x057570  0x0577F0  get_par_cooked_line
    0x0574CC  0x05774C  just_get_the_next_line_please
    0x057FC6  0x058246  mr_$get_q_only
    0x058262  0x0584E2  mr_$get_expanded_line
    0x058034  0x0582B4  do_special_macro
    0x0580C8  0x058348  queue_error
    0x0581A0  0x058420  skip_white_space
    0x0581E4  0x058464  prep_split_id
    0x058BD8  0x058E58  str_locate_c_id
    0x058E80  0x059100  mr_$check_define
    A5 0x14907C (cc.m68k), 0x2C907C (cc.a88k): the module's data, 0x63C
    bytes: the line the implicit #include displaced (+0x000, 512
    characters), the last element of each actual parameter's list
    (+0x200) and the lists (+0x300, 64 each), the formal parameters'
    text (+0x400, 512 characters), mr_time and mr_date (+0x600,
    +0x608), the line being decommented (+0x614), the diagnostics'
    queue (+0x618), the queue (+0x61C), the displaced line's number
    and length (+0x620, +0x622), the counts of actual and formal
    parameters (+0x624, +0x626), the formals' length (+0x628),
    mr_std_include_state (+0x62A), the displaced line's comment flags
    (+0x62C, +0x62E), whether the line read had a comment (+0x630),
    mr_open_quote (+0x632) and the quote of the string
    get_decommented_line is in (+0x634).

  The MR_ routines and str_locate_c_id are global and load A5; the
  others do not (internal, on their caller's A5).  The nested routines
  reach their parent's frame through their own dynamic link (`movea.l
  (A6),A2').

  A line's characters 128 and 254 are marks: get_decommented_line
  writes mark (128 for the expanding readers, a blank for
  mr_$get_raw_line) over comments and 254 over a backslash-newline;
  get_par_cooked_line blanks the 128s of a line that had a comment and
  mr_$get_expanded_line drops the 254s before returning.
}
module c_macro_read;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include 'lang/c_compiler/source/c_pre_proc.ins.pas';
%include 'lang/c_compiler/source/general_utl.ins.pas';
%include 'lang/c_compiler/source/macro_utl.ins.pas';
%include 'lang/c_compiler/source/macro_read.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'us/us/ins/ev.ins.pas';
%include 'us/us/ins/c.ins.pas';
%include 'us/us/ins/name.ins.pas';
%include 'lang/c_compiler/source/c_lex_pp.pvt.pas';

define
  mr_time;                              { +0x600 (macro_read.ins.pas) }
  mr_date;                              { +0x608 }
  mr_std_include_state;                 { +0x62A (c_pre_proc.ins.pas) }
  mr_open_quote;                        { +0x632 (macro_read.ins.pas) }

var
  saved_line: array [1..mu_$text_max] of char;       { +0x000 }
  actual_tails: array [1..64] of mu_$tle_ptr_t;      { +0x200 }
  actuals: mu_$actuals_t;                            { +0x300 }
  formals: array [1..mu_$text_max] of char;          { +0x400 }
  decomment_line: ^pp_$line_t;                       { +0x614 }
  error_queue: mu_$tle_ptr_t;                        { +0x618 }
  queue: mu_$tle_ptr_t;                              { +0x61C }
  saved_lineno: integer;                             { +0x620 }
  saved_len: integer;                                { +0x622 }
  nactuals: integer;                                 { +0x624 }
  nformals: integer;                                 { +0x626 }
  formals_len: integer;                              { +0x628 }
  saved_in_comment: boolean;                         { +0x62C }
  saved_had_comment: boolean;                        { +0x62E }
  line_had_comment: boolean;                         { +0x630 }
  quote: char;                                       { +0x634 }

{ mr_$initialize - start reading a source file.

  0x05641C, 0x56 bytes: lex_files[0].in_comment (c_lex_pp +0x26C),
  the line being decommented, mr_open_quote and both queues cleared,
  the 64 actuals' lists cleared (a `dbf' loop over +0x300), then
  mu_$initialize(free_blocks).

  Not known from the original:
  - the local's name. }

procedure mr_$initialize(
    free_blocks: boolean); options(val_param);
var
  i: integer;
begin
  lex_files[0].in_comment := false;
  decomment_line := nil;
  mr_open_quote := chr(0);
  queue := nil;
  error_queue := nil;
  for i := 1 to 64 do
    actuals[i] := nil;
  mu_$initialize(free_blocks);
end;

{ s_pick_off_name - take the identifier that begins line (after blanks
  and tabs) off it: its first 4096 characters to name, its length in
  n (clipped when longer), with strip the blanks after it too; true
  when there was one.

  0x056472, 0x114 bytes.  The result and clipped share D0 (false
  first).  A loop finds the first character other than a blank or a
  tab; it must be in the set at 0x056588 ('a'..'z', 'A'..'Z', '_',
  '$'), the rest in the set at 0x056598 (with '0'..'9').  min(4096,
  n) characters are copied (str_copy), the position moved past all n,
  and with strip past the blanks after; str_slide(len, line, pos, 1).

  Not known from the original:
  - the locals' names. }

function s_pick_off_name(
    in out len: integer;
    in out line: univ pp_$line_t;
    strip: boolean;
    out n: integer;
    out name: univ pp_$line_t;
    out clipped: boolean): boolean; options(val_param); internal;
var
  i, start, m: integer;
begin
  s_pick_off_name := false;
  clipped := false;
  n := 0;
  if len > 0 then begin
    start := 0;
    for i := 1 to len do
      if (line[i] <> ' ') and (line[i] <> chr(9)) then begin
        start := i;
        exit;
      end;
    if start <> 0 then
      if line[start] in ['a'..'z', 'A'..'Z', '_', '$'] then begin
        n := 1;
        for i := start + 1 to len do
          if line[i] in ['a'..'z', 'A'..'Z', '0'..'9', '_', '$'] then
            n := n + 1
          else
            exit;
        m := min(4096, n);
        if n > 4096 then
          clipped := true;
        str_copy(m, line[start], name);
        start := start + n;
        n := m;
        if strip then
          for i := start to len do
            if line[i] = ' ' then
              start := start + 1
            else
              exit;
        str_slide(len, line, start, 1);
        s_pick_off_name := true;
      end;
  end;
end;

{ remove_q - the queue's first element to len and text (its pos and
  kind too), freed; false when the queue is empty.

  0x0565A8, 0x7A bytes.

  Not known from the original:
  - the parameters' and local's names. }

function remove_q(
    out len: integer;
    out text: univ pp_$line_t;
    out pos: integer;
    out kind: integer): boolean; internal;
var
  p: mu_$tle_ptr_t;
begin
  if queue = nil then
    remove_q := false
  else begin
    len := queue^.len;
    str_copy(len, queue^.text, text);
    pos := queue^.pos;
    kind := queue^.kind;
    p := queue;
    queue := queue^.next;
    mu_$free_tle(p);
    remove_q := true;
  end;
end;

{ insert_q_tlp - the list p (when not nil) to the head of the queue.

  0x056622, 0x1E bytes, no frame (docs/rev889-patterns.md 14).

  Not known from the original:
  - the parameter's and local's names. }

procedure insert_q_tlp(
    p: mu_$tle_ptr_t); options(val_param); internal;
var
  t: mu_$tle_ptr_t;
begin
  if p <> nil then begin
    t := p;
    while t^.next <> nil do
      t := t^.next;
    t^.next := queue;
    queue := p;
  end;
end;

{ insert_q - len characters of text to the head of the queue, in a new
  element.

  0x056640, 0x46 bytes.

  Not known from the original:
  - the parameters' and local's names. }

procedure insert_q(
    len: integer;
    in text: univ pp_$line_t); options(val_param); internal;
var
  p: mu_$tle_ptr_t;
begin
  p := mu_$alloc_tle;
  p^.len := len;
  str_copy(len, text, p^.text);
  insert_q_tlp(p);
end;

{ insert_error_q - a diagnostic of kind kind (len characters of text)
  to the end of the diagnostics' queue.

  0x056686, 0x5C bytes.

  Not known from the original:
  - the parameters' and locals' names. }

procedure insert_error_q(
    kind: integer;
    len: integer;
    in text: univ pp_$line_t); options(val_param); internal;
var
  p, t: mu_$tle_ptr_t;
begin
  p := mu_$alloc_tle;
  p^.len := len;
  str_copy(len, text, p^.text);
  p^.kind := kind;
  if error_queue = nil then
    error_queue := p
  else begin
    t := error_queue;
    while t^.next <> nil do
      t := t^.next;
    t^.next := p;
  end;
end;

procedure get_par_cooked_line(
    in out len: integer;
    in out line: univ pp_$line_t;
    in out kind: integer); internal; forward;

{ find_id - the position of the first identifier of line[start..len]
  (0 if none; str_locate_c_id with angles and quotes); its characters
  to buf, its length to idlen and n.  An identifier that reaches the
  line's end continues on the next lines (from the queue, else
  get_par_cooked_line): each line that begins with an identifier
  character is kept on the list first..last, its identifier found
  with continuing set; a line that does not is queued again (and a
  diagnostic, kinds 1 and 2, with its kind).  Then the pieces are
  joined into buf (at most 4096 characters), the list's elements
  marked 4 and the last 5.

  0x0566E2, 0x246 bytes.  The current length is kept in D3 (len
  first), the next position in D4; the loop's test (`cmp.l' of p +
  idlen - 1 with the length, then p > 0) is at its bottom.

  Not known from the original:
  - the parameters' and locals' names. }

function find_id(
    start: integer;
    angles: boolean;
    quotes: boolean;
    len: integer;
    in line: univ pp_$line_t;
    var idlen: integer;
    out n: integer;
    out buf: univ pp_$line_t;
    out first: mu_$tle_ptr_t;
    out last: mu_$tle_ptr_t): integer; options(val_param); internal;
var
  text: array [1..mu_$text_max] of char;        { -520 }
  kind: integer;                                { -526 }
  tlen: integer;                                { -528 }
  qpos: integer;                                { -532 }
  pos: integer;                                 { -534 }
  cur_len, p, i, m: integer;
  t: mu_$tle_ptr_t;
begin
  first := nil;
  last := nil;
  cur_len := len;
  kind := 0;
  n := 0;
  p := str_locate_c_id(start, angles, false, quotes, len, line, idlen);
  pos := p;
  if p <> 0 then begin
    for i := 1 to idlen do
      buf[i] := line[p + i - 1];
    n := idlen;
    while (p + idlen - 1 = cur_len) and (p > 0) do begin
      if (kind <> 0) or else not remove_q(tlen, text, qpos, kind) then
        get_par_cooked_line(tlen, text, kind);
      cur_len := tlen;
      if cur_len < 0 then
        exit;
      if kind in [1, 2] then begin
        insert_q(cur_len, text);
        queue^.kind := kind;
        exit;
      end;
      if (cur_len > 0) and
         (text[1] in ['a'..'z', 'A'..'Z', '0'..'9', '_', '$']) then begin
        t := mu_$alloc_tle;
        str_copy(cur_len, text, t^.text);
        t^.len := cur_len;
        if first = nil then
          first := t
        else
          last^.next := t;
        last := t;
        p := str_locate_c_id(1, angles, true, quotes, cur_len, text, idlen);
      end
      else begin
        p := 0;
        insert_q(cur_len, text);
      end;
    end;
    if (first <> nil) and (cur_len >= 0) then begin
      t := first;
      while t <> last do begin
        t^.kind := 4;
        m := min(t^.len, 4096 - n);
        for i := 1 to m do
          buf[n + i] := t^.text[i];
        n := n + m;
        t := t^.next;
      end;
      t^.kind := 5;
      m := min(idlen, 4096 - n);
      for i := 1 to m do
        buf[n + i] := t^.text[i];
      n := n + m;
    end;
  end;
  find_id := pos;
end;

{ text_identical - the text lists a and b hold the same pieces.

  0x056928, 0x60 bytes: str_eql of each pair of elements, until one
  list ends; true when both end together.

  Not known from the original:
  - the parameters' names. }

function text_identical(
    a: mu_$tle_ptr_t;
    b: mu_$tle_ptr_t): boolean; options(val_param); internal;
begin
  text_identical := false;
  while (a <> nil) and (b <> nil) do begin
    if not str_eql(a^.len, a^.text, b^.len, b^.text) then
      return;
    a := a^.next;
    b := b^.next;
  end;
  if a = b then
    text_identical := true;
end;

{ process_formals - number the formal parameters in formals (separated
  by commas) and mark them in body (mu_$convert_formal); false when
  one is not an identifier or is followed by something else than a
  comma.

  0x056988, 0x72 bytes.  s_pick_off_name strips the blanks; the comma
  is blanked for the next.

  Not known from the original:
  - the parameter's and locals' names. }

function process_formals(
    body: mu_$tle_ptr_t): boolean; options(val_param); internal;
var
  clipped: boolean;                             { -4108 }
  n: integer;                                   { -4106 }
  name: pp_$line_t;                             { -4104 }
begin
  process_formals := false;
  while formals_len > 0 do begin
    if not s_pick_off_name(formals_len, formals, true, n, name,
                           clipped) then
      return;
    nformals := nformals + 1;
    mu_$convert_formal(nformals, n, name, body);
    if formals_len = 0 then
      exit;
    if formals[1] <> ',' then
      return;
    formals[1] := ' ';
  end;
  process_formals := true;
end;

{ append_actual - len characters of text to the end of the current
  actual parameter's list (number nactuals, 1..64).

  0x0569FA, 0x9A bytes.

  Not known from the original:
  - the parameters' and local's names. }

procedure append_actual(
    len: integer;
    in text: univ pp_$line_t); options(val_param); internal;
var
  p: mu_$tle_ptr_t;
begin
  if (nactuals > 0) and (nactuals <= 64) then begin
    p := mu_$alloc_tle;
    if len <> 0 then
      str_copy(len, text, p^.text);
    p^.len := len;
    if actuals[nactuals] = nil then
      actuals[nactuals] := p
    else
      actual_tails[nactuals]^.next := p;
    actual_tails[nactuals] := p;
  end;
end;

{ extract_params - the actual parameters of a macro call whose `('
  should follow line[start] (on this line or the next ones) into the
  actuals' lists; line is cut at start, and what follows the `)' put
  back (or queued when it does not fit in 512 characters).  nactuals
  is -1 without a `(' (and an identifier character that followed is
  pushed off with a blank).

  0x056A94, 0x400 bytes.  The 64 lists freed and cleared; the rest of
  the line (from start) copied to a 512-character frame buffer.  For
  each actual (the string flags and the backslash flag in D4
  cleared): unless in a string, blanks and newlines (and the first
  `(') are passed over, more lines fetched as needed (remove_q, else
  get_par_cooked_line; a diagnostic is queued again with its kind and
  the line emptied; end of input returns); then the characters are
  scanned for a backslash (toggles), quotes (strings, unless
  escaped), `(' and `)' (nesting; the `)' that closes the call ends
  the last actual), and a comma at depth 0 (`seq' and `and.b' with
  the negated backslash flag, then the depth).  A line without the
  end is appended whole and the next fetched; else the part before is
  appended and the scan goes on after it.

  Not known from the original:
  - the parameters' and locals' names; how the loops were written (the
    image's flow is reproduced with `exit' and one goto). }

procedure extract_params(
    start: integer;
    in out len: integer;
    in out line: univ pp_$line_t); options(val_param); internal;
label
  done;
var
  text: array [1..mu_$text_max] of char;        { -520 }
  kind: integer;                                { -522 }
  depth: integer;                               { -524 }
  tlen: integer;                                { -526 }
  qpos: integer;                                { -528 }
  pos: integer;                                 { -530 }
  first: boolean;                               { -538 }
  closed: boolean;                              { -540 }
  in_dq: boolean;                               { -542 }
  in_sq: boolean;                               { -544 }
  escaped: boolean;
  i: integer;
begin
  kind := 0;
  nactuals := -1;
  for i := 1 to 64 do
    if actuals[i] <> nil then begin
      mu_$free_tle_list(actuals[i]);
      actuals[i] := nil;
    end;
  tlen := len - start + 1;
  str_copy(tlen, line[start], text);
  len := start - 1;
  depth := 0;
  closed := false;
  nactuals := 1;
  first := true;
  repeat
    in_sq := false;
    in_dq := false;
    escaped := false;
    repeat
      if not in_dq and not in_sq then
        repeat
          pos := 0;
          for i := 1 to tlen do
            if not ((text[i] = ' ') or (text[i] = chr(10))) then
              if first and (text[i] = '(') then
                first := false
              else begin
                pos := i;
                exit;
              end;
          if pos <> 0 then begin
            str_slide(tlen, text, pos, 1);
            exit;
          end;
          if (kind <> 0) or else not remove_q(tlen, text, qpos, kind) then
            get_par_cooked_line(tlen, text, kind);
          if tlen < 0 then
            return;
          if kind in [1, 2] then begin
            insert_q(tlen, text);
            queue^.kind := kind;
            tlen := 0;
          end;
        until false;
      if first then begin
        nactuals := -1;
        pos := 0;
        if (tlen > 0) and (text[1] in ['a'..'z', 'A'..'Z', '_', '$']) then
          begin
          str_slide(tlen, text, 1, 2);
          text[1] := ' ';
        end;
        goto done;
      end;
      pos := 0;
      for i := 1 to tlen do begin
        if text[i] = '\' then
          escaped := not escaped
        else if in_dq then begin
          if not escaped and then (text[i] = '"') then
            in_dq := false;
        end
        else if in_sq then begin
          if not escaped and then (text[i] = '''') then
            in_sq := false;
        end
        else if not escaped and then (text[i] = '"') then
          in_dq := true
        else if not escaped and then (text[i] = '''') then
          in_sq := true
        else if not escaped and then (text[i] = ')') then begin
          depth := depth - 1;
          if depth < 0 then begin
            pos := i;
            closed := true;
            exit;
          end;
        end
        else if not escaped and then (text[i] = '(') then
          depth := depth + 1
        else if (text[i] = ',') and not escaped then
          if depth = 0 then begin
            pos := i;
            exit;
          end;
        if text[i] <> '\' then
          escaped := false;
      end;
      if pos = 0 then begin
        append_actual(tlen, text);
        if (kind <> 0) or else not remove_q(tlen, text, qpos, kind) then
          get_par_cooked_line(tlen, text, kind);
        if tlen < 0 then
          return;
        if kind in [1, 2] then begin
          insert_q(tlen, text);
          queue^.kind := kind;
          tlen := 0;
        end;
      end
      else begin
        append_actual(pos - 1, text);
        if closed then
          goto done;
        str_slide(tlen, text, pos + 1, 1);
        nactuals := nactuals + 1;
        exit;
      end;
    until false;
  until false;
done:
  if len + tlen - pos > 512 then
    insert_q(tlen - pos, text[pos + 1])
  else begin
    str_copy(tlen - pos, text[pos + 1], line[len + 1]);
    len := len + tlen - pos;
  end;
end;

{ get_decommented_line - the next source line with its comments
  replaced by mark; with force a line of a newline only is returned
  too (it is skipped otherwise, and an #if continued or a line that
  did not end in a newline forces).  in_comment: the line ends in a
  comment.

  0x056E94, 0x4A4 bytes.  ppio_$get_line; when mr_std_include_state
  is 0 the line is a newline only (the included file has ended); end
  of input in a comment is warned of (ppio_$error(2, 43, ...)).  An
  empty line gets a newline.  The state machine over the characters
  (a jump table over 0..6; the state is kept in the file's entry of
  lex_files between lines, +18): 0 code, 1 after a `/', 2 in a
  comment, 3 after a `*' in one, 4 in a string or character constant
  (its quote at +0x634), 5 after a backslash in one, 6 after a
  backslash in code.  A `/*' is overwritten with mark (a `/' at the
  line's end too when the next character, ppio_$lookahead, is `*');
  the comment's text with mark; at its end the text after it is
  slid back over it (str_slide) when it began on this line, a mark
  of 128 made 254.  A backslash-newline becomes 254 254 (128 for a
  blank mark).  With -COMCHK (cargs +0x27D bit 4) a `/*' inside a
  comment is warned of (59).  The position of the last character that
  is not a blank, tab, newline or `/' is kept (-12,A6), and that of a
  `#' that is the first of them (-10,A6, -5 until one is met, -2 for
  a later `#'); after the loop the line is cut after the last such
  character (keeping the newline), and a lone `#' becomes an empty
  line.  CR characters become newlines.

  Not known from the original:
  - the parameters' and locals' names; whether the state was an
    enumeration (it is a word here). }

procedure get_decommented_line(
    in out len: integer;
    in out line: univ pp_$line_t;
    force: boolean;
    mark: char;
    out in_comment: boolean); options(val_param); internal;
label
  done;
var
  i: integer;
  c: char;
  star_at: integer;
  state: integer;                               { -6 }
  hash_at: integer;                             { -10 }
  last: integer;                                { -12 }
  next_star: boolean;
begin
  repeat
    if cr_if_continued or else lex_files[lex_depth].continued then
      force := true;
    repeat
      ppio_$get_line(len, line);
      if mr_std_include_state = 0 then begin
        len := 1;
        line[1] := chr(10);
        goto done;
      end;
      if len < 0 then begin
        if lex_files[lex_depth].in_comment then
          ppio_$error(2, 43, 'End of file encountered while in a comment.');
        goto done;
      end;
      if len = 0 then begin
        len := len + 1;
        line[len] := chr(10);
      end;
    until force or (len > 1);
    lex_files[lex_depth].continued := line[len] <> chr(10);
    star_at := 0;
    hash_at := -5;
    decomment_line := addr(line);
    i := 1;
    last := star_at;
    state := lex_files[lex_depth].comment_state;
    line_had_comment := (state = 2) or (state = 3);
    while i <= len do begin
      if line[i] = chr(13) then
        line[i] := chr(10);
      c := line[i];
      case state of
        0: begin
          case c of
            '/': begin
              if i = len then
                if ppio_$lookahead = '*' then begin
                  if mark = chr(128) then
                    line[i] := chr(254)
                  else
                    line[i] := mark;
                  line_had_comment := true;
                end
                else
                  last := i;
              state := 1;
            end;
            '''', '"': begin
              quote := c;
              state := 4;
            end;
            '\': begin
              if (i = len) and then (ppio_$lookahead = chr(10)) then
                if mark = chr(128) then
                  line[i] := chr(254)
                else
                  line[i] := chr(128);
              state := 6;
            end;
          end;
          if (c <> ' ') and (c <> '/') and (c <> chr(9)) and
             (c <> chr(10)) then
            last := i;
        end;
        1:
          if c = '*' then begin
            if i > 1 then begin
              line[i - 1] := mark;
              star_at := i - 1;
            end;
            line[i] := mark;
            line_had_comment := true;
            lex_files[lex_depth].in_comment := true;
            state := 2;
          end
          else if c <> '/' then begin
            if (c = ' ') or (c = chr(9)) or (c = chr(10)) then
              last := i - 1
            else
              last := i;
            state := 0;
          end;
        2: begin
          if cargs_$options.comchk and then (c = '/') then begin
            if i = len then
              next_star := ppio_$lookahead = '*'
            else
              next_star := line[i + 1] = '*';
            if next_star then
              ppio_$error(2, 59,
                'Unbalanced comment; another comment start found before end.');
          end;
          if c = '*' then
            state := 3;
          line[i] := mark;
        end;
        3: begin
          line[i] := mark;
          if c = '/' then begin
            state := 0;
            lex_files[lex_depth].in_comment := false;
            if star_at <> 0 then begin
              str_slide(len, line, i + 1, star_at + 1);
              if mark = chr(128) then
                line[star_at] := chr(254);
              i := star_at;
              star_at := 0;
            end;
          end
          else if c <> '*' then
            state := 2;
        end;
        4: begin
          if c = '\' then begin
            if (i = len) and then (ppio_$lookahead = chr(10)) then
              if mark = chr(128) then
                line[i] := chr(254)
              else
                line[i] := mark;
            state := 5;
          end
          else if (c = quote) or (c = chr(10)) then
            state := 0;
          last := i;
        end;
        5, 6: begin
          if c = chr(10) then begin
            if mark = chr(128) then
              line[i] := chr(254)
            else
              line[i] := chr(128);
            if i > 1 then
              line[i - 1] := line[i];
          end
          else
            last := i;
          if state = 5 then
            state := 4
          else
            state := 0;
        end;
      end;
      if (c = '#') and (hash_at = -5) then begin
        if last = 0 then
          hash_at := i
        else
          hash_at := -2;
        last := i;
      end;
      i := i + 1;
    end;
    lex_files[lex_depth].comment_state := state;
    if last < len - 1 then
      if last = 0 then begin
        line[1] := line[len];
        len := 1;
      end
      else begin
        line[last + 1] := line[len];
        len := last + 1;
      end;
    if len - 1 = hash_at then begin
      len := 1;
      line[1] := chr(10);
    end;
  until force or (len <> 1);
done:
  in_comment := lex_files[lex_depth].in_comment;
end;

{ mr_$get_raw_line - the next line without comments (a blank mark)
  that is a conditional directive: the queue's first, else the next
  line read that begins with #else, #endif, #if, #ifdef or #ifndef
  (mu_$find_hash_word, not stripped); other lines are passed over
  with their continuation lines.

  0x0573A0, 0x114 bytes.

  Not known from the original:
  - the locals' names. }

procedure mr_$get_raw_line(
    in out len: integer;
    in out line: univ pp_$line_t);
var
  pos, kind: integer;
  in_comment: boolean;
begin
  if remove_q(len, line, pos, kind) then
    return;
  repeat
    get_decommented_line(len, line, false, ' ', in_comment);
    if len < 0 then
      return;
    if mu_$find_hash_word(len, line, 4, 'else', false) then
      return;
    if mu_$find_hash_word(len, line, 5, 'endif', false) then
      return;
    if mu_$find_hash_word(len, line, 2, 'if', false) then
      return;
    if mu_$find_hash_word(len, line, 5, 'ifdef', false) then
      return;
    if mu_$find_hash_word(len, line, 6, 'ifndef', false) then
      return;
    while line[len] <> chr(10) do begin
      get_decommented_line(len, line, true, ' ', in_comment);
      if len < 0 then
        return;
    end;
  until false;
end;

{ get_par_cooked_line - the next line, its comments removed, after any
  #define (taken in, with its continuation lines) and #undef (when
  not inside a string continued from the line before); kind 1 or 2
  with a diagnostic in line when one is malformed.

  0x057570, 0x82E bytes.  Before the first line (mr_std_include_state
  2), unless it is #systype, #module or #1 (not stripped), when
  /usr/include is there (name_$resolve_stop_short does not say
  name_$not_found) and either name_$resolve of it fails or
  /usr/include/apollo_$std.h is there, the line is saved (with its
  line number and comment flag) and replaced by `#include
  "/usr/include/apollo_$std.h"' (kind 3, state 3); else state 1.

  #define (stripped; the line at least 3 characters): the body is
  collected from the line and its continuations into a text list, up
  to a line that ends in a newline outside a comment (that newline
  dropped);
  the name taken off (s_pick_off_name; diagnostic 197 through error1
  when clipped); a `(' right after it opens the formals (up to the
  first `)'; a missing `)' is diagnosed), which go to formals and
  process_formals (64 at most); the blanks after the name or `)' are
  cut to one; mu_$compress_macro; nformals 0 becomes 1; a predefined
  macro is not redefined (kind 2), a different definition replaces
  the old one (kind 2: `already declared'), the same one is dropped
  and the next line read; a new macro is entered and the next line
  read.  The messages are copied into line in pieces (str_copy);
  two pieces are copied to positions that do not follow the piece
  before (`Formals list of macro "' name: the closing text at
  line[n + 18]; `Text follows the valid #undef of ' name: at
  line[n + 22], and the length n + 51), as the image does.

  When the line had a comment its marks (128) become blanks.  #undef
  (stripped): a predefined macro is kept (kind 2); else
  mu_$cancel_name, and text after the name is diagnosed (kind 2);
  without a name kind 1.

  Not known from the original:
  - the parameters' and locals' names; the error messages' lengths
    and positions as the original wrote them. }

procedure get_par_cooked_line;
label
  restart;
var
  in_comment: boolean;                          { -4150 }
  clipped: boolean;                             { -4148 }
  no_params: boolean;                           { -4144 }
  n: integer;                                   { -4134 }
  body: mu_$tle_ptr_t;                          { -4124 }
  m: mu_$macro_ptr_t;                           { -4120 }
  status: status_$t;                            { -4116 }
  name: pp_$line_t;                             { -4112 }
  uid: uid_$t;                                  { -16 }
  tail, t, b, mbody: mu_$tle_ptr_t;
  found, skip, same: boolean;
  close, blanks, i: integer;
  c: char;

  { just_get_the_next_line_please - the next line (get_decommented_line
    with the marks 128) unless the implicit #include has ended
    (mr_std_include_state 0): then the saved first line again, with
    its number (the listing's number field remade, cgu_$make_line_no
    with `(' and `)', 8 wide) and comment flags, kind 3.

    0x0574CC, 0xA4 bytes, nested (the parent's frame through (A6)). }

  procedure just_get_the_next_line_please(
      force: boolean); options(val_param);
  begin
    if mr_std_include_state <> 0 then begin
      get_decommented_line(len, line, force, chr(128), in_comment);
      kind := 0;
      if len < 0 then
        return;
      if mr_std_include_state <> 0 then
        return;
    end;
    str_copy(saved_len, saved_line, line);
    len := saved_len;
    lex_line := saved_lineno;
    cgu_$make_line_no(lex_line, '(', ')', 8, lex_listing_line);
    in_comment := saved_in_comment;
    mr_std_include_state := 1;
    line_had_comment := saved_had_comment;
    kind := 3;
  end;

begin
  kind := 0;
  in_comment := false;
restart:
  body := nil;
  nformals := -1;
  just_get_the_next_line_please(false);
  if len < 0 then
    return;
  if mr_std_include_state = 2 then
    if not mu_$find_hash_word(len, line, 7, 'systype', false) and then
       not mu_$find_hash_word(len, line, 6, 'module', false) and then
       not mu_$find_hash_word(len, line, 1, '1', false) then begin
      found := false;
      name_$resolve_stop_short('/usr/include', 12, uid, status);
      if status.all <> name_$not_found then begin
        name_$resolve('/usr/include', 12, uid, status);
        if status.all <> 0 then
          found := true
        else begin
          name_$resolve_stop_short('/usr/include/apollo_$std.h', 26, uid,
                                   status);
          if status.all <> name_$not_found then
            found := true;
        end;
      end;
      if found then begin
        str_copy(len, line, saved_line);
        saved_len := len;
        saved_lineno := lex_line;
        saved_in_comment := in_comment;
        str_copy(37, '#include "/usr/include/apollo_$std.h"', line);
        len := 38;
        line[len] := chr(10);
        in_comment := false;
        mr_std_include_state := 3;
        saved_had_comment := line_had_comment;
        kind := 3;
      end
      else
        mr_std_include_state := 1;
    end;
  skip := mr_open_quote <> chr(0);
  if not skip then
    if mu_$find_hash_word(len, line, 6, 'define', true) then begin
      if len < 3 then begin
        kind := 1;
        len := 31;
        str_copy(len, 'Macro name missing from #define', line);
        return;
      end;
      repeat
        t := mu_$alloc_tle;
        if body = nil then
          body := t
        else
          tail^.next := t;
        tail := t;
        str_copy(len, line, t^.text);
        t^.len := len;
        if not in_comment and (line[len] = chr(10)) then begin
          t^.len := t^.len - 1;
          exit;
        end;
        just_get_the_next_line_please(true);
        if len < 0 then
          return;
      until false;
      if (body = nil) or else
         not s_pick_off_name(body^.len, body^.text, false, n, name,
                             clipped) then begin
        kind := 1;
        len := 41;
        str_copy(len, 'Macro name missing or invalid for #define', line);
        mu_$free_tle_list(body);
        return;
      end;
      if clipped then
        error1(197, lex_line, idntk(76, name, n));
      b := body;
      no_params := true;
      if (b^.len > 0) and (b^.text[1] = '(') then begin
        close := 0;
        for i := 2 to b^.len do begin
          if b^.text[i] = ')' then begin
            close := i;
            exit;
          end;
          if not ((b^.text[i] = ' ') or (b^.text[i] = chr(9))) then
            no_params := false;
        end;
        if close = 0 then begin
          kind := 1;
          str_copy(23, 'Formals list of macro "', line);
          str_copy(n, name, line[24]);
          str_copy(32, '" is missing closing parenthesis', line[n + 18]);
          len := n + 55;
          mu_$free_tle_list(body);
          return;
        end;
        formals_len := close - 2;
        nformals := 0;
        str_copy(formals_len, b^.text[2], formals);
      end
      else begin
        close := 0;
        formals_len := close;
      end;
      blanks := 0;
      for i := close + 1 to b^.len do begin
        c := b^.text[i];
        if (c = ' ') or (c = chr(9)) then
          blanks := blanks + 1
        else begin
          if blanks > 1 then
            blanks := blanks - 1;
          exit;
        end;
      end;
      if (close <> 0) or (blanks <> 0) then
        str_slide(b^.len, b^.text, close + blanks + 1, 1);
      if not no_params and then (formals_len <> 0) then begin
        if not process_formals(body) then begin
          kind := 1;
          str_copy(7, 'Macro "', line);
          str_copy(n, name, line[8]);
          str_copy(40, '" has a malformed formal parameter list.',
                   line[n + 8]);
          len := n + 47;
          return;
        end;
        if nformals > 64 then begin
          kind := 1;
          str_copy(7, 'Macro "', line);
          str_copy(n, name, line[8]);
          str_copy(26, '" has too many parameters.', line[n + 8]);
          len := n + 33;
          return;
        end;
      end;
      mu_$compress_macro(body);
      mbody := body;
      if nformals = 0 then
        nformals := 1;
      if mu_$lookup_name(n, name, m) then begin
        if m^.predefined then begin
          kind := 2;
          str_copy(7, 'Macro "', line);
          str_copy(n, name, line[8]);
          str_copy(47, '" is a predefined macro - redefinition ignored ',
                   line[n + 8]);
          len := n + 54;
          mu_$free_tle_list(mbody);
          return;
        end;
        same := false;
        if m^.nparams = nformals then
          if text_identical(m^.body, mbody) then
            same := true;
        if not same then begin
          kind := 2;
          str_copy(7, 'Macro "', line);
          str_copy(n, name, line[8]);
          str_copy(42, '" already declared - it has been redefined',
                   line[n + 8]);
          len := n + 49;
          mu_$free_tle_list(m^.body);
          m^.body := mbody;
          m^.nparams := nformals;
          m^.predefined := false;
          return;
        end;
        mu_$free_tle_list(mbody);
        goto restart;
      end;
      m := mu_$enter_name(n, name);
      m^.body := mbody;
      m^.nparams := nformals;
      m^.predefined := false;
      goto restart;
    end;
  if line_had_comment then
    for i := 1 to len do
      if line[i] = chr(128) then
        line[i] := ' ';
  if skip then
    return;
  if not mu_$find_hash_word(len, line, 5, 'undef', true) then
    return;
  if s_pick_off_name(len, line, true, n, name, clipped) then begin
    if mu_$lookup_name(n, name, m) and then m^.predefined then begin
      kind := 2;
      str_copy(7, 'Macro "', line);
      str_copy(n, name, line[8]);
      str_copy(51, '" is a predefined macro - it has not been undefined',
               line[n + 8]);
      len := n + 58;
    end
    else begin
      mu_$cancel_name(n, name);
      if len <= 1 then
        goto restart;
      kind := 2;
      str_copy(33, 'Text follows the valid #undef of ', line);
      str_copy(n, name, line[34]);
      str_copy(23, '", it has been ignored.', line[n + 22]);
      len := n + 51;
    end;
  end
  else begin
    kind := 1;
    len := 40;
    str_copy(len, 'Macro name missing or invalid for #undef', line);
  end;
end;

{ mr_$get_q_only - the queue's lines, expanded, until it is empty.

  0x057FC6, 0x6E bytes.  The result in D2 (false first).

  Not known from the original:
  - the local's name. }

function mr_$get_q_only(
    in out len: integer;
    in out line: univ pp_$line_t): boolean;
var
  kind: integer;
begin
  mr_$get_q_only := false;
  repeat
    if queue = nil then begin
      queue := error_queue;
      error_queue := nil;
      len := 0;
      return;
    end;
    mr_$get_expanded_line(len, line, kind);
    if len < 0 then
      return;
    if (kind = 0) or (kind = 3) then begin
      mr_$get_q_only := true;
      return;
    end;
    insert_error_q(kind, len, line);
  until false;
end;

{ mr_$get_expanded_line - the next line with its macros expanded.

  0x058262, 0x85E bytes.  The line comes from the queue (with its kind
  and position) or get_par_cooked_line.  Kind 4 is returned as it is;
  kind 5 resumes the scan at the element's position; other kinds but
  0 and 3 get a newline (when shorter than 512) and are returned.
  Inside a continued string the line is scanned without the #if
  forms; #endif, #else, #ifdef, #ifndef and #apollo lines are returned
  as they are; #include sets find_id's angles; #if (or a continued
  #if) allows `defined' and `systype'.

  The scan: find_id from the position; a macro sets
  lex_macro_expanded; the predefined __LINE__ gets the current line's
  number (vfmt_$encode2 `%1JLD%$' into its body), __FILE__ the
  region's user name (prtobj into a frame PRTSUB line), `defined' is
  not expanded here; an identifier continued from the next lines is
  split back (prep_split_id); a macro without parameters is replaced
  by a copy of its body (mu_$merge_line_tlp, the rest queued); one
  with parameters gets its actuals (extract_params) bound
  (mu_$bind_params, min(nparams, nactuals) of them), and a count that
  differs is diagnosed (queue_error, kind 2) and ends the scan.  In
  an #if, `defined' (name) or `defined name' and `systype("t")' are
  replaced by 0 or 1 (do_special_macro): `defined' looks the name up;
  `systype' accepts a string c_$decode_version takes and compares it
  with the environment variable COMPILESYSTYPE (else SYSTYPE); a
  missing name or parenthesis, or a bad string, is diagnosed (kind 1).
  Another identifier is passed over (its continuation queued and the
  scan ended).  Last the 254 marks are dropped.

  The `if' flag (D2) is not set on the kind 5 path: there the register
  still holds the element's position (remove_q's third result), and
  the image tests its low byte; the translation leaves the variable
  unset.

  Not known from the original:
  - the parameters' and locals' names; the flag on the kind 5 path. }

procedure mr_$get_expanded_line(
    in out len: integer;
    in out line: univ pp_$line_t;
    in out kind: integer);
label
  not_macro, finish, done;
var
  is_include: boolean;                          { -4928 }
  pos: integer;                                 { -4922 }
  p: integer;                                   { -4920 }
  qpos: integer;                                { -4918 }
  idlen: integer;                               { -4914 }
  n: integer;                                   { -4912 }
  val_len: integer;                             { -4910 }
  v1, v2: integer;                              { -4908, -4906 }
  env_len: integer;                             { -4902 }
  first: mu_$tle_ptr_t;                         { -4900 }
  last: mu_$tle_ptr_t;                          { -4896 }
  m: mu_$macro_ptr_t;                           { -4892 }
  bound: mu_$tle_ptr_t;                         { -4888 }
  env: ev_$string_ptr_t;                        { -4884 }
  region: integer32;                            { -4880 }
  lineno: integer32;                            { -4876 }
  name: pp_$line_t;                             { -4872 }
  val: array [1..mu_$text_max] of char;         { -776 }
  pline: prtsub_$line_t;                        { -264 }
  in_if, split, bad, paren: boolean;
  err, start: integer;
  b: mu_$tle_ptr_t;

  { do_special_macro - replace line[first..last] by val: name defined
    (predefined) as val, a copy of its body merged into the line (the
    rest queued), and with cancel the macro removed again.

    0x058034, 0x94 bytes, nested. }

  procedure do_special_macro(
      name_len: integer;
      in name: univ pp_$line_t;
      val_len: integer;
      in val: univ pp_$line_t;
      first: integer;
      last: integer;
      cancel: boolean); options(val_param);
  var
    ok: boolean;
    sm: mu_$macro_ptr_t;
  begin
    ok := mu_$def_macro(name_len, name, val_len, val, true);
    ok := mu_$lookup_name(name_len, name, sm);
    insert_q_tlp(mu_$merge_line_tlp(len, line, first, last,
                                    mu_$copy_text_list(sm^.body)));
    if cancel then
      mu_$cancel_name(name_len, name);
  end;

  { queue_error - the line queued (in bound) and replaced by the text
    (mlen characters), the name, `"' and a newline; kind 2.

    0x0580C8, 0xD8 bytes, nested. }

  procedure queue_error(
      mlen: integer;
      in text: univ pp_$line_t); options(val_param);
  begin
    bound := mu_$alloc_tle;
    str_copy(len, line, bound^.text);
    bound^.len := len;
    insert_q_tlp(bound);
    len := mlen;
    str_copy(len, text, line);
    str_copy(n, name, line[len + 1]);
    len := len + (n + 1);
    line[len] := '"';
    len := len + 1;
    line[len] := chr(10);
    kind := 2;
  end;

  { skip_white_space - p past blanks and tabs (back to the last
    character when it would pass len).

    0x0581A0, 0x44 bytes, nested. }

  procedure skip_white_space;
  begin
    while (line[p] = ' ') or else (line[p] = chr(9)) do
      if p <= len then
        p := p + 1
      else begin
        p := p - 1;
        exit;
      end;
  end;

  { prep_split_id - an identifier continued on the next lines is not a
    macro's name after all: the last piece, past the identifier's
    part, is queued again (kind 0), the pieces before it freed, and the
    scan goes on to the line's end.

    0x0581E4, 0x7E bytes, nested. }

  procedure prep_split_id;
  var
    t, f: mu_$tle_ptr_t;
  begin
    str_slide(last^.len, last^.text, idlen + 1, 1);
    last^.kind := 0;
    insert_q_tlp(last);
    t := first;
    while t <> last do begin
      f := t;
      t := t^.next;
      mu_$free_tle(f);
    end;
    idlen := len - pos + 1;
  end;

begin
  is_include := false;
  pos := 1;
  if not remove_q(len, line, qpos, kind) then begin
    get_par_cooked_line(len, line, kind);
    if len < 0 then
      goto finish;
  end;
  if kind = 4 then
    goto done;
  if kind = 5 then
    pos := qpos
  else if (kind <> 0) and (kind <> 3) then begin
    if (line[len] <> chr(10)) and (len < 512) then begin
      len := len + 1;
      line[len] := chr(10);
    end;
    goto finish;
  end
  else if mr_open_quote <> chr(0) then
    in_if := false
  else begin
    if mu_$find_hash_word(len, line, 5, 'endif', false) or else
       mu_$find_hash_word(len, line, 4, 'else', false) or else
       mu_$find_hash_word(len, line, 5, 'ifdef', false) or else
       mu_$find_hash_word(len, line, 6, 'ifndef', false) or else
       mu_$find_hash_word(len, line, 6, 'apollo', false) then
      goto finish;
    is_include := mu_$find_hash_word(len, line, 7, 'include', false);
    in_if := mu_$find_hash_word(len, line, 2, 'if', false) or else
             cr_if_continued;
  end;
  while pos <= len do begin
    pos := find_id(pos, is_include, true, len, line, idlen, n, name,
                   first, last);
    if pos = 0 then
      goto finish;
    split := first <> nil;
    if mu_$lookup_name(n, name, m) then begin
      lex_macro_expanded := true;
      if m^.predefined then
        if str_eql(n, name, 8, '__LINE__') then begin
          spos_$decode_source_position(lex_line, region, lineno);
          vfmt_$encode2('%1JLD%$', m^.body^.text, 20, m^.body^.len,
                        lineno, 0);
        end
        else if str_eql(n, name, 8, '__FILE__') then begin
          b := m^.body;
          spos_$decode_source_position(lex_line, region, lineno);
          pline.length := 0;
          prtobj(pline, spos_$region_user_name(region));
          str_copy(pline.length, pline.body, b^.text);
          b^.len := pline.length;
        end
        else if str_eql(n, name, 7, 'defined') then
          goto not_macro;
      if split then
        prep_split_id;
      if m^.nparams = -1 then begin
        insert_q_tlp(mu_$merge_line_tlp(len, line, pos, pos + idlen - 1,
                                        mu_$copy_text_list(m^.body)));
        next;
      end;
      extract_params(pos + idlen, len, line);
      bound := mu_$bind_params(m, min(m^.nparams, nactuals), actuals);
      insert_q_tlp(mu_$merge_line_tlp(len, line, pos, pos + idlen - 1,
                                      bound));
      if nactuals <> m^.nparams then begin
        if nactuals < 0 then
          queue_error(33, 'Missing argument list for macro "')
        else if nactuals < m^.nparams then
          queue_error(28, 'Too few arguments to macro "')
        else
          queue_error(29, 'Too many arguments to macro "');
        goto finish;
      end;
      next;
    end;
not_macro:
    if in_if then
      if str_eql(n, name, 7, 'defined') then begin
        val[1] := '0';
        val_len := 1;
        p := pos + n;
        skip_white_space;
        if line[p] = '(' then begin
          p := p + 1;
          paren := true;
          skip_white_space;
        end
        else
          paren := false;
        if not (line[p] in ['a'..'z', 'A'..'Z', '_', '$']) then begin
          bad := true;
          start := p;
          idlen := 0;
        end
        else begin
          bad := false;
          start := str_locate_c_id(p, false, false, true, len, line, idlen);
          n := min(4096, idlen);
          str_copy(n, line[start], name);
          if mu_$lookup_name(n, name, m) then
            val[1] := '1';
        end;
        p := start + idlen;
        if paren then begin
          while line[p] <> ')' do
            if p <= len then
              p := p + 1
            else begin
              p := p - 1;
              exit;
            end;
          if line[p] = ')' then
            p := p + 1;
        end;
        do_special_macro(7, 'defined', val_len, val, pos, p - 1, true);
        if bad then begin
          queue_error(29, 'No valid argument for macro "');
          kind := 1;
          goto finish;
        end;
        next;
      end
      else if str_eql(n, name, 7, 'systype') then begin
        val[1] := '0';
        val_len := 1;
        p := pos + n;
        skip_white_space;
        if line[p] <> '(' then begin
          err := 1;
          start := p;
          idlen := 0;
        end
        else begin
          p := p + 1;
          err := 0;
          skip_white_space;
          if line[p] = '"' then
            p := p + 1;
          start := p;
          while not (line[p] in [chr(9), chr(10), ' ', '"', ')']) do
            if p <= len then
              p := p + 1
            else begin
              p := p - 1;
              exit;
            end;
          idlen := p - start;
          if c_$decode_version(line[start], idlen, v1, v2) then begin
            if ev_$get_var('COMPILESYSTYPE', 14, env, env_len) or else
               ev_$get_var('SYSTYPE', 7, env, env_len) then
              if str_eql(idlen, line[start], env_len, env^) then
                val[1] := '1';
          end
          else begin
            err := 2;
            n := min(4096, idlen);
            str_copy(n, line[start], name);
          end;
        end;
        p := start + idlen;
        while line[p] <> ')' do
          if p <= len then
            p := p + 1
          else begin
            p := p - 1;
            exit;
          end;
        if line[p] = ')' then
          p := p + 1;
        do_special_macro(7, 'systype', val_len, val, pos, p - 1, true);
        if err = 2 then begin
          queue_error(48, '"systype" macro has illegal system type string "');
          kind := 1;
          goto finish;
        end
        else if err = 1 then begin
          queue_error(26, 'No parenthesis for macro "');
          kind := 1;
          goto finish;
        end;
        next;
      end;
    if split then begin
      insert_q_tlp(first);
      pos := len + 1;
    end
    else
      pos := pos + idlen;
  end;
finish:
  if len > 0 then begin
    p := 1;
    for pos := 1 to len do
      if line[pos] <> chr(254) then begin
        line[p] := line[pos];
        p := p + 1;
      end;
    len := p - 1;
  end;
done:
end;

{ str_locate_c_id - see macro_read.ins.pas.

  0x058BD8, 0x2A0 bytes.  The result (-10,A6) and n are 0 first; the
  open quote (D4) is mr_open_quote when line is the line being
  decommented (+0x614), and then the angles flag is dropped.  A for
  loop from max(1, start): a backslash toggles the escape flag (D3,
  cleared after any other character); in a string only its closing
  quote counts (`>' always, a quote when not escaped); `*/' ends a
  comment, a quote (with quotes, not escaped) or `<' (with angles)
  opens a string, `/*' a comment; otherwise, not escaped, an
  identifier character (the set at 0x056588, or with continuing a
  digit, the set at 0x058E78) where one may start is the result;
  another character allows one to start unless it is a digit, and a
  `.' after digits that do not follow an identifier character makes
  a number (no identifier starts in it).  The identifier's length is
  counted over the set at 0x056598.  An open quote is closed by a
  newline not escaped, and carried in mr_open_quote.

  Not known from the original:
  - the locals' names. }

function str_locate_c_id(
    start: integer;
    angles: boolean;
    continuing: boolean;
    quotes: boolean;
    len: integer;
    in line: univ pp_$line_t;
    out n: integer): integer;
var
  pos: integer;                                 { -10 }
  angle_ok: boolean;                            { -20 }
  can_start: boolean;                           { -16 }
  in_comment: boolean;                          { -14 }
  found: integer;                               { -4 }
  escaped: boolean;
  open: char;
  first, i, j: integer;
  c: char;
begin
  pos := 0;
  n := 0;
  angle_ok := angles;
  if len > 0 then begin
    if decomment_line = addr(line) then
      open := mr_open_quote
    else
      open := chr(0);
    if open <> chr(0) then
      angle_ok := false;
    escaped := false;
    can_start := true;
    in_comment := escaped;
    first := max(1, start);
    found := 0;
    for i := first to len do begin
      c := line[i];
      if c = '\' then
        escaped := not escaped
      else if open <> chr(0) then begin
        if c = open then
          if (open = '>') or else
             (not escaped and ((open = '"') or (open = ''''))) then begin
            open := chr(0);
            can_start := true;
          end;
      end
      else if ((c = '/') and in_comment) and then (line[i - 1] = '*') then
        in_comment := false
      else if not in_comment and
              ((not escaped and quotes) and then
               ((c = '"') or (c = ''''))) then
        open := c
      else if not in_comment and angle_ok and (c = '<') then
        open := '>'
      else if (c = '/') and then (line[i + 1] = '*') then
        in_comment := true
      else if not escaped then
        if (c in ['a'..'z', 'A'..'Z', '_', '$']) or else
           (continuing and (c in ['0'..'9'])) then begin
          if can_start then begin
            found := i;
            exit;
          end;
        end
        else begin
          can_start := not (c in ['0'..'9']);
          if (c = '.') and (i > first) and then
             (line[i - 1] in ['0'..'9']) then begin
            j := i - 2;
            while j >= first do
              if line[j] in ['0'..'9'] then
                j := j - 1
              else
                exit;
            if (j < first) or else
               not (line[j] in ['a'..'z', 'A'..'Z', '_', '$']) then
              can_start := false;
          end;
        end;
      if line[i] <> '\' then
        escaped := false;
    end;
    if found <> 0 then begin
      n := 1;
      pos := found;
      for j := found + 1 to len do
        if line[j] in ['a'..'z', 'A'..'Z', '0'..'9', '_', '$'] then
          n := n + 1
        else
          exit;
    end;
    if open <> chr(0) then
      if (line[len] = chr(10)) and then (line[len - 1] <> '\') then
        open := chr(0);
    if decomment_line = addr(line) then
      mr_open_quote := open;
  end;
  str_locate_c_id := pos;
end;

{ mr_$check_define - see macro_read.ins.pas.

  0x058E80, 0x80 bytes: s_pick_off_name(n, s, true, ...); without a
  name n := -1 and false; else mu_$lookup_name's answer, and n := 0
  when only a newline is left.

  Not known from the original:
  - the locals' names. }

function mr_$check_define(
    in out n: integer;
    in out s: univ pp_$line_t): boolean;
var
  name: pp_$line_t;                             { -4096 }
  m: mu_$macro_ptr_t;                           { -4100 }
  len: integer;                                 { -4102 }
  clipped: boolean;                             { -4104 }
begin
  if not s_pick_off_name(n, s, true, len, name, clipped) then begin
    n := -1;
    mr_$check_define := false;
  end
  else begin
    mr_$check_define := mu_$lookup_name(len, name, m);
    if (n = 1) and (s[1] = chr(10)) then
      n := 0;
  end;
end;
