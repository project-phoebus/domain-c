{ c_cond_read - CR_, the C preprocessor's conditional reader: it hands
  c_lex_pp the lines #ifdef, #ifndef, #if, #else and #endif let through,
  keeps the nesting of the conditionals on a stack, and prepares an
  #if's expression (macros expanded, the identifiers left replaced by
  0) for c_lex_pp to evaluate.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0403D8  0x040658  cr_$initialize
    0x040404  0x040684  cr_$if_is_on
    0x04041E  0x04069E  cr_$get_cooked_line
    0x0407D0  0x040A50  first_token
    0x040920  0x040BA0  match_keyword
    0x0409C0  0x040C40  push_current_state
    0x0409D2  0x040C52  pop_current_state
    A5 0x140000 (cc.m68k), 0x2C0000 (cc.a88k): the module's data, 0x54
    bytes: the stack of states (+0x00, 34 words indexed by the depth),
    the current line's address (+0x44), the depth (+0x48), the state
    (+0x4A), the scan position (+0x4C) and the line's length (+0x4E),
    cr_if_continued (+0x50) and a byte (+0x52).

  The three CR_ routines are global and load A5; first_token,
  match_keyword and the stack routines do not (internal, on their
  caller's A5).
}
module c_cond_read;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_pre_proc.ins.pas';
%include 'lang/c_compiler/source/general_utl.ins.pas';
%include 'lang/c_compiler/source/macro_read.ins.pas';

define
  cr_if_continued;                      { +0x50 (c_pre_proc.ins.pas) }

type
  { What lines are taken: those of a true branch (0), none until the
    #else or #endif of a false one (1), none until the #endif (2, after
    a true branch's #else, or inside a skipped conditional).  Stored as
    a word (`move.w #0..#2'). }
  cr_state_t = (cr_on, cr_off, cr_skip);

  { What a line begins with (first_token's result, a word): the five
    directives, nothing (5), anything else (6); 7 an #if expression's
    continuation (cr_$get_cooked_line's own value). }
  cr_token_t = (cr_tok_ifdef, cr_tok_ifndef, cr_tok_if, cr_tok_else,
                cr_tok_endif, cr_tok_none, cr_tok_other, cr_tok_cont);

  { A position in the current line: compared unsigned (`bls') and
    zero-extended (`clr.l; move.w') in the image. }
  cr_pos_t = 0..pp_$line_max;

var
  state_stack: array [0..33] of cr_state_t;     { +0x00 }
  cur_line: ^pp_$line_t;                        { +0x44 }
  depth: integer;                               { +0x48 }
  state: cr_state_t;                            { +0x4A }
  pos: cr_pos_t;                                { +0x4C }
  line_len: cr_pos_t;                           { +0x4E }
  last_id_at_end: boolean;                      { +0x52 }

{ push_current_state - save the state.

  0x0409C0, 0x12 bytes, no frame: `addq.w #1,(72,A5)';
  `move.w (74,A5),(0,A5,D0.w)' with D0 the depth doubled. }

procedure push_current_state; internal;
begin
  depth := depth + 1;
  state_stack[depth] := state;
end;

{ pop_current_state - restore the saved state.

  0x0409D2, 0x12 bytes, no frame: the state from the stack, then
  `subq.w #1,(72,A5)'. }

procedure pop_current_state; internal;
begin
  state := state_stack[depth];
  depth := depth - 1;
end;

{ match_keyword - kw[1..len] is at pos, not followed by an identifier
  character; pos is moved past it when it is.

  0x040920, 0x90 bytes.  The result is held in D0, false first; a
  counted loop over 1..len returns at once when pos + i - 1 (computed
  in longwords, pos zero-extended, i sign-extended) passes line_len
  (`bgt') or the characters differ.  Then p := pos + len; when p >
  line_len (`bgt', words) or the character at p is not in the set at
  0x0409B0 (16 bytes: 'a'..'z', 'A'..'Z', '0'..'9', '_', '$'; `btst'
  on (127 - c) div 8), the result is true and pos := p.

  Not known from the original:
  - the parameters' and locals' names; the set's form (a constant set
    written in place). }

function match_keyword(
    len: integer;
    in kw: univ pp_$line_t): boolean; internal;
var
  i: integer;
  p: integer;
begin
  match_keyword := false;
  for i := 1 to len do begin
    if pos + i - 1 > line_len then
      return;
    if cur_line^[pos + i - 1] <> kw[i] then
      return;
  end;
  p := pos + len;
  if (p > line_len) or else
     not (cur_line^[p] in ['a'..'z', 'A'..'Z', '0'..'9', '_', '$']) then begin
    match_keyword := true;
    pos := p;
  end;
end;

{ first_token - what the current line begins with.

  0x0407D0, 0x134 bytes.  When hash_first is true (`bmi' on the byte
  at (8,A6)), pos := 1: the '#' must be the line's first character
  (cr_$get_cooked_line's only call passes true); else pos runs from 1
  past the blanks and tabs (`seq', `or.b'), 5 being the result when it
  passes line_len (`bls', unsigned).  A character other than '#' gives 6.  Then a for loop
  whose index is pos itself (`addq.w #1,(76,A5)' a pass; the trip
  count line_len - (pos + 1) kept at (-12,A6)) skips the blanks after
  the '#', left at the first other character (`bpl'); then
  match_keyword with 'ifdef' (0), 'ifndef' (1), 'if' (2), 'else' (3),
  and 'endif' or 'end' (4: both calls are made, the first result kept
  at (-10,A6), `or.b'); else 6.  The literals at 0x040904.

  Not known from the original:
  - the parameter's name; whether the loop over pos was written as a
    for loop (the image's trip count and step say so) or a while
    loop. }

function first_token(
    hash_first: boolean): cr_token_t; internal;
begin
  if hash_first then
    pos := 1
  else begin
    pos := 0;
    repeat
      pos := pos + 1;
      if pos > line_len then begin
        first_token := cr_tok_none;
        return;
      end;
    until not ((cur_line^[pos] = ' ') or (cur_line^[pos] = chr(9)));
  end;
  if cur_line^[pos] <> '#' then begin
    first_token := cr_tok_other;
    return;
  end;
  for pos := pos + 1 to line_len do
    if not ((cur_line^[pos] = ' ') or (cur_line^[pos] = chr(9))) then
      exit;
  if match_keyword(5, 'ifdef') then
    first_token := cr_tok_ifdef
  else if match_keyword(6, 'ifndef') then
    first_token := cr_tok_ifndef
  else if match_keyword(2, 'if') then
    first_token := cr_tok_if
  else if match_keyword(4, 'else') then
    first_token := cr_tok_else
  else if match_keyword(5, 'endif') or match_keyword(3, 'end') then
    first_token := cr_tok_endif
  else
    first_token := cr_tok_other;
end;

{ cr_$initialize - no conditional is open.

  0x0403D8, 0x2C bytes: `move.w #0' to +0x4A (the state) and +0x48 (the
  depth); mr_$initialize(flag) (0x0403F6). }

procedure cr_$initialize(
    flag: boolean);
begin
  state := cr_on;
  depth := 0;
  mr_$initialize(flag);
end;

{ cr_$if_is_on - the #if just returned is true.

  0x040404, 0x1A bytes: `move.w #0,(74,A5)'. }

procedure cr_$if_is_on;
begin
  state := cr_on;
end;

{ cr_$get_cooked_line - the next line the conditionals let through.

  0x04041E, 0x346 bytes.  The result is held in D4 (0 first), a done
  flag in D5 (false); raw := mr_632 (`tst.b 0x1496AE; sne').  A loop
  (`bpl' on D5 back to 0x04043C):
  - in state cr_on, mr_$get_expanded_line(len, line, kind) (0x04044C;
    kind a word at (-514,A6)): kind 3 makes the result 6, kinds 1 and
    2 are returned at once; in the other states mr_$get_raw_line
    (0x040482);
  - len < 0 returns 5; pos := 1, line_len := len, cur_line := line's
    address (+0x44 := (12,A6)); raw returns the result as it stands;
  - the token is cr_tok_cont while cr_if_continued, else
    first_token(true) (0x0404B8);
  - a case on the state (`cmpi.w' chain), and in each a case on the
    token (jump tables at 0x0404EE, 0x040706, 0x040730):
    cr_on: #if and a continuation (0x0404FE) slide the expression to
    the line's start unless continuing (str_slide(len, line, pos, 1),
    0x040512), note whether the line ends without a newline
    (cr_if_continued; else the newline becomes ';'), decide whether
    the first identifier continues one ending the previous line
    (last_id_at_end, the line not empty, its first character a digit:
    the set at 0x0407B0, '0'..'9'; tested with branches), then
    replace each identifier str_locate_c_id finds (0x040584) by '0'
    (str_slide closes the gap, 0x0405C0; last_id_at_end := the
    identifier ends the line, compared in longwords); unless
    continuing, the state is pushed and becomes cr_off (the caller
    calls cr_$if_is_on when the expression is true); 3 is returned for
    #if, 4 for a continuation.  #ifdef and #ifndef (0x040604) ask
    mr_$check_define(n, cur_line^[pos]) with n := line_len - pos + 1
    (0x040622), negated for #ifndef, push the state and take the
    branch or not; n <> 0 puts 'Malformed predicate for conditional
    compilation.' and a newline in line (str_copy of the 49-character
    literal at 0x040764, whose last character 'N' is then overwritten
    by the newline) and ends the loop.  #else and #endif outside any
    conditional (depth 0) put '#else not inside a #if.' or '#endif not
    inside a #if.' (0x0407B8, 0x040796) and end the loop; inside, #else
    makes the state cr_skip and #endif pops it.  Nothing, or another
    line, returns the result.
    cr_off: #ifdef, #ifndef and #if push the state and make it
    cr_skip; #else makes it cr_on; #endif pops it.
    cr_skip: the same, but #else does nothing.
  After the loop the state is cr_on and the result 1.

  Not known from the original:
  - the parameters' and locals' names; whether line was a by-address
    array (as here) or a pointer by value (the image passes (12,A6) on
    and stores it); the frame's 512 bytes at (-512,A6), which no
    instruction touches; how the early returns were written (a goto to
    the end, as here, or return after assigning the result). }

function cr_$get_cooked_line(
    in out len: integer;
    in out line: univ pp_$line_t): integer;
label
  done;
var
  result: integer;
  finished: boolean;
  raw: boolean;
  kind: integer;
  tok: cr_token_t;
  n: integer;
  defined: boolean;
  i: integer;
  id_len: integer;
  continuing_id: boolean;
begin
  result := 0;
  finished := false;
  raw := mr_632;
  repeat
    if state = cr_on then begin
      mr_$get_expanded_line(len, line, kind);
      if kind = 3 then
        result := 6
      else if kind = 1 then begin
        result := 1;
        goto done;
      end
      else if kind = 2 then begin
        result := 2;
        goto done;
      end;
    end
    else
      mr_$get_raw_line(len, line);
    if len < 0 then begin
      result := 5;
      goto done;
    end;
    pos := 1;
    line_len := len;
    cur_line := addr(line);
    if raw then
      goto done;
    if cr_if_continued then
      tok := cr_tok_cont
    else
      tok := first_token(true);
    case state of
      cr_on:
        case tok of
          cr_tok_if, cr_tok_cont: begin
            if not cr_if_continued then
              str_slide(len, line, pos, 1);
            if line[len] <> chr(10) then
              cr_if_continued := true
            else begin
              line[len] := ';';
              cr_if_continued := false;
            end;
            if last_id_at_end and then (len > 0) and then
               (line[1] in ['0'..'9']) then
              continuing_id := true
            else begin
              continuing_id := false;
              last_id_at_end := false;
            end;
            i := 1;
            while i <= len do begin
              i := str_locate_c_id(i, false, continuing_id, true, len,
                                   line, id_len);
              if i = 0 then
                exit;
              last_id_at_end := (i + id_len - 1 = len);
              str_slide(len, line, i + id_len, i + 1);
              line[i] := '0';
              i := i + 1;
              continuing_id := false;
            end;
            if not cr_if_continued then begin
              push_current_state;
              state := cr_off;
              last_id_at_end := false;
            end;
            if tok = cr_tok_if then
              result := 3
            else
              result := 4;
            goto done;
          end;
          cr_tok_ifdef, cr_tok_ifndef: begin
            n := line_len - pos + 1;
            defined := mr_$check_define(n, cur_line^[pos]);
            if tok = cr_tok_ifndef then
              defined := not defined;
            push_current_state;
            if defined then
              state := cr_on
            else
              state := cr_off;
            if n <> 0 then begin
              str_copy(49, 'Malformed predicate for conditional compilation.N',
                       line);
              len := 49;
              line[49] := chr(10);
              finished := true;
            end;
          end;
          cr_tok_else:
            if depth <> 0 then
              state := cr_skip
            else begin
              str_copy(24, '#else not inside a #if.N', line);
              len := 24;
              line[24] := chr(10);
              finished := true;
            end;
          cr_tok_endif:
            if depth <> 0 then
              pop_current_state
            else begin
              str_copy(25, '#endif not inside a #if.N', line);
              len := 25;
              line[25] := chr(10);
              finished := true;
            end;
          cr_tok_none, cr_tok_other:
            goto done;
        end;
      cr_off:
        case tok of
          cr_tok_ifdef, cr_tok_ifndef, cr_tok_if: begin
            push_current_state;
            state := cr_skip;
          end;
          cr_tok_else:
            state := cr_on;
          cr_tok_endif:
            pop_current_state;
          otherwise
        end;
      cr_skip:
        case tok of
          cr_tok_ifdef, cr_tok_ifndef, cr_tok_if: begin
            push_current_state;
            state := cr_skip;
          end;
          cr_tok_endif:
            pop_current_state;
          otherwise
        end;
    end;
  until finished;
  state := cr_on;
  result := 1;
done:
  cr_$get_cooked_line := result;
end;
