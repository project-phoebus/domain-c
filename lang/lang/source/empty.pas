{ empty - an empty module: no routines, no data, no insert opened.

  Image addresses (DOMAIN C 6.9): the unit is in both binaries with no
  routine records and no A5.  Its .blocks record (version 4) has only
  the module block, named `empty', and the file list is the unit's own
  path.  The file record's code start, cc.m68k 0x0FDEA4 (section
  codegen$proc) and cc.a88k 0x101194 (.text), falls inside other code
  (cc.m68k: cg_top.pas's return_proc, 0x0FD9D8..0x0FE167; cc.a88k: the
  ISC routines without records, docs/survey.md open item 1), so the
  unit contributes no bytes there: the survey's 4396 and 293168 bytes
  are the distances to the next unit's start, not the unit's.  In
  cc.m68k it was compiled into the m68k code generator's code section
  (codegen$proc, as cg_top, cg_tree and the other cg_ units are); in
  cc.a88k into .text.  The module heading names no section, as the
  other units' headings here do not.

  Not known from the original: why the module exists (a placeholder
  that the m68k and a88k builds bind in the code generator's place,
  perhaps); whether its source held anything compiled away (comments,
  constants or types that leave no code or data).
}

module empty;
