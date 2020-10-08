program weather;
{$librarypath '../blibs/'}
// get your blibs here: https://gitlab.com/bocianu/blibs
uses atari, sysutils, crt, b_crt, fn_tcp, fn_sio, graph;
{$r resources.rc}

const
{$i const.inc}
JSON_OPEN = #123;
JSON_CLOSE = #125;

{$i datetime.inc}

type Tunits = (metric, imperial);

var IP_api: PChar = 'N:TCP://api.ipstack.com:80';
    OW_api: PChar = 'N:TCP://api.openweathermap.org:80';
    getLine: string;    
    ioResult: byte;
    responseBuffer: array [0..0] of byte absolute JSON_BUFFER;
    jsonStart, jsonEnd, jsonPtr: word;

    ip,country,country_code,long,lat,zip:Tstring;
    city:string[80];
    ccode_imperial: array [0..7] of string[2] = ('US', 'GB', 'IN', 'IE', 'CA', 'AU', 'HK', 'NZ');
    utfMap192: array [0..0] of byte absolute UTFTABLE192;
    windDir: array [0..7] of string[2] = ('N ', 'NE', 'E ', 'SE', 'S ', 'SW', 'W ', 'NW');
    weatherDesc, weatherMain, icon, temp, feels, pressure, humidity, windSpeed, windAngle, clouds:TString;
    unixTime:cardinal;
    timezone:integer;
    curDate, sunriseDate, sunsetDate : TdateTime;

    i: byte;
    k: char;
    
    units:TUnits;
    
    iconsD: array [0..8] of word = (
        0 * 10 + 0 * (40 * 24) + GFX, 
        1 * 10 + 0 * (40 * 24) + GFX, 
        2 * 10 + 0 * (40 * 24) + GFX,
        3 * 10 + 0 * (40 * 24) + GFX,
        0 * 10 + 1 * (40 * 24) + GFX,
        1 * 10 + 1 * (40 * 24) + GFX,
        2 * 10 + 1 * (40 * 24) + GFX,
        3 * 10 + 1 * (40 * 24) + GFX,
        0 * 10 + 2 * (40 * 24) + GFX
    );
    iconsN: array [0..8] of word = (
        1 * 10 + 2 * (40 * 24) + GFX,
        2 * 10 + 2 * (40 * 24) + GFX,
        2 * 10 + 0 * (40 * 24) + GFX,
        3 * 10 + 0 * (40 * 24) + GFX,
        0 * 10 + 1 * (40 * 24) + GFX,
        3 * 10 + 2 * (40 * 24) + GFX,
        2 * 10 + 1 * (40 * 24) + GFX,
        3 * 10 + 1 * (40 * 24) + GFX, 
        0 * 10 + 2 * (40 * 24) + GFX
    );
    colorsNTSC: array [0..3] of byte = ( $a6, $2c, $0f, $90 );
    colorsPAL:  array [0..3] of byte = ( $96, $ec, $0f, $80 );
    colors: array [0..0] of byte;
    
    olddli:pointer;
  
{$i interrupts.inc}    
{$i json.inc}    
  
    
// ***************************************************** HELPERS    
    
function isCCImperial(var cc:TString):boolean;
var i:byte;
    ic:string[2];
begin
    result := false;
    for i := 0 to 7 do begin
        ic := ccode_imperial[i];
        if (ic[1] = cc[1]) and (ic[2] = cc[2]) then exit(true);
    end;
end;

function GetDirName(angle:word):byte;
begin
    result:= Round(angle / 45.0) mod 8;
end;

function GetIconPtr(var icon:Tstring): word;
var iconNum,iconId:byte;
begin
    iconNum := (ord(icon[1])-48)*10 + (ord(icon[2])-48);
    iconId := 0;
    case iconNum of
        1: iconId := 0;
        2: iconId := 1;
        3: iconId := 2;
        4: iconId := 3;
        9: iconId := 4;
        10: iconId := 5;
        11: iconId := 6;
        13: iconId := 7;
        50: iconId := 8;
    end;
    if icon[3] = 'd' then result := iconsD[iconId]
    else result := iconsN[iconId];
end;

// ********************************************************* DATA PARSERS

procedure ParseLocation;
begin
    ip := getJsonKeyValue('ip');
    city := getJsonKeyValue('city');
    utfNormalize(city);
    country := getJsonKeyValue('country_name');
    country_code := getJsonKeyValue('country_code');
    lat := getJsonKeyValue('latitude');
    long := getJsonKeyValue('longitude');
    zip := getJsonKeyValue('zip');
    units := metric;
    if isCCImperial(country_code) then units := imperial;
end;


procedure ParseWeather;
begin
    timezone := StrToInt(getJsonKeyValue('timezone'));
    unixTime := StrToInt(getJsonKeyValue('dt'));
    unixtime := unixtime + timezone;
    UnixToDate(unixtime, curDate);
    unixTime := StrToInt(getJsonKeyValue('sunrise'));
    unixtime := unixtime + timezone;
    UnixToDate(unixtime, sunriseDate);
    unixTime := StrToInt(getJsonKeyValue('sunset'));
    unixtime := unixtime + timezone;
    UnixToDate(unixtime, sunsetDate);
    
    weatherMain := getJsonKeyValue('main');
    weatherDesc := getJsonKeyValue('description');
    icon := getJsonKeyValue('icon');
    temp := getJsonKeyValue('temp');
    feels := getJsonKeyValue('feels_like');
    pressure := getJsonKeyValue('pressure');
    humidity := getJsonKeyValue('humidity');
    windSpeed := getJsonKeyValue('speed');
    windAngle := getJsonKeyValue('deg');
    clouds := getJsonKeyValue('all');    
end;

// ***************************************************** NETWORK ROUTINES

function WaitAndParseRequest:byte;
begin
    result := TCP_WaitForData(100);
    jsonEnd := TCP_bytesWaiting;
    FN_ReadBuffer(@responseBuffer, jsonEnd);
    jsonStart := getJsonStart;
end;

function isIOError:boolean;
begin
    result := false;
    if ioResult <> 1 then begin // error
        Writeln('Connection Error: ', ioResult);
        Readkey;
        result := true;
    end;
end;

procedure GetWeather;
begin
    ioResult := TCP_Connect(OW_api);
    if isIOError then exit;

    getLine:='GET /data/2.5/weather?zip=';
    getLine:=Concat(getLine,zip);
    getLine:=Concat(getLine,',');
    getLine:=Concat(getLine,country_code);
    getLine:=Concat(getLine,'&units=');
    if units = metric then getLine:=Concat(getLine,'metric')
    else getLine:=Concat(getLine,'imperial');
    getLine:=Concat(getLine,'&appid=2e8616654c548c26bc1c86b1615ef7f1 HTTP/1.1'#13#10'Host: api.openweathermap.org'#13#10'Cache-Control: no-cache;'#13#10#13#10);
    TCP_SendString(getLine);

    ioResult := WaitAndParseRequest;
    if isIOError then exit;
    TCP_Close;    
    ParseWeather;
end;

procedure GetLocation;
begin
    getLine:='GET /check?access_key=9ba846d99b9d24288378762533e00318&fields=ip,country_code,country_name,city,latitude,longitude,zip HTTP/1.1'#13#10'Host: api.ipstack.com'#13#10'Cache-Control: no-cache;'#13#10#13#10;
    TCP_SendString(getLine);
   
    ioResult := WaitAndParseRequest;
    if isIOError then exit;
    TCP_Close;
    ParseLocation;
end;

// ***************************************************** GUI ROUTINES

procedure WaitForOverride();
var timeout:byte;
    c:char;
begin
    CursorOff;
    timeout := 150;
    c:=#0;
    Write('3...');
    repeat 
        pause;
        if keypressed then c := Readkey;
        dec(timeout);
        if timeout = 100 then begin
            DelLine; Write('2...');
        end;
        if timeout = 50 then begin
            DelLine; Write('1...');
        end;
    until (c <> #0) or (timeout = 0);
    DelLine;
    if c = #32 then Writeln('Not yet implemented. Blame author.');
    CursorOn;
end;

procedure WriteDate(date: TDateTime);
begin
    if date.day < 10 then Write(0);
    Write(date.day,'-');
    if date.month < 10 then Write(0);
    Write(date.month,'-',date.year);
end;

procedure WriteTime(date: TDateTime);
var hour:byte;
begin
    hour := date.hour;
    if units = imperial then hour := hour24to12(hour);
    if hour < 10 then Write(0);
    Write(hour,':');
    if date.minute < 10 then Write(0);
    Write(date.minute);
    if units = imperial then begin
        if date.hour > 12 then Write(' am')
            else Write(' pm');
    end;
    //if date.second < 10 then Write(0);
    //Write(date.second);
end;

procedure WriteTempUnit;
begin
    if units = metric then Write('^C');
    if units = imperial then Write('^F');
end;

procedure WriteSpeedUnit;
begin
    if units = metric then Write('m/s');
    if units = imperial then Write('mph');
end;

procedure DrawIcon(src,dest: word);
var row,col:byte;
begin
    row:=0;
    repeat 
        col:=0;
        repeat
            poke(dest+col,peek(src+col));
            inc(col)
        until col = 10;
        inc(src,40);
        inc(dest,40);
        inc(row);
    until row = 24;
end;

procedure Stamp(src,dest:word;w,h:byte);
var row,col:byte;
begin
    row:=0;
    repeat 
        col:=0;
        repeat
            poke(dest+col,peek(src+col));
            inc(col)
        until col = w;
        inc(src,40);
        inc(dest,40);
        inc(row);
    until row = h;
end;

function PutChar(c:char; dest: word; color: byte):byte;
var row,bit,ic:byte;
    src,dc:word;
begin
    row := 0;
    src := FONT + (Atascii2Antic(ord(c)) shl 3);
    repeat 
        dc := 0;
        bit := 0;
        ic := peek(src);
        repeat 
            if (ic and 128) <> 0 then dc := dc or color;
            ic := ic shl 1;
            dc := dc shl 2;
            inc(bit);
        until bit = 8;
        poke(dest,peek(dest) or hi(dc));
        poke(dest+1,peek(dest+1) or lo(dc));
        inc(src);
        inc(dest,40);
        inc(row);
    until row = 8;
end;

procedure PutString(var s:string;dest: word;color:byte);
var i:byte;
begin
    i:=1;
    while (i<=Length(s)) do begin
        putChar(s[i],dest,color);
        inc(dest,2);
        inc(i);
    end;
end;

procedure PutCString(var s:string;dest: word;color:byte);
var l:byte;
begin
    l:=Length(s);
    if l>20 then SetLength(s,20)
    else begin
        dest := dest + (20 - l)
    end;
    PutString(s,dest,color);
end;

function PutSymbol(c:char; dest: word):byte;
var x,w,h:byte;
    src,off:word;
begin
    result:=0;
    w := 3;
    h := 19;
    src:= GFX + 74 * 40;
    case c of
        '0'..'9': begin 
            x:=(ord(c)-48)*3;
            if c='1' then begin
                dec(w);
                inc(x);
            end;
        end;
        'F': begin
            x:=11*3;
        end;
        'C': begin
            x:=12*3;
        end;
        '^': begin
            x:=10*3+1;
            dec(w);
            h:=5;
        end;
        '.': begin
            x:=10*3+1;
            dec(w);
            h:=3;
            off:=40*16;
            inc(src,off);
            inc(dest,off)
        end;
        '-': begin
            x:=10*3+1;
            dec(w);
            h:=2;
            off:=40*8;
            inc(src,off);
            inc(dest,off)
        end;
    end;
    inc(src,x);
    Stamp(src,dest,w,h);
    exit(w);
end;

procedure PrintTemperature(var s:string;dest: word);
var i,w:byte;
begin
    i:=1;
    while (i<=Length(s)) do begin
        w := putSymbol(s[i],dest);
        inc(dest,w);
        inc(i);
    end;
end;

procedure ShowLocation;
begin
    Writeln('Your IP: ',ip);
    Writeln('Location: ',country,', ',city);
    Writeln('latitude: ',lat);
    Writeln('longitude: ',long);
    Writeln('zip-code: ',zip);
    Write('units: ');
    if units = metric then Writeln('metric')
    else Writeln('imperial');
    Writeln;
    Writeln('Press '+'SPACE'*+' to override location');
    WaitForOverride;
end;

procedure ShowWeather;
begin
    Pause;
    SDLSTL := DLIST;
    SetIntVec(iDLI, @dli);
    nmien := $c0; 
    chbas := Hi(FONT);
    Fillbyte(pointer(VRAM),2240,0);

    if palnts = 0 then colors := colorsNTSC
        else colors := colorsPAL;

    color0 := colors[0];
    color1 := colors[1];
    color2 := colors[2];
    color4 := (colors[3] and $f0);

    // set backgrond color based on icon type
    if icon[3] = 'd' then color4 := (colors[3] and $f0) or $0a;

    // top of screen - GFX part
    savmsc := VRAM;
    
    getLine := Concat(city, ', ');
    getLine := Concat(getLine, country_code);
    PutCString(getLine, savmsc + 0 * 40,3);
   
    DrawIcon(GetIconPtr(icon),savmsc+8*40);

    if Length(temp)>5 then setLength(temp,5); 
    if units = metric then getLine := Concat(temp, '^C') 
        else getLine := Concat(temp, '^F');

    PrintTemperature(getLine, savmsc+10*40 + 12);
    
    i := 40 - Length(pressure) shl 1;
    PutString(pressure, savmsc + 9 * 40 + i,3);
    getLine := 'hPa';
    PutString(getLine, savmsc + 17 * 40 + 34,3);
    
    PutCString(weatherDesc, savmsc + 36 * 40,1);
    PutCString(weatherDesc, savmsc + 35 * 40,3);
    
    // bottom - TXT part
    savmsc := VRAM + 44 * 40;
    lmargin := 12;
    Gotoxy(1,1);
    
    Writeln;    
    Write('Feels like: ', feels);
    WriteTempUnit;
    Writeln;
    Write('Wind: ',windSpeed,' ');
    WriteSpeedUnit;
    Write(' ');
    Write(windDir[getDirName(StrToInt(windAngle))]);
    Writeln;
    Writeln;
    Writeln('Humidity: ', humidity, '%');
    Writeln('Clouds:   ', clouds, '%');
    Writeln;
    Write('Sunrise: ');
    WriteTime(sunriseDate);
    Writeln;
    Write('Sunset:  ');
    WriteTime(sunsetDate);
    lmargin:=1;
    Writeln;
    Writeln;
    Writeln;    
    Write('F'*+'orecast   '+'U'*+'nits    '+'R'*+'efresh     '+'Q'*+'uit');
end;


// **********************************************************************
// *******************************************************************************  MAIN
// **********************************************************************

begin

    GetIntVec(iDLI, olddli);
    Writeln('Connecting to ipstack.com');
    ioResult := TCP_Connect(IP_api);
    if isIOError then exit;
    TCP_AttachIRQ;

    Writeln('Checking your ip and location');
    GetLocation;
    ShowLocation;

    Writeln;
    Writeln('Connecting to openweathermap.org');
    Writeln('Checking weather for your location');
    CursorOff;

    GetWeather;
    ShowWeather;

    repeat

        repeat 
            pause;
            atract := 1;
        until KeyPressed;

        k := readkey;
        case k of
            'r', 'R': begin 
                GetWeather;
                ShowWeather;
            end;
            'u', 'U': begin
                if units = metric then units := imperial else units := metric;
                GetWeather;
                ShowWeather;
            end;
        end;

    until (k = 'q') or (k = 'Q');

    TCP_DetachIRQ;
    TextMode(0);
end.
