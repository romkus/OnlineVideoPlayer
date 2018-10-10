unit PatchMemory;


Interface
uses Windows, ImageHlp, SysUtils;

var  BasePointer: pointer;
type TPatchMemory = Class
  DllNameToPatch: String; //Имя DLL, в секции импорта которой будем производить изменения
  DllNameToFind: String; //Имя DLL, функцию которой мы хотим перехватить (например, 'KERNEL32.dll')
  FuncNameToFind: String; //Функция, которую мы хотим перехватить (например, 'CreateProcessA')
  NewFunctionAddr: Pointer; //Адрес функции - заменителя
  OldFunctionAddr: Pointer; //Старый адрес замещенной функции
  procedure Patch;  //Выполняет замену стандартной функции на нашу
  procedure UnPatch;  //Отменяет патчинг

        Constructor Create;
        Destructor Destroy; Override;

private

  AddrWherePatching: Pointer; //Для UnPatch
  function GetDwordByRVA(rva: dword):dword;
  function GetStringByRVA(rva: dword):pchar;
  function GetPointerByRVA(rva: DWORD):Pointer;
  function GetRVAByPointer(P: Pointer):DWORD;
  procedure WriteDwordToMemory(Kuda: Pointer; Data: DWORD);

end;


//////////////////////////////////////////////////////////
implementation

//////////////////////////////////////////////////////////
procedure say(s:String);
//Отладочная печать
begin
//  MessageBox(0,pchar(s),'',0);
end;


//////////////////////////////////////////////////////////////
Constructor TPatchMemory.Create;
begin
     inherited Create;
end;

//////////////////////////////////////////////////////////////
destructor TPatchMemory.Destroy;
begin
     say('Destroy');
     inherited Destroy;

end;



//////////////////////////////////////////////////
function TPatchMemory.GetDwordByRVA(rva: dword):dword;
//Получает значение (4 байтовое целое без знака - DWORD) из памяти по
//смещению (RVA)
begin
   asm
     push ebx;

     mov ebx, [rva];
     add ebx, [BasePointer];

     mov eax, [ebx];
     mov Result, eax;

     pop ebx;
   end;
end;

//////////////////////////////////////////////////
function TPatchMemory.GetStringByRVA(rva: dword):pchar;
//Получает строку по указателю RVA
begin
   asm
     mov eax, [rva];
     add eax, [BasePointer];
     mov Result, eax;
   end;
end;

//////////////////////////////////////////////////
function TPatchMemory.GetPointerByRVA(rva: DWORD):Pointer;
//Получает указатель из RVA (т.е. прибавляет к rva значение BasePointer)
begin
   asm
     mov eax, rva;
     add eax, [BasePointer];
     mov Result, eax;
   end;
end;

//////////////////////////////////////////////////
function TPatchMemory.GetRVAByPointer(P: Pointer):DWORD;
//Получает указатель RVA из указателя
//(т.е. вычитает из указателя значение BasePointer)
begin
  asm
    mov eax, [p];
    sub eax, BasePointer;
    mov Result, eax;
  end;
end;

//////////////////////////////////////////////////
Procedure TPatchMemory.WriteDwordToMemory( //Пишем 4 байта в память по указателю.
  Kuda: Pointer; //Адрес куда пишем
  Data: DWORD //Значение которое пишем
);

var  BytesWritten: DWORD;
var  hProcess: THandle;
var old: DWORD;
begin

  hProcess := GetCurrentProcess(//Функция WinAPI
  );


    //Разрешаем доступ на запись по указанному адресу

    VirtualProtect(//Функция WinAPI
      kuda, //адрес
      4, //число байт (будут затронуты 1 или 2 страницы памяти размером 4К)
      PAGE_EXECUTE_READWRITE, //атрибуты доступа
      @old); //сюда будут возвращены старые атрибуты

    BytesWritten:=0;

    //Записываем 4 байта
    WriteProcessMemory(//Функция WinAPI
      hProcess,
      kuda,
      @data,
      4,
      BytesWritten);

 //Восстанавливаем прежние атрибуты доступа
    VirtualProtect(//Функция WinAPI
      kuda,
      4,
      old,
      @old);

end;



//////////////////////////////////////////////////////////
procedure TPatchMemory.Patch;
var ulSize: ULONG;
var rva: DWORD;
var ImportTableOffset: pointer;
var OffsetDllName: DWORD;
var OffsetFuncAddrs: DWORD;
var FunctionAddr: DWORD;
var DllName: String;
var FuncAddrToFind: DWORD;
begin

//В Windows 2000 DLL в этот момент, возможно, еще не загружена
   if DWORD(GetModuleHandle(pchar(DllNameToPatch)))=0 then begin
      LoadLibrary(pchar(DllNameToPatch));
   end;

//Получаем адрес функции, который мы хотим найти в таблице IAT
  FuncAddrToFind:= DWORD(
    GetProcAddress(//Функция Windows API
      GetModuleHandle(//Функция Windows API
        pchar(DllNameToFind)
      ),
      pchar(FuncNameToFind)
    ));

  say(DllNameToFind+' '+FuncNameToFind);
  say('FuncAddrToFind: '+IntToHex(FuncAddrToFind,8));
  OldFunctionAddr:=Pointer(FuncAddrToFind);

//Получаем адрес, по которому расположена в памяти dll - "жертва".
  BasePointer:=pointer(GetModuleHandle(//Функция Windows API
  pChar(DllNameToPatch)));

//Получаем смещение таблицы импорта
  ImportTableOffset:= ImageDirectoryEntryToData( //Функция Windows API
  BasePointer, TRUE, IMAGE_DIRECTORY_ENTRY_IMPORT, ulSize);

//Переводим смещение таблицы импорта в формат RVA
//(смещение относительно начала DLL)
  rva:=GetRvaByPointer(ImportTableOffset);

  repeat    {Проходим по таблице импорта.
     Каждая запись в таблице импорта имеет длину 20 байт:
     +0 - указатель на таблицу имен функций (для Borland ее нет)
     +4 - ?
     +8 - ?
     +12 - Указатель (RVA) на имя DLL
     +16 - указатель на таблицу адресов функций
     }

         OffsetDllName := GetDwordByRVA(rva+12);
         if OffsetDllName = 0 then break; //Если таблица кончилась, выходим

          DllName := GetStringByRVA(OffsetDllName);//Имя DLL

               OffsetFuncAddrs:=GetDwordByRva(rva+16);
                 repeat //Цикл по списку функций DLL
                   FunctionAddr:=Dword(GetDwordByRva(OffsetFuncAddrs));
                   if FunctionAddr=0 then break; //Если функции закончились, выходим

                   if FunctionAddr=FuncAddrToFind then begin
                    //Нашли - выполняем патч
                     AddrWherePatching:=GetPointerByRva(OffsetFuncAddrs);
                     WriteDwordToMemory(
                      AddrWherePatching,
                      DWORD(NewFunctionAddr));
                   //say('AddrWherePatching: '+IntToHex(Dword(AddrWherePatching),8));
                   end;



                 inc(OffsetFuncAddrs,4);
               until false;
          rva:=rva+20;
  until false;

end;


//////////////////////////////////////////////////////////
procedure TPatchMemory.UnPatch;
begin
   say('AddrWherePatching: '+IntToHex(Dword(AddrWherePatching),8));
   say('OldFunctionAddr: '+IntToHex(Dword(OldFunctionAddr),8));
   WriteDwordToMemory(
     AddrWherePatching,
     DWORD(OldFunctionAddr));
end;


end.
