{ lang/lang/source/globals.ins.pas - the compilers' common prelude: the
  shared types, variables and the interfaces of the common units.

  About 126 of the units of cc.m68k and cc.a88k open exactly this
  sequence of inserts, globals.ins.pas first (their .blocks file lists,
  docs/core-plan.md), so this file includes the others, in that order.
  None of those units opens /sys/ins/base.ins.pas before it: what the
  prelude needs of base it declares itself.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
}

%include 'ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas';
%include 'lang/lang/source/glob_extern.ins.pas';
%include 'lang/lang/source/real_globals.ins.pas';
%include 'lang/lang/source/real_externals.ins.pas';
%include 'lang/lang/source/il.ins.pas';
%include 'lang/lang/source/target_properties.ins.pas';
%include 'lang/lang/source/cargs.ins.pas';
%include 'lang/lang/source/gspace.ins.pas';
%include 'lang/lang/source/strings.ins.pas';
%include 'lang/lang/source/token.ins.pas';
%include 'lang/lang/source/il_utils.ins.pas';
%include 'lang/lang/source/inc_list.ins.pas';
%include 'lang/lang/source/error_listing.ins.pas';
%include 'lang/lang/source/gen_utils.ins.pas';
%include 'lang/lang/source/add_node.ins.pas';
%include 'lang/lang/source/debug_sym_dmp.ins.pas';
%include 'lang/lang/source/globals_from_general.ins.pas';
%include 'lang/lang/source/globals_from_backend.ins.pas';
%include 'lang/lang/source/globals_from_frontend.ins.pas';
%include 'us/us/ins/lib.ins.pas';
%include 'lang/lang/source/outbin.ins.pas';
