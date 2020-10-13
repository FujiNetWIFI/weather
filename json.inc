const
    JSON_OPEN = #123;
    JSON_CLOSE = #125;

var
    utfMap192: array [0..0] of byte absolute UTFTABLE192;
    jsonRoot, jsonStart, jsonEnd, jsonPtr: word;

// ***************************************************** JSON PARSER ROUTINES

function GetJsonRoot:word;
var ptr:word;
begin
    result := $ffff;
    ptr := 0;
    repeat
        if responseBuffer[ptr] = 13 then
            if responseBuffer[ptr+1] = 10 then
                if responseBuffer[ptr+2] = 13 then
                    if responseBuffer[ptr+3] = 10 then exit(word(ptr+4));
        inc(ptr);
    until ptr = jsonEnd;
end;

function FindKeyPos(skey:Tstring):word;
var inQuotes,keyParsing,gotKey,keyMatch,foundKey:boolean;
    key:Tstring;
    level:byte;
    c: char;
begin
    inQuotes := false;
    keyParsing := false;
    foundKey := false;
    gotKey := false;
    level := $ff;
    jsonPtr := jsonStart;
    repeat
        c := char(responseBuffer[jsonPtr]);
        if not inQuotes then begin     // out of Quotes

            case c of
                '"':begin
                        if not gotKey then begin
                            keyParsing := true;
                            key[0] := #0;
                            keyMatch := true;
                        end;
                        inQuotes := true;
                    end;
                
                ',':begin
                        gotKey := false;
                        keyParsing := false;
                    end;

                JSON_OPEN:begin
                        gotKey := false;
                        keyParsing := false;
                        inc(level);
                    end;

                JSON_CLOSE:begin
                        gotKey := false;
                        keyParsing := false;
                        dec(level);
                        if level = $ff then exit(0);
                    end;
                
                ':':begin
                        if gotKey and keyMatch then exit(word(jsonPtr + 1));
                    end;
            end;
        
        end else begin                 // in Quotes

            if c = '"' then begin               // ending quote
                if keyParsing then begin
                    gotKey := true;
                    keyMatch := keyMatch and (Length(key) = Length(skey));
                end;
                keyParsing := false;
                inQuotes := false;
            end else begin                      // other letter
                if keyParsing then begin
                    Inc(key[0]);
                    if skey[Length(key)] <> c then keyMatch := false;
                    key[Length(key)] := c;
                end;
            end;
        
        end;
        
        Inc(jsonPtr);
    until jsonPtr = jsonEnd;
    result:=0;

end;

function GetElementsCount: byte;
var inQuotes,inObject, hasContent:boolean;
    alevel,olevel:byte;
    c: char;
begin
    alevel := $ff;
    olevel := $ff;
    result := 0;
    inQuotes := false;
    inObject := false;
    hasContent := false;
    jsonPtr := jsonStart;

    repeat
        c := char(responseBuffer[jsonPtr]);
        if not inQuotes then begin     // out of Quotes

            case c of
                '"':begin
                        inQuotes := true;
                        hasContent := true;
                    end;
                JSON_OPEN:begin
                        inc(olevel);
                        inObject := true;
                        hasContent := true;
                    end;
                JSON_CLOSE:begin
                        dec(olevel);
                        if olevel = $ff then inObject := false;
                    end;
                
                ',':begin
                        if (alevel = 0) and (not inObject) then begin
                            inc(result);
                        end;
                    end;

                '[':begin
                        if not inObject then begin
                            inc(alevel);
                            if alevel = 0 then hasContent := false
                                else hasContent := true;
                        end;
                    end;

                ']':begin
                        if not inObject then begin
                            dec(alevel);
                            if alevel = $ff then begin
                                if hasContent then inc(result);
                                exit(result);
                            end;
                        end;
                    end;
            end;
        end else                            // not inQuotes
            if c = '"' then begin           // ending quote
                inQuotes := false;
            end;
        
        Inc(jsonPtr);
    until (jsonPtr = jsonEnd);
end;

function FindIndex(i:byte):word;
var inQuotes,inObject,found:boolean;
    element:byte;
    alevel,olevel:byte;
    c: char;
begin
    alevel := $ff;
    olevel := $ff;
    element := 0;
    found := false;
    inQuotes := false;
    inObject := false;
    jsonPtr := jsonStart;

    repeat
        c := char(responseBuffer[jsonPtr]);
        if not inQuotes then begin     // out of Quotes

            case c of
                '"':begin
                        inQuotes := true;
                    end;
                JSON_OPEN:begin
                        inc(olevel);
                        inObject := true;
                    end;
                JSON_CLOSE:begin
                        dec(olevel);
                        if olevel = $ff then inObject := false;
                    end;
                
                ',':begin
                        if (alevel = 0) and (not inObject) then begin
                            inc(element);
                            if element = i then found := true;
                        end;
                    end;

                '[':begin
                        if not inObject then begin
                            inc(alevel);
                            if (alevel = 0) and (element = i) then found := true;
                        end;
                    end;

                ']':begin
                        if not inObject then begin
                            dec(alevel);
                            if alevel = $ff then exit(0);
                        end;
                    end;
            end;
        end else                            // not inQuotes
            if c = '"' then begin           // ending quote
                inQuotes := false;
            end;
        
        Inc(jsonPtr);
    until found or (jsonPtr = jsonEnd);
    result := 0;
    if found then result := jsonPtr;
end;

function GetJsonKeyValue(skey:Tstring):Tstring;
var c: char;
    inQuotes: boolean;
begin
    result[0] := #0;
    inQuotes := false;
    jsonPtr := FindKeyPos(skey);
    //writeln('key at: ', jsonPtr);
    if jsonPtr <> 0 then begin
        repeat
            c := char(responseBuffer[jsonPtr]);
            case c of 
                '"':
                    begin
                        if not inQuotes then begin
                            inQuotes := true;
                        end else begin
                            exit(result);
                        end;
                    end;
                ',', JSON_CLOSE, ']':
                    begin
                        if not inQuotes then exit(result);
                    end;
            else 
                Inc(result[0]);
                result[Length(result)] := c;
            end;
            inc(jsonPtr);
        until jsonPtr = jsonEnd;
    end;
    Writeln('Key not found: ', skey);
    result := '';
end;

function FollowKey(s:Tstring):word;
begin
    jsonPtr := FindKeyPos(s);
    if jsonPtr <> 0 then begin
        jsonStart := jsonPtr;
    end;
    result := jsonPtr;
end;

function FollowIndex(i:byte):word;
begin
    jsonPtr := FindIndex(i);
    if jsonPtr <> 0 then begin
        jsonStart := jsonPtr;
    end;
    result := jsonPtr;
end;

// ***************************************************** JSON HELPERS

procedure EscapeJson(var s:string);
var i: byte;
    c: char;
begin
    i := 0;
    while (i < Length(s)) do begin
        Inc(i);
        c := s[i];
        case c of  
            JSON_OPEN: s[i] := '<';
            JSON_CLOSE: s[i] := '>';
        end;
    end;
end;

procedure DumpJson;
var s:string[100];
    jlen, tomove:word;
begin
    jlen := jsonEnd - jsonStart;
    jsonPtr := jsonStart;
    while (jlen>0) do begin
        tomove := jlen;
        if jlen>100 then tomove := 100;
        s[0] := char(tomove);
        Move(responseBuffer[jsonPtr],s[1],tomove);
        jlen := jlen - tomove;
        jsonPtr := jsonPtr + tomove;
        EscapeJson(s);
        Write(s);
    end;
    Writeln;
end;

function Hex2Dec(c:char):byte;
begin
    result:=0;
    case c of
        '0'..'9': begin 
            exit(byte(byte(c)-48));
        end;
        'a'..'f': begin 
            exit(byte(byte(c)-87));
        end;
        'A'..'F': begin 
            exit(byte(byte(c)-55));
        end;
    end;
end;

procedure UtfNormalize(var s:string);
var readHead, writeHead :byte;
    utfLen:byte;
    hex:word;
begin
    utfLen := Length(s);
    readHead := 1;
    writeHead := 1;
    repeat
        if (s[readHead] = '\') and (s[readHead + 1] = 'u') then begin  // detect and decode \uXXXX codes
            hex := Hex2dec(s[readHead+2]) shl 12;
            hex := hex + Hex2dec(s[readHead + 3]) shl 8;
            hex := hex + Hex2dec(s[readHead + 4]) shl 4;
            hex := hex + Hex2dec(s[readHead + 5]);
            if (hex > 191) and (hex < 577) then s[writeHead] := char(utfMap192[hex - 192])
                else s[writeHead] := '_';
            inc(readHead,6);
            inc(writeHead);
        end 
        else 
            if byte(s[readHead]) > $c1 then begin                // detect and decode inline symbols
                hex := word(((byte(s[readHead]) - $c2) shl 6)) + word(s[readHead + 1]);
                if (hex > 191) and (hex < 577) then s[writeHead] := char(utfMap192[hex - 192])
                    else s[writeHead] := '_';
                inc(readHead, 2);
                inc(writeHead);
            end else begin
                s[writeHead] := s[readHead];
                inc(readHead);
                inc(writeHead);
            end;
    until readHead > utfLen;
    SetLength(s,writeHead - 1);
end;

