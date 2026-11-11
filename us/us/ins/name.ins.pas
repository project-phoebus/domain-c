{ us/us/ins/name.ins.pas - Apollo's internal NAME_ insert (//us/us/ins),
  opened by c_macro_read (which opens no /sys/ins/name.ins.pas).  No
  copy survives.  Until its own contents are known it stands in by
  including the customer insert, and declares the internal routines
  the translated units call.

  Not known from the original: everything about its contents.
}

{ TODO(pascal) name.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated. }

%include '/sys/ins/name.ins.pas';

{ NAME_$RESOLVE - the object pathname (namelen characters) names.
  c_macro_read's get_par_cooked_line passes a literal, its length by
  address (a word literal), a frame uid and the status. }
procedure name_$resolve(
    in pathname: univ name_$long_pname_t;
    in namelen: integer;
    out uid: uid_$t;
    out status: status_$t); extern;

{ NAME_$RESOLVE_STOP_SHORT - the same without following a final link
  (c_macro_read compares the status with name_$not_found). }
procedure name_$resolve_stop_short(
    in pathname: univ name_$long_pname_t;
    in namelen: integer;
    out uid: uid_$t;
    out status: status_$t); extern;
