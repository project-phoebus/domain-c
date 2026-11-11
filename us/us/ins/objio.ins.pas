{ us/us/ins/objio.ins.pas - Apollo's internal object-file I/O insert
  (//us/us/ins).  No copy survives.

  Not known from the original: everything about its contents.
}

{ TODO(pascal) objio.ins.pas not reconstructed yet

  Declarations are added as the units that use them are translated. }

type
  obj_$image_name_t = array [1..32] of char;

{ OBJ_$GET_MY_OBJ_INFO - the running compiler image's name (32
  characters), edit number and time stamp; failed set when they cannot
  be read.  lang/bind/source/objio.pas (cc.m68k 0x0883EA, A5).  Read off
  its frame (12 the name, 16 a word, 20 a longword, 24 a byte, all by
  address; 8 is not read) and its one call, cargs.pas
  get_compiler_image_timestamp_and_edit_number (0x0B48E8: 8 the word
  constant 1234).

  Not known from the original: the parameters' names; what the first
  one is. }
procedure obj_$get_my_obj_info(
    in p1: integer;
    out name: obj_$image_name_t;
    out edit: integer;
    out timestamp: integer32;
    out failed: boolean); extern;
