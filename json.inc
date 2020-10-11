const
JSON_OPEN = #123;
JSON_CLOSE = #125;

// ***************************************************** JSON PARSER ROUTINES

function getJsonStart:word;
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

function findKeyPos(skey:string):word;
var inQuotes,keyParsing,gotKey,keyMatch,foundKey:boolean;
    key:string;
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
                
                ',',JSON_CLOSE,JSON_OPEN:begin
                        gotKey := false;
                        keyParsing := false;
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

function getJsonKeyValue(skey:Tstring):Tstring;
var c: char;
    inQuotes: boolean;
begin
    result[0] := #0;
    inQuotes := false;
    jsonPtr := findKeyPos(skey);
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
var srp,swp:byte;
    slen:byte;
    hex:word;
begin
    slen := Length(s);
    srp := 1;
    swp := 1;
    repeat
        if (s[srp] = '\') and (s[srp+1] = 'u') then begin
            hex := Hex2dec(s[srp+2]) shl 12;
            hex := hex + Hex2dec(s[srp+3]) shl 8;
            hex := hex + Hex2dec(s[srp+4]) shl 4;
            hex := hex + Hex2dec(s[srp+5]);
            if (hex > 191) and (hex<577) then s[swp] := char(utfMap192[hex-192])
                else s[swp] := '_';
            inc(srp,6);
            inc(swp);
        end else begin
            s[swp] := s[srp];
            inc(srp);
            inc(swp);
        end;
        
    until srp > slen;
    SetLength(s,swp-1);
end;

