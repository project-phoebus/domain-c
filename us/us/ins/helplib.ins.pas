{ us/us/ins/helplib.ins.pas - Apollo's internal HELP_ insert
  (//us/us/ins), the library that prints a command's usage and help.
  No copy survives.

  Not known from the original: everything about its contents but what
  the units translated so far call.
}

{ TODO(pascal) helplib.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated. }

type
  help_$chars_t = array [1..1024] of char;

{ HELP_$PRINT_OPTS - print a command's usage or help.  A library
  routine (transfer vector); the heading is read off cargs.pas
  cargs_$parse_command_line_fixed_arguments (cc.m68k 0x0B4E20): six
  arguments by address: two word constants (2, 2 for -USAGE; 2, 1 for
  -HELP), the compiler's name and its length, the system release
  'sr10.0' and its length 6.

  Not known from the original: the parameters' names and meaning. }
procedure help_$print_opts(
    in p1: integer;
    in mode: integer;
    in command: univ help_$chars_t;
    in command_length: integer;
    in release: univ help_$chars_t;
    in release_length: integer); extern;
