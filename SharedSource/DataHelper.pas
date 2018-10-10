unit DataHelper;

interface

uses SysUtils, StrUtils, Classes, SyncObjs, AnsiStrings, Variants, Math,
 IdGlobal;

const
      cByteBitCount = 8;
      cByteHexLen = 2;
      c_ByteBits = $FF;
      c_ZeroSymb = '0';
      c_Comma = ',';
      c_Dot = '.';
      c_DoubleDot = ':';
      c_Quotes = '"';
      c_Semicolon = ';';
      c_Space = ' ';
      c_Equal = '=';
      c_CR = Chr(13);
      c_LF = Chr(10);

      c_BackSlash = '\';
      c_DoubleBackSlash = c_BackSlash + c_BackSlash;
      c_Slash = '/';
      c_DoubleSlash = c_Slash + c_Slash;

      c_Amp = '&';
      c_QuotesReplacement = c_Amp+'quot';
      c_SemicolonReplacement = c_Amp+'semicolon';
      c_CommaReplacement = c_Amp+'comma';
      c_AmpReplacement = c_Amp+'amp';

      c_HideMessageWhenRepeatedMoreThan = 3;

      c_FirstLogFileNum = 1;

      c_ANSICyrCodePage = 1251;

      sc_UnknownLengthOfFloatNumber = ': невідомий розмір для дійсного числа: ';
      sc_TriSpot = '...';

      //NaN         =  0.0 / 0.0;
      //Infinity    =  1.0 / 0.0;
      //NegInfinity = -1.0 / 0.0;
type
    TCp1251String = type AnsiString(c_ANSICyrCodePage);

    TPortWorkString = AnsiString;
    //PPortWorkString = ^TPortWorkString;

    //TPortWorkStringArray = array of TPortWorkString;
    TPortWorkChar = AnsiChar;
    PPortWorkChar = ^TPortWorkChar;

    TBufRec = record
      BufLength: Integer;
      Buf:array [0..0] of Byte;
    End;
    PBufRec = ^TBufRec;

    TWorkStringAndTimeRecord = record
         cTime: TDateTime;
         cString: TPortWorkString;
    End;

    TWorkStringAndTimeBufRecord = record
         FTime: TDateTime;
         FString: PBufRec;
    End;
    PWorkStringAndTimeBufRecord = ^TWorkStringAndTimeBufRecord;

    //TPortWorkBuf = array of TPortWorkChar;
    //PPortWorkBuf = ^TPortWorkBuf;

    TUnsignedIntegerParameters = array of Cardinal;
    TSingleFloatParameters = array of Single;
    TDoubleFloatParameters = array of Double;
    TExtendedFloatParameters = array of Extended;

    TPortWorkStrings = array of TPortWorkString;

    //TMessagePosArray = array of Integer;

    {PMessageList = ^TMessageList;
    TMessageList = record
      sMessage: TPortWorkString;
      Next: PMessageList;
    End;}

    TWorkStringList = class(Classes.TList)
      protected
        procedure Notify(Ptr: Pointer; Action: TListNotification); override;

        function Get(Index: Integer): TPortWorkString;
        procedure Put(Index: Integer; Const Item: TPortWorkString);
      public
        //destructor Destroy; override;
        function Add(Const Item: TPortWorkString): Integer;
        procedure Clear; override;
        procedure Delete(Index: Integer);
        function Remove(Item: TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): Integer;
        function Extract(Const Item: TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): TPortWorkString;
        function ExtractByNum(Index: Integer): TPortWorkString;
        function First: TPortWorkString;
        function ExtractFirst: TPortWorkString;
        procedure Insert(Index: Integer; Const Item: TPortWorkString);
        function Last: TPortWorkString;
        function ExtractLast: TPortWorkString;
             // Виконує пошук рядка у списку...:
        function IndexOf(Const Item: TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): Integer;

        property Items[Index: Integer]: TPortWorkString read Get write Put; default;
    end;

    TWorkStringAndTimeList = class(Classes.TList)
      protected
        procedure Notify(Ptr: Pointer; Action: TListNotification); override;

        function Get(Index: Integer): TWorkStringAndTimeRecord;
        procedure Put(Index: Integer; Const Item: TWorkStringAndTimeRecord);
      public
        //destructor Destroy; override;
        function Add(Const Item: TWorkStringAndTimeRecord): Integer; overload;
        function Add(Const sTime:TDateTime; Const sString: TPortWorkString): Integer; overload;
        procedure Clear; override;
        procedure Delete(Index: Integer);

        function Remove(Item: TWorkStringAndTimeRecord;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): Integer;

        function Extract(Const Item: TWorkStringAndTimeRecord;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): TWorkStringAndTimeRecord; overload;

        function Extract(Const sTime:TDateTime; Const sString: TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): TWorkStringAndTimeRecord; overload;

        function ExtractByNum(Index: Integer): TWorkStringAndTimeRecord;
        function First: TWorkStringAndTimeRecord; overload;
        procedure First(Var dTime:TDateTime; Var dString: TPortWorkString); overload;
        function ExtractFirst: TWorkStringAndTimeRecord; overload;
        procedure ExtractFirst(Var dTime:TDateTime; Var dString: TPortWorkString); overload;
        procedure Insert(Index: Integer; Const Item: TWorkStringAndTimeRecord); overload;
        procedure Insert(Index: Integer;
          Const sTime:TDateTime; Const sString: TPortWorkString); overload;
        function Last: TWorkStringAndTimeRecord; overload;
        procedure Last(Var dTime:TDateTime; Var dString: TPortWorkString); overload;
        function ExtractLast: TWorkStringAndTimeRecord; overload;
        procedure ExtractLast(Var dTime:TDateTime; Var dString: TPortWorkString); overload;
             // Виконує пошук рядка і часу запису у списку за заданим часом і рядком...:
        function IndexOf(Const Item: TWorkStringAndTimeRecord;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): Integer;

        property Items[Index: Integer]: TWorkStringAndTimeRecord read Get write Put; default;
    end;

    {TWorkStringAndTimeRecordObject = class(TObject)
       private
         FString: TPortWorkString;
         FTime: TDateTime;
       public
         Constructor Create(sTime: TDateTime; sString: TPortWorkString)
         property Time: TDateTime read
    end;}


    TCustomTextFile = class(TObject)
      private
        cFile: System.Text;
        cFilePath: String;
        cOpened: Boolean;

        cFileCriticalSection:SyncObjs.TCriticalSection;
      Protected
        Procedure ProcEnterCriticalSection;
        Procedure ProcLeaveCriticalSection;


      public
        property Opened: Boolean read cOpened;
        property FilePath:String read cFilePath;

        Constructor Create(UseCriticalSection:Boolean = True);
        Procedure Open(Const sPath:String); virtual; abstract;
        Procedure Close; virtual;
        Destructor Destroy; override;
    end;

    TLogFile = class(TCustomTextFile)
    private
      //cFile: System.Text;
      //cFilePath: String;
      //cOpened: Boolean;

      //cFileCriticalSection:SyncObjs.TCriticalSection;

      cLastLogTime: TDateTime;
      cLastLogLine: String;

      cLineRepeatCount: Cardinal;

      cMessageRepeatChecking:Boolean;
      cHideMessageWhenRepeatedMoreThan:Cardinal;

      //Procedure ProcEnterCriticalSection;
      //Procedure ProcLeaveCriticalSection;
    protected
      function GetLastLogLine: String;
      function GetLastLogLineNoTimeStamp: String;
      function GetLastLogTime: TDateTime;

      Procedure SetMessageRepeatChecking(Value: Boolean);
      Procedure SetHideMessageWhenRepeatedMoreThan(Value: Cardinal);

      procedure ProcLogRepeating(Const sTimeToWrite:TDateTime);

      procedure ProcWriteMessage(Const sMessage:String;
        sFinishLine:Boolean = True);
    public
      //property Opened: Boolean read cOpened;
      //property FilePath:String read cFilePath;

      property LastLogLine: String read GetLastLogLine;
      property LastLogLineWithNoTimeStamp: String read GetLastLogLineNoTimeStamp;
      property LastLogTime: TDateTime read GetLastLogTime;

      property MessageRepeatChecking: Boolean read cMessageRepeatChecking
        write SetMessageRepeatChecking;
      property HideMessageWhenRepeatedMoreThan: Cardinal
        read cHideMessageWhenRepeatedMoreThan write SetHideMessageWhenRepeatedMoreThan;

      Constructor Create(UseCriticalSection:Boolean = True;
        sMessageRepeatChecking:Boolean = True;
        sHideMessageWhenRepeatedMoreThan: Cardinal = c_HideMessageWhenRepeatedMoreThan);
      Procedure Open(Const sPath:String); override;
      Procedure WriteMessage(Const sMessage:String;
        sFinishLine:Boolean = True; sAddTimeStamp:Boolean = True);
      Procedure Close; override;

      //Destructor Destroy; override;
    end;


    TReadingTextFile = class(TCustomTextFile)
    private
      //cFile: System.Text;
      //cFilePath: String;
      //cOpened: Boolean;

      //cFileCriticalSection:SyncObjs.TCriticalSection;

      //cLastLogTime: TDateTime;
      //cLastLogLine: String;

      //cLineRepeatCount: Cardinal;

      //cMessageRepeatChecking:Boolean;
      //cHideMessageWhenRepeatedMoreThan:Cardinal;
    protected

      //Procedure ProcEnterCriticalSection;
      //Procedure ProcLeaveCriticalSection;

      //function GetLastLogLine: String;
      //function GetLastLogLineNoTimeStamp: String;
      //function GetLastLogTime: TDateTime;

      //Procedure SetMessageRepeatChecking(Value: Boolean);
      //Procedure SetHideMessageWhenRepeatedMoreThan(Value: Cardinal);

      //procedure ProcLogRepeating(Const sTimeToWrite:TDateTime);

      //procedure ProcWriteMessage(Const sMessage:String;
      //  sFinishLine:Boolean = True);

      Function ProcReadLine:String;
    public
      Constructor Create(UseCriticalSection:Boolean = True);
      Procedure Open(Const sPath:String); override;
        // Повертає True, якщо файл вдалося відкрити з початку.
        // Якщо файл не був відкритий - повертає False.
      Function ReOpenFromStart:Boolean;
      Function EOF:Boolean;
      Function EOLn:Boolean;
        // Функції SeekEOF SeekEOln пропускають тільки пробіли. Якщо
        // зустрічають символи, що не є пробілами, то зупиняються на них і
        // повертають False:
      Function SeekEOF:Boolean;
      Function SeekEOln:Boolean;

      Function ReadLine:String;
      //Procedure Close; override;
      //Destructor Destroy; override;
    end;

  TUIntList = class(Classes.TList)
    protected
      procedure Notify(Ptr: Pointer; Action: TListNotification); override;

      function Get(Index: Integer): Cardinal;
      procedure Put(Index: Integer; Const Item: Cardinal);
    public
        function Add(Const Item: Cardinal): Integer;
        procedure Clear; override;
        procedure Delete(Index: Integer);
        function Remove(Item: Cardinal): Integer;
        function Extract(Const Item: Cardinal): Cardinal;
        function ExtractByNum(Index: Integer): Cardinal;
        function First: Cardinal;
        function ExtractFirst: Cardinal;
        procedure Insert(Index: Integer; Const Item: Cardinal);
        function Last: Cardinal;
        function ExtractLast: Cardinal;
             // Виконує пошук у списку... знаходить перший елемент, що
             // рівний поданому значенню:
        function IndexOf(Const Item: Cardinal): Integer;

        property Items[Index: Integer]: Cardinal read Get write Put; default;
  end;

function Trim(const S: TPortWorkString;
    sSpace:TPortWorkString = c_Space;
    sDiscardAllCodesUpToSpace:Boolean = True): TPortWorkString;
//function Trim(const S: String): String; overload;

function BinToHexString(bs: TPortWorkString): TPortWorkString;
function HexToByte(h: TPortWorkString; sLogFile:TLogFile): Byte;
function HexToBinString(s: TPortWorkString; sLogFile:TLogFile): TPortWorkString;


  // Зміна порядку байтів, копіювання:
function BufToString(Const sBuf; sLength:Cardinal;
  sLittleEndian:Boolean = True):TPortWorkString;
Procedure StringToBuf(Const sString:TPortWorkString; Var dBuf;
  sLittleEndian:Boolean = True);

    // --- Перевірка передачі даних, CRC ---
    // Запис числа у рядок за правилом BigEndian (старші байти першими):
function NumberToStringBigEndian(SNumber:Cardinal;
           SBytesCount:Byte):TPortWorkString;
    // Запис числа у рядок за правилом LittleEndian (молодші байти першими):
function NumberToStringLittleEndian(SNumber:Cardinal;
           SBytesCount:Byte):TPortWorkString;
    // Збірна функція, NumberToStringBigEndian або NumberToStringLittleEndian:
function NumberToString(SNumber:Cardinal;
           SBytesCount:Byte; sLittleEndian:Boolean = True):TPortWorkString; overload;
    // Запис дійсних чисел в рядок:
function NumberToString(Const SNumber:Single;
           sLittleEndian:Boolean = True):TPortWorkString; overload;
function NumberToString(Const SNumber:Double;
           sLittleEndian:Boolean = True):TPortWorkString; overload;
function NumberToString(Const SNumber:Extended;
           sLittleEndian:Boolean = True):TPortWorkString; overload;
    // Запис байтового рядка за правилом BigEndian (старші байти першими) як числа:
function StringBigEndianToNumber(SString:TPortWorkString;
  sMaxBytesCount:Byte=SizeOf(Cardinal)):Cardinal;
    // Запис байтового рядка за правилом LittleEndian (молодші байти першими) як числа:
function StringLittleEndianToNumber(SString:TPortWorkString;
  sMaxBytesCount:Byte=SizeOf(Cardinal)):Cardinal;
    // Збірна функція, StringBigEndianToNumber або StringLittleEndianToNumber:
function StringToNumber(SString:TPortWorkString;
  sMaxBytesCount:Byte=SizeOf(Cardinal); sLittleEndian:Boolean = True):Cardinal; overload;
    // Читання дійсних чисел із рядків:
Procedure StringToNumber(Const SString:TPortWorkString; Var dNum:Single;
  sLittleEndian:Boolean = True); overload;
Procedure StringToNumber(Const SString:TPortWorkString; Var dNum:Double;
  sLittleEndian:Boolean = True); overload;
Procedure StringToNumber(Const SString:TPortWorkString; Var dNum:Extended;
  sLittleEndian:Boolean = True); overload;

   // Відкушує частину рядка за вказаними позиціями:
function CutSubString(sString:TPortWorkString; sStart, SCount:Integer;
           Var dRemainedString: TPortWorkString):TPortWorkString;
   //   Відкушує частину рядка від його початку до заданого рядка-суфікса.
   //   Повертає відкушену частину. у dRemainedString повертає частину, що
   // лишилася (кінець рядка).
   //   sLeaveSuffixInRemainedString - лишити знайдений суфікс у dRemainedString;
   //   sPutSuffixToCuttedPart - відкусити разом із суфіксом;
   //   При sLeaveSuffixInRemainedString = False і sPutSuffixToCuttedPart = False
   // знайдений суфікс відкидаєтсья (не лишається у рядках).
function CutFromStartToSuffix(sString, sSuffix:TPortWorkString;
           Var dRemainedString: TPortWorkString;
           sLeaveSuffixInRemainedString:Boolean = False;
           sPutSuffixToCuttedPart:Boolean = False):TPortWorkString;

function CutFromPosToSuffix(Const sString, sSuffix:TPortWorkString;
           Var sdPos: Integer;
           sLeaveSuffixInRemainedString:Boolean = False;
           sPutSuffixToCuttedPart:Boolean = False):TPortWorkString;

Procedure PrepareToCutFromPosToSuffix(Const sString, sSuffix:TPortWorkString;
           sPos: Integer; Var dCuttedLength, dNextPos: Integer;
           sLeaveSuffixInRemainedString:Boolean = False;
           sPutSuffixToCuttedPart:Boolean = False); overload;

Procedure PrepareToCutFromPosToSuffix(Const sString, sSuffix:String;
           sPos: Integer; Var dCuttedLength, dNextPos: Integer;
           sLeaveSuffixInRemainedString:Boolean = False;
           sPutSuffixToCuttedPart:Boolean = False); overload;

    // Витягування масива чисел із буфера:
function StringBigEndianToNumberArray(sString:TPortWorkString;
           sBytesInNumber:Byte):TUnsignedIntegerParameters;
function StringToNaturalNumberArray(sString:TPortWorkString;
           sBytesInNumber:Byte; sLittleEndian:Boolean = False):TUnsignedIntegerParameters;
function StringToSingleNumberArray(sString:TPortWorkString;
           sLittleEndian:Boolean = False):TSingleFloatParameters;
function StringToDoubleNumberArray(sString:TPortWorkString;
           sLittleEndian:Boolean = False):TDoubleFloatParameters;
function StringToExtendedNumberArray(sString:TPortWorkString;
           sLittleEndian:Boolean = False):TExtendedFloatParameters;

function NumberArrayToStringBigEndian(Const sNumbers:TUnsignedIntegerParameters;
  sBytesInNumber:Byte = SizeOf(Cardinal)):TPortWorkString;
function NumberArrayToString(Const sNumbers:TUnsignedIntegerParameters;
  sBytesInNumber:Byte = SizeOf(Cardinal);
  sLittleEndian:Boolean = False):TPortWorkString; overload;
function NumberArrayToString(Const sNumbers:TSingleFloatParameters;
  sLittleEndian:Boolean = False):TPortWorkString; overload;
function NumberArrayToString(Const sNumbers:TDoubleFloatParameters;
  sLittleEndian:Boolean = False):TPortWorkString; overload;
function NumberArrayToString(Const sNumbers:TExtendedFloatParameters;
  sLittleEndian:Boolean = False):TPortWorkString; overload;

  // Записує число в рядок у двійковій системі
  // (задом наперед при sBigEndian = False).
function NumberToBitString(sNumber:Cardinal;
  sBytesInNumber:Byte = SizeOf(Cardinal);
  sBigEndian:Boolean = True):TPortWorkString;

  // Записує рядок у двійковій системі в число.
function BitStringToNumber(sString:TPortWorkString;
  sBytesInNumber:Byte = SizeOf(Cardinal);
  sBigEndian:Boolean = True):Cardinal;

function NumberArrayToCommaSeparatedString(Const sNumbers:TUnsignedIntegerParameters;
  sComma:TPortWorkString = c_Comma; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes;
  s_ConvertToSignedNumbers:Boolean = False):TPortWorkString; overload;

{function NumberArrayToCommaSeparatedString(Const sNumbers: array of Const;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes):TPortWorkString; overload;}

function NumberArrayToCommaSeparatedString(Const sNumbers:TSingleFloatParameters;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes):TPortWorkString; overload;
function NumberArrayToCommaSeparatedString(Const sNumbers:TDoubleFloatParameters;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes):TPortWorkString; overload;
function NumberArrayToCommaSeparatedString(Const sNumbers:TExtendedFloatParameters;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes):TPortWorkString; overload;

Function StringBufToNumbersCommaSeparatedString(sString:TPortWorkString;
           sBytesInNumber:Byte; sFloatNumbers:Boolean = False;
           s_ConvertToSignedNumbers:Boolean = False; // тільки для цілих чисел, float завжди зі знаком
  sLittleEndian:Boolean = False;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes;
  sLogFile:TLogFile = Nil):TPortWorkString;

function CommaSeparatedNumbersToNumberArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Comma; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TUnsignedIntegerParameters;
function CommaSeparatedNumbersToSingleNumberArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Semicolon; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TSingleFloatParameters;
function CommaSeparatedNumbersToDoubleNumberArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Semicolon; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TDoubleFloatParameters;
function CommaSeparatedNumbersToExtendedNumberArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Semicolon; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TExtendedFloatParameters;

Function CommaSeparatedNumbersToStringBuf(sString:TPortWorkString;
    sFloatNumbers:Boolean; sBytesForNumber:Byte;
    sWriteLittleEndian:Boolean = False;
    sComma:TPortWorkString = c_Semicolon; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TPortWorkString;

function StringArrayToCommaSeparatedString(sStrings:TPortWorkStrings;
  sComma:TPortWorkString = c_Comma; sAddPairQuotes:Boolean = True;
  s_Quotes:TPortWorkString = c_Quotes;
  s_QuotesReplacement:TPortWorkString = c_QuotesReplacement;
  s_CommaReplacement:TPortWorkString = c_CommaReplacement):TPortWorkString;

function CommaSeparatedStringsToStringArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Comma; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil;  // файл для запису повідомлень про помилки та попереджень (якщо не заданий - повідомлення про помилки передаються як виключення). У цій функції поки що не використовується
    s_QuotesReplacement:TPortWorkString = c_QuotesReplacement;
    s_CommaReplacement:TPortWorkString = c_CommaReplacement):TPortWorkStrings;

// --- Робота з числами
function DivR(sDivided, sDivider:Cardinal; Var dRemainder:Cardinal;
  sReserveForRemainder:Boolean=False):Cardinal;

function DivWithReserve(sDivided, sDivider:Cardinal):Cardinal;

function ConvertNumberArrayToExtended(Const sNumbers:TSingleFloatParameters):
  TExtendedFloatParameters; overload;

function ConvertNumberArrayToExtended(Const sNumbers:TDoubleFloatParameters):
  TExtendedFloatParameters; overload;

function ConvertNumberArrayToSingle(Const sNumbers:TExtendedFloatParameters):
  TSingleFloatParameters;

function ConvertNumberArrayToDouble(Const sNumbers:TExtendedFloatParameters):
  TDoubleFloatParameters; overload;

function AsBoolean(Const sValue: OleVariant):Boolean;
  // Замінювач рядків.. AnsiStrings.ReplaceStr не підійшов, бо дивиться на
  // нульові символи і зупиняється на них.. Тому так:
function PortStringReplace(const AStr, AFromStr, AToStr:
  TPortWorkString):TPortWorkString; overload;
function PortStringReplace(const AStr:TPortWorkString; AFromStr, AToStr:
  TWorkStringList; sAllWordsInOnePass:Boolean = True):TPortWorkString; overload;
function StringReplace(const AStr, AFromStr, AToStr: String):String; overload;
function StringReplace(const AStr:String; AFromStr, AToStr:
  TStrings; sAllWordsInOnePass:Boolean = True):String; overload;

function BytesToAnsiString(const sBytes:TIdBytes):AnsiString;
function BytesToString(const sBytes:TIdBytes):String;
function AnsiStringToBytes(const sString:AnsiString):TIdBytes;
function StringToBytes(const sString:String):TIdBytes;

implementation

function PortStringReplace(const AStr:TPortWorkString;
   AFromStr, AToStr: TWorkStringList;
   sAllWordsInOnePass:Boolean = True):TPortWorkString;
Var ccPos, ccOldPos:Integer; //, ccAFromStrLen
    // 2017.02.02. З цього ccPosArray треба було зробити масив позицій всіх
    // слів і їх номерів або довжин. Але поспішав, і забув взагалі
    // використати цей масив, тільки зробив його заповнення.
    // І в ньому треба записувати не лише позиції, а й номери чи довжини слів.
    // Покищо без нього зробив...:
    //ccPosArray,
    ccFromStrLenArray: TUnsignedIntegerParameters;
    ccReplacedWordsCount, ccReplaceWordNum,
      ccCurReplacedWordNum:Integer;

    Procedure GetNextWordPos(const AStr:TPortWorkString;
      var AFromStr, AToStr: TWorkStringList;
      var ccPos, ccOldPos:Integer;
      //var ccPosArray: TUnsignedIntegerParameters;
      const ccReplacedWordsCount: Integer;
      var ccCurReplacedWordNum: Integer);
    Var ccReplaceWordNum:Integer;
        ccCurWordPos:Integer;
        //ccNoMoreToReplace:Boolean;
    Begin
      //ccNoMoreToReplace:= True; // це не треба якщо є "ccPos:= 0;"
        // 2017.02.02. Цю ініціалізацію я забув написати 2015 року...
        // або поспішав і подумав що це не можна. Але це треба:
      ccPos:= 0;
      for ccReplaceWordNum:= 0 to ccReplacedWordsCount - 1 do
      Begin
        ccCurWordPos:= AnsiStrings.PosEx(AFromStr[ccReplaceWordNum], AStr, ccOldPos);
        //ccPosArray[ccReplaceWordNum]:= ccCurWordPos;
           // Визначаємо перше місце появи одного із слів:
        if (ccCurWordPos > 0) and ((ccPos = 0) or (ccPos > ccCurWordPos)) then
        Begin
          //ccNoMoreToReplace:= False;
          ccPos:= ccCurWordPos;
          ccCurReplacedWordNum:= ccReplaceWordNum;
        End;
      End;

      //if ccNoMoreToReplace then ccPos:= 0;
    End;
Begin
  ccReplacedWordsCount:= AFromStr.Count;

  if sAllWordsInOnePass then
  Begin
    Result:='';

    //System.SetLength(ccPosArray, ccReplacedWordsCount);
    System.SetLength(ccFromStrLenArray, ccReplacedWordsCount);

    ccOldPos:= 1;
    ccPos:= 0;
    ccCurReplacedWordNum:= 0;
      // Читаємо довжини слів, які треба заміняти:
    for ccReplaceWordNum := 0 to ccReplacedWordsCount - 1 do
    Begin
      ccFromStrLenArray[ccReplaceWordNum]:=
        Cardinal(System.Length(AFromStr[ccReplaceWordNum]));
    End;
      //  Шукаємо місця перших появ кожного слова:
    GetNextWordPos(AStr,
      AFromStr, AToStr,
      ccPos, ccOldPos,
      //ccPosArray,
      ccReplacedWordsCount,
      ccCurReplacedWordNum);

    while ccPos > 0 do
    Begin
      Result:= Result + System.Copy(AStr, ccOldPos, ccPos - ccOldPos) +
        AToStr[ccCurReplacedWordNum];

      ccOldPos:= ccPos + Integer(ccFromStrLenArray[ccCurReplacedWordNum]);

      GetNextWordPos(AStr,
        AFromStr, AToStr,
        ccPos, ccOldPos,
        //ccPosArray,
        ccReplacedWordsCount,
        ccCurReplacedWordNum);
    End;

    Result:= Result + System.Copy(AStr, ccOldPos, System.Length(AStr)-ccOldPos+1);

    System.SetLength(ccFromStrLenArray, 0);
    //System.SetLength(ccPosArray, 0);
  End
  Else
  Begin
    Result:= AStr;
    for ccReplaceWordNum := 0 to ccReplacedWordsCount - 1 do
    Begin
      Result:= DataHelper.PortStringReplace(Result,
        AFromStr[ccReplaceWordNum],
        AToStr[ccReplaceWordNum]);
    End;
  End;
End;

function PortStringReplace(const AStr, AFromStr, AToStr:
  TPortWorkString):TPortWorkString;
Var ccPos, ccOldPos, ccAFromStrLen:Integer;
Begin
  Result:='';

  ccAFromStrLen:= System.Length(AFromStr);

  ccOldPos:= 1;
  ccPos:= AnsiStrings.PosEx(AFromStr, AStr, ccOldPos);
  while ccPos > 0 do
  Begin
    Result:= Result + System.Copy(AStr, ccOldPos, ccPos - ccOldPos) +
      AToStr;
    ccOldPos:= ccPos + ccAFromStrLen;
    ccPos:= AnsiStrings.PosEx(AFromStr, AStr, ccOldPos);
  End;
  Result:= Result + System.Copy(AStr, ccOldPos, System.Length(AStr)-ccOldPos+1);
End;

function StringReplace(const AStr:String; AFromStr, AToStr: TStrings;
    sAllWordsInOnePass:Boolean = True):String;
Var ccPos, ccOldPos:Integer; //, ccAFromStrLen
    // 2017.02.02. З цього ccPosArray треба було зробити масив позицій всіх
    // слів і їх номерів або довжин. Але поспішав, і забув взагалі
    // використати цей масив, тільки зробив його заповнення.
    // І в ньому треба записувати не лише позиції, а й номери чи довжини слів.
    // Покищо без нього зробив...:
    //ccPosArray,
    ccFromStrLenArray: TUnsignedIntegerParameters;
    ccReplacedWordsCount, ccReplaceWordNum,
      ccCurReplacedWordNum:Integer;

    Procedure GetNextWordPos(const AStr:String;
      var AFromStr, AToStr: TStrings;
      var ccPos, ccOldPos:Integer;
      //var ccPosArray: TUnsignedIntegerParameters;
      const ccReplacedWordsCount: Integer;
      var ccCurReplacedWordNum: Integer);
    Var ccReplaceWordNum:Integer;
        ccCurWordPos:Integer;
        //ccNoMoreToReplace:Boolean;
    Begin
      //ccNoMoreToReplace:= True; // це не треба якщо є "ccPos:= 0;"
        // 2017.02.02. Цю ініціалізацію я забув написати 2015 року...
        // або поспішав і подумав що це не можна. Але це треба:
      ccPos:= 0;
      for ccReplaceWordNum:= 0 to ccReplacedWordsCount - 1 do
      Begin
        ccCurWordPos:= StrUtils.PosEx(AFromStr[ccReplaceWordNum], AStr, ccOldPos);
        //ccPosArray[ccReplaceWordNum]:= ccCurWordPos;
           // Визначаємо перше місце появи одного із слів:
        if (ccCurWordPos > 0) and ((ccPos = 0) or (ccPos > ccCurWordPos)) then
        Begin
          //ccNoMoreToReplace:= False;
          ccPos:= ccCurWordPos;
          ccCurReplacedWordNum:= ccReplaceWordNum;
        End;
      End;

      //if ccNoMoreToReplace then ccPos:= 0;
    End;
Begin
  ccReplacedWordsCount:= AFromStr.Count;

  if sAllWordsInOnePass then
  Begin
    Result:='';

//    System.SetLength(ccPosArray, ccReplacedWordsCount);
    System.SetLength(ccFromStrLenArray, ccReplacedWordsCount);

    ccOldPos:= 1;
    ccPos:= 0;
    ccCurReplacedWordNum:= 0;
      // Читаємо довжини слів, які треба заміняти:
    for ccReplaceWordNum := 0 to ccReplacedWordsCount - 1 do
    Begin
      ccFromStrLenArray[ccReplaceWordNum]:=
        Cardinal(System.Length(AFromStr[ccReplaceWordNum]));
    End;
      //  Шукаємо місця перших появ кожного слова:
    GetNextWordPos(AStr,
      AFromStr, AToStr,
      ccPos, ccOldPos,
//      ccPosArray,
      ccReplacedWordsCount,
      ccCurReplacedWordNum);

    while ccPos > 0 do
    Begin
      Result:= Result + System.Copy(AStr, ccOldPos, ccPos - ccOldPos) +
        AToStr[ccCurReplacedWordNum];

      ccOldPos:= ccPos + Integer(ccFromStrLenArray[ccCurReplacedWordNum]);

      GetNextWordPos(AStr,
        AFromStr, AToStr,
        ccPos, ccOldPos,
//        ccPosArray,
        ccReplacedWordsCount,
        ccCurReplacedWordNum);
    End;

    Result:= Result + System.Copy(AStr, ccOldPos, System.Length(AStr)-ccOldPos+1);

    System.SetLength(ccFromStrLenArray, 0);
//    System.SetLength(ccPosArray, 0);
  End
  Else
  Begin
    Result:= AStr;
    for ccReplaceWordNum := 0 to ccReplacedWordsCount - 1 do
    Begin
      Result:= DataHelper.StringReplace(Result,
        AFromStr[ccReplaceWordNum],
        AToStr[ccReplaceWordNum]);
    End;
  End;
End;

function StringReplace(const AStr, AFromStr, AToStr: String):String;
Var ccPos, ccOldPos, ccAFromStrLen:Integer;
Begin
  Result:='';

  ccAFromStrLen:= System.Length(AFromStr);

  ccOldPos:= 1;
  ccPos:= StrUtils.PosEx(AFromStr, AStr, ccOldPos);
  while ccPos > 0 do
  Begin
    Result:= Result + System.Copy(AStr, ccOldPos, ccPos - ccOldPos) +
      AToStr;
    ccOldPos:= ccPos + ccAFromStrLen;
    ccPos:= StrUtils.PosEx(AFromStr, AStr, ccOldPos);
  End;
  Result:= Result + System.Copy(AStr, ccOldPos, System.Length(AStr)-ccOldPos+1);
End;

function DivR(sDivided, sDivider:Cardinal; Var dRemainder:Cardinal;
  sReserveForRemainder:Boolean=False):Cardinal;
Begin
  Result:= sDivided div sDivider;
  dRemainder:= sDivided mod sDivider;
  if sReserveForRemainder And (dRemainder <> 0) then
    Inc(Result);
End;

function DivWithReserve(sDivided, sDivider:Cardinal):Cardinal;
Var ccRemainder: Cardinal;
Begin
  Result:= DivR(sDivided, sDivider, ccRemainder, True);
End;

function BinToHexString(bs: TPortWorkString): TPortWorkString;
var i: Integer;
    c: TPortWorkChar;
    cResult:String;
begin
  Result:='';
  cResult:= '';
  for i:=1 to length(bs) do begin
    c:=bs[i];
    cResult:= cResult + IntToHex(ord(c), 2)+c_Space;
    //result:=result+AnsiString(IntToHex(ord(c), 2))+c_Space;
  end;

  Result:= AnsiString(cResult);
end;

// Взята із SysUtils... В ній змінено тип String на TPortWorkString.
// Інакше компілятор попереджає про неявне перетворення типів
// String і AnsiString...:
function Trim(const S: TPortWorkString;
    sSpace:TPortWorkString = c_Space;
    sDiscardAllCodesUpToSpace:Boolean = True): TPortWorkString;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;

  if sDiscardAllCodesUpToSpace then
  Begin
    while (I <= L) and (S[I] <= sSpace) do Inc(I);
    if I > L then Result := '' else
    begin
      while S[L] <= sSpace do Dec(L);
      Result := Copy(S, I, L - I + 1);
    end;
  End
  Else
  Begin
    while (I <= L) and (S[I] = sSpace) do Inc(I);
    if I > L then Result := '' else
    begin
      while S[L] = sSpace do Dec(L);
      Result := Copy(S, I, L - I + 1);
    end;
  End;
end;

{function Trim(const S: String): String;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= c_Space) do Inc(I);
  if I > L then Result := '' else
  begin
    while S[L] <= c_Space do Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
end;}

function HexToByte(h: TPortWorkString; sLogFile:TLogFile): Byte;
  var N:Byte;
  i:Integer;
  z: TPortWorkChar;
begin
  Result:=0;

  h:= trim(h);
  if length(h)>8 then
  Begin
    sLogFile.WriteMessage('Длина HEX-числа превышает 8 символов');
    Exit;
  End;

  if length(h)=0 then
  Begin
    sLogFile.WriteMessage('Пустое HEX-число');
    Exit;
  End;

  N:=0;

  for i:=1 to length(h) do begin
    z:=h[i];
    if i>1 then
       N:=N shl 4;

    case z of
      '0': begin end;
      '1': N:=N+1;
      '2': N:=N+2;
      '3': N:=N+3;
      '4': N:=N+4;
      '5': N:=N+5;
      '6': N:=N+6;
      '7': N:=N+7;
      '8': N:=N+8;
      '9': N:=N+9;
      'A', 'a': N:=N+10;
      'B', 'b': N:=N+11;
      'C', 'c': N:=N+12;
      'D', 'd': N:=N+13;
      'E', 'e': N:=N+14;
      'F', 'f': N:=N+15;
      else
      Begin
        sLogFile.WriteMessage('Неправильное HEX-число: "'+String(h)+'"...');
        Exit;
      End;
    end;//case
  end;
  Result:=N;



end;



function HexToBinString(s: TPortWorkString; sLogFile:TLogFile): TPortWorkString;
var i: Integer;
 ss: TPortWorkString;
 c: TPortWorkChar;
 ccWordLength: Integer;
begin
  s:=Trim(s);  // якщо є зайві пробіли вкінці - відкидаємо
  result:='';
  // 2017.12.13. Якщо передали пустий рядок - то не значить що щось не так...
  // Просто він дійсно може бути пустим коли нема жодного коду символа.
  // Тому результуючий рядок буде теж пустим, і повідомляти про помилку
  // кодування не треба:
  if System.Length(s) = 0 then
    Exit;

  s:=s+c_Space;    // проте додаємо один в кінець, він потрібен як маркер

  ss:='';

  for i:=1 to System.Length(s) do begin
    c:=s[i];
    ss:=ss+c;
    if (c=c_Space) then
    Begin
      ss:=trim(ss);
      ccWordLength:= System.Length(ss);
      if ccWordLength <> 0 then
      begin
        if ccWordLength <> 2 then
        Begin
          sLogFile.WriteMessage('HexToBinString: Ожидаются 2-значные цифры... Значение не распознано: "'+
            String(ss)+'"...');
          ss:='';  // 2017.12.13. Коли щось не розпізнане - відкидаємо... а не ліпимо до нього нові символи сплошняком...
          Continue;
        End;

        result:=result+AnsiChar(HexToByte(ss, sLogFile));
        ss:='';
      end;
    end;
  end;
  //MessageBox(0, pchar(''+result), '', 0); //это для проверки, потом убрать
end;

function BufToString(Const sBuf; sLength:Cardinal;
  sLittleEndian:Boolean = True):TPortWorkString;
var ccPBuf, ccChar, ccFirstChar:PPortWorkChar;
Begin
  System.SetLength(Result, sLength);

  if sLittleEndian then
  Begin
    System.Move(sBuf, Result[1], sLength * SizeOf(TPortWorkChar));
  End
  Else // BigEndian:
  Begin
    if sLength > 0 then
    Begin
      ccPBuf:= Addr(sBuf);
      ccChar:= Addr(Result[sLength * SizeOf(TPortWorkChar)]);
      ccFirstChar:= Addr(Result[1]);

      while Cardinal(ccChar)>=Cardinal(ccFirstChar) do
      Begin
        ccChar^:= ccPBuf^;
        Inc(ccPBuf, SizeOf(TPortWorkChar));
        Dec(ccChar, SizeOf(TPortWorkChar));
      End;
    End;
  End;
End;

Procedure StringToBuf(Const sString:TPortWorkString; Var dBuf;
  sLittleEndian:Boolean = True);
Var ccLength:Cardinal;
    ccPBuf, ccChar, ccFirstChar:PPortWorkChar;
Begin
  ccLength:= System.Length(sString);
  if sLittleEndian then
  Begin
    System.Move(sString[1], dBuf, ccLength * SizeOf(TPortWorkChar));
  End
  Else // BigEndian:
  Begin
    if ccLength > 0 then
    Begin
      ccPBuf:= Addr(dBuf);
      ccChar:= Addr(sString[ccLength * SizeOf(TPortWorkChar)]);
      ccFirstChar:= Addr(sString[1]);

      while Cardinal(ccChar)>=Cardinal(ccFirstChar) do
      Begin
        ccPBuf^:= ccChar^;
        Inc(ccPBuf, SizeOf(TPortWorkChar));
        Dec(ccChar, SizeOf(TPortWorkChar));
      End;
    End;
  End;
End;

function NumberToStringBigEndian(SNumber:Cardinal; SBytesCount:Byte):TPortWorkString;
var ResStr:TPortWorkString; i:Byte;
begin
  System.Setlength(ResStr, SBytesCount);
  for i := SBytesCount downto 1 do
  Begin
    ResStr[i]:= TPortWorkChar(SNumber and c_ByteBits);
    SNumber:= SNumber shr cByteBitCount;
  End;
  NumberToStringBigEndian:= ResStr;
end;

    // Запис числа у рядок за правилом LittleEndian (молодші байти першими):
function NumberToStringLittleEndian(SNumber:Cardinal;
           SBytesCount:Byte):TPortWorkString;
var ResStr:TPortWorkString; i:Byte;
begin
  System.Setlength(ResStr, SBytesCount);
  for i := 1 to SBytesCount do
  Begin
    ResStr[i]:= TPortWorkChar(SNumber and c_ByteBits);
    SNumber:= SNumber shr cByteBitCount;
  End;
  NumberToStringLittleEndian:= ResStr;
end;

function NumberToString(SNumber:Cardinal;
           SBytesCount:Byte; sLittleEndian:Boolean = True):TPortWorkString; overload;
Begin
  if sLittleEndian then
    Result:= NumberToStringLittleEndian(SNumber, SBytesCount)
  Else
    Result:= NumberToStringBigEndian(SNumber, SBytesCount);
End;

    // Запис дійсних чисел в рядок:
function NumberToString(Const SNumber:Single;
           sLittleEndian:Boolean = True):TPortWorkString; overload;
Begin
  Result:= BufToString(SNumber, DivWithReserve(SizeOf(SNumber), SizeOf(TPortWorkChar)),
    sLittleEndian);
End;
function NumberToString(Const SNumber:Double;
           sLittleEndian:Boolean = True):TPortWorkString; overload;
Begin
  Result:= BufToString(SNumber, DivWithReserve(SizeOf(SNumber), SizeOf(TPortWorkChar)),
    sLittleEndian);
End;
function NumberToString(Const SNumber:Extended;
           sLittleEndian:Boolean = True):TPortWorkString; overload;
Begin
  Result:= BufToString(SNumber, DivWithReserve(SizeOf(SNumber), SizeOf(TPortWorkChar)),
    sLittleEndian);
End;

function StringBigEndianToNumber(SString:TPortWorkString; sMaxBytesCount:Byte=SizeOf(Cardinal)):Cardinal;
var cNumber: Cardinal; i, cLength:Integer;
Begin
    // Читаємо число із рядка:
  cLength:= System.Length(SString);
    // Якщо рядок довший за ту довжину в яку вміщається потрібне число, то ігноруємо зайві символи...:
  if cLength > sMaxBytesCount then cLength:= sMaxBytesCount;

  cNumber:= 0;
  for i := 1 to cLength do
  begin
    cNumber:= cNumber shl cByteBitCount;
    cNumber:= cNumber or System.Ord(SString[i]);
  end;
  StringBigEndianToNumber:= cNumber;
End;

function StringLittleEndianToNumber(SString:TPortWorkString; sMaxBytesCount:Byte=SizeOf(Cardinal)):Cardinal;
var cNumber: Cardinal; i, cLength:Integer;
Begin
    // Читаємо число із рядка:
  cLength:= System.Length(SString);
    // Якщо рядок довший за ту довжину в яку вміщається потрібне число, то ігноруємо зайві символи...:
  if cLength > sMaxBytesCount then cLength:= sMaxBytesCount;

  cNumber:= 0;
  for i := cLength downto 1 do
  begin
    cNumber:= cNumber shl cByteBitCount;
    cNumber:= cNumber or System.Ord(SString[i]);
  end;
  StringLittleEndianToNumber:= cNumber;
End;

function StringToNumber(SString:TPortWorkString;
  sMaxBytesCount:Byte=SizeOf(Cardinal); sLittleEndian:Boolean = True):Cardinal;
Begin
  if sLittleEndian then
    Result:= StringLittleEndianToNumber(SString, sMaxBytesCount)
  Else
    Result:= StringBigEndianToNumber(SString, sMaxBytesCount);
End;

Procedure StringToNumber(Const SString:TPortWorkString; Var dNum:Single;
  sLittleEndian:Boolean = True); overload;
Var ccString: TPortWorkString; MaxLength:Integer;
Begin
  ccString:= SString;
  MaxLength:= DivWithReserve(SizeOf(dNum), SizeOf(TPortWorkChar));
  if MaxLength < System.Length(ccString) then  // рядок надто довгий, обрізаємо...:
    ccString:= System.Copy(ccString, 1, MaxLength);

  StringToBuf(SString, dNum, sLittleEndian);
End;
Procedure StringToNumber(Const SString:TPortWorkString; Var dNum:Double;
  sLittleEndian:Boolean = True); overload;
Var ccString: TPortWorkString; MaxLength:Integer;
Begin
  ccString:= SString;
  MaxLength:= DivWithReserve(SizeOf(dNum), SizeOf(TPortWorkChar));
  if MaxLength < System.Length(ccString) then  // рядок надто довгий, обрізаємо...:
    ccString:= System.Copy(ccString, 1, MaxLength);

  StringToBuf(SString, dNum, sLittleEndian);
End;
Procedure StringToNumber(Const SString:TPortWorkString; Var dNum:Extended;
  sLittleEndian:Boolean = True); overload;
Var ccString: TPortWorkString; MaxLength:Integer;
Begin
  ccString:= SString;
  MaxLength:= DivWithReserve(SizeOf(dNum), SizeOf(TPortWorkChar));
  if MaxLength < System.Length(ccString) then  // рядок надто довгий, обрізаємо...:
    ccString:= System.Copy(ccString, 1, MaxLength);

  StringToBuf(SString, dNum, sLittleEndian);
End;

function CutSubString(sString:TPortWorkString; sStart, SCount:Integer;
           Var dRemainedString: TPortWorkString):TPortWorkString;
Begin
  Result:= System.Copy(sString, sStart, SCount);
  dRemainedString:= System.Copy(sString, 1, sStart-1)+
    System.Copy(sString, sStart + SCount,
      System.Length(sString) - sStart - SCount + 1);
End;

   //   Відкушує частину рядка від його початку до заданого рядка-суфікса.
   //   Повертає відкушену частину. у dRemainedString повертає частину, що
   // лишилася (кінець рядка).
   //   sLeaveSuffixInRemainedString - лишити знайдений суфікс у dRemainedString;
   //   sPutSuffixToCuttedPart - відкусити разом із суфіксом;
   //   При sLeaveSuffixInRemainedString = False і sPutSuffixToCuttedPart = False
   // знайдений суфікс відкидаєтсья (не лишається у рядках).
function CutFromStartToSuffix(sString, sSuffix:TPortWorkString;
           Var dRemainedString: TPortWorkString;
           sLeaveSuffixInRemainedString:Boolean = False;
           sPutSuffixToCuttedPart:Boolean = False):TPortWorkString;
Var cSuffixPos, cAfterSuffixEndPos, cSuffixLen, cStrLen: Integer;
Begin
  cSuffixLen:= System.Length(sSuffix);
  cStrLen:= System.Length(sString);

  if cSuffixLen = 0 then
    cSuffixPos:= 0
  else cSuffixPos:= System.Pos(sSuffix, sString);

  cAfterSuffixEndPos:= cSuffixPos + cSuffixLen;

  if cSuffixPos > 0 then
  Begin
    if sLeaveSuffixInRemainedString then
      dRemainedString:= System.Copy(sString, cSuffixPos,
        cStrLen - cSuffixPos + 1)
    else dRemainedString:= System.Copy(sString, cAfterSuffixEndPos,
        cStrLen - cAfterSuffixEndPos + 1);

    if sPutSuffixToCuttedPart then
      Result:= System.Copy(sString, 1, cAfterSuffixEndPos - 1)
    else Result:= System.Copy(sString, 1, cSuffixPos - 1);
  End
  Else  // якщо суфікс не знайдений - нічого не відкушуємо:
  Begin
    dRemainedString:=sString;
    Result:='';
  End;
End;

function CutFromPosToSuffix(Const sString, sSuffix:TPortWorkString;
           Var sdPos: Integer;
           sLeaveSuffixInRemainedString:Boolean = False;
           sPutSuffixToCuttedPart:Boolean = False):TPortWorkString;
Var cSuffixPos, cAfterSuffixEndPos, cSuffixLen: Integer; //, cStrLen
Begin
  cSuffixLen:= System.Length(sSuffix);
  //cStrLen:= System.Length(sString);

  if cSuffixLen = 0 then
    cSuffixPos:= 0
  else cSuffixPos:= AnsiStrings.PosEx(sSuffix, sString, sdPos);

  cAfterSuffixEndPos:= cSuffixPos + cSuffixLen;

  if cSuffixPos > 0 then
  Begin
    if sPutSuffixToCuttedPart then
      Result:= System.Copy(sString, sdPos, cAfterSuffixEndPos - sdPos)
    else Result:= System.Copy(sString, sdPos, cSuffixPos - sdPos);

    if sLeaveSuffixInRemainedString then
      sdPos:= cSuffixPos
    else sdPos:= cAfterSuffixEndPos;
  End
  Else  // якщо суфікс не знайдений - нічого не відкушуємо:
  Begin
    //dRemainedString:=sString;
    Result:='';
  End;
End;

Procedure PrepareToCutFromPosToSuffix(Const sString, sSuffix:TPortWorkString;
           sPos: Integer; Var dCuttedLength, dNextPos: Integer;
           sLeaveSuffixInRemainedString:Boolean = False;
           sPutSuffixToCuttedPart:Boolean = False);
Var cSuffixPos, cAfterSuffixEndPos, cSuffixLen: Integer; //, cStrLen
Begin
  cSuffixLen:= System.Length(sSuffix);

  if cSuffixLen = 0 then
    cSuffixPos:= 0
  else cSuffixPos:= AnsiStrings.PosEx(sSuffix, sString, sPos);

  cAfterSuffixEndPos:= cSuffixPos + cSuffixLen;

  if cSuffixPos > 0 then
  Begin
    if sPutSuffixToCuttedPart then
      dCuttedLength:= cAfterSuffixEndPos - sPos
    else dCuttedLength:= cSuffixPos - sPos;

    if sLeaveSuffixInRemainedString then
      dNextPos:= cSuffixPos
    else dNextPos:= cAfterSuffixEndPos;
  End
  Else  // якщо суфікс не знайдений - нічого не відкушуємо:
  Begin
    dCuttedLength:= 0;
    dNextPos:= sPos;
  End;
End;

Procedure PrepareToCutFromPosToSuffix(Const sString, sSuffix:String;
           sPos: Integer; Var dCuttedLength, dNextPos: Integer;
           sLeaveSuffixInRemainedString:Boolean = False;
           sPutSuffixToCuttedPart:Boolean = False);
Var cSuffixPos, cAfterSuffixEndPos, cSuffixLen: Integer;
Begin
  cSuffixLen:= System.Length(sSuffix);

  if cSuffixLen = 0 then
    cSuffixPos:= 0
  else cSuffixPos:= StrUtils.PosEx(sSuffix, sString, sPos);

  cAfterSuffixEndPos:= cSuffixPos + cSuffixLen;

  if cSuffixPos > 0 then
  Begin
    if sPutSuffixToCuttedPart then
      dCuttedLength:= cAfterSuffixEndPos - sPos
    else dCuttedLength:= cSuffixPos - sPos;

    if sLeaveSuffixInRemainedString then
      dNextPos:= cSuffixPos
    else dNextPos:= cAfterSuffixEndPos;
  End
  Else  // якщо суфікс не знайдений - нічого не відкушуємо:
  Begin
    dCuttedLength:= 0;
    dNextPos:= sPos;
  End;
End;

function StringBigEndianToNumberArray(sString:TPortWorkString;
  sBytesInNumber:Byte):TUnsignedIntegerParameters;
Begin
  Result:= StringToNaturalNumberArray(sString,
           sBytesInNumber, False);
End;

function StringToNaturalNumberArray(sString:TPortWorkString;
           sBytesInNumber:Byte; sLittleEndian:Boolean = False):TUnsignedIntegerParameters;
Var cOneNumString:TPortWorkString;
    cNumArray: TUnsignedIntegerParameters;
    cLength, cArrayCount, cElmNum:Cardinal;
Begin
  if sBytesInNumber = 0 then
  Begin
    System.SetLength(cNumArray, 0);
    Result:= cNumArray;
    Exit;
  End;

  cLength:= System.Length(sString);
  cArrayCount:= DivWithReserve(cLength, sBytesInNumber);
  //cArrayCount:= cLength div sBytesInNumber;
  //if (cLength mod sBytesInNumber) > 0 then Inc(cArrayCount);

  System.SetLength(cNumArray, cArrayCount);
  cElmNum:= 0;
  while System.Length(sString)>0 do
  Begin
    cOneNumString:= CutSubString(sString, 1, sBytesInNumber,
           sString);
    cNumArray[cElmNum]:=StringToNumber(cOneNumString, sBytesInNumber,
      sLittleEndian);
    Inc(cElmNum);
  End;

  Result:= cNumArray;
End;

function StringToSingleNumberArray(sString:TPortWorkString;
           sLittleEndian:Boolean = False):TSingleFloatParameters;
Var cOneNumString:TPortWorkString;
    cLength, cArrayCount, cElmNum:Cardinal;
    ccBytesInNumber: Byte;
Begin
  ccBytesInNumber:= SizeOf(Single);
  {if ccBytesInNumber = 0 then
  Begin
    System.SetLength(Result, 0);
    //Result:= cNumArray;
    Exit;
  End;}

  cLength:= System.Length(sString);
  cArrayCount:= DivWithReserve(cLength, ccBytesInNumber);

  System.SetLength(Result, cArrayCount);
  cElmNum:= 0;
  while System.Length(sString)>0 do
  Begin
    cOneNumString:= CutSubString(sString, 1, ccBytesInNumber,
           sString);
    StringToNumber(cOneNumString, Result[cElmNum], sLittleEndian);
    Inc(cElmNum);
  End;

  //Result:= cNumArray;
End;
function StringToDoubleNumberArray(sString:TPortWorkString;
           sLittleEndian:Boolean = False):TDoubleFloatParameters;
Var cOneNumString:TPortWorkString;
    cLength, cArrayCount, cElmNum:Cardinal;
    ccBytesInNumber: Byte;
Begin
  ccBytesInNumber:= SizeOf(Double);

  cLength:= System.Length(sString);
  cArrayCount:= DivWithReserve(cLength, ccBytesInNumber);

  System.SetLength(Result, cArrayCount);
  cElmNum:= 0;
  while System.Length(sString)>0 do
  Begin
    cOneNumString:= CutSubString(sString, 1, ccBytesInNumber,
           sString);
    StringToNumber(cOneNumString, Result[cElmNum], sLittleEndian);
    Inc(cElmNum);
  End;
End;
function StringToExtendedNumberArray(sString:TPortWorkString;
           sLittleEndian:Boolean = False):TExtendedFloatParameters;
Var cOneNumString:TPortWorkString;
    cLength, cArrayCount, cElmNum:Cardinal;
    ccBytesInNumber: Byte;
Begin
  ccBytesInNumber:= SizeOf(Extended);

  cLength:= System.Length(sString);
  cArrayCount:= DivWithReserve(cLength, ccBytesInNumber);

  System.SetLength(Result, cArrayCount);
  cElmNum:= 0;
  while System.Length(sString)>0 do
  Begin
    cOneNumString:= CutSubString(sString, 1, ccBytesInNumber,
           sString);
    StringToNumber(cOneNumString, Result[cElmNum], sLittleEndian);
    Inc(cElmNum);
  End;
End;

function NumberArrayToStringBigEndian(Const sNumbers:TUnsignedIntegerParameters;
  sBytesInNumber:Byte = SizeOf(Cardinal)):TPortWorkString;
Begin
  Result:= NumberArrayToString(sNumbers, sBytesInNumber, False);
End;

function NumberArrayToString(Const sNumbers:TUnsignedIntegerParameters;
  sBytesInNumber:Byte = SizeOf(Cardinal);
  sLittleEndian:Boolean = False):TPortWorkString; overload;
Var cOneNumString, cString:TPortWorkString;
    //cNumArray: TUnsignedIntegerParameters;
    cLength, cArrayCount, cElmNum, cSymbNum:Cardinal;
Begin
  cString:= '';
  if sBytesInNumber = 0 then
  Begin
    Result:= cString;
    Exit;
  End;

  cArrayCount:= System.Length(sNumbers);
  cLength:= cArrayCount * sBytesInNumber;

  System.SetLength(cString, cLength);
  cSymbNum:= 1;

  for cElmNum:= 0 to cArrayCount - 1 do
  Begin
    cOneNumString:= NumberToString(sNumbers[cElmNum], sBytesInNumber,
      sLittleEndian);

    System.Move(cOneNumString[1], cString[cSymbNum], sBytesInNumber);

    cSymbNum:= cSymbNum + sBytesInNumber;
  End;
  Result:= cString;
End;

function NumberArrayToString(Const sNumbers:TSingleFloatParameters;
  sLittleEndian:Boolean = False):TPortWorkString; overload;
Var cOneNumString, cString:TPortWorkString;
    cLength, cArrayCount, cElmNum, cSymbNum:Cardinal;
    ccBytesInNumber:Byte;
Begin
  cString:= '';
  ccBytesInNumber:= SizeOf(Single);

  cArrayCount:= System.Length(sNumbers);
  cLength:= cArrayCount * ccBytesInNumber;

  System.SetLength(cString, cLength);
  cSymbNum:= 1;

  for cElmNum:= 0 to cArrayCount - 1 do
  Begin
    cOneNumString:= NumberToString(sNumbers[cElmNum], sLittleEndian);

    System.Move(cOneNumString[1], cString[cSymbNum], ccBytesInNumber);

    cSymbNum:= cSymbNum + ccBytesInNumber;
  End;
  Result:= cString;
End;
function NumberArrayToString(Const sNumbers:TDoubleFloatParameters;
  sLittleEndian:Boolean = False):TPortWorkString; overload;
Var cOneNumString, cString:TPortWorkString;
    cLength, cArrayCount, cElmNum, cSymbNum:Cardinal;
    ccBytesInNumber:Byte;
Begin
  cString:= '';
  ccBytesInNumber:= SizeOf(Double);

  cArrayCount:= System.Length(sNumbers);
  cLength:= cArrayCount * ccBytesInNumber;

  System.SetLength(cString, cLength);
  cSymbNum:= 1;

  for cElmNum:= 0 to cArrayCount - 1 do
  Begin
    cOneNumString:= NumberToString(sNumbers[cElmNum], sLittleEndian);

    System.Move(cOneNumString[1], cString[cSymbNum], ccBytesInNumber);

    cSymbNum:= cSymbNum + ccBytesInNumber;
  End;
  Result:= cString;
End;
function NumberArrayToString(Const sNumbers:TExtendedFloatParameters;
  sLittleEndian:Boolean = False):TPortWorkString; overload;
Var cOneNumString, cString:TPortWorkString;
    cLength, cArrayCount, cElmNum, cSymbNum:Cardinal;
    ccBytesInNumber:Byte;
Begin
  cString:= '';
  ccBytesInNumber:= SizeOf(Extended);

  cArrayCount:= System.Length(sNumbers);
  cLength:= cArrayCount * ccBytesInNumber;

  System.SetLength(cString, cLength);
  cSymbNum:= 1;

  for cElmNum:= 0 to cArrayCount - 1 do
  Begin
    cOneNumString:= NumberToString(sNumbers[cElmNum], sLittleEndian);

    System.Move(cOneNumString[1], cString[cSymbNum], ccBytesInNumber);

    cSymbNum:= cSymbNum + ccBytesInNumber;
  End;
  Result:= cString;
End;

  // Записує число в рядок у двійковій системі
  // (задом наперед при sBigEndian = False).
function NumberToBitString(sNumber:Cardinal;
  sBytesInNumber:Byte = SizeOf(Cardinal);
  sBigEndian:Boolean = True):TPortWorkString;
Var cString:TPortWorkString; cMask, cBitsInNumber:Cardinal;
    cSymbNum:Cardinal;
Begin
  cString:= '';
  if sBytesInNumber = 0 then
  Begin
    Result:= cString;
    Exit;
  End;

  cBitsInNumber:= sBytesInNumber * cByteBitCount;
  System.SetLength(cString, cBitsInNumber);

  cMask:= 1;  // починаємо із наймолодшого біта

  if sBigEndian then
  Begin  // якщо молодші біти справа, а старші зліва:
    for cSymbNum:= cBitsInNumber downto 1 do
    Begin
      cString[cSymbNum]:= TPortWorkChar(Ord(c_ZeroSymb) +
        Ord((sNumber and cMask) <> 0));

      cMask:= cMask shl 1;
    End;
  End
  else // якщо молодші біти зліва, а старші справа:
  Begin
    for cSymbNum:= 1 to cBitsInNumber do
    Begin
      cString[cSymbNum]:= TPortWorkChar(Ord(c_ZeroSymb) +
        Ord((sNumber and cMask) <> 0));

      cMask:= cMask shl 1;
    End;
  End;
  Result:= cString;
End;

  // Записує рядок у двійковій системі в число.
function BitStringToNumber(sString:TPortWorkString;
  sBytesInNumber:Byte = SizeOf(Cardinal);
  sBigEndian:Boolean = True):Cardinal;
Var cNumber, cMask, cBitsInNumber:Cardinal;
    cSymbNum, cLength:Cardinal;
Begin
  cNumber:= 0;
  if sBytesInNumber = 0 then
  Begin
    Result:= cNumber;
    Exit;
  End  // не підтримується більше за SizeOf(Cardinal) бітів для одного числа...:
  else if sBytesInNumber > SizeOf(Cardinal) then
    sBytesInNumber:= SizeOf(Cardinal);


  cBitsInNumber:= sBytesInNumber * cByteBitCount;
  cLength:= System.Length(sString);
    //   Якщо в рядку насправді менше записано символів (бітів) ніж заявлено...
    // Беремо ті що є:
  if cLength < cBitsInNumber then cBitsInNumber:= cLength;

  //System.SetLength(cString, cBitsInNumber);
  cMask:= 1;  // починаємо із наймолодшого біта

  if sBigEndian then
  Begin  // якщо молодші біти справа, а старші зліва:
    for cSymbNum:= cBitsInNumber downto 1 do
    Begin
      if sString[cSymbNum] <> c_ZeroSymb then
        cNumber:= cNumber or cMask;

      cMask:= cMask shl 1;
    End;
  End
  Else
  Begin
    for cSymbNum:= 1 to cBitsInNumber do
    Begin
      if sString[cSymbNum] <> c_ZeroSymb then
        cNumber:= cNumber or cMask;

      cMask:= cMask shl 1;
    End;
  End;

  Result:= cNumber;
End;

function ConvertToSigned(const sNumber:Cardinal):Integer;
const cc_TestByte = $FF; cc_NegSign = $80;
var ccFirstFillByteNum, ccByteNum:Byte; ccTestNum: Cardinal;
    ccIsNegative: Boolean;
Begin
  ccFirstFillByteNum:= 0;
  ccIsNegative:= False;
  for ccByteNum := SizeOf(sNumber) - 1 downto 0 do
  Begin
    ccTestNum:= sNumber shr (ccByteNum*cByteBitCount);
    ccTestNum:= ccTestNum and cc_TestByte;
    if ccTestNum<>0 then
    Begin
      ccFirstFillByteNum:= ccByteNum;
      ccIsNegative:= (ccTestNum and cc_NegSign) <> 0;
      Break;
    End;
  End;

  ccTestNum:= sNumber;

  if ccIsNegative then
  Begin    // Заповнення всіх бітів, що були за межею розрядності:
    for ccByteNum := ccFirstFillByteNum + 1 to SizeOf(sNumber) - 1 do
    Begin
      ccTestNum:= ccTestNum or (cc_TestByte shl (ccByteNum*cByteBitCount));
    End;
  End;
  Result:= Integer(ccTestNum);
End;


function NumberArrayToCommaSeparatedString(Const sNumbers:TUnsignedIntegerParameters;
  sComma:TPortWorkString = c_Comma; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes;
  s_ConvertToSignedNumbers:Boolean = False):TPortWorkString;
Var cString, cNumberStr:TPortWorkString; cNumCount, cNumPos:Cardinal;
Begin
  cString:= '';
  cNumCount:= System.Length(sNumbers);
  if cNumCount <= 0 then
  Begin
    Result:= cString;
    Exit;
  End;

  for cNumPos := 0 to cNumCount - 1 do
  Begin
    if System.Length(cString) > 0 then
      cNumberStr:= sComma
    else cNumberStr:= '';

    if s_ConvertToSignedNumbers then
      cNumberStr:= cNumberStr + TPortWorkString(SysUtils.IntToStr(ConvertToSigned(sNumbers[cNumPos])))
    else
      cNumberStr:= cNumberStr + TPortWorkString(SysUtils.IntToStr(sNumbers[cNumPos]));

    if sAddPairQuotes then
      cNumberStr:= s_Quotes + cNumberStr + s_Quotes;

    cString:= cString + cNumberStr;
  End;

  Result:= cString;
End;

{function NumberArrayToCommaSeparatedString(Const sNumbers: array of Const;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes):TPortWorkString; overload;
Var cString, cNumberStr:TPortWorkString; cNumCount, cNumPos:Cardinal;
Begin
  cString:= '';
  cNumCount:= System.Length(sNumbers);
  if cNumCount <= 0 then
  Begin
    Result:= cString;
    Exit;
  End;

  for cNumPos := 0 to cNumCount - 1 do
  Begin
    if System.Length(cString) > 0 then
      cNumberStr:= sComma
    else cNumberStr:= '';

    //if s_ConvertToSignedNumbers then
    //  cNumberStr:= cNumberStr + TPortWorkString(SysUtils.IntToStr(Integer(sNumbers[cNumPos])))
    //else
      cNumberStr:= cNumberStr + TPortWorkString(SysUtils.FloatToStr(sNumbers[cNumPos]));

    if sAddPairQuotes then
      cNumberStr:= s_Quotes + cNumberStr + s_Quotes;

    cString:= cString + cNumberStr;
  End;

  Result:= cString;
End;}

function ConvertNumberArrayToExtended(Const sNumbers:TSingleFloatParameters):
  TExtendedFloatParameters; overload;
Var cNumCount, cNumPos:Cardinal;
Begin
  cNumCount:= System.Length(sNumbers);

  System.SetLength(Result, cNumCount);
  for cNumPos := 0 to cNumCount - 1 do
  Begin
    Result[cNumPos]:= sNumbers[cNumPos];
  End;
End;

function ConvertNumberArrayToExtended(Const sNumbers:TDoubleFloatParameters):
  TExtendedFloatParameters; overload;
Var cNumCount, cNumPos:Cardinal;
Begin
  cNumCount:= System.Length(sNumbers);

  System.SetLength(Result, cNumCount);
  for cNumPos := 0 to cNumCount - 1 do
  Begin
    Result[cNumPos]:= sNumbers[cNumPos];
  End;
End;

function ConvertNumberArrayToSingle(Const sNumbers:TExtendedFloatParameters):
  TSingleFloatParameters;
Var cNumCount, cNumPos:Cardinal;
Begin
  cNumCount:= System.Length(sNumbers);

  System.SetLength(Result, cNumCount);
  for cNumPos := 0 to cNumCount - 1 do
  Begin
    Result[cNumPos]:= sNumbers[cNumPos];
  End;
End;

function ConvertNumberArrayToDouble(Const sNumbers:TExtendedFloatParameters):
  TDoubleFloatParameters; overload;
Var cNumCount, cNumPos:Cardinal;
Begin
  cNumCount:= System.Length(sNumbers);

  System.SetLength(Result, cNumCount);
  for cNumPos := 0 to cNumCount - 1 do
  Begin
    Result[cNumPos]:= sNumbers[cNumPos];
  End;
End;

function AsBoolean(Const sValue: OleVariant):Boolean;
Begin
  Case Variants.VarType(sValue) of
     varEmpty: Result:= False;
     varNull: Result:= False;
     varBoolean: Result:= sValue;
     varOleStr, varString, varUString, varStrArg:
      Result:= (SysUtils.Trim(sValue) <> '0');
     Else
      Result:= (sValue <> 0);
  End;
End;

function NumberArrayToCommaSeparatedString(Const sNumbers:TSingleFloatParameters;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes):TPortWorkString; overload;
Var ccExtendedNumbers: TExtendedFloatParameters;
Begin
  ccExtendedNumbers:= ConvertNumberArrayToExtended(sNumbers);

  Result:= NumberArrayToCommaSeparatedString(ccExtendedNumbers,
    sComma, sAddPairQuotes, s_Quotes);
End;
function NumberArrayToCommaSeparatedString(Const sNumbers:TDoubleFloatParameters;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes):TPortWorkString; overload;
Var ccExtendedNumbers: TExtendedFloatParameters;
Begin
  ccExtendedNumbers:= ConvertNumberArrayToExtended(sNumbers);

  Result:= NumberArrayToCommaSeparatedString(ccExtendedNumbers,
    sComma, sAddPairQuotes, s_Quotes);
End;
function NumberArrayToCommaSeparatedString(Const sNumbers:TExtendedFloatParameters;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes):TPortWorkString; overload;
Var cString, cNumberStr:TPortWorkString; cNumCount, cNumPos:Cardinal;
Begin
  cString:= '';
  cNumCount:= System.Length(sNumbers);
  if cNumCount <= 0 then
  Begin
    Result:= cString;
    Exit;
  End;

  for cNumPos := 0 to cNumCount - 1 do
  Begin
    if System.Length(cString) > 0 then
      cNumberStr:= sComma
    else cNumberStr:= '';

    cNumberStr:= cNumberStr +
      TPortWorkString(SysUtils.FloatToStr(sNumbers[cNumPos]));

    if sAddPairQuotes then
      cNumberStr:= s_Quotes + cNumberStr + s_Quotes;

    cString:= cString + cNumberStr;
  End;

  Result:= cString;
End;

Function StringBufToNumbersCommaSeparatedString(sString:TPortWorkString;
           sBytesInNumber:Byte; sFloatNumbers:Boolean = False;
           s_ConvertToSignedNumbers:Boolean = False; // тільки для цілих чисел, float завжди зі знаком
  sLittleEndian:Boolean = False;
  sComma:TPortWorkString = c_Semicolon; sAddPairQuotes:Boolean = False;
  s_Quotes:TPortWorkString = c_Quotes;
  sLogFile:TLogFile = Nil):TPortWorkString;
const sc_ProcName = 'StringBufToNumbersCommaSeparatedString';
//Var ccIntegerNumbers: TUnsignedIntegerParameters;
    //ccExtendedNumbers: TExtendedFloatParameters;
    //ccSingleNumbers: TSingleFloatParameters;
    //ccDoubleNumbers: TDoubleFloatParameters;
Begin
  Result:= '';
  if sFloatNumbers then
  Begin
    Case sBytesInNumber of
      SizeOf(Single):
      Begin
        Result:= NumberArrayToCommaSeparatedString(
          StringToSingleNumberArray(sString, sLittleEndian),
          sComma, sAddPairQuotes, s_Quotes);
      End;
      SizeOf(Double):
      Begin
        Result:= NumberArrayToCommaSeparatedString(
          StringToDoubleNumberArray(sString, sLittleEndian),
          sComma, sAddPairQuotes, s_Quotes);
      End;
      SizeOf(Extended):
      Begin
        Result:= NumberArrayToCommaSeparatedString(
          StringToExtendedNumberArray(sString, sLittleEndian),
          sComma, sAddPairQuotes, s_Quotes);
      End
      Else
      Begin
        if sLogFile<>Nil then
        Begin
          sLogFile.WriteMessage(sc_ProcName+sc_UnknownLengthOfFloatNumber+
            Sysutils.IntToStr(sBytesInNumber)+sc_TriSpot);
        End;
      End;
    End;
  End
  Else
  Begin
    Result:= NumberArrayToCommaSeparatedString(
        StringToNaturalNumberArray(sString, sBytesInNumber, sLittleEndian),
      sComma, sAddPairQuotes, s_Quotes,
      s_ConvertToSignedNumbers);
  End;
End;

function StringArrayToCommaSeparatedString(sStrings:TPortWorkStrings;
  sComma:TPortWorkString = c_Comma; sAddPairQuotes:Boolean = True;
  s_Quotes:TPortWorkString = c_Quotes;
  s_QuotesReplacement:TPortWorkString = c_QuotesReplacement;
  s_CommaReplacement:TPortWorkString = c_CommaReplacement):TPortWorkString;
Var cString, cSubStr:TPortWorkString; cSubStrCount, cSubStrPos:Cardinal;
Begin
  cString:= '';
  cSubStrCount:= System.Length(sStrings);
  if cSubStrCount <= 0 then
  Begin
    Result:= cString;
    Exit;
  End;

  for cSubStrPos := 0 to cSubStrCount - 1 do
  Begin
    cSubStr:= sStrings[cSubStrPos];

      //   Заміняємо амперсенди на службові рядки, щоб вони не були спряйняті як
      // частини службових рядків, що використовуються замість ком в лапок...
      // Це дає можливість вкладати масиви рядків один в одного (робити їх
      // багатовимірними). Для того треба щоб у
      // s_QuotesReplacement і s_CommaReplacement використовувався амперсенд
      // і не був останнім символом. Отже, заміняємо амперсенд:
    if SizeOf(c_Amp) > 0 then
      cSubStr:= AnsiStrings.ReplaceStr(cSubStr, c_Amp, c_AmpReplacement);

      //   Заміняємо у рядку коми і лапки на задані символи
      // (якщо не задані пусті символи):
    if (System.Length(s_QuotesReplacement) > 0)
       and (System.Length(s_Quotes) > 0) then
      cSubStr:= AnsiStrings.ReplaceStr(cSubStr, s_Quotes,
        s_QuotesReplacement);

    if (System.Length(s_CommaReplacement) > 0)
       and (System.Length(sComma) > 0) then
      cSubStr:= AnsiStrings.ReplaceStr(cSubStr, sComma,
        s_CommaReplacement);

    if System.Length(cString) > 0 then
      cSubStr:= sComma + cSubStr;

    if sAddPairQuotes then
      cSubStr:= s_Quotes + cSubStr + s_Quotes;

    cString:= cString + cSubStr;
  End;

  Result:= cString;
End;

function CommaSeparatedNumbersToNumberArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Comma; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TUnsignedIntegerParameters;
Var cNumberStr:TPortWorkString; //cNumCount, cNumPos:Cardinal;
    cNumbers:TUnsignedIntegerParameters; cNumber:Cardinal;
    cNumPos:Cardinal;
      procedure AnalyzeNumber;
      var cNumCount:Cardinal;
      Begin
        cNumberStr:= Trim(cNumberStr);
        try
          cNumber:= Cardinal(SysUtils.StrToInt(String(cNumberStr)));
        except
          cNumber:= High(Cardinal);
          if sLogFile<>Nil then
          Begin
            sLogFile.WriteMessage('CommaSeparatedNumbersToNumberArray: число ['+
              IntToStr(cNumPos) + ']="'+String(cNumberStr)+
              '" не вдалося розпізнати як число... Замінено на '+
              IntToStr(cNumber) + '.');
          End;
        end;

        cNumCount:= System.Length(cNumbers);
        System.SetLength(cNumbers, cNumCount + 1);

        cNumbers[cNumCount]:= cNumber;
      End;
Begin

  System.SetLength(cNumbers, 0);

  if sCheckForQuotes then
    sString:= AnsiStrings.ReplaceStr(sString, s_Quotes, '');

  {if System.Length(sString) <= 0 then
  Begin
    Result:= cNumbers;
    Exit;
  End;}

  cNumPos:= 0;

  if System.Length(sComma) <= 0 then
  Begin
    cNumberStr:= sString;

    AnalyzeNumber;
  End
  Else
  Begin
    while System.Length(sString) > 0 do
    Begin
      cNumberStr:= CutFromStartToSuffix(sString, sComma,
             sString, False, False);

        // Якщо більше ком немає:
      if System.Length(cNumberStr) <= 0 then
      Begin  // беремо рядок, що залишився щоб спробувати розпізнати число:
        cNumberStr:= sString;
        sString:= '';
      End;

      AnalyzeNumber;

      cNumPos:= cNumPos + 1;
    End;
  End;

  Result:= cNumbers;
End;

function CommaSeparatedNumbersToSingleNumberArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Semicolon; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TSingleFloatParameters;
Var ccExtendedNumbers: TExtendedFloatParameters;
Begin
  ccExtendedNumbers:= CommaSeparatedNumbersToExtendedNumberArray(sString,
    sComma, sCheckForQuotes,
    s_Quotes, sLogFile);

  Result:= ConvertNumberArrayToSingle(ccExtendedNumbers);
End;
function CommaSeparatedNumbersToDoubleNumberArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Semicolon; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TDoubleFloatParameters;
Var ccExtendedNumbers: TExtendedFloatParameters;
Begin
  ccExtendedNumbers:= CommaSeparatedNumbersToExtendedNumberArray(sString,
    sComma, sCheckForQuotes,
    s_Quotes, sLogFile);

  Result:= ConvertNumberArrayToDouble(ccExtendedNumbers);
End;
function CommaSeparatedNumbersToExtendedNumberArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Semicolon; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TExtendedFloatParameters;
Const sc_ProcName = 'CommaSeparatedNumbersToExtendedNumberArray';
Var cNumberStr:TPortWorkString;
    //cNumbers:TUnsignedIntegerParameters;
    cNumber:Extended;
    cNumPos:Cardinal;
      procedure AnalyzeNumber;
      var cNumCount:Cardinal;
      Begin
        cNumberStr:= Trim(cNumberStr);
        try
          cNumber:= SysUtils.StrToFloat(String(cNumberStr));
        except
          cNumber:= NAN; // Not A Number // High(Cardinal);
          if sLogFile<>Nil then
          Begin
            sLogFile.WriteMessage(sc_ProcName+': число ['+
              SysUtils.IntToStr(cNumPos) + ']="'+String(cNumberStr)+
              '" не вдалося розпізнати як число... Замінено на '+
              SysUtils.FloatToStr(cNumber) + '.');
          End;
        end;

        cNumCount:= System.Length(Result);
        System.SetLength(Result, cNumCount + 1);

        Result[cNumCount]:= cNumber;
      End;
Begin

  System.SetLength(Result, 0);

  if sCheckForQuotes then
    sString:= AnsiStrings.ReplaceStr(sString, s_Quotes, '');

  {if System.Length(sString) <= 0 then
  Begin
    Result:= Result;
    Exit;
  End;}

  cNumPos:= 0;

  if System.Length(sComma) <= 0 then
  Begin
    cNumberStr:= sString;

    AnalyzeNumber;
  End
  Else
  Begin
    while System.Length(sString) > 0 do
    Begin
      cNumberStr:= CutFromStartToSuffix(sString, sComma,
             sString, False, False);

        // Якщо більше ком немає:
      if System.Length(cNumberStr) <= 0 then
      Begin  // беремо рядок, що залишився щоб спробувати розпізнати число:
        cNumberStr:= sString;
        sString:= '';
      End;

      AnalyzeNumber;

      cNumPos:= cNumPos + 1;
    End;
  End;
End;

Function CommaSeparatedNumbersToStringBuf(sString:TPortWorkString;
    sFloatNumbers:Boolean; sBytesForNumber:Byte;
    sWriteLittleEndian:Boolean = False;
    sComma:TPortWorkString = c_Semicolon; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil):TPortWorkString;
const sc_ProcName = 'CommaSeparatedNumbersToStringBuf';
Begin
  Result:= '';
  if sFloatNumbers then
  Begin
    Case sBytesForNumber of
      SizeOf(Single):
      Begin
        Result:= NumberArrayToString(
          CommaSeparatedNumbersToSingleNumberArray(sString,
            sComma, sCheckForQuotes,
            s_Quotes,
            sLogFile),
          sWriteLittleEndian);
      End;
      SizeOf(Double):
      Begin
        Result:= NumberArrayToString(
          CommaSeparatedNumbersToDoubleNumberArray(sString,
            sComma, sCheckForQuotes,
            s_Quotes,
            sLogFile),
          sWriteLittleEndian);
      End;
      SizeOf(Extended):
      Begin
        Result:= NumberArrayToString(
          CommaSeparatedNumbersToExtendedNumberArray(sString,
            sComma, sCheckForQuotes,
            s_Quotes,
            sLogFile),
          sWriteLittleEndian);
      End
      Else
      Begin
        if sLogFile<>Nil then
        Begin
          sLogFile.WriteMessage(sc_ProcName+sc_UnknownLengthOfFloatNumber+
            Sysutils.IntToStr(sBytesForNumber)+sc_TriSpot);
        End;
      End;
    End;
  End
  Else
  Begin
    Result:= NumberArrayToString(
          CommaSeparatedNumbersToNumberArray(sString,
          sComma, sCheckForQuotes,
          s_Quotes,
          sLogFile),
        sBytesForNumber,
        sWriteLittleEndian);
  End;
End;

function CommaSeparatedStringsToStringArray(sString:TPortWorkString;
    sComma:TPortWorkString = c_Comma; sCheckForQuotes:Boolean = False;
    s_Quotes:TPortWorkString = c_Quotes;
    sLogFile:TLogFile = Nil;  // файл для запису повідомлень про помилки та попереджень (якщо не заданий - повідомлення про помилки передаються як виключення). У цій функції поки що не використовується
    s_QuotesReplacement:TPortWorkString = c_QuotesReplacement;
    s_CommaReplacement:TPortWorkString = c_CommaReplacement):TPortWorkStrings;
Var cSubStr:TPortWorkString; //cNumCount, cNumPos:Cardinal;
    cStrings:TPortWorkStrings;// cNumber:Cardinal;
    //cSubStrPos:Cardinal;
      procedure AddSubString(var cSubStr:TPortWorkString;
        var cStrings:TPortWorkStrings);
      var cSubStrCount:Cardinal;
      Begin
            //   Повертаємо в рядок коми і лапки, що були раніше замінені
            // спецсимволами чи спецрядками:
        if (System.Length(s_CommaReplacement) > 0)
          and (System.Length(sComma) > 0) then
            cSubStr:= AnsiStrings.ReplaceStr(cSubStr, s_CommaReplacement,
              sComma);

        if (System.Length(s_QuotesReplacement) > 0)
          and (System.Length(s_Quotes) > 0) then
            cSubStr:= AnsiStrings.ReplaceStr(cSubStr, s_QuotesReplacement,
              s_Quotes);

          //   Повертаємо на місце амперсенди.
          // Це дасть можливість вкладати масиви рядків один в одного (робити їх
          // багатовимірними), при умові що у
          // s_QuotesReplacement і s_CommaReplacement використовувється амперсенд
          // і не є останнім символом. Отже, повертаємо амперсенд:
        if SizeOf(c_Amp) > 0 then
          cSubStr:= AnsiStrings.ReplaceStr(cSubStr, c_AmpReplacement, c_Amp);
            // Додаємо рядок до масиву:
        cSubStrCount:= System.Length(cStrings);
        System.SetLength(cStrings, cSubStrCount + 1);

        cStrings[cSubStrCount]:= cSubStr;
      End;
Begin

  System.SetLength(cStrings, 0);
    //   За лапками нічого не визначаємо. Сподіваємося на те що коми в рядках
    // були замінені на спецрядки, і тут можна орієнтуватися по
    // комах між рядками. Тому лапки, в які взяті рядки, просто видаляємо:
  if sCheckForQuotes then
    sString:= AnsiStrings.ReplaceStr(sString, s_Quotes, '');

  //cSubStrPos:= 0;

  if System.Length(sComma) <= 0 then
  Begin
    cSubStr:= sString;

    AddSubString(cSubStr, cStrings);
  End
  Else
  Begin
    while System.Length(sString) > 0 do
    Begin
      cSubStr:= CutFromStartToSuffix(sString, sComma,
             sString, False, False);

        // Якщо більше ком немає:
      if System.Length(cSubStr) <= 0 then
      Begin  // беремо рядок, що залишився:
        cSubStr:= sString;
        sString:= '';
      End;

      AddSubString(cSubStr, cStrings);

      //cSubStrPos:= cSubStrPos + 1;
    End;
  End;

  Result:= cStrings;
End;

//   Копіює рядок у запис-буфер (для якого виділяє пам'ять),
// на який повертає вказівник...:
Function CopyStringToBuf(Const Item: TPortWorkString):PBufRec;
Var cBuf:PBufRec; cLength:Integer;
Begin
  cLength:= System.Length(Item);

  System.GetMem(cBuf, SizeOf(TBufRec) + cLength);

  cBuf^.BufLength:= cLength;

  if cLength > 0 then
  Begin
    System.Move(Item[1], cBuf^.Buf[0], cLength);
  End;

  Result:= cBuf;
End;

function CopyMessageAndTimeToBufRec(
    Const Item: TWorkStringAndTimeRecord):PWorkStringAndTimeBufRecord;
Var cBuf:PWorkStringAndTimeBufRecord;
Begin
  System.New(cBuf);
  cBuf^.FTime:= Item.cTime;
  cBuf^.FString:= CopyStringToBuf(Item.cString);

  Result:= cBuf;
End;

Procedure FreeAndNilBuf(Var sBuf:PBufRec);
Begin
  if sBuf <> Nil then
  Begin
    System.FreeMem(sBuf);
    sBuf:= Nil;
  End;
End;

Procedure FreeAndNilMessageAndTimeBufRec(
    Var sBuf:PWorkStringAndTimeBufRecord);
Begin
  if sBuf <> Nil then
  Begin
    FreeAndNilBuf(sBuf^.FString);
    System.Dispose(sBuf);
    sBuf:= Nil;
  End;
End;

Function GetStringFromBuf(sBuf:PBufRec):TPortWorkString;
Var cString:TPortWorkString; cLength:Integer;
Begin
  cString:= '';
  if sBuf <> Nil then
  Begin
    cLength:= sBuf^.BufLength;

    System.SetLength(cString, cLength);

    if cLength > 0 then
    Begin
      System.Move(sBuf^.Buf[0], cString[1], cLength);
    End;
  End;
  Result:= cString;
End;

function GetMessageAndTimeFromBufRec(sBuf:PWorkStringAndTimeBufRecord):TWorkStringAndTimeRecord;
var cRecord: TWorkStringAndTimeRecord;
Begin
  if sBuf <> Nil then
  Begin
    cRecord.cTime:= sBuf^.FTime;
    cRecord.cString:= GetStringFromBuf(sBuf^.FString);
  End
  else
  Begin
    cRecord.cTime:= 0;
    cRecord.cString:= '';
  End;
  Result:= cRecord;
End;

function TWorkStringList.Get(Index: Integer): TPortWorkString;
Begin
  Get:= GetStringFromBuf(Inherited Get(Index));
End;

function TWorkStringAndTimeList.Get(Index: Integer): TWorkStringAndTimeRecord;
Begin
  Get:= GetMessageAndTimeFromBufRec(Inherited Get(Index));
End;

procedure TWorkStringList.Put(Index: Integer; Const Item: TPortWorkString);
Begin
  Inherited Put(Index, CopyStringToBuf(Item));
End;

procedure TWorkStringAndTimeList.Put(Index: Integer; Const Item: TWorkStringAndTimeRecord);
Begin
  Inherited Put(Index, CopyMessageAndTimeToBufRec(Item));
End;

procedure TWorkStringList.Notify(Ptr: Pointer; Action: TListNotification);
Begin
End;

procedure TWorkStringAndTimeList.Notify(Ptr: Pointer; Action: TListNotification);
Begin
End;

//destructor Destroy; override;
function TWorkStringList.Add(Const Item: TPortWorkString): Integer;
Begin
  Add:= Inherited Add(CopyStringToBuf(Item));
End;

function TWorkStringAndTimeList.Add(Const Item: TWorkStringAndTimeRecord): Integer;
Begin
  Add:= Inherited Add(CopyMessageAndTimeToBufRec(Item));
End;

function TWorkStringAndTimeList.Add(Const sTime:TDateTime;
          Const sString: TPortWorkString): Integer;
Var cItem: TWorkStringAndTimeRecord;
Begin
  cItem.cTime:= sTime;
  cItem.cString:= sString;
  Result:= Self.Add(cItem);
End;
//procedure Clear; override;
//procedure TWorkStringList.Delete(Index: Integer);
//Begin
//
//End;

//function Extract(Const Item: TPortWorkString): Pointer;
function TWorkStringList.ExtractByNum(Index: Integer): TPortWorkString;
Var cItem:PBufRec;
Begin
  cItem:= Inherited Get(Index);

  Result:= GetStringFromBuf(cItem);

  Self.List^[Index]:=Nil;
  Inherited Delete(Index);
  Self.Notify(cItem, Classes.lnExtracted);

  FreeAndNilBuf(cItem);
End;

function TWorkStringAndTimeList.ExtractByNum(Index: Integer): TWorkStringAndTimeRecord;
Var cItem:PWorkStringAndTimeBufRecord;
Begin
  cItem:= Inherited Get(Index);

  Result:= GetMessageAndTimeFromBufRec(cItem);

  Self.List^[Index]:=Nil;
  Inherited Delete(Index);
  Self.Notify(cItem, Classes.lnExtracted);

  FreeAndNilMessageAndTimeBufRec(cItem);
End;

function TWorkStringList.Extract(Const Item: TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): TPortWorkString;
Var cIndex: Integer;
Begin
  cIndex:= Self.IndexOf(Item, sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive, sSpace);
  if cIndex >= 0 then
    Result:= Self.ExtractByNum(cIndex)
  Else Result:= '';
End;

function TWorkStringAndTimeList.Extract(Const Item: TWorkStringAndTimeRecord;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): TWorkStringAndTimeRecord;
Var cIndex: Integer;
Begin
  cIndex:= Self.IndexOf(Item, sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive, sSpace);
  if cIndex >= 0 then
    Result:= Self.ExtractByNum(cIndex)
  Else
  Begin
    Result.cTime:= 0;
    Result.cString:= '';
  End;
End;

function TWorkStringAndTimeList.Extract(Const sTime:TDateTime;
            Const sString: TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): TWorkStringAndTimeRecord;
Var cItem: TWorkStringAndTimeRecord;
Begin
  cItem.cTime:= sTime;
  cItem.cString:= sString;

  Result:= Self.Extract(cItem, sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive,
            sSpace);
End;

procedure TWorkStringList.Delete(Index: Integer);
Var cItem:PBufRec;
Begin
  cItem:= Inherited Get(Index);

  Self.List^[Index]:=Nil;
  Inherited Delete(Index);

  if cItem <> Nil then
  Begin
    Self.Notify(cItem, Classes.lnDeleted);

    FreeAndNilBuf(cItem);
  End;
End;

procedure TWorkStringAndTimeList.Delete(Index: Integer);
Var cItem:PWorkStringAndTimeBufRecord;
Begin
  cItem:= Inherited Get(Index);

  Self.List^[Index]:=Nil;
  Inherited Delete(Index);

  if cItem <> Nil then
  Begin
    Self.Notify(cItem, Classes.lnDeleted);

    FreeAndNilMessageAndTimeBufRec(cItem);
  End;
End;

function TWorkStringList.Remove(Item: TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): Integer;
Begin
  Result := IndexOf(Item, sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive,
            sSpace);
  if Result >= 0 then
    Self.Delete(Result);
End;

function TWorkStringAndTimeList.Remove(Item: TWorkStringAndTimeRecord;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): Integer;
Begin
  Result := IndexOf(Item, sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive,
            sSpace);
  if Result >= 0 then
    Self.Delete(Result);
End;

procedure TWorkStringList.Clear;
Begin
    // Перед очисткою списка звільняємо пам'ять від усіх рядків, що у ньому:
  while Self.Count > 0 do
    Self.Delete(0);

  Inherited Clear;
End;

procedure TWorkStringAndTimeList.Clear;
Begin
    // Перед очисткою списка звільняємо пам'ять від усіх записів, що у ньому:
  while Self.Count > 0 do
    Self.Delete(0);

  Inherited Clear;
End;

function TWorkStringList.First: TPortWorkString;
Begin
  First:= GetStringFromBuf(Inherited First);
End;

function TWorkStringAndTimeList.First: TWorkStringAndTimeRecord;
Begin
  First:= GetMessageAndTimeFromBufRec(Inherited First);
End;

procedure TWorkStringAndTimeList.First(
    Var dTime:TDateTime; Var dString: TPortWorkString);
Var cItem: TWorkStringAndTimeRecord;
Begin
   cItem:= Self.First;
   dTime:= cItem.cTime;
   dString:= cItem.cString;
End;

function TWorkStringList.ExtractFirst: TPortWorkString;
Begin
  ExtractFirst:= Self.ExtractByNum(0);
End;

function TWorkStringAndTimeList.ExtractFirst: TWorkStringAndTimeRecord;
Begin
  ExtractFirst:= Self.ExtractByNum(0);
End;

procedure TWorkStringAndTimeList.ExtractFirst(
  Var dTime:TDateTime; Var dString: TPortWorkString);
Var cItem: TWorkStringAndTimeRecord;
Begin
  cItem:= Self.ExtractFirst;
  dTime:= cItem.cTime;
  dString:= cItem.cString;
End;

procedure TWorkStringList.Insert(Index: Integer; Const Item: TPortWorkString);
Begin
  Inherited Insert(Index, CopyStringToBuf(Item));
End;

procedure TWorkStringAndTimeList.Insert(Index: Integer;
    Const Item: TWorkStringAndTimeRecord);
Begin
  Inherited Insert(Index, CopyMessageAndTimeToBufRec(Item));
End;

procedure TWorkStringAndTimeList.Insert(Index: Integer;
          Const sTime:TDateTime; Const sString: TPortWorkString);
Var cItem: TWorkStringAndTimeRecord;
Begin
  cItem.cTime:= sTime;
  cItem.cString:= sString;
  Self.Insert(Index, cItem);
End;

function TWorkStringList.Last: TPortWorkString;
Begin
  Last:= GetStringFromBuf(Inherited Last);
End;

function TWorkStringAndTimeList.Last: TWorkStringAndTimeRecord;
Begin
  Last:= GetMessageAndTimeFromBufRec(Inherited Last);
End;

procedure TWorkStringAndTimeList.Last(Var dTime:TDateTime; Var dString: TPortWorkString);
Var cItem: TWorkStringAndTimeRecord;
Begin
  cItem:= Self.Last;
  dTime:= cItem.cTime;
  dString:= cItem.cString;
End;

function TWorkStringList.ExtractLast: TPortWorkString;
Begin
  ExtractLast:= Self.ExtractByNum(Self.Count - 1);
End;

function TWorkStringAndTimeList.ExtractLast: TWorkStringAndTimeRecord;
Begin
  ExtractLast:= Self.ExtractByNum(Self.Count - 1);
End;

procedure TWorkStringAndTimeList.ExtractLast(Var dTime:TDateTime; Var dString: TPortWorkString);
Var cItem: TWorkStringAndTimeRecord;
Begin
  cItem:= Self.ExtractLast;
  dTime:= cItem.cTime;
  dString:= cItem.cString;
End;

Function PrepareStringToCompare(Const sString:TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space):TPortWorkString;
Var cString:TPortWorkString;
Begin
  cString:= sString;
  if (Not(sEndSpaceSensitive)) and sSpaceSensitive then
  Begin
    cString:= Trim(cString, sSpace, False);
  End;

  if Not(sSpaceSensitive) then
  Begin
    cString:= AnsiStrings.ReplaceStr(cString, sSpace, '');
  End;

  if Not(sCaseSensitive) then
  Begin
    cString:= TPortWorkString(SysUtils.AnsiLowerCase(String(cString)));
  End;
  Result:= cString;
End;

             // Виконує пошук рядка у списку...:
function TWorkStringList.IndexOf(Const Item: TPortWorkString;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): Integer;
var
  LCount: Integer;
  //LList: PPointerList;
  //cBuf:PBufRec;
  cString, cSourceString: TPortWorkString;
begin
  LCount := Self.Count;
  //LList := Self.List;

  cSourceString:= PrepareStringToCompare(Item,
            sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive,
            sSpace);

  for Result := 0 to LCount - 1 do // new optimizer doesn't use [esp] for Result
  Begin
    cString:= Self.Get(Result);

    //Self.ExtractByNum(Result);
    cString:= PrepareStringToCompare(cString,
            sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive,
            sSpace);

    if cString = cSourceString then Exit;
  End;

  Result := -1;
end;

function TWorkStringAndTimeList.IndexOf(Const Item: TWorkStringAndTimeRecord;
            sCaseSensitive:Boolean = True;
            sEndSpaceSensitive:Boolean = True;
            sSpaceSensitive:Boolean = True;
            sSpace:TPortWorkString = c_Space): Integer;
var
  LCount: Integer;
  cItem, cSourceItem: TWorkStringAndTimeRecord;
Begin
  LCount := Self.Count;

  cSourceItem.cTime:= Item.cTime;
  cSourceItem.cString:= PrepareStringToCompare(Item.cString,
            sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive,
            sSpace);

  for Result := 0 to LCount - 1 do // new optimizer doesn't use [esp] for Result
  Begin
    cItem:= Self.Get(Result); // Self.ExtractByNum(Result);

    if cItem.cTime = cSourceItem.cTime then
    Begin
      cItem.cString:= PrepareStringToCompare(cItem.cString,
            sCaseSensitive,
            sEndSpaceSensitive,
            sSpaceSensitive,
            sSpace);

      if cItem.cString = cSourceItem.cString then Exit;
    End;
  End;

  Result := -1;
End;

Constructor TCustomTextFile.Create(UseCriticalSection:Boolean = True);
Begin
  Inherited Create;

  //Self.cFile:= Nil;
  Self.cOpened:= False;
  Self.cFilePath:= '';

  if UseCriticalSection then
    Self.cFileCriticalSection:= SyncObjs.TCriticalSection.Create
  else Self.cFileCriticalSection:= Nil;
End;

Constructor TReadingTextFile.Create(UseCriticalSection:Boolean = True);
Begin
  Inherited Create(UseCriticalSection);
End;

Constructor TLogFile.Create(UseCriticalSection:Boolean = True;
    sMessageRepeatChecking:Boolean = True;
    sHideMessageWhenRepeatedMoreThan: Cardinal = c_HideMessageWhenRepeatedMoreThan);
Begin
  Inherited Create(UseCriticalSection);

  Self.cLastLogLine:= '';
  Self.cLastLogTime:= 0;

  Self.cLineRepeatCount:= 0;

  Self.cMessageRepeatChecking:= sMessageRepeatChecking;
  Self.cHideMessageWhenRepeatedMoreThan:= sHideMessageWhenRepeatedMoreThan;
End;

Procedure GetFileNumAndExtAndPathWithPureName(Const sPath: String;
   Var dPath, dExt:String; Var dFileNum:Integer);
Var cExt, cPathWithNoExtAndNumber, cPathWithNoExt, cFileNumStr:String;
    cFileNumLen, cFileNum: Integer;
Begin
  cExt:=SysUtils.ExtractFileExt(sPath);
  cPathWithNoExt:= System.Copy(sPath, 1, System.Length(sPath)-
            System.Length(cExt));
  cPathWithNoExtAndNumber:= cPathWithNoExt;

  cFileNumStr:= SysUtils.ExtractFileExt(cPathWithNoExtAndNumber);

  cFileNumLen:= System.Length(cFileNumStr);
  if cFileNumLen>0 then
  Begin    // якщо ще є "підрозширення":
      // Відкидаємо його із шляху і отримуємо шлях із "голим" (без номера) іменем файла...:
    cPathWithNoExtAndNumber:= System.Copy(cPathWithNoExtAndNumber, 1,
      System.Length(cPathWithNoExt) - cFileNumLen);
      // відкидаємо розділовий знак, який повертає ExtractFileExt:
    cFileNumStr:= System.Copy(cFileNumStr, 1 + System.Length(c_Dot),
      cFileNumLen);
  End;

  cFileNumStr:= SysUtils.Trim(cFileNumStr);
  cFileNum:= c_FirstLogFileNum;

  if Not(cFileNumStr = '') then
  Begin
    try
      cFileNum:= StrToInt(cFileNumStr);
    except
      cFileNum:= c_FirstLogFileNum;
      cPathWithNoExtAndNumber:= cPathWithNoExt;
    end;
  End;

  dPath:= cPathWithNoExtAndNumber;
  dExt:= cExt;

  dFileNum:= cFileNum;
End;

Procedure TReadingTextFile.Open(Const sPath:String);
Var cPath, cPathWithNoExt, cExt:String; // cFileExists:Boolean;
Begin
  cPathWithNoExt:= '';
  cExt:= '';

  Self.ProcEnterCriticalSection;

  try
      //   Закриваємо перед повторним відкриванням. Тут буде повторний вхід
      // до cFileCriticalSection, і вихід... але це не блокує і не губить нічого,
      // головне щоб кількість виходів була рівна кількості входів... Windows Api каже:
      //   After a thread has ownership of a critical section,
      // it can make additional calls to EnterCriticalSection or
      // TryEnterCriticalSection without blocking its execution. This prevents
      // a thread from deadlocking itself while waiting for a critical section
      // that it already owns. The thread enters the critical section
      // each time EnterCriticalSection and TryEnterCriticalSection succeed.
      // A thread must call LeaveCriticalSection once for each time that it
      // entered the critical section.
    if Self.cOpened then Self.Close;

    if Not(Self.cOpened) then  // якщо файл не відкрили в іншому потоці поки тут чекали критичну секцію...:
    Begin
      System.FileMode:= 0; // O_RDONLY. Кажуть, що для текстових файлів це можна не задавати... вони всеодно читаються тільки в режимі "тільки читання"...

      if sPath = '' then cPath:= Self.cFilePath
        else cPath:= sPath;

      //cFileExists:= SysUtils.FileExists(cPath);


      System.AssignFile(Self.cFile, cPath);

      try
        System.Reset(Self.cFile);
        Self.cOpened:= True;
      except
        on E:Exception do
        Begin
          Self.cOpened:= False;

          Raise Exception.Create('Не удалось открыть для чтения файл"'+
            cPath + '"... Система сообщила: '+
            E.Message);
        End;
      end;

      if Self.cOpened then Self.cFilePath:= cPath;
    End;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

Function TReadingTextFile.ReOpenFromStart:Boolean;
Begin
  if Self.Opened then
  Begin
    Self.Close;
    Self.Open(Self.cFilePath);
    Result:= True;
  End
  Else Result:=False;
End;

Function TReadingTextFile.EOF:Boolean;
Begin
  if Self.Opened then
    Result:=System.Eof(Self.cFile)
  else Result:= True;
End;

Function TReadingTextFile.EOLn:Boolean;
Begin
  if Self.Opened then
    Result:= System.Eoln(Self.cFile)
  Else Result:= True;
End;

Function TReadingTextFile.SeekEOF:Boolean;
Begin
  if Self.Opened then
    Result:= System.SeekEof(Self.cFile)
  Else Result:= True;
End;

Function TReadingTextFile.SeekEOln:Boolean;
Begin
  if Self.Opened then
    Result:= System.SeekEoln(Self.cFile)
  Else Result:= True;
End;

Procedure TLogFile.Open(Const sPath:String);
Var cFileExists:Boolean; cPath, cPathWithNoExt, cExt:String;
Var cFileNum:Integer;
Begin
  cPathWithNoExt:= '';
  cExt:= '';
  cFileNum:= 0;

  Self.ProcEnterCriticalSection;

  try
      //   Закриваємо перед повторним відкриванням. Тут буде повторний вхід
      // до cFileCriticalSection, і вихід... але це не блокує і не губить нічого,
      // головне щоб кількість виходів була рівна кількості входів... Windows Api каже:
      //   After a thread has ownership of a critical section,
      // it can make additional calls to EnterCriticalSection or
      // TryEnterCriticalSection without blocking its execution. This prevents
      // a thread from deadlocking itself while waiting for a critical section
      // that it already owns. The thread enters the critical section
      // each time EnterCriticalSection and TryEnterCriticalSection succeed.
      // A thread must call LeaveCriticalSection once for each time that it
      // entered the critical section.
    if Self.cOpened then Self.Close;

    if Not(Self.cOpened) then  // якщо файл не відкрили в іншому потоці поки тут чекали критичну секцію...:
    Begin
      System.FileMode:= 2; // read/write

      if sPath = '' then cPath:= Self.cFilePath
        else cPath:= sPath;

      cFileExists:= SysUtils.FileExists(cPath);

      While cFileExists do
      Begin
        System.AssignFile(Self.cFile, cPath);

        try
          System.Append(Self.cFile);
          Self.cOpened:= True;
        except
          Self.cOpened:= False;
        end;

        if Not(Self.cOpened) then // можливо файл уже відкритий, монопольно
        Begin  // Читаємо розширення і номер файла, беремо наступний номер:
          if cPathWithNoExt = '' then
            GetFileNumAndExtAndPathWithPureName(cPath,
              cPathWithNoExt, cExt, cFileNum);

          Inc(cFileNum);

          cPath:= cPathWithNoExt + c_Dot + IntToStr(cFileNum) + cExt;

          cFileExists:= SysUtils.FileExists(cPath);
        End
        Else Break;
      End;

      if Not(Self.cOpened) then
      Begin
        System.AssignFile(Self.cFile, cPath);

        try
          System.Rewrite(Self.cFile);
          Self.cOpened:= True;
        except
          Self.cOpened:= False;
        end;
      End;

      if Self.cOpened then
        Self.cFilePath:= cPath
      else
      Begin
        Raise Exception.Create('Не удалось открыть или создать файл"'+
            cPath + '"...');
      End;
    End;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

Function AddTimeStampToMessage(Const sMessage:String;
          Const sTime:TDateTime):String;
Begin
  Result:= SysUtils.DateTimeToStr(sTime) + c_Space + sMessage;
End;

procedure TLogFile.ProcLogRepeating(Const sTimeToWrite:TDateTime);
Var cMessage:String;
Begin
    // Критичну секцію тут не чіпаємо, це приватна процедура і в неї мали вже зайти...
  if Self.cLineRepeatCount > 0 then
  Begin
    cMessage:= AddTimeStampToMessage('Повідомлення повторилося '+
      IntToStr(Self.cLineRepeatCount)+' разів, останній раз о '+
      SysUtils.DateTimeToStr(Self.cLastLogTime)+': "'+
      Self.cLastLogLine+'"...', sTimeToWrite);

    Self.ProcWriteMessage(cMessage);
  End;
End;

procedure TLogFile.ProcWriteMessage(Const sMessage:String;
        sFinishLine:Boolean = True);
Begin
    // Критичну секцію тут не чіпаємо, це приватна процедура і в секцію мали вже зайти...
  if Not(Self.cOpened) then
  Begin
    Raise Exception.Create('Не удалось записать в файл журнала "'+
        Self.cFilePath+'", потому что он не открыт... Сообщение было "'+
      sMessage + '".');
  End;

  if sFinishLine then
    System.Writeln(Self.cFile, sMessage)
  else System.Write(Self.cFile, sMessage);
End;

Function TReadingTextFile.ProcReadLine:String;
Begin
    // Критичну секцію тут не чіпаємо, це приватна процедура і в секцію мали вже зайти...
  if Not(Self.cOpened) then
  Begin
    Raise Exception.Create('Не удалось прочитать строку из файла "'+
      Self.cFilePath+'", потому что он не открыт...');
  End;

  System.Readln(Self.cFile, Result);
End;

Function TReadingTextFile.ReadLine:String;
Begin
  Self.ProcEnterCriticalSection;
  try
    Result:= Self.ProcReadLine;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

Procedure TLogFile.WriteMessage(Const sMessage:String;
        sFinishLine:Boolean = True; sAddTimeStamp:Boolean = True);
Var cMessage:String; // cFormatSet:TFormatSettings;
    cTime:TDateTime;
    cDoNotHide:Boolean;
Begin
  Self.ProcEnterCriticalSection;
  try
    cTime:= SysUtils.Now;

    cDoNotHide:= True;

    if Self.cMessageRepeatChecking then
    Begin
      if sMessage = Self.cLastLogLine then
      Begin
        Inc(Self.cLineRepeatCount);
        cDoNotHide:= Not(Self.cLineRepeatCount > Self.cHideMessageWhenRepeatedMoreThan);
      End
      else // якщо повідомлення відрізняється від попереднього:
      Begin
        Self.ProcLogRepeating(cTime);
        Self.cLineRepeatCount:= 0;
      End;
    End;


    Self.cLastLogTime:= cTime;

    if cDoNotHide then
    Begin
      Self.cLastLogLine:= sMessage;

         // Додаємо до повідомлення поточну дату і час щоб бачити час всіх подій, про які повідомляється:
      if sAddTimeStamp then
        cMessage:= AddTimeStampToMessage(sMessage, cTime)
      Else cMessage:= sMessage;

      Self.ProcWriteMessage(cMessage, sFinishLine);
    End;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

function TLogFile.GetLastLogLine: String;
Begin
  Self.ProcEnterCriticalSection;
  try
    GetLastLogLine:= AddTimeStampToMessage(Self.cLastLogLine, Self.cLastLogTime);
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

function TLogFile.GetLastLogLineNoTimeStamp: String;
Begin
  Self.ProcEnterCriticalSection;
  try
    GetLastLogLineNoTimeStamp:= Self.cLastLogLine;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

function TLogFile.GetLastLogTime: TDateTime;
Begin
  Self.ProcEnterCriticalSection;
  try
    GetLastLogTime:= Self.cLastLogTime;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

Procedure TCustomTextFile.ProcEnterCriticalSection;
Begin
  if Self.cFileCriticalSection<>Nil then
    Self.cFileCriticalSection.Enter;
End;

Procedure TCustomTextFile.ProcLeaveCriticalSection;
Begin
  if Self.cFileCriticalSection<>Nil then
    Self.cFileCriticalSection.Leave;
End;

Procedure TLogFile.SetMessageRepeatChecking(Value: Boolean);
Begin
  Self.ProcEnterCriticalSection;

  try
    Self.cMessageRepeatChecking:= Value;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

Procedure TLogFile.SetHideMessageWhenRepeatedMoreThan(Value: Cardinal);
Begin
  Self.ProcEnterCriticalSection;

  try
    Self.cHideMessageWhenRepeatedMoreThan:= Value;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

Procedure TCustomTextFile.Close;
Begin
  Self.ProcEnterCriticalSection;

  try
    if Self.cOpened then
    Begin
      System.CloseFile(Self.cFile);
      //Self.cFile := Nil;
      Self.cOpened := False;
    End;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

Procedure TLogFile.Close;
Begin
  Self.ProcEnterCriticalSection;

  try
    if Self.cOpened then
    Begin
        // Якщо повторювалися повідомлення - то пишемо про це перед тим як закрити файл..:
      Self.ProcLogRepeating(SysUtils.Now);

      System.Flush(Self.cFile);

      Inherited Close;
    End;
  finally
    Self.ProcLeaveCriticalSection;
  end;
End;

Destructor TCustomTextFile.Destroy;
Begin
  Self.Close;

  if Self.cFileCriticalSection<>Nil then
    SysUtils.FreeAndNil(Self.cFileCriticalSection);
  Inherited Destroy;
End;


Function ReadCardinalFromTList(sPnt:PCardinal):Cardinal;
Begin
  Result:= sPnt^;
End;

Function WriteCardinalToTList(sValue:Cardinal):PCardinal;
Begin
  //Result:= Nil;
  System.New(Result);
  Result^:= sValue;
End;

Procedure FreeAndNilCardinal(Var sPnt:PCardinal);
Begin
  if sPnt <> Nil then
  Begin
    System.Dispose(sPnt);
    //System.FreeMem(sBuf);
    sPnt:= Nil;
  End;
End;


procedure TUIntList.Notify(Ptr: Pointer; Action: TListNotification);
Begin

End;

function TUIntList.Get(Index: Integer): Cardinal;
Begin
  Result:= ReadCardinalFromTList(Inherited Get(Index));
End;
procedure TUIntList.Put(Index: Integer; Const Item: Cardinal);
Begin
  Inherited Put(Index, WriteCardinalToTList(Item));
End;

function TUIntList.Add(Const Item: Cardinal): Integer;
Begin
  Add:= Inherited Add(WriteCardinalToTList(Item));
End;
procedure TUIntList.Clear;
Begin
    // Перед очисткою списка звільняємо пам'ять від усіх елементів, що у ньому:
  while Self.Count > 0 do
    Self.Delete(0);

  Inherited Clear;
End;
procedure TUIntList.Delete(Index: Integer);
Var cItem:PCardinal;
Begin
  cItem:= Inherited Get(Index);

  Self.List^[Index]:=Nil;
  Inherited Delete(Index);

  if cItem <> Nil then
  Begin
    Self.Notify(cItem, Classes.lnDeleted);

    FreeAndNilCardinal(cItem);
  End;
End;
function TUIntList.Remove(Item: Cardinal): Integer;
Begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Self.Delete(Result);
End;
function TUIntList.Extract(Const Item: Cardinal): Cardinal;
Var cIndex: Integer;
Begin
  cIndex:= Self.IndexOf(Item);
  if cIndex >= 0 then
    Result:= Self.ExtractByNum(cIndex)
  Else Result:= 0;
End;
function TUIntList.ExtractByNum(Index: Integer): Cardinal;
Var cItem:PCardinal;
Begin
  cItem:= Inherited Get(Index);

  Result:= ReadCardinalFromTList(cItem);

  Self.List^[Index]:=Nil;
  Inherited Delete(Index);
  Self.Notify(cItem, Classes.lnExtracted);

  FreeAndNilCardinal(cItem);
End;
function TUIntList.First: Cardinal;
Begin
  First:= ReadCardinalFromTList(Inherited First);
End;
function TUIntList.ExtractFirst: Cardinal;
Begin
  ExtractFirst:= Self.ExtractByNum(0);
End;
procedure TUIntList.Insert(Index: Integer; Const Item: Cardinal);
Begin
  Inherited Insert(Index, WriteCardinalToTList(Item));
End;
function TUIntList.Last: Cardinal;
Begin
  Last:= ReadCardinalFromTList(Inherited Last);
End;
function TUIntList.ExtractLast: Cardinal;
Begin
  ExtractLast:= Self.ExtractByNum(Self.Count - 1);
End;
             // Виконує пошук у списку... знаходить перший елемент, що
             // рівний поданому значенню:
function TUIntList.IndexOf(Const Item: Cardinal): Integer;
var
  LCount: Integer;
  cItem, cSourceItem: Cardinal;
begin
  LCount := Self.Count;

  cSourceItem:= Item;

  for Result := 0 to LCount - 1 do // new optimizer doesn't use [esp] for Result
  Begin
    cItem:= Self.Get(Result);

    if cItem = cSourceItem then Exit;
  End;

  Result := -1;
end;

function BytesToAnsiString(const sBytes:TIdBytes):AnsiString;
var ccLength:Integer;
Begin
  ccLength:= System.Length(sBytes);
  SetLength(Result, ccLength);
  if ccLength > 0 then
    System.Move(sBytes[0], Result[1], ccLength);
End;
function BytesToString(const sBytes:TIdBytes):String;
var ccLength, ccDoubleByteLength, ccCharLength:Integer;
Begin
  ccLength:= System.Length(sBytes);
  ccCharLength:= SizeOf(System.Char);
  ccDoubleByteLength:= (ccLength div ccCharLength) + (ccLength mod ccCharLength);
  SetLength(Result, ccDoubleByteLength);
  if ccDoubleByteLength > 0 then
    System.Move(sBytes[0], Result[1], ccLength);
End;
function AnsiStringToBytes(const sString:AnsiString):TIdBytes;
var ccByteCount:Integer;
Begin
  ccByteCount:= System.Length(sString);
  SetLength(Result, ccByteCount);
  if ccByteCount > 0 then
    System.Move(sString[1], Result[0], ccByteCount);
End;
function StringToBytes(const sString:String):TIdBytes;
var ccByteCount:Integer;
Begin
  ccByteCount:= SysUtils.ByteLength(sString);
  SetLength(Result, ccByteCount);
  if ccByteCount > 0 then
    System.Move(sString[1], Result[0], ccByteCount);
End;

end.
