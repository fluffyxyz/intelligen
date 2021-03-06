{ ********************************************************
  *                                                      *
  *  Zshare.net Delphi API                               *
  *  Version 2.0.0.0                                     *
  *  Copyright (c) 2010 Sebastian Klatte                 *
  *                                                      *
  ******************************************************** }
unit uZshareNet;

interface

uses
  // Delphi
  Windows, SysUtils, Classes, Math, HTTPApp,
  // Reg Ex
  RegExpr,
  // Common
  uBaseConst,
  // HTTPManager
  uHTTPInterface, uHTTPClasses,
  // plugin system
  uPlugInFileHosterClass, uPlugInHTTPClasses, uPlugInConst,
  // Utils
  uPathUtils, uSizeUtils, uURLUtils;

type
  TZshareNet = class(TFileHosterPlugIn)
  public
    function GetName: WideString; override; safecall;
    function CheckLink(const AFile: WideString): TLinkInfo; override; safecall;
    // function CheckLinks(const AFiles: WideString): Integer; override; safecall;
  end;

implementation

{ TZshareNet }

function TZshareNet.GetName: WideString;
begin
  Result := 'Zshare.net';
end;

function TZshareNet.CheckLink(const AFile: WideString): TLinkInfo;
var
  LinkInfo: TLinkInfo;
  _postreply: TStringStream;
begin
  with LinkInfo do
  begin
    Link := AFile;
    Status := csUnknown;
    Size := 0;
    FileName := '';
    Checksum := '';
  end;
  {
  with TIdHTTPHelper.Create(Self) do
    try
      _postreply := TStringStream.Create('', CP_UTF8);
      try
        try
          Get(AFile, _postreply);
        except

        end;

        if (Pos('File Not Found', _postreply.DataString) > 0) then
          LinkInfo.Status := csOffline
        else
          with TRegExpr.Create do
            try
              InputString := _postreply.DataString;
              Expression := '<h2>Download: (.*?)<\/h2>.*?>([\d\.]+)(\w+)<';

              if Exec(InputString) then
              begin
                LinkInfo.Status := csOnline;
                LinkInfo.Size := TSizeFormatter.SizeToByte(Match[2], Match[3]);
                LinkInfo.FileName := Match[1];
              end;
            finally
              Free;
            end;
      finally
        _postreply.Free;
      end;
    finally
      Free;
    end;
  }
  Result := LinkInfo;
end;

end.
