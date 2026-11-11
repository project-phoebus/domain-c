{ us/us/ins/as_info.ins.pas - Apollo's internal insert of the address
  space information calls (//us/us/ins), opened by c_main.pas.  No copy
  survives.

  Not known from the original: everything about its contents but the
  routine's name (the transfer vector's external).
}

{ AS_INFO_$STACK_SIZE - the stack's size: c_main's cc calls it through
  the transfer vector with no arguments and stores D0 as a longword
  (c_stmt_sem's +0x5F4). }
function as_info_$stack_size: integer32; extern;
