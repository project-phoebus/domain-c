{ us/us/ins/proc2.ins.pas - Apollo's internal PROC2_ insert
  (//us/us/ins), opened where the customer /sys/ins/proc2.ins.pas would
  be.  No copy survives.

  Not known from the original: everything about its contents but what
  the units translated so far use.
}

{ TODO(pascal) proc2.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated. }

type
  { A process's information as proc2_$get_info returns it: prfpkg.pas
    asks for 228 bytes (the customer insert's proc2_$info_t is the first
    part) and reads four longwords at +86..+101, the page faults (two
    counts it adds) and the disk and network I/O counts. }
  proc2_$info_t = record
    head: array [0..42] of integer;     { +0 }
    faults_86: integer32;               { +86 }
    faults_90: integer32;               { +90 }
    disk_io: integer32;                 { +94 }
    net_io: integer32;                  { +98 }
    tail: array [51..113] of integer;   { +102 }
  end;

{ PROC2_$GET_INFO - a process's information.  Transfer vector. }
procedure proc2_$get_info(
    in p2_uid: uid_$t;
    out info: univ proc2_$info_t;
    in info_buf_len: integer;
    out status: status_$t); extern;

{ PROC2_$WHO_AM_I - the calling process's UID.  Transfer vector. }
procedure proc2_$who_am_i(
    out puid: uid_$t); extern;
