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

var IP_api: string[15] = 'api.ipstack.com';
    OW_api: string[22] = 'api.openweathermap.org';
    getLine: string;    
    ioResult: byte;
    responseBuffer: array [0..0] of byte absolute JSON_BUFFER;

    units:TUnits;
    imperialCCodes: array [0..7] of string[2] = ('US', 'GB', 'IN', 'IE', 'CA', 'AU', 'HK', 'NZ');
    windDir: array [0..7] of string[2] = ('N ', 'NE', 'E ', 'SE', 'S ', 'SW', 'W ', 'NW');
    monthNames: array [0..11] of string[5] = (' Jan ', ' Feb ', ' Mar ', ' Apr ', ' May ', ' Jun' , ' Jul ', ' Aug ', ' Sep ',' Oct ',' Nov ',' Dec ');
    dowNames: array [0..6] of string[3] = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

    city:string[40];
    tmp, weatherDesc: TString;
    longitude, latitude, ip: string[20];
    pressure, temp, feels, windSpeed, dewpoint, visibility: string[10];
    country_code, icon, humidity, clouds, windAngle: string[3];
    
    descDir, descOffset, descScroll, descHSC: byte;

    curDate, sunriseDate, sunsetDate: TDateTime;
    unixTime: cardinal;
    timezone: integer;

    forecastPtrs: array [0..7] of word;

    scrWidth: byte;
    i, menuDelay: byte;
    k: char;
    
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
    
    page: byte;
  
{$i interrupts.inc}    
{$i json.inc}    
  
    
// ***************************************************** HELPERS    
    

procedure ScreenOff;
begin
    sdmctl := sdmctl and %11111100;
end;

procedure ScreenOn;
begin
    sdmctl := sdmctl or %10;
end;

procedure MergeStr(var s1:string;s2:string[80]);
var l1,l2:byte;
begin
    l1 := Length(s1);
    l2 := Length(s2);
    s1[0] := char(l1 + l2);
    while l2>0 do begin
        s1[l1+l2] := s2[l2];
        dec(l2);
    end;
end;
    
function isCCImperial(var cc:TString):boolean;
var i:byte;
    ic:string[2];
begin
    result := false;
    for i := 0 to 7 do begin
        ic := imperialCCodes[i];
        if (ic[1] = cc[1]) and (ic[2] = cc[2]) then exit(true);
    end;
end;

function GetDirName(angle:word):byte;
begin
    result := Round(angle / 45.0) mod 8;
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
    result := iconsD[iconId];
    if icon[3] = 'n' then result := iconsN[iconId];
end;

// ********************************************************* DATA PARSERS

procedure ParseLocation;
begin
    ip := GetJsonKeyValue('ip');
    city := GetJsonKeyValue('city');
    utfNormalize(city);
    country_code := GetJsonKeyValue('country_code');
    latitude := GetJsonKeyValue('latitude');
    longitude := GetJsonKeyValue('longitude');
    units := metric;
    if isCCImperial(country_code) then units := imperial;
end;



procedure ParseWeatherCommons;
begin
    unixTime := StrToInt(GetJsonKeyValue('dt')) + timezone;
    UnixToDate(unixtime, curDate);

    icon := GetJsonKeyValue('icon');
    pressure := GetJsonKeyValue('pressure');
    humidity := GetJsonKeyValue('humidity');
    windSpeed := GetJsonKeyValue('wind_speed');
end;


procedure ParseWeather;
begin
    timezone := StrToInt(GetJsonKeyValue('timezone_offset'));

    unixTime := StrToInt(GetJsonKeyValue('sunrise')) + timezone;
    UnixToDate(unixtime, sunriseDate);
    unixTime := StrToInt(GetJsonKeyValue('sunset')) + timezone;
    UnixToDate(unixtime, sunsetDate);

    ParseWeatherCommons;
    
    windAngle := GetJsonKeyValue('wind_deg');
    clouds := GetJsonKeyValue('clouds');    
    dewpoint := GetJsonKeyValue('dew_point');
    weatherDesc := GetJsonKeyValue('description');
    temp := GetJsonKeyValue('temp');
    feels := GetJsonKeyValue('feels_like');
    visibility := GetJsonKeyValue('visibility');
end;

procedure ParseForecast;
var i:byte;
begin
    timezone := StrToInt(GetJsonKeyValue('timezone_offset'));
    FollowKey('daily');
    for i := 0 to 7 do forecastPtrs[i] := FindIndex(i);
end;

procedure ParseDay(day:byte);
begin
    jsonStart := forecastPtrs[day];
    ParseWeatherCommons;
    temp := GetJsonKeyValue('day');
    feels := GetJsonKeyValue('night');
    //weatherDesc := GetJsonKeyValue('pop');
end;

{$ifdef fake}
procedure FakeWeather;
var date: array [0..7] of byte = ($de,7,6,9,21,37,03,0);
begin
    UnixToDate(unixtime, curDate);
    Move(date, curDate,8);
    Move(date, sunriseDate,8);
    Move(date, sunsetDate,8);
    
    city := 'Przedmiescie Szczebrzeszynskie';
    country_code := 'PL';
    //weatherMain := GetJsonKeyValue('main');
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
{$endif}

// ***************************************************** NETWORK ROUTINES

function WaitAndParseRequest:byte;
begin
    result := TCP_WaitForData(100);
    jsonEnd := TCP_bytesWaiting;
    FN_ReadBuffer(@responseBuffer, jsonEnd);
    jsonRoot := GetJsonRoot;
    jsonStart := jsonRoot;
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

procedure AppendRequestHeaders(var s, api:string);
begin
    MergeStr(s, ' HTTP/1.1'#13#10'Host: ');
    MergeStr(s, api);
    MergeStr(s, #13#10'Cache-Control: no-cache;'#13#10#13#10);
end;

procedure ComposeGetHeader(var s:string; askFor:byte);
begin
    s:='GET /data/2.5/';
    if askFor = CALL_CHECKCITY then begin
        MergeStr(s,'weather?q=');
        MergeStr(s,city);
    end;
    if (askFor = CALL_WEATHER) or (askFor = CALL_FORECAST) then begin
        MergeStr(s,'onecall?lat=');
        MergeStr(s,latitude);
        MergeStr(s,'&lon=');
        MergeStr(s,longitude);
        MergeStr(s,'&exclude=minutely,hourly,alerts');
        if askFor = CALL_WEATHER then MergeStr(s,',daily');
        if askFor = CALL_FORECAST then MergeStr(s,',current');
    end;
    MergeStr(s,'&units=');
    if units = metric then MergeStr(s,'metric')
    else MergeStr(s,'imperial');
    MergeStr(s,'&appid=2e8616654c548c26bc1c86b1615ef7f1');
    AppendRequestHeaders(s, OW_api);
end;

procedure HTTPGet(var api, header:string);
begin
    tmp:='N:TCP://';
    MergeStr(tmp, api);
    MergeStr(tmp,':80');
    ioResult := TCP_Connect(tmp);
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
   
    ComposeGetHeader(getLine, CALL_WEATHER);
    HTTPGet(OW_api, getLine);
    ParseWeather;
end;

procedure GetForecast;
begin
    ComposeGetHeader(getLine, CALL_FORECAST);
    HTTPGet(OW_api, getLine);
    ParseForecast;
end;


procedure GetCityLocation;
begin
    ComposeGetHeader(getLine, CALL_CHECKCITY);
    HTTPGet(OW_api, getLine);
    getLine[0] := #0;
    city[0] := #0;
    country_code[0] := #0;
    if findKeyPos('name') <> 0 then begin
        city := GetJsonKeyValue('name');
        UtfNormalize(city);
        country_code := GetJsonKeyValue('country');
        latitude := GetJsonKeyValue('lat');
        longitude := GetJsonKeyValue('lon');
    end;
    if findKeyPos('message') <> 0 then begin
        getLine := GetJsonKeyValue('message');
        tmp := GetJsonKeyValue('cod');
    end;
end;

procedure GetIPLocation;
begin
    getLine:='GET /check?access_key=9ba846d99b9d24288378762533e00318&';
    MergeStr(getLine, 'fields=ip,country_code,city,latitude,longitude');
    AppendRequestHeaders(getLine, IP_api);
    HTTPGet(IP_api, getLine);
    ParseLocation;
    Writeln('Your IP: ',ip);
end;

// ***************************************************** GUI ROUTINES

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

procedure DrawIcon(src,dest: word);
begin
    Stamp(src,dest,10,24);
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

procedure PutCString(var s:string;dest: word;color:byte;w:byte);
var l:byte;
begin
    l:=Length(s);
    if l < w then dest := dest + (w - l);
    PutString(s,dest,color);
end;

function PutSymbol(c:char; dest: word):byte;
var x,h:byte;
    src,off:word;
begin
    result := 3;
    h := 19;
    src:= GFX + 74 * 40;
    case c of
        '0'..'9': begin 
            x := (ord(c) - 48) * 3;
            if c = '1' then begin
                dec(result);
                inc(x);
            end;
        end;
        'F': begin
            x := 11 * 3;
        end;
        'C': begin
            x := 12 * 3;
        end;
        '^': begin
            x := 10 * 3 + 1;
            dec(result);
            h := 5;
        end;
        '.': begin
            x := 10 * 3 + 1;
            dec(result);
            h := 3;
            off := 40 * 16;
            inc(src, off);
            inc(dest, off)
        end;
        '-': begin
            x := 10 * 3 + 1;
            dec(result);
            h := 2;
            off := 40 * 8;
            inc(src, off);
            inc(dest, off)
        end;
    end;
    inc(src, x);
    Stamp(src, dest, result, h);
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
        Writeln('Search for city,country');
        Writeln('example: PARIS,FR');
        Readln(city);
        GetCityLocation;
        if Length(city) <> 0 then begin
            foundLocation := true; 
            showLocation;
        end else begin
            Writeln('Request Error : ',tmp);
            Writeln(getLine);
            Writeln('Try Again!');
            Writeln;
        end;
    until foundLocation;
    CursorOff;
end;

procedure WaitForOverride;
var timeout:byte;
    counter:byte;
    change:boolean;
begin
    CursorOff;
    counter := 1;
    timeout := 4;
    change := false;
    Writeln('Press '+'SELECT'*+' to override location');
    repeat 
        pause;
        if CRT_SelectPressed then change := true;
        dec(counter);
        if counter = 0 then begin
            dec(timeout);
            DelLine; Write(timeout,'...');
            counter := 50;
        end;
    until change or (timeout = 0);
    DelLine;
    if change then PromptLocation;
    CursorOn;
end;

procedure ClearGfx;
begin
    FillByte(pointer(VRAM),VRAM_SIZE,0);
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

procedure ScrollInit;
begin
    descDir := 0;
    descOffset := 0;
    descScroll := BOUNCE_DELAY;
    descHSC := 8;
    hscrol := descHSC;
    ScrollDescription;
end;

procedure ShowHeader;
begin
    ClearGfx;
    ScrollInit;
    scrWidth:=80;
    PutCString(getLine, VRAM + 43 * 40 + 2,1,20);
    scrWidth:=40;
end;

procedure ShowDescription;
begin
    ScrollInit;
    scrWidth := 80;
    PutCString(weatherDesc, VRAM + 43 * 40 + 2,1,20);
    PutCString(weatherDesc, VRAM + 41 * 40 + 2,3,20); 
    scrWidth := 40;
end;

procedure ShowMenu;
begin
    menuDelay := 150;
    menuColor := cityColor;
end;

procedure InitGfx;
begin
    Pause;
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

    cityColor := 6;
    textColor := 15;
    menuColor := color4;
end;

procedure ShowWeather;
begin
    ScreenOff;
    InitGfx;
    // set backgrond color based on icon type
    if icon[3] = 'd' then color4 := (colors[3] and $f0) or $0a;

    // date
    Str(curDate.day, getLine);
    MergeStr(getLine, monthNames[curDate.month - 1]);
    Str(curDate.year, tmp);
    MergeStr(getLine, tmp);
    MergeStr(getLine, ', ');
    MergeStr(getLine, dowNames[curDate.dow]);
    PutCString(getLine, VRAM + 0 * 40, 1,20);
   
    // icon
    DrawIcon(GetIconPtr(icon), VRAM + 17 * 40);
    
    // temperature
    getLine[0] := #0;
    MergeStr(getLine, temp);
    if Length(getLine)>5 then setLength(getLine, 5); 
    if units = metric then MergeStr(getLine, '^C') 
        else MergeStr(getLine, '^F');
    PrintTemperature(getLine, VRAM + 17 * 40 + 12);
    
    // pressure
    i := 40 - Length(pressure) shl 1;
    PutString(pressure, VRAM + 16 * 40 + i, 3);
    getLine := 'hPa';
    PutString(getLine, VRAM + 24 * 40 + 34, 3);
    
    // desription
    ShowDescription;
    
    // bottom - TXT part
    savmsc := VRAM + (41 * 40) + (9 * 80);
 
    // city, country
    getLine[0] := #0;
    MergeStr(getLine, city);    
    MergeStr(getLine, ', ');
    MergeStr(getLine, country_code);
    if Length(getLine) > 40 then setLength(getLine, 40); 
    Gotoxy(21-(Length(getLine) shr 1), 1);
    Writeln(getLine);

    // wind
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
        write(unixtime, 'km')
    end else Write(unixtime, 'm');

    Gotoxy(2,4);
    Write('Feels like: ', feels);
    if units = metric then Write('^C') else Write('^F');

    Gotoxy(2,9);
    Write('F'*+'orecast    '+'U'*+'nits     '+'R'*+'efresh   '+'Q'*+'uit');

    ShowMenu;
    ScreenOn;
    page := PAGE_WEATHER;
end;

procedure ShowDayofForecast(column:byte);
var x:byte;
    o:byte;
begin
    x := column * 10;
    Str(curDate.day, getLine);
    PutCString(getLine, VRAM + 0 * 40 + x, 3, 5);
    getLine[0] := #0;
    MergeStr(getLine, monthNames[curDate.month - 1]);
    PutString(getLine, VRAM + 8 * 40 + x, 1);

    // icon
    DrawIcon(GetIconPtr(icon), VRAM + 17 * 40 + x);
    
    scrWidth := 80;
    getLine[0] := #0;
    MergeStr(getLine, dowNames[curDate.dow]);
    PutString(getLine, VRAM + 40 * 41 + x + 4, 1);
    scrWidth := 40;

    savmsc := VRAM + (41 * 40) + (9 * 80);

    //ptr := VRAM + (41 * 40) + (9 * 80);
    //Poke(ptr + x, GetDirName(StrToInt(windAngle))+$40);

    o := 2;

    getLine[0] := #0;
    MergeStr(getLine, feels);
    if Length(getLine)>5 then setLength(getLine, 5); 
    if units = metric then MergeStr(getLine, '^C') 
        else MergeStr(getLine, '^F');
    Gotoxy(x + o,1);
    Write(getLine);

    getLine[0] := #0;
    MergeStr(getLine, temp);
    if Length(getLine)>5 then setLength(getLine, 5); 
    if units = metric then MergeStr(getLine, '^C') 
        else MergeStr(getLine, '^F');
    Gotoxy(x + o,2);
    Write(getLine);

    getLine[0] := #0;
    MergeStr(getLine, pressure);
    Gotoxy(x + o,4);
    Write(getLine);
    Write('hPa');
    
    getLine[0] := #0;
    MergeStr(getLine, windSpeed);
    Gotoxy(x + o,6);
    Write(getLine);
    WriteSpeedUnit;
end;

procedure ShowForecast(pageNum:byte);
var day, column:byte;
    pages: array[0..1] of byte = ( PAGE_FORECAST0, PAGE_FORECAST1);
begin
    ScreenOff;
    InitGfx;
    ScrollInit;

    color0 := colors[0] - 4;
    color4 := (colors[3] and $f0) or $06;
    cityColor := 2;

    column := 0;
    day := (pageNum shl 2);

    repeat 
        if forecastPtrs[day]<>0 then begin
            ParseDay(day);
            ShowDayofForecast(column);
        end;
        inc(day);
        inc(column);
    until column = 4;

    savmsc:= VRAM + (41 * 40) + (9 * 80);

    Gotoxy(2,9);
    Write('N'*+'ext      '+'B'*+'ack                '+'Q'*+'uit');

    ShowMenu;
    ScreenOn;
    page := pages[pageNum];
end;

procedure ShowWelcomeMsg;
begin
    ScreenOff;
    ClearGfx;
    Pause;
    SDLSTL := DLIST2;
    nmien := $40; 
    savmsc := VRAMTXT;

    color1 := 10;
    color2 := $94;
    color4 := 0;

    // prepare logo charset
    move(pointer($e000),pointer(VRAM), $400);
    move(pointer(LOGO_CHARSET),pointer(VRAM+$200), $100);
    chbas := Hi(VRAM); 

    // draw logo
    move(logo[0*13],pointer(savmsc+40*1+2),13);
    move(logo[1*13],pointer(savmsc+40*2+2),13);
    move(logo[2*13],pointer(savmsc+40*3+2),13);
    move(logo[3*13],pointer(savmsc+40*4+2),13);
    
    Gotoxy(17,3);
    Write('openWeather.org client');
    Gotoxy(17,4);
    Write('by bocianu@gmail.com');
    Gotoxy(2,6);
    Writeln;

    ScreenOn;
end;

procedure Animate;
begin
    // menu
    if menuDelay>0 then begin
        dec(menuDelay);
        if menuDelay = 0 then menuColor := color4;
    end;
    
    //description
    if (Length(weatherDesc) > 20) and (page = PAGE_WEATHER) then begin
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

procedure ReloadWeather;
begin 
    GetWeather;
    ShowWeather;
end;

procedure ChangeLocation;
begin
    ShowWelcomeMsg;
    PromptLocation;
    ReloadWeather;
end;

procedure ChangeUnits;
begin
    if units = metric then units := imperial else units := metric;
    getLine := 'Changing Units';
    ShowHeader;
    ReloadWeather;
end;

// **********************************************************************
// *******************************************************************************  MAIN
// **********************************************************************

begin
    portb := $ff;
    hscrol := 8;

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
    ReloadWeather;
    
    repeat

        // main loop
        repeat  
            pause;
            atract := 1;
            Animate;
            if CRT_SelectPressed then ChangeLocation;
            if CRT_OptionPressed then ChangeUnits;
        until KeyPressed;

        // menu key reading
        k := readkey;
        if page = PAGE_WEATHER then         // weather page
            case k of
                'r', 'R': begin
                    getLine := 'Reloading Weather';
                    ShowHeader;
                    ReloadWeather;
                end;
                'u', 'U': ChangeUnits;
                'f', 'F': begin
                    getLine := 'Checking Forecast';
                    ShowHeader;
                    GetForecast;
                    ShowForecast(0);
                end;
                else ShowMenu;
            end
        else                               // forecast page
            case k of
                'n', 'N': begin
                    case page of
                        0: ShowForecast(1);
                        1: ShowForecast(0);
                    end;
                end;
                'b', 'B': begin
                    getLine := 'Reloading Weather';
                    ShowHeader;
                    ReloadWeather;
                end;                
                else ShowMenu;
            end;
        
    until (k = 'q') or (k = 'Q');

    TCP_DetachIRQ;
    TextMode(0);
end.
