unit Unit1;


interface

uses
  SysUtils, SysConst, Windows, Messages, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, activex, directshow9, Grids, ValEdit,
  SyncObjs,
  ComObj, IniFiles,
  DShowUtil, DataHelper, UDirectShowHelp, Buttons,
  Jpeg;

Const
  cs_Mode = 'Mode';
  cs_Capturing = 'Capturing';
  cs_RowCount = 'RowCount';
  cs_Channel = 'Channel';
  cs_Count = 'Count';
  cs_Name = 'Name';
  cs_Url = 'Url';
  cs_CheckBoxVideoOn = 'CheckBoxVideoOn';
  cs_CheckBoxAudioOn = 'CheckBoxAudioOn';
  cs_CheckBoxPhotoOn = 'CheckBoxPhotoOn';
  cs_CaptureSampleCount = 'CaptureSampleCount';
  cs_CaptureJpegQuality = 'CaptureJpegQuality';

  c_DefJpegQuality = 80;

type
  TForm1 = class;

  TPlayVideoPanel = class (ExtCtrls.TPanel)
  protected
    procedure Paint; override;
  public
    FPlayerForm:TForm1;

    //property DockManager;

    procedure Assign(Source: TPersistent); override;
  published

  end;

  TForm1 = class(TForm)  //, ISampleGrabberCB
    Panel1: TPanel;
    PanelButtons: TPanel;
    ButtonHideList: TButton;
    Button1: TButton;
    Button2: TButton;
    ButtonHideEventLog: TButton;
    PanelEvents: TPanel;
    MemoEvents: TMemo;
    ButtonClearLog: TButton;
    PanelChannels: TPanel;
    ValueListEditor1: TValueListEditor;
    SplitterChannels: TSplitter;
    SplitterEvents: TSplitter;
    ButtonSaveGraph: TButton;
    SaveDialogForGraph: TSaveDialog;
    PanelControl: TPanel;
    ButtonPlayChannel: TSpeedButton;
    ButtonPause: TSpeedButton;
    ButtonStop: TSpeedButton;
    LabelState: TLabel;
    CheckBoxVideoOn: TCheckBox;
    CheckBoxAudioOn: TCheckBox;
    CheckBoxPhotoOn: TCheckBox;
    PanelControl2: TPanel;
    ButtonGetImage: TButton;
    EditSampleCount: TEdit;
    LabelSampleCount: TLabel;
    LabelJpegQuality: TLabel;
    EditJpegQuality: TEdit;

    //Function CreateGraph(Const Url, Name_ch:String;
    //  sStartPaused:Boolean = False):Boolean;

    procedure Play(Const Url:String = ''; Const Name_ch:String = '';
      cForceRebuildGraph:Boolean = False);
    procedure Pause(Const Url: String = ''; Const Name_ch:String = '');
    procedure Stop;

    Procedure UpdateProcRunningButtonsState(sCurState:TFilterState;
            sSTATE_INTERMEDIATE, sCANT_CUE: Boolean);


    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);

    procedure ValueListEditor1DblClick(Sender: TObject);

    procedure LoadIniFiles;
    procedure SaveIniFiles;
    procedure Panel1Resize(Sender: TObject);
    procedure ButtonHideListClick(Sender: TObject);
    procedure ButtonHideEventLogClick(Sender: TObject);

    //Function DSEventHandler(slParam:LParam):Boolean;

    Procedure LogMessage(Const sMessage:String);

    procedure FormDestroy(Sender: TObject);
    procedure ButtonClearLogClick(Sender: TObject);
    procedure ButtonPlayChannelClick(Sender: TObject);
    procedure ButtonSaveGraphClick(Sender: TObject);
    procedure ButtonPauseClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);

      //   Перехоплювачі подій, про які потрібно повідомляти
      // відеорендереру, коли він працює без свого вікна і малює прямо на вікні
      // програми:
    Procedure ProcOnDisplayChange(Var sMessage:TWMDISPLAYCHANGE); Message WM_DISPLAYCHANGE;
    procedure ButtonGetImageClick(Sender: TObject);
    //WM_PAINT оброблюємо у власному класі-нащадку від TCustomPanel (не малюємо, інформуємо відеорендерера)
    //WM_SIZE беремо із OnResize, розраховуємо потрібний розмір картинки і повідомляємо рендереру

    //procedure DSFilterGraphDSEvent(sender: TComponent; Event, Param1,
    // Param2: Integer);
  private
      //   Секція обробки подій DirectShow при надходженні викликів від
      // потока читання подій і потока налаштування графа:
    cDShowEventSection:TCriticalSection;

    cLogFile:TLogFile;
    cGraphController: TCaptureJpegToFileGraphController;

    cNewVideoX, cNewVideoY: Integer;

    cGraphLogMessage: String;

    cPanelForVideo: TPanel;

    //cSampleCompressionQuality: TJpegQualityRange;

    procedure DoSynchronize(AThread: TThread; AMethod: TThreadMethod);

    //cInitRes:HResult;

    //cGraphBuildRunning:Boolean;
    //cCurURL:String;

    //  //каналы
    //Url, Name_ch:string;

    procedure ToggleHideControl(sControl: TControl;
      sToggledButton: TButton = Nil;
      Const sButtonCaptionWhenHidden:String = '';
      Const sButtonCaptionWhenShown:String = '');

    Procedure SaveMemoLog(Const sFileName:String);

    //   // Реалізація інтерфейса ISampleGrabberCB:
    //function  SampleCB(SampleTime: Double; pSample: IMediaSample): HResult; stdcall;
    //function  BufferCB(SampleTime: Double; pBuffer: PByte; BufferLen: longint): HResult; stdcall;
       // Обробник подій графа типу ТProcDShowEvent,
       // викликається із UDirectShowHelp.ProcDShowEvent:
    Procedure DShowEventParamHandler(sCaller: TThread;
      sEvCode:Longint; slParam1, slParam2:Longint;
      sEventName, sEventData:String);
    Procedure DSGraphOnStateChange(sCaller: TThread;
      Const sState, sLastState:TFilterState;
      sSTATE_INTERMEDIATE, sCANT_CUE:Boolean;
      sStateRes, sLastStateRes:HResult;
      sCurURL, sLastURL, sCurName_ch:String);
    Procedure DSGraphOnLogMessage(sCaller: TThread;
        Const sMessage:String;
        sThisIsCriticalError:Boolean = False);

    Procedure ProcOnVideoSizeChanged;
    Procedure ProcUpdateProcRunningButtonsState;
    Procedure ProcOnLogGraphMessage;


    Function GetSampleCountToCapture:Cardinal;
    Function GetJpegQualityToSet:TJpegQualityRange;

  protected
    cCurState: TFilterState;
    cSTATE_INTERMEDIATE, cCANT_CUE:Boolean;

//    cEvCode:Longint; lParam1, lParam2:Longint);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  //файл конфигурации
  IniFile: TIniFile;

  cMainWindowsHookHandle: Windows.HHOOK;
  cMessageIDForDSEvents: UInt;

  cExceptNumber:Cardinal;

implementation

{$R *.dfm}

procedure TPlayVideoPanel.Paint;
Var cPainted:Boolean;
Begin
  cPainted:= False;
  if Assigned(Self.FPlayerForm) then
  Begin
    if Assigned(Self.FPlayerForm.cGraphController) then
    Begin
      if Self.FPlayerForm.cGraphController.RenderVideo then
      Begin
          // Перемалювати вікно треба буде при старті відео, навіть якщо зараз
          // відтворення ще не відбувається. Тому посилаємо контролеру графа
          // запит на перемалювання. Він пошле його рендереру коли той буде
          // створений після запуску графа:
        Self.FPlayerForm.cGraphController.RePaint(Self.Handle, Self.Canvas.Handle);
          // Поки граф не показує відео - перемальовуємо панель:
        //if (Not(Self.FPlayerForm.cCurState = State_Stopped))
        //        or (Self.FPlayerForm.cSTATE_INTERMEDIATE) then
        if Self.FPlayerForm.cGraphController.VideoBeingRendered then
        Begin
          cPainted:= True;
        End;
      End;
    End;
  End;

  if Not(cPainted) then Inherited Paint;
End;

procedure TPlayVideoPanel.Assign(Source: TPersistent);
Var ccSource:TPanel;
Begin
  if Source is TPanel then
  Begin
    ccSource:= TPanel(Source);
    Self.Parent:= ccSource.Parent;
    Self.Align:= ccSource.Align;
    Self.Alignment:= ccSource.Alignment;
    Self.AlignWithMargins:= ccSource.AlignWithMargins;
    Self.Anchors:= ccSource.Anchors;
    Self.AutoSize:= ccSource.AutoSize;
    Self.BevelEdges:= ccSource.BevelEdges;
    Self.BevelInner:= ccSource.BevelInner;
    Self.BevelKind:= ccSource.BevelKind;
    Self.BevelOuter:= ccSource.BevelOuter;
    Self.BevelWidth:= ccSource.BevelWidth;
    Self.BiDiMode:= ccSource.BiDiMode;
    Self.BorderStyle:= ccSource.BorderStyle;
    Self.BorderWidth:= ccSource.BorderWidth;
    Self.Caption:= ccSource.Caption;
    Self.Color:= ccSource.Color;
    Self.Constraints:= ccSource.Constraints;
    Self.Ctl3D:= ccSource.Ctl3D;
    Self.Cursor:= ccSource.Cursor;
    Self.DockSite:= ccSource.DockSite;
    Self.DoubleBuffered:= ccSource.DoubleBuffered;
    Self.DragCursor:= ccSource.DragCursor;
    Self.DragKind:= ccSource.DragKind;

    Self.CustomHint:= ccSource.CustomHint;

    Self.DragMode:= ccSource.DragMode;
    Self.Enabled:= ccSource.Enabled;
    Self.Font:= ccSource.Font;
    Self.FullRepaint:= ccSource.FullRepaint;
    Self.Height:= ccSource.Height;
    Self.HelpContext:= ccSource.HelpContext;
    Self.HelpKeyword:= ccSource.HelpKeyword;
    Self.HelpType:= ccSource.HelpType;
    Self.Hint:= ccSource.Hint;
    Self.Left:= ccSource.Left;
    Self.Locked:= ccSource.Locked;
    Self.Margins:= ccSource.Margins;

    Self.Padding:= ccSource.Padding;
    Self.ParentBackground:= ccSource.ParentBackground;
    Self.ParentBiDiMode:= ccSource.ParentBiDiMode;
    Self.ParentColor:= ccSource.ParentColor;
    Self.ParentCtl3D:= ccSource.ParentCtl3D;
    Self.ParentCustomHint:= ccSource.ParentCustomHint;
    Self.ParentDoubleBuffered:= ccSource.ParentDoubleBuffered;
    Self.ParentFont:= ccSource.ParentFont;
    Self.ParentShowHint:= ccSource.ParentShowHint;

    Self.PopupMenu:= ccSource.PopupMenu;

    Self.ShowCaption:= ccSource.ShowCaption;
    Self.ShowHint:= ccSource.ShowHint;
    Self.TabOrder:= ccSource.TabOrder;
    Self.TabStop:= ccSource.TabStop;
    Self.Tag:= ccSource.Tag;
    Self.Top:= ccSource.Top;
    Self.UseDockManager:= ccSource.UseDockManager;
    Self.VerticalAlignment:= ccSource.VerticalAlignment;
    Self.Visible:= ccSource.Visible;
    Self.Width:= ccSource.Width;

    Self.OnAlignInsertBefore:= ccSource.OnAlignInsertBefore;
    Self.OnAlignPosition:= ccSource.OnAlignPosition;
    Self.OnCanResize:= ccSource.OnCanResize;
    Self.OnClick:= ccSource.OnClick;
    Self.OnConstrainedResize:= ccSource.OnConstrainedResize;
    Self.OnContextPopup:= ccSource.OnContextPopup;
    Self.OnDblClick:= ccSource.OnDblClick;
    Self.OnDockDrop:= ccSource.OnDockDrop;
    Self.OnDockOver:= ccSource.OnDockOver;
    Self.OnDragDrop:= ccSource.OnDragDrop;
    Self.OnDragOver:= ccSource.OnDragOver;
    Self.OnEndDock:= ccSource.OnEndDock;
    Self.OnEndDrag:= ccSource.OnEndDrag;
    Self.OnEnter:= ccSource.OnEnter;
    Self.OnExit:= ccSource.OnExit;
    Self.OnGetSiteInfo:= ccSource.OnGetSiteInfo;
    Self.OnMouseActivate:= ccSource.OnMouseActivate;
    Self.OnMouseDown:= ccSource.OnMouseDown;
    Self.OnMouseEnter:= ccSource.OnMouseEnter;
    Self.OnMouseLeave:= ccSource.OnMouseLeave;
    Self.OnMouseMove:= ccSource.OnMouseMove;
    Self.OnMouseUp:= ccSource.OnMouseUp;
    Self.OnResize:= ccSource.OnResize;
    Self.OnStartDock:= ccSource.OnStartDock;
    Self.OnStartDrag:= ccSource.OnStartDrag;
    Self.OnUnDock:= ccSource.OnUnDock;
  End
  else Inherited Assign(Source);
End;





Procedure TForm1.SaveMemoLog(Const sFileName:String);
Begin
  Self.MemoEvents.Lines.SaveToFile(sFileName + '.txt');
End;

Procedure TForm1.UpdateProcRunningButtonsState(sCurState:TFilterState;
            sSTATE_INTERMEDIATE, sCANT_CUE: Boolean);
Var ccCurState:TFilterState;
    cSTATE_INTERMEDIATE, cCANT_CUE: Boolean;
    cDownButton:TSpeedButton;
    ccControlsOn:Boolean;
Begin
  //ccCurState:=Self.GetRunningState(cSTATE_INTERMEDIATE, cCANT_CUE, 0);
  ccCurState:= sCurState;
  cSTATE_INTERMEDIATE:= sSTATE_INTERMEDIATE;
  cCANT_CUE:= sCANT_CUE;
  cDownButton:= Nil;
  ccControlsOn:= False;

  case ccCurState of
    State_Stopped:
      Begin
        Self.ButtonPlayChannel.Enabled:=True;
        Self.ButtonPause.Enabled:=True;
        Self.ButtonStop.Enabled:=False;

        ccControlsOn:= Not(sSTATE_INTERMEDIATE);

        cDownButton:= Self.ButtonStop;
      End;
    State_Paused:
      Begin
        Self.ButtonPlayChannel.Enabled:=True;
        Self.ButtonPause.Enabled:=False;
        Self.ButtonStop.Enabled:=True;

        cDownButton:= Self.ButtonPause;
      End;
    State_Running:
      Begin
        Self.ButtonPlayChannel.Enabled:=True;
        //Self.ButtonPlayChannel.PressedImageIndex
        Self.ButtonPause.Enabled:=True;
        Self.ButtonStop.Enabled:=True;

        cDownButton:= Self.ButtonPlayChannel;
      End;
  end;

  Self.CheckBoxVideoOn.Enabled:= ccControlsOn;
  Self.CheckBoxAudioOn.Enabled:= ccControlsOn;
  Self.CheckBoxPhotoOn.Enabled:= ccControlsOn;

  Self.ButtonPlayChannel.Down:= Self.ButtonPlayChannel = cDownButton;
  Self.ButtonPause.Down:= Self.ButtonPause = cDownButton;
  Self.ButtonStop.Down:= Self.ButtonStop = cDownButton;

  Self.ButtonGetImage.Enabled:= Self.CheckBoxPhotoOn.Checked
    And (ccCurState <> State_Stopped);

  if cSTATE_INTERMEDIATE then
    Self.LabelState.Caption:='...'
  Else if cCANT_CUE then
    Self.LabelState.Caption:='X'
  Else Self.LabelState.Caption:='';
End;

procedure TForm1.Stop;
//Const cs_ProcName = 'Stop';
//Var Res1:HResult; ccCurState:TFilterState;// cNeedRebuildGraph:Boolean;
//    cSTATE_INTERMEDIATE, cCANT_CUE: Boolean;
Begin
  Self.cGraphController.Stop;
End;

procedure TForm1.Pause(Const Url: String = ''; Const Name_ch:String = '');
//Const cs_ProcName = 'Pause';
//Var Res1:HResult; ccCurState:TFilterState; cNeedRebuildGraph:Boolean;
//    cSTATE_INTERMEDIATE, cCANT_CUE:Boolean;
Begin

  Self.cGraphController.RenderVideo:= Self.CheckBoxVideoOn.Checked;
  Self.cGraphController.RenderAudio:= Self.CheckBoxAudioOn.Checked;
  Self.cGraphController.RenderSamples:= Self.CheckBoxPhotoOn.Checked;

  Self.cGraphController.CompressionQuality:= Self.GetJpegQualityToSet;

  Self.cGraphController.Pause(Url, Name_ch, False);
End;

procedure TForm1.Play(Const Url:String = ''; Const Name_ch:String = '';
  cForceRebuildGraph:Boolean = False);
//Const cs_ProcName = 'Play';
//Var Res1:HResult; ccCurState:TFilterState; cNeedRebuildGraph:Boolean;
//    cSTATE_INTERMEDIATE, cCANT_CUE:Boolean;
Begin
  //Res1:= S_OK;

  Self.cGraphController.RenderVideo:= Self.CheckBoxVideoOn.Checked;
  Self.cGraphController.RenderAudio:= Self.CheckBoxAudioOn.Checked;
  Self.cGraphController.RenderSamples:= Self.CheckBoxPhotoOn.Checked;

  Self.cGraphController.CompressionQuality:= Self.GetJpegQualityToSet;

  Self.cGraphController.Play(Url, Name_ch, cForceRebuildGraph);
End;

//Добавление записи в ValueListEditor1
procedure TForm1.Button1Click(Sender: TObject);
var Url1, Name1: string;
begin
 Url1:= inputbox('Введите адрес канала?','Например: mms://live.rfn.ru/vesti_24','');
 if Url1<>'' then begin
      Name1:=InputBox('Введите имя канала?', 'Например: Россия 24','');
      if Name1<>'' then  ValueListEditor1.InsertRow(Name1,Url1,true);
 end;
end;

//Удаление записи из ValueListEditor1
procedure TForm1.Button2Click(Sender: TObject);
begin
  if ValueListEditor1.RowCount<=2 then exit;
    ValueListEditor1.deleterow(ValueListEditor1.Row);
end;

procedure TForm1.ButtonClearLogClick(Sender: TObject);
begin
  Self.MemoEvents.Lines.Clear;
end;

procedure TForm1.ButtonGetImageClick(Sender: TObject);
Var ccSamplesToCapture:Cardinal;
begin
  ccSamplesToCapture:= Self.GetSampleCountToCapture;

  Self.cGraphController.CompressionQuality:= Self.GetJpegQualityToSet;

  Self.cGraphController.CaptureSamples(ccSamplesToCapture);
end;

procedure TForm1.ToggleHideControl(sControl: TControl;
      sToggledButton: TButton = Nil;
      Const sButtonCaptionWhenHidden:String = '';
      Const sButtonCaptionWhenShown:String = '');
Begin
  if sControl.Tag = 0 then
  Begin
    sControl.Hide;

    sControl.Tag:=1;
    //sControl.Tag:= sControl.Height;
    //sControl.Height:= 0;

    if sToggledButton<>Nil then
      sToggledButton.Caption:= sButtonCaptionWhenHidden;
  End
  Else
  Begin
    //sControl.Height:= sControl.Tag;
    sControl.Tag:= 0;

    sControl.Show;

    if sToggledButton<>Nil then
      sToggledButton.Caption:= sButtonCaptionWhenShown;
  End;
End;

procedure TForm1.ButtonHideEventLogClick(Sender: TObject);
begin
  Self.ToggleHideControl(Self.PanelEvents, Self.ButtonHideEventLog,
      'Показати журнал', 'Заховати журнал');
  Self.ToggleHideControl(Self.SplitterEvents);
end;

procedure TForm1.ButtonHideListClick(Sender: TObject);
begin
  Self.ToggleHideControl(Self.PanelChannels, Self.ButtonHideList,
      'Показати список', 'Заховати список');
  Self.ToggleHideControl(Self.SplitterChannels);

  Self.ToggleHideControl(Self.Button1);
  Self.ToggleHideControl(Self.Button2);
end;

procedure TForm1.ButtonPauseClick(Sender: TObject);
begin
  Self.Pause(ValueListEditor1.Cells[1,ValueListEditor1.Row],
     ValueListEditor1.Cells[0,ValueListEditor1.Row]);
end;

procedure TForm1.ButtonPlayChannelClick(Sender: TObject);
begin
  Self.ValueListEditor1DblClick(Sender);
end;

procedure TForm1.ButtonSaveGraphClick(Sender: TObject);
Const cs_ProcName = 'ButtonSaveGraphClick';
begin
  if Assigned(Self.cGraphController) then
  Begin
    if Self.SaveDialogForGraph.Execute(Self.Handle) then
    Begin
      Self.cGraphController.SaveGraphToFile(Self.SaveDialogForGraph.FileName);
      //Self.SaveGraphToFile(FGraphBuilder, Self.SaveDialogForGraph.FileName);
      Self.SaveMemoLog(Self.SaveDialogForGraph.FileName);
    End;
  End
  Else
  Begin
    Self.LogMessage(cs_ProcName + ': обробник графа не виявлений...');
  End;
end;

procedure TForm1.ButtonStopClick(Sender: TObject);
begin
  Self.Stop;
end;

////Деинициализация COM
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //   //  FGraphBuilder.RenderFile, хоч і зупиняє хід потоку доки не поверне значення,
  //   // та потік програми всеодно продовжує відповідати на повідомлення Windows!..
  //   // Можливо, RenderFile в себе десь у потоці слідкує за надходженням нових повідомлень,
  //   // і одразу викликає їх обробку, для зручності. Тому якщо це закривання форми -
  //   // не робимо нічого в рекурсії:
  //if Self.cGraphBuildRunning then Exit;
end;

//Инициализация COM
procedure TForm1.FormCreate(Sender: TObject);
const cs_ProcName = 'TForm1.FormCreate';
//var cMessage:String;
begin

  System.ReportMemoryLeaksOnShutdown:= True;
//  RegisterExpectedMemoryLeak

    //FGraphBuilder:= Nil;
    //fMediaEventEx:= Nil;
    //  // Розширений будувач графа, що має функції зв'язування фільтрів та
    //  //  автовиводу від фільтрів за типом медіапотоку, без вказування пунктів
    //  //  входу-виходу.. Для поділу потоків із кількома відео чи аудіодоріжками
    //  //  всеодно треба зв'язувати на рівні пунктів входу-виходу потоків...
    //  // Але тут використовується це...:
    //FCaptureGraphBuilder: ICaptureGraphBuilder2 = Nil;
    //FMediaControl:= Nil;
    //FVideoWindow:= Nil;

  //Self.cGraphBuildingSection:= TCriticalSection.Create;

  Self.cLogFile:=TLogFile.Create(True, True, 3);
  Self.cLogFile.Open(Application.ExeName + '.log');

  Self.MemoEvents.Lines.Clear;
    // Заміняємо налаштовану в конфігураторі панель на нову, в якій
    // перемалювання перероблене (вона сповізає про нього об'єкту-контролеру
    // графа відображення відео):
  Self.cPanelForVideo:= TPlayVideoPanel.Create(Application);
  TPlayVideoPanel(Self.cPanelForVideo).Assign(Self.Panel1);
  TPlayVideoPanel(Self.cPanelForVideo).FPlayerForm:= Self;

  Self.cPanelForVideo.Caption:= 'Це панель для відео...';

  Self.Panel1.Visible:= False;

  Self.cPanelForVideo.Visible:= True;

  //Self.cPanelForVideo:= Self.Panel1;

  {Self.cInitRes:= CoInitializeEx(Nil, COINIT_APARTMENTTHREADED);

  if Failed(Self.cInitRes) then
  Begin
    cMessage:= HResultToStr(cs_ProcName + cs_CoInitializeExFailed, cInitRes);
    Self.cLogFile.WriteMessage(cMessage);  // у файл
    Self.LogMessage(cMessage);             // на форму, на екран
  End;}
  //CoInitialize(nil);

  //Self.InitDSMessageHandler;

  Self.cDShowEventSection:= TCriticalSection.Create;

  //Загрузка настроек каналов
  LoadIniFiles;
     // Ініціювання потока управління графом:

  Self.cGraphController:= TCaptureJpegToFileGraphController.Create(Self.cLogFile,
    False, ExtractFilePath(Application.ExeName)+'Jpeg\'+DateToStr(Now)+'_.jpg');

  Self.cGraphController.OnGraphEvent:= Self.DShowEventParamHandler;
  Self.cGraphController.OnLogMessage:= Self.DSGraphOnLogMessage;
  Self.cGraphController.OnStateChange:= Self.DSGraphOnStateChange;

  Self.cGraphController.CompressionQuality:= Self.GetJpegQualityToSet; //c_DefJpegQuality;

  Self.cGraphController.SetupVideoWindow(Self.cPanelForVideo.Handle,
    0, 0, cPanelForVideo.ClientRect.Right, cPanelForVideo.ClientRect.Bottom
    //, WS_CHILD or WS_CLIPSIBLINGS
    );
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  //if Self.cGraphBuildRunning then Exit;
  //Self.StopDSMessageHandler;
  //FreeAndNil(Self.cGraphBuildingSection);

  SysUtils.FreeAndNil(Self.cGraphController);
  SysUtils.FreeAndNil(Self.cDShowEventSection);

  //CoUninitialize;

  //сохранение настроек каналов
  SaveIniFiles;
  IniFile.Free;

  //SysUtils.FreeAndNil(Self.cPanelForVideo);

  {if Not(Failed(Self.cInitRes)) then
  Begin
    CoUninitialize;
  End;}

  SysUtils.FreeAndNil(Self.cLogFile);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  form1.Caption:='Програвач мережевих потоків і файлів';
  {if ValueListEditor1.RowCount<>0 then
      Begin
        url:=ValueListEditor1.Cells[1,1];
        Name_ch:=ValueListEditor1.Cells[0,1];
        form1.Caption:=Name_ch;
      End;}
end;

//Выбор канала из ValueListEditor1
procedure TForm1.ValueListEditor1DblClick(Sender: TObject);
//Var cMessage:String;
begin

   //url:=ValueListEditor1.Cells[1,ValueListEditor1.Row];
   //Name_ch:=ValueListEditor1.Cells[0,ValueListEditor1.Row];
   //form1.Caption:=Name_ch;
   //вызов процедуры построения графа
   Self.Play(ValueListEditor1.Cells[1,ValueListEditor1.Row],
     ValueListEditor1.Cells[0,ValueListEditor1.Row]);
   //CreateGraph();
end;

procedure TForm1.LoadIniFiles;
var i,  ccCount: integer;
    Url1, Name1: string;
begin

    //создание inifile  с именем Config.ini
  IniFile:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'config.ini');
    //загрузка настроек из inifile
    //параметры каналов

  ccCount:= IniFile.ReadInteger(cs_RowCount,cs_Count,0);

  for i:= 1 to ccCount - 1 do
  begin
    Name1:=IniFile.ReadString(cs_Channel,cs_Name+inttostr(i),'');
    Url1:=IniFile.ReadString(cs_Channel,cs_Url+inttostr(i),'');
    ValueListEditor1.InsertRow(Name1,Url1,true);
  end;

  Self.CheckBoxVideoOn.Checked:=
    IniFile.ReadBool(cs_Mode, cs_CheckBoxVideoOn, True);

  Self.CheckBoxAudioOn.Checked:=
    IniFile.ReadBool(cs_Mode, cs_CheckBoxAudioOn, True);

  Self.CheckBoxPhotoOn.Checked:=
    IniFile.ReadBool(cs_Mode, cs_CheckBoxPhotoOn, False);

  Self.EditSampleCount.Text:= IntToStr(
    IniFile.ReadInteger(cs_Capturing, cs_CaptureSampleCount, 1));

  Self.EditJpegQuality.Text:= IntToStr(
    IniFile.ReadInteger(cs_Capturing, cs_CaptureJpegQuality, c_DefJpegQuality));
end;


//Процедура изменения размеов окна проигрывания при изменении размеров панели
procedure TForm1.Panel1Resize(Sender: TObject);
begin
  Self.cGraphController.SetupVideoWindow(Self.cPanelForVideo.Handle,
    0, 0, cPanelForVideo.ClientRect.Right,cPanelForVideo.ClientRect.Bottom
    //, WS_CHILD or WS_CLIPSIBLINGS
    );

  //if Assigned(FVideoWindow)  then
  //FVideoWindow.SetWindowPosition(0,0,cPanelForVideo.ClientRect.Right,cPanelForVideo.ClientRect.Bottom);
end;

procedure TForm1.SaveIniFiles;
var i: integer;
begin
    //сохраняем настройки в inifile
    //Параметры каналов
  IniFile.WriteInteger(cs_RowCount,cs_Count,ValueListEditor1.RowCount);
    //очистка секции PlayList
  IniFile.EraseSection(cs_Channel);
  for i:=1 to ValueListEditor1.RowCount - 1 do
  begin
    IniFile.WriteString(cs_Channel,cs_Name+inttostr(i),ValueListEditor1.Cells[0,i]);
    IniFile.WriteString(cs_Channel,cs_Url+inttostr(i),ValueListEditor1.Cells[1,i]);
  end;

  IniFile.WriteBool(cs_Mode, cs_CheckBoxVideoOn,
    Self.CheckBoxVideoOn.Checked);

  IniFile.WriteBool(cs_Mode, cs_CheckBoxAudioOn,
    Self.CheckBoxAudioOn.Checked);

  IniFile.WriteBool(cs_Mode, cs_CheckBoxPhotoOn,
    Self.CheckBoxPhotoOn.Checked);

  IniFile.WriteInteger(cs_Capturing, cs_CaptureSampleCount,
    Self.GetSampleCountToCapture);

  IniFile.WriteInteger(cs_Capturing, cs_CaptureJpegQuality,
    Self.GetJpegQualityToSet);
end;

Procedure TForm1.LogMessage(Const sMessage:String);
Begin
  Self.MemoEvents.Lines.Add(DateTimeToStr(Now) + ' ' + sMessage);
End;

// Синхронізує поточний потік із головним потоком і запускає
// AMethod у головному потоці процеса.
procedure TForm1.DoSynchronize(AThread: TThread; AMethod: TThreadMethod);
const cs_ProcName='TForm1.DoSynchronize';
Var ccThreadId:DWord; cMessage:String;
Begin
    // Краще автосинхронізація без вказування об'єкта-потока, ніж
    // із неправильним потоком...:
  if Assigned(AThread) then
  Begin
    ccThreadId:= Windows.GetCurrentThreadID;
    if AThread.ThreadID <> ccThreadId then
    Begin
      cMessage:= cs_ProcName + ': потік '+IntToStr(AThread.ThreadID) + ' НЕ є поточним потоком!..'+
        ' Зараз процедура виконується у потоці із ID=' + IntToStr(ccThreadId)+
        '...';
      if Assigned(Self.cGraphController) then
      Begin
        if Assigned(Self.cGraphController.LogFile) then
        Begin
          if Self.cGraphController.LogFile.Opened then
            Self.cGraphController.LogFile.WriteMessage(cMessage);
        End;
      End;

      Self.DSGraphOnLogMessage(Nil, cMessage);
      AThread:= Nil;
    End;
  End;

  TThread.Synchronize(AThread, AMethod);
End;

Procedure TForm1.DShowEventParamHandler(sCaller: TThread;
      sEvCode:Longint; slParam1, slParam2:Longint;
      sEventName, sEventData:String);

var //cEventDefineName, cEventData:String; cMessage:String;
    cNeedReopen:Boolean;

    x, y:Word;
Begin
    // Якщо секції немає, то форма вже була закрита, або ще не відкрилася...:
  if Not(Assigned(Self.cDShowEventSection)) then
  Begin
    ShowMessage('TForm1.DShowEventParamHandler: подія "'+sEventName+'.'+
     sEventData+'" відбулася коли форма не існує...');
    Exit;
  End;

  Self.cDShowEventSection.Enter;
  try
      // Якщо відтворення перервалося - відкриваємо знову:
    cNeedReopen:= False;
    case sEvCode of
      EC_COMPLETE: cNeedReopen:= True;
      EC_PLEASE_REOPEN: cNeedReopen:= True;
      EC_VIDEO_SIZE_CHANGED:
      Begin
        Get16Words(slParam1, x, y);

        Self.cNewVideoX:= x;
        Self.cNewVideoY:= y;
           // Синхронізуємося із потоком головного вікна і
           // запускаємо обробку нового розміра відео
           // (щоб вікно плеєра змінило свої розміри так щоб показати
           // по можливості відеовікно в оригінальних пропорціях і масштабі:
        Self.DoSynchronize(sCaller, //Nil,
           Self.ProcOnVideoSizeChanged);
      End;
      //Це виконується у Self.cGraphController, де викликається OnGraphEvent.
      //Тут не треба:
      //  // в інших подіях просто оновлюємо стан кнопок і індикаторів відтворення:
      //else Self.UpdateProcRunningButtonsState;
    end;

    if cNeedReopen then
    Begin
        //   Перезапускаємо відтворення графа на відтворення з поточним
        // джерелом з перебудовою графа:
      //Self.Stop;
      Self.Play('', '', True);
    End;
  finally
    Self.cDShowEventSection.Leave;
  end;
End;

Procedure TForm1.DSGraphOnStateChange(sCaller: TThread;
      Const sState, sLastState:TFilterState;
      sSTATE_INTERMEDIATE, sCANT_CUE:Boolean;
      sStateRes, sLastStateRes:HResult;
      sCurURL, sLastURL, sCurName_ch:String);
Begin
    // Якщо секції немає, то форма вже була закрита, або ще не відкрилася...:
  if Not(Assigned(Self.cDShowEventSection)) then
  Begin
    ShowMessage('TForm1.DSGraphOnStateChange: стан змінився коли форма не існує...');
    Exit;
  End;


    //   Запам'ятовуємо параметри, синхронізуємося із потоком вікон, і
    // оновлюємо відображення стану на вікні. Все це у критичній секції
    // для того щоб не було повторного входу і затирання параметрів поки йде
    // синхронізація із потоком вікна...:
  Self.cDShowEventSection.Enter;
  try
    Self.cCurState:= sState;
    Self.cSTATE_INTERMEDIATE:= sSTATE_INTERMEDIATE;
    Self.cCANT_CUE:= sCANT_CUE;

    Self.DoSynchronize(sCaller, //Nil,
      Self.ProcUpdateProcRunningButtonsState);
  finally
    Self.cDShowEventSection.Leave;
  end;
    //   Якщо граф починає відтворення або відображення по паузі, то треба
    // перемалювати паенль відображення відео. Це викличе перемалювання
    // відеорендерером пікселів відображення відео (у TPlayVideoPanel.Paint),
    // і замість панелі почнеться відео:
  if sState<>State_Stopped then
  Begin
    Self.DoSynchronize(sCaller, //Nil,
      Self.cPanelForVideo.Repaint);
  End;
End;

Procedure TForm1.DSGraphOnLogMessage(sCaller: TThread;
        Const sMessage:String;
        sThisIsCriticalError:Boolean = False);
Begin
    // Якщо критичну секцію ще не звільнили, тобто подія виникла не після звільнення форми:
  if Not(Assigned(Self.cDShowEventSection)) then
  Begin
    ShowMessage('TForm1.DSGraphOnLogMessage: повідомлення "'+
      sMessage+'" прийшло коли форма не існує...');
    Exit;
  End;

  //Begin
      //   Запам'ятовуємо параметри, синхронізуємося із потоком вікон, і
      // оновлюємо відображення стану на вікні. Все це у критичній секції
      // для того щоб не було повторного входу і затирання параметрів поки йде
      // синхронізація із потоком вікна...:
    Self.cDShowEventSection.Enter;
    try
      Self.cGraphLogMessage:= sMessage;

      Self.DoSynchronize(sCaller, //Nil,
        Self.ProcOnLogGraphMessage);
    finally
      Self.cDShowEventSection.Leave;
    end;
 // End;
End;

Procedure TForm1.ProcUpdateProcRunningButtonsState;
Begin
  Self.UpdateProcRunningButtonsState(Self.cCurState, Self.cSTATE_INTERMEDIATE,
    Self.cCANT_CUE);
End;

Procedure TForm1.ProcOnLogGraphMessage;
Begin
  Self.LogMessage(Self.cGraphLogMessage);
End;

Function TForm1.GetSampleCountToCapture:Cardinal;
Begin
  try
    Result:= StrToInt(Self.EditSampleCount.Text);
  except
    Result:= 1;
    Self.LogMessage('Задана кількість кадрів "'+Self.EditSampleCount.Text+
      '" не розпізнана як натуральне число. Буде використано ' +
      IntToStr(Result) + '...');
  end;
End;

Function TForm1.GetJpegQualityToSet:TJpegQualityRange;
Begin
  try
    Result:= StrToInt(Self.EditJpegQuality.Text);
  except
    Result:= c_DefJpegQuality;
    Self.LogMessage('Задана якість стискання "'+Self.EditJpegQuality.Text+
      '" не розпізнана як натуральне число. Буде використано ' +
      IntToStr(Result) + '...');
  end;
End;


Procedure TForm1.ProcOnVideoSizeChanged;
Var ccScreenWidth, ccScreenHeight, ccScreenLeft, ccScreenTop,
      ccNewVideoWidth, ccNewVideoHeight,
      ccResVideoWidth, ccResVideoHeight:Integer;
    ccOnPanelResize:TNotifyEvent;

    ccCoord, ccSize, cFormTop, cFormLeft:Integer;

    ccResized:Boolean;

    Function TuneWindowDimension(Var sdCoord, sdSize:Integer;
      sScreenCoord, sScreenSize:Integer):Boolean;
    Begin
      Result:= False;
      if sdSize > sScreenSize then
      Begin
        sdSize:= sScreenSize;
        Result:= True;
      End;

      if ((sdCoord + sdSize) > (sScreenCoord + sScreenSize)) then
      Begin
        sdCoord:= sScreenCoord + sScreenSize - sdSize;
        Result:= True;
      End
      else if (sdCoord < sScreenCoord) then
      Begin
        sdCoord:= sScreenCoord;
        Result:= True;
      End;
    End;
Begin
  ccNewVideoWidth:= Self.cNewVideoX;
  ccNewVideoHeight:= Self.cNewVideoY;

  ccResVideoWidth:= ccNewVideoWidth;
  ccResVideoHeight:= ccNewVideoHeight;


  ccScreenWidth:= Forms.Screen.WorkAreaWidth;
  ccScreenHeight:= Forms.Screen.WorkAreaHeight;
  ccScreenLeft:= Forms.Screen.WorkAreaLeft;
  ccScreenTop:= Forms.Screen.WorkAreaTop;

  cFormTop:= Self.Top;
  cFormLeft:= Self.Left;

  ccOnPanelResize:= Self.cPanelForVideo.OnResize;

  ccResized:= False;
      //   Збільшуємо розміри вікна якщо треба для відображення відео
      // в оригінальних розмірах, зміщуємо його:
  if Self.cPanelForVideo.ClientWidth <> ccNewVideoWidth then
  Begin
    ccResized:= True;
    Self.cPanelForVideo.OnResize:= Nil;  // вимикаємо обробку зміни розмірів поки порахуємо потрібну ширину і/або висоту
       // Обчислюємо яким має стати розмір вікна програми:
    ccCoord:= cFormLeft;
    ccSize:= Self.Width + ccNewVideoWidth - Self.cPanelForVideo.ClientWidth;
       // Коригуємо координату вікна програми і розмір відео,
       // якщо на екран вікно не вміщається:
    if TuneWindowDimension(ccCoord, ccSize, ccScreenLeft, ccScreenWidth) then
    Begin
      cFormLeft:= ccCoord;
      ccResVideoWidth:= ccSize + Self.cPanelForVideo.ClientWidth - Self.Width;
    End;
  End;

  if Self.cPanelForVideo.ClientHeight <> ccNewVideoHeight then
  Begin
    ccResized:= True;
    Self.cPanelForVideo.OnResize:= Nil;  // вимикаємо обробку зміни розмірів поки порахуємо потрібну ширину і/або висоту

       // Обчислюємо яким має стати розмір вікна програми:
    ccCoord:= cFormTop;
    ccSize:= Self.Height + ccNewVideoHeight - Self.cPanelForVideo.ClientHeight;
       // Коригуємо координату вікна програми і розмір відео,
       // якщо на екран вікно не вміщається:
    if TuneWindowDimension(ccCoord, ccSize, ccScreenTop, ccScreenHeight) then
    Begin
      cFormTop:= ccCoord;
      ccResVideoHeight:= ccSize + Self.cPanelForVideo.ClientHeight - Self.Height;
    End;
  End;

    // Зменшуємо один із розмірів вікна щоб вікно відео було в
    // оригінальній пропорції його розмірів:
  if (ccResVideoHeight <> ccNewVideoHeight) or
     (ccResVideoWidth <> ccNewVideoWidth) then  //ccResized and
  Begin
    if ccNewVideoWidth >= ccNewVideoHeight then
      ccResVideoHeight:= (ccResVideoWidth * ccNewVideoHeight) div ccNewVideoWidth
    Else
      ccResVideoWidth:= (ccResVideoHeight * ccNewVideoWidth) div ccNewVideoHeight;
  End;

  if ccResized then
  Begin
    Self.Top:= cFormTop;
    Self.Left:= cFormLeft;
    Self.Width:= Self.Width + ccResVideoWidth - Self.cPanelForVideo.ClientWidth;
    Self.Height:=  Self.Height + ccResVideoHeight - Self.cPanelForVideo.ClientHeight;
    //Зміна розміру панелі не змінює розмір вікна форми, бо це панель
    //вирівнюється по формі, а не форма по панелі:
    //Self.cPanelForVideo.ClientWidth:= ccResVideoWidth;
    //Self.cPanelForVideo.ClientHeight:= ccResVideoHeight;
       // Повертаємо на місце обробник зміни розміру:
    if Assigned(ccOnPanelResize) then
    Begin
      Self.cPanelForVideo.OnResize:= ccOnPanelResize;
         // Обробка нових розмірів вікна, налаштування відеовікна:
      ccOnPanelResize(Self);
    End;
  End;
End;

Procedure TForm1.ProcOnDisplayChange(Var sMessage:TWMDISPLAYCHANGE);
Begin
  Inherited;

  if Assigned(Self.cGraphController) then
    Self.cGraphController.DisplayModeChange;
End;

procedure ProcExceptHandler(ExceptObject: TObject; ExceptAddr: Pointer); far;
Var ccExceptMessage:String;
begin
  ccExceptMessage:= 'Виключення у '+ExceptObject.ClassName+'('+ExceptObject.ToString+
   ') за адресою '+IntToHex(Integer(ExceptAddr), 8)+'...';

  Inc(cExceptNumber);

  //ShowException(ExceptObject, ExceptAddr);
  MessageBox(0, PWideChar(ccExceptMessage),
    PWideChar('ExceptHandler:' + IntToStr(cExceptNumber)),
    MB_OK or MB_ICONSTOP or MB_TASKMODAL);
  //Dialogs.ShowMessage(ccExceptMessage);
end;

procedure ProcErrorProc(ErrorCode: Byte; ErrorAddr: Pointer);
Var ccExceptMessage:String;
Begin
  ccExceptMessage:= 'Виключення '+IntToStr(ErrorCode)+' за адресою'+
    IntToHex(Integer(ErrorAddr), 8)+'...';

  Inc(cExceptNumber);

  MessageBox(0, PWideChar(ccExceptMessage),
    PWideChar('ErrorProc:' + IntToStr(cExceptNumber)),
    MB_OK or MB_ICONSTOP or MB_TASKMODAL);
End;

Initialization
  cExceptNumber:= 0;
  //System.ExceptProc:= Addr(ProcExceptHandler);
  //System.ErrorProc:=  Addr(ProcErrorProc);
  //ExceptClsProc
end.

