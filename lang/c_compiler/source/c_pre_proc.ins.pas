{ lang/c_compiler/source/c_pre_proc.ins.pas - the C preprocessor's
  common types and the interface of its conditional reader (CR_,
  c_cond_read.pas).  Opened after c_globals.ins.pas (and
  c_externs.ins.pas) by the preprocessor's units (c_cond_read,
  c_general_utl, c_lex_pp, c_macro_read, c_macro_utl) and c_main.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: every name here.
}

{ TODO(pascal) c_pre_proc.ins.pas is incomplete

  The preprocessor's line, token and queue types and CR_'s headings
  are added as c_cond_read, c_lex_pp and c_macro_read are translated. }

const
  { The longest line the preprocessor handles: s_pick_off_name and
    find_id (c_macro_read) clip lengths to 4096. }
  pp_$line_max = 4096;

type
  { The characters of a line; its length is kept apart, a word (the
    general utilities take the length and the characters as separate
    parameters). }
  pp_$line_t = array [1..pp_$line_max] of char;
