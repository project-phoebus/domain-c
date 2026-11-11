{ us/us/ins/file.ins.pas - Apollo's internal FILE_ insert (//us/us/ins).

  No copy survives.  The declarations are the source repository's
  com/ins/file.ins.pas (what the SR10.2 /com/bind uses), which
  lang/bind/source's units call.

  Not known from the original: everything about its contents but the
  routine names.
}

const
  { The object sub-types (the attribute record's byte 1) acl tells apart.
    0, 4 and 5 are files to it, 1 and 2 directories; 3 is an ACL object,
    which it passes over. }
  file_$sub_file_0 = 0;
  file_$sub_dir_1 = 1;
  file_$sub_dir_2 = 2;
  file_$sub_acl_3 = 3;
  file_$sub_file_4 = 4;
  file_$sub_file_5 = 5;

  { The request codes acl passes file_$get_attributes, and the record's
    size. }
  file_$attr_req_4 = 4;
  file_$attr_req_260 = 260;
  file_$attributes_size = 144;

type
  { The object-location record, 0x20 bytes (the kernel's
    file_$obj_loc_t).  acl only passes it. }
  file_$obj_loc_t = array[1..32] of char;

  file_$sub_type_t = [byte] 0..255;

  { The 0x90-byte attribute record (the kernel's file_$attributes_t). }
  file_$attributes_t = record
    unused_00: char;                    { 0x00 }
    sub_type: file_$sub_type_t;         { 0x01 }
    unused_02: integer;                 { 0x02 }
    obj_uid: uid_$t;                    { 0x04: the object's UID }
    unused_0c: array[16#0C..16#87] of char;  { 0x0C }
    { 0x88: the UID acl prints as the object's ACL's with -uid, and
      hands its listing as the ACL's.  The kernel tree's VTOCE record
      calls this UID parent_uid. }
    uid_88: uid_$t;
  end;

{ FILE_$GET_ATTRIBUTES - an object's attributes. }
procedure file_$get_attributes(in file_uid: uid_$t; in req: integer;
                               in size: integer;
                               in out loc: file_$obj_loc_t;
                               out attrs: file_$attributes_t;
                               out status: status_$t); extern;

const
  { FILE_$READ_LOCK_ENTRYU's status for an object nobody has locked,
    and the one bind gives for an object somebody has (the kernel tree's
    names). }
  file_$object_not_locked_by_this_process = 16#000F0005;
  file_$object_in_use = 16#000F0006;

type
  { The 64-byte attribute record FILE_$ATTRIBUTES fills (the kernel's
    old-format VTOCE up to its file map). }
  file_$attr_t = record
    unused_00: array[1..4] of char;     { 0x00 }
    obj_uid: uid_$t;                    { 0x04 }
    type_uid: uid_$t;                   { 0x0C }
    unused_14: array[1..8] of char;     { 0x14 }
    cur_len: integer32;                 { 0x1C: what bind takes as the
                                          object's length }
    unused_20: array[16#20..16#3F] of char;  { 0x20 }
  end;

  { The first 26 bytes of an object's lock record. }
  file_$lock_user_t = array[1..26] of char;

{ FILE_$ATTRIBUTES - an object's attributes. }
procedure file_$attributes(in file_uid: uid_$t;
                           out attr: file_$attr_t;
                           out status: status_$t); extern;

{ FILE_$SET_LEN - set an object's length. }
procedure file_$set_len(in file_uid: uid_$t;
                        in new_length: integer32;
                        out status: status_$t); extern;

{ FILE_$SET_TYPE - set an object's type UID (the kernel's heading). }
procedure file_$set_type(in file_uid: uid_$t;
                         type_uid: uid_$t;
                         out status: status_$t); extern;

{ FILE_$READ_LOCK_ENTRYU - the lock record of an object. }
procedure file_$read_lock_entryu(in file_uid: uid_$t;
                                 out info: file_$lock_user_t;
                                 out status: status_$t); extern;
