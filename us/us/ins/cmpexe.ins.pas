{ us/us/ins/cmpexe.ins.pas - Apollo's internal CMPEXE_ insert (//us/us/ins): compound executables.

  No copy survives.  The declarations are the source repository's
  com/ins/cmpexe.ins.pas (what the SR10.2 /com/bind uses), which
  lang/bind/source's units call.

  Not known from the original: everything about its contents but the
  routine names.
}

type
  cmpexe_$tag_t = array[1..32] of char;

{ CMPEXE_$FIND_BY_TAG_UID - the part of a compound executable with a
  tag: its offset and length in the object, and its type. }
procedure cmpexe_$find_by_tag_uid(in uid: uid_$t;
                                  in tag: univ cmpexe_$tag_t;
                                  in tag_len: integer;
                                  out offset: integer32;
                                  out length: integer32;
                                  out elem_type: uid_$t;
                                  out status: status_$t); extern;
