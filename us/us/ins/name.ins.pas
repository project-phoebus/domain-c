{ us/us/ins/name.ins.pas - Apollo's internal NAME_ insert (//us/us/ins).

  No copy survives.  objio.pas and c_macro_read open it and not the customer
  /sys/ins/name.ins.pas, so it stands in by including that insert.  The declarations are the source repository's
  com/ins/name.ins.pas (what the SR10.2 /com/bind uses), which
  lang/bind/source's units call.

  Not known from the original: everything about its contents but the
  routine names.
}

%include '/sys/ins/name.ins.pas';

const
  { 16#000E0011, "illegal directory operation": what setting an initial
    ACL gives on a directory that has no room for one. }
  status_$naming_illegal_directory_operation = 16#000E0011;

{ NAME_$RESOLVE - resolve a pathname to the UID of the object it names. }
procedure name_$resolve(in path: univ name_$long_pname_t;
                        in path_len: integer;
                        out resolved_uid: uid_$t;
                        out status: status_$t); extern;

{ NAME_$RESOLVE_STOP_SHORT - resolve a pathname without following a link
  in its last component. }
procedure name_$resolve_stop_short(in path: univ name_$long_pname_t;
                                   in path_len: integer;
                                   out resolved_uid: uid_$t;
                                   out status: status_$t); extern;

{ NAME_$READ_WDIR - the UID of the working directory. }
procedure name_$read_wdir(out wdir_uid: uid_$t); extern;

{ NAME_$GPATH_LC - the pathname of an object.  acl passes 3 as the
  second argument and its buffer's size as the third. }
procedure name_$gpath_lc(in obj_uid: uid_$t; in form: integer;
                         in max_len: integer;
                         out path: univ name_$long_pname_t;
                         out path_len: integer;
                         out status: status_$t); extern;

{ NAME_$GPATH_CC - the pathname of an object (the global library's
  heading, lib/pmlib/ins/name.ins.pas). }
procedure name_$gpath_cc(in obj_uid: uid_$t;
                         in form: integer;
                         out path: univ name_$long_pname_t;
                         out path_len: integer;
                         out status: status_$t); extern;

{ NAME_$STRIP_LEAF - split a pathname's last component (at most 32
  characters) off (the global library's heading). }
procedure name_$strip_leaf(in path: univ name_$long_pname_t;
                           in path_len: integer;
                           out dir_len: pinteger;
                           out leaf: univ name_$name_t;
                           out leaf_len: pinteger;
                           out status: status_$t); extern;

{ NAME_$STRIP_LEAF_LC - split a pathname's last component off.
  dir_len is a word: cc's cargs.pas build_my_name_string passes the
  frame word at (-18,A6), between a word at -20 and a pointer at -16
  (cc.m68k 0x0B4854); the source repository's heading had integer32.  aqdev
  passes a pathname and its length, 255, a longword it never reads, the
  text and the length word of an argument record, and a status it never
  tests. }
procedure name_$strip_leaf_lc(in path: univ name_$long_pname_t;
                              in path_len: integer;
                              in max_len: integer;
                              out dir_len: integer;
                              out leaf: univ name_$long_name_t;
                              out leaf_len: integer;
                              out status: status_$t); extern;

{ NAME_$FORCE_MIXCASE - whether names are to be kept in mixed case from
  now on; returns the previous setting.  bind sets it while it renames
  its output and gives the previous setting back after. }
function name_$force_mixcase(in on: boolean): boolean; extern;
