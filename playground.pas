program playground;
uses atari, sysutils, crt;

const
    NULL = $ff;

var
    s1: string;
    s2: string[8];
    s3: string[2];

begin
    s1 := '12345123451234512345';
    s2 := 'ABCDEFG';
    s3 := '--';
    Writeln(s1,' ',word(@s1));
    Writeln(s2,' ',word(@s2));
    Writeln(s3,' ',word(@s3));
    s2:=s1;
    Writeln(s1,' ',word(@s1));
    Writeln(s2,' ',word(@s2));
    Writeln(s3,' ',word(@s3));

        readkey;
    


end.
