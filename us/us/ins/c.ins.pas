{ us/us/ins/c.ins.pas - Apollo's internal insert of that name
  (//us/us/ins), opened by inc_list.pas after ubase (and by c_macro_read
  and c_main).  No copy survives.

  Not known from the original: everything about its contents.
}

{ TODO(pascal) c.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated. }

type
  { Characters, its own type: c_lex_pp opens this insert before the
    prelude (cargs_$chars_t's layout).  Not known from the original:
    the name. }
  c_$chars_t = array [1..1024] of char;

{ C_$DECODE_VERSION - whether the len characters of s are a system type
  string (c_macro_read's #systype test: false makes `illegal system
  type string').  Called through the transfer vector with s and len by
  address and two frame words by address (not read afterwards).

  Not known from the original: the parameters' names and the outputs'
  meaning. }
function c_$decode_version(
    in s: univ c_$chars_t;
    in len: integer;
    out v1: integer;
    out v2: integer): boolean; extern;

{ C_$MAP_TO_APOLLO_COND - a UNIX-style pathname (path_len characters)
  as the Apollo name to open (c_lex_pp's open_include, under -USRCH,
  for an include file found other than in the first directory).
  Through the transfer vector, all four by address; no result read.

  Not known from the original: the parameters' names. }
procedure c_$map_to_apollo_cond(
    in path: univ c_$chars_t;
    in path_len: integer;
    out mapped: univ c_$chars_t;
    out mapped_len: integer); extern;

{ MBSTOWCS - the C library's: at most n wide characters (longwords)
  from the multibyte string src into dst; the count, negative for an
  invalid sequence.  c_lex_pp's get_wstring calls it through the
  transfer vector with the C convention (dst's address, src's address,
  n by value; D0 read as a word), when init_lex found mbtowc loaded.

  Not known from the original: where Apollo declared it. }
type
  c_$wchars_t = array [1..4096] of integer32;

function mbstowcs(
    out dst: univ c_$wchars_t;
    in src: univ c_$chars_t;
    n: integer32): integer32; options(val_param); extern;
