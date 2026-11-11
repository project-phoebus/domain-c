{ us/us/ins/ms.ins.pas - Apollo's internal mapping-server insert
  (//us/us/ins), opened by mrh.pas.

  No copy survives.  Until its own contents are known it stands in by
  including the customer insert (MS_$CRTEMP, MS_$ADDMAP, MS_$UNMAP are
  what mrh.pas calls).  objio.pas (lang/bind/source) opens it too and
  calls MS_$MAPL_UID, which the customer insert does not declare: its
  heading is the source repository's com/ins/ms.ins.pas.

  Not known from the original: everything about its contents.
}

%include '/sys/ins/ms.ins.pas';

{ MS_$MAPL_UID - map and lock an object given its UID. }
function ms_$mapl_uid(in uid: uid_$t;
                      in start: linteger;
                      in length: linteger;
                      in conc: ms_$conc_mode_t;
                      in access: ms_$acc_mode_t;
                      in ext_ok: boolean;
                      out len_mapped: linteger;
                      out status: status_$t): univ_ptr;
  options(extern, a0_return, d0_return);
