{ us/us/ins/name.ins.pas - Apollo's internal NAME_ insert (//us/us/ins).
  No copy survives.

  Not known from the original: everything about its contents but what
  the units translated so far call.
}

{ TODO(pascal) name.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated. }

type
  name_$chars_t = array [1..1024] of char;

{ NAME_$STRIP_LEAF_LC - the leaf of a pathname, in lower case.  A
  library routine (transfer vector); the heading is read off its one
  call, cargs.pas build_my_name_string (cc.m68k 0x0B4862): seven
  arguments by address: the pathname and its length (argument 0's
  characters and length word), 32 (a word constant), a word local, the
  compiler's name (32 characters) and its length, and a status; and
  iosub.pas iosub_$init_io (0x0B57E0), whose use shows the fourth to be
  the length of the pathname's directory part.

  Not known from the original: the parameters' names and modes. }
procedure name_$strip_leaf_lc(
    in pathname: univ name_$chars_t;
    in pathname_length: integer;
    in leaf_max: integer;
    out dir_length: integer;
    out leaf: univ name_$chars_t;
    out leaf_length: integer;
    out status: status_$t); extern;
