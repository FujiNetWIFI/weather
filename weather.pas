program weather;
{$librarypath '../blibs/'}
// get your blibs here: https://gitlab.com/bocianu/blibs
uses atari, sysutils, crt, b_crt, fn_tcp, fn_sio;
{$r resources.rc}

{ $define fake}

const
{$i const.inc}
{$i datetime.inc}

type Tunits = (metric, imperial);

var IP_api: PChar = 'N:TCP://api.ipstack.com:80';
    OW_api: PChar = 'N:TCP://api.openweathermap.org:80';
    getLine: string;    
    ioResult: byte;
    responseBuffer: array [0..0] of byte absolute JSON_BUFFER;
    jsonStart, jsonEnd, jsonPtr: word;

    ip,country,country_code,longitude,latitude,zip:Tstring;
    city:string[80];
    ccode_imperial: array [0..7] of string[2] = ('US', 'GB', 'IN', 'IE', 'CA', 'AU', 'HK', 'NZ');
    utfMap192: array [0..0] of byte absolute UTFTABLE192;
    windDir: array [0..7] of string[2] = ('N ', 'NE', 'E ', 'SE', 'S ', 'SW', 'W ', 'NW');
    monthNames: array [0..11] of string[5] = (' Jan ', ' Feb ', ' Mar ', ' Apr ', ' May ', ' Jun ', ' Jul ', ' Aug ', ' Sep ',' Oct ',' Nov ',' Dec ');
    dowNames: array [0..6] of string[3] = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
    tmp, weatherDesc, icon, temp, feels, pressure, humidity, windSpeed, windAngle, clouds, dewpoint, visibility:TString;
    unixTime:cardinal;
    timezone:integer;
    curDate, sunriseDate, sunsetDate : TdateTime;

    i,menuDelay: byte;
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
    logo: array [0..13*4-1] of byte = (
    $00, $00, $00, $00, $00, $5a, $5b, $5c, $00, $00, $00, $00, $00, 
    $40, $41, $42, $43, $44, $54, $55, $56, $4a, $4b, $4c, $4d, $4e, 
    $45, $46, $47, $48, $49, $57, $58, $59, $4f, $50, $51, $52, $53, 
    $00, $00, $00, $00, $00, $00, $5d, $5e, $5f, $00, $00, $00, $00
    );

    colorsNTSC: array [0..3] of byte = ( $a6, $2c, $0f, $90 );
    colorsPAL:  array [0..3] of byte = ( $96, $ec, $0f, $80 );
    colors: array [0..0] of byte;
    cityColor, textColor, menuColor: byte;

    scrWidth: byte;
    descDir, descOffset, descScroll, descHSC: byte;
    
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
    latitude := getJsonKeyValue('latitude');
    longitude := getJsonKeyValue('longitude');
    zip := getJsonKeyValue('zip');
    units := metric;
    if isCCImperial(country_code) then units := imperial;
end;


procedure ParseWeather;
begin
    timezone := StrToInt(getJsonKeyValue('timezone_offset'));
    unixTime := StrToInt(getJsonKeyValue('dt'));
    unixtime := unixtime + timezone;
    UnixToDate(unixtime, curDate);
    unixTime := StrToInt(getJsonKeyValue('sunrise'));
    unixtime := unixtime + timezone;
    UnixToDate(unixtime, sunriseDate);
    unixTime := StrToInt(getJsonKeyValue('sunset'));
    unixtime := unixtime + timezone;
    UnixToDate(unixtime, sunsetDate);
    
    //weatherMain := getJsonKeyValue('main');
    weatherDesc := getJsonKeyValue('description');
    icon := getJsonKeyValue('icon');
    temp := getJsonKeyValue('temp');
    feels := getJsonKeyValue('feels_like');
    pressure := getJsonKeyValue('pressure');
    humidity := getJsonKeyValue('humidity');
    dewpoint := getJsonKeyValue('dew_point');
    visibility := getJsonKeyValue('visibility');
    windSpeed := getJsonKeyValue('wind_speed');
    windAngle := getJsonKeyValue('wind_deg');
    clouds := getJsonKeyValue('clouds');    
end;

procedure FakeWeather;
var date: array [0..7] of byte = ($de,7,6,9,21,37,03,0);
begin
    UnixToDate(unixtime, curDate);
    Move(date, curDate,8);
    Move(date, sunriseDate,8);
    Move(date, sunsetDate,8);
    
    city := 'Przedmiescie Szczebrzeszynskie';
    country_code := 'PL';
    //weatherMain := getJsonKeyValue('main');
    weatherDesc := 'heavy shower rain and drizzle';
    icon := '02d';
    temp := '-20.35';
    feels := '17.4';
    pressure := '1024';
    humidity := '100';
    windSpeed := '12';
    windAngle := '245';
    dewpoint := '8';
    visibility := '10000';    
    clouds := '0';
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

procedure ComposeGetHeader(var s:string; askFor:byte);
begin
        
    if askFor = CALL_CHECKCITY then begin
        s:='GET /data/2.5/weather?q=';
        s:=Concat(s,city);
    end;
    if (askFor = CALL_WEATHER) or (askFor = CALL_FORECAST) then begin
        s:='GET /data/2.5/onecall?lat=';
        s:=Concat(s,latitude);
        s:=Concat(s,'&lon=');
        s:=Concat(s,longitude);
        s:=Concat(s,'&exclude=minutely,hourly,alerts');
        if askFor = CALL_WEATHER then s:=Concat(s,',daily');
        if askFor = CALL_FORECAST then s:=Concat(s,',current');
    end;
    s:=Concat(s,'&units=');
    if units = metric then s:=Concat(s,'metric')
    else s:=Concat(s,'imperial');
    
    s:=Concat(s,'&appid=2e8616654c548c26bc1c86b1615ef7f1 HTTP/1.1'#13#10'Host: api.openweathermap.org'#13#10'Cache-Control: no-cache;'#13#10#13#10);
end;

procedure HTTPGet(var api,header:string);
begin
    ioResult := TCP_Connect(api);
    if isIOError then exit;
    TCP_AttachIRQ;
    TCP_SendString(header);
    ioResult := WaitAndParseRequest;
    if isIOError then exit;
    TCP_DetachIRQ;
    TCP_Close;    
end;

procedure GetWeather;
begin
    {$ifdef fake}
    FakeWeather; exit;
    {$endif}
   
    ComposeGetHeader(getLine,  CALL_WEATHER);
    HTTPGet(OW_api, getLine);
    ParseWeather;
end;

procedure GetCityLocation;
begin
    ComposeGetHeader(getLine,CALL_CHECKCITY);
    HTTPGet(OW_api, getLine);
    getLine[0] := #0;
    city[0] := #0;
    country_code[0] := #0;
    if findKeyPos('name')<>0 then begin
        city := getJsonKeyValue('name');
        UtfNormalize(city);
        country_code := getJsonKeyValue('country');
        latitude := getJsonKeyValue('lat');
        longitude := getJsonKeyValue('lon');
    end;
    if findKeyPos('message')<>0 then begin
        getLine := getJsonKeyValue('message');
        country_code := getJsonKeyValue('cod');
    end;
end;

procedure GetIPLocation;
begin
    getLine:='GET /check?access_key=9ba846d99b9d24288378762533e00318&fields=ip,country_code,country_name,city,latitude,longitude,zip HTTP/1.1'#13#10'Host: api.ipstack.com'#13#10'Cache-Control: no-cache;'#13#10#13#10;
    HTTPGet(IP_api, getLine);
    ParseLocation;
    Writeln('Your IP: ',ip);
end;

// ***************************************************** GUI ROUTINES

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
    if units = imperial then hour := hour24to12(hour) 
    else Write(' ');
    if hour < 10 then Write(0);
    Write(hour,':');
    if date.minute < 10 then Write(0);
    Write(date.minute);
    if units = imperial then begin
        if date.hour > 12 then Write('am')
            else Write('pm');
    end;
    //if date.second < 10 then Write(0);
    //Write(date.second);
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
    src := FONT + (ord(c) shl 3);
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
        inc(dest,scrWidth);
        inc(row);
    until row = 8;
end;

procedure PutString(var s:string;dest: word;color:byte);
var i:byte;
    line:string[40];
begin
    i:=1;
    line:=Atascii2Antic(s);
    while (i<=Length(line)) do begin
        PutChar(line[i],dest,color);
        inc(dest,2);
        inc(i);
    end;
end;

procedure PutCString(var s:string;dest: word;color:byte);
var l:byte;
begin
    l:=Length(s);
    if l<20 then dest := dest + (20 - l);
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
    Writeln('Location: ',city,', ',country_code);
    Writeln('latitude: ',latitude);
    Writeln('longitude: ',longitude);
    //Writeln('zip-code: ',zip);
    Write('units: ');
    if units = metric then Writeln('metric')
    else Writeln('imperial');
    Writeln;
end;

procedure PromptLocation;
var foundLocation:boolean;
begin
    foundLocation := false;
    CursorOn;
    repeat 
        Writeln('Enter desired city,country');
        Writeln('example: PARIS,FR');
        Readln(city);
        GetCityLocation;
        if Length(city) <> 0 then begin
            foundLocation := true; 
            showLocation;
        end else begin
            Writeln('Request Error : ',country_code);
            Writeln(getLine);
            Writeln('Try Again!');
            Writeln;
        end;
    until foundLocation;
    CursorOff;
end;

procedure WaitForOverride;
var timeout:byte;
    over:boolean;
begin
    CursorOff;
    timeout := 150;
    over:=false;
    Writeln('Press '+'SELECT'*+' to override location');
    Write('3...');
    repeat 
        pause;
        if CRT_SelectPressed then over:=true;
        dec(timeout);
        if timeout = 100 then begin
            DelLine; Write('2...');
        end;
        if timeout = 50 then begin
            DelLine; Write('1...');
        end;
    until over or (timeout = 0);
    DelLine;
    if over then PromptLocation;
    CursorOn;
end;

procedure ClearGfx;
begin
    FillByte(pointer(VRAM),VRAM_SIZE,0);
end;

procedure ShowHeader;
begin
    ClearGfx;
    scrWidth:=80;
    PutCString(getLine, VRAM + 43    * 40 + 2,1);
    scrWidth:=40;
end;

procedure ShowDescription;
begin
    scrWidth := 80;
    PutCString(weatherDesc, VRAM + 43 * 40 + 2,1);
    PutCString(weatherDesc, VRAM + 41 * 40 + 2,3); 
    scrWidth := 40;
end;

procedure ScrollInit;
begin
    descDir := 0;
    descOffset := 0;
    descScroll := BOUNCE_DELAY;
    descHSC := 8;
    hscrol := descHSC;
end;

procedure ScrollDescription;
var row:byte;
    dlptr:byte;
    vptr:word;
begin
    dlptr := 51;
    vptr := VRAM + (41*40) + descOffset;
    for row:=0 to 8 do begin
        dpoke(DLIST + dlptr, vptr);
        inc(dlptr,3);
        inc(vptr,80);
    end;
end;

procedure ShowWeather;
begin
    Pause;
    sdmctl := sdmctl and %11111100;
    scrWidth := 40;
    SDLSTL := DLIST;
    SetIntVec(iDLI, @dli);
    nmien := $c0; 
    chbas := Hi(FONT);
    ClearGfx;

    if palnts = 0 then colors := colorsNTSC
        else colors := colorsPAL;

    color0 := colors[0];
    color1 := colors[1];
    color2 := colors[2];
    color4 := (colors[3] and $f0);

    // set backgrond color based on icon type
    if icon[3] = 'd' then color4 := (colors[3] and $f0) or $0a;

    cityColor := 6;
    textColor := 15;
    menuColor := color4;


    // top of screen - GFX part
    savmsc := VRAM;

    Str(curDate.day, getLine);
    getLine := Concat(getLine,monthNames[curDate.month-1]);
    Str(curDate.year, tmp);
    getLine := Concat(getLine, tmp);
    getLine := Concat(getLine,', ');
    getLine := Concat(getLine,dowNames[curDate.dow]);
    
    PutCString(getLine, savmsc + 0 * 40,1);
   
    DrawIcon(GetIconPtr(icon),savmsc+17*40);

    if Length(temp)>5 then setLength(temp,5); 
    if units = metric then getLine := Concat(temp, '^C') 
        else getLine := Concat(temp, '^F');

    PrintTemperature(getLine, savmsc+17*40 + 12);
    
    i := 40 - Length(pressure) shl 1;
    PutString(pressure, savmsc + 16 * 40 + i,3);
    getLine := 'hPa';
    PutString(getLine, savmsc + 24 * 40 + 34,3);
    
    ScrollInit;
    ShowDescription;
    
    // bottom - TXT part
    savmsc := VRAM + (41 * 40) + (9 * 80);
    
    getLine := Concat(city, ', ');
    getLine := Concat(getLine, country_code);
    if Length(getLine)>40 then setLength(getLine,40); 
    Gotoxy(21-(Length(getLine) shr 1),1);
    Writeln(getLine);

    Gotoxy(2,3);
    Write('Wind: ',windSpeed,' ');
    WriteSpeedUnit;
    Write(' ');
    Write(windDir[getDirName(StrToInt(windAngle))]);

    Gotoxy(24,6);
    Write('Humidity: ', humidity, '%');
    Gotoxy(24,7);
    Write('Clouds:   ', clouds, '%');

    Gotoxy(24,3);
    Write('Sunrise: ');
    WriteTime(sunriseDate);
    Gotoxy(24,4);
    Write('Sunset:  ');
    WriteTime(sunsetDate);

    Gotoxy(2,6);
    Write('Dew point:  ',dewPoint);
    if units = metric then Write('^C') else Write('^F');

    Gotoxy(2,7);
    unixtime := StrToInt(visibility);
    Write('Visibility: ');
    if unixtime > 1000 then begin
        unixtime := unixtime div 1000;
        write(unixtime,'km')
    end else Write(unixtime,'m');

    Gotoxy(2,4);
    Write('Feels like: ', feels);
    if units = metric then Write('^C') else Write('^F');

    Gotoxy(2,9);
    Write('F'*+'orecast    '+'U'*+'nits     '+'R'*+'efresh   '+'Q'*+'uit');

    sdmctl := sdmctl or %10;
end;

procedure ShowMenu;
begin
    menuDelay := 150;
    menuColor := cityColor;
end;

procedure ShowWelcomeMsg;
begin
    move(pointer($e000),pointer(VRAM),$400);
    move(pointer(LOGO_CHARSET),pointer(VRAM+$200),$100);
    TextMode(0);
    chbas := Hi(VRAM); // set custom charset
    move(logo[0*13],pointer(savmsc+40*1+2),13);
    move(logo[1*13],pointer(savmsc+40*2+2),13);
    move(logo[2*13],pointer(savmsc+40*3+2),13);
    move(logo[3*13],pointer(savmsc+40*4+2),13);
    Gotoxy(17,3);
    Write('openWeather.org Client');
    Gotoxy(17,4);
    Write('by bocianu@gmail.com');
    Gotoxy(2,6);
    Writeln;
end;

procedure Animate;
begin
    // menu
    if menuDelay>0 then begin
        dec(menuDelay);
        if menuDelay = 0 then menuColor := color4;
    end;
    
    //description
    if Length(weatherDesc) > 20 then begin
        dec(descScroll);
        if descScroll = 0 then begin
            descScroll := SCROLL_SPEED;
            if descDir = 0 then begin 
                dec(descHSC);
                if descHSC <= 4 then begin
                    inc(descOffset);
                    ScrollDescription;;
                    descHsc := 8;
                end;
                if descOffset = (Length(weatherDesc) shl 1) - 40 then begin
                    descDir := 1;
                    descScroll := BOUNCE_DELAY;
                end;
            end else begin
                inc (descHSC);
                if descHSC >= 9 then  begin
                    dec(descOffset);
                    ScrollDescription;;
                    descHSC := 5;
                end;
                if (descOffset = 0) and (descHSC = 8) then begin
                    descDir := 0;
                    descScroll := BOUNCE_DELAY;
                end;
            end;
            hscrol := descHsc;
        end;
    end;
end;

procedure ChangeLocation;
begin
    Pause;
    nmien := $40; 
    ShowWelcomeMsg;
    PromptLocation;
    GetWeather;
    ShowWeather;
    ShowMenu;
end;

// **********************************************************************
// *******************************************************************************  MAIN
// **********************************************************************

begin

    portb := $ff;
    hscrol := 8;
    GetIntVec(iDLI, olddli);

{$ifndef fake}

    ShowWelcomeMsg;
    Writeln('Connecting to ipstack.com');
    Writeln('Checking your ip and location');

    GetIPLocation;
    ShowLocation;
    WaitForOverride;

    Writeln;
    Writeln('Connecting to openweathermap.org');
    Writeln('Checking weather for your location');

{$endif}

    CursorOff;
    GetWeather;
    ShowWeather;
    ShowMenu;

    repeat

        repeat 
            pause;
            atract := 1;
            Animate;
            if CRT_SelectPressed then ChangeLocation;
            
        until KeyPressed;

        k := readkey;
        case k of
            'r', 'R': begin 
                getLine := 'Reloading Weather';
                ShowHeader;
                GetWeather;
                ShowWeather;
            end;
            'u', 'U': begin
                getLine := 'Changing Units';
                ShowHeader;
                if units = metric then units := imperial else units := metric;
                GetWeather;
                ShowWeather;
            end;
            else ShowMenu;
        end;

    until (k = 'q') or (k = 'Q');

    TCP_DetachIRQ;
    TextMode(0);
end.
