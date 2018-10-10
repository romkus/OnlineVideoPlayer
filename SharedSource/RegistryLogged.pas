{*******************************************************}
{                                                       }
{           CodeGear Delphi Runtime Library             }
{                                                       }
{           Copyright (c) 1995-2008 CodeGear            }
{           Modified in 2015 by romkus at Victor&Co     }
{                                                       }
{*******************************************************}

unit RegistryLogged;

{$R-,T-,H+,X+}

interface

uses {$IFDEF LINUX} WinUtils, {$ENDIF} Windows, Classes, SysUtils, IniFiles,
   DataHelper, OSFuncHelper;

const cs_CantCloseKeyOf = 'не вдалося закрити ключ';
      cs_CantOpenKeyOf = 'не вдалося відкрити ключ';
      cs_CantCreateKeyOf = 'не вдалося створити ключ';
      cs_CantFlushKeyOf = 'не вдалося записати з кеша ключ';
      cs_CantEnumSubkeyOf = 'не вдалося отримати підключ із переліку для ключа';
      cs_CantDeleteKeyOf = 'не вдалося видалити ключ';
      cs_CantDeleteValueOf = 'не вдалося видалити значення';
      cs_CantQueryInfoAboutValueOf = 'не вдалося отримати інформацію про значення';
      cs_CantQueryInfoAboutKeyOf = 'не вдалося отримати інформацію про ключ';
      cs_CantLoadKeyOf = 'не вдалося завантажити ключ';
      cs_CantUnloadKeyOf = 'не вдалося звільнити завантажений раніше ключ';
      cs_CantRestoreKeyOf = 'не вдалося відновити ключ із копії';
      cs_CantSaveKeyOf = 'не вдалося записати копію ключа';
      cs_CantConnectRegistryOf = 'не вдалося підключити віддалений реєстр';
      cs_CantReplaceKeyOf = 'не вдалося поміняти файл ключа';
      cs_To = 'на';
      cs_WithBackupIn = 'із резервною копією у';
      cs_FromFile = 'із файла';
      cs_ToFile = 'у файл';
      cs_ExpandEnvironmentStringsFailed =
         'не вдалося розіменувати рядок зі змінними середовища у ExpandEnvironmentStrings';

      RRF_NOEXPAND = $10000000;
      ci_RegBufLenIncrement = 128;
      ci_MaxRegBufLenIncrements = 8192;
      cs_LineBreak = c_CR + c_LF;
      cs_TwoZeroes = Chr(0) + Chr(0);
type
  ERegistryException = class(Exception);

  TRegKeyInfo = record
    NumSubKeys: DWord;
    MaxSubKeyLen: DWord;
    NumValues: DWord;
    MaxValueLen: DWord;
    MaxDataLen: DWord;
    FileTime: TFileTime;
  end;

  TRegDataType = (rdUnknown, rdString, rdExpandString, rdInteger, rdBinary,
    rdMultiString);

  TRegDataInfo = record
    RegData: TRegDataType;
    DataSize: DWord;
  end;

  TRegistry = class(TObject)
  private
    FCurrentKey: HKEY;
    FRootKey: HKEY;
    FLazyWrite: Boolean;
    FCurrentPath: string;
    FCloseRootKey: Boolean;
    FAccess: LongWord;

    cLogFile: DataHelper.TLogFile;
    //cDLLLoader: OSFuncHelper.TDLLLoader;

    //cpRegGetValue: OSFuncHelper.TRegGetValue;

    procedure SetRootKey(Value: HKEY);
    function RegOpenKeyExAndLog(Const sProcName:String;
      hKey: HKEY; lpSubKey: PWideChar;
      ulOptions: DWORD; samDesired: REGSAM; var phkResult: HKEY;
      Const sKeyName:String = ''): Boolean;
    function RegCloseKeyAndLog(Const sProcName:String; hKey: HKEY;
      Const sKeyName:String = ''): Boolean;
    procedure ReadError(const Name: string);

    function GetDataInfoOldFunc(const ValueName: string; var Value: TRegDataInfo): Boolean;
  protected
    procedure ChangeKey(Value: HKey; const Path: string);
    function GetBaseKey(Relative: Boolean): HKey;

    function GetDataOldFunc(const Name: string; Buffer: Pointer;
      BufSize: DWord; var RegData: TRegDataType;
      Var dMoreDataNeeded:Boolean): DWord; // Virtual;
    function GetData(const Name: string; Buffer: Pointer;
      BufSize: DWord; var RegData: TRegDataType): DWord; // Virtual;
    function GetDataEx(const Name: string; Buffer: Pointer;
      BufSize: DWord; var RegData: TRegDataType;
      Var dMoreDataNeeded:Boolean): DWord; // Virtual;

    Procedure AllocateAndGetDataEx(const Name: string;
      Var dBuffer: Pointer;
      Var dBufSize: DWord; var RegData: TRegDataType); // Virtual;

    function GetKey(const Key: string): HKEY;// Virtual;
    procedure PutData(const Name: string; Buffer: Pointer;
      BufSize: DWord; RegData: TRegDataType);// Virtual;
    procedure SetCurrentKey(Value: HKEY);
  public
    constructor Create(sLogFile:TLogFile = Nil); overload;
    constructor Create(AAccess: LongWord; sLogFile:TLogFile = Nil); overload;

    destructor Destroy; override;
    procedure CloseKey;
    function CreateKey(const Key: string): Boolean;
    function DeleteKey(const Key: string): Boolean;
    function DeleteValue(const Name: string): Boolean;
    function GetDataAsString(const ValueName: string; PrefixType: Boolean = false): string;
    function GetDataInfo(const ValueName: string; var Value: TRegDataInfo): Boolean;
    function GetDataSize(const ValueName: string): DWord;
    function GetDataType(const ValueName: string): TRegDataType;
    function GetKeyInfo(var Value: TRegKeyInfo): Boolean;
    procedure GetKeyNames(Strings: TStrings);
    procedure GetValueNames(Strings: TStrings);
    function HasSubKeys: Boolean;
    function KeyExists(const Key: string): Boolean;
    function LoadKey(const Key, FileName: string): Boolean;
    procedure MoveKey(const OldName, NewName: string; Delete: Boolean);
    function OpenKey(const Key: string; CanCreate: Boolean): Boolean;
    function OpenKeyReadOnly(const Key: String): Boolean;
    function ReadCurrency(const Name: string): Currency;
    function ReadBinaryData(const Name: string; var Buffer; BufSize: DWord): DWord;
    Procedure ReadBinaryDataEx(const Name: string; var Buffer:Pointer;
      Var dBufSize: DWord);
    function ReadBool(const Name: string): Boolean;
    function ReadDate(const Name: string): TDateTime;
    function ReadDateTime(const Name: string): TDateTime;
    function ReadFloat(const Name: string): Double;
    function ReadInteger(const Name: string): Integer;
    function ReadString(const Name: string;
      sExpandRegExpandEnvironmentVarsInStrings: Boolean = False): string;
    function ReadTime(const Name: string): TDateTime;
    function RegistryConnect(const UNCName: string): Boolean;
    procedure RenameValue(const OldName, NewName: string);
    function ReplaceKey(const Key, FileName, BackUpFileName: string): Boolean;
    function RestoreKey(const Key, FileName: string): Boolean;
    function SaveKey(const Key, FileName: string): Boolean;
    function UnLoadKey(const Key: string): Boolean;
    function ValueExists(const Name: string): Boolean;
    procedure WriteCurrency(const Name: string; Value: Currency);
    procedure WriteBinaryData(const Name: string; var Buffer; BufSize: DWord);
    procedure WriteBool(const Name: string; Value: Boolean);
    procedure WriteDate(const Name: string; Value: TDateTime);
    procedure WriteDateTime(const Name: string; Value: TDateTime);
    procedure WriteFloat(const Name: string; Value: Double);
    procedure WriteInteger(const Name: string; Value: Integer);
    procedure WriteStringWithAutoStringType(const Name, Value: string);
    procedure WriteString(const Name, Value: string);
    procedure WriteExpandString(const Name, Value: string);
    procedure WriteMultiString(const Name, Value: string;
      sReplaceLineBreaksWithZeroes:Boolean = True);
    procedure WriteTime(const Name: string; Value: TDateTime);
    property CurrentKey: HKEY read FCurrentKey;
    property CurrentPath: string read FCurrentPath;
    property LazyWrite: Boolean read FLazyWrite write FLazyWrite;
    property RootKey: HKEY read FRootKey write SetRootKey;
    property Access: LongWord read FAccess write FAccess;
      //   Заміняє назви змінних середовища ОС, що вказані у рядку, на
      // їхні значення:
    Function ExpandEnvironmentVarsInString(Var sdString:String):Boolean;

    procedure LogLastOSError(sCommentToError:String;
      sRaiseExceptionIfCantLogError:Boolean = True); overload;
    procedure LogLastOSError(sCommentToError:String; LastError: Integer;
      sRaiseExceptionIfCantLogError:Boolean = True); overload;
    procedure LogException(Const sError: Exception;
      sRaiseExceptionIfCantLogError:Boolean = True;
      sRaiseAllways:Boolean = False);
    procedure LogExceptionAddOsError(Const sError: Exception;
      LastError: Integer;
      sRaiseExceptionIfCantLogError:Boolean = True;
      sRaiseAllways:Boolean = False); overload;
    procedure LogExceptionAddOsError(Const sError: Exception;
      sRaiseExceptionIfCantLogError:Boolean = True;
      sRaiseAllways:Boolean = False); overload;
  end;

  {TLoggedRegistry = class(TRegistry)
  private
    cLogFile:TLogFile;
  protected
    function GetData(const Name: string; Buffer: Pointer; Virtual;
      BufSize: Integer; var RegData: TRegDataType): Integer;
    function GetKey(const Key: string): HKEY; Virtual;
    procedure PutData(const Name: string;
      Buffer: Pointer; BufSize: Integer; RegData: TRegDataType); Virtual;
  public
    constructor Create(sLogFile:TLogFile); overload;
    constructor Create(AAccess: LongWord; sLogFile:TLogFile); overload;
    function OpenKey(const Key: string; CanCreate: Boolean): Boolean; override;
    function OpenKeyReadOnly(const Key: String): Boolean; override;
  end;}

  TRegIniFile = class(TRegistry)
  private
    FFileName: string;
  public
    constructor Create(const FileName: string); overload;
    constructor Create(const FileName: string; AAccess: LongWord); overload;
    function ReadString(const Section, Ident, Default: string): string;
    function ReadInteger(const Section, Ident: string;
      Default: Longint): Longint;
    procedure WriteInteger(const Section, Ident: string; Value: Longint);
    procedure WriteString(const Section, Ident, Value: string);
    function ReadBool(const Section, Ident: string; Default: Boolean): Boolean;
    procedure WriteBool(const Section, Ident: string; Value: Boolean);
    procedure ReadSection(const Section: string; Strings: TStrings);
    procedure ReadSections(Strings: TStrings);
    procedure ReadSectionValues(const Section: string; Strings: TStrings);
    procedure EraseSection(const Section: string);
    procedure DeleteKey(const Section, Ident: string);
    property FileName: string read FFileName;
  end;

  TRegistryIniFile = class(TCustomIniFile)
  private
    FRegIniFile: TRegIniFile;
  public
    constructor Create(const FileName: string); overload;
    constructor Create(const FileName: string; AAccess: LongWord); overload;
    destructor Destroy; override;
    function ReadDate(const Section, Name: string; Default: TDateTime): TDateTime; override;
    function ReadDateTime(const Section, Name: string; Default: TDateTime): TDateTime; override;
    function ReadInteger(const Section, Ident: string; Default: Longint): Longint; override;
    function ReadFloat(const Section, Name: string; Default: Double): Double; override;
    function ReadString(const Section, Ident, Default: string): string; override;
    function ReadTime(const Section, Name: string; Default: TDateTime): TDateTime; override;
    function ReadBinaryStream(const Section, Name: string; Value: TStream): Integer; override;
//    procedure ReadKeys(const Section: string; Sections: TStrings);
    procedure WriteDate(const Section, Name: string; Value: TDateTime); override;
    procedure WriteDateTime(const Section, Name: string; Value: TDateTime); override;
    procedure WriteFloat(const Section, Name: string; Value: Double); override;
    procedure WriteInteger(const Section, Ident: string; Value: Longint); override;
    procedure WriteString(const Section, Ident, Value: string); override;
    procedure WriteTime(const Section, Name: string; Value: TDateTime); override;
    procedure WriteBinaryStream(const Section, Name: string; Value: TStream); override;
    procedure ReadSection(const Section: string; Strings: TStrings); override;
    procedure ReadSections(Strings: TStrings); overload; override;
    procedure ReadSections(const Section: string; Strings: TStrings); overload; override;
    procedure ReadSectionValues(const Section: string; Strings: TStrings); override;
    procedure EraseSection(const Section: string); override;
    procedure DeleteKey(const Section, Ident: string); override;
    procedure UpdateFile; override;

    property RegIniFile: TRegIniFile read FRegIniFile;
  end;

implementation

uses RTLConsts;

//procedure ReadError(const Name: string);
//begin
//  raise ERegistryException.CreateResFmt(@SInvalidRegType, [Name]);
//end;

procedure TRegistry.ReadError(const Name: string);
Begin
  Self.LogException(ERegistryException.CreateResFmt(@SInvalidRegType, [Name]),
    True, True);
End;

function IsRelative(const Value: string): Boolean;
begin
  Result := not ((Value <> '') and (Value[1] = '\'));
end;

function RegDataToDataType(Value: TRegDataType): DWord;
begin
  case Value of
    rdString: Result := REG_SZ;
    rdExpandString: Result := REG_EXPAND_SZ;
    rdMultiString: Result := REG_MULTI_SZ;
    rdInteger: Result := REG_DWORD;
    rdBinary: Result := REG_BINARY;
  else
    Result := REG_NONE;
  end;
end;

function DataTypeToRegData(Value: DWord): TRegDataType;
begin
  if Value = REG_SZ then Result := rdString
  else if Value = REG_EXPAND_SZ then Result := rdExpandString
  else if Value = REG_MULTI_SZ then Result := rdMultiString
  else if Value = REG_DWORD then Result := rdInteger
  else if Value = REG_BINARY then Result := rdBinary
  else Result := rdUnknown;
end;

function BinaryToHexString(const BinaryData: array of Byte; const PrefixStr: string): string;
var
  DataSize, I, Offset: Integer;
  HexData: string;
  PResult: PChar;
begin
  OffSet := 0;
  if PrefixStr <> '' then
  begin
    Result := PrefixStr;
    Inc(Offset, Length(PrefixStr));
  end;
  DataSize := Length(BinaryData);

  SetLength(Result, Offset + (DataSize*3) - 1); // less one for last ','
  PResult := PChar(Result); // Use a char pointer to reduce string overhead
  for I := 0 to DataSize - 1 do
  begin
    HexData := IntToHex(BinaryData[I], 2);
    PResult[Offset] := HexData[1];
    PResult[Offset+1] := HexData[2];
    if I < DataSize - 1 then
      PResult[Offset+2] := ',';
    Inc(Offset, 3);
  end;
end;

{ TRegistry }

procedure TRegistry.LogLastOSError(sCommentToError:String;
  sRaiseExceptionIfCantLogError:Boolean = True);
Begin
  if sRaiseExceptionIfCantLogError or
    (System.Assigned(Self.cLogFile) and Self.cLogFile.Opened) then
  OSFuncHelper.LogLastOsError(sCommentToError, Self.cLogFile);
End;
procedure TRegistry.LogLastOSError(sCommentToError:String; LastError: Integer;
  sRaiseExceptionIfCantLogError:Boolean = True);
Begin
  if sRaiseExceptionIfCantLogError or
    (System.Assigned(Self.cLogFile) and Self.cLogFile.Opened) then
  OSFuncHelper.LogLastOsError(sCommentToError, LastError, Self.cLogFile);
End;

procedure TRegistry.LogException(Const sError: Exception;
      sRaiseExceptionIfCantLogError:Boolean = True;
      sRaiseAllways:Boolean = False);
Begin
  if System.Assigned(Self.cLogFile) and Self.cLogFile.Opened then
  Begin
    Self.cLogFile.WriteMessage(sError.Message);
  End
  Else if sRaiseExceptionIfCantLogError then
    raise sError;
  if sRaiseAllways then raise sError;
End;

procedure TRegistry.LogExceptionAddOsError(Const sError: Exception;
      LastError: Integer;
      sRaiseExceptionIfCantLogError:Boolean = True;
      sRaiseAllways:Boolean = False);
Var ccMessage:String;
    ccRegException: ERegistryException;
Begin
  ccMessage:= sError.Message + c_Space + c_SystemSays + c_Space +
    SysUtils.SysErrorMessage(LastError);

  ccRegException:= ERegistryException.Create(ccMessage);
  Self.LogException(ccRegException, sRaiseExceptionIfCantLogError,
      sRaiseAllways);
End;

procedure TRegistry.LogExceptionAddOsError(Const sError: Exception;
      sRaiseExceptionIfCantLogError:Boolean = True;
      sRaiseAllways:Boolean = False);
Begin
  Self.LogExceptionAddOsError(sError,
      Windows.GetLastError,
      sRaiseExceptionIfCantLogError,
      sRaiseAllways);
End;

constructor TRegistry.Create(sLogFile:TLogFile = Nil);
begin
  RootKey := HKEY_CURRENT_USER;
  FAccess := KEY_ALL_ACCESS;
  LazyWrite := True;

  Self.cLogFile:= sLogFile;

  //Self.cpRegGetValue:= Nil;

  {try
    Self.cDLLLoader:= OSFuncHelper.TDLLLoader.Create(cs_Advapi32Name,
      Self.cLogFile);
  except
    Self.cDLLLoader:= Nil;
  end;

  if System.Assigned(Self.cDLLLoader) then
  Begin
    Self.cpRegGetValue:= Self.cDLLLoader.GetDLLProcOrFuncAddr(
      cs_RegGetValueProcName);
  End;}
end;

constructor TRegistry.Create(AAccess: LongWord; sLogFile:TLogFile = Nil);
begin
  Create(sLogFile);
  FAccess := AAccess;
end;

destructor TRegistry.Destroy;
begin
  CloseKey;

  //SysUtils.FreeAndNil(Self.cDLLLoader);

  //Self.cpRegGetValue:= Nil;

    //   Файл журнала тут не створювали тому і звільняти тут не будемо,
    // тільки обнулимо... на випадок якщо об'єкт файла буде інтерфейсним:
  Self.cLogFile:= Nil;
  inherited;
end;

procedure TRegistry.CloseKey;
const cs_ProcName = 'TRegistry.CloseKey';
var ccResult:Integer;
begin
  if CurrentKey <> 0 then
  begin
    if not LazyWrite then
    Begin
      ccResult:= RegFlushKey(CurrentKey);
      if ccResult<>ERROR_SUCCESS then
        Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantFlushKeyOf+c_Space+c_Quotes+Self.CurrentPath+c_Quotes+//+SysUtils.IntToStr(CurrentKey)+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
    End;
    ccResult:= RegCloseKey(CurrentKey);
    if ccResult<>ERROR_SUCCESS then
      Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantCloseKeyOf+c_Space+c_Quotes+Self.CurrentPath+c_Quotes+//+SysUtils.IntToStr(CurrentKey)+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);

    FCurrentKey := 0;
    FCurrentPath := '';
  end;
end;

procedure TRegistry.SetRootKey(Value: HKEY);
const cs_ProcName = 'TRegistry.SetRootKey';
Var ccResult:LongInt;
begin
  if RootKey <> Value then
  begin
    if FCloseRootKey then
    begin
      ccResult:= RegCloseKey(RootKey);
      if ccResult<>ERROR_SUCCESS then
        Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantCloseKeyOf+c_Space+SysUtils.IntToStr(RootKey)+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);

      FCloseRootKey := False;
    end;
    FRootKey := Value;
    CloseKey;
  end;
end;

procedure TRegistry.ChangeKey(Value: HKey; const Path: string);
begin
  CloseKey;
  FCurrentKey := Value;
  FCurrentPath := Path;
end;

function TRegistry.GetBaseKey(Relative: Boolean): HKey;
begin
  if (CurrentKey = 0) or not Relative then
    Result := RootKey else
    Result := CurrentKey;
end;

procedure TRegistry.SetCurrentKey(Value: HKEY);
begin
  FCurrentKey := Value;
end;

function TRegistry.CreateKey(const Key: string): Boolean;
const cs_ProcName = 'TRegistry.CreateKey';
var
  TempKey: HKey;
  S: string;
  Disposition: DWord;
  Relative: Boolean;
  ccResult: Integer;
begin
  TempKey := 0;
  S := Key;
  Relative := IsRelative(S);
  if not Relative then Delete(S, 1, 1);
  ccResult:= RegCreateKeyEx(GetBaseKey(Relative), PChar(S), 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, nil, TempKey, @Disposition);
  Result := ccResult = ERROR_SUCCESS;
  if Result then
  Begin
    ccResult:=RegCloseKey(TempKey);
    if ccResult<>ERROR_SUCCESS then
        Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantCloseKeyOf+c_Space+SysUtils.IntToStr(TempKey)+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);
  End
  else
    Self.LogExceptionAddOsError(
      ERegistryException.CreateResFmt(@SRegCreateFailed, [Key]),
        ccResult, True, True);

end;

function TRegistry.RegOpenKeyExAndLog(Const sProcName:String;
      hKey: HKEY; lpSubKey: PWideChar;
      ulOptions: DWORD; samDesired: REGSAM; var phkResult: HKEY;
      Const sKeyName:String = ''): Boolean;
Var ccResult:Integer;
Begin
  ccResult:= Windows.RegOpenKeyEx(hKey, lpSubKey, ulOptions, samDesired,
    phkResult);
  Result:= ccResult = ERROR_SUCCESS;
  if Not(Result) then
  Begin
    if sKeyName = '' then
      Self.LogLastOSError(sProcName+c_DoubleDot+c_Space+
               cs_CantOpenKeyOf+c_Space+SysUtils.IntToStr(hKey)+//c_Quotes+sKeyName+c_Quotes+
               c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
               False)
    Else
      Self.LogLastOSError(sProcName+c_DoubleDot+c_Space+
               cs_CantOpenKeyOf+c_Space+c_Quotes+sKeyName+c_Quotes+
               c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
               False)
  End;
End;

function TRegistry.RegCloseKeyAndLog(Const sProcName:String; hKey: HKEY;
      Const sKeyName:String = ''): Boolean;
Var ccResult:Integer;
Begin
  ccResult:= Windows.RegCloseKey(hKey);
  Result:= ccResult = ERROR_SUCCESS;
  if Not(Result) then
  Begin
    if sKeyName = '' then
      Self.LogLastOSError(sProcName+c_DoubleDot+c_Space+
               cs_CantCloseKeyOf+c_Space+SysUtils.IntToStr(hKey)+//c_Quotes+sKeyName+c_Quotes+
               c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
               False)
    Else
      Self.LogLastOSError(sProcName+c_DoubleDot+c_Space+
               cs_CantCloseKeyOf+c_Space+c_Quotes+sKeyName+c_Quotes+
               c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
               False)
  End;
End;

function TRegistry.OpenKey(const Key: string; Cancreate: boolean): Boolean;
const cs_ProcName = 'TRegistry.OpenKey';
var
  TempKey: HKey;
  S: string;
  Disposition: DWord;
  Relative: Boolean;
  ccResult: Integer;
  ccTriedCreate: Boolean;
begin
  S := Key;
  Relative := IsRelative(S);

  if not Relative then Delete(S, 1, 1);
  TempKey := 0;
  if not CanCreate or (S = '') then
  begin
    ccTriedCreate:= False;
    ccResult:= RegOpenKeyEx(GetBaseKey(Relative), PChar(S), 0,
      FAccess, TempKey)
  end
  else
  Begin
    ccTriedCreate:= True;
    ccResult:= RegCreateKeyEx(GetBaseKey(Relative), PChar(S), 0, nil,
      REG_OPTION_NON_VOLATILE, FAccess, nil, TempKey, @Disposition);
  End;

  Result := ccResult = ERROR_SUCCESS;

  if Result then
  begin
    if (CurrentKey <> 0) and Relative then S := CurrentPath + '\' + S;
    ChangeKey(TempKey, S);
  end
  else if ccTriedCreate then
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
               cs_CantCreateKeyOf+c_Space+c_Quotes+Key+c_Quotes+
               c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
               False)
  else
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
               cs_CantOpenKeyOf+c_Space+c_Quotes+Key+c_Quotes+
               c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
               False)
end;

function TRegistry.OpenKeyReadOnly(const Key: string): Boolean;
const cs_ProcName = 'TRegistry.OpenKeyReadOnly';
var
  TempKey: HKey;
  S: string;
  Relative: Boolean;
  WOWFlags: Cardinal;
begin
  S := Key;
  Relative := IsRelative(S);

  if not Relative then Delete(S, 1, 1);
  TempKey := 0;
  // Preserve KEY_WOW64_XXX flags for later use
  WOWFlags := FAccess and KEY_WOW64_RES;
  Result := Self.RegOpenKeyExAndLog(cs_ProcName,
      GetBaseKey(Relative), PChar(S), 0,
      KEY_READ or WOWFlags, TempKey, Key);
  if Result then
  begin
    FAccess := KEY_READ or WOWFlags;
    if (CurrentKey <> 0) and Relative then S := CurrentPath + '\' + S;
    ChangeKey(TempKey, S);
  end
  else
  begin
    Result := Self.RegOpenKeyExAndLog(cs_ProcName,
        GetBaseKey(Relative), PChar(S), 0,
        STANDARD_RIGHTS_READ or KEY_QUERY_VALUE or KEY_ENUMERATE_SUB_KEYS or WOWFlags,
        TempKey, Key);
    if Result then
    begin
      FAccess := STANDARD_RIGHTS_READ or KEY_QUERY_VALUE or KEY_ENUMERATE_SUB_KEYS or WOWFlags;
      if (CurrentKey <> 0) and Relative then S := CurrentPath + '\' + S;
      ChangeKey(TempKey, S);
    end
    else
    begin
      Result := Self.RegOpenKeyExAndLog(cs_ProcName,
          GetBaseKey(Relative), PChar(S), 0,
          KEY_QUERY_VALUE or WOWFlags, TempKey, Key);
      if Result then
      begin
        FAccess := KEY_QUERY_VALUE or WOWFlags;
        if (CurrentKey <> 0) and Relative then S := CurrentPath + '\' + S;
        ChangeKey(TempKey, S);
      end
    end;
  end;
end;

function TRegistry.DeleteKey(const Key: string): Boolean;
const cs_ProcName = 'TRegistry.DeleteKey';
var
  Len: DWORD;
  I: DWord;
  Relative: Boolean;
  S, KeyName: string;
  OldKey, DeleteKey: HKEY;
  Info: TRegKeyInfo;
  ccResult: Integer;
begin
  S := Key;
  Relative := IsRelative(S);
  if not Relative then Delete(S, 1, 1);
  OldKey := CurrentKey;
  DeleteKey := GetKey(Key);
  if DeleteKey <> 0 then
  try
    SetCurrentKey(DeleteKey);
    if GetKeyInfo(Info) then
    begin
      SetString(KeyName, nil, Info.MaxSubKeyLen + 1);
      for I := Info.NumSubKeys - 1 downto 0 do
      begin
        Len := Info.MaxSubKeyLen + 1;
        ccResult:= RegEnumKeyEx(DeleteKey, DWORD(I), PChar(KeyName), Len, nil, nil, nil,
          nil);
        if ccResult = ERROR_SUCCESS then
          Self.DeleteKey(KeyName) //Self.DeleteKey(PChar(KeyName));
        else Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
               cs_CantEnumSubkeyOf+c_Space+c_Quotes+Key+c_Quotes+
               c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
               False);
      end;
    end;
  finally
    SetCurrentKey(OldKey);
    ccResult:= RegCloseKey(DeleteKey);
    if ccResult <> ERROR_SUCCESS then
      Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantCloseKeyOf+c_Space+c_Quotes+Key+c_Quotes+//+c_Space+SysUtils.IntToStr(DeleteKey)+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);
  end;
  ccResult:= RegDeleteKey(GetBaseKey(Relative), PChar(S));
  if ccResult = ERROR_SUCCESS then
    Result := True
  Else
  Begin
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantDeleteKeyOf+c_Space+c_Quotes+Key+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);
    Result := False;
  End;
end;

function TRegistry.DeleteValue(const Name: string): Boolean;
const cs_ProcName = 'TRegistry.DeleteValue';
Var   ccResult: Integer;
begin
  ccResult:= RegDeleteValue(CurrentKey, PChar(Name));
  if ccResult = ERROR_SUCCESS then Result:= True
  Else
  Begin
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantDeleteValueOf+c_Space+c_Quotes+Name+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);
    Result:= False;
  End;
end;

function TRegistry.GetKeyInfo(var Value: TRegKeyInfo): Boolean;
const cs_ProcName = 'TRegistry.GetKeyInfo';
Var   ccResult: Integer;
begin
  FillChar(Value, SizeOf(TRegKeyInfo), 0);
  ccResult:= RegQueryInfoKey(CurrentKey, nil, nil, nil, @Value.NumSubKeys,
    @Value.MaxSubKeyLen, nil, @Value.NumValues, @Value.MaxValueLen,
    @Value.MaxDataLen, nil, @Value.FileTime);
  if ccResult = ERROR_SUCCESS then Result:= True
  Else
  Begin
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantQueryInfoAboutKeyOf+c_Space+c_Quotes+CurrentPath+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);
    Result:= False;
  End;
  if SysLocale.FarEast and (Win32Platform = VER_PLATFORM_WIN32_NT) then
    with Value do
    begin
      Inc(MaxSubKeyLen, MaxSubKeyLen);
      Inc(MaxValueLen, MaxValueLen);
    end;
end;

procedure TRegistry.GetKeyNames(Strings: TStrings);
const cs_ProcName = 'TRegistry.GetKeyNames';
var
  Len: DWORD;
  I: DWord;
  Info: TRegKeyInfo;
  S: string;
  ccResult: Integer;
begin
  Strings.Clear;
  if GetKeyInfo(Info) then
  begin
    SetString(S, nil, Info.MaxSubKeyLen + 1);
    for I := 0 to Info.NumSubKeys - 1 do
    begin
      Len := Info.MaxSubKeyLen + 1;
      ccResult:= RegEnumKeyEx(CurrentKey, I, PChar(S), Len, nil, nil, nil, nil);
      if ccResult <> ERROR_SUCCESS then
        Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
               cs_CantEnumSubkeyOf+c_Space+c_Quotes+Self.CurrentPath+c_Quotes+
               c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
               False);

      Strings.Add(PChar(S));
    end;
  end;
end;

procedure TRegistry.GetValueNames(Strings: TStrings);
Const cs_ProcName = 'TRegistry.GetValueNames';
var
  Len: DWORD;
  I: DWord;
  Info: TRegKeyInfo;
  S: string;
  ccResult: Integer;
begin
  Strings.Clear;
  if GetKeyInfo(Info) then
  begin
    SetString(S, nil, Info.MaxValueLen + 1);
    for I := 0 to Info.NumValues - 1 do
    begin
      Len := Info.MaxValueLen + 1;
      ccResult:= RegEnumValue(CurrentKey, I, PChar(S), Len, nil, nil, nil, nil);
      if ccResult <> ERROR_SUCCESS then
        Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantQueryInfoAboutValueOf+c_Space+c_Quotes+Self.CurrentPath+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);

      Strings.Add(PChar(S));
    end;
  end;
end;

function TRegistry.GetDataInfoOldFunc(const ValueName: string; var Value: TRegDataInfo): Boolean;
Const cs_ProcName = 'TRegistry.GetDataInfoOldFunc';
var
  DataType: DWord;
  ccResult: Integer;
begin
  FillChar(Value, SizeOf(TRegDataInfo), 0);
  ccResult:= RegQueryValueEx(CurrentKey, PChar(ValueName), nil, @DataType, nil,
    @Value.DataSize);
  if ccResult = ERROR_SUCCESS then Result:= True
  Else
  Begin
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantQueryInfoAboutValueOf+c_Space+c_Quotes+ValueName+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);
    Result:= False;
  End;

  Value.RegData := DataTypeToRegData(DataType);
end;

function TRegistry.GetDataInfo(const ValueName: string; var Value: TRegDataInfo): Boolean;
Const cs_ProcName = 'TRegistry.GetDataInfo';
//var
  //DataType: DWord;
  //ccResult: Integer;
begin
  {2015.07.27: на Windows 8.1 for single language каже
27.07.2015 9:11:23 System Error.  Code: 87.
TRegistry.GetDataInfo: не вдалося отримати інформацію про значення "TextNotifier" . Система каже: Параметр задан неверно
чому так не виявив ще... спробую використовувати завжди стару функцію.
  if System.Assigned(Self.cpRegGetValue) then
  Begin
    FillChar(Value, SizeOf(TRegDataInfo), 0);

    ccResult:= Self.cpRegGetValue(Self.CurrentKey, Nil, PChar(ValueName),
      0, //може варто RRF_NOEXPAND?..
      Addr(DataType), Nil, Addr(Value.DataSize));

    if ccResult = ERROR_SUCCESS then Result:= True
    Else
    Begin
      Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantQueryInfoAboutValueOf+c_Space+c_Quotes+ValueName+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
          False);
      Result:= False;
    End;

    Value.RegData := DataTypeToRegData(DataType);

    // TRegGetValue = function(hkey:HKEY; lpSubKey:LPCTSTR;
    //   lpValue:LPCTSTR; dwFlags:DWORD; Var pdwType: DWORD;
    //   pvData: PByte; Var pcbData: DWORD): LongInt; stdcall;
  End
  Else} Result:= Self.GetDataInfoOldFunc(ValueName, Value);
end;

function TRegistry.GetDataSize(const ValueName: string): DWord;
var
  Info: TRegDataInfo;
begin
  if GetDataInfo(ValueName, Info) then
    Result := Info.DataSize else
    Result := 0;//-1;
end;

function TRegistry.GetDataType(const ValueName: string): TRegDataType;
var
  Info: TRegDataInfo;
begin
  if GetDataInfo(ValueName, Info) then
    Result := Info.RegData else
    Result := rdUnknown;
end;

procedure TRegistry.WriteStringWithAutoStringType(const Name, Value: string);
Var ccLineBreakPos:Integer;
    ccToReplaceLineBreaksWithZeroes, ccIsExpandStr:Boolean;
    ccExpandedStr:String;
Begin
  ccToReplaceLineBreaksWithZeroes:= False;
  ccIsExpandStr:= False;
  ccLineBreakPos:= System.Pos(cs_LineBreak, Value);
  if ccLineBreakPos = 0 then
    ccLineBreakPos:= System.Pos(Chr(0), Value)
  else ccToReplaceLineBreaksWithZeroes:= True;

  if (ccLineBreakPos <> 0) and (ccLineBreakPos <> System.Length(Value)) then
    Self.WriteMultiString(Name, Value, ccToReplaceLineBreaksWithZeroes)
  else
  Begin
    ccExpandedStr:= Value;
    if Self.ExpandEnvironmentVarsInString(ccExpandedStr) then
    Begin
      if ccExpandedStr <> Value then
      Begin
        ccIsExpandStr:= True;
      End;
    End;
    if ccIsExpandStr then
      Self.WriteExpandString(Name, Value)
    Else Self.WriteString(Name, Value);
  End;
End;

procedure TRegistry.WriteString(const Name, Value: string);
begin
  PutData(Name, PChar(Value), (Length(Value)+1) * SizeOf(Char), rdString);
end;

procedure TRegistry.WriteExpandString(const Name, Value: string);
begin
  PutData(Name, PChar(Value), (Length(Value)+1) * SizeOf(Char), rdExpandString);
end;

procedure TRegistry.WriteMultiString(const Name, Value: string;
      sReplaceLineBreaksWithZeroes:Boolean = True);
Var ccWorkString:String;
    ccTwoZeroesLen, ccStrLen: Integer;
Begin
  ccWorkString:= Value;
  if sReplaceLineBreaksWithZeroes then
  Begin
      // Заміняємо у рядку усі переводи рядка на символи-нулі:
    ccWorkString:= DataHelper.StringReplace(ccWorkString, cs_LineBreak, Chr(0));
  End;

  ccStrLen:= System.Length(ccWorkString);
  ccTwoZeroesLen:= System.Length(cs_TwoZeroes);
     //Про RegSetValueEx писали, що рядок REG_MULTI_SZ має містити вкінці два нулі:
     //https://msdn.microsoft.com/ru-ru/library/windows/desktop/ms724923%28v=vs.85%29.aspx
     //тому додаємо вкінці рядка два нулі, якщо їх там немає:
  if System.Copy(ccWorkString, ccStrLen - ccTwoZeroesLen + 1,
               ccTwoZeroesLen) <> cs_TwoZeroes then
  Begin
    ccWorkString:= ccWorkString + cs_TwoZeroes;
  End;

  PutData(Name, Addr(ccWorkString[1]), (Length(Value)+1) * SizeOf(Char),
    rdMultiString);
End;

Function TRegistry.ExpandEnvironmentVarsInString(Var sdString:String):Boolean;
const ci_SuggesedLenAddition = 128;
      cs_ProcName = 'TRegistry.ExpandEnvironmentVarsInString';
Var ccNewLength, ccOldLength:Integer; ccFailed: Boolean;
    ccExpandedString:String;
Begin
  ccNewLength:= System.Length(sdString) + ci_SuggesedLenAddition;
  ccFailed:= False;
  repeat
    System.SetLength(ccExpandedString, ccNewLength);
    ccOldLength:= ccNewLength;
    ccNewLength:= Windows.ExpandEnvironmentStrings(PChar(sdString),
      PChar(ccExpandedString), ccNewLength // + 1
        ) - 1; // функція включає і нульовий символ кінця рядка

    if ccNewLength = 0 then
    Begin
      Self.LogLastOSError(cs_ProcName + c_DoubleDot + c_Space +
        cs_ExpandEnvironmentStringsFailed + c_DoubleDot + c_Space+c_Quotes+
         sdString+c_Quotes+ c_Dot+c_Space+c_SystemSays+c_Space);
      ccFailed:= True;
      Break;
    End;
//function ExpandEnvironmentStrings(lpSrc: PWideChar; lpDst: PWideChar; nSize: DWORD): DWORD; stdcall;
  until ccNewLength <= ccOldLength;

//  if ccFailed then
//    ccExpandedString:= sdString
//  else
  Result:= Not(ccFailed);
     // Скорочуємо довжину рядка до тої яку передала функція:
  if Result then
  Begin
    System.SetLength(ccExpandedString, ccNewLength);
    sdString:= ccExpandedString;
  End;
End;

function TRegistry.ReadString(const Name: string;
  sExpandRegExpandEnvironmentVarsInStrings: Boolean = False): string;
const cs_ProcName = 'TRegistry.ReadString';
var
  Len: DWord; // розмір отриманих даних У БАЙТАХ, не в символах
  ccStrLen, ccPCharLen:Integer;
  RegData: TRegDataType;
  ccBuffer: Pointer;
  ccTwoZeroesLen:Integer;
  //ccMoreDataNeeded: Boolean;
begin
  Self.AllocateAndGetDataEx(Name, ccBuffer,
      Len, RegData);
  //Len := GetDataSize(Name);
  //ccOldLen:= Len;
  try
    if Len > 0 then
    begin
      //GetData(Name, PChar(Result), Len, RegData);
      if (RegData = rdString) or (RegData = rdExpandString)
           or (RegData = rdMultiString) then
      Begin
        //   Відповідно до:
        // https://msdn.microsoft.com/ru-ru/library/windows/desktop/ms724911%28v=vs.85%29.aspx
        // https://msdn.microsoft.com/ru-ru/library/windows/desktop/ms724868%28v=vs.85%29.aspx
        //   Рядок може містити декілька нулів коли він багаторядковий
        // (rdMultiString), або не містити нуля взагалі коли читається
        // функцією RegQueryValueEx. Тому спочатку встановлюємо ту довжину що
        // повернула сама процедура читання. Вона може включати і нульовий
        // символ вкінці:
        //SetLength(Result, StrLen(PChar(Result)))

        ccStrLen:= Len div SizeOf(Char);
        if (Len Mod SizeOf(Char)) > 0 then Inc(ccStrLen);

        if RegData = rdMultiString then
        Begin
            // Копіюємо отримані дані в рядок:
          System.SetLength(Result, ccStrLen);
          System.Move(ccBuffer^, Result[1], Len);
            // Зразу звільняємо буфер, перед операціями із рядком:
          System.FreeMem(ccBuffer); ccBuffer:= Nil;

            // Відкидаємо два нулі вкінці рядка, якщо вони там є:
          ccTwoZeroesLen:= System.Length(cs_TwoZeroes);

          if System.Copy(Result, ccStrLen - ccTwoZeroesLen + 1,
               ccTwoZeroesLen) = cs_TwoZeroes then
            System.SetLength(Result, ccStrLen - ccTwoZeroesLen);

            // Заміняємо у рядку усі символи-нулі на переводи рядка:
          Result:= DataHelper.StringReplace(Result, Chr(0), cs_LineBreak);
        End
        else
        Begin
          ccPCharLen:= SysUtils.StrLen(PChar(ccBuffer));
            // Якщо нулів у рядку немає взагалі то беремо рядок до кінця буфера:
          if ccPCharLen > ccStrLen then ccPCharLen:= ccStrLen;

            // Копіюємо отримані дані в рядок:
          System.SetLength(Result, ccPCharLen);

          //Self.cLogFile.WriteMessage(cs_ProcName+': у буфер прочитано "'+String(PChar(ccBuffer))+'"');

          //Result:= SysUtils.StrPas(PChar(ccBuffer));

          System.Move(ccBuffer^, Result[1], ccPCharLen * SizeOf(Char));

          //Self.cLogFile.WriteMessage(cs_ProcName+': із буфера зкопійовано "'+Result+'"');
            // Зразу звільняємо буфер, перед операціями із рядком:
          System.FreeMem(ccBuffer); ccBuffer:= Nil;

          if sExpandRegExpandEnvironmentVarsInStrings and (RegData = rdExpandString) then
          Begin
            Self.ExpandEnvironmentVarsInString(Result);
          End;
        End;
      End
      else ReadError(Name);
    end
    else Result := '';
  finally
    if System.Assigned(ccBuffer) then
    Begin
      System.FreeMem(ccBuffer); ccBuffer:= Nil;
    End;
  end;
end;

// Returns rdInteger and rdBinary as strings
function TRegistry.GetDataAsString(const ValueName: string;
  PrefixType: Boolean = false): string;
const
  SDWORD_PREFIX = 'dword:';
  SHEX_PREFIX = 'hex:';
var
  Info: TRegDataInfo;
  BinaryBuffer: array of Byte;
begin
  Result := '';
  if GetDataInfo(ValueName, Info) and (Info.DataSize > 0) then
  begin
    case Info.RegData of
      rdString, rdExpandString:
        begin
          SetString(Result, nil, Info.DataSize);
          GetData(ValueName, PChar(Result), Info.DataSize, Info.RegData);
          SetLength(Result, StrLen(PChar(Result)));
        end;
      rdInteger:
        begin
          if PrefixType then
            Result := SDWORD_PREFIX+IntToHex(ReadInteger(ValueName), 8)
          else
            Result := IntToStr(ReadInteger(ValueName));
        end;
      rdBinary, rdUnknown:
        begin
          SetLength(BinaryBuffer, Info.DataSize);
          ReadBinaryData(ValueName, Pointer(BinaryBuffer)^, Info.DataSize);
          if PrefixType then
            Result := BinaryToHexString(BinaryBuffer, SHEX_PREFIX)
          else
            Result := BinaryToHexString(BinaryBuffer, '');
        end;
    end;
  end;
end;

procedure TRegistry.WriteInteger(const Name: string; Value: Integer);
begin
  PutData(Name, @Value, SizeOf(Integer), rdInteger);
end;

function TRegistry.ReadInteger(const Name: string): Integer;
var
  RegData: TRegDataType;
begin
  GetData(Name, @Result, SizeOf(Integer), RegData);
  if RegData <> rdInteger then ReadError(Name);
end;

procedure TRegistry.WriteBool(const Name: string; Value: Boolean);
begin
  WriteInteger(Name, Ord(Value));
end;

function TRegistry.ReadBool(const Name: string): Boolean;
begin
  Result := ReadInteger(Name) <> 0;
end;

procedure TRegistry.WriteFloat(const Name: string; Value: Double);
begin
  PutData(Name, @Value, SizeOf(Double), rdBinary);
end;

function TRegistry.ReadFloat(const Name: string): Double;
var
  Len: DWord;
  RegData: TRegDataType;
begin
  Len := GetData(Name, @Result, SizeOf(Double), RegData);
  if (RegData <> rdBinary) or (Len <> SizeOf(Double)) then
    ReadError(Name);
end;

procedure TRegistry.WriteCurrency(const Name: string; Value: Currency);
begin
  PutData(Name, @Value, SizeOf(Currency), rdBinary);
end;

function TRegistry.ReadCurrency(const Name: string): Currency;
var
  Len: DWord;
  RegData: TRegDataType;
begin
  Len := GetData(Name, @Result, SizeOf(Currency), RegData);
  if (RegData <> rdBinary) or (Len <> SizeOf(Currency)) then
    ReadError(Name);
end;

procedure TRegistry.WriteDateTime(const Name: string; Value: TDateTime);
begin
  PutData(Name, @Value, SizeOf(TDateTime), rdBinary);
end;

function TRegistry.ReadDateTime(const Name: string): TDateTime;
var
  Len: DWord;
  RegData: TRegDataType;
begin
  Len := GetData(Name, @Result, SizeOf(TDateTime), RegData);
  if (RegData <> rdBinary) or (Len <> SizeOf(TDateTime)) then
    ReadError(Name);
end;

procedure TRegistry.WriteDate(const Name: string; Value: TDateTime);
begin
  WriteDateTime(Name, Value);
end;

function TRegistry.ReadDate(const Name: string): TDateTime;
begin
  Result := ReadDateTime(Name);
end;

procedure TRegistry.WriteTime(const Name: string; Value: TDateTime);
begin
  WriteDateTime(Name, Value);
end;

function TRegistry.ReadTime(const Name: string): TDateTime;
begin
  Result := ReadDateTime(Name);
end;

procedure TRegistry.WriteBinaryData(const Name: string; var Buffer; BufSize: DWord);
begin
  PutData(Name, @Buffer, BufSize, rdBinary);
end;

function TRegistry.ReadBinaryData(const Name: string; var Buffer; BufSize: DWord): DWord;
var
  RegData: TRegDataType;
  Info: TRegDataInfo;
begin
  if GetDataInfo(Name, Info) then
  begin
    Result := Info.DataSize;
    RegData := Info.RegData;
    if ((RegData = rdBinary) or (RegData = rdUnknown)) and (Result <= BufSize) then
      GetData(Name, @Buffer, Result, RegData)
    else ReadError(Name);
  end else
    Result := 0;
end;

Procedure TRegistry.ReadBinaryDataEx(const Name: string; var Buffer:Pointer;
      Var dBufSize: DWord);
var
  RegData: TRegDataType;
Begin
  Self.AllocateAndGetDataEx(Name, Buffer, dBufSize, RegData);
  if Not((RegData = rdBinary) or (RegData = rdUnknown)) then
  Begin
    if System.Assigned(Buffer) then
    Begin
      System.FreeMem(Buffer);
      Buffer:= Nil;
      dBufSize:= 0;
    End;
    ReadError(Name);
  End;
End;

procedure TRegistry.PutData(const Name: string; Buffer: Pointer;
  BufSize: DWord; RegData: TRegDataType);
var
  DataType: DWord;
  ccResult:Integer;
begin
  DataType := RegDataToDataType(RegData);

  ccResult:= RegSetValueEx(CurrentKey, PChar(Name), 0, DataType, Buffer,
    BufSize);

  if ccResult <> ERROR_SUCCESS then
    Self.LogExceptionAddOsError(
      ERegistryException.CreateResFmt(@SRegSetDataFailed, [Name]),
        ccResult, True, True);
end;

function TRegistry.GetDataOldFunc(const Name: string; Buffer: Pointer;
      BufSize: DWord; var RegData: TRegDataType;
      Var dMoreDataNeeded:Boolean): DWord;
var
  DataType: DWord;
  ccResult:LongInt;
begin
  DataType := REG_NONE;
  dMoreDataNeeded:= False;
  ccResult:= RegQueryValueEx(CurrentKey, PChar(Name), nil, @DataType, Buffer,
    @BufSize);
  if ccResult = ERROR_MORE_DATA then
    dMoreDataNeeded:= True
  else if ccResult <> ERROR_SUCCESS then
    Self.LogExceptionAddOsError(
      ERegistryException.CreateResFmt(@SRegGetDataFailed, [Name]),
        ccResult, True, True);
  Result := BufSize;
  RegData := DataTypeToRegData(DataType);
end;

function TRegistry.GetData(const Name: string; Buffer: Pointer;
  BufSize: DWord; var RegData: TRegDataType): DWord;
var
  //DataType: DWord;
  //ccResult:LongInt;
  ccMoreDataNeeded:Boolean;
begin
  Result:= GetDataOldFunc(Name, Buffer,
      BufSize, RegData,
      ccMoreDataNeeded);
  if ccMoreDataNeeded then
    Self.LogExceptionAddOsError(
      ERegistryException.CreateResFmt(@SRegGetDataFailed, [Name]),
        ERROR_MORE_DATA, True, True);
end;

function TRegistry.GetDataEx(const Name: string; Buffer: Pointer;
      BufSize: DWord; var RegData: TRegDataType;
      Var dMoreDataNeeded:Boolean): DWord;
//var
  //DataType: DWord;
  //ccResult:LongInt;
Begin
  dMoreDataNeeded:= False;
  {  // Якщо вдалося знайти процедуру RegGetValue то використовуємо її,
    // а якщо її ОС не підтримує то використовуємо RegQueryValueEx:
  if System.Assigned(Self.cpRegGetValue) then
  Begin
    DataType := REG_NONE;

    ccResult:= Self.cpRegGetValue(Self.CurrentKey, Nil,  // підключ не вказуємо
      PChar(Name), 0, //може варто RRF_NOEXPAND?..
      Addr(DataType), Buffer, Addr(BufSize));

    if ccResult = ERROR_MORE_DATA then
      dMoreDataNeeded:= True
    else if ccResult <> ERROR_SUCCESS then
      Self.LogExceptionAddOsError(
        ERegistryException.CreateResFmt(@SRegGetDataFailed, [Name]),
          ccResult, True, True);
    Result:= BufSize;
    RegData := DataTypeToRegData(DataType);

    //if ccResult = ERROR_MORE_DATA then
    //Begin

    //End;

   // function(hkey:HKEY; lpSubKey:LPCTSTR;
   // lpValue:LPCTSTR; dwFlags:DWORD; Var pdwType: DWORD;
   // pvData: PByte; Var pcbData: DWORD): LongInt; stdcall;

  End
  Else} Result:= Self.GetDataOldFunc(Name, Buffer, BufSize, RegData,
    dMoreDataNeeded);
End;

Procedure TRegistry.AllocateAndGetDataEx(const Name: string;
      Var dBuffer: Pointer;
      Var dBufSize: DWord; var RegData: TRegDataType);
Var ccOldSize:DWord;
    ccMoreDataNeeded: Boolean;
    ccIncrementNum: Cardinal;
    ccDataInfo: TRegDataInfo;
Begin
  dBuffer:= Nil;

  if Self.GetDataInfo(Name, ccDataInfo) then
  Begin
    dBufSize:= ccDataInfo.DataSize;
    RegData:= ccDataInfo.RegData;
  End
  Else
  Begin
    dBufSize:= 0;//-1;
    RegData:= rdUnknown;
  End;
  //dBufSize:= Self.GetDataSize(Name);

  if dBufSize > 0 then
  Begin
    ccOldSize:= dBufSize;

    ccIncrementNum:= 0;
    repeat
      Inc(ccIncrementNum);
          // Якщо dBufSize останнього разу повернуто не адекватне
          // (у
          // https://msdn.microsoft.com/ru-ru/library/windows/desktop/ms724911%28v=vs.85%29.aspx
          // https://msdn.microsoft.com/ru-ru/library/windows/desktop/ms724868%28v=vs.85%29.aspx
          // кажуть що це може бути для HKEY_PERFORMANCE_DATA)
          // то збільшуємо на константу і пробуємо ще раз:
      if ccOldSize > dBufSize then dBufSize:= ccOldSize + ci_RegBufLenIncrement;
         // Звільняємо старий буфер (якщо він був і мав недостатню довжину):
      if System.Assigned(dBuffer) then
      Begin
        System.FreeMem(dBuffer);
        dBuffer:= Nil;
      End;
         //   Виділяємо новий буфер. Використовується AllocMem щоб
         // заповнити буфер нулями.. бо при отриманні даних частина буфера
         // може лишитися не писаною...:
      dBuffer:= System.AllocMem(dBufSize);
      //System.GetMem(dBuffer, dBufSize);
      //SetString(Result, nil, Len div SizeOf(Char));
      try
        dBufSize:= Self.GetDataEx(Name, dBuffer, dBufSize, RegData,
          ccMoreDataNeeded);
      except
        on E:Exception do
        Begin
          System.FreeMem(dBuffer);
          dBufSize:= 0;
          raise E;
        End;
      end;
    until (Not(ccMoreDataNeeded)) or (ccIncrementNum >= ci_MaxRegBufLenIncrements);

    if ccMoreDataNeeded then
    Begin
      System.FreeMem(dBuffer);
      dBufSize:= 0;

      Self.LogExceptionAddOsError(
          ERegistryException.CreateResFmt(@SRegGetDataFailed, [Name]),
            ERROR_MORE_DATA, True, True);
    End;
  End;
End;

function TRegistry.HasSubKeys: Boolean;
var
  Info: TRegKeyInfo;
begin
  Result := GetKeyInfo(Info) and (Info.NumSubKeys > 0);
end;

function TRegistry.ValueExists(const Name: string): Boolean;
var
  Info: TRegDataInfo;
begin
  Result := GetDataInfo(Name, Info);
end;

function TRegistry.GetKey(const Key: string): HKEY;
Const cs_ProcName = 'TRegistry.GetKey';
var
  S: string;
  Relative: Boolean;
  ccResult: Integer;
  ccKey:HKey;
begin
  S := Key;
  Relative := IsRelative(S);
  if not Relative then Delete(S, 1, 1);
  Result := 0;
  ccKey:= GetBaseKey(Relative);
  ccResult:= RegOpenKeyEx(ccKey, PChar(S), 0, FAccess, Result);
  if ccResult<>ERROR_SUCCESS then
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantOpenKeyOf+c_Space+c_Quotes+Key+c_Quotes+//+c_Space+SysUtils.IntToStr(ccKey)+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
end;

function TRegistry.RegistryConnect(const UNCName: string): Boolean;
const cs_ProcName = 'TRegistry.RegistryConnect';
var
  TempKey: HKEY;
  ccResult: Integer;
begin
  ccResult:= RegConnectRegistry(PChar(UNCname), RootKey, TempKey);
  Result := ccResult = ERROR_SUCCESS;
  if Result then
  begin
    RootKey := TempKey;
    FCloseRootKey := True;
  end
  Else
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantConnectRegistryOf+c_Space+c_Quotes+UNCName+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
end;

function TRegistry.LoadKey(const Key, FileName: string): Boolean;
const cs_ProcName = 'TRegistry.LoadKey';
var
  S: string;
  ccResult: Integer;
begin
  S := Key;
  if not IsRelative(S) then Delete(S, 1, 1);
  ccResult:= RegLoadKey(RootKey, PChar(S), PChar(FileName));
  if ccResult = ERROR_SUCCESS then Result := True
  Else
  Begin
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantLoadKeyOf+c_Space+c_Quotes+Key+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
    Result := False;
  End;
end;

function TRegistry.UnLoadKey(const Key: string): Boolean;
const cs_ProcName = 'TRegistry.UnLoadKey';
var
  S: string;
  ccResult: Integer;
begin
  S := Key;
  if not IsRelative(S) then Delete(S, 1, 1);
  ccResult:= RegUnLoadKey(RootKey, PChar(S));
  if ccResult = ERROR_SUCCESS then Result := True
  Else
  Begin
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantUnloadKeyOf+c_Space+c_Quotes+Key+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
    Result := False;
  End;
end;

function TRegistry.RestoreKey(const Key, FileName: string): Boolean;
const cs_ProcName = 'TRegistry.RestoreKey';
var
  RestoreKey: HKEY;
  ccResult: Integer;
begin
  Result := False;
  RestoreKey := GetKey(Key);
  if RestoreKey <> 0 then
  try
    ccResult:= RegRestoreKey(RestoreKey, PChar(FileName), 0);
    Result := ccResult = ERROR_SUCCESS;
    if Not(Result) then
    Begin
      Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantRestoreKeyOf+c_Space+c_Quotes+Key+c_Quotes+
          c_Space+cs_FromFile+c_Space+FileName+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
    End;
  finally
    Self.RegCloseKeyAndLog(cs_ProcName, RestoreKey, Key);
  end;
end;

function TRegistry.ReplaceKey(const Key, FileName, BackUpFileName: string): Boolean;
const cs_ProcName = 'TRegistry.ReplaceKey';
var
  S: string;
  Relative: Boolean;
  ccResult: Integer;
begin
  S := Key;
  Relative := IsRelative(S);
  if not Relative then Delete(S, 1, 1);
  ccResult:= RegReplaceKey(GetBaseKey(Relative), PChar(S),
    PChar(FileName), PChar(BackUpFileName));
  Result := ccResult = ERROR_SUCCESS;
  if Not(Result) then
  Begin
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantReplaceKeyOf+c_Space+c_Quotes+Key+c_Quotes+
          c_Space+cs_To+c_Space+FileName+c_Space+cs_WithBackupIn+
            c_Space+BackUpFileName+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
  End;
end;

function TRegistry.SaveKey(const Key, FileName: string): Boolean;
const cs_ProcName = 'TRegistry.SaveKey';
var
  SaveKey: HKEY;
  ccResult: Integer;
begin
  Result := False;
  SaveKey := GetKey(Key);
  if SaveKey <> 0 then
  try
    ccResult:= RegSaveKey(SaveKey, PChar(FileName), nil);
    Result := ccResult = ERROR_SUCCESS;
    if Not(Result) then
    Begin
      Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantSaveKeyOf+c_Space+c_Quotes+Key+c_Quotes+
          c_Space+cs_ToFile+c_Space+FileName+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
    End;
  finally
    RegCloseKey(SaveKey);
  end;
end;

function TRegistry.KeyExists(const Key: string): Boolean;
const cs_ProcName = 'TRegistry.KeyExists';
var
  TempKey: HKEY;
  OldAccess: Longword;
  ccResult:Integer;
begin
  OldAccess := FAccess;
  try
    FAccess := STANDARD_RIGHTS_READ or KEY_QUERY_VALUE or
      KEY_ENUMERATE_SUB_KEYS or (OldAccess and KEY_WOW64_RES);
    TempKey := GetKey(Key);
    if TempKey <> 0 then
    Begin
      ccResult:= RegCloseKey(TempKey);
      if ccResult<>ERROR_SUCCESS then
        Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantCloseKeyOf+c_Space+c_Quotes+Key+c_Quotes+
          c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
    End;
    Result := TempKey <> 0;
  finally
    FAccess := OldAccess;
  end;
end;

procedure TRegistry.RenameValue(const OldName, NewName: string);
var
  Len: DWord;
  RegData: TRegDataType;
  Buffer: Pointer;
begin
  if {ValueExists(OldName) and} not ValueExists(NewName) then
  begin
    //Len := GetDataSize(OldName); // returns 0 if OldName doesn't exist
    Self.AllocateAndGetDataEx(OldName, Buffer, Len, RegData);
    try
      if Len > 0 then
      begin
        //Buffer := AllocMem(Len);
        //Len := GetData(OldName, Buffer, Len, RegData);
        DeleteValue(OldName);
        PutData(NewName, Buffer, Len, RegData);
      end;
    finally
      FreeMem(Buffer);
    end;
  end;
end;

procedure TRegistry.MoveKey(const OldName, NewName: string; Delete: Boolean);
const cs_ProcName = 'TRegistry.MoveKey';
var
  SrcKey, DestKey: HKEY;
  ccResult: Integer;

  procedure MoveValue(SrcKey, DestKey: HKEY; const Name: string);
  var
    Len: DWord;
    OldKey, PrevKey: HKEY;
    Buffer: Pointer; //PChar;
    RegData: TRegDataType;
  begin
    OldKey := CurrentKey;
    SetCurrentKey(SrcKey);
    try
      Self.AllocateAndGetDataEx(Name, Buffer, Len, RegData);
      //Len := GetDataSize(Name);
      if Len > 0 then
      begin
        //Buffer := AllocMem(Len);
        try
          //Len := GetData(Name, Buffer, Len, RegData);
          PrevKey := CurrentKey;
          SetCurrentKey(DestKey);
          try
            PutData(Name, Buffer, Len, RegData);
          finally
            SetCurrentKey(PrevKey);
          end;
        finally
          FreeMem(Buffer);
        end;
      end;
    finally
      SetCurrentKey(OldKey);
    end;
  end;

  procedure CopyValues(SrcKey, DestKey: HKEY);
  const cs_ProcName = 'CopyValues';
  var
    Len: DWORD;
    I: DWord;
    KeyInfo: TRegKeyInfo;
    S: string;
    OldKey: HKEY;
    ccResult: Integer;
  begin
    OldKey := CurrentKey;
    SetCurrentKey(SrcKey);
    try
      if GetKeyInfo(KeyInfo) then
      begin
        MoveValue(SrcKey, DestKey, '');
        SetString(S, nil, KeyInfo.MaxValueLen + 1);
        for I := 0 to KeyInfo.NumValues - 1 do
        begin
          Len := KeyInfo.MaxValueLen + 1;
          ccResult:= RegEnumValue(SrcKey, I, PChar(S), Len, nil, nil, nil, nil);
          if ccResult = ERROR_SUCCESS then
            MoveValue(SrcKey, DestKey, PChar(S))
          Else
            Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
              cs_CantQueryInfoAboutValueOf+c_Space+SysUtils.IntToStr(SrcKey)+//c_Quotes+Self.CurrentPath+c_Quotes+
              c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
              False);
        end;
      end;
    finally
      SetCurrentKey(OldKey);
    end;
  end;

  procedure CopyKeys(SrcKey, DestKey: HKEY);
  const cs_ProcName = 'CopyKeys';
  var
    Len: DWORD;
    I: DWord;
    Info: TRegKeyInfo;
    S: string;
    OldKey, PrevKey, NewSrc, NewDest: HKEY;
    ccResult: Integer;
  begin
    OldKey := CurrentKey;
    SetCurrentKey(SrcKey);
    try
      if GetKeyInfo(Info) then
      begin
        SetString(S, nil, Info.MaxSubKeyLen + 1);
        for I := 0 to Info.NumSubKeys - 1 do
        begin
          Len := Info.MaxSubKeyLen + 1;
          ccResult:= RegEnumKeyEx(SrcKey, I, PChar(S), Len, nil, nil, nil, nil);
          if ccResult = ERROR_SUCCESS then
          begin
            NewSrc := GetKey(PChar(S));
            if NewSrc <> 0 then
            try
              PrevKey := CurrentKey;
              SetCurrentKey(DestKey);
              try
                CreateKey(PChar(S));
                NewDest := GetKey(PChar(S));
                try
                  CopyValues(NewSrc, NewDest);
                  CopyKeys(NewSrc, NewDest);
                finally
                  ccResult:= RegCloseKey(NewDest);
                  if ccResult <> ERROR_SUCCESS then
                    Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
                    cs_CantCloseKeyOf+c_Space+SysUtils.IntToStr(NewDest)+
                    c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
                end;
              finally
                SetCurrentKey(PrevKey);
              end;
            finally
              ccResult:= RegCloseKey(NewSrc);
              if ccResult <> ERROR_SUCCESS then
                  Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
                    cs_CantCloseKeyOf+c_Space+SysUtils.IntToStr(NewSrc)+
                    c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
            end;
          end
          Else Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
                 cs_CantEnumSubkeyOf+c_Space+SysUtils.IntToStr(SrcKey)+//+c_Quotes+Key+c_Quotes+
                 c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult,
                 False);

        end;
      end;
    finally
      SetCurrentKey(OldKey);
    end;
  end;

begin
  if KeyExists(OldName) and not KeyExists(NewName) then
  begin
    SrcKey := GetKey(OldName);
    if SrcKey <> 0 then
    try
      CreateKey(NewName);
      DestKey := GetKey(NewName);
      if DestKey <> 0 then
      try
        CopyValues(SrcKey, DestKey);
        CopyKeys(SrcKey, DestKey);
        if Delete then DeleteKey(OldName);
      finally
        ccResult:= RegCloseKey(DestKey);
        if ccResult <> ERROR_SUCCESS then
          Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
            cs_CantCloseKeyOf+c_Space+c_Quotes+NewName+c_Quotes+
            c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
      end;
    finally
      ccResult:= RegCloseKey(SrcKey);
      if ccResult <> ERROR_SUCCESS then
          Self.LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
            cs_CantCloseKeyOf+c_Space+c_Quotes+OldName+c_Quotes+
            c_Space+c_Dot+c_Space+c_SystemSays+c_Space, ccResult, False);
    end;
  end;
end;

{ TRegIniFile }

constructor TRegIniFile.Create(const FileName: string);
begin
  Create(FileName, KEY_ALL_ACCESS);
end;

constructor TRegIniFile.Create(const FileName: string; AAccess: LongWord);
begin
  inherited Create(AAccess);
  FFilename := FileName;
  OpenKey(FileName, True);
end;

function TRegIniFile.ReadString(const Section, Ident, Default: string): string;
var
  Key, OldKey: HKEY;
begin
  Key := GetKey(Section);
  if Key <> 0 then
  try
    OldKey := CurrentKey;
    SetCurrentKey(Key);
    try
      if (Default = '') or ValueExists(Ident) then
        Result := inherited ReadString(Ident) else
        Result := Default;
    finally
      SetCurrentKey(OldKey);
    end;
  finally
    RegCloseKey(Key);
  end
  else Result := Default;
end;

procedure TRegIniFile.WriteString(const Section, Ident, Value: String);
var
  Key, OldKey: HKEY;
begin
  CreateKey(Section);
  Key := GetKey(Section);
  if Key <> 0 then
  try
    OldKey := CurrentKey;
    SetCurrentKey(Key);
    try
      inherited WriteString(Ident, Value);
    finally
      SetCurrentKey(OldKey);
    end;
  finally
    RegCloseKey(Key);
  end;
end;

function TRegIniFile.ReadInteger(const Section, Ident: string; Default: LongInt): LongInt;
var
  Key, OldKey: HKEY;
  S: string;
begin
  Key := GetKey(Section);
  if Key <> 0 then
  try
    OldKey := CurrentKey;
    SetCurrentKey(Key);
    try
      S := inherited ReadString(Ident);
      Result := StrToIntDef(S, Default);
    finally
      SetCurrentKey(OldKey);
    end;
  finally
    RegCloseKey(Key);
  end
  else Result := Default;
end;

procedure TRegIniFile.WriteInteger(const Section, Ident: string; Value: LongInt);
var
  Key, OldKey: HKEY;
begin
  CreateKey(Section);
  Key := GetKey(Section);
  if Key <> 0 then
  try
    OldKey := CurrentKey;
    SetCurrentKey(Key);
    try
      inherited WriteString(Ident, IntToStr(Value));
    finally
      SetCurrentKey(OldKey);
    end;
  finally
    RegCloseKey(Key);
  end;
end;

function TRegIniFile.ReadBool(const Section, Ident: string; Default: Boolean): Boolean;
begin
  Result := ReadInteger(Section, Ident, Ord(Default)) <> 0;
end;

procedure TRegIniFile.WriteBool(const Section, Ident: string; Value: Boolean);
const
  Values: array[Boolean] of string = ('0', '1');
var
  Key, OldKey: HKEY;
begin
  CreateKey(Section);
  Key := GetKey(Section);
  if Key <> 0 then
  try
    OldKey := CurrentKey;
    SetCurrentKey(Key);
    try
      inherited WriteString(Ident, Values[Value]);
    finally
      SetCurrentKey(OldKey);
    end;
  finally
    RegCloseKey(Key);
  end;
end;

procedure TRegIniFile.ReadSection(const Section: string; Strings: TStrings);
var
  Key, OldKey: HKEY;
begin
  Key := GetKey(Section);
  if Key <> 0 then
  try
    OldKey := CurrentKey;
    SetCurrentKey(Key);
    try
      inherited GetValueNames(Strings);
    finally
      SetCurrentKey(OldKey);
    end;
  finally
    RegCloseKey(Key);
  end;
end;

procedure TRegIniFile.ReadSections(Strings: TStrings);
begin
  GetKeyNames(Strings);
end;

procedure TRegIniFile.ReadSectionValues(const Section: string; Strings: TStrings);
var
  Key, OldKey: HKEY;
  ValueName: string;
  ValueNames: TStringList;
  I: Integer;
begin
  Key := GetKey(Section);
  if Key <> 0 then
  try
    OldKey := CurrentKey;
    SetCurrentKey(Key);
  try
      ValueNames := TStringList.Create;
    Strings.BeginUpdate;
    try
        inherited GetValueNames(ValueNames);
        for I := 0 to ValueNames.Count - 1 do
        begin
          ValueName := ValueNames[I];
          Strings.Values[ValueName] := GetDataAsString(ValueName, True);
        end;
    finally
      Strings.EndUpdate;
        ValueNames.Free;
    end;
  finally
      SetCurrentKey(OldKey);
  end;
  finally
    RegCloseKey(Key);
  end

end;

procedure TRegIniFile.EraseSection(const Section: string);
begin
  inherited DeleteKey(Section);
end;

procedure TRegIniFile.DeleteKey(const Section, Ident: String);
var
  Key, OldKey: HKEY;
begin
  Key := GetKey(Section);
  if Key <> 0 then
  try
    OldKey := CurrentKey;
    SetCurrentKey(Key);
    try
      inherited DeleteValue(Ident);
    finally
      SetCurrentKey(OldKey);
    end;
  finally
    RegCloseKey(Key);
  end;
end;

{ TRegistryIniFile }

constructor TRegistryIniFile.Create(const FileName: string);
begin
  Create(FileName, KEY_ALL_ACCESS);
end;

constructor TRegistryIniFile.Create(const FileName: string; AAccess: LongWord);
begin
  inherited Create(FileName);
  FRegIniFile := TRegIniFile.Create(FileName, AAccess);
end;

destructor TRegistryIniFile.Destroy;
begin
  FRegIniFile.Free;
  inherited Destroy;
end;

function TRegistryIniFile.ReadString(const Section, Ident, Default: string): string;
begin
  Result := FRegIniFile.ReadString(Section, Ident, Default);
end;

function TRegistryIniFile.ReadDate(const Section, Name: string; Default: TDateTime): TDateTime;
var
  Key, OldKey: HKEY;
begin
  with FRegIniFile do
  begin
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        if ValueExists(Name) then
          Result := ReadDate(Name)
        else Result := Default;
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end else Result := Default;
  end;
end;

function TRegistryIniFile.ReadDateTime(const Section, Name: string; Default: TDateTime): TDateTime;
var
  Key, OldKey: HKEY;
begin
  with FRegIniFile do
  begin
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        if ValueExists(Name) then
          Result := ReadDateTime(Name)
        else Result := Default;
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end else Result := Default;
  end;
end;

function TRegistryIniFile.ReadFloat(const Section, Name: string; Default: Double): Double;
var
  Key, OldKey: HKEY;
begin
  with FRegIniFile do
  begin
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        if ValueExists(Name) then
          Result := ReadFloat(Name)
        else Result := Default;
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end else Result := Default;
  end;
end;

function TRegistryIniFile.ReadInteger(const Section, Ident: string; Default: LongInt): LongInt;
var
  Key, OldKey: HKEY;
  Info: TRegDataInfo;
begin
  with TRegistry(FRegIniFile) do
  begin
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        Result := Default;
        if GetDataInfo(Ident, Info) then
          if Info.RegData = rdString then
            Result := StrToIntDef(ReadString(Ident), Default)
          else Result := ReadInteger(Ident);
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end
    else Result := Default;
  end;
end;

function TRegistryIniFile.ReadTime(const Section, Name: string; Default: TDateTime): TDateTime;
var
  Key, OldKey: HKEY;
begin
  with FRegIniFile do
  begin
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        if ValueExists(Name) then
          Result := ReadTime(Name)
        else Result := Default;
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end else Result := Default;
  end;
end;

function TRegistryIniFile.ReadBinaryStream(const Section, Name: string; Value: TStream): Integer;
var
  RegData: TRegDataType;
  Info: TRegDataInfo;
  Key, OldKey: HKEY;
  Stream: TMemoryStream;
begin
  Result := 0;
  with RegIniFile do
  begin
    Key := TRegistry(FRegIniFile).GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      TRegistry(FRegIniFile).SetCurrentKey(Key);
      try
        if GetDataInfo(Name, Info) then
        begin
          Result := Info.DataSize;
          RegData := Info.RegData;
          if Value is TMemoryStream then
            Stream := TMemoryStream(Value)
          else Stream := TMemoryStream.Create;
          try
            if (RegData = rdBinary) or (RegData = rdUnknown) then
            begin
              Stream.Size := Stream.Position + Info.DataSize;
              Result := ReadBinaryData(Name,
                Pointer(Integer(Stream.Memory) + Stream.Position)^, Stream.Size);
              if Stream <> Value then Value.CopyFrom(Stream, Stream.Size - Stream.Position);
            end;
          finally
            if Stream <> Value then Stream.Free;
	      end;
        end;
      finally
        TRegistry(FRegIniFile).SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end;
  end;
end;

procedure TRegistryIniFile.WriteDate(const Section, Name: string; Value: TDateTime);
var
  Key, OldKey: HKEY;
begin
  with FRegIniFile do
  begin
    CreateKey(Section);
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        WriteDate(Name, Value);
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end;
  end;
end;

procedure TRegistryIniFile.WriteDateTime(const Section, Name: string; Value: TDateTime);
var
  Key, OldKey: HKEY;
begin
  with FRegIniFile do
  begin
    CreateKey(Section);
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        WriteDateTime(Name, Value);
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end;
  end;
end;

procedure TRegistryIniFile.WriteFloat(const Section, Name: string; Value: Double);
var
  Key, OldKey: HKEY;
begin
  with FRegIniFile do
  begin
    CreateKey(Section);
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        WriteFloat(Name, Value);
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end;
  end;
end;

procedure TRegistryIniFile.WriteInteger(const Section, Ident: string; Value: LongInt);
var
  Key, OldKey: HKEY;
  Info: TRegDataInfo;
begin
  with TRegistry(FRegIniFile) do
  begin
    CreateKey(Section);
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        if GetDataInfo(Ident, Info) and (Info.RegData = rdString) then
          WriteString(Ident, IntToStr(Value))
        else WriteInteger(Ident, Value);
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end;
  end;
end;

procedure TRegistryIniFile.WriteTime(const Section, Name: string; Value: TDateTime);
var
  Key, OldKey: HKEY;
begin
  with FRegIniFile do
  begin
    CreateKey(Section);
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        WriteTime(Name, Value);
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end;
  end;
end;

procedure TRegistryIniFile.WriteBinaryStream(const Section, Name: string;
  Value: TStream);
var
  Key, OldKey: HKEY;
  Stream: TMemoryStream;
begin
  with RegIniFile do
  begin
    CreateKey(Section);
    Key := TRegistry(FRegIniFile).GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      if Value is TMemoryStream then
        Stream := TMemoryStream(Value)
      else Stream := TMemoryStream.Create;
      try
        if Stream <> Value then
        begin
          Stream.CopyFrom(Value, Value.Size - Value.Position);
          Stream.Position := 0;
        end;
        TRegistry(FRegIniFile).SetCurrentKey(Key);
        try
          WriteBinaryData(Name, Pointer(Integer(Stream.Memory) + Stream.Position)^,
            Stream.Size - Stream.Position);
        finally
          TRegistry(FRegIniFile).SetCurrentKey(OldKey);
        end;
      finally
        if Value <> Stream then Stream.Free;
      end;
    finally
      RegCloseKey(Key);
    end;
  end;
end;

procedure TRegistryIniFile.WriteString(const Section, Ident, Value: String);
begin
  FRegIniFile.WriteString(Section, Ident, Value);
end;

procedure TRegistryIniFile.ReadSection(const Section: string; Strings: TStrings);
begin
  FRegIniFile.ReadSection(Section, Strings);
end;

procedure TRegistryIniFile.ReadSections(Strings: TStrings);
begin
  FRegIniFile.ReadSections(Strings);
end;

procedure TRegistryIniFile.ReadSectionValues(const Section: string; Strings: TStrings);
begin
  FRegIniFile.ReadSectionValues(Section, Strings);
end;

procedure TRegistryIniFile.EraseSection(const Section: string);
begin
  FRegIniFile.EraseSection(Section);
end;

procedure TRegistryIniFile.DeleteKey(const Section, Ident: String);
begin
  FRegIniFile.DeleteKey(Section, Ident);
end;

procedure TRegistryIniFile.UpdateFile;
begin
  { Do nothing }
end;

procedure TRegistryIniFile.ReadSections(const Section: string; Strings: TStrings);
var
  Key, OldKey: HKEY;
begin
  with RegIniFile do
  begin
    Key := GetKey(Section);
    if Key <> 0 then
    try
      OldKey := CurrentKey;
      SetCurrentKey(Key);
      try
        GetKeyNames(Strings);
      finally
        SetCurrentKey(OldKey);
      end;
    finally
      RegCloseKey(Key);
    end;
  end;
end;

end.



