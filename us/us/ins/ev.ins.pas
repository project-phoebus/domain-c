{ us/us/ins/ev.ins.pas - Apollo's internal EV_ insert (//us/us/ins),
  opened by c_macro_read and c_main (neither opens
  /sys/ins/ev.ins.pas).  No copy survives.  Until its own contents are
  known it stands in by including the customer insert (ev_$get_var,
  which c_macro_read's mr_$get_expanded_line calls).

  Not known from the original: everything about its contents.
}

{ TODO(pascal) ev.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated. }

%include '/sys/ins/ev.ins.pas';
