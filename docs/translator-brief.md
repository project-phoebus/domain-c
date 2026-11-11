# Brief for the parallel translators

The standing instructions for the agents that translate units in parallel
(at most three at a time).  Your launch message names your units, in
priority order.  Everything else is here.

## Setup

- You work in your own git worktree on your own branch.  `ctape/` (the
  binaries) is git-ignored and absent from a worktree: first run
  `ln -s /Users/toshok/src/project-phoebus/domain-c/ctape ctape` at the
  worktree's top (never commit the link; it is ignored).
- `export DPC=~/src/domainos-archeology/domain-pascal/target/debug/dpc`
  (cc_check.sh's default).  Never modify the domain-pascal or source
  repositories.  Never push.  Commit on your branch after each unit; end
  every commit message with the line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Work unattended: decide conservatively and append questions for the
  owner to `docs/questions.md` instead of stopping.

## Read first

`README.md`, `docs/core-plan.md` (especially "For the parallel
translators"), `docs/rev889-patterns.md`, `docs/dpc-gaps.md`, and the
finished units: `lang/lang/source/gspace.pas`, `strings.pas`, `prtsub.pas`,
`target_properties.pas`, `il.pas`, `lang/common/source/std.pas`, `diag.pas`.
Background on method (kernel-oriented; the archivist rules apply):
`~/src/domainos-archeology/source/docs/pascal-translation-rules.md`.
Language reference:
`~/src/domainos-archeology/domain-pascal/docs/000792-A01_Domain_Pascal_Language_Reference_Dec90.txt`.

## The job, per unit

1. `docs/routines-cc.m68k.md` (and `routines-cc.a88k.md`) give the unit's
   routines, addresses, nesting levels and its inserts in the order opened:
   reproduce that `%include` list exactly (`//us/us/sys/ins/x` as
   `/sys/ins/x`, everything else rooted at the tree: `lang/...`,
   `us/us/ins/...`; a unit opening the prelude includes
   `lang/lang/source/globals.ins.pas`, which brings its 22 members).
   Create stubs for inserts that do not exist yet, in the style of the
   prelude's stubs, and fill them as you go.
2. Disassemble each routine (`tools/cc_dis.py BINARY NAME`) and walk every
   instruction.  The disassembly is the truth.  `tools/cc_params.py
   BINARY UNIT` gives frame slots, A5 loads and call sites;
   `tools/cc_globals.py BINARY --unit X` the unit's shared cells;
   `tools/cc_data.py BINARY ADDR LEN` initial data from .rwdi.
3. Write the unit file in the house style: the header comment (purpose,
   the address table `0xMMMMMM  0xAAAAAA  name` for both binaries, or
   `--------` for a binary without the unit; A5 and module data), `module`
   with the unit's .blocks module name, the includes, `define` for
   variables the inserts declare extern, then each routine with its header
   comment (address, length, the instructions that decide each construct,
   "Not known from the original").  Nested routines inside their parent.
   A module-level routine that does not load A5 is `internal`.
4. **Best effort**: the code must do what the image does; byte identity is
   not required (the binaries are Pascal Rev 8.89).  Read dpc's output
   (`tools/coff_compare.py --keep DIR --binary B FILE.pas -- -I $PWD`)
   for the routines where a mistake is easy (comparisons, signedness,
   argument order, loop bounds, record offsets).
5. Gate: `tools/cc_check.sh FILE.pas` must show `errors=0` for both
   binaries (or the one that has the unit) and no address-table
   complaint.  A construct dpc refuses that the reference allows and the
   image needs: keep it, add a numbered entry with a reproducer to
   `docs/dpc-gaps.md` and a scratch rewrite line to
   `tools/cc_gap_rewrites.txt`.
6. New Rev 8.89 code-generation forms: add them to
   `docs/rev889-patterns.md` with addresses.

## Shared files

- Your own units' inserts are yours.  The prelude's inserts
  (`lang/lang/source/*.ins.pas` included by globals.ins.pas) and other
  shared inserts may need a field added or a type narrowed: make the
  smallest change, keep it in its own commit whose message begins
  `core:`, and say why.  Do not rename or re-lay-out shared declarations;
  propose that in `docs/questions.md` instead.  The lead merges branches
  and resolves conflicts.
- Update the README status table and `docs/core-plan.md`'s table rows for
  your units.
- Lessons from the first wave's merge:
  - Before creating an insert outside your area, check whether it exists
    on `main` (your branch starts from it); if not, keep your stub
    minimal (only what your units use), since another translator may be
    creating the same file.  Take names from the owner's insert when it
    exists, rather than inventing a second name for the same cell.
  - An insert that some unit opens without the inserts it would otherwise
    lean on must declare its own types (lang/lang token.ins.pas is opened
    by lang/common token.pas without strings.ins.pas).
  - When you change a shared heading's parameter modes or types, grep
    every caller in the tree (`git grep -n 'name('`) and fix them in the
    same commit.
  - New numbered entries (dpc gaps, patterns, questions) will collide with
    other branches' numbers; that is fine, the lead renumbers at merge.
    Cite them in unit comments as `docs/dpc-gaps.md N` so they can be
    found.
  - **dpc takes a routine's parameter names and types from its first
    declaration**, which for a global routine is the insert's heading;
    the unit's own heading is not consulted.  When you define a routine
    whose insert heading has placeholder names (p1, p4, ...), correct
    the heading (and its callers) rather than renaming in the body.
  - **Regions a gap rewrite removes are not checked by the gate.**  Also
    run `tools/cc_typecheck.sh FILE.pas` (dpc --check-only on the
    unrewritten unit, with only the inserts' rewrites applied, so a
    shared insert's gap does not stop it early): it stops before code generation, so it
    type-checks everything; any error that is not one of the logged
    gaps' messages is a real mistake.  (A merge found two calls and a
    renamed field hidden in a gap-25 region.)
  - **objdump prints indexed displacements in hex without `0x`**:
    `%a5@(12,%d1:l)` is 0x12, while a plain `%fp@(12)` is decimal 12.
    `tools/cc_dis.py` now rewrites the indexed ones as `0x12`/`-0x11`;
    if you read raw objdump output (or your own scripts' output), mind
    the difference.
  - Keep your helper scripts and scratch files in a subdirectory of the
    session scratchpad named after you (e.g. `scratchpad/transN/`); the
    scratchpad is shared and translators have overwritten each other's
    files.
  - Do not hand units to subagents of your own: do the work yourself.
    (In the second wave a translator's subagent reported a unit done and
    committed when nothing existed.)  Report only what `git log` and the
    files on your branch show.
  - The full gate takes several minutes: run `tools/cc_check.sh FILE.pas`
    for the units you touch, and the full gate once before your report
    (in the background if your tool times out).

## Report

When your units are done or you are running out of room: everything
committed, gate clean.  Reply with: units finished (routines each),
units started but unfinished and where, core changes made, dpc gaps and
patterns added, questions added, and anything the lead must know to
merge.
