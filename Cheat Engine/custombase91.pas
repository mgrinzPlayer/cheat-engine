unit CustomBase91;


// uses 91 ascii characters which are better to use in XML ( no &'<"\> chars and no space char = more efficient )
//
// Base91ToBin doesn't support white spaces and line breaks (HexToBin doesn't support it too)

// original basE91 by Joachim Henke (base91.sourceforge.net)
// freepascal implementation by mgr.inz.Player

{$mode delphi}

interface

uses
  Classes;

procedure BinToBase91(BinValue: PChar; var outputStringBase91: PChar; BinBufSize: integer);
//
//  example:
//    BinToBase91(b,outputstring,BinarySize);
//
//  it adds a 0 terminator to outputstring

function Base91ToBin(inputStringBase91: PChar; var BinValue: PChar): integer;
//
//  example:
//    Base91ToBin(inputstring, b);
//
//  Base91ToBin doesn't support: white space between the characters, line breaks. (HexToBin doesn't support it too)
//  Base91ToBin doesn't check for data corruption.

implementation

const
  customBase91='0123456789'+
               'ABCDEFGHIJKLMNOPQRSTUVWXYZ'+
               'abcdefghijklmnopqrstuvwxyz'+
               '!#$%()*+,-./:;=?@[]^_{}'+
               '~`|\"'+#39;

procedure BinToBase91(BinValue: PChar; var outputStringBase91: PChar; BinBufSize: integer);
var
  i,j,k,n : integer;
  a,b : dword;
  nilCharPos : integer;
begin
  for k:=1 to 2 do // two pass
  begin
    i:=0;
    j:=0;
    a:=0;
    b:=0;
    n:=0;
    while i<BinBufSize do
    begin
      a:=a or pbyte(BinValue+i)^ shl n;
      inc(n,8);
      if n>13 then
      begin
        b:=a and 8191;
        if b>88 then
        begin
          a:=a shr 13;
          dec(n,13);
        end
        else
        begin
          b:=a and 16383;
          a:=a shr 14;
          dec(n,14);
        end;
        if k=2 then
        begin
          outputStringBase91[j]:=customBase91[b mod 91 + 1];
          outputStringBase91[j+1]:=customBase91[b div 91 + 1];
        end;
        inc(j,2);
      end;
      inc(i);
    end;

    //remaining bits
    if k=1 then
    begin
      if n>0 then
      begin
        inc(j);
        if (n>7) or (a>90) then inc(j);
      end;
      nilCharPos:=j;
      getmem(outputStringBase91,nilCharPos+1);
    end
    else
    begin
      if n>0 then
      begin
        outputStringBase91[j]:=customBase91[a mod 91 + 1];
        if (n>7) or (a>90) then outputStringBase91[j+1]:=customBase91[a div 91 + 1];
      end;
    end;

  end;
  outputStringBase91[nilCharPos]:=#0;
end;

function Base91ToBin(inputStringBase91: PChar; var BinValue: PChar): integer;
var
  i,j,k,n : integer;
  size : integer;
  a,b : dword;
begin

  size:=length(inputStringBase91);

  for k:=1 to 2 do // two pass
  begin
    i:=0;
    j:=0;
    a:=0;
    b:=$FFFFFFFF;
    n:=0;

    while i<size do
    begin
      if b=$FFFFFFFF then b:=( pos((inputStringBase91+i)^, customBase91) - 1 )
      else
      begin
        b:=b + ( pos((inputStringBase91+i)^, customBase91) - 1 ) * 91;
        a:=a or b shl n;
        if (b and 8191) > 88 then inc(n,13) else inc(n,14);
        repeat
          if k=2 then BinValue[j]:=char( a and $ff );
          inc(j);
          a:=a shr 8;
          dec(n,8);
        until not (n>7);
        b:=$FFFFFFFF;
      end;
      inc(i);
    end;

    //remaining byte
    if k=1 then
    begin
      if b<>$FFFFFFFF then inc(j);
      getmem(BinValue,j);
      result:=j;
    end
    else
      if b<>$FFFFFFFF then BinValue[j]:=char( (a or b shl n) and $ff );
  end;

end;

end.

