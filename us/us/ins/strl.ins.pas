{ us/us/ins/strl.ins.pas - Apollo's internal STRL_ insert (//us/us/ins): counted strings.

  No copy survives.  The declarations are the source repository's
  com/ins/strl.ins.pas (what the SR10.2 /com/bind uses), which
  lang/bind/source's units call.

  Not known from the original: everything about its contents but the
  routine names.
}

type
  strl_$string_t = array[1..1024] of char;

{ STRL_$LOWER - fold a string to lower case in place.  acl passes a
  buffer and its length variable. }
procedure strl_$lower(in out s: univ strl_$string_t;
                      in len: integer); extern;

{ STRL_$EQ - whether two strings are equal.  acl passes a buffer and its
  length, then a literal and its length. }
function strl_$eq(in s1: univ strl_$string_t; in len1: integer;
                  in s2: univ strl_$string_t; in len2: integer): boolean;
  extern;

{ STRL_$COMPARE - how two strings sort: negative, zero or positive as
  s1 comes before, with or after s2.  /com/bind passes two names and
  their lengths. }
function strl_$compare(in s1: univ strl_$string_t; in len1: integer;
                       in s2: univ strl_$string_t; in len2: integer):
  integer; extern;

{ STRL_$COPY - copy a string, at most max_len characters; /com/bind
  passes the source and its length, the buffer and its length variable,
  and the buffer's size. }
procedure strl_$copy(in s: univ strl_$string_t; in len: integer;
                     out d: univ strl_$string_t; out d_len: integer;
                     in max_len: integer); extern;
