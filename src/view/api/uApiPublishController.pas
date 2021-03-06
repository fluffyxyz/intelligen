unit uApiPublishController;

interface

uses
  // Delphi
  Windows, SysUtils, Classes, StrUtils, Math, Dialogs, Variants,
  // Spring Framework
  Spring.Collections.Lists, Spring.Collections.Dictionaries, Spring.Cryptography,
  // MultiEvent
  Generics.MultiEvents.NotifyInterface, Generics.MultiEvents.NotifyHandler,
  // Common
  uBaseConst, uBaseInterface, uAppConst, uAppInterface, uFileInterface,
  // DLLs
  uExport,
  // Api
  uApiConst, uApiFile, uApiIScriptParser, uApiMultiCastEvent, uApiTabSheetData, uApiMirrorControlBase, uApiMirrorControllerBase, uApiSettings,
  // Plugin system
  uPlugInEvent,
  // Utils
  uPathUtils, uStringUtils;

type
  TICMSWebsite = class(TInterfacedObject, ICMSWebsite)
  private
    FAccountName, FAccountPassword, FSettingsFileName, FHostWithPath, FWebsite, FSubject, FTags, FMessage: WideString;
  protected
    function GetAccountName: WideString;
    function GetAccountPassword: WideString;
    function GetSettingsFileName: WideString;
    function GetHostWithPath: WideString;
    function GetWebsite: WideString;
    function GetSubject: WideString;
    function GetTags: WideString;
    function GetMessage: WideString;
  public
    constructor Create(const AAccountName, AAccountPassword, ASettingsFileName, AHostWithPath, AWebsite, ASubject, ATags, AMessage: WideString);
    property AccountName: WideString read GetAccountName;
    property AccountPassword: WideString read GetAccountPassword;

    property SettingsFileName: WideString read GetSettingsFileName;

    property HostWithPath: WideString read GetHostWithPath;
    property Website: WideString read GetWebsite;
    property Subject: WideString read GetSubject;
    property Tags: WideString read GetTags;
    property Message: WideString read GetMessage;
  end;

  TIPublishTab = class(TInterfacedObject, IPublishTab)
  private
    FReleaseName: WideString;
    FPublishItemList: TInterfaceList<IPublishItem>;
  protected
    function GetReleaseName: WideString;
    function GetItem(const IndexOrName: OleVariant): IPublishItem;
  public
    constructor Create(const AReleaseName: WideString);
    procedure Add(const APublishItem: IPublishItem);
    property ReleaseName: WideString read GetReleaseName;
    property Item[const IndexOrName: OleVariant]: IPublishItem read GetItem;
    function Count: Integer;
    destructor Destroy; override;
  end;

  TIPublishJob = class(TInterfacedObject, IPublishJob)
  private
    FUniqueID: Longword;
    FDescription: WideString;
    FPublishTabList: TInterfaceList<IPublishTab>;
  protected
    function GetUniqueID: Longword;
    procedure SetUniqueID(AUniqueID: Longword);
    function GetDescription: WideString;
    function GetUpload(const IndexOrName: OleVariant): IPublishTab;
  public
    constructor Create(ADescription: WideString);
    procedure Add(const APublishTab: IPublishTab);
    property UniqueID: Longword read GetUniqueID write SetUniqueID;
    property Description: WideString read GetDescription;
    property Upload[const IndexOrName: OleVariant]: IPublishTab read GetUpload;
    function Count: Integer;
    destructor Destroy; override;
  end;

  TICMSWebsiteContainer = class(TInterfacedObject, ICMSWebsiteContainer)
  strict private
  type
    TPartlyType = (ptControls, ptMirrors);

    TICMSWebsiteContainerActiveController = class
    private
      FTabConnection: ITabSheetController;
      FACMSCollectionItem: TCMSWebsitesCollectionItem;

      FCanUpdatePartly: Boolean;

      FControlsCategories: Boolean;

      FControlsSide: Boolean;
      FHosterSide: Boolean;

      function IsControlValueAllowed(const AControl: IControlBasic): Boolean;
      function IsHosterAllowed(const AHoster: IMirrorControl): Boolean;

      function IsAllowed: Boolean;
      function AllControlsAllowed: Boolean;
      function HasAtLeastOneHosterAllowed: Boolean;

      property ControlsSide: Boolean read FControlsSide write FControlsSide;
      property HosterSide: Boolean read FHosterSide write FHosterSide;
    public
      constructor Create(const ATabConnection: ITabSheetController; ACMSWebsitesCollectionItem: TCMSWebsitesCollectionItem); reintroduce;
      function Active(APartlyType: TPartlyType): Boolean; overload;
      function Active: Boolean; overload;
      property CanUpdatePartly: Boolean read FCanUpdatePartly;
      destructor Destroy; override;
    end;

  var
    FICMSWebsiteContainerActiveController: TICMSWebsiteContainerActiveController;

  type
    TIScriptCheckFunc = reference to function(const AIScript: WideString): RIScriptResult;
    TIScriptParseFunc = reference to function(const AIScript: WideString; AIScriptType: TIScriptType): RIScriptResult;

    TICMSWebsiteIScriptData = class(TInterfacedObject, ICMSWebsiteIScriptData)
    private
      FIScriptType: TIScriptType;
      FCMSWebsiteCollectionItem: TCMSWebsitesCollectionItem;
      FCheckFunc: TIScriptCheckFunc;
      FParseFunc: TIScriptParseFunc;
      FCodeChanged: Boolean;
      FCode: WideString;
      FResult: RIScriptResult;
      function LoadFromFile(const AFileName: string): string;
      procedure ResetCode;
      procedure CodeChange(ACMSItemChangeType: TCMSItemChangeType; AIndex, AParam: Integer);
    protected
      function GetFileName: WideString;
      procedure SetFileName(const AFileName: WideString);
      function GetOriginalCode: WideString;
      function GetCode: WideString;
      procedure SetCode(const ACode: WideString);
      function GetPreview: WideString;

      function GetCheckedResult: RIScriptResult;
      function GetParsedResult: RIScriptResult;
    public
      constructor Create(const AIScriptType: TIScriptType; const ACMSWebsiteCollectionItem: TCMSWebsitesCollectionItem; out ACodeChange: TCMSItemChangeMethod; const ACheckFunc: TIScriptCheckFunc; const AParseFunc: TIScriptParseFunc);
      destructor Destroy; override;

      property FileName: WideString read GetFileName write SetFileName;
      property OriginalCode: WideString read GetOriginalCode;
      property Code: WideString read GetCode write SetCode;
      property Preview: WideString read GetPreview;

      property CheckedResult: RIScriptResult read GetCheckedResult;
      property ParsedResult: RIScriptResult read GetParsedResult;
    end;

  var
    FICMSWebsiteSubjectIScriptData: ICMSWebsiteIScriptData;
    FICMSWebsiteMessageIScriptData: ICMSWebsiteIScriptData;

  type
    TIPublishItem = class(TICMSWebsite, IPublishItem)
    private
      FCMSPluginPath: WideString;
      FCMSWebsiteData: ITabSheetData;
    protected
      function GetCMSPluginPath: WideString;
      function GetData: ITabSheetData;
    public
      constructor Create(AAccountName, AAccountPassword, ASettingsFileName, AHost, AWebsite, ASubject, ATags, AMessage, ACMSPluginPath: WideString; const ACMSWebsiteData: ITabSheetData);
      property CMSPluginPath: WideString read GetCMSPluginPath;
      property WebsiteData: ITabSheetData read GetData;
      destructor Destroy; override;
    end;

  private
    FTopIndex, FIndex: Integer;
    FTabConnection: ITabSheetController;
    FCMSCollectionItem: TCMSCollectionItem;
    FCMSWebsiteCollectionItem: TCMSWebsitesCollectionItem;
    FActiveChanged: Boolean;
    FActiveBuffer: Boolean;
    FDataChanged, FParsedDataSubjectChanged, FParsedDataMessageChanged: Boolean;
    FDataBuffer: ITabSheetData;
    FControlsPreviousValue, FMirrorPreviousValue: Boolean;
    FIWebsiteChange: TICMSItemChangeEventHandler;
    FISubjectChange: TICMSItemChangeEventHandler;
    FIMessageChange: TICMSItemChangeEventHandler;
    FIControlChange: TIControlEventHandler;
    FIMirrorChange: TINotifyEventHandler;

    procedure ValidateFile(const ARelativeFileName, AFileName, AFileType: string);
    function ValidateFiles: Boolean;

    procedure HandleBlackWhitelist(ACMSWebsiteCollectionItem: TCMSWebsitesCollectionItem; out AControlList: TControlDataList; out AMirrorList: TMirrorContainerList);
    procedure HandleCustomFieldList(ACMSWebsiteCollectionItem: TCMSWebsitesCollectionItem; AControlList: TControlDataList; AMirrorList: TMirrorContainerList; out ACustomFieldList: TCustomFieldList);

    procedure WebsiteChange(ACMSItemChangeType: TCMSItemChangeType; AIndex, AParam: Integer);
    procedure ControlChange(const Sender: IControlBasic);
    procedure MirrorChange(const Sender: IUnknown);
  protected
    function GetTabSheetController: ITabSheetController;
    procedure SetTabSheetController(const ATabSheetController: ITabSheetController);
    function GetCMS: WideString;
    function GetCMSInnerIndex: Integer;
    function GetCMSPluginPath: WideString;
    function GetName: WideString;
    function GetTopIndex: Integer;
    procedure SetTopIndex(ATopIndex: Integer);
    function GetIndex: Integer;
    procedure SetIndex(AIndex: Integer);
    function GetActive: WordBool;
    function GetEnabled: Boolean;
    function GetAccountName: WideString;
    procedure SetAccountName(const AAccountName: WideString);
    function GetAccountPassword: WideString;
    procedure SetAccountPassword(const AAccountPassword: WideString);

    function GetSettingsFileName: WideString;

    function GetHostWithPath: WideString;
    function GetWebsite: WideString;

    function GetSubject: WideString;
    function GetSubjectData: ICMSWebsiteIScriptData;

    function GetTags: WideString;

    function GetMessage: WideString;
    function GetMessageData: ICMSWebsiteIScriptData;
  public
    constructor Create(const ATabConnection: ITabSheetController; ACMSCollectionItem: TCMSCollectionItem; ACMSWebsitesCollectionItem: TCMSWebsitesCollectionItem);
    property TabSheetController: ITabSheetController read GetTabSheetController write SetTabSheetController;
    property CMS: WideString read GetCMS;
    property CMSInnerIndex: Integer read GetCMSInnerIndex;
    property Name: WideString read GetName;
    property TopIndex: Integer read GetTopIndex write SetTopIndex;
    property Index: Integer read GetIndex write SetIndex;
    property Active: WordBool read GetActive;
    property Enabled: Boolean read GetEnabled;
    property AccountName: WideString read GetAccountName write SetAccountName;
    property AccountPassword: WideString read GetAccountPassword write SetAccountPassword;

    function CheckIScript(const AIScript: WideString): RIScriptResult;
    function ParseIScript(const AIScript: WideString; AIScriptType: TIScriptType = itMessage): RIScriptResult;

    function GenerateData: ITabSheetData;

    function GeneratePublishItem: IPublishItem;
    function GeneratePublishTab: IPublishTab;
    function GeneratePublishJob: IPublishJob;

    property SettingsFileName: WideString read GetSettingsFileName;

    property HostWithPath: WideString read GetHostWithPath;
    property Website: WideString read GetWebsite;

    property Subject: WideString read GetSubject;
    property SubjectData: ICMSWebsiteIScriptData read GetSubjectData;

    property Tags: WideString read GetTags;

    property Message: WideString read GetMessage;
    property MessageData: ICMSWebsiteIScriptData read GetMessageData;

    destructor Destroy; override;
  end;

  TICMSContainer = class(TInterfacedObject, ICMSContainer)
  private
    FIndex: Integer;
    FTabConnection: ITabSheetController;
    FWebsiteList: TInterfaceList<ICMSWebsiteContainer>;
    FCMSCollectionItem: TCMSCollectionItem;
    FSettingsChangeEventHandler: ICMSItemChangeEventHandler;
    function CreateNewWebsiteContainer(AWebsiteIndex: Integer): ICMSWebsiteContainer;
    procedure SettingsUpdate(ACMSItemChangeType: TCMSItemChangeType; AIndex: Integer; AParam: Integer);
    procedure UpdateInternalListItemIndex;
    procedure UpdateCMSWebsiteList;
  protected
    function GetTabSheetController: ITabSheetController;
    procedure SetTabSheetController(const ATabSheetController: ITabSheetController);
    function GetName: WideString;
    function GetIndex: Integer;
    procedure SetIndex(AIndex: Integer);
    function GetWebsite(AIndex: Integer): ICMSWebsiteContainer;
  public
    constructor Create(const ATabConnection: ITabSheetController; ACMSCollectionItem: TCMSCollectionItem);
    property TabSheetController: ITabSheetController read GetTabSheetController write SetTabSheetController;
    property Name: WideString read GetName;
    property Index: Integer read GetIndex write SetIndex;
    property Website[index: Integer]: ICMSWebsiteContainer read GetWebsite;
    function Count: Integer;
    destructor Destroy; override;
  end;

  TIPublishController = class(TInterfacedObject, IPublishController)
  private
    FTabSheetController: ITabSheetController;
    FIScriptBuffer: TDictionary<string, RIScriptResult>;
    FCMSList: TInterfaceList<ICMSContainer>;
    FActive: Boolean;
    FUpdateCMSList: IUpdateCMSListEvent;
    FUpdateCMSWebsiteList: IUpdateCMSWebsiteListEvent;
    FUpdateCMSWebsite: IUpdateCMSWebsiteEvent;
    FIChange: TINotifyEventHandler;
    FPluginChangeEventHandler: IPluginChangeEventHandler;
    function CreateNewCMSContainer(ACMSIndex: Integer): ICMSContainer;
    procedure CMSUpdate(ACMSChangeType: TPluginChangeType; AIndex: Integer; AParam: Integer);
    procedure TabChange(const Sender: IUnknown);
    procedure UpdateInternalListItemIndex;
    procedure UpdateCMSList(AClose: Boolean = False);
    function FindCMSContainer(const AName: WideString): Integer;
  protected
    function GetTabSheetController: ITabSheetController;
    procedure SetTabSheetController(const ATabSheetController: ITabSheetController);

    function GetActive: WordBool;
    procedure SetActive(AActive: WordBool);

    function GetCMS(const IndexOrName: OleVariant): ICMSContainer;

    function GetUpdateCMSList: IUpdateCMSListEvent;
    function GetUpdateCMSWebsiteList: IUpdateCMSWebsiteListEvent;
    function GetUpdateCMSWebsite: IUpdateCMSWebsiteEvent;
  public
    constructor Create(const ATabConnection: ITabSheetController);
    property TabSheetController: ITabSheetController read GetTabSheetController write SetTabSheetController;
    property Active: WordBool read GetActive write SetActive;

    property CMS[const IndexOrName: OleVariant]: ICMSContainer read GetCMS;
    function Count: Integer;

    function GeneratePublishTab: IPublishTab;
    function GeneratePublishJob: IPublishJob;

    function CheckIScript(const ACMS, AWebsite, AIScript: WideString; const ATabSheetData: ITabSheetData): RIScriptResult;
    function ParseIScript(const ACMS, AWebsite, AIScript: WideString; const ATabSheetData: ITabSheetData; ADataChanged: WordBool = True): RIScriptResult; // TODO: Improve this (don't use ITabSheetData directly)

    property OnUpdateCMSList: IUpdateCMSListEvent read GetUpdateCMSList;
    property OnUpdateCMSWebsiteList: IUpdateCMSWebsiteListEvent read GetUpdateCMSWebsiteList;
    property OnUpdateCMSWebsite: IUpdateCMSWebsiteEvent read GetUpdateCMSWebsite;
    destructor Destroy; override;
  end;

implementation

uses
  uMain;

{ TICMSWebsite }

function TICMSWebsite.GetAccountName: WideString;
begin
  Result := FAccountName;
end;

function TICMSWebsite.GetAccountPassword: WideString;
begin
  Result := FAccountPassword;
end;

function TICMSWebsite.GetSettingsFileName: WideString;
begin
  Result := FSettingsFileName;
end;

function TICMSWebsite.GetHostWithPath: WideString;
begin
  Result := FHostWithPath;
end;

function TICMSWebsite.GetWebsite: WideString;
begin
  Result := FWebsite;
end;

function TICMSWebsite.GetSubject: WideString;
begin
  Result := FSubject;
end;

function TICMSWebsite.GetTags: WideString;
begin
  Result := FTags;
end;

function TICMSWebsite.GetMessage: WideString;
begin
  Result := FMessage;
end;

constructor TICMSWebsite.Create(const AAccountName, AAccountPassword, ASettingsFileName, AHostWithPath, AWebsite, ASubject, ATags, AMessage: WideString);
begin
  inherited Create;

  FAccountName := AAccountName;
  FAccountPassword := AAccountPassword;
  FSettingsFileName := ASettingsFileName;
  FHostWithPath := AHostWithPath;
  FWebsite := AWebsite;
  FSubject := ASubject;
  FTags := ATags;
  FMessage := AMessage;
end;

{ TIPublishTab }

function TIPublishTab.GetReleaseName: WideString;
begin
  Result := FReleaseName;
end;

function TIPublishTab.GetItem(const IndexOrName: OleVariant): IPublishItem;

  function Find(AName: string): Integer;
  var
    I: Integer;
  begin
    Result := -1;
    with FPublishItemList do
      for I := 0 to Count - 1 do
        if SameText(AName, Items[I].Website) then
          Exit(I);
  end;

var
  Index: Integer;
begin
  Result := nil;

  if not VarIsNull(IndexOrName) then
  begin
    Index := -1;
    if VarIsNumeric(IndexOrName) then
      Index := IndexOrName
    else
      Index := Find(IndexOrName);

    if not((Index < 0) or (Index > FPublishItemList.Count)) then
      Result := FPublishItemList.Items[Index];
  end;
end;

constructor TIPublishTab.Create(const AReleaseName: WideString);
begin
  inherited Create;
  FReleaseName := AReleaseName;
  FPublishItemList := TInterfaceList<IPublishItem>.Create;
end;

procedure TIPublishTab.Add(const APublishItem: IPublishItem);
begin
  if Assigned(APublishItem) then
    FPublishItemList.Add(APublishItem);
end;

function TIPublishTab.Count: Integer;
begin
  Result := FPublishItemList.Count;
end;

destructor TIPublishTab.Destroy;
begin
  FPublishItemList.Free;
  inherited Destroy;
end;

{ TIPublishJob }

function TIPublishJob.GetUniqueID: Longword;
begin
  Result := FUniqueID;
end;

procedure TIPublishJob.SetUniqueID(AUniqueID: Longword);
begin
  FUniqueID := AUniqueID;
end;

function TIPublishJob.GetDescription: WideString;
begin
  Result := FDescription;
end;

function TIPublishJob.GetUpload(const IndexOrName: OleVariant): IPublishTab;

  function Find(AName: string): Integer;
  var
    I: Integer;
  begin
    Result := -1;
    with FPublishTabList do
      for I := 0 to Count - 1 do
        if SameText(AName, Items[I].ReleaseName) then
          Exit(I);
  end;

var
  Index: Integer;
begin
  Result := nil;

  if not VarIsNull(IndexOrName) then
  begin
    Index := -1;
    if VarIsNumeric(IndexOrName) then
      Index := IndexOrName
    else
      Index := Find(IndexOrName);

    if not((Index < 0) or (Index > FPublishTabList.Count)) then
      Result := FPublishTabList.Items[Index];
  end;
end;

constructor TIPublishJob.Create;
begin
  inherited Create;
  FUniqueID := 0;
  FDescription := ADescription;
  FPublishTabList := TInterfaceList<IPublishTab>.Create;
end;

procedure TIPublishJob.Add(const APublishTab: IPublishTab);
begin
  FPublishTabList.Add(APublishTab);
end;

function TIPublishJob.Count: Integer;
begin
  Result := FPublishTabList.Count;
end;

destructor TIPublishJob.Destroy;
begin
  FPublishTabList.Free;
  inherited Destroy; ;
end;

{ TICMSWebsiteContainer.TICMSWebsiteContainerActiveController }

function TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.IsAllowed: Boolean;
begin
  Result := True;

  with FACMSCollectionItem.Filter do
    if Active then
    begin
      if not CanUpdatePartly then
        FControlsCategories := FTabConnection.ControlController.TypeID in FACMSCollectionItem.Filter.GetCategoriesAsTTypeIDs;
      Result := FControlsCategories;
    end;
end;

function TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.IsControlValueAllowed(const AControl: IControlBasic): Boolean;

  function GetControlsForControl(const AControls: Generics.Collections.TList<IControl>; const AControl: IControlBasic): TList<IControl>;
  var
    LIndex: Integer;
    LCategory: string;
    LIsCategory: Boolean;
  begin
    Result := TList<IControl>.Create;

    for LIndex := 0 to AControls.Count - 1 do
    begin
      LCategory := AControls.Items[LIndex].Category;
      LIsCategory := StringInTypeID(LCategory);
      if (not LIsCategory or (LIsCategory and (AControl.TypeID = StringToTypeID(LCategory)))) and
      { . } (AControl.ControlID = StringToControlID(AControls.Items[LIndex].Name)) then
        Result.Add(AControls.Items[LIndex]);
    end;
  end;

  function RelToBool(const ARel: string): Boolean;
  begin
    Result := (ARel = '=');
  end;

var
  LControlFilters: TList<IControl>;
  LFilterIndex: Integer;
  LAllowed, LHasAFilter: Boolean;
begin
  Result := True;
  LControlFilters := GetControlsForControl(FACMSCollectionItem.Filter.Controls, AControl);
  try
    if (LControlFilters.Count > 0) then
    begin
      // for not equals relations: make AND connection
      for LFilterIndex := 0 to LControlFilters.Count - 1 do
        if not RelToBool(LControlFilters.Items[LFilterIndex].Relation) then
        begin
          LAllowed := not MatchTextMask(LControlFilters.Items[LFilterIndex].Value, AControl.Value);

          if not LAllowed then
            Exit(False);
        end;
      // for equals relations: make OR connection
      LAllowed := False;
      LHasAFilter := False;
      for LFilterIndex := 0 to LControlFilters.Count - 1 do
        if RelToBool(LControlFilters.Items[LFilterIndex].Relation) then
        begin
          LHasAFilter := True;
          LAllowed := LAllowed or MatchTextMask(LControlFilters.Items[LFilterIndex].Value, AControl.Value);
        end;
      if LHasAFilter and not LAllowed then
        Exit(False);
    end;
  finally
    LControlFilters.Free;
  end;
end;

function TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.IsHosterAllowed(const AHoster: IMirrorControl): Boolean;
var
  I: Integer;
begin
  Result := False or (FACMSCollectionItem.Filter.Hosters.Count = 0);

  for I := 0 to FACMSCollectionItem.Filter.Hosters.Count - 1 do
    if GetHosterNameType(FACMSCollectionItem.Filter.Hosters.Items[I].Name) = htFile then
      if SameStr('', AHoster.Hoster) or (FACMSCollectionItem.Filter.Hosters.Items[I].Blacklist.IndexOf(AHoster.Hoster) = -1) then
        Exit(True);
end;

function TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.AllControlsAllowed: Boolean;
var
  I: Integer;
  Allowed: Boolean;
begin
  Result := True;
  if FACMSCollectionItem.Filter.Active then
    for I := 0 to FTabConnection.ControlController.ControlCount - 1 do
    begin
      Allowed := IsControlValueAllowed(FTabConnection.ControlController.Control[I]);
      if not Allowed then
        Exit(False);
    end;
end;

function TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.HasAtLeastOneHosterAllowed: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FTabConnection.MirrorController.MirrorCount - 1 do
    if IsHosterAllowed(FTabConnection.MirrorController.Mirror[I]) then
      Exit(True);
end;

constructor TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.Create;
begin
  FTabConnection := ATabConnection;
  FACMSCollectionItem := ACMSWebsitesCollectionItem;

  FCanUpdatePartly := False;

  ControlsSide := True;
  HosterSide := True;
end;

function TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.Active(APartlyType: TPartlyType): Boolean;
begin
  case APartlyType of
    ptControls:
      ControlsSide := IsAllowed and AllControlsAllowed;
    ptMirrors:
      HosterSide := HasAtLeastOneHosterAllowed;
  end;
  Result := ControlsSide and HosterSide;
end;

function TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.Active: Boolean;
begin
  if not CanUpdatePartly then
  begin
    Active(ptControls);
    Active(ptMirrors);

    FCanUpdatePartly := True;
  end;

  Result := ControlsSide and HosterSide;
end;

destructor TICMSWebsiteContainer.TICMSWebsiteContainerActiveController.Destroy;
begin
  FACMSCollectionItem := nil;
  FTabConnection := nil;
  inherited Destroy;
end;

{ TICMSWebsiteContainer.TICMSWebsiteIScriptData }

function TICMSWebsiteContainer.TICMSWebsiteIScriptData.LoadFromFile(const AFileName: string): string;
begin
  with TStringStream.Create do
    try
      LoadFromFile(AFileName);
      Result := DataString;
    finally
      Free;
    end;
end;

procedure TICMSWebsiteContainer.TICMSWebsiteIScriptData.ResetCode;
begin
  if FileExists(FileName) then
    Code := LoadFromFile(FileName)
  else
    Code := '';
end;

procedure TICMSWebsiteContainer.TICMSWebsiteIScriptData.CodeChange(ACMSItemChangeType: TCMSItemChangeType; AIndex, AParam: Integer);
begin
  if (ACMSItemChangeType = cctChange) and (AIndex = FCMSWebsiteCollectionItem.Index) then
  begin
    ResetCode;
  end;
end;

function TICMSWebsiteContainer.TICMSWebsiteIScriptData.GetFileName: WideString;
begin
  case FIScriptType of
    itSubject:
      Result := FCMSWebsiteCollectionItem.GetSubjectFileName;
    itMessage:
      Result := FCMSWebsiteCollectionItem.GetMessageFileName;
  end;
end;

procedure TICMSWebsiteContainer.TICMSWebsiteIScriptData.SetFileName(const AFileName: WideString);
var
  LNewFileName: string;
begin
  // DO NOT USE THIS FUNCTION

  LNewFileName := ExtractRelativePath(GetTemplatesCMSFolder, AFileName);

  if not SameFileName(LNewFileName, FileName) then
  begin
    case FIScriptType of
      itSubject:
        FCMSWebsiteCollectionItem.SubjectFileName := LNewFileName;
      itMessage:
        FCMSWebsiteCollectionItem.MessageFileName := LNewFileName;
    end;
    ResetCode;
  end;
end;

function TICMSWebsiteContainer.TICMSWebsiteIScriptData.GetOriginalCode: WideString;
begin
  Result := LoadFromFile(FileName);
end;

function TICMSWebsiteContainer.TICMSWebsiteIScriptData.GetCode: WideString;
begin
  Result := FCode;
end;

procedure TICMSWebsiteContainer.TICMSWebsiteIScriptData.SetCode(const ACode: WideString);
begin
  if not CompareTextByMD5(ACode, FCode) then
  begin
    FCode := ACode;
    FCodeChanged := True;
  end;
end;

function TICMSWebsiteContainer.TICMSWebsiteIScriptData.GetPreview: WideString;
begin
  Result := ParsedResult.CompiledText;
end;

function TICMSWebsiteContainer.TICMSWebsiteIScriptData.GetCheckedResult: RIScriptResult;
begin
  Result := FCheckFunc(FCode);
end;

function TICMSWebsiteContainer.TICMSWebsiteIScriptData.GetParsedResult: RIScriptResult;
begin
  if FCodeChanged then
  begin
    FResult := FParseFunc(FCode, FIScriptType);
  end;

  Result := FResult;
end;

constructor TICMSWebsiteContainer.TICMSWebsiteIScriptData.Create(const AIScriptType: TIScriptType; const ACMSWebsiteCollectionItem: TCMSWebsitesCollectionItem; out ACodeChange: TCMSItemChangeMethod; const ACheckFunc: TIScriptCheckFunc; const AParseFunc: TIScriptParseFunc);
begin
  inherited Create;
  FIScriptType := AIScriptType;
  FCMSWebsiteCollectionItem := ACMSWebsiteCollectionItem;
  ACodeChange := CodeChange;
  FCheckFunc := ACheckFunc;
  FParseFunc := AParseFunc;
  FCodeChanged := False;
  FCode := '';
  FResult.Init;

  ResetCode;
end;

destructor TICMSWebsiteContainer.TICMSWebsiteIScriptData.Destroy;
begin
  FParseFunc := nil;
  FCheckFunc := nil;
  FCMSWebsiteCollectionItem := nil;
  inherited Destroy;
end;

{ TICMSWebsiteContainer.TIPublishItem }

function TICMSWebsiteContainer.TIPublishItem.GetCMSPluginPath: WideString;
begin
  Result := FCMSPluginPath;
end;

constructor TICMSWebsiteContainer.TIPublishItem.Create;
begin
  inherited Create(AAccountName, AAccountPassword, ASettingsFileName, AHost, AWebsite, ASubject, ATags, AMessage);
  FCMSPluginPath := ACMSPluginPath;
  FCMSWebsiteData := ACMSWebsiteData;
end;

function TICMSWebsiteContainer.TIPublishItem.GetData: ITabSheetData;
begin
  Result := FCMSWebsiteData;
end;

destructor TICMSWebsiteContainer.TIPublishItem.Destroy;
begin
  FCMSWebsiteData := nil;
  inherited Destroy;
end;

{ TICMSWebsiteContainer }

procedure TICMSWebsiteContainer.ValidateFile(const ARelativeFileName, AFileName, AFileType: string);
begin
  if SameStr('', ARelativeFileName) then
    raise Exception.Create('You have to define a ' + AFileType + ' file for ' + Name + ' [' + CMS + '] inside CMS/website settings');
  if not FileExists(AFileName) then
    raise Exception.Create('The defined ' + AFileType + ' file for ' + Name + ' [' + CMS + '] was not found (relative path: ' + ARelativeFileName + ')' + sLineBreak + sLineBreak + 'Full path: ' + AFileName);
end;

function TICMSWebsiteContainer.ValidateFiles: Boolean;
begin
  Result := True;
  try
    ValidateFile(FCMSWebsiteCollectionItem.SubjectFileName, FICMSWebsiteSubjectIScriptData.FileName, 'Subject');
    ValidateFile(FCMSWebsiteCollectionItem.MessageFileName, FICMSWebsiteMessageIScriptData.FileName, 'Message');
  except
    on E: Exception do
    begin
      Result := False;
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TICMSWebsiteContainer.HandleBlackWhitelist(ACMSWebsiteCollectionItem: TCMSWebsitesCollectionItem; out AControlList: TControlDataList; out AMirrorList: TMirrorContainerList);
var
  LHostersIntex, LWhitelistIndex, LControlIndex: Integer;
  LHosterType: THosterType;
  LBlackList, LWhitelist: TStringList;

  LControlBasic: IControlBasic;
  LPicture: IPicture;

  LHasMirror: Boolean;
  LHasPicture: Boolean;
begin
  AControlList := TControlDataList.Create;
  AMirrorList := TMirrorContainerList.Create;

  LControlBasic := TabSheetController.ControlController.FindControl(cPicture);
  if Assigned(LControlBasic) then
  begin
    LControlBasic.QueryInterface(IPicture, LPicture);
  end;

  LHasMirror := False;
  LHasPicture := False;

  // Handle if hoster ranking/whitelist or blacklist is defined
  for LHostersIntex := 0 to ACMSWebsiteCollectionItem.Filter.Hosters.Count - 1 do
  begin
    LHosterType := GetHosterNameType(ACMSWebsiteCollectionItem.Filter.Hosters.Items[LHostersIntex].Name);

    LBlackList := TStringList.Create;
    LWhitelist := TStringList.Create;
    try
      // Load black- and whitelist
      LBlackList.Text := ACMSWebsiteCollectionItem.Filter.Hosters.Items[LHostersIntex].Blacklist.Text;
      if ACMSWebsiteCollectionItem.Filter.Hosters.Items[LHostersIntex].Ranked then
        LWhitelist.Text := ACMSWebsiteCollectionItem.Filter.Hosters.Items[LHostersIntex].Whitelist.Text;

      // Reduce black- and whitelist to used hosters
      case LHosterType of
        htFile:
          begin

            for LWhitelistIndex := LWhitelist.Count - 1 downto 0 do
              if not Assigned(TabSheetController.MirrorController.Mirror[LWhitelist.Strings[LWhitelistIndex]]) then
              begin
                LWhitelist.Delete(LWhitelistIndex);
              end;
            for LWhitelistIndex := LBlackList.Count - 1 downto 0 do
              if not Assigned(TabSheetController.MirrorController.Mirror[LBlackList.Strings[LWhitelistIndex]]) then
              begin
                LBlackList.Delete(LWhitelistIndex);
              end;

          end;
        htImage:
          begin

            if Assigned(LPicture) then
            begin
              for LWhitelistIndex := LWhitelist.Count - 1 downto 0 do
                if not Assigned(LPicture.Mirror[LWhitelist.Strings[LWhitelistIndex]]) then
                begin
                  LWhitelist.Delete(LWhitelistIndex);
                end;
              for LWhitelistIndex := LBlackList.Count - 1 downto 0 do
                if not Assigned(LPicture.Mirror[LBlackList.Strings[LWhitelistIndex]]) then
                begin
                  LBlackList.Delete(LWhitelistIndex);
                end;
            end;

          end;
      end;

      // Make the ordering and filter for blacklist
      for LWhitelistIndex := 0 to LWhitelist.Count - 1 do
      begin
        // If not in blacklist
        if (LBlackList.IndexOf(LWhitelist.Strings[LWhitelistIndex]) = -1) then
        begin
          LBlackList.Add(LWhitelist.Strings[LWhitelistIndex]); // Add to blacklist, to not let add again into mirror list

          case LHosterType of
            htFile:
              begin

                for LControlIndex := 0 to TabSheetController.MirrorController.MirrorCount - 1 do
                  if SameText(LWhitelist.Strings[LWhitelistIndex], TabSheetController.MirrorController.Mirror[LControlIndex].Hoster) then
                  begin
                    AMirrorList.Add(TabSheetController.MirrorController.Mirror[LControlIndex].CloneInstance());
                    Break;
                  end;

              end;
            htImage:
              begin

                if Assigned(LPicture) then
                begin
                  for LControlIndex := 0 to LPicture.MirrorCount - 1 do
                    if SameText(LWhitelist.Strings[LWhitelistIndex], LPicture.Mirror[LControlIndex].Name) and not SameStr('', LPicture.Mirror[LControlIndex].Value) then
                    begin
                      AControlList.Add(LPicture.Mirror[LControlIndex].CloneInstance());
                      LHasPicture := True;
                      Break;
                    end
                    else if SameText(LWhitelist.Strings[LWhitelistIndex], 'OriginalValue') and not SameStr('', LPicture.Value) then
                    begin
                      AControlList.Add(LPicture.CloneInstance());
                      LHasPicture := True;
                      Break;
                    end;
                end;

                Break; // only one picture needed, break whitelist loop
              end;
          end;
        end;
      end;

      case LHosterType of
        htFile:
          begin

            for LControlIndex := 0 to TabSheetController.MirrorController.MirrorCount - 1 do
              if (LBlackList.IndexOf(TabSheetController.MirrorController.Mirror[LControlIndex].Hoster) = -1) then
              begin
                AMirrorList.Add(TabSheetController.MirrorController.Mirror[LControlIndex].CloneInstance());
              end;

            LHasMirror := True;

          end;
        htImage:
          begin

            if Assigned(LPicture) and not LHasPicture then
            begin
              for LControlIndex := 0 to LPicture.MirrorCount - 1 do
                if (LBlackList.IndexOf(LPicture.Mirror[LControlIndex].Name) = -1) and not SameStr('', LPicture.Mirror[LControlIndex].Value) then
                begin
                  AControlList.Add(LPicture.Mirror[LControlIndex].CloneInstance());
                  LHasPicture := True;
                  Break;
                end;

              if not LHasPicture then
              begin
                AControlList.Add(LPicture.CloneInstance());
                LHasPicture := True;
              end;
            end;

          end;
      end;

    finally
      LWhitelist.Free;
      LBlackList.Free;
    end;
  end;

  // Handle if nothing is defined i.e. "filters"-tag not specified
  if not LHasMirror then
  begin
    for LControlIndex := 0 to TabSheetController.MirrorController.MirrorCount - 1 do
      AMirrorList.Add(TabSheetController.MirrorController.Mirror[LControlIndex].CloneInstance());
  end;
  if Assigned(LPicture) and not LHasPicture then
  begin
    for LControlIndex := 0 to LPicture.MirrorCount - 1 do
      if not SameStr('', LPicture.Mirror[LControlIndex].Value) then
      begin
        AControlList.Add(LPicture.Mirror[LControlIndex].CloneInstance());
        LHasPicture := True;
        Break;
      end;

    if not LHasPicture then
      AControlList.Add(LPicture.CloneInstance());
  end;

  LPicture := nil;
  LControlBasic := nil;
end;

procedure TICMSWebsiteContainer.HandleCustomFieldList(ACMSWebsiteCollectionItem: TCMSWebsitesCollectionItem; AControlList: TControlDataList; AMirrorList: TMirrorContainerList; out ACustomFieldList: TCustomFieldList);
var
  LCustomFieldIndex: Integer;
  LIScript: WideString;
  LIScriptResult: RIScriptResult;
begin
  ACustomFieldList := TCustomFieldList.Create;

  with ACMSWebsiteCollectionItem.CustomFields do
    for LCustomFieldIndex := 0 to CustomFields.Count - 1 do
    begin
      LIScript := CustomFields[LCustomFieldIndex].Value;
      LIScriptResult := TabSheetController.PublishController.ParseIScript(CMS, Website, LIScript, TITabSheetData.Create(TabSheetController.TypeID, AControlList, AMirrorList, ACustomFieldList, False)); // TODO: Improve this
      ACustomFieldList.Add(TINameValueItem.Create(CustomFields[LCustomFieldIndex].Name, IfThen(not LIScriptResult.HasError, LIScriptResult.CompiledText)));
    end;
end;

procedure TICMSWebsiteContainer.WebsiteChange(ACMSItemChangeType: TCMSItemChangeType; AIndex, AParam: Integer);
var
  LNewValue: Boolean;
begin
  if (AIndex = FCMSWebsiteCollectionItem.Index) then
  begin
    FActiveChanged := True;
    FDataChanged := True;

    with FICMSWebsiteContainerActiveController do
    begin
      FICMSWebsiteContainerActiveController.FCanUpdatePartly := False;
      LNewValue := FICMSWebsiteContainerActiveController.Active;
      if not(LNewValue = FActiveBuffer) then
      begin
        FActiveBuffer := LNewValue;
        FTabConnection.PublishController.OnUpdateCMSWebsite.Invoke(TopIndex, Index, LNewValue);
      end;
      FActiveChanged := False;
    end;
  end;
end;

procedure TICMSWebsiteContainer.ControlChange(const Sender: IControlBasic);
var
  LNewValue: Boolean;
begin
  FActiveChanged := True;
  FDataChanged := True;
  FParsedDataSubjectChanged := True;
  FParsedDataMessageChanged := True;

  with FICMSWebsiteContainerActiveController do
    if CanUpdatePartly then
    begin
      LNewValue := FICMSWebsiteContainerActiveController.Active(ptControls);
      if not(LNewValue = FControlsPreviousValue) then
      begin
        FControlsPreviousValue := LNewValue;
        FTabConnection.PublishController.OnUpdateCMSWebsite.Invoke(TopIndex, Index, LNewValue);
      end;
    end;
end;

procedure TICMSWebsiteContainer.MirrorChange(const Sender: IInterface);
var
  LNewValue: Boolean;
begin
  FActiveChanged := True;
  FDataChanged := True;
  FParsedDataSubjectChanged := True;
  FParsedDataMessageChanged := True;

  with FICMSWebsiteContainerActiveController do
    if CanUpdatePartly then
    begin
      LNewValue := FICMSWebsiteContainerActiveController.Active(ptMirrors);
      if not(LNewValue = FMirrorPreviousValue) then
      begin
        FMirrorPreviousValue := LNewValue;
        FTabConnection.PublishController.OnUpdateCMSWebsite.Invoke(TopIndex, Index, LNewValue);
      end;
    end;
end;

function TICMSWebsiteContainer.GetTabSheetController: ITabSheetController;
begin
  Result := FTabConnection;
end;

procedure TICMSWebsiteContainer.SetTabSheetController(const ATabSheetController: ITabSheetController);
begin
  FTabConnection := ATabSheetController;
  FICMSWebsiteContainerActiveController.FTabConnection := ATabSheetController;
end;

function TICMSWebsiteContainer.GetCMS: WideString;
begin
  Result := FCMSCollectionItem.Name;
end;

function TICMSWebsiteContainer.GetCMSInnerIndex: Integer;
begin
  Result := FCMSCollectionItem.Index;
end;

function TICMSWebsiteContainer.GetCMSPluginPath: WideString;
begin
  Result := FCMSCollectionItem.GetPath;
end;

function TICMSWebsiteContainer.GetName: WideString;
begin
  Result := FCMSWebsiteCollectionItem.Name;
end;

function TICMSWebsiteContainer.GetTopIndex: Integer;
begin
  Result := FTopIndex;
end;

procedure TICMSWebsiteContainer.SetTopIndex(ATopIndex: Integer);
begin
  FTopIndex := ATopIndex;
end;

function TICMSWebsiteContainer.GetIndex: Integer;
begin
  Result := FIndex;
end;

procedure TICMSWebsiteContainer.SetIndex(AIndex: Integer);
begin
  FIndex := AIndex;
end;

function TICMSWebsiteContainer.GetActive: WordBool;
begin
  if FActiveChanged then
  begin
    FActiveBuffer := FICMSWebsiteContainerActiveController.Active;
    FActiveChanged := False;
  end;

  Result := FActiveBuffer;
end;

function TICMSWebsiteContainer.GetEnabled: Boolean;
begin
  Result := FCMSWebsiteCollectionItem.Enabled;
end;

function TICMSWebsiteContainer.GetAccountName: WideString;
begin
  Result := FCMSWebsiteCollectionItem.AccountName;
end;

procedure TICMSWebsiteContainer.SetAccountName(const AAccountName: WideString);
begin
  FCMSWebsiteCollectionItem.AccountName := AAccountName;
end;

function TICMSWebsiteContainer.GetAccountPassword: WideString;
begin
  Result := FCMSWebsiteCollectionItem.AccountPassword;
end;

procedure TICMSWebsiteContainer.SetAccountPassword(const AAccountPassword: WideString);
begin
  FCMSWebsiteCollectionItem.AccountPassword := AAccountPassword;
end;

function TICMSWebsiteContainer.GetSettingsFileName: WideString;
begin
  Result := FCMSWebsiteCollectionItem.GetPath;
end;

function TICMSWebsiteContainer.GetHostWithPath: WideString;
begin
  Result := FCMSWebsiteCollectionItem.HostWithPath;
end;

function TICMSWebsiteContainer.GetWebsite: WideString;
begin
  Result := FCMSWebsiteCollectionItem.Website;
end;

function TICMSWebsiteContainer.GetSubject: WideString;
begin
  Result := FICMSWebsiteSubjectIScriptData.Preview;
end;

function TICMSWebsiteContainer.GetSubjectData: ICMSWebsiteIScriptData;
begin
  Result := FICMSWebsiteSubjectIScriptData;
end;

function TICMSWebsiteContainer.GetTags: WideString;
begin
  Result := '';
  if Assigned(FTabConnection.ControlController.FindControl(cTags)) then
    Result := FTabConnection.ControlController.FindControl(cTags).Value;
end;

function TICMSWebsiteContainer.GetMessage: WideString;
begin
  Result := FICMSWebsiteMessageIScriptData.Preview;
end;

function TICMSWebsiteContainer.GetMessageData: ICMSWebsiteIScriptData;
begin
  Result := FICMSWebsiteMessageIScriptData;
end;

constructor TICMSWebsiteContainer.Create;
var
  LSubjectChange, LMessageChange: TCMSItemChangeMethod;
begin
  inherited Create;

  FICMSWebsiteContainerActiveController := TICMSWebsiteContainerActiveController.Create(ATabConnection, ACMSWebsitesCollectionItem);

  FICMSWebsiteSubjectIScriptData := TICMSWebsiteIScriptData.Create(itSubject, ACMSWebsitesCollectionItem, LSubjectChange, CheckIScript, ParseIScript);
  FICMSWebsiteMessageIScriptData := TICMSWebsiteIScriptData.Create(itMessage, ACMSWebsitesCollectionItem, LMessageChange, CheckIScript, ParseIScript);

  FTopIndex := -1;
  FIndex := -1;
  FTabConnection := ATabConnection;
  FCMSCollectionItem := ACMSCollectionItem;
  FCMSWebsiteCollectionItem := ACMSWebsitesCollectionItem;

  FActiveChanged := True; // Need to be true to make first update.
  FActiveBuffer := False;

  FDataChanged := True; // Need to be true to make first update.
  FParsedDataSubjectChanged := True;
  FParsedDataMessageChanged := True;
  FDataBuffer := nil;

  FControlsPreviousValue := True; // Need to be true to make first update.
  FMirrorPreviousValue := True;

  FIWebsiteChange := TICMSItemChangeEventHandler.Create(WebsiteChange);
  FCMSCollectionItem.OnWebsitesChange.Add(FIWebsiteChange);

  FISubjectChange := TICMSItemChangeEventHandler.Create(LSubjectChange);
  FCMSCollectionItem.OnSubjectsChange.Add(FISubjectChange);

  FIMessageChange := TICMSItemChangeEventHandler.Create(LMessageChange);
  FCMSCollectionItem.OnMessagesChange.Add(FIMessageChange);

  FIControlChange := TIControlEventHandler.Create(ControlChange);
  FTabConnection.ControlController.OnControlChange.Add(FIControlChange);

  FIMirrorChange := TINotifyEventHandler.Create(MirrorChange);
  FTabConnection.MirrorController.OnChange.Add(FIMirrorChange);
end;

function TICMSWebsiteContainer.CheckIScript(const AIScript: WideString): RIScriptResult;
begin
  Result := TabSheetController.PublishController.CheckIScript(CMS, Website, AIScript, GenerateData);
end;

function TICMSWebsiteContainer.ParseIScript(const AIScript: WideString; AIScriptType: TIScriptType = itMessage): RIScriptResult;
var
  LChanged: Boolean;
begin
  case AIScriptType of
    itSubject:
      LChanged := FParsedDataSubjectChanged;
    itMessage:
      LChanged := FParsedDataMessageChanged;
  end;
  Result := TabSheetController.PublishController.ParseIScript(CMS, Website, AIScript, GenerateData, LChanged);
  case AIScriptType of
    itSubject:
      FParsedDataSubjectChanged := False;
    itMessage:
      FParsedDataMessageChanged := False;
  end;
end;

function TICMSWebsiteContainer.GenerateData: ITabSheetData;
var
  LControlList: TControlDataList;
  LMirrorList: TMirrorContainerList;
  LCustomFieldList: TCustomFieldList;

  LControlIndex: Integer;
begin
  if FDataChanged then
  begin
    HandleBlackWhitelist(FCMSWebsiteCollectionItem, LControlList, LMirrorList);

    for LControlIndex := 0 to TabSheetController.ControlController.ControlCount - 1 do
    begin
      if not(TabSheetController.ControlController.Control[LControlIndex].ControlID = cPicture) then
        LControlList.Add(TabSheetController.ControlController.Control[LControlIndex]);
    end;

    HandleCustomFieldList(FCMSWebsiteCollectionItem, LControlList, LMirrorList, LCustomFieldList);

    FDataBuffer := TITabSheetData.Create(TabSheetController.TypeID, LControlList, LMirrorList, LCustomFieldList);
    FDataChanged := False;
  end;

  Result := FDataBuffer;
end;

function TICMSWebsiteContainer.GeneratePublishItem: IPublishItem;
begin
  Result := nil;
  if ValidateFiles then
    Result := TIPublishItem.Create(AccountName, AccountPassword, SettingsFileName, HostWithPath, Website, Subject, Tags, Message, GetCMSPluginPath, GenerateData);
end;

function TICMSWebsiteContainer.GeneratePublishTab: IPublishTab;
var
  PublishTab: TIPublishTab;
begin
  PublishTab := TIPublishTab.Create(TabSheetController.ReleaseName);

  PublishTab.Add(GeneratePublishItem);

  Result := PublishTab;
end;

function TICMSWebsiteContainer.GeneratePublishJob: IPublishJob;
var
  PublishJob: TIPublishJob;
begin
  PublishJob := TIPublishJob.Create(TabSheetController.ReleaseNameShort + ' @ ' + Website);

  PublishJob.Add(GeneratePublishTab);

  Result := PublishJob;
end;

destructor TICMSWebsiteContainer.Destroy;
begin
  FCMSCollectionItem.OnMessagesChange.Remove(FIMessageChange);
  FCMSCollectionItem.OnSubjectsChange.Remove(FISubjectChange);
  FCMSCollectionItem.OnWebsitesChange.Remove(FIWebsiteChange);
  FTabConnection.MirrorController.OnChange.Remove(FIMirrorChange);
  FTabConnection.ControlController.OnControlChange.Remove(FIControlChange);
  FDataBuffer := nil;
  FIMirrorChange := nil;
  FIControlChange := nil;
  FIMessageChange := nil;
  FISubjectChange := nil;
  FIWebsiteChange := nil;
  FTabConnection := nil;
  FCMSCollectionItem := nil;
  FCMSWebsiteCollectionItem := nil;
  FICMSWebsiteMessageIScriptData := nil;
  FICMSWebsiteSubjectIScriptData := nil;
  FICMSWebsiteContainerActiveController.Free;
  inherited Destroy;
end;

{ TICMSContainer }

function TICMSContainer.CreateNewWebsiteContainer(AWebsiteIndex: Integer): ICMSWebsiteContainer;
begin
  Result := TICMSWebsiteContainer.Create(FTabConnection, FCMSCollectionItem, TCMSWebsitesCollectionItem(FCMSCollectionItem.Websites.Items[AWebsiteIndex]));
end;

procedure TICMSContainer.SettingsUpdate(ACMSItemChangeType: TCMSItemChangeType; AIndex: Integer; AParam: Integer);

  function FindCMSWebsiteItem(AName: string): Integer;
  var
    I: Integer;
  begin
    Result := -1;
    for I := 0 to Count - 1 do
      if SameText(AName, Website[I].Name) then
        Exit(I);
  end;

  function FindNextEnabledCMSWebsiteItem(AStartIndex: Integer): Integer;
  var
    I: Integer;
  begin
    Result := -1;
    with FCMSCollectionItem.Websites do
      for I := AStartIndex to Count - 1 do
        if TCMSWebsitesCollectionItem(Items[I]).Enabled then
          Exit(I);
  end;

  function CMSWebsiteItemToInternalIndex(AIndex: Integer): Integer;
  begin
    if (AIndex = -1) then
      Exit(-1);
    Result := FindCMSWebsiteItem(TCMSWebsitesCollectionItem(FCMSCollectionItem.Websites.Items[AIndex]).name);
  end;

var
  LIndex, LCMSWebsiteIndex: Integer;
  LCMSWebsiteName: string;
begin
  with TCMSWebsitesCollectionItem(FCMSCollectionItem.Websites.Items[AIndex]) do
  begin
    LCMSWebsiteIndex := Index;
    LCMSWebsiteName := Name;
  end;

  case ACMSItemChangeType of
    cctAdd:
      ;
    cctDelete:
      begin
        LIndex := FindCMSWebsiteItem(LCMSWebsiteName);
        if not(LIndex = -1) then
          FWebsiteList.Delete(LIndex);
      end;
    cctEnabled:
      begin
        if AParam = 0 then
        begin
          LIndex := FindCMSWebsiteItem(LCMSWebsiteName);
          if not(LIndex = -1) then
            FWebsiteList.Delete(LIndex);
        end
        else
        begin
          LIndex := FindCMSWebsiteItem(LCMSWebsiteName);
          if (LIndex = -1) then
          begin
            LIndex := CMSWebsiteItemToInternalIndex(FindNextEnabledCMSWebsiteItem(LCMSWebsiteIndex + 1));
            if (LIndex = -1) then
              FWebsiteList.Add(CreateNewWebsiteContainer(LCMSWebsiteIndex))
            else
              FWebsiteList.Insert(LIndex, CreateNewWebsiteContainer(LCMSWebsiteIndex));
          end;
        end;
      end;
  end;

  UpdateInternalListItemIndex;
  UpdateCMSWebsiteList;
end;

procedure TICMSContainer.UpdateInternalListItemIndex;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    with Website[I] do
    begin
      TopIndex := Self.Index;
      Index := I;
    end;
end;

procedure TICMSContainer.UpdateCMSWebsiteList;
begin
  if TabSheetController.IsTabActive then
    FTabConnection.PublishController.OnUpdateCMSWebsiteList.Invoke(Self, Index);
end;

function TICMSContainer.GetTabSheetController: ITabSheetController;
begin
  Result := FTabConnection;
end;

procedure TICMSContainer.SetTabSheetController(const ATabSheetController: ITabSheetController);
begin
  FTabConnection := ATabSheetController;
end;

function TICMSContainer.GetName: WideString;
begin
  Result := FCMSCollectionItem.Name;
end;

function TICMSContainer.GetIndex: Integer;
begin
  Result := FIndex;
end;

procedure TICMSContainer.SetIndex(AIndex: Integer);
begin
  FIndex := AIndex;
  UpdateInternalListItemIndex;
end;

function TICMSContainer.GetWebsite(AIndex: Integer): ICMSWebsiteContainer;
begin
  Result := FWebsiteList[AIndex];
end;

constructor TICMSContainer.Create(const ATabConnection: ITabSheetController; ACMSCollectionItem: TCMSCollectionItem);
var
  LIndex: Integer;
begin
  inherited Create;

  FIndex := -1;
  FTabConnection := ATabConnection;
  FWebsiteList := TInterfaceList<ICMSWebsiteContainer>.Create;
  FCMSCollectionItem := ACMSCollectionItem;

  with FCMSCollectionItem do
  begin
    for LIndex := 0 to Websites.Count - 1 do
      if TCMSWebsitesCollectionItem(Websites.Items[LIndex]).Enabled then
        FWebsiteList.Add(CreateNewWebsiteContainer(LIndex));
    UpdateInternalListItemIndex;
    FSettingsChangeEventHandler := TICMSItemChangeEventHandler.Create(SettingsUpdate);
    OnSettingsChange.Add(FSettingsChangeEventHandler);
  end;
end;

function TICMSContainer.Count: Integer;
begin
  Result := FWebsiteList.Count;
end;

destructor TICMSContainer.Destroy;
begin
  FCMSCollectionItem.OnSettingsChange.Remove(FSettingsChangeEventHandler);
  FCMSCollectionItem := nil;
  FWebsiteList.Free;
  FTabConnection := nil;
  inherited;
end;

{ TIPublishController }

function TIPublishController.CreateNewCMSContainer(ACMSIndex: Integer): ICMSContainer;
begin
  with SettingsManager.Settings.Plugins do
    Result := TICMSContainer.Create(TabSheetController, TCMSCollectionItem(CMS.Items[ACMSIndex]));
end;

procedure TIPublishController.CMSUpdate(ACMSChangeType: TPluginChangeType; AIndex: Integer; AParam: Integer);

  function FindPrevEnabledCMSItem(AEndIndex: Integer): Integer;
  var
    I: Integer;
  begin
    Result := -1;
    with SettingsManager.Settings.Plugins.CMS do
      for I := Min(AEndIndex, Count) - 1 downto 0 do
        with TCMSCollectionItem(Items[I]) do
          if Enabled then
            Exit(I);
  end;

  function FindNextEnabledCMSItem(AStartIndex: Integer): Integer;
  var
    I: Integer;
  begin
    Result := -1;
    with SettingsManager.Settings.Plugins.CMS do
      for I := AStartIndex to Count - 1 do
        if TCMSCollectionItem(Items[I]).Enabled then
          Exit(I);
  end;

  function CMSItemToInternalIndex(AIndex: Integer): Integer;
  begin
    if (AIndex = -1) then
      Exit(-1);
    Result := FindCMSContainer(TCMSCollectionItem(SettingsManager.Settings.Plugins.CMS.Items[AIndex]).name);
  end;

var
  Index, Position, CMSIndex: Integer;
  CMSName: string;
  buf: ICMSContainer;
begin
  with TCMSCollectionItem(SettingsManager.Settings.Plugins.CMS.Items[AIndex]) do
  begin
    CMSIndex := Index;
    CMSName := Name;
  end;

  case ACMSChangeType of
    pctAdd:
      ; // nothing
    pctMove:
      begin
        Index := FindCMSContainer(CMSName);

        if not(Index = -1) then
        begin
          buf := CMS[Index];
          FCMSList.Delete(Index);

          Position := FindPrevEnabledCMSItem(CMSIndex);
          if (Position = -1) then
            FCMSList.Insert(0, buf)
          else
          begin
            Position := CMSItemToInternalIndex(Position);
            FCMSList.Insert(Position + 1, buf);
          end;
        end;
      end;
    pctDelete:
      begin
        Index := FindCMSContainer(CMSName);
        if not(Index = -1) then
          FCMSList.Delete(Index);
      end;
    pctEnabled:
      begin
        if AParam = 0 then
        begin
          Index := FindCMSContainer(CMSName);
          if not(Index = -1) then
            FCMSList.Delete(Index);
        end
        else
        begin
          Index := FindCMSContainer(CMSName);
          if (Index = -1) then
          begin
            Index := CMSItemToInternalIndex(FindNextEnabledCMSItem(CMSIndex + 1));
            if (Index = -1) then
              FCMSList.Add(CreateNewCMSContainer(CMSIndex))
            else
              FCMSList.Insert(Index, CreateNewCMSContainer(CMSIndex));
          end;
        end;
      end;
  end;

  UpdateInternalListItemIndex;
  UpdateCMSList;
end;

procedure TIPublishController.TabChange(const Sender: IInterface);
begin
  UpdateCMSList;
end;

procedure TIPublishController.UpdateInternalListItemIndex;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    CMS[I].Index := I;
end;

procedure TIPublishController.UpdateCMSList(AClose: Boolean = False);
begin
  if TabSheetController.IsTabActive then
  begin
    if AClose then
      OnUpdateCMSList.Invoke(nil)
    else
      OnUpdateCMSList.Invoke(Self);
  end;
end;

function TIPublishController.FindCMSContainer(const AName: WideString): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if SameText(AName, CMS[I].Name) then
      Exit(I);
end;

constructor TIPublishController.Create;
begin
  inherited Create;

  FTabSheetController := ATabConnection;

  FIScriptBuffer := TDictionary<string, RIScriptResult>.Create;

  FCMSList := TInterfaceList<ICMSContainer>.Create;

  FUpdateCMSList := TIUpdateCMSListEvent.Create;
  FUpdateCMSWebsiteList := TIUpdateCMSWebsiteListEvent.Create;
  FUpdateCMSWebsite := TIUpdateCMSWebsiteEvent.Create;

  FIChange := TINotifyEventHandler.Create(TabChange);
  FPluginChangeEventHandler := TIPluginChangeEventHandler.Create(CMSUpdate);
end;

function TIPublishController.GetTabSheetController: ITabSheetController;
begin
  Result := FTabSheetController;
end;

procedure TIPublishController.SetTabSheetController(const ATabSheetController: ITabSheetController);
begin
  FTabSheetController := ATabSheetController;
end;

function TIPublishController.GetActive: WordBool;
begin
  Result := FActive;
end;

procedure TIPublishController.SetActive(AActive: WordBool);
var
  LCMSIndex: Integer;
begin
  if not(Active = AActive) then
  begin
    case AActive of
      True:
        begin
          with SettingsManager.Settings.Plugins do
          begin
            for LCMSIndex := 0 to CMS.Count - 1 do
              if TCMSCollectionItem(CMS.Items[LCMSIndex]).Enabled then
                FCMSList.Add(CreateNewCMSContainer(LCMSIndex));
            UpdateInternalListItemIndex;

            OnCMSChange.Add(FPluginChangeEventHandler);
          end;

          TabSheetController.PageController.OnChange.Add(FIChange);
        end;
      False:
        begin
          TabSheetController.PageController.OnChange.Remove(FIChange);

          with SettingsManager.Settings.Plugins do
            OnCMSChange.Remove(FPluginChangeEventHandler);
        end;
    end;
    FActive := AActive;
  end;
end;

function TIPublishController.GetCMS(const IndexOrName: OleVariant): ICMSContainer;
var
  Index: Integer;
begin
  Result := nil;

  if not VarIsNull(IndexOrName) then
  begin
    Index := -1;
    if VarIsNumeric(IndexOrName) then
      Index := IndexOrName
    else
      Index := FindCMSContainer(IndexOrName);

    if not((Index < 0) or (Index > FCMSList.Count)) then
      Result := FCMSList[Index];
  end;
end;

function TIPublishController.GetUpdateCMSList: IUpdateCMSListEvent;
begin
  Result := FUpdateCMSList;
end;

function TIPublishController.GetUpdateCMSWebsiteList: IUpdateCMSWebsiteListEvent;
begin
  Result := FUpdateCMSWebsiteList;
end;

function TIPublishController.GetUpdateCMSWebsite: IUpdateCMSWebsiteEvent;
begin
  Result := FUpdateCMSWebsite;
end;

function TIPublishController.Count: Integer;
begin
  Result := FCMSList.Count;
end;

function TIPublishController.GeneratePublishTab: IPublishTab;
var
  PublishTab: TIPublishTab;

  I, J: Integer;
begin
  PublishTab := TIPublishTab.Create(TabSheetController.ReleaseName);

  for I := 0 to Count - 1 do
    for J := 0 to CMS[I].Count - 1 do
      with CMS[I].Website[J] do
        if Active then
          PublishTab.Add(GeneratePublishItem);

  Result := PublishTab;
end;

function TIPublishController.GeneratePublishJob: IPublishJob;
var
  LPublishJob: TIPublishJob;
begin
  LPublishJob := TIPublishJob.Create('All active for ' + TabSheetController.ReleaseNameShort);

  LPublishJob.Add(GeneratePublishTab);

  Result := LPublishJob;
end;

function TIPublishController.CheckIScript(const ACMS, AWebsite, AIScript: WideString; const ATabSheetData: ITabSheetData): RIScriptResult;
begin
  with TIScirptParser.Create(ACMS, AWebsite, ATabSheetData, AIScript) do
    try
      Result := ErrorAnalysis();
    finally
      Free;
    end;
end;

function TIPublishController.ParseIScript(const ACMS, AWebsite, AIScript: WideString; const ATabSheetData: ITabSheetData; ADataChanged: WordBool = True): RIScriptResult;

  function GetWhitelistString(const ATabSheetData: ITabSheetData): string;
  var
    LControlData: IControlData;
    LPicture: IPicture;
    LIndex: Integer;
  begin
    Result := '';
    LControlData := ATabSheetData.FindControl(cPicture);
    if Assigned(LControlData) then
      Result := Result + LControlData.Value;
    for LIndex := 0 to ATabSheetData.MirrorCount - 1 do
      Result := Result + ATabSheetData.Mirror[LIndex].Hoster;
    LControlData := nil;
  end;

var
  LHash: string;
  LContainsKey: Boolean;
  LIScriptResult: RIScriptResult;
begin
  LHash := CreateMD5.ComputeHash(Trim(AIScript + GetWhitelistString(ATabSheetData))).ToHexString;
  if (FIScriptBuffer.Count > 20) then
  begin
    FIScriptBuffer.Clear;
  end;
  LContainsKey := FIScriptBuffer.ContainsKey(LHash);
  if ADataChanged or not LContainsKey then
  begin
    with TIScirptParser.Create(ACMS, AWebsite, ATabSheetData, AIScript) do
      try
        LIScriptResult := Execute();
      finally
        Free;
      end;
    if LContainsKey then
      FIScriptBuffer.Items[LHash] := LIScriptResult
    else
      FIScriptBuffer.Add(LHash, LIScriptResult);
  end;

  Result := FIScriptBuffer[LHash];
end;

destructor TIPublishController.Destroy;
begin
  UpdateCMSList(True);

  FPluginChangeEventHandler := nil;
  FIChange := nil;

  FUpdateCMSWebsite := nil;
  FUpdateCMSWebsiteList := nil;
  FUpdateCMSList := nil;
  FCMSList.Free;

  FIScriptBuffer.Free;

  FTabSheetController := nil;

  inherited Destroy;
end;

end.
