{ opcode_enumeration.ins.pas - the PRISM (and PA-RISC) back end's
  opcodes: a DSEE derived object of be_com/opcodes.def, which Apollo's
  opcode generator also made instr_mnemonic.init,
  instr_mnemonic_length.init, instr_attributes.init, instr_size.init,
  instr_assembly.init, code_cell_size.init and fp_registers_busy.init
  from.  Opened by every be_com unit after be_prism/target.ins.pas, and
  by call_conv and the ISC units.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  How the names were recovered:

  - isc_to_lir's end_statement writes an opcode with Pascal `write', so
    the compiler put the type's identifier table after the routine's
    constants (cc.a88k 0x209FEE: the count 384, then each identifier as
    a length byte and its upper-case characters, in ordinal order:
    OPC$UNDEFINED, OPC$BNEVER, ..., OPC$INIT_LB).  tools/cc_enumnames.py
    lists every such table of a binary and prints one as Pascal
    (`tools/cc_enumnames.py ctape/.../cc.a88k 0x209FEE --pascal').
  - The section instruction_mnemonic (0x2B7A3C, 384 entries of 12
    characters; their lengths in instruction_mnemonic_length, 0x2B773C)
    is the same list without the prefix, "********" for 0: every entry
    agrees with the identifier of its ordinal.
  - The PRISM tables instruction_attributes (0x2B8C3C, 20 bytes an
    entry) and instruction_assembly (0x2B9CCC, 44 bytes) have 212
    entries: opc$undefined..opc$adj_move are the PRISM opcodes and the
    back end's pseudo-instructions (opc$nop..opc$adj_move); the rest,
    opc$bc..opc$init_lb (PL_, PA_, PG_, PM_, the compare-and-branch and
    skip forms), are HP Precision Architecture ones, which this back
    end never makes (backend.ins.pas's instr_attrs_t has 212 entries;
    the records hold an opcode as a word, opc$w_t, since backend.ins.pas
    is opened before this insert).

  Not known from the original: the type's name (OPC$ is the elements'
  prefix; the ISC's ARITH$T_MAX suggests a `<prefix>$t' convention). }

type
  opc$t = (
    opc$undefined, opc$bnever, opc$bnl2v, opc$bl2v,  { 0 }
    opc$bnl2, opc$bl2, opc$bnz3, opc$bz3,  { 4 }
    opc$bgt, opc$ble, opc$bge, opc$blt,  { 8 }
    opc$bhi, opc$bls, opc$blo, opc$bhs,  { 12 }
    opc$bnn, opc$bn, opc$bne, opc$beq,  { 16 }
    opc$bnv, opc$bv, opc$fbeq, opc$fbne,  { 20 }
    opc$fbgt, opc$fble, opc$fbge, opc$fblt,  { 24 }
    opc$trap_gt, opc$trap_le, opc$trap_ge, opc$trap_lt,  { 28 }
    opc$trap_hi, opc$trap_ls, opc$trap_lo, opc$trap_hs,  { 32 }
    opc$trap_nn, opc$trap_n, opc$trap_ne, opc$trap_eq,  { 36 }
    opc$trap_nv, opc$trap_v, opc$trap_feq, opc$trap_fne,  { 40 }
    opc$trap_fgt, opc$trap_fle, opc$trap_fge, opc$trap_flt,  { 44 }
    opc$trapd_gt, opc$trapd_le, opc$trapd_ge, opc$trapd_lt,  { 48 }
    opc$trapd_hi, opc$trapd_ls, opc$trapd_lo, opc$trapd_hs,  { 52 }
    opc$trapd_nn, opc$trapd_n, opc$trapd_ne, opc$trapd_eq,  { 56 }
    opc$trapd_nv, opc$trapd_v, opc$trapd_feq, opc$trapd_fne,  { 60 }
    opc$trapd_fgt, opc$trapd_fle, opc$trapd_fge, opc$trapd_flt,  { 64 }
    opc$trap, opc$jump, opc$dispatch, opc$tstb,  { 68 }
    opc$tstw, opc$tst, opc$cmp, opc$move,  { 72 }
    opc$pmove, opc$neg, opc$com, opc$add,  { 76 }
    opc$addc, opc$sub, opc$subc, opc$rsub,  { 80 }
    opc$and, opc$or, opc$xor, opc$extend0,  { 84 }
    opc$extend7, opc$extend15, opc$asr, opc$lsr,  { 88 }
    opc$lsl, opc$isolate, opc$clrins, opc$transfer,  { 92 }
    opc$insert, opc$extractu, opc$widenb, opc$widenw,  { 96 }
    opc$synchb, opc$synchw, opc$synch, opc$loadbu,  { 100 }
    opc$loadwu, opc$loadl, opc$loads, opc$loadse,  { 104 }
    opc$loadso, opc$loadd, opc$load_pair, opc$mfnextcc,  { 108 }
    opc$mfippsw, opc$mffpcc, opc$mffppsw, opc$mfpr,  { 112 }
    opc$mffp, opc$fpquiesce, opc$storeb, opc$storew,  { 116 }
    opc$storel, opc$stores, opc$storese, opc$storeso,  { 120 }
    opc$stored, opc$mtpr, opc$mtfp, opc$enable,  { 124 }
    opc$disable, opc$call, opc$svc, opc$svc2,  { 128 }
    opc$return, opc$movei, opc$pmovei, opc$negi,  { 132 }
    opc$comi, opc$addi, opc$subi, opc$andi,  { 136 }
    opc$ori, opc$xori, opc$cvtis, opc$cvtid,  { 140 }
    opc$copys, opc$pcopys, opc$moves, opc$negs,  { 144 }
    opc$abss, opc$cvtsd, opc$roundsi, opc$rounds,  { 148 }
    opc$truncsi, opc$truncs, opc$adds, opc$subs,  { 152 }
    opc$cmps, opc$classs, opc$tsts, opc$mins,  { 156 }
    opc$maxs, opc$copyd, opc$pcopyd, opc$moved,  { 160 }
    opc$negd, opc$absd, opc$cvtds, opc$rounddi,  { 164 }
    opc$roundd, opc$truncdi, opc$truncd, opc$addd,  { 168 }
    opc$subd, opc$cmpd, opc$classd, opc$tstd,  { 172 }
    opc$mind, opc$maxd, opc$muli, opc$divi,  { 176 }
    opc$sqrts, opc$muls, opc$divs, opc$sqrtd,  { 180 }
    opc$muld, opc$divd, opc$adds5, opc$subs5,  { 184 }
    opc$truncsi5, opc$addd5, opc$subd5, opc$truncdi5,  { 188 }
    opc$nop, opc$fnop, opc$ipccnop, opc$shiftnop,  { 192 }
    opc$entry, opc$limit, opc$epilogue, opc$label,  { 196 }
    opc$label$, opc$seq, opc$mmt_seq, opc$join_bp,  { 200 }
    opc$ltorg, opc$tableb, opc$tablew, opc$tablel,  { 204 }
    opc$costly, opc$bugcheck, opc$none, opc$adj_move,  { 208 }
    opc$bc, opc$bnc, opc$bic, opc$load_sc,  { 212 }
    opc$lsr_pair, opc$loadbs, opc$loadws, opc$pl_loads,  { 216 }
    opc$pl_loadd, opc$loadq, opc$pl_adv12s, opc$pl_adv23s,  { 220 }
    opc$pl_unld3s, opc$pl_adv12d, opc$pl_adv23d, opc$pl_unld3d,  { 224 }
    opc$storeq, opc$lock, opc$unlock, opc$pg_negi,  { 228 }
    opc$pg_addi, opc$movi, opc$pg_movi, opc$pg_subi,  { 232 }
    opc$rsubi, opc$pg_rsubi, opc$pg_unldi, opc$negj,  { 236 }
    opc$pg_negj, opc$addj, opc$pg_addj, opc$movj,  { 240 }
    opc$pg_movj, opc$subj, opc$pg_subj, opc$rsubj,  { 244 }
    opc$pg_rsubj, opc$pg_unldj, opc$pa_negs, opc$pa_adds,  { 248 }
    opc$pa_moves, opc$pa_subs, opc$rsubs, opc$pa_rsubs,  { 252 }
    opc$pa_cvtsd, opc$roundsj, opc$pa_roundsj, opc$truncsj,  { 256 }
    opc$pa_truncsj, opc$cmpgts, opc$pa_cmpgts, opc$cmples,  { 260 }
    opc$pa_cmples, opc$cmpeqs, opc$pa_cmpeqs, opc$pa_adv12s,  { 264 }
    opc$pa_adv23s, opc$pa_unld3s, opc$pa_negd, opc$pa_addd,  { 268 }
    opc$pa_moved, opc$pa_subd, opc$pa_cvtds, opc$rounddj,  { 272 }
    opc$pa_rounddj, opc$truncdj, opc$pa_truncdj, opc$cmpgtd,  { 276 }
    opc$pa_cmpgtd, opc$cmpled, opc$pa_cmpled, opc$cmpeqd,  { 280 }
    opc$pa_cmpeqd, opc$pa_adv12d, opc$pa_adv23d, opc$pa_unld3d,  { 284 }
    opc$mulj, opc$pm_muls, opc$pm_adv12s, opc$pm_adv23s,  { 288 }
    opc$pm_unld3s, opc$recips, opc$sqrtrecips, opc$pm_muld,  { 292 }
    opc$pm_adv13d, opc$pm_unld3d, opc$recipd, opc$sqrtrecipd,  { 296 }
    opc$cmp_beq, opc$cmp_bne, opc$cmp_bgt, opc$cmp_ble,  { 300 }
    opc$cmp_bge, opc$cmp_blt, opc$cmp_bhi, opc$cmp_bls,  { 304 }
    opc$cmp_bhs, opc$cmp_blo, opc$cmp_bv, opc$cmp_bnv,  { 308 }
    opc$cmp_bd, opc$cmp_bnd, opc$be_tbit_beq, opc$be_tbit_bne,  { 312 }
    opc$add_beq, opc$add_bne, opc$add_bgt, opc$add_ble,  { 316 }
    opc$add_bge, opc$add_blt, opc$add_bhi, opc$add_bls,  { 320 }
    opc$add_bhs, opc$add_blo, opc$add_bv, opc$add_bnv,  { 324 }
    opc$add_bd, opc$add_bnd, opc$move_beq, opc$move_bne,  { 328 }
    opc$move_bn, opc$move_bnn, opc$move_bd, opc$move_bnd,  { 332 }
    opc$skp_eq_clr, opc$skp_ne_clr, opc$skp_gt_clr, opc$skp_le_clr,  { 336 }
    opc$skp_ge_clr, opc$skp_lt_clr, opc$skp_hi_clr, opc$skp_ls_clr,  { 340 }
    opc$skp_hs_clr, opc$skp_lo_clr, opc$skp_v, opc$skp_nv_clr,  { 344 }
    opc$skp_d, opc$skp_nd_clr, opc$add_jump, opc$move_jump,  { 348 }
    opc$be_asr, opc$be_clrins, opc$be_extracts, opc$be_extractu,  { 352 }
    opc$be_insert, opc$be_lsl, opc$be_lsr, opc$be_lsr_pair,  { 356 }
    opc$extracts, opc$mfcr, opc$mfsc, opc$mfsr,  { 360 }
    opc$mtcr, opc$mtsc, opc$mtsr, opc$physical,  { 364 }
    opc$pdtbl_va, opc$pdtbl_entry, opc$pitbl_va, opc$pitbl_entry,  { 368 }
    opc$pdc_va, opc$fdc_va, opc$fic_va, opc$fdc_entry,  { 372 }
    opc$fic_entry, opc$rsm, opc$ssm, opc$mtsm,  { 376 }
    opc$sync, opc$pa_prober, opc$pa_probew, opc$init_lb  { 380 }
    );
