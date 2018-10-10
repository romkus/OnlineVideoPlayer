unit uBalloon;
(*
Образцы кода взяты из
Delphi Russian Knowledge Base
from Vit
Version 2.2

*)

interface
uses  { Какие библиотеки используем }
  Windows, ShellAPI, SysUtils, Classes, SyncObjs, Messages,// Dialogs,
    DataHelper, OSFuncHelper;

const
    cs_CantCreateObject = 'Не вдалося створити об''єкт';
    cs_CantSetEvent = 'Не вдалося встановити сигнал';
    cs_CantResetEvent = 'Не вдалося вимкнути сигнал';
    cs_CantCloseObject = 'Не вдалося закрити об''єкт';
    cs_OfTerminateTBaloonMessengerEvent =
      ' події завершення роботи TBaloonMessenger... ';
    cs_OfNewBaloonMessageEvent =
      ' події надходження повідомлення на відображення у треї... ';

    cs_OfChangeIconStateCommand =
      ' команди змінити стан значка у треї... ';

    cs_FailedToAddTaskbarIcon = ': не вдалося додати значок у трей...';
    cs_FailedToChangeTaskbarIcon = ': не вдалося змінити значок у треї...';
    cs_FailedToRemoveTaskbarIcon = ': не вдалося прибрати значок із трея...';
    cs_FailedToShowBalloon = ': не вдалося показати кульку з повідомленням...';

    cs_WaitForCommand = 'Очікування на команду';
    cs_WaitForCommandBetweenBalloons = cs_WaitForCommand+
      ' між відображеннями кульок';
    cs_ReturnedUnknownResult = ' повернуло невідомий результат: ';

    cs_CallingBalloonEventException =
      'при виклику обробника події відображення кульки виникло виключення';
    cs_FromMessagesThread = '(із потока повідомлень)';
    cs_WhenSynchronizedWithMain = '(синхронізованого з головним)';

    //cs_OfIconRemoveCommand =
    //  ' команди прибрати значок у треї... ';

    ci_ShowTimeAddition = 2000; // мс. Постійна частина часу відображення кульки
      // Типова кількість мілісекунд відображення повідомлення на один його
      // символ:
    ci_DefMillisecondsPerSymbol = 100;
type
  TBalloonTimeout = 10..30{seconds};
  TBalloonIconType = (bitNone,    // нет иконки
                      bitInfo,    // информационная иконка (синяя)
                      bitWarning, // иконка восклицания (жёлтая)
                      bitError,   // иконка ошибки (краснаа)
                      bitNotSet); // иконка не определена
  PBalloonIconType = ^TBalloonIconType;

  TBalloonIconAndMessageBoxType = record
    BalloonIconType: TBalloonIconType;
    MessageBoxType: DWord;
  End;
  PBalloonIconAndMessageBoxType = ^TBalloonIconAndMessageBoxType;

  TBaloonMessenger = class;

  TOnBalloonProc = procedure(Sender:TBaloonMessenger;
    Const sBalloonMessageShown, sBalloonTitleShown:String;
    Const sMessageQueue:TStrings) of object;

  TBaloonHider = class(TThread)
    private
      //cHideThis: Boolean;

      cWindow: HWND;
      cIconID: Byte;
      cPauseBeforeHide: DWORD;

      cBalloonCriticalSection: TCriticalSection;
    protected
      procedure Execute; override;
    public
      property PauseBeforeHide: DWORD read cPauseBeforeHide
        write cPauseBeforeHide;
      Constructor Create(CreateSuspended: Boolean; const Window: HWND;
        const IconID: Byte; sPauseBeforeHide:DWORD;
        sBalloonCriticalSection:TCriticalSection);
  end;

  TBaloonIconTypesList = class(Classes.TList)
    protected
      procedure Notify(Ptr: Pointer; Action: TListNotification); override;

      function Get(Index: Integer): TBalloonIconAndMessageBoxType;
      procedure Put(Index: Integer; Const Item: TBalloonIconAndMessageBoxType);
    public
        function Add(Const Item: TBalloonIconAndMessageBoxType): Integer;
        procedure Clear; override;
        procedure Delete(Index: Integer);
        function Remove(Item: TBalloonIconAndMessageBoxType): Integer;
        function Extract(Const Item: TBalloonIconAndMessageBoxType): TBalloonIconAndMessageBoxType;
        function ExtractByNum(Index: Integer): TBalloonIconAndMessageBoxType;
        function First: TBalloonIconAndMessageBoxType;
        function ExtractFirst: TBalloonIconAndMessageBoxType;
        procedure Insert(Index: Integer; Const Item: TBalloonIconAndMessageBoxType);
        function Last: TBalloonIconAndMessageBoxType;
        function ExtractLast: TBalloonIconAndMessageBoxType;
             // Виконує пошук у списку... знаходить перший елемент, що
             // рівний поданому значенню:
        function IndexOf(Const Item: TBalloonIconAndMessageBoxType): Integer;

        property Items[Index: Integer]: TBalloonIconAndMessageBoxType read Get write Put; default;
  end;

  TBaloonMessenger = class(TThread)
    private
      //cHideThis: Boolean;
        // Власне вікно потока.
        // Використовується для MessageBox як батьківське,
        // і отримує повідомлення про події значка:
      FWnd:HWND;
        // Вікно, якому перенадсилаються повідомлення про події значка трея:
      cWindow: HWND; //, cNewWindow
      cuCallbackMessage, cNewuCallbackMessage:UInt;
      cIconID, cNewIconID: Byte;
      chIcon: HICON; //, cNewhIcon
      cDefPauseBeforeHide:DWord;//, cPauseBeforeNext: DWORD;
      cNoSystemBalloonSound: Boolean;

      cBalloonCriticalSection, cCallingEventProcSection: TCriticalSection;

      cBaloonMessageQueue, cBalloonTitleQueue: TStrings;
      cBaloonIconQueue:TBaloonIconTypesList;
      cShowPauseQueue: TUIntList;
        // Спливаючий підпис значка в треї.
        // Не має черги. Змінюється потоком відразу при виклику команди
        // ShowTrayIcon (ProcShowTrayIcon):
      cHint: String;


      cHideIconOnLastMessageShown:Boolean;

      cTerminateEvent, // cMessageQueuedEvent,
        cChangeIconStateCommand: THandle;

      cLogFile:TLogFile;

      cIconVisible, cToShowIcon:Boolean;

      //cLastMessage: String;

      cRaiseExceptions:Boolean;
        // Обробники подій:
      cEvtAfterBalloon,
          //   cBalloonEvtToCall використовується щоб запам'ятати обробник що треба
          // викликати на час коли потік вийде із критичної серкції
          // охорони своїх даних (cBalloonCriticalSection) і зайде
          // у секцію охорони даних виклику обробника (cCallingEventProcSection).
          // В цей час головний потік може затерти cEvtAfterBalloon чи інші
          // обробники іншими значеннями доки цей потік чекатиме
          // поки головний потік виконає свою поточну роботу:
        cBalloonEvtToCall:
         TOnBalloonProc;
        // Режим виклику із потока обробників подій:
      cSynchronizeEvents: Boolean;

      cCurMessage, cCurTitle: String;

      Procedure SetHostingWindow(Value: HWND);
      Procedure SetCallbackMessage(Value: UInt);
      Procedure SetIconID(Value: Byte);
      Procedure SetIcon(Value: HICON);
      Procedure SetNoSystemBalloonSound(Value: Boolean);

      Procedure SetIconHint(Value: String);

      Procedure SetDefPauseBeforeHide(Value: DWORD);
      //Procedure SetPauseBeforeNext(Value: DWORD);
      Procedure SetHideIconOnLastMessageShown(Value: Boolean);

      Procedure SetAfterBalloon(Value: TOnBalloonProc);
      Procedure SetSynchronizeEvents(Value: Boolean);

      Function AddTrayIcon(const Hint: String = ''):Boolean;
      Function ChangeTrayIcon(const Hint: String = ''):Boolean;
      Function RemoveTrayIcon:Boolean;
      Function ProcShowBalloon(const BalloonText,
        BalloonTitle: String; const BalloonIconType: TBalloonIconType;
        sPauseBeforeHide:Cardinal; sNoSystemSound:Boolean):Boolean;
          // Рекурсивна процедура додавання повідомлення в чергу із
          // поділом його на частини що можна відобразити:
      Procedure ProcAddMessageToQueue(const BalloonText,
        BalloonTitle: String;
        const BalloonIconType: TBalloonIconType; Const sMessageBoxType: DWORD;
        sPauseBeforeHide:Cardinal);

      function CheckSelfExitCode:DWord;

      Procedure CallAfterBalloonShow(Const sMessage, sTitle: String;
           Const sBaloonMessageQueue:TStrings);
         //   Викликається синхронізованою із головним потоком
         // коли cSynchronizeEvents = True:
      Procedure SynchronizedCallBalloonEventProc;
    protected
      procedure Execute; override;

      procedure WindowProc(var sMessage: Messages.TMessage);
      Procedure ProcessMessages;

        // Процедури, що посилають команди потокові:
      procedure ProcHideTrayIcon;
      procedure ProcShowTrayIcon(const Hint: String = '');
      procedure ProcQueueBalloon(const BalloonText,
        BalloonTitle: String;
        const BalloonIconType: TBalloonIconType; Const sMessageBoxType: DWORD;
        sPauseBeforeHide: Cardinal = 0);
    public
      property Window: HWND read cWindow write SetHostingWindow;
      property SelfWindow: HWND read FWnd;
      property IconID: Byte read cIconID write SetIconID;
      property hIcon: HICON read chIcon write SetIcon;
      property uCallbackMessage: UInt read cuCallbackMessage
        write SetCallbackMessage;

          //   NoSystemBalloonSound = True вимикає системний звук відображення
          // кульки із повідомленням.
          //   Правда, для Windows Vista і вище (по Windows 8.1 принаймні)
          // існує баг, і системний звук
          // НЕ відтворюєтсья ніколи поки вручну не записати відомості
          // про медіафайл у потрібному розділі реєстру:
          // Windows Registry Editor Version 5.00
          // [HKEY_CURRENT_USER\AppEvents\Schemes\Apps\Explorer\SystemNotification\.current]
          // @="C:\\Windows\\Media\\Windows Balloon.wav"
          // Про це писали тут...:
          // http://winaero.com/blog/fix-windows-plays-no-sound-for-tray-balloon-tips-notifications/
          //   Якщо ж система налаштована вірно щоб відтворювати цей звук
          // то при NoSystemBalloonSound = False вона відтворюватиме:
      property NoSystemBalloonSound: Boolean read cNoSystemBalloonSound
        write SetNoSystemBalloonSound;

      property IconHint: String read cHint write SetIconHint;

      property DefPauseBeforeHide: DWORD read cDefPauseBeforeHide
        write SetDefPauseBeforeHide;
      //property PauseBeforeNext: DWord read cPauseBeforeNext
      //  write SetPauseBeforeNext;
          //   Чи прибирати значок у треї після відображення останнього
          // повідомлення з черги:
      property HideIconOnLastMessageShown:Boolean read
        cHideIconOnLastMessageShown write
        SetHideIconOnLastMessageShown;
          //   Чи піднімати виключення коли не вдається записати
          // повідомлення про помилку у cLogFile:
      property RaiseExceptions:Boolean read cRaiseExceptions
        write cRaiseExceptions;

      property IconVisible: Boolean read cIconVisible;
         //   Обробники подій відображення повідомлень.
         // Викликаються із цього потока відображення повідомлень у кульках.
         // У разі SynchronizeEvents = True їх виклик синхронізується із
         // головним потоком програми, інакше викликається без синхронізації
         // в контексті критичної секції використання даних потоком.
         //   Обробник не повинен займати надто багато часу так як він
         // виконується разом із відображенням повідомлень:
      property AfterBalloon: TOnBalloonProc read cEvtAfterBalloon
        write SetAfterBalloon;
         //   Режим виклику із потока обробників подій.
         //   У разі SynchronizeEvents = True їх виклик синхронізується із
         // головним потоком програми. В цьому режимі можна звертатися до
         // будь-яких даних головного потока програми. Проте перед викликом
         // потік відображення кульок чекає доки потік головної програми
         // буде не занйятий.
         //   При SynchronizeEvents = False викликається без синхронізації
         // в контексті критичної секції використання даних потоком.
         // Головний потік може бути зайнятий іншою роботою. В цей час обробник
         // може виконувати потрібні йому дії, проте використовувати дані
         // головного потока має з думкою про те що він таким чином втручається
         // в роботу головного потока і може поламати її якщо змінюватиме дані,
         // або розгубитися сам якщо дані неочікувано змінить головний потік.
         // Тобто для доступу до даних головного потока може бути потрібна
         // додаткова синхонізація (наприклад додаткові критичні секції)...:
      property SynchronizeEvents: Boolean read cSynchronizeEvents
        write SetSynchronizeEvents;

        //   Показує значок в треї із спливаючим поясненням,
        // якщо він ще не показаний.
        // Інакше тільки міняє пояснення:
      Procedure ShowTrayIcon(const Hint: String = '');

        //   Додає повідомлення в чергу на відображення.
        //   Якщо повідомлень у черзі немає то повідомлення відображається
        // відразу.
        //   Якщо довжина повідомлення p_Message завелика щоб показати його
        // у кульці трея то ділить повідомлення на декілька і додає їх у чергу.
        // При цьому повідомлення ділиться по рядкам. Якщо один рядок
        // всеодно задовгий то він ділиться по словам по пробілам. Якщо
        // слово надто довге то ділить його за максимальною довжиною що можна
        // вмістити.
        //   Якщо sPauseBeforeHide не рівна нулю то змінює час відображення
        // кульки PauseBeforeHide (у мілісекундах) після відображення
        // останнього повідомлення.
        //   Якщо значок у треї не відображається (не було
        // виклику ShowIcon), то показує його із спливаючою підказкою
        // p_Header.
        //   Якщо HideIconOnLastMessageShown=True то після відображення
        // всіх повідомлень автоматично прибирає значок (без виклику
        // HideIcon).
        //   BalloonIconType - тип значка в повідомленні-кульці.
        // Якщо не задана (рівна bitNotSet) то визначається за sMessageBoxType.
        // Якщо sMessageBoxType теж не задано то приймається як bitInfo;
        //   sMessageBoxType - тип кнопок, значка і параметри вікна
        // MessageBox, яке може бути відображено замість кульки якщо кульку
        // не вдасться показати. Якщо не задано то визначається
        // за BalloonIconType.
      procedure ShowBalloon(p_Message, p_Header: String;
        sPauseBeforeHide: Integer = 0;
        BalloonIconType: TBalloonIconType = bitNotSet;
        sMessageBoxType: DWORD = High(DWORD));
          //   Прибирає значок із трея. Якщо у черзі ще є
          // непоказані повідомлення то значок не прибирається
          // доки всі вони не будуть показані. Якщо протягом цього часу
          // буде викликано ShowIcon то значок не буде прибраний і
          // після показу всіх повідомлень (тобто цей виклик не матиме тоді
          // ефекту):
      Procedure HideTrayIcon;

        //   Якщо вказано sLogFile то об'єкт буде записувати у цей файл
        // повідомлення про виключення і копії повідомлень, що
        // відображаються.
        //   Вказаний sLogFile має існувати доки існує цей об'єкт...:
      Constructor Create(CreateSuspended: Boolean;
        sFreeOnTerminate: Boolean;
        const Window: HWND;
        const IconID: Byte; sDefPauseBeforeHide:DWORD;
        sLogFile:TLogFile = Nil;
        suCallbackMessage:UInt = 0);
      destructor Destroy; override;
      procedure Terminate; virtual; // override; тут, на жаль, не можна override, бо у TThread Terminate не є віртуальною...

      procedure LogMessage(sMessage:String; sThisIsAnError:Boolean = False);
      procedure LogLastOSError(sCommentToError:String); overload;
      procedure LogLastOSError(sCommentToError:String; LastError: Integer); overload;
         // Не робить нічого якщо викликається не із потока цього
         // об'єкта і потік ще не завершений. Інакше - ховає значок...:
      Procedure CleanUpAfterWork;

      Class Function ConvertBalloonIconTypeToMessageBoxWithOkButtonType(
        BalloonIconType:TBalloonIconType):DWORD; static;
      Class Function ConvertMessageBoxTypeToBalloonIconType(suType:DWORD):
        TBalloonIconType; static;
  end;

function DZAddTrayIcon(const Window: HWND; const IconID: Byte;
  const Icon: HICON; const Hint: String = '';
  const suCallbackMessage:UInt = 0): Boolean;
function DZChangeTrayIcon(const Window: HWND; const IconID: Byte;
  const Icon: HICON; const Hint: String = ''): Boolean;
function DZRemoveTrayIcon(const Window: HWND; const IconID: Byte): Boolean;

function DZBalloonTrayIcon(const Window: HWND;
  const IconID: Byte; const Timeout: TBalloonTimeout;
  const BalloonText, BalloonTitle: String;
  const BalloonIconType: TBalloonIconType;
  sNoSystemSound:Boolean = False): Boolean; overload;

function DZBalloonTrayIcon(const Window: HWND; const IconID: Byte;
  const Timeout: UINT;
  const BalloonText, BalloonTitle: String;
  const BalloonIconType: TBalloonIconType;
  sNoSystemSound:Boolean = False): Boolean; overload;



implementation

const
  NIF_INFO      =        $00000010;

  NIIF_NONE     =        $00000000;
  NIIF_INFO     =        $00000001;
  NIIF_WARNING  =        $00000002;
  NIIF_ERROR    =        $00000003;
  NIIF_NOSOUND  =        $00000010;

  aBalloonIconTypes : array[TBalloonIconType] of Byte = (NIIF_NONE, NIIF_INFO,
    NIIF_WARNING, NIIF_ERROR,
    NIIF_NONE);  // якщо bitNotSet то не показується значок (NIIF_NONE)

  Var
    ci_MaxTrayTipLen, ci_MaxTrayBaloonInfoLen, ci_MaxTrayBaloonTitleLen:
      Integer;


{type
  NotifyIconData_50 = record // определённая в shellapi.h
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array[0..MAXCHAR] of AnsiChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array[0..MAXBYTE] of AnsiChar;
    uTimeout: UINT; // union with uVersion: UINT;
    szInfoTitle: array[0..63] of AnsiChar;
    dwInfoFlags: DWORD;
  end; //record}

///////////////////////////////////////////////////////////////////////
{добавление иконки }
//Взято с Исходников.ru http://www.sources.ru
function DZAddTrayIcon(const Window: HWND; const IconID: Byte;
  const Icon: HICON; const Hint: String = '';
  const suCallbackMessage:UInt = 0): Boolean;
var
  NID : NotifyIconData;
begin
  FillChar(NID, SizeOf(NotifyIconData), 0);
  with NID do begin
    cbSize := SizeOf(NotifyIconData);
    Wnd := Window;
    uID := IconID;

    if Hint = '' then begin
      uFlags := NIF_ICON;
    end{if} else begin
      uFlags := NIF_ICON or NIF_TIP;
      //StrPCopy(szTip, Hint);
      //StrCopy(szTip, PChar(Hint));
      StrLCopy(szTip, PChar(Hint), SizeOf(szTip) - 1);
    end{else};

    if suCallbackMessage <> 0 then
    Begin
      uCallbackMessage:= suCallbackMessage;
      uFlags:= uFlags or NIF_MESSAGE;
    End;
    hIcon := Icon;
  end{with};
  Result := Shell_NotifyIcon(NIM_ADD, @NID);
end;

function DZChangeTrayIcon(const Window: HWND; const IconID: Byte;
  const Icon: HICON; const Hint: String = ''): Boolean;
var
  NID : NotifyIconData;
begin
  FillChar(NID, SizeOf(NotifyIconData), 0);
  with NID do begin
    cbSize := SizeOf(NotifyIconData);
    Wnd := Window;
    uID := IconID;
    if Hint = '' then begin
      uFlags := NIF_ICON;
    end{if} else
    begin
      uFlags := NIF_ICON or NIF_TIP;
      StrLCopy(szTip, PChar(Hint), SizeOf(szTip) - 1);
    end{else};
    hIcon := Icon;
  end{with};
  Result := Shell_NotifyIcon(NIM_MODIFY, @NID);
end;

///////////////////////////////////////////////////////////////////////
{удаляет иконку}
//Взято с Исходников.ru http://www.sources.ru

function DZRemoveTrayIcon(const Window: HWND; const IconID: Byte): Boolean;
var
  NID : NotifyIconData;
begin
  FillChar(NID, SizeOf(NotifyIconData), 0);
  with NID do begin
    cbSize := SizeOf(NotifyIconData);
    Wnd := Window;
    uID := IconID;
  end{with};
  Result := Shell_NotifyIcon(NIM_DELETE, @NID);
end;

///////////////////////////////////////////////////////////////////////
{Показывает баллон}
//Взято с Исходников.ru http://www.sources.ru



///////////////////////////////////////////////////////////////////////
function DZBalloonTrayIcon(const Window: HWND;
  const IconID: Byte; const Timeout: TBalloonTimeout;
  const BalloonText, BalloonTitle: String;
  const BalloonIconType: TBalloonIconType;
  sNoSystemSound:Boolean): Boolean;
//const
//  aBalloonIconTypes : array[TBalloonIconType] of Byte = (NIIF_NONE, NIIF_INFO, NIIF_WARNING, NIIF_ERROR);
//var
//  NID_50 : NotifyIconData; //NotifyIconData_50;
begin
  Result:= DZBalloonTrayIcon(Window, IconID, UINT(Timeout*1000),
    BalloonText, BalloonTitle,
    BalloonIconType, sNoSystemSound);
end;

function DZBalloonTrayIcon(const Window: HWND; const IconID: Byte;
  const Timeout: UINT;
  const BalloonText, BalloonTitle: String;
  const BalloonIconType: TBalloonIconType;
  sNoSystemSound:Boolean): Boolean;
var
  NID_50 : NotifyIconData; //NotifyIconData_50;
  ccdwInfoFlags:DWord;
begin
  //FillChar(NID_50, SizeOf(NotifyIconData_50), 0);
  FillChar(NID_50, SizeOf(NotifyIconData), 0);
  with NID_50 do begin
    //cbSize := SizeOf(NotifyIconData_50);
    cbSize := SizeOf(NotifyIconData);
    Wnd := Window;
    uID := IconID;
    uFlags := NIF_INFO;
    //StrPCopy(szInfo, AnsiString(BalloonText));
    //StrCopy(szInfo, PChar(BalloonText));
    StrLCopy(szInfo, PChar(BalloonText), SizeOf(szInfo) - 1);
    uTimeout := Timeout;
    //StrPCopy(szInfoTitle, AnsiString(BalloonTitle));
    //StrCopy(szInfoTitle, PChar(BalloonTitle));
    StrLCopy(szInfoTitle, PChar(BalloonTitle), SizeOf(szInfoTitle) - 1);
    ccdwInfoFlags:= aBalloonIconTypes[BalloonIconType];
    if sNoSystemSound then
      ccdwInfoFlags:= ccdwInfoFlags or NIIF_NOSOUND;
    dwInfoFlags := ccdwInfoFlags;
  end{with};
  Result := Shell_NotifyIcon(NIM_MODIFY, @NID_50);
end;



Constructor TBaloonHider.Create(CreateSuspended: Boolean; const Window: HWND;
        const IconID: Byte; sPauseBeforeHide:DWORD;
        sBalloonCriticalSection:TCriticalSection);
Begin
  Inherited Create(True);

  Self.cWindow:= Window;
  Self.cIconID:= IconID;
  Self.cPauseBeforeHide:= sPauseBeforeHide;

  Self.cBalloonCriticalSection:= sBalloonCriticalSection;

  Self.FreeOnTerminate:= True; // звільняти об'єкт не будемо, хай сам..

  if Not(CreateSuspended) then Self.Resume;
End;

procedure TBaloonHider.Execute;
Begin
  if Not(Self.Terminated) then
  Begin
    Windows.Sleep(Self.cPauseBeforeHide);

    Self.cBalloonCriticalSection.Enter;
    try
      DZRemoveTrayIcon(Self.cWindow, Self.cIconID);
    finally
      Self.cBalloonCriticalSection.Leave;
    end;
  End;
End;

{Хотів зробити щоб кулька не ховалася швидко якщо в ній з'явився новий текст.. але тоді треба слідкувати за важелем вікна, чи воно не змінилося, чи не з'явилася нова кулька...
procedure TBaloonHider.Execute;
Var cCurPause: DWord;
Begin
  While Not(Self.Terminated) do
  Begin
    if Not(Self.cHideThis) then
    Begin
      Self.Suspend;
      Continue;
    End;

    Self.cBalloonCriticalSection.Enter;
    try
      cCurPause:= Self.cPauseBeforeHide;
      Self.cPauseBeforeHide:= 0; // скидаємо ту паузу, яку виконаємо

      Self.cHideThis:= False;  // скидаємо команду "зховати кульку тексту", бо її виконаємо
    finally
      Self.cBalloonCriticalSection.Leave;
    end;

    Windows.Sleep(cCurPause);
      // Якщо за час паузи знову прийшла команда зховати повідомлення після паузи
      // (і задана нова пауза) - то не ховаємо повідомлення, чекаємо ще той час який задали:
    if Self.cHideThis then Continue;

    Self.cBalloonCriticalSection.Enter;
    try
      DZRemoveTrayIcon(Self.cWindow, Self.cIconID);
    finally
      Self.cBalloonCriticalSection.Leave;
    end;
  End;
End;}


Constructor TBaloonMessenger.Create(CreateSuspended: Boolean;
        sFreeOnTerminate: Boolean;
        const Window: HWND;
        const IconID: Byte; sDefPauseBeforeHide:DWORD;
        sLogFile:TLogFile = Nil;
        suCallbackMessage:UInt = 0);
Begin
  Inherited Create(True);

  Self.cLogFile:= sLogFile;
    // Своє вікно ще не створене, його створить потік коли буде запущений:
  Self.FWnd:= 0;

  Self.cWindow:= Window;
  //Self.cNewWindow:= Self.cWindow;
  Self.cuCallbackMessage:= suCallbackMessage;
  Self.cNewuCallbackMessage:= Self.cuCallbackMessage;

  Self.cIconID:= IconID;
  Self.cNewIconID:= Self.cIconID;

  Self.cDefPauseBeforeHide:= sDefPauseBeforeHide;
  //  // Типово пауза перед наступним повідомленням рівна паузі
  //  // перед хованням кульки:
  //Self.cPauseBeforeNext:= Self.cDefPauseBeforeHide;

    // Типове зображення для значка в треї:
  Self.chIcon:= Windows.LoadIcon(0, IDI_APPLICATION);
    //   Якщо на сповіщення у кульці встановлений системний звук то
    // типово він відтворюється.
    // Правда, для Windows Vista і вище (по Windows 8.1 принаймні) існує баг,
    // і системний звук
    // не відтворюєтсья поки вручну не записати відомості про медіафайл
    // у потрібному розділі реєстру:
    // Windows Registry Editor Version 5.00
    // [HKEY_CURRENT_USER\AppEvents\Schemes\Apps\Explorer\SystemNotification\.current]
    // @="C:\\Windows\\Media\\Windows Balloon.wav"
    // Про це писали тут...:
    // http://winaero.com/blog/fix-windows-plays-no-sound-for-tray-balloon-tips-notifications/
    //   Проте якщо система може відтворювати звук, то типово вона відтворює:
  Self.cNoSystemBalloonSound:= False;

  //Self.cNewhIcon:= Self.chIcon;

  Self.cBalloonCriticalSection:= TCriticalSection.Create;
  Self.cCallingEventProcSection:= TCriticalSection.Create;
    // Черга повідомлень для відображення.
    // Якщо в ній накопичується більше одного повідомлення то
    // всі вони відображаються через паузу   :
  Self.cBaloonMessageQueue:= TStringList.Create;
    // частина черги - черга заголовків повідомлень:
  Self.cBalloonTitleQueue:= TStringList.Create;
  Self.cBaloonIconQueue:= TBaloonIconTypesList.Create;
  Self.cShowPauseQueue:= TUIntList.Create;
    // Вмикає прибирання значка із трея після відображення
    // усіх повідомлень із черги. Тоді при надходженні нових
    // повідомлень значок знову додається.
    // При завершенні роботи цього об'єкта значок прибирається
    // незалежно від цього параметра:
  Self.cHideIconOnLastMessageShown:= True;


    // Цей об'єкт готовий приймати на відображення і відображати
    // повідомлення в Baloon доки його не звільнять.
    // Тому сам не звільняється навіть якщо потік
    // закінчить роботу через якусь неочікувану ситуацію:
  Self.FreeOnTerminate:= sFreeOnTerminate;

  Self.cTerminateEvent:= OsFuncHelper.ProcCreateEvent(
   cs_CantCreateObject+cs_OfTerminateTBaloonMessengerEvent
      + c_SystemSays,
   True,   // після виникнення скидається вручну
   False,  // спочатку подія не відбувалася
   Nil,    // подія не має імені (воно не треба, бо інші процеси цю подію не використовують і її важіль не успадковують)
   Self.cLogFile);

  {Self.cMessageQueuedEvent:= OsFuncHelper.ProcCreateEvent(
   cs_CantCreateObject+cs_OfNewBaloonMessageEvent
      + c_SystemSays,
   True,   // після виникнення скидається вручну
   False,  // спочатку подія не відбувалася
   Nil,    // подія не має імені (воно не треба, бо інші процеси цю подію не використовують і її важіль не успадковують)
   Self.cLogFile);}

  Self.cChangeIconStateCommand:= OsFuncHelper.ProcCreateEvent(
   cs_CantCreateObject+cs_OfChangeIconStateCommand
      + c_SystemSays,
   True,   // після виникнення скидається вручну
   False,  // спочатку подія не відбувалася
   Nil,    // подія не має імені (воно не треба, бо інші процеси цю подію не використовують і її важіль не успадковують)
   Self.cLogFile);

     // Вважаємо що спочатку немає значка...:
  Self.cIconVisible:= False;
  Self.cToShowIcon:= False; // команди показати значок ще не було

     // Обробники подій спочатку не задані:
  Self.cEvtAfterBalloon:= Nil;
  Self.cBalloonEvtToCall:= Nil;

  cCurMessage:= '';
  cCurTitle:= '';

  if Not(CreateSuspended) then Self.Resume;
End;

procedure TBaloonMessenger.Terminate;
Begin
    // Спочатку встановлюємо помітку про те що треба завершувати роботу:
  Inherited Terminate;
    // А потім уже подаємо про те сигнал:
    // Встановлюємо сигнал про те що треба завершити процедуру (потік):
  OSFuncHelper.ProcSetEvent(Self.cTerminateEvent,
     cs_CantSetEvent+cs_OfTerminateTBaloonMessengerEvent +
       c_SystemSays,
    Self.cLogFile);
End;

destructor TBaloonMessenger.Destroy;
var cc_ThreadExitCode:DWord;
Begin
  cc_ThreadExitCode:= Self.CheckSelfExitCode;
    // Чекаємо завершення потока тільки якщо він ще дійсно
    // працює (не завершився і його ніхто не перервав...):
  if cc_ThreadExitCode = STILL_ACTIVE then
  Begin
    if Not(Self.Finished) then
    Begin
      Self.Terminate;
      while Self.Suspended and (cc_ThreadExitCode = STILL_ACTIVE) do
      Begin
        Self.Resume;
        cc_ThreadExitCode:= Self.CheckSelfExitCode;
      End;

      if cc_ThreadExitCode = STILL_ACTIVE then
        Self.WaitFor;
    //  if Not(Self.Finished) then
    //    Windows.Sleep(c_EmergencySleepTime);
    End;
  End;

  Self.cEvtAfterBalloon:= Nil;
  Self.cBalloonEvtToCall:= Nil;

  {OSFuncHelper.ProcCloseHandle(Self.cMessageQueuedEvent,
    cs_CantCloseObject+cs_OfNewBaloonMessageEvent +
       c_SystemSays,
     Self.cLogFile);}

  OSFuncHelper.ProcCloseHandle(Self.cTerminateEvent,
    cs_CantCloseObject+cs_OfTerminateTBaloonMessengerEvent +
       c_SystemSays,
     Self.cLogFile);

  OSFuncHelper.ProcCloseHandle(Self.cChangeIconStateCommand,
    cs_CantCloseObject+cs_OfChangeIconStateCommand +
       c_SystemSays,
     Self.cLogFile);

  SysUtils.FreeAndNil(Self.cBaloonMessageQueue);
  SysUtils.FreeAndNil(Self.cBalloonTitleQueue);
  SysUtils.FreeAndNil(Self.cBaloonIconQueue);
  SysUtils.FreeAndNil(Self.cShowPauseQueue);
  SysUtils.FreeAndNil(Self.cCallingEventProcSection);
  SysUtils.FreeAndNil(Self.cBalloonCriticalSection);

  Inherited Destroy;
End;

procedure TBaloonMessenger.LogLastOSError(sCommentToError:String);
var ccDoIt:Boolean;
Begin
  ccDoIt:= Self.cRaiseExceptions;
  if System.Assigned(Self.cLogFile) then
  Begin
    if Self.cLogFile.Opened then ccDoIt:= True;
  End;

  if ccDoIt then
    OSFuncHelper.LogLastOsError(sCommentToError, Self.cLogFile);
End;

procedure TBaloonMessenger.LogMessage(sMessage:String;
            sThisIsAnError:Boolean = False);
var ccDoIt:Boolean;
Begin
  ccDoIt:= Self.cRaiseExceptions and sThisIsAnError;
  if System.Assigned(Self.cLogFile) then
  Begin
    if Self.cLogFile.Opened or ccDoIt then
    Begin
      Self.cLogFile.WriteMessage(sMessage);
    End;
  End
  else if ccDoIt then
  Begin
    Raise Exception.Create(sMessage);
  End;
End;

procedure TBaloonMessenger.LogLastOSError(sCommentToError:String; LastError: Integer);
var ccDoIt:Boolean;
Begin
  ccDoIt:= Self.cRaiseExceptions;
  if System.Assigned(Self.cLogFile) then
  Begin
    if Self.cLogFile.Opened then ccDoIt:= True;
  End;

  if ccDoIt then
    OSFuncHelper.LogLastOsError(sCommentToError, LastError, Self.cLogFile);
End;

Function TBaloonMessenger.AddTrayIcon(const Hint: String = ''):Boolean;
const cs_ProcName = 'TBaloonMessenger.AddTrayIcon';
Begin
  Result:= DZAddTrayIcon(Self.FWnd, //Self.cNewWindow,
      Self.cNewIconID, Self.chIcon, Hint,
    Self.cNewuCallbackMessage);
  if Result then
  Begin
    //Self.cWindow:= Self.cNewWindow;
    Self.cIconID:= Self.cNewIconID;
    Self.cuCallbackMessage:= Self.cNewuCallbackMessage;
    Self.cIconVisible:= True;
  End
  Else Self.LogMessage(cs_ProcName + cs_FailedToAddTaskbarIcon, True);
End;
Function TBaloonMessenger.ChangeTrayIcon(const Hint: String = ''):Boolean;
const cs_ProcName = 'TBaloonMessenger.ChangeTrayIcon';
Begin
  Result:= DZChangeTrayIcon(Self.FWnd, Self.IconID, Self.chIcon, Hint);
  if Not(Result) then
  Begin
    Self.LogMessage(cs_ProcName + cs_FailedToChangeTaskbarIcon, True);
  End;
End;
Function TBaloonMessenger.RemoveTrayIcon:Boolean;
const cs_ProcName = 'TBaloonMessenger.RemoveTrayIcon';
Begin
  Result:= DZRemoveTrayIcon(Self.FWnd, Self.IconID);
    // Чи вдалося заховати значок чи ні - вважаємо що він не відображається, бо
    // якщо контролювати його не виходить то і робити з ним нічого не можливо
    // більше. І система швидше за все його прибрала вже, вона прибирає значки
    // чиї вікна вже не існують, коли над ними з'являється мишка:
  Self.cIconVisible:= False;

  if Not(Result) then
    Self.LogMessage(cs_ProcName + cs_FailedToRemoveTaskbarIcon, True);
End;
Function TBaloonMessenger.ProcShowBalloon(const BalloonText,
  BalloonTitle: String; const BalloonIconType: TBalloonIconType;
  sPauseBeforeHide:Cardinal; sNoSystemSound:Boolean):Boolean;
const cs_ProcName = 'TBaloonMessenger.ProcShowBalloon';
Begin
  Result:= DZBalloonTrayIcon(Self.FWnd, Self.IconID,
    sPauseBeforeHide, BalloonText, BalloonTitle,
    BalloonIconType, sNoSystemSound);

  if Not(Result) then
  Begin
    Self.LogMessage(cs_ProcName + cs_FailedToShowBalloon, True);
  End;
End;

        // Процедури, що посилають команди потокові:
procedure TBaloonMessenger.ProcHideTrayIcon;
const sc_ProcName='TBaloonMessenger.ProcHideTrayIcon: ';
Begin
  Self.cBalloonCriticalSection.Enter;
  try
    Self.cToShowIcon:= False; // треба приховати значок
  finally
    Self.cBalloonCriticalSection.Leave;
  end;

  OSFuncHelper.ProcSetEvent(Self.cChangeIconStateCommand,
     sc_ProcName + cs_CantSetEvent + cs_OfChangeIconStateCommand + c_SystemSays,
    Self.cLogFile);
  //Begin
    While Self.Suspended do Self.Resume;
  //End;
End;

Procedure TBaloonMessenger.HideTrayIcon;
Begin
  Self.ProcHideTrayIcon;
End;

procedure TBaloonMessenger.ProcShowTrayIcon(const Hint: String = '');
const sc_ProcName='TBaloonMessenger.ProcShowTrayIcon: ';
Begin
  //if (Self.IconHint<>Hint) then // це перевіряється у SetIconHint
  Self.cBalloonCriticalSection.Enter;
  try
    Self.IconHint:= Hint;
    Self.cToShowIcon:= True;  // треба показати значок
  finally
    Self.cBalloonCriticalSection.Leave;
  end;

  OSFuncHelper.ProcSetEvent(Self.cChangeIconStateCommand,
     sc_ProcName + cs_CantSetEvent + cs_OfChangeIconStateCommand + c_SystemSays,
    Self.cLogFile);
  While Self.Suspended do Self.Resume;
End;

Procedure TBaloonMessenger.ShowTrayIcon(const Hint: String = '');
Begin
  Self.ProcShowTrayIcon(Hint);
End;

procedure TBaloonMessenger.ProcQueueBalloon(const BalloonText,
        BalloonTitle: String;
        const BalloonIconType: TBalloonIconType; Const sMessageBoxType: DWORD;
        sPauseBeforeHide: Cardinal = 0);
const sc_ProcName='TBaloonMessenger.ProcQueueBalloon: ';
Begin
  Self.cBalloonCriticalSection.Enter;
  try
    Self.ProcAddMessageToQueue(BalloonText,
        BalloonTitle, BalloonIconType, sMessageBoxType,
        sPauseBeforeHide);
          // Щоб показати повідомлення треба створити значок.
          // Система може показувати його або приховувати,
          // та він має бути:
    Self.cToShowIcon:= True;
  finally
    Self.cBalloonCriticalSection.Leave;
  end;

  OSFuncHelper.ProcSetEvent(Self.cChangeIconStateCommand,
     sc_ProcName + cs_CantSetEvent + cs_OfChangeIconStateCommand + c_SystemSays,
    Self.cLogFile);
  While Self.Suspended do Self.Resume;
End;

Class Function TBaloonMessenger.ConvertBalloonIconTypeToMessageBoxWithOkButtonType(
        BalloonIconType:TBalloonIconType):DWORD;
Begin
  Result:= ci_DefOkMsgBoxType;  // MessageBox із кнопкою OK поверх всіх вікон
  case BalloonIconType of
    bitNone:; // без значка у вікні із повідомленням
    bitInfo: Result:= Result or MB_ICONINFORMATION;
    bitWarning: Result:= Result or  MB_ICONWARNING;
    bitError: Result:= Result or MB_ICONERROR;
    bitNotSet: ;
  end;
End;

Class Function TBaloonMessenger.ConvertMessageBoxTypeToBalloonIconType(suType:DWORD):
        TBalloonIconType;
Var ccMsgBoxIconType:DWORD;
Begin
  ccMsgBoxIconType:= suType and MB_AllMessageBoxIconsMask; //MB_AllMessageBoxButtonsMask
  case ccMsgBoxIconType of
    MB_ICONINFORMATION:Result:= bitInfo;
    MB_ICONERROR:Result:= bitError;
    MB_ICONWARNING:Result:= bitWarning;
    MB_ICONQUESTION:Result:= bitWarning;
    else
      Result:= bitNone;
  end;
End;

procedure TBaloonMessenger.ShowBalloon(p_Message, p_Header: String;
        sPauseBeforeHide: Integer = 0;
        BalloonIconType: TBalloonIconType = bitNotSet;
        sMessageBoxType: DWORD = High(DWORD));
Begin
  {if sPauseBeforeHide > 0 then
  Begin
    Self.PauseBeforeHide:= sPauseBeforeHide;
  End;}
    // Якщо sMessageBoxType не задано то:
  if sMessageBoxType = High(DWORD) then
  Begin
      //  Якщо BalloonIconType теж не задано:
    if BalloonIconType >= bitNotSet then
    Begin
      BalloonIconType:= bitInfo;
    End;
    sMessageBoxType:=
      Self.ConvertBalloonIconTypeToMessageBoxWithOkButtonType(BalloonIconType);
  End
  Else
  Begin
      //  Якщо BalloonIconType не задано:
    if BalloonIconType >= bitNotSet then
    Begin
      BalloonIconType:=
        Self.ConvertMessageBoxTypeToBalloonIconType(sMessageBoxType);
    End;
  End;

  Self.ProcQueueBalloon(p_Message, p_Header, BalloonIconType, sMessageBoxType,
    sPauseBeforeHide);
End;

Procedure TBaloonMessenger.SetHostingWindow(Value: HWND);
Begin
    //   Якщо вже командували поміняти вікно на вказане то
    // нічого робити не треба, потік це виконає:
  //if Self.cNewWindow = Value then Exit;
  if Self.cWindow = Value then Exit;


  Self.cBalloonCriticalSection.Enter;
  try
    //Self.cNewWindow:= Value;
    Self.cWindow:= Value;


    //  Потік використовує своє вікно для отримання повідомлень від значка,
    //тому тут показувати значок із новим вікном не треба.
    //Після виходу із секції cBalloonCriticalSection
    //процедура WindowProc буде пересилати повідомлення значка
    //новому вікну Self.cWindow.
    //  // Якщо на момент заміни вікна значок треба відображати
    //  // (і/або показувати повідомлення), то
    //  // командуємо прибрати значок із трея (від староно вікна)
    //  // і показати (від нового вікна), без очікування на виконання команди.
    //  // Якщо значок відображається то потік заховає його від старого вікна.
    //  // Далі покаже від нового:
    //if Self.cToShowIcon then
    //  Self.ProcShowTrayIcon(Self.IconHint);
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;

Procedure TBaloonMessenger.SetCallbackMessage(Value: UInt);
Begin
  if Self.cuCallbackMessage = Value then Exit;

  Self.cBalloonCriticalSection.Enter;
  try
    Self.cNewuCallbackMessage:= Value;

      // Якщо на момент заміни вікна значок треба відображати
      // (і/або показувати повідомлення), то
      // командуємо прибрати значок із трея (від староно вікна)
      // і показати (від нового вікна), без очікування на виконання команди.
      // Якщо значок відображається то потік заховає його і покаже
      // із новим номером повідомлення-відгуку:
    if Self.cToShowIcon then
      Self.ProcShowTrayIcon(Self.IconHint);
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;

Procedure TBaloonMessenger.SetIconID(Value: Byte);
Begin
    //   Якщо вже командували поміняти вікно на вказане то
    // нічого робити не треба, потік це виконає:
  if Self.cNewIconID = Value then Exit;

  Self.cBalloonCriticalSection.Enter;
  try
    Self.cNewIconID:= Value;

      // Командуємо прибрати старий значок із трея
      // і показати новий, без очікування на виконання команди:
      // Якщо значок відображається то потік заховає його.
      // Далі покаже з новим ідентифікатором (номером):
    if Self.cToShowIcon then
      Self.ProcShowTrayIcon(Self.IconHint);
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;

Procedure TBaloonMessenger.SetIcon(Value: HICON);
Begin
    //   Якщо цей значок вже заданий то нічого не командуємо:
  if Self.chIcon = Value then Exit;

  Self.cBalloonCriticalSection.Enter;
  try
    Self.chIcon:= Value;

        //  Командуємо показати значок із новими параметрами.
        //Якщо значок не відображається то потік запустить
        //DZAddTrayIcon. Якщо він уже відображається то потік запустить його
        //заміну (DZChangeTrayIcon).
    if Self.cToShowIcon then
      Self.ProcShowTrayIcon(Self.IconHint);
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;

Procedure TBaloonMessenger.SetNoSystemBalloonSound(Value: Boolean);
Begin
  if Self.cNoSystemBalloonSound = Value then Exit;
  Self.cBalloonCriticalSection.Enter;
  try
    Self.cNoSystemBalloonSound:= Value;
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;

Procedure TBaloonMessenger.SetIconHint(Value: String);
Begin
  if Self.cHint = Value then Exit;
  Self.cBalloonCriticalSection.Enter;
  try
    Self.cHint:= Value;

        //  Командуємо показати значок із новими параметрами.
        //Якщо значок не відображається то потік запустить
        //DZAddTrayIcon. Якщо він уже відображається то потік запустить його
        //правку (DZChangeTrayIcon).
    if Self.cToShowIcon then
      Self.ProcShowTrayIcon(Self.IconHint);
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;

Procedure TBaloonMessenger.SetDefPauseBeforeHide(Value: DWORD);
Begin
  if Self.cDefPauseBeforeHide = Value then Exit;
  Self.cBalloonCriticalSection.Enter;
  try
    Self.cDefPauseBeforeHide:= Value;
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;

Procedure TBaloonMessenger.SetAfterBalloon(Value: TOnBalloonProc);
Begin
  if Addr(Self.cEvtAfterBalloon) = Addr(Value) then Exit;
  Self.cBalloonCriticalSection.Enter;
  try
    Self.cEvtAfterBalloon:= Value;
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;
Procedure TBaloonMessenger.SetSynchronizeEvents(Value: Boolean);
Begin
  if Self.cSynchronizeEvents = Value then Exit;
  Self.cBalloonCriticalSection.Enter;
  try
    Self.cSynchronizeEvents:= Value;
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;

{Procedure TBaloonMessenger.SetPauseBeforeNext(Value: DWORD);
Begin
  if Self.cPauseBeforeNext = Value then Exit;
  Self.cBalloonCriticalSection.Enter;
  try
    Self.cPauseBeforeNext:= Value;
  finally
    Self.cBalloonCriticalSection.Leave;
  end;
End;}

Procedure TBaloonMessenger.SetHideIconOnLastMessageShown(Value: Boolean);
const sc_ProcName = 'TBaloonMessenger.SetHideIconOnLastMessageShown';
Begin
  if Self.cHideIconOnLastMessageShown = Value then Exit;
  Self.cBalloonCriticalSection.Enter;
  try
    Self.cHideIconOnLastMessageShown:= Value;
  finally
    Self.cBalloonCriticalSection.Leave;
  end;

    // Тільки якщо треба сховати значок після відображення повідомлень:
  if Value then
  Begin
      // Будимо потік щоб він сховав значок, якщо його треба сховати
      // після відображення повідомлень, і всі вони вже відображені:
    OSFuncHelper.ProcSetEvent(Self.cChangeIconStateCommand,
       sc_ProcName + cs_CantSetEvent + cs_OfChangeIconStateCommand + c_SystemSays,
      Self.cLogFile);
    While Self.Suspended do Self.Resume;
  End;
End;

Procedure TBaloonMessenger.SynchronizedCallBalloonEventProc;
const cs_ProcName = 'TBaloonMessenger.SynchronizedCallBalloonEventProc';
Begin
  try
    Self.cBalloonEvtToCall(Self, Self.cCurMessage, Self.cCurTitle,
      Self.cBaloonMessageQueue);
  except
    on E:Exception do
    Begin
      Self.LogMessage(cs_ProcName + c_DoubleDot + c_Space +
                cs_CallingBalloonEventException+  c_Space+
                cs_WhenSynchronizedWithMain + c_DoubleDot + c_Space+
                E.Message, True);
    End;
  end;
End;

  //   Викликається із потока відображення повідомлень після відображення
  // повідомлення (при відображенні у кульці - відразу після відображення
  // кульки; якщо кульку неможливо показати то після відображення і
  // закривання вікна з повідомленням MessageBox):
Procedure TBaloonMessenger.CallAfterBalloonShow(Const sMessage, sTitle: String;
           Const sBaloonMessageQueue:TStrings);
const cs_ProcName = 'TBaloonMessenger.CallAfterBalloonShow';
Var ccSynchronizeEvents: Boolean;
    ccAfterBalloonShow: TOnBalloonProc;
Begin
 ccSynchronizeEvents:= Self.cSynchronizeEvents;
 ccAfterBalloonShow:= Self.cEvtAfterBalloon;

 if System.Assigned(ccAfterBalloonShow) then
 Begin
   if ccSynchronizeEvents then
   Begin
     Self.cBalloonCriticalSection.Leave;
     try
       Self.cCallingEventProcSection.Enter;
       try
         Self.cBalloonEvtToCall:= ccAfterBalloonShow;
         Self.cCurMessage:= sMessage;
         Self.cCurTitle:= sTitle;

         Self.Synchronize(Self.SynchronizedCallBalloonEventProc);
       finally
         Self.cCallingEventProcSection.Leave;
       end;
     finally
       Self.cBalloonCriticalSection.Enter;
     end;
   End
   Else  // якщо не треба синхронізувати із головним потоком:
   Begin
     try
       ccAfterBalloonShow(Self, sMessage, sTItle, Self.cBaloonMessageQueue);
     except
       on E:Exception do
       Begin
         Self.LogMessage(cs_ProcName + c_DoubleDot + c_Space +
                cs_CallingBalloonEventException + c_Space+
                  cs_FromMessagesThread + c_DoubleDot + c_Space+
                E.Message, True);
       End;
     end;
   End;
 End;
End;

// WindowProc. Процедура реагування на повідомлення до вікна.
// Потрібна через те що потік може показувати повідомлення у
// MessageBox, що є вікном (хоч і малюється системою).
// Для MessageBox потрібне батьківське вікно, яке приймає на себе
// повідомлення, бо коли немає кнопки Пуск, не запущений explorer.exe то
// MessageBox без батьківського вікна часом не відображається, або
// відображається і не відповідає. Так як батьківське вікно має бути із
// того ж потока то потік повідомлень створює пусте вікно і приймає на нього
// повідомлення.
procedure TBaloonMessenger.WindowProc(var sMessage: Messages.TMessage);
Var ccCallBackMessageId:UInt;
    ccWindowToInform: HWND;
Begin
  Self.cBalloonCriticalSection.Enter;
  try
    ccCallBackMessageId:= Self.cuCallbackMessage;
    ccWindowToInform:= Self.cWindow;
  finally
    Self.cBalloonCriticalSection.Leave;
  end;

  if sMessage.Msg = ccCallBackMessageId then
  Begin
    sMessage.Result:= Windows.SendMessage(ccWindowToInform,
      sMessage.Msg, sMessage.WParam, sMessage.LParam);
  End
  Else
    sMessage.Result:=
     Windows.DefWindowProc(Self.FWnd, sMessage.Msg, sMessage.WParam,
        sMessage.LParam);
End;

procedure TBaloonMessenger.ProcessMessages;
Var ccMessage:Windows.TMsg;
Begin
  while Windows.PeekMessage(ccMessage,
    0,  // читаються всі повідомлення для всіхз вікон і ті що послані із PostThreadMessage
    0,  // wMsgFilterMin, без ранжування по типам повідомлень
    0,  // wMsgFilterMax, без ранжування по типам повідомлень
    Windows.PM_REMOVE) do
  Begin
    Windows.TranslateMessage(ccMessage);
    Windows.DispatchMessage(ccMessage);
  End;
End;


procedure TBaloonMessenger.Execute;
const c_EventCount = 2;
      c_ChangeStateCommandIndex = 0;
      c_TerminateCommandIndex = 1;

      cs_ProcNameStart = 'Потік TBaloonMessenger.Execute';

Var ccBalloonShowMoment, ccLastMoment, ccCurMoment: Cardinal;  // момент останнього відображення значка (мс)
    ccHandleArray: array [0..c_EventCount - 1] of THandle;
    cSignal: DWord; //cLastOSError,
    cs_ProcName:String;
    cc_ThreadID:THandle;
    ccPausePendingBeforeNext, ccWaitCommandTimeout:Cardinal;

    ccMsgBoxNum: Cardinal;

    //ccICanSleep: Boolean;
    //ccThisThreadWindow:HWND;


    Procedure ProcShowOneBalloon(Var sdPauseBeforeNextPending:Cardinal;
       Var dSuccessful, dMessagesRemained:Boolean);
    Var ccMessage, ccTitle: String; ccIconType:TBalloonIconAndMessageBoxType;
        ccShowPause:Cardinal;
        ccMBoxResult: Integer;
        ccNoSysSound: Boolean;

        //ccMessageBoxWindow:HWND;
       Procedure ProcMessageSuccessful;
       Begin
         Self.cBaloonMessageQueue.Delete(0);
         Self.cBalloonTitleQueue.Delete(0);
         Self.cBaloonIconQueue.Delete(0);
         Self.cShowPauseQueue.Delete(0);

         dSuccessful:= True;
         sdPauseBeforeNextPending:= ccShowPause;

         dMessagesRemained:= Self.cBaloonMessageQueue.Count > 0;

         ccBalloonShowMoment:= Windows.GetTickCount;
         ccLastMoment:= ccBalloonShowMoment;

         Self.CallAfterBalloonShow(ccMessage, ccTitle,
           Self.cBaloonMessageQueue);
       End;
    Begin
      dSuccessful:= False;
      //dPauseBeforeNext:= 0;

      if Self.cBaloonMessageQueue.Count > 0 then
      Begin
        dMessagesRemained:= True;
          // Якщо витримана пауза для відображення кульки:
        if sdPauseBeforeNextPending = 0 then
        Begin
          ccMessage:= Self.cBaloonMessageQueue[0];
          ccTitle:= Self.cBalloonTitleQueue[0];
          ccIconType:= Self.cBaloonIconQueue[0];
          ccShowPause:= Self.cShowPauseQueue[0];
          ccNoSysSound:= Self.cNoSystemBalloonSound;

          {Спробую як працюють MessageBox коли насправді панель конпки Пуск запущена..:
          If Self.ProcShowBalloon(ccMessage, ccTitle, ccIconType.BalloonIconType,
            ccShowPause, ccNoSysSound) then
          Begin
            ProcMessageSuccessful;
            Self.LogMessage(cs_ProcName+ c_DoubleDot + c_Space+
              ccMessage+'" ('+ccTitle+') Ok.', False);
          End
          else
          Begin
            Self.LogMessage(cs_ProcName+ c_DoubleDot + c_Space+
              'не вдалося показати кульку "'+ccMessage+'" ('+
              ccTitle+')...', True);

            Self.RemoveTrayIcon;
            if Not(Self.AddTrayIcon(Self.IconHint)) then
            Begin}
                //   Windows.MessageBox не повертається поки
                // вікно із повідомленням не закриється
                // (поки користувач не закриє чи не натисне Ok),
                // тому тут виходимо із секції роботи потока
                // щоб інші потоки (що слідкують за цією секцією)
                // в цей час могли надсилати нові повідомлення.
                //   MessageBoxTimeOut теж не повертається доки вікно не
                // закриється, проте воно закривається і само якщо користувач
                // за відведену паузу не натиснув на ньому нічого і не закрив
                // його:
              Self.cBalloonCriticalSection.Leave;
              try
                //ccMessageBoxWindow:= Self.cNewWindow;

//                Dialogs.ShowMessage();

 //               ccMBoxResult:= Dialogs.TaskMessageDlg(ccTitle, ccMessage,
 //                 mtInformation, [mbOK], 0);

                Inc(ccMsgBoxNum);

                ccMBoxResult:= OsFuncHelper.MessageBoxTimeOut(Self.FWnd, //0,  //ccMessageBoxWindow
                  PWideChar(ccMessage),
                   PWideChar(ccTitle
                     // + ' #' + SysUtils.IntToStr(ccMessageBoxWindow)
                      + ' #'+ SysUtils.IntToStr(ccMsgBoxNum)
                     ),  // тимчасово, для наладки, важіль батьківського вікна відображати поставив
                  (ccIconType.MessageBoxType and (not MB_AllMessageBoxWndTypeMask)) or MB_TOPMOST, // ci_DefOkMsgBoxType, MB_OK or MB_TOPMOST, //MB_TASKMODAL, MB_SYSTEMMODAL,   //MB_SETFOREGROUND не гарантує появу вікна поверх інших вікон.. воно тільки ставить його поверх інших вікон програми. І це не усуває глюк із повідомленнями при вводі пароля 1С7.7.
                  0,
                  ccShowPause);

                //Windows.MessageBox(0, PWideChar(ccMessage),
                //  PWideChar(ccTitle), MB_OK or MB_SETFOREGROUND); //MB_TOPMOST напевно не підходить. Вікно зависає або не відображається взагалі при вході в 1С7 коли відображається повідомлення про невірний пароль...
              finally
                Self.cBalloonCriticalSection.Enter;
              End;

              If ccMBoxResult = 0 then
              Begin
                Self.LogLastOSError(cs_ProcName+ c_DoubleDot + c_Space+
                  'не вдалося показати кульку "'+ccMessage+'" ('+
                  ccTitle+')... '+c_SystemSays);
                Windows.Sleep(c_EmergencySleepTime);
              End
              Else
              Begin
                  // Альтернативне вікно з повідомленням відображається
                  // доки користувач не натисне кнопку Ok,
                  // тут воно вже закрилося, тому паузи робити не треба, можна
                  // показувати наступне повідомлення:
                ccShowPause:= 0;
                ProcMessageSuccessful;
              End;
            {End;
          End;}
        End;
      End
      Else dMessagesRemained:= False;
    End;

    procedure ProcCommands();  //var dRunOnceMore:Boolean
    var ccShowMoreMessagesPending, ccBaloonShown:Boolean;
        ccPause:Cardinal;
        ccTerminateEvent:THandle;
    Begin
      ccShowMoreMessagesPending:= False;
      ccBaloonShown:= False;

      //ccCurMoment:= Windows.GetTickCount;
        // Оновлення паузи яку ще слід чекати:
      ccPause:= ccCurMoment - ccBalloonShowMoment;
      if ccPause > ccPausePendingBeforeNext then
        ccPausePendingBeforeNext:= 0
      Else ccPausePendingBeforeNext:= ccPausePendingBeforeNext - ccPause;

        // Якщо була команда показати чи заховати значок:
      if Self.cToShowIcon then
      Begin
        if Not(Self.cIconVisible) then
        Begin
          Self.AddTrayIcon(Self.IconHint);
        End
        else
        Begin
            //  Якщо задано новий ідентифікатор значка або
            // ідентифікатор повідомлення про натискання на значок
            // то намагаємося спочатку сховати старий значок, бо з новими
            // ідентифікатораим буде новий:
          if (Self.cNewIconID<>Self.cIconID) //(Self.cNewWindow<>Self.cWindow) or
              or (Self.cNewuCallbackMessage<>Self.cuCallbackMessage) then
          Begin
            Self.RemoveTrayIcon;
            Self.AddTrayIcon(Self.IconHint);
          End
          Else  // якщо важелі значка ті самі:
          Begin  // запускаємо оновлення значка:
            if Not(Self.ChangeTrayIcon(Self.IconHint)) then // якщо змінити не можна - може значок система видалила через те що вікно закрилося... Спробуємо показати знову:
            Begin
              Self.RemoveTrayIcon;
              Self.AddTrayIcon(Self.IconHint);
            End;
          End;
        End;

        // Навіть якщо значок не вдалося показати - намагаємося
        // показати повідомлення. В значку це не можливо, та ProcShowOneBalloon
        // покаже альтернативним методом, бо було задано показати:
        //if Self.cIconVisible then  // якщо значок відображається:
        //Begin
          ProcShowOneBalloon(ccPausePendingBeforeNext,
            ccBaloonShown, ccShowMoreMessagesPending); //ccPause
          //  //   Якщо повідомлення успішно показано то беремо паузу почекати
          //  // перед відображенням наступного:
          //if ccBaloonShown then
          //  ccPause:= Self.cPauseBeforeNext;
        //End;
      End
        // Якщо показувати значок не треба проте він не захований:
      Else if Self.cIconVisible then
      Begin
        Self.RemoveTrayIcon;
      End;

      if ccShowMoreMessagesPending then  // якщо є ще повідомлення:
      Begin
        //if ccBaloonShown then // якщо відобразили кульку то треба зробити паузу:
        //Begin

          // Витримування паузи перед відображенням наступного повідомлення:
        if ccPausePendingBeforeNext > 0 then
        Begin
          ccTerminateEvent:= Self.cTerminateEvent;
          Self.cBalloonCriticalSection.Leave;
          try
            //cSignal:= Windows.WaitForSingleObject(Self.cTerminateEvent,
            //  ccPausePendingBeforeNext);

            cSignal:= Windows.MsgWaitForMultipleObjects(1,
              ccTerminateEvent, False, ccPausePendingBeforeNext,
              QS_ALLINPUT);
          finally
            Self.cBalloonCriticalSection.Enter;
          end;

          ccCurMoment:= Windows.GetTickCount;

          if cSignal = Windows.WAIT_FAILED then
          begin
            Self.LogLastOSError(cs_ProcName + c_DoubleDot + c_Space +
                cs_WaitForCommandBetweenBalloons +
                cs_ReportedAnError + c_SystemSays);
            Windows.Sleep(c_EmergencySleepTime); // якщо очікування не вдається - то принаймні не завантажуємо процесора і очікуємо приходу кращого часу...
          end
          else  // обробляємо повідомлення для потока і його вікон якщо такі були:
            Self.ProcessMessages;
        End;
      End
      Else  // якщо повідомлень у черзі немає то команди оброблені:
      Begin
        OSFuncHelper.ProcResetEvent(Self.cChangeIconStateCommand,
          cs_ProcName + cs_CantResetEvent + cs_OfChangeIconStateCommand +
          c_SystemSays,
          Self.cLogFile);
      End;
    End;

Begin
  cc_ThreadID:= Windows.GetCurrentThreadId;
    // Якщо процедуру запустили насправді не від того потока що
    // записано в об'єкті (з якихось причин...):
  if Self.ThreadID<>cc_ThreadID then
  Begin
    cs_ProcName:= cs_ProcNameStart+' (ID='+SysUtils.IntToStr(Self.ThreadID)+
      '<>'+SysUtils.IntToStr(cc_ThreadID)+')';
    Self.LogMessage(cs_ProcName + ' запущено від іншого потока із ID='+
      SysUtils.IntToStr(cc_ThreadID)+'!..', True);
  End
  Else
    cs_ProcName:= cs_ProcNameStart+' (ID='+SysUtils.IntToStr(Self.ThreadID)+')';

  ccPausePendingBeforeNext:= 0;

  try
    Self.LogMessage(cs_ProcName + sc_StartsItsWork, False);

    ccBalloonShowMoment:= 0;
    ccLastMoment:= 0;

    ccMsgBoxNum:= 0;

      //   Створюємо вікно для цього потока і вказуємо процедуру для
      // обробки повідомлень що приходитимуть до вікна:
    Self.FWnd:= Classes.AllocateHWnd(Self.WindowProc);

    ccCurMoment:= Windows.GetTickCount;

    Self.cBalloonCriticalSection.Enter;
    try
      while Not(Self.Terminated) do
      Begin
        if ccPausePendingBeforeNext = 0 then
        Begin
          if Self.cDefPauseBeforeHide = 0 then
            ccWaitCommandTimeout:= c_EmergencySleepTime
          Else ccWaitCommandTimeout:= Self.cDefPauseBeforeHide;
        End
        Else
        Begin
          ccWaitCommandTimeout:= ccPausePendingBeforeNext;
        End;

            // Очікування команд:
            // Масив подій, на які треба очікувати:
        ccHandleArray[c_ChangeStateCommandIndex]:= Self.cChangeIconStateCommand;  // подія подачі команди на виконання
        ccHandleArray[c_TerminateCommandIndex]:= Self.cTerminateEvent;     // команда для потока (завершити роботу)

        Self.cBalloonCriticalSection.Leave;
        try
            //   Очікуємо одну із можливих подій, але не довше за час до
            // ховання кульки з повідомленням:
          cSignal:= Windows.MsgWaitForMultipleObjects(c_EventCount,
             ccHandleArray, False, ccWaitCommandTimeout,
             QS_ALLINPUT);
        finally
          Self.cBalloonCriticalSection.Enter;
        end;

          // Обробляємо команди які були дані:

        ccCurMoment:= Windows.GetTickCount;

        if cSignal = Windows.WAIT_FAILED then
        begin
          Self.LogLastOSError(cs_ProcName + c_DoubleDot + c_Space +
              cs_WaitForCommand +
              cs_ReportedAnError + c_SystemSays);
          Windows.Sleep(c_EmergencySleepTime); // якщо очікування не вдається - то принаймні не завантажуємо процесора і очікуємо приходу кращого часу...
        end
        else if cSignal = Windows.WAIT_TIMEOUT then // якщо дочекалися до ccWaitCommandTimeout:
        Begin
          if (ccCurMoment - ccLastMoment >=
                  ccPausePendingBeforeNext) then
          Begin
            if Self.cHideIconOnLastMessageShown
                and Self.cIconVisible then Self.RemoveTrayIcon;
            ccPausePendingBeforeNext:= 0;
          End
          else  // виявляється, буває що і при таймауті після очікування
                // ccWaitCommandTimeout = ccPausePendingBeforeNext
                // GetTickCount показує що пройшло на одну (чи декілька)
                // мілісекунд менше за ту паузу що витримана у
                // WaitForMultipleObjects. Можливо, різні таймери, в них
                // похибка...
                // Тому поправляємо і чекаємо ще той час який не дочекали...:
          Begin
            ccPausePendingBeforeNext:= ccPausePendingBeforeNext -
              (ccCurMoment - ccLastMoment);
            ccLastMoment:= ccCurMoment;
          End;

          if ccPausePendingBeforeNext = 0 then
          Begin
              //   Більше чекати нічого крім команд. При подачі команд
              // потік мають розбудити. Тому потік може спати:
            Self.cBalloonCriticalSection.Leave;
            try
              Self.Suspend;
            finally
              Self.cBalloonCriticalSection.Enter;
            end;
          End;
        End
        else if cSignal = Windows.WAIT_OBJECT_0 + c_TerminateCommandIndex then // якщо треба завершувати роботу:
        Begin
          Continue;   // перевіряємо помітку про завершення роботи і виходимо
        End
        else if cSignal = Windows.WAIT_OBJECT_0 + c_ChangeStateCommandIndex then // якщо є команда:
        Begin
          ProcCommands;
        End
        Else if cSignal >= WAIT_ABANDONED_0 then
        Begin
          Self.LogMessage(cs_ProcName + c_DoubleDot + c_Space +
            cs_WaitForCommand + cs_ReturnedUnknownResult +
            SysUtils.IntToStr(cSignal) + c_Space + sc_TriSpot, True);
          Windows.Sleep(c_EmergencySleepTime);
        End
          // Якщо це не ті об'єкти які замовляли чекати і не повідомлення
          // "WAIT_ABANDONED", і не таймаут, то є повідомлення для вікон потока:
        Else  // оброблюємо всі повідомлення вікнам потока, що є у черзі:
        Begin
          Self.ProcessMessages;
        End;
      End;
         // Якщо вкінці роботи потока значок не прибраний то прибираємо його:
      Self.CleanUpAfterWork;
    finally
      Self.cBalloonCriticalSection.Leave;
        // Звільняємо пусте вікно, що створене було для цього потока:
      Classes.DeallocateHWnd(Self.FWnd);
      Self.FWnd:= 0;
    end;

    Self.LogMessage(cs_ProcName+sc_FinishedItsWork, False);
  except
    on E:Exception do
    begin
      Self.cLogFile.WriteMessage(cs_ProcName + sc_FallenOnError+
        E.Message);
    end;
  end;
End;

function TBaloonMessenger.CheckSelfExitCode:DWord;
const cs_ProcName = 'TBaloonMessenger.CheckSelfExitCode';
Begin
  Result:= High(Result);
  if Not(Windows.GetExitCodeThread(Self.Handle,
      Result)) then
  Begin
    Self.LogLastOSError(cs_ProcName+c_DoubleDot+
      c_Space + 'GetExitCodeThread'+ cs_ReportedAnError+c_SystemSays);
  End;
End;

Procedure TBaloonMessenger.CleanUpAfterWork;
const cs_ProcName = 'TBaloonMessenger.CleanUpAfterWork';
var cc_ThreadExitCode:DWord;
  Procedure ProcCleanUp;
  Begin
    if Self.cIconVisible then
      Self.RemoveTrayIcon;
  End;
Begin
  if Self.ThreadID = Windows.GetCurrentThreadId then
  Begin
    ProcCleanUp;
  End
  Else
  Begin
    cc_ThreadExitCode:= Self.CheckSelfExitCode;

    if cc_ThreadExitCode<>STILL_ACTIVE then
    Begin
      if Self.IconVisible then
      Begin
        Self.LogMessage(cs_ProcName+c_DoubleDot+
          c_Space + 'потік BalloonMessenger (ID='+
          SysUtils.IntToStr(Self.ThreadID)+
          ') УЖЕ не запущений, повернув код='+
          SysUtils.IntToStr(cc_ThreadExitCode)+
          ', проте значок не захований...', True);

        ProcCleanUp;
      End;
    End;
  End;
End;


//------------- Поділ повідомлення на частини --------------

Procedure CutShowTime(sFullTime:Cardinal; sCuttedLen, sFullLength:Integer; //, sRemainedLen
            Var dCuttedTime:Cardinal);
var ccCuttedLen, ccFullTime, ccFullLen:UInt64;  //ccFullLen //ccFullTime, //ccRemainedLen
Begin
  //ci_ShowTimeAddition
  //ccFullLen:= sCuttedLen+sRemainedLen;

  //ccFullTime:= sFullTime;
  //ccRemainedLen:= sRemainedLen;

  if sFullLength = 0 then
  Begin
    dCuttedTime:= sFullTime + ci_ShowTimeAddition;
    //dRemainedTime:= 0;
  End
  Else
  Begin
    ccCuttedLen:= sCuttedLen;
    ccFullTime:= sFullTime;
    ccFullLen:= sFullLength;
    //dRemainedTime:= (ccFullTime*ccRemainedLen) div ccFullLen;
    dCuttedTime:= (ccFullTime*ccCuttedLen) div ccFullLen;
      // До відкушеного часу додаємо мінімальний гарантований час відображення
      // кульки. Кулька відображатиметься протягом цього часу і ще
      // протягом поправки на довжину тексту, яка тут відкушена:
    dCuttedTime:= dCuttedTime + ci_ShowTimeAddition;
  End;



  {
  dCuttedTime/dRemainedTime = sCuttedLen / sRemainedLen,
  dCuttedTime+dRemainedTime = sFullTime;

  dRemainedTime = dCuttedTime/(sCuttedLen / sRemainedLen);
  dRemainedTime = dCuttedTime*sRemainedLen/sCuttedLen;

  dCuttedTime+dCuttedTime*sRemainedLen/sCuttedLen = sFullTime;
  dCuttedTime*(1+sRemainedLen/sCuttedLen) = sFullTime;

  dCuttedTime = sFullTime/(1+sRemainedLen/sCuttedLen);
  dCuttedTime = sFullTime*sCuttedLen/(sCuttedLen+sRemainedLen);

  dRemainedTime = (sFullTime/(1+sRemainedLen/sCuttedLen))*sRemainedLen/sCuttedLen;
  dRemainedTime = (sFullTime*sRemainedLen/((1+sRemainedLen/sCuttedLen)*sCuttedLen));

  dRemainedTime = sFullTime*sRemainedLen/(sCuttedLen+sRemainedLen);
  dRemainedTime = sFullTime/(sCuttedLen/sRemainedLen+1);

  }
End;

Function TryToCut(
    Const sSuffix: String;
    Var sdCutPiece: String;
    Const sMessage: String;
    Var sdStartPos: Integer;
    //Var sdRemainedString:String;
    sMaxLen:Integer;
    sCutAllIfFits:Boolean = True):Boolean;
Var ccLength, ccFullCutLength:Integer;
    ccCutPiece:String;
    ccStartPos, ccNewStartPos: Integer;
Begin
  Result:= False;
  ccLength:= System.Length(sMessage) - sdStartPos + 1;
  //ccFullCutLength:= System.Length(sdCutPiece);
  if sCutAllIfFits then // якщо можна не кусати коли все вміщається:
  Begin
    //ccLength:= System.Length(sMessage) - sdStartPos + 1;
    ccFullCutLength:= System.Length(sdCutPiece) + ccLength;
    Result:= (ccLength > 0) and
     (ccFullCutLength <= sMaxLen);
  End;

  if Result then  // якщо й так все вміщається і нічого кусати не треба:
  Begin
    sdCutPiece:= sdCutPiece + System.Copy(sMessage, sdStartPos, ccLength);
    sdStartPos:= sdStartPos + ccLength;
  End
  Else
  Begin
    ccStartPos:= sdStartPos;

    DataHelper.PrepareToCutFromPosToSuffix(sMessage, sSuffix,
           ccStartPos, ccLength, ccNewStartPos,
           False, True); // суфікс відкушується разом із відкушеним


    //ccCutPiece:= DataHelper.CutFromPosToSuffix(sMessage, sSuffix,
    //       ccStartPos,
    //       False, True);

    //ccLength:= System.Length(ccCutPiece);
    ccFullCutLength:= System.Length(sdCutPiece) + ccLength;

    Result:= (ccLength > 0) and  // якщо підрядки sSuffix є і щось відкусили
       (ccFullCutLength <= sMaxLen); // і відкушене вміщається
    if Result then  // якщо вміщається - додаємо до відкушеного:
    Begin
      ccCutPiece:= System.Copy(sMessage, ccStartPos, ccLength);
      sdCutPiece:= sdCutPiece + ccCutPiece;
      sdStartPos:= ccNewStartPos;
    End;
  End;
End;

          // Рекурсивна процедура додавання повідомлення в чергу із
          // поділом його на частини що можна відобразити:
        //   Якщо довжина повідомлення p_Message завелика щоб показати його
        // у кульці трея то ділить повідомлення на декілька і додає їх у чергу.
        // При цьому повідомлення ділиться по рядкам. Якщо один рядок
        // всеодно задовгий то він ділиться по словам по пробілам. Якщо
        // слово надто довге то ділить його за максимальною довжиною що можна
        // вмістити.
        //   Якщо sPauseBeforeHide не рівна нулю то змінює час відображення
        // кульки PauseBeforeHide (у мілісекундах) після відображення
        // останнього повідомлення.
Procedure TBaloonMessenger.ProcAddMessageToQueue(const BalloonText,
        BalloonTitle: String;
        const BalloonIconType: TBalloonIconType; Const sMessageBoxType: DWORD;
        sPauseBeforeHide:Cardinal);
Var ccLength, ccRemainedPos, ccFullLength:Integer;
    ccCutString: String; //, ccRemainedString
    ccCutted, ccRowsCutted, ccWordsCutted:Boolean;
    ccShowTimeCutted: Cardinal; //, ccShowTimeRemained
    ccBalloonIconAndMsgBoxType: TBalloonIconAndMessageBoxType;
Begin
  {ccLength:= System.Length(BalloonText);
  if ccLength > ci_MaxTrayBaloonInfoLen then
  Begin}

  //ccRemainedString:= BalloonText;
  ccRemainedPos:= 1;
  ccFullLength:= System.Length(BalloonText);

  if sPauseBeforeHide = 0 then
  Begin
    if ccFullLength = 0 then
      sPauseBeforeHide:= Self.DefPauseBeforeHide
    else sPauseBeforeHide:= ccFullLength * ci_DefMillisecondsPerSymbol;
  End;

  //ccShowTimeRemained:= sPauseBeforeHide;

  repeat
    ccRowsCutted:= False;
    ccWordsCutted:= False;
    ccCutString:= '';
    ccShowTimeCutted:= 0;


    repeat  // відкушуємо і додаємо до відкушеного доки вміщається:
        // Поділ на рядки:
      ccCutted:= TryToCut(c_CR+c_LF,
        ccCutString, BalloonText, ccRemainedPos,
        ci_MaxTrayBaloonInfoLen);
      if ccCutted then ccRowsCutted:= True
      Else
      Begin  // якщо поділів c_CR+c_LF нема
        ccCutted:= TryToCut(c_CR,
          ccCutString, BalloonText, ccRemainedPos,
          ci_MaxTrayBaloonInfoLen);
        if ccCutted then ccRowsCutted:= True
        Else
        Begin   // якщо поділів c_CR нема
          ccCutted:= TryToCut(c_LF,
            ccCutString, BalloonText, ccRemainedPos,
            ci_MaxTrayBaloonInfoLen);
          if ccCutted then ccRowsCutted:= True
              // Слова кусаємо тільки якщо не відкусився ні один рядок:
          Else if Not(ccRowsCutted) then
          Begin  // якщо поділів c_LF нема
            ccCutted:= TryToCut(c_Space,
              ccCutString, BalloonText, ccRemainedPos,
              ci_MaxTrayBaloonInfoLen);
            if ccCutted then ccWordsCutted:= True
              //   Якщо нічого не відкушується, то вставляємо
              // скільки вміщається по довжині:
            Else if Not(ccRowsCutted or ccWordsCutted) then
            Begin
              ccCutString:= System.Copy(BalloonText, ccRemainedPos,
                ci_MaxTrayBaloonInfoLen);
              ccLength:= System.Length(ccCutString);
              ccRemainedPos:= ccRemainedPos + ccLength;

//              CutShowTime(sPauseBeforeHide, ccLength,
//                System.Length(ccRemainedString),
//                ccShowTimeCutted, ccShowTimeRemained);
            End;
          End;
        End;
      End;
    until Not(ccCutted);

    CutShowTime(sPauseBeforeHide, System.Length(ccCutString),
            ccFullLength,
            ccShowTimeCutted);

    {CutShowTime(sPauseBeforeHide, ,
                ccFullLength - ccRemainedPos + 1,
                ccShowTimeCutted, ccShowTimeRemained);}
    ccBalloonIconAndMsgBoxType.BalloonIconType:= BalloonIconType;
    ccBalloonIconAndMsgBoxType.MessageBoxType:= sMessageBoxType;

    Self.cBaloonMessageQueue.Add(ccCutString);
    Self.cBalloonTitleQueue.Add(BalloonTitle);
    Self.cBaloonIconQueue.Add(ccBalloonIconAndMsgBoxType);
    Self.cShowPauseQueue.Add(ccShowTimeCutted);
      // Якщо якась частина повідомлення не вмістилася то
      // ділимо її при потребі і додаємо далі в чергу,
      // з тим самим заголовком і значком кульки:
    //але робимо це звичайним циклои repeat, а не рекурсією:
    //if ccRemainedString <> '' then
    //Begin
    //  Self.ProcAddMessageToQueue(ccRemainedString, BalloonTitle,
    //    BalloonIconType, ccShowTimeRemained);
    //End;
  until ccRemainedPos > ccFullLength;
{  End
  Else
  Begin
    Self.cBaloonMessageQueue.Add(BalloonText);
    Self.cBalloonTitleQueue.Add(BalloonTitle);
    Self.cBaloonIconQueue.Add(BalloonIconType);
  End;}
End;


//------------- TBaloonIconTypesList --------------

Function ReadBaloonIconAndMsgBoxType(sPnt:PBalloonIconAndMessageBoxType):TBalloonIconAndMessageBoxType;
Begin
  Result:= sPnt^;
End;

Function WriteBaloonIconAndMsgBoxType(sType:TBalloonIconAndMessageBoxType):PBalloonIconAndMessageBoxType;
Begin
  //Result:= Nil;
  System.New(Result);
  Result^:= sType;
End;

Procedure FreeAndNilBaloonIconAndMsgBoxType(Var sPnt:PBalloonIconAndMessageBoxType);
Begin
  if sPnt <> Nil then
  Begin
    System.Dispose(sPnt);
    //System.FreeMem(sBuf);
    sPnt:= Nil;
  End;
End;


procedure TBaloonIconTypesList.Notify(Ptr: Pointer; Action: TListNotification);
Begin
End;
function TBaloonIconTypesList.Get(Index: Integer): TBalloonIconAndMessageBoxType;
Begin
  Result:= ReadBaloonIconAndMsgBoxType(Inherited Get(Index));
End;
procedure TBaloonIconTypesList.Put(Index: Integer; Const Item: TBalloonIconAndMessageBoxType);
Begin
  Inherited Put(Index, WriteBaloonIconAndMsgBoxType(Item));
End;

function TBaloonIconTypesList.Add(Const Item: TBalloonIconAndMessageBoxType): Integer;
Begin
  Add:= Inherited Add(WriteBaloonIconAndMsgBoxType(Item));
End;
procedure TBaloonIconTypesList.Clear;
Begin
    // Перед очисткою списка звільняємо пам'ять від усіх елементів, що у ньому:
  while Self.Count > 0 do
    Self.Delete(0);

  Inherited Clear;
End;

procedure TBaloonIconTypesList.Delete(Index: Integer);
Var cItem:PBalloonIconAndMessageBoxType;
Begin
  cItem:= Inherited Get(Index);

  Self.List^[Index]:=Nil;
  Inherited Delete(Index);

  if cItem <> Nil then
  Begin
    Self.Notify(cItem, Classes.lnDeleted);

    FreeAndNilBaloonIconAndMsgBoxType(cItem);
  End;
End;

function TBaloonIconTypesList.Remove(Item: TBalloonIconAndMessageBoxType): Integer;
Begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Self.Delete(Result);
End;

function TBaloonIconTypesList.Extract(Const Item: TBalloonIconAndMessageBoxType): TBalloonIconAndMessageBoxType;
Var cIndex: Integer;
Begin
  cIndex:= Self.IndexOf(Item);
  if cIndex >= 0 then
    Result:= Self.ExtractByNum(cIndex)
  Else
  Begin
    Result.BalloonIconType:= bitNone; //'';
    Result.MessageBoxType:= ci_DefOkMsgBoxType;
  End;
End;
function TBaloonIconTypesList.ExtractByNum(Index: Integer): TBalloonIconAndMessageBoxType;
Var cItem:PBalloonIconAndMessageBoxType;
Begin
  cItem:= Inherited Get(Index);

  Result:= ReadBaloonIconAndMsgBoxType(cItem);

  Self.List^[Index]:=Nil;
  Inherited Delete(Index);
  Self.Notify(cItem, Classes.lnExtracted);

  FreeAndNilBaloonIconAndMsgBoxType(cItem);
End;

function TBaloonIconTypesList.First: TBalloonIconAndMessageBoxType;
Begin
  First:= ReadBaloonIconAndMsgBoxType(Inherited First);
End;

function TBaloonIconTypesList.ExtractFirst: TBalloonIconAndMessageBoxType;
Begin
  ExtractFirst:= Self.ExtractByNum(0);
End;

Procedure TBaloonIconTypesList.Insert(Index: Integer; Const Item: TBalloonIconAndMessageBoxType);
Begin
  Inherited Insert(Index, WriteBaloonIconAndMsgBoxType(Item));
End;
function TBaloonIconTypesList.Last: TBalloonIconAndMessageBoxType;
Begin
  Last:= ReadBaloonIconAndMsgBoxType(Inherited Last);
End;

function TBaloonIconTypesList.ExtractLast: TBalloonIconAndMessageBoxType;
Begin
  ExtractLast:= Self.ExtractByNum(Self.Count - 1);
End;
             // Виконує пошук у списку...:
function TBaloonIconTypesList.IndexOf(Const Item: TBalloonIconAndMessageBoxType): Integer;
var
  LCount: Integer;
  cItem, cSourceItem: TBalloonIconAndMessageBoxType;
begin
  LCount := Self.Count;

  cSourceItem:= Item;

  for Result := 0 to LCount - 1 do // new optimizer doesn't use [esp] for Result
  Begin
    cItem:= Self.Get(Result);

    if (cItem.BalloonIconType = cSourceItem.BalloonIconType)
      and (cItem.MessageBoxType = cSourceItem.MessageBoxType) then
    Begin
      Exit;
    End;
  End;

  Result := -1;
end;

// Ініціалізація констант про довжину рядків у NotifyIconData.
// Не вдалося зробити це в оголошенні констант.
Procedure ReadNotifyIconDataStringsLength;
Var ccDummyData: NotifyIconData;
Begin   // -1 - з поправкою на нуль-символ, бо рядки там з нулями вкінці:
  ci_MaxTrayTipLen:= System.Length(ccDummyData.szTip) - 1;
  ci_MaxTrayBaloonInfoLen:= System.Length(ccDummyData.szInfo) - 1;
  ci_MaxTrayBaloonTitleLen:= System.Length(ccDummyData.szInfoTitle) - 1;
End;

initialization
  ReadNotifyIconDataStringsLength;

end.