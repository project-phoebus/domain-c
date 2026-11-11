{ lang/c_compiler/source/macro_utl.ins.pas - the interface of the
  preprocessor's macro utilities (MU_, c_macro_utl.pas): the macro
  table, the text lists macro bodies are kept in, and binding a
  macro's actual parameters into its body.  Opened after
  general_utl.ins.pas by c_macro_read, c_macro_utl and c_main.

  No Apollo copy survives; reconstructed from c_macro_utl's routines
  (cc.m68k 0x058F00..0x059F12) and their callers.

  Not known from the original: every name but the routines'.
}

const
  { The characters a text list element holds: mu_$merge_line_tlp and
    mu_$compress_macro join elements while the total stays below it. }
  mu_$text_max = 512;

type
  { A text list element: a piece of a macro body or of a line.  They
    are cut from blocks of 256 (mu_$alloc_tle); 524 bytes (free_tle
    divides by 524).  In a body a formal parameter is the character
    128 + its number, followed by characters 128 for the rest of its
    name (mu_$convert_formal; mu_$compress_macro drops 128 and 254). }
  mu_$tle_ptr_t = ^mu_$tle_t;
  mu_$tle_t = record
    next: mu_$tle_ptr_t;                { +0 }
    len: integer;                       { +4 }
    pos: integer;                       { +6: in c_macro_read's queue,
                                          where a kind 5 piece's scan
                                          resumes (remove_q returns it;
                                          nothing in either preprocessor
                                          unit stores it) }
    kind: integer;                      { +8: cleared when allocated;
                                          in c_macro_read's queues, the
                                          line's kind (mr_$get_expanded_line)
                                          or a diagnostic's }
    text: array [1..mu_$text_max] of char;  { +10 }
    unused_522: integer;                { +522 }
  end;

  { A macro: 4110 bytes from PAS_$NEW (mu_$enter_name), on one of 128
    hash chains.  The image has name at +13, right after the byte at
    +12 (Pascal Rev 8.89 does not word-align the character array
    there, docs/rev889-patterns.md 15); dpc puts it at +14. }
  mu_$macro_ptr_t = ^mu_$macro_t;
  mu_$macro_t = record
    next: mu_$macro_ptr_t;              { +0: the hash chain }
    body: mu_$tle_ptr_t;                { +4 }
    name_len: integer;                  { +8 }
    nparams: integer;                   { +10: -1 without parentheses }
    predefined: boolean;                { +12: mu_$def_macro's flag
                                          (true for every macro
                                          mu_$initialize defines) }
    name: array [1..pp_$line_max] of char;  { +13 }
  end;

  { The actual parameters' text lists, by number (c_macro_read's data
    +0x300, by address): at most 64 (append_actual drops the 65th on;
    mr_$initialize and extract_params clear 64). }
  mu_$actuals_t = array [1..64] of mu_$tle_ptr_t;

{ MU_$LOOKUP_NAME - the macro called name (len characters), in m.
  0x058F42. }
function mu_$lookup_name(
    len: integer;
    in name: univ pp_$line_t;
    out m: mu_$macro_ptr_t): boolean; options(val_param); extern;

{ MU_$ENTER_NAME - a new macro called name at the head of its chain,
  without a body.  0x058FB0. }
function mu_$enter_name(
    len: integer;
    in name: univ pp_$line_t): mu_$macro_ptr_t; options(val_param); extern;

{ MU_$CANCEL_NAME - #undef: the first macro called name off its chain,
  its body freed.  0x05909C. }
procedure mu_$cancel_name(
    len: integer;
    in name: univ pp_$line_t); options(val_param); extern;

{ MU_$DEF_MACRO - define name (clipped to 4096, diagnostic 197) with
  the body body (body_len characters, one element) and no parameter
  list; true.  0x059128. }
function mu_$def_macro(
    name_len: integer;
    in name: univ pp_$line_t;
    body_len: integer;
    in body: univ pp_$line_t;
    predefined: boolean): boolean; options(val_param); extern;

{ MU_$INITIALIZE - an empty table and the predefined macros; with
  free_blocks, the text list blocks are given back.  0x0591C8. }
procedure mu_$initialize(
    free_blocks: boolean); options(val_param); extern;

{ MU_$DUMP - the table to standard output.  0x059494; no caller. }
procedure mu_$dump; extern;

{ MU_$CONVERT_FORMAL - mark the occurrences of the formal parameter
  formal (number index) in a body.  0x05968C. }
procedure mu_$convert_formal(
    index: integer;
    formal_len: integer;
    in formal: univ pp_$line_t;
    list: mu_$tle_ptr_t); options(val_param); extern;

{ MU_$COMPRESS_MACRO - drop the padding characters from a body and
  join its elements.  0x05973C. }
procedure mu_$compress_macro(
    in out list: mu_$tle_ptr_t); extern;

{ MU_$ALLOC_TLE, MU_$FREE_TLE, MU_$FREE_TLE_LIST - text list elements.
  0x059812, 0x059A44, 0x059B7A. }
function mu_$alloc_tle: mu_$tle_ptr_t; extern;

procedure mu_$free_tle(
    p: mu_$tle_ptr_t); options(val_param); extern;

procedure mu_$free_tle_list(
    p: mu_$tle_ptr_t); options(val_param); extern;

{ MU_$FIND_HASH_WORD - line is a directive '#' word (blanks allowed
  after the '#'), the word not followed by an identifier character;
  with strip, the '#' and the word are removed.  0x059BB2. }
function mu_$find_hash_word(
    in out len: integer;
    in out line: univ pp_$line_t;
    word_len: integer;
    in word: univ pp_$line_t;
    strip: boolean): boolean; options(val_param); extern;

{ MU_$COPY_TEXT_LIST - a copy of a text list.  0x059D08. }
function mu_$copy_text_list(
    p: mu_$tle_ptr_t): mu_$tle_ptr_t; options(val_param); extern;

{ MU_$MERGE_LINE_TLP - replace text[first..last] by the text list,
  joining what fits into text; the rest of the list (with text's tail
  after it) is the result.  0x059D36. }
function mu_$merge_line_tlp(
    in out len: integer;
    in out text: univ pp_$line_t;
    first: integer;
    last: integer;
    list: mu_$tle_ptr_t): mu_$tle_ptr_t; options(val_param); extern;

{ MU_$BIND_PARAMS - a copy of m's body with its first nactuals formal
  parameters replaced by the actuals.  0x059EDC. }
function mu_$bind_params(
    m: mu_$macro_ptr_t;
    nactuals: integer;
    in actuals: mu_$actuals_t): mu_$tle_ptr_t; options(val_param); extern;
