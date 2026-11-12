{ lang2/source/isc/isc_consts.ins.pas - the ISC's constants (cc.a88k only): opened by the ISC
  units after isc.pvt.pas and before isc_types.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k (translator PD).

  The requests: a longword of flags that the ISC hands the LIR with an
  instruction (debug_lir_$..._instruction's third argument, the calls'
  debug_lir_$begin_call_or_svc and _emit_call_or_svc).  Their names
  are the image's: isc_to_lir's requests_to_string (0x208BB4) prints
  bit k's name for each bit set (bits 0..24, then 27, 25, 26).

  Not known from the original: the constants' names (the requests'
  prefix is the reconstruction's); whether the requests were a set
  type (the image adds them: `add.l'). }

const
  request$set_condition_codes          = 16#00000001;  { bit 0 }
  request$set_signed_relational_ccs    = 16#00000002;
  request$set_unsigned_relational_ccs  = 16#00000004;
  request$set_equality_ccs             = 16#00000008;
  request$premodify                    = 16#00000010;
  request$postmodify                   = 16#00000020;
  request$advancing_address_mode       = 16#00000040;
  request$physical                     = 16#00000080;
  request$lock                         = 16#00000100;  { bit 8 }
  request$unlock                       = 16#00000200;
  request$and_zero                     = 16#00000400;
  request$inscrutable                  = 16#00000800;
  request$invariant                    = 16#00001000;
  request$has_alias_descriptor         = 16#00002000;
  request$widen_in_place               = 16#00004000;
  request$call_or_svc_argument         = 16#00008000;
  request$may_cause_non_local_return   = 16#00010000;  { bit 16 }
  request$may_cause_ftn_io_return      = 16#00020000;
  request$ftn_assigned_goto            = 16#00040000;
  request$asynchronous_return          = 16#00080000;
  request$pfm_cleanup                  = 16#00100000;
  request$assert_inside_atomic_block   = 16#00200000;
  request$volatile_location            = 16#00400000;
  request$case_dispatch                = 16#00800000;
  request$hidden_index                 = 16#01000000;  { bit 24 }
  request$prolog_base_register_init    = 16#02000000;
  request$preference_move              = 16#04000000;
  request$do_not_delete                = 16#08000000;  { bit 27 }
