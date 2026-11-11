{ lang/common/source/spos.ins.pas - SPOS_, source positions: the files
  and lines of the source and its include files (lang/common/source/
  spos.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: the variables' names.
}

{ TODO(pascal) spos.ins.pas is incomplete

  The rest of SPOS_'s interface is added when spos.pas and its users
  are translated. }

var
  { spos.pas's data, A5 0x14B874 (cc.m68k) + 0x2EFC (0x14E770): a word
    spos_$init_source_position clears (0x071D2E) and 15 units read
    (c_error, c_lex_pp, c_macro_utl, c_stmt_sem, c_syntax, cg_top,
    error_listing, opt_general, ...), comparing source positions with
    it: the position of a node that has none (il_utils's src_line and
    source_generated_top_level_node skip nodes whose +20 equals it;
    error_listing's print_error prints nothing for a line equal to
    it). }
  spos_2efc: extern integer;
