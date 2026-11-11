{ us/us/ins/mst.ins.pas - Apollo's internal MST_ insert (//us/us/ins): the segment table.

  No copy survives.  The declarations are the source repository's
  com/ins/mst.ins.pas (what the SR10.2 /com/bind uses), which
  lang/bind/source's units call.

  Not known from the original: everything about its contents but the
  routine names.
}

{ MST_$GET_UID - the object and offset an address is mapped from. }
procedure mst_$get_uid(in va: univ_ptr;
                       out uid: uid_$t;
                       out offset: integer32;
                       out status: status_$t); extern;
