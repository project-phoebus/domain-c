{ us/us/ins/ios.ins.pas - Apollo's internal IOS_ insert (//us/us/ins),
  opened just before the customer /sys/ins/ios.ins.pas (objio.pas).

  No copy survives.  IOS_$INQ_OBJ_UID's heading is the source
  repository's com/ins/ios.ins.pas (the SR10.2 /com/bind's call); the
  stream id is ios_$id_t's integer, since /sys/ins/ios.ins.pas comes
  after this insert.

  Not known from the original: everything about its contents but the
  routine name.
}

procedure ios_$inq_obj_uid(in strid: integer;
                           out uid: uid_$t;
                           out status: status_$t); extern;
