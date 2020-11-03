program testcookie;
{$librarypath '../blibs/'}
uses atari, crt, fn_cookies;

var cval: string = 'abcdefghijklmnopqrstuvwxyz';
    s: string;
    res:byte;

begin
    InitCookie($FFFF,$FF,$FF);
    repeat
        Writeln('press any key to proceed');
        Readkey;
        Writeln('set cookie');
        res := SetCookie(@cval[1], Length(cval)-4);
        Writeln('ioResult:',res);
        Writeln('press any key to proceed');
        Readkey;
        Writeln('get cookie');
        res := GetCookie(@s[1]);
        Writeln('ioResult:',res);
        s[0]:=char(cookie.len);
        Writeln(s);
    until false;
end.
