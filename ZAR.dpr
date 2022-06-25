program ZAR;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes;

Procedure Seek4(Stream:TStream);
var
b:byte;
begin
b:=$00;
  if Stream.Position mod 4 <>0 then
  while Stream.Position mod 4 <>0 do
   Stream.Write(b,1);
end;

Function readtext(Stream:TStream):AnsiString;
var
b:byte;
off:longword;
size:byte;
t:AnsiString;
begin
off:=Stream.Position;
b:=$01;
while b<>$00 do
Stream.Read(b,1);
size:=Stream.Position-off-1;
Stream.Position:=off;
SetLength(t,size);
Stream.Read(t[1],size);
Result:=t;
end;

Function SwapSlash(Path:AnsiString;Mode:Boolean):AnsiString;
begin
if mode=false then
Result:=StringReplace(path,'/','\',[rfReplaceAll]) else Result:=StringReplace(path,'\','/',[rfReplaceAll]);
end;

function ExtractOnlyFileName(const FileName: string): string;
 begin
   result:=StringReplace(ExtractFileName(FileName),ExtractFileExt(FileName),'',[])
end;

Type
TFileTypes = record
CountFilesWithType    : LongWord;
FileNumberIndexOffset : LongWord;
FileTypeNameOffset    : LongWord;
AssumedConstant       : LongWord;
FileNumberIndex       : Array[0..99] of LongWord;
NameType              : AnsiString;
end;
TFileInfo = record
SizeFile   : LongWord;
OffsetName : LongWord;
FileName   : AnsiString;
end;
TZar = packed record
//ZAR
Size            : LongWord;
CountFilesTypes : Word;
CountFiles      : Word;
FileTypesOffset : LongWord;
FileNamesOffset : LongWord;
FileIndexOffset : LongWord;
//queen
FileTypes       : Array[1..$FFFF] of TFileTypes;
FileInfo        : Array[1..$FFFF] of TFileInfo;
FileOffset      : Array[1..$FFFF] of LongWord;
const
Header : longword = $0152415A;
queen : Ansistring = 'queen';
end;

var
F,Temp:TFileStream;
text:textfile;
z:TZar;
TL:LongWord;
i,ii:integer;
filename,ts:ansistring;
bb:byte;

begin
if ParamStr(1)<>'' then
begin
if ExtractFileExt(ParamStr(1))<>'.index' then
 begin
  F:=TFileStream.Create(ParamStr(1),fmopenread);
  f.Read(tl,4);
  if tl=z.Header then
   begin
     f.Read(z.Size,4);
     f.Read(z.CountFilesTypes,2);
     f.Read(z.CountFiles,2);
     f.Read(z.FileTypesOffset,4);
     f.Read(z.FileNamesOffset,4);
     f.Read(z.FileIndexOffset,4);
     f.Position:=z.FileTypesOffset;
     for I := 1 to z.CountFilesTypes do
       begin
         f.Position:=(z.FileTypesOffset)+($10*i-$10);
         f.read(z.FileTypes[i].CountFilesWithType,4);
         f.Read(z.FileTypes[i].FileNumberIndexOffset,4);
         f.Read(z.FileTypes[i].FileTypeNameOffset,4);
         f.Read(z.FileTypes[i].AssumedConstant,4);
         if z.FileTypes[i].CountFilesWithType>0 then
          begin
           f.Position:=z.FileTypes[i].FileNumberIndexOffset;
           for ii := 1 to z.FileTypes[i].CountFilesWithType do
             begin
               f.Read(z.FileTypes[i].FileNumberIndex[ii],4);
               inc(z.FileTypes[i].FileNumberIndex[ii]);
             end;
          end;
        f.Position:=z.FileTypes[i].FileTypeNameOffset;
        z.FileTypes[i].NameType:=readtext(f);
       end;
     f.Position:=z.FileNamesOffset;
     for I := 1 to z.CountFiles do
       begin
         f.Read(z.FileInfo[i].SizeFile,4);
         f.Read(z.FileInfo[i].OffsetName,4);
       end;
     for I := 1 to z.CountFiles do
       begin
         f.Position:=z.FileInfo[i].OffsetName;
         z.FileInfo[i].FileName:=readtext(f);
         z.FileInfo[i].FileName:=SwapSlash(z.FileInfo[i].FileName,false);
       end;
     f.Position:=z.FileIndexOffset;
     for I := 1 to z.CountFiles do
        f.Read(z.FileOffset[i],4);
     //end read archive
     filename:=ExtractOnlyFileName(ParamStr(1));
     if DirectoryExists(filename)=false then
     CreateDir(filename);
     for I := 1 to z.CountFiles do
       begin
         Writeln(filename + '\' + z.FileInfo[i].FileName);
         ForceDirectories(filename + '\' + ExtractFilePath(z.FileInfo[i].FileName));
         Temp:=TFileStream.Create(filename + '\' + z.FileInfo[i].FileName,fmcreate);
         f.Position:=z.FileOffset[i];
         temp.CopyFrom(f,z.FileInfo[i].SizeFile);
         temp.Free;
       end;
     f.Free;
     AssignFile(text,filename+'.index');
     Rewrite(text);
     Writeln(text,inttostr(z.CountFilesTypes));
     WriteLn(text,inttostr(z.CountFiles));
     for I := 1 to z.CountFilesTypes do
       begin
        writeln(text,inttostr(z.FileTypes[i].CountFilesWithType));
        writeln(text,inttostr(z.FileTypes[i].AssumedConstant));
        writeln(text,z.FileTypes[i].NameType);
        for Ii := 1 to z.FileTypes[i].CountFilesWithType do
          writeln(text,inttostr(z.FileTypes[i].FileNumberIndex[ii]));
       end;
      for I := 1 to z.CountFiles do
      Writeln(text,z.FileInfo[i].FileName);
     CloseFile(text);
     Writeln('Done:)');
  end else begin Writeln('Error. Not ZAR file'); readln;end;
end else
  begin
    AssignFile(Text,paramstr(1));
    reset(text);
    Readln(text,ts);
    z.CountFilesTypes:=strtoint(ts);
    readln(text,ts);
    z.CountFiles:=StrToInt(ts);
    for i := 1 to z.CountFilesTypes do
      begin
        readln(text,ts);
        z.FileTypes[i].CountFilesWithType:=StrToInt(ts);
        readln(text,ts);
        z.FileTypes[i].AssumedConstant:=StrToInt64(ts);
        readln(text,ts);
        z.FileTypes[i].NameType:=ts;
        for ii := 1 to z.FileTypes[i].CountFilesWithType do
          begin
            readln(text,ts);
            z.FileTypes[i].FileNumberIndex[ii]:=StrToInt(ts)-1;
          end;
      end;
    for I := 1 to z.CountFiles do
      begin
        Readln(text,ts);
        z.FileInfo[i].FileName:=ts;
      end;
    filename:=ExtractOnlyFileName(ParamStr(1));
    if ParamStr(2)<>'' then
    f:=TFileStream.Create(ParamStr(2)+'.zar',fmcreate) else f:=TFileStream.Create(filename+'.zar',fmcreate);
    f.Write(z.Header,4);
    f.Position:=f.Position+4;
    f.Write(z.CountFilesTypes,2);
    f.Write(z.CountFiles,2);
    tl:=$00000020;
    f.Write(tl,4);
    f.Position:=f.Position+$8;
    f.Write(z.queen[1],length(z.queen));
    bb:=$00;
    f.Write(bb,3);
    f.Position:=f.Position+($10*z.CountFilesTypes);
    for I := 1 to z.CountFilesTypes do
      begin
        z.FileTypes[i].FileNumberIndexOffset:=f.Position;
        for ii := 1 to z.FileTypes[i].CountFilesWithType do
        f.Write(z.FileTypes[i].FileNumberIndex[ii],4);
        z.FileTypes[i].FileTypeNameOffset:=f.Position;
        f.Write(z.FileTypes[i].NameType[1],length(z.FileTypes[i].NameType));
        f.Write(bb,1);
        Seek4(f);
      end;
     f.Position:=$20;
     for I := 1 to z.CountFilesTypes do
      begin
        f.Write(z.FileTypes[i].CountFilesWithType,4);
        if z.FileTypes[i].CountFilesWithType>0 then
        f.Write(z.FileTypes[i].FileNumberIndexOffset,4)
        else begin
               tl:=$FFFFFFFF;
               f.Write(tl,4);
             end;
        f.Write(z.FileTypes[i].FileTypeNameOffset,4);
        f.Write(z.FileTypes[i].AssumedConstant,4);
      end;
      f.Position:=f.Size;
      z.FileNamesOffset:=f.Position;
      f.Position:=f.Position+($8*z.CountFiles);
      for I := 1 to z.CountFiles do
        begin
          z.FileInfo[i].OffsetName:=f.Position;
          z.FileInfo[i].FileName:=SwapSlash(z.FileInfo[i].FileName,true);
          f.Write(z.FileInfo[i].FileName[1],length(z.FileInfo[i].FileName));
          z.FileInfo[i].FileName:=SwapSlash(z.FileInfo[i].FileName,false);
          f.Write(bb,1);
          Seek4(f);
        end;
      z.FileIndexOffset:=f.Position;
      f.Position:=f.Position+($4*z.CountFiles);
      for i := 1 to z.CountFiles do
        begin
          z.FileOffset[i]:=f.Position;
          temp:=TFileStream.Create(filename+'\'+z.FileInfo[i].FileName,fmopenread);
          z.FileInfo[i].SizeFile:=temp.Size;
          f.CopyFrom(temp,temp.Size);
          temp.Free;
        end;
      f.Position:=z.FileIndexOffset;
      for I := 1 to z.CountFiles do
        begin
          f.Write(z.FileOffset[i],4);
        end;
      f.Position:=z.FileNamesOffset;
      for I := 1 to z.CountFiles do
        begin
          f.Write(z.FileInfo[i].SizeFile,4);
          f.Write(z.FileInfo[i].OffsetName,4);
        end;
      f.Position:=$10;
      f.Write(z.FileNamesOffset,4);
      f.Write(z.FileIndexOffset,4);
      f.Position:=$4;
      tl:=f.Size;
      f.Write(tl,4);
      f.Free;
      close(text);
  end;
end else
    begin
      Writeln('ZAR Extract\Repack v0.1');
      WriteLn('Specially for Zelda64Rus');
      Writeln('By TTEMMA, 2015');
      WriteLn('Using:');
      Writeln('      extract: zar.exe file.zar');
      Writeln('      repack : zar.exe file.index <NewNameFile>');
      readln;
    end;
  try
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
