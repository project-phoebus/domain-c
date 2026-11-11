{ us/us/ins/c.ins.pas - Apollo's internal insert of that name
  (//us/us/ins), opened by inc_list.pas after ubase (and by c_macro_read
  and c_main).  No copy survives.

  Not known from the original: everything about its contents.
}

{ TODO(pascal) c.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated. }

{ C_$DECODE_VERSION - whether the len characters of s are a system type
  string (c_macro_read's #systype test: false makes `illegal system
  type string').  Called through the transfer vector with s and len by
  address and two frame words by address (not read afterwards).

  Not known from the original: the parameters' names and the outputs'
  meaning. }
function c_$decode_version(
    in s: univ cargs_$chars_t;
    in len: integer;
    out v1: integer;
    out v2: integer): boolean; extern;
