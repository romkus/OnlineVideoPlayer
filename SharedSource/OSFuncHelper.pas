unit OSFuncHelper;

interface
uses SysUtils, Classes, Windows, SysConst, AnsiStrings, Registry, DataHelper;

const
          c_SystemSays = 'Система каже:';
          c_ObjectSays = 'Об''єкт каже:';
          c_Warning = 'Warning';
          c_Error = 'Error';

          sc_FallenOnError = ' упав, через помилку:';
          sc_StartsItsWork=' починає роботу...';
          sc_FinishedItsWork=' завершив роботу...';

      cs_ErrorInProcessor = ': сталася помилка в обробнику ';
      cs_ReportedAnError = ' повідомило про помилку... ';
      sc_CantReadEnvironmentVariable = 'не вдалося прочитати змінну середовища:';

      cs_CantAddNetworkShare = 'не вдалося під''єднати мережеву папку';
      cs_CantRemoveNetworkShare = 'не вдалося від''єднати мережеву папку';
      cs_CantLoadLibrary = 'не вдалося завантажити бібліотеку';
      cs_CantUnloadLibrary = 'не вдалося вивантажити бібліотеку';
      cs_CantGetLibraryHandle = 'Не вдалося отримати важіль на бібіліотеку';
      cs_WillTryToLoadIt = 'спробую її завантажити';
      cs_CantGetProcAddress = 'Не вдалося отримати адресу процедури';
      //cs_IsWow64ProcessFailed = 'Функція IsWow64Process відмовила';
      cs_Function = 'Функція';
      cs_fFailed = 'відмовила';
      cs_Returned = 'повернуло';
      cs_fReturned = 'повернула';

      cs_CantOpenRegKey = 'не вдалося відкрити ключ реєстра';
      cs_CantWriteRegValue = 'не вдалося записати змінну в реестр';

      cs_ThisDir = '.';
      cs_SuperiorDir = '..';

      cs_AllFilesMask = '*';

        // Ascii-коди клавіш...:
      ci_SpaceKey = 32;  ci_EnterKey = 13;

      c_EmergencySleepTime = 5000; // при неочікуваних помилках перед продовженням роботи, мс
      c_WaitForGoodWindSleepTime = 7000;

      COPY_FILE_ALLOW_DECRYPTED_DESTINATION = $00000008;
      PROCESS_QUERY_LIMITED_INFORMATION = $1000;

      STATUS_SUCCESS = 0;

        // wProductType:
      VER_NT_WORKSTATION = $0000001;
      VER_NT_DOMAIN_CONTROLLER = $0000002;
      VER_NT_SERVER = $0000003;
        // wSuiteMask:
      VER_SUITE_WH_SERVER = $00008000;
      VER_SUITE_TERMINAL = $00000010;

      VER_SUITE_STORAGE_SERVER = $00002000;

      VER_SUITE_SMALLBUSINESS_RESTRICTED = $00000020;

      VER_SUITE_SMALLBUSINESS = $00000001;

      VER_SUITE_SINGLEUSERTS = $00000100;

      VER_SUITE_PERSONAL = $00000200;

      VER_SUITE_EMBEDDEDNT = $00000040;

      VER_SUITE_ENTERPRISE = $00000002;

      VER_SUITE_DATACENTER = $00000080;

      VER_SUITE_COMPUTE_SERVER = $00004000;

      VER_SUITE_BLADE = $00000400;

      VER_SUITE_BACKOFFICE = $00000004;

      cs_Advapi32Name = 'advapi32.dll';

      cs_RegGetValueProcName =
        {$IFDEF UNICODE}'RegGetValueW'{$ELSE}'RegGetValueA'{$ENDIF};

      MB_TIMEDOUT = 32000;

      MB_AllMessageBoxButtonsMask = Windows.MB_TYPEMASK; // $0F;
      MB_AllMessageBoxIconsMask = Windows.MB_ICONMASK;   // $F0;
      MB_AllMessageBoxWndTypeMask = $00FF0000;
      ci_DefOkMsgBoxType = MB_OK or MB_TOPMOST;

type
  TNTSTATUS = DWord;

  // --- Описи типів функцій і процедур що не знайдені у модулі Windows.pas ---

  //TIsWow64Process = function(hProcess: THandle; var Wow64Process: BOOL): BOOL;
  //  stdcall;

  // ntdll.dll
  TRtlGetVersion = function(
    Var lpVersionInformation:Windows.RTL_OSVERSIONINFOEXW): TNTSTATUS; stdcall;
     //можливо cdecl?.. в NTOSKrnl.exe може й так..

  //advapi32.dll
  //TRegGetValue = function(hkey:HKEY; lpSubKey:LPCTSTR;
  //  lpValue:LPCTSTR; dwFlags:DWORD; Var pdwType: DWORD;
  //  pvData: PByte; Var pcbData: DWORD): LongInt; stdcall;

  TRegGetValue = function(hkey:HKEY; lpSubKey:LPCTSTR;
    lpValue:LPCTSTR; dwFlags:DWORD; pdwType: LPDWORD;
    pvData: PByte; pcbData: LPDWORD): LongInt; stdcall;

 { LONG WINAPI RegGetValue(
  _In_        HKEY    hkey,
  _In_opt_    LPCTSTR lpSubKey,
  _In_opt_    LPCTSTR lpValue,
  _In_opt_    DWORD   dwFlags,
  _Out_opt_   LPDWORD pdwType,
  _Out_opt_   PVOID   pvData,
  _Inout_opt_ LPDWORD pcbData
);}


type
//  TFilePathsArray = array of String;

  TDLLLoader = class(TObject)
    private
      cDLLHandle: THandle;
      cDLLName:String;
      cLogFile: TLogFile;
      cNeedNoFreeHandle: Boolean;
    public
      constructor Create(Const sDLLName:String; sLogFile:TLogFile = Nil);
      destructor Destroy; override;
      Function GetDLLProcOrFuncAddr(sProcOrFuncName:String):Pointer;

      property DLLHandle: THandle read cDLLHandle;
      property DLLName: String read cDllName;
      property LogFile: TLogFile read cLogFile write cLogFile;
  end;

function FormatOSError(sCommentToError:String; LastError: Integer):SysUtils.EOSError;
function FormatLastOSError(sCommentToError:String):SysUtils.EOSError;
procedure RaiseLastOSError(sCommentToError:String); overload;
procedure RaiseLastOSError(sCommentToError:String; LastError: Integer); overload;

procedure LogLastOSError(sCommentToError:String; LastError: Integer;
   sLogFile:TLogFile); overload;
procedure LogLastOSError(sCommentToError:String; sLogFile:TLogFile); overload;

  // Управління об'єктами подій (Windows.CreateEvent):
Function ProcCreateEvent(Const sMessageOnError:String;
   bManualReset: Windows.BOOL = True; bInitialState: Windows.BOOL = True;
   lpName: PWideChar = Nil; sLogFile:TLogFile = Nil):Windows.THandle;
Function ProcSetEvent(sEvent:THandle; Const sMessageOnError:String;
      sLogFile:TLogFile = Nil):Boolean;
function ProcResetEvent(sEvent:THandle; Const sMessageOnError:String;
      sLogFile:TLogFile = Nil):Boolean;
Procedure ProcCloseHandle(Var sHandle:THandle; Const sMessageOnError:String;
  sLogFile:TLogFile = Nil);

function GetEnvironmentVariableWithLogErrors(const Name: string;
  sLogFile:TLogFile; const sMessageOnError:String = ''): string;
  // Функції роботи із мережевими папками:
function ConnectShare(Drive, RemotePath, UserName, Password : String;
          sLogFile: TLogFile = Nil;
          sWindow: HWND = 0):Integer;
function DisconnectShare(Drive : String; sLogFile:TlogFile = Nil):Integer;

Procedure FindFiles(Const sDir, sMask:String;
           Var sdPathList:TStrings;
           sSearchSubdirs:Boolean = False;
           sAttr:Integer = faHidden or faSysFile; // or faDirectory
             // якщо sStrictAttr=False то незалежно від sAttr повертаються і
             // звичайні файли (без атрибутів):
           sStrictAttr:Boolean = False;
           sLogFile:TLogFile = Nil);

Function CopyFile(Const sSourceDir, sDestDir,
              sFileName:String; sLogFile:TLogFile = Nil):Boolean; overload;
Function CopyFile(Const sSourcePath, sDestPath:String;
              sLogFile:TLogFile = Nil):Boolean; overload;
Function CopyFileToDir(Const sSourcePath, sDestDir:String;
              sLogFile:TLogFile = Nil):Boolean;

Function CopyListOfFiles(sList:TStrings; Const sDestDir:String;
  sBreakOnError:Boolean = True;
  sLogFile:TLogFile = Nil):Boolean;

{//------------------ Робота із реєстром
//Function ReadRegValue(sKey:String; )
Function WriteRegValue(Const sRegistry:TRegistry; Const sKey, sValueName:String;
           Const sValue:String; Const sLogFile:TLogFile):Boolean; overload;
Function ReadRegValue(Const sRegistry:TRegistry; Const sKey, sValueName:String;
           Var sValue:String; Const sLogFile:TLogFile):Boolean; overload;}
//OpenKey(const Key: string;

// Is64BitWindows взята із http://stackoverflow.com/questions/2523957/how-to-get-information-about-the-computer-32bit-or-64bit
// Перероблена.
function Is64BitWindows(sLogFile:TLogFile = Nil): boolean;

Function GetOSVersion(Var dMinor, dMajor, dBuildNumber,
           dSPMajor, dSPMinor: DWord; Var dSuiteMask:Word;
           Var dProductType: Byte;
           Var dVerName, dSuiteFeatures:String;
           sLogFile:TLogFile = Nil):Boolean;


function MessageBoxTimeOut(hWnd: HWND; lpText: PChar; lpCaption: PChar;
                           uType: UINT; wLanguageId: WORD; dwMilliseconds: DWORD): Integer; stdcall;

function MessageBoxTimeOutA(hWnd: HWND; lpText: PChar; lpCaption: PChar;
                            uType: UINT; wLanguageId: WORD; dwMilliseconds: DWORD): Integer; stdcall;


function MessageBoxTimeOutW(hWnd: HWND; lpText: PWideChar; lpCaption: PWideChar;
                            uType: UINT; wLanguageId: WORD; dwMilliseconds: DWORD): Integer; stdcall;

implementation

function FormatOSError(sCommentToError:String; LastError: Integer):SysUtils.EOSError;
var
  Error: SysUtils.EOSError;
Begin
  //if LastError <> 0 then
    Error := SysUtils.EOSError.CreateResFmt(@SysConst.SOSError, [LastError,
      sCommentToError + SysUtils.SysErrorMessage(LastError)]);
  //else
  //  Error := SysUtils.EOSError.CreateResFmt(@SysConst.SUnkOSError, [LastError,
  //    sCommentToError + SysUtils.SysErrorMessage(LastError)]);
  Error.ErrorCode := LastError;

  FormatOSError:= Error;
End;

function FormatLastOSError(sCommentToError:String):SysUtils.EOSError;
Begin
  Result:= FormatOSError(sCommentToError, GetLastError);
End;
procedure RaiseLastOSError(sCommentToError:String; LastError: Integer);
begin
  raise FormatOSError(sCommentToError, LastError);
end;

procedure LogLastOSError(sCommentToError:String; LastError: Integer;
   sLogFile:TLogFile);
Var cError: SysUtils.EOSError;
begin
  cError:= FormatOSError(sCommentToError, LastError);
  if sLogFile<>Nil then
    sLogFile.WriteMessage(cError.Message)
  else
  begin
    raise cError;
  end;
end;

procedure RaiseLastOSError(sCommentToError:String);
begin
  RaiseLastOSError(sCommentToError, Windows.GetLastError);
end;

procedure LogLastOSError(sCommentToError:String; sLogFile:TLogFile);
Begin
  LogLastOSError(sCommentToError, Windows.GetLastError, sLogFile);
End;


Function ProcCreateEvent(Const sMessageOnError:String;
   bManualReset: Windows.BOOL = True; bInitialState: Windows.BOOL = True;
   lpName: PWideChar = Nil; sLogFile:TLogFile = Nil):Windows.THandle;
Var cEvent: THandle;
Begin
  cEvent:= Windows.CreateEvent(Nil,  // у спадок іншим процесам подію не передаємо
    bManualReset,
    bInitialState,
    lpName);

  if cEvent = 0 then LogLastOsError(sMessageOnError, sLogFile);

  ProcCreateEvent:= cEvent;
End;

Function ProcSetEvent(sEvent:THandle; Const sMessageOnError:String;
      sLogFile:TLogFile = Nil):Boolean;
Var Res:Boolean;
Begin
    // Встановлюємо сигнал події:
  If Not(Windows.SetEvent(sEvent)) then
  Begin
    LogLastOsError(sMessageOnError, sLogFile);
    Res:= False;
  End
  Else Res:=True;
  ProcSetEvent:= Res;
End;

function ProcResetEvent(sEvent:THandle; Const sMessageOnError:String;
      sLogFile:TLogFile = Nil):Boolean;
Var Res:Boolean;
Begin
    // Знімаємо сигнал події:
  If Not(Windows.ResetEvent(sEvent)) then
  Begin
    LogLastOsError(sMessageOnError, sLogFile);
    Res:= False;
  End
  Else Res:=True;
  ProcResetEvent:= Res;
End;

Procedure ProcCloseHandle(Var sHandle:THandle; Const sMessageOnError:String;
  sLogFile:TLogFile = Nil);
Begin
  if sHandle <> 0 then
  Begin
    If Not(Windows.CloseHandle(sHandle)) then
      LogLastOSError(sMessageOnError, sLogFile);
    sHandle:= 0;
  End;
End;

// Перероблено із SysUtils.GetEnvironmentVariable:
function GetEnvironmentVariableWithLogErrors(const Name: string;
  sLogFile:TLogFile; const sMessageOnError:String = ''): string;
const
  BufSize = 1024;
  cs_ProcName = 'GetEnvironmentVariableWithLogErrors';
var
  Len: Integer;
  Buffer: array[0..BufSize - 1] of Char;
  ccMessageOnError:String;
begin
  Result := '';
  Len := Windows.GetEnvironmentVariable(PChar(Name), @Buffer, BufSize);
  if Len = 0 then
  Begin
    ccMessageOnError:= cs_ProcName+ c_DoubleDot+c_Space+sMessageOnError+
         sc_CantReadEnvironmentVariable+Name+c_Dot+c_SystemSays;
    if System.Assigned(sLogFile) then
      LogLastOSError(ccMessageOnError, sLogFile)
    Else RaiseLastOSError(ccMessageOnError);
    Result := '';
  End
  Else if Len < BufSize then
    SetString(Result, PChar(@Buffer), Len)
  else
  begin
    SetLength(Result, Len - 1);
    Len:= Windows.GetEnvironmentVariable(PChar(Name), PChar(Result), Len);
    if Len = 0 then
    Begin
      ccMessageOnError:= cs_ProcName+ c_DoubleDot+c_Space+sMessageOnError+
         sc_CantReadEnvironmentVariable+Name+c_Dot+c_SystemSays;

      if System.Assigned(sLogFile) then
        LogLastOSError(ccMessageOnError, sLogFile)
      Else RaiseLastOSError(ccMessageOnError);
      Result := '';
    End;
  end;
end;

function ConnectShare(Drive, RemotePath, UserName, Password : String;
          sLogFile: TLogFile = Nil;
          sWindow: HWND = 0):Integer;
const cs_ProcName = 'ConnectShare';
var
  NRW : TNetResource;
  ccFlags: DWord;
begin
  with NRW do
  begin
    dwType := RESOURCETYPE_ANY;
    if Drive <> '' then
      lpLocalName := PChar(Drive)
    else
      lpLocalName := nil;
    lpRemoteName := PChar(RemotePath);
    lpProvider := '';
  end;

  ccFlags:= 0;
  if sWindow<>0 then
    ccFlags:= ccFlags or Windows.CONNECT_INTERACTIVE;

  Result := Windows.WNetAddConnection3(sWindow,
    NRW, PChar(Password), PChar(UserName), ccFlags);

//    function WNetAddConnection3(hwndOwner: HWND; var lpNetResource: TNetResource;
//  lpPassword, lpUserName: PWideChar; dwFlags: DWORD): DWORD; stdcall;

  if Assigned(sLogFile) and (Result <> Windows.NO_ERROR) then
  Begin
    LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
      cs_CantAddNetworkShare+
      c_Space + c_SystemSays, Result,
      sLogFile);
  End;
end;

function DisconnectShare(Drive : String; sLogFile:TlogFile = Nil):Integer;
const cs_ProcName = 'DisconnectShare';
begin
  Result := Windows.WNetCancelConnection2(PChar(Drive), 0, false);
  if Assigned(sLogFile) and (Result <> Windows.NO_ERROR) then
  Begin
    LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
      cs_CantRemoveNetworkShare+
      c_Space + c_SystemSays, Result,
      sLogFile);
  End;
end;

Procedure FindFiles(Const sDir, sMask:String;
           Var sdPathList:TStrings;
           sSearchSubdirs:Boolean = False;
           sAttr:Integer = faHidden or faSysFile; // or faDirectory
             // якщо sStrictAttr=False то незалежно від sAttr повертаються і
             // звичайні файли (без атрибутів):
           sStrictAttr:Boolean = False;
           sLogFile:TLogFile = Nil);
const cs_ProcName = 'FindFiles';
var ccResult: Integer;
    ccShRec: SysUtils.TSearchRec;
    ccPath, ccDirAndSlash:String;
    ccAttr: Integer;
Begin
 ccDirAndSlash:= SysUtils.IncludeTrailingPathDelimiter(sDir);
 ccPath:= ccDirAndSlash + sMask;

 ccAttr:= sAttr;

// if sSearchSubdirs = True then
//   ccAttr:= ccAttr or faDirectory;

 ccResult:= SysUtils.FindFirst(ccPath, ccAttr, ccShRec);
// function FindFirst(const Path: string; Attr: Integer;
//  var  F: TSearchRec): Integer;
 while ccResult = 0 do
 Begin
   if (NOT(SStrictAttr)) or
        ((ccShRec.Attr and sAttr) = ccShRec.Attr) then
            sdPathList.Add(ccDirAndSlash + ccShRec.Name);
   ccResult:= SysUtils.FindNext(ccShRec);
 End;

 if ccResult <> 0 then
 Begin
   if Assigned(sLogFile) then
   Begin
     LogLastOSError(cs_ProcName + c_DoubleDot+c_Space+
        c_SystemSays, ccResult, sLogFile);
   End;
 End;

 SysUtils.FindClose(ccShRec);

 if sSearchSubdirs then
 Begin
   //Windows.ZeroMemory(ccShRec, SizeOf(ccShRec));

   ccPath:= ccDirAndSlash + cs_AllFilesMask;
   ccAttr:= sAttr or faDirectory;
   ccResult:= SysUtils.FindFirst(ccPath, ccAttr, ccShRec);
   while ccResult = 0 do
   Begin
     if ((ccShRec.Attr and faDirectory) = faDirectory) then
     Begin
       if Not((ccShRec.Name = cs_ThisDir) or
          (ccShRec.Name = cs_SuperiorDir)) then
       Begin
         FindFiles(ccDirAndSlash + ccShRec.Name,
             sMask,
             sdPathList,
             sSearchSubdirs,
             sAttr,
             sStrictAttr,
             sLogFile);
       End;
     End;
     ccResult:= SysUtils.FindNext(ccShRec);
   End;
   SysUtils.FindClose(ccShRec);
 End;
End;

Function CopyFile(Const sSourceDir, sDestDir,
              sFileName:String; sLogFile:TLogFile = Nil):Boolean;
Var ccSourcePath, ccDestPath:String;
Begin
  ccSourcePath:= SysUtils.IncludeTrailingPathDelimiter(sSourceDir)+
    sFileName;
  ccDestPath:= SysUtils.IncludeTrailingPathDelimiter(sDestDir)+
    sFileName;

  Result:= CopyFile(ccSourcePath, ccDestPath,
              sLogFile);
End;

Function CopyFileToDir(Const sSourcePath, sDestDir:String;
              sLogFile:TLogFile = Nil):Boolean;
Var ccDestPath, ccFileName:String;
Begin
  ccFileName:= SysUtils.ExtractFileName(sSourcePath);
  ccDestPath:= SysUtils.IncludeTrailingPathDelimiter(sDestDir)+
    ccFileName;

  Result:= CopyFile(sSourcePath, ccDestPath, sLogFile);
End;
Function CopyFile(Const sSourcePath, sDestPath:String;
              sLogFile:TLogFile = Nil):Boolean; overload;
const cs_ProcName = 'CopyFile';
Var
      ccCancel: BOOL;
Begin
  ccCancel:= False;
  if Not(Windows.CopyFileEx(PWideChar(sSourcePath), PWideChar(sDestPath),
    Nil,   //lpProgressRoutine: TFNProgressRoutine
    Nil,   //lpData: Pointer
    Addr(ccCancel), //pbCancel: PBool;
    COPY_FILE_ALLOW_DECRYPTED_DESTINATION   //dwCopyFlags: DWORD
    )) then
  Begin
    if Assigned(sLogFile) then
    Begin
      LogLastOSError(cs_ProcName + c_DoubleDot+c_Space+
        c_SystemSays, sLogFile);
    End;
    Result:= False;
  End
  Else Result:= True;

  //function CopyFileEx(lpExistingFileName, lpNewFileName: PWideChar;
  //lpProgressRoutine: TFNProgressRoutine; lpData: Pointer; pbCancel: PBool;
  //dwCopyFlags: DWORD): BOOL; stdcall;
End;


Function CopyListOfFiles(sList:TStrings; Const sDestDir:String;
  sBreakOnError:Boolean = True;
  sLogFile:TLogFile = Nil):Boolean;
var ccFileNum:Integer; ccResult:Boolean;
Begin
  ccResult:= True;
  for ccFileNum := 0 to sList.Count - 1 do
  Begin
    If Not(CopyFileToDir(sList[ccFileNum], sDestDir,
              sLogFile)) then
    Begin
      ccResult:= False;
      if sBreakOnError then Break;
    End;
  End;

  Result:= ccResult;
End;

//------------------------------------------------------
// Is64BitWindows взята із http://stackoverflow.com/questions/2523957/how-to-get-information-about-the-computer-32bit-or-64bit
// Перероблена.
function Is64BitWindows(sLogFile:TLogFile = Nil): boolean;
  {$IFDEF CPUX64}
  {$DEFINE CPU64}
  {$ENDIF}
  {$IFDEF CPU64}
begin // IsWow64Process повертає false, якщо і сама програма 64-бітна,
      // тому якщо компілятор каже що він компілює в x64 то це буде x64:
  Result := True;
End;
  {$ELSE}
const cs_ProcName = 'Is64BitWindows';
      cs_BaseProcName = 'IsWow64Process';
      cs_KernelLibFileName = 'kernel32.dll';
type
  TIsWow64Process = function(hProcess: THandle; var Wow64Process: BOOL): BOOL;
    stdcall;
var
  DLLHandle: THandle;
  pIsWow64Process: TIsWow64Process;
  IsWow64: BOOL;
begin
  Result := False;
  DllHandle := LoadLibrary(cs_KernelLibFileName);
  if DLLHandle <> 0 then begin
    try
      pIsWow64Process := GetProcAddress(DLLHandle, cs_BaseProcName);
      if Assigned(pIsWow64Process) then
      Begin
        Result := pIsWow64Process(GetCurrentProcess, IsWow64);
        if Result then Result:= IsWow64
        Else if Assigned(sLogFile) then
        Begin
          LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
            cs_Function+c_Space+cs_BaseProcName+c_Space+cs_fFailed+
            c_Dot+c_Space+c_SystemSays+
            c_Space, sLogFile);
        End;
      End
      else if Assigned(sLogFile) then
        LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantGetProcAddress+c_DoubleDot+c_Space+c_Quotes+
          cs_BaseProcName+c_Quotes+c_Dot+c_Space+c_SystemSays+
          c_Space, sLogFile);
    finally
      FreeLibrary(DLLHandle);
    end;
  end
  Else if Assigned(sLogFile) then
  Begin
    LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
      cs_CantLoadLibrary+c_DoubleDot+c_Space+c_Quotes+
      cs_KernelLibFileName+c_Quotes+c_Dot+c_Space+c_SystemSays+
      c_Space, sLogFile);
  End;
end;
  {$ENDIF}

Procedure AddMessage(Var sdString:String; Const sMessage:String;
    sDelimiter:String = c_Comma + c_Space);
Begin
  if sdString = '' then sdString:= sMessage
  Else sdString:= sdString + sDelimiter + sMessage;
End;

{  TDLLLoader = class(TObject)
    private
      cDLLHandle: THandle;
      cLogFile: TLogFile;
      cNeedNoFreeHandle: Boolean;
    public
      constructor Create(Const sDLLName:String; sLogFile:TLogFile = Nil);
      destructor Destroy; override;
      Function GetDLLProcOrFuncAddr(sProcOrFuncName:String):Pointer;

      property DLLHandle: THandle read cDLLHandle;
  end; }

constructor TDLLLoader.Create(Const sDLLName:String; sLogFile:TLogFile = Nil);
const cs_ProcName = 'TDLLLoader.Create';
Var ccMessage:String;
Begin
  Inherited Create;
  Self.cNeedNoFreeHandle:= False;
  Self.cLogFile:= sLogFile;
  Self.cDLLHandle:= Windows.GetModuleHandle(PChar(sDLLName));
  if (Self.cDLLHandle = 0) then
  Begin
    if Assigned(Self.cLogFile) then
      LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
        cs_CantGetLibraryHandle+c_DoubleDot+c_Space+c_Quotes+
        sDLLName+c_Quotes+c_Dot+c_Space+cs_WillTryToLoadIt+c_Dot+
        c_Space+c_SystemSays+
        c_Space, sLogFile);

    Self.cDLLHandle:= Windows.LoadLibrary(PChar(sDLLName));
    if Self.cDLLHandle = 0 then
    begin
      ccMessage:= cs_ProcName+c_DoubleDot+c_Space+
          cs_CantLoadLibrary+c_DoubleDot+c_Space+c_Quotes+
          sDLLName+c_Quotes+c_Dot+c_Space+c_SystemSays+
          c_Space;
      if Assigned(Self.cLogFile) then
        LogLastOSError(ccMessage, sLogFile);
      LogLastOSError(ccMessage, Nil); // raise exception
    end
    Else Self.cNeedNoFreeHandle:= True;
  End;

  Self.cDllName:= sDLLName;
End;

destructor TDLLLoader.Destroy;
const cs_ProcName = 'TDLLLoader.Destroy';
Var ccResult:Boolean;
Begin
  if Self.cNeedNoFreeHandle then
  Begin
    ccResult:= Windows.FreeLibrary(Self.cDLLHandle);
    if ccResult then Self.cDLLHandle:= 0
    Else if Assigned(Self.cLogFile) then
      LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
        cs_CantUnloadLibrary+c_DoubleDot+c_Space+c_Quotes+
        Self.DLLName+c_Quotes+c_Dot+
        c_Space+c_SystemSays+
        c_Space, Self.cLogFile);
  End;

  Self.cLogFile:= Nil;
  Self.cDLLName:= '';
  Inherited Destroy;
End;

Function TDLLLoader.GetDLLProcOrFuncAddr(sProcOrFuncName:String):Pointer;
const cs_ProcName = 'TDLLLoader.GetDLLProcOrFuncAddr';
Begin
  Result:= Windows.GetProcAddress(Self.cDLLHandle, PChar(sProcOrFuncName));
  if Not(System.Assigned(Result)) then
  Begin
    if System.Assigned(Self.cLogFile) then
      LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantGetProcAddress+c_DoubleDot+c_Space+c_Quotes+
          sProcOrFuncName+c_Quotes+c_Dot+c_Space+c_SystemSays+
          c_Space, Self.cLogFile);
  End;
End;

//------------------------------------------------------
Function GetOSVersion(Var dMinor, dMajor, dBuildNumber,
           dSPMajor, dSPMinor: DWord; Var dSuiteMask:Word;
           Var dProductType: Byte;
           Var dVerName, dSuiteFeatures:String;
           sLogFile:TLogFile = Nil):Boolean;
const cs_ProcName = 'GetOSVersion';
      cs_BaseProcName = 'RtlGetVersion';
      cs_KernelLibFileName = 'ntdll.dll';
      cs_Windows='Windows';
      cs_Server = 'Server';
      cs_NT_DOMAIN_CONTROLLER = 'Domain Controller';
      //ci_MajorKoef = 1000;
      ci_MajorShl = 16;
      ci_Windows2000 = $50000;
      ci_WindowsXP = $50001;
      ci_WindowsXPx64ProfOrServer2003OrHomeServer = $50002;
      ci_WindowsVistaOrServer2008 = $60000;
      ci_Windows7OrServer2008R2 = $60001;
      ci_Windows80OrServer2012 = $60002;
      ci_Windows81 = $60003;
var
  DLLHandle: THandle;
  ccVersionInfo:Windows.RTL_OSVERSIONINFOEXW;
  PRtlGetVersion: TRtlGetVersion;
  ccStatus: TNTSTATUS;
  ccVersionMinorAndMajor:Cardinal;
  ccCSDVersion:String;
  //IsWow64: BOOL;
Begin
  dMinor:= 0;
  dMajor:= 0;
  dBuildNumber:= 0;
  dSPMajor:= 0;
  dSPMinor:= 0;
  dVerName:= '';
  dSuiteFeatures:= '';
  dSuiteMask:= 0;
  dProductType:= 0;

  Result := False;


  DllHandle := Windows.GetModuleHandle(cs_KernelLibFileName);
  if DLLHandle <> 0 then
  Begin
    Windows.ZeroMemory(Addr(ccVersionInfo), SizeOf(ccVersionInfo));
    ccVersionInfo.dwOSVersionInfoSize:= SizeOf(ccVersionInfo);

    PRtlGetVersion := GetProcAddress(DLLHandle, cs_BaseProcName);
    if Assigned(PRtlGetVersion) then
    Begin
      ccStatus:= PRtlGetVersion(ccVersionInfo);
      if ccStatus = STATUS_SUCCESS then
      Begin
        dMinor:= ccVersionInfo.dwMinorVersion;
        dMajor:= ccVersionInfo.dwMajorVersion;
        dBuildNumber:= ccVersionInfo.dwBuildNumber;
        dSPMajor:= ccVersionInfo.wServicePackMajor;
        dSPMinor:= ccVersionInfo.wServicePackMinor;
        dSuiteMask:= ccVersionInfo.wSuiteMask;
        dProductType:= ccVersionInfo.wProductType;

        //ccVersionMinorAndMajor:= (dMajor*ci_MajorKoef) + dMinor;
        ccVersionMinorAndMajor:= (dMajor shl ci_MajorShl) or dMinor;

        dVerName:= cs_Windows+c_Space;

        case ccVersionMinorAndMajor of
           ci_Windows2000:
           Begin
             dVerName:= dVerName+'2000';
             case dProductType of
               VER_NT_SERVER: dVerName:= dVerName + c_Space + cs_Server;
               VER_NT_DOMAIN_CONTROLLER: dVerName:= dVerName + c_Space +
                 cs_NT_DOMAIN_CONTROLLER;
             end;
           End;
           ci_WindowsXP:
           Begin
             dVerName:= dVerName+'XP';
             case dProductType of
               VER_NT_SERVER: dVerName:= dVerName + c_Space + cs_Server;
               VER_NT_DOMAIN_CONTROLLER: dVerName:= dVerName + c_Space +
                 cs_NT_DOMAIN_CONTROLLER;
             end;
           End;
           ci_WindowsXPx64ProfOrServer2003OrHomeServer:
           Begin
             if dProductType = VER_NT_WORKSTATION then
               dVerName:= dVerName+'XP x64'
             else if (dSuiteMask and VER_SUITE_WH_SERVER) =
                       VER_SUITE_WH_SERVER then
               dVerName:= dVerName+'XP Home server'
             else dVerName:= dVerName + c_Space + cs_Server + '2003';
           End;
           ci_WindowsVistaOrServer2008:
           Begin
             case dProductType of
               VER_NT_SERVER: dVerName:= dVerName + cs_Server +
                  ' 2008';
               VER_NT_DOMAIN_CONTROLLER: dVerName:= dVerName
                   + cs_Server +
                   ' 2008' + c_Space + cs_NT_DOMAIN_CONTROLLER;
               else
                 dVerName:= dVerName+'Vista';
             end;
           End;
           ci_Windows7OrServer2008R2:
           Begin
             case dProductType of
               VER_NT_SERVER: dVerName:= dVerName +
                  cs_Server + ' 2008 R2';
               VER_NT_DOMAIN_CONTROLLER: dVerName:= dVerName +
                  cs_Server +  ' 2008 R2' +
                  c_Space + cs_NT_DOMAIN_CONTROLLER;
               else
                 dVerName:= dVerName+'7';
             end;
           End;
           ci_Windows80OrServer2012:
           Begin
             case dProductType of
               VER_NT_SERVER: dVerName:= dVerName +
                  cs_Server + ' 2012';
               VER_NT_DOMAIN_CONTROLLER: dVerName:= dVerName +
                  cs_Server +  ' 2012' +
                  c_Space + cs_NT_DOMAIN_CONTROLLER;
               else
                 dVerName:= dVerName+'8';
             end;
           End;
           ci_Windows81:
           Begin
             case dProductType of
               VER_NT_SERVER: dVerName:= dVerName +
                  cs_Server + ' 2012 R2';
               VER_NT_DOMAIN_CONTROLLER: dVerName:= dVerName +
                  cs_Server +  ' 2012 R2' +
                  c_Space + cs_NT_DOMAIN_CONTROLLER;
               else
                 dVerName:= dVerName+'8.1';
             end;
           End;
           Else
           Begin
             dVerName:= dVerName + SysUtils.IntToStr(dMajor) +c_Dot+
               SysUtils.IntToStr(dMinor);

             case dProductType of
               VER_NT_SERVER: dVerName:= dVerName + c_Space +
                  cs_Server;
               VER_NT_DOMAIN_CONTROLLER: dVerName:= dVerName + c_Space +
                  cs_NT_DOMAIN_CONTROLLER;
             end;
           End;
        end;

        ccCSDVersion:= SysUtils.StrPas(PWideChar(Addr(ccVersionInfo.szCSDVersion)));

        if ccCSDVersion<>'' then
          dVerName:= dVerName + c_Space + ccCSDVersion;

        dSuiteFeatures:= '';

        if (dSuiteMask and VER_SUITE_WH_SERVER) = VER_SUITE_WH_SERVER then
        Begin
          AddMessage(dSuiteFeatures, 'Home server');
        End;

        if (dSuiteMask and VER_SUITE_TERMINAL) = VER_SUITE_TERMINAL then
        Begin
          if (dSuiteMask and VER_SUITE_SINGLEUSERTS) = VER_SUITE_SINGLEUSERTS then
          Begin
            AddMessage(dSuiteFeatures, 'One remote desktop');
          End
          Else AddMessage(dSuiteFeatures, 'Terminal (remote desktop server)');
        End;

        if (dSuiteMask and VER_SUITE_STORAGE_SERVER) = VER_SUITE_STORAGE_SERVER then
        Begin
          AddMessage(dSuiteFeatures, 'Storage server');
        End;

        if (dSuiteMask and VER_SUITE_SMALLBUSINESS) = VER_SUITE_SMALLBUSINESS then
        Begin
          if (dSuiteMask and VER_SUITE_SMALLBUSINESS_RESTRICTED) = VER_SUITE_SMALLBUSINESS_RESTRICTED then
            AddMessage(dSuiteFeatures, 'Small business')
          else AddMessage(dSuiteFeatures, 'Small business in past');
        End;

        if (dSuiteMask and VER_SUITE_PERSONAL) = VER_SUITE_PERSONAL then
        Begin
          AddMessage(dSuiteFeatures, 'Home')
        End;

        if (dSuiteMask and VER_SUITE_EMBEDDEDNT) = VER_SUITE_EMBEDDEDNT then
        Begin
          AddMessage(dSuiteFeatures, 'Embedded')
        End;

        if (dSuiteMask and VER_SUITE_ENTERPRISE) = VER_SUITE_ENTERPRISE then
        Begin
          AddMessage(dSuiteFeatures, 'Enterprise')
        End;

        if (dSuiteMask and VER_SUITE_DATACENTER) = VER_SUITE_DATACENTER then
        Begin
          AddMessage(dSuiteFeatures, 'Datacenter')
        End;

        if (dSuiteMask and VER_SUITE_COMPUTE_SERVER) = VER_SUITE_COMPUTE_SERVER then
        Begin
          AddMessage(dSuiteFeatures, 'Compute cluster')
        End;

        if (dSuiteMask and VER_SUITE_BLADE) = VER_SUITE_BLADE then
        Begin
          AddMessage(dSuiteFeatures, 'Web')
        End;

        if (dSuiteMask and VER_SUITE_BACKOFFICE) = VER_SUITE_BACKOFFICE then
        Begin
          AddMessage(dSuiteFeatures, 'BackOffice')
        End;
      End
      Else if Assigned(sLogFile) then
      Begin
        LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_Function+c_Space+cs_BaseProcName+c_Space+cs_fFailed+
          '('+cs_fReturned+c_Space+SysUtils.IntToStr(ccStatus)+')'+
          c_Dot+c_Space+c_SystemSays+
          c_Space, sLogFile);
      End;
    End
    else if Assigned(sLogFile) then
        LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
          cs_CantGetProcAddress+c_DoubleDot+c_Space+c_Quotes+
          cs_BaseProcName+c_Quotes+c_Dot+c_Space+c_SystemSays+
          c_Space, sLogFile);
  End
  Else if Assigned(sLogFile) then
  Begin
    LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+
      cs_CantGetLibraryHandle+c_DoubleDot+c_Space+c_Quotes+
      cs_KernelLibFileName+c_Quotes+c_Dot+c_Space+c_SystemSays+
      c_Space, sLogFile);
  End;

//function GetModuleHandle(lpModuleName: PWideChar): HMODULE; stdcall;
End;
//RTL_OSVERSIONINFOEXW
{     VER_NT_WORKSTATION = $0000001;
      VER_NT_DOMAIN_CONTROLLER = $0000002;
      VER_NT_SERVER = $0000003;}

{ взято із http://www.codeproject.com/Articles/678606/Part-Overcoming-Windows-s-deprecation-of-GetVe?msg=5080848#xx5080848xx
// RTL_OSVERSIONINFOEXW is defined in winnt.h
BOOL GetOsVersion(RTL_OSVERSIONINFOEXW* pk_OsVer)}
{
    typedef LONG (WINAPI* tRtlGetVersion)(RTL_OSVERSIONINFOEXW*);

    memset(pk_OsVer, 0, sizeof(RTL_OSVERSIONINFOEXW));
    pk_OsVer->dwOSVersionInfoSize = sizeof(RTL_OSVERSIONINFOEXW);

    HMODULE h_NtDll = GetModuleHandleW(L"ntdll.dll");
    tRtlGetVersion f_RtlGetVersion = (tRtlGetVersion)GetProcAddress(h_NtDll, "RtlGetVersion");

    if (!f_RtlGetVersion)
        return FALSE; // This will never happen (all processes load ntdll.dll)

    LONG Status = f_RtlGetVersion(pk_OsVer);
    return Status == 0; // STATUS_SUCCESS;
}

{Function OpenRegKeyInObject(Const sRegistry:TRegistry; Const sKey:String;
   Const sLogFile:TLogFile):Boolean;
const cs_ProcName = 'OpenRegKeyInObject';
Begin
  Result:= sRegistry.OpenKey(sKey, True);
  If Not(Result) then
  Begin
    LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+cs_CantOpenRegKey+
      c_Space+c_Quotes+sKey+c_Quotes+c_Space+c_SystemSays+c_Space,
        sLogFile);
  End
  Else
  Begin

  End;
End;

Function WriteRegValue(Const sRegistry:TRegistry; Const sKey, sValueName:String;
           Const sValue:String; Const sLogFile:TLogFile):Boolean;
const cs_ProcName = 'WriteRegValueString';
Begin
  Result:= sRegistry.OpenKey(sKey, True);
  If Not(Result) then
  Begin
    LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+cs_CantOpenRegKey+
      c_Space+c_Quotes+sKey+c_Quotes+c_Space+c_SystemSays+c_Space,
        sLogFile);
  End
  Else
  Begin
    try
      sRegistry.WriteString(sValueName, sValue);
    except
      on E:ERegistryException do
      Begin
        LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+cs_CantWriteRegValue+
          c_Space+c_Quotes+sValueName+c_Quotes+c_Equal+
            c_Quotes+sValue+c_Quotes+c_Space+
            c_ObjectSays+c_Space+c_Quotes+E.Message+c_Quotes+
            c_Space+c_SystemSays+c_Space,
          sLogFile);
        Result:= False;
      End;
    end;
  End;
End;

Function ReadRegValue(Const sRegistry:TRegistry; Const sKey, sValueName:String;
           Var sValue:String; Const sLogFile:TLogFile):Boolean;
const cs_ProcName = 'ReadRegValueString';
Begin
  Result:= sRegistry.OpenKey(sKey, False);
  If Not(Result) then
  Begin
    LogLastOSError(cs_ProcName+c_DoubleDot+c_Space+cs_CantOpenRegKey+
      c_Space+c_Quotes+sKey+c_Quotes+c_Space+c_SystemSays+c_Space,
        sLogFile);
  End
  Else
  Begin

  End;
End;}

function MessageBoxTimeOut; external user32 name 'MessageBoxTimeoutW';
function MessageBoxTimeOutA; external user32 name 'MessageBoxTimeoutA';
function MessageBoxTimeOutW; external user32 name 'MessageBoxTimeoutW';

end.
