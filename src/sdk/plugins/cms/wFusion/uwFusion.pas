unit uwFusion;

interface

uses
  // Delphi
  Windows, SysUtils, Classes, Variants,
  // RegEx
  RegExpr,
  // Utils,
  uHTMLUtils, uStringUtils,
  // Common
  uBaseConst, uBaseInterface,
  // HTTPManager
  uHTTPInterface, uHTTPClasses,
  // Plugin system
  uPlugInCMSClass, uPlugInCMSFormbasedClass, uPlugInHTTPClasses;

type
  TwFusionSettings = class(TCMSFormbasedPlugInSettings)
  published
    property use_plainlinks;
    property use_textasdescription;

    property categorys;
  end;

  TwFusion = class(TCMSFormbasedPlugIn)
  private
    wFusionSettings: TwFusionSettings;
  protected
    function SettingsClass: TCMSPlugInSettingsMeta; override;
    function GetSettings: TCMSPlugInSettings; override;
    procedure SetSettings(ACMSPlugInSettings: TCMSPlugInSettings); override;
    function LoadSettings(const AData: ITabSheetData = nil): Boolean; override;

    function DoBuildLoginRequest(out AHTTPRequest: IHTTPRequest; out AHTTPParams: IHTTPParams; out AHTTPOptions: IHTTPOptions; APrevResponse: string; ACAPTCHALogin: Boolean = False): Boolean; override;
    function DoAnalyzeLogin(const AResponseStr: string; out ACAPTCHALogin: Boolean): Boolean; override;

    function DoBuildPostRequest(const AData: ITabSheetData; out AHTTPRequest: IHTTPRequest; out AHTTPParams: IHTTPParams; out AHTTPOptions: IHTTPOptions; APrevResponse: string; APrevRequest: Double): Boolean; override;
    function DoAnalyzePost(const AResponseStr: string; AHTTPProcess: IHTTPProcess): Boolean; override;
  public
    function GetName: WideString; override; safecall;
    function DefaultCharset: WideString; override; safecall;
    function BelongsTo(const AWebsiteSourceCode: WideString): WordBool; override; safecall;
    function GetIDs: Integer; override; safecall;
    function GetArticleLink(const AURL: WideString; const AArticleID: Integer): WideString; override; safecall;
  end;

implementation

function TwFusion.SettingsClass;
begin
  Result := TwFusionSettings;
end;

function TwFusion.GetSettings;
begin
  Result := wFusionSettings;
end;

procedure TwFusion.SetSettings;
begin
  wFusionSettings := ACMSPlugInSettings as TwFusionSettings;
end;

function TwFusion.LoadSettings;
begin
  Result := inherited LoadSettings(AData);
  with wFusionSettings do
  begin
    if Assigned(AData) and (categorys = null) then
    begin
      ErrorMsg := 'category is undefined!';
      Result := False;
    end;
  end;
end;

function TwFusion.DoBuildLoginRequest;
begin
  Result := True;

  AHTTPRequest := THTTPRequest.Create(Website + 'login/');
  with AHTTPRequest do
  begin
    Referer := Website;
    CharSet := wFusionSettings.CharSet;
  end;

  AHTTPParams := THTTPParams.Create;
  with AHTTPParams do
  begin
    AddFormField('name', AccountName);
    AddFormField('password', AccountPassword);
    AddFormField('login', 'Login');
  end;

  AHTTPOptions := TPlugInHTTPOptions.Create(Self);
end;

function TwFusion.DoAnalyzeLogin;
begin
  ACAPTCHALogin := False;
  Result := not(Pos('logout/', AResponseStr) = 0);
  if not Result then
    with TRegExpr.Create do
      try
        InputString := AResponseStr;
        Expression := '<h3>(.*?)<\/h3>';

        if Exec(InputString) then
          Self.ErrorMsg := HTML2Text(Match[1]);
      finally
        Free;
      end;
end;

function TwFusion.DoBuildPostRequest;
var
  I: Integer;

  _lang: string;
begin
  Result := True;

  AHTTPRequest := THTTPRequest.Create(Website + 'upload/');
  with AHTTPRequest do
  begin
    Referer := Website;
    CharSet := wFusionSettings.CharSet;
  end;

  AHTTPParams := THTTPParams.Create;
  with AHTTPParams do
  begin
    if Assigned(AData.FindControl(cReleaseName)) then
      AddFormField('title', AData.FindControl(cReleaseName).Value);

    AddFormField('category', VarToStr(wFusionSettings.categorys));

    if Assigned(AData.FindControl(cPicture)) then
      AddFormField('cover', AData.FindControl(cPicture).Value);

    if Assigned(AData.FindControl(cGenre)) then
      AddFormField('genre', AData.FindControl(cGenre).Value);

    if Assigned(AData.FindControl(cPassword)) then
      AddFormField('password', AData.FindControl(cPassword).Value);

    if Assigned(AData.FindControl(cLanguage)) then
    begin
      _lang := AData.FindControl(cLanguage).Value;

      if (Pos('GER', _lang) > 0) and not(Pos('ENG', _lang) > 0) and not(Pos('FRE', _lang) > 0) and not(Pos('SPA', _lang) > 0) and not(Pos('JPN', _lang) > 0) then
        AddFormField('lang', '1')
      else if (Pos('ENG', _lang) > 0) and not(Pos('GER', _lang) > 0) and not(Pos('FRE', _lang) > 0) and not(Pos('SPA', _lang) > 0) and not(Pos('JPN', _lang) > 0) then
        AddFormField('lang', '2')
      else if (Pos('SPA', _lang) > 0) and not(Pos('GER', _lang) > 0) and not(Pos('FRE', _lang) > 0) and not(Pos('ENG', _lang) > 0) and not(Pos('JPN', _lang) > 0) then
        AddFormField('lang', '5')
      else if (Pos('FRE', _lang) > 0) and not(Pos('GER', _lang) > 0) and not(Pos('ENG', _lang) > 0) and not(Pos('SPA', _lang) > 0) and not(Pos('JPN', _lang) > 0) then
        AddFormField('lang', '6')
      else if (Pos('JPN', _lang) > 0) and not(Pos('GER', _lang) > 0) and not(Pos('FRE', _lang) > 0) and not(Pos('SPA', _lang) > 0) and not(Pos('ENG', _lang) > 0) then
        AddFormField('lang', '8')
      else
        AddFormField('lang', '3');
    end;

    if not wFusionSettings.use_textasdescription then
    begin
      if Assigned(AData.FindControl(cDescription)) then
        AddFormField('description', AData.FindControl(cDescription).Value);
    end
    else
      AddFormField('description', Message);

    if Assigned(AData.FindControl(cNFO)) then
      AddFormField('nfo', AData.FindControl(cNFO).Value);

    for I := 0 to AData.MirrorCount - 1 do
    begin
      if wFusionSettings.use_plainlinks and (AData.Mirror[I].DirectlinkCount > 0) then
        AddFormField('urls[]', AData.Mirror[I].Directlink[0].Value)
      else if not wFusionSettings.use_plainlinks and (AData.Mirror[I].CrypterCount > 0) then
        AddFormField('urls[]', AData.Mirror[I].Crypter[0].Value)
      else
      begin
        ErrorMsg := 'No directlink or crypter initialized! (enable use_plainlinks with a directlink for each mirror or disable use_plainlinks and add a crypter)';
        Result := False;
      end;
    end;

    AddFormField('mirror_count', IntToStr(AData.MirrorCount));

    AddFormField('upload', 'Download eintragen');
  end;

  AHTTPOptions := TPlugInHTTPOptions.Create(Self);
end;

function TwFusion.DoAnalyzePost;
begin
  Result := not(Pos('<br /><br /><a href=', AResponseStr) = 0);
  if not Result then
    with TRegExpr.Create do
      try
        InputString := AResponseStr;
        Expression := 'r<\/div>\s+<div class="new">\s+<br \/>(.*?)<br /><br />';

        if Exec(InputString) then
          Self.ErrorMsg := Trim(HTML2Text(Match[1]));
      finally
        Free;
      end;
end;

function TwFusion.GetName;
begin
  Result := 'wFusion';
end;

function TwFusion.DefaultCharset;
begin
  Result := 'UTF-8';
end;

function TwFusion.BelongsTo;
begin
  // TODO:
  Result := False;
end;

function TwFusion.GetIDs;
begin
  // TODO:
  Result := FCheckedIDsList.Count;
end;

function TwFusion.GetArticleLink;
begin
  // TODO:
  Result := Format('%s?id=%d', [AURL, AArticleID]);
end;

end.
