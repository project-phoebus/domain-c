{ us/us/ins/time.ins.pas - Apollo's internal TIME_ insert (//us/us/ins).
  time.pas opens it, not the customer /sys/ins/time.ins.pas, and calls
  time_$clock, so it declared the customer insert's routines itself;
  until its own contents are known it stands in by including the
  customer insert (as us/us/ins/ubase.ins.pas does for base).

  Not known from the original: everything about its contents.
}

%include '/sys/ins/time.ins.pas';
