unit UDirectShowHelp;

interface
  // DShowUtil - це DSUtil із пакета DSPAck. Її довелося перейменувати,
  // бо однойменний модуль DSUtil вже є у пакеті "database" (в Delphi 9)...
Uses SysUtils, SysConst, Windows, ShLwApi, Classes, Jpeg, SyncObjs, ComObj, StrUtils,
     ActiveX, DirectShow9, DShowUtil, Graphics,
      DataHelper, OSFuncHelper, UEventHelper;

type
  TBMPSampleRec = record
    cSampleTime: Double;  // час кадра, є його ідентифікатором
    cBmpHead: TBitmapInfoHeader;
    cBufferSize: LongInt;
    pBuffer: PByte;
  End;
  PBMPSampleRec = ^TBMPSampleRec;

Const cs_NewLine = Chr(13)+Chr(10);

    //   Фільтр отримання із джерела відео і розбору його на потоки
    // LAV Splitter Source.
    //   Вміє розбирати різні формати файлів і читати відео із серверів за
    // URL через такі протоколи як RTSP, RTMP.
    // Спочатку робиться спроба відкрити потік через нього в явному вигляді, бо
    // хоч він і є пріоритетним у пакеті K-Lite codec pack, налаштувати щоб він
    // автоматично використовувався для потоків RTSP і RTMP утилітами пакета
    ///не вдалося. Тому тут він викликається явно:
  CLSID_LAVSplitterSource: TGUID = '{B98D13E7-55DB-4385-A33D-09FD1BA26338}';

  //Ці константи не використовуються. Вони бул ипотрібні для реалізації
  //отримання подій графа через події вікна. Тепер реалізовано через
  //очікування на об'єкт-подію:
  //sc_MessageToHandleFromDSGraph='WM_MessageToHandleEventOfDirectShowGraph';
  //c_lParamForDSHandler = 9;  // можна будь-яке число, тут не аналізується. Поки що..

  cs_FGraphBuilderAbsent=': не задано інтерфейс будувача графа FGraphBuilder...';
  cs_CaptureGraphBuilderNotSet=': не заданий CaptureGraphBuilder...';
  cs_CoInitializeExFailed = ': CoInitializeEx не вдалося: ';

  cs_EnumPinsReported = ': EnumPins сообщило: ';
  cs_EnumPinsFailedToStart = ': не удалось начать обход пинов, pEnumPins.Reset сообщило: ';
  cs_EnumPinsNextReportedUnusual = ': pEnumPins.Next сообщило неожиданный результат: ';
  cs_EnumPinsNextNotReturnedExistedPin = ': pEnumPins.Next не повернуло пін, хоч і повідомило що він є!..';
  cs_EnumPinsDeSynchronizedOn = ': pEnumPins.Next сообщило о рассинхронизации обхода пинов на ';
  cs_EnumPinsStartingNewEnum = '. Обход начинается заново...';
  cs_ConnectionMediaTypeReported = ': sPin.ConnectionMediaType повідомило:';

  cs_FailedToSetEvent = ': не вдалося встановити сигнал';
  cs_FailedToResetEvent = ': не вдалося вимкнути сигнал';

  cs_FailedToCreateEvent = ': не вдалося створити об''єкт для очікування';
  cs_FailedToCloseEvent = ': не вдалося закрити об''єкт очікування ';

  cs_AboutThreadStopCommand = ' команди завершення потока... ';
  cs_AboutSampleCapturedEvent = ' події отримання кадра... ';
  cs_AboutNewSampleCaptured = ' про те що захоплено новий кадр... ';

  cs_UnknownResultOnWaitingEvent =
    ': очікування на подію повернуло невідомий результат: ';

  cs_OnSampleException = ': при роботі обробника OnSample сталося виключення: ';

  cs_SeekingInterfaceNotAssigned = ': інтерфейс перемотки не заданий...';

  c_SamplesInfinite = High(Cardinal);

  c_DefJpegCompressionQuality = 50; //30;
  cs_JpegExt = 'jpg';

type
  PAMMPEGSystemType = ^TAMMPEGSystemType;

  TProcDShowEvent = Procedure (cEvCode:Longint; lParam1, lParam2:Longint) of object;
  TCallFromThreadMethod = Procedure (sCaller: TThread) of object;

  TCallFromThreadOnGraphEvent = Procedure (sCaller: TThread;
    sEvCode:Longint; slParam1, slParam2:Longint;
    sEventName, sEventData:String) of object;

  TCallFromThreadOnStateChange = Procedure (sCaller: TThread;
    Const sState, sLastState:TFilterState;
    sSTATE_INTERMEDIATE, sCANT_CUE:Boolean;
    sStateRes, sLastStateRes:HResult;
    sCurURL, sLastURL, sCurName_ch:String) of object;

  TCallFromThreadOnLogMessage = Procedure (sCaller: TThread;
        Const sMessage:String;
        sThisIsCriticalError:Boolean = False) of object;

  TMessageLogProc = Procedure (sCurThread:TThread;
        Const sMessage:String;
        sThisIsCriticalError:Boolean = False) of object;

  TCallFromThreadOnSample = Procedure (sCaller: TThread;
    sSample:PBMPSampleRec) of object;

  TCallFromThreadOnSampleAsBitmap = Procedure (sCaller: TThread;
    sSample:Graphics.TBitmap) of object;

  TCallFromThreadOnSampleAsJpeg = Procedure (sCaller: TThread;
    sSample:TJpegImage) of object;

  TCallFromThreadOnSampleAsFile = Procedure (sCaller: TThread;
    sFilePath: String) of object;

  //TCallFromThreadOnSampleCB = function (
  //    SampleTime: Double; pSample: IMediaSample): HResult;

  //TCallFromThreadOnBufferCB = function (
  //    SampleTime: Double; pBuffer: PByte; BufferLen: longint): HResult;

  PVideoWindowInfo = ^TVideoWindowInfo;
  TVideoWindowInfo = record
    sOwner:HWND;
    CoordsInClient: TRect;
    //sWindowStyle:Longint;
  End;
    //   Список кадрів TBMPSampleList.
    // Всі кадри при додаванні копіює у окрему пам'ять (за виключенням додавання
    // із вказуванням sToCopyItem = False).
    // При видаленні елементів звільняє від них пам'ять.
    // При витягуванні елементів зі списка (Extract) НЕ копіює в окерму пам'ять,
    // і не очищає її. Для звільненні пам'яті треба викликати FreeItem.
    //   FreeItem можна викликати як для елементів, що витягнуті вже зі списка,
    // так і для тих що в списку. При цьому пам'ять від елемента зв'льняється,
    // і елемент видаляється зі списка, якщо він там є.
    //   Тобто для кожного елемента, для якого немає певності що він Є у списку,
    // при закінченні роботи із ним треба перевірити його наявність (IndexOf),
    // і додати у список при потребі, після чого викликати FreeBMPData (якщо
    // sToCopyItem = True. Можна явно задати sToCopyItem = False, і тоді
    // FreeBMPData не треба викликати при додаванні елемента.
    // sToCopyItem має бути True якщо пам'ять від елемента не можна звільняти,
    // якщо не можна для елемента викликати FreeBMPData).
    //   Також при закінченні роботи з елементом можна викликати FreeItem,
    // якщо треба звільнити від нього пам'ять і видалити зі списка (в цьому
    // випадку список не буде змінений якщо даного елемента в ньому і так
    // немає)...
    //   Робота йде так для того щоб кадри копіювалися тільки один раз
    // (із джерела, яке даї читати їх на короткий час). Далі вони не копіюються
    // самим списком.
  TBMPSampleList = class (TList)
     private
       cListSection:TCriticalSection;
     protected


        //procedure Notify(Ptr: Pointer; Action: TListNotification); override;

        function Get(Index: Integer): PBMPSampleRec;
        procedure Put(Index: Integer; Const Item: PBMPSampleRec);
     public
        Procedure LockList;
        procedure UnlockList;

          //   Викликається для елементів, з якими робота завершена і які треба
          // видалити зі списку. Повертає номер елемента, під яким він
          // був у списку. Якщо елемент не був у списку - повертає -1
          // (але пам'ять від елемента всеодно звільняє):
        Function FreeItem(Var sdItem:PBMPSampleRec):Integer;
          //   Видаляє елемент зі списка і звільняє від нього пам'ять.
          // Якщо елемента немає у списку то не звільняє від нього пам'ять,
          // і повертає -1. Інакше - повертає номер елемента, з яким він
          // був у списку:
        function Remove(Item: PBMPSampleRec): Integer;

        function Add(Const Item: PBMPSampleRec;
          sToCopyItem:Boolean = True): Integer; overload;

        Function Add(sHeader: PBitmapInfoHeader;
          pBuffer:PByte; sBufferSize: Longint;
          sSampleTime:Double):Integer; overload;

        procedure Clear; override;
        procedure Delete(Index: Integer);
        function Extract(Const Item: PBMPSampleRec): PBMPSampleRec;
        function ExtractByNum(Index: Integer): PBMPSampleRec;
        function First: PBMPSampleRec;
        function ExtractFirst: PBMPSampleRec;
        procedure Insert(Index: Integer; Const Item: PBMPSampleRec;
          sToCopyItem:Boolean = True); overload;
        procedure Insert(Index: Integer;
          sHeader: PBitmapInfoHeader;
          pBuffer:PByte; sBufferSize: Longint;
          sSampleTime:Double); overload;

        function Last: PBMPSampleRec;
        function ExtractLast: PBMPSampleRec;
             // Виконує пошук кадра у списку за часом...:
        function IndexOf(Const Item: PBMPSampleRec): Integer;

        property Items[Index: Integer]: PBMPSampleRec read Get write Put; default;

        Constructor Create(sUseCriticalSection:Boolean = True);
        destructor Destroy; override;
  end;

  TDirectShowGraphController = class;

  TDirectShowGraphEventHandler = class(TThread)
    private
      cMediaEvent: IMediaEventEx;
    protected
      cGraphController:TDirectShowGraphController;
      cTerminateEvent, cGraphEvent: THandle;

      cOnGraphEvent: TCallFromThreadOnGraphEvent;

      cMediaEventUseSection:TCriticalSection;

         //Інтерфейси DirectShow:
      property fMediaEvent: IMediaEventEx read cMediaEvent;

      procedure Execute; override;

      Procedure SetOnGraphEvent(Value: TCallFromThreadOnGraphEvent); virtual;

      Function InitDSMessageHandler(sGraphBuilder:IGraphBuilder):Boolean;
      Procedure StopDSMessageHandler;

      Procedure DShowEventParamHandler(cEvCode:Longint;
        lParam1, lParam2:Longint);
    public
      property OnGraphEvent:TCallFromThreadOnGraphEvent read cOnGraphEvent write SetOnGraphEvent;

      constructor Create(sGraphController:TDirectShowGraphController;
        sGraphBuilder:IGraphBuilder);

      //  Ні. Метода ChangeGraph не буде. Якщо граф змінюється - треба створити
      //новий слухач подій і налаштувати його.
      //Procedure ChangeGraph(sGraphBuilder:IGraphBuilder);
      destructor Destroy; override;
      procedure Terminate; virtual;
  end;

   // Базовий клас потока для керування читанням і перетворенням
   // відео і/або аудіо:
  TDirectShowGraphController = class(TThread)
    private
        // Інтерфейси DirectShow:
      cGraphBuilder: IGraphBuilder;
        // Інтерфейс для керування відтворенням (пуск, пауза, стоп...):
      cMediaControl: IMediaControl;
        // Інтерфейс для перемотування позиції відтворення:
      cMediaSeeking: IMediaSeeking;
      //cVideoWindow: IVideoWindow;

    protected
      //cTerminateEvent: THandle;
      cLogFile: TLogFile;

      cEventHandler: TDirectShowGraphEventHandler;

      cOnStateChange:TCallFromThreadOnStateChange;

      cOnGraphEvent: TCallFromThreadOnGraphEvent;
      cOnLogMessage: TCallFromThreadOnLogMessage;

      // write SetOnLogMessage;

        // Поточний мережевий потік чи файл:
      cUrl, cName_ch:string;
        // Потік, який треба запустити:
      cDestUrl, cDestChName: String;
      cDestUrlIsLocal:Boolean;
        // Стан, в який задано встановити граф відтворення;
        // стан, в якому граф був останнього разу в момент визначення стану:
      cDestState, cLastState: TFilterState;
        // Подробиці стану, в якому граф був останнього разу в момент визначення стану:
      cLastStateRes:HResult;
      cLastURL:String;
        // Запит на перемотку:
      cNewPositionQueried:Boolean;
        // Позиція відтворення, до якої треба перемотати:
      cDestPosition:Int64; cDestPositionIsRelative:Boolean;
        //   cTimeFormat - формат позиції відтворення медіафайла.
        //   При його зміні граф зупиняється (і запускається заново з
        // відтворенням із початку).
        //   Типова визначається графом при його створенні,
        // зазвичай вона є TIME_FORMAT_MEDIA_TIME (тобто сотні наносекунд):
      cTimeFormat, cDestTimeFormat:TGUID;


        // Вмикач обов'язкової перебудови графа на наступному такті керування
        // (запускає перебудову навіть якщо не змінилося посилання на потік чи
        // файл, cUrl, і не змінився потрібний стан графа, cDestState).
        // Щоб потік запустив такт треба розбудити його (Resume)
        // якщо він спить (Suspended):
      cDoRebuildGraph:Boolean;
        // Секція доступа до змінних потрібного стану; секція доступа до
        // будувача графа:
      cDestStateUseSection, cGraphBuilderUseSection:TCriticalSection;

      cVideoWindowInfo, cVideoWindowNewSettings:TVideoWindowInfo;

        // Події для реагування у класах-нащадках:
        // Викликаються із потока цього об'єкта:
      cAfterStop, cAfterPause, cAfterRun:
        TCallFromThreadOnStateChange;

      Function GetBitmapHeaderFromMEDIA_TYPEStruct(Const sMediaType:TAMMediaType;
        var dBMIInfo: TBitmapInfoHeader;
        sStreamNumber:Cardinal = 0):Boolean;

// GetBitmapHeaderOfVideoOnConnectedPin отримує TBitmapInfoHeader для
// відео на піні, якщо він під'єднаний.
// Якщо відео на піні має декілька потоків, то повертає дані для потока
// з номером sStreamNumber.
// Повертає True, якщо пін під'єднаний і через нього йде відео, і дані про
// картинку вдалося прочитати.
      Function GetBitmapHeaderOfVideoOnConnectedPin(sPin:IPin;
        var dBMIInfo: TBitmapInfoHeader;
        sStreamNumber:Cardinal = 0):Boolean;
      Function GetVideoSizeOnConnectedPin(sPin:IPin;
        Var dWidth, dHeight:Integer;
        sStreamNumber:Cardinal = 0):Boolean;

      Function GetPinArray(sFilter:IBaseFilter; sPinDirection: TPinDirection;
         sOnlyConnectedPins:Boolean;
        Const sMediaType: PGUID = Nil):IInterfaceList;

      Procedure SetNewGraphBuilder(Value: IGraphBuilder); virtual;

        //Інтерфейси DirectShow:

      Property FMediaControl: IMediaControl read cMediaControl;
      Property FMediaSeeking: IMediaSeeking read cMediaSeeking;
      //  //   Інтерфейс вікна відтворення відео. Ініціюється тільки при
      //  // виклику SetupVideoWindow:
      //Property FVideoWindow: IVideoWindow read cVideoWindow;

      property FGraphBuilder: IGraphBuilder read cGraphBuilder write
        SetNewGraphBuilder;

      Procedure SetOnGraphEvent(Value: TCallFromThreadOnGraphEvent); // virtual;
      Procedure SetOnLogMessage(Value: TCallFromThreadOnLogMessage); // virtual;
      //Function GetOnGraphEvent: TCallFromThreadOnGraphEvent; virtual;

      Procedure SetOnStateChange(Value: TCallFromThreadOnStateChange); // virtual;
        // Будувач графа фільтрів. Реалізується в класах-нащадках.
        // Будує граф, але не запускає його. Виконується в потоці цього об'єкта.
        // Повертає ознаку успішності побудови графа
        // (коли файл або потік відкритий, всі потрібні фільтри для читання і
        // відтворення медіа у потрібному форматі знайдені і приєднані в граф):
      Function CreateGraph(Const sUrl, sName_ch:String):Boolean; virtual; abstract;

        // Запускає граф на відтворення або на паузу.
      Function RunGraph(sStartPaused:Boolean = False):Boolean; virtual;

      //Function DSEventHandler(slParam:LParam):Boolean;
        // LogMessage
        // Може викликатися із різних потоків. Треба вказувати об'єкт поточного
        // потока у sCurThread.
      Procedure LogMessage(sCurThread:TThread;
        Const sMessage:String;
        sThisIsCriticalError:Boolean = False);

         // Читання стану відтворення. Ззовні запускати не рекомендується,
         // краще використати обробник події OnStateChange, який отримує
         // ці дані якщо вони змінюються при будь-яких подіях у графі
         // і після кожного такта керування графом. Також в OnStateChange
         // передається адреса потока і його назва, який зараз відтворюється,
         // або відтворювався останнього разу (sCurURL, sCurName_ch):
      Function GetRunningState(sCurThread:TThread;
          Var dSTATE_INTERMEDIATE:Boolean;
          Var dCANT_CUE:Boolean;
          Var dStateRes:HResult;
          Const sTimeOut:DWord = 0):TFilterState;

      Function CheckUrlIsLocal(Const sUrl:String):Boolean;

      Function QueryNewState(Url, Name_ch:String;
        sForceRebuildGraph:Boolean; sNewState:TFilterState):Boolean;

      Function QueryNewPos(Const sPosition:Int64;
          sPositionIsRelativeToCurrent:Boolean):Boolean;

      procedure QueryTimeFormat(Value:TGUID);
        //   Читає одиницю часу графа і записує її cTimeFormat.
        // Граф має існувати:
      Function ReadGraphTimeFormat: TGUID;
      Function GetCurTimeFormat: TGUID;
        //   Установнює в графі нову одиницю виміру часу.
        //// Якщо граф запущений то зупиняє його і знову запускає з
        //// новою одиницею із початку відтворення
        //// (бо про IMediaSeeking::SetTimeFormat сказано у
        //// https://msdn.microsoft.com/ru-ru/library/windows/desktop/dd407040%28v=vs.85%29.aspx)
        //// що вона може повертати VFW_E_WRONG_STATE коли граф запущений.
        //   Запускається із цього потока при завершенні створення і побудови
        // графа, коли граф ще зупинений:
      Procedure SetGraphTimeFormat(Const sTimeFormat:TGUID);
        //   Повертає True якщо в графі вдалося встановити задану позицію
        // відтворення. Позиція задається в одиницях часу графа
        // (копія поточного типу одиниці графа зберігається у cTimeFormat):
      Function SetPosition(Const sPosition:Int64;
        sPositionIsRelativeToCur:Boolean):Boolean;

      procedure Execute; override; // abstract;
    public


        // Всі методи подій тут запускається БЕЗ будь-якої синхронізації.
        // Для синхронізації із іншими потоками в методі має бути вхід в
        // критичну секцію, або виклик іншого метода функцією
        // TThread.Synchronize для синхронізації із
        // головним потоком (потоком GUI):

        // Метод OnGraphEvent викликається при запису події в лог-файл.
        // При відсутності лог-файла записи в нього не ведуться, виключення
        // не піднімаються, але цей метод всеодно запускається якщо він є.
        // Якщо метод OnGraphEvent заданий, і в ньому виникає виключення то
        // воно записується разом із повідомленням про подію в лог-файл.
        // Якщо в OnGraphEvent піднімається виключення і лог-файл
        // не відкритий то воно перепіднімається разом із повідомленням про
        // подію:
      property OnGraphEvent:TCallFromThreadOnGraphEvent read cOnGraphEvent write SetOnGraphEvent;
      property OnLogMessage:TCallFromThreadOnLogMessage read cOnLogMessage write SetOnLogMessage;
        // Метод OnStateChange викликається після кожної спроби запустити
        // відтворення, і при кожній події графа (разом із OnGraphEvent),
        // якщо параметри стану графа або Url змінилися:
      property OnStateChange:TCallFromThreadOnStateChange read cOnStateChange write SetOnStateChange;

      Property LogFile:TLogFile read cLogFile;

        //   TimeFormat - формат позиції відтворення медіафайла.
        //   При його зміні граф зупиняється (і запускається заново з
        // відтворенням із початку).
        //   Типова визначається графом при його створенні,
        // зазвичай вона є TIME_FORMAT_MEDIA_TIME (тобто сотні наносекунд):
      property TimeFormat:TGUID read GetCurTimeFormat write QueryTimeFormat;

        //   Play і Pause повертають False, якщо Url не задано і не було задано
        // з часу створення об'єкта. Для відтворення треба задати Url
        // (посилання на потік у мережі або шлях до файла) хоча б один раз.
        // Якщо тут Url заданий то Play і Pause повертають True. Відтворення
        // може початися пізніше, коли Url вдасться відкрити. Об'єкт
        // повторює спроби запустити відтворення якщо відкрити потік і запустити
        // його не вдається. Ці спроби (і відтворення) припиняються після
        // виклику Stop (або звільнення об'єкта). Після кожної спроби
        // об'єкт викликає метод OnStateChange:
      Function Play(Const Url:String = ''; Const Name_ch:String = '';
        sForceRebuildGraph:Boolean = False):Boolean; virtual;
      Function Pause(Const Url:String = ''; Const Name_ch:String = '';
        sForceRebuildGraph:Boolean = False):Boolean; virtual;
      procedure Stop; virtual;
         //   Переводить стан відтворення на початок файла чи потока,
         // коли це можливо. Якщо не можливо то перебудовує граф
         // і якщо йшло відтворення то запускає його, інакше переводить
         // граф у режим паузи:
      Procedure Rewind; Virtual;
         //   Переводить стан відтворення на задану позицію.
         // Позиція має вказуватися в одиницях часу, що вказані у
         // TimeFormat:
      Procedure RewindToPos(sPosition:Int64;
        sRelativeToCurrent:Boolean = False); Virtual;

         // Тут метод SetupVideoWindow тільки запам'ятовує вікно
         // і координати для відеокартинки в ньому, і записує їх у
         // Self.cVideoWindowNewSettings.
         // Метод заміняється і доповнюється у класах-нащадках, де він
         // виконує операції із налаштування вікна відображення відео, ті які
         // потрібні із тим рендерером який в тих класах використовується.
         // Якщо дочірній клас не реалізує вікно відображення відео, то цей
         // метод не робить ніякого ефекту.
      Procedure SetupVideoWindow(sOwner:HWND;
        Left, Top, Width, Height: Longint); virtual; // overload;
 //        // Для вказування координат вікна відтвоерння на заданому вікні
 //        // (яке було вже задане раніше):
 //     function SetVideoWindowPos(Left, Top, Width, Height: Longint):Boolean; virtual;
 // //    function SetupVideoWindow(sControl:TWinControl;
 // //      Left, Top, Width, Height: Longint;
 // //      sWindowStyle:Longint = WS_CHILD or WS_CLIPSIBLINGS); virtual; overload;

      Function SaveGraphToFile(Const sFileName:String):Boolean;

      constructor Create(sLogFile:TLogFile = Nil;
        CreateSuspended:Boolean = False);
      destructor Destroy; override;
      procedure Terminate; virtual; // override; тут, на жаль, не можна override, бо у TThread Terminate не є віртуальною...
  end;

  TPlayVideoGraphController = class;

  TProcVideoGraphControllerQueryThread = class (TThread)
    private
      cGraphController:TPlayVideoGraphController;
    protected
      procedure Execute; override;
    public
      constructor Create(sGraphController:TPlayVideoGraphController = Nil;
        CreateSuspended:Boolean = False);
      destructor Destroy; override;
      procedure Terminate; virtual; // override; тут, на жаль, не можна override, бо у TThread Terminate не є віртуальною...
  end;

  TPlayVideoGraphController = class(TDirectShowGraphController)
    private
      cVMRWindowlessControl:IVMRWindowlessControl;

      cProcQueryThread: TProcVideoGraphControllerQueryThread;

      cVideoWidth, cVideoHeight:Integer;

      cRenderVideo, cRenderAudio:Boolean;

      Procedure SetRenderVideo(Value:Boolean);
      Procedure SetRenderAudio(Value:Boolean);

      Procedure ReportVideoWidthHeightChanged;

      Procedure ReportVideoWidth(Value:Integer);
      Procedure ReportVideoHeight(Value:Integer);

      Function CheckVideoBeingRendered:Boolean;

      Function InitVideoMediaRendererOnWindow(
        sVideoRenderer:IBaseFilter
        //; Const sNewSettings:PVideoWindowInfo = Nil
        ):IVMRWindowlessControl;
    protected
        // Параметри запиту на перемалювання вікна відображення відео
        // (коли треба перемалювати його пікселі, а не оверлейне зображення,
        // тобто коли вікно отримує повідомлення WM_Paint):
      cRepaintQuery, cDisplayModeChangeQuery, cWindowChangeQuery:Boolean;
      cPaintOwner: HWnd;
      cPaintDC: HDC;

      Property VideoWidth: Integer read cVideoWidth write ReportVideoWidth;
      Property VideoHeight: Integer read cVideoHeight write ReportVideoHeight;

      Procedure SetNewGraphBuilder(Value: IGraphBuilder); override;

        // Реалізація побудови графа:
      Function CreateGraph(Const sUrl, sName_ch:String):Boolean; override;

        // Запускає граф на відтворення або на паузу.
        // Налаштовує відеовікно, якщо його параметри були задані
        // у SetupVideoWindow:
      Function RunGraph(sStartPaused:Boolean = False):Boolean; override;

        //// Якщо інтерфейс вікна відсутній
        //// (був звільнений при зміні графа чи ще не створений), то отримує
        //// інтерфейс вікна із будувача графа.
        //// Також отримує інтерфейс заново
        //// і налаштовує вікно при sForceRequeryForIt = True.
        //// При sNewSettings = Nil встановлює налаштування вікна, які задані
        //// раніше у SetupVideoWindow або у SetVideoWindowPos.
        //// Якщо важіль вікна sOwner=0 то вікно не створюється і не відображається.

        // Оновлює координати відеокартинки на вікні де вона розташовується.
        // Функція повертає True якщо інтерфейс відображення на заданому вікні
        // IVMRWindowlessControl отриманий і параметри вікна задані:
      Function UpdateVideoWindowPos:Boolean;  //(Const sNewSettings:PVideoWindowInfo = Nil)

        // Допоміжні методи, що використовуються для побудови графа:
      Function CreateFilterGraph(Var sGraphBuilder:IGraphBuilder):Boolean;

      Function RenderStreams(sGraphBuilder: IGraphBuilder;
        sSourceFilterOrPin:IUnknown;
        Var dVideoRenderer:IBaseFilter; Var dAudioRenderer:IBaseFilter;
        sSourceName:String = ''):Boolean; virtual;
      Function CreateVideoRenderer(sGraphBuilder: IGraphBuilder):IBaseFilter; virtual;
      Function CreateAudioRenderer(sGraphBuilder: IGraphBuilder):IBaseFilter; virtual;

      Function AddFilter(sGraphBuilder:IGraphBuilder;
        sFilterCLSID: TGUID;
        Var dFilter:IBaseFilter; Var sdFilterName:String):Boolean;

      Function AddSourceFilter(sGraphBuilder:IGraphBuilder;
        sFilterCLSID: TGUID;
        sUrlOrFileName:String;
        Var dFilter:IBaseFilter; Var dFilterName:String):Boolean; overload;

      Function AddSourceFilter(sGraphBuilder:IGraphBuilder;
        sUrlOrFileName:String;
        Var dFilter:IBaseFilter; Var dFilterName:String):Boolean; overload;

      Function TryRenderToFilters(sCaptureGraphBuilder:ICaptureGraphBuilder2;
           sSourceFilterOrPin: IUnknown;
           sSourceName:String = '';
           Const sSourcePinCategory: PGUID = Nil;
           Const sMediaType: PGUID = Nil;
           sMidFilter:IBaseFilter = Nil;
           sDestFilter:IBaseFilter = Nil):HResult;

      Function TryRenderFromEveryPinToFilters(sCaptureGraphBuilder:ICaptureGraphBuilder2;
           sSourceFilter: IBaseFilter;
           sSourceName:String = '';
           Const sSourcePinCategory: PGUID = Nil;
           Const sMediaType: PGUID = Nil;
           sMidFilter:IBaseFilter = Nil;
           sDestFilter:IBaseFilter = Nil):HResult;

      Function GetMidAndDestFilterExplanation(
           sMidFilter:IBaseFilter = Nil;
           sDestFilter:IBaseFilter = Nil):String;
    public
        //   Налаштування відтворення із графа.
        // Починають діяти при побудові нового графа:
      Property RenderVideo:Boolean read cRenderVideo write SetRenderVideo;
      Property RenderAudio:Boolean read cRenderAudio write SetRenderAudio;

      Property VideoBeingRendered:Boolean read CheckVideoBeingRendered;

        // Для розміщення вікна відтворення відео на заданому вікні, та для
        // оновлення коодинат картинки у вікні.
        // Повертає False, якщо на даний момент відео не готове до відтворення
        // (відсутнє) або вікно відтворення не вдається створити з іншої
        // причини. Проте, навіть в такому випадку параметри вікна
        // запам'ятовуються, і вікно буде відображено
      procedure SetupVideoWindow(sOwner:HWND;
        Left, Top, Width, Height: Longint); override;
        //    RePaint треба викликати коли вікно, на якому відображається відео,
        //  отримує повідомлення WM_PAINT.
      Procedure RePaint(sOwner:HWND; sDC:HDC);
        //    DisplayModeChange треба викликати коли вікно,
        //  на якому відображається відео, отримує повідомлення WM_DISPLAYCHANGE:
      Procedure DisplayModeChange;

      constructor Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
      procedure Terminate; override;
      destructor Destroy; override;
  end;

  TSampleGrabberCapturer = class;

  ISampleGrabberSampleObtainer = interface(ISampleGrabberCB)
       //   Цей метод треба викликати коли SampleGrabberCapturer, що був
       // переданий у конструкторі, звільняється. Після виклику об'єкт не
       // викликає більше SampleCB і BufferCB у SampleGrabberCapturer.
       // Викликати його потрібно тому що при звільненні SampleGrabberCapturer
       // для цього об'єкта метод Destroy може бути не викликаний (якщо на
       // його інтерфейс ще десь є вказівники):
    procedure SampleCapturerFinishedWork;
  end;

  TSampleGrabberSampleObtainer = class(TInterfacedObject,
     ISampleGrabberSampleObtainer)
    private
      //cGraphController:TDirectShowGraphController;
      //cTerminateEvent, cGraphEvent: THandle;

      //cOnSampleCB: TCallFromThreadOnSampleCB;
      //cOnBufferCB: TCallFromThreadOnBufferCB;

           // Використовувати секцію при виклику SampleCapturerFinishedWork:
      cSampleCapSection:TCriticalSection;

      cSampleGrabberCapturer: TSampleGrabberCapturer;
    protected

        //   // Реалізація інтерфейса ISampleGrabberCB.
        //   Передає виклики SampleCB і BufferCB методам
        // SampleCB і BufferCB у SampleGrabberCapturer.
        // Не дотримується ніяких критичних секцій,
        // синхронізації з іншими потоками, так як це не рекомендовано у
        // описі ISampleGrabber::SetCallback через те що граф можна заблокувати
        // цим. Граф сам зупиняється коли ISampleGrabber викликає один із цих
        // методів. Обробник повинен виконати дії із захопленим кадром,
        // скопіювати його куди йому треба, і завершитися. Далі всі дії
        // із даними кадра, що потребують синхронізації із будь-якими потоками,
        // мають виконуватися в іншому потоці.
        //   Правда, критична секція всеодно треба якщо кадр треба кудись
        // копіювати. Пізніша версія MSDN
        // http://msdn.microsoft.com/en-us/library/windows/desktop/dd376992%28v=vs.85%29.aspx
        // вже не згадує про те що не треба використовувати навіть ніяких
        // критичних секцій. При необхідності вони потрібні. Даний клас їх
        // не застосовує.
        //   Реалізовувати достатньо один із методів, виклик якого буде
        // заданий у ISampleGrabber.SetCallback:
      function  SampleCB(SampleTime: Double; pSample: IMediaSample): HResult; stdcall;
      function  BufferCB(SampleTime: Double; pBuffer: PByte; BufferLen: longint): HResult; stdcall;
        //   Цей метод треба викликати коли SampleGrabberCapturer, що був
        // переданий у конструкторі, звільняється. Після виклику об'єкт не
        // викликає більше SampleCB і BufferCB у SampleGrabberCapturer.
        // Викликати його потрібно тому що при звільненні SampleGrabberCapturer
        // для цього об'єкта метод Destroy може бути не викликаний (якщо на
        // його інтерфейс ще десь є вказівники):
      procedure SampleCapturerFinishedWork;
    public
        // Методи Free і Destroy не треба викликати напряму. Треба
        // використовувати об'єкт як інтерфейс і вкінці роботи
        // обнуляти його вказівник. Коли всі вказівники на об'єкт будуть
        // обнулені, буде викликаний метод Destroy.
      Constructor Create(sSampleGrabberCapturer:TSampleGrabberCapturer);

      Destructor Destroy; override;
  end;

    //   TSampleGrabberCapturer отримує кадри відео і записує їх у свій
    // буфер-список. Викликає обробники кадрів зі свого потока.
  TSampleGrabberCapturer = class(TThread)
    private
      cSampleObtainer: ISampleGrabberSampleObtainer;
      cSampleQueriedCount: Cardinal;

      cDataUseSection:TCriticalSection;
      cSampleList: TBMPSampleList;

      cSampleGrabber:ISampleGrabber;
      cGraphController:TPlayVideoGraphController;

      cOnSample: TCallFromThreadOnSample;

      cTerminateEvent, cSampleCapturedEvent: THandle;

      cCurMediaType: PAMMediaType;

      Function ProcGetCurMediaType:PAMMediaType;
      Procedure ProcChangeCurMediaType(sNewMediaType:PAMMediaType);
      Procedure ProcDeleteCurMediaType;

      Procedure SetOnSample(Value:TCallFromThreadOnSample);
    protected
      property SampleGrabber:ISampleGrabber read cSampleGrabber;

        // SampleCB викликається із SampleGrabber-а через ISampleGrabberCB
        //   (TSampleGrabberSampleObtainer).
        // SampleCB копіює кадри у список коли є на те запит (лічильник
        //   запитаних кадрів більше нуля). Якщо лічильник рівний максимальному
        //   числу то він не змінюється (кадри захоплюються необмежено).
        //   Після додавання кадра у список дає команду своєму потоку щоб він
        //   запустив обробку кадрів у списку:
      function  SampleCB(SampleTime: Double; pSample: IMediaSample): HResult;
        // BufferCB не реалізований, повертає E_NOTIMPL:
      function  BufferCB(SampleTime: Double; pBuffer: PByte; BufferLen: longint): HResult;
          //   Налаштування SampleGrabber реалізується у класі-нащадку
          // із конкретним типом даних у відеокадрах:
      function InitSampleGrabber:ISampleGrabber; virtual; abstract;
      Procedure SetCallbackForSampleGrabber;
          //   Виконує обробку (використання) захопленого кадра.
          //   Викликається у потоці цього об'єкта (без синхронізації
          // з іншими потоками).
          //   Після закінчення роботи із кадром пам'ять від
          // структур sSample має бути звільнена
          // (за допомогою FreeBMPData або викликом
          // inherited ProcessSample):
      Procedure ProcessSample(Var sdSample: PBMPSampleRec); virtual; // abstract;

      procedure Execute; override;
    public
        //   Обробник bmp-даних кадра. Ці дані мають лише заголовки у форматі
        // сумісному із BMP. Дані кадра можуть бути стиснені по-різному,
        // залежно від налаштувань у ISampleGrabber, що виконує InitSampleGrabber.
        //   Цей обробник не повинен звільняти пам'ять від записів про кадр,
        // його даних. Він може редагувати їх, якщо йому потрібно (але це не
        // впливає на кадр у графі). Після його роботи дані кадра
        // звільняються автоматично.
      property OnSample:TCallFromThreadOnSample read cOnSample write
        SetOnSample;
         //   CaptureSamples дає запит на отримання кадрів із вказуванням їх
         // кількості. Задана кількість додається до лічильника запитаних кадрів.
         // Кадри захоплюються по можливості послідовно, доки лічильник
         // запитаних не опуститься до нуля. Лічильник не знижується, якщо
         // задати cSamplesCount = c_SamplesInfinite (тоді кадри захоплюються
         // необмежено, доки відтворюється відео).
         //   CaptureSamples(0) не робить ефекту:
      procedure CaptureSamples(cSamplesCount:Cardinal = c_SamplesInfinite);
         //   StopCaptureSamples обнуляє лічильник захоплення кадрів і припиняє
         // їх захоплення:
      procedure StopCaptureSamples;

      constructor Create(sGraphController:TPlayVideoGraphController = Nil;
        CreateSuspended:Boolean = False);
      destructor Destroy; override;
      procedure Terminate; virtual;
  end;

  TSampleGrabberRGB24BMPCapturer = class(TSampleGrabberCapturer)
    protected
      function InitSampleGrabber:ISampleGrabber; override;
  end;

  TCaptureImageGraphController = class(TPlayVideoGraphController)
    private
      cRenderSamples:Boolean;

      cSampleGrabberCapturer: TSampleGrabberCapturer;

      cOnSample: TCallFromThreadOnSample;

      cSampleQueriedCount: Cardinal;

      Procedure SetRenderSamples(Value:Boolean);
      Procedure SetOnSample(Value:TCallFromThreadOnSample);
      Procedure SetSampleGrabberCapturer(Value:TSampleGrabberCapturer);

      Procedure ProcAfterStop(sCaller: TThread;
        Const sState, sLastState:TFilterState;
        sSTATE_INTERMEDIATE, sCANT_CUE:Boolean;
        sStateRes, sLastStateRes:HResult;
         sCurURL, sLastURL, sCurName_ch:String);
    protected
      property SampleGrabberCapturer: TSampleGrabberCapturer read
        cSampleGrabberCapturer write SetSampleGrabberCapturer;

      Function RenderStreams(sGraphBuilder: IGraphBuilder;
        sSourceFilterOrPin:IUnknown;
        Var dVideoRenderer:IBaseFilter; Var dAudioRenderer:IBaseFilter;
        sSourceName:String = ''):Boolean; override;
      Function CreateNullRenderer(sGraphBuilder: IGraphBuilder):IBaseFilter;
      //Function CreateVideoRenderer(sGraphBuilder: IGraphBuilder):IBaseFilter; override;
    public
        //   Вмикач захоплення кадрів для отримання фотографій.
        // Якщо вимкнений то граф не захоплює фотографії (і працює як
        // TPlayVideoGraphController).
        //   Параметр починає діяти при побудові нового графа
        // (запуска відтворення чи паузи з перебудовою графа):
      Property RenderSamples:Boolean read cRenderSamples write SetRenderSamples;

        //   Обробник bmp-даних кадра. Ці дані мають лише заголовки у форматі
        // сумісному із BMP. Дані кадра можуть бути стиснені по-різному,
        // залежно від налаштувань у ISampleGrabber, що виконує InitSampleGrabber.
        //   Цей обробник не повинен звільняти пам'ять від записів про кадр,
        // його даних. Він може редагувати їх, якщо йому потрібно (але це не
        // впливає на кадр у графі). Після його роботи дані кадра
        // звільняються автоматично.
      property OnSample:TCallFromThreadOnSample read cOnSample write
        SetOnSample;

         //   CaptureSamples дає запит на отримання кадрів із вказуванням їх
         // кількості. Задана кількість додається до лічильника запитаних кадрів.
         // Кадри захоплюються по можливості послідовно, доки лічильник
         // запитаних не опуститься до нуля. Лічильник не знижується, якщо
         // задати cSamplesCount = c_SamplesInfinite (тоді кадри захоплюються
         // необмежено, доки відтворюється відео).
         //   CaptureSamples(0) не робить ефекту:
      procedure CaptureSamples(cSamplesCount:Cardinal = c_SamplesInfinite);
         //   StopCaptureSamples обнуляє лічильник захоплення кадрів і припиняє
         // їх захоплення:
      procedure StopCaptureSamples;

      constructor Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
      procedure Terminate; override;
      destructor Destroy; override;
  end;

  TCaptureBitmapGraphController = class(TCaptureImageGraphController)
    private
      cOnSampleAsBitmap: TCallFromThreadOnSampleAsBitmap;

      Procedure ProcOnSample(sCaller: TThread;
        sSample:PBMPSampleRec);

      Procedure SetOnSampleAsBitmap(Value: TCallFromThreadOnSampleAsBitmap);
    public
      property OnSample: TCallFromThreadOnSampleAsBitmap read cOnSampleAsBitmap
        write SetOnSampleAsBitmap;
      constructor Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
  end;

  TCaptureJpegGraphController = class(TCaptureBitmapGraphController)
    private
      cOnSampleAsJpeg: TCallFromThreadOnSampleAsJpeg;
      cCompressionQuality: TJpegQualityRange;

      Procedure ProcOnSample(sCaller: TThread;
        sSample:Graphics.TBitmap);

      Procedure SetOnSampleAsJpeg(Value: TCallFromThreadOnSampleAsJpeg);
    public
      property OnSample: TCallFromThreadOnSampleAsJpeg read cOnSampleAsJpeg
        write SetOnSampleAsJpeg;
      property CompressionQuality: TJpegQualityRange read cCompressionQuality
        write cCompressionQuality;
      constructor Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
  end;

  TCaptureJpegToFileGraphController = class(TCaptureJpegGraphController)
    private
      cOnSampleAsJpegFile: TCallFromThreadOnSampleAsFile;
      cFileDir, cFileNameStart, cFileExt:String;
      cCounter: Cardinal;

      Procedure ProcOnSample(sCaller: TThread; sSample:TJpegImage);

      Procedure SetOnSampleAsJpegFile(Value: TCallFromThreadOnSampleAsFile);
    public
      property OnSample: TCallFromThreadOnSampleAsFile read cOnSampleAsJpegFile
        write SetOnSampleAsJpegFile;
      constructor Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False;
              sFilePathAndBaseName:String = '');
  end;

  // Читання опису результата функції DirectShow:
Function HResultToStr(Const sCommentToError:String; sResult:HResult):String;

{Перенесено в модуль UEventHelper:
// Управління об'єктами подій (Windows.CreateEvent):
Function ProcCreateEvent(Const sMessageOnError:String;
   bManualReset: Windows.BOOL = True; bInitialState: Windows.BOOL = True;
   lpName: PWideChar = Nil; sLogFile:TLogFile = Nil):Windows.THandle;
Function ProcSetEvent(sEvent:THandle; Const sMessageOnError:String;
      sLogFile:TLogFile = Nil):Boolean;
function ProcResetEvent(sEvent:THandle; Const sMessageOnError:String;
      sLogFile:TLogFile = Nil):Boolean;
Procedure ProcCloseHandle(Var sHandle:THandle; Const sMessageOnError:String;
  sLogFile:TLogFile = Nil);}

Function GetFilterInfo(sIBaseFilter:IBaseFilter):TFilterInfo; overload;

//Function GetFilterInfo(sIFilterInfo:IFilterInfo;
//  var dName, dVendorInfo: WideString):Boolean; overload;

Function GetFilterInfo(sIBaseFilter:IBaseFilter;
  var dName, dNameInGraph, dVendorInfo: WideString):Boolean; overload;

Function GetPinInfo(sIPin:IPin; Var dPinInfo:TPinInfo):Boolean;

Function GetPinAndFilterInfo(sIPin:IPin; Var dPinName:String;
   Var dPinDirection:TPinDirection;
   Var dFilterName, dFilterNameInGraph, dVendorInfo: WideString):Boolean;

Function GetPinAndOrFilterName(sObject:IUnknown; Var dName:String;
           Var dErrorMessage:String):Boolean;

Function GetSndDevErrStr(cErr:TSndDevErr):String;

Procedure GetWindowInfo(sWindow:HWND; dText:String; dClassName:String);

Procedure Get16Words(Const cLongWord:LongWord; Var cLowWord, cHighWord:Word);
Procedure Put16WordsToLong(Var cLongWord:LongWord; Const cLowWord, cHighWord:Word);

Procedure GetBytesFromLongWord(Const cLongWord:LongWord;
  Var dB0, dB1, dB2, dB3:Byte);

Function GetStrWordCoordsFromLongWord(Const cLongWord:LongWord):String;
Function GetStrDVD_HMSF_TIMECODE(Const cLongWord:LongWord):String;

Procedure GetDVD_TIMECODE_FLAGS(Const sFlags:LongWord; Var d25fps, d30fps,
  dDropFrame29_97, dTC_FLAG_Interpolated:Boolean);
Function GetStrDVD_TIMECODE_FLAGS(Const sFlags:LongWord):String;

Function GetDVD_DOMAINStr(Const sDomain: DVD_DOMAIN):String;

Function GetDVD_ERRORStr(Const sError:DVD_ERROR; Const sParam2:LongWord):String;

Function GetDVD_PB_STOPPEDStr(Const sDVD_PB_STOPPED:DVD_PB_STOPPED):String;

Function GetVALID_UOP_FLAGStr(Const sFlags:VALID_UOP_FLAG):String;

Function GetDVD_WARNINGStr(Const sDVD_WARNING:DVD_WARNING;
  Const Param2: LongWord):String;

  // Для читання одної події із черги подій DirectShow (і її параметрів):

//Function GetDShowEventParameters(Const sIMediaEvent:IMediaEvent;
//           Var dEvCode:Longint; dlParam1, dlParam2:Longint):Boolean;

// ProcDShowEvent витягує параметри повідомлення DirectShow.
// sMessageLogProc - процедура для запису журналу повідомлень.
// sCurThread передається для sMessageLogProc. sCurThread - об'єкт потока,
// із яким може синхронізуватися головний потік програми для виконання
// sMessageLogProc (при потребі). Якщо sCurThread = Nil, то
// виконується автосинхронізація головного потока із [поточним].
Function ProcDShowEvent(sIMediaEvent:IMediaEvent;
           sHandler: TProcDShowEvent;
           sMessageLogProc:TMessageLogProc = Nil;
           sCurThread:TThread = Nil):Boolean;

  // Процедури для отримання описів параметрів подій DirectShow:
Function GetDShowEventExplanation(Event, Param1, Param2: Integer;
           Var dEventDefineName, dEventData:String):Boolean; overload;

Function GetDShowEventExplanation(sIMediaEvent:IMediaEvent;
           Var dEventDefineName, dEventData:String):Boolean; overload;


    // Виділяє пам'ять і копіює дані про заголовок і буфер кадра:
Function AllocateBMPData(sHeader: PBitmapInfoHeader;
          pBuffer:PByte; sBufferSize: Longint;
          sSampleTime:Double):PBMPSampleRec;
    // Викликається для елементів що точно не у списку.
Procedure FreeBMPData(Var sdData:PBMPSampleRec);

implementation

const cs_InGraph='в графі "';

constructor TDirectShowGraphEventHandler.Create(
        sGraphController:TDirectShowGraphController;
        sGraphBuilder:IGraphBuilder);
const cs_ProcName = 'TDirectShowGraphEventHandler.Create';
Begin
  Inherited Create(True);

  Self.FreeOnTerminate:=False;

  Self.cGraphController:= sGraphController;

  Self.cTerminateEvent:= ProcCreateEvent(cs_ProcName +
        cs_FailedToCreateEvent + cs_AboutThreadStopCommand +
        c_SystemSays,
       True,   // після виникнення скидається вручну (у цій програмі). Можна автоматом, яле тоді система сама скине якщо це було в іншому потоці і той інший завершився вже.
       False,   // подія створюється такою що ще не відбулася.
       Nil,   // подія не має імені (воно не треба, бо інші процеси цю подію не використовують і її важіль не успадковують)
       Self.cGraphController.LogFile);  // об'єкт для передачі повідомлень

  Self.cGraphEvent:= 0;  // об'єкт подій графа створюється інтерфейсом графа
  Self.cOnGraphEvent:= Nil;

  Self.cMediaEvent:= Nil;
    // Секція роботи із інтерфейсом подій графа:
  cMediaEventUseSection:= TCriticalSection.Create;
    // Слухаємо події графа, якщо він заданий:
  Self.InitDSMessageHandler(sGraphBuilder);
  //Self.ChangeGraph(sGraphBuilder);

  Self.Resume;
End;

destructor TDirectShowGraphEventHandler.Destroy;
const cs_ProcName = 'TDirectShowGraphEventHandler.Destroy';
Begin
  if Not(Self.Finished) then
  Begin
    Self.Terminate;
    Self.WaitFor;
  End;

     // Завершуємо слухати події графа:
  Self.StopDSMessageHandler;

  ProcCloseHandle(Self.cTerminateEvent,
     cs_ProcName +
      ': не вдалося закрити об''єкт події закриття потока читання подій графа... ' +
       c_SystemSays,
     Self.cGraphController.LogFile);

  Self.cMediaEvent:= Nil;

  Self.cOnGraphEvent:= Nil;
  Self.cGraphEvent:= 0;

  SysUtils.FreeAndNil(Self.cMediaEventUseSection);

  Self.cGraphController:= Nil;

  Inherited Destroy;
End;

procedure TDirectShowGraphEventHandler.Terminate;
const cs_ProcName = 'TDirectShowGraphEventHandler.Terminate';
Begin
     // Спочатку встановлюємо помітку про те що треба завершувати роботу:
  Inherited Terminate;
     // Потім даємо команду завершити роботу щоб потік почув її
     // якщо зараз чекає на подію:

  ProcSetEvent(Self.cTerminateEvent, cs_ProcName +
        cs_FailedToSetEvent+cs_AboutThreadStopCommand+
          c_SystemSays,
       Self.cGraphController.LogFile);

     // Якщо потік спить - будимо щоб він завершив роботу:
  while Self.Suspended do Self.Resume;
End;

//InitDSMessageHandler викликається перед запуском потока.
Function TDirectShowGraphEventHandler.InitDSMessageHandler(
           sGraphBuilder:IGraphBuilder):Boolean;
const cs_ProcName = 'TDirectShowGraphEventHandler.InitDSMessageHandler';
Var Res1:HResult;
    cGraphEventHandle:OAEVENT;
    cCurProcPseudoHandle:THandle;
Begin
  //InitDSMessageHandler викликається перед запуском потока і тільки один раз,
  //тому критична секція тут не потрібна.
  //Self.cMediaEventUseSection.Enter;
  //try

  if Assigned(sGraphBuilder) then
  Begin
    Result:= True;

    Self.cMediaEvent:= Nil;
    Res1:= sGraphBuilder.QueryInterface(IID_IMediaEventEx, Self.cMediaEvent);
    if Failed(Res1) then
    Begin
      Self.cGraphController.LogMessage(Self.cGraphController, // InitDSMessageHandler викликається із конструктора у потоці cGraphController.
        HResultToStr(cs_ProcName +
        ': не вдалося отримати інтерфейс IMediaEventEx від графа: ', Res1));
      Self.cMediaEvent:= Nil;
      Result:= False;
    End
    else
    Begin
      Res1:= Self.fMediaEvent.SetNotifyFlags(0);
      if Failed(Res1) then
      Begin
        Self.cGraphController.LogMessage(Self.cGraphController, // викликається із конструктора у потоці cGraphController
          HResultToStr(cs_ProcName +
          ': fMediaEvent.SetNotifyFlags повідомило про помилку: ', Res1));
        Result:= False;
      End;

      cGraphEventHandle:= 0;

      Res1:=Self.fMediaEvent.GetEventHandle(cGraphEventHandle);
      if Failed(Res1) then
      Begin
        Self.cGraphController.LogMessage(Self.cGraphController, // викликається із конструктора у потоці cGraphController
          HResultToStr(cs_ProcName +
          ': fMediaEvent.GetEventHandle не дало об''єкт подій графа, повідомило про помилку: ',
           Res1));
        Result:= False;
      End
      else
      Begin
        Self.cGraphEvent:= 0;
          //   Дублюємо важіль об'єкта подій графа щоб мати його незалежно від
          // того чи звільниться граф. Свій важіль граф сам звільнить.
          // Дубльований важіль звільняється в цьому об'єкті:
        cCurProcPseudoHandle:= Windows.GetCurrentProcess;
        If Not(Windows.DuplicateHandle(cCurProcPseudoHandle, cGraphEventHandle,
          cCurProcPseudoHandle,
          Addr(Self.cGraphEvent),
          0, //is ignored if the dwOptions parameter specifies the DUPLICATE_SAME_ACCESS flag
          False,
          DUPLICATE_SAME_ACCESS)) then
        Begin
          Self.cGraphController.LogMessage(Self.cGraphController, // викликається із конструктора у потоці cGraphController
            FormatLastOSError(cs_ProcName +
              ': Windows.DuplicateHandle повідомило про помилку: ').Message);
          Self.cGraphEvent:= 0;
          Result:= False;
        End;
      End;
    End;
  End
  Else Result:= False;

  //finally
  //  Self.cMediaEventUseSection.Leave;
  //end;
End;

//StopDSMessageHandler викликається після завершення роботи потока.
Procedure TDirectShowGraphEventHandler.StopDSMessageHandler;
const cs_ProcName = 'TDirectShowGraphEventHandler.StopDSMessageHandler';
Begin
  ProcCloseHandle(Self.cGraphEvent, //Self.cTerminateEvent,
     cs_ProcName +
      ': не вдалося закрити важіль подій графа... ' +
       c_SystemSays,
     Self.cGraphController.LogFile);
  Self.cMediaEvent:=Nil;
End;

Procedure TDirectShowGraphEventHandler.SetOnGraphEvent(
            Value: TCallFromThreadOnGraphEvent);
Begin
  //if Addr(Self.cOnGraphEvent) <> Addr(Value) then
    Self.cOnGraphEvent:= Value;
End;

procedure TDirectShowGraphEventHandler.Execute;
Const cs_ProcName = 'Потік TDirectShowGraphEventHandler.Execute';
  c_EventCount = 2;
  c_GraphEventIndex = 0;
  c_TerminateCommandIndex = 1;
  //c_WaitTimeOut = Windows.INFINITE;
  c_WaitTimeOut = 180000; // 3 хвилини
Var
   cHandleArray: array [0..c_EventCount - 1] of THandle;
   cSignal:DWord;
   cInitRes: HResult;
Begin

  try
    Self.cGraphController.LogMessage(Self, cs_ProcName+ sc_StartsItsWork);

    cInitRes:= CoInitializeEx(Nil, COINIT_MULTITHREADED); //COINIT_APARTMENTTHREADED

    if Failed(cInitRes) then
    Begin
      Self.cGraphController.LogMessage(Self, HResultToStr(cs_ProcName +
       cs_CoInitializeExFailed,
        cInitRes));
    End;

    while not(Self.Terminated) do
    Begin
      if Not(Assigned(Self.cMediaEvent)) then
      Begin
        Self.Suspend;
        Continue;
      End;

      if Self.cGraphEvent = 0 then
      Begin
        Self.Suspend;
        Continue;
      End;

         // Масив подій, на які треба очікувати:
      cHandleArray[c_GraphEventIndex]:= Self.cGraphEvent; // події графа
      cHandleArray[c_TerminateCommandIndex]:= Self.cTerminateEvent; // подія команди завершення потока

        // Очікуємо одну із можливих подій:
      cSignal:= Windows.WaitForMultipleObjects(c_EventCount,
        Addr(cHandleArray[0]), False, c_WaitTimeOut);

      case cSignal of
        Windows.WAIT_FAILED:
        Begin
          Self.cGraphController.LogMessage(Self, FormatLastOSError(cs_ProcName +
            ': очікування на подію графа повідомило про помилку: ').Message);
            // Спимо щоб не навантажувати процесор:
          Windows.Sleep(c_EmergencySleepTime);
          Continue;
        End;
        Windows.WAIT_OBJECT_0 + c_GraphEventIndex: // подія графа:
        Begin
          Self.cGraphController.cGraphBuilderUseSection.Enter;
          try
            while ProcDShowEvent(Self.cMediaEvent,
              Self.DShowEventParamHandler, Self.cGraphController.LogMessage,
              Self) do;
          finally
            Self.cGraphController.cGraphBuilderUseSection.Leave;
          end;

          //Self.cMediaEvent.GetEvent()
          //Self.DShowEventParamHandler();
        End;
        Windows.WAIT_OBJECT_0 + c_TerminateCommandIndex:;
        Windows.WAIT_TIMEOUT:
        Begin
          if Self.cGraphController.cLastStateRes = VFW_S_STATE_INTERMEDIATE then
          Begin
            Self.cGraphController.LogMessage(Self,
              cs_ProcName +
              ': у графі з інтерфейсом подій IMediaEventEx за адресою '+
              IntToStr(Cardinal(Self.cMediaEvent))+ ' не сталося подій протягом '+
              IntToStr(c_WaitTimeOut) +
              ' мс у перехідному стані. Можливо граф завис... Буде перезапущений...');
            Self.cGraphController.QueryNewState('','', True,
              Self.cGraphController.cDestState);
          End;

          //Self.cGraphController.LogMessage(Self, cs_ProcName +
          //  ': у графі з інтерфейсом подій IMediaEventEx за адресою '+
          //  IntToStr(Cardinal(Self.cMediaEvent))+ ' не сталося подій протягом '+
          //  IntToStr(c_WaitTimeOut) + ' мс.');
        End;
        Else
        Begin
          Self.cGraphController.LogMessage(Self, cs_ProcName +
            cs_UnknownResultOnWaitingEvent+
            IntToStr(cSignal)+'...');
            // Спимо щоб не навантажувати процесор:
          Windows.Sleep(c_EmergencySleepTime);
        End;
      end; // case cSignal of...
    End; // while not(Self.Terminated) do...

    if Not(Failed(cInitRes)) then
      CoUnInitialize;

    Self.cGraphController.LogMessage(Self, cs_ProcName+sc_FinishedItsWork);
  except
    on E:Exception do
    begin
      Self.cGraphController.LogMessage(Self, cs_ProcName + sc_FallenOnError+
        E.ToString);
    end;
  end;
End;

Procedure TDirectShowGraphEventHandler.DShowEventParamHandler(cEvCode:Longint;
        lParam1, lParam2:Longint);
const cs_ProcName = 'TDirectShowGraphEventHandler.DShowEventParamHandler';
var cEventDefineName, cEventData:String; cMessage:String;
    //cNeedReopen:Boolean;
    ccOnGraphEvent:TCallFromThreadOnGraphEvent;
    ccIntermediateState, ccCantCueState: Boolean; ccStateRes:HResult;
Begin
    // Записуємо у журнал всі події графа:
 If UDirectShowHelp.GetDShowEventExplanation(cEvCode, lParam1, lParam2,
           cEventDefineName, cEventData) then
  Begin
    cMessage:= cEventDefineName;
      if Not(cEventData = '') then
        cMessage:= cMessage + cs_NewLine + '    '+ cEventData;

    Self.cGraphController.LogMessage(Self, cMessage);
  End;

    // Викликаємо додатковий обробник події, якщо він заданий:
    //   Запам'ятовуємо поточне посилання на обробник щоб працювати з ним
    // в цьому виклику процедури, навіть якщо інший потік змінить його в ході
    // обробки цієї події (обробник починає діяти на початку
    // обробки нової події):
  ccOnGraphEvent:= Self.OnGraphEvent;

  if Assigned(ccOnGraphEvent) then
  Begin
    try
      ccOnGraphEvent(Self, cEvCode, lParam1, lParam2,
        cEventDefineName, cEventData);
    except
      on E:Exception do
      Begin
        Self.cGraphController.LogMessage(Self, cs_ProcName +
          ': при роботі обробника події графа OnGraphEvent сталося виключення :' +
          E.ToString);
      End;
    end;
  End;
    //   Якщо задано зовнішній обробник зміни стану графа, то
    // читаємо поточний стан графа і викликаємо обробник зміни стану
    // якщо стан змінився:
  if Assigned(Self.cGraphController.OnStateChange) then
  Begin
    Self.cGraphController.GetRunningState(Self,
          ccIntermediateState,
          ccCantCueState, ccStateRes, 0);
  End;
End;

constructor TProcVideoGraphControllerQueryThread.Create(
        sGraphController:TPlayVideoGraphController = Nil;
        CreateSuspended:Boolean = False);
Begin
  Inherited Create(True);

  Self.cGraphController:= sGraphController;
  if Not(CreateSuspended) then Self.Resume;
End;

destructor TProcVideoGraphControllerQueryThread.Destroy;
Begin
  if Not(Self.Finished) then
  Begin
    Self.Terminate;
    Self.WaitFor;
  End;

  Self.cGraphController:= Nil;

  Inherited Destroy;
End;

procedure TProcVideoGraphControllerQueryThread.Terminate;
Begin
    // Спочатку встановлюємо помітку про те що треба завершувати роботу:
  Inherited Terminate;

    // Якщо потік спить - будимо щоб він завершив роботу:
  while Self.Suspended do Self.Resume;
End;

procedure TProcVideoGraphControllerQueryThread.Execute;
Const cs_ProcName = 'Потік TProcVideoGraphControllerQueryThread.Execute';
Var cRes, cInitRes:HResult;
    ccRepaintQuery, ccDisplayModeChangeQuery: Boolean;
    ccPaintOwner, ccCurOwner, ccNewWindOwner: HWnd;
    ccPaintDC: HDC;

    ccWindowChangeQuery:Boolean;
    ccDestState: TFilterState;
    ccDone, ccBRes, ccRenderVideo:Boolean;
Begin
  try
    Self.cGraphController.LogMessage(Self, cs_ProcName+ sc_StartsItsWork);

    cInitRes:= CoInitializeEx(Nil, COINIT_MULTITHREADED); //COINIT_APARTMENTTHREADED

    if Failed(cInitRes) then
    Begin
      Self.cGraphController.LogMessage(Self, HResultToStr(cs_ProcName +
        cs_CoInitializeExFailed,
        cInitRes));
    End;

      // Потік виконує один запит (задані в параметрах cGraphController операції)
      // і засинає доти доки його знову не розбудять
      // для виконання наступного запиту:
    while not(Self.Terminated) do
    Begin
      Self.cGraphController.cDestStateUseSection.Enter;
      try
        ccRepaintQuery:= Self.cGraphController.cRepaintQuery;
        ccPaintOwner:= Self.cGraphController.cPaintOwner;
        ccPaintDC:= Self.cGraphController.cPaintDC;

        ccCurOwner:= Self.cGraphController.cVideoWindowInfo.sOwner;

        ccDisplayModeChangeQuery:= Self.cGraphController.cDisplayModeChangeQuery;

        ccWindowChangeQuery:= Self.cGraphController.cWindowChangeQuery;
        //cVideoWindowInfo <>  Self.cGraphController.cVideoWindowNewSettings;

        ccNewWindOwner:= Self.cGraphController.cVideoWindowNewSettings.sOwner;
        ccDestState:= Self.cGraphController.cDestState;

        ccRenderVideo:= Self.cGraphController.RenderVideo;
      finally
        Self.cGraphController.cDestStateUseSection.Leave;
      end;

      ccDone:= True;

      if ccRenderVideo then // обробка команд, які виконуються тільки для відображення відео
      Begin
        if ccRepaintQuery then
        Begin
          cRes:= S_False;
             // Якщо вікно відображення відео не було задане - то відео просто
             // може бути ще не зщапущене, і попереджень писати та перемалювання робити не треба:
          if Not(ccCurOwner = 0) then
          Begin
            if ccCurOwner<>ccPaintOwner then
            Begin
              Self.cGraphController.LogMessage(Self, cs_ProcName+
                ': для перемалювання задано не поточне вікно: зараз відеовікном є '+
                IntToStr(ccCurOwner)+
                ', задано перемалювати ' + IntToStr(ccPaintOwner) +
                '. Буде перемальовано поточне...');
              ccPaintOwner:= ccCurOwner;
            End;

            //Else
            //Begin
            Self.cGraphController.cGraphBuilderUseSection.Enter;
            try
              //Self.cGraphController
              if Assigned(Self.cGraphController.cVMRWindowlessControl) then
              Begin
                cRes:= Self.cGraphController.cVMRWindowlessControl.RepaintVideo(
                  ccPaintOwner, ccPaintDC);
                if Failed(cRes) then
                Begin
                  Self.cGraphController.LogMessage(Self,
                    HResultToStr(cs_ProcName +
                    ': cVMRWindowlessControl.RepaintVideo повідомило:', cRes));
                End;
              End;
            finally
              Self.cGraphController.cGraphBuilderUseSection.Leave;
            end;

            if cRes = S_OK then
            Begin
                 // Запит виконано, скидаємо прапорець:
              Self.cGraphController.cDestStateUseSection.Enter;
              try
                Self.cGraphController.cRepaintQuery:= False;
              finally
                Self.cGraphController.cDestStateUseSection.Leave;
              end;
            End
            else ccDone:= False;
          End;
        End;

        if ccDisplayModeChangeQuery then
        Begin
          cRes:= S_False;

          Self.cGraphController.cGraphBuilderUseSection.Enter;
          try
            if Assigned(Self.cGraphController.cVMRWindowlessControl) then
            Begin
              cRes:= Self.cGraphController.cVMRWindowlessControl.DisplayModeChanged;

              if Failed(cRes) then
              Begin
                Self.cGraphController.LogMessage(Self,
                  HResultToStr(cs_ProcName +
                  ': cVMRWindowlessControl.DisplayModeChanged повідомило:', cRes));
              End;
            End;
          finally
            Self.cGraphController.cGraphBuilderUseSection.Leave;
          end;

          if cRes = S_OK then
          Begin
               // Запит виконано, скидаємо прапорець:
            Self.cGraphController.cDestStateUseSection.Enter;
            try
              Self.cGraphController.cDisplayModeChangeQuery:= False;
            finally
              Self.cGraphController.cDestStateUseSection.Leave;
            end;
          End
          else ccDone:= False;
        End;

        if ccWindowChangeQuery then
        Begin
          //cRes:= S_False;
          ccBRes:= True;

          if (ccDestState <> State_Stopped)
            and (ccCurOwner <> ccNewWindOwner) then
          Begin  // перезапустити граф, якщо треба нове вікно:
            ccBRes:= Self.cGraphController.QueryNewState('', '', True, ccDestState)
              and ccBRes;
          End  // якщо не треба міняти вікно - тільки оновлюємо координати картинки у вікні:
          Else ccBRes:= Self.cGraphController.UpdateVideoWindowPos
            and ccBRes;

          if ccBRes then
          Begin
                    // Запит виконано, скидаємо прапорець:
            Self.cGraphController.cDestStateUseSection.Enter;
            try
              Self.cGraphController.cWindowChangeQuery:= False;
            finally
              Self.cGraphController.cDestStateUseSection.Leave;
            end;
          End
          else ccDone:= False;
        End;
      End; // if ccRenderVideo then...

      if ccDone then
        Self.Suspend
      Else Windows.Sleep(c_EmergencySleepTime);
    End;  // while not(Self.Terminated) do...

    if Not(Failed(cInitRes)) then
      CoUnInitialize;
    Self.cGraphController.LogMessage(Self, cs_ProcName+sc_FinishedItsWork);
  except
    on E:Exception do
    begin
      Self.cGraphController.LogMessage(Self, cs_ProcName + sc_FallenOnError+
        E.ToString);
    end;
  end;
End;

constructor TDirectShowGraphController.Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
const cs_ProcName = 'TDirectShowGraphController.Create';
Begin
  Inherited Create(True);

  Self.FreeOnTerminate:=False;

  Self.cLogFile:= sLogFile;

  Self.cDoRebuildGraph:= False;  // вмикач обов'язкової перебудови графа

  // Так як на інші об'єкти і події потік не очікує, то для нього очікування
  // команди завершуватися разом із ними не потрібне, тому це прибрав:
  // Self.cTerminateEvent:= ProcCreateEvent(cs_ProcName +
  //   cs_FailedToCreateEvent + cs_AboutThreadStopCommand +
  //      c_SystemSays,
  //   True,   // після виникнення скидається вручну (у цій програмі). Можна автоматом, яле тоді система сама скине якщо це було в іншому потоці і той інший завершився вже.
  //   False,   // подія створюється такою що ще не відбулася.
  //   Nil,   // подія не має імені (воно не треба, бо інші процеси цю подію не використовують і її важіль не успадковують)
  //   Self.cLogFile);  // об'єкт для передачі повідомлень

  Self.cOnStateChange:= Nil;
  Self.cOnGraphEvent:= Nil;

      // Поточний мережевий потік чи файл:
  Self.cUrl:= '';
  Self.cLastURL:=Self.cUrl;
  Self.cName_ch:= '';

      // Потік, який треба запустити:
  Self.cDestUrl:= '';
  Self.cDestChName:= '';
  Self.cDestUrlIsLocal:= False;
    // Перемотки спочатку не треба:
  Self.cNewPositionQueried:= False;
  Self.cDestPosition:= 0;
  Self.cDestPositionIsRelative:= False;
    // Поточний тип часу графа буде прочитаний із нього при створенні графа:
  Self.cTimeFormat:= GUID_NULL;
    //   Бажаний тип часу графа не заданий. Буде заповнений поточним
    // якщо буде не заданий:
  Self.cDestTimeFormat:= GUID_NULL;

      // Стан, в який задано встановити граф відтворення:
  Self.cDestState:= State_Stopped;

  Self.cLastState:= State_Stopped;
  Self.cLastStateRes:= S_OK;
      // Секція доступа до змінних потрібного стану:
  Self.cDestStateUseSection:= TCriticalSection.Create;
      // Cекція доступа до будувача графа:
  Self.cGraphBuilderUseSection:= TCriticalSection.Create;

      //Інтерфейси DirectShow:
      // Спочатку будувача графа нема.
      // Він створюється щоразу новий при перебудові!..:
  Self.cGraphBuilder:= Nil;

  Self.cMediaControl:=Nil;
  Self.cMediaSeeking:= Nil;

  //      //   Інтерфейс вікна відтворення відео. Ініціюється тільки при
  //      // виклику SetupVideoWindow:
  //Self.cVideoWindow:= Nil;
  Windows.ZeroMemory(Addr(Self.cVideoWindowInfo), SizeOf(Self.cVideoWindowInfo));
  Windows.ZeroMemory(Addr(Self.cVideoWindowNewSettings),
    SizeOf(Self.cVideoWindowNewSettings));

   // // Створюємо оброблювач подій графа з нульовим графом. Він
   // // не буде запускати слідкування за подіями доки йому не буде призначено
   // // новий граф:
   //Ні, бо зміна графа у об'єкті очікування на події не реалізована, і
   //якщо її реалізувати - робота потока того об'єкта буде ускладненою.
   //Краще завершувати старий і створювати новий потік очікування подій для
   //нового графа..
   //  Тому спочатку немає графа і немає потока очікування подій:
  Self.cEventHandler:= Nil;
    //TDirectShowGraphEventHandler.Create(Self, FGraphBuilder);

  Self.cAfterStop:= Nil;
  Self.cAfterPause:= Nil;
  Self.cAfterRun:= Nil;

  if Not CreateSuspended then Self.Resume;
End;

destructor TDirectShowGraphController.Destroy;
const cs_ProcName = 'TDirectShowGraphController.Destroy';
Begin
  if Not(Self.Finished) then
  Begin
    Self.Terminate;
    Self.WaitFor;
  End;

  SysUtils.FreeAndNil(Self.cEventHandler);

    // Звільнення COM-інтерфейсів:
  Self.FGraphBuilder:= Nil;

  //Self.FMediaControl:=Nil;
        //   Інтерфейс вікна відтворення відео. Ініціюється тільки при
        // виклику SetupVideoWindow:
  //Self.FVideoWindow:= Nil;

  // Так як на інші об'єкти і події потік не очікує, то для нього очікування
  // команди завершуватися разом із ними не потрібне, тому це прибрав:
  // ProcCloseHandle(Self.cTerminateEvent,
  //   cs_ProcName + ': не вдалося закрити об''єкт події закриття потока роботи з графом... ' +
  //     c_SystemSays,
  //   Self.cLogFile);


  Self.cOnStateChange:= Nil;
  Self.cOnGraphEvent:= Nil;

  SysUtils.FreeAndNil(Self.cDestStateUseSection);
  SysUtils.FreeAndNil(Self.cGraphBuilderUseSection);

  Self.cLogFile:= Nil;

  Inherited Destroy;
End;

procedure TDirectShowGraphController.Terminate;
const cs_ProcName = 'TDirectShowGraphController.Terminate';
Begin
    // Спочатку встановлюємо помітку про те що треба завершувати роботу:
  Inherited Terminate;
     // Якщо потік налаштування графа завершується то і потік обробки його подій
     // теж завершується:
  If Assigned(Self.cEventHandler) then
    Self.cEventHandler.Terminate;
      // Якщо потік спить - будимо щоб він завершив роботу:
  while Self.Suspended do Self.Resume;

  // Так як на інші об'єкти і події потік не очікує, то для нього очікування
  // команди завершуватися разом із ними не потрібне, тому це прибрав:
  //   // А потім уже подаємо про те сигнал:
  //   // Встановлюємо сигнал про те що треба завершити процедуру (потік) читання:
  // ProcSetEvent(Self.cTerminateEvent, cs_ProcName +
  //    cs_FailedToSetEvent+cs_AboutThreadStopCommand+
  //      c_SystemSays,
  //   Self.cLogFile);
End;

Function TDirectShowGraphController.GetBitmapHeaderFromMEDIA_TYPEStruct(
        Const sMediaType:TAMMediaType;
        var dBMIInfo: TBitmapInfoHeader;
        sStreamNumber:Cardinal = 0):Boolean;
Const cs_ProcName = 'TDirectShowGraphController.GetBitmapHeaderFromMEDIA_TYPEStruct';
    Procedure ProcLogTooLittleRecLength(Const sRecName:String;
      sLength, sNormalLength:Integer);
    Begin
      Self.LogMessage(Nil,   // невідомо з якого потока, може запускатися із різних
        cs_ProcName + ': '+sRecName+' надто короткий: вказано '+
        IntToStr(sLength)+', має бути '+IntToStr(sNormalLength) + ' байт.');
    End;
//Var cCurStreamNum:DWord;
Begin
  Result:= False;
  Windows.ZeroMemory(Addr(dBMIInfo), SizeOf(dBMIInfo));
      // Шукаємо структуру TBitmapInfoHeader в структурі типу медіа:
  //case sMediaType.formattype of
  //  GUID_NULL:;
  //  FORMAT_None:;

  if IsEqualGUID(sMediaType.formattype, FORMAT_VideoInfo) then
    Begin
      if sMediaType.cbFormat >= SizeOf(TVIDEOINFOHEADER) then
      Begin
        dBMIInfo:= PVIDEOINFOHEADER(sMediaType.pbFormat).bmiHeader;
        Result:= True;
      End
      else ProcLogTooLittleRecLength('TVIDEOINFOHEADER',
        sMediaType.cbFormat, SizeOf(TVIDEOINFOHEADER));
    End
  else if IsEqualGUID(sMediaType.formattype, FORMAT_VideoInfo2) then
    Begin
      if sMediaType.cbFormat >= SizeOf(TVIDEOINFOHEADER2) then
      Begin
        dBMIInfo:= PVIDEOINFOHEADER2(sMediaType.pbFormat).bmiHeader;
        Result:= True;
      End
      else ProcLogTooLittleRecLength('TVIDEOINFOHEADER2',
        sMediaType.cbFormat, SizeOf(TVIDEOINFOHEADER2));
    End
  else if IsEqualGUID(sMediaType.formattype, FORMAT_MPEGVideo) then
    Begin
      if sMediaType.cbFormat >= SizeOf(MPEG1VIDEOINFO) then
      Begin
        dBMIInfo:= PMPEG1VIDEOINFO(sMediaType.pbFormat).hdr.bmiHeader;
        Result:= True;
      End
      else ProcLogTooLittleRecLength('MPEG1VIDEOINFO',
        sMediaType.cbFormat, SizeOf(MPEG1VIDEOINFO));
    End
  else if IsEqualGUID(sMediaType.formattype, FORMAT_MPEGStreams) then
    Begin
      if sMediaType.cbFormat >= SizeOf(TAMMPEGSystemType) then
      Begin
        if sStreamNumber < PAMMPEGSystemType(sMediaType.pbFormat).cStreams then
        Begin
          Result:= GetBitmapHeaderFromMEDIA_TYPEStruct(
            PAMMPEGSystemType(sMediaType.pbFormat).Streams[sStreamNumber].mt,
            dBMIInfo,
            0  // у потоці відео не підтримуються підпотоки...
            );
        End;

        //for cCurStreamNum := 0 to
        //  PAMMPEGSystemType(sMediaType.pbFormat).cStreams - 1 do
        //Begin
        //  PAMMPEGSystemType(sMediaType.pbFormat).Streams[cCurStreamNum].mt;
        //End;
      End
      else ProcLogTooLittleRecLength('TAMMPEGSystemType',
        sMediaType.cbFormat, SizeOf(TAMMPEGSystemType));
    End;
//    FORMAT_DvInfo:;
//  end;
End;

// Отримує TBitmapInfoHeader для відео на піні, якщо він під'єднаний.
// Якщо відео на піні має декілька потоків, то повертає дані для потока
// з номером sStreamNumber.
// Повертає True, якщо пін під'єднаний і через нього йде відео, і дані про
// картинку вдалося прочитати.
Function TDirectShowGraphController.GetBitmapHeaderOfVideoOnConnectedPin(
         sPin:IPin;
        var dBMIInfo: TBitmapInfoHeader;
        sStreamNumber:Cardinal = 0):Boolean;
Const cs_ProcName = 'TDirectShowGraphController.GetBitmapHeaderOfVideoOnConnectedPin';
Var cMediaType: TAMMediaType; cRes:HResult;

Begin
  Result:= False;
  Windows.ZeroMemory(Addr(dBMIInfo), SizeOf(dBMIInfo));
  Windows.ZeroMemory(Addr(cMediaType), SizeOf(cMediaType));

  if Not(Assigned(sPin)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName + ': пін не заданий.');
    Exit;
  End;

  cRes:= sPin.ConnectionMediaType(cMediaType);
  if Failed(cRes) then
  Begin
    Self.LogMessage(Nil, HResultToStr(cs_ProcName + cs_ConnectionMediaTypeReported,
      cRes));

    Windows.ZeroMemory(Addr(cMediaType), SizeOf(cMediaType));
    Exit;
  End;

  try
    Result:= Self.GetBitmapHeaderFromMEDIA_TYPEStruct(cMediaType,
      dBMIInfo, sStreamNumber);
  finally
    FreeMediaType(Addr(cMediaType));
  end;
End;

Function TDirectShowGraphController.GetVideoSizeOnConnectedPin(sPin:IPin;
        Var dWidth, dHeight:Integer;
        sStreamNumber:Cardinal = 0):Boolean;
Var ccBMIInfo: TBitmapInfoHeader;
Begin
  Result:= Self.GetBitmapHeaderOfVideoOnConnectedPin(sPin, ccBMIInfo,
    sStreamNumber);
  dWidth:= ccBMIInfo.biWidth;
  dHeight:= ccBMIInfo.biHeight;
End;

Function TDirectShowGraphController.GetPinArray(sFilter:IBaseFilter;
        sPinDirection: TPinDirection; sOnlyConnectedPins:Boolean;
        Const sMediaType: PGUID = Nil):IInterfaceList;
Const cs_ProcName = 'TDirectShowGraphController.GetPinArray';
Var sSourceName, cErrorMsg, cCurPinName:String;
    cFilterName, cFilterNameInGraph, cVendorInfo: WideString;
    pEnumPins:IEnumPins;
    Res1:HResult;
    pCurPin, pConnectedPin:IPin;

    cPinDirection: TPinDirection;

    cSkip:Boolean;

    cMediaType: TAMMediaType;

    cPinList:IInterfaceList;

    {Res1, RenderRes:HResult;
    pCurPin, pConnectedPin:IPin;
    cErrorMsg, cDestFilterExplanation, cCurPinName:String; //cMidName, cDestName,


    cFilterName, cFilterNameInGraph, cVendorInfo: WideString;
      //   Список для запису фільтрів, які вже під'єднані до вихідних
      //  пінів фільтра sSourceFilter. Якщо sSourceFilter не має вільних пінів,
      //  або жоден не підходить - пошук піна йде у під'єднаних до нього
      //  фільтрах:
    cConnectedFiltersList: IInterfaceList;
    cConnectedPinInfo:TPinInfo;
    cConFilterNum: Integer;}

Begin
  Result:=Nil;
  if Not(Assigned(sFilter)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName+': не задано фільтр для пошуку пінів (sFilter)...');
    Exit;
  End;

  GetPinAndOrFilterName(sFilter, sSourceName, cErrorMsg);

  pEnumPins:= Nil;
  Res1:= sFilter.EnumPins(pEnumPins);
  If Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(
       cs_ProcName+cs_EnumPinsReported, Res1));
    pEnumPins:= Nil;
    Exit;
  End;

  pCurPin:= Nil;
  pConnectedPin:= Nil;

  cPinList:= TInterfaceList.Create;

  //RenderRes:= S_False; // тут ще не було рендеринга

  //cConnectedFiltersList:= TInterfaceList.Create;

  repeat
    cPinList.Clear;

    Res1:=pEnumPins.Reset;
    if Failed(Res1) then
    Begin
      Self.LogMessage(Nil, HResultToStr(
        cs_ProcName+cs_EnumPinsFailedToStart,
          Res1));
      Break;
    End;
      //   Всі дані, що зібрані в попередніх тактах, можуть бути не дійсними
      // при VFW_E_ENUM_OUT_OF_SYNC, тому повторюємо доки вдасться їх зібрати:

    //cConnectedFiltersList.Clear;

    cCurPinName:='';
    Res1:= pEnumPins.Next(1, pCurPin, Nil);
    while Res1 = S_OK do
    Begin
      cErrorMsg:= '';

      if Assigned(pCurPin) then
      Begin

        //GetPinAndOrFilterName(pCurPin, cCurPinName, cErrorMsg);

          // Перевіряємо що це вихідний пін:

        if GetPinAndFilterInfo(pCurPin, cCurPinName,
          cPinDirection,
          cFilterName, cFilterNameInGraph, cVendorInfo) then
        Begin
          if cFilterNameInGraph <> '' then
            cCurPinName:= cFilterNameInGraph + '.' + cCurPinName;
        End
        Else cPinDirection:= PINDIR_OUTPUT;  // якщо не вдалося отримати інформацію про пін, вважаємо що він вихідний всеодно...

        if cPinDirection = sPinDirection then
        Begin
          cSkip:= False;
            //   Перевіряємо що пін під'єднаний:
          if sOnlyConnectedPins then
          Begin
            Res1:= pCurPin.ConnectedTo(pConnectedPin);
            if Res1 = VFW_E_NOT_CONNECTED then  // пін вільний:
              cSkip:= True;
          End;

          if Not(cSkip) then
          Begin
            if Assigned(sMediaType) then
            Begin
              Windows.ZeroMemory(Addr(cMediaType), SizeOf(cMediaType));
              Res1:= pCurPin.ConnectionMediaType(cMediaType);
              if Failed(Res1) then
                Self.LogMessage(Nil, HResultToStr(cs_ProcName +
                  cs_ConnectionMediaTypeReported, Res1))
              else
              Begin
                try
                  if Not(IsEqualGUID((sMediaType^), cMediaType.majortype)) then
                    cSkip:= True;
                finally
                  FreeMediaType(Addr(cMediaType));
                end;
              End;
            End;
          End;

          if Not(cSkip) then cPinList.Add(pCurPin);
        End;
      End
      Else  //pCurPin = Nil
      Begin
        Self.LogMessage(Nil, cs_ProcName+
           cs_EnumPinsNextNotReturnedExistedPin);
      End;

      //if cCurPinName='' then cCurPinName:= cErrorMsg;

      Res1:= pEnumPins.Next(1, pCurPin, Nil);
    End;

    case Res1 of
      VFW_E_ENUM_OUT_OF_SYNC:  // обхід пінів розсинхронізувався, і потребує повтору:
      Begin
        Self.LogMessage(Nil, cs_ProcName+
          cs_EnumPinsDeSynchronizedOn+
             sSourceName+cs_EnumPinsStartingNewEnum);
        Continue;
      End;
      S_False:;
      S_OK:;
      Else     // невідомий результат:
      Begin
        Self.LogMessage(Nil, HResultToStr(
          cs_ProcName+cs_EnumPinsNextReportedUnusual,
            Res1));
        Break;
      End;
    end;
  until (Res1 = S_OK) or (Res1 = S_False);

  pCurPin:= Nil;
  pConnectedPin:= Nil;
  pEnumPins:= Nil;

  Result:= cPinList;
End;

Procedure TDirectShowGraphController.SetNewGraphBuilder(Value: IGraphBuilder);
Const cs_ProcName = 'TDirectShowGraphController.SetNewGraphBuilder';
Var Res1:HResult;
Begin
  Self.cGraphBuilderUseSection.Enter;
  try
    if Self.cGraphBuilder <> Value then
    Begin
      Self.cGraphBuilder:= Value;
      Self.cMediaControl:= Nil;
      Self.cMediaSeeking:= Nil;
        // Поточний формат часу у новому графі ще не визначений:
      Self.cTimeFormat:= GUID_NULL;

      //Self.cVideoWindow:= Nil;

      if Assigned(Value) then
      Begin
        Res1:= Self.cGraphBuilder.QueryInterface(IID_IMediaControl,
          Self.cMediaControl);
        if Failed(Res1) then
        Begin
          Self.LogMessage(Nil, HResultToStr(cs_ProcName +
            ': не вдалося отримати інтерфейс IMediaControl у графа: ', Res1));
          Self.cMediaControl:= Nil;
        End;

        Res1:= Self.cGraphBuilder.QueryInterface(IID_IMediaSeeking,
          Self.cMediaSeeking);

        if Failed(Res1) then
        Begin
          Self.LogMessage(Nil, HResultToStr(cs_ProcName +
            ': не вдалося отримати інтерфейс IMediaSeeking у графа: ', Res1));
          Self.cMediaSeeking:= Nil;
        End;
      End;
        // Створюємо новий об'єкт читання подій графа:
      if Assigned(Self.cEventHandler) then
      Begin
        SysUtils.FreeAndNil(Self.cEventHandler);
      End;

      if Assigned(Value) then
      Begin
        Self.cEventHandler:= TDirectShowGraphEventHandler.Create(Self,
          Self.cGraphBuilder);
           // Відновлюємо в об'єкта читання подій адресу зовнішнього обробника
           // подій, якщо він був встановлений:
        Self.cEventHandler.OnGraphEvent:= Self.cOnGraphEvent;
           //   Читаємо поточний формат часу графа і встановлюємо бажаний
           // (якщо його задав користувач):
        Self.SetGraphTimeFormat(Self.cDestTimeFormat);
      End;
    End;

  finally
    Self.cGraphBuilderUseSection.Leave;
  end;
End;

Procedure TPlayVideoGraphController.SetNewGraphBuilder(Value: IGraphBuilder);
Begin
  Self.cGraphBuilderUseSection.Enter;
  try
    if Self.FGraphBuilder<>Value then Self.cVMRWindowlessControl:= Nil;
    Inherited SetNewGraphBuilder(Value);
  finally
    Self.cGraphBuilderUseSection.Leave;
  end;
End;

Procedure TDirectShowGraphController.SetOnGraphEvent(Value: TCallFromThreadOnGraphEvent);
Begin
  if Addr(Self.cOnGraphEvent) <> Addr(Value) then
  Begin
    Self.cOnGraphEvent:= Value;

    if Assigned(Self.cEventHandler) then
      Self.cEventHandler.OnGraphEvent:= Value;
  End;
End;

Procedure TDirectShowGraphController.SetOnLogMessage(Value: TCallFromThreadOnLogMessage);
Begin
  //if Addr(Self.cOnLogMessage) <> Addr(Value) then
  //Begin
    Self.cOnLogMessage:= Value;
  //End;
End;

//Function TDirectShowGraphController.GetOnGraphEvent: TCallFromThreadOnGraphEvent;
//Begin
//  if Assigned(Self.cEventHandler) then
//  Begin
//    Result:= Self.cEventHandler.OnGraphEvent;
//  End
//  Else Result:= Nil;
//End;

Procedure TDirectShowGraphController.SetOnStateChange(Value: TCallFromThreadOnStateChange);
Begin
    // Ні з чим тут не синхронізується... Метод починає викликатися коли він
    // заданий.. Не викликається коли стає рівний Nil. Поточне значення
    // зчитується тільки на початку такта цикла побудови чи керування
    // станом графа:
  //if Addr(Self.cOnStateChange) <> Addr(Value) then
    Self.cOnStateChange:= Value;
End;

// Запускає граф на відтворення або на паузу.
// Налаштовує відеовікно, якщо його параметри були задані
// у SetupVideoWindow:
Function TDirectShowGraphController.RunGraph(sStartPaused:Boolean = False):Boolean;
const cs_ProcName = 'TDirectShowGraphController.RunGraph';
Var Res1: HResult;
Begin
  Result:= False;
  Self.cGraphBuilderUseSection.Enter;
  try
    if Assigned(Self.FMediaControl) then
    Begin
      if sStartPaused then  Res1:=Self.FMediaControl.Pause
      Else Res1:=FMediaControl.Run;

      if Failed(Res1) then
      Begin
        Result:= False;
        Self.LogMessage(Nil, HResultToStr(cs_ProcName + ': ошибка при запуске графа: ',
          Res1));
      End
      Else Result:= True;
    End;
    //Self.FMediaControl
  finally
    Self.cGraphBuilderUseSection.Leave;
  end;
End;

Function TPlayVideoGraphController.RunGraph(sStartPaused:Boolean = False):Boolean;
Begin
  Result:= Inherited RunGraph(sStartPaused);
    // Після запуску графа оновлюємо позицію відео на вікні форми.
    // Асоціювання відеорендерера із цим вікном тут НЕ проводиться,
    // це виконується при побудові графа, після додавання в нього\
    // рендерера, але до під'єднання до його пінів. Тут тільки
    // встановлюється або змінюється розташування картинки у вікні:
  if Result then Result:= Self.UpdateVideoWindowPos;
End;

Function TPlayVideoGraphController.InitVideoMediaRendererOnWindow(
        sVideoRenderer:IBaseFilter
        //; Const sNewSettings:PVideoWindowInfo = Nil
        ):IVMRWindowlessControl;
const cs_ProcName = 'TPlayVideoGraphController.InitVideoMediaRendererOnWindow';
Var ccVMRConfig:IVMRFilterConfig; cRes:HResult;
Begin
  // Цей метод викликається при побудові графа тільки із потока керування
  // графом, тому тут вхід в секцію вже зроблений:
  //Self.cGraphBuilderUseSection.Enter;
  //try

  Result:= Nil;
  ccVMRConfig:= Nil;

  //if Assigned(sNewSettings) then
  //Begin
  //  Self.cVideoWindowNewSettings:= sNewSettings^;
  //End;

  if Assigned(sVideoRenderer) then
  Begin
    if Not(Self.cVideoWindowNewSettings.sOwner = 0) then
    Begin
      cRes:= sVideoRenderer.QueryInterface(IID_IVMRFilterConfig, ccVMRConfig);
      if Failed(cRes) then
        Self.LogMessage(Nil, HResultToStr(cs_ProcName +
              ': не вдалося отримати інтерфейс IVMRFilterConfig у фільтра VMR: ',
               cRes))
      Else
      Begin
        cRes:= ccVMRConfig.SetRenderingMode(VMRMode_Windowless);
        if Failed(cRes) then
          Self.LogMessage(Nil, HResultToStr(cs_ProcName +
              ': не вдалося встановити режим VMRMode_Windowless у фільтра VMR: ',
               cRes))
        Else
        Begin
          cRes:= sVideoRenderer.QueryInterface(IID_IVMRWindowlessControl,
            Result);
          if Failed(cRes) then
          Begin
            Self.LogMessage(Nil, HResultToStr(cs_ProcName +
              ': не вдалося отримати інтерфейс IVMRWindowlessControl у фільтра VMR: ',
               cRes));
            Result:= Nil;
          End
          Else
          Begin
            cRes:= Result.SetVideoClippingWindow(Self.cVideoWindowNewSettings.sOwner);
            if Failed(cRes) then
            Begin
              Self.LogMessage(Nil, HResultToStr(cs_ProcName +
                ': не вдалося задати вікно '+
                  IntToStr(Self.cVideoWindowNewSettings.sOwner)+
                  ' як вікно відображення відео для фільтра VMR: ',
                 cRes));
              Result:= Nil;
            End
            Else  // запам'ятовуємо вікно, яке встановлене для відображення:
            Begin
              Self.cVideoWindowInfo.sOwner:= Self.cVideoWindowNewSettings.sOwner;
                 // Вмикаємо режим збереження пропорційності розмірів відео:
              cRes:= Result.SetAspectRatioMode(VMR_ARMODE_LETTER_BOX);
              if Failed(cRes) then
              Begin
                Self.LogMessage(Nil, HResultToStr(cs_ProcName +
                  ': не вдалося режим збереження пропорційності відео для фільтра VMR: ',
                   cRes));
              End;
            End;
          End;
        End;
      End;
    End;
  End;

  ccVMRConfig:= Nil;

  //finally
  //  Self.cGraphBuilderUseSection.Leave;
  //end;
End;

procedure TPlayVideoGraphController.SetupVideoWindow(sOwner:HWND;
        Left, Top, Width, Height: Longint);
Begin
  Self.cDestStateUseSection.Enter;
  try
    Inherited SetupVideoWindow(sOwner, Left, Top, Width, Height);
    Self.cWindowChangeQuery:=True;
    while Self.cProcQueryThread.Suspended do Self.cProcQueryThread.Resume;
  finally
    Self.cDestStateUseSection.Leave;
  end;

  {//Self.cGraphBuilderUseSection.Enter;
  Self.cDestStateUseSection.Enter;
  try
    Inherited SetupVideoWindow(sOwner, Left, Top, Width, Height);

    if (Self.cDestState <> State_Stopped)
      and (Self.cVideoWindowInfo.sOwner <> sOwner) then
    Begin  // перезапустити граф, якщо треба нове вікно:
      Self.QueryNewState('', '', True, Self.cDestState);
    End  // якщо не треба міняти вікно - тільки оновлюємо координати картинки у вікні:
    Else Self.UpdateVideoWindowPos;
  finally
    Self.cDestStateUseSection.Leave;
  end;}
End;

// Оновлює координати відеовікна і вікно на якому воно розташовується.
// Функція повертає True якщо інтерфейс вікна отриманий і параметри його задані.
Function TPlayVideoGraphController.UpdateVideoWindowPos(
        //Const sNewSettings:PVideoWindowInfo = Nil
        //; sForceRequeryForIt:Boolean = False
        ):Boolean;
const cs_ProcName = 'TPlayVideoGraphController.UpdateVideoWindowPos';
Var Res1:HResult; //cNewWindowGot, cNewSettingsApplied:Boolean;
Begin
  if Self.cRenderVideo then
  Begin
    Self.cGraphBuilderUseSection.Enter;

    Result:=False;

    //cNewWindowGot:= False;
    //cNewSettingsApplied:= False; // Value assigned to 'cNewSettingsApplied' never used

    try
      //if Assigned(sNewSettings) then
      //Begin
      //  Self.cVideoWindowNewSettings:= sNewSettings^;
      //End;

      if Assigned(Self.cVMRWindowlessControl) then
      Begin   // Всю картинку відео розмістити у заданому прямокутнику вікна
              // відображення:
        Res1:= Self.cVMRWindowlessControl.SetVideoPosition(Nil,
           Addr(Self.cVideoWindowNewSettings.CoordsInClient));
        if Failed(Res1) then
        Begin
          Self.LogMessage(Nil, HResultToStr(cs_ProcName +
                ': не вдалося встановити координати картинки Video Media Renderer у вікні для відображення: ',
                   Res1));
        End
        Else
        Begin
            // Запам'ятовуємо координати, що були встановлені:
          Self.cVideoWindowInfo.CoordsInClient:= Self.cVideoWindowNewSettings.CoordsInClient;

          Result:= True;
        End;
      End;  // if Assigned(Self.cVMRWindowlessControl) then...




      {if Assigned(Self.FGraphBuilder) then
      if Not(Self.cVideoWindowNewSettings.sOwner = 0) then
      Begin
        if Not(Assigned(Self.FVideoWindow)) or sForceRequeryForIt then
        Begin
            //получаем интерфейс IVideoWindow
          Res1:= Self.FGraphBuilder.QueryInterface(IID_IVideoWindow, Self.cVideoWindow);
          if Failed(Res1) then
          Begin
            Self.LogMessage(HResultToStr(cs_ProcName +
              ': не вдалося отримати інтерфейс IVideoWindow у графа: ', Res1));
            Self.cVideoWindow:= Nil;
          End
          Else cNewWindowGot:= True;
        End;

        if Assigned(Self.FVideoWindow) then
        Begin
          cNewSettingsApplied:= True;

          if cNewWindowGot or
            (Self.cVideoWindowInfo.sOwner <>
             Self.cVideoWindowNewSettings.sOwner) then
          Begin
            Res1:= Self.FVideoWindow.put_Owner(Self.cVideoWindowNewSettings.sOwner);
            if Failed(Res1) then
            Begin
              Self.LogMessage(HResultToStr(cs_ProcName +
                ': не вдалося виконати FVideoWindow.put_Owner: ', Res1));
              cNewSettingsApplied:= False;
            End;

            Res1:= Self.FVideoWindow.put_MessageDrain(Self.cVideoWindowNewSettings.sOwner);
            if Failed(Res1) then
            Begin
              Self.LogMessage(HResultToStr(cs_ProcName +
                ': не вдалося виконати FVideoWindow.put_MessageDrain: ', Res1));
              cNewSettingsApplied:= False;
            End;
          End;


          Res1:= Self.FVideoWindow.put_WindowStyle(
            Self.cVideoWindowNewSettings.sWindowStyle);
          if Failed(Res1) then
          Begin
            Self.LogMessage(HResultToStr(cs_ProcName +
                ': не вдалося виконати FVideoWindow.put_WindowStyle: ', Res1));
            cNewSettingsApplied:= False;
          End;


          Res1:= Self.FVideoWindow.SetWindowPosition(
              Self.cVideoWindowNewSettings.CoordsInClient.Left,
              Self.cVideoWindowNewSettings.CoordsInClient.Top,
              Self.cVideoWindowNewSettings.CoordsInClient.Right,
              Self.cVideoWindowNewSettings.CoordsInClient.Bottom);
          if Failed(Res1) then
          Begin
            Self.LogMessage(HResultToStr(cs_ProcName +
                ': не вдалося виконати FVideoWindow.SetWindowPosition: ', Res1));
            cNewSettingsApplied:= False;
          End;

          if cNewSettingsApplied then
            Self.cVideoWindowInfo:= Self.cVideoWindowNewSettings;
          Result:= cNewSettingsApplied;
        End;
      End;  // if Not(Self.cVideoWindowNewSettings.sOwner = 0) then...}
    //End;  // if Assigned(Self.FGraphBuilder) then...
    finally
      Self.cGraphBuilderUseSection.Leave;
    end;
  End
  Else Result:= True; // якщо відображення відео не ввімкнене то і вікно рендерера налаштовувати не треба
End;

Procedure TPlayVideoGraphController.RePaint(sOwner:HWND; sDC:HDC);
//Const cs_ProcName = 'TPlayVideoGraphController.RePaint';
//Var cRes:HResult;
Begin
  // cGraphBuilderUseSection.Enter тут часто викликає постійне блокування потоків один одним;
  // Self.cGraphBuilderUseSection.TryEnter пропускає потенційне блокування, але
  //   при пропуску не виконує потрібну дію (перемалювання пікселів вікна з відео).
  // Тому тут вхід в секцію доступа до параметрів: параметри записуються, і
  // запускається додатковий потік, що очікує на розблокування
  // cGraphBuilderUseSection і потім запускає перемалювання:

  //if Self.cGraphBuilderUseSection.TryEnter then
  //Begin
  Self.cDestStateUseSection.Enter; //cGraphBuilderUseSection.Enter;
  try
    Self.cRepaintQuery:= True;
    if sOwner<>0 then Self.cPaintOwner:= sOwner;
    if sDC<>0 then Self.cPaintDC:= sDC;

    while Self.cProcQueryThread.Suspended do Self.cProcQueryThread.Resume;
  finally
    Self.cDestStateUseSection.Leave;
    //Self.cGraphBuilderUseSection.Leave;
  end;
  //End;
End;

Procedure TPlayVideoGraphController.DisplayModeChange;
//Const cs_ProcName = 'TPlayVideoGraphController.DisplayModeChange';
//Var cRes:HResult;
Begin
  Self.cDestStateUseSection.Enter;
  try
    Self.cDisplayModeChangeQuery:= True;

    while Self.cProcQueryThread.Suspended do Self.cProcQueryThread.Resume;
  finally
    Self.cDestStateUseSection.Leave;
  end;
End;

Procedure TDirectShowGraphController.LogMessage(sCurThread:TThread;
        Const sMessage:String;
        sThisIsCriticalError:Boolean = False);
const cs_ProcName = 'TDirectShowGraphController.LogMessage';
Var ccOnLogMessage:TCallFromThreadOnLogMessage;
    cErrorMessage, cMessage:String;
Begin
  ccOnLogMessage:= Self.OnLogMessage;
  cErrorMessage:= '';
  try
    if Assigned(ccOnLogMessage) then
      ccOnLogMessage(sCurThread, sMessage, sThisIsCriticalError);
  except
    on E:Exception do
    Begin
      cErrorMessage:= cErrorMessage + cs_ProcName + cs_ErrorInProcessor +
         'OnLogMessage: '+ E.ToString;
      sThisIsCriticalError:= True;
    End;
  end;

  cMessage:= sMessage;
  if (cErrorMessage<>'') then
    cMessage:= cMessage + cs_NewLine + cErrorMessage;

  if Assigned(Self.LogFile) then
  Begin
    if Self.LogFile.Opened or sThisIsCriticalError then
      Self.LogFile.WriteMessage(cMessage);
  End
  else if sThisIsCriticalError then
  Begin
    Raise Exception.Create(cMessage);
  End;
End;

Function TDirectShowGraphController.CheckUrlIsLocal(Const sUrl:String):Boolean;
Var ccIsNetwork:Boolean;
Begin
  {$IFDEF UNICODE}
  ccIsNetwork:= ShlWapi.PathIsNetworkPathW(PChar(sUrl));
  {$ELSE}
  ccIsNetwork:= ShlWapi.PathIsNetworkPathA(PChar(sUrl));
  {$ENDIF}

  if Not(ccIsNetwork) then
  Begin
    if System.Pos(c_DoubleBackSlash, sUrl) > 0 then
      ccIsNetwork:= True
    Else if System.Pos(c_DoubleSlash, sUrl) > 0 then
      ccIsNetwork:= True;
  End;
  Result:= Not(ccIsNetwork);
End;

 // Може викликатися з різних потоків, в тому числі із головного.
Function TDirectShowGraphController.QueryNewPos(Const sPosition:Int64;
          sPositionIsRelativeToCurrent:Boolean):Boolean;
Const cs_ProcName = 'TDirectShowGraphController.QueryNewPos';
Begin
  Result:=True;

  Self.cDestStateUseSection.Enter;
  try
    Self.cDestPosition:= sPosition;
    Self.cDestPositionIsRelative:= sPositionIsRelativeToCurrent;
    Self.cNewPositionQueried:= True;
  finally
    Self.cDestStateUseSection.Leave;
  end;
End;

procedure TDirectShowGraphController.QueryTimeFormat(Value:TGUID);
Begin
  if Self.cDestTimeFormat = Value then Exit;

  Self.cDestStateUseSection.Enter;
  try
    Self.cDestTimeFormat:= Value;
  finally
    Self.cDestStateUseSection.Leave;
  end;
End;

Function TDirectShowGraphController.ReadGraphTimeFormat: TGUID;
const cs_ProcName = 'TDirectShowGraphController.ReadGraphTimeFormat';
Var ccTimeFormat:TGUID;
    ccRes:HResult; ccAssigned:Boolean;
    ccThread:TThread;
Begin
  ccAssigned:= False;
  ccThread:= Nil;
  Result:= GUID_NULL;
  Self.cGraphBuilderUseSection.Enter;
  try
    if System.Assigned(Self.cMediaSeeking) then
    Begin
      ccRes:= Self.cMediaSeeking.GetTimeFormat(ccTimeFormat);
      ccAssigned:= True;
    End;
  finally
    Self.cGraphBuilderUseSection.Leave;
  end;

  if Windows.GetCurrentThreadId = Self.ThreadID then
    ccThread:= Self;

  if ccAssigned then
  Begin
    if Failed(ccRes) then
    Begin
      Self.LogMessage(ccThread, HResultToStr(cs_ProcName +
        ': не вдалося прочитати формат часу графа: ', ccRes));
    End
    Else
    Begin
      Result:= ccTimeFormat;
      Self.cDestStateUseSection.Enter;
      try
        Self.cTimeFormat:= ccTimeFormat;
      finally
        Self.cDestStateUseSection.Leave;
      end;
    End;
  End
  Else
  Begin
    Self.LogMessage(ccThread, cs_ProcName +
        cs_SeekingInterfaceNotAssigned);
  End;
End;

Function TDirectShowGraphController.GetCurTimeFormat: TGUID;
Begin
  Self.cDestStateUseSection.Enter;
  try
    Result:= Self.cTimeFormat;
  finally
    Self.cDestStateUseSection.Leave;
  end;

  if IsEqualGUID(Result, GUID_NULL) then // якщо формат ще не був прочитаний:
    Result:= Self.ReadGraphTimeFormat;
End;

Procedure TDirectShowGraphController.SetGraphTimeFormat(Const sTimeFormat:TGUID);
const cs_ProcName = 'TDirectShowGraphController.SetGraphTimeFormat';
Var ccTimeFormat: TGUID; ccRes:HResult; ccInterfaceAssigned: Boolean;
    ccThread:TThread;
Begin
  ccTimeFormat:= Self.GetCurTimeFormat;

  if Not(IsEqualGUID(ccTimeFormat, sTimeFormat)) then
  Begin
    Self.cGraphBuilderUseSection.Enter;
    try
      if System.Assigned(Self.cMediaSeeking) then
      Begin
        ccRes:= Self.cMediaSeeking.SetTimeFormat(sTimeFormat);
        ccInterfaceAssigned:= True;
      End;
    finally
      Self.cGraphBuilderUseSection.Leave;
    end;

    if Windows.GetCurrentThreadId = Self.ThreadID then
      ccThread:= Self
    else ccThread:= Nil;

    if ccInterfaceAssigned then
    Begin
      if Failed(ccRes) then
      Begin
        Self.LogMessage(ccThread, HResultToStr(cs_ProcName +
          ': не вдалося встановити формат часу графа '+
          GUIDToString(sTimeFormat)+': ', ccRes));
      End
      Else
      Begin
        Self.cDestStateUseSection.Enter;
        try
          Self.cTimeFormat:= sTimeFormat;
        finally
          Self.cDestStateUseSection.Leave;
        end;
      End;
    End
    Else
    Begin
       Self.LogMessage(ccThread, cs_ProcName +
          cs_SeekingInterfaceNotAssigned);
    End;
  End;
End;

Function TDirectShowGraphController.SetPosition(Const sPosition:Int64;
  sPositionIsRelativeToCur, sSeekToKeyFrame:Boolean):Boolean;
const cs_ProcName = 'TDirectShowGraphController.SetPosition';
Var ccRes:HResult; ccInterfaceAssigned:Boolean;
    ccThread:TThread;
    ccFlags: DWord;
Begin
  Result:= False;
  if sPositionIsRelativeToCur then
    ccFlags:=
      AM_SEEKING_RelativePositioning
  Else
    ccFlags:=
      AM_SEEKING_AbsolutePositioning;

  if sSeekToKeyFrame then

  ccFlags:= ccFlags or AM_SEEKING_SeekToKeyFrame;

  Self.cGraphBuilderUseSection.Enter;
  try
    if System.Assigned(Self.cMediaSeeking) then
    Begin
      ccRes:= Self.cMediaSeeking.SetPositions(sPosition, ccFlags,
        0, AM_SEEKING_NoPositioning);
      ccInterfaceAssigned:= True;
    End;
  finally
    Self.cGraphBuilderUseSection.Leave;
  end;

  if Windows.GetCurrentThreadId = Self.ThreadID then
    ccThread:= Self
  else ccThread:= Nil;

  if ccInterfaceAssigned then
  Begin
    if Failed(ccRes) then
    Begin
      Self.LogMessage(ccThread, HResultToStr(cs_ProcName +
          ': не вдалося встановити позицію графа '+
          IntToStr(sPosition)+': ', ccRes));
    End
    Else Result:= True;
  End
  Else
  Begin
    Self.LogMessage(ccThread, cs_ProcName +
        cs_SeekingInterfaceNotAssigned);
  End;
End;


 // Може викликатися з різних потоків, в тому числі із головного.
Function TDirectShowGraphController.QueryNewState(Url, Name_ch:String;
        sForceRebuildGraph:Boolean; sNewState:TFilterState):Boolean;
Const cs_ProcName = 'TDirectShowGraphController.QueryNewState';
Begin
  Result:=True;

  Self.cDestStateUseSection.Enter;
  try
    if Url = '' then Url:= Self.cDestUrl;
    if Name_ch = '' then Name_ch:= Self.cDestChName;

    if (Url = '') and (sNewState<>State_Stopped) then
    Begin
      Self.LogMessage(Nil,
        cs_ProcName + ': неможливо запустити відтворення, бо посилання на потік (Url) пусте...');
      Result:=False
    End
    Else
    Begin
        // Не затираємо адресу потока якщо це команда зупинити відтворення:
      if sNewState<>State_Stopped then
      Begin
        Self.cDestUrl:= Url;
        Self.cDestChName:= Name_ch;

        Self.cDestUrlIsLocal:= CheckUrlIsLocal(Self.cDestUrl);
      End;

      Self.cDestState:= sNewState;
      Self.cDoRebuildGraph:= sForceRebuildGraph;
        // Будимо потік якщо він спить щоб він прочитав нові параметри і
        // налаштував граф:
      while Self.Suspended do Self.Resume;
    End;
  finally
    Self.cDestStateUseSection.Leave;
  end;
End;


Function TDirectShowGraphController.Play(Const Url:String = '';
        Const Name_ch:String = '';
        sForceRebuildGraph:Boolean = False):Boolean;
Begin
  Result:= Self.QueryNewState(Url, Name_ch, sForceRebuildGraph, State_Running);
End;

Function TDirectShowGraphController.Pause(Const Url:String = '';
        Const Name_ch:String = '';
        sForceRebuildGraph:Boolean = False):Boolean;
Begin
  Result:= Self.QueryNewState(Url, Name_ch, sForceRebuildGraph, State_Paused);
End;
procedure TDirectShowGraphController.Stop;
Begin
  Self.QueryNewState('', '', False, State_Stopped);
End;


procedure TDirectShowGraphController.SetupVideoWindow(sOwner:HWND;
        Left, Top, Width, Height: Longint);
Var cNewSettings: TVideoWindowInfo;
Begin
  cNewSettings.sOwner:= sOwner;

  //cNewSettings.sWindowStyle:= sWindowStyle;

  cNewSettings.CoordsInClient.Left:= Left;
  cNewSettings.CoordsInClient.Top:= Top;
  cNewSettings.CoordsInClient.Right:= Width;
  cNewSettings.CoordsInClient.Bottom:= Height;

  Self.cDestStateUseSection.Enter;
  //Self.cGraphBuilderUseSection.Enter;
  try
    Self.cVideoWindowNewSettings:= cNewSettings;
  finally
    Self.cDestStateUseSection.Leave;
    //Self.cGraphBuilderUseSection.Leave;
  end;

  //Result:= Self.UpdateVideoWindow(Addr(cNewSettings), False);
End;

procedure TDirectShowGraphController.Execute;
Const cs_ProcName = 'Потік TDirectShowGraphController.Execute';
Var ccDoRebuildGraph:Boolean;
    ccDUrl, ccDName_ch:String;
    ccDestState, ccCurState: TFilterState;
    ccIntermediateState, ccCantCueState:Boolean;
    ccStateRes, Res1, cInitRes:HResult;
    ccDestUrlIsLocal:Boolean;

    ccGraphTuned, ccDoRun, ccNewPositionQueried:Boolean;
    ccDestPosition: Int64;
    ccDestPositionIsRelative:Boolean;

    Procedure ProcCheckStateForRun;
    Begin
        // Для відтворення або постановки на паузу треба щоб:
      ccDoRebuildGraph:= ccDoRebuildGraph or
        (Not(Assigned(Self.FGraphBuilder)))  // - граф був створений
        or (ccCantCueState)                  // - міг опрацьовувати дані
          // - не був у стані зупинки (бо зупинений граф не завжди
          // можливо запустити знову через те що фільтри джерел можуть втратити
          // з ними з'єднання через простій, і відновлюють його тільки при
          // перепідключенні. При цьому в них оновлюються піни, і від них знову
          // треба будувати).
          // Тому зупинений граф перебудовуємо для нового запуску:
        or ((ccCurState = State_Stopped) and (Not(ccDestUrlIsLocal)));

      if Not(ccDoRebuildGraph) then
      Begin
            //   Також коли треба відкрити інший потік то для нього треба
            // побудувати інший граф:
        if Not(ccDUrl=Self.cUrl) then ccDoRebuildGraph:= True;
      End;

      ccGraphTuned:= Not(ccDoRebuildGraph);
    End;
Begin
  try
    Self.LogMessage(Self, cs_ProcName+ sc_StartsItsWork);

    cInitRes:= CoInitializeEx(Nil, COINIT_MULTITHREADED); //COINIT_APARTMENTTHREADED

    if Failed(cInitRes) then
    Begin
      Self.LogMessage(Self, HResultToStr(cs_ProcName + cs_CoInitializeExFailed,
        cInitRes));
    End;


    while not(Self.Terminated) do
    Begin
      Self.cDestStateUseSection.Enter;
      try
        ccDoRebuildGraph:=Self.cDoRebuildGraph;
        ccDUrl:= Self.cDestUrl;
        ccDestUrlIsLocal:= Self.cDestUrlIsLocal;
        ccDName_ch:= Self.cDestChName;
        ccDestState:= Self.cDestState;

        ccNewPositionQueried:= Self.cNewPositionQueried;
        //Self.cNewPositionQueried:= False;
        ccDestPosition:= Self.cDestPosition;
        ccDestPositionIsRelative:= Self.cDestPositionIsRelative;
      finally
        Self.cDestStateUseSection.Leave;
      end;

      ccGraphTuned:= True;

      Self.cGraphBuilderUseSection.Enter;
      try
        ccCurState:= Self.GetRunningState(Self,
          ccIntermediateState, ccCantCueState, ccStateRes, 0);

        case ccDestState of
          State_Stopped:
            Begin
                // Для зупинки графа не обов'язково його перебудовувати,
                // якщо його немає то і зупиняти нічого...:
              ccDoRebuildGraph:=False;

              case ccCurState of
                State_Stopped:;
                Else
                Begin
                  if Assigned(Self.FMediaControl) then  // якщо граф є:
                  Begin
                    Res1:=Self.FMediaControl.Stop;
                    if Failed(Res1) then
                    Begin
                      ccGraphTuned:= False;
                      Self.LogMessage(Self, HResultToStr(cs_ProcName +
                        ': FMediaControl.Stop повідомило про помилку:', Res1));
                    End;
                  End;
                End;
              end;
            End;
          State_Paused:
            Begin
              ProcCheckStateForRun;

              if Not(ccDoRebuildGraph) then
              Begin
                ccDoRun:= False;
                case ccCurState of
                  State_Stopped: ccDoRun:= True;
                  State_Paused:;
                  State_Running: ccDoRun:= True;
                end;

                if ccDoRun then
                Begin
                  Res1:=Self.FMediaControl.Pause;
                  if Failed(Res1) then
                  Begin
                    Self.LogMessage(Self, HResultToStr(cs_ProcName +
                      ': FMediaControl.Pause повідомило про помилку:', Res1));
                    ccDoRebuildGraph:= True;
                    ccGraphTuned:= False;
                  End;
                End;
              End;
            End;
          State_Running:
            Begin
              ProcCheckStateForRun;

              if Not(ccDoRebuildGraph) then
              Begin
                ccDoRun:= False;
                case ccCurState of
                  State_Stopped: ccDoRun:= True;
                  State_Paused: ccDoRun:= True;
                  State_Running:;
                end;

                if ccDoRun then
                Begin
                  Res1:=Self.FMediaControl.Run;
                  if Failed(Res1) then
                  Begin
                    Self.LogMessage(Self, HResultToStr(cs_ProcName +
                      ': FMediaControl.Run повідомило про помилку:', Res1));
                    ccDoRebuildGraph:= True;
                    ccGraphTuned:= False;
                  End;
                End;
              End;

            End;
        end;      // case ccDestState of...

        if ccDoRebuildGraph then
        Begin
          ccGraphTuned:= False;

          if Self.CreateGraph(ccDUrl, ccDName_ch) then
          Begin
            Self.cUrl:= ccDUrl;
            Self.cName_ch:= ccDName_ch;
              // Запускаємо обробку даних у графі і показуємо відеовікно, якщо
              // воно було налаштоване і граф реалізує для нього інтерфейс:
            ccGraphTuned:= Self.RunGraph(ccDestState = State_Paused);
          End
          else
          Begin
            Self.LogMessage(Self, cs_ProcName + ': CreateGraph не зміг створити граф для "'+
              ccDUrl+'"...');
          End;
        End;

          // Встановлюємо потрібну позицію відтворення, якщо запитана:
        if ccNewPositionQueried then
        Begin
          if Self.SetPosition(ccDestPosition, ccDestPositionIsRelative) then
            ccNewPositionQueried:= False;
          //Self.cMediaSeeking.IsUsingTimeFormat(TIME_FORMAT_MEDIA_TIME)
          //ccNewPositionQueried:= False;
        End;
      finally
        Self.cGraphBuilderUseSection.Leave;
      end;

      if ccGraphTuned then  // якщо граф налаштований в потрібний стан:
      Begin
          // Читаємо поточний стан, викликаємо обробник зміни стану графа
          // якщо стан змінився і обробник заданий:
        ccCurState:= Self.GetRunningState(Self,
          ccIntermediateState, ccCantCueState, ccStateRes, 0);

        Self.Suspend;  // чекаємо на подальші події графа, і на команди зміни стану
      End
      else  // Якщо перевести граф у потрібний стан не вдалося:
      Begin
          // Пауза, 5 секунд, перед наступною спробою.
          // Щоб не перевантажувати процесор:
        Windows.Sleep(c_EmergencySleepTime);
      End;

    End;  // while not(Self.Terminated) do ...

    if Not(Failed(cInitRes)) then
      CoUnInitialize;

    Self.LogMessage(Self, cs_ProcName+sc_FinishedItsWork);
  except
    on E:Exception do
    begin
      Self.LogMessage(Self, cs_ProcName + sc_FallenOnError+
        E.ToString);
    end;
  end;
End;

// Цей метод може викликатися із різних потоків
// (із TDirectShowGraphController і TDirectShowGraphEventHandler),
// і він викликає обробник, якому передає поточний потік,
// який може бути потреба синхронізувати із головним потоком.
// Тому в цей метод обов'язково має передаватися посилання на об'єкт потока:
Function TDirectShowGraphController.GetRunningState(sCurThread:TThread;
          Var dSTATE_INTERMEDIATE:Boolean;
          Var dCANT_CUE:Boolean;
          Var dStateRes:HResult;
          Const sTimeOut:DWord = 0):TFilterState;
Const cs_ProcName = 'TDirectShowGraphController.GetRunningState';
Var ccState, ccLastState:TFilterState; Res1, ccLastStateRes:HResult;
    ccStateChanged:Boolean;
    ccUrl, ccLastURL, ccName_ch, cErrorMessage:String;
    ccOnStateChange:TCallFromThreadOnStateChange;

    ccAfterStop, ccAfterPause, ccAfterRun:
        TCallFromThreadOnStateChange;
Begin
  Self.cGraphBuilderUseSection.Enter;

  ccStateChanged:= False;

  dSTATE_INTERMEDIATE:= False;
  dCANT_CUE:= False;
  dStateRes:= S_OK;
  ccLastStateRes:= S_OK;

  Res1:= S_OK;

  Result:= DirectShow9.State_Stopped;
  ccState:= DirectShow9.State_Stopped;
  ccLastState:= ccState;

  ccAfterStop:= Nil;
  ccAfterPause:= Nil;
  ccAfterRun:= Nil;

  try
    ccUrl:= Self.cUrl;
    ccOnStateChange:= Self.OnStateChange;

    ccAfterStop:= Self.cAfterStop;
    ccAfterPause:= Self.cAfterPause;
    ccAfterRun:= Self.cAfterRun;


    if Assigned(Self.FMediaControl) then
    Begin
      Res1:= Self.FMediaControl.GetState(sTimeOut, ccState);
      dStateRes:= Res1;
      case Res1 of
        S_OK:;
        VFW_S_STATE_INTERMEDIATE: dSTATE_INTERMEDIATE:= True;
        VFW_S_CANT_CUE: dCANT_CUE:= True;
        Else Self.LogMessage(Nil, HResultToStr(cs_ProcName +
          ': стан відтворення незвичний: ', Res1));
      end;
      Result:= ccState;

      if ccState<>Self.cLastState then ccStateChanged:= True
      else if Res1<>Self.cLastStateRes then ccStateChanged:= True
      else if ccUrl<>Self.cLastURL then ccStateChanged:= True;

      cErrorMessage:= '';


      ccLastState:= Self.cLastState;
      ccLastStateRes:= Self.cLastStateRes;
      ccLastURL:= Self.cLastURL;
      ccName_ch:= Self.cName_ch;

      if ccStateChanged then
      Begin
          // Запам'ятовуємо поточний стан:
        Self.cLastState:= ccState;
        Self.cLastStateRes:= Res1;
        Self.cLastURL:= ccUrl;
      End;
    End;
  finally
    Self.cGraphBuilderUseSection.Leave;
  end;
    //   Якщо стан змінився і є обробник зміни стану - викликаємо його,
    // без критичних секцій (якщо обробнику потрібна синхронізація, то
    // він використовує свої критичні секції або інші об'єкти у себе.
    //   Він також може викликати методи цього об'єкта
    // графа (публічні), в яких можуть використовуватися критичні секції
    // Self.cGraphBuilderUseSection, cDestStateUseSection, що може призводити
    // до блокування коли тут обробник викликався б із критичної секції.
    // Тому тут викликаємо метод поза критичною секцією, передаючи йому
    // прочитані в секції параметри:
  if ccStateChanged then
  Begin
    cErrorMessage:= '';
    case ccState of
      State_Stopped:
        if Assigned(ccAfterStop) then
        Begin
          try
            ccAfterStop(sCurThread,
                  ccState, ccLastState,
                  dSTATE_INTERMEDIATE, dCANT_CUE, Res1, ccLastStateRes,
                  ccUrl, ccLastURL, ccName_ch);
          except
            on E:Exception do
            Begin
              cErrorMessage:= cs_ProcName +
                cs_ErrorInProcessor +'AfterStop: '+
                E.ToString;
            End;
          end;
        End;
      State_Paused:
        if Assigned(ccAfterPause) then
        Begin
          try
            ccAfterPause(sCurThread,
                ccState, ccLastState,
                dSTATE_INTERMEDIATE, dCANT_CUE, Res1, ccLastStateRes,
                ccUrl, ccLastURL, ccName_ch);
          except
            on E:Exception do
            Begin
              cErrorMessage:= cs_ProcName +
                cs_ErrorInProcessor +'AfterPause: '+
                E.ToString;
            End;
          end;
        End;
      State_Running:
        if Assigned(ccAfterRun) then
        Begin
          try
            ccAfterRun(sCurThread,
                ccState, ccLastState,
                dSTATE_INTERMEDIATE, dCANT_CUE, Res1, ccLastStateRes,
                ccUrl, ccLastURL, ccName_ch);
          except
            on E:Exception do
            Begin
              cErrorMessage:= cs_ProcName +
                cs_ErrorInProcessor +'AfterRun: '+
                E.ToString;
            End;
          end;
        End;
    end;

    if cErrorMessage<>'' then Self.LogMessage(Nil, cErrorMessage);

    cErrorMessage:= '';

    if Assigned(ccOnStateChange) then
    Begin
      try
        ccOnStateChange(sCurThread,  // Self
                ccState, ccLastState,
                dSTATE_INTERMEDIATE, dCANT_CUE, Res1, ccLastStateRes,
                ccUrl, ccLastURL, ccName_ch);
      except
        on E:Exception do
        Begin
          cErrorMessage:= cs_ProcName +
            cs_ErrorInProcessor +'OnStateChange: '+
            E.ToString;
        End;
      end;
    End;

    if cErrorMessage<>'' then Self.LogMessage(Nil, cErrorMessage);
  End;
End;

Function TDirectShowGraphController.SaveGraphToFile(Const sFileName:String):Boolean;
const wszStreamName = 'ActiveMovieGraph';
      cs_ProcName = 'TDirectShowGraphController.SaveGraphToFile';
Var   hr:HRESULT;
      pStorage:IStorage;
      pStream:IStream;
      pPersist:IPersistStream;
Begin
  Self.cGraphBuilderUseSection.Enter;

  try

  if Assigned(Self.FGraphBuilder) then
  Begin

    pStorage:= Nil;
    pPersist:= Nil;

    Result:=True;

    hr:= StgCreateDocfile(PWideChar(sFileName),
      STGM_CREATE or STGM_TRANSACTED or STGM_READWRITE or STGM_SHARE_EXCLUSIVE,
      0, //reserved
      pStorage);
    if Failed(hr) then
    Begin
      Self.LogMessage(Nil, HResultToStr(
          cs_ProcName + ': StgCreateDocfile не открыло файл "'+
          sFileName+'" : ', hr));
      Result:=False;
      Exit;
    End;

    hr:= pStorage.CreateStream(wszStreamName,
      STGM_WRITE or STGM_CREATE or STGM_SHARE_EXCLUSIVE,
      0,0, //reserved
      pStream);

    if Failed(hr) then
    Begin
      Self.LogMessage(Nil, HResultToStr(
          cs_ProcName + ': CreateStream не создало поток "'+
          wszStreamName+'" для файла "'+sFileName+'" : ', hr));
      pStorage:= Nil;
      Result:=False;
      Exit;
    End;

    hr:= Self.FGraphBuilder.QueryInterface(IID_IPersistStream, pPersist);
    if Failed(hr) then
    Begin
      Self.LogMessage(Nil, HResultToStr(
          cs_ProcName +
          ': не удалось получить интерфейс IPersistStream от графа : ', hr));
      pStorage:= Nil;
      pStream:= Nil;
      Result:=False;
      Exit;
    End;

    hr:= pPersist.Save(pStream, True);
    pStream:= Nil;
    pPersist:= Nil;

    if Succeeded(hr) then
    Begin
      hr:= pStorage.Commit(STGC_DEFAULT);
      if Failed(hr) then
      Begin
        Self.LogMessage(Nil, HResultToStr(cs_ProcName +
          ': pStorage.Commit возвратило : ', hr));
        Result:=False;
      End;
    End
    Else
    Begin
      Self.LogMessage(Nil, HResultToStr(cs_ProcName +
          ': pPersist.Save возвратило : ', hr));
      Result:=False;
    End;
  End
  Else  //if Assigned(Self.FGraphBuilder) then...
  Begin
    Self.LogMessage(Nil, cs_ProcName +
      ': будувач графа в даний момент не створений, тому неможливо зберегти граф...');
    Result:=False;
  End;
  finally
    pStream:= Nil;
    pPersist:= Nil;
    pStorage:= Nil;

    Self.cGraphBuilderUseSection.Leave;
  end;
End;


Function HResultWithNumber(sResult:HResult;
  Const sCommentToError:String = ''):String;
Begin
  Result:= IntToStr(sResult) + '('+
    HResultToStr(sCommentToError, sResult)+ ')' + '...';
End;


Function ProcDShowEvent(sIMediaEvent:IMediaEvent;
           sHandler: TProcDShowEvent;
           sMessageLogProc:TMessageLogProc = Nil;
           sCurThread:TThread = Nil):Boolean;
Const sc_ProcName = 'ProcDShowEvent';
Var cEvCode:Longint; dlParam1, dlParam2:Longint;
    cRes:HResult;
Begin
  cEvCode:= 0;
  dlParam1:= 0;
  dlParam2:= 0;

  //Result:=False;

  cRes:= sIMediaEvent.GetEvent(cEvCode, dlParam1, dlParam2, 0);

  try
    if cRes = S_OK then
    Begin
      Result:=True;
      sHandler(cEvCode, dlParam1, dlParam2);


      //if Failed(sIMediaEvent.QueryInterface(IID_IGraphBuilder, cGraphBuilder)) then
      //  Result:= False; // проте продовжуємо, бо інформацію про подію отримано, її можна показати
    End
    else
    Begin
      Result:= False;
      if cRes <> E_ABORT then
      Begin
        if Assigned(sMessageLogProc) then
          sMessageLogProc(sCurThread,
            HResultToStr(sc_ProcName +
            ': IMediaEvent.GetEvent повідомило про помилку: ', cRes));
      End;
    End;
  finally
    cRes:= sIMediaEvent.FreeEventParams(cEvCode, dlParam1, dlParam2);
    if Failed(cRes) and Assigned(sMessageLogProc) then
    Begin
      sMessageLogProc(sCurThread,
        HResultToStr(sc_ProcName +
        ': sIMediaEvent.FreeEventParams повідомило про помилку: ', cRes));
    End;
  end;
End;

Function GetDShowEventExplanation(sIMediaEvent:IMediaEvent;
           Var dEventDefineName, dEventData:String):Boolean;
var cEvCode:Longint; lParam1, lParam2:Longint; // cGraphBuilder:IGraphBuilder;
Begin
  //cGraphBuilder:= Nil;

  {так не можна, бо параметри вже будуть звільнені при вижачі їх адрес із процедури:
  if GetDShowEventParameters(sIMediaEvent,
           cEvCode, lParam1, lParam2) then
  Begin
    Result:= GetDShowEventExplanation(
             cEvCode, lParam1, lParam2,
             dEventDefineName, dEventData);
  End
  Else Result:= False;}



  cEvCode:= 0;
  lParam1:= 0;
  lParam2:= 0;
  try
    if sIMediaEvent.GetEvent(cEvCode, lParam1, lParam2, 0) = S_OK then
    Begin
      Result:=True;
      //if Failed(sIMediaEvent.QueryInterface(IID_IGraphBuilder, cGraphBuilder)) then
      //  Result:= False; // проте продовжуємо, бо інформацію про подію отримано, її можна показати
      Result:= Result and GetDShowEventExplanation(//Nil,
             cEvCode, lParam1, lParam2,
             dEventDefineName, dEventData);
      //cGraphBuilder:= Nil;
    End
    else Result:= False;
  finally
    sIMediaEvent.FreeEventParams(cEvCode, lParam1, lParam2);
  end;
End;

Function GetFilterInfo(sIBaseFilter:IBaseFilter):TFilterInfo; overload;
var cInfo:TFilterInfo; //cRes:HResult;
Begin
  Windows.ZeroMemory(@cInfo, SizeOf(cInfo));
  //cRes:=
  sIBaseFilter.QueryFilterInfo(cInfo);
  //if Failed(cRes) then
  //Begin
  //  //cInfo.achName:='<назву не визначено>';
  //End;
  Result:= cInfo;
End;

{IFilterInfo Зроблений ЗАМІСТЬ IBaseFilter для Visual Basic та Automation... тут не використовується:
Function GetFilterInfo(sIFilterInfo:IFilterInfo;
  var dName, dVendorInfo: WideString):Boolean; overload;
Begin
  dName:= '';
  dVendorInfo:= '';
  if Assigned(sIFilterInfo) then
  Begin
    Result:= True;

    If Failed(sIFilterInfo.get_Name(dName)) then Result:=False;
    If Failed(sIFilterInfo.get_VendorInfo(dVendorInfo)) then Result:=False;
  End
  Else Result:= False;
End;}

Function GetFilterInfo(sIBaseFilter:IBaseFilter;
  var dName, dNameInGraph, dVendorInfo: WideString):Boolean; overload;
Var cInfo: TFilterInfo; cVerdorInfo:PWideChar; cRes:HResult;
    cFilterGUID:TGUID;
    //cMoniker:IMoniker;
    //cPropertyBag:IPropertyBag;
    //cName:OleVariant;
    //cBindCtx:IBindCtx;
Begin
  //cIInfo:= Nil;
  dName:='';
  dNameInGraph:='';
  dVendorInfo:= '';

  //cMoniker:=Nil;
  //cPropertyBag:= Nil;
  //cName:= '';
  //cBindCtx:=Nil;
  if Assigned(sIBaseFilter) then
  Begin
    //Result:=True;

    try
      {не вдалося реалізувати. Схоже що отримати FriendlyName фільтра можна
       тільки через CLSID_SystemDeviceEnum\IID_ICreateDevEnum, CreateClassEnumerator,
       що дасть IEnumMoniker, і його метод Next дасть IMoniker, що реалізує
       BindToStorage(Nil, Nil, IID_IPropertyBag, PropertyBag), який дає
       PropertyBag, в якого можна отримати Read('FriendlyName', cName, LogObject).
       Але для цього треба отримати GUID (GetClassID(out classID: TCLSID)),
       поточного фільтра і в тому переліку SystemDeviceEnum знайти кодек із таким
       GUID, і проситати FriendlyName. Поки що я цього не захотів робити, бо
       відносно повільно працюватиме.

      if Not(Failed(ActiveX.CreatePointerMoniker(sIBaseFilter, cMoniker))) then
      Begin
        cRes:=CreateBindCtx(0, cBindCtx);
        if Not(Failed(cRes)) then
        Begin

          cRes:=cMoniker.BindToStorage(cBindCtx, Nil,  // тут "інтерфейс не підтримується"...
            IID_IPropertyBag, cPropertyBag);
          If Not(Failed(cRes)) then
          Begin
            //cPropertyBag:= sIBaseFilter as IPropertyBag;

            cRes:=cPropertyBag.Read('FriendlyName', cName, Nil);
            if Not(Failed(cRes)) then
            Begin
              dName:=WideString(cName);
            End
            Else dName:= HResultWithNumber(cRes, 'Read(''FriendlyName'') повернуло:');
          End
          Else dName:= HResultWithNumber(cRes, 'BindToStorage повернуло:');

          //cBindCtx._Release;
          cBindCtx:=Nil;
        End
        Else dName:= HResultWithNumber(cRes, 'CreateBindCtx повернуло:');
      End;}
         // Так як не підтримується отримувати назву фільтра
         // (що присвоєна розробником, не графом),
         // використовується GUID фільтра як основна назва:
      if Not(Failed(sIBaseFilter.GetClassID(cFilterGUID))) then
      Begin
        //try
          dName:= GUIDToString(cFilterGUID);
        //except
        //  dName:='';
        //end;
      End;

      cInfo:= GetFilterInfo(sIBaseFilter);
      dNameInGraph:= cInfo.achName;

      cInfo.pGraph:=Nil; // це не використовується, писали що треба звільнити.. Тому обнуляємо

      cRes:= sIBaseFilter.QueryVendorInfo(cVerdorInfo);
      if failed(cRes) then
      Begin
        //Result:= False;
        //dVendorInfo:= HResultWithNumber(cRes, 'Назву виробника фільтра не визначено:');
        dVendorInfo:= '';
      End
      Else
      Begin
        dVendorInfo:= cVerdorInfo;
      End;

      Result:= (dName <> '') or (dNameInGraph <> '') or (dVendorInfo<>'');

      {IFilterInfo Зроблений ЗАМІСТЬ IBaseFilter для Visual Basic та Automation... тут не використовується:

      If Failed(sIBaseFilter.QueryInterface(IID_IFilterInfo, cIInfo)) then
      Begin
        cIInfo:= Nil;
        Result:= False;
      End
      Else
      Begin
        Result:= Result and GetFilterInfo(cIInfo,
          dName, dVendorInfo);
      End;}
    except
      //cIInfo:=Nil;
      on E:Exception do
      Begin
        dName:= '<Назва фільтра не отримана, помилка: ' +  E.ToString+'>';
        Result:=False;
      End;
    end;
  End
  else Result:=False;

  //cMoniker:=Nil;
  //cPropertyBag:= Nil;
  //cName:= '';
End;

Function AddNameInGraphAndVendorToFilterName(Const sName, sNameInGraph,
  sVendorInfo:WideString):WideString;
Begin
  if sName = '' then
    Result:= sName
  else Result:= sName + ', ';

  if sNameInGraph<>'' then
  Begin
    Result:= Result + cs_InGraph + sNameInGraph + '"';
  End;
  if sVendorInfo <> '' then
  Begin
    Result:= Result + ' (' + sVendorInfo + ')';
  End;
End;

Function AddFilterNameAndVendor(sIFilter:IBaseFilter;
  Var sdEventData: String):Boolean;
Var cName, cNameInGraph, cVendorInfo:WideString;
Begin
  Result:= GetFilterInfo(sIFilter, cName, cNameInGraph, cVendorInfo);

  sdEventData:= sdEventData + ' ' + AddNameInGraphAndVendorToFilterName(cName,
    cNameInGraph, cVendorInfo);
End;

Function GetPinInfo(sIPin:IPin; Var dPinInfo:TPinInfo):Boolean;
Begin
  Windows.ZeroMemory(@dPinInfo, SizeOf(dPinInfo));
  if Assigned(sIPin) then
  Begin
    Result:= Not Failed(sIPin.QueryPinInfo(dPinInfo));
  End
  Else Result:= False;
End;

Function GetPinAndFilterInfo(sIPin:IPin; Var dPinName:String;
   Var dPinDirection:TPinDirection;
   Var dFilterName, dFilterNameInGraph, dVendorInfo: WideString):Boolean;
Var cPinInfo:TPinInfo;
Begin
  Result:= GetPinInfo(sIPin, cPinInfo);

  if Result then
  Begin
    dPinName:= cPinInfo.achName;
    dPinDirection:= cPinInfo.dir;

    Result:= GetFilterInfo(cPinInfo.pFilter,
      dFilterName, dFilterNameInGraph, dVendorInfo);
  End
  Else
  Begin
    dPinName:= '';
    dFilterName:=''; dVendorInfo:= '';
    dFilterNameInGraph:='';
  End;
End;

Function GetPinAndOrFilterName(sObject:IUnknown; Var dName:String;
           Var dErrorMessage:String):Boolean;
Var dFilterName, dVendorInfo, dWideName, dWideNameInGraph: WideString;
    dPinDirection:TPinDirection;
    //cErrorMessage:String;
    cBaseFilter:IBaseFilter;
    cPin:IPin;

    //Procedure AddNameInGraphAndVendor;
    //Begin
    //  if dWideNameInGraph<>'' then
    //    dName:=dName + cs_InGraph + dWideNameInGraph+'"';
    //  if dVendorInfo<>'' then dName:=dName + ' ('+dVendorInfo+')';
    //End;
Begin
  Result:=False;
  dErrorMessage:= '';
  dWideName:= '';
  try
    cBaseFilter:= sObject as IBaseFilter;
    if GetFilterInfo(cBaseFilter, dWideName, dWideNameInGraph, dVendorInfo) then
    Begin
      dName:= AddNameInGraphAndVendorToFilterName(dWideName, dWideNameInGraph,
        dVendorInfo);

      Result:=True;
    End;
  except
    on E:Exception do
    Begin
      dErrorMessage:= dErrorMessage + E.ToString;
    End;
  end;

  if Not(Result) then
  Begin
    try
      cPin:= sObject as IPin;

      if GetPinAndFilterInfo(cPin, dName,
         dPinDirection, dFilterName, dWideNameInGraph, dVendorInfo) then
      Begin
        if dFilterName <> '' then
        Begin
          dName:= dFilterName+'.'+dName;
        End;

        if dPinDirection=PINDIR_INPUT then
          dName:= 'In ' + dName
        Else dName:= 'Out ' + dName;

        dName:= AddNameInGraphAndVendorToFilterName(dName, dWideNameInGraph,
          dVendorInfo);

        //dName:= dName;

        //AddNameInGraphAndVendor;

        Result:=True;
      End;
    except
      on E:Exception do
      Begin
        dErrorMessage:= dErrorMessage + cs_NewLine + E.ToString;
      End;
    end;
  End;
End;

Function AddPinAndFilterInfo(sIPin:IPin; Var sdEventData:String):Boolean;
Var cPinName:String;
    cPinDirection:TPinDirection;
    cFilterName, cFilterNameInGraph, cVendorInfo, cFullFilterName: WideString;
Begin
  Result:= GetPinAndFilterInfo(sIPin, cPinName,
   cPinDirection,
   cFilterName, cFilterNameInGraph, cVendorInfo);
  if Result or (cPinName <> '') then
  Begin
    sdEventData:= sdEventData + ' ' + cPinName;

    if cPinDirection = PINDIR_INPUT then
      sdEventData:= sdEventData + ' >'
    else sdEventData:= sdEventData + ' <';

    cFullFilterName:= AddNameInGraphAndVendorToFilterName(cFilterName,
          cFilterNameInGraph, cVendorInfo);

    if cFullFilterName <> '' then
      sdEventData:= sdEventData + ' ' + cFullFilterName;
  End;
End;

Procedure GetWindowInfo(sWindow:HWND; dText:String; dClassName:String);
Const c_MaxWindowClassNameLen=255;
Var cTextLen:Integer;
Begin
  dText:='';
  dClassName:='';
  cTextLen:= Windows.GetWindowTextLength(sWindow);
  if cTextLen > 0 then
  Begin
    System.SetLength(dText, cTextLen + 1);
    cTextLen:= Windows.GetWindowText(sWindow, PWideChar(dText), System.Length(dText));
    if cTextLen > 0 then
      System.SetLength(dText, cTextLen);
  End;
  System.SetLength(dClassName, c_MaxWindowClassNameLen);

  cTextLen:= Windows.GetClassName(sWindow, PWideChar(dClassName),
    c_MaxWindowClassNameLen);
  if cTextLen > 0 then
      System.SetLength(dClassName, cTextLen);
End;

Procedure AddWindowInfo(sWindow:HWND; Var sdEventData: String);
Var cText:String; cClassName:String;
Begin
  GetWindowInfo(sWindow, cText, cClassName);

  sdEventData:= sdEventData + ' ' + cText + ', клас вікна ' + cClassName+'.';
End;

Function GetSndDevErrStr(cErr:TSndDevErr):String;
Begin
  case cErr of
    SNDDEV_ERROR_Open: Result:= 'SNDDEV_ERROR_Open';
    SNDDEV_ERROR_Close: Result:= 'SNDDEV_ERROR_Close';
    SNDDEV_ERROR_GetCaps: Result:= 'SNDDEV_ERROR_GetCaps';
    SNDDEV_ERROR_PrepareHeader: Result:= 'SNDDEV_ERROR_PrepareHeader';
    SNDDEV_ERROR_UnprepareHeader: Result:= 'SNDDEV_ERROR_UnprepareHeader';
    SNDDEV_ERROR_Reset: Result:= 'SNDDEV_ERROR_Reset';
    SNDDEV_ERROR_Restart: Result:= 'SNDDEV_ERROR_Restart';
    SNDDEV_ERROR_GetPosition: Result:= 'SNDDEV_ERROR_GetPosition';
    SNDDEV_ERROR_Write: Result:= 'SNDDEV_ERROR_Write';
    SNDDEV_ERROR_Pause: Result:= 'SNDDEV_ERROR_Pause';
    SNDDEV_ERROR_Stop: Result:= 'SNDDEV_ERROR_Stop';
    SNDDEV_ERROR_Start: Result:= 'SNDDEV_ERROR_Start';
    SNDDEV_ERROR_AddBuffer: Result:= 'SNDDEV_ERROR_AddBuffer';
    SNDDEV_ERROR_Query: Result:= 'SNDDEV_ERROR_Query';
    else Result:= 'Невідомий тип помилки звукового пристрою, '+IntToStr(Integer(cErr));
  end;
End;

Procedure Get16Words(Const cLongWord:LongWord; Var cLowWord, cHighWord:Word);
Var cRec: LongRec;
Begin
  cRec:= LongRec(cLongWord);
  cLowWord:= cRec.Lo;
  cHighWord:= cRec.Hi;
End;

Procedure Put16WordsToLong(Var cLongWord:LongWord; Const cLowWord, cHighWord:Word);
Var cRec: LongRec;
Begin
  cRec.Lo:= cLowWord;
  cRec.Hi:= cHighWord;

  cLongWord:= LongWord(cRec);
End;

Procedure GetBytesFromLongWord(Const cLongWord:LongWord;
  Var dB0, dB1, dB2, dB3:Byte);
Var cRec: LongRec;
Begin
  cRec:= LongRec(cLongWord);
  dB0:=cRec.Bytes[0];
  dB1:=cRec.Bytes[1];
  dB2:=cRec.Bytes[2];
  dB3:=cRec.Bytes[3];
End;

Function GetStrWordCoordsFromLongWord(Const cLongWord:LongWord):String;
Var x,y:Word;
Begin
  Get16Words(cLongWord, x, y);
  Result:= IntToStr(x)+'x'+IntToStr(y);
End;

Function GetStrDVD_HMSF_TIMECODE(Const cLongWord:LongWord):String;
Var cB0, cB1, cB2, cB3:Byte;
Begin
  GetBytesFromLongWord(cLongWord,
    cB0, cB1, cB2, cB3);
  Result:= IntToStr(cB0) + ' годин, ' + IntToStr(cB1) + ' хвилин, ' +
    IntToStr(cB2) + ' секунд, ' + IntToStr(cB3) + ' кадрів';
End;

Function GetFlag(Const sFlags, sPattern:Cardinal):Boolean;
Begin
  Result:= (sFlags and sPattern) <> 0;
End;

Function GetMark(sValue:Boolean):Char;
Begin
  If sValue then Result:= 'v' else Result:='_';
End;

Procedure GetDVD_TIMECODE_FLAGS(Const sFlags:LongWord; Var d25fps, d30fps,
  dDropFrame29_97, dTC_FLAG_Interpolated:Boolean);
Begin
  d25fps:= (sFlags and DVD_TC_FLAG_25fps) <> 0;
  d30fps:= (sFlags and DVD_TC_FLAG_30fps) <> 0;
  dDropFrame29_97:= (sFlags and DVD_TC_FLAG_DropFrame) <> 0;
  dTC_FLAG_Interpolated:= (sFlags and DVD_TC_FLAG_Interpolated) <> 0;
End;

Function GetStrDVD_TIMECODE_FLAGS(Const sFlags:LongWord):String;
Var c25fps, c30fps, cDropFrame29_97, cTC_FLAG_Interpolated: Boolean;
Begin
  GetDVD_TIMECODE_FLAGS(sFlags, c25fps, c30fps,
    cDropFrame29_97, cTC_FLAG_Interpolated);
  Result:= cs_NewLine+
    '25fps ['+GetMark(c25fps)+'];'+cs_NewLine+
    '30fps ['+GetMark(c30fps)+'];'+cs_NewLine+
    '29,97 [' + GetMark(cDropFrame29_97) + '];'+cs_NewLine+
    'Interpolated ['+GetMark(cTC_FLAG_Interpolated)+']';
End;

Function GetDVD_DOMAINStr(Const sDomain: DVD_DOMAIN):String;
Begin
  case sDomain of
    DVD_DOMAIN_FirstPlay: Result:= 'FirstPlay';
    DVD_DOMAIN_VideoManagerMenu: Result:= 'VideoManagerMenu';
    DVD_DOMAIN_VideoTitleSetMenu: Result:= 'VideoTitleSetMenu';
    DVD_DOMAIN_Title: Result:= 'Title';
    DVD_DOMAIN_Stop: Result:= 'Stop';
    Else Result:= 'невідомий стан';
  end;
End;

Function GetDVD_ERRORStr(Const sError:DVD_ERROR; Const sParam2:LongWord):String;
Var cLowWord, cHighWord:Word;
Begin
  case sError of
    DVD_ERROR_Unexpected: Result:= 'Unexpected (напевно невірна авторизація). Відтворення зупинене.';
    DVD_ERROR_CopyProtectFail: Result:= 'CopyProtectFail (помилка захисту від копіювання). Відтворення зупинене.';
    DVD_ERROR_InvalidDVD1_0Disc: Result:= 'InvalidDVD1_0Disc (диск несумісний із авторизацією DVD 1.0). Відтворення зупинене.';
    DVD_ERROR_InvalidDiscRegion:
      Begin
        Get16Words(sParam2, cLowWord, cHighWord);
        Result:= 'InvalidDiscRegion (регіон диска ('+
          String(DataHelper.NumberToBitString(cLowWord, SizeOf(cLowWord), True))+
          ') не сумісний із регіоном системи ('+
          String(DataHelper.NumberToBitString(cHighWord, SizeOf(cHighWord), True))+'))';
      End;
    DVD_ERROR_LowParentalLevel:
      Begin
        Result:= 'LowParentalLevel (на плеєрі рівень батьківського контролю нижче за найнижчий рівень на диску, тобто '+
          IntToStr(sParam2)+'). Відтворення зупинене.';
      End;
    DVD_ERROR_MacrovisionFail: Result:= 'MacrovisionFail (помилка аналогово захисту від копіювання). Відтворення зупинене.';
    DVD_ERROR_IncompatibleSystemAndDecoderRegions:
      Begin
        Get16Words(sParam2, cLowWord, cHighWord);
        Result:= 'IncompatibleSystemAndDecoderRegions (регіони системи ('+
          String(DataHelper.NumberToBitString(cLowWord, SizeOf(cLowWord), True))+
          ') і розпакувальника ('+
          String(DataHelper.NumberToBitString(cHighWord, SizeOf(cHighWord), True))+
          ') не співпадають). Відтворення зупинене.';
      End;
    DVD_ERROR_IncompatibleDiscAndDecoderRegions:
      Begin
        Get16Words(sParam2, cLowWord, cHighWord);
        Result:= 'IncompatibleDiscAndDecoderRegions (регіони диска ('+
          String(DataHelper.NumberToBitString(cLowWord, SizeOf(cLowWord), True))+
          ') і розпакувальника ('+
          String(DataHelper.NumberToBitString(cHighWord, SizeOf(cHighWord), True))+
          ') не сумісні). Відтворення зупинене.';
      End;
    else Result:= 'невідома помилка, код '+IntToStr(Cardinal(sError))+
      ', додатковий параметр ' + IntToStr(sParam2) + '.';
  end;
End;

Function GetDVD_PB_STOPPEDStr(Const sDVD_PB_STOPPED:DVD_PB_STOPPED):String;
Begin
  case sDVD_PB_STOPPED of
    DVD_PB_STOPPED_Other: Result:= 'Other';
    DVD_PB_STOPPED_NoBranch: Result:= 'NoBranch';
    DVD_PB_STOPPED_NoFirstPlayDomain: Result:= 'NoFirstPlayDomain';
    DVD_PB_STOPPED_StopCommand: Result:= 'StopCommand';
    DVD_PB_STOPPED_Reset: Result:= 'Reset';
    DVD_PB_STOPPED_DiscEjected: Result:= 'DiscEjected';
    DVD_PB_STOPPED_IllegalNavCommand: Result:= 'IllegalNavCommand';
    DVD_PB_STOPPED_PlayPeriodAutoStop: Result:= 'PlayPeriodAutoStop';
    DVD_PB_STOPPED_PlayChapterAutoStop: Result:= 'PlayChapterAutoStop';
    DVD_PB_STOPPED_ParentalFailure: Result:= 'ParentalFailure';
    DVD_PB_STOPPED_RegionFailure: Result:= 'RegionFailure';
    DVD_PB_STOPPED_MacrovisionFailure: Result:= 'MacrovisionFailure';
    DVD_PB_STOPPED_DiscReadError: Result:= 'DiscReadError';
    DVD_PB_STOPPED_CopyProtectFailure: Result:= 'CopyProtectFailure';
    Else Result:= 'невідома причина, ' + IntToStr(Cardinal(sDVD_PB_STOPPED));
  end;
End;

Function GetVALID_UOP_FLAGStr(Const sFlags:VALID_UOP_FLAG):String;
Begin
  Result:= cs_NewLine+
    'UOP_FLAG_Play_Title_Or_AtTime ['+GetMark(GetFlag(sFlags, UOP_FLAG_Play_Title_Or_AtTime))+'];'+cs_NewLine+
    'UOP_FLAG_Play_Chapter ['+GetMark(GetFlag(sFlags, UOP_FLAG_Play_Chapter))+'];'+cs_NewLine+
    'UOP_FLAG_Play_Title ['+GetMark(GetFlag(sFlags, UOP_FLAG_Play_Title))+'];'+cs_NewLine+
    'UOP_FLAG_Stop ['+GetMark(GetFlag(sFlags, UOP_FLAG_Stop))+'];'+cs_NewLine+
    'UOP_FLAG_ReturnFromSubMenu ['+GetMark(GetFlag(sFlags, UOP_FLAG_ReturnFromSubMenu))+'];'+cs_NewLine+
    'UOP_FLAG_Play_Chapter_Or_AtTime ['+GetMark(GetFlag(sFlags, UOP_FLAG_Play_Chapter_Or_AtTime))+'];'+cs_NewLine+
    'UOP_FLAG_PlayPrev_Or_Replay_Chapter ['+GetMark(GetFlag(sFlags, UOP_FLAG_PlayPrev_Or_Replay_Chapter))+'];'+cs_NewLine+
    'UOP_FLAG_PlayNext_Chapter ['+GetMark(GetFlag(sFlags, UOP_FLAG_PlayNext_Chapter))+'];'+cs_NewLine+
    'UOP_FLAG_Play_Forwards ['+GetMark(GetFlag(sFlags, UOP_FLAG_Play_Forwards))+'];'+cs_NewLine+
    'UOP_FLAG_Play_Backwards ['+GetMark(GetFlag(sFlags, UOP_FLAG_Play_Backwards))+'];'+cs_NewLine+
    'UOP_FLAG_ShowMenu_Title ['+GetMark(GetFlag(sFlags, UOP_FLAG_ShowMenu_Title))+'];'+cs_NewLine+
    'UOP_FLAG_ShowMenu_Root ['+GetMark(GetFlag(sFlags, UOP_FLAG_ShowMenu_Root))+'];'+cs_NewLine+
    'UOP_FLAG_ShowMenu_SubPic ['+GetMark(GetFlag(sFlags, UOP_FLAG_ShowMenu_SubPic))+'];'+cs_NewLine+
    'UOP_FLAG_ShowMenu_Audio ['+GetMark(GetFlag(sFlags, UOP_FLAG_ShowMenu_Audio))+'];'+cs_NewLine+
    'UOP_FLAG_ShowMenu_Angle ['+GetMark(GetFlag(sFlags, UOP_FLAG_ShowMenu_Angle))+'];'+cs_NewLine+
    'UOP_FLAG_ShowMenu_Chapter ['+GetMark(GetFlag(sFlags, UOP_FLAG_ShowMenu_Chapter))+'];'+cs_NewLine+
    'UOP_FLAG_Resume ['+GetMark(GetFlag(sFlags, UOP_FLAG_Resume))+'];'+cs_NewLine+
    'UOP_FLAG_Select_Or_Activate_Button ['+GetMark(GetFlag(sFlags, UOP_FLAG_Select_Or_Activate_Button))+'];'+cs_NewLine+
    'UOP_FLAG_Still_Off ['+GetMark(GetFlag(sFlags, UOP_FLAG_Still_Off))+'];'+cs_NewLine+
    'UOP_FLAG_Pause_On ['+GetMark(GetFlag(sFlags, UOP_FLAG_Pause_On))+'];'+cs_NewLine+
    'UOP_FLAG_Select_Audio_Stream ['+GetMark(GetFlag(sFlags, UOP_FLAG_Select_Audio_Stream))+'];'+cs_NewLine+
    'UOP_FLAG_Select_SubPic_Stream ['+GetMark(GetFlag(sFlags, UOP_FLAG_Select_SubPic_Stream))+'];'+cs_NewLine+
    'UOP_FLAG_Select_Angle ['+GetMark(GetFlag(sFlags, UOP_FLAG_Select_Angle))+'];'+cs_NewLine+
    'UOP_FLAG_Select_Karaoke_Audio_Presentation_Mode ['+GetMark(GetFlag(sFlags, UOP_FLAG_Select_Karaoke_Audio_Presentation_Mode))+'];'+cs_NewLine+
    'UOP_FLAG_Select_Video_Mode_Preference ['+GetMark(GetFlag(sFlags, UOP_FLAG_Select_Video_Mode_Preference))+']'
End;

Function GetDVD_WARNINGStr(Const sDVD_WARNING:DVD_WARNING;
  Const Param2: LongWord):String;
Begin
  case sDVD_Warning of
    DVD_WARNING_InvalidDVD1_0Disc: Result:= 'InvalidDVD1_0Disc';
    DVD_WARNING_FormatNotSupported: Result:= 'FormatNotSupported';
    DVD_WARNING_IllegalNavCommand: Result:= 'IllegalNavCommand';
    DVD_WARNING_Open:
      Result:= 'Open failed, status is '+HResultWithNumber(Param2);
    DVD_WARNING_Seek:
      Result:= 'Seek failed, status is '+HResultWithNumber(Param2);
    DVD_WARNING_Read:
      Result:= 'Read failed, status is '+HResultWithNumber(Param2);
    Else Result:= 'невідоме попередження, номер '+
      IntToStr(Cardinal(sDVD_WARNING));
  end;
End;


Function GetDShowEventExplanation(Event, Param1, Param2: Integer;
           Var dEventDefineName, dEventData:String):Boolean;
//var cIFilterInfo:IFilterInfo;
Var cFilter:IBaseFilter;
Begin
  dEventDefineName:= DShowUtil.GetEventCodeDef(Event);

  dEventData:= '';

  //cIFilterInfo:= Nil;

  {try
    If Failed(sender.QueryInterface(IID_IFilterInfo, cIFilterInfo)) then
    Begin
      cIFilterInfo:= Nil;
    End;
  finally

  end;}

  Result:=True;

  cFilter:=Nil;



  try

    case Event of
      EC_ACTIVATE                  : // result:= 'EC_ACTIVATE - A video window is being activated or deactivated.';
      Begin
        if LongBool(Param1) then
          dEventData:='Активовано вікно фільтра видачі'
        else dEventData:='Деактивовано вікно фільтра видачі';

        Result:= Result and AddFilterNameAndVendor(IBaseFilter(Param2), dEventData);
      End;
      EC_BUFFERING_DATA            : //result:= 'EC_BUFFERING_DATA - The graph is buffering data, or has stopped buffering data.';
      Begin
        if LongBool(Param1) then
          dEventData:='Запис в буфер почався...'
        else dEventData:='Запис в буфер закінчився...';
      End;
      //EC_CLOCK_CHANGED             : result:= 'EC_CLOCK_CHANGED - The reference clock has changed.';
      EC_COMPLETE                  : //result:= 'EC_COMPLETE - All data from a particular stream has been rendered.';
      Begin
        dEventData:= 'Обробка в графі закінчилася, статус ' +
          HResultWithNumber(Param1);
      End;
      EC_DEVICE_LOST               : //result:= 'EC_DEVICE_LOST - A Plug and Play device was removed or has become available again.';
      Begin
        if Param2 = 0 then
          dEventData:='Пристрій відімкнений'
        else dEventData:='Пристрій з''явився';
        try
          cFilter:=  IUnknown(Param1) as IBaseFilter;
        except
          on E:Exception do
          Begin
            cFilter:= Nil;
            dEventData:= dEventData + ', не вдалося отримати його інтерфейс, '+
              E.ToString;
          End;
        end;
        if Assigned(cFilter) then
          Result:= Result and AddFilterNameAndVendor(cFilter, dEventData)
        Else Result:=False;
      End;
      EC_DISPLAY_CHANGED           : //result:= 'EC_DISPLAY_CHANGED - The display mode has changed.';
      Begin
        if Param2 = 0 then
          dEventData:='Один пін відеовиходу'
        else dEventData:= IntToStr(Param2) + ' пінів відеовиходу';
      End;
      EC_END_OF_SEGMENT            : //result:= 'EC_END_OF_SEGMENT - The end of a segment has been reached.';
      Begin
        dEventData:= 'Закінчився сегмент номер ' + IntToStr(Param2);
        if Param1 = 0 then
          dEventData:= dEventData + ', час НЕ вказаний.'
        Else dEventData:= dEventData + ', ' + IntToStr(PReferenceTime(Param1)^)
          + ' 100наносекунд';
      End;
      EC_ERROR_STILLPLAYING        : //result:= 'EC_ERROR_STILLPLAYING - An asynchronous command to run the graph has failed.';
      Begin
        dEventData:= 'Через те що граф ще обробляє дані, операція перервана з кодом ' +
          HResultWithNumber(Param1);
      End;

      EC_ERRORABORT                : //result:= 'EC_ERRORABORT - An operation was aborted because of an error.';
      Begin
        dEventData:= 'Через те що граф ще обробляє дані, операція перервана з кодом ' +
          HResultWithNumber(Param1);
      End;
      EC_FULLSCREEN_LOST           : //result:= 'EC_FULLSCREEN_LOST - The video renderer is switching out of full-screen mode.';
      Begin
        dEventData:= 'Вихід з повноекранного режиму для фільтра ';

        if Param2<>0 then
        Begin
          try
            cFilter:=  IUnknown(Param2) as IBaseFilter;
          except
            on E:Exception do
            Begin
              cFilter:= Nil;
              dEventData:= dEventData + ', не вдалося отримати його інтерфейс, '+
                E.ToString;
            End;
          end;

          if Assigned(cFilter) then
            Result:= Result and AddFilterNameAndVendor(cFilter, dEventData)
          Else Result:=False;
        End
        Else dEventData:= dEventData + ', фільтр не вказаний.';
      End;
      //EC_GRAPH_CHANGED             : //result:= 'EC_GRAPH_CHANGED - The filter graph has changed.';

      //EC_NEED_RESTART              : //result:= 'EC_NEED_RESTART - A filter is requesting that the graph be restarted.';
      EC_NOTIFY_WINDOW             : //result:= 'EC_NOTIFY_WINDOW - Notifies a filter of the video renderer''s window.';
      Begin
        dEventData:= 'Вікно видачі ';
        AddWindowInfo(Param1, dEventData);
      End;
      EC_OLE_EVENT                 : //result:= 'EC_OLE_EVENT - A filter is passing a text string to the application.';
      Begin
        dEventData:= 'Передача від фільтра, тип ' +
          String(ActiveX.TBStr(Param1)) + ', опис: ' + String(ActiveX.TBStr(Param2));
      End;
      EC_OPENING_FILE              : //result:= 'EC_OPENING_FILE - The graph is opening a file, or has finished opening a file.';
      Begin
        if LongBool(Param1) then
          dEventData:= 'Виконується спроба відкрити файл...'
        else dEventData:= 'Виконано спробу відкрити файл...';
      End;
      //EC_PALETTE_CHANGED           : //result:= 'EC_PALETTE_CHANGED - The video palette has changed.';

      EC_PAUSED                    : //result:= 'EC_PAUSED - A pause request has completed.';
      Begin
        dEventData:= 'Перехід в режим паузи, ' +
          HResultWithNumber(Param1);
      End;
      //EC_QUALITY_CHANGE            : // result:= 'EC_QUALITY_CHANGE - The graph is dropping samples, for quality control.';
      EC_REPAINT                   : //result:= 'EC_REPAINT - A video renderer requires a repaint.';
      Begin
        dEventData:= 'Вимога перемалювати для піна';
        AddPinAndFilterInfo(IPin(Param1), dEventData);
      End;
      EC_SEGMENT_STARTED           : //result:= 'EC_SEGMENT_STARTED - A new segment has started.';
      Begin
        dEventData:= 'Почався сегмент номер ' + IntToStr(Param2);
        if Param1 = 0 then
          dEventData:= dEventData + ', час НЕ вказаний.'
        Else dEventData:= dEventData + ', ' + IntToStr(PReferenceTime(Param1)^)
          + ' 100наносекунд';
      End;
      //EC_SHUTTING_DOWN             : //result:= 'EC_SHUTTING_DOWN - The filter graph is shutting down, prior to being destroyed.';
      EC_SNDDEV_IN_ERROR           : //result:= 'EC_SNDDEV_IN_ERROR - An audio device error has occurred on an input pin.';
      Begin
        dEventData:= 'Помилка пристрою-джерела звуку '+
          GetSndDevErrStr(TSndDevErr(Param1))+', ' +
          HResultWithNumber(Param2);
      End;
      EC_SNDDEV_OUT_ERROR          : //result:= 'EC_SNDDEV_OUT_ERROR - An audio device error has occurred on an output pin.';
      Begin
        dEventData:= 'Помилка пристрою-отримувача звуку '+
          GetSndDevErrStr(TSndDevErr(Param1))+', ' +
          HResultWithNumber(Param2);
      End;
      //EC_STARVATION                : //result:= 'EC_STARVATION - A filter is not receiving enough data.';

      EC_STEP_COMPLETE             : //result:= 'EC_STEP_COMPLETE - A filter performing frame stepping has stepped the specified number of frames.';
      Begin
        if LongBool(Param1) then
          dEventData:= 'Крок скасований...'
        else dEventData:= 'Крок виконаний...';
      End;
      EC_STREAM_CONTROL_STARTED    : //result:= 'EC_STREAM_CONTROL_STARTED - A stream-control start command has taken effect.';
      Begin
        dEventData:= 'Потік розпочався від піна ';
        AddPinAndFilterInfo(IPin(Param1), dEventData);
        dEventData:= dEventData + ' Додатковий параметр: ' + IntToStr(Param2) +
          '.';
      End;
      EC_STREAM_CONTROL_STOPPED    : //result:= 'EC_STREAM_CONTROL_STOPPED - A stream-control start command has taken effect.';
      Begin
        dEventData:= 'Потік зупинився від піна ';
        AddPinAndFilterInfo(IPin(Param1), dEventData);
        dEventData:= dEventData + ' Додатковий параметр: ' + IntToStr(Param2) +
          '.';
      End;
      EC_STREAM_ERROR_STILLPLAYING : //result:= 'EC_STREAM_ERROR_STILLPLAYING - An error has occurred in a stream. The stream is still playing.';
      Begin
        dEventData:= 'Сталася помилка у потоці: ' + HResultWithNumber(Param1) +
          ', варіант=' + IntToStr(Param2) + '. Можливо, потік ще відтворюється.'
      End;
      EC_STREAM_ERROR_STOPPED      : //result:= 'EC_STREAM_ERROR_STOPPED - A stream has stopped because of an error.';
      Begin
        dEventData:= 'Сталася помилка у потоці: ' + HResultWithNumber(Param1) +
          ', варіант=' + IntToStr(Param2) + '. Потік зупинився.'
      End;
      //EC_USERABORT                 : result:= 'EC_USERABORT - The user has terminated playback.';
      EC_VIDEO_SIZE_CHANGED        : //result:= 'EC_VIDEO_SIZE_CHANGED - The native video size has changed.';
      Begin
        dEventData:= 'Новий розмір відео: ' +
          GetStrWordCoordsFromLongWord(Param1) +'.';
      End;
      EC_VMR_RECONNECTION_FAILED       : //result:= 'EC_VMR_RECONNECTION_FAILED - VMR-7 or VMR-9 was unable to accept a dynamic format change request from the upstream decoder.';
// (hr - ReceiveConnection return code, void)
// Identifies that an upstream decoder tried to perform a dynamic format
// change and the VMR was unable to accept the new format.
      Begin
        dEventData:= 'Статус на піні, що не зміг перепід''єднатися: ' +
          HResultWithNumber(Param1) +'...'
      End;

      EC_VMR_SURFACE_FLIPPED           : //result:= 'EC_VMR_SURFACE_FLIPPED - VMR-7''s allocator presenter has called the DirectDraw Flip method on the surface being presented.';
// (hr - Flip return code, void)
// Identifies the VMR's allocator-presenter has called the DDraw flip api on
// the surface being presented.   This allows the VMR to keep its DX-VA table
// of DDraw surfaces in sync with DDraws flipping chain.
      Begin
        dEventData:= 'Метод Flip відповів: ' +
          HResultWithNumber(Param1) +'...'
      End;

      EC_WINDOW_DESTROYED          : //result:= 'EC_WINDOW_DESTROYED - The video renderer was destroyed or removed from the graph.';
      Begin
        dEventData:= 'Закрилося вікно фільтра ';

        if Param1<>0 then
        Begin
          try
            cFilter:=  IUnknown(Param1) as IBaseFilter;
          except
            on E:Exception do
            Begin
              cFilter:= Nil;
              dEventData:= dEventData + ', не вдалося отримати його інтерфейс, '+
                E.ToString;
            End;
          end;

          if Assigned(cFilter) then
            Result:= Result and AddFilterNameAndVendor(cFilter, dEventData)
          Else Result:=False;
        End
        Else dEventData:= dEventData + ', фільтр не вказаний';

        dEventData:= dEventData + '.';
      End;

      //EC_TIMECODE_AVAILABLE        : //result:= 'EC_TIMECODE_AVAILABLE- Sent by filter supporting timecode.';
      //EC_EXTDEVICE_MODE_CHANGE     : result:= 'EC_EXTDEVICE_MODE_CHANGE - Sent by filter supporting IAMExtDevice.';
      //EC_CLOCK_UNSET               : result:= 'EC_CLOCK_UNSET - notify the filter graph to unset the current graph clock.';
      //EC_TIME                      : result:= 'EC_TIME - The requested reference time occurred (currently not used).';
      EC_VMR_RENDERDEVICE_SET      : //result:= 'EC_VMR_RENDERDEVICE_SET - Identifies the type of rendering mechanism the VMR is using to display video.';
      Begin
        dEventData:= 'VMR обрав механізм захоплення: ';
        case Param1 of
           VMR_RENDER_DEVICE_OVERLAY: dEventData:= dEventData +
             'VMR_RENDER_DEVICE_OVERLAY (оверлейна площина)';
           VMR_RENDER_DEVICE_VIDMEM: dEventData:= dEventData +
             'VMR_RENDER_DEVICE_VIDMEM (відеопам''ять)';
           VMR_RENDER_DEVICE_SYSMEM: dEventData:= dEventData +
             'VMR_RENDER_DEVICE_SYSMEM (системна пам''ять)';
           else dEventData:= dEventData +
             'невідомий, номер ' + IntToStr(Param1) + '.';
        end;
      End;

      EC_DVD_ANGLE_CHANGE              : //result:= 'EC_DVD_ANGLE_CHANGE - Signals that either the number of available angles changed or that the current angle number changed.';
      Begin
        dEventData:= 'DVD-варіант відео помінявся на ' + IntToStr(Param2) +
          ', всього є ' + IntToStr(Param1) + 'варіантів.';
      End;
      EC_DVD_ANGLES_AVAILABLE          : //result:= 'EC_DVD_ANGLES_AVAILABLE - Indicates whether an angle block is being played and angle changes can be performed.';
      Begin
        dEventData:= 'DVD-варіанти відео тут ';
        if Param1 = 0 then dEventData:= dEventData + 'НЕ доступні.'
          else dEventData:= dEventData + 'доступні.'
      End;
      EC_DVD_AUDIO_STREAM_CHANGE       : //result:= 'EC_DVD_AUDIO_STREAM_CHANGE - Signals that the current audio stream number changed for the main title.';
      Begin
        if Param1 = High(Param1) then
          dEventData:= 'DVD-потік аудіо не вибраний (повідомляється про номер' + IntToStr(Param1) + ').'
        else dEventData:= 'DVD-потік аудіо змінений на ' + IntToStr(Param1) + '.';
      End;
      EC_DVD_BUTTON_AUTO_ACTIVATED     : //result:= 'EC_DVD_BUTTON_AUTO_ACTIVATED - Signals that a menu button has been automatically activated per instructions on the disc.';
      Begin
        dEventData:= 'DVD: автоматично обрана кнопка номер ' +
          IntToStr(Param1) + '.';
      End;
      EC_DVD_BUTTON_CHANGE             : //result:= 'EC_DVD_BUTTON_CHANGE - Signals that either the number of available buttons changed or that the currently selected button number changed.';
      Begin
        dEventData:= 'DVD: стан кнопок: кількість ' +
          IntToStr(Param1) + ', обрано кнопку номер ' + IntToStr(Param2) + '.';
      End;
      //EC_DVD_CHAPTER_AUTOSTOP          : //result:= 'EC_DVD_CHAPTER_AUTOSTOP - Indicates that playback stopped as the result of a call to the IDvdControl2::PlayChaptersAutoStop method.';
      EC_DVD_CHAPTER_START             : //result:= 'EC_DVD_CHAPTER_START - Signals that the DVD Navigator started playback of a new chapter in the current title.';
      Begin
        dEventData:= 'DVD: номер розділу ' + IntToStr(Param1) + '.';
      End;
      EC_DVD_CMD_START                 : //result:= 'EC_DVD_CMD_START - Signals that a particular command has begun.';
      Begin
        dEventData:= 'DVD: команда номер ' + IntToStr(Param1) + ', статус: '+
          HResultWithNumber(Param2) + '.';
      End;
      EC_DVD_CMD_END                   : //result:= 'EC_DVD_CMD_END - Signals that a particular command has completed.';
      Begin
        dEventData:= 'DVD: команда номер ' + IntToStr(Param1) + ', статус: '+
          HResultWithNumber(Param2) + '.';
      End;
      EC_DVD_CURRENT_HMSF_TIME         : //result:= 'EC_DVD_CURRENT_HMSF_TIME - Signals the current time in DVD_HMSF_TIMECODE format at the beginning of every VOBU, which occurs every .4 to 1.0 sec.';
      Begin
        dEventData:= 'DVD: час блока: ' +
          GetStrDVD_HMSF_TIMECODE(Param1) + '; дозволені формати відтворення: ' +
          GetStrDVD_TIMECODE_FLAGS(Param2) + '.';
      End;
      //EC_DVD_CURRENT_TIME              : //result:= 'EC_DVD_CURRENT_TIME - Signals the beginning of every video object unit (VOBU), a video segment which is 0.4 to 1.0 seconds in length.';
      //EC_DVD_DISC_EJECTED              : //result:= 'EC_DVD_DISC_EJECTED - Signals that a disc has been ejected from the drive.';
      //EC_DVD_DISC_INSERTED             : //result:= 'EC_DVD_DISC_INSERTED - Signals that a disc has been inserted into the drive.';
      EC_DVD_DOMAIN_CHANGE             : //result:= 'EC_DVD_DOMAIN_CHANGE - Indicates the DVD Navigator''s new domain.';
      Begin
        dEventData:= 'DVD: стан домена: ' + GetDVD_DOMAINStr(DVD_DOMAIN(Param1)) + '.';
      End;
      EC_DVD_ERROR                     : //result:= 'EC_DVD_ERROR - Signals a DVD error condition.';
      Begin
        dEventData:= 'DVD: помилка: ' +
          GetDVD_ERRORStr(DVD_ERROR(Param1), Param2);
      End;
      EC_DVD_KARAOKE_MODE              : //result:= 'EC_DVD_KARAOKE_MODE - Indicates that the Navigator has either begun playing or finished playing karaoke data.';
      Begin
        dEventData:='DVD: відтворення караоке';
        if LongBool(Param1) then dEventData:= dEventData + ' почалося.'
          else dEventData:= dEventData + ' закінчилося.';
      End;
      //EC_DVD_NO_FP_PGC                 : //result:= 'EC_DVD_NO_FP_PGC - Indicates that the DVD disc does not have a FP_PGC (First Play Program Chain).';
      EC_DVD_PARENTAL_LEVEL_CHANGE     : //result:= 'EC_DVD_PARENTAL_LEVEL_CHANGE - Signals that the parental level of the authored content is about to change.';
      Begin
        dEventData:='DVD: рівень батьківського контроля в плеєрі помінявся на '+
          IntToStr(Param1)+'.';
      End;
      EC_DVD_PLAYBACK_RATE_CHANGE      : //result:= 'EC_DVD_PLAYBACK_RATE_CHANGE - Indicates that a playback rate change has been initiated and the new rate is in the parameter.';
      Begin
        dEventData:='DVD: темп відтворення змінився: '+IntToStr(Param1)+'.';
      End;
      EC_DVD_PLAYBACK_STOPPED          : //result:= 'EC_DVD_PLAYBACK_STOPPED - Indicates that playback has been stopped. The DVD Navigator has completed playback of the title and did not find any other branching instruction for subsequent playback.';
      Begin
        dEventData:='DVD: відтворення зупинене, причина: ' +
          GetDVD_PB_STOPPEDStr(DVD_PB_STOPPED(Param1));
      End;
      //EC_DVD_PLAYPERIOD_AUTOSTOP       : //result:= 'EC_DVD_PLAYPERIOD_AUTOSTOP - Indicates that the Navigator has finished playing the segment specified in a call to PlayPeriodInTitleAutoStop.';
      //EC_DVD_STILL_OFF                 : //result:= 'EC_DVD_STILL_OFF - Signals the end of any still.';
      EC_DVD_STILL_ON                  : //result:= 'EC_DVD_STILL_ON - Signals the beginning of any still.';
      Begin
        dEventData:='DVD: починається відтворення картинки: ';
        if Param1 = 0 then dEventData:= dEventData + 'на ній є кнопки'
          else dEventData:= dEventData + 'на ній нема кнопок';
        dEventData:= dEventData + ', ';
        if Param2 = High(Param2) then dEventData:= dEventData +
          'відтворення безстрокове.'
        else dEventData:= dEventData + 'відтворення триватиме протягом '+
          IntToStr(Param2) + ' секунд.'
      End;
      EC_DVD_SUBPICTURE_STREAM_CHANGE  : //result:= 'EC_DVD_SUBPICTURE_STREAM_CHANGE - Signals that the current subpicture stream number changed for the main title.';
      Begin
        dEventData:='DVD: потік субкартинки ';
        if Param1 = High(Param1) then dEventData:= dEventData + 'не вибраний'
          else dEventData:= dEventData + 'встановлений на ' + IntToStr(Param1);
        dEventData:= dEventData + ', ';
        if LongBool(Param2) then
          dEventData:= dEventData + ', підкартинка ввімкнена'
        Else dEventData:= dEventData + ', підкартинка вимкнена';
      End;
      EC_DVD_TITLE_CHANGE              : //result:= 'EC_DVD_TITLE_CHANGE - Indicates when the current title number changes.';
      Begin
        dEventData:='DVD: встановлено заголовок номер ' + IntToStr(Param1) + '.';
      End;
      EC_DVD_VALID_UOPS_CHANGE         : //result:= 'EC_DVD_VALID_UOPS_CHANGE - Signals that the available set of IDVDControl2 interface methods has changed.';
      Begin
        dEventData:='DVD: на диску НЕдоступні такі команди: ' +
          GetVALID_UOP_FLAGStr(VALID_UOP_FLAG(Param1)) + '.';
      End;
      EC_DVD_WARNING                   : //result:= 'EC_DVD_WARNING - Signals a DVD warning condition.'
      Begin
        dEventData:='DVD: попередження: ' +
          GetDVD_WARNINGStr(DVD_WARNING(Param1), Param2);
      End;
      EC_PREPROCESS_COMPLETE           : //result:= 'EC_PREPROCESS_COMPLETE - Sent by the WM ASF writer filter (WMSDK V9 version) to signal the completion of a pre-process run when running in multipass encode mode.';
// Sent by the WM ASF writer filter (WMSDK V9 version) to signal the completion
// of a pre-process run when running in multipass encode mode.
// Param1 = 0, Param2 = IBaseFilter ptr of sending filter
      Begin
        dEventData:='Пре-процес завершено у фільтрі';

        if Param2<>0 then
        Begin
          try
            cFilter:=  IUnknown(Param2) as IBaseFilter;
          except
            on E:Exception do
            Begin
              cFilter:= Nil;
              dEventData:= dEventData + ', не вдалося отримати його інтерфейс, '+
                E.ToString;
            End;
          end;

          if Assigned(cFilter) then
            Result:= Result and AddFilterNameAndVendor(cFilter, dEventData)
          Else Result:=False;
        End
        Else dEventData:= dEventData + ', фільтр не вказаний';

        dEventData:= dEventData + '.';
      End;
      EC_SKIP_FRAMES                   : //result:= 'EC_SKIP_FRAMES - Get the filter graph to skip nFramesToSkip and notify.';
// ( nFramesToSkip, IFrameSkipResultCallback)
//Get the filter graph to skip nFramesToSkip and notify.
//Reserved for future use in dx8.1 specific.
      Begin
        dEventData:= 'Пропуск '+IntToStr(Param1) + ' кадра(-ів)...';
      End;
      EC_STATUS                        : //result:= 'EC_STATUS - Two arbitrary strings, a short one and a long one.';
// ( BSTR, BSTR) : application
// Two arbitrary strings, a short one and a long one.';
      Begin
        dEventData:= 'Рядки статуса: "'+TBSTR(Param1) + '", "'+
          TBSTR(Param2)+'".';
      End;
      EC_MARKER_HIT                    : //result:= 'EC_MARKER_HIT - The specified "marker #" has just been passed.';
// (int, void) : application
// The specified "marker #" has just been passed.';
      Begin
        dEventData:= 'Маркер: '+IntToStr(Param1)+'.';
      End;
      EC_LOADSTATUS                    : //result:= 'EC_LOADSTATUS - Sent when various points during the loading of a network file are reached.';
// (int, void) : application
// Sent when various points during the loading of a network file are reached.';
      Begin
        dEventData:= 'Статус завантаження: '+IntToStr(Param1)+'.';
      End;
      EC_ERRORABORTEX                  : //result:= 'EC_ERRORABORTEX - Operation aborted because of error.  Additional information available.';
// ( HRESULT, BSTR ) : application
// Operation aborted because of error.  Additional information available.
      Begin
        dEventData:='Перервано, статус: ' + HResultWithNumber(Param1) +
          '; ' + TBSTR(Param2)+'.';
      End;
      EC_CONTENTPROPERTY_CHANGED       : //result:= 'EC_CONTENTPROPERTY_CHANGED - Sent when a streaming media filter recieves a change in stream description information. The UI is expected to re-query for the changed property in response.';
// (ULONG, void)
// Sent when a streaming media filter recieves a change in stream description information.
// the UI is expected to re-query for the changed property in response
      Begin
        dEventData:='Параметр: ' + IntToStr(Param1)+'.';
      End;
      EC_BANDWIDTHCHANGE               : //result:= 'EC_BANDWIDTHCHANGE - sent when the bandwidth of the streaming data has changed.';
// (WORD, long) : application
// sent when the bandwidth of the streaming data has changed.  First parameter
// is the new level of bandwidth. Second is the MAX number of levels. Second
// parameter may be 0, if the max levels could not be determined.
      Begin
        dEventData:='Рівень пропускної здатності: ' + IntToStr(Param1);
        if Param2 <> 0 then
        Begin
          dEventData:= dEventData + ', із ' + IntToStr(Param2);
        End;

        dEventData:= dEventData + '.';
      End;
    //else  не всі події мають додаткові параметри.
    //  result := format('Unknow Graph Event ($%x)',[code]);
    end;
  except
    on E:Exception do
    Begin
      dEventData:= dEventData + ' ...помилка отримання опису: ' + E.ToString+'...';
      Result:= False;
    End;
    //cIFilterInfo:= Nil;
  end;
End;

Function HResultToStr(Const sCommentToError:String; sResult:HResult):String;
Var //cError: SysUtils.EOSError;
    //cResCode:Integer;
    cStrBuf:String;
    cReadLen:DWORD;
    cLastSymbWithNoNewLine:Integer;
Begin
  //cResCode:= ActiveX.ResultCode(sResult);


  SetLength(cStrBuf, MAX_ERROR_TEXT_LEN+1);

  cReadLen:= AMGetErrorText(sResult, PChar(cStrBuf), System.Length(cStrBuf));
  if cReadLen > 0 then
  Begin
    SetLength(cStrBuf, cReadLen);
    cLastSymbWithNoNewLine:= Integer(cReadLen) - System.Length(cs_NewLine);
    if System.Copy(cStrBuf, cLastSymbWithNoNewLine+1,
          System.Length(cs_NewLine)) = cs_NewLine then
      cStrBuf:= System.Copy(cStrBuf, 1, cLastSymbWithNoNewLine);

    Result:= cStrBuf;
  End
  Else
  Begin
    Result:= 'Невідома помилка '+ IntToStr(sResult) +
      ', за Windows.FormatMessage: ' +
      SysUtils.SysErrorMessage(Cardinal(sResult));
  End;

  Result:= sCommentToError + Result;



  {if sResult = 0 then
    Result:= SysUtils.SysErrorMessage(cResCode)
  else
  Begin
    cError:= FormatOSError(sCommentToError, cResCode);
    Result:= cError.Message;
  End;}

  {Case sResult of
    S_OK: Result:= 'ошибок не выявлено';
    REGDB_E_CLASSNOTREG: Result:= 'COM-клас не зарегистрирован';
    CLASS_E_NOAGGREGATION: Result:= 'COM-клас не может быть создан как часть агрегата';
    E_NOINTERFACE: Result:= 'COM-клас не реализует запрошенный интерфейс';
    Else Result:= '';
  End;
  if Result = '' then Result:= IntToStr(sResult)
  Else Result:= Result + ' (' +IntToStr(sResult)+ ')';}
End;


constructor TPlayVideoGraphController.Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
Begin
  Inherited Create(sLogFile, True);
  Self.cVMRWindowlessControl:= Nil;

  Self.cRepaintQuery:= False;
  Self.cDisplayModeChangeQuery:= False;
  Self.cWindowChangeQuery:= False;
  cPaintOwner:= 0;
  cPaintDC:= 0;

  cVideoWidth:= 0;
  cVideoHeight:= 0;

  cRenderVideo:= True;
  cRenderAudio:= True;

  cProcQueryThread:= TProcVideoGraphControllerQueryThread.Create(Self, False);

  if Not CreateSuspended then Self.Resume;
End;

{procedure TBMPSampleList.Notify(Ptr: Pointer; Action: TListNotification);
Var ccRec: PBMPSampleRec;
Begin
  ccRec:= Ptr;
  case Action of
    lnAdded: ;
    lnExtracted: ;
    lnDeleted:
      Begin
        FreeMem(ccRec.pBuffer);
        FreeMem(ccRec);
      End;
  end;
End;}

function TBMPSampleList.Get(Index: Integer): PBMPSampleRec;
Begin
  Self.LockList;
  try
    Result:= PBMPSampleRec(Inherited Get(Index));
  finally
    Self.UnlockList;
  end;
End;

procedure TBMPSampleList.Put(Index: Integer; Const Item: PBMPSampleRec);
Begin
  Self.LockList;
  try
    Inherited Put(Index, Item);
  finally
    Self.UnlockList;
  end;
End;

function TBMPSampleList.FreeItem(Var sdItem:PBMPSampleRec):Integer;
Begin
  Self.LockList;
  try
      // Звільняємо і видаляємо елемент зі списка. А якщо у списку його немає,
      // то просто звільняємо:
    Result:= Self.Remove(sdItem);
    If Not(Result >= 0) then FreeBMPData(sdItem);
  finally
    Self.UnlockList;
  end;
End;

function TBMPSampleList.Remove(Item: PBMPSampleRec): Integer;
Begin
  Self.LockList;
  try
    Result := IndexOf(Item);
    if Result >= 0 then
      Self.Delete(Result);
  finally
    Self.UnlockList;
  end;
End;

function TBMPSampleList.Add(Const Item: PBMPSampleRec;
          sToCopyItem:Boolean = True): Integer;
Var cItemToAdd: PBMPSampleRec;
Begin
  if sToCopyItem then
  Begin
    if Assigned(Item) then
    Begin
      cItemToAdd:= AllocateBMPData(Addr(Item.cBmpHead),
          Item.pBuffer, Item.cBufferSize,
          Item.cSampleTime);
    End
    Else cItemToAdd:= Nil;
  End
  Else cItemToAdd:= Item;

  Self.LockList;
  try
    Result:= Inherited Add(cItemToAdd);
  finally
    Self.UnlockList;
  end;
End;

Function TBMPSampleList.Add(sHeader: PBitmapInfoHeader;
          pBuffer:PByte; sBufferSize: Longint;
          sSampleTime:Double):Integer;
Var cItemToAdd: PBMPSampleRec;
Begin
  //Self.LockList;
  //try
      // Створюємо елемент, копіюємо заголовок і буфер:
    cItemToAdd:= AllocateBMPData(sHeader,
            pBuffer, sBufferSize,
            sSampleTime);
      // Додаємо вказівник на елемент у список:
    Result:= Self.Add(cItemToAdd, False);
  //finally
  //  Self.UnlockList;
  //end;
End;

procedure TBMPSampleList.Clear;
Begin
  Self.LockList;
  try
    while Self.Count > 0 do
      Self.Delete(0);
    Inherited Clear;
  finally
    Self.UnlockList;
  end;
End;

procedure TBMPSampleList.Delete(Index: Integer);
Var cItem: PBMPSampleRec;
Begin
  Self.LockList;
  try
    cItem:= Inherited Get(Index);

    Self.List^[Index]:=Nil;
    Inherited Delete(Index);

    if Assigned(cItem) then
    Begin
      Self.Notify(cItem, Classes.lnDeleted);

      FreeBMPData(cItem);
    End;
  finally
    Self.UnlockList;
  end;
End;

function TBMPSampleList.Extract(Const Item: PBMPSampleRec): PBMPSampleRec;
Var cIndex: Integer;
Begin
  Self.LockList;
  try
    cIndex:= Self.IndexOf(Item);
    if cIndex >= 0 then
      Result:= Self.ExtractByNum(cIndex)
    Else Result:= Nil;
  finally
    Self.UnlockList;
  end;
End;

function TBMPSampleList.ExtractByNum(Index: Integer): PBMPSampleRec;
Var cItem:PBMPSampleRec;
Begin
  Self.LockList;
  try
    cItem:= Self.Get(Index);

    Result:= cItem; // GetStringFromBuf(cItem);
      // Видаляємо елемент без звільнення від нього пам'яті:
    Self.List^[Index]:=Nil;
    Self.Delete(Index);
    Self.Notify(cItem, Classes.lnExtracted);
  finally
    Self.UnlockList;
  end;

  //FreeAndNilBuf(cItem);
End;

function TBMPSampleList.First: PBMPSampleRec;
Begin
  Self.LockList;
  try
    Result:= Self.Get(0);
  finally
    Self.UnlockList;
  end;
End;

function TBMPSampleList.ExtractFirst: PBMPSampleRec;
Begin
  Result:= Self.ExtractByNum(0);
End;

procedure TBMPSampleList.Insert(Index: Integer; Const Item: PBMPSampleRec;
          sToCopyItem:Boolean = True);
Var cItemToAdd: PBMPSampleRec;
Begin
  if sToCopyItem then
  Begin
    if Assigned(Item) then
    Begin
      cItemToAdd:= AllocateBMPData(Addr(Item.cBmpHead),
          Item.pBuffer, Item.cBufferSize,
          Item.cSampleTime);
    End
    Else cItemToAdd:= Nil;
  End
  Else cItemToAdd:= Item;

  Self.LockList;
  try
    Inherited Insert(Index, cItemToAdd);
  finally
    Self.UnlockList;
  end;
End;

procedure TBMPSampleList.Insert(Index: Integer;
            sHeader: PBitmapInfoHeader;
            pBuffer:PByte; sBufferSize: Longint;
            sSampleTime:Double);
Var cItemToAdd: PBMPSampleRec;
Begin
//  Self.LockList;
//  try
      // Створюємо елемент, копіюємо заголовок і буфер:
    cItemToAdd:= AllocateBMPData(sHeader,
            pBuffer, sBufferSize,
            sSampleTime);
      // Додаємо вказівник на елемент у список:
    Self.Insert(Index, cItemToAdd, False);
//  finally
//    Self.UnlockList;
//  end;
End;

function TBMPSampleList.Last: PBMPSampleRec;
Begin
  Self.LockList;
  try
    Result:= PBMPSampleRec(Inherited Last);
  finally
    Self.UnlockList;
  end;
End;

function TBMPSampleList.ExtractLast: PBMPSampleRec;
Begin
  Result:= Self.ExtractByNum(Self.Count - 1);
End;

  // Виконує пошук кадра у списку за часом...:
function TBMPSampleList.IndexOf(Const Item: PBMPSampleRec): Integer;
Var LCount: Integer; cSourceTime:Double; ccItem:PBMPSampleRec;
Begin
  Self.LockList;
  try
    LCount := Self.Count;
    //LList := Self.List;

    if Assigned(Item) then
    Begin
      cSourceTime:= Item.cSampleTime;

      for Result := 0 to LCount - 1 do // new optimizer doesn't use [esp] for Result
      Begin
        ccItem:= Self.Get(Result);
        if Assigned(ccItem) then
        Begin
          if ccItem.cSampleTime = cSourceTime then Exit;  // знайшовся кадр
        End;
      End;
    End;

    Result := -1;   // не знайшовся
  finally
    Self.UnlockList;
  end;
End;

Procedure TBMPSampleList.LockList;
Begin
  if Assigned(Self.cListSection) then Self.cListSection.Enter;
End;

procedure TBMPSampleList.UnlockList;
Begin
  if Assigned(Self.cListSection) then Self.cListSection.Leave;
End;

Constructor TBMPSampleList.Create(sUseCriticalSection:Boolean = True);
Begin
  Inherited Create;
  if sUseCriticalSection then
    Self.cListSection:= TCriticalSection.Create
  Else Self.cListSection:= Nil;
End;

destructor TBMPSampleList.Destroy;
Var ccListSection:TCriticalSection;
Begin
  ccListSection:= Self.cListSection;
  Inherited Destroy;
    // Звільняємо секцію тільки після Self.Clear, що викликається у Inherited Destroy:
  SysUtils.FreeAndNil(ccListSection);
End;

constructor TSampleGrabberCapturer.Create(
        sGraphController:TPlayVideoGraphController = Nil;
        CreateSuspended:Boolean = False);
Const cs_ProcName = 'TSampleGrabberCapturer.Create';
Begin
  Inherited Create(True);

  Self.FreeOnTerminate:=False;

  Self.cGraphController:= sGraphController;
  Self.cSampleQueriedCount:= 0;
  Self.cDataUseSection:= TCriticalSection.Create;
  Self.cSampleList:= TBMPSampleList.Create(True);
  Self.cSampleGrabber:= Nil;

  Self.cOnSample:= Nil;

  Self.cTerminateEvent:= ProcCreateEvent(cs_ProcName +
     cs_FailedToCreateEvent + cs_AboutThreadStopCommand +
        c_SystemSays,
       True,   // після виникнення скидається вручну (у цій програмі). Можна автоматом, яле тоді система сама скине якщо це було в іншому потоці і той інший завершився вже.
       False,   // подія створюється такою що ще не відбулася.
       Nil,   // подія не має імені (воно не треба, бо інші процеси цю подію не використовують і її важіль не успадковують)
       Self.cGraphController.LogFile);  // об'єкт для передачі повідомлень

  Self.cSampleCapturedEvent:= ProcCreateEvent(cs_ProcName +
     cs_FailedToCreateEvent + cs_AboutSampleCapturedEvent +
        c_SystemSays,
       True,   // після виникнення скидається вручну (у цій програмі). Можна автоматом, яле тоді система сама скине якщо це було в іншому потоці і той інший завершився вже.
       False,   // подія створюється такою що ще не відбулася.
       Nil,   // подія не має імені (воно не треба, бо інші процеси цю подію не використовують і її важіль не успадковують)
       Self.cGraphController.LogFile);  // об'єкт для передачі повідомлень


  Self.cSampleObtainer:= TSampleGrabberSampleObtainer.Create(Self);

  Self.cSampleGrabber:= Self.InitSampleGrabber;

  Self.SetCallbackForSampleGrabber;

  Self.cCurMediaType:= Nil;

  if Not CreateSuspended then Self.Resume;
End;

procedure TSampleGrabberCapturer.Terminate;
const cs_ProcName = 'TSampleGrabberCapturer.Terminate';
Begin
    // Спочатку встановлюємо помітку про те що треба завершувати роботу:
  Inherited Terminate;

  Self.StopCaptureSamples;

     // Потім даємо команду завершити роботу щоб потік почув її
     // якщо зараз чекає на подію:
  ProcSetEvent(Self.cTerminateEvent, cs_ProcName +
        cs_FailedToSetEvent+cs_AboutThreadStopCommand+
          c_SystemSays,
       Self.cGraphController.LogFile);

      // Якщо потік спить - будимо щоб він завершив роботу:
  while Self.Suspended do Self.Resume;
End;

destructor TSampleGrabberCapturer.Destroy;
const cs_ProcName = 'TSampleGrabberCapturer.Destroy';
Begin
  if Not(Self.Finished) then
  Begin
    Self.Terminate;
    Self.WaitFor;
  End;

  Self.cSampleObtainer.SampleCapturerFinishedWork;
  Self.cSampleObtainer:= Nil;

  Self.ProcDeleteCurMediaType;

  SysUtils.FreeAndNil(Self.cDataUseSection);

  SysUtils.FreeAndNil(Self.cSampleList);

  Self.cSampleGrabber:= Nil;

  ProcCloseHandle(Self.cTerminateEvent,
     cs_ProcName +
       cs_FailedToCloseEvent+cs_AboutThreadStopCommand +
       c_SystemSays,
     Self.cGraphController.LogFile);

  ProcCloseHandle(Self.cSampleCapturedEvent,
     cs_ProcName +
       cs_FailedToCloseEvent+cs_AboutSampleCapturedEvent +
       c_SystemSays,
     Self.cGraphController.LogFile);

  Inherited Destroy;
End;

Procedure TSampleGrabberCapturer.ProcChangeCurMediaType(
  sNewMediaType:PAMMediaType);
Begin
  Self.cDataUseSection.Enter;
  try
    if Self.cCurMediaType<>sNewMediaType then
    Begin
      Self.ProcDeleteCurMediaType;
      Self.cCurMediaType:= sNewMediaType;
    End;
  finally
    Self.cDataUseSection.Leave;
  end;
End;

Procedure TSampleGrabberCapturer.ProcDeleteCurMediaType;
Begin
  Self.cDataUseSection.Enter;
  try
    if Assigned(Self.cCurMediaType) then
    Begin
      DeleteMediaType(Self.cCurMediaType);
      Self.cCurMediaType:= Nil;
    End;
  finally
    Self.cDataUseSection.Leave;
  end;
End;

Function TSampleGrabberCapturer.ProcGetCurMediaType:PAMMediaType;
Const cs_ProcName = 'TSampleGrabberCapturer.ProcGetCurMediaType';
Var ccRes:HResult;
Begin
  Self.cDataUseSection.Enter;

  try
    if Assigned(Self.cCurMediaType) then
      Result:= Self.cCurMediaType
    Else
    Begin
      Result:= Nil;
      if Assigned(Self.cSampleGrabber) then
      Begin
        Self.cCurMediaType:= CoTaskMemAlloc(SizeOf(TAMMediaType));

        if Assigned(Self.cCurMediaType) then
        Begin
          Windows.ZeroMemory(Self.cCurMediaType, SizeOf(TAMMediaType));

          ccRes:= Self.cSampleGrabber.GetConnectedMediaType(Self.cCurMediaType^);

          if Failed(ccRes) then
          Begin
            Self.cGraphController.LogMessage(Nil, HResultToStr(cs_ProcName +
              ': cSampleGrabber.GetConnectedMediaType відмовило: ', ccRes));
            CoTaskMemFree(Self.cCurMediaType);
            Self.cCurMediaType:= Nil;
          End
          Else    // якщо SampleGrabber під'єднаний і його тип медіа вдалося прочитати:
          Begin
            Result:= Self.cCurMediaType;
          End;
        End
        Else
        Begin
          Self.cGraphController.LogMessage(Nil, cs_ProcName +
            ': не вистачило пам''яті для cCurMediaType (було треба '+
            IntToStr(SizeOf(TAMMediaType)) + ' байт...');
        End;


      End;
    End;
  finally
    Self.cDataUseSection.Leave;
  end;
End;

Procedure TSampleGrabberCapturer.SetOnSample(Value:TCallFromThreadOnSample);
Begin
  Self.cDataUseSection.Enter;
  try
    //if Addr(Self.cOnSample) <> Addr(Value) then
      Self.cOnSample:= Value;
  finally
    Self.cDataUseSection.Leave;
  end;
End;

function  TSampleGrabberCapturer.BufferCB(SampleTime: Double;
  pBuffer: PByte; BufferLen: longint): HResult;
Begin
  Result:= E_NOTIMPL;
End;

function  TSampleGrabberCapturer.SampleCB(SampleTime: Double;
  pSample: IMediaSample): HResult;
Const cs_ProcName = 'TSampleGrabberCapturer.SampleCB';
Var ccMediaType:PAMMediaType; ccRes:HResult; ccBufSize:LongInt;
    ccBMIInfo: TBitmapInfoHeader; ccBuffer:PByte;
Begin
  Result:= S_OK;
    // Не приймаємо кадри, якщо потік, що їх оброблює,
    // завершився (йому скомандували завершгитися):
  if Self.Finished then
    Exit;


  //Self.cDataUseSection.Enter;

  //try
    if Self.cSampleQueriedCount > 0 then // є запит захопити кадр
    Begin
      ccMediaType:= Nil;

        // Тут GetMediaType повертає S_False і ccMediaType=Nil, якщо тип медія
        // не змінився. Поточний тип треба читати у SampleGrabber після
        // його під'єднання. Тут перевіряти тільки чи він змінився.
        // Якщо змінився - замінити на новий, і пам'ятати його:
      ccRes:= pSample.GetMediaType(ccMediaType);


      if Failed(ccRes) then
      Begin
        Self.cGraphController.LogMessage(Nil, HResultToStr(cs_ProcName +
          ': pSample.GetMediaType відмовило: ', ccRes));
        Result:= ccRes;
      End
      Else
      Begin
          // Якщо тип медіа не мінявся і інтерфейс IMediaSample не повернув тип:
        if Assigned(ccMediaType) then
        Begin
          Self.ProcChangeCurMediaType(ccMediaType);
        End
        Else ccMediaType:= Self.ProcGetCurMediaType;

        if Assigned(ccMediaType) then
        Begin
            // Якщо тип даних на семплі має тип, сумісний із Bitmap, то:
          if Self.cGraphController.GetBitmapHeaderFromMEDIA_TYPEStruct(
            ccMediaType^, ccBMIInfo, 0) then
          Begin
            ccBufSize:= pSample.GetActualDataLength;

            if ccBufSize = 0 then
            Begin
              Self.cGraphController.LogMessage(Nil, cs_ProcName +
                ': pSample.GetActualDataLength повідомило що кадр пустий...');
              Result:=E_INVALIDARG;
            End
            Else
            Begin
              ccRes:= pSample.GetPointer(ccBuffer);
              if Failed(ccRes) then
              Begin
                Self.cGraphController.LogMessage(Nil, HResultToStr(cs_ProcName +
                  ': pSample.GetPointer відмовило: ', ccRes));
                Result:= ccRes;
              End
              Else
              Begin
                Self.cDataUseSection.Enter;
                try
                    //   Копіюємо кадр в окрему пам'ять і додаємо у список
                    // обробки кадрів:
                  Self.cSampleList.Add(Addr(ccBMiInfo), ccBuffer, ccBufSize, SampleTime);

                    //   Якщо запити на захоплення кадрів ще не скасували доки
                    // йшло тут копіювання кадра, то віднімаємо від лічильника
                    // запитів один запит (бо він виконаний, кадр скопійований у
                    // список із якого буде відправлений потоком куди треба...).
                    //   Якщо ж була комадна не захоплювати більше кадри поки цей
                    // копіювався, то це буде останній захоплений, але він буде
                    // оброблений.
                    //   Якщо захоплення не скасували і задано захоплювати
                    // необмежено - то теж не змінюємо лічильник:
                  if (Self.cSampleQueriedCount > 0)
                     and (Self.cSampleQueriedCount <> c_SamplesInfinite) then
                       Dec(Self.cSampleQueriedCount);

                    //   Подаємо сигнал для потока, що є кадри для обробки:
                  ProcSetEvent(Self.cSampleCapturedEvent, cs_ProcName +
                      cs_FailedToSetEvent+cs_AboutNewSampleCaptured+
                      c_SystemSays,
                      Self.cGraphController.LogFile);

                    //   Будимо потік обробки кадрів якщо він заснув:
                  while Self.Suspended do Self.Resume;
                finally
                  Self.cDataUseSection.Leave;
                end;
              End;
            End;
          End
          Else
          Begin
            Self.cGraphController.LogMessage(Nil, cs_ProcName +
              ': GetBitmapHeaderFromMEDIA_TYPEStruct не виявило підтримки формата Bitmap...');
            Result:= TYPE_E_WRONGTYPEKIND;  // тип даних не відео або не сумісне із Bitmap
          End;
        End;

        // Цього тут не робимо, запам'ятовуємо поточний тип медіа.
        // Він звільняється при ProcChangeCurMediaType і ProcDeleteCurMediaType:
        //DeleteMediaType(ccMediaType);
      End;

    End;
  //finally
  //  Self.cDataUseSection.Leave;
  //end;
End;

function TSampleGrabberRGB24BMPCapturer.InitSampleGrabber:ISampleGrabber;
Const cs_ProcName = 'TSampleGrabberRGB24BMPCapturer.InitSampleGrabber';
Var ccMediaType: TAMMediaType; ccRes:HResult;
    ccSampleGrabberAsFilter:IBaseFilter; ccSampleGrabberName:String;
    ccSampleGrabber:ISampleGrabber;
Begin
  Windows.ZeroMemory(Addr(ccMediaType), SizeOf(ccMediaType));
  ccMediaType.majortype:= MEDIATYPE_Video;
  ccMediaType.subtype:= MEDIASUBTYPE_RGB24;

  ccSampleGrabberAsFilter:= Nil;
  ccSampleGrabber:= Nil;

  Result:=Nil;

  ccSampleGrabberName:= 'SampleGrabber';

  If Self.cGraphController.AddFilter(Self.cGraphController.FGraphBuilder,
    CLSID_SampleGrabber, ccSampleGrabberAsFilter, ccSampleGrabberName) then
  Begin
    ccRes:= ccSampleGrabberAsFilter.QueryInterface(IID_ISampleGrabber,
      ccSampleGrabber);
    if Failed(ccRes) then
    Begin
      Self.cGraphController.LogMessage(Nil, HResultToStr(cs_ProcName +
        ': не вдалося отримати інтерфейс ISampleGrabber: ', ccRes));

      ccSampleGrabberAsFilter:= Nil;
    End
    Else
    Begin
      Result:= ccSampleGrabber;

      ccRes:= ccSampleGrabber.SetMediaType(ccMediaType);
      if Failed(ccRes) then
      Begin
        Self.cGraphController.LogMessage(Nil, HResultToStr(cs_ProcName +
          ': ccSampleGrabber.SetMediaType відмовило: ', ccRes));
      End;
    End;
  End;

  ccSampleGrabberAsFilter:= Nil;
  ccSampleGrabber:= Nil;
End;

Procedure TSampleGrabberCapturer.SetCallbackForSampleGrabber;
Const cs_ProcName = 'TSampleGrabberCapturer.SetCallbackForSampleGrabber';
Var ccRes:HResult;
Begin
  Self.cDataUseSection.Enter;
  try
    if Assigned(Self.cSampleGrabber) then
    Begin
        //   Копіювання кадрів в окремий буфер не вмикаємо, бо
        // використовується обробник SampleCB, і він сам копіює кадри:
      ccRes:= Self.cSampleGrabber.SetBufferSamples(False);
      if Failed(ccRes) then
      Begin
        Self.cGraphController.LogMessage(Nil, HResultToStr(cs_ProcName +
          ': cSampleGrabber.SetBufferSamples(False) відмовило: ', ccRes));
        Exit;
      End;
        //   Відворення не зупиняємо після захоплення кадра відразу.
        // Можливо треба буде ще захопити пізніше..:
      ccRes:= Self.cSampleGrabber.SetOneShot(False);
      if Failed(ccRes) then
      Begin
        Self.cGraphController.LogMessage(Nil, HResultToStr(cs_ProcName +
          ': cSampleGrabber.SetOneShot(False) відмовило: ', ccRes));
        Exit;
      End;
        //  Встановлюємо перехоплювач кадрів SampleCB:
      ccRes:= Self.cSampleGrabber.SetCallback(Self.cSampleObtainer, 0);
      if Failed(ccRes) then
      Begin
        Self.cGraphController.LogMessage(Nil, HResultToStr(cs_ProcName +
          ': cSampleGrabber.SetCallback відмовило: ', ccRes));
        Exit;
      End;
    End
    Else
    Begin
      Self.cGraphController.LogMessage(Nil, cs_ProcName +
        ': cSampleGrabber не створений...');
    End;
  finally
    Self.cDataUseSection.Leave;
  end;
End;

procedure TSampleGrabberCapturer.CaptureSamples(
            cSamplesCount:Cardinal = c_SamplesInfinite);
Begin
  Self.cDataUseSection.Enter;
  try
      //   Якщо захоплення вже задано необмеженим, то додавати до лічильника
      // запити про кадри немає сенсу. Інакше - додаємо:
    if Self.cSampleQueriedCount <> c_SamplesInfinite then
    Begin
      Self.cSampleQueriedCount:= Self.cSampleQueriedCount + cSamplesCount;
    End;
  finally
    Self.cDataUseSection.Leave;
  end;
End;

   //   CaptureSamples дає запит на отримання кадрів із вказуванням їх
         // кількості. Задана кількість додається до лічильника запитаних кадрів.
         // Кадри захоплюються по можливості послідовно, доки лічильник
         // запитаних не опуститься до нуля. Лічильник не знижується, якщо
         // задати cSamplesCount = c_SamplesInfinite (тоді кадри захоплюються
         // необмежено, доки відтворюється відео).
         //   CaptureSamples(0) не робить ефекту:
procedure TCaptureImageGraphController.CaptureSamples(cSamplesCount:Cardinal = c_SamplesInfinite);
Begin
  Self.cGraphBuilderUseSection.Enter;
  try
    if Assigned(Self.cSampleGrabberCapturer) then
    Begin
      Self.cSampleGrabberCapturer.CaptureSamples(cSamplesCount);
    End
    Else  // накопичуємо запити захоплення в лічильнику поки немає захоплювача:
    Begin
          //   Якщо захоплення вже задано необмеженим, то додавати до лічильника
          // запити про кадри немає сенсу. Інакше - додаємо:
      if Self.cSampleQueriedCount <> c_SamplesInfinite then
      Begin
        Self.cSampleQueriedCount:= Self.cSampleQueriedCount + cSamplesCount;
      End;
    End;
  finally
    Self.cGraphBuilderUseSection.Leave;
  end;
End;

   //   StopCaptureSamples обнуляє лічильник захоплення кадрів і припиняє
   // їх захоплення:
procedure TCaptureImageGraphController.StopCaptureSamples;
Begin
  Self.cGraphBuilderUseSection.Enter;
  try
    if Assigned(Self.cSampleGrabberCapturer) then
    Begin
      Self.cSampleGrabberCapturer.StopCaptureSamples;
    End
    Else  // якщо захоплювача зараз немає, то він і та кне захоплює.
          // Обнуляємо запити захоплення кадрів, що подані раніше:
    Begin
      Self.cSampleQueriedCount:= 0;
    End;
  finally
    Self.cGraphBuilderUseSection.Leave;
  end;
End;

procedure TSampleGrabberCapturer.StopCaptureSamples;
Begin
  Self.cDataUseSection.Enter;
  try
    Self.cSampleQueriedCount:= 0;
  finally
    Self.cDataUseSection.Leave;
  end;
End;

procedure TSampleGrabberCapturer.Execute;
Const cs_ProcName = 'Потік TSampleGrabberCapturer.Execute';
  c_EventCount = 2;
  c_SampleEventIndex = 0;
  c_TerminateCommandIndex = 1;
  c_WaitTimeOut = Windows.INFINITE; //180000; // 3 хвилини
Var
   cHandleArray: array [0..c_EventCount - 1] of THandle;
   cSignal:DWord;
   cInitRes: HResult;

   ccSample: PBMPSampleRec;
Begin
  try
    Self.cGraphController.LogMessage(Self, cs_ProcName+ sc_StartsItsWork);

    cInitRes:= CoInitializeEx(Nil, COINIT_MULTITHREADED); //COINIT_APARTMENTTHREADED

    if Failed(cInitRes) then
    Begin
      Self.cGraphController.LogMessage(Self, HResultToStr(cs_ProcName +
       cs_CoInitializeExFailed,
        cInitRes));
    End;

    while not(Self.Terminated) do
    Begin
      //if Not(Assigned(Self.cSampleList)) then
      //Begin
      //  Self.Suspend;
      //  Continue;
      //End;

      if Self.cSampleCapturedEvent = 0 then
      Begin
        Self.Suspend;
        Continue;
      End;

         // Масив подій, на які треба очікувати:
      cHandleArray[c_SampleEventIndex]:= Self.cSampleCapturedEvent; // події графа
      cHandleArray[c_TerminateCommandIndex]:= Self.cTerminateEvent; // подія команди завершення потока

        // Очікуємо одну із можливих подій:
      cSignal:= Windows.WaitForMultipleObjects(c_EventCount,
        Addr(cHandleArray[0]), False, c_WaitTimeOut);

      case cSignal of
        Windows.WAIT_FAILED:
        Begin
          Self.cGraphController.LogMessage(Self, FormatLastOSError(cs_ProcName +
            ': очікування на подію захоплення кадра повідомило про помилку: ').Message);
            // Спимо щоб не навантажувати процесор:
          Windows.Sleep(c_EmergencySleepTime);
          Continue;
        End;
        Windows.WAIT_OBJECT_0 + c_SampleEventIndex: // є захоплені кадри:
        Begin
            // Витягуємо зі списка кадр:
          ccSample:= Nil;

          Self.cDataUseSection.Enter;
          try
            if Self.cSampleList.Count > 0 then
              ccSample:= Self.cSampleList.ExtractFirst;

              //   Якщо це останній кадр у списку - то вимикаємо сигнал про те
              // що є кадри. Після обробки цього кадра будемо чекати на нові:
            if Self.cSampleList.Count <= 0 then
            Begin
              ProcResetEvent(Self.cSampleCapturedEvent,
                cs_ProcName +
                cs_FailedToResetEvent+cs_AboutNewSampleCaptured+
                c_SystemSays,
                Self.cGraphController.LogFile);
            End;
          finally
            Self.cDataUseSection.Leave;
          end;
             //   Запускаємо обробку кадра, який скопіювали у список і
             // витягли зі списка:
          if Assigned(ccSample) then
          Begin
            Self.ProcessSample(ccSample);

            if Assigned(ccSample) then // пам'ять кадра має бути звільнена у ProcessSample
            Begin
              Self.cGraphController.LogMessage(Self,
                cs_ProcName +
                ': метод ProcessSample класа-нащадка ""'+ Self.ClassName +
                '"" не обнулив кадр. Спробую звільнити від нього пам''ять...');
              try
                FreeBMPData(ccSample);
              except
                on E:Exception do
                begin
                  Self.cGraphController.LogMessage(Self, cs_ProcName +
                    ': пам''ять необнуленого кадра не вдалося звільнити... '+
                    'можливо метод ProcessSample класа-нащадка вже звільнив '+
                    'її сам, не обнуливши кадр :'+
                      E.ToString);
                end;
              end;
            End;
          End;

          //Self.cMediaEvent.GetEvent()
          //Self.DShowEventParamHandler();
        End;
        Windows.WAIT_OBJECT_0 + c_TerminateCommandIndex:;
        Windows.WAIT_TIMEOUT:
        Begin
          Self.cGraphController.LogMessage(Self,
              cs_ProcName +
              ': у графі не захоплювалися кадри '+
              IntToStr(c_WaitTimeOut) +
              ' мс. Чекатиму на захоплення далі...');
        End;
        Else
        Begin
          Self.cGraphController.LogMessage(Self, cs_ProcName +
            cs_UnknownResultOnWaitingEvent+
            IntToStr(cSignal)+'...');
            // Спимо щоб не навантажувати процесор:
          Windows.Sleep(c_EmergencySleepTime);
        End;
      end; // case cSignal of...
    End; // while not(Self.Terminated) do...

    if Not(Failed(cInitRes)) then
      CoUnInitialize;

    Self.cGraphController.LogMessage(Self, cs_ProcName+sc_FinishedItsWork);
  except
    on E:Exception do
    begin
      Self.cGraphController.LogMessage(Self, cs_ProcName + sc_FallenOnError+
        E.ToString);
    end;
  end;
End;

// Цей клас нічого не робить із захопленими кадрами
// (тільки викликає обробник OnSample, якщо він заданий). Тому тут
// лише звільняється пам'ять від кадра. Всі нащадки теж мають звільняти пам'ять
// від кадра після роботи з ним:
Procedure TSampleGrabberCapturer.ProcessSample(Var sdSample: PBMPSampleRec);
Const cs_ProcName = 'TSampleGrabberCapturer.ProcessSample';
Var ccOnSample:TCallFromThreadOnSample;
Begin
  ccOnSample:= Self.OnSample;
  if Assigned(Addr(ccOnSample)) then
  Begin
    try
      ccOnSample(Self, sdSample);
    except
      on E:Exception do
      Begin
        Self.cGraphController.LogMessage(Self, cs_ProcName +
          cs_OnSampleException +
          E.ToString);
      End;
    end;
  End;

  FreeBMPData(sdSample);
End;

Constructor TCaptureImageGraphController.Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
begin
  Inherited Create(sLogFile, True);

  Self.cRenderSamples:= True;
     //   Спочатку захоплювач кадрів не створений.
     // Він створюється при створенні графа:
  Self.cSampleGrabberCapturer:= Nil;
  Self.cOnSample:= Nil;
  Self.cSampleQueriedCount:= 0;

  Self.cAfterStop:= Self.ProcAfterStop;

  if Not CreateSuspended then Self.Resume;
end;

constructor TCaptureBitmapGraphController.Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
Begin
  Inherited Create(sLogFile, True);

  Self.cOnSampleAsBitmap:= Nil;

  if Not CreateSuspended then Self.Resume;
End;

Procedure TCaptureBitmapGraphController.SetOnSampleAsBitmap(
  Value: TCallFromThreadOnSampleAsBitmap);
Begin
  if Addr(Self.cOnSampleAsBitmap)<>Addr(Value) then
  Begin
    Self.cOnSampleAsBitmap:= Value;
    if Assigned(Value) then
      Inherited OnSample:= Self.ProcOnSample
    Else Inherited OnSample:= Nil;
  End;
End;

Procedure TCaptureBitmapGraphController.ProcOnSample(sCaller: TThread;
        sSample:PBMPSampleRec);
Const cs_ProcName = 'TCaptureBitmapGraphController.ProcOnSample';
Var ccOnSampleAsBitmap: TCallFromThreadOnSampleAsBitmap;
    ccBitmap:Graphics.TBitmap;
    ccBitmapInfo: TBitmapInfo;
    ccBufferInBitmap: Pointer;
    ccDIBHandle: HBITMAP;
Begin
  ccOnSampleAsBitmap:= Self.cOnSampleAsBitmap;
  if Assigned(ccOnSampleAsBitmap) then
  Begin

      // Формуємо об'єкт Bitmap за даними про Bitmap:
    ccBitmap:= Graphics.TBitmap.Create;

    try
      Windows.ZeroMemory(Addr(ccBitmapInfo), SizeOf(ccBitmapInfo));

      ccBitmapInfo.bmiHeader:= sSample.cBmpHead;

      ccBufferInBitmap:= Nil; // sSample.pBuffer;

      ccDIBHandle:= CreateDIBSection(0, ccBitmapInfo,
        DIB_RGB_COLORS, ccBufferInBitmap, 0, 0);
      if ccDIBHandle = 0 then
      Begin
        Self.LogMessage(Nil, FormatLastOSError(cs_ProcName +
              ': CreateDIBSection повідомило про помилку: ').Message);
        Exit;
      End;

      ccBitmap.Handle:= ccDIBHandle;
        // Копіюємо буфер даних Bitmap у виділену DIBSection:
      System.Move(sSample.pBuffer^, ccBufferInBitmap^, sSample.cBufferSize);

      try
        ccOnSampleAsBitmap(Self.cSampleGrabberCapturer, ccBitmap);
      except
        on E:Exception do
        Begin
          Self.LogMessage(Nil, cs_ProcName +
            cs_OnSampleException +
            E.ToString);
        End;
      end;
    finally
      ccBitmap.Free;
    end;
  End;
End;

constructor TCaptureJpegGraphController.Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False);
Begin
  Inherited Create(sLogFile, True);

  Self.cOnSampleAsJpeg:= Nil;
  Self.cCompressionQuality:= c_DefJpegCompressionQuality;

  if Not CreateSuspended then Self.Resume;
End;

Procedure TCaptureJpegGraphController.SetOnSampleAsJpeg(
  Value: TCallFromThreadOnSampleAsJpeg);
Begin
  if Addr(Self.cOnSampleAsJpeg)<>Addr(Value) then
  Begin
    Self.cOnSampleAsJpeg:= Value;
    if Assigned(Value) then
      Inherited OnSample:= Self.ProcOnSample
    Else Inherited OnSample:= Nil;
  End;
End;

Procedure TCaptureJpegGraphController.ProcOnSample(sCaller: TThread;
        sSample:Graphics.TBitmap);
Const cs_ProcName = 'TCaptureJpegGraphController.ProcOnSample';
Var ccOnSampleAsJpeg: TCallFromThreadOnSampleAsJpeg;
    ccJpeg:TJpegImage;
Begin
  ccOnSampleAsJpeg:= Self.cOnSampleAsJpeg;
  if Assigned(ccOnSampleAsJpeg) then
  Begin
    ccJpeg:= TJpegImage.Create;
    try
      ccJpeg.Assign(sSample);
      ccJpeg.CompressionQuality:= Self.CompressionQuality;
      ccJpeg.Compress;

      try
        ccOnSampleAsJpeg(Self.cSampleGrabberCapturer, ccJpeg);
      except
        on E:Exception do
        Begin
          Self.LogMessage(Nil, cs_ProcName +
            cs_OnSampleException +
            E.ToString);
        End;
      end;
    finally
      ccJpeg.Free;
    end;
  End;

End;

constructor TCaptureJpegToFileGraphController.Create(sLogFile:TLogFile = Nil;
              CreateSuspended:Boolean = False;
              sFilePathAndBaseName:String = '');
Begin
  Inherited Create(sLogFile, True);

  Self.cOnSampleAsJpegFile:= Nil;

  if sFilePathAndBaseName = '' then
  Begin
    Self.cFileDir:= '';
    Self.cFileNameStart:= '';
    Self.cFileExt:= cs_JpegExt;
  End
  Else
  Begin
    Self.cFileDir:= ExtractFilePath(sFilePathAndBaseName);
    Self.cFileExt:= ExtractFileExt(sFilePathAndBaseName);
    Self.cFileNameStart:= ExtractFileName(sFilePathAndBaseName);
    Self.cFileNameStart:= System.Copy(Self.cFileNameStart, 1,
      System.Length(Self.cFileNameStart)-System.Length(Self.cFileExt));
  End;

  if Self.cFileDir = '' then
    Self.cFileDir:= SysUtils.GetEnvironmentVariable('TEMP'); //ExtractFilePath(Application.ExeName);

  if Not(StrUtils.AnsiEndsStr(c_BackSlash, Self.cFileDir)) then
        Self.cFileDir:= Self.cFileDir + c_BackSlash;

  Self.cCounter:= 0;

    // Встановлюємо обробник запису кадрів у файли Jpeg:
  Inherited OnSample:= Self.ProcOnSample;

  if Not CreateSuspended then Self.Resume;
End;

Procedure TCaptureJpegToFileGraphController.SetOnSampleAsJpegFile(
   Value: TCallFromThreadOnSampleAsFile);
Begin
 if Addr(Self.cOnSampleAsJpegFile)<>Addr(Value) then
  Begin
    Self.cOnSampleAsJpegFile:= Value;
        // Цей обробник записує до файлів завжди, навіть якщо не треба передавати
        // їх шляхи іншим обробникам. Тому це виконується у конструкторі:
    //if Assigned(Value) then
    //  Inherited OnSample:= Self.ProcOnSample
    //Else Inherited OnSample:= Nil;
  End;
End;

Procedure TCaptureJpegToFileGraphController.ProcOnSample(
  sCaller: TThread; sSample:TJpegImage);
Const cs_ProcName = 'TCaptureJpegToFileGraphController.ProcOnSample';
Var ccOnSampleAsJpegFile: TCallFromThreadOnSampleAsFile;
    //ccJpeg:TJpegImage;
    ccCounter:Cardinal;
    ccFilePath:String;
Begin
  ccOnSampleAsJpegFile:= Self.cOnSampleAsJpegFile;

  ccCounter:= Self.cCounter;

  repeat
    Inc(ccCounter);
    ccFilePath:= Self.cFileDir + Self.cFileNameStart+
      IntToStr(ccCounter) + Self.cFileExt;
  until Not(SysUtils.FileExists(ccFilePath));
  Self.cCounter:= ccCounter;

  sSample.SaveToFile(ccFilePath);

  if Assigned(ccOnSampleAsJpegFile) then
  Begin
    try
      ccOnSampleAsJpegFile(Self.cSampleGrabberCapturer, ccFilePath);
    except
      on E:Exception do
        Begin
          Self.LogMessage(Nil, cs_ProcName +
            cs_OnSampleException +
            E.ToString);
        End;
    end;
  End;
End;

procedure TCaptureImageGraphController.Terminate;
Begin
  Inherited Terminate;
  if Assigned(Self.cSampleGrabberCapturer) then
    Self.cSampleGrabberCapturer.Terminate;
End;

destructor TCaptureImageGraphController.Destroy;
Begin
  if Not(Self.Finished) then
  Begin
    Self.Terminate;
    Self.WaitFor;
  End;

  SysUtils.FreeAndNil(Self.cSampleGrabberCapturer);

  Inherited Destroy;
End;

Function TCaptureImageGraphController.RenderStreams(sGraphBuilder: IGraphBuilder;
        sSourceFilterOrPin:IUnknown;
        Var dVideoRenderer:IBaseFilter; Var dAudioRenderer:IBaseFilter;
        sSourceName:String = ''):Boolean;
Const cs_ProcName = 'TCaptureImageGraphController.RenderStreams';
Var Res1:HResult; cErrorMsg:String;
    // Розширений будувач графа, що має функції зв'язування фільтрів та
    //  автовиводу від фільтрів за типом медіапотоку, без вказування пунктів
    //  входу-виходу...:
  FCaptureGraphBuilder: ICaptureGraphBuilder2;
  RenderedStreamCount:Byte;
  ccVideoRenderer, ccAudioRenderer, ccSampleGrabber:IBaseFilter;

  ccRenderVideo, ccRenderAudio, ccRenderSamples: Boolean;

  Procedure ProcFreeVars;
  Begin
    FCaptureGraphBuilder:=Nil;
    ccVideoRenderer:= Nil;
    ccAudioRenderer:= Nil;
    ccSampleGrabber:= Nil;
  End;
Begin
  dVideoRenderer:= Nil;
  dAudioRenderer:= Nil;

  ccSampleGrabber:= Nil;

  ccRenderVideo:= Self.RenderVideo;
  ccRenderAudio:= Self.RenderAudio;
  ccRenderSamples:= Self.cRenderSamples;

  // Це тут не треба, буде зроблено при присвоєнні:
  //  // Звільняємо об'єкт захоплювача кадрів, якщо він був:
  //if Assigned(Self.SampleGrabberCapturer) then
  //Begin
  //  Self.SampleGrabberCapturer.Free;
  //  Self.SampleGrabberCapturer:= Nil;
  //End;

  if Not(ccRenderVideo or ccRenderAudio or ccRenderSamples) then
  Begin
    Result:=True;
    Exit;
  End;

  if Not(Assigned(sGraphBuilder)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName + cs_FGraphBuilderAbsent);
    Result:=False;
    Exit;
  End;

  if Not(Assigned(sSourceFilterOrPin)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName+': не задано інтерфейс джерела потока(-ів) sSourceFilterOrPin...');
    Result:=False;
    Exit;
  End;

  FCaptureGraphBuilder:=Nil;

  RenderedStreamCount:=0;

    // Створюємо фільтри, до яких має дотягнутися граф:

  if ccRenderVideo then
  Begin
    ccVideoRenderer:=Self.CreateVideoRenderer(sGraphBuilder);
    if Not(Assigned(ccVideoRenderer)) then
    Begin
      Result:=False;
      ProcFreeVars;
      Exit;
    End;

    dVideoRenderer:= ccVideoRenderer;
  End
    // Якщо відображення відео не треба, але потрібно захоплювати кадри, то
    // для закінчення гілки відеографа додаємо NullRenderer:
  Else if ccRenderSamples then
  Begin
    ccVideoRenderer:=Self.CreateNullRenderer(sGraphBuilder);
    if Not(Assigned(ccVideoRenderer)) then
    Begin
      Result:=False;
      ProcFreeVars;
      Exit;
    End;

    dVideoRenderer:= ccVideoRenderer;
  End;

  if ccRenderSamples then
  Begin
    Self.SampleGrabberCapturer:= TSampleGrabberRGB24BMPCapturer.Create(Self, False);
    if Assigned(Self.SampleGrabberCapturer.SampleGrabber) then
    Begin
      ccSampleGrabber:= Self.SampleGrabberCapturer.SampleGrabber as IBaseFilter;
    End
    Else
    Begin
      Result:=False;
      ProcFreeVars;
      Exit;
    End;
  End;


  if ccRenderAudio then
  Begin
    ccAudioRenderer:= Self.CreateAudioRenderer(sGraphBuilder);
    if Not(Assigned(ccAudioRenderer)) then
    Begin
      Result:=False;
      ProcFreeVars;
      Exit;
    End;
    dAudioRenderer:= ccAudioRenderer;
  End;

  //ccAudioRenderer.Stop;
  //ccVideoRenderer.Stop;

    // Для побудови графа від заданого фільтра:
  Res1:= CoCreateInstance(CLSID_CaptureGraphBuilder2, nil, CLSCTX_INPROC_SERVER,
    IID_ICaptureGraphBuilder2, FCaptureGraphBuilder);
  if Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(cs_ProcName+': не удалось создать COM-объект CaptureGraphBuilder2... ',
      Res1));
    Result:=False;
    ProcFreeVars;
    Exit;
  End;

  Res1:= FCaptureGraphBuilder.SetFilterGraph(sGraphBuilder);
  if Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(cs_ProcName+': не удалось установить для CaptureGraphBuilder2 ранее созданный построитель FilterGraph... ',
      Res1));
    Result:=False;
    ProcFreeVars;
    Exit;
  End;

  if sSourceName = '' then
    GetPinAndOrFilterName(sSourceFilterOrPin, sSourceName, cErrorMsg);

     // Створюємо захоплювач кадрів:


     // Будуємо граф відтворення із вставленим в нього відтворювачем кадрів.
     // (якщо стандартне відтворення не потрібне - то треба створити Null renderer і вказати що вкінці має бути він)

  if ccRenderVideo or ccRenderSamples then
  Begin
        // Будуємо граф відеопотока:
    Res1:= Self.TryRenderToFilters(FCaptureGraphBuilder, sSourceFilterOrPin,
      sSourceName, Nil, Nil,
      ccSampleGrabber,
      ccVideoRenderer);
    if Not(Res1 = S_OK) then
    Begin
      Self.LogMessage(Nil, HResultToStr(
           cs_ProcName+': от фильтра или пина '+sSourceName+
           ' не удалось получить поток видео... TryRenderToFilters возвратило: '
           , Res1));
         //cAutoGraph:= True;
    End
    else Inc(RenderedStreamCount);
  End;

  if ccRenderAudio then
  Begin
        //   Побудова графа відображення аудіо від фільтра джерела:
    Res1:= Self.TryRenderToFilters(FCaptureGraphBuilder, sSourceFilterOrPin,
      sSourceName, Nil, Nil,
      Nil,
      ccAudioRenderer);
    //Res1:= FCaptureGraphBuilder.RenderStream(Nil, Nil, //@MediaType_Audio,
    //   sSourceFilterOrPin,  // від фільтра-читача джерела медіа
    //   nil,    // через будь-які розпакувальники, автовизначення без обмежень
    //   ccAudioRenderer     // на типовий відтворювач звука
    //   );
    if Not(Res1 = S_OK) then
    Begin
      Self.LogMessage(Nil, HResultToStr(cs_ProcName+': от фильтра или пина '+sSourceName+
         ' не удалось получить поток аудио... TryRenderToFilters возвратило: ',
         Res1));
      //cAutoGraph:= True;
    End
    else Inc(RenderedStreamCount);
  End;

  Result:= RenderedStreamCount > 0;

  ProcFreeVars;
End;

Procedure TCaptureImageGraphController.ProcAfterStop(sCaller: TThread;
        Const sState, sLastState:TFilterState;
        sSTATE_INTERMEDIATE, sCANT_CUE:Boolean;
        sStateRes, sLastStateRes:HResult;
         sCurURL, sLastURL, sCurName_ch:String);
Begin
    //   Після зупинки відтворення звільняємо захоплювач кадрів,
    // і читаємо перед тим чи є замовлені кадри, які він не
    // захопив (бо вони не прийшли до зупинки). При наступному запуску
    // і створенні захоплювача цю кількість кадрів буде скомандувано
    // захопити:
  Self.SampleGrabberCapturer:= Nil;
End;

Function TCaptureImageGraphController.CreateNullRenderer(
  sGraphBuilder: IGraphBuilder):IBaseFilter;
Const cs_ProcName = 'TCaptureImageGraphController.CreateNullRenderer';
Var dFilterName: String;
Begin     // Створення типового відтворювача відео:
  Result:= Nil;

  dFilterName:= 'NullRenderer';

  If Not(Self.AddFilter(sGraphBuilder,
      CLSID_NullRenderer
      , Result, dFilterName)) then
  Begin
    Result:=Nil;
    Exit;
  End;
End;

procedure TPlayVideoGraphController.Terminate;
Begin
  Inherited Terminate;
  if Assigned(Self.cProcQueryThread) then
    Self.cProcQueryThread.Terminate;
End;

destructor TPlayVideoGraphController.Destroy;
Begin
  if Not(Self.Finished) then
  Begin
    Self.Terminate;
    Self.WaitFor;
  End;

  SysUtils.FreeAndNil(Self.cProcQueryThread);

  Self.cVMRWindowlessControl:= Nil;

  Inherited Destroy;
End;

Constructor TSampleGrabberSampleObtainer.Create(
        sSampleGrabberCapturer:TSampleGrabberCapturer);
Begin
  Inherited Create;

  Self.cSampleCapSection:= TCriticalSection.Create;
  Self.cSampleGrabberCapturer:= sSampleGrabberCapturer;
End;

Destructor TSampleGrabberSampleObtainer.Destroy;
Begin
  Self.SampleCapturerFinishedWork;

  SysUtils.FreeAndNil(Self.cSampleCapSection);

  Inherited Destroy;
End;

procedure TSampleGrabberSampleObtainer.SampleCapturerFinishedWork;
Begin
  Self.cSampleCapSection.Enter;
  try
    Self.cSampleGrabberCapturer:= Nil;
  finally
    Self.cSampleCapSection.Leave;
  end;
End;

function TSampleGrabberSampleObtainer.SampleCB(SampleTime: Double;
  pSample: IMediaSample): HResult; stdcall;
Var ccSampleGrabberCapturer: TSampleGrabberCapturer;
Begin
  Self.cSampleCapSection.Enter;
  try
    ccSampleGrabberCapturer:= Self.cSampleGrabberCapturer;
    if Assigned(ccSampleGrabberCapturer) then
      Result:=ccSampleGrabberCapturer.SampleCB(SampleTime,
        pSample)
   else Result:= S_OK;
  finally
    Self.cSampleCapSection.Leave;
  end;
End;

function TSampleGrabberSampleObtainer.BufferCB(SampleTime: Double;
  pBuffer: PByte; BufferLen: longint): HResult; stdcall;
Var ccSampleGrabberCapturer: TSampleGrabberCapturer;
Begin
  Self.cSampleCapSection.Enter;
  try
    ccSampleGrabberCapturer:= Self.cSampleGrabberCapturer;

    if Assigned(ccSampleGrabberCapturer) then
      Result:=ccSampleGrabberCapturer.BufferCB(SampleTime,
        pBuffer, BufferLen)
    else Result:= S_OK;
  finally
    Self.cSampleCapSection.Leave;
  end;
End;


Function TPlayVideoGraphController.CreateGraph(Const sUrl, sName_ch:String):Boolean;
Const cs_ProcName = 'TPlayVideoGraphController.CreateGraph';
Var
    //Res1: HResult;
    cSourceFilter:IBaseFilter;
    cSourceFilterName:String;
    //cMessage:String;

    ccGraphBuilder: IGraphBuilder;

    cVideoRenderer, cAudioRenderer:IBaseFilter;

    cPinList:IInterfaceList;  // список під'єднаних пінів відеорендерера
    ccVideoWidth, ccVideoHeight:Integer;

    Procedure ProcAbort;
    Begin
      ccGraphBuilder:= Nil;
      cSourceFilter:= Nil;
      Self.LogMessage(Nil, cs_ProcName + ': не вдалося під''єднатися до "'+sUrl+
        '"...');
    End;
begin

  Result:=False;
    // При перебудові графа розміри картинки вважаємо новими. Тому перед
    // їх отриманням скидаємо їх в нуль:
  Self.cVideoWidth:= 0;
  self.cVideoHeight:= 0;

  cVideoRenderer:= Nil;
  cAudioRenderer:= Nil;

  //Self.cGraphBuildRunning:= True;

  //Self.cUrl:=

 //Self.Url:= Url;
 //Self.Name_ch:= Name_ch;

  //Self.Caption:= Name_ch;

  //Self.cCurURL:= Url;

  ccGraphBuilder:= Nil;

  Self.LogMessage(Nil, cs_ProcName + ': під''єднання до "'+sUrl+'"...');

  //try
      //освобождаем подключенные интерфейсы
    //if Assigned(Self.FMediaControl) then FMediaControl:= NIL;
    //if Assigned(Self.FVideoWindow)  then FVideoWindow := NIL;
    if Assigned(Self.FGraphBuilder) then Self.FGraphBuilder:= NIL;

      //   Выходим если канал не выбран:
    if sUrl='' then Exit;
      // Створюємо граф DirectShow:
    if Not Self.CreateFilterGraph(ccGraphBuilder) then Exit;

      // Пробуємо відкрити потік за допомогою фільтра LAVSplitterSource:
    if Not(Self.AddSourceFilter(ccGraphBuilder, CLSID_LAVSplitterSource, sUrl,
       cSourceFilter, cSourceFilterName)) then
    Begin           // якщо не вийшло:
        // створюємо новий граф (бо в старому міг лишитися фільтр, яким не вдалося відкрити):
      if Not Self.CreateFilterGraph(ccGraphBuilder) then Exit;
        // Пробуємо знайти потрібний фільтр автоматично і відкрити потік:
      if Not(Self.AddSourceFilter(ccGraphBuilder, sUrl,
        cSourceFilter, cSourceFilterName)) then
      Begin
        ProcAbort;
        Exit;
      End;
    End;
      //   Якщо знайшли потрібний кодек - вписуємо будувач графа в об'єкт.
      // При цьому запрошується інтерфейс подій графа, починають працювати їх
      // обробники. І далі граф можна записати у файл для наладки,
      // навіть якщо до кінця його не вдасться побудувати...:
    Self.FGraphBuilder:= ccGraphBuilder;

    If Not (Self.RenderStreams(ccGraphBuilder, cSourceFilter,
       cVideoRenderer, cAudioRenderer,
       cSourceFilterName)) then
    Begin
      ProcAbort;
      Exit;
    End;

    if Assigned(cVideoRenderer) then
    Begin
        // Читаємо розмір відеокартинки:
      cPinList:= Self.GetPinArray(cVideoRenderer, PINDIR_INPUT, True,
        Addr(MEDIATYPE_Video));
      if cPinList.Count>=1 then
      Begin
        if Self.GetVideoSizeOnConnectedPin(IPin(cPinList[0]),
          ccVideoWidth, ccVideoHeight) then
        Begin
          Self.VideoWidth:= ccVideoWidth;
          Self.VideoHeight:= ccVideoHeight;
        End;
      End;
    End;

    Self.FGraphBuilder:= ccGraphBuilder;

    Result:= True;
 {Запуск графа виконується в інших процедурах: SetNewGraphBuilder; RunGraph:
 //получаем интерфейс ImediaControl
 FGraphBuilder.QueryInterface(IID_IMediaControl, FMediaControl);

 //получаем интерфейс IVideoWindow
 FGraphBuilder.QueryInterface(IID_IVideoWindow, FVideoWindow);

 //распологаем окно вывода на Panel1
 FVideoWindow.put_Owner(Panel1.Handle);
 FVideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
 FVideoWindow.put_MessageDrain(Panel1.Handle);
 FVideoWindow.SetWindowPosition(0, 0, Panel1.ClientRect.Right,Panel1.ClientRect.Bottom);

 //запускаем на воспроизведение
 if sStartPaused then Res1:=Self.FMediaControl.Pause
 Else Res1:=FMediaControl.Run;

 if Failed(Res1) then
 Begin
   Self.LogMessage(HResultToStr(cs_ProcName + ': ошибка при запуске графа: ',
     Res1));
 End;}

 //finally
   //Self.cGraphBuildRunning:= False;
 //End;
End;

Procedure TPlayVideoGraphController.SetRenderVideo(Value:Boolean);
Begin
  //Self.cDestStateUseSection.Enter;
  //try
    if Self.cRenderVideo<>Value then
      Self.cRenderVideo:= Value;
  //finally
  //  Self.cDestStateUseSection.Leave;
  //end;
End;
Procedure TPlayVideoGraphController.SetRenderAudio(Value:Boolean);
Begin
  //Self.cDestStateUseSection.Enter;
  //try
    if Self.cRenderAudio<>Value then
      Self.cRenderAudio:= Value;
  //finally
  //  Self.cDestStateUseSection.Leave;
  //end;
End;

Procedure TCaptureImageGraphController.SetRenderSamples(Value:Boolean);
Begin
  if Self.cRenderSamples<>Value then
      Self.cRenderSamples:= Value;
End;

Procedure TCaptureImageGraphController.SetOnSample(Value:TCallFromThreadOnSample);
Begin
  if Addr(Self.cOnSample)<>Addr(Value) then
  Begin
    Self.cOnSample:= Value;
    if Assigned(Self.SampleGrabberCapturer) then
      Self.SampleGrabberCapturer.OnSample:= Value;
  End;
End;

Procedure TCaptureImageGraphController.SetSampleGrabberCapturer(
  Value:TSampleGrabberCapturer);
Begin
  Self.cGraphBuilderUseSection.Enter;
  try
    if Self.cSampleGrabberCapturer<>Value then
    Begin
      if Assigned(Self.cSampleGrabberCapturer) then
      Begin
          //   Запам'ятовуємо, скільки кадрів захоплювач ще не захопив
          // (щоб захопити їх при наступному створенні захоплювача
          // і захоплюванні):
        Self.cSampleQueriedCount:= Self.cSampleQueriedCount +
          Self.cSampleGrabberCapturer.cSampleQueriedCount;
           //   Звільняємо захоплювач. Тому перед присвоєнням нового захоплювача
           // звільняти його не можна!..:
        SysUtils.FreeAndNil(Self.cSampleGrabberCapturer);
      End;

      Self.cSampleGrabberCapturer:= Value;
      if Assigned(Value) then
      Begin
        Value.OnSample:= Self.OnSample;
          // Передаємо запити на захоплення карів до об'єкта керування захоплювачем:
        if Self.cSampleQueriedCount<>0 then
        Begin
          Value.CaptureSamples(Self.cSampleQueriedCount);
          Self.cSampleQueriedCount:= 0;
        End;
      End;
    End;
  finally
    Self.cGraphBuilderUseSection.Leave;
  end;
End;

Procedure TPlayVideoGraphController.ReportVideoWidth(Value:Integer);
Begin
  if Self.cVideoWidth <> Value then
  Begin
    Self.cVideoWidth:= Value;
    Self.ReportVideoWidthHeightChanged;
  End;
End;

Procedure TPlayVideoGraphController.ReportVideoHeight(Value:Integer);
Begin
  if Self.cVideoHeight <> Value then
  Begin
    Self.cVideoHeight:= Value;
    Self.ReportVideoWidthHeightChanged;
  End;
End;

Procedure TPlayVideoGraphController.ReportVideoWidthHeightChanged;
Var ccVideoWidth, ccVideoHeight:Integer; ccOnGraphEvent:TCallFromThreadOnGraphEvent;
    ccParam1:LongWord;
Begin
    //   Повідомлення посилаємо тільки якщо координати прочитав цей потік.
    // Якщо це був інший (потік читання подій графа), то тут нічого не
    // робимо, тільки запам'ятовуємо
    // розміри відео у ReportVideoHeight і ReportVideoWidth.
    //   Потік читання подій графа сам пошле поідомлення програмі
    // про подію, якщо граф про неї повідомив. Тут надсилається повідомлення
    // тільки тоді коли події зміни розміру відео не було
    // (граф не повідомив про неї), але розмір встановлений:
  if GetCurrentThreadID = Self.ThreadID then
  Begin
    ccOnGraphEvent:= Self.OnGraphEvent;
    ccVideoWidth:= Self.cVideoWidth;
    ccVideoHeight:= Self.cVideoHeight;

    if Assigned(ccOnGraphEvent) then
    Begin
      Put16WordsToLong(ccParam1, ccVideoWidth, ccVideoHeight);

      ccOnGraphEvent(Self, EC_VIDEO_SIZE_CHANGED, ccParam1, 0,
        'Video size discovered on graph have built',
        'Отримано розмір відео після побудови графа');
    End;
  End;
End;

Function TPlayVideoGraphController.CheckVideoBeingRendered:Boolean;
Begin
  Result:= Assigned(Self.cVMRWindowlessControl);
End;

Function TPlayVideoGraphController.CreateFilterGraph(
           Var sGraphBuilder:IGraphBuilder):Boolean;
const cs_ProcName = 'TPlayVideoGraphController.CreateFilterGraph';
Var Res1:HResult;
Begin
   Result:= True;

   sGraphBuilder:= Nil;

    //получаем интерфейс IGraphBuilder
   Res1:= CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER,
     IID_IGraphBuilder, sGraphBuilder);
   if Failed(Res1) then
   Begin
     Self.LogMessage(Nil, HResultToStr(cs_ProcName +
       ': не удалось создать COM-объект FilterGraph... ',
       Res1));
     Result:= False;
   End;
   {else
   Begin
     Res1:= FGraphBuilder.QueryInterface(IID_IMediaEventEx, fMediaEventEx);
     if Failed(Res1) then
     Begin
       Self.LogMessage(HResultToStr('Не удалось получить интерфейс IMediaEventEx от FilterGraph... ',
         Res1));
       Result:= False;
     End
     Else
     Begin
       if Failed(fMediaEventEx.SetNotifyWindow(Application.MainFormHandle,
         cMessageIDForDSEvents, c_lParamForDSHandler)) then
       Begin
         Self.LogMessage(FormatLastOsError('MediaEventEx.SetNotifyWindow: не вдалося встановити вікно надсилання повідомлень графа:').Message);
       End
       Else
       Begin
         if Failed(fMediaEventEx.SetNotifyFlags(0)) then
         Begin
           Self.LogMessage(FormatLastOsError('MediaEventEx.SetNotifyWindow: не вдалося ввімкнути надсилання повідомлень графа:').Message);
         End;
       End;
     End;
   End;}
End;

Function TPlayVideoGraphController.RenderStreams(sGraphBuilder: IGraphBuilder;
        sSourceFilterOrPin:IUnknown;
        Var dVideoRenderer:IBaseFilter; Var dAudioRenderer:IBaseFilter;
        sSourceName:String = ''):Boolean;
Const cs_ProcName = 'TPlayVideoGraphController.RenderStreams';
Var Res1:HResult; cErrorMsg:String;
    // Розширений будувач графа, що має функції зв'язування фільтрів та
    //  автовиводу від фільтрів за типом медіапотоку, без вказування пунктів
    //  входу-виходу.. Для поділу потоків із кількома відео чи аудіодоріжками
    //  всеодно треба зв'язувати на рівні пунктів входу-виходу потоків...
    // Але тут використовується це...:
  FCaptureGraphBuilder: ICaptureGraphBuilder2;
  RenderedStreamCount:Byte;
  ccVideoRenderer, ccAudioRenderer:IBaseFilter;

  ccRenderVideo, ccRenderAudio: Boolean;

  Procedure ProcFreeVars;
  Begin
    FCaptureGraphBuilder:=Nil;
    ccVideoRenderer:= Nil;
    ccAudioRenderer:= Nil;
  End;
Begin
  dVideoRenderer:= Nil;
  dAudioRenderer:= Nil;

  ccRenderVideo:= Self.RenderVideo;
  ccRenderAudio:= Self.RenderAudio;

  if Not(ccRenderVideo or ccRenderAudio) then
  Begin
    Result:=True;
    Exit;
  End;

  if Not(Assigned(sGraphBuilder)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName + cs_FGraphBuilderAbsent);
    Result:=False;
    Exit;
  End;

  if Not(Assigned(sSourceFilterOrPin)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName+': не задано інтерфейс джерела потока(-ів) sSourceFilterOrPin...');
    Result:=False;
    Exit;
  End;

  FCaptureGraphBuilder:=Nil;

  RenderedStreamCount:=0;

  if ccRenderVideo then
  Begin
      // Створюємо фільтри, до яких має дотягнутися граф:
    ccVideoRenderer:=Self.CreateVideoRenderer(sGraphBuilder);
    if Not(Assigned(ccVideoRenderer)) then
    Begin
      Result:=False;
      ProcFreeVars;
      Exit;
    End;

    dVideoRenderer:= ccVideoRenderer;
  End;

  if ccRenderAudio then
  Begin
    ccAudioRenderer:= Self.CreateAudioRenderer(sGraphBuilder);
    if Not(Assigned(ccAudioRenderer)) then
    Begin
      Result:=False;
      ProcFreeVars;
      Exit;
    End;
    dAudioRenderer:= ccAudioRenderer;
  End;

  //ccAudioRenderer.Stop;
  //ccVideoRenderer.Stop;

    // Для побудови графа від заданого фільтра:
  Res1:= CoCreateInstance(CLSID_CaptureGraphBuilder2, nil, CLSCTX_INPROC_SERVER,
    IID_ICaptureGraphBuilder2, FCaptureGraphBuilder);
  if Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(cs_ProcName+': не удалось создать COM-объект CaptureGraphBuilder2... ',
      Res1));
    Result:=False;
    ProcFreeVars;
    Exit;
  End;

  Res1:= FCaptureGraphBuilder.SetFilterGraph(sGraphBuilder);
  if Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(cs_ProcName+': не удалось установить для CaptureGraphBuilder2 ранее созданный построитель FilterGraph... ',
      Res1));
    Result:=False;
    ProcFreeVars;
    Exit;
  End;

  if sSourceName = '' then
    GetPinAndOrFilterName(sSourceFilterOrPin, sSourceName, cErrorMsg);

     // Створюємо захоплювач кадрів:


     // Будуємо граф відтворення із вставленим в нього відтворювачем кадрів.
     // (якщо стандартне відтворення не потрібне - то треба створити Null renderer і вказати що вкінці має бути він)

  if ccRenderVideo then
  Begin
        // Будуємо граф відеопотока:
    Res1:= Self.TryRenderToFilters(FCaptureGraphBuilder, sSourceFilterOrPin,
      sSourceName, Nil, Nil,
      Nil,
      ccVideoRenderer);
    if Not(Res1 = S_OK) then
    Begin
      Self.LogMessage(Nil, HResultToStr(
           cs_ProcName+': от фильтра или пина '+sSourceName+
           ' не удалось получить поток видео... TryRenderToFilters возвратило: '
           , Res1));
         //cAutoGraph:= True;
    End
    else Inc(RenderedStreamCount);
  End;

  if ccRenderAudio then
  Begin
        //   Побудова графа відображення аудіо від фільтра джерела:
    Res1:= Self.TryRenderToFilters(FCaptureGraphBuilder, sSourceFilterOrPin,
      sSourceName, Nil, Nil,
      Nil,
      ccAudioRenderer);
    //Res1:= FCaptureGraphBuilder.RenderStream(Nil, Nil, //@MediaType_Audio,
    //   sSourceFilterOrPin,  // від фільтра-читача джерела медіа
    //   nil,    // через будь-які розпакувальники, автовизначення без обмежень
    //   ccAudioRenderer     // на типовий відтворювач звука
    //   );
    if Not(Res1 = S_OK) then
    Begin
      Self.LogMessage(Nil, HResultToStr(cs_ProcName+': от фильтра или пина '+sSourceName+
         ' не удалось получить поток аудио... TryRenderToFilters возвратило: ',
         Res1));
      //cAutoGraph:= True;
    End
    else Inc(RenderedStreamCount);
  End;

  Result:= RenderedStreamCount > 0;
  ProcFreeVars;
End;

Function TPlayVideoGraphController.CreateVideoRenderer(
           sGraphBuilder: IGraphBuilder):IBaseFilter;
Const cs_ProcName = 'TPlayVideoGraphController.CreateVideoRenderer';
Var dFilterName: String; //Res1:HResult;
Begin     // Створення типового відтворювача відео:
  Result:= Nil;

    //CLSID_VideoMixingRenderer
    //CLSID_VideoRendererDefault

  dFilterName:= 'VideoRenderer';

  If Not(Self.AddFilter(sGraphBuilder,
      CLSID_VideoRendererDefault //CLSID_VideoRenderer
      , Result, dFilterName)) then
  Begin
    Result:=Nil;
    Exit;
  End;

     //   Присвоюємо для фільтра відображення відео вікно програми, на якому
     // буде йти відображення (якщо важіль вікна був заданий у
     // SetupVideoWindow перед цією побудовою графа):
  Self.cVMRWindowlessControl:=
    Self.InitVideoMediaRendererOnWindow(Result);
End;
Function TPlayVideoGraphController.CreateAudioRenderer(
           sGraphBuilder: IGraphBuilder):IBaseFilter;
Const cs_ProcName = 'TPlayVideoGraphController.CreateAudioRenderer';
Var dFilterName:String; //Res1:HResult;
Begin     // Створення типового відтворювача звука на звукову карту, що встановлена як типова:
  Result:= Nil;

    //CLSID_DSoundRender

  dFilterName:= 'AudioRenderer';

  If Not(Self.AddFilter(sGraphBuilder,
      CLSID_DSoundRender, //CLSID_AudioRender,
      Result, dFilterName)) then
  Begin
    Result:=Nil;
    Exit;
  End;
End;

Function TPlayVideoGraphController.AddFilter(sGraphBuilder:IGraphBuilder;
        sFilterCLSID: TGUID;
        Var dFilter:IBaseFilter; Var sdFilterName:String):Boolean;
Const cs_ProcName='TPlayVideoGraphController.AddFilter';
Var Res1:HResult;
    //FSourceFilterInterface:IFileSourceFilter;
    cErrorMsg, cFilterGUIDStr:String;
    sFilterNamePChar:PWideChar;
Begin
  if Not(Assigned(sGraphBuilder)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName + cs_FGraphBuilderAbsent);
    Result:=False;
    Exit;
  End;

  dFilter:= Nil;
  Result:=True;

  cFilterGUIDStr:= ComObj.GUIDToString(sFilterCLSID);

  Res1:= ActiveX.CoCreateInstance(sFilterCLSID, Nil, CLSCTX_INPROC_SERVER,
    IID_IBaseFilter, dFilter);
  if Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(cs_ProcName +
      ': не удалось создать объект фильтра '+
      cFilterGUIDStr+'... CoCreateInstance возвратило: ', Res1));
    Result:=False;
    Exit;
  End;

      // Додаємо фільтр джерела до графа:
  if sdFilterName = '' then
    sFilterNamePChar:= Nil
  Else sFilterNamePChar:= PWideChar(sdFilterName);

  Res1:= sGraphBuilder.AddFilter(dFilter, sFilterNamePChar);
  if Failed(Res1) then
  Begin
    sdFilterName:= cFilterGUIDStr;

    Self.LogMessage(Nil, HResultToStr(cs_ProcName + ': фильтр '+sdFilterName+
      ' не удалось добавить в граф... : ',
     Res1));
    Result:=False;
  End
  else
  Begin
      // При додаванні у граф назва фільтра модифікується, тому отримуємо її тут:
    if Not(GetPinAndOrFilterName(dFilter, sdFilterName, cErrorMsg)) then
    Begin
      sdFilterName:= cFilterGUIDStr;
      Self.LogMessage(Nil, cs_ProcName + ': не удалось определить имя фильтра ' +
        cFilterGUIDStr + ', ' + cErrorMsg);
    End;
  End;

End;

Function TPlayVideoGraphController.AddSourceFilter(sGraphBuilder:IGraphBuilder;
        sFilterCLSID: TGUID;
        sUrlOrFileName:String;
        Var dFilter:IBaseFilter; Var dFilterName:String):Boolean;
Const cs_ProcName='TPlayVideoGraphController.AddSourceFilterWithCLSID';
Var Res1:HResult;
    FSourceFilterInterface:IFileSourceFilter;
Begin
  Result:=True;

  dFilterName:='';

  If Not(Self.AddFilter(sGraphBuilder,
      sFilterCLSID,
      dFilter, dFilterName)) then
  Begin
    Result:=False;
    Exit;
  End;

  FSourceFilterInterface:= Nil;

  If Failed(dFilter.QueryInterface(IID_IFileSourceFilter,
      FSourceFilterInterface)) then Result:=False
  else
  Begin
    Res1:= FSourceFilterInterface.Load(StringToOleStr(sUrlOrFileName), Nil);
    if Failed(Res1) then
    Begin
      Self.LogMessage(Nil, HResultToStr(cs_ProcName + ': фильтр '+dFilterName+
        ' не открыл путь "'+sUrlOrFileName+
           '"... SourceFilterInterface.Load возвратило: ',
         Res1));
      Result:=False;
    End;
  End;

  FSourceFilterInterface:= Nil;
End;

Function TPlayVideoGraphController.AddSourceFilter(sGraphBuilder:IGraphBuilder;
        sUrlOrFileName:String;
        Var dFilter:IBaseFilter; Var dFilterName:String):Boolean;
Const cs_ProcName='TPlayVideoGraphController.AddSourceFilter';
Var Res1:HResult;
    //FSourceFilterInterface:IFileSourceFilter;
    cErrorMsg, cErrorMsg2, cFilterGUIDStr:String;
    cFilterGUID:TGUID;
Begin
  if Not(Assigned(sGraphBuilder)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName + cs_FGraphBuilderAbsent);
    Result:=False;
    Exit;
  End;

  dFilter:= Nil;
  dFilterName:= '';
  Result:=True;


  Res1:= sGraphBuilder.AddSourceFilter(PChar(sUrlOrFileName), Nil, dFilter);
  if Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(cs_ProcName +
      ': не удалось найти фильтр для источника "'+sUrlOrFileName+
      '"... : ', Res1));
    Result:=False;
  End
  Else
  Begin
    if Not(GetPinAndOrFilterName(dFilter, dFilterName, cErrorMsg)) then
    Begin
      cErrorMsg2:= cs_ProcName + ': не удалось определить имя фильтра';

      if Failed(dFilter.GetClassID(cFilterGUID)) then
        cFilterGUIDStr:= ''
      else
      Begin
        cFilterGUIDStr:= ComObj.GUIDToString(cFilterGUID);
        cErrorMsg2:= cErrorMsg2 + ' ' +cFilterGUIDStr;
      End;

      cErrorMsg2:= cErrorMsg2 + ', который найден для чтения "' +sUrlOrFileName+
        '": '+cErrorMsg;
      Self.LogMessage(Nil, cErrorMsg2);
    End;
  End;
End;

Function TPlayVideoGraphController.TryRenderToFilters(
           sCaptureGraphBuilder:ICaptureGraphBuilder2;
           sSourceFilterOrPin: IUnknown;
           sSourceName:String = '';
           Const sSourcePinCategory: PGUID = Nil;
           Const sMediaType: PGUID = Nil;
           sMidFilter:IBaseFilter = Nil;
           sDestFilter:IBaseFilter = Nil):HResult;
Const cs_ProcName = 'TPlayVideoGraphController.TryRenderToFilters';
Var Res1:HResult; cErrorMsg, cItIsFilterStr, cDestFilterExplanation:String;
    cSourceAsFilter:IBaseFilter;
    cItIsFilter:Boolean;
Begin
  cSourceAsFilter:= Nil;

  if Not(Assigned(sCaptureGraphBuilder)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName+ cs_CaptureGraphBuilderNotSet);
    Result:=S_FALSE;
    Exit;
  End;

  if Not(Assigned(sSourceFilterOrPin)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName+': не задано джерело (sSourceFilterOrPin)...');
    Result:=S_FALSE;
    Exit;
  End;

  if sSourceName = '' then
    GetPinAndOrFilterName(sSourceFilterOrPin, sSourceName, cErrorMsg);

  cDestFilterExplanation:=Self.GetMidAndDestFilterExplanation(sMidFilter,
    sDestFilter);

  cItIsFilter:= Succeeded(sSourceFilterOrPin.QueryInterface(IID_IBaseFilter,
         cSourceAsFilter));
  if cItIsFilter then
     cItIsFilterStr:= 'от фильтра '
  else cItIsFilterStr:= 'от пина ';

  Res1:= sCaptureGraphBuilder.RenderStream(sSourcePinCategory,
            sMediaType, //@MediaType_Video,
            sSourceFilterOrPin,  // від фільтра-читача джерела медіа
            sMidFilter,        // через конкретний фільтр-перетворювач, якщо він заданий
            sDestFilter     // на заданий приймач потока
             );
  if Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(
       cs_ProcName+': ' + cItIsFilterStr + sSourceName+
           ' не удалось получить поток'+cDestFilterExplanation+
           '... FCaptureGraphBuilder.RenderStream возвратило: '
           , Res1));
         //cAutoGraph:= True;

    if Not(cItIsFilter) then
      Result:= Res1
    Else   //   Якщо джерелом є фільтр (а не окремий пін), то пробуємо побудувати
           // граф від його вільних вихідних пінів (окремо від кожного):
    Begin
      Res1:= Self.TryRenderFromEveryPinToFilters(sCaptureGraphBuilder,
           cSourceAsFilter,
           sSourceName,
           sSourcePinCategory,
           sMediaType,
           sMidFilter,
           sDestFilter);

      Result:= Res1;
    End;
  End
  Else
  Begin
    Self.LogMessage(Nil, cs_ProcName+
         ': граф построен '+cItIsFilterStr+
               sSourceName + cDestFilterExplanation+'...');
    Result:= Res1;
  End;
  cSourceAsFilter:=Nil;
  //else Inc(RenderedStreamCount);
End;

Function TPlayVideoGraphController.TryRenderFromEveryPinToFilters(
           sCaptureGraphBuilder:ICaptureGraphBuilder2;
           sSourceFilter: IBaseFilter;
           sSourceName:String = '';
           Const sSourcePinCategory: PGUID = Nil;
           Const sMediaType: PGUID = Nil;
           sMidFilter:IBaseFilter = Nil;
           sDestFilter:IBaseFilter = Nil):HResult;
Const cs_ProcName = 'TPlayVideoGraphController.TryRenderFromEveryPinToFilters';
Var pEnumPins:IEnumPins;
    Res1, RenderRes:HResult;
    pCurPin, pConnectedPin:IPin;
    cErrorMsg, cDestFilterExplanation, cCurPinName:String; //cMidName, cDestName,

    cPinDirection: TPinDirection;
    cFilterName, cFilterNameInGraph, cVendorInfo: WideString;
      //   Список для запису фільтрів, які вже під'єднані до вихідних
      //  пінів фільтра sSourceFilter. Якщо sSourceFilter не має вільних пінів,
      //  або жоден не підходить - пошук піна йде у під'єднаних до нього
      //  фільтрах:
    cConnectedFiltersList: IInterfaceList;
    cConnectedPinInfo:TPinInfo;
    cConFilterNum: Integer;
Begin
  if Not(Assigned(sCaptureGraphBuilder)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName+cs_CaptureGraphBuilderNotSet);
    Result:=S_FALSE;
    Exit;
  End;

  if Not(Assigned(sSourceFilter)) then
  Begin
    Self.LogMessage(Nil, cs_ProcName+': не задано джерело (sSourceFilter)...');
    Result:=S_FALSE;
    Exit;
  End;

  if sSourceName = '' then
    GetPinAndOrFilterName(sSourceFilter, sSourceName, cErrorMsg);

  cDestFilterExplanation:=Self.GetMidAndDestFilterExplanation(sMidFilter,
    sDestFilter);

  pEnumPins:= Nil;
  Res1:= sSourceFilter.EnumPins(pEnumPins);
  If Failed(Res1) then
  Begin
    Self.LogMessage(Nil, HResultToStr(
       cs_ProcName+cs_EnumPinsReported, Res1));
    pEnumPins:= Nil;
    Result:=Res1;
    Exit;
  End;

  pCurPin:= Nil;
  pConnectedPin:= Nil;

  RenderRes:= S_False; // тут ще не було рендеринга

  cConnectedFiltersList:= TInterfaceList.Create;

  repeat
    Res1:=pEnumPins.Reset;
    if Failed(Res1) then
    Begin
      Self.LogMessage(Nil, HResultToStr(
        cs_ProcName+cs_EnumPinsFailedToStart,
          Res1));
      Break;
    End;
      //   Всі дані, що зібрані в попередніх тактах, можуть бути не дійсними
      // при VFW_E_ENUM_OUT_OF_SYNC, тому повторюємо доки вдасться їх зібрати:
    cConnectedFiltersList.Clear;

    cCurPinName:='';
    Res1:= pEnumPins.Next(1, pCurPin, Nil);
    while Res1 = S_OK do
    Begin
      cErrorMsg:= '';

      if Assigned(pCurPin) then
      Begin

        //GetPinAndOrFilterName(pCurPin, cCurPinName, cErrorMsg);

          // Перевіряємо що це вихідний пін:

        if GetPinAndFilterInfo(pCurPin, cCurPinName,
          cPinDirection,
          cFilterName, cFilterNameInGraph, cVendorInfo) then
        Begin
          if cFilterNameInGraph <> '' then
            cCurPinName:= cFilterNameInGraph + '.' + cCurPinName;
        End
        Else cPinDirection:= PINDIR_OUTPUT;  // якщо не вдалося отримати інформацію про пін, вважаємо що він вихідний всеодно...

        if cPinDirection = PINDIR_OUTPUT then
        Begin
            // Перевіряємо що пін вільний (від нього ще не побудовано нічого):
          Res1:= pCurPin.ConnectedTo(pConnectedPin);
          if Res1 = VFW_E_NOT_CONNECTED then  // пін вільний:
          Begin
                // Запускаємо побудову графа від піна:
            RenderRes:= Self.TryRenderToFilters(sCaptureGraphBuilder, pCurPin,
              cCurPinName,
              sSourcePinCategory, sMediaType, sMidFilter, sDestFilter);

            if Succeeded(RenderRes) then // якщо граф від поточного піна вдалося побудувати:
            Begin
              Res1:=S_OK;
              Break;
            End;
          End
          Else if Res1 = S_OK then            // пін вже під'єднаний:
          Begin
            if Not(Assigned(pConnectedPin)) then
            Begin
              Self.LogMessage(Nil, cs_ProcName+
                ': pCurPin.ConnectedTo не повернуло під''єднаний пін, хоч і повідомило що він під''єднаний!..');
            End
            Else
            Begin
              if UDIrectShowHelp.GetPinInfo(pConnectedPin, cConnectedPinInfo) then
              Begin
                  //   Якщо у списку під'єднаних фільтрів ще немає поточного
                  // фільтра, то додаємо:
                if cConnectedFiltersList.IndexOf(cConnectedPinInfo.pFilter) < 0 then
                  cConnectedFiltersList.Add(cConnectedPinInfo.pFilter);
              End
              Else
              Begin
                Self.LogMessage(Nil, cs_ProcName+
                  ': не вдалося прочитати інформацію з піна, що під''єднаний до "'+
                    cCurPinName+'"...');
              End;
            End;
          End
          else                                // невідома помилка:
          Begin
            Self.LogMessage(Nil, HResultToStr(
              cs_ProcName+
                ': pCurPin.ConnectedTo сообщило неожиданный результат у пина "'+
                  cCurPinName+'": ', Res1));
                   // далі пробуємо наступні піни...
          End;
        End;
      End
      Else  //pCurPin = Nil
      Begin
        Self.LogMessage(Nil, cs_ProcName+
           cs_EnumPinsNextNotReturnedExistedPin);
      End;

      //if cCurPinName='' then cCurPinName:= cErrorMsg;

      Res1:= pEnumPins.Next(1, pCurPin, Nil);
    End;

    case Res1 of
      VFW_E_ENUM_OUT_OF_SYNC:  // обхід пінів розсинхронізувався, і потребує повтору:
      Begin
        Self.LogMessage(Nil, cs_ProcName+
          cs_EnumPinsDeSynchronizedOn+
             sSourceName+cs_EnumPinsStartingNewEnum);
        Continue;
      End;
      S_False: // всі піни перевірені, жоден не підійшов:
      Begin
        cErrorMsg:= cs_ProcName+
          ': Не удалось построить граф ни от одного пина на '+
             sSourceName + cDestFilterExplanation + '...';

        Self.LogMessage(Nil, cErrorMsg);
      End;

      S_OK:   // від одного із пінів успішно побудований граф:
      Begin
         // повідомлення про це уже відображено у Self.TryRenderToFilters:
        {if Assigned(pCurPin) then
        Begin


          Self.LogMessage(Nil, cs_ProcName+
            ': граф построен от пина '+
             cCurPinName + cDestFilterExplanation + '...');
        End
        Else
          Self.LogMessage(Nil, cs_ProcName+
            ': не обнаружен пин, от которого построен граф!..');}
      End
      Else     // невідомий результат:
      Begin
        Self.LogMessage(Nil, HResultToStr(
          cs_ProcName+cs_EnumPinsNextReportedUnusual,
            Res1));
        Break;
      End;
    end;
  until (Res1 = S_OK) or (Res1 = S_False);

  pCurPin:= Nil;
  pEnumPins:= Nil;

    //   Якщо граф не вдалося побудувати на пінах поточного фільтра
    // sSourceFilter, пробуємо побудувати його від тих вільтрів, що вже
    // під'єднані до вихідних пінів:
  if Not(Res1 = S_OK) then
  Begin
    try
      for cConFilterNum := 0 to cConnectedFiltersList.Count - 1 do
      Begin
        Res1:= Self.TryRenderFromEveryPinToFilters(sCaptureGraphBuilder,
             cConnectedFiltersList.Items[cConFilterNum] as IBaseFilter,
             '',
             sSourcePinCategory,
             sMediaType,
             sMidFilter,
             sDestFilter);
        if Res1 = S_OK then Break;
      End;
    except
      on E:Exception do
      Begin
        Self.LogMessage(Nil, cs_ProcName+
            ': сталося виключення при побудові дерева від фільтрів, що під''єднані до фільтра "'+
              sSourceName+'", :' + E.ToString + '...');
      End;
    end;
  End;

  cConnectedFiltersList.Clear;

  cConnectedFiltersList:= Nil;

  if Res1 = S_False then
    Result:=RenderRes  // останній результат спроби побудувати граф для потока
  Else Result:= Res1;
End;

Function TPlayVideoGraphController.GetMidAndDestFilterExplanation(
           sMidFilter:IBaseFilter = Nil;
           sDestFilter:IBaseFilter = Nil):String;
Var cDestFilterExplanation, cMidName, cDestName, cErrorMsg:String;
Begin
  cDestFilterExplanation:='';
  cMidName:='';
  cDestName:='';
  cErrorMsg:='';

  if Assigned(sMidFilter) then
  Begin
    GetPinAndOrFilterName(sMidFilter, cMidName, cErrorMsg);
    cDestFilterExplanation:= cDestFilterExplanation + ' через ' + cMidName;
  End
  Else cMidName:= '';
  if Assigned(sDestFilter) then
  Begin
    GetPinAndOrFilterName(sDestFilter, cDestName, cErrorMsg);
    cDestFilterExplanation:= cDestFilterExplanation + ' до ' + cDestName;
  End
  Else cDestName:= '';
  Result:= cDestFilterExplanation;
End;

    // Виділяє пам'ять і копіює дані про заголовок і буфер кадра:
Function AllocateBMPData(sHeader: PBitmapInfoHeader;
          pBuffer:PByte; sBufferSize: Longint;
          sSampleTime:Double):PBMPSampleRec;
Begin
  //Result:= Nil;  // value assigned, never used
  New(Result);
  Result.cSampleTime:= sSampleTime;
  Result.cBufferSize:= sBufferSize;

  Result.cBmpHead:= sHeader^;

  System.GetMem(Result.pBuffer, sBufferSize);
  System.Move(pBuffer^, Result.pBuffer^, sBufferSize);
End;
    // Викликається для елементів що точно не у списку.
Procedure FreeBMPData(Var sdData:PBMPSampleRec);
Begin
  if Assigned(sdData) then
  Begin
    System.FreeMem(sdData.pBuffer);
    Dispose(sdData);
    sdData:= Nil;
  End;
End;



end.