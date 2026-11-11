module c_get_rlen;

type
    c_type_node_t = record
        unk0 : integer;            { +0 }
        kind : integer;            { +2 }
        len  : integer;            { +4 }
    end;
    c_type_node_p = ^c_type_node_t;
    c_type_t = record
        node : c_type_node_p;      { +0 }
        pad  : array [1..12] of char;
        size : integer32;          { +16 }
    end;

function get_rlen(var t : c_type_t) : integer;
begin
    case t.node^.kind of
        210:      get_rlen := 0;
        135, 130: get_rlen := 5;
        123:      get_rlen := t.node^.len;
        126, 127: get_rlen := 9;
        otherwise
            if t.size = 1 then get_rlen := 1
            else if t.size = 2 then get_rlen := 2
            else if t.size = 4 then get_rlen := 4
            else get_rlen := 11;
    end;
end;
