unit uImageUtils;

interface

uses
  // Delphi
  Windows, SysUtils, Classes, Graphics, jpeg, GIFImg,
  // DevExpress
  dxGDIPlusClasses;

type
  TGraphicMeta = class of TGraphic;

function GetTGraphicType(AStream: TStream): TGraphicMeta;
function GetTGraphicFileExt(AStream: TStream): string;

function IsBMP(const AFileStream: TStream): Boolean; overload;
function IsBMP(const AFileName: String): Boolean; overload;

function IsGIF(const AFileStream: TStream): Boolean; overload;
function IsGIF(const AFileName: String): Boolean; overload;

function IsJPG(const AFileStream: TStream): Boolean; overload;
function IsJPG(const AFileName: String): Boolean; overload;

function IsPNG(const AFileStream: TStream): Boolean; overload;
function IsPNG(const AFileName: String): Boolean; overload;

function IsTIF(const AFileStream: TStream): Boolean; overload;
function IsTIF(const AFileName: String): Boolean; overload;

implementation

function GetTGraphicType(AStream: TStream): TGraphicMeta;
begin
  if IsJPG(AStream) then
    Result := TJPEGImage
  else if IsBMP(AStream) then
    Result := TBitmap
  else if IsPNG(AStream) then
    Result := TdxPNGImage
  else if IsGIF(AStream) then
    Result := TGIFImage
  else if IsTIF(AStream) then
    Result := TWicImage
  else
    raise Exception.Create('Unknown image format');
end;

function GetTGraphicFileExt(AStream: TStream): string;
begin
  if IsJPG(AStream) then
    Result := '.jpg'
  else if IsBMP(AStream) then
    Result := '.bmp'
  else if IsPNG(AStream) then
    Result := '.png'
  else if IsGIF(AStream) then
    Result := '.gif'
  else if IsTIF(AStream) then
    Result := '.tif'
  else
    Result := '';
end;

function IsBMP(const AFileStream: TStream): Boolean;
var
  Buffer: Word;
begin
  with AFileStream do
  begin
    Position := 0;
    Read(Buffer, 2);
    Result := Buffer = $4D42;
    Position := 0;
  end;
end;

function IsBMP(const AFileName: String): Boolean;
var
  FileHandle: Integer;
  Buffer: Word;
begin
  FileHandle := FileOpen(AFileName, fmOpenRead);
  FileSeek(FileHandle, 0, 0);
  FileRead(FileHandle, Buffer, 2);
  FileClose(FileHandle);
  Result := Buffer = $4D42;
end;

function IsGIF(const AFileStream: TStream): Boolean;
var
  Buffer: Word;
begin
  with AFileStream do
  begin
    Position := 0;
    Read(Buffer, 2);
    Result := Buffer = $4947;
    Position := 0;
  end;
end;

function IsGIF(const AFileName: String): Boolean;
var
  FileHandle: Integer;
  Buffer: Word;
begin
  FileHandle := FileOpen(AFileName, fmOpenRead);
  FileSeek(FileHandle, 0, 0);
  FileRead(FileHandle, Buffer, 2);
  FileClose(FileHandle);
  Result := Buffer = $4947;
end;

function IsJPG(const AFileStream: TStream): Boolean;
var
  Buffer: Word;
begin
  with AFileStream do
  begin
    Position := 0;
    Read(Buffer, 2);
    Result := Buffer = $D8FF;
    Position := 0;
  end;
end;

function IsJPG(const AFileName: String): Boolean;
var
  FileHandle: Integer;
  Buffer: Word;
begin
  FileHandle := FileOpen(AFileName, fmOpenRead);
  FileSeek(FileHandle, 0, 0);
  FileRead(FileHandle, Buffer, 2);
  FileClose(FileHandle);
  Result := Buffer = $D8FF;
end;

function IsPNG(const AFileStream: TStream): Boolean;
var
  Buffer: Int64;
begin
  with AFileStream do
  begin
    Position := 0;
    Read(Buffer, 8);
    Result := (Buffer = $0A1A0A0D474E5089);
    Position := 0;
  end;
end;

function IsPNG(const AFileName: String): Boolean;
var
  FileHandle: Integer;
  Buffer: Int64;
begin
  FileHandle := FileOpen(AFileName, fmOpenRead);
  FileSeek(FileHandle, 0, 0);
  FileRead(FileHandle, Buffer, 8);
  FileClose(FileHandle);
  Result := (Buffer = $0A1A0A0D474E5089);
end;

function IsTIF(const AFileStream: TStream): Boolean;
var
  Buffer1, Buffer2: Word;
begin
  with AFileStream do
  begin
    Position := 0;
    Read(Buffer1, 2);
    Position := 2;
    Read(Buffer2, 2);
    Result := ((Buffer1 = $4949) and (Buffer2 = $002A)) or ((Buffer1 = $4D4D) and (Buffer2 = $2A00));
    Position := 0;
  end;
end;

function IsTIF(const AFileName: String): Boolean;
var
  FileHandle: Integer;
  Buffer1, Buffer2: Word;
begin
  FileHandle := FileOpen(AFileName, fmOpenRead);
  FileSeek(FileHandle, 0, 0);
  FileRead(FileHandle, Buffer1, 2);
  FileSeek(FileHandle, 2, 0);
  FileRead(FileHandle, Buffer2, 2);
  FileClose(FileHandle);
  Result := ((Buffer1 = $4949) and (Buffer2 = $002A)) or ((Buffer1 = $4D4D) and (Buffer2 = $2A00));
end;

end.
