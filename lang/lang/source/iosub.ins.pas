{ lang/lang/source/iosub.ins.pas - IOSUB, the compilers' input and output:
  the source, include files, the listing and the object file
  (lang/lang/source/iosub.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: the parameter names.
}

{ TODO(pascal) iosub.ins.pas is incomplete

  The rest of IOSUB's interface is added when iosub.pas and its users
  are translated. }

{ OPEN_INCLUDE_FILE - open the include file named by the len characters
  of name; sid gets its stream.  0x0B60D6 (cc.a88k 0x0B9B9E): name by
  address, len a word by value (its slot is also passed by address to
  strl_$copy), sid a word by address (ios_$open's result), then two
  booleans: when in_first is false the name is first copied by
  strl_$copy; the last is not read.  The result: whether it opened
  (false for five `not found' statuses; another status is reported and
  ends the program).  Callers: inc_list's open_include_list_sub (in_first: the
  name was built on the first directory of its list, false for a name
  taken as it is), c_lex_pp's open_file_to_get_info (false). }
function open_include_file(
    in name: univ cargs_$chars_t;
    len: integer;
    var sid: integer;
    in_first: boolean;
    unused: boolean): boolean; options(val_param); extern;
