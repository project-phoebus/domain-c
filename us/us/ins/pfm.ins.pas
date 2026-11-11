{ us/us/ins/pfm.ins.pas - Apollo's internal PFM_ insert (//us/us/ins).

  No copy survives.  objio.pas opens it and not the customer
  /sys/ins/pfm.ins.pas, so it stands in by including that insert.  The declarations are the source repository's
  com/ins/pfm.ins.pas (what the SR10.2 /com/bind uses), which
  lang/bind/source's units call.

  Not known from the original: everything about its contents but the
  routine names.
}

%include '/sys/ins/pfm.ins.pas';

type
  pfm_$static_handler_t = ^procedure(
      in arg1: univ_ptr;
      in arg2: univ_ptr;
      in arg3: univ_ptr;
      in arg4: univ_ptr);

{ PFM_$STATIC_CLEANUP - a handler to be called when the program ends,
  however it ends. }
procedure pfm_$static_cleanup(in handler: pfm_$static_handler_t;
                              out status: status_$t); extern;
