{ lang/lang/source/gen_utils.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/gen_utils.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ GEN_UTILS - code generation helpers: address constants, sections,
  transfer vectors, external references and the libraries the program is
  bound with.  gen_utils.pas (cc.m68k 0x07C3C4..0x07D4C6).  Headings from
  the routines' frames and their call sites (tools/cc_params.py): a word
  or longword read from the frame is a value (val_param); a slot moved to
  an address register and dereferenced is a pointer passed by value
  (univ_ptr until its target type is known); a function's result is a
  pointer in A0 when its callers read A0 after the call.

  Not known from the original: every parameter name and most types. }

{ TODO(pascal) gen_utils headings are read off the frames only

  The parameters' types and modes (univ_ptr for every pointer, by-value
  for every slot) are the conservative reading; refine them when
  gen_utils.pas and its callers are translated. }

{ INLIB_ERROR - the error routine OBJUTIL_ reports through (bind's
  inliberror in the C compiler).  0x07C3C4. }
procedure inlib_error(
    severity: integer32;
    code: integer32;
    name: univ_ptr;
    msg: univ_ptr); options(val_param); extern;

{ INLIB_INIT, INLIB_TERM - start and end reading the libraries the
  program is bound with (-inlib).  0x07C552, 0x07C582. }
procedure inlib_init; extern;
procedure inlib_term; extern;

{ INLIB_ADD - a library to read: its name and the name's length.
  0x07C59C. }
procedure inlib_add(
    name: univ_ptr;
    len: integer); options(val_param); extern;

{ The address constants.  0x07C5C6, 0x07C63E, 0x07C8EC, 0x07C9F8,
  0x07CD52, 0x07D414. }
function make_abs_addr_con(
    kind: integer;
    p: univ_ptr;
    v: integer32): univ_ptr; options(val_param); extern;

function check_for_addr_con(
    kind: integer;
    p: univ_ptr;
    v: integer32;
    q: univ_ptr): univ_ptr; options(val_param); extern;

function get_addr_con(
    kind: integer;
    p: univ_ptr;
    q: univ_ptr;
    v: integer32;
    flag: boolean): univ_ptr; options(val_param); extern;

function make_new_addr_con(
    kind: integer;
    p: univ_ptr;
    v: integer32;
    w: integer32;
    flag: boolean): univ_ptr; options(val_param); extern;

function get_proc_addr_con(
    kind: integer;
    p: univ_ptr;
    v: integer32;
    w: integer32): univ_ptr; options(val_param); extern;

function gen_utils_$alloc_new_addr_con(
    kind: integer;
    v: integer32;
    w: integer32;
    p: univ_ptr): univ_ptr; options(val_param); extern;

{ CHANGE_NAME_LOWER_CASE - 0x07C966. }
procedure change_name_lower_case(
    p: univ_ptr;
    q: univ_ptr); options(val_param); extern;

{ FIND_AC_DSECT - 0x07CE7A. }
function find_ac_dsect(
    p: univ_ptr): univ_ptr; options(val_param); extern;

{ GET_XDYNM_PTR, MAKE_XDYNM_PTR - 0x07CECE, 0x07CF2E. }
function get_xdynm_ptr(
    v: integer32;
    p: univ_ptr): univ_ptr; options(val_param); extern;

function make_xdynm_ptr(
    v: integer32;
    w: integer32): univ_ptr; options(val_param); extern;

{ CHECK_SECTION_NAME - 0x07D0C4. }
function check_section_name(
    p: univ_ptr): univ_ptr; options(val_param); extern;

{ ADD_PSECT, ADD_DSECT - enter a code (procedure) or data section of the
  name (an identifier node); the section's node.  0x07D15C, 0x07D1D4;
  il.pas's initialize_module enters `.text' and `.data'. }
function add_psect(
    name: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

function add_dsect(
    name: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ GET_TRANSFER_VECTOR - 0x07D2EE. }
function get_transfer_vector(
    p: univ_ptr): univ_ptr; options(val_param); extern;

{ GET_EXTERNAL_REF - 0x07D3B6. }
procedure get_external_ref(
    p: univ_ptr); options(val_param); extern;
