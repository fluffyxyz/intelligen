{ ********************************************************
  *                                                      *
  *  Kewlshare.com Delphi API                            *
  *  Version 2.0.0.0                                     *
  *  Copyright (c) 2010 Sebastian Klatte                 *
  *                                                      *
  ******************************************************** }
unit uKewlshareCom;

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
  TKewlshareCom = class(TFileHosterPlugIn)
  public
    function GetName: WideString; override; safecall;
    function CheckLink(const AFile: WideString): TLinkInfo; override; safecall;
    // function CheckLinks(const AFiles: WideString): Integer; override; safecall;
  end;

implementation

{ TKewlshareCom }

function TKewlshareCom.GetName: WideString;
begin
  result := 'Kewlshare.com';
end;

function TKewlshareCom.CheckLink(const AFile: WideString): TLinkInfo;
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
        Get(AFile, _postreply);

        if (Pos('<h1 style="text-align:left;">', _postreply.DataString) > 0) then
        begin
          LinkInfo.Status := csOffline;
          Exit;
        end;

        with TRegExpr.Create do
          try
            ModifierS := True;

            InputString := _postreply.DataString;
            Expression := '<title>(.*?)\.html</title>';

            LinkInfo.Status := csOnline;
            LinkInfo.Size := 0;

            if Exec(InputString) then
              LinkInfo.FileName := Match[1];
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
  result := LinkInfo;
end;

end.
